#!/bin/bash

echo "Enter directory where devkitpro is installed at. If unsure, this is usually located at /opt"
read devkitloc

echo "Enter directory where HBC-Source is located at (i.e. /home/zak/Waltress02132024)"
read walloc

cd $devkitloc/devkitpro/devkitPPC/bin

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/main.s -o $walloc/HBC-Source/build/main.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/assemble.s -o $walloc/HBC-Source/build/assemble.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/bin2txt.s -o $walloc/HBC-Source/build/bin2txt.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/finalized_assembled_bin.s -o $walloc/HBC-Source/build/finalized_assembled_bin.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/gencodebinsize.s -o $walloc/HBC-Source/build/gencodebinsize.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/source_parser.s -o $walloc/HBC-Source/build/source_parser.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/add_header.s -o $walloc/HBC-Source/build/add_header.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/get_geckoheadertype.s -o $walloc/HBC-Source/build/get_geckoheadertype.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/saveANDoverwrite_geckoheader.s -o $walloc/HBC-Source/build/saveANDoverwrite_geckoheader.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/codetxt2bin.s -o $walloc/HBC-Source/build/codetxt2bin.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/codetxtparser.s -o $walloc/HBC-Source/build/codetxtparser.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/codetxtpostparsersize.s -o $walloc/HBC-Source/build/codetxtpostparsersize.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/disassemble.s -o $walloc/HBC-Source/build/disassemble.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/fixwaltress_nulls.s -o $walloc/HBC-Source/build/fixwaltress_nulls.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/prep_waltress_dbin.s -o $walloc/HBC-Source/build/prep_waltress_dbin.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/newline_fixer.s -o $walloc/HBC-Source/build/newline_fixer.o

./powerpc-eabi-as -mregnames -mbroadway $walloc/HBC-Source/build/branchlabelparser.s -o $walloc/HBC-Source/build/branchlabelparser.o

cd $walloc/HBC-Source
make
rm HBC-Source.elf
mv HBC-Source.dol boot.dol
cd build
rm *.o
rm *.elf.map

echo "Done! Delete old boot.dol located at /HBC-Waltress, and replace with new boot.dol that's located at /HBC-Source"


