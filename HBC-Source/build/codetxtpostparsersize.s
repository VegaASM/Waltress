	.file	"codetxtpostparsersize.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Simple func to calculate file size, excluding null byte
#r3 = pointer to code.txt
#r3 returns byte size

.globl codetxtpostparsersize
codetxtpostparsersize:
addi r4, r3, -1
li r3, 0

lbzu r0, 0x1 (r4)
cmpwi r0, 0
beqlr-
addi r3, r3, 1
b -0x10
