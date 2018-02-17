;	                       FillIndigo

;	Xrefs:
;	setup

	align	kIntAlign

FillIndigo	;	EXPORTED
	mflr	r9
	llabel	r23, panic
	add		r23, r23, r25
	addi	r8, r1, PSA.IndigoVecBase
	li		r22, 192 ;VecTable.Size
	bl		wordfill
	mtlr	r9
	llabel	r23, IntIndigo
	add		r23, r23, r25
	stw		r23, VecTable.SystemResetVector(r8)
	stw		r23, VecTable.ExternalIntVector(r8)
	stw		r23, VecTable.DecrementerVector(r8)
	blr



;	                     kcPowerDispatch

;	NB: I was probably wrong about this.
;	Contains a (very rare) mtsprg0 instruction.

;	Xrefs:
;	"sup"

	align	kIntAlign

kcPowerDispatch	;	EXPORTED	;	OUTSIDE REFERER
	mtcr	r7
	lwz		r4,  0x0670(r1)
	cmplwi	cr7, r3,  0x0b
	mr		r9, r13
	blt-	cr2, kcPowerDispatch_0x18
	lwz		r9, -0x0440(r1)

kcPowerDispatch_0x18
	and.	r8, r4, r9
	bgt-	cr7, major_0x09e28_0x34
	bne-	major_0x09e28_0x2c
	cmplwi	cr7, r3,  0x0b
	beq-	cr7, major_0x0a600_0x1c
	cmplwi	cr7, r3,  0x08
	beq-	cr7, major_0x09e28_0x3c
	cmplwi	cr7, r3,  0x09
	beq-	cr7, major_0x0a600_0x10
	stw		r26,  0x01d4(r6)
	stw		r27,  0x01dc(r6)
	stw		r28,  0x01e4(r6)
	stw		r29,  0x01ec(r6)
	stw		r30,  0x01f4(r6)
	stw		r31,  0x01fc(r6)
	mfsprg	r31, 3
	addi	r8, r1, -0x810
	mtsprg	3, r8
	rlwinm	r26, r3,  0, 29, 29
	clrlwi	r3, r3,  0x1e
	lbz		r8,  0x06b8(r1)
	slwi	r3, r3,  1
	addi	r3, r3,  0x1a
	rlwnm	r3, r8, r3,  0x1e,  0x1f
	cmpwi	r3,  0x00
	beq-	major_0x09e28_0x24
	lbz		r9,  0x06b9(r1)
	cmpwi	r9,  0x00
	beq-	kcPowerDispatch_0xb0
	mfspr	r27, hid0
	mr		r8, r27
	cmpwi	r9,  0x01
	beq-	kcPowerDispatch_0xa8
	oris	r9, r3,  0x100
	srw		r9, r9, r9
	rlwimi	r8, r9,  0,  8, 10

kcPowerDispatch_0xa8
	oris	r8, r8,  0x01
	mtspr	hid0, r8

kcPowerDispatch_0xb0
	cmplwi	r26,  0x04
	beql-	kcCacheDispatch_0x258
	mfmsr	r8
	ori		r8, r8,  0x8002
	cmplwi	r3,  0x00
	beq-	kcPowerDispatch_0xcc
	oris	r8, r8,  0x04

kcPowerDispatch_0xcc
	sync
	mtmsr	r8
	isync

kcPowerDispatch_0xd8
	b		kcPowerDispatch_0xd8



;	                       IntIndigo

;	Odd that this is unaligned

IntIndigo
	lbz		r8,  0x06b9(r1)
	cmpwi	r8,  0x00
	beq-	IntIndigo_0x10
	mtspr	hid0, r27

IntIndigo_0x10
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	lis		r9,  0x7fff
	mfspr	r8, dec
	mtspr	dec, r9
	mtspr	dec, r8



;	                     major_0x09e28

;	Xrefs:
;	kcPowerDispatch
;	IntIndigo

	li		r3,  0x00

major_0x09e28_0x4
	mtsprg	3, r31
	lwz		r26,  0x01d4(r6)
	lwz		r27,  0x01dc(r6)
	lwz		r28,  0x01e4(r6)
	lwz		r29,  0x01ec(r6)
	lwz		r30,  0x01f4(r6)
	lwz		r31,  0x01fc(r6)
	b		IntReturn

major_0x09e28_0x24	;	OUTSIDE REFERER
	li		r3, -0x7267
	b		major_0x09e28_0x4

major_0x09e28_0x2c	;	OUTSIDE REFERER
	li		r3,  0x00
	b		IntReturn

major_0x09e28_0x34	;	OUTSIDE REFERER
	li		r3, -0x01
	b		IntReturn

major_0x09e28_0x3c	;	OUTSIDE REFERER
	mfsprg	r9, 0
	lwz		r8, -0x0338(r9)
	lwz		r9,  0x0024(r8)
	cmpwi	r9,  0x01
	li		r3, -0x7267
	bgt+	IntReturn
	stw		r26,  0x01d4(r6)
	stw		r27,  0x01dc(r6)
	stw		r28,  0x01e4(r6)
	stw		r29,  0x01ec(r6)
	stw		r30,  0x01f4(r6)
	stw		r31,  0x01fc(r6)
	bl		kcCacheDispatch_0x258
	mfspr	r9, hid0
	rlwinm	r9, r9,  0, 18, 16
	rlwinm	r9, r9,  0, 17, 15
	mtspr	hid0, r9
	sync
	isync
	lwz		r26,  0x0f68(r1)
	andi.	r26, r26,  0x01
	beq-	major_0x09e28_0xb0
	mfspr	r9, l2cr
	clrlwi	r9, r9,  0x01
	mtspr	l2cr, r9
	sync
	isync
	addi	r8, r1, -0x4d0
	stw		r9,  0x0050(r8)

major_0x09e28_0xb0
	stw		r7,  0x0000(r6)
	stw		r2,  0x0114(r6)
	stw		r3,  0x011c(r6)
	stw		r4,  0x0124(r6)
	stw		r5,  0x012c(r6)
	stw		r14,  0x0174(r6)
	stw		r15,  0x017c(r6)
	stw		r16,  0x0184(r6)
	stw		r17,  0x018c(r6)
	stw		r18,  0x0194(r6)
	stw		r19,  0x019c(r6)
	stw		r20,  0x01a4(r6)
	stw		r21,  0x01ac(r6)
	stw		r22,  0x01b4(r6)
	stw		r23,  0x01bc(r6)
	stw		r24,  0x01c4(r6)
	stw		r25,  0x01cc(r6)
	stw		r13,  0x00dc(r6)
	andi.	r8, r11,  0x2000
	beq-	major_0x09e28_0x198
	mfmsr	r8
	ori		r8, r8,  0x2000
	mtmsr	r8
	isync
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
	mffs	f0
	stfd	f17,  0x0288(r6)
	stfd	f18,  0x0290(r6)
	stfd	f19,  0x0298(r6)
	stfd	f20,  0x02a0(r6)
	stfd	f21,  0x02a8(r6)
	stfd	f22,  0x02b0(r6)
	stfd	f23,  0x02b8(r6)
	stfd	f24,  0x02c0(r6)
	stfd	f25,  0x02c8(r6)
	stfd	f26,  0x02d0(r6)
	stfd	f27,  0x02d8(r6)
	stfd	f28,  0x02e0(r6)
	stfd	f29,  0x02e8(r6)
	stfd	f30,  0x02f0(r6)
	stfd	f31,  0x02f8(r6)
	stfd	f0,  0x00e0(r6)

major_0x09e28_0x198
	mfxer	r9
	addi	r16, r1, -0x4d0
	stw		r9,  0x00d4(r6)
	mfctr	r9
	stw		r9,  0x00f0(r6)
	stw		r12,  0x00e8(r6)
	stw		r10,  0x0054(r16)
	stw		r11,  0x0058(r16)
	mfspr	r9, hid0
	stw		r9,  0x0064(r16)

major_0x09e28_0x1c0
	mftbu	r9
	stw		r9,  0x005c(r16)
	mftb	r9
	stw		r9,  0x0060(r16)
	mftbu	r8
	lwz		r9,  0x005c(r16)
	cmpw	r8, r9
	bne+	major_0x09e28_0x1c0
	mfmsr	r9
	stw		r9,  0x006c(r16)
	mfspr	r9, sdr1
	stw		r9,  0x0070(r16)
	mfspr	r9, dbat0u
	stw		r9,  0x0000(r16)
	mfspr	r9, dbat0l
	stw		r9,  0x0004(r16)
	mfspr	r9, dbat1u
	stw		r9,  0x0008(r16)
	mfspr	r9, dbat1l
	stw		r9,  0x000c(r16)
	mfspr	r9, dbat2u
	stw		r9,  0x0010(r16)
	mfspr	r9, dbat2l
	stw		r9,  0x0014(r16)
	mfspr	r9, dbat3u
	stw		r9,  0x0018(r16)
	mfspr	r9, dbat3l
	stw		r9,  0x001c(r16)
	mfspr	r9, ibat0u
	stw		r9,  0x0020(r16)
	mfspr	r9, ibat0l
	stw		r9,  0x0024(r16)
	mfspr	r9, ibat1u
	stw		r9,  0x0028(r16)
	mfspr	r9, ibat1l
	stw		r9,  0x002c(r16)
	mfspr	r9, ibat2u
	stw		r9,  0x0030(r16)
	mfspr	r9, ibat2l
	stw		r9,  0x0034(r16)
	mfspr	r9, ibat3u
	stw		r9,  0x0038(r16)
	mfspr	r9, ibat3l
	stw		r9,  0x003c(r16)
	mfsprg	r9, 0
	stw		r9,  0x0040(r16)
	mfsprg	r9, 1
	stw		r9,  0x0044(r16)
	mfsprg	r9, 2
	stw		r9,  0x0048(r16)
	mfsprg	r9, 3
	stw		r9,  0x004c(r16)
	stw		r6,  0x007c(r16)
	bl		major_0x09e28_0x59c
	lwz		r1,  0x0004(r1)
	addi	r16, r1, -0x4d0
	lis		r8,  0x100
	ori		r8, r8,  0x00
	lis		r9,  0x00

major_0x09e28_0x2ac
	addis	r9, r9, -0x1000
	addis	r8, r8, -0x10
	mr.		r9, r9
	mtsrin	r8, r9
	bne+	major_0x09e28_0x2ac
	isync
	mfspr	r9, hid0
	li		r8,  0x800
	ori		r8, r8,  0x200
	or		r9, r9, r8
	mtspr	hid0, r9
	isync
	andc	r9, r9, r8
	mtspr	hid0, r9
	isync
	ori		r9, r9,  0x8000
	ori		r9, r9,  0x4000
	mtspr	hid0, r9
	isync
	lwz		r26,  0x0f68(r1)
	andi.	r26, r26,  0x01
	beq-	major_0x09e28_0x38c
	lwz		r8,  0x0f54(r1)
	mr.		r8, r8
	beq-	major_0x09e28_0x38c
	mfspr	r9, hid0
	rlwinm	r9, r9,  0, 12, 10
	mtspr	hid0, r9
	isync
	lwz		r9,  0x0050(r16)
	mtspr	l2cr, r9
	sync
	isync
	lis		r8,  0x20
	or		r8, r9, r8
	mtspr	l2cr, r8
	sync
	isync

major_0x09e28_0x344
	mfspr	r8, l2cr
	rlwinm.	r8, r8, 31,  0,  0
	bne+	major_0x09e28_0x344
	mfspr	r8, l2cr
	lis		r9, -0x21
	ori		r9, r9,  0xffff
	and		r8, r8, r9
	mtspr	l2cr, r8
	sync
	mfspr	r8, hid0
	oris	r8, r8,  0x10
	mtspr	hid0, r8
	isync
	mfspr	r8, l2cr
	oris	r8, r8,  0x8000
	mtspr	l2cr, r8
	sync
	isync

major_0x09e28_0x38c
	lwz		r6,  0x007c(r16)
	lwz		r7,  0x0000(r6)
	lwz		r13,  0x00dc(r6)
	lwz		r9,  0x00f0(r6)
	mtctr	r9
	lwz		r12,  0x00e8(r6)
	lwz		r9,  0x00d4(r6)
	mtxer	r9
	lwz		r10,  0x0054(r16)
	lwz		r11,  0x0058(r16)
	lwz		r2,  0x0114(r6)
	lwz		r3,  0x011c(r6)
	lwz		r4,  0x0124(r6)
	lwz		r5,  0x012c(r6)
	lwz		r14,  0x0174(r6)
	lwz		r15,  0x017c(r6)
	lwz		r17,  0x018c(r6)
	lwz		r18,  0x0194(r6)
	lwz		r19,  0x019c(r6)
	lwz		r20,  0x01a4(r6)
	lwz		r21,  0x01ac(r6)
	lwz		r22,  0x01b4(r6)
	lwz		r23,  0x01bc(r6)
	lwz		r24,  0x01c4(r6)
	lwz		r25,  0x01cc(r6)
	lwz		r26,  0x01d4(r6)
	lwz		r27,  0x01dc(r6)
	lwz		r28,  0x01e4(r6)
	lwz		r29,  0x01ec(r6)
	lwz		r30,  0x01f4(r6)
	lwz		r31,  0x01fc(r6)
	andi.	r8, r11,  0x2000
	beq-	major_0x09e28_0x4a8
	mfmsr	r8
	ori		r8, r8,  0x2000
	mtmsr	r8
	isync
	lfd		f31,  0x00e0(r6)
	lfd		f0,  0x0200(r6)
	lfd		f1,  0x0208(r6)
	lfd		f2,  0x0210(r6)
	lfd		f3,  0x0218(r6)
	lfd		f4,  0x0220(r6)
	lfd		f5,  0x0228(r6)
	lfd		f6,  0x0230(r6)
	lfd		f7,  0x0238(r6)
	lfd		f8,  0x0240(r6)
	mtfsf	 0xff, f31
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

major_0x09e28_0x4a8
	lwz		r9,  0x0064(r16)
	ori		r9, r9,  0x8000
	ori		r9, r9,  0x4000
	mtspr	hid0, r9
	sync
	isync
	lwz		r9,  0x005c(r16)
	mtspr	tbu, r9
	lwz		r9,  0x0060(r16)
	mtspr	tbl, r9
	li		r9,  0x01
	mtspr	dec, r9
	lwz		r9,  0x006c(r16)
	mtmsr	r9
	sync
	isync
	lwz		r9,  0x0070(r16)
	mtspr	sdr1, r9
	lwz		r9,  0x0040(r16)
	mtsprg	0, r9
	lwz		r9,  0x0044(r16)
	mtsprg	1, r9
	lwz		r9,  0x0048(r16)
	mtsprg	2, r9
	lwz		r9,  0x004c(r16)
	mtsprg	3, r9
	lwz		r9,  0x0000(r16)
	mtspr	dbat0u, r9
	lwz		r9,  0x0004(r16)
	mtspr	dbat0l, r9
	lwz		r9,  0x0008(r16)
	mtspr	dbat1u, r9
	lwz		r9,  0x000c(r16)
	mtspr	dbat1l, r9
	lwz		r9,  0x0010(r16)
	mtspr	dbat2u, r9
	lwz		r9,  0x0014(r16)
	mtspr	dbat2l, r9
	lwz		r9,  0x0018(r16)
	mtspr	dbat3u, r9
	lwz		r9,  0x001c(r16)
	mtspr	dbat3l, r9
	lwz		r9,  0x0020(r16)
	mtspr	ibat0u, r9
	lwz		r9,  0x0024(r16)
	mtspr	ibat0l, r9
	lwz		r9,  0x0028(r16)
	mtspr	ibat1u, r9
	lwz		r9,  0x002c(r16)
	mtspr	ibat1l, r9
	lwz		r9,  0x0030(r16)
	mtspr	ibat2u, r9
	lwz		r9,  0x0034(r16)
	mtspr	ibat2l, r9
	lwz		r9,  0x0038(r16)
	mtspr	ibat3u, r9
	lwz		r9,  0x003c(r16)
	mtspr	ibat3l, r9
	lwz		r16,  0x0184(r6)
	li		r3,  0x00
	b		IntReturn

major_0x09e28_0x59c
	mflr	r9
	stw		r9,  0x0074(r16)
	stw		r1,  0x0078(r16)
	addi	r9, r16,  0x74
	li		r0,  0x00
	stw		r9,  0x0000(0)
	lis		r9,  0x4c61
	ori		r9, r9,  0x7273
	stw		r9,  0x0004(0)
	mfspr	r9, hid0
	andis.	r9, r9,  0x20
	mtspr	hid0, r9
	mfmsr	r8
	oris	r8, r8,  0x04
	mfspr	r9, hid0
	ori		r9, r9,  0x8000
	mtspr	hid0, r9
	bl		* + 4
	mflr	r9
	addi	r9, r9, major_0x0a600 - (* - 4)
	lisori	r1, 0xcafebabe
	b		major_0x0a500


	align	8


;	                     major_0x0a500

;	Xrefs:
;	major_0x09e28

major_0x0a500	;	OUTSIDE REFERER
	sync
	mtmsr	r8
	isync
	cmpwi	r1,  0x00
	beq+	major_0x0a500
	lwz		r0,  0x0000(r9)
	andi.	r1, r1,  0x00
	b		major_0x0a500


	align	8


;	                     major_0x0a600

;	Xrefs:
;	kcPowerDispatch

major_0x0a600	;	OUTSIDE REFERER
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0

major_0x0a600_0x10	;	OUTSIDE REFERER
	mtspr	1019, r5
	li		r3,  0x00
	b		IntReturn

major_0x0a600_0x1c	;	OUTSIDE REFERER
	b		major_0x0a600_0x1c
