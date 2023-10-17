	.file	"fixwaltress_nulls.c"
	.machine ppc
	.section	".text"
	.ident	"GCC: (devkitPPC release 44.2) 13.2.0"

#Func is meant to fix source.s after dbin.bin
#Replace all gen'd null bytes with 0x20 and 0xA. end in final null
#r3 = Pointer to newly gen source.s
#r4 = number of instructions

#TODO maybe write in code to check if r4 = 1 then simply blr back!

.set enter, 0x0A

.globl fixwaltress_nulls
fixwaltress_nulls:
li r5, enter
li r6, 0
mtctr r4

#Find the next null byte, once found decrement CTR, if CTR zero, skip 'fix', we are eof
fixwaltress_nulls_loop:
lbzu r0, 0x1 (r3) #No need to pre-decrement, no source.s line is a byte long
cmpwi r0, 0
bne+ fixwaltress_nulls_loop

#Found Waltress-created null byte, apply "enter"
stb r5, 0 (r3)

#Decrement
bdnz+ fixwaltress_nulls_loop
li r0, 0 #Store final final null byte, overwrites most recent newly written 0xA ofc. *NOTE* this is important as it ensures final string is terminated, sanity for overflow
stb r0, 0 (r3)
blr

