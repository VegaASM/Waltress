/*
    Waltress - 100% Broadway Compliant PPC Assembler+Disassembler written in PPC
    Copyright (C) 2022-2024 Vega

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
#r3 = address where line of source is located at
#r4 = address to store compiled instruction to

#r3 return values
#0 = Success
#-3 = sscanf fail (source line is not in correct format)
#-4 = incorrect instruction parameter

.globl asm_engine
asm_engine:

#Handy label names
.set asm_rc, 0x00000001
.set asm_oe, 0x00000400
.set asm_lk, 0x00000001
.set asm_aa, 0x00000002

#A hacky patch to make sure something such as "nopjsdladjsa" doesn't get verified as "nop" from memcmp. Avoding strcmp and strncmp due to this code already being really slow
#NOTE might just change to strcmp or strncmp instead to save length
.macro pre_check_memcmp
lbzx r0, r31, r5 #Null byte should be located at this offset
cmpwi r0, 0
bne- 0xC
bl memcmp
b 0x8
li r3, -1
.endm

.macro call_sscanf_one
addi r5, sp, 0x8
mr r3, r31
bl sscanf
.endm

.macro call_sscanf_two
addi r5, sp, 0x8
addi r6, sp, 0xC
mr r3, r31
bl sscanf
.endm

.macro call_sscanf_three
addi r5, sp, 0x8
addi r6, sp, 0xC
addi r7, sp, 0x10
mr r3, r31
bl sscanf
.endm

.macro call_sscanf_four
addi r5, sp, 0x8
addi r6, sp, 0xC
addi r7, sp, 0x10
addi r8, sp, 0x14
mr r3, r31
bl sscanf
.endm

.macro call_sscanf_five
addi r5, sp, 0x8
addi r6, sp, 0xC
addi r7, sp, 0x10
addi r8, sp, 0x14
addi r9, sp, 0x18
mr r3, r31
bl sscanf
.endm

.macro process_three_items_left_aligned #NOT FOR STRING STORE/LOADS!!! (lswi and stswi)
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp)
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_nonstoreload #for things such as addi, addic., etc NOT for store/loads and NOT for logical instructions
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #IMM in r7!!!
cmplwi r7, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14 #yes skip the clrlwi cuz it wont be needed for 0x0000XXXX values
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r7, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r7, r7, 16
slwi r5, r5, 21
slwi r6, r6, 16 #No need to shift r7 (IMM)
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_addis
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #IMM in r7!!!
cmplwi r7, 0xFFFF
bgt- epilogue_error
clrlwi r7, r7, 16
slwi r5, r5, 21
slwi r6, r6, 16 #No need to shift r7 (IMM)
or r5, r5, r6
or r5, r5, r7
.endm

.macro processSUBTRACT_imm_nonstoreload #for things such as subi, subic., etc NOT for store/loads and NOT for logical instructions
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #IMM in r7!!!
cmplwi r7, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x10
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r7, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
neg r7, r7 #Flip IMM
clrlwi r7, r7, 16
slwi r5, r5, 21
slwi r6, r6, 16 #No need to shift r7 (IMM)
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_subis
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #IMM in r7!!!
cmplwi r7, 0xFFFF
bgt- epilogue_error
extsh r7, r7
neg r7, r7
clrlwi r7, r7, 16
slwi r5, r5, 21
slwi r6, r6, 16 #No need to shift r7 (IMM)
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_two_items_left_aligned
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
or r5, r5, r6
.endm

.macro process_three_items_logical
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp)
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
slwi r7, r7, 11 #2nd source register goes in far right!
or r5, r5, r7
or r5, r5, r6
.endm

.macro process_one_item_branch #for b, ba, bl, and bla
lwz r5, 0x8 (sp) #SIMM in r5!
andi. r0, r5, 3 #SIMM must be divisible by 4
bne- epilogue_error
#Proper range is
#0x0 thru 0x001FFFFFC
#0xFFFFFFFC thru 0xFE000000
lis r0, 0x0200
cmplw r5, r0
blt+ 0x14 #Forward branches more common than backwards
srwi r0, r5, 25 #After this shift, r0 should be 0x7F
cmpwi r0, 0x7F
bne- epilogue_error
clrlwi r5, r5, 6
.endm

.macro process_three_items_bcX #For bc, bcl, bca, and bcla
lwz r5, 0x8 (sp) #BO
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #BI
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #SIMM in r7!!
andi. r0, r7, 3 #SIMM  needs to be divisible by 4
bne- epilogue_error
cmplwi r7, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r7, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r7, r7, 16
slwi r5, r5, 21
slwi r6, r6, 16 #No shifting needed for r7
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_two_items_logical #for exstb(.) and exsth; NOT for Neg! Neg is NOT a logical operation!
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #Source register goes in far left!
or r5, r5, r6
.endm

.macro process_two_items_cache #right aligned
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 16
slwi r6, r6, 11
or r5, r5, r6
.endm

.macro process_two_items_left_split
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 11
or r5, r5, r6
.endm

.macro process_three_items_compare #float and paired single compares only
lwz r5, 0x8 (sp)
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp)
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_four_items
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp)
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp)
cmplwi r8, 31
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 6 #Yes this is correct, fC goes into 4th/final spot
slwi r8, r8, 11 #Yes this is correct, fB goes into 3rd spot
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
.endm

.macro process_three_items_leftwo_rightone_split
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp)
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 6
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_storeload
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r7, 0x10 (sp)
cmplwi r7, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #IMM is in r6
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for IMM (r6)
or r5, r5, r7
.endm

.macro process_one_item_left_aligned
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
slwi r5, r5, 21
.endm

.macro process_imm_logical
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #IMM in r7!!!!
cmplwi r7, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #Source register goes to far left!
or r5, r5, r6
or r5, r5, r7 #No need to shift IMM
.endm

.macro process_imm_psq #for psq_l and psq_st ONLY
lwz r5, 0x8 (sp) #frD
cmplwi r5, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #W
cmplwi r8, 1
bgt- epilogue_error
lwz r9, 0x18 (sp) #I
cmplwi r9, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #IMM!!!
cmplwi r6, 0x7FF
blt+ 0x14
#Make sure 12-bit negative SIMM is legit
ori r0, r6, 0xFFF #Filp all bits in 12-bit unsigned field
cmpwi r0, -1 #After field fill in, r0 should be -1
bne- epilogue_error
clrlwi r6, r6, 20
slwi r5, r5, 21
slwi r7, r7, 16
slwi r8, r8, 15
slwi r9, r9, 12
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
.endm

.macro process_nonimm_psq #for psq_lx and psq_stx ONLY
lwz r5, 0x8 (sp) #frD/frS
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #W
cmplwi r8, 1
bgt- epilogue_error
lwz r9, 0x18 (sp) #I
cmplwi r9, 7
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
slwi r8, r8, 10
slwi r9, r9, 7
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
.endm

.macro process_imm_psq_update #for psq_lu and psq_stu ONLY
lwz r5, 0x8 (sp) #frD
cmplwi r5, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #W
cmplwi r8, 1
bgt- epilogue_error
lwz r9, 0x18 (sp) #I
cmplwi r9, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #IMM!!!
cmplwi r6, 0x7FF
blt+ 0x14
#Make sure 12-bit negative SIMM is legit
ori r0, r6, 0xFFF #Filp all bits in 12-bit unsigned field
cmpwi r0, -1 #After field fill in, r0 should be -1
bne- epilogue_error
clrlwi r6, r6, 20
cmpwi r7, 0 #rA cannot be r0
beq- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
slwi r8, r8, 15
slwi r9, r9, 12
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
.endm

.macro process_nonimm_psq_updateindex #for psq_lux and psq_stux ONLY
lwz r5, 0x8 (sp) #frD/frS
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #W
cmplwi r8, 1
bgt- epilogue_error
lwz r9, 0x18 (sp) #I
cmplwi r9, 7
bgt- epilogue_error
cmpwi r6, 0 #rA cannot be r0
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
slwi r8, r8, 10
slwi r9, r9, 7
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
.endm

.macro process_five_items #For rotate instructions. Operates in logical form, fyi. For the 3 rotate instructions only
lwz r5, 0x8 (sp) #rA
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rS
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #SH/rB
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #MB
cmplwi r8, 31
bgt- epilogue_error
lwz r9, 0x18 (sp) #ME
cmplwi r9, 31
bgt- epilogue_error
slwi r5, r5, 16 #Dest register (rA) goes 2nd spot
slwi r6, r6, 21 #rS goes far left
slwi r7, r7, 11 #SH/rB goes in 3rd spot
slwi r8, r8, 6 #MB goes in 4th spot
slwi r9, r9, 1 #ME goes far right
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
.endm

.macro process_simpilified_logical_two_items #for mr(.) and not(.)
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle
slwi r7, r6, 21 #1st source register goes far left
slwi r6, r6, 11 #2nd source register (same register value being used as 1st source, this goes far right)
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_int_load_update #for lbzu, lhau, lhzu, lwzu
#Other than typical checks, rA cannot be r0 and rA =/= rD
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #IMM is in r6!!!
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
cmpwi r7, 0 #rA cannot be r0
beq- epilogue_error
cmpw r5, r7 #rA cannot be rD
beq- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for IMM (r6)
or r5, r5, r7
.endm

.macro process_load_int_updateindex #for lbzux, lhaux, lhzux, lwxuz
#Other than typical checks, rA cannot be r0 and rA =/= rD
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB
cmplwi r7, 31
bgt- epilogue_error
cmpwi r6, 0 #rA cannot be r0
beq- epilogue_error
cmpw r5, r6 #rA cannot be rD
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_update_rAneq0 #for lfdu, lfsu, stbu, stfdu, stfsu, sthu, stwu
#Other than typical checks, rA cannot be r0
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #IMM is in r6!!!
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
cmpwi r7, 0 #rA cannot be r0
beq- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for IMM (r6)
or r5, r5, r7
.endm

.macro process_float_or_intstore_updateindex #for lfdux, lfsux, stbux, stfdux, stfsux, sthux, stwux
#Other than typical checks, rA cannot be r0
lwz r5, 0x8 (sp) #frD/frS/rS
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB
cmplwi r7, 31
bgt- epilogue_error
cmpwi r6, 0 #rA cannot be r0
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_simp_sub_subc #Swap rA and rB
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA subf
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB subf
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 11 #Swap rA and rB due to simplified mnemonic use
slwi r7, r7, 16
or r5, r5, r6
or r5, r5, r7
.endm

#Following 4 macros are for simplified bcX
.macro process_bcX_2sscanfarg BO_ValueNOHINT, aalkbits, virtual_hint #For bdnzfX, bdzfX, bdnztX, and bdztX
#NOTE BO_ValueNOHINT can only be 0bXXXXX
#NOTE aalkbits can only 0 thru 3
#NOTE virtual_hint can only be 0, 1, or -1 (-1 no hint provided)
lwz r5, 0x8 (sp) #BI
cmplwi r5, 31
bgt- epilogue_error_bcX
lwz r6, 0xC (sp) #SIMM (must be div'd by 4)
andi. r0, r6, 3 #SIMM  needs to be divisible by 4
bne- epilogue_error_bcX
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error_bcX
clrlwi r6, r6, 16
slwi r5, r5, 16 #Shift BI into place
li r7, \BO_ValueNOHINT
#
li r8, \virtual_hint
cmpwi r8, -1
beq- 0x10 #If equal then no instruction hint was in string, which means regardless of SIMM, don't OR anything into BO hint slot
#A virtual hint was provided, since the instruction mnemonic has a provided hint
rlwinm r9, r6, 17, 0x1 #Extract SIMM sign bit
xor r8, r8, r9 #XOR virtual hint with SIMM sign bit to get proper bit value to use for the BO hint bit
#Insert true bit
rlwimi r7, r8, 0, 0x1
#where beq- lands at
slwi r7, r7, 21 #Shift BO into place
or r5, r5, r6 #No shifting needed for SIMM
or r5, r5, r7
ori r5, r5, \aalkbits
oris r3, r5, 0x4000
.endm

.macro process_bcX_1sscanfarg_cr0 BO_ValueNOHINT, BI_Value, aalkbits, virtual_hint #For all "common" bcX branches that use cr0
#NOTE BI will be 0,1,2,or 3 when you use this macro!
lwz r5, 0x8 (sp) #SIMM (must be div'd by 4)
andi. r0, r5, 3 #SIMM  needs to be divisible by 4
bne- epilogue_error_bcX
cmplwi r5, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r5, 16
cmplwi r0, 0xFFFF
bne- epilogue_error_bcX
clrlwi r5, r5, 16
li r6, \BO_ValueNOHINT
#
li r7, \virtual_hint
cmpwi r7, -1
beq- 0x10 #If equal then no instruction hint was in string, which means regardless of SIMM, don't OR anything into BO hint slot
#A virtual hint was provided, since the instruction mnemonic has a provided hint
rlwinm r8, r5, 17, 0x1 #Extract SIMM sign bit
xor r7, r7, r8 #XOR virtual hint with SIMM sign bit to get proper bit value to use for the BO hint bit
#Insert true bit
rlwimi r6, r7, 0, 0x1
#where beq- lands at
slwi r6, r6, 21 #Shift BO into place
li r7, \BI_Value
slwi r7, r7, 16 #Shift BI info place
or r5, r5, r6 #No shifting needed for SIMM
or r5, r5, r7
ori r5, r5, \aalkbits
oris r3, r5, 0x4000
.endm

.macro process_bcX_2sscanfarg_NOTcr0 BO_ValueNOHINT, crB_bit, aalkbits, virtual_hint #For all "common" bcX branches that *DON'T* use cr0 or cr0 is explicitly written out in the instruction
lwz r5, 0x8 (sp) #crF, will be converted to BI soon
cmplwi r5, 7
bgt- epilogue_error_bcX
lwz r6, 0xC (sp) #SIMM (must be div'd by 4)
andi. r0, r6, 3 #SIMM  needs to be divisible by 4
bne- epilogue_error_bcX
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error_bcX
clrlwi r6, r6, 16
#Calc BI value from crF sscanf value and crB_bit provided value
#(4*crF)+crB
slwi r5, r5, 2
li r7, \crB_bit
add r5, r5, r7
slwi r5, r5, 16 #Shift BI value into place
li r7, \BO_ValueNOHINT
#
li r8, \virtual_hint
cmpwi r8, -1
beq- 0x10 #If equal then no instruction hint was in string, which means regardless of SIMM, don't OR anything into BO hint slot
#A virtual hint was provided, since the instruction mnemonic has a provided hint
rlwinm r9, r6, 17, 0x1 #Extract SIMM sign bit
xor r8, r8, r9 #XOR virtual hint with SIMM sign bit to get proper bit value to use for the BO hint bit
#Insert true bit
rlwimi r7, r8, 0, 0x1
#where beq- lands at
slwi r7, r7, 21 #Shift BO into place
or r5, r5, r6 #No shifting needed for SIMM
or r5, r5, r7
ori r5, r5, \aalkbits
oris r3, r5, 0x4000
.endm

.macro process_bcX_dnz_nz BO_ValueNOHINT, aalkbits, virtual_hint #For bdnzX, bdzX
lwz r5, 0x8 (sp) #SIMM (must be div'd by 4)
andi. r0, r5, 3 #SIMM  needs to be divisible by 4
bne- epilogue_error_bcX
cmplwi r5, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r5, 16
cmplwi r0, 0xFFFF
bne- epilogue_error_bcX
clrlwi r5, r5, 16
li r6, \BO_ValueNOHINT
#
li r7, \virtual_hint
cmpwi r7, -1
beq- 0x10 #If equal then no instruciton hint was in string, which means regardless of SIMM, don't OR anything into BO hint slot
#A virtual hint was provided, since the instruction mnemonic has a provided hint
rlwinm r8, r5, 17, 0x1 #Extract SIMM sign bit
xor r7, r7, r8 #XOR virtual hint with SIMM sign bit to get proper bit value to use for the BO hint bit
#Insert true bit
rlwimi r6, r7, 0, 0x1
#where beq- lands at
slwi r6, r6, 21 #Shift BO into place
or r5, r5, r6 #No shifting needed for SIMM
ori r5, r5, \aalkbits
oris r3, r5, 0x4000
.endm

.macro process_bcX_always aalkbits #For bc-always
lwz r5, 0x8 (sp) #SIMM (must be div'd by 4)
andi. r0, r5, 3 #SIMM  needs to be divisible by 4
bne- epilogue_error_bcX
cmplwi r5, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r5, 16
cmplwi r0, 0xFFFF
bne- epilogue_error_bcX
clrlwi r5, r5, 16
ori r5, r5, \aalkbits #No shifting needed for SIMM
oris r3, r5, 0x4280 #BO of 0b10100 with BI of 0.
.endm

#Following 4 macros are for simplified bcctrX
.macro process_bcctrX_1sscanfarg BO_Value, lkbits #For bdnzfctrX, bdzfctrX, bdnztctrX, and bdztctrX
lwz r5, 0x8 (sp) #BI
cmplwi r5, 31
bgt- epilogue_error_bcctrX
slwi r5, r5, 16 #Shift BI into place
li r6, \BO_Value
slwi r6, r6, 21 #Shift BO into place
or r5, r5, r6
ori r5, r5, \lkbits
lwz r0, 0x1C (r29)
or r3, r0, r5
.endm

.macro process_bcctrX_cr0 BO_Value, BI_Value, lkbits #For all "common" bcctrX branches that use cr0
#NOTE BI will be 0,1,2,or 3 when you use this macro!
#NOTE no sscanf int args
li r5, \BO_Value
slwi r5, r5, 21 #Shift BO into place
li r6, \BI_Value
slwi r6, r6, 16 #Shift BI info place
or r5, r5, r6 #No shifting needed for SIMM
ori r5, r5, \lkbits
lwz r0, 0x1C (r29)
or r3, r0, r5
.endm

.macro process_bcctrX_1sscanfarg_NOTcr0 BO_Value, crB_bit, lkbits #For all "common" bcctrX branches that *DON'T* use cr0 or cr0 is explicitly written out in the instruction
lwz r5, 0x8 (sp) #crF, will be converted to BI soon
cmplwi r5, 7
bgt- epilogue_error_bcctrX
#Calc BI value from crF sscanf value and crB_bit provided value
#(4*crF)+crB
slwi r5, r5, 2
li r6, \crB_bit
add r5, r5, r6
slwi r5, r5, 16 #Shift BI value into place
li r6, \BO_Value
slwi r6, r6, 21 #Shift BO into place
or r5, r5, r6
ori r5, r5, \lkbits
lwz r0, 0x1C (r29)
or r3, r0, r5
.endm

.macro process_bcctrX_NOsscanfarg BO_Value, lkbits #For bdnzctrX, bdzctrX
#NOTE no sscanf int args
li r5, \BO_Value
slwi r5, r5, 21 #Shift BO into place
ori r5, r5, \lkbits
lwz r0, 0x1C (r29)
or r3, r0, r5
.endm
 
#Following 4 macros are for simplified bclrX
.macro process_bclrX_1sscanfarg BO_Value, lkbits #For bdnzflrX, bdzflrX, bdnztlrX, and bdztlrX
lwz r5, 0x8 (sp) #BI
cmplwi r5, 31
bgt- epilogue_error_bclrX
slwi r5, r5, 16 #Shift BI into place
li r6, \BO_Value
slwi r6, r6, 21 #Shift BO into place
or r5, r5, r6
ori r5, r5, \lkbits
lwz r0, 0x20 (r29)
or r3, r0, r5
.endm

.macro process_bclrX_cr0 BO_Value, BI_Value, lkbits #For all "common" bclrX branches that use cr0
#NOTE BI will be 0,1,2,or 3 when you use this macro!
#NOTE no sscanf int args
li r5, \BO_Value
slwi r5, r5, 21 #Shift BO into place
li r6, \BI_Value
slwi r6, r6, 16 #Shift BI info place
or r5, r5, r6 #No shifting needed for SIMM
ori r5, r5, \lkbits
lwz r0, 0x20 (r29)
or r3, r0, r5
.endm

.macro process_bclrX_1sscanfarg_NOTcr0 BO_Value, crB_bit, lkbits #For all "common" bclrX branches that *DON'T* use cr0 or cr0 is explicitly written out in the instruction
lwz r5, 0x8 (sp) #crF, will be converted to BI soon
cmplwi r5, 7
bgt- epilogue_error_bclrX
#Calc BI value from crF sscanf value and crB_bit provided value
#(4*crF)+crB
slwi r5, r5, 2
li r6, \crB_bit
add r5, r5, r6
slwi r5, r5, 16 #Shift BI value into place
li r6, \BO_Value
slwi r6, r6, 21 #Shift BO into place
or r5, r5, r6
ori r5, r5, \lkbits
lwz r0, 0x20 (r29)
or r3, r0, r5
.endm

.macro process_bclrX_NOsscanfarg BO_Value, lkbits #For bdnzlrX, bdzlrX
#NOTE no sscanf int args
li r5, \BO_Value
slwi r5, r5, 21 #Shift BO into place
ori r5, r5, \lkbits
lwz r0, 0x20 (r29)
or r3, r0, r5
.endm

#Start!

#Prologue, backup r29 thru r31 and also create a space field of 0x14 in size
stwu sp, -0x0030 (sp)
mflr r0
stw r29, 0x24 (sp)
stw r30, 0x28 (sp)
stw r31, 0x2C (sp)
stw r0, 0x0034 (sp)

#Backup r3 & r4 args
mr r31, r3
mr r30, r4

#Make massive lookup table; fyi capital X = Rc option
#ORing masks for instructions, only masks with non-zero bits in both upper and lower 16 bits need to be loaded from this lookup table. Masks that don't meet this requirement are commented out but left in source for personal preference.
bl asm_table
asm_table_start:
.long 0x7C000214 #0 addX
.long 0x7C000014 #0x4 addcX
.long 0x7C000114 #0x8 addeX
#.long 0x38000000 #addi
#.long 0x30000000 #addic
#.long 0x34000000 #addic.
#.long 0x3C000000 #addis
.long 0x7C0001D4 #0xC addmeX
.long 0x7C000194 #0x10 addzeX
.long 0x7C000038 #0x14 andX
.long 0x7C000078 #0x18 andcX
#.long 0x70000000 #andi.
#.long 0x74000000 #andis.
#.long 0x48000000 #bX
#.long 0x40000000 #bcX
.long 0x4C000420 #0x1C bcctrX
.long 0x4C000020 #0x20 bclrX
#.long 0x7C000000 #cmp
#.long 0x2C000000 #cmpi
.long 0x7C000040 #0x24 cmpl
#.long 0x28000000 #cmpli
.long 0x7C000034 #0x28 cntlzw
.long 0x4C000202 #0x2C crand
.long 0x4C000102 #0x30 crandc
.long 0x4C000242 #0x34 creqv
.long 0x4C0001C2 #0x38 crnand
.long 0x4C000042 #0x3C crnor
.long 0x4C000382 #0x40 cror
.long 0x4C000342 #0x44 crorc
.long 0x4C000182 #0x48 crxor
.long 0x7C0000AC #0x4C dcbf
.long 0x7C0003AC #0x50 dcbi
.long 0x7C00006C #0x54 dcbst
.long 0x7C00022C #0x58 dcbt
.long 0x7C0001EC #0x5C dcbtst
.long 0x7C0007EC #0x60 dcbz
.long 0x100007EC #0x64 dcbz_l
.long 0x7C0003D6 #0x68 divwX
.long 0x7C000396 #0x6C divwuX
.long 0x7C00026C #0x70 eciwx
.long 0x7C00036C #0x74 ecowx
.long 0x7C0006AC #0x78 eieio
.long 0x7C000238 #0x7C eqvX
.long 0x7C000774 #0x80 extsbX
.long 0x7C000734 #0x84 extshX
.long 0xFC000210 #0x88 fabsX
.long 0xFC00002A #0x8C faddX
.long 0xEC00002A #0x90 faddsX
.long 0xFC000040 #0x94 fcmpo
#.long 0xFC000000 #fcmpu
.long 0xFC00001C #0x98 fctiwX
.long 0xFC00001E #0x9C fctiwzX
.long 0xFC000024 #0xA0 fdivX
.long 0xEC000024 #0xA4 fdivsX
.long 0xFC00003A #0xA8 fmaddX
.long 0xEC00003A #0xAC fmaddsX
.long 0xFC000090 #0xB0 fmrX
.long 0xFC000038 #0xB4 fmsubX
.long 0xEC000038 #0xB8 fmsubsX
.long 0xFC000032 #0xBC fmulX
.long 0xEC000032 #0xC0 fmulsX
.long 0xFC000110 #0xC4 fnabsX
.long 0xFC000050 #0xC8 fnegX
.long 0xFC00003E #0xCC fnmaddX
.long 0xEC00003E #0xD0 fnmaddsX
.long 0xFC00003C #0xD4 fnmsubX
.long 0xEC00003C #0xD8 fnmsubsX
.long 0xEC000030 #0xDC fresX
.long 0xFC000018 #0xE0 frspX
.long 0xFC000034 #0xE4 frsqrteX
.long 0xFC00002E #0xE8 fselX
.long 0xFC000028 #0xEC fsubX
.long 0xEC000028 #0xF0 fsubsX
.long 0x7C0007AC #0xF4 icbi
.long 0x4C00012C #0xF8 isync
#.long 0x88000000 #lbz
#.long 0x8C000000 #lbzu
.long 0x7C0000EE #0xFC lbzux
.long 0x7C0000AE #0x100 lbzx
#.long 0xC8000000 #lfd
#.long 0xCC000000 #lfdu
.long 0x7C0004EE #0x104 lfdux
.long 0x7C0004AE #0x108 lfdx
#.long 0xC0000000 #lfs
#.long 0xC4000000 #lfsu
.long 0x7C00046E #0x10C lfsux
.long 0x7C00042E #0x110 lfsx
#.long 0xA8000000 #lha
#.long 0xAC000000 #lhau
.long 0x7C0002EE #0x114 lhaux
.long 0x7C0002AE #0x118 lhax
.long 0x7C00062C #0x11C lhbrx
#.long 0xA0000000 #lhz
#.long 0xA4000000 #lhzu
.long 0x7C00026E #0x120 lhzux
.long 0x7C00022E #0x124 lhzx
#.long 0xB8000000 #lmw
.long 0x7C0004AA #0x128 lswi
.long 0x7C00042A #0x12C lswx
.long 0x7C000028 #0x130 lwarx
.long 0x7C00042C #0x134 lwbrx
#.long 0x80000000 #lwz
#.long 0x84000000 #lwzu
.long 0x7C00006E #0x138 lwzux
.long 0x7C00002E #0x13C lwzx
#.long 0x4C000000 #mcrf
.long 0xFC000080 #0x140 mcrfs
.long 0x7C000400 #0x144 mcrxr
.long 0x7C000026 #0x148 mfcr
.long 0xFC00048E #0x14C mffsX
.long 0x7C0000A6 #0x150 mfmsr
.long 0x7C0002A6 #0x154 mfspr
.long 0x7C0004A6 #0x158 mfsr
.long 0x7C000526 #0x15C mfsrin
.long 0x7C0002E6 #0x160 mftb
.long 0x7C000120 #0x164 mtcrf
.long 0xFC00008C #0x168 mtfsb0X
.long 0xFC00004C #0x16C mtfsb1X
.long 0xFC00058E #0x170 mtfsfX
.long 0xFC00010C #0x174 mtfsfiX
.long 0x7C000124 #0x178 mtmsr
.long 0x7C0003A6 #0x17C mtspr
.long 0x7C0001A4 #0x180 mtsr
.long 0x7C0001E4 #0x184 msrin
.long 0x7C000096 #0x188 mulhwX
.long 0x7C000016 #0x18C mulhwuX
#.long 0x1C000000 #mulli
.long 0x7C0001D6 #0x190 mullwX
.long 0x7C0003B8 #0x194 nandX
.long 0x7C0000D0 #0x198 negX
.long 0x7C0000F8 #0x19C norX
.long 0x7C000378 #0x1A0 orX
.long 0x7C000338 #0x1A4 orcX
#.long 0x60000000 #ori
#.long 0x64000000 #oris
#.long 0xE0000000 #psq_l
#.long 0xE4000000 #psq_lu
.long 0x1000004C #0x1A8 psq_lux
.long 0x1000000C #0x1AC psq_lx
#.long 0xF0000000 #psq_st
#.long 0xF4000000 #psq_stu
.long 0x1000004E #0x1B0 psq_stux
.long 0x1000000E #0x1B4 psq_stx
.long 0x10000210 #0x1B8 ps_absX
.long 0x1000002A #0x1BC ps_addX
.long 0x10000040 #0x1C0 ps_cmpo0
.long 0x100000C0 #0x1C4 ps_cmpo1
#.long 0x10000000 #ps_cmpu0
.long 0x10000080 #0x1C8 ps_cmpu1
.long 0x10000024 #0x1CC ps_divX
.long 0x1000003A #0x1D0 ps_maddX
.long 0x1000001C #0x1D4 ps_madds0X
.long 0x1000001E #0x1D8 ps_madds1X
.long 0x10000420 #0x1DC ps_merge00X
.long 0x10000460 #0x1E0 ps_merge01X
.long 0x100004A0 #0x1E4 ps_merge10X
.long 0x100004E0 #0x1E8 ps_merge11X
.long 0x10000090 #0x1EC ps_mrX
.long 0x10000038 #0x1F0 ps_msubX
.long 0x10000032 #0x1F4 ps_mulX
.long 0x10000018 #0x1F8 ps_muls0X
.long 0x1000001A #0x1FC ps_muls1X
.long 0x10000110 #0x200 ps_nabsX
.long 0x10000050 #0x204 ps_negX
.long 0x1000003E #0x208 ps_nmaddX
.long 0x1000003C #0x20C ps_nmsubX
.long 0x10000030 #0x210 ps_resX
.long 0x10000034 #0x214 ps_rsqrteX
.long 0x1000002E #0x218 ps_selX
.long 0x10000028 #0x21C ps_subX
.long 0x10000014 #0x220 ps_sum0X
.long 0x10000016 #0x224 ps_sum1X
.long 0x4C000064 #0x228 rfi
#.long 0x50000000 #rlwimiX
#.long 0x54000000 #rlwinmX
#.long 0x5C000000 #rlwnmX
.long 0x44000002 #0x22C sc
.long 0x7C000030 #0x230 slwX
.long 0x7C000630 #0x234 srawX
.long 0x7C000670 #0x238 srawiX
.long 0x7C000430 #0x23C srwX
#.long 0x98000000 #stb
#.long 0x9C000000 #stbu
.long 0x7C0001EE #0x240 stbux
.long 0x7C0001AE #0x244 stbx
#.long 0xD8000000 #stfd
#.long 0xDC000000 #stfdu
.long 0x7C0005EE #0x248 stfdux
.long 0x7C0005AE #0x24C stfdx
.long 0x7C0007AE #0x250 stfiwx
#.long 0xD0000000 #stfs
#.long 0xD4000000 #stfsu
.long 0x7C00056E #0x254 stfsux
.long 0x7C00052E #0x258 stfsx
#.long 0xB0000000 #sth
.long 0x7C00072C #0x25C sthbrx
#.long 0xB4000000 #sthu
.long 0x7C00036E #0x260 sthux
.long 0x7C00032E #0x264 sthx
#.long 0xBC000000 #stmw
.long 0x7C0005AA #0x268 stswi
.long 0x7C00052A #0x26C stswx
#.long 0x90000000 #stw
.long 0x7C00052C #0x270 stwbrx
.long 0x7C00012D #0x274 stwcx.
#.long 0x94000000 #stwu
.long 0x7C00016E #0x278 stwux
.long 0x7C00012E #0x27C stwx
.long 0x7C000050 #0x280 subfX
.long 0x7C000010 #0x284 subfcX
.long 0x7C000110 #0x288 subfeX
#.long 0x20000000 #subfic
.long 0x7C0001D0 #0x28C subfmeX
.long 0x7C000190 #0x290 subfzeX
.long 0x7C0004AC #0x294 sync
.long 0x7C000264 #0x298 tlbie
.long 0x7C00046C #0x29C tlbsync
.long 0x7C000008 #0x2A0 tw
#.long 0x0C000000 #twi
.long 0x7C000278 #0x2A4 xorX
#.long 0x68000000 #xori
#.long 0x6C000000 #xoris
.long 0x03FFFFFC #TODO REMOVE ME 2A8 For Unconditional Branch SIMM Checking (lhz is shorter than lis + ori)
.short 0xFFFF #TODO REMOVE ME 0x2AC For 16-bit SIM Checking (lhz is shorter than lis + ori)
.short 0xFFFC #TODO REMOVE ME 0x2AE For 16-bit Conditional Branch SIMM Checking (lhz is shorter than lis + ori)
.long 0x7FE00008 #0x2B0 For simplified mnemonic trap
.long 0x4E800420 #0x2B4 For simplified mnemonic bctr
.long 0x4E800421 #0x2B8 For simplified mnemonic bctrl
.long 0x4E800020 #0x2BC For simplified mnemonic blr
.long 0x4E800021 #0x2C0 For simplified mnemonic blrl

#Instruction decompiled ASCii strings
asm_ins_add:
.asciz "add r%d, r%d, r%d"
asm_ins_add_:
.asciz "add. r%d, r%d, r%d"
asm_ins_addo:
.asciz "addo r%d, r%d, r%d"
asm_ins_addo_:
.asciz "addo. r%d, r%d, r%d"

asm_ins_addc:
.asciz "addc r%d, r%d, r%d"
asm_ins_addc_:
.asciz "addc. r%d, r%d, r%d"
asm_ins_addco:
.asciz "addco r%d, r%d, r%d"
asm_ins_addco_:
.asciz "addco. r%d, r%d, r%d"

asm_ins_adde:
.asciz "adde r%d, r%d, r%d"
asm_ins_adde_:
.asciz "adde. r%d, r%d, r%d"
asm_ins_addeo:
.asciz "addeo r%d, r%d, r%d"
asm_ins_addeo_:
.asciz "addeo. r%d, r%d, r%d"

asm_ins_addi:
.asciz "addi r%d, r%d, 0x%X"
asm_ins_addiDEC:
.asciz "addi r%d, r%d, %d"

asm_ins_subi:
.asciz "subi r%d, r%d, 0x%X"
asm_ins_subiDEC:
.asciz "subi r%d, r%d, %d"

asm_ins_addic:
.asciz "addic r%d, r%d, 0x%X"
asm_ins_addicDEC:
.asciz "addic r%d, r%d, %d"

asm_ins_subic:
.asciz "subic r%d, r%d, 0x%X"
asm_ins_subicDEC:
.asciz "subic r%d, r%d, %d"

asm_ins_addic_:
.asciz "addic. r%d, r%d, 0x%X"
asm_ins_addic_DEC:
.asciz "addic. r%d, r%d, %d"

asm_ins_subic_:
.asciz "subic. r%d, r%d, 0x%X"
asm_ins_subic_DEC:
.asciz "subic. r%d, r%d, %d"

asm_ins_addis:
.asciz "addis r%d, r%d, 0x%X"
asm_ins_addisDEC:
.asciz "addis r%d, r%d, %d"

asm_ins_subis:
.asciz "subis r%d, r%d, 0x%X"
asm_ins_subisDEC:
.asciz "subis r%d, r%d, %u"

asm_ins_addme:
.asciz "addme r%d, r%d"
asm_ins_addme_:
.asciz "addme. r%d, r%d"
asm_ins_addmeo:
.asciz "addmeo r%d, r%d"
asm_ins_addmeo_:
.asciz "addmeo. r%d, r%d"

asm_ins_addze:
.asciz "addze r%d, r%d"
asm_ins_addze_:
.asciz "addze. r%d, r%d"
asm_ins_addzeo:
.asciz "addzeo r%d, r%d"
asm_ins_addzeo_:
.asciz "addzeo. r%d, r%d"

asm_ins_and:
.asciz "and r%d, r%d, r%d" #0x718
asm_ins_and_:
.asciz "and. r%d, r%d, r%d" #0x738

asm_ins_andc:
.asciz "andc r%d, r%d, r%d" #0x758
asm_ins_andc_:
.asciz "andc. r%d, r%d, r%d" #0x778

asm_ins_andi_:
.asciz "andi. r%d, r%d, 0x%X" #0x798

asm_ins_andis_:
.asciz "andis. r%d, r%d, 0x%X" #0x7B8

asm_ins_b:
.asciz "b 0x%X" #0x7D8
asm_ins_ba:
.asciz "ba 0x%X" #0x7F8
asm_ins_bl:
.asciz "bl 0x%X" #0x818
asm_ins_bla:
.asciz "bla 0x%X" #0x838

asm_ins_bc:
.asciz "bc %d, %d, 0x%X" #0x858
asm_ins_bca:
.asciz "bca %d, %d, 0x%X" #0x878
asm_ins_bcl:
.asciz "bcl %d, %d, 0x%X" #0x898
asm_ins_bcla:
.asciz "bcla %d, %d, 0x%X" #0x8B8

asm_ins_bcctr:
.asciz "bcctr %d, %d" #0x8D8
asm_ins_bcctrl:
.asciz "bcctrl %d, %d" #0x8F8

asm_ins_bclr:
.asciz "bclr %d, %d" #0x918
asm_ins_bclrl:
.asciz "bclrl %d, %d" #0x938

asm_ins_cmp:
.asciz "cmp cr%d, %d, r%d, r%d" #0x958

asm_ins_cmpi:
.asciz "cmpi cr%d, %d, r%d, 0x%X" #0x978
asm_ins_cmpiDEC:
.asciz "cmpi cr%d, %d, r%d, %d" #0x978

asm_ins_cmpl:
.asciz "cmpl cr%d, %d, r%d, r%d" #0x998

asm_ins_cmpli:
.asciz "cmpli cr%d, %d, r%d, 0x%X" #0x9B8
asm_ins_cmpliDEC:
.asciz "cmpli cr%d, %d, r%d, %u" #0x9B8

asm_ins_cmpw: #Simplified mnemonic of cmp crX, 0, rX, rX
.asciz "cmpw cr%d, r%d, r%d"
asm_ins_cmpw_cr0:
.asciz "cmpw r%d, r%d"

asm_ins_cmpwi: #Simplified mnemonic of cmpi crX, 0, rX, 0xXXXX
.asciz "cmpwi cr%d, r%d, 0x%X"
asm_ins_cmpwiDEC: #Simplified mnemonic of cmpi crX, 0, rX, XXXX
.asciz "cmpwi cr%d, r%d, %d"
asm_ins_cmpwi_cr0:
.asciz "cmpwi r%d, 0x%X"
asm_ins_cmpwi_cr0DEC:
.asciz "cmpwi r%d, %d"

asm_ins_cmplw: #Simplified mnemonic of cmpl crX, 0, rX, rX
.asciz "cmplw cr%d, r%d, r%d"
asm_ins_cmplw_cr0:
.asciz "cmplw r%d, r%d"

asm_ins_cmplwi: #Simplified mnemonic of cmpli crX, 0, rX, 0xXXXX
.asciz "cmplwi cr%d, r%d, 0x%X"
asm_ins_cmplwiDEC: #Simplified mnemonic of cmpli crX, 0, rX, XXXX
.asciz "cmplwi cr%d, r%d, %u"
asm_ins_cmplwi_cr0:
.asciz "cmplwi r%d, 0x%X"
asm_ins_cmplwi_cr0DEC:
.asciz "cmplwi r%d, %u"

asm_ins_cntlzw:
.asciz "cntlzw r%d, r%d" #0x9D8
asm_ins_cntlzw_:
.asciz "cntlzw. r%d, r%d" #0x9F8

asm_ins_crand:
.asciz "crand %d, %d, %d" #0xA18

asm_ins_crandc:
.asciz "crandc %d, %d, %d" #0xA38

asm_ins_creqv:
.asciz "creqv %d, %d, %d" #0xA58

asm_ins_crnand:
.asciz "crnand %d, %d, %d" #0xA78

asm_ins_crnor:
.asciz "crnor %d, %d, %d" #0xA98

asm_ins_cror:
.asciz "cror %d, %d, %d" #0xAB8

asm_ins_crorc:
.asciz "crorc %d, %d, %d" #0xAD8

asm_ins_crxor:
.asciz "crxor %d, %d, %d" #0xAF8

asm_ins_dcbf:
.asciz "dcbf r%d, r%d" #0xB18

asm_ins_dcbi:
.asciz "dcbi r%d, r%d" #0xB38

asm_ins_dcbst:
.asciz "dcbst r%d, r%d" #0xB58

asm_ins_dcbt:
.asciz "dcbt r%d, r%d" #0xB78

asm_ins_dcbtst:
.asciz "dcbtst r%d, r%d" #0xB98

asm_ins_dcbz:
.asciz "dcbz r%d, r%d" #0xBB8

asm_ins_dcbz_l:
.asciz "dcbz_l r%d, r%d" #0xBD8

asm_ins_divw:
.asciz "divw r%d, r%d, r%d" #0xBF8
asm_ins_divw_:
.asciz "divw. r%d, r%d, r%d" #0xC18
asm_ins_divwo:
.asciz "divwo r%d, r%d, r%d" #0xC38
asm_ins_divwo_:
.asciz "divwo. r%d, r%d, r%d" #0xC58

asm_ins_divwu:
.asciz "divwu r%d, r%d, r%d" #0xC78
asm_ins_divwu_:
.asciz "divwu. r%d, r%d, r%d" #0xC98
asm_ins_divwuo:
.asciz "divwuo r%d, r%d, r%d" #0xCB8
asm_ins_divwuo_:
.asciz "divwuo. r%d, r%d, r%d" #0xCD8

asm_ins_eciwx:
.asciz "eciwx r%d, r%d, r%d" #0xCF8

asm_ins_ecowx:
.asciz "ecowx r%d, r%d, r%d" #0xD18

asm_ins_eieio:
.asciz "eieio" #0xD38

asm_ins_eqv:
.asciz "eqv r%d, r%d, r%d"
asm_ins_eqv_:
.asciz "eqv. r%d, r%d, r%d" #0xD68

asm_ins_extsb:
.asciz "extsb r%d, r%d" #0xD88
asm_ins_extsb_:
.asciz "extsb. r%d, r%d" #0xDA8

asm_ins_extsh:
.asciz "extsh r%d, r%d" #0xDC8
asm_ins_extsh_:
.asciz "extsh. r%d, r%d" #0xDE8

asm_ins_fabs:
.asciz "fabs f%d, f%d" #0xE08
asm_ins_fabs_:
.asciz "fabs. f%d, f%d" #0xE28

asm_ins_fadd:
.asciz "fadd f%d, f%d, f%d" #0xE48
asm_ins_fadd_:
.asciz "fadd. f%d, f%d, f%d" #0xE68

asm_ins_fadds:
.asciz "fadds f%d, f%d, f%d" #0xE88
asm_ins_fadds_:
.asciz "fadds. f%d, f%d, f%d" #0xEA8

asm_ins_fcmpo:
.asciz "fcmpo cr%d, f%d, f%d" #0xEC8

asm_ins_fcmpu:
.asciz "fcmpu cr%d, f%d, f%d" #0xEE8

asm_ins_fctiw:
.asciz "fctiw f%d, f%d" #0xF08
asm_ins_fctiw_:
.asciz "fctiw. f%d, f%d" #0xF28

asm_ins_fctiwz:
.asciz "fctiwz f%d, f%d" #0xF48
asm_ins_fctiwz_:
.asciz "fctiwz. f%d, f%d" #0xF68

asm_ins_fdiv:
.asciz "fdiv f%d, f%d, f%d" #0xF88
asm_ins_fdiv_:
.asciz "fdiv. f%d, f%d, f%d" #0xFA8

asm_ins_fdivs:
.asciz "fdivs f%d, f%d, f%d" #0xFC8
asm_ins_fdivs_:
.asciz "fdivs. f%d, f%d, f%d" #0xFE8

asm_ins_fmadd:
.asciz "fmadd f%d, f%d, f%d, f%d" #0x1008
asm_ins_fmadd_:
.asciz "fmadd. f%d, f%d, f%d, f%d" #0x1028

asm_ins_fmadds:
.asciz "fmadds f%d, f%d, f%d, f%d" #0x1048
asm_ins_fmadds_:
.asciz "fmadds. f%d, f%d, f%d, f%d" #0x1068

asm_ins_fmr:
.asciz "fmr f%d, f%d" #0x1088
asm_ins_fmr_:
.asciz "fmr. f%d, f%d" #0x10A8

asm_ins_fmsub:
.asciz "fmsub f%d, f%d, f%d, f%d" #0x10C8
asm_ins_fmsub_:
.asciz "fmsub. f%d, f%d, f%d, f%d" #0x10E8

asm_ins_fmsubs:
.asciz "fmsubs f%d, f%d, f%d, f%d" #0x1108
asm_ins_fmsubs_:
.asciz "fmsubs. f%d, f%d, f%d, f%d" #0x1128

asm_ins_fmul:
.asciz "fmul f%d, f%d, f%d" #0x1148
asm_ins_fmul_:
.asciz "fmul. f%d, f%d, f%d" #0x1168

asm_ins_fmuls:
.asciz "fmuls f%d, f%d, f%d" #0x1188
asm_ins_fmuls_:
.asciz "fmuls. f%d, f%d, f%d" #0x11A8

asm_ins_fnabs:
.asciz "fnabs f%d, f%d" #0x11C8
asm_ins_fnabs_:
.asciz "fnabs. f%d, f%d" #0x11E8

asm_ins_fneg:
.asciz "fneg f%d, f%d" #0x1208
asm_ins_fneg_:
.asciz "fneg. f%d, f%d" #0x1228

asm_ins_fnmadd:
.asciz "fnmadd f%d, f%d, f%d, f%d" #0x1248
asm_ins_fnmadd_:
.asciz "fnmadd. f%d, f%d, f%d, f%d" #0x1268

asm_ins_fnmadds:
.asciz "fnmadds f%d, f%d, f%d, f%d" #0x1288
asm_ins_fnmadds_:
.asciz "fnmadds. f%d, f%d, f%d, f%d" #0x12A8

asm_ins_fnmsub:
.asciz "fnmsub f%d, f%d, f%d, f%d" #0x12C8
asm_ins_fnmsub_:
.asciz "fnmsub. f%d, f%d, f%d, f%d" #0x12E8

asm_ins_fnmsubs:
.asciz "fnmsubs f%d, f%d, f%d, f%d" #0x1308
asm_ins_fnmsubs_:
.asciz "fnmsubs. f%d, f%d, f%d, f%d" #0x1328

asm_ins_fres:
.asciz "fres f%d, f%d" #0x1348
asm_ins_fres_:
.asciz "fres. f%d, f%d" #0x1368

asm_ins_frsp:
.asciz "frsp f%d, f%d" #0x1388
asm_ins_frsp_:
.asciz "frsp. f%d, f%d" #0x13A8

asm_ins_frsqrte:
.asciz "frsqrte f%d, f%d" #0x13C8
asm_ins_frsqrte_:
.asciz "frsqrte. f%d, f%d" #0x13E8

asm_ins_fsel:
.asciz "fsel f%d, f%d, f%d, f%d" #0x1408
asm_ins_fsel_:
.asciz "fsel. f%d, f%d, f%d, f%d" #0x1428

asm_ins_fsub:
.asciz "fsub f%d, f%d, f%d" #0x1448
asm_ins_fsub_:
.asciz "fsub. f%d, f%d, f%d" #0x1468

asm_ins_fsubs:
.asciz "fsubs f%d, f%d, f%d" #0x1488
asm_ins_fsubs_:
.asciz "fsubs. f%d, f%d, f%d" #0x14A8

asm_ins_icbi:
.asciz "icbi r%d, r%d" #0x14C8

asm_ins_isync:
.asciz "isync" #0x14E8

asm_ins_lbz:
.asciz "lbz r%d, 0x%X (r%d)"

asm_ins_lbzu:
.asciz "lbzu r%d, 0x%X (r%d)" #0x1518

asm_ins_lbzux:
.asciz "lbzux r%d, r%d, r%d" #0x1538

asm_ins_lbzx:
.asciz "lbzx r%d, r%d, r%d" #0x1558

asm_ins_lfd:
.asciz "lfd f%d, 0x%X (r%d)" #0x1578

asm_ins_lfdu:
.asciz "lfdu f%d, 0x%X (r%d)" #0x1598

asm_ins_lfdux:
.asciz "lfdux f%d, r%d, r%d" #0x15B8

asm_ins_lfdx:
.asciz "lfdx f%d, r%d, r%d" #0x15D8

asm_ins_lfs:
.asciz "lfs f%d, 0x%X (r%d)" #0x15F8

asm_ins_lfsu:
.asciz "lfsu f%d, 0x%X (r%d)" #0x1618

asm_ins_lfsux:
.asciz "lfsux f%d, r%d, r%d" #0x1638

asm_ins_lfsx:
.asciz "lfsx f%d, r%d, r%d" #0x1658

asm_ins_lha:
.asciz "lha r%d, 0x%X (r%d)" #0x1678

asm_ins_lhau:
.asciz "lhau r%d, 0x%X (r%d)" #0x1698

asm_ins_lhaux:
.asciz "lhaux r%d, r%d, r%d" #0x16B8

asm_ins_lhax:
.asciz "lhax r%d, r%d, r%d" #0x16D8

asm_ins_lhbrx:
.asciz "lhbrx r%d, r%d, r%d" #0x16F8

asm_ins_lhz:
.asciz "lhz r%d, 0x%X (r%d)" #0x1718

asm_ins_lhzu:
.asciz "lhzu r%d, 0x%X (r%d)" #0x1738

asm_ins_lhzux:
.asciz "lhzux r%d, r%d, r%d" #0x1758

asm_ins_lhzx:
.asciz "lhzx r%d, r%d, r%d" #0x1778

asm_ins_li: #Simplified mnemonic for addi rX, r0, 0xXXXX
.asciz "li r%d, 0x%X"
asm_ins_liDEC: #Simplified mnemonic for addi rX, r0, XXXX
.asciz "li r%d, %d"

asm_ins_lis: #Simplified mnemonic for addis rX, r0, 0xXXXX
.asciz "lis r%d, 0x%X"
asm_ins_lisDEC: #Simplified mnemonic for addis rX, r0, 0xXXXX
.asciz "lis r%d, %u"

asm_ins_lmw:
.asciz "lmw r%d, 0x%X (r%d)" #0x1798

asm_ins_lswi:
.asciz "lswi r%d, r%d, %d" #0x17B8

asm_ins_lswx:
.asciz "lswx r%d, r%d, r%d" #0x17D8

asm_ins_lwarx:
.asciz "lwarx r%d, r%d, r%d" #0x17F8

asm_ins_lwbrx:
.asciz "lwbrx r%d, r%d, r%d" #0x1818

asm_ins_lwz:
.asciz "lwz r%d, 0x%X (r%d)" #0x1838

asm_ins_lwzu:
.asciz "lwzu r%d, 0x%X (r%d)" #0x1858

asm_ins_lwzux:
.asciz "lwzux r%d, r%d, r%d" #0x1878

asm_ins_lwzx:
.asciz "lwzx r%d, r%d, r%d" #0x1898

asm_ins_mcrf:
.asciz "mcrf cr%d, cr%d" #0x18B8

asm_ins_mcrfs:
.asciz "mcrfs cr%d, cr%d" #0x18D8

asm_ins_mcrxr:
.asciz "mcrxr cr%d" #0x18F8

asm_ins_mfcr:
.asciz "mfcr r%d" #0x1918

asm_ins_mffs:
.asciz "mffs f%d" #0x1938
asm_ins_mffs_:
.asciz "mffs. f%d" #0x1958

asm_ins_mfmsr:
.asciz "mfmsr r%d" #0x1978

asm_ins_mfspr:
.asciz "mfspr r%d, %d" #0x1998

asm_ins_mfsr:
.asciz "mfsr r%d, %d" #0x19B8

asm_ins_mfsrin:
.asciz "mfsrin r%d, r%d" #0x19D8

asm_ins_mftb:
.asciz "mftb r%d, %d" #0x19F8
asm_ins_mftb_simp: #Simplified mnemonic for mftb rD, 268
.asciz "mftb r%d"
asm_ins_mftbl: #Same thing as above
.asciz "mftbl r%d"
asm_ins_mftbu: #Simplified mnemonic for mftb rD, 269
.asciz "mftbu r%d"

asm_ins_mr: #Simplified mnemonic for or rX, rY, rY
.asciz "mr r%d, r%d"

asm_ins_mr_: #Simplified mnemonic for or. rX, rY, Y
.asciz "mr. r%d, r%d"

asm_ins_mtcrf:
.asciz "mtcrf 0x%X, r%d" #0x1A18
asm_ins_mtcr: #Simplified mnemonic for mtcrfs 0xFF, rS
.asciz "mtcr r%d"

asm_ins_mtfsb0:
.asciz "mtfsb0 %d" #0x1A38
asm_ins_mtfsb0_:
.asciz "mtfsb0. %d" #0x1A58

asm_ins_mtfsb1:
.asciz "mtfsb1 %d" #0x1A78
asm_ins_mtfsb1_:
.asciz "mtfsb1. %d" #0x1A98

asm_ins_mtfsf:
.asciz "mtfsf 0x%X, f%d" #0x1AB8
asm_ins_mtfsf_:
.asciz "mtfsf. 0x%X, f%d" #0x1AD8

asm_ins_mtfsfi:
.asciz "mtfsfi cr%d, %d" #0x1AF8
asm_ins_mtfsfi_:
.asciz "mtfsfi. cr%d, %d" #0x1B18

asm_ins_mtmsr:
.asciz "mtmsr r%d" #0x1B38

asm_ins_mtspr:
.asciz "mtspr %d, r%d" #0x1B58

asm_ins_mtsr:
.asciz "mtsr %d, r%d" #0x1B78

asm_ins_mtsrin:
.asciz "mtsrin r%d, r%d" #0x1B98

asm_ins_mulhw:
.asciz "mulhw r%d, r%d, r%d" #0x1BB8
asm_ins_mulhw_:
.asciz "mulhw. r%d, r%d, r%d" #0x1BD8

asm_ins_mulhwu:
.asciz "mulhwu r%d, r%d, r%d" #0x1BF8
asm_ins_mulhwu_:
.asciz "mulhwu. r%d, r%d, r%d" #0x1C18

asm_ins_mulli:
.asciz "mulli r%d, r%d, 0x%X" #0x1C38
asm_ins_mulliDEC:
.asciz "mulli r%d, r%d, %d" #0x1C38

asm_ins_mullw:
.asciz "mullw r%d, r%d, r%d" #0x1C58
asm_ins_mullw_:
.asciz "mullw. r%d, r%d, r%d" #0x1C78
asm_ins_mullwo:
.asciz "mullwo r%d, r%d, r%d" #0x1C98
asm_ins_mullwo_:
.asciz "mullwo. r%d, r%d, r%d" #0x1CB8

asm_ins_nand:
.asciz "nand r%d, r%d, r%d" #0x1CD8
asm_ins_nand_:
.asciz "nand. r%d, r%d, r%d" #0x1CF8

asm_ins_neg:
.asciz "neg r%d, r%d" #0x1D18
asm_ins_neg_:
.asciz "neg. r%d, r%d" #0x1D38
asm_ins_nego:
.asciz "nego r%d, r%d" #0x1D58
asm_ins_nego_:
.asciz "nego. r%d, r%d" #0x1D78

asm_ins_nop: #Simplified mnemonic for ori r0, r0, 0x0000
.asciz "nop"

asm_ins_nor:
.asciz "nor r%d, r%d, r%d" #0x1D98
asm_ins_nor_:
.asciz "nor. r%d, r%d, r%d" #0x1DB8

asm_ins_not: #Simplified mnemonic for nor rX, rY, Y
.asciz "not r%d, r%d"
asm_ins_not_: #Simplified mnemonic for nor. rX, rY, Y
.asciz "not. r%d, r%d"

asm_ins_or:
.asciz "or r%d, r%d, r%d" #0x1DD8
asm_ins_or_:
.asciz "or. r%d, r%d, r%d" #0x1DF8

asm_ins_orc:
.asciz "orc r%d, r%d, r%d" #0x1E18
asm_ins_orc_:
.asciz "orc. r%d, r%d, r%d" #0x1E38

asm_ins_ori:
.asciz "ori r%d, r%d, 0x%X" #0x1E58

asm_ins_oris:
.asciz "oris r%d, r%d, 0x%X" #0x1E78

asm_ins_psq_l:
.asciz "psq_l f%d, 0x%X (r%d), %d, %d" #0x1E98

asm_ins_psq_lu:
.asciz "psq_lu f%d, 0x%X (r%d), %d, %d" #0x1ED8

asm_ins_psq_lux:
.asciz "psq_lux f%d, r%d, r%d, %d, %d" #0x1F18

asm_ins_psq_lx:
.asciz "psq_lx f%d, r%d, r%d, %d, %d" #0x1F58

asm_ins_psq_st:
.asciz "psq_st f%d, 0x%X (r%d), %d, %d" #0x1F98

asm_ins_psq_stu:
.asciz "psq_stu f%d, 0x%X (r%d), %d, %d" #0x1FD8

asm_ins_psq_stux:
.asciz "psq_stux f%d, r%d, r%d, %d, %d" #0x2018

asm_ins_psq_stx:
.asciz "psq_stx f%d, r%d, r%d, %d, %d" #0x2058

asm_ins_ps_abs:
.asciz "ps_abs f%d, f%d" #0x2098;
asm_ins_ps_abs_:
.asciz "ps_abs. f%d, f%d" #0x20B8

asm_ins_ps_add:
.asciz "ps_add f%d, f%d, f%d" #0x20D8
asm_ins_ps_add_:
.asciz "ps_add. f%d, f%d, f%d" #0x20F8

asm_ins_ps_cmpo0:
.asciz "ps_cmpo0 cr%d, f%d, f%d" #0x2118

asm_ins_ps_cmpo1:
.asciz "ps_cmpo1 cr%d, f%d, f%d" #0x2138

asm_ins_ps_cmpu0:
.asciz "ps_cmpu0 cr%d, f%d, f%d" #0x2158

asm_ins_ps_cmpu1:
.asciz "ps_cmpu1 cr%d, f%d, f%d" #0x2178

asm_ins_ps_div:
.asciz "ps_div f%d, f%d, f%d" #0x2198
asm_ins_ps_div_:
.asciz "ps_div. f%d, f%d, f%d" #0x21B8

asm_ins_ps_madd:
.asciz "ps_madd f%d, f%d, f%d, f%d" #0x21D8
asm_ins_ps_madd_:
.asciz "ps_madd. f%d, f%d, f%d, f%d" #0x21F8

asm_ins_ps_madds0:
.asciz "ps_madds0 f%d, f%d, f%d, f%d" #0x2218
asm_ins_ps_madds0_:
.asciz "ps_madds0. f%d, f%d, f%d, f%d" #0x2238

asm_ins_ps_madds1:
.asciz "ps_madds1 f%d, f%d, f%d, f%d" #0x2258
asm_ins_ps_madds1_:
.asciz "ps_madds1. f%d, f%d, f%d, f%d" #0x2278

asm_ins_ps_merge00:
.asciz "ps_merge00 f%d, f%d, f%d" #0x2298
asm_ins_ps_merge00_:
.asciz "ps_merge00. f%d, f%d, f%d" #0x22B8

asm_ins_ps_merge01:
.asciz "ps_merge01 f%d, f%d, f%d" #0x22D8
asm_ins_ps_merge01_:
.asciz "ps_merge01. f%d, f%d, f%d" #0x22F8

asm_ins_ps_merge10:
.asciz "ps_merge10 f%d, f%d, f%d" #0x2318
asm_ins_ps_merge10_:
.asciz "ps_merge10. f%d, f%d, f%d" #0x2338

asm_ins_ps_merge11:
.asciz "ps_merge11 f%d, f%d, f%d" #0x2358
asm_ins_ps_merge11_:
.asciz "ps_merge11. f%d, f%d, f%d" #0x2378

asm_ins_ps_mr:
.asciz "ps_mr f%d, f%d" #0x2398
asm_ins_ps_mr_:
.asciz "ps_mr. f%d, f%d" #0x23B8

asm_ins_ps_msub:
.asciz "ps_msub f%d, f%d, f%d, f%d" #0x23D8
asm_ins_ps_msub_:
.asciz "ps_msub. f%d, f%d, f%d, f%d" #0x23F8

#NOTE ps_mulX, ps_muls0X, and ps_muls1X need spaces removed. All other strings can be processed thru sscanf without needing space removal. For whatever unknown reason, this doesn't apply to the following 3 instruction types. Therefore remove the spaces.
asm_ins_ps_mul:
.asciz "ps_mul f%d, f%d, f%d" #0x2418
asm_ins_ps_mul_:
.asciz "ps_mul. f%d, f%d, f%d" #0x2438

asm_ins_ps_muls0:
.asciz "ps_muls0 f%d, f%d, f%d" #0x2458
asm_ins_ps_muls0_:
.asciz "ps_muls0. f%d, f%d, f%d" #0x2478

asm_ins_ps_muls1:
.asciz "ps_muls1 f%d, f%d, f%d" #0x2498
asm_ins_ps_muls1_:
.asciz "ps_muls1. f%d, f%d, f%d" #0x24B8

asm_ins_ps_nabs:
.asciz "ps_nabs f%d, f%d" #0x24D8
asm_ins_ps_nabs_:
.asciz "ps_nabs. f%d, f%d" #0x24F8

asm_ins_ps_neg:
.asciz "ps_neg f%d, f%d" #0x2518
asm_ins_ps_neg_:
.asciz "ps_neg. f%d, f%d" #0x2538

asm_ins_ps_nmadd:
.asciz "ps_nmadd f%d, f%d, f%d, f%d" #0x2558
asm_ins_ps_nmadd_:
.asciz "ps_nmadd. f%d, f%d, f%d, f%d" #0x2578

asm_ins_ps_nmsub:
.asciz "ps_nmsub f%d, f%d, f%d, f%d" #0x2598
asm_ins_ps_nmsub_:
.asciz "ps_nmsub. f%d, f%d, f%d, f%d" #0x25B8

asm_ins_ps_res:
.asciz "ps_res f%d, f%d" #0x25D8
asm_ins_ps_res_:
.asciz "ps_res. f%d, f%d" #0x25F8

asm_ins_ps_rsqrte:
.asciz "ps_rsqrte f%d, f%d" #0x2618
asm_ins_ps_rsqrte_:
.asciz "ps_rsqrte. f%d, f%d" #0x2638

asm_ins_ps_sel:
.asciz "ps_sel f%d, f%d, f%d, f%d" #0x2658
asm_ins_ps_sel_:
.asciz "ps_sel. f%d, f%d, f%d, f%d" #0x2678

asm_ins_ps_sub:
.asciz "ps_sub f%d, f%d, f%d" #0x2698
asm_ins_ps_sub_:
.asciz "ps_sub. f%d, f%d, f%d" #0x26B8

asm_ins_ps_sum0:
.asciz "ps_sum0 f%d, f%d, f%d, f%d" #0x26D8
asm_ins_ps_sum0_:
.asciz "ps_sum0. f%d, f%d, f%d, f%d" #0x26F8

asm_ins_ps_sum1:
.asciz "ps_sum1 f%d, f%d, f%d, f%d" #0x2718
asm_ins_ps_sum1_:
.asciz "ps_sum1. f%d, f%d, f%d, f%d" #0x2738

asm_ins_rfi:
.asciz "rfi" #0x2758

asm_ins_rlwimi:
.asciz "rlwimi r%d, r%d, %d, %d, %d" #0x2768;
asm_ins_rlwimi_:
.asciz "rlwimi. r%d, r%d, %d, %d, %d" #0x2788

asm_ins_rlwinm:
.asciz "rlwinm r%d, r%d, %d, %d, %d" #0x27A8
asm_ins_rlwinm_:
.asciz "rlwinm. r%d, r%d, %d, %d, %d" #0x27C8

asm_ins_rlwnm:
.asciz "rlwnm r%d, r%d, r%d, %d, %d" #0x27E8
asm_ins_rlwnm_:
.asciz "rlwnm. r%d, r%d, r%d, %d, %d" #0x2808

asm_ins_sc:
.asciz "sc" #0x2828

asm_ins_slw:
.asciz "slw r%d, r%d, r%d" #0x2838;
asm_ins_slw_:
.asciz "slw. r%d, r%d, r%d" #0x2858

asm_ins_sraw:
.asciz "sraw r%d, r%d, r%d" #0x2878
asm_ins_sraw_:
.asciz "sraw. r%d, r%d, r%d" #0x2898

asm_ins_srawi:
.asciz "srawi r%d, r%d, %d" #0x28B8
asm_ins_srawi_:
.asciz "srawi. r%d, r%d, %d" #0x28D8

asm_ins_srw:
.asciz "srw r%d, r%d, r%d" #0x28F8
asm_ins_srw_:
.asciz "srw. r%d, r%d, r%d" #0x2918

asm_ins_stb:
.asciz "stb r%d, 0x%X (r%d)" #0x2938

asm_ins_stbu:
.asciz "stbu r%d, 0x%X (r%d)" #0x2958

asm_ins_stbux:
.asciz "stbux r%d, r%d, r%d" #0x2978

asm_ins_stbx:
.asciz "stbx r%d, r%d, r%d" #0x2998

asm_ins_stfd:
.asciz "stfd f%d, 0x%X (r%d)" #0x29B8

asm_ins_stfdu:
.asciz "stfdu f%d, 0x%X (r%d)" #0x29D8

asm_ins_stfdux:
.asciz "stfdux f%d, r%d, r%d" #0x29F8

asm_ins_stfdx:
.asciz "stfdx f%d, r%d, r%d" #0x2A18

asm_ins_stfiwx:
.asciz "stfiwx f%d, r%d, r%d" #0x2A38

asm_ins_stfs:
.asciz "stfs f%d, 0x%X (r%d)" #0x2A58

asm_ins_stfsu:
.asciz "stfsu f%d, 0x%X (r%d)" #0x2A78

asm_ins_stfsux:
.asciz "stfsux f%d, r%d, r%d" #0x2A98

asm_ins_stfsx:
.asciz "stfsx f%d, r%d, r%d" #0x2AB8

asm_ins_sth:
.asciz "sth r%d, 0x%X (r%d)" #0x2AD8

asm_ins_sthbrx:
.asciz "sthbrx r%d, r%d, r%d" #0x2AF8

asm_ins_sthu:
.asciz "sthu r%d, 0x%X (r%d)" #0x2B18

asm_ins_sthux:
.asciz "sthux r%d, r%d, r%d" #0x2B38

asm_ins_sthx:
.asciz "sthx r%d, r%d, r%d" #0x2B58

asm_ins_stmw:
.asciz "stmw r%d, 0x%X (r%d)" #0x2B78

asm_ins_stswi:
.asciz "stswi r%d, r%d, %d" #0x2B98

asm_ins_stswx:
.asciz "stswx r%d, r%d, r%d" #0x2BB8

asm_ins_stw:
.asciz "stw r%d, 0x%X (r%d)" #0x2BD8

asm_ins_stwbrx:
.asciz "stwbrx r%d, r%d, r%d" #0x2BF8

asm_ins_stwcx_:
.asciz "stwcx. r%d, r%d, r%d" #0x2C18

asm_ins_stwu:
.asciz "stwu r%d, 0x%X (r%d)" #0x2C38

asm_ins_stwux:
.asciz "stwux r%d, r%d, r%d" #0x2C58

asm_ins_stwx:
.asciz "stwx r%d, r%d, r%d" #0x2C78

asm_ins_subf:
.asciz "subf r%d, r%d, r%d"
asm_ins_subf_:
.asciz "subf. r%d, r%d, r%d"
asm_ins_subfo:
.asciz "subfo r%d, r%d, r%d"
asm_ins_subfo_:
.asciz "subfo. r%d, r%d, r%d"

#Simplified mnemonics for subfX rD, rB, rA
asm_ins_sub:
.asciz "sub r%d, r%d, r%d"
asm_ins_sub_:
.asciz "sub. r%d, r%d, r%d"
asm_ins_subo:
.asciz "subo r%d, r%d, r%d"
asm_ins_subo_:
.asciz "subo. r%d, r%d, r%d"

asm_ins_subfc:
.asciz "subfc r%d, r%d, r%d"
asm_ins_subfc_:
.asciz "subfc. r%d, r%d, r%d"
asm_ins_subfco:
.asciz "subfco r%d, r%d, r%d"
asm_ins_subfco_:
.asciz "subfco. r%d, r%d, r%d"

#Simplified mnemonics for subfcX rD, rB, rA
asm_ins_subc:
.asciz "subc r%d, r%d, r%d"
asm_ins_subc_:
.asciz "subc. r%d, r%d, r%d"
asm_ins_subco:
.asciz "subco r%d, r%d, r%d"
asm_ins_subco_:
.asciz "subco. r%d, r%d, r%d"

asm_ins_subfe:
.asciz "subfe r%d, r%d, r%d"
asm_ins_subfe_:
.asciz "subfe. r%d, r%d, r%d"
asm_ins_subfeo:
.asciz "subfeo r%d, r%d, r%d"
asm_ins_subfeo_:
.asciz "subfeo. r%d, r%d, r%d"

asm_ins_subfic:
.asciz "subfic r%d, r%d, 0x%X"
asm_ins_subficDEC:
.asciz "subfic r%d, r%d, %d"

asm_ins_subfme:
.asciz "subfme r%d, r%d"
asm_ins_subfme_:
.asciz "subfme. r%d, r%d"
asm_ins_subfmeo:
.asciz "subfmeo r%d, r%d"
asm_ins_subfmeo_:
.asciz "subfmeo. r%d, r%d"

asm_ins_subfze:
.asciz "subfze r%d, r%d"
asm_ins_subfze_:
.asciz "subfze. r%d, r%d"
asm_ins_subfzeo:
.asciz "subfzeo r%d, r%d"
asm_ins_subfzeo_:
.asciz "subfzeo. r%d, r%d"

asm_ins_sync:
.asciz "sync"

asm_ins_tlbie:
.asciz "tlbie r%d"

asm_ins_tlbsync:
.asciz "tlbsync"

asm_ins_trap: #Simplified mnemonic for tw 31, rA, rB
.asciz "trap"

asm_ins_tw:
.asciz "tw %d, r%d, r%d"

asm_ins_twi:
.asciz "twi %d, r%d, 0x%X"
asm_ins_twiDEC:
.asciz "twi %d, r%d, %d"

asm_ins_xor:
.asciz "xor r%d, r%d, r%d"
asm_ins_xor_:
.asciz "xor. r%d, r%d, r%d"

asm_ins_xori:
.asciz "xori r%d, r%d, 0x%X"

asm_ins_xoris:
.asciz "xoris r%d, r%d, 0x%X"

#Following are mfspr simplified mnemonics, rather have these in a group than placed in alphabetically
asm_ins_mfxer:
.asciz "mfxer r%d"
asm_ins_mflr:
.asciz "mflr r%d"
asm_ins_mfctr:
.asciz "mfctr r%d"
asm_ins_mfdsisr:
.asciz "mfdsisr r%d"
asm_ins_mfdar:
.asciz "mfdar r%d"
asm_ins_mfdec:
.asciz "mfdec r%d"
asm_ins_mfsdr1:
.asciz "mfsdr1 r%d"
asm_ins_mfsrr0:
.asciz "mfsrr0 r%d"
asm_ins_mfsrr1:
.asciz "mfsrr1 r%d"
asm_ins_mfsprg0:
.asciz "mfsprg0 r%d"
asm_ins_mfsprg1:
.asciz "mfsprg1 r%d"
asm_ins_mfsprg2:
.asciz "mfsprg2 r%d"
asm_ins_mfsprg3:
.asciz "mfsprg3 r%d"
asm_ins_mfear:
.asciz "mfear r%d"
asm_ins_mfpvr:
.asciz "mfpvr r%d"
asm_ins_mfibat0u:
.asciz "mfibat0u r%d"
asm_ins_mfibat0l:
.asciz "mfibat0l r%d"
asm_ins_mfibat1u:
.asciz "mfibat1u r%d"
asm_ins_mfibat1l:
.asciz "mfibat1l r%d"
asm_ins_mfibat2u:
.asciz "mfibat2u r%d"
asm_ins_mfibat2l:
.asciz "mfibat2l r%d"
asm_ins_mfibat3u:
.asciz "mfibat3u r%d"
asm_ins_mfibat3l:
.asciz "mfibat3l r%d"
asm_ins_mfibat4u:
.asciz "mfibat4u r%d"
asm_ins_mfibat4l:
.asciz "mfibat4l r%d"
asm_ins_mfibat5u:
.asciz "mfibat5u r%d"
asm_ins_mfibat5l:
.asciz "mfibat5l r%d"
asm_ins_mfibat6u:
.asciz "mfibat6u r%d"
asm_ins_mfibat6l:
.asciz "mfibat6l r%d"
asm_ins_mfibat7u:
.asciz "mfibat7u r%d"
asm_ins_mfibat7l:
.asciz "mfibat7l r%d"
asm_ins_mfdbat0u:
.asciz "mfdbat0u r%d"
asm_ins_mfdbat0l:
.asciz "mfdbat0l r%d"
asm_ins_mfdbat1u:
.asciz "mfdbat1u r%d"
asm_ins_mfdbat1l:
.asciz "mfdbat1l r%d"
asm_ins_mfdbat2u:
.asciz "mfdbat2u r%d"
asm_ins_mfdbat2l:
.asciz "mfdbat2l r%d"
asm_ins_mfdbat3u:
.asciz "mfdbat3u r%d"
asm_ins_mfdbat3l:
.asciz "mfdbat3l r%d"
asm_ins_mfdbat4u:
.asciz "mfdbat4u r%d"
asm_ins_mfdbat4l:
.asciz "mfdbat4l r%d"
asm_ins_mfdbat5u:
.asciz "mfdbat5u r%d"
asm_ins_mfdbat5l:
.asciz "mfdbat5l r%d"
asm_ins_mfdbat6u:
.asciz "mfdbat6u r%d"
asm_ins_mfdbat6l:
.asciz "mfdbat6l r%d"
asm_ins_mfdbat7u:
.asciz "mfdbat7u r%d"
asm_ins_mfdbat7l:
.asciz "mfdbat7l r%d"
asm_ins_mfgqr0:
.asciz "mfgqr0 r%d"
asm_ins_mfgqr1:
.asciz "mfgqr1 r%d"
asm_ins_mfgqr2:
.asciz "mfgqr2 r%d"
asm_ins_mfgqr3:
.asciz "mfgqr3 r%d"
asm_ins_mfgqr4:
.asciz "mfgqr4 r%d"
asm_ins_mfgqr5:
.asciz "mfgqr5 r%d"
asm_ins_mfgqr6:
.asciz "mfgqr6 r%d"
asm_ins_mfgqr7:
.asciz "mfgqr7 r%d"
asm_ins_mfhid2:
.asciz "mfhid2 r%d"
asm_ins_mfwpar:
.asciz "mfwpar r%d"
asm_ins_mfdma_u:
.asciz "mfdma_u r%d"
asm_ins_mfdma_l:
.asciz "mfdma_l r%d"
asm_ins_mfcidh:
.asciz "mfcidh r%d" #Special Broadway Chip IDs supported
asm_ins_mfcidm:
.asciz "mfcidm r%d" #Special Broadway Chip IDs supported
asm_ins_mfcidl:
.asciz "mfcidl r%d" #Special Broadway Chip IDs supported
asm_ins_mfummcr0:
.asciz "mfummcr0 r%d"
asm_ins_mfupmc1:
.asciz "mfupmc1 r%d"
asm_ins_mfupmc2:
.asciz "mfupmc2 r%d"
asm_ins_mfusia:
.asciz "mfusia r%d"
asm_ins_mfummcr1:
.asciz "mfummcr1 r%d"
asm_ins_mfupmc3:
.asciz "mfupmc3 r%d"
asm_ins_mfupmc4:
.asciz "mfupmc4 r%d"
asm_ins_mfusda:
.asciz "mfusda r%d"
asm_ins_mfmmcr0:
.asciz "mfmmcr0 r%d"
asm_ins_mfpmc1:
.asciz "mfpmc1 r%d"
asm_ins_mfpmc2:
.asciz "mfpmc2 r%d"
asm_ins_mfsia:
.asciz "mfsia r%d"
asm_ins_mfmmcr1:
.asciz "mfmmcr1 r%d"
asm_ins_mfpmc3:
.asciz "mfpmc3 r%d"
asm_ins_mfpmc4:
.asciz "mfpmc4 r%d"
asm_ins_mfsda:
.asciz "mfsda r%d"
asm_ins_mfhid0:
.asciz "mfhid0 r%d"
asm_ins_mfhid1:
.asciz "mfhid1 r%d"
asm_ins_mfiabr:
.asciz "mfiabr r%d"
asm_ins_mfhid4:
.asciz "mfhid4 r%d"
asm_ins_mftdcl:
.asciz "mftdcl r%d"
asm_ins_mfdabr:
.asciz "mfdabr r%d"
asm_ins_mfl2cr:
.asciz "mfl2cr r%d"
asm_ins_mftdch:
.asciz "mftdch r%d"
asm_ins_mfictc:
.asciz "mfictc r%d"
asm_ins_mfthrm1:
.asciz "mfthrm1 r%d"
asm_ins_mfthrm2:
.asciz "mfthrm2 r%d"
asm_ins_mfthrm3:
.asciz "mfthrm3 r%d"

#Following are mtspr simplified mnemonics, rather have these in a group than placed in alphabetically
asm_ins_mtxer:
.asciz "mtxer r%d"
asm_ins_mtlr:
.asciz "mtlr r%d"
asm_ins_mtctr:
.asciz "mtctr r%d"
asm_ins_mtdsisr:
.asciz "mtdsisr r%d"
asm_ins_mtdar:
.asciz "mtdar r%d"
asm_ins_mtdec:
.asciz "mtdec r%d"
asm_ins_mtsdr1:
.asciz "mtsdr1 r%d"
asm_ins_mtsrr0:
.asciz "mtsrr0 r%d"
asm_ins_mtsrr1:
.asciz "mtsrr1 r%d"
asm_ins_mtsprg0:
.asciz "mtsprg0 r%d"
asm_ins_mtsprg1:
.asciz "mtsprg1 r%d"
asm_ins_mtsprg2:
.asciz "mtsprg2 r%d"
asm_ins_mtsprg3:
.asciz "mtsprg3 r%d"
asm_ins_mtear:
.asciz "mtear r%d"
asm_ins_mttbl:
.asciz "mttbl r%d"
asm_ins_mttbu:
.asciz "mttbu r%d"
asm_ins_mtibat0u:
.asciz "mtibat0u r%d"
asm_ins_mtibat0l:
.asciz "mtibat0l r%d"
asm_ins_mtibat1u:
.asciz "mtibat1u r%d"
asm_ins_mtibat1l:
.asciz "mtibat1l r%d"
asm_ins_mtibat2u:
.asciz "mtibat2u r%d"
asm_ins_mtibat2l:
.asciz "mtibat2l r%d"
asm_ins_mtibat3u:
.asciz "mtibat3u r%d"
asm_ins_mtibat3l:
.asciz "mtibat3l r%d"
asm_ins_mtibat4u:
.asciz "mtibat4u r%d"
asm_ins_mtibat4l:
.asciz "mtibat4l r%d"
asm_ins_mtibat5u:
.asciz "mtibat5u r%d"
asm_ins_mtibat5l:
.asciz "mtibat5l r%d"
asm_ins_mtibat6u:
.asciz "mtibat6u r%d"
asm_ins_mtibat6l:
.asciz "mtibat6l r%d"
asm_ins_mtibat7u:
.asciz "mtibat7u r%d"
asm_ins_mtibat7l:
.asciz "mtibat7l r%d"
asm_ins_mtdbat0u:
.asciz "mtdbat0u r%d"
asm_ins_mtdbat0l:
.asciz "mtdbat0l r%d"
asm_ins_mtdbat1u:
.asciz "mtdbat1u r%d"
asm_ins_mtdbat1l:
.asciz "mtdbat1l r%d"
asm_ins_mtdbat2u:
.asciz "mtdbat2u r%d"
asm_ins_mtdbat2l:
.asciz "mtdbat2l r%d"
asm_ins_mtdbat3u:
.asciz "mtdbat3u r%d"
asm_ins_mtdbat3l:
.asciz "mtdbat3l r%d"
asm_ins_mtdbat4u:
.asciz "mtdbat4u r%d"
asm_ins_mtdbat4l:
.asciz "mtdbat4l r%d"
asm_ins_mtdbat5u:
.asciz "mtdbat5u r%d"
asm_ins_mtdbat5l:
.asciz "mtdbat5l r%d"
asm_ins_mtdbat6u:
.asciz "mtdbat6u r%d"
asm_ins_mtdbat6l:
.asciz "mtdbat6l r%d"
asm_ins_mtdbat7u:
.asciz "mtdbat7u r%d"
asm_ins_mtdbat7l:
.asciz "mtdbat7l r%d"
asm_ins_mtgqr0:
.asciz "mtgqr0 r%d"
asm_ins_mtgqr1:
.asciz "mtgqr1 r%d"
asm_ins_mtgqr2:
.asciz "mtgqr2 r%d"
asm_ins_mtgqr3:
.asciz "mtgqr3 r%d"
asm_ins_mtgqr4:
.asciz "mtgqr4 r%d"
asm_ins_mtgqr5:
.asciz "mtgqr5 r%d"
asm_ins_mtgqr6:
.asciz "mtgqr6 r%d"
asm_ins_mtgqr7:
.asciz "mtgqr7 r%d"
asm_ins_mthid2:
.asciz "mthid2 r%d"
asm_ins_mtwpar:
.asciz "mtwpar r%d"
asm_ins_mtdma_u:
.asciz "mtdma_u r%d"
asm_ins_mtdma_l:
.asciz "mtdma_l r%d"
asm_ins_mtummcr0:
.asciz "mtummcr0 r%d"
asm_ins_mtupmc1:
.asciz "mtupmc1 r%d"
asm_ins_mtupmc2:
.asciz "mtupmc2 r%d"
asm_ins_mtusia:
.asciz "mtusia r%d"
asm_ins_mtummcr1:
.asciz "mtummcr1 r%d"
asm_ins_mtupmc3:
.asciz "mtupmc3 r%d"
asm_ins_mtupmc4:
.asciz "mtupmc4 r%d"
asm_ins_mtusda:
.asciz "mtusda r%d"
asm_ins_mtmmcr0:
.asciz "mtmmcr0 r%d"
asm_ins_mtpmc1:
.asciz "mtpmc1 r%d"
asm_ins_mtpmc2:
.asciz "mtpmc2 r%d"
asm_ins_mtsia:
.asciz "mtsia r%d"
asm_ins_mtmmcr1:
.asciz "mtmmcr1 r%d"
asm_ins_mtpmc3:
.asciz "mtpmc3 r%d"
asm_ins_mtpmc4:
.asciz "mtpmc4 r%d"
asm_ins_mtsda:
.asciz "mtsda r%d"
asm_ins_mthid0:
.asciz "mthid0 r%d"
asm_ins_mthid1:
.asciz "mthid1 r%d"
asm_ins_mtiabr:
.asciz "mtiabr r%d"
asm_ins_mthid4:
.asciz "mthid4 r%d"
asm_ins_mtdabr:
.asciz "mtdabr r%d"
asm_ins_mtl2cr:
.asciz "mtl2cr r%d"
asm_ins_mtictc:
.asciz "mtictc r%d"
asm_ins_mtthrm1:
.asciz "mtthrm1 r%d"
asm_ins_mtthrm2:
.asciz "mtthrm2 r%d"
asm_ins_mtthrm3:
.asciz "mtthrm3 r%d"

#Following are CR simplified mnemonics
asm_ins_crset:
.asciz "crset %d" #creqv d, d, d
asm_ins_crnot:
.asciz "crnot %d, %d" #crnor d, a, a
asm_ins_crmove:
.asciz "crmove %d, %d" #cror d, a, a
asm_ins_crclr:
.asciz "crclr %d" #crxor d, d, d

#Following are SOME rlwinmX simplified mnemonics
asm_ins_slwi: #Simplified mnemonic for rlwinm rX, rY, b, 0, 31-b
.asciz "slwi r%d, r%d, %d"
asm_ins_slwi_:
.asciz "slwi. r%d, r%d, %d"
asm_ins_srwi: #Simplified mnemonic for rlwinm rX, rY, 32-b, b, 31
.asciz "srwi r%d, r%d, %d"
asm_ins_srwi_:
.asciz "srwi. r%d, r%d, %d"
asm_ins_clrlwi: #Simplified mnemonic for rlwinm rX, rY, 0, b, 31
.asciz "clrlwi r%d, r%d, %d"
asm_ins_clrlwi_:
.asciz "clrlwi. r%d, r%d, %d"
asm_ins_clrrwi: #Simplified mnemonic for rlwinm rX, rY, 0, 0, 31-b
.asciz "clrrwi r%d, r%d, %d"
asm_ins_clrrwi_:
.asciz "clrrwi. r%d, r%d, %d"
asm_ins_rotlwi: #Simplified mnemonic for rlwinm rX, rY, b, 0, 31
.asciz "rotlwi r%d, r%d, %d"
asm_ins_rotlwi_:
.asciz "rotlwi. r%d, r%d, %d"

#Simplified mnemonic for rlwnmX
asm_ins_rotlw: #Simplified mnemonic for rlwnm rX, rY, rZ, 0, 31
.asciz "rotlw r%d, r%d, r%d"
asm_ins_rotlw_:
.asciz "rotlw. r%d, r%d, r%d"

#Following are all the branch simplified mnemonics
#NOTE some need %u or else the - or + gets picked up with the num and not the string
asm_ins_bdnzf:
.asciz "bdnzf %u, 0x%X"
asm_ins_bdnzf_ll:
.asciz "bdnzf- %u, 0x%X"
asm_ins_bdnzf_ml:
.asciz "bdnzf+ %u, 0x%X"
asm_ins_bdnzfa:
.asciz "bdnzfa %u, 0x%X"
asm_ins_bdnzfa_ll:
.asciz "bdnzfa- %u, 0x%X"
asm_ins_bdnzfa_ml:
.asciz "bdnzfa+ %u, 0x%X"
asm_ins_bdnzfl:
.asciz "bdnzfl %u, 0x%X"
asm_ins_bdnzfl_ll:
.asciz "bdnzfl- %u, 0x%X"
asm_ins_bdnzfl_ml:
.asciz "bdnzfl+ %u, 0x%X"
asm_ins_bdnzfla:
.asciz "bdnzfla %u, 0x%X"
asm_ins_bdnzfla_ll:
.asciz "bdnzfla- %u, 0x%X"
asm_ins_bdnzfla_ml:
.asciz "bdnzfla+ %u, 0x%X"

asm_ins_bdzf:
.asciz "bdzf %u, 0x%X"
asm_ins_bdzf_ll:
.asciz "bdzf- %u, 0x%X"
asm_ins_bdzf_ml:
.asciz "bdzf+ %u, 0x%X"
asm_ins_bdzfa:
.asciz "bdzfa %u, 0x%X"
asm_ins_bdzfa_ll:
.asciz "bdzfa- %u, 0x%X"
asm_ins_bdzfa_ml:
.asciz "bdzfa+ %u, 0x%X"
asm_ins_bdzfl:
.asciz "bdzfl %u, 0x%X"
asm_ins_bdzfl_ll:
.asciz "bdzfl- %u, 0x%X"
asm_ins_bdzfl_ml:
.asciz "bdzfl+ %u, 0x%X"
asm_ins_bdzfla:
.asciz "bdzfla %u, 0x%X"
asm_ins_bdzfla_ll:
.asciz "bdzfla- %u, 0x%X"
asm_ins_bdzfla_ml:
.asciz "bdzfla+ %u, 0x%X"

asm_ins_bge_cr0:
.asciz "bge 0x%X"
asm_ins_bge_ll_cr0:
.asciz "bge- 0x%X"
asm_ins_bge_ml_cr0:
.asciz "bge+ 0x%X"
asm_ins_bgea_cr0:
.asciz "bgea 0x%X"
asm_ins_bgea_ll_cr0:
.asciz "bgea- 0x%X"
asm_ins_bgea_ml_cr0:
.asciz "bgea+ 0x%X"
asm_ins_bgel_cr0:
.asciz "bgel 0x%X"
asm_ins_bgel_ll_cr0:
.asciz "bgel- 0x%X"
asm_ins_bgel_ml_cr0:
.asciz "bgel+ 0x%X"
asm_ins_bgela_cr0:
.asciz "bgela 0x%X"
asm_ins_bgela_ll_cr0:
.asciz "bgela- 0x%X"
asm_ins_bgela_ml_cr0:
.asciz "bgela+ 0x%X"
asm_ins_bge:
.asciz "bge cr%d, 0x%X"
asm_ins_bge_ll:
.asciz "bge- cr%d, 0x%X"
asm_ins_bge_ml:
.asciz "bge+ cr%d, 0x%X"
asm_ins_bgea:
.asciz "bgea cr%d, 0x%X"
asm_ins_bgea_ll:
.asciz "bgea- cr%d, 0x%X"
asm_ins_bgea_ml:
.asciz "bgea+ cr%d, 0x%X"
asm_ins_bgel:
.asciz "bgel cr%d, 0x%X"
asm_ins_bgel_ll:
.asciz "bgel- cr%d, 0x%X"
asm_ins_bgel_ml:
.asciz "bgel+ cr%d, 0x%X"
asm_ins_bgela:
.asciz "bgela cr%d, 0x%X"
asm_ins_bgela_ll:
.asciz "bgela- cr%d, 0x%X"
asm_ins_bgela_ml:
.asciz "bgela+ cr%d, 0x%X"

asm_ins_ble_cr0:
.asciz "ble 0x%X"
asm_ins_ble_ll_cr0:
.asciz "ble- 0x%X"
asm_ins_ble_ml_cr0:
.asciz "ble+ 0x%X"
asm_ins_blea_cr0:
.asciz "blea 0x%X"
asm_ins_blea_ll_cr0:
.asciz "blea- 0x%X"
asm_ins_blea_ml_cr0:
.asciz "blea+ 0x%X"
asm_ins_blel_cr0:
.asciz "blel 0x%X"
asm_ins_blel_ll_cr0:
.asciz "blel- 0x%X"
asm_ins_blel_ml_cr0:
.asciz "blel+ 0x%X"
asm_ins_blela_cr0:
.asciz "blela 0x%X"
asm_ins_blela_ll_cr0:
.asciz "blela- 0x%X"
asm_ins_blela_ml_cr0:
.asciz "blela+ 0x%X"
asm_ins_ble:
.asciz "ble cr%d, 0x%X"
asm_ins_ble_ll:
.asciz "ble- cr%d, 0x%X"
asm_ins_ble_ml:
.asciz "ble+ cr%d, 0x%X"
asm_ins_blea:
.asciz "blea cr%d, 0x%X"
asm_ins_blea_ll:
.asciz "blea- cr%d, 0x%X"
asm_ins_blea_ml:
.asciz "blea+ cr%d, 0x%X"
asm_ins_blel:
.asciz "blel cr%d, 0x%X"
asm_ins_blel_ll:
.asciz "blel- cr%d, 0x%X"
asm_ins_blel_ml:
.asciz "blel+ cr%d, 0x%X"
asm_ins_blela:
.asciz "blela cr%d, 0x%X"
asm_ins_blela_ll:
.asciz "blela- cr%d, 0x%X"
asm_ins_blela_ml:
.asciz "blela+ cr%d, 0x%X"

asm_ins_bne_cr0:
.asciz "bne 0x%X"
asm_ins_bne_ll_cr0:
.asciz "bne- 0x%X"
asm_ins_bne_ml_cr0:
.asciz "bne+ 0x%X"
asm_ins_bnea_cr0:
.asciz "bnea 0x%X"
asm_ins_bnea_ll_cr0:
.asciz "bnea- 0x%X"
asm_ins_bnea_ml_cr0:
.asciz "bnea+ 0x%X"
asm_ins_bnel_cr0:
.asciz "bnel 0x%X"
asm_ins_bnel_ll_cr0:
.asciz "bnel- 0x%X"
asm_ins_bnel_ml_cr0:
.asciz "bnel+ 0x%X"
asm_ins_bnela_cr0:
.asciz "bnela 0x%X"
asm_ins_bnela_ll_cr0:
.asciz "bnela- 0x%X"
asm_ins_bnela_ml_cr0:
.asciz "bnela+ 0x%X"
asm_ins_bne:
.asciz "bne cr%d, 0x%X"
asm_ins_bne_ll:
.asciz "bne- cr%d, 0x%X"
asm_ins_bne_ml:
.asciz "bne+ cr%d, 0x%X"
asm_ins_bnea:
.asciz "bnea cr%d, 0x%X"
asm_ins_bnea_ll:
.asciz "bnea- cr%d, 0x%X"
asm_ins_bnea_ml:
.asciz "bnea+ cr%d, 0x%X"
asm_ins_bnel:
.asciz "bnel cr%d, 0x%X"
asm_ins_bnel_ll:
.asciz "bnel- cr%d, 0x%X"
asm_ins_bnel_ml:
.asciz "bnel+ cr%d, 0x%X"
asm_ins_bnela:
.asciz "bnela cr%d, 0x%X"
asm_ins_bnela_ll:
.asciz "bnela- cr%d, 0x%X"
asm_ins_bnela_ml:
.asciz "bnela+ cr%d, 0x%X"

asm_ins_bns_cr0:
.asciz "bns 0x%X"
asm_ins_bns_ll_cr0:
.asciz "bns- 0x%X"
asm_ins_bns_ml_cr0:
.asciz "bns+ 0x%X"
asm_ins_bnsa_cr0:
.asciz "bnsa 0x%X"
asm_ins_bnsa_ll_cr0:
.asciz "bnsa- 0x%X"
asm_ins_bnsa_ml_cr0:
.asciz "bnsa+ 0x%X"
asm_ins_bnsl_cr0:
.asciz "bnsl 0x%X"
asm_ins_bnsl_ll_cr0:
.asciz "bnsl- 0x%X"
asm_ins_bnsl_ml_cr0:
.asciz "bnsl+ 0x%X"
asm_ins_bnsla_cr0:
.asciz "bnsla 0x%X"
asm_ins_bnsla_ll_cr0:
.asciz "bnsla- 0x%X"
asm_ins_bnsla_ml_cr0:
.asciz "bnsla+ 0x%X"
asm_ins_bns:
.asciz "bns cr%d, 0x%X"
asm_ins_bns_ll:
.asciz "bns- cr%d, 0x%X"
asm_ins_bns_ml:
.asciz "bns+ cr%d, 0x%X"
asm_ins_bnsa:
.asciz "bnsa cr%d, 0x%X"
asm_ins_bnsa_ll:
.asciz "bnsa- cr%d, 0x%X"
asm_ins_bnsa_ml:
.asciz "bnsa+ cr%d, 0x%X"
asm_ins_bnsl:
.asciz "bnsl cr%d, 0x%X"
asm_ins_bnsl_ll:
.asciz "bnsl- cr%d, 0x%X"
asm_ins_bnsl_ml:
.asciz "bnsl+ cr%d, 0x%X"
asm_ins_bnsla:
.asciz "bnsla cr%d, 0x%X"
asm_ins_bnsla_ll:
.asciz "bnsla- cr%d, 0x%X"
asm_ins_bnsla_ml:
.asciz "bnsla+ cr%d, 0x%X"

asm_ins_bdnzt:
.asciz "bdnzt %u, 0x%X"
asm_ins_bdnzt_ll:
.asciz "bdnzt- %u, 0x%X"
asm_ins_bdnzt_ml:
.asciz "bdnzt+ %u, 0x%X"
asm_ins_bdnzta:
.asciz "bdnzta %u, 0x%X"
asm_ins_bdnzta_ll:
.asciz "bdnzta- %u, 0x%X"
asm_ins_bdnzta_ml:
.asciz "bdnzta+ %u, 0x%X"
asm_ins_bdnztl:
.asciz "bdnztl %u, 0x%X"
asm_ins_bdnztl_ll:
.asciz "bdnztl- %u, 0x%X"
asm_ins_bdnztl_ml:
.asciz "bdnztl+ %u, 0x%X"
asm_ins_bdnztla:
.asciz "bdnztla %u, 0x%X"
asm_ins_bdnztla_ll:
.asciz "bdnztla- %u, 0x%X"
asm_ins_bdnztla_ml:
.asciz "bdnztla+ %u, 0x%X"

asm_ins_bdzt:
.asciz "bdzt %u, 0x%X"
asm_ins_bdzt_ll:
.asciz "bdzt- %u, 0x%X"
asm_ins_bdzt_ml:
.asciz "bdzt+ %u, 0x%X"
asm_ins_bdzta:
.asciz "bdzta %u, 0x%X"
asm_ins_bdzta_ll:
.asciz "bdzta- %u, 0x%X"
asm_ins_bdzta_ml:
.asciz "bdzta+ %u, 0x%X"
asm_ins_bdztl:
.asciz "bdztl %u, 0x%X"
asm_ins_bdztl_ll:
.asciz "bdztl- %u, 0x%X"
asm_ins_bdztl_ml:
.asciz "bdztl+ %u, 0x%X"
asm_ins_bdztla:
.asciz "bdztla %u, 0x%X"
asm_ins_bdztla_ll:
.asciz "bdztla- %u, 0x%X"
asm_ins_bdztla_ml:
.asciz "bdztla+ %u, 0x%X"

asm_ins_blt_cr0:
.asciz "blt 0x%X"
asm_ins_blt_ll_cr0:
.asciz "blt- 0x%X"
asm_ins_blt_ml_cr0:
.asciz "blt+ 0x%X"
asm_ins_blta_cr0:
.asciz "blta 0x%X"
asm_ins_blta_ll_cr0:
.asciz "blta- 0x%X"
asm_ins_blta_ml_cr0:
.asciz "blta+ 0x%X"
asm_ins_bltl_cr0:
.asciz "bltl 0x%X"
asm_ins_bltl_ll_cr0:
.asciz "bltl- 0x%X"
asm_ins_bltl_ml_cr0:
.asciz "bltl+ 0x%X"
asm_ins_bltla_cr0:
.asciz "bltla 0x%X"
asm_ins_bltla_ll_cr0:
.asciz "bltla- 0x%X"
asm_ins_bltla_ml_cr0:
.asciz "bltla+ 0x%X"
asm_ins_blt:
.asciz "blt cr%d, 0x%X"
asm_ins_blt_ll:
.asciz "blt- cr%d, 0x%X"
asm_ins_blt_ml:
.asciz "blt+ cr%d, 0x%X"
asm_ins_blta:
.asciz "blta cr%d, 0x%X"
asm_ins_blta_ll:
.asciz "blta- cr%d, 0x%X"
asm_ins_blta_ml:
.asciz "blta+ cr%d, 0x%X"
asm_ins_bltl:
.asciz "bltl cr%d, 0x%X"
asm_ins_bltl_ll:
.asciz "bltl- cr%d, 0x%X"
asm_ins_bltl_ml:
.asciz "bltl+ cr%d, 0x%X"
asm_ins_bltla:
.asciz "bltla cr%d, 0x%X"
asm_ins_bltla_ll:
.asciz "bltla- cr%d, 0x%X"
asm_ins_bltla_ml:
.asciz "bltla+ cr%d, 0x%X"

asm_ins_bgt_cr0:
.asciz "bgt 0x%X"
asm_ins_bgt_ll_cr0:
.asciz "bgt- 0x%X"
asm_ins_bgt_ml_cr0:
.asciz "bgt+ 0x%X"
asm_ins_bgta_cr0:
.asciz "bgta 0x%X"
asm_ins_bgta_ll_cr0:
.asciz "bgta- 0x%X"
asm_ins_bgta_ml_cr0:
.asciz "bgta+ 0x%X"
asm_ins_bgtl_cr0:
.asciz "bgtl 0x%X"
asm_ins_bgtl_ll_cr0:
.asciz "bgtl- 0x%X"
asm_ins_bgtl_ml_cr0:
.asciz "bgtl+ 0x%X"
asm_ins_bgtla_cr0:
.asciz "bgtla 0x%X"
asm_ins_bgtla_ll_cr0:
.asciz "bgtla- 0x%X"
asm_ins_bgtla_ml_cr0:
.asciz "bgtla+ 0x%X"
asm_ins_bgt:
.asciz "bgt cr%d, 0x%X"
asm_ins_bgt_ll:
.asciz "bgt- cr%d, 0x%X"
asm_ins_bgt_ml:
.asciz "bgt+ cr%d, 0x%X"
asm_ins_bgta:
.asciz "bgta cr%d, 0x%X"
asm_ins_bgta_ll:
.asciz "bgta- cr%d, 0x%X"
asm_ins_bgta_ml:
.asciz "bgta+ cr%d, 0x%X"
asm_ins_bgtl:
.asciz "bgtl cr%d, 0x%X"
asm_ins_bgtl_ll:
.asciz "bgtl- cr%d, 0x%X"
asm_ins_bgtl_ml:
.asciz "bgtl+ cr%d, 0x%X"
asm_ins_bgtla:
.asciz "bgtla cr%d, 0x%X"
asm_ins_bgtla_ll:
.asciz "bgtla- cr%d, 0x%X"
asm_ins_bgtla_ml:
.asciz "bgtla+ cr%d, 0x%X"

asm_ins_beq_cr0:
.asciz "beq 0x%X"
asm_ins_beq_ll_cr0:
.asciz "beq- 0x%X"
asm_ins_beq_ml_cr0:
.asciz "beq+ 0x%X"
asm_ins_beqa_cr0:
.asciz "beqa 0x%X"
asm_ins_beqa_ll_cr0:
.asciz "beqa- 0x%X"
asm_ins_beqa_ml_cr0:
.asciz "beqa+ 0x%X"
asm_ins_beql_cr0:
.asciz "beql 0x%X"
asm_ins_beql_ll_cr0:
.asciz "beql- 0x%X"
asm_ins_beql_ml_cr0:
.asciz "beql+ 0x%X"
asm_ins_beqla_cr0:
.asciz "beqla 0x%X"
asm_ins_beqla_ll_cr0:
.asciz "beqla- 0x%X"
asm_ins_beqla_ml_cr0:
.asciz "beqla+ 0x%X"
asm_ins_beq:
.asciz "beq cr%d, 0x%X"
asm_ins_beq_ll:
.asciz "beq- cr%d, 0x%X"
asm_ins_beq_ml:
.asciz "beq+ cr%d, 0x%X"
asm_ins_beqa:
.asciz "beqa cr%d, 0x%X"
asm_ins_beqa_ll:
.asciz "beqa- cr%d, 0x%X"
asm_ins_beqa_ml:
.asciz "beqa+ cr%d, 0x%X"
asm_ins_beql:
.asciz "beql cr%d, 0x%X"
asm_ins_beql_ll:
.asciz "beql- cr%d, 0x%X"
asm_ins_beql_ml:
.asciz "beql+ cr%d, 0x%X"
asm_ins_beqla:
.asciz "beqla cr%d, 0x%X"
asm_ins_beqla_ll:
.asciz "beqla- cr%d, 0x%X"
asm_ins_beqla_ml:
.asciz "beqla+ cr%d, 0x%X"

asm_ins_bso_cr0:
.asciz "bso 0x%X"
asm_ins_bso_ll_cr0:
.asciz "bso- 0x%X"
asm_ins_bso_ml_cr0:
.asciz "bso+ 0x%X"
asm_ins_bsoa_cr0:
.asciz "bsoa 0x%X"
asm_ins_bsoa_ll_cr0:
.asciz "bsoa- 0x%X"
asm_ins_bsoa_ml_cr0:
.asciz "bsoa+ 0x%X"
asm_ins_bsol_cr0:
.asciz "bsol 0x%X"
asm_ins_bsol_ll_cr0:
.asciz "bsol- 0x%X"
asm_ins_bsol_ml_cr0:
.asciz "bsol+ 0x%X"
asm_ins_bsola_cr0:
.asciz "bsola 0x%X"
asm_ins_bsola_ll_cr0:
.asciz "bsola- 0x%X"
asm_ins_bsola_ml_cr0:
.asciz "bsola+ 0x%X"
asm_ins_bso:
.asciz "bso cr%d, 0x%X"
asm_ins_bso_ll:
.asciz "bso- cr%d, 0x%X"
asm_ins_bso_ml:
.asciz "bso+ cr%d, 0x%X"
asm_ins_bsoa:
.asciz "bsoa cr%d, 0x%X"
asm_ins_bsoa_ll:
.asciz "bsoa- cr%d, 0x%X"
asm_ins_bsoa_ml:
.asciz "bsoa+ cr%d, 0x%X"
asm_ins_bsol:
.asciz "bsol cr%d, 0x%X"
asm_ins_bsol_ll:
.asciz "bsol- cr%d, 0x%X"
asm_ins_bsol_ml:
.asciz "bsol+ cr%d, 0x%X"
asm_ins_bsola:
.asciz "bsola cr%d, 0x%X"
asm_ins_bsola_ll:
.asciz "bsola- cr%d, 0x%X"
asm_ins_bsola_ml:
.asciz "bsola+ cr%d, 0x%X"

asm_ins_bdnz:
.asciz "bdnz 0x%X"
asm_ins_bdnz_ll:
.asciz "bdnz- 0x%X"
asm_ins_bdnz_ml:
.asciz "bdnz+ 0x%X"
asm_ins_bdnza:
.asciz "bdnza 0x%X"
asm_ins_bdnza_ll:
.asciz "bdnza- 0x%X"
asm_ins_bdnza_ml:
.asciz "bdnza+ 0x%X"
asm_ins_bdnzl:
.asciz "bdnzl 0x%X"
asm_ins_bdnzl_ll:
.asciz "bdnzl- 0x%X"
asm_ins_bdnzl_ml:
.asciz "bdnzl+ 0x%X"
asm_ins_bdnzla:
.asciz "bdnzla 0x%X"
asm_ins_bdnzla_ll:
.asciz "bdnzla- 0x%X"
asm_ins_bdnzla_ml:
.asciz "bdnzla+ 0x%X"

asm_ins_bdz:
.asciz "bdz 0x%X"
asm_ins_bdz_ll:
.asciz "bdz- 0x%X"
asm_ins_bdz_ml:
.asciz "bdz+ 0x%X"
asm_ins_bdza:
.asciz "bdza 0x%X"
asm_ins_bdza_ll:
.asciz "bdza- 0x%X"
asm_ins_bdza_ml:
.asciz "bdza+ 0x%X"
asm_ins_bdzl:
.asciz "bdzl 0x%X"
asm_ins_bdzl_ll:
.asciz "bdzl- 0x%X"
asm_ins_bdzl_ml:
.asciz "bdzl+ 0x%X"
asm_ins_bdzla:
.asciz "bdzla 0x%X"
asm_ins_bdzla_ll:
.asciz "bdzla- 0x%X"
asm_ins_bdzla_ml:
.asciz "bdzla+ 0x%X"

asm_ins_bcalways:
.asciz "bal 0x%0X"
asm_ins_bcalwaysA:
.asciz "bala 0x%0X"
asm_ins_bcalwaysL:
.asciz "ball 0x%0X"
asm_ins_bcalwaysAL:
.asciz "balla 0x%0X"

#
asm_ins_bdnzfctr:
.asciz "bdnzfctr %u"
asm_ins_bdnzfctr_ll:
.asciz "bdnzfctr- %u"
asm_ins_bdnzfctr_ml:
.asciz "bdnzfctr+ %u"
asm_ins_bdnzfctrl:
.asciz "bdnzfctrl %u"
asm_ins_bdnzfctrl_ll:
.asciz "bdnzfctrl- %u"
asm_ins_bdnzfctrl_ml:
.asciz "bdnzfctrl+ %u"

asm_ins_bdzfctr:
.asciz "bdzfctr %u"
asm_ins_bdzfctr_ll:
.asciz "bdzfctr- %u"
asm_ins_bdzfctr_ml:
.asciz "bdzfctr+ %u"
asm_ins_bdzfctrl:
.asciz "bdzfctrl %u"
asm_ins_bdzfctrl_ll:
.asciz "bdzfctrl- %u"
asm_ins_bdzfctrl_ml:
.asciz "bdzfctrl+ %u"

asm_ins_bgectr_cr0:
.asciz "bgectr"
asm_ins_bgectr_ll_cr0:
.asciz "bgectr-"
asm_ins_bgectr_ml_cr0:
.asciz "bgectr+"
asm_ins_bgectrl_cr0:
.asciz "bgectrl"
asm_ins_bgectrl_ll_cr0:
.asciz "bgectrl-"
asm_ins_bgectrl_ml_cr0:
.asciz "bgectrl+"
asm_ins_bgectr:
.asciz "bgectr cr%d"
asm_ins_bgectr_ll:
.asciz "bgectr- cr%d"
asm_ins_bgectr_ml:
.asciz "bgectr+ cr%d"
asm_ins_bgectrl:
.asciz "bgectrl cr%d"
asm_ins_bgectrl_ll:
.asciz "bgectrl- cr%d"
asm_ins_bgectrl_ml:
.asciz "bgectrl+ cr%d"

asm_ins_blectr_cr0:
.asciz "blectr"
asm_ins_blectr_ll_cr0:
.asciz "blectr-"
asm_ins_blectr_ml_cr0:
.asciz "blectr+"
asm_ins_blectrl_cr0:
.asciz "blectrl"
asm_ins_blectrl_ll_cr0:
.asciz "blectrl-"
asm_ins_blectrl_ml_cr0:
.asciz "blectrl+"
asm_ins_blectr:
.asciz "blectr cr%d"
asm_ins_blectr_ll:
.asciz "blectr- cr%d"
asm_ins_blectr_ml:
.asciz "blectr+ cr%d"
asm_ins_blectrl:
.asciz "blectrl cr%d"
asm_ins_blectrl_ll:
.asciz "blectrl- cr%d"
asm_ins_blectrl_ml:
.asciz "blectrl+ cr%d"

asm_ins_bnectr_cr0:
.asciz "bnectr"
asm_ins_bnectr_ll_cr0:
.asciz "bnectr-"
asm_ins_bnectr_ml_cr0:
.asciz "bnectr+"
asm_ins_bnectrl_cr0:
.asciz "bnectrl"
asm_ins_bnectrl_ll_cr0:
.asciz "bnectrl-"
asm_ins_bnectrl_ml_cr0:
.asciz "bnectrl+"
asm_ins_bnectr:
.asciz "bnectr cr%d"
asm_ins_bnectr_ll:
.asciz "bnectr- cr%d"
asm_ins_bnectr_ml:
.asciz "bnectr+ cr%d"
asm_ins_bnectrl:
.asciz "bnectrl cr%d"
asm_ins_bnectrl_ll:
.asciz "bnectrl- cr%d"
asm_ins_bnectrl_ml:
.asciz "bnectrl+ cr%d"

asm_ins_bnsctr_cr0:
.asciz "bnsctr"
asm_ins_bnsctr_ll_cr0:
.asciz "bnsctr-"
asm_ins_bnsctr_ml_cr0:
.asciz "bnsctr+"
asm_ins_bnsctrl_cr0:
.asciz "bnsctrl"
asm_ins_bnsctrl_ll_cr0:
.asciz "bnsctrl-"
asm_ins_bnsctrl_ml_cr0:
.asciz "bnsctrl+"
asm_ins_bnsctr:
.asciz "bnsctr cr%d"
asm_ins_bnsctr_ll:
.asciz "bnsctr- cr%d"
asm_ins_bnsctr_ml:
.asciz "bnsctr+ cr%d"
asm_ins_bnsctrl:
.asciz "bnsctrl cr%d"
asm_ins_bnsctrl_ll:
.asciz "bnsctrl- cr%d"
asm_ins_bnsctrl_ml:
.asciz "bnsctrl+ cr%d"

asm_ins_bdnztctr:
.asciz "bdnztctr %u"
asm_ins_bdnztctr_ll:
.asciz "bdnztctr- %u"
asm_ins_bdnztctr_ml:
.asciz "bdnztctr+ %u"
asm_ins_bdnztctrl:
.asciz "bdnztctrl %u"
asm_ins_bdnztctrl_ll:
.asciz "bdnztctrl- %u"
asm_ins_bdnztctrl_ml:
.asciz "bdnztctrl+ %u"

asm_ins_bdztctr:
.asciz "bdztctr %u"
asm_ins_bdztctr_ll:
.asciz "bdztctr- %u"
asm_ins_bdztctr_ml:
.asciz "bdztctr+ %u"
asm_ins_bdztctrl:
.asciz "bdztctrl %u"
asm_ins_bdztctrl_ll:
.asciz "bdztctrl- %u"
asm_ins_bdztctrl_ml:
.asciz "bdztctrl+ %u"

asm_ins_bltctr_cr0:
.asciz "bltctr"
asm_ins_bltctr_ll_cr0:
.asciz "bltctr-"
asm_ins_bltctr_ml_cr0:
.asciz "bltctr+"
asm_ins_bltctrl_cr0:
.asciz "bltctrl"
asm_ins_bltctrl_ll_cr0:
.asciz "bltctrl-"
asm_ins_bltctrl_ml_cr0:
.asciz "bltctrl+"
asm_ins_bltctr:
.asciz "bltctr cr%d"
asm_ins_bltctr_ll:
.asciz "bltctr- cr%d"
asm_ins_bltctr_ml:
.asciz "bltctr+ cr%d"
asm_ins_bltctrl:
.asciz "bltctrl cr%d"
asm_ins_bltctrl_ll:
.asciz "bltctrl- cr%d"
asm_ins_bltctrl_ml:
.asciz "bltctrl+ cr%d"

asm_ins_bgtctr_cr0:
.asciz "bgtctr"
asm_ins_bgtctr_ll_cr0:
.asciz "bgtctr-"
asm_ins_bgtctr_ml_cr0:
.asciz "bgtctr+"
asm_ins_bgtctrl_cr0:
.asciz "bgtctrl"
asm_ins_bgtctrl_ll_cr0:
.asciz "bgtctrl-"
asm_ins_bgtctrl_ml_cr0:
.asciz "bgtctrl+"
asm_ins_bgtctr:
.asciz "bgtctr cr%d"
asm_ins_bgtctr_ll:
.asciz "bgtctr- cr%d"
asm_ins_bgtctr_ml:
.asciz "bgtctr+ cr%d"
asm_ins_bgtctrl:
.asciz "bgtctrl cr%d"
asm_ins_bgtctrl_ll:
.asciz "bgtctrl- cr%d"
asm_ins_bgtctrl_ml:
.asciz "bgtctrl+ cr%d"

asm_ins_beqctr_cr0:
.asciz "beqctr"
asm_ins_beqctr_ll_cr0:
.asciz "beqctr-"
asm_ins_beqctr_ml_cr0:
.asciz "beqctr+"
asm_ins_beqctrl_cr0:
.asciz "beqctrl"
asm_ins_beqctrl_ll_cr0:
.asciz "beqctrl-"
asm_ins_beqctrl_ml_cr0:
.asciz "beqctrl+"
asm_ins_beqctr:
.asciz "beqctr cr%d"
asm_ins_beqctr_ll:
.asciz "beqctr- cr%d"
asm_ins_beqctr_ml:
.asciz "beqctr+ cr%d"
asm_ins_beqctrl:
.asciz "beqctrl cr%d"
asm_ins_beqctrl_ll:
.asciz "beqctrl- cr%d"
asm_ins_beqctrl_ml:
.asciz "beqctrl+ cr%d"

asm_ins_bsoctr_cr0:
.asciz "bsoctr"
asm_ins_bsoctr_ll_cr0:
.asciz "bsoctr-"
asm_ins_bsoctr_ml_cr0:
.asciz "bsoctr+"
asm_ins_bsoctrl_cr0:
.asciz "bsoctrl"
asm_ins_bsoctrl_ll_cr0:
.asciz "bsoctrl-"
asm_ins_bsoctrl_ml_cr0:
.asciz "bsoctrl+"
asm_ins_bsoctr:
.asciz "bsoctr cr%d"
asm_ins_bsoctr_ll:
.asciz "bsoctr- cr%d"
asm_ins_bsoctr_ml:
.asciz "bsoctr+ cr%d"
asm_ins_bsoctrl:
.asciz "bsoctrl cr%d"
asm_ins_bsoctrl_ll:
.asciz "bsoctrl- cr%d"
asm_ins_bsoctrl_ml:
.asciz "bsoctrl+ cr%d"

asm_ins_bdnzctr:
.asciz "bdnzctr"
asm_ins_bdnzctr_ll:
.asciz "bdnzctr-"
asm_ins_bdnzctr_ml:
.asciz "bdnzctr+"
asm_ins_bdnzctrl:
.asciz "bdnzctrl"
asm_ins_bdnzctrl_ll:
.asciz "bdnzctrl-"
asm_ins_bdnzctrl_ml:
.asciz "bdnzctrl+"

asm_ins_bdzctr:
.asciz "bdzctr"
asm_ins_bdzctr_ll:
.asciz "bdzctr-"
asm_ins_bdzctr_ml:
.asciz "bdzctr+"
asm_ins_bdzctrl:
.asciz "bdzctrl"
asm_ins_bdzctrl_ll:
.asciz "bdzctrl-"
asm_ins_bdzctrl_ml:
.asciz "bdzctrl+"

asm_ins_bctr:
.asciz "bctr"
asm_ins_bctrl:
.asciz "bctrl"

#
asm_ins_bdnzflr:
.asciz "bdnzflr %u"
asm_ins_bdnzflr_ll:
.asciz "bdnzflr- %u"
asm_ins_bdnzflr_ml:
.asciz "bdnzflr+ %u"
asm_ins_bdnzflrl:
.asciz "bdnzflrl %u"
asm_ins_bdnzflrl_ll:
.asciz "bdnzflrl- %u"
asm_ins_bdnzflrl_ml:
.asciz "bdnzflrl+ %u"

asm_ins_bdzflr:
.asciz "bdzflr %u"
asm_ins_bdzflr_ll:
.asciz "bdzflr- %u"
asm_ins_bdzflr_ml:
.asciz "bdzflr+ %u"
asm_ins_bdzflrl:
.asciz "bdzflrl %u"
asm_ins_bdzflrl_ll:
.asciz "bdzflrl- %u"
asm_ins_bdzflrl_ml:
.asciz "bdzflrl+ %u"

asm_ins_bgelr_cr0:
.asciz "bgelr"
asm_ins_bgelr_ll_cr0:
.asciz "bgelr-"
asm_ins_bgelr_ml_cr0:
.asciz "bgelr+"
asm_ins_bgelrl_cr0:
.asciz "bgelrl"
asm_ins_bgelrl_ll_cr0:
.asciz "bgelrl-"
asm_ins_bgelrl_ml_cr0:
.asciz "bgelrl+"
asm_ins_bgelr:
.asciz "bgelr cr%d"
asm_ins_bgelr_ll:
.asciz "bgelr- cr%d"
asm_ins_bgelr_ml:
.asciz "bgelr+ cr%d"
asm_ins_bgelrl:
.asciz "bgelrl cr%d"
asm_ins_bgelrl_ll:
.asciz "bgelrl- cr%d"
asm_ins_bgelrl_ml:
.asciz "bgelrl+ cr%d"

asm_ins_blelr_cr0:
.asciz "blelr"
asm_ins_blelr_ll_cr0:
.asciz "blelr-"
asm_ins_blelr_ml_cr0:
.asciz "blelr+"
asm_ins_blelrl_cr0:
.asciz "blelrl"
asm_ins_blelrl_ll_cr0:
.asciz "blelrl-"
asm_ins_blelrl_ml_cr0:
.asciz "blelrl+"
asm_ins_blelr:
.asciz "blelr cr%d"
asm_ins_blelr_ll:
.asciz "blelr- cr%d"
asm_ins_blelr_ml:
.asciz "blelr+ cr%d"
asm_ins_blelrl:
.asciz "blelrl cr%d"
asm_ins_blelrl_ll:
.asciz "blelrl- cr%d"
asm_ins_blelrl_ml:
.asciz "blelrl+ cr%d"

asm_ins_bnelr_cr0:
.asciz "bnelr"
asm_ins_bnelr_ll_cr0:
.asciz "bnelr-"
asm_ins_bnelr_ml_cr0:
.asciz "bnelr+"
asm_ins_bnelrl_cr0:
.asciz "bnelrl"
asm_ins_bnelrl_ll_cr0:
.asciz "bnelrl-"
asm_ins_bnelrl_ml_cr0:
.asciz "bnelrl+"
asm_ins_bnelr:
.asciz "bnelr cr%d"
asm_ins_bnelr_ll:
.asciz "bnelr- cr%d"
asm_ins_bnelr_ml:
.asciz "bnelr+ cr%d"
asm_ins_bnelrl:
.asciz "bnelrl cr%d"
asm_ins_bnelrl_ll:
.asciz "bnelrl- cr%d"
asm_ins_bnelrl_ml:
.asciz "bnelrl+ cr%d"

asm_ins_bnslr_cr0:
.asciz "bnslr"
asm_ins_bnslr_ll_cr0:
.asciz "bnslr-"
asm_ins_bnslr_ml_cr0:
.asciz "bnslr+"
asm_ins_bnslrl_cr0:
.asciz "bnslrl"
asm_ins_bnslrl_ll_cr0:
.asciz "bnslrl-"
asm_ins_bnslrl_ml_cr0:
.asciz "bnslrl+"
asm_ins_bnslr:
.asciz "bnslr cr%d"
asm_ins_bnslr_ll:
.asciz "bnslr- cr%d"
asm_ins_bnslr_ml:
.asciz "bnslr+ cr%d"
asm_ins_bnslrl:
.asciz "bnslrl cr%d"
asm_ins_bnslrl_ll:
.asciz "bnslrl- cr%d"
asm_ins_bnslrl_ml:
.asciz "bnslrl+ cr%d"

asm_ins_bdnztlr:
.asciz "bdnztlr %u"
asm_ins_bdnztlr_ll:
.asciz "bdnztlr- %u"
asm_ins_bdnztlr_ml:
.asciz "bdnztlr+ %u"
asm_ins_bdnztlrl:
.asciz "bdnztlrl %u"
asm_ins_bdnztlrl_ll:
.asciz "bdnztlrl- %u"
asm_ins_bdnztlrl_ml:
.asciz "bdnztlrl+ %u"

asm_ins_bdztlr:
.asciz "bdztlr %u"
asm_ins_bdztlr_ll:
.asciz "bdztlr- %u"
asm_ins_bdztlr_ml:
.asciz "bdztlr+ %u"
asm_ins_bdztlrl:
.asciz "bdztlrl %u"
asm_ins_bdztlrl_ll:
.asciz "bdztlrl- %u"
asm_ins_bdztlrl_ml:
.asciz "bdztlrl+ %u"

asm_ins_bltlr_cr0:
.asciz "bltlr"
asm_ins_bltlr_ll_cr0:
.asciz "bltlr-"
asm_ins_bltlr_ml_cr0:
.asciz "bltlr+"
asm_ins_bltlrl_cr0:
.asciz "bltlrl"
asm_ins_bltlrl_ll_cr0:
.asciz "bltlrl-"
asm_ins_bltlrl_ml_cr0:
.asciz "bltlrl+"
asm_ins_bltlr:
.asciz "bltlr cr%d"
asm_ins_bltlr_ll:
.asciz "bltlr- cr%d"
asm_ins_bltlr_ml:
.asciz "bltlr+ cr%d"
asm_ins_bltlrl:
.asciz "bltlrl cr%d"
asm_ins_bltlrl_ll:
.asciz "bltlrl- cr%d"
asm_ins_bltlrl_ml:
.asciz "bltlrl+ cr%d"

asm_ins_bgtlr_cr0:
.asciz "bgtlr"
asm_ins_bgtlr_ll_cr0:
.asciz "bgtlr-"
asm_ins_bgtlr_ml_cr0:
.asciz "bgtlr+"
asm_ins_bgtlrl_cr0:
.asciz "bgtlrl"
asm_ins_bgtlrl_ll_cr0:
.asciz "bgtlrl-"
asm_ins_bgtlrl_ml_cr0:
.asciz "bgtlrl+"
asm_ins_bgtlr:
.asciz "bgtlr cr%d"
asm_ins_bgtlr_ll:
.asciz "bgtlr- cr%d"
asm_ins_bgtlr_ml:
.asciz "bgtlr+ cr%d"
asm_ins_bgtlrl:
.asciz "bgtlrl cr%d"
asm_ins_bgtlrl_ll:
.asciz "bgtlrl- cr%d"
asm_ins_bgtlrl_ml:
.asciz "bgtlrl+ cr%d"

asm_ins_beqlr_cr0:
.asciz "beqlr"
asm_ins_beqlr_ll_cr0:
.asciz "beqlr-"
asm_ins_beqlr_ml_cr0:
.asciz "beqlr+"
asm_ins_beqlrl_cr0:
.asciz "beqlrl"
asm_ins_beqlrl_ll_cr0:
.asciz "beqlrl-"
asm_ins_beqlrl_ml_cr0:
.asciz "beqlrl+"
asm_ins_beqlr:
.asciz "beqlr cr%d"
asm_ins_beqlr_ll:
.asciz "beqlr- cr%d"
asm_ins_beqlr_ml:
.asciz "beqlr+ cr%d"
asm_ins_beqlrl:
.asciz "beqlrl cr%d"
asm_ins_beqlrl_ll:
.asciz "beqlrl- cr%d"
asm_ins_beqlrl_ml:
.asciz "beqlrl+ cr%d"

asm_ins_bsolr_cr0:
.asciz "bsolr"
asm_ins_bsolr_ll_cr0:
.asciz "bsolr-"
asm_ins_bsolr_ml_cr0:
.asciz "bsolr+"
asm_ins_bsolrl_cr0:
.asciz "bsolrl"
asm_ins_bsolrl_ll_cr0:
.asciz "bsolrl-"
asm_ins_bsolrl_ml_cr0:
.asciz "bsolrl+"
asm_ins_bsolr:
.asciz "bsolr cr%d"
asm_ins_bsolr_ll:
.asciz "bsolr- cr%d"
asm_ins_bsolr_ml:
.asciz "bsolr+ cr%d"
asm_ins_bsolrl:
.asciz "bsolrl cr%d"
asm_ins_bsolrl_ll:
.asciz "bsolrl- cr%d"
asm_ins_bsolrl_ml:
.asciz "bsolrl+ cr%d"

asm_ins_bdnzlr:
.asciz "bdnzlr"
asm_ins_bdnzlr_ll:
.asciz "bdnzlr-"
asm_ins_bdnzlr_ml:
.asciz "bdnzlr+"
asm_ins_bdnzlrl:
.asciz "bdnzlrl"
asm_ins_bdnzlrl_ll:
.asciz "bdnzlrl-"
asm_ins_bdnzlrl_ml:
.asciz "bdnzlrl+"

asm_ins_bdzlr:
.asciz "bdzlr"
asm_ins_bdzlr_ll:
.asciz "bdzlr-"
asm_ins_bdzlr_ml:
.asciz "bdzlr+"
asm_ins_bdzlrl:
.asciz "bdzlrl"
asm_ins_bdzlrl_ll:
.asciz "bdzlrl-"
asm_ins_bdzlrl_ml:
.asciz "bdzlrl+"

asm_ins_blr:
.asciz "blr"
asm_ins_blrl:
.asciz "blrl"

#No valid instruction
asm_invalid_instruction:
.asciz ".long 0x%08X"
.align 2

asm_table:
mflr r29 #Place Lookup Table in GVR

#Start instruction search
#Fyi if something is found, we check it with sscanf
#r3 = Formatted C string
#r4 = Conversions (% items)
#r5 = Dump spot of Conversion #1
#r6 = Dump spot #2
#r7 = #3, etc etc til r10

#NOTE NOTE NOTE
#For memcmp strings (strings that don't require sscanf), the longer strings have to go first
#For any branches where the BI IMM can "touch" the - or + in the instruction name, then the the order must be this... ll , ml, none
#For non-blank crF vs blank crF bcctrX and bclrX, the blanks must be checked first.

#Start the search!

try_bdnzf_ll: #label name not needed here, just for preference
addi r4, r29, asm_ins_bdnzf_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzf_ml

process_bcX_2sscanfarg 0b00000, 0, 0
b epilogue_main_asm

try_bdnzf_ml:
addi r4, r29, asm_ins_bdnzf_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzf

process_bcX_2sscanfarg 0b00000, 0, 1
b epilogue_main_asm

try_bdnzf:
addi r4, r29, asm_ins_bdnzf - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfa_ll

process_bcX_2sscanfarg 0b00000, 0, -1
b epilogue_main_asm

try_bdnzfa_ll:
addi r4, r29, asm_ins_bdnzfa_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfa_ml

process_bcX_2sscanfarg 0b00000, asm_aa, 0
b epilogue_main_asm

try_bdnzfa_ml:
addi r4, r29, asm_ins_bdnzfa_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfa

process_bcX_2sscanfarg 0b00000, asm_aa, 1
b epilogue_main_asm

try_bdnzfa:
addi r4, r29, asm_ins_bdnzfa - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfl_ll

process_bcX_2sscanfarg 0b00000, asm_aa, -1
b epilogue_main_asm

try_bdnzfl_ll:
addi r4, r29, asm_ins_bdnzfl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfl_ml

process_bcX_2sscanfarg 0b00000, asm_lk, 0
b epilogue_main_asm

try_bdnzfl_ml:
addi r4, r29, asm_ins_bdnzfl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfl

process_bcX_2sscanfarg 0b00000, asm_lk, 1
b epilogue_main_asm

try_bdnzfl:
addi r4, r29, asm_ins_bdnzfl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfla_ll

process_bcX_2sscanfarg 0b00000, asm_lk, -1
b epilogue_main_asm

try_bdnzfla_ll:
addi r4, r29, asm_ins_bdnzfla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfla_ml

process_bcX_2sscanfarg 0b00000, 3, 0
b epilogue_main_asm

try_bdnzfla_ml:
addi r4, r29, asm_ins_bdnzfla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzfla

process_bcX_2sscanfarg 0b00000, 3, 1
b epilogue_main_asm

try_bdnzfla:
addi r4, r29, asm_ins_bdnzfla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzf_ll

process_bcX_2sscanfarg 0b00000, 3, -1
b epilogue_main_asm

#################

try_bdzf_ll:
addi r4, r29, asm_ins_bdzf_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzf_ml

process_bcX_2sscanfarg 0b00010, 0, 0
b epilogue_main_asm

try_bdzf_ml:
addi r4, r29, asm_ins_bdzf_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzf

process_bcX_2sscanfarg 0b00010, 0, 1
b epilogue_main_asm

try_bdzf:
addi r4, r29, asm_ins_bdzf - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfa_ll

process_bcX_2sscanfarg 0b00010, 0, -1
b epilogue_main_asm

try_bdzfa_ll:
addi r4, r29, asm_ins_bdzfa_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfa_ml

process_bcX_2sscanfarg 0b00010, asm_aa, 0
b epilogue_main_asm

try_bdzfa_ml:
addi r4, r29, asm_ins_bdzfa_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfa

process_bcX_2sscanfarg 0b00010, asm_aa, 1
b epilogue_main_asm

try_bdzfa:
addi r4, r29, asm_ins_bdzfa - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfl_ll

process_bcX_2sscanfarg 0b00010, asm_aa, -1
b epilogue_main_asm

try_bdzfl_ll:
addi r4, r29, asm_ins_bdzfl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfl_ml

process_bcX_2sscanfarg 0b00010, asm_lk, 0
b epilogue_main_asm

try_bdzfl_ml:
addi r4, r29, asm_ins_bdzfl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfl

process_bcX_2sscanfarg 0b00010, asm_lk, 1
b epilogue_main_asm

try_bdzfl:
addi r4, r29, asm_ins_bdzfl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfla_ll

process_bcX_2sscanfarg 0b00010, asm_lk, -1
b epilogue_main_asm

try_bdzfla_ll:
addi r4, r29, asm_ins_bdzfla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfla_ml

process_bcX_2sscanfarg 0b00010, 3, 0
b epilogue_main_asm

try_bdzfla_ml:
addi r4, r29, asm_ins_bdzfla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzfla

process_bcX_2sscanfarg 0b00010, 3, 1
b epilogue_main_asm

try_bdzfla:
addi r4, r29, asm_ins_bdzfla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bge_cr0

process_bcX_2sscanfarg 0b00010, 3, -1
b epilogue_main_asm

#################

try_bge_cr0:
addi r4, r29, asm_ins_bge_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bge_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, 0, -1
b epilogue_main_asm

try_bge_ll_cr0:
addi r4, r29, asm_ins_bge_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bge_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, 0, 0
b epilogue_main_asm

try_bge_ml_cr0:
addi r4, r29, asm_ins_bge_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgea_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, 0, 1
b epilogue_main_asm

try_bgea_cr0:
addi r4, r29, asm_ins_bgea_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgea_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, asm_aa, -1
b epilogue_main_asm

try_bgea_ll_cr0:
addi r4, r29, asm_ins_bgea_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgea_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, asm_aa, 0
b epilogue_main_asm

try_bgea_ml_cr0:
addi r4, r29, asm_ins_bgea_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgel_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, asm_aa, 1
b epilogue_main_asm

try_bgel_cr0:
addi r4, r29, asm_ins_bgel_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgel_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, asm_lk, -1
b epilogue_main_asm

try_bgel_ll_cr0:
addi r4, r29, asm_ins_bgel_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgel_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, asm_lk, 0
b epilogue_main_asm

try_bgel_ml_cr0:
addi r4, r29, asm_ins_bgel_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgela_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, asm_lk, 1
b epilogue_main_asm

try_bgela_cr0:
addi r4, r29, asm_ins_bgela_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgela_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, 3, -1
b epilogue_main_asm

try_bgela_ll_cr0:
addi r4, r29, asm_ins_bgela_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgela_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 0, 3, 0
b epilogue_main_asm

try_bgela_ml_cr0:
addi r4, r29, asm_ins_bgela_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bge

process_bcX_1sscanfarg_cr0 0b00100, 0, 3, 1
b epilogue_main_asm

##

try_bge:
addi r4, r29, asm_ins_bge - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bge_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, 0, -1
b epilogue_main_asm

try_bge_ll:
addi r4, r29, asm_ins_bge_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bge_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, 0, 0
b epilogue_main_asm

try_bge_ml:
addi r4, r29, asm_ins_bge_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgea

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, 0, 1
b epilogue_main_asm

try_bgea:
addi r4, r29, asm_ins_bgea - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgea_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, asm_aa, -1
b epilogue_main_asm

try_bgea_ll:
addi r4, r29, asm_ins_bgea_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgea_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, asm_aa, 0
b epilogue_main_asm

try_bgea_ml:
addi r4, r29, asm_ins_bgea_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgel

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, asm_aa, 1
b epilogue_main_asm

try_bgel:
addi r4, r29, asm_ins_bgel - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgel_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, asm_lk, -1
b epilogue_main_asm

try_bgel_ll:
addi r4, r29, asm_ins_bgel_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgel_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, asm_lk, 0
b epilogue_main_asm

try_bgel_ml:
addi r4, r29, asm_ins_bgel_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgela

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, asm_lk, 1
b epilogue_main_asm

try_bgela:
addi r4, r29, asm_ins_bgela - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgela_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, 3, -1
b epilogue_main_asm

try_bgela_ll:
addi r4, r29, asm_ins_bgela_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgela_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, 3, 0
b epilogue_main_asm

try_bgela_ml:
addi r4, r29, asm_ins_bgela_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ble_cr0

process_bcX_2sscanfarg_NOTcr0 0b00100, 0, 3, 1
b epilogue_main_asm

########

try_ble_cr0:
addi r4, r29, asm_ins_ble_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_ble_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, 0, -1
b epilogue_main_asm

try_ble_ll_cr0:
addi r4, r29, asm_ins_ble_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_ble_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, 0, 0
b epilogue_main_asm

try_ble_ml_cr0:
addi r4, r29, asm_ins_ble_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blea_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, 0, 1
b epilogue_main_asm

try_blea_cr0:
addi r4, r29, asm_ins_blea_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blea_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, asm_aa, -1
b epilogue_main_asm

try_blea_ll_cr0:
addi r4, r29, asm_ins_blea_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blea_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, asm_aa, 0
b epilogue_main_asm

try_blea_ml_cr0:
addi r4, r29, asm_ins_blea_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blel_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, asm_aa, 1
b epilogue_main_asm

try_blel_cr0:
addi r4, r29, asm_ins_blel_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blel_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, asm_lk, -1
b epilogue_main_asm

try_blel_ll_cr0:
addi r4, r29, asm_ins_blel_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blel_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, asm_lk, 0
b epilogue_main_asm

try_blel_ml_cr0:
addi r4, r29, asm_ins_blel_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blela_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, asm_lk, 1
b epilogue_main_asm

try_blela_cr0:
addi r4, r29, asm_ins_blela_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blela_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, 3, -1
b epilogue_main_asm

try_blela_ll_cr0:
addi r4, r29, asm_ins_blela_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blela_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 1, 3, 0
b epilogue_main_asm

try_blela_ml_cr0:
addi r4, r29, asm_ins_blela_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_ble

process_bcX_1sscanfarg_cr0 0b00100, 1, 3, 1
b epilogue_main_asm

##

try_ble:
addi r4, r29, asm_ins_ble - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ble_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, 0, -1
b epilogue_main_asm

try_ble_ll:
addi r4, r29, asm_ins_ble_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ble_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, 0, 0
b epilogue_main_asm

try_ble_ml:
addi r4, r29, asm_ins_ble_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blea

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, 0, 1
b epilogue_main_asm

try_blea:
addi r4, r29, asm_ins_blea - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blea_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, asm_aa, -1
b epilogue_main_asm

try_blea_ll:
addi r4, r29, asm_ins_blea_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blea_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, asm_aa, 0
b epilogue_main_asm

try_blea_ml:
addi r4, r29, asm_ins_blea_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blel

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, asm_aa, 1
b epilogue_main_asm

try_blel:
addi r4, r29, asm_ins_blel - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blel_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, asm_lk, -1
b epilogue_main_asm

try_blel_ll:
addi r4, r29, asm_ins_blel_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blel_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, asm_lk, 0
b epilogue_main_asm

try_blel_ml:
addi r4, r29, asm_ins_blel_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blela

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, asm_lk, 1
b epilogue_main_asm

try_blela:
addi r4, r29, asm_ins_blela - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blela_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, 3, -1
b epilogue_main_asm

try_blela_ll:
addi r4, r29, asm_ins_blela_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blela_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, 3, 0
b epilogue_main_asm

try_blela_ml:
addi r4, r29, asm_ins_blela_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bne_cr0

process_bcX_2sscanfarg_NOTcr0 0b00100, 1, 3, 1
b epilogue_main_asm

########

try_bne_cr0:
addi r4, r29, asm_ins_bne_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bne_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, 0, -1
b epilogue_main_asm

try_bne_ll_cr0:
addi r4, r29, asm_ins_bne_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bne_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, 0, 0
b epilogue_main_asm

try_bne_ml_cr0:
addi r4, r29, asm_ins_bne_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnea_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, 0, 1
b epilogue_main_asm

try_bnea_cr0:
addi r4, r29, asm_ins_bnea_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnea_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, asm_aa, -1
b epilogue_main_asm

try_bnea_ll_cr0:
addi r4, r29, asm_ins_bnea_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnea_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, asm_aa, 0
b epilogue_main_asm

try_bnea_ml_cr0:
addi r4, r29, asm_ins_bnea_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnel_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, asm_aa, 1
b epilogue_main_asm

try_bnel_cr0:
addi r4, r29, asm_ins_bnel_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnel_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, asm_lk, -1
b epilogue_main_asm

try_bnel_ll_cr0:
addi r4, r29, asm_ins_bnel_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnel_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, asm_lk, 0
b epilogue_main_asm

try_bnel_ml_cr0:
addi r4, r29, asm_ins_bnel_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnela_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, asm_lk, 1
b epilogue_main_asm

try_bnela_cr0:
addi r4, r29, asm_ins_bnela_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnela_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, 3, -1
b epilogue_main_asm

try_bnela_ll_cr0:
addi r4, r29, asm_ins_bnela_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnela_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 2, 3, 0
b epilogue_main_asm

try_bnela_ml_cr0:
addi r4, r29, asm_ins_bnela_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bne

process_bcX_1sscanfarg_cr0 0b00100, 2, 3, 1
b epilogue_main_asm

##

try_bne:
addi r4, r29, asm_ins_bne - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bne_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, 0, -1
b epilogue_main_asm

try_bne_ll:
addi r4, r29, asm_ins_bne_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bne_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, 0, 0
b epilogue_main_asm

try_bne_ml:
addi r4, r29, asm_ins_bne_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnea

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, 0, 1
b epilogue_main_asm

try_bnea:
addi r4, r29, asm_ins_bnea - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnea_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, asm_aa, -1
b epilogue_main_asm

try_bnea_ll:
addi r4, r29, asm_ins_bnea_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnea_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, asm_aa, 0
b epilogue_main_asm

try_bnea_ml:
addi r4, r29, asm_ins_bnea_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnel

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, asm_aa, 1
b epilogue_main_asm

try_bnel:
addi r4, r29, asm_ins_bnel - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnel_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, asm_lk, -1
b epilogue_main_asm

try_bnel_ll:
addi r4, r29, asm_ins_bnel_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnel_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, asm_lk, 0
b epilogue_main_asm

try_bnel_ml:
addi r4, r29, asm_ins_bnel_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnela

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, asm_lk, 1
b epilogue_main_asm

try_bnela:
addi r4, r29, asm_ins_bnela - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnela_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, 3, -1
b epilogue_main_asm

try_bnela_ll:
addi r4, r29, asm_ins_bnela_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnela_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, 3, 0
b epilogue_main_asm

try_bnela_ml:
addi r4, r29, asm_ins_bnela_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bns_cr0

process_bcX_2sscanfarg_NOTcr0 0b00100, 2, 3, 1
b epilogue_main_asm

########

try_bns_cr0:
addi r4, r29, asm_ins_bns_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bns_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, 0, -1
b epilogue_main_asm

try_bns_ll_cr0:
addi r4, r29, asm_ins_bns_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bns_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, 0, 0
b epilogue_main_asm

try_bns_ml_cr0:
addi r4, r29, asm_ins_bns_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsa_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, 0, 1
b epilogue_main_asm

try_bnsa_cr0:
addi r4, r29, asm_ins_bnsa_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsa_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, asm_aa, -1
b epilogue_main_asm

try_bnsa_ll_cr0:
addi r4, r29, asm_ins_bnsa_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsa_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, asm_aa, 0
b epilogue_main_asm

try_bnsa_ml_cr0:
addi r4, r29, asm_ins_bnsa_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsl_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, asm_aa, 1
b epilogue_main_asm

try_bnsl_cr0:
addi r4, r29, asm_ins_bnsl_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsl_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, asm_lk, -1
b epilogue_main_asm

try_bnsl_ll_cr0:
addi r4, r29, asm_ins_bnsl_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsl_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, asm_lk, 0
b epilogue_main_asm

try_bnsl_ml_cr0:
addi r4, r29, asm_ins_bnsl_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsla_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, asm_lk, 1
b epilogue_main_asm

try_bnsla_cr0:
addi r4, r29, asm_ins_bnsla_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsla_ll_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, 3, -1
b epilogue_main_asm

try_bnsla_ll_cr0:
addi r4, r29, asm_ins_bnsla_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsla_ml_cr0

process_bcX_1sscanfarg_cr0 0b00100, 3, 3, 0
b epilogue_main_asm

try_bnsla_ml_cr0:
addi r4, r29, asm_ins_bnsla_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bns

process_bcX_1sscanfarg_cr0 0b00100, 3, 3, 1
b epilogue_main_asm

##

try_bns:
addi r4, r29, asm_ins_bns - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bns_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, 0, -1
b epilogue_main_asm

try_bns_ll:
addi r4, r29, asm_ins_bns_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bns_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, 0, 0
b epilogue_main_asm

try_bns_ml:
addi r4, r29, asm_ins_bns_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsa

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, 0, 1
b epilogue_main_asm

try_bnsa:
addi r4, r29, asm_ins_bnsa - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsa_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, asm_aa, -1
b epilogue_main_asm

try_bnsa_ll:
addi r4, r29, asm_ins_bnsa_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsa_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, asm_aa, 0
b epilogue_main_asm

try_bnsa_ml:
addi r4, r29, asm_ins_bnsa_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsl

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, asm_aa, 1
b epilogue_main_asm

try_bnsl:
addi r4, r29, asm_ins_bnsl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsl_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, asm_lk, -1
b epilogue_main_asm

try_bnsl_ll:
addi r4, r29, asm_ins_bnsl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsl_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, asm_lk, 0
b epilogue_main_asm

try_bnsl_ml:
addi r4, r29, asm_ins_bnsl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsla

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, asm_lk, 1
b epilogue_main_asm

try_bnsla:
addi r4, r29, asm_ins_bnsla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsla_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, 3, -1
b epilogue_main_asm

try_bnsla_ll:
addi r4, r29, asm_ins_bnsla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bnsla_ml

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, 3, 0
b epilogue_main_asm

try_bnsla_ml:
addi r4, r29, asm_ins_bnsla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzt_ll

process_bcX_2sscanfarg_NOTcr0 0b00100, 3, 3, 1
b epilogue_main_asm

###############################################################

#NOTE: This must be here or else the SIMM for the cond branch jumps are too far way
epilogue_error_bcX:
li r3, -4
b epilogue_final

###############################################################

try_bdnzt_ll:
addi r4, r29, asm_ins_bdnzt_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzt_ml

process_bcX_2sscanfarg 0b01000, 0, 0
b epilogue_main_asm

try_bdnzt_ml:
addi r4, r29, asm_ins_bdnzt_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzt

process_bcX_2sscanfarg 0b01000, 0, 1
b epilogue_main_asm

try_bdnzt:
addi r4, r29, asm_ins_bdnzt - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzta_ll

process_bcX_2sscanfarg 0b01000, 0, -1
b epilogue_main_asm

try_bdnzta_ll:
addi r4, r29, asm_ins_bdnzta_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzta_ml

process_bcX_2sscanfarg 0b01000, asm_aa, 0
b epilogue_main_asm

try_bdnzta_ml:
addi r4, r29, asm_ins_bdnzta_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnzta

process_bcX_2sscanfarg 0b01000, asm_aa, 1
b epilogue_main_asm

try_bdnzta:
addi r4, r29, asm_ins_bdnzta - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnztl_ll

process_bcX_2sscanfarg 0b01000, asm_aa, -1
b epilogue_main_asm

try_bdnztl_ll:
addi r4, r29, asm_ins_bdnztl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnztl_ml

process_bcX_2sscanfarg 0b01000, asm_lk, 0
b epilogue_main_asm

try_bdnztl_ml:
addi r4, r29, asm_ins_bdnztl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnztl

process_bcX_2sscanfarg 0b01000, asm_lk, 1
b epilogue_main_asm

try_bdnztl:
addi r4, r29, asm_ins_bdnztl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnztla_ll

process_bcX_2sscanfarg 0b01000, asm_lk, -1
b epilogue_main_asm

try_bdnztla_ll:
addi r4, r29, asm_ins_bdnztla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnztla_ml

process_bcX_2sscanfarg 0b01000, 3, 0
b epilogue_main_asm

try_bdnztla_ml:
addi r4, r29, asm_ins_bdnztla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnztla

process_bcX_2sscanfarg 0b01000, 3, 1
b epilogue_main_asm

try_bdnztla:
addi r4, r29, asm_ins_bdnztla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzt_ll

process_bcX_2sscanfarg 0b01000, 3, -1
b epilogue_main_asm

#################

try_bdzt_ll:
addi r4, r29, asm_ins_bdzt_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzt_ml

process_bcX_2sscanfarg 0b01010, 0, 0
b epilogue_main_asm

try_bdzt_ml:
addi r4, r29, asm_ins_bdzt_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzt

process_bcX_2sscanfarg 0b01010, 0, 1
b epilogue_main_asm

try_bdzt:
addi r4, r29, asm_ins_bdzt - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzta_ll

process_bcX_2sscanfarg 0b01010, 0, -1
b epilogue_main_asm

try_bdzta_ll:
addi r4, r29, asm_ins_bdzta_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzta_ml

process_bcX_2sscanfarg 0b01010, asm_aa, 0
b epilogue_main_asm

try_bdzta_ml:
addi r4, r29, asm_ins_bdzta_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdzta

process_bcX_2sscanfarg 0b01010, asm_aa, 1
b epilogue_main_asm

try_bdzta:
addi r4, r29, asm_ins_bdzta - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdztl_ll

process_bcX_2sscanfarg 0b01010, asm_aa, -1
b epilogue_main_asm

try_bdztl_ll:
addi r4, r29, asm_ins_bdztl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdztl_ml

process_bcX_2sscanfarg 0b01010, asm_lk, 0
b epilogue_main_asm

try_bdztl_ml:
addi r4, r29, asm_ins_bdztl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdztl

process_bcX_2sscanfarg 0b01010, asm_lk, 1
b epilogue_main_asm

try_bdztl:
addi r4, r29, asm_ins_bdztl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdztla_ll

process_bcX_2sscanfarg 0b01010, asm_lk, -1
b epilogue_main_asm

try_bdztla_ll:
addi r4, r29, asm_ins_bdztla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdztla_ml

process_bcX_2sscanfarg 0b01010, 3, 0
b epilogue_main_asm

try_bdztla_ml:
addi r4, r29, asm_ins_bdztla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdztla

process_bcX_2sscanfarg 0b01010, 3, 1
b epilogue_main_asm

try_bdztla:
addi r4, r29, asm_ins_bdztla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blt_cr0

process_bcX_2sscanfarg 0b01010, 3, -1
b epilogue_main_asm

#####################

try_blt_cr0:
addi r4, r29, asm_ins_blt_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blt_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, 0, -1
b epilogue_main_asm

try_blt_ll_cr0:
addi r4, r29, asm_ins_blt_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blt_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, 0, 0
b epilogue_main_asm

try_blt_ml_cr0:
addi r4, r29, asm_ins_blt_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blta_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, 0, 1
b epilogue_main_asm

try_blta_cr0:
addi r4, r29, asm_ins_blta_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blta_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, asm_aa, -1
b epilogue_main_asm

try_blta_ll_cr0:
addi r4, r29, asm_ins_blta_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blta_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, asm_aa, 0
b epilogue_main_asm

try_blta_ml_cr0:
addi r4, r29, asm_ins_blta_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltl_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, asm_aa, 1
b epilogue_main_asm

try_bltl_cr0:
addi r4, r29, asm_ins_bltl_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltl_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, asm_lk, -1
b epilogue_main_asm

try_bltl_ll_cr0:
addi r4, r29, asm_ins_bltl_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltl_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, asm_lk, 0
b epilogue_main_asm

try_bltl_ml_cr0:
addi r4, r29, asm_ins_bltl_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltla_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, asm_lk, 1
b epilogue_main_asm

try_bltla_cr0:
addi r4, r29, asm_ins_bltla_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltla_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, 3, -1
b epilogue_main_asm

try_bltla_ll_cr0:
addi r4, r29, asm_ins_bltla_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltla_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 0, 3, 0
b epilogue_main_asm

try_bltla_ml_cr0:
addi r4, r29, asm_ins_bltla_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blt

process_bcX_1sscanfarg_cr0 0b01100, 0, 3, 1
b epilogue_main_asm

##

try_blt:
addi r4, r29, asm_ins_blt - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blt_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, 0, -1
b epilogue_main_asm

try_blt_ll:
addi r4, r29, asm_ins_blt_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blt_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, 0, 0
b epilogue_main_asm

try_blt_ml:
addi r4, r29, asm_ins_blt_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blta

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, 0, 1
b epilogue_main_asm

try_blta:
addi r4, r29, asm_ins_blta - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blta_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, asm_aa, -1
b epilogue_main_asm

try_blta_ll:
addi r4, r29, asm_ins_blta_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blta_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, asm_aa, 0
b epilogue_main_asm

try_blta_ml:
addi r4, r29, asm_ins_blta_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bltl

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, asm_aa, 1
b epilogue_main_asm

try_bltl:
addi r4, r29, asm_ins_bltl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bltl_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, asm_lk, -1
b epilogue_main_asm

try_bltl_ll:
addi r4, r29, asm_ins_bltl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bltl_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, asm_lk, 0
b epilogue_main_asm

try_bltl_ml:
addi r4, r29, asm_ins_bltl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bltla

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, asm_lk, 1
b epilogue_main_asm

try_bltla:
addi r4, r29, asm_ins_bltla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bltla_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, 3, -1
b epilogue_main_asm

try_bltla_ll:
addi r4, r29, asm_ins_bltla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bltla_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, 3, 0
b epilogue_main_asm

try_bltla_ml:
addi r4, r29, asm_ins_bltla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgt_cr0

process_bcX_2sscanfarg_NOTcr0 0b01100, 0, 3, 1
b epilogue_main_asm

########

try_bgt_cr0:
addi r4, r29, asm_ins_bgt_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgt_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, 0, -1
b epilogue_main_asm

try_bgt_ll_cr0:
addi r4, r29, asm_ins_bgt_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgt_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, 0, 0
b epilogue_main_asm

try_bgt_ml_cr0:
addi r4, r29, asm_ins_bgt_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgta_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, 0, 1
b epilogue_main_asm

try_bgta_cr0:
addi r4, r29, asm_ins_bgta_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgta_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, asm_aa, -1
b epilogue_main_asm

try_bgta_ll_cr0:
addi r4, r29, asm_ins_bgta_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgta_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, asm_aa, 0
b epilogue_main_asm

try_bgta_ml_cr0:
addi r4, r29, asm_ins_bgta_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtl_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, asm_aa, 1
b epilogue_main_asm

try_bgtl_cr0:
addi r4, r29, asm_ins_bgtl_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtl_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, asm_lk, -1
b epilogue_main_asm

try_bgtl_ll_cr0:
addi r4, r29, asm_ins_bgtl_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtl_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, asm_lk, 0
b epilogue_main_asm

try_bgtl_ml_cr0:
addi r4, r29, asm_ins_bgtl_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtla_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, asm_lk, 1
b epilogue_main_asm

try_bgtla_cr0:
addi r4, r29, asm_ins_bgtla_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtla_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, 3, -1
b epilogue_main_asm

try_bgtla_ll_cr0:
addi r4, r29, asm_ins_bgtla_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtla_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 1, 3, 0
b epilogue_main_asm

try_bgtla_ml_cr0:
addi r4, r29, asm_ins_bgtla_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgt

process_bcX_1sscanfarg_cr0 0b01100, 1, 3, 1
b epilogue_main_asm

##

try_bgt:
addi r4, r29, asm_ins_bgt - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgt_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, 0, -1
b epilogue_main_asm

try_bgt_ll:
addi r4, r29, asm_ins_bgt_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgt_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, 0, 0
b epilogue_main_asm

try_bgt_ml:
addi r4, r29, asm_ins_bgt_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgta

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, 0, 1
b epilogue_main_asm

try_bgta:
addi r4, r29, asm_ins_bgta - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgta_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, asm_aa, -1
b epilogue_main_asm

try_bgta_ll:
addi r4, r29, asm_ins_bgta_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgta_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, asm_aa, 0
b epilogue_main_asm

try_bgta_ml:
addi r4, r29, asm_ins_bgta_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgtl

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, asm_aa, 1
b epilogue_main_asm

try_bgtl:
addi r4, r29, asm_ins_bgtl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgtl_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, asm_lk, -1
b epilogue_main_asm

try_bgtl_ll:
addi r4, r29, asm_ins_bgtl_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgtl_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, asm_lk, 0
b epilogue_main_asm

try_bgtl_ml:
addi r4, r29, asm_ins_bgtl_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgtla

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, asm_lk, 1
b epilogue_main_asm

try_bgtla:
addi r4, r29, asm_ins_bgtla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgtla_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, 3, -1
b epilogue_main_asm

try_bgtla_ll:
addi r4, r29, asm_ins_bgtla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bgtla_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, 3, 0
b epilogue_main_asm

try_bgtla_ml:
addi r4, r29, asm_ins_bgtla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beq_cr0

process_bcX_2sscanfarg_NOTcr0 0b01100, 1, 3, 1
b epilogue_main_asm

########

try_beq_cr0:
addi r4, r29, asm_ins_beq_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beq_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, 0, -1
b epilogue_main_asm

try_beq_ll_cr0:
addi r4, r29, asm_ins_beq_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beq_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, 0, 0
b epilogue_main_asm

try_beq_ml_cr0:
addi r4, r29, asm_ins_beq_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqa_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, 0, 1
b epilogue_main_asm

try_beqa_cr0:
addi r4, r29, asm_ins_beqa_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqa_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, asm_aa, -1
b epilogue_main_asm

try_beqa_ll_cr0:
addi r4, r29, asm_ins_beqa_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqa_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, asm_aa, 0
b epilogue_main_asm

try_beqa_ml_cr0:
addi r4, r29, asm_ins_beqa_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beql_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, asm_aa, 1
b epilogue_main_asm

try_beql_cr0:
addi r4, r29, asm_ins_beql_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beql_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, asm_lk, -1
b epilogue_main_asm

try_beql_ll_cr0:
addi r4, r29, asm_ins_beql_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beql_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, asm_lk, 0
b epilogue_main_asm

try_beql_ml_cr0:
addi r4, r29, asm_ins_beql_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqla_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, asm_lk, 1
b epilogue_main_asm

try_beqla_cr0:
addi r4, r29, asm_ins_beqla_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqla_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, 3, -1
b epilogue_main_asm

try_beqla_ll_cr0:
addi r4, r29, asm_ins_beqla_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqla_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 2, 3, 0
b epilogue_main_asm

try_beqla_ml_cr0:
addi r4, r29, asm_ins_beqla_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beq

process_bcX_1sscanfarg_cr0 0b01100, 2, 3, 1
b epilogue_main_asm

##

try_beq:
addi r4, r29, asm_ins_beq - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beq_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, 0, -1
b epilogue_main_asm

try_beq_ll:
addi r4, r29, asm_ins_beq_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beq_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, 0, 0
b epilogue_main_asm

try_beq_ml:
addi r4, r29, asm_ins_beq_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beqa

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, 0, 1
b epilogue_main_asm

try_beqa:
addi r4, r29, asm_ins_beqa - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beqa_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, asm_aa, -1
b epilogue_main_asm

try_beqa_ll:
addi r4, r29, asm_ins_beqa_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beqa_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, asm_aa, 0
b epilogue_main_asm

try_beqa_ml:
addi r4, r29, asm_ins_beqa_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beql

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, asm_aa, 1
b epilogue_main_asm

try_beql:
addi r4, r29, asm_ins_beql - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beql_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, asm_lk, -1
b epilogue_main_asm

try_beql_ll:
addi r4, r29, asm_ins_beql_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beql_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, asm_lk, 0
b epilogue_main_asm

try_beql_ml:
addi r4, r29, asm_ins_beql_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beqla

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, asm_lk, 1
b epilogue_main_asm

try_beqla:
addi r4, r29, asm_ins_beqla - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beqla_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, 3, -1
b epilogue_main_asm

try_beqla_ll:
addi r4, r29, asm_ins_beqla_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_beqla_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, 3, 0
b epilogue_main_asm

try_beqla_ml:
addi r4, r29, asm_ins_beqla_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bso_cr0

process_bcX_2sscanfarg_NOTcr0 0b01100, 2, 3, 1
b epilogue_main_asm

########

try_bso_cr0:
addi r4, r29, asm_ins_bso_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bso_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, 0, -1
b epilogue_main_asm

try_bso_ll_cr0:
addi r4, r29, asm_ins_bso_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bso_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, 0, 0
b epilogue_main_asm

try_bso_ml_cr0:
addi r4, r29, asm_ins_bso_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoa_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, 0, 1
b epilogue_main_asm

try_bsoa_cr0:
addi r4, r29, asm_ins_bsoa_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoa_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, asm_aa, -1
b epilogue_main_asm

try_bsoa_ll_cr0:
addi r4, r29, asm_ins_bsoa_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoa_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, asm_aa, 0
b epilogue_main_asm

try_bsoa_ml_cr0:
addi r4, r29, asm_ins_bsoa_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsol_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, asm_aa, 1
b epilogue_main_asm

try_bsol_cr0:
addi r4, r29, asm_ins_bsol_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsol_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, asm_lk, -1
b epilogue_main_asm

try_bsol_ll_cr0:
addi r4, r29, asm_ins_bsol_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsol_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, asm_lk, 0
b epilogue_main_asm

try_bsol_ml_cr0:
addi r4, r29, asm_ins_bsol_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsola_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, asm_lk, 1
b epilogue_main_asm

try_bsola_cr0:
addi r4, r29, asm_ins_bsola_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsola_ll_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, 3, -1
b epilogue_main_asm

try_bsola_ll_cr0:
addi r4, r29, asm_ins_bsola_ll_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsola_ml_cr0

process_bcX_1sscanfarg_cr0 0b01100, 3, 3, 0
b epilogue_main_asm

try_bsola_ml_cr0:
addi r4, r29, asm_ins_bsola_ml_cr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bso

process_bcX_1sscanfarg_cr0 0b01100, 3, 3, 1
b epilogue_main_asm

##

try_bso:
addi r4, r29, asm_ins_bso - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bso_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, 0, -1
b epilogue_main_asm

try_bso_ll:
addi r4, r29, asm_ins_bso_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bso_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, 0, 0
b epilogue_main_asm

try_bso_ml:
addi r4, r29, asm_ins_bso_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsoa

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, 0, 1
b epilogue_main_asm

try_bsoa:
addi r4, r29, asm_ins_bsoa - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsoa_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, asm_aa, -1
b epilogue_main_asm

try_bsoa_ll:
addi r4, r29, asm_ins_bsoa_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsoa_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, asm_aa, 0
b epilogue_main_asm

try_bsoa_ml:
addi r4, r29, asm_ins_bsoa_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsol

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, asm_aa, 1
b epilogue_main_asm

try_bsol:
addi r4, r29, asm_ins_bsol - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsol_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, asm_lk, -1
b epilogue_main_asm

try_bsol_ll:
addi r4, r29, asm_ins_bsol_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsol_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, asm_lk, 0
b epilogue_main_asm

try_bsol_ml:
addi r4, r29, asm_ins_bsol_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsola

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, asm_lk, 1
b epilogue_main_asm

try_bsola:
addi r4, r29, asm_ins_bsola - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsola_ll

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, 3, -1
b epilogue_main_asm

try_bsola_ll:
addi r4, r29, asm_ins_bsola_ll - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bsola_ml

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, 3, 0
b epilogue_main_asm

try_bsola_ml:
addi r4, r29, asm_ins_bsola_ml - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bdnz

process_bcX_2sscanfarg_NOTcr0 0b01100, 3, 3, 1
b epilogue_main_asm

########################

try_bdnz:
addi r4, r29, asm_ins_bdnz - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnz_ll

process_bcX_dnz_nz 0b10000, 0, -1
b epilogue_main_asm

try_bdnz_ll:
addi r4, r29, asm_ins_bdnz_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnz_ml

process_bcX_dnz_nz 0b10000, 0, 0
b epilogue_main_asm

try_bdnz_ml:
addi r4, r29, asm_ins_bdnz_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnza

process_bcX_dnz_nz 0b10000, 0, 1
b epilogue_main_asm

try_bdnza:
addi r4, r29, asm_ins_bdnza - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnza_ll

process_bcX_dnz_nz 0b10000, asm_aa, -1
b epilogue_main_asm

try_bdnza_ll:
addi r4, r29, asm_ins_bdnza_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnza_ml

process_bcX_dnz_nz 0b10000, asm_aa, 0
b epilogue_main_asm

try_bdnza_ml:
addi r4, r29, asm_ins_bdnza_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzl

process_bcX_dnz_nz 0b10000, asm_aa, 1
b epilogue_main_asm

try_bdnzl:
addi r4, r29, asm_ins_bdnzl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzl_ll

process_bcX_dnz_nz 0b10000, asm_lk, -1
b epilogue_main_asm

try_bdnzl_ll:
addi r4, r29, asm_ins_bdnzl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzl_ml

process_bcX_dnz_nz 0b10000, asm_lk, 0
b epilogue_main_asm

try_bdnzl_ml:
addi r4, r29, asm_ins_bdnzl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzla

process_bcX_dnz_nz 0b10000, asm_lk, 1
b epilogue_main_asm

try_bdnzla:
addi r4, r29, asm_ins_bdnzla - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzla_ll

process_bcX_dnz_nz 0b10000, 3, -1
b epilogue_main_asm

try_bdnzla_ll:
addi r4, r29, asm_ins_bdnzla_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzla_ml

process_bcX_dnz_nz 0b10000, 3, 0
b epilogue_main_asm

try_bdnzla_ml:
addi r4, r29, asm_ins_bdnzla_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdz

process_bcX_dnz_nz 0b10000, 3, 1
b epilogue_main_asm

#######################

try_bdz:
addi r4, r29, asm_ins_bdz - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdz_ll

process_bcX_dnz_nz 0b10010, 0, -1
b epilogue_main_asm

try_bdz_ll:
addi r4, r29, asm_ins_bdz_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdz_ml

process_bcX_dnz_nz 0b10010, 0, 0
b epilogue_main_asm

try_bdz_ml:
addi r4, r29, asm_ins_bdz_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdza

process_bcX_dnz_nz 0b10010, 0, 1
b epilogue_main_asm

try_bdza:
addi r4, r29, asm_ins_bdza - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdza_ll

process_bcX_dnz_nz 0b10010, asm_aa, -1
b epilogue_main_asm

try_bdza_ll:
addi r4, r29, asm_ins_bdza_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdza_ml

process_bcX_dnz_nz 0b10010, asm_aa, 0
b epilogue_main_asm

try_bdza_ml:
addi r4, r29, asm_ins_bdza_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzl

process_bcX_dnz_nz 0b10010, asm_aa, 1
b epilogue_main_asm

try_bdzl:
addi r4, r29, asm_ins_bdzl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzl_ll

process_bcX_dnz_nz 0b10010, asm_lk, -1
b epilogue_main_asm

try_bdzl_ll:
addi r4, r29, asm_ins_bdzl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzl_ml

process_bcX_dnz_nz 0b10010, asm_lk, 0
b epilogue_main_asm

try_bdzl_ml:
addi r4, r29, asm_ins_bdzl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzla

process_bcX_dnz_nz 0b10010, asm_lk, 1
b epilogue_main_asm

try_bdzla:
addi r4, r29, asm_ins_bdzla - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzla_ll

process_bcX_dnz_nz 0b10010, 3, -1
b epilogue_main_asm

try_bdzla_ll:
addi r4, r29, asm_ins_bdzla_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzla_ml

process_bcX_dnz_nz 0b10010, 3, 0
b epilogue_main_asm

try_bdzla_ml:
addi r4, r29, asm_ins_bdzla_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bcalways

process_bcX_dnz_nz 0b10010, 3, 1
b epilogue_main_asm

######################

try_bcalways:
addi r4, r29, asm_ins_bcalways - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bcalwaysA

process_bcX_always 0
b epilogue_main_asm

try_bcalwaysA:
addi r4, r29, asm_ins_bcalwaysA - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bcalwaysL

process_bcX_always asm_aa
b epilogue_main_asm

try_bcalwaysL:
addi r4, r29, asm_ins_bcalwaysL - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bcalwaysAL

process_bcX_always asm_lk
b epilogue_main_asm

try_bcalwaysAL:
addi r4, r29, asm_ins_bcalwaysAL - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzfctr_ll

process_bcX_always 3
b epilogue_main_asm

###########

try_bdnzfctr_ll:
addi r4, r29, asm_ins_bdnzfctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzfctr_ml

process_bcctrX_1sscanfarg 0b00000, 0
b epilogue_main_asm

try_bdnzfctr_ml:
addi r4, r29, asm_ins_bdnzfctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzfctr

process_bcctrX_1sscanfarg 0b00001, 0
b epilogue_main_asm

try_bdnzfctr:
addi r4, r29, asm_ins_bdnzfctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzfctrl_ll

process_bcctrX_1sscanfarg 0b00000, 0
b epilogue_main_asm

try_bdnzfctrl_ll:
addi r4, r29, asm_ins_bdnzfctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzfctrl_ml

process_bcctrX_1sscanfarg 0b00000, asm_lk
b epilogue_main_asm

try_bdnzfctrl_ml:
addi r4, r29, asm_ins_bdnzfctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzfctrl

process_bcctrX_1sscanfarg 0b00001, asm_lk
b epilogue_main_asm

try_bdnzfctrl:
addi r4, r29, asm_ins_bdnzfctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzfctr_ll

process_bcctrX_1sscanfarg 0b00000, asm_lk
b epilogue_main_asm

######################

try_bdzfctr_ll:
addi r4, r29, asm_ins_bdzfctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzfctr_ml

process_bcctrX_1sscanfarg 0b00010, 0
b epilogue_main_asm

try_bdzfctr_ml:
addi r4, r29, asm_ins_bdzfctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzfctr

process_bcctrX_1sscanfarg 0b00011, 0
b epilogue_main_asm

try_bdzfctr:
addi r4, r29, asm_ins_bdzfctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzfctrl_ll

process_bcctrX_1sscanfarg 0b00010, 0
b epilogue_main_asm

try_bdzfctrl_ll:
addi r4, r29, asm_ins_bdzfctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzfctrl_ml

process_bcctrX_1sscanfarg 0b00010, asm_lk
b epilogue_main_asm

try_bdzfctrl_ml:
addi r4, r29, asm_ins_bdzfctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzfctrl

process_bcctrX_1sscanfarg 0b00011, asm_lk
b epilogue_main_asm

try_bdzfctrl:
addi r4, r29, asm_ins_bdzfctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectr

process_bcctrX_1sscanfarg 0b00010, asm_lk
b epilogue_main_asm

####################

try_bgectr:
addi r4, r29, asm_ins_bgectr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 0, 0
b epilogue_main_asm

try_bgectr_ll:
addi r4, r29, asm_ins_bgectr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 0, 0
b epilogue_main_asm

try_bgectr_ml:
addi r4, r29, asm_ins_bgectr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectrl

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 0, 0
b epilogue_main_asm

try_bgectrl:
addi r4, r29, asm_ins_bgectrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgectrl_ll:
addi r4, r29, asm_ins_bgectrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgectrl_ml:
addi r4, r29, asm_ins_bgectrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgectrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 0, asm_lk
b epilogue_main_asm

try_bgectrl_ll_cr0:
addi r4, r29, asm_ins_bgectrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bgectrl_ml_cr0

process_bcctrX_cr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgectrl_ml_cr0:
addi r4, r29, asm_ins_bgectrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bgectrl_cr0

process_bcctrX_cr0 0b00101, 0, asm_lk
b epilogue_main_asm

try_bgectrl_cr0:
addi r4, r29, asm_ins_bgectrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgectr_ll_cr0

process_bcctrX_cr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgectr_ll_cr0:
addi r4, r29, asm_ins_bgectr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgectr_ml_cr0

process_bcctrX_cr0 0b00100, 0, 0
b epilogue_main_asm

try_bgectr_ml_cr0:
addi r4, r29, asm_ins_bgectr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgectr_cr0

process_bcctrX_cr0 0b00101, 0, 0
b epilogue_main_asm

try_bgectr_cr0:
addi r4, r29, asm_ins_bgectr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_blectr

process_bcctrX_cr0 0b00100, 0, 0
b epilogue_main_asm

#

try_blectr:
addi r4, r29, asm_ins_blectr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blectr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 1, 0
b epilogue_main_asm

try_blectr_ll:
addi r4, r29, asm_ins_blectr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blectr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 1, 0
b epilogue_main_asm

try_blectr_ml:
addi r4, r29, asm_ins_blectr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blectrl

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 1, 0
b epilogue_main_asm

try_blectrl:
addi r4, r29, asm_ins_blectrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blectrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blectrl_ll:
addi r4, r29, asm_ins_blectrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blectrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blectrl_ml:
addi r4, r29, asm_ins_blectrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blectrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 1, asm_lk
b epilogue_main_asm

try_blectrl_ll_cr0:
addi r4, r29, asm_ins_blectrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_blectrl_ml_cr0

process_bcctrX_cr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blectrl_ml_cr0:
addi r4, r29, asm_ins_blectrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_blectrl_cr0

process_bcctrX_cr0 0b00101, 1, asm_lk
b epilogue_main_asm

try_blectrl_cr0:
addi r4, r29, asm_ins_blectrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_blectr_ll_cr0

process_bcctrX_cr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blectr_ll_cr0:
addi r4, r29, asm_ins_blectr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_blectr_ml_cr0

process_bcctrX_cr0 0b00100, 1, 0
b epilogue_main_asm

try_blectr_ml_cr0:
addi r4, r29, asm_ins_blectr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_blectr_cr0

process_bcctrX_cr0 0b00101, 1, 0
b epilogue_main_asm

try_blectr_cr0:
addi r4, r29, asm_ins_blectr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnectr

process_bcctrX_cr0 0b00100, 1, 0
b epilogue_main_asm

#

try_bnectr:
addi r4, r29, asm_ins_bnectr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnectr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 2, 0
b epilogue_main_asm

try_bnectr_ll:
addi r4, r29, asm_ins_bnectr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnectr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 2, 0
b epilogue_main_asm

try_bnectr_ml:
addi r4, r29, asm_ins_bnectr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnectrl

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 2, 0
b epilogue_main_asm

try_bnectrl:
addi r4, r29, asm_ins_bnectrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnectrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnectrl_ll:
addi r4, r29, asm_ins_bnectrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnectrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnectrl_ml:
addi r4, r29, asm_ins_bnectrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnectrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 2, asm_lk
b epilogue_main_asm

try_bnectrl_ll_cr0:
addi r4, r29, asm_ins_bnectrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bnectrl_ml_cr0

process_bcctrX_cr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnectrl_ml_cr0:
addi r4, r29, asm_ins_bnectrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bnectrl_cr0

process_bcctrX_cr0 0b00101, 2, asm_lk
b epilogue_main_asm

try_bnectrl_cr0:
addi r4, r29, asm_ins_bnectrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnectr_ll_cr0

process_bcctrX_cr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnectr_ll_cr0:
addi r4, r29, asm_ins_bnectr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnectr_ml_cr0

process_bcctrX_cr0 0b00100, 2, 0
b epilogue_main_asm

try_bnectr_ml_cr0:
addi r4, r29, asm_ins_bnectr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnectr_cr0

process_bcctrX_cr0 0b00101, 2, 0
b epilogue_main_asm

try_bnectr_cr0:
addi r4, r29, asm_ins_bnectr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnsctr

process_bcctrX_cr0 0b00100, 2, 0
b epilogue_main_asm

#

try_bnsctr:
addi r4, r29, asm_ins_bnsctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsctr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 3, 0
b epilogue_main_asm

try_bnsctr_ll:
addi r4, r29, asm_ins_bnsctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsctr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 3, 0
b epilogue_main_asm

try_bnsctr_ml:
addi r4, r29, asm_ins_bnsctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsctrl

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 3, 0
b epilogue_main_asm

try_bnsctrl:
addi r4, r29, asm_ins_bnsctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsctrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnsctrl_ll:
addi r4, r29, asm_ins_bnsctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsctrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnsctrl_ml:
addi r4, r29, asm_ins_bnsctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnsctrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b00101, 3, asm_lk
b epilogue_main_asm

try_bnsctrl_ll_cr0:
addi r4, r29, asm_ins_bnsctrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bnsctrl_ml_cr0

process_bcctrX_cr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnsctrl_ml_cr0:
addi r4, r29, asm_ins_bnsctrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bnsctrl_cr0

process_bcctrX_cr0 0b00101, 3, asm_lk
b epilogue_main_asm

try_bnsctrl_cr0:
addi r4, r29, asm_ins_bnsctrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnsctr_ll_cr0

process_bcctrX_cr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnsctr_ll_cr0:
addi r4, r29, asm_ins_bnsctr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnsctr_ml_cr0

process_bcctrX_cr0 0b00100, 3, 0
b epilogue_main_asm

try_bnsctr_ml_cr0:
addi r4, r29, asm_ins_bnsctr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnsctr_cr0

process_bcctrX_cr0 0b00101, 3, 0
b epilogue_main_asm

try_bnsctr_cr0:
addi r4, r29, asm_ins_bnsctr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bdnztctr_ll

process_bcctrX_cr0 0b00100, 3, 0
b epilogue_main_asm

###############################################

#NOTE: This must be here or else the SIMM for the cond branch jumps are too far way
epilogue_error_bcctrX:
li r3, -4
b epilogue_final

###############################################

try_bdnztctr_ll:
addi r4, r29, asm_ins_bdnztctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztctr_ml

process_bcctrX_1sscanfarg 0b01000, 0
b epilogue_main_asm

try_bdnztctr_ml:
addi r4, r29, asm_ins_bdnztctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztctr

process_bcctrX_1sscanfarg 0b01001, 0
b epilogue_main_asm

try_bdnztctr:
addi r4, r29, asm_ins_bdnztctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztctrl_ll

process_bcctrX_1sscanfarg 0b01000, 0
b epilogue_main_asm

try_bdnztctrl_ll:
addi r4, r29, asm_ins_bdnztctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztctrl_ml

process_bcctrX_1sscanfarg 0b01000, asm_lk
b epilogue_main_asm

try_bdnztctrl_ml:
addi r4, r29, asm_ins_bdnztctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztctrl

process_bcctrX_1sscanfarg 0b01001, asm_lk
b epilogue_main_asm

try_bdnztctrl:
addi r4, r29, asm_ins_bdnztctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztctr_ll

process_bcctrX_1sscanfarg 0b01000, asm_lk
b epilogue_main_asm

######################

try_bdztctr_ll:
addi r4, r29, asm_ins_bdztctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztctr_ml

process_bcctrX_1sscanfarg 0b01010, 0
b epilogue_main_asm

try_bdztctr_ml:
addi r4, r29, asm_ins_bdztctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztctr

process_bcctrX_1sscanfarg 0b01011, 0
b epilogue_main_asm

try_bdztctr:
addi r4, r29, asm_ins_bdztctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztctrl_ll

process_bcctrX_1sscanfarg 0b01010, 0
b epilogue_main_asm

try_bdztctrl_ll:
addi r4, r29, asm_ins_bdztctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztctrl_ml

process_bcctrX_1sscanfarg 0b01010, asm_lk
b epilogue_main_asm

try_bdztctrl_ml:
addi r4, r29, asm_ins_bdztctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztctrl

process_bcctrX_1sscanfarg 0b01011, asm_lk
b epilogue_main_asm

try_bdztctrl:
addi r4, r29, asm_ins_bdztctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctr

process_bcctrX_1sscanfarg 0b01010, asm_lk
b epilogue_main_asm

#######################

try_bltctr:
addi r4, r29, asm_ins_bltctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 0, 0
b epilogue_main_asm

try_bltctr_ll:
addi r4, r29, asm_ins_bltctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 0, 0
b epilogue_main_asm

try_bltctr_ml:
addi r4, r29, asm_ins_bltctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctrl

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 0, 0
b epilogue_main_asm

try_bltctrl:
addi r4, r29, asm_ins_bltctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltctrl_ll:
addi r4, r29, asm_ins_bltctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltctrl_ml:
addi r4, r29, asm_ins_bltctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltctrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 0, asm_lk
b epilogue_main_asm

try_bltctrl_ll_cr0:
addi r4, r29, asm_ins_bltctrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bltctrl_ml_cr0

process_bcctrX_cr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltctrl_ml_cr0:
addi r4, r29, asm_ins_bltctrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bltctrl_cr0

process_bcctrX_cr0 0b01101, 0, asm_lk
b epilogue_main_asm

try_bltctrl_cr0:
addi r4, r29, asm_ins_bltctrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bltctr_ll_cr0

process_bcctrX_cr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltctr_ll_cr0:
addi r4, r29, asm_ins_bltctr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bltctr_ml_cr0

process_bcctrX_cr0 0b01100, 0, 0
b epilogue_main_asm

try_bltctr_ml_cr0:
addi r4, r29, asm_ins_bltctr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bltctr_cr0

process_bcctrX_cr0 0b01101, 0, 0
b epilogue_main_asm

try_bltctr_cr0:
addi r4, r29, asm_ins_bltctr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgtctr

process_bcctrX_cr0 0b01100, 0, 0
b epilogue_main_asm

#

try_bgtctr:
addi r4, r29, asm_ins_bgtctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtctr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 1, 0
b epilogue_main_asm

try_bgtctr_ll:
addi r4, r29, asm_ins_bgtctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtctr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 1, 0
b epilogue_main_asm

try_bgtctr_ml:
addi r4, r29, asm_ins_bgtctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtctrl

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 1, 0
b epilogue_main_asm

try_bgtctrl:
addi r4, r29, asm_ins_bgtctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtctrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtctrl_ll:
addi r4, r29, asm_ins_bgtctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtctrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtctrl_ml:
addi r4, r29, asm_ins_bgtctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtctrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 1, asm_lk
b epilogue_main_asm

try_bgtctrl_ll_cr0:
addi r4, r29, asm_ins_bgtctrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bgtctrl_ml_cr0

process_bcctrX_cr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtctrl_ml_cr0:
addi r4, r29, asm_ins_bgtctrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bgtctrl_cr0

process_bcctrX_cr0 0b01101, 1, asm_lk
b epilogue_main_asm

try_bgtctrl_cr0:
addi r4, r29, asm_ins_bgtctrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgtctr_ll_cr0

process_bcctrX_cr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtctr_ll_cr0:
addi r4, r29, asm_ins_bgtctr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgtctr_ml_cr0

process_bcctrX_cr0 0b01100, 1, 0
b epilogue_main_asm

try_bgtctr_ml_cr0:
addi r4, r29, asm_ins_bgtctr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgtctr_cr0

process_bcctrX_cr0 0b01101, 1, 0
b epilogue_main_asm

try_bgtctr_cr0:
addi r4, r29, asm_ins_bgtctr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_beqctr

process_bcctrX_cr0 0b01100, 1, 0
b epilogue_main_asm

#

try_beqctr:
addi r4, r29, asm_ins_beqctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqctr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 2, 0
b epilogue_main_asm

try_beqctr_ll:
addi r4, r29, asm_ins_beqctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqctr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 2, 0
b epilogue_main_asm

try_beqctr_ml:
addi r4, r29, asm_ins_beqctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqctrl

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 2, 0
b epilogue_main_asm

try_beqctrl:
addi r4, r29, asm_ins_beqctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqctrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqctrl_ll:
addi r4, r29, asm_ins_beqctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqctrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqctrl_ml:
addi r4, r29, asm_ins_beqctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqctrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 2, asm_lk
b epilogue_main_asm

try_beqctrl_ll_cr0:
addi r4, r29, asm_ins_beqctrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_beqctrl_ml_cr0

process_bcctrX_cr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqctrl_ml_cr0:
addi r4, r29, asm_ins_beqctrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_beqctrl_cr0

process_bcctrX_cr0 0b01101, 2, asm_lk
b epilogue_main_asm

try_beqctrl_cr0:
addi r4, r29, asm_ins_beqctrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_beqctr_ll_cr0

process_bcctrX_cr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqctr_ll_cr0:
addi r4, r29, asm_ins_beqctr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_beqctr_ml_cr0

process_bcctrX_cr0 0b01100, 2, 0
b epilogue_main_asm

try_beqctr_ml_cr0:
addi r4, r29, asm_ins_beqctr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_beqctr_cr0

process_bcctrX_cr0 0b01101, 2, 0
b epilogue_main_asm

try_beqctr_cr0:
addi r4, r29, asm_ins_beqctr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bsoctr

process_bcctrX_cr0 0b01100, 2, 0
b epilogue_main_asm

#

try_bsoctr:
addi r4, r29, asm_ins_bsoctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoctr_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 3, 0
b epilogue_main_asm

try_bsoctr_ll:
addi r4, r29, asm_ins_bsoctr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoctr_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 3, 0
b epilogue_main_asm

try_bsoctr_ml:
addi r4, r29, asm_ins_bsoctr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoctrl

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 3, 0
b epilogue_main_asm

try_bsoctrl:
addi r4, r29, asm_ins_bsoctrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoctrl_ll

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsoctrl_ll:
addi r4, r29, asm_ins_bsoctrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoctrl_ml

process_bcctrX_1sscanfarg_NOTcr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsoctrl_ml:
addi r4, r29, asm_ins_bsoctrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsoctrl_ll_cr0

process_bcctrX_1sscanfarg_NOTcr0 0b01101, 3, asm_lk
b epilogue_main_asm

try_bsoctrl_ll_cr0:
addi r4, r29, asm_ins_bsoctrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bsoctrl_ml_cr0

process_bcctrX_cr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsoctrl_ml_cr0:
addi r4, r29, asm_ins_bsoctrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bsoctrl_cr0

process_bcctrX_cr0 0b01101, 3, asm_lk
b epilogue_main_asm

try_bsoctrl_cr0:
addi r4, r29, asm_ins_bsoctrl_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bsoctr_ll_cr0

process_bcctrX_cr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsoctr_ll_cr0:
addi r4, r29, asm_ins_bsoctr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bsoctr_ml_cr0

process_bcctrX_cr0 0b01100, 3, 0
b epilogue_main_asm

try_bsoctr_ml_cr0:
addi r4, r29, asm_ins_bsoctr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bsoctr_cr0

process_bcctrX_cr0 0b01101, 3, 0
b epilogue_main_asm

try_bsoctr_cr0:
addi r4, r29, asm_ins_bsoctr_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bdnzctrl_ll

process_bcctrX_cr0 0b01100, 3, 0
b epilogue_main_asm

#######################

try_bdnzctrl_ll:
addi r4, r29, asm_ins_bdnzctrl_ll - asm_table_start
mr r3, r31
li r5, 9
bl memcmp
cmpwi r3, 0
bne- try_bdnzctrl_ml

process_bcctrX_NOsscanfarg 0b10000, asm_lk
b epilogue_main_asm

try_bdnzctrl_ml:
addi r4, r29, asm_ins_bdnzctrl_ml - asm_table_start
mr r3, r31
li r5, 9
bl memcmp
cmpwi r3, 0
bne- try_bdnzctrl

process_bcctrX_NOsscanfarg 0b10001, asm_lk
b epilogue_main_asm

try_bdnzctrl:
addi r4, r29, asm_ins_bdnzctrl - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdnzctr_ll

process_bcctrX_NOsscanfarg 0b10000, asm_lk
b epilogue_main_asm

try_bdnzctr_ll:
addi r4, r29, asm_ins_bdnzctr_ll - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdnzctr_ml

process_bcctrX_NOsscanfarg 0b10000, 0
b epilogue_main_asm

try_bdnzctr_ml:
addi r4, r29, asm_ins_bdnzctr_ml - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdnzctr

process_bcctrX_NOsscanfarg 0b10001, 0
b epilogue_main_asm

try_bdnzctr:
addi r4, r29, asm_ins_bdnzctr - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdzctrl_ll

process_bcctrX_NOsscanfarg 0b10000, 0
b epilogue_main_asm

###################

try_bdzctrl_ll:
addi r4, r29, asm_ins_bdzctrl_ll - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdzctrl_ml

process_bcctrX_NOsscanfarg 0b10010, asm_lk
b epilogue_main_asm

try_bdzctrl_ml:
addi r4, r29, asm_ins_bdzctrl_ml - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdzctrl

process_bcctrX_NOsscanfarg 0b10011, asm_lk
b epilogue_main_asm

try_bdzctrl:
addi r4, r29, asm_ins_bdzctrl - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdzctr_ll

process_bcctrX_NOsscanfarg 0b10010, asm_lk
b epilogue_main_asm

try_bdzctr_ll:
addi r4, r29, asm_ins_bdzctr_ll - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdzctr_ml

process_bcctrX_NOsscanfarg 0b10010, 0
b epilogue_main_asm

try_bdzctr_ml:
addi r4, r29, asm_ins_bdzctr_ml - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdzctr

process_bcctrX_NOsscanfarg 0b10011, 0
b epilogue_main_asm

try_bdzctr:
addi r4, r29, asm_ins_bdzctr - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bctrl

process_bcctrX_NOsscanfarg 0b10010, 0
b epilogue_main_asm

################

try_bctrl:
addi r4, r29, asm_ins_bctrl - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bctr

lwz r3, 0x2B8 (r29)
b epilogue_main_asm

try_bctr:
addi r4, r29, asm_ins_bctr - asm_table_start
mr r3, r31
li r5, 4
bl memcmp
cmpwi r3, 0
bne- try_bdnzflr_ll 

lwz r3, 0x2B4 (r29)
b epilogue_main_asm

#######################################################

try_bdnzflr_ll:
addi r4, r29, asm_ins_bdnzflr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzflr_ml

process_bclrX_1sscanfarg 0b00000, 0
b epilogue_main_asm

try_bdnzflr_ml:
addi r4, r29, asm_ins_bdnzflr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzflr

process_bclrX_1sscanfarg 0b00001, 0
b epilogue_main_asm

try_bdnzflr:
addi r4, r29, asm_ins_bdnzflr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzflrl_ll

process_bclrX_1sscanfarg 0b00000, 0
b epilogue_main_asm

try_bdnzflrl_ll:
addi r4, r29, asm_ins_bdnzflrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzflrl_ml

process_bclrX_1sscanfarg 0b00000, asm_lk
b epilogue_main_asm

try_bdnzflrl_ml:
addi r4, r29, asm_ins_bdnzflrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnzflrl

process_bclrX_1sscanfarg 0b00001, asm_lk
b epilogue_main_asm

try_bdnzflrl:
addi r4, r29, asm_ins_bdnzflrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzflr_ll

process_bclrX_1sscanfarg 0b00000, asm_lk
b epilogue_main_asm

######################

try_bdzflr_ll:
addi r4, r29, asm_ins_bdzflr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzflr_ml

process_bclrX_1sscanfarg 0b00010, 0
b epilogue_main_asm

try_bdzflr_ml:
addi r4, r29, asm_ins_bdzflr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzflr

process_bclrX_1sscanfarg 0b00011, 0
b epilogue_main_asm

try_bdzflr:
addi r4, r29, asm_ins_bdzflr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzflrl_ll

process_bclrX_1sscanfarg 0b00010, 0
b epilogue_main_asm

try_bdzflrl_ll:
addi r4, r29, asm_ins_bdzflrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzflrl_ml

process_bclrX_1sscanfarg 0b00010, asm_lk
b epilogue_main_asm

try_bdzflrl_ml:
addi r4, r29, asm_ins_bdzflrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdzflrl

process_bclrX_1sscanfarg 0b00011, asm_lk
b epilogue_main_asm

try_bdzflrl:
addi r4, r29, asm_ins_bdzflrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelr

process_bclrX_1sscanfarg 0b00010, asm_lk
b epilogue_main_asm

####################

try_bgelr:
addi r4, r29, asm_ins_bgelr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelr_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 0, 0
b epilogue_main_asm

try_bgelr_ll:
addi r4, r29, asm_ins_bgelr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelr_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 0, 0
b epilogue_main_asm

try_bgelr_ml:
addi r4, r29, asm_ins_bgelr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelrl

process_bclrX_1sscanfarg_NOTcr0 0b00101, 0, 0
b epilogue_main_asm

try_bgelrl:
addi r4, r29, asm_ins_bgelrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgelrl_ll:
addi r4, r29, asm_ins_bgelrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgelrl_ml:
addi r4, r29, asm_ins_bgelrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgelrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b00101, 0, asm_lk
b epilogue_main_asm

try_bgelrl_ll_cr0:
addi r4, r29, asm_ins_bgelrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgelrl_ml_cr0

process_bclrX_cr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgelrl_ml_cr0:
addi r4, r29, asm_ins_bgelrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgelrl_cr0

process_bclrX_cr0 0b00101, 0, asm_lk
b epilogue_main_asm

try_bgelrl_cr0:
addi r4, r29, asm_ins_bgelrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgelr_ll_cr0

process_bclrX_cr0 0b00100, 0, asm_lk
b epilogue_main_asm

try_bgelr_ll_cr0:
addi r4, r29, asm_ins_bgelr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgelr_ml_cr0

process_bclrX_cr0 0b00100, 0, 0
b epilogue_main_asm

try_bgelr_ml_cr0:
addi r4, r29, asm_ins_bgelr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgelr_cr0

process_bclrX_cr0 0b00101, 0, 0
b epilogue_main_asm

try_bgelr_cr0:
addi r4, r29, asm_ins_bgelr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_blelr

process_bclrX_cr0 0b00100, 0, 0
b epilogue_main_asm

#

try_blelr:
addi r4, r29, asm_ins_blelr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blelr_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 1, 0
b epilogue_main_asm

try_blelr_ll:
addi r4, r29, asm_ins_blelr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blelr_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 1, 0
b epilogue_main_asm

try_blelr_ml:
addi r4, r29, asm_ins_blelr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blelrl

process_bclrX_1sscanfarg_NOTcr0 0b00101, 1, 0
b epilogue_main_asm

try_blelrl:
addi r4, r29, asm_ins_blelrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blelrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blelrl_ll:
addi r4, r29, asm_ins_blelrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blelrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blelrl_ml:
addi r4, r29, asm_ins_blelrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_blelrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b00101, 1, asm_lk
b epilogue_main_asm

try_blelrl_ll_cr0:
addi r4, r29, asm_ins_blelrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_blelrl_ml_cr0

process_bclrX_cr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blelrl_ml_cr0:
addi r4, r29, asm_ins_blelrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_blelrl_cr0

process_bclrX_cr0 0b00101, 1, asm_lk
b epilogue_main_asm

try_blelrl_cr0:
addi r4, r29, asm_ins_blelrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_blelr_ll_cr0

process_bclrX_cr0 0b00100, 1, asm_lk
b epilogue_main_asm

try_blelr_ll_cr0:
addi r4, r29, asm_ins_blelr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_blelr_ml_cr0

process_bclrX_cr0 0b00100, 1, 0
b epilogue_main_asm

try_blelr_ml_cr0:
addi r4, r29, asm_ins_blelr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_blelr_cr0

process_bclrX_cr0 0b00101, 1, 0
b epilogue_main_asm

try_blelr_cr0:
addi r4, r29, asm_ins_blelr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bnelr

process_bclrX_cr0 0b00100, 1, 0
b epilogue_main_asm

#

try_bnelr:
addi r4, r29, asm_ins_bnelr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnelr_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 2, 0
b epilogue_main_asm

try_bnelr_ll:
addi r4, r29, asm_ins_bnelr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnelr_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 2, 0
b epilogue_main_asm

try_bnelr_ml:
addi r4, r29, asm_ins_bnelr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnelrl

process_bclrX_1sscanfarg_NOTcr0 0b00101, 2, 0
b epilogue_main_asm

try_bnelrl:
addi r4, r29, asm_ins_bnelrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnelrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnelrl_ll:
addi r4, r29, asm_ins_bnelrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnelrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnelrl_ml:
addi r4, r29, asm_ins_bnelrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnelrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b00101, 2, asm_lk
b epilogue_main_asm

try_bnelrl_ll_cr0:
addi r4, r29, asm_ins_bnelrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnelrl_ml_cr0

process_bclrX_cr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnelrl_ml_cr0:
addi r4, r29, asm_ins_bnelrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnelrl_cr0

process_bclrX_cr0 0b00101, 2, asm_lk
b epilogue_main_asm

try_bnelrl_cr0:
addi r4, r29, asm_ins_bnelrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnelr_ll_cr0

process_bclrX_cr0 0b00100, 2, asm_lk
b epilogue_main_asm

try_bnelr_ll_cr0:
addi r4, r29, asm_ins_bnelr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnelr_ml_cr0

process_bclrX_cr0 0b00100, 2, 0
b epilogue_main_asm

try_bnelr_ml_cr0:
addi r4, r29, asm_ins_bnelr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnelr_cr0

process_bclrX_cr0 0b00101, 2, 0
b epilogue_main_asm

try_bnelr_cr0:
addi r4, r29, asm_ins_bnelr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bnslr

process_bclrX_cr0 0b00100, 2, 0
b epilogue_main_asm

#

try_bnslr:
addi r4, r29, asm_ins_bnslr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnslr_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 3, 0
b epilogue_main_asm

try_bnslr_ll:
addi r4, r29, asm_ins_bnslr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnslr_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 3, 0
b epilogue_main_asm

try_bnslr_ml:
addi r4, r29, asm_ins_bnslr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnslrl

process_bclrX_1sscanfarg_NOTcr0 0b00101, 3, 0
b epilogue_main_asm

try_bnslrl:
addi r4, r29, asm_ins_bnslrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnslrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnslrl_ll:
addi r4, r29, asm_ins_bnslrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnslrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnslrl_ml:
addi r4, r29, asm_ins_bnslrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bnslrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b00101, 3, asm_lk
b epilogue_main_asm

try_bnslrl_ll_cr0:
addi r4, r29, asm_ins_bnslrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnslrl_ml_cr0

process_bclrX_cr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnslrl_ml_cr0:
addi r4, r29, asm_ins_bnslrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bnslrl_cr0

process_bclrX_cr0 0b00101, 3, asm_lk
b epilogue_main_asm

try_bnslrl_cr0:
addi r4, r29, asm_ins_bnslrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnslr_ll_cr0

process_bclrX_cr0 0b00100, 3, asm_lk
b epilogue_main_asm

try_bnslr_ll_cr0:
addi r4, r29, asm_ins_bnslr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnslr_ml_cr0

process_bclrX_cr0 0b00100, 3, 0
b epilogue_main_asm

try_bnslr_ml_cr0:
addi r4, r29, asm_ins_bnslr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bnslr_cr0

process_bclrX_cr0 0b00101, 3, 0
b epilogue_main_asm

try_bnslr_cr0:
addi r4, r29, asm_ins_bnslr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bdnztlr_ll

process_bclrX_cr0 0b00100, 3, 0
b epilogue_main_asm

###############################################

#NOTE: This must be here or else the SIMM for the cond branch jumps are too far way
epilogue_error_bclrX:
li r3, -4
b epilogue_final

###############################################

try_bdnztlr_ll:
addi r4, r29, asm_ins_bdnztlr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztlr_ml

process_bclrX_1sscanfarg 0b01000, 0
b epilogue_main_asm

try_bdnztlr_ml:
addi r4, r29, asm_ins_bdnztlr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztlr

process_bclrX_1sscanfarg 0b01001, 0
b epilogue_main_asm

try_bdnztlr:
addi r4, r29, asm_ins_bdnztlr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztlrl_ll

process_bclrX_1sscanfarg 0b01000, 0
b epilogue_main_asm

try_bdnztlrl_ll:
addi r4, r29, asm_ins_bdnztlrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztlrl_ml

process_bclrX_1sscanfarg 0b01000, asm_lk
b epilogue_main_asm

try_bdnztlrl_ml:
addi r4, r29, asm_ins_bdnztlrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdnztlrl

process_bclrX_1sscanfarg 0b01001, asm_lk
b epilogue_main_asm

try_bdnztlrl:
addi r4, r29, asm_ins_bdnztlrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztlr_ll

process_bclrX_1sscanfarg 0b01000, asm_lk
b epilogue_main_asm

######################

try_bdztlr_ll:
addi r4, r29, asm_ins_bdztlr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztlr_ml

process_bclrX_1sscanfarg 0b01010, 0
b epilogue_main_asm

try_bdztlr_ml:
addi r4, r29, asm_ins_bdztlr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztlr

process_bclrX_1sscanfarg 0b01011, 0
b epilogue_main_asm

try_bdztlr:
addi r4, r29, asm_ins_bdztlr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztlrl_ll

process_bclrX_1sscanfarg 0b01010, 0
b epilogue_main_asm

try_bdztlrl_ll:
addi r4, r29, asm_ins_bdztlrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztlrl_ml

process_bclrX_1sscanfarg 0b01010, asm_lk
b epilogue_main_asm

try_bdztlrl_ml:
addi r4, r29, asm_ins_bdztlrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bdztlrl

process_bclrX_1sscanfarg 0b01011, asm_lk
b epilogue_main_asm

try_bdztlrl:
addi r4, r29, asm_ins_bdztlrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlr

process_bclrX_1sscanfarg 0b01010, asm_lk
b epilogue_main_asm

#######################

try_bltlr:
addi r4, r29, asm_ins_bltlr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlr_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 0, 0
b epilogue_main_asm

try_bltlr_ll:
addi r4, r29, asm_ins_bltlr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlr_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 0, 0
b epilogue_main_asm

try_bltlr_ml:
addi r4, r29, asm_ins_bltlr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlrl

process_bclrX_1sscanfarg_NOTcr0 0b01101, 0, 0
b epilogue_main_asm

try_bltlrl:
addi r4, r29, asm_ins_bltlrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltlrl_ll:
addi r4, r29, asm_ins_bltlrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltlrl_ml:
addi r4, r29, asm_ins_bltlrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bltlrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b01101, 0, asm_lk
b epilogue_main_asm

try_bltlrl_ll_cr0:
addi r4, r29, asm_ins_bltlrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bltlrl_ml_cr0

process_bclrX_cr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltlrl_ml_cr0:
addi r4, r29, asm_ins_bltlrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bltlrl_cr0

process_bclrX_cr0 0b01101, 0, asm_lk
b epilogue_main_asm

try_bltlrl_cr0:
addi r4, r29, asm_ins_bltlrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bltlr_ll_cr0

process_bclrX_cr0 0b01100, 0, asm_lk
b epilogue_main_asm

try_bltlr_ll_cr0:
addi r4, r29, asm_ins_bltlr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bltlr_ml_cr0

process_bclrX_cr0 0b01100, 0, 0
b epilogue_main_asm

try_bltlr_ml_cr0:
addi r4, r29, asm_ins_bltlr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bltlr_cr0

process_bclrX_cr0 0b01101, 0, 0
b epilogue_main_asm

try_bltlr_cr0:
addi r4, r29, asm_ins_bltlr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bgtlr

process_bclrX_cr0 0b01100, 0, 0
b epilogue_main_asm

#

try_bgtlr:
addi r4, r29, asm_ins_bgtlr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtlr_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 1, 0
b epilogue_main_asm

try_bgtlr_ll:
addi r4, r29, asm_ins_bgtlr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtlr_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 1, 0
b epilogue_main_asm

try_bgtlr_ml:
addi r4, r29, asm_ins_bgtlr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtlrl

process_bclrX_1sscanfarg_NOTcr0 0b01101, 1, 0
b epilogue_main_asm

try_bgtlrl:
addi r4, r29, asm_ins_bgtlrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtlrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtlrl_ll:
addi r4, r29, asm_ins_bgtlrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtlrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtlrl_ml:
addi r4, r29, asm_ins_bgtlrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bgtlrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b01101, 1, asm_lk
b epilogue_main_asm

try_bgtlrl_ll_cr0:
addi r4, r29, asm_ins_bgtlrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgtlrl_ml_cr0

process_bclrX_cr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtlrl_ml_cr0:
addi r4, r29, asm_ins_bgtlrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bgtlrl_cr0

process_bclrX_cr0 0b01101, 1, asm_lk
b epilogue_main_asm

try_bgtlrl_cr0:
addi r4, r29, asm_ins_bgtlrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgtlr_ll_cr0

process_bclrX_cr0 0b01100, 1, asm_lk
b epilogue_main_asm

try_bgtlr_ll_cr0:
addi r4, r29, asm_ins_bgtlr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgtlr_ml_cr0

process_bclrX_cr0 0b01100, 1, 0
b epilogue_main_asm

try_bgtlr_ml_cr0:
addi r4, r29, asm_ins_bgtlr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bgtlr_cr0

process_bclrX_cr0 0b01101, 1, 0
b epilogue_main_asm

try_bgtlr_cr0:
addi r4, r29, asm_ins_bgtlr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_beqlr

process_bclrX_cr0 0b01100, 1, 0
b epilogue_main_asm

#

try_beqlr:
addi r4, r29, asm_ins_beqlr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqlr_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 2, 0
b epilogue_main_asm

try_beqlr_ll:
addi r4, r29, asm_ins_beqlr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqlr_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 2, 0
b epilogue_main_asm

try_beqlr_ml:
addi r4, r29, asm_ins_beqlr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqlrl

process_bclrX_1sscanfarg_NOTcr0 0b01101, 2, 0
b epilogue_main_asm

try_beqlrl:
addi r4, r29, asm_ins_beqlrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqlrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqlrl_ll:
addi r4, r29, asm_ins_beqlrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqlrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqlrl_ml:
addi r4, r29, asm_ins_beqlrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_beqlrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b01101, 2, asm_lk
b epilogue_main_asm

try_beqlrl_ll_cr0:
addi r4, r29, asm_ins_beqlrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_beqlrl_ml_cr0

process_bclrX_cr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqlrl_ml_cr0:
addi r4, r29, asm_ins_beqlrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_beqlrl_cr0

process_bclrX_cr0 0b01101, 2, asm_lk
b epilogue_main_asm

try_beqlrl_cr0:
addi r4, r29, asm_ins_beqlrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_beqlr_ll_cr0

process_bclrX_cr0 0b01100, 2, asm_lk
b epilogue_main_asm

try_beqlr_ll_cr0:
addi r4, r29, asm_ins_beqlr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_beqlr_ml_cr0

process_bclrX_cr0 0b01100, 2, 0
b epilogue_main_asm

try_beqlr_ml_cr0:
addi r4, r29, asm_ins_beqlr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_beqlr_cr0

process_bclrX_cr0 0b01101, 2, 0
b epilogue_main_asm

try_beqlr_cr0:
addi r4, r29, asm_ins_beqlr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bsolr

process_bclrX_cr0 0b01100, 2, 0
b epilogue_main_asm

#

try_bsolr:
addi r4, r29, asm_ins_bsolr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsolr_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 3, 0
b epilogue_main_asm

try_bsolr_ll:
addi r4, r29, asm_ins_bsolr_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsolr_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 3, 0
b epilogue_main_asm

try_bsolr_ml:
addi r4, r29, asm_ins_bsolr_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsolrl

process_bclrX_1sscanfarg_NOTcr0 0b01101, 3, 0
b epilogue_main_asm

try_bsolrl:
addi r4, r29, asm_ins_bsolrl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsolrl_ll

process_bclrX_1sscanfarg_NOTcr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsolrl_ll:
addi r4, r29, asm_ins_bsolrl_ll - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsolrl_ml

process_bclrX_1sscanfarg_NOTcr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsolrl_ml:
addi r4, r29, asm_ins_bsolrl_ml - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bsolrl_ll_cr0

process_bclrX_1sscanfarg_NOTcr0 0b01101, 3, asm_lk
b epilogue_main_asm

try_bsolrl_ll_cr0:
addi r4, r29, asm_ins_bsolrl_ll_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bsolrl_ml_cr0

process_bclrX_cr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsolrl_ml_cr0:
addi r4, r29, asm_ins_bsolrl_ml_cr0 - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bsolrl_cr0

process_bclrX_cr0 0b01101, 3, asm_lk
b epilogue_main_asm

try_bsolrl_cr0:
addi r4, r29, asm_ins_bsolrl_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bsolr_ll_cr0

process_bclrX_cr0 0b01100, 3, asm_lk
b epilogue_main_asm

try_bsolr_ll_cr0:
addi r4, r29, asm_ins_bsolr_ll_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bsolr_ml_cr0

process_bclrX_cr0 0b01100, 3, 0
b epilogue_main_asm

try_bsolr_ml_cr0:
addi r4, r29, asm_ins_bsolr_ml_cr0 - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bsolr_cr0

process_bclrX_cr0 0b01101, 3, 0
b epilogue_main_asm

try_bsolr_cr0:
addi r4, r29, asm_ins_bsolr_cr0 - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_bdnzlrl_ll

process_bclrX_cr0 0b01100, 3, 0
b epilogue_main_asm

#######################

try_bdnzlrl_ll:
addi r4, r29, asm_ins_bdnzlrl_ll - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdnzlrl_ml

process_bclrX_NOsscanfarg 0b10000, asm_lk
b epilogue_main_asm

try_bdnzlrl_ml:
addi r4, r29, asm_ins_bdnzlrl_ml - asm_table_start
mr r3, r31
li r5, 8
bl memcmp
cmpwi r3, 0
bne- try_bdnzlrl

process_bclrX_NOsscanfarg 0b10001, asm_lk
b epilogue_main_asm

try_bdnzlrl:
addi r4, r29, asm_ins_bdnzlrl - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdnzlr_ll

process_bclrX_NOsscanfarg 0b10000, asm_lk
b epilogue_main_asm

try_bdnzlr_ll:
addi r4, r29, asm_ins_bdnzlr_ll - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdnzlr_ml

process_bclrX_NOsscanfarg 0b10000, 0
b epilogue_main_asm

try_bdnzlr_ml:
addi r4, r29, asm_ins_bdnzlr_ml - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdnzlr

process_bclrX_NOsscanfarg 0b10001, 0
b epilogue_main_asm

try_bdnzlr:
addi r4, r29, asm_ins_bdnzlr - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bdzlrl_ll

process_bclrX_NOsscanfarg 0b10000, 0
b epilogue_main_asm

###################

try_bdzlrl_ll:
addi r4, r29, asm_ins_bdzlrl_ll - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdzlrl_ml

process_bclrX_NOsscanfarg 0b10010, asm_lk
b epilogue_main_asm

try_bdzlrl_ml:
addi r4, r29, asm_ins_bdzlrl_ml - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_bdzlrl

process_bclrX_NOsscanfarg 0b10011, asm_lk
b epilogue_main_asm

try_bdzlrl:
addi r4, r29, asm_ins_bdzlrl - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bdzlr_ll

process_bclrX_NOsscanfarg 0b10010, asm_lk
b epilogue_main_asm

try_bdzlr_ll:
addi r4, r29, asm_ins_bdzlr_ll - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bdzlr_ml

process_bclrX_NOsscanfarg 0b10010, 0
b epilogue_main_asm

try_bdzlr_ml:
addi r4, r29, asm_ins_bdzlr_ml - asm_table_start
mr r3, r31
li r5, 6
bl memcmp
cmpwi r3, 0
bne- try_bdzlr

process_bclrX_NOsscanfarg 0b10011, 0
b epilogue_main_asm

try_bdzlr:
addi r4, r29, asm_ins_bdzlr - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_blrl

process_bclrX_NOsscanfarg 0b10010, 0
b epilogue_main_asm

################

try_blrl:
addi r4, r29, asm_ins_blrl - asm_table_start
mr r3, r31
li r5, 4
bl memcmp
cmpwi r3, 0
bne- try_blr

lwz r3, 0x2C0 (r29)
b epilogue_main_asm

try_blr:
addi r4, r29, asm_ins_blr - asm_table_start
mr r3, r31
li r5, 3
bl memcmp
cmpwi r3, 0
bne- try_add 

lwz r3, 0x2BC (r29)
b epilogue_main_asm

#Check for add
try_add:
addi r4, r29, asm_ins_add - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_add_

#add found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for add.
try_add_:
addi r4, r29, asm_ins_add_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addo

#add. found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for addo
try_addo:
addi r4, r29, asm_ins_addo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addo_

#addo found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for addo.
try_addo_:
addi r4, r29, asm_ins_addo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addc

#addo. found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#
#Check for addc
try_addc:
addi r4, r29, asm_ins_addc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addc_

#addc found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for addc.
try_addc_:
addi r4, r29, asm_ins_addc_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addco

#addc. found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for addco
try_addco:
addi r4, r29, asm_ins_addco - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addco_

#addco found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for addco.
try_addco_:
addi r4, r29, asm_ins_addco_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_adde

#addco. found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#
#Check for adde
try_adde:
addi r4, r29, asm_ins_adde - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_adde_

#adde found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for adde.
try_adde_:
addi r4, r29, asm_ins_adde_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addeo

#adde. found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for addeo
try_addeo:
addi r4, r29, asm_ins_addeo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addeo_

#addeo found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for addeo.
try_addeo_:
addi r4, r29, asm_ins_addeo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addi

#addeo. found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for addi
try_addi:
addi r4, r29, asm_ins_addi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addiDEC

#addi found
process_imm_nonstoreload
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for addi DEC
try_addiDEC:
addi r4, r29, asm_ins_addiDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subi

#addi DEC found
process_imm_nonstoreload
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for subi
try_subi:
addi r4, r29, asm_ins_subi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subiDEC

#subi found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for subi DEC
try_subiDEC:
addi r4, r29, asm_ins_subiDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addic

#subi DEC found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for addic
try_addic:
addi r4, r29, asm_ins_addic - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addicDEC

#addic found
process_imm_nonstoreload
oris r3, r5, 0x3000
b epilogue_main_asm

#Check for addicDEC
try_addicDEC:
addi r4, r29, asm_ins_addicDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subic

#addic DEC found
process_imm_nonstoreload
oris r3, r5, 0x3000
b epilogue_main_asm

#Check for subic
try_subic:
addi r4, r29, asm_ins_subic - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subicDEC

#subic found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3000
b epilogue_main_asm

#Check for subicDEC
try_subicDEC:
addi r4, r29, asm_ins_subicDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addic_

#subicDEC found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3000
b epilogue_main_asm

#Check for addic.
try_addic_:
addi r4, r29, asm_ins_addic_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addic_DEC

#addic. found
process_imm_nonstoreload
oris r3, r5, 0x3400
b epilogue_main_asm

#Check for addic.DEC
try_addic_DEC:
addi r4, r29, asm_ins_addic_DEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subic_

#addic.DEC found
process_imm_nonstoreload
oris r3, r5, 0x3400
b epilogue_main_asm

#Check for subic.
try_subic_:
addi r4, r29, asm_ins_subic_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subic_DEC

#subic. found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3400
b epilogue_main_asm

#Check for subic.DEC
try_subic_DEC:
addi r4, r29, asm_ins_subic_DEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addis

#subic.DEC found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3400
b epilogue_main_asm

#Check for addis
try_addis:
addi r4, r29, asm_ins_addis - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addisDEC

#addis found
process_addis
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for addisDEC
try_addisDEC:
addi r4, r29, asm_ins_addisDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subis

#addisDEC found
process_imm_nonstoreload
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for subis
try_subis:
addi r4, r29, asm_ins_subis - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subisDEC

#subis found
process_subis
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for subisDEC
try_subisDEC:
addi r4, r29, asm_ins_subisDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addme

#subisDEC found
processSUBTRACT_imm_nonstoreload
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for addme
try_addme:
addi r4, r29, asm_ins_addme - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addme_

#addme found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for addme.
try_addme_:
addi r4, r29, asm_ins_addme_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addmeo

#addme. found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for addmeo
try_addmeo:
addi r4, r29, asm_ins_addmeo - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addmeo_

#addmeo found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for addmeo.
try_addmeo_:
addi r4, r29, asm_ins_addmeo_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addze

#addmeo. found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for addze
try_addze:
addi r4, r29, asm_ins_addze - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addze_

#addze found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for addze.
try_addze_:
addi r4, r29, asm_ins_addze_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addzeo

#addze. found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for addzeo
try_addzeo:
addi r4, r29, asm_ins_addzeo - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addzeo_

#addzeo found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for addzeo.
try_addzeo_:
addi r4, r29, asm_ins_addzeo_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_and

#addzeo. found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for and
try_and:
addi r4, r29, asm_ins_and - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_and_

#and found
process_three_items_logical
lwz r0, 0x14 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for and.
try_and_:
addi r4, r29, asm_ins_and_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andc

#and. found
process_three_items_logical
lwz r0, 0x14 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for andc
try_andc:
addi r4, r29, asm_ins_andc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andc_

#andc found
process_three_items_logical
lwz r0, 0x18 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for andc.
try_andc_:
addi r4, r29, asm_ins_andc_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andi_

#andc. found
process_three_items_logical
lwz r0, 0x18 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for andi.
try_andi_:
addi r4, r29, asm_ins_andi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andis_

#andi. found
process_imm_logical
oris r3, r5, 0x7000
b epilogue_main_asm

#Check for andis.
try_andis_:
addi r4, r29, asm_ins_andis_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_b

#andis. found
process_imm_logical
oris r3, r5, 0x7400
b epilogue_main_asm

#Check for b
try_b:
addi r4, r29, asm_ins_b - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_ba

#b found
process_one_item_branch
oris r3, r5, 0x4800
b epilogue_main_asm

#Check for ba
try_ba:
addi r4, r29, asm_ins_ba - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bl

#ba found
process_one_item_branch
oris r3, r5, 0x4800
ori r3, r3, asm_aa
b epilogue_main_asm

#Check for bl
try_bl:
addi r4, r29, asm_ins_bl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bla

#bl found
process_one_item_branch
oris r3, r5, 0x4800
ori r3, r3, asm_lk
b epilogue_main_asm

#Check for bla
try_bla:
addi r4, r29, asm_ins_bla - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bc

#bla found
process_one_item_branch
oris r3, r5, 0x4800
ori r3, r3, asm_aa | asm_lk
b epilogue_main_asm

#Check for bc
try_bc:
addi r4, r29, asm_ins_bc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bca

#bc found
process_three_items_bcX
oris r3, r5, 0x4000
b epilogue_main_asm

#Check for bca
try_bca:
addi r4, r29, asm_ins_bca - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bcl

#bca found
process_three_items_bcX
oris r3, r5, 0x4000
ori r3, r3, asm_aa
b epilogue_main_asm

#Check for bcl
try_bcl:
addi r4, r29, asm_ins_bcl - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bcla

#bcl found
process_three_items_bcX
oris r3, r5, 0x4000
ori r3, r3, asm_lk
b epilogue_main_asm

#Check for bcla
try_bcla:
addi r4, r29, asm_ins_bcla - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bcctr

#bcla found
process_three_items_bcX
oris r3, r5, 0x4000
ori r3, r3, asm_aa | asm_lk
b epilogue_main_asm

#Check for bcctr
try_bcctr:
addi r4, r29, asm_ins_bcctr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bcctrl

#bcctr found
process_two_items_left_aligned
lwz r0, 0x1C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for bcctrl
try_bcctrl:
addi r4, r29, asm_ins_bcctrl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bclr

#bcctrl found
process_two_items_left_aligned
lwz r0, 0x1C (r29)
or r3, r0, r5
ori r3, r3, asm_lk
b epilogue_main_asm

#Check for bclr
try_bclr:
addi r4, r29, asm_ins_bclr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_bclrl

#bclr found
process_two_items_left_aligned
lwz r0, 0x20 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for bclrl
try_bclrl:
addi r4, r29, asm_ins_bclrl - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmp

#bclrl found
process_two_items_left_aligned
lwz r0, 0x20 (r29)
or r3, r0, r5
ori r3, r3, asm_lk
b epilogue_main_asm

#Check for cmp
try_cmp:
addi r4, r29, asm_ins_cmp - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpi

#cmp found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #L (must be 0)
cmpwi r6, 0
bne- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #rB
cmplwi r8, 31
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21 #TODO REMOVE me, not needed
slwi r7, r7, 16
slwi r8, r8, 11
or r5, r5, r6 #TODO remove, not needed
or r5, r5, r7
or r5, r5, r8
oris r3, r5, 0x7C00
b epilogue_main_asm

#Check for cmpi
try_cmpi:
addi r4, r29, asm_ins_cmpi - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpiDEC

#cmpi found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #L
cmpwi r6, 0
bne- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #SIMM
cmplwi r8, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r8, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r8, r8, 16
slwi r5, r5, 23
slwi r6, r6, 21 #TODO remove me, not needed
slwi r7, r7, 16
or r5, r5, r6 #TODO remove me not needed
or r5, r5, r7
or r5, r5, r8 #No shifting needed for imm
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cmpiDEC
try_cmpiDEC:
addi r4, r29, asm_ins_cmpiDEC - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpl

#cmpiDEC found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #L
cmpwi r6, 0
bne- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #SIMM
cmplwi r8, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r8, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r8, r8, 16
slwi r5, r5, 23
slwi r6, r6, 21 #TODO remove me, not needed
slwi r7, r7, 16
or r5, r5, r6 #TODO remove me not needed
or r5, r5, r7
or r5, r5, r8 #No shifting needed for imm
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cmpl
try_cmpl:
addi r4, r29, asm_ins_cmpl - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpli

#cmpl found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #L (must be 0)
cmpwi r6, 0
bne- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #rB
cmplwi r8, 31
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21 #TODO remove me
slwi r7, r7, 16
slwi r8, r8, 11
or r5, r5, r6 #TODO remove me
or r5, r5, r7
or r5, r5, r8
lwz r0, 0x24 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for cmpli
try_cmpli:
addi r4, r29, asm_ins_cmpli - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpliDEC

#cmpli found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #L
cmpwi r6, 0
bne- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #UIMM
cmplwi r8, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21 #TODO remove me
slwi r7, r7, 16
or r5, r5, r6 #TODO remove me
or r5, r5, r7
or r5, r5, r8
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cmpliDEC
try_cmpliDEC:
addi r4, r29, asm_ins_cmpliDEC - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpw

#cmpliDEC found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #L
cmpwi r6, 0
bne- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r8, 0x14 (sp) #UIMM
cmplwi r8, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21 #TODO remove me
slwi r7, r7, 16
or r5, r5, r6 #TODO remove me
or r5, r5, r7
or r5, r5, r8
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cmpw
try_cmpw:
addi r4, r29, asm_ins_cmpw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmpwi

#cmpw found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmpwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
oris r3, r5, 0x7C00
b epilogue_main_asm

#Check for cmpwi
try_cmpwi:
addi r4, r29, asm_ins_cmpwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmpwiDEC

#cmpwi found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmpwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #SIMM
cmplwi r7, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r7, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r7, r7, 16
slwi r5, r5, 23
slwi r6, r6, 16
or r5, r5, r6
or r5, r5, r7
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cmpwiDEC
try_cmpwiDEC:
addi r4, r29, asm_ins_cmpwiDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmplw

#cmpwiDEC found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmpwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #SIMM
cmplwi r7, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r7, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r7, r7, 16
slwi r5, r5, 23
slwi r6, r6, 16
or r5, r5, r6
or r5, r5, r7
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cmplw
try_cmplw:
addi r4, r29, asm_ins_cmplw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmplwi

#cmplw found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmpwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rB
cmplwi r7, 31
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
lwz r0, 0x24 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for cmplwi
try_cmplwi:
addi r4, r29, asm_ins_cmplwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmplwiDEC

#cmplwi found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmpwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #UIMM
cmplwi r7, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
or r5, r5, r6
or r5, r5, r7 #No shifting needed for UIMM
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cmplwiDEC
try_cmplwiDEC:
addi r4, r29, asm_ins_cmplwiDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmpw_cr0

#cmplwiDEC found
lwz r5, 0x8 (sp) #crF
cmplwi r5, 7
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmpwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #UIMM
cmplwi r7, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
or r5, r5, r6
or r5, r5, r7 #No shifting needed for UIMM
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cr0'd cmpw
try_cmpw_cr0:
addi r4, r29, asm_ins_cmpw_cr0 - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmpwi_cr0

#cr0'd cmpw found
lwz r5, 0x8 (sp) #rA
cmpwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rB
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 16
slwi r6, r6, 11
or r5, r5, r6
oris r3, r5, 0x7C00
b epilogue_main_asm

#Check for cr0'd cmpwi
try_cmpwi_cr0:
addi r4, r29, asm_ins_cmpwi_cr0 - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmpwi_cr0DEC

#cr0'd cmpwi found
lwz r5, 0x8 (sp) #rA
cmpwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #SIMM
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
slwi r5, r5, 16
or r5, r5, r6 #No shifting needed for SIMM
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cr0'd cmpwiDEC
try_cmpwi_cr0DEC:
addi r4, r29, asm_ins_cmpwi_cr0DEC - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmplw_cr0

#cr0'dDEC cmpwi found
lwz r5, 0x8 (sp) #rA
cmpwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #SIMM
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
slwi r5, r5, 16
or r5, r5, r6 #No shifting needed for SIMM
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cr0'd cmplw
try_cmplw_cr0:
addi r4, r29, asm_ins_cmplw_cr0 - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmplwi_cr0

#cr0'd cmplw found
lwz r5, 0x8 (sp) #rA
cmpwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rB
cmplwi r6, 31
bgt- epilogue_error
slwi r5, r5, 16
slwi r6, r6, 11
or r5, r5, r6
lwz r0, 0x24 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for cr0'd cmplwi
try_cmplwi_cr0:
addi r4, r29, asm_ins_cmplwi_cr0 - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmplwi_cr0DEC

#cr0'd cmplwi found
lwz r5, 0x8 (sp) #rA
cmpwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #UIMM
cmplwi r6, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 16
or r5, r5, r6 #No shifting needed for UIMM
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cr0'd cmplwiDEC
try_cmplwi_cr0DEC:
addi r4, r29, asm_ins_cmplwi_cr0DEC - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cntlzw

#cr0'd cmplwi DECfound
lwz r5, 0x8 (sp) #rA
cmpwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #UIMM
cmplwi r6, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 16
or r5, r5, r6 #No shifting needed for UIMM
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cntlzw
try_cntlzw:
addi r4, r29, asm_ins_cntlzw - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cntlzw_

#cntlzw found
process_two_items_logical
lwz r0, 0x28 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for cntlzw.
try_cntlzw_:
addi r4, r29, asm_ins_cntlzw_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_crand

#cntlzw. found
process_two_items_logical
lwz r0, 0x28 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for crand
try_crand:
addi r4, r29, asm_ins_crand - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_crandc

#crand found
process_three_items_left_aligned
lwz r0, 0x2C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crandc
try_crandc:
addi r4, r29, asm_ins_crandc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_creqv

#crandc found
process_three_items_left_aligned
lwz r0, 0x30 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for creqv
try_creqv:
addi r4, r29, asm_ins_creqv - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_crnand

#creqv found
process_three_items_left_aligned
lwz r0, 0x34 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crnand
try_crnand:
addi r4, r29, asm_ins_crnand - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_crnor

#crnand found
process_three_items_left_aligned
lwz r0, 0x38 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crnor
try_crnor:
addi r4, r29, asm_ins_crnor - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cror

#crnor found
process_three_items_left_aligned
lwz r0, 0x3C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for cror
try_cror:
addi r4, r29, asm_ins_cror - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_crorc

#cror found
process_three_items_left_aligned
lwz r0, 0x40 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crorc
try_crorc:
addi r4, r29, asm_ins_crorc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_crxor

#crorc found
process_three_items_left_aligned
lwz r0, 0x44 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crxor
try_crxor:
addi r4, r29, asm_ins_crxor - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_crset

#crxor found
process_three_items_left_aligned
lwz r0, 0x48 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crset
try_crset:
addi r4, r29, asm_ins_crset - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_crnot

#crset found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
mr r6, r5 #all crb's must be equal
mr r7, r5 #all crb's must be equal
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
lwz r0, 0x34 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crnot
try_crnot:
addi r4, r29, asm_ins_crnot - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_crmove

#crnot found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
mr r7, r6 #crbA and crbB must be equal
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
lwz r0, 0x3C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crmove
try_crmove:
addi r4, r29, asm_ins_crmove - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_crclr

#crmove found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
mr r7, r6 #crbA and crbB must be equal
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
lwz r0, 0x40 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for crclr
try_crclr:
addi r4, r29, asm_ins_crclr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_dcbf

#crclr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
mr r6, r5 #all crb's must be equal
mr r7, r5 #all crb's must be equal
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
lwz r0, 0x48 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbf
try_dcbf:
addi r4, r29, asm_ins_dcbf - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_dcbi

#dcbf found
process_two_items_cache
lwz r0, 0x4C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbi
try_dcbi:
addi r4, r29, asm_ins_dcbi - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_dcbst

#dcbi found
process_two_items_cache
lwz r0, 0x50 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbst
try_dcbst:
addi r4, r29, asm_ins_dcbst - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_dcbt

#dcbst found
process_two_items_cache
lwz r0, 0x54 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbt
try_dcbt:
addi r4, r29, asm_ins_dcbt - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_dcbtst

#dcbt found
process_two_items_cache
lwz r0, 0x58 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbtst
try_dcbtst:
addi r4, r29, asm_ins_dcbtst - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_dcbz

#dcbtst found
process_two_items_cache
lwz r0, 0x5C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbz
try_dcbz:
addi r4, r29, asm_ins_dcbz - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_dcbz_l

#dcbz found
process_two_items_cache
lwz r0, 0x60 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for dcbz_l
try_dcbz_l:
addi r4, r29, asm_ins_dcbz_l - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_divw

#dcbz_l found
process_two_items_cache
lwz r0, 0x64 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for divw
try_divw:
addi r4, r29, asm_ins_divw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divw_

#divw found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for divw.
try_divw_:
addi r4, r29, asm_ins_divw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwo

#divw. found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for divwo
try_divwo:
addi r4, r29, asm_ins_divwo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwo_

#divwo found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for divwo.
try_divwo_:
addi r4, r29, asm_ins_divwo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwu

#divwo. found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for divwu
try_divwu:
addi r4, r29, asm_ins_divwu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwu_

#divwu found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for divwu.
try_divwu_:
addi r4, r29, asm_ins_divwu_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwuo

#divwu_ found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for divwuo
try_divwuo:
addi r4, r29, asm_ins_divwuo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwuo_

#divwuo found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for divwuo.
try_divwuo_:
addi r4, r29, asm_ins_divwuo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_eciwx

#divwuo_ found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for eciwx
try_eciwx:
addi r4, r29, asm_ins_eciwx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ecowx

#eciwx found
process_three_items_left_aligned
lwz r0, 0x70 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ecowx
try_ecowx:
addi r4, r29, asm_ins_ecowx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_eieio

#ecowx found
process_three_items_left_aligned
lwz r0, 0x74 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for eieio
try_eieio:
addi r4, r29, asm_ins_eieio - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_eqv

#eieio found
lwz r3, 0x78 (r29)
b epilogue_main_asm

#Check for eqv
try_eqv:
addi r4, r29, asm_ins_eqv - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_eqv_

#eqv found
process_three_items_logical
lwz r0, 0x7C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for eqv.
try_eqv_:
addi r4, r29, asm_ins_eqv_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_extsb

#eqv. found
process_three_items_logical
lwz r0, 0x7C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for extsb
try_extsb:
addi r4, r29, asm_ins_extsb - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_extsb_

#extsb found
process_two_items_logical
lwz r0, 0x80 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for extsb.
try_extsb_:
addi r4, r29, asm_ins_extsb_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_exsth

#extsb. found
process_two_items_logical
lwz r0, 0x80 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for extsh
try_exsth:
addi r4, r29, asm_ins_extsh- asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_extsh_

#extsh found
process_two_items_logical
lwz r0, 0x84 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for extsh.
try_extsh_:
addi r4, r29, asm_ins_extsh_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fabs

#extsh. found
process_two_items_logical
lwz r0, 0x84 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fabs
try_fabs:
addi r4, r29, asm_ins_fabs - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fabs_

#fabs found
process_two_items_left_split
lwz r0, 0x88 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fabs.
try_fabs_:
addi r4, r29, asm_ins_fabs_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fadd

#fabs. found
process_two_items_left_split
lwz r0, 0x88 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fadd
try_fadd:
addi r4, r29, asm_ins_fadd - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fadd_

#fadd found
process_three_items_left_aligned
lwz r0, 0x8C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fadd.
try_fadd_:
addi r4, r29, asm_ins_fadd_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fadds

#fadd. found
process_three_items_left_aligned
lwz r0, 0x8C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fadds
try_fadds:
addi r4, r29, asm_ins_fadds - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fadds_

#fadds found
process_three_items_left_aligned
lwz r0, 0x90 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fadds.
try_fadds_:
addi r4, r29, asm_ins_fadds_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fcmpo

#fadds. found
process_three_items_left_aligned
lwz r0, 0x90 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fcmpo
try_fcmpo:
addi r4, r29, asm_ins_fcmpo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fcmpu

#fcmpo found
process_three_items_compare
lwz r0, 0x94 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fcmpu
try_fcmpu:
addi r4, r29, asm_ins_fcmpu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fctiw

#fcmpu found
process_three_items_compare
oris r3, r5, 0xFC00
b epilogue_main_asm

#Check for fctiw
try_fctiw:
addi r4, r29, asm_ins_fctiw - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fctiw_

#fctiw found
process_two_items_left_split
lwz r0, 0x98 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fctiw.
try_fctiw_:
addi r4, r29, asm_ins_fctiw_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fctiwz

#fctiw. found
process_two_items_left_split
lwz r0, 0x98 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fctiwz
try_fctiwz:
addi r4, r29, asm_ins_fctiwz - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fctiwz_

#fctiwz found
process_two_items_left_split
lwz r0, 0x9C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fctiwz.
try_fctiwz_:
addi r4, r29, asm_ins_fctiwz_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fdiv

#fctiwz. found
process_two_items_left_split
lwz r0, 0x9C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fdiv
try_fdiv:
addi r4, r29, asm_ins_fdiv - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fdiv_

#fdiv found
process_three_items_left_aligned
lwz r0, 0xA0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fdiv.
try_fdiv_:
addi r4, r29, asm_ins_fdiv_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fdivs

#fdiv. found
process_three_items_left_aligned
lwz r0, 0xA0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fdivs
try_fdivs:
addi r4, r29, asm_ins_fdivs - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fdivs_

#fdivs found
process_three_items_left_aligned
lwz r0, 0xA4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fdivs.
try_fdivs_:
addi r4, r29, asm_ins_fdivs_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fmadd

#fdivs. found
process_three_items_left_aligned
lwz r0, 0xA4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmadd
try_fmadd:
addi r4, r29, asm_ins_fmadd - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmadd_

#fmadd found
process_four_items
lwz r0, 0xA8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmadd.
try_fmadd_:
addi r4, r29, asm_ins_fmadd_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmadds

#fmadd. found
process_four_items
lwz r0, 0xA8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmadds
try_fmadds:
addi r4, r29, asm_ins_fmadds - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmadds_

#fmadds found
process_four_items
lwz r0, 0xAC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmadds.
try_fmadds_:
addi r4, r29, asm_ins_fmadds_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmr

#fmadds. found
process_four_items
lwz r0, 0xAC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmr
try_fmr:
addi r4, r29, asm_ins_fmr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fmr_

#fmr found
process_two_items_left_split
lwz r0, 0xB0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmr.
try_fmr_:
addi r4, r29, asm_ins_fmr_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fmsub

#fmr. found
process_two_items_left_split
lwz r0, 0xB0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmsub
try_fmsub:
addi r4, r29, asm_ins_fmsub - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmsub_

#fmsub found
process_four_items
lwz r0, 0xB4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmsub.
try_fmsub_:
addi r4, r29, asm_ins_fmsub_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmsubs

#fmsub. found
process_four_items
lwz r0, 0xB4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmsubs
try_fmsubs:
addi r4, r29, asm_ins_fmsubs - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmsubs_

#fmsubs found
process_four_items
lwz r0, 0xB8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmsubs.
try_fmsubs_:
addi r4, r29, asm_ins_fmsubs_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmul

#fmsubs. found
process_four_items
lwz r0, 0xB8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmul
try_fmul:
addi r4, r29, asm_ins_fmul - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fmul_

#fmul found
process_three_items_leftwo_rightone_split
lwz r0, 0xBC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmul.
try_fmul_:
addi r4, r29, asm_ins_fmul_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fmuls

#fmul. found
process_three_items_leftwo_rightone_split
lwz r0, 0xBC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fmuls
try_fmuls:
addi r4, r29, asm_ins_fmuls - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fmuls_

#fmuls found
process_three_items_leftwo_rightone_split
lwz r0, 0xC0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fmuls.
try_fmuls_:
addi r4, r29, asm_ins_fmuls_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fnabs

#fmuls. found
process_three_items_leftwo_rightone_split
lwz r0, 0xC0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fnabs
try_fnabs:
addi r4, r29, asm_ins_fnabs - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fnabs_

#fnabs found
process_two_items_left_split
lwz r0, 0xC4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fnabs.
try_fnabs_:
addi r4, r29, asm_ins_fnabs_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fneg

#fnabs. found
process_two_items_left_split
lwz r0, 0xC4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fneg
try_fneg:
addi r4, r29, asm_ins_fneg - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fneg_

#fneg found
process_two_items_left_split
lwz r0, 0xC8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fneg.
try_fneg_:
addi r4, r29, asm_ins_fneg_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fnmadd

#fneg. found
process_two_items_left_split
lwz r0, 0xC8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fnmadd
try_fnmadd:
addi r4, r29, asm_ins_fnmadd - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmadd_

#fmmadd found
process_four_items
lwz r0, 0xCC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fnmadd.
try_fnmadd_:
addi r4, r29, asm_ins_fnmadd_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmadds

#fnmadd. found
process_four_items
lwz r0, 0xCC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fnmadds
try_fnmadds:
addi r4, r29, asm_ins_fnmadds - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmadds_

#fmmadds found
process_four_items
lwz r0, 0xD0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fnmadds.
try_fnmadds_:
addi r4, r29, asm_ins_fnmadds_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmsub

#fnmadds. found
process_four_items
lwz r0, 0xD0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fnmsub
try_fnmsub:
addi r4, r29, asm_ins_fnmsub - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmsub_

#fmmsub found
process_four_items
lwz r0, 0xD4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fnmsub.
try_fnmsub_:
addi r4, r29, asm_ins_fnmsub_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmsubs

#fnmsub. found
process_four_items
lwz r0, 0xD4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fnmsubs
try_fnmsubs:
addi r4, r29, asm_ins_fnmsubs - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmsubs_

#fmmsubs found
process_four_items
lwz r0, 0xD8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fnmsubs.
try_fnmsubs_:
addi r4, r29, asm_ins_fnmsubs_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fres

#fnmsubs. found
process_four_items
lwz r0, 0xD8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fres
try_fres:
addi r4, r29, asm_ins_fres - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fres_

#fres found
process_two_items_left_split
lwz r0, 0xDC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fres.
try_fres_:
addi r4, r29, asm_ins_fres_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_frsp

#fres. found
process_two_items_left_split
lwz r0, 0xDC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for frsp
try_frsp:
addi r4, r29, asm_ins_frsp - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_frsp_

#frsp found
process_two_items_left_split
lwz r0, 0xE0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for frsp.
try_frsp_:
addi r4, r29, asm_ins_frsp_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_frsqrte

#frsp. found
process_two_items_left_split
lwz r0, 0xE0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for frsqrte
try_frsqrte:
addi r4, r29, asm_ins_frsqrte - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_frsqrte_

#frsqrte found
process_two_items_left_split
lwz r0, 0xE4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for frsqrte.
try_frsqrte_:
addi r4, r29, asm_ins_frsqrte_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fsel

#frsqrte. found
process_two_items_left_split
lwz r0, 0xE4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fsel
try_fsel:
addi r4, r29, asm_ins_fsel - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fsel_

#fsel found
process_four_items
lwz r0, 0xE8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fsel.
try_fsel_:
addi r4, r29, asm_ins_fsel_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fsub

#fsel. found
process_four_items
lwz r0, 0xE8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fsub
try_fsub:
addi r4, r29, asm_ins_fsub - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fsub_

#fsub found
process_three_items_left_aligned
lwz r0, 0xEC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fsub.
try_fsub_:
addi r4, r29, asm_ins_fsub_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fsubs

#fsub. found
process_three_items_left_aligned
lwz r0, 0xEC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for fsubs
try_fsubs:
addi r4, r29, asm_ins_fsubs - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fsubs_

#fsubs found
process_three_items_left_aligned
lwz r0, 0xF0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for fsubs.
try_fsubs_:
addi r4, r29, asm_ins_fsubs_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_icbi

#fsubs. found
process_three_items_left_aligned
lwz r0, 0xF0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for icbi
try_icbi:
addi r4, r29, asm_ins_icbi - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_isync

#icbi found
process_two_items_cache
lwz r0, 0xF4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for isync
try_isync:
addi r4, r29, asm_ins_isync - asm_table_start
mr r3, r31
li r5, 5
bl memcmp
cmpwi r3, 0
bne- try_lbz

#isync found
lwz r3, 0xF8 (r29)
b epilogue_main_asm

#Check for lbz
try_lbz:
addi r4, r29, asm_ins_lbz - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lbzu

#lbz found
process_imm_storeload
oris r3, r5, 0x8800
b epilogue_main_asm

#Check for lbzu
try_lbzu:
addi r4, r29, asm_ins_lbzu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lbzux

#lbzu found
process_imm_int_load_update
oris r3, r5, 0x8C00
b epilogue_main_asm

#Check for lbzux
try_lbzux:
addi r4, r29, asm_ins_lbzux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lbzx

#lbzux found
process_load_int_updateindex
lwz r0, 0xFC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lbzx
try_lbzx:
addi r4, r29, asm_ins_lbzx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfd

#lbzx found
process_three_items_left_aligned
lwz r0, 0x100 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lfd
try_lfd:
addi r4, r29, asm_ins_lfd - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfdu

#lfd found
process_imm_storeload
oris r3, r5, 0xC800
b epilogue_main_asm

#Check for lfdu
try_lfdu:
addi r4, r29, asm_ins_lfdu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfdux

#lfdu found
process_imm_update_rAneq0
oris r3, r5, 0xCC00
b epilogue_main_asm

#Check for lfdux
try_lfdux:
addi r4, r29, asm_ins_lfdux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfdx

#lfdux found
process_float_or_intstore_updateindex
lwz r0, 0x104 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lfdx
try_lfdx:
addi r4, r29, asm_ins_lfdx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfs

#lfdx found
process_three_items_left_aligned
lwz r0, 0x108 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lfs
try_lfs:
addi r4, r29, asm_ins_lfs - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfsu

#lfs found
process_imm_storeload
oris r3, r5, 0xC000
b epilogue_main_asm

#Check for lfsu
try_lfsu:
addi r4, r29, asm_ins_lfsu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfsux

#lfsu found
process_imm_update_rAneq0
oris r3, r5, 0xC400
b epilogue_main_asm

#Check for lfsux
try_lfsux:
addi r4, r29, asm_ins_lfsux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfsx

#lfsux found
process_float_or_intstore_updateindex
lwz r0, 0x10C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lfsx
try_lfsx:
addi r4, r29, asm_ins_lfsx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lha

#lfsx found
process_three_items_left_aligned
lwz r0, 0x110 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lha
try_lha:
addi r4, r29, asm_ins_lha - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhau

#lha found
process_imm_storeload
oris r3, r5, 0xA800
b epilogue_main_asm

#Check for lhau
try_lhau:
addi r4, r29, asm_ins_lhau - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhaux

#lhau found
process_imm_int_load_update
oris r3, r5, 0xAC00
b epilogue_main_asm

#Check for lhaux
try_lhaux:
addi r4, r29, asm_ins_lhaux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhax

#lhaux found
process_load_int_updateindex
lwz r0, 0x114 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lhax
try_lhax:
addi r4, r29, asm_ins_lhax - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhbrx

#lhax found
process_three_items_left_aligned
lwz r0, 0x118 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lhbrx
try_lhbrx:
addi r4, r29, asm_ins_lhbrx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhz

#lhbrx found
process_three_items_left_aligned
lwz r0, 0x11C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lhz
try_lhz:
addi r4, r29, asm_ins_lhz - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhzu

#lhz found
process_imm_storeload
oris r3, r5, 0xA000
b epilogue_main_asm

#Check for lhzu
try_lhzu:
addi r4, r29, asm_ins_lhzu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhzux

#lhzu found
process_imm_int_load_update
oris r3, r5, 0xA400
b epilogue_main_asm

#Check for lhzux
try_lhzux:
addi r4, r29, asm_ins_lhzux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhzx

#lhzux found
process_load_int_updateindex
lwz r0, 0x120 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lhzx
try_lhzx:
addi r4, r29, asm_ins_lhzx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_li

#lhzx found
process_three_items_left_aligned
lwz r0, 0x124 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for li
try_li:
addi r4, r29, asm_ins_li - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_liDEC

#li found
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #SIMM
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
slwi r5, r5, 21
or r5, r5, r6
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for liDEC
try_liDEC:
addi r4, r29, asm_ins_liDEC - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_lis

#liDEC found
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #SIMM
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
slwi r5, r5, 21
or r5, r5, r6
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for lis
try_lis:
addi r4, r29, asm_ins_lis - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_lisDEC

#lis found
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #UIMM, yes this is UIMM
cmplwi r6, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 21
or r5, r5, r6
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for lisDEC
try_lisDEC:
addi r4, r29, asm_ins_lisDEC - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_lmw

#lisDEC found
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #UIMM, yes this is UIMM
cmplwi r6, 0xFFFF
bgt- epilogue_error
slwi r5, r5, 21
or r5, r5, r6
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for lmw
try_lmw:
addi r4, r29, asm_ins_lmw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lswi

#lmw found
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #rA
cmplwi r7, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #SIMM is in r6!!!
cmplwi r6, 0x7FFF #Yes, We want logical comparison for this
ble+ 0x14
#Make sure 32-bit SIMM is a legit negative 16-bit value (0xFFFF----)
srwi r0, r6, 16
cmplwi r0, 0xFFFF
bne- epilogue_error
clrlwi r6, r6, 16
cmplw r7, r5 #rA cannot be >= to rD
bge- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for SIMM (r6)
or r5, r5, r7
oris r3, r5, 0xB800
b epilogue_main_asm

#Check for lswi
try_lswi:
addi r4, r29, asm_ins_lswi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lswx

#lswi found
#Notice: we CANNOT use a similar check method for lswx, because it's simply impossible to know the value that will be contained within rB itself of lswx
lwz r5, 0x8 (sp) #rD
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp) #rA
cmplwi r6, 31
bgt- epilogue_error
lwz r7, 0x10 (sp) #NB, this is a quasi-immediate value, we know what's in here like knowing the IMM value in a store/load
cmplwi r7, 31
bgt- epilogue_error
#In the case that rA is >= than rD, we need to make sure NB doesn't have a large enough value to cause loaded bytes to spill into rA!
#Fyi Broadway will use an NB value of 32 if it's set to 0 in the instruction!!!!!!!!!
cmplw r5, r6
bgt- asm_start_processing_lswi
mr r12, r7 #Preserve r7 aka NB
cmpwi r12, 0
bne- asm_skip_nb_adjustment
li r12, 32
asm_skip_nb_adjustment:
subf r0, r5, r6
slwi r0, r0, 2 #Mulli by 0x4 for bytes
cmpw r12, r0
bgt- epilogue_error #NB value will cause bytes to spill into rA which is invalid according to the Broadway manual, abort!
asm_start_processing_lswi:
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
lwz r0, 0x128 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lswx
try_lswx:
addi r4, r29, asm_ins_lswx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwarx

#lswx found
process_three_items_left_aligned
lwz r0, 0x12C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lwarx
try_lwarx:
addi r4, r29, asm_ins_lwarx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwbrx

#lwarx found
process_three_items_left_aligned
lwz r0, 0x130 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lwbrx
try_lwbrx:
addi r4, r29, asm_ins_lwbrx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwz

#lwbrx found
process_three_items_left_aligned
lwz r0, 0x134 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lwz
try_lwz:
addi r4, r29, asm_ins_lwz - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwzu

#lwz found
process_imm_storeload
oris r3, r5, 0x8000
b epilogue_main_asm

#Check for lwzu
try_lwzu:
addi r4, r29, asm_ins_lwzu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwzux

#lwzu found
process_imm_int_load_update
oris r3, r5, 0x8400
b epilogue_main_asm

#Check for lwzux
try_lwzux:
addi r4, r29, asm_ins_lwzux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwzx

#lwzux found
process_load_int_updateindex
lwz r0, 0x138 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for lwzx
try_lwzx:
addi r4, r29, asm_ins_lwzx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mcrf

#lwzx found
process_three_items_left_aligned
lwz r0, 0x13C (r29)
or r3, r0, r5
b epilogue_main_asm

####NOTE: This code is so f**king big, that I have to place the following branch destination (epilogue_error) here. If I don't there will be at least 18 instances where the branch to epilogue_error will exceed the 16-bit branch-conditional signed limit (0x7FFC). Holy moly. Placing it close enough to center. Now max branch amounts in the source shouldn't even come close to 0x7FFC.

#Source line cannot be compiled due to bad format or an item was out of range
epilogue_error:
li r3, -4
b epilogue_final

#Check for mcrf
try_mcrf:
addi r4, r29, asm_ins_mcrf - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mcrfs

#mcrf found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 7
cmplwi cr7, r6, 7
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 18
or r5, r5, r6
oris r3, r5, 0x4C00
b epilogue_main_asm

#Check for mcrfs
try_mcrfs:
addi r4, r29, asm_ins_mcrfs - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mcrxr

#mcrfs found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 7
cmplwi cr7, r6, 7
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 18
or r5, r5, r6
lwz r0, 0x140 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mcrxr
try_mcrxr:
addi r4, r29, asm_ins_mcrxr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfcr

#mcrxr found
lwz r5, 0x8 (sp)
cmplwi r5, 7
bgt- epilogue_error
slwi r5, r5, 23
lwz r0, 0x144 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mfcr
try_mfcr:
addi r4, r29, asm_ins_mfcr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mffs

#mfcr found
process_one_item_left_aligned
lwz r0, 0x148 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mffs
try_mffs:
addi r4, r29, asm_ins_mffs - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mffs_

#mffs found
process_one_item_left_aligned
lwz r0, 0x14C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mffs.
try_mffs_:
addi r4, r29, asm_ins_mffs_ - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfmsr

#mffs. found
process_one_item_left_aligned
lwz r0, 0x14C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mfmsr
try_mfmsr:
addi r4, r29, asm_ins_mfmsr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfxer

#mfmsr found
process_one_item_left_aligned
lwz r0, 0x150 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mfxer
try_mfxer:
addi r4, r29, asm_ins_mfxer - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mflr

#mfxer found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1 #Set SPR number to XER
b proceed_mfspr #finish off SPR operations

#Check for mflr
try_mflr:
addi r4, r29, asm_ins_mflr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfctr

#mflr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 8 #Set SPR number to LR
b proceed_mfspr #finish off SPR operations

#Check for mfctr
try_mfctr:
addi r4, r29, asm_ins_mfctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdsisr

#mfctr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 9 #Set SPR number to CTR
b proceed_mfspr #finish off SPR operations

try_mfdsisr:
addi r4, r29, asm_ins_mfdsisr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdar

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 18
b proceed_mfspr

try_mfdar:
addi r4, r29, asm_ins_mfdar - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdec

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 19
b proceed_mfspr

try_mfdec:
addi r4, r29, asm_ins_mfdec - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsdr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 22
b proceed_mfspr

try_mfsdr1:
addi r4, r29, asm_ins_mfsdr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsrr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 25
b proceed_mfspr

try_mfsrr0:
addi r4, r29, asm_ins_mfsrr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsrr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 26
b proceed_mfspr

try_mfsrr1:
addi r4, r29, asm_ins_mfsrr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsprg0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 27
b proceed_mfspr

try_mfsprg0:
addi r4, r29, asm_ins_mfsprg0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsprg1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 272
b proceed_mfspr

try_mfsprg1:
addi r4, r29, asm_ins_mfsprg1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsprg2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 273
b proceed_mfspr

try_mfsprg2:
addi r4, r29, asm_ins_mfsprg2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsprg3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 274
b proceed_mfspr

try_mfsprg3:
addi r4, r29, asm_ins_mfsprg3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfear

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 275
b proceed_mfspr

try_mfear:
addi r4, r29, asm_ins_mfear - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfpvr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 282
b proceed_mfspr

try_mfpvr:
addi r4, r29, asm_ins_mfpvr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat0u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 287
b proceed_mfspr

try_mfibat0u:
addi r4, r29, asm_ins_mfibat0u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat0l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 528
b proceed_mfspr

try_mfibat0l:
addi r4, r29, asm_ins_mfibat0l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat1u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 529
b proceed_mfspr

try_mfibat1u:
addi r4, r29, asm_ins_mfibat1u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat1l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 530
b proceed_mfspr

try_mfibat1l:
addi r4, r29, asm_ins_mfibat1l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat2u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 531
b proceed_mfspr

try_mfibat2u:
addi r4, r29, asm_ins_mfibat2u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat2l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 532
b proceed_mfspr

try_mfibat2l:
addi r4, r29, asm_ins_mfibat2l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat3u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 533
b proceed_mfspr

try_mfibat3u:
addi r4, r29, asm_ins_mfibat3u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat3l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 534
b proceed_mfspr

try_mfibat3l:
addi r4, r29, asm_ins_mfibat3l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat4u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 535
b proceed_mfspr

try_mfibat4u:
addi r4, r29, asm_ins_mfibat4u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat4l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 560
b proceed_mfspr

try_mfibat4l:
addi r4, r29, asm_ins_mfibat4l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat5u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 561
b proceed_mfspr

try_mfibat5u:
addi r4, r29, asm_ins_mfibat5u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat5l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 562
b proceed_mfspr

try_mfibat5l:
addi r4, r29, asm_ins_mfibat5l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat6u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 563
b proceed_mfspr

try_mfibat6u:
addi r4, r29, asm_ins_mfibat6u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat6l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 564
b proceed_mfspr

try_mfibat6l:
addi r4, r29, asm_ins_mfibat6l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat7u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 565
b proceed_mfspr

try_mfibat7u:
addi r4, r29, asm_ins_mfibat7u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfibat7l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 566
b proceed_mfspr

try_mfibat7l:
addi r4, r29, asm_ins_mfibat7l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat0u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 567
b proceed_mfspr

try_mfdbat0u:
addi r4, r29, asm_ins_mfdbat0u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat0l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 536
b proceed_mfspr

try_mfdbat0l:
addi r4, r29, asm_ins_mfdbat0l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat1u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 537
b proceed_mfspr

try_mfdbat1u:
addi r4, r29, asm_ins_mfdbat1u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat1l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 538
b proceed_mfspr

try_mfdbat1l:
addi r4, r29, asm_ins_mfdbat1l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat2u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 539
b proceed_mfspr

try_mfdbat2u:
addi r4, r29, asm_ins_mfdbat2u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat2l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 540
b proceed_mfspr

try_mfdbat2l:
addi r4, r29, asm_ins_mfdbat2l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat3u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 541
b proceed_mfspr

try_mfdbat3u:
addi r4, r29, asm_ins_mfdbat3u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat3l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 542
b proceed_mfspr

try_mfdbat3l:
addi r4, r29, asm_ins_mfdbat3l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat4u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 543
b proceed_mfspr

try_mfdbat4u:
addi r4, r29, asm_ins_mfdbat4u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat4l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 568
b proceed_mfspr

try_mfdbat4l:
addi r4, r29, asm_ins_mfdbat4l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat5u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 569
b proceed_mfspr

try_mfdbat5u:
addi r4, r29, asm_ins_mfdbat5u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat5l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 570
b proceed_mfspr

try_mfdbat5l:
addi r4, r29, asm_ins_mfdbat5l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat6u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 571
b proceed_mfspr

try_mfdbat6u:
addi r4, r29, asm_ins_mfdbat6u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat6l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 572
b proceed_mfspr

try_mfdbat6l:
addi r4, r29, asm_ins_mfdbat6l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat7u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 573
b proceed_mfspr

try_mfdbat7u:
addi r4, r29, asm_ins_mfdbat7u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdbat7l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 574
b proceed_mfspr

try_mfdbat7l:
addi r4, r29, asm_ins_mfdbat7l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 575
b proceed_mfspr

try_mfgqr0:
addi r4, r29, asm_ins_mfgqr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 912
b proceed_mfspr

try_mfgqr1:
addi r4, r29, asm_ins_mfgqr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 913
b proceed_mfspr

try_mfgqr2:
addi r4, r29, asm_ins_mfgqr2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 914
b proceed_mfspr

try_mfgqr3:
addi r4, r29, asm_ins_mfgqr3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 915
b proceed_mfspr

try_mfgqr4:
addi r4, r29, asm_ins_mfgqr4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr5

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 916
b proceed_mfspr

try_mfgqr5:
addi r4, r29, asm_ins_mfgqr5 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr6

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 917
b proceed_mfspr

try_mfgqr6:
addi r4, r29, asm_ins_mfgqr6 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfgqr7

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 918
b proceed_mfspr

try_mfgqr7:
addi r4, r29, asm_ins_mfgqr7 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfhid2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 919
b proceed_mfspr

try_mfhid2:
addi r4, r29, asm_ins_mfhid2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfwpar

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 920
b proceed_mfspr

try_mfwpar:
addi r4, r29, asm_ins_mfwpar - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdma_u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 921
b proceed_mfspr

try_mfdma_u:
addi r4, r29, asm_ins_mfdma_u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdma_l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 922
b proceed_mfspr

try_mfdma_l:
addi r4, r29, asm_ins_mfdma_l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfcidh

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 923
b proceed_mfspr

try_mfcidh:
addi r4, r29, asm_ins_mfcidh - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfcidm

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 925
b proceed_mfspr

try_mfcidm:
addi r4, r29, asm_ins_mfcidm - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfcidl

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 926
b proceed_mfspr

try_mfcidl:
addi r4, r29, asm_ins_mfcidl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfummcr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 927
b proceed_mfspr

try_mfummcr0:
addi r4, r29, asm_ins_mfummcr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfupmc1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 936
b proceed_mfspr

try_mfupmc1:
addi r4, r29, asm_ins_mfupmc1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfupmc2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 937
b proceed_mfspr

try_mfupmc2:
addi r4, r29, asm_ins_mfupmc2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfusia

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 938
b proceed_mfspr

try_mfusia:
addi r4, r29, asm_ins_mfusia - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfummcr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 939
b proceed_mfspr

try_mfummcr1:
addi r4, r29, asm_ins_mfummcr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfupmc3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 940
b proceed_mfspr

try_mfupmc3:
addi r4, r29, asm_ins_mfupmc3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfupmc4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 941
b proceed_mfspr

try_mfupmc4:
addi r4, r29, asm_ins_mfupmc4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfusda

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 942
b proceed_mfspr

try_mfusda:
addi r4, r29, asm_ins_mfusda - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfmmcr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 943
b proceed_mfspr

try_mfmmcr0:
addi r4, r29, asm_ins_mfmmcr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfpmc1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 952
b proceed_mfspr

try_mfpmc1:
addi r4, r29, asm_ins_mfpmc1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfpmc2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 953
b proceed_mfspr

try_mfpmc2:
addi r4, r29, asm_ins_mfpmc2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsia

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 954
b proceed_mfspr

try_mfsia:
addi r4, r29, asm_ins_mfsia - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfmmcr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 955
b proceed_mfspr

try_mfmmcr1:
addi r4, r29, asm_ins_mfmmcr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfpmc3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 956
b proceed_mfspr

try_mfpmc3:
addi r4, r29, asm_ins_mfpmc3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfpmc4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 957
b proceed_mfspr

try_mfpmc4:
addi r4, r29, asm_ins_mfpmc4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfsda

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 958
b proceed_mfspr

try_mfsda:
addi r4, r29, asm_ins_mfsda - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfhid0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 959
b proceed_mfspr

try_mfhid0:
addi r4, r29, asm_ins_mfhid0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfhid1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1008
b proceed_mfspr

try_mfhid1:
addi r4, r29, asm_ins_mfhid1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfiabr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1009
b proceed_mfspr

try_mfiabr:
addi r4, r29, asm_ins_mfiabr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfhid4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1010
b proceed_mfspr

try_mfhid4:
addi r4, r29, asm_ins_mfhid4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mftdcl

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1011
b proceed_mfspr

try_mftdcl:
addi r4, r29, asm_ins_mftdcl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfdabr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1012
b proceed_mfspr

try_mfdabr:
addi r4, r29, asm_ins_mfdabr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfl2cr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1013
b proceed_mfspr

try_mfl2cr:
addi r4, r29, asm_ins_mfl2cr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mftdch

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1017
b proceed_mfspr

try_mftdch:
addi r4, r29, asm_ins_mftdch - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfictc

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1018
b proceed_mfspr

try_mfictc:
addi r4, r29, asm_ins_mfictc - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfthrm1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1019
b proceed_mfspr

try_mfthrm1:
addi r4, r29, asm_ins_mfthrm1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfthrm2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1020
b proceed_mfspr

try_mfthrm2:
addi r4, r29, asm_ins_mfthrm2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfthrm3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1021
b proceed_mfspr

try_mfthrm3:
addi r4, r29, asm_ins_mfthrm3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfspr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1022
b proceed_mfspr

#Check for mfspr
try_mfspr:
addi r4, r29, asm_ins_mfspr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mfsr

#mfspr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lwz r6, 0xC (sp)
#Start massive spr # checks. Fyi list is slightly diff than mtspr!
cmpwi r6, 1
beq- proceed_mfspr
cmpwi r6, 8
beq- proceed_mfspr
cmpwi r6, 9
beq- proceed_mfspr
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
bne- epilogue_error
#SPR number is good. Proceed.
proceed_mfspr:
rlwinm r7, r6, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r6, r6, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r6
or r6, r7, r6 #OR them together to complete SPR field
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x154 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mfsr
try_mfsr:
addi r4, r29, asm_ins_mfsr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mfsrin

#mfsr found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 15
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
or r5, r5, r6
lwz r0, 0x158 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mfsrin
try_mfsrin:
addi r4, r29, asm_ins_mfsrin - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mftb

#mfsrin found
process_two_items_left_split
lwz r0, 0x15C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mftb
try_mftb:
addi r4, r29, asm_ins_mftb - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mftb_simp

#mftb found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
bgt- epilogue_error
cmpwi r6, 268
cmpwi cr7, r6, 269
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+eq
bne- epilogue_error #Error if r6 isn't equal to 268 or 269
rlwinm r7, r6, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r6, r6, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r6
or r6, r7, r6 #OR them together to complete SPR field
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x160 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mftb simplified (no SPR field)
try_mftb_simp:
addi r4, r29, asm_ins_mftb_simp - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mftbl

#mftb simplified found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 268 #Set TBL SPR number
rlwinm r7, r6, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r6, r6, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r6
or r6, r7, r6 #OR them together to complete SPR field
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x160 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mftbl
try_mftbl:
addi r4, r29, asm_ins_mftbl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mftbu

#mftbl found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 268 #Set TBL SPR number
rlwinm r7, r6, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r6, r6, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r6
or r6, r7, r6 #OR them together to complete SPR field
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x160 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mftbu
try_mftbu:
addi r4, r29, asm_ins_mftbu - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mr

#mftbu found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 269 #Set TBU SPR number
rlwinm r7, r6, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r6, r6, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r6
or r6, r7, r6 #OR them together to complete SPR field
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x160 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mr
try_mr:
addi r4, r29, asm_ins_mr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mr_

#mr found
process_simpilified_logical_two_items
lwz r0, 0x1A0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mr.
try_mr_:
addi r4, r29, asm_ins_mr_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtcrf

#mr. found
process_simpilified_logical_two_items
lwz r0, 0x1A0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mtcrf
try_mtcrf:
addi r4, r29, asm_ins_mtcrf - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtcr

#mtcrf found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 255
cmplwi r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 12
slwi r6, r6, 21
or r5, r5, r6
lwz r0, 0x164 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtcr
try_mtcr:
addi r4, r29, asm_ins_mtcr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsb0

#mtcr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 0xFF
slwi r6, r6, 12
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x164 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtfsb0
try_mtfsb0:
addi r4, r29, asm_ins_mtfsb0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsb0_

#mtsfb0 found
process_one_item_left_aligned
lwz r0, 0x168 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtfsb0.
try_mtfsb0_:
addi r4, r29, asm_ins_mtfsb0_ - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsb1

#mtfsb0. found
process_one_item_left_aligned
lwz r0, 0x168 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mtfsb1
try_mtfsb1:
addi r4, r29, asm_ins_mtfsb1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsb1_

#mtfsb1 found
process_one_item_left_aligned
lwz r0, 0x16C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtfsb1.
try_mtfsb1_:
addi r4, r29, asm_ins_mtfsb1_ - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsf

#mtfsb1. found
process_one_item_left_aligned
lwz r0, 0x16C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mtfsf
try_mtfsf:
addi r4, r29, asm_ins_mtfsf - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtfsf_

#mtfsf found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 255
cmplwi r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 17
slwi r6, r6, 11
or r5, r5, r6
lwz r0, 0x170 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtfsf.
try_mtfsf_:
addi r4, r29, asm_ins_mtfsf_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtfsfi

#mtfsf. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 255
cmplwi r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 17
slwi r6, r6, 11
or r5, r5, r6
lwz r0, 0x170 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mtfsfi
try_mtfsfi:
addi r4, r29, asm_ins_mtfsfi - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtfsfi_

#mtfsfi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 7
cmplwi r6, 15
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 12
or r5, r5, r6
lwz r0, 0x174 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtfsfi.
try_mtfsfi_:
addi r4, r29, asm_ins_mtfsfi_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtmsr

#mtfsfi. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 7
cmplwi r6, 15
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 12
or r5, r5, r6
lwz r0, 0x174 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mtmsr
try_mtmsr:
addi r4, r29, asm_ins_mtmsr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtxer

#mtmsr found
process_one_item_left_aligned
lwz r0, 0x178 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtxer
try_mtxer:
addi r4, r29, asm_ins_mtxer - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtlr

#mtxer found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1
b continue_spr_operations_mtspr #Proceed with SPR operations

#Check for mtlr
try_mtlr:
addi r4, r29, asm_ins_mtlr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtctr

#mtlr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 8
b continue_spr_operations_mtspr #Proceed with SPR operations

#Check for mtctr
try_mtctr:
addi r4, r29, asm_ins_mtctr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdsisr

#mtctr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 9
b continue_spr_operations_mtspr #Proceed with SPR operations

try_mtdsisr:
addi r4, r29, asm_ins_mtdsisr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdar

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 18
b continue_spr_operations_mtspr

try_mtdar:
addi r4, r29, asm_ins_mtdar - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdec

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 19
b continue_spr_operations_mtspr

try_mtdec:
addi r4, r29, asm_ins_mtdec - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsdr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 22
b continue_spr_operations_mtspr

try_mtsdr1:
addi r4, r29, asm_ins_mtsdr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsrr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 25
b continue_spr_operations_mtspr

try_mtsrr0:
addi r4, r29, asm_ins_mtsrr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsrr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 26
b continue_spr_operations_mtspr

try_mtsrr1:
addi r4, r29, asm_ins_mtsrr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsprg0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 27
b continue_spr_operations_mtspr

try_mtsprg0:
addi r4, r29, asm_ins_mtsprg0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsprg1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 272
b continue_spr_operations_mtspr

try_mtsprg1:
addi r4, r29, asm_ins_mtsprg1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsprg2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 273
b continue_spr_operations_mtspr

try_mtsprg2:
addi r4, r29, asm_ins_mtsprg2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsprg3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 274
b continue_spr_operations_mtspr

try_mtsprg3:
addi r4, r29, asm_ins_mtsprg3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtear

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 275
b continue_spr_operations_mtspr

try_mtear:
addi r4, r29, asm_ins_mtear - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mttbl

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 282
b continue_spr_operations_mtspr

try_mttbl:
addi r4, r29, asm_ins_mttbl - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mttbu

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 284
b continue_spr_operations_mtspr

try_mttbu:
addi r4, r29, asm_ins_mttbu - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat0u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 285
b continue_spr_operations_mtspr

try_mtibat0u:
addi r4, r29, asm_ins_mtibat0u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat0l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 528
b continue_spr_operations_mtspr

try_mtibat0l:
addi r4, r29, asm_ins_mtibat0l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat1u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 529
b continue_spr_operations_mtspr

try_mtibat1u:
addi r4, r29, asm_ins_mtibat1u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat1l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 530
b continue_spr_operations_mtspr

try_mtibat1l:
addi r4, r29, asm_ins_mtibat1l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat2u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 531
b continue_spr_operations_mtspr

try_mtibat2u:
addi r4, r29, asm_ins_mtibat2u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat2l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 532
b continue_spr_operations_mtspr

try_mtibat2l:
addi r4, r29, asm_ins_mtibat2l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat3u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 533
b continue_spr_operations_mtspr

try_mtibat3u:
addi r4, r29, asm_ins_mtibat3u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat3l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 534
b continue_spr_operations_mtspr

try_mtibat3l:
addi r4, r29, asm_ins_mtibat3l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat4u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 535
b continue_spr_operations_mtspr

try_mtibat4u:
addi r4, r29, asm_ins_mtibat4u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat4l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 560
b continue_spr_operations_mtspr

try_mtibat4l:
addi r4, r29, asm_ins_mtibat4l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat5u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 561
b continue_spr_operations_mtspr

try_mtibat5u:
addi r4, r29, asm_ins_mtibat5u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat5l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 562
b continue_spr_operations_mtspr

try_mtibat5l:
addi r4, r29, asm_ins_mtibat5l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat6u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 563
b continue_spr_operations_mtspr

try_mtibat6u:
addi r4, r29, asm_ins_mtibat6u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat6l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 564
b continue_spr_operations_mtspr

try_mtibat6l:
addi r4, r29, asm_ins_mtibat6l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat7u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 565
b continue_spr_operations_mtspr

try_mtibat7u:
addi r4, r29, asm_ins_mtibat7u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtibat7l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 566
b continue_spr_operations_mtspr

try_mtibat7l:
addi r4, r29, asm_ins_mtibat7l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat0u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 567
b continue_spr_operations_mtspr

try_mtdbat0u:
addi r4, r29, asm_ins_mtdbat0u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat0l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 536
b continue_spr_operations_mtspr

try_mtdbat0l:
addi r4, r29, asm_ins_mtdbat0l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat1u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 537
b continue_spr_operations_mtspr

try_mtdbat1u:
addi r4, r29, asm_ins_mtdbat1u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat1l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 538
b continue_spr_operations_mtspr

try_mtdbat1l:
addi r4, r29, asm_ins_mtdbat1l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat2u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 539
b continue_spr_operations_mtspr

try_mtdbat2u:
addi r4, r29, asm_ins_mtdbat2u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat2l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 540
b continue_spr_operations_mtspr

try_mtdbat2l:
addi r4, r29, asm_ins_mtdbat2l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat3u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 541
b continue_spr_operations_mtspr

try_mtdbat3u:
addi r4, r29, asm_ins_mtdbat3u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat3l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 542
b continue_spr_operations_mtspr

try_mtdbat3l:
addi r4, r29, asm_ins_mtdbat3l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat4u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 543
b continue_spr_operations_mtspr

try_mtdbat4u:
addi r4, r29, asm_ins_mtdbat4u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat4l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 568
b continue_spr_operations_mtspr

try_mtdbat4l:
addi r4, r29, asm_ins_mtdbat4l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat5u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 569
b continue_spr_operations_mtspr

try_mtdbat5u:
addi r4, r29, asm_ins_mtdbat5u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat5l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 570
b continue_spr_operations_mtspr

try_mtdbat5l:
addi r4, r29, asm_ins_mtdbat5l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat6u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 571
b continue_spr_operations_mtspr

try_mtdbat6u:
addi r4, r29, asm_ins_mtdbat6u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat6l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 572
b continue_spr_operations_mtspr

try_mtdbat6l:
addi r4, r29, asm_ins_mtdbat6l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat7u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 573
b continue_spr_operations_mtspr

try_mtdbat7u:
addi r4, r29, asm_ins_mtdbat7u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdbat7l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 574
b continue_spr_operations_mtspr

try_mtdbat7l:
addi r4, r29, asm_ins_mtdbat7l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 575
b continue_spr_operations_mtspr

try_mtgqr0:
addi r4, r29, asm_ins_mtgqr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 912
b continue_spr_operations_mtspr

try_mtgqr1:
addi r4, r29, asm_ins_mtgqr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 913
b continue_spr_operations_mtspr

try_mtgqr2:
addi r4, r29, asm_ins_mtgqr2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 914
b continue_spr_operations_mtspr

try_mtgqr3:
addi r4, r29, asm_ins_mtgqr3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 915
b continue_spr_operations_mtspr

try_mtgqr4:
addi r4, r29, asm_ins_mtgqr4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr5

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 916
b continue_spr_operations_mtspr

try_mtgqr5:
addi r4, r29, asm_ins_mtgqr5 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr6

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 917
b continue_spr_operations_mtspr

try_mtgqr6:
addi r4, r29, asm_ins_mtgqr6 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtgqr7

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 918
b continue_spr_operations_mtspr

try_mtgqr7:
addi r4, r29, asm_ins_mtgqr7 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mthid2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 919
b continue_spr_operations_mtspr

try_mthid2:
addi r4, r29, asm_ins_mthid2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtwpar

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 920
b continue_spr_operations_mtspr

try_mtwpar:
addi r4, r29, asm_ins_mtwpar - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdma_u

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 921
b continue_spr_operations_mtspr

try_mtdma_u:
addi r4, r29, asm_ins_mtdma_u - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdma_l

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 922
b continue_spr_operations_mtspr

try_mtdma_l:
addi r4, r29, asm_ins_mtdma_l - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtummcr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 923
b continue_spr_operations_mtspr

try_mtummcr0:
addi r4, r29, asm_ins_mtummcr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtupmc1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 936
b continue_spr_operations_mtspr

try_mtupmc1:
addi r4, r29, asm_ins_mtupmc1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtupmc2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 937
b continue_spr_operations_mtspr

try_mtupmc2:
addi r4, r29, asm_ins_mtupmc2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtusia

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 938
b continue_spr_operations_mtspr

try_mtusia:
addi r4, r29, asm_ins_mtusia - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtummcr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 939
b continue_spr_operations_mtspr

try_mtummcr1:
addi r4, r29, asm_ins_mtummcr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtupmc3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 940
b continue_spr_operations_mtspr

try_mtupmc3:
addi r4, r29, asm_ins_mtupmc3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtupmc4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 941
b continue_spr_operations_mtspr

try_mtupmc4:
addi r4, r29, asm_ins_mtupmc4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtusda

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 942
b continue_spr_operations_mtspr

try_mtusda:
addi r4, r29, asm_ins_mtusda - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtmmcr0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 943
b continue_spr_operations_mtspr

try_mtmmcr0:
addi r4, r29, asm_ins_mtmmcr0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtpmc1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 952
b continue_spr_operations_mtspr

try_mtpmc1:
addi r4, r29, asm_ins_mtpmc1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtpmc2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 953
b continue_spr_operations_mtspr

try_mtpmc2:
addi r4, r29, asm_ins_mtpmc2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsia

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 954
b continue_spr_operations_mtspr

try_mtsia:
addi r4, r29, asm_ins_mtsia - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtmmcr1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 955
b continue_spr_operations_mtspr

try_mtmmcr1:
addi r4, r29, asm_ins_mtmmcr1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtpmc3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 956
b continue_spr_operations_mtspr

try_mtpmc3:
addi r4, r29, asm_ins_mtpmc3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtpmc4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 957
b continue_spr_operations_mtspr

try_mtpmc4:
addi r4, r29, asm_ins_mtpmc4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtsda

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 958
b continue_spr_operations_mtspr

try_mtsda:
addi r4, r29, asm_ins_mtsda - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mthid0

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 959
b continue_spr_operations_mtspr

try_mthid0:
addi r4, r29, asm_ins_mthid0 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mthid1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1008
b continue_spr_operations_mtspr

try_mthid1:
addi r4, r29, asm_ins_mthid1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtiabr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1009
b continue_spr_operations_mtspr

try_mtiabr:
addi r4, r29, asm_ins_mtiabr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mthid4

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1010
b continue_spr_operations_mtspr

try_mthid4:
addi r4, r29, asm_ins_mthid4 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtdabr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1011
b continue_spr_operations_mtspr

try_mtdabr:
addi r4, r29, asm_ins_mtdabr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtl2cr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1013
b continue_spr_operations_mtspr

try_mtl2cr:
addi r4, r29, asm_ins_mtl2cr - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtictc

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1017
b continue_spr_operations_mtspr

try_mtictc:
addi r4, r29, asm_ins_mtictc - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtthrm1

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1019
b continue_spr_operations_mtspr

try_mtthrm1:
addi r4, r29, asm_ins_mtthrm1 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtthrm2

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1020
b continue_spr_operations_mtspr

try_mtthrm2:
addi r4, r29, asm_ins_mtthrm2 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtthrm3

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1021
b continue_spr_operations_mtspr

try_mtthrm3:
addi r4, r29, asm_ins_mtthrm3 - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtspr

lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 1022

#Finishing touches to mtspr simplified mnemonics
continue_spr_operations_mtspr:
rlwinm r7, r6, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r6, r6, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r5
or r6, r7, r6 #OR them together to complete SPR field
slwi r5, r5, 21
or r5, r5, r6
lwz r0, 0x17C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtspr
try_mtspr:
addi r4, r29, asm_ins_mtspr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtsr

#mtspr found
lwz r5, 0x8 (sp)
#Start massive spr # checks
cmpwi r5, 1
beq- proceed_mtspr
cmpwi r5, 8
beq- proceed_mtspr
cmpwi r5, 9
beq- proceed_mtspr
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
bne- epilogue_error
#SPR checks out, proceed
proceed_mtspr:
lwz r6, 0xC (sp)
cmplwi r6, 31
bgt- epilogue_error
rlwinm r7, r5, 6, 16, 20 #Place SPR field 5-9 bits into bits 16 thru 20 of r7
rlwinm r5, r5, 16, 11, 15 #Place SPR field 0-4 bits into bits 11 thru 15 of r5
or r5, r7, r5 #OR them together to complete SPR field
slwi r6, r6, 21
or r5, r5, r6
lwz r0, 0x17C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check fo mtsr
try_mtsr:
addi r4, r29, asm_ins_mtsr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtsrin

#mtsr found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 15
cmplwi r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16
slwi r6, r6, 21
or r5, r5, r6
lwz r0, 0x180 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mtsrin
try_mtsrin:
addi r4, r29, asm_ins_mtsrin - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mulhw

#mtsrin found
process_two_items_left_split
lwz r0, 0x184 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mulhw
try_mulhw:
addi r4, r29, asm_ins_mulhw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulhw_

#mulhw found
process_three_items_left_aligned
lwz r0, 0x188 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mulhw.
try_mulhw_:
addi r4, r29, asm_ins_mulhw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulhwu

#mulhw. found
process_three_items_left_aligned
lwz r0, 0x188 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mulhwu
try_mulhwu:
addi r4, r29, asm_ins_mulhwu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulhwu_

#mulhwu found
process_three_items_left_aligned
lwz r0, 0x18C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mulhwu.
try_mulhwu_:
addi r4, r29, asm_ins_mulhwu_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulli

#mulhwu. found
process_three_items_left_aligned
lwz r0, 0x18C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mulli
try_mulli:
addi r4, r29, asm_ins_mulli - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulliDEC

#mulli found
process_imm_nonstoreload
oris r3, r5, 0x1C00
b epilogue_main_asm

#Check for mulliDEC
try_mulliDEC:
addi r4, r29, asm_ins_mulliDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullw

#mulli DECfound
process_imm_nonstoreload
oris r3, r5, 0x1C00
b epilogue_main_asm

#Check for mullw
try_mullw:
addi r4, r29, asm_ins_mullw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullw_

#mullw found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mullw.
try_mullw_:
addi r4, r29, asm_ins_mullw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullwo

#mullw. found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for mullwo
try_mullwo:
addi r4, r29, asm_ins_mullwo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullwo_

#mullwo found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for mullwo.
try_mullwo_:
addi r4, r29, asm_ins_mullwo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_nand

#mullwo. found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for nand
try_nand:
addi r4, r29, asm_ins_nand - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_nand_

#nand found
process_three_items_logical
lwz r0, 0x194 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for nand.
try_nand_:
addi r4, r29, asm_ins_nand_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_neg

#nand. found
process_three_items_logical
lwz r0, 0x194 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for neg
try_neg:
addi r4, r29, asm_ins_neg - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_neg_

#neg found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for neg.
try_neg_:
addi r4, r29, asm_ins_neg_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_nego

#neg. found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for nego
try_nego:
addi r4, r29, asm_ins_nego - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_nego_

#nego found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for nego.
try_nego_:
addi r4, r29, asm_ins_nego_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_nop

#nego. found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for nop
try_nop:
addi r4, r29, asm_ins_nop - asm_table_start
mr r3, r31
li r5, 3
bl memcmp
cmpwi r3, 0
bne- try_nor

#Nop found
lis r3, 0x6000
b epilogue_main_asm

#Check for nor
try_nor:
addi r4, r29, asm_ins_nor - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_nor_

#nor found
process_three_items_logical
lwz r0, 0x19C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check fo nor.
try_nor_:
addi r4, r29, asm_ins_nor_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_not

#nor. found
process_three_items_logical
lwz r0, 0x19C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for not
try_not:
addi r4, r29, asm_ins_not - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_not_

#not found
process_simpilified_logical_two_items
lwz r0, 0x19C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for not.
try_not_:
addi r4, r29, asm_ins_not_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_or

#not. found
process_simpilified_logical_two_items
lwz r0, 0x19C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for or
try_or:
addi r4, r29, asm_ins_or - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_or_

#or found
process_three_items_logical
lwz r0, 0x1A0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for or.
try_or_:
addi r4, r29, asm_ins_or_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_orc

#or. found
process_three_items_logical
lwz r0, 0x1A0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for orc
try_orc:
addi r4, r29, asm_ins_orc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_orc_

#orc found
process_three_items_logical
lwz r0, 0x1A4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for orc.
try_orc_:
addi r4, r29, asm_ins_orc_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ori

#orc. found
process_three_items_logical
lwz r0, 0x1A4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ori
try_ori:
addi r4, r29, asm_ins_ori - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_oris

#ori found
process_imm_logical
oris r3, r5, 0x6000
b epilogue_main_asm

#Check for oris
try_oris:
addi r4, r29, asm_ins_oris - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_psq_l

#oris found
process_imm_logical
oris r3, r5, 0x6400
b epilogue_main_asm

#Check for psq_l
try_psq_l:
addi r4, r29, asm_ins_psq_l - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_lu

#psq_l found
process_imm_psq
oris r3, r5, 0xE000
b epilogue_main_asm

#Check for psq_lu
try_psq_lu:
addi r4, r29, asm_ins_psq_lu - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_lux

#psq_lu found
process_imm_psq_update
oris r3, r5, 0xE400
b epilogue_main_asm

#Check for psq_lux
try_psq_lux:
addi r4, r29, asm_ins_psq_lux - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_lx

#psq_lux found
process_nonimm_psq_updateindex
lwz r0, 0x1A8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for psq_lx
try_psq_lx:
addi r4, r29, asm_ins_psq_lx - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_st

#psq_lx found
process_nonimm_psq
lwz r0, 0x1AC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for psq_st
try_psq_st:
addi r4, r29, asm_ins_psq_st - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_stu

#psq_st found
process_imm_psq
oris r3, r5, 0xF000
b epilogue_main_asm

#Check for psq_stu
try_psq_stu:
addi r4, r29, asm_ins_psq_stu - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_stux

#psq_stu found
process_imm_psq_update
oris r3, r5, 0xF400
b epilogue_main_asm

#Check for psq_stux
try_psq_stux:
addi r4, r29, asm_ins_psq_stux - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_stx

#psq_stux found
process_nonimm_psq_updateindex
lwz r0, 0x1B0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for psq_stx
try_psq_stx:
addi r4, r29, asm_ins_psq_stx - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_ps_abs

#psq_stx found
process_nonimm_psq
lwz r0, 0x1B4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_abs
try_ps_abs:
addi r4, r29, asm_ins_ps_abs - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_abs_

#ps_abs found
process_two_items_left_split
lwz r0, 0x1B8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_abs.
try_ps_abs_:
addi r4, r29, asm_ins_ps_abs_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_add

#ps_abs. found
process_two_items_left_split
lwz r0, 0x1B8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_add
try_ps_add:
addi r4, r29, asm_ins_ps_add - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_add_

#ps_add found
process_three_items_left_aligned
lwz r0, 0x1BC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_add.
try_ps_add_:
addi r4, r29, asm_ins_ps_add_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_cmpo0

#ps_add. found
process_three_items_left_aligned
lwz r0, 0x1BC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_cmpo0
try_ps_cmpo0:
addi r4, r29, asm_ins_ps_cmpo0 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_cmpo1

#ps_cmpo0 found
process_three_items_compare
lwz r0, 0x1C0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_cmpo1
try_ps_cmpo1:
addi r4, r29, asm_ins_ps_cmpo1 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_cmpu0

#ps_cmpo1 found
process_three_items_compare
lwz r0, 0x1C4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_cmpu0
try_ps_cmpu0:
addi r4, r29, asm_ins_ps_cmpu0 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_cmpu1

#ps_cmpu0 found
process_three_items_compare
oris r3, r5, 0x1000
b epilogue_main_asm

#Check for ps_cmpu1
try_ps_cmpu1:
addi r4, r29, asm_ins_ps_cmpu1 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_div

#ps_cmpu1 found
process_three_items_compare
lwz r0, 0x1C8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_div
try_ps_div:
addi r4, r29, asm_ins_ps_div - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_div_

#ps_div found
process_three_items_left_aligned
lwz r0, 0x1CC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_div.
try_ps_div_:
addi r4, r29, asm_ins_ps_div_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_madd

#ps_div. found
process_three_items_left_aligned
lwz r0, 0x1CC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_madd
try_ps_madd:
addi r4, r29, asm_ins_ps_madd - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madd_

#ps_madd found
process_four_items
lwz r0, 0x1D0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_madd.
try_ps_madd_:
addi r4, r29, asm_ins_ps_madd_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madds0

#ps_madd. found
process_four_items
lwz r0, 0x1D0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_madds0
try_ps_madds0:
addi r4, r29, asm_ins_ps_madds0 - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madds0_

#ps_madds0 found
process_four_items
lwz r0, 0x1D4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_madds0.
try_ps_madds0_:
addi r4, r29, asm_ins_ps_madds0_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madds1

#ps_madds0. found
process_four_items
lwz r0, 0x1D4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_madds1
try_ps_madds1:
addi r4, r29, asm_ins_ps_madds1 - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madds1_

#ps_madds1 found
process_four_items
lwz r0, 0x1D8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_madds1.
try_ps_madds1_:
addi r4, r29, asm_ins_ps_madds1_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_merge00

#ps_madds1. found
process_four_items
lwz r0, 0x1D8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_merge00
try_ps_merge00:
addi r4, r29, asm_ins_ps_merge00 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge00_

#ps_merge00 found
process_three_items_left_aligned
lwz r0, 0x1DC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_merge00.
try_ps_merge00_:
addi r4, r29, asm_ins_ps_merge00_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge01

#ps_merge00. found
process_three_items_left_aligned
lwz r0, 0x1DC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_merge01
try_ps_merge01:
addi r4, r29, asm_ins_ps_merge01 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge01_

#ps_merge01 found
process_three_items_left_aligned
lwz r0, 0x1E0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_merge01.
try_ps_merge01_:
addi r4, r29, asm_ins_ps_merge01_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge10

#ps_merge01. found
process_three_items_left_aligned
lwz r0, 0x1E0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_merge10
try_ps_merge10:
addi r4, r29, asm_ins_ps_merge10 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge10_

#ps_merge10 found
process_three_items_left_aligned
lwz r0, 0x1E4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_merge10.
try_ps_merge10_:
addi r4, r29, asm_ins_ps_merge10_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge11

#ps_merge10. found
process_three_items_left_aligned
lwz r0, 0x1E4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_merge11
try_ps_merge11:
addi r4, r29, asm_ins_ps_merge11 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge11_

#ps_merge11 found
process_three_items_left_aligned
lwz r0, 0x1E8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_merge11.
try_ps_merge11_:
addi r4, r29, asm_ins_ps_merge11_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_mr

#ps_merge11. found
process_three_items_left_aligned
lwz r0, 0x1E8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_mr
try_ps_mr:
addi r4, r29, asm_ins_ps_mr - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_mr_

#ps_mr found
process_two_items_left_split
lwz r0, 0x1EC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_mr.
try_ps_mr_:
addi r4, r29, asm_ins_ps_mr_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_msub

#ps_mr. found
process_two_items_left_split
lwz r0, 0x1EC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_msub
try_ps_msub:
addi r4, r29, asm_ins_ps_msub - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_msub_

#ps_msub found
process_four_items
lwz r0, 0x1F0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_msub.
try_ps_msub_:
addi r4, r29, asm_ins_ps_msub_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_mul

#ps_msub. found
process_four_items
lwz r0, 0x1F0 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_mul
try_ps_mul:
addi r4, r29, asm_ins_ps_mul - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_mul_

#ps_mul found
process_three_items_leftwo_rightone_split
lwz r0, 0x1F4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_mul.
try_ps_mul_:
addi r4, r29, asm_ins_ps_mul_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_muls0

#ps_mul. found
process_three_items_leftwo_rightone_split
lwz r0, 0x1F4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_muls0
try_ps_muls0:
addi r4, r29, asm_ins_ps_muls0 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_muls0_

#ps_muls0 found
process_three_items_leftwo_rightone_split
lwz r0, 0x1F8 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_muls0_
try_ps_muls0_:
addi r4, r29, asm_ins_ps_muls0_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_muls1

#ps_muls0. found
process_three_items_leftwo_rightone_split
lwz r0, 0x1F8 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_muls1
try_ps_muls1:
addi r4, r29, asm_ins_ps_muls1 - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_muls1_

#ps_muls1 found
process_three_items_leftwo_rightone_split
lwz r0, 0x1FC (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_muls1.
try_ps_muls1_:
addi r4, r29, asm_ins_ps_muls1_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_nabs

#ps_muls1. found
process_three_items_leftwo_rightone_split
lwz r0, 0x1FC (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_nabs
try_ps_nabs:
addi r4, r29, asm_ins_ps_nabs - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_nabs_

#ps_nabs found
process_two_items_left_split
lwz r0, 0x200 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_nabs.
try_ps_nabs_:
addi r4, r29, asm_ins_ps_nabs_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_neg

#ps_nabs. found
process_two_items_left_split
lwz r0, 0x200 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_neg
try_ps_neg:
addi r4, r29, asm_ins_ps_neg - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_neg_

#ps_neg found
process_two_items_left_split
lwz r0, 0x204 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_neg.
try_ps_neg_:
addi r4, r29, asm_ins_ps_neg_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_nmadd

#ps_neg. found
process_two_items_left_split
lwz r0, 0x204 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_nmadd
try_ps_nmadd:
addi r4, r29, asm_ins_ps_nmadd - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_nmadd_

#ps_nmadd found
process_four_items
lwz r0, 0x208 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_nmadd.
try_ps_nmadd_:
addi r4, r29, asm_ins_ps_nmadd_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_nmsub

#ps_nmadd. found
process_four_items
lwz r0, 0x208 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_nmsub
try_ps_nmsub:
addi r4, r29, asm_ins_ps_nmsub - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_nmsub_

#ps_nmsub found
process_four_items
lwz r0, 0x20C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_nmsub.
try_ps_nmsub_:
addi r4, r29, asm_ins_ps_nmsub_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_res

#ps_nmsub. found
process_four_items
lwz r0, 0x20C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_res
try_ps_res:
addi r4, r29, asm_ins_ps_res - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_res_

#ps_res found
process_two_items_left_split
lwz r0, 0x210 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_res.
try_ps_res_:
addi r4, r29, asm_ins_ps_res_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_rsqrte

#ps_res. found
process_two_items_left_split
lwz r0, 0x210 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_rsqrte
try_ps_rsqrte:
addi r4, r29, asm_ins_ps_rsqrte - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_rsqrte_

#ps_rsqrte found
process_two_items_left_split
lwz r0, 0x214 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_rsqrte.
try_ps_rsqrte_:
addi r4, r29, asm_ins_ps_rsqrte_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_sel

#ps_rsqrte. found
process_two_items_left_split
lwz r0, 0x214 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_sel
try_ps_sel:
addi r4, r29, asm_ins_ps_sel - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sel_

#ps_sel found
process_four_items
lwz r0, 0x218 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_sel.
try_ps_sel_:
addi r4, r29, asm_ins_ps_sel_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sub

#ps_sel. found
process_four_items
lwz r0, 0x218 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_sub
try_ps_sub:
addi r4, r29, asm_ins_ps_sub - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_sub_

#ps_sub found
process_three_items_left_aligned
lwz r0, 0x21C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_sub.
try_ps_sub_:
addi r4, r29, asm_ins_ps_sub_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_sum0

#ps_sub. found
process_three_items_left_aligned
lwz r0, 0x21C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_sum0
try_ps_sum0:
addi r4, r29, asm_ins_ps_sum0 - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sum0_

#ps_sum0 found
process_four_items
lwz r0, 0x220 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_sum0.
try_ps_sum0_:
addi r4, r29, asm_ins_ps_sum0_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sum1

#ps_sum0. found
process_four_items
lwz r0, 0x220 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for ps_sum1
try_ps_sum1:
addi r4, r29, asm_ins_ps_sum1 - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sum1_

#ps_sum1 found
process_four_items
lwz r0, 0x224 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for ps_sum1.
try_ps_sum1_:
addi r4, r29, asm_ins_ps_sum1_ - asm_table_start
call_sscanf_four
cmpwi r3, 4
bne- try_rfi

#ps_sum1. found
process_four_items
lwz r0, 0x224 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for rfi
try_rfi:
addi r4, r29, asm_ins_rfi - asm_table_start
mr r3, r31
li r5, 3
bl memcmp
cmpwi r3, 0
bne- try_rlwimi

#rfi found
lwz r3, 0x228 (r29)
b epilogue_main_asm

#Check for rlwimi
try_rlwimi:
addi r4, r29, asm_ins_rlwimi - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rlwimi_

#rlwimi found
process_five_items
oris r3, r5, 0x5000
b epilogue_main_asm

#Check for rlwimi.
try_rlwimi_:
addi r4, r29, asm_ins_rlwimi_ - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_slwi

#rlwimi. found
process_five_items
oris r3, r5, 0x5000
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for slwi
try_slwi:
addi r4, r29, asm_ins_slwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_slwi_

#slwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = b (r7)
#MB (r8 = 0
#ME (r9) = 31-b aka 31-r7
subfic r9, r7, 31
slwi r7, r7, 11
slwi r9, r9, 1 #No need to shift or logically OR in a null r8 (MB) value
or r5, r5, r6
or r5, r5, r7
or r5, r5, r9
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for slwi.
try_slwi_:
addi r4, r29, asm_ins_slwi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srwi

#slwi. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = b (r7)
#MB (r8 = 0
#ME (r9) = 31-b aka 31-r7
subfic r9, r7, 31
slwi r7, r7, 11
slwi r9, r9, 1 #No need to shift or logically OR in a null r8 (MB) value
or r5, r5, r6
or r5, r5, r7
or r5, r5, r9
oris r3, r5, 0x5400
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for srwi
try_srwi:
addi r4, r29, asm_ins_srwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srwi_

#srwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = 32-b aka 32-r7
#MB (r8) = b (r7)
#ME (r9) = 31
mr r8, r7
subfic r7, r7, 32
li r9, 31
slwi r7, r7, 11
slwi r8, r8, 6
slwi r9, r9, 1
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for srwi.
try_srwi_:
addi r4, r29, asm_ins_srwi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_clrlwi

#srwi. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = 32-b aka 32-r7
#MB (r8) = b (r7)
#ME (r9) = 31
mr r8, r7
subfic r7, r7, 32
li r9, 31
slwi r7, r7, 11
slwi r8, r8, 6
slwi r9, r9, 1
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
or r5, r5, r9
oris r3, r5, 0x5400
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for clrlwi
try_clrlwi:
addi r4, r29, asm_ins_clrlwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_clrlwi_

#clrlwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = 0
#MB (r8) = b (r7)
#ME (r9) = 31
mr r8, r7
li r9, 31
slwi r8, r8, 6 #No need to shift a null (r7; SH) value
slwi r9, r9, 1
or r5, r5, r6
or r5, r5, r8 #No need to logically OR in a null (r7; SH) value
or r5, r5, r9
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for clrlwi.
try_clrlwi_:
addi r4, r29, asm_ins_clrlwi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_clrrwi

#clrlwi. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = 0
#MB (r8) = b (r7)
#ME (r9) = 31
mr r8, r7
li r7, 0
li r9, 31
slwi r8, r8, 6 #No need to shift a null (r7; SH) value
slwi r9, r9, 1
or r5, r5, r6
or r5, r5, r8 #No need to logically OR in a null (r7; SH) value
or r5, r5, r9
oris r3, r5, 0x5400
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for clrrwi
try_clrrwi:
addi r4, r29, asm_ins_clrrwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_clrrwi_

#clrrwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = 0
#MB (r8) = 0
#ME (r9) = 31-b aka 31-r7
subfic r9, r7, 31
slwi r9, r9, 1
or r5, r5, r6
or r5, r5, r9 #No need to shift or logically OR in null values (r7/SH and r8/MB)
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for clrrwi.
try_clrrwi_:
addi r4, r29, asm_ins_clrrwi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_rotlwi

#clrrwi. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
#SH (r7) = 0
#MB (r8) = 0
#ME (r9) = 31-b aka 31-r7
subfic r9, r7, 31
slwi r9, r9, 1
or r5, r5, r6
or r5, r5, r9 #No need to shift or logically OR in null values (r7/SH and r8/MB)
oris r3, r5, 0x5400
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for rotlwi
try_rotlwi:
addi r4, r29, asm_ins_rotlwi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_rotlwi_

#rotlwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
slwi r7, r7, 11 #SH/rB goes in 3rd spot
li r9, 31
slwi r9, r9, 1 #No need to shift in a null (r8/MB) value
or r5, r5, r6
or r5, r5, r7
or r5, r5, r9 #No need to logically OR in a null value (r8/MB)
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for rotlwi.
try_rotlwi_:
addi r4, r29, asm_ins_rotlwi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_rlwinm

#rotlwi. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
slwi r7, r7, 11 #SH/rB goes in 3rd spot
li r9, 31
slwi r9, r9, 1 #No need to shift in a null (r8/MB) value
or r5, r5, r6
or r5, r5, r7
or r5, r5, r9 #No need to logically OR in a null value (r8/MB)
oris r3, r5, 0x5400
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for rlwinm
try_rlwinm:
addi r4, r29, asm_ins_rlwinm - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rlwinm_

#rlwinm found
process_five_items
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for rlwinm.
try_rlwinm_:
addi r4, r29, asm_ins_rlwinm_ - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rotlw

#rlwinm. found
process_five_items
oris r3, r5, 0x5400
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for rotlw
try_rotlw:
addi r4, r29, asm_ins_rotlw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_rotlw_

#rotlw found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
slwi r7, r7, 11 #SH/rB goes in 3rd spot
li r9, 31
slwi r9, r9, 1 #No need to shift in a null (r8/MB) value
or r5, r5, r6
or r5, r5, r7
or r5, r5, r9 #No need to logically OR in a null value (r8/MB)
oris r3, r5, 0x5C00
b epilogue_main_asm

#Check for rotlw.
try_rotlw_:
addi r4, r29, asm_ins_rotlw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_rlwnm

#rotlw. found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #1st source register goes in far left!
slwi r7, r7, 11 #SH/rB goes in 3rd spot
li r9, 31
slwi r9, r9, 1 #No need to shift in a null (r8/MB) value
or r5, r5, r6
or r5, r5, r7
or r5, r5, r9 #No need to logically OR in a null value (r8/MB)
oris r3, r5, 0x5C00
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for rlwnm
try_rlwnm:
addi r4, r29, asm_ins_rlwnm - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rlwnm_

#rlwnm found
process_five_items
oris r3, r5, 0x5C00
b epilogue_main_asm

#Check for rlwnm.
try_rlwnm_:
addi r4, r29, asm_ins_rlwnm_ - asm_table_start
call_sscanf_five
cmpwi r3, 5
bne- try_sc

#rlwnm. found
process_five_items
oris r3, r5, 0x5C00
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for sc
try_sc:
addi r4, r29, asm_ins_sc - asm_table_start
mr r3, r31
li r5, 2
bl memcmp
cmpwi r3, 0
bne- try_slw

#sc found
lwz r3, 0x22C (r29)
b epilogue_main_asm

#Check for slw
try_slw:
addi r4, r29, asm_ins_slw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_slw_

#slw found
process_three_items_logical
lwz r0, 0x230 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for slw.
try_slw_:
addi r4, r29, asm_ins_slw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sraw

#slw. found
process_three_items_logical
lwz r0, 0x230 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for sraw
try_sraw:
addi r4, r29, asm_ins_sraw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sraw_

#sraw found
process_three_items_logical
lwz r0, 0x234 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for sraw.
try_sraw_:
addi r4, r29, asm_ins_sraw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srawi

#sraw. found
process_three_items_logical
lwz r0, 0x234 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for srawi
try_srawi:
addi r4, r29, asm_ins_srawi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srawi_

#srawi found
process_three_items_logical
lwz r0, 0x238 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for srawi.
try_srawi_:
addi r4, r29, asm_ins_srawi_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srw

#srawi. found
process_three_items_logical
lwz r0, 0x238 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for srw
try_srw:
addi r4, r29, asm_ins_srw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srw_

#srw found
process_three_items_logical
lwz r0, 0x23C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for srw.
try_srw_:
addi r4, r29, asm_ins_srw_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stb

#srw. found
process_three_items_logical
lwz r0, 0x23C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for stb
try_stb:
addi r4, r29, asm_ins_stb - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stbu

#stb found
process_imm_storeload
oris r3, r5, 0x9800
b epilogue_main_asm

#Check for stbu
try_stbu:
addi r4, r29, asm_ins_stbu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stbux

#stbu found
process_imm_update_rAneq0
oris r3, r5, 0x9C00
b epilogue_main_asm

#Check for stbux
try_stbux:
addi r4, r29, asm_ins_stbux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stbx

#stbux found
process_float_or_intstore_updateindex
lwz r0, 0x240 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stbx
try_stbx:
addi r4, r29, asm_ins_stbx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfd

#stbx found
process_three_items_left_aligned
lwz r0, 0x244 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stfd
try_stfd:
addi r4, r29, asm_ins_stfd - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfdu

#stfd found
process_imm_storeload
oris r3, r5, 0xD800
b epilogue_main_asm

#Check for stfdu
try_stfdu:
addi r4, r29, asm_ins_stfdu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfdux

#stfdu found
process_imm_update_rAneq0
oris r3, r5, 0xDC00
b epilogue_main_asm

#Check for stfdux
try_stfdux:
addi r4, r29, asm_ins_stfdux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfdx

#stfdux found
process_float_or_intstore_updateindex
lwz r0, 0x248 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stfdx
try_stfdx:
addi r4, r29, asm_ins_stfdx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfiwx

#stfdx found
process_three_items_left_aligned
lwz r0, 0x24C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stfiwx
try_stfiwx:
addi r4, r29, asm_ins_stfiwx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfs

#stfiwx found
process_three_items_left_aligned
lwz r0, 0x250 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stfs
try_stfs:
addi r4, r29, asm_ins_stfs - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfsu

#stfs found
process_imm_storeload
oris r3, r5, 0xD000
b epilogue_main_asm

#Check stfsu
try_stfsu:
addi r4, r29, asm_ins_stfsu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfsux

#stfsu found
process_imm_update_rAneq0
oris r3, r5, 0xD400
b epilogue_main_asm

#Check for stfsux
try_stfsux:
addi r4, r29, asm_ins_stfsux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfsx

#stfsux found
process_float_or_intstore_updateindex
lwz r0, 0x254 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stfsx
try_stfsx:
addi r4, r29, asm_ins_stfsx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sth

#stfsx found
process_three_items_left_aligned
lwz r0, 0x258 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for sth
try_sth:
addi r4, r29, asm_ins_sth - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sthbrx

#sth found
process_imm_storeload
oris r3, r5, 0xB000
b epilogue_main_asm

#Check for sthbrx
try_sthbrx:
addi r4, r29, asm_ins_sthbrx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sthu

#sthbrx found
process_three_items_left_aligned
lwz r0, 0x25C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for sthu
try_sthu:
addi r4, r29, asm_ins_sthu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sthux

#sthu found
process_imm_update_rAneq0
oris r3, r5, 0xB400
b epilogue_main_asm

#Check for sthux
try_sthux:
addi r4, r29, asm_ins_sthux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sthx

#sthux found
process_float_or_intstore_updateindex
lwz r0, 0x260 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for sthx
try_sthx:
addi r4, r29, asm_ins_sthx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stmw

#sthx found
process_three_items_left_aligned
lwz r0, 0x264 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stmw
try_stmw:
addi r4, r29, asm_ins_stmw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stswi

#stmw found
process_imm_storeload
oris r3, r5, 0xBC00
b epilogue_main_asm

#Check for stswi
try_stswi:
addi r4, r29, asm_ins_stswi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stswx

#stswi found
process_three_items_left_aligned
lwz r0, 0x268 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stswx
try_stswx:
addi r4, r29, asm_ins_stswx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stw

#stswx found
process_three_items_left_aligned
lwz r0, 0x26C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stw
try_stw:
addi r4, r29, asm_ins_stw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwbrx

#stw found
process_imm_storeload
oris r3, r5, 0x9000
b epilogue_main_asm

#Check for stwbrx
try_stwbrx:
addi r4, r29, asm_ins_stwbrx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwcx_

#stwbrx found
process_three_items_left_aligned
lwz r0, 0x270 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stwcx.
try_stwcx_:
addi r4, r29, asm_ins_stwcx_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwu

#stwcx. found
process_three_items_left_aligned
lwz r0, 0x274 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stwu
try_stwu:
addi r4, r29, asm_ins_stwu - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwux

#stwu found
process_imm_update_rAneq0
oris r3, r5, 0x9400
b epilogue_main_asm

#Check for stwux
try_stwux:
addi r4, r29, asm_ins_stwux - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwx

#stwux found
process_float_or_intstore_updateindex
lwz r0, 0x278 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for stwx
try_stwx:
addi r4, r29, asm_ins_stwx - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subf

#stwx found
process_three_items_left_aligned
lwz r0, 0x27C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subf
try_subf:
addi r4, r29, asm_ins_subf - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subf_

#subf found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subf.
try_subf_:
addi r4, r29, asm_ins_subf_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfo

#subf. found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subfo
try_subfo:
addi r4, r29, asm_ins_subfo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfo_

#subfo found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subfo.
try_subfo_:
addi r4, r29, asm_ins_subfo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sub

#subfo. found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for sub
try_sub:
addi r4, r29, asm_ins_sub - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sub_

#sub found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for sub.
try_sub_:
addi r4, r29, asm_ins_sub_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subo

#sub. found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subo
try_subo:
addi r4, r29, asm_ins_subo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subo_

#subo found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subo.
try_subo_:
addi r4, r29, asm_ins_subo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfc

#subo. found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for subfc
try_subfc:
addi r4, r29, asm_ins_subfc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfc_

#subfc found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subfc.
try_subfc_:
addi r4, r29, asm_ins_subfc_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfco

#subfc. found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subfco
try_subfco:
addi r4, r29, asm_ins_subfco - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfco_

#subfco found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subfco.
try_subfco_:
addi r4, r29, asm_ins_subfco_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subc

#subfco. found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for subc
try_subc:
addi r4, r29, asm_ins_subc - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subc_

#subc found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subc.
try_subc_:
addi r4, r29, asm_ins_subc_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subco

#subc. found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subco
try_subco:
addi r4, r29, asm_ins_subco - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subco_

#subco found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subco.
try_subco_:
addi r4, r29, asm_ins_subco_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfe

#subco. found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for subfe
try_subfe:
addi r4, r29, asm_ins_subfe - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfe_

#subfe found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subfe.
try_subfe_:
addi r4, r29, asm_ins_subfe_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfeo

#subfe. found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subfeo
try_subfeo:
addi r4, r29, asm_ins_subfeo - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfeo_

#subfeo found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subfeo.
try_subfeo_:
addi r4, r29, asm_ins_subfeo_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfic

#subfeo. found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for subfic
try_subfic:
addi r4, r29, asm_ins_subfic - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subficDEC

#subfic found
process_imm_nonstoreload
oris r3, r5, 0x2000
b epilogue_main_asm

#Check for subficDEC
try_subficDEC:
addi r4, r29, asm_ins_subficDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfme

#subficDEC found
process_imm_nonstoreload
oris r3, r5, 0x2000
b epilogue_main_asm

#Check for subfme
try_subfme:
addi r4, r29, asm_ins_subfme - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfme_

#subfme found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subfme.
try_subfme_:
addi r4, r29, asm_ins_subfme_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfmeo

#subfme. found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subfmeo
try_subfmeo:
addi r4, r29, asm_ins_subfmeo - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfmeo_

#subfmeo found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subfmeo.
try_subfmeo_:
addi r4, r29, asm_ins_subfmeo_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfze

#subfmeo. found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for subfze
try_subfze:
addi r4, r29, asm_ins_subfze - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfze_

#subfze found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for subfze.
try_subfze_:
addi r4, r29, asm_ins_subfze_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfzeo

#subfze. found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for subfzeo
try_subfzeo:
addi r4, r29, asm_ins_subfzeo - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfzeo_

#subfzeo found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
ori r3, r3, asm_oe
b epilogue_main_asm

#Check for subfzeo.
try_subfzeo_:
addi r4, r29, asm_ins_subfzeo_ - asm_table_start
call_sscanf_two
cmpwi r3, 2
bne- try_sync

#subfzeo. found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
ori r3, r3, asm_oe | asm_rc
b epilogue_main_asm

#Check for sync
try_sync:
addi r4, r29, asm_ins_sync - asm_table_start
mr r3, r31
li r5, 4
bl memcmp
cmpwi r3, 0
bne- try_tlbie

#sync found
lwz r3, 0x294 (r29)
b epilogue_main_asm

#Check for tlbie
try_tlbie:
addi r4, r29, asm_ins_tlbie - asm_table_start
call_sscanf_one
cmpwi r3, 1
bne- try_tlbsync

#tlbie found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
slwi r5, r5, 11
lwz r0, 0x298 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for tlbsync
try_tlbsync:
addi r4, r29, asm_ins_tlbsync - asm_table_start
mr r3, r31
li r5, 7
bl memcmp
cmpwi r3, 0
bne- try_trap

#tlbsync found
lwz r3, 0x29C (r29)
b epilogue_main_asm

#Check for trap
try_trap:
addi r4, r29, asm_ins_trap - asm_table_start
mr r3, r31
li r5, 4
bl memcmp
cmpwi r3, 0
bne- try_tw

#trap found
lwz r3, 0x2B0 (r29)
b epilogue_main_asm

#Check for tw
try_tw:
addi r4, r29, asm_ins_tw - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_twi

#tw found
process_three_items_left_aligned
lwz r0, 0x2A0 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for twi
try_twi:
addi r4, r29, asm_ins_twi - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_twiDEC

#twi found
process_imm_nonstoreload
oris r3, r5, 0x0C00
b epilogue_main_asm

#Check for twiDEC
try_twiDEC:
addi r4, r29, asm_ins_twiDEC - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xor

#twiDEC found
process_imm_nonstoreload
oris r3, r5, 0x0C00
b epilogue_main_asm

#Check for xor
try_xor:
addi r4, r29, asm_ins_xor - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xor_

#xor found
process_three_items_logical
lwz r0, 0x2A4 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for xor.
try_xor_:
addi r4, r29, asm_ins_xor_ - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xori

#xor. found
process_three_items_logical
lwz r0, 0x2A4 (r29)
or r3, r0, r5
ori r3, r3, asm_rc
b epilogue_main_asm

#Check for xori
try_xori:
addi r4, r29, asm_ins_xori - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xoris

#xori found
process_imm_logical
oris r3, r5, 0x6800
b epilogue_main_asm

#Check for xoris
try_xoris:
addi r4, r29, asm_ins_xoris - asm_table_start
call_sscanf_three
cmpwi r3, 3
bne- try__long

#xoris found
process_imm_logical
oris r3, r5, 0x6C00
b epilogue_main_asm

#Check for .long (custom 8 digit hex value)
try__long:
addi r4, r29, asm_invalid_instruction - asm_table_start #Doesn't literally mean invalid instruction, I carried look-up table over from disassembler, plus there's always a possibility of merging both the assembler and disassembler into one 'unit/code'
call_sscanf_one
cmpwi r3, 1
bne- cant_compile_source_line

#.long found
lwz r3, 0x8 (sp)
b epilogue_main_asm

##

#Source line cannot be compiled due to sscanf error
cant_compile_source_line:
li r3, -3
b epilogue_final

#Epilogue if successful. Store compiled instruction to r30 (r4 arg)
epilogue_main_asm:
stw r3, 0 (r30)
li r3, 0

#Real epilogue, end function
epilogue_final:
lwz r0, 0x0034 (sp)
lwz r31, 0x2C (sp)
lwz r30, 0x28 (sp)
lwz r29, 0x24 (sp)
mtlr r0
addi sp, sp, 0x0030
blr
