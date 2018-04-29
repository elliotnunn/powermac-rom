;	This file mostly provides MPCall implementations related to multitasking.
;	We won't understand this very well until someone disassembles MPLibrary.



Local_Panic		set		*
				b		panic



;	ARG		ProcessID r3
;	RET		OSStatus r3, TaskID r10

;	kMPCreateTaskSuspendedMask is ignored?

	DeclareMPCall	7, MPCall_7

MPCall_7	;	OUTSIDE REFERER
	rlwinm.	r8, r5,  0, ~0x00000006			; kMPCreateTaskValidOptionsMask minus kMPCreateTaskSuspendedMask
	bne		ReturnMPCallOOM

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Process.kIDClass
	mr		r30, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lwz		r16, Process.Flags(r30)
	rlwinm.	r17, r16, 0, 30, 30
	bne		ReleaseAndReturnMPCallOOM

	;	ARG		CPUFlags r7, Process *r8
	bl		CreateTask
	;	RET		Task *r8

	mr.		r31, r8
	beq		ReleaseAndScrambleMPCall


	mfsprg	r15, 0

	lwz		r17, Task.ID(r31)
	stw		r17, ContextBlock.r10(r6)

	lhz		r16, EWA.CPUIndex(r15)
	sth		r16, Task.CPUIndex(r31)


	addi	r16, r31, Task.ContextBlock

	lwz		r17, ContextBlock.r7(r6)
	stw		r17, ContextBlock.r12(r16)

	lwz		r17, ContextBlock.r8(r6)
	stw		r17, ContextBlock.CodePtr(r16)

	lwz		r17, ContextBlock.r9(r6)
	stw		r17, ContextBlock.r2(r16)

	stw		r4,  0x0098(r31)

	lwz		r17, ContextBlock.r6(r6)
	stw		r17, ContextBlock.LR(r31)


	lwz		r16, Task.Flags(r28)

	rlwinm.	r8, r5, 0, kMPCreateTaskTakesAllExceptionsMask
	beq		@noflag
	_bset	r16, r16, Task.kFlagTakesAllExceptions
@noflag

	rlwinm.	r8, r5, 0, kMPCreateTaskNotDebuggableMask
	beq		@noflag2
	_bset	r16, r16, Task.kFlagNotDebuggable
@noflag2

	stw		r16, Task.Flags(r28)


	b		ReleaseAndReturnZeroFromMPCall



;	ARG		Flags r7, Process *r8
;	RET		Task *r8

CreateTask

	;	Save arg and lr for later
	mr		r27, r8
	mflr	r29


;	Create the 1k TASK struct in the pool and give it an ID, leave ptr in r28

	li		r8, 0x400 ;Task.Size
	bl		PoolAllocClear
	mr.		r28, r8
	beq		@fail_oom

	;	Allocate an opaque ID for it
	li		r9, Task.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	beq		@fail_no_id

	;	ID and sign it
	stw		r8, Task.ID(r28)

	lisori	r8, Task.kSignature
	stw		r8, Task.Signature(r28)

	;	Untitled. Usually set to creator code of owning MacOS process
	lisori	r8, '----'
	stw		r8, Task.Name(r28)



;	Create a subordinate notification struct -- NOPENOPENOPE

	li		r8, 0x1c ;Notification.Size
	bl		PoolAllocClear
	cmpwi	r8, 0
	stw		r8, Task.NotificationPtr(r28)
	beq		@fail_note_oom

	lisori	r9, 'note'
	stw		r9, 4(r8)



;	Create a semaphore struct inside the task

	addi				r16, r28, Task.PageFaultSema
	_lstart				r17, Semaphore.kSignature
	stw					r16, Semaphore.BlockedTasks + LLL.Next(r16)
	_lfinish
	stw					r16, Semaphore.BlockedTasks + LLL.Prev(r16)
	stw					r17, Semaphore.BlockedTasks + LLL.Signature(r16)

	li		r16, 1
	stw		r16, Task.PageFaultSema + Semaphore.MaxValue(r28)
	li		r16, 0
	stw		r16, Task.PageFaultSema + Semaphore.Value(r28)

	addi	r8, r28, Task.PageFaultSema
	li		r9, Semaphore.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	beq		@fail_semq_no_id
	stw		r8, Task.PageFaultSema + Semaphore.BlockedTasks + LLL.Freeform(r28)



;	Allocate a vector (i.e. AltiVec) save area

	;	Conditionally, that is 
	rlwinm.	r8, r7, 0, 1 << (31 - EWA.kFlagVec)
	beq		@non_altivec_task

	;	Allocate and check
	li		r8, 0x214 ;VectorSaveArea.Size		;	room for v registers plus 20 bytes
	bl		PoolAllocClear
	andi.	r9, r8, 16-1		;	Sanity check: aligned to size of vector register?
	cmpwi	cr1, r8, 0
	bne		Local_Panic
	beq		cr1, @fail_altivec_oom

	;	Point to it (from inside and outside the ECB-like area)
	stw		r8, Task.VectorSaveArea(r28)
	stw		r8, Task.ContextBlock + ContextBlock.VectorSaveArea(r28)

	;	Fill the actual register parts with 0x7fffffff
	li		r16, 0x80 ;VectorSaveArea.RegisterAreaSize / 4
	subi	r8, r8, 4
	lwz		r17, PSA.VectorRegInitWord(r1)
@vectorarea_copyloop
	subi	r16, r16, 1
	stwu	r17, 4(r8)
	cmpwi	r16, 0
	bgt		@vectorarea_copyloop
@non_altivec_task


	;	Some unexplored DLYQ stuff

	addi	r16, r1, PSA.DelayQueue
	addi	r17, r28, 0x08
	stw		r16, 0x0000(r17)
	stw		r16, 0x0008(r17)
	lwz		r18, 0x000c(r16)
	stw		r18, 0x000c(r17)
	stw		r17, 0x0008(r18)
	stw		r17, 0x000c(r16)



	li		r16, 0
	stb		r16, Task.State(r28)

	li		r16, 9 ; (Z>>Task.kFlag28) | (Z>>Task.kFlag31)
	stw		r16, Task.Flags(r28)

	lisori	r16, 'time'
	stw		r16, 0x0024(r28)

	li		r16, 1
	stb		r16, 0x0036(r28)

	li		r16, 100
	stw		r16, Task.Weight(r28)

	li		r16, Task.kNominalPriority
	stb		r16, Task.Priority(r28)




	addi	r16, r28, Task.ContextBlock
	stw		r16, Task.ContextBlockPtr(r28)		; overridden to real ECB on blue

	lwz		r16, PSA.FlagsTemplate(r1)
	stw		r16, Task.ContextBlock + ContextBlock.Flags(r28)

	lwz		r16, PSA.UserModeMSR(r1)
	stw		r16, Task.ContextBlock + ContextBlock.MSR(r28)

	addi	r16, r1, KDP.VecBaseSystem
	stw		r16, Task.VecBase(r28)

	li		r16, 0
	lwz		r17, Task.NotificationPtr(r28)
	stw		r16, 0x0010(r17)
	stw		r16, 0x0014(r17)
	li		r16, kMPTaskAbortedErr
	stw		r16, 0x0018(r17)

	li		r16, 0
	stw		r16, Task.Zero1(r28)
	stw		r16, Task.Zero2(r28)
	stw		r16, Task.CodeFaultCtr(r28)
	stw		r16, Task.DataFaultCtr(r28)
	stw		r16, Task.PreemptCtr(r28)

	;	Who knows that these are for
	bl		GetTime

	stw		r8, Task.CreateTime1(r28)
	stw		r9, Task.CreateTime1 + 4(r28)

	stw		r8, Task.CreateTime2(r28)
	stw		r9, Task.CreateTime2 + 4(r28)

	stw		r8, Task.CreateTime3(r28)
	stw		r9, Task.CreateTime3 + 4(r28)

	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.TaskCount(r1)
	addi	r16, r16, 1
	stw		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.TaskCount(r1)

	;	Squeeze some info (including my owning process) out of the passed PROC ptr
	stw		r27, Task.OwningProcessPtr(r28)

	lwz		r16, Process.ID(r27)
	stw		r16, Task.ProcessID(r28)

	lwz		r17, Process.SystemAddressSpacePtr(r27)
	stw		r17, Task.AddressSpacePtr(r28)

	lwz		r16, AddressSpace.TaskCount(r17)
	addi	r16, r16, 1
	stw		r16, AddressSpace.TaskCount(r17)

	lwz		r16, Process.TaskCount(r27)
	addi	r16, r16, 1
	stw		r16, Process.TaskCount(r27)

	;	Restore and return
	mtlr	r29
	mr		r8, r28
	blr

@fail_altivec_oom
	lwz		r8, 0x00a0(r28)
	bl		DeleteID

@fail_semq_no_id:
	lwz		r8, 0x009c(r28)
	bl		PoolFree

@fail_note_oom
	lwz		r8, 0x0000(r28)
	bl		DeleteID

@fail_no_id
	mr		r8, r28
	bl		PoolFree

@fail_oom
	mtlr	r29
	li		r8, 0
	blr



	DeclareMPCall	8, MPCall_8

MPCall_8	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	lbz		r16,  0x0018(r31)
	cmpwi	r16,  0x00
	bne		ReleaseAndReturnMPCallOOM
	lwz		r8,  0x0060(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Process.kIDClass

	bne		Local_Panic
	lwz		r16,  0x0008(r8)
	rlwinm.	r17, r16,  0, 30, 30
	bne		ReleaseAndReturnMPCallOOM
	lwz		r30,  0x0088(r31)
	stw		r4,  0x0074(r31)
	stw		r5,  0x011c(r30)
	lwz		r18,  0x009c(r31)
	lwz		r16,  0x0134(r6)
	lwz		r17,  0x013c(r6)
	stw		r16,  0x0010(r18)
	stw		r17,  0x0014(r18)
	lwz		r16,  0x0144(r6)
	lwz		r17,  0x014c(r6)
	stw		r16,  0x010c(r30)
	stw		r16,  0x0090(r31)
	stw		r17,  0x0094(r31)
	addi	r16, r31,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	mr		r8, r31
	bl		SchRdyTaskNow
	bl		CalculateTimeslice
	bl		FlagSchEvaluationIfTaskRequires

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	9, MPCall_9

MPCall_9	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	mr		r31, r8
	cmpwi	r9,  0x02
	bne		ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  0x0064(r31)
	lbz		r17,  0x0018(r31)
	rlwinm.	r18, r16,  0, 30, 30
	cmpwi	cr1, r17,  0x00
	bne		ReleaseAndReturnMPCallOOM
	beq		cr1, MPCall_9_0xb4
	mfsprg	r15, 0
	lhz		r18,  0x001a(r31)
	lhz		r17, EWA.CPUIndex(r15)
	cmpw	r18, r17
	beq		MPCall_9_0xe0
	ori		r16, r16,  0x400
	stw		r16,  0x0064(r31)
	li		r17,  0x01
	stb		r17,  0x0019(r31)
	mr		r8, r31
	bl		FlagSchEval
	_AssertAndRelease	PSA.SchLock, scratch=r16
	subi	r10, r10, 4
	b		MPCall_6_0x78

MPCall_9_0x98	;	OUTSIDE REFERER
	lwz		r16,  0x0064(r31)
	ori		r16, r16,  0x02
	stw		r16,  0x0064(r31)
	lwz		r17,  0x009c(r31)
	li		r16, kMPTaskAbortedErr
	stw		r16,  0x0018(r17)
	b		MPCall_9_0xfc

MPCall_9_0xb4
	ori		r16, r16,  0x02
	stw		r16,  0x0064(r31)
	addi	r16, r31,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	b		MPCall_9_0xf0

MPCall_9_0xe0
	ori		r16, r16,  0x02
	stw		r16,  0x0064(r31)
	mr		r8, r31
	bl		SchTaskUnrdy

MPCall_9_0xf0
	lwz		r17,  0x009c(r31)
	li		r3,  0x00
	stw		r4,  0x0018(r17)

MPCall_9_0xfc
	addi	r16, r1, PSA.DelayQueue
	addi	r17, r31,  0x08
	stw		r16,  0x0000(r17)
	InsertAsPrev	r17, r16, scratch=r18
	lbz		r8,  0x0037(r31)
	cmpwi	r8,  0x01
	bne		MPCall_9_0x130
	addi	r8, r31,  0x20
	bl		DequeueTimer

MPCall_9_0x130
	lwz		r8,  0x0098(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	li		r18,  0x00
	lwz		r17,  0x009c(r31)
	stw		r18,  0x009c(r31)
	bne		MPCall_9_0x15c
	mr		r31, r8
	mr		r8, r17
	bl		EnqueueMessage		; Message *r8, Queue *r31
	b		ReleaseAndReturnMPCall

MPCall_9_0x15c
	mr		r8, r17
	bl		PoolFree
	b		ReleaseAndReturnMPCall



	DeclareMPCall	10, MPCall_10

MPCall_10	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lbz		r16,  0x0018(r31)
	cmpwi	r16,  0x00
	bne		ReleaseAndReturnMPCallOOM
	lwz		r16,  0x0064(r31)
	rlwinm.	r16, r16,  0, 30, 30
	beq		ReleaseAndReturnMPCallOOM
	mr		r8, r31
	bl		TasksFuncThatIsNotAMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



TasksFuncThatIsNotAMPCall
	mflr	r27
	mr		r26, r8
	addi	r16, r26,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r8,  0x0000(r26)
	bl		DeleteID
	lwz		r8,  0x00a0(r26)
	bl		DeleteID
	lwz		r8,  0x009c(r26)
	cmpwi	r8,  0x00
	beq		@_0x98
	bl		PoolFree

@_0x98
	lwz		r8,  0x008c(r26)
	cmpwi	r8,  0x00
	beq		@_0xa8
	bl		PoolFree

@_0xa8
	lwz		r17,  0x006c(r26)
	lwz		r16,  0x0010(r17)
	addi	r16, r16, -0x01
	stw		r16,  0x0010(r17)
	lwz		r17,  0x0070(r26)
	lwz		r16,  0x000c(r17)
	addi	r16, r16, -0x01
	stw		r16,  0x000c(r17)
	mr		r8, r26
	bl		PoolFree
	lwz		r16,  0x0ecc(r1)
	addi	r16, r16, -0x01
	stw		r16,  0x0ecc(r1)
	mtlr	r27
	blr


;	int MPIsTaskBlue(TaskID)
;	Returns true if the Task ID is the same as the blue Task.
;	If the Task ID sent is 0, it uses the calling Task's ID.

	DeclareMPCall	11, MPIsTaskBlue

MPIsTaskBlue	;	OUTSIDE REFERER
	mfsprg	r16, 0
	cmpwi	r3,  0x00
	lwz		r17, PSA.PA_BlueTask(r1)
	lwz		r18, EWA.PA_CurTask(r16)
	lwz		r19,  Task.ID(r17)
	bne		@ID_Provided
	lwz		r3,  Task.ID(r18);if r3 is 0, use calling Task's ID

@ID_Provided
	cmpw	r3, r19
	li		r3,  0x01
	beq		CommonMPCallReturnPath
	li		r3,  0x00
	b		CommonMPCallReturnPath


;	returns the ID and SomeLabelField of the blue Task.
;	Needs a name. MPGetBlueTaskIDAndSomeLabelField() isn't good enough
	DeclareMPCall	12, MPCall_12

MPCall_12	;	OUTSIDE REFERER
	mfsprg	r14, 0
	lwz		r15, EWA.PA_CurTask(r14)
	lwz		r3,  Task.ID(r15)
	lwz		r4,  Task.SomeLabelField(r15)
	b		CommonMPCallReturnPath


;	OSStatus MPSetTaskWeight(TaskID, weight)
;	sets the weight of a Task. Recalculates scheduler stuff if needed.
;	Name is just a guess. Change it if you find out what this is really called.
	DeclareMPCall	14, MPSetTaskWeight

MPSetTaskWeight	;	OUTSIDE REFERER
	cmpwi	r4,  0x01
	cmpwi	cr1, r4, 10000
	blt		ReturnMPCallInvalidIDErr
	bgt		cr1, ReturnMPCallInvalidIDErr

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lbz		r16,  Task.State(r31)
	cmpwi	r16,  0x01
	bne		@Set_Weight;if task isn't running, you can change its weight freely
	lwz		r16,  Task.QueueMember(r31)
	lwz		r17,  Task.Weight(r31)
	lwz		r18,  ReadyQueue.TotalWeight(r16)
	subf	r17, r17, r4	;get the change in weight
	add		r18, r17, r18;add the change to ReadyQueue.TotalWeight
	cmpwi	r17,  0x00
	stw		r18,  ReadyQueue.TotalWeight(r16)
	beq		@Set_Weight;don't mess with scheduler if weight is unchanged
	mr		r8, r31
	bl		FlagSchEval

@Set_Weight
	stw		r4,  Task.Weight(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	MPLibrary passthrough

;	When an exception occurs, the message to the queue will be:
;		(32 bits) task ID
;		(32 bits) exception type a la MachineExceptions.h
;		(32 bits) 0 (reserved)

;	ARG		TaskID r3, QueueID r4
;	RET		OSStatus r3

	DeclareMPCall	56, MPSetExceptionHandler

MPSetExceptionHandler

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Task.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8

	mr		r8, r4
 	bl		LookupID

	cmpwi	r9, 0
	cmpwi	cr1, r9, Queue.kIDClass
	beq		@isnil
	bne		cr1, ReleaseAndReturnMPCallInvalidIDErr
@isnil

	mr		r30, r8
	stw		r4, Task.ExceptionHandlerID(r31)

	b		ReleaseAndReturnZeroFromMPCall



;	MPLibrary passthrough

;	Throws an exception to a specified task.

;	ARG		TaskID r3, ExceptionKind r4
;	RET		OSStatus r3

	DeclareMPCall	57, MPThrowException

MPThrowException
	mfsprg	r15, 0

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Task.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	;	This is gold!
		lwz		r16, Task.Flags(r31)
		mtcr	r16

		li		r3, kMPTaskAbortedErr
		bc		BO_IF, Task.kFlagAborted, ReleaseAndReturnMPCall

		li		r3, kMPTaskStoppedErr
		bc		BO_IF, Task.kFlagStopped, ReleaseAndReturnMPCall

		bc		BO_IF, 14, ReleaseAndReturnMPCallOOM

	lbz		r17,  0x0018(r31)
	lhz		r18,  0x001a(r31)
	cmpwi	cr1, r17,  0x00
	bc		BO_IF_NOT, 6, KCThrowException_0x70
	ori		r16, r16,  0x600
	stw		r4,  0x00f8(r31)
	stw		r16,  0x0064(r31)

	li		r3, kMPTaskBlockedErr
	b		ReleaseAndReturnMPCall

KCThrowException_0x70
	lhz		r19, EWA.CPUIndex(r15)
	cmpw	r19, r18
	bne		KCThrowException_0xb8
	ori		r16, r16,  0x200
	stw		r4,  0x00f8(r31)
	stw		r16,  0x0064(r31)
	mr		r8, r31
	bl		SchTaskUnrdy
	addi	r16, r1, PSA.DbugQueue
	addi	r17, r31,  0x08
	stw		r16,  0x0000(r17)
	InsertAsPrev	r17, r16, scratch=r18
	li		r3, kMPTaskStoppedErr
	b		ReleaseAndReturnMPCall

KCThrowException_0xb8
	lwz		r3,  0x0000(r31)
	ori		r16, r16,  0x400
	stw		r16,  0x0064(r31)
	li		r17,  0x01
	stb		r17,  0x0019(r31)
	mr		r8, r31
	bl		FlagSchEval
	_AssertAndRelease	PSA.SchLock, scratch=r16
	subi	r10, r10, 4
	b		MPCall_6_0x78



	DeclareMPCall	58, MPCall_58

MPCall_58	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	lwz		r29, Task.Flags(r31)
	mtcr	r29
	li		r3, kMPTaskAbortedErr
	bc		BO_IF, Task.kFlagAborted, ReleaseAndReturnMPCall

	bc		BO_IF, Task.kFlagPageFaulted, MPCall_58_0x44
	bc		BO_IF_NOT, Task.kFlagStopped, ReleaseAndReturnMPCallOOM

MPCall_58_0x44
	mtcr	r4
	lwz		r30,  Task.ContextBlockPtr(r31)
	bc		BO_IF_NOT, 31, MPCall_58_0x68
	li		r8,  0x1c
	bl		PoolAlloc
	cmpwi	r8,  0x00
	beq		ReleaseAndScrambleMPCall
	li		r3,  0x00
	b		MPCall_58_0x114

MPCall_58_0x68
	li		r17,  0x3800
	rlwinm.	r8, r29,  0, 18, 18;Task.kFlagPageFaulted, but empw complains when I call it that
	andc	r29, r29, r17	;clear Task.kFlagPageFaulted, Task.kFlag19, and Task.kFlag20
	li		r17,  0x00
	bne		cr7, MPCall_58_0x80
	ori		r17, r17,  0x400

MPCall_58_0x80
	ble		cr7, MPCall_58_0x88
	ori		r17, r17,  0x200

MPCall_58_0x88
	lwz		r18,  ContextBlock.MSR(r30)
	rlwimi	r18, r17,  0, MSR_SEbit, MSR_BEbit
	stw		r18,  0x00a4(r30)
	li		r19,  0x600
	lwz		r17,  0x0008(r31)
	addi	r18, r1, PSA.DbugQueue
	andc	r29, r29, r19
	cmpw	cr1, r17, r18
	stw		r29,  0x0064(r31)
	bne		MPCall_58_0xb4
	bne		cr1, MPCall_58_0xe0

MPCall_58_0xb4
	addi	r16, r31,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	mr		r8, r31
	bl		SchRdyTaskNow
	bl		FlagSchEvaluationIfTaskRequires

MPCall_58_0xe0
;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



ThrowTaskToDebugger	;	OUTSIDE REFERER
	addi	r16, r1, PSA.DbugQueue
	addi	r17, r31, Task.QueueMember
	stw		r16, LLL.Freeform(r17)
	InsertAsPrev	r17, r16, scratch=r18
	li		r8,  0x1c
	bl		PoolAlloc
	lwz		r29, Task.Flags(r31)
	_bset	r29, r29, Task.kFlagStopped

MPCall_58_0x114
	mtcr	r29
	mr		r28, r8
	bc		BO_IF, Task.kFlagNotDebuggable, MPCall_58_0x13c
	bc		BO_IF, Task.kFlag20, MPCall_58_0x13c
	lwz		r8, PSA._8e8(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r30, r8
	_bset	r29, r29, Task.kFlag20
	beq		MPCall_58_0x184
MPCall_58_0x13c

	bc		BO_IF, 19, MPCall_58_0x158
	lwz		r8,  0x00f4(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r30, r8
	_bset	r29, r29, Task.kFlag19
	beq		MPCall_58_0x184

MPCall_58_0x158
	mr.		r8, r28
	bnel	PoolFree
	addi	r16, r31,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	b		MPCall_9_0x98

MPCall_58_0x184
	mr.		r8, r28
	stw		r29,  0x0064(r31)
	bne		MPCall_58_0x1a4
	lwz		r8,  0x0028(r30)
	cmpwi	r8,  0x00
	beq		MPCall_58_0x114
	lwz		r17,  0x0008(r8)
	stw		r17,  0x0028(r30)

MPCall_58_0x1a4
	bl		LoadSomeData
	lwz		r16,  0x0088(r31)
	lwz		r17,  0x0000(r31)
	mflr	r18
	stw		r17,  0x0010(r8)
	lwz		r17,  0x0074(r16)
	lbz		r19,  0x0040(r16)
	lbzx	r18, r18, r19
	stw		r18,  0x0014(r8)
	stw		r17,  0x0018(r8)
	stw		r18,  0x00f8(r31)
	mr		r31, r30
	bl		EnqueueMessage		; Message *r8, Queue *r31
	b		ReleaseAndReturnMPCall






LoadSomeData	;	OUTSIDE REFERER
	blrl
	dc.l	0x0002020d
	dc.l	0x01080003
	dc.l	0x090a0403
	dc.l	0x07000500
	dc.l	0x0b0b0403
	dc.l	0x07060505
	dc.l	0x11000000



;	Used to extract task state. This will be tricky.

	DeclareMPCall	59, MPCall_59

MPCall_59	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	beq		MPCall_59_0x30

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

MPCall_59_0x30
	stw		r3, PSA._8e8(r1)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	60, MPCall_60

MPCall_60	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	cmpwi	r4,  0x05
	beq		MPCall_60_0x288

	lwz		r16, Task.Flags(r31)
	mtcr	r16

	li		r3, kMPTaskAbortedErr
	bc		BO_IF, Task.kFlagAborted, ReleaseAndReturnMPCall

	bc		BO_IF, Task.kFlagPageFaulted, MPCall_60_0x4c
	bc		BO_IF_NOT, Task.kFlagStopped, ReleaseAndReturnMPCallOOM

MPCall_60_0x4c
	lbz		r16,  Task.State(r31)
	cmpwi	r16,  0x00
	bne		ReleaseAndReturnMPCallOOM
	cmpwi	r4,  0x00
	cmpwi	cr1, r4,  0x01
	beq		MPCall_60_0xf8
	beq		cr1, MPCall_60_0x10c
	cmpwi	r4,  0x02
	cmpwi	cr1, r4,  0x03
	beq		MPCall_60_0x150
	beq		cr1, MPCall_60_0x1c0
	cmpwi	r4,  0x04
	bne		ReleaseAndReturnMPCallOOM
	lwz		r16,  Task.ContextBlockPtr(r31)
	li		r17,  0x00
	cmplwi	r5,  0x00
	cmplwi	cr1, r5,  0x04
	beq		MPCall_60_0xac;gets ID of Area SRR0 is in
	beq		cr1, MPCall_60_0xc0
	cmplwi	r5,  0x08
	cmplwi	cr1, r5,  0x0c
	beq		MPCall_60_0xc8
	beq		cr1, MPCall_60_0xd0
	b		ReleaseAndReturnMPCallOOM

MPCall_60_0xac
	lwz		r8,  Task.AddressSpacePtr(r31)
	lwz		r9,  ContextBlock.SRR0(r16)
	bl		FindAreaAbove
	lwz		r17,  Area.ID(r8)
	b		MPCall_60_0x36c

MPCall_60_0xc0
	lwz		r17,  ContextBlock.SRR0(r16)
	b		MPCall_60_0x36c

MPCall_60_0xc8
	lwz		r17,  Task.ErrToReturnIfIDie(r31)
	b		MPCall_60_0x36c

MPCall_60_0xd0
	lwz		r17,  ContextBlock.SavedFlags(r16)
	lwz		r18,  0x0064(r16);some unknown ContextBlock value
	rlwinm.	r8, r17,  0, EWA.kFlagLowSaves, EWA.kFlagLowSaves
	li		r17,  0x02
	beq		MPCall_60_0x36c
	rlwinm.	r8, r18,  0,  EWA.kFlag1, EWA.kFlag1
	li		r17,  0x01
	bne		MPCall_60_0x36c
	li		r17,  0x00
	b		MPCall_60_0x36c

MPCall_60_0xf8
	lwz		r16,  Task.ContextBlockPtr(r31)
	cmplwi	cr1, r5,  0xf8
	andi.	r17, r5,  0x07
	addi	r16, r16,  0xfc
	b		MPCall_60_0x124

MPCall_60_0x10c
	lwz		r16,  Task.ContextBlockPtr(r31)
	cmplwi	r5,  0x100
	cmplwi	cr1, r5,  0xf8
	beq		MPCall_60_0x144
	andi.	r17, r5,  0x07
	addi	r16, r16,  0x1fc

MPCall_60_0x124
	add		r16, r16, r5
	bgt		cr1, ReleaseAndReturnMPCallOOM
	bne		ReleaseAndReturnMPCallOOM
	lwzu	r17,  0x0004(r16)
	lwzu	r18,  0x0004(r16)
	lwzu	r19,  0x0004(r16)
	lwzu	r20,  0x0004(r16)
	b		MPCall_60_0x3a8

MPCall_60_0x144
	lwz		r17,  0x00e4(r16)
	li		r18,  0x00
	b		MPCall_60_0x37c

MPCall_60_0x150
	lwz		r16,  0x0088(r31)
	rlwinm.	r8, r7, 0, EWA.kFlagVec, EWA.kFlagVec
	lwz		r16,  0x00d8(r16)
	beq		ReleaseAndReturnMPCallOOM
	cmplwi	cr3, r16,  0x00
	cmplwi	r5,  0x200
	cmplwi	cr2, r5,  0x210
	cmplwi	cr1, r5,  0x1f0
	beql	cr3, Local_Panic
	beq		MPCall_60_0x1a4
	beq		cr2, MPCall_60_0x1b8
	andi.	r8, r5,  0x0f
	add		r16, r16, r5
	subi	r16, r16, 4
	bgt		cr1, ReleaseAndReturnMPCallOOM
	bne		ReleaseAndReturnMPCallOOM
	lwzu	r17,  0x0004(r16)
	lwzu	r18,  0x0004(r16)
	lwzu	r19,  0x0004(r16)
	lwzu	r20,  0x0004(r16)
	b		MPCall_60_0x3a8

MPCall_60_0x1a4
	lwz		r17,  0x0200(r16)
	lwz		r18,  0x0204(r16)
	lwz		r19,  0x0208(r16)
	lwz		r20,  0x020c(r16)
	b		MPCall_60_0x3a8

MPCall_60_0x1b8
	lwz		r17,  0x0210(r16)
	b		MPCall_60_0x36c

MPCall_60_0x1c0
	lwz		r16,  0x0088(r31)
	li		r17,  0x00
	cmplwi	r5,  0x00
	cmplwi	cr1, r5,  0x08
	beq		MPCall_60_0x21c
	beq		cr1, MPCall_60_0x228
	cmplwi	r5,  0x10
	cmplwi	cr1, r5,  0x30
	beq		MPCall_60_0x234
	beq		cr1, MPCall_60_0x240
	cmplwi	r5,  0x1c
	cmplwi	cr1, r5,  0x20
	beq		MPCall_60_0x24c
	beq		cr1, MPCall_60_0x254
	cmplwi	r5,  0x24
	cmplwi	cr1, r5,  0x28
	beq		MPCall_60_0x25c
	beq		cr1, MPCall_60_0x264
	cmplwi	r5,  0x2c
	cmplwi	cr1, r5,  0x18
	beq		MPCall_60_0x278
	beq		cr1, MPCall_60_0x280
	b		ReleaseAndReturnMPCallOOM

MPCall_60_0x21c
	lwz		r17,  0x00f0(r16)
	lwz		r18,  0x00f4(r16)
	b		MPCall_60_0x37c

MPCall_60_0x228
	lwz		r17,  0x00e8(r16)
	lwz		r18,  0x00ec(r16)
	b		MPCall_60_0x37c

MPCall_60_0x234
	lwz		r17,  0x00f8(r16)
	lwz		r18,  0x00fc(r16)
	b		MPCall_60_0x37c

MPCall_60_0x240
	lwz		r17,  0x0070(r16)
	lwz		r18,  0x0074(r16)
	b		MPCall_60_0x37c

MPCall_60_0x24c
	lwz		r17,  0x00d4(r16)
	b		MPCall_60_0x36c

MPCall_60_0x254
	lwz		r17,  0x00a4(r16)
	b		MPCall_60_0x36c

MPCall_60_0x25c
	lwz		r17,  0x00c4(r16)
	b		MPCall_60_0x36c

MPCall_60_0x264
	lbz		r17,  0x0040(r16)
	bl		LoadSomeData
	mflr	r18
	lbzx	r17, r18, r17
	b		MPCall_60_0x36c

MPCall_60_0x278
	li		r17,  0x00
	b		MPCall_60_0x36c

MPCall_60_0x280
	lwz		r17,  0x00dc(r16)
	b		MPCall_60_0x36c

MPCall_60_0x288
	cmplwi	cr1, r5,  0x04
	cmplwi	r5,  0x14
	beq		cr1, MPCall_60_0x2c4
	beq		MPCall_60_0x2e4
	cmplwi	cr1, r5,  0x20
	cmplwi	r5,  0x30
	beq		cr1, MPCall_60_0x2f4
	beq		MPCall_60_0x308
	cmpwi	cr1, r5,  0x40
	cmplwi	r5,  0x3c
	beq		cr1, MPCall_60_0x320
	beq		MPCall_60_0x318
	cmpwi	cr1, r5,  0x50
	beq		cr1, MPCall_60_0x34c
	b		ReleaseAndReturnMPCallOOM

MPCall_60_0x2c4
	lwz		r17,  0x0074(r31)
	lwz		r18,  0x0008(r31)
	lwz		r18,  0x0004(r18)
	lhz		r19,  0x001a(r31)
	lbz		r20,  0x0018(r31)
	rlwimi	r19, r20, 16,  8, 15
	lwz		r20,  0x001c(r31)
	b		MPCall_60_0x3a8

MPCall_60_0x2e4
	lwz		r17,  0x0060(r31)
	lwz		r18,  0x00c0(r31)
	lwz		r19,  0x00c4(r31)
	b		MPCall_60_0x390

MPCall_60_0x2f4
	lwz		r17,  0x00c8(r31)
	lwz		r18,  0x00cc(r31)
	lwz		r19,  0x00d0(r31)
	lwz		r20,  0x00d4(r31)
	b		MPCall_60_0x3a8

MPCall_60_0x308
	lwz		r17,  0x00e0(r31)
	lwz		r18,  0x00e4(r31)
	lwz		r19,  0x00e8(r31)
	b		MPCall_60_0x390

MPCall_60_0x318
	lwz		r17,  0x0078(r31)
	b		MPCall_60_0x36c

MPCall_60_0x320
	lbz		r20,  0x0018(r31)
	li		r17,  0x00
	lwz		r16,  0x0008(r31)
	lwz		r18,  0x0070(r31)
	cmpwi	r20,  0x00
	lwz		r19,  0x0094(r31)
	lwz		r20,  0x0090(r31)
	lwz		r18,  0x0000(r18)
	bne		MPCall_60_0x3a8
	lwz		r17,  0x0000(r16)
	b		MPCall_60_0x3a8

MPCall_60_0x34c
	mfsprg	r18, 0
	lwz		r20,  0x0088(r31)
	lwz		r19, -0x0008(r18)
	cmpw	r19, r31
	lwz		r17,  0x0004(r18)
	beq		MPCall_60_0x36c
	lwz		r17,  0x010c(r20)
	b		MPCall_60_0x36c

MPCall_60_0x36c
	li		r21,  0x04
	stw		r17,  0x0134(r6)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_60_0x37c
	li		r21,  0x08
	stw		r17,  0x0134(r6)
	stw		r18,  0x013c(r6)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_60_0x390
	li		r21,  0x0c
	stw		r17,  0x0134(r6)
	stw		r18,  0x013c(r6)
	stw		r19,  0x0144(r6)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_60_0x3a8
	li		r21,  0x10
	stw		r17,  0x0134(r6)
	stw		r18,  0x013c(r6)
	stw		r19,  0x0144(r6)
	stw		r20,  0x014c(r6)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	61, MPCall_61

MPCall_61	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	lwz		r16, Task.Flags(r31)
	mtcr	r16

	li		r3, kMPTaskAbortedErr
	bc		BO_IF, 30, ReleaseAndReturnMPCall

	bc		BO_IF, 18, MPCall_61_0x44
	bc		BO_IF_NOT, 22, ReleaseAndReturnMPCallOOM

MPCall_61_0x44
	lbz		r16,  0x0018(r31)
	cmpwi	r16,  0x00
	bne		ReleaseAndReturnMPCallOOM
	lwz		r17,  0x0134(r6)
	lwz		r18,  0x013c(r6)
	lwz		r19,  0x0144(r6)
	lwz		r20,  0x014c(r6)
	cmpwi	r4,  0x00
	cmpwi	cr1, r4,  0x01
	beq		MPCall_61_0x84
	beq		cr1, MPCall_61_0x98
	cmpwi	r4,  0x02
	cmpwi	cr1, r4,  0x03
	beq		MPCall_61_0xe8
	beq		cr1, MPCall_61_0x170
	b		ReleaseAndReturnMPCallOOM

MPCall_61_0x84
	lwz		r16,  0x0088(r31)
	cmplwi	cr1, r5,  0xf8
	andi.	r8, r5,  0x07
	addi	r16, r16,  0xfc
	b		MPCall_61_0xb0

MPCall_61_0x98
	lwz		r16,  0x0088(r31)
	cmplwi	r5,  0x100
	cmplwi	cr1, r5,  0xf8
	beq		MPCall_61_0xd8
	andi.	r8, r5,  0x07
	addi	r16, r16,  0x1fc

MPCall_61_0xb0
	add		r16, r16, r5
	bgt		cr1, ReleaseAndReturnMPCallOOM
	bne		ReleaseAndReturnMPCallOOM
	li		r21,  0x10
	stwu	r17,  0x0004(r16)
	stwu	r18,  0x0004(r16)
	stwu	r19,  0x0004(r16)
	stwu	r20,  0x0004(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0xd8
	li		r21,  0x04
	stw		r17,  0x00e4(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0xe8
	lwz		r16,  0x0088(r31)
	rlwinm.	r8, r7, 0, EWA.kFlagVec, EWA.kFlagVec
	lwz		r16,  0x00d8(r16)
	beq		ReleaseAndReturnMPCallOOM
	cmplwi	cr3, r16,  0x00
	cmplwi	r5,  0x200
	cmplwi	cr2, r5,  0x210
	cmplwi	cr1, r5,  0x1f0
	beql	cr3, Local_Panic
	beq		MPCall_61_0x144
	beq		cr2, MPCall_61_0x160
	andi.	r8, r5,  0x0f
	add		r16, r16, r5
	subi	r16, r16, 4
	bgt		cr1, ReleaseAndReturnMPCallOOM
	bne		ReleaseAndReturnMPCallOOM
	li		r21,  0x10
	stwu	r17,  0x0004(r16)
	stwu	r18,  0x0004(r16)
	stwu	r19,  0x0004(r16)
	stwu	r20,  0x0004(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x144
	li		r21,  0x10
	stw		r17,  0x0200(r16)
	stw		r18,  0x0204(r16)
	stw		r19,  0x0208(r16)
	stw		r20,  0x020c(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x160
	li		r21,  0x04
	stw		r17,  0x0210(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x170
	lwz		r16,  0x0088(r31)
	cmplwi	r5,  0x00
	cmplwi	cr1, r5,  0x08
	beq		MPCall_61_0x1b0
	beq		cr1, MPCall_61_0x1c4
	cmplwi	r5,  0x10
	beq		MPCall_61_0x1d8
	cmplwi	r5,  0x1c
	cmplwi	cr1, r5,  0x20
	beq		MPCall_61_0x1ec
	beq		cr1, MPCall_61_0x1fc
	cmplwi	r5,  0x24
	cmplwi	cr1, r5,  0x18
	beq		MPCall_61_0x218
	beq		cr1, MPCall_61_0x228
	b		ReleaseAndReturnMPCallOOM

MPCall_61_0x1b0
	li		r21,  0x08
	stw		r17,  0x00f0(r16)
	stw		r18,  0x00f4(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x1c4
	li		r21,  0x08
	stw		r17,  0x00e8(r16)
	stw		r18,  0x00ec(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x1d8
	li		r21,  0x08
	stw		r17,  0x00f8(r16)
	stw		r18,  0x00fc(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x1ec
	li		r21,  0x04
	stw		r17,  0x00d4(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x1fc
	li		r21,  0x04
	lwz		r18,  0x00a4(r16)
	rlwimi	r18, r17,  0, 20, 23 ; MSR[FE0/SE/BE/FE1]
	rlwimi	r18, r17,  0, 31, 31
	stw		r18,  0x00a4(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x218
	li		r21,  0x04
	stw		r17,  0x00c4(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_61_0x228
	li		r21,  0x04
	stw		r17,  0x00dc(r16)
	stw		r21,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	63, MPCall_63

MPCall_63	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	stw		r4,  Task.SomeLabelField(r8)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall


;	OSStatus MPSetTaskCPU(TaskID, CPUID)
;	Makes it so that a Task can only run on a single CPU.
	DeclareMPCall	114, MPSetTaskCPU

MPSetTaskCPU	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r4

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CPU.kIDClass

	mr		r30, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  Task.Flags(r31)
	lwz		r17,  Task.PreemptCtr(r31)
	rlwinm.	r8, r16,  0, Task.kFlagAborted, Task.kFlagAborted
	cmplw	cr1, r17, r5
	lwz		r18,  CPU.Flags(r30)
	bne		ReleaseAndReturnMPCallOOM
	bne		cr1, ReleaseAndReturnMPCallOOM
	rlwinm.	r8, r18,  0, CPU.kFlagScheduled, CPU.kFlagScheduled
	cmplwi	cr1, r17,  0x04
	beq		ReleaseAndReturnMPCallOOM
	lwz		r16,  Task.Flags(r31)
	lhz		r17, CPU.EWA + EWA.CPUIndex(r30)
	ori		r16, r16,  0x40;Task.kFlag25
	stw		r16,  Task.Flags(r31)
	sth		r17,  Task.CPUIndex(r31)
	rlwinm.	r8, r16,  0, Task.kFlag26, Task.kFlag26
	mr		r8, r31
	bne		@No_Requeueing
	bl		SchTaskUnrdy
	bl		SchRdyTaskNow

@No_Requeueing
	bl		FlagSchEvaluationIfTaskRequires

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	ARG		TaskID r3, OSType r4
;	RET		OSStatus r3

	DeclareMPCall	126, KCSetTaskType

KCSetTaskType

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Task.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	stw		r4, Task.Name(r8)

	b		ReleaseAndReturnZeroFromMPCall
