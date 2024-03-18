
#Small func that will prevent segmentations faults if there is an IMM that exceeds 8 ascii bytes in width
simm_length_ec:
.asciz "\n\nError! The above instruction has an IMM value that exceeds 8 digits in width. Please note that all spaces are stripped out. This is normal. Assembling has been rejected to prevent a segmentation fault. The 8 digit count includes leading zeroes. So be sure to remove those if that is the reason for this Error."
.align 2

.globl simm_length_checker
simm_length_checker:
stwu sp, -0x0010 (sp)
mflr r0
stw r0, 0x0014 (sp)

#Save arg, no need for GVR since theres no function calls
mr r10, r3

#Prep r3 for loop
subi r3, r3, 1

#Test whole file
simm_length_checker_ROOTLOOP:
lhzu r0, 0x1 (r3)
srwi. r4, r0, 8
beq- simm_length_checker_success #EoF reached

#Check against constant (0x)
li r5, 0x3078
cmpw r0, r5
bne+ simm_length_checker_ROOTLOOP

#Found an instance of "0x"
#Count IMM digits
addi r4, r3, 1
lbzu r0, 0x1 (r4)
cmplwi r0, 0x39
bgt- -0x8
cmplwi r0, 0x30
bge- -0x10
sub r5, r4, r3
cmplwi r5, 10 #8 digit max plus the 2 digits for "0x"
ble- simm_length_checker_ROOTLOOP

#UH OH, IMM exceeds 8 digits in width, print the instruction thats faulty
#Null out instruction's enter
mr r4, r3
lbzu r0, 0x1 (r4)
cmpwi r0, 0xA
bne+ -0x8
li r0, 0
stb r0, 0 (r4)
#Now go backwards til hit first enter or til we hit SoF-1
lbzu r0, -0x1 (r3)
cmplw r3, r10
blt- 0xC #If SoF, we want cursor at SoF-1
cmpwi r0, 0xA
bne+ -0x10
#Increment cursor by 1, and instruction is ready to print
addi r3, r3, 1
crxor 6, 6, 6
bl printf #DONT use puts
#Bad instruction printed, now return back with new string for parent to print
lis r3, simm_length_ec@h
ori r3, r3, simm_length_ec@l
b end_this_crappp

simm_length_checker_success:
li r3, 0

end_this_crappp:
lwz r0, 0x0014 (sp)
mtlr r0
addi sp, sp, 0x0010
blr
