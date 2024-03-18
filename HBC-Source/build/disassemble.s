	.file	"disassemble.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Disassemble Func (void)
#r3 returns 0 for success, any negative number is error

#Open source.s to make sure one doesn't exist
#Open dbin.bin, get size, alloc mem, dump, close
#Open code.txt, get size, alloc mem, dump, close
#Multiply code.txt's size by 13 for estimated size of to-be-generated source.s
#Mem alloc for estimated size
#Update cache for dbin.bin since we will execute it
#Run waltress dbin.bin
#Create source.s, write to it, close, success

#r31 = fp, then source.s pointer
#VOID NOW r30 = dbin.bin size
#VOID NOW r29 = dbin.bin pointer
#r28 = code.txt size
#r27 = code.txt pointer
#r26 = Header flag, 0 = raw, 1 = 04,06,C2, 2 = C0
#r23 thru r25 = Gecko Header (ASCII)
#r22 = r31 (net; factoring in gecko header)

#Directives
sources:
.asciz "source.s"
codetxt:
.asciz "code.txt"
rb:
.asciz "rb"
wb:
.asciz "wb"
dfopensourceEC:
.asciz "\n\nError! Source.s already exists. Delete it and try again.\n\n"
dfopencodetxtEC:
.asciz "\n\nError! Can't find code.txt. This file needs to be present for disassembling. Is the file named incorrectly?\n\n"
dfseekcodetxtEC:
.asciz "\n\nError! fseek failure on code.txt.\n\n"
dmemaligncodetxtEC:
.asciz "\n\nError! Can't allocate memory for code.txt.\n\n"
dfreadcodetxtEC:
.asciz "\n\nError! Unable to dump code.txt to memory.\n\n"
dfclosecodetxtEC:
.asciz "\n\nError! Can't close code.txt.\n\n"
dgeckoheaderEC:
.asciz "\n\nError! The Gecko Header is not the correct format or an unsupported Header type is being used.\n\n"
dsavestripmallocEC:
.asciz "\n\nError! Can't allocate memory within the Save and Strip Gecko Header subroutine.\n\n"
dcodetxt2binEC:
.asciz "\n\nError! Either a sscanf failure occurred within the codetxt2bin subroutine, or somehow code.txt (after the codetxtpostparsersize subroutine) has a size that isn't divisible by 4. Please report this Error at MarioKartWii.com!\n\n"
dmemalignTOBEsourceEC:
.asciz "\n\nError! Can't allocate memory for future source.s.\n\n"
dprepwaltressdbinEC:
.asciz "\n\nError! One the following scenarios has occurred. The 06 line amount designator byte is an incorrect value, the C0 line amount designator byte is an incorrect value, or the C2 line amount designator byte is an incorrect value.\n\n"
dwaltressSprintfFailureEC:
.asciz "\n\nError! A sprintf failure occurred when Waltress tried disassembling one of the instruction(s). This should never occur. Please report this Error at MarioKartWii.com!\n\n"
dfcreatesourceEC:
.asciz "\n\nError! Can't create new source.s. If you are using the Desktop Version, make sure the DV folder has user permissions enabled.\n\n"
dfwritesourceEC:
.asciz "\n\nError! Can't write content to newly created source.s.\n\n"
dfclosesourceEC:
.asciz "\n\nError! Can't close new source.s.\n\n"

.align 2

#Prologue
.globl disassemble
disassemble:
stwu sp, -0x0040 (sp)
mflr r0
stmw r20, 0x10 (sp)
stw r0, 0x0044 (sp)

#Open source.s, one shouldn't exist
lis r3, sources@h
lis r4, rb@h
ori r3, r3, sources@l
ori r4, r4, rb@l
bl fopen
cmpwi r3, 0
lis r3, dfopensourceEC@h
ori r3, r3, dfopensourceEC@l
bne- disassemble_error #YES this is bne! We don't want file to exist

#Open code.txt
lis r3, codetxt@h
lis r4, rb@h
ori r3, r3, codetxt@l
ori r4, r4, rb@l
bl fopen
mr. r31, r3
lis r3, dfopencodetxtEC@h
ori r3, r3, dfopencodetxtEC@l
beq- disassemble_error

#Get size of code.txt
mr r3, r31
li r4, 0
li r5, 2 #Seek end
bl fseek
cmpwi r3, 0
lis r3, dfseekcodetxtEC@h
ori r3, r3, dfseekcodetxtEC@l
bne- disassemble_error
mr r3, r31
bl ftell #No error check for this

#Rewind file stream position
#Alloc mem for code.txt
#*NOTE* We have code.txt filesize but future custom subfuncs require the file ends in a null byte, therefore add 1 to the file size before calling memalign.
addi r28, r3, 1
mr r3, r31
bl rewind #No error check for this
li r3, 32
mr r4, r28
bl memalign
mr. r27, r3 
lis r3, dmemaligncodetxtEC@h
ori r3, r3, dmemaligncodetxtEC@l
beq- disassemble_error

#Dump code.txt, close
mr r3, r27
li r4, 1
subi r5, r28, 1 #This is because we added 1 fake byte from earlier!!!
mr r6, r31
bl fread
subi r0, r28, 1
cmpw r3, r0
lis r3, dfreadcodetxtEC@h
ori r3, r3, dfreadcodetxtEC@l
bne- disassemble_error
mr r3, r31
bl fclose
cmpwi r3, 0
lis r3, dfclosecodetxtEC@h
ori r3, r3, dfclosecodetxtEC@l
bne- disassemble_error

#Append null byte to end of file, this is needed for future funcs
subi r3, r28, 1
li r4, 0
stbx r4, r3, r27

#Patch carriages
mr r3, r27
bl newline_fixer

#Get the Gecko Header type from code.txt
#-1 = Invalid
#0 = Raw
#1 = C2
#2 = 04
#3 = 06
#4 = C0
mr r3, r27
bl get_geckoheadertype
mr. r22, r3
lis r3, dgeckoheaderEC@h
ori r3, r3, dgeckoheaderEC@l
blt- disassemble_error
beq- skip_codetxt_geckostripper

#Call func that saves gecko header then overwrites it with spaces
#r3 returns malloced space where header is saved at
#r3 arg = gecko header type
#r4 arg = code.txt ptr, code.txt must end in null byte
mr r3, r22
mr r4, r27
bl saveANDoverwrite_geckoheader
mr. r20, r3
lis r3, dsavestripmallocEC@h
ori r3, r3, dsavestripmallocEC@l
beq- disassemble_error

#Call the code.txt parser to remove all spaces, enters, tabs, and comments
#r3 = pointer to code.txt, must end in null
#r4 = size of code.txt plus null byte
skip_codetxt_geckostripper:
mr r3, r27
mr r4, r28 #TODO fix me, r28 is incorrect (needs to be decremented) but it actually doesn't matter, func will still work correctly
bl codetxtparser #No error check for this

#Gen post parser code.txt size (EXclude null byte on count)
mr r3, r27
bl codetxtpostparsersize
mr r25, r3 #Save in r25, no error check for this func

#Transform code.txt to a temporary code.bin, yuck
#r3 = code.txt pointer
#r4 = code.txt post-parsed size excluding null byte (must exclude because r4 needs to be divisible by 8)
mr r3, r27
mr r4, r25
bl codetxt2bin
cmpwi r3, 0
lis r3, dcodetxt2binEC@h
ori r3, r3, dcodetxt2binEC@l
bne- disassemble_error #Carry return error from codetxt2bin to parent func

#Using code.txt post parser size, use that to generate safe upper bound range
#for memalign size for to-be-genned source.s
#Longest possible line is 36 bytes 
#36 / 8 = 4.5
#Take code.txt post parser size times 5. Then finally add 10 bytes for possible Header
mulli r5, r25, 5 #Yuck
addi r4, r5, 10
li r3, 32
bl memalign
mr. r31, r3
lis r3, dmemalignTOBEsourceEC@h
ori r3, r3, dmemalignTOBEsourceEC@l
beq- disassemble_error

#Prep for Engine.
#r3 = code.bin pointer
#r4 = code.TXT size (***NOT** .bin size, it hasn't yet been calc'd)
#r5 = gecko type
#Func returns...
#r3 = new code.bin pointer
#r4 = loop/instruction amount for 
mr r3, r27
mr r4, r25
mr r5, r22
bl prep_waltress_dbin
cmpwi r3, 0 #r3 == 0 is only possible if 06 byte amount is *not* divisible by 4
addi r24, r3, -4 #Decrement for waltress din bin loop
lis r3, dprepwaltressdbinEC@h
ori r3, r3, dprepwaltressdbinEC@l
beq- disassemble_error
mr r25, r4 #Loop counter GVR
mr r21, r4 #Need instruction amount for later, save again in diff GVR
mr r23, r31 #Make copy of source.s pointer

#RUN WALTRESS DASM ENGINE
#r3 = source.s ptr  (output addr)
#r4 = instruction (input value)

run_waltress_dbin_bin:
lwzu r4, 0x4 (r24)
mr r3, r23
bl dasm_engine # :)
cmpwi r3, 0
beq+ its_the_waltress

lis r3, dwaltressSprintfFailureEC@h
ori r3, r3, dwaltressSprintfFailureEC@l
b disassemble_error

its_the_waltress:
subic. r25, r25, 1
#Find null on newly printed source line at source.s, so we know how much to increment r23 for next go around
lbzu r0, 0x1 (r23)
cmpwi cr7, r0, 0
bne+ cr7, -0x8
#r23 needs to be incremented by 1
addi r23, r23, 1
bne+ run_waltress_dbin_bin

#Fyi waltress stores null byte to every output string
#Now we just need to replace all null bytes (except last one) with spaces and enters
#Spaces are for odd instructions, enters for even, null byte at very end
mr r3, r31
mr r4, r21
bl fixwaltress_nulls #No error check

#Get length of new source.s (EXclude null byte ender)
addi r3, r31, -1
li r28, 0 #We don't have any more need for r28, free to use now
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beq- 0xC
addi r28, r28, 1
b -0x10

#Now add back in gecko header carried over from code.txt
cmpwi r22, 0 #If Raw, skip ofc
beq- create_sources

#r3 = pointer to source.s
#r4 = source.s size EXcluding null
#r5 = pointer to gecko header
#r6 = gecko header type
#r3 returns updated size that EXcludes null
mr r3, r31
mr r4, r28
mr r5, r20
mr r6, r22
bl add_header
mr r28, r3

#Create finished source.s
#r28 contains size EXcluding null byte
create_sources:
lis r3, sources@h
lis r4, wb@h
ori r3, r3, sources@l
ori r4, r4, wb@l
bl fopen
mr. r29, r3
lis r3, dfcreatesourceEC@h
ori r3, r3, dfcreatesourceEC@l
beq- disassemble_error
li r4, 1
mr r3, r31
mr r5, r28 #Count (real size)
mr r6, r29
bl fwrite
cmpw r3, r28
lis r3, dfwritesourceEC@h
ori r3, r3, dfwritesourceEC@l
bne- disassemble_error
mr r3, r29
bl fclose
cmpwi r3, 0
lis r3, dfclosesourceEC@h
ori r3, r3, dfclosesourceEC@l
bne- disassemble_error

#TODO add in code to free up allocated blocks of mem

#Success!
li r3, 0

disassemble_error:
lwz r0, 0x0044 (sp)
lmw r20, 0x10 (sp)
mtlr r0
addi sp, sp, 0x0040
blr
