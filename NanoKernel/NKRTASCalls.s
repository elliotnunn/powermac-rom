Local_Panic		set		*
				b		panic



;	                       kcRTASDispatch

;	Only major that hits the RTAS globals.
;	RTAS requires some specific context stuff.

;	Xrefs:
;	"sup"

;	> r1    = kdp
;	> r6    = some kind of place
;	> r7    = some kind of flags

	align	5

kcRTASDispatch	;	OUTSIDE REFERER
	lwz		r8,  0x0908(r1)
	cmpwi	r8,  0x00
	bne-	rtas_is_available
	li		r3, -0x01
	b		IntReturn

rtas_is_available

	_Lock			PSA.RTASLock, scratch1=r8, scratch2=r9

	mtcrf	 0x3f, r7
	lwz		r9, KDP.PA_ECB(r1)
	lwz		r8, EWA.Enables(r1)
	stw		r7,  0x0000(r6)
	stw		r8,  0x0004(r6)
	bns-	cr6, kcRTASDispatch_0x5c
	stw		r17,  0x0024(r6)
	stw		r20,  0x0028(r6)
	stw		r21,  0x002c(r6)
	stw		r19,  0x0034(r6)
	stw		r18,  0x003c(r6)
	lmw		r14,  0x0038(r1)

kcRTASDispatch_0x5c
	mfxer	r8
	stw		r13,  0x00dc(r6)
	stw		r8,  0x00d4(r6)
	stw		r12,  0x00ec(r6)
	mfctr	r8
	stw		r10,  0x00fc(r6)
	stw		r8,  0x00f4(r6)
	ble-	cr3, kcRTASDispatch_0x8c
	lwz		r8,  0x00c4(r9)
	mfspr	r12, mq
	mtspr	mq, r8
	stw		r12,  0x00c4(r6)

kcRTASDispatch_0x8c
	lwz		r8,  0x0004(r1)
	stw		r8,  0x010c(r6)
	stw		r2,  0x0114(r6)
	stw		r3,  0x011c(r6)
	stw		r4,  0x0124(r6)
	lwz		r8,  0x0018(r1)
	stw		r5,  0x012c(r6)
	stw		r8,  0x0134(r6)
	andi.	r8, r11,  0x2000
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
	stw		r26,  0x01d4(r6)
	stw		r27,  0x01dc(r6)
	stw		r28,  0x01e4(r6)
	stw		r29,  0x01ec(r6)
	stw		r30,  0x01f4(r6)
	stw		r31,  0x01fc(r6)
	bnel+	major_0x03e18_0xb4
	stw		r11,  0x00a4(r6)
	mr		r27, r3
	addi	r29, r1, 800
	bl		PagingFunc3
	beql+	Local_Panic
	rlwimi	r3, r31,  0,  0, 19
	lhz		r8,  0x0004(r3)
	cmpwi	r8,  0x00
	beq-	kcRTASDispatch_0x14c
	slwi	r8, r8,  2
	lwzx	r27, r8, r3
	addi	r29, r1, 800
	bl		PagingFunc3
	beql+	Local_Panic
	lwzx	r9, r8, r3
	rlwimi	r9, r31,  0,  0, 19
	stwx	r9, r8, r3
	li		r9,  0x00
	sth		r9,  0x0004(r3)
	dcbf	r8, r3

kcRTASDispatch_0x14c
	li		r9,  0x04
	dcbf	r9, r3
	sync
	isync
	lwz		r4,  0x090c(r1)
	mfmsr	r8
	andi.	r8, r8,  0x10cf
	mtmsr	r8
	isync
	mr		r28, r3
	lwz		r9,  0x0908(r1)
	bl		rtas_make_actual_call
	mfsprg	r1, 0
	lwz		r6, -0x0014(r1)
	clrlwi	r29, r28,  0x14
	subfic	r29, r29,  0x1000
	lhz		r27,  0x0f4a(r1)

kcRTASDispatch_0x190
	subf.	r29, r27, r29
	dcbf	r29, r28
	sync
	icbi	r29, r28
	bge+	kcRTASDispatch_0x190
	sync
	isync
	lwz		r8,  0x0000(r6)
	lwz		r11,  0x00a4(r6)
	mr		r7, r8
	andi.	r8, r11,  0x900
	lwz		r8,  0x0004(r6)
	lwz		r13,  0x00dc(r6)
	stw		r8, EWA.Enables(r1)
	lwz		r8,  0x00d4(r6)
	lwz		r12,  0x00ec(r6)
	mtxer	r8
	lwz		r8,  0x00f4(r6)
	lwz		r10,  0x00fc(r6)
	mtctr	r8
	bnel+	major_0x03e18_0x8
	lwz		r8,  0x010c(r6)
	stw		r8,  0x0004(r1)
	lwz		r2,  0x0114(r6)
	lwz		r3,  0x011c(r6)
	lwz		r4,  0x0124(r6)
	lwz		r8,  0x0134(r6)
	lwz		r5,  0x012c(r6)
	stw		r8,  0x0018(r1)
	lwz		r14,  0x0174(r6)
	lwz		r15,  0x017c(r6)
	lwz		r16,  0x0184(r6)
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
	_AssertAndRelease	PSA.RTASLock, scratch=r8
	li		r3,  0x00
	b		IntReturn

rtas_make_actual_call
	mtctr	r9
	bctr
