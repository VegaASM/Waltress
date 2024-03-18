	.file	"finalize_assembled_bin.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Func (right after waltress abin completes)

#r3 = code.bin raw size calc (this div'd by 4 = amount of instructions)
#r4 = code.bin pointer
#r5 = codetype
#r6 = gecko header pointer
#r3 returns new code.bin size

#NOTE net instruction amount = total word amount of final code.bin, includes headers, footers etc
#raw size anything = without any gecko shit

.globl finalize_assembled_bin
finalize_assembled_bin:
#For the case that if somehow this func gets called with RAW, If r5 = 0, simple end func
cmpwi r5, 0
beqlr-

#Look for C0 next, cuz it needs no stack shit
cmpwi r5, 4
bne- this_is_gonna_suck

#C0 codetype found
#Write header
Cohohoh:
lis r0, 0xC000
stw r0, 0 (r4)
#If byte size end in 0x0 or 0x8, we need to add whole new line (blr + null word)
#If byte size end in 0x4 or 0xC, we need to add just blr to current last line
andi. r0, r3, 0x4
lis r0, 0x4E80
ori r0, r0, 0x0020
addi r3, r3, 8 #No matter what add 8 to byte amount cuz C0 header and lineamount word holder
stwx r0, r3, r4 #No matter what write the blr
bne- add_four_for_blr
li r0, 0
addi r3, r3, 4 #Add 4 for byte amount for null
stwx r0, r3, r4
add_four_for_blr:
addi r3, r3, 4 #Add 4 for byte amount for blr
#Write in line amount [(current net byte amount - 8) / 8]
subi r5, r3, 8
srawi r0, r5, 3
stw r0, 0x4 (r4)
#r3 ready to return
blr

#C2/04/06 found, great... lol
this_is_gonna_suck:
stwu sp, -0x0020 (sp)
mflr r0
stw r28, 0x10 (sp)
stw r29, 0x14 (sp)
stw r30, 0x18 (sp)
stw r31, 0x1C (sp)
stw r0, 0x0020 (sp)

#Backup args
mr r31, r3
mr r30, r4
mr r29, r5
mr r28, r6

#First change header to binary and store
#Sub func
#r3 = pointer to header
#r3 returns header word in hex
mr r3, r6
bl ascii2hexPARENT #Making this a func so its not cluttered in my way and shit
stw r3, 0 (r30)

#check codetypes again
cmpwi r29, 1
beq- Ctwotwotwo
cmpwi r29, 2
li r3, 8
beq- finalassemepipen #nothing left to do if 04 codetype

#06 codetype found
#If byte size end in 0x0 or 0x8, do nothing
#If byte size end in 0x4 or 0xC, we need to add just null word to current last line
andi. r0, r31, 0x4
stw r31, 0x4 (r30) #No matter what write net byte amount in 06byteamount holder
addi r31, r31, 8 #No matter what add 8 to byte amount cuz 06 header and byteamount word holder
beq- just_move_r31
li r0, 0
stwx r0, r31, r30 #Write the null
addi r3, r31, 4 #Add 4 to byte amount cuz null word, return in r3
b finalassemepipen
just_move_r31:
mr r3, r31 #Do NOT add 4 to byte amount. we DONT have added null word. Copy r31 to r3 and return
b finalassemepipen

#C2 codetype found
#Write header
#r5 = instruction amount that gets updated over time, at end we will mulli by 4 to get net code.bin size
Ctwotwotwo:
#If byte size end in 0x0 or 0x8, we need to add whole new line (nop + null word)
#If byte size end in 0x4 or 0xC, we need to add just null word to current last line
andi. r0, r31, 0x4
li r4, 0 #r4 will write the null word
addi r31, r31, 8 #No matter what add 8 to byte amount cuz C2 header and lineamount word holder
bne- add_c2nullender
lis r0, 0x6000
stwx r0, r31, r30
addi r31, r31, 4 #Add 4 to byte amount cuz nop was needed
add_c2nullender:
stwx r4, r31, r30
addi r31, r31, 4 #Add 4 to byte amount cuz null word no matter what
#Write in line amount [(current net byte amount - 8) / 8]
subi r5, r31, 8
srawi r0, r5, 3
stw r0, 0x4 (r30)
#move r31 to r3
mr r3, r31

#Epilogue for when codetype is C2/04/06
finalassemepipen:
lwz r0, 0x0020 (sp)
lwz r31, 0x1C (sp)
lwz r30, 0x18 (sp)
lwz r29, 0x14 (sp)
lwz r28, 0x10 (sp)
mtlr r0
addi sp, sp, 0x0020
blr

#Parent routine for converting header from ascii to hex
#r3 arg = ptr to gecko header
#r3 returns gecko header in hex (word)
ascii2hexPARENT:
li r0, 8
li r4, 28 #Amount to shift left by
li r5, 0 #Clear out register for shift+save usage
mtctr r0
as2hexloop:
lbzu r6, 0x1 (r3)
##
ascii2hex:
cmplwi r6, 0x3A
blt- cleartodigit
cmplwi r6, 0x60
bgt- sub0x57
#sub 0x37
subi r6, r6, 0x37
b shifty_shift
sub0x57:
subi r6, r6, 0x57
b shifty_shift
cleartodigit:
andi. r6, r6, 0xF
##
shifty_shift:
slw r6, r6, r4
or r5, r6, r5
subi r4, r4, 4 #Decrement shift-left amount
bdnz+ as2hexloop
mr r3, r5
blr

