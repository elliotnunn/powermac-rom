;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKIndex
;	    DeleteID
;	    LookupID
;	    MakeID
;	  NKMPCalls
;	    BlockMPCall
;	    ReleaseAndReturnMPCall
;	    ReleaseAndReturnMPCallBlueBlocking
;	    ReleaseAndReturnMPCallInvalidIDErr
;	    ReleaseAndReturnMPCallOOM
;	    ReleaseAndReturnMPCallTaskAborted
;	    ReleaseAndReturnParamErrFromMPCall
;	    ReleaseAndReturnZeroFromMPCall
;	    ReleaseAndScrambleMPCall
;	    ReleaseAndTimeoutMPCall
;	    ReturnMPCallOOM
;	    ReturnZeroFromMPCall
;	    ScrambleMPCall
;	  NKPoolAllocator
;	    PoolAlloc
;	    PoolAllocClear
;	    PoolFree
;	  NKScheduler
;	    CalculateTimeslice
;	    FlagSchEvaluationIfTaskRequires
;	    SchRdyTaskLater
;	    SchRdyTaskNow
;	    SchTaskUnrdy
;	  NKThud
;	    panic
;	  NKTimers
;	    DequeueTimer
;	    EnqueueTimer
;	    GetTime
;	    TimebaseTicksPerPeriod
;	EXPORTS:
;	  CauseNotification (=> NKAddressSpaces, NKExceptions, NKIntMisc, NKPrimaryIntHandlers)
;	  EnqueueMessage (=> NKExceptions, NKTasks, NKTimers)
;	  SetEvent (=> NKAddressSpaces, NKTimers)
;	  SignalSemaphore (=> NKTimers)
;	  UnblockBlueIfCouldBePolling (=> NKExceptions)


 #######  ##     ## ######## ##     ## ########  ######  
##     ## ##     ## ##       ##     ## ##       ##    ## 
##     ## ##     ## ##       ##     ## ##       ##       
##     ## ##     ## ######   ##     ## ######    ######  
##  ## ## ##     ## ##       ##     ## ##             ## 
##    ##  ##     ## ##       ##     ## ##       ##    ## 
 ##### ##  #######  ########  #######  ########  ######  



   ##   ########     #######      ######  ########  ########    ###    ######## ######## 
 ####   ##          ##     ##    ##    ## ##     ## ##         ## ##      ##    ##       
   ##   ##          ##     ##    ##       ##     ## ##        ##   ##     ##    ##       
   ##   #######     ##     ##    ##       ########  ######   ##     ##    ##    ######   
   ##         ##    ##  ## ##    ##       ##   ##   ##       #########    ##    ##       
   ##   ##    ##    ##    ##     ##    ## ##    ##  ##       ##     ##    ##    ##       
 ######  ######      ##### ##     ######  ##     ## ######## ##     ##    ##    ######## 

;	RET		OSStatus r3, QueueID r4

	DeclareMPCall	15, MPCreateQueue

MPCreateQueue

	li		r8, Queue.Size
	bl		PoolAlloc
	mr.		r31, r8
	beq		ScrambleMPCall

	;	List of messages waiting for tasks
	InitList	r8, 'MSGQ', scratch=r16

	;	List of blocked tasks waiting to be notified of messages
	addi	r9, r8, Queue.Messages
	InitList	r9, 'NOTQ', scratch=r16

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9, Queue.kIDClass
	bl		MakeID

	cmpwi	r8, 0
	bne+	@nofail
	mr		r8, r31
	bl		PoolFree
	b		ReleaseAndScrambleMPCall
@nofail

	mfsprg	r30, 0
	lwz		r30, EWA.PA_CurTask(r30)

	stw		r8, Queue.BlockedTasks + LLL.Freeform(r31)

	lwz		r17, Task.ProcessID(r30)
	stw		r17, Queue.ProcessID(r31)

	mr		r4, r8

	li		r17, 0
	stw		r17, Queue.ReserveCount(r31)
	stw		r17, Queue.ReservePtr(r31)
	stw		r17, Queue.BlockedTaskCount(r31)
	stw		r17, Queue.MessageCount(r31)

	b		ReleaseAndReturnZeroFromMPCall



   ##    #######      #######     ########  ######## ##       ######## ######## ######## 
 ####   ##     ##    ##     ##    ##     ## ##       ##       ##          ##    ##       
   ##   ##           ##     ##    ##     ## ##       ##       ##          ##    ##       
   ##   ########     ##     ##    ##     ## ######   ##       ######      ##    ######   
   ##   ##     ##    ##  ## ##    ##     ## ##       ##       ##          ##    ##       
   ##   ##     ##    ##    ##     ##     ## ##       ##       ##          ##    ##       
 ######  #######      ##### ##    ########  ######## ######## ########    ##    ######## 

;	Delete a message queue:
;	1. Delete its messages.
;	2. Call UnblockBlueIfCouldBePolling on the queue?
;	3. Unblock waiting tasks with kMPDeletedErr, calling FlagSchEvaluationIfTaskRequires on each.
;	4. Delete the queue structure and its ID.

;	ARG		QueueID r3
;	RET		OSStatus r3

	DeclareMPCall	16, MPDeleteQueue

MPDeleteQueue

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr


	;	Delete all auto-allocated messages
@note_free_loop
	addi	r30, r31, Queue.Messages
	lwz		r8, Queue.Messages + LLL.Next(r31)
	cmpw	r8, r30
	beq		@exit_note_free_loop
	RemoveFromList		r8, scratch1=r16, scratch2=r17
	bl		PoolFree
	b		@note_free_loop
@exit_note_free_loop


	;	Delete all pre-allocated messages
	lwz		r30, Queue.ReservePtr(r31)
@notr_free_loop
	mr.		r8, r30
	beq		@exit_notr_free_loop
	lwz		r30, Message.LLL + LLL.Next(r30)
	bl		PoolFree
	b		@notr_free_loop
@exit_notr_free_loop


	mr		r8, r3
	bl		UnblockBlueIfCouldBePolling


	;	UNBLOCK the tasks that are blocked waiting on this queue.
	;	From the task's perspective, MPWaitOnQueue will return
	;	kMPDeletedErr, because we tweak the task's ContextBlock.
@task_unblock_loop

	;	Peek at our MSGQ queue of blocked tasks
	addi	r30, r31, Queue.BlockedTasks
	lwz		r16, Queue.BlockedTasks + LLL.Next(r31)
	cmpw	r16, r30
	subi	r8, r16, Task.QueueMember
	beq		@exit_task_loop

	;	Manipulate its r3 from afar
	lwz		r17, Task.ContextBlockPtr(r8)
	li		r18, kMPDeletedErr
	stw		r18, ContextBlock.r3(r17)

	;	If blocked with timeout, dequeue task's internal timer
	lbz		r17, Task.Timer + Timer.Byte3(r8)
	cmpwi	r17, 1
	bne		@no_timeout
	addi	r8, r8, Task.Timer
	bl		DequeueTimer
@no_timeout

	;	Remove from this MSGQ
	lwz		r16, Queue.BlockedTasks + LLL.Next(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18

	;	Put RDYQ
	subi	r8, r16, Task.QueueMember
	bl		SchRdyTaskNow

	bl		FlagSchEvaluationIfTaskRequires

	b		@task_unblock_loop
@exit_task_loop


	;	Delete the actual Queue structure and its ID
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID


	b		ReleaseAndReturnZeroFromMPCall



 #######   #######      #######     ########  ########  ######  ######## ########  ##     ## ######## 
##     ## ##     ##    ##     ##    ##     ## ##       ##    ## ##       ##     ## ##     ## ##       
       ## ##     ##    ##     ##    ##     ## ##       ##       ##       ##     ## ##     ## ##       
 #######   ########    ##     ##    ########  ######    ######  ######   ########  ##     ## ######   
       ##        ##    ##  ## ##    ##   ##   ##             ## ##       ##   ##    ##   ##  ##       
##     ## ##     ##    ##    ##     ##    ##  ##       ##    ## ##       ##    ##    ## ##   ##       
 #######   #######      ##### ##    ##     ## ########  ######  ######## ##     ##    ###    ######## 

;	Reserve space for messages for this queue.
;	(guarantees message delivery)

;	Reserved messages have signature 'notr' (vs. 'note').

;	ARG		QueueID r3, ItemCount r4
;	RET		OSStatus r3

	DeclareMPCall	39, MPSetQueueReserve

MPSetQueueReserve

	cmpwi	r4, 0
	blt		ReturnMPCallOOM

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lwz		r29, Queue.ReserveCount(r31)
	lwz		r30, Queue.ReservePtr(r31)

	cmpw	r29, r4
	beq		ReleaseAndReturnZeroFromMPCall
	blt		@make_more


	;	NEW < OLD
@free_loop
	mr.		r8, r30
	beq		@free_loop_failed
	subi	r29, r29, 1
	lwz		r30, LLL.Next(r30)
	bl		PoolFree
	cmpw	r29, r4
	bgt		@free_loop

;free loop succeeded
	stw		r4, Queue.ReserveCount(r31)
	stw		r30, Queue.ReservePtr(r31)
	b		ReleaseAndReturnZeroFromMPCall

@free_loop_failed
	stw		r29, Queue.ReserveCount(r31)
	stw		r30, Queue.ReservePtr(r31)
	b		ReleaseAndReturnMPCallOOM


	;	NEW > OLD
@make_more
@alloc_loop
	li		r8, Message.Size
	bl		PoolAlloc
	cmpwi	r8, 0
	beq		ReleaseAndScrambleMPCall

	addi	r29, r29, 1

	lisori	r17, Message.kReservedSignature
	stw		r17, Message.LLL + LLL.Signature(r8)

	stw		r30, Message.LLL + LLL.Next(r8)

	stw		r29, Queue.ReserveCount(r31)

	cmpw	r29, r4
	stw		r8, Queue.ReservePtr(r31)
	mr		r30, r8
	blt		@alloc_loop


	b		ReleaseAndReturnZeroFromMPCall



   ##   ########     #######     ##    ##  #######  ######## #### ######## ##    ## 
 ####   ##    ##    ##     ##    ###   ## ##     ##    ##     ##  ##        ##  ##  
   ##       ##      ##     ##    ####  ## ##     ##    ##     ##  ##         ####   
   ##      ##       ##     ##    ## ## ## ##     ##    ##     ##  ######      ##    
   ##     ##        ##  ## ##    ##  #### ##     ##    ##     ##  ##          ##    
   ##     ##        ##    ##     ##   ### ##     ##    ##     ##  ##          ##    
 ######   ##         ##### ##    ##    ##  #######     ##    #### ##          ##    

;	Sends a 12-byte message to the specified queue

;	ARG		QueueID r3, long r4, long r5, long r6

	DeclareMPCall	17, MPNotifyQueue

MPNotifyQueue

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lwz		r16, Queue.ReserveCount(r31)
	li		r8, Message.Size
	cmpwi	r16, 0
	bne		@try_reserve

;no reservation available
	bl		PoolAlloc

	cmpwi	r8, 0
	beq		ReleaseAndScrambleMPCall

	lisori	r17, Message.kSignature
	stw		r17, Message.LLL + LLL.Signature(r8)

	b		@common

@try_reserve
	lwz		r17, Queue.ReservePtr(r31)
	mr.		r8, r17
	beq		ReleaseAndReturnMPCallOOM

	lwz		r17, Message.LLL + LLL.Next(r17)
	stw		r17, Queue.ReservePtr(r31)

@common
	;	Got a message ptr in r8!

	;	Fill it with lies
	lwz		r16, ContextBlock.r6(r6)
	stw		r4, Message.Word1(r8)
	stw		r5, Message.Word2(r8)
	stw		r16, Message.Word3(r8)

	bl		EnqueueMessage		; Message *r8, Queue *r31


	b		ReleaseAndReturnZeroFromMPCall



  ###  #######     ##     ##  ######   ######   ###   
 ##   ##     ##    ###   ### ##    ## ##    ##    ##  
##    ##     ##    #### #### ##       ##           ## 
##    ##     ##    ## ### ##  ######  ##   ####    ## 
##    ##  ## ##    ##     ##       ## ##    ##     ## 
 ##   ##    ##     ##     ## ##    ## ##    ##    ##  
  ###  ##### ##    ##     ##  ######   ######   ###   

;	Enqueue a note/notr object.

;	Odd way of unblocking task (does not touch r3 directly):
;	1. Add message to queue.
;	2. If task waiting, unblock with rewound PC to retry syscall.

;	ARG		Message *r8, Queue *r31

EnqueueMessage

	addi	r17, r31, Queue.Messages
	stw		r17, LLL.Freeform(r8)

	InsertAsPrev	r8, r17, scratch=r16

	lwz		r18, Queue.MessageCount(r31)
	addi	r18, r18, 1
	stw		r18, Queue.MessageCount(r31)

	mflr	r27

	lwz		r8, Queue.BlockedTasks + LLL.Freeform(r31)
	bl		UnblockBlueIfCouldBePolling

	;	Got a task to unblock straight away?
	lwz		r16, Queue.BlockedTasks + LLL.Next(r31)
	cmpw	r16, r31
	subi	r8, r16, Task.QueueMember
	beq		@no_task

	;	Saves us special-casing 
	lwz		r17, Task.ContextBlockPtr(r8)
	lwz		r18, ContextBlock.CodePtr(r17)
	subi	r18, r18, 4
	stw		r18, ContextBlock.CodePtr(r17)

	;	De-fang the task's blocking timeout
	lbz		r17, Task.Timer + Timer.Byte3(r8)
	cmpwi	r17, 1
	bne		@no_timeout
	addi	r8, r8, Task.Timer
	bl		DequeueTimer
@no_timeout

	;	Remove the task from this MSGQ
	lwz		r16, Queue.BlockedTasks + LLL.Next(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18

	lwz		r18, Queue.BlockedTaskCount(r31)
	subi	r18, r18, 1
	stw		r18, Queue.BlockedTaskCount(r31)

	subi	r8, r16, Task.QueueMember

	;	And add it back to the latency-protection RDYQ
	li		r17, Task.kLatencyProtectPriority
	stb		r17, Task.Priority(r8)

	bl		SchRdyTaskNow
	bl		CalculateTimeslice

	bl		FlagSchEvaluationIfTaskRequires
@no_task

	mtlr	r27
	blr



   ##    #######      #######     ##      ##    ###    #### ######## 
 ####   ##     ##    ##     ##    ##  ##  ##   ## ##    ##     ##    
   ##   ##     ##    ##     ##    ##  ##  ##  ##   ##   ##     ##    
   ##    #######     ##     ##    ##  ##  ## ##     ##  ##     ##    
   ##   ##     ##    ##  ## ##    ##  ##  ## #########  ##     ##    
   ##   ##     ##    ##    ##     ##  ##  ## ##     ##  ##     ##    
 ######  #######      ##### ##     ###  ###  ##     ## ####    ##    

;	Get a message from the specified queue, or fail.

;	Abbreviated summary of cases:
;	1. Return a pending message
;	2. Time out instantly
;	3. Move task to MSGQ from RDYQ and arm timer
;	4. Move task to MSGQ from RDYQ, no timeout

;	ARG		QueueID r3, Duration r7
;	RET		OSStatus r3, long r4, long r5, long r6

	DeclareMPCall	18, MPWaitOnQueue

MPWaitOnQueue

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8

	lwz		r16, Queue.Messages + LLL.Next(r31)
	addi	r17, r31, Queue.Messages
	cmpw	r16, r17
	beq		@no_messages_pending

;messages pending
	lwz		r4, Message.Word1(r16)
	lwz		r5, Message.Word2(r16)
	lwz		r17, Message.Word3(r16)
	stw		r17, ContextBlock.r6(r6)

	RemoveFromList		r16, scratch1=r17, scratch2=r18

	lwz		r18, Queue.MessageCount(r31)
	subi	r18, r18, 1
	stw		r18, Queue.MessageCount(r31)

	lbz		r17, Message.LLL + LLL.Signature + 3(r16)		; 'r' if mem-reserved message, else 'e'
	mr		r8, r16
	cmpwi	r17, Message.kReservedSignature & 0xFF
	beq		@immediate_msg_was_reserved

;immediate message was not reserved ... return noErr
	bl		PoolFree
	b		ReleaseAndReturnZeroFromMPCall

@immediate_msg_was_reserved ; ... return noErr
	lwz		r17, Queue.ReservePtr(r31)
	stw		r16, Queue.ReservePtr(r31)
	stw		r17, LLL.Next(r16)
	b		ReleaseAndReturnZeroFromMPCall


;	The blocking case (eew!)

@no_messages_pending
	lwz		r17, ContextBlock.r7(r6)
	mfsprg	r30, 0

;special case: zero timeout ... return
	cmpwi	r17, 0
	lwz		r19, EWA.PA_CurTask(r30)
	beq		ReleaseAndTimeoutMPCall

;special case: blue may not block
	lwz		r16, Task.Flags(r19)
	rlwinm.	r16, r16, 0, Task.kFlagBlue, Task.kFlagBlue
	beq		@bot_blue
	stw		r3, PSA.BlueSpinningOn(r1)
	b		ReleaseAndReturnMPCallBlueBlocking
@bot_blue

;committed to blocking the calling task

	;	Remove from ready queue
	mr		r8, r19
	bl		SchTaskUnrdy

	;	Add to this queue
	lwz		r19, EWA.PA_CurTask(r30)

	addi	r16, r31, Queue.BlockedTasks
	addi	r17, r19, Task.QueueMember

	stw		r16, LLL.FreeForm(r17)
	InsertAsPrev	r17, r16, scratch=r18

	lwz		r18, Queue.BlockedTaskCount(r31)
	addi	r18, r18, 1
	stw		r18, Queue.BlockedTaskCount(r31)

	;	Decide whether call can time out
	_lstart	r16, 0x7fffffff ; "forever"
	lwz		r17, ContextBlock.r7(r6)
	_lfinish

	addi	r30, r19, Task.Timer
	cmpw	r17, r16

	li		r16, 2
	beq		@wait_forever

;committed to arming task's built-in timer (finite timeout)
	stb		r16, Timer.Kind(r30)
	stw		r19, Timer.ParentTaskPtr(r30)
	mr		r8, r17

	;	Convert that timeout to a tick count
	bl		TimebaseTicksPerPeriod
	mr		r27, r8
	mr		r28, r9

	bl		GetTime
	mfxer	r16
	addc	r9, r9, r28
	adde	r8, r8, r27
	mtxer	r16

	;	Now r8/r9 = absolute timeout date
	stw		r8, Timer.Time(r30)
	stw		r9, Timer.Time+4(r30)

	mr		r8, r30
	bl		EnqueueTimer

@wait_forever
	b		BlockMPCall



   ##    #######      #######      #######  ##     ## ######## ########  ##    ## 
 ####   ##     ##    ##     ##    ##     ## ##     ## ##       ##     ##  ##  ##  
   ##   ##     ##    ##     ##    ##     ## ##     ## ##       ##     ##   ####   
   ##    ########    ##     ##    ##     ## ##     ## ######   ########     ##    
   ##          ##    ##  ## ##    ##  ## ## ##     ## ##       ##   ##      ##    
   ##   ##     ##    ##    ##     ##    ##  ##     ## ##       ##    ##     ##    
 ######  #######      ##### ##     ##### ##  #######  ######## ##     ##    ##    

;	Non-blocking peek at contents of queue (undocumented)
;	Returns timeout if empty, noErr if non-empty

;	ARG		QueueID r3
;	RET		OSStatus r3

	DeclareMPCall	19, MPQueryQueue

MPQueryQueue

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID

	cmpwi	r9, Queue.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8
	lwz		r16, Queue.Messages + LLL.Next(r31)
	addi	r17, r31, Queue.Messages
	cmpw	r16, r17

	beq		ReleaseAndTimeoutMPCall

	b		ReleaseAndReturnZeroFromMPCall









 ######  ######## ##     ##    ###    ########  ##     ##  #######  ########  ########  ######  
##    ## ##       ###   ###   ## ##   ##     ## ##     ## ##     ## ##     ## ##       ##    ## 
##       ##       #### ####  ##   ##  ##     ## ##     ## ##     ## ##     ## ##       ##       
 ######  ######   ## ### ## ##     ## ########  ######### ##     ## ########  ######    ######  
      ## ##       ##     ## ######### ##        ##     ## ##     ## ##   ##   ##             ## 
##    ## ##       ##     ## ##     ## ##        ##     ## ##     ## ##    ##  ##       ##    ## 
 ######  ######## ##     ## ##     ## ##        ##     ##  #######  ##     ## ########  ######  



 #######    #####       ######      ######  ########  ########    ###    ######## ######## 
##     ##  ##   ##     ##    ##    ##    ## ##     ## ##         ## ##      ##    ##       
       ## ##     ##    ##          ##       ##     ## ##        ##   ##     ##    ##       
 #######  ##     ##     ######     ##       ########  ######   ##     ##    ##    ######   
##        ##     ##          ##    ##       ##   ##   ##       #########    ##    ##       
##         ##   ##     ##    ##    ##    ## ##    ##  ##       ##     ##    ##    ##       
#########   #####       ######      ######  ##     ## ######## ##     ##    ##    ######## 

;	ARG		maxValue r3, initialValue r4
;	RET		OSStatus r3, SemaphoreID r5

	DeclareMPCall	20, MPCreateSemaphore

MPCreateSemaphore

	cmpw	r4, r3
	bgt		ReturnMPCallOOM

	li		r8, Semaphore.Size
	bl		PoolAlloc
	mr.		r31, r8
	beq		ScrambleMPCall

	InitList	r31, Semaphore.kSignature, scratch=r16

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9, Semaphore.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	bne+	@nofail

	mr		r8, r31
	bl		PoolFree
	b		ReleaseAndScrambleMPCall
@nofail

	li		r18,  0x00
	stw		r8,  0x0000(r31)

	mfsprg	r30, 0
	lwz		r30, EWA.PA_CurTask(r30)

	stw		r3, Semaphore.MaxValue(r31)
	stw		r4, Semaphore.Value(r31)
	lwz		r17, Task.ProcessID(r30)
	stw		r18, Semaphore.BlockedTaskCount(r31)
	stw		r17, Semaphore.ProcessID(r31)

	mr		r5, r8

	b		ReleaseAndReturnZeroFromMPCall



 #######   #######      ######     ##      ##    ###    #### ######## 
##     ## ##     ##    ##    ##    ##  ##  ##   ## ##    ##     ##    
       ##        ##    ##          ##  ##  ##  ##   ##   ##     ##    
 #######   #######      ######     ##  ##  ## ##     ##  ##     ##    
##               ##          ##    ##  ##  ## #########  ##     ##    
##        ##     ##    ##    ##    ##  ##  ## ##     ##  ##     ##    
#########  #######      ######      ###  ###  ##     ## ####    ##    

;	Wait on a semaphore, or fail (similar to MPWaitOnQueue)

;	Abbreviated summary of cases:
;	1. Decrement and return instantly
;	2. Time out instantly
;	3. Move task to SEMA from RDYQ and arm timer
;	4. Move task to SEMA from RDYQ, no timeout

;	ARG		SemaphoreID r3, Duration r4

	DeclareMPCall	23, MPWaitOnSemaphore

MPWaitOnSemaphore

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	lwz		r16, Semaphore.Value(r31)
	cmpwi	r16, 0
	subi	r16, r16, 1
	ble		@must_wait

;easiest case ... decrement and return
	stw		r16, Semaphore.Value(r31)
	b		ReleaseAndReturnZeroFromMPCall
@must_wait

;next easiest case ... instant timeout
	cmpwi	r4, 0
	mfsprg	r30, 0
	beq		ReleaseAndTimeoutMPCall

	lwz		r8, EWA.PA_CurTask(r30)

;special case: blue may not block
	lwz		r16, Task.Flags(r8)
	rlwinm.	r16, r16, 0, Task.kFlagBlue, Task.kFlagBlue
	beq		@bot_blue
	stw		r3, PSA.BlueSpinningOn(r1)
	b		ReleaseAndReturnMPCallBlueBlocking
@bot_blue

;committed to blocking the calling task

	;	Remove from ready queue
	bl		SchTaskUnrdy

	;	Add to this queue
	addi	r16, r31, Semaphore.BlockedTasks
	addi	r17, r8, Task.QueueMember

	stw		r16, LLL.FreeForm(r17)
	InsertAsPrev	r17, r16, scratch=r18

	lwz		r18, Semaphore.BlockedTaskCount(r31)
	addi	r18, r18, 1
	stw		r18, Semaphore.BlockedTaskCount(r31)

	_lstart	r16,  0x7fffffff
	addi	r30, r8, Task.Timer
	_lfinish
	cmpw	r4, r16

	li		r17, 2
	beq		@wait_forever

;committed to creating a timer (finite timeout)
	stb		r17, Timer.Kind(r30)
	stw		r8, Timer.ParentTaskPtr(r30)
	mr		r8, r4

	;	Convert that timeout to a tick count
	bl		TimebaseTicksPerPeriod
	mr		r27, r8
	mr		r28, r9

	bl		GetTime
	mfxer	r16
	addc	r9, r9, r28
	adde	r8, r8, r27
	mtxer	r16

	;	Now r8/r9 = absolute timeout date
	stw		r8, Timer.Time(r30)
	stw		r9, Timer.Time+4(r30)

	mr		r8, r30
	bl		EnqueueTimer

@wait_forever
	li		r3,  0x00
	b		BlockMPCall



 #######  ##            ######      #######  ##     ## ######## ########  ##    ## 
##     ## ##    ##     ##    ##    ##     ## ##     ## ##       ##     ##  ##  ##  
       ## ##    ##     ##          ##     ## ##     ## ##       ##     ##   ####   
 #######  ##    ##      ######     ##     ## ##     ## ######   ########     ##    
##        #########          ##    ##  ## ## ##     ## ##       ##   ##      ##    
##              ##     ##    ##    ##    ##  ##     ## ##       ##    ##     ##    
#########       ##      ######      ##### ##  #######  ######## ##     ##    ##    

;	Non-blocking peek at semaphore (undocumented)
;	Returns timeout if empty, noErr if non-empty

;	ARG		SemaphoreID r3
;	RET		OSStatus r3

	DeclareMPCall	24, MPQuerySemaphore

MPQuerySemaphore

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID

	cmpwi	r9, Semaphore.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8
	lwz		r16, Semaphore.Value(r31)
	cmpwi	r16, 0

	ble		ReleaseAndTimeoutMPCall

	b		ReleaseAndReturnZeroFromMPCall



 #######   #######      ######      ######  ####  ######   ##    ##    ###    ##       
##     ## ##     ##    ##    ##    ##    ##  ##  ##    ##  ###   ##   ## ##   ##       
       ##        ##    ##          ##        ##  ##        ####  ##  ##   ##  ##       
 #######   #######      ######      ######   ##  ##   #### ## ## ## ##     ## ##       
##        ##                 ##          ##  ##  ##    ##  ##  #### ######### ##       
##        ##           ##    ##    ##    ##  ##  ##    ##  ##   ### ##     ## ##       
######### #########     ######      ######  ####  ######   ##    ## ##     ## ######## 

;	ARG		SemaphoreID r3
;	RET		OSStatus r3

	DeclareMPCall	22, MPSignalSemaphore

MPSignalSemaphore

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID

	cmpwi	r9, Semaphore.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	bl		SignalSemaphore

	mr		r3, r8
	b		ReleaseAndReturnMPCall



  ###  ######      ######  ####  ######   ##    ##    ###    ##       ###   
 ##   ##    ##    ##    ##  ##  ##    ##  ###   ##   ## ##   ##         ##  
##    ##          ##        ##  ##        ####  ##  ##   ##  ##          ## 
##     ######      ######   ##  ##   #### ## ## ## ##     ## ##          ## 
##          ##          ##  ##  ##    ##  ##  #### ######### ##          ## 
 ##   ##    ##    ##    ##  ##  ##    ##  ##   ### ##     ## ##         ##  
  ###  ######      ######  ####  ######   ##    ## ##     ## ######## ###   

;	ARG		Semaphore *r31

SignalSemaphore	;	OUTSIDE REFERER
	mflr	r27
	lwz		r8, Semaphore.BlockedTasks + LLL.Freeform(r31)
	bl		UnblockBlueIfCouldBePolling
	lwz		r16,  0x0008(r31)
	cmpw	r16, r31
	beq		SignalSemaphore_0x80
	addi	r8, r16, -0x08
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne		SignalSemaphore_0x30
	addi	r8, r8,  0x20
	bl		DequeueTimer

SignalSemaphore_0x30
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18,  0x001c(r31)
	addi	r18, r18, -0x01
	stw		r18,  0x001c(r31)
	addi	r8, r16, -0x08
	li		r17,  0x01
	stb		r17,  0x0019(r8)
	bl		SchRdyTaskNow
	bl		CalculateTimeslice
	bl		FlagSchEvaluationIfTaskRequires
	mtlr	r27
	li		r8,  0x00
	blr

SignalSemaphore_0x80
	mtlr	r27
	lwz		r16,  0x0010(r31)
	lwz		r17,  0x0014(r31)
	cmpw	r16, r17
	addi	r16, r16,  0x01
	li		r8, kMPInsufficientResourcesErr
	bgelr
	stw		r16,  0x0010(r31)
	li		r8,  0x00
	blr



 #######     ##       ######     ########  ######## ##       ######## ######## ######## 
##     ##  ####      ##    ##    ##     ## ##       ##       ##          ##    ##       
       ##    ##      ##          ##     ## ##       ##       ##          ##    ##       
 #######     ##       ######     ##     ## ######   ##       ######      ##    ######   
##           ##            ##    ##     ## ##       ##       ##          ##    ##       
##           ##      ##    ##    ##     ## ##       ##       ##          ##    ##       
#########  ######     ######     ########  ######## ######## ########    ##    ######## 

	DeclareMPCall	21, MPDeleteSemaphore

MPDeleteSemaphore

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r8, r3
	bl		UnblockBlueIfCouldBePolling

MPCall_21_0x34
	addi	r30, r31, Semaphore.BlockedTasks
	lwz		r16, LLL.Next(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq		MPCall_21_0x98
	lwz		r17,  0x0088(r8)
	li		r18, kMPDeletedErr
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne		MPCall_21_0x68
	addi	r8, r8,  0x20
	bl		DequeueTimer

MPCall_21_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		SchRdyTaskNow
	bl		FlagSchEvaluationIfTaskRequires
	b		MPCall_21_0x34

MPCall_21_0x98
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall









 ######  ########  #### ######## ####  ######     ###    ##       
##    ## ##     ##  ##     ##     ##  ##    ##   ## ##   ##       
##       ##     ##  ##     ##     ##  ##        ##   ##  ##       
##       ########   ##     ##     ##  ##       ##     ## ##       
##       ##   ##    ##     ##     ##  ##       ######### ##       
##    ## ##    ##   ##     ##     ##  ##    ## ##     ## ##       
 ######  ##     ## ####    ##    ####  ######  ##     ## ######## 

########  ########  ######   ####  #######  ##    ##  ######  
##     ## ##       ##    ##   ##  ##     ## ###   ## ##    ## 
##     ## ##       ##         ##  ##     ## ####  ## ##       
########  ######   ##   ####  ##  ##     ## ## ## ##  ######  
##   ##   ##       ##    ##   ##  ##     ## ##  ####       ## 
##    ##  ##       ##    ##   ##  ##     ## ##   ### ##    ## 
##     ## ########  ######   ####  #######  ##    ##  ######  



 #######  ########    ########      ######  ########  ########    ###    ######## ######## 
##     ## ##          ##     ##    ##    ## ##     ## ##         ## ##      ##    ##       
       ## ##          ##     ##    ##       ##     ## ##        ##   ##     ##    ##       
 #######  #######     ########     ##       ########  ######   ##     ##    ##    ######   
##              ##    ##   ##      ##       ##   ##   ##       #########    ##    ##       
##        ##    ##    ##    ##     ##    ## ##    ##  ##       ##     ##    ##    ##       
#########  ######     ##     ##     ######  ##     ## ######## ##     ##    ##    ######## 



	DeclareMPCall	25, MPCreateCriticalRegion

MPCreateCriticalRegion
	li		r8,  0x24
	bl		PoolAlloc
	mr.		r31, r8
	beq		ScrambleMPCall
	InitList	r31, CriticalRegion.kSignature, scratch=r16

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9,  0x06

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne+	MPCall_25_0x58
	mr		r8, r31
	bl		PoolFree
	b		ReleaseAndScrambleMPCall

MPCall_25_0x58
	li		r18,  0x00
	mfsprg	r30, 0
	lwz		r30, -0x0008(r30)
	li		r16,  0x00
	stw		r8,  0x0000(r31)
	stw		r16,  0x0014(r31)
	stw		r16,  0x001c(r31)
	stw		r16,  0x0018(r31)
	lwz		r17,  0x0060(r30)
	stw		r18,  0x0020(r31)
	stw		r17,  0x0010(r31)
	mr		r4, r8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



 #######  ########    ########     ######## ##    ## ######## ######## ########  
##     ## ##    ##    ##     ##    ##       ###   ##    ##    ##       ##     ## 
       ##     ##      ##     ##    ##       ####  ##    ##    ##       ##     ## 
 #######     ##       ########     ######   ## ## ##    ##    ######   ########  
##          ##        ##   ##      ##       ##  ####    ##    ##       ##   ##   
##          ##        ##    ##     ##       ##   ###    ##    ##       ##    ##  
#########   ##        ##     ##    ######## ##    ##    ##    ######## ##     ## 

	DeclareMPCall	27, MPEnterCriticalRegion

MPEnterCriticalRegion

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mfsprg	r17, 0
	lwz		r18,  0x0014(r31)
	lwz		r30, -0x0008(r17)
	cmpwi	r18,  0x00
	lwz		r16,  0x0018(r31)
	beq		MPCall_27_0x64
	lwz		r17,  0x001c(r31)
	cmpw	r16, r30
	cmpw	cr1, r17, r5
	bne		MPCall_27_0x78
	bne		cr1, MPCall_27_0x78
	addi	r18, r18,  0x01
	stw		r18,  0x0014(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_27_0x64
	addi	r18, r18,  0x01
	stw		r30,  0x0018(r31)
	stw		r5,  0x001c(r31)
	stw		r18,  0x0014(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_27_0x78
	lwz		r8,  0x0000(r16)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Task.kIDClass

	bne		ReleaseAndReturnMPCallTaskAborted
	lwz		r8,  0x001c(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Process.kIDClass

	bne		ReleaseAndReturnMPCallTaskAborted
	cmpwi	r4,  0x00
;special case: blue may not block
	lwz		r16, Task.Flags(r30)
	beq		ReleaseAndTimeoutMPCall
	rlwinm.	r16, r16, 0, Task.kFlagBlue, Task.kFlagBlue
	beq		@bot_blue
	stw		r3, PSA.BlueSpinningOn(r1)
	b		ReleaseAndReturnMPCallBlueBlocking
@bot_blue

MPCall_27_0xb4
	mr		r8, r30
	bl		SchTaskUnrdy
	lis		r16,  0x7fff
	addi	r18, r30,  0x08
	ori		r16, r16,  0xffff
	stw		r31,  0x0000(r18)
	InsertAsPrev	r18, r31, scratch=r19
	lwz		r18,  0x0020(r31)
	addi	r18, r18,  0x01
	stw		r18,  0x0020(r31)
	cmpw	r4, r16
	beq		MPCall_27_0x138
	addi	r29, r30,  0x20
	li		r8,  0x02
	stw		r30,  0x0018(r29)
	stb		r8,  0x0014(r29)
	mr		r8, r4

;	r1 = kdp
;	r8 = multiple (pos: /250; neg: /250000)
	bl		TimebaseTicksPerPeriod
;	r8 = hi
;	r9 = lo

	mr		r27, r8
	mr		r28, r9
	bl		GetTime
	mfxer	r16
	addc	r9, r9, r28
	adde	r8, r8, r27
	mtxer	r16
	stw		r8,  0x0038(r29)
	stw		r9,  0x003c(r29)
	mr		r8, r29
	bl		EnqueueTimer

MPCall_27_0x138
	b		BlockMPCall



 #######   #######     ########      #######  ##     ## ######## ########  ##    ## 
##     ## ##     ##    ##     ##    ##     ## ##     ## ##       ##     ##  ##  ##  
       ## ##     ##    ##     ##    ##     ## ##     ## ##       ##     ##   ####   
 #######   ########    ########     ##     ## ##     ## ######   ########     ##    
##               ##    ##   ##      ##  ## ## ##     ## ##       ##   ##      ##    
##        ##     ##    ##    ##     ##    ##  ##     ## ##       ##    ##     ##    
#########  #######     ##     ##     ##### ##  #######  ######## ##     ##    ##    

	DeclareMPCall	29, MPQueryCriticalRegion

MPQueryCriticalRegion

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mfsprg	r17, 0
	lwz		r18,  0x0014(r31)
	cmpwi	r18,  0x00

;	r1 = kdp
	beq		ReleaseAndReturnZeroFromMPCall
	lwz		r30, -0x0008(r17)
	lwz		r16,  0x0018(r31)
	lwz		r17,  0x001c(r31)
	cmpw	r16, r30
	cmpw	cr1, r17, r4
	bne		ReleaseAndTimeoutMPCall
	bne		cr1, ReleaseAndTimeoutMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



 #######   #######     ########     ######## ##     ## #### ######## 
##     ## ##     ##    ##     ##    ##        ##   ##   ##     ##    
       ## ##     ##    ##     ##    ##         ## ##    ##     ##    
 #######   #######     ########     ######      ###     ##     ##    
##        ##     ##    ##   ##      ##         ## ##    ##     ##    
##        ##     ##    ##    ##     ##        ##   ##   ##     ##    
#########  #######     ##     ##    ######## ##     ## ####    ##    

	DeclareMPCall	28, MPExitCriticalRegion

MPExitCriticalRegion

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mfsprg	r17, 0
	lwz		r16,  0x0018(r31)
	lwz		r30, -0x0008(r17)
	lwz		r18,  0x0014(r31)
	lwz		r17,  0x001c(r31)
	cmpw	r16, r30
	cmpw	cr1, r17, r4
	bne		ReleaseAndReturnMPCallOOM
	bne		cr1, ReleaseAndReturnMPCallOOM
	addi	r18, r18, -0x01
	cmpwi	r18,  0x00
	stw		r18,  0x0014(r31)

;	r1 = kdp
	bne		ReleaseAndReturnZeroFromMPCall
	stw		r18,  0x0018(r31)
	stw		r18,  0x001c(r31)
	mr		r8, r3
	bl		UnblockBlueIfCouldBePolling
	lwz		r16,  0x0008(r31)
	cmpw	r16, r31

;	r1 = kdp
	beq		ReleaseAndReturnZeroFromMPCall
	addi	r8, r16, -0x08
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne		MPCall_28_0x94
	addi	r8, r8,  0x20
	bl		DequeueTimer

MPCall_28_0x94
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18,  0x0020(r31)
	addi	r18, r18, -0x01
	stw		r18,  0x0020(r31)
	addi	r8, r16, -0x08
	lwz		r17,  0x0088(r8)
	lwz		r18,  0x00fc(r17)
	subi	r18, r18, 4
	stw		r18,  0x00fc(r17)
	li		r17,  0x01
	stb		r17,  0x0019(r8)
	bl		SchRdyTaskNow
	bl		CalculateTimeslice
	bl		FlagSchEvaluationIfTaskRequires

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



 #######   #######     ########     ########  ######## ##       ######## ######## ######## 
##     ## ##     ##    ##     ##    ##     ## ##       ##       ##          ##    ##       
       ## ##           ##     ##    ##     ## ##       ##       ##          ##    ##       
 #######  ########     ########     ##     ## ######   ##       ######      ##    ######   
##        ##     ##    ##   ##      ##     ## ##       ##       ##          ##    ##       
##        ##     ##    ##    ##     ##     ## ##       ##       ##          ##    ##       
#########  #######     ##     ##    ########  ######## ######## ########    ##    ######## 

	DeclareMPCall	26, MPDeleteCriticalRegion

MPDeleteCriticalRegion

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r3
	bl		UnblockBlueIfCouldBePolling

MPCall_26_0x34
	addi	r30, r31,  0x00
	lwz		r16,  0x0008(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq		MPCall_26_0x98
	lwz		r17,  0x0088(r8)
	li		r18, kMPDeletedErr
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne		MPCall_26_0x68
	addi	r8, r8,  0x20
	bl		DequeueTimer

MPCall_26_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		SchRdyTaskNow
	bl		FlagSchEvaluationIfTaskRequires
	b		MPCall_26_0x34

MPCall_26_0x98
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall









######## ##     ## ######## ##    ## ######## 
##       ##     ## ##       ###   ##    ##    
##       ##     ## ##       ####  ##    ##    
######   ##     ## ######   ## ## ##    ##    
##        ##   ##  ##       ##  ####    ##    
##         ## ##   ##       ##   ###    ##    
########    ###    ######## ##    ##    ##    

 ######   ########   #######  ##     ## ########   ######  
##    ##  ##     ## ##     ## ##     ## ##     ## ##    ## 
##        ##     ## ##     ## ##     ## ##     ## ##       
##   #### ########  ##     ## ##     ## ########   ######  
##    ##  ##   ##   ##     ## ##     ## ##              ## 
##    ##  ##    ##  ##     ## ##     ## ##        ##    ## 
 ######   ##     ##  #######   #######  ##         ######  



;_______________________________________________________________________
;	Lifted from docs:
;
;	An event group is essentially a group of binary semaphores. You can use
;	event groups to indicate a number of simple events. For example, a task
;	running on a server may need to be aware of multiple message queues.
;	Instead of trying to poll each one in turn, the server task can wait on
;	an event group. Whenever a message is posted on a queue, the poster can
;	also set the bit corresponding to that queue in the event group. Doing
;	so notifies the task, and it then knows which queue to access to extract
;	the message. In Multiprocessing Services, an event group consists of
;	thirty-two 1-bit flags, each of which may be set independently. When a
;	task receives an event group, it receives all 32-bits at once (that is,
;	it cannot poll individual bits), and all the bits in the event group are
;	subsequently cleared.
;_______________________________________________________________________



##         #######     ########     ######  ########  ########    ###    ######## ######## 
##    ##  ##     ##    ##          ##    ## ##     ## ##         ## ##      ##    ##       
##    ##  ##     ##    ##          ##       ##     ## ##        ##   ##     ##    ##       
##    ##   ########    ######      ##       ########  ######   ##     ##    ##    ######   
#########        ##    ##          ##       ##   ##   ##       #########    ##    ##       
      ##  ##     ##    ##          ##    ## ##    ##  ##       ##     ##    ##    ##       
      ##   #######     ########     ######  ##     ## ######## ##     ##    ##    ######## 

	DeclareMPCall	49, MPCreateEvent

;	RET		OSStatus r3, MPEventID r4

;	called using the FE1F trap by the 68k ROM

MPCreateEvent

	li		r8, EventGroup.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		ScrambleMPCall

	InitList	r8, EventGroup.kSignature, scratch=r16

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9, EventGroup.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	bne+	@success

	mr		r8, r31
	bl		PoolFree
	b		ReleaseAndScrambleMPCall

@success
	mfsprg	r30, 0
	lwz		r30, EWA.PA_CurTask(r30)

	stw		r8, EventGroup.LLL + LLL.Freeform(r31)

	lwz		r17, Task.ProcessID(r30)
	stw		r17, EventGroup.ProcessID(r31)

	mr		r4, r8
	b		ReleaseAndReturnZeroFromMPCall



########   #####      ########    ########  ######## ##       ######## ######## ######## 
##        ##   ##     ##          ##     ## ##       ##       ##          ##    ##       
##       ##     ##    ##          ##     ## ##       ##       ##          ##    ##       
#######  ##     ##    ######      ##     ## ######   ##       ######      ##    ######   
      ## ##     ##    ##          ##     ## ##       ##       ##          ##    ##       
##    ##  ##   ##     ##          ##     ## ##       ##       ##          ##    ##       
 ######    #####      ########    ########  ######## ######## ########    ##    ######## 

	DeclareMPCall	50, MPDeleteEvent

;	ARG		MPEventID r3
;	RET		OSStatus r3

MPDeleteEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r8, r3
	bl		UnblockBlueIfCouldBePolling

MPDeleteEvent_0x34
	addi	r30, r31,  0x00
	lwz		r16,  0x0008(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq		MPDeleteEvent_0x98
	lwz		r17,  0x0088(r8)
	li		r18, kMPDeletedErr
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne		MPDeleteEvent_0x68
	addi	r8, r8,  0x20
	bl		DequeueTimer

MPDeleteEvent_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		SchRdyTaskNow
	bl		FlagSchEvaluationIfTaskRequires
	b		MPDeleteEvent_0x34

MPDeleteEvent_0x98
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



########    ##      ########     ######  ######## ######## 
##        ####      ##          ##    ## ##          ##    
##          ##      ##          ##       ##          ##    
#######     ##      ######       ######  ######      ##    
      ##    ##      ##                ## ##          ##    
##    ##    ##      ##          ##    ## ##          ##    
 ######   ######    ########     ######  ########    ##    

	DeclareMPCall	51, MPSetEvent

;	ARG		MPEventID r3, MPEventFlags r4
;	RET		OSStatus r3

MPSetEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r8, r4
	bl		SetEvent

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



  ### ########     ######  ######## ######## ###   
 ##   ##          ##    ## ##          ##      ##  
##    ##          ##       ##          ##       ## 
##    ######       ######  ######      ##       ## 
##    ##                ## ##          ##       ## 
 ##   ##          ##    ## ##          ##      ##  
  ### ########     ######  ########    ##    ###   

;	ARG		Event *r31, flags r8

SetEvent
	lwz		r16, EventGroup.Flags(r31)
	or		r16, r16, r8
	stw		r16, EventGroup.Flags(r31)

	mflr	r27

	lwz		r8, EventGroup.LLL + LLL.Freeform(r31)
	bl		UnblockBlueIfCouldBePolling

	;	
	lwz		r16, EventGroup.LLL + LLL.Next(r31)
	cmpw	r16, r31
	subi	r8, r16, Task.QueueMember
	beq		@no_task_waiting


	;	CASE 1: task needs unblocking

	;	Rerun SC instruction in task context
	lwz		r17, Task.ContextBlockPtr(r8)
	lwz		r18, ContextBlock.CodePtr(r17)
	subi	r18, r18, 4
	stw		r18, ContextBlock.CodePtr(r17)

	;	Cancel timeout
	lbz		r17, Task.Timer + Timer.Byte3(r8)
	cmpwi	r17, 1
	bne		@timer_not_armed
	addi	r8, r8, Task.Timer
	bl		DequeueTimer
@timer_not_armed

	;	Remove this task from my wait queue
	lwz		r16, EventGroup.LLL + LLL.Next(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18, EventGroup.Counter(r31)
	subi	r18, r18, 1
	stw		r18, EventGroup.Counter(r31)

	;	Latency protection priority
	subi	r8, r16, Task.QueueMember
	li		r17, Task.kLatencyProtectPriority
	stb		r17, Task.Priority(r8)

	bl		SchRdyTaskNow
	bl		CalculateTimeslice
	bl		FlagSchEvaluationIfTaskRequires


@no_task_waiting
	lwz		r16, EventGroup.SWI(r31)
	rlwinm.	r17, r16, 0, 27, 27


	;	CASE 2: no task waiting.

	beq		@return


	;	CASE 3: SOFTWARE INTERRUPT

	lwz		r17, KDP.PA_ECB(r1)
	lwz		r26, PSA.PA_BlueTask(r1)
	lwz		r18, ContextBlock.EDPOffsetSWIRelated(r17)
	lwz		r19, ContextBlock.SWIEventGroupID(r17)
	cmpwi	cr1, r18, 0
	cmpwi	r19, 0
	bne		cr1, @do_not_save_swi_event_id
	bne		@return

	lwz		r8, EventGroup.LLL + LLL.Freeform(r31) ; contains my ID
	stw		r8, ContextBlock.SWIEventGroupID(r17)
	b		@common_case
@do_not_save_swi_event_id

	;	There is an EDP table of SWI-EventGroup IDs... set ours, cancel if already set
	lwz		r9, KDP.PA_EmulatorData(r1)
	rlwinm	r16, r16,  2, 26, 29
	add		r18, r18, r9
	lwzx	r19, r16, r18
	cmpwi	r19, 0
	bne		@return

	;	Set!
	lwz		r8, EventGroup.LLL + LLL.Freeform(r31) ; my ID
	stwx	r8, r16, r18

	;	Find the highest interrupt level with a nonzero thing
	li		r19, 7*4
	li		r9, 4
@loop
	lwzx	r8, r19, r18
	cmpwi	r8, 0
	bne		@exit_loop
	subf.	r19, r9, r19
	bgt		@loop
	bl		panic
@exit_loop

	;	Can I interrupt the current interrupt?
	cmplw	r16, r19
	srwi	r16, r16, 2
	blt		@return
	stw		r16, ContextBlock.SWIEventGroupID(r17)
@common_case


	lwz		r16, Task.Flags(r26)
	lbz		r19, Task.State(r26)
	ori		r16, r16, (1 << (31 - Task.kFlagSchToInterruptEmu))
	stw		r16, Task.Flags(r26)

	;	But what *is* MCR?
	lwz		r17, PSA.MCR(r1)
	lwz		r16,  KDP.PostIntMaskInit(r1)
	lwz		r8,  KDP.ClearIntMaskInit(r1)
	and		r16, r16, r8
	or		r17, r17, r16
	stw		r17, PSA.MCR(r1)

	cmpwi	r19, 0
	addi	r16, r26, Task.QueueMember
	bne		@task_already_running

	;	De-fang the blocking timeout
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lbz		r17, Task.Timer + Timer.Byte3(r26)
	cmpwi	r17, 1
	bne		@timer_not_armed_2
	addi	r8, r26, Task.Timer
	bl		DequeueTimer
@timer_not_armed_2

	lwz		r18, PSA.PA_BlueTask(r1)
	li		r16, Task.kCriticalPriority
	stb		r16, Task.Priority(r26)
	mr		r8, r26
	bl		SchRdyTaskLater
	mr		r8, r26
	bl		CalculateTimeslice
@task_already_running

	mr		r8, r26
	bl		FlagSchEvaluationIfTaskRequires

@return
	mtlr	r27
	blr



########  #######     ########    ##      ##    ###    #### ######## 
##       ##     ##    ##          ##  ##  ##   ## ##    ##     ##    
##              ##    ##          ##  ##  ##  ##   ##   ##     ##    
#######   #######     ######      ##  ##  ## ##     ##  ##     ##    
      ## ##           ##          ##  ##  ## #########  ##     ##    
##    ## ##           ##          ##  ##  ## ##     ##  ##     ##    
 ######  #########    ########     ###  ###  ##     ## ####    ##    

	DeclareMPCall	52, MPWaitForEvent

;	ARG		MPEventID r3, Duration r5
;	RET		OSStatus r3, MPEventFlags r4

;	called using the FE1F trap by the 68k ROM

MPWaitForEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

	;	Check that the Event Group ID in r3 is valid.
	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	lwz		r16, 0x0010(r31)
	cmpwi	r16, 0
	beq		MPWaitForEvent_field_10_was_zero

	mr		r4, r16

	li		r16, 0
	stw		r16,  0x0010(r31)

	lwz		r16,  0x0018(r31)
	lwz		r17, KDP.PA_ECB(r1)
	rlwinm.	r18, r16,  0, 27, 27
	rlwinm	r16, r16,  2, 26, 29
	beq		ReleaseAndReturnZeroFromMPCall

	lwz		r18,  0x00c8(r17)
	lwz		r9,  0x0634(r1)
	cmpwi	r18,  0x00
	add		r18, r18, r9
	bne		MPWaitForEvent_0x84
	lwz		r18,  0x00d0(r17)
	cmpw	r18, r3
	li		r18,  0x00

;	r1 = kdp
	bne		ReleaseAndReturnZeroFromMPCall
	stw		r18,  0x00d0(r17)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPWaitForEvent_0x84
	lwzx	r19, r16, r18
	cmpw	r19, r3
	li		r19,  0x00

;	r1 = kdp
	bne		ReleaseAndReturnZeroFromMPCall
	stwx	r19, r16, r18
	li		r19,  0x1c
	li		r9,  0x04

MPWaitForEvent_0xa0
	lwzx	r8, r19, r18
	cmpwi	r8,  0x00
	bne		MPWaitForEvent_0xb4
	subf.	r19, r9, r19
	bgt		MPWaitForEvent_0xa0

MPWaitForEvent_0xb4
	srwi	r19, r19,  2
	stw		r19,  0x00d0(r17)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPWaitForEvent_field_10_was_zero
	mfsprg	r30, 0
	cmpwi	r5, 0
	lwz		r19, EWA.PA_CurTask(r30)
	beq		ReleaseAndTimeoutMPCall

;special case: blue may not block
	lwz		r16, Task.Flags(r19)
	rlwinm.	r16, r16, 0, Task.kFlagBlue, Task.kFlagBlue
	beq		@bot_blue
	stw		r3, PSA.BlueSpinningOn(r1)
	b		ReleaseAndReturnMPCallBlueBlocking
@bot_blue

	;	MOVE TASK OUT OF QUEUE AND INTO EVENT GROUP
	mr		r8, r19
	bl		SchTaskUnrdy

	lwz		r19, EWA.PA_CurTask(r30)
	addi	r16, r31, EventGroup.LLL
	addi	r17, r19, Task.QueueMember
	stw		r16, LLL.FreeForm(r17)

	InsertAsPrev	r17, r16, scratch=r18

	lwz		r18, EventGroup.Counter(r31)
	addi	r18, r18, 1
	stw		r18, EventGroup.Counter(r31)

	lisori	r16, 0x7fffffff				;	LONG_MAX
	addi	r30, r19, Task.Timer
	cmpw	r5, r16
	li		r16, 2
	beq		@wait_forever				;	never trigger max-wait timers

	stb		r16, Timer.Kind(r30)
	stw		r19, Timer.ParentTaskPtr(r30)
	mr		r8, r5

	bl		TimebaseTicksPerPeriod
	mr		r27, r8
	mr		r28, r9

	bl		GetTime
	mfxer	r16
	addc	r9, r9, r28
	adde	r8, r8, r27
	mtxer	r16

	stw		r8, Timer.Time(r30)
	stw		r9, Timer.Time+4(r30)

	mr		r8, r30
	bl		EnqueueTimer

@wait_forever
	b		BlockMPCall



########  #######     ########     #######  ##     ## ######## ########  ##    ## 
##       ##     ##    ##          ##     ## ##     ## ##       ##     ##  ##  ##  
##              ##    ##          ##     ## ##     ## ##       ##     ##   ####   
#######   #######     ######      ##     ## ##     ## ######   ########     ##    
      ##        ##    ##          ##  ## ## ##     ## ##       ##   ##      ##    
##    ## ##     ##    ##          ##    ##  ##     ## ##       ##    ##     ##    
 ######   #######     ########     ##### ##  #######  ######## ##     ##    ##    

	DeclareMPCall	53, MPQueryEvent

;	Returns Timeout if no flags are set, otherwise NoErr

;	ARG		MPEventID r3
;	RET		OSStatus r3

MPQueryEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8
	lwz		r16,  0x0010(r31)
	cmpwi	r16,  0x00
	beq		ReleaseAndTimeoutMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



######## ##           ########     ######  ######## ########  ######  ##      ## #### 
##       ##    ##     ##          ##    ## ##          ##    ##    ## ##  ##  ##  ##  
##       ##    ##     ##          ##       ##          ##    ##       ##  ##  ##  ##  
#######  ##    ##     ######       ######  ######      ##     ######  ##  ##  ##  ##  
      ## #########    ##                ## ##          ##          ## ##  ##  ##  ##  
##    ##       ##     ##          ##    ## ##          ##    ##    ## ##  ##  ##  ##  
 ######        ##     ########     ######  ########    ##     ######   ###  ###  #### 

	DeclareMPCall	54, MPSetSWIEvent

;	ARG		MPEventID r3, int r4 swi

;	called using the FE1F trap by the 68k ROM

MPSetSWIEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8
	li		r17, 1

	cmpwi	r4, 0
	cmplwi	cr1, r4, 8

	lwz		r16, EventGroup.SWI(r31)

	beq		@use_1
	bgt		cr1, @use_1

	mr		r17, r4
@use_1

	;	r17 = 1 if outside 1-8 (inc) range

	ori		r16, r16, 0x10
	rlwimi	r16, r17, 0, 28, 31
	stw		r16, EventGroup.SWI(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall









######## #### ##     ## ######## ########   ######  
   ##     ##  ###   ### ##       ##     ## ##    ## 
   ##     ##  #### #### ##       ##     ## ##       
   ##     ##  ## ### ## ######   ########   ######  
   ##     ##  ##     ## ##       ##   ##         ## 
   ##     ##  ##     ## ##       ##    ##  ##    ## 
   ##    #### ##     ## ######## ##     ##  ######  



##          #####      ########     ######  ########  ########    ###    ######## ######## 
##    ##   ##   ##        ##       ##    ## ##     ## ##         ## ##      ##    ##       
##    ##  ##     ##       ##       ##       ##     ## ##        ##   ##     ##    ##       
##    ##  ##     ##       ##       ##       ########  ######   ##     ##    ##    ######   
######### ##     ##       ##       ##       ##   ##   ##       #########    ##    ##       
      ##   ##   ##        ##       ##    ## ##    ##  ##       ##     ##    ##    ##       
      ##    #####         ##        ######  ##     ## ######## ##     ##    ##    ######## 

	DeclareMPCall	40, NKCreateTimer

NKCreateTimer	;	OUTSIDE REFERER
	li		r8,  0x40

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	mr.		r31, r8
	beq		ScrambleMPCall

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r31
	li		r9,  0x03

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne		NKCreateTimer_0x48
	mr		r8, r31
	bl		PoolFree
	b		ReleaseAndScrambleMPCall

NKCreateTimer_0x48
	mfsprg	r30, 0
	stw		r8,  0x0000(r31)
	lwz		r30, -0x0008(r30)
	mr		r4, r8
	lwz		r17,  0x0060(r30)
	stw		r17,  0x0010(r31)
	bl		GetTime
	stw		r8,  0x0038(r31)
	stw		r9,  0x003c(r31)
	lis		r17,  0x5449
	ori		r17, r17,  0x4d45
	stw		r17,  0x0004(r31)
	li		r17,  0x03
	stb		r17,  0x0014(r31)
	li		r17,  0x00
	stb		r17,  0x0016(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



##           ##      ########    ########  ######## ##       ######## ######## ######## 
##    ##   ####         ##       ##     ## ##       ##       ##          ##    ##       
##    ##     ##         ##       ##     ## ##       ##       ##          ##    ##       
##    ##     ##         ##       ##     ## ######   ##       ######      ##    ######   
#########    ##         ##       ##     ## ##       ##       ##          ##    ##       
      ##     ##         ##       ##     ## ##       ##       ##          ##    ##       
      ##   ######       ##       ########  ######## ######## ########    ##    ######## 

	DeclareMPCall	41, NKDeleteTimer

NKDeleteTimer	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r3
	bl		DeleteID
	lwz		r16,  0x0008(r31)
	cmpwi	r16,  0x00
	beq		NKDeleteTimer_0x48
	mr		r8, r31
	bl		DequeueTimer

NKDeleteTimer_0x48
	_AssertAndRelease	PSA.SchLock, scratch=r16
	lwz		r8,  0x001c(r31)
	cmpwi	r8,  0x00
	bnel	PoolFree
	mr		r8, r31
	bl		PoolFree
	b		ReturnZeroFromMPCall



 #######    #####      ########     ######  ######## ######## ##    ##  #######  ######## #### ######## ##    ## 
##     ##  ##   ##        ##       ##    ## ##          ##    ###   ## ##     ##    ##     ##  ##        ##  ##  
       ## ##     ##       ##       ##       ##          ##    ####  ## ##     ##    ##     ##  ##         ####   
 #######  ##     ##       ##        ######  ######      ##    ## ## ## ##     ##    ##     ##  ######      ##    
       ## ##     ##       ##             ## ##          ##    ##  #### ##     ##    ##     ##  ##          ##    
##     ##  ##   ##        ##       ##    ## ##          ##    ##   ### ##     ##    ##     ##  ##          ##    
 #######    #####         ##        ######  ########    ##    ##    ##  #######     ##    #### ##          ##    

;	ARG		TimerID r3, EventGroup/Queue/SemaphoreID r4, long r5, long r6, long r7
;	RET		OSStatus r3

	DeclareMPCall	30, NKSetTimerNotify

NKSetTimerNotify

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lbz		r16, Timer.Kind(r31)
	cmpwi	r16, 3
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r8, r4
	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass
	cmpwi	cr2, r9, Queue.kIDClass
	beq		@SEMAPHORE
	cmpwi	r9, EventGroup.kIDClass
	beq		cr2, @QUEUE
	bne		ReleaseAndReturnMPCallInvalidIDErr

@EVENTGROUP
	stw		r4, Timer.EventGroupID(r31)
	stw		r5, Timer.EventGroupFlags(r31)

	b		ReleaseAndReturnZeroFromMPCall

@QUEUE
	stw		r4, Timer.MessageQueueID(r31)
	lwz		r16, ContextBlock.r6(r6)
	lwz		r17, ContextBlock.r7(r6)
	stw		r5, Timer.Message1(r31)			; notifyParam1
	stw		r16, Timer.Message2(r31)		; notifyParam2
	stw		r17, Timer.Message3(r31)		; notifyParam3

	b		ReleaseAndReturnZeroFromMPCall

@SEMAPHORE
	stw		r4, Timer.SemaphoreID(r31)


	b		ReleaseAndReturnZeroFromMPCall



 #######     ##      ########       ###    ########  ##     ## 
##     ##  ####         ##         ## ##   ##     ## ###   ### 
       ##    ##         ##        ##   ##  ##     ## #### #### 
 #######     ##         ##       ##     ## ########  ## ### ## 
       ##    ##         ##       ######### ##   ##   ##     ## 
##     ##    ##         ##       ##     ## ##    ##  ##     ## 
 #######   ######       ##       ##     ## ##     ## ##     ## 

;	Time can be absolute or delta, and a duration (r4)
;	or timebase time (r4/r5).

;	ARG		TimerID r3, long r4, long r5, OptionBits r6
;	RET		OSStatus r3

	DeclareMPCall	31, MPArmTimer

MPArmTimer

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lbz		r16, Timer.Kind(r31)
	cmpwi	r16, Timer.kKind3
	bne		ReleaseAndReturnMPCallInvalidIDErr


	;	Disarm if armed
	lwz		r16, Timer.QueueLLL + LLL.Freeform(r31)
	cmpwi	r16, 0
	mr		r8, r31
	beq		@no_disarm
	bl		DequeueTimer
@no_disarm


	;	Ah... reserve a note if a message is to be sent

	lwz		r9, Timer.ReservedMessage(r31)
	lwz		r8, Timer.MessageQueueID(r31)
	cmpwi	r9, 0
	cmpwi	cr1, r8, 0
	bne		@already_got_note
	beq		cr1, @no_queue

 	bl		LookupID
	cmpwi	r9, Queue.kIDClass
	bne		@no_queue

	lwz		r9, Queue.ReserveCount(r8)
	li		r8, Message.Size
	cmpwi	r9, 0
	bne		@already_got_notr

	bl		PoolAllocClear
	mr.		r30, r8
	beq		ReleaseAndScrambleMPCall

	lisori	r8, 'note'
	stw		r8, Message.LLL + LLL.Signature(r30)
	stw		r30,  0x001c(r31)
@already_got_note
@already_got_notr
@no_queue


	;	Calculate firing solution

	lwz		r16, ContextBlock.r6(r6)
	rlwinm.	r9, r16, 0, kMPTimeIsDurationMask
	mr		r8, r4
	beq		@not_duration
	bl		TimebaseTicksPerPeriod
	mr		r4, r8
	mr		r5, r9
@not_duration

	lwz		r16,  ContextBlock.r6(r6)
	rlwinm.	r8, r16, 0, kMPTimeIsDeltaMask
	mfxer	r17
	beq		@not_delta
	lwz		r19, Timer.Time + 4(r31)
	lwz		r18, Timer.Time(r31)
	addc	r5, r5, r19
	adde	r4, r4, r18
	mtxer	r17
@not_delta

	stw		r4, Timer.Time(r31)
	stw		r5, Timer.Time + 4(r31)


	;	Teensy little option: keep after firing?
	lwz		r16,  ContextBlock.r6(r6)
	rlwinm.	r16, r16, 0, kMPPreserveTimerIDMask
	li		r17, 0
	beq		@no_preserve
	li		r17, 1
@no_preserve
	stb		r17, Timer.KeepAfterFiring(r31)


	mr		r8, r31
	bl		EnqueueTimer


	b		ReleaseAndReturnZeroFromMPCall



 #######   #######     ########     ######     ###    ##    ##  ######  ######## ##       
##     ## ##     ##       ##       ##    ##   ## ##   ###   ## ##    ## ##       ##       
       ##        ##       ##       ##        ##   ##  ####  ## ##       ##       ##       
 #######   #######        ##       ##       ##     ## ## ## ## ##       ######   ##       
       ## ##              ##       ##       ######### ##  #### ##       ##       ##       
##     ## ##              ##       ##    ## ##     ## ##   ### ##    ## ##       ##       
 #######  #########       ##        ######  ##     ## ##    ##  ######  ######## ######## 

;	ARG		TimerID r3
;	RET		OSStatus r3, AbsoluteTime r4/r5

	DeclareMPCall	32, MPCancelTimer

MPCancelTimer

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lbz		r16, Timer.Byte3(r31)
	cmpwi	r16, 1
	bne		@say_no_time_remained

	lwz		r4, Timer.Time(r31)
	lwz		r5, Timer.Time + 4(r31)
	bl		GetTime
	mfxer	r16
	subfc	r5, r9, r5
	subfe.	r4, r8, r4
	mtxer	r16
	bge+	@can_return_time_remaining
@say_no_time_remained

	li		r4, 0
	li		r5, 0
@can_return_time_remaining

	lwz		r16, Timer.QueueLLL + LLL.Freeform(r31)
	cmpwi	r16, 0
	mr		r8, r31
	beq		@not_queued
	bl		DequeueTimer
@not_queued

	b		ReleaseAndReturnZeroFromMPCall









##    ##  #######  ######## #### ######## ####  ######     ###    ######## ####  #######  ##    ##  ######  
###   ## ##     ##    ##     ##  ##        ##  ##    ##   ## ##      ##     ##  ##     ## ###   ## ##    ## 
####  ## ##     ##    ##     ##  ##        ##  ##        ##   ##     ##     ##  ##     ## ####  ## ##       
## ## ## ##     ##    ##     ##  ######    ##  ##       ##     ##    ##     ##  ##     ## ## ## ##  ######  
##  #### ##     ##    ##     ##  ##        ##  ##       #########    ##     ##  ##     ## ##  ####       ## 
##   ### ##     ##    ##     ##  ##        ##  ##    ## ##     ##    ##     ##  ##     ## ##   ### ##    ## 
##    ##  #######     ##    #### ##       ####  ######  ##     ##    ##    ####  #######  ##    ##  ######  



 #######  ##           ##    ##     ######  ########  ########    ###    ######## ######## 
##     ## ##    ##     ###   ##    ##    ## ##     ## ##         ## ##      ##    ##       
##        ##    ##     ####  ##    ##       ##     ## ##        ##   ##     ##    ##       
########  ##    ##     ## ## ##    ##       ########  ######   ##     ##    ##    ######   
##     ## #########    ##  ####    ##       ##   ##   ##       #########    ##    ##       
##     ##       ##     ##   ###    ##    ## ##    ##  ##       ##     ##    ##    ##       
 #######        ##     ##    ##     ######  ##     ## ######## ##     ##    ##    ######## 

;	RET		OSErr r3, NotificationID r4

	DeclareMPCall	64, MPCreateNotification

MPCreateNotification
	li		r8, Notification.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		ScrambleMPCall

	lisori	r16, Notification.kSignature
	stw		r16, Notification.Signature(r31)

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9, Notification.kIDClass
	bl		MakeID

	cmpwi	r8, 0
	bne+	@nofail
	mr		r8, r31
	bl		PoolFree
	b		ReleaseAndScrambleMPCall
@nofail

	mfsprg	r30, 0
	lwz		r30, EWA.PA_CurTask(r30)
	stw		r8, Notification.TaskPtr(r31)
	lwz		r17, Task.ProcessID(r30)
	stw		r17, Notification.ProcessID(r31)

	mr		r4, r8
	b		ReleaseAndReturnZeroFromMPCall



 #######  ########    ##    ##    ########  ######## ##       ######## ######## ######## 
##     ## ##          ###   ##    ##     ## ##       ##       ##          ##    ##       
##        ##          ####  ##    ##     ## ##       ##       ##          ##    ##       
########  #######     ## ## ##    ##     ## ######   ##       ######      ##    ######   
##     ##       ##    ##  ####    ##     ## ##       ##       ##          ##    ##       
##     ## ##    ##    ##   ###    ##     ## ##       ##       ##          ##    ##       
 #######   ######     ##    ##    ########  ######## ######## ########    ##    ######## 

;	ARG		NotificationID r3
;	RET		OSErr r3

	DeclareMPCall	65, MPDeleteNotification

MPDeleteNotification

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

	b		ReleaseAndReturnZeroFromMPCall



 #######  ########    ##    ##     ######     ###    ##     ##  ######  ######## 
##     ## ##    ##    ###   ##    ##    ##   ## ##   ##     ## ##    ## ##       
##            ##      ####  ##    ##        ##   ##  ##     ## ##       ##       
########     ##       ## ## ##    ##       ##     ## ##     ##  ######  ######   
##     ##   ##        ##  ####    ##       ######### ##     ##       ## ##       
##     ##   ##        ##   ###    ##    ## ##     ## ##     ## ##    ## ##       
 #######    ##        ##    ##     ######  ##     ##  #######   ######  ######## 

	DeclareMPCall	67, MPCauseNotification

MPCauseNotification

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	mr		r30, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	bl		CauseNotification

	mr		r3, r8
	b		ReleaseAndReturnMPCall



  ### ##    ##     ######     ###    ##     ##  ######  ######## ###   
 ##   ###   ##    ##    ##   ## ##   ##     ## ##    ## ##         ##  
##    ####  ##    ##        ##   ##  ##     ## ##       ##          ## 
##    ## ## ##    ##       ##     ## ##     ##  ######  ######      ## 
##    ##  ####    ##       ######### ##     ##       ## ##          ## 
 ##   ##   ###    ##    ## ##     ## ##     ## ##    ## ##         ##  
  ### ##    ##     ######  ##     ##  #######   ######  ######## ###   

;	ARG		Notification *r30
;	RET		OSStatus r8

CauseNotification

	mflr	r29

	lwz		r16,  0x000c(r30)
	lwz		r17,  0x0024(r30)
	cmplwi	r16,  0x00
	cmplwi	cr1, r17,  0x00
	bne		@0x28
	bne		cr1, @0x28
	lwz		r18,  0x001c(r30)
	cmplwi	r18,  0x00
	beq		@fail_insufficient_resources
@0x28


	;	SEND MESSAGE TO QUEUE

	lwz		r8, Notification.QueueID(r30)
	cmplwi	r8, 0
	beq		@NO_QUEUE
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass
	mr		r31, r8
	bne		@fail_invalid_id

	lwz		r16, Queue.ReserveCount(r31)
	cmpwi	r16, 0
	lwz		r17, Queue.ReservePtr(r31)
	beq		@no_notr

;use notr
	mr.		r8, r17
	lwz		r17, Message.LLL + LLL.Next(r17)
	beq		@fail_insufficient_resources
	stw		r17, Queue.ReservePtr(r31)
	b		@queue_common

@no_notr ; ... allocate message anew
	li		r8, Message.Size
	bl		PoolAlloc
	cmpwi	r8, 0
	beq		@fail_unknown_err

@queue_common
	lwz		r16, Notification.MsgWord1(r30)
	lwz		r17, Notification.MsgWord2(r30)
	lwz		r18, Notification.MsgWord3(r30)
	stw		r16, Message.Word1(r8)
	stw		r17, Message.Word2(r8)
	stw		r18, Message.Word3(r8)
	bl		EnqueueMessage		; Message *r8, Queue *r31
@NO_QUEUE


	;	SIGNAL SEMAPHORE

	lwz		r8, Notification.SemaphoreID(r30)
	cmplwi	r8, 0
	beq		@NO_SEMAPHORE
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass
	mr		r31, r8
	bne		@fail_invalid_id

	bl		SignalSemaphore
@NO_SEMAPHORE


	;	SET EVENT

	lwz		r8, Notification.EventGroupID(r30)
	cmplwi	r8, 0
	beq		@NO_EVENT_GROUP
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	mr		r31, r8
	bne		@fail_invalid_id

	lwz		r8, Notification.EventFlags(r30)
	bl		SetEvent
@NO_EVENT_GROUP ; ... fall thru to success


@succeed
	mtlr	r29
	li		r8,  0x00
	blr

@fail_unknown_err
	mtlr	r29
	li		r8, -29294
	blr

@fail_insufficient_resources
	mtlr	r29
	li		r8, kMPInsufficientResourcesErr
	blr

@fail_invalid_id
	mtlr	r29
	li		r8, kMPInvalidIDErr
	blr



 #######   #######     ##    ##    ##     ##  #######  ########  #### ######## ##    ## 
##     ## ##     ##    ###   ##    ###   ### ##     ## ##     ##  ##  ##        ##  ##  
##        ##           ####  ##    #### #### ##     ## ##     ##  ##  ##         ####   
########  ########     ## ## ##    ## ### ## ##     ## ##     ##  ##  ######      ##    
##     ## ##     ##    ##  ####    ##     ## ##     ## ##     ##  ##  ##          ##    
##     ## ##     ##    ##   ###    ##     ## ##     ## ##     ##  ##  ##          ##    
 #######   #######     ##    ##    ##     ##  #######  ########  #### ##          ##    

	DeclareMPCall	66, MPModifyNotification

MPModifyNotification

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r4

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	cmpwi	cr2, r9,  0x04
	beq		MPCall_66_0x74
	cmpwi	r9,  0x09
	beq		cr2, MPCall_66_0x58
	bne		ReleaseAndReturnMPCallInvalidIDErr
	stw		r4,  0x001c(r31)
	stw		r5,  0x0020(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_66_0x58
	stw		r4,  0x000c(r31)
	lwz		r16,  ContextBlock.r6(r6)
	lwz		r17,  ContextBlock.r7(r6)
	stw		r5,  0x0010(r31)
	stw		r16,  0x0014(r31)
	stw		r17,  0x0018(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_66_0x74
	stw		r4,  0x0024(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



   ##    #######   #######     ##    ##    ##     ##  #######  ########  ########     ###    ########     ###    ##     ##  ######  
 ####   ##     ## ##     ##    ###   ##    ###   ### ##     ## ##     ## ##     ##   ## ##   ##     ##   ## ##   ###   ### ##    ## 
   ##          ## ##     ##    ####  ##    #### #### ##     ## ##     ## ##     ##  ##   ##  ##     ##  ##   ##  #### #### ##       
   ##    #######   #######     ## ## ##    ## ### ## ##     ## ##     ## ########  ##     ## ########  ##     ## ## ### ##  ######  
   ##   ##        ##     ##    ##  ####    ##     ## ##     ## ##     ## ##        ######### ##   ##   ######### ##     ##       ## 
   ##   ##        ##     ##    ##   ###    ##     ## ##     ## ##     ## ##        ##     ## ##    ##  ##     ## ##     ## ##    ## 
 ###### #########  #######     ##    ##    ##     ##  #######  ########  ##        ##     ## ##     ## ##     ## ##     ##  ######  

	DeclareMPCall	128, MPCall_128

MPCall_128	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	cmpwi	r4,  0x04
	cmpwi	cr1, r4,  0x09
	beq		MPCall_128_0x40
	beq		cr1, MPCall_128_0x58
	b		ReleaseAndReturnParamErrFromMPCall

MPCall_128_0x40
	lwz		r16,  ContextBlock.r6(r6)
	lwz		r17,  ContextBlock.r7(r6)
	stw		r5,  0x0010(r31)
	stw		r16,  0x0014(r31)
	stw		r17,  0x0018(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_128_0x58
	stw		r5,  0x0020(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall









  ### ########  ##     ## ##    ##    ########  ##       ##     ## ######## ###   
 ##   ##     ## ##     ## ###   ##    ##     ## ##       ##     ## ##         ##  
##    ##     ## ##     ## ####  ##    ##     ## ##       ##     ## ##          ## 
##    ########  ##     ## ## ## ##    ########  ##       ##     ## ######      ## 
##    ##   ##   ##     ## ##  ####    ##     ## ##       ##     ## ##          ## 
 ##   ##    ##  ##     ## ##   ###    ##     ## ##       ##     ## ##         ##  
  ### ##     ##  #######  ##    ##    ########  ########  #######  ######## ###   

;	ARG		OpaqueID r8

;	MP calls by blue return kMPBlueBlockingErr instead of blocking,
;	in order to maintain system responsiveness. Blue might poll these
;	calls, e.g. at SysTask time. This function, called when a
;	blocking object becomes "available", unblocks blue to give it
;	 another shot.

UnblockBlueIfCouldBePolling

	lwz		r9, PSA.BlueSpinningOn(r1)
	lwz		r19, PSA.PA_BlueTask(r1)
	cmpw	r8, r9
	bnelr

	li		r9, -1
	mflr	r24
	stw		r9, PSA.BlueSpinningOn(r1)

	lbz		r17, Task.State(r19)
	cmpwi	r17, 0

	addi	r16, r19, Task.QueueMember
	bne		@blue_already_running

	RemoveFromList		r16, scratch1=r17, scratch2=r18

	lbz		r17, Task.Timer + Timer.Byte3(r19)
	cmpwi	r17, 1
	bne		@no_timer_to_dequeue
	addi	r8, r19, Task.Timer
	bl		DequeueTimer
	lwz		r19, PSA.PA_BlueTask(r1)
@no_timer_to_dequeue

	li		r16, Task.kLatencyProtectPriority
	stb		r16, Task.Priority(r19)
	lwz		r8, PSA.PA_BlueTask(r1)
	bl		SchRdyTaskNow
@blue_already_running

	lwz		r8, PSA.PA_BlueTask(r1)
	mtlr	r24
	b		FlagSchEvaluationIfTaskRequires









   ##    #######    #####      ########  ####  ######       ######     ###    ##       ##       
 ####   ##     ##  ##   ##     ##     ##  ##  ##    ##     ##    ##   ## ##   ##       ##       
   ##          ## ##     ##    ##     ##  ##  ##           ##        ##   ##  ##       ##       
   ##    #######  ##     ##    ########   ##  ##   ####    ##       ##     ## ##       ##       
   ##   ##        ##     ##    ##     ##  ##  ##    ##     ##       ######### ##       ##       
   ##   ##         ##   ##     ##     ##  ##  ##    ##     ##    ## ##     ## ##       ##       
 ###### #########   #####      ########  ####  ######       ######  ##     ## ######## ######## 

	DeclareMPCall	120, MPCall_120

MPCall_120

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
	bl		LookupID
	mr		r31, r8

	cmpwi	r9, Semaphore.kIDClass
	cmpwi	cr1, r9, Queue.kIDClass
	beq		@SEMAPHORE
	beq		cr1, @QUEUE

	cmpwi	r9, EventGroup.kIDClass
	cmpwi	cr1, r9, CriticalRegion.kIDClass
	beq		@EVENT_GROUP
	beq		cr1, @CRITICAL_REGION

	cmpwi	r9, Notification.kIDClass
	cmpwi	cr1, r9, AddressSpace.kIDClass
	beq		@NOTIFICATION
	beq		cr1, @ADDRESS_SPACE

	b		ReleaseAndReturnParamErrFromMPCall

@NOTIFICATION
	lisori	r8, Notification.kFirstID
	cmpw	r8, r4
	bne		ReleaseAndReturnParamErrFromMPCall

	cmplwi	r5, 0
	bne		@notification_not_0

	;	r5 == 0
	lisori	r16, Notification.kFirstID

	stw		r16, ContextBlock.r6(r6)
	lwz		r16, Notification.ProcessID(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, Notification.Signature(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x000c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 16
	stw		r16, ContextBlock.r10(r6)

	b		ReleaseAndReturnZeroFromMPCall

@notification_not_0
	cmplwi	r5, 16
	bne		@notification_not_16

	;	r5 == 16
	lwz		r16, 0x0010(r31)
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0014(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0018(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x001c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 16
	stw		r16, ContextBlock.r10(r6)

	b		ReleaseAndReturnZeroFromMPCall

@notification_not_16

	cmplwi	r5, 32
	bne		@notification_not_32

	;	r5 == 32
	lwz		r16, 0x0020(r31)
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0024(r31)
	stw		r16, ContextBlock.r7(r6)
	li		r16, 8
	stw		r16, ContextBlock.r10(r6)

	b		ReleaseAndReturnZeroFromMPCall

@notification_not_32
	cmpwi	r5, 40
	bne		ReleaseAndReturnParamErrFromMPCall

	;	r5 == 40
	li		r16, 0x00
	stw		r16, ContextBlock.r10(r6)

	b		ReleaseAndReturnZeroFromMPCall


@CRITICAL_REGION
	lisori	r8, 0x00060001
	cmpw	r8, r4
	bne		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5, 0x00
	bne		@154
	lis		r16, 0x06
	ori		r16, r16, 0x01
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0010(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0004(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x0020(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@154
	cmplwi	r5, 0x10
	bne		@1a0
	addi	r17, r31, 0x00
	lwz		r18, 0x0008(r31)
	li		r16, 0x00
	cmpw	r17, r18
	beq		@174
	lwz		r16, -0x0008(r18)

@174
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0018(r31)
	cmpwi	r16, 0x00
	beq		@188
	lwz		r16, 0x0000(r16)

@188
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0014(r31)
	stw		r16, ContextBlock.r8(r6)
	li		r16, 0x0c
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@1a0
	cmpwi	r5, 0x1c
	bne		ReleaseAndReturnParamErrFromMPCall
	li		r16, 0x00
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@EVENT_GROUP
	lis		r8, 0x09
	ori		r8, r8, 0x01
	cmpw	r8, r4
	bne		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5, 0x00
	bne		@1fc
	lis		r16, 0x09
	ori		r16, r16, 0x01
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0014(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0004(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x001c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@1fc
	cmplwi	r5, 0x10
	bne		@234
	addi	r17, r31, 0x00
	lwz		r18, 0x0008(r31)
	li		r16, 0x00
	cmpw	r17, r18
	beq		@21c
	lwz		r16, -0x0008(r18)

@21c
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0010(r31)
	stw		r16, ContextBlock.r7(r6)
	li		r16, 0x08
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@234
	cmpwi	r5, 0x18
	bne		ReleaseAndReturnParamErrFromMPCall
	li		r16, 0x00
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@QUEUE
	lis		r8, 0x04
	ori		r8, r8, 0x01
	cmpw	r8, r4
	bne		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5, 0x00
	bne		@290
	lis		r16, 0x04
	ori		r16, r16, 0x01
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0020(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0004(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x002c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@290
	cmplwi	r5, 0x10
	bne		@2ec
	addi	r17, r31, 0x00
	lwz		r18, 0x0008(r31)
	li		r16, 0x00
	cmpw	r17, r18
	beq		@2b0
	lwz		r16, -0x0008(r18)

@2b0
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0030(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0024(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r18, 0x0018(r31)
	addi	r17, r31, 0x10
	li		r16, 0x00
	cmpw	r17, r18
	beq		@2dc
	lwz		r16, 0x0010(r18)

@2dc
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@2ec
	cmplwi	r5, 0x20
	bne		@328
	lwz		r18, 0x0018(r31)
	addi	r17, r31, 0x10
	li		r16, 0x00
	cmpw	r17, r18
	li		r17, 0x00
	beq		@314
	lwz		r16, 0x0014(r18)
	lwz		r17, 0x0018(r18)

@314
	stw		r16, ContextBlock.r6(r6)
	stw		r17, ContextBlock.r7(r6)
	li		r16, 0x08
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@328
	cmpwi	r5, 0x28
	bne		ReleaseAndReturnParamErrFromMPCall
	li		r16, 0x00
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@SEMAPHORE
	lis		r8, 0x05
	ori		r8, r8, 0x01
	cmpw	r8, r4
	bne		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5, 0x00
	bne		@384
	lis		r16, 0x05
	ori		r16, r16, 0x01
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0018(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0004(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x001c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@384
	cmplwi	r5, 0x10
	bne		@3c4
	addi	r17, r31, 0x00
	lwz		r18, 0x0008(r31)
	li		r16, 0x00
	cmpw	r17, r18
	beq		@3a4
	lwz		r16, -0x0008(r18)

@3a4
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0014(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0010(r31)
	stw		r16, ContextBlock.r8(r6)
	li		r16, 0x0c
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@3c4
	cmpwi	r5, 0x1c
	bne		ReleaseAndReturnParamErrFromMPCall
	li		r16, 0x00
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@ADDRESS_SPACE
	lisori	r8, 0x00080001
	cmpw	r8, r4
	bne		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5, 0x00
	bne		@420
	lisori	r16, 0x00080001
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0074(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0070(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x000c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@420
	cmplwi	r5, 0x10
	bne		@454
	lwz		r16, 0x0030(r31)
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0034(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0038(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x003c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@454
	cmplwi	r5, 0x20
	bne		@488
	lwz		r16, 0x0040(r31)
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0044(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0048(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x004c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@488
	cmplwi	r5, 0x30
	bne		@4bc
	lwz		r16, 0x0050(r31)
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0054(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0058(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x005c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@4bc
	cmplwi	r5, 0x40
	bne		@4f0
	lwz		r16, 0x0060(r31)
	stw		r16, ContextBlock.r6(r6)
	lwz		r16, 0x0064(r31)
	stw		r16, ContextBlock.r7(r6)
	lwz		r16, 0x0068(r31)
	stw		r16, ContextBlock.r8(r6)
	lwz		r16, 0x006c(r31)
	stw		r16, ContextBlock.r9(r6)
	li		r16, 0x10
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@4f0
	cmpwi	r5, 0x50
	bne		ReleaseAndReturnParamErrFromMPCall
	li		r16, 0x00
	stw		r16, ContextBlock.r10(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall
