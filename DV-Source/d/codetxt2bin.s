#Func changes fully parsed code.txt to a bare bones code.bin via a series of sscanf calls
#r3 = pointer to code.txt
#r4 = size of code.txt excluding null byte (we need this to make this func short)
#r3 return 0 for success, negative for failure
string1_codetxt2bin:
.asciz "%08X"
string2_codetxt2bin:
.asciz "%08x"
.align 2

.globl codetxt2bin
codetxt2bin:
#Make sure r4 is divisible by 8, just in case.....
mr r5, r3
andi. r0, r4, 0x7 #3 LSB's need to get null
li r3, -999
bnelr-
mr r3, r5

#Prologue
stwu sp, -0x0030 (sp)
mflr r0
stw r29, 0x24 (sp) #0x8 thru 0x23 is buffer space for sprintf
stw r30, 0x28 (sp)
stw r31, 0x2C (sp) 
stw r0, 0x0034 (sp)

#Set main loop count in r29 (size divided by 8)
#Set buffer sp dump spot
srwi r29, r4, 3
addi r30, r3, -4
addi r31, r3, -8

#sscanf
#r3 = pointer to formatted (ascii) shit
#r4 = pointer to %08X/x
#r5 = where to dump real hex word value (converted *from* ascii)

codetxt2bin_loop:
addi r31, r31, 8 #Every ASCII instruction is 8 bytes (double-word) long
lis r4, string1_codetxt2bin@h
addi r5, sp, 8
ori r4, r4, string1_codetxt2bin@l
mr r3, r31
bl sscanf
cmpwi r3, 1
beq- storebuffer_and_decrement
#Try again but with lowercase hex char string
lis r4, string2_codetxt2bin@h
addi r5, sp, 8
ori r4, r4, string2_codetxt2bin@l
mr r3, r31
bl sscanf
cmpwi r3, 1
li r3, -999
bne- codetxt2bin_error
storebuffer_and_decrement:
subic. r29, r29, 1
lwz r0, 0x8 (sp)
stwu r0, 0x4 (r30)
bne+ codetxt2bin_loop

#Success
li r3, 0

codetxt2bin_error:
lwz r0, 0x0034 (sp)
lwz r31, 0x2C (sp)
lwz r30, 0x28 (sp)
lwz r29, 0x24 (sp)
mtlr r0
addi sp, sp, 0x0030
blr
