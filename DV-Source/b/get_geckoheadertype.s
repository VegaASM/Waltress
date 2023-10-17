#Func returns Gecko Header type
#r3 arg = pointer to code.txt/source.s
#r3 returns..
#-1 = some header found, but invalid
#0 = raw (no header)
#1 = C2
#2 = 04
#3 = 06
#4 = C0

.globl get_geckoheadertype
get_geckoheadertype:
#Save r3 arg
mr r4, r3

#Check for Valid Header
lbz r0, 0x0 (r3)
cmpwi r0, 0x21 #Check for exclamation point
li r3, 0 #Raw ASM, no header
bnelr-

#Some header was found, is it valid?
lhz r0, 0x1 (r4)
li r5, 0x4332
cmpw r0, r5
li r3, 1
beq- c20406headerfound
li r6, 0x3034
cmpw r0, r6
li r3, 2
beq- c20406headerfound
li r7, 0x3036
cmpw r0, r7
li r3, 3
beq- c20406headerfound
li r8, 0x4330
cmpw r0, r8
li r3, -1 #Set error
bnelr- #Branch to LR in invalid header with r3 -1

#C0 found
li r3, 4
blr

#Header cannot have non ascii numbers & letters within address ascii field
c20406headerfound:
li r6, 6
mr r7, r3 #temp backup r3
addi r5, r4, 2
li r3, -1 #preset error
mtctr r6

silly_loop:
lbzu r0, 0x1 (r5)
cmplwi r0, 0x30
bltlr-
cmplwi r0, 0x66
bgtlr-
cmplwi r0, 0x3A
blt- valid_ascii
cmplwi r0, 0x60
bgt- valid_ascii
cmplwi r0, 0x41
bltlr-
cmplwi r0, 0x46
bgtlr-
valid_ascii:
bdnz+ silly_loop

#End func, recover r3
mr r3, r7
blr



