	.file	"newline_fixer.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Quick hacky patch to change all Carriages to Newlines, and Carriage+Newline combos (eww Windows) to Newlines
#r3 = pointer to code.txt/source.s (must end in null byte)

.globl newline_fixer
newline_fixer:
subi r3, r3, 1
li r4, 0xA
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beqlr-
cmpwi r0, 0xD
bne+ -0x10
stb r4, 0 (r3)
b -0x18


