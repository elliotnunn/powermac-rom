Local_Panic		set		*
				b		panic



	align		5



MaxVMCallCount		equ		26



	MACRO
	DeclareVMCall	&n, &code

@h
	org				VMDispatchMainTable + &n * 4
	dc.l			&code - NKTop - &n * 4

	org				VMDispatchAltTable + &n * 4
	dc.l			&code - NKTop - &n * 4

	org				@h

	ENDM


	MACRO
	DeclareVMCallWithAlt	&n, &code, &alt

@h
	org				VMDispatchMainTable + &n * 4
	dc.l			&code - NKTop - &n * 4

	org				VMDispatchAltTable + &n * 4
	dc.l			&alt - NKTop - &n * 4

	org				@h

	ENDM



;	Accessed ONLY via Sup table

kcVMDispatch	;	OUTSIDE REFERER

	_Lock			PSA.HTABLock, scratch1=r8, scratch2=r9

	mfsprg	r8, 0
	stw		r7, -0x0010(r8)
	lwz		r6, EWA.r6(r8)
	stw		r14, EWA.r14(r8)
	stw		r15, EWA.r15(r8)
	stw		r16, EWA.r16(r8)

;	Whoa... where did cr0 get set?
;	And why do we set cr2?
	mfpvr	r9
	srwi	r9, r9, 16
	cmpwi	cr2, r9, 0x0009
	beq-	@other_pvr_test
	cmpwi	cr2, r9, 0x000a
@other_pvr_test

	lwz		r7, KDP.NanoKernelInfo + NKNanoKernelInfo.VMDispatchCountTblPtr(r1)
	rlwinm	r8, r3,  2, 20, 29
	cmplwi	r7, 0
	beq-	@no_count
	lwzx	r9, r7, r8
	addi	r9, r9, 1
	stwx	r9, r7, r8
@no_count

	lwz		r7, KDP.PA_NanoKernelCode(r1)
	b		VMDispatchTableEnd

VMDispatchMainTable
	dcb.l	MaxVMCallCount, 0;Local_Panic - (* - VMDispatchMainTable)
VMDispatchAltTable
	dcb.l	MaxVMCallCount, 0;Local_Panic - (* - VMDispatchAltTable)
VMDispatchTableEnd

	lwz		r9, KDP.VMMaxVirtualPages(r1)
	cmplwi	r3, MaxVMCallCount
	cmpwi	cr1, r9, 0
	rlwimi	r7, r3,  2, 23, 29
	llabel	r8, VMDispatchMainTable

	bne-	cr1, @noalt
	llabel	r8, VMDispatchAltTable
@noalt

	lwzx	r8, r8, r7
	lwz		r9, KDP.UsablePhysicalPages(r1)
	add		r8, r8, r7
	mtlr	r8
	bltlr-	




;	UNIMPLEMENTED kcVMDispatch selectors:

;	VMUnInit: 'un-init the MMU virtual space'

	DeclareVMCall			1, VMReturn


;	VMGetPhysicalAddress: 'return phys address given log page (can be different from above!)'
;	('above' means VMGetPhysicalPage)

	DeclareVMCallWithAlt	11, VMReturnMinus1, VMReturnNotReady


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

;	Xrefs:
;	kcVMDispatch
;	VMFinalInit
;	VMInit
;	VMExchangePages
;	VMGetPhysicalPage
;	getPTEntryGivenPage
;	major_0x08d88
;	VMIsInited
;	VMIsResident
;	VMIsUnmodified
;	VMLRU
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	PageSetCommon
;	VMMakePageNonCacheable
;	VMMarkBacking
;	VMMarkCleanUnused
;	VMMarkUndefined
;	VMMarkResident
;	VMPTest
;	setPTEntryGivenPage
;	VMShouldClean
;	VMAllocateMemory
;	VeryPopularFunction
;	major_0x09c9c

VMReturnMinus1	;	OUTSIDE REFERER
	li		r3, -0x01
	b		VMReturn

VMReturnNotReady	;	OUTSIDE REFERER
	b		VMReturnMinus1

VMReturn0	;	OUTSIDE REFERER
	li		r3,  0x00
	b		VMReturn

VMReturn1	;	OUTSIDE REFERER
	li		r3,  0x01

VMReturn	;	OUTSIDE REFERER
	mfsprg	r8, 0
	lwz		r14,  0x0038(r8)
	lwz		r15,  0x003c(r8)
	lwz		r16,  0x0040(r8)
	lwz		r7, -0x0010(r8)
	lwz		r6, -0x0014(r8)
	_AssertAndRelease	PSA.HTABLock, scratch=r8
	b		IntReturn



;	'last chance to init after new memory dispatch is installed'
;
;	Does protecting the kernel mean *wiring* the kernel?

	DeclareVMCall	2, VMFinalInit

VMFinalInit	;	OUTSIDE REFERER
	mfsprg	r8, 0
	stmw	r29, EWA.r29(r8)

	lwz		r29, KDP.TopOfFreePages(r1)
	lwz		r30, KDP.PA_NanoKernelCode(r1)
	lwz		r31, KDP.OtherFreeThing(r1)

	subf	r30, r30, r29
	cmpwi	r31, 0
	add		r30, r30, r31		; r30 = TopOfFreePages - PA_NanoKernelCode + OtherFreeThing

	beq-	@skip

	li		r8, 0
	stw		r8, KDP.OtherFreeThing(r1)

	_log	'Protecting the nanokernel: '

	mr		r8, r31
	bl		printw

	mr		r8, r30
	bl		printw

	_log	'^n'

	addi	r29, r1, 4096

@loop
	srwi	r4, r31, 12
	lwz		r9, KDP.UsablePhysicalPages(r1)
	bl		VeryPopularFunction
	bge-	cr4, @skip
	bltl-	cr5, VMDoSomethingWithTLB
	bgel-	cr5, VMSecondLastExportedFunc
	ori		r16, r16,  0x400
	rlwimi	r9, r29,  0,  0, 19
	bl		major_0x09b40
	addi	r31, r31,  0x1000
	cmplw	r31, r30
	ble+	@loop

@skip
	mfsprg	r8, 0
	lmw		r29, EWA.r29(r8)
	b		VMReturn1



;	'init the MMU virtual space'

	DeclareVMCallWithAlt	0, VMInit, VMReturn1

VMInit	;	OUTSIDE REFERER
	_log	'Legacy VMInit '
	mr		r8, r4
	bl		printw
	mr		r8, r5
	bl		printw
	_log	'^n'
	lwz		r7,  KDP.FlatPageListPtr(r1)
	lwz		r8,  0x06c0(r1)
	cmpw	r7, r8
	bne+	VMReturn1
	stw		r4,  0x06a8(r1)
	stw		r5,  KDP.FlatPageListPtr(r1)
	lwz		r6,  0x05e8(r1)
	li		r5,  0x00
	li		r4,  0x00

VMInit_0x60
	lwz		r8,  0x0000(r6)
	addi	r6, r6,  0x08
	lhz		r3,  0x0000(r8)
	lhz		r7,  0x0002(r8)
	lwz		r8,  0x0004(r8)
	addi	r7, r7,  0x01
	cmpwi	cr1, r3,  0x00
	andi.	r3, r8,  0xc00
	cmpwi	r3,  0xc00
	bne-	VMInit_0x110
	bnel+	cr1, Local_Panic
	rlwinm	r15, r8, 22,  0, 29
	addi	r3, r1,  0x6c0
	rlwimi	r3, r5,  2, 28, 29
	stw		r15,  0x0000(r3)
	slwi	r3, r5, 16
	cmpw	r3, r4
	bnel+	Local_Panic

VMInit_0xa8
	lwz		r16,  0x0000(r15)
	addi	r7, r7, -0x01
	andi.	r3, r16,  0x01
	beql+	Local_Panic
	andi.	r3, r16,  0x800
	beq-	VMInit_0x100
	lwz		r14,  0x06a4(r1)
	rlwinm	r3, r16, 23,  9, 28
	lwzux	r8, r14, r3
	lwz		r9,  0x0004(r14)
	andis.	r3, r8,  0x8000
	beql+	Local_Panic
	andi.	r3, r9,  0x03
	cmpwi	r3,  0x00
	beql+	Local_Panic
	rlwinm	r3, r16, 17, 22, 31
	rlwimi	r3, r8, 10, 16, 21
	rlwimi	r3, r8, 21, 12, 15
	cmpw	r3, r4
	bnel+	Local_Panic
	bl		VMDoSomethingWithTLB
	bl		major_0x09b40

VMInit_0x100
	cmpwi	r7,  0x00
	addi	r15, r15,  0x04
	addi	r4, r4,  0x01
	bne+	VMInit_0xa8

VMInit_0x110
	lwz		r7,  0x06b4(r1)
	addi	r5, r5,  0x01
	addi	r7, r7, -0x01
	srwi	r7, r7, 16
	cmpw	r5, r7
	ble+	VMInit_0x60
	lwz		r7,  0x06ac(r1)
	cmpw	r4, r7
	bnel+	Local_Panic
	lwz		r5,  KDP.FlatPageListPtr(r1)
	lwz		r4,  0x06a8(r1)
	andi.	r7, r5,  0xfff
	li		r3,  0x02
	bne-	VMInit_0x374
	lwz		r7,  0x06b4(r1)
	cmplw	r7, r4
	li		r3,  0x03
	blt-	VMInit_0x374
	addi	r7, r4,  0x3ff
	srwi	r6, r7, 10
	srwi	r8, r5, 12
	add		r8, r8, r6
	lwz		r9,  0x06ac(r1)
	cmplw	r8, r9
	li		r3,  0x04
	bgt-	VMInit_0x374
	cmplw	r4, r9
	li		r3,  0x05
	blt-	VMInit_0x374
	srwi	r7, r5, 12
	bl		major_0x09c9c
	stw		r9,  KDP.FlatPageListPtr(r1)
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
	bne-	VMInit_0x374
	stw		r4,  0x06a8(r1)
	lwz		r8, -0x0020(r1)
	slwi	r7, r4, 12
	stw		r7,  0x0dc8(r8)
	slwi	r7, r4,  2
	li		r8,  0x00

VMInit_0x1d4
	subi	r7, r7, 4
	cmpwi	r7,  0x00
	stwx	r8, r15, r7
	bne+	VMInit_0x1d4
	lwz		r7,  0x06ac(r1)
	slwi	r6, r7,  2

VMInit_0x1ec
	subi	r6, r6, 4
	srwi	r7, r6,  2
	bl		major_0x09c9c
	cmpwi	r6,  0x00
	ori		r16, r9,  0x21
	stwx	r16, r15, r6
	bne+	VMInit_0x1ec
	lwz		r15,  KDP.FlatPageListPtr(r1)
	srwi	r7, r5, 10
	add		r15, r15, r7
	lwz		r5,  0x06a8(r1)

VMInit_0x218
	lwz		r16,  0x0000(r15)
	andi.	r7, r16,  0x01
	beql+	Local_Panic
	ori		r16, r16,  0x404
	stw		r16,  0x0000(r15)
	addi	r5, r5, -0x400
	cmpwi	r5,  0x00
	addi	r15, r15,  0x04
	bgt+	VMInit_0x218
	lwz		r9,  0x06b4(r1)
	lwz		r6,  0x05e8(r1)
	addi	r9, r9, -0x01
	li		r8,  0xa00
	ori		r7, r8,  0xffff

VMInit_0x250
	cmplwi	r9,  0xffff
	lwz		r3,  0x0000(r6)
	addi	r6, r6,  0x08
	stw		r7,  0x0000(r3)
	stw		r8,  0x0004(r3)
	stw		r7,  0x0008(r3)
	stw		r8,  0x000c(r3)
	addis	r9, r9, -0x01
	bgt+	VMInit_0x250
	sth		r9,  0x0002(r3)
	sth		r9,  0x000a(r3)
	lwz		r6,  0x05e8(r1)
	lwz		r9,  0x06a8(r1)
	lwz		r15,  KDP.FlatPageListPtr(r1)

VMInit_0x288
	lwz		r8,  0x0000(r6)
	lis		r7,  0x01
	rlwinm.	r3, r9, 16, 16, 31
	bne-	VMInit_0x29c
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
	bne+	VMInit_0x288
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	lwz		r8, -0x001c(r9)
	li		r9,  0x00
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	cmpwi	r16,  0x00
	bne+	Local_Panic
	li		r16,  0x00
	stw		r16,  0x003c(r8)
	lwz		r16,  KDP.FlatPageListPtr(r1)
	stw		r16,  0x0040(r8)
	lwz		r16,  0x06a8(r1)
	slwi	r16, r16, 12
	stw		r16,  0x002c(r8)
	addi	r16, r16, -0x01
	stw		r16,  0x0028(r8)
	mr		r17, r8
	_log	'Adjusting area '
	lwz		r8,  0x0000(r17)
	mr		r8, r8
	bl		printw
	_log	'to size '
	lwz		r8,  0x002c(r17)
	mr		r8, r8
	bl		printw
	_log	'^n'

;	r6 = ewa
	bl		Restore_r14_r31
	b		VMReturn0

VMInit_0x374
	lwz		r7,  0x06ac(r1)
	lwz		r8,  0x06c0(r1)
	stw		r7,  0x06a8(r1)
	stw		r8,  KDP.FlatPageListPtr(r1)
	b		VMReturn



;	'exchange physical page contents'

	DeclareVMCallWithAlt	12, VMExchangePages, VMReturnNotReady

VMExchangePages	;	OUTSIDE REFERER
	bl		VeryPopularFunction
	bge+	cr4, VMReturnMinus1
	bgt+	cr5, VMReturnMinus1
	bns+	cr7, VMReturnMinus1
	bgt+	cr6, VMReturnMinus1
	bne+	cr6, VMReturnMinus1
	bltl-	cr5, VMDoSomethingWithTLB
	bltl-	cr5, major_0x09b40
	mr		r6, r15
	mr		r4, r5
	mr		r5, r16
	lwz		r9,  0x06a8(r1)
	bl		VeryPopularFunction
	bge+	cr4, VMReturnMinus1
	bgt+	cr5, VMReturnMinus1
	bns+	cr7, VMReturnMinus1
	bgt+	cr6, VMReturnMinus1
	bne+	cr6, VMReturnMinus1
	bltl-	cr5, VMDoSomethingWithTLB
	bltl-	cr5, major_0x09b40
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
	bne+	VMExchangePages_0x68
	b		VMReturn



;	'return phys page given log page'

	DeclareVMCall	10, VMGetPhysicalPage

VMGetPhysicalPage	;	OUTSIDE REFERER
	bne-	cr1, VMGetPhysicalPage_0x30
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	slwi	r29, r4, 12
	bl		major_0x08d88
	blt-	VMGetPhysicalPage_0x28
	bns-	cr7, major_0x08d88_0xa8
	srwi	r3, r17, 12
	b		major_0x08d88_0xb0

VMGetPhysicalPage_0x28
;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r9,  0x06a8(r1)

VMGetPhysicalPage_0x30
	bl		VeryPopularFunction
	bns+	cr7, VMReturnMinus1
	srwi	r3, r9, 12
	b		VMReturn



;	'given a page, get its 68K PTE'

	DeclareVMCall	19, getPTEntryGivenPage

getPTEntryGivenPage	;	OUTSIDE REFERER
	bne-	cr1, getPTEntryGivenPage_0x50
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	slwi	r29, r4, 12
	bl		major_0x08d88
	blt-	getPTEntryGivenPage_0x48
	lwz		r3,  0x0000(r30)
	beq-	getPTEntryGivenPage_0x3c
	bns-	cr7, getPTEntryGivenPage_0x3c
	bge-	cr5, getPTEntryGivenPage_0x3c
	bl		MPCall_95_0x2e0
	bl		MPCall_95_0x334
	lwz		r3,  0x0000(r30)
	rlwimi	r3, r17,  0,  0, 19

getPTEntryGivenPage_0x3c
	li		r16,  0x882
	andc	r3, r3, r16
	b		major_0x08d88_0xb0

getPTEntryGivenPage_0x48
;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r9,  0x06a8(r1)

getPTEntryGivenPage_0x50
	bl		VeryPopularFunction
	mr		r3, r16
	bns-	cr7, getPTEntryGivenPage_0x74
	rlwimi	r3, r9,  0,  0, 19
	bge-	cr5, getPTEntryGivenPage_0x74
	bl		VMDoSomethingWithTLB
	bl		VMDoSomeIO_0x4
	mr		r3, r16
	rlwimi	r3, r9,  0,  0, 19

getPTEntryGivenPage_0x74
	li		r8,  0x882
	andc	r3, r3, r8
	b		VMReturn



;	                     major_0x08d88                      

;	Xrefs:
;	VMGetPhysicalPage
;	getPTEntryGivenPage
;	VMIsResident
;	VMMarkBacking
;	VMMarkResident
;	setPTEntryGivenPage

major_0x08d88	;	OUTSIDE REFERER
	mfsprg	r28, 0
	mflr	r27
	mr		r9, r29
	lwz		r8, -0x001c(r28)
	bl		FindAreaAbove
	mr		r31, r8
	lwz		r16,  0x0024(r31)
	lwz		r17,  0x0028(r31)
	lwz		r18,  0x0020(r31)
	cmplw	r29, r16
	cmplw	cr1, r29, r17
	blt-	major_0x08d88_0x74
	bgt-	cr1, major_0x08d88_0x74
	rlwinm.	r8, r18,  0, 16, 16
	lwz		r19,  0x0070(r31)
	beq-	major_0x08d88_0x8c
	lwz		r17,  0x0038(r31)
	rlwinm	r19, r19,  0,  0, 19
	cmpwi	r17,  0x00
	subf	r18, r16, r29
	beq-	major_0x08d88_0x74
	mtlr	r27
	crclr	cr0_lt
	crset	cr0_eq
	add		r17, r18, r19
	addi	r30, r31,  0x74
	crset	cr7_so
	rlwimi	r18, r17,  0,  0, 19
	blr		

major_0x08d88_0x74
	mtlr	r27
	srwi	r8, r29, 28
	cmpwi	r8,  0x07
	beq-	major_0x08d88_0xa8
	crset	cr0_lt
	blr		

major_0x08d88_0x8c
	mr		r8, r29
	bl		MPCall_95_0x1e4
	bl		MPCall_95_0x2b0
	mtlr	r27
	crclr	cr0_lt
	crclr	cr0_eq
	blr		

major_0x08d88_0xa8	;	OUTSIDE REFERER
;	r6 = ewa
	bl		Restore_r14_r31
	b		VMReturnMinus1

major_0x08d88_0xb0	;	OUTSIDE REFERER
;	r6 = ewa
	bl		Restore_r14_r31
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCallWithAlt	5, VMIsInited, VMReturnNotReady

VMIsInited	;	OUTSIDE REFERER
	bl		VeryPopularFunction
	bso+	cr7, VMReturn1
	rlwinm	r3, r16, 16, 31, 31
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCall	3, VMIsResident

VMIsResident	;	OUTSIDE REFERER
	bne-	cr1, VMIsResident_0x30
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	slwi	r29, r4, 12
	bl		major_0x08d88
	blt-	VMIsResident_0x28
	lwz		r16,  0x0000(r30)
	srwi	r3, r16, 31
	b		major_0x08d88_0xb0

VMIsResident_0x28
;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r9,  0x06a8(r1)

VMIsResident_0x30
	bl		VeryPopularFunction
	clrlwi	r3, r16,  0x1f
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCallWithAlt	4, VMIsUnmodified, VMReturnNotReady

VMIsUnmodified	;	OUTSIDE REFERER
	bl		VeryPopularFunction
	rlwinm	r3, r16, 28, 31, 31
	xori	r3, r3,  0x01
	bge+	cr5, VMReturn
	bl		VMDoSomethingWithTLB
	bl		VMDoSomeIO_0x4
	rlwinm	r3, r16, 28, 31, 31
	xori	r3, r3,  0x01
	b		VMReturn



;	Cube-E has no comment

	DeclareVMCallWithAlt	22, VMLRU, VMReturnNotReady

VMLRU	;	OUTSIDE REFERER
	rlwinm.	r9, r9,  2,  0, 29
	lwz		r15,  KDP.FlatPageListPtr(r1)
	lwz		r14,  0x06a4(r1)
	add		r15, r15, r9
	srwi	r4, r9,  2
	li		r5,  0x100
	li		r6,  0x08

VMLRU_0x1c
	lwzu	r16, -0x0004(r15)
	addi	r4, r4, -0x01
	mtcrf	 0x07, r16
	cmpwi	r4,  0x00
	rlwinm	r7, r16, 23,  9, 28
	bns-	cr7, VMLRU_0x5c
	bge-	cr5, VMLRU_0x50
	add		r14, r14, r7
	lwz		r8,  0x0000(r14)
	bl		VMDoSomethingWithTLB
	andc	r9, r9, r5
	bl		major_0x09b40
	subf	r14, r7, r14

VMLRU_0x50
	rlwimi	r16, r16,  6, 22, 22
	andc	r16, r16, r6
	stw		r16,  0x0000(r15)

VMLRU_0x5c
	bne+	VMLRU_0x1c
	b		VMReturn



;	                     major_0x08f14                      

;	Xrefs:
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	VMMakePageNonCacheable

major_0x08f14	;	OUTSIDE REFERER
	mflr	r28
	mr		r29, r8
	mr		r30, r9
	mfsprg	r18, 0
	slwi	r9, r4, 12
	lwz		r8, -0x001c(r18)
	bl		FindAreaAbove
	lwz		r17,  0x0020(r8)
	lwz		r16,  0x0024(r8)
	rlwinm.	r18, r17,  0, 16, 16
	cmplw	cr1, r16, r9
	beq+	Local_Panic
	bgt+	cr1, Local_Panic
	li		r16, -0x01
	mtlr	r28
	stw		r16,  0x0038(r8)
	mr		r8, r29
	mr		r9, r30
	blr		



;	'make it so'

	DeclareVMCall	17, VMMakePageCacheable

VMMakePageCacheable	;	OUTSIDE REFERER
	bne-	cr1, VMMakePageCacheable_0x4

VMMakePageCacheable_0x4
	bl		VeryPopularFunction
	rlwinm	r7, r16,  0, 25, 26
	cmpwi	r7,  0x20
	bns+	cr7, VMReturnMinus1
	beq+	VMReturn
	bge-	cr4, VMMakePageCacheable_0x40
	bltl-	cr5, VMDoSomethingWithTLB
	bgel-	cr5, VMSecondLastExportedFunc
	rlwinm	r16, r16,  0, 27, 24
	rlwinm	r9, r9,  0, 27, 24
	lwz		r7,  0x0688(r1)
	rlwimi	r9, r7,  0, 27, 28
	ori		r16, r16,  0x20
	bl		VMDoSomeIO
	b		VMReturn

VMMakePageCacheable_0x40
	rlwinm	r7, r4, 16, 28, 31
	cmpwi	r7,  0x08
	blt+	VMReturnMinus1
	ble+	cr6, VMReturnMinus1
	_log	'VMMakePageCacheable for I/O '
	mr		r8, r4
	bl		printw
	_log	'^n'
	mfsprg	r6, 0
	lwz		r6, -0x0014(r6)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	bl		major_0x08f14

;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r5,  0x000c(r15)
	andi.	r6, r5,  0xe01
	cmpwi	r6,  0xa01
	beq-	VMMakePageCacheable_0xec
	addi	r15, r15, -0x08
	lwz		r5,  0x0004(r15)
	lhz		r6,  0x0000(r15)
	andi.	r5, r5,  0xc00
	lhz		r5,  0x0002(r15)
	bne+	VMReturnMinus1
	addi	r5, r5,  0x01
	add		r6, r6, r5
	xor		r6, r6, r4
	andi.	r6, r6,  0xffff
	bne+	VMReturnMinus1
	sth		r5,  0x0002(r15)
	b		PageSetCommon

VMMakePageCacheable_0xec
	lwz		r5,  0x0000(r15)
	lwz		r6,  0x0004(r15)
	stw		r5,  0x0008(r15)
	stw		r6,  0x000c(r15)
	slwi	r5, r4, 16
	stw		r5,  0x0000(r15)
	slwi	r5, r4, 12
	ori		r5, r5,  0x12
	stw		r5,  0x0004(r15)
	b		PageSetCommon



;	Cube-E has no comment

	DeclareVMCall	24, VMMakePageWriteThrough

VMMakePageWriteThrough	;	OUTSIDE REFERER
	bne-	cr1, VMMakePageWriteThrough_0x4

VMMakePageWriteThrough_0x4
	bl		VeryPopularFunction
	rlwinm.	r7, r16,  0, 25, 26
	bns+	cr7, VMReturnMinus1
	beq+	VMReturn
	bge-	cr4, VMMakePageWriteThrough_0x3c
	bltl-	cr5, VMDoSomethingWithTLB
	bgel-	cr5, VMSecondLastExportedFunc
	rlwinm	r16, r16,  0, 27, 24
	rlwinm	r9, r9,  0, 27, 24
	lwz		r7,  0x0688(r1)
	rlwimi	r9, r7,  0, 27, 28
	ori		r9, r9,  0x40
	bl		VMDoSomeIO
	b		VMMakePageNonCacheable_0x3c

VMMakePageWriteThrough_0x3c
	rlwinm	r7, r4, 16, 28, 31
	cmpwi	r7,  0x08
	blt+	VMReturnMinus1
	ble+	cr6, VMReturnMinus1
	_log	'VMMakePageWriteThrough for I/O '
	mr		r8, r4
	bl		printw
	_log	'^n'
	mfsprg	r6, 0
	lwz		r6, -0x0014(r6)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	bl		major_0x08f14

;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r5,  0x000c(r15)
	andi.	r6, r5,  0xe01
	cmpwi	r6,  0xa01
	beq-	VMMakePageWriteThrough_0xec
	addi	r15, r15, -0x08
	lwz		r5,  0x0004(r15)
	lhz		r6,  0x0000(r15)
	andi.	r5, r5,  0xc00
	lhz		r5,  0x0002(r15)
	bne+	VMReturnMinus1
	addi	r5, r5,  0x01
	add		r6, r6, r5
	xor		r6, r6, r4
	andi.	r6, r6,  0xffff
	bne+	VMReturnMinus1
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
	ori		r5, r5,  0x52
	stw		r5,  0x0004(r15)



;	                     PageSetCommon                      

;	Xrefs:
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	VMMakePageNonCacheable

PageSetCommon	;	OUTSIDE REFERER
	lwz		r15,  0x06a0(r1)
	lwz		r14,  0x06a4(r1)
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
	beq-	cr1, PageSetCommon_0xc8
	beq-	cr2, PageSetCommon_0xc4
	beq-	cr3, PageSetCommon_0xc0
	beq-	cr4, PageSetCommon_0xbc
	lwzu	r7,  0x0020(r14)
	lwz		r15,  0x0008(r14)
	lwz		r6,  0x0010(r14)
	lwz		r5,  0x0018(r14)
	cmplw	cr1, r7, r8
	cmplw	cr2, r15, r8
	cmplw	cr3, r6, r8
	cmplw	cr4, r5, r8
	beq-	cr1, PageSetCommon_0xc8
	beq-	cr2, PageSetCommon_0xc4
	beq-	cr3, PageSetCommon_0xc0
	beq-	cr4, PageSetCommon_0xbc
	crnot	2, 2
	lwz		r15,  0x06a0(r1)
	lwz		r14,  0x06a4(r1)
	slwi	r6, r4, 12
	mfsrin	r6, r6
	xor		r6, r6, r4
	not		r6, r6
	slwi	r7, r6,  6
	and		r15, r15, r7
	xori	r8, r8,  0x40
	bne+	PageSetCommon_0x2c
	b		VMReturn

PageSetCommon_0xbc
	addi	r14, r14,  0x08

PageSetCommon_0xc0
	addi	r14, r14,  0x08

PageSetCommon_0xc4
	addi	r14, r14,  0x08

PageSetCommon_0xc8
	bl		VMDoSomethingWithTLB
	li		r8,  0x00
	li		r9,  0x00
	bl		VMDoSomeIO_0x4
	b		VMReturn



;	'make it so'

	DeclareVMCall	18, VMMakePageNonCacheable

VMMakePageNonCacheable	;	OUTSIDE REFERER
	bne-	cr1, VMMakePageNonCacheable_0x4

VMMakePageNonCacheable_0x4
	bl		VeryPopularFunction
	rlwinm	r7, r16,  0, 25, 26
	cmpwi	r7,  0x60
	bns+	cr7, VMReturnMinus1
	beq+	VMReturn
	bge-	cr4, VMMakePageNonCacheable_0x78
	bltl-	cr5, VMDoSomethingWithTLB
	bgel-	cr5, VMSecondLastExportedFunc
	rlwinm	r9, r9,  0, 27, 24
	lwz		r7,  0x0688(r1)
	rlwimi	r9, r7,  0, 27, 28
	ori		r16, r16,  0x60
	ori		r9, r9,  0x20
	bl		VMDoSomeIO

VMMakePageNonCacheable_0x3c	;	OUTSIDE REFERER
	rlwinm	r4, r9,  0,  0, 19
	lhz		r8,  0x0f4a(r1)
	add		r5, r4, r8
	li		r7,  0x1000
	slwi	r8, r8,  1

VMMakePageNonCacheable_0x50
	subf.	r7, r8, r7
	dcbf	r7, r4
	dcbf	r7, r5
	sync	
	icbi	r7, r4
	icbi	r7, r5
	bne+	VMMakePageNonCacheable_0x50
	sync	
	isync	
	b		VMReturn

VMMakePageNonCacheable_0x78
	rlwinm	r7, r4, 16, 28, 31
	cmpwi	r7,  0x08
	blt+	VMReturnMinus1
	bgt+	cr6, VMReturnMinus1
	_log	'VMMakePageNonCacheable for I/O '
	mr		r8, r4
	bl		printw
	_log	'^n'
	mfsprg	r6, 0
	lwz		r6, -0x0014(r6)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	bl		major_0x08f14

;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r5,  0x0004(r15)
	srwi	r6, r5, 12
	cmpw	r6, r4
	bne+	VMReturnMinus1
	lis		r7,  0x00
	lis		r8,  0x00
	lis		r9,  0x00
	srwi	r6, r5, 12
	lhz		r8,  0x0002(r15)
	lhz		r7,  0x0000(r15)
	addi	r6, r6,  0x01
	cmpwi	r8,  0x00
	beq-	VMMakePageNonCacheable_0x134
	addi	r7, r7,  0x01
	addi	r8, r8, -0x01
	rlwimi	r5, r6, 12,  0, 19
	sth		r7,  0x0000(r15)
	sth		r8,  0x0002(r15)
	stw		r5,  0x0004(r15)
	b		PageSetCommon

VMMakePageNonCacheable_0x134
	lis		r6,  0x00
	lwz		r7,  0x0008(r15)
	lwz		r8,  0x000c(r15)
	lis		r5,  0x00
	ori		r6, r6,  0xa01
	stw		r7,  0x0000(r15)
	stw		r8,  0x0004(r15)
	stw		r5,  0x0008(r15)
	stw		r6,  0x000c(r15)
	dcbf	0, r15
	b		PageSetCommon



;	'set page status'

	DeclareVMCall	8, VMMarkBacking

VMMarkBacking	;	OUTSIDE REFERER
	bne-	cr1, VMMarkBacking_0x58
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	slwi	r29, r4, 12
	bl		major_0x08d88
	blt-	VMMarkBacking_0x50
	beq+	major_0x08d88_0xa8
	bns-	cr7, VMMarkBacking_0x30
	bge-	cr5, VMMarkBacking_0x30
	bl		MPCall_95_0x2e0
	bl		MPCall_95_0x348

VMMarkBacking_0x30
	lwz		r18,  0x0000(r30)
	rlwinm	r18, r18,  0,  0, 30
	stw		r18,  0x0000(r30)
	lwz		r18,  0x0068(r31)
	lwz		r17,  0x0038(r31)
	subf	r17, r18, r17
	stw		r17,  0x0038(r31)
	b		major_0x08d88_0xb0

VMMarkBacking_0x50
;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r9,  0x06a8(r1)

VMMarkBacking_0x58
	bl		VeryPopularFunction
	bge+	cr4, VMReturnMinus1
	bgt+	cr5, VMReturnMinus1
	bltl-	cr5, VMDoSomethingWithTLB
	bltl-	cr5, major_0x09b40
	rlwimi	r16, r5, 16, 15, 15
	li		r7,  0x01
	andc	r16, r16, r7
	stw		r16,  0x0000(r15)
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCallWithAlt	9, VMMarkCleanUnused, VMReturnNotReady

VMMarkCleanUnused	;	OUTSIDE REFERER
	bl		VeryPopularFunction
	bge+	cr4, VMReturnMinus1
	bns+	cr7, VMReturnMinus1
	bltl-	cr5, VMDoSomethingWithTLB
	beq-	cr2, VMMarkCleanUnused_0x2c
	bgel-	cr5, VMSecondLastExportedFunc
	li		r7,  0x180
	andc	r9, r9, r7
	ori		r16, r16,  0x100
	bl		VMDoSomeIO
	b		VMReturn

VMMarkCleanUnused_0x2c
	bgel-	cr5, VMSecondLastExportedFunc
	ori		r16, r16,  0x100
	li		r7,  0x18
	andc	r16, r16, r7
	bl		major_0x09b40
	b		VMReturn



;	Cube-E has no comment

	DeclareVMCallWithAlt	23, VMMarkUndefined, VMReturnNotReady

VMMarkUndefined	;	OUTSIDE REFERER
	cmplw	r4, r9
	cmplw	cr1, r5, r9
	add		r7, r4, r5
	cmplw	cr2, r7, r9
	bge+	VMReturnMinus1
	bgt+	cr1, VMReturnMinus1
	bgt+	cr2, VMReturnMinus1
	lwz		r15,  KDP.FlatPageListPtr(r1)
	slwi	r8, r7,  2
	li		r7,  0x01

VMMarkUndefined_0x28
	subi	r8, r8, 4
	subf.	r5, r7, r5
	lwzx	r16, r15, r8
	blt+	VMReturn
	rlwimi	r16, r6,  7, 24, 24
	stwx	r16, r15, r8
	b		VMMarkUndefined_0x28



;	'set page status'

	DeclareVMCall	7, VMMarkResident

VMMarkResident	;	OUTSIDE REFERER
	bne-	cr1, VMMarkResident_0x58
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	slwi	r29, r4, 12
	slwi	r26, r5, 12
	bl		major_0x08d88
	blt-	VMMarkResident_0x50
	beq+	major_0x08d88_0xa8
	bso+	cr7, major_0x08d88_0xa8
	bltl+	cr5, Local_Panic
	lwz		r16,  0x0000(r30)
	rlwimi	r16, r5, 12,  0, 19
	ori		r16, r16,  0x01
	stw		r16,  0x0000(r30)
	lwz		r18,  0x0068(r31)
	lwz		r17,  0x0038(r31)
	add		r17, r17, r18
	stw		r17,  0x0038(r31)
	b		major_0x08d88_0xb0

VMMarkResident_0x50
;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r9,  0x06a8(r1)

VMMarkResident_0x58
	bl		VeryPopularFunction
	bge+	cr4, VMReturnMinus1
	bso+	cr7, VMReturnMinus1
	bltl+	cr5, Local_Panic
	rlwimi	r16, r5, 12,  0, 19
	ori		r16, r16,  0x01
	stw		r16,  0x0000(r15)
	bl		VMSecondLastExportedFunc
	bl		VMDoSomeIO
	b		VMReturn



;	'ask why we got this page fault'

	DeclareVMCallWithAlt	21, VMPTest, VMReturnNotReady

VMPTest	;	OUTSIDE REFERER
	srwi	r4, r4, 12
	cmplw	r4, r9
	li		r3,  0x4000
	bge+	VMReturn
	bl		VeryPopularFunction
	li		r3,  0x400
	bns+	cr7, VMReturn
	li		r3,  0x00
	ori		r3, r3,  0x8000
	ble+	cr7, VMReturn
	cmpwi	r6,  0x00
	beq+	VMReturn
	li		r3,  0x800
	b		VMReturn



;	'given a page & 68K pte, set the real PTE'

	DeclareVMCall	20, setPTEntryGivenPage

setPTEntryGivenPage	;	OUTSIDE REFERER
	bne-	cr1, setPTEntryGivenPage_0x64
	mfsprg	r9, 0
	lwz		r6, -0x0014(r9)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	mr		r26, r4
	slwi	r29, r5, 12
	bl		major_0x08d88
	blt-	setPTEntryGivenPage_0x5c
	beq+	major_0x08d88_0xa8
	bns-	cr7, setPTEntryGivenPage_0x34
	bge-	cr5, setPTEntryGivenPage_0x34
	bl		MPCall_95_0x2e0
	bl		MPCall_95_0x348

setPTEntryGivenPage_0x34
	lwz		r18,  0x0000(r30)
	xor		r8, r18, r26
	li		r3,  0x461
	rlwimi	r3, r18, 24, 29, 29
	and.	r3, r3, r8
	bne+	major_0x08d88_0xa8
	andi.	r8, r8,  0x11c
	xor		r18, r18, r8
	stw		r18,  0x0000(r30)
	b		major_0x08d88_0xb0

setPTEntryGivenPage_0x5c
;	r6 = ewa
	bl		Restore_r14_r31
	lwz		r9,  0x06a8(r1)

setPTEntryGivenPage_0x64
	mr		r6, r4
	mr		r4, r5
	bl		VeryPopularFunction
	bge+	cr4, VMReturnMinus1
	xor		r7, r16, r6
	li		r3,  0x461
	rlwimi	r3, r16, 24, 29, 29
	and.	r3, r3, r7
	bne+	VMReturnMinus1
	andi.	r7, r7,  0x11c
	xor		r16, r16, r7
	stw		r16,  0x0000(r15)
	bge+	cr5, VMReturn
	bl		VMDoSomethingWithTLB
	lwz		r16,  0x0000(r15)
	bne-	cr2, setPTEntryGivenPage_0xb4
	andi.	r7, r16,  0x08
	bne-	setPTEntryGivenPage_0xb4
	bl		major_0x09b40
	b		VMReturn

setPTEntryGivenPage_0xb4
	rlwimi	r9, r16,  5, 23, 23
	rlwimi	r9, r16,  3, 24, 24
	rlwimi	r9, r16, 30, 31, 31
	bl		VMDoSomeIO_0x4
	b		VMReturn



;	'ask about page status' (typo?)

	DeclareVMCallWithAlt	6, VMShouldClean, VMReturnNotReady

VMShouldClean	;	OUTSIDE REFERER
	bl		VeryPopularFunction
	bns+	cr7, VMReturn0
	bge+	cr4, VMReturnMinus1
	bltl-	cr5, VMDoSomethingWithTLB
	blt-	cr7, VMShouldClean_0x34
	bns-	cr6, VMShouldClean_0x34
	xori	r16, r16,  0x10
	ori		r16, r16,  0x100
	stw		r16,  0x0000(r15)
	bge+	cr5, VMReturn1
	xori	r9, r9,  0x80
	bl		VMDoSomeIO_0x4
	b		VMReturn1

VMShouldClean_0x34
	bltl-	cr5, VMDoSomeIO_0x4
	b		VMReturn0



;	Cube-E has no comment

	DeclareVMCallWithAlt	25, VMAllocateMemory, VMReturnNotReady

VMAllocateMemory	;	OUTSIDE REFERER
	lwz		r7,  KDP.FlatPageListPtr(r1)
	lwz		r8,  0x06c0(r1)
	cmpwi	cr6, r5,  0x00
	cmpw	cr7, r7, r8
	or		r7, r4, r6
	rlwinm.	r7, r7,  0,  0, 11
	ble+	cr6, VMReturnMinus1
	lwz		r9,  0x06a8(r1)
	bne+	cr7, VMReturnMinus1
	mr		r7, r4
	bne+	VMReturnMinus1
	mr		r4, r9
	slwi	r6, r6, 12
	lwz		r9, -0x0408(r1)
	crclr	cr3_eq
	cmpwi	cr6, r6,  0x00
	cmplw	cr7, r9, r5
	bne-	cr6, VMAllocateMemory_0x6c
	blt-	cr7, VMAllocateMemory_0x6c
	lwz		r9, -0x040c(r1)
	subf	r4, r5, r9
	slwi	r4, r4,  2
	lwz		r15,  KDP.FlatPageListPtr(r1)
	add		r15, r15, r4
	srwi	r4, r4,  2
	crset	cr3_eq
	b		VMAllocateMemory_0xc0

VMAllocateMemory_0x6c
	lwz		r9,  0x06a8(r1)
	addi	r5, r5, -0x01

VMAllocateMemory_0x74
	addi	r4, r4, -0x01
	bl		VeryPopularFunction
	bltl-	cr5, VMDoSomethingWithTLB
	bltl-	cr5, major_0x09b40
	lwz		r9,  0x06a8(r1)
	subf	r8, r4, r9
	cmplw	cr7, r5, r8
	and.	r8, r16, r6
	bge+	cr7, VMAllocateMemory_0x74
	bne+	VMAllocateMemory_0x74
	cmpwi	cr6, r6,  0x00
	beq-	cr6, VMAllocateMemory_0xc0
	slwi	r8, r5,  2
	lwzx	r8, r15, r8
	slwi	r14, r5, 12
	add		r14, r14, r16
	xor		r8, r8, r14
	rlwinm.	r8, r8,  0,  0, 19
	bne+	VMAllocateMemory_0x74

VMAllocateMemory_0xc0
	slwi	r4, r7, 12
	lwz		r9,  0x06b4(r1)
	cmplw	cr7, r7, r9
	rlwinm.	r9, r7,  0,  0, 11
	blt+	cr7, VMReturnMinus1
	bne+	VMReturnMinus1
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
	bgt+	cr7, VMAllocateMemory_0xf0
	add		r8, r8, r5
	cmplw	cr7, r8, r16
	bgt+	cr7, VMReturnMinus1
	lwz		r16,  0x0004(r14)
	slwi	r8, r7, 16
	andi.	r16, r16,  0xe01
	cmpwi	r16,  0xa01
	or		r8, r8, r5
	addi	r5, r5,  0x01
	bne+	VMReturnMinus1
	stw		r8,  0x0000(r14)
	bnel-	cr6, VMAllocateMemory_0x2e8
	mr		r7, r15
	rotlwi	r15, r15,  0x0a
	ori		r15, r15,  0xc00
	stw		r15,  0x0004(r14)
	bne-	cr3, VMAllocateMemory_0x164
	lwz		r8, -0x0408(r1)
	subf	r8, r5, r8
	stw		r8, -0x0408(r1)
	lwz		r8, -0x040c(r1)
	subf	r8, r5, r8
	stw		r8, -0x040c(r1)
	b		VMAllocateMemory_0x1a4

VMAllocateMemory_0x164
	lwz		r7,  0x06ac(r1)
	subf	r7, r5, r7
	stw		r7,  0x06ac(r1)
	stw		r7,  0x06a8(r1)
	lwz		r5, -0x0020(r1)
	slwi	r8, r7, 12
	stw		r8,  0x0dc4(r5)
	stw		r8,  0x0dc8(r5)
	mr		r5, r14
	lwz		r7,  0x06b4(r1)
	li		r8,  0xa00
	bl		VMAllocateMemory_0x33c
	lwz		r7,  0x06ac(r1)
	li		r8,  0xc00
	bl		VMAllocateMemory_0x33c
	mr		r14, r5

VMAllocateMemory_0x1a4
	mfsprg	r6, 0
	lwz		r6, -0x0014(r6)

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	mr		r30, r14
	_log	' VMAllocateMemory - creating area'
	li		r8, 160

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	mr.		r31, r8
	beq+	Local_Panic
	lwz		r17,  0x0004(r30)
	lhz		r16,  0x0002(r30)
	lis		r8,  0x6172
	ori		r8, r8,  0x6561
	stw		r8,  0x0004(r31)
	addi	r16, r16,  0x01
	mr		r15, r4
	slwi	r16, r16, 12
	lwz		r8, -0x041c(r1)
	lwz		r8,  0x0014(r8)
	stw		r8,  0x006c(r31)
	stw		r15,  0x0024(r31)
	stw		r16,  0x002c(r31)
	stw		r16,  0x0038(r31)
	li		r8,  0x00
	stw		r8,  0x0030(r31)
	_log	' at 0x'
	mr		r8, r15
	bl		printw
	mr		r8, r16
	bl		printw
	_log	'^n'
	li		r8,  0x07
	stw		r8,  0x001c(r31)
	lis		r8,  0x00
	ori		r8, r8,  0x600c
	stw		r8,  0x0020(r31)
	rlwinm	r8, r17, 22,  0, 29
	stw		r8,  0x0040(r31)
	lwz		r8,  0x0008(r31)
	ori		r8, r8,  0xc0
	stw		r8,  0x0008(r31)
	mr		r8, r31
	bl		createarea
	cmpwi	r9,  0x00
	bne+	Local_Panic
	mr		r31, r8
	mfsprg	r9, 0
	lwz		r8, -0x001c(r9)
	li		r9,  0x00
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	cmpwi	r16,  0x00
	bne+	Local_Panic
	lwz		r16,  0x06a8(r1)
	lwz		r17,  0x002c(r8)
	slwi	r16, r16, 12
	cmpw	r17, r16
	beq-	VMAllocateMemory_0x2e0
	stw		r16,  0x002c(r8)
	addi	r16, r16, -0x01
	stw		r16,  0x0028(r8)

VMAllocateMemory_0x2e0
;	r6 = ewa
	bl		Restore_r14_r31
	b		VMReturn1

VMAllocateMemory_0x2e8
	lwz		r16,  0x0000(r15)
	lwz		r7,  0x06ac(r1)
	lwz		r8,  KDP.FlatPageListPtr(r1)
	slwi	r7, r7,  2
	add		r7, r7, r8
	slwi	r8, r5,  2
	subf	r7, r8, r7
	cmplw	r15, r7
	beqlr-	
	subi	r7, r7, 4

VMAllocateMemory_0x310
	lwzx	r9, r15, r8
	cmplw	r15, r7
	stw		r9,  0x0000(r15)
	addi	r15, r15,  0x04
	blt+	VMAllocateMemory_0x310

VMAllocateMemory_0x324
	cmpwi	r8,  0x04
	subi	r8, r8, 4
	stwu	r16,  0x0004(r7)
	addi	r16, r16,  0x1000
	bgt+	VMAllocateMemory_0x324
	blr		

VMAllocateMemory_0x33c
	addi	r14, r1, 120
	lwz		r15,  KDP.FlatPageListPtr(r1)
	addi	r7, r7, -0x01
	cmpwi	cr7, r8,  0xc00

VMAllocateMemory_0x34c
	cmplwi	r7,  0xffff
	lwzu	r16,  0x0008(r14)
	bne-	cr7, VMAllocateMemory_0x360
	rotlwi	r8, r15,  0x0a
	ori		r8, r8,  0xc00

VMAllocateMemory_0x360
	stw		r8,  0x0004(r16)
	addis	r15, r15,  0x04
	addis	r7, r7, -0x01
	bgt+	VMAllocateMemory_0x34c
	sth		r7,  0x0002(r16)
	blr		



;	                  VeryPopularFunction                   

;	Xrefs:
;	VMFinalInit
;	VMExchangePages
;	VMGetPhysicalPage
;	getPTEntryGivenPage
;	VMIsInited
;	VMIsResident
;	VMIsUnmodified
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	VMMakePageNonCacheable
;	VMMarkBacking
;	VMMarkCleanUnused
;	VMMarkResident
;	VMPTest
;	setPTEntryGivenPage
;	VMShouldClean
;	VMAllocateMemory
;	VMLastExportedFunc
;	major_0x0b144

VeryPopularFunction	;	OUTSIDE REFERER
	cmplw	cr4, r4, r9
	lwz		r15,  KDP.FlatPageListPtr(r1)
	slwi	r8, r4,  2
	bge-	cr4, VeryPopularFunction_0x40

VeryPopularFunction_0x10
	lwzux	r16, r15, r8
	lwz		r14,  0x06a4(r1)
	mtcrf	 0x07, r16
	rlwinm	r8, r16, 23,  9, 28
	rlwinm	r9, r16,  0,  0, 19
	bgelr-	cr5
	lwzux	r8, r14, r8
	lwz		r9,  0x0004(r14)
	mtcrf	 0x80, r8
	bns+	cr7, Local_Panic
	bltlr-	
	bl		Local_Panic

VeryPopularFunction_0x40
	lwz		r9,  0x06b4(r1)
	cmplw	cr4, r4, r9
	rlwinm.	r9, r4,  0,  0, 11
	blt+	cr4, VMReturnMinus1
	bne+	VMReturnMinus1
	lwz		r15,  0x05e8(r1)
	rlwinm	r9, r4, 19, 25, 28
	lwzx	r15, r15, r9
	clrlwi	r9, r4,  0x10
	lhz		r8,  0x0000(r15)
	b		VeryPopularFunction_0x70

VeryPopularFunction_0x6c
	lhzu	r8,  0x0008(r15)

VeryPopularFunction_0x70
	lhz		r16,  0x0002(r15)
	subf	r8, r8, r9
	cmplw	cr4, r8, r16
	bgt+	cr4, VeryPopularFunction_0x6c
	lwz		r9,  0x0004(r15)
	andi.	r16, r9,  0xc00
	cmpwi	cr6, r16,  0x400
	cmpwi	cr7, r16,  0xc00
	beq-	VeryPopularFunction_0xac
	beq-	cr6, VeryPopularFunction_0xb4
	bne+	cr7, VMReturnMinus1
	slwi	r8, r8,  2
	rlwinm	r15, r9, 22,  0, 29
	crset	cr4_lt
	b		VeryPopularFunction_0x10

VeryPopularFunction_0xac
	slwi	r8, r8, 12
	add		r9, r9, r8

VeryPopularFunction_0xb4
	rlwinm	r16, r9,  0,  0, 19
	crclr	cr4_lt
	rlwinm	r9, r9,  0, 22, 19
	rlwimi	r16, r9,  1, 25, 25
	rlwimi	r16, r9, 31, 26, 26
	xori	r16, r16,  0x20
	rlwimi	r16, r9, 29, 27, 27
	rlwimi	r16, r9, 27, 28, 28
	rlwimi	r16, r9,  2, 29, 29
	ori		r16, r16,  0x01
	mtcrf	 0x07, r16
	blr		



;	                  VMDoSomethingWithTLB                  

;	Xrefs:
;	VMFinalInit
;	VMInit
;	VMExchangePages
;	getPTEntryGivenPage
;	VMIsUnmodified
;	VMLRU
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	PageSetCommon
;	VMMakePageNonCacheable
;	VMMarkBacking
;	VMMarkCleanUnused
;	setPTEntryGivenPage
;	VMShouldClean
;	VMAllocateMemory
;	VMLastExportedFunc
;	major_0x0b144

VMDoSomethingWithTLB	;	OUTSIDE REFERER
	mfpvr	r9
	clrlwi	r8, r8,  0x01
	rlwinm.	r9, r9,  0,  0, 14
	stw		r8,  0x0000(r14)
	slwi	r9, r4, 12
	sync	
	tlbie	r9
	beq-	VMDoSomethingWithTLB_0x28
	sync	
	tlbsync	

VMDoSomethingWithTLB_0x28
	sync	
	isync	
	lwz		r9,  0x0004(r14)
	oris	r8, r8,  0x8000
	rlwimi	r16, r9, 29, 27, 27
	rlwimi	r16, r9, 27, 28, 28
	mtcrf	 0x07, r16
	blr		



;	                       VMDoSomeIO                       

;	Xrefs:
;	getPTEntryGivenPage
;	VMIsUnmodified
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	PageSetCommon
;	VMMakePageNonCacheable
;	VMMarkCleanUnused
;	VMMarkResident
;	setPTEntryGivenPage
;	VMShouldClean
;	major_0x09b40
;	major_0x0b144

VMDoSomeIO	;	OUTSIDE REFERER
	stw		r16,  0x0000(r15)

VMDoSomeIO_0x4	;	OUTSIDE REFERER
	stw		r9,  0x0004(r14)
	eieio	
	stw		r8,  0x0000(r14)
	sync	
	blr		



;	                     major_0x09b40                      

;	Xrefs:
;	VMFinalInit
;	VMInit
;	VMExchangePages
;	VMLRU
;	VMMakePageCacheable
;	VMMakePageWriteThrough
;	VMMakePageNonCacheable
;	VMMarkBacking
;	VMMarkCleanUnused
;	VMMarkResident
;	setPTEntryGivenPage
;	VMAllocateMemory
;	major_0x0b144

major_0x09b40	;	OUTSIDE REFERER
	lwz		r8,  0x0e98(r1)
	rlwinm	r16, r16,  0, 21, 19
	addi	r8, r8,  0x01
	stw		r8,  0x0e98(r1)
	rlwimi	r16, r9,  0,  0, 19
	li		r8, -0x01
	stw		r8,  0x0340(r1)
	stw		r8,  0x0348(r1)
	stw		r8,  0x0350(r1)
	stw		r8,  0x0358(r1)
	li		r8,  0x00
	li		r9,  0x00
	b		VMDoSomeIO

VMSecondLastExportedFunc	;	OUTSIDE REFERER
	lwz		r8,  0x06a0(r1)



;	                   VMLastExportedFunc                   

;	Xrefs:
;	major_0x09b40


VMLastExportedFunc
	lwz		r14,  0x06a4(r1)
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
	bge-	VMLastExportedFunc_0x87
	bge-	cr1, VMLastExportedFunc_0x83
	bge-	cr2, VMLastExportedFunc_0x7f
	bge-	cr3, VMLastExportedFunc_0x7b
	lwzu	r7,  0x0020(r14)
	lwz		r8,  0x0008(r14)
	lwz		r9,  0x0010(r14)
	lwz		r5,  0x0018(r14)
	cmpwi	r7,  0x00
	cmpwi	cr1, r8,  0x00
	cmpwi	cr2, r9,  0x00
	cmpwi	cr3, r5,  0x00
	bge-	VMLastExportedFunc_0x87
	bge-	cr1, VMLastExportedFunc_0x83
	bge-	cr2, VMLastExportedFunc_0x7f
	blt-	cr3, VMLastExportedFunc_0xd7

VMLastExportedFunc_0x7b
	addi	r14, r14,  0x08

VMLastExportedFunc_0x7f
	addi	r14, r14,  0x08

VMLastExportedFunc_0x83
	addi	r14, r14,  0x08

VMLastExportedFunc_0x87
	lwz		r9,  0x0e94(r1)
	rlwinm	r8, r6,  7,  1, 24
	addi	r9, r9,  0x01
	stw		r9,  0x0e94(r1)
	rlwimi	r8, r4, 22, 26, 31
	lwz		r9,  0x0688(r1)
	oris	r8, r8,  0x8000
	rlwimi	r9, r16,  0,  0, 19
	ori		r9, r9,  0x100
	ori		r16, r16,  0x08
	rlwimi	r9, r16,  3, 24, 24
	rlwimi	r9, r16, 31, 26, 26
	rlwimi	r9, r16,  1, 25, 25
	xori	r9, r9,  0x40
	rlwimi	r9, r16, 30, 31, 31
	lwz		r7,  0x06a4(r1)
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
	bl		PagingFunc1
	bnel+	Local_Panic
	mr		r27, r7
	mr		r29, r8
	mr		r30, r9
	mr		r31, r5
	mr		r28, r16
	mr		r26, r14
	lwz		r9,  0x06a8(r1)
	bl		VeryPopularFunction
	mtlr	r6
	b		VMDoSomethingWithTLB



;	                     major_0x09c9c                      

;	Xrefs:
;	VMInit

major_0x09c9c	;	OUTSIDE REFERER
	addi	r8, r1,  0x6c0
	lwz		r9,  0x06ac(r1)
	rlwimi	r8, r7, 18, 26, 29
	cmplw	r7, r9
	lwz		r8,  0x0000(r8)
	rlwinm	r7, r7,  2, 14, 29
	bge+	VMReturnMinus1
	lwzx	r9, r8, r7
	rlwinm	r9, r9,  0,  0, 19
	blr		
