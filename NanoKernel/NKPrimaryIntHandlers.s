;	LookupInterruptHandler

;	Called at init time to get the (64b-aligned) physical address
;	off the primary interrupt handler ("PIH") for this platform.
;	The interrupt handler kind is specified in a one-byte field in
;	ConfigInfo, and is an index into the below macro-populated
;	table.

;	ARG		NKConfigurationInfo *r3
;	RET		PIHPtr r7
;	CLOB	r12



MaxPIHCount		equ		12



	MACRO
	DeclarePIH		&n, &code

@h
	org				PIHTableStart + &n * 2
	dc.w			&code - PIHTableStart
	org				@h

	ENDM



LookupInterruptHandler	;	OUTSIDE REFERER
	mflr	r12
	bl		PIHTableEnd

PIHTableStart
	dcb.w	MaxPIHCount, 0
PIHTableEnd

	mflr	r7
	mtlr	r12
	lbz		r12, NKConfigurationInfo.InterruptHandlerKind(r3)
	slwi	r12, r12,  1
	lhzx	r12, r7, r12
	add		r7, r7, r12
	blr



;	CommonPIHPath

;	At least I think so.

;	Xrefs:
;	KCPropogateExternalInterrupt
;	PDM_PIH
;	PBX_PIH
;	GazellePIH
;	TNT_PIH
;	GossamerPIH
;	NewWorldPowerBookPIH
;	CordycepsPIH
;	NewWorldPIH
;	UnknownPIH

;	> r1    = kdp

;	Alignment probably to fit a cache block (very oft-run code).
	align	5

CommonPIHPath	;	OUTSIDE REFERER
	mtsprg	3, r30
	lwz		r23, KDP.PA_EmulatorIplValue(r1)
	lwz		r27, -0x0428(r1)

CommonPIHPath_0xc	;	OUTSIDE REFERER
	cmpwi	cr7, r28, 0
	li		r31,  0x00
	blt-	cr7, @negative

	beq-	cr7, @zero_rupt
	ori		r28, r28, 0x8000
	lwz		r31, KDP.PostIntMaskInit(r1)
@zero_rupt

	andis.	r8, r11, 0x8000 >> 14		;	some kind of perfmon bit
	cmpwi	cr1, r27, 0x00
	lwz		r29, KDP.ClearIntMaskInit(r1)

	bne-	@noperf
	bne-	cr1, CommonPIHPath_0x78
@noperf

	rlwinm.	r8, r7,  0, 10, 10
	beq-	CommonPIHPath_0x14c
	sth		r28,  0x0000(r23)
	or		r13, r13, r31
	bgt-	cr7, @negative
	and		r13, r13, r29

@negative
	_AssertAndRelease	PSA.PIHLock, scratch=r8
	bl		Restore_r20_r31
	b		skeleton_key

CommonPIHPath_0x78
	_AssertAndRelease	PSA.PIHLock, scratch=r8
	bl		Save_r14_r19

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	mr		r8, r27

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne-	CommonPIHPath_0x100
	clrlwi	r9, r28,  0x11
	stw		r9,  0x0010(r30)
	stw		r22,  0x0014(r30)
	bl		major_0x0db04
	_AssertAndRelease	PSA.SchLock, scratch=r8

;	r6 = ewa
	bl		Restore_r14_r31
	b		skeleton_key

CommonPIHPath_0x100
	li		r27,  0x00
	lwz		r23,  0x067c(r1)
	stw		r27, -0x0428(r1)
	_AssertAndRelease	PSA.SchLock, scratch=r8
	bl		Restore_r14_r19

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

	b		CommonPIHPath_0xc

CommonPIHPath_0x14c
	_AssertAndRelease	PSA.PIHLock, scratch=r8
	bl		Save_r14_r19

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	lwz		r30, -0x0440(r1)
	or		r31, r31, r30
	stw		r31, -0x0440(r1)
	sth		r28, -0x043c(r1)
	lwz		r31, -0x08f0(r1)
	mfsprg	r30, 0
	lwz		r28,  0x0064(r31)
	lbz		r29,  0x0018(r31)
	ori		r28, r28,  0x10
	stw		r28,  0x0064(r31)
	cmpwi	r29,  0x00
	lhz		r16,  0x001a(r31)
	beq-	CommonPIHPath_0x1dc
	lhz		r17, -0x0116(r30)
	cmpw	cr1, r16, r17
	rlwinm.	r8, r28,  0, 26, 26
	beq-	cr1, CommonPIHPath_0x1d0
	bne-	CommonPIHPath_0x230

CommonPIHPath_0x1d0
	mr		r8, r31
	bl		DequeueTask
	b		CommonPIHPath_0x218

CommonPIHPath_0x1dc
	addi	r16, r31,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	lbz		r17,  0x0037(r31)
	cmpwi	r17,  0x01
	bne-	CommonPIHPath_0x210
	addi	r8, r31,  0x20
	bl		major_0x136c8

CommonPIHPath_0x210
	lwz		r16,  0x0e80(r1)
	stw		r16, PSA.OtherSystemContextPtr(r1)

CommonPIHPath_0x218
	li		r16,  0x00
	stb		r16,  0x0019(r31)
	mr		r8, r31
	bl		TaskReadyAsNext
	mr		r8, r31
	bl		CalculateTimeslice

CommonPIHPath_0x230
	mr		r8, r31
	bl		major_0x14af8
	_AssertAndRelease	PSA.SchLock, scratch=r16

;	r6 = ewa
	bl		Restore_r14_r31
	b		skeleton_key



;	KCPropogateExternalInterrupt


	DeclareMPCall	122, KCPropogateExternalInterrupt

KCPropogateExternalInterrupt	;	OUTSIDE REFERER
	rlwinm.	r8, r7, 0, 10, 10
	cmplwi	cr1, r3, 7
	bne-	@notthegumdropbuttons
	bgt-	cr1, @too_high

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

	;	Get current interrupt level
	lwz		r23, KDP.PA_EmulatorIplValue(r1)
	lbz		r28, 1(r23)

	;	r28 = max(current level, desired level)
	cmpw	r3, r28
	ble-	@desired_is_lower
	mr		r28, r3
@desired_is_lower

	li		r27,  0x00
	li		r3,  0x00
	bl		Restore_r14_r19
	b		CommonPIHPath_0xc

@notthegumdropbuttons
	b		ReturnMPCallOOM

@too_high
	b		ReturnParamErrFromMPCall



Save_r14_r19	;	OUTSIDE REFERER
	stw		r14,  ContextBlock.r14(r6)
	stw		r15,  ContextBlock.r15(r6)
	stw		r16,  ContextBlock.r16(r6)
	stw		r17,  ContextBlock.r17(r6)
	stw		r18,  ContextBlock.r18(r6)
	stw		r19,  ContextBlock.r19(r6)
	blr



Restore_r14_r19	;	OUTSIDE REFERER
	lwz		r14,  ContextBlock.r14(r6)
	lwz		r15,  ContextBlock.r15(r6)
	lwz		r16,  ContextBlock.r16(r6)
	lwz		r17,  ContextBlock.r17(r6)
	lwz		r18,  ContextBlock.r18(r6)
	lwz		r19,  ContextBlock.r19(r6)
	blr



;	PDM68kInterruptTable

;	The (byte-sized) entries in the table are 68k rupt numbers.

;	Strictly unnecessary considering indexing method,
;	but might speed it up?
	align	6

PDM68kInterruptTable	;	OUTSIDE REFERER
	dc.l	0x00010202
	dc.l	0x04040404
	dc.l	0x03030303
	dc.l	0x04040404
	dc.l	0x04040404
	dc.l	0x04040404
	dc.l	0x04040404
	dc.l	0x04040404
	dc.l	0x07070707
	dc.l	0x07070707
	dc.l	0x07070707
	dc.l	0x07070707
	dc.l	0x07070707
	dc.l	0x07070707
	dc.l	0x07070707
	dc.l	0x07070707



;	PDM (Piltdown Man) Primary Interrupt Handler

;	= first ("G1") Power Macs. NuBus. Models
;	61xx, 71xx, 81xx.

	DeclarePIH		1, PDM_PIH

	align		6

PDM_PIH

	_Lock		PSA.PIHLock, scratch1=r8, scratch2=r9

	bl			Save_r20_r31

	addi		r9, r1, PSA.BlueVecBase
	andis.		r8, r11, 0x8000 >> 14		;	SRR1 mystery bit

	mfsprg		r30, 3

	bne-		@nocount
	lwz			r21, KDP.NanoKernelInfo + NKNanoKernelInfo.ExternalIntCount(r1)
	addi		r21, r21,  0x01
	stw			r21, KDP.NanoKernelInfo + NKNanoKernelInfo.ExternalIntCount(r1)
@nocount

	;	Switch to Blue vector table
	mtsprg		3, r9

	;	Do the bare minimum to access the device at 0x50f30000

	;	Hardcoded address is hardcoded
	lis			r22,  0x50f3;0000

	;	*Prepare* to enable data paging
	mfmsr		r23
	_bset		r20, r23, MSR_DRbit
	;ori			r20, r23, 0x80000000 >> MSR_DRbit

	;	Find a SPAC to set sr5 from
	lwz			r25, PSA.OtherSystemAddrSpcPtr(r1)
	rlwinm		r24, r22,  6, 26, 29
	addi		r25, r25, AddressSpace.SRs

	;	Save sr5 in r21, load new value from SPAC, isync
	mfsrin		r21, r22
	lwzx		r24, r25, r24
	mtsrin		r24, r22
	isync

	;	Turn on data paging, isync
	mtmsr		r20
	isync

	;	Ask (the PIC?) something
	li			r20,  0xc0
	stb			r20, -0x6000(r22)
	eieio
	lbz			r20, -0x6000(r22)

	;	Turn data paging back off, isync
	mtmsr		r23
	isync

	;	Lookup a 68k int number using this 6-bit thing from the PIC
	lwz			r23, KDP.PA_NanoKernelCode(r1)
	rlwimi		r23, r20, 0, 26, 31
	llabel	r28, PDM68kInterruptTable
	lbzx		r28, r28, r23

	;	Restore sr5, isync
	mtsrin		r21, r22
	isync

	b			CommonPIHPath



;	PBX Primary Interrupt Handler

;	= pre-PCI PowerPC 'Books. Possibly not including the 5300?

	DeclarePIH		3, PBX_PIH

	align		6

PBX_PIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	PBX_PIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

PBX_PIH_0x38
	mtsprg	3, r9
	lis		r22,  0x50f3
	mfmsr	r23
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	ori		r20, r23,  0x10
	mtmsr	r20
	isync
	lwz		r20, -0x6000(r22)
	ori		r20, r20,  0x80
	stw		r20, -0x6000(r22)
	eieio
	lwz		r20, -0x6000(r22)
	rlwimi	r20, r20,  3, 26, 28
	stw		r20, -0x6000(r22)
	eieio
	mr		r28, r20
	mtmsr	r23
	isync
	mtsrin	r21, r22
	isync
	clrlwi	r28, r28,  0x1d

;	r1 = kdp
	b		CommonPIHPath



;	Gazelle Primary Interrupt Handler

;	= later low-end "G2" Power Macs. 603 series
;	processors. PCI. Models 54xx-55xx, 64xx-65xx.
;	The 54xx/64xx ROM actually identifies as Alchemy, not
;	Gazelle, and SheepShaver considers this difference when
;	patching the ROM Nanokernels. But, Wikipedia describes
;	these machines as minor upgrades, EveryMac calls them
;	Gazelle, and they use the same PIH type.

	DeclarePIH		5, GazellePIH

	align		6

GazellePIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	GazellePIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

GazellePIH_0x38
	mtsprg	3, r9
	lis		r22, -0xd00
	mfmsr	r20
	ori		r23, r20,  0x10
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	mtmsr	r23
	isync
	li		r26,  0x20
	lwbrx	r27, r26, r22
	rlwinm	r27, r27,  1,  1,  1
	eieio
	lis		r23, -0x8000
	li		r26,  0x28
	stwbrx	r23, r26, r22
	eieio
	li		r26,  0x24
	lwbrx	r23, r26, r22
	eieio
	rlwinm	r28, r23,  1,  1,  1
	and		r28, r27, r28
	or		r23, r28, r23
	stwbrx	r23, r26, r22
	eieio
	li		r26,  0x2c
	lwbrx	r26, r26, r22
	eieio
	rlwimi	r26, r23,  0,  1,  1
	and		r23, r26, r23
	mtmsr	r20
	isync
	andis.	r28, r23,  0x10
	li		r28,  0x07
	bne-	GazellePIH_0x104
	rlwinm	r28, r23,  0, 15, 16
	rlwimi.	r28, r23,  0, 22, 31
	li		r28,  0x04
	bne-	GazellePIH_0x104
	andis.	r28, r23,  0x5fca
	rlwimi.	r28, r23,  0, 17, 20
	li		r28,  0x02
	bne-	GazellePIH_0x104
	andis.	r28, r23,  0x04
	li		r28,  0x01
	bne-	GazellePIH_0x104
	li		r28,  0x00

GazellePIH_0x104
	mtsrin	r21, r22
	isync

;	r1 = kdp
	b		CommonPIHPath



;	TNT (The New Tesseract) Primary Interrupt Handler

;	= High-end and mid-range "G2" Power Macs. PCI. 603
;	and 604 series processors. Models 7200-7600, 8500-8600,
;	9500-9600.

	DeclarePIH		2, TNT_PIH

	align		6

TNT_PIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	TNT_PIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

TNT_PIH_0x38
	mtsprg	3, r9
	lis		r22, -0xd00
	mfmsr	r20
	ori		r23, r20,  0x10
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	mtmsr	r23
	isync
	lis		r23, -0x8000
	li		r26,  0x28
	stwbrx	r23, r26, r22
	eieio
	li		r26,  0x24
	lwbrx	r23, r26, r22
	li		r26,  0x2c
	lwbrx	r26, r26, r22
	and		r23, r26, r23
	eieio
	mtmsr	r20
	isync
	rlwinm.	r28, r23,  0, 11, 11
	li		r28,  0x07
	bne-	TNT_PIH_0xd8
	rlwinm	r28, r23,  0, 15, 16
	rlwimi.	r28, r23,  0, 21, 31
	li		r28,  0x04
	bne-	TNT_PIH_0xd8
	rlwinm.	r28, r23,  0, 17, 17
	li		r28,  0x03
	bne-	TNT_PIH_0xd8
	andis.	r28, r23,  0x7fea
	rlwimi.	r28, r23,  0, 18, 19
	li		r28,  0x02
	bne-	TNT_PIH_0xd8
	rlwinm.	r28, r23, 14, 31, 31

TNT_PIH_0xd8
	mtsrin	r21, r22
	isync

;	r1 = kdp
	b		CommonPIHPath



;	Gossamer (and GRX) Primary Interrupt Handler

;	= beige (pre-iMac) G3s. PIH 07 also used for GRX = OldWorld
;	PowerBook G3 Series.

	DeclarePIH		7, GossamerPIH

	align		6

GossamerPIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	GossamerPIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

GossamerPIH_0x38
	mtsprg	3, r9
	mfmsr	r20
	ori		r23, r20,  0x10
	lis		r22, -0xd00
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	mtmsr	r23
	isync
	lis		r23, -0x8000
	li		r25,  0x28
	stwbrx	r23, r25, r22
	eieio
	li		r25,  0x24
	lwbrx	r23, r25, r22
	li		r25,  0x2c
	lwbrx	r25, r25, r22
	and		r23, r25, r23
	eieio
	lis		r24, -0x8000
	li		r25,  0x18
	stwbrx	r24, r25, r22
	eieio
	li		r25,  0x14
	lwbrx	r24, r25, r22
	li		r25,  0x1c
	lwbrx	r25, r25, r22
	and		r24, r25, r24
	eieio
	mtmsr	r20
	isync
	rlwinm.	r28, r23,  0, 11, 11
	li		r28,  0x07
	bne-	GossamerPIH_0x118
	rlwinm	r28, r23,  0, 15, 16
	rlwimi.	r28, r23,  0, 22, 31
	li		r28,  0x04
	bne-	GossamerPIH_0x118
	clrlwi.	r28, r24,  0x1e
	li		r28,  0x04
	bne-	GossamerPIH_0x118
	rlwinm.	r28, r24,  0, 21, 21
	li		r28,  0x03
	bne-	GossamerPIH_0x118
	andis.	r28, r23,  0x3fea
	rlwimi.	r28, r23,  0, 17, 20
	li		r28,  0x02
	bne-	GossamerPIH_0x118
	rlwinm.	r28, r24,  0, 20, 20
	li		r28,  0x01
	bne-	GossamerPIH_0x118
	rlwinm.	r28, r23, 14, 31, 31

GossamerPIH_0x118
	mtsrin	r21, r22
	isync

;	r1 = kdp
	b		CommonPIHPath



;	NewWorld PowerBook Primary Interrupt Handler

;	Only ever seen this on Mikey's (NewWorld) Lombard. So
;	apparently the Trampoline can also change the ROM's
;	default PIH.

	DeclarePIH		10, NewWorldPowerBookPIH	;	logged as 'kind 0a'

	align		6

NewWorldPowerBookPIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	NewWorldPowerBookPIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

NewWorldPowerBookPIH_0x38
	mtsprg	3, r9
	lwz		r26, -0x0020(r1)
	mfmsr	r20
	ori		r23, r20,  0x10
	lwz		r22,  0x0ec0(r26)
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	mtmsr	r23
	isync
	li		r23,  0x80
	stw		r23,  0x0018(r22)
	eieio
	lwz		r23,  0x0014(r22)
	lwz		r25,  0x001c(r22)
	and		r23, r25, r23
	lwz		r24,  0x0004(r22)
	lwz		r25,  0x000c(r22)
	and		r24, r25, r24
	mtmsr	r20
	isync
	stw		r23,  0x0f28(r26)
	stw		r24,  0x0f2c(r26)
	lis		r25,  0x00
	ori		r25, r25,  0x3f60
	li		r28,  0x07

NewWorldPowerBookPIH_0xb0
	lwz		r26,  0x001c(r25)
	and.	r26, r24, r26
	bne-	NewWorldPowerBookPIH_0xd4
	lwzu	r26, -0x0004(r25)
	and.	r26, r23, r26
	bne-	NewWorldPowerBookPIH_0xd4
	addi	r28, r28, -0x01
	cmplwi	r28,  0x00
	bne+	NewWorldPowerBookPIH_0xb0

NewWorldPowerBookPIH_0xd4
	mtsrin	r21, r22
	isync

;	r1 = kdp
	b		CommonPIHPath



;	Cordyceps Primary Interrupt Handler

;	= early low-end "G2" Power Macs. 603 series
;	processors. PCI. Models 52xx-53xx, 62xx-63xx.

	DeclarePIH		4, CordycepsPIH

	align		6

CordycepsPIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	CordycepsPIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

CordycepsPIH_0x38
	mtsprg	3, r9
	lis		r22,  0x5300
	mfmsr	r23
	mfspr	r26, dbat0u
	mfspr	r27, dbat0l
	ori		r20, r22,  0x03
	mtspr	dbat0u, r20
	ori		r20, r22,  0x2a
	mtspr	dbat0l, r20
	isync
	ori		r20, r23,  0x10
	mtmsr	r20
	isync
	lwz		r20,  0x001c(r22)
	sync
	lis		r20,  0x00
	stw		r20,  0x001c(r22)
	eieio
	lwz		r20,  0x001c(r22)
	lwz		r20,  0x001c(r22)
	sync
	lwz		r28,  0x0024(r22)
	sync
	xori	r28, r28,  0x07
	mtmsr	r23
	isync
	mtspr	dbat0l, r27
	mtspr	dbat0u, r26
	clrlwi	r28, r28,  0x1d

;	r1 = kdp
	b		CommonPIHPath



;	NewWorld Primary Interrupt Handler

;	(At least most NewWorld machines.)
;	The '06' in the NewWorld ROM ConfigInfo seems to
;	be left alone by the Trampoline on most machines.

;	This ID was reused from, of all things, the Pippin.

	DeclarePIH		6, NewWorldPIH

	align		6

NewWorldPIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	NewWorldPIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

NewWorldPIH_0x38
	mtsprg	3, r9
	mfmsr	r23
	lwz		r20, -0x0020(r1)
	lhz		r27,  0x0910(r1)
	lwz		r22,  0x0f18(r20)
	li		r28,  0x00
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	cmpwi	cr1, r27,  0x00
	andis.	r26, r11,  0x02
	beq-	cr1, NewWorldPIH_0x23c
	beq-	NewWorldPIH_0x150
	lbz		r29,  0x0f93(r20)
	stb		r28,  0x0f93(r20)
	addi	r26, r1,  0x912
	cmpwi	cr1, r29,  0x07
	cmplwi	r27,  0x01
	bne+	cr1, NewWorldPIH_0xa8
	addi	r27, r27, -0x01
	ble-	NewWorldPIH_0x1fc
	lbzx	r26, r26, r27
	lbz		r28,  0x3f00(r26)
	b		NewWorldPIH_0x1fc

NewWorldPIH_0xa8
	cmplwi	r27,  0x01
	addi	r27, r27, -0x01
	ble-	NewWorldPIH_0x1fc
	add		r26, r26, r27
	addi	r27, r20,  0xf93
	lbz		r24,  0x0000(r26)

NewWorldPIH_0xc0
	lbzu	r28, -0x0001(r27)
	cmpw	r24, r28
	cmpwi	cr1, r28,  0xfe
	beq-	NewWorldPIH_0xdc
	bne+	cr1, NewWorldPIH_0xc0
	li		r28, -0x01
	b		NewWorldPIH_0x1fc

NewWorldPIH_0xdc
	li		r28,  0xff
	stb		r28,  0x0000(r27)
	addi	r27, r20,  0xf28
	rlwinm	r20, r24, 29, 29, 29
	clrlwi	r24, r24,  0x1b
	lis		r28, -0x8000
	add		r27, r27, r20
	srw		r28, r28, r24
	lwz		r24,  0x0000(r27)
	andc	r24, r24, r28
	addi	r26, r26, -0x01
	stw		r24,  0x0000(r27)
	lbz		r26,  0x0000(r26)
	li		r28,  0x00
	ori		r29, r23,  0x10
	lis		r27,  0x02
	ori		r27, r27,  0xb0
	mtmsr	r29
	isync
	stwx	r28, r22, r27
	mtmsr	r23
	isync
	lhz		r27,  0x0910(r1)
	cmpwi	r26,  0xff
	addi	r27, r27, -0x01
	beq+	NewWorldPIH_0x148
	lbz		r28,  0x3f00(r26)

NewWorldPIH_0x148
	sth		r27,  0x0910(r1)
	b		NewWorldPIH_0x1fc

NewWorldPIH_0x150
	lhz		r27,  0x0f88(r20)
	ori		r20, r23,  0x10
	lis		r26,  0x02
	ori		r26, r26, 160
	mtmsr	r20
	isync
	lwbrx	r26, r22, r26
	clrlwi	r26, r26,  0x14
	cmplwi	r26,  0x40
	cmplwi	cr1, r26,  0x41
	li		r29,  0x00
	beq-	NewWorldPIH_0x208
	bge-	cr1, NewWorldPIH_0x218
	cmplw	r26, r27
	lis		r27,  0x02
	ori		r27, r27,  0xb0
	bne+	NewWorldPIH_0x198
	stwx	r29, r22, r27

NewWorldPIH_0x198
	mtmsr	r23
	isync
	lwz		r20, -0x0020(r1)
	lbz		r28,  0x3f00(r26)
	cmpwi	r28,  0x07
	bne+	NewWorldPIH_0x1b8
	stb		r28,  0x0f93(r20)
	b		NewWorldPIH_0x1fc

NewWorldPIH_0x1b8
	lhz		r27,  0x0910(r1)
	add		r24, r27, r1
	addi	r27, r27,  0x01
	stb		r26,  0x0912(r24)
	rlwinm	r25, r26, 29, 29, 29
	clrlwi	r26, r26,  0x1b
	lis		r24, -0x8000
	sth		r27,  0x0910(r1)
	addi	r27, r20,  0xf28
	add		r27, r27, r25
	lwz		r25,  0x0000(r27)
	srw		r24, r24, r26
	or		r25, r25, r24
	li		r24,  0xff
	stw		r25,  0x0000(r27)
	addi	r27, r20,  0xf8c
	stbx	r24, r28, r27

NewWorldPIH_0x1fc
	mtsrin	r21, r22
	isync

;	r1 = kdp
	b		CommonPIHPath

NewWorldPIH_0x208
	mtmsr	r23
	isync
	li		r28, -0x01
	b		NewWorldPIH_0x1fc

NewWorldPIH_0x218
	lis		r27,  0x02
	ori		r27, r27,  0xb0
	li		r29,  0x00
	stwx	r29, r22, r27
	eieio
	mtmsr	r23
	isync
	li		r28, -0x01
	b		NewWorldPIH_0x1fc

NewWorldPIH_0x23c
	addi	r27, r27,  0x01
	li		r28, -0x01
	sth		r27,  0x0910(r1)
	stw		r28,  0x0912(r1)
	stw		r28,  0x0f90(r20)
	xoris	r28, r28,  0x100
	stw		r28,  0x0f8c(r20)
	li		r28,  0x00
	b		NewWorldPIH_0x1fc



;	Primary Interrupt Handler for a mystery machine

	DeclarePIH		8, UnknownPIH

	align		6

UnknownPIH

	_Lock			PSA.PIHLock, scratch1=r8, scratch2=r9

;	r6 = ewa
	bl		Save_r20_r31
;	r8 = sprg0 (not used by me)

	addi	r9, r1, -0x750
	andis.	r8, r11,  0x02
	mfsprg	r30, 3
	bne-	UnknownPIH_0x38
	lwz		r21,  0x0e80(r1)
	addi	r21, r21,  0x01
	stw		r21,  0x0e80(r1)

UnknownPIH_0x38
	mtsprg	3, r9
	mfmsr	r23
	lwz		r20, -0x0020(r1)
	lhz		r27,  0x0910(r1)
	lwz		r22,  0x0f18(r20)
	li		r28,  0x00
	lwz		r25, -0x03fc(r1)
	rlwinm	r24, r22,  6, 26, 29
	addi	r25, r25,  0x30
	mfsrin	r21, r22
	lwzx	r24, r25, r24
	mtsrin	r24, r22
	isync
	cmpwi	cr1, r27,  0x00
	andis.	r26, r11,  0x02
	beq-	cr1, UnknownPIH_0x23c
	beq-	UnknownPIH_0x170
	cmplwi	r27,  0x01
	ble-	UnknownPIH_0x1f8
	addi	r27, r27, -0x01
	addi	r26, r1,  0x912
	add		r26, r26, r27
	addi	r27, r20,  0xee0
	lbz		r24,  0x0000(r26)
	mr		r29, r24
	cmpwi	r24,  0x20
	blt+	UnknownPIH_0xac
	addi	r27, r27,  0x04
	addi	r24, r24, -0x20

UnknownPIH_0xac
	lwz		r27,  0x0000(r27)
	lis		r28, -0x8000
	srw		r28, r28, r24
	and.	r27, r27, r28
	bne-	UnknownPIH_0xc8
	li		r28, -0x01
	b		UnknownPIH_0x1f8

UnknownPIH_0xc8
	addi	r27, r20,  0xec4
	cmpwi	r29,  0x20
	blt+	UnknownPIH_0xd8
	addi	r27, r27,  0x04

UnknownPIH_0xd8
	lwz		r24,  0x0000(r27)
	andc	r24, r24, r28
	stw		r24,  0x0000(r27)
	addi	r27, r20,  0xee0
	cmpwi	r29,  0x20
	blt+	UnknownPIH_0xf4
	addi	r27, r27,  0x04

UnknownPIH_0xf4
	lwz		r29,  0x0000(r27)
	andc	r29, r29, r28
	stw		r29,  0x0000(r27)
	addi	r26, r26, -0x01
	lbz		r26,  0x0000(r26)
	cmpwi	r26,  0xff
	beq-	UnknownPIH_0x114
	b		UnknownPIH_0x118

UnknownPIH_0x114
	li		r26,  0x800

UnknownPIH_0x118
	ori		r28, r23,  0x10
	lis		r27,  0x02
	ori		r27, r27,  0xb0
	mtmsr	r28
	isync
	li		r28,  0x00
	stwx	r28, r22, r27
	eieio
	cmpwi	r26,  0x800
	beq-	UnknownPIH_0x158
	lis		r28,  0x01
	ori		r28, r28,  0x00
	rlwinm	r27, r26,  5, 16, 31
	add		r28, r28, r27
	lwbrx	r28, r22, r28
	rlwinm	r28, r28, 16, 28, 31

UnknownPIH_0x158
	mtmsr	r23
	isync
	lhz		r27,  0x0910(r1)
	addi	r27, r27, -0x01
	sth		r27,  0x0910(r1)
	b		UnknownPIH_0x1f8

UnknownPIH_0x170
	ori		r27, r23,  0x10
	lis		r26,  0x02
	ori		r26, r26, 160
	lis		r28,  0x01
	ori		r28, r28,  0x00
	mtmsr	r27
	isync
	lwbrx	r26, r22, r26
	clrlwi	r26, r26,  0x14
	cmplwi	r26,  0x31
	cmplwi	cr1, r26,  0x28
	beq-	UnknownPIH_0x204
	bge-	cr1, UnknownPIH_0x214
	rlwinm	r27, r26,  5, 16, 31
	add		r28, r28, r27
	lwbrx	r28, r22, r28
	rlwinm	r28, r28, 16, 28, 31
	mtmsr	r23
	isync
	lhz		r27,  0x0910(r1)
	add		r24, r27, r1
	addi	r27, r27,  0x01
	stb		r26,  0x0912(r24)
	sth		r27,  0x0910(r1)
	addi	r27, r20,  0xec4
	cmpwi	r26,  0x20
	blt+	UnknownPIH_0x1e4
	addi	r27, r27,  0x04
	addi	r26, r26, -0x20

UnknownPIH_0x1e4
	lwz		r25,  0x0000(r27)
	lis		r24, -0x8000
	srw		r24, r24, r26
	or		r25, r25, r24
	stw		r25,  0x0000(r27)

UnknownPIH_0x1f8
	mtsrin	r21, r22
	isync

;	r1 = kdp
	b		CommonPIHPath

UnknownPIH_0x204
	mtmsr	r23
	isync
	li		r28, -0x01
	b		UnknownPIH_0x1f8

UnknownPIH_0x214
	lis		r27,  0x02
	ori		r27, r27,  0xb0
	li		r29,  0x00
	stwx	r29, r22, r27
	eieio
	mtmsr	r23
	isync
	li		r28,  0x06
	li		r28, -0x01
	b		UnknownPIH_0x1f8

UnknownPIH_0x23c
	addi	r27, r27,  0x01
	li		r28, -0x01
	sth		r27,  0x0910(r1)
	stw		r28,  0x0912(r1)
	li		r28,  0x00
	stw		r28,  0x0ee4(r20)
	stw		r28,  0x0ee0(r20)
	b		UnknownPIH_0x1f8
