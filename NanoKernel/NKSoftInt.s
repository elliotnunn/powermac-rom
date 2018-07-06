;	AUTO-GENERATED SYMBOL LIST

########################################################################

IllegalInstruction

	org		0x29c0

########################################################################

;	We can assume that this is being called from the emulator

;	We accept a logical NCB ptr but the kernel needs a physical one.
;	So we keep a four-entry cache in KDP, mapping logical NCB ptrs
;	to physical ones. But when are there multiple alt contexts?

;	ARG		flags? r3, mask r4

	align	kIntAlign
KCallRunAlternateContext

	and.	r8, r4, r13
	lwz		r9, KDP.NCBCacheLA0(r1)
	rlwinm	r8, r3, 0, 0, 25
	cmpw	cr1, r8, r9
	bne		IntReturn
	lwz		r9, KDP.NCBCachePA0(r1)
	bne		cr1, @search_cache


@found_physical_in_cache ; can come here from below after a more thorough search

	addi	r8, r1, KDP.VecBaseAlternate ; the only use of this vector table?
	mtsprg	3, r8

	lwz		r8, KDP.LA_EmulatorKernelTrapTable(r1)
	mtcrf	0x3f, r7
	clrlwi	r7, r7, 8
	stw		r8, ContextBlock.LA_EmulatorKernelTrapTable(r9)

	stw		r9, EWA.PA_ContextBlock(r1)

	b		IntReturnToOtherBlueContext


@search_cache

	lwz		r9, KDP.NCBCacheLA1(r1)
	cmpw	cr1, r8, r9
	beq		cr1, @found_in_slot_1

	lwz		r9, KDP.NCBCacheLA2(r1)
	cmpw	cr1, r8, r9
	beq		cr1, @found_in_slot_2

	lwz		r9, KDP.NCBCacheLA3(r1)
	cmpw	cr1, r8, r9
	beq		cr1, @found_in_slot_3


	;	No luck with the cache

	stmw	r14, EWA.r14(r1)

	cmpw	cr1, r8, r6
	beq		cr1, @fail

	mr		r27, r8
	addi	r29, r1, KDP.BATs + 0xa0
	bl		PagingL2PWithBATs
	clrlwi	r23, r8, 20
	beq		@fail

	cmplwi	r23, 0x0d00
	mr		r9, r8
	mr		r8, r31
	ble		@not_straddling_pages

	addi	r27, r27, 0x1000
	addi	r29, r1, KDP.BATs + 0xa0
	bl		PagingL2PWithBATs
	beq		@fail

	subi	r31, r31, 0x1000
	xor		r23, r8, r31
	rlwinm.	r23, r23, 0, 25, 22
	bne		@fail ; because physical pages are discontiguous
@not_straddling_pages

	clrlwi	r23, r31, 30
	cmpwi	r23, 3
	rlwimi	r8, r9, 0, 20, 31
	beq		@fail


	;	Found a non-cached physical address for this NCB!

	lwz		r23, KDP.NanoKernelInfo + NKNanoKernelInfo.NCBPtrCacheMissCount(r1)
	addi	r23, r23, 1
	stw		r23, KDP.NanoKernelInfo + NKNanoKernelInfo.NCBPtrCacheMissCount(r1)


	;	Stick it in cache slot 3

	lmw		r14, EWA.r14(r1)
	stw		r8, KDP.NCBCachePA3(r1)


@found_in_slot_3 ; so promote to slot 2

	lwz		r8, KDP.NCBCacheLA2(r1)
	stw		r9, KDP.NCBCacheLA2(r1)
	stw		r8, KDP.NCBCacheLA3(r1)

	lwz		r9, KDP.NCBCachePA3(r1)
	lwz		r8, KDP.NCBCachePA2(r1)
	stw		r9, KDP.NCBCachePA2(r1)
	stw		r8, KDP.NCBCachePA3(r1)

	lwz		r9, KDP.NCBCacheLA2(r1)


@found_in_slot_2 ; so promote to slot 1

	lwz		r8, KDP.NCBCacheLA1(r1)
	stw		r9, KDP.NCBCacheLA1(r1)
	stw		r8, KDP.NCBCacheLA2(r1)

	lwz		r9, KDP.NCBCachePA2(r1)
	lwz		r8, KDP.NCBCachePA1(r1)
	stw		r9, KDP.NCBCachePA1(r1)
	stw		r8, KDP.NCBCachePA2(r1)

	lwz		r9, KDP.NCBCacheLA1(r1)


@found_in_slot_1 ; so promote to slot 0, save elsewhere, and push on

	lwz		r8, KDP.NCBCacheLA0(r1)
	stw		r9, KDP.NCBCacheLA0(r1)
;	stw		r9, KDP.LA_NCB(r1)
	stw		r8, KDP.NCBCacheLA1(r1)

	lwz		r9, KDP.NCBCachePA1(r1)
	lwz		r8, KDP.NCBCachePA0(r1)
	stw		r9, KDP.NCBCachePA0(r1)
	stw		r8, KDP.NCBCachePA1(r1)

	b		@found_physical_in_cache


@fail

	lmw		r14, EWA.r14(r1)
	li		r8, ecTrapInstr
	b		Exception

########################################################################

	align	kIntAlign
KCallResetSystem ; PPC trap 1, or indirectly, 68k RESET
	stmw	r14, EWA.r14(r1)

	xoris	r8, r3, 'Ga'
	cmplwi	r8,     'ry'
	bne		Reset
	xoris	r8, r4, 0x0505
	cmplwi	r8,     0x1956
	bne		Reset

	;	Gary Davidian skeleton key: r5/D0 = MSR bits to unset, r7/D2 = MSR bits to set
	andc	r11, r11, r5
	lwz		r8, ContextBlock.r7(r6)
	or		r11, r11, r8
	b		IntReturn

Reset
	include	'NKReset.s'

	lmw		r14, EWA.r14(r1)
	b		KCallPrioritizeInterrupts

########################################################################

	align	kIntAlign
KCallPrioritizeInterrupts

	;	Left side: roll back the interrupt preparation before the int handler repeats is
	;	Right side: jump to the external interrupt handler (PIH or IntProgram)
	mtsprg	2, r12
	mtsrr0	r10
	mtsrr1	r11
	mtcr	r13
	lwz		r10, ContextBlock.r10(r6)
	lwz		r11, ContextBlock.r11(r6)
	lwz		r12, ContextBlock.r12(r6)
	lwz		r13, ContextBlock.r13(r6)
	lwz		r7, ContextBlock.r7(r6)
	lwz		r8, EWA.r1(r1)
										mfsprg	r9, 3
										lwz		r9, VecTable.ExternalIntVector(r9)
	mtsprg	1, r8
										mtlr	r9
	lwz		r8, ContextBlock.r8(r6)
	lwz		r9, ContextBlock.r9(r6)
	lwz		r6, EWA.r6(r1)
										blrl ; (could this ever fall though to KCallallSystemCrash?)

########################################################################

;	Move registers from CB to EWA, and Thud.

	align	kIntAlign
KCallallSystemCrash

	stw		r0, EWA.r0(r1)
	stw		r2, EWA.r2(r1)
	stw		r3, EWA.r3(r1)
	stw		r4, EWA.r4(r1)
	stw		r5, EWA.r5(r1)

	lwz		r8, ContextBlock.r7(r6)
	lwz		r9, ContextBlock.r8(r6)
	stw		r8, EWA.r7(r1)
	stw		r9, EWA.r8(r1)

	lwz		r8, ContextBlock.r9(r6)
	lwz		r9, ContextBlock.r10(r6)
	stw		r8, EWA.r9(r1)
	stw		r9, EWA.r10(r1)

	lwz		r8, ContextBlock.r11(r6)
	lwz		r9, ContextBlock.r12(r6)
	stw		r8, EWA.r11(r1)
	stw		r9, EWA.r12(r1)

	lwz		r8, ContextBlock.r13(r6)
	stw		r8, EWA.r13(r1)

	stmw	r14, EWA.r14(r1)

	bl		Panic

########################################################################

	align	kIntAlign
IntProgram ; (also called when the Alternate Context gets an External Int => Exception)

	;	Standard interrupt palaver
	mfsprg	r1, 0
	stw		r6, EWA.r6(r1)
	mfsprg	r6, 1
	stw		r6, EWA.r1(r1)
	lwz		r6, KDP.PA_ContextBlock(r1)
	stw		r7, ContextBlock.r7(r6)
	stw		r8, ContextBlock.r8(r6)
	stw		r9, ContextBlock.r9(r6)
	stw		r10, ContextBlock.r10(r6)
	stw		r11, ContextBlock.r11(r6)
	stw		r12, ContextBlock.r12(r6)
	stw		r13, ContextBlock.r13(r6)

	;	Compare SRR0 with address of Emulator's KCall trap table
	lwz		r8, KDP.LA_EmulatorKernelTrapTable(r1)
	mfsrr0	r10
	mfcr	r13
	xor.	r8, r10, r8
	lwz		r7, KDP.Flags(r1)
	mfsprg	r12, 2
	beq		ReturnFromExceptionFastPath		; KCall in Emulator table => fast path
	rlwimi. r7, r7, EWA.kFlagEmu, 0, 0
	cmplwi	cr7, r8, 16 * 4
	bge		cr0, @fromAltContext			; Alt Context cannot make KCalls; this might be an External Int
	bge		cr7, @notFromEmulatorTrapTable	; from Emulator but not from its KCall table => do more checks

	;	SUCCESSFUL TRAP from emulator KCall table
	;	=> Service call then return to link register
	add		r8, r8, r1
	lwz		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	lwz		r10, KDP.NanoKernelCallTable(r8)
	addi	r11, r11, 1
	stw		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	mtlr	r10
	mr		r10, r12 ; ret addr: LR was saved to SPRG2, SPRG2 to r12 above, r12 to r10 now, r10 to SRR0 to program ctr later
	mfsrr1	r11
	rlwimi	r7, r7, 32-5, 26, 26 ; something about MSR[SE]
	blr

@notFromEmulatorTrapTable ; so check if it is even a trap...
	mfsrr1	r11
	mtcrf	0x70, r11
	bc		BO_IF_NOT, 14, @notTrap

	mfmsr	r9					; fetch the instruction to get the "trap number"
	_bset	r8, r9, MSR_DRbit
	mtmsr	r8
	lwz		r8, 0(r10)
	mtmsr	r9
	xoris	r8, r8, 0xfff
	cmplwi	cr7, r8, 16			; only traps 0-15 are allowed
	slwi	r8, r8, 2			; (for "success" case below)
	bge		@illegalTrap

	;	SUCCESSFUL TRAP from outside emulator KCall table
	;	=> Service call then return to following instruction
	add		r8, r8, r1
	lwz		r10, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r10, r10, 1
	stw		r10, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	lwz		r8, KDP.NanoKernelCallTable(r8)
	mtlr	r8
	addi	r10, r10, 4				; continue executing the next instruction
	rlwimi	r7, r7, 32-5, 26, 26	; something about MSR[SE]
	blr

	;	Cannot service with a KCall => throw Exception
@fromAltContext					; external interrupt, or a (forbidden) KCall attempt
	mfsrr1	r11
	mtcrf	0x70, r11
@notTrap						; then it was some other software exception
	bc		BO_IF, 12, IllegalInstruction
	bc		BO_IF, 11, @floatingPointException
@illegalTrap					; because we only allow traps 0-15
	rlwinm	r8, r11, 17, 28, 29	
	addi	r8, r8, 0x4b3
	rlwnm	r8, r8, r8, 28, 31
	b		Exception			; CLEVER BIT HACKING described below

	;	SRR1[13]	SRR[14]		Exception
	;	0			0			ecNoException
	;	0			1			ecTrapInstr
	;	1			0			ecPrivilegedInstr
	;	1			1			9 (floating-point?)

@floatingPointException
	li		r8, ecFloatException
	bc		BO_IF, 15, Exception	; SRR1[15] set => handler can retry
	addi	r10, r10, 4
	rlwimi	r7, r7, 32-5, 26, 26	; something about MSR[SE]
	b		Exception				; SRR1[15] unset => can't retry

########################################################################

	align	kIntAlign
IntSyscall

	bl		LoadInterruptRegisters
	mfmsr	r8
	subi	r10, r10, 4
	rlwimi	r11, r8, 0, 0xFFFF0000
	li		r8, ecSystemCall
	b		Exception

########################################################################

	align	kIntAlign
IntTrace

	bl		LoadInterruptRegisters
	li		r8, ecInstTrace
	b		Exception
