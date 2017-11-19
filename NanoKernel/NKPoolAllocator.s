Local_Panic		set		*
				b		panic



;	                       InitPool

;	Allocate one page for the kernel pool. Same layout at
;	Memtop starts at 7 pages below KDP.
;	Take note of the structure from kdp-ab0 to kdp-aa0

;	Xrefs:
;	setup

;	> r1    = kdp

InitPool	;	OUTSIDE REFERER

	;	r9 = LA_KD - 7 pages
	lwz		r8, KDP.PA_ConfigInfo(r1)
	lwz		r8, NKConfigurationInfo.LA_KernelData(r8)
	lisori	r9, 0x7000
	subf	r9, r9, r8
	stw		r9, -0x0a9c(r1)

	lisori	r9, -0x7000
	add		r9, r9, r1
	stw		r9, -0x0aa0(r1)

;	bit of a mystery
	lisori	r8,  0x00006458
	add		r23, r8, r9
	stw		r8,  0x0000(r9)

	lisori	r8, '‡BGN'
	stw		r8,  0x0004(r9)

	addi	r9, r9,  0x08
	lisori	r8,  0x00006450
	stw		r8,  0x0000(r9)

	lisori	r8, 'free'
	stw		r8,  0x0004(r9)

	li		r8,  0x00
	stw		r8,  0x0000(r23)

	lisori	r8, '‡END'
	stw		r8,  0x0004(r23)

;	set up linked list
		addi	r8, r1, PSA.FreePool

		stw		r9, LLL.Next(r8)
		stw		r9, LLL.Prev(r8)
		stw		r8, LLL.Next(r9)
		stw		r8, LLL.Prev(r9)

		lisori	r9, 'POOL'
		stw		r9, LLL.Signature(r8)


	blr



;	                      PoolAlloc

;	Easy to use! 0xfd8 (a page minus 10 words) is the
;	largest request that can be satisfied.

;	Xrefs:
;	setup
;	major_0x02ccc
;	KCCreateProcess
;	KCCreateCpuStruct
;	MPCall_15
;	MPCall_39
;	MPCall_17
;	MPCall_20
;	MPCall_25
;	MPCall_49
;	MPCall_40
;	MPCall_31
;	MPCall_64
;	major_0x0db04
;	CreateTask
;	MPCall_58
;	convert_pmdts_to_areas
;	NKCreateAddressSpaceSub
;	MPCall_72
;	createarea
;	MPCall_73
;	MPCall_130
;	InitTMRQs
;	InitIDIndex
;	MakeID

;	> r1    = kdp
;	> r8    = size

;	< r8    = ptr

PoolAlloc	;	OUTSIDE REFERER
	crclr	cr7_eq
	b		PoolAllocCommon

PoolAlloc_with_crset	;	OUTSIDE REFERER
	crset	cr7_eq

PoolAllocCommon

	;	Save LR and arg to EWA. Get lock.
		mflr	r17
		mfsprg	r18, 0
	
		_Lock			PSA.PoolLock, scratch1=r15, scratch2=r16
	
		;	These saves are my first real hint at the contents of that
		;	large unexplored area of the EWA. This file, then, owns
		;	part of the EWA, for its CPU-scoped globals. Because the
		;	kernel runs stackless.
		stw		r17, EWA.PoolSavedLR(r18)
		stw		r8, EWA.PoolSavedSizeArg(r18)

@try_again
	;	Check that requested allocation is in the doable size range.
	cmpwi	r8, 0
	cmpwi	cr1, r8, 0xfd8
	ble+	Local_Panic						; zero-byte request => thud
	bgt-	cr1, @request_too_large

	addi	r8, r8, 39
	rlwinm	r8, r8,  0,  0, 26
	
	;	Check that the pool has any pages in it.
	addi	r14, r1, PSA.FreePool
	lwz		r15, LLL.Next(r14)
@try_different_page
	cmpw	r14, r15
	
	bne+	@pool_has_page
	
	;	No? Then claim a page from the system free list for the pool?
	
		;	Got a free page in the system free list? It's ours.
		li		r8, 0						; return zero if there is no page at all
		li		r9, 1						; number of pages to grab
		
		lwz		r16, PSA.FreePageCount(r1)
		lwz		r17, PSA.UnheldFreePageCount(r1)
		subf.	r16, r9, r16
		subf	r17, r9, r17
		blt-	PoolCommonReturn
	
		stw		r16, PSA.FreePageCount(r1)
		stw		r17, PSA.UnheldFreePageCount(r1)
	
		;	Get that page, mofo. Macros FTW.
		lwz		r8, PSA.FreeList + LLL.Next(r1)
		RemoveFromList		r8, scratch1=r17, scratch2=r18
	
		;	There was probably once a mechanism for virtual addressing of the pool!
		li		r9, 0
		bl		ExtendPool			; r8=page, r9=virt=0
	
	;	Now that the pool is not empty, start over.
	mfsprg	r18, 0
	lwz		r8, EWA.PoolSavedSizeArg(r18)
	b		@try_again

@request_too_large
	li		r8, 0
	b		PoolCommonReturn

@pool_has_page
	;	We have a page (r15) that might have room in it.
	;	r8 contains the size describing our actual demand on the page!
	
	lwz		r16, PoolPage.FreeBytes(r15)
	cmplw	r16, r8
	
	lis		r20, 'fr'
	bgt-	@fits_with_leftover_space
	beq-	@fits_perfectly
	ori		r20, r20, 'ee'
	
	lwz		r16, PoolPage.FreeBytes(r15)
	add		r18, r16, r15					; r18 = ???
	lwz		r19,  0x0004(r18)
	cmplw	cr1, r18, r15
	cmpw	r19, r20
	ble+	cr1, Local_Panic
	bne-	@_118
	lwz		r17,  0x0000(r18)
	rotlwi	r19, r19,  0x08
	add		r17, r17, r16
	stw		r17,  0x0000(r15)
	stw		r19,  0x0004(r18)
	lwz		r17,  0x000c(r18)
	lwz		r16, LLL.Next(r18)
	stw		r16, LLL.Next(r17)
	stw		r17,  0x000c(r16)
	b		@pool_has_page

@_118
	lwz		r15, LLL.Next(r15)
	b		@try_different_page

@fits_with_leftover_space
	subf	r16, r8, r16
	cmpwi	r16,  0x28
	blt-	@fits_perfectly
	stw		r16,  0x0000(r15)
	add		r15, r15, r16
	stw		r8,  0x0000(r15)
	b		@_14c

@fits_perfectly
	lwz		r14,  0x000c(r15)
	lwz		r16, LLL.Next(r15)
	stw		r16, LLL.Next(r14)
	stw		r14,  0x000c(r16)

@_14c
	lisori	r8, '‡loc'
	stw		r8,  0x0004(r15)
	addi	r8, r15,  0x08
	
	beq-	cr7, PoolCommonReturn
	lwz		r16,  0x0000(r15)
	addi	r16, r16, -0x08
	li		r14,  0x00
	add		r16, r16, r15
	addi	r15, r15,  0x04

@_174
	stwu	r14,  0x0004(r15)
	cmpw	r15, r16
	ble+	@_174
	b		PoolCommonReturn



;	                 PoolFree

;	ARG		void *r8

PoolFree	;	OUTSIDE REFERER
	mflr	r17
	mfsprg	r18, 0

	_Lock			PSA.PoolLock, scratch1=r15, scratch2=r16

	stw		r17, EWA.PoolSavedLR(r18)
	bl		major_0x129fc
	bl		major_0x12a34



;	File-internal

;	Return path of most of these functions?
;	Releases Pool lock and Returns to the link
;	address saved in EWA.

PoolCommonReturn	;	OUTSIDE REFERER
	mfsprg	r18, 0
	sync

	lwz		r15, PSA.PoolLock + Lock.Count(r1)
	cmpwi	cr1, r15, 0
	li		r15, 0
	bne+	cr1, @no_panic
	mflr	r15
	bl		panic
@no_panic

	stw		r15, PSA.PoolLock + Lock.Count(r1)
	
	lwz		r17, EWA.PoolSavedLR(r18)
	mtlr	r17
	blr



;	                     major_0x129fc

;	Xrefs:
;	PoolFree
;	ExtendPool

;	ARG		Area *r8

major_0x129fc	;	OUTSIDE REFERER
	subi	r15, r8, 8

	lis		r20, 'fr'
	lhz		r16, 4(r15)
	ori		r20, r20, 'ee'
	cmplwi	r16, 0x876c
	bne+	Local_Panic
	stw		r20, 4(r15)

	addi	r16, r1, PSA.FreePool

	InsertAsPrev	r15, r16, scratch=r17

	blr



;	                     major_0x12a34

;	Xrefs:
;	PoolFree
;	ExtendPool

major_0x12a34	;	OUTSIDE REFERER
	lis		r20,  0x6672
	lwz		r16,  0x0000(r15)
	ori		r20, r20,  0x6565
	add		r18, r16, r15
	lwz		r19,  0x0004(r18)
	cmplw	cr1, r18, r15
	cmpw	r19, r20
	ble+	cr1, Local_Panic
	bnelr-
	lwz		r17,  0x0000(r18)
	rotlwi	r19, r19,  0x08
	add		r17, r17, r16
	stw		r17,  0x0000(r15)
	stw		r19,  0x0004(r18)
	lwz		r17,  0x000c(r18)
	lwz		r16, LLL.Next(r18)
	stw		r16, LLL.Next(r17)
	stw		r17,  0x000c(r16)
	b		major_0x12a34



;	                       ExtendPool

;	 0xed0(r1) = pool extends (I increment)
;	-0xa9c(r1) = virt last page (I update)
;	-0xaa0(r1) = phys last page (I update)
;	Assumes that cache blocks are 32 bytes! Uh-oh.
;	Page gets decorated like this:
;	000: 00 00 0f e8
;	004: 87 'B 'G 'N
;	008: 00 00 0f e8
;	00c: 87 'l 'o 'c
;	...     zeros    << r8 passes ptr to here
;	fe8: phys offset from here to prev page
;	fec: 87 'E 'N 'D
;	ff0: logical abs address of prev page
;	ff4: 00 00 00 00
;	ff8: 00 00 00 00
;	ffc: 00 00 00 00

;	Xrefs:
;	MPCall_0
;	PoolAlloc

;	> r1    = kdp
;	> r8    = anywhere in new page (phys)
;	> r9    = page_virt

ExtendPool	;	OUTSIDE REFERER
	mflr	r14
	rlwinm	r17, r8,  0,  0, 19

	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.FreePoolExtendCount(r1)
	addi	r16, r16, 1
	stw		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.FreePoolExtendCount(r1)
	
	_log	'Extend free pool: phys 0x'
	mr		r8, r17
	bl		Printw
	_log	' virt 0x'
	mr		r8, r9
	bl		Printw
	_log	' count: '
	mr		r8, r16
	bl		Printd
	_log	'^n'
	li		r16,  0x1000

@zeroloop
	subi	r16, r16, 32
	cmpwi	r16, 0
	dcbz	r16, r17
	bgt+	@zeroloop

;	Put the funny stuff in
	li		r16,  0xfe8
	stw		r16,  0x0000(r17)
	lisori	r16, '‡BGN'
	stw		r16,  0x0004(r17)
	addi	r15, r17,  0x08
	li		r16,  0xfe0
	stw		r16,  0x0000(r15)
	lisori	r16, '‡loc'
	stw		r16,  0x0004(r15)
	addi	r15, r17,  0xfe8
	lwz		r18, -0x0aa0(r1)
	subf	r18, r15, r18
	stw		r18,  0x0000(r15)
	lisori	r16, '‡END'
	stw		r16,  0x0004(r15)
	lwz		r16, -0x0a9c(r1)
	stw		r16, LLL.Next(r15)

;	Update globals
	stw		r9, -0x0a9c(r1)
	stw		r17, -0x0aa0(r1)

;	Unknown func calls
	addi	r8, r17,  0x10
	bl		major_0x129fc
	bl		major_0x12a34
	mtlr	r14
	blr



;	                     major_0x12b94

;	Xrefs:
;	"HeapSegCorrupt"

	mflr	r19
	lwz		r20, -0x0aa0(r1)

major_0x12b94_0x8
	addi	r8, r20,  0x08
	bl		major_0x12b94_0x30
	lwz		r17,  0x0000(r20)
	add		r17, r17, r20
	lwz		r18,  0x0000(r17)
	cmpwi	r18,  0x00
	add		r20, r18, r17
	bne+	major_0x12b94_0x8
	mtlr	r19
	blr

major_0x12b94_0x30
	mflr	r14
	addi	r16, r8, -0x08

major_0x12b94_0x38
	lwz		r17,  0x0004(r16)
	lis		r18, -0x78bb
	ori		r18, r18,  0x4e44
	cmpw	r17, r18
	li		r9,  0x00
	beq-	major_0x12b94_0x1a4
	lis		r18, -0x7894
	ori		r18, r18,  0x6f63
	cmpw	r17, r18
	beq-	major_0x12b94_0x94
	lis		r18,  0x6672
	ori		r18, r18,  0x6565
	li		r9,  0x04
	cmpw	r17, r18
	bne-	major_0x12b94_0xa8
	lwz		r17,  0x000c(r16)
	cmpwi	r17,  0x00
	li		r9,  0x05
	beq-	major_0x12b94_0xa8
	lwz		r17, LLL.Next(r16)
	cmpwi	r17,  0x00
	li		r9,  0x06
	beq-	major_0x12b94_0xa8

major_0x12b94_0x94
	lwz		r17,  0x0000(r16)
	add		r16, r16, r17
	cmpwi	r17,  0x00
	li		r9,  0x07
	bgt+	major_0x12b94_0x38

major_0x12b94_0xa8
	mr		r18, r8
	_log	'Heap segment corrupt '
	mr		r8, r9
	bl		Printd
	_log	'at '
	mr		r8, r16
	bl		Printw
	_log	'^n'
	addi	r16, r16, -0x40
	li		r17,  0x08

major_0x12b94_0x10c
	mr		r8, r16
	bl		Printw
	_log	' '
	lwz		r8,  0x0000(r16)
	bl		Printw
	lwz		r8,  0x0004(r16)
	bl		Printw
	lwz		r8, LLL.Next(r16)
	bl		Printw
	lwz		r8,  0x000c(r16)
	bl		Printw
	_log	'  *'
	li		r8,  0x10
	addi	r16, r16, -0x01
	mtctr	r8

major_0x12b94_0x164
	lbzu	r8,  0x0001(r16)
	cmpwi	r8,  0x20
	bgt-	major_0x12b94_0x174
	li		r8,  0x20

major_0x12b94_0x174
	bl		Printc
	bdnz+	major_0x12b94_0x164
	_log	'*^n'
	addi	r17, r17, -0x01
	addi	r16, r16,  0x01
	cmpwi	r17,  0x00
	bne+	major_0x12b94_0x10c
	mr		r8, r18

major_0x12b94_0x1a4
	mtlr	r14
	blr
