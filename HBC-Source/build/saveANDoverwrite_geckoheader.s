	.file	"saveANDoverwrite_geckoheader.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Func does...
#Save header to new malloc space
#Strips out Header from code.txt/source.s and memmoves accordingly
#Returns back malloc pointer

#r3 arg = gecko header type
#r4 arg = pointer to code.txt/source.s
#r3 returns pointer
#r3 returns 0 if malloc failed, allow parent func to handle error!

.globl saveANDoverwrite_geckoheader
saveANDoverwrite_geckoheader:

#For the case this somehow gets called with no header....
cmpwi r3, 0
beqlr-

#Prologue
stwu sp, -0x0020 (sp)
mflr r0
stw r28, 0x10 (sp)
stw r29, 0x14 (sp)
stw r30, 0x18 (sp)
stw r31, 0x1C (sp)
stw r0, 0x0024 (sp)

#Update r4 (& backup to r30) cursor just in case there are spaces, tabs, and centers before gecko header
subi r30, r4, 1
lbzu r0, 0x1 (r30)
cmpwi r0, 0x20
beq -0x8
cmpwi r0, 0x0A
beq- -0x10
cmpwi r0, 0x09
beq- -0x18

#Check for C0 type
cmpwi r3, 4
li r3, 3
beq- 0x8 #C0's header type number matches malloc arg, lucky for us

#C2/04/06 header found
li r3, 9

#Save malloc's r3 arg (length of Gecko header, 3 for C0, 9 for 04/06/C2)
mr r31, r3

#Malloc, malloc enough for header plus extra byte afterwards
bl malloc
mr. r28, r3 #Save malloc's return value
beq- epipen #Skip saving and memmove if malloc failed

#Save header to malloc'd space
addi r4, r30, -1
addi r5, r3, -1
mtctr r31
lbzu r0, 0x1 (r4)
stbu r0, 0x1 (r5)
bdnz+ -0x8

#Now replace header with spaces, ye we could "cut" it out via memmove, but it's bother faster and shorter just to space fill it
mtctr r31
addi r3, r30, -1
li r0, 0x20
stbu r0, 0x1 (r3)
bdnz+ -0x4

#Recover malloc return value
epipen:
mr r3, r28

#Return malloc return value back to parent
lwz r0, 0x0024 (sp)
lwz r31, 0x1C (sp)
lwz r30, 0x18 (sp)
lwz r29, 0x14 (sp)
lwz r28, 0x10 (sp)
mtlr r0
addi sp, sp, 0x0020
blr
