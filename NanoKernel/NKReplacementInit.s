;		sprg0 = old KDP/EWA/r1 ptr
;		r3 = PA_NanoKernelCode
;		r4 = physical base of our global area
;		r5 = NoIdeaR23
;		r6 = PA_EDP or zero?
;		r7 = probably ROMHeader.ROMRelease ('rom vers', e.g. 0x10B5 is 1.0§5)


InitReplacement

	crset	cr5_eq


	li		r0, 0



;	Position and initialise the kernel globals, IRP to KDP inclusive.
;	(subset of builtin kernel)

	;	Zero from IRP (r4) to KDP (r4 + 10 pages)

	lisori	r12, kKDPfromIRP
	mr		r13, r4
@wipeloop
	subic.	r12, r12, 4
	stwx	r0, r13, r12
	bgt		@wipeloop


	;	Copy the old KDP to r4 + 10 pages.
	;	(r1 becomes our main ptr and r4 is discarded)

	mfsprg	r11, 0
	lisori	r1, kKDPfromIRP
	add		r1, r1, r4

	li		r12, 4096
@kdp_copyloop
	subic.	r12, r12, 4
	lwzx	r10, r11, r12
	stwx	r10, r1, r12
	bgt		@kdp_copyloop


	;	IRP goes at the base of the area we were given.
	;	Fill with repeating pattern and point EWA at it.

	lisori	r12, -kKDPfromIRP
	add		r12, r12, r1
	stw		r12, EWA.PA_IRP(r1)
	bl		InitIRP				;	clobbers r10 and r12



;	Play with some of the other values we were given

	;	Leave ROMRelease in r23.

	mr		r23, r7

	;	If no EDP (Emulator Data Page) pointer was provided,
	;	then put the EDP above our new KDP.

	cmpwi	r6, 0
	stw		r11, KDP.OldKDP(r1)
	stw		r9,  0x05a4(r1)


	;	discarded

	bne		@emulatordata_ptr_provided
	addi	r6, r1,  0x1000
@emulatordata_ptr_provided



	;	Save a few bits

	stw		r6,  0x05a8(r1)
	stw		r3, KDP.PA_NanoKernelCode(r1)
	stw		r5, PSA.NoIdeaR23(r1)
	stw		r1, EWA.PA_KDP(r1)

	addi	r12, r1, -0x340			;	get the base of the main CPU struct
	li		r10, -1
	stw		r10, CPU.ID(r12)

	lwz		r3, KDP.PA_ConfigInfo(r1)

	bl		LookupInterruptHandler
	stw		r7, KDP.PA_InterruptHandler(r1)



;	Clearly changed our mind about where we might be.

	bl		@x
@x	mflr	r12
	subi	r12, r12, @x - NKTop

	stw		r12, KDP.PA_NanoKernelCode(r1)


;	FDP

	llabel	r10, FDP
	add		r12, r10, r12
	stw		r12, KDP.PA_FDP(r1)


;	Do something terrible with the CPU features

	lwz		r12, EWA.Flags(r1)
	li		r10,  0x00
	rlwimi	r10, r12,  0, 12, 15
	rlwimi	r10, r12,  0, 28, 30
	stw		r10, PSA.FlagsTemplate(r1)


;	Cook up a MSR:
;		MSR_EE = 1
;		MSR_PR = 1
;		MSR_FP = 0
;		MSR_ME = 0
;		MSR_FE0 = 0
;		MSR_SE = 0
;		MSR_BE = 0
;		MSR_FE1 = 0
;		MSR_IP = preserved
;		MSR_IR = 1
;		MSR_DR = 1
;		MSR_RI = 0
;		MSR_LE = 0

	mfmsr	r12
	andi.	r12, r12,  0x0040
	ori		r12, r12,  0xd032
	stw		r12, PSA.UserModeMSR(r1)



;	Set SPRG0 (for this CPU at least)

	mtsprg	0, r1


;	r11 still contains the OLD EWA ptr (which is also KDP/PSA ptr?)

	lhz		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoVer(r11)
	cmpwi	r12,  0x0101

	bgt		@replaces_later_than_0101

	;	
	lwz		r12, KDP.PA_ECB_Old(r1)
	stw		r12, EWA.PA_ContextBlock(r1)

	lwz		r12, 0x660(r1)
	oris	r12, r12, 0x20
	stw		r12, EWA.Flags(r1)

	lwz		r12,  0x0664(r1)
	stw		r12, EWA.Enables(r1)		; boy, better figure out what this is

	b		@endif
@replaces_later_than_0101

	;	Obviously cannot replace a v2 NanoKernel like myself
	cmpwi	r12,  0x0200
	bge		CancelReplacement

	lwz		r12, EWA.PA_ContextBlock(r11)
	stw		r12, EWA.PA_ContextBlock(r1)

	lwz		r12, EWA.Flags(r11)
	oris	r12, r12, 0x20
	stw		r12, EWA.Flags(r1)

	lwz		r12, -0x000c(r11)
	stw		r12, EWA.Enables(r1)

@endif



	lwz		r12,  0x0340(r11)
	lwz		r10,  KDP.LA_NCB(r11)
	cmpw	r12, r10

	beq		replace_old_kernel_0x198
	stw		r12,  KDP.LA_NCB(r1)
	stw		r0,  0x06b4(r1)
	lwz		r10,  0x05b0(r11)
	stw		r10,  0x06c0(r1)
	lwz		r10,  KDP.LA_NCB(r11)
	stw		r10,  0x06c4(r1)
	lwz		r10,  0x05b8(r11)
	stw		r10,  0x06c8(r1)
	lwz		r10,  0x05bc(r11)
	stw		r10,  0x06cc(r1)
	stw		r0,  0x06d0(r1)
	stw		r0,  0x06d4(r1)
	stw		r0,  0x06d8(r1)
	stw		r0,  0x06dc(r1)
	stw		r0,  0x06e0(r1)
	stw		r0,  0x06e4(r1)
	stw		r0,  0x06e8(r1)
	stw		r0,  0x06ec(r1)
	stw		r0,  0x06f0(r1)
	stw		r0,  0x06f4(r1)
	stw		r0,  0x06f8(r1)
	stw		r0,  0x06fc(r1)
replace_old_kernel_0x198



;	Adjust a few KDP pointers to point into the new KDP

	lwz		r12, KDP.PA_PageMapStart(r1)
	subf	r12, r11, r12
	add		r12, r12, r1
	stw		r12, KDP.PA_PageMapStart(r1)

	lwz		r12, KDP.PA_PageMapEnd(r1)
	subf	r12, r11, r12
	add		r12, r12, r1
	stw		r12, KDP.PA_PageMapEnd(r1)

	lwz		r12,  0x05e8(r1)
	subf	r12, r11, r12
	add		r12, r12, r1
	stw		r12,  0x05e8(r1)



;	Wipe KDP's NKInfo and ProcessorInfo

	li		r12, 0x200
	addi	r10, r1, KDP.NanoKernelInfo

@wipeloop
	subic.	r12, r12, 4
	stwx	r0, r10, r12
	bgt		@wipeloop




	;	r9 = physical base of kernel
	li		r12, 0
	addi	r10, r1, KDP.InfoRecord

	bl		MoveRecord ; (NanoKernelCode, NewKDPInfoRecord, OldKDP, 0)

	stw		r10, KDP.InfoRecord + InfoRecord.InfoRecordPtr(r1)
	stw		r0, KDP.InfoRecord + InfoRecord.Zero(r1)



	lhz		r12, KDP.InfoRecord + InfoRecord.NKProcessorStateLen(r1)
	addi	r10, r1, PSA.ProcessorState
	lwz		r9, KDP.InfoRecord + InfoRecord.NKProcessorStatePtr(r1)

	bl		MoveRecord ; (OldProcessorState, NewPSAProcessorState, OldKDP, ProcessorStateLen)

	stw		r10, KDP.InfoRecord + InfoRecord.NKProcessorStatePtr(r1)



	lhz		r12, KDP.InfoRecord + InfoRecord.NKHWInfoLen(r1)
	lwz		r10, EWA.PA_IRP(r1)
	addi	r10, r10, IRP.HWInfo
	lwz		r9, KDP.InfoRecord + InfoRecord.NKHWInfoPtr(r1)

	bl		MoveRecord ; (OldHWInfo, NewIRPHWInfo, OldKDP, HWInfoLen)

	stw		r10, KDP.InfoRecord + InfoRecord.NKHWInfoPtr(r1)



	lhz		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoLen(r1)
	addi	r10, r1, KDP.ProcessorInfo
	lwz		r9, KDP.InfoRecord + InfoRecord.NKProcessorInfoPtr(r1)

	bl		MoveRecord ; (OldProcessorInfo, NewKDPProcessorInfo, OldKDP, ProcessorInfoLen)

	stw		r10, KDP.InfoRecord + InfoRecord.NKProcessorInfoPtr(r1)
	stw		r10, KDP.InfoRecord + InfoRecord.NKProcessorInfoPtr2(r1)



	lhz		r10, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer(r1)
	cmplwi	r10, 0x0112
	bge		@ProcessorInfo_version_already_current

	li		r12, 160
	li		r10, 0x0112
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoLen(r1)
	sth		r12, KDP.InfoRecord + InfoRecord.NKProcessorInfoLen2(r1)
	sth		r10, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer(r1)
	sth		r10, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer2(r1)
@ProcessorInfo_version_already_current



	lhz		r12, KDP.InfoRecord + InfoRecord.NKDiagInfoLen(r1)
	addi	r10, r1, PSA.DiagInfo
	lwz		r9, KDP.InfoRecord + InfoRecord.NKDiagInfoPtr(r1)

	bl		MoveRecord ; (OldDiagInfo, NewPSADiagInfo, OldKDP, DiagInfoLen)

	stw		r10, KDP.InfoRecord + InfoRecord.NKDiagInfoPtr(r1)



	lhz		r12, KDP.InfoRecord + InfoRecord.NKSystemInfoLen(r1)
	lwz		r10, EWA.PA_IRP(r1)
	addi	r10, r10, IRP.SystemInfo
	lwz		r9, KDP.InfoRecord + InfoRecord.NKSystemInfoPtr(r1)

	bl		MoveRecord ; (OldSystemInfo, NewIRPSystemInfo, OldKDP, SystemInfoLen)

	stw		r10, KDP.InfoRecord + InfoRecord.NKSystemInfoPtr(r1)



	lhz		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoLen(r1)
	addi	r10, r1, KDP.NanoKernelInfo
	lwz		r9, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoPtr(r1)

	bl		MoveRecord ; (OldNanoKernelInfo, NewKDPNanoKernelInfo, OldKDP, NanoKernelInfoLen)

	stw		r10, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoPtr(r1)



	li		r12, 0x160
	sth		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoLen(r1)


	li		r12, kNanoKernelVersion
	sth		r12, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoVer(r1)


	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.DecClockRateHz(r1)
	stw		r8, PSA.DecClockRateHzCopy(r1)



;	Play with ConfigFlags

	lwz		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)

	_bset	r8, r8, 31		;	always set bit 31

	if		&TYPE('NKShowLog') != 'UNDEFINED'
		_bset	r8, r8, 28	;	see if someone can test this
	endif

	cmplwi	r23, 0x27f3		;	set bit 27 on ROM 2.7f3 or later
	blt		@oldrom			;	means later than PDM and Cordyceps
	_bset	r8, r8, 27
@oldrom

	stw		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)



;	Say hello.

	bl		InitScreenConsole

	_log	'Hello from the replacement multitasking NanoKernel. Version: '

	mr		r8, r12
	bl		printh


	_log	'^n Old KDP: '

	mr		r8, r11
	bl		printw


	_log	' new KDP: '

	mr		r8, r1
	bl		printw


	_log	' new irp: '

	lwz		r8, EWA.PA_IRP(r1)
	mr		r8, r8
	bl		printw


	_log	'ROM vers: '

	mr		r8, r23
	bl		printh

	_log	'^n'



;	Jump back into the common code path of Init.s

	;	The Emulator ContextBlock is expected in r6.
	lwz		r6, KDP.PA_ECB(r1)

	b		InitHighLevel



;	                     MoveRecord                      

;		r9 = base of kernel???

;	Seems to be code to relocate some old structures.

MoveRecord	;	OUTSIDE REFERER

	;	Check whether the old structure is in KDP
	;	
	lwz		r22, KDP.PA_ConfigInfo(r1)
	lwz		r22, NKConfigurationInfo.LA_InfoRecord(r22)

	subf	r9, r22, r9		; r9 = offset of old address in irp
	cmplwi	r9, 0x1000
	bge		@kdp

	add		r21, r9, r11	; r21 = the old address if it had been in KDP instead?


@0x18

	;	r9 = offset of old structure in old parent page
	;	r10 = destination
	;	r12 = length


	;	
@loop
	subic.	r12, r12, 4
	blt		@exit_loop
	lwzx	r9, r21, r12
	stwx	r9, r10, r12
	bgt		@loop
@exit_loop

	lwz		r22, KDP.PA_ConfigInfo(r1)
	lwz		r22, NKConfigurationInfo.LA_KernelData(r22)

	subf	r10, r1, r10
	lisori	r21, -9 * 4096
	cmpw	r10, r21			; if dest is nearer than 9 pages below kdp...
	blt		@0x50
	add		r10, r10, r22
	blr		
@0x50

	lwz		r22, KDP.PA_ConfigInfo(r1)
	lwz		r22, NKConfigurationInfo.LA_InfoRecord(r22)
	lwz		r21, EWA.PA_IRP(r1)
	add		r10, r10, r1
	subf	r10, r21, r10
	add		r10, r10, r22
	blr		

@kdp
	add		r9, r9, r22
	lwz		r22, KDP.PA_ConfigInfo(r1)
	lwz		r22, NKConfigurationInfo.LA_KernelData(r22)
	subf	r9, r22, r9				; r9 now equals an offset from old_kdp
	add		r21, r9, r11			; r21 = address in new_kdp
	b		@0x18