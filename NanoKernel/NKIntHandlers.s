;	AUTO-GENERATED SYMBOL LIST

########################################################################

;	Increment the Sys/Alt CPU clocks, and the Dec-int counter
	_align 6
IntDecrementerSystem
	mfsprg	r1, 0
	stmw	r2, EWA.r2(r1)
	mfdec	r31
	lwz		r30, KDP.OtherContextDEC(r1)

DecCommon ; DEC for Alternate=r30, System=r31
	mfxer	r29							; we will do carries

	lwz		r28, KDP.ProcInfo.DecClockRateHz(r1)
	stw		r28, KDP.OtherContextDEC(r1)
	mtdec	r28							; reset Sys and Alt decrementers

	subf	r31, r31, r28				; System ticks actually elapsed
	subf	r30, r30, r28				; Alternate ticks actually elapsed

	lwz		r28, KDP.NKInfo.SysContextCpuTime+4(r1)
	lwz		r27, KDP.NKInfo.SysContextCpuTime(r1)
	addc	r28, r28, r31
	addze	r27, r27
	stw		r28, KDP.NKInfo.SysContextCpuTime+4(r1)
	stw		r27, KDP.NKInfo.SysContextCpuTime(r1)

	lwz		r28, KDP.NKInfo.AltContextCpuTime+4(r1)
	lwz		r27, KDP.NKInfo.AltContextCpuTime(r1)
	addc	r28, r28, r30
	addze	r27, r27
	stw		r28, KDP.NKInfo.AltContextCpuTime+4(r1)
	stw		r27, KDP.NKInfo.AltContextCpuTime(r1)

	mtxer	r29

	stw		r0, EWA.r0(r1)
	mfsprg	r31, 1
	stw		r31, EWA.r1(r1)

	lwz		r31, KDP.NKInfo.DecrementerIntCount(r1)
	addi	r31, r31, 1
	stw		r31, KDP.NKInfo.DecrementerIntCount(r1)

	lmw		r27, EWA.r27(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi

IntDecrementerAlternate
	mfsprg	r1, 0
	stmw	r2, EWA.r2(r1)
	lwz		r31, KDP.OtherContextDEC(r1)
	mfdec	r30
	b		DecCommon

########################################################################

	_align 6
IntDSI
	mfsprg	r1, 0
	stmw	r2, EWA.r2(r1)
	mfsprg	r11, 1
	stw		r0, EWA.r0(r1)
	stw		r11, EWA.r1(r1)

	mfsrr0	r10
	mfsrr1	r11
	mfsprg	r12, 2
	mfcr	r13

	mfmsr	r14
	_bset	r15, r14, bitMsrDR
	mtmsr	r15
	lwz		r27, 0(r10)
	mtmsr	r14

EmulateDataAccess
	rlwinm.	r18, r27, 18, 25, 29			; r16 = 4 * rA (r0 wired to 0)
	lwz		r25, KDP.PA_FDP(r1)
	li		r21, 0
	beq		@r0
	lwzx	r18, r1, r18
@r0
	andis.	r26, r27, 0xec00
	lwz		r16, KDP.Flags(r1)
	mfsprg	r24, 3
	rlwinm	r17, r27, 0, 6, 15
	rlwimi	r16, r16, 27, 26, 26
	bge		@low_opcode

	rlwimi	r25, r27, 7, 26, 29				; opcode >= 32
	rlwimi	r25, r27, 12, 25, 25
	lwz		r26, 0xb80(r25)
	extsh	r23, r27
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	mtcr	r26
	add		r18, r18, r23
	rlwimi	r17, r26, 6, 26, 5
	blr

@low_opcode									; opcode <= 31
	rlwimi	r25, r27, 27, 26, 29
	rlwimi	r25, r27, 0, 25, 25
	rlwimi	r25, r27, 6, 23, 24
	lwz		r26, 0x800(r25)
	rlwinm	r23, r27, 23, 25, 29
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	mtcr	r26
	lwzx	r23, r1, r23
	rlwimi	r17, r26, 6, 26, 5
	add		r18, r18, r23
	bclr	BO_IF_NOT, 13
	neg		r23, r23
	add		r18, r18, r23
	blr

########################################################################

	_align 6
IntAlignment
	mfsprg	r1, 0
	stmw	r2, EWA.r2(r1)

	lwz		r11, KDP.NKInfo.MisalignmentCount(r1)
	addi	r11, r11, 1
	stw		r11, KDP.NKInfo.MisalignmentCount(r1)

	mfsprg	r11, 1
	stw		r0, EWA.r0(r1)
	stw		r11, EWA.r1(r1)

	mfsrr0	r10
	mfsrr1	r11
	mfsprg	r12, 2
	mfcr	r13
	mfsprg	r24, 3
	mfdsisr	r27
	mfdar	r18

	extrwi.	r21, r27, 2, 15			; evaluate hi two bits of XO (or 0 for d-form?)
	lwz		r25, KDP.PA_FDP(r1)
	rlwinm	r17, r27, 16, 0x03FF0000
	lwz		r16, KDP.Flags(r1)
	rlwimi	r25, r27, 24, 23, 29	; add constant fields from dsisr (*4) to FDP
	rlwimi	r16, r16, 27, 26, 26	; copy FlagSE to Flag26
	bne		@X_form

	;	D- or DS-form (immediate-indexed) instruction
	lwz		r26, FDP_TableBase + 4*(0x40 + 0x20)(r25)	; use upper quarter of table
	mfmsr	r14
	rlwimi	r25, r26, 26, 22, 29	; third byte of lookup value is a /4 code offset in FDP
	mtlr	r25						; so get ready to go there
	_bset	r15, r14, bitMsrDR
	mtcr	r26
	rlwimi	r17, r26, 6, 26, 5		; wrap some shite around the register values
	blr

@X_form
	;	X-form (register-indexed) instruction
	lwz		r26, FDP_TableBase(r25)
	mfmsr	r14
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	_bset	r15, r14, bitMsrDR
	mtcr	r26
	rlwimi	r17, r26, 6, 26, 5
	bclr	BO_IF_NOT, 12
	mtmsr	r15
	lwz		r27, 0(r10)
	mtmsr	r14
	blr

########################################################################

; FDP GOES HERE (0xC00)! (just include it as a file?)
; there are some big mistakes in the labels below!
	_align 10
FDP
	dcb.l	(0x1874-0xC00)/4, 0x46445020 ; 'FDP '

########################################################################

IntISI
	bl		LoadInterruptRegisters

	andis.	r8, r11, 0x4020			; what the hell are these MSR bits?
	beq		major_0x039dc_0x14

	stmw	r14, EWA.r14(r8)
	mr		r27, r10
	bl		PopulateHTAB
	bne		@not_in_htab

	mfsprg	r24, 3
	mfmsr	r14
	_bset	r15, r14, bitMsrDR
	addi	r23, r1, KDP.VecBaseMemRetry
	mtsprg	3, r23
	mr		r19, r10
	mtmsr	r15
	lbz		r23, 0(r19)
	sync
	mtmsr	r14
	mtsprg	3, r24
	lmw		r14, EWA.r14(r8)
	b		IntReturn

@not_in_htab
	lmw		r14, EWA.r14(r8)
	li		r8, ecInstPageFault
	blt		Exception
	li		r8, ecInstInvalidAddress
	b		Exception

major_0x039dc_0x14
	andis.	r8, r11, 0x800
	li		r8, ecInstSupAccessViolation
	bne		Exception
	li		r8, ecInstHardwareFault
	b		Exception

########################################################################

IntMachineCheck
	bl		LoadInterruptRegisters
	li		r8, ecMachineCheck
	b		Exception
