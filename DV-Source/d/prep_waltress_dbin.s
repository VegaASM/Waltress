#Func will properly prep the engine to where all the parent func has to do is typical pre-decrement of
#r3 = code.bin pointer
#r4 = code.TXT size (***NOT** .bin size, it hasn't yet been calc'd)
#r5 = gecko type

#Func returns
#r3 = new code.bin pointer
#r4 = loop/instruction amount for waltress dbin

#(code.txt post excluding null byte parsed size / 2) = code.bin size
#code.bin size / 4 = Amount of Instruction
#Raw = do nothing afterwards
#!04 = lower by 1 afterwards, skip decrement of r27
#!06 = read 06-specific byte count, divide by 4, increment r27 by 4
#!C2 = increment r27 by 4, read C2 line count, mulli by 2. Subtract 1 for 00000000. Then read line count again, if odd and 2nd to last word is nop, subtract 1 again for GVR
#!C0 = increment r27 by 4, read C0 line count, mulli by 2. Subtract 1 afterwards. Then read line count again. If odd and final final instruction is 00000000, then skip blr (2nd to last instruction), and subtract 1 again to compensate

#0 = Raw
#1 = C2
#2 = 04
#3 = 06
#4 = C0

.globl prep_waltress_dbin
prep_waltress_dbin:
cmpwi r5, 0
srawi r4, r4, 3 #Divide code.TXT! size by 8 to get raw instruction amount
beqlr-

#Check for C2
cmpwi r5, 1
bne- try04

#C2 codetype found
#Make sure C2 line amount matches {(rawinstructionamount - 2) / 2}
lwz r6, 0x4 (r3)
subi r7, r4, 2
srawi r7, r7, 1
cmpw r7, r6
mr r5, r3 #temp save r3
li r3, 0
bnelr-
#Good to go
subi r4, r4, 3 #Take away C2 header  C2 line amount, and final null word
addi r3, r5, 8 #Go  past header past C2 line amount
#Check if C2's byte amount matches r4 genned amount

#If 2nd to last word is nop, subtract r4 by one more
lis r0, 0x6000 #Nop
slwi r6, r4, 2 #r6 = instruction amount x 4 =  (byte amount of source + possible nop)
subi r6, r6, 4
lwzx r6, r6, r3
cmpw r0, r6
bnelr-
subi r4, r4, 1
blr

#Check for 04
try04:
cmpwi r5, 2
bne- tryC0

#04 codetype found
addi r3, r3, 4
li r4, 1
blr

#Check for C0
tryC0:
cmpwi r5, 4
bne- found06

#C0 codetype found
#Make sure C0 line amount matches {(rawinstructionamount - 2) / 2}
lwz r6, 0x4 (r3)
subi r7, r4, 2
srawi r7, r7, 1
cmpw r7, r6
mr r5, r3 #temp save r3
li r3, 0
bnelr-
#Good to go
subi r4, r4, 2 #Take away C0 header  C0 line amount
addi r3, r5, 8 #Go  past header past C2 line amount

#If last word is null or blr, subtract one more
lis r0, 0x4E80 #blr
ori r0, r0, 0x0020
slwi r6, r4, 2 #r6 = instruction amount x 4 =  (byte amount of source + possible 2ndtolastword)
subi r6, r6, 4
lwzx r7, r6, r3
cmpwi r7, 0
beq- 0xC
cmpw r7, r0
bnelr- #For whatever reason the C0 code in question has an odd setup (custom blr in middle?), *DON*T subtract anymore from r4, end func
#Check if 2nd to last and last word are blr's
#If 2nd to last word is blr, subtract one more again...
subi r4, r4, 1
subi r6, r6, 4
lwzx r7, r6, r3
cmpw r7, r0
bnelr-
subi r4, r4, 1
blr

#06 codetype found
found06:
lwz r6, 0x4 (r3)
andi. r0, r6, 3 #06 byte amount must be divisible by 4
addi r5, r3, 8 #Go past 06 header 06 byte amount
li r3, 0
bnelr-
subi r4, r4, 2 #Take away 06 header and 06 byte amount line
#If 06 byte amount ends in 0x4 or 0xC, then subtract r4 by 1 and compare vs r6 cuz last word of 06 code is null. If not, skip the subtraction part
andi. r0, r6, 7
beq- 0x8
subi r4, r4, 1
#Byte Amount / 4 should match instruction amount
srawi r6, r6, 2
cmpw r6, r4
bnelr- #r3 still 0
mr r3, r5 #Recover r3 before returning to signal everything is good to go
blr
