!06B23458
add r3, r4, r5
rlwinm. r31, r31, 7, 22, 30
mtlr r19
lhau r30, 0xFC (r12)
psq_lux f0, r17, r3, 1, 1
and. r8, r7, r6
nop
stwu r1, 0xFFD0 (r1)
li r11, 0xFFFC
fmr f16, f27
b 0x3FFFFF8
.long 0x01010202
bl 0x18FC
slwi r5, r31, 16
lis r12, 0x8000
cmpwi cr0, r25, 0xFFFF
bclr 12, 2
