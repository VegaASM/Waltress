	.file	"branchlabelparser.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#This gets immediately called AFTER source.s parser
no_landing_spot_text:
.asciz "\n\nError! The above instruction's branch label doesn't have a landing spot.\n\n"
too_small_text:
.asciz "\n\nError! The above instruction's branch label is not at least 3 characters in length.\n\n"
too_much_text:
.asciz "\n\nError! The above instruction's branch label exceeds 31 characters in length.\n\n"
invalid_char_text:
.asciz "\n\nError! The above instruction's branch label uses an invalid character.\n\n"
too_far_jump_condi_text:
.asciz "\n\nError! The above instruction's branch label (conditional) has a jump that exceeds 0x7FFC.\n\n"
too_far_jump_uncondi_text:
.asciz "\n\nError! The above instruction's branch label (unconditional) has a jump that exceeds 0x01FFFFFC.\n\n"
duplicate_spots:
.asciz "\n\nError! The above instruction's branch label has at least 2 different landing spots.\n\n"
malloc_text:
.asciz "\n\nError! For whatever reason, memory couldn't be allocated when needing to expand source.s due to a label-to-simm conversion.\n\n"
.align 2

.globl branchlabelparser
branchlabelparser:

#Func processes branch labels
#Branch instructions receive their SIMMs
#Landing labels gets removed

#Args
#r3 = source.s ptr (MUST END IN NULL or else overflow occurs)
#Return Values
#r3 = 0 (success)
#r3 = Pointer to ASCII error message if not success

/*
r31 = source.s
r30 = branch label ptr
r29 = simm max
r28 = length of branch label
r27 = branch lebal landing ptr
r26 = source.s size
r25 = brand new source.s ptr (will replace assemble.s's r27 if used)
*/

#Symbols
.set branch_ident, 0x0A62 #/nb
.set underscore, 0x5F #_
.set colon, 0x3A #:

#Prologue
stwu sp, -0x0030 (sp)
mflr r0
stw r25, 0x14 (sp) #0x8 thru 0x13 is buffer
stw r26, 0x18 (sp)
stw r27, 0x1C (sp)
stw r28, 0x20 (sp)
stw r29, 0x24 (sp)
stw r30, 0x28 (sp)
stw r31, 0x2C (sp)
stw r0, 0x0034 (sp)

#Save arg
mr r31, r3

#Search for 0x0A62 (/nb)
subi r30, r31, 1
ROOTLOOP:
lhzu r0, 0x1 (r30)
srwi. r4, r0, 8 #Check for EoF null byteROOTLOOP
beq- erase_landing_spots
cmpwi r0, branch_ident
bne+ ROOTLOOP

#Possible branch found, check character after b
#lf capital letter or underscore, its a label for uncondi branch
lbzu r0, 0x2 (r30)
cmpwi r0, 0x6C #l
beq- condibranch
cmpwi r0, 0x67 #g
beq- condibranch
cmpwi r0, 0x65 #e
beq- condibranch
cmpwi r0, 0x73 #s
beq- condibranch
cmpwi r0, 0x6E #n
beq- condibranch
cmpwi r0, 0x64 #d
beq- condibranch
cmpwi r0, underscore
beq- uncondibranch
cmplwi r0, 0x41 #A
blt- ROOTLOOP 
cmplwi r0, 0x5A #Z
bgt- ROOTLOOP

#Uncondi branch possibly found, set one-way SIMM max value
uncondibranch:
#Check for "0x"
lhz r0, 0 (r30)
cmpwi r0, 0x3078
beq- ROOTLOOP #SIMM used, not label, skip branch!
lis r29, 0x01FF
ori r29, r29, 0xFFFC
b get_label_length

#Condi branch possibly found, set one-way SIMM value max
#Atm, r30 is at the char right after (b). Every conditional branch is bxx or greater, so add one to r30 then start doing update-type loop,load, and check
condibranch:
addi r30, r30, 1
condibranch_loop:
lbzu r0, 0x1 (r30)
cmpwi r0, 0 
beq- erase_landing_spots
cmpwi r0, 0xA
beq- ROOTLOOP
cmpwi r0, 0x30 #check for 0 out of possible 0x
bne- 0x10
lbz r0, 0x1 (r30)
cmpwi r0, 0x78 #check for x out of possible 0x
beq- ROOTLOOP #SIMM found instead of branch label, skip this branch!!!
cmpwi r0, underscore
li r29, 0x7FFC
beq- get_label_length
cmplwi r0, 0x41 #A
blt- condibranch_loop
cmplwi r0, 0x5A #Z
bgt- condibranch_loop

#r30 (Branch label ptr/cursor) is fully adjusted, now get length of label
#Must be *in* between 3 and 32
get_label_length:
mr r3, r30 #Keep GVR intact for later
lbzu r0, 0x1 (r3)
cmpwi r0, 0xA
bne+ -0x8
sub r28, r3, r30
cmplwi r28, 3
blt- too_short
cmplwi r28, 31
bgt- too_long

#Branch labels can ONLY contain capital letters and underscores
subi r3, r30, 1
char_validator:
lbzu r0, 0x1 (r3)
cmpwi r0, 0xA
beq- search_for_landing_spot
cmplwi r0, 0x41
blt- invalid_branch_char
cmpwi r0, 0x5F
beq- char_validator
cmplwi r0, 0x5A
ble- char_validator
b invalid_branch_char

#Now search the file for the label's "landing spot" respective label
search_for_landing_spot:
subi r27, r31, 1
compare_labels:
lbzu r0, 0x1 (r27)
cmpwi r0, 0
beq- missing_landing_spot
#r30 = label ptr
#r27 = landing label ptr
#r28 = byte count
mr r3, r30
mr r4, r27
mr r5, r28
bl memcmp
cmpwi r3, 0
bne+ compare_labels

#Either we found the branch label landing-spot or we just ran into the branch label again
#Colon should be next char
lbzx r0, r27, r28
cmpwi r0, colon
bne- compare_labels

#Now search rest of file if 2nd+ landing spot exist which it shouldn't
make_sure_no_duplicate_landing_spot_exists:
mr r26, r27
make_sure_no_duplicate_landing_spot_exists_LOOP:
lbzu r0, 0x1 (r26)
cmpwi r0, 0
beq- found_it_for_sure
mr r3, r27
mr r4, r26
addi r5, r28, 1 #Include the colon in count
bl memcmp
cmpwi r3, 0
beq- duplicate_error
b make_sure_no_duplicate_landing_spot_exists_LOOP

#Now we've found it!
#Make copy of r30 & r27
found_it_for_sure:
mr r3, r30
mr r4, r27

#First we need to differentiate if the branch SIMM is positive or negative
#lf r30 ptr is less than r27 then its a positive branch
#lf r30 ptr is greater than r27, then its a negative branch
cmplw cr7, r30, r27 #Use cr7 because we need to branch on this conditonal later on!!
blt- cr7, 0x10 #Skip register swap

#SIMM is negative (backwards branch) Swap r30 (now r3) and r27 (now r4), thank you PPC compiler writer's guide
xor r3, r3, r4
xor r4, r4, r3
xor r3, r3, r4

#Count amount of 0xA's (enter's) in between the labels
subi r3, r3, 1
li r5, 0
lbzu r0, 0x1 (r3)
cmpw r3, r4
beq- calc_branchlabel_simm
cmpwi r0, 0xA
bne+ -0x10
lbz r0, -0x1 (r3) #Check for : from unrelated branch landing spot, we do NOT want to count that enter
cmpwi r0, colon
beq- -0x1C
addi r5, r5, 1
b -0x24

#Now we have amount of enters (instruction count), mulli by 4 to get SIMM, then check vs Upper Bound One-way SIMM
calc_branchlabel_simm:
slwi r3, r5, 2
cmplw r3, r29
bgt- exceed_simm

#Convert SIMM from hex to ascii, store to buffer
blt- cr7, 0x8 #If SIMM (r30 vs r27) is positive, this branch is taken
neg r3, r3 #Negative SIMM needs to be Negative ofc
addi r4, sp, 0x8
bl hex2asciiBParser #Keeping this in a subfunc to not clobber stuff up here

#SIMM digit length will be hardcoded to 0xXXXXXXXX (10 chars)
#Do Label digits minus SIMM digits, we need this for later, plus it will also decide if we expand, contract, or keep file size same
#0 = do simm write only
#>0 = must contract file then simm write
#<0 = must expand file, adjust key GVRs, then simm write
subic. r3, r28, 10
beq- do_simm_write

#At this point no matter what, we need to know the current length of source.s (INcluding null byte)
#NOTE Keep cr0 & r3 intact!
subi r4, r31, 1
lbzu r0, 0x1 (r4)
cmpwi cr7, r0, 0
bne+ cr7, -0x8
sub r4, r4, r31
addi r26, r4, 1 #Account for null byte

#Okay r26 holds length of source.s plus null byte, now branch based on expanding vs contracting file
bgt- must_contract_file

#Alloc new buffer for filesize + r3 from above subic(.) instruction
sub r3, r26, r3 #r3 (delta) is negative, so a subtraction will yield an addition
bl malloc
mr. r25, r3
beq- malloc_branchparser_error_label
#Transfer from original space to new malloced space
mr r4, r31
mr r5, r26
bl memcpy

#NOTE: Yes the following is hardcoded, yuck! Edit GVR!!!!
#Source.s is now at a new spot, we need to manually fix r27 
stw r25, 0x1C (sp) #Replace caller-saved r27 with callee-made r25
#Fix r30 (label ptr)
sub r3, r30, r31
add r30, r25, r3
#Fix this func's r31 (source.s ptr)
mr r31, r25
#Now we can just memmove it, hooray

must_contract_file:
#File size needs cut down! Branch label digit length exceeds 10 digits
#memmove
#r3 = dest
#r4 = src
#r5 = length of block
add r4, r30, r28 #Label Ptr + Label Size will result as Src ptr (point at the 0xA right after branch label)
addi r3, r30, 10 #okay to hardcode since all gen'd SIMMs are 0xXXXXXXXX ;r3 NOW set
add r5, r31, r26 #r5 at this moment = one byte PAST null byte ptr
sub r5, r5, r4 #One-past-Null byte ptr - Src ptr = amount to move exactly!
bl memmove
#Only thing left to do is transfer the SIMM ascii to source.s

#No expanding nor contracting needed, just plug in SIMM ascii!
do_simm_write:
#Transfer from stack buffer to source.s
li r0, 5
addi r3, sp, 6
mtctr r0
subi r4, r30, 2
lhzu r0, 0x2 (r3)
sthu r0, 0x2 (r4)
bdnz+ -0x8

#Sweet! We did it. Move onto next possible branch label
b ROOTLOOP

#A branch label has 2 more more landing spots
duplicate_error:
#Null out enter AFTER branch label
mr r3, r30
bl null_post_enter
#Move cursor to previous enter or SoF-1 (start of file minus 1)
mr r3, r30
bl move_cursor_back
#Print the culprit
crxor 6, 6, 6
bl printf
#Return error string to Parent
lis r3, duplicate_spots@h
ori r3, r3, duplicate_spots@l
b branchlabelepilogue

#A branch label's landing spot is missing
missing_landing_spot:
#Null out enter AFTER branch label
mr r3, r30
bl null_post_enter
#Move cursor to previous enter or SoF-1 (start of file minus 1)
mr r3, r30
bl move_cursor_back
#Print the culprit
crxor 6, 6, 6
bl printf
#Return error string to Parent
lis r3, no_landing_spot_text@h
ori r3, r3, no_landing_spot_text@l
b branchlabelepilogue

#Branch min violation
too_short:
#Null out enter AFTER branch label
mr r3, r30
bl null_post_enter
#Move cursor to previous enter or SoF-1 (start of file minus 1)
mr r3, r30
bl move_cursor_back
#Print the culprit
crxor 6, 6, 6
bl printf
#Return error string to Parent
lis r3, too_small_text@h
ori r3, r3, too_small_text@l
b branchlabelepilogue

#Branch max violation
too_long:
#Null out enter AFTER branch label
mr r3, r30
bl null_post_enter
#Move cursor to previous enter or SoF-1 (start of file minus 1)
mr r3, r30
bl move_cursor_back
#Print the culprit
crxor 6, 6, 6
bl printf
#Return error string to Parent
lis r3, too_much_text@h
ori r3, r3, too_much_text@l
b branchlabelepilogue

#Branch invalid char violation
invalid_branch_char:
#Null out enter AFTER branch label
mr r3, r30
bl null_post_enter
#Move cursor to previous enter or SoF-1 (start of file minus 1)
mr r3, r30
bl move_cursor_back
#Print the culprit
crxor 6, 6, 6
bl printf
#Return error string to Parent
lis r3, invalid_char_text@h
ori r3, r3, invalid_char_text@l
b branchlabelepilogue

#Bad SIMM
exceed_simm:
#Null out enter AFTER branch label
mr r3, r30
bl null_post_enter
#Move cursor to previous enter or SoF-1 (start of file minus 1)
mr r3, r30
bl move_cursor_back
#Print the culprit
crxor 6, 6, 6
bl printf
#Depending on SIMM used, send appropriate error message back to parent
cmpwi r29, 0x7FFC
bne- 0x10
lis r3, too_far_jump_condi_text@h
ori r3, r3, too_far_jump_condi_text@l
b branchlabelepilogue
lis r3, too_far_jump_uncondi_text@h
ori r3, r3, too_far_jump_uncondi_text@l
b branchlabelepilogue

#Malloc failure
malloc_branchparser_error_label:
lis r3, malloc_text@h
ori r3, r3, malloc_text@l
b branchlabelepilogue

#Done! Only thing left is to remove all branch landing labels (example:)
erase_landing_spots:
#Search for colon
subi r30, r31, 1
erase_landing_spots_loop:
lbzu r0, 0x1 (r30)
cmpwi r0, 0
beq- finally_done
cmpwi r0, colon
bne+ -0x10

#Get size of source.s's null byte ptr, we have to do this because its possible this function never executed to make an r26 value to use from earlier
mr r5, r30 #No need to restart at beginning of file again
lbzu r0, 0x1 (r5)
cmpwi r0, 0
bne+ -0x8
#r5 now = null byte ptr

#Found colon
#For the case that if the user has a branch label at the very very very start of file, we first check
#backwards til we see that the current working ptr matches r31 (source.s) ptr
#For NOT the case above, we then check backwards to see once we hit ASCII enter (0xA)
mr r3, r30
lbzu r0, -0x1 (r3)
cmpw r3, r31
beq- 0xC
cmpwi r0, 0xA
bne+ -0x10
#*DON'T* add one to r3 because we need one of the enters gone, or else we will have back to back enters
addi r4, r30, 1 #Src; must be at char right AFTER :
sub r5, r5, r4 #(Null byte ptr - Src ptr) + 1) = amount to move
addi r5, r5, 1
#Before calling memmove make r30 the dest src, needs to be updated before we loop again
mr r30, r3
#Remove the landing label!
bl memmove
b erase_landing_spots_loop

finally_done:
#ALMOST THERE, if a branch landing label was at very very start of file then the file will start with 0xA which will jack up
#future subroutines and cause crash
lbz r0, 0x0 (r31)
cmpwi r0, 0xA
bne+ actually_done_lol

#Get null byte ptr; so hacky we need to fix all of this in the future lol
subi r5, r31, 1
lbzu r0, 0x1 (r5)
cmpwi r0, 0
bne+ -0x8

#r5 now = null byte ptr, set up args for memmove and call it
mr r3, r31 #Dest
addi r4, r31, 1 #Src
sub r5, r5, r4 #(Null byte ptr - Src ptr) + 1) = amount to move
addi r5, r5, 1
bl memmove

actually_done_lol:
li r3, 0

branchlabelepilogue:
lwz r0, 0x0034 (sp)
lwz r31, 0x2C (sp)
lwz r30, 0x28 (sp)
lwz r29, 0x24 (sp)
lwz r28, 0x20 (sp)
lwz r27, 0x1C (sp)
lwz r26, 0x18 (sp)
lwz r25, 0x14 (sp)
mtlr r0
addi sp, sp, 0x0030
blr

hex2asciiBParser:
#First store "0x" to buffer space
li r0, 0x3078
sth r0, 0 (r4)
#Set loop amount
li r0, 8
mtctr r0
#Set initial shiftor amount
li r5, 32
#Adjust r4 for when we stbu the ascii byte
addi r4, r4, 1
#Loop
hex2asciiBParser_loop:
#Update shiftor  amount
subi r5, r5, 4
#Extract digit
srw r0, r3, r5
clrlwi r6, r0, 28
#Convert from digit hex to byte ascii
cmplwi r6, 9
bgt- 0xC
ori r7, r6, 0x30
b 0x8
addi r7, r6, 0x37
#Store converted byte to buffer
stbu r7, 0x1 (r4)
#Decrement loop
bdnz+ hex2asciiBParser_loop
#End func
blr

null_post_enter:
lbzu r0, 0x1 (r3)
cmpwi r0, 0xA
bne+ -0x8
li r0, 0
stb r0, 0 (r3)
blr

move_cursor_back:
lbzu r0, -0x1 (r3)
cmplw r3, r31
blt- 0xC
cmpwi r0, 0xA
bne+ -0x10
addi r3, r3, 1
blr
