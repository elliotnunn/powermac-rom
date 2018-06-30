;_______________________________________________________________________
;	NanoKernel Opaque ID Index
;
;	Creates opaque structure IDs and stores them in the Pool. An opaque
;	ID maps back to the (type, pointer) pair passed to MakeID.
;
;	This abstraction is very important to the Multiprocessing Services.
;
;	Rene on comp.sys.mac.programmer.help, 26 Oct 01:
;
;	Total opaque IDs - The number of IDs currently in use. All MP
;	objects: address spaces, areas, processors, memory coherence groups,
;	queues, semaphores, critical regions, event groups, timers,
;	notifications, etc. are assigned an ID when created, and they are
;	accessed by way of this ID. The kernel presently handles 65,000
;	simultaneous IDs with a bit pattern reuse probability of 1 in 4
;	billion.
;
;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKPoolAllocator
;	    PoolAllocClear
;	  NKThud
;	    panic
;	EXPORTS:
;	  DeleteID (=> NKAddressSpaces, NKMPCalls, NKSync, NKTasks, NKTimers)
;	  GetNextIDOfClass (=> NKAddressSpaces, NKMPCalls, NKThud)
;	  InitIDIndex (=> NKInit)
;	  LookupID (=> NKAddressSpaces, NKInterrupts, NKMPCalls, NKPrimaryIntHandlers, NKSync, NKTasks, NKThud, NKTimers)
;	  MakeID (=> NKAddressSpaces, NKInit, NKMPCalls, NKSync, NKTasks)
;_______________________________________________________________________

Local_Panic		set		*
				b		panic



;	ARG		KDP *r1

InitIDIndex
	mflr	r23

	li		r8, Index.Size
	bl		PoolAllocClear

	mr.		r22, r8
	stw		r8, PSA.IndexPtr(r1)
	beq		Local_Panic

	li		r9,  0
	stw		r9,  KDP.NanoKernelInfo + NKNanoKernelInfo.IDCtr(r1)

	sth		r9, Index.HalfOne(r22)
	sth		r9, Index.HalfTwo(r22)

	lisori	r9, Index.kSignature
	stw		r9, Index.Signature(r22)


	;	Then what the hell is this?
	li		r8,  0xfd8
	bl		PoolAllocClear

	cmpwi	r8,  0
	stw		r8, Index.IDsPtr(r22)
	beq		Local_Panic

	mtlr	r23

	li		r9,  0x00
	sth		r9,  0x0000(r8)
	li		r9,  0x1fa
	sth		r9,  0x0002(r8)
	lisori	r9, 'IDs '
	stw		r9,  0x0004(r8)
	blr



;	ARG		void *r8, IDClass r9
;	RET		ID r8

MakeID
	lwz		r18, PSA.IndexPtr(r1)
	lhz		r19,  0x0000(r18)
	mr		r21, r19

@_c
	lwz		r18, PSA.IndexPtr(r1)
	rlwinm	r20, r19, 25, 23, 29
	addi	r20, r20,  0x08
	clrlwi.	r19, r19,  0x17
	lwzx	r18, r18, r20
	slwi	r22, r19,  3
	addi	r20, r18,  0x08
	cmpwi	r18,  0x00
	add		r22, r22, r20
	bne		@_48
	li		r19,  0x00
	b		@_c

@_3c
	add		r20, r20, r19
	cmpw	r20, r21
	beq		@_70

@_48
	lbz		r23,  0x0000(r22)
	cmpwi	r23,  0x00
	beq		@_f0
	addi	r19, r19,  0x01
	cmpwi	cr1, r19,  0x1fa
	addi	r22, r22,  0x08
	lhz		r20,  0x0000(r18)
	blt		cr1, @_3c
	addi	r19, r20,  0x200
	b		@_c

@_70
	lwz		r18, PSA.IndexPtr(r1)
	mr		r21, r8
	lhz		r19,  0x0002(r18)
	mr		r22, r9
	addi	r19, r19,  0x200
	rlwinm.	r20, r19, 25, 23, 29
	li		r8,  0x00
	beqlr
	mflr	r23
	li		r8,  0xfd8

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	mr.		r18, r8
	mtlr	r23
	li		r8,  0x00
	beqlr
	lwz		r17, PSA.IndexPtr(r1)
	lhz		r19,  0x0002(r17)
	addi	r19, r19,  0x200
	rlwinm	r20, r19, 25, 23, 29
	addi	r20, r20,  0x08
	sth		r19,  0x0002(r17)
	stwx	r18, r20, r17
	sth		r19,  0x0000(r18)
	li		r9,  0x1fa
	sth		r9,  0x0002(r18)
	lis		r9,  0x4944
	ori		r9, r9,  0x7320
	stw		r9,  0x0004(r18)
	li		r19,  0x00
	mr		r8, r21
	mr		r9, r22
	addi	r22, r18,  0x08

@_f0
	stw		r8,  0x0004(r22)
	stb		r9,  0x0000(r22)
	lwz		r9,  KDP.NanoKernelInfo + NKNanoKernelInfo.IDCtr(r1)
	addi	r9, r9,  0x01
	stw		r9,  KDP.NanoKernelInfo + NKNanoKernelInfo.IDCtr(r1)
	lhz		r20,  0x0000(r18)
	lhz		r8,  0x0002(r22)
	lwz		r21, PSA.IndexPtr(r1)
	add		r19, r19, r20
	addi	r8, r8,  0x01
	lhz		r20,  0x0002(r18)
	sth		r8,  0x0002(r22)
	addi	r20, r20, -0x01
	rlwimi.	r8, r19, 16,  0, 15
	sth		r20,  0x0002(r18)
	sth		r19,  0x0000(r21)
	bnelr+
	lhz		r8,  0x0002(r22)
	addi	r8, r8,  0x01
	sth		r8,  0x0002(r22)
	rlwimi	r8, r19, 16,  0, 15
	blr



;	ARG		ID r8

	align	5

DeleteID
	rlwinm	r20, r8,  9, 23, 29
	lwz		r18, PSA.IndexPtr(r1)
	addi	r20, r20,  0x08
	rlwinm.	r19, r8, 16, 23, 31
	lwzx	r18, r18, r20
	cmplwi	cr1, r19,  0x1fa
	cmpwi	r18,  0x00
	addi	r20, r18,  0x08
	slwi	r22, r19,  3
	add		r22, r22, r20
	clrlwi	r20, r8,  0x10
	li		r8,  0x00
	bgelr	cr1
	beqlr
	lbz		r19,  0x0000(r22)
	lhz		r23,  0x0002(r22)
	cmpwi	r19,  0x00
	cmpw	cr1, r23, r20
	beqlr
	bnelr	cr1
	lwz		r9,  KDP.NanoKernelInfo + NKNanoKernelInfo.IDCtr(r1)
	addi	r9, r9, -0x01
	stw		r9,  KDP.NanoKernelInfo + NKNanoKernelInfo.IDCtr(r1)
	lhz		r20,  0x0002(r18)
	stb		r8,  0x0000(r22)
	addi	r20, r20,  0x01
	li		r8,  0x01
	sth		r20,  0x0002(r18)
	blr



;	ARG		ID r8
;	RET		Ptr r8, IDClass r9

	align	5

LookupID
	rlwinm	r20, r8,  9, 23, 29
	lwz		r18, PSA.IndexPtr(r1)
	addi	r20, r20,  0x08
	rlwinm.	r19, r8, 16, 23, 31
	lwzx	r18, r18, r20
	cmplwi	cr1, r19,  0x1fa
	cmpwi	r18,  0x00
	addi	r20, r18,  0x08
	slwi	r22, r19,  3
	add		r22, r22, r20
	clrlwi	r20, r8,  0x10
	li		r8,  0x00
	li		r9,  0x00
	bgelr	cr1
	beqlr
	lbz		r19,  0x0000(r22)
	lhz		r23,  0x0002(r22)
	cmpwi	r19,  0x00
	cmpw	cr1, r23, r20
	beqlr
	bnelr	cr1
	lwz		r8,  0x0004(r22)
	mr		r9, r19
	blr



;	ARG		ID r8, IDClass r9
;	RET		ID r8

	align	5

GetNextIDOfClass
	rlwinm	r20, r8,  9, 23, 29
	lwz		r18, PSA.IndexPtr(r1)
	addi	r20, r20,  0x08
	rlwinm.	r19, r8, 16, 23, 31
	lwzx	r18, r18, r20
	cmplwi	cr1, r19,  0x1fa
	cmpwi	r18,  0x00
	cmpwi	cr2, r8,  0x00
	addi	r20, r18,  0x08
	slwi	r22, r19,  3
	li		r8,  0x00
	bgelr	cr1
	beqlr
	add		r22, r22, r20
	bne		cr2, @_48

@_3c
	lbz		r23,  0x0000(r22)
	cmpwi	r23,  0x00
	bne		@_8c

@_48
	addi	r19, r19,  0x01
	cmpwi	r19,  0x1fa
	addi	r22, r22,  0x08
	blt		@_3c
	lhz		r20,  0x0000(r18)
	addi	r20, r20,  0x200
	rlwinm.	r20, r20, 25, 23, 29
	lwz		r18, PSA.IndexPtr(r1)
	beqlr
	addi	r20, r20,  0x08
	li		r19,  0x00
	lwzx	r18, r18, r20
	cmpwi	r18,  0x00
	addi	r22, r18,  0x08
	bne		@_3c
	li		r8,  0x00
	blr

@_8c
	cmpwi	r9,  0x00
	cmpw	cr1, r9, r23
	beq		@_9c
	bne		cr1, @_48

@_9c
	lhz		r20,  0x0000(r18)
	lhz		r8,  0x0002(r22)
	add		r19, r19, r20
	rlwimi	r8, r19, 16,  0, 15
	blr
