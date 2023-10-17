#r3 = source pointer
#r4 = dest pointer
#r5 = code.bin byte size / 4 

.globl bin2txt
bin2txt:
stwu sp, -0x0020 (sp)
mflr r0
stw r26, 0x8 (sp)
stw r27, 0xC (sp)
stw r28, 0x10 (sp)
stw r29, 0x14 (sp)
stw r30, 0x18 (sp)
stw r31, 0x1C (sp)
stw r0, 0x0024 (sp)

#Save args
addi r31, r3, -4
addi r30, r4, -1

#Set Loop Amount
mtctr r5

#Set space vs enter flag
li r26, -1

#Loop
bin2txtloop:
lwzu r0, 0x4 (r31)
rlwinm r6, r0, 4, 0x0000000F #srwi r6, r5, 28
rlwinm r7, r0, 8, 0x0000000F
rlwinm r8, r0, 12, 0x0000000F
rlwinm r9, r0, 16, 0x0000000F
rlwinm r10, r0, 20, 0x0000000F
rlwinm r29, r0, 24, 0x0000000F
rlwinm r4, r0, 28, 0x0000000F
rlwinm r5, r0, 0, 0x0000000F #clrlwi r5, r5, 28

mr r3, r6
bl hex2ascii
rlwimi r27, r3, 24, 0xFFFFFFFF #Needed to not use any junk data thats residing in r27

mr r3, r7
bl hex2ascii
rlwimi r27, r3, 16, 0x00FF0000

mr r3, r8
bl hex2ascii
rlwimi r27, r3, 8, 0x0000FF00

mr r3, r9
bl hex2ascii
rlwimi r27, r3, 0, 0x000000FF

mr r3, r10
bl hex2ascii
rlwimi r28, r3, 24, 0xFFFFFFFF #Needed to not use any junk data thats residing in r27

mr r3, r29
bl hex2ascii
rlwimi r28, r3, 16, 0x00FF0000

mr r3, r4
bl hex2ascii
rlwimi r28, r3, 8, 0x0000FF00

mr r3, r5
bl hex2ascii
rlwimi r28, r3, 0, 0x000000FF

#Check space vs enter flag, also store r27 and r28 to give time for branch prediction
not. r26, r26
stw r27, 0x1 (r30)
stw r28, 0x5 (r30)
bne- 0xC
#Write space 0x20
li r3, 0x20
b 0x8
#Write enter 0xA
li r3, 0xA
stbu r3, 0x9 (r30)
bdnz+ bin2txtloop

#Write null byte over final space/enter
li r0, 0
stb r0, 0x0 (r30)

#End func
lwz r0, 0x0024 (sp)
lwz r31, 0x1C (sp)
lwz r30, 0x18 (sp)
lwz r29, 0x14 (sp)
lwz r28, 0x10 (sp)
lwz r27, 0xC (sp)
lwz r26, 0x8 (sp)
mtlr r0
addi sp, sp, 0x0020
blr

hex2ascii:
cmplwi r3, 9
bgt- 0xC #less likely branch because A-F is less possible outcomes than 0-9
ori r3, r3, 0x30
blr
addi r3, r3, 0x37
blr
