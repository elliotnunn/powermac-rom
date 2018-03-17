;_______________________________________________________________________
;	My additions to the NanoKernel, to go at the end of the code image
;_______________________________________________________________________

	if		&TYPE('NKDebugShim') != 'UNDEFINED'

	DeclareMPCall	200, NKDebug

NKDebug

	;	Lifted from NKxprintf:
	;	Put the physical address of the r3 arg in r8

	rlwinm.	r9, r11, 0, MSR_DRbit, MSR_DRbit	;	IntSyscall sets this
	mr		r8, r3

	beq		@already_physical
	li		r9, 0
	bl		V2P			; takes page EA in r8, r9=0, returns page PA in r17
	beq		@fail
	rlwimi	r8, r17,  0,  0, 19
@already_physical
	

	;	Copy the command into the KDP buffer reserved for this purpose:
	;	r8 = src
	;	r29 = dest
	;	r30 = ctr
	;	r31 = val

	mfsprg	r1, 0
	lwz		r1, EWA.PA_KDP(r1)

	li		r30, 0
	addi	r29, r1, PSA.ThudBuffer
@cmdloop
	lbzx	r31, r8, r30
	stbx	r31, r29, r30
	addi	r30, r30, 1
	cmpwi	r31, 0
	bne		@cmdloop

	lwz		r31, PSA._404(r1)

	stw		r8, PSA._404(r1)
	
	bl		panic

	lwz		r8, PSA._404(r1)
	li		r0, 0
	stw		r0, 0(r8)

	stw		r31, PSA._404(r1)

	b		ReturnZeroFromMPCall


@fail
	b		ReturnMPCallOOM

	endif



;	The 7447a does not have THRM registers. Enable me to stop the mini
;	crashing with a vanilla CPU plugin

	IF 1

;	ARG		selector r3, arbitrary args r4...
;	RET		arbitrary

	DeclareMPCall	46, MPCpuPluginThatDoesntTrustThrmRegisters

MPCpuPluginThatDoesntTrustThrmRegisters

	cmpwi	r3, kGetProcessorTemp
	bne		@not_temp_selector

	mfpvr	r8
	rlwinm	r8, r8, 0, 0xffff0000
	lis		r9, 0x8003
	cmpw	r8, r9
	bne		@not_G4e

	li		r3, kCantReportProcessorTemperatureErr ; (MacErrors.a)
	b		CommonMPCallReturnPath

@not_temp_selector
@not_G4e

	;	Arguments in registers
	li		r8, 0

	;	Hopefully returns via kcReturnFromInterrupt? Geez...
	bl		SIGP

	mr		r3, r8
	mr		r4, r9	; r4 not accessible calling MPLibrary func from C

	b		CommonMPCallReturnPath

	ENDIF
