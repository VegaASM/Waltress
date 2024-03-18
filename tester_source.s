#This is a test source to compare the results against something like CodeWrite
add r5, r15, r25
add. r5, r15, r25
addo r5, r15, r25
addo. r5, r15, r25
addc r5, r15, r25
addc. r5, r15, r25
addco r5, r15, r25
addco. r5, r15, r25
adde r5, r15, r25
adde. r5, r15, r25
addeo r5, r15, r25
addeo. r5, r15, r25
addi r5, r15, 0x7777
addi r5, r15, 0xFFFF9999
li r5, 0x7777
li r5, 0xFFFF9999
subi r5, r15, 0x7777
subi r5, r15, 0xFFFF9999
addic r5, r15, 0x7777
addic r5, r15, 0xFFFF9999
subic r5, r15, 0x7777
subic r5, r15, 0xFFFF9999
addic. r5, r15, 0x7777
addic. r5, r15, 0xFFFF9999
subic. r5, r15, 0x7777
subic. r5, r15, 0xFFFF9999
addis r5, r15, 0xDDDD
lis r5, 0xDDDD
subis r5, r15, 0xDDDD #Note there is a bug in Codewrite where it uses SIMM for subis instead of UIMM, switch the IMM to 0xFFFFDDDD when testing against Codewrite
addme r5, r15
addme. r5, r15
addmeo r5, r15
addmeo. r5, r15
addze r5, r15
addze. r5, r15
addzeo r5, r15
addzeo. r5, r15
and r5, r15, r25
and. r5, r15, r25
andc r5, r15, r25
andc. r5, r15, r25
andi. r5, r15, 0xDDDD
andis. r5, r15, 0xDDDD
b 0x8
b 0xFFFFFFF8
ba 0x8
ba 0xFFFFFFF8
bl 0x8
bl 0xFFFFFFF8
bla 0x8
bla 0xFFFFFFF8
bc 12, 2, 0x8
bc 12, 2, 0xFFFFFFF8
bca 12, 2, 0x8
bca 12, 2, 0xFFFFFFF8
bcl 12, 2, 0x8
bcl 12, 2, 0xFFFFFFF8
bcla 12, 2, 0x8
bcla 12, 2, 0xFFFFFFF8
bdnzf 2, 0x8
bdnzf 2, 0xFFFFFFF8
bdnzf- 2, 0x8
bdnzf- 2, 0xFFFFFFF8
bdnzf+ 2, 0x8
bdnzf+ 2, 0xFFFFFFF8
bdnzfl 2, 0x8
bdnzfl 2, 0xFFFFFFF8
bdnzfl- 2, 0x8
bdnzfl- 2, 0xFFFFFFF8
bdnzfl+ 2, 0x8
bdnzfl+ 2, 0xFFFFFFF8
bdnzfa 2, 0x8
bdnzfa 2, 0xFFFFFFF8
bdnzfa- 2, 0x8
bdnzfa- 2, 0xFFFFFFF8
bdnzfa+ 2, 0x8
bdnzfa+ 2, 0xFFFFFFF8
bdnzfla 2, 0x8
bdnzfla 2, 0xFFFFFFF8
bdnzfla- 2, 0x8
bdnzfla- 2, 0xFFFFFFF8
bdnzfla+ 2, 0x8
bdnzfla+ 2, 0xFFFFFFF8
bdzf 2, 0x8
bdzf 2, 0xFFFFFFF8
bdzf- 2, 0x8
bdzf- 2, 0xFFFFFFF8
bdzf+ 2, 0x8
bdzf+ 2, 0xFFFFFFF8
bdzfl 2, 0x8
bdzfl 2, 0xFFFFFFF8
bdzfl- 2, 0x8
bdzfl- 2, 0xFFFFFFF8
bdzfl+ 2, 0x8
bdzfl+ 2, 0xFFFFFFF8
bdzfa 2, 0x8
bdzfa 2, 0xFFFFFFF8
bdzfa- 2, 0x8
bdzfa- 2, 0xFFFFFFF8
bdzfa+ 2, 0x8
bdzfa+ 2, 0xFFFFFFF8
bdzfla 2, 0x8
bdzfla 2, 0xFFFFFFF8
bdzfla- 2, 0x8
bdzfla- 2, 0xFFFFFFF8
bdzfla+ 2, 0x8
bdzfla+ 2, 0xFFFFFFF8
bge cr4, 0x8
bge cr4, 0xFFFFFFF8
bge- cr4, 0x8
bge- cr4, 0xFFFFFFF8
bge+ cr4, 0x8
bge+ cr4, 0xFFFFFFF8
bgel cr4, 0x8
bgel cr4, 0xFFFFFFF8
bgel- cr4, 0x8
bgel- cr4, 0xFFFFFFF8
bgel+ cr4, 0x8
bgel+ cr4, 0xFFFFFFF8
bgea cr4, 0x8
bgea cr4, 0xFFFFFFF8
bgea- cr4, 0x8
bgea- cr4, 0xFFFFFFF8
bgea+ cr4, 0x8
bgea+ cr4, 0xFFFFFFF8
bgela cr4, 0x8
bgela cr4, 0xFFFFFFF8
bgela- cr4, 0x8
bgela- cr4, 0xFFFFFFF8
bgela+ cr4, 0x8
bgela+ cr4, 0xFFFFFFF8
bge 0x8
bge 0xFFFFFFF8
bge- 0x8
bge- 0xFFFFFFF8
bge+ 0x8
bge+ 0xFFFFFFF8
bgel 0x8
bgel 0xFFFFFFF8
bgel- 0x8
bgel- 0xFFFFFFF8
bgel+ 0x8
bgel+ 0xFFFFFFF8
bgea 0x8
bgea 0xFFFFFFF8
bgea- 0x8
bgea- 0xFFFFFFF8
bgea+ 0x8
bgea+ 0xFFFFFFF8
bgela 0x8
bgela 0xFFFFFFF8
bgela- 0x8
bgela- 0xFFFFFFF8
bgela+ 0x8
bgela+ 0xFFFFFFF8
ble cr4, 0x8
ble cr4, 0xFFFFFFF8
ble- cr4, 0x8
ble- cr4, 0xFFFFFFF8
ble+ cr4, 0x8
ble+ cr4, 0xFFFFFFF8
blel cr4, 0x8
blel cr4, 0xFFFFFFF8
blel- cr4, 0x8
blel- cr4, 0xFFFFFFF8
blel+ cr4, 0x8
blel+ cr4, 0xFFFFFFF8
blea cr4, 0x8
blea cr4, 0xFFFFFFF8
blea- cr4, 0x8
blea- cr4, 0xFFFFFFF8
blea+ cr4, 0x8
blea+ cr4, 0xFFFFFFF8
blela cr4, 0x8
blela cr4, 0xFFFFFFF8
blela- cr4, 0x8
blela- cr4, 0xFFFFFFF8
blela+ cr4, 0x8
blela+ cr4, 0xFFFFFFF8
ble 0x8
ble 0xFFFFFFF8
ble- 0x8
ble- 0xFFFFFFF8
ble+ 0x8
ble+ 0xFFFFFFF8
blel 0x8
blel 0xFFFFFFF8
blel- 0x8
blel- 0xFFFFFFF8
blel+ 0x8
blel+ 0xFFFFFFF8
blea 0x8
blea 0xFFFFFFF8
blea- 0x8
blea- 0xFFFFFFF8
blea+ 0x8
blea+ 0xFFFFFFF8
blela 0x8
blela 0xFFFFFFF8
blela- 0x8
blela- 0xFFFFFFF8
blela+ 0x8
blela+ 0xFFFFFFF8
bne cr4, 0x8
bne cr4, 0xFFFFFFF8
bne- cr4, 0x8
bne- cr4, 0xFFFFFFF8
bne+ cr4, 0x8
bne+ cr4, 0xFFFFFFF8
bnel cr4, 0x8
bnel cr4, 0xFFFFFFF8
bnel- cr4, 0x8
bnel- cr4, 0xFFFFFFF8
bnel+ cr4, 0x8
bnel+ cr4, 0xFFFFFFF8
bnea cr4, 0x8
bnea cr4, 0xFFFFFFF8
bnea- cr4, 0x8
bnea- cr4, 0xFFFFFFF8
bnea+ cr4, 0x8
bnea+ cr4, 0xFFFFFFF8
bnela cr4, 0x8
bnela cr4, 0xFFFFFFF8
bnela- cr4, 0x8
bnela- cr4, 0xFFFFFFF8
bnela+ cr4, 0x8
bnela+ cr4, 0xFFFFFFF8
bne 0x8
bne 0xFFFFFFF8
bne- 0x8
bne- 0xFFFFFFF8
bne+ 0x8
bne+ 0xFFFFFFF8
bnel 0x8
bnel 0xFFFFFFF8
bnel- 0x8
bnel- 0xFFFFFFF8
bnel+ 0x8
bnel+ 0xFFFFFFF8
bnea 0x8
bnea 0xFFFFFFF8
bnea- 0x8
bnea- 0xFFFFFFF8
bnea+ 0x8
bnea+ 0xFFFFFFF8
bnela 0x8
bnela 0xFFFFFFF8
bnela- 0x8
bnela- 0xFFFFFFF8
bnela+ 0x8
bnela+ 0xFFFFFFF8
bns cr4, 0x8
bns cr4, 0xFFFFFFF8
bns- cr4, 0x8
bns- cr4, 0xFFFFFFF8
bns+ cr4, 0x8
bns+ cr4, 0xFFFFFFF8
bnsl cr4, 0x8
bnsl cr4, 0xFFFFFFF8
bnsl- cr4, 0x8
bnsl- cr4, 0xFFFFFFF8
bnsl+ cr4, 0x8
bnsl+ cr4, 0xFFFFFFF8
bnsa cr4, 0x8
bnsa cr4, 0xFFFFFFF8
bnsa- cr4, 0x8
bnsa- cr4, 0xFFFFFFF8
bnsa+ cr4, 0x8
bnsa+ cr4, 0xFFFFFFF8
bnsla cr4, 0x8
bnsla cr4, 0xFFFFFFF8
bnsla- cr4, 0x8
bnsla- cr4, 0xFFFFFFF8
bnsla+ cr4, 0x8
bnsla+ cr4, 0xFFFFFFF8
bns 0x8
bns 0xFFFFFFF8
bns- 0x8
bns- 0xFFFFFFF8
bns+ 0x8
bns+ 0xFFFFFFF8
bnsl 0x8
bnsl 0xFFFFFFF8
bnsl- 0x8
bnsl- 0xFFFFFFF8
bnsl+ 0x8
bnsl+ 0xFFFFFFF8
bnsa 0x8
bnsa 0xFFFFFFF8
bnsa- 0x8
bnsa- 0xFFFFFFF8
bnsa+ 0x8
bnsa+ 0xFFFFFFF8
bnsla 0x8
bnsla 0xFFFFFFF8
bnsla- 0x8
bnsla- 0xFFFFFFF8
bnsla+ 0x8
bnsla+ 0xFFFFFFF8
bdnzt 2, 0x8
bdnzt 2, 0xFFFFFFF8
bdnzt- 2, 0x8
bdnzt- 2, 0xFFFFFFF8
bdnzt+ 2, 0x8
bdnzt+ 2, 0xFFFFFFF8
bdnztl 2, 0x8
bdnztl 2, 0xFFFFFFF8
bdnztl- 2, 0x8
bdnztl- 2, 0xFFFFFFF8
bdnztl+ 2, 0x8
bdnztl+ 2, 0xFFFFFFF8
bdnzta 2, 0x8
bdnzta 2, 0xFFFFFFF8
bdnzta- 2, 0x8
bdnzta- 2, 0xFFFFFFF8
bdnzta+ 2, 0x8
bdnzta+ 2, 0xFFFFFFF8
bdnztla 2, 0x8
bdnztla 2, 0xFFFFFFF8
bdnztla- 2, 0x8
bdnztla- 2, 0xFFFFFFF8
bdnztla+ 2, 0x8
bdnztla+ 2, 0xFFFFFFF8
bdzt 2, 0x8
bdzt 2, 0xFFFFFFF8
bdzt- 2, 0x8
bdzt- 2, 0xFFFFFFF8
bdzt+ 2, 0x8
bdzt+ 2, 0xFFFFFFF8
bdztl 2, 0x8
bdztl 2, 0xFFFFFFF8
bdztl- 2, 0x8
bdztl- 2, 0xFFFFFFF8
bdztl+ 2, 0x8
bdztl+ 2, 0xFFFFFFF8
bdzta 2, 0x8
bdzta 2, 0xFFFFFFF8
bdzta- 2, 0x8
bdzta- 2, 0xFFFFFFF8
bdzta+ 2, 0x8
bdzta+ 2, 0xFFFFFFF8
bdztla 2, 0x8
bdztla 2, 0xFFFFFFF8
bdztla- 2, 0x8
bdztla- 2, 0xFFFFFFF8
bdztla+ 2, 0x8
bdztla+ 2, 0xFFFFFFF8
blt cr4, 0x8
blt cr4, 0xFFFFFFF8
blt- cr4, 0x8
blt- cr4, 0xFFFFFFF8
blt+ cr4, 0x8
blt+ cr4, 0xFFFFFFF8
bltl cr4, 0x8
bltl cr4, 0xFFFFFFF8
bltl- cr4, 0x8
bltl- cr4, 0xFFFFFFF8
bltl+ cr4, 0x8
bltl+ cr4, 0xFFFFFFF8
blta cr4, 0x8
blta cr4, 0xFFFFFFF8
blta- cr4, 0x8
blta- cr4, 0xFFFFFFF8
blta+ cr4, 0x8
blta+ cr4, 0xFFFFFFF8
bltla cr4, 0x8
bltla cr4, 0xFFFFFFF8
bltla- cr4, 0x8
bltla- cr4, 0xFFFFFFF8
bltla+ cr4, 0x8
bltla+ cr4, 0xFFFFFFF8
blt 0x8
blt 0xFFFFFFF8
blt- 0x8
blt- 0xFFFFFFF8
blt+ 0x8
blt+ 0xFFFFFFF8
bltl 0x8
bltl 0xFFFFFFF8
bltl- 0x8
bltl- 0xFFFFFFF8
bltl+ 0x8
bltl+ 0xFFFFFFF8
blta 0x8
blta 0xFFFFFFF8
blta- 0x8
blta- 0xFFFFFFF8
blta+ 0x8
blta+ 0xFFFFFFF8
bltla 0x8
bltla 0xFFFFFFF8
bltla- 0x8
bltla- 0xFFFFFFF8
bltla+ 0x8
bltla+ 0xFFFFFFF8
bgt cr4, 0x8
bgt cr4, 0xFFFFFFF8
bgt- cr4, 0x8
bgt- cr4, 0xFFFFFFF8
bgt+ cr4, 0x8
bgt+ cr4, 0xFFFFFFF8
bgtl cr4, 0x8
bgtl cr4, 0xFFFFFFF8
bgtl- cr4, 0x8
bgtl- cr4, 0xFFFFFFF8
bgtl+ cr4, 0x8
bgtl+ cr4, 0xFFFFFFF8
bgta cr4, 0x8
bgta cr4, 0xFFFFFFF8
bgta- cr4, 0x8
bgta- cr4, 0xFFFFFFF8
bgta+ cr4, 0x8
bgta+ cr4, 0xFFFFFFF8
bgtla cr4, 0x8
bgtla cr4, 0xFFFFFFF8
bgtla- cr4, 0x8
bgtla- cr4, 0xFFFFFFF8
bgtla+ cr4, 0x8
bgtla+ cr4, 0xFFFFFFF8
bgt 0x8
bgt 0xFFFFFFF8
bgt- 0x8
bgt- 0xFFFFFFF8
bgt+ 0x8
bgt+ 0xFFFFFFF8
bgtl 0x8
bgtl 0xFFFFFFF8
bgtl- 0x8
bgtl- 0xFFFFFFF8
bgtl+ 0x8
bgtl+ 0xFFFFFFF8
bgta 0x8
bgta 0xFFFFFFF8
bgta- 0x8
bgta- 0xFFFFFFF8
bgta+ 0x8
bgta+ 0xFFFFFFF8
bgtla 0x8
bgtla 0xFFFFFFF8
bgtla- 0x8
bgtla- 0xFFFFFFF8
bgtla+ 0x8
bgtla+ 0xFFFFFFF8
beq cr4, 0x8
beq cr4, 0xFFFFFFF8
beq- cr4, 0x8
beq- cr4, 0xFFFFFFF8
beq+ cr4, 0x8
beq+ cr4, 0xFFFFFFF8
beql cr4, 0x8
beql cr4, 0xFFFFFFF8
beql- cr4, 0x8
beql- cr4, 0xFFFFFFF8
beql+ cr4, 0x8
beql+ cr4, 0xFFFFFFF8
beqa cr4, 0x8
beqa cr4, 0xFFFFFFF8
beqa- cr4, 0x8
beqa- cr4, 0xFFFFFFF8
beqa+ cr4, 0x8
beqa+ cr4, 0xFFFFFFF8
beqla cr4, 0x8
beqla cr4, 0xFFFFFFF8
beqla- cr4, 0x8
beqla- cr4, 0xFFFFFFF8
beqla+ cr4, 0x8
beqla+ cr4, 0xFFFFFFF8
beq 0x8
beq 0xFFFFFFF8
beq- 0x8
beq- 0xFFFFFFF8
beq+ 0x8
beq+ 0xFFFFFFF8
beql 0x8
beql 0xFFFFFFF8
beql- 0x8
beql- 0xFFFFFFF8
beql+ 0x8
beql+ 0xFFFFFFF8
beqa 0x8
beqa 0xFFFFFFF8
beqa- 0x8
beqa- 0xFFFFFFF8
beqa+ 0x8
beqa+ 0xFFFFFFF8
beqla 0x8
beqla 0xFFFFFFF8
beqla- 0x8
beqla- 0xFFFFFFF8
beqla+ 0x8
beqla+ 0xFFFFFFF8
bso cr4, 0x8
bso cr4, 0xFFFFFFF8
bso- cr4, 0x8
bso- cr4, 0xFFFFFFF8
bso+ cr4, 0x8
bso+ cr4, 0xFFFFFFF8
bsol cr4, 0x8
bsol cr4, 0xFFFFFFF8
bsol- cr4, 0x8
bsol- cr4, 0xFFFFFFF8
bsol+ cr4, 0x8
bsol+ cr4, 0xFFFFFFF8
bsoa cr4, 0x8
bsoa cr4, 0xFFFFFFF8
bsoa- cr4, 0x8
bsoa- cr4, 0xFFFFFFF8
bsoa+ cr4, 0x8
bsoa+ cr4, 0xFFFFFFF8
bsola cr4, 0x8
bsola cr4, 0xFFFFFFF8
bsola- cr4, 0x8
bsola- cr4, 0xFFFFFFF8
bsola+ cr4, 0x8
bsola+ cr4, 0xFFFFFFF8
bso 0x8
bso 0xFFFFFFF8
bso- 0x8
bso- 0xFFFFFFF8
bso+ 0x8
bso+ 0xFFFFFFF8
bsol 0x8
bsol 0xFFFFFFF8
bsol- 0x8
bsol- 0xFFFFFFF8
bsol+ 0x8
bsol+ 0xFFFFFFF8
bsoa 0x8
bsoa 0xFFFFFFF8
bsoa- 0x8
bsoa- 0xFFFFFFF8
bsoa+ 0x8
bsoa+ 0xFFFFFFF8
bsola 0x8
bsola 0xFFFFFFF8
bsola- 0x8
bsola- 0xFFFFFFF8
bsola+ 0x8
bsola+ 0xFFFFFFF8
bdnz 0x8
bdnz 0xFFFFFFF8
bdnz- 0x8
bdnz- 0xFFFFFFF8
bdnz+ 0x8
bdnz+ 0xFFFFFFF8
bdnzl 0x8
bdnzl 0xFFFFFFF8
bdnzl- 0x8
bdnzl- 0xFFFFFFF8
bdnzl+ 0x8
bdnzl+ 0xFFFFFFF8
bdnza 0x8
bdnza 0xFFFFFFF8
bdnza- 0x8
bdnza- 0xFFFFFFF8
bdnza+ 0x8
bdnza+ 0xFFFFFFF8
bdnzla 0x8
bdnzla 0xFFFFFFF8
bdnzla- 0x8
bdnzla- 0xFFFFFFF8
bdnzla+ 0x8
bdnzla+ 0xFFFFFFF8
bdz 0x8
bdz 0xFFFFFFF8
bdz- 0x8
bdz- 0xFFFFFFF8
bdz+ 0x8
bdz+ 0xFFFFFFF8
bdzl 0x8
bdzl 0xFFFFFFF8
bdzl- 0x8
bdzl- 0xFFFFFFF8
bdzl+ 0x8
bdzl+ 0xFFFFFFF8
bdza 0x8
bdza 0xFFFFFFF8
bdza- 0x8
bdza- 0xFFFFFFF8
bdza+ 0x8
bdza+ 0xFFFFFFF8
bdzla 0x8
bdzla 0xFFFFFFF8
bdzla- 0x8
bdzla- 0xFFFFFFF8
bdzla+ 0x8
bdzla+ 0xFFFFFFF8
bcctr 12, 2
bcctrl 12, 2
bctr
bctrl
bgectr cr4
bgectr- cr4
bgectr+ cr4
bgectrl cr4
bgectrl- cr4
bgectrl+ cr4
bgectr
bgectr-
bgectr+
bgectrl
bgectrl-
bgectrl+
blectr cr4
blectr- cr4
blectr+ cr4
blectrl cr4
blectrl- cr4
blectrl+ cr4
blectr
blectr-
blectr+
blectrl
blectrl-
blectrl+
bnectr cr4
bnectr- cr4
bnectr+ cr4
bnectrl cr4
bnectrl- cr4
bnectrl+ cr4
bnectr
bnectr-
bnectr+
bnectrl
bnectrl-
bnectrl+
bnsctr cr4
bnsctr- cr4
bnsctr+ cr4
bnsctrl cr4
bnsctrl- cr4
bnsctrl+ cr4
bnsctr
bnsctr-
bnsctr+
bnsctrl
bnsctrl-
bnsctrl+
bltctr cr4
bltctr- cr4
bltctr+ cr4
bltctrl cr4
bltctrl- cr4
bltctrl+ cr4
bltctr
bltctr-
bltctr+
bltctrl
bltctrl-
bltctrl+
bgtctr cr4
bgtctr- cr4
bgtctr+ cr4
bgtctrl cr4
bgtctrl- cr4
bgtctrl+ cr4
bgtctr
bgtctr-
bgtctr+
bgtctrl
bgtctrl-
bgtctrl+
beqctr cr4
beqctr- cr4
beqctr+ cr4
beqctrl cr4
beqctrl- cr4
beqctrl+ cr4
beqctr
beqctr-
beqctr+
beqctrl
beqctrl-
beqctrl+
bsoctr cr4
bsoctr- cr4
bsoctr+ cr4
bsoctrl cr4
bsoctrl- cr4
bsoctrl+ cr4
bsoctr
bsoctr-
bsoctr+
bsoctrl
bsoctrl-
bsoctrl+
bclr 12, 2
bclrl 12, 2
blr
blrl
bdnzflr 2
bdnzflr- 2
bdnzflr+ 2
bdnzflrl 2
bdnzflrl- 2
bdnzflrl+ 2
bdzflr 2
bdzflr- 2
bdzflr+ 2
bdzflrl 2
bdzflrl- 2
bdzflrl+ 2
bgelr cr4
bgelr- cr4
bgelr+ cr4
bgelrl cr4
bgelrl- cr4
bgelrl+ cr4
bgelr
bgelr-
bgelr+
bgelrl
bgelrl-
bgelrl+
blelr cr4
blelr- cr4
blelr+ cr4
blelrl cr4
blelrl- cr4
blelrl+ cr4
blelr
blelr-
blelr+
blelrl
blelrl-
blelrl+
bnelr cr4
bnelr- cr4
bnelr+ cr4
bnelrl cr4
bnelrl- cr4
bnelrl+ cr4
bnelr
bnelr-
bnelr+
bnelrl
bnelrl-
bnelrl+
bnslr cr4
bnslr- cr4
bnslr+ cr4
bnslrl cr4
bnslrl- cr4
bnslrl+ cr4
bnslr
bnslr-
bnslr+
bnslrl
bnslrl-
bnslrl+
bdnztlr 2
bdnztlr- 2
bdnztlr+ 2
bdnztlrl 2
bdnztlrl- 2
bdnztlrl+ 2
bdztlr 2
bdztlr- 2
bdztlr+ 2
bdztlrl 2
bdztlrl- 2
bdztlrl+ 2
bltlr cr4
bltlr- cr4
bltlr+ cr4
bltlrl cr4
bltlrl- cr4
bltlrl+ cr4
bltlr
bltlr-
bltlr+
bltlrl
bltlrl-
bltlrl+
bgtlr cr4
bgtlr- cr4
bgtlr+ cr4
bgtlrl cr4
bgtlrl- cr4
bgtlrl+ cr4
bgtlr
bgtlr-
bgtlr+
bgtlrl
bgtlrl-
bgtlrl+
beqlr cr4
beqlr- cr4
beqlr+ cr4
beqlrl cr4
beqlrl- cr4
beqlrl+ cr4
beqlr
beqlr-
beqlr+
beqlrl
beqlrl-
beqlrl+
bsolr cr4
bsolr- cr4
bsolr+ cr4
bsolrl cr4
bsolrl- cr4
bsolrl+ cr4
bsolr
bsolr-
bsolr+
bsolrl
bsolrl-
bsolrl+
bdnzlr
bdnzlr-
bdnzlr+
bdnzlrl
bdnzlrl-
bdnzlrl+
bdzlr
bdzlr-
bdzlr+
bdzlrl
bdzlrl-
bdzlrl+
cmp cr4, 0, r5, r15
cmpw cr4, r5, r15
cmpw r5, r15
cmpi cr4, 0, r5, 0x8
cmpi cr4, 0, r5, 0xFFFFFFF8
cmpwi cr4, r5, 0x8
cmpwi cr4, r5, 0xFFFFFFF8
cmpwi r5, 0x8
cmpwi r5, 0xFFFFFFF8
cmpl cr4, 0, r5, r15
cmplw cr4, r5, r15
cmplw r5, r15
cmpli cr4, 0, r5, 0x8
cmpli cr4, 0, r5, 0xFFF8
cmplwi cr4, r5, 0x8
cmplwi cr4, r5, 0xFFF8
cmplwi r5, 0x8
cmplwi r5, 0xFFF8
cntlzw r5, r15
cntlzw. r5, r15
crand 5, 15, 25
crandc 5, 15, 25
creqv 5, 15, 25
crset 5
crnand 5, 15, 25
crnor 5, 15, 25
crnot 5, 15
cror 5, 15, 25
crmove 5, 15
crorc 5, 15, 25
crxor 5, 15, 25
crclr 5
dcbf r5, r15
dcbi r5, r15
dcbst r5, r15
dcbt r5, r15
dcbtst r5, r15
dcbz r5, r15
dcbz_l r5, r15
divw r5, r15, r25
divw. r5, r15, r25
divwo r5, r15, r25
divwo. r5, r15, r25
divwu r5, r15, r25
divwu. r5, r15, r25
divwuo r5, r15, r25
divwuo. r5, r15, r25
eciwx r5, r15, r25
ecowx r5, r15, r25
eieio
eqv r5, r15, r25
eqv. r5, r15, r25
extsb r5, r15
extsb. r5, r15
extsh r5, r15
extsh. r5, r15
fabs f5, f15
fabs. f5, f15
fadd f5, f15, f25
fadd. f5, f15, f25
fadds f5, f15, f25
fadds. f5, f15, f25
fcmpo cr4, f5, f15
fcmpu cr4, f5, f15
fctiw f5, f15
fctiw. f5, f15
fctiwz f5, f15
fctiwz. f5, f15
fdiv f5, f15, f25
fdiv. f5, f15, f25
fdivs f5, f15, f25
fdivs. f5, f15, f25
fmadd f5, f15, f25, f9
fmadd. f5, f15, f25, f9
fmadds f5, f15, f25, f9
fmadds. f5, f15, f25, f9
fmr f5, f15
fmr. f5, f15
fmsub f5, f15, f25, f9
fmsub. f5, f15, f25, f9
fmsubs f5, f15, f25, f9
fmsubs. f5, f15, f25, f9
fmul f5, f15, f25
fmul. f5, f15, f25
fmuls f5, f15, f25
fmuls. f5, f15, f25
fnabs f5, f15
fnabs. f5, f15
fneg f5, f15
fneg. f5, f15
fnmadd f5, f15, f25, f9
fnmadd. f5, f15, f25, f9
fnmadds f5, f15, f25, f9
fnmadds. f5, f15, f25, f9
fnmsub f5, f15, f25, f9
fnmsub. f5, f15, f25, f9
fnmsubs f5, f15, f25, f9
fnmsubs. f5, f15, f25, f9
fres f5, f15
fres. f5, f15
frsp f5, f15
frsp. f5, f15
frsqrte f5, f15
frsqrte. f5, f15
fsel f5, f15, f25, f9
fsel. f5, f15, f25, f9
fsub f5, f15, f25
fsub. f5, f15, f25
fsubs f5, f15, f25
fsubs. f5, f15, f25
icbi r5, r15
isync
lbz r5, 0x7777 (r15)
lbz r5, 0xFFFF9999 (r15)
lbzu r5, 0x7777 (r15)
lbzu r5, 0xFFFF9999 (r15)
lbzux r5, r15, r25
lbzx r5, r15, r25
lfd f5, 0x7777 (r15)
lfd f5, 0xFFFF9999 (r15)
lfdu f5, 0x7777 (r15)
lfdu f5, 0xFFFF9999 (r15)
lfdux f5, r15, r25
lfdx f5, r15, r25
lfs f5, 0x7777 (r15)
lfs f5, 0xFFFF9999 (r15)
lfsu f5, 0x7777 (r15)
lfsu f5, 0xFFFF9999 (r15)
lfsux f5, r15, r25
lfsx f5, r15, r25
lha r5, 0x7777 (r15)
lha r5, 0xFFFF9999 (r15)
lhau r5, 0x7777 (r15)
lhau r5, 0xFFFF9999 (r15)
lhaux r5, r15, r25
lhax r5, r15, r25
lhbrx r5, r15, r25
lhz r5, 0x7777 (r15)
lhz r5, 0xFFFF9999 (r15)
lhzu r5, 0x7777 (r15)
lhzu r5, 0xFFFF9999 (r15)
lhzux r5, r15, r25
lhzx r5, r15, r25
lmw r15, 0x7777 (r5)
lmw r15, 0xFFFF9999 (r5)
lswi r5, r15, 4
lswx r5, r15, r25
lwarx r5, r15, r25
lwbrx r5, r15, r25
lwz r5, 0x7777 (r15)
lwz r5, 0xFFFF9999 (r15)
lwzu r5, 0x7777 (r15)
lwzu r5, 0xFFFF9999 (r15)
lwzux r5, r15, r25
lwzx r5, r15, r25
mcrf cr4, cr6
mcrfs cr4, cr6
mcrxr cr4
mfcr r5
mffs f5
mffs. f5
mfmsr r5
mfspr r5, 18
mfxer r5
mflr r5
mfctr r5
mfsr r5, 15
mfsrin r5, r15
mftb r5, 269
mftb r5
mftbu r5
mtcrf 0x10, r5
mtcr r5
mtfsb0 5
mtfsb0. 5
mtfsb1 5
mtfsb1. 5
mtfsf 0x11, f5
mtfsf. 0x11, f5
mtfsfi cr5, 7
mtfsfi. cr5, 7
mtmsr r5
mtspr 18, r5
mtxer r5
mtlr r5
mtctr r5
mtsr 15, r5
mtsrin r5, r15
mulhw r5, r15, r15
mulhw. r5, r15, r15
mulhwu r5, r15, r15
mulhwu. r5, r15, r15
mulli r5, r15, 0x7777
mulli r5, r15, 0xFFFF9999
mullw r5, r15, r25
mullw. r5, r15, r25
mullwo r5, r15, r25
mullwo. r5, r15, r25
nand r5, r15, r25
nand. r5, r15, r25
neg r5, r15
neg. r5, r15
nego r5, r15
nego. r5, r15
nor r5, r15, r25
nor. r5, r15, r25
not r5, r15
not. r5, r15
or r5, r15, r25
or. r5, r15, r25
mr r5, r15
mr. r5, r15
orc r5, r15, r25
orc. r5, r15, r25
ori r5, r15, 0xDDDD
nop
oris r5, r15, 0xDDDD
psq_l f5, 0x777 (r15), 1, 2
psq_l f5, 0xFFFFF999 (r15), 1, 2
psq_lu f5, 0x777 (r15), 1, 2
psq_lu f5, 0xFFFFF999 (r15), 1, 2
psq_lux f5, r15, r25, 1, 2
psq_lx f5, r15, r25, 1, 2
psq_st f5, 0x777 (r15), 1, 2
psq_st f5, 0xFFFFF999 (r15), 1, 2
psq_stu f5, 0x777 (r15), 1, 2
psq_stu f5, 0xFFFFF999 (r15), 1, 2
psq_stux f5, r15, r25, 1, 2
psq_stx f5, r15, r25, 1, 2
ps_abs f5, f15
ps_abs. f5, f15
ps_add f5, f15, f25
ps_add. f5, f15, f25
ps_cmpo0 cr4, f5, f15
ps_cmpo1 cr4, f5, f15
ps_cmpu0 cr4, f5, f15
ps_cmpu1 cr4, f5, f15
ps_div f5, f15, f25
ps_div. f5, f15, f25
ps_madd f5, f15, f25, f9
ps_madd. f5, f15, f25, f9
ps_madds0 f5, f15, f25, f9
ps_madds0. f5, f15, f25, f9
ps_madds1 f5, f15, f25, f9
ps_madds1. f5, f15, f25, f9
ps_merge00 f5, f15, f25
ps_merge00. f5, f15, f25
ps_merge01 f5, f15, f25
ps_merge01. f5, f15, f25
ps_merge10 f5, f15, f25
ps_merge10. f5, f15, f25
ps_merge11 f5, f15, f25
ps_merge11. f5, f15, f25
ps_mr f5, f15
ps_mr. f5, f15
ps_msub f5, f15, f25, f9
ps_msub. f5, f15, f25, f9
ps_mul f5, f15, f25
ps_mul. f5, f15, f25
ps_muls0 f5, f15, f25
ps_muls0. f5, f15, f25
ps_muls1 f5, f15, f25
ps_muls1. f5, f15, f25
ps_nabs f5, f15
ps_nabs. f5, f15
ps_neg f5, f15
ps_neg. f5, f15
ps_nmadd f5, f15, f25, f9
ps_nmadd. f5, f15, f25, f9
ps_nmsub f5, f15, f25, f9
ps_nmsub. f5, f15, f25, f9
ps_res f5, f15
ps_res. f5, f15
ps_rsqrte f5, f15
ps_rsqrte. f5, f15
ps_sel f5, f15, f25, f9 #NOTE Codewrite doesn't assemble ps_sel instructions correctly
ps_sel. f5, f15, f25, f9 #NOTE Codewrite doesn't assemble ps_sel instructions correctly
ps_sub f5, f15, f25
ps_sub. f5, f15, f25
ps_sum0 f5, f15, f25, f9
ps_sum0. f5, f15, f25, f9
ps_sum1 f5, f15, f25, f9
ps_sum1. f5, f15, f25, f9
rfi
rlwimi r5, r15, 25, 10, 20
rlwimi. r5, r15, 25, 10, 20
rlwinm r5, r15, 25, 10, 20
rlwinm. r5, r15, 25, 10, 20
rotlwi r5, r15, 25
rotlwi. r5, r15, 25
slwi r5, r15, 25
slwi. r5, r15, 25
srwi r5, r15, 25
srwi. r5, r15, 25
clrlwi r5, r15, 25
clrlwi. r5, r15, 25
clrrwi r5, r15, 25
clrrwi. r5, r15, 25
rlwnm r5, r15, r25, 10, 20
rlwnm. r5, r15, r25, 10, 20
rotlw r5, r15, r25
rotlw. r5, r15, r25
sc
slw r5, r15, r25
slw. r5, r15, r25
sraw r5, r15, r25
sraw. r5, r15, r25
srawi r5, r15, 25
srawi. r5, r15, 25
srw r5, r15, r25
srw. r5, r15, r25
stb r5, 0x7777 (r15)
stb r5, 0xFFFF9999 (r15)
stbu r5, 0x7777 (r15)
stbu r5, 0xFFFF9999 (r15)
stbux r5, r15, r25
stbx r5, r15, r25
stfd f5, 0x7777 (r15)
stfd f5, 0xFFFF9999 (r15)
stfdu f5, 0x7777 (r15)
stfdu f5, 0xFFFF9999 (r15)
stfdux f5, r15, r25
stfdx f5, r15, r25
stfiwx f5, r15, r25
stfs f5, 0x7777 (r15)
stfs f5, 0xFFFF9999 (r15)
stfsu f5, 0x7777 (r15)
stfsu f5, 0xFFFF9999 (r15)
stfsux f5, r15, r25
stfsx f5, r15, r25
sth r5, 0x7777 (r15)
sth r5, 0xFFFF9999 (r15)
sthbrx r5, r15, r25
sthu r5, 0x7777 (r15)
sthu r5, 0xFFFF9999 (r15)
sthux r5, r15, r25
sthx r5, r15, r25
stmw r5, 0x7777 (r15)
stmw r5, 0xFFFF9999 (r15)
stswi r5, r15, 4
stswx r5, r15, r25
stw r5, 0x7777 (r15)
stw r5, 0xFFFF9999 (r15)
stwbrx r5, r15, r25
stwcx. r5, r15, r25
stwu r5, 0x7777 (r15)
stwu r5, 0xFFFF9999 (r15)
stwux r5, r15, r25
stwx r5, r15, r25
subf r5, r15, r25
subf. r5, r15, r25
subfo r5, r15, r25
subfo. r5, r15, r25
sub r5, r15, r25
sub. r5, r15, r25
subo r5, r15, r25
subo. r5, r15, r25
subfc r5, r15, r25
subfc. r5, r15, r25
subfco r5, r15, r25
subfco. r5, r15, r25
subc r5, r15, r25
subc. r5, r15, r25
subco r5, r15, r25
subco. r5, r15, r25
subfe r5, r15, r25
subfe. r5, r15, r25
subfeo r5, r15, r25
subfeo. r5, r15, r25
subfic r5, r15, 0x7777
subfic r5, r15, 0xFFFF9999
subfme r5, r15
subfme. r5, r15
subfmeo r5, r15
subfmeo. r5, r15
subfze r5, r15
subfze. r5, r15
subfzeo r5, r15
subfzeo. r5, r15
sync
tlbie r5
tlbsync
tw 5, r15, r25
trap
twi 5, r15, 0x7777
twi 5, r15, 0xFFFF9999
xor r5, r15, r25
xor. r5, r15, r25
xori r5, r15, 0xDDDD
xoris r5, r15, 0xDDDD
.long 0x01234567
