#include "a/assemble.s"
#include "a/source_parser.s"
#include "a/gencodebinsize.s"
#include "a/bin2txt.s"
#include "a/finalized_assembled_bin.s"

#include "d/disassemble.s"
#include "d/codetxtparser.s"
#include "d/codetxtpostparsersize.s"
#include "d/codetxt2bin.s"
#include "d/prep_waltress_dbin.s"
#include "d/fixwaltress_nulls.s"

#include "b/dcbst_file.s"
#include "b/icbi_file.s"
#include "b/newline_fixer.s"
#include "b/get_geckoheadertype.s"
#include "b/saveANDoverwrite_geckoheader.s"
#include "b/add_header.s"

prompt_message:
.asciz "Welcome to Waltress! Version 0.6.1\n\nType a for Assembling, type d for Disassembling. "

success_message:
.asciz "Success!\n\n"

fgetsEC:
.asciz "Somehow an fgets error occurred when reading stdin. This should never happen. Please report this Error at MarioKartWii.com!\n\n"

noad:
.asciz "You've entered an invalid option. Relaunch the program.\n\n"

.align 2

.section .text
    .globl main
    
main:
#Prologue, welcome message
stwu sp, -0x0020 (sp) #0x8 space for char
lis r3, prompt_message@h
mflr r0
ori r3, r3, prompt_message@l
stw r0, 0x0024 (sp)
crxor 6,6,6
bl printf

#Call fgets and check return of fgets
lis r5, stdin@ha
li r4, 100 #FIX ME LATER, we don't need this high of a number
lwz r5, stdin@l (r5)
addi r3, sp, 8
bl fgets
cmpwi r3, 0
lis r3, fgetsEC@h
ori r3, r3, fgetsEC@l
beq- error

#No error on fgets
lbz r0, 0x8 (sp)
cmpwi r0, 0x61
bne- check_d
bl assemble
b check_for_error

check_d:
cmpwi r0, 0x64
lis r3, noad@h
ori r3, r3, noad@l
bne- error
bl disassemble

check_for_error:
cmpwi r3, 0
bne- error

#Success
lis r3, success_message@h
ori r3, r3, success_message@l
bl puts
b epilogue

#Error, r3 is already set, simply run printf!
error:
crxor 6,6,6
bl printf

#Epilogue
epilogue:
li r3, 0 #Signal to exit
lwz r0, 0x0024 (sp)
mtlr r0
addi sp, sp, 0x0020
blr
