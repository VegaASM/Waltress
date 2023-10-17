	.file	"codetxtparser.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#This function accepts code.txt and removes the following..
#Spaces
#Tabs
#Enters
#Comments (chain comments not handled yet, will crash)
#This is needed because Waltress DASM Engine needs everything stripped
#r3 code.txt must end in null byte!

#r3 = pointer to code.txt that ends in null
#r4 = byte size plus null

.set cspace, 0x20
.set center, 0x0A
.set ctab, 0x09
.set ccomment, 0x23

#Prologue
.globl codetxtparser
codetxtparser:
stwu sp, -0x0010 (sp)
mflr r0
stw r30, 0x8 (sp)
stw r31, 0xC (sp)
stw r0, 0x0014 (sp)

#Save Args
mr r31, r3
mr r30, r4

#Change all comments and chars within comments to spaces
#We'll make a dedicated comment handler in a future version
#Pre decrement ptr and place space symbol in r4
addi r3, r3, -1
li r4, cspace

hacky_but_whatever_d:
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beq- d_start_parser #If null, stop doing this ofc
cmpwi r0, ccomment #Check for 1st comment symbol of line
bne+ hacky_but_whatever_d

#Now we are on a comment
#Write over comment symbol first
stb r4, 0 (r3)
#Now check for enter, once we hit enter go back to prev loop
lbzu r0, 0x1 (r3)
cmpwi r0, center
beq- hacky_but_whatever_d
stb r4, 0 (r3)
b -0x10 #Go back to checking for enter again

#Set counter to know how much to subtract from r29 which will be used as setup for memmove r4 arg
d_start_parser:
li r6, 0

#Setup r31 for loop
addi r31, r31, -1

#Loop2
codetxtparser_loop:
lbzu r0, 0x1 (r31)
addi r6, r6, 1
cmpwi r0, 0
beq- codetxtparser_epilogue
cmpwi r0, cspace
beq- codetxtparser_setup_memmove
cmpwi r0, center
beq- codetxtparser_setup_memmove
cmpwi r0, ctab
bne+ codetxtparser_loop

#Memmove
#r3 = Destination Addr
#r4 = Source Addr
#r5 = Size in bytes
codetxtparser_setup_memmove:
mr r3, r31
addi r4, r31, 1
sub r30, r30, r6
mr r5, r30
bl memmove
li r6, 0 #Reset r6
subi r31, r31, 1 #Update cursor to correct spot now that contents have shifted left 1 byte
b codetxtparser_loop

#Epilogue
codetxtparser_epilogue:
lwz r30, 0x8 (sp)
lwz r31, 0xC (sp)
lwz r0, 0x0014 (sp)
mtlr r0
addi sp, sp, 0x0010
blr
