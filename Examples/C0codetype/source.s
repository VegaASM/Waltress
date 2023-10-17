!C0

addis r1, r21, 0xFFFF8234
bne- 0x1234
bgtlrl+
cmplwi cr4, r1, 0x66
mfdbat6u r12
mtictc r30
nop
psq_l f0, 0x100 (r20), 1, 5
sthx r10, r20, r30
sync
crset 7
clrlwi. r10, r15, 25
.long 0xFEDCBA98
