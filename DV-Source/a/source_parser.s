#This function accepts source.s and removes the following..
#Double+ Enters, *not* single enters
#Spaces
#Tabs
#Comments
#This is needed because Waltress ASM Engine needs everything stripped
#r3 source.s must end in enter then null byte!

#r3 = pointer to source.s that ends in Enter then Null
#r4 = byte size *plus* null

#TODO show condi branch in puts message

wtf_lmao: #TODO remove this error line/check from the branch label parser since its here
.asciz "\n\nError! At least 1 branch label does not have a landing spot."
.align 2

#Symbols
.set space, 0x20
.set enter, 0x0A
.set tab, 0x09
.set comment, 0x23
.set slash, 0x2F
.set asterisk, 0x2A

#Prologue
.globl source_parser
source_parser:
stwu sp, -0x0020 (sp)
mflr r0
stw r26, 0x8 (sp)
stw r27, 0xC (sp)
stw r28, 0x10 (sp)
stw r29, 0x14 (sp)
stw r30, 0x18 (sp)
stw r31, 0x1C (sp)
stw r0, 0x0024 (sp)

#Save Args
mr r31, r3
mr r30, r4

#Change all comments and chars within comments to spaces
#We'll make a dedicated comment handler in a future version
#Pre decrement ptr/cursor and place space symbol in r4
addi r3, r3, -1
li r4, space

change_comments_to_spaces:
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beq- remove_double_enters #If null, stop doing this ofc
cmpwi r0, comment #Check for 1st comment symbol of line
beq- handle_hashtagged_comment
cmpwi r0, slash
bne+ change_comments_to_spaces
#At this point, we may be in a chain-type comment
lbz r0, 0x1 (r3)
cmpwi r0, asterisk
bne- change_comments_to_spaces

#Now we are on a chain comment
#Write over slash asterisk first
stb r4, 0 (r3)
stbu r4, 0x1 (r3)
lbzu r0, 0x1 (r3)
cmpwi r0, asterisk #if asterisk is hit we may be at end of chain comment
stb r4, 0 (r3) #No matter what, this must be done. Overwrite current char with space
bne+ -0xC
lbz r0, 0x1 (r3) #asterisk was current char, very next char must be the slash
cmpwi r0, slash
bne+ -0x18
stbu r4, 0x1 (r3) #Overwrite slash and update cursor to comply with loop
b change_comments_to_spaces

#Now we are on a hashtag-type comment
#Write over comment symbol first
handle_hashtagged_comment:
stb r4, 0 (r3)
#Now check for enter, once we hit enter go back to prev loop
lbzu r0, 0x1 (r3)
cmpwi r0, enter
beq- change_comments_to_spaces
#Enter not found yet, overwrite char/symbol with space
stb r4, 0 (r3)
b -0x10 #Go back to checking for enter again

#All comment and chars within comments are now spaces
#Now remove all double+ enters
remove_double_enters:
addi r3, r31, -1 #Reset cursor
remove_double_enters_loop:
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beq- almost_there
cmpwi r0, enter
bne+ remove_double_enters_loop
mr r4, r3
lbzu r0, 0x1 (r4)
cmpwi r0, space
beq- -0x8
cmpwi r0, tab
beq- -0x10
cmpwi r0, enter #TODO fix to move cursor (update r3 is bne route is taken) forward, not needed technically but should be done
bne+ remove_double_enters_loop
li r5, space
stb r5, 0 (r4)
b -0x24

#There may be a newline (0xA) char at the very start of file, remove it
almost_there:
lbz r0, 0x0 (r31)
cmpwi r0, enter
bne- start_standard_parser
li r0, space
stb r0, 0x0 (r31)

#####################
#####################
#Set counter to know how much to subtract from r30 which will be used as setup for memmove r4 arg
start_standard_parser:
li r6, 0

#Setup r31 for loop
addi r31, r31, -1

#Loop
standard_parser_loop:
lbzu r0, 0x1 (r31)
addi r6, r6, 1
cmpwi r0, 0
beq- source_parser_epilogue
cmpwi r0, space
beq- setup_memmoves
cmpwi r0, tab
bne+ standard_parser_loop

#Memmove
#r3 = Destination Addr
#r4 = Source Addr
#r5 = Size in bytes
setup_memmoves:
mr r3, r31
addi r4, r31, 1
sub r30, r30, r6
mr r5, r30
bl memmove
li r6, 0 #Reset r6
subi r31, r31, 1 #Update cursor to correct spot now that contents have shifted left 1 byte
b standard_parser_loop

wtf_lol:
lis r3, wtf_lmao@h
ori r3, r3, wtf_lmao@l
b source_parser_further_epilogue

#Epilogue
source_parser_epilogue:
li r3, 0
source_parser_further_epilogue:
lwz r31, 0x1C (sp)
lwz r30, 0x18 (sp)
lwz r29, 0x14 (sp)
lwz r28, 0x10 (sp)
lwz r27, 0xC (sp)
lwz r26, 0x8 (sp)
lwz r0, 0x0024 (sp)
mtlr r0
addi sp, sp, 0x0020
blr
