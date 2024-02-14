#Assemble Func (void)
#r3 returns 0 for success, any negative number is error

#Open code.txt to make sure one doesn't exist
#Open abin.bin, get size, alloc mem, dump, close
#Open sourse.s, get size, alloc mem, dump, close
#Count 0xA ascii bytes present to estimate needed size sourse's generated code.txt
#Mem alloc for estimated size
#Update cache for abin.bin since we will execute on it
#Run waltress abin.bin
#Create code.text, write to it, close, success

#r31 = fd, then code.txt pointer
#r30 = abin.bin size
#r29 = abin.bin pointer
#r28 = sourse.s size
#r27 = sourse.s pointer
#r26 = C2, C0, 04, 06, RAW flag

#Directives
abin:
.asciz "abin.bin"
asources:
.asciz "source.s"
acodetxt:
.asciz "code.txt"
arb:
.asciz "rb"
awb:
.asciz "wb"
afopencodetxtEC:
.asciz "Error! Code.txt already exists. Delete it and try again.\n\n"
afopenabinbinEC:
.asciz "Error! Unable to open abin.bin. Did you accidentally delete it?\n\n"
afseekabinbinEC:
.asciz "Error! fseek failure on abin.bin.\n\n"
amemalignabinbinEC:
.asciz "Error! Can't allocate memory for abin.bin.\n\n"
afreadabinbinEC:
.asciz "Error! Unable to dump abin.bin to memory.\n\n"
afcloseabinbinEC:
.asciz "Error! Can't close abin.bin.\n\n"
afopensourceEC:
.asciz "Error! Can't find source.s. This file needs to be present for assembling. Is the file named incorrectly?\n\n"
afseeksourceEC:
.asciz "Error! fseek failure on source.s.\n\n"
amemalignsourceEC:
.asciz "Error! Can't allocate memory for source.s.\n\n"
afreadsourceEC:
.asciz "Error! Unable to dump source.s to memory.\n\n"
afclosesourceEC:
.asciz "Error! Can't close source.s.\n\n"
ageckoheaderEC:
.asciz "Error! The Gecko Header is not the correct format or an unsupported Header type is being used.\n\n"
asavestripmallocEC:
.asciz "Error! Can't allocate memory within the Save and Strip Gecko Header subroutine.\n\n"
amemalignTOBEcodebinEC:
.asciz "Error! Can't allocate memory for temporary code.bin.\n\n"
awaltressSscanfFailureEC:
.asciz "\n\nError! A sscanf failure occurred when Waltress tried assembling the above instruction. Please note that all spaces are stripped out, this is normal. Did you typo the instruction name? Did you forget a comma? Did you forget to prepend a Hex value with 0x? Did you forget to prepend a GPR with the letter r? Did you forget to prepend a FPR with the letter f? If the above instruction is andi/andis, did you forget to add a period after the instruction name?\n\n"
awaltressBadParamEC:
.asciz "\n\nError! The above instruction was interpreted by Waltress to be valid, but an invalid parameter (register value, imm value, etc) was used. Please note that all spaces are stripped out, this is normal. Did you exceed the SIMM-16 range? Did you exceed the UIMM-16 range? Are you following the IMM Format rules? Did you exceed the SIMM-12 range for a psq load/store? Are you using a crF number higher than 7?\n\n"
amemaligncodetxtEC:
.asciz "Error! Can't allocate memory for code.txt.\n\n"
afcreatecodetxtEC:
.asciz "Error! Can't create new code.txt. If you are using the Desktop Version, make sure the DV folder has user permissions enabled.\n\n"
afwritecodetxtEC:
.asciz "Error! Can't write content to newly created code.txt.\n\n"
afclosecodetxtEC:
.asciz "Error! Can't close new code.txt.\n\n"

.align 2

#Prologue
.globl assemble
assemble:
stwu sp, -0x0030 (sp)
mflr r0
stw r22, 0x8 (sp)
stw r23, 0xC (sp)
stw r24, 0x10 (sp)
stw r25, 0x14 (sp)
stw r26, 0x18 (sp)
stw r27, 0x1C (sp)
stw r28, 0x20 (sp)
stw r29, 0x24 (sp)
stw r30, 0x28 (sp)
stw r31, 0x2C (sp)
stw r0, 0x0034 (sp)

#Open code.txt, one shouldn't exist
lis r3, acodetxt@h
lis r4, arb@h
ori r3, r3, acodetxt@l
ori r4, r4, arb@l
bl fopen
cmpwi r3, 0
lis r3, afopencodetxtEC@h
ori r3, r3, afopencodetxtEC@l
bne- assembleerror #YES this is bne! We don't want file to exist

#Open abin.bin
lis r3, abin@h
lis r4, arb@h
ori r3, r3, abin@l
ori r4, r4, arb@l
bl fopen
mr. r31, r3
lis r3, afopenabinbinEC@h
ori r3, r3, afopenabinbinEC@l
beq- assembleerror

#Get size of abin.bin
mr r3, r31
li r4, 0
li r5, 2
bl fseek
cmpwi r3, 0
lis r3, afseekabinbinEC@h
ori r3, r3, afseekabinbinEC@l
bne- assembleerror
mr r3, r31
bl ftell #No error check for this

#Rewind file stream position
#Allocate mem for abin.bin
mr r30, r3
mr r3, r31
bl rewind #No error check for this
li r3, 32
mr r4, r30
bl memalign
mr. r29, r3
lis r3, amemalignabinbinEC@h
ori r3, r3, amemalignabinbinEC@l
beq- assembleerror

#Dump abin.bin, close
mr r3, r29
li r4, 1
mr r5, r30 #count (this is real size)
mr r6, r31
bl fread
cmpw r3, r30
lis r3, afreadabinbinEC@h
ori r3, r3, afreadabinbinEC@l
bne- assembleerror
mr r3, r31
bl fclose
cmpwi r3, 0
lis r3, afcloseabinbinEC@h
ori r3, r3, afcloseabinbinEC@l
bne- assembleerror

#Software is required to write in the sscanf, and memcmp func address's to the Waltress ASM engine
lis r0, sscanf@h
lis r3, memcmp@h
ori r0, r0, sscanf@l
ori r3, r3, memcmp@l
stw r0, 0x2E0 (r29) #This is a hardcoded offset! If abinDV.bin engine gets modified, remember to adjust this!
stw r3, 0x2E4 (r29) #This is a hardcoded offset! If abinDV.bin engine gets modified, remember to adjust this!

#File operation funcs don't update cache for us, we gotta do it
mr r3, r29
mr r4, r30
bl DCStoreRange

#Finish off cache stuff
mr r3, r29
mr r4, r30
bl ICInvalidateRange

#Open source.s
lis r3, asources@h
lis r4, arb@h
ori r3, r3, asources@l
ori r4, r4, arb@l
bl fopen
mr. r31, r3
lis r3, afopensourceEC@h
ori r3, r3, afopensourceEC@l
beq- assembleerror

#Get size of source.s
mr r3, r31
li r4, 0
li r5, 2 #Seek end
bl fseek
cmpwi r3, 0
lis r3, afseeksourceEC@h
ori r3, r3, afseeksourceEC@l
bne- assembleerror
mr r3, r31
bl ftell #No error check for this

#Rewind file stream position
#Alloc mem for source.s
#*NOTE* We have source.s filesize but future custom subfuncs require the file ends in a null byte, therefore add 1 to the file size before calling memalign.
#*NOTE* Also, the gencodebinsize.s function further below requires source.s end in 0xA (enter), therefore we have to add 1 to the file for that as well (total of 2 bytes added)
addi r28, r3, 2
mr r3, r31
bl rewind
li r3, 32
mr r4, r28
bl memalign
mr. r27, r3 
lis r3, amemalignsourceEC@h
ori r3, r3, amemalignsourceEC@l
beq- assembleerror

#Dump source.s, close
mr r3, r27
li r4, 1
subi r5, r28, 2 #This is because we added 2 fake bytes from earlier!!!
mr r6, r31
bl fread
subi r0, r28, 2
cmpw r3, r0
lis r3, afreadsourceEC@h
ori r3, r3, afreadsourceEC@l
bne- assembleerror
mr r3, r31
bl fclose
cmpwi r3, 0
lis r3, afclosesourceEC@h
ori r3, r3, afclosesourceEC@l
bne- assembleerror

#Append an 0x0A00 to file (last halfword of allocated block), because we allocated 2 extra bytes and future funcs require the file to end in 0x0A00 (enter new line then null)
subi r3, r28, 2
li r4, 0x0A00
sthx r4, r3, r27

#Patch carriages
mr r3, r27
bl newline_fixer

#Get the Gecko Header type from source.s
#-1 = Invalid
#0 = Raw
#1 = C2
#2 = 04
#3 = 06
#4 = C0
mr r3, r27
bl get_geckoheadertype
mr. r24, r3
lis r3, ageckoheaderEC@h
ori r3, r3, ageckoheaderEC@l
blt- assembleerror
beq- skipstrip

#Call func that saves gecko header then overwrites it with spaces
#r3 returns malloced space where header is saved at
#r3 arg = gecko header type
#r4 arg = source.s ptr, source.s must end in null byte
mr r3, r24
mr r4, r27
bl saveANDoverwrite_geckoheader
mr. r23, r3
lis r3, asavestripmallocEC@h
ori r3, r3, asavestripmallocEC@l
beq- assembleerror

#Call the source.s parser to remove any double+ enters, spaces, tabs, and comments
#r3 = pointer to source.s, must end in null byte
#r4 = size of source.s plus null byte
skipstrip:
mr r3, r27
mr r4, r28 #TODO fix me, r28 is incorrect (needs to be decremented) but it actually doesn't matter, func will still work correctly cuz null byte ender. THIS MUST BE fixed in the save and stripper function
bl source_parser #No error check for this

#Now remove all branch labels and branch label landing spots
mr r3, r27
bl branchlabelparser
cmpwi r3, 0
bne- assembleerror #If not 0, r3 will hold memory address to return to main.S to print to console

#Call custom subfunc to generate a temp code.bin's upper bound size, if gecko code, this will be incremented right before running Waltress
#r3 = pointer to source.s
#r3 returns byte size, will never return an error
mr r3, r27
bl gencodebinsize #TODO in this func add checks for gecko type (and arg) because we need to allocate more shit to memalign if so
mr r26, r3

#Alloc mem for to-be-genned temp code.bin and place its pointer in r31
addi r4, r26, 16 #Highest possible incrementation needed is C0 end that requires a whole end appended,no need to checs, mights as well just increase it across the board for any situation
li r3, 32
bl memalign
mr. r31, r3
lis r3, amemalignTOBEcodebinEC@h
ori r3, r3, amemalignTOBEcodebinEC@l
beq- assembleerror

#Adjust r30 use based on codetype
cmpwi r24, 0
beq- raw_setup_abin
cmpwi r24, 2
bne- add_eight

#Increase r30 by 4 cuz 04 codetype
addi r30, r31, 4
b minusOner27

#Increase r30 by 8 cuz c2/06/c0 codetype
add_eight:
addi r30, r31, 8
b minusOner27

#Prep for Engine
raw_setup_abin:
mr r30, r31
minusOner27:
addi r27, r27, -1

main_abinDV_loop:
mr r5, r27

#Loop
#Check for null byte, if so stop
#Write temp null at 0xA
#Send each source instruction to engine
asm_engine_loop:
lbzu r0, 0x1 (r5)
cmpwi r0, 0
beq- asm_engine_completed
cmpwi r0, 0xA
bne+ asm_engine_loop

overwrite_enter:
li r0, 0
stb r0, 0 (r5)

#Give waltress's arg, then update r27 before running engine
addi r3, r27, 1
addi r22, r27, 1 #Save current asm instruction string in r22. If an error occurs after running Waltress, we know the culprit.
mr r4, r30
mr r27, r5

#RUN WALTRESS ASM (abin.bin) ENGINE
#r27 = r3 = source.s line input addr (must end in null)
#r31 = r4 = code.bin*** output addr (where binary assembled instruction gets written at)
mtlr r29
blrl # :)
cmpwi r3, 0
beq- waltress_loves_us

cmpwi r3, -3
beq- waltress_sscanf_failure

#Bad format/parameter error
mr r3, r22
crxor 6,6,6
bl printf #print the culprit
lis r3, awaltressBadParamEC@h #Set new string for next printf
ori r3, r3, awaltressBadParamEC@l
b assembleerror

#sscanf failure
waltress_sscanf_failure:
mr r3, r22
crxor 6,6,6
bl printf #print the culprit
lis r3, awaltressSscanfFailureEC@h  #Set new string for next printf
ori r3, r3, awaltressSscanfFailureEC@l
b assembleerror

#Update r30 (code.bin pointer) & r28 (amount of times engine ran)
waltress_loves_us:
addi r30, r30, 4
b main_abinDV_loop

asm_engine_completed:
#r3 = code.bin raw size calc (this div'd by 4 = amount of instructions)
#r4 = code.bin pointer
#r5 = codetype
#r6 = gecko header pointer
#r3 returns net code.bin size value
cmpwi r24, 0
beq- mulli_crap
mr r3, r26
mr r4, r31
mr r5, r24
mr r6, r23
bl finalize_assembled_bin
mr r26, r3

#Multiply saved code.bin size by 3 for code.txt's needed memory
#TODO this allocates too much memory for the job, fix later
mulli_crap:
mulli r4, r26, 3
li r3, 32
mr r25, r4 #Need this for later for memset
bl memalign
mr. r30, r3 #r30 we can use now btw
lis r3, amemaligncodetxtEC@h
ori r3, r3, amemaligncodetxtEC@l
beq- assembleerror

#Memset it w/ null. Needed because we will eventually count the content size
mr r3, r30
li r4, 0
mr r5, r25
bl memset

#Change code.bin to code.txt
#Call Hex2ASCII
#r3 = source pointer
#r4 = dest pointer
#r5 = code bin word size (byte / 4)
mr r3, r31
mr r4, r30
srawi r5, r26, 2 #TODO needs adjustment after running finalizeassembled func
bl bin2txt

#Get length of current code.txt (EXclude null byte ender)
addi r3, r30, -1
li r28, 0 #We don't have any more need for r28, free to use now
lbzu r0, 0x1 (r3)
cmpwi r0, 0
beq- 0xC
addi r28, r28, 1
b -0x10

#Add in saved gecko header to code.txt
cmpwi r24, 0 #If Raw, skip ofc
beq- create_codetxt

#r3 = pointer to code.txt
#r4 = code.txt size EXcluding null 
#r5 = pointer to gecko header
#r6 = gecko header type
#r3 returns updated size that EXcludes null
mr r3, r30
mr r4, r28
mr r5, r23
mr r6, r24
bl add_header 
mr r28, r3

#Create finished code.txt
create_codetxt:
lis r3, acodetxt@h
lis r4, awb@h
ori r3, r3, acodetxt@l
ori r4, r4, awb@l
bl fopen
mr. r29, r3
lis r3, afcreatecodetxtEC@h
ori r3, r3, afcreatecodetxtEC@l
beq- assembleerror
li r4, 1
mr r3, r30
mr r5, r28 #Count (real size)
mr r6, r29
bl fwrite
cmpw r3, r28
lis r3, afwritecodetxtEC@h
ori r3, r3, afwritecodetxtEC@l
bne- assembleerror
mr r3, r29
bl fclose
cmpwi r3, 0
lis r3, afclosecodetxtEC@h
ori r3, r3, afclosecodetxtEC@l
bne- assembleerror

#TODO add in code to free up allocated blocks of mem

#Success!
li r3, 0

assembleerror:
lwz r0, 0x0034 (sp)
lwz r31, 0x2C (sp)
lwz r30, 0x28 (sp)
lwz r29, 0x24 (sp)
lwz r28, 0x20 (sp)
lwz r27, 0x1C (sp)
lwz r26, 0x18 (sp)
lwz r25, 0x14 (sp)
lwz r24, 0x10 (sp)
lwz r23, 0xC (sp)
lwz r22, 0x8 (sp)
mtlr r0
addi sp, sp, 0x0030
blr
