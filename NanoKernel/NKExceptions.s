;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKConsoleLog
;	    printw
;	  NKFloatInts
;	    IntHandleSpecialFPException
;	    bugger_around_with_floats
;	  NKIndex
;	    LookupID
;	  NKIntMisc
;	    IntReturnFromSIGP
;	  NKMPCalls
;	    BlockMPCall
;	  NKPoolAllocator
;	    PoolAlloc
;	  NKScheduler
;	    FlagSchEval
;	    Save_v0_v31
;	    SchEval
;	    SchRdyTaskNow
;	    SchRestoreStartingAtR14
;	    SchReturn
;	    SchSaveStartingAtR14
;	    SchTaskUnrdy
;	  NKSync
;	    CauseNotification
;	    EnqueueMessage
;	    UnblockBlueIfCouldBePolling
;	  NKTasks
;	    ThrowTaskToDebugger
;	  NKTranslation
;	    FDP_011c
;	EXPORTS:
;	  Exception (=> NKIntHandlers, NKIntMisc, NKThud, NKTranslation)
;	  ExceptionMemRetried (=> NKIntHandlers, NKTranslation)
;	  IntReturn (=> NKCache, NKIntHandlers, NKIntMisc, NKMPCalls, NKPowerCalls, NKPrimaryIntHandlers, NKRTASCalls, NKVMCalls)
;	  IntReturnToOtherBlueContext (=> NKIntMisc)
;	  IntReturnToSystemContext (=> NKIntHandlers)



BlockTaskToHandleException

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

	andi.	r8, r7, (1 << (31 - 26)) | (1 << (31 - 27))
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
	b		FDP_011c



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
	beq		BlockTaskToHandleException



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
