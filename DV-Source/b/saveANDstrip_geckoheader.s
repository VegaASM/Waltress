#Func does...
#Save header to new malloc space
#Strips out Header from code.txt/source.s and memmoves accordingly
#Returns back malloc pointer

#r3 arg = gecko header type
#r4 arg = pointer to code.txt/source.s
#r5 arg = size of code.txt/source.s plus NULL
#r3 returns pointer
#r3 returns 0 if malloc failed, allow parent func to handle error!

#*NOTE* do not call this when no header or else func will state that malloc failed

.globl saveANDstrip_geckoheader
saveANDstrip_geckoheader:

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

#Backup r4 arg & r5 arg
mr r30, r4
mr r29, r5

#Check for C0 type
cmpwi r3, 4
beq- 0x8 #C0's header type number matches malloc arg, lucky for us

#C2/04/06 header found
li r3, 10

#Save malloc's r3 arg
mr r31, r3

#Malloc, malloc enough for header plus extra byte afterwards
bl malloc
mr. r28, r3 #Save malloc's return value
beq- epipen #Skip saving and memmove if malloc failed

#Save header to malloc'd space
subi r31, r31, 1
addi r4, r30, -1
addi r5, r3, -1
mtctr r31
lbzu r0, 0x1 (r4)
stbu r0, 0x1 (r5)
bdnz+ -0x8

#Now strip header out from code.txt (move code.txt/source/s backwards)
mr r3, r30 #Dest, code.txt/source.s start pointer
add r4, r30, r31 #Src, code.txt/source.s start pointer + moveforward bytes
sub r5, r29, r31 #size of code.txt/source.s str plus null byte
bl memmove

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
