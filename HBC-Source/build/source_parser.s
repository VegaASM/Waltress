	.file	"source_parser.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#This function accepts source.s and removes the following..
#Double+ Enters, *not* single enters
#Enter at start of file
#Enter at end of file (before null byte ender)
#Spaces
#Tabs
#Comments (chain comments not handled yet, will crash)
#This is needed because Waltress ASM Engine needs everything stripped
#r3 source.s must end in enter then null byte!

#r3 = pointer to code.txt that ends in null
#r4 = byte size plus null

.set space, 0x20
.set enter, 0x0A
.set tab, 0x09
.set comment, 0x23

#Prologue
.globl source_parser
source_parser:
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
li r4, space

hacky_but_whatever_a:
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beq- a_start_parser #If null, stop doing this ofc
cmpwi r0, comment #Check for 1st comment symbol of line
bne+ hacky_but_whatever_a

#Now we are on a comment
#Write over comment symbol first
stb r4, 0 (r3)
#Now check for enter, once we hit enter go back to prev loop
lbzu r0, 0x1 (r3)
cmpwi r0, enter
beq- hacky_but_whatever_a
stb r4, 0 (r3)
b -0x10 #Go back to checking for enter again

#Set counter to know how much to subtract from r29 which will be used as setup for memmove r4 arg
a_start_parser:
li r6, 0

#Setup r31 for loop
addi r31, r31, -1

#Loop222
loop222:
lbzu r0, 0x1 (r31)
addi r6, r6, 1
cmpwi r0, 0
beq- source_parser_epilogue
cmpwi r0, space
beq- setup_memmoves
cmpwi r0, enter
beq- enter_handlerr
cmpwi r0, tab
bne+ loop222

#Memmove
#r3 = Destination Addr
#r4 = Source Addr
#r5 = Size in bytes
setup_memmoves:
mr r3, r31
addi r4, r31, 1
sub r30, r30, r6
mr r5, r30
bl memmove
li r6, 0 #Reset r6
subi r31, r31, 1 #Update cursor to correct spot now that contents have shifted left 1 byte
b loop222

#Enter found
#iif enter is found after this enter..
#then we do memmove
enter_handlerr:
lbz r0, 0x1 (r31)
cmpwi r0, enter
bne- loop222
#Double or Double+ enter found, remove only the next enter, we could check for further enters but fuck it this code is already messed up enough and hard to "read"
b setup_memmoves

#Epilogue
source_parser_epilogue:
lwz r30, 0x8 (sp)
lwz r31, 0xC (sp)
lwz r0, 0x0014 (sp)
mtlr r0
addi sp, sp, 0x0010
blr
