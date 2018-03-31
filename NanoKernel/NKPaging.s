Local_Panic		set		*
				b		panic



	align	5

PagingFunc1	;	OUTSIDE REFERER
	mfsprg	r29, 0
	mflr	r28
	stw		r8, -0x00dc(r29)
	mfcr	r8
	stw		r9, -0x00d8(r29)
	stw		r8, -0x00a4(r29)
	stw		r14, -0x00d4(r29)
	stw		r15, -0x00d0(r29)
	stw		r16, -0x00cc(r29)
	stw		r17, -0x00c8(r29)
	stw		r18, -0x00c4(r29)
	stw		r19, -0x00c0(r29)
	stw		r20, -0x00bc(r29)
	stw		r21, -0x00b8(r29)
	stw		r22, -0x00b4(r29)
	stw		r28, -0x00e0(r29)
	b		@_88

@_44
	mfsprg	r29, 0
	lwz		r8, -0x00a4(r29)
	lwz		r28, -0x00e0(r29)
	mtcrf	 0x7f, r8
	lwz		r8, -0x00dc(r29)
	mtlr	r28
	lwz		r9, -0x00d8(r29)
	lwz		r14, -0x00d4(r29)
	lwz		r15, -0x00d0(r29)
	lwz		r16, -0x00cc(r29)
	lwz		r17, -0x00c8(r29)
	lwz		r18, -0x00c4(r29)
	lwz		r19, -0x00c0(r29)
	lwz		r20, -0x00bc(r29)
	lwz		r21, -0x00b8(r29)
	lwz		r22, -0x00b4(r29)
	blr

@_88
	mfsprg	r30, 0
	mr		r9, r27
	lwz		r8, -0x001c(r30)
	bl		FindAreaAbove
	mr		r31, r8
	stw		r8, EWA.SpecialAreaPtr(r30)
	stw		r27, -0x00e8(r30)
	lwz		r16,  0x0024(r31)
	lwz		r17,  0x0020(r31)
	cmplw	r16, r27
	lwz		r18,  0x007c(r31)
	bgt		@_1a0
	bgt		@_44
	and		r28, r27, r18
	rlwinm.	r26, r17,  0, 16, 16
	lwz		r17,  0x0038(r31)
	beq		@_fc
	lwz		r18,  0x0070(r31)
	subf	r19, r16, r28
	clrlwi	r31, r18,  0x1e
	cmpwi	cr7, r17, -0x01
	cmpwi	cr6, r31,  0x00
	beq		cr7, @_1a0
	beq		cr6, @_44
	cmpwi	r17,  0x01
	add		r31, r18, r19
	blt		@_44
	li		r26,  0x00
	b		@_208

@_fc
	mr		r8, r27
	bl		MPCall_95_0x1e4
	lwz		r28,  0x0000(r30)
	mr		r26, r30
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		@_12c
	lhz		r16,  0x0000(r30)
	rlwinm.	r8, r16,  0, 16, 16
	bne		@_12c
	srwi	r16, r16,  1
	sth		r16,  0x0000(r30)

@_12c
	lwz		r8,  0x0024(r31)
	lwz		r9,  0x06b4(r1)
	cmpwi	r8,  0x00
	cmpwi	cr6, r9,  0x00
	li		r8,  0x801
	li		r9,  0x01
	bne		@_154
	beq		cr6, @_154
	li		r8,  0x881
	li		r9,  0x81

@_154
	lwz		r31,  0x0688(r1)
	and.	r30, r28, r8
	rlwimi	r31, r28,  0,  0, 19
	cmplwi	cr6, r30,  0x800
	cmplwi	r30,  0x01
	bge		cr6, @_2ec
	cmplw	cr7, r30, r9
	ori		r31, r31,  0x100
	rlwimi	r31, r28, 28, 28, 28
	rlwimi	r31, r28,  3, 24, 24
	rlwimi	r31, r28, 31, 26, 26
	rlwimi	r31, r28,  1, 25, 25
	xori	r31, r31,  0x40
	rlwimi	r31, r28, 30, 31, 31
	rlwimi	r31, r28,  0, 30, 30
	xori	r31, r31,  0x02
	beq		@_208
	blt		cr7, @_44
	bl		Local_Panic

@_1a0
	lwz		r29,  0x05e8(r1)
	rlwinm	r28, r27,  7, 25, 28
	lwzx	r29, r29, r28
	rlwinm	r28, r27, 20, 16, 31
	lhz		r30,  0x0000(r29)
	b		@_1bc

@_1b8
	lhzu	r30,  0x0008(r29)

@_1bc
	lhz		r31,  0x0002(r29)
	subf	r30, r30, r28
	cmplw	cr7, r30, r31
	bgt		cr7, @_1b8
	lwz		r28,  0x0690(r1)
	lwz		r31,  0x0004(r29)
	cmpwi	cr7, r28,  0x00
	bnel	cr7, @_314
	rlwinm.	r26, r31, 23, 29, 30
	cmplwi	cr7, r26,  0x06
	beq		@_200
	cmplwi	cr6, r26,  0x02
	beq		cr7, @_368
	beq		cr6, @_3b8
	b		@_44
	dc.l	0x41800168
	dc.l	0x418101bc

@_200
	slwi	r28, r30, 12
	add		r31, r31, r28

@_208
	mfsrin	r30, r27
	rlwinm	r28, r27, 26, 10, 25
	rlwinm	r30, r30,  6,  7, 25
	xor		r28, r28, r30
	lwz		r30, KDP.PTEGMask(r1)
	lwz		r29, KDP.HTABORG(r1)
	and		r28, r28, r30
	or.		r29, r29, r28

@_228
	lwz		r30,  0x0000(r29)
	lwz		r28,  0x0008(r29)
	cmpwi	cr6, r30,  0x00
	lwz		r30,  0x0010(r29)
	cmpwi	cr7, r28,  0x00
	lwzu	r28,  0x0018(r29)
	bge		cr6, @_298
	cmpwi	cr6, r30,  0x00
	lwzu	r30,  0x0008(r29)
	bge		cr7, @_298
	cmpwi	cr7, r28,  0x00
	lwzu	r28,  0x0008(r29)
	bge		cr6, @_298
	cmpwi	cr6, r30,  0x00
	lwzu	r30,  0x0008(r29)
	bge		cr7, @_298
	cmpwi	cr7, r28,  0x00
	lwzu	r28,  0x0008(r29)
	bge		cr6, @_298
	cmpwi	cr6, r30,  0x00
	addi	r29, r29,  0x08
	bge		cr7, @_298
	cmpwi	cr7, r28,  0x00
	addi	r29, r29,  0x08
	bge		cr6, @_298
	rlwinm	r28, r31,  0, 26, 26
	addi	r29, r29,  0x08
	blt		cr7, @_3e0

@_298
	cmpwi	r26,  0x00
	mfsrin	r28, r27
	rlwinm	r30, r27, 10, 26, 31
	stw		r27,  0x0694(r1)
	oris	r30, r30,  0x8000
	ori		r31, r31,  0x100
	rlwimi	r30, r31, 27, 25, 25
	rlwinm	r31, r31,  0, 21, 19
	rlwimi	r30, r28,  7,  1, 24
	stw		r31, -0x0014(r29)
	eieio
	stwu	r30, -0x0018(r29)
	sync
	lwz		r28,  0x0e94(r1)
	stw		r29,  0x0698(r1)
	addi	r28, r28,  0x01
	stw		r28,  0x0e94(r1)
	beq		@_44
	cmpwi	r26,  0x5a5a
	bne		@_2f4
	stw		r29,  0x0690(r1)

@_2ec
	cmpw	r29, r29
	b		@_44

@_2f4
	lwz		r28,  0x0000(r26)
	lwz		r30, KDP.HTABORG(r1)
	ori		r28, r28,  0x800
	subf	r30, r30, r29
	cmpw	r29, r29
	rlwimi	r28, r30,  9,  0, 19
	stw		r28,  0x0000(r26)
	b		@_44

@_314
	lwz		r28,  0x0e98(r1)
	lwz		r29,  0x0690(r1)
	addi	r28, r28,  0x01
	stw		r28,  0x0e98(r1)
	li		r28,  0x00
	stw		r28,  0x0000(r29)
	lwz		r29,  0x068c(r1)
	stw		r28,  0x068c(r1)
	stw		r28,  0x0690(r1)
	mfspr	r28, pvr
	rlwinm.	r28, r28,  0,  0, 14
	sync
	tlbie	r29
	beq		@_354
	sync
	tlbsync

@_354
	sync
	isync
	blr
	dc.l	0x57fca803
	dc.l	0x40800068

@_368
	slwi	r28, r30,  2
	rlwinm	r26, r31, 22,  0, 29
	lwzux	r28, r26, r28
	lwz		r31,  0x0688(r1)
	andi.	r30, r28,  0x881
	rlwimi	r31, r28,  0,  0, 19
	cmplwi	cr6, r30,  0x800
	cmplwi	cr7, r30,  0x81
	cmplwi	r30,  0x01
	bge		cr6, @_2ec
	cmplwi	cr7, r30,  0x81
	ori		r31, r31,  0x100
	rlwimi	r31, r28,  3, 24, 24
	rlwimi	r31, r28, 31, 26, 26
	rlwimi	r31, r28,  1, 25, 25
	xori	r31, r31,  0x40
	rlwimi	r31, r28, 30, 31, 31
	beq		@_208
	blt		cr7, @_44
	bl		Local_Panic

@_3b8
	ori		r28, r27,  0xfff
	stw		r28,  0x068c(r1)
	rlwinm	r31, r31,  0, 22, 19
	li		r26,  0x5a5a
	b		@_208
	dc.l	0x4181fc78
	dc.l	0x4bfffc11
	dc.l	0x3ba105c8
	dc.l	0x48000281
	dc.l	0x4bfffc68

@_3e0
	cmplw	cr6, r28, r26
	addi	r29, r29, -0x50
	ble		cr6, @_400
	crnot	2, 2
	lwz		r30, KDP.PTEGMask(r1)
	xori	r31, r31,  0x800
	xor		r29, r29, r30
	beq		@_228

@_400
	lwz		r26,  0x069c(r1)
	crclr	cr6_eq
	rlwimi	r26, r29,  0,  0, 25
	li		r9,  0x08
	addi	r29, r26,  0x08
	b		@_428
	dc.l	0x409a0008
	dc.l	0x7fbaeb78

@_420
	cmpw	cr6, r29, r26
	addi	r29, r29,  0x08

@_428
	rlwimi	r29, r26,  0,  0, 25
	lwz		r31,  0x0004(r29)
	lwz		r30,  0x0000(r29)
	beq		cr6, @_444
	rlwinm	r28, r31, 30, 25, 25
	andc.	r28, r28, r30
	bne		@_420

@_444
	addi	r9, r9, -0x01
	cmpwi	cr7, r9,  0x00
	rlwinm	r31, r30,  0, 25, 25
	blel	cr7, Local_Panic
	rlwinm	r28, r30,  1,  0,  3
	neg		r31, r31
	rlwimi	r28, r30, 22,  4,  9
	xor		r31, r31, r29
	rlwimi	r28, r30,  5, 10, 19
	rlwinm	r31, r31,  6, 10, 19
	xor		r28, r28, r31
	xoris	r30, r30,  0x8000
	lwz		r31,  0x0e9c(r1)
	stw		r29,  0x069c(r1)
	addi	r31, r31,  0x01
	stw		r31,  0x0e9c(r1)
	lwz		r31,  0x0e98(r1)
	stw		r30,  0x0000(r29)
	addi	r31, r31,  0x01
	stw		r31,  0x0e98(r1)
	sync
	mfspr	r31, pvr
	rlwinm.	r31, r31,  0,  0, 14
	tlbie	r28
	beq		@_4b0
	sync
	tlbsync

@_4b0
	sync
	isync

	_InvalNCBPointerCache scratch=r8

	mfsprg	r8, 0
	mr		r9, r28
	lwz		r8, -0x001c(r8)
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	mr		r31, r8
	cmplw	r16, r28
	mr		r8, r28
	bgt		@_600
	bgt		Local_Panic
	bl		MPCall_95_0x1e4
	mr		r26, r30
	beql	@_88

@_500
	lwz		r28,  0x0000(r26)
	lwz		r31,  0x0004(r29)
	andi.	r30, r28,  0x800
	rlwinm	r30, r28, 23,  9, 28
	xor		r30, r30, r29
	beq		Local_Panic
	andi.	r30, r30,  0xffff
	xori	r28, r28,  0x800
	bne		Local_Panic
	rlwimi	r28, r31,  0,  0, 19
	rlwimi	r28, r31, 29, 27, 27
	rlwimi	r28, r31, 27, 28, 28
	stw		r28,  0x0000(r26)
	bl		@_88
	_log	'PTEG overflow: EA '
	mr		r8, r27
	bl		Printw
	_log	'Victim EA: '
	mr		r8, r28
	bl		Printw
	_log	'MapInfo: '
	mr		r8, r29
	bl		Printw
	lwz		r16,  0x0000(r26)
	mr		r8, r26
	bl		Printw
	mr		r8, r16
	bl		Printw
	_log	' PTE: '
	lwz		r16,  0x0000(r29)
	lwz		r17,  0x0004(r29)
	mr		r8, r29
	bl		Printw
	mr		r8, r16
	bl		Printw
	mr		r8, r17
	bl		Printw
	_log	'^n'
	bl		@_88

@_600
	lwz		r26,  0x05e8(r1)
	rlwinm	r30, r28,  7, 25, 28
	lwzx	r26, r26, r30

@_60c
	lhz		r30,  0x0000(r26)
	rlwinm	r31, r28, 20, 16, 31
	subf	r30, r30, r31
	lhz		r31,  0x0002(r26)
	addi	r26, r26,  0x08
	cmplw	cr7, r30, r31
	lwz		r31, -0x0004(r26)
	andi.	r31, r31,  0xe01
	cmpwi	r31,  0xa01
	bgt		cr7, @_60c
	beq		@_60c
	lwz		r26, -0x0004(r26)
	slwi	r30, r30,  2
	rlwinm	r31, r26, 22, 30, 31
	cmpwi	cr7, r31,  0x03
	rlwinm	r26, r26, 22,  0, 29
	add		r26, r26, r30
	bnel	cr7, @_88
	b		@_500



PagingFunc2	;	OUTSIDE REFERER
	sync
	isync
	lwz		r28,  0x0000(r29)
	stw		r28,  0x05e8(r1)
	addi	r28, r28,  0x84
	lis		r31,  0x00

@_18
	lwzu	r30, -0x0008(r28)
	addis	r31, r31, -0x1000
	mr.		r31, r31
	mtsrin	r30, r31
	bne		@_18
	isync

PagingFunc2AndAHalf
	lwz		r28,  0x0004(r29)
	mfspr	r31, pvr
	rlwinm.	r31, r31,  0,  0, 14
	addi	r29, r1,  0x00
	stw		r28,  0x05ec(r1)
	beq		@_168
	li		r30,  0x00
	mtspr	ibat0u, r30
	mtspr	ibat1u, r30
	mtspr	ibat2u, r30
	mtspr	ibat3u, r30
	mtspr	dbat0u, r30
	mtspr	dbat1u, r30
	mtspr	dbat2u, r30
	mtspr	dbat3u, r30
	rlwimi	r29, r28,  7, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	rlwinm	r31, r31,  0, 29, 27
	mtspr	ibat0l, r31
	mtspr	ibat0u, r30
	stw		r31,  0x0304(r1)
	stw		r30,  0x0300(r1)
	rlwimi	r29, r28, 11, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	rlwinm	r31, r31,  0, 29, 27
	mtspr	ibat1l, r31
	mtspr	ibat1u, r30
	stw		r31,  0x030c(r1)
	stw		r30,  0x0308(r1)
	rlwimi	r29, r28, 15, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	rlwinm	r31, r31,  0, 29, 27
	mtspr	ibat2l, r31
	mtspr	ibat2u, r30
	stw		r31,  0x0314(r1)
	stw		r30,  0x0310(r1)
	rlwimi	r29, r28, 19, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	rlwinm	r31, r31,  0, 29, 27
	mtspr	ibat3l, r31
	mtspr	ibat3u, r30
	stw		r31,  0x031c(r1)
	stw		r30,  0x0318(r1)
	rlwimi	r29, r28, 23, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	mtspr	dbat0l, r31
	mtspr	dbat0u, r30
	stw		r31,  0x0324(r1)
	stw		r30,  0x0320(r1)
	rlwimi	r29, r28, 27, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	mtspr	dbat1l, r31
	mtspr	dbat1u, r30
	stw		r31,  0x032c(r1)
	stw		r30,  0x0328(r1)
	rlwimi	r29, r28, 31, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	mtspr	dbat2l, r31
	mtspr	dbat2u, r30
	stw		r31,  0x0334(r1)
	stw		r30,  0x0330(r1)
	rlwimi	r29, r28,  3, 25, 28
	lwz		r31,  0x0284(r29)
	lwz		r30,  0x0280(r29)
	mtspr	dbat3l, r31
	mtspr	dbat3u, r30
	stw		r31,  0x033c(r1)
	stw		r30,  0x0338(r1)
	isync
	cmpw	r29, r29
	blr

@_168
	rlwimi	r29, r28,  7, 25, 28
	lwz		r30,  0x0280(r29)
	lwz		r31,  0x0284(r29)
	stw		r30,  0x0300(r1)
	stw		r31,  0x0304(r1)
	stw		r30,  0x0320(r1)
	stw		r31,  0x0324(r1)
	rlwimi	r30, r31,  0, 25, 31
	mtspr	ibat0u, r30
	lwz		r30,  0x0280(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30,  6, 25, 25
	mtspr	ibat0l, r31
	rlwimi	r29, r28, 11, 25, 28
	lwz		r30,  0x0280(r29)
	lwz		r31,  0x0284(r29)
	stw		r30,  0x0308(r1)
	stw		r31,  0x030c(r1)
	stw		r30,  0x0328(r1)
	stw		r31,  0x032c(r1)
	rlwimi	r30, r31,  0, 25, 31
	mtspr	ibat1u, r30
	lwz		r30,  0x0280(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30,  6, 25, 25
	mtspr	ibat1l, r31
	rlwimi	r29, r28, 15, 25, 28
	lwz		r30,  0x0280(r29)
	lwz		r31,  0x0284(r29)
	stw		r30,  0x0310(r1)
	stw		r31,  0x0314(r1)
	stw		r30,  0x0330(r1)
	stw		r31,  0x0334(r1)
	rlwimi	r30, r31,  0, 25, 31
	mtspr	ibat2u, r30
	lwz		r30,  0x0280(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30,  6, 25, 25
	mtspr	ibat2l, r31
	rlwimi	r29, r28, 19, 25, 28
	lwz		r30,  0x0280(r29)
	lwz		r31,  0x0284(r29)
	stw		r30,  0x0318(r1)
	stw		r31,  0x031c(r1)
	stw		r30,  0x0338(r1)
	stw		r31,  0x033c(r1)
	rlwimi	r30, r31,  0, 25, 31
	mtspr	ibat3u, r30
	lwz		r30,  0x0280(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30,  6, 25, 25
	mtspr	ibat3l, r31
	cmpw	r29, r29
	blr



PagingL2PWithBATs	;	OUTSIDE REFERER
	lwz		r30,  0x0000(r29)
	li		r28, -0x01
	rlwimi	r28, r30, 15,  0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	beq		@_54
	lwzu	r30,  0x0008(r29)
	rlwimi	r28, r30, 15,  0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	beq		@_54
	lwzu	r30,  0x0008(r29)
	rlwimi	r28, r30, 15,  0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	beq		@_54
	lwzu	r30,  0x0008(r29)
	rlwimi	r28, r30, 15,  0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	bne		PagingL2PWithoutBATs

@_54
	andi.	r31, r30,  0x01
	rlwinm	r28, r28,  0,  8, 19
	lwzu	r31,  0x0004(r29)
	and		r28, r27, r28
	or		r31, r31, r28
	bnelr



PagingL2PWithoutBATs	;	OUTSIDE REFERER
	mfsrin	r31, r27
	rlwinm	r30, r27, 10, 26, 31
	rlwimi	r30, r31,  7,  1, 24
	rlwinm	r28, r27, 26, 10, 25
	oris	r30, r30,  0x8000
	rlwinm	r31, r31,  6,  7, 25
	xor		r28, r28, r31
	lwz		r31, KDP.PTEGMask(r1)
	lwz		r29, KDP.HTABORG(r1)
	and		r28, r28, r31
	or.		r29, r29, r28

@_2c
	lwz		r31,  0x0000(r29)
	lwz		r28,  0x0008(r29)
	cmpw	cr6, r30, r31
	lwz		r31,  0x0010(r29)
	cmpw	cr7, r30, r28
	lwzu	r28,  0x0018(r29)
	bne		cr6, @_50

@_48
	lwzu	r31, -0x0014(r29)
	blr

@_50
	cmpw	cr6, r30, r31
	lwzu	r31,  0x0008(r29)
	beq		cr7, @_48
	cmpw	cr7, r30, r28
	lwzu	r28,  0x0008(r29)
	beq		cr6, @_48
	cmpw	cr6, r30, r31
	lwzu	r31,  0x0008(r29)
	beq		cr7, @_48
	cmpw	cr7, r30, r28
	lwzu	r28,  0x0008(r29)
	beq		cr6, @_48
	cmpw	cr6, r30, r31
	lwzu	r31, -0x000c(r29)
	beqlr	cr7
	cmpw	cr7, r30, r28
	lwzu	r31,  0x0008(r29)
	beqlr	cr6
	lwzu	r31,  0x0008(r29)
	beqlr	cr7
	lwz		r31, KDP.PTEGMask(r1)
	xori	r30, r30,  0x40
	andi.	r28, r30,  0x40
	addi	r29, r29, -0x3c
	xor		r29, r29, r31
	bne		@_2c
	blr



pb	equ		12

PagingFlushTLB	;	OUTSIDE REFERER
	lhz		r29, KDP.ProcessorInfo + NKProcessorInfo.TransCacheTotalSize(r1)
	slwi	r29, r29, pb

@loop
	subi	r29, r29, 1 << pb
	cmpwi	r29, 0
	tlbie	r29
	bgt		@loop

	mfspr	r29, pvr
	rlwinm.	r29, r29, 0, 0, 14

	;	All cpus
	sync
	beqlr

	;	Non-601 stuff
	tlbsync
	sync
	isync
	blr
