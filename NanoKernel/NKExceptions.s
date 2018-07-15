;	AUTO-GENERATED SYMBOL LIST

########################################################################

ExceptionAfterRetry
	mtsprg	3, r24

	lwz		r9, KDP.Enables(r1)
	rlwinm	r23, r17, (32-1), 27, 31
	rlwnm.	r9, r9, r8, 0, 0				; BGE taken if exception disabled

	bcl		BO_IF, bitFlag15, major_0x02980_0x100

	lwz		r6, KDP.PA_ContextBlock(r1)

	_bset	r7, r16, 27

	neg		r23, r23
	mtcrf	0x3f, r7
	add		r19, r19, r23

	insrwi	r7, r8, 8, 0					; ec code -> high byte of flags

	slwi	r8, r8, 2						; increment counter
	add		r8, r8, r1
	lwz		r9, KDP.NKInfo.ExceptionCauseCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NKInfo.ExceptionCauseCounts(r8)

	;	Move regs from KDP to ContextBlock
	lwz		r8, EWA.r7(r1)
	stw		r8, CB.r7(r6)
	lwz		r8, EWA.r8(r1)
	stw		r8, CB.r8(r6)
	lwz		r8, EWA.r9(r1)
	stw		r8, CB.r9(r6)
	lwz		r8, EWA.r10(r1)
	stw		r8, CB.r10(r6)
	lwz		r8, EWA.r11(r1)
	stw		r8, CB.r11(r6)
	lwz		r8, EWA.r12(r1)
	stw		r8, CB.r12(r6)
	lwz		r8, EWA.r13(r1)
	stw		r8, CB.r13(r6)

	bge		RunSystemContext			; Alt Context has left exception disabled => Sys Context
	;fall through							; exception enabled => run userspace handler

########################################################################

RunExceptionHandler
	stw		r10, CB.ExceptionOriginAddr(r6)			; Save r10/SRR0, r12/LR, r3, r4
	stw		r12, CB.ExceptionOriginLR(r6)
	stw		r3, CB.ExceptionOriginR3(r6)
	stw		r4, CB.ExceptionOriginR4(r6)

	lwz		r8, KDP.Enables(r1)						; Save Enables & Flags				
	stw		r7, CB.ExceptionOriginFlags(r6)
	stw		r8, CB.ExceptionOriginEnables(r6)

													; Set up the Exception Handler context
	li		r8, 0									; r8/Enables = 0 (handler must not throw exception)
	lwz		r10, CB.ExceptionHandler(r6)			; r10/SRR0 = handler addr
	lwz		r4, CB.ExceptionHandlerR4(r6)			; r4 = arbitrary second argument
	lwz		r3, KDP.LA_ECB(r1)						; r3 = ContextBlock ptr
	bc		BO_IF, bitFlagEmu, @sys
	lwz		r3, KDP.NCBCacheLA0(r1)
@sys
	lwz		r12, KDP.LA_EmulatorKernelTrapTable + NanoKernelCallTable.ReturnFromException(r1)
													; r12/LR = address of KCallReturnFromException trap

	bcl		BO_IF, bitFlagLowSaves, PreferRegistersFromKDPSavingContextBlock	; ???

	rlwinm	r7, r7, 0, 29, 15						; unset flags 16-28
	stw		r8, KDP.Enables(r1)
	rlwimi	r11, r7, 0, 20, 23						; threfore unset MSR[FE0/SE/BE/FE1]

	b		IntReturn

########################################################################

major_0x02980_0x100
	lwz		r0, EWA.r0(r1)
	lwz		r2, EWA.r2(r1)
	lwz		r3, EWA.r3(r1)
	lwz		r4, EWA.r4(r1)
	lwz		r5, EWA.r5(r1)
	blr

PreferRegistersFromKDPSavingContextBlock
	stw		r17, CB.PropagateR17(r6)
	stw		r20, CB.PropagateR20(r6)
	stw		r21, CB.PropagateR21(r6)
	stw		r19, CB.PropagateR19(r6)
	stw		r18, CB.PropagateR18(r6)
	lmw		r14, EWA.r14(r1)
	blr

########################################################################

	_alignToCacheBlock
KCallReturnFromExceptionFastPath
	lwz		r11, KDP.NKInfo.NanoKernelCallCounts(r1)
	mr		r10, r12
	addi	r11, r11, 1
	stw		r11, KDP.NKInfo.NanoKernelCallCounts(r1)
	mfsrr1	r11
	rlwimi	r7, r7, 27, 26, 26							; ?re-enable single stepping

KCallReturnFromException
	cmplwi	cr1, r3, 1									; exception handler return value
	blt		cr1, @dispose
	mtcrf	0x3f, r7
	beq		cr1, @propagate

;force to system context			; Handler returned >= 1
	subi	r8, r3, 32
	lwz		r9, KDP.NKInfo.ExceptionForcedCount(r1)
	cmplwi	r8, 256-32
	addi	r9, r9, 1
	stw		r9, KDP.NKInfo.ExceptionForcedCount(r1)
	insrwi	r7, r3, 8, 0
	blt		RunSystemContext			; Handler returned 1-255: force that exception number to System
	li		r8, ecTrapInstr
	b		Exception						; Handler returned >= 256: fail!

@dispose							; Handler returned 0: return to the code that threw the exception
	lwz		r8, CB.ExceptionOriginFlags(r6)
	lwz		r10, CB.ExceptionOriginAddr(r6)
	rlwimi	r7, r8, 0, 0xFF00FFFF			; restore most Flags to pre-exception state
	lwz		r8, CB.ExceptionOriginEnables(r6)
	rlwimi	r11, r7, 0, 20, 23				; MSR[FE0/SE/BE/FE1] <- Flags
	stw		r8, KDP.Enables(r1)

	andi.	r8, r11, MsrFE0 + MsrFE1		; check: are floating-pt exceptions enabled?

	lwz		r12, CB.ExceptionOriginLR(r6)	; restore LR/r3/r4
	lwz		r3, CB.ExceptionOriginR3(r6)
	lwz		r4, CB.ExceptionOriginR4(r6)

	bnel	EnableFPU						; if FP exceptions are enabled, make sure the FPU is enabled

	addi	r9, r6, CB.ExceptionOriginFlags	; never gets used... points to exception part of ContextBlock?

	b		IntReturn

@propagate							; Handler returned 1: propagate exception
	lwz		r9, KDP.NKInfo.ExceptionPropagateCount(r1)
	lwz		r8, CB.ExceptionOriginFlags(r6)
	addi	r9, r9, 1
	stw		r9, KDP.NKInfo.ExceptionPropagateCount(r1)
	lwz		r10, CB.ExceptionOriginAddr(r6)
	rlwimi	r7, r8, 0, 0xFF00FFFF			; restore most Flags to pre-exception state
	lwz		r8, CB.ExceptionOriginEnables(r6)
	mtcrf	0x0f, r7
	rlwimi	r11, r7, 0, 20, 23				; MSR[FE0/SE/BE/FE1] <- Flags
	stw		r8, KDP.Enables(r1)

	lwz		r12, CB.ExceptionOriginLR(r6)	; restore LR/r3/r4
	lwz		r3, CB.ExceptionOriginR3(r6)
	lwz		r4, CB.ExceptionOriginR4(r6)

	bc		BO_IF_NOT, bitFlagLowSaves, RunSystemContext
	stmw	r14, EWA.r14(r1)
	lwz		r17, CB.PropagateR17(r6)
	lwz		r20, CB.PropagateR20(r6)
	lwz		r21, CB.PropagateR21(r6)
	lwz		r19, CB.PropagateR19(r6)
	lwz		r18, CB.PropagateR18(r6)
	b		RunSystemContext

########################################################################

;	BEFORE
;		PowerPC exception vector saved r1/LR in SPRG1/2 and
;		jumped where directed by the vecTable pointed to by
;		SPRG3. That function bl'ed here.
;
;	AFTER
;		Reg		Contains			Original saved in
;		---------------------------------------------
;		 r0		(itself)
;		 r1		KDP					SPRG1
;		 r2		(itself)					
;		 r3		(itself)
;		 r4		(itself)
;		 r5		(itself)
;		 r6		ContextBlock		EWA
;		 r7		Flags				ContextBlock
;		 r8		KDP					ContextBlock
;		 r9		(scratch CB ptr)	ContextBlock
;		r10		SRR0				ContextBlock
;		r11		SRR1				ContextBlock
;		r12		LR					ContextBlock
;		r13		CR					ContextBlock

LoadInterruptRegisters
	mfsprg	r1, 0
	stw		r6, EWA.r6(r1)
	mfsprg	r6, 1
	stw		r6, EWA.r1(r1)
	lwz		r6, KDP.PA_ContextBlock(r1)
	stw		r7, CB.r7(r6)
	stw		r8, CB.r8(r6)
	stw		r9, CB.r9(r6)
	stw		r10, CB.r10(r6)
	stw		r11, CB.r11(r6)
	stw		r12, CB.r12(r6)
	stw		r13, CB.r13(r6)
	mfsrr0	r10
	mfcr	r13
	lwz		r7, KDP.Flags(r1)
	mfsprg	r12, 2
	mfsrr1	r11
	blr

########################################################################

Exception
	lwz		r9, KDP.Enables(r1)
	mtcrf	0x3f, r7

	rlwnm.	r9, r9, r8, 0, 0				; BLT taken if exception enabled

	insrwi	r7, r8, 8, 0					; Exception code to hi byte of Flags

	slwi	r8, r8, 2						; Increment counter, easy enough
	add		r8, r8, r1
	lwz		r9, KDP.NKInfo.ExceptionCauseCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NKInfo.ExceptionCauseCounts(r8)

	blt		RunExceptionHandler				; exception enabled => run userspace handler
	;fall through							; Alt Context has left exception disabled => Sys Context

########################################################################

RunSystemContext
	lwz		r9, KDP.PA_ECB(r1)				; System ("Emulator") ContextBlock

	addi	r8, r1, KDP.VecBaseSystem		; System VecTable
	mtsprg	3, r8

	bcl		BO_IF, bitFlagEmu, SystemCrash	; System Context already running!

	;	Fallthru (new CB in r9, old CB in r6)

########################################################################

SwitchContext ; OldCB *r6, NewCB *r9
;	Run the System or Alternate Context
	lwz		r8, KDP.Enables(r1)
	stw		r7, CB.Flags(r6)
	stw		r8, CB.Enables(r6)

	bc		BO_IF_NOT, bitFlagLowSaves, @not_low_saves
	stw		r17, CB.LowSave17(r6)
	stw		r20, CB.LowSave20(r6)
	stw		r21, CB.LowSave21(r6)
	stw		r19, CB.LowSave19(r6)
	stw		r18, CB.LowSave18(r6)
	lmw		r14, EWA.r14(r1)
@not_low_saves

	mfxer	r8
	stw		r13, CB.CR(r6)
	stw		r8, CB.XER(r6)
	stw		r12, CB.LR(r6)
	mfctr	r8
	stw		r10, CB.CodePtr(r6)
	stw		r8, CB.KernelCTR(r6)

	bc		BO_IF_NOT, bitFlagHasMQ, @no_mq
	lwz		r8, CB.MQ(r9)
	mfspr	r12, mq
	mtspr	mq, r8
	stw		r12, CB.MQ(r6)
@no_mq

	lwz		r8, EWA.r1(r1)
	stw		r0, CB.r0(r6)
	stw		r8, 0x010c(r6)
	stw		r2, 0x0114(r6)
	stw		r3, 0x011c(r6)
	stw		r4, 0x0124(r6)
	lwz		r8, 0x0018(r1)
	stw		r5, 0x012c(r6)
	stw		r8, 0x0134(r6)
	_band.	r8, r11, bitMsrFP
	stw		r14, 0x0174(r6)
	stw		r15, 0x017c(r6)
	stw		r16, 0x0184(r6)
	stw		r17, 0x018c(r6)
	stw		r18, 0x0194(r6)
	stw		r19, 0x019c(r6)
	stw		r20, 0x01a4(r6)
	stw		r21, 0x01ac(r6)
	stw		r22, 0x01b4(r6)
	stw		r23, 0x01bc(r6)
	stw		r24, 0x01c4(r6)
	stw		r25, 0x01cc(r6)
	stw		r26, 0x01d4(r6)
	stw		r27, 0x01dc(r6)
	stw		r28, 0x01e4(r6)
	stw		r29, 0x01ec(r6)
	stw		r30, 0x01f4(r6)
	stw		r31, 0x01fc(r6)
	bnel	DisableFPU

	lwz		r8, KDP.OtherContextDEC(r1)
	mfdec	r31
	cmpwi	r8, 0
	stw		r31, KDP.OtherContextDEC(r1)
	mtdec	r8
	blel	ResetDEC ; to r8

	lwz		r8, CB.Flags(r9)							; r8 is the new Flags variable
	stw		r9, KDP.PA_ContextBlock(r1)
	xoris	r7, r7, 1 << (15 - bitFlagEmu)			; flip Emulator flag
	rlwimi	r11, r8, 0, 20, 23							; "enact" MSR[FE0/SE/BE/FE1]
	mr		r6, r9										; change the magic ContextBlock register
	rlwimi	r7, r8, 0, 0x0000FFFF						; change bottom half of flags only

	andi.	r8, r11, MsrFE0 + MsrFE1					; FP exceptions enabled in new context?

	lwz		r8, CB.Enables(r6)
	lwz		r13, CB.CR(r6)
	stw		r8, KDP.Enables(r1)
	lwz		r8, CB.XER(r6)
	lwz		r12, CB.LR(r6)
	mtxer	r8
	lwz		r8, CB.KernelCTR(r6)
	lwz		r10, CB.CodePtr(r6)
	mtctr	r8

	bnel	ReloadFPU									; FP exceptions enabled, so load FPU

	stwcx.	r0, 0, r1

	lwz		r8, CB.r1(r6)
	lwz		r0, CB.r0(r6)
	stw		r8, EWA.r1(r1)
	lwz		r2, 0x0114(r6)
	lwz		r3, 0x011c(r6)
	lwz		r4, 0x0124(r6)
	lwz		r8, 0x0134(r6)
	lwz		r5, 0x012c(r6)
	stw		r8, 0x0018(r1)
	lwz		r14, 0x0174(r6)
	lwz		r15, 0x017c(r6)
	lwz		r16, 0x0184(r6)
	lwz		r17, 0x018c(r6)
	lwz		r18, 0x0194(r6)
	lwz		r19, 0x019c(r6)
	lwz		r20, 0x01a4(r6)
	lwz		r21, 0x01ac(r6)
	lwz		r22, 0x01b4(r6)
	lwz		r23, 0x01bc(r6)
	lwz		r24, 0x01c4(r6)
	lwz		r25, 0x01cc(r6)
	lwz		r26, 0x01d4(r6)
	lwz		r27, 0x01dc(r6)
	lwz		r28, 0x01e4(r6)
	lwz		r29, 0x01ec(r6)
	lwz		r30, 0x01f4(r6)
	lwz		r31, 0x01fc(r6)

########################################################################

IntReturn
	andi.	r8, r7, (1 << (31 - 26)) | (1 << (31 - 27))
	bnel	@do_trace			; Keep single-step code out of hot path

	stw		r7, KDP.Flags(r1)

	mtlr	r12					; restore user SPRs from kernel GPRs
	mtsrr0	r10
	mtsrr1	r11
	mtcr	r13

	lwz		r10, CB.r10(r6)		; restore user GPRs from ContextBlock
	lwz		r11, CB.r11(r6)
	lwz		r12, CB.r12(r6)
	lwz		r13, CB.r13(r6)
	lwz		r7, CB.r7(r6)
	lwz		r8, CB.r8(r6)
	lwz		r9, CB.r9(r6)

	lwz		r6, EWA.r6(r1)		; restore last two registers from EWA
	lwz		r1, EWA.r1(r1)

	rfi


@do_trace
	mtcrf	0x3f, r7

	bc		BO_IF_NOT, bitFlagLowSaves, @Trace_0x18
	_bclr	r7, r7, bitFlagLowSaves

	bc		BO_IF, bitFlag31, Trace_0x30
	_bclr	r7, r7, bitFlag26

	b		@return
@Trace_0x18

	bc		BO_IF_NOT, bitFlag26, @return
	_bclr	r7, r7, bitFlag26

	stw		r7, KDP.Flags(r1)
	li		r8, ecInstTrace
	b		Exception

@return
	blr

Trace_0x30
	; according to my counter, this point is never reached

	stw		r7, KDP.Flags(r1)
	stw		r0, 0x0000(r1)
	stw		r2, 0x0008(r1)
	stw		r3, 0x000c(r1)
	stw		r4, 0x0010(r1)
	stw		r5, 0x0014(r1)
	lwz		r8, 0x013c(r6)
	stw		r8, 0x001c(r1)
	lwz		r8, 0x0144(r6)
	stw		r8, 0x0020(r1)
	lwz		r8, 0x014c(r6)
	stw		r8, 0x0024(r1)
	lwz		r8, 0x0154(r6)
	stw		r8, 0x0028(r1)
	lwz		r8, 0x015c(r6)
	stw		r8, 0x002c(r1)
	lwz		r8, 0x0164(r6)
	stw		r8, 0x0030(r1)
	lwz		r8, 0x016c(r6)
	stw		r8, 0x0034(r1)
	stmw	r14, 0x0038(r1)
	lwz		r17, 0x0024(r9)
	lwz		r20, 0x0028(r9)
	lwz		r21, 0x002c(r9)
	lwz		r19, 0x0034(r9)
	lwz		r18, 0x003c(r9)
	_bclr	r16, r7, bitFlagLowSaves
	lwz		r25, 0x0650(r1)
	extrwi.	r22, r17, 4, 27
	add		r19, r19, r22
	rlwimi	r25, r17, 7, 25, 30
	lhz		r26, 0x0d20(r25) ; leaving this incorrect as a reminder!
	insrwi	r25, r19, 3, 28
	stw		r16, KDP.Flags(r1)
	rlwimi	r26, r26, 8, 8, 15		; copy hi byte of entry to second byte of word
	insrwi	r25, r17, 4, 24
	mtcrf	 0x10, r26					; so the second nybble of the entry is copied to cr3
	lha		r22, 0x0c00(r25)
	addi	r23, r1, KDP.VecBaseMemRetry
	add		r22, r22, r25
	mfsprg	r24, 3
	mtlr	r22
	mtsprg	3, r23
	mfmsr	r14
	ori		r15, r14, 0x10
	mtmsr	r15
	rlwimi	r25, r26, 2, 22, 29		; apparently the lower byte of the entry is an FDP (code?) offset, /4!
	bnelr
	b		FDP_011c

########################################################################

ResetDEC ; to r8
	lis		r31, 0x7FFF
	mtdec	r31
	mtdec	r8
	blr
