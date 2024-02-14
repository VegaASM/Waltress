
.globl DCStoreRange
DCStoreRange:
#Make sure we actually have a size
cmplwi r4, 0
blelr-

#If address isn't 32-byte aligned, add 32 bytes to r4
clrlwi. r5, r3, 27
beq- 0x8
addi r4, r4, 0x20

#Now calculate CTR amount
addi r4, r4, 0x1F
srwi r4, r4, 5
mtctr r4

#DCBST loop
dcbst_loop:
dcbst 0, r3
addi r3, r3, 0x20
bdnz+ dcbst_loop
sync
blr
