fixneghexEC:
.asciz "\n\nError! For whatever reason, the malloc function failed within the fix_neg_hex.s subroutine."
.align 2

#r3 = Ptr to source.s
#r3 returns 0 for success or addr to return a message for printing back to parent

.globl fix_neg_hex
fix_neg_hex:
#Prologue
stwu sp, -0x0030 (sp)
mflr r0
stw r27, 0x1C (sp) #0x8 thru 0x11 is buffer space (10 bytes)
stw r28, 0x20 (sp)
stw r29, 0x24 (sp)
stw r30, 0x28 (sp)
stw r31, 0x2C (sp)
stw r0, 0x0034 (sp)

#Save arg
mr r31, r3

#Pre decrement loading addr
subi r30, r3, 1

#ROOT LOOP
fix_neg_hex_ROOT_loop:
lwzu r0, 0x1 (r30)
srwi. r3, r0, 24 #Check for null byte by removing 3 far side right bytes
beq- fix_neg_hex_success

#Set constant to compare to
lis r3, 0x002D
ori r3, r3, 0x3078

#Verify against constant
srwi r4, r0, 8
cmpw r3, r4
bne+ fix_neg_hex_ROOT_loop

#Found negative hex SIMM!
#NOTE First make sure we *SKIP* condi branches
#Make copy of cursor and go back to first enter before current instruction, or SoF-1 (start of file minus 1)
mr r3, r30
lbzu r0, -0x1 (r3)
cmplw r3, r31
blt- 0x10
cmpwi r0, 0xA
beq- 0x8
b -0x14
#Okay we are at \n or at SoF-1, now check if next line instruction was a condi branch
lhz r0, 0x1 (r3)
cmpwi r0, 0x6267 #bg
beq- fix_neg_hex_ROOT_loop
cmpwi r0, 0x6265 #be
beq- fix_neg_hex_ROOT_loop
cmpwi r0, 0x626E #bn
beq- fix_neg_hex_ROOT_loop
cmpwi r0, 0x6264 #bd
beq- fix_neg_hex_ROOT_loop
cmpwi r0, 0x626C #bl
beq- check_for_t_or_e
cmpwi r0, 0x6273
bne+ not_a_condi_branch
#bs found, if char after bs is o, then abort. its a condi branch
lbz r0, 0x3 (r3)
cmpwi r0, 0x6F #o
beq- fix_neg_hex_ROOT_loop
b not_a_condi_branch
check_for_t_or_e:
lbz r0, 0x3 (r3)
cmpwi r0, 0x74 #t
beq- fix_neg_hex_ROOT_loop
cmpwi r0, 0x65 #e
beq- fix_neg_hex_ROOT_loop

#Okay perfect negative SIMM is *NOT* for a condi branch, good to proceed.
#Count the amount of hexanumerical ascii digits til non-hexanumerical
not_a_condi_branch:
addi r3, r30, 2 #Point to "x" so first load is the first SIMM digit
digit_width_loop:
lbzu r0, 0x1 (r3)
cmplwi r0, 0x46 #F
bgt- done_w_digit_width_loop
cmplwi r0, 0x30 #0
blt- done_w_digit_width_loop
cmplwi r0, 0x39 #9
ble- digit_width_loop
cmplwi r0, 0x41 #A
bge- digit_width_loop
done_w_digit_width_loop:
sub r29, r3, r30

#Change negative ascii to temp positive
#Change temp pos ascii to temp pos hex int
#Flip pos hex int to neg (unsigned eqiv)
#Change neg int to final unsigned ascii
addi r3, r30, 3
subi r4, r29, 3 #Discount the "-0x" portion
bl fixneghex_ascii2hex #r3 = src addr, r4 = amount of digits to convert, r3 returns hex word
#Neg it!
neg r3, r3
#Flip back to ascii
addi r4, sp, 8
bl fixneghex_hex2ascii

#Do Size minus 10
subic. r3, r29, 10
beq- transfer_the_new_simm

#No matter what, we need source.s plus Null byte length
#Keep cr0 and r3 intact
subi r4, r31, 1
lbzu r0, 0x1 (r4)
cmpwi cr7, r0, 0
bne+ cr7, -0x8
sub r4, r4, r31
addi r28, r4, 1 #Count null byte and save size to r28

#Now branch (cr7) on whether or not we malloc
bgt- we_DONT_need_malloc

#Call malloc, and adjust global r27 register (global source.s ptr)
sub r3, r28, r3 #r3 (delta) is negative, so a subtraction will yield an addition
bl malloc
mr. r27, r3
beq- fix_neg_hex_malloc_ec_string_lock
#Memcpy source.s to malloc'd space
mr r4, r31
mr r5, r28
bl memcpy

#Change GLOBAL r27 with local r27. THIS IS A GLOBAL CHANGE!
stw r27, 0x1C (sp)
#Fix r30 (-0xXXX... ptr)
sub r3, r30, r31
add r30, r27, r3
#Fix this func's r31 (source.s ptr)
mr r31, r27
#Now we can memmove, yay

we_DONT_need_malloc:
#Memmove portion of file to right to free up inner space to insert 0x00000000 over -0xX...
#r3 = dest; 
#r4 = src; where the comma is located (r30)
#r5 = amt (null byte ptr minus src ptr) + 1
add r4, r30, r29 #-0xXX ptr + SIMM width size = src ptr
addi r3, r30, 10 #Okay to hardcode since all newly gen'd SIMMs with be 10 digits in width
add r5, r31, r28 #r5 at this moment = one past PAST null byte ptr
sub r5, r5, r4 #One-past-Null byte ptr - Src ptr = amount to move
bl memmove

#Transfer newly gen'd SIMM from stack buffer to its spot in updated source.s
#r3 needs to be setup before this section is executed
transfer_the_new_simm:
li r0, 5 #5 halfwords to transfer
addi r3, sp, 6 #r4 is same no matter circumstance
mtctr r0
subi r4, r30, 2
lhzu r0, 0x2 (r3)
sthu r0, 0x2 (r4)
bdnz+ -0x8
b fix_neg_hex_ROOT_loop

fix_neg_hex_malloc_ec_string_lock:
lis r3, fixneghexEC@h
ori r3, r3, fixneghexEC@l
b 0x8

#Return
fix_neg_hex_success:
li r3, 0
lwz r0, 0x0034 (sp)
lwz r31, 0x2C (sp)
lwz r30, 0x28 (sp)
lwz r29, 0x24 (sp)
lwz r28, 0x20 (sp)
lwz r27, 0x1C (sp)
mtlr r0
addi sp, sp, 0x0030
blr

fixneghex_hex2ascii:
#Write "0x"
li r0, 0x3078
sth r0, 0 (r4)
#Set loop amount
li r0, 8
mtctr r0
#Set initial shiftor amount
li r5, 32
#Adjust r4 for when we stbu the ascii byte
addi r4, r4, 1
#Loop
fixneghex_hex2ascii_loop:
#Update shiftor  amount
subi r5, r5, 4
#Extract digit
srw r0, r3, r5
clrlwi r6, r0, 28
#Convert from digit hex to byte ascii
cmplwi r6, 9
bgt- 0xC
ori r7, r6, 0x30
b 0x8
addi r7, r6, 0x37
#Store converted byte to buffer
stbu r7, 0x1 (r4)
#Decrement loop
bdnz+ fixneghex_hex2ascii_loop
#End func
blr

fixneghex_ascii2hex: #r3 = src addr of SIMM hex word, r4 = digit length
mtctr r4
slwi r5, r4, 2 #r4 x 4 = start-off slw shiftor amount (r5)
subi r4, r3, 1
li r3, 0 #Register used to "compile" word
lbzu r6, 0x1 (r4)
cmplwi r6, 0x39
subi r5, r5, 4 #update shiftor amount
bgt- 0xC
clrlwi r6, r6, 28 #change 0x30 thru 0x39 to 0x0 thru 0x9
b 0x8
subi r6, r6, 0x37 #Change 0x41 thru 0x46 to 0xA thru 0xF
slw r6, r6, r5 #Place hex digit into its proper slot
or r3, r3, r6 #"compile" hexword
bdnz+ -0x24
blr
