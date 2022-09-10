# Waltress

Readme modified for Waltress on Github

Welcome to Waltress! The first ever PPC Assembler+Disassembler entirely handwritten in PPC! It is 100% Broadway (Wii CPU) compliant. Waltress is also a bare bones Gecko Cheat Code compiler. Please read over this document to understand the contents of some of the folders and files present in this zip package.

Created by Vega

=====================

General Overview~

Why the name Waltress? Waltress is one of Daysha's cats, and she is a shy black+brown long hair cat with a gigantic fluffy tail. Waltress is also the site mascot for MarioKartWii.com.

This Package includes the following folders & files~

-- Engine #The handwritten source files for Waltress's "Engine" Binary Files

-- Examples #Contains multiple pre-made source.s, code.bin, and code.txt files to assist you in understanding the required format of writing your own files for usage of Waltress

-- Source-HBC #The source files for the Waltress HBC Application

-- Waltress #The Waltress HBC Application

-- ERRORS.txt #Definition of error codes that may appear when running the HBC Application

-- FORMAT.txt #Everything you need to know regarding format rules for Assembling and Disassembling

-- HISTORY.txt #Summary of past revisions

-- LICENSE #Copy of GPL 3.0

-- README.md #This document you are reading right now

Waltress can assemble and disassemble raw PPC code. She can also compile and decompile certain Gecko Cheat Codes. Please ***READ*** the FORMAT.txt file before using Waltress!!!

List of Gecko Cheat Codes supported:
- RAM Write (04 Opcode)
- String Write (06 Opcode)
- Execute ASM (C0 Opcode); YES, blr is auto-added for you!
- Insert ASM (C2 Opcode)

Waltress is only at version 0.5. She is considered to be meta-stable.

=====================

Using Waltress HBC App~

Requirements: HBC (version 1.1.0 or later) installed on your Wii. Waltress has only been tested on Wii and Dolphin-Emulator (virtual SD). She may NOT work on the Wii-U. HBC App has only been tested via being located on the SD Card. Usage of the App on a USB device has not been tested. However, it should work without issue.

1. Copy-Paste the Waltress folder into the apps folder of your SD/USB device
2a. Waltress expects a source.s file present in apps/Waltress for assembling or Gecko Code compiling. Place source.s into apps/Waltress folder
2b. Waltress expects a code.txt or code.bin file present in apps/Waltress for disassembling or Gecko Code decompiling. Place that file into apps/Waltress folder.
3. Do *NOT* have both a source.s and code.txt/bin file present in apps/Waltress.
4. SD/USB device out of computer and into your Wii
5. Launch HBC. Launch Waltress HBC App. Follow on-screen instructions.
6. Waltress will display a Success Message or an Error Code (negative number) after usage. Read the ERRORS.txt file for more information about error codes.

=======================

About source.s & code.txt/bin~

When writing a source.s file for assembling or for Gecko Cheat Code compiling, there are *many* format requirements that must be followed. All format requirements are listed in the FORMAT.txt file. In the Waltress HBC App, you can choose to assemble/compile to a code.bin, or to a code.txt file.

When writing a code.txt file for disassembling or for Gecko Cheat Code decompiling, there are format requirements that must be followed. It's not as many as in the case of assembling a source.s, but you still need to read the FORMAT.txt file to avoid unintended error codes.

Alternatively, you can disassemble a code.bin file instead. Since code.bin is a basic binary file, there isn't much requirements to follow. All that is required is that the file shall only contain assembled PPC instructions only. Nothing else.

All disassembling results into a source.s file.

In conclusion, ***READ*** the FORMAT.txt file before using Waltress.

=========================

Features~

While Waltress may have her quirks, she does come with some features that no other Assembler+Disassembler provides. Those are...

- Has checks to make sure rA =/= r0 for psq_lu, psq_lux, psq_stu, & psq_stux.
- Has checks to make sure NB in a lswi instruction does not cause rD loaded bytes to spill into rA.
- Has checks to make sure a valid SPR number is being used for mfspr, mftb, and mtspr instructions. This includes support for mfspr using any of the 3 CHIP ID SPR's (925, 926, 927).
- Everything that can be assembled can be disassembled, and vice versa. Other programs (such as PyiiASMH) cannot do this due its inconvertibility of illegal (.long) instructions.

*NOTE*: The following simplified mnemonics...

*trap
*blr
*blrl
*bctr
*bctrl

...may not re-assemble back to their 100% original pre-assembled instruction (Hexadecimal word value) after disassembling from an original code.txt/bin file. This is because these simplified mnemonics have fields and/or register values that qualify as "Don't Care Values". Meaning that these fields/values can be anything and the instruction in question still qualifies as being the simplified mnemonic. Please note that all other known PPC Assembler+Disassemblers are "plagued" with this. It's impossible to fix without completely getting rid of the simplified mnemonics.

=====================

HBC App Source Compilation Instructions (Linux only)~

Requirements: DevkitPPC installed and it's environment set.

1. Open a terminal and go to the directory where your PPC Binutils are located. This will be located at /whereyouinstalledDevKit/devkitpro/devkitPPC/bin

cd /whereyouinstalledDevKit/devkitpro/devkitPPC/bin

2. Run the following command in terminal

./powerpc-eabi-as -mregnames -mbroadway /path/to/Source-HBC/build/main.s -o /path/to/Source-HBC/build/main.o

3. At this point an object file is now created. Navigate to the Source-HBC folder and run a make command to finish the build

cd /path/to/Source-HBC
make

4. There will be a new Source-HBC.dol and Source-HBC.elf file created in the Source-HBC folder. Delete the .elf file that was generated. Navigate to the Waltress folder (where the pre-compiled HBC app files reside at), and DELETE that boot.dol.

cd /path/to/Waltress
rm boot.dol

5. Now rename the Source-HBC.dol to boot.dol. Place the new boot.dol into the Waltress folder.

=====================

Engine Folder Overview~

The Engine folder contains the following items~

- abin.bin (Assembler Engine)
- dbin.bin (Disassembler Engine)
- main_asm.s (handwritten source for abin.bin)
- main_dasm.s (handwritten source for dbin.bin)

The abin.bin and dbin.bin files are the "heart" of Waltress. These are the actual binary files that do all the magic.

The handwritten source files (main_asm.s & main_dasm.s) for the engine files are HUGE! This was a lot of work to get this done and for it to actually assemble. I suffered many hand cramps... There may be some oddball leftover notes and comments that don't make sense (lol). I cannot be asked to 'scrub' the source files and make them 'pretty'. :P

How to assemble the abin.bin and dbin.bin files from their source. 

1. Copy paste the contents of main_asm.s into PyiiASMH. Select RAW option and assemble. Use a Hex editor (such as HxD), copy paste the assembled instructions from PyiiASMH into your Hex Editor. Save it as abin.bin.

2. Repeat step 1, but use main_dasm.s and save it as dbin.bin. Congratz, engine files have been assembled from handwritten source. To verify these have been assembled correctly, use any standard SHA-family hashing program/mechanism. The hashes of the binary files you have assembled from source SHOULD match the binary files that were already present.

NOTE: The assembling the handwritten source files have only been tested on Legacy PyiiASMH. May not work with Devkit, Codewrite, PyiiASMH-3, WiiRDGUI, etc.

=====================

Waltress using Waltress Guide~

***YES*** Waltress can disassemble herself and then re-assemble herself!!! There would be no reason to release Waltress if she wasn't capable of doing such a task.

1. Make a copy of abin.bin and place it in the Waltress folder. When asked by your Computer OS on what to do (i.e. skip, replace, rename, etc), click rename and rename it to code.bin. Thus, you now have an exact copy of abin.bin present that is now called code.bin. So the 3 *BINARY* files present in the Waltress folder are abin.bin, code.bin (copy of abin.bin), and dbin.bin.

2. Place Waltress folder in the apps folder of your SD/USB device. Plug device in Wii, launch HBC, launch Waltress HBC App. Click X/- on your controller to disassemble using the "code.bin" option. Then at the disassembly/decompilation option screen, press A for the "Raw" option. The App will notify you with a SUCCESS message prompt. It will also say that you can press B on your controller to remove the original (input) file. **Press B.**. Code.bin is now deleted, and you will auto-exit back to HBC.

3. At this point you will be residing at HBC Main Menu, and you will have a source.s file representing the source for abin.bin. Relaunch Waltress HBC app. Press Y/+ to assemble using the "code.bin" option. It will be successful, and press B to delete the source.s file. File will be deleted and you will auto-exit back to HBC.

4. Plug SD/USB device back into computer, there will be a code.bin file. Now using any SHA-family hashing program/mechanism, run hashes for abin.bin and code.bin. You will see they are an EXACT MATCH. Congratz!!!

5. Delete the code.bin, and repeat steps 1 thru 4 again but for dbin.bin. Verify the hashes of dbin.bin vs code.bin. They will be an EXACT MATCH. Now you will have both engine files re-assembled and verified using Waltress. :)

6. Fyi: You don't have to delete the source.s's of abin.bin and dbin.bin if you want to keep them. You can use them as a helpful guide on instruction format for future Assembling. :)
