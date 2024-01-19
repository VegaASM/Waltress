	.file	"add_header.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#r3 = pointer to source.s/code.txt
#r4 = source.s/code.txt size EXcluding null
#r5 = pointer to gecko header
#r6 = gecko header type

#r3 returns new size INCLUDING NULL

#0 = Raw
#1 = C2
#2 = 04
#3 = 06
#4 = C0

.globl add_header
add_header:
stwu sp, -0x0020 (sp)
mflr r0
stw r29, 0x14 (sp)
stw r30, 0x18 (sp)
stw r31, 0x1C (sp)
stw r0, 0x0024 (sp)

#Save r3 r4 r5 arg
mr r31, r3
mr r30, r4
mr r29, r5

#Now include null byte to size (r4 arg)
#We want to move the appending null byte to always ensure source.s final string ends in null, sanity to stop overflows
#NOTE this is important
addi r4, r4, 1

cmpwi r6, 4
beq- jimmyrakestrawC0

#C2/04/06 found, memmove source.s forward by 10 bytes
mr r5, r4 #Size
mr r4, r3 #Source
addi r3, r3, 10 #Dest, move forward
bl memmove
li r7, 9
b transferheader_to_source

#C0 found, memmove source.s/code.txt forward by 4 bytes
jimmyrakestrawC0:
mr r5, r4 #Size
mr r4, r3 #Source
addi r3, r3, 4 #Dest, move forward
bl memmove
li r7, 3

transferheader_to_source:
mtctr r7
addi r4, r29, -1
addi r3, r31, -1
lbzu r0, 0x1 (r4)
stbu r0, 0x1 (r3)
bdnz+ -0x8

#Now store an enter inbetween header and rest of source.s/code.txt
li r0, 0xA
stb r0, 0x1 (r3)

#Now calc new source.s length and EXCLUDE null to return to parent func
add r3, r7, r30 #Header + source.s/code.txt(w/ null)
addi r3, r3, 1 #Account for 0xA byte in between header and source.s/code.txt

#Epilogue
lwz r0, 0x0024 (sp)
lwz r31, 0x1C (sp)
lwz r30, 0x18 (sp)
lwz r29, 0x14 (sp)
mtlr r0
addi sp, sp, 0x0020
blr





