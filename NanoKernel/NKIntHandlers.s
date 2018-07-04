;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKAddressSpaces
;	    FindAreaAbove
;	    SpaceGetPagePLE
;	    SpaceL2PUsingBATs
;	  NKCache
;	    FlushL1CacheUsingMSSCR0
;	  NKConsoleLog
;	    printw
;	  NKExceptions
;	    Exception
;	    ExceptionMemRetried
;	    IntReturn
;	    IntReturnToSystemContext
;	  NKFloatInts
;	    major_0x03e18
;	  NKIntMisc
;	    IntReturnFromSIGP
;	  NKPaging
;	    PagingFunc1
;	    PagingL2PWithBATs
;	  NKScheduler
;	    SchFiddlePriorityShifty
;	    SchRestoreStartingAtR14
;	    SchSaveStartingAtR14
;	  NKTimers
;	    TimerDispatch
;	  NKTranslation
;	    FDP_0DA0
;	EXPORTS:
;	  IntAlignment (=> NKInit)
;	  IntDSI (=> NKInit)
;	  IntDecrementer (=> NKInit)
;	  IntISI (=> NKInit)
;	  IntMachineCheck (=> NKInit)
;	  LoadInterruptRegisters (=> NKIntMisc, NKTranslation)
;	  MaskedInterruptTaken (=> NKIntMisc)
;	  MemRetryDSI (=> NKInit)
;	  MemRetryMachineCheck (=> NKInit)
;	  PIHDSI (=> NKInit)
;	  kcReturnFromException (=> NKInit)
;	  major_0x03324 (=> NKTranslation)
;	  major_0x03548 (=> NKTranslation)
;	  save_all_registers (=> NKIntMisc)



	align	kIntAlign

IntDecrementer	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	lwz		r8, KDP.OldKDP(r1)
	rlwinm.	r9, r11,  0, 16, 16
	cmpwi	cr1, r8,  0x00
	beq		MaskedInterruptTaken
	beq		cr1, IntDecrementer_0x54

	stw		r16, ContextBlock.r16(r6)
	stw		r17, ContextBlock.r17(r6)
	stw		r18, ContextBlock.r18(r6)
	stw		r25, ContextBlock.r25(r6)

	bl		SchFiddlePriorityShifty
	ble		IntDecrementer_0x48

	lwz		r8, PSA.CriticalReadyQ + ReadyQueue.Timecake + 4(r1)
	mtspr	dec, r8

	lwz		r16, ContextBlock.r16(r6)
	lwz		r17, ContextBlock.r17(r6)
	lwz		r18, ContextBlock.r18(r6)
	b		IntReturn

IntDecrementer_0x48
	lwz		r16,  0x0184(r6)
	lwz		r17,  0x018c(r6)
	lwz		r18,  0x0194(r6)

IntDecrementer_0x54
;	r6 = ewa
	bl		SchSaveStartingAtR14
;	r8 = sprg0 (not used by me)


	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8,  0x0e8c(r1)
	addi	r8, r8,  0x01
	stw		r8,  0x0e8c(r1)
	bl		TimerDispatch
	_AssertAndRelease	PSA.SchLock, scratch=r8

	bl		SchRestoreStartingAtR14
	b		IntReturn



###              ######   #####  ### 
 #  #    # ##### #     # #     #  #  
 #  ##   #   #   #     # #        #  
 #  # #  #   #   #     #  #####   #  
 #  #  # #   #   #     #       #  #  
 #  #   ##   #   #     # #     #  #  
### #    #   #   ######   #####  ### 

;	Kick it to the FDP-associated MemRetryDSI

	align	kIntAlign

IntDSI

	mfsprg	r1, 0
	stmw	r2, EWA.r2(r1)
	mfsprg	r11, 1

	stw		r0, EWA.r0(r1)
	stw		r11, EWA.r1(r1) ; Why?

	li		r0, 0

	mfspr	r10, srr0
	mfspr	r11, srr1
	mfsprg	r12, 2
	mfcr	r13
	mfsprg	r24, 3

	lwz		r16, EWA.Flags(r1)
	lwz		r1, EWA.PA_KDP(r1)

	mfspr	r26, dsisr

	;	Activate the Translation vecTable, and test DSISR bit 5
	;	("Set if the access is due to a lwarx, ldarx, stwcx., or stdcx.
	;	instruction that addresses memory that is Write Through
	;	Required or Caching Inhibited; otherwise cleared")
	addi	r23, r1, KDP.VecBaseMemRetry
	andis.	r28, r26, 0x400			; test bit 5 (see cmt above)
	mtsprg	3, r23

	mfmsr	r14
	bne		HandleDSIDueToIllegalSyncPrimitive

	_bset	r15, r14, 27			; temp set MSR[DR]
	mtmsr	r15
	isync

	lwz		r27, 0(r10)				; get instruction (should be fine!)

	mtmsr	r14						; restore MSR
	isync



major_0x03324	;	OUTSIDE REFERER
	rlwinm.	r18, r27, 18, 25, 29
	lwz		r25,  0x0650(r1)
	li		r21,  0x00
	mfsprg	r1, 0
	beq		major_0x03324_0x18
	lwzx	r18, r1, r18

major_0x03324_0x18
	andis.	r26, r27,  0xec00
	lwz		r16, EWA.Flags(r1)
	rlwinm	r17, r27,  0,  6, 15
	rlwimi	r16, r16, 27, 26, 26
	bge		major_0x03324_0x58
	rlwimi	r25, r27,  7, 26, 29
	rlwimi	r25, r27, 12, 25, 25
	lwz		r26,  0x0b80(r25)
	extsh	r23, r27
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	mtcr	r26
	add		r18, r18, r23
	crclr	cr5_so
	rlwimi	r17, r26,  6, 26,  5
	blr

major_0x03324_0x58
	rlwimi	r25, r27, 27, 26, 29
	rlwimi	r25, r27,  0, 25, 25
	rlwimi	r25, r27,  6, 23, 24
	rlwimi	r25, r27,  4, 22, 22
	lwz		r26,  0x0800(r25)
	rlwinm	r23, r27, 23, 25, 29
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	mtcr	r26
	lwzx	r23, r1, r23
	crclr	cr5_so
	rlwimi	r17, r26,  6, 26,  5
	add		r18, r18, r23
	bclr	BO_IF_NOT, 13
	neg		r23, r23
	add		r18, r18, r23
	blr



HandleDSIDueToIllegalSyncPrimitive	;	OUTSIDE REFERER

	ori		r15, r14,  0x10
	mr		r28, r16
	mfspr	r18, dar
	mfspr	r19, dsisr
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync
	mtsprg	3, r24
	lwz		r1, -0x0004(r1)
	mr		r31, r19
	mr		r8, r18
	li		r9,  0x00
	bl		SpaceL2PUsingBATs ; LogicalPage *r8, MPAddressSpace *r9 // PhysicalPage *r17
	mr		r16, r28
	crset	cr3_so
	mfsprg	r1, 0
	beq		major_0x03324_0x12c
	mr		r18, r8
	rlwinm	r28, r27, 13, 25, 29
	andis.	r9, r31,  0x200
	rlwimi	r18, r17,  0,  0, 19
	beq		major_0x03324_0x118
	lwzx	r31, r1, r28
	stwcx.	r31, 0, r18
	sync
	dcbf	0, r18
	mfcr	r31
	rlwimi	r13, r31,  0,  0,  3
	b		FDP_0da0

major_0x03324_0x118
	lwarx	r31, 0, r18
	sync
	dcbf	0, r18
	stwx	r31, r1, r28
	b		FDP_0da0

major_0x03324_0x12c
	subi	r10, r10, 4
	b		FDP_0da0



;	This int handler is our best foothold into the FDP!

	align	kIntAlign

IntAlignment	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r2,  0x0008(r1)
	mfsprg	r11, 1
	stw		r0,  0x0000(r1)
	stw		r11,  0x0004(r1)
	li		r0,  0x00

	lwz		r11, EWA.PA_CurTask(r1)
	lwz		r16, EWA.Flags(r1)
	lwz		r21, Task.Flags(r11)
	lwz		r1, -0x0004(r1)		;	wha???

	lwz		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.MisalignmentCount(r1)
	addi	r11, r11, 1
	stw		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.MisalignmentCount(r1)

	mfspr	r10, srr0
	mfspr	r11, srr1
	mfsprg	r12, 2
	mfcr	r13
	mfsprg	r24, 3
	mfspr	r27, dsisr
	mfspr	r18, dar

	rlwinm.	r21, r21, 0, Task.kFlagTakesAllExceptions, Task.kFlagTakesAllExceptions

	addi	r23, r1, KDP.VecBaseMemRetry

	bne		major_0x03548_0x20

	;	DSISR for misaligned X-form instruction:

	;	(0) 0 (14)||(15) 29:30 (16)||(17) 25 (17)||(18) 21:24 (21)||(22) rD (26)||(27) rA? (31)

	;	DSISR for misaligned D-form instruction:
	
	;	(0)        zero        (16)||(17)  5 (17)||(18)  1:4  (21)||(22) rD (26)||(27) rA? (31)

FDP_TableBase		equ		0xa00

	;	Virtual PC might put the thing in MSR_LE mode
	rlwinm.	r21, r11, 0, MSR_LEbit, MSR_LEbit			;	msr bits in srr1

	;	Get the FDP and F.O. if we were in MSR_LE mode
	lwz		r25,  KDP.PA_FDP(r1)
	bne		major_0x03548_0x20


	rlwinm.	r21, r27, 17, 30, 31	; evaluate hi two bits of XO (or 0 for d-form?)

	rlwinm	r17, r27, 16,  6, 15	; save src and dest register indices in r17

	mfsprg	r1, 0

	rlwimi	r25, r27, 24, 23, 29	; add constant fields from dsisr (*4) to FDP


	rlwimi	r16, r16, 27, 26, 26	; AllCpuFeatures: copy bit 21 to bit 26

	bne		@regidx

	;	D-form (immediate-indexed) instruction
	lwz		r26,  FDP_TableBase + 4*(0x40 + 0x20)(r25)	; use upper quarter of table
	mfmsr	r14
	rlwimi	r25, r26, 26, 22, 29	; third byte of lookup value is a /4 code offset in FDP
	mtlr	r25						; so get ready to go there
	ori		r15, r14,  0x10
	mtcr	r26
	rlwimi	r17, r26,  6, 26,  5	; wrap some shite around the register values
	crclr	cr5_so
	blr

@regidx
	;	X-form (register-indexed) instruction
	lwz		r26,  FDP_TableBase(r25)
	mfmsr	r14
	mtsprg	3, r23
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	ori		r15, r14,  0x10
	mtcr	r26
	rlwimi	r17, r26,  6, 26,  5
	crclr	23						; unset bit 23 = cr5_so
	bclr	BO_IF_NOT, 12			; jump now if bit 12 is off

	;	if bit 12 was on, turn on paging and fetch the offending insn
	;	and also activate the Translation vector table
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync
	mtsprg	3, r24
	blr



major_0x03548	;	OUTSIDE REFERER
	sync
	mtmsr	r14
	isync
	mflr	r23
	icbi	0, r23
	sync
	isync
	blr

major_0x03548_0x20	;	OUTSIDE REFERER
	li		r8,  0x00
	lis		r17, -0x100
	mtcr	r8
	mr		r19, r18
	rlwimi	r17, r27,  7, 31, 31
	xori	r17, r17,  0x01
	li		r8, ecUnknown24
	b		ExceptionMemRetried



	align	kIntAlign

MemRetryDSI	;	OUTSIDE REFERER

	mfsprg	r1, 0
	mfspr	r31, dsisr
	mfspr	r27, dar
	andis.	r28, r31,  0xc030
	lwz		r1, -0x0004(r1)
	bne		MemRetryDSI_0x1c8
	mfspr	r30, srr1
	andi.	r28, r30,  0x4000
	mfsprg	r30, 0
	beq		MemRetryDSI_0x100
	stw		r8, -0x00e0(r30)
	stw		r9, -0x00dc(r30)
	mfcr	r8
	stw		r16, -0x00d8(r30)
	stw		r17, -0x00d4(r30)
	stw		r18, -0x00d0(r30)
	stw		r19, -0x00cc(r30)
	stw		r8, -0x00c8(r30)
	lwz		r8, -0x001c(r30)
	mr		r9, r27
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	lwz		r17,  0x0028(r8)
	cmplw	r27, r16
	cmplw	cr7, r27, r17
	blt		MemRetryDSI_0xe0
	bgt		cr7, MemRetryDSI_0xe0
	mr		r31, r8
	mr		r8, r27
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		MemRetryDSI_0xe0
	lwz		r8,  0x0000(r30)
	lwz		r16,  0x0098(r31)
	rlwinm	r28, r8,  0, 29, 30
	cmpwi	cr7, r28,  0x04
	cmpwi	r28,  0x02
	beq		cr7, MemRetryDSI_0xe0
	beq		MemRetryDSI_0xe0

MemRetryDSI_0x98
	addi	r17, r31,  0x90
	cmpw	r16, r17
	addi	r17, r16,  0x14
	beq		MemRetryDSI_0x158
	lwz		r9,  0x0010(r16)
	add		r9, r9, r17

MemRetryDSI_0xb0
	lwz		r18,  0x0000(r17)
	cmplw	cr7, r17, r9
	lwz		r19,  0x0004(r17)
	bgt		cr7, MemRetryDSI_0xd8
	cmplw	r27, r18
	cmplw	cr7, r27, r19
	blt		MemRetryDSI_0xd0
	ble		cr7, MemRetryDSI_0xe0

MemRetryDSI_0xd0
	addi	r17, r17,  0x08
	b		MemRetryDSI_0xb0

MemRetryDSI_0xd8
	lwz		r16,  0x0008(r16)
	b		MemRetryDSI_0x98

MemRetryDSI_0xe0
	mfsprg	r30, 0
	mfspr	r31, dsisr
	lwz		r8, -0x00e0(r30)
	lwz		r9, -0x00dc(r30)
	lwz		r16, -0x00d8(r30)
	lwz		r17, -0x00d4(r30)
	lwz		r18, -0x00d0(r30)
	lwz		r19, -0x00cc(r30)

MemRetryDSI_0x100
	andis.	r28, r31,  0x800
	addi	r29, r1, KDP.BATs + 0xa0
	bnel	PagingL2PWithBATs
	li		r28,  0x43
	and		r28, r31, r28
	cmpwi	cr7, r28,  0x43
	beql	IntPanicIsland
	mfsprg	r28, 2
	mtlr	r28
	bne		cr7, MemRetryDSI_0x144
	mfspr	r28, srr0
	addi	r28, r28,  0x04
	lwz		r26,  0x0e90(r1)
	mtspr	srr0, r28
	addi	r26, r26,  0x01
	stw		r26,  0x0e90(r1)
	b		MemRetryDSI_0x19c

MemRetryDSI_0x144
	andi.	r28, r31,  0x03
	li		r8, ecDataSupAccessViolation
	beq		ExceptionMemRetried
	li		r8, ecDataWriteViolation
	b		ExceptionMemRetried

MemRetryDSI_0x158
	mfsprg	r30, 0
	lwz		r16,  0x0f00(r1)
	lwz		r8, -0x00c8(r30)
	addi	r16, r16,  0x01
	mtcr	r8
	lwz		r9, -0x00dc(r30)
	stw		r16,  0x0f00(r1)
	lwz		r16, -0x00d8(r30)
	lwz		r17, -0x00d4(r30)
	lwz		r18, -0x00d0(r30)
	lwz		r19, -0x00cc(r30)
	lwz		r8, -0x00e0(r30)
	mfspr	r29, srr1
	mfsprg	r28, 2
	_bclr	r29, r29, 17
	mtlr	r28
	mtspr	srr1, r29

MemRetryDSI_0x19c
	mfsprg	r1, 1
	rlwinm	r26, r25, 30, 24, 31
	rfi
	dcb.b	32, 0


MemRetryDSI_0x1c8
	andis.	r28, r31,  0x8010
	bne		MemRetryMachineCheck_0x14c

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	bl		PagingFunc1
	_AssertAndRelease	PSA.HTABLock, scratch=r28
	mfsprg	r28, 2
	mtlr	r28
	beq		MemRetryDSI_0x19c
	li		r8, ecDataInvalidAddress
	bge		ExceptionMemRetried
	li		r8, ecDataPageFault
	b		ExceptionMemRetried



MemRetryMachineCheck	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mr		r28, r8

	lwz		r27, EWA.CPUBase + CPU.ID(r1)
	_log	'CPU '
	mr		r8, r27
	bl		Printw

	_log	'MemRetry machine check - last EA '
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r27,  0x0694(r1)
	mr		r8, r27
	bl		Printw

	_log	' SRR1 '
	mfspr	r8, srr1
	mr		r8, r8
	bl		Printw

	_log	' SRR0 '
	mfspr	r8, srr0
	mr		r8, r8
	bl		Printw
	_log	'^n'

	mr		r8, r28
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r27,  0x0694(r1)
	subf	r28, r19, r27
	cmpwi	r28, -0x10
	blt		MemRetryMachineCheck_0x14c
	cmpwi	r28,  0x10
	bgt		MemRetryMachineCheck_0x14c

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r29

	lwz		r28,  0x0e98(r1)
	addi	r28, r28,  0x01
	stw		r28,  0x0e98(r1)
	lwz		r29,  0x0698(r1)
	li		r28,  0x00
	stw		r28,  0x0000(r29)
	mfspr	r28, pvr
	rlwinm.	r28, r28,  0,  0, 14
	sync
	tlbie	r27
	beq		MemRetryMachineCheck_0x124
	sync
	tlbsync

MemRetryMachineCheck_0x124
	sync
	isync
	_AssertAndRelease	PSA.HTABLock, scratch=r28



MemRetryMachineCheck_0x14c	;	OUTSIDE REFERER
	cmplw	r10, r19
	li		r8, ecDataHardwareFault
	bne		ExceptionMemRetried
	mfsprg	r1, 0
	mtsprg	3, r24
	lmw		r14,  0x0038(r1)
	li		r8, ecInstHardwareFault
	b		Exception



	align	kIntAlign

IntISI	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	andis.	r8, r11,  0x4020
	beq		major_0x039dc_0x14
	mfsprg	r8, 0
	stmw	r14,  0x0038(r8)

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	mr		r27, r10
	bl		PagingFunc1
	_AssertAndRelease	PSA.HTABLock, scratch=r28
	mfsprg	r8, 0
	bne		major_0x039dc


	;	MemRetry

	mfsprg	r24, 3
	mfmsr	r14
	ori		r15, r14,  0x10
	addi	r23, r1, KDP.VecBaseMemRetry
	mtsprg	3, r23
	mr		r19, r10
	mtmsr	r15
	isync
	lbz		r23,  0x0000(r19)
	sync
	mtmsr	r14
	isync
	mfsprg	r8, 0
	mtsprg	3, r24
	lmw		r14,  0x0038(r8)
	b		IntReturn



major_0x039dc	;	OUTSIDE REFERER
	lmw		r14,  0x0038(r8)
	li		r8, ecInstPageFault
	blt		Exception
	li		r8, ecInstInvalidAddress
	b		Exception

major_0x039dc_0x14	;	OUTSIDE REFERER
	andis.	r8, r11,  0x800
	li		r8, ecInstSupAccessViolation
	bne		Exception
	li		r8, ecInstHardwareFault
	b		Exception



IntMachineCheck	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	lwz		r9, EWA.CPUBase + CPU.ID(r8)
	_log	'CPU '
	mr		r8, r9
	bl		Printw

	_log	'Machine check at '		; srr1/srr0
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw

	_log	'- last unmapped EA '
	lwz		r8,  0x0694(r1)
	mr		r8, r8
	bl		Printw
	_log	'^n'

	rlwinm.	r8, r11,  0,  2,  2
	beq		@not_L1_data_cache_error

;L1 data cache error
	bl		FlushL1CacheUsingMSSCR0
	b		IntReturn

@not_L1_data_cache_error
	li		r8, ecMachineCheck
	b		Exception



MaskedInterruptTaken	;	OUTSIDE REFERER
	_log	'*** CPU MALFUNCTION - Masked interrupt punched through. SRR1/0 '
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw
	_log	'^n'
	lis		r10, -0x4523
	ori		r10, r10,  0xcb00
	li		r8, ecMachineCheck
	b		Exception



	align	kIntAlign

PIHDSI	;	OUTSIDE REFERER
	mfspr	r8, dsisr
	rlwimi	r11, r8,  0,  0,  9
	andis.	r8, r11,  0x4020
	beq		major_0x039dc_0x14
	mfsprg	r8, 0
	stmw	r14,  0x0038(r8)
	lwz		r1, -0x0004(r8)

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	mfspr	r27, dar
	bl		PagingFunc1
	_AssertAndRelease	PSA.HTABLock, scratch=r28
	mfsprg	r8, 0
	bne		major_0x039dc
	lmw		r14,  0x0038(r8)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0



              ######                                    #######                      #######                                                   
#    #  ####  #     # ###### ##### #    # #####  #    # #       #####   ####  #    # #       #    #  ####  ###### #####  ##### #  ####  #    # 
#   #  #    # #     # #        #   #    # #    # ##   # #       #    # #    # ##  ## #        #  #  #    # #      #    #   #   # #    # ##   # 
####   #      ######  #####    #   #    # #    # # #  # #####   #    # #    # # ## # #####     ##   #      #####  #    #   #   # #    # # #  # 
#  #   #      #   #   #        #   #    # #####  #  # # #       #####  #    # #    # #         ##   #      #      #####    #   # #    # #  # # 
#   #  #    # #    #  #        #   #    # #   #  #   ## #       #   #  #    # #    # #        #  #  #    # #      #        #   # #    # #   ## 
#    #  ####  #     # ######   #    ####  #    # #    # #       #    #  ####  #    # ####### #    #  ####  ###### #        #   #  ####  #    # 

	align	kIntAlign

;	dead code?

	lwz		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r1)
	mr		r10, r12
	addi	r11, r11, 1
	stw		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r1)
	mfsrr1	r11
	rlwimi	r7, r7, 27, 26, 26

kcReturnFromException	;	OUTSIDE REFERER

	_bset	r11, r11, MSR_EEbit

	mtcrf	0x3f, r7
	cmplwi	cr1, r3, 1									; exception handler return value
	bc		BO_IF, EWA.kFlagSIGP, IntReturnFromSIGP

	blt		cr1, major_0x03be0_0x58
	beq		cr1, major_0x03be0_0x90


	subi	r8, r3, 32
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionForcedCount(r1)
	cmplwi	r8, 224
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionForcedCount(r1)
	mfsprg	r1, 0
	rlwimi	r7, r3, 24,  0,  7
	blt		major_0x03be0_0xe8
	li		r8, ecTrapInstr
	b		Exception

major_0x03be0_0x58
	mfsprg	r1, 0
	lwz		r8,  0x0040(r6)
	lwz		r10,  0x0084(r6)
	rlwimi	r7, r8,  0, 17,  7
	lwz		r8,  0x0044(r6)
	rlwimi	r11, r7,  0, 20, 23 ; MSR[FE0/SE/BE/FE1]
	stw		r8, EWA.Enables(r1)
	andi.	r8, r11,  0x900
	lwz		r12,  0x008c(r6)
	lwz		r3,  0x0094(r6)
	lwz		r4,  0x009c(r6)
	bnel	major_0x03e18
	addi	r9, r6,  0x40
	b		IntReturn

major_0x03be0_0x90
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionPropagateCount(r1)
	lwz		r8,  0x0040(r6)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionPropagateCount(r1)
	mfsprg	r1, 0
	lwz		r10,  0x0084(r6)
	rlwimi	r7, r8,  0, 17,  7
	lwz		r8,  0x0044(r6)
	mtcrf	 0x0f, r7
	rlwimi	r11, r7,  0, 20, 23 ; MSR[FE0/SE/BE/FE1]
	stw		r8, EWA.Enables(r1)
	lwz		r12,  0x008c(r6)
	lwz		r3,  0x0094(r6)
	lwz		r4,  0x009c(r6)
	bne		cr2, major_0x03be0_0xe8
	bns		cr6, major_0x03be0_0xe8
	stmw	r14,  0x0038(r1)
	lwz		r17,  0x0064(r6)
	lwz		r20,  0x0068(r6)
	lwz		r21,  0x006c(r6)
	lwz		r19, ContextBlock.SRR0(r6)
	lwz		r18,  0x007c(r6)

major_0x03be0_0xe8
	beq		cr2, IntReturnToSystemContext
	crclr	cr6_so
	mfspr	r10, srr0
	li		r8, ecTrapInstr
	b		Exception



	align	5

save_all_registers	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stw		r6,  0x0018(r1)
	mfsprg	r6, 1
	stw		r6,  0x0004(r1)
	lwz		r6, -0x0014(r1)
	stw		r0,  0x0104(r6)
	stw		r7,  0x013c(r6)
	stw		r8,  0x0144(r6)
	stw		r9,  0x014c(r6)
	stw		r10,  0x0154(r6)
	stw		r11,  0x015c(r6)
	stw		r12,  0x0164(r6)
	stw		r13,  0x016c(r6)
	li		r0,  0x00
	mfspr	r10, srr0
	mfspr	r11, srr1
	mfcr	r13
	mfsprg	r12, 2
	lwz		r7, EWA.Flags(r1)
	lwz		r1, -0x0004(r1)

;	r6 = ewa
	b		SchSaveStartingAtR14
;	r8 = sprg0 (not used by me)



#                            ###                                                       ######                                                    
#        ####    ##   #####   #  #    # ##### ###### #####  #####  #    # #####  ##### #     # ######  ####  #  ####  ##### ###### #####   ####  
#       #    #  #  #  #    #  #  ##   #   #   #      #    # #    # #    # #    #   #   #     # #      #    # # #        #   #      #    # #      
#       #    # #    # #    #  #  # #  #   #   #####  #    # #    # #    # #    #   #   ######  #####  #      #  ####    #   #####  #    #  ####  
#       #    # ###### #    #  #  #  # #   #   #      #####  #####  #    # #####    #   #   #   #      #  ### #      #   #   #      #####       # 
#       #    # #    # #    #  #  #   ##   #   #      #   #  #   #  #    # #        #   #    #  #      #    # # #    #   #   #      #   #  #    # 
#######  ####  #    # #####  ### #    #   #   ###### #    # #    #  ####  #        #   #     # ######  ####  #  ####    #   ###### #    #  ####  

;	How we arrive here:
;
;		PowerPC exception vector saved r1/LR in SPRG1/2 and
;		jumped where directed by the vecTable pointed to by
;		SPRG3. That function bl'ed here.
;
;
;	When we arrive here:
;
;		r1 is saved in SPRG1 (r1 itself is junk)
;		LR is saved in SPRG2 (LR itself contains return addr)
;
;
;	Before we return:
;
;		Reg		Contains			Original saved in
;		---------------------------------------------
;		 r0		0					ContextBlock
;		 r1		KDP					EWA
;		 r2		(itself)					
;		 r3		(itself)
;		 r4		(itself)
;		 r5		(itself)
;		 r6		ContextBlock		EWA
;		 r7		Flags				ContextBlock
;		 r8		EWA					ContextBlock
;		 r9		(itself)			ContextBlock
;		r10		SRR0				ContextBlock
;		r11		SRR1				ContextBlock
;		r12		LR					ContextBlock
;		r13		CR					ContextBlock
;
;
;	Can be followed up by a call to SchSaveStartingAtR14,
;	(which will put them in the ContextBlock too).

	align	5

LoadInterruptRegisters

	;	Get EWA pointer in r1 (phew)
	mfsprg	r1, 0

	;	Save r6 in EWA
	stw		r6, EWA.r6(r1)

	;	Save pre-interrupt r1 (which SPRG1 held) to EWA
	mfsprg	r6, 1
	stw		r6, EWA.r1(r1)

	;	Get ContextBlock pointer in r6 (phew)
	lwz		r6, EWA.PA_ContextBlock(r1)

	;	Save r0, r7-r13 in ContextBlock
	stw		r0, ContextBlock.r0(r6)
	stw		r7, ContextBlock.r7(r6)
	stw		r8, ContextBlock.r8(r6)
	stw		r9, ContextBlock.r9(r6)
	stw		r10, ContextBlock.r10(r6)
	stw		r11, ContextBlock.r11(r6)
	stw		r12, ContextBlock.r12(r6)
	stw		r13, ContextBlock.r13(r6)

	;	Zero r0 (convenient)
	li		r0, 0

	;	Make some useful special registers conveniently available
	mfspr	r10, srr0
	mfspr	r11, srr1
	mfcr	r13
	mfsprg	r12, 2

	;	Point r8 to EWA
	mr		r8, r1

	;	Features in r7, KDP in r8
	lwz		r7, EWA.Flags(r1)
	lwz		r1, EWA.PA_KDP(r1)

	blr
