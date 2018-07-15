;	AUTO-GENERATED SYMBOL LIST

########################################################################

	_alignToCacheBlock
IntFPUnavail
;	Reload the FPU

	mfsprg	r1, 0
	stw		r11, KDP.FloatingPtTemp1(r1)
	lwz		r11, KDP.NKInfo.FPUReloadCount(r1)
	stw		r6, KDP.FloatingPtTemp2(r1)
	addi	r11, r11, 1
	stw		r11, KDP.NKInfo.FPUReloadCount(r1)

	mfsrr1	r11
	_bset	r11, r11, bitMsrFP
	mtsrr1	r11

	mfmsr	r11				; need this to access float registers
	_bset	r11, r11, bitMsrFP
	lwz		r6, KDP.CurCBPtr(r1)
	mtmsr	r11

	bl		LoadFloats

	lwz		r11, KDP.FloatingPtTemp1(r1)
	lwz		r6, KDP.FloatingPtTemp2(r1)

	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1

	rfi

########################################################################

EnableFPU
	rlwinm.	r8, r11, 0, 18, 18
	bnelr

ReloadFPU
	lwz		r8, 0xe4(r6)			; ???
	rlwinm.	r8, r8, 1, 0, 0

	mfmsr	r8
	_bset	r8, r8, bitMsrFP
	beqlr
	mtmsr	r8

	_bset	r11, r11, bitMsrFP

########################################################################

LoadFloats
	lfd		f31, 0xe0(r6)
	lfd		f0, 0x200(r6)
	lfd		f1, 0x208(r6)
	lfd		f2, 0x210(r6)
	lfd		f3, 0x218(r6)
	lfd		f4, 0x220(r6)
	lfd		f5, 0x228(r6)
	lfd		f6, 0x230(r6)
	lfd		f7, 0x238(r6)
	mtfsf	0xff, f31
	lfd		f8, 0x240(r6)
	lfd		f9, 0x248(r6)
	lfd		f10, 0x250(r6)
	lfd		f11, 0x258(r6)
	lfd		f12, 0x260(r6)
	lfd		f13, 0x268(r6)
	lfd		f14, 0x270(r6)
	lfd		f15, 0x278(r6)
	lfd		f16, 0x280(r6)
	lfd		f17, 0x288(r6)
	lfd		f18, 0x290(r6)
	lfd		f19, 0x298(r6)
	lfd		f20, 0x2a0(r6)
	lfd		f21, 0x2a8(r6)
	lfd		f22, 0x2b0(r6)
	lfd		f23, 0x2b8(r6)
	lfd		f24, 0x2c0(r6)
	lfd		f25, 0x2c8(r6)
	lfd		f26, 0x2d0(r6)
	lfd		f27, 0x2d8(r6)
	lfd		f28, 0x2e0(r6)
	lfd		f29, 0x2e8(r6)
	lfd		f30, 0x2f0(r6)
	lfd		f31, 0x2f8(r6)

	blr

########################################################################

DisableFPU
	mfmsr	r8
	_bset	r8, r8, bitMsrFP
	mtmsr	r8

	_bclr	r11, r11, bitMsrFP

	stfd	f0, 0x200(r6)
	stfd	f1, 0x208(r6)
	stfd	f2, 0x210(r6)
	stfd	f3, 0x218(r6)
	stfd	f4, 0x220(r6)
	stfd	f5, 0x228(r6)
	stfd	f6, 0x230(r6)
	stfd	f7, 0x238(r6)
	stfd	f8, 0x240(r6)
	stfd	f9, 0x248(r6)
	stfd	f10, 0x250(r6)
	stfd	f11, 0x258(r6)
	stfd	f12, 0x260(r6)
	stfd	f13, 0x268(r6)
	stfd	f14, 0x270(r6)
	stfd	f15, 0x278(r6)
	stfd	f16, 0x280(r6)
	stfd	f17, 0x288(r6)
	stfd	f18, 0x290(r6)
	stfd	f19, 0x298(r6)
	stfd	f20, 0x2a0(r6)
	stfd	f21, 0x2a8(r6)
	stfd	f22, 0x2b0(r6)
	stfd	f23, 0x2b8(r6)
	mffs	f0
	stfd	f24, 0x2c0(r6)
	stfd	f25, 0x2c8(r6)
	stfd	f26, 0x2d0(r6)
	stfd	f27, 0x2d8(r6)
	stfd	f28, 0x2e0(r6)
	stfd	f29, 0x2e8(r6)
	stfd	f30, 0x2f0(r6)
	stfd	f31, 0x2f8(r6)
	stfd	f0, 0xe0(r6)

	blr

########################################################################

;	This is used by MemRetry

	MACRO
	MakeFloatJumpTable &OPCODE, &DEST, &highest==31
	if &highest > 0
		MakeFloatJumpTable &OPCODE, &DEST, highest = (&highest) - 1
	endif
	&OPCODE	&highest, KDP.FloatEmScratch(r1)
	b		&DEST
	ENDM

FloatLoadJumpTable
	MakeFloatJumpTable	lfd, FDP_0da0
FloatSaveJumpTable
	MakeFloatJumpTable	stfd, FDP_003c
