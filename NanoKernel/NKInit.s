;_______________________________________________________________________
;	START OF NANOKERNEL
;
;	Init.s is the first code file included by NanoKernel.s. It contains:
;		the NanoKernel header (both declarative and executable)
;		
;	The NanoKernel header follows:
;_______________________________________________________________________


;	This is the entry point for the NanoKernel. Execution always starts here,
;	regardless of how the NK was put in control. The immediate purpose of this
;	code is to figure out if it was called by the Trampoline bootloader for
;	NewWorld Macs or the 'boot' 3 resource on OldWorld Macs. The code path
;	diverges dramatically for the 2 cases, so it is important to figure out which
;	is which.

;	If data paging is off, we recieved control from the Trampoline and we are the
;	built in NanoKernel. The register assignments are as follows:
;		r3 = ConfigInfo
;		r4 = ProcessorInfo
;		r5 = SystemInfo
;		r6 = DiagInfo
;		r7 = RTAS_flag ('RTAS' or 0)
;		r8 = RTAS_proc
;		r9 = HWInfo
;		r23= SCC (Serial Communications Controller) base address 
;

;	If data paging is on, we recieved control from the 'boot' 3 resource and we
;	are replacing another NanoKernel. The register assignments are as follows:

;		LR = return address?
;		sprg0 = old KDP/EWA/r1 ptr
;		r3 = PA_NanoKernelCode (the physical address of this code)
;		r4 = physical base of our global area
;		r5 = SCC base address (will be saved to NoIdeaR23)
;		r6 = PA_EDP or zero?
;		r7 = ROMHeader.ROMRelease (e.g. 0x10B5 is 1.0ß5)


;	First we need to avoid executing the data that follows:

	b		EndOfNanoKernelHeader



;	On OldWorld Macs, the 68k code in the 'boot' 3 resource
;	(of the System or enabler file) loads the NanoKernel
;	from the 'krnl' 0 resource (of the System file), and
;	uses it to replace the ROM kernel.
;
;	This code probably uses the following header:

	dc.w	kNanoKernelVersion
	dc.w	12
	dc.w	0x400
	dc.w	0
EndOfNanoKernelHeader



;	Figure out how we got control

	;	cr5_eq is cleared for the builtin init process

	crclr	cr5_eq


	;	If data paging is off, jump straight to the builtin init code

	mfmsr	r0
	rlwinm.	r0, r0, 0, MSR_DRbit, MSR_DRbit
	beql	InitBuiltin


	;	But if data paging is on, we are the replacement NanoKernel.
	;	We need to turn off paging and jump to the replacement init code.

		;	Does LR contain a return address, or my address, or...?
		mflr	r9
		subi	r9, r9, 28

		;	Find the physical address of the replacement init code
		addi	r12, r3, InitReplacement - NKTop; offset

		;	Unset MSR_POW, MSR_ILE, MSR_EE, MSR_IR and MSR_DR
		mfmsr	r11
		li		r10, -0x7fd0
		andc	r11, r11, r10

		;	Jump and set MSR with an RFI.
		mtspr	srr0, r12
		mtspr	srr1, r11
		;	We will now be at InitReplacement with paging off
		rfi

;	For clarity, the NanoKernel-replacement code is included from
;	another file. It copies the old kernel structures to a new area
;	and adopts them as our own, with some modifications.
;
;	Jumps to InitHighLevel (below) when finished.

	include		'NKReplacementInit.s'



;	Function that fills a new InfoRecord Page (IRP) with the
;	bus error-eliciting value, 0x68f1.
;	(called by both builtin and replacement code paths)

;	CLOB	r10, r12

InitIRP
	lwz		r12, EWA.PA_IRP(r1)

@wipe_loop
	lisori	r10, 0x68f168f1
	stw		r10, 0(r12)
	stw		r10, 4(r12)
	addi	r12, r12, 8
	andi.	r10, r12, 0xfff
	bne		@wipe_loop
	blr



;	This is the code that does the bulk of the builtin-specific init.
;	
;	If the Trampoline has not passed in a valid HWInfo struct then
;	this code will depend on ProcessorInfoTable.s. In that case it
;	will jump to ProcessorInfoTable.s:OverrideProcessorInfo, which
;	will fall though to FinishInitBuiltin.
;
;	But normally, this code will jump straight to FinishInitBuiltin.

	include		'NKBuiltinInit.s'



;	Table used by the common init code (below) to fill some KDP flags
;	indicating processor capabilities (e.g. presence of L2CR register)
;
;	No code here.

	include		'NKProcFlagsTbl.s'



;	Table used by the builtin init code (above) to populate some of
;	the ProcessorInfo struct when information from the Trampoline
;	is lacking.
;
;	Includes OverrideProcessorInfo code for use by InitBuiltin.s.
;	This code falls through to FinishInitBuiltin below.

	include		'NKProcInfoTbl.s'



;	Tidy up the builtin init process before joining the common
;	init code path.
;
;	This code might be accessed by fall-through from
;	ProcessorInfoTable.s:OverrideProcessorInfo, or by branch
;	from InitBuiltin.s

FinishInitBuiltin

	;	Set ProcessorInfo version in case ProcessorInfo had to be loaded
	;	from the table above.

	li		r8, 0x0112
	sth		r8, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer(r1)


	;	Copy some choice values out of KDP's copy of NKProcessorInfo

	lwz		r9, KDP.ProcessorInfo + NKProcessorInfo.DecClockRateHz(r1)
	stw		r9, KDP.ProcessorInfo + NKProcessorInfo.ClockRates + 8(r1)

	lwz		r9, KDP.ProcessorInfo + NKProcessorInfo.BusClockRateHz(r1)
	stw		r9, KDP.ProcessorInfo + NKProcessorInfo.ClockRates + 4(r1)

	lwz		r9, KDP.ProcessorInfo + NKProcessorInfo.CpuClockRateHz(r1)
	stw		r9, KDP.ProcessorInfo + NKProcessorInfo.ClockRates + 0(r1)

	li		r9, 0
	sth		r9, KDP.ProcessorInfo + NKProcessorInfo.SetToZero(r1)

	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.DecClockRateHz(r1)
	stw		r8, PSA.DecClockRateHzCopy(r1)


	;	Test AltiVec and MQ registers

		;	Prepare a simple vector table to ignore illegal
		;	instructions (like lvewx on a G3 ;)
		lwz		r9, KDP.PA_NanoKernelCode(r1)

		llabel	r8, IgnoreSoftwareInt
		add		r8, r8, r9
		stw		r8, KDP.VecBaseSystem + VecTable.ProgramIntVector(r1)

		llabel	r8, HandlePerfMonitorInt
		add		r8, r8, r9
		stw		r8, KDP.VecBaseSystem + VecTable.PerfMonitorVector(r1)

		addi	r8, r1, KDP.VecBaseSystem
		mtsprg	3, r8


		;	Test MQ and save feature field
		lis		r8, 1 << (15 - EWA.kFlagHasMQ)
		mtspr	mq, r8
		li		r8, 0
		mfspr	r8, mq
		stw		r8, PSA.FlagsTemplate(r1)

		;	Add AV and save that in scratch field
		_bset	r9, r8, EWA.kFlagVec
		stw		r9, EWA.r0(r1)

		;	Load from scratch field into a vector register
		addi	r9, r1, 0
		lvewx	v0, 0, r9

		;	Save MQ into the scratch register in case vector save fails
		stw		r8, EWA.r0(r1)

		;	Try save vector register (with AV flag) to scratch field
		stvewx	v0, 0, r9

		;	Scratch field now contains AltiVec and MQ flags.
		;	Copy it to FlagsTemplate
		lwz		r8, EWA.r0(r1)
		stw		r8, PSA.FlagsTemplate(r1)

		;	initial blue flags = global template + EWA.kFlagEmu + EWA.kFlag9
		oris	r7, r8, 0xa0
		stw		r7, EWA.Flags(r1)


	;	Emulator data and code pointers useful for the common code path?

	lwz		r6, KDP.PA_ECB(r1)
	lwz		r10, KDP.LA_EmulatorKernelTrapTable(r1)


	;	Create MSR (machine status register) values for use by the common code path

		mfmsr	r14

		;	Zero out a reserved bit. Considering next insn, should have no effect
		rlwinm r14, r14, 0, 7, 5

		;	Test for and keep MSR_IP (IVT location) flag
		;	(presumably set by Trampoline)
		andi. r14, r14,					MSR_IP

		;	"KernelModeMSR" -- Seems not to get used?
		ori		r15, r14,           MSR_ME      + MSR_DR + MSR_RI

		;	"MSR"
		ori		r11, r14, MSR_EE + MSR_PR + MSR_ME + MSR_IR + MSR_DR + MSR_RI
		stw		r11, PSA.UserModeMSR(r1)


	;	Zero out a bunch of registers.

	li		r13, 0
	li		r12, 0
	li		r0, 0
	li		r2, 0
	li		r3, 0
	li		r4, 0



;	The builtin kernel can be partly reinited by a 68k RESET trap.
;	Rene says this is for address space setup.

ResetBuiltinKernel

	crclr cr5_eq



;	The common code path! InitIRP has been called but IRP is
;	otherwise untouched (InfoRecord still in KDP).
;
;	We get here by a jump from InitReplacement.s
;	or by fallthough from FinishInitBuiltin above.
;
;	When we get here:
;		cr5_eq = is_replacement_kernel
;		cr0 will be set if IVT is in high meg (MSR.IP)
;			r1 = KDP
;			r2 = 0
;			r3 = 0
;			r4 = 0
;			r5 = SystemInfo
;			r6 = ECB
;			r7 = Flags
;			r9 = even more altivec crud
;		r10 = LA_EmulatorKernelTrapTable
;		r11 = MSR
;		r12 = 0
;		r13 = 0
;		r15 = KernelModeMSR

InitHighLevel


;	The XER contains carries, overflows and string lengths.
;	Apple seems to use it for all sorts of crap.

	mfxer	r17
	stw		r17, ContextBlock.XER(r6)



;	Boring intro from the high-level init code

	_log	'Kernel code base at 0x'

	lwz		r8, KDP.PA_NanoKernelCode(r1)
	mr		r8, r8
	bl		Printw

	_log	' Physical RAM size 0x'

	lwz		r8, EWA.PA_IRP(r1)
	lwz		r8, IRP.SystemInfo + NKSystemInfo.PhysicalMemorySize(r8)
	mr		r8, r8
	bl		Printw

	_log	'bytes^n'



;	Copy InfoRecord from KDP to IRP.
;	(Does this become the authoritative version?)

	lisori	r22,	InfoRecord.Size
	lwz		r9,		EWA.PA_IRP(r1)
	addi	r8, r1,	KDP.InfoRecord
	addi	r9, r9,	IRP.InfoRecord

@loop
	subic.	r22, r22, 4
	lwzx	r0, r22, r8
	stwx	r0, r22, r9
	bgt		@loop



;	Some useful values for filling tables

	lwz		r26, KDP.PA_ConfigInfo(r1)
	lwz		r25, KDP.PA_NanoKernelCode(r1)
	lwz		r18, KDP.PA_PageMapStart(r1)



;	A quick reminder about wordfill:
;		ARG		void *r3 dest, long r22 len, long r23 fill



;	Fill the old-style KDP vector tables, and also two new PSA ones,
;	with panics

	llabel	r23, panic
	add		r23, r23, r25

	addi	r8, r1, KDP.VecBaseSystem
	li		r22,	VecTable.Size
	bl		wordfill

	addi	r8, r1, KDP.VecBaseAlternate
	li		r22,	VecTable.Size
	bl		wordfill

	addi	r8, r1, KDP.VecBaseMemRetry
	li		r22,	VecTable.Size
	bl		wordfill

	addi	r8, r1, PSA.VioletVecBase
	li		r22,	VecTable.Size
	bl		wordfill

	addi	r8, r1, PSA.VecBasePIH
	li		r22,	VecTable.Size
	bl		wordfill



;	Fill Green (PSA) with IgnoreSoftwareInt

	llabel	r23, IgnoreSoftwareInt
	add		r23, r23, r25

	addi	r8, r1, PSA.VecBaseScreenConsole
	li		r22,	VecTable.Size
	bl		wordfill



;	Populate System and Alternate Context vector tables.
;	Activate System Context vector table (will enter 68k emu soon).

	addi	r9, r1, KDP.VecBaseSystem
	mtsprg	3, r9

	addi	r8, r1, KDP.VecBaseAlternate

	llabel	r23, panic
	add		r23, r23, r25
	stw		r23, VecTable.SystemResetVector(r9)
	stw		r23, VecTable.SystemResetVector(r8)

	llabel	r23, IntMachineCheck
	add		r23, r23, r25
	stw		r23, VecTable.MachineCheckVector(r9)
	stw		r23, VecTable.MachineCheckVector(r8)

	llabel	r23, IntDSI
	add		r23, r23, r25
	stw		r23, VecTable.DSIVector(r9)
	stw		r23, VecTable.DSIVector(r8)

	llabel	r23, IntISI
	add		r23, r23, r25
	stw		r23, VecTable.ISIVector(r9)
	stw		r23, VecTable.ISIVector(r8)

	;	Here is the difference between the System and Alternate
	;	vector tables
	llabel	r23, IntExternalSystem
	add		r23, r23, r25
	stw		r23, VecTable.ExternalIntVector(r9)

	llabel	r23, IntExternalAlternate
	add		r23, r23, r25
	stw		r23, VecTable.ExternalIntVector(r8)

	llabel	r23, IntAlignment
	add		r23, r23, r25
	stw		r23, VecTable.AlignmentIntVector(r9)
	stw		r23, VecTable.AlignmentIntVector(r8)

	llabel	r23, IntProgram
	add		r23, r23, r25
	stw		r23, VecTable.ProgramIntVector(r9)
	stw		r23, VecTable.ProgramIntVector(r8)

	llabel	r23, IntFPUnavail
	add		r23, r23, r25
	stw		r23, VecTable.FPUnavailVector(r9)
	stw		r23, VecTable.FPUnavailVector(r8)

	llabel	r23, IntDecrementer
	add		r23, r23, r25
	stw		r23, VecTable.DecrementerVector(r9)
	stw		r23, VecTable.DecrementerVector(r8)

	llabel	r23, IntSyscall
	add		r23, r23, r25
	stw		r23, VecTable.SyscallVector(r9)
	stw		r23, VecTable.SyscallVector(r8)

	llabel	r23, IntPerfMonitor
	add		r23, r23, r25
	stw		r23, VecTable.PerfMonitorVector(r9)
	stw		r23, VecTable.PerfMonitorVector(r8)

	llabel	r23, IntTrace
	add		r23, r23, r25
	stw		r23, VecTable.TraceVector(r9)
	stw		r23, VecTable.TraceVector(r8)
	stw		r23, 0x0080(r9)			; Unexplored parts of vecBase
	stw		r23, 0x0080(r8)

	llabel	r23, FDP_1c40			; seems AltiVec-related
	add		r23, r23, r25
	stw		r23, 0x0058(r9)
	stw		r23, 0x0058(r8)

	llabel	r23, IntThermalEvent	; thermal event
	add		r23, r23, r25
	stw		r23, VecTable.ThermalEventVector(r9)
	stw		r23, VecTable.ThermalEventVector(r8)



;	Fill the Translation vector table

	addi	r8, r1, KDP.VecBaseMemRetry

	llabel	r23, panic
	add		r23, r23, r25
	stw		r23, VecTable.SystemResetVector(r8)

	llabel	r23, MemRetryMachineCheck
	add		r23, r23, r25
	stw		r23, VecTable.MachineCheckVector(r8)

	llabel	r23, MemRetryDSI
	add		r23, r23, r25
	stw		r23, VecTable.DSIVector(r8)

	llabel	r23, IntSyscall
	add		r23, r23, r25
	stw		r23, VecTable.SyscallVector(r8)



;	Fill Violet (PSA)

	;	Fill everything with this
	llabel	r23, major_0x04a20
	add		r23, r23, r25
	addi	r8, r1, PSA.VioletVecBase
	li		r22, VecTable.Size
	bl		wordfill

	;	Then override with these
	llabel	r23, panic
	add		r23, r23, r25
	stw		r23, VecTable.SystemResetVector(r8)

	llabel	r23, IntDSI
	add		r23, r23, r25
	stw		r23, VecTable.DSIVector(r8)

	llabel	r23, IntISI
	add		r23, r23, r25
	stw		r23, VecTable.ISIVector(r8)

	llabel	r23, IntAlignment
	add		r23, r23, r25
	stw		r23, VecTable.AlignmentIntVector(r8)



;	For the PowerDispatch selector that governs idle modes

	bl		InitIdleVecTable



;	Fill Blue (PSA)

	addi	r8, r1, PSA.VecBasePIH

	llabel	r23, panic
	add		r23, r23, r25
	stw		r23, VecTable.SystemResetVector(r8)

	llabel	r23, IntMachineCheck
	add		r23, r23, r25
	stw		r23, VecTable.MachineCheckVector(r8)

	llabel	r23, PIHDSI
	add		r23, r23, r25
	stw		r23, VecTable.DSIVector(r8)

	llabel	r23, IntSyscall
	add		r23, r23, r25
	stw		r23, VecTable.SyscallVector(r8)



;	Fill the NanoKernelCallTable, the IntProgram interface to the NanoKernel

	;	Start with a default function
	
	llabel	r23, major_0x046d0
	add		r23, r23, r25

	addi	r8, r1, KDP.NanoKernelCallTable

	li		r22, NanoKernelCallTable.Size

@kctab_initloop
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne		@kctab_initloop


	;	Then some overrides (names still pretty poor)

	llabel	r23, kcReturnFromException
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.ReturnFromException(r8)

	llabel	r23, kcRunAlternateContext
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.RunAlternateContext(r8)

	llabel	r23, kcResetSystem
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.ResetSystem(r8)

	llabel	r23, kcVMDispatch
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.VMDispatch(r8)

	llabel	r23, kcPrioritizeInterrupts
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.PrioritizeInterrupts(r8)

	llabel	r23, kcPowerDispatch
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.PowerDispatch(r8)

	llabel	r23, kcRTASDispatch
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.RTASDispatch(r8)

	llabel	r23, kcCacheDispatch
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.CacheDispatch(r8)

	llabel	r23, kcMPDispatch
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.MPDispatch(r8)

	llabel	r23, kcThud
	add		r23, r23, r25
	stw		r23, NanoKernelCallTable.Thud(r8)



;	Set ProcessorFlags (and two other bytes) from PVR.
;	Nigh unforgivably ugly code, but ProcessorFlagsTable.s
;	describes what it does pretty well.

SetProcessorFlags

	mfpvr	r23
	srwi	r23, r23, 16
	andi.	r8, r23,  0x8000
	bne		@pvr_has_high_bit_set

	;	PVR < 0x8000 (therefore probably equals 000*)
	cmplwi	r23,  0x000f	; but if not, pretend it's zero
	ble		@pvr_not_low
	li		r23,  0x0000
@pvr_not_low

	add		r8, r25, r23
	lbz		r23, ProcessorFlagsTable - NKTop + 0(r8)
	stb		r23, KDP.CpuSpecificByte1(r1)
	lbz		r23, ProcessorFlagsTable - NKTop + 32(r8)
	stb		r23, KDP.CpuSpecificByte2(r1)
	mfpvr	r23
	srwi	r23, r23, 16
	slwi	r23, r23,  2
	add		r8, r25, r23
	lwz		r23, ProcessorFlagsTable - NKTop + 64(r8)
	stw		r23, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	b		@done

@pvr_has_high_bit_set
	andi.	r23, r23, 0x7fff

	cmplwi	r23, 0x000f
	ble		@other_pvr_not_low
	li		r23, -0x10
@other_pvr_not_low

	add		r8, r25, r23
	lbz		r23, ProcessorFlagsTable - NKTop + 16(r8)
	stb		r23, KDP.CpuSpecificByte1(r1)
	lbz		r23, ProcessorFlagsTable - NKTop + 48(r8)
	stb		r23, KDP.CpuSpecificByte2(r1)
	mfpvr	r23
	srwi	r23, r23, 16
	andi.	r23, r23,  0x7fff
	slwi	r23, r23,  2
	add		r8, r25, r23
	lwz		r23, ProcessorFlagsTable - NKTop + 128(r8)
	stw		r23, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	b		@done

@done


;	Init the NCB Pointer Cache

	_InvalNCBPointerCache scratch=r23



;	Initialize the seven kernel locks (Count and Signature fields)

	li		r23, 0
	stw		r23, PSA.HTABLock + Lock.Count(r1)
	stw		r23, PSA.PIHLock  + Lock.Count(r1)
	stw		r23, PSA.SchLock  + Lock.Count(r1)
	stw		r23, PSA.ThudLock + Lock.Count(r1)
	stw		r23, PSA.RTASLock + Lock.Count(r1)
	stw		r23, PSA.DbugLock + Lock.Count(r1)
	stw		r23, PSA.PoolLock + Lock.Count(r1)

	lisori	r23, Lock.kHTABLockSignature
	stw		r23, PSA.HTABLock + Lock.Signature(r1)

	lisori	r23, Lock.kPIHLockSignature
	stw		r23, PSA.PIHLock  + Lock.Signature(r1)

	lisori	r23, Lock.kSchLockSignature
	stw		r23, PSA.SchLock  + Lock.Signature(r1)

	lisori	r23, Lock.kThudLockSignature			; older kernel versions have a powr lock?
	stw		r23, PSA.ThudLock + Lock.Signature(r1)

	lisori	r23, Lock.kRTASLockSignature
	stw		r23, PSA.RTASLock + Lock.Signature(r1)

	lisori	r23, Lock.kDbugLockSignature
	stw		r23, PSA.DbugLock + Lock.Signature(r1)

	lisori	r23, Lock.kPoolLockSignature
	stw		r23, PSA.PoolLock + Lock.Signature(r1)



;	These seem to be register templates.

	lisori	r17, 0x7fffdead

	stw		r17, PSA.VectorRegInitWord(r1)
	stw		r17, PSA.SevenFFFDead2(r1)
	stw		r17, PSA.SevenFFFDead3(r1)
	stw		r17, PSA.SevenFFFDead4(r1)



;	Set up the not-quite-a-heap 'pool' of dynamic NanoKernel storage.
;
;	And then set up the structure (hash table?) mapping opaque
;	usermode-facing IDs with numeric types to storage blocks.

	bl		InitPool
	bl		InitIDIndex



;	Leave AllCpuFeatures in r7 for use waaaaay down there...

	lwz		r7, EWA.Flags(r1)



;	Create a blue process to own the blue and idle tasks

	;	Allocate and check
	li		r8, 32 ;Process.Size
	bl		PoolAllocClear		; takes size and returns ptr, all in r8

	mr.		r31, r8
	beq		Init_Panic

	;	Get opaque ID
	li		r9, Process.kIDClass
	bl		MakeID

	;	Point KDP to it
	stw		r31, PSA.blueProcessPtr(r1)

	;	Save ID in self and KDP
	stw		r8, Process.ID(r31)
	stw		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.blueProcessID(r1)

	;	Sign it
	lisori	r8,	Process.kSignature
	stw		r8, Process.Signature(r31)

	;	blue and idle
	li		r8, 2
	stw		r8, Process.TaskCount(r31)



;	Init a global linked list of coherence groups.
;	Leave ptr in r30.

	addi	r30, r1, PSA.CoherenceGrpList
	InitList	r30, 'GRPS', scratch=r17



;	Create the motherboard coherence group (CGRP, ID class 10) in the pool.
;	Owns a linked list of GRPSes, is itself a linked list member.
;	Leave ptr in r29.

	;	Allocate the main structure in the kernel pool, and check for a null ptr
	li		r8, 0x58 ;CoherenceGroup.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		Init_Panic


	;	Append to the global CGRP list
	addi	r17, r31, CoherenceGroup.LLL
	stw     r30, LLL.Freeform(r17)
	InsertAsPrev	r17, r30, scratch=r18


	;	Init a list of the CPUs in this CGRP
	addi    r29, r31,  CoherenceGroup.CPUList
	InitList	r29, CoherenceGroup.kSignature, scratch=r17


	;	Get opaque ID
	mr		r8, r31
	li		r9, CoherenceGroup.kIDClass
	bl		MakeID
	stw		r8, CoherenceGroup.CPUList + LLL.Freeform(r31)


	;	Congratulate ourselves
	mr		r16, r8							; Print macro clobbers r8 (opaque ID), so save it

		_log	'Created motherboard coherence group. ID '

	mr		r8, r16
	bl		Printw

		_log	'^n'


	;	Fill in some actual fields (then still have 48 unused bytes)
	li		r16, 1
	stw		r16, CoherenceGroup.CpuCount(r31)
	stw		r16, CoherenceGroup.ScheduledCpuCount(r31)


	; problem: expecting to see more stuff set here



;	Create a CPU struct in KDP with a linked list of coherence groups

	;	Place
	subi	r31, r1, CPU.EWA
	addi	r30, r31, CPU.EWABase


	;	Get opaque ID
	mr		r8, r31
	li		r9, CPU.kIDClass
	bl		MakeID


	;	Identify and sign
	stw		r8, CPU.ID(r31)

	lisori	r8,	CPU.kSignature
	stw		r8, CPU.Signature(r31)


	;	Append to the motherboard CGRP
	addi	r17, r31, CPU.LLL

	stw		r29, LLL.Freeform(r17)
	InsertAsPrev	r17, r29, scratch=r18


	;	Actually populate something useful (still have one unused long)
	lisori	r8,	15
	stw		r8, CPU.Flags(r31)

	;	Matches code in KCCreateCpuStruct very closely

	addi	r8, r1, PSA.Base
	stw		r8, EWA.PA_PSA - EWA.Base(r30)


	stw		r1, EWA.PA_KDP - EWA.Base(r30)

	li		r8, 0
	stw		r8, 0x0318(r30)			;	-0x28
	sth		r8, 0x020a(r30)			;	-0x136

	lisori	r8,	'time'
	stw		r8, 0x0004(r30)

	li		r8, 0x04
	stb		r8, 0x0014(r30)

	li		r8, 0x01
	stb		r8, 0x0016(r30)

	li		r8, 0x00
	stb		r8, 0x0017(r30)

	lisori	r8,	0x7fffffff
	stw		r8, 0x0038(r30)

	oris	r8, r8, 0xffff
	stw		r8, 0x003c(r30)



;	Copy the 32-element BATRangeInit array from ConfigInfo
;	For odd-indexed longs (offsets 0x*4 and 0x*c) with bit 22 set:
;	-	unset that bit
;	-	increment the value by PA_ConfigInfo (so... they were relative?)

	lwz		r26, KDP.PA_ConfigInfo(r1)
	addi	r9, r26, NKConfigurationInfo.BATRangeInit - 4
	addi	r8, r1, KDP.BATs - 4
	li		r22, 0x80

@BAT_copyloop
	lwzu	r20, 4(r9)				; grab 8 bytes
	lwzu	r21, 4(r9)

	stwu	r20, 4(r8)				; store the first byte directly

	rlwinm	r23, r21, 0, 23, 21		; munge the second byte
	cmpw	r21, r23

	beq		@bitnotset
	add		r21, r23, r26
@bitnotset

	addic.	r22, r22, -8
	stwu	r21, 4(r8)				; but store it eventually
	bgt		@BAT_copyloop



;	Create a 'system' address space owned by the motherboard coherence
;	group and by the MacOS process that we created earlier.
;	Leave a ptr to the new AddressSpace in r30 and its ID in r16.

	li		r8, 0
	lwz		r9, PSA.blueProcessPtr(r1)

	;	ARG		MPCoherenceID r8 owningCOHG		; 0 to use mobo COHG
	;			Process *r9 owningPROC

	bl		NKCreateAddressSpaceSub

	;	RET		MPErr r8
	;			AddressSpace *r9

	cmpwi	r8, 0
	mr		r30, r9
	bne		Init_Panic


	;	The relationship between SPACes and PROCs is still unclear...
	lwz		r31, PSA.blueProcessPtr(r1)


	;	Save the new addr spc ID in system process struct and KDP
	lwz		r16, AddressSpace.ID(r30)
	stw		r16, Process.SystemAddressSpaceID(r31)
	stw		r16, PSA.SystemAddressSpaceID(r1)


	;	Save a few pointers to it for good measure
	stw		r30, Process.SystemAddressSpacePtr(r31)
	stw		r30, EWA.PA_CurAddressSpace(r1)
	stw		r30, PSA.OtherSystemAddrSpcPtr(r1)



;	Show off the new address space struct, and at the same time,
;	copy the BATs that we copied from ConfigInfo to KDP, into the struct.

	_log	'Created system address space. ID '

	mr		r8, r16
	bl		Printw

	_log	'^n BATs '

	lwz		r16, 0x0288(r1) ; kdp.bat0l
	lwz		r17, 0x028c(r1) ; kdp.bat0u
	stw		r16, 0x0080(r30)
	stw		r17, 0x0084(r30)

	mr		r8, r16
	bl		Printw
	mr		r8, r17
	bl		Printw
	_log	'  '

	lwz		r16, 0x0298(r1) ; kdp.bat1l
	lwz		r17, 0x029c(r1) ; kdp.bat1u
	stw		r16, 0x0088(r30)
	stw		r17, 0x008c(r30)

	mr		r8, r16
	bl		Printw
	mr		r8, r17
	bl		Printw
	_log	'  '

	lwz		r16, 0x02a8(r1) ; kdp.bat2l
	lwz		r17, 0x02ac(r1) ; kdp.bat2u
	stw		r16, 0x0090(r30)
	stw		r17, 0x0094(r30)

	mr		r8, r16
	bl		Printw
	mr		r8, r17
	bl		Printw
	_log	'  '

	lwz		r16, 0x02b8(r1) ; kdp.bat3l
	lwz		r17, 0x02bc(r1) ; kdp.bat3u
	stw		r16, 0x0098(r30)
	stw		r17, 0x009c(r30)

	mr		r8, r16
	bl		Printw
	mr		r8, r17
	bl		Printw
	_log	'^n'



;	Initialize the kernel queues. They are called:
;
;	-	PHYS	(free list, in KDP, by InitFreePageList)
;	-	DLYQ	(in KDP, by me)
;	-	DBUG	(in KDP, by me)
;	-	PAGQ	(in KDP, has ID, by me)
;	-	NOTQ	(in KDP, by me)
;	-	TMRQs	(one in KDP, two in pool, one more in pool for Nanodebugger)
;	-	RDYQs	(four in KDP, for each task priority)

	;	Free list in hardcoded KDP location
	;	ARG		KernelData *r1
	;	CLOB	r8, r9
	bl		InitFreePageList


	;	Delay queue in hardcoded KDP location

	addi		r9, r1, PSA.DelayQueue
	InitList	r9, 'DLYQ', scratch=r8


	;	Debugger queue in hardcoded KDP location

	addi		r9, r1, PSA.DbugQueue
	InitList	r9, 'DBUG', scratch=r8


	;	Page queue in hardcoded KDP location...

	addi	r8, r1, PSA.PageQueue

	;	...with opaque id...
	li		r9, Queue.kIDClass
	bl		MakeID
	addi	r9, r1, PSA.PageQueue
	stw		r8, LLL.Freeform(r9)

	;	...which the blue task will probably want to know about
	stw		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.pageQueueID(r1)

	InitList	r9, 'PAGQ', scratch=r16


	;	Not sure what these globals relate to

	li		r8, 0
	stw		r8, PSA.QueueRelatedZero1(r1)
	stw		r8, PSA.QueueRelatedZero2(r1)


	;	Notification queue in hardcoded KDP location

	addi		r9, r1, PSA.NotQueue
	InitList	r9, 'NOTQ', scratch=r16


	;	TMRQs (see comments above and with InitTMRQs)
	;	(These are all the same structure but only one is signed!)

	bl		InitTMRQs


	;	One ready for each task priority (critical, etc)

	bl		SchInit



;	Set the BAT and segment registers (how were SRs calculated?)

	lwz		r8, EWA.PA_CurAddressSpace(r1)
	li		r9, 0
	bl		SchSwitchSpace



;	Create the Blue MacOS task

	;	ARG		Flags r7, Process *r8
	;	RET		Task *r8

	lwz		r8, PSA.blueProcessPtr(r1)
	bl		CreateTask

	;	Check
	mr.		r31, r8
	beq		Init_Panic

	lwz		r8, Task.ID(r31)
	stw		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.blueTaskID(r1)


	;	Can equal -1 or a 68k interrupt number. PIHes touch it.
	li		r8, -1
	sth		r8, PSA.Pending68kInt(r1)

	;
	stw		r31, PSA.PA_BlueTask(r1)
	stw		r31, EWA.PA_CurTask(r1)

	;	Misc population
	lisori	r8,	'blue'
	stw		r8, Task.Name(r31)

	li		r8, 2
	stb		r8, Task.State(r31)

	lisori	r8,	0x30028 ; (Z>>Task.kFlagNotDebuggable) | (Z>>Task.kFlagBlue) | (Z>>Task.kFlag26) | (Z>>Task.kFlag28)
	stw		r8, Task.Flags(r31)

	li		r8, 200
	stw		r8, Task.Weight(r31)

	li		r8, Task.kNominalPriority
	stb		r8, Task.Priority(r31)

	lhz		r8, EWA.CPUIndex(r1)			;	zero??????
	sth		r8, 0x001a(r31)

	lwz		r8, EWA.CPUBase + CPU.ID(r1)
	stw		r8, Task.CpuID(r31)

	lwz		r6, KDP.PA_ECB(r1)
	stw		r6, Task.ContextBlockPtr(r31)		;	override structs own ECB area

	lwz		r16, Task.ContextBlock + ContextBlock.VectorSaveArea(r31)
	stw		r16, ContextBlock.VectorSaveArea(r6)


	;	Bang on about some stuff

	_log	'System context at 0x'
	mr		r8, r6
	bl		Printw

	_log	' Vector save area at 0x'
	mr		r8, r16
	bl		Printw

	_log	' SDR1 0x'
	mfspr	r8, sdr1
	mr		r8, r8
	bl		Printw
	_log	'^n'


	;	Task enqueueing is still a bit of a mystery to me

	_log	'Adding blue task '
	lwz		r8, Task.ID(r31)
	mr		r8, r8
	bl		Printw
	_log	'to the ready queue^n'

	addi			r16, r31, Task.QueueMember
	RemoveFromList	r16, scratch1=r17, scratch2=r18


	;	ARG		Task *r8
	;	CLOB	r16, r17, r18

	mr		r8, r31
	bl		SchRdyTaskNow

	bl		CalculateTimeslice



;	Do some things I do not understand
	bl		FlagSchEval
	bl		StartTimeslicing



;	Create the idle task for the first CPU

	;	Unset EWA.kFlagVec so that
	;	idle task vector registers are not saved/restored
	;	(Leave the old value in r31)

	mr		r31, r7
	_bclr	r7, r7, EWA.kFlagVec

	;	ARG		Flags r7, Process *r8
	;	RET		Task *r8

	lwz		r8, PSA.blueProcessPtr(r1)
	bl		CreateTask

	;	Restore Flags
	mr		r7, r31

	;	Check
	mr.		r31, r8
	beq		Init_Panic

	;	Misc population
	lisori	r8, 'idle'
	stw		r8, Task.Name(r31)


	lisori	r8, 0xA0040 ; (Z>>Task.kFlag12) | (Z>>Task.kFlagNotDebuggable) | (Z>>Task.kFlag25)
	stw		r8, Task.Flags(r31)

	;	For the scheduler
	li		r8, 1
	stw		r8, Task.Weight(r31)

	li		r8, Task.kIdlePriority
	stb		r8, Task.Priority(r31)

	;	Blue does this too, probably zero, not sure why?
	lhz		r8, -0x116(r1)
	sth		r8, 0x01a(r31)

	lwz		r8, EWA.CPUBase + CPU.ID(r1)
	stw		r8, Task.CpuID(r31)

	;	Add a feature!?!?!?!
	lwz		r8, Task.ContextBlock + ContextBlock.Flags(r31)
	oris	r8, r8, 0x40
	stw		r8, Task.ContextBlock + ContextBlock.Flags(r31)

	;	Point task ECB at the idle loop within the nanokernel code
	lwz		r8, KDP.PA_NanoKernelCode(r1)
	llabel	r26, SchIdleTask
	add		r8, r8, r26
	stw		r8, Task.ContextBlock + ContextBlock.CodePtr(r31)

	;	The idle task runs in privileged mode with physical addressing
	lwz		r8, 0x01a4(r31)
	andi.	r8, r8, 0xbfcf		; unset loword (MSR_POW, MSR_ILE), MSR_PR, MSR_IR, MSR_DR
	stw		r8, 0x01a4(r31)

	;	Idle task for first CPU
	addi	r30, r1, EWA.CPUBase
	stw		r31, CPU.IdleTaskPtr(r30)

	;	Boast a bit
	_log	'Adding idle task '
	lwz		r8, Task.ID(r31)
	mr		r8, r8
	bl		Printw
	_log	'to the ready queue^n'

	;	This sure looks like a linked-list insertion
	addi			r16, r31, Task.QueueMember
	RemoveFromList	r16, scratch1=r17, scratch2=r18

	;	ARG		Task *r8
	;	CLOB	r16, r17, r18

	mr		r8, r31
	bl		SchRdyTaskNow

	bl		CalculateTimeslice

	;	Create a 'dummy' address space
		li		r8, 0
		lwz		r9, PSA.blueProcessPtr(r1)

		;	ARG		MPCoherenceID r8 owningCOHG		; 0 to use mobo COHG
		;			Process *r9 owningPROC

		bl		NKCreateAddressSpaceSub

		;	RET		MPErr r8
		;			AddressSpace *r9

		cmpwi	r8, 0
		mr		r30, r9
		lwz		r31, EWA.CPUBase + CPU.IdleTaskPtr(r1)
		bne		Init_Panic

		stw		r30, Task.AddressSpacePtr(r31)



;	Now do something with the page table
	lwz		r7, EWA.Flags(r1)
	lwz		r26, KDP.PA_ConfigInfo(r1)
	lwz		r18, KDP.PA_PageMapStart(r1)



;	Put HTABORG and PTEGMask in KDP, and zero out the last PTEG

	beq		cr5, @skip_zeroing_pteg
	mfspr	r8, sdr1

	;	get settable HTABMASK bits
	rlwinm	r22, r8, 16, 7, 15

	;	and HTABORG
	rlwinm	r8, r8, 0, 0, 15

	;	get a PTEGMask from upper half of HTABMASK
	ori		r22, r22, (-64) & 0xffff

	;	Save in KDP (OldWorld must do this another way)
	stw		r8, KDP.HTABORG(r1)
	stw		r22, KDP.PTEGMask(r1)

	;	zero out the last PTEG in the HTAB
	li		r23, 0
	addi	r22, r22, 64
@loop
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bgt		@loop
@skip_zeroing_pteg


;	Rather self-explanatory. Do this even if we did not just edit HTAB.

	bl		PagingFlushTLB



;	Copy the ConfigInfo pagemap into KDP, absolut-ising entries
;	whose physical addresses are relative to ConfigInfo.

	beq		cr5, @skip_copying_pagemap
	lwz		r9, NKConfigurationInfo.PageMapInitOffset(r26)	; from base of CI
	lwz		r22, NKConfigurationInfo.PageMapInitSize(r26)
	add		r9, r9, r26

@copyloop_pagemap
	subi	r22, r22, 4		;	load a word from the CI pagemap (top first)
	lwzx	r21, r9, r22

	andi.	r23, r21, PMDT.DaddyFlag | PMDT.PhysicalIsRelativeFlag
	cmpwi	r23, PMDT.PhysicalIsRelativeFlag
	bne		@physical_address_not_relative_to_config_info

	rlwinm	r21, r21, 0, ~PMDT.PhysicalIsRelativeFlag
	add		r21, r21, r26
@physical_address_not_relative_to_config_info

	stwx	r21, r18, r22	;	save in the KDP pagemap

	subic.	r22, r22, 4
	lwzx	r20, r9, r22	;	load another word, but no be cray
	stwx	r20, r18, r22	;	just save it in KDP
	bgt		@copyloop_pagemap
@skip_copying_pagemap



;	Edit the KDP's copied PageMap to contain the correct physical address
;	of the parts that we know about: IRP, KDP & surrounds, EDP.
;	(No changes to flags)

	;	IRP

		lwz		r8, NKConfigurationInfo.PageMapIRPOffset(r26)
		add		r8, r18, r8

		lisori	r19, IRPOffset
		add		r19, r19, r1

		;	Set physical address (top 20 bits of second word)
		lwz		r23, PMDT.PBaseAndFlags(r8)
		rlwimi	r23, r19, 0, 0, 19
		stw		r23, PMDT.PBaseAndFlags(r8)


	;	KDP (plus the nine pages below it)

IRPTopOffset	equ		IRPOffset + 0x1000

		lwz		r8, NKConfigurationInfo.PageMapKDPOffset(r26)
		add		r8, r18, r8

		lisori	r19, IRPTopOffset
		add		r19, r1, r19

		;	Page count - 1
		lisori	r22, (-IRPTopOffset) >> 12

		;	Set physical address (top 20 bits of second word)
		lwz		r23, PMDT.PBaseAndFlags(r8)
		rlwimi	r23, r19, 0, 0, 19
		stw		r23, PMDT.PBaseAndFlags(r8)

		;	Set page count - 1 (bottom half of first word)
		sth		r22, PMDT.PageCount(r8)

		;	Whaaaaaa?
		lhz		r23, PMDT.LBase(r8)
		subf	r23, r22, r23
		sth		r23, PMDT.LBase(r8)


	;	EDP

		lwz		r19, KDP.PA_EmulatorData(r1)
		lwz		r8, NKConfigurationInfo.PageMapEDPOffset(r26)
		add		r8, r18, r8

		lwz		r23, PMDT.PBaseAndFlags(r8)
		rlwimi	r23, r19, 0, 0, 19
		stw		r23, PMDT.PBaseAndFlags(r8)



;	Copy segment maps from ConfigInfo
;	(128 bytes per mode: supervisor, user, CPU, overlay)
;		even-indexed words are offsets into the pagemap
;		odd-indexed words are or-ed with 0x20000000

	addi	r9, r26, NKConfigurationInfo.SegMaps - 4
	addi	r8, r1, KDP.SegMaps - 4
	li		r22, 128 * 4

@copyloop_segmaps
	lwzu	r23, 4(r9)
	subic.	r22, r22, 8
	add		r23, r18, r23	;	even-indexed words are PMDT offsets in PageMap
	stwu	r23, 4(r8)

	lwzu	r23, 4(r9)
	oris	r23, r23, 0x2000	;	no clue?
	stwu	r23, 4(r8)

	bgt		@copyloop_segmaps



;	Give KDP pointers to its own structures (how lame).

	addi	r23, r1, KDP.SegMap32SupInit
	stw		r23, KDP.SegMap32SupInitPtr(r1)

	lwz		r23, NKConfigurationInfo.BatMap32SupInit(r26)
	stw		r23, KDP.BatMap32SupInit(r1)


	addi	r23, r1, KDP.SegMap32UsrInit
	stw		r23, KDP.SegMap32UsrInitPtr(r1)

	lwz		r23, NKConfigurationInfo.BatMap32UsrInit(r26)
	stw		r23, KDP.BatMap32UsrInit(r1)


	addi	r23, r1, KDP.SegMap32CPUInit
	stw		r23, KDP.SegMap32CPUInitPtr(r1)

	lwz		r23, NKConfigurationInfo.BatMap32CPUInit(r26)
	stw		r23, KDP.BatMap32CPUInit(r1)


	addi	r23, r1, KDP.SegMap32OvlInit
	stw		r23, KDP.SegMap32OvlInitPtr(r1)

	lwz		r23, NKConfigurationInfo.BatMap32OvlInit(r26)
	stw		r23, KDP.BatMap32OvlInit(r1)



;	Use the PageMap kindly provided by the Trampoline to count VMMaxVirtualPages
;	(remembering that virtual is meant in the '68k VM' sense).

;	In brief: only big fat PMDTs on 256MB (i.e. segment) boundaries need apply.

;	INDEPENDENT OF INSTALLED RAM!

	li		r22, 0		;	counter
	addi	r19, r1, KDP.SegMaps - 8
	b		@next_segment

@skip_pmdt
	addi	r8, r8, 0x08
	b		@searchloop

@next_segment
	lwzu	r8, 8(r19)

@searchloop
	;	Get both words of the pointed-to PMDT
	lwz		r30, 0(r8)		;	OffsetWithinSegInPages(16b) || PageCount-1(16b)
	lwz		r31, 4(r8)		;	PhysicalInPages(20b) || pageAttr(12b)

	;	Stop counting if we meet a PMDT not at the base of its segment.

	;	Stop counting if we meet a PMDT with its top two pageAttr bits both unset.

	;	If PMDT has its top two pageAttr bits both set,
	;	check the PMDT following it in the PageMap.
	;	(Never seen this in the wild.)

	cmplwi	cr7, r30, 0xffff								;	if not at base:
	rlwinm.	r31, r31, 0, PMDT.DaddyFlag | PMDT.CountingFlag ;						if neither flag:
	bgt		cr7, @finish_count								;	stop counting
	cmpwi	cr6, r31, PMDT.DaddyFlag | PMDT.CountingFlag 	;											if both flags:
	beq		@finish_count									;						stop counting
	beq		cr6, @skip_pmdt									;											next PMDT instead

	add		r22, r22, r30
	addi	r22, r22, 1
	beq		cr7, @next_segment		;	else count and move on to next segment descriptor

@finish_count
	stw		r22, KDP.VMMaxVirtualPages(r1)



;	Create the Flat Page List:
;	a draft PTE for every usable physical page.

;	Usable physical pages are:
;		Inside a RAM bank, and
;		NOT inside the kernel's reserved physical memory

;	By 'draft PTE', I mean these parts of the second word of a PTE:
;		physical page number (base & 0xfffff000)
;		WIMG bits (from oddly formatted ConfigInfo.PageAttributeInit)
;		bottom PP bit always set

;	And all this goes at the bottom of the kernel reserved area.
;	Leave ptr to kernel reserved area in r21
;	Leave ptr to topmost entry in r29.

ListFreePhysicalPages

	beq		cr5, @skip

	lwz		r21, KDP.KernelMemoryBase(r1)
	lwz		r20, KDP.KernelMemoryEnd(r1)

	stw		r21, KDP.FlatPageListPtr(r1)

	lwz		r30, EWA.PA_IRP(r1)

	;	Will be writing things to the very base of kernel memory. Oh dear.
	subi	r29, r21, 4

	addi	r19, r30, IRP.SystemInfo + NKSystemInfo.Bank0Start - 8

	lwz		r23, KDP.PageAttributeInit(r1)	;	default WIMG/PP settings in PTEs

	;	Pull WIMG bits out of PageAttributeInit
	li		r30, 1
	rlwimi	r30, r23, 1, 25, 25
	rlwimi	r30, r23, 31, 26, 26
	xori	r30, r30, 0x20
	rlwimi	r30, r23, 29, 27, 27
	rlwimi	r30, r23, 27, 28, 28

	li		r23, NKSystemInfo.MaxBanks

@nextbank
	subic.	r23, r23, 1
	blt		@done

	lwzu	r31, 8(r19)		;	bank start address
	lwz		r22, 4(r19)		;	bank size
	or		r31, r31, r30	;	looks a lot like the second word of a PTE

@nextpage
	cmplwi	r22, 4096
	cmplw	cr6, r31, r21
	cmplw	cr7, r31, r20
	subi	r22, r22, 4096
	blt		@nextbank

	;	Check that this page is outside the kernel's reserved area
	blt		cr6, @below_reserved
	blt		cr7, @in_reserved
@below_reserved
	stwu	r31, 4(r29)		;	write that part-PTE at the base of kernel memory
@in_reserved

	addi	r31, r31, 4096
	b		@nextpage

@done
@skip



PrimeFreeListFromBanks

	beq		cr5, PrimeFreeListFromSystemHeap

	;	Add ~18 to 20 of these pages to the free list, depending on RAM size
	subf	r22, r21, r29
	addi	r8, r22, 4096
	srwi	r17, r22, 13
	addi	r17, r17, 18

	_log	'Priming the system free list with '

	mr		r8, r17
	bl		Printd

	_log	'pages.^n'

@loop
	lwz		r8, 0(r29)
	rlwinm	r8, r8, 0, 0, 19		;	physical base of page
	bl		FreePageListPush ; PhysicalPage *r8

	subi	r17, r17, 1
	subi	r29, r29, 4
	cmpwi	r17, 0
	bgt		@loop

	b		DonePrimingFreeList



;	Apparently the replacement kernel can find pages just above the EDP?

;	More power to it, I say.

PrimeFreeListFromSystemHeap

	lwz		r8, 0x05a8(r1) ; kdp.0x5a8
	addi	r18, r1, 0x2000 ; kdp.0x2000
	subf.	r8, r18, r8
	blt		DonePrimingFreeList
	addi	r8, r8, 0x1000
	srwi	r17, r8, 12

	_log	'Priming the system free list with '

	mr		r8, r17
	bl		Printd

	_log	'system heap pages.^n'


@stupidloop
	rlwinm r8, r18, 0, 0, 19

	bl		FreePageListPush ; PhysicalPage *r8
	addi	r17, r17, -0x01
	addi	r18, r18, 0x1000
	cmpwi	r17, 0x00
	bgt		@stupidloop




DonePrimingFreeList



;	Bang on a little bit


	_log	'VMMaxVirtualPages: '			; 0005fffe

	lwz		r8, KDP.VMMaxVirtualPages(r1)
	mr		r8, r8
	bl		Printw

	_log	'VMLogicalPages: '

	lwz		r8, KDP.VMLogicalPages(r1)
	mr		r8, r8
	bl		Printw

	_log	'^n'

	_log	'Interrupt handler kind: '

	lwz		r8, KDP.PA_ConfigInfo(r1) ; kdp.pa_ConfigInfo
	lbz		r8, NKConfigurationInfo.InterruptHandlerKind(r8)
	mr		r8, r8
	bl		Printb

	_log	'^n'



;	Now the code paths diverge again.
;
;	The builtin kernel needs to start the 68k virtual machine.
;
;	The replacement kernel needs to return to the Mac OS
;	boot process.

	beq		cr5, finish_old_world



;	Here we reconcile the actual physical memory with the
;	size of the contiguous part of the MacOS address space.

;	Going in:
;		r21 points to base of long array
;		r29 points (empty ascending) to top of long array

;	Pops have been made to prime the system free list,
;	but otherwise, this contains all the physical memory
;	that the Trampoline reported in the banks (Tramp already
;	subtracted ROM and structures), minus the kernel data.

ReconcileMemory

	;	r22 = pages still in array * 4
	subf	r22, r21, r29

	;	r8 = theoretical maximum MacOS page count * 4
	lwz		r8, KDP.VMMaxVirtualPages(r1)
	slwi	r8, r8, 2

	;	Memory We Have versus Memory We Could Use
	;	(see blt  below)
	cmplw	r22, r8

	;	TotalPhysicalPages equals pages not yet in free list but that could go in.
	;	(Therefore exludes Trampoline areas, kernel areas, free list prime)
	addi	r19, r22, 4
	srwi	r19, r19, 2
	stw		r19, KDP.TotalPhysicalPages(r1)

	;	r22 = pages in array destined to be mapped to blue area
	blt		@less_than_VMMaxVirtualPages
	subi	r22, r8, 4
@less_than_VMMaxVirtualPages

	li		r30, 0

	lwz		r8, EWA.PA_IRP(r1)

	;	That sets UsableMemorySize = LogicalMemorySize (= size of blue area), 
	addi	r19, r22, 4
	slwi	r19, r19, 10
	ori		r30, r30, 0xffff
	stw		r19, IRP.SystemInfo + NKSystemInfo.UsableMemorySize(r8)
	srwi	r22, r22, 2
	stw		r19, IRP.SystemInfo + NKSystemInfo.LogicalMemorySize(r8)
	;	Now r22 is a page count

	;	The above, divided by 4096
	srwi	r19, r19, 12
	stw		r19, KDP.VMLogicalPages(r1)

	addi	r29, r1, KDP.FlatPageListSegPtrs - 4
	addi	r19, r1, KDP.SegMaps - 8



	;	Divvy up the FlatPageList into segments
@persegment
			;	r21 = fully ascending pointer (starts at base)
			;	r

			cmplwi	r22, 0xffff			;	pages in a segment
			lwzu	r8, 8(r19)			;	get the first word of a SegMap entry

			rotlwi	r31, r21, 10
			ori		r31, r31, 0xc00		;	r31 = second byte with fake-ass physical backing

			;	Rewrite the pagemap entry
			stw		r30, 0(r8)			;	Whole segment
			stw		r31, 4(r8)			;	Based on the FlatPageList, with weird shifts!

			stwu	r21, 0x0004(r29)
			addis	r21, r21, 4			;	we just used a segment's worth of pages on this
			subis	r22, r22, 1			;	pages in a segment
	bgt		@persegment

	;	Number of pages in that last segment
	sth		r22, 0x0002(r8)

	lwz		r17, KDP.VMLogicalPages(r1)
	lwz		r18, KDP.TotalPhysicalPages(r1)
	stw		r17, KDP.TotalPhysicalPages(r1)

	;	Get the number of 'unusable' physical pages (not [yet] wanted by main MacOS area)
	;	If any, they will be chucked on the free list
	subf.	r18, r17, r18
	slwi	r31, r17, 12		;	does this work with discontiguous banks? hmm...
	ble		@no_leftover_ram

	;	See?
	_log	'Physical RAM greater than the initial logical area.^n Moving '

	mr		r8, r18
	bl		Printd

	_log	'pages into the system free page list.^n'


@loop
	mr		r8, r31
	bl		FreePageListPush ; PhysicalPage *r8
	addi	r31, r31, 4096
	subi	r18, r18, 1
	cmpwi	r18, 0
	bgt		@loop

@no_leftover_ram



;	Create Areas (an abstract NKv2 structure) from the Trampoline's PageMap

	bl		CreateAreasFromPageMap



;	No understandy

	addi	r29, r1, 0x5e0 ; kdp.0x5e0
	bl		PagingFunc2
	bl		PagingFlushTLB



;	Makes QEMU complain

	bl		ProbePerfMonitor



;	Done all we can

	_log	'Reset system - Into the 68K fire: '

	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw

	_log	'^n'

	lwz		r9, ContextBlock.XER(r6)
	mfsprg	r8, 0
	mtxer	r9

	bl		SchRestoreStartingAtR14

	b		kcPrioritizeInterrupts



finish_old_world
	addi	r29, r1,  0x5e8
	bl		PagingFunc2
	bl		PagingFlushTLB
	bl		CreateAreasFromPageMap
	bl		ProbePerfMonitor
	lwz		r27,  0x0630(r1)
	lwz		r27,  0x0094(r27)
	bl		PagingL2PWithoutBATs
	beq		setup_0x1160
	li		r30,  0x00
	stw		r30, -0x0004(r29)
	eieio	
	stw		r30,  0x0000(r29)
	sync	

setup_0x1160
	bl		PagingFunc1
	lwz		r27,  0x0630(r1)
	lwz		r27,  0x009c(r27)
	bl		PagingL2PWithoutBATs
	beq		setup_0x1188
	li		r30,  0x00
	stw		r30, -0x0004(r29)
	eieio	
	stw		r30,  0x0000(r29)
	sync	

setup_0x1188
	bl		PagingFunc1
	lwz		r27,  0x0630(r1)
	lwz		r27,  0x00a0(r27)
	lis		r19,  0x00
	ori		r19, r19,  0xa000
	subf	r19, r19, r27

setup_0x11a0
	bl		PagingL2PWithoutBATs
	beq		setup_0x11bc
	li		r30,  0x00
	stw		r30, -0x0004(r29)
	eieio	
	stw		r30,  0x0000(r29)
	sync	

setup_0x11bc
	bl		PagingFunc1
	cmplw	r27, r19
	addi	r27, r27, -0x1000
	bgt		setup_0x11a0
	lwz		r27,  0x0630(r1)
	lwz		r27,  0x00a4(r27)
	bl		PagingL2PWithoutBATs
	beq		setup_0x11f0
	li		r30,  0x00
	stw		r30, -0x0004(r29)
	eieio	
	stw		r30,  0x0000(r29)
	sync	

setup_0x11f0
	bl		PagingFunc1

	_log	'Nanokernel replaced. Returning to boot process^n'

	addi	r9, r1, KDP.VecBaseAlternate
	mtsprg	3, r9

;	r1 = kdp
	b		old_world_rfi_to_userspace_boot



;	Called by InitReplacement.s if we accidentally try
;	to replace a v2 kernel (like ourself).
;
;	All we need to do is restore
;	sprg0 (ewa/kdp) and sprg3 (vecBase).

CancelReplacement

	bl		InitScreenConsole

	_log	'Nanokernel NOT replaced. Returning to boot process^n'

	lwz		r8, KDP.OldKDP(r1)
	mtsprg	0, r8

	addi	r9, r8, KDP.VecBaseAlternate
	mtsprg	3, r9



;	            old_world_rfi_to_userspace_boot             

;	> r1    = kdp

old_world_rfi_to_userspace_boot	;	OUTSIDE REFERER
	lwz		r4, KDP.LA_EmulatorKernelTrapTable(r1)
	lwz		r8, KDP.OtherFreeThing(r1)
	lwz		r9, PSA.UserModeMSR(r1)
	addi	r8, r8, ReturnCode - NKTop
	mtsrr0	r8
	mtsrr1	r9
	rfi


ReturnCode
	li		r3, 255
	mtlr	r4
	blrl



;	ARG		Lock *r8

	align	5

AcquireLock	;	OUTSIDE REFERER
	lwarx	r9, 0, r8
	cmpwi	r9,  0
	mfsprg	r9, 0
	bne-	@already_held
	lwz		r9, -0x0340(r9)
	sync
	stwcx.	r9, 0, r8
	bne-	AcquireLock
	mflr	r9
	stw		r9,  0x0010(r8)
	isync
	blr

@already_held
	stmw	r22, -0x0094(r9)
	mr		r22, r9
	mflr	r30
	mr		r31, r8
	lwz		r29, -0x0340(r22)
	lwz		r28,  0x0000(r31)
	stw		r30, -0x0098(r22)
	cmpw	r28, r29
	bne+	@0x84
	bl		@start_logging
	_log	'Recursive spinlock ***^n'
	bl		Init_Panic

@0x84
	bl		@0x184
	mr		r24, r28
	mr		r25, r29
	lwz		r30, -0x0004(r22)
	mfdec	r29
	lwz		r28, PSA.DecClockRateHzCopy(r30)
	slwi	r28, r28,  3
	subf	r29, r28, r29
	b		@0xc0

@0xa8
	lwz		r30, -0x0004(r22)
	lwz		r28, PSA.ThudLock(r30)
	cmpwi	r28,  0x00
	beq-	@0xc0
	mfdec	r29
	addis	r29, r29, -0x01

@0xc0
	mfdec	r28
	subf.	r28, r29, r28
	bgt-	@0x118
	bl		@start_logging
	_log	'Timeout - locked CpuID '
	mr		r8, r30
	bl		printw
	_log	'***^n'
	bl		Init_Panic

@0x118
	lwz		r30,  0x0000(r31)
	cmpwi	r30,  0x00
	bne+	@0xa8

@0x124
	lwarx	r30, 0, r31
	cmpwi	r30, 0
	bne+	@0xa8
	lwz		r30, EWA.CPUBase + CPU.ID(r22)
	sync
	stwcx.	r30, 0, r31
	bne-	@0x124
	mfxer	r30
	bl		@0x184
	lwz		r27, -0x0098(r22)
	subfc	r29, r25, r29
	lwz		r25,  0x000c(r31)
	subfe	r28, r24, r28
	lwz		r24,  0x0008(r31)
	addc	r25, r25, r29
	adde	r24, r24, r28
	stw		r25,  0x000c(r31)
	stw		r24,  0x0008(r31)
	mtlr	r27
	stw		r27,  0x0010(r31)
	mtxer	r30
	mr		r8, r22
	lmw		r22, -0x0094(r8)
	blr

@0x184
	mftbu	r28
	mftb	r29
	mftbu	r27
	cmpw	r28, r27
	beqlr+
	b		@0x184

@start_logging		;	actually a func
	mfsprg	r28, 0
	mflr	r27

	lwz		r29, EWA.CPUBase + CPU.ID(r28)
	_log	'^n*** On CPU '
	mr		r8, r29
	bl		printw

	_log	'spinlock 0x'

	mr		r8, r31
	bl		printw

	;	Print lock sig
	lwz		r8, Lock.Signature(r31)
	rotlwi	r8, r8, 8
	bl		printc
	rotlwi	r8, r8, 8
	bl		printc
	rotlwi	r8, r8, 8
	bl		printc
	rotlwi	r8, r8, 8
	bl		printc

	lwz		r29, -0x0098(r28)
	_log	' caller 0x'
	mr		r8, r29
	bl		printw

	mtlr	r27
	blr



Init_Panic
	b		panic
