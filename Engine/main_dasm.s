/*
    Waltress - 100% Broadway Compliant PPC Assembler+Disassembler written in PPC
    Copyright (C) 2022 Vega

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see https://www.gnu.org/licenses/gpl-3.0.txt
*/

#START ASSEMBLY

#Args
#r3 = Instruction to Decompile
#r4 = Where to store decompiled instruction

#Return values
#r3 = 0 (success)
#r3 = -1 (r4 arg is not a valid memory pointer)
#r3 = -2 (sprintf fail, should never happen)

main_dasm:

#Handy label names
.set rc, 0x00000001
.set oe, 0x00000400
.set lk, 0x00000001
.set aa, 0x00000002

#Handy macros

#Macro for sprintf pre-call so it gets auto adjust by above label name
.macro precall_sprintf
lwz r12, 0x3B8 (r10)
mtlr r12
.endm

#Following 4 macros are for instructions that use a Mask with non-zero bits in both the upper and lower 16 bits. The lower 16 bit calcuations can differ in 4 unique ways
.macro check_ins_bits_oe_yes
clrrwi r0, r31, 26
rlwinm r12, r31, 0, 22, 30
or r0, r0, r12
.endm

.macro check_ins_bits_oe_no
clrrwi r0, r31, 26
rlwinm r12, r31, 0, 21, 30
or r0, r0, r12
.endm

.macro check_ins_bits_oe_f #for some float instructions; there's no OE bit ofc but i named macro like this for ease of quick adjustments during copy-paste shit-stuff lol
clrrwi r0, r31, 26
rlwinm r12, r31, 0, 26, 30
or r0, r0, r12
.endm

.macro check_ins_bits_oe_p #for ps index/update store/loads
clrrwi r0, r31, 26
rlwinm r12, r31, 0, 25, 30
or r0, r0, r12
.endm

#Rest of macros are for sprintf r5+ arg setup. This doesn't include every unique situation. Other situations that, let's say, only occur around twice or less were left out, as a macro for those isn't justified
.macro three_items_left_aligned
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
.endm

.macro loadstore_imm
rlwinm r5, r31, 11, 0x0000001F
clrlwi r6, r31, 16
rlwinm r7, r31, 16, 0x0000001F
.endm

.macro two_items_left_aligned
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
.endm

.macro three_items_logical
rlwinm r5, r31, 16, 0x0000001F
rlwinm r6, r31, 11, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
.endm

.macro logical_imm
rlwinm r5, r31, 16, 0x0000001F
rlwinm r6, r31, 11, 0x0000001F
clrlwi r7, r31, 16
.endm

.macro nonloadstore_imm
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
clrlwi r7, r31, 16
.endm

.macro two_items_logical
rlwinm r5, r31, 16, 0x0000001F
rlwinm r6, r31, 11, 0x0000001F
.endm

.macro two_items_cache
rlwinm r5, r31, 16, 0x0000001F
rlwinm r6, r31, 21, 0x0000001F
.endm

.macro two_items_left_split
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 21, 0x0000001F
.endm

.macro three_items_compare
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
.endm

.macro four_items
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 26, 0x0000001F #Yes this is correct, fC resides at 4th/final spot
rlwinm r8, r31, 21, 0x0000001F #Yes this is correct, fB resides at 3rd spot
.endm

.macro three_items_left_split_two_one
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 26, 0x0000001F
.endm

.macro five_items_logical
rlwinm r5, r31, 16, 0x0000001F
rlwinm r6, r31, 11, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
rlwinm r8, r31, 26, 0x0000001F
rlwinm r9, r31, 31, 0x0000001F
.endm

.macro psq_index
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
rlwinm r8, r31, 22, 0x00000001
rlwinm r9, r31, 25, 0x00000007
.endm

.macro psq_imm
rlwinm r5, r31, 11, 0x0000001F
clrlwi r6, r31, 20
rlwinm r7, r31, 16, 0x0000001F
rlwinm r8, r31, 17, 0x00000001
rlwinm r9, r31, 20, 0x00000007
.endm

#Following macros are for certain load/store instructions where extra checks need to be done, after the instruction has been 'found'. If checks fail, then it's an automatic .long instruction
.macro load_int_update_doublecheck #lbzu, lhau, lhzu, lwzu
#rA =/= rD, and rA cannot be r0
cmpw r5, r7
cmpwi cr7, r7, 0
cror 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
beq- cr6, do_invalid
.endm

.macro load_int_update_index_doublecheck #lbzux, lhaux, lhzux, lwzux
#rA =/= rD, and rA cannot be r0
cmpw r5, r6
cmpwi cr7, r6, 0
cror 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
beq- cr6, do_invalid
.endm

.macro loadstorefloat_or_storeint_update_doublecheck #lfdu, lfsu, stbu, stfdu, stfsu, sthu, stwu
#rA cannot be r0
cmpwi r7, 0
beq- do_invalid
.endm

.macro loadstoreuxfloat_or_storeuxint_doublecheck #lfdux, lfsux, stbux, stfdux, stfsux, sthux, stwux
#rA cannot be r0
cmpwi r6, 0
beq- do_invalid
.endm

#Make sure r4 arg is a valid mem1 address (0x80000000 thru 0x817FFFC0; 0x90000000 thru 0x93FFFFC0)
mr r0, r3 #Temp backup r3 arg, due to possible negative return value
li r3, -1
lis r5, 0x8000
lis r6, 0x817F
ori r6, r6, 0xFFC0
addis r7, r5, 0x1000
addis r8, r6, 0x1280
cmplw r4, r5
cmplw cr5, r4, r6
cmplw cr6, r4, r7
cmplw cr7, r4, r8
cror 4*cr0+eq, 4*cr0+lt, 4*cr7+gt #Check if less than 0x80000000 or greater than 0x93FFFFC0
beqlr-
crand 4*cr0+eq, 4*cr5+gt, 4*cr6+lt #Now check if its inbetween 0x817FFFC0 & 0x90000000
beqlr-

#Restore r3
mr r3, r0

#Prologue
stwu sp, -0x0010 (sp)
mflr r0
stw r0, 0x0014 (sp)
stmw r30, 0x8 (sp)

#backup args
mr r31, r3
mr r30, r4

#Make massive lookup table; fyi capital X = Rc option
#ANDing masks for instructions, have to have every full 32-bit mask due to needing exact match for cmpw after and instruction
bl table
table_start:
.long 0x7C000214 #0 addX
.long 0x7C000014 #0x4 addcX
.long 0x7C000114 #0x8 addeX
.long 0x38000000 #0xC addi
.long 0x30000000 #0x10 addic
.long 0x34000000 #0x14 addic.
.long 0x3C000000 #0x18 addis
.long 0x7C0001D4 #0x1C addmeX
.long 0x7C000194 #0x20 addzeX
.long 0x7C000038 #0x24 andX
.long 0x7C000078 #0x28 andcX
.long 0x70000000 #0x2C andi.
.long 0x74000000 #0x30 andis.
.long 0x48000000 #0x34 bX
.long 0x40000000 #0x38 bcX
.long 0x4C000420 #0x3C bcctrX
.long 0x4C000020 #0x40 bclrX
.long 0x7C000000 #0x44 cmp
.long 0x2C000000 #0x48 cmpi
.long 0x7C000040 #0x4C cmpl
.long 0x28000000 #0x50 cmpli
.long 0x7C000034 #0x54 cntlzw
.long 0x4C000202 #0x58 crand
.long 0x4C000102 #0x5C crandc
.long 0x4C000242 #0x60 creqv
.long 0x4C0001C2 #0x64 crnand
.long 0x4C000042 #0x68 crnor
.long 0x4C000382 #0x6C cror
.long 0x4C000342 #0x70 corc
.long 0x4C000182 #0x74 crxor
.long 0x7C0000AC #0x78 dcbf
.long 0x7C0003AC #0x7C dcbi
.long 0x7C00006C #0x80 dcbst
.long 0x7C00022C #0x84 dcbt
.long 0x7C0001EC #0x88 dcbtst
.long 0x7C0007EC #0x8C dcbz
.long 0x100007EC #0x90 dcbz_l
.long 0x7C0003D6 #0x94 divwX
.long 0x7C000396 #0x98 divwuX
.long 0x7C00026C #0x9C eciwx
.long 0x7C00036C #0xA0 ecowx
.long 0x7C0006AC #0xA4 eieio
.long 0x7C000238 #0xA8 eqvX
.long 0x7C000774 #0xAC extsbX
.long 0x7C000734 #0xB0 extshX
.long 0xFC000210 #0xB4 fabsX
.long 0xFC00002A #0xB8 faddX
.long 0xEC00002A #0xBC faddsX
.long 0xFC000040 #0xC0 fcmpo
.long 0xFC000000 #0xC4 fcmpu
.long 0xFC00001C #0xC8 fctiwX
.long 0xFC00001E #0xCC fctiwzX
.long 0xFC000024 #0xD0 fdivX
.long 0xEC000024 #0xD4 fdivsX
.long 0xFC00003A #0xD8 fmaddX
.long 0xEC00003A #0xDC fmaddsX
.long 0xFC000090 #0xE0 fmrX
.long 0xFC000038 #0xE4 fmsubX
.long 0xEC000038 #0xE8 fmsubsX
.long 0xFC000032 #0xEC fmulX
.long 0xEC000032 #0xF0 fmulsX
.long 0xFC000110 #0xF4 fnabsX
.long 0xFC000050 #0xF8 fnegX
.long 0xFC00003E #0xFC fnmaddX
.long 0xEC00003E #0x100 fnmaddsX
.long 0xFC00003C #0x104 fnmsubX
.long 0xEC00003C #0x108 fnmsubsX
.long 0xEC000030 #0x10C fresX
.long 0xFC000018 #0x110 frspX
.long 0xFC000034 #0x114 frsqrte
.long 0xFC00002E #0x118 fselX
.long 0xFC000028 #0x11C fsubX
.long 0xEC000028 #0x120 fsubsX
.long 0x7C0007AC #0x124 icbi
.long 0x4C00012C #0x128 isync
.long 0x88000000 #0x12C lbz
.long 0x8C000000 #0x130 lbzu
.long 0x7C0000EE #0x134 lbzux
.long 0x7C0000AE #0x138 lbzx
.long 0xC8000000 #0x13C lfd
.long 0xCC000000 #0x140 lfdu
.long 0x7C0004EE #0x144 lfdux
.long 0x7C0004AE #0x148 lfdx
.long 0xC0000000 #0x14C lfs
.long 0xC4000000 #0x150 lfsu
.long 0x7C00046E #0x154 lfsux
.long 0x7C00042E #0x158 lfsx
.long 0xA8000000 #0x15C lha
.long 0xAC000000 #0x160 lhau
.long 0x7C0002EE #0x164 lhaux
.long 0x7C0002AE #0x168 lhax
.long 0x7C00062C #0x16C lhbrx
.long 0xA0000000 #0x170 lhz
.long 0xA4000000 #0x174 lhzu
.long 0x7C00026E #0x178 lhzux
.long 0x7C00022E #0x17C lhzx
.long 0xB8000000 #0x180 lmw
.long 0x7C0004AA #0x184 lswi
.long 0x7C00042A #0x188 lswx
.long 0x7C000028 #0x18C lwarx
.long 0x7C00042C #0x190 lwbrx
.long 0x80000000 #0x194 lwz
.long 0x84000000 #0x198 lwzu
.long 0x7C00006E #0x19C lwzux
.long 0x7C00002E #0x1A0 lwzx
.long 0x4C000000 #0x1A4 mcrf
.long 0xFC000080 #0x1A8 mcrfs
.long 0x7C000400 #0x1AC mcrxr
.long 0x7C000026 #0x1B0 mfcr
.long 0xFC00048E #0x1B4 mffsX
.long 0x7C0000A6 #0x1B8 mfmsr
.long 0x7C0002A6 #0x1BC mfspr
.long 0x7C0004A6 #0x1C0 mfsr
.long 0x7C000526 #0x1C4 mfsrin
.long 0x7C0002E6 #0x1C8 mftb
.long 0x7C000120 #0x1CC mtcrf
.long 0xFC00008C #0x1D0 mtfsb0X
.long 0xFC00004C #0x1D4 mtfsb1X
.long 0xFC00058E #0x1D8 mtfsfX
.long 0xFC00010C #0x1DC mtfsfiX
.long 0x7C000124 #0x1E0 mtmsr
.long 0x7C0003A6 #0x1E4 mtspr
.long 0x7C0001A4 #0x1E8 mtsr
.long 0x7C0001E4 #0x1EC msrin
.long 0x7C000096 #0x1F0 mulhwX
.long 0x7C000016 #0x1F4 mulhwuX
.long 0x1C000000 #0x1F8 mulli
.long 0x7C0001D6 #0x1FC mullwX
.long 0x7C0003B8 #0x200 nandX
.long 0x7C0000D0 #0x204 negX
.long 0x7C0000F8 #0x208 norX
.long 0x7C000378 #0x20C orX
.long 0x7C000338 #0x210 orcX
.long 0x60000000 #0x214 ori
.long 0x64000000 #0x218 oris
.long 0xE0000000 #0x21C psq_l
.long 0xE4000000 #0x220 psq_lu
.long 0x1000004C #0x224 psq_lux
.long 0x1000000C #0x228 psq_lx
.long 0xF0000000 #0x22C psq_st
.long 0xF4000000 #0x230 psq_stu
.long 0x1000004E #0x234 psq_stux
.long 0x1000000E #0x238 psq_stx
.long 0x10000210 #0x23C ps_absX
.long 0x1000002A #0x240 ps_addX
.long 0x10000040 #0x244 ps_cmpo0
.long 0x100000C0 #0x248 ps_cmpo1
.long 0x10000000 #0x24C ps_cmpu0
.long 0x10000080 #0x250 ps_cmpu1
.long 0x10000024 #0x254 ps_divX
.long 0x1000003A #0x258 ps_maddX
.long 0x1000001C #0x25C ps_madds0X
.long 0x1000001E #0x260 ps_madds1X
.long 0x10000420 #0x264 ps_merge00X
.long 0x10000460 #0x268 ps_merge01X
.long 0x100004A0 #0x26C ps_merge10X
.long 0x100004E0 #0x270 ps_merge11X
.long 0x10000090 #0x274 ps_mrX
.long 0x10000038 #0x278 ps_msubX
.long 0x10000032 #0x27C ps_mulX
.long 0x10000018 #0x280 ps_muls0X
.long 0x1000001A #0x284 ps_muls1X
.long 0x10000110 #0x288 ps_nabsX
.long 0x10000050 #0x28C ps_negX
.long 0x1000003E #0x290 ps_nmaddX
.long 0x1000003C #0x294 ps_nmsubX
.long 0x10000030 #0x298 ps_resX
.long 0x10000034 #0x29C ps_rsqrteX
.long 0x1000002E #0x2A0 ps_selX
.long 0x10000028 #0x2A4 ps_subX
.long 0x10000014 #0x2A8 ps_sum0X
.long 0x10000016 #0x2AC ps_sum1X
.long 0x4C000064 #0x2B0 rfi
.long 0x50000000 #0x2B4 rlwimiX
.long 0x54000000 #0x2B8 rlwinmX
.long 0x5C000000 #0x2BC rlwnmX
.long 0x44000002 #0x2C0 sc
.long 0x7C000030 #0x2C4 slwX
.long 0x7C000630 #0x2C8 srawX
.long 0x7C000670 #0x2CC srawiX
.long 0x7C000430 #0x2D0 srwX
.long 0x98000000 #0x2D4 stb
.long 0x9C000000 #0x2D8 stbu
.long 0x7C0001EE #0x2DC stbux
.long 0x7C0001AE #0x2E0 stbx
.long 0xD8000000 #0x2E4 stfd
.long 0xDC000000 #0x2E8 stfdu
.long 0x7C0005EE #0x2EC stfdux
.long 0x7C0005AE #0x2F0 stfdx
.long 0x7C0007AE #0x2F4 stfiwx
.long 0xD0000000 #0x2F8 stfs
.long 0xD4000000 #0x2FC stfsu
.long 0x7C00056E #0x300 stfsux
.long 0x7C00052E #0x304 stfsx
.long 0xB0000000 #0x308 sth
.long 0x7C00072C #0x30C sthbrx
.long 0xB4000000 #0x310 sthu
.long 0x7C00036E #0x314 sthux
.long 0x7C00032E #0x318 sthx
.long 0xBC000000 #0x31C stmw
.long 0x7C0005AA #0x320 stswi
.long 0x7C00052A #0x324 stswx
.long 0x90000000 #0x328 stw
.long 0x7C00052C #0x32C stwbrx
.long 0x7C00012D #0x330 stwcx.
.long 0x94000000 #0x334 stwu
.long 0x7C00016E #0x338 stwux
.long 0x7C00012E #0x33C stwx
.long 0x7C000050 #0x340 subfX
.long 0x7C000010 #0x344 subfcX
.long 0x7C000110 #0x348 subfeX
.long 0x20000000 #0x34C subfic
.long 0x7C0001D0 #0x350 subfmeX
.long 0x7C000190 #0x354 subfzeX
.long 0x7C0004AC #0x358 sync
.long 0x7C000264 #0x35C tlbie
.long 0x7C00046C #0x360 tlbsync
.long 0x7C000008 #0x364 tw
.long 0x0C000000 #0x368 twi
.long 0x7C000278 #0x36C xorX
.long 0x68000000 #0x370 xori
.long 0x6C000000 #0x374 xoris

#Secondary AND Masks for any instruction that have reserved (0) bits in both upper and lower 16 bits of instruction
#Noe that cmp and cmpl also includes L bit to check to make sure that is also low
.long 0x006007FF #0x378 cmp, fcmpu, ps_cmpu0
.long 0x00600001 #0x37C cmpl, fcmpo, ps_cmpo0, ps_cmpo1, ps_cmpu1
.long 0x03E00001 #0x380 dcbf, dcbi, dcbst, dcbt, dcbtst, dcbz, dcbz_l, icbi
.long 0x03FFF801 #0x384 eieio, isync, rfi, sync, tlbsync
.long 0x001F07C0 #0x388 fresX, frsqrteX, ps_resX, ps_rsqrteX
.long 0x0063FFFF #0x38C mcrf
.long 0x0063F801 #0x390 mcrfs
.long 0x007FF801 #0x394 mcrxr
.long 0x001FF801 #0x398 mfcr, mfmsr, mtmsr
.long 0x001FF800 #0x39C mffsX, mtfsb0X, mtfsb1X
.long 0x0010F801 #0x3A0 mfsr, mtsr
.long 0x001F0001 #0x3A4 mfsrin, mtsrin
.long 0x00100801 #0x3A8 mtcrf
.long 0x007F0800 #0x3AC mtfsfiX
.long 0x03FFFFFD #0x3B0 sc
.long 0x03FF0001 #0x3B4 tlbie

#NOTE the following is for sprintf function addr, software will write this to (then update cache) before the file (as a function) is called
.long 0 #0x3B8; sprintf

#Instruction decompiled ASCii strings
ins_add:
.asciz "add r%d, r%d, r%d"
ins_add_:
.asciz "add. r%d, r%d, r%d"
ins_addo:
.asciz "addo r%d, r%d, r%d"
ins_addo_:
.asciz "addo. r%d, r%d, r%d"

ins_addc:
.asciz "addc r%d, r%d, r%d"
ins_addc_:
.asciz "addc. r%d, r%d, r%d"
ins_addco:
.asciz "addco r%d, r%d, r%d"
ins_addco_:
.asciz "addco. r%d, r%d, r%d"

ins_adde:
.asciz "adde r%d, r%d, r%d"
ins_adde_:
.asciz "adde. r%d, r%d, r%d"
ins_addeo:
.asciz "addeo r%d, r%d, r%d"
ins_addeo_:
.asciz "addeo. r%d, r%d, r%d"

ins_addi:
.asciz "addi r%d, r%d, 0x%X"

ins_addic:
.asciz "addic r%d, r%d, 0x%X"

ins_addic_:
.asciz "addic. r%d, r%d, 0x%X"

ins_addis:
.asciz "addis r%d, r%d, 0x%X"

ins_addme:
.asciz "addme r%d, r%d"
ins_addme_:
.asciz "addme. r%d, r%d"
ins_addmeo:
.asciz "addmeo r%d, r%d"
ins_addmeo_:
.asciz "addmeo. r%d, r%d"

ins_addze:
.asciz "addze r%d, r%d"
ins_addze_:
.asciz "addze. r%d, r%d"
ins_addzeo:
.asciz "addzeo r%d, r%d"
ins_addzeo_:
.asciz "addzeo. r%d, r%d"

ins_and:
.asciz "and r%d, r%d, r%d"
ins_and_:
.asciz "and. r%d, r%d, r%d"

ins_andc:
.asciz "andc r%d, r%d, r%d"
ins_andc_:
.asciz "andc. r%d, r%d, r%d"

ins_andi_:
.asciz "andi. r%d, r%d, 0x%X"

ins_andis_:
.asciz "andis. r%d, r%d, 0x%X"

ins_b:
.asciz "b 0x%X"
ins_ba:
.asciz "ba 0x%X"
ins_bl:
.asciz "bl 0x%X"
ins_bla:
.asciz "bla 0x%X"

ins_bc:
.asciz "bc %d, %d, 0x%X"
ins_bca:
.asciz "bca %d, %d, 0x%X"
ins_bcl:
.asciz "bcl %d, %d, 0x%X"
ins_bcla:
.asciz "bcla %d, %d, 0x%X"

ins_bcctr:
.asciz "bcctr %d, %d"
ins_bcctrl:
.asciz "bcctrl %d, %d"
ins_bctr: #Simplified mnemonic for 'bcctr b1z1zz, Z' #z = don't care BO bit values, Z = don't care BI field
.asciz "bctr"
ins_bctrl: #Simplfied mnemonic for 'bcctrl b1z1zz, Z'
.asciz "bctrl"

ins_bclr:
.asciz "bclr %d, %d"
ins_bclrl:
.asciz "bclrl %d, %d"
ins_blr: #Simplfied mnemonic for 'bclr b1z1zz, Z' #z = dont' care BO bit values, Z = don't care BI field
.asciz "blr"
ins_blrl: #Simplified mnemonic for 'bclrl b1z1zz, Z'
.asciz "blrl"

#Standard mnemonics that include the L bit for compare instructions are not needed in disassembler
#ins_cmp:
#.asciz "cmp cr%d, %d, r%d, r%d"
ins_cmpw: #Simplified mnemonic for cmp crX, 0, rX, rY
.asciz "cmpw cr%d, r%d, r%d"

#ins_cmpi:
#.asciz "cmpi cr%d, %d, r%d, 0x%X"
ins_cmpwi: #Simplified mnemonic for cmpi crX, 0, rX, rY
.asciz "cmpwi cr%d, r%d, 0x%X"

#ins_cmpl:
#.asciz "cmpl cr%d, %d, r%d, r%d"
ins_cmplw: #Simplified mnemonic for cmpl crX, 0, rX, rY
.asciz "cmplw cr%d, r%d, r%d"

#ins_cmpli:
#.asciz "cmpli cr%d, %d, r%d, 0x%X"
ins_cmplwi: #Simplified mnemonic for cmpli crX, 0, rX, rY
.asciz "cmplwi cr%d, r%d, 0x%X"

ins_cntlzw:
.asciz "cntlzw r%d, r%d"
ins_cntlzw_:
.asciz "cntlzw. r%d, r%d"

ins_crand:
.asciz "crand %d, %d, %d"

ins_crandc:
.asciz "crandc %d, %d, %d"

ins_creqv:
.asciz "creqv %d, %d, %d"

ins_crnand:
.asciz "crnand %d, %d, %d"

ins_crnor:
.asciz "crnor %d, %d, %d"

ins_cror:
.asciz "cror %d, %d, %d"

ins_crorc:
.asciz "crorc %d, %d, %d"

ins_crxor:
.asciz "crxor %d, %d, %d"

ins_dcbf:
.asciz "dcbf r%d, r%d" #0xB18

ins_dcbi:
.asciz "dcbi r%d, r%d" #0xB38

ins_dcbst:
.asciz "dcbst r%d, r%d" #0xB58

ins_dcbt:
.asciz "dcbt r%d, r%d" #0xB78

ins_dcbtst:
.asciz "dcbtst r%d, r%d" #0xB98

ins_dcbz:
.asciz "dcbz r%d, r%d" #0xBB8

ins_dcbz_l:
.asciz "dcbz_l r%d, r%d" #0xBD8

ins_divw:
.asciz "divw r%d, r%d, r%d" #0xBF8
ins_divw_:
.asciz "divw. r%d, r%d, r%d" #0xC18
ins_divwo:
.asciz "divwo r%d, r%d, r%d" #0xC38
ins_divwo_:
.asciz "divwo. r%d, r%d, r%d" #0xC58

ins_divwu:
.asciz "divwu r%d, r%d, r%d" #0xC78
ins_divwu_:
.asciz "divwu. r%d, r%d, r%d" #0xC98
ins_divwuo:
.asciz "divwuo r%d, r%d, r%d" #0xCB8
ins_divwuo_:
.asciz "divwuo. r%d, r%d, r%d" #0xCD8

ins_eciwx:
.asciz "eciwx r%d, r%d, r%d" #0xCF8

ins_ecowx:
.asciz "ecowx r%d, r%d, r%d"

ins_eieio:
.asciz "eieio"

ins_eqv:
.asciz "eqv r%d, r%d, r%d"
ins_eqv_:
.asciz "eqv. r%d, r%d, r%d" #0xD68

ins_extsb:
.asciz "extsb r%d, r%d" #0xD88
ins_extsb_:
.asciz "extsb. r%d, r%d" #0xDA8

ins_extsh:
.asciz "extsh r%d, r%d" #0xDC8
ins_extsh_:
.asciz "extsh. r%d, r%d" #0xDE8

ins_fabs:
.asciz "fabs f%d, f%d" #0xE08
ins_fabs_:
.asciz "fabs. f%d, f%d" #0xE28

ins_fadd:
.asciz "fadd f%d, f%d, f%d" #0xE48
ins_fadd_:
.asciz "fadd. f%d, f%d, f%d" #0xE68

ins_fadds:
.asciz "fadds f%d, f%d, f%d" #0xE88
ins_fadds_:
.asciz "fadds. f%d, f%d, f%d" #0xEA8

ins_fcmpo:
.asciz "fcmpo cr%d, f%d, f%d" #0xEC8

ins_fcmpu:
.asciz "fcmpu cr%d, f%d, f%d" #0xEE8

ins_fctiw:
.asciz "fctiw f%d, f%d" #0xF08
ins_fctiw_:
.asciz "fctiw. f%d, f%d" #0xF28

ins_fctiwz:
.asciz "fctiwz f%d, f%d" #0xF48
ins_fctiwz_:
.asciz "fctiwz. f%d, f%d" #0xF68

ins_fdiv:
.asciz "fdiv f%d, f%d, f%d" #0xF88
ins_fdiv_:
.asciz "fdiv. f%d, f%d, f%d" #0xFA8

ins_fdivs:
.asciz "fdivs f%d, f%d, f%d" #0xFC8
ins_fdivs_:
.asciz "fdivs. f%d, f%d, f%d" #0xFE8

ins_fmadd:
.asciz "fmadd f%d, f%d, f%d, f%d" #0x1008
ins_fmadd_:
.asciz "fmadd. f%d, f%d, f%d, f%d" #0x1028

ins_fmadds:
.asciz "fmadds f%d, f%d, f%d, f%d" #0x1048
ins_fmadds_:
.asciz "fmadds. f%d, f%d, f%d, f%d" #0x1068

ins_fmr:
.asciz "fmr f%d, f%d" #0x1088
ins_fmr_:
.asciz "fmr. f%d, f%d" #0x10A8

ins_fmsub:
.asciz "fmsub f%d, f%d, f%d, f%d" #0x10C8
ins_fmsub_:
.asciz "fmsub. f%d, f%d, f%d, f%d" #0x10E8

ins_fmsubs:
.asciz "fmsubs f%d, f%d, f%d, f%d" #0x1108
ins_fmsubs_:
.asciz "fmsubs. f%d, f%d, f%d, f%d" #0x1128

ins_fmul:
.asciz "fmul f%d, f%d, f%d" #0x1148
ins_fmul_:
.asciz "fmul. f%d, f%d, f%d" #0x1168

ins_fmuls:
.asciz "fmuls f%d, f%d, f%d" #0x1188
ins_fmuls_:
.asciz "fmuls. f%d, f%d, f%d" #0x11A8

ins_fnabs:
.asciz "fnabs f%d, f%d" #0x11C8
ins_fnabs_:
.asciz "fnabs. f%d, f%d" #0x11E8

ins_fneg:
.asciz "fneg f%d, f%d" #0x1208
ins_fneg_:
.asciz "fneg. f%d, f%d" #0x1228

ins_fnmadd:
.asciz "fnmadd f%d, f%d, f%d, f%d" #0x1248
ins_fnmadd_:
.asciz "fnmadd. f%d, f%d, f%d, f%d" #0x1268

ins_fnmadds:
.asciz "fnmadds f%d, f%d, f%d, f%d" #0x1288
ins_fnmadds_:
.asciz "fnmadds. f%d, f%d, f%d, f%d" #0x12A8

ins_fnmsub:
.asciz "fnmsub f%d, f%d, f%d, f%d" #0x12C8
ins_fnmsub_:
.asciz "fnmsub. f%d, f%d, f%d, f%d" #0x12E8

ins_fnmsubs:
.asciz "fnmsubs f%d, f%d, f%d, f%d" #0x1308
ins_fnmsubs_:
.asciz "fnmsubs. f%d, f%d, f%d, f%d" #0x1328

ins_fres:
.asciz "fres f%d, f%d" #0x1348
ins_fres_:
.asciz "fres. f%d, f%d" #0x1368

ins_frsp:
.asciz "frsp f%d, f%d" #0x1388
ins_frsp_:
.asciz "frsp. f%d, f%d" #0x13A8

ins_frsqrte:
.asciz "frsqrte f%d, f%d" #0x13C8
ins_frsqrte_:
.asciz "frsqrte. f%d, f%d" #0x13E8

ins_fsel:
.asciz "fsel f%d, f%d, f%d, f%d" #0x1408
ins_fsel_:
.asciz "fsel. f%d, f%d, f%d, f%d" #0x1428

ins_fsub:
.asciz "fsub f%d, f%d, f%d" #0x1448
ins_fsub_:
.asciz "fsub. f%d, f%d, f%d" #0x1468

ins_fsubs:
.asciz "fsubs f%d, f%d, f%d" #0x1488
ins_fsubs_:
.asciz "fsubs. f%d, f%d, f%d" #0x14A8

ins_icbi:
.asciz "icbi r%d, r%d" #0x14C8

ins_isync:
.asciz "isync"

ins_lbz:
.asciz "lbz r%d, 0x%X (r%d)"

ins_lbzu:
.asciz "lbzu r%d, 0x%X (r%d)" #0x1518

ins_lbzux:
.asciz "lbzux r%d, r%d, r%d" #0x1538

ins_lbzx:
.asciz "lbzx r%d, r%d, r%d" #0x1558

ins_lfd:
.asciz "lfd f%d, 0x%X (r%d)" #0x1578

ins_lfdu:
.asciz "lfdu f%d, 0x%X (r%d)" #0x1598

ins_lfdux:
.asciz "lfdux f%d, r%d, r%d" #0x15B8

ins_lfdx:
.asciz "lfdx f%d, r%d, r%d" #0x15D8

ins_lfs:
.asciz "lfs f%d, 0x%X (r%d)" #0x15F8

ins_lfsu:
.asciz "lfsu f%d, 0x%X (r%d)" #0x1618

ins_lfsux:
.asciz "lfsux f%d, r%d, r%d" #0x1638

ins_lfsx:
.asciz "lfsx f%d, r%d, r%d" #0x1658

ins_lha:
.asciz "lha r%d, 0x%X (r%d)" #0x1678

ins_lhau:
.asciz "lhau r%d, 0x%X (r%d)" #0x1698

ins_lhaux:
.asciz "lhaux r%d, r%d, r%d" #0x16B8

ins_lhax:
.asciz "lhax r%d, r%d, r%d" #0x16D8

ins_lhbrx:
.asciz "lhbrx r%d, r%d, r%d" #0x16F8

ins_lhz:
.asciz "lhz r%d, 0x%X (r%d)" #0x1718

ins_lhzu:
.asciz "lhzu r%d, 0x%X (r%d)" #0x1738

ins_lhzux:
.asciz "lhzux r%d, r%d, r%d" #0x1758

ins_lhzx:
.asciz "lhzx r%d, r%d, r%d" #0x1778

ins_li: #Simplified mnemonic for addi rX, r0, 0xXXXX
.asciz "li r%d, 0x%X"
ins_lis: #Simplified mnemonic for addis rX, r0, 0xXXXX
.asciz "lis r%d, 0x%X"

ins_lmw:
.asciz "lmw r%d, 0x%X (r%d)" #0x1798

ins_lswi:
.asciz "lswi r%d, r%d, %d" #0x17B8

ins_lswx:
.asciz "lswx r%d, r%d, r%d" #0x17D8

ins_lwarx:
.asciz "lwarx r%d, r%d, r%d" #0x17F8

ins_lwbrx:
.asciz "lwbrx r%d, r%d, r%d" #0x1818

ins_lwz:
.asciz "lwz r%d, 0x%X (r%d)" #0x1838

ins_lwzu:
.asciz "lwzu r%d, 0x%X (r%d)" #0x1858

ins_lwzux:
.asciz "lwzux r%d, r%d, r%d" #0x1878

ins_lwzx:
.asciz "lwzx r%d, r%d, r%d" #0x1898

ins_mcrf:
.asciz "mcrf cr%d, cr%d" #0x18B8

ins_mcrfs:
.asciz "mcrfs cr%d, cr%d" #0x18D8

ins_mcrxr:
.asciz "mcrxr cr%d" #0x18F8

ins_mfcr:
.asciz "mfcr r%d" #0x1918

ins_mffs:
.asciz "mffs f%d" #0x1938
ins_mffs_:
.asciz "mffs. f%d" #0x1958

ins_mfmsr:
.asciz "mfmsr r%d" #0x1978

ins_mfspr:
.asciz "mfspr r%d, %d" #0x1998

ins_mfsr:
.asciz "mfsr r%d, %d" #0x19B8

ins_mfsrin:
.asciz "mfsrin r%d, r%d" #0x19D8

#ins_mftb: #Not needed for disassembler
#.asciz "mftb r%d, %d"

#Following are mftb simplifed mnemonics, first is unused for disassembler
#ins_mftb_simp: #Simplified mnemonic for mftb rD, 268
#.asciz "mftb r%d"
ins_mftbl: #Same thing as above
.asciz "mftbl r%d"
ins_mftbu: #Simplified mnemonic for mftb rD, 269
.asciz "mftbu r%d"

ins_mr: #Simplified mnemonic for or rA, rS, rS
.asciz "mr r%d, r%d"
ins_mr_: #Simplified mnemonic for or. rA, rS, rS
.asciz "mr. r%d, r%d"

ins_mtcrf:
.asciz "mtcrf 0x%X, r%d" #0x1A18
ins_mtcr: #Simplified mnemonic for mtcrfs 0xFF, rS
.asciz "mtcr r%d"

ins_mtfsb0:
.asciz "mtfsb0 %d" #0x1A38
ins_mtfsb0_:
.asciz "mtfsb0. %d" #0x1A58

ins_mtfsb1:
.asciz "mtfsb1 %d" #0x1A78
ins_mtfsb1_:
.asciz "mtfsb1. %d" #0x1A98

ins_mtfsf:
.asciz "mtfsf 0x%X, f%d" #0x1AB8
ins_mtfsf_:
.asciz "mtfsf. 0x%X, f%d" #0x1AD8

ins_mtfsfi:
.asciz "mtfsfi cr%d, %d" #0x1AF8
ins_mtfsfi_:
.asciz "mtfsfi. cr%d, %d" #0x1B18

ins_mtmsr:
.asciz "mtmsr r%d" #0x1B38

ins_mtspr:
.asciz "mtspr %d, r%d" #0x1B58

ins_mtsr:
.asciz "mtsr %d, r%d" #0x1B78

ins_mtsrin:
.asciz "mtsrin r%d, r%d" #0x1B98

ins_mulhw:
.asciz "mulhw r%d, r%d, r%d" #0x1BB8
ins_mulhw_:
.asciz "mulhw. r%d, r%d, r%d" #0x1BD8

ins_mulhwu:
.asciz "mulhwu r%d, r%d, r%d" #0x1BF8
ins_mulhwu_:
.asciz "mulhwu. r%d, r%d, r%d" #0x1C18

ins_mulli:
.asciz "mulli r%d, r%d, 0x%X" #0x1C38

ins_mullw:
.asciz "mullw r%d, r%d, r%d" #0x1C58
ins_mullw_:
.asciz "mullw. r%d, r%d, r%d" #0x1C78
ins_mullwo:
.asciz "mullwo r%d, r%d, r%d" #0x1C98
ins_mullwo_:
.asciz "mullwo. r%d, r%d, r%d" #0x1CB8

ins_nand:
.asciz "nand r%d, r%d, r%d" #0x1CD8
ins_nand_:
.asciz "nand. r%d, r%d, r%d" #0x1CF8

ins_neg:
.asciz "neg r%d, r%d" #0x1D18
ins_neg_:
.asciz "neg. r%d, r%d" #0x1D38
ins_nego:
.asciz "nego r%d, r%d" #0x1D58
ins_nego_:
.asciz "nego. r%d, r%d" #0x1D78

ins_nor:
.asciz "nor r%d, r%d, r%d" #0x1D98
ins_nor_:
.asciz "nor. r%d, r%d, r%d" #0x1DB8

ins_not: #Simplified mnemonic for nor rA, rS, rS
.asciz "not r%d, r%d"
ins_not_: #Simplified mnemonic for nor. rA, rS, rS
.asciz "not. r%d, r%d"

ins_nop: #Simplified mnemonic for ori r0, r0, 0x0000
.asciz "nop"

ins_or:
.asciz "or r%d, r%d, r%d" #0x1DD8
ins_or_:
.asciz "or. r%d, r%d, r%d" #0x1DF8

ins_orc:
.asciz "orc r%d, r%d, r%d" #0x1E18
ins_orc_:
.asciz "orc. r%d, r%d, r%d" #0x1E38

ins_ori:
.asciz "ori r%d, r%d, 0x%X" #0x1E58

ins_oris:
.asciz "oris r%d, r%d, 0x%X" #0x1E78

ins_psq_l:
.asciz "psq_l f%d, 0x%X (r%d), %d, %d" #0x1E98

ins_psq_lu:
.asciz "psq_lu f%d, 0x%X (r%d), %d, %d" #0x1ED8

ins_psq_lux:
.asciz "psq_lux f%d, r%d, r%d, %d, %d" #0x1F18

ins_psq_lx:
.asciz "psq_lx f%d, r%d, r%d, %d, %d" #0x1F58

ins_psq_st:
.asciz "psq_st f%d, 0x%X (r%d), %d, %d" #0x1F98

ins_psq_stu:
.asciz "psq_stu f%d, 0x%X (r%d), %d, %d" #0x1FD8

ins_psq_stux:
.asciz "psq_stux f%d, r%d, r%d, %d, %d" #0x2018

ins_psq_stx:
.asciz "psq_stx f%d, r%d, r%d, %d, %d" #0x2058

ins_ps_abs:
.asciz "ps_abs f%d, f%d" #0x2098;
ins_ps_abs_:
.asciz "ps_abs. f%d, f%d" #0x20B8

ins_ps_add:
.asciz "ps_add f%d, f%d, f%d" #0x20D8
ins_ps_add_:
.asciz "ps_add. f%d, f%d, f%d" #0x20F8

ins_ps_cmpo0:
.asciz "ps_cmpo0 cr%d, f%d, f%d" #0x2118

ins_ps_cmpo1:
.asciz "ps_cmpo1 cr%d, f%d, f%d" #0x2138

ins_ps_cmpu0:
.asciz "ps_cmpu0 cr%d, f%d, f%d" #0x2158

ins_ps_cmpu1:
.asciz "ps_cmpu1 cr%d, f%d, f%d" #0x2178

ins_ps_div:
.asciz "ps_div f%d, f%d, f%d" #0x2198
ins_ps_div_:
.asciz "ps_div. f%d, f%d, f%d" #0x21B8

ins_ps_madd:
.asciz "ps_madd f%d, f%d, f%d, f%d" #0x21D8
ins_ps_madd_:
.asciz "ps_madd. f%d, f%d, f%d, f%d" #0x21F8

ins_ps_madds0:
.asciz "ps_madds0 f%d, f%d, f%d, f%d" #0x2218
ins_ps_madds0_:
.asciz "ps_madds0. f%d, f%d, f%d, f%d" #0x2238

ins_ps_madds1:
.asciz "ps_madds1 f%d, f%d, f%d, f%d" #0x2258
ins_ps_madds1_:
.asciz "ps_madds1. f%d, f%d, f%d, f%d" #0x2278

ins_ps_merge00:
.asciz "ps_merge00 f%d, f%d, f%d" #0x2298
ins_ps_merge00_:
.asciz "ps_merge00. f%d, f%d, f%d" #0x22B8

ins_ps_merge01:
.asciz "ps_merge01 f%d, f%d, f%d" #0x22D8
ins_ps_merge01_:
.asciz "ps_merge01. f%d, f%d, f%d" #0x22F8

ins_ps_merge10:
.asciz "ps_merge10 f%d, f%d, f%d" #0x2318
ins_ps_merge10_:
.asciz "ps_merge10. f%d, f%d, f%d" #0x2338

ins_ps_merge11:
.asciz "ps_merge11 f%d, f%d, f%d" #0x2358
ins_ps_merge11_:
.asciz "ps_merge11. f%d, f%d, f%d" #0x2378

ins_ps_mr:
.asciz "ps_mr f%d, f%d" #0x2398
ins_ps_mr_:
.asciz "ps_mr. f%d, f%d" #0x23B8

ins_ps_msub:
.asciz "ps_msub f%d, f%d, f%d, f%d" #0x23D8
ins_ps_msub_:
.asciz "ps_msub. f%d, f%d, f%d, f%d" #0x23F8

ins_ps_mul:
.asciz "ps_mul f%d, f%d, f%d" #0x2418
ins_ps_mul_:
.asciz "ps_mul. f%d, f%d, f%d" #0x2438

ins_ps_muls0:
.asciz "ps_muls0 f%d, f%d, f%d" #0x2458
ins_ps_muls0_:
.asciz "ps_muls0. f%d, f%d, f%d" #0x2478

ins_ps_muls1:
.asciz "ps_muls1 f%d, f%d, f%d" #0x2498
ins_ps_muls1_:
.asciz "ps_muls1. f%d, f%d, f%d" #0x24B8

ins_ps_nabs:
.asciz "ps_nabs f%d, f%d" #0x24D8
ins_ps_nabs_:
.asciz "ps_nabs. f%d, f%d" #0x24F8

ins_ps_neg:
.asciz "ps_neg f%d, f%d" #0x2518
ins_ps_neg_:
.asciz "ps_neg. f%d, f%d" #0x2538

ins_ps_nmadd:
.asciz "ps_nmadd f%d, f%d, f%d, f%d" #0x2558
ins_ps_nmadd_:
.asciz "ps_nmadd. f%d, f%d, f%d, f%d" #0x2578

ins_ps_nmsub:
.asciz "ps_nmsub f%d, f%d, f%d, f%d" #0x2598
ins_ps_nmsub_:
.asciz "ps_nmsub. f%d, f%d, f%d, f%d" #0x25B8

ins_ps_res:
.asciz "ps_res f%d, f%d" #0x25D8
ins_ps_res_:
.asciz "ps_res. f%d, f%d" #0x25F8

ins_ps_rsqrte:
.asciz "ps_rsqrte f%d, f%d" #0x2618
ins_ps_rsqrte_:
.asciz "ps_rsqrte. f%d, f%d" #0x2638

ins_ps_sel:
.asciz "ps_sel f%d, f%d, f%d, f%d" #0x2658
ins_ps_sel_:
.asciz "ps_sel. f%d, f%d, f%d, f%d" #0x2678

ins_ps_sub:
.asciz "ps_sub f%d, f%d, f%d" #0x2698
ins_ps_sub_:
.asciz "ps_sub. f%d, f%d, f%d" #0x26B8

ins_ps_sum0:
.asciz "ps_sum0 f%d, f%d, f%d, f%d" #0x26D8
ins_ps_sum0_:
.asciz "ps_sum0. f%d, f%d, f%d, f%d" #0x26F8

ins_ps_sum1:
.asciz "ps_sum1 f%d, f%d, f%d, f%d" #0x2718
ins_ps_sum1_:
.asciz "ps_sum1. f%d, f%d, f%d, f%d" #0x2738

ins_rfi:
.asciz "rfi" #0x2758

ins_rlwimi:
.asciz "rlwimi r%d, r%d, %d, %d, %d" #0x2768;
ins_rlwimi_:
.asciz "rlwimi. r%d, r%d, %d, %d, %d" #0x2788

ins_rlwinm:
.asciz "rlwinm r%d, r%d, %d, %d, %d" #0x27A8
ins_rlwinm_:
.asciz "rlwinm. r%d, r%d, %d, %d, %d" #0x27C8

ins_rlwnm:
.asciz "rlwnm r%d, r%d, r%d, %d, %d" #0x27E8
ins_rlwnm_:
.asciz "rlwnm. r%d, r%d, r%d, %d, %d" #0x2808

ins_sc:
.asciz "sc" #0x2828

ins_slw:
.asciz "slw r%d, r%d, r%d" #0x2838;
ins_slw_:
.asciz "slw. r%d, r%d, r%d" #0x2858

ins_sraw:
.asciz "sraw r%d, r%d, r%d" #0x2878
ins_sraw_:
.asciz "sraw. r%d, r%d, r%d" #0x2898

ins_srawi:
.asciz "srawi r%d, r%d, %d" #0x28B8
ins_srawi_:
.asciz "srawi. r%d, r%d, %d" #0x28D8

ins_srw:
.asciz "srw r%d, r%d, r%d" #0x28F8
ins_srw_:
.asciz "srw. r%d, r%d, r%d" #0x2918

ins_stb:
.asciz "stb r%d, 0x%X (r%d)" #0x2938

ins_stbu:
.asciz "stbu r%d, 0x%X (r%d)" #0x2958

ins_stbux:
.asciz "stbux r%d, r%d, r%d" #0x2978

ins_stbx:
.asciz "stbx r%d, r%d, r%d" #0x2998

ins_stfd:
.asciz "stfd f%d, 0x%X (r%d)" #0x29B8

ins_stfdu:
.asciz "stfdu f%d, 0x%X (r%d)" #0x29D8

ins_stfdux:
.asciz "stfdux f%d, r%d, r%d" #0x29F8

ins_stfdx:
.asciz "stfdx f%d, r%d, r%d" #0x2A18

ins_stfiwx:
.asciz "stfiwx f%d, r%d, r%d" #0x2A38

ins_stfs:
.asciz "stfs f%d, 0x%X (r%d)" #0x2A58

ins_stfsu:
.asciz "stfsu f%d, 0x%X (r%d)" #0x2A78

ins_stfsux:
.asciz "stfsux f%d, r%d, r%d" #0x2A98

ins_stfsx:
.asciz "stfsx f%d, r%d, r%d" #0x2AB8

ins_sth:
.asciz "sth r%d, 0x%X (r%d)"

ins_sthbrx:
.asciz "sthbrx r%d, r%d, r%d"

ins_sthu:
.asciz "sthu r%d, 0x%X (r%d)"

ins_sthux:
.asciz "sthux r%d, r%d, r%d"

ins_sthx:
.asciz "sthx r%d, r%d, r%d"

ins_stmw:
.asciz "stmw r%d, 0x%X (r%d)"

ins_stswi:
.asciz "stswi r%d, r%d, %d"

ins_stswx:
.asciz "stswx r%d, r%d, r%d"

ins_stw:
.asciz "stw r%d, 0x%X (r%d)"

ins_stwbrx:
.asciz "stwbrx r%d, r%d, r%d"

ins_stwcx_:
.asciz "stwcx. r%d, r%d, r%d"

ins_stwu:
.asciz "stwu r%d, 0x%X (r%d)"

ins_stwux:
.asciz "stwux r%d, r%d, r%d"

ins_stwx:
.asciz "stwx r%d, r%d, r%d"

#ins_subf: #NOT NEEDED in the disassembler
#.asciz "subf r%d, r%d, r%d"
#ins_subf_:
#.asciz "subf. r%d, r%d, r%d"
#ins_subfo:
#.asciz "subfo r%d, r%d, r%d"
#ins_subfo_:
#.asciz "subfo. r%d, r%d, r%d"

#Simplified mnemonics for subfX rD, rB, rA
ins_sub:
.asciz "sub r%d, r%d, r%d"
ins_sub_:
.asciz "sub. r%d, r%d, r%d"
ins_subo:
.asciz "subo r%d, r%d, r%d"
ins_subo_:
.asciz "subo. r%d, r%d, r%d"

#ins_subfc: #NOT NEEDED in the disassembler
#.asciz "subfc r%d, r%d, r%d"
#ins_subfc_:
#.asciz "subfc. r%d, r%d, r%d"
#ins_subfco:
#.asciz "subfco r%d, r%d, r%d"
#ins_subfco_:
#.asciz "subfco. r%d, r%d, r%d"

#Simplified mnemonics for subfcX rD, rB, rA
ins_subc:
.asciz "subc r%d, r%d, r%d"
ins_subc_:
.asciz "subc. r%d, r%d, r%d"
ins_subco:
.asciz "subco r%d, r%d, r%d"
ins_subco_:
.asciz "subco. r%d, r%d, r%d"

ins_subfe:
.asciz "subfe r%d, r%d, r%d"
ins_subfe_:
.asciz "subfe. r%d, r%d, r%d"
ins_subfeo:
.asciz "subfeo r%d, r%d, r%d"
ins_subfeo_:
.asciz "subfeo. r%d, r%d, r%d"

ins_subfic:
.asciz "subfic r%d, r%d, 0x%X"

ins_subfme:
.asciz "subfme r%d, r%d"
ins_subfme_:
.asciz "subfme. r%d, r%d"
ins_subfmeo:
.asciz "subfmeo r%d, r%d"
ins_subfmeo_:
.asciz "subfmeo. r%d, r%d"

ins_subfze:
.asciz "subfze r%d, r%d"
ins_subfze_:
.asciz "subfze. r%d, r%d"
ins_subfzeo:
.asciz "subfzeo r%d, r%d"
ins_subfzeo_:
.asciz "subfzeo. r%d, r%d"

ins_sync:
.asciz "sync"

ins_tlbie:
.asciz "tlbie r%d"

ins_tlbsync:
.asciz "tlbsync"

ins_trap: #Simplified mnemonic for tw 31, rA, rB
.asciz "trap"

ins_tw:
.asciz "tw %d, r%d, r%d"

ins_twi:
.asciz "twi %d, r%d, 0x%X"

ins_xor:
.asciz "xor r%d, r%d, r%d"
ins_xor_:
.asciz "xor. r%d, r%d, r%d"

ins_xori:
.asciz "xori r%d, r%d, 0x%X"

ins_xoris:
.asciz "xoris r%d, r%d, 0x%X"

#Following are mfspr simplified mnemonics, rather have these in a group than placed in alphabetically
ins_mfxer:
.asciz "mfxer r%d"
ins_mflr:
.asciz "mflr r%d"
ins_mfctr:
.asciz "mfctr r%d"

#Following are mtspr simplified mnemonics, rather have these in a group than placed in alphabetically
ins_mtxer:
.asciz "mtxer r%d"
ins_mtlr:
.asciz "mtlr r%d"
ins_mtctr:
.asciz "mtctr r%d"

#Following are CR simplified mnemonics
ins_crset:
.asciz "crset %d" #creqv d, d, d
ins_crnot:
.asciz "crnot %d, %d" #crnor d, a, a
ins_crmove:
.asciz "crmove %d, %d" #cror d, a, a
ins_crclr:
.asciz "crclr %d" #crxor d, d, d

#Following are SOME rlwinmX simplified mnemonics
ins_slwi: #Simplified mnemonic for rlwinm rX, rY, b, 0, 31-b
.asciz "slwi r%d, r%d, %d"
ins_slwi_:
.asciz "slwi. r%d, r%d, %d"
ins_srwi: #Simplified mnemonic for rlwinm rX, rY, 32-b, b, 31
.asciz "srwi r%d, r%d, %d"
ins_srwi_:
.asciz "srwi. r%d, r%d, %d"
ins_clrlwi: #Simplified mnemonic for rlwinm rX, rY, 0, b, 31
.asciz "clrlwi r%d, r%d, %d"
ins_clrlwi_:
.asciz "clrlwi. r%d, r%d, %d"
ins_clrrwi: #Simplified mnemonic for rlwinm rX, rY, 0, 0, 31-b
.asciz "clrrwi r%d, r%d, %d"
ins_clrrwi_:
.asciz "clrrwi. r%d, r%d, %d"
ins_rotlwi: #Simplified mnemonic for rlwinm rX, rY, b, 0, 31
.asciz "rotlwi r%d, r%d, %d"
ins_rotlwi_:
.asciz "rotlwi. r%d, r%d, %d"

#Simplified mnemonic for rlwnmX
ins_rotlw: #Simplified mnemonic for rlwnm rX, rY, rZ, 0, 31
.asciz "rotlw r%d, r%d, r%d"
ins_rotlw_:
.asciz "rotlw. r%d, r%d, r%d"

#No valid instruction
invalid_instruction:
.asciz ".long 0x%08X"
.align 2

table:
mflr r10

#Load AND mask and see if we found our instruction

#Check for addX
lwz r11, 0 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_addcX

#addX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_add - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_add_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_addo - table_start
beq- epilogue_main
addi r4, r10, ins_addo_ - table_start
b epilogue_main

#Check for addcX
check_addcX:
lwz r11, 0x4 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_addeX

#addcX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_addc - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_addc_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_addco - table_start
beq- epilogue_main
addi r4, r10, ins_addco_ - table_start
b epilogue_main

#Check for addeX
check_addeX:
lwz r11, 0x8 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_addi

#addeX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_adde - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_adde_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_addeo - table_start
beq- epilogue_main
addi r4, r10, ins_addeo_ - table_start
b epilogue_main

#Check for addi
check_addi:
lwz r11, 0xC (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_addic

#addi found (HOWEVER check for li as well)
nonloadstore_imm
#It's li if rA = r0. which meeans r6 = 0 from nonloadstore_imm
cmpwi r6, 0
bne- not_li
mr r6, r7 #Don't need rA (r6)
addi r4, r10, ins_li - table_start
b epilogue_main
not_li:
addi r4, r10, ins_addi - table_start
b epilogue_main

#Check for addic
check_addic:
lwz r11, 0x10 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_addic_

#addic found
nonloadstore_imm
addi r4, r10, ins_addic - table_start
b epilogue_main

#Check for addic.
check_addic_:
lwz r11, 0x14 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_addis

#addic. found
nonloadstore_imm
addi r4, r10, ins_addic_ - table_start
b epilogue_main

#Check for addis
check_addis:
lwz r11, 0x18 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_addmeX

#addis found (HOWEVER check for lis as well)
nonloadstore_imm
#It's lis if rA = r0. which meeans r6 = 0 from nonloadstore_imm
cmpwi r6, 0
bne- not_lis
mr r6, r7 #Don't need rA (r6)
addi r4, r10, ins_lis - table_start
b epilogue_main
not_lis:
addi r4, r10, ins_addis - table_start
b epilogue_main

#Check for addmeX
check_addmeX:
lwz r6, 0x1C (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne- cr6, check_addzeX

#addmeX found
andi. r0, r31, oe | rc
two_items_left_aligned
addi r4, r10, ins_addme - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_addme_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_addmeo - table_start
beq- epilogue_main
addi r4, r10, ins_addmeo_ - table_start
b epilogue_main

#Check for addzeX
check_addzeX:
lwz r6, 0x20 (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_andX

#addzeX found
andi. r0, r31, oe | rc
two_items_left_aligned
addi r4, r10, ins_addze - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_addze_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_addzeo - table_start
beq- epilogue_main
addi r4, r10, ins_addzeo_ - table_start
b epilogue_main

#Check for andX
check_andX:
lwz r11, 0x24 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_andcX

#andX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_and - table_start
beq- epilogue_main
addi r4, r10, ins_and_ - table_start
b epilogue_main

#Check for andcX
check_andcX:
lwz r11, 0x28 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_andi_

#andcX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_andc - table_start
beq- epilogue_main
addi r4, r10, ins_andc_ - table_start
b epilogue_main

#Check for andi.
check_andi_:
lwz r11, 0x2C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_andis_

#andi. found
logical_imm
addi r4, r10, ins_andi_ - table_start
b epilogue_main

#Check for andis.
check_andis_:
lwz r11, 0x30 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_bX

#andis. found
logical_imm
addi r4, r10, ins_andis_ - table_start
b epilogue_main

#Check for bX
check_bX:
lwz r11, 0x34 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_bcX

#bX found
andi. r0, r31, aa | lk
rlwinm r5, r31, 0, 6, 29
addi r4, r10, ins_b - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_ba - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bl - table_start
beq- epilogue_main
addi r4, r10, ins_bla - table_start
b epilogue_main

#Check for bcX
check_bcX:
lwz r11, 0x38 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_bcctrX

#bcX found
andi. r0, r31, aa | lk
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 0, 16, 29
addi r4, r10, ins_bc - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bca - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bcl - table_start
beq- epilogue_main
addi r4, r10, ins_bcla - table_start
b epilogue_main

#Check for bcctrX
check_bcctrX:
lwz r6, 0x3C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_bclrX

#bcctrX found (HOWEVER check for bctrX first)
#Will be bctrX if BO field is 0x14 after AND'ing
andi. r0, r31, lk
two_items_left_aligned
#Check for bctrX
li r0, 0x14 #BO field 1z1zz; z = don't care values
and r12, r5, r0 #No RC bit used, KEEP cr0 intact for lk check!
cmpw cr7, r12, r0 #r12 must equal 0x14, KEEP cr0 intact for lk check!
bne- cr7, standard_bcctrX
addi r4, r10, ins_bctr - table_start
beq- epilogue_main
addi r4, r10, ins_bctrl - table_start
b epilogue_main
#bctrX not found
standard_bcctrX:
addi r4, r10, ins_bcctr - table_start
beq- epilogue_main
addi r4, r10, ins_bcctrl - table_start
b epilogue_main

#Check for bclrX
check_bclrX:
lwz r6, 0x40 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_cmpw

#bclrX found (HOWEVER check for blrX first)
#Will be blrX if BO field is 0x14 after AND'ing
andi. r0, r31, lk
two_items_left_aligned
#Check for blrX
li r0, 0x14 #BO field 1z1zz; z = don't care values
and r12, r5, r0 #No RC bit used, KEEP cr0 intact for lk check!
cmpw cr7, r12, r0 #r12 must equal 0x14, KEEP cr0 intact for lk check!
bne- cr7, standard_bclrX
addi r4, r10, ins_blr - table_start
beq- epilogue_main
addi r4, r10, ins_blrl - table_start
b epilogue_main
#bctrX not found
standard_bclrX:
addi r4, r10, ins_bclr - table_start
beq- epilogue_main
addi r4, r10, ins_bclrl - table_start
b epilogue_main

#Check for cmpw
check_cmpw:
lwz r6, 0x44 (r10)
clrrwi r0, r31, 26
cmpw cr7, r0, r6
lwz r0, 0x378 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_cmpwi

#cmpw found
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
addi r4, r10, ins_cmpw - table_start
b epilogue_main

#Check for cmpwi
check_cmpwi:
lwz r6, 0x48 (r10)
clrrwi r0, r31, 26
cmpw cr7, r0, r6
andis. r0, r31, 0x0060
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_cmplw

#cmpwi found
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 16, 0x0000001F
clrlwi r7, r31, 16
addi r4, r10, ins_cmpwi - table_start
b epilogue_main

#Check for cmplw
check_cmplw:
lwz r6, 0x4C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x37C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_cmplwi

#cmplw found
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 21, 0x0000001F
addi r4, r10, ins_cmplw - table_start
b epilogue_main

#Check for cmplwi
check_cmplwi:
lwz r6, 0x50 (r10)
clrrwi r0, r31, 26
cmpw cr7, r0, r6
andis. r0, r31, 0x0060
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_cntlzwX

#cmplwi found
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 16, 0x0000001F
clrlwi r7, r31, 16
addi r4, r10, ins_cmplwi - table_start
b epilogue_main

#Check for cntlzwX
check_cntlzwX:
lwz r6, 0x54 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_crand

#cntlzwX found
andi. r0, r31, rc
two_items_logical
addi r4, r10, ins_cntlzw - table_start
beq- epilogue_main
addi r4, r10, ins_cntlzw_ - table_start
b epilogue_main

#Check for crand
check_crand:
lwz r6, 0x58 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_crandc

#crand found
three_items_left_aligned
addi r4, r10, ins_crand - table_start
b epilogue_main

#Check for crandc
check_crandc:
lwz r6, 0x5C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_creqv

#crandc found
three_items_left_aligned
addi r4, r10, ins_crandc - table_start
b epilogue_main

#Check for creqv
check_creqv:
lwz r6, 0x60 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_crnand

#creqv found (HOWEVER check for crset first; all crb's must be equal)
three_items_left_aligned
cmpw r5, r6
cmpw cr7, r5, r7
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, not_crset
addi r4, r10, ins_crset - table_start
b epilogue_main
not_crset:
addi r4, r10, ins_creqv - table_start
b epilogue_main

#Check for crnand
check_crnand:
lwz r6, 0x64 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_crnor

#crnand found
three_items_left_aligned
addi r4, r10, ins_crnand - table_start
b epilogue_main

#Check for crnor
check_crnor:
lwz r6, 0x68 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_cror

#crnor found (HOWEVER check for crnot first, crbA and crbB must be equal)
three_items_left_aligned
cmpw r6, r7
bne+ not_crnot
addi r4, r10, ins_crnot - table_start
b epilogue_main
not_crnot:
addi r4, r10, ins_crnor - table_start
b epilogue_main

#Check for cror
check_cror:
lwz r6, 0x6C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_crorc

#cror found (HOWEVER check for crmove first, crbA and crbB must be equal)
three_items_left_aligned
cmpw r6, r7
bne+ not_crmove
addi r4, r10, ins_crmove - table_start
b epilogue_main
not_crmove:
addi r4, r10, ins_cror - table_start
b epilogue_main

#Check for crorc
check_crorc:
lwz r6, 0x70 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_crxor

#crorc found
three_items_left_aligned
addi r4, r10, ins_crorc - table_start
b epilogue_main

#Check for crxor
check_crxor:
lwz r6, 0x74 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbf

#crxor found (HOWEVER check for crclr first, all crb's must be equal)
three_items_left_aligned
cmpw r5, r6
cmpw cr7, r5, r7
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, not_crclr
addi r4, r10, ins_crclr - table_start
b epilogue_main
not_crclr:
addi r4, r10, ins_crxor - table_start
b epilogue_main

#Check for dcbf
check_dcbf:
lwz r6, 0x78 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbi

#dcbf found
two_items_cache
addi r4, r10, ins_dcbf - table_start
b epilogue_main

#Check for dcbi
check_dcbi:
lwz r6, 0x7C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbst

#dcbi found
two_items_cache
addi r4, r10, ins_dcbi - table_start
b epilogue_main

#Check for dcbst
check_dcbst:
lwz r6, 0x80 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbt

#dcbst found
two_items_cache
addi r4, r10, ins_dcbst - table_start
b epilogue_main

#Check for dcbt
check_dcbt:
lwz r6, 0x84 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbtst

#dcbt found
two_items_cache
addi r4, r10, ins_dcbt - table_start
b epilogue_main

#Check for dcbtst
check_dcbtst:
lwz r6, 0x88 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbz

#dcbtst found
two_items_cache
addi r4, r10, ins_dcbtst - table_start
b epilogue_main

#Check for dcbz
check_dcbz:
lwz r6, 0x8C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_dcbz_l

#dcbz found
two_items_cache
addi r4, r10, ins_dcbz - table_start
b epilogue_main

#Check for dcbz_l
check_dcbz_l:
lwz r6, 0x90 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_divwX

#dcbz_l found
two_items_cache
addi r4, r10, ins_dcbz_l - table_start
b epilogue_main

#Check for divwX
check_divwX:
lwz r11, 0x94 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_divwuX

#divwX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_divw - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_divw_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_divwo - table_start
beq- epilogue_main
addi r4, r10, ins_divwo_ - table_start
b epilogue_main

#Check for divwuX
check_divwuX:
lwz r11, 0x98 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_eciwx

#divwuX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_divwu - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_divwu_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_divwuo - table_start
beq- epilogue_main
addi r4, r10, ins_divwuo_ - table_start
b epilogue_main

#Check for eciwx
check_eciwx:
lwz r6, 0x9C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ecowx

#eciwx found
three_items_left_aligned
addi r4, r10, ins_eciwx - table_start
b epilogue_main

#Check for ecowx
check_ecowx:
lwz r6, 0xA0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_eieio

#ecowx found
three_items_left_aligned
addi r4, r10, ins_ecowx - table_start
b epilogue_main

#Check for eieio
check_eieio:
lwz r6, 0xA4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x384 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_eqvX

#eieio found
addi r4, r10, ins_eieio - table_start
b epilogue_main

#Check for eqvX
check_eqvX:
lwz r11, 0xA8 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_extsbX

#eqvX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_eqv - table_start
beq- epilogue_main
addi r4, r10, ins_eqv_ - table_start
b epilogue_main

#Check for extsbX
check_extsbX:
lwz r6, 0xAC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_extshX

#extsbX found
andi. r0, r31, rc
two_items_logical
addi r4, r10, ins_extsb - table_start
beq- epilogue_main
addi r4, r10, ins_extsb_ - table_start
b epilogue_main

#Check for extshX
check_extshX:
lwz r6, 0xB0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fabsX

#extshX found
andi. r0, r31, rc
two_items_logical
addi r4, r10, ins_extsh - table_start
beq- epilogue_main
addi r4, r10, ins_extsh_ - table_start
b epilogue_main

#Check for fabsX
check_fabsX:
lwz r6, 0xB4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_faddX

#fabsX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fabs - table_start
beq- epilogue_main
addi r4, r10, ins_fabs_ - table_start
b epilogue_main

#Check for faddX
check_faddX:
lwz r6, 0xB8 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_faddsX

#faddX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_fadd - table_start
beq- epilogue_main
addi r4, r10, ins_fadd_ - table_start
b epilogue_main

#Check for faddsX
check_faddsX:
lwz r6, 0xBC (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fcmpo

#faddsX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_fadds - table_start
beq- epilogue_main
addi r4, r10, ins_fadds_ - table_start
b epilogue_main

#Check for fcmpo
check_fcmpo:
lwz r6, 0xC0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x37C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fcmpu

#fcmpo found
three_items_compare
addi r4, r10, ins_fcmpo - table_start
b epilogue_main

#Check for fcmpu
check_fcmpu:
lwz r6, 0xC4 (r10)
clrrwi r0, r31, 26
cmpw cr7, r0, r6
lwz r0, 0x378 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fctiwX

#fcmpu found
three_items_compare
addi r4, r10, ins_fcmpu - table_start
b epilogue_main

#Check for fctiwX
check_fctiwX:
lwz r6, 0xC8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fctiwzX

#fctiwX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fctiw - table_start
beq- epilogue_main
addi r4, r10, ins_fctiw_ - table_start
b epilogue_main

#Check for fctiwzX
check_fctiwzX:
lwz r6, 0xCC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fdivX

#fctiwzX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fctiwz - table_start
beq- epilogue_main
addi r4, r10, ins_fctiwz_ - table_start
b epilogue_main

#Check for fdivX
check_fdivX:
lwz r6, 0xD0 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fdivsX

#fdivX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_fdiv - table_start
beq- epilogue_main
addi r4, r10, ins_fdiv_ - table_start
b epilogue_main

#Check for fdivsX
check_fdivsX:
lwz r6, 0xD4 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fmaddX

#fdivsX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_fdivs - table_start
beq- epilogue_main
addi r4, r10, ins_fdivs_ - table_start
b epilogue_main

#Check for fmaddX
check_fmaddX:
lwz r11, 0xD8 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fmaddsX

#fmaddX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fmadd - table_start
beq- epilogue_main
addi r4, r10, ins_fmadd_ - table_start
b epilogue_main

#Check for fmaddsX
check_fmaddsX:
lwz r11, 0xDC (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fmr

#fmaddsX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fmadds - table_start
beq- epilogue_main
addi r4, r10, ins_fmadds_ - table_start
b epilogue_main

#Check for fmrX
check_fmr:
lwz r11, 0xE0 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_fmsub

#fmrX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fmr - table_start
beq- epilogue_main
addi r4, r10, ins_fmr_ - table_start
b epilogue_main

#Check for fmsubX
check_fmsub:
lwz r11, 0xE4 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fmsubsX

#fmsubX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fmsub - table_start
beq- epilogue_main
addi r4, r10, ins_fmsub_ - table_start
b epilogue_main

#Check for fmsubsX
check_fmsubsX:
lwz r11, 0xE8 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fmulX

#fmsubsX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fmsubs - table_start
beq- epilogue_main
addi r4, r10, ins_fmsubs_ - table_start
b epilogue_main

#Check for fmulX
check_fmulX:
lwz r6, 0xEC (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fmulsX

#fmulX found
andi. r0, r31, rc
three_items_left_split_two_one
addi r4, r10, ins_fmul - table_start
beq- epilogue_main
addi r4, r10, ins_fmul_ - table_start
b epilogue_main

#Check for fmulsX
check_fmulsX:
lwz r6, 0xF0 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fnabsX

#fmulsX found
andi. r0, r31, rc
three_items_left_split_two_one
addi r4, r10, ins_fmuls - table_start
beq- epilogue_main
addi r4, r10, ins_fmuls_ - table_start
b epilogue_main

#Check for fnabsX
check_fnabsX:
lwz r6, 0xF4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fnegX

#fnabsX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fnabs - table_start
beq- epilogue_main
addi r4, r10, ins_fnabs_ - table_start
b epilogue_main

#Check for fnegX
check_fnegX:
lwz r6, 0xF8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fnmaddX

#fnegX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fneg - table_start
beq- epilogue_main
addi r4, r10, ins_fneg_ - table_start
b epilogue_main

#Check for fnmaddX
check_fnmaddX:
lwz r11, 0xFC (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fnmaddsX

#fnmaddX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fnmadd - table_start
beq- epilogue_main
addi r4, r10, ins_fnmadd_ - table_start
b epilogue_main

#Check for fnmaddsX
check_fnmaddsX:
lwz r11, 0x100 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fnmsubX

#fnmaddsX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fnmadds - table_start
beq- epilogue_main
addi r4, r10, ins_fnmadds_ - table_start
b epilogue_main

#Check for fnmsubX
check_fnmsubX:
lwz r11, 0x104 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fnmsubsX

#fnmsubX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fnmsub - table_start
beq- epilogue_main
addi r4, r10, ins_fnmsub_ - table_start
b epilogue_main

#Check for fnmsubsX
check_fnmsubsX:
lwz r11, 0x108 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fresX

#fnmsubsX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fnmsubs - table_start
beq- epilogue_main
addi r4, r10, ins_fnmsubs_ - table_start
b epilogue_main

#Check for fresX
check_fresX:
lwz r6, 0x10C (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
lwz r0, 0x388 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_frspX

#fresX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_fres - table_start
beq- epilogue_main
addi r4, r10, ins_fres_ - table_start
b epilogue_main

#Check for frspX
check_frspX:
lwz r6, 0x110 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_frsqrteX

#frspX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_frsp - table_start
beq- epilogue_main
addi r4, r10, ins_frsp_ - table_start
b epilogue_main

#Check for frsqrteX
check_frsqrteX:
lwz r6, 0x114 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
lwz r0, 0x388 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fselX

#frsqrteX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_frsqrte - table_start
beq- epilogue_main
addi r4, r10, ins_frsqrte_ - table_start
b epilogue_main

#Check for fselX
check_fselX:
lwz r11, 0x118 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_fsubX

#fselX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_fsel - table_start
beq- epilogue_main
addi r4, r10, ins_fsel_ - table_start
b epilogue_main

#Check for fsubX
check_fsubX:
lwz r6, 0x11C (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_fsubsX

#fsubX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_fsub - table_start
beq- epilogue_main
addi r4, r10, ins_fsub_ - table_start
b epilogue_main

#Check for fsubsX
check_fsubsX:
lwz r6, 0x120 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_icbi

#fsubsX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_fsubs - table_start
beq- epilogue_main
addi r4, r10, ins_fsubs_ - table_start
b epilogue_main

#Check for icbi
check_icbi:
lwz r6, 0x124 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x380 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_isync

#icbi found
two_items_cache
addi r4, r10, ins_icbi - table_start
b epilogue_main

#Check for isync
check_isync:
lwz r6, 0x128 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x384 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lbz

#isync found
addi r4, r10, ins_isync - table_start
b epilogue_main

#Check for lbz
check_lbz:
lwz r11, 0x12C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lbzu

#lbz found
loadstore_imm
addi r4, r10, ins_lbz - table_start
b epilogue_main

#Check for lbzu
check_lbzu:
lwz r11, 0x130 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lbzux

#lbzu found
loadstore_imm
load_int_update_doublecheck
addi r4, r10, ins_lbzu - table_start
b epilogue_main

#Check for lbzux
check_lbzux:
lwz r6, 0x134 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lbzx

#lbzux found
three_items_left_aligned
load_int_update_index_doublecheck
addi r4, r10, ins_lbzux - table_start
b epilogue_main

#Check for lbzx
check_lbzx:
lwz r6, 0x138 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lfd

#lbzx found
three_items_left_aligned
addi r4, r10, ins_lbzx - table_start
b epilogue_main

#Check for lfd
check_lfd:
lwz r11, 0x13C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lfdu

#lfd found
loadstore_imm
addi r4, r10, ins_lfd - table_start
b epilogue_main

#Check for lfdu
check_lfdu:
lwz r11, 0x140 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lfdux

#lfdu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_lfdu - table_start
b epilogue_main

#Check for lfdux
check_lfdux:
lwz r6, 0x144 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lfdx

#lfdux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_lfdux - table_start
b epilogue_main

#Check for lfdx
check_lfdx:
lwz r6, 0x148 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lfs

#lfdx found
three_items_left_aligned
addi r4, r10, ins_lfdx - table_start
b epilogue_main

#Check for lfs
check_lfs:
lwz r11, 0x14C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lfsu

#lfs found
loadstore_imm
addi r4, r10, ins_lfs - table_start
b epilogue_main

#Check for lfsu
check_lfsu:
lwz r11, 0x150 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lfsux

#lfsu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_lfsu - table_start
b epilogue_main

#Check for lfsux
check_lfsux:
lwz r6, 0x154 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lfsx

#lfsux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_lfsux - table_start
b epilogue_main

#Check for lfsx
check_lfsx:
lwz r6, 0x158 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lha

#lfsx found
three_items_left_aligned
addi r4, r10, ins_lfsx - table_start
b epilogue_main

#Check for lha
check_lha:
lwz r11, 0x15C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lhau

#lha found
loadstore_imm
addi r4, r10, ins_lha - table_start
b epilogue_main

#Check for lhau
check_lhau:
lwz r11, 0x160 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lhaux

#lhau found
loadstore_imm
load_int_update_doublecheck
addi r4, r10, ins_lhau - table_start
b epilogue_main

#Check for lhaux
check_lhaux:
lwz r6, 0x164 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lhax

#lhaux found
three_items_left_aligned
load_int_update_index_doublecheck
addi r4, r10, ins_lhaux - table_start
b epilogue_main

#Check for lhax
check_lhax:
lwz r6, 0x168 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lhbrx

#lhax found
three_items_left_aligned
addi r4, r10, ins_lhax - table_start
b epilogue_main

#Check for lhbrx
check_lhbrx:
lwz r6, 0x16C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lhz

#lhbrx found
three_items_left_aligned
addi r4, r10, ins_lhbrx - table_start
b epilogue_main

#Check for lhz
check_lhz:
lwz r11, 0x170 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lhzu

#lhz found
loadstore_imm
addi r4, r10, ins_lhz - table_start
b epilogue_main

#Check for lhzu
check_lhzu:
lwz r11, 0x174 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lhzux

#lhzu found
loadstore_imm
load_int_update_doublecheck
addi r4, r10, ins_lhzu - table_start
b epilogue_main

#Check for lhzux
check_lhzux:
lwz r6, 0x178 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lhzx

#lhzux found
three_items_left_aligned
load_int_update_index_doublecheck
addi r4, r10, ins_lhzux - table_start
b epilogue_main

#Check for lhzx
check_lhzx:
lwz r6, 0x17C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lmw

#lhzx found
three_items_left_aligned
addi r4, r10, ins_lhzx - table_start
b epilogue_main

#Check for lmw
check_lmw:
lwz r11, 0x180 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lswi

#lmw found
loadstore_imm
#rA cannot = or be > rD
cmplw r7, r5
bge- do_invalid
addi r4, r10, ins_lmw - table_start
b epilogue_main

#Check for lswi
check_lswi:
lwz r6, 0x184 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lswx

#lswi found
three_items_left_aligned
#NB cannot cause loaded bytes to spill into rA
#This can only occur if rA is = or > rD
#r5 = rD
#r6 = rA
#r7 = NB
cmplw r5, r6
bgt- start_processing_lswi
#In the case that NB is 0, Broadway treats it as 32!!
mr r12, r7 #Preserve r7 aka NB
cmpwi r12, 0
bne- skip_nb_adjustment
li r12, 32
skip_nb_adjustment:
subf r0, r5, r6
slwi r0, r0, 2
cmplw r12, r0
bgt- do_invalid
start_processing_lswi:
addi r4, r10, ins_lswi - table_start
b epilogue_main

#Check for lswx
check_lswx:
lwz r6, 0x188 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lwarx

#lswx found
three_items_left_aligned
addi r4, r10, ins_lswx - table_start
b epilogue_main

#Check for lwarx
check_lwarx:
lwz r6, 0x18C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lwbrx

#lwarx found
three_items_left_aligned
addi r4, r10, ins_lwarx - table_start
b epilogue_main

#Check for lwbrx
check_lwbrx:
lwz r6, 0x190 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lwz

#lwbrx found
three_items_left_aligned
addi r4, r10, ins_lwbrx - table_start
b epilogue_main

#Check for lwz
check_lwz:
lwz r11, 0x194 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lwzu

#lwz found
loadstore_imm
addi r4, r10, ins_lwz - table_start
b epilogue_main

#Check for lwzu
check_lwzu:
lwz r11, 0x198 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_lwzux

#lwzu found
loadstore_imm
load_int_update_doublecheck
addi r4, r10, ins_lwzu - table_start
b epilogue_main

#Check for lwzux
check_lwzux:
lwz r6, 0x19C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_lwzx

#lwzux found
three_items_left_aligned
load_int_update_index_doublecheck
addi r4, r10, ins_lwzux - table_start
b epilogue_main

#Check for lwzx
check_lwzx:
lwz r6, 0x1A0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mcrf

#lwzx found
three_items_left_aligned
addi r4, r10, ins_lwzx - table_start
b epilogue_main

#Check for mcrf
check_mcrf:
lwz r6, 0x1A4 (r10)
clrrwi r0, r31, 26
cmpw cr7, r0, r6
lwz r0, 0x38C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mcrfs

#mcrf found
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 14, 0x00000007
addi r4, r10, ins_mcrf - table_start
b epilogue_main

#Check for mcrfs
check_mcrfs:
lwz r6, 0x1A8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x390 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mcrxr

#mcrfs found
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 14, 0x00000007
addi r4, r10, ins_mcrfs - table_start
b epilogue_main

#Check for mcrxr
check_mcrxr:
lwz r6, 0x1AC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x394 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mfcr

#mcrxr found
rlwinm r5, r31, 9, 0x00000007
addi r4, r10, ins_mcrxr - table_start
b epilogue_main

#Check for mfcr
check_mfcr:
lwz r6, 0x1B0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x398 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mffsX

#mfcr found
rlwinm r5, r31, 11, 0x0000001F
addi r4, r10, ins_mfcr - table_start
b epilogue_main

#Check for mffsX
check_mffsX:
lwz r6, 0x1B4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x39C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mfmsr

#mffsX found
rlwinm r5, r31, 11, 0x0000001F
andi. r0, r31, rc
addi r4, r10, ins_mffs - table_start
beq- epilogue_main
addi r4, r10, ins_mffs_ - table_start
b epilogue_main

#Check for mfmsr
check_mfmsr:
lwz r6, 0x1B8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x398 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mfspr

#mfmsr found
rlwinm r5, r31, 11, 0x0000001F
addi r4, r10, ins_mfmsr - table_start
b epilogue_main

#Check for mfspr
check_mfspr:
lwz r6, 0x1BC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mfsr

#mfspr found (also add in temp r4 pointers to simplified mnemonics)
rlwinm r5, r31, 11, 0x0000001F #r5 now = rD
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 26, 0x000003E0
or r6, r7, r6 #r6 now = SPR number
#r5 (rD) in perfect place for sprintf (r%d) regardless of whether or not a simplified mnemonic is used
cmpwi r6, 1
addi r4, r10, ins_mfxer - table_start
beq- epilogue_main
cmpwi r6, 8
addi r4, r10, ins_mflr - table_start
beq- epilogue_main
cmpwi r6, 9
addi r4, r10, ins_mfctr - table_start
beq- epilogue_main
cmpwi r6, 18
beq- proceed_mfspr
cmpwi r6, 19
beq- proceed_mfspr
cmpwi r6, 22
beq- proceed_mfspr
cmpwi r6, 25
beq- proceed_mfspr
cmpwi r6, 26
beq- proceed_mfspr
cmpwi r6, 27
beq- proceed_mfspr
cmpwi r6, 272
beq- proceed_mfspr
cmpwi r6, 273
beq- proceed_mfspr
cmpwi r6, 274
beq- proceed_mfspr
cmpwi r6, 275
beq- proceed_mfspr
cmpwi r6, 282
beq- proceed_mfspr
cmpwi r6, 287
beq- proceed_mfspr
cmpwi r6, 528
beq- proceed_mfspr
cmpwi r6, 529
beq- proceed_mfspr
cmpwi r6, 530
beq- proceed_mfspr
cmpwi r6, 531
beq- proceed_mfspr
cmpwi r6, 532
beq- proceed_mfspr
cmpwi r6, 533
beq- proceed_mfspr
cmpwi r6, 534
beq- proceed_mfspr
cmpwi r6, 535
beq- proceed_mfspr
cmpwi r6, 560
beq- proceed_mfspr
cmpwi r6, 561
beq- proceed_mfspr
cmpwi r6, 562
beq- proceed_mfspr
cmpwi r6, 563
beq- proceed_mfspr
cmpwi r6, 564
beq- proceed_mfspr
cmpwi r6, 565
beq- proceed_mfspr
cmpwi r6, 566
beq- proceed_mfspr
cmpwi r6, 567
beq- proceed_mfspr
cmpwi r6, 536
beq- proceed_mfspr
cmpwi r6, 537
beq- proceed_mfspr
cmpwi r6, 538
beq- proceed_mfspr
cmpwi r6, 539
beq- proceed_mfspr
cmpwi r6, 540
beq- proceed_mfspr
cmpwi r6, 541
beq- proceed_mfspr
cmpwi r6, 542
beq- proceed_mfspr
cmpwi r6, 543
beq- proceed_mfspr
cmpwi r6, 568
beq- proceed_mfspr
cmpwi r6, 569
beq- proceed_mfspr
cmpwi r6, 570
beq- proceed_mfspr
cmpwi r6, 571
beq- proceed_mfspr
cmpwi r6, 572
beq- proceed_mfspr
cmpwi r6, 573
beq- proceed_mfspr
cmpwi r6, 574
beq- proceed_mfspr
cmpwi r6, 575
beq- proceed_mfspr
cmpwi r6, 912
beq- proceed_mfspr
cmpwi r6, 913
beq- proceed_mfspr
cmpwi r6, 914
beq- proceed_mfspr
cmpwi r6, 915
beq- proceed_mfspr
cmpwi r6, 916
beq- proceed_mfspr
cmpwi r6, 917
beq- proceed_mfspr
cmpwi r6, 918
beq- proceed_mfspr
cmpwi r6, 919
beq- proceed_mfspr
cmpwi r6, 920
beq- proceed_mfspr
cmpwi r6, 921
beq- proceed_mfspr
cmpwi r6, 922
beq- proceed_mfspr
cmpwi r6, 923
beq- proceed_mfspr
#Support for CHIP ID SPR's added in!
cmpwi r6, 925
beq- proceed_mfspr
cmpwi r6, 926
beq- proceed_mfspr
cmpwi r6, 927
beq- proceed_mfspr
#
cmpwi r6, 936
beq- proceed_mfspr
cmpwi r6, 937
beq- proceed_mfspr
cmpwi r6, 938
beq- proceed_mfspr
cmpwi r6, 939
beq- proceed_mfspr
cmpwi r6, 940
beq- proceed_mfspr
cmpwi r6, 941
beq- proceed_mfspr
cmpwi r6, 942
beq- proceed_mfspr
cmpwi r6, 943
beq- proceed_mfspr
cmpwi r6, 952
beq- proceed_mfspr
cmpwi r6, 953
beq- proceed_mfspr
cmpwi r6, 954
beq- proceed_mfspr
cmpwi r6, 955
beq- proceed_mfspr
cmpwi r6, 956
beq- proceed_mfspr
cmpwi r6, 957
beq- proceed_mfspr
cmpwi r6, 958
beq- proceed_mfspr
cmpwi r6, 959
beq- proceed_mfspr
cmpwi r6, 1008
beq- proceed_mfspr
cmpwi r6, 1009
beq- proceed_mfspr
cmpwi r6, 1010
beq- proceed_mfspr
cmpwi r6, 1011
beq- proceed_mfspr
cmpwi r6, 1012
beq- proceed_mfspr
cmpwi r6, 1013
beq- proceed_mfspr
cmpwi r6, 1017
beq- proceed_mfspr
cmpwi r6, 1018
beq- proceed_mfspr
cmpwi r6, 1019
beq- proceed_mfspr
cmpwi r6, 1020
beq- proceed_mfspr
cmpwi r6, 1021
beq- proceed_mfspr
cmpwi r6, 1022
bne- do_invalid #Invalid instruction found, do .long
proceed_mfspr:
addi r4, r10, ins_mfspr - table_start
b epilogue_main

#Check for mfsr
check_mfsr:
lwz r6, 0x1C0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3A0 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mfsrin

#mfsr found
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 16, 0x0000000F
addi r4, r10, ins_mfsr - table_start
b epilogue_main

#Check for mfsrin
check_mfsrin:
lwz r6, 0x1C4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3A4 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mftb

#mfsrin found
two_items_left_split
addi r4, r10, ins_mfsrin - table_start
b epilogue_main

#Check for mftb
check_mftb:
lwz r6, 0x1C8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtcrf

#mftb found (ALSO find out if it's either mftbl or mftbu)
rlwinm r6, r31, 16, 0x0000001F
rlwinm r7, r31, 26, 0x000003E0
or r6, r7, r6
cmpwi r6, 268
cmpwi cr7, r6, 269
cror 4*cr6+eq, 4*cr0+eq, 4*cr7+eq #Keep cr0 intact, YES this is suppose to be a crOR instruction
bne- cr6, do_invalid #Invalid instruction found, do .long
rlwinm r5, r31, 11, 0x0000001F
addi r4, r10, ins_mftbl - table_start
beq- epilogue_main #Take branch to call sprintf if it's mftbl (r6 = 268)
addi r4, r10, ins_mftbu - table_start
b epilogue_main

#Check for mtcrf (HOWEVER, also check if mtcr simplified mnemonic is the instruction)
check_mtcrf:
lwz r6, 0x1CC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3A8 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtfsb0X

#mtcrf found
rlwinm r5, r31, 20, 0x000000FF #CRM
rlwinm r6, r31, 11, 0x0000001F #rS
cmpwi r5, 0xFF
#Temp backup CRM
mr r7, r5
#Temp place rS (r6) into r5, for possiblity of mtcr
mr r5, r6
addi r4, r10, ins_mtcr - table_start
beq- epilogue_main
#Recover CRM since it's not mtcr
mr r5, r7
addi r4, r10, ins_mtcrf - table_start
b epilogue_main

#Check for mtfsb0X
check_mtfsb0X:
lwz r6, 0x1D0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x39C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtfsb1X

#mtfsb0X found
andi. r0, r31, rc
rlwinm r5, r31, 11, 0x0000001F
addi r4, r10, ins_mtfsb0 - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsb0_ - table_start
b epilogue_main

#Check for mtfsb1X
check_mtfsb1X:
lwz r6, 0x1D4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x39C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtfsfX

#mtfsb1X found
andi. r0, r31, rc
rlwinm r5, r31, 11, 0x0000001F
addi r4, r10, ins_mtfsb1 - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsb1_ - table_start
b epilogue_main

#Check for mtfsfX
check_mtfsfX:
lwz r6, 0x1D8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x0201
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtfsfiX

#mtfsfX found
andi. r0, r31, rc
rlwinm r5, r31, 15, 0x000000FF
rlwinm r6, r31, 21, 0x0000001F
addi r4, r10, ins_mtfsf - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsf_ - table_start
b epilogue_main

#Check for mtfsfiX
check_mtfsfiX:
lwz r6, 0x1DC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3AC (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtmsr

#mtfsfiX found
andi. r0, r31, rc
rlwinm r5, r31, 9, 0x00000007
rlwinm r6, r31, 20, 0x0000000F
addi r4, r10, ins_mtfsfi - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsfi_ - table_start
b epilogue_main

#Check for mtmsr
check_mtmsr:
lwz r6, 0x1E0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x398 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtspr

#mtmsr found
rlwinm r5, r31, 11, 0x0000001F
addi r4, r10, ins_mtmsr - table_start
b epilogue_main

#Check for mtspr
check_mtspr:
lwz r6, 0x1E4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtsr

#mtspr found (also add in r4 pointers for simplified mnemonics)
rlwinm r5, r31, 16, 0x0000001F
rlwinm r6, r31, 26, 0x000003E0
or r5, r6, r5 #r5 now = SPR number
rlwinm r6, r31, 11, 0x0000001F #r6 now = rS
#Before we start massive SPR number checks, implement a hacky fix to backup SPR (r5) and rS (r6), because rS actually needs to be in r5 for the first 3 SPR number checks due to possible siplified mnemonic scenario. After those 3 checks, 'recover' rS and SPR approriately.
mr r11, r5
mr r12, r6
mr r5, r12
#Start simplified mnemonic spr number checks
cmpwi r11, 1
addi r4, r10, ins_mtxer - table_start
beq- epilogue_main
cmpwi r11, 8
addi r4, r10, ins_mtlr - table_start
beq- epilogue_main
cmpwi r11, 9
addi r4, r10, ins_mtctr - table_start
beq- epilogue_main
#'Recover' SPR and rS, continue with rest of spr number checks
mr r5, r11
mr r6, r12
cmpwi r5, 18
beq- proceed_mtspr
cmpwi r5, 19
beq- proceed_mtspr
cmpwi r5, 22
beq- proceed_mtspr
cmpwi r5, 25
beq- proceed_mtspr
cmpwi r5, 26
beq- proceed_mtspr
cmpwi r5, 27
beq- proceed_mtspr
cmpwi r5, 272
beq- proceed_mtspr
cmpwi r5, 273
beq- proceed_mtspr
cmpwi r5, 274
beq- proceed_mtspr
cmpwi r5, 275
beq- proceed_mtspr
cmpwi r5, 282
beq- proceed_mtspr
cmpwi r5, 284
beq- proceed_mtspr
cmpwi r5, 285
beq- proceed_mtspr
cmpwi r5, 528
beq- proceed_mtspr
cmpwi r5, 529
beq- proceed_mtspr
cmpwi r5, 530
beq- proceed_mtspr
cmpwi r5, 531
beq- proceed_mtspr
cmpwi r5, 532
beq- proceed_mtspr
cmpwi r5, 533
beq- proceed_mtspr
cmpwi r5, 534
beq- proceed_mtspr
cmpwi r5, 535
beq- proceed_mtspr
cmpwi r5, 560
beq- proceed_mtspr
cmpwi r5, 561
beq- proceed_mtspr
cmpwi r5, 562
beq- proceed_mtspr
cmpwi r5, 563
beq- proceed_mtspr
cmpwi r5, 564
beq- proceed_mtspr
cmpwi r5, 565
beq- proceed_mtspr
cmpwi r5, 566
beq- proceed_mtspr
cmpwi r5, 567
beq- proceed_mtspr
cmpwi r5, 536
beq- proceed_mtspr
cmpwi r5, 537
beq- proceed_mtspr
cmpwi r5, 538
beq- proceed_mtspr
cmpwi r5, 539
beq- proceed_mtspr
cmpwi r5, 540
beq- proceed_mtspr
cmpwi r5, 541
beq- proceed_mtspr
cmpwi r5, 542
beq- proceed_mtspr
cmpwi r5, 543
beq- proceed_mtspr
cmpwi r5, 568
beq- proceed_mtspr
cmpwi r5, 569
beq- proceed_mtspr
cmpwi r5, 570
beq- proceed_mtspr
cmpwi r5, 571
beq- proceed_mtspr
cmpwi r5, 572
beq- proceed_mtspr
cmpwi r5, 573
beq- proceed_mtspr
cmpwi r5, 574
beq- proceed_mtspr
cmpwi r5, 575
beq- proceed_mtspr
cmpwi r5, 912
beq- proceed_mtspr
cmpwi r5, 913
beq- proceed_mtspr
cmpwi r5, 914
beq- proceed_mtspr
cmpwi r5, 915
beq- proceed_mtspr
cmpwi r5, 916
beq- proceed_mtspr
cmpwi r5, 917
beq- proceed_mtspr
cmpwi r5, 918
beq- proceed_mtspr
cmpwi r5, 919
beq- proceed_mtspr
cmpwi r5, 920
beq- proceed_mtspr
cmpwi r5, 921
beq- proceed_mtspr
cmpwi r5, 922
beq- proceed_mtspr
cmpwi r5, 923
beq- proceed_mtspr
cmpwi r5, 936
beq- proceed_mtspr
cmpwi r5, 937
beq- proceed_mtspr
cmpwi r5, 938
beq- proceed_mtspr
cmpwi r5, 939
beq- proceed_mtspr
cmpwi r5, 940
beq- proceed_mtspr
cmpwi r5, 941
beq- proceed_mtspr
cmpwi r5, 942
beq- proceed_mtspr
cmpwi r5, 943
beq- proceed_mtspr
cmpwi r5, 952
beq- proceed_mtspr
cmpwi r5, 953
beq- proceed_mtspr
cmpwi r5, 954
beq- proceed_mtspr
cmpwi r5, 955
beq- proceed_mtspr
cmpwi r5, 956
beq- proceed_mtspr
cmpwi r5, 957
beq- proceed_mtspr
cmpwi r5, 958
beq- proceed_mtspr
cmpwi r5, 959
beq- proceed_mtspr
cmpwi r5, 1008
beq- proceed_mtspr
cmpwi r5, 1009
beq- proceed_mtspr
cmpwi r5, 1010
beq- proceed_mtspr
cmpwi r5, 1011
beq- proceed_mtspr
cmpwi r5, 1013
beq- proceed_mtspr
cmpwi r5, 1017
beq- proceed_mtspr
cmpwi r5, 1019
beq- proceed_mtspr
cmpwi r5, 1020
beq- proceed_mtspr
cmpwi r5, 1021
beq- proceed_mtspr
cmpwi r5, 1022
bne- do_invalid #Invalid instruction found, do .long
proceed_mtspr:
addi r4, r10, ins_mtspr - table_start
b epilogue_main

#Check for mtsr
check_mtsr:
lwz r6, 0x1E8 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3A0 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mtsrin

#mtsr found
rlwinm r5, r31, 16, 0x0000000F
rlwinm r6, r31, 11, 0x0000001F
addi r4, r10, ins_mtsr - table_start
b epilogue_main

#Check for mtsrin
check_mtsrin:
lwz r6, 0x1EC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3A4 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mulhwX

#mtsrin found
two_items_left_split
addi r4, r10, ins_mtsrin - table_start
b epilogue_main

#Check for mulhwX
check_mulhwX:
lwz r6, 0x1F0 (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0x0200
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mulhwuX

#mulhwX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_mulhw - table_start
beq- epilogue_main
addi r4, r10, ins_mulhw_ - table_start
b epilogue_main

#Check for mulhwuX
check_mulhwuX:
lwz r6, 0x1F4 (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0x0200
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_mulli

#mulhwuX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_mulhwu - table_start
beq- epilogue_main
addi r4, r10, ins_mulhwu_ - table_start
b epilogue_main

#Check for mulli
check_mulli:
lwz r11, 0x1F8 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_mullwX

#mulli found
nonloadstore_imm
addi r4, r10, ins_mulli - table_start
b epilogue_main

#Check for mullwX
check_mullwX:
lwz r11, 0x1FC (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_nandX

#mullwX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_mullw - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_mullw_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_mullwo - table_start
beq- epilogue_main
addi r4, r10, ins_mullwo_ - table_start
b epilogue_main

#Check for nandX
check_nandX:
lwz r11, 0x200 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_negX

#nandX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_nand - table_start
beq- epilogue_main
addi r4, r10, ins_nand_ - table_start
b epilogue_main

#Check for negX
check_negX:
lwz r6, 0x204 (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_norX

#negX found
andi. r0, r31, oe | rc
two_items_left_aligned
addi r4, r10, ins_neg - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_neg_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_nego - table_start
beq- epilogue_main
addi r4, r10, ins_nego_ - table_start
b epilogue_main

#Check for norX
check_norX:
lwz r11, 0x208 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_orX

#norX found (HOWEVER check for simplified notX as well)
andi. r0, r31, rc
three_items_logical
#instruction is notX if rS (r6) and rB (r7) are the same
cmpw cr7, r6, r7
bne- cr7, not_notX
#notX found, do not vs not. depending on cr0 from andi.
addi r4, r10, ins_not - table_start
beq- epilogue_main
addi r4, r10, ins_not_ - table_start
b epilogue_main
not_notX:
addi r4, r10, ins_nor - table_start
beq- epilogue_main
addi r4, r10, ins_nor_ - table_start
b epilogue_main

#Check for orX
check_orX:
lwz r11, 0x20C (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_orcX

#orX found (HOWEVER check for simplified mrX as well)
andi. r0, r31, rc
three_items_logical
#instruction is mrX if rS (r6) and rB (r7) are the same
cmpw cr7, r6, r7
bne- cr7, not_mrX
#mrX found, do mr vs mr. depending on cr0 from andi.
addi r4, r10, ins_mr - table_start
beq- epilogue_main
addi r4, r10, ins_mr_ - table_start
b epilogue_main
not_mrX:
addi r4, r10, ins_or - table_start
beq- epilogue_main
addi r4, r10, ins_or_ - table_start
b epilogue_main

#Check for orcX
check_orcX:
lwz r11, 0x210 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_ori

#orcX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_orc - table_start
beq- epilogue_main
addi r4, r10, ins_orc_ - table_start
b epilogue_main

#Check for ori (HOWEVER, check for nop first)
check_ori:
lwz r11, 0x214 (r10)
cmpw r11, r31
bne- not_nop
addi r4, r10, ins_nop - table_start
b epilogue_main
not_nop:
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_oris

#ori found
logical_imm
addi r4, r10, ins_ori - table_start
b epilogue_main

#Check for oris
check_oris:
lwz r11, 0x218 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_psq_l

#oris found
logical_imm
addi r4, r10, ins_oris - table_start
b epilogue_main

#Check for psq_l
check_psq_l:
lwz r11, 0x21C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_psq_lu

#psq_l found
psq_imm
addi r4, r10, ins_psq_l - table_start
b epilogue_main

#Check for psq_lu
check_psq_lu:
lwz r11, 0x220 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_psq_lux

#psq_lu found
psq_imm
cmpwi r7, 0
beq- do_invalid
addi r4, r10, ins_psq_lu - table_start
b epilogue_main

#Check for psq_lux
check_psq_lux:
lwz r6, 0x224 (r10)
check_ins_bits_oe_p
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_psq_lx

#psq_lux found
psq_index
cmpwi r6, 0
beq- do_invalid
addi r4, r10, ins_psq_lux - table_start
b epilogue_main

#Check for psq_lx
check_psq_lx:
lwz r6, 0x228 (r10)
check_ins_bits_oe_p
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_psq_st

#psq_lx found
psq_index
addi r4, r10, ins_psq_lx - table_start
b epilogue_main

#Check for psq_st
check_psq_st:
lwz r11, 0x22C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_psq_stu

#psq_st found
psq_imm
addi r4, r10, ins_psq_st - table_start
b epilogue_main

#Check for psq_stu
check_psq_stu:
lwz r11, 0x230 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_psq_stux

#psq_stu found
psq_imm
cmpwi r7, 0
beq- do_invalid
addi r4, r10, ins_psq_stu - table_start
b epilogue_main

#Check for psq_stux
check_psq_stux:
lwz r6, 0x234 (r10)
check_ins_bits_oe_p
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_psq_stx

#psq_stux found
psq_index
cmpwi r6, 0
beq- do_invalid
addi r4, r10, ins_psq_stux - table_start
b epilogue_main

#Check for psq_stx
check_psq_stx:
lwz r6, 0x238 (r10)
check_ins_bits_oe_p
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_absX

#psq_stx found
psq_index
addi r4, r10, ins_psq_stx - table_start
b epilogue_main

#Check for ps_absX
check_ps_absX:
lwz r6, 0x23C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_addX

#ps_absX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_ps_abs - table_start
beq- epilogue_main
addi r4, r10, ins_ps_abs_ - table_start
b epilogue_main

#Check for ps_addX
check_ps_addX:
lwz r6, 0x240 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_cmpo0

#ps_addX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_add - table_start
beq- epilogue_main
addi r4, r10, ins_ps_add_ - table_start
b epilogue_main

#Check for ps_cmpo0
check_ps_cmpo0:
lwz r6, 0x244 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x37C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_cmpo1

#ps_cmpo0 found
three_items_compare
addi r4, r10, ins_ps_cmpo0 - table_start
b epilogue_main

#Check for ps_cmpo1
check_ps_cmpo1:
lwz r6, 0x248 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x37C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_cmpu0

#ps_cmpo1 found
three_items_compare
addi r4, r10, ins_ps_cmpo1 - table_start
b epilogue_main

#Check for ps_cmpu0
check_ps_cmpu0:
lwz r6, 0x24C (r10)
clrrwi r0, r31, 26
cmpw cr7, r0, r6
lwz r0, 0x378 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_cmpu1

#ps_cmpu0 found
three_items_compare
addi r4, r10, ins_ps_cmpu0 - table_start
b epilogue_main

#Check for ps_cmpu1
check_ps_cmpu1:
lwz r6, 0x250 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x37C (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_divX

#ps_cmpu1 found
three_items_compare
addi r4, r10, ins_ps_cmpu1 - table_start
b epilogue_main

#Check for ps_divX
check_ps_divX:
lwz r6, 0x254 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_maddX

#ps_divX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_div - table_start
beq- epilogue_main
addi r4, r10, ins_ps_div_ - table_start
b epilogue_main

#Check for ps_maddX
check_ps_maddX:
lwz r11, 0x258 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_madds0X

#ps_maddX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_madd - table_start
beq- epilogue_main
addi r4, r10, ins_ps_madd_ - table_start
b epilogue_main

#Check for ps_madds0X
check_ps_madds0X:
lwz r11, 0x25C (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_madds1X

#ps_madds0X found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_madds0 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_madds0_ - table_start
b epilogue_main

#Check for ps_madds1X
check_ps_madds1X:
lwz r11, 0x260 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_merge00X

#ps_madds1X found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_madds1 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_madds1_ - table_start
b epilogue_main

#Check for ps_merge00X
check_ps_merge00X:
lwz r11, 0x264 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_ps_merge01X

#ps_merge00X found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_merge00 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge00_ - table_start
b epilogue_main

#Check for ps_merge01X
check_ps_merge01X:
lwz r11, 0x268 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_ps_merge10X

#ps_merge01X found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_merge01 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge01_ - table_start
b epilogue_main

#Check for ps_merge10X
check_ps_merge10X:
lwz r11, 0x26C (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_ps_merge11X

#ps_merge10X found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_merge10 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge10_ - table_start
b epilogue_main

#Check for ps_merge11X
check_ps_merge11X:
lwz r11, 0x270 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_ps_mrX

#ps_merge11X found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_merge11 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge11_ - table_start
b epilogue_main

#Check for ps_mrX
check_ps_mrX:
lwz r6, 0x274 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_msubX

#ps_mrX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_ps_mr - table_start
beq- epilogue_main
addi r4, r10, ins_ps_mr_ - table_start
b epilogue_main

#Check for ps_msubX
check_ps_msubX:
lwz r11, 0x278 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_mulX

#ps_msubX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_msub - table_start
beq- epilogue_main
addi r4, r10, ins_ps_msub_ - table_start
b epilogue_main

#Check for ps_mulX
check_ps_mulX:
lwz r6, 0x27C (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_muls0X

#ps_mulX found
andi. r0, r31, rc
three_items_left_split_two_one
addi r4, r10, ins_ps_mul - table_start
beq- epilogue_main
addi r4, r10, ins_ps_mul_ - table_start
b epilogue_main

#Check for ps_muls0X
check_ps_muls0X:
lwz r6, 0x280 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_muls1X

#ps_muls0X found
andi. r0, r31, rc
three_items_left_split_two_one
addi r4, r10, ins_ps_muls0 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_muls0_ - table_start
b epilogue_main

#Check for ps_muls1X
check_ps_muls1X:
lwz r6, 0x284 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_nabsX

#ps_muls1X found
andi. r0, r31, rc
three_items_left_split_two_one
addi r4, r10, ins_ps_muls1 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_muls1_ - table_start
b epilogue_main

#Check for ps_nabsX
check_ps_nabsX:
lwz r6, 0x288 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_negX

#ps_nabsX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_ps_nabs - table_start
beq- epilogue_main
addi r4, r10, ins_ps_nabs_ - table_start
b epilogue_main

#Check for ps_negX
check_ps_negX:
lwz r6, 0x28C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andis. r0, r31, 0x001F
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_nmaddX

#ps_negX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_ps_neg - table_start
beq- epilogue_main
addi r4, r10, ins_ps_neg_ - table_start
b epilogue_main

#Check for ps_nmaddX
check_ps_nmaddX:
lwz r11, 0x290 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_nmsubX

#ps_nmaddX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_nmadd - table_start
beq- epilogue_main
addi r4, r10, ins_ps_nmadd_ - table_start
b epilogue_main

#Check for ps_nmsubX
check_ps_nmsubX:
lwz r11, 0x294 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_resX

#ps_nmsubX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_nmsub - table_start
beq- epilogue_main
addi r4, r10, ins_ps_nmsub_ - table_start
b epilogue_main

#Check for ps_resX
check_ps_resX:
lwz r6, 0x298 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
lwz r0, 0x388 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_rsqrteX

#ps_resX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_ps_res - table_start
beq- epilogue_main
addi r4, r10, ins_ps_res_ - table_start
b epilogue_main

#Check for ps_rsqrteX
check_ps_rsqrteX:
lwz r6, 0x29C (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
lwz r0, 0x388 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_selX

#ps_rsqrteX found
andi. r0, r31, rc
two_items_left_split
addi r4, r10, ins_ps_rsqrte - table_start
beq- epilogue_main
addi r4, r10, ins_ps_rsqrte_ - table_start
b epilogue_main

#Check for ps_selX
check_ps_selX:
lwz r11, 0x2A0 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_subX

#ps_selX found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_sel - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sel_ - table_start
b epilogue_main

#Check for ps_subX
check_ps_subX:
lwz r6, 0x2A4 (r10)
check_ins_bits_oe_f
cmpw cr7, r0, r6
andi. r0, r31, 0x07C0
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_ps_sum0X

#ps_subX found
andi. r0, r31, rc
three_items_left_aligned
addi r4, r10, ins_ps_sub - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sub_ - table_start
b epilogue_main

#Check for ps_sum0X
check_ps_sum0X:
lwz r11, 0x2A8 (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_ps_sum1X

#ps_sum0X found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_sum0 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sum0_ - table_start
b epilogue_main

#Check for ps_sum1X
check_ps_sum1X:
lwz r11, 0x2AC (r10)
check_ins_bits_oe_f
cmpw r0, r11
bne+ check_rfi

#ps_sum1X found
andi. r0, r31, rc
four_items
addi r4, r10, ins_ps_sum1 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sum1_ - table_start
b epilogue_main

#Check for rfi
check_rfi:
lwz r6, 0x2B0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x384 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_rlwimiX

#rfi found
addi r4, r10, ins_rfi - table_start
b epilogue_main

#Check for rlwimiX
check_rlwimiX:
lwz r11, 0x2B4 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_rlwinmX

#rlwimiX found
andi. r0, r31, rc
five_items_logical
addi r4, r10, ins_rlwimi - table_start
beq- epilogue_main
addi r4, r10, ins_rlwimi_ - table_start
b epilogue_main

#Check for rlwinmX
check_rlwinmX:
lwz r11, 0x2B8 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_rlwnmX

#rlwinmX found (HOWEVER check for slwiX, srwiX, clrlwiX, clrrwiX, and rotlwiX)
andi. r0, r31, rc #KEEP cr0 intact throughout entire process!!!! until one of the simplified's have been found
five_items_logical
#Check for slwiX
cmpwi cr6, r8, 0 #MB must = 0
add r0, r7, r9 
cmpwi cr7, r0, 31 #SH + ME must = 31
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, check_srwiX
#slwiX found. b of the slwiX = SH value of the compiled rlwinm instruction
#SH (r7) is already in b spot (r7), no moving of register values is needed
addi r4, r10, ins_slwi - table_start
beq- epilogue_main #Now branch for rc bit
addi r4, r10, ins_slwi_ - table_start
b epilogue_main
#Check for srwiX
check_srwiX:
cmpwi cr6, r9, 31
add r0, r7, r8
cmpwi cr7, r0, 32 #SH + MB must = 32
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, check_clrlwiX
#srwiX found. b of the srwiX = MB value of the compiled rlwinm instruction
#Adjust args for sprintf so MB (r8) of compiled instruction is r7 arg (3rd sprintf value input)
mr r7, r8
addi r4, r10, ins_srwi - table_start
beq- epilogue_main #Now branch for rc bit
addi r4, r10, ins_srwi_ - table_start
b epilogue_main
#Check for clrlwiX
check_clrlwiX:
cmpwi cr6, r7, 0
cmpwi cr7, r9, 31
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, check_clrrwiX
#clrlwiX found. b of the clrlwiX = MB value of the compiled rlwinm instruction
#Adjust args for sprintf so MB (r8) of compiled instruction is r7 arg (3rd sprintf value input)
mr r7, r8
addi r4, r10, ins_clrlwi - table_start
beq- epilogue_main #Now branch for rc bit
addi r4, r10, ins_clrlwi_ - table_start
b epilogue_main
#Check for clrrwiX
check_clrrwiX:
cmpwi cr6, r7, 0
cmpwi cr7, r8, 0
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, check_rotlwiX
#clrrwiX found. b of the clrrwiX = (31-ME)
#result must also be r7 arg of sprintf value (3rd sprintf value input)
subfic r7, r9, 31
addi r4, r10, ins_clrrwi - table_start
beq- epilogue_main #Now branch for rc bit
addi r4, r10, ins_clrrwi_ - table_start
b epilogue_main
#Check for rotlwiX
check_rotlwiX:
cmpwi cr6, r8, 0 #MB must = 0
cmpwi cr7, r9, 31 #ME must = 31
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, its_regular_rlwinm
#rotlwiX found, nothing needed (other than RC check in cr0) to be done in prep for sprintf
addi r4, r10, ins_rotlwi - table_start
beq- epilogue_main
addi r4, r10, ins_rotlwi_ - table_start
b epilogue_main
#Standard rlwinm mnemonic will be used
its_regular_rlwinm:
addi r4, r10, ins_rlwinm - table_start
beq- epilogue_main
addi r4, r10, ins_rlwinm_ - table_start
b epilogue_main

#Check for rlwnmX
check_rlwnmX:
lwz r11, 0x2BC (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_sc

#rlwnmX found (HOWEVER check for rotlwX first)
andi. r0, r31, rc
five_items_logical
#Check for rotlwX
cmpwi cr6, r8, 0 #MB must = 0
cmpwi cr7, r9, 31 #ME must = 31
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, its_regular_rlwnm
#rotlwX found, nothing needed (other than RC check in cr0) be done in prep for sprintf
addi r4, r10, ins_rotlw - table_start
beq- epilogue_main
addi r4, r10, ins_rotlw_ - table_start
b epilogue_main
#Standard rlwnm mnemonic will be used
its_regular_rlwnm:
addi r4, r10, ins_rlwnm - table_start
beq- epilogue_main
addi r4, r10, ins_rlwnm_ - table_start
b epilogue_main

#Check for sc
check_sc:
lwz r6, 0x2C0 (r10)
clrrwi r0, r31, 26
rlwinm r12, r31, 0, 30, 30
or r0, r0, r12
cmpw cr7, r0, r6
lwz r0, 0x3B0 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_slwX

#sc found
addi r4, r10, ins_sc - table_start
b epilogue_main

#Check for slwX
check_slwX:
lwz r11, 0x2C4 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_srawX

#slwX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_slw - table_start
beq- epilogue_main
addi r4, r10, ins_slw_ - table_start
b epilogue_main

#Check for srawX
check_srawX:
lwz r11, 0x2C8 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_srawiX

#srawX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_sraw - table_start
beq- epilogue_main
addi r4, r10, ins_sraw_ - table_start
b epilogue_main

#Check for srawiX
check_srawiX:
lwz r11, 0x2CC (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_srwX

#srawiX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_srawi - table_start
beq- epilogue_main
addi r4, r10, ins_srawi_ - table_start
b epilogue_main

#Check for srwX
check_srwX:
lwz r11, 0x2D0 (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_stb

#srwX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_srw - table_start
beq- epilogue_main
addi r4, r10, ins_srw_ - table_start
b epilogue_main

#Check for stb
check_stb:
lwz r11, 0x2D4 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stbu

#stb found
loadstore_imm
addi r4, r10, ins_stb - table_start
b epilogue_main

#Check for stbu
check_stbu:
lwz r11, 0x2D8 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stbux

#stbu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stbu - table_start
b epilogue_main

#Check for stbux
check_stbux:
lwz r6, 0x2DC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stbx

#stbux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stbux - table_start
b epilogue_main

#Check for stbx
check_stbx:
lwz r6, 0x2E0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stfd

#stbx found
three_items_left_aligned
addi r4, r10, ins_stbx - table_start
b epilogue_main

#Check for stfd
check_stfd:
lwz r11, 0x2E4 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stfdu

#stfd found
loadstore_imm
addi r4, r10, ins_stfd - table_start
b epilogue_main

#Check for stfdu
check_stfdu:
lwz r11, 0x2E8 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stfdux

#stfdu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stfdu - table_start
b epilogue_main

#Check for stfdux
check_stfdux:
lwz r6, 0x2EC (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stfdx

#stfdux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stfdux - table_start
b epilogue_main

#Check for stfdx
check_stfdx:
lwz r6, 0x2F0 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stfiwx

#stfdx found
three_items_left_aligned
addi r4, r10, ins_stfdx - table_start
b epilogue_main

#Check for stfiwx
check_stfiwx:
lwz r6, 0x2F4 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stfs

#stfiwx found
three_items_left_aligned
addi r4, r10, ins_stfiwx - table_start
b epilogue_main

#Check for stfs
check_stfs:
lwz r11, 0x2F8 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stfsu

#stfs found
loadstore_imm
addi r4, r10, ins_stfs - table_start
b epilogue_main

#Check for stfsu
check_stfsu:
lwz r11, 0x2FC (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stfsux

#stfsu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stfsu - table_start
b epilogue_main

#Check for stfsux
check_stfsux:
lwz r6, 0x300 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stfsx

#stfsux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stfsux - table_start
b epilogue_main

#Check for stfsx
check_stfsx:
lwz r6, 0x304 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_sth

#stfsx found
three_items_left_aligned
addi r4, r10, ins_stfsx - table_start
b epilogue_main

#Check for sth
check_sth:
lwz r11, 0x308 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_sthbrx

#sth found
loadstore_imm
addi r4, r10, ins_sth - table_start
b epilogue_main

#Check for sthbrx
check_sthbrx:
lwz r6, 0x30C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_sthu

#sthbrx found
three_items_left_aligned
addi r4, r10, ins_sthbrx - table_start
b epilogue_main

#Check for sthu
check_sthu:
lwz r11, 0x310 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_sthux

#sthu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_sthu - table_start
b epilogue_main

#Check for sthux
check_sthux:
lwz r6, 0x314 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_sthx

#sthux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_sthux - table_start
b epilogue_main

#Check for sthx
check_sthx:
lwz r6, 0x318 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stmw

#sthx found
three_items_left_aligned
addi r4, r10, ins_sthx - table_start
b epilogue_main

#Check for stmw
check_stmw:
lwz r11, 0x31C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stswi

#stmw found
loadstore_imm
addi r4, r10, ins_stmw - table_start
b epilogue_main

#Check for stswi
check_stswi:
lwz r6, 0x320 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stswx

#stswi found
three_items_left_aligned
addi r4, r10, ins_stswi - table_start
b epilogue_main

#Check for stswx
check_stswx:
lwz r6, 0x324 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stw

#stswx found
three_items_left_aligned
addi r4, r10, ins_stswx - table_start
b epilogue_main

#Check for stw
check_stw:
lwz r11, 0x328 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stwbrx

#stw found
loadstore_imm
addi r4, r10, ins_stw - table_start
b epilogue_main

#Check for stwbrx
check_stwbrx:
lwz r6, 0x32C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stwcx_

#stwbrx found
three_items_left_aligned
addi r4, r10, ins_stwbrx - table_start
b epilogue_main

#Check for stwcx.
check_stwcx_:
lwz r11, 0x330 (r10)
clrrwi r0, r31, 26
rlwinm r12, r31, 0, 21, 31 #Lower 16-bit ins bits for stwcx. includes the high bit 31
or r0, r0, r12
cmpw r0, r11
bne+ check_stwu

#stwcx. found
three_items_left_aligned
addi r4, r10, ins_stwcx_ - table_start
b epilogue_main

#Check for stwu
check_stwu:
lwz r11, 0x334 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_stwux

#stwu found
loadstore_imm
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stwu - table_start
b epilogue_main

#Check for stwux
check_stwux:
lwz r6, 0x338 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_stwx

#stwux found
three_items_left_aligned
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stwux - table_start
b epilogue_main

#Check for stwx
check_stwx:
lwz r6, 0x33C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_subX

#stwx found
three_items_left_aligned
addi r4, r10, ins_stwx - table_start
b epilogue_main

#Check for subX
check_subX:
lwz r11, 0x340 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_subcX

#subX found
andi. r0, r31, oe | rc
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 21, 0x0000001F #Swap rA and rB for sub simplified mnemonic
rlwinm r7, r31, 16, 0x0000001F
addi r4, r10, ins_sub - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_sub_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_subo - table_start
beq- epilogue_main
addi r4, r10, ins_subo_ - table_start
b epilogue_main

#Check for subcX
check_subcX:
lwz r11, 0x344 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_subfeX

#subcX found
andi. r0, r31, oe | rc
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 21, 0x0000001F #Swap rA and rB for subc simplified mnemonic
rlwinm r7, r31, 16, 0x0000001F
addi r4, r10, ins_subc - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_subc_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_subco - table_start
beq- epilogue_main
addi r4, r10, ins_subco_ - table_start
b epilogue_main

#Check for subfeX
check_subfeX:
lwz r11, 0x348 (r10)
check_ins_bits_oe_yes
cmpw r0, r11
bne+ check_subfic

#subfeX found
andi. r0, r31, oe | rc
three_items_left_aligned
addi r4, r10, ins_subfe - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_subfe_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_subfeo - table_start
beq- epilogue_main
addi r4, r10, ins_subfeo_ - table_start
b epilogue_main

#Check for subfic
check_subfic:
lwz r11, 0x34C (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_subfmeX

#subfic found
nonloadstore_imm
addi r4, r10, ins_subfic - table_start
b epilogue_main

#Check for subfmeX
check_subfmeX:
lwz r6, 0x350 (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_subfzeX

#subfmeX found
andi. r0, r31, oe | rc
two_items_left_aligned
addi r4, r10, ins_subfme - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_subfme_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_subfmeo - table_start
beq- epilogue_main
addi r4, r10, ins_subfmeo_ - table_start
b epilogue_main

#Check for subfzeX
check_subfzeX:
lwz r6, 0x354 (r10)
check_ins_bits_oe_yes
cmpw cr7, r0, r6
andi. r0, r31, 0xF800
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_sync

#subfzeX found
andi. r0, r31, oe | rc
two_items_left_aligned
addi r4, r10, ins_subfze - table_start
beq- epilogue_main
cmpwi r0, rc
addi r4, r10, ins_subfze_ - table_start
beq- epilogue_main
cmpwi r0, oe
addi r4, r10, ins_subfzeo - table_start
beq- epilogue_main
addi r4, r10, ins_subfzeo_ - table_start
b epilogue_main

#Check for sync
check_sync:
lwz r6, 0x358 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x384 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_tlbie

#sync found
addi r4, r10, ins_sync - table_start
b epilogue_main

#Check for tlbie
check_tlbie:
lwz r6, 0x35C (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x3B4 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_tlbsync

#tlbie found
rlwinm r5, r31, 21, 0x0000001F
addi r4, r10, ins_tlbie - table_start
b epilogue_main

#Check for tlbsync
check_tlbsync:
lwz r6, 0x360 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
lwz r0, 0x384 (r10)
and. r0, r0, r31
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_tw

#tlbsync found
addi r4, r10, ins_tlbsync - table_start
b epilogue_main

#Check for tw
check_tw:
lwz r6, 0x364 (r10)
check_ins_bits_oe_no
cmpw cr7, r0, r6
andi. r0, r31, 0x0001
crand 4*cr6+eq, 4*cr0+eq, 4*cr7+eq
bne+ cr6, check_twi

#tw found (HOWEVER check for trap first)
three_items_left_aligned
cmpwi r5, 31
bne+ not_trap
addi r4, r10, ins_trap - table_start
b epilogue_main
not_trap:
addi r4, r10, ins_tw - table_start
b epilogue_main

#Check for twi
check_twi:
lwz r11, 0x368 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_xorX

#twi found
nonloadstore_imm
addi r4, r10, ins_twi - table_start
b epilogue_main

#Check for xorX
check_xorX:
lwz r11, 0x36C (r10)
check_ins_bits_oe_no
cmpw r0, r11
bne+ check_xori

#xorX found
andi. r0, r31, rc
three_items_logical
addi r4, r10, ins_xor - table_start
beq- epilogue_main
addi r4, r10, ins_xor_ - table_start
b epilogue_main

#Check for xori
check_xori:
lwz r11, 0x370 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ check_xoris

#xori found
logical_imm
addi r4, r10, ins_xori - table_start
b epilogue_main

#Check for xoris
check_xoris:
lwz r11, 0x374 (r10)
clrrwi r0, r31, 26
cmpw r0, r11
bne+ do_invalid

#xoris found
logical_imm
addi r4, r10, ins_xoris - table_start
b epilogue_main

#No valid instruction found
do_invalid:
addi r4, r10, invalid_instruction - table_start
mr r5, r31

#Not the correct label name, but I'm too lazy to change all the branch label names that just here, lmao.
epilogue_main:
#Pre-Call sprintf
precall_sprintf

#Setup sprintf arg 1
mr r3, r30

#Call sprintf
blrl

#Verify return of sprintf
cmpwi r3, 0
li r3, 0
bgt- 0x8
li r3, -2

#Real epilogue
lmw r30, 0x8 (sp)
lwz r0, 0x0014 (sp)
mtlr r0
addi sp, sp, 0x0010
blr

