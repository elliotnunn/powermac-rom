kcCacheDispatch	;	OUTSIDE REFERER
	stw		r21,  0x01ac(r6)
	stw		r22,  0x01b4(r6)
	stw		r23,  0x01bc(r6)
	clrlwi	r8, r3,  0x10
	cmplwi	r8,  0x02
	bgt-	kcCacheDispatch_0x4c
	lwz		r8,  0x0f68(r1)
	andi.	r8, r8,  0x01
	beq-	kcCacheDispatch_0x178
	rlwinm.	r9, r3,  0,  2,  2
	bnel-	kcCacheDispatch_0x1e4
	srwi	r8, r3, 30
	cmpwi	r8,  0x03
	beq-	kcCacheDispatch_0xd8
	clrlwi	r8, r3,  0x10
	cmplwi	r8,  0x01
	beq-	kcCacheDispatch_0x58
	cmplwi	r8,  0x02
	beq-	kcCacheDispatch_0xb8

kcCacheDispatch_0x4c
	lis		r3, -0x01
	ori		r3, r3,  0xfffe
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0x58
	rlwinm.	r9, r3,  0,  1,  1
	bne-	kcCacheDispatch_0x74
	rlwinm.	r9, r3,  0,  0,  0
	bne-	kcCacheDispatch_0x98
	rlwinm.	r9, r3,  0,  3,  3
	bl		kcCacheDispatch_0x258
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0x74
	bl		kcCacheDispatch_0x258
	rlwinm	r22, r3,  0,  4,  5
	srwi	r22, r22, 12
	mfspr	r21, hid0
	andc	r21, r21, r22
	sync
	mtspr	hid0, r21
	li		r3,  0x00
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0x98
	rlwinm	r22, r3,  0,  4,  5
	srwi	r22, r22, 12
	mfspr	r21, hid0
	or		r21, r21, r22
	sync
	mtspr	hid0, r21
	li		r3,  0x00
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0xb8
	rlwinm.	r9, r3,  0,  1,  1
	bne-	kcCacheDispatch_0x180
	rlwinm.	r9, r3,  0,  0,  0
	bne-	kcCacheDispatch_0xe8
	rlwinm.	r9, r3,  0,  3,  3
	bne-	kcCacheDispatch_0xe4
	rlwinm.	r9, r3,  0,  2,  2
	bne-	kcCacheDispatch_0x1c4

kcCacheDispatch_0xd8
	lis		r3, -0x01
	ori		r3, r3,  0xfffc
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0xe4
	bl		kcCacheDispatch_0x180

kcCacheDispatch_0xe8
	mfspr	r21, l2cr
	sync
	andis.	r21, r21,  0x8000
	bne-	kcCacheDispatch_0x1c4
	lwz		r8,  0x0f54(r1)
	and.	r8, r8, r8
	beq-	kcCacheDispatch_0x178
	mfspr	r21, hid0
	rlwinm	r8, r21,  0, 12, 10
	mtspr	hid0, r8
	sync
	addi	r8, r1, -0x4d0
	lwz		r8,  0x0050(r8)
	and.	r8, r8, r8
	beq-	kcCacheDispatch_0x1c4
	sync
	lis		r9,  0x20
	or		r8, r8, r9
	mtspr	l2cr, r8
	sync

kcCacheDispatch_0x138
	mfspr	r8, l2cr
	sync
	andi.	r9, r8,  0x01
	bne+	kcCacheDispatch_0x138
	lis		r9,  0x20
	andc	r8, r8, r9
	mtspr	l2cr, r8
	sync
	lis		r9, -0x8000
	or		r8, r8, r9
	mtspr	l2cr, r8
	sync
	mtspr	hid0, r21
	sync
	li		r3,  0x00
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0x178
	li		r3, -0x02
	b		kcCacheDispatch_0x1c4

kcCacheDispatch_0x180
	mfspr	r22, l2cr
	sync
	andis.	r22, r22,  0x8000
	beq-	kcCacheDispatch_0x1c4
	bl		kcCacheDispatch_0x258
	mfspr	r22, l2cr
	sync
	clrlwi	r22, r22,  0x01
	mtspr	l2cr, r22
	sync
	addi	r8, r1, -0x4d0
	stw		r22,  0x0050(r8)
	sync
	rlwinm	r22, r22,  0,  7,  3
	oris	r22, r22,  0x10
	mtspr	l2cr, r22
	sync

kcCacheDispatch_0x1c4
	ori		r23, r23,  0xffff
	oris	r3, r3,  0xffff
	and		r3, r3, r23

kcCacheDispatch_0x1d0
	lwz		r21,  0x01ac(r6)
	lwz		r22,  0x01b4(r6)
	lwz		r23,  0x01bc(r6)
	sync
	b		skeleton_key

kcCacheDispatch_0x1e4
	clrlwi	r8, r3,  0x10
	cmplwi	r8,  0x01
	beq-	kcCacheDispatch_0x204
	cmplwi	r8,  0x02
	beq-	kcCacheDispatch_0x218
	lis		r3, -0x01
	ori		r3, r3,  0xfffb
	b		kcCacheDispatch_0x1d0

kcCacheDispatch_0x204
	mfspr	r21, hid0
	rlwinm.	r21, r21, 12,  4,  5
	beq-	kcCacheDispatch_0x24c
	oris	r23, r21,  0x8000
	blr

kcCacheDispatch_0x218
	lwz		r8,  0x0f54(r1)
	and.	r8, r8, r8
	beq+	kcCacheDispatch_0x178
	mfspr	r21, hid0
	rlwinm	r21, r21, 12,  4,  5
	mfspr	r22, l2cr
	rlwinm	r22, r22,  5,  4,  4
	andc	r21, r21, r22
	mfspr	r22, l2cr
	andis.	r22, r22,  0x8000
	beq-	kcCacheDispatch_0x24c
	or		r23, r21, r22
	blr

kcCacheDispatch_0x24c
	lis		r23,  0x4000
	ori		r23, r23,  0x00
	blr

kcCacheDispatch_0x258	;	OUTSIDE REFERER
	mfctr	r8
	stw		r25,  0x01cc(r6)
	stw		r24,  0x01c4(r6)
	stw		r8,  0x00f4(r6)
	lhz		r25,  0x0f44(r1)
	and.	r25, r25, r25
	cntlzw	r8, r25
	beq-	kcCacheDispatch_0x338
	subfic	r9, r8,  0x1f
	lwz		r8,  0x0f34(r1)
	and.	r8, r8, r8
	beq-	kcCacheDispatch_0x338
	lwz		r24,  0x0f68(r1)
	mtcr	r24
	bso-	cr6, kcCacheDispatch_0x350
	bne-	cr7, kcCacheDispatch_0x2a4
	slwi	r24, r8,  1
	add		r8, r8, r24
	srwi	r8, r8,  1

kcCacheDispatch_0x2a4
	srw		r8, r8, r9
	mtctr	r8
	lwz		r8,  0x0630(r1)
	lwz		r9,  0x0028(r8)
	add		r8, r8, r9

kcCacheDispatch_0x2b8
	lwzux	r9, r8, r25
	bdnz+	kcCacheDispatch_0x2b8
	lwz		r24,  0x0f68(r1)
	andi.	r24, r24,  0x01
	beq-	kcCacheDispatch_0x338
	mfspr	r24, l2cr
	andis.	r24, r24,  0x8000
	beq-	kcCacheDispatch_0x338
	lhz		r25,  0x0f60(r1)
	and.	r25, r25, r25
	cntlzw	r8, r25
	beq-	kcCacheDispatch_0x338
	subfic	r9, r8,  0x1f
	lwz		r8,  0x0f54(r1)
	and.	r8, r8, r8
	beq-	kcCacheDispatch_0x338
	srw		r8, r8, r9
	mtctr	r8
	mfspr	r24, l2cr
	oris	r24, r24,  0x40
	mtspr	l2cr, r24
	isync
	lwz		r8,  0x0630(r1)
	lwz		r9,  0x0028(r8)
	add		r8, r8, r9
	addis	r8, r8,  0x19
	neg		r25, r25

kcCacheDispatch_0x324
	lwzux	r9, r8, r25
	bdnz+	kcCacheDispatch_0x324
	rlwinm	r24, r24,  0, 10,  8
	mtspr	l2cr, r24
	isync

kcCacheDispatch_0x338
	lwz		r8,  0x00f4(r6)
	lwz		r25,  0x01cc(r6)
	lwz		r24,  0x01c4(r6)
	sync
	mtctr	r8
	blr

kcCacheDispatch_0x350
	dssall
	sync
	mfspr	r8, 1014
	oris	r8, r8,  0x80
	mtspr	1014, r8
	sync

kcCacheDispatch_0x368
	mfspr	r8, 1014
	sync
	andis.	r8, r8,  0x80
	bne+	kcCacheDispatch_0x368
	mfspr	r8, l2cr
	ori		r8, r8,  0x800
	mtspr	l2cr, r8
	sync

kcCacheDispatch_0x388
	mfspr	r8, l2cr
	sync
	andi.	r8, r8,  0x800
	bne+	kcCacheDispatch_0x388
	b		kcCacheDispatch_0x338

kcCacheDispatch_0x39c	;	OUTSIDE REFERER
	lwz		r8,  0x0f68(r1)
	mtcr	r8
	bnslr-	cr6
	dssall
	sync
	mfspr	r8, 1014
	oris	r8, r8,  0x80
	mtspr	1014, r8
	sync

kcCacheDispatch_0x3c0
	mfspr	r8, 1014
	sync
	andis.	r8, r8,  0x80
	bne+	kcCacheDispatch_0x3c0
	blr
