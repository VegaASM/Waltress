/*
    Waltress - 100% Broadway Compliant PPC Assembler+Disassembler written in PPC
    Copyright (C) 2023 Vega

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
#r3 = Where to store disassembled instruction
#r4 = Instruction to disassemble

#Return values
#r3 = 0 (success)
#r3 = -1 (sprintf fail, should never happen)

.globl main_dasm
main_dasm:

#Handy Symbols
.set rc, 0x00000001
.set oe, 0x00000400
.set lk, 0x00000001
.set aa, 0x00000002

.set addX, 0x7C000214
.set addcX, 0x7C000014
.set addeX, 0x7C000114
.set addi, 0x38000000
.set addic, 0x30000000
.set addicRC, 0x34000000
.set addis, 0x3C000000
.set addmeX, 0x7C0001D4
.set addzeX, 0x7C000194
.set andX, 0x7C000038
.set andcX, 0x7C000078
.set andiRC, 0x70000000
.set andisRC, 0x74000000
.set bX, 0x48000000
.set bcX, 0x40000000
.set bcctrX, 0x4C000420
.set bclrX, 0x4C000020 
.set cmpw, 0x7C000000 
.set cmpwi, 0x2C000000 
.set cmplw, 0x7C000040 
.set cmplwi, 0x28000000 
.set cntlzwX, 0x7C000034 
.set crand, 0x4C000202 
.set crandc, 0x4C000102 
.set creqv, 0x4C000242 
.set crnand, 0x4C0001C2 
.set crnor, 0x4C000042 
.set cror, 0x4C000382 
.set crorc, 0x4C000342 
.set crxor, 0x4C000182 
.set dcbf, 0x7C0000AC 
.set dcbi, 0x7C0003AC 
.set dcbst, 0x7C00006C 
.set dcbt, 0x7C00022C 
.set dcbtst, 0x7C0001EC 
.set dcbz, 0x7C0007EC 
.set dcbz_l, 0x100007EC 
.set divwX, 0x7C0003D6 
.set divwuX, 0x7C000396 
.set eciwx, 0x7C00026C 
.set ecowx, 0x7C00036C #0xA0 
.set eieio, 0x7C0006AC #0xA4 
.set eqvX, 0x7C000238 #0xA8 
.set extsbX, 0x7C000774 #0xAC 
.set extshX, 0x7C000734 #0xB0 
.set fabsX, 0xFC000210 #0xB4 
.set faddX, 0xFC00002A #0xB8 
.set faddsX, 0xEC00002A #0xBC 
.set fcmpo, 0xFC000040 #0xC0 
.set fcmpu, 0xFC000000 #0xC4 
.set fctiwX, 0xFC00001C #0xC8 
.set fctiwzX, 0xFC00001E #0xCC 
.set fdivX, 0xFC000024 #0xD0 
.set fdivsX, 0xEC000024 #0xD4 
.set fmaddX, 0xFC00003A #0xD8 
.set fmaddsX, 0xEC00003A #0xDC 
.set fmrX, 0xFC000090 #0xE0 
.set fmsubX, 0xFC000038 #0xE4 
.set fmsubsX, 0xEC000038 #0xE8 
.set fmulX, 0xFC000032 #0xEC
.set fmulsX, 0xEC000032 #0xF0 
.set fnabsX, 0xFC000110 #0xF4 
.set fnegX, 0xFC000050 #0xF8 
.set fnmaddX, 0xFC00003E 
.set fnmaddsX, 0xEC00003E 
.set fnmsubX, 0xFC00003C 
.set fnmsubsX, 0xEC00003C #0x108 fnmsubsX
.set fresX, 0xEC000030 #0x10C fresX
.set frspX, 0xFC000018 #0x110 frspX
.set frsqrteX, 0xFC000034 #0x114 
.set fselX, 0xFC00002E #0x118 fselX
.set fsubX, 0xFC000028 #0x11C fsubX
.set fsubsX, 0xEC000028 #0x120 fsubsX
.set icbi, 0x7C0007AC #0x124 icbi
.set isync, 0x4C00012C #0x128 isync
.set lbz, 0x88000000 #0x12C lbz
.set lbzu, 0x8C000000 #0x130 lbzu
.set lbzux, 0x7C0000EE #0x134 lbzux
.set lbzx, 0x7C0000AE #0x138 lbzx
.set lfd, 0xC8000000 #0x13C lfd
.set lfdu, 0xCC000000 #0x140 lfdu
.set lfdux, 0x7C0004EE #0x144 lfdux
.set lfdx, 0x7C0004AE #0x148 lfdx
.set lfs, 0xC0000000 #0x14C lfs
.set lfsu, 0xC4000000 #0x150 lfsu
.set lfsux, 0x7C00046E #0x154 lfsux
.set lfsx, 0x7C00042E #0x158 lfsx
.set lha, 0xA8000000 #0x15C lha
.set lhau, 0xAC000000 #0x160 lhau
.set lhaux, 0x7C0002EE #0x164 lhaux
.set lhax, 0x7C0002AE #0x168 lhax
.set lhbrx, 0x7C00062C #0x16C lhbrx
.set lhz, 0xA0000000 #0x170 lhz
.set lhzu, 0xA4000000 #0x174 lhzu
.set lhzux, 0x7C00026E #0x178 lhzux
.set lhzx, 0x7C00022E #0x17C lhzx
.set lmw, 0xB8000000 #0x180 lmw
.set lswi, 0x7C0004AA #0x184 lswi
.set lswx, 0x7C00042A #0x188 lswx
.set lwarx, 0x7C000028 #0x18C lwarx
.set lwbrx, 0x7C00042C #0x190 lwbrx
.set lwz, 0x80000000 #0x194 lwz
.set lwzu, 0x84000000 #0x198 lwzu
.set lwzux, 0x7C00006E #0x19C lwzux
.set lwzx, 0x7C00002E #0x1A0 lwzx
.set mcrf, 0x4C000000 #0x1A4 mcrf
.set mcrfs, 0xFC000080 #0x1A8 mcrfs
.set mcrxr, 0x7C000400 #0x1AC mcrxr
.set mfcr, 0x7C000026 #0x1B0 mfcr
.set mffsX, 0xFC00048E #0x1B4 mffsX
.set mfmsr, 0x7C0000A6 #0x1B8 mfmsr
.set mfspr, 0x7C0002A6 #0x1BC mfspr
.set mfsr, 0x7C0004A6 #0x1C0 mfsr
.set mfsrin, 0x7C000526 #0x1C4 mfsrin
.set mftb, 0x7C0002E6 #0x1C8 mftb
.set mtcrf, 0x7C000120 #0x1CC mtcrf
.set mtfsb0X, 0xFC00008C #0x1D0 mtfsb0X
.set mtfsb1X, 0xFC00004C #0x1D4 mtfsb1X
.set mtfsfX, 0xFC00058E #0x1D8 mtfsfX
.set mtfsfiX, 0xFC00010C #0x1DC mtfsfiX
.set mtmsr, 0x7C000124 #0x1E0 mtmsr
.set mtspr, 0x7C0003A6 #0x1E4 mtspr
.set mtsr, 0x7C0001A4 #0x1E8 mtsr
.set mtsrin, 0x7C0001E4 #0x1EC mtsrin
.set mulhwX, 0x7C000096 #0x1F0 mulhwX
.set mulhwuX, 0x7C000016 #0x1F4 mulhwuX
.set mulli, 0x1C000000 #0x1F8 mulli
.set mullwX, 0x7C0001D6 #0x1FC mullwX
.set nandX, 0x7C0003B8 #0x200 nandX
.set negX, 0x7C0000D0 #0x204 negX
.set norX, 0x7C0000F8 #0x208 norX
.set orX, 0x7C000378 #0x20C orX
.set orcX, 0x7C000338 #0x210 orcX
.set ori, 0x60000000 #0x214 ori
.set oris, 0x64000000 #0x218 oris
.set psq_l, 0xE0000000 #0x21C psq_l
.set psq_lu, 0xE4000000 #0x220 psq_lu
.set psq_lux, 0x1000004C #0x224 psq_lux
.set psq_lx, 0x1000000C #0x228 psq_lx
.set psq_st, 0xF0000000 #0x22C psq_st
.set psq_stu, 0xF4000000 #0x230 psq_stu
.set psq_stux, 0x1000004E #0x234 psq_stux
.set psq_stx, 0x1000000E #0x238 psq_stx
.set ps_absX, 0x10000210 #0x23C ps_absX
.set ps_addX, 0x1000002A #0x240 ps_addX
.set ps_cmpo0, 0x10000040 #0x244 ps_cmpo0
.set ps_cmpo1, 0x100000C0 #0x248 ps_cmpo1
.set ps_cmpu0, 0x10000000 #0x24C ps_cmpu0
.set ps_cmpu1, 0x10000080 #0x250 ps_cmpu1
.set ps_divX, 0x10000024 #0x254 ps_divX
.set ps_maddX, 0x1000003A #0x258 ps_maddX
.set ps_madds0X, 0x1000001C #0x25C ps_madds0X
.set ps_madds1X, 0x1000001E #0x260 ps_madds1X
.set ps_merge00X, 0x10000420 #0x264 ps_merge00X
.set ps_merge01X, 0x10000460 #0x268 ps_merge01X
.set ps_merge10X, 0x100004A0 #0x26C ps_merge10X
.set ps_merge11X, 0x100004E0 #0x270 ps_merge11X
.set ps_mrX, 0x10000090 #0x274 ps_mrX
.set ps_msubX, 0x10000038 #0x278 ps_msubX
.set ps_mulX, 0x10000032 #0x27C ps_mulX
.set ps_muls0X, 0x10000018 #0x280 ps_muls0X
.set ps_muls1X, 0x1000001A #0x284 ps_muls1X
.set ps_nabsX, 0x10000110 #0x288 ps_nabsX
.set ps_negX, 0x10000050 #0x28C ps_negX
.set ps_nmaddX, 0x1000003E #0x290 ps_nmaddX
.set ps_nmsubX, 0x1000003C #0x294 ps_nmsubX
.set ps_resX, 0x10000030 #0x298 ps_resX
.set ps_rsqrteX, 0x10000034 #0x29C ps_rsqrteX
.set ps_selX, 0x1000002E #0x2A0 ps_selX
.set ps_subX, 0x10000028 #0x2A4 ps_subX
.set ps_sum0X, 0x10000014 #0x2A8 ps_sum0X
.set ps_sum1X, 0x10000016 #0x2AC ps_sum1X
.set rfi, 0x4C000064 #0x2B0 rfi
.set rlwimiX, 0x50000000 #0x2B4 rlwimiX
.set rlwinmX, 0x54000000 #0x2B8 rlwinmX
.set rlwnmX, 0x5C000000 #0x2BC rlwnmX
.set sc, 0x44000002 #0x2C0 sc
.set slwX, 0x7C000030 #0x2C4 slwX
.set srawX, 0x7C000630 #0x2C8 srawX
.set srawiX, 0x7C000670 #0x2CC srawiX
.set srwX, 0x7C000430 #0x2D0 srwX
.set stb, 0x98000000 #0x2D4 stb
.set stbu, 0x9C000000 #0x2D8 stbu
.set stbux, 0x7C0001EE #0x2DC stbux
.set stbx, 0x7C0001AE #0x2E0 stbx
.set stfd, 0xD8000000 #0x2E4 stfd
.set stfdu, 0xDC000000 #0x2E8 stfdu
.set stfdux, 0x7C0005EE #0x2EC stfdux
.set stfdx, 0x7C0005AE #0x2F0 stfdx
.set stfiwx, 0x7C0007AE #0x2F4 stfiwx
.set stfs, 0xD0000000 #0x2F8 stfs
.set stfsu, 0xD4000000 #0x2FC stfsu
.set stfsux, 0x7C00056E #0x300 stfsux
.set stfsx, 0x7C00052E #0x304 stfsx
.set sth, 0xB0000000 #0x308 sth
.set sthbrx, 0x7C00072C #0x30C sthbrx
.set sthu, 0xB4000000 #0x310 sthu
.set sthux, 0x7C00036E #0x314 sthux
.set sthx, 0x7C00032E #0x318 sthx
.set stmw, 0xBC000000 
.set stswi, 0x7C0005AA 
.set stswx, 0x7C00052A 
.set stw, 0x90000000 
.set stwbrx, 0x7C00052C 
.set stwcxRC, 0x7C00012D 
.set stwu, 0x94000000 
.set stwux, 0x7C00016E 
.set stwx, 0x7C00012E 
.set subX, 0x7C000050 
.set subcX, 0x7C000010
.set subfeX, 0x7C000110 
.set subfic, 0x20000000
.set subfmeX, 0x7C0001D0
.set subfzeX, 0x7C000190
.set sync, 0x7C0004AC
.set tlbie, 0x7C000264
.set tlbsync, 0x7C00046C
.set tw, 0x7C000008
.set twi, 0x0C000000
.set xorX, 0x7C000278
.set xori, 0x68000000
.set xoris, 0x6C000000

#Symbols for Secondary Check Masks
.set check_cmps1, 0x006007FF #cmpw, fcmpu, ps_cmpu0
.set check_cmps2, 0x00600001 #cmplw, fcmpo, ps_cmpo0, ps_cmpo1, ps_cmpu1
.set check_cache, 0x03E00001 #for all cache related instructions
.set check_syncs, 0x03FFF801 #for eieio, rfi, and all sync-type instructions
.set check_res_sqrt, 0x001F07C0 #for res and rsqrte type instructions
.set check_mcrf, 0x0063FFFF #mcrf
.set check_mcrfs, 0x0063F801 #0x390 mcrfs
.set check_mcrxr, 0x007FF801 #0x394 mcrxr
.set check_cr_msr, 0x001FF801 #0x398 mfcr, mfmsr, mtmsr
.set check_fs_fsb, 0x001FF800 #0x39C mffsX, mtfsb0X, mtfsb1X
.set check_sr, 0x0010F801 #0x3A0 mfsr, mtsr
.set check_srin, 0x001F0001 #0x3A4 mfsrin, mtsrin
.set check_mtcrf, 0x00100801 #0x3A8 mtcrf
.set check_mtfsfiX, 0x007F0800 #0x3AC mtfsfiX
#.set check_sc, 0x03FFFFFD #Not needed
.set check_tlbie, 0x03FF0001

#Handy macros
.macro first_check register, mask #register will be used in instruction as one of the 4 symbols below
xoris r0, \register, \mask@h
cmplwi r0, \mask@l #Don't place branch in macro so we can use label names
.endm

.set b21_30, 29 #r29, for instructions that basically have just rc
.set b22_30, 28 #r28, for instructions that basically have oe and rc
.set b25_30, 27 #r27, for some psq instructions
.set b26_30, 26 #r26, for some float & ps instructions

.macro second_check mask
lis r11, \mask@h
ori r11, r11, \mask@l
and. r11, r11, r31
.endm

.macro check_nullrA #Also used for fA. Not in second_check since we can AND it in one go
andis. r11, r31, 0x001F
.endm

.macro check_nullrB #Also used for fB. Not in second_check since we can AND it in one go
andi. r11, r31, 0xF800
.endm

.macro check_nullfC #Not in second_check since we can AND it in one go
andi. r11, r31, 0x07C0
.endm

.macro check_cmpwicmplwi #Not in second_check since we can AND it in one go
andis. r11, r31, 0x0060
.endm

.macro check_b31 #For cr ops, cache ops, ux, and x, mfspr, mftb, mtspr, stfiwx, sthbrx, lwbrx, lswi, stswi, tw .Not in second_check since we can AND it in one go
andi. r11, r31, 1
.endm

.macro check_mtfsfX #For mtfsfX. Not in second_check since we can AND it in one go
andis. r11, r31, 0x0201
.endm

.macro check_b21 #For mulhwX and mulhwuX. Not in second_check since we can AND it in one go
andi. r11, r31, 0x0200
.endm


#Macros for Handy instructions

#Macros for rD/rS/etc slot
.macro rD register
rlwinm \register, r31, 11, 0x1F
.endm

.macro rS register
rlwinm \register, r31, 11, 0x1F
.endm

#TODO remove me after adding all branch shit
.macro BO register #"rD" for cond branches
rlwinm \register, r31, 11, 0x1F
.endm

.macro crbD register
rlwinm \register, r31, 11, 0x1F
.endm

.macro fD register
rlwinm \register, r31, 11, 0x1F
.endm

.macro fS register
rlwinm \register, r31, 11, 0x1F
.endm

.macro TO register #For tw and twi
rlwinm \register, r31, 11, 0x1F
.endm

#Macro for crf's
.macro crfD register
rlwinm \register, r31, 9, 0x7
.endm

.macro crfS register
rlwinm \register, r31, 14, 0x7
.endm

#Macros for rA/fA/etc slot
.macro rA register
rlwinm \register, r31, 16, 0x1F
.endm

.macro BI register #"rA"
rlwinm \register, r31, 16, 0x1F
.endm

.macro crbA register
rlwinm \register, r31, 16, 0x1F
.endm

.macro fA register
rlwinm \register, r31, 16, 0x1F
.endm

#Macros for rB/NB/etc slot
.macro rB register
rlwinm \register, r31, 21, 0x1F
.endm

.macro fB register
rlwinm \register, r31, 21, 0x1F
.endm

.macro NB register #For lswi and stswi
rlwinm \register, r31, 21, 0x1F
.endm

.macro crbB register
rlwinm \register, r31, 21, 0x1F
.endm

.macro SH register
rlwinm \register, r31, 21, 0x1F
.endm

#Macros for rC and MB
.macro fC register
rlwinm \register, r31, 26, 0x1F
.endm

.macro MB register
rlwinm \register, r31, 26, 0x1F
.endm

#Macro for ME
.macro ME register
rlwinm \register, r31, 31, 0x1F
.endm

#Macros for IMM's
.macro SIMM register
rlwinm \register, r31, 0, 0xFFFF
extsh \register, \register
.endm

.macro UIMM register
rlwinm \register, r31, 0, 0xFFFF
.endm

.macro d register
rlwinm \register, r31, 0, 0xFFFF
extsh \register, \register
.endm

.macro LI_SIMM register #for unconditional branches
rlwinm \register, r31, 0, 0x03FFFFFC
andis. r0, \register, 0x0200
beq+ 0x8 #Forward branches are more common than backward backwards
oris \register, \register, 0xFC00
.endm

.macro BD register #SIMM for cond branches
rlwinm \register, r31, 0, 0xFFFC
extsh \register, \register
.endm

.macro ps_SIMM register #SIMM for psq's
rlwinm \register, r31, 0, 0xFFF
andi. r0, \register, 0x0800
beq+ 0xC #Postive offsets are more common than negative offsets
oris \register, \register, 0xFFFF
ori \register, \register, 0xF000
.endm

.macro IMM register #For mtfsfiX
rlwinm \register, r31, 20, 0xF
.endm

#Macro for misc registers
.macro SPR register
rlwinm \register, r31, 16, 0x1F
rlwimi \register, r31, 26, 0x3E0
.endm

.macro TBR register
rlwinm \register, r31, 16, 0x1F
rlwimi \register, r31, 26, 0x3E0
.endm

.macro SR register
rlwinm \register, r31, 16, 0xF
.endm

.macro CRM register
rlwinm \register, r31, 20, 0xFF
.endm

.macro FM register
rlwinm \register, r31, 15, 0xFF
.endm

.macro W_nonx register #W in non-indexed psq load and stores
rlwinm \register, r31, 17, 1
.endm

.macro I_nonx register #I in non-indexed psq load and stores
rlwinm \register, r31, 20, 0x7
.endm

.macro W_x register #W in indexed psq load and stores
rlwinm \register, r31, 22, 1
.endm

.macro I_x register #I in indexed psq load and stores
rlwinm \register, r31, 25, 0x7
.endm

#Following 4 macros are to allow branch simplified mnemonics to be done
.macro BO_nohint register 
rlwinm \register, r31, 10, 0xF
.endm

.macro BO_onlyhint register
rlwinm \register, r31, 11, 0x1
.endm

.macro BO_onlyhint_bcX register1 register2
#When BD is negative for bcX instruction, the hint bit has to be flipped
rlwinm \register1, r31, 17, 0x1 #Extract BD's sign bit
rlwinm \register2, r31, 11, 0x1 #Extract gross hint bit
xor \register1, \register1, \register2 #XOR it
.endm

.macro findcrbtype register
rlwinm \register, r31, 16, 0x3
.endm

.macro crfD_manual register #DOUBLE CHECK THIS
rlwinm \register, r31, 14, 0x7
.endm

#Following macros are for certain load/store instructions where extra checks need to be done, after the instruction has been 'found'. If checks fail, then it's an automatic .long instruction
.macro load_int_update_doublecheck #lbzu, lhau, lhzu, lwzu
#rA =/= rD, and rA cannot be r0
cmpw r5, r7
beq- do_invalid
cmpwi r7, 0
beq- do_invalid
.endm

.macro load_int_update_index_doublecheck #lbzux, lhaux, lhzux, lwzux
#rA =/= rD, and rA cannot be r0
cmpw r5, r6
beq- do_invalid
cmpwi r6, 0
beq- do_invalid
.endm

.macro loadstorefloat_or_storeint_update_doublecheck #lfdu, lfsu, stbu, stfdu, stfsu, sthu, stwu
#rA cannot be r0
#psq_lu and psq_stu also requires this but this macro isn't used for them (personal preference)
cmpwi r7, 0
beq- do_invalid
.endm

.macro loadstoreuxfloat_or_storeuxint_doublecheck #lfdux, lfsux, stbux, stfdux, stfsux, sthux, stwux
#rA cannot be r0
#psq_lux and psq_stux also requires this but this macro isn't used for them (personal preference)
cmpwi r6, 0
beq- do_invalid
.endm

#Prologue
stwu sp, -0x0020 (sp)
mflr r0
stw r0, 0x0024 (sp)
stw r26, 0x8 (sp)
stw r27, 0xC (sp)
stw r28, 0x10 (sp)
stw r29, 0x14 (sp)
stw r30, 0x18 (sp)
stw r31, 0x1C (sp)

#Place r4 arg in GVR
#Don't move r3 due to later call of sprintf
mr r31, r4

#Make massive lookup table; fyi capital X = Rc option
#Having this type of table instead of a typical table above results in way less overall instructions
#addi (1 instruction) is better than lis, la (2 instructions)
bl table
table_start:

#Sprintf function location spot
.long 0 

#Instruction disassembled ASCii strings
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

#Standard branch conditional mnemonics NOT needed in disassembler
#ins_bc:
#.asciz "bc %d, %d, 0x%X"
#ins_bca:
#.asciz "bca %d, %d, 0x%X"
#ins_bcl:
#.asciz "bcl %d, %d, 0x%X"
#ins_bcla:
#.asciz "bcla %d, %d, 0x%X"
#ins_bcctr:
#.asciz "bcctr %d, %d"
#ins_bcctrl:
#.asciz "bcctrl %d, %d"
#ins_bclr:
#.asciz "bclr %d, %d"
#ins_bclrl:
#.asciz "bclrl %d, %d"

#Standard mnemonics that include the L bit for compare instructions are not needed in disassembler
#ins_cmp:
#.asciz "cmp cr%d, %d, r%d, r%d"
ins_cmpw: #Simplified mnemonic for cmp crX, 0, rX, rY
.asciz "cmpw cr%d, r%d, r%d"
ins_cmpw_cr0:
.asciz "cmpw r%d, r%d"

#ins_cmpi:
#.asciz "cmpi cr%d, %d, r%d, 0x%X"
ins_cmpwi: #Simplified mnemonic for cmpi crX, 0, rX, rY
.asciz "cmpwi cr%d, r%d, 0x%X"
ins_cmpwi_cr0:
.asciz "cmpwi r%d, 0x%X"

#ins_cmpl:
#.asciz "cmpl cr%d, %d, r%d, r%d"
ins_cmplw: #Simplified mnemonic for cmpl crX, 0, rX, rY
.asciz "cmplw cr%d, r%d, r%d"
ins_cmplw_cr0:
.asciz "cmplw r%d, r%d"

#ins_cmpli:
#.asciz "cmpli cr%d, %d, r%d, 0x%X"
ins_cmplwi: #Simplified mnemonic for cmpli crX, 0, rX, rY
.asciz "cmplwi cr%d, r%d, 0x%X"
ins_cmplwi_cr0:
.asciz "cmplwi r%d, 0x%X"

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
.asciz "dcbf r%d, r%d"

ins_dcbi:
.asciz "dcbi r%d, r%d"

ins_dcbst:
.asciz "dcbst r%d, r%d"

ins_dcbt:
.asciz "dcbt r%d, r%d"

ins_dcbtst:
.asciz "dcbtst r%d, r%d"

ins_dcbz:
.asciz "dcbz r%d, r%d"

ins_dcbz_l:
.asciz "dcbz_l r%d, r%d"

ins_divw:
.asciz "divw r%d, r%d, r%d"
ins_divw_:
.asciz "divw. r%d, r%d, r%d"
ins_divwo:
.asciz "divwo r%d, r%d, r%d"
ins_divwo_:
.asciz "divwo. r%d, r%d, r%d"

ins_divwu:
.asciz "divwu r%d, r%d, r%d"
ins_divwu_:
.asciz "divwu. r%d, r%d, r%d"
ins_divwuo:
.asciz "divwuo r%d, r%d, r%d"
ins_divwuo_:
.asciz "divwuo. r%d, r%d, r%d"

ins_eciwx:
.asciz "eciwx r%d, r%d, r%d"

ins_ecowx:
.asciz "ecowx r%d, r%d, r%d"

ins_eieio:
.asciz "eieio"

ins_eqv:
.asciz "eqv r%d, r%d, r%d"
ins_eqv_:
.asciz "eqv. r%d, r%d, r%d"

ins_extsb:
.asciz "extsb r%d, r%d"
ins_extsb_:
.asciz "extsb. r%d, r%d"

ins_extsh:
.asciz "extsh r%d, r%d"
ins_extsh_:
.asciz "extsh. r%d, r%d"

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

#Not needed for disassembler
#ins_mfspr:
#.asciz "mfspr r%d, %d" #0x1998

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

#Not needed for disassembler
#ins_mtspr:
#.asciz "mtspr %d, r%d" #0x1B58

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
.asciz "stfd f%d, 0x%X (r%d)"

ins_stfdu:
.asciz "stfdu f%d, 0x%X (r%d)"

ins_stfdux:
.asciz "stfdux f%d, r%d, r%d"

ins_stfdx:
.asciz "stfdx f%d, r%d, r%d"

ins_stfiwx:
.asciz "stfiwx f%d, r%d, r%d"

ins_stfs:
.asciz "stfs f%d, 0x%X (r%d)"

ins_stfsu:
.asciz "stfsu f%d, 0x%X (r%d)"

ins_stfsux:
.asciz "stfsux f%d, r%d, r%d"

ins_stfsx:
.asciz "stfsx f%d, r%d, r%d"

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
ins_mfdsisr:
.asciz "mfdsisr r%d"
ins_mfdar:
.asciz "mfdar r%d"
ins_mfdec:
.asciz "mfdec r%d"
ins_mfsdr1:
.asciz "mfsdr1 r%d"
ins_mfsrr0:
.asciz "mfsrr0 r%d"
ins_mfsrr1:
.asciz "mfsrr1 r%d"
ins_mfsprg0:
.asciz "mfsprg0 r%d"
ins_mfsprg1:
.asciz "mfsprg1 r%d"
ins_mfsprg2:
.asciz "mfsprg2 r%d"
ins_mfsprg3:
.asciz "mfsprg3 r%d"
ins_mfear:
.asciz "mfear r%d"
ins_mfpvr:
.asciz "mfpvr r%d"
ins_mfibat0u:
.asciz "mfibat0u r%d"
ins_mfibat0l:
.asciz "mfibat0l r%d"
ins_mfibat1u:
.asciz "mfibat1u r%d"
ins_mfibat1l:
.asciz "mfibat1l r%d"
ins_mfibat2u:
.asciz "mfibat2u r%d"
ins_mfibat2l:
.asciz "mfibat2l r%d"
ins_mfibat3u:
.asciz "mfibat3u r%d"
ins_mfibat3l:
.asciz "mfibat3l r%d"
ins_mfibat4u:
.asciz "mfibat4u r%d"
ins_mfibat4l:
.asciz "mfibat4l r%d"
ins_mfibat5u:
.asciz "mfibat5u r%d"
ins_mfibat5l:
.asciz "mfibat5l r%d"
ins_mfibat6u:
.asciz "mfibat6u r%d"
ins_mfibat6l:
.asciz "mfibat6l r%d"
ins_mfibat7u:
.asciz "mfibat7u r%d"
ins_mfibat7l:
.asciz "mfibat7l r%d"
ins_mfdbat0u:
.asciz "mfdbat0u r%d"
ins_mfdbat0l:
.asciz "mfdbat0l r%d"
ins_mfdbat1u:
.asciz "mfdbat1u r%d"
ins_mfdbat1l:
.asciz "mfdbat1l r%d"
ins_mfdbat2u:
.asciz "mfdbat2u r%d"
ins_mfdbat2l:
.asciz "mfdbat2l r%d"
ins_mfdbat3u:
.asciz "mfdbat3u r%d"
ins_mfdbat3l:
.asciz "mfdbat3l r%d"
ins_mfdbat4u:
.asciz "mfdbat4u r%d"
ins_mfdbat4l:
.asciz "mfdbat4l r%d"
ins_mfdbat5u:
.asciz "mfdbat5u r%d"
ins_mfdbat5l:
.asciz "mfdbat5l r%d"
ins_mfdbat6u:
.asciz "mfdbat6u r%d"
ins_mfdbat6l:
.asciz "mfdbat6l r%d"
ins_mfdbat7u:
.asciz "mfdbat7u r%d"
ins_mfdbat7l:
.asciz "mfdbat7l r%d"
ins_mfgqr0:
.asciz "mfgqr0 r%d"
ins_mfgqr1:
.asciz "mfgqr1 r%d"
ins_mfgqr2:
.asciz "mfgqr2 r%d"
ins_mfgqr3:
.asciz "mfgqr3 r%d"
ins_mfgqr4:
.asciz "mfgqr4 r%d"
ins_mfgqr5:
.asciz "mfgqr5 r%d"
ins_mfgqr6:
.asciz "mfgqr6 r%d"
ins_mfgqr7:
.asciz "mfgqr7 r%d"
ins_mfhid2:
.asciz "mfhid2 r%d"
ins_mfwpar:
.asciz "mfwpar r%d"
ins_mfdma_u:
.asciz "mfdma_u r%d"
ins_mfdma_l:
.asciz "mfdma_l r%d"
ins_mfcidh:
.asciz "mfcidh r%d" #Special Broadway Chip IDs supported
ins_mfcidm:
.asciz "mfcidm r%d" #Special Broadway Chip IDs supported
ins_mfcidl:
.asciz "mfcidl r%d" #Special Broadway Chip IDs supported
ins_mfummcr0:
.asciz "mfummcr0 r%d"
ins_mfupmc1:
.asciz "mfupmc1 r%d"
ins_mfupmc2:
.asciz "mfupmc2 r%d"
ins_mfusia:
.asciz "mfusia r%d"
ins_mfummcr1:
.asciz "mfummcr1 r%d"
ins_mfupmc3:
.asciz "mfupmc3 r%d"
ins_mfupmc4:
.asciz "mfupmc4 r%d"
ins_mfusda:
.asciz "mfusda r%d"
ins_mfmmcr0:
.asciz "mfmmcr0 r%d"
ins_mfpmc1:
.asciz "mfpmc1 r%d"
ins_mfpmc2:
.asciz "mfpmc2 r%d"
ins_mfsia:
.asciz "mfsia r%d"
ins_mfmmcr1:
.asciz "mfmmcr1 r%d"
ins_mfpmc3:
.asciz "mfpmc3 r%d"
ins_mfpmc4:
.asciz "mfpmc4 r%d"
ins_mfsda:
.asciz "mfsda r%d"
ins_mfhid0:
.asciz "mfhid0 r%d"
ins_mfhid1:
.asciz "mfhid1 r%d"
ins_mfiabr:
.asciz "mfiabr r%d"
ins_mfhid4:
.asciz "mfhid4 r%d"
ins_mftdcl:
.asciz "mftdcl r%d"
ins_mfdabr:
.asciz "mfdabr r%d"
ins_mfl2cr:
.asciz "mfl2cr r%d"
ins_mftdch:
.asciz "mftdch r%d"
ins_mfictc:
.asciz "mfictc r%d"
ins_mfthrm1:
.asciz "mfthrm1 r%d"
ins_mfthrm2:
.asciz "mfthrm2 r%d"
ins_mfthrm3:
.asciz "mfthrm3 r%d"

#Following are mtspr simplified mnemonics, rather have these in a group than placed in alphabetically
ins_mtxer:
.asciz "mtxer r%d"
ins_mtlr:
.asciz "mtlr r%d"
ins_mtctr:
.asciz "mtctr r%d"
ins_mtdsisr:
.asciz "mtdsisr r%d"
ins_mtdar:
.asciz "mtdar r%d"
ins_mtdec:
.asciz "mtdec r%d"
ins_mtsdr1:
.asciz "mtsdr1 r%d"
ins_mtsrr0:
.asciz "mtsrr0 r%d"
ins_mtsrr1:
.asciz "mtsrr1 r%d"
ins_mtsprg0:
.asciz "mtsprg0 r%d"
ins_mtsprg1:
.asciz "mtsprg1 r%d"
ins_mtsprg2:
.asciz "mtsprg2 r%d"
ins_mtsprg3:
.asciz "mtsprg3 r%d"
ins_mtear:
.asciz "mtear r%d"
ins_mttbl:
.asciz "mttbl r%d"
ins_mttbu:
.asciz "mttbu r%d"
ins_mtibat0u:
.asciz "mtibat0u r%d"
ins_mtibat0l:
.asciz "mtibat0l r%d"
ins_mtibat1u:
.asciz "mtibat1u r%d"
ins_mtibat1l:
.asciz "mtibat1l r%d"
ins_mtibat2u:
.asciz "mtibat2u r%d"
ins_mtibat2l:
.asciz "mtibat2l r%d"
ins_mtibat3u:
.asciz "mtibat3u r%d"
ins_mtibat3l:
.asciz "mtibat3l r%d"
ins_mtibat4u:
.asciz "mtibat4u r%d"
ins_mtibat4l:
.asciz "mtibat4l r%d"
ins_mtibat5u:
.asciz "mtibat5u r%d"
ins_mtibat5l:
.asciz "mtibat5l r%d"
ins_mtibat6u:
.asciz "mtibat6u r%d"
ins_mtibat6l:
.asciz "mtibat6l r%d"
ins_mtibat7u:
.asciz "mtibat7u r%d"
ins_mtibat7l:
.asciz "mtibat7l r%d"
ins_mtdbat0u:
.asciz "mtdbat0u r%d"
ins_mtdbat0l:
.asciz "mtdbat0l r%d"
ins_mtdbat1u:
.asciz "mtdbat1u r%d"
ins_mtdbat1l:
.asciz "mtdbat1l r%d"
ins_mtdbat2u:
.asciz "mtdbat2u r%d"
ins_mtdbat2l:
.asciz "mtdbat2l r%d"
ins_mtdbat3u:
.asciz "mtdbat3u r%d"
ins_mtdbat3l:
.asciz "mtdbat3l r%d"
ins_mtdbat4u:
.asciz "mtdbat4u r%d"
ins_mtdbat4l:
.asciz "mtdbat4l r%d"
ins_mtdbat5u:
.asciz "mtdbat5u r%d"
ins_mtdbat5l:
.asciz "mtdbat5l r%d"
ins_mtdbat6u:
.asciz "mtdbat6u r%d"
ins_mtdbat6l:
.asciz "mtdbat6l r%d"
ins_mtdbat7u:
.asciz "mtdbat7u r%d"
ins_mtdbat7l:
.asciz "mtdbat7l r%d"
ins_mtgqr0:
.asciz "mtgqr0 r%d"
ins_mtgqr1:
.asciz "mtgqr1 r%d"
ins_mtgqr2:
.asciz "mtgqr2 r%d"
ins_mtgqr3:
.asciz "mtgqr3 r%d"
ins_mtgqr4:
.asciz "mtgqr4 r%d"
ins_mtgqr5:
.asciz "mtgqr5 r%d"
ins_mtgqr6:
.asciz "mtgqr6 r%d"
ins_mtgqr7:
.asciz "mtgqr7 r%d"
ins_mthid2:
.asciz "mthid2 r%d"
ins_mtwpar:
.asciz "mtwpar r%d"
ins_mtdma_u:
.asciz "mtdma_u r%d"
ins_mtdma_l:
.asciz "mtdma_l r%d"
ins_mtummcr0:
.asciz "mtummcr0 r%d"
ins_mtupmc1:
.asciz "mtupmc1 r%d"
ins_mtupmc2:
.asciz "mtupmc2 r%d"
ins_mtusia:
.asciz "mtusia r%d"
ins_mtummcr1:
.asciz "mtummcr1 r%d"
ins_mtupmc3:
.asciz "mtupmc3 r%d"
ins_mtupmc4:
.asciz "mtupmc4 r%d"
ins_mtusda:
.asciz "mtusda r%d"
ins_mtmmcr0:
.asciz "mtmmcr0 r%d"
ins_mtpmc1:
.asciz "mtpmc1 r%d"
ins_mtpmc2:
.asciz "mtpmc2 r%d"
ins_mtsia:
.asciz "mtsia r%d"
ins_mtmmcr1:
.asciz "mtmmcr1 r%d"
ins_mtpmc3:
.asciz "mtpmc3 r%d"
ins_mtpmc4:
.asciz "mtpmc4 r%d"
ins_mtsda:
.asciz "mtsda r%d"
ins_mthid0:
.asciz "mthid0 r%d"
ins_mthid1:
.asciz "mthid1 r%d"
ins_mtiabr:
.asciz "mtiabr r%d"
ins_mthid4:
.asciz "mthid4 r%d"
ins_mtdabr:
.asciz "mtdabr r%d"
ins_mtl2cr:
.asciz "mtl2cr r%d"
ins_mtictc:
.asciz "mtictc r%d"
ins_mtthrm1:
.asciz "mtthrm1 r%d"
ins_mtthrm2:
.asciz "mtthrm2 r%d"
ins_mtthrm3:
.asciz "mtthrm3 r%d"

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

#Following are all the branch simplified mnemonics
ins_bdnzf_ll:
.asciz "bdnzf- %d, 0x%X"
ins_bdnzf_ml:
.asciz "bdnzf+ %d, 0x%X"
ins_bdnzfa_ll:
.asciz "bdnzfa- %d, 0x%X"
ins_bdnzfa_ml:
.asciz "bdnzfa+ %d, 0x%X"
ins_bdnzfl_ll:
.asciz "bdnzfl- %d, 0x%X"
ins_bdnzfl_ml:
.asciz "bdnzfl+ %d, 0x%X"
ins_bdnzfla_ll:
.asciz "bdnzfla- %d, 0x%X"
ins_bdnzfla_ml:
.asciz "bdnzfla+ %d, 0x%X"

ins_bdzf_ll:
.asciz "bdzf- %d, 0x%X"
ins_bdzf_ml:
.asciz "bdzf+ %d, 0x%X"
ins_bdzfa_ll:
.asciz "bdzfa- %d, 0x%X"
ins_bdzfa_ml:
.asciz "bdzfa+ %d, 0x%X"
ins_bdzfl_ll:
.asciz "bdzfl- %d, 0x%X"
ins_bdzfl_ml:
.asciz "bdzfl+ %d, 0x%X"
ins_bdzfla_ll:
.asciz "bdzfla- %d, 0x%X"
ins_bdzfla_ml:
.asciz "bdzfla+ %d, 0x%X"

ins_bge_ll_cr0:
.asciz "bge- 0x%X"
ins_bge_ml_cr0:
.asciz "bge+ 0x%X"
ins_bgea_ll_cr0:
.asciz "bgea- 0x%X"
ins_bgea_ml_cr0:
.asciz "bgea+ 0x%X"
ins_bgel_ll_cr0:
.asciz "bgel- 0x%X"
ins_bgel_ml_cr0:
.asciz "bgel+ 0x%X"
ins_bgela_ll_cr0:
.asciz "bgela- 0x%X"
ins_bgela_ml_cr0:
.asciz "bgela+ 0x%X"
ins_bge_ll:
.asciz "bge- cr%d, 0x%X"
ins_bge_ml:
.asciz "bge+ cr%d, 0x%X"
ins_bgea_ll:
.asciz "bgea- cr%d, 0x%X"
ins_bgea_ml:
.asciz "bgea+ cr%d, 0x%X"
ins_bgel_ll:
.asciz "bgel- cr%d, 0x%X"
ins_bgel_ml:
.asciz "bgel+ cr%d, 0x%X"
ins_bgela_ll:
.asciz "bgela- cr%d, 0x%X"
ins_bgela_ml:
.asciz "bgela+ cr%d, 0x%X"

ins_ble_ll_cr0:
.asciz "ble- 0x%X"
ins_ble_ml_cr0:
.asciz "ble+ 0x%X"
ins_blea_ll_cr0:
.asciz "blea- 0x%X"
ins_blea_ml_cr0:
.asciz "blea+ 0x%X"
ins_blel_ll_cr0:
.asciz "blel- 0x%X"
ins_blel_ml_cr0:
.asciz "blel+ 0x%X"
ins_blela_ll_cr0:
.asciz "blela- 0x%X"
ins_blela_ml_cr0:
.asciz "blela+ 0x%X"
ins_ble_ll:
.asciz "ble- cr%d, 0x%X"
ins_ble_ml:
.asciz "ble+ cr%d, 0x%X"
ins_blea_ll:
.asciz "blea- cr%d, 0x%X"
ins_blea_ml:
.asciz "blea+ cr%d, 0x%X"
ins_blel_ll:
.asciz "blel- cr%d, 0x%X"
ins_blel_ml:
.asciz "blel+ cr%d, 0x%X"
ins_blela_ll:
.asciz "blela- cr%d, 0x%X"
ins_blela_ml:
.asciz "blela+ cr%d, 0x%X"

ins_bne_ll_cr0:
.asciz "bne- 0x%X"
ins_bne_ml_cr0:
.asciz "bne+ 0x%X"
ins_bnea_ll_cr0:
.asciz "bnea- 0x%X"
ins_bnea_ml_cr0:
.asciz "bnea+ 0x%X"
ins_bnel_ll_cr0:
.asciz "bnel- 0x%X"
ins_bnel_ml_cr0:
.asciz "bnel+ 0x%X"
ins_bnela_ll_cr0:
.asciz "bnela- 0x%X"
ins_bnela_ml_cr0:
.asciz "bnela+ 0x%X"
ins_bne_ll:
.asciz "bne- cr%d, 0x%X"
ins_bne_ml:
.asciz "bne+ cr%d, 0x%X"
ins_bnea_ll:
.asciz "bnea- cr%d, 0x%X"
ins_bnea_ml:
.asciz "bnea+ cr%d, 0x%X"
ins_bnel_ll:
.asciz "bnel- cr%d, 0x%X"
ins_bnel_ml:
.asciz "bnel+ cr%d, 0x%X"
ins_bnela_ll:
.asciz "bnela- cr%d, 0x%X"
ins_bnela_ml:
.asciz "bnela+ cr%d, 0x%X"

ins_bns_ll_cr0:
.asciz "bns- 0x%X"
ins_bns_ml_cr0:
.asciz "bns+ 0x%X"
ins_bnsa_ll_cr0:
.asciz "bnsa- 0x%X"
ins_bnsa_ml_cr0:
.asciz "bnsa+ 0x%X"
ins_bnsl_ll_cr0:
.asciz "bnsl- 0x%X"
ins_bnsl_ml_cr0:
.asciz "bnsl+ 0x%X"
ins_bnsla_ll_cr0:
.asciz "bnsla- 0x%X"
ins_bnsla_ml_cr0:
.asciz "bnsla+ 0x%X"
ins_bns_ll:
.asciz "bns- cr%d, 0x%X"
ins_bns_ml:
.asciz "bns+ cr%d, 0x%X"
ins_bnsa_ll:
.asciz "bnsa- cr%d, 0x%X"
ins_bnsa_ml:
.asciz "bnsa+ cr%d, 0x%X"
ins_bnsl_ll:
.asciz "bnsl- cr%d, 0x%X"
ins_bnsl_ml:
.asciz "bnsl+ cr%d, 0x%X"
ins_bnsla_ll:
.asciz "bnsla- cr%d, 0x%X"
ins_bnsla_ml:
.asciz "bnsla+ cr%d, 0x%X"

ins_bdnzt_ll:
.asciz "bdnzt- %d, 0x%X"
ins_bdnzt_ml:
.asciz "bdnzt+ %d, 0x%X"
ins_bdnzta_ll:
.asciz "bdnzta- %d, 0x%X"
ins_bdnzta_ml:
.asciz "bdnzta+ %d, 0x%X"
ins_bdnztl_ll:
.asciz "bdnztl- %d, 0x%X"
ins_bdnztl_ml:
.asciz "bdnztl+ %d, 0x%X"
ins_bdnztla_ll:
.asciz "bdnztla- %d, 0x%X"
ins_bdnztla_ml:
.asciz "bdnztla+ %d, 0x%X"

ins_bdzt_ll:
.asciz "bdzt- %d, 0x%X"
ins_bdzt_ml:
.asciz "bdzt+ %d, 0x%X"
ins_bdzta_ll:
.asciz "bdzta- %d, 0x%X"
ins_bdzta_ml:
.asciz "bdzta+ %d, 0x%X"
ins_bdztl_ll:
.asciz "bdztl- %d, 0x%X"
ins_bdztl_ml:
.asciz "bdztl+ %d, 0x%X"
ins_bdztla_ll:
.asciz "bdztla- %d, 0x%X"
ins_bdztla_ml:
.asciz "bdztla+ %d, 0x%X"

ins_blt_ll_cr0:
.asciz "blt- 0x%X"
ins_blt_ml_cr0:
.asciz "blt+ 0x%X"
ins_blta_ll_cr0:
.asciz "blta- 0x%X"
ins_blta_ml_cr0:
.asciz "blta+ 0x%X"
ins_bltl_ll_cr0:
.asciz "bltl- 0x%X"
ins_bltl_ml_cr0:
.asciz "bltl+ 0x%X"
ins_bltla_ll_cr0:
.asciz "bltla- 0x%X"
ins_bltla_ml_cr0:
.asciz "bltla+ 0x%X"
ins_blt_ll:
.asciz "blt- cr%d, 0x%X"
ins_blt_ml:
.asciz "blt+ cr%d, 0x%X"
ins_blta_ll:
.asciz "blta- cr%d, 0x%X"
ins_blta_ml:
.asciz "blta+ cr%d, 0x%X"
ins_bltl_ll:
.asciz "bltl- cr%d, 0x%X"
ins_bltl_ml:
.asciz "bltl+ cr%d, 0x%X"
ins_bltla_ll:
.asciz "bltla- cr%d, 0x%X"
ins_bltla_ml:
.asciz "bltla+ cr%d, 0x%X"

ins_bgt_ll_cr0:
.asciz "bgt- 0x%X"
ins_bgt_ml_cr0:
.asciz "bgt+ 0x%X"
ins_bgta_ll_cr0:
.asciz "bgta- 0x%X"
ins_bgta_ml_cr0:
.asciz "bgta+ 0x%X"
ins_bgtl_ll_cr0:
.asciz "bgtl- 0x%X"
ins_bgtl_ml_cr0:
.asciz "bgtl+ 0x%X"
ins_bgtla_ll_cr0:
.asciz "bgtla- 0x%X"
ins_bgtla_ml_cr0:
.asciz "bgtla+ 0x%X"
ins_bgt_ll:
.asciz "bgt- cr%d, 0x%X"
ins_bgt_ml:
.asciz "bgt+ cr%d, 0x%X"
ins_bgta_ll:
.asciz "bgta- cr%d, 0x%X"
ins_bgta_ml:
.asciz "bgta+ cr%d, 0x%X"
ins_bgtl_ll:
.asciz "bgtl- cr%d, 0x%X"
ins_bgtl_ml:
.asciz "bgtl+ cr%d, 0x%X"
ins_bgtla_ll:
.asciz "bgtla- cr%d, 0x%X"
ins_bgtla_ml:
.asciz "bgtla+ cr%d, 0x%X"

ins_beq_ll_cr0:
.asciz "beq- 0x%X"
ins_beq_ml_cr0:
.asciz "beq+ 0x%X"
ins_beqa_ll_cr0:
.asciz "beqa- 0x%X"
ins_beqa_ml_cr0:
.asciz "beqa+ 0x%X"
ins_beql_ll_cr0:
.asciz "beql- 0x%X"
ins_beql_ml_cr0:
.asciz "beql+ 0x%X"
ins_beqla_ll_cr0:
.asciz "beqla- 0x%X"
ins_beqla_ml_cr0:
.asciz "beqla+ 0x%X"
ins_beq_ll:
.asciz "beq- cr%d, 0x%X"
ins_beq_ml:
.asciz "beq+ cr%d, 0x%X"
ins_beqa_ll:
.asciz "beqa- cr%d, 0x%X"
ins_beqa_ml:
.asciz "beqa+ cr%d, 0x%X"
ins_beql_ll:
.asciz "beql- cr%d, 0x%X"
ins_beql_ml:
.asciz "beql+ cr%d, 0x%X"
ins_beqla_ll:
.asciz "beqla- cr%d, 0x%X"
ins_beqla_ml:
.asciz "beqla+ cr%d, 0x%X"

ins_bso_ll_cr0:
.asciz "bso- 0x%X"
ins_bso_ml_cr0:
.asciz "bso+ 0x%X"
ins_bsoa_ll_cr0:
.asciz "bsoa- 0x%X"
ins_bsoa_ml_cr0:
.asciz "bsoa+ 0x%X"
ins_bsol_ll_cr0:
.asciz "bsol- 0x%X"
ins_bsol_ml_cr0:
.asciz "bsol+ 0x%X"
ins_bsola_ll_cr0:
.asciz "bsola- 0x%X"
ins_bsola_ml_cr0:
.asciz "bsola+ 0x%X"
ins_bso_ll:
.asciz "bso- cr%d, 0x%X"
ins_bso_ml:
.asciz "bso+ cr%d, 0x%X"
ins_bsoa_ll:
.asciz "bsoa- cr%d, 0x%X"
ins_bsoa_ml:
.asciz "bsoa+ cr%d, 0x%X"
ins_bsol_ll:
.asciz "bsol- cr%d, 0x%X"
ins_bsol_ml:
.asciz "bsol+ cr%d, 0x%X"
ins_bsola_ll:
.asciz "bsola- cr%d, 0x%X"
ins_bsola_ml:
.asciz "bsola+ cr%d, 0x%X"

ins_bdnz_ll:
.asciz "bdnz- 0x%X"
ins_bdnz_ml:
.asciz "bdnz+ 0x%X"
ins_bdnza_ll:
.asciz "bdnza- 0x%X"
ins_bdnza_ml:
.asciz "bdnza+ 0x%X"
ins_bdnzl_ll:
.asciz "bdnzl- 0x%X"
ins_bdnzl_ml:
.asciz "bdnzl+ 0x%X"
ins_bdnzla_ll:
.asciz "bdnzla- 0x%X"
ins_bdnzla_ml:
.asciz "bdnzla+ 0x%X"

ins_bdz_ll:
.asciz "bdz- 0x%X"
ins_bdz_ml:
.asciz "bdz+ 0x%X"
ins_bdza_ll:
.asciz "bdza- 0x%X"
ins_bdza_ml:
.asciz "bdza+ 0x%X"
ins_bdzl_ll:
.asciz "bdzl- 0x%X"
ins_bdzl_ml:
.asciz "bdzl+ 0x%X"
ins_bdzla_ll:
.asciz "bdzla- 0x%X"
ins_bdzla_ml:
.asciz "bdzla+ 0x%X"

ins_bcalways:
.asciz "bal 0x%0X"
ins_bcalwaysA:
.asciz "bala 0x%0X"
ins_bcalwaysL:
.asciz "ball 0x%0X"
ins_bcalwaysAL:
.asciz "balla 0x%0X"

#
ins_bdnzfctr_ll:
.asciz "bdnzfctr- %d"
ins_bdnzfctr_ml:
.asciz "bdnzfctr+ %d"
ins_bdnzfctrl_ll:
.asciz "bdnzfctrl- %d"
ins_bdnzfctrl_ml:
.asciz "bdnzfctrl+ %d"

ins_bdzfctr_ll:
.asciz "bdzfctr- %d"
ins_bdzfctr_ml:
.asciz "bdzfctr+ %d"
ins_bdzfctrl_ll:
.asciz "bdzfctrl- %d"
ins_bdzfctrl_ml:
.asciz "bdzfctrl+ %d"

ins_bgectr_ll_cr0:
.asciz "bgectr-"
ins_bgectr_ml_cr0:
.asciz "bgectr+"
ins_bgectrl_ll_cr0:
.asciz "bgectrl-"
ins_bgectrl_ml_cr0:
.asciz "bgectrl+"
ins_bgectr_ll:
.asciz "bgectr- cr%d"
ins_bgectr_ml:
.asciz "bgectr+ cr%d"
ins_bgectrl_ll:
.asciz "bgectrl- cr%d"
ins_bgectrl_ml:
.asciz "bgectrl+ cr%d"

ins_blectr_ll_cr0:
.asciz "blectr-"
ins_blectr_ml_cr0:
.asciz "blectr+"
ins_blectrl_ll_cr0:
.asciz "blectrl-"
ins_blectrl_ml_cr0:
.asciz "blectrl+"
ins_blectr_ll:
.asciz "blectr- cr%d"
ins_blectr_ml:
.asciz "blectr+ cr%d"
ins_blectrl_ll:
.asciz "blectrl- cr%d"
ins_blectrl_ml:
.asciz "blectrl+ cr%d"

ins_bnectr_ll_cr0:
.asciz "bnectr-"
ins_bnectr_ml_cr0:
.asciz "bnectr+"
ins_bnectrl_ll_cr0:
.asciz "bnectrl-"
ins_bnectrl_ml_cr0:
.asciz "bnectrl+"
ins_bnectr_ll:
.asciz "bnectr- cr%d"
ins_bnectr_ml:
.asciz "bnectr+ cr%d"
ins_bnectrl_ll:
.asciz "bnectrl- cr%d"
ins_bnectrl_ml:
.asciz "bnectrl+ cr%d"

ins_bnsctr_ll_cr0:
.asciz "bnsctr-"
ins_bnsctr_ml_cr0:
.asciz "bnsctr+"
ins_bnsctrl_ll_cr0:
.asciz "bnsctrl-"
ins_bnsctrl_ml_cr0:
.asciz "bnsctrl+"
ins_bnsctr_ll:
.asciz "bnsctr- cr%d"
ins_bnsctr_ml:
.asciz "bnsctr+ cr%d"
ins_bnsctrl_ll:
.asciz "bnsctrl- cr%d"
ins_bnsctrl_ml:
.asciz "bnsctrl+ cr%d"

ins_bdnztctr_ll:
.asciz "bdnztctr- %d"
ins_bdnztctr_ml:
.asciz "bdnztctr+ %d"
ins_bdnztctrl_ll:
.asciz "bdnztctrl- %d"
ins_bdnztctrl_ml:
.asciz "bdnztctrl+ %d"

ins_bdztctr_ll:
.asciz "bdztctr- %d"
ins_bdztctr_ml:
.asciz "bdztctr+ %d"
ins_bdztctrl_ll:
.asciz "bdztctrl- %d"
ins_bdztctrl_ml:
.asciz "bdztctrl+ %d"

ins_bltctr_ll_cr0:
.asciz "bltctr-"
ins_bltctr_ml_cr0:
.asciz "bltctr+"
ins_bltctrl_ll_cr0:
.asciz "bltctrl-"
ins_bltctrl_ml_cr0:
.asciz "bltctrl+"
ins_bltctr_ll:
.asciz "bltctr- cr%d"
ins_bltctr_ml:
.asciz "bltctr+ cr%d"
ins_bltctrl_ll:
.asciz "bltctrl- cr%d"
ins_bltctrl_ml:
.asciz "bltctrl+ cr%d"

ins_bgtctr_ll_cr0:
.asciz "bgtctr-"
ins_bgtctr_ml_cr0:
.asciz "bgtctr+"
ins_bgtctrl_ll_cr0:
.asciz "bgtctrl-"
ins_bgtctrl_ml_cr0:
.asciz "bgtctrl+"
ins_bgtctr_ll:
.asciz "bgtctr- cr%d"
ins_bgtctr_ml:
.asciz "bgtctr+ cr%d"
ins_bgtctrl_ll:
.asciz "bgtctrl- cr%d"
ins_bgtctrl_ml:
.asciz "bgtctrl+ cr%d"

ins_beqctr_ll_cr0:
.asciz "beqctr-"
ins_beqctr_ml_cr0:
.asciz "beqctr+"
ins_beqctrl_ll_cr0:
.asciz "beqctrl-"
ins_beqctrl_ml_cr0:
.asciz "beqctrl+"
ins_beqctr_ll:
.asciz "beqctr- cr%d"
ins_beqctr_ml:
.asciz "beqctr+ cr%d"
ins_beqctrl_ll:
.asciz "beqctrl- cr%d"
ins_beqctrl_ml:
.asciz "beqctrl+ cr%d"

ins_bsoctr_ll_cr0:
.asciz "bsoctr-"
ins_bsoctr_ml_cr0:
.asciz "bsoctr+"
ins_bsoctrl_ll_cr0:
.asciz "bsoctrl-"
ins_bsoctrl_ml_cr0:
.asciz "bsoctrl+"
ins_bsoctr_ll:
.asciz "bsoctr- cr%d"
ins_bsoctr_ml:
.asciz "bsoctr+ cr%d"
ins_bsoctrl_ll:
.asciz "bsoctrl- cr%d"
ins_bsoctrl_ml:
.asciz "bsoctrl+ cr%d"

ins_bdnzctr_ll:
.asciz "bdnzctr-"
ins_bdnzctr_ml:
.asciz "bdnzctr+"
ins_bdnzctrl_ll:
.asciz "bdnzctrl-"
ins_bdnzctrl_ml:
.asciz "bdnzctrl+"

ins_bdzctr_ll:
.asciz "bdzctr-"
ins_bdzctr_ml:
.asciz "bdzctr+"
ins_bdzctrl_ll:
.asciz "bdzctrl-"
ins_bdzctrl_ml:
.asciz "bdzctrl+"

ins_bctr:
.asciz "bctr"
ins_bctrl:
.asciz "bctrl"

#
ins_bdnzflr_ll:
.asciz "bdnzflr- %d"
ins_bdnzflr_ml:
.asciz "bdnzflr+ %d"
ins_bdnzflrl_ll:
.asciz "bdnzflrl- %d"
ins_bdnzflrl_ml:
.asciz "bdnzflrl+ %d"

ins_bdzflr_ll:
.asciz "bdzflr- %d"
ins_bdzflr_ml:
.asciz "bdzflr+ %d"
ins_bdzflrl_ll:
.asciz "bdzflrl- %d"
ins_bdzflrl_ml:
.asciz "bdzflrl+ %d"

ins_bgelr_ll_cr0:
.asciz "bgelr-"
ins_bgelr_ml_cr0:
.asciz "bgelr+"
ins_bgelrl_ll_cr0:
.asciz "bgelrl-"
ins_bgelrl_ml_cr0:
.asciz "bgelrl+"
ins_bgelr_ll:
.asciz "bgelr- cr%d"
ins_bgelr_ml:
.asciz "bgelr+ cr%d"
ins_bgelrl_ll:
.asciz "bgelrl- cr%d"
ins_bgelrl_ml:
.asciz "bgelrl+ cr%d"

ins_blelr_ll_cr0:
.asciz "blelr-"
ins_blelr_ml_cr0:
.asciz "blelr+"
ins_blelrl_ll_cr0:
.asciz "blelrl-"
ins_blelrl_ml_cr0:
.asciz "blelrl+"
ins_blelr_ll:
.asciz "blelr- cr%d"
ins_blelr_ml:
.asciz "blelr+ cr%d"
ins_blelrl_ll:
.asciz "blelrl- cr%d"
ins_blelrl_ml:
.asciz "blelrl+ cr%d"

ins_bnelr_ll_cr0:
.asciz "bnelr-"
ins_bnelr_ml_cr0:
.asciz "bnelr+"
ins_bnelrl_ll_cr0:
.asciz "bnelrl-"
ins_bnelrl_ml_cr0:
.asciz "bnelrl+"
ins_bnelr_ll:
.asciz "bnelr- cr%d"
ins_bnelr_ml:
.asciz "bnelr+ cr%d"
ins_bnelrl_ll:
.asciz "bnelrl- cr%d"
ins_bnelrl_ml:
.asciz "bnelrl+ cr%d"

ins_bnslr_ll_cr0:
.asciz "bnslr-"
ins_bnslr_ml_cr0:
.asciz "bnslr+"
ins_bnslrl_ll_cr0:
.asciz "bnslrl-"
ins_bnslrl_ml_cr0:
.asciz "bnslrl+"
ins_bnslr_ll:
.asciz "bnslr- cr%d"
ins_bnslr_ml:
.asciz "bnslr+ cr%d"
ins_bnslrl_ll:
.asciz "bnslrl- cr%d"
ins_bnslrl_ml:
.asciz "bnslrl+ cr%d"

ins_bdnztlr_ll:
.asciz "bdnztlr- %d"
ins_bdnztlr_ml:
.asciz "bdnztlr+ %d"
ins_bdnztlrl_ll:
.asciz "bdnztlrl- %d"
ins_bdnztlrl_ml:
.asciz "bdnztlrl+ %d"

ins_bdztlr_ll:
.asciz "bdztlr- %d"
ins_bdztlr_ml:
.asciz "bdztlr+ %d"
ins_bdztlrl_ll:
.asciz "bdztlrl- %d"
ins_bdztlrl_ml:
.asciz "bdztlrl+ %d"

ins_bltlr_ll_cr0:
.asciz "bltlr-"
ins_bltlr_ml_cr0:
.asciz "bltlr+"
ins_bltlrl_ll_cr0:
.asciz "bltlrl-"
ins_bltlrl_ml_cr0:
.asciz "bltlrl+"
ins_bltlr_ll:
.asciz "bltlr- cr%d"
ins_bltlr_ml:
.asciz "bltlr+ cr%d"
ins_bltlrl_ll:
.asciz "bltlrl- cr%d"
ins_bltlrl_ml:
.asciz "bltlrl+ cr%d"

ins_bgtlr_ll_cr0:
.asciz "bgtlr-"
ins_bgtlr_ml_cr0:
.asciz "bgtlr+"
ins_bgtlrl_ll_cr0:
.asciz "bgtlrl-"
ins_bgtlrl_ml_cr0:
.asciz "bgtlrl+"
ins_bgtlr_ll:
.asciz "bgtlr- cr%d"
ins_bgtlr_ml:
.asciz "bgtlr+ cr%d"
ins_bgtlrl_ll:
.asciz "bgtlrl- cr%d"
ins_bgtlrl_ml:
.asciz "bgtlrl+ cr%d"

ins_beqlr_ll_cr0:
.asciz "beqlr-"
ins_beqlr_ml_cr0:
.asciz "beqlr+"
ins_beqlrl_ll_cr0:
.asciz "beqlrl-"
ins_beqlrl_ml_cr0:
.asciz "beqlrl+"
ins_beqlr_ll:
.asciz "beqlr- cr%d"
ins_beqlr_ml:
.asciz "beqlr+ cr%d"
ins_beqlrl_ll:
.asciz "beqlrl- cr%d"
ins_beqlrl_ml:
.asciz "beqlrl+ cr%d"

ins_bsolr_ll_cr0:
.asciz "bsolr-"
ins_bsolr_ml_cr0:
.asciz "bsolr+"
ins_bsolrl_ll_cr0:
.asciz "bsolrl-"
ins_bsolrl_ml_cr0:
.asciz "bsolrl+"
ins_bsolr_ll:
.asciz "bsolr- cr%d"
ins_bsolr_ml:
.asciz "bsolr+ cr%d"
ins_bsolrl_ll:
.asciz "bsolrl- cr%d"
ins_bsolrl_ml:
.asciz "bsolrl+ cr%d"

ins_bdnzlr_ll:
.asciz "bdnzlr-"
ins_bdnzlr_ml:
.asciz "bdnzlr+"
ins_bdnzlrl_ll:
.asciz "bdnzlrl-"
ins_bdnzlrl_ml:
.asciz "bdnzlrl+"

ins_bdzlr_ll:
.asciz "bdzlr-"
ins_bdzlr_ml:
.asciz "bdzlr+"
ins_bdzlrl_ll:
.asciz "bdzlrl-"
ins_bdzlrl_ml:
.asciz "bdzlrl+"

ins_blr:
.asciz "blr"
ins_blrl:
.asciz "blrl"

#No valid instruction
invalid_instruction:
.asciz ".long 0x%08X"
.align 2

table:
mflr r10

#Place Opcode in r30
clrrwi r30, r31, 26

#Place possible Secondary bits 21 thru 30 in r29
mr r29, r30
rlwimi r29, r31, 0, 21, 30

#Place possible Secondary bits 22 thru 30 in r28
rlwinm r28, r29, 0, 22, 20 #Drop bit 21

#Place possible Secondary bits 25 thru 30 in r27
rlwinm r27, r28, 0, 25, 21 #Now drop bits 22, 23, and 24

#place possible Secondary bits 26 thru 30 in r26
rlwinm r26, r27, 0, 26, 24 #Now drop bit 25

#Now rotate left r30 by 16 for easy checks
rotlwi r30, r30, 16

#!!START THE SEARCH!!#

#Check for addX
first_check b22_30, addX
bne+ check_addcX

#addX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
first_check b22_30 addcX
bne+ check_addeX

#addcX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
first_check b22_30 addeX
bne+ check_addi

#addeX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
cmplwi r30, addi@h
bne+ check_addic

#addi found (HOWEVER check for li as well)
rD r5
rA r6
SIMM r7
#It's li if rA = r0. which means r6 = 0 from nonloadstore_imm
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
cmplwi r30, addic@h
bne+ check_addic_

#addic found
rD r5
rA r6
SIMM r7
addi r4, r10, ins_addic - table_start
b epilogue_main

#Check for addic.
check_addic_:
cmplwi r30, addicRC@h
bne+ check_addis

#addic. found
rD r5
rA r6
SIMM r7
addi r4, r10, ins_addic_ - table_start
b epilogue_main

#Check for addis
check_addis:
cmplwi r30, addis@h
bne+ check_addmeX

#addis found (HOWEVER check for lis as well)
rD r5
rA r6
SIMM r7
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
first_check b22_30, addmeX
bne+ check_addzeX
check_nullrB
bne- check_addzeX

#addmeX found
rD r5
rA r6
andi. r0, r31, oe | rc
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
first_check b22_30, addzeX
bne+ check_andX
check_nullrB
bne- check_andX

#addzeX found
rD r5
rA r6
andi. r0, r31, oe | rc
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
first_check b21_30, andX
bne+ check_andcX

#andX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_and - table_start
beq- epilogue_main
addi r4, r10, ins_and_ - table_start
b epilogue_main

#Check for andcX
check_andcX:
first_check b21_30, andcX
bne+ check_andi_

#andcX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_andc - table_start
beq- epilogue_main
addi r4, r10, ins_andc_ - table_start
b epilogue_main

#Check for andi.
check_andi_:
cmplwi r30, andiRC@h
bne+ check_andis_

#andi. found
rA r5
rS r6
UIMM r7
addi r4, r10, ins_andi_ - table_start
b epilogue_main

#Check for andis.
check_andis_:
cmplwi r30, andisRC@h
bne+ check_bX

#andis. found
rA r5
rS r6
UIMM r7
addi r4, r10, ins_andis_ - table_start
b epilogue_main

#Check for bX
check_bX:
cmplwi r30, bX@h
bne+ check_bcX

#bX found
LI_SIMM r5
andi. r0, r31, aa | lk
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
cmplwi r30, bcX@h
bne+ check_bcctrX

#bcX found
BI r5
BD r6
crfD_manual r7
findcrbtype r8

#Check branch hint *FIRST*
BO_onlyhint_bcX r0, r9 #r3 thru r10 already taken
cmpwi cr7, r0, 1 #EQ of cr7 set high if branch hint + is present

BO_nohint r9

#Check for bdnzf+- type
cmpwi r9, 0x0
bne+ check_bdzf

#Found bdnzf+- type
beq- cr7, found_bdnzfPLUS
andi. r0, r31, aa | lk
addi r4, r10, ins_bdnzf_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdnzfa_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdnzfl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzfla_ll - table_start
b epilogue_main

found_bdnzfPLUS:
andi. r0, r31, aa | lk
addi r4, r10, ins_bdnzf_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdnzfa_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdnzfl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzfla_ml - table_start
b epilogue_main

#=====================

#Check for bdzf+- type
check_bdzf:
cmpwi r9, 0x1
bne+ check_bgeblebnebns

#Found bdzf+- type
beq- cr7, found_bdzfPLUS
andi. r0, r31, aa | lk
addi r4, r10, ins_bdzf_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdzfa_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdzfl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdzfla_ll - table_start
b epilogue_main

found_bdzfPLUS:
andi. r0, r31, aa | lk
addi r4, r10, ins_bdzf_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdzfa_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdzfl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdzfla_ml - table_start
b epilogue_main

#======================

#Check for bge,ble,bne,bns
check_bgeblebnebns:
cmpwi r9, 0x2
bne+ check_bdnzt

#Found bge,ble,bne,bns
mr r5, r7 #crF needs to be in r5 for sprintf, r6 already set
cmpwi r8, 0
beq- bge_variant
cmpwi r8, 1
beq- ble_variant
cmpwi r8, 2
beq- bne_variant

#bns variant found, check hint bit (cr7 result)
bns_variant:
beq- cr7, bnsPLUSfound

#bns- found
cmpwi r5, 0
beq+ bnsMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bns_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnsa_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnsl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bnsla_ll - table_start
b epilogue_main

#bns- cr0 found
bnsMINUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bns_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnsa_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnsl_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnsla_ll_cr0 - table_start
b epilogue_main

#bns+ found
bnsPLUSfound:
cmpwi r5, 0
beq+ bnsPLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bns_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnsa_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnsl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bnsla_ml - table_start
b epilogue_main

bnsPLUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bns_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnsa_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnsl_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnsla_ml_cr0 - table_start
b epilogue_main

#bge variant found, check hint bit (cr7 result)
bge_variant:
beq- cr7, bgePLUSfound

#bge- found
cmpwi r5, 0
beq+ bgeMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bge_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgea_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgel_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bgela_ll - table_start
b epilogue_main

bgeMINUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bge_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgea_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgel_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgela_ll_cr0 - table_start
b epilogue_main

#bge+ found
bgePLUSfound:
cmpwi r5, 0
beq+ bgePLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bge_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgea_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgel_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bgela_ml - table_start
b epilogue_main

bgePLUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bge_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgea_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgel_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgela_ml_cr0 - table_start
b epilogue_main

#ble variant found, check hint bit (cr7 result)
ble_variant:
beq- cr7, blePLUSfound

#ble- found
cmpwi r5, 0
beq- bleMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_ble_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blea_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_blel_ll - table_start
beq- epilogue_main
addi r4, r10, ins_blela_ll - table_start
b epilogue_main

bleMINUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_ble_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blea_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_blel_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_blela_ll_cr0 - table_start
b epilogue_main

#ble+ found
blePLUSfound:
cmpwi r5, 0
beq+ blePLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_ble_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blea_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_blel_ml - table_start
beq- epilogue_main
addi r4, r10, ins_blela_ml - table_start
b epilogue_main

blePLUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_ble_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blea_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_blel_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_blela_ml_cr0 - table_start
b epilogue_main

#bne variant found, check hint bit (cr7 result)
bne_variant:
beq- cr7, bnePLUSfound

#bne- found
cmpwi r5, 0
beq+ bneMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bne_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnea_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnel_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bnela_ll - table_start
b epilogue_main

bneMINUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bne_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnea_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnel_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnela_ll_cr0 - table_start
b epilogue_main

#bne+ found
bnePLUSfound:
cmpwi r5, 0
beq+ bnePLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bne_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnea_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnel_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bnela_ml - table_start
b epilogue_main

bnePLUScr0found:
mr r5, r6 #Place BD into r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bne_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bnea_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bnel_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnela_ml_cr0 - table_start
b epilogue_main

#============================

#Check for bdnzt+-
check_bdnzt:
cmpwi r9, 0x4
bne+ check_bdzt

#bdnzt+- found
beq- cr7, found_bdnztPLUS
andi. r0, r31, aa | lk
addi r4, r10, ins_bdnzt_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdnzta_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdnztl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnztla_ll - table_start
b epilogue_main

#found bdnzt+
found_bdnztPLUS:
andi. r0, r31, aa | lk
addi r4, r10, ins_bdnzt_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdnzta_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdnztl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnztla_ml - table_start
b epilogue_main

#=========================

#Check fo bdzt+-
check_bdzt:
cmpwi r9, 0x5
bne+ check_bltbgtbeqbso

#bdzt+- found
beq- cr7, found_bdztPLUS
andi. r0, r31, aa | lk
addi r4, r10, ins_bdzt_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdzta_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdztl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdztla_ll - table_start
b epilogue_main

#found bdzt+
found_bdztPLUS:
andi. r0, r31, aa | lk
addi r4, r10, ins_bdzt_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdzta_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdztl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdztla_ml - table_start
b epilogue_main

#=========================

#Check for the common shit that EXcludes bne, bns
check_bltbgtbeqbso:
cmpwi r9, 0x6
bne+ check_bdnz

#Common bc variant found
#Check BI for blt, bgt, beq, bso
mr r5, r7 #crF needs to be in r5 for sprintf, r6 already set
cmpwi r8, 0
beq- blt_variant
cmpwi r8, 1
beq- bgt_variant
cmpwi r8, 2
beq- beq_variant

#bso variant found, check hint bit (cr7 result)
bso_variant:
beq- cr7, bsoPLUSfound

#bso- found
cmpwi r5, 0
beq+ bsoMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bso_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bsoa_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bsol_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bsola_ll - table_start
b epilogue_main

bsoMINUScr0found:
mr r5, r6 #BD needs to be in r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bso_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bsoa_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bsol_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bsola_ll_cr0 - table_start
b epilogue_main

#bso+ found
bsoPLUSfound:
cmpwi r5, 0
beq+ bsoPLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bso_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bsoa_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bsol_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bsola_ml - table_start
b epilogue_main

bsoPLUScr0found:
mr r5, r6 #cuz sprintf 
andi. r0, r31, aa | lk
addi r4, r10, ins_bso_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bsoa_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bsol_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bsola_ml_cr0 - table_start
b epilogue_main

#blt variant found, check hint bit (cr7 result)
blt_variant:
beq- cr7, bltPLUSfound

#blt- found
cmpwi r5, 0
beq+ bltMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_blt_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blta_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bltl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bltla_ll - table_start
b epilogue_main

bltMINUScr0found:
mr r5, r6
andi. r0, r31, aa | lk
addi r4, r10, ins_blt_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blta_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bltl_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bltla_ll_cr0 - table_start
b epilogue_main

#blt+ found
bltPLUSfound:
cmpwi r5, 0
beq+ bltPLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_blt_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blta_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bltl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bltla_ml - table_start
b epilogue_main

bltPLUScr0found:
mr r5, r6
andi. r0, r31, aa | lk
addi r4, r10, ins_blt_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_blta_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bltl_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bltla_ml_cr0 - table_start
b epilogue_main

#bgt variant found, check hint bit (cr7 result)
bgt_variant:
beq- cr7, bgtPLUSfound

#bgt- found
cmpwi r5, 0
beq+ bgtMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bgt_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgta_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgtl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bgtla_ll - table_start
b epilogue_main

bgtMINUScr0found:
mr r5, r6
andi. r0, r31, aa | lk
addi r4, r10, ins_bgt_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgta_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgtl_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgtla_ll_cr0 - table_start
b epilogue_main

#bgt+ found
bgtPLUSfound:
cmpwi r5, 0
beq+ bgtPLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_bgt_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgta_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgtl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bgtla_ml - table_start
b epilogue_main

bgtPLUScr0found:
mr r5, r6
andi. r0, r31, aa | lk
addi r4, r10, ins_bgt_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bgta_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bgtl_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgtla_ml_cr0 - table_start
b epilogue_main

#beq variant found, check hint bit (cr7 result)
beq_variant:
beq- cr7, beqPLUSfound

#beq- found
cmpwi r5, 0
beq+ beqMINUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_beq_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_beqa_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_beql_ll - table_start
beq- epilogue_main
addi r4, r10, ins_beqla_ll - table_start
b epilogue_main

beqMINUScr0found:
mr r5, r6
andi. r0, r31, aa | lk
addi r4, r10, ins_beq_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_beqa_ll_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_beql_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_beqla_ll_cr0 - table_start
b epilogue_main

#beq+ found
beqPLUSfound:
cmpwi r5, 0
beq+ beqPLUScr0found
andi. r0, r31, aa | lk
addi r4, r10, ins_beq_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_beqa_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_beql_ml - table_start
beq- epilogue_main
addi r4, r10, ins_beqla_ml - table_start
b epilogue_main

beqPLUScr0found:
mr r5, r6
andi. r0, r31, aa | lk
addi r4, r10, ins_beq_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_beqa_ml_cr0 - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_beql_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_beqla_ml_cr0 - table_start
b epilogue_main

#============================

#Check for bdnz+-
check_bdnz:
cmpwi r9, 0x8
bne+ check_for_bdz

#Found bdnz+- type
mr r5, r6 #BD needs to be in r5 for sprintf
beq- cr7, found_bdnzPLUS
andi. r0, r31, aa | lk
addi r4, r10, ins_bdnz_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdnza_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdnzl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzla_ll - table_start
b epilogue_main

found_bdnzPLUS:
andi. r0, r31, aa | lk
addi r4, r10, ins_bdnz_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdnza_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdnzl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzla_ml - table_start
b epilogue_main

#======================

#Check for bdz+-
check_for_bdz:
cmpwi r9, 0x9
bne+ check_for_bc_branch_always

#Found bdz+- type
mr r5, r6 #BD needs to be in r5 for sprintf
beq- cr7, found_bdzPLUS
andi. r0, r31, aa | lk
addi r4, r10, ins_bdz_ll - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdza_ll - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdzl_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdzla_ll - table_start
b epilogue_main

found_bdzPLUS:
andi. r0, r31, aa | lk
addi r4, r10, ins_bdz_ml - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bdza_ml - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bdzl_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdzla_ml - table_start
b epilogue_main

#======================

#Check for bc variant of branch always
check_for_bc_branch_always:
cmpwi r9, 0xA
bne+ do_invalid #Waltress setup where don't care values must be low

mr r5, r6 #BD needs to be in r5 for sprintf
andi. r0, r31, aa | lk
addi r4, r10, ins_bcalways - table_start
beq- epilogue_main
cmpwi r0, aa
addi r4, r10, ins_bcalwaysA - table_start
beq- epilogue_main
cmpwi r0, lk
addi r4, r10, ins_bcalwaysL - table_start
beq- epilogue_main
addi r4, r10, ins_bcalwaysAL - table_start
b epilogue_main

#
#Check for bcctrX
check_bcctrX:
first_check b21_30, bcctrX
bne+ check_bclrX
check_nullrB
bne- check_bclrX

#bcctrX found
BI r5
crfD_manual r6
findcrbtype r7
BO_nohint r9

#Check branch hint *FIRST*
BO_onlyhint r0
cmpwi cr7, r0, 1 #EQ of cr7 set high if branch hint + is present

#Check for bdnzfctr+- type
cmpwi r9, 0x0
bne+ check_bdzfctr

#Found bdnzfctr+- type
beq- cr7, found_bdnzfctrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdnzfctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzfctrl_ll - table_start
b epilogue_main

found_bdnzfctrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdnzfctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzfctrl_ml - table_start
b epilogue_main

#=====================

#Check for bdzfctr+- type
check_bdzfctr:
cmpwi r9, 0x1
bne+ check_bgectrblectrbnectrbnsctr

#Found bdzfctr+- type
beq- cr7, found_bdzfctrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdzfctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdzfctrl_ll - table_start
b epilogue_main

found_bdzfctrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdzfctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdzfctrl_ml - table_start
b epilogue_main


#======================

#Check for bgectr,blectr,bnectr,bnsctr
check_bgectrblectrbnectrbnsctr:
cmpwi r9, 0x2
bne+ check_bdnztctr

#Found bgectr,blectr,bnectr,bnsctr
mr r5, r6 #crF needs to be in r5 for sprintf
cmpwi r7, 0
beq- bgectr_variant
cmpwi r7, 1
beq- blectr_variant
cmpwi r7, 2
beq- bnectr_variant

#bnsctr variant found, check hint bit (cr7 result)
bnsctr_variant:
beq- cr7, bnsctrPLUSfound

#bnsctr- found
cmpwi r5, 0
beq+ bnsctrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnsctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bnsctrl_ll - table_start
b epilogue_main

bnsctrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnsctr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnsctrl_ll_cr0 - table_start
b epilogue_main

#bnsctr+ found
bnsctrPLUSfound:
cmpwi r5, 0
beq+ bnsctrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnsctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bnsctrl_ml - table_start
b epilogue_main

bnsctrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnsctr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnsctrl_ml_cr0 - table_start
b epilogue_main

#bgectr variant found, check hint bit (cr7 result)
bgectr_variant:
beq- cr7, bgectrPLUSfound

#bgectr- found
cmpwi r5, 0
beq+ bgectrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgectr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bgectrl_ll - table_start
b epilogue_main

bgectrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgectr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgectrl_ll_cr0 - table_start
b epilogue_main

#bgectr+ found
bgectrPLUSfound:
cmpwi r5, 0
beq+ bgectrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgectr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bgectrl_ml - table_start
b epilogue_main

bgectrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgectr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgectrl_ml_cr0 - table_start
b epilogue_main

#blectr variant found, check hint bit (cr7 result)
blectr_variant:
beq- cr7, blectrPLUSfound

#blectr- found
cmpwi r5, 0
beq+ blectrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_blectr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_blectrl_ll - table_start
b epilogue_main

blectrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_blectr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_blectrl_ll_cr0 - table_start
b epilogue_main

#blectr+ found
blectrPLUSfound:
cmpwi r5, 0
beq+ blectrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_blectr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_blectrl_ml - table_start
b epilogue_main

blectrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_blectr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_blectrl_ml_cr0 - table_start
b epilogue_main

#bnectr variant found, check hint bit (cr7 result)
bnectr_variant:
beq- cr7, bnectrPLUSfound

#bnectr- found
cmpwi r5, 0
beq+ bnectrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnectr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bnectrl_ll - table_start
b epilogue_main

bnectrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnectr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnectrl_ll_cr0 - table_start
b epilogue_main

#bnectr+ found
bnectrPLUSfound:
cmpwi r5, 0
beq+ bnectrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnectr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bnectrl_ml - table_start
b epilogue_main

bnectrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnectr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnectrl_ml_cr0 - table_start
b epilogue_main

#============================

#Check for bdnztctr+-
check_bdnztctr:
cmpwi r9, 0x4
bne+ check_bdztctr

#Found bdnztctr+- type
beq- cr7, found_bdnztctrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdnztctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnztctrl_ll - table_start
b epilogue_main

found_bdnztctrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdnztctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnztctrl_ml - table_start
b epilogue_main

#=====================

#Check fo bdztctr+-
check_bdztctr:
cmpwi r9, 0x5
bne+ check_bltctrbgtctrbeqctrbsoctr

#Found bdztctr+- type
beq- cr7, found_bdztctrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdztctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdztctrl_ll - table_start
b epilogue_main

found_bdztctrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdztctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdztctrl_ml - table_start
b epilogue_main

#=====================

#Check for the common shit that EXcludes bne, bns
check_bltctrbgtctrbeqctrbsoctr:
cmpwi r9, 0x6
bne+ check_bdnzctr

#Found bltctr,bgtctr,beqctr,bsoctr
mr r5, r6 #crF needs to be in r5 for sprintf
cmpwi r7, 0
beq- bltctr_variant
cmpwi r7, 1
beq- bgtctr_variant
cmpwi r7, 2
beq- beqctr_variant

#bsoctr variant found, check hint bit (cr7 result)
bsoctr_variant:
beq- cr7, bsoctrPLUSfound

#bsoctr- found
cmpwi r5, 0
beq+ bsoctrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bsoctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bsoctrl_ll - table_start
b epilogue_main

bsoctrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bsoctr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bsoctrl_ll_cr0 - table_start
b epilogue_main

#bsoctr+ found
bsoctrPLUSfound:
cmpwi r5, 0
beq+ bsoctrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bsoctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bsoctrl_ml - table_start
b epilogue_main

bsoctrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bsoctr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bsoctrl_ml_cr0 - table_start
b epilogue_main

#bltctr variant found, check hint bit (cr7 result)
bltctr_variant:
beq- cr7, bltctrPLUSfound

#bltctr- found
cmpwi r5, 0
beq+ bltctrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bltctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bltctrl_ll - table_start
b epilogue_main

bltctrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bltctr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bltctrl_ll_cr0 - table_start
b epilogue_main

#bltctr+ found
bltctrPLUSfound:
cmpwi r5, 0
beq+ bltctrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bltctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bltctrl_ml - table_start
b epilogue_main

bltctrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bltctr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bltctrl_ml_cr0 - table_start
b epilogue_main

#bgtctr variant found, check hint bit (cr7 result)
bgtctr_variant:
beq- cr7, bgtctrPLUSfound

#bgtctr- found
cmpwi r5, 0
beq+ bgtctrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgtctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bgtctrl_ll - table_start
b epilogue_main

bgtctrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgtctr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgtctrl_ll_cr0 - table_start
b epilogue_main

#bgtctr+ found
bgtctrPLUSfound:
cmpwi r5, 0
beq+ bgtctrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgtctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bgtctrl_ml - table_start
b epilogue_main

bgtctrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgtctr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgtctrl_ml_cr0 - table_start
b epilogue_main

#beqctr variant found, check hint bit (cr7 result)
beqctr_variant:
beq- cr7, beqctrPLUSfound

#beqctr- found
cmpwi r5, 0
beq+ beqctrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_beqctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_beqctrl_ll - table_start
b epilogue_main

beqctrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_beqctr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_beqctrl_ll_cr0 - table_start
b epilogue_main

#beqctr+ found
beqctrPLUSfound:
cmpwi r5, 0
beq+ beqctrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_beqctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_beqctrl_ml - table_start
b epilogue_main

beqctrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_beqctr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_beqctrl_ml_cr0 - table_start
b epilogue_main

#============================

#Check for bdnzctr+-
check_bdnzctr:
cmpwi r9, 0x8
bne+ check_for_bdzctr

#Found bdnzctr+- type
beq- cr7, found_bdnzctrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdnzctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzctrl_ll - table_start
b epilogue_main

found_bdnzctrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdnzctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzctrl_ml - table_start
b epilogue_main

#======================

#Check for bdzctr+-
check_for_bdzctr:
cmpwi r9, 0x9
bne+ check_for_bctr

#Found bdzctr+- type
beq- cr7, found_bdzctrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdzctr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdzctrl_ll - table_start
b epilogue_main

found_bdzctrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdzctr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdzctrl_ml - table_start
b epilogue_main

#======================

#Check for bcctr variant of branch always
check_for_bctr:
cmpwi r9, 0xA
bne+ do_invalid #I don't think it's possible to reach here, but just in case....

andi. r0, r31, lk
addi r4, r10, ins_bctr - table_start
beq- epilogue_main
addi r4, r10, ins_bctrl - table_start
b epilogue_main

#
#Check for bclrX
check_bclrX:
first_check b21_30, bclrX
bne+ check_cmpw
check_nullrB
bne- check_cmpw

#bclrX found
BI r5
crfD_manual r6
findcrbtype r7
BO_nohint r9

#Check branch hint *FIRST*
BO_onlyhint r0
cmpwi cr7, r0, 1 #EQ of cr7 set high if branch hint + is present

#Check for bdnzflr+- type
cmpwi r9, 0x0
bne+ check_bdzflr

#Found bdnzflr+- type
beq- cr7, found_bdnzflrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdnzflr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzflrl_ll - table_start
b epilogue_main

found_bdnzflrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdnzflr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzflrl_ml - table_start
b epilogue_main

#=====================

#Check for bdzflr+- type
check_bdzflr:
cmpwi r9, 0x1
bne+ check_bgelrblelrbnelrbnslr

#Found bdzflr+- type
beq- cr7, found_bdzflrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdzflr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdzflrl_ll - table_start
b epilogue_main

found_bdzflrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdzflr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdzflrl_ml - table_start
b epilogue_main


#======================

#Check for bgelr,blelr,bnelr,bnslr
check_bgelrblelrbnelrbnslr:
cmpwi r9, 0x2
bne+ check_bdnztlr

#Found bgelr,blelr,bnelr,bnslr
mr r5, r6 #crF needs to be in r5 for sprintf
cmpwi r7, 0
beq- bgelr_variant
cmpwi r7, 1
beq- blelr_variant
cmpwi r7, 2
beq- bnelr_variant

#bnslr variant found, check hint bit (cr7 result)
bnslr_variant:
beq- cr7, bnslrPLUSfound

#bnslr- found
cmpwi r5, 0
beq+ bnslrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnslr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bnslrl_ll - table_start
b epilogue_main

bnslrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnslr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnslrl_ll_cr0 - table_start
b epilogue_main

#bnslr+ found
bnslrPLUSfound:
cmpwi r5, 0
beq+ bnslrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnslr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bnslrl_ml - table_start
b epilogue_main

bnslrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnslr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnslrl_ml_cr0 - table_start
b epilogue_main

#bgelr variant found, check hint bit (cr7 result)
bgelr_variant:
beq- cr7, bgelrPLUSfound

#bgelr- found
cmpwi r5, 0
beq+ bgelrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgelr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bgelrl_ll - table_start
b epilogue_main

bgelrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgelr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgelrl_ll_cr0 - table_start
b epilogue_main

#bgelr+ found
bgelrPLUSfound:
cmpwi r5, 0
beq+ bgelrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgelr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bgelrl_ml - table_start
b epilogue_main

bgelrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgelr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgelrl_ml_cr0 - table_start
b epilogue_main

#blelr variant found, check hint bit (cr7 result)
blelr_variant:
beq- cr7, blelrPLUSfound

#blelr- found
cmpwi r5, 0
beq+ blelrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_blelr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_blelrl_ll - table_start
b epilogue_main

blelrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_blelr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_blelrl_ll_cr0 - table_start
b epilogue_main

#blelr+ found
blelrPLUSfound:
cmpwi r5, 0
beq+ blelrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_blelr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_blelrl_ml - table_start
b epilogue_main

blelrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_blelr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_blelrl_ml_cr0 - table_start
b epilogue_main

#bnelr variant found, check hint bit (cr7 result)
bnelr_variant:
beq- cr7, bnelrPLUSfound

#bnelr- found
cmpwi r5, 0
beq+ bnelrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnelr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bnelrl_ll - table_start
b epilogue_main

bnelrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnelr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnelrl_ll_cr0 - table_start
b epilogue_main

#bnelr+ found
bnelrPLUSfound:
cmpwi r5, 0
beq+ bnelrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bnelr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bnelrl_ml - table_start
b epilogue_main

bnelrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bnelr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bnelrl_ml_cr0 - table_start
b epilogue_main

#============================

#Check for bdnztlr+-
check_bdnztlr:
cmpwi r9, 0x4
bne+ check_bdztlr

#Found bdnztlr+- type
beq- cr7, found_bdnztlrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdnztlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnztlrl_ll - table_start
b epilogue_main

found_bdnztlrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdnztlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnztlrl_ml - table_start
b epilogue_main

#=====================

#Check fo bdztlr+-
check_bdztlr:
cmpwi r9, 0x5
bne+ check_bltlrbgtlrbeqlrbsolr

#Found bdztlr+- type
beq- cr7, found_bdztlrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdztlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdztlrl_ll - table_start
b epilogue_main

found_bdztlrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdztlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdztlrl_ml - table_start
b epilogue_main

#=====================

#Check for the common shit that EXcludes bne, bns
check_bltlrbgtlrbeqlrbsolr:
cmpwi r9, 0x6
bne+ check_bdnzlr

#Found bltlr,bgtlr,beqlr,bsolr
mr r5, r6 #crF needs to be in r5 for sprintf
cmpwi r7, 0
beq- bltlr_variant
cmpwi r7, 1
beq- bgtlr_variant
cmpwi r7, 2
beq- beqlr_variant

#bsolr variant found, check hint bit (cr7 result)
bsolr_variant:
beq- cr7, bsolrPLUSfound

#bsolr- found
cmpwi r5, 0
beq+ bsolrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bsolr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bsolrl_ll - table_start
b epilogue_main

bsolrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bsolr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bsolrl_ll_cr0 - table_start
b epilogue_main

#bsolr+ found
bsolrPLUSfound:
cmpwi r5, 0
beq+ bsolrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bsolr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bsolrl_ml - table_start
b epilogue_main

bsolrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bsolr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bsolrl_ml_cr0 - table_start
b epilogue_main

#bltlr variant found, check hint bit (cr7 result)
bltlr_variant:
beq- cr7, bltlrPLUSfound

#bltlr- found
cmpwi r5, 0
beq+ bltlrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bltlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bltlrl_ll - table_start
b epilogue_main

bltlrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bltlr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bltlrl_ll_cr0 - table_start
b epilogue_main

#bltlr+ found
bltlrPLUSfound:
cmpwi r5, 0
beq+ bltlrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bltlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bltlrl_ml - table_start
b epilogue_main

bltlrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bltlr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bltlrl_ml_cr0 - table_start
b epilogue_main

#bgtlr variant found, check hint bit (cr7 result)
bgtlr_variant:
beq- cr7, bgtlrPLUSfound

#bgtlr- found
cmpwi r5, 0
beq+ bgtlrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgtlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bgtlrl_ll - table_start
b epilogue_main

bgtlrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgtlr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgtlrl_ll_cr0 - table_start
b epilogue_main

#bgtlr+ found
bgtlrPLUSfound:
cmpwi r5, 0
beq+ bgtlrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_bgtlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bgtlrl_ml - table_start
b epilogue_main

bgtlrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_bgtlr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_bgtlrl_ml_cr0 - table_start
b epilogue_main

#beqlr variant found, check hint bit (cr7 result)
beqlr_variant:
beq- cr7, beqlrPLUSfound

#beqlr- found
cmpwi r5, 0
beq+ beqlrMINUScr0found
andi. r0, r31, lk
addi r4, r10, ins_beqlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_beqlrl_ll - table_start
b epilogue_main

beqlrMINUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_beqlr_ll_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_beqlrl_ll_cr0 - table_start
b epilogue_main

#beqlr+ found
beqlrPLUSfound:
cmpwi r5, 0
beq+ beqlrPLUScr0found
andi. r0, r31, lk
addi r4, r10, ins_beqlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_beqlrl_ml - table_start
b epilogue_main

beqlrPLUScr0found:
andi. r0, r31, lk
addi r4, r10, ins_beqlr_ml_cr0 - table_start
beq- epilogue_main
addi r4, r10, ins_beqlrl_ml_cr0 - table_start
b epilogue_main

#============================

#Check for bdnzlr+-
check_bdnzlr:
cmpwi r9, 0x8
bne+ check_for_bdzlr

#Found bdnzlr+- type
beq- cr7, found_bdnzlrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdnzlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzlrl_ll - table_start
b epilogue_main

found_bdnzlrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdnzlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdnzlrl_ml - table_start
b epilogue_main

#======================

#Check for bdzlr+-
check_for_bdzlr:
cmpwi r9, 0x9
bne+ check_for_blr

#Found bdzlr+- type
beq- cr7, found_bdzlrPLUS
andi. r0, r31, lk
addi r4, r10, ins_bdzlr_ll - table_start
beq- epilogue_main
addi r4, r10, ins_bdzlrl_ll - table_start
b epilogue_main

found_bdzlrPLUS:
andi. r0, r31, lk
addi r4, r10, ins_bdzlr_ml - table_start
beq- epilogue_main
addi r4, r10, ins_bdzlrl_ml - table_start
b epilogue_main

#======================

#Check for bclr variant of branch always
check_for_blr:
cmpwi r9, 0xA
bne+ do_invalid #I don't think it's possible to reach here, but just in case....

andi. r0, r31, lk
addi r4, r10, ins_blr - table_start
beq- epilogue_main
addi r4, r10, ins_blrl - table_start
b epilogue_main

#Check for cmpw
check_cmpw:
cmplwi r30, cmpw@h
bne+ check_cmpwi
second_check check_cmps1
bne- check_cmpwi

#cmpw found
crfD r5
rA r6
rB r7
cmpwi r5, 0
addi r4, r10, ins_cmpw - table_start
bne- epilogue_main
#crF is 0
mr r5, r6
mr r6, r7
addi r4, r10, ins_cmpw_cr0 - table_start
b epilogue_main

#Check for cmpwi
check_cmpwi:
cmplwi r30, cmpwi@h
bne+ check_cmplw
check_cmpwicmplwi
bne- check_cmplw

#cmpwi found
crfD r5
rA r6
SIMM r7
cmpwi r5, 0
addi r4, r10, ins_cmpwi - table_start
bne- epilogue_main
#crF is 0
mr r5, r6
mr r6, r7
addi r4, r10, ins_cmpwi_cr0 - table_start
b epilogue_main

#Check for cmplw
check_cmplw:
first_check b21_30, cmplw
bne+ check_cmplwi
second_check check_cmps2
bne- check_cmplwi

#cmplw found
crfD r5
rA r6
rB r7
cmpwi r5, 0
addi r4, r10, ins_cmplw - table_start
bne- epilogue_main
#crF is 0
mr r5, r6
mr r6, r7
addi r4, r10, ins_cmplw_cr0 - table_start
b epilogue_main

#Check for cmplwi
check_cmplwi:
cmplwi r30, cmplwi@h
bne+ check_cntlzwX
check_cmpwicmplwi
bne- check_cntlzwX

#cmplwi found
crfD r5
rA r6
UIMM r7
cmpwi r5, 0
addi r4, r10, ins_cmplwi - table_start
bne- epilogue_main
#crF is 0
mr r5, r6
mr r6, r7
addi r4, r10, ins_cmplwi_cr0 - table_start
b epilogue_main

#Check for cntlzwX
check_cntlzwX:
first_check b21_30, cntlzwX
bne+ check_crand
check_nullrB
bne- check_crand

#cntlzwX found
rA r5
rS r6
andi. r0, r31, rc
addi r4, r10, ins_cntlzw - table_start
beq- epilogue_main
addi r4, r10, ins_cntlzw_ - table_start
b epilogue_main

#Check for crand
check_crand:
first_check b21_30, crand
bne+ check_crandc
check_b31
bne- check_crandc

#crand found
crbD r5
crbA r6
crbB r7
addi r4, r10, ins_crand - table_start
b epilogue_main

#Check for crandc
check_crandc:
first_check b21_30, crandc
bne+ check_creqv
check_b31
bne- check_creqv

#crandc found
crbD r5
crbA r6
crbB r7
addi r4, r10, ins_crandc - table_start
b epilogue_main

#Check for creqv
check_creqv:
first_check b21_30, creqv
bne+ check_crnand
check_b31
bne- check_crnand

#creqv found (HOWEVER check for crset first; all crb's must be equal)
crbD r5
crbA r6
crbB r7
cmpw r5, r6
bne- not_crset
cmpw r5, r7
bne- not_crset
addi r4, r10, ins_crset - table_start
b epilogue_main
not_crset:
addi r4, r10, ins_creqv - table_start
b epilogue_main

#Check for crnand
check_crnand:
first_check b21_30, crnand
bne+ check_crnor
check_b31
bne- check_crnor

#crnand found
crbD r5
crbA r6
crbB r7
addi r4, r10, ins_crnand - table_start
b epilogue_main

#Check for crnor
check_crnor:
first_check b21_30, crnor
bne+ check_cror
check_b31
bne- check_cror

#crnor found (HOWEVER check for crnot first, crbA and crbB must be equal)
crbD r5
crbA r6
crbB r7
cmpw r6, r7
bne+ not_crnot
addi r4, r10, ins_crnot - table_start
b epilogue_main
not_crnot:
addi r4, r10, ins_crnor - table_start
b epilogue_main

#Check for cror
check_cror:
first_check b21_30, cror
bne+ check_crorc
check_b31
bne- check_crorc

#cror found (HOWEVER check for crmove first, crbA and crbB must be equal)
crbD r5
crbA r6
crbB r7
cmpw r6, r7
bne+ not_crmove
addi r4, r10, ins_crmove - table_start
b epilogue_main
not_crmove:
addi r4, r10, ins_cror - table_start
b epilogue_main

#Check for crorc
check_crorc:
first_check b21_30, crorc
bne+ check_crxor
check_b31
bne- check_crxor

#crorc found
crbD r5
crbA r6
crbB r7
addi r4, r10, ins_crorc - table_start
b epilogue_main

#Check for crxor
check_crxor:
first_check b21_30, crxor
bne+ check_dcbf
check_b31
bne- check_dcbf

#crxor found (HOWEVER check for crclr first, all crb's must be equal)
crbD r5
crbA r6
crbB r7
cmpw r5, r6
bne- not_crclr
cmpw cr7, r5, r7
bne- not_crclr
addi r4, r10, ins_crclr - table_start
b epilogue_main
not_crclr:
addi r4, r10, ins_crxor - table_start
b epilogue_main

#Check for dcbf
check_dcbf:
first_check b21_30, dcbf
bne+ check_dcbi
second_check check_cache
bne- check_dcbi

#dcbf found
rA r5
rB r6
addi r4, r10, ins_dcbf - table_start
b epilogue_main

#Check for dcbi
check_dcbi:
first_check b21_30, dcbi
bne+ check_dcbst
second_check check_cache
bne- check_dcbst

#dcbi found
rA r5
rB r6
addi r4, r10, ins_dcbi - table_start
b epilogue_main

#Check for dcbst
check_dcbst:
first_check b21_30, dcbst
bne+ check_dcbt
second_check check_cache
bne- check_dcbt

#dcbst found
rA r5
rB r6
addi r4, r10, ins_dcbst - table_start
b epilogue_main

#Check for dcbt
check_dcbt:
first_check b21_30, dcbt
bne+ check_dcbtst
second_check check_cache
bne- check_dcbtst

#dcbt found
rA r5
rB r6
addi r4, r10, ins_dcbt - table_start
b epilogue_main

#Check for dcbtst
check_dcbtst:
first_check b21_30, dcbtst
bne+ check_dcbz
second_check check_cache
bne- check_dcbz

#dcbtst found
rA r5
rB r6
addi r4, r10, ins_dcbtst - table_start
b epilogue_main

#Check for dcbz
check_dcbz:
first_check b21_30, dcbz
bne+ check_dcbz_l
second_check check_cache
bne- check_dcbz_l

#dcbz found
rA r5
rB r6
addi r4, r10, ins_dcbz - table_start
b epilogue_main

#Check for dcbz_l
check_dcbz_l:
first_check b21_30, dcbz_l
bne+ check_divwX
second_check check_cache
bne- check_divwX

#dcbz_l found
rA r5
rB r6
addi r4, r10, ins_dcbz_l - table_start
b epilogue_main

#Check for divwX
check_divwX:
first_check b22_30, divwX
bne+ check_divwuX

#divwX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
first_check b22_30, divwuX
bne+ check_eciwx

#divwuX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
first_check b21_30, eciwx
bne+ check_ecowx
check_b31
bne- check_ecowx

#eciwx found
rD r5
rA r6
rB r7
addi r4, r10, ins_eciwx - table_start
b epilogue_main

#Check for ecowx
check_ecowx:
first_check b21_30, ecowx
bne+ check_eieio
check_b31
bne- check_eieio

#ecowx found
rS r5
rA r6
rB r7
addi r4, r10, ins_ecowx - table_start
b epilogue_main

#Check for eieio
check_eieio:
first_check b21_30, eieio
bne+ check_eqvX
second_check check_syncs
bne- check_eqvX

#eieio found
addi r4, r10, ins_eieio - table_start
b epilogue_main

#Check for eqvX
check_eqvX:
first_check b21_30, eqvX
bne+ check_extsbX

#eqvX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_eqv - table_start
beq- epilogue_main
addi r4, r10, ins_eqv_ - table_start
b epilogue_main

#Check for extsbX
check_extsbX:
first_check b21_30, extsbX
bne+ check_extshX
check_nullrB
bne- check_extshX

#extsbX found
rA r5
rS r6
andi. r0, r31, rc
addi r4, r10, ins_extsb - table_start
beq- epilogue_main
addi r4, r10, ins_extsb_ - table_start
b epilogue_main

#Check for extshX
check_extshX:
first_check b21_30, extshX
bne+ check_fabsX
check_nullrB
bne- check_fabsX

#extshX found
rA r5
rS r6
andi. r0, r31, rc
addi r4, r10, ins_extsh - table_start
beq- epilogue_main
addi r4, r10, ins_extsh_ - table_start
b epilogue_main

#Check for fabsX
check_fabsX:
first_check b21_30, fabsX
bne+ check_faddX
check_nullrA
bne- check_faddX

#fabsX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fabs - table_start
beq- epilogue_main
addi r4, r10, ins_fabs_ - table_start
b epilogue_main

#Check for faddX
check_faddX:
first_check b26_30, faddX
bne+ check_faddsX
check_nullfC
bne- check_faddsX

#faddX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_fadd - table_start
beq- epilogue_main
addi r4, r10, ins_fadd_ - table_start
b epilogue_main

#Check for faddsX
check_faddsX:
first_check b26_30, faddsX
bne+ check_fcmpo
check_nullfC
bne- check_fcmpo

#faddsX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_fadds - table_start
beq- epilogue_main
addi r4, r10, ins_fadds_ - table_start
b epilogue_main

#Check for fcmpo
check_fcmpo:
first_check b21_30, fcmpo
bne+ check_fcmpu
second_check check_cmps2
bne- check_fcmpu

#fcmpo found
crfD r5
fA r6
fB r7
addi r4, r10, ins_fcmpo - table_start
b epilogue_main

#Check for fcmpu
check_fcmpu:
cmplwi r30, fcmpu@h
bne+ check_fctiwX
second_check check_cmps1
bne- check_fctiwX

#fcmpu found
crfD r5
fA r6
fB r7
addi r4, r10, ins_fcmpu - table_start
b epilogue_main

#Check for fctiwX
check_fctiwX:
first_check b21_30, fctiwX
bne+ check_fctiwzX
check_nullrA
bne- check_fctiwzX

#fctiwX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fctiw - table_start
beq- epilogue_main
addi r4, r10, ins_fctiw_ - table_start
b epilogue_main

#Check for fctiwzX
check_fctiwzX:
first_check b21_30, fctiwzX
bne+ check_fdivX
check_nullrA
bne- check_fdivX

#fctiwzX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fctiwz - table_start
beq- epilogue_main
addi r4, r10, ins_fctiwz_ - table_start
b epilogue_main

#Check for fdivX
check_fdivX:
first_check b26_30, fdivX
bne+ check_fdivsX
check_nullfC
bne- check_fdivsX

#fdivX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_fdiv - table_start
beq- epilogue_main
addi r4, r10, ins_fdiv_ - table_start
b epilogue_main

#Check for fdivsX
check_fdivsX:
first_check b26_30, fdivsX
bne+ check_fmaddX
check_nullfC
bne- check_fmaddX

#fdivsX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_fdivs - table_start
beq- epilogue_main
addi r4, r10, ins_fdivs_ - table_start
b epilogue_main

#Check for fmaddX
check_fmaddX:
first_check b26_30, fmaddX
bne+ check_fmaddsX

#fmaddX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fmadd - table_start
beq- epilogue_main
addi r4, r10, ins_fmadd_ - table_start
b epilogue_main

#Check for fmaddsX
check_fmaddsX:
first_check b26_30, fmaddsX
bne+ check_fmr

#fmaddsX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fmadds - table_start
beq- epilogue_main
addi r4, r10, ins_fmadds_ - table_start
b epilogue_main

#Check for fmrX
check_fmr:
first_check b21_30, fmrX
bne+ check_fmsub
check_nullrA
bne- check_fmsub

#fmrX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fmr - table_start
beq- epilogue_main
addi r4, r10, ins_fmr_ - table_start
b epilogue_main

#Check for fmsubX
check_fmsub:
first_check b26_30, fmsubX
bne+ check_fmsubsX

#fmsubX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fmsub - table_start
beq- epilogue_main
addi r4, r10, ins_fmsub_ - table_start
b epilogue_main

#Check for fmsubsX
check_fmsubsX:
first_check b26_30, fmsubsX
bne+ check_fmulX

#fmsubsX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fmsubs - table_start
beq- epilogue_main
addi r4, r10, ins_fmsubs_ - table_start
b epilogue_main

#Check for fmulX
check_fmulX:
first_check b26_30, fmulX
bne+ check_fmulsX
check_nullrB
bne- check_fmulsX

#fmulX found
fD r5
fA r6
fC r7
andi. r0, r31, rc
addi r4, r10, ins_fmul - table_start
beq- epilogue_main
addi r4, r10, ins_fmul_ - table_start
b epilogue_main

#Check for fmulsX
check_fmulsX:
first_check b26_30, fmulsX
bne+ check_fnabsX
check_nullrB
bne- check_fnabsX

#fmulsX found
fD r5
fA r6
fC r7
andi. r0, r31, rc
addi r4, r10, ins_fmuls - table_start
beq- epilogue_main
addi r4, r10, ins_fmuls_ - table_start
b epilogue_main

#Check for fnabsX
check_fnabsX:
first_check b21_30, fnabsX
bne+ check_fnegX
check_nullrA
bne- check_fnegX

#fnabsX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fnabs - table_start
beq- epilogue_main
addi r4, r10, ins_fnabs_ - table_start
b epilogue_main

#Check for fnegX
check_fnegX:
first_check b21_30, fnegX
bne+ check_fnmaddX
check_nullrA
bne- check_fnmaddX

#fnegX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fneg - table_start
beq- epilogue_main
addi r4, r10, ins_fneg_ - table_start
b epilogue_main

#Check for fnmaddX
check_fnmaddX:
first_check b26_30, fnmaddX
bne+ check_fnmaddsX

#fnmaddX found
fD r5
fA r6
fC r7
rB r8
andi. r0, r31, rc
addi r4, r10, ins_fnmadd - table_start
beq- epilogue_main
addi r4, r10, ins_fnmadd_ - table_start
b epilogue_main

#Check for fnmaddsX
check_fnmaddsX:
first_check b26_30, fnmaddsX
bne+ check_fnmsubX

#fnmaddsX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fnmadds - table_start
beq- epilogue_main
addi r4, r10, ins_fnmadds_ - table_start
b epilogue_main

#Check for fnmsubX
check_fnmsubX:
first_check b26_30, fnmsubX
bne+ check_fnmsubsX

#fnmsubX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fnmsub - table_start
beq- epilogue_main
addi r4, r10, ins_fnmsub_ - table_start
b epilogue_main

#Check for fnmsubsX
check_fnmsubsX:
first_check b26_30, fnmsubsX
bne+ check_fresX

#fnmsubsX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fnmsubs - table_start
beq- epilogue_main
addi r4, r10, ins_fnmsubs_ - table_start
b epilogue_main

#Check for fresX
check_fresX:
first_check b26_30, fresX
bne+ check_frspX
second_check check_res_sqrt
bne- check_frspX

#fresX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_fres - table_start
beq- epilogue_main
addi r4, r10, ins_fres_ - table_start
b epilogue_main

#Check for frspX
check_frspX:
first_check b21_30, frspX
bne+ check_frsqrteX
check_nullrA
bne- check_frsqrteX

#frspX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_frsp - table_start
beq- epilogue_main
addi r4, r10, ins_frsp_ - table_start
b epilogue_main

#Check for frsqrteX
check_frsqrteX:
first_check b26_30, frsqrteX
bne+ check_fselX
second_check check_res_sqrt
bne- check_fselX

#frsqrteX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_frsqrte - table_start
beq- epilogue_main
addi r4, r10, ins_frsqrte_ - table_start
b epilogue_main

#Check for fselX
check_fselX:
first_check b26_30, fselX
bne+ check_fsubX

#fselX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_fsel - table_start
beq- epilogue_main
addi r4, r10, ins_fsel_ - table_start
b epilogue_main

#Check for fsubX
check_fsubX:
first_check b26_30, fsubX
bne+ check_fsubsX
check_nullfC
bne- check_fsubsX

#fsubX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_fsub - table_start
beq- epilogue_main
addi r4, r10, ins_fsub_ - table_start
b epilogue_main

#Check for fsubsX
check_fsubsX:
first_check b26_30, fsubsX
bne+ check_icbi
check_nullfC
bne- check_icbi

#fsubsX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_fsubs - table_start
beq- epilogue_main
addi r4, r10, ins_fsubs_ - table_start
b epilogue_main

#Check for icbi
check_icbi:
first_check b21_30, icbi
bne+ check_isync
second_check check_cache
bne- check_isync

#icbi found
rA r5
rB r6
addi r4, r10, ins_icbi - table_start
b epilogue_main

#Check for isync
check_isync:
first_check b21_30, isync
bne+ check_lbz
second_check check_syncs
bne- check_lbz

#isync found
addi r4, r10, ins_isync - table_start
b epilogue_main

#Check for lbz
check_lbz:
cmplwi r30, lbz@h
bne+ check_lbzu

#lbz found
rD r5
d r6
rA r7
addi r4, r10, ins_lbz - table_start
b epilogue_main

#Check for lbzu
check_lbzu:
cmplwi r30, lbzu@h
bne+ check_lbzux

#lbzu found
rD r5
d r6
rA r7
load_int_update_doublecheck
addi r4, r10, ins_lbzu - table_start
b epilogue_main

#Check for lbzux
check_lbzux:
first_check b21_30, lbzux
bne+ check_lbzx
check_b31
bne- check_lbzx

#lbzux found
rD r5
rA r6
rB r7
load_int_update_index_doublecheck
addi r4, r10, ins_lbzux - table_start
b epilogue_main

#Check for lbzx
check_lbzx:
first_check b21_30, lbzx
bne+ check_lfd
check_b31
bne- check_lfd

#lbzx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lbzx - table_start
b epilogue_main

#Check for lfd
check_lfd:
cmplwi r30, lfd@h
bne+ check_lfdu

#lfd found
fD r5
d r6
rA r7
addi r4, r10, ins_lfd - table_start
b epilogue_main

#Check for lfdu
check_lfdu:
cmplwi r30, lfdu@h
bne+ check_lfdux

#lfdu found
fD r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_lfdu - table_start
b epilogue_main

#Check for lfdux
check_lfdux:
first_check b21_30, lfdux
bne+ check_lfdx
check_b31
bne- check_lfdx

#lfdux found
fD r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_lfdux - table_start
b epilogue_main

#Check for lfdx
check_lfdx:
first_check b21_30, lfdx
bne+ check_lfs
check_b31
bne- check_lfs

#lfdx found
fD r5
rA r6
rB r7
addi r4, r10, ins_lfdx - table_start
b epilogue_main

#Check for lfs
check_lfs:
cmplwi r30, lfs@h
bne+ check_lfsu

#lfs found
fD r5
d r6
rA r7
addi r4, r10, ins_lfs - table_start
b epilogue_main

#Check for lfsu
check_lfsu:
cmplwi r30, lfsu@h
bne+ check_lfsux

#lfsu found
fD r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_lfsu - table_start
b epilogue_main

#Check for lfsux
check_lfsux:
first_check b21_30, lfsux
bne+ check_lfsx
check_b31
bne- check_lfsx

#lfsux found
fD r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_lfsux - table_start
b epilogue_main

#Check for lfsx
check_lfsx:
first_check b21_30, lfsx
bne+ check_lha
check_b31
bne- check_lha

#lfsx found
fD r5
rA r6
rB r7
addi r4, r10, ins_lfsx - table_start
b epilogue_main

#Check for lha
check_lha:
cmplwi r30, lha@h
bne+ check_lhau

#lha found
rD r5
d r6
rA r7
addi r4, r10, ins_lha - table_start
b epilogue_main

#Check for lhau
check_lhau:
cmplwi r30, lhau@h
bne+ check_lhaux

#lhau found
rD r5
d r6
rA r7
load_int_update_doublecheck
addi r4, r10, ins_lhau - table_start
b epilogue_main

#Check for lhaux
check_lhaux:
first_check b21_30, lhaux
bne+ check_lhax
check_b31
bne- check_lhax

#lhaux found
rD r5
rA r6
rB r7
load_int_update_index_doublecheck
addi r4, r10, ins_lhaux - table_start
b epilogue_main

#Check for lhax
check_lhax:
first_check b21_30, lhax
bne+ check_lhbrx
check_b31
bne- check_lhbrx

#lhax found
rD r5
rA r6
rB r7
addi r4, r10, ins_lhax - table_start
b epilogue_main

#Check for lhbrx
check_lhbrx:
first_check b21_30, lhbrx
bne+ check_lhz
check_b31
bne- check_lhz

#lhbrx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lhbrx - table_start
b epilogue_main

#Check for lhz
check_lhz:
cmplwi r30, lhz@h
bne+ check_lhzu

#lhz found
rD r5
d r6
rA r7
addi r4, r10, ins_lhz - table_start
b epilogue_main

#Check for lhzu
check_lhzu:
cmplwi r30, lhzu@h
bne+ check_lhzux

#lhzu found
rD r5
d r6
rA r7
load_int_update_doublecheck
addi r4, r10, ins_lhzu - table_start
b epilogue_main

#Check for lhzux
check_lhzux:
first_check b21_30, lhzux
bne+ check_lhzx
check_b31
bne- check_lhzx

#lhzux found
rD r5
rA r6
rB r7
load_int_update_index_doublecheck
addi r4, r10, ins_lhzux - table_start
b epilogue_main

#Check for lhzx
check_lhzx:
first_check b21_30, lhzx
bne+ check_lmw
check_b31
bne- check_lmw

#lhzx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lhzx - table_start
b epilogue_main

#Check for lmw
check_lmw:
cmplwi r30, lmw@h
bne+ check_lswi

#lmw found
rD r5
d r6
rA r7
#rA cannot = or be > rD
cmplw r7, r5
bge- do_invalid
addi r4, r10, ins_lmw - table_start
b epilogue_main

#Check for lswi
check_lswi:
first_check b21_30, lswi
bne+ check_lswx
check_b31
bne- check_lswx

#lswi found
rD r5
rA r6
NB r7
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
first_check b21_30, lswx
bne+ check_lwarx
check_b31
bne- check_lwarx

#lswx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lswx - table_start
b epilogue_main

#Check for lwarx
check_lwarx:
first_check b21_30, lwarx
bne+ check_lwbrx
check_b31
bne- check_lwbrx

#lwarx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lwarx - table_start
b epilogue_main

#Check for lwbrx
check_lwbrx:
first_check b21_30, lwbrx
bne+ check_lwz
check_b31
bne- check_lwz

#lwbrx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lwbrx - table_start
b epilogue_main

#Check for lwz
check_lwz:
cmplwi r30, lwz@h
bne+ check_lwzu

#lwz found
rD r5
d r6
rA r7
addi r4, r10, ins_lwz - table_start
b epilogue_main

#Check for lwzu
check_lwzu:
cmplwi r30, lwzu@h
bne+ check_lwzux

#lwzu found
rD r5
d r6
rA r7
load_int_update_doublecheck
addi r4, r10, ins_lwzu - table_start
b epilogue_main

#Check for lwzux
check_lwzux:
first_check b21_30, lwzux
bne+ check_lwzx
check_b31
bne- check_lwzx

#lwzux found
rD r5
rA r6
rB r7
load_int_update_index_doublecheck
addi r4, r10, ins_lwzux - table_start
b epilogue_main

#Check for lwzx
check_lwzx:
first_check b21_30, lwzx
bne+ check_mcrfnow
check_b31
bne- check_mcrfnow

#lwzx found
rD r5
rA r6
rB r7
addi r4, r10, ins_lwzx - table_start
b epilogue_main

#Check for mcrf
check_mcrfnow:
cmplwi r30, mcrf@h
bne+ check_mcrfsnow
second_check check_mcrf
bne- check_mcrfsnow

#mcrf found
crfD r5
crfS r6
addi r4, r10, ins_mcrf - table_start
b epilogue_main

#Check for mcrfs
check_mcrfsnow:
first_check b21_30, mcrfs
bne+ check_mcrxrnow
second_check check_mcrfs
bne- check_mcrxrnow

#mcrfs found
crfD r5
crfS r6
addi r4, r10, ins_mcrfs - table_start
b epilogue_main

#Check for mcrxr
check_mcrxrnow:
first_check b21_30, mcrxr
bne+ check_mfcr
second_check check_mcrxr
bne- check_mfcr

#mcrxr found
crfD r5
addi r4, r10, ins_mcrxr - table_start
b epilogue_main

#Check for mfcr
check_mfcr:
first_check b21_30, mfcr
bne+ check_mffsX
second_check check_cr_msr
bne- check_mffsX

#mfcr found
rD r5
addi r4, r10, ins_mfcr - table_start
b epilogue_main

#Check for mffsX
check_mffsX:
first_check b21_30, mffsX
bne+ check_mfmsr
second_check check_fs_fsb
bne- check_mfmsr

#mffsX found
fD r5
andi. r0, r31, rc
addi r4, r10, ins_mffs - table_start
beq- epilogue_main
addi r4, r10, ins_mffs_ - table_start
b epilogue_main

#Check for mfmsr
check_mfmsr:
first_check b21_30, mfmsr
bne+ check_mfspr
second_check check_cr_msr
bne- check_mfspr

#mfmsr found
rD r5
addi r4, r10, ins_mfmsr - table_start
b epilogue_main

#Check for mfspr
check_mfspr:
first_check b21_30, mfspr
bne+ check_mfsr
check_b31
bne- check_mfsr

#mfspr found (also add in temp r4 pointers to simplified mnemonics)
rD r5
SPR r6
#r5 (rD) is in perfect place for sprintf (r%d) regardless of whether or not a simplified mnemonic is used
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
addi r4, r10, ins_mfdsisr - table_start
beq- epilogue_main
cmpwi r6, 19
addi r4, r10, ins_mfdar - table_start
beq- epilogue_main
cmpwi r6, 22
addi r4, r10, ins_mfdec - table_start
beq- epilogue_main
cmpwi r6, 25
addi r4, r10, ins_mfsdr1 - table_start
beq- epilogue_main
cmpwi r6, 26
addi r4, r10, ins_mfsrr0 - table_start
beq- epilogue_main
cmpwi r6, 27
addi r4, r10, ins_mfsrr1 - table_start
beq- epilogue_main
cmpwi r6, 272
addi r4, r10, ins_mfsprg0 - table_start
beq- epilogue_main
cmpwi r6, 273
addi r4, r10, ins_mfsprg1 - table_start
beq- epilogue_main
cmpwi r6, 274
addi r4, r10, ins_mfsprg2 - table_start
beq- epilogue_main
cmpwi r6, 275
addi r4, r10, ins_mfsprg3 - table_start
beq- epilogue_main
cmpwi r6, 282
addi r4, r10, ins_mfear - table_start
beq- epilogue_main
cmpwi r6, 287
addi r4, r10, ins_mfpvr - table_start
beq- epilogue_main
cmpwi r6, 528
addi r4, r10, ins_mfibat0u - table_start
beq- epilogue_main
cmpwi r6, 529
addi r4, r10, ins_mfibat0l - table_start
beq- epilogue_main
cmpwi r6, 530
addi r4, r10, ins_mfibat1u - table_start
beq- epilogue_main
cmpwi r6, 531
addi r4, r10, ins_mfibat1l - table_start
beq- epilogue_main
cmpwi r6, 532
addi r4, r10, ins_mfibat2u - table_start
beq- epilogue_main
cmpwi r6, 533
addi r4, r10, ins_mfibat2l - table_start
beq- epilogue_main
cmpwi r6, 534
addi r4, r10, ins_mfibat3u - table_start
beq- epilogue_main
cmpwi r6, 535
addi r4, r10, ins_mfibat3l - table_start
beq- epilogue_main
cmpwi r6, 560
addi r4, r10, ins_mfibat4u - table_start
beq- epilogue_main
cmpwi r6, 561
addi r4, r10, ins_mfibat4l - table_start
beq- epilogue_main
cmpwi r6, 562
addi r4, r10, ins_mfibat5u - table_start
beq- epilogue_main
cmpwi r6, 563
addi r4, r10, ins_mfibat5l - table_start
beq- epilogue_main
cmpwi r6, 564
addi r4, r10, ins_mfibat6u - table_start
beq- epilogue_main
cmpwi r6, 565
addi r4, r10, ins_mfibat6l - table_start
beq- epilogue_main
cmpwi r6, 566
addi r4, r10, ins_mfibat7u - table_start
beq- epilogue_main
cmpwi r6, 567
addi r4, r10, ins_mfibat7l - table_start
beq- epilogue_main
cmpwi r6, 536
addi r4, r10, ins_mfdbat0u - table_start
beq- epilogue_main
cmpwi r6, 537
addi r4, r10, ins_mfdbat0l - table_start
beq- epilogue_main
cmpwi r6, 538
addi r4, r10, ins_mfdbat1u - table_start
beq- epilogue_main
cmpwi r6, 539
addi r4, r10, ins_mfdbat1l - table_start
beq- epilogue_main
cmpwi r6, 540
addi r4, r10, ins_mfdbat2u - table_start
beq- epilogue_main
cmpwi r6, 541
addi r4, r10, ins_mfdbat2l - table_start
beq- epilogue_main
cmpwi r6, 542
addi r4, r10, ins_mfdbat3u - table_start
beq- epilogue_main
cmpwi r6, 543
addi r4, r10, ins_mfdbat3l - table_start
beq- epilogue_main
cmpwi r6, 568
addi r4, r10, ins_mfdbat4u - table_start
beq- epilogue_main
cmpwi r6, 569
addi r4, r10, ins_mfdbat4l - table_start
beq- epilogue_main
cmpwi r6, 570
addi r4, r10, ins_mfdbat5u - table_start
beq- epilogue_main
cmpwi r6, 571
addi r4, r10, ins_mfdbat5l - table_start
beq- epilogue_main
cmpwi r6, 572
addi r4, r10, ins_mfdbat6u - table_start
beq- epilogue_main
cmpwi r6, 573
addi r4, r10, ins_mfdbat6l - table_start
beq- epilogue_main
cmpwi r6, 574
addi r4, r10, ins_mfdbat7u - table_start
beq- epilogue_main
cmpwi r6, 575
addi r4, r10, ins_mfdbat7l - table_start
beq- epilogue_main
cmpwi r6, 912
addi r4, r10, ins_mfgqr0 - table_start
beq- epilogue_main
cmpwi r6, 913
addi r4, r10, ins_mfgqr1 - table_start
beq- epilogue_main
cmpwi r6, 914
addi r4, r10, ins_mfgqr2 - table_start
beq- epilogue_main
cmpwi r6, 915
addi r4, r10, ins_mfgqr3 - table_start
beq- epilogue_main
cmpwi r6, 916
addi r4, r10, ins_mfgqr4 - table_start
beq- epilogue_main
cmpwi r6, 917
addi r4, r10, ins_mfgqr5 - table_start
beq- epilogue_main
cmpwi r6, 918
addi r4, r10, ins_mfgqr6 - table_start
beq- epilogue_main
cmpwi r6, 919
addi r4, r10, ins_mfgqr7 - table_start
beq- epilogue_main
cmpwi r6, 920
addi r4, r10, ins_mfhid2 - table_start
beq- epilogue_main
cmpwi r6, 921
addi r4, r10, ins_mfwpar - table_start
beq- epilogue_main
cmpwi r6, 922
addi r4, r10, ins_mfdma_u - table_start
beq- epilogue_main
cmpwi r6, 923
addi r4, r10, ins_mfdma_l - table_start
beq- epilogue_main
#Support for CHIP ID SPR's added in!
cmpwi r6, 925
addi r4, r10, ins_mfcidh - table_start
beq- epilogue_main
cmpwi r6, 926
addi r4, r10, ins_mfcidm - table_start
beq- epilogue_main
cmpwi r6, 927
addi r4, r10, ins_mfcidl - table_start
beq- epilogue_main
#
cmpwi r6, 936
addi r4, r10, ins_mfummcr0 - table_start
beq- epilogue_main
cmpwi r6, 937
addi r4, r10, ins_mfupmc1 - table_start
beq- epilogue_main
cmpwi r6, 938
addi r4, r10, ins_mfupmc2 - table_start
beq- epilogue_main
cmpwi r6, 939
addi r4, r10, ins_mfusia - table_start
beq- epilogue_main
cmpwi r6, 940
addi r4, r10, ins_mfummcr1 - table_start
beq- epilogue_main
cmpwi r6, 941
addi r4, r10, ins_mfupmc3 - table_start
beq- epilogue_main
cmpwi r6, 942
addi r4, r10, ins_mfupmc4 - table_start
beq- epilogue_main
cmpwi r6, 943
addi r4, r10, ins_mfusda - table_start
beq- epilogue_main
cmpwi r6, 952
addi r4, r10, ins_mfmmcr0 - table_start
beq- epilogue_main
cmpwi r6, 953
addi r4, r10, ins_mfpmc1 - table_start
beq- epilogue_main
cmpwi r6, 954
addi r4, r10, ins_mfpmc2 - table_start
beq- epilogue_main
cmpwi r6, 955
addi r4, r10, ins_mfsia - table_start
beq- epilogue_main
cmpwi r6, 956
addi r4, r10, ins_mfmmcr1 - table_start
beq- epilogue_main
cmpwi r6, 957
addi r4, r10, ins_mfpmc3 - table_start
beq- epilogue_main
cmpwi r6, 958
addi r4, r10, ins_mfpmc4 - table_start
beq- epilogue_main
cmpwi r6, 959
addi r4, r10, ins_mfsda - table_start
beq- epilogue_main
cmpwi r6, 1008
addi r4, r10, ins_mfhid0 - table_start
beq- epilogue_main
cmpwi r6, 1009
addi r4, r10, ins_mfhid1 - table_start
beq- epilogue_main
cmpwi r6, 1010
addi r4, r10, ins_mfiabr - table_start
beq- epilogue_main
cmpwi r6, 1011
addi r4, r10, ins_mfhid4 - table_start
beq- epilogue_main
cmpwi r6, 1012
addi r4, r10, ins_mftdcl - table_start
beq- epilogue_main
cmpwi r6, 1013
addi r4, r10, ins_mfdabr - table_start
beq- epilogue_main
cmpwi r6, 1017
addi r4, r10, ins_mfl2cr - table_start
beq- epilogue_main
cmpwi r6, 1018
addi r4, r10, ins_mftdch - table_start
beq- epilogue_main
cmpwi r6, 1019
addi r4, r10, ins_mfictc - table_start
beq- epilogue_main
cmpwi r6, 1020
addi r4, r10, ins_mfthrm1 - table_start
beq- epilogue_main
cmpwi r6, 1021
addi r4, r10, ins_mfthrm2 - table_start
beq- epilogue_main
cmpwi r6, 1022
addi r4, r10, ins_mfthrm3 - table_start
beq- epilogue_main
b do_invalid #Invalid instruction found, do .long

#Check for mfsr
check_mfsr:
first_check b21_30, mfsr
bne+ check_mfsrin
second_check check_sr
bne- check_mfsrin

#mfsr found
rD r5
SR r6
addi r4, r10, ins_mfsr - table_start
b epilogue_main

#Check for mfsrin
check_mfsrin:
first_check b21_30, mfsrin
bne+ check_mftb
second_check check_srin
bne- check_mftb

#mfsrin found
rD r5
rB r6
addi r4, r10, ins_mfsrin - table_start
b epilogue_main

#Check for mftb
check_mftb:
first_check b21_30, mftb
bne+ check_mtcrfnow
check_b31
bne- check_mtcrfnow

#mftb found (ALSO find out if it's either mftbl or mftbu)
rD r5
TBR r6
cmpwi r6, 269
beq- 0x14 #Go to mftbu
cmpwi r6, 268
bne- do_invalid #Invalid instruction found, do .long
addi r4, r10, ins_mftbl - table_start
beq- epilogue_main #Take branch to call sprintf if it's mftbl (r6 = 268)
addi r4, r10, ins_mftbu - table_start
b epilogue_main

#Check for mtcrf (HOWEVER, also check if mtcr simplified mnemonic is the instruction)
check_mtcrfnow:
first_check b21_30, mtcrf
bne+ check_mtfsb0X
second_check check_mtcrf
bne- check_mtfsb0X

#mtcrf found
CRM r5
rS r6
cmpwi r5, 0xFF
#Temp backup CRM
mr r7, r5
#Temp place rS (r6) into r5, for possibility of mtcr
mr r5, r6
addi r4, r10, ins_mtcr - table_start
beq- epilogue_main
#Recover CRM since it's not mtcr
mr r5, r7
addi r4, r10, ins_mtcrf - table_start
b epilogue_main

#Check for mtfsb0X
check_mtfsb0X:
first_check b21_30, mtfsb0X
bne+ check_mtfsb1X
second_check check_fs_fsb
bne- check_mtfsb1X

#mtfsb0X found
crbD r5
andi. r0, r31, rc
addi r4, r10, ins_mtfsb0 - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsb0_ - table_start
b epilogue_main

#Check for mtfsb1X
check_mtfsb1X:
first_check b21_30, mtfsb1X
bne+ check_mtfsfXnow
second_check check_fs_fsb
bne- check_mtfsfXnow

#mtfsb1X found
crbD r5
andi. r0, r31, rc
addi r4, r10, ins_mtfsb1 - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsb1_ - table_start
b epilogue_main

#Check for mtfsfX
check_mtfsfXnow:
first_check b21_30, mtfsfX
bne+ check_mtfsfiXnow
check_mtfsfX
bne- check_mtfsfiXnow

#mtfsfX found
FM r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_mtfsf - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsf_ - table_start
b epilogue_main

#Check for mtfsfiX
check_mtfsfiXnow:
first_check b21_30, mtfsfiX
bne+ check_mtmsr
second_check check_mtfsfiX
bne- check_mtmsr

#mtfsfiX found
crfD r5
IMM r6
andi. r0, r31, rc
addi r4, r10, ins_mtfsfi - table_start
beq- epilogue_main
addi r4, r10, ins_mtfsfi_ - table_start
b epilogue_main

#Check for mtmsr
check_mtmsr:
first_check b21_30, mtmsr
bne+ check_mtspr
second_check check_cr_msr
bne- check_mtspr

#mtmsr found
rS r5
addi r4, r10, ins_mtmsr - table_start
b epilogue_main

#Check for mtspr
check_mtspr:
first_check b21_30, mtspr
bne+ check_mtsr
check_b31
bne- check_mtsr

#mtspr found (also add in r4 pointers for simplified mnemonics)
SPR r6 #Suppose to go into r5 for sprintf but since mtspr is NOT needed in the disassembler, we want rS in r5 instead
rS r5 #Read direct note above, since we only use simplified mnemonics, r5 is in perfect sprintf spot

#Start simplified mnemonic spr number checks
cmpwi r6, 1
addi r4, r10, ins_mtxer - table_start
beq- epilogue_main
cmpwi r6, 8
addi r4, r10, ins_mtlr - table_start
beq- epilogue_main
cmpwi r6, 9
addi r4, r10, ins_mtctr - table_start
beq- epilogue_main
cmpwi r6, 18
addi r4, r10, ins_mtdsisr - table_start
beq- epilogue_main
cmpwi r6, 19
addi r4, r10, ins_mtdar - table_start
beq- epilogue_main
cmpwi r6, 22
addi r4, r10, ins_mtdec - table_start
beq- epilogue_main
cmpwi r6, 25
addi r4, r10, ins_mtsdr1 - table_start
beq- epilogue_main
cmpwi r6, 26
addi r4, r10, ins_mtsrr0 - table_start
beq- epilogue_main
cmpwi r6, 27
addi r4, r10, ins_mtsrr1 - table_start
beq- epilogue_main
cmpwi r6, 272
addi r4, r10, ins_mtsprg0 - table_start
beq- epilogue_main
cmpwi r6, 273
addi r4, r10, ins_mtsprg1 - table_start
beq- epilogue_main
cmpwi r6, 274
addi r4, r10, ins_mtsprg2 - table_start
beq- epilogue_main
cmpwi r6, 275
addi r4, r10, ins_mtsprg3 - table_start
beq- epilogue_main
cmpwi r6, 282
addi r4, r10, ins_mtear - table_start
beq- epilogue_main
cmpwi r6, 284
addi r4, r10, ins_mttbl - table_start
beq- epilogue_main
cmpwi r6, 285
addi r4, r10, ins_mttbu - table_start
beq- epilogue_main
cmpwi r6, 528
addi r4, r10, ins_mtibat0u - table_start
beq- epilogue_main
cmpwi r6, 529
addi r4, r10, ins_mtibat0l - table_start
beq- epilogue_main
cmpwi r6, 530
addi r4, r10, ins_mtibat1u - table_start
beq- epilogue_main
cmpwi r6, 531
addi r4, r10, ins_mtibat1l - table_start
beq- epilogue_main
cmpwi r6, 532
addi r4, r10, ins_mtibat2u - table_start
beq- epilogue_main
cmpwi r6, 533
addi r4, r10, ins_mtibat2l - table_start
beq- epilogue_main
cmpwi r6, 534
addi r4, r10, ins_mtibat3u - table_start
beq- epilogue_main
cmpwi r6, 535
addi r4, r10, ins_mtibat3l - table_start
beq- epilogue_main
cmpwi r6, 560
addi r4, r10, ins_mtibat4u - table_start
beq- epilogue_main
cmpwi r6, 561
addi r4, r10, ins_mtibat4l - table_start
beq- epilogue_main
cmpwi r6, 562
addi r4, r10, ins_mtibat5u - table_start
beq- epilogue_main
cmpwi r6, 563
addi r4, r10, ins_mtibat5l - table_start
beq- epilogue_main
cmpwi r6, 564
addi r4, r10, ins_mtibat6u - table_start
beq- epilogue_main
cmpwi r6, 565
addi r4, r10, ins_mtibat6l - table_start
beq- epilogue_main
cmpwi r6, 566
addi r4, r10, ins_mtibat7u - table_start
beq- epilogue_main
cmpwi r6, 567
addi r4, r10, ins_mtibat7l - table_start
beq- epilogue_main
cmpwi r6, 536
addi r4, r10, ins_mtdbat0u - table_start
beq- epilogue_main
cmpwi r6, 537
addi r4, r10, ins_mtdbat0l - table_start
beq- epilogue_main
cmpwi r6, 538
addi r4, r10, ins_mtdbat1u - table_start
beq- epilogue_main
cmpwi r6, 539
addi r4, r10, ins_mtdbat1l - table_start
beq- epilogue_main
cmpwi r6, 540
addi r4, r10, ins_mtdbat2u - table_start
beq- epilogue_main
cmpwi r6, 541
addi r4, r10, ins_mtdbat2l - table_start
beq- epilogue_main
cmpwi r6, 542
addi r4, r10, ins_mtdbat3u - table_start
beq- epilogue_main
cmpwi r6, 543
addi r4, r10, ins_mtdbat3l - table_start
beq- epilogue_main
cmpwi r6, 568
addi r4, r10, ins_mtdbat4u - table_start
beq- epilogue_main
cmpwi r6, 569
addi r4, r10, ins_mtdbat4l - table_start
beq- epilogue_main
cmpwi r6, 570
addi r4, r10, ins_mtdbat5u - table_start
beq- epilogue_main
cmpwi r6, 571
addi r4, r10, ins_mtdbat5l - table_start
beq- epilogue_main
cmpwi r6, 572
addi r4, r10, ins_mtdbat6u - table_start
beq- epilogue_main
cmpwi r6, 573
addi r4, r10, ins_mtdbat6l - table_start
beq- epilogue_main
cmpwi r6, 574
addi r4, r10, ins_mtdbat7u - table_start
beq- epilogue_main
cmpwi r6, 575
addi r4, r10, ins_mtdbat7l - table_start
beq- epilogue_main
cmpwi r6, 912
addi r4, r10, ins_mtgqr0 - table_start
beq- epilogue_main
cmpwi r6, 913
addi r4, r10, ins_mtgqr1 - table_start
beq- epilogue_main
cmpwi r6, 914
addi r4, r10, ins_mtgqr2 - table_start
beq- epilogue_main
cmpwi r6, 915
addi r4, r10, ins_mtgqr3 - table_start
beq- epilogue_main
cmpwi r6, 916
addi r4, r10, ins_mtgqr4 - table_start
beq- epilogue_main
cmpwi r6, 917
addi r4, r10, ins_mtgqr5 - table_start
beq- epilogue_main
cmpwi r6, 918
addi r4, r10, ins_mtgqr6 - table_start
beq- epilogue_main
cmpwi r6, 919
addi r4, r10, ins_mtgqr7 - table_start
beq- epilogue_main
cmpwi r6, 920
addi r4, r10, ins_mthid2 - table_start
beq- epilogue_main
cmpwi r6, 921
addi r4, r10, ins_mtwpar - table_start
beq- epilogue_main
cmpwi r6, 922
addi r4, r10, ins_mtdma_u - table_start
beq- epilogue_main
cmpwi r6, 923
addi r4, r10, ins_mtdma_l - table_start
beq- epilogue_main
cmpwi r6, 936
addi r4, r10, ins_mtummcr0 - table_start
beq- epilogue_main
cmpwi r6, 937
addi r4, r10, ins_mtupmc1 - table_start
beq- epilogue_main
cmpwi r6, 938
addi r4, r10, ins_mtupmc2 - table_start
beq- epilogue_main
cmpwi r6, 939
addi r4, r10, ins_mtusia - table_start
beq- epilogue_main
cmpwi r6, 940
addi r4, r10, ins_mtummcr1 - table_start
beq- epilogue_main
cmpwi r6, 941
addi r4, r10, ins_mtupmc3 - table_start
beq- epilogue_main
cmpwi r6, 942
addi r4, r10, ins_mtupmc4 - table_start
beq- epilogue_main
cmpwi r6, 943
addi r4, r10, ins_mtusda - table_start
beq- epilogue_main
cmpwi r6, 952
addi r4, r10, ins_mtmmcr0 - table_start
beq- epilogue_main
cmpwi r6, 953
addi r4, r10, ins_mtpmc1 - table_start
beq- epilogue_main
cmpwi r6, 954
addi r4, r10, ins_mtpmc2 - table_start
beq- epilogue_main
cmpwi r6, 955
addi r4, r10, ins_mtsia - table_start
beq- epilogue_main
cmpwi r6, 956
addi r4, r10, ins_mtmmcr1 - table_start
beq- epilogue_main
cmpwi r6, 957
addi r4, r10, ins_mtpmc3 - table_start
beq- epilogue_main
cmpwi r6, 958
addi r4, r10, ins_mtpmc4 - table_start
beq- epilogue_main
cmpwi r6, 959
addi r4, r10, ins_mtsda - table_start
beq- epilogue_main
cmpwi r6, 1008
addi r4, r10, ins_mthid0 - table_start
beq- epilogue_main
cmpwi r6, 1009
addi r4, r10, ins_mthid1 - table_start
beq- epilogue_main
cmpwi r6, 1010
addi r4, r10, ins_mtiabr - table_start
beq- epilogue_main
cmpwi r6, 1011
addi r4, r10, ins_mthid4 - table_start
beq- epilogue_main
cmpwi r6, 1013
addi r4, r10, ins_mtdabr - table_start
beq- epilogue_main
cmpwi r6, 1017
addi r4, r10, ins_mtl2cr - table_start
beq- epilogue_main
cmpwi r6, 1019
addi r4, r10, ins_mtictc - table_start
beq- epilogue_main
cmpwi r6, 1020
addi r4, r10, ins_mtthrm1 - table_start
beq- epilogue_main
cmpwi r6, 1021
addi r4, r10, ins_mtthrm2 - table_start
beq- epilogue_main
cmpwi r6, 1022
addi r4, r10, ins_mtthrm3 - table_start
beq- epilogue_main
b do_invalid #Invalid instruction found, do .long

#Check for mtsr
check_mtsr:
first_check b21_30, mtsr
bne+ check_mtsrin
second_check check_sr
bne- check_mtsrin

#mtsr found
SR r5
rS r6
addi r4, r10, ins_mtsr - table_start
b epilogue_main

#Check for mtsrin
check_mtsrin:
first_check b21_30, mtsrin
bne+ check_mulhwX
second_check check_srin
bne- check_mulhwX

#mtsrin found
rS r5
rB r6
addi r4, r10, ins_mtsrin - table_start
b epilogue_main

#Check for mulhwX
check_mulhwX:
first_check b22_30, mulhwX
bne+ check_mulhwuX
check_b21
bne- check_mulhwuX

#mulhwX found
rD r5
rA r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_mulhw - table_start
beq- epilogue_main
addi r4, r10, ins_mulhw_ - table_start
b epilogue_main

#Check for mulhwuX
check_mulhwuX:
first_check b22_30, mulhwuX
bne+ check_mulli
check_b21
bne- check_mulli

#mulhwuX found
rD r5
rA r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_mulhwu - table_start
beq- epilogue_main
addi r4, r10, ins_mulhwu_ - table_start
b epilogue_main

#Check for mulli
check_mulli:
cmplwi r30, mulli@h
bne+ check_mullwX

#mulli found
rD r5
rA r6
SIMM r7
addi r4, r10, ins_mulli - table_start
b epilogue_main

#Check for mullwX
check_mullwX:
first_check b22_30, mullwX
bne+ check_nandX

#mullwX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
first_check b21_30, nandX
bne+ check_negX

#nandX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_nand - table_start
beq- epilogue_main
addi r4, r10, ins_nand_ - table_start
b epilogue_main

#Check for negX
check_negX:
first_check b22_30, negX
bne+ check_norX
check_nullrB
bne- check_norX

#negX found
rD r5
rA r6
andi. r0, r31, oe | rc
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
first_check b21_30, norX
bne+ check_orX

#norX found (HOWEVER check for simplified notX as well)
rA r5
rS r6
rB r7
andi. r0, r31, rc
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
first_check b21_30, orX
bne+ check_orcX

#orX found (HOWEVER check for simplified mrX as well)
rA r5
rS r6
rB r7
andi. r0, r31, rc
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
first_check b21_30, orcX
bne+ check_ori

#orcX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_orc - table_start
beq- epilogue_main
addi r4, r10, ins_orc_ - table_start
b epilogue_main

#Check for ori (HOWEVER, check for nop first)
check_ori:
lis r11, 0x6000
cmpw r11, r31 #compare against instruction, not the mask!
bne- not_nop
addi r4, r10, ins_nop - table_start
b epilogue_main
not_nop:
cmplwi r30, ori@h
bne+ check_oris

#ori found
rA r5
rS r6
UIMM r7
addi r4, r10, ins_ori - table_start
b epilogue_main

#Check for oris
check_oris:
cmplwi r30, oris@h
bne+ check_psq_l

#oris found
rA r5
rS r6
UIMM r7
addi r4, r10, ins_oris - table_start
b epilogue_main

#Check for psq_l
check_psq_l:
cmplwi r30, psq_l@h
bne+ check_psq_lu

#psq_l found
fD r5
ps_SIMM r6
rA r7
W_nonx r8
I_nonx r9
addi r4, r10, ins_psq_l - table_start
b epilogue_main

#Check for psq_lu
check_psq_lu:
cmplwi r30, psq_lu@h
bne+ check_psq_lux

#psq_lu found
fD r5
ps_SIMM r6
rA r7
W_nonx r8
I_nonx r9
cmpwi r7, 0 #rA cannot be r0
beq- do_invalid
addi r4, r10, ins_psq_lu - table_start
b epilogue_main

#Check for psq_lux
check_psq_lux:
first_check b25_30, psq_lux
bne+ check_psq_lx
check_b31
bne- check_psq_lx

#psq_lux found
fD r5
rA r6
rB r7
W_x r8
I_x r9
cmpwi r6, 0 #rA cannot be r0
beq- do_invalid
addi r4, r10, ins_psq_lux - table_start
b epilogue_main

#Check for psq_lx
check_psq_lx:
first_check b25_30, psq_lx
bne+ check_psq_st
check_b31
bne- check_psq_st

#psq_lx found
fD r5
rA r6
rB r7
W_x r8
I_x r9
addi r4, r10, ins_psq_lx - table_start
b epilogue_main

#Check for psq_st
check_psq_st:
cmplwi r30, psq_st@h
bne+ check_psq_stu

#psq_st found
fD r5
ps_SIMM r6
rA r7
W_nonx r8
I_nonx r9
addi r4, r10, ins_psq_st - table_start
b epilogue_main

#Check for psq_stu
check_psq_stu:
cmplwi r30, psq_stu@h
bne+ check_psq_stux

#psq_stu found
fD r5
ps_SIMM r6
rA r7
W_nonx r8
I_nonx r9
cmpwi r7, 0 #rA cannot be r0
beq- do_invalid
addi r4, r10, ins_psq_stu - table_start
b epilogue_main

#Check for psq_stux
check_psq_stux:
first_check b25_30, psq_stux
bne+ check_psq_stx
check_b31
bne- check_psq_stx

#psq_stux found
fD r5
rA r6
rB r7
W_x r8
I_x r9
cmpwi r6, 0 #rA cannot be r0
beq- do_invalid
addi r4, r10, ins_psq_stux - table_start
b epilogue_main

#Check for psq_stx
check_psq_stx:
first_check b25_30, psq_stx
bne+ check_ps_absX
check_b31
bne- check_ps_absX

#psq_stx found
fD r5
rA r6
rB r7
W_x r8
I_x r9
addi r4, r10, ins_psq_stx - table_start
b epilogue_main

#Check for ps_absX
check_ps_absX:
first_check b21_30, ps_absX
bne+ check_ps_addX
check_nullrA
bne- check_ps_addX

#ps_absX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_ps_abs - table_start
beq- epilogue_main
addi r4, r10, ins_ps_abs_ - table_start
b epilogue_main

#Check for ps_addX
check_ps_addX:
first_check b26_30, ps_addX
bne+ check_ps_cmpo0
check_nullfC
bne- check_ps_cmpo0

#ps_addX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_add - table_start
beq- epilogue_main
addi r4, r10, ins_ps_add_ - table_start
b epilogue_main

#Check for ps_cmpo0
check_ps_cmpo0:
first_check b21_30, ps_cmpo0
bne+ check_ps_cmpo1
second_check check_cmps2
bne- check_ps_cmpo1

#ps_cmpo0 found
crfD r5
fA r6
fB r7
addi r4, r10, ins_ps_cmpo0 - table_start
b epilogue_main

#Check for ps_cmpo1
check_ps_cmpo1:
first_check b21_30, ps_cmpo1
bne+ check_ps_cmpu0
second_check check_cmps2
bne- check_ps_cmpu0

#ps_cmpo1 found
crfD r5
fA r6
fB r7
addi r4, r10, ins_ps_cmpo1 - table_start
b epilogue_main

#Check for ps_cmpu0
check_ps_cmpu0:
cmplwi r30, ps_cmpu0@h
bne+ check_ps_cmpu1
second_check check_cmps1
bne- check_ps_cmpu1

#ps_cmpu0 found
crfD r5
fA r6
fB r7
addi r4, r10, ins_ps_cmpu0 - table_start
b epilogue_main

#Check for ps_cmpu1
check_ps_cmpu1:
first_check b21_30, ps_cmpu1
bne+ check_ps_divX
second_check check_cmps2
bne- check_ps_divX

#ps_cmpu1 found
crfD r5
fA r6
fB r7
addi r4, r10, ins_ps_cmpu1 - table_start
b epilogue_main

#Check for ps_divX
check_ps_divX:
first_check b26_30, ps_divX
bne+ check_ps_maddX
check_nullfC
bne- check_ps_maddX

#ps_divX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_div - table_start
beq- epilogue_main
addi r4, r10, ins_ps_div_ - table_start
b epilogue_main

#Check for ps_maddX
check_ps_maddX:
first_check b26_30, ps_maddX
bne+ check_ps_madds0X

#ps_maddX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_madd - table_start
beq- epilogue_main
addi r4, r10, ins_ps_madd_ - table_start
b epilogue_main

#Check for ps_madds0X
check_ps_madds0X:
first_check b26_30, ps_madds0X
bne+ check_ps_madds1X

#ps_madds0X found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_madds0 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_madds0_ - table_start
b epilogue_main

#Check for ps_madds1X
check_ps_madds1X:
first_check b26_30, ps_madds1X
bne+ check_ps_merge00X

#ps_madds1X found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_madds1 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_madds1_ - table_start
b epilogue_main

#Check for ps_merge00X
check_ps_merge00X:
first_check b21_30, ps_merge00X
bne+ check_ps_merge01X

#ps_merge00X found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_merge00 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge00_ - table_start
b epilogue_main

#Check for ps_merge01X
check_ps_merge01X:
first_check b21_30, ps_merge01X
bne+ check_ps_merge10X

#ps_merge01X found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_merge01 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge01_ - table_start
b epilogue_main

#Check for ps_merge10X
check_ps_merge10X:
first_check b21_30, ps_merge10X
bne+ check_ps_merge11X

#ps_merge10X found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_merge10 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge10_ - table_start
b epilogue_main

#Check for ps_merge11X
check_ps_merge11X:
first_check b21_30, ps_merge11X
bne+ check_ps_mrX

#ps_merge11X found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_merge11 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_merge11_ - table_start
b epilogue_main

#Check for ps_mrX
check_ps_mrX:
first_check b21_30, ps_mrX
bne+ check_ps_msubX
check_nullrA
bne- check_ps_msubX

#ps_mrX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_ps_mr - table_start
beq- epilogue_main
addi r4, r10, ins_ps_mr_ - table_start
b epilogue_main

#Check for ps_msubX
check_ps_msubX:
first_check b26_30, ps_msubX
bne+ check_ps_mulX

#ps_msubX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_msub - table_start
beq- epilogue_main
addi r4, r10, ins_ps_msub_ - table_start
b epilogue_main

#Check for ps_mulX
check_ps_mulX:
first_check b26_30, ps_mulX
bne+ check_ps_muls0X
check_nullrB
bne- check_ps_muls0X

#ps_mulX found
fD r5
fA r6
fC r7
andi. r0, r31, rc
addi r4, r10, ins_ps_mul - table_start
beq- epilogue_main
addi r4, r10, ins_ps_mul_ - table_start
b epilogue_main

#Check for ps_muls0X
check_ps_muls0X:
first_check b26_30, ps_muls0X
bne+ check_ps_muls1X
check_nullrB
bne- check_ps_muls1X

#ps_muls0X found
fD r5
fA r6
fC r7
andi. r0, r31, rc
addi r4, r10, ins_ps_muls0 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_muls0_ - table_start
b epilogue_main

#Check for ps_muls1X
check_ps_muls1X:
first_check b26_30, ps_muls1X
bne+ check_ps_nabsX
check_nullrB
bne- check_ps_nabsX

#ps_muls1X found
fD r5
fA r6
fC r7
andi. r0, r31, rc
addi r4, r10, ins_ps_muls1 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_muls1_ - table_start
b epilogue_main

#Check for ps_nabsX
check_ps_nabsX:
first_check b21_30, ps_nabsX
bne+ check_ps_negX
check_nullrA
bne- check_ps_negX

#ps_nabsX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_ps_nabs - table_start
beq- epilogue_main
addi r4, r10, ins_ps_nabs_ - table_start
b epilogue_main

#Check for ps_negX
check_ps_negX:
first_check b21_30, ps_negX
bne+ check_ps_nmaddX
check_nullrA
bne- check_ps_nmaddX

#ps_negX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_ps_neg - table_start
beq- epilogue_main
addi r4, r10, ins_ps_neg_ - table_start
b epilogue_main

#Check for ps_nmaddX
check_ps_nmaddX:
first_check b26_30, ps_nmaddX
bne+ check_ps_nmsubX

#ps_nmaddX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_nmadd - table_start
beq- epilogue_main
addi r4, r10, ins_ps_nmadd_ - table_start
b epilogue_main

#Check for ps_nmsubX
check_ps_nmsubX:
first_check b26_30, ps_nmsubX
bne+ check_ps_resX

#ps_nmsubX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_nmsub - table_start
beq- epilogue_main
addi r4, r10, ins_ps_nmsub_ - table_start
b epilogue_main

#Check for ps_resX
check_ps_resX:
first_check b26_30, ps_resX
bne+ check_ps_rsqrteX
second_check check_res_sqrt
bne- check_ps_rsqrteX

#ps_resX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_ps_res - table_start
beq- epilogue_main
addi r4, r10, ins_ps_res_ - table_start
b epilogue_main

#Check for ps_rsqrteX
check_ps_rsqrteX:
first_check b26_30, ps_rsqrteX
bne+ check_ps_selX
second_check check_res_sqrt
bne- check_ps_selX

#ps_rsqrteX found
fD r5
fB r6
andi. r0, r31, rc
addi r4, r10, ins_ps_rsqrte - table_start
beq- epilogue_main
addi r4, r10, ins_ps_rsqrte_ - table_start
b epilogue_main

#Check for ps_selX
check_ps_selX:
first_check b26_30, ps_selX
bne+ check_ps_subX

#ps_selX found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_sel - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sel_ - table_start
b epilogue_main

#Check for ps_subX
check_ps_subX:
first_check b26_30, ps_subX
bne+ check_ps_sum0X
check_nullfC
bne- check_ps_sum0X

#ps_subX found
fD r5
fA r6
fB r7
andi. r0, r31, rc
addi r4, r10, ins_ps_sub - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sub_ - table_start
b epilogue_main

#Check for ps_sum0X
check_ps_sum0X:
first_check b26_30, ps_sum0X
bne+ check_ps_sum1X

#ps_sum0X found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_sum0 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sum0_ - table_start
b epilogue_main

#Check for ps_sum1X
check_ps_sum1X:
first_check b26_30, ps_sum1X
bne+ check_rfi

#ps_sum1X found
fD r5
fA r6
fC r7
fB r8
andi. r0, r31, rc
addi r4, r10, ins_ps_sum1 - table_start
beq- epilogue_main
addi r4, r10, ins_ps_sum1_ - table_start
b epilogue_main

#Check for rfi
check_rfi:
first_check b21_30, rfi
bne+ check_rlwimiX
second_check check_syncs
bne- check_rlwimiX

#rfi found
addi r4, r10, ins_rfi - table_start
b epilogue_main

#Check for rlwimiX
check_rlwimiX:
cmplwi r30, rlwimiX@h
bne+ check_rlwinmX

#rlwimiX found
rA r5
rS r6
SH r7
MB r8
ME r9
andi. r0, r31, rc
addi r4, r10, ins_rlwimi - table_start
beq- epilogue_main
addi r4, r10, ins_rlwimi_ - table_start
b epilogue_main

#Check for rlwinmX
check_rlwinmX:
cmplwi r30, rlwinmX@h
bne+ check_rlwnmX

#rlwinmX found (HOWEVER check for slwiX, srwiX, clrlwiX, clrrwiX, and rotlwiX)
rA r5
rS r6
SH r7
MB r8
ME r9
andi. r0, r31, rc #KEEP cr0 intact throughout entire process!!!! until one of the simplified mnemonics have been found
#Check for slwiX
cmpwi cr6, r8, 0 #MB must = 0
add r0, r7, r9 
cmpwi cr7, r0, 31 #SH + ME must = 31
crand 4*cr5+eq, 4*cr6+eq, 4*cr7+eq
bne+ cr5, check_srwiX
#slwiX found. n of the slwiX = SH value of the compiled rlwinm instruction
#SH (r7) is already in n spot (r7), no moving of register values is needed
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
#srwiX found. n of the srwiX = MB value of the compiled rlwinm instruction
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
#clrlwiX found. n of the clrlwiX = MB value of the compiled rlwinm instruction
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
#clrrwiX found. n of the clrrwiX = (31-ME)
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
cmplwi r30, rlwnmX@h
bne+ check_scnow

#rlwnmX found (HOWEVER check for rotlwX first)
rA r5
rS r6
rB r7
MB r8
ME r9
andi. r0, r31, rc #Keep cr0 intact!
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
check_scnow:
lis r0, 0x4400
ori r0, r0, 0x0002
cmpw r0, r31
bne+ check_slwX

#sc found
addi r4, r10, ins_sc - table_start
b epilogue_main

#Check for slwX
check_slwX:
first_check b21_30, slwX
bne+ check_srawX

#slwX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_slw - table_start
beq- epilogue_main
addi r4, r10, ins_slw_ - table_start
b epilogue_main

#Check for srawX
check_srawX:
first_check b21_30, srawX
bne+ check_srawiX

#srawX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_sraw - table_start
beq- epilogue_main
addi r4, r10, ins_sraw_ - table_start
b epilogue_main

#Check for srawiX
check_srawiX:
first_check b21_30, srawiX
bne+ check_srwX

#srawiX found
rA r5
rS r6
SH r7
andi. r0, r31, rc
addi r4, r10, ins_srawi - table_start
beq- epilogue_main
addi r4, r10, ins_srawi_ - table_start
b epilogue_main

#Check for srwX
check_srwX:
first_check b21_30, srwX
bne+ check_stb

#srwX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_srw - table_start
beq- epilogue_main
addi r4, r10, ins_srw_ - table_start
b epilogue_main

#Check for stb
check_stb:
cmplwi r30, stb@h
bne+ check_stbu

#stb found
rS r5
d r6
rA r7
addi r4, r10, ins_stb - table_start
b epilogue_main

#Check for stbu
check_stbu:
cmplwi r30, stbu@h
bne+ check_stbux

#stbu found
rS r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stbu - table_start
b epilogue_main

#Check for stbux
check_stbux:
first_check b21_30, stbux
bne+ check_stbx
check_b31
bne- check_stbx

#stbux found
rS r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stbux - table_start
b epilogue_main

#Check for stbx
check_stbx:
first_check b21_30, stbx
bne+ check_stfd
check_b31
bne- check_stfd

#stbx found
rS r5
rA r6
rB r7
addi r4, r10, ins_stbx - table_start
b epilogue_main

#Check for stfd
check_stfd:
cmplwi r30, stfd@h
bne+ check_stfdu

#stfd found
fS r5
d r6
rA r7
addi r4, r10, ins_stfd - table_start
b epilogue_main

#Check for stfdu
check_stfdu:
cmplwi r30, stfdu@h
bne+ check_stfdux

#stfdu found
fS r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stfdu - table_start
b epilogue_main

#Check for stfdux
check_stfdux:
first_check b21_30, stfdux
bne+ check_stfdx
check_b31
bne- check_stfdx

#stfdux found
fS r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stfdux - table_start
b epilogue_main

#Check for stfdx
check_stfdx:
first_check b21_30, stfdx
bne+ check_stfiwx
check_b31
bne- check_stfiwx

#stfdx found
fS r5
rA r6
rB r7
addi r4, r10, ins_stfdx - table_start
b epilogue_main

#Check for stfiwx
check_stfiwx:
first_check b21_30, stfiwx
bne+ check_stfs
check_b31
bne- check_stfs

#stfiwx found
fS r5
rA r6
rB r7
addi r4, r10, ins_stfiwx - table_start
b epilogue_main

#Check for stfs
check_stfs:
cmplwi r30, stfs@h
bne+ check_stfsu

#stfs found
fS r5
d r6
rA r7
addi r4, r10, ins_stfs - table_start
b epilogue_main

#Check for stfsu
check_stfsu:
cmplwi r30, stfsu@h
bne+ check_stfsux

#stfsu found
fS r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stfsu - table_start
b epilogue_main

#Check for stfsux
check_stfsux:
first_check b21_30, stfsux
bne+ check_stfsx
check_b31
bne- check_stfsx

#stfsux found
fS r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stfsux - table_start
b epilogue_main

#Check for stfsx
check_stfsx:
first_check b21_30, stfsx
bne+ check_sth
check_b31
bne- check_sth

#stfsx found
fS r5
rA r6
rB r7
addi r4, r10, ins_stfsx - table_start
b epilogue_main

#Check for sth
check_sth:
cmplwi r30, sth@h
bne+ check_sthbrx

#sth found
rS r5
d r6
rA r7
addi r4, r10, ins_sth - table_start
b epilogue_main

#Check for sthbrx
check_sthbrx:
first_check b21_30, sthbrx
bne+ check_sthu
check_b31
bne- check_sthu

#sthbrx found
rS r5
rA r6
rB r7
addi r4, r10, ins_sthbrx - table_start
b epilogue_main

#Check for sthu
check_sthu:
cmplwi r30, sthu@h
bne+ check_sthux

#sthu found
rS r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_sthu - table_start
b epilogue_main

#Check for sthux
check_sthux:
first_check b21_30, sthux
bne+ check_sthx
check_b31
bne- check_sthx

#sthux found
rS r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_sthux - table_start
b epilogue_main

#Check for sthx
check_sthx:
first_check b21_30, sthx
bne+ check_stmw
check_b31
bne- check_stmw

#sthx found
rS r5
rA r6
rB r7
addi r4, r10, ins_sthx - table_start
b epilogue_main

#Check for stmw
check_stmw:
cmplwi r30, stmw@h
bne+ check_stswi

#stmw found
rS r5
d r6
rA r7
addi r4, r10, ins_stmw - table_start
b epilogue_main

#Check for stswi
check_stswi:
first_check b21_30, stswi
bne+ check_stswx
check_b31
bne- check_stswx

#stswi found
rS r5
rA r6
NB r7
addi r4, r10, ins_stswi - table_start
b epilogue_main

#Check for stswx
check_stswx:
first_check b21_30, stswx
bne+ check_stw
check_b31
bne- check_stw

#stswx found
rS r5
rA r6
rB r7
addi r4, r10, ins_stswx - table_start
b epilogue_main

#Check for stw
check_stw:
cmplwi r30, stw@h
bne+ check_stwbrx

#stw found
rS r5
d r6
rA r7
addi r4, r10, ins_stw - table_start
b epilogue_main

#Check for stwbrx
check_stwbrx:
first_check b21_30, stwbrx
bne+ check_stwcx_
check_b31
bne- check_stwcx_

#stwbrx found
rS r5
rA r6
rB r7
addi r4, r10, ins_stwbrx - table_start
b epilogue_main

#Check for stwcx.
check_stwcx_:
clrrwi r0, r31, 26 #Place Opcode (not moved) into r0
rlwimi r0, r31, 0, 21, 31 #Place stwcx.'s secondary bits into r0 while preserving all other bits
xoris r0, r0, stwcxRC@h #This will result in 0 if opcode is for stwcx.
cmplwi r0, stwcxRC@l #Now simply check lower 16-bits
bne+ check_stwu

#stwcx. found
rS r5
rA r6
rB r7
addi r4, r10, ins_stwcx_ - table_start
b epilogue_main

#Check for stwu
check_stwu:
cmplwi r30, stwu@h
bne+ check_stwux

#stwu found
rS r5
d r6
rA r7
loadstorefloat_or_storeint_update_doublecheck
addi r4, r10, ins_stwu - table_start
b epilogue_main

#Check for stwux
check_stwux:
first_check b21_30, stwux
bne+ check_stwx
check_b31
bne- check_stwx

#stwux found
rS r5
rA r6
rB r7
loadstoreuxfloat_or_storeuxint_doublecheck
addi r4, r10, ins_stwux - table_start
b epilogue_main

#Check for stwx
check_stwx:
first_check b21_30, stwx
bne+ check_subX
check_b31
bne- check_subX

#stwx found
rS r5
rA r6
rB r7
addi r4, r10, ins_stwx - table_start
b epilogue_main

#Check for subX
check_subX:
first_check b22_30, subX
bne+ check_subcX

#subX found
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 21, 0x0000001F #Swap rA and rB for sub simplified mnemonic, must keep this out of macro usage
rlwinm r7, r31, 16, 0x0000001F
andi. r0, r31, oe | rc
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
first_check b22_30, subcX
bne+ check_subfeX

#subcX found
rlwinm r5, r31, 11, 0x0000001F
rlwinm r6, r31, 21, 0x0000001F #Swap rA and rB for subc simplified mnemonic, must keep this out of macro usage
rlwinm r7, r31, 16, 0x0000001F
andi. r0, r31, oe | rc
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
first_check b22_30, subfeX
bne+ check_subfic

#subfeX found
rD r5
rA r6
rB r7
andi. r0, r31, oe | rc
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
cmplwi r30, subfic@h
bne+ check_subfmeX

#subfic found
rD r5
rA r6
SIMM r7
addi r4, r10, ins_subfic - table_start
b epilogue_main

#Check for subfmeX
check_subfmeX:
first_check b22_30, subfmeX
bne+ check_subfzeX
check_nullrB
bne- check_subfzeX

#subfmeX found
rD r5
rA r6
andi. r0, r31, oe | rc
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
first_check b22_30, subfzeX
bne+ check_sync
check_nullrB
bne- check_sync

#subfzeX found
rD r5
rA r6
andi. r0, r31, oe | rc
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
first_check b21_30, sync
bne+ check_tlbienow
second_check check_syncs
bne- check_tlbienow

#sync found
addi r4, r10, ins_sync - table_start
b epilogue_main

#Check for tlbie
check_tlbienow:
first_check b21_30, tlbie
bne+ check_tlbsync
second_check check_tlbie
bne- check_tlbsync

#tlbie found
rB r5
addi r4, r10, ins_tlbie - table_start
b epilogue_main

#Check for tlbsync
check_tlbsync:
first_check b21_30, tlbsync
bne+ check_tw
second_check check_syncs
bne- check_tw

#tlbsync found
addi r4, r10, ins_tlbsync - table_start
b epilogue_main

#Check for tw
check_tw:
first_check b21_30, tw
bne+ check_twi
check_b31
bne- check_twi

#tw found (HOWEVER check for trap first)
TO r5
rA r6
rB r7
cmpwi r5, 31 #If TO = r31 regardless of what rA and rB are, then its trap simplified mnemonic
bne+ not_trap
addi r4, r10, ins_trap - table_start
b epilogue_main
not_trap:
addi r4, r10, ins_tw - table_start
b epilogue_main

#Check for twi
check_twi:
cmplwi r30, twi@h
bne+ check_xorX

#twi found
TO r5
rA r6
SIMM r7
addi r4, r10, ins_twi - table_start
b epilogue_main

#Check for xorX
check_xorX:
first_check b21_30, xorX
bne+ check_xori

#xorX found
rA r5
rS r6
rB r7
andi. r0, r31, rc
addi r4, r10, ins_xor - table_start
beq- epilogue_main
addi r4, r10, ins_xor_ - table_start
b epilogue_main

#Check for xori
check_xori:
cmplwi r30, xori@h
bne+ check_xoris

#xori found
rA r5
rS r6
UIMM r7
addi r4, r10, ins_xori - table_start
b epilogue_main

#Check for xoris
check_xoris:
cmplwi r30, xoris@h
bne+ do_invalid

#xoris found
rA r5
rS r6
UIMM r7
addi r4, r10, ins_xoris - table_start
b epilogue_main

#No valid instruction found
do_invalid:
addi r4, r10, invalid_instruction - table_start
mr r5, r31

#Not the correct label name, but I'm too lazy to change all the branch label names that just here, lmao.
epilogue_main:
#Call sprintf
lwz r12, 0 (r10)
mtlr r12
blrl

#Verify return of sprintf
cmpwi r3, 0
li r3, 0
bgt- 0x8
li r3, -2

#Real epilogue
lwz r26, 0x8 (sp)
lwz r27, 0xC (sp)
lwz r28, 0x10 (sp)
lwz r29, 0x14 (sp)
lwz r30, 0x18 (sp)
lwz r31, 0x1C (sp)
lwz r0, 0x0024 (sp)
mtlr r0
addi sp, sp, 0x0020
blr
