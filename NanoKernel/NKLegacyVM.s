;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKExceptions
;	    IntReturn
;	  NKPaging
;	    PopulateHTAB
;	EXPORTS:
;	  EditPTEInHTAB (=> NKMPCalls)
;	  GetPARPageInfo (=> NKMPCalls)
;	  VMSecondLastExportedFunc (=> NKMPCalls)
;	  kcVMDispatch (=> NKInit)


MaxVMCallCount		equ		26



	MACRO
	DeclareVMCall	&n, &code

@h
	org				VMDispatchTable + &n * 2
	dc.w			&code - NKTop - &n * 2

	org				@h

	ENDM



;	Accessed ONLY via Sup table

KCallVMDispatch	;	OUTSIDE REFERER

	stw		r7, KDP.Flags(r1)
	lwz		r7, KDP.PA_NanoKernelCode(r1)
	cmplwi	r3, MaxVMCallCount
	insrwi	r7, r3, 7, 24
	lhz		r8, VMDispatchTable - NKTop(r7)
	lwz		r9, KDP.VMLogicalPages(r1)
	add		r8, r8, r7
	mtlr	r8

	lwz		r6, EWA.r6(r1)
	stw		r14, EWA.r14(r1)
	stw		r15, EWA.r15(r1)
	stw		r16, EWA.r16(r1)

	bltlr
	b		VMReturnMinus1

VMDispatchTable
	dcb.w	MaxVMCallCount, 0



;	UNIMPLEMENTED kcVMDispatch selectors:

;	VMUnInit: 'un-init the MMU virtual space'

	DeclareVMCall			1, VMReturn


;	VMFinalInit: 'last chance to init after new memory dispatch is installed'

	DeclareVMCall			2, VMReturn


;	VMGetPhysicalAddress: 'return phys address given log page (can be different from above!)'
;	('above' means VMGetPhysicalPage)

	DeclareVMCall			11, VMReturnMinus1


;	VMReload: 'reload the ATC with specified page'

	DeclareVMCall			13, VMReturn


;	VMFlushAddressTranslationCache: 'just do it'

	DeclareVMCall			14, VMReturn


;	VMFlushDataCache: 'wack the data cache'

	DeclareVMCall			15, VMReturn


;	VMFlushCodeCache: 'wack the code cache'

	DeclareVMCall			16, VMReturn




;	                        VMReturn                        

;	VMGetPhysicalAddress_one

VMReturnMinus1	;	OUTSIDE REFERER
	li		r3, -0x01
	b		VMReturn

VMReturn0	;	OUTSIDE REFERER
	li		r3,  0x00
	b		VMReturn

VMReturn1	;	OUTSIDE REFERER
	li		r3,  0x01

VMReturn	;	OUTSIDE REFERER
	lwz		r14, EWA.r14(r1)
	lwz		r15, EWA.r15(r1)
	lwz		r16, EWA.r16(r1)
	lwz		r7, KDP.Flags(r1)
	lwz		r6, KDP.PA_ContextBlock(r1)
	b		IntReturn



;	'init the MMU virtual space'

	DeclareVMCall	0, VMInit

VMInit	;	OUTSIDE REFERER
	lwz		r7, KDP.PARPageListPtr(r1)			; check that zero seg isn't empty
	lwz		r8, KDP.PARPerSegmentPLEPtrs + 0(r1)
	cmpw	r7, r8
	bne		VMReturn1

	stw		r4, KDP.VMLogicalPages(r1)	; resize PAR

	stw		r5, KDP.PARPageListPtr(r1)			; where did NK find this???

	lwz		r6,  0x05e8(r1)
	li		r5,  0x00
	li		r4,  0x00

VMInit_BigLoop
	lwz		r8,  0x0000(r6)
	addi	r6, r6,  0x08
	lhz		r3,  0x0000(r8)
	lhz		r7,  0x0002(r8)
	lwz		r8,  0x0004(r8)
	addi	r7, r7,  0x01
	cmpwi	cr1, r3,  0x00
	andi.	r3, r8,  0xc00
	cmpwi	r3,  0xc00
	bne		VMInit_0x110
	bnel	cr1, SystemCrash
	rlwinm	r15, r8, 22,  0, 29
	addi	r3, r1, KDP.PARPerSegmentPLEPtrs
	rlwimi	r3, r5,  2, 28, 29
	stw		r15,  0x0000(r3)
	slwi	r3, r5, 16
	cmpw	r3, r4
	bnel	SystemCrash

VMInit_0xa8
	lwz		r16,  0x0000(r15)
	addi	r7, r7, -0x01
	andi.	r3, r16,  0x01
	beql	SystemCrash
	andi.	r3, r16,  0x800
	beq		VMInit_0x100
	lwz		r14, KDP.HTABORG(r1)
	rlwinm	r3, r16, 23,  9, 28
	lwzux	r8, r14, r3
	lwz		r9,  0x0004(r14)
	andis.	r3, r8,  0x8000
	beql	SystemCrash
	andi.	r3, r9,  0x03
	cmpwi	r3,  0x00
	beql	SystemCrash
	rlwinm	r3, r16, 17, 22, 31
	rlwimi	r3, r8, 10, 16, 21
	rlwimi	r3, r8, 21, 12, 15
	cmpw	r3, r4
	bnel	SystemCrash
;	bl		RemovePageFromTLB
	bl		RemovePTEFromHTAB

VMInit_0x100
	cmpwi	r7,  0x00
	addi	r15, r15,  0x04
	addi	r4, r4,  0x01
	bne		VMInit_0xa8

VMInit_0x110
	addi	r5, r5,  0x01
	cmpwi	r5, 4
	bne		VMInit_BigLoop



	lwz		r7, KDP.TotalPhysicalPages(r1)
	cmpw	r4, r7
	bnel	SystemCrash
	lwz		r5,  KDP.PARPageListPtr(r1)
	lwz		r4, KDP.VMLogicalPages(r1)
	andi.	r7, r5,  0xfff

	li		r3,  0x02
	bne		VMInit_Fail

	lis		r7, 4
	cmplw	r7, r4

	li		r3,  0x03
	blt		VMInit_Fail

	addi	r7, r4,  0x3ff
	srwi	r6, r7, 10
	srwi	r8, r5, 12
	add		r8, r8, r6
	lwz		r9, KDP.TotalPhysicalPages(r1)
	cmplw	r8, r9

	li		r3,  0x04
	bgt		VMInit_Fail

	cmplw	r4, r9

	li		r3,  0x05
	blt		VMInit_Fail

	srwi	r7, r5, 12
	bl		major_0x09c9c
	stw		r9,  KDP.PARPageListPtr(r1)
	mr		r15, r9
	srwi	r7, r5, 12
	add		r7, r7, r6
	addi	r7, r7, -0x01
	bl		major_0x09c9c
	subf	r9, r15, r9
	srwi	r9, r9, 12
	addi	r9, r9,  0x01
	cmpw	r9, r6

	li		r3,  0x06
	bne		VMInit_Fail

	stw		r4, KDP.VMLogicalPages(r1)
	slwi	r7, r4, 12
	stw		r7, KDP.SysInfo.LogicalMemorySize(r1) ; bug in NKv2??
	slwi	r7, r4,  2
	li		r8,  0x00

VMInit_0x1d4
	subi	r7, r7, 4
	cmpwi	r7,  0x00
	stwx	r8, r15, r7
	bne		VMInit_0x1d4
	lwz		r7, KDP.TotalPhysicalPages(r1)
	slwi	r6, r7,  2

VMInit_0x1ec
	subi	r6, r6, 4
	srwi	r7, r6,  2
	bl		major_0x09c9c
	cmpwi	r6,  0x00
	ori		r16, r9,  0x21
	stwx	r16, r15, r6
	bne		VMInit_0x1ec
	lwz		r15,  KDP.PARPageListPtr(r1)
	srwi	r7, r5, 10
	add		r15, r15, r7
	lwz		r5, KDP.VMLogicalPages(r1)

VMInit_0x218
	lwz		r16,  0x0000(r15)
	andi.	r7, r16,  0x01
	beql	SystemCrash
	ori		r16, r16,  0x404
	stw		r16,  0x0000(r15)
	addi	r5, r5, -0x400
	cmpwi	r5,  0x00
	addi	r15, r15,  0x04
	bgt		VMInit_0x218
	lwz		r6,  0x05e8(r1)
	li		r9, 0
	ori		r7, r9,  0xffff
	li		r8,  0xa00

VMInit_0x250
	lwz		r3,  0x0000(r6)
	addi	r6, r6,  0x08
	stw		r7,  0x0000(r3)
	stw		r8,  0x0004(r3)
	stw		r7,  0x0008(r3)
	stw		r8,  0x000c(r3)
	addi	r9, r9, 1
	cmpwi	r9, 3
	ble		VMInit_0x250
	lwz		r6,  0x05e8(r1)
	lwz		r9, KDP.VMLogicalPages(r1)
	lwz		r15,  KDP.PARPageListPtr(r1)

VMInit_0x288
	lwz		r8,  0x0000(r6)
	lis		r7,  0x01
	rlwinm.	r3, r9, 16, 16, 31
	bne		VMInit_0x29c
	mr		r7, r9

VMInit_0x29c
	subf.	r9, r7, r9
	addi	r7, r7, -0x01
	stw		r7,  0x0000(r8)
	rlwinm	r7, r15, 10, 22, 19
	ori		r7, r7,  0xc00
	stw		r7,  0x0004(r8)
	addis	r15, r15,  0x04
	addi	r6, r6,  0x08
	bne		VMInit_0x288

	b		VMReturn0

VMInit_Fail
	lwz		r7, KDP.TotalPhysicalPages(r1)
	lwz		r8, KDP.PARPerSegmentPLEPtrs + 0(r1)
	stw		r7, KDP.VMLogicalPages(r1)
	stw		r8, KDP.PARPageListPtr(r1)

	b		VMReturn



;	'exchange physical page contents'

	DeclareVMCall	12, VMExchangePages

VMExchangePages	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bge		cr4, VMReturnMinus1
	bgt		cr5, VMReturnMinus1
	bns		cr7, VMReturnMinus1
	bgt		cr6, VMReturnMinus1
	bne		cr6, VMReturnMinus1
;	bltl	cr5, RemovePageFromTLB
	bltl	cr5, RemovePTEFromHTAB
	mr		r6, r15
	mr		r4, r5
	mr		r5, r16
	lwz		r9, KDP.VMLogicalPages(r1)
	bl		GetPARPageInfo
	bge		cr4, VMReturnMinus1
	bgt		cr5, VMReturnMinus1
	bns		cr7, VMReturnMinus1
	bgt		cr6, VMReturnMinus1
	bne		cr6, VMReturnMinus1
;	bltl	cr5, RemovePageFromTLB
	bltl	cr5, RemovePTEFromHTAB
	stw		r5,  0x0000(r15)
	stw		r16,  0x0000(r6)
	rlwinm	r4, r5,  0,  0, 19
	rlwinm	r5, r16,  0,  0, 19
	li		r9,  0x1000
	li		r6,  0x04

VMExchangePages_0x68
	subf.	r9, r6, r9
	lwzx	r7, r4, r9
	lwzx	r8, r5, r9
	stwx	r7, r5, r9
	stwx	r8, r4, r9
	bne		VMExchangePages_0x68
	b		VMReturn



;	'return phys page given log page'

	DeclareVMCall	10, VMGetPhysicalPage

VMGetPhysicalPage	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bns		cr7, VMReturnMinus1
	srwi	r3, r9, 12
	b		VMReturn



;	'given a page, get its 68K PTE'

	DeclareVMCall	19, getPTEntryGivenPage

getPTEntryGivenPage	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	mr		r3, r16
	bns		cr7, VMReturn
	rlwimi	r3, r9,  0,  0, 19
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCall	5, VMIsInited

VMIsInited	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bso		cr7, VMReturn1
	rlwinm	r3, r16, 16, 31, 31
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCall	3, VMIsResident

VMIsResident	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	clrlwi	r3, r16,  0x1f
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCall	4, VMIsUnmodified

VMIsUnmodified	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	rlwinm	r3, r16, 28, 31, 31
	xori	r3, r3,  0x01
	b		VMReturn



;	Cube-E has no comment

	DeclareVMCall	22, VMLRU

VMLRU	;	OUTSIDE REFERER
	rlwinm.	r9, r9,  2,  0, 29
	lwz		r15,  KDP.PARPageListPtr(r1)
	lwz		r14, KDP.HTABORG(r1)
	add		r15, r15, r9
	srwi	r4, r9,  2
	li		r5,  0x100
	li		r6,  0x08

VMLRU_0x1c
	lwzu	r16, -0x0004(r15)
	addi	r4, r4, -0x01
	mtcr	 r16
	cmpwi	r4,  0x00
	rlwinm	r7, r16, 23,  9, 28
	bns		cr7, VMLRU_0x5c
	bge		cr5, VMLRU_0x50
	add		r14, r14, r7
	lwz		r9, 4(r14)
	rlwimi	r16, r9, 27, 28, 28
	andc	r9, r9, r5
	bl		EditPTEOnlyInHTAB
	subf	r14, r7, r14

VMLRU_0x50
	rlwimi	r16, r16,  6, 22, 22
	andc	r16, r16, r6
	stw		r16,  0x0000(r15)

VMLRU_0x5c
	bne		VMLRU_0x1c
	b		VMReturn



;	'make it so'

	DeclareVMCall	17, VMMakePageCacheable

VMMakePageCacheable	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	rlwinm	r7, r16,  0, 25, 26
	cmpwi	r7,  0x20
	bns		cr7, VMReturnMinus1
	beq		VMReturn
	bge		cr4, VMReturnMinus1
	bgel	cr5, VMSecondLastExportedFunc
	rlwinm	r16, r16,  0, 27, 24
	rlwinm	r9, r9,  0, 27, 24
	ori		r16, r16,  0x20
	bl		EditPTEInHTAB
	b		VMReturn



;	Cube-E has no comment

	DeclareVMCall	24, VMMakePageWriteThrough

VMMakePageWriteThrough	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	rlwinm.	r7, r16,  0, 25, 26
	bns		cr7, VMReturnMinus1
	beq		VMReturn
	bge		cr4, VMMakePageWriteThrough_0x3c
	bgel	cr5, VMSecondLastExportedFunc
	rlwinm	r16, r16,  0, 27, 24
	rlwinm	r9, r9,  0, 27, 24
	ori		r9, r9,  0x40
	bl		EditPTEInHTAB
	b		VMMakePageNonCacheable_0x3c

VMMakePageWriteThrough_0x3c
	rlwinm	r7, r4, 16, 28, 31
	cmpwi	r7,  0x09
	blt		VMReturnMinus1
	ble		cr6, VMReturnMinus1
	lwz		r5,  0x000c(r15)
	andi.	r6, r5,  0xe01
	cmpwi	r6,  0xa01
	beq		VMMakePageWriteThrough_0xec
	addi	r15, r15, -0x08
	lwz		r5,  0x0004(r15)
	lhz		r6,  0x0000(r15)
	andi.	r5, r5,  0xc00
	lhz		r5,  0x0002(r15)
	bne		VMReturnMinus1
	addi	r5, r5,  0x01
	add		r6, r6, r5
	xor		r6, r6, r4
	andi.	r6, r6,  0xffff
	bne		VMReturnMinus1
	sth		r5,  0x0002(r15)
	b		PageSetCommon

VMMakePageWriteThrough_0xec
	lwz		r5,  0x0000(r15)
	lwz		r6,  0x0004(r15)
	stw		r5,  0x0008(r15)
	stw		r6,  0x000c(r15)
	slwi	r5, r4, 16
	stw		r5,  0x0000(r15)
	slwi	r5, r4, 12
	ori		r5, r5,  0x42
	stw		r5,  0x0004(r15)



;	                     PageSetCommon                      

PageSetCommon	;	OUTSIDE REFERER
	lwz		r15, KDP.PTEGMask(r1)
	lwz		r14, KDP.HTABORG(r1)
	slwi	r6, r4, 12
	mfsrin	r6, r6
	rlwinm	r8, r6,  7,  0, 20
	xor		r6, r6, r4
	slwi	r7, r6,  6
	and		r15, r15, r7
	rlwimi	r8, r4, 22, 26, 31
	crset	cr0_eq
	oris	r8, r8,  0x8000

PageSetCommon_0x2c
	lwzux	r7, r14, r15
	lwz		r15,  0x0008(r14)
	lwz		r6,  0x0010(r14)
	lwz		r5,  0x0018(r14)
	cmplw	cr1, r7, r8
	cmplw	cr2, r15, r8
	cmplw	cr3, r6, r8
	cmplw	cr4, r5, r8
	beq		cr1, PageSetCommon_0xc8
	beq		cr2, PageSetCommon_0xc4
	beq		cr3, PageSetCommon_0xc0
	beq		cr4, PageSetCommon_0xbc
	lwzu	r7,  0x0020(r14)
	lwz		r15,  0x0008(r14)
	lwz		r6,  0x0010(r14)
	lwz		r5,  0x0018(r14)
	cmplw	cr1, r7, r8
	cmplw	cr2, r15, r8
	cmplw	cr3, r6, r8
	cmplw	cr4, r5, r8
	beq		cr1, PageSetCommon_0xc8
	beq		cr2, PageSetCommon_0xc4
	beq		cr3, PageSetCommon_0xc0
	beq		cr4, PageSetCommon_0xbc
	crnot	2, 2
	lwz		r15, KDP.PTEGMask(r1)
	lwz		r14, KDP.HTABORG(r1)
	slwi	r6, r4, 12
	mfsrin	r6, r6
	xor		r6, r6, r4
	not		r6, r6
	slwi	r7, r6,  6
	and		r15, r15, r7
	xori	r8, r8,  0x40
	bne		PageSetCommon_0x2c
	b		VMReturn

PageSetCommon_0xbc
	addi	r14, r14,  0x08

PageSetCommon_0xc0
	addi	r14, r14,  0x08

PageSetCommon_0xc4
	addi	r14, r14,  0x08

PageSetCommon_0xc8
;	bl		RemovePageFromTLB
	li		r8,  0x00
	li		r9,  0x00
	bl		EditLowerPTEOnlyInHTAB
	b		VMReturn



;	'make it so'

	DeclareVMCall	18, VMMakePageNonCacheable

VMMakePageNonCacheable	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	rlwinm	r7, r16,  0, 25, 26
	cmpwi	r7,  0x60
	bns		cr7, VMReturnMinus1
	beq		VMReturn
	bge		cr4, VMReturnMinus1
	bgel	cr5, VMSecondLastExportedFunc
	rlwinm	r9, r9,  0, 27, 24
	ori		r16, r16,  0x60
	ori		r9, r9,  0x20
	bl		EditPTEInHTAB

VMMakePageNonCacheable_0x3c	;	OUTSIDE REFERER
	rlwinm	r4, r9,  0,  0, 19
	addi	r5, r4, 0x20
	li		r7,  0x1000
	li		r8, 0x40

VMMakePageNonCacheable_0x50
	subf.	r7, r8, r7
	dcbf	r7, r4
	dcbf	r7, r5
	bne		VMMakePageNonCacheable_0x50
	b		VMReturn



;	'set page status'

	DeclareVMCall	8, VMMarkBacking

VMMarkBacking	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bge		cr4, VMReturnMinus1
	bgt		cr5, VMReturnMinus1
	bltl	cr5, RemovePTEFromHTAB
	rlwimi	r16, r5, 16, 15, 15
	li		r7,  0x01
	andc	r16, r16, r7
	stw		r16,  0x0000(r15)
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCall	9, VMMarkCleanUnused

VMMarkCleanUnused	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bge		cr4, VMReturnMinus1
	bns		cr7, VMReturnMinus1
	bgel	cr5, VMSecondLastExportedFunc
	li		r7,  0x180
	andc	r9, r9, r7
	ori		r16, r16,  0x100
	bl		EditPTEInHTAB
	b		VMReturn



;	Cube-E has no comment

	DeclareVMCall	23, VMMarkUndefined

VMMarkUndefined	;	OUTSIDE REFERER
	cmplw	r4, r9
	cmplw	cr1, r5, r9
	add		r7, r4, r5
	cmplw	cr2, r7, r9
	bge		VMReturnMinus1
	bgt		cr1, VMReturnMinus1
	bgt		cr2, VMReturnMinus1
	lwz		r15,  KDP.PARPageListPtr(r1)
	slwi	r8, r7,  2
	li		r7,  0x01

VMMarkUndefined_0x28
	subi	r8, r8, 4
	subf.	r5, r7, r5
	lwzx	r16, r15, r8
	blt		VMReturn
	rlwimi	r16, r6,  7, 24, 24
	stwx	r16, r15, r8
	b		VMMarkUndefined_0x28



;	'set page status'

	DeclareVMCall	7, VMMarkResident

VMMarkResident	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bge		cr4, VMReturnMinus1
	bso		cr7, VMReturnMinus1
	bltl	cr5, SystemCrash
	rlwimi	r16, r5, 12,  0, 19
	ori		r16, r16,  0x01
	stw		r16,  0x0000(r15)
	bl		VMSecondLastExportedFunc
	bl		EditPTEInHTAB
	b		VMReturn



;	'ask why we got this page fault'

	DeclareVMCall	21, VMPTest

VMPTest	;	OUTSIDE REFERER
	srwi	r4, r4, 12
	cmplw	r4, r9
	li		r3,  0x4000
	bge		VMReturn
	bl		GetPARPageInfo
	li		r3,  0x400
	bns		cr7, VMReturn
	li		r3,  0x00
	ori		r3, r3,  0x8000
	ble		cr7, VMReturn
	cmpwi	r6,  0x00
	beq		VMReturn
	li		r3,  0x800
	b		VMReturn



;	'given a page & 68K pte, set the real PTE'

	DeclareVMCall	20, setPTEntryGivenPage

setPTEntryGivenPage	;	OUTSIDE REFERER
	mr		r6, r4
	mr		r4, r5
	bl		GetPARPageInfo
	bge		cr4, VMReturnMinus1
	xor		r7, r16, r6
	li		r3,  0x461
	rlwimi	r3, r16, 24, 29, 29
	and.	r3, r3, r7
	bne		VMReturnMinus1
	andi.	r7, r7,  0x11c
	xor		r16, r16, r7
	stw		r16,  0x0000(r15)
	bge		cr5, VMReturn
	rlwimi	r9, r16,  5, 23, 23
	rlwimi	r9, r16,  3, 24, 24
	rlwimi	r9, r16, 30, 31, 31
	bl		EditPTEOnlyInHTAB
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCall	6, VMShouldClean

VMShouldClean	;	OUTSIDE REFERER
	bl		GetPARPageInfo
	bns		cr7, VMReturn0
	blt		cr7, VMReturn0
	bns		cr6, VMReturn0
	bge		cr4, VMReturnMinus1
	xori	r16, r16,  0x10
	ori		r16, r16,  0x100
	stw		r16,  0x0000(r15)
	bge		cr5, VMReturn1
	xori	r9, r9,  0x80
	bl		EditPTEOnlyInHTAB
	b		VMReturn1



;	Cube-E has no comment

	DeclareVMCall	25, VMAllocateMemory

VMAllocateMemory	;	OUTSIDE REFERER
	lwz		r7,  KDP.PARPageListPtr(r1)
	lwz		r8, KDP.PARPerSegmentPLEPtrs + 0(r1)
	cmpwi	cr6, r5,  0x00
	cmpw	cr7, r7, r8
	or		r7, r4, r6
	rlwinm.	r7, r7,  0,  0, 11
	ble		cr6, VMReturnMinus1
	lwz		r9, KDP.VMLogicalPages(r1)
	bne		cr7, VMReturnMinus1
	mr		r7, r4
	bne		VMReturnMinus1
	mr		r4, r9
	slwi	r6, r6, 12
	addi	r5, r5, -0x01

VMAllocateMemory_0x74
	addi	r4, r4, -0x01
	bl		GetPARPageInfo
	bltl	cr5, RemovePTEFromHTAB
	lwz		r9, KDP.VMLogicalPages(r1)
	subf	r8, r4, r9
	cmplw	cr7, r5, r8
	and.	r8, r16, r6
	bge		cr7, VMAllocateMemory_0x74
	bne		VMAllocateMemory_0x74
	cmpwi	cr6, r6,  0x00
	beq		cr6, VMAllocateMemory_0xc0
	slwi	r8, r5,  2
	lwzx	r8, r15, r8
	slwi	r14, r5, 12
	add		r14, r14, r16
	xor		r8, r8, r14
	rlwinm.	r8, r8,  0,  0, 19
	bne		VMAllocateMemory_0x74

VMAllocateMemory_0xc0
	lis		r9, 4
	cmplw	cr7, r7, r9
	rlwinm.	r9, r7,  0,  0, 11
	blt		cr7, VMReturnMinus1
	bne		VMReturnMinus1
	lwz		r14,  0x05e8(r1)
	rlwinm	r9, r7, 19, 25, 28
	lwzx	r14, r14, r9
	clrlwi	r9, r7,  0x10
	lhz		r8,  0x0000(r14)
	b		VMAllocateMemory_0xf4

VMAllocateMemory_0xf0
	lhzu	r8,  0x0008(r14)

VMAllocateMemory_0xf4
	lhz		r16,  0x0002(r14)
	subf	r8, r8, r9
	cmplw	cr7, r8, r16
	bgt		cr7, VMAllocateMemory_0xf0
	add		r8, r8, r5
	cmplw	cr7, r8, r16
	bgt		cr7, VMReturnMinus1
	lwz		r16,  0x0004(r14)
	slwi	r8, r7, 16
	andi.	r16, r16,  0xe01
	cmpwi	r16,  0xa01
	or		r8, r8, r5
	addi	r5, r5,  0x01
	bne		VMReturnMinus1
	stw		r8,  0x0000(r14)
	bnel	cr6, VMAllocateMemory_0x2e8
	rotlwi	r15, r15,  0x0a
	ori		r15, r15,  0xc00
	stw		r15,  0x0004(r14)
	lwz		r7, KDP.TotalPhysicalPages(r1)
	subf	r7, r5, r7
	stw		r7, KDP.TotalPhysicalPages(r1)
	stw		r7, KDP.VMLogicalPages(r1)
	slwi	r8, r7, 12
	stw		r8, KDP.SysInfo.UsableMemorySize(r1)
	stw		r8, KDP.SysInfo.LogicalMemorySize(r1)

	addi	r14, r1, 120
	lwz		r15,  KDP.PARPageListPtr(r1)
	li		r8, 0
	addi	r7, r7, -0x01
	ori		r8, r8, 0xffff

VMAllocateMemory_0x34c
	cmplwi	r7,  0xffff
	lwzu	r16,  0x0008(r14)
	rotlwi	r9, r15,  0x0a
	ori		r9, r9,  0xc00
	stw		r8,  0x0000(r16)
	stw		r9,  0x0004(r16)
	addis	r15, r15,  0x04
	addis	r7, r7, -0x01
	bgt		VMAllocateMemory_0x34c
	sth		r7,  0x0002(r16)
	b		VMReturn1



VMAllocateMemory_0x2e8
	lwz		r16,  0x0000(r15)
	lwz		r7, KDP.TotalPhysicalPages(r1)
	lwz		r8,  KDP.PARPageListPtr(r1)
	slwi	r7, r7,  2
	add		r7, r7, r8
	slwi	r8, r5,  2
	subf	r7, r8, r7
	cmplw	r15, r7
	beqlr	
	subi	r7, r7, 4

VMAllocateMemory_0x310
	lwzx	r9, r15, r8
	cmplw	r15, r7
	stw		r9,  0x0000(r15)
	addi	r15, r15,  0x04
	blt		VMAllocateMemory_0x310

VMAllocateMemory_0x324
	cmpwi	r8,  0x04
	subi	r8, r8, 4
	stwu	r16,  0x0004(r7)
	addi	r16, r16,  0x1000
	bgt		VMAllocateMemory_0x324
	blr		



;This function gets sent an page# for a page in the main mac os memory area and returns a bunch of useful info on it.
;Return values that mention HTAB are undefined when the PTE is not in the HTAB
;HTAB residence is determined by bit 20 (value 0x800) of the PTE. This is often checked by a bltl cr5

;	ARG		page# r4, KDP.VMMaxVirtualPages r9,
;	RET		PTE_flags CR, HTAB_upper r8, HTAB_lower r9, PTE_value r16, HTAB_entry_loc r14, PTE_loc r15, 


GetPARPageInfo	;	OUTSIDE REFERER
	cmplw	cr4, r4, r9	;r9 is VMMaxVirtualPages by convention
	lwz		r15,  KDP.PARPageListPtr(r1)
	slwi	r8, r4,  2
	bge		cr4, GetPARPageInfo_0x40

GetPARPageInfo_0x10
	lwzux	r16, r15, r8	;get PTE from KDP.FlatPageListPointer
	lwz		r14,  KDP.HTABORG(r1)
	mtcrf	 0x07, r16	;copy bits 20-31 to cr
	rlwinm	r8, r16, 23,  9, 28;convert page# into an index
	rlwinm	r9, r16,  0,  0, 19;get unshifted page#
	bgelr	cr5		;return if PTE is not in HTAB
	bns		cr7, SystemCrash;panic if the PTE is in the HTAB but isn't mapped to a real page
	lwzux	r8, r14, r8	;get first word of PTE from HTAB
	lwz		r9,  0x0004(r14);get second word of PTE from HTAB
	mtcrf	 0x80, r8
	rlwimi	r16, r9, 29, 27, 27
	rlwimi	r16, r9, 27, 28, 28
	mtcrf	0x07, r16
	bltlr			;return if PTE is valid
	bl		SystemCrash;panic if PTE isn't valid but is in the HTAB

GetPARPageInfo_0x40	;some kind of little-used code path for when VMMaxVirtualPages is invalid? ROM overlay?
	lis		r9, 4
	cmplw	cr4, r4, r9
	rlwinm.	r9, r4,  0,  0, 11
	blt		cr4, VMReturnMinus1;return failure if r4<VMMaxVirtualPages
	bne		VMReturnMinus1	;return failure if bits 0-11 of r4 are non-zero
	lwz		r15,  0x05e8(r1);this appears to be an array of 8-byte structures.
	rlwinm	r9, r4, 19, 25, 28;copy bits 12-15 or r4 to bits 25-28 of r9
	lwzx	r15, r15, r9	;do an index for some reason
	clrlwi	r9, r4,  0x10	;copy bits 16-31 to r9
	lhz		r8,  0x0000(r15)
	b		GetPARPageInfo_0x70

GetPARPageInfo_0x6c
	lhzu	r8,  0x0008(r15)

GetPARPageInfo_0x70
	lhz		r16,  0x0002(r15)
	subf	r8, r8, r9
	cmplw	cr4, r8, r16
	bgt		cr4, GetPARPageInfo_0x6c
	lwz		r9,  0x0004(r15)
	andi.	r16, r9,  0xc00
	cmpwi	cr6, r16,  0x400
	cmpwi	cr7, r16,  0xc00
	beq		GetPARPageInfo_0xac
	beq		cr6, GetPARPageInfo_0xb4
	bne		cr7, VMReturnMinus1
	slwi	r8, r8,  2
	rlwinm	r15, r9, 22,  0, 29
	crset	cr4_lt
	b		GetPARPageInfo_0x10

GetPARPageInfo_0xac
	slwi	r8, r8, 12
	add		r9, r9, r8

GetPARPageInfo_0xb4
	rlwinm	r16, r9,  0,  0, 19
	crclr	cr4_lt
	rlwinm	r9, r9,  0, 22, 19
	rlwimi	r16, r9,  1, 25, 25
	rlwimi	r16, r9, 31, 26, 26
	xori	r16, r16,  0x20
	rlwimi	r16, r9, 29, 27, 27
	rlwimi	r16, r9, 28, 28, 28
	rlwimi	r16, r9,  2, 29, 29
	ori		r16, r16,  0x01
	mtcrf	 0x07, r16
	blr		



;updates stored PTE and HTAB entry for PTE
;r16 is PTE value
;r15 is address of stored PTE
;r8 is lower word of HTAB entry
;r9 is upper word of HTAB entry
;r14 is address of HTAB entry
EditPTEInHTAB	;	OUTSIDE REFERER
	stw		r16,  0x0000(r15)
;just updates HTAB entry
EditLowerPTEOnlyInHTAB
	stw		r8,  0x0000(r14)
EditPTEOnlyInHTAB	;	OUTSIDE REFERER
	stw		r9,  0x0004(r14);upper word of HTAB entry contains valid bit
	slwi	r8, r4, 12
	sync
	tlbie	r8
	sync	
	blr



;Removes a page from the HTAB.
;Called right after GetPARPageInfo, with either a bl or a bltl cr5
;
;also updates NK statistics?
;r9 is low word of HTAB entry
;r14 ia address of HTAB entry
;r15 is address of stored PTE
;r16 is PTE value
RemovePTEFromHTAB	;	OUTSIDE REFERER
	lwz		r8, KDP.NKInfo.HashTableDeleteCount(r1);update a value in NanoKernelInfo
	rlwinm	r16, r16,  0, 21, 19	;update PTE flags to indicate not in HTAB
	addi	r8, r8,  0x01
	stw		r8, KDP.NKInfo.HashTableDeleteCount(r1)
	rlwimi	r16, r9,  0,  0, 19	;move page# back into PTE

	_InvalNCBPointerCache scratch=r8

	li		r8,  0x00	;0 upper HTAB word
	li		r9,  0x00	;0 lower HTAB word
	b		EditPTEInHTAB	;update stored PTE and invalidate HTAB entry

VMSecondLastExportedFunc	;	OUTSIDE REFERER
	lwz		r8, KDP.PTEGMask(r1)



;	                   VMLastExportedFunc                   


VMLastExportedFunc
	lwz		r14, KDP.HTABORG(r1)
	slwi	r9, r4, 12
	mfsrin	r6, r9
	xor		r9, r6, r4
	slwi	r7, r9,  6
	and		r8, r8, r7
	lwzux	r7, r14, r8
	lwz		r8,  0x0008(r14)
	lwz		r9,  0x0010(r14)
	lwz		r5,  0x0018(r14)
	cmpwi	r7,  0x00
	cmpwi	cr1, r8,  0x00
	cmpwi	cr2, r9,  0x00
	cmpwi	cr3, r5,  0x00
	bge		VMLastExportedFunc_0x87
	bge		cr1, VMLastExportedFunc_0x83
	bge		cr2, VMLastExportedFunc_0x7f
	bge		cr3, VMLastExportedFunc_0x7b
	lwzu	r7,  0x0020(r14)
	lwz		r8,  0x0008(r14)
	lwz		r9,  0x0010(r14)
	lwz		r5,  0x0018(r14)
	cmpwi	r7,  0x00
	cmpwi	cr1, r8,  0x00
	cmpwi	cr2, r9,  0x00
	cmpwi	cr3, r5,  0x00
	bge		VMLastExportedFunc_0x87
	bge		cr1, VMLastExportedFunc_0x83
	bge		cr2, VMLastExportedFunc_0x7f
	blt		cr3, VMLastExportedFunc_0xd7

VMLastExportedFunc_0x7b
	addi	r14, r14,  0x08

VMLastExportedFunc_0x7f
	addi	r14, r14,  0x08

VMLastExportedFunc_0x83
	addi	r14, r14,  0x08

VMLastExportedFunc_0x87
	lwz		r9, KDP.NKInfo.HashTableCreateCount(r1)
	rlwinm	r8, r6,  7,  1, 24
	addi	r9, r9,  0x01
	stw		r9, KDP.NKInfo.HashTableCreateCount(r1)
	rlwimi	r8, r4, 22, 26, 31
	lwz		r9, KDP.PageAttributeInit(r1)
	oris	r8, r8,  0x8000
	rlwimi	r9, r16,  0,  0, 19
	rlwimi	r9, r16, 5, 23, 23
	rlwimi	r9, r16,  3, 24, 24
	rlwimi	r9, r16, 31, 26, 26
	rlwimi	r9, r16,  1, 25, 25
	xori	r9, r9,  0x40
	rlwimi	r9, r16, 30, 31, 31
	lwz		r7, KDP.HTABORG(r1)
	ori		r16, r16,  0x801
	subf	r7, r7, r14
	rlwimi	r16, r7,  9,  0, 19
	blr		

VMLastExportedFunc_0xd7
	mr		r7, r27
	mr		r8, r29
	mr		r9, r30
	mr		r5, r31
	mr		r16, r28
	mr		r14, r26
	mflr	r6
	slwi	r27, r4, 12
	bl		PopulateHTAB
	bnel	SystemCrash
	mr		r27, r7
	mr		r29, r8
	mr		r30, r9
	mr		r31, r5
	mr		r28, r16
	mr		r26, r14
	mtlr	r6
	lwz		r9, KDP.VMLogicalPages(r1)
	b		GetPARPageInfo



;	                     major_0x09c9c                      

major_0x09c9c	;	OUTSIDE REFERER
	addi	r8, r1, KDP.PARPerSegmentPLEPtrs
	lwz		r9, KDP.TotalPhysicalPages(r1)
	rlwimi	r8, r7, 18, 28, 29
	cmplw	r7, r9
	lwz		r8,  0x0000(r8)
	rlwinm	r7, r7,  2, 14, 29
	bge		VMReturnMinus1
	lwzx	r9, r8, r7
	rlwinm	r9, r9,  0,  0, 19
	blr		
