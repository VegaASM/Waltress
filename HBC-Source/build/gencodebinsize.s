	.file	"gencodebinsize.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Function will return the size of to-be-genned code.bin using source.s's amount of Enters
#r3 arg = pointer to source.s
#r3 returns code.bin size

.globl gencodebinsize
gencodebinsize:
addi r4, r3, -1
li r3, 0
gencodebinsizeloop:
lbzu r0, 0x1 (r4)
cmpwi r0, 0
beqlr-
cmpwi r0, 0xA
bne+ gencodebinsizeloop
addi r3, r3, 4
b gencodebinsizeloop
