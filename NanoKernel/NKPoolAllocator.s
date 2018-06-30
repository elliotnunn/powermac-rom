;	SEGMENTS
;	
;	The pool is made up of segments of contiguous memory. The first segment
;	to be created is about 25k, running from 0x7000 below r1 to the start of
;	the Primary System Area. It is initialised by InitPool. Every subsequent
;	segment occupies a single page, plucked from the system free list by
;	ExtendPool.
;	
;	
;	BLOCKS
;	
;	Each segment is an array of variously sized blocks, with no gaps between
;	them. The first block is a Begin (‡BGN) block, the last block is an End
;	block (‡END), and all others are Allocated (‡loc) or Free (free) blocks.
;	To allow the data in each Allocated block to be 16b-aligned, all
;	Allocated and Free blocks start 8b below a 16b boundary.
;	
;	
;	SINGLY LINKED LIST OF SEGMENTS
;	
;	PSA.FirstPoolSeg points to the start of the most recently added pool
;	segment, i.e. to its Begin block. The OffsetToNext field of a Begin
;	block points not to the block immediately beyond it in memory, but to
;	the segment's End block. The OffsetToNext field of the End block points
;	to the start of the next most recently added pool segment. If there is
;	none, it contains zero.
;	
;	
;	DOUBLY LINKED LIST OF FREE BLOCKS
;	
;	Every free block is a member of PSA.FreePool, a doubly linked list of
;	free segments. The "LLL" structure occupies the first 16 bytes of the
;	block.



;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKConsoleLog
;	    printc
;	    printd
;	    printw
;	  NKThud
;	    panic
;	EXPORTS:
;	  ExtendPool (=> NKMPCalls)
;	  InitPool (=> NKInit)
;	  PoolAlloc (=> NKInterrupts, NKSync, NKTasks)
;	  PoolAllocClear (=> NKAddressSpaces, NKIndex, NKInit, NKMPCalls, NKSync, NKTasks, NKTimers, NKVMCalls)
;	  PoolFree (=> NKAddressSpaces, NKMPCalls, NKSync, NKTasks, NKTimers)



Block			record

kBeginSize		equ		8	
kEndSize		equ		24

kPoolSig		equ		'POOL'
kBeginSig		equ		'‡BGN'
kEndSig			equ		'‡END'
kAllocSig		equ		'‡loc'
kFreeSig		equ		'free'

;	For free and allocated blocks, points to the next block
;	For begin blocks, points to corresponding end block
;	For end blocks, points to another begin block (or zero)
OffsetToNext	ds.l	1	; 0

Signature		ds.l	1	; 4

Data
LogiNextSeg
FreeNext		ds.l	1	; 8

FreePrev		ds.l	1	; c

				endr



_PoolPanic

	b		panic



;	Use all the memory from r1 - 0x7000 to PSA

InitPool

	;	Add first segment to global singly linked list

	lwz		r8, KDP.PA_ConfigInfo(r1)
	lwz		r8, NKConfigurationInfo.LA_KernelData(r8)
	lisori	r9, -kPoolOffsetFromGlobals
	subf	r9, r9, r8
	stw		r9, PSA.FirstPoolSegLogical(r1)

	lisori	r9, kPoolOffsetFromGlobals
	add		r9, r9, r1
	stw		r9, PSA.FirstPoolSeg(r1)


	;	Decide how big the segment will be

_pool_first_seg equ PSA.Base - kPoolOffsetFromGlobals


	;	Begin block (leave ptr to End in r23)

	lisori	r8, _pool_first_seg - Block.kEndSize
	add		r23, r8, r9
	stw		r8, Block.OffsetToNext(r9)

	lisori	r8, Block.kBeginSig
	stw		r8, Block.Signature(r9)


	;	Free block (leave ptr in r9)

	addi	r9, r9, Block.kBeginSize
	lisori	r8, _pool_first_seg - Block.kEndSize - Block.kBeginSize
	stw		r8, Block.OffsetToNext(r9)

	lisori	r8, Block.kFreeSig
	stw		r8, Block.Signature(r9)


	;	End block

	li		r8, 0
	stw		r8, Block.OffsetToNext(r23)

	lisori	r8, Block.kEndSig
	stw		r8, Block.Signature(r23)


	;	Add Free block to global doubly linked list

	addi	r8, r1, PSA.FreePool

	stw		r9, Block.FreeNext(r8)
	stw		r9, Block.FreePrev(r8)
	stw		r8, Block.FreeNext(r9)
	stw		r8, Block.FreePrev(r9)

	lisori	r9, Block.kPoolSig
	stw		r9, Block.Signature(r8)


	;	Return

	blr



;	The NanoKernel's malloc

;	ARG		size r8
;	RET		ptr r8

_poolalloc_noclr_cr_bit equ 30

PoolAllocClear
	crclr	_poolalloc_noclr_cr_bit
	b		_PoolAllocCommon
PoolAlloc
	crset	_poolalloc_noclr_cr_bit
_PoolAllocCommon

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


@recheck_for_new_block

	;	Sanity checks

	cmpwi	r8, 0
	cmpwi	cr1, r8, 0xfd8
	ble		_PoolPanic
	bgt		cr1, @request_too_large


	;	Up-align to 32b boundary and snatch an extra 8b
	;	This is our minimum OffsetToNext field

	addi	r8, r8, 8 + 31
	rlwinm	r8, r8, 0, 0xffffffe0
	

	;	Iterate the free-block list

	addi	r14, r1, PSA.FreePool
	lwz		r15, LLL.Next(r14)
@next_block
	cmpw	r14, r15
	bne+	@try_block


	;	Global free-block list is empty (not great news)
	
	;	Got a free page in the system free list? It's ours.
	li		r8, 0						; return zero if there is no page at all
	li		r9, 1						; number of pages to grab
	
	lwz		r16, PSA.FreePageCount(r1)
	lwz		r17, PSA.UnheldFreePageCount(r1)
	subf.	r16, r9, r16
	subf	r17, r9, r17
	blt		_PoolReturn

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
	b		@recheck_for_new_block


	;	Request was greater than the maximum block size

@request_too_large

	li		r8, 0
	b		_PoolReturn


	;	Try the free block that r15 points to

@try_block
@retry_newly_expanded_block

	lwz		r16, Block.OffsetToNext(r15)
	cmplw	r16, r8
	
	lis		r20, 'fr'
	bgt		@decide_whether_to_split
	beq		@do_not_split
	ori		r20, r20, 'ee'
	

	;	This block is too small to fit our allocation, but can it be mashed together
	;	with a physically adjacent free block? This might happen a few times before
	;	we decide to give up and search for another block.

	lwz		r16, Block.OffsetToNext(r15)
	add		r18, r16, r15
	lwz		r19, Block.Signature(r18)
	cmplw	cr1, r18, r15
	cmpw	r19, r20
	ble		cr1, _PoolPanic
	bne		@physically_adjacent_block_is_not_free

	lwz		r17, Block.OffsetToNext(r18)
	rotlwi	r19, r19, 8
	add		r17, r17, r16
	stw		r17, Block.OffsetToNext(r15)
	stw		r19, Block.Signature(r18)				; scramble old signature to clarify mem dumps
	lwz		r17, Block.FreePrev(r18)
	lwz		r16, Block.FreeNext(r18)
	stw		r16, Block.FreeNext(r17)
	stw		r17, Block.FreePrev(r16)

	b		@retry_newly_expanded_block
@physically_adjacent_block_is_not_free

	lwz		r15, Block.FreeNext(r15)
	b		@next_block


	;	Success: split the block if there is >=40b left over

@decide_whether_to_split

	subf	r16, r8, r16
	cmpwi	r16, 40
	blt		@do_not_split


	;	Use the rightmost part of the block, leaving ptr in r15
	;	(Leaving the leftmost part saves us touching the free block list)

	stw		r16, Block.OffsetToNext(r15)
	add		r15, r15, r16
	stw		r8, Block.OffsetToNext(r15)
	b		@proceed_with_block


	;	Success: use the entire block, leaving ptr in r15

@do_not_split

	lwz		r14,  0x000c(r15)
	lwz		r16, LLL.Next(r15)
	stw		r16, LLL.Next(r14)
	stw		r14,  0x000c(r16)


	;	Sign the block and return data ptr in r8

@proceed_with_block

	lisori	r8, Block.kAllocSig
	stw		r8, Block.Signature(r15)

	addi	r8, r15, Block.Data


	;	Optionally clear the block (quicker if we don't)

	bc		BO_IF, _poolalloc_noclr_cr_bit, _PoolReturn
	lwz		r16, Block.OffsetToNext(r15)
	subi	r16, r16, Block.Data
	li		r14, 0
	add		r16, r16, r15
	addi	r15, r15, 4

@clrloop
	stwu	r14, 4(r15)
	cmpw	r15, r16
	ble		@clrloop

	b		_PoolReturn



;	The NanoKernel's free

;	ARG		r8 = ptr to contents of pool block

PoolFree

	mflr	r17
	mfsprg	r18, 0

	_Lock			PSA.PoolLock, scratch1=r15, scratch2=r16

	stw		r17, EWA.PoolSavedLR(r18)
	bl		_PoolAddBlockToFreeList
	bl		_PoolMergeAdjacentFreeBlocks

	;	Fall through...



;	PoolAlloc and PoolFree save LR on entry, then return this way

_PoolReturn

	mfsprg	r18, 0

	_AssertAndRelease	PSA.PoolLock, scratch=r15
	
	lwz		r17, EWA.PoolSavedLR(r18)
	mtlr	r17
	blr



;	Re-label an Allocated block as Free, and add it to the global list
;	Panics if block is not Allocated to start with!

;	ARG		r8 = ptr to contents of pool block
;	RET		r15 = ptr to pool block itself (r8 - 8)

_PoolAddBlockToFreeList

	;	Get the block containing the data
	subi	r15, r8, Block.Data

	;	Change the signature
	_lstart	r20, Block.kFreeSig
	lhz		r16, Block.Signature(r15)
	_lfinish
	cmplwi	r16, 0x876c ; Block.kAllocSig >> 16
	bne		_PoolPanic
	stw		r20, Block.Signature(r15)

	;	Insert into the global free block list
	addi	r16, r1, PSA.FreePool
	InsertAsPrev	r15, r16, scratch=r17

	blr



;	Merge a free block with any free blocks to the right
;	(Cannot look to the left because list is singly linked)

;	ARG		r15 = ptr to free block

_PoolMergeAdjacentFreeBlocks

@next_segment
	_lstart	r20, Block.kFreeSig
	lwz		r16, Block.OffsetToNext(r15)
	_lfinish
	add		r18, r16, r15						; r18 = block to the right
	lwz		r19, Block.Signature(r18)			; r19 = signature of that block
	cmplw	cr1, r18, r15
	cmpw	r19, r20
	ble		cr1, _PoolPanic						; die if block was of non-positive size!
	bnelr										; return if block to right is not free

	lwz		r17, Block.OffsetToNext(r18)
	rotlwi	r19, r19, 8							; scramble old signature to clarify mem dumps
	add		r17, r17, r16
	stw		r17, Block.OffsetToNext(r15)		; increase the size of the main block
	stw		r19, Block.Signature(r18)		

	lwz		r17, Block.FreePrev(r18)			; remove the absorbed block from the list of free blocks
	lwz		r16, Block.FreeNext(r18)
	stw		r16, Block.FreeNext(r17)
	stw		r17, Block.FreePrev(r16)

	b		@next_segment			



;	Create a new pool segment from a physical page

;	ARG		PhysPtr r8, LogiPtr r9

ExtendPool

	mflr	r14


	;	This segment will occupy a page

_pool_page_seg equ 0x1000

	rlwinm	r17, r8, 0, -(_pool_page_seg)


	;	Counter can be viewed from Apple System Profiler

	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.FreePoolExtendCount(r1)
	addi	r16, r16, 1
	stw		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.FreePoolExtendCount(r1)
	
	
	;	Bit of palaver

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


	;	Clear the page

	li		r16, _pool_page_seg
@zeroloop
	subi	r16, r16, 32
	cmpwi	r16, 0
	dcbz	r16, r17
	bgt		@zeroloop


	;	Begin block

	li		r16, _pool_page_seg - Block.kEndSize
	stw		r16, Block.OffsetToNext(r17)

	lisori	r16, Block.kBeginSig
	stw		r16, Block.Signature(r17)


	;	Alloc block (_PoolAddBlockToFreeList will convert to Free)

	addi	r15, r17, Block.kBeginSize
	li		r16, _pool_page_seg - Block.kEndSize - Block.kBeginSize
	stw		r16, Block.OffsetToNext(r15)

	lisori	r16, Block.kAllocSig
	stw		r16, Block.Signature(r15)


	;	End block

	addi	r15, r17, _pool_page_seg - Block.kEndSize
	lwz		r18, PSA.FirstPoolSeg(r1)
	subf	r18, r15, r18
	stw		r18, Block.OffsetToNext(r15)					; point to next-most-recently-added segment

	lisori	r16, Block.kEndSig
	stw		r16, Block.Signature(r15)

	lwz		r16, PSA.FirstPoolSegLogical(r1)				; vestigial?
	stw		r16, Block.LogiNextSeg(r15)


	;	Add new segment to global singly linked list

	stw		r9, PSA.FirstPoolSegLogical(r1)
	stw		r17, PSA.FirstPoolSeg(r1)


	;	Free the Alloc block and add it to the global doubly linked list

	addi	r8, r17, Block.kBeginSize + Block.Data
	bl		_PoolAddBlockToFreeList


	;	This won't do anything, because there is no other free block in the segment

	bl		_PoolMergeAdjacentFreeBlocks


	;	Return

	mtlr	r14
	blr



;	Check the pool for corruption (dead code)

PoolCheck

	mflr	r19
	lwz		r20, PSA.FirstPoolSeg(r1)


	;	Check this segment, starting with first Allocated block

@next_segment
	addi	r8, r20, Block.kBeginSize
	bl		_PoolCheckBlocks


	;	Get End block

	lwz		r17, Block.OffsetToNext(r20)
	add		r17, r17, r20


	;	Use that to get another Begin block

	lwz		r18, Block.OffsetToNext(r17)
	cmpwi	r18, 0							
	add		r20, r18, r17
	bne		@next_segment


	;	If there are no more Begins, we are done

	mtlr	r19
	blr



;	Only called by the above function
;	Called on data ptrs? Or on block ptrs?

;	ARG		ptr r8

_PoolCheckBlocks

	mflr	r14
	subi	r16, r8, 8		; Block.kBeginSize or Block.Data?

@loop
	lwz		r17, Block.Signature(r16)

	lisori	r18, Block.kEndSig
	cmpw	r17, r18
	li		r9, 0
	beq		@return

	lisori	r18, Block.kAllocSig
	cmpw	r17, r18
	beq		@block_is_allocated

	lisori	r18, Block.kFreeSig
	li		r9, 4
	cmpw	r17, r18
	bne		@block_corrupt

	;	From now we assume Free
	lwz		r17, Block.FreePrev(r16)
	cmpwi	r17, 0
	li		r9, 5
	beq		@block_corrupt

	lwz		r17, Block.FreeNext(r16)
	cmpwi	r17, 0
	li		r9, 6
	beq		@block_corrupt

@block_is_allocated
;or block is free (fallthru)
	lwz		r17, Block.OffsetToNext(r16)
	add		r16, r16, r17
	cmpwi	r17, 0
	li		r9, 7
	bgt		@loop


	;	4: neither Allocated nor Free
	;	5: Free with bad FreePrev ptr
	;	6: Free with bad FreeNext ptr
	;	7: bad OffsetToNext ptr

@block_corrupt
	mr		r18, r8
	_log	'Heap segment corrupt '
	mr		r8, r9
	bl		Printd
	_log	'at '
	mr		r8, r16
	bl		Printw
	_log	'^n'


	;	Dump some memory

	subi	r16, r16, 64
	li		r17, 8				; 8 lines, 16 bytes each

@dump_next_line
	mr		r8, r16
	bl		Printw

	_log	' '

	lwz		r8, 0(r16)
	bl		Printw
	lwz		r8, 4(r16)
	bl		Printw
	lwz		r8, 8(r16)
	bl		Printw
	lwz		r8, 12(r16)
	bl		Printw

	_log	'  *'

	li		r8, 16
	subi	r16, r16, 1
	mtctr	r8

@dump_next_char
	lbzu	r8, 1(r16)

	cmpwi	r8, ' '
	bgt		@dont_use_space
	li		r8, ' '
@dont_use_space

	bl		Printc
	bdnz	@dump_next_char

	_log	'*^n'

	subi	r17, r17, 1
	addi	r16, r16, 1
	cmpwi	r17,  0x00
	bne		@dump_next_line


	mr		r8, r18


@return
	mtlr	r14
	blr
