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
#r3 = address where line of source is located at
#r4 = address to store compiled instruction to

#r3 return values
#0 = Success
#-1 = r3 or r4 isn't in valid range
#-2 = instruction name too long (invalid instruction name)
#-3 = sscanf fail (source line is not in correct format)
#-4 = incorrect instruction parameter

main_asm:

#Handy label names
.set rc, 0x00000001
.set oe, 0x00000400
.set lk, 0x00000001
.set aa, 0x00000002

.macro call_sscanf_one
mtlr r28
addi r5, sp, 0x8
mr r3, r31
blrl
.endm

.macro call_sscanf_two
mtlr r28
addi r5, sp, 0x8
addi r6, sp, 0xC
mr r3, r31
blrl
.endm

.macro call_sscanf_three
mtlr r28
addi r5, sp, 0x8
addi r6, sp, 0xC
addi r7, sp, 0x10
mr r3, r31
blrl
.endm

.macro call_sscanf_four
mtlr r28
addi r5, sp, 0x8
addi r6, sp, 0xC
addi r7, sp, 0x10
addi r8, sp, 0x14
mr r3, r31
blrl
.endm

.macro call_sscanf_five
mtlr r28
addi r5, sp, 0x8
addi r6, sp, 0xC
addi r7, sp, 0x10
addi r8, sp, 0x14
addi r9, sp, 0x18
mr r3, r31
blrl
.endm

.macro process_three_items_left_aligned #NOT FOR STRING STORE/LOADS!!! (lswi and stswi)
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_nonstoreload #for things such as addis, NOT for store/loads and NOT for logical instructions
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp) #IMM in r7
cmplwi r5, 31
cmplwi cr6, r6, 31
lhz r0, 0x2AC (r29) #Load 0xFFFF
cmplw cr7, r7, r0
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16 #No need to shift r7 (IMM)
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_two_items_left_aligned
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
or r5, r5, r6
.endm

.macro process_three_items_logical
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
slwi r7, r7, 11 #2nd source register goes in far right!
or r5, r5, r7
or r5, r5, r6
.endm

.macro process_one_item_branch #for b, ba, bl, and bla
lwz r5, 0x8 (sp) #IMM in r5
clrlwi. r0, r5, 30 #IMM aka target_addr needs to be divisible by 4
bne- epilogue_error
lwz r0, 0x2A8 (r29) #Load 0x03FFFFFC
cmplw r5, r0
bgt- epilogue_error #Fyi no shifting needed for r5
.endm

.macro process_three_items_bcX #For bc, bcl, bca, and bcla
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp) #IMM in r7
clrlwi. r0, r7, 30 #IMM aka target_addr needs to be divisible by 4
bne- epilogue_error
cmplwi cr6, r5, 31
cmplwi cr7, r6, 31
lhz r0, 0x2AE (r29) #Load 0xFFFC
cmplw r7, r0
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16 #No shifting needed for r7
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_two_items_logical #for exstb(.) and exsth; NOT for Neg! Neg is NOT a logical operation!
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #Source register goes in far left!
or r5, r5, r6
.endm

.macro process_two_items_cache #right aligned
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16
slwi r6, r6, 11
or r5, r5, r6
.endm

.macro process_two_items_left_split
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 11
or r5, r5, r6
.endm

.macro process_three_items_compare #float and paired single compares only
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 7
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_four_items
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
lwz r8, 0x14 (sp)
cmplwi r5, 31
cmplwi cr5, r6, 31
cmplwi cr6, r7, 31
cmplwi cr7, r8, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
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
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 7
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 6
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_storeload
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp) #IMM is in r6
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r7, 31
lhz r0, 0x2AC (r29) #0xFFFF
cmplw cr7, r6, r0 #r6 for the compare cuz its the IMM
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
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
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp) #IMM in r7
cmplwi r5, 31
cmplwi cr6, r6, 31
lhz r0, 0x2AC (r29) #0xFFFF
cmplw r7, r0
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle!
slwi r6, r6, 21 #Source register goes to far left!
or r5, r5, r6
or r5, r5, r7 #No need to shift IMM
.endm

.macro process_imm_psq #for psq_l and psq_st
lwz r5, 0x8 (sp) #frD
lwz r6, 0xC (sp) #IMM
lwz r7, 0x10 (sp) #rA
lwz r8, 0x14 (sp) #W
lwz r9, 0x18 (sp) #I
cmplwi r5, 31
cmplwi cr5, r6, 0xFFF
cmplwi cr6, r7, 31
cmplwi cr7, r8, 1
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
cmplwi cr5, r9, 7
cror 4*cr0+eq, 4*cr0+eq, 4*cr5+gt
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

.macro process_nonimm_psq #for psq_lx and psq_stx
lwz r5, 0x8 (sp) #frD/frS
lwz r6, 0xC (sp) #rA
lwz r7, 0x10 (sp) #rB
lwz r8, 0x14 (sp) #W
lwz r9, 0x18 (sp) #I
cmplwi r5, 31
cmplwi cr5, r6, 31
cmplwi cr6, r7, 31
cmplwi cr7, r8, 1
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
cmplwi cr5, r9, 7
cror 4*cr0+eq, 4*cr0+eq, 4*cr5+gt
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

.macro process_imm_psq_update #for psq_lu and psq_stu
lwz r5, 0x8 (sp) #frD
lwz r6, 0xC (sp) #IMM
lwz r7, 0x10 (sp) #rA
lwz r8, 0x14 (sp) #W
lwz r9, 0x18 (sp) #I
cmplwi r5, 31
cmplwi cr5, r6, 0xFFF
cmplwi cr6, r7, 31
cmplwi cr7, r8, 1
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
cmplwi cr5, r9, 7
cror 4*cr0+eq, 4*cr0+eq, 4*cr5+gt
beq- epilogue_error
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

.macro process_nonimm_psq_updateindex #for psq_lux and psq_stux
lwz r5, 0x8 (sp) #frD/frS
lwz r6, 0xC (sp) #rA
lwz r7, 0x10 (sp) #rB
lwz r8, 0x14 (sp) #W
lwz r9, 0x18 (sp) #I
cmplwi r5, 31
cmplwi cr5, r6, 31
cmplwi cr6, r7, 31
cmplwi cr7, r8, 1
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
cmplwi cr5, r9, 7
cror 4*cr0+eq, 4*cr0+eq, 4*cr5+gt
beq- epilogue_error
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

.macro process_five_items #Works in logical form, fyi. For the 3 rotate instructions only
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
lwz r8, 0x14 (sp)
lwz r9, 0x18 (sp)
cmplwi r5, 31
cmplwi cr5, r6, 31
cmplwi cr6, r7, 31
cmplwi cr7, r8, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
cmplwi cr5, r9, 31
cror 4*cr0+eq, 4*cr0+eq, 4*cr5+gt
beq- epilogue_error
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
lwz r6, 0xC (sp)
cmplwi r5, 31
cmplwi cr7, r6, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 16 #Dest register goes in middle
slwi r7, r6, 21 #1st source register goes far left
slwi r6, r6, 11 #2nd source register (same register value being used as 1st source, this goes far right)
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_imm_int_load_update #for lbzu, lhau, lhzu, lwzu
#Other than typical checks, rA cannot be r0 and rA =/= rD
lwz r5, 0x8 (sp) #rD
lwz r6, 0xC (sp) #IMM is in r6
lwz r7, 0x10 (sp) #rA
cmplwi r5, 31
cmplwi cr6, r7, 31
lhz r0, 0x2AC (r29) #0xFFFF
cmplw cr7, r6, r0 #r6 for the compare cuz its the IMM
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
cmpwi r7, 0
cmpw cr7, r5, r7
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+eq
beq- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for IMM (r6)
or r5, r5, r7
.endm

.macro process_load_int_updateindex #for lbzux, lhaux, lhzux, lwxuz
#Other than typical checks, rA cannot be r0 and rA =/= rD
lwz r5, 0x8 (sp) #rD
lwz r6, 0xC (sp) #rA
lwz r7, 0x10 (sp) #rB
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
cmpwi r6, 0
cmpw cr7, r5, r6
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+eq
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
lwz r6, 0xC (sp) #IMM is in r6
lwz r7, 0x10 (sp) #rA
cmplwi r5, 31
cmpwi cr5, r7, 0
cmplwi cr6, r7, 31
lhz r0, 0x2AC (r29) #0xFFFF
cmplw cr7, r6, r0 #r6 for the compare cuz its the IMM
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+eq
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for IMM (r6)
or r5, r5, r7
.endm

.macro process_float_or_intstore_updateindex #for lfdux, lfsux, stbux, stfdux, stfsux, sthux, stwux
#Other than typical checks, rA cannot be r0
lwz r5, 0x8 (sp) #frD/frS/rS
lwz r6, 0xC (sp) #rA
lwz r7, 0x10 (sp) #rB
cmplwi r5, 31
cmpwi cr5, r6, 0
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr5+eq
cror 4*cr0+eq, 4*cr0+eq, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
.endm

.macro process_simp_sub_subc #Swap rA and rB
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 21
slwi r6, r6, 11 #Swap rA and rB due to simplified mnemonic use
slwi r7, r7, 16
or r5, r5, r6
or r5, r5, r7
.endm

#Start!

#Make sure both r3 arg & r4 arg are a valid mem1 address (0x80000000 thru 0x817FFFFC; 0x90000000 thru 0x93FFFFFC)
mr r0, r3 #Temp backup r3 arg, due to possible negative return value
li r3, -1
lis r5, 0x8000
lis r6, 0x817F
ori r6, r6, 0xFFFC
addis r7, r5, 0x1000
addis r8, r6, 0x1280
cmplw r0, r5
cmplw cr5, r0, r6
cmplw cr6, r0, r7
cmplw cr7, r0, r8
cror 4*cr0+eq, 4*cr0+lt, 4*cr7+gt #Check if less than 0x80000000 or greater than 0x93FFFFC0
beqlr-
crand 4*cr0+eq, 4*cr5+gt, 4*cr6+lt #Now check if its inbetween 0x817FFFC0 & 0x90000000
beqlr-
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

#Prologue, backup r27 thru r31 and also create a space field of 0x14 in size
stwu sp, -0x0030 (sp)
mflr r0
stw r0, 0x0034 (sp)
stmw r27, 0x1C (sp)

#Backup r3 & r4 args
mr r31, r3
mr r30, r4

#Make massive lookup table; fyi capital X = Rc option
#ORing masks for instructions, only masks with non-zero bits in both upper and lower 16 bits need to be loaded from this lookup table. Masks that don't meet this requirement are commented out but left in source for personal preference.
bl table
table_start:
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
.long 0x03FFFFFC #2A8 For Unconditional Branch SIMM Checking (lhz is faster than lis + ori)
.short 0xFFFF #0x2AC For 16-bit SIM Checking (lhz is faster than lis + ori)
.short 0xFFFC #0x2AE For 16-bit Conditional Branch SIMM Checking (lhz is faster than lis + ori)
.long 0x7FE00008 #0x2B0 For simplified mnemonic trap
.long 0x4E800420 #0x2B4 For simplified mnemonic bctr
.long 0x4E800421 #0x2B8 For simplified mnemonic bctrl
.long 0x4E800020 #0x2BC For simplified mnemonic blr
.long 0x4E800021 #0x2C0 For simplified mnemonic blrl

#NOTE the following are for sscanf function addr and memcmp function addr, software will write this to (then update cache) before the file (as a function) is called
.long 0 #0x2C4; sscanf
.long 0 #0x2C8; memcmp

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
.asciz "and r%d, r%d, r%d" #0x718
ins_and_:
.asciz "and. r%d, r%d, r%d" #0x738

ins_andc:
.asciz "andc r%d, r%d, r%d" #0x758
ins_andc_:
.asciz "andc. r%d, r%d, r%d" #0x778

ins_andi_:
.asciz "andi. r%d, r%d, 0x%X" #0x798

ins_andis_:
.asciz "andis. r%d, r%d, 0x%X" #0x7B8

ins_b:
.asciz "b 0x%X" #0x7D8
ins_ba:
.asciz "ba 0x%X" #0x7F8
ins_bl:
.asciz "bl 0x%X" #0x818
ins_bla:
.asciz "bla 0x%X" #0x838

ins_bc:
.asciz "bc %d, %d, 0x%X" #0x858
ins_bca:
.asciz "bca %d, %d, 0x%X" #0x878
ins_bcl:
.asciz "bcl %d, %d, 0x%X" #0x898
ins_bcla:
.asciz "bcla %d, %d, 0x%X" #0x8B8

ins_bcctr:
.asciz "bcctr %d, %d" #0x8D8
ins_bcctrl:
.asciz "bcctrl %d, %d" #0x8F8
ins_bctr: #Simplified mnemonic for 'bcctr b1z1zz, Z' #z = don't care BO bit values, Z = don't care BI field
.asciz "bctr"
ins_bctrl: #Simplfied mnemonic for 'bcctrl b1z1zz, Z'
.asciz "bctrl"

ins_bclr:
.asciz "bclr %d, %d" #0x918
ins_bclrl:
.asciz "bclrl %d, %d" #0x938
ins_blr: #Simplfied mnemonic for 'bclr b1z1zz, Z' #z = dont' care BO bit values, Z = don't care BI field
.asciz "blr"
ins_blrl: #Simplified mnemonic for 'bclrl b1z1zz, Z'
.asciz "blrl"

ins_cmp:
.asciz "cmp cr%d, %d, r%d, r%d" #0x958

ins_cmpi:
.asciz "cmpi cr%d, %d, r%d, 0x%X" #0x978

ins_cmpl:
.asciz "cmpl cr%d, %d, r%d, r%d" #0x998

ins_cmpli:
.asciz "cmpli cr%d, %d, r%d, 0x%X" #0x9B8

ins_cmpw: #Simplified mnemonic of cmp crX, 0, rX, rX
.asciz "cmpw cr%d, r%d, r%d"

ins_cmpwi: #Simplified mnemonic of cmpi crX, 0, rX, 0xXXXX
.asciz "cmpwi cr%d, r%d, 0x%X"

ins_cmplw: #Simplified mnemonic of cmpl crX, 0, rX, rX
.asciz "cmplw cr%d, r%d, r%d"

ins_cmplwi: #Simplified mnemonic of cmpli crX, 0, rX, 0xXXXX
.asciz "cmplwi cr%d, r%d, 0x%X"

ins_cntlzw:
.asciz "cntlzw r%d, r%d" #0x9D8
ins_cntlzw_:
.asciz "cntlzw. r%d, r%d" #0x9F8

ins_crand:
.asciz "crand %d, %d, %d" #0xA18

ins_crandc:
.asciz "crandc %d, %d, %d" #0xA38

ins_creqv:
.asciz "creqv %d, %d, %d" #0xA58

ins_crnand:
.asciz "crnand %d, %d, %d" #0xA78

ins_crnor:
.asciz "crnor %d, %d, %d" #0xA98

ins_cror:
.asciz "cror %d, %d, %d" #0xAB8

ins_crorc:
.asciz "crorc %d, %d, %d" #0xAD8

ins_crxor:
.asciz "crxor %d, %d, %d" #0xAF8

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
.asciz "ecowx r%d, r%d, r%d" #0xD18

ins_eieio:
.asciz "eieio" #0xD38

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
.asciz "isync" #0x14E8

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

ins_mftb:
.asciz "mftb r%d, %d" #0x19F8
ins_mftb_simp: #Simplified mnemonic for mftb rD, 268
.asciz "mftb r%d"
ins_mftbl: #Same thing as above
.asciz "mftbl r%d"
ins_mftbu: #Simplified mnemonic for mftb rD, 269
.asciz "mftbu r%d"

ins_mr: #Simplified mnemonic for or rX, rY, rY
.asciz "mr r%d, r%d"

ins_mr_: #Simplified mnemonic for or. rX, rY, Y
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

ins_nop: #Simplified mnemonic for ori r0, r0, 0x0000
.asciz "nop"

ins_nor:
.asciz "nor r%d, r%d, r%d" #0x1D98
ins_nor_:
.asciz "nor. r%d, r%d, r%d" #0x1DB8

ins_not: #Simplified mnemonic for nor rX, rY, Y
.asciz "not r%d, r%d"
ins_not_: #Simplified mnemonic for nor. rX, rY, Y
.asciz "not. r%d, r%d"

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
.asciz "sth r%d, 0x%X (r%d)" #0x2AD8

ins_sthbrx:
.asciz "sthbrx r%d, r%d, r%d" #0x2AF8

ins_sthu:
.asciz "sthu r%d, 0x%X (r%d)" #0x2B18

ins_sthux:
.asciz "sthux r%d, r%d, r%d" #0x2B38

ins_sthx:
.asciz "sthx r%d, r%d, r%d" #0x2B58

ins_stmw:
.asciz "stmw r%d, 0x%X (r%d)" #0x2B78

ins_stswi:
.asciz "stswi r%d, r%d, %d" #0x2B98

ins_stswx:
.asciz "stswx r%d, r%d, r%d" #0x2BB8

ins_stw:
.asciz "stw r%d, 0x%X (r%d)" #0x2BD8

ins_stwbrx:
.asciz "stwbrx r%d, r%d, r%d" #0x2BF8

ins_stwcx_:
.asciz "stwcx. r%d, r%d, r%d" #0x2C18

ins_stwu:
.asciz "stwu r%d, 0x%X (r%d)" #0x2C38

ins_stwux:
.asciz "stwux r%d, r%d, r%d" #0x2C58

ins_stwx:
.asciz "stwx r%d, r%d, r%d" #0x2C78

ins_subf:
.asciz "subf r%d, r%d, r%d"
ins_subf_:
.asciz "subf. r%d, r%d, r%d"
ins_subfo:
.asciz "subfo r%d, r%d, r%d"
ins_subfo_:
.asciz "subfo. r%d, r%d, r%d"

#Simplified mnemonics for subfX rD, rB, rA
ins_sub:
.asciz "sub r%d, r%d, r%d"
ins_sub_:
.asciz "sub. r%d, r%d, r%d"
ins_subo:
.asciz "subo r%d, r%d, r%d"
ins_subo_:
.asciz "subo. r%d, r%d, r%d"

ins_subfc:
.asciz "subfc r%d, r%d, r%d"
ins_subfc_:
.asciz "subfc. r%d, r%d, r%d"
ins_subfco:
.asciz "subfco r%d, r%d, r%d"
ins_subfco_:
.asciz "subfco. r%d, r%d, r%d"

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
mflr r4
#Backup Lookup Table pointer
mr r29, r4

#Start instruction search
#Fyi if something is found, we check it with sscanf
#r3 = Formatted C string
#r4 = Conversions (% items)
#r5 = Dump spot of Conversion #1
#r6 = Dump spot #2
#r7 = #3, etc etc til r10

#Place sscanf fnction address in r28
lwz r28, 0x2C4 (r29)

#Place memcmp function address in r27
lwz r27, 0x2C8 (r29)

#Check for add
addi r4, r29, ins_add - table_start
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
addi r4, r29, ins_add_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addo

#add. found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for addo
try_addo:
addi r4, r29, ins_addo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addo_

#addo found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for addo.
try_addo_:
addi r4, r29, ins_addo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addc

#addo. found
process_three_items_left_aligned
lwz r0, 0 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#
#Check for addc
try_addc:
addi r4, r29, ins_addc - table_start
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
addi r4, r29, ins_addc_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addco

#addc. found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for addco
try_addco:
addi r4, r29, ins_addco - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addco_

#addco found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for addco.
try_addco_:
addi r4, r29, ins_addco_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_adde

#addco. found
process_three_items_left_aligned
lwz r0, 0x4 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#
#Check for adde
try_adde:
addi r4, r29, ins_adde - table_start
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
addi r4, r29, ins_adde_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addeo

#adde. found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for addeo
try_addeo:
addi r4, r29, ins_addeo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addeo_

#addeo found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for addeo.
try_addeo_:
addi r4, r29, ins_addeo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addi

#addeo. found
process_three_items_left_aligned
lwz r0, 0x8 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm


#Check for addi
try_addi:
addi r4, r29, ins_addi - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addic

#addi found
process_imm_nonstoreload
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for addic
try_addic:
addi r4, r29, ins_addic - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addic_

#addic found
process_imm_nonstoreload
oris r3, r5, 0x3000
b epilogue_main_asm

#Check for addic.
try_addic_:
addi r4, r29, ins_addic_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addis

#addic. found
process_imm_nonstoreload
oris r3, r5, 0x3400
b epilogue_main_asm

#Check for addis
try_addis:
addi r4, r29, ins_addis - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_addme

#addis found
process_imm_nonstoreload
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for addme
try_addme:
addi r4, r29, ins_addme - table_start
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
addi r4, r29, ins_addme_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addmeo

#addme. found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for addmeo
try_addmeo:
addi r4, r29, ins_addmeo - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addmeo_

#addmeo found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for addmeo.
try_addmeo_:
addi r4, r29, ins_addmeo_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addze

#addmeo. found
process_two_items_left_aligned
lwz r0, 0xC (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for addze
try_addze:
addi r4, r29, ins_addze - table_start
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
addi r4, r29, ins_addze_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addzeo

#addze. found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for addzeo
try_addzeo:
addi r4, r29, ins_addzeo - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_addzeo_

#addzeo found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for addzeo.
try_addzeo_:
addi r4, r29, ins_addzeo_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_and

#addzeo. found
process_two_items_left_aligned
lwz r0, 0x10 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for and
try_and:
addi r4, r29, ins_and - table_start
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
addi r4, r29, ins_and_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andc

#and. found
process_three_items_logical
lwz r0, 0x14 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for andc
try_andc:
addi r4, r29, ins_andc - table_start
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
addi r4, r29, ins_andc_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andi_

#andc. found
process_three_items_logical
lwz r0, 0x18 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for andi.
try_andi_:
addi r4, r29, ins_andi_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_andis_

#andi. found
process_imm_logical
oris r3, r5, 0x7000
b epilogue_main_asm

#Check for andis.
try_andis_:
addi r4, r29, ins_andis_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_b

#andis. found
process_imm_logical
oris r3, r5, 0x7400
b epilogue_main_asm

#Check for b
try_b:
addi r4, r29, ins_b - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_ba

#b found
process_one_item_branch
oris r3, r5, 0x4800
b epilogue_main_asm

#Check for ba
try_ba:
addi r4, r29, ins_ba - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bl

#ba found
process_one_item_branch
oris r3, r5, 0x4800
ori r3, r3, aa
b epilogue_main_asm

#Check for bl
try_bl:
addi r4, r29, ins_bl - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bla

#bl found
process_one_item_branch
oris r3, r5, 0x4800
ori r3, r3, lk
b epilogue_main_asm

#Check for bla
try_bla:
addi r4, r29, ins_bla - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_bc

#bla found
process_one_item_branch
oris r3, r5, 0x4800
ori r3, r3, aa | lk
b epilogue_main_asm

#Check for bc
try_bc:
addi r4, r29, ins_bc - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bca

#bc found
process_three_items_bcX
oris r3, r5, 0x4000
b epilogue_main_asm

#Check for bca
try_bca:
addi r4, r29, ins_bca - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bcl

#bca found
process_three_items_bcX
oris r3, r5, 0x4000
ori r3, r3, aa
b epilogue_main_asm

#Check for bcl
try_bcl:
addi r4, r29, ins_bcl - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bcla

#bcl found
process_three_items_bcX
oris r3, r5, 0x4000
ori r3, r3, lk
b epilogue_main_asm

#Check for bcla
try_bcla:
addi r4, r29, ins_bcla - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_bctrl

#bcla found
process_three_items_bcX
oris r3, r5, 0x4000
ori r3, r3, aa | lk
b epilogue_main_asm

#Check for bctrl !!bctrl must always be checked before bctr or else memcmp can give a false positive find!!
try_bctrl:
addi r4, r29, ins_bctrl - table_start
mtlr r27
mr r3, r31
li r5, 5
blrl
cmpwi r3, 0
bne- try_bctr

#bctrl found
lwz r3, 0x2B8 (r29)
b epilogue_main_asm

#Check for bctr
try_bctr:
addi r4, r29, ins_bctr - table_start
mtlr r27
mr r3, r31
li r5, 4
blrl
cmpwi r3, 0
bne- try_bcctr

#bctr found
lwz r3, 0x2B4(r29)
b epilogue_main_asm

#Check for bcctr
try_bcctr:
addi r4, r29, ins_bcctr - table_start
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
addi r4, r29, ins_bcctrl - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_blrl

#bcctrl found
process_two_items_left_aligned
lwz r0, 0x1C (r29)
or r3, r0, r5
ori r3, r3, lk
b epilogue_main_asm

#Check for blrl !!blrl must always be checked before blr or else memcmp can give a false positive find!!
try_blrl:
addi r4, r29, ins_blrl - table_start
mtlr r27
mr r3, r31
li r5, 4
blrl
cmpwi r3, 0
bne- try_blr

#blrl found
lwz r3, 0x2C0 (r29)
b epilogue_main_asm

#Check for blr
try_blr:
addi r4, r29, ins_blr - table_start
mtlr r27
mr r3, r31
li r5, 3
blrl
cmpwi r3, 0
bne- try_bclr

#blr found
lwz r3, 0x2BC (r29)
b epilogue_main_asm

#Check for bclr
try_bclr:
addi r4, r29, ins_bclr - table_start
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
addi r4, r29, ins_bclrl - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_cmp

#bclrl found
process_two_items_left_aligned
lwz r0, 0x20 (r29)
or r3, r0, r5
ori r3, r3, lk
b epilogue_main_asm

#Check for cmp
try_cmp:
addi r4, r29, ins_cmp - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpi

#cmp found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
lwz r8, 0x14 (sp)
cmpwi r6, 0
bne- epilogue_error
cmplwi r5, 7 #CrF can't be > 7, L must = 0, rA and rB can't be > 31
cmplwi cr6, r7, 31
cmplwi cr7, r8, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21
slwi r7, r7, 16
slwi r8, r8, 11
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
oris r3, r5, 0x7C00
b epilogue_main_asm

#Check for cmpi
try_cmpi:
addi r4, r29, ins_cmpi - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpl

#cmpi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
lwz r8, 0x14 (sp)
cmpwi r6, 0
bne- epilogue_error
cmplwi r5, 7 #CrF can't be > 7, L must = 0, rA can't be > 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21
slwi r7, r7, 16
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cmpl
try_cmpl:
addi r4, r29, ins_cmpl - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpli

#cmpl found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
lwz r8, 0x14 (sp)
cmpwi r6, 0
bne- epilogue_error
cmplwi r5, 7 #CrF can't be > 7, L must = 0, rA and rB can't be > 31
cmplwi cr6, r7, 31
cmplwi cr7, r8, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21
slwi r7, r7, 16
slwi r8, r8, 11
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
lwz r0, 0x24 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for cmpli
try_cmpli:
addi r4, r29, ins_cmpli - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_cmpw

#cmpli found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
lwz r8, 0x14 (sp)
cmpwi r6, 0
bne- epilogue_error
cmplwi r5, 7 #CrF can't be > 7, L must = 0, rA can't be > 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 21
slwi r7, r7, 16
or r5, r5, r6
or r5, r5, r7
or r5, r5, r8
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cmpw
try_cmpw:
addi r4, r29, ins_cmpw - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmpwi

#cmpw found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 7
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
slwi r7, r7, 11
or r5, r5, r6
or r5, r5, r7
oris r3, r5, 0x7C00
b epilogue_main_asm

#Check for cmpwi
try_cmpwi:
addi r4, r29, ins_cmpwi - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmplw

#cmpwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 7
cmplwi cr6, r6, 31
lhz r0, 0x2AC (r29)
cmplw cr7, r7, r0
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
or r5, r5, r6
or r5, r5, r7
oris r3, r5, 0x2C00
b epilogue_main_asm

#Check for cmplw
try_cmplw:
addi r4, r29, ins_cmplw - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cmplwi

#cmplw found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 7
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
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
addi r4, r29, ins_cmplwi - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_cntlzw

#cmplwi found
lwz r5, 0x8 (sp)
lwz r6, 0xC (sp)
lwz r7, 0x10 (sp)
cmplwi r5, 7
cmplwi cr6, r6, 31
lhz r0, 0x2AC (r29)
cmplw cr7, r7, r0
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
slwi r5, r5, 23
slwi r6, r6, 16
or r5, r5, r6
or r5, r5, r7
oris r3, r5, 0x2800
b epilogue_main_asm

#Check for cntlzw
try_cntlzw:
addi r4, r29, ins_cntlzw - table_start
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
addi r4, r29, ins_cntlzw_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_crand

#cntlzw. found
process_two_items_logical
lwz r0, 0x28 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for crand
try_crand:
addi r4, r29, ins_crand - table_start
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
addi r4, r29, ins_crandc - table_start
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
addi r4, r29, ins_creqv - table_start
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
addi r4, r29, ins_crnand - table_start
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
addi r4, r29, ins_crnor - table_start
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
addi r4, r29, ins_cror - table_start
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
addi r4, r29, ins_crorc - table_start
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
addi r4, r29, ins_crxor - table_start
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
addi r4, r29, ins_crset - table_start
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
addi r4, r29, ins_crnot - table_start
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
addi r4, r29, ins_crmove - table_start
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
addi r4, r29, ins_crclr - table_start
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
addi r4, r29, ins_dcbf - table_start
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
addi r4, r29, ins_dcbi - table_start
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
addi r4, r29, ins_dcbst - table_start
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
addi r4, r29, ins_dcbt - table_start
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
addi r4, r29, ins_dcbtst - table_start
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
addi r4, r29, ins_dcbz - table_start
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
addi r4, r29, ins_dcbz_l - table_start
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
addi r4, r29, ins_divw - table_start
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
addi r4, r29, ins_divw_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwo

#divw. found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for divwo
try_divwo:
addi r4, r29, ins_divwo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwo_

#divwo found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for divwo.
try_divwo_:
addi r4, r29, ins_divwo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwu

#divwo. found
process_three_items_left_aligned
lwz r0, 0x68 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for divwu
try_divwu:
addi r4, r29, ins_divwu - table_start
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
addi r4, r29, ins_divwu_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwuo

#divwu_ found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for divwuo
try_divwuo:
addi r4, r29, ins_divwuo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_divwuo_

#divwuo found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for divwuo.
try_divwuo_:
addi r4, r29, ins_divwuo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_eciwx

#divwuo_ found
process_three_items_left_aligned
lwz r0, 0x6C (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for eciwx
try_eciwx:
addi r4, r29, ins_eciwx - table_start
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
addi r4, r29, ins_ecowx - table_start
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
addi r4, r29, ins_eieio - table_start
mtlr r27
mr r3, r31
li r5, 5
blrl
cmpwi r3, 0
bne- try_eqv

#eieio found
lwz r3, 0x78 (r29)
b epilogue_main_asm

#Check for eqv
try_eqv:
addi r4, r29, ins_eqv - table_start
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
addi r4, r29, ins_eqv_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_extsb

#eqv. found
process_three_items_logical
lwz r0, 0x7C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for extsb
try_extsb:
addi r4, r29, ins_extsb - table_start
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
addi r4, r29, ins_extsb_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_exsth

#extsb. found
process_two_items_logical
lwz r0, 0x80 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for extsh
try_exsth:
addi r4, r29, ins_extsh- table_start
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
addi r4, r29, ins_extsh_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fabs

#extsh. found
process_two_items_logical
lwz r0, 0x84 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fabs
try_fabs:
addi r4, r29, ins_fabs - table_start
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
addi r4, r29, ins_fabs_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fadd

#fabs. found
process_two_items_left_split
lwz r0, 0x88 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fadd
try_fadd:
addi r4, r29, ins_fadd - table_start
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
addi r4, r29, ins_fadd_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fadds

#fadd. found
process_three_items_left_aligned
lwz r0, 0x8C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fadds
try_fadds:
addi r4, r29, ins_fadds - table_start
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
addi r4, r29, ins_fadds_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fcmpo

#fadds. found
process_three_items_left_aligned
lwz r0, 0x90 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fcmpo
try_fcmpo:
addi r4, r29, ins_fcmpo - table_start
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
addi r4, r29, ins_fcmpu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fctiw

#fcmpu found
process_three_items_compare
oris r3, r5, 0xFC00
b epilogue_main_asm

#Check for fctiw
try_fctiw:
addi r4, r29, ins_fctiw - table_start
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
addi r4, r29, ins_fctiw_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fctiwz

#fctiw. found
process_two_items_left_split
lwz r0, 0x98 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fctiwz
try_fctiwz:
addi r4, r29, ins_fctiwz - table_start
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
addi r4, r29, ins_fctiwz_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fdiv

#fctiwz. found
process_two_items_left_split
lwz r0, 0x9C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fdiv
try_fdiv:
addi r4, r29, ins_fdiv - table_start
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
addi r4, r29, ins_fdiv_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fdivs

#fdiv. found
process_three_items_left_aligned
lwz r0, 0xA0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fdivs
try_fdivs:
addi r4, r29, ins_fdivs - table_start
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
addi r4, r29, ins_fdivs_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fmadd

#fdivs. found
process_three_items_left_aligned
lwz r0, 0xA4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmadd
try_fmadd:
addi r4, r29, ins_fmadd - table_start
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
addi r4, r29, ins_fmadd_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmadds

#fmadd. found
process_four_items
lwz r0, 0xA8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmadds
try_fmadds:
addi r4, r29, ins_fmadds - table_start
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
addi r4, r29, ins_fmadds_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmr

#fmadds. found
process_four_items
lwz r0, 0xAC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmr
try_fmr:
addi r4, r29, ins_fmr - table_start
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
addi r4, r29, ins_fmr_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fmsub

#fmr. found
process_two_items_left_split
lwz r0, 0xB0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmsub
try_fmsub:
addi r4, r29, ins_fmsub - table_start
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
addi r4, r29, ins_fmsub_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmsubs

#fmsub. found
process_four_items
lwz r0, 0xB4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmsubs
try_fmsubs:
addi r4, r29, ins_fmsubs - table_start
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
addi r4, r29, ins_fmsubs_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fmul

#fmsubs. found
process_four_items
lwz r0, 0xB8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmul
try_fmul:
addi r4, r29, ins_fmul - table_start
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
addi r4, r29, ins_fmul_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fmuls

#fmul. found
process_three_items_leftwo_rightone_split
lwz r0, 0xBC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fmuls
try_fmuls:
addi r4, r29, ins_fmuls - table_start
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
addi r4, r29, ins_fmuls_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fnabs

#fmuls. found
process_three_items_leftwo_rightone_split
lwz r0, 0xC0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fnabs
try_fnabs:
addi r4, r29, ins_fnabs - table_start
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
addi r4, r29, ins_fnabs_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fneg

#fnabs. found
process_two_items_left_split
lwz r0, 0xC4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fneg
try_fneg:
addi r4, r29, ins_fneg - table_start
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
addi r4, r29, ins_fneg_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fnmadd

#fneg. found
process_two_items_left_split
lwz r0, 0xC8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fnmadd
try_fnmadd:
addi r4, r29, ins_fnmadd - table_start
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
addi r4, r29, ins_fnmadd_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmadds

#fnmadd. found
process_four_items
lwz r0, 0xCC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fnmadds
try_fnmadds:
addi r4, r29, ins_fnmadds - table_start
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
addi r4, r29, ins_fnmadds_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmsub

#fnmadds. found
process_four_items
lwz r0, 0xD0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fnmsub
try_fnmsub:
addi r4, r29, ins_fnmsub - table_start
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
addi r4, r29, ins_fnmsub_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fnmsubs

#fnmsub. found
process_four_items
lwz r0, 0xD4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fnmsubs
try_fnmsubs:
addi r4, r29, ins_fnmsubs - table_start
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
addi r4, r29, ins_fnmsubs_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fres

#fnmsubs. found
process_four_items
lwz r0, 0xD8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fres
try_fres:
addi r4, r29, ins_fres - table_start
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
addi r4, r29, ins_fres_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_frsp

#fres. found
process_two_items_left_split
lwz r0, 0xDC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for frsp
try_frsp:
addi r4, r29, ins_frsp - table_start
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
addi r4, r29, ins_frsp_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_frsqrte

#frsp. found
process_two_items_left_split
lwz r0, 0xE0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for frsqrte
try_frsqrte:
addi r4, r29, ins_frsqrte - table_start
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
addi r4, r29, ins_frsqrte_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_fsel

#frsqrte. found
process_two_items_left_split
lwz r0, 0xE4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fsel
try_fsel:
addi r4, r29, ins_fsel - table_start
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
addi r4, r29, ins_fsel_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_fsub

#fsel. found
process_four_items
lwz r0, 0xE8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fsub
try_fsub:
addi r4, r29, ins_fsub - table_start
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
addi r4, r29, ins_fsub_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_fsubs

#fsub. found
process_three_items_left_aligned
lwz r0, 0xEC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for fsubs
try_fsubs:
addi r4, r29, ins_fsubs - table_start
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
addi r4, r29, ins_fsubs_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_icbi

#fsubs. found
process_three_items_left_aligned
lwz r0, 0xF0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for icbi
try_icbi:
addi r4, r29, ins_icbi - table_start
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
addi r4, r29, ins_isync - table_start
mtlr r27
mr r3, r31
li r5, 5
blrl
cmpwi r3, 0
bne- try_lbz

#isync found
lwz r3, 0xF8 (r29)
b epilogue_main_asm

#Check for lbz
try_lbz:
addi r4, r29, ins_lbz - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lbzu

#lbz found
process_imm_storeload
oris r3, r5, 0x8800
b epilogue_main_asm

#Check for lbzu
try_lbzu:
addi r4, r29, ins_lbzu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lbzux

#lbzu found
process_imm_int_load_update
oris r3, r5, 0x8C00
b epilogue_main_asm

#Check for lbzux
try_lbzux:
addi r4, r29, ins_lbzux - table_start
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
addi r4, r29, ins_lbzx - table_start
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
addi r4, r29, ins_lfd - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfdu

#lfd found
process_imm_storeload
oris r3, r5, 0xC800
b epilogue_main_asm

#Check for lfdu
try_lfdu:
addi r4, r29, ins_lfdu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfdux

#lfdu found
process_imm_update_rAneq0
oris r3, r5, 0xCC00
b epilogue_main_asm

#Check for lfdux
try_lfdux:
addi r4, r29, ins_lfdux - table_start
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
addi r4, r29, ins_lfdx - table_start
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
addi r4, r29, ins_lfs - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfsu

#lfs found
process_imm_storeload
oris r3, r5, 0xC000
b epilogue_main_asm

#Check for lfsu
try_lfsu:
addi r4, r29, ins_lfsu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lfsux

#lfsu found
process_imm_update_rAneq0
oris r3, r5, 0xC400
b epilogue_main_asm

#Check for lfsux
try_lfsux:
addi r4, r29, ins_lfsux - table_start
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
addi r4, r29, ins_lfsx - table_start
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
addi r4, r29, ins_lha - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhau

#lha found
process_imm_storeload
oris r3, r5, 0xA800
b epilogue_main_asm

#Check for lhau
try_lhau:
addi r4, r29, ins_lhau - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhaux

#lhau found
process_imm_int_load_update
oris r3, r5, 0xAC00
b epilogue_main_asm

#Check for lhaux
try_lhaux:
addi r4, r29, ins_lhaux - table_start
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
addi r4, r29, ins_lhax - table_start
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
addi r4, r29, ins_lhbrx - table_start
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
addi r4, r29, ins_lhz - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhzu

#lhz found
process_imm_storeload
oris r3, r5, 0xA000
b epilogue_main_asm

#Check for lhzu
try_lhzu:
addi r4, r29, ins_lhzu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lhzux

#lhzu found
process_imm_int_load_update
oris r3, r5, 0xA400
b epilogue_main_asm

#Check for lhzux
try_lhzux:
addi r4, r29, ins_lhzux - table_start
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
addi r4, r29, ins_lhzx - table_start
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
addi r4, r29, ins_li - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_lis

#li found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lhz r0, 0x2AC (r29) #Load 0xFFFF
lwz r6, 0xC (sp)
cmplw r6, r0
bgt- epilogue_error
slwi r5, r5, 21
or r5, r5, r6
oris r3, r5, 0x3800
b epilogue_main_asm

#Check for lis
try_lis:
addi r4, r29, ins_lis - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_lmw

#lis found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
lhz r0, 0x2AC (r29) #Load 0xFFFF
lwz r6, 0xC (sp)
cmplw r6, r0
bgt- epilogue_error
slwi r5, r5, 21
or r5, r5, r6
oris r3, r5, 0x3C00
b epilogue_main_asm

#Check for lmw
try_lmw:
addi r4, r29, ins_lmw - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lswi

#lmw found
lwz r5, 0x8 (sp) #rD
lwz r6, 0xC (sp) #IMM is in r6
lwz r7, 0x10 (sp) #rA
cmplwi r5, 31
cmplwi cr6, r7, 31
lhz r0, 0x2AC (r29) #0xFFFF
cmplw cr7, r6, r0 #r6 for the compare cuz its the IMM
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
cmplw r7, r5 #rA cannot be >= to rD
bge- epilogue_error
slwi r5, r5, 21
slwi r7, r7, 16
or r5, r5, r6 #No shifting needed for IMM (r6)
or r5, r5, r7
oris r3, r5, 0xB800
b epilogue_main_asm

#Check for lswi
try_lswi:
addi r4, r29, ins_lswi - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lswx

#lswi found
#Notice: we CANNOT use a similar check method for lswx, because it's simply impossible to know the value that will be contained within rB itself of lswx
lwz r5, 0x8 (sp) #rD
lwz r6, 0xC (sp) #rA
lwz r7, 0x10 (sp) #NB, this is a quasi-immediate value, we know what's in here like knowing the IMM value in a store/load
cmplwi r5, 31
cmplwi cr6, r6, 31
cmplwi cr7, r7, 31
cror 4*cr0+eq, 4*cr0+gt, 4*cr6+gt
cror 4*cr0+eq, 4*cr0+eq, 4*cr7+gt
beq- epilogue_error
#In the case that rA is >= than rD, we need to make sure NB doesn't have a large enough value to cause loaded bytes to spill into rA!
#Fyi Broadway will use an NB value of 32 if it's set to 0 in the instruction!!!!!!!!!!!!!!!!!!!!!!
cmplw r5, r6
bgt- start_processing_lswi
mr r12, r7 #Preserve r7 aka NB
cmpwi r12, 0
bne- skip_nb_adjustment
li r12, 32
skip_nb_adjustment:
subf r0, r5, r6
slwi r0, r0, 2 #Mulli by 0x4 for bytes
cmpw r12, r0
bgt- epilogue_error #NB value will cause bytes to spill into rA which is invalid according to the Broadway manual, abort!
start_processing_lswi:
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
addi r4, r29, ins_lswx - table_start
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
addi r4, r29, ins_lwarx - table_start
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
addi r4, r29, ins_lwbrx - table_start
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
addi r4, r29, ins_lwz - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwzu

#lwz found
process_imm_storeload
oris r3, r5, 0x8000
b epilogue_main_asm

#Check for lwzu
try_lwzu:
addi r4, r29, ins_lwzu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_lwzux

#lwzu found
process_imm_int_load_update
oris r3, r5, 0x8400
b epilogue_main_asm

#Check for lwzux
try_lwzux:
addi r4, r29, ins_lwzux - table_start
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
addi r4, r29, ins_lwzx - table_start
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
li r3, -3
b epilogue_final

#Check for mcrf
try_mcrf:
addi r4, r29, ins_mcrf - table_start
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
addi r4, r29, ins_mcrfs - table_start
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
addi r4, r29, ins_mcrxr - table_start
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
addi r4, r29, ins_mfcr - table_start
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
addi r4, r29, ins_mffs - table_start
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
addi r4, r29, ins_mffs_ - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfmsr

#mffs. found
process_one_item_left_aligned
lwz r0, 0x14C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for mfmsr
try_mfmsr:
addi r4, r29, ins_mfmsr - table_start
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
addi r4, r29, ins_mfxer - table_start
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
addi r4, r29, ins_mflr - table_start
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
addi r4, r29, ins_mfctr - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mfspr

#mfctr found
lwz r5, 0x8 (sp)
cmplwi r5, 31
bgt- epilogue_error
li r6, 9 #Set SPR number to CTR
b proceed_mfspr #finish off SPR operations

#Check for mfspr
try_mfspr:
addi r4, r29, ins_mfspr - table_start
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
addi r4, r29, ins_mfsr - table_start
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
lwz r0, 0x158 (r29)
or r3, r0, r5
b epilogue_main_asm

#Check for mfsrin
try_mfsrin:
addi r4, r29, ins_mfsrin - table_start
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
addi r4, r29, ins_mftb - table_start
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
addi r4, r29, ins_mftb_simp - table_start
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
addi r4, r29, ins_mftbl - table_start
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
addi r4, r29, ins_mftbu - table_start
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
addi r4, r29, ins_mr - table_start
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
addi r4, r29, ins_mr_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtcrf

#mr. found
process_simpilified_logical_two_items
lwz r0, 0x1A0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for mtcrf
try_mtcrf:
addi r4, r29, ins_mtcrf - table_start
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
addi r4, r29, ins_mtcr - table_start
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
addi r4, r29, ins_mtfsb0 - table_start
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
addi r4, r29, ins_mtfsb0_ - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsb1

#mtfsb0. found
process_one_item_left_aligned
lwz r0, 0x168 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for mtfsb1
try_mtfsb1:
addi r4, r29, ins_mtfsb1 - table_start
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
addi r4, r29, ins_mtfsb1_ - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtfsf

#mtfsb1. found
process_one_item_left_aligned
lwz r0, 0x16C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for mtfsf
try_mtfsf:
addi r4, r29, ins_mtfsf - table_start
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
addi r4, r29, ins_mtfsf_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for mtfsfi
try_mtfsfi:
addi r4, r29, ins_mtfsfi - table_start
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

#Check for mtfsf.
try_mtfsfi_:
addi r4, r29, ins_mtfsfi_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_mtmsr

#mtfsf. found
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
ori r3, r3, rc
b epilogue_main_asm

#Check for mtmsr
try_mtmsr:
addi r4, r29, ins_mtmsr - table_start
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
addi r4, r29, ins_mtxer - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtlr

#mtxer found
li r5, 1 #Set SPR number for XER
lwz r6, 0x8 (sp)
b continue_spr_operations_mtspr #Proceed with SPR operations

#Check for mtlr
try_mtlr:
addi r4, r29, ins_mtlr - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtctr

#mtlr found
li r5, 8 #Set SPR number for LR
lwz r6, 0x8 (sp)
b continue_spr_operations_mtspr #Proceed with SPR operations

#Check for mtctr
try_mtctr:
addi r4, r29, ins_mtctr - table_start
call_sscanf_one
cmpwi r3, 1
bne- try_mtspr

#mtctr found
li r5, 9 #Set SPR number for CTR
lwz r6, 0x8 (sp)
b continue_spr_operations_mtspr #Proceed with SPR operations

#Check for mtspr
try_mtspr:
addi r4, r29, ins_mtspr - table_start
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
continue_spr_operations_mtspr: #Landing spot for mtxer, mtlr, and mtctr
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
addi r4, r29, ins_mtsr - table_start
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
addi r4, r29, ins_mtsrin - table_start
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
addi r4, r29, ins_mulhw - table_start
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
addi r4, r29, ins_mulhw_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulhwu

#mulhw. found
process_three_items_left_aligned
lwz r0, 0x188 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for mulhwu
try_mulhwu:
addi r4, r29, ins_mulhwu - table_start
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
addi r4, r29, ins_mulhwu_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mulli

#mulhwu. found
process_three_items_left_aligned
lwz r0, 0x18C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check fo mulli
try_mulli:
addi r4, r29, ins_mulli - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullw

#mulli found
process_imm_nonstoreload
oris r3, r5, 0x1C00
b epilogue_main_asm

#Check for mullw
try_mullw:
addi r4, r29, ins_mullw - table_start
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
addi r4, r29, ins_mullw_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullwo

#mullw. found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for mullwo
try_mullwo:
addi r4, r29, ins_mullwo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_mullwo_

#mullwo found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for mullwo.
try_mullwo_:
addi r4, r29, ins_mullwo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_nand

#mullwo. found
process_three_items_left_aligned
lwz r0, 0x190 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for nand
try_nand:
addi r4, r29, ins_nand - table_start
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
addi r4, r29, ins_nand_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_neg

#nand. found
process_three_items_logical
lwz r0, 0x194 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for neg
try_neg:
addi r4, r29, ins_neg - table_start
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
addi r4, r29, ins_neg_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_nego

#neg. found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for nego
try_nego:
addi r4, r29, ins_nego - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_nego_

#nego found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for nego.
try_nego_:
addi r4, r29, ins_nego_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_nop

#nego. found
process_two_items_left_aligned
lwz r0, 0x198 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for nop
try_nop:
addi r4, r29, ins_nop - table_start
mtlr r27
mr r3, r31
li r5, 3
blrl
cmpwi r3, 0
bne- try_nor

#Nop found
lis r3, 0x6000
b epilogue_main_asm

#Check for nor
try_nor:
addi r4, r29, ins_nor - table_start
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
addi r4, r29, ins_nor_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_not

#nor. found
process_three_items_logical
lwz r0, 0x19C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for not
try_not:
addi r4, r29, ins_not - table_start
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
addi r4, r29, ins_not_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_or

#not. found
process_simpilified_logical_two_items
lwz r0, 0x19C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for or
try_or:
addi r4, r29, ins_or - table_start
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
addi r4, r29, ins_or_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_orc

#or. found
process_three_items_logical
lwz r0, 0x1A0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for orc
try_orc:
addi r4, r29, ins_orc - table_start
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
addi r4, r29, ins_orc_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ori

#orc. found
process_three_items_logical
lwz r0, 0x1A4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ori
try_ori:
addi r4, r29, ins_ori - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_oris

#ori found
process_imm_logical
oris r3, r5, 0x6000
b epilogue_main_asm

#Check for oris
try_oris:
addi r4, r29, ins_oris - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_psq_l

#oris found
process_imm_logical
oris r3, r5, 0x6400
b epilogue_main_asm

#Check for psq_l
try_psq_l:
addi r4, r29, ins_psq_l - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_lu

#psq_l found
process_imm_psq
oris r3, r5, 0xE000
b epilogue_main_asm

#Check for psq_lu
try_psq_lu:
addi r4, r29, ins_psq_lu - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_lux

#psq_lu found
process_imm_psq_update
oris r3, r5, 0xE400
b epilogue_main_asm

#Check for psq_lux
try_psq_lux:
addi r4, r29, ins_psq_lux - table_start
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
addi r4, r29, ins_psq_lx - table_start
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
addi r4, r29, ins_psq_st - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_stu

#psq_st found
process_imm_psq
oris r3, r5, 0xF000
b epilogue_main_asm

#Check for psq_stu
try_psq_stu:
addi r4, r29, ins_psq_stu - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_psq_stux

#psq_stu found
process_imm_psq_update
oris r3, r5, 0xF400
b epilogue_main_asm

#Check for psq_stux
try_psq_stux:
addi r4, r29, ins_psq_stux - table_start
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
addi r4, r29, ins_psq_stx - table_start
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
addi r4, r29, ins_ps_abs - table_start
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
addi r4, r29, ins_ps_abs_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_add

#ps_abs. found
process_two_items_left_split
lwz r0, 0x1B8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_add
try_ps_add:
addi r4, r29, ins_ps_add - table_start
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
addi r4, r29, ins_ps_add_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_cmpo0

#ps_add. found
process_three_items_left_aligned
lwz r0, 0x1BC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_cmpo0
try_ps_cmpo0:
addi r4, r29, ins_ps_cmpo0 - table_start
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
addi r4, r29, ins_ps_cmpo1 - table_start
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
addi r4, r29, ins_ps_cmpu0 - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_cmpu1

#ps_cmpu0 found
process_three_items_compare
oris r3, r5, 0x1000
b epilogue_main_asm

#Check for ps_cmpu1
try_ps_cmpu1:
addi r4, r29, ins_ps_cmpu1 - table_start
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
addi r4, r29, ins_ps_div - table_start
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
addi r4, r29, ins_ps_div_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_madd

#ps_div. found
process_three_items_left_aligned
lwz r0, 0x1CC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_madd
try_ps_madd:
addi r4, r29, ins_ps_madd - table_start
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
addi r4, r29, ins_ps_madd_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madds0

#ps_madd. found
process_four_items
lwz r0, 0x1D0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_madds0
try_ps_madds0:
addi r4, r29, ins_ps_madds0 - table_start
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
addi r4, r29, ins_ps_madds0_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_madds1

#ps_madds0. found
process_four_items
lwz r0, 0x1D4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_madds1
try_ps_madds1:
addi r4, r29, ins_ps_madds1 - table_start
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
addi r4, r29, ins_ps_madds1_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_merge00

#ps_madds1. found
process_four_items
lwz r0, 0x1D8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_merge00
try_ps_merge00:
addi r4, r29, ins_ps_merge00 - table_start
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
addi r4, r29, ins_ps_merge00_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge01

#ps_merge00. found
process_three_items_left_aligned
lwz r0, 0x1DC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_merge01
try_ps_merge01:
addi r4, r29, ins_ps_merge01 - table_start
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
addi r4, r29, ins_ps_merge01_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge10

#ps_merge01. found
process_three_items_left_aligned
lwz r0, 0x1E0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_merge10
try_ps_merge10:
addi r4, r29, ins_ps_merge10 - table_start
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
addi r4, r29, ins_ps_merge10_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_merge11

#ps_merge10. found
process_three_items_left_aligned
lwz r0, 0x1E4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_merge11
try_ps_merge11:
addi r4, r29, ins_ps_merge11 - table_start
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
addi r4, r29, ins_ps_merge11_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_mr

#ps_merge11. found
process_three_items_left_aligned
lwz r0, 0x1E8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_mr
try_ps_mr:
addi r4, r29, ins_ps_mr - table_start
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
addi r4, r29, ins_ps_mr_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_msub

#ps_mr. found
process_two_items_left_split
lwz r0, 0x1EC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_msub
try_ps_msub:
addi r4, r29, ins_ps_msub - table_start
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
addi r4, r29, ins_ps_msub_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_mul

#ps_msub. found
process_four_items
lwz r0, 0x1F0 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_mul
try_ps_mul:
addi r4, r29, ins_ps_mul - table_start
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
addi r4, r29, ins_ps_mul_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_muls0

#ps_mul. found
process_three_items_leftwo_rightone_split
lwz r0, 0x1F4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_muls0
try_ps_muls0:
addi r4, r29, ins_ps_muls0 - table_start
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
addi r4, r29, ins_ps_muls0_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_muls1

#ps_muls0. found
process_three_items_leftwo_rightone_split
lwz r0, 0x1F8 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_muls1
try_ps_muls1:
addi r4, r29, ins_ps_muls1 - table_start
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
addi r4, r29, ins_ps_muls1_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_nabs

#ps_muls1. found
process_three_items_leftwo_rightone_split
lwz r0, 0x1FC (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_nabs
try_ps_nabs:
addi r4, r29, ins_ps_nabs - table_start
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
addi r4, r29, ins_ps_nabs_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_neg

#ps_nabs. found
process_two_items_left_split
lwz r0, 0x200 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_neg
try_ps_neg:
addi r4, r29, ins_ps_neg - table_start
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
addi r4, r29, ins_ps_neg_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_nmadd

#ps_neg. found
process_two_items_left_split
lwz r0, 0x204 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_nmadd
try_ps_nmadd:
addi r4, r29, ins_ps_nmadd - table_start
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
addi r4, r29, ins_ps_nmadd_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_nmsub

#ps_nmadd. found
process_four_items
lwz r0, 0x208 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_nmsub
try_ps_nmsub:
addi r4, r29, ins_ps_nmsub - table_start
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
addi r4, r29, ins_ps_nmsub_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_res

#ps_nmsub. found
process_four_items
lwz r0, 0x20C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_res
try_ps_res:
addi r4, r29, ins_ps_res - table_start
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
addi r4, r29, ins_ps_res_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_rsqrte

#ps_res. found
process_two_items_left_split
lwz r0, 0x210 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_rsqrte
try_ps_rsqrte:
addi r4, r29, ins_ps_rsqrte - table_start
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
addi r4, r29, ins_ps_rsqrte_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_ps_sel

#ps_rsqrte. found
process_two_items_left_split
lwz r0, 0x214 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_sel
try_ps_sel:
addi r4, r29, ins_ps_sel - table_start
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
addi r4, r29, ins_ps_sel_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sub

#ps_sel. found
process_four_items
lwz r0, 0x218 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_sub
try_ps_sub:
addi r4, r29, ins_ps_sub - table_start
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
addi r4, r29, ins_ps_sub_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_ps_sum0

#ps_sub. found
process_three_items_left_aligned
lwz r0, 0x21C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_sum0
try_ps_sum0:
addi r4, r29, ins_ps_sum0 - table_start
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
addi r4, r29, ins_ps_sum0_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_ps_sum1

#ps_sum0. found
process_four_items
lwz r0, 0x220 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for ps_sum1
try_ps_sum1:
addi r4, r29, ins_ps_sum1 - table_start
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
addi r4, r29, ins_ps_sum1_ - table_start
call_sscanf_four
cmpwi r3, 4
bne- try_rfi

#ps_sum1. found
process_four_items
lwz r0, 0x224 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for rfi
try_rfi:
addi r4, r29, ins_rfi - table_start
mtlr r27
mr r3, r31
li r5, 3
blrl
cmpwi r3, 0
bne- try_rlwimi

#rfi found
lwz r3, 0x228 (r29)
b epilogue_main_asm

#Check for rlwimi
try_rlwimi:
addi r4, r29, ins_rlwimi - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rlwimi_

#rlwimi found
process_five_items
oris r3, r5, 0x5000
b epilogue_main_asm

#Check for rlwimi.
try_rlwimi_:
addi r4, r29, ins_rlwimi_ - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_slwi

#rlwimi. found
process_five_items
oris r3, r5, 0x5000
ori r3, r3, rc
b epilogue_main_asm

#Check for slwi
try_slwi:
addi r4, r29, ins_slwi - table_start
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
addi r4, r29, ins_slwi_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for srwi
try_srwi:
addi r4, r29, ins_srwi - table_start
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
addi r4, r29, ins_srwi_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for clrlwi
try_clrlwi:
addi r4, r29, ins_clrlwi - table_start
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
addi r4, r29, ins_clrlwi_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for clrrwi
try_clrrwi:
addi r4, r29, ins_clrrwi - table_start
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
addi r4, r29, ins_clrrwi_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for rotlwi
try_rotlwi:
addi r4, r29, ins_rotlwi - table_start
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
addi r4, r29, ins_rotlwi_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for rlwinm
try_rlwinm:
addi r4, r29, ins_rlwinm - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rlwinm_

#rlwinm found
process_five_items
oris r3, r5, 0x5400
b epilogue_main_asm

#Check for rlwinm.
try_rlwinm_:
addi r4, r29, ins_rlwinm_ - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rotlw

#rlwinm. found
process_five_items
oris r3, r5, 0x5400
ori r3, r3, rc
b epilogue_main_asm

#Check for rotlw
try_rotlw:
addi r4, r29, ins_rotlw - table_start
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
addi r4, r29, ins_rotlw_ - table_start
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
ori r3, r3, rc
b epilogue_main_asm

#Check for rlwnm
try_rlwnm:
addi r4, r29, ins_rlwnm - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_rlwnm_

#rlwnm found
process_five_items
oris r3, r5, 0x5C00
b epilogue_main_asm

#Check for rlwnm.
try_rlwnm_:
addi r4, r29, ins_rlwnm_ - table_start
call_sscanf_five
cmpwi r3, 5
bne- try_sc

#rlwnm. found
process_five_items
oris r3, r5, 0x5C00
ori r3, r3, rc
b epilogue_main_asm

#Check for sc
try_sc:
addi r4, r29, ins_sc - table_start
mtlr r27
mr r3, r31
li r5, 2
blrl
cmpwi r3, 0
bne- try_slw

#sc found
lwz r3, 0x22C (r29)
b epilogue_main_asm

#Check for slw
try_slw:
addi r4, r29, ins_slw - table_start
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
addi r4, r29, ins_slw_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sraw

#slw. found
process_three_items_logical
lwz r0, 0x230 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for sraw
try_sraw:
addi r4, r29, ins_sraw - table_start
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
addi r4, r29, ins_sraw_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srawi

#sraw. found
process_three_items_logical
lwz r0, 0x234 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for srawi
try_srawi:
addi r4, r29, ins_srawi - table_start
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
addi r4, r29, ins_srawi_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_srw

#srawi. found
process_three_items_logical
lwz r0, 0x238 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for srw
try_srw:
addi r4, r29, ins_srw - table_start
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
addi r4, r29, ins_srw_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stb

#srw. found
process_three_items_logical
lwz r0, 0x23C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for stb
try_stb:
addi r4, r29, ins_stb - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stbu

#stb found
process_imm_storeload
oris r3, r5, 0x9800
b epilogue_main_asm

#Check for stbu
try_stbu:
addi r4, r29, ins_stbu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stbux

#stbu found
process_imm_update_rAneq0
oris r3, r5, 0x9C00
b epilogue_main_asm

#Check for stbux
try_stbux:
addi r4, r29, ins_stbux - table_start
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
addi r4, r29, ins_stbx - table_start
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
addi r4, r29, ins_stfd - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfdu

#stfd found
process_imm_storeload
oris r3, r5, 0xD800
b epilogue_main_asm

#Check for stfdu
try_stfdu:
addi r4, r29, ins_stfdu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfdux

#stfdu found
process_imm_update_rAneq0
oris r3, r5, 0xDC00
b epilogue_main_asm

#Check for stfdux
try_stfdux:
addi r4, r29, ins_stfdux - table_start
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
addi r4, r29, ins_stfdx - table_start
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
addi r4, r29, ins_stfiwx - table_start
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
addi r4, r29, ins_stfs - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfsu

#stfs found
process_imm_storeload
oris r3, r5, 0xD000
b epilogue_main_asm

#Check stfsu
try_stfsu:
addi r4, r29, ins_stfsu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stfsux

#stfsu found
process_imm_update_rAneq0
oris r3, r5, 0xD400
b epilogue_main_asm

#Check for stfsux
try_stfsux:
addi r4, r29, ins_stfsux - table_start
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
addi r4, r29, ins_stfsx - table_start
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
addi r4, r29, ins_sth - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sthbrx

#sth found
process_imm_storeload
oris r3, r5, 0xB000
b epilogue_main_asm

#Check for sthbrx
try_sthbrx:
addi r4, r29, ins_sthbrx - table_start
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
addi r4, r29, ins_sthu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sthux

#sthu found
process_imm_update_rAneq0
oris r3, r5, 0xB400
b epilogue_main_asm

#Check for sthux
try_sthux:
addi r4, r29, ins_sthux - table_start
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
addi r4, r29, ins_sthx - table_start
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
addi r4, r29, ins_stmw - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stswi

#stmw found
process_imm_storeload
oris r3, r5, 0xBC00
b epilogue_main_asm

#Check for stswi
try_stswi:
addi r4, r29, ins_stswi - table_start
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
addi r4, r29, ins_stswx - table_start
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
addi r4, r29, ins_stw - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwbrx

#stw found
process_imm_storeload
oris r3, r5, 0x9000
b epilogue_main_asm

#Check for stwbrx
try_stwbrx:
addi r4, r29, ins_stwbrx - table_start
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
addi r4, r29, ins_stwcx_ - table_start
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
addi r4, r29, ins_stwu - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_stwux

#stwu found
process_imm_update_rAneq0
oris r3, r5, 0x9400
b epilogue_main_asm

#Check for stwux
try_stwux:
addi r4, r29, ins_stwux - table_start
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
addi r4, r29, ins_stwx - table_start
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
addi r4, r29, ins_subf - table_start
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
addi r4, r29, ins_subf_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfo

#subf. found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subfo
try_subfo:
addi r4, r29, ins_subfo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfo_

#subfo found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subfo.
try_subfo_:
addi r4, r29, ins_subfo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_sub

#subfo. found
process_three_items_left_aligned
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for sub
try_sub:
addi r4, r29, ins_sub - table_start
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
addi r4, r29, ins_sub_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subo

#sub. found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subo
try_subo:
addi r4, r29, ins_subo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subo_

#subo found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subo.
try_subo_:
addi r4, r29, ins_subo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfc

#subo. found
process_simp_sub_subc
lwz r0, 0x280 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for subfc
try_subfc:
addi r4, r29, ins_subfc - table_start
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
addi r4, r29, ins_subfc_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfco

#subfc. found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subfco
try_subfco:
addi r4, r29, ins_subfco - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfco_

#subfco found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subfco.
try_subfco_:
addi r4, r29, ins_subfco_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subc

#subfco. found
process_three_items_left_aligned
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for subc
try_subc:
addi r4, r29, ins_subc - table_start
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
addi r4, r29, ins_subc_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subco

#subc. found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subco
try_subco:
addi r4, r29, ins_subco - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subco_

#subco found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subco.
try_subco_:
addi r4, r29, ins_subco_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfe

#subco. found
process_simp_sub_subc
lwz r0, 0x284 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for subfe
try_subfe:
addi r4, r29, ins_subfe - table_start
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
addi r4, r29, ins_subfe_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfeo

#subfe. found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subfeo
try_subfeo:
addi r4, r29, ins_subfeo - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfeo_

#subfeo found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subfeo.
try_subfeo_:
addi r4, r29, ins_subfeo_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfic

#subfeo. found
process_three_items_left_aligned
lwz r0, 0x288 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for subfic
try_subfic:
addi r4, r29, ins_subfic - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_subfme

#subfic found
process_imm_nonstoreload
oris r3, r5, 0x2000
b epilogue_main_asm

#Check for subfme
try_subfme:
addi r4, r29, ins_subfme - table_start
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
addi r4, r29, ins_subfme_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfmeo

#subfme. found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subfmeo
try_subfmeo:
addi r4, r29, ins_subfmeo - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfmeo_

#subfmeo found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subfmeo.
try_subfmeo_:
addi r4, r29, ins_subfmeo_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfze

#subfmeo. found
process_two_items_left_aligned
lwz r0, 0x28C (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for subfze
try_subfze:
addi r4, r29, ins_subfze - table_start
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
addi r4, r29, ins_subfze_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfzeo

#subfze. found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for subfzeo
try_subfzeo:
addi r4, r29, ins_subfzeo - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_subfzeo_

#subfzeo found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
ori r3, r3, oe
b epilogue_main_asm

#Check for subfzeo.
try_subfzeo_:
addi r4, r29, ins_subfzeo_ - table_start
call_sscanf_two
cmpwi r3, 2
bne- try_sync

#subfzeo. found
process_two_items_left_aligned
lwz r0, 0x290 (r29)
or r3, r0, r5
ori r3, r3, oe | rc
b epilogue_main_asm

#Check for sync
try_sync:
addi r4, r29, ins_sync - table_start
mtlr r27
mr r3, r31
li r5, 4
blrl
cmpwi r3, 0
bne- try_tlbie

#sync found
lwz r3, 0x294 (r29)
b epilogue_main_asm

#Check for tlbie
try_tlbie:
addi r4, r29, ins_tlbie - table_start
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
addi r4, r29, ins_tlbsync - table_start
mtlr r27
mr r3, r31
li r5, 7
blrl
cmpwi r3, 0
bne- try_trap

#tlbsync found
lwz r3, 0x29C (r29)
b epilogue_main_asm

#Check for trap
try_trap:
addi r4, r29, ins_trap - table_start
mtlr r27
mr r3, r31
li r5, 4
blrl
cmpwi r3, 0
bne- try_tw

#trap found
lwz r3, 0x2B0 (r29)
b epilogue_main_asm

#Check for tw
try_tw:
addi r4, r29, ins_tw - table_start
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
addi r4, r29, ins_twi - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xor

#twi found
process_imm_nonstoreload
oris r3, r5, 0x0C00
b epilogue_main_asm

#Check for xor
try_xor:
addi r4, r29, ins_xor - table_start
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
addi r4, r29, ins_xor_ - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xori

#xor. found
process_three_items_logical
lwz r0, 0x2A4 (r29)
or r3, r0, r5
ori r3, r3, rc
b epilogue_main_asm

#Check for xori
try_xori:
addi r4, r29, ins_xori - table_start
call_sscanf_three
cmpwi r3, 3
bne- try_xoris

#xori found
process_imm_logical
oris r3, r5, 0x6800
b epilogue_main_asm

#Check for xoris
try_xoris:
addi r4, r29, ins_xoris - table_start
call_sscanf_three
cmpwi r3, 3
bne- try__long

#xoris found
process_imm_logical
oris r3, r5, 0x6C00
b epilogue_main_asm

#Check for .long (custom 8 digit hex value)
try__long:
addi r4, r29, invalid_instruction - table_start #Doesn't literally mean invalid instruction, I carried look-up table over from disassmebler, plus there's always a possiblility of merging both the assembler and disassembler into one 'unit/code'
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
lmw r27, 0x1C (sp)
lwz r0, 0x0034 (sp)
mtlr r0
addi sp, sp, 0x0030
blr

