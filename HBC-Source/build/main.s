	.file	"main.c"
	.machine ppc
	.section	".text"
	.globl __eabi
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.asciz	"\033[2;0H"
.LC1:
    .asciz "\x1b[2J" #Reset Cursor, clear current screen contents
.LC2:
    .asciz "\n\n       /\\      /\\\n      /  \\____/  \\\n     |            |\n     |  @      @  |\n     |___>_**_<___|\n  _______======_______\n (______        ______)\n        |      |\n        |      |        _\n        |      |_______/ |\n        |      |________/\n       / ______ \\\n      / /      \\ \\\n     /_/        \\_\\\nWelcome to \x1b[43m\x1b[30mWaltress\x1b[40m\x1b[37m! The PPC Assembler that's entirely handwritten in PPC! You can also assemble Gecko Codes! Read the README and NOTES.txt for more info.\n\nPress \x1b[32mA\x1b[37m to Assemble source.s to code.txt. Press \x1b[31mB\x1b[37m to Disassemble code.txt to source.s.\n\nCreated by \x1b[35mVega\x1b[37m. Version: 0.7\nPress Home/Start button to exit back to \x1b[36mHBC\x1b[37m at any time. Visit www.MarioKartWii.com for questions or bug reports."
.LC3:
    .asciz "\n\n\x1b[32mSUCCESS!\x1b[37m\n\nPress Home/Start button to exit back to \x1b[36mHBC\x1b[37m."
.LC4:
	.asciz	"\n\nError!\n\nUnable to initiate the FAT File System.\n\nPress Home/Start button to exit back to \x1b[36mHBC\x1b[37m."
.LC5:
    .asciz "\n\nExiting to \x1b[36mHBC\x1b[37m..."
	
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
	la 30,.LANCHOR0@l(31)
	bl PAD_Init
	li 3,0
	bl VIDEO_GetPreferredMode
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
	beq+ 0,.L2
	bl VIDEO_WaitVSync
.L2:
#Init the Console Cursor
	lis 3,.LC0@ha
	la 3,.LC0@l(3)
	crxor 6,6,6
	bl printf
	
#Init the FAT System
    bl fatInitDefault
	cmpwi r3, 0
	lis r3, .LC4@h
	ori r3, r3, .LC4@l
	beq- error_handler
	
#Reset Cursor
	lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
	
#Display the Main Menu Message
    lis 3,.LC2@ha
	la 3,.LC2@l(3)
	crxor 6,6,6
	bl printf
    
#Main Menu Idle and Read Button Inputs
main_menu:
#Scan Controllers
    bl WPAD_ScanPads
	li r3, 0
	bl WPAD_ButtonsDown
	mr r31, r3
	bl PAD_ScanPads
	li r3, 0
	bl PAD_ButtonsDown
	
#Check for Start/Home press
	andi. r0, r3, 0x1000 #GCN Start
	bne- leave_hbc
	andi. r0, r31, 0x0080 #Wheel/Chuck Home
	bne- leave_hbc
	andis. r0, r31, 0x0800 #Classic Home
	bne- leave_hbc
#Check for A (assemble press)
	andi. r0, r3, 0x0100 #GCN A
	bne- init_asm
	andi. r0, r31, 0x0008 #Wheel/Chuck A
	bne- init_asm
	andis. r0, r31, 0x0010 #Classic A
    bne- init_asm	
#Check for B (disassemble press)
	andi. r0, r3, 0x0200 #GCN B
	bne- init_dasm
	andi. r0, r31, 0x0004 #Wheel/Chuck B
	bne- init_dasm
	andis. r0, r31, 0x0040 #Classic B
	beq+ sync_video
    
#Start/Home was pressed. Reset console, send leaving message. Leave to HBC.
leave_hbc:
    lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
    lis r3, .LC5@h
	ori r3, r3, .LC5@l
	crxor 6,6,6
	bl printf
	li r3, 0
	bl exit

#A was pressed, assemble!
init_asm:
#Reset Cursor again and call assemble
	lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
    bl assemble
    cmpwi r3, 0 #r3 returns address w/ string to print if error
    blt- error_handler
    b success_handler
	
#B was pressed, disassemble!
init_dasm:
#Reset Cursor again and call disassemble
	lis 3,.LC1@ha
	la 3,.LC1@l(3)
	crxor 6,6,6
	bl printf
    bl disassemble
    cmpwi r3, 0 #r3 returns address w/ string to print if error
    blt- error_handler
    
#Success Handler, print success. console has already been reset
success_handler:
    lis 3,.LC3@ha
	la 3,.LC3@l(3)
	crxor 6,6,6
	bl printf
	
#Custom Wait Idle Loop
custom_wait:
    bl VIDEO_WaitVSync
#Scan Controllers
    bl WPAD_ScanPads
	li r3, 0
	bl WPAD_ButtonsDown
	mr r31, r3
	bl PAD_ScanPads
	li r3, 0
	bl PAD_ButtonsDown
#Check for Start/Home press
	andi. r0, r3, 0x1000 #GCN Start
	bne- leave_hbc
	andi. r0, r31, 0x0080 #Wheel/Chuck Home
	bne- leave_hbc
	andis. r0, r31, 0x0800 #Classic Home
	bne- leave_hbc
    b custom_wait
    
#Error Handler
error_handler:
#print r3 returned message. console has already been reset
	crxor 6,6,6
	bl printf
	b custom_wait
	
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
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"
