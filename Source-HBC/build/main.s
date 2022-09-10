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
	.file	"main.c"
	.machine ppc
	.section	".text"
	.globl __eabi
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"\033[2;0H" #Init Cursor
.LC1:
    .string "\x1b[2J" #Reset Cursor, clear current screen contents
.LC2:
    .string "\n\n       /\\      /\\\n      /  \\____/  \\\n     |            |\n     |  @      @  |\n     |___>_**_<___|\n  _______======_______\n (______        ______)\n        |      |\n        |      |        _\n        |      |_______/ |\n        |      |________/\n       / ______ \\\n      / /      \\ \\\n     /_/        \\_\\\nWelcome to \x1b[43m\x1b[30mWaltress\x1b[40m\x1b[37m! The PPC Assembler+Disassembler that's entirely handwritten in PPC! You can also compile+decompile Gecko Codes! Read the README for more info.\n\nPress \x1b[32mA\x1b[37m to Assemble source.s to code.txt. Press Y/+ to Assemble source.s to code.bin. Press \x1b[31mB\x1b[37m to Disassemble code.txt to source.s. Press X/- to Disassemble code.bin to source.s.\n\n*NOTE: Y/+ designates Y on Classic/GCN, and X/- designates X on Classic/GCN.\n\nCreated by \x1b[35mVega\x1b[37m. Version: 0.5\nPress Home/Start button to exit back to \x1b[36mHBC\x1b[37m. Visit www.MarioKartWii.com for questions or bug reports."
.LC3:
    .string "dbin.bin"
.LC4:
    .string "rb"
.LC5:
    .string "source.s"
.LC6:
    .string "code.bin"
.LC7:
    .string "wb"
.LC8:
    .string "\n\n\x1b[32mSUCCESS!\x1b[37m code.txt/bin has been disassembled. Disassembled instructions are in source.s file located at apps/Waltress. Press Home/Start button to exit back to \x1b[36mHBC\x1b[37m.\n\nOptionally, you can press the \x1b[31mB\x1b[37m button your controller to delete the original file (code.txt/bin) and then you will automatically exit back to \x1b[36mHBC\x1b[37m."
.LC9:
    .string "abin.bin"
.LC10:
	.string "\n\n\x1b[32mSUCCESS!\x1b[37m source.s has been assembled. Assembled instructions are in code.txt/bin file located at apps/Waltress. Press Home/Start button to exit back to \x1b[36mHBC\x1b[37m.\n\nOptionally, you can press the \x1b[31mB\x1b[37m button your controller to delete the original file (source.s) and then you will automatically exit back to \x1b[36mHBC\x1b[37m."
.LC11:
    .string "\n\n\x1b[31mError! \x1b[37m%d\n\nPlease read the ERRORS.txt file more information. Press Home/Start button to exit back to \x1b[36mHBC\x1b[37m."
.LC12:
    .string "\n\n\x1b[37mExiting back to \x1b[36mHBC\x1b[37m..."
.LC13:
    .string "code.txt"
.LC14:
    .string "%08X"
.LC15:
    .string "\n\n\x1b[37mOriginal file has been deleted. Auto-exiting back to \x1b[36mHBC\x1b[37m..."
.LC16:
    .string "\n\n\x1b[37mError! Unable to delete original file. Auto-exiting back to \x1b[36mHBC\x1b[37m..."
.LC17:
    .string "!%08X"
.LC18:
    .string "\n\nBefore Waltress can execute the Disassembly/Decompilation, please choose one of the Options:\n\nA = Raw\nB = 32-bit RAM Write\nY/+ = String Write\nX/- = Execute ASM\nL/1 = Insert ASM\nStart/Home = Exit to \x1b[36mHBC\x1b[37m.\n\n\n*NOTE: Y/+ designates Y button for Classic/GCN. X/- designates X button for Classic/GCN."
.LC19:
    .string "!04%06X"
.LC20:
    .string "!06%06X"
.LC21:
    .string "!C2%06X"
	.section	.text.startup,"ax",@progbits
	.align 2
	.globl main
	.type	main, @function
main:
.LFB86:
	.cfi_startproc
	stwu 1,-16(1)
	.cfi_def_cfa_offset 16
	mflr 0
	stw 0,20(1)
	stmw 30,8(1)
	.cfi_offset 65, 4
	.cfi_offset 30, -8
	.cfi_offset 31, -4
	bl __eabi
	bl VIDEO_Init
	lis 31,.LANCHOR0@ha
	bl WPAD_Init
	bl PAD_Init #Added in GC controller capabilities!!!
	li 3,0
	bl VIDEO_GetPreferredMode
	la 30,.LANCHOR0@l(31)
	stw 3,.LANCHOR0@l(31)
	bl SYS_AllocateFramebuffer
	lwz 9,.LANCHOR0@l(31)
	li 5,20
	li 4,20
	addis 3,3,0x4000
	lhz 6,4(9)
	lhz 7,8(9)
	slwi 8,6,1
	stw 3,4(30)
	bl CON_Init
	lwz 3,.LANCHOR0@l(31)
	bl VIDEO_Configure
	lwz 3,4(30)
	bl VIDEO_SetNextFramebuffer
	li 3,0
	bl VIDEO_SetBlack
	bl VIDEO_Flush
	bl VIDEO_WaitVSync
	lwz 9,.LANCHOR0@l(31)
	lwz 9,0(9)
	andi. 9,9,0x1
	beq+ 0, launch_app
	bl VIDEO_WaitVSync
	
launch_app:
    #Init the Console Cursor
	lis 3,.LC0@ha
	la 3,.LC0@l(3)
	crxor 6,6,6
	bl printf
	
	#Init FAT System
	bl fatInitDefault
	cmpwi r3, 0
	li r4, -1
	beq- error
	
	#Reset cursor to slightly move its default position
    lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
	
	#Display Main Menu Message
    lis 3,.LC2@ha
	la 3,.LC2@l(3)
	crxor 6,6,6
	bl printf
	
	#Read Controllers
main_menu:
	bl WPAD_ScanPads
	li r3, 0
	bl WPAD_ButtonsDown
	mr r31, r3
	bl PAD_ScanPads
	li r3, 0
	bl PAD_ButtonsDown
	andi. r0, r3, 0x1000 #GCN Start
	bne- leave_to_hbc
	andi. r0, r31, 0x0080 #Wheel/Chuck Home
	bne- leave_to_hbc
	andis. r0, r31, 0x0800 #Classic Home
	bne- leave_to_hbc
	#Set r26 flag, 0 = txt, 1 = bin
	li r26, 0
	andi. r0, r3, 0x0100 #GCN A
	bne- assemble
	andi. r0, r31, 0x0008 #Wheel/Chuck A
	bne- assemble
	andis. r0, r31, 0x0010 #Classic A
	bne- assemble
	andi. r0, r3, 0x0200 #GCN B
	bne- pre_dasm_execute_menu
	andi. r0, r31, 0x0004 #Wheel/Chuck B
	bne- pre_dasm_execute_menu
	andis. r0, r31, 0x0040 #Classic B
	bne- pre_dasm_execute_menu
	#Set r26 flag, 0 = txt, 1 = bin
	li r26, 1
	andi. r0, r3, 0x0800 #GCN Y
	bne- assemble
	andi. r0, r31, 0x1000 #Wheel/Chuck +
	bne- assemble
	andis. r0, r31, 0x0020 #Classic y
	bne- assemble
	andi. r0, r3, 0x0400 #GCN X
	bne- pre_dasm_execute_menu
	andi. r0, r31, 0x0010 #Wheel/Chuck -
	bne- pre_dasm_execute_menu
	andis. r0, r31, 0x0008 #Classic X
	beq+ sync_video #Jump to VIDEO_WaitVSync
	
	#Go into secondary menu since Disassemble was chosen
pre_dasm_execute_menu:
#Reset cursor first
    lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf

    #Print updated message
    lis 3,.LC18@ha
    la 3,.LC18@l(3)
    crxor 6,6,6
    bl printf

    #Scan buttons
    idle_on_pre_dasm:
    bl WPAD_ScanPads
    li r3, 0
    bl WPAD_ButtonsDown
    mr r31, r3
    bl PAD_ScanPads
    li r3, 0
    bl PAD_ButtonsDown
    andi. r0, r3, 0x1000 #GCN Start
    bne- leave_to_hbc
    andi. r0, r31, 0x0080 #Wheel/Chuck Home
    bne- leave_to_hbc
    andis. r0, r31, 0x0800 #Classic Home
    bne- leave_to_hbc

    #r14 = Dasm Mode
    #0 = Raw
    #1 = 04
    #2 = 06
    #3 = C0
    #4 = C2
    li r14, 0
    andi. r0, r3, 0x0100 #GCN A
    bne- disassemble
    andi. r0, r31, 0x0008 #Wheel/Chuck A
    bne- disassemble
    andis. r0, r31, 0x0010 #Classic A
    bne- disassemble
    li r14, 1
    andi. r0, r3, 0x0200 #GCN B
    bne- disassemble
    andi. r0, r31, 0x0004 #Wheel/Chuck B
    bne- disassemble
    andis. r0, r31, 0x0040 #Classic B
    bne- disassemble
    li r14, 2
    andi. r0, r3, 0x0800 #GCN Y
    bne- disassemble
    andi. r0, r31, 0x1000 #Wheel/Chuck +
    bne- disassemble
    andis. r0, r31, 0x0020 #Classic Y
    bne- disassemble
    li r14, 3
    andi. r0, r3, 0x0400 #GCN X
    bne- disassemble
    andi. r0, r31, 0x0010 #Wheel/Chuck Minus
    bne- disassemble
    andis. r0, r31, 0x0008 #Classic X
    bne- disassemble
    li r14, 4
    andi. r0, r3, 0x0040 #GCN L
    bne- disassemble
    andi. r0, r31, 0x0002 #Wheel/Chuck 1
    bne- disassemble
    andis. r0, r31, 0x2000 #Classic L
    bne- disassemble

    #Sync Video
    bl VIDEO_WaitVSync
    b idle_on_pre_dasm
	#Disassemble!
disassemble:
    #Open dbin.bin, get size, alloc mem for it, dump it, close
    #Pre-Open source.s to make sure one doesn't alread exist
    #Open code.txt/bin, get size, alloc mem for it, dump it, close
    #Alloc mem for new source.s (Size of code.bin x 32)
    #Run dbin.bin engine
    #Create source.s, write to it, close. Print SUCCESS
    
    #Reset cursor first
    lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
    
    #Open dbin.bin
    lis 3,.LC3@ha
	la 3,.LC3@l(3)
	lis 4,.LC4@ha
	la 4,.LC4@l(4)
	bl fopen
	mr. r31, r3 #Check & Backup fp
	li r4, -2
	beq- error
	
	#Get size of dbin.bin via fseek and ftell
	li r4, 0
	li r5, 2 #SEEK_END
	bl fseek
	cmpwi r3, 0
	li r4, -3
	bne- error
	mr r3, r31
	bl ftell #No need for error checks
	
	#Rewind to set stream position of file back to the start of file
	#Then allocate memory
	mr r30, r3 #Backup size of dbin.bin
	mr r3, r31
	bl rewind #No need for error checks
	li r3, 32 #32-byte alignment
	mr r4, r30 #Size
	bl memalign
	mr. r29, r3 #Check & Backup dbin.bin mem pointer
	li r4, -4
	beq- error
	
	#Dump dbin.bin, then close
	li r4, 1 #size (not real size)
	mr r5, r30 #count (real size of dbin.bin)
	mr r6, r31 #fp
	bl fread
	cmpw r3, r30 #CHECK COUNT, not size
	li r4, -5
	bne- error
	mr r3, r31
	bl fclose
	cmpwi r3, 0
	li r4, -6
    bne- error
	
	#Pre-open source.s, shouldn't exist
	lis 3,.LC5@ha
	la 3,.LC5@l(3)
	lis 4,.LC4@ha
	la 4,.LC4@l(4)
	bl fopen
	cmpwi r3, 0
	li r4, -7
	bne- error #YES THIS IS A BNE! We don't want it to exist
	
	#Check r26 flag on which file to open
	#0 = disassembling code.txt to source.s
	#1 = disassembling code.bin to source.s
	cmpwi r26, 0
	#Preset code.txt as r3 fopen arg
	lis 3,.LC13@ha
	la 3,.LC13@l(3)
	beq- continue_dasm
	
	#Set code.bin as r3 fopen arg
	lis 3,.LC6@ha
	la 3,.LC6@l(3)
	
continue_dasm:
	lis 4,.LC4@ha
	la 4,.LC4@l(4)
	bl fopen
	mr. r31, r3 #Check & Backup fp
	li r4, -8
	beq- error
	
	#Get size of code.txt/bin via fseek and ftell
	li r4, 0
	li r5, 2 #SEEK_END
	bl fseek
	cmpwi r3, 0
	li r4, -9
	bne- error
	mr r3, r31
	bl ftell #No need for error check
	
	#Rewind to set stream position of file back to the start of file
	#Then allocate memory
	mr r28, r3 #Backup code.txt/bin size
	mr r3, r31
	bl rewind #No need for error checks
	li r3, 32 #32-byte alignment
	mr r4, r28 #Size
	bl memalign
	mr. r27, r3 #Check & Backup code.txt/bin INPUT mem pointer
	li r4, -10
	beq- error
	
	#Dump code.txt/bin, then close
	li r4, 1 #size (not real size)
	mr r5, r28 #count (real size of code.txt/bin)
	mr r6, r31 #fp
	bl fread
	cmpw r3, r28 #CHECK COUNT, not size
	li r4, -11
	bne- error
	mr r3, r31
	bl fclose
	cmpwi r3, 0
	li r4, -12
    bne- error
    
    #Check r26 flag on what size for memalign for new gen source.s
    cmpwi r26, 0
    #Largest instruction in ascii (plus the 0xA byte) possible is psq_lux for a size of 32 bytes.
    #An instruction in code.txt is always 9 bytes long. 32/9 = 4 (rounded up), so mulli by 4
    slwi r4, r28, 2
    beq- still_continue_dasm
    
    #Largest instruction in ascii (plus the 0xA byte) possible is psq_lux for a size of 32 bytes.
    #An instruction in code.bin is always 4 bytes long. 32/4 = 8, so mulli by 8
    slwi r4, r28, 3 #Mulli by 8
    
still_continue_dasm:
    li r3, 32
    bl memalign
    mr. r31, r3 #Backup pointer to new source.s
    li r4, -13
    beq- error
    
    #Software is required to store sprintf func addr to the reserved lookup table spot in dbin.bin
    lis r0, sprintf@h
    ori r0, r0, sprintf@l
    stw r0, 0x414 (r29)
    
    #fread doesn't do any cache updates btw, we need to do a dcbst and icbi for the entire dbin.bin file
    mr r3, r29 #Pointer of dbin.bin
    mr r4, r30 #Size of dbin.bin
    bl DCStoreRange
    mr r3, r29 #Pointer of dbin.bin
    mr r4, r30 #Size of dbin.bin
    bl ICInvalidateRange
    
    #Check r26 flag to see if we are gonna have to transform a code.txt into code.bin
    cmpwi r26, 0
    bne- prep_before_sending_to_waltress_disassembler
    
    #We are working with code.txt, we need to transform it to code.bin for Waltress D engine
    lis 25,.LC14@ha
	la 25,.LC14@l(25)
    
    #Call sscanf to change ASCII assembled instruction to it's Hex word equivalent
    #We can re-store on the same memalign block cuz Hex Word (4 bytes) is always shorter than ASCII 8-bit word (8 bytes)
    mr r24, r27
    addi r23, r27, -4
    
    #r22 is a flag, when null the byte loaded at r24+0x8 must be 0x20 (space), when -1 the byte loaded at r24+8 must be 0xA (enter). r22 will be notted for each loop iteration
    li r22, -1
    
    #Use r28 to calc code.bin, it's needed for Waltress Assembler Engine
    li r28, 0 #Start at zero
    
convert_codetxt_to_codebin:
    not. r22, r22
    lbz r0, 0x8 (r24) #Make sure a space or enter is after the instruction
    bne- check_for_enter
    
    cmpwi r0, 0x20
    b finish_space_enter_check
    
    check_for_enter:
    cmpwi r0, 0x0A
    
finish_space_enter_check:
    li r4, -14
    bne- error
    
    #Increment updating sscanf r5 arg (place to dump Hex PPC Instruction to)
    addi r23, r23, 4 
    mr r5, r23
    
    #Set sscanf r3 arg
    mr r3, r24
    
    #Set sscanf r4arg
    mr r4, r25
    
    #sscanf
    #r3 = mem pointer to formatted string (what's already present)
    #r4 = mem pointer to unformatted string (how the r3 arg will be deciphered)
    #r5 = place to dump format variable
    bl sscanf
    cmpwi r3, 1 #sscanf diff than sprintf for return values. sscanf does successful dumps, not total bytes formatted
    li r4, -15
    bne- error
    
    #Update code.bin size
    addi r28, r28, 4
    
    #Check for EoF (end of file)
    lbz r0, 0x9 (r24)
    cmpwi r0, 0
    beq- prep_before_sending_to_waltress_disassembler
    
    #Increment updating sscanf r3 arg (place where ASCII PPC assembled instruction is at)
    addi r24, r24, 9 
    b convert_codetxt_to_codebin
    
    #Check r14 flag to know how to disassemble
    #r27 = Start of code.bin (input file sent to Waltress DASM)
    #r31 = Start of output file for soon-to-be-generated source.s
    #r28 = size of code.bin in bytes
prep_before_sending_to_waltress_disassembler:
    cmpwi r14, 0
    beq- setup_D_loop
    cmpwi r14, 1
    beq- decomp_04
    cmpwi r14, 2
    beq- decomp_06
    cmpwi r14, 3
    beq- decomp_C0

    #C2 chosen
    #Sanity check to make sure we are on a C2
    lbz r0, 0 (r27)
    cmpwi r0, 0xC2
    li r4, -16
    bne- error
    lis 4,.LC21@ha
	la 4,.LC21@l(4)
    b run_decomp_sprintf
    
decomp_04:
    #04 chosen
    #Sanity check to make sure we are on 04
    lbz r0, 0 (r27)
    cmpwi r0, 0x04
    li r4, -17
    bne- error
    lis 4,.LC19@ha
	la 4,.LC19@l(4)
    b run_decomp_sprintf
    
decomp_06:
    #06 chosen
    #Sanity check to make sure we are on 06
    lbz r0, 0 (r27)
    cmpwi r0, 0x06
    li r4, -18
    bne- error
    lis 4,.LC20@ha
	la 4,.LC20@l(4)
    b run_decomp_sprintf
    
decomp_C0:
    #C0 chosen
    #Sanity check to make sure we are on C0
    lwz r0, 0 (r27) #Load WORD, not byte for C0 opcode check because "C0000000"
    lis r3, 0xC000
    cmpw r0, r3
    li r4, -19
    bne- error
    
    #Write out "!C0/n" in ASCII, store to start of output file (source.s)
    lis r0, 0x2143
    ori r0, r0, 0x300A
    stw r0, 0 (r31)
    
    #Load final word of code.bin, check for null or blr
    addi r3, r28, -4
    lwzx r0, r3, r27
    lis r4, 0x4E80
    ori r4, r4, 0x0020
    cmplw r0, r4
    beq- finish_decomp_c0
    
    #NOTE: By reducing r28, we are "removing" tail instructions that would be sent to the Waltress Disassembler Engine
    
    #Check if 2nd to last compiled word in C0 is a blr
    #For the case it's not, jump directly to finish_decomp_c0, as we only want to reduce r28 by a total of 4
    #For the case it IS, reduce r28 by a total of 8
    addi r3, r3, -4
    lwzx r0, r3, r27
    cmplw r0, r4
    bne- finish_decomp_c0
    
    #blr as second to last instruction, null word as last instruction
    #Reduce r28 by extra 4 to account for this blr being at bottom-left of C0 code
    subi r28, r28, 4
    
    finish_decomp_c0:
    #Increment r27, and r31. Update r28 so C0 specific-blr is EXcluded from being placed into source.s
    addi r27, r27, 8 #Skip past gecko opcode and reserved line-count spot
    #Backup real r31
    mr r15, r31
    addi r31, r31, 4 #Skip past "!C0\n"
    
    #Finally reduce r28 by 12 more bytes to exclude Gecko Opcode, Line Count Word, & final-blr/null-word
    subi r28, r28, 12
    b setup_D_loop
    
run_decomp_sprintf:
    lwz r5, 0 (r27)
    clrlwi r5, r5, 8
    mr r3, r31
    bl sprintf
    cmpwi r3, 9
    li r4, -20
    bne- error
    
    #Check for 04 Ram write
    cmpwi r14, 1
    beq- finish_decomp_04
    cmpwi r14, 2
    beq- finish_decomp_06
    
    #Finish decomp C2, last word of C2 must always be Null
    addi r3, r28, -4
    lwzx r4, r3, r27
    cmpwi r4, 0
    li r4, -21
    bne- error
    #Now see if a C2-auto-applied nop is second to last word
    #For the case C2 code size ends in 0x0 or 0x8, then the nop next to null word was auto applied
    #For the case size ends in 0x4 or 0xC, then the nop is a nop that is purposefully apart of the code's source
    addi r3, r3, -4
    lwzx r4, r3, 27
    lis r5, 0x6000
    cmplw r4, r5
    bne- final_reduce_c2
    #C2-related nop found, reduce r28 by extra 4 bytes so Waltress d-engine won't process this nop
    subi r28, r28, 4
    #Finally reduce r28 by 12 more bytes to exclude Opcode, Line Count word, and Null word
final_reduce_c2:
    subi r28, r28, 12
    b finalize_06C2_before_waltress_dasm
    
finish_decomp_04:
    li r28, 4 #Make waltress d-engine only run 1 instruction of for source.s
    b finalize_0406C2_before_waltress_dasm
    
finish_decomp_06:
    #Load byte count of 06 string code, round up to make it divisible by 4
    #Then use that as r28 amount for loop usage of Waltress Disassembler Engine
    lwz r28, 0x4 (r27)
    clrlwi. r0, r28, 30
    beq- finalize_06C2_before_waltress_dasm
    clrrwi r28, r28, 2
    addi r28, r28, 4
    
finalize_06C2_before_waltress_dasm:
    addi r27, r27, 4
    
finalize_0406C2_before_waltress_dasm:
    addi r27, r27, 4
    li r0, 0xA
    stb r0, 0x9 (r31)
    #Backup real r31
    mr r15, r31
    addi r31, r31, 10 #Skip past !Gecko Opcode and the enter/space
    
#RUN WALTRESS Disassembler
#Set pointer where the new source.s will be located
#r31 = Pointer to new source.s r4 arg
#r27 = Pointer to code.bin input r3 arg
#r28 = Pointer to code.bin input size

#Waltress Disassembler Engine
#r3 arg = Instruction to Disassemble
#r4 arg = Pointer to write new Source line to (NOTE nothing is appended by the engine!)

#Setup stuff for d_loop
setup_D_loop:
addi r27, r27, -4 #Updating pointer for r3 arg
addi r30, r31, -1 #Updating pointer for r4 arg, keep r31 intact, will be after D_loop is done
srwi r28, r28, 2 #Divide byte size by 4 to get loop amount aka how many compiled instructions are in the file

#D_loop
D_loop:
lwzu r3, 0x4 (r27) #Load r3 arg
addi r30, r30, 1 #Make sure r30 points past 0xA byte for next source line (ofc if a previous source line was written)
mr r4, r30 #Set dbin.bin r4 arg

mtlr r29
blrl #CALL WALTRESS DISASSEMBLER ENGINE

cmpwi r3, 0
subi r4, r3, 21 #NOTE: Make -1 be -22, make -2 be -23
bne- error

#Decrementer loop, update 'cursor'. Write 0xA (enter new line) after new source line. Cursor will be moved to the new generated 0xA
move_cursor:
lbzu r0, 0x1 (r30) #Since it's impossible for a source line to be just one char long, we don't need an 'addi r30, r30, -1' beforehand!
cmpwi r0, 0 #Check for null byte after newly generated source line
bne+ move_cursor #move 'cursor' to update r23, so when next time DASM runs, r4 arg is correctly updated

#End of source line (also possible end of code.bin file) has been reached, store 0xA. Fyi this will make source.s end by a 0xA byte (ascii for enter-in-new-line) which is perfect because the Assembler follows that format rule
li r0, 0xA
stb r0, 0 (r30)

#Cursor is set, decrement D_loop
subic. r28, r28, 1
bne+ D_loop
    
    #Disassembler completed 100%, create source.s (fopen with write perms)
    #For the case of using Raw, r31 is real r31. If not, it's in r15
    cmpwi r14, 0
    beq- got_real_r31
    mr r31, r15
got_real_r31:
    lis 3,.LC5@ha
	la 3,.LC5@l(3)
	lis 4,.LC7@ha
	la 4,.LC7@l(4)
	bl fopen
	mr. r29, r3 #Check & Backup fp
	li r4, -24
	beq- error
	
	#Write source.s, then close
	mr r3, r31 #mem pointer to new source.s
	#Calc file size by taking r31 (start of source.s) and subtract it from r30 from D_loop which is the last byte (0xA) address of source.s. After doing the subtraction, add 1 for margin
    subf r31, r31, r30 #Place in a GVR for later r3 return value check
    addi r31, r31, 1 #+1 needed for equation
    li r4, 1 #Size (not real size)
    mr r5, r31 #Count (real size)
	mr r6, r29 #fp
	bl fwrite
	cmpw r3, r31 #CHECK COUNT, not size
	li r4, -25
	bne- error
	mr r3, r29
	bl fclose
	cmpwi r3, 0
	li r4, -26
	bne- error
	
	#SUCCESS
    lis 3,.LC8@ha
	la 3,.LC8@l(3)
	
	#Set r30 flag for possible input file deletion
	#r30 = 0 (code.txt/bin)
	#r30 = 1 (source.s)
	#r30 = -1 (can't delete due to error)
	li r30, 0
	b output_message
	
#==================================================================#

    #Assemble!
assemble:
    #Open abin.bin, get size, alloc mem for it, dump it, close
    #Open code.bin to make sure one doesn't pre-exist
    #Open source.s, get size, alloc mem for it, dump it, close
    #Count 0xA bytes to roughly figure out instruction coutn to gen mem size for source.s
    #Alloc mem for new source.s
    #Run abin.bin engine
    #Create code.bin, write to it, close. Print SUCCESS
    
    #Reset cursor first
    lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
    
    #Open abin.bin
    lis 3,.LC9@ha
	la 3,.LC9@l(3)
	lis 4,.LC4@ha
	la 4,.LC4@l(4)
	bl fopen
	mr. r31, r3 #Check & Backup fp
	li r4, -27
	beq- error
	
	#Get size of abin.bin via fseek and ftell
	li r4, 0
	li r5, 2 #SEEK_END
	bl fseek
	cmpwi r3, 0
	li r4, -28
	bne- error
	mr r3, r31
	bl ftell #No need for error check
	
	#Rewind to set stream position of file back to the start of file
	#Then allocate memory
	mr r30, r3 #Backup size, no need for check after ftell
	mr r3, r31
	bl rewind #No need for error check
	li r3, 32 #32-byte alignment
	mr r4, r30 #Size
	bl memalign
	mr. r29, r3 #Check & Backup abin.bin mem pointer
	li r4, -29
	beq- error
	
	#Dump abin.bin, then close
	li r4, 1 #size (not real size)
	mr r5, r30 #count (real size of abin.bin)
	mr r6, r31 #fp
	bl fread
	cmpw r3, r30 #CHECK COUNT, not size
	li r4, -30
	bne- error
	mr r3, r31
	bl fclose
	cmpwi r3, 0
	li r4, -31
    bne- error
    
    #Pre-open code.txt if r26=0, pre-open code.bin if r26=1
    cmpwi r26, 0
    lis 3,.LC13@ha
	la 3,.LC13@l(3)
	beq- continue_asm
	
	#Pre-open code.bin, shouldn't exist
	lis 3,.LC6@ha
	la 3,.LC6@l(3)
	
continue_asm:
	lis 4,.LC4@ha
	la 4,.LC4@l(4)
	bl fopen
	cmpwi r3, 0
	li r4, -32
	bne- error #YES THIS IS A BNE! We don't want it to exist
	
	#Open source.s
	lis 3,.LC5@ha
	la 3,.LC5@l(3)
	lis 4,.LC4@ha
	la 4,.LC4@l(4)
	bl fopen
	mr. r31, r3 #Check & Backup fp
	li r4, -33
	beq- error
	
	#Get size of source.s via fseek and ftell
	li r4, 0
	li r5, 2 #SEEK_END
	bl fseek
	cmpwi r3, 0
	li r4, -34
	bne- error
	mr r3, r31
	bl ftell #No need for error check
	
	#Rewind to set stream position of file back to the start of file
	#Then allocate memory
	mr r28, r3 #Temp Backup size
	mr r3, r31
	bl rewind #No need for error check
	li r3, 32 #32-byte alignment
	mr r4, r28 #Size
	bl memalign
	mr. r27, r3 #Check & Backup source.s input mem pointer
	li r4, -35
	beq- error
	
	#Dump source.s, then close
	li r4, 1 #size (not real size)
	mr r5, r28 #count (real size of source.s)
	mr r6, r31 #fp
	bl fread
	cmpw r3, r28 #CHECK COUNT, not size
	li r4, -36
	bne- error
	mr r3, r31
	bl fclose
	cmpwi r3, 0
	li r4, -37
    bne- error
    
    #for r26 = 0 (txt), make r5 = 9
    #for r26 = 1 (bin), make r5 = 4
    cmpwi r26, 0
    li r5, 9
    beq- start_gen_codebintxt_size
    li r5, 4
    
    #Count 0xA bytes in source.s to get code.bin/txt gen size, but just incase, add 8 words of space, hey you never know
start_gen_codebintxt_size:
    addi r3, r27, -1
    li r4, 0
    pre_gen_codebintxt_size:
    lbzu r0, 0x1 (r3)
    cmpwi r0, 0
    beq- pre_gen_done
    cmpwi r0, 0xA
    bne+ pre_gen_codebintxt_size
    add r4, r4, r5
    b pre_gen_codebintxt_size
    pre_gen_done:
    addi r4, r4, 32 #Extra 8 words, just in case, the loop read the source.s incorrectly
    #Got size, alloc block for new code.bin
    li r3, 32
    bl memalign
    mr. r31, r3 #Backup new code.bin pointer, r28 no longer needs to be source.s's zie
    li r4, -38
    beq- error
    
    #Software is required to store sscanf and memcmp func addr's to reserved spots in lookup table of abin.bin
    lis r0, sscanf@h
    ori r0, r0, sscanf@l
    lis r3, memcmp@h
    ori r3, r3, memcmp@l
    stw r0, 0x340 (r29)
    stw r3, 0x344 (r29)
    
    #fread doesn't do any cache updates btw, we need to do a dcbst and icbi for the entire abin.bin file
    mr r3, r29 #Pointer
    mr r4, r30 #Size
    bl DCStoreRange
    mr r3, r29 #Pointer
    mr r4, r30 #Size
    bl ICInvalidateRange
    
    #Check for a Gecko Header in the source.s Input file (r27)
    #Fyi r31 = Start of code.bin
    #x = 24-bit address
    #!C2xxxxxx
    #!C0
    #!06xxxxxx
    #!04xxxxxx

    #r14 flag list, flag tells us if we need to do shit to the output file immediately after it done in Waltress Asm engine
    #Raw = 0
    #04 = 1
    #06 = 2
    #C0 = 3
    #C2 = 4

    #Set r3 as "!C2", r4 as "!C0/n", r5 as "!06", r6 as "!04"
    lis r3, 0x2143
    ori r3, r3, 0x3200
    subi r4, r3, 0x01F6
    lis r5, 0x2130
    ori r5, r5, 0x3600
    subi r6, r5, 0x0200

    #Load first four bytes Gecko Header; check for each one. However clear out last byte before doing any non-C0 checks
    lwz r0, 0 (r27)
    clrrwi r7, r0, 8
    cmpw r7, r6
    li r14, 1
    beq- C2_06_04
    cmpw r7, r5
    li r14, 2
    beq- C2_06_04
    cmpw r0, r4
    li r14, 3
    beq- c0_asm
    cmpw r7, r3
    li r14, 4
    beq- C2_06_04
    li r14, 0 #Raw being used
    b setup_A_loop

c0_asm:
    #Make sure there is an "enter/0xA" after !C0
    lbz r0, 0x3 (r27)
    cmpwi r0, 0xA
    li r4, -39
    bne- error

    #Write C0 Gecko Opcode to pre-made code.bin
    lis r0, 0xC000
    stw r0, 0 (r31)

    #Update r27 and r31 so we can now run Waltress ASM Engine, r14 flag will be checked after that for further adjustments of output code.bin file
    addi r27, r27, 4 #Points to first source after Gecko Opcode
    addi r31, r31, 8 #Will need to fill in 'C0 code length byte' (0x4 spot) afterwards, and throw in blr and nullword if required
    b setup_A_loop

C2_06_04:
    #04 RAM Write, 06 String, or C2 Insert being used
    #Make sure there is an "enter/0xA" after !04xxxxxx
    lbz r0, 0x9 (r27)
    cmpwi r0, 0xA
    li r4, -40
    bne- error

    #Write null byte terminator to shit due to upcoming use of sscanf
    li r0, 0
    stb r0, 0x9 (r27)

    #Change ASCII C2/06/04xxxxxx to Hex byte code
    #sscanf
    #r3 = mem pointer to formatted string (what's already present)
    #r4 = mem pointer to unformatted string (how the r3 arg will be deciphered)
    #r5 = place to dump format variable
    lis 4,.LC17@ha
    la 4,.LC17@l(4)
    mr r3, r27
    addi r5, sp, 8
    bl sscanf
    cmpwi r3, 1
    li r4, -41
    bne- error

    #Load Gecko Opcode + 24-bit address Write byte code value & store to 31 (code.bin)
    lwz r0, 0x8 (sp)
    stw r0, 0 (r31)

    #Check r14 flag for 04 RAM Write
    cmpwi r14, 1
    addi r31, r31, 4 #Regardless of option (04 v 06 v C2) r31 needs to be incremented by at least 4
    addi r27, r27, 10 #Regardless of option (04 v 06 v C2), r27 needs 10 added to it
    bne- add_another_4_to_r31

    #04 RAM Write is being used. Make sure there is only one actual instruction source line ofc...
    #Just incase the user has more than 1 source line.. (lol).. write a null byte after the source line's 0xA byte.
    #That way Waltress ASM Engine will have a properly signaled EoF
    addi r3, r27, -1
make_sure_one_source_line:
    lbzu r0, 1 (r3)
    cmpwi r0, 0 #If Eof reached before 0xA, then that's an error
    li r4, -42
    beq- error
    cmpwi r0, 0xA
    bne+ make_sure_one_source_line

    #Write null to byte spot AFTER where 0xA is at
    #Then we can go to Waltress ASM Engine
    li r0, 0
    stb r0, 0x1 (r3)
    b setup_A_loop

    #06 or C2 is being used, have to increment r31 by 4 again for a total of 8 added to skip waltress writing to C2/06 line/byte code count (0x4 spot)
add_another_4_to_r31:
    addi r31, r31, 4
    #NOW we can go to the Waltress Assembly Engine setup
    
#RUN WALTRESS ASSEMBLER ENGINE
#r27 = source.s INPUT pointer aka r3 arg
#r31 = code.bin OUTPUT pointer aka r4 arg

#Waltress Assembler Engine

#r3 arg = Pointer where source line to be disassembled to located at (Engine itself will discard any end-appneded bytes, do not worry)
#r4 arg = Pointer where compiled Instruction will be written to

#Setup stuff for A_loop
#r27; source.s INPUT will be updated thruout loop for the r3 arg
setup_A_loop:
addi r30, r31, -4 #Updating pointer for r4 arg, keep original r31 intact for later use after A_loop is done
li r28, 0 #Use r28 to calc file size for new code.bin

#A_loop
A_loop:
li r4, 0 #Used for counting chars for source line that will soon be sent to the Assembler engine

#Make a temp copy of r27 to r3 (and minus 1 it)
addi r3, r27, -1

#Check for 0xA byte after source line. Source line will SOON be sent to the engine for assembling
count_non0xAchars:
lbzu r0, 0x1 (r3)
addi r4, r4, 1
cmpwi r0, 0xA
beq- prep_asm_engine
cmpwi r0, 0 #Check for EoF
bne+ count_non0xAchars

#No more assembling needs to be done!
b asm_engine_completed

#Found the 0xA byte, cursor is on said 0xA, overwrite 0xA with NULL
prep_asm_engine:
li r0, 0
stb r0, 0 (r3)

#Setup the r3 arg
mr r3, r27

#r27 (r3 arg) pointer must be updated for possible next iteration of calling abin.bin & A_loop
add r27, r27, r4

#Update r4 arg (r30)
addi r30, r30, 4

#Set r4 arg
mr r4, r30

mtlr r29
blrl #CALL WALTRESS Assembler ENGINE :)
cmpwi r3, 0
subi r4, r3, 42 #NOTE: Make -1 turn -43, -2 to -44, -3 to -45
bne- error

#Update generated code.bin size due to successful instruction compilation, repeat loop
addi r28, r28, 4
b A_loop
    
    #Assembler completed 100%, check r14 flag to see if the code.bin file needs any more post processing (for Gecko-related stuff)
asm_engine_completed:
    #r28 = current size (in progress) of code.bin file
    #r30 = points to last assembled word of code.bin file
    #r31 = points to very start of code.bin file
    #atm file is in code.bin, could be code.txt later depending on r26 (user option)
    
    #First check if user did RAW option (no post processing needed for Gecko stuff)
    cmpwi r14, 0
    beq- check_for_code_txt_creation
    
    #First we gotta add 4 to r28 because of opcode
    #And at the least subtract 4 from r31
    addi r28, r28, 4
    subi r31, r31, 4
    
    #Check r14 flag for 04 RAM Write; if 04 RAM, r28 is set & r31 is set, good to proceed
    cmpwi r14, 1
    beq- check_for_code_txt_creation
    
    #We now know we have to add at least another 4 since its 06/C0/C2 (word reserved spot for byte/line amount)
    #And subtract another 4 from r31
    addi r28, r28, 4
    subi r31, r31, 4
    
    #Check for r14 for flag for C0 
    cmpwi r14, 3
    bne- C2_or_06
    
    #Write blr (to r30 + 0x4); update r28
    lis r0, 0x4E80
    ori r0, r0, 0x0020
    stw r0, 0x4 (r30)
    addi r28, r28, 4
    
    #For the case r28 (divided into word amount) is odd, write null word after blr and increase r28 by 4 again
    andi. r0, r28, 0x0004
    beq- finish_off_c0c2
    
    #Need final null word, write it, increase file size
    li r0, 0 #Just incase null doesn't pre-exist from memalign alloc...
    stw r0, 0x8 (r30)
    addi r28, r28, 4
    b finish_off_c0c2
    
    #Only cases left are C2 or 06
    C2_or_06:
    cmpwi r14, 2
    beq- its_06_string
    
    #Found C2 Insert
    #Do we need a nop?
    andi. r0, r28, 0x0004 #If byte size ends in 0x4 or 0xC, then this will result in NON-zero, we don't need a null because when you factor in C2 ender null-word it will be aligned
    mr r3, r30 #maybe fix this one day..., do stwx r31's instead of stw r30's!
    bne- no_nop_needed
    
    #Write Nop
    lis r0, 0x6000
    stwu r0, 0x4 (r3) #Make a copy of r30 and Update address due to regular stw use for the null word
    addi r28, r28, 4
    
    #Now write null word shit
    no_nop_needed:
    li r0, 0
    stw r0, 0x4 (r3)
    addi r28, r28, 4
    
    #Now calc the C2 line amount in word #2 of code.bin file
    #4 8 = 0
    #c 10 = 1
    #14 18 = 2
    #1c 20 = 3
    #20 24 = 4
    #28 2c = 5
    #.. ..
    
    finish_off_c0c2:
    subi r3, r28, 8 #Get byte amount of code.bin EXcluding gecko header and c0/c2 line amount
    srwi r3, r3, 3 #Divide by 8 to get double-word (code line) amount
    stw r3, 0x4 (r31) #Write to c0/c2 line amount spot
    b check_for_code_txt_creation
    
    #06 string write
    its_06_string:
    #Simply subtract current current generated code.bin file size by 8 to get byte size to write to byte-size spot in 06 code
    subi r0, r28, 8 
    stw r0, 0x4 (r31)
    
    #Do we need an extra null for the 06 string write?
    andi. r0, r28, 0x0004 #If byte size ends in 0x4 or 0xC, then this will result in NON-zero
    beq- check_for_code_txt_creation
    li r0, 0 #Just incase...
    stw r0, 0x4 (r30)
    addi r28, r28, 4
   
    #Code.bin fully fnished, check r26 flag to see if user wants further assembling to a code.txt file
    #We have code.bin at r31 with its size at r28
    #Now check r26 to see if we will transform it to a code.txt using sprintf
check_for_code_txt_creation:
    cmpwi r26, 0
    bne- create_new_code_bin
    
    #Transform code.bin to code.txt
    #Use r30 as a flag for knowing when to write 0x20 vs 0x0A, code.txt will end in 0xA
    #r30 = 0 = write 0x20
    #r30 = -1 = write 0x0A
    li r30, -1
    #Need another memalign block
    #Instruction in code.bin = 4 bytes, instruction in code.txt = 9 bytes
    #Therefore mulli by 3
    mulli r4, r28, 3
    li r3, 32
    bl memalign
    cmpwi r3, 0
    li r4, -46
    beq- error
    
    #Use r29 for size clac after every sprintf call, we have to reset to 0 first
    li r29, 0
    
    #Use r27 as r4 arg for sprintf
    lis 27,.LC14@ha
	la 27,.LC14@l(27)
	
	#Setup r31, will be used for updating r5 arg of sprintf
	addi r31, r31, -4
	
	#Use r25 for new memalign block as place to dump (r3), set it up
	mr r25, r3
	
	#Make another copy of this r24, need this later
	mr r24, r3
	
	#sprintf
	#r3 = mem pointer to dump formatted string to
	#r4 = mem pointer to unformatted string
	#r5+ variables applied for formatting
	#Loop to transform code.bin to code.txt
	change_codebin_to_codetxt:
	lwzu r5, 0x4 (r31)
	mr r4, r27
	mr r3, r25
	bl sprintf
	cmpwi r3, 8
	li r4, -47
	bne- error
	
	#Not r30 and do rc shortcut, store ascii symbol (space vs enter) based on r30's value
	not. r30, r30
	li r0, 0x20
	beq- write_ascii_symbol
	li r0, 0x0A
	write_ascii_symbol:
	stbu r0, 0x8 (r25)
	
	#Increment r25 by 1 to accoutn for 0x20/0xA byte space/slot for possible next loop iteration
	addi r25, r25, 1 
	
	#Decrement loop (subtract 4 from r28 everytime)
	subic. r28, r28, 4
	#Update file size tracker
	addi r29, r29, 9
	#loop coutner check
	bne+ change_codebin_to_codetxt
	
	#Alright code.txt has been 'made'!
	#Place calc'd size (r29) into r28
	mr r28, r29
	
	#Place memalign block of code.txt (r24) into r31
	mr r31, r24
	
	#Open code.txt with write perms
    lis 3,.LC13@ha
	la 3,.LC13@l(3)
	b create_codetxtbin

	#Open code.bin with write perms
create_new_code_bin:
    lis 3,.LC6@ha
	la 3,.LC6@l(3)
	
create_codetxtbin:
	lis 4,.LC7@ha
	la 4,.LC7@l(4)
	bl fopen
	mr. r29, r3 #Check & Backup fp
	li r4, -48
	beq- error
	
	#Write code.bin/txt, then close
	mr r3, r31 #mem pointer for new code.bin/txt
	li r4, 1 #size (not real size)
	mr r5, r28 #count; real size calc'd from earlier in A_loop, OR size calc'd from code.bin to code.txt sprintf loop
	mr r6, r29 #fp
	bl fwrite
	cmpw r3, r28 #CHECK COUNT, not size!
	li r4, -49
	bne- error
	mr r3, r29
	bl fclose
	cmpwi r3, 0
	li r4, -50
	bne- error
	
	#SUCCESS
    lis 3,.LC10@ha
	la 3,.LC10@l(3)
	
	#Set r30 flag for possible input file deletion
	#r30 = 0 (code.txt/bin)
	#r30 = 1 (source.s)
	#r30 = -1 (can't delete due to error)
	li r30, 1
	b output_message
	
	#Error handler
error: #r4 already set to error code value
	lis 3,.LC11@ha
	la 3,.LC11@l(3)
	
	#Set r30 flag for possible input file deletion
	#r30 = 0 (code.txt/bin)
	#r30 = 1 (source.s)
	#r30 = -1 (can't delete due to error)
	li r30, -1
	
	#Print out selected error message to Console
output_message: #Doesn't include the leaving HBC message, that one is the real final message
    crxor 6,6,6
	bl printf
app_done:
    bl VIDEO_WaitVSync
	bl WPAD_ScanPads
	li r3, 0
	bl WPAD_ButtonsDown
	mr r31, r3
	bl PAD_ScanPads
	li r3, 0
	bl PAD_ButtonsDown
	andi. r0, r3, 0x0200 #GCN B
	bne- delete_input_file
	andi. r0, r31, 0x0004 #Wheel/Chuck B
	bne- delete_input_file
	andis. r0, r31, 0x0040 #Classic B
	bne- delete_input_file
	andi. r0, r3, 0x1000 #GCN Start
	bne- leave_to_hbc
	andi. r0, r31, 0x0080 #Wheel/Chuck Home
	bne- leave_to_hbc
	andis. r0, r31, 0x0800 #Classic Home
	beq+ app_done
	leave_to_hbc:
	lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
	lis 3,.LC12@ha #Print out "Exiting back to HBC!"
	la 3,.LC12@l(3)
final_console_output:
	crxor 6,6,6
	bl printf
	li r3, 0
	bl exit
	
delete_input_file:
    cmpwi r30, 0
    blt- app_done #Don't allow input file deletion due to Error
    
    #Reset console
    lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
	
	#Reread r30 flag
	#0 = input file was code.txt/bin
	#1 = input file was source.s
	cmpwi r30, 0
	beq- delete_codetxtbin
	
	#Assembling was done, delete source.s.
	lis 3,.LC5@ha
	la 3,.LC5@l(3)
	bl remove
	cmpwi r3, 0
	bne- bad_delete
	
	#Good Delete!
	good_delete:
	lis 3,.LC15@ha
	la 3,.LC15@l(3)
	b final_console_output
	
	#Disassembling was done, delete code.txt/bin, try both
delete_codetxtbin:
	lis 3,.LC6@ha
	la 3,.LC6@l(3)
	bl remove
	cmpwi r3, 0
	beq- good_delete
	lis 3,.LC13@ha
	la 3,.LC13@l(3)
	bl remove
	cmpwi r3, 0
	beq- good_delete
	
	#Somehow, original file couldn't be deleted ?
	bad_delete:
	lis 3,.LC16@ha
	la 3,.LC16@l(3)
	b final_console_output
    
#====================================================================#
	
sync_video:
	bl VIDEO_WaitVSync
	b main_menu
	.cfi_endproc
.LFE86:
	.size	main, .-main
	.section	".bss"
	.align 2
	.set	.LANCHOR0,. + 0
	.type	rmode, @object
	.size	rmode, 4
rmode:
	.zero	4
	.type	xfb, @object
	.size	xfb, 4
xfb:
	.zero	4
	.ident	"GCC: (devkitPPC release 40) 11.2.0"
