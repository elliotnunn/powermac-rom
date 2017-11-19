;	When we receive control:
;		r3 = ConfigInfo
;		r4 = ProcessorInfo
;		r5 = SystemInfo
;		r6 = DiagInfo
;		r7 = RTAS_flag ('RTAS' or 0)
;		r8 = RTAS_proc
;		r9 = HWInfo



InitBuiltin



;	Leave zero in r0 (it is rather a silly place).

	li		r0, 0



;	Initialize segment registers (understand these better!)

	isync
	lis			r12, 0x2000
	mtsr		0, r12
	mtsr		1, r0
	mtsr		2, r0
	mtsr		3, r0
	mtsr		4, r0
	mtsr		5, r0
	mtsr		6, r0
	mtsr		7, r0
	mtsr		8, r0
	mtsr		9, r0
	mtsr		10, r0
	mtsr		11, r0
	mtsr		12, r0
	mtsr		13, r0
	mtsr		14, r0
	mtsr		15, r0
	isync



;	Zero out the timebase (rtc on 601) and upper BAT registers
;	(this is best practice for invalidating BATs)
;	(Interestingly, SheepShaver also uses r12 for this PVR access.)

	mfspr	r12, pvr
	rlwinm.	r12, r12, 0, 0, 14
	bne-	@not601

	mtspr	rtcl, r0
	mtspr	rtcu, r0
	mtspr	ibat0l, r0
	mtspr	ibat1l, r0
	mtspr	ibat2l, r0
	mtspr	ibat3l, r0

	b		@endif601
@not601

	mtspr	tbl, r0
	mtspr	tbu, r0
	mtspr	ibat0u, r0
	mtspr	ibat1u, r0
	mtspr	ibat2u, r0
	mtspr	ibat3u, r0
	mtspr	dbat0u, r0
	mtspr	dbat1u, r0
	mtspr	dbat2u, r0
	mtspr	dbat3u, r0

@endif601




;	The Trampoline instructs us to put the base of the blue area at
;	this physical address, which seems always to be the base of the
;	first RAM bank reported by the trampoline. (The kernel is also
;	expected to initialise MacOS LowMemory from a key/valye list.)

	lwz		r12, NKConfigurationInfo.PA_RelocatedLowMemInit(r3)



;	Search SysInfo for the first nonzero size RAM bank.

	addi	r10, r5, NKSystemInfo.Bank0Start - 4
@rambank_loop
	lwzu	r11, 8(r10)		; Bank0Size, Bank1Size...
	cmpwi	r11, 0
	beq+	@rambank_loop

	;	r10 points to BankXSize, r11 contains BankXSize



;	DeltaMemory = PA_RelocatedLowMemInit if fits in bank, else 0.

	subf	r11, r12, r11
	srawi	r11, r11, 31	; f... if PA_ > BankSize else 0...
	andc	r12, r12, r11	; zero DeltaMemory if PA_ > BankSize



;	BankSize -= DeltaMemory

	lwz		r11, 0(r10)
	subf	r11, r12, r11
	stw		r11, 0(r10)



;	BankStart += DeltaMemory

	lwz		r11, -4(r10)
	add		r11, r11, r12
	stw		r11, -4(r10)



;	PhysicalMemorySize -= DeltaMemory (+ another page if there is close to 2GB)

	lwz		r11, NKSystemInfo.PhysicalMemorySize(r5)
	addis	r15, r11, 1
	cmpwi	r15, 0
	bgt-	@skip_reducing_ram
	addi	r11, r11, -4096
@skip_reducing_ram
	subf	r11, r12, r11
	stw		r11, 0(r5)



;	Load PhysicalMemorySize - 1 into r15.
;
;	Create the HTABMASK for eventual insertion in lo half of SDR1:
;	-	Is number of bits used from hash func to index PTEGs in HTAB.
;	-	Arch allows 10..19 bits.
;		-	Bits 0-9 assumed by architecture.
;		-	Bits 10-18 in the low field of SDR1.
;		-	Bits 19-31 also in low field, but must be zeroed.
;	-	Our r14 "mask" = (future low half of SDR1) || 0xffff.
;		-	Therefore has an extra six ones.
;		-	Therefore equals HTAB size - 1.
;	-	Computed from PhysicalMemorySize as follows:
;
;	---------------------------------------------------------------------
;	Phys RAM		r14			HTABMASK bits	PTEGs in HTAB	HTAB size
;	(MB)						(10-19 allowed)
;	---------------------------------------------------------------------
;	<= 8		0000ffff			10				1k				64k
;	<= 16		0001ffff			11				2k				128k
;	<= 32		0003ffff			12				4k				256k
;	<= 64		0007ffff			13				8k				512k
;	<= 128		000fffff			14				16k				1024k
;	<= 256		001fffff			15				32k				2048k
;	 > 256		003fffff			16				64k				4096k

	lwz		r15, NKSystemInfo.PhysicalMemorySize(r5)
	addi	r15, r15, -1
	cntlzw	r12, r15

	lis		r14, 0x01ff
	srw		r14, r14, r12
	ori		r14, r14, 0xffff
	clrlwi	r14, r14, 10



;	Based on PhysicalMemorySize, guess how much memory the
;	kernel needs, including the HTAB. Leave it in r15.
;
;	-----------------------------
;	Phys RAM	r15			Kern
;	(MB)					pages
;	-----------------------------
;	>=   4		0001d000	  29
;	>=   8		0001e000	  30
;	>=  16		00030000	  48
;	>=  32		00054000	  84
;	>=  64		0009c000	 156
;	>= 128		0012c000	 300
;	>= 256		0024c000	 588
;	>= 512		0048c000	1164
;	>=1024		0050c000	1292
;	>=2048		0060c000	1548

	addis	r15, r15, 0x40
	rlwinm	r15, r15, 22, 10, 19
	add		r15, r15, r14
	lisori	r10, 0x0000c001
	add		r15, r15, r10



;	Search SysInfo backwards for a RAM bank that can fit:
;	-	A HTAB aligned to a multiple of its own length
;	-	An r15-size area immediately below that
;
;	Kernel structures (HTAB at top) will butt up against
;	BankEnd % HTABSIZE. Leave bottom in r13 and top in r12.

	addi	r10, r5, NKSystemInfo.EndOfBanks
@try_another_bank
	lwz		r11, -4(r10)			;	size
	lwzu	r12, -8(r10)			;	start
	add		r11, r12, r11			;	end
	andc	r13, r11, r14			;	end % HTABSIZE
	subf	r13, r15, r13			;	end % HTABSIZE - r15
	cmplw	r13, r12
	blt+	@try_another_bank
	cmplw	r13, r11
	bgt+	@try_another_bank

	add		r12, r13, r15



;	Populate SDR1 with HTABORG || HTABMASK:
;	-	HTABORG = top_of_bank % HTABSIZE (only top half)
;	-	HTABMASK = top half of r14 (which equals HTABSIZE-1)
;
;	Leave SDR1 in r12 and HTABORG (a full address) in r11.

	subf	r12, r14, r12
	rlwimi r12, r14, 16, 16, 31
	mtspr	sdr1, r12

	rlwinm r11, r12, 0, 0, 15



;	Recap: (matches SheepShaver notes on NKv1)
;		r11		HTABORG
;		r12		SDR1
;		r13		base of "reserved" kernel area
;		r14		HTABSIZE - 1
;		r15		size of "reserved" kernel area



;	Place the kernel data page (KDP) 8k below the HTAB,
;	and point SPRG0 at it. r1 almost always points to KDP.
;
;	Page above KDP becomes emulator data page (EDP).
;	Page below KDP becomes private v2 kernel globals.

	lisori	r1,	-0x2000
	add		r1, r1, r11

	mtsprg	0, r1



;	Init the reserved area to zero, up to the HTAB.
;
;	But if the machine has Thudded and dumped all its registers
;	(as evidenced by a saved SDR1) then don't zero that dump.

	lwz		r11, KDP.ThudSavedSDR1(r1)
	cmpw	r12, r11
	lis		r11, 0x7fff

	bne-	@did_not_panic
	subf	r11, r13, r1
	addi	r11, r11, KDP.StartOfPanicArea
@did_not_panic

	subf	r12, r14, r15
	addi	r12, r12, -0x01

@eraseloop
	addic.	r12, r12, -4

	subf	r10, r11, r12
	cmplwi	cr7, r10, KDP.EndOfPanicArea - KDP.StartOfPanicArea - 4

	ble-	cr7, @skipwrite
	stwx	r0, r13, r12
@skipwrite

	bne+	@eraseloop



;	Put r1 pointer (for indexing PSA/KDP) in CPU-0 EWA 

	stw		r1, EWA.PA_KDP(r1)



;	Set up the interrupt response page (IRP) at KDP - (10 pages).
;
;	(Point CPU-0 EWA to it and fill it with 0x68f168f1.)

	lisori	r12, IRPOffset
	add		r12, r12, r1
	stw		r12, EWA.PA_IRP(r1)

	bl		InitIRP



;	Set up runtime abstraction services (RTAS).
;
;	Kernel argument r7 is either 'RTAS' or zero. If 'RTAS':
;	-	Arg r8 points to RTAS dispatch proc.
;	-	Arg r9 points to HWInfo points to RTAS private data
;	-	Copy HWInfo into IRP
;
;	TODO: neaten, use records!


	lisori	r12, 'RTAS'
	cmpw	r7, r12
	bne-	@RTAS_absent

	stw		r8, KDP.RTAS_Proc(r1)

	lwz		r7, NKHWInfo.RTAS_PrivDataArea(r9)
	stw		r7, KDP.RTAS_PrivDataArea(r1)

	lwz		r11, EWA.PA_IRP(r1)
	addi	r11, r11, IRP.HWInfo
	li		r10, 0xc0

@RTAS_copyloop
	addic. r10, r10, -4
	lwzx	r12, r9, r10
	stwx	r12, r11, r10
	bgt+	@RTAS_copyloop

	stw		r23, PSA.NoIdeaR23(r1)
	b		@RTAS_done

@RTAS_absent
	stw		r0, KDP.RTAS_Proc(r1)
	stw		r0, KDP.RTAS_PrivDataArea(r1)

@RTAS_done



;	Copy 160 bytes of ProcessorInfo into KDP
;	(Way longer than anything I know about!)

	addi	r11, r1, KDP.ProcessorInfo
	li		r10, 160
@ProcessorInfo_copyloop
	addic. r10, r10, -4
	lwzx	r12, r4, r10
	stwx	r12, r11, r10
	bgt+	@ProcessorInfo_copyloop



;	Copy 320 bytes of SystemInfo into IRP

	lwz		r11, EWA.PA_IRP(r1)
	addi	r11, r11, IRP.SystemInfo
	li		r10, 320
@SystemInfo_copyloop
	addic. r10, r10, -4
	lwzx	r12, r5, r10
	stwx	r12, r11, r10
	bgt+	@SystemInfo_copyloop



;	If DiagnosticInfo != 0, copy it to PSA

	cmpwi	r6, 0
	beq-	@DiagInfo_skipcopy

	addi	r11, r1, PSA.DiagInfo
	li		r10, 256; NKDiagInfo.Size

@DiagInfo_copyloop
	addic. r10, r10, -4
	lwzx	r12, r6, r10
	stwx	r12, r11, r10
	bgt+	@DiagInfo_copyloop

@DiagInfo_skipcopy



;	Store a ConfigInfo pointer in KDP

	stw		r3, KDP.PA_ConfigInfo(r1)



;	Add to (presumably empty) ConfigFlags

	lwz		r9, KDP.PA_ConfigInfo(r1)
	lhz		r8, NKConfigurationInfo.Debug(r9)

	;	If CI.Debug >= 257 && CI.DebugFlags & 2 ...
	cmplwi	r8, NKConfigurationInfo.DebugThreshold
	lwz		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)

	if		&TYPE('NKShowLog') = 'UNDEFINED'
		blt-	@no_screen_log
		lwz		r8, NKConfigurationInfo.DebugFlags(r9)
		rlwinm.	r8, r8, 0, NKConfigurationInfo.LogFlagBit, NKConfigurationInfo.LogFlagBit
		lwz		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)
		beq-	@no_screen_log
	endif

	;	Enable the screen log
	ori		r8, r8, 1<< 3
@no_screen_log

	;	Switch on two other flags
	ori		r8, r8, 1<< 0		; not sure
	ori		r8, r8, 1<< 4		; to do with interrupts
	stw		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)



;	Turns out that there was a CPU struct hiding between PSA and KDP,
;	which contains our main CPU ewa

	addi	r9, r1, EWA.CPUBase
	li		r8, -1
	stw		r8, CPU.ID(r9)



; Say hello.

	bl		InitScreenConsole

	_log	'Hello from the builtin multitasking NanoKernel. Version: '

	li		r8, kNanoKernelVersion
	mr		r8, r8
	bl		Printh

	_log	'^n'



;	Save a pointer to the kernel memory area in KDP
;	(will get upped by pool extends?)

	stw		r13, KDP.KernelMemoryBase(r1)



;	PA_NanoKernelCode is uninitialized, but this loaded value gets
;	clobbered straight away anyway. Compiler!

	lwz		r12, KDP.PA_NanoKernelCode(r1)



;	Choose a primary interrupt handler (PIH)
;
	;	ARG		NKConfigurationInfo *r3
	bl		LookupInterruptHandler
	;	RET		InterruptHandler *r7
	;	CLOB	r12

	stw		r7, KDP.PA_InterruptHandler(r1)



;	Store HTABSIZE in the IRP

	lwz		r11, EWA.PA_IRP(r1)
	addi	r12, r14, 1
	stw		r12, IRP.SystemInfo + NKSystemInfo.HashTableSize(r11)



;	Populate KDP...

	;	Place EDP pointer (and leave it in r8).
	addi		r8, r1, 0x1000
	stw		r8, KDP.PA_EmulatorData(r1)


	;	Place pointer to top of reserved kernel area.
	;	(= ptr to top of HTAB)
	add		r12, r13, r15
	stw		r12, KDP.KernelMemoryEnd(r1)


	;	Place PA_RelocatedLowMemInit from ConfigInfo in KDP.
	;	(See note above.)
	lwz		r12, NKConfigurationInfo.PA_RelocatedLowMemInit(r3)
	stw		r12, KDP.PA_RelocatedLowMemInit(r1)


	;	Place something from ConfigInfo in KDP.
	;	This address seems to contain 0x40820160.
	;	Trampoline ns old SharedMemoryAddr, which was 0 anyway.
	lwz		r12, NKConfigurationInfo.SharedMemoryAddr(r3)
	stw		r12, KDP.SharedMemoryAddr(r1)


	;	Place (LA_EmulatorCode + KernelTrapTableOffset) from ConfigInfo in KDP.
	;	(Call this LA_EmulatorKernelTrapTable?)
	lwz		r12, NKConfigurationInfo.LA_EmulatorCode(r3)
	lwz		r11, NKConfigurationInfo.KernelTrapTableOffset(r3)
	add		r12, r12, r11
	stw		r12, KDP.LA_EmulatorKernelTrapTable(r1)


	;	Place "PA_NanoKernelCode" in KDP and leave it in r12.
	bl		* + 4
	mflr	r12
	addi	r12, r12, 4 - *
	stw		r12, KDP.PA_NanoKernelCode(r1)


	;	FDP. Got its name from an embarrassing mistake by me. Needs a better one.
	;	Probably written by Gary, it emulates bad PowerPC instructions.
	llabel	r11, FDP
	add		r12, r11, r12
	stw		r12, KDP.PA_FDP(r1)


	;	Place "LA_ECB" and "PA_ECB" (twice) from ConfigInfo in KDP.
	;	(This gets called the System Context.)
	lwz		r12, NKConfigurationInfo.LA_EmulatorData(r3)
	lwz		r11, NKConfigurationInfo.ECBOffset(r3)
	add		r12, r12, r11
	stw		r12, KDP.LA_ECB(r1)


	add		r12, r8, r11			;	PA_EmulatorData + ECBOffset
	stw		r12, KDP.PA_ECB(r1)
	stw		r12, EWA.PA_ContextBlock(r1)


	;	Place init vals for rupt masks from ConfigInfo in KDP.
	lwz		r12, NKConfigurationInfo.TestIntMaskInit(r3)
	stw		r12, KDP.TestIntMaskInit(r1)
	lwz		r12, NKConfigurationInfo.ClearIntMaskInit(r3)
	stw		r12, KDP.ClearIntMaskInit(r1)
	lwz		r12, NKConfigurationInfo.PostIntMaskInit(r3)
	stw		r12, KDP.PostIntMaskInit(r1)


	;	Place "PA_EmulatorIplValue" from ConfigInfo in KDP.
	lwz		r12, NKConfigurationInfo.IplValueOffset(r3)
	add		r12, r8, r12
	stw		r12, KDP.PA_EmulatorIplValue(r1)


	;	Copy this value from ConfigInfo to KDP *again* (see above).
	;	But this time, add 0x7c to get 0x408201DC.
	lwz		r12, NKConfigurationInfo.SharedMemoryAddr(r3)
	addi	r12, r12, 0x7c
	stw		r12, KDP.SharedMemoryAddrPlus(r1)


	;	Place PageAttributeInit from ConfigInfo in KDP.
	lwz		r12, NKConfigurationInfo.PageAttributeInit(r3)
	stw		r12, KDP.PageAttributeInit(r1)


	;	Make space at KDP + 0x920 for PageMap,
	;	according to ConfigInfo.PageMapInitSize.
	;	0x1b8 might be a typical value
	addi	r13, r1, KDP.PageMap
	lwz		r12, NKConfigurationInfo.PageMapInitSize(r3)
	stw		r13, KDP.PA_PageMapStart(r1)
	add		r13, r13, r12
	stw		r13, KDP.PA_PageMapEnd(r1)


	;	Zero out a word in KDP a bit below &PA_PageMap.
	;	Only NewWorld and Unknown PIHes touch this.
	stw		r0, KDP.ZeroWord(r1)



;	The InfoRecord contains metadata about the Power Mac structures
;	described in PPCInfoRecordsPriv.

;	It lives in the top 64b of the InfoRecord (nee Interrupt Response) Page,
;	which on PCI machines is mapped to 5fffe000 (just under 1.5GB). Here we
;	populate it at the top of our KDP, and later we copy it to our IRP.

	;	Logical self-pointer to the copy of InfoRecord in KDP
	;	(Will this be altered when the InfoRecord is copied to IRP?)
	lwz		r11, NKConfigurationInfo.LA_KernelData(r3)
	addi	r12, r11, KDP.InfoRecord
	stw		r12, KDP.InfoRecord + InfoRecord.InfoRecordPtr(r1)


	;	Constant
	stw		r0, KDP.InfoRecord + InfoRecord.Zero(r1)


	;	NKProcessorState (created by kernel, lives in PSA)

	lwz		r11, NKConfigurationInfo.LA_KernelData(r3)
	addi	r12, r11, PSA.ProcessorState
	stw		r12, KDP.InfoRecord + InfoRecord.NKProcessorStatePtr(r1)

	li		r12, 0x0100
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorStateVer(r1)

	li		r12, 128
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorStateLen(r1)


	;	NKHWInfo (created by bootloader, copied to IRP)

	lwz		r11, NKConfigurationInfo.LA_InfoRecord(r3)
	addi	r12, r11, IRP.HWInfo
	stw		r12, KDP.InfoRecord + InfoRecord.NKHWInfoPtr(r1)

	li		r12, 0x0108
	sth		r12, KDP.InfoRecord + InfoRecord.NKHWInfoVer(r1)

	li		r12, 192
	sth		r12, KDP.InfoRecord + InfoRecord.NKHWInfoLen(r1)


	;	NKProcessorInfo (created by bootloader, copied to KDP)

	lwz		r11, NKConfigurationInfo.LA_KernelData(r3)
	addi	r12, r11, KDP.ProcessorInfo
	stw		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoPtr(r1)

	li		r12, 0x0112
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer(r1)

	li		r12, 160
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoLen(r1)


	;	NKNanoKernelInfo (created by kernel, lives in KDP)

	lwz		r11, NKConfigurationInfo.LA_KernelData(r3)
	addi	r12, r11, KDP.NanoKernelInfo
	stw		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoPtr(r1)

	li		r12, kNanoKernelVersion
	sth		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoVer(r1)

	li		r12, 352
	sth		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoLen(r1)


	;	NKDiagInfo (created by bootloader, copied to PSA)

	lwz		r11, NKConfigurationInfo.LA_KernelData(r3)
	addi	r12, r11, PSA.DiagInfo
	stw		r12, KDP.InfoRecord + InfoRecord.NKDiagInfoPtr(r1)

	li		r12, 0x0100
	sth		r12, KDP.InfoRecord + InfoRecord.NKDiagInfoVer(r1)

	li		r12, 256
	sth		r12, KDP.InfoRecord + InfoRecord.NKDiagInfoLen(r1)


	;	NKSystemInfo (created by bootloader, copied to IRP)

	lwz		r11, NKConfigurationInfo.LA_InfoRecord(r3)
	addi	r12, r11, IRP.SystemInfo
	stw		r12, KDP.InfoRecord + InfoRecord.NKSystemInfoPtr(r1)

	li		r12, 0x0107
	sth		r12, KDP.InfoRecord + InfoRecord.NKSystemInfoVer(r1)

	li		r12, 320
	sth		r12, KDP.InfoRecord + InfoRecord.NKSystemInfoLen(r1)


	;	NKProcessorInfo... again!

	lwz		r11, NKConfigurationInfo.LA_KernelData(r3)
	addi	r12, r11, KDP.ProcessorInfo
	stw		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoPtr2(r1)

	li		r12, 0x0112
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer2(r1)

	li		r12, 160
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoLen2(r1)



;	Populate emulator data page (EDP).

	;	Copy 16-byte BootstrapVersion string from ConfigInfo
	lwz		r11, NKConfigurationInfo.BootVersionOffset(r3)
	lwz		r12, NKConfigurationInfo.BootstrapVersion(r3)
	stwux r12, r11, r8
	lwz		r12, NKConfigurationInfo.BootstrapVersion + 4(r3)
	stw		r12, 4(r11)
	lwz		r12, NKConfigurationInfo.BootstrapVersion + 8(r3)
	stw		r12, 8(r11)
	lwz		r12, NKConfigurationInfo.BootstrapVersion + 12(r3)
	stw		r12, 12(r11)


	;	Place logical pointer to emulator entry point in ContextBlock.
	;	Leave pointer to ECB in r11.
	lwz		r12, NKConfigurationInfo.LA_EmulatorCode(r3)
	lwz		r11, NKConfigurationInfo.EmulatorEntryOffset(r3)
	add		r12, r11, r12
	lwz		r11, NKConfigurationInfo.ECBOffset(r3)
	add		r11, r11, r8
	stw		r12, ContextBlock.LA_EmulatorEntry(r11)


	;	Place LA_EmulatorData from ConfigInfo in ContextBlock.
	lwz		r12, NKConfigurationInfo.LA_EmulatorData(r3)
	stw		r12, ContextBlock.LA_EmulatorData(r11)


	;	Place LA_DispatchTable from ConfigInfo in ContextBlock.
	lwz		r12, NKConfigurationInfo.LA_DispatchTable(r3)
	stw		r12, ContextBlock.LA_DispatchTable(r11)


	;	Place LA_EmulatorKernelTrapTable from KDP in ContextBlock.
	lwz		r12, KDP.LA_EmulatorKernelTrapTable(r1)
	stw		r12, ContextBlock.LA_EmulatorKernelTrapTable(r11)



;	Initialize MacOS LowMem globals at PA_RelocatedLowMemInit

	;	Zero out 8k
	lwz		r10, KDP.PA_RelocatedLowMemInit(r1)
	li		r9, 0x2000
@LowMem_zeroloop
	addic.	r9, r9, -4
	stwx		r0, r10, r9
	bne+	@LowMem_zeroloop


	;	Populate from LowMemInit "key-value" table.
	lwz		r11, NKConfigurationInfo.MacLowMemInitOffset(r3)
	lwz		r10, KDP.PA_RelocatedLowMemInit(r1)

	lwzux	r9, r11, r3			;	get first word and point r11 at it
@LowMem_setloop
	mr.		r9, r9
	beq-	@LowMem_done
	lwzu	r12, 4(r11)
	stwx	r12, r10, r9
	lwzu		r9, 4(r11)
	b		@LowMem_setloop
@LowMem_done



;	We expect a 'Hnfo' signature (from Trampoline) in HWInfo.
;
;	If HWInfo IS signed, great -- we can move on with the init process,
;	and skip all the nasty cache-probing, table-consulting madness that
;	follows. Just ignore the rest of this file.
;
;	But if HWInfo is unsigned, then this is going to hurt.

	lwz		r11, EWA.PA_IRP(r1)
	lwz		r11, IRP.HWInfo + NKHWInfo.Signature(r11)
	lisori	r12, 'Hnfo'
	cmplw	r12, r11
	beq-	FinishInitBuiltin



;	Darn. All right, see if we can copy ProcessorInfo from
;	ProcessorInfoTable.s

	mfpvr	r12
	stw		r12, KDP.ProcessorInfo + NKProcessorInfo.ProcessorVersionReg(r1)
	srwi	r12, r12, 16
	lwz		r11, KDP.PA_NanoKernelCode(r1)
	addi	r10, r1, KDP.ProcessorInfo + NKProcessorInfo.Ovr
	li		r9, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr

;	check for several (some unknown) pre-7410 CPUs, and load their info
	cmpwi	r12, 0x0001												; 601
	addi	r11, r11, ProcessorInfoTable - NKTop
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x0003												; 603
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x0004												; 604
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x0006												; 603e
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x0007												; 750FX
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x0008												; 750
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x0009												; ???
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo
	cmpwi	r12, 0x000a												; ???
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x000c												; 7400
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo

	cmpwi	r12, 0x000d												; ???
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq-	OverrideProcessorInfo



;	Now things get crazy. Have barely touched this...

;	get base of page table (why?)
	mfsdr1	r22

;	r21 = SDR1 & 0xffff0000
	rlwinm	r21, r22,  0,  0, 15

;	r22 = (SDR1 << 16) & 0x007F0000
	rlwinm	r22, r22, 16,  9, 15
	addis	r22, r22,  0x01
	li		r15,  0x00
	li		r12,  0x1a
	mtctr	r12
	lwz		r12, -0x0020(r1)
	addi	r10, r12,  0xec0

new_world_0x60c
	lwz		r11, -0x0004(r10)
	lwzu	r12, -0x0008(r10)
	subf	r9, r12, r21
	cmplw	r9, r11
	bge-	new_world_0x624
	mr		r11, r9

new_world_0x624
	cmplw	r11, r15
	ble-	new_world_0x634
	mr		r13, r12
	mr		r15, r11

new_world_0x634
	bdnz+	new_world_0x60c
	addi	r12, r22, -0x01
	neg		r11, r13
	and		r12, r11, r12
	add		r13, r13, r12
	subf	r15, r12, r15
	rlwinm	r15, r15,  0,  0, 21
	li		r11,  0x1000
	stw		r11,  0x0f30(r1)
	li		r11, -0x01
	li		r10,  0x400

new_world_0x660
	subic.	r10, r10, 4
	stwx	r11, r21, r10
	bne+	new_world_0x660
	dcbz	0, r21

new_world_0x670
	addi	r10, r10,  0x01
	lbzx	r11, r21, r10
	cmpwi	r11,  0x00
	beq+	new_world_0x670
	sth		r10,  0x0f3c(r1)
	sth		r10,  0x0f3e(r1)
	sth		r10,  0x0f46(r1)
	sth		r10,  0x0f48(r1)
	sth		r10,  0x0f4a(r1)
	lis		r12, -0x8000
	add		r11, r21, r22
	addi	r11, r11, -0xe6e
	addis	r10, r21,  0x01

new_world_0x6a4
	stwu	r11, -0x0004(r10)
	rlwimi	r12, r10, 29, 29, 31
	stwu	r12, -0x0004(r10)
	cmpw	r10, r21
	rlwinm	r9, r10,  9,  7, 19
	tlbie	r9
	bne+	new_world_0x6a4
	sync	
	isync	
	lwz		r11,  0x064c(r1)
	li		r12, (copied_code_1_end - copied_code_1) / 4
	mtctr	r12
	add		r20, r21, r22
	addi	r11, r11, copied_code_1_end - NKTop

new_world_0x6dc
	lwzu	r12, -0x0004(r11)
	stwu	r12, -0x0004(r20)
	dcbst	0, r20
	sync	
	icbi	0, r20
	bdnz+	new_world_0x6dc
	sync	
	isync	
	stw		r0,  0x0f34(r1)
	li		r17,  0x00
	li		r18,  0x200
	li		r19,  0x00
	li		r16, -0x01
	b		new_world_0x720

new_world_0x714
	addi	r17, r17,  0x200
	cmplw	r17, r15
	bge-	new_world_0x734

new_world_0x720
	mtlr	r20
	blrl	
	ble+	new_world_0x714
	addi	r12, r17, -0x200
	stw		r12,  0x0f34(r1)

new_world_0x734
	li		r12,  0x01
	sth		r12,  0x0f4e(r1)
	lwz		r18,  0x0f34(r1)
	mr		r17, r18
	li		r19,  0x00
	li		r16, -0x01
	b		new_world_0x75c

new_world_0x750
	add		r17, r17, r18
	cmplw	r17, r15
	bge-	new_world_0x774

new_world_0x75c
	mtlr	r20
	blrl	
	ble+	new_world_0x750
	subf	r17, r18, r17
	divwu	r12, r17, r18
	sth		r12,  0x0f4e(r1)

new_world_0x774
	lwz		r17,  0x0f34(r1)
	lhz		r18,  0x0f4e(r1)
	slwi	r17, r17,  1
	divwu	r18, r17, r18
	srwi	r19, r18,  1
	li		r14,  0x200
	add		r19, r19, r14
	li		r16, -0x01
	b		new_world_0x7ac

new_world_0x798
	lhz		r12,  0x0f4a(r1)
	cmplw	r14, r12
	ble-	new_world_0x7bc
	srwi	r14, r14,  1
	subf	r19, r14, r19

new_world_0x7ac
	mtlr	r20
	blrl	
	ble+	new_world_0x798
	slwi	r12, r14,  1

new_world_0x7bc
	sth		r12,  0x0f44(r1)
	mtsdr1	r21
	mr		r14, r13
	li		r13,  0xff0
	sth		r0,  0x0f50(r1)
	li		r17,  0x00
	lwz		r18,  0x0f30(r1)
	li		r19,  0x00
	li		r16, -0x01
	b		new_world_0x7f4

new_world_0x7e4
	add		r17, r17, r18
	lis		r12,  0x3f
	cmplw	r17, r12
	bge-	new_world_0x82c

new_world_0x7f4
	mtlr	r20
	mfmsr	r12
	ori		r12, r12,  0x10
	mtmsr	r12
	isync	
	blrl	
	mfmsr	r12
	rlwinm	r12, r12,  0, 28, 26
	mtmsr	r12
	isync	
	ble+	new_world_0x7e4
	subf	r17, r18, r17
	divwu	r12, r17, r18
	sth		r12,  0x0f50(r1)

new_world_0x82c
	li		r12,  0x01
	sth		r12,  0x0f52(r1)
	li		r17,  0x00
	lis		r18,  0x40
	li		r19,  0x00
	li		r16, -0x01
	b		new_world_0x858

new_world_0x848
	add		r17, r17, r18
	lis		r12,  0x200
	cmplw	r17, r12
	bge-	new_world_0x890

new_world_0x858
	mtlr	r20
	mfmsr	r12
	ori		r12, r12,  0x10
	mtmsr	r12
	isync	
	blrl	
	mfmsr	r12
	rlwinm	r12, r12,  0, 28, 26
	mtmsr	r12
	isync	
	ble+	new_world_0x848
	subf	r17, r18, r17
	divwu	r12, r17, r18
	sth		r12,  0x0f52(r1)

new_world_0x890
	mr		r13, r14
	addi	r12, r22, -0x01
	srwi	r12, r12, 16
	or		r12, r12, r21
	mtsdr1	r12
	lwz		r12,  0x0f34(r1)
	stw		r12,  0x0f38(r1)
	lhz		r12,  0x0f4e(r1)
	sth		r12,  0x0f4c(r1)
	lhz		r12,  0x0f44(r1)
	sth		r12,  0x0f42(r1)
	lis		r11,  0x3960
	stw		r11,  0x0000(r21)
	lis		r11,  0x4e80
	ori		r11, r11,  0x20
	stw		r11,  0x0004(r21)
	dcbst	0, r21
	sync	
	icbi	0, r21
	sync	
	isync	
	mtlr	r21
	blrl	
	li		r11,  0x01
	sth		r11,  0x0002(r21)
	sync	
	isync	
	mtlr	r21
	blrl	
	sth		r11,  0x0f40(r1)
	cmpwi	r11,  0x01
	beq-	skip_cache_hackery_never
	lwz		r11,  0x064c(r1)
	li		r12, (copied_code_2_end - copied_code_2) / 4
	mtctr	r12
	add		r20, r21, r22
	addi	r11, r11, copied_code_2_end - NKTop

new_world_0x924
	lwzu	r12, -0x0004(r11)
	stwu	r12, -0x0004(r20)
	dcbst	0, r20
	sync	
	icbi	0, r20
	bdnz+	new_world_0x924
	sync	
	isync	
	subf	r12, r21, r20
	mulli	r12, r12,  0x80
	cmplw	r12, r15
	bge-	new_world_0x958
	mr		r15, r12

new_world_0x958
	add		r12, r13, r15
	mr		r11, r20
	lis		r10,  0x4e80
	ori		r10, r10,  0x20

new_world_0x968
	lwzu	r9, -0x0200(r12)
	stw		r10,  0x0000(r12)
	cmpw	r12, r13
	stwu	r9, -0x0004(r11)
	dcbst	0, r12
	sync	
	icbi	0, r12
	bne+	new_world_0x968
	sync	
	isync	
	stw		r0,  0x0f38(r1)
	li		r17,  0x00
	li		r18,  0x200
	li		r19,  0x00
	li		r16, -0x01
	b		new_world_0x9b4

new_world_0x9a8
	addi	r17, r17,  0x200
	cmplw	r17, r15
	bge-	new_world_0x9c8

new_world_0x9b4
	mtlr	r20
	blrl	
	ble+	new_world_0x9a8
	addi	r12, r17, -0x200
	stw		r12,  0x0f38(r1)

new_world_0x9c8
	li		r12,  0x01
	sth		r12,  0x0f4c(r1)
	lwz		r18,  0x0f38(r1)
	mr		r17, r18
	li		r19,  0x00
	li		r16, -0x01
	b		new_world_0x9f0

new_world_0x9e4
	add		r17, r17, r18
	cmplw	r17, r15
	bge-	new_world_0xa08

new_world_0x9f0
	mtlr	r20
	blrl	
	ble+	new_world_0x9e4
	subf	r17, r18, r17
	divwu	r12, r17, r18
	sth		r12,  0x0f4c(r1)

new_world_0xa08
	add		r12, r13, r15
	mr		r11, r20

new_world_0xa10
	lwzu	r9, -0x0004(r11)
	stwu	r9, -0x0200(r12)
	cmpw	r12, r13
	dcbst	0, r12
	sync	
	icbi	0, r12
	bne+	new_world_0xa10
	sync	
	isync	
	lwz		r17,  0x0f38(r1)
	lhz		r18,  0x0f4c(r1)
	divwu	r18, r17, r18
	slwi	r17, r17,  1
	add		r12, r13, r17
	subi	r11, r21, 4

new_world_0xa4c
	subf	r12, r18, r12
	li		r14,  0x400

new_world_0xa54
	rlwinm.	r14, r14, 31,  0, 28
	lwzx	r9, r12, r14
	lis		r10,  0x4e80
	ori		r10, r10,  0x20
	stwx	r10, r12, r14
	stwu	r9,  0x0004(r11)
	dcbst	r12, r14
	sync	
	icbi	r12, r14
	addi	r14, r14,  0x04
	lwzx	r9, r12, r14
	lis		r10,  0x4bff
	ori		r10, r10,  0xfffc
	stwx	r10, r12, r14
	stwu	r9,  0x0004(r11)
	dcbst	r12, r14
	sync	
	icbi	r12, r14
	bne+	new_world_0xa54
	cmpw	r12, r13
	bne+	new_world_0xa4c
	sync	
	isync	
	mr		r19, r18
	slwi	r18, r18,  1
	li		r14,  0x200
	add		r19, r19, r14
	li		r16, -0x01
	b		new_world_0xadc

new_world_0xac8
	li		r12,  0x08
	cmplw	r14, r12
	ble-	new_world_0xaec
	srwi	r14, r14,  1
	subf	r19, r14, r19

new_world_0xadc
	mtlr	r20
	blrl	
	ble+	new_world_0xac8
	slwi	r12, r14,  1

new_world_0xaec
	sth		r12,  0x0f42(r1)
	srwi	r18, r18,  1
	add		r12, r13, r17
	subi	r11, r21, 4

new_world_0xafc
	subf	r12, r18, r12
	li		r14,  0x400

new_world_0xb04
	rlwinm.	r14, r14, 31,  0, 28
	lwzu	r9,  0x0004(r11)
	stwx	r9, r12, r14
	addi	r14, r14,  0x04
	lwzu	r9,  0x0004(r11)
	stwx	r9, r12, r14
	bne+	new_world_0xb04
	cmpw	r12, r13
	bne+	new_world_0xafc

skip_cache_hackery_never
	;	Clearly can't just fall through
	b		FinishInitBuiltin


;	                     copied_code_1                      

;	Xrefs:
;	new_world

copied_code_1	;	OUTSIDE REFERER
	li		r10,  0x03

copied_code_1_0x4
	li		r12,  0x800
	mtctr	r12
	add		r19, r19, r13
	li		r11,  0x00
	mtdec	r11

copied_code_1_0x18
	subf	r12, r17, r11
	srawi	r12, r12, 31
	and		r11, r11, r12
	lbzx	r12, r13, r11
	add		r12, r12, r12
	lbzx	r12, r19, r11
	add		r12, r12, r12
	add		r11, r11, r18
	bdnz+	copied_code_1_0x18
	subf	r19, r13, r19
	mfdec	r12
	neg		r12, r12
	cmplw	r12, r16
	bgt-	copied_code_1_0x54
	mr		r16, r12

copied_code_1_0x54
	srwi	r11, r12,  7
	subf	r12, r11, r12
	cmpw	r12, r16
	blelr-	
	addic.	r10, r10, -0x01
	bgt+	copied_code_1_0x4
	cmpw	r12, r16
	blr		
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
copied_code_1_end	;	OUTSIDE REFERER



;	                     copied_code_2                      

;	Xrefs:
;	new_world

copied_code_2	;	OUTSIDE REFERER
	li		r10,  0x03
	mflr	r9

copied_code_2_0x8
	li		r12,  0x800
	mtctr	r12
	add		r19, r19, r13
	li		r11,  0x00
	mtdec	r11

copied_code_2_0x1c
	subf	r12, r17, r11
	srawi	r12, r12, 31
	and		r11, r11, r12
	add		r12, r13, r11
	mtlr	r12
	blrl	
	add		r12, r19, r11
	mtlr	r12
	blrl	
	add		r11, r11, r18
	bdnz+	copied_code_2_0x1c
	subf	r19, r13, r19
	mfdec	r12
	neg		r12, r12
	cmplw	r12, r16
	bgt-	copied_code_2_0x60
	mr		r16, r12

copied_code_2_0x60
	srwi	r11, r12,  7
	subf	r12, r11, r12
	cmpw	r12, r16
	mtlr	r9
	blelr-	
	addic.	r10, r10, -0x01
	bgt+	copied_code_2_0x8
	cmpw	r12, r16
	blr		
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
	isync
copied_code_2_end	;	OUTSIDE REFERER
