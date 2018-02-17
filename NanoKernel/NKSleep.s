;	Implements two MPCalls that seem to have something to do with COHGs



;	Make conditional calls easier
Local_Panic set *
	b		panic

Local_ReturnParamErrFromMPCall
	b		ReturnParamErrFromMPCall

Local_ReturnInsufficientResourcesErrFromMPCall
	b		ReturnMPCallOOM

Local_CommonMPCallReturnPath
	b		CommonMPCallReturnPath



	DeclareMPCall	102, MPCall_102

MPCall_102	;	OUTSIDE REFERER
	mfsprg	r9, 0
	lwz		r8, EWA.CPUBase + CPU.LLL + LLL.Freeform(r9)
	lwz		r9, CoherenceGroup.ScheduledCpuCount(r8)
	cmpwi	r9, 1
	bgt+	Local_ReturnInsufficientResourcesErrFromMPCall
	bl		CoherenceFunc
	mr		r4, r8
	mr		r5, r9
	b		ReturnZeroFromMPCall



	DeclareMPCall	103, MPCall_103

MPCall_103	;	OUTSIDE REFERER
	mfsprg	r9, 0
	lwz		r8, EWA.CPUBase + CPU.LLL + LLL.Freeform(r9)
	lwz		r9, CoherenceGroup.ScheduledCpuCount(r8)
	cmpwi	r9, 1
	bgt+	Local_ReturnInsufficientResourcesErrFromMPCall

	clrlwi.	r8, r5, 20
	bne+	Local_ReturnParamErrFromMPCall
	bl		CoherenceFunc
	cmpw	r3, r8
	blt+	Local_ReturnParamErrFromMPCall
	cmpw	r4, r9
	blt+	Local_ReturnParamErrFromMPCall
	bl		PagingFlushTLB
	mfsprg	r9, 0
	mfxer	r8
	stw		r13,  0x00dc(r6)
	stw		r8,  0x00d4(r6)
	stw		r12,  0x00ec(r6)
	mfctr	r8
	stw		r10,  0x00fc(r6)
	stw		r8,  0x00f4(r6)

	mfpvr	r8
	rlwinm.	r8, r8, 0, 0, 14
	bne-	@not_601
	mfspr	r8, mq
	stw		r8, ContextBlock.MQ(r6)
@not_601

	lwz		r8, EWA.r1(r9)
	stw		r8, ContextBlock.r1(r6)
	stw		r2, ContextBlock.r2(r6)
	stw		r3, ContextBlock.r3(r6)
	andi.	r8, r11, MSR_FP
	stw		r4, ContextBlock.r4(r6)
	lwz		r8, EWA.r6(r9)
	stw		r5, ContextBlock.r5(r6)
	stw		r8, ContextBlock.r6(r6)
	bnel+	Save_f0_f31
	rlwinm.	r8, r7,  0, 12, 12 ; flags
	bnel+	Save_v0_v31

	lwz		r3, ContextBlock.r3(r6)
	lwz		r4, ContextBlock.r4(r6)
	lwz		r5, ContextBlock.r5(r6)
	
	stw		r11,ContextBlock.MSR(r6)
	mr		r27, r5
	addi	r29, r1, 800
	bl		PagingFunc3
	beq+	Local_ReturnInsufficientResourcesErrFromMPCall
	rlwimi	r27, r31,  0,  0, 19
	mr		r17, r27
	addi	r15, r17,  0x34
	srwi	r3, r3, 12

MPCall_103_0xc8
	mr		r27, r5
	addi	r29, r1, 800
	bl		PagingFunc3
	beq+	Local_ReturnInsufficientResourcesErrFromMPCall
	rlwimi	r27, r31,  0,  0, 19
	stwu	r27,  0x0004(r15)
	addi	r3, r3, -0x01
	addi	r5, r5,  0x1000
	cmpwi	r3,  0x00
	bge+	MPCall_103_0xc8
	addi	r15, r15,  0x04
	subf	r15, r17, r15
	stw		r15,  0x0034(r17)
	mfsprg	r15, 0
	stw		r15,  0x0024(r17)
	mfsprg	r8, 3
	stw		r8,  0x0028(r17)

MPCall_103_0x10c
	mftbu	r8
	mftb	r9,  0x10c
	mftbu	r16
	cmpw	r16, r8
	bne-	MPCall_103_0x10c
	stw		r8, -0x0278(r15)
	stw		r9, -0x0274(r15)
	mr		r29, r17
	li		r16,  0x06
	stw		r16, -0x0238(r15)
	lhz		r16, EWA.CPUIndex(r15)
	stw		r16, -0x0234(r15)
	li		r8,  0x02

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	mr		r17, r29
	mfsdr1	r8
	stw		r8,  0x002c(r17)
	rlwinm	r9, r8, 16,  7, 15
	cntlzw	r18, r9
	li		r9, -0x01
	srw		r9, r9, r18
	addi	r9, r9,  0x01
	stw		r9,  0x000c(r17)
	rlwinm	r8, r8,  0,  0, 15
	stw		r8,  0x0010(r17)
	lis		r8,  0x00
	ori		r8, r8,  0xc000
	stw		r8,  0x0018(r17)
	lis		r9,  0x00
	ori		r9, r9,  0xa000
	subf	r8, r9, r1
	stw		r8,  0x001c(r17)
	addi	r9, r1, 120
	lis		r31,  0x00
	li		r14,  0x00
	lwz		r29,  0x0034(r17)
	add		r29, r29, r17

MPCall_103_0x1a0
	lwzu	r30,  0x0008(r9)

MPCall_103_0x1a4
	lwz		r18,  0x0004(r30)
	lhz		r15,  0x0000(r30)
	andi.	r19, r18,  0xe00
	lhz		r16,  0x0002(r30)
	cmplwi	r19,  0xc00
	bne-	MPCall_103_0x1dc
	addi	r16, r16,  0x01
	slwi	r16, r16,  2
	stw		r16,  0x0000(r29)
	rlwinm	r18, r18, 22,  0, 29
	stw		r18,  0x0004(r29)
	addi	r29, r29,  0x0c
	addi	r14, r14,  0x01
	b		MPCall_103_0x1fc

MPCall_103_0x1dc
	cmpwi	r15,  0x00
	bne-	MPCall_103_0x1fc
	cmplwi	r16,  0xffff
	bne-	MPCall_103_0x1fc
	addis	r31, r31,  0x1000
	cmpwi	r31,  0x00
	bne+	MPCall_103_0x1a0
	b		MPCall_103_0x204

MPCall_103_0x1fc
	addi	r30, r30,  0x08
	b		MPCall_103_0x1a4

MPCall_103_0x204
	lwz		r16, -0x0aa0(r1)

MPCall_103_0x208
	lwz		r31,  0x0000(r16)
	add		r18, r31, r16
	lwz		r19,  0x0000(r18)
	addi	r31, r31,  0x18
	stw		r31,  0x0000(r29)
	stw		r16,  0x0004(r29)
	addi	r29, r29,  0x0c
	addi	r14, r14,  0x01
	cmpwi	r19,  0x00
	beq-	MPCall_103_0x238
	add		r16, r19, r18
	b		MPCall_103_0x208

MPCall_103_0x238
	addi	r19, r1, -0x450
	lwz		r31, -0x0448(r1)

MPCall_103_0x240
	cmpw	r31, r19
	beq-	MPCall_103_0x264
	li		r18,  0x10
	stw		r18,  0x0000(r29)
	stw		r31,  0x0004(r29)
	addi	r29, r29,  0x0c
	addi	r14, r14,  0x01
	lwz		r31,  0x0008(r31)
	b		MPCall_103_0x240

MPCall_103_0x264
	stw		r14,  0x0030(r17)
	lwz		r30,  0x0034(r17)
	add		r30, r30, r17

MPCall_103_0x270
	subf	r8, r17, r29
	stw		r8,  0x0008(r30)
	lwz		r24,  0x0004(r30)
	mr		r25, r8
	lwz		r26,  0x0000(r30)
	add		r29, r29, r26
	bl		AnotherCoherenceFunc
	addi	r30, r30,  0x0c
	addi	r14, r14, -0x01
	cmpwi	r14,  0x00
	bne+	MPCall_103_0x270
	subf	r8, r17, r29
	stw		r8,  0x0020(r17)
	lwz		r24,  0x001c(r17)
	mr		r25, r8
	lwz		r26,  0x0018(r17)
	add		r29, r29, r26
	bl		AnotherCoherenceFunc
	subf	r8, r17, r29
	stw		r8,  0x0014(r17)
	lwz		r24,  0x0010(r17)
	mr		r25, r8
	lwz		r26,  0x000c(r17)
	add		r29, r29, r26
	bl		AnotherCoherenceFunc
	bl		LoadStateRestoreFunc
	mflr	r9
	stw		r9,  0x0000(r17)
	lwz		r8, -0x0900(r1)
	stw		r8,  0x0008(r17)
	li		r8,  0x00
	stw		r8,  0x0004(r17)
	mfsprg	r15, 0
	li		r16,  0x11
	stw		r16, -0x0238(r15)
	lhz		r16, EWA.CPUIndex(r15)
	stw		r16, -0x0234(r15)
	li		r8,  0x02

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	li		r3,  0x00
	b		Local_CommonMPCallReturnPath



LoadStateRestoreFunc
	blrl

	mr		r17, r3
	lwz		r24,  0x0014(r17)
	lwz		r25,  0x0010(r17)
	lwz		r26,  0x000c(r17)
	bl		YetAnotherCoherenceFunc
	lwz		r24,  0x002c(r17)
	mtsdr1	r24
	lwz		r24,  0x0020(r17)
	lwz		r25,  0x001c(r17)
	lwz		r26,  0x0018(r17)
	bl		YetAnotherCoherenceFunc
	lwz		r14,  0x0030(r17)
	lwz		r30,  0x0034(r17)
	add		r30, r30, r17

RestoreKernelState_0x38
	lwz		r24,  0x0008(r30)
	lwz		r25,  0x0004(r30)
	lwz		r26,  0x0000(r30)
	bl		YetAnotherCoherenceFunc
	addi	r30, r30,  0x0c
	addi	r14, r14, -0x01
	cmpwi	r14,  0x00
	bne+	RestoreKernelState_0x38
	lwz		r16,  0x0024(r17)
	mtsprg	0, r16
	lwz		r8,  0x0028(r17)
	mtsprg	3, r8
	lwz		r1, -0x0004(r16)
	lwz		r6, -0x0014(r16)
	lwz		r7, -0x0010(r16)
	li		r8, -0x01
	stw		r8,  0x0004(r17)
	lwz		r8, -0x0278(r16)
	lwz		r9, -0x0274(r16)
	li		r16,  0x01
	mttb	r16
	mttbu	r8
	mttb	r9
	mtdec	r16
	_log	'Resuming saved kernel state^n'
	lwz		r8,  0x00d4(r6)
	lwz		r13,  0x00dc(r6)
	mtxer	r8
	lwz		r12,  0x00ec(r6)
	lwz		r8,  0x00f4(r6)
	lwz		r10,  0x00fc(r6)
	mtctr	r8
	lwz		r11,  0x00a4(r6)
	mfpvr	r8
	rlwinm.	r8, r8,  0,  0, 14
	bne-	RestoreKernelState_0xf8
	lwz		r8,  0x00c4(r6)
	DIALECT	POWER
	mtmq	r8
	DIALECT	PowerPC

RestoreKernelState_0xf8
	lwz		r4, -0x0020(r1)
	li		r2,  0x01
	sth		r2,  0x0910(r1)
	li		r2, -0x01
	stw		r2,  0x0912(r1)
	stw		r2,  0x0f90(r4)
	xoris	r2, r2,  0x100
	stw		r2,  0x0f8c(r4)
	li		r2,  0x00
	stw		r2,  0x0f28(r4)
	stw		r2,  0x0f2c(r4)
	lwz		r2,  0x0114(r6)
	lwz		r4,  0x0124(r6)
	lwz		r5,  0x012c(r6)
	lwz		r29,  0x00d8(r6)
	cmpwi	r29,  0x00
	lwz		r8,  0x0210(r29)
	beq-	RestoreKernelState_0x144
	mtspr	vrsave, r8

RestoreKernelState_0x144
	bl		PagingFlushTLB
	addi	r29, r1,  0x5e0
	bl		PagingFunc2AndAHalf
	mfsprg	r15, 0
	lwz		r8, -0x001c(r15)
	li		r9,  0x00
	bl		SetSpaceSRsAndBATs
	isync
	mfsprg	r15, 0
	li		r16,  0x07
	stw		r16, -0x0238(r15)
	lhz		r16, EWA.CPUIndex(r15)
	stw		r16, -0x0234(r15)
	li		r8,  0x02

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	mfsprg	r15, 0
	li		r16,  0x11
	stw		r16, -0x0238(r15)
	lhz		r16, EWA.CPUIndex(r15)
	stw		r16, -0x0234(r15)
	li		r8,  0x02

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	li		r3,  0x00
	b		Local_CommonMPCallReturnPath



;	Xrefs:
;	MPCall_102
;	MPCall_103
;	AnotherCoherenceFunc
;	YetAnotherCoherenceFunc

CoherenceFunc	;	OUTSIDE REFERER
	li		r24,  0x00
	mfsdr1	r16
	rlwinm	r16, r16, 16,  7, 15
	cntlzw	r17, r16
	li		r16, -0x01
	srw		r16, r16, r17
	addi	r8, r16,  0x01
	addi	r9, r1, 120
	lis		r31,  0x00
	li		r19,  0x00
	li		r14,  0x00

CoherenceFunc_0x2c
	lwzu	r17,  0x0008(r9)

CoherenceFunc_0x30
	lwz		r18,  0x0004(r17)
	lhz		r15,  0x0000(r17)
	andi.	r18, r18,  0xe00
	lhz		r16,  0x0002(r17)
	cmplwi	r18,  0xc00
	bne-	CoherenceFunc_0x58
	addi	r16, r16,  0x01
	add		r19, r19, r16
	addi	r14, r14,  0x01
	b		CoherenceFunc_0x78

CoherenceFunc_0x58
	cmpwi	r15,  0x00
	bne-	CoherenceFunc_0x78
	cmplwi	r16,  0xffff
	bne-	CoherenceFunc_0x78
	addis	r31, r31,  0x1000
	cmpwi	r31,  0x00
	bne+	CoherenceFunc_0x2c
	b		CoherenceFunc_0x80

CoherenceFunc_0x78
	addi	r17, r17,  0x08
	b		CoherenceFunc_0x30

CoherenceFunc_0x80
	slwi	r19, r19,  2
	add		r8, r8, r19
	cmpwi	r14,  0x00
	beq+	Local_ReturnInsufficientResourcesErrFromMPCall
	mulli	r9, r14,  0x0c
	add		r8, r8, r9
	add		r24, r24, r9
	li		r9,  0x00
	li		r14,  0x00
	lwz		r16, -0x0aa0(r1)

CoherenceFunc_0xa8
	lwz		r17,  0x0000(r16)
	add		r18, r17, r16
	lwz		r19,  0x0000(r18)
	add		r9, r9, r17
	addi	r9, r9,  0x18
	addi	r14, r14,  0x01
	cmpwi	r19,  0x00
	add		r16, r19, r18
	beq-	CoherenceFunc_0xd0
	b		CoherenceFunc_0xa8

CoherenceFunc_0xd0
	addi	r16, r1, -0x450
	lwz		r18, -0x0448(r1)

CoherenceFunc_0xd8
	cmpw	r18, r16
	beq-	CoherenceFunc_0xf0
	addi	r9, r9,  0x10
	addi	r14, r14,  0x01
	lwz		r18,  0x0008(r18)
	b		CoherenceFunc_0xd8

CoherenceFunc_0xf0
	add		r8, r8, r9
	mulli	r9, r14,  0x0c
	add		r8, r8, r9
	add		r24, r24, r9
	lis		r9,  0x00
	ori		r9, r9,  0xc000
	add		r8, r8, r9
	lis		r9,  0x00
	ori		r9, r9,  0x3c
	add		r8, r8, r9
	add		r24, r24, r9
	srwi	r9, r8, 12
	slwi	r9, r9,  2
	addi	r9, r9,  0x04
	add		r8, r8, r9
	add		r24, r24, r9
	mr		r9, r24
	blr

CoherenceFunc_0x138	;	OUTSIDE REFERER
	srwi	r23, r28, 12
	slwi	r23, r23,  2
	add		r23, r23, r17
	lwz		r23,  0x0038(r23)
	rlwimi	r23, r28,  0, 20, 31
	blr



;	Xrefs:
;	MPCall_103

AnotherCoherenceFunc	;	OUTSIDE REFERER
	cmpwi	r26,  0x00
	beqlr-
	mflr	r22
	addi	r24, r24, -0x01
	mr		r28, r25

AnotherCoherenceFunc_0x14
	bl		CoherenceFunc_0x138
	clrlwi	r25, r23,  0x14
	subfic	r25, r25,  0x1000
	cmplw	r25, r26
	blt-	AnotherCoherenceFunc_0x2c
	mr		r25, r26

AnotherCoherenceFunc_0x2c
	mr		r19, r23
	mr		r20, r25
	addi	r23, r23, -0x01
	mtctr	r25

AnotherCoherenceFunc_0x3c
	lbzu	r27,  0x0001(r24)
	stbu	r27,  0x0001(r23)
	bdnz+	AnotherCoherenceFunc_0x3c
	bl		YetAnotherCoherenceFunc_0x64
	subf	r26, r25, r26
	add		r28, r28, r25
	cmpwi	r26,  0x00
	bne+	AnotherCoherenceFunc_0x14
	mtlr	r22
	blr



;	Xrefs:
;	RestoreKernelState
;	AnotherCoherenceFunc

YetAnotherCoherenceFunc	;	OUTSIDE REFERER
	cmpwi	r26,  0x00
	beqlr-
	mr		r19, r25
	mr		r20, r26
	mflr	r22
	addi	r25, r25, -0x01
	mr		r28, r24

YetAnotherCoherenceFunc_0x1c
	bl		CoherenceFunc_0x138
	clrlwi	r24, r23,  0x14
	subfic	r24, r24,  0x1000
	cmplw	r24, r26
	blt-	YetAnotherCoherenceFunc_0x34
	mr		r24, r26

YetAnotherCoherenceFunc_0x34
	addi	r23, r23, -0x01
	mtctr	r24

YetAnotherCoherenceFunc_0x3c
	lbzu	r27,  0x0001(r23)
	stbu	r27,  0x0001(r25)
	bdnz+	YetAnotherCoherenceFunc_0x3c
	add		r28, r28, r24
	subf	r26, r24, r26
	cmpwi	r26,  0x00
	bne+	YetAnotherCoherenceFunc_0x1c
	bl		YetAnotherCoherenceFunc_0x64
	mtlr	r22
	blr

YetAnotherCoherenceFunc_0x64	;	OUTSIDE REFERER
	sync
	isync
	lhz		r21,  0x0f4a(r1)
	addi	r15, r21, -0x01
	add		r20, r19, r20
	add		r20, r20, r15
	neg		r15, r21
	and		r19, r19, r15
	and		r20, r20, r15

YetAnotherCoherenceFunc_0x88
	dcbst	0, r19
	sync
	icbi	0, r19
	add		r19, r19, r21
	cmpw	r19, r20
	blt+	YetAnotherCoherenceFunc_0x88
	sync
	isync
	blr
