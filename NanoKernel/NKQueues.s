	DeclareMPCall	15, MPCall_15

MPCall_15	;	OUTSIDE REFERER
	li		r8,  0x34
	bl		PoolAlloc_with_crset
	mr.		r31, r8
	beq+	major_0x0af60_0x20
	lis		r16, 'MS'
	stw		r8,  0x0008(r8)
	ori		r16, r16, 'GQ'
	stw		r8,  0x000c(r8)
	stw		r16,  0x0004(r8)
	addi	r9, r8,  0x10
	lis		r16,  'NO'
	stw		r9,  0x0008(r9)
	ori		r16, r16,  'TQ'
	stw		r9,  0x000c(r9)
	stw		r16,  0x0004(r9)

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9,  0x04

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne+	MPCall_15_0x70
	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60

MPCall_15_0x70
	mfsprg	r30, 0
	lwz		r30, -0x0008(r30)
	stw		r8,  0x0000(r31)
	lwz		r17,  0x0060(r30)
	stw		r17,  0x0020(r31)
	mr		r4, r8
	li		r17,  0x00
	stw		r17,  0x0024(r31)
	stw		r17,  0x0028(r31)
	stw		r17,  0x002c(r31)
	stw		r17,  0x0030(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	16, MPCall_16

MPCall_16	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr

MPCall_16_0x2c
	addi	r30, r31,  0x10
	lwz		r8,  0x0018(r31)
	cmpw	r8, r30
	beq-	MPCall_16_0x60
	RemoveFromList		r8, scratch1=r16, scratch2=r17
	bl		PoolFree
	b		MPCall_16_0x2c

MPCall_16_0x60
	lwz		r30,  0x0028(r31)

MPCall_16_0x64
	mr.		r8, r30
	beq-	MPCall_16_0x78
	lwz		r30,  0x0008(r30)
	bl		PoolFree
	b		MPCall_16_0x64

MPCall_16_0x78
	mr		r8, r3
	bl		major_0x0dce8

MPCall_16_0x80
	addi	r30, r31,  0x00
	lwz		r16,  0x0008(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq-	MPCall_16_0xe4
	lwz		r17,  0x0088(r8)
	li		r18, -0x726f
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	MPCall_16_0xb4
	addi	r8, r8,  0x20
	bl		major_0x136c8

MPCall_16_0xb4
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		TaskReadyAsPrev
	bl		major_0x14af8
	b		MPCall_16_0x80

MPCall_16_0xe4
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	39, MPCall_39

MPCall_39	;	OUTSIDE REFERER
	cmpwi	r4,  0x00
	blt+	ReturnMPCallOOM

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r29,  0x0024(r31)
	lwz		r30,  0x0028(r31)
	cmpw	r29, r4

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	blt-	MPCall_39_0x7c

MPCall_39_0x48
	mr.		r8, r30
	beq-	MPCall_39_0x70
	addi	r29, r29, -0x01
	lwz		r30,  0x0008(r30)
	bl		PoolFree
	cmpw	r29, r4
	bgt+	MPCall_39_0x48
	stw		r4,  0x0024(r31)
	stw		r30,  0x0028(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_39_0x70
	stw		r29,  0x0024(r31)
	stw		r30,  0x0028(r31)
	b		ReleaseAndReturnMPCallOOM

MPCall_39_0x7c
	li		r8,  0x1c
	bl		PoolAlloc_with_crset
	cmpwi	r8,  0x00
	beq+	major_0x0af60
	addi	r29, r29,  0x01
	lis		r17,  0x6e6f
	ori		r17, r17,  0x7472
	stw		r17,  0x0004(r8)
	stw		r30,  0x0008(r8)
	stw		r29,  0x0024(r31)
	cmpw	r29, r4
	stw		r8,  0x0028(r31)
	mr		r30, r8
	blt+	MPCall_39_0x7c

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	17, MPCall_17

MPCall_17	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  0x0024(r31)
	li		r8,  0x1c
	cmpwi	r16,  0x00
	bne-	MPCall_17_0x58
	bl		PoolAlloc_with_crset
	cmpwi	r8,  0x00
	beq+	major_0x0af60
	lis		r17,  0x6e6f
	ori		r17, r17,  0x7465
	stw		r17,  0x0004(r8)
	b		MPCall_17_0x6c

MPCall_17_0x58
	lwz		r17,  0x0028(r31)
	mr.		r8, r17
	beq+	ReleaseAndReturnMPCallOOM
	lwz		r17,  0x0008(r17)
	stw		r17,  0x0028(r31)

MPCall_17_0x6c
	lwz		r16,  0x0134(r6)
	stw		r4,  0x0010(r8)
	stw		r5,  0x0014(r8)
	stw		r16,  0x0018(r8)
	bl		major_0x0c8b4

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     major_0x0c8b4

;	Xrefs:
;	major_0x02ccc
;	MPCall_17
;	major_0x0db04
;	MPCall_9
;	MPCall_58

major_0x0c8b4	;	OUTSIDE REFERER
	addi	r17, r31,  0x10
	stw		r17,  0x0000(r8)
	InsertAsPrev	r8, r17, scratch=r16
	lwz		r18,  0x0030(r31)
	addi	r18, r18,  0x01
	stw		r18,  0x0030(r31)
	mflr	r27
	lwz		r8,  0x0000(r31)
	bl		major_0x0dce8
	lwz		r16,  0x0008(r31)
	cmpw	r16, r31
	addi	r8, r16, -0x08
	beq-	major_0x0c8b4_0xac
	lwz		r17,  0x0088(r8)
	lwz		r18,  0x00fc(r17)
	subi	r18, r18, 4
	stw		r18,  0x00fc(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	major_0x0c8b4_0x68
	addi	r8, r8,  0x20
	bl		major_0x136c8

major_0x0c8b4_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18,  0x002c(r31)
	addi	r18, r18, -0x01
	stw		r18,  0x002c(r31)
	addi	r8, r16, -0x08
	li		r17,  0x01
	stb		r17,  0x0019(r8)
	bl		TaskReadyAsPrev
	bl		CalculateTimeslice
	bl		major_0x14af8

major_0x0c8b4_0xac
	mtlr	r27
	blr



	DeclareMPCall	18, MPCall_18

MPCall_18	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16,  0x0018(r31)
	addi	r17, r31,  0x10
	cmpw	r16, r17
	beq-	MPCall_18_0x9c
	lwz		r4,  0x0010(r16)
	lwz		r5,  0x0014(r16)
	lwz		r17,  0x0018(r16)
	stw		r17,  0x0134(r6)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18,  0x0030(r31)
	addi	r18, r18, -0x01
	stw		r18,  0x0030(r31)
	lbz		r17,  0x0007(r16)
	mr		r8, r16
	cmpwi	r17,  0x72
	beq-	MPCall_18_0x8c
	bl		PoolFree

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_18_0x8c
	lwz		r17,  0x0028(r31)
	stw		r16,  0x0028(r31)
	stw		r17,  0x0008(r16)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_18_0x9c
	lwz		r17,  0x013c(r6)
	mfsprg	r30, 0
	cmpwi	r17,  0x00
	lwz		r19, -0x0008(r30)
	beq+	ReleaseAndTimeoutMPCall
	lwz		r16,  0x0064(r19)
	rlwinm.	r16, r16,  0, 15, 15
	beq-	MPCall_18_0xc4
	stw		r3, -0x0410(r1)
	b		ReleaseAndReturnMPCallBlueBlocking

MPCall_18_0xc4
	mr		r8, r19
	bl		DequeueTask
	lwz		r19, -0x0008(r30)
	addi	r16, r31,  0x00
	addi	r17, r19,  0x08
	stw		r16,  0x0000(r17)
	InsertAsPrev	r17, r16, scratch=r18
	lwz		r18,  0x002c(r31)
	addi	r18, r18,  0x01
	stw		r18,  0x002c(r31)
	lis		r16,  0x7fff
	lwz		r17,  0x013c(r6)
	ori		r16, r16,  0xffff
	addi	r30, r19,  0x20
	cmpw	r17, r16
	li		r16,  0x02
	beq-	MPCall_18_0x154
	stb		r16,  0x0014(r30)
	stw		r19,  0x0018(r30)
	mr		r8, r17

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
	stw		r8,  0x0038(r30)
	stw		r9,  0x003c(r30)
	mr		r8, r30
	bl		EnqueueTimer

MPCall_18_0x154
	b		AlternateMPCallReturnPath



	DeclareMPCall	19, MPCall_19

MPCall_19	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16,  0x0018(r31)
	addi	r17, r31,  0x10
	cmpw	r16, r17
	beq+	ReleaseAndTimeoutMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	20, MPCall_20

MPCall_20	;	OUTSIDE REFERER
	cmpw	r4, r3
	bgt+	ReturnMPCallOOM
	li		r8,  0x20
	bl		PoolAlloc_with_crset
	mr.		r31, r8
	beq+	major_0x0af60_0x20
	InitList	r31, Semaphore.kSignature, scratch=r16

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9,  0x05

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne+	MPCall_20_0x60
	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60

MPCall_20_0x60
	li		r18,  0x00
	stw		r8,  0x0000(r31)
	mfsprg	r30, 0
	lwz		r30, -0x0008(r30)
	stw		r3,  0x0014(r31)
	stw		r4,  0x0010(r31)
	lwz		r17,  0x0060(r30)
	stw		r18,  0x001c(r31)
	stw		r17,  0x0018(r31)
	mr		r5, r8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	23, MPCall_23

MPCall_23	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16,  0x0010(r31)
	cmpwi	r16,  0x00
	addi	r16, r16, -0x01
	ble-	MPCall_23_0x44
	stw		r16,  0x0010(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_23_0x44
	cmpwi	r4,  0x00
	mfsprg	r30, 0
	beq+	ReleaseAndTimeoutMPCall
	lwz		r8, -0x0008(r30)
	lwz		r16,  0x0064(r8)
	rlwinm.	r16, r16,  0, 15, 15
	beq-	MPCall_23_0x68
	stw		r3, -0x0410(r1)
	b		ReleaseAndReturnMPCallBlueBlocking

MPCall_23_0x68
	bl		DequeueTask
	addi	r16, r31,  0x00
	addi	r17, r8,  0x08
	stw		r16,  0x0000(r17)
	InsertAsPrev	r17, r16, scratch=r18
	lwz		r18,  0x001c(r31)
	addi	r18, r18,  0x01
	stw		r18,  0x001c(r31)
	lis		r16,  0x7fff
	addi	r30, r8,  0x20
	ori		r16, r16,  0xffff
	cmpw	r4, r16
	li		r17,  0x02
	beq-	MPCall_23_0xec
	stb		r17,  0x0014(r30)
	stw		r8,  0x0018(r30)
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
	stw		r8,  0x0038(r30)
	stw		r9,  0x003c(r30)
	mr		r8, r30
	bl		EnqueueTimer

MPCall_23_0xec
	li		r3,  0x00
	b		AlternateMPCallReturnPath



	DeclareMPCall	24, MPCall_24

MPCall_24	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16,  0x0010(r31)
	cmpwi	r16,  0x00
	ble+	ReleaseAndTimeoutMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	22, MPCall_22

MPCall_22	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	bl		major_0x0ccf4
	mr		r3, r8
	b		ReleaseAndReturnMPCall



;	                     major_0x0ccf4

;	Xrefs:
;	MPCall_22
;	major_0x0db04

major_0x0ccf4	;	OUTSIDE REFERER
	mflr	r27
	lwz		r8,  0x0000(r31)
	bl		major_0x0dce8
	lwz		r16,  0x0008(r31)
	cmpw	r16, r31
	beq-	major_0x0ccf4_0x80
	addi	r8, r16, -0x08
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	major_0x0ccf4_0x30
	addi	r8, r8,  0x20
	bl		major_0x136c8

major_0x0ccf4_0x30
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18,  0x001c(r31)
	addi	r18, r18, -0x01
	stw		r18,  0x001c(r31)
	addi	r8, r16, -0x08
	li		r17,  0x01
	stb		r17,  0x0019(r8)
	bl		TaskReadyAsPrev
	bl		CalculateTimeslice
	bl		major_0x14af8
	mtlr	r27
	li		r8,  0x00
	blr

major_0x0ccf4_0x80
	mtlr	r27
	lwz		r16,  0x0010(r31)
	lwz		r17,  0x0014(r31)
	cmpw	r16, r17
	addi	r16, r16,  0x01
	li		r8, -0x7272
	bgelr-
	stw		r16,  0x0010(r31)
	li		r8,  0x00
	blr



	DeclareMPCall	21, MPCall_21

MPCall_21	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r3
	bl		major_0x0dce8

MPCall_21_0x34
	addi	r30, r31,  0x00
	lwz		r16,  0x0008(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq-	MPCall_21_0x98
	lwz		r17,  0x0088(r8)
	li		r18, -0x726f
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	MPCall_21_0x68
	addi	r8, r8,  0x20
	bl		major_0x136c8

MPCall_21_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		TaskReadyAsPrev
	bl		major_0x14af8
	b		MPCall_21_0x34

MPCall_21_0x98
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	25, MPCall_25

MPCall_25	;	OUTSIDE REFERER
	li		r8,  0x24
	bl		PoolAlloc_with_crset
	mr.		r31, r8
	beq+	major_0x0af60_0x20
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
	b		major_0x0af60

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



	DeclareMPCall	27, MPCall_27

MPCall_27	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mfsprg	r17, 0
	lwz		r18,  0x0014(r31)
	lwz		r30, -0x0008(r17)
	cmpwi	r18,  0x00
	lwz		r16,  0x0018(r31)
	beq-	MPCall_27_0x64
	lwz		r17,  0x001c(r31)
	cmpw	r16, r30
	cmpw	cr1, r17, r5
	bne-	MPCall_27_0x78
	bne-	cr1, MPCall_27_0x78
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

	bne+	ReleaseAndReturnMPCallTaskAborted
	lwz		r8,  0x001c(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Process.kIDClass

	bne+	ReleaseAndReturnMPCallTaskAborted
	cmpwi	r4,  0x00
	lwz		r16,  0x0064(r30)
	beq+	ReleaseAndTimeoutMPCall
	rlwinm.	r16, r16,  0, 15, 15
	beq-	MPCall_27_0xb4
	stw		r3, -0x0410(r1)
	b		ReleaseAndReturnMPCallBlueBlocking

MPCall_27_0xb4
	mr		r8, r30
	bl		DequeueTask
	lis		r16,  0x7fff
	addi	r18, r30,  0x08
	ori		r16, r16,  0xffff
	stw		r31,  0x0000(r18)
	InsertAsPrev	r18, r31, scratch=r19
	lwz		r18,  0x0020(r31)
	addi	r18, r18,  0x01
	stw		r18,  0x0020(r31)
	cmpw	r4, r16
	beq-	MPCall_27_0x138
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
	b		AlternateMPCallReturnPath



	DeclareMPCall	29, MPCall_29

MPCall_29	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mfsprg	r17, 0
	lwz		r18,  0x0014(r31)
	cmpwi	r18,  0x00

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	lwz		r30, -0x0008(r17)
	lwz		r16,  0x0018(r31)
	lwz		r17,  0x001c(r31)
	cmpw	r16, r30
	cmpw	cr1, r17, r4
	bne+	ReleaseAndTimeoutMPCall
	bne+	cr1, ReleaseAndTimeoutMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	28, MPCall_28

MPCall_28	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mfsprg	r17, 0
	lwz		r16,  0x0018(r31)
	lwz		r30, -0x0008(r17)
	lwz		r18,  0x0014(r31)
	lwz		r17,  0x001c(r31)
	cmpw	r16, r30
	cmpw	cr1, r17, r4
	bne+	ReleaseAndReturnMPCallOOM
	bne+	cr1, ReleaseAndReturnMPCallOOM
	addi	r18, r18, -0x01
	cmpwi	r18,  0x00
	stw		r18,  0x0014(r31)

;	r1 = kdp
	bne+	ReleaseAndReturnZeroFromMPCall
	stw		r18,  0x0018(r31)
	stw		r18,  0x001c(r31)
	mr		r8, r3
	bl		major_0x0dce8
	lwz		r16,  0x0008(r31)
	cmpw	r16, r31

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	addi	r8, r16, -0x08
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	MPCall_28_0x94
	addi	r8, r8,  0x20
	bl		major_0x136c8

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
	bl		TaskReadyAsPrev
	bl		CalculateTimeslice
	bl		major_0x14af8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	26, MPCall_26

MPCall_26	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CriticalRegion.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r3
	bl		major_0x0dce8

MPCall_26_0x34
	addi	r30, r31,  0x00
	lwz		r16,  0x0008(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq-	MPCall_26_0x98
	lwz		r17,  0x0088(r8)
	li		r18, -0x726f
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	MPCall_26_0x68
	addi	r8, r8,  0x20
	bl		major_0x136c8

MPCall_26_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		TaskReadyAsPrev
	bl		major_0x14af8
	b		MPCall_26_0x34

MPCall_26_0x98
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;_______________________________________________________________________
;	EVENT GROUP MP CALLS (49-54)
;
;	Corresponding with MPLibrary functions, although signatures differ
;
;	49*		MPCreateEvent
;	50		MPDeleteEvent
;	51		MPSetEvent
;	52*		MPWaitForEvent
;	53		MPQueryEvent
;	54*		MPSetSWIEvent
;	* also called using the FE1F trap by the 68k ROM
;
;	Lifted from docs:
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

	DeclareMPCall	49, MPCreateEvent

;	RET		OSStatus r3, MPEventID r4

MPCreateEvent

	li		r8, EventGroup.Size
	bl		PoolAlloc
	mr.		r31, r8
	beq+	major_0x0af60_0x20

	InitList	r8, EventGroup.kSignature, scratch=r16

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9, EventGroup.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	bne+	@success

	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60

@success
	mfsprg	r30, 0
	lwz		r30, EWA.PA_CurTask(r30)

	stw		r8, EventGroup.LLL + LLL.Freeform(r31)

	lwz		r17, Task.ProcessID(r30)
	stw		r17, EventGroup.ProcessID(r31)

	mr		r4, r8
	b		ReleaseAndReturnZeroFromMPCall



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
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	mr		r8, r3
	bl		major_0x0dce8

MPDeleteEvent_0x34
	addi	r30, r31,  0x00
	lwz		r16,  0x0008(r31)
	cmpw	r16, r30
	addi	r8, r16, -0x08
	beq-	MPDeleteEvent_0x98
	lwz		r17,  0x0088(r8)
	li		r18, -0x726f
	stw		r18,  0x011c(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	MPDeleteEvent_0x68
	addi	r8, r8,  0x20
	bl		major_0x136c8

MPDeleteEvent_0x68
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	addi	r8, r16, -0x08
	bl		TaskReadyAsPrev
	bl		major_0x14af8
	b		MPDeleteEvent_0x34

MPDeleteEvent_0x98
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	51, MPSetEvent

;	ARG		MPEventID r3, MPEventFlags r4
;	RET		OSStatus r3

MPSetEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	mr		r8, r4
	bl		major_0x0d35c

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     major_0x0d35c

;	Xrefs:
;	MPCall_51
;	major_0x0db04
;	MPCall_83

major_0x0d35c	;	OUTSIDE REFERER
	lwz		r16,  0x0010(r31)
	or		r16, r16, r8
	stw		r16,  0x0010(r31)
	mflr	r27
	lwz		r8,  0x0000(r31)
	bl		major_0x0dce8
	lwz		r16,  0x0008(r31)
	cmpw	r16, r31
	addi	r8, r16, -0x08
	beq-	major_0x0d35c_0x90
	lwz		r17,  0x0088(r8)
	lwz		r18,  0x00fc(r17)
	subi	r18, r18, 4
	stw		r18,  0x00fc(r17)
	lbz		r17,  0x0037(r8)
	cmpwi	r17,  0x01
	bne-	major_0x0d35c_0x4c
	addi	r8, r8,  0x20
	bl		major_0x136c8

major_0x0d35c_0x4c
	lwz		r16,  0x0008(r31)
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lwz		r18,  0x001c(r31)
	addi	r18, r18, -0x01
	stw		r18,  0x001c(r31)
	addi	r8, r16, -0x08
	li		r17,  0x01
	stb		r17,  0x0019(r8)
	bl		TaskReadyAsPrev
	bl		CalculateTimeslice
	bl		major_0x14af8

major_0x0d35c_0x90
	lwz		r16,  0x0018(r31)
	rlwinm.	r17, r16,  0, 27, 27
	beq-	major_0x0d35c_0x1a0
	lwz		r17,  0x0658(r1)
	lwz		r26, -0x08f0(r1)
	lwz		r18,  0x00c8(r17)
	lwz		r19,  0x00d0(r17)
	cmpwi	cr1, r18,  0x00
	cmpwi	r19,  0x00
	bne-	cr1, major_0x0d35c_0xc8
	bne-	major_0x0d35c_0x1a0
	lwz		r8,  0x0000(r31)
	stw		r8,  0x00d0(r17)
	b		major_0x0d35c_0x118

major_0x0d35c_0xc8
	lwz		r9,  0x0634(r1)
	rlwinm	r16, r16,  2, 26, 29
	add		r18, r18, r9
	lwzx	r19, r16, r18
	cmpwi	r19,  0x00
	bne-	major_0x0d35c_0x1a0
	lwz		r8,  0x0000(r31)
	stwx	r8, r16, r18
	li		r19,  0x1c
	li		r9,  0x04

major_0x0d35c_0xf0
	lwzx	r8, r19, r18
	cmpwi	r8,  0x00
	bne-	major_0x0d35c_0x108
	subf.	r19, r9, r19
	bgt+	major_0x0d35c_0xf0
	bl		panic

major_0x0d35c_0x108
	cmplw	r16, r19
	srwi	r16, r16,  2
	blt-	major_0x0d35c_0x1a0
	stw		r16,  0x00d0(r17)

major_0x0d35c_0x118
	lwz		r16,  0x0064(r26)
	lbz		r19,  0x0018(r26)
	ori		r16, r16,  0x10
	stw		r16,  0x0064(r26)
	lwz		r17, -0x0440(r1)
	lwz		r16,  0x0674(r1)
	lwz		r8,  0x0678(r1)
	and		r16, r16, r8
	or		r17, r17, r16
	stw		r17, -0x0440(r1)
	cmpwi	r19,  0x00
	addi	r16, r26,  0x08
	bne-	major_0x0d35c_0x198
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lbz		r17,  0x0037(r26)
	cmpwi	r17,  0x01
	bne-	major_0x0d35c_0x17c
	addi	r8, r26,  0x20
	bl		major_0x136c8

major_0x0d35c_0x17c
	lwz		r18, -0x08f0(r1)
	li		r16,  0x00
	stb		r16,  0x0019(r26)
	mr		r8, r26
	bl		TaskReadyAsNext
	mr		r8, r26
	bl		CalculateTimeslice

major_0x0d35c_0x198
	mr		r8, r26
	bl		major_0x14af8

major_0x0d35c_0x1a0
	mtlr	r27
	blr



	DeclareMPCall	52, MPWaitForEvent

;	ARG		MPEventID r3, Duration r5
;	RET		OSStatus r3, MPEventFlags r4

MPWaitForEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

	;	Check that the Event Group ID in r3 is valid.
	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	lwz		r16, 0x0010(r31)
	cmpwi	r16, 0
	beq-	MPWaitForEvent_field_10_was_zero

	mr		r4, r16

	li		r16, 0
	stw		r16,  0x0010(r31)

	lwz		r16,  0x0018(r31)
	lwz		r17, KDP.PA_ECB(r1)
	rlwinm.	r18, r16,  0, 27, 27
	rlwinm	r16, r16,  2, 26, 29
	beq+	ReleaseAndReturnZeroFromMPCall

	lwz		r18,  0x00c8(r17)
	lwz		r9,  0x0634(r1)
	cmpwi	r18,  0x00
	add		r18, r18, r9
	bne-	MPWaitForEvent_0x84
	lwz		r18,  0x00d0(r17)
	cmpw	r18, r3
	li		r18,  0x00

;	r1 = kdp
	bne+	ReleaseAndReturnZeroFromMPCall
	stw		r18,  0x00d0(r17)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPWaitForEvent_0x84
	lwzx	r19, r16, r18
	cmpw	r19, r3
	li		r19,  0x00

;	r1 = kdp
	bne+	ReleaseAndReturnZeroFromMPCall
	stwx	r19, r16, r18
	li		r19,  0x1c
	li		r9,  0x04

MPWaitForEvent_0xa0
	lwzx	r8, r19, r18
	cmpwi	r8,  0x00
	bne-	MPWaitForEvent_0xb4
	subf.	r19, r9, r19
	bgt+	MPWaitForEvent_0xa0

MPWaitForEvent_0xb4
	srwi	r19, r19,  2
	stw		r19,  0x00d0(r17)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPWaitForEvent_field_10_was_zero
	mfsprg	r30, 0
	cmpwi	r5, 0
	lwz		r19, EWA.PA_CurTask(r30)
	beq+	ReleaseAndTimeoutMPCall
	lwz		r16, Task.ThingThatAlignVecHits(r19)
	rlwinm.	r16, r16, 0, 15, 15

	beq-	@bit_15_was_unset
	stw		r3, PSA.SomeEvtGrpID(r1)
	b		ReleaseAndReturnMPCallBlueBlocking
@bit_15_was_unset

	;	MOVE TASK OUT OF QUEUE AND INTO EVENT GROUP
	mr		r8, r19
	bl		DequeueTask

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
	beq-	@wait_forever				;	never trigger max-wait timers

	stb		r16, Timer.Byte0(r30)
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
	b		AlternateMPCallReturnPath



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
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8
	lwz		r16,  0x0010(r31)
	cmpwi	r16,  0x00
	beq+	ReleaseAndTimeoutMPCall

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	54, MPSetSWIEvent

;	ARG		MPEventID r3, int r4 swi

MPSetSWIEvent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8
	li		r17, 1

	cmpwi	r4, 0
	cmplwi	cr1, r4, 8

	lwz		r16, EventGroup.SWI(r31)

	beq-	@use_1
	bgt-	cr1, @use_1

	mr		r17, r4
@use_1

	;	r17 = 1 if outside 1-8 (inc) range

	ori		r16, r16, 0x10
	rlwimi	r16, r17, 0, 28, 31
	stw		r16, EventGroup.SWI(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall














	DeclareMPCall	40, NKCreateTimer

NKCreateTimer	;	OUTSIDE REFERER
	li		r8,  0x40

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	mr.		r31, r8
	beq+	major_0x0af60_0x20

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r31
	li		r9,  0x03

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne-	NKCreateTimer_0x48
	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60

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



	DeclareMPCall	41, NKDeleteTimer

NKDeleteTimer	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r3
	bl		DeleteID
	lwz		r16,  0x0008(r31)
	cmpwi	r16,  0x00
	beq-	NKDeleteTimer_0x48
	mr		r8, r31
	bl		major_0x136c8

NKDeleteTimer_0x48
	_AssertAndRelease	PSA.SchLock, scratch=r16
	lwz		r8,  0x001c(r31)
	cmpwi	r8,  0x00
	bnel-	PoolFree
	mr		r8, r31
	bl		PoolFree
	b		ReturnZeroFromMPCall



	DeclareMPCall	30, NKSetTimerNotify

NKSetTimerNotify	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lbz		r16,  0x0014(r31)
	cmpwi	r16,  0x03
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r4

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	cmpwi	cr2, r9,  0x04
	beq-	NKSetTimerNotify_0x80
	cmpwi	r9,  0x09
	beq-	cr2, NKSetTimerNotify_0x64
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	stw		r4,  0x002c(r31)
	stw		r5,  0x0030(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

NKSetTimerNotify_0x64
	stw		r4,  0x0018(r31)
	lwz		r16,  0x0134(r6)
	lwz		r17,  0x013c(r6)
	stw		r5,  0x0020(r31)
	stw		r16,  0x0024(r31)
	stw		r17,  0x0028(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

NKSetTimerNotify_0x80
	stw		r4,  0x0034(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	31, MPCall_31

MPCall_31	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lbz		r16,  0x0014(r31)
	cmpwi	r16,  0x03
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  0x0008(r31)
	cmpwi	r16,  0x00
	mr		r8, r31
	beq-	MPCall_31_0x4c
	bl		major_0x136c8

MPCall_31_0x4c
	lwz		r9,  0x001c(r31)
	lwz		r8,  0x0018(r31)
	cmpwi	r9,  0x00
	cmpwi	cr1, r8,  0x00
	bne-	MPCall_31_0x9c
	beq-	cr1, MPCall_31_0x9c

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	bne-	MPCall_31_0x9c
	lwz		r9,  0x0024(r8)
	li		r8,  0x1c
	cmpwi	r9,  0x00
	bne-	MPCall_31_0x9c

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	mr.		r30, r8
	beq+	major_0x0af60
	lis		r8,  0x6e6f
	ori		r8, r8,  0x7465
	stw		r8,  0x0004(r30)
	stw		r30,  0x001c(r31)

MPCall_31_0x9c
	lwz		r16,  0x0134(r6)
	rlwinm.	r9, r16,  0, 29, 29
	mr		r8, r4
	beq-	MPCall_31_0xb8

;	r1 = kdp
;	r8 = multiple (pos: /250; neg: /250000)
	bl		TimebaseTicksPerPeriod
;	r8 = hi
;	r9 = lo

	mr		r4, r8
	mr		r5, r9

MPCall_31_0xb8
	lwz		r16,  0x0134(r6)
	rlwinm.	r8, r16,  0, 30, 30
	mfxer	r17
	beq-	MPCall_31_0xdc
	lwz		r19,  0x003c(r31)
	lwz		r18,  0x0038(r31)
	addc	r5, r5, r19
	adde	r4, r4, r18
	mtxer	r17

MPCall_31_0xdc
	stw		r4,  0x0038(r31)
	stw		r5,  0x003c(r31)
	lwz		r16,  0x0134(r6)
	clrlwi.	r16, r16,  0x1f
	li		r17,  0x00
	beq-	MPCall_31_0xf8
	li		r17,  0x01

MPCall_31_0xf8
	stb		r17,  0x0016(r31)
	mr		r8, r31
	bl		EnqueueTimer

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	32, MPCall_32

MPCall_32	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Timer.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lbz		r16,  0x0017(r31)
	cmpwi	r16,  0x01
	bne-	MPCall_32_0x58
	lwz		r4,  0x0038(r31)
	lwz		r5,  0x003c(r31)
	bl		GetTime
	mfxer	r16
	subfc	r5, r9, r5
	subfe.	r4, r8, r4
	mtxer	r16
	bge+	MPCall_32_0x60

MPCall_32_0x58
	li		r4,  0x00
	li		r5,  0x00

MPCall_32_0x60
	lwz		r16,  0x0008(r31)
	cmpwi	r16,  0x00
	mr		r8, r31
	beq-	MPCall_32_0x74
	bl		major_0x136c8

MPCall_32_0x74
;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	64, MPCall_64

MPCall_64	;	OUTSIDE REFERER
	li		r8,  0x28

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	mr.		r31, r8
	beq+	major_0x0af60_0x20
	lis		r16,  0x4b4e
	ori		r16, r16,  0x4f54
	stw		r16,  0x0004(r31)

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9,  0x0c

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne+	MPCall_64_0x50
	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60

MPCall_64_0x50
	mfsprg	r30, 0
	lwz		r30, -0x0008(r30)
	stw		r8,  0x0000(r31)
	lwz		r17,  0x0060(r30)
	stw		r17,  0x0008(r31)
	mr		r4, r8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	65, MPCall_65

MPCall_65	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	67, MPCall_67

MPCall_67	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	bl		major_0x0db04
	mr		r3, r8
	b		ReleaseAndReturnMPCall



;	                     major_0x0db04

;	Xrefs:
;	major_0x02ccc
;	IntPerfMonitor
;	IntThermalEvent
;	MPCall_67
;	major_0x102c8
;	CommonPIHPath

major_0x0db04	;	OUTSIDE REFERER
	mflr	r29
	lwz		r16,  0x000c(r30)
	lwz		r17,  0x0024(r30)
	cmplwi	r16,  0x00
	cmplwi	cr1, r17,  0x00
	bne-	major_0x0db04_0x28
	bne-	cr1, major_0x0db04_0x28
	lwz		r18,  0x001c(r30)
	cmplwi	r18,  0x00
	beq-	major_0x0db04_0xf0

major_0x0db04_0x28
	lwz		r8,  0x000c(r30)
	cmplwi	r8,  0x00
	beq-	major_0x0db04_0x94

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne-	major_0x0db04_0xfc
	lwz		r16,  0x0024(r31)
	cmpwi	r16,  0x00
	lwz		r17,  0x0028(r31)
	beq-	major_0x0db04_0x68
	mr.		r8, r17
	lwz		r17,  0x0008(r17)
	beq-	major_0x0db04_0xf0
	stw		r17,  0x0028(r31)
	b		major_0x0db04_0x78

major_0x0db04_0x68
	li		r8,  0x1c
	bl		PoolAlloc_with_crset
	cmpwi	r8,  0x00
	beq-	major_0x0db04_0xe4

major_0x0db04_0x78
	lwz		r16,  0x0010(r30)
	lwz		r17,  0x0014(r30)
	lwz		r18,  0x0018(r30)
	stw		r16,  0x0010(r8)
	stw		r17,  0x0014(r8)
	stw		r18,  0x0018(r8)
	bl		major_0x0c8b4

major_0x0db04_0x94
	lwz		r8,  0x0024(r30)
	cmplwi	r8,  0x00
	beq-	major_0x0db04_0xb4

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	mr		r31, r8
	bne-	major_0x0db04_0xfc
	bl		major_0x0ccf4

major_0x0db04_0xb4
	lwz		r8,  0x001c(r30)
	cmplwi	r8,  0x00
	beq-	major_0x0db04_0xd8

;	r8 = id
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass

	mr		r31, r8
	bne-	major_0x0db04_0xfc
	lwz		r8,  0x0020(r30)
	bl		major_0x0d35c

major_0x0db04_0xd8
	mtlr	r29
	li		r8,  0x00
	blr

major_0x0db04_0xe4
	mtlr	r29
	li		r8, -0x726e
	blr

major_0x0db04_0xf0
	mtlr	r29
	li		r8, -0x7272
	blr

major_0x0db04_0xfc
	mtlr	r29
	li		r8, -0x7273
	blr



	DeclareMPCall	66, MPCall_66

MPCall_66	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r8, r4

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	cmpwi	cr2, r9,  0x04
	beq-	MPCall_66_0x74
	cmpwi	r9,  0x09
	beq-	cr2, MPCall_66_0x58
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	stw		r4,  0x001c(r31)
	stw		r5,  0x0020(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_66_0x58
	stw		r4,  0x000c(r31)
	lwz		r16,  0x0134(r6)
	lwz		r17,  0x013c(r6)
	stw		r5,  0x0010(r31)
	stw		r16,  0x0014(r31)
	stw		r17,  0x0018(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_66_0x74
	stw		r4,  0x0024(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	128, MPCall_128

MPCall_128	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	cmpwi	r4,  0x04
	cmpwi	cr1, r4,  0x09
	beq-	MPCall_128_0x40
	beq-	cr1, MPCall_128_0x58
	b		major_0x0b054

MPCall_128_0x40
	lwz		r16,  0x0134(r6)
	lwz		r17,  0x013c(r6)
	stw		r5,  0x0010(r31)
	stw		r16,  0x0014(r31)
	stw		r17,  0x0018(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_128_0x58
	stw		r5,  0x0020(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     major_0x0dce8

;	Xrefs:
;	major_0x02ccc
;	MPCall_16
;	major_0x0c8b4
;	major_0x0ccf4
;	MPCall_21
;	MPCall_28
;	MPCall_26
;	MPDeleteEvent
;	major_0x0d35c

major_0x0dce8	;	OUTSIDE REFERER
	lwz		r9, -0x0410(r1)
	lwz		r19, -0x08f0(r1)
	cmpw	r8, r9
	bnelr-
	li		r9, -0x01
	mflr	r24
	stw		r9, -0x0410(r1)
	lbz		r17,  0x0018(r19)
	cmpwi	r17,  0x00
	addi	r16, r19,  0x08
	bne-	major_0x0dce8_0x70
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lbz		r17,  0x0037(r19)
	cmpwi	r17,  0x01
	bne-	major_0x0dce8_0x60
	addi	r8, r19,  0x20
	bl		major_0x136c8
	lwz		r19, -0x08f0(r1)

major_0x0dce8_0x60
	li		r16,  0x01
	stb		r16,  0x0019(r19)
	lwz		r8, -0x08f0(r1)
	bl		TaskReadyAsPrev

major_0x0dce8_0x70
	lwz		r8, -0x08f0(r1)
	mtlr	r24
	b		major_0x14af8



	DeclareMPCall	120, MPCall_120

MPCall_120	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	mr		r31, r8
	cmpwi	r9,  0x05
	cmpwi	cr1, r9,  0x04
	beq-	MPCall_120_0x33c
	beq-	cr1, MPCall_120_0x248
	cmpwi	r9,  0x09
	cmpwi	cr1, r9,  0x06
	beq-	MPCall_120_0x1b4
	beq-	cr1, MPCall_120_0x10c
	cmpwi	r9,  0x0c
	cmpwi	cr1, r9,  0x08
	beq-	MPCall_120_0x58
	beq-	cr1, MPCall_120_0x3d8
	b		major_0x0b054

MPCall_120_0x58
	lis		r8,  0x0c
	ori		r8, r8,  0x01
	cmpw	r8, r4
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_120_0xa0
	lis		r16,  0x0c
	ori		r16, r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0008(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0004(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x000c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0xa0
	cmplwi	r5,  0x10
	bne-	MPCall_120_0xd4
	lwz		r16,  0x0010(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0014(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0018(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x001c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0xd4
	cmplwi	r5,  0x20
	bne-	MPCall_120_0xf8
	lwz		r16,  0x0020(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0024(r31)
	stw		r16,  0x013c(r6)
	li		r16,  0x08
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0xf8
	cmpwi	r5,  0x28
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x10c
	lis		r8,  0x06
	ori		r8, r8,  0x01
	cmpw	r8, r4
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_120_0x154
	lis		r16,  0x06
	ori		r16, r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0010(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0004(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x0020(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x154
	cmplwi	r5,  0x10
	bne-	MPCall_120_0x1a0
	addi	r17, r31,  0x00
	lwz		r18,  0x0008(r31)
	li		r16,  0x00
	cmpw	r17, r18
	beq-	MPCall_120_0x174
	lwz		r16, -0x0008(r18)

MPCall_120_0x174
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0018(r31)
	cmpwi	r16,  0x00
	beq-	MPCall_120_0x188
	lwz		r16,  0x0000(r16)

MPCall_120_0x188
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0014(r31)
	stw		r16,  0x0144(r6)
	li		r16,  0x0c
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x1a0
	cmpwi	r5,  0x1c
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x1b4
	lis		r8,  0x09
	ori		r8, r8,  0x01
	cmpw	r8, r4
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_120_0x1fc
	lis		r16,  0x09
	ori		r16, r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0014(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0004(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x001c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x1fc
	cmplwi	r5,  0x10
	bne-	MPCall_120_0x234
	addi	r17, r31,  0x00
	lwz		r18,  0x0008(r31)
	li		r16,  0x00
	cmpw	r17, r18
	beq-	MPCall_120_0x21c
	lwz		r16, -0x0008(r18)

MPCall_120_0x21c
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0010(r31)
	stw		r16,  0x013c(r6)
	li		r16,  0x08
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x234
	cmpwi	r5,  0x18
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x248
	lis		r8,  0x04
	ori		r8, r8,  0x01
	cmpw	r8, r4
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_120_0x290
	lis		r16,  0x04
	ori		r16, r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0020(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0004(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x002c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x290
	cmplwi	r5,  0x10
	bne-	MPCall_120_0x2ec
	addi	r17, r31,  0x00
	lwz		r18,  0x0008(r31)
	li		r16,  0x00
	cmpw	r17, r18
	beq-	MPCall_120_0x2b0
	lwz		r16, -0x0008(r18)

MPCall_120_0x2b0
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0030(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0024(r31)
	stw		r16,  0x0144(r6)
	lwz		r18,  0x0018(r31)
	addi	r17, r31,  0x10
	li		r16,  0x00
	cmpw	r17, r18
	beq-	MPCall_120_0x2dc
	lwz		r16,  0x0010(r18)

MPCall_120_0x2dc
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x2ec
	cmplwi	r5,  0x20
	bne-	MPCall_120_0x328
	lwz		r18,  0x0018(r31)
	addi	r17, r31,  0x10
	li		r16,  0x00
	cmpw	r17, r18
	li		r17,  0x00
	beq-	MPCall_120_0x314
	lwz		r16,  0x0014(r18)
	lwz		r17,  0x0018(r18)

MPCall_120_0x314
	stw		r16,  0x0134(r6)
	stw		r17,  0x013c(r6)
	li		r16,  0x08
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x328
	cmpwi	r5,  0x28
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x33c
	lis		r8,  0x05
	ori		r8, r8,  0x01
	cmpw	r8, r4
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_120_0x384
	lis		r16,  0x05
	ori		r16, r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0018(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0004(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x001c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x384
	cmplwi	r5,  0x10
	bne-	MPCall_120_0x3c4
	addi	r17, r31,  0x00
	lwz		r18,  0x0008(r31)
	li		r16,  0x00
	cmpw	r17, r18
	beq-	MPCall_120_0x3a4
	lwz		r16, -0x0008(r18)

MPCall_120_0x3a4
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0014(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0010(r31)
	stw		r16,  0x0144(r6)
	li		r16,  0x0c
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x3c4
	cmpwi	r5,  0x1c
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x3d8
	lis		r8,  0x08
	ori		r8, r8,  0x01
	cmpw	r8, r4
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_120_0x420
	lis		r16,  0x08
	ori		r16, r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0074(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0070(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x000c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x420
	cmplwi	r5,  0x10
	bne-	MPCall_120_0x454
	lwz		r16,  0x0030(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0034(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0038(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x003c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x454
	cmplwi	r5,  0x20
	bne-	MPCall_120_0x488
	lwz		r16,  0x0040(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0044(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0048(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x004c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x488
	cmplwi	r5,  0x30
	bne-	MPCall_120_0x4bc
	lwz		r16,  0x0050(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0054(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0058(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x005c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x4bc
	cmplwi	r5,  0x40
	bne-	MPCall_120_0x4f0
	lwz		r16,  0x0060(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0064(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0068(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x006c(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_120_0x4f0
	cmpwi	r5,  0x50
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall
