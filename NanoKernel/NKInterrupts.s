ecNoException				equ		0
ecSystemCall				equ		1
ecTrapInstr					equ		2
ecFloatException			equ		3
ecInvalidInstr				equ		4
ecPrivilegedInstr			equ		5
ecMachineCheck				equ		7
ecInstTrace					equ		8
ecInstInvalidAddress		equ		10
ecInstHardwareFault			equ		11
ecInstPageFault				equ		12
ecInstSupAccessViolation	equ		14
ecDataInvalidAccess			equ		18
ecDataHardwareFault			equ		19
ecDataPageFault				equ		20
ecDataWriteViolation		equ		21
ecDataSupAccessViolation	equ		22
ecDataSupWriteViolation		equ		23
ecUnknown24					equ		24



Local_Panic		set		*
				b		panic



;	                     IntLocalBlockMPCall

;	Xrefs:
;	major_0x02ccc

IntLocalBlockMPCall	;	OUTSIDE REFERER
	b		BlockMPCall



;	                     major_0x02980

;	Xrefs:
;	major_0x02ccc
;	major_0x03548
;	IntDSIOtherOther
;	IntMachineCheckMemRetry
;	major_0x039dc
;	IntMachineCheck
;	MaskedInterruptTaken
;	major_0x03be0
;	major_0x04180
;	kcRunAlternateContext
;	major_0x046d0
;	IntExternalOrange
;	IntProgram
;	IntTrace
;	FDP_1214

	align	5

major_0x02980	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mtsprg	3, r24
	lwz		r9, EWA.Enables(r1)
	rlwinm	r23, r17, 31, 27, 31
	rlwnm.	r9, r9, r8,  0x00,  0x00
	bsol-	cr3, major_0x02980_0x100
	lwz		r6, -0x0014(r1)
	ori		r7, r16,  0x10
	neg		r23, r23
	mtcrf	 0x3f, r7
	add		r19, r19, r23
	rlwimi	r7, r8, 24,  0,  7
	lwz		r1, -0x0004(r1)
	slwi	r8, r8,  2
	add		r8, r8, r1
	lwz		r9,  0x0dc0(r8)
	addi	r9, r9,  0x01
	stw		r9,  0x0dc0(r8)
	srwi	r9, r7, 24
	mfsprg	r1, 0
	lwz		r8,  0x0000(r1)
	stw		r8,  0x0104(r6)
	lwz		r8,  0x001c(r1)
	stw		r8,  0x013c(r6)
	lwz		r8,  0x0020(r1)
	stw		r8,  0x0144(r6)
	lwz		r8,  0x0024(r1)
	stw		r8,  0x014c(r6)
	lwz		r8,  0x0028(r1)
	stw		r8,  0x0154(r6)
	lwz		r8,  0x002c(r1)
	stw		r8,  0x015c(r6)
	lwz		r8,  0x0030(r1)
	stw		r8,  0x0164(r6)
	lwz		r8,  0x0034(r1)
	stw		r8,  0x016c(r6)
	cmpwi	cr1, r9,  0x14
	blt-	cr4, major_0x04a20_0x18
	bne-	cr2, TaskApproachTwo
	blt-	major_0x02980_0xa8
	bne-	cr1, major_0x02980_0x178
	b		TaskApproachTwo

major_0x02980_0xa8
	mfsprg	r1, 0
	stw		r10,  0x0084(r6)
	stw		r12,  0x008c(r6)
	stw		r3,  0x0094(r6)
	stw		r4,  0x009c(r6)
	lwz		r8, EWA.Enables(r1)
	stw		r7,  0x0040(r6)
	stw		r8,  0x0044(r6)
	li		r8,  0x00
	lwz		r10,  0x004c(r6)
	stw		r8, EWA.Enables(r1)
	lwz		r1, -0x0004(r1)
	lwz		r4,  0x0054(r6)
	lwz		r3,  0x0654(r1)
	blt-	cr2, major_0x02980_0xec
	lwz		r3,  0x05b4(r1)
	_bclr	r11, r11, 16

major_0x02980_0xec
	lwz		r12,  0x0648(r1)
	bsol-	cr6, PreferRegistersFromEWASavingContextBlock
	rlwinm	r7, r7,  0, 29, 16
	rlwimi	r11, r7,  0, 20, 23
	b		IntReturn

major_0x02980_0x100
	lwz		r2,  0x0008(r1)
	lwz		r3,  0x000c(r1)
	lwz		r4,  0x0010(r1)
	lwz		r5,  0x0014(r1)
	blr

PreferRegistersFromEWASavingContextBlock	;	OUTSIDE REFERER
	mfsprg	r8, 0
	stw		r17,  0x0064(r6)
	stw		r20,  0x0068(r6)
	stw		r21,  0x006c(r6)
	stw		r19,  0x0074(r6)
	stw		r18,  0x007c(r6)
	lmw		r14, EWA.r14(r8)
	blr






major_0x02980_0x134	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mtcrf	0x3f, r7
	lwz		r9, EWA.Enables(r1)
	lwz		r1, EWA.PA_KDP(r1)
	rlwnm.	r9, r9, r8, 0, 0
	rlwimi	r7, r8, 24,  0,  7

	slwi	r8, r8, 2
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionCauseCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionCauseCounts(r8)

	srwi	r9, r7, 24

	bc		BO_IF, EWA.kFlag16, major_0x04a20_0x18
	bc		BO_IF_NOT, EWA.kFlagBlue, TaskApproachOne
	cmpwi	cr1, r9, ecInstPageFault
	blt+	major_0x02980_0xa8						; when Enables[cause] is set!
	beq-	cr1, TaskApproachOne

major_0x02980_0x178	;	OUTSIDE REFERER
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r9, KDP.PA_ECB(r1)
	addi	r8, r1, KDP.YellowVecBase
	mtsprg	3, r8

	bcl		BO_IF, 8, SuspendBlueTask				; does not return

major_0x02980_0x18c	;	OUTSIDE REFERER
	mfsprg	r1, 0
	lwz		r8, EWA.Enables(r1)
	stw		r7, ContextBlock.Flags(r6)
	stw		r8, ContextBlock.Enables(r6)
	bc		BO_IF_NOT, 27, major_0x02980_0x1b8
	stw		r17,  0x0024(r6)
	stw		r20,  0x0028(r6)
	stw		r21,  0x002c(r6)
	stw		r19,  0x0034(r6)
	stw		r18,  0x003c(r6)
	lmw		r14,  0x0038(r1)

major_0x02980_0x1b8
	mfxer	r8
	stw		r13,  0x00dc(r6)
	stw		r8,  0x00d4(r6)
	stw		r12,  0x00ec(r6)
	mfctr	r8
	stw		r10,  0x00fc(r6)
	stw		r8,  0x00f4(r6)
	bc		BO_IF_NOT, 13, major_0x02980_0x1e8
	lwz		r8,  0x00c4(r9)
	mfspr	r12, mq
	mtspr	mq, r8
	stw		r12,  0x00c4(r6)

major_0x02980_0x1e8
	lwz		r8,  0x0004(r1)
	stw		r8,  0x010c(r6)
	stw		r2,  0x0114(r6)
	stw		r3,  0x011c(r6)
	stw		r4,  0x0124(r6)
	lwz		r8,  0x0018(r1)
	stw		r5,  0x012c(r6)
	stw		r8,  0x0134(r6)
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
	andi.	r8, r11,  0x2000
	stw		r27,  0x01dc(r6)
	stw		r28,  0x01e4(r6)
	stw		r29,  0x01ec(r6)
	stw		r30,  0x01f4(r6)
	stw		r31,  0x01fc(r6)
	bnel-	major_0x03e18_0xb4

	bc		BO_IF_NOT, 12, major_0x02980_0x260
	bl		Save_v0_v31
major_0x02980_0x260

	stw		r11,  0x00a4(r6)
	lwz		r8,  0x0000(r9)
	stw		r9, -0x0014(r1)
	xoris	r7, r7,  0x80
	rlwimi	r11, r8,  0, 20, 23
	mr		r6, r9
	rlwimi	r7, r8,  0, 17, 31
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
	bnel-	major_0x03e18_0x8
	lwarx	r8, 0, r1
	sync
	stwcx.	r8, 0, r1
	lwz		r29,  0x00d8(r6)
	lwz		r8,  0x010c(r6)
	cmpwi	r29,  0x00
	stw		r8,  0x0004(r1)
	lwz		r28,  0x0210(r29)
	beq-	major_0x02980_0x2d0
	mtspr	vrsave, r28

major_0x02980_0x2d0
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



;	Almost always goes straight through to SchReturn. Zeros a word in EWA.

;	ARG		flags_to_set r7

IntReturn	;	OUTSIDE REFERER

	andi.	r8, r7, (1 << (31 - 26)) | (1 << (31 - 27))
	mfsprg	r1, 0
	bnel-	major_0x02ccc								; my counters say almost never called!
	li		r8, 0
	stw		r7, EWA.Flags(r1)
	stw		r8, EWA.WeMightClear(r1)
	b		SchReturn



;	 Almost never called (by above func)

major_0x02ccc	;	OUTSIDE REFERER

	mtcrf	 0x3f, r7

	bc		BO_IF_NOT, 27, @major_0x02ccc_0x18
	_bclr	r7, r7, 27

	bc		BO_IF, 31, major_0x02ccc_0x30
	_bclr	r7, r7, 26

	b		@return
@major_0x02ccc_0x18

	bc		BO_IF_NOT, 26, @return
	_bclr	r7, r7, 26

	stw		r7, EWA.Flags(r1)
	li		r8, ecInstTrace
	b		major_0x02980_0x134
@return

	blr

major_0x02ccc_0x30
	; according to my counter, this point is never reached

	rlwinm.	r8, r7,  0,  8,  8
	beq-	SuspendBlueTask
	stw		r7, EWA.Flags(r1)
	lwz		r8,  0x0104(r6)
	stw		r8,  0x0000(r1)
	stw		r2,  0x0008(r1)
	stw		r3,  0x000c(r1)
	stw		r4,  0x0010(r1)
	stw		r5,  0x0014(r1)
	lwz		r8,  0x013c(r6)
	stw		r8,  0x001c(r1)
	lwz		r8,  0x0144(r6)
	stw		r8,  0x0020(r1)
	lwz		r8,  0x014c(r6)
	stw		r8,  0x0024(r1)
	lwz		r8,  0x0154(r6)
	stw		r8,  0x0028(r1)
	lwz		r8,  0x015c(r6)
	stw		r8,  0x002c(r1)
	lwz		r8,  0x0164(r6)
	stw		r8,  0x0030(r1)
	lwz		r8,  0x016c(r6)
	stw		r8,  0x0034(r1)
	stmw	r14,  0x0038(r1)
	lwz		r8, -0x0004(r1)
	lwz		r17,  0x0024(r9)
	lwz		r20,  0x0028(r9)
	lwz		r21,  0x002c(r9)
	lwz		r19,  0x0034(r9)
	lwz		r18,  0x003c(r9)
	_bclr	r16, r7, 27
	lwz		r25,  0x0650(r8)
	rlwinm.	r22, r17, 31, 27, 31
	add		r19, r19, r22
	rlwimi	r25, r17,  7, 25, 30
	lhz		r26,  0x0d20(r25)
	rlwimi	r25, r19,  1, 28, 30
	stw		r16, EWA.Flags(r1)
	rlwimi	r26, r26,  8,  8, 15		; copy hi byte of entry to second byte of word
	rlwimi	r25, r17,  4, 23, 27
	mtcrf	 0x10, r26					; so the second nybble of the entry is copied to cr3
	lha		r22,  0x0c00(r25)
	addi	r23, r8,  0x4e0
	add		r22, r22, r25
	mfsprg	r24, 3
	mtlr	r22
	mtsprg	3, r23
	mfmsr	r14
	ori		r15, r14,  0x10
	mtmsr	r15
	isync
	rlwimi	r25, r26,  2, 22, 29		; apparently the lower byte of the entry is an FDP (code?) offset, /4!
	bnelr-
	b		FDP_011c



SuspendBlueTask
	bl		SchSaveStartingAtR14		; r8 := EWA

	lwz		r31, EWA.PA_CurTask(r8)
	lwz		r8, Task.ExceptionHandlerID(r31)
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass
	mr		r30, r8
	bnel-	@no_exception_handler

	lwz		r28, Queue.ReservePtr(r30)
	cmpwi	r28, 0
	beql-	@no_memory_reserved_for_exception_messages

;notify exception handler
	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r29, Task.Flags(r31)
	_bset	r29, r29, Task.kFlag22
	_bset	r29, r29, Task.kFlag19
	stw		r29, Task.Flags(r31)

	;	pop 'notr'
	lwz		r17, Message.LLL + LLL.Next(r28)
	stw		r17, Queue.ReservePtr(r30)

	;	word1 = task ID
	lwz		r17, Task.ID(r31)
	stw		r17, Message.Word1(r28)

	;	word 2 = kMPTaskAbortedErr
	li		r18, kMPTaskAbortedErr
	stw		r18, Message.Word2(r28)
	stw		r18, Task.ErrToReturnIfIDie(r31)

	;	word 3 = SRR0
	stw		r10, Message.Word3(r28)

	_log	'Blue task suspended. Notifying exception handler - srr1/0 '
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw
	_log	'lr '
	mr		r8, r12
	bl		Printw
	_log	'^n'

	mr		r31, r30
	mr		r8, r28
	bl		EnqueueMessage		; Message *r8, Queue *r31

	b		SchEval

@no_exception_handler
@no_memory_reserved_for_exception_messages
	mflr	r16
	_log	'Blue task terminated - no exception handler registered - srr1/0 '
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw
	_log	'lr '
	mr		r8, r12
	bl		Printw
	_log	'^n'
	mtlr	r16
	b		Local_Panic



TaskApproachOne	;	OUTSIDE REFERER

	bcl		BO_IF, 27, Local_Panic
	bl		SchSaveStartingAtR14

	mr		r30, r10
	lwz		r29, EWA.r6(r8)
	lwz		r31, EWA.PA_CurTask(r8)
	stw		r29, ContextBlock.r6(r6)
	stw		r30, 0x0074(r6)						; ContextBlock.srr0?
	stw		r7, 0x0040(r6)						; ContextBlock.savedFlags?
	lwz		r1, EWA.PA_KDP(r1)

	; get task in r31, globals in r1

	_Lock			PSA.SchLock, scratch1=r28, scratch2=r29

	mr		r8, r31
	bl		SchTaskUnrdy

	lwz		r16, Task.Flags(r31)
	srwi	r8, r7, 24
	rlwinm.	r16, r16, 0, Task.kFlag9, Task.kFlag9
	cmpwi	cr1, r8, ecInstPageFault
	bne-	TaskNotSuitableForWhatWeWantToDo
	bne-	cr1, TaskNotSuitableForWhatWeWantToDo
	;	what is special about the upper 8 Flags? Are they Task-related?

	lwz		r8, Task.Zero3(r31)
	addi	r8, r8, 1
	stw		r8, Task.Zero3(r31)

	b		CommonPathBetweenTaskIntFuncs



TaskApproachTwo	;	OUTSIDE REFERER

	bcl		BO_IF_NOT, 27, Local_Panic

	bl		PreferRegistersFromEWASavingContextBlock

	stw		r10, ContextBlock.LA_EmulatorEntry(r6)

	_bclr	r7, r7, EWA.kFlag27


	bl		SchSaveStartingAtR14

	lwz		r30,  0x0074(r6)
	lwz		r29,  0x0018(r8)
	lwz		r31, -0x0008(r8)
	stw		r29,  0x0134(r6)
	stw		r7,  0x0040(r6)
	lwz		r1, -0x0004(r1)


	_Lock			PSA.SchLock, scratch1=r28, scratch2=r29

	mr		r8, r31
	bl		SchTaskUnrdy

	lwz		r16, Task.Flags(r31)
	srwi	r8, r7, 24
	rlwinm.	r16, r16, 0, Task.kFlag9, Task.kFlag9
	cmpwi	cr1, r8, 0x14
	bne-	TaskNotSuitableForWhatWeWantToDo
	bne-	cr1, TaskNotSuitableForWhatWeWantToDo

	lwz		r8, Task.Zero4(r31)
	addi	r8, r8, 1
	stw		r8, Task.Zero4(r31)




CommonPathBetweenTaskIntFuncs

	mfsprg	r14, 0

	_bclr	r7, r7, EWA.kFlag26
	_bclr	r7, r7, EWA.kFlag31

	lwz		r29, EWA.SpecialAreaPtr(r14)
	lisori	r17, Area.kSignature
	lwz		r16, Area.Signature(r29)
	cmplw	r16, r17
	bnel+	Local_Panic

	lwz		r17, Area.Counter(r29)
	addi	r17, r17, 1
	stw		r17, Area.Counter(r29)

	lwz		r8, Area.BackingProviderID(r29) ; this is a notification? ugh...
	bl		LookupID

	lwz		r16, KDP.VMMaxVirtualPages(r1)
	cmpwi	cr0, r9, ecInstPageFault
	cmpwi	cr1, r16, 0
	mr		r26, r8
	bne-	cr0, CanSendMessage
	beq-	cr1, CantSendMessage
	beq-	cr2, CanSendMessage

CantSendMessage
	lwz		r16, Task.Flags(r31)
	addi	r17, r31, Task.QueueMember
	addi	r18, r31, Task.Semaphore

	stw		r18, LLL.Freeform(r17)
	InsertAsPrev	r17, r18, scratch=r19

	li		r17, 1
	_bset	r16, r16, Task.kFlag18
	stw		r17, Task.Semaphore + Semaphore.Value(r31)
	stw		r16, Task.Flags(r31)

	rlwinm	r30, r30,  0,  0, 19

	lwz		r27,  0x0000(r29)
	lwz		r28,  0x0000(r31)
	stw		r30,  0x0010(r26)
	stw		r27,  0x0014(r26)
	stw		r28,  0x0018(r26)

	mr		r30, r26
	bl		CauseNotification

	cmpwi	r8, 0
	beq+	IntLocalBlockMPCall				; jump if no error?

CanSendMessage
	mfcr	r28
	li		r8, Message.Size
	beq-	cr2, major_0x02ccc_0x4a8
	bl		PoolAlloc
	mr.		r26, r8
	beq-	major_0x02ccc_PoolAllocFailed

	addi	r17, r31, Task.QueueMember
	addi	r18, r31, Task.Semaphore
	stw		r18, LLL.Freeform(r17)
	InsertAsPrev	r17, r18, scratch=r19					; make this task wait on its own semaphore

	li		r17, 1
	stw		r17, Task.Semaphore + Semaphore.Value(r31)

	;	message = area ID, semaphore ID, address (page aligned?)
	lwz		r27, Area.ID(r29)
	lisori	r8, Message.kSignature
	lwz		r29, Task.Semaphore + Semaphore.BlockedTasks + LLL.Freeform(r31)
	stw		r27, Message.Word1(r26)
	stw		r29, Message.Word2(r26)
	stw		r8, Message.LLL + LLL.Signature(r26)
	stw		r30, Message.Word3(r26)

	mr		r8, r26
	addi	r31, r1, PSA.PageQueue
	bl		EnqueueMessage		; Message *r8, Queue *r31
	lwz		r8, PSA.BlueSpinningOn(r1)
	bl		UnblockBlueIfCouldBePolling
	b		BlockMPCall

major_0x02ccc_0x4a8
	mr		r8, r31
	bl		SchRdyTaskNow
	_AssertAndRelease	PSA.SchLock, scratch=r31
	mtcr	r28
	bns-	cr6, major_0x02ccc_0x504
	lwz		r8,  0x0064(r6)
	lwz		r9,  0x0068(r6)
	stw		r8,  0x0024(r6)
	stw		r9,  0x0028(r6)
	lwz		r8,  0x006c(r6)
	lwz		r9,  0x0074(r6)
	stw		r8,  0x002c(r6)
	stw		r9,  0x0034(r6)
	lwz		r8,  0x007c(r6)
	stw		r8,  0x003c(r6)
	crclr	EWA.kFlag27

major_0x02ccc_0x504
;	r6 = ewa
	bl		SchRestoreStartingAtR14
	b		major_0x02980_0x178

major_0x02ccc_PoolAllocFailed
	li		r16, Task.kNominalPriority
	stb		r16, Task.Priority(r31)
	mr		r8, r31
	bl		SchRdyTaskNow
	bl		FlagSchEval
	b		BlockMPCall

TaskNotSuitableForWhatWeWantToDo
	b		FuncExportedFromTasks



;	                     IntDecrementer

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDecrementer	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	lwz		r8, KDP.OldKDP(r1)
	rlwinm.	r9, r11,  0, 16, 16
	cmpwi	cr1, r8,  0x00
	beq-	MaskedInterruptTaken
	beq-	cr1, IntDecrementer_0x54

	stw		r16, ContextBlock.r16(r6)
	stw		r17, ContextBlock.r17(r6)
	stw		r18, ContextBlock.r18(r6)
	stw		r25, ContextBlock.r25(r6)

	bl		SchFiddlePriorityShifty
	ble-	IntDecrementer_0x48

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



;	                         IntDSI

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDSI	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r2,  0x0008(r1)
	mfsprg	r11, 1
	stw		r0,  0x0000(r1)
	stw		r11,  0x0004(r1)
	li		r0,  0x00
	mfspr	r10, srr0
	mfspr	r11, srr1
	mfsprg	r12, 2
	mfcr	r13
	mfsprg	r24, 3
	lwz		r16, EWA.Flags(r1)
	lwz		r1, -0x0004(r1)
	mfspr	r26, dsisr
	addi	r23, r1,  0x4e0
	andis.	r28, r26,  0x400
	mtsprg	3, r23
	mfmsr	r14
	bne-	major_0x03324_0x9c
	ori		r15, r14,  0x10
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync



;	                     major_0x03324

;	Xrefs:
;	IntDSI
;	FDP_1214

major_0x03324	;	OUTSIDE REFERER
	rlwinm.	r18, r27, 18, 25, 29
	lwz		r25,  0x0650(r1)
	li		r21,  0x00
	mfsprg	r1, 0
	beq-	major_0x03324_0x18
	lwzx	r18, r1, r18

major_0x03324_0x18
	andis.	r26, r27,  0xec00
	lwz		r16, EWA.Flags(r1)
	rlwinm	r17, r27,  0,  6, 15
	rlwimi	r16, r16, 27, 26, 26
	bge-	major_0x03324_0x58
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
	blelr-	cr3
	neg		r23, r23
	add		r18, r18, r23
	blr

major_0x03324_0x9c	;	OUTSIDE REFERER
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
	bl		V2P
	mr		r16, r28
	crset	cr3_so
	mfsprg	r1, 0
	beq-	major_0x03324_0x12c
	mr		r18, r8
	rlwinm	r28, r27, 13, 25, 29
	andis.	r9, r31,  0x200
	rlwimi	r18, r17,  0,  0, 19
	beq-	major_0x03324_0x118
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



;	                      IntAlignment

;	Xrefs:
;	"vec"

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

	rlwinm.	r21, r21, 0, Task.kFlag9, Task.kFlag9

	addi	r23, r1, KDP.RedVecBase

	bne-	major_0x03548_0x20

	;	DSISR for misaligned X-form instruction:

	;	(0) 0 (14)||(15) 29:30 (16)||(17) 25 (17)||(18) 21:24 (21)||(22) rD (26)||(27) rA? (31)

	;	DSISR for misaligned D-form instruction:
	
	;	(0)        zero        (16)||(17)  5 (17)||(18)  1:4  (21)||(22) rD (26)||(27) rA? (31)

FDP_TableBase		equ		0xa00

	;	Virtual PC might put the thing in MSR_LE mode
	rlwinm.	r21, r11, 0, MSR_LEbit, MSR_LEbit			;	msr bits in srr1

	;	Get the FDP and F.O. if we were in MSR_LE mode
	lwz		r25,  KDP.PA_FDP(r1)
	bne-	major_0x03548_0x20


	rlwinm.	r21, r27, 17, 30, 31	; evaluate hi two bits of XO (or 0 for d-form?)

	rlwinm	r17, r27, 16,  6, 15	; save src and dest register indices in r17

	mfsprg	r1, 0

	rlwimi	r25, r27, 24, 23, 29	; add constant fields from dsisr (*4) to FDP


	rlwimi	r16, r16, 27, 26, 26	; AllCpuFeatures: copy bit 21 to bit 26

	bne-	@regidx

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
	bgelr-	cr3						; jump now if bit 12 is off

	;	if bit 12 was on, turn on paging and fetch the offending insn
	;	and also activate the Red vector table
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync
	mtsprg	3, r24
	blr



;	                     major_0x03548

;	Xrefs:
;	IntAlignment
;	major_0x05808

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
	b		major_0x02980



;	                    IntDSIOtherOther

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDSIOtherOther	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mfspr	r31, dsisr
	mfspr	r27, dar
	andis.	r28, r31,  0xc030
	lwz		r1, -0x0004(r1)
	bne-	IntDSIOtherOther_0x1c8
	mfspr	r30, srr1
	andi.	r28, r30,  0x4000
	mfsprg	r30, 0
	beq-	IntDSIOtherOther_0x100
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
	blt-	IntDSIOtherOther_0xe0
	bgt-	cr7, IntDSIOtherOther_0xe0
	mr		r31, r8
	mr		r8, r27
	bl		MPCall_95_0x1e4
	beq-	IntDSIOtherOther_0xe0
	lwz		r8,  0x0000(r30)
	lwz		r16,  0x0098(r31)
	rlwinm	r28, r8,  0, 29, 30
	cmpwi	cr7, r28,  0x04
	cmpwi	r28,  0x02
	beq-	cr7, IntDSIOtherOther_0xe0
	beq-	IntDSIOtherOther_0xe0

IntDSIOtherOther_0x98
	addi	r17, r31,  0x90
	cmpw	r16, r17
	addi	r17, r16,  0x14
	beq-	IntDSIOtherOther_0x158
	lwz		r9,  0x0010(r16)
	add		r9, r9, r17

IntDSIOtherOther_0xb0
	lwz		r18,  0x0000(r17)
	cmplw	cr7, r17, r9
	lwz		r19,  0x0004(r17)
	bgt-	cr7, IntDSIOtherOther_0xd8
	cmplw	r27, r18
	cmplw	cr7, r27, r19
	blt-	IntDSIOtherOther_0xd0
	ble-	cr7, IntDSIOtherOther_0xe0

IntDSIOtherOther_0xd0
	addi	r17, r17,  0x08
	b		IntDSIOtherOther_0xb0

IntDSIOtherOther_0xd8
	lwz		r16,  0x0008(r16)
	b		IntDSIOtherOther_0x98

IntDSIOtherOther_0xe0
	mfsprg	r30, 0
	mfspr	r31, dsisr
	lwz		r8, -0x00e0(r30)
	lwz		r9, -0x00dc(r30)
	lwz		r16, -0x00d8(r30)
	lwz		r17, -0x00d4(r30)
	lwz		r18, -0x00d0(r30)
	lwz		r19, -0x00cc(r30)

IntDSIOtherOther_0x100
	andis.	r28, r31,  0x800
	addi	r29, r1, 800
	bnel-	PagingFunc3
	li		r28,  0x43
	and		r28, r31, r28
	cmpwi	cr7, r28,  0x43
	beql+	Local_Panic
	mfsprg	r28, 2
	mtlr	r28
	bne-	cr7, IntDSIOtherOther_0x144
	mfspr	r28, srr0
	addi	r28, r28,  0x04
	lwz		r26,  0x0e90(r1)
	mtspr	srr0, r28
	addi	r26, r26,  0x01
	stw		r26,  0x0e90(r1)
	b		IntDSIOtherOther_0x19c

IntDSIOtherOther_0x144
	andi.	r28, r31,  0x03
	li		r8, ecDataSupAccessViolation
	beq+	major_0x02980
	li		r8, ecDataWriteViolation
	b		major_0x02980

IntDSIOtherOther_0x158
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

IntDSIOtherOther_0x19c
	mfsprg	r1, 1
	rlwinm	r26, r25, 30, 24, 31
	rfi
	dcb.b	32, 0


IntDSIOtherOther_0x1c8
	andis.	r28, r31,  0x8010
	bne-	IntMachineCheckMemRetry_0x14c

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	bl		PagingFunc1
	_AssertAndRelease	PSA.HTABLock, scratch=r28
	mfsprg	r28, 2
	mtlr	r28
	beq+	IntDSIOtherOther_0x19c
	li		r8, ecDataInvalidAccess
	bge+	major_0x02980
	li		r8, ecDataPageFault
	b		major_0x02980



;	                IntMachineCheckMemRetry

;	Xrefs:
;	"vec"
;	IntDSIOtherOther

IntMachineCheckMemRetry	;	OUTSIDE REFERER
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
	blt-	IntMachineCheckMemRetry_0x14c
	cmpwi	r28,  0x10
	bgt-	IntMachineCheckMemRetry_0x14c

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
	beq-	IntMachineCheckMemRetry_0x124
	sync
	tlbsync

IntMachineCheckMemRetry_0x124
	sync
	isync
	_AssertAndRelease	PSA.HTABLock, scratch=r28

IntMachineCheckMemRetry_0x14c	;	OUTSIDE REFERER
	cmplw	r10, r19
	li		r8, ecDataHardwareFault
	bne+	major_0x02980
	mfsprg	r1, 0
	mtsprg	3, r24
	lmw		r14,  0x0038(r1)
	li		r8, ecInstHardwareFault
	b		major_0x02980_0x134



;	                         IntISI

;	Xrefs:
;	"vec"

	align	kIntAlign

IntISI	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	andis.	r8, r11,  0x4020
	beq-	major_0x039dc_0x14
	mfsprg	r8, 0
	stmw	r14,  0x0038(r8)

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	mr		r27, r10
	bl		PagingFunc1
	_AssertAndRelease	PSA.HTABLock, scratch=r28
	mfsprg	r8, 0
	bne-	major_0x039dc
	mfsprg	r24, 3
	mfmsr	r14
	ori		r15, r14,  0x10
	addi	r23, r1,  0x4e0
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



;	                     major_0x039dc

;	Xrefs:
;	IntISI
;	IntDSIOther

major_0x039dc	;	OUTSIDE REFERER
	lmw		r14,  0x0038(r8)
	li		r8, ecInstPageFault
	blt+	major_0x02980_0x134
	li		r8, ecInstInvalidAddress
	b		major_0x02980_0x134

major_0x039dc_0x14	;	OUTSIDE REFERER
	andis.	r8, r11,  0x800
	li		r8, ecInstSupAccessViolation
	bne+	major_0x02980_0x134
	li		r8, ecInstHardwareFault
	b		major_0x02980_0x134



;	                    IntMachineCheck

;	Xrefs:
;	"vec"

IntMachineCheck	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

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
	beq-	@not_L1_data_cache_error

;L1 data cache error
	bl		FlushL1CacheUsingMSSCR0
	b		IntReturn

@not_L1_data_cache_error
	li		r8, ecMachineCheck
	b		major_0x02980_0x134



;	                     MaskedInterruptTaken

;	Xrefs:
;	IntDecrementer
;	IntPerfMonitor
;	IntThermalEvent
;	IntExternalYellow

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
	b		major_0x02980_0x134



;	                      IntDSIOther

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDSIOther	;	OUTSIDE REFERER
	mfspr	r8, dsisr
	rlwimi	r11, r8,  0,  0,  9
	andis.	r8, r11,  0x4020
	beq+	major_0x039dc_0x14
	mfsprg	r8, 0
	stmw	r14,  0x0038(r8)
	lwz		r1, -0x0004(r8)

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	mfspr	r27, dar
	bl		PagingFunc1
	_AssertAndRelease	PSA.HTABLock, scratch=r28
	mfsprg	r8, 0
	bne+	major_0x039dc
	lmw		r14,  0x0038(r8)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




;	                     major_0x03be0

;	Xrefs:
;	"sup"

	align	kIntAlign

;	dead code?

	lwz		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r1)
	mr		r10, r12
	addi	r11, r11, 1
	stw		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r1)
	mfsrr1	r11
	rlwimi	r7, r7, 27, 26, 26

kcReturnFromException	;	OUTSIDE REFERER
	ori		r11, r11,  0x8000
	mtcrf	 0x3f, r7
	cmplwi	cr1, r3,  0x01
	blt-	cr4, major_0x04a20_0x18
	blt-	cr1, major_0x03be0_0x58
	beq-	cr1, major_0x03be0_0x90
	addi	r8, r3, -0x20
	lwz		r9,  0x0eac(r1)
	cmplwi	r8,  0xe0
	addi	r9, r9,  0x01
	stw		r9,  0x0eac(r1)
	mfsprg	r1, 0
	rlwimi	r7, r3, 24,  0,  7
	blt-	major_0x03be0_0xe8
	li		r8, ecTrapInstr
	b		major_0x02980_0x134

major_0x03be0_0x58
	mfsprg	r1, 0
	lwz		r8,  0x0040(r6)
	lwz		r10,  0x0084(r6)
	rlwimi	r7, r8,  0, 17,  7
	lwz		r8,  0x0044(r6)
	rlwimi	r11, r7,  0, 20, 23
	stw		r8, EWA.Enables(r1)
	andi.	r8, r11,  0x900
	lwz		r12,  0x008c(r6)
	lwz		r3,  0x0094(r6)
	lwz		r4,  0x009c(r6)
	bnel-	major_0x03e18
	addi	r9, r6,  0x40
	b		IntReturn

major_0x03be0_0x90
	lwz		r9,  0x0ea8(r1)
	lwz		r8,  0x0040(r6)
	addi	r9, r9,  0x01
	stw		r9,  0x0ea8(r1)
	mfsprg	r1, 0
	lwz		r10,  0x0084(r6)
	rlwimi	r7, r8,  0, 17,  7
	lwz		r8,  0x0044(r6)
	mtcrf	 0x0f, r7
	rlwimi	r11, r7,  0, 20, 23
	stw		r8, EWA.Enables(r1)
	lwz		r12,  0x008c(r6)
	lwz		r3,  0x0094(r6)
	lwz		r4,  0x009c(r6)
	bne-	cr2, major_0x03be0_0xe8
	bns-	cr6, major_0x03be0_0xe8
	stmw	r14,  0x0038(r1)
	lwz		r17,  0x0064(r6)
	lwz		r20,  0x0068(r6)
	lwz		r21,  0x006c(r6)
	lwz		r19,  0x0074(r6)
	lwz		r18,  0x007c(r6)

major_0x03be0_0xe8
	beq+	cr2, major_0x02980_0x178
	crclr	cr6_so
	mfspr	r10, srr0
	li		r8, ecTrapInstr
	b		major_0x02980_0x134



;	                   save_all_registers

;	Xrefs:
;	IntPerfMonitor
;	IntThermalEvent

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

int_prepare

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



;	                      IntFPUnavail

;	Xrefs:
;	"vec"

	align	kIntAlign

IntFPUnavail	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stw		r11, -0x0290(r1)
	stw		r6, -0x028c(r1)
	lwz		r6, -0x0004(r1)
	lwz		r11,  0x0e88(r6)
	addi	r11, r11,  0x01
	stw		r11,  0x0e88(r6)
	mfspr	r11, srr1
	ori		r11, r11,  0x2000
	mtspr	srr1, r11
	mfmsr	r11
	ori		r11, r11,  0x2000
	lwz		r6, -0x0014(r1)
	mtmsr	r11
	isync
	bl		LoadFloatsFromContextBlock
	lwz		r11, -0x0290(r1)
	lwz		r6, -0x028c(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




;	                     major_0x03e18

;	Xrefs:
;	major_0x02980
;	major_0x03be0
;	IntFPUnavail
;	kcRTASDispatch

major_0x03e18	;	OUTSIDE REFERER
	rlwinm.	r8, r11,  0, 18, 18
	bnelr-

major_0x03e18_0x8	;	OUTSIDE REFERER
	lwz		r8,  0x00e4(r6)
	rlwinm.	r8, r8,  1,  0,  0
	mfmsr	r8
	ori		r8, r8,  0x2000
	beqlr-
	mtmsr	r8
	isync
	ori		r11, r11,  0x2000

LoadFloatsFromContextBlock	;	OUTSIDE REFERER
	lfd		f31,  0x00e0(r6)
	lfd		f0,  0x0200(r6)
	lfd		f1,  0x0208(r6)
	lfd		f2,  0x0210(r6)
	lfd		f3,  0x0218(r6)
	lfd		f4,  0x0220(r6)
	lfd		f5,  0x0228(r6)
	lfd		f6,  0x0230(r6)
	lfd		f7,  0x0238(r6)
	mtfsf	 0xff, f31
	lfd		f8,  0x0240(r6)
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
	blr





major_0x03e18_0xb4	;	OUTSIDE REFERER
	mfmsr	r8
	ori		r8, r8,  0x2000
	mtmsr	r8
	isync
	_bclr	r11, r11, 18
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
	stfd	f17,  0x0288(r6)
	stfd	f18,  0x0290(r6)
	stfd	f19,  0x0298(r6)
	stfd	f20,  0x02a0(r6)
	stfd	f21,  0x02a8(r6)
	stfd	f22,  0x02b0(r6)
	stfd	f23,  0x02b8(r6)
	mffs	f0
	stfd	f24,  0x02c0(r6)
	stfd	f25,  0x02c8(r6)
	stfd	f26,  0x02d0(r6)
	stfd	f27,  0x02d8(r6)
	stfd	f28,  0x02e0(r6)
	stfd	f29,  0x02e8(r6)
	stfd	f30,  0x02f0(r6)
	stfd	f31,  0x02f8(r6)
	stfd	f0,  0x00e0(r6)
	blr




;	indexed emulation code, mofo

;two instructions per load-store register

	macro
	CreateFloatJumpTable	&opcode, &dest, &highest==31

	if		&highest > 0
		CreateFloatJumpTable	&opcode, &dest, highest = (&highest) - 1
	endif

	&opcode		(&highest), -0x2e0(r1)
	b			&dest

	endm


FloatLoadJumpTable
	CreateFloatJumpTable	lfd, FDP_0da0


FloatSaveJumpTable
	CreateFloatJumpTable	stfd, FDP_003c




;	                     major_0x04180

;	Xrefs:
;	IntPerfMonitor

	align	6

major_0x04180	;	OUTSIDE REFERER
	stw		r6, -0x0290(r1)
	stw		r10, -0x028c(r1)
	stw		r11, -0x0288(r1)
	lwz		r6, -0x0014(r1)
	lwz		r10,  0x00d8(r6)
	mfspr	r11, srr1
	cmpwi	r10,  0x00
	beql-	major_0x04180_0x9c
	oris	r11, r11,  0x200
	stw		r9, -0x027c(r1)
	mtspr	srr1, r11
	mfmsr	r11
	oris	r11, r11,  0x200
	mtmsr	r11
	isync
	bl		Restore_v0_v31
	lwz		r8, -0x0004(r1)
	lwz		r11,  0x0ed4(r8)
	addi	r11, r11,  0x01
	stw		r11,  0x0ed4(r8)
	mtcr	r13
	lwz		r6, -0x0290(r1)
	lwz		r10, -0x028c(r1)
	lwz		r11, -0x0288(r1)
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	lwz		r9, -0x027c(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0


major_0x04180_0x9c
	mtcr	r13
	lwz		r6, -0x0290(r1)
	lwz		r10, -0x028c(r1)
	lwz		r11, -0x0288(r1)
	lwz		r13, -0x0284(r1)

;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	li		r8, ecInvalidInstr
	b		major_0x02980_0x134



;	                     IntPerfMonitor

;	Xrefs:
;	"vec"

	align	kIntAlign

IntPerfMonitor	;	OUTSIDE REFERER
	mtlr	r1
	mfsprg	r1, 0
	stw		r8, -0x0280(r1)
	stw		r13, -0x0284(r1)
	mflr	r8
	mfcr	r13
	cmpwi	r8,  0xf20
	beq+	major_0x04180
	mtcr	r13
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq+	MaskedInterruptTaken

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, -0x0414(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne-	IntPerfMonitor_0x88
	lwz		r16, -0x0340(r28)
	lwz		r17, -0x0008(r28)
	stw		r16,  0x0010(r30)
	lwz		r16,  0x0000(r17)
	stw		r16,  0x0014(r30)
	mfspr	r16, 955
	stw		r16,  0x0018(r30)
	bl		CauseNotification

IntPerfMonitor_0x88
	_AssertAndRelease	PSA.SchLock, scratch=r8

;	r6 = ewa
	bl		SchRestoreStartingAtR14
	b		IntReturn



;	Notify the Thermal Handler

	align	kIntAlign

IntThermalEvent	;	OUTSIDE REFERER
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq+	MaskedInterruptTaken
	_log	'Thermal event^n'

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, PSA.ThermalHandlerID(r1)
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	mr		r30, r8
	bne-	@no_thermal_handler

	lwz		r16, EWA.CPUBase + CPU.ID(r28)
	stw		r16, Notification.MsgWord1(r30)
	bl		CauseNotification
@no_thermal_handler

	_AssertAndRelease	PSA.SchLock, scratch=r8
	bl		SchRestoreStartingAtR14
	b		IntReturn



;	                     kcRunAlternateContext

;	Xrefs:
;	"sup"

	align	kIntAlign

kcRunAlternateContext	;	OUTSIDE REFERER

	mtcrf	0x3f, r7

	bcl		BO_IF_NOT, 10, IntReturn

	and.	r8, r4, r13
	lwz		r9, KDP.MinusOne1(r1)
	rlwinm	r8, r3,  0,  0, 25
	cmpw	cr1, r8, r9
	bne+	IntReturn
	lwz		r9,  0x0344(r1)
	bne-	cr1, major_0x043a0_0x48

major_0x043a0_0x24
	addi	r8, r1,  0x420
	mtsprg	3, r8
	lwz		r8,  0x0648(r1)
	mtcrf	 0x3f, r7
	mfsprg	r1, 0
	clrlwi	r7, r7,  0x08
	stw		r8,  0x005c(r9)
	stw		r9, -0x0014(r1)
	b		major_0x02980_0x18c

major_0x043a0_0x48
	lwz		r9,  0x0348(r1)
	cmpw	cr1, r8, r9
	beq-	cr1, major_0x043a0_0x130
	lwz		r9,  0x0350(r1)
	cmpw	cr1, r8, r9
	beq-	cr1, major_0x043a0_0x110
	lwz		r9,  0x0358(r1)
	cmpw	cr1, r8, r9
	beq-	cr1, major_0x043a0_0xf0
	mfsprg	r1, 0
	stmw	r14,  0x0038(r1)
	lwz		r1, -0x0004(r1)
	cmpw	cr1, r8, r6
	beq-	cr1, major_0x043a0_0x154
	mr		r27, r8
	addi	r29, r1, 800
	bl		PagingFunc3
	clrlwi	r23, r8,  0x14
	beq-	major_0x043a0_0x154
	cmplwi	r23,  0xd00
	mr		r9, r8
	mr		r8, r31
	ble-	major_0x043a0_0xc4
	addi	r27, r27,  0x1000
	addi	r29, r1, 800
	bl		PagingFunc3
	beq-	major_0x043a0_0x154
	addi	r31, r31, -0x1000
	xor		r23, r8, r31
	rlwinm.	r23, r23,  0, 25, 22
	bne-	major_0x043a0_0x154

major_0x043a0_0xc4
	clrlwi	r23, r31,  0x1e
	cmpwi	r23,  0x03
	rlwimi	r8, r9,  0, 20, 31
	beq-	major_0x043a0_0x154
	lwz		r23,  0x0ea4(r1)
	addi	r23, r23,  0x01
	stw		r23,  0x0ea4(r1)
	mfsprg	r1, 0
	lmw		r14,  0x0038(r1)
	lwz		r1, -0x0004(r1)
	stw		r8,  0x035c(r1)

major_0x043a0_0xf0
	lwz		r8,  0x0350(r1)
	stw		r9,  0x0350(r1)
	stw		r8,  0x0358(r1)
	lwz		r9,  0x035c(r1)
	lwz		r8,  0x0354(r1)
	stw		r9,  0x0354(r1)
	stw		r8,  0x035c(r1)
	lwz		r9,  0x0350(r1)

major_0x043a0_0x110
	lwz		r8,  0x0348(r1)
	stw		r9,  0x0348(r1)
	stw		r8,  0x0350(r1)
	lwz		r9,  0x0354(r1)
	lwz		r8,  0x034c(r1)
	stw		r9,  0x034c(r1)
	stw		r8,  0x0354(r1)
	lwz		r9,  0x0348(r1)

major_0x043a0_0x130
	lwz		r8,  0x0340(r1)
	stw		r9,  0x0340(r1)
	stw		r9,  0x05b4(r1)
	stw		r8,  0x0348(r1)
	lwz		r9,  0x034c(r1)
	lwz		r8,  0x0344(r1)
	stw		r9,  0x0344(r1)
	stw		r8,  0x034c(r1)
	b		major_0x043a0_0x24

major_0x043a0_0x154
	mfsprg	r1, 0
	lmw		r14,  0x0038(r1)
	lwz		r1, -0x0004(r1)
	li		r8, ecTrapInstr
	b		major_0x02980_0x134



;	                        wordfill

;	Xrefs:
;	setup
;	FillIndigo

;	> r8    = dest
;	> r22   = len in bytes
;	> r23   = fillword

wordfill	;	OUTSIDE REFERER
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne+	wordfill
	blr



;	Handle a 68k reset trap.

;	If A0(r3)/A1(r4) == 'Gary'/$05051955, load the register list in A3? Or is this now disabled?

;	New SRR0 = SRR0 & ~r5(D0) | r7(D2)

	align	kIntAlign

kcResetSystem	;	OUTSIDE REFERER
;	r6 = ewa
	bl		SchSaveStartingAtR14
;	r8 = sprg0 (not used by me)

	;	Check for 601 (rtc vs timebase)
	mfpvr	r9
	rlwinm.	r9, r9, 0,  0, 14

	;	This xoris/cmplwi technique is very cool
	xoris	r8, r3, 'Ga'

	beq-	@is_601
	mftb	r9
	b		@endif_601
@is_601
	dialect	POWER
	mfrtcl	r9
	dialect	PowerPC
@endif_601

	;	Not sure why this would need to hit cr0?
	andis.	r9, r9,  0xffff

	cmplwi	r8, 'ry'
	bne-	NonGaryReset

	;	r4 (i.e. A1) == 5 May 1956?
	xoris	r8, r4, 0x0505
	cmplwi	r8,     0x1956
	bne-	NonGaryReset

	andc	r11, r11, r5
	lwz		r8, ContextBlock.r7(r6)
	or		r11, r11, r8

	_log	'Skeleton key inserted at'

	mr		r8, r11
	bl		Printw

	mr		r8, r10
	bl		Printw

	_log	'^n'
	
	b		IntReturn



;	                NonGaryReset

;	A 68k reset trap without Gary Davidian's magic numbers.

;	Xrefs:
;	kcResetSystem

NonGaryReset

	_log	'ResetSystem trap entered^n'

	lwz		r8, KDP.OldKDP(r1)

	cmpwi	r8, 0
	beq+	ResetBuiltinKernel

	_log	'Unplugging the replacement nanokernel^n'

	lwz		r8, KDP.OldKDP(r1)
	mfsprg	r1, 0
	addi	r9, r8, KDP.YellowVecBase
	mtsprg	0, r8		;	old NK has only one EWA!
	mtsprg	3, r9

	lwz		r9, EWA.r1(r1)
	stw		r9, EWA.r1(r8)

	lwz		r9, EWA.r6(r1)
	stw		r9, EWA.r6(r8)

	stw		r6,  0x065c(r8)
	stw		r7,  0x0660(r8)			; ??????????

	lwz		r9, EWA.Enables(r1)
	stw		r9,  0x0664(r8)

;	r6 = ewa
	bl		SchRestoreStartingAtR14
	subi	r10, r10, 4
	lwz		r1, -0x0004(r1)

;	sprg0 = for r1 and r6
;	r1 = kdp
;	r6 = register restore area
;	r7 = flag to insert into XER
;	r10 = new srr0 (return location)
;	r11 = new srr1
;	r12 = lr restore
;	r13 = cr restore
	b		SchExitInterrupt



;	                      kcPrioritizeInterrupts

;	Xrefs:
;	"sup"
;	setup
;	IntExternalYellow

;	> r1    = kdp

kcPrioritizeInterrupts	;	OUTSIDE REFERER
	lwz		r9, KDP.PA_InterruptHandler(r1)
	mtlr	r9
	blr



;	Move registers from CB to EWA, and Thud.

	align	kIntAlign

kcThud

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

	bl		Local_Panic



;	                     major_0x046d0

;	Xrefs:
;	"vec"
;	kcThud

major_0x046d0	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	li		r8, ecTrapInstr
	b		major_0x02980_0x134



;	                     IntExternalOrange

;	Xrefs:
;	"vec"

	align	kIntAlign

IntExternalOrange	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	mtcrf	 0x3f, r7
	bnel+	cr2, Local_Panic
	li		r8, ecNoException
	b		major_0x02980_0x134



	align	kIntAlign

IntProgram

	bl		int_prepare

	lwz		r8, KDP.LA_EmulatorKernelTrapTable(r1)
	mtcr	r11						; UNUSUAL to have SRR1 in condition register
	xor		r8, r10, r8
	bc		BO_IF_NOT, 14, @not_trap


	;	Program interrupt caused by a trap instruction


	;	From the table of twis in the emulator code image? Then return will be to LR.

	cmplwi	cr0, r8, NanoKernelCallTable.ReturnFromException
	cmplwi	cr1, r8, NanoKernelCallTable.MPDispatch
	beq-	cr0, @emutrap_0_return_from_exception
	beq-	cr1, @emutrap_8_mpdispatch
	cmplwi	cr0, r8, NanoKernelCallTable.VMDispatch
	cmplwi	cr1, r8, NanoKernelCallTable.Size
	beq-	cr0, @emutrap_3_vmdispatch
	blt-	cr1, @emutrap_other


	;	Not from the emulator image? Return will be to next instruction,
	;	and we will read the trap instruction from memory

	;	If !MSR[IR], turn on MSR[DR] for just a moment
	bc		BO_IF_NOT, 26, @_IntProgram_0x58
	stw		r14, ContextBlock.r14(r6)
	mfsprg	r14, 3
	addi	r8, r1, PSA.BlueVecBase
	mfmsr	r9
	mtsprg	3, r8
	_bset	r8, r9, 27				; turn on data paging (MSR[DR]) for just a sec
	mtmsr	r8
	isync
@_IntProgram_0x58

	;	Get the offending instruction!
	lwz		r8, 0(r10)

	;	If !MSR[IR], restore MSR
	bc		BO_IF_NOT, 26, @_IntProgram_0x74
	isync
	mtmsr	r9
	isync
	mtsprg	3, r14
	lwz		r14, ContextBlock.r14(r6)
@_IntProgram_0x74


	;	Switch from SRR1-in-CR to Flags-in-CR

	mtcr	r7


	;	Read the bottom half of the non-emu-image trap instruction, getting trapnum*8 in r8
	xoris	r8, r8, 0xfff
	cmplwi	cr0, r8, NanoKernelCallTable.Size / 4
	cmplwi	cr1, r8, NanoKernelCallTable.ReturnFromException / 4
	bge-	cr0, @trap_too_high
	cmplwi	cr7, r8, NanoKernelCallTable.MPDispatch / 4
	cmplwi	cr0, r8, NanoKernelCallTable.VMDispatch / 4
	slwi	r8, r8, 2
	beq-	cr1, @nonemu_return_from_exception
	beq-	cr7, @nonemu_mpdispatch
	beq-	cr0, @nonemu_vmdispatch

	;	Fall through to some hard truths
	bc		BO_IF, 16, @_IntProgram_0x150
	bc		BO_IF, 8, @_IntProgram_0xac
	bc		BO_IF_NOT, 9, @_IntProgram_0x150

@nonemu_return_from_exception
@nonemu_vmdispatch
@_IntProgram_0xac
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9,  1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)

@nonemu_go
	lwz		r8, KDP.NanoKernelCallTable(r8)
	mtlr	r8
	addi	r10, r10, 4
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlag22 into EWA.kFlag26
	blr

@nonemu_mpdispatch
	lwz		r9, ContextBlock.r0(r6)
	add		r8, r8, r1
	cmpwi	r9, -1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	bne+	@nonemu_go

	;	Non-emu MPDispatch trap with r0 == -1: muck around a bit?
	addi	r10, r10, 4
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlag22 into EWA.kFlag26
	mfsprg	r8, 0
	rlwimi	r13, r7, 8, 2, 2
	lwz		r9, EWA.PA_CurTask(r8)
	xoris	r13, r13,  0x2000
	lwz		r8, Task.SomeLabelField(r9)
	stw		r8, ContextBlock.r0(r6)
	b		IntReturn


@emutrap_other
@_IntProgram_0x110
	mtcr	r7
	bc		BO_IF, 16, @_IntProgram_0x150
	bc		BO_IF, 8, @_IntProgram_0x120
	bc		BO_IF_NOT, 9, @_IntProgram_0x150

@emutrap_0_return_from_exception
@emutrap_8_mpdispatch
@emutrap_3_vmdispatch
@_IntProgram_0x120
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	lwz		r10, KDP.NanoKernelCallTable(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	mtlr	r10
	mr		r10, r12								; return to whatever the emulator left in the PPC link register
	rlwimi	r7, r7, 27, 26, 26
	blr


	;	Program interrupt not caused by a trap instruction: consult SRR1 bits 11-13

@not_trap
	bc		BO_IF+1, 12, FDPEmulateInstruction		; illegal instruction exception
	bc		BO_IF,   13, FDPEmulateInstruction		; privileged instruction exception
	bc		BO_IF,   11, @floating_point_exception	; floating point exception

@trap_too_high
@_IntProgram_0x150
	rlwinm	r8, r11, 17, 28, 29						; whoa
	addi	r8, r8,  0x4b3
	rlwnm	r8, r8, r8, 28, 31
	b		major_0x02980_0x134

@floating_point_exception
	li		r8, ecFloatException

	bc		BO_IF, 15, major_0x02980_0x134			; if SRR0 points to subsequent instr
	addi	r10, r10, 4								; if SRR0 points to offending instr
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlag22 into EWA.kFlag26
	b		major_0x02980_0x134



;	                   IntExternalYellow

;	Xrefs:
;	"vec"

	align	kIntAlign

IntExternalYellow	;	OUTSIDE REFERER

	bl		int_prepare

	;	RET		r0 = 0
	;			r1 = KernelData
	;			r6 = ECB
	;			r7 = AllCpuFeatures
	;			r8 = EWA (pretend KDP)
	;			r10 = SRR0
	;			r11 = SRR1
	;			r12 = LR from SPRG2
	;			r13 = CR


	;	Sanity check

	rlwinm.	r9, r11, 0, MSR_EEbit, MSR_EEbit
	beq+	MaskedInterruptTaken


	;	How many CPUs?

	lwz		r9, EWA.CPUBase + CPU.LLL + LLL.Freeform(r8)
	lwz		r9, CoherenceGroup.CpuCount(r9)
	cmpwi	r9, 2


	;	Uniprocessor machine: go straight to PIH

	blt+	kcPrioritizeInterrupts


	;	Check with the CPU plugin whether this is an interprocessor interrupt
	;	(i.e. an alert to flag a scheduler evaluation)

	bl		SchSaveStartingAtR14

	li		r9, kSIGP9
	stw		r9, EWA.SIGPSelector(r8)
	li		r8, 1						;	args are in EWA
	bl		SIGP
	bl		SchRestoreStartingAtR14

	cmpwi	cr0, r8, -29278				;	real external interrupt
	cmpwi	cr1, r8, -29277				;	ignore
	cmpwi	cr2, r8, -29279				;	interprocessor interrupt!
										;	else: real external interrupt

	beq+	cr0, kcPrioritizeInterrupts
	beq+	cr1, IntReturn
	bne+	cr2, kcPrioritizeInterrupts
	
	mfsprg	r9, 0						;	"alert" => run scheduler evaluation
	li		r8, 1
	stb		r8, EWA.SchEvalFlag(r9)
	b		IntReturn					;	goes to SchReturn



;	"SIGnal Plugin": Call the CPU plugin PEF bundle synchronously.
;	(blue address space but in supervisor mode without interrupts)

;	ARG:

;	if r8 == 0, i.e. userspace MPCpuPlugin call:
;		r3 => routine selector
;		executing CPU index => r3
;		r4-10 => r4-10

;	if r8 != 0, i.e. internal NanoKernel call:
;		EWA.SIGPSelector => routine selector
;		executing CPU index => r3
;		PlugCallR4-10 => r4-10

;	For most NK SIGPs, r4 contains the index of the CPU being operated on

	align	5

SIGP

	mfsprg	r23, 0
	mtcr	r7

	;	r20 = offset into CPU plugin dispatch table = routine number * 4
	;
	lwz		r16, EWA.PA_CurAddressSpace(r23)
	slwi	r20, r3, 2
	stw		r16, EWA.SIGPSpacOnResume(r23)
	bc		BO_IF, 16, major_0x04a20_0x18			; not sure about this
	cmpwi	cr2, r8, 0
	lwz		r18, EWA.SIGPSelector(r23)
	beq-	cr2, @args_in_registers
	slwi	r20, r18, 2
@args_in_registers

	;	Check that a CPU plugin is installed and that the
	;	plugin dispatch table includes this command number.
	lwz		r22, EWA.CPUBase + CPU.LLL + LLL.Freeform(r23)
	li		r8, -0x7266
	lwz		r17, CoherenceGroup.PA_CpuPluginDesc(r22)
	lwz		r16, CoherenceGroup.CpuPluginSelectorCount(r22)
	mr.		r17, r17
	beqlr-
	slwi	r16, r16,  2
	li		r8, -0x7267
	cmplw	r20, r16
	bgelr-

	;	Save some registers in advance of this unusual "upcall".
	stw		r10, EWA.SIGPSavedR10(r23)
	stw		r11, EWA.SIGPSavedR11(r23)
	stw		r12, EWA.SIGPSavedR12(r23)
	stw		r13, EWA.SIGPSavedR13(r23)
	mfxer	r16
	mfctr	r17
	stw		r16, EWA.SIGPSavedXER(r23)
	mflr	r16
	stw		r17, EWA.SIGPSavedCTR(r23)
	stw		r16, EWA.SIGPSavedLR(r23)	; obviously this is getting revisited somewhere
	stw		r6, EWA.SIGPSavedR6(r23)
	stw		r7, EWA.SIGPSavedR7(r23)

	;	Change to the CPU plugin's preferred address space.
	lwz		r9, EWA.PA_CurAddressSpace(r23)
	lwz		r8, CoherenceGroup.CpuPluginSpacePtr(r22)
	cmpw	r9, r8
	beq-	@noNeedToSwitchSpace
	bl		SchSwitchSpace
@noNeedToSwitchSpace

	;	Save user registers to ContextBlock (odd way to do this).
	lwz		r16, EWA.r1(r23)
	lwz		r17, EWA.r6(r23)
	stw		r16, ContextBlock.r1(r6)
	stw		r2, ContextBlock.r2(r6)
	stw		r3, ContextBlock.r3(r6)
	stw		r4, ContextBlock.r4(r6)
	stw		r5, ContextBlock.r5(r6)
	stw		r17, ContextBlock.r6(r6)

	;	Return address for CPU plugin code (=> twi 31, r31, 0 => kcReturnFromException)
	lwz		r17, KDP.LA_EmulatorKernelTrapTable + NanoKernelCallTable.ReturnFromException(r1)

	;	Need CPU index to look up the CPU plugin stack pointer in a table
	lhz		r16, EWA.CPUIndex(r23)

	;	MSR for CPU plugin with EE (external ints) and PR (problem state) switched off
	lwz		r19, PSA.UserModeMSR(r1)
	slwi	r16, r16, 2
	rlwinm	r19, r19, 0, 18, 15

	;	SRR0 (=> program counter) = TOC[routine_idx][first long]
	;	r1 (stack ptr) = stackPtrs[cpu_idx]
	;	r2 (RTOC) = TOC[routine_idx][second long]
	lwz		r8, CoherenceGroup.PA_CpuPluginTOC(r22)
	lwz		r9, CoherenceGroup.PA_CpuPluginStackPtrs(r22)
	lwzx	r20, r8, r20
	lwz		r18, 0(r20)
	mtlr	r17
	mtspr	srr0, r18
	mtspr	srr1, r19
	lwzx	r1, r9, r16
	lwz		r2, 4(r20)

	;	r3 (first arg) = CPU index
	srwi	r3, r16, 2

	;	Flags |= 0x8000
	ori		r7, r7,  0x8000
	mr		r16, r6
	stw		r7, EWA.Flags(r23)

	;	Not sure where this ContextBlock comes from?
	addi	r6, r23, -0x318
	stw		r6, EWA.PA_ContextBlock(r23)

	beq-	cr2, @args_in_registers_2

;args not in registers
	lwz		r4, EWA.SIGPCallR4(r23)
	lwz		r5, EWA.SIGPCallR5(r23)
	lwz		r6, EWA.SIGPCallR6(r23)
	lwz		r7, EWA.SIGPCallR7(r23)
	lwz		r8, EWA.SIGPCallR8(r23)
	lwz		r9, EWA.SIGPCallR9(r23)
	lwz		r10, EWA.SIGPCallR10(r23)

	;	Go.
	rfi

@args_in_registers_2
	lwz		r6, ContextBlock.r6(r16)
	lwz		r7, ContextBlock.r7(r16)
	lwz		r8, ContextBlock.r8(r16)
	lwz		r9, ContextBlock.r9(r16)
	lwz		r10, ContextBlock.r10(r16)

	;	Go.
	rfi



;	                     major_0x04a20

;	Xrefs:
;	"vec"
;	major_0x02980
;	major_0x03be0
;	SIGP

major_0x04a20	;	OUTSIDE REFERER
	mfsprg	r23, 0
	lwz		r6, -0x0014(r23)
	lwz		r7, -0x0010(r23)
	lwz		r1, -0x0004(r23)
	mfspr	r10, srr0
	mfspr	r11, srr1

major_0x04a20_0x18	;	OUTSIDE REFERER
	mfsprg	r23, 0
	lwz		r7, -0x02b0(r23)
	andis.	r8, r11,  0x02
	stw		r7, -0x0010(r23)
	bne-	major_0x04a20_0x30
	li		r3, -0x7265

major_0x04a20_0x30
	lwz		r8, EWA.SIGPSpacOnResume(r23)
	lwz		r9, -0x001c(r23)
	cmpw	r9, r8
	beq-	major_0x04a20_0x44
	bl		SchSwitchSpace

major_0x04a20_0x44
	lwz		r10, -0x02d0(r23)
	lwz		r11, -0x02cc(r23)
	lwz		r12, -0x02c8(r23)
	lwz		r13, -0x02c4(r23)
	lwz		r8, -0x02c0(r23)
	lwz		r9, -0x02bc(r23)
	mtxer	r8
	lwz		r8, -0x02b8(r23)
	lwz		r6, -0x02b4(r23)
	mtctr	r9
	stw		r6, -0x0014(r23)
	mtlr	r8
	mr		r8, r3
	mr		r9, r4
	lwz		r16,  0x010c(r6)
	lwz		r2,  0x0114(r6)
	lwz		r3,  0x011c(r6)
	lwz		r4,  0x0124(r6)
	lwz		r5,  0x012c(r6)
	lwz		r17,  0x0134(r6)
	stw		r16,  0x0004(r23)
	stw		r17,  0x0018(r23)
	blr



;	                       IntSyscall

;	Not fully sure about this one

;	Xrefs:
;	"vec"

IntSyscall	;	OUTSIDE REFERER

	;	Only r1 and LR have been saved, so these compares clobber cr0

	cmpwi	r0, -3
	bne-	@not_minus_3

	;	sc -3:

		;	unset MSR_PR bit
		mfspr	r1, srr1
		rlwinm.	r0, r1, 26, 26, 27	; nonsense code?
		_bclr	r1, r1, 17
		blt-	@dont_unset_pr		; r0 should never have bit 0 set
		mtspr	srr1, r1
	@dont_unset_pr

		;	restore LR from SPRG2, r1 from SPRG1
		mfsprg	r1, 2
		mtlr	r1
		mfsprg	r1, 1

		rfi

@not_minus_3
	cmpwi	r0, -1
	mfsprg	r1, 0
	bne-	@not_minus_1

	;	sc -1: mess around with flags

		lwz		r0, EWA.Flags(r1)
		mfsprg	r1, 2
		rlwinm.	r0, r0,  0, 10, 10
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_minus_1
	cmpwi	r0, -2
	bne-	@not_any_special

	;	sc -2: more flag nonsense?

		lwz		r0, EWA.Flags(r1)
		lwz		r1, -0x0008(r1)
		rlwinm.	r0, r0,  0, 10, 10
		lwz		r0,  0x00ec(r1)
		mfsprg	r1, 2
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_any_special
	
	;	Positive numbered syscalls are a fast path to MPDispatch (twi 31, r31, 8)

	bl		int_prepare			;	Save the usual suspects and get comfy

;		Reg		Contains			Original saved in
;		---------------------------------------------
;		 r0		0					ContextBlock
;		 r1		KDP					EWA
;		 r2		(itself)					
;		 r3		(itself)
;		 r4		(itself)
;		 r5		(itself)
;		 r6		ContextBlock		EWA
;		 r7		AllCpuFeatures		ContextBlock
;		 r8		EWA					ContextBlock
;		 r9		(itself)			ContextBlock
;		r10		SRR0				ContextBlock
;		r11		SRR1				ContextBlock
;		r12		LR					ContextBlock
;		r13		CR					ContextBlock

	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 32(r1)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 8*4(r1)

	;	Not sure what to make of these
	_bset	r11, r11, 14
	rlwimi	r7, r7, 27, 26, 26

	b		kcMPDispatch



;	                        IntTrace

;	Xrefs:
;	"vec"

	align	kIntAlign

IntTrace	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	li		r8, ecInstTrace
	b		major_0x02980_0x134



;	                   IgnoreSoftwareInt

;	Xrefs:
;	"vec"

	align	kIntAlign

IgnoreSoftwareInt	;	OUTSIDE REFERER
	mfspr	r1, srr0
	addi	r1, r1,  0x04
	mtspr	srr0, r1
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




;	                     HandlePerfMonitorInt

;	Xrefs:
;	"vec"

	align	kIntAlign

HandlePerfMonitorInt	;	OUTSIDE REFERER
	mfspr	r1, srr1
	oris	r1, r1,  0x200
	mtspr	srr1, r1
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0

