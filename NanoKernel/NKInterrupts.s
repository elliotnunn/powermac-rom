; System = FFFFFFFF, Alt = 7DF2F700 (ecInstPageFault and ecDataPageFault disabled), same +/- VM
ecNoException				equ		0		; Exception
ecSystemCall				equ		1		; ?
ecTrapInstr					equ		2		; Exception
ecFloatException			equ		3		; Exception
ecInvalidInstr				equ		4		; Exception
ecPrivilegedInstr			equ		5		; ?
ecMachineCheck				equ		7		; Exception
ecInstTrace					equ		8		; Exception
ecInstInvalidAddress		equ		10		; Exception
ecInstHardwareFault			equ		11		; Exception
ecInstPageFault				equ		12		; Exception
ecInstSupAccessViolation	equ		14		; Exception

;	Usually from MemRetryDSI (also IntAlignment and IntMachineCheck)
ecDataInvalidAddress		equ		18		; ExceptionMemRetried
ecDataHardwareFault			equ		19		; ExceptionMemRetried
ecDataPageFault				equ		20		; ExceptionMemRetried
ecDataWriteViolation		equ		21		; ExceptionMemRetried
ecDataSupAccessViolation	equ		22		; ExceptionMemRetried
ecDataSupWriteViolation		equ		23		; ?
ecAlignment					equ		24		; ExceptionMemRetried



IntPanicIsland
	b		panic

IntLocalBlockMPCall
	b		BlockMPCall



;	ARG		EC r8, nuFlags r16, ? r17, ? r19, ? r23, vecTable *r24

	align	5

ExceptionMemRetried

	mfsprg	r1, 0
	mtsprg	3, r24

	lwz		r9, EWA.Enables(r1)
	rlwinm	r23, r17, (32-1), 27, 31
	rlwnm.	r9, r9, r8, 0, 0					; cr0.lt = (exception enabled?)

	bcl		BO_IF, EWA.kFlag15, major_0x02980_0x100

	lwz		r6, EWA.PA_ContextBlock(r1)

	_bset	r7, r16, 27

	neg		r23, r23
	mtcrf	0x3f, r7
	add		r19, r19, r23

	;	Exception code in high byte of flags
	rlwimi	r7, r8, 24, 0xFF000000


	;	Increment counter, easy enough
	lwz		r1, EWA.PA_KDP(r1)
	slwi	r8, r8, 2
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionCauseCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionCauseCounts(r8)

	srwi	r9, r7, 24

	;	Move regs from EWA to ContextBlock
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


	;	Order of preference:
	;		SIGP-return exceptions obviously separate
	;		MTasks (non-blue) -> UnhandledDataFault (ends up going to system page queue)
	;		Exception enabled for blue task (i.e. in system context) -> field exception to task
	;		Not actually a data fault -> system context (68k interrupt)
	;		Data fault that blue does not wish to handle

	cmpwi	cr1, r9, ecDataPageFault

	bc		BO_IF, EWA.kFlagSIGP,				IntReturnFromSIGP
	bc		BO_IF_NOT, EWA.kFlagBlue,			UnhandledDataFault
	blt											LetBlueHandleOwnException
	bne		cr1,								IntReturnToSystemContext
	b											UnhandledDataFault



LetBlueHandleOwnException

	;	How does the ContextBlock contain exception handling information?
	mfsprg	r1, 0
	stw		r10,  0x0084(r6)
	stw		r12,  0x008c(r6)
	stw		r3,  0x0094(r6)
	stw		r4,  0x009c(r6)
	lwz		r8, EWA.Enables(r1)
	stw		r7, ContextBlock.SavedFlags(r6)
	stw		r8, ContextBlock.SavedEnables(r6)
	li		r8, 0
	lwz		r10, ContextBlock.ExceptionHandler(r6)
	stw		r8, EWA.Enables(r1)							; disallow double-exceptions
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r4,  0x0054(r6)

	;	Which context will we pass to the task exception handler?
	lwz		r3, KDP.LA_ECB(r1)
	bc		BO_IF, 8, @pass_system_context
	lwz		r3,  KDP.LA_NCB(r1)
	_bclr	r11, r11, MSR_EEbit
@pass_system_context

	;	exception handler will return via trap in emulator code
	lwz		r12, KDP.LA_EmulatorKernelTrapTable + NanoKernelCallTable.ReturnFromException(r1)

	bcl		BO_IF, EWA.kFlagLowSaves, PreferRegistersFromEWASavingContextBlock

	rlwinm	r7, r7,  0, 29, 16							; unset 17-28
	rlwimi	r11, r7, 0, 20, 23							; threfore unset MSR[FE0/SE/BE/FE1]

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
	stw		r19, ContextBlock.SRR0(r6)
	stw		r18,  0x007c(r6)
	lmw		r14, EWA.r14(r8)
	blr



;	This is the only path to UnhandledCodeFault

Exception

	mfsprg	r1, 0
	mtcrf	0x3f, r7

	lwz		r9, EWA.Enables(r1)
	lwz		r1, EWA.PA_KDP(r1)

	rlwnm.	r9, r9, r8, 0, 0					; cr0.lt = (exception enabled?)

	;	Exception code in high byte of flags
	rlwimi	r7, r8, 24, 0xFF000000

	;	Increment counter, easy enough
	slwi	r8, r8, 2
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionCauseCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.ExceptionCauseCounts(r8)

	srwi	r9, r7, 24

	;	Order of preference:
	;		SIGP-return exceptions obviously separate
	;		MTasks (non-blue) -> UnhandledCodeFault (ends up going to backing store)
	;		Exception enabled for blue task (i.e. in system context) -> field exception to task
	;		Code fault for blue task but exception is disabled -> UnhandledCodeFault
	;		Non-code fault for blue task -> system context (68k interrupt)

	bc		BO_IF, EWA.kFlagSIGP,				IntReturnFromSIGP
	bc		BO_IF_NOT, EWA.kFlagBlue,			UnhandledCodeFault

	cmpwi	cr1, r9, ecInstPageFault

	blt											LetBlueHandleOwnException
	beq		cr1,								UnhandledCodeFault
;	b											IntReturnToSystemContext



;	THESE TWO RETURN PATHS ARE ONLY CALLED IF BLUE IS RUNNING!

IntReturnToSystemContext

	lwz		r1, EWA.PA_KDP(r1)
	lwz		r9, KDP.PA_ECB(r1)

	addi	r8, r1, KDP.VecBaseSystem
	mtsprg	3, r8

	;	Exception came from emulator! Can't handle that with a 68k interrupt, can we?
	bcl		BO_IF, EWA.kFlagEmu, SuspendBlueTask



;	Swap the blue task between the system and alternate contexts

;	ARG		old_context r6, new_context r9

IntReturnToOtherBlueContext

	mfsprg	r1, 0

	lwz		r8, EWA.Enables(r1)
	stw		r7, ContextBlock.Flags(r6)
	stw		r8, ContextBlock.Enables(r6)

	bc		BO_IF_NOT, EWA.kFlagLowSaves, @not_low_saves
	stw		r17,  0x0024(r6)
	stw		r20,  0x0028(r6)
	stw		r21,  0x002c(r6)
	stw		r19,  0x0034(r6)
	stw		r18,  0x003c(r6)
	lmw		r14,  0x0038(r1)
@not_low_saves


	;	Save state to the old ContextBlock

	mfxer	r8
	stw		r13, ContextBlock.CR(r6)
	stw		r8, ContextBlock.XER(r6)
	stw		r12, ContextBlock.LR(r6)
	mfctr	r8
	stw		r10, ContextBlock.CodePtr(r6)
	stw		r8, ContextBlock.KernelCTR(r6)

	bc		BO_IF_NOT, EWA.kFlagHasMQ, @no_mq
	lwz		r8, ContextBlock.MQ(r9)
	mfspr	r12, mq
	mtspr	mq, r8
	stw		r12, ContextBlock.MQ(r6)
@no_mq

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
	_band.	r8, r11, MSR_FPbit
	stw		r27,  0x01dc(r6)
	stw		r28,  0x01e4(r6)
	stw		r29,  0x01ec(r6)
	stw		r30,  0x01f4(r6)
	stw		r31,  0x01fc(r6)

	bnel	bugger_around_with_floats

	bc		BO_IF_NOT, EWA.kFlagVec, @no_vec
	bl		Save_v0_v31
@no_vec

	stw		r11, ContextBlock.MSR(r6)


	;	Load state from the new ContextBlock

	lwz		r8, ContextBlock.Flags(r9)

	stw		r9, EWA.PA_ContextBlock(r1)

	xoris	r7, r7, 1 << (15 - EWA.kFlagEmu)			; toggle the emulator flag

	rlwimi	r11, r8,  0, 20, 23							; MSR[FE0/SE/BE/FE1]

	mr		r6, r9
	rlwimi	r7, r8,  0, 17, 31							; copy the flags that *do* differ between contexts

	andi.	r8, r11, MSR_FE0 | MSR_FE1

	lwz		r8, ContextBlock.Enables(r6)
	lwz		r13, ContextBlock.CR(r6)
	stw		r8, EWA.Enables(r1)
	lwz		r8, ContextBlock.XER(r6)
	lwz		r12, ContextBlock.LR(r6)
	mtxer	r8
	lwz		r8, ContextBlock.KernelCTR(r6)
	lwz		r10, ContextBlock.CodePtr(r6)
	mtctr	r8

	bnel	IntHandleSpecialFPException

	lwarx	r8, 0, r1
	sync
	stwcx.	r8, 0, r1

	lwz		r29, ContextBlock.VectorSaveArea(r6)
	lwz		r8, ContextBlock.r1(r6)
	cmpwi	r29, 0
	stw		r8, EWA.r1(r1)
	lwz		r28, 0x210(r29)
	beq		@no_vrsave
	mtspr	vrsave, r28
@no_vrsave

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

	andi.	r8, r7, (1 << (31 - EWA.kFlag26)) | (1 << (31 - EWA.kFlagLowSaves))
	mfsprg	r1, 0
	bnel	major_0x02ccc								; my counters say almost never called!
	li		r8, 0
	stw		r7, EWA.Flags(r1)
	stw		r8, EWA.WeMightClear(r1)
	b		SchReturn



;	 Almost never called (by above func)

major_0x02ccc	;	OUTSIDE REFERER

	mtcrf	0x3f, r7

	bc		BO_IF_NOT, EWA.kFlagLowSaves, @major_0x02ccc_0x18
	_bclr	r7, r7, EWA.kFlagLowSaves

	bc		BO_IF, EWA.kFlag31, major_0x02ccc_0x30
	_bclr	r7, r7, EWA.kFlag26

	b		@return
@major_0x02ccc_0x18

	bc		BO_IF_NOT, EWA.kFlag26, @return
	_bclr	r7, r7, EWA.kFlag26

	stw		r7, EWA.Flags(r1)
	li		r8, ecInstTrace
	b		Exception
@return

	blr

major_0x02ccc_0x30
	; according to my counter, this point is never reached

	rlwinm.	r8, r7,  0,  8,  8
	beq		SuspendBlueTask
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
	_bclr	r16, r7, EWA.kFlagLowSaves
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
	addi	r23, r8, KDP.VecBaseMemRetry
	add		r22, r22, r25
	mfsprg	r24, 3
	mtlr	r22
	mtsprg	3, r23
	mfmsr	r14
	ori		r15, r14,  0x10
	mtmsr	r15
	isync
	rlwimi	r25, r26,  2, 22, 29		; apparently the lower byte of the entry is an FDP (code?) offset, /4!
	bnelr
	b		MRExecuted



SuspendBlueTask
	bl		SchSaveStartingAtR14		; r8 := EWA

	lwz		r31, EWA.PA_CurTask(r8)
	lwz		r8, Task.ExceptionHandlerID(r31)
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass
	mr		r30, r8
	bnel	@no_exception_handler

	lwz		r28, Queue.ReservePtr(r30)
	cmpwi	r28, 0
	beql	@no_memory_reserved_for_exception_messages

;notify exception handler
	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r29, Task.Flags(r31)
	_bset	r29, r29, Task.kFlagStopped
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
	b		IntPanicIsland



########     ###     ######   ########    ########    ###    ##     ## ##       ########  ######  
##     ##   ## ##   ##    ##  ##          ##         ## ##   ##     ## ##          ##    ##    ## 
##     ##  ##   ##  ##        ##          ##        ##   ##  ##     ## ##          ##    ##       
########  ##     ## ##   #### ######      ######   ##     ## ##     ## ##          ##     ######  
##        ######### ##    ##  ##          ##       ######### ##     ## ##          ##          ## 
##        ##     ## ##    ##  ##          ##       ##     ## ##     ## ##          ##    ##    ## 
##        ##     ##  ######   ########    ##       ##     ##  #######  ########    ##     ######  

;	Blue can easily get to both of these!

UnhandledCodeFault

	bcl		BO_IF, EWA.kFlagLowSaves, IntPanicIsland
	bl		SchSaveStartingAtR14

	mr		r30, r10
	lwz		r29, EWA.r6(r8)
	lwz		r31, EWA.PA_CurTask(r8)
	stw		r29, ContextBlock.r6(r6)
	stw		r30, ContextBlock.SRR0(r6)						; ContextBlock.srr0?
	stw		r7, 0x0040(r6)						; ContextBlock.savedFlags?
	lwz		r1, EWA.PA_KDP(r1)

	; get task in r31, globals in r1

	;	Will be released via BlockMPCall
	_Lock			PSA.SchLock, scratch1=r28, scratch2=r29

	mr		r8, r31
	bl		SchTaskUnrdy

	lwz		r16, Task.Flags(r31)
	srwi	r8, r7, 24


	;	To debugger if not actually a code fault, or Task takes all exceptions
	rlwinm.	r16, r16, 0, Task.kFlagTakesAllExceptions, Task.kFlagTakesAllExceptions
	cmpwi	cr1, r8, ecInstPageFault
	bne		_PageFaultToDebugger
	bne		cr1, _PageFaultToDebugger


	lwz		r8, Task.CodeFaultCtr(r31)
	addi	r8, r8, 1
	stw		r8, Task.CodeFaultCtr(r31)

	b		_CommonFaultPath



UnhandledDataFault

	bcl		BO_IF_NOT, EWA.kFlagLowSaves, IntPanicIsland

	bl		PreferRegistersFromEWASavingContextBlock

	stw		r10, ContextBlock.LA_EmulatorEntry(r6)

	_bclr	r7, r7, EWA.kFlagLowSaves


	bl		SchSaveStartingAtR14

	lwz		r30, ContextBlock.SRR0(r6)
	lwz		r29,  0x0018(r8)
	lwz		r31, -0x0008(r8)
	stw		r29,  0x0134(r6)
	stw		r7,  0x0040(r6)
	lwz		r1, -0x0004(r1)


	;	Will be released via BlockMPCall
	_Lock			PSA.SchLock, scratch1=r28, scratch2=r29


	mr		r8, r31
	bl		SchTaskUnrdy


	lwz		r16, Task.Flags(r31)
	srwi	r8, r7, 24


	;	To debugger if not actually a data fault, or Task takes all exceptions
	rlwinm.	r16, r16, 0, Task.kFlagTakesAllExceptions, Task.kFlagTakesAllExceptions
	cmpwi	cr1, r8, ecDataPageFault
	bne		_PageFaultToDebugger
	bne		cr1, _PageFaultToDebugger


	lwz		r8, Task.DataFaultCtr(r31)
	addi	r8, r8, 1
	stw		r8, Task.DataFaultCtr(r31)



_CommonFaultPath

	mfsprg	r14, 0

	_bclr	r7, r7, EWA.kFlag26
	_bclr	r7, r7, EWA.kFlag31

	;	Panic if EWA.SpecialAreaPtr is invalid (presumably means CurrentlyFaultingArea?)
	lwz		r29, EWA.SpecialAreaPtr(r14)
	lisori	r17, Area.kSignature
	lwz		r16, Area.Signature(r29)
	cmplw	r16, r17
	bnel	IntPanicIsland

	lwz		r17, Area.Counter(r29)
	addi	r17, r17, 1
	stw		r17, Area.Counter(r29)

	;	Get BackingProvider ptr in r26 (`mr` a few instructions down)
	lwz		r8, Area.BackingProviderID(r29)
	bl		LookupID


	;	Three escape hatches:

	;   PAGE FAULT      TASK          VMMaxVirtualPages      CODE PATH
	;   --------------------------------------------------------------
	;   code            blue          0                      1
	;   code            blue          nonzero                  3
	;   code            non-blue      0                      1
	;   code            non-blue      nonzero                1
	;   data            blue          0                        3
	;   data            blue          nonzero                  3
	;   data            non-blue      0                       2
	;   data            non-blue      nonzero                 2

	lwz		r16, KDP.VMMaxVirtualPages(r1)
	cmpwi	cr0, r9, ecInstPageFault
	cmpwi	cr1, r16, 0
	mr		r26, r8
	bne		cr0, @ESCAPE_HATCH_2_OR_3
	beq		cr1, @force_escape_hatch_1
	bc		BO_IF, EWA.kFlagBlue, @ESCAPE_HATCH_2_OR_3
@force_escape_hatch_1



;	ESCAPE HATCH 1: CODE FAULT OUTSIDE BLUE TASK -> AREA BACKING PROVIDER

;	(also handles blue code faults IFF the never-before-seen VM regime is active)

	lwz		r16, Task.Flags(r31)

	;	Enqueue Task on its internal Semaphore (only to be released when Provider says)
	addi	r17, r31, Task.QueueMember
	addi	r18, r31, Task.PageFaultSema
	stw		r18, LLL.Freeform(r17)
	InsertAsPrev	r17, r18, scratch=r19

	li		r17, 1
	_bset	r16, r16, Task.kFlagPageFaulted
	stw		r17, Task.PageFaultSema + Semaphore.Value(r31)
	stw		r16, Task.Flags(r31)

	;   SRR0 points to faulting instruction. Extract the faulting page.
	rlwinm	r30, r30, 0, 0xFFFFF000

	;	Message = page address || Area ID || Task ID
	lwz		r27, Area.ID(r29)
	lwz		r28, Task.ID(r31)
	stw		r30, Message.Word1(r26)
	stw		r27, Message.Word2(r26)
	stw		r28, Message.Word3(r26)

	;	Bang
	mr		r30, r26
	bl		CauseNotification

	;	Success? If not, fall through to using the global blue-serviced page queue
	cmpwi	r8, 0
	beq		IntLocalBlockMPCall



@ESCAPE_HATCH_2_OR_3

	mfcr	r28							; only for hatch 3
	li		r8, Message.Size			; only for hatch 2

	bc		BO_IF, EWA.kFlagBlue, @ESCAPE_HATCH_3



;	ESCAPE HATCH 2: DATA FAULT OUTSIDE BLUE TASK -> INTO SYSTEM PAGQ FOR BLUE TO SERVICE

	;	Instead of banging a notification, we send a (new) message to the global Page Queue

	bl		PoolAlloc
	mr.		r26, r8
	beq		@oom_for_pagq_message


	;	Block the task in the usual way, but do *not* set Task.kFlagPageFaulted

	addi	r17, r31, Task.QueueMember
	addi	r18, r31, Task.PageFaultSema
	stw		r18, LLL.Freeform(r17)
	InsertAsPrev	r17, r18, scratch=r19

	li		r17, 1
	stw		r17, Task.PageFaultSema + Semaphore.Value(r31)


	;	Via the Page Queue, tell the blue task what it needs to know

	lwz		r27, Area.ID(r29)
	lisori	r8, Message.kSignature
	lwz		r29, Task.PageFaultSema(r31)
	stw		r27, Message.Word1(r26)						; arg1 = area ID
	stw		r29, Message.Word2(r26)						; arg2 = sempahore ID in its BlockedTasks linked list
	stw		r8, Message.LLL + LLL.Signature(r26)
	stw		r30, Message.Word3(r26)						; arg3 = page address

	mr		r8, r26
	addi	r31, r1, PSA.PageQueue
	bl		EnqueueMessage		; Message *r8, Queue *r31


	;	(Unconditionally) raise blue's priority to latency protection, and unblock it

	lwz		r8, PSA.BlueSpinningOn(r1)						; this guarantees that blue will always be unblocked
	bl		UnblockBlueIfCouldBePolling


	;	Block the faulting task (this releases the scheduler lock)

	b		BlockMPCall



;	ESCAPE HATCH 3: PAGE FAULT IN BLUE TASK -> 68K INTERRUPT

;	All faults that occur in the blue task, except inst faults when the ?? VM regime is enabled

@ESCAPE_HATCH_3

	;	Let the blue task keep running!
	mr		r8, r31
	bl		SchRdyTaskNow

	;	The other pathways release the Sch lock in BlockMPCall
	_AssertAndRelease	PSA.SchLock, scratch=r31

	;	Restore CR (got clobbered by SchRdyTaskNow?)

	;	Do the LowSaves help the Emulator do an interrupt?
	mtcr    r28
	bc		BO_IF_NOT, EWA.kFlagLowSaves, @nolo
	lwz		r8,  0x0064(r6)
	lwz		r9,  0x0068(r6)
	stw		r8,  0x0024(r6)
	stw		r9,  0x0028(r6)
	lwz		r8,  0x006c(r6)
	lwz		r9, ContextBlock.SRR0(r6)
	stw		r8,  0x002c(r6)
	stw		r9,  0x0034(r6)
	lwz		r8,  0x007c(r6)
	stw		r8,  0x003c(r6)
	crclr	EWA.kFlagLowSaves
@nolo

	bl		SchRestoreStartingAtR14

	;	Central to the Mac OS architecture: a 68k interrupt!
	b		IntReturnToSystemContext



;	This seems like an awfully calm way to handle a page fault.

@oom_for_pagq_message

	li		r16, Task.kNominalPriority
	stb		r16, Task.Priority(r31)
	mr		r8, r31
	bl		SchRdyTaskNow
	bl		FlagSchEval
	b		BlockMPCall



;	For tasks that were created with kMPCreateTaskTakesAllExceptionsMask

_PageFaultToDebugger

	b		ThrowTaskToDebugger



#### ##    ## ########    ##     ##    ###    ##    ## ########  ##       ######## ########   ######  
 ##  ###   ##    ##       ##     ##   ## ##   ###   ## ##     ## ##       ##       ##     ## ##    ## 
 ##  ####  ##    ##       ##     ##  ##   ##  ####  ## ##     ## ##       ##       ##     ## ##       
 ##  ## ## ##    ##       ######### ##     ## ## ## ## ##     ## ##       ######   ########   ######  
 ##  ##  ####    ##       ##     ## ######### ##  #### ##     ## ##       ##       ##   ##         ## 
 ##  ##   ###    ##       ##     ## ##     ## ##   ### ##     ## ##       ##       ##    ##  ##    ## 
#### ##    ##    ##       ##     ## ##     ## ##    ## ########  ######## ######## ##     ##  ######  

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

	bne		ThrowAlignmentException

	;	DSISR for misaligned X-form instruction:

	;	(0) 0 (14)||(15) 29:30 (16)||(17) 25 (17)||(18) 21:24 (21)||(22) rD (26)||(27) rA? (31)

	;	DSISR for misaligned D-form instruction:
	
	;	(0)        zero        (16)||(17)  5 (17)||(18)  1:4  (21)||(22) rD (26)||(27) rA? (31)

FDP_TableBase		equ		0xa00

	;	Virtual PC might put the thing in MSR_LE mode
	rlwinm.	r21, r11, 0, MSR_LEbit, MSR_LEbit			;	msr bits in srr1

	;	Get the FDP and F.O. if we were in MSR_LE mode
	lwz		r25,  KDP.PA_FDP(r1)
	bne		ThrowAlignmentException


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



IcbiNextBlock ; msr r14 //

	sync
	mtmsr	r14
	isync
	mflr	r23
	icbi	0, r23
	sync
	isync
	blr


ThrowAlignmentException

	li		r8, 0
	lis		r17, 0xFF00
	mtcr	r8
	mr		r19, r18

	rlwimi	r17, r27, 7, 31, 31			; why ~DSISR[6]... those DSISR bytes are reserved?
	xori	r17, r17, 1

	li		r8, ecAlignment
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

	bc		BO_IF_NOT, 30, MemRetryDSI_0x144

	;	"Ignore write to ROM", for example
	mfspr	r28, srr0
	addi	r28, r28, 4
	lwz		r26, KDP.NanoKernelInfo + NKNanoKernelInfo.QuietWriteCount(r1)
	mtspr	srr0, r28
	addi	r26, r26, 1
	stw		r26, KDP.NanoKernelInfo + NKNanoKernelInfo.QuietWriteCount(r1)

	b		MemRetryDSI_GracefulExit

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

MemRetryDSI_GracefulExit
	mfsprg	r1, 1
	rlwinm	r26, r25, 30, 24, 31
	rfi
	dcb.b	32, 0


MemRetryDSI_0x1c8
	andis.	r28, r31,  0x8010
	bne		MemRetryMachineCheck_0x14c

	_Lock				PSA.HTABLock, scratch1=r28, scratch2=r31
	bl		GetMeAccessToThisPage ; Page *r27 // success cr0.eq
	_AssertAndRelease	PSA.HTABLock, scratch=r28

	mfsprg	r28, 2
	mtlr	r28

	beq		MemRetryDSI_GracefulExit

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
	bl		GetMeAccessToThisPage ; Page *r27 // success cr0.eq
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
	bl		GetMeAccessToThisPage ; Page *r27 // success cr0.eq
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



###              ####### ######  #     #                                      
 #  #    # ##### #       #     # #     # #    #   ##   #    #   ##   # #      
 #  ##   #   #   #       #     # #     # ##   #  #  #  #    #  #  #  # #      
 #  # #  #   #   #####   ######  #     # # #  # #    # #    # #    # # #      
 #  #  # #   #   #       #       #     # #  # # ###### #    # ###### # #      
 #  #   ##   #   #       #       #     # #   ## #    #  #  #  #    # # #      
### #    #   #   #       #        #####  #    # #    #   ##   #    # # ###### 

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




major_0x03e18	;	OUTSIDE REFERER
	rlwinm.	r8, r11,  0, 18, 18
	bnelr

IntHandleSpecialFPException	;	OUTSIDE REFERER
	lwz		r8,  0x00e4(r6)
	rlwinm.	r8, r8,  1,  0,  0
	mfmsr	r8
	ori		r8, r8,  0x2000
	beqlr
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





bugger_around_with_floats	;	OUTSIDE REFERER
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




	align	6

major_0x04180	;	OUTSIDE REFERER
	stw		r6, -0x0290(r1)
	stw		r10, -0x028c(r1)
	stw		r11, -0x0288(r1)
	lwz		r6, -0x0014(r1)
	lwz		r10,  0x00d8(r6)
	mfspr	r11, srr1
	cmpwi	r10,  0x00
	beql	major_0x04180_0x9c
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


	bl		LoadInterruptRegisters

	li		r8, ecInvalidInstr
	b		Exception



###              ######                       #     #                                     
 #  #    # ##### #     # ###### #####  ###### ##   ##  ####  #    # # #####  ####  #####  
 #  ##   #   #   #     # #      #    # #      # # # # #    # ##   # #   #   #    # #    # 
 #  # #  #   #   ######  #####  #    # #####  #  #  # #    # # #  # #   #   #    # #    # 
 #  #  # #   #   #       #      #####  #      #     # #    # #  # # #   #   #    # #####  
 #  #   ##   #   #       #      #   #  #      #     # #    # #   ## #   #   #    # #   #  
### #    #   #   #       ###### #    # #      #     #  ####  #    # #   #    ####  #    # 

	align	kIntAlign

IntPerfMonitor	;	OUTSIDE REFERER
	mtlr	r1
	mfsprg	r1, 0
	stw		r8, -0x0280(r1)
	stw		r13, -0x0284(r1)
	mflr	r8
	mfcr	r13
	cmpwi	r8,  0xf20
	beq		major_0x04180
	mtcr	r13
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq		MaskedInterruptTaken

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, PSA.PMFHandlerID(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne		IntPerfMonitor_0x88
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
	beq		MaskedInterruptTaken
	_log	'Thermal event^n'

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, PSA.ThermalHandlerID(r1)
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	mr		r30, r8
	bne		@no_thermal_handler

	lwz		r16, EWA.CPUBase + CPU.ID(r28)
	stw		r16, Notification.MsgWord1(r30)
	bl		CauseNotification
@no_thermal_handler

	_AssertAndRelease	PSA.SchLock, scratch=r8
	bl		SchRestoreStartingAtR14
	b		IntReturn



              ######                   #                                                           #####                                          
#    #  ####  #     # #    # #    #   # #   #      ##### ###### #####  #    #   ##   ##### ###### #     #  ####  #    # ##### ###### #    # ##### 
#   #  #    # #     # #    # ##   #  #   #  #        #   #      #    # ##   #  #  #    #   #      #       #    # ##   #   #   #       #  #    #   
####   #      ######  #    # # #  # #     # #        #   #####  #    # # #  # #    #   #   #####  #       #    # # #  #   #   #####    ##     #   
#  #   #      #   #   #    # #  # # ####### #        #   #      #####  #  # # ######   #   #      #       #    # #  # #   #   #        ##     #   
#   #  #    # #    #  #    # #   ## #     # #        #   #      #   #  #   ## #    #   #   #      #     # #    # #   ##   #   #       #  #    #   
#    #  ####  #     #  ####  #    # #     # ######   #   ###### #    # #    # #    #   #   ######  #####   ####  #    #   #   ###### #    #   #   

;	We can assume that this is being called from the emulator

;	We accept a logical NCB ptr but the kernel needs a physical one.
;	So we keep a four-entry cache in KDP, mapping logical NCB ptrs
;	to physical ones. But when are there multiple alt contexts?

;	ARG		flags? r3, mask r4

	align	kIntAlign

kcRunAlternateContext

	mtcrf	0x3f, r7

	bcl		BO_IF_NOT, EWA.kFlagBlue, IntReturn

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
	mfsprg	r1, 0
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

	mfsprg	r1, 0
	stmw	r14, EWA.r14(r1)
	lwz		r1, EWA.PA_KDP(r1)

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

	mfsprg	r1, 0
	lmw		r14, EWA.r14(r1)
	lwz		r1, EWA.PA_KDP(r1)
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
	stw		r9, KDP.LA_NCB(r1)
	stw		r8, KDP.NCBCacheLA1(r1)

	lwz		r9, KDP.NCBCachePA1(r1)
	lwz		r8, KDP.NCBCachePA0(r1)
	stw		r9, KDP.NCBCachePA0(r1)
	stw		r8, KDP.NCBCachePA1(r1)

	b		@found_physical_in_cache


@fail

	mfsprg	r1, 0
	lmw		r14, EWA.r14(r1)
	lwz		r1, EWA.PA_KDP(r1)
	li		r8, ecTrapInstr
	b		Exception



;	> r8    = dest
;	> r22   = len in bytes
;	> r23   = fillword

wordfill	;	OUTSIDE REFERER
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne		wordfill
	blr



              ######                              #####                                   
#    #  ####  #     # ######  ####  ###### ##### #     # #   #  ####  ##### ###### #    # 
#   #  #    # #     # #      #      #        #   #        # #  #        #   #      ##  ## 
####   #      ######  #####   ####  #####    #    #####    #    ####    #   #####  # ## # 
#  #   #      #   #   #           # #        #         #   #        #   #   #      #    # 
#   #  #    # #    #  #      #    # #        #   #     #   #   #    #   #   #      #    # 
#    #  ####  #     # ######  ####  ######   #    #####    #    ####    #   ###### #    # 

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

	beq		@is_601
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
	bne		NonGaryReset

	;	r4 (i.e. A1) == 5 May 1956?
	xoris	r8, r4, 0x0505
	cmplwi	r8,     0x1956
	bne		NonGaryReset

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

NonGaryReset

	_log	'ResetSystem trap entered^n'

	lwz		r8, KDP.OldKDP(r1)

	cmpwi	r8, 0
	beq		ResetBuiltinKernel

	_log	'Unplugging the replacement nanokernel^n'

	lwz		r8, KDP.OldKDP(r1)
	mfsprg	r1, 0
	addi	r9, r8, KDP.VecBaseSystem
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



              ######                                                 ###                                                              
#    #  ####  #     # #####  #  ####  #####  # ##### # ###### ######  #  #    # ##### ###### #####  #####  #    # #####  #####  ####  
#   #  #    # #     # #    # # #    # #    # #   #   #     #  #       #  ##   #   #   #      #    # #    # #    # #    #   #   #      
####   #      ######  #    # # #    # #    # #   #   #    #   #####   #  # #  #   #   #####  #    # #    # #    # #    #   #    ####  
#  #   #      #       #####  # #    # #####  #   #   #   #    #       #  #  # #   #   #      #####  #####  #    # #####    #        # 
#   #  #    # #       #   #  # #    # #   #  #   #   #  #     #       #  #   ##   #   #      #   #  #   #  #    # #        #   #    # 
#    #  ####  #       #    # #  ####  #    # #   #   # ###### ###### ### #    #   #   ###### #    # #    #  ####  #        #    ####  

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

	bl		IntPanicIsland



major_0x046d0	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	li		r8, ecTrapInstr
	b		Exception



###              #######                                                    #                                                          
 #  #    # ##### #       #    # ##### ###### #####  #    #   ##   #        # #   #      ##### ###### #####  #    #   ##   ##### ###### 
 #  ##   #   #   #        #  #    #   #      #    # ##   #  #  #  #       #   #  #        #   #      #    # ##   #  #  #    #   #      
 #  # #  #   #   #####     ##     #   #####  #    # # #  # #    # #      #     # #        #   #####  #    # # #  # #    #   #   #####  
 #  #  # #   #   #         ##     #   #      #####  #  # # ###### #      ####### #        #   #      #####  #  # # ######   #   #      
 #  #   ##   #   #        #  #    #   #      #   #  #   ## #    # #      #     # #        #   #      #   #  #   ## #    #   #   #      
### #    #   #   ####### #    #   #   ###### #    # #    # #    # ###### #     # ######   #   ###### #    # #    # #    #   #   ###### 

;	For when the alternate context is running?

	align	kIntAlign

IntExternalAlternate

	bl		LoadInterruptRegisters
	mtcrf	0x3f, r7
	bcl		BO_IF_NOT, EWA.kFlagBlue, IntPanicIsland
	li		r8, ecNoException
	b		Exception



###              ######                                            
 #  #    # ##### #     # #####   ####   ####  #####    ##   #    # 
 #  ##   #   #   #     # #    # #    # #    # #    #  #  #  ##  ## 
 #  # #  #   #   ######  #    # #    # #      #    # #    # # ## # 
 #  #  # #   #   #       #####  #    # #  ### #####  ###### #    # 
 #  #   ##   #   #       #   #  #    # #    # #   #  #    # #    # 
### #    #   #   #       #    #  ####   ####  #    # #    # #    # 

	align	kIntAlign

IntProgram

	bl		LoadInterruptRegisters

	lwz		r8, KDP.LA_EmulatorKernelTrapTable(r1)
	mtcr	r11						; UNUSUAL to have SRR1 in condition register
	xor		r8, r10, r8
	bc		BO_IF_NOT, 14, @not_trap


	;	Program interrupt caused by a trap instruction


	;	From the table of twis in the emulator code image? Then return will be to LR.

	cmplwi	cr0, r8, NanoKernelCallTable.ReturnFromException
	cmplwi	cr1, r8, NanoKernelCallTable.MPDispatch
	beq		cr0, @emutrap_0_return_from_exception
	beq		cr1, @emutrap_8_mpdispatch
	cmplwi	cr0, r8, NanoKernelCallTable.VMDispatch
	cmplwi	cr1, r8, NanoKernelCallTable.Size
	beq		cr0, @emutrap_3_vmdispatch
	blt		cr1, @emutrap_other


	;	Not from the emulator image? Return will be to next instruction,
	;	and we will read the trap instruction from memory

	;	If !MSR[IR], turn on MSR[DR] for just a moment
	bc		BO_IF_NOT, 26, @_IntProgram_0x58
	stw		r14, ContextBlock.r14(r6)
	mfsprg	r14, 3
	addi	r8, r1, PSA.VecBasePIH
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
	bge		cr0, @trap_too_high
	cmplwi	cr7, r8, NanoKernelCallTable.MPDispatch / 4
	cmplwi	cr0, r8, NanoKernelCallTable.VMDispatch / 4
	slwi	r8, r8, 2
	beq		cr1, @nonemu_return_from_exception
	beq		cr7, @nonemu_mpdispatch
	beq		cr0, @nonemu_vmdispatch

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
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlagBE into EWA.kFlag26
	blr

@nonemu_mpdispatch
	lwz		r9, ContextBlock.r0(r6)
	add		r8, r8, r1
	cmpwi	r9, -1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	bne		@nonemu_go

	;	Non-emu MPDispatch trap with r0 == -1: muck around a bit?
	addi	r10, r10, 4
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlagBE into EWA.kFlag26
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
	b		Exception

@floating_point_exception
	li		r8, ecFloatException

	bc		BO_IF, 15, Exception			; if SRR0 points to subsequent instr
	addi	r10, r10, 4								; if SRR0 points to offending instr
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlagBE into EWA.kFlag26
	b		Exception



	align	kIntAlign

IntExternalSystem

	bl		LoadInterruptRegisters


	;	Sanity check

	rlwinm.	r9, r11, 0, MSR_EEbit, MSR_EEbit
	beq		MaskedInterruptTaken


	;	How many CPUs?

	lwz		r9, EWA.CPUBase + CPU.LLL + LLL.Freeform(r8)
	lwz		r9, CoherenceGroup.CpuCount(r9)
	cmpwi	r9, 2


	;	Uniprocessor machine: go straight to PIH

	blt		kcPrioritizeInterrupts


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

	beq		cr0, kcPrioritizeInterrupts
	beq		cr1, IntReturn
	bne		cr2, kcPrioritizeInterrupts
	
	mfsprg	r9, 0						;	"alert" => run scheduler evaluation
	li		r8, 1
	stb		r8, EWA.SchEvalFlag(r9)
	b		IntReturn					;	goes to SchReturn



 #####  ###  #####  ######  
#     #  #  #     # #     # 
#        #  #       #     # 
 #####   #  #  #### ######  
      #  #  #     # #       
#     #  #  #     # #       
 #####  ###  #####  #       

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
	bc		BO_IF, EWA.kFlagSIGP, IntReturnFromSIGP			; not sure about this
	cmpwi	cr2, r8, 0
	lwz		r18, EWA.SIGPSelector(r23)
	beq		cr2, @args_in_registers
	slwi	r20, r18, 2
@args_in_registers

	;	Check that a CPU plugin is installed and that the
	;	plugin dispatch table includes this command number.
	lwz		r22, EWA.CPUBase + CPU.LLL + LLL.Freeform(r23)
	li		r8, -0x7266
	lwz		r17, CoherenceGroup.PA_CpuPluginDesc(r22)
	lwz		r16, CoherenceGroup.CpuPluginSelectorCount(r22)
	mr.		r17, r17
	beqlr
	slwi	r16, r16,  2
	li		r8, -0x7267
	cmplw	r20, r16
	bgelr

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
	beq		@noNeedToSwitchSpace
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
	_bset	r7, r7, EWA.kFlagSIGP
	mr		r16, r6
	stw		r7, EWA.Flags(r23)

	;	Not sure where this ContextBlock comes from?
	addi	r6, r23, -0x318
	stw		r6, EWA.PA_ContextBlock(r23)

	beq		cr2, @args_in_registers_2

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



major_0x04a20

	mfsprg	r23, 0
	lwz		r6, -0x0014(r23)
	lwz		r7, -0x0010(r23)
	lwz		r1, -0x0004(r23)
	mfspr	r10, srr0
	mfspr	r11, srr1



IntReturnFromSIGP

	mfsprg	r23, 0
	lwz		r7, EWA.SIGPSavedR7(r23)
	andis.	r8, r11, 0x0002						; MSR bit 14??
	stw		r7, -0x0010(r23)
	bne		@msr_14_set
	li		r3, -29285
@msr_14_set

	;	Restore address space
	lwz		r8, EWA.SIGPSpacOnResume(r23)
	lwz		r9, EWA.PA_CurAddressSpace(r23)
	cmpw	r9, r8
	beq		@no_switch_space
	bl		SchSwitchSpace
@no_switch_space

	lwz		r10, EWA.SIGPSavedR10(r23)
	lwz		r11, EWA.SIGPSavedR11(r23)
	lwz		r12, EWA.SIGPSavedR12(r23)
	lwz		r13, EWA.SIGPSavedR13(r23)
	lwz		r8, EWA.SIGPSavedXER(r23)
	lwz		r9, EWA.SIGPSavedCTR(r23)
	mtxer	r8
	lwz		r8, EWA.SIGPSavedLR(r23)
	lwz		r6, EWA.SIGPSavedR6(r23)
	mtctr	r9
	stw		r6, EWA.PA_ContextBlock(r23)
	mtlr	r8
	mr		r8, r3
	mr		r9, r4
	lwz		r16, ContextBlock.r1(r6)
	lwz		r2, ContextBlock.r2(r6)
	lwz		r3, ContextBlock.r3(r6)
	lwz		r4, ContextBlock.r4(r6)
	lwz		r5, ContextBlock.r5(r6)
	lwz		r17, ContextBlock.r6(r6)
	stw		r16, EWA.r1(r23)
	stw		r17, EWA.r6(r23)

	blr



###               #####                                           
 #  #    # ##### #     # #   #  ####   ####    ##   #      #      
 #  ##   #   #   #        # #  #      #    #  #  #  #      #      
 #  # #  #   #    #####    #    ####  #      #    # #      #      
 #  #  # #   #         #   #        # #      ###### #      #      
 #  #   ##   #   #     #   #   #    # #    # #    # #      #      
### #    #   #    #####    #    ####   ####  #    # ###### ###### 

;	                       IntSyscall

;	Not fully sure about this one

IntSyscall	;	OUTSIDE REFERER

	;	Only r1 and LR have been saved, so these compares clobber cr0

	cmpwi	r0, -3
	bne		@not_minus_3

	;	sc -3:

		;	unset MSR_PR bit
		mfspr	r1, srr1
		rlwinm.	r0, r1, 26, 26, 27	; nonsense code?
		_bclr	r1, r1, 17
		blt		@dont_unset_pr		; r0 should never have bit 0 set
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
	bne		@not_minus_1

	;	sc -1: quick-test whether "this task" is blue (cr0.eq if not blue)

		lwz		r0, EWA.Flags(r1)
		mfsprg	r1, 2
		rlwinm.	r0, r0, 0, EWA.kFlagBlue, EWA.kFlagBlue
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_minus_1
	cmpwi	r0, -2
	bne		@not_any_special

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

	bl		LoadInterruptRegisters			;	Save the usual suspects and get comfy

	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 32(r1)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 8*4(r1)

	;	Not sure what to make of these
	_bset	r11, r11, 14
	rlwimi	r7, r7, 27, 26, 26

	b		kcMPDispatch



###              #######                             
 #  #    # #####    #    #####    ##    ####  ###### 
 #  ##   #   #      #    #    #  #  #  #    # #      
 #  # #  #   #      #    #    # #    # #      #####  
 #  #  # #   #      #    #####  ###### #      #      
 #  #   ##   #      #    #   #  #    # #    # #      
### #    #   #      #    #    # #    #  ####  ###### 

	align	kIntAlign

IntTrace	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	li		r8, ecInstTrace
	b		Exception



###                                     #####                                                  ###              
 #   ####  #    #  ####  #####  ###### #     #  ####  ###### ##### #    #   ##   #####  ######  #  #    # ##### 
 #  #    # ##   # #    # #    # #      #       #    # #        #   #    #  #  #  #    # #       #  ##   #   #   
 #  #      # #  # #    # #    # #####   #####  #    # #####    #   #    # #    # #    # #####   #  # #  #   #   
 #  #  ### #  # # #    # #####  #            # #    # #        #   # ## # ###### #####  #       #  #  # #   #   
 #  #    # #   ## #    # #   #  #      #     # #    # #        #   ##  ## #    # #   #  #       #  #   ##   #   
###  ####  #    #  ####  #    # ######  #####   ####  #        #   #    # #    # #    # ###### ### #    #   #   

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




#     #                                    ######                       #     #                                     ###              
#     #   ##   #    # #####  #      ###### #     # ###### #####  ###### ##   ##  ####  #    # # #####  ####  #####   #  #    # ##### 
#     #  #  #  ##   # #    # #      #      #     # #      #    # #      # # # # #    # ##   # #   #   #    # #    #  #  ##   #   #   
####### #    # # #  # #    # #      #####  ######  #####  #    # #####  #  #  # #    # # #  # #   #   #    # #    #  #  # #  #   #   
#     # ###### #  # # #    # #      #      #       #      #####  #      #     # #    # #  # # #   #   #    # #####   #  #  # #   #   
#     # #    # #   ## #    # #      #      #       #      #   #  #      #     # #    # #   ## #   #   #    # #   #   #  #   ##   #   
#     # #    # #    # #####  ###### ###### #       ###### #    # #      #     #  ####  #    # #   #    ####  #    # ### #    #   #   

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

