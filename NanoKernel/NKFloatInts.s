;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKTranslation
;	    FDP_003c
;	    FDP_0DA0
;	EXPORTS:
;	  FloatLoadJumpTable (=> NKTranslation)
;	  FloatSaveJumpTable (=> NKTranslation)
;	  IntFPUnavail (=> NKInit)
;	  IntHandleSpecialFPException (=> NKExceptions, NKRTASCalls)
;	  bugger_around_with_floats (=> NKExceptions, NKRTASCalls)
;	  major_0x03e18 (=> NKIntHandlers)



###              ####### ######  #     #                                      
 #  #    # ##### #       #     # #     # #    #   ##   #    #   ##   # #      
 #  ##   #   #   #       #     # #     # ##   #  #  #  #    #  #  #  # #      
 #  # #  #   #   #####   ######  #     # # #  # #    # #    # #    # # #      
 #  #  # #   #   #       #       #     # #  # # ###### #    # ###### # #      
 #  #   ##   #   #       #       #     # #   ## #    #  #  #  #    # # #      
### #    #   #   #       #        #####  #    # #    #   ##   #    # # ###### 

	align	kIntAlign

IntFPUnavail	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stw		r11, -0x0290(r1)
	stw		r6, -0x028c(r1)
	lwz		r6, -0x0004(r1)
	lwz		r11,  0x0e88(r6)
	addi	r11, r11,  0x01
	stw		r11,  0x0e88(r6)
	mfspr	r11, srr1
	ori		r11, r11,  0x2000
	mtspr	srr1, r11
	mfmsr	r11
	ori		r11, r11,  0x2000
	lwz		r6, -0x0014(r1)
	mtmsr	r11
	isync
	bl		LoadFloatsFromContextBlock
	lwz		r11, -0x0290(r1)
	lwz		r6, -0x028c(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




major_0x03e18	;	OUTSIDE REFERER
	rlwinm.	r8, r11,  0, 18, 18
	bnelr

IntHandleSpecialFPException	;	OUTSIDE REFERER
	lwz		r8,  0x00e4(r6)
	rlwinm.	r8, r8,  1,  0,  0
	mfmsr	r8
	ori		r8, r8,  0x2000
	beqlr
	mtmsr	r8
	isync
	ori		r11, r11,  0x2000

LoadFloatsFromContextBlock	;	OUTSIDE REFERER
	lfd		f31,  0x00e0(r6)
	lfd		f0,  0x0200(r6)
	lfd		f1,  0x0208(r6)
	lfd		f2,  0x0210(r6)
	lfd		f3,  0x0218(r6)
	lfd		f4,  0x0220(r6)
	lfd		f5,  0x0228(r6)
	lfd		f6,  0x0230(r6)
	lfd		f7,  0x0238(r6)
	mtfsf	 0xff, f31
	lfd		f8,  0x0240(r6)
	lfd		f9,  0x0248(r6)
	lfd		f10,  0x0250(r6)
	lfd		f11,  0x0258(r6)
	lfd		f12,  0x0260(r6)
	lfd		f13,  0x0268(r6)
	lfd		f14,  0x0270(r6)
	lfd		f15,  0x0278(r6)
	lfd		f16,  0x0280(r6)
	lfd		f17,  0x0288(r6)
	lfd		f18,  0x0290(r6)
	lfd		f19,  0x0298(r6)
	lfd		f20,  0x02a0(r6)
	lfd		f21,  0x02a8(r6)
	lfd		f22,  0x02b0(r6)
	lfd		f23,  0x02b8(r6)
	lfd		f24,  0x02c0(r6)
	lfd		f25,  0x02c8(r6)
	lfd		f26,  0x02d0(r6)
	lfd		f27,  0x02d8(r6)
	lfd		f28,  0x02e0(r6)
	lfd		f29,  0x02e8(r6)
	lfd		f30,  0x02f0(r6)
	lfd		f31,  0x02f8(r6)
	blr





bugger_around_with_floats	;	OUTSIDE REFERER
	mfmsr	r8
	ori		r8, r8,  0x2000
	mtmsr	r8
	isync
	_bclr	r11, r11, 18
	stfd	f0,  0x0200(r6)
	stfd	f1,  0x0208(r6)
	stfd	f2,  0x0210(r6)
	stfd	f3,  0x0218(r6)
	stfd	f4,  0x0220(r6)
	stfd	f5,  0x0228(r6)
	stfd	f6,  0x0230(r6)
	stfd	f7,  0x0238(r6)
	stfd	f8,  0x0240(r6)
	stfd	f9,  0x0248(r6)
	stfd	f10,  0x0250(r6)
	stfd	f11,  0x0258(r6)
	stfd	f12,  0x0260(r6)
	stfd	f13,  0x0268(r6)
	stfd	f14,  0x0270(r6)
	stfd	f15,  0x0278(r6)
	stfd	f16,  0x0280(r6)
	stfd	f17,  0x0288(r6)
	stfd	f18,  0x0290(r6)
	stfd	f19,  0x0298(r6)
	stfd	f20,  0x02a0(r6)
	stfd	f21,  0x02a8(r6)
	stfd	f22,  0x02b0(r6)
	stfd	f23,  0x02b8(r6)
	mffs	f0
	stfd	f24,  0x02c0(r6)
	stfd	f25,  0x02c8(r6)
	stfd	f26,  0x02d0(r6)
	stfd	f27,  0x02d8(r6)
	stfd	f28,  0x02e0(r6)
	stfd	f29,  0x02e8(r6)
	stfd	f30,  0x02f0(r6)
	stfd	f31,  0x02f8(r6)
	stfd	f0,  0x00e0(r6)
	blr




;	indexed emulation code, mofo

;two instructions per load-store register

	macro
	CreateFloatJumpTable	&opcode, &dest, &highest==31

	if		&highest > 0
		CreateFloatJumpTable	&opcode, &dest, highest = (&highest) - 1
	endif

	&opcode		(&highest), -0x2e0(r1)
	b			&dest

	endm


FloatLoadJumpTable
	CreateFloatJumpTable	lfd, FDP_0da0


FloatSaveJumpTable
	CreateFloatJumpTable	stfd, FDP_003c
