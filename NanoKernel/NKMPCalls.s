;	Important note: If you want more than r3-r5, get them from ECB!!!

;	Unimplemented MPCalls from MPLibrary:
;		NKSetPrInfoPageSize			109
;		NKSetPrInfoILockSizes		110
;		NKSetPrInfoTransCache		111
;		NKSetPrInfoL1Cache			112
;		NKSetPrInfoL2Cache			113



;MPCall_Panic		set		MPCall_Panic



		if		&TYPE('NKDebugShim') != 'UNDEFINED'
MaxMPCallCount		equ		300
		else
MaxMPCallCount		equ		134
		endif



	MACRO
	DeclareMPCall	&n, &code
@h
	org				MPCallTable + 4*&n
	dc.l			&code - NKTop - 4*&n
	org				@h
	ENDM


	;	Creates a blank table without overflowing PPCAsm's default
	;	macro stack size :)

	MACRO
	CreateMPCallTbl	&n

	if			&n >= 1
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 2
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 3
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 4
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 5
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 6
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 7
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 8
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 9
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 10
	dc.l		(MPCallBad - NKTop) - (* - MPCallTable)
	endif

	if			&n >= 11
		CreateMPCallTbl	(&n) - 10
	endif

	ENDM



kcMPDispatch		;	reached by `sc`, or `twi *, *, 8`

	bl		Save_r14_r31

	lwz		r8, EWA.r6(r8)					;	clobbers our EWA pointer :(
	lwz		r14, KDP.PA_NanoKernelCode(r1)	;	but r14...
	lwz		r15, ContextBlock.r0(r6)		;	...and r15 were saved
	stw		r8, ContextBlock.r6(r6)			;	why move r6 from EWA to ContextBlock?
	b		MPCallTableEnd

MPCallTable
	CreateMPCallTbl	MaxMPCallCount
MPCallTableEnd

;	Not sure where this counter table is?

	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.MPDispatchCountTblPtr(r1)
	rlwinm	r17, r15,  2, 20, 29
	cmplwi	r16, 0
	beq-	@no_count
	lwzx	r18, r16, r17
	addi	r18, r18, 1
	stwx	r18, r16, r17
@no_count

	cmplwi	r15, MaxMPCallCount
	rlwimi	r14, r15, 2, 21, 29
	llabel	r16, MPCallTable
	lwzx	r15, r16, r14
	add		r15, r15, r14
	mtlr	r15
	bltlr-



;	Handler for out-of-range or unimplemented (debug)
;	MPCalls.

MPCallBad	;	OUTSIDE REFERER
	li		r3, -4
	b		CommonMPCallReturnPath



;	                     ReleaseAndMPCallWasBad

;	Xrefs:
;	MPCall_75

ReleaseAndMPCallWasBad	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16
	b		MPCallBad



;	            ReleaseAndReturnZeroFromMPCall

;	Xrefs:
;	KCRegisterCpuPlugin
;	KCCreateProcess
;	MPCall_5
;	MPCall_55
;	KCCreateCpuStruct
;	MPCall_43
;	KCStartCPU
;	KCStopScheduling
;	KCRegisterThermalHandler
;	KCRegisterPMFHandler
;	KCMarkPMFTask
;	NKSetClockStep
;	NKSetClockDriftCorrection
;	MPCall_115
;	KCRegisterExternalHandler
;	MPCall_133
;	MPCall_15
;	MPCall_16
;	MPCall_39
;	MPCall_17
;	MPCall_18
;	MPCall_19
;	MPCall_20
;	MPCall_23
;	MPCall_24
;	MPCall_21
;	MPCall_25
;	MPCall_27
;	MPCall_29
;	MPCall_28
;	MPCall_26
;	MPCall_49
;	MPCall_50
;	MPCall_51
;	MPCall_52
;	MPCall_53
;	MPCall_54
;	MPCall_40
;	MPCall_30
;	MPCall_31
;	MPCall_32
;	MPCall_64
;	MPCall_65
;	MPCall_66
;	MPCall_128
;	MPCall_120
;	MPCall_7
;	MPCall_8
;	MPCall_10
;	MPCall_14
;	MPCall_56
;	MPCall_58
;	MPCall_59
;	MPCall_60
;	MPCall_61
;	MPCall_63
;	MPCall_114
;	KCSetTaskType
;	MPCall_71
;	KCSetTaskAddressSpace
;	MPCall_74
;	MPCall_75
;	MPCall_130
;	KCSetAreaAccess
;	MPCall_123
;	MPCall_77
;	MPCall_78
;	MPCall_80
;	MPCall_125
;	MPCall_81
;	MPCall_98
;	MPCall_82
;	KCMapPage
;	KCUnmapPages
;	KCMakePhysicallyContiguous
;	KCLockPages
;	KCUnlockPages
;	KCHoldPages
;	KCUnholdPages
;	MPCall_91
;	MPCall_92
;	MPCall_93
;	MPCall_94
;	MPCall_129
;	MPCall_95

;	> r1    = kdp

ReleaseAndReturnZeroFromMPCall	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16



;	                  ReturnZeroFromMPCall

;	Xrefs:
;	ReleaseAndReturnZeroFromMPCall
;	MPCall_0
;	MPCall_6
;	MPCall_55
;	MPCall_34
;	MPCall_35
;	MPCall_36
;	KCGetNextID
;	KCGetNextIDOwnedByProcess
;	MPCall_38
;	MPCall_62
;	KCStartCPU
;	MPCall_47
;	NKxprintf
;	KCSetBlueProcessID
;	NKLocateInfoRecord
;	MPCall_108
;	NKSetClockDriftCorrection
;	MPCall_41
;	MPCall_79
;	MPCall_83
;	MPCall_102

ReturnZeroFromMPCall	;	OUTSIDE REFERER
	li		r3,  0x00
	b		CommonMPCallReturnPath



;	                     major_0x0af60

;	Xrefs:
;	KCRegisterCpuPlugin
;	KCCreateProcess
;	MPCall_5
;	MPCall_6
;	MPCall_34
;	KCCreateCpuStruct
;	MPCall_43
;	KCStartCPU
;	KCStopScheduling
;	MPCall_115
;	MPCall_15
;	MPCall_39
;	MPCall_17
;	MPCall_18
;	MPCall_19
;	MPCall_20
;	MPCall_23
;	MPCall_24
;	MPCall_25
;	MPCall_27
;	MPCall_29
;	MPCall_28
;	MPCall_49
;	MPCall_52
;	MPCall_53
;	MPCall_40
;	MPCall_31
;	MPCall_64
;	MPCall_7
;	MPCall_8
;	MPCall_9
;	MPCall_10
;	KCThrowException
;	MPCall_58
;	MPCall_60
;	MPCall_61
;	MPCall_114
;	MPCall_70
;	MPCall_71
;	KCSetTaskAddressSpace
;	MPCall_72
;	MPCall_73
;	MPCall_74
;	MPCall_75
;	MPCall_130
;	MPCall_83
;	KCMapPage
;	KCUnmapPages
;	KCMakePhysicallyContiguous
;	KCLockPages
;	KCHoldPages
;	MPCall_91
;	MPCall_92
;	MPCall_94
;	MPCall_95

major_0x0af60	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16



;	I'd really live a name for this.

major_0x0af60_0x20	;	OUTSIDE REFERER
	mfspr	r16, pvr
	rlwinm.	r16, r16,  0,  0, 14

	beq-	@is_601
	mftb	r4
	b		@not_601
@is_601
	mfspr	r4, rtcl
@not_601

	xori	r16, r4,  0x1007
	xoris	r16, r16,  0x1950

	stw		r16, PSA.ScrambledMPCallTime(r1)
	li		r3, -0x726e
	b		CommonMPCallReturnPath




;	dead code?
	li		r3, kMPDeletedErr
	b		CommonMPCallReturnPath



ReleaseAndTimeoutMPCall	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16
	li		r3, kMPTimeOutErr
	b		CommonMPCallReturnPath



ReleaseAndReturnMPCallTaskAborted	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16
	li		r3, kMPTaskAbortedErr
	b		CommonMPCallReturnPath



ReleaseAndReturnMPCallOOM	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16



;	        ReturnMPCallOOM

;	Xrefs:
;	major_0x0af60
;	MPCall_0
;	KCRegisterCpuPlugin
;	MPCall_47
;	NKxprintf
;	KCSetBlueProcessID
;	NKSetClockStep
;	NKSetClockDriftCorrection
;	MPCall_39
;	MPCall_20
;	MPCall_7
;	MPCall_82
;	KCPropogateExternalInterrupt
;	major_0x16b80

ReturnMPCallOOM	;	OUTSIDE REFERER
	li		r3, kMPInsufficientResourcesErr
	b		CommonMPCallReturnPath



;	                     ReleaseAndReturnMPCallBlueBlocking

;	Xrefs:
;	MPCall_18
;	MPCall_23
;	MPCall_27
;	MPCall_52

ReleaseAndReturnMPCallBlueBlocking	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16



;	               ReturnMPCallBlueBlocking

;	Xrefs:
;	ReleaseAndReturnMPCallBlueBlocking
;	MPCall_33

ReturnMPCallBlueBlocking	;	OUTSIDE REFERER
	li		r3, kMPBlueBlockingErr
	b		CommonMPCallReturnPath



;	                     major_0x0b054

;	Xrefs:
;	MPCall_128
;	MPCall_120
;	MPCall_73
;	MPCall_75
;	MPCall_130
;	KCSetAreaAccess
;	MPCall_123
;	MPCall_78
;	MPCall_80
;	MPCall_125
;	MPCall_81
;	MPCall_98
;	KCMapPage
;	KCUnmapPages
;	KCMakePhysicallyContiguous
;	KCLockPages
;	KCUnlockPages
;	KCHoldPages
;	KCUnholdPages
;	MPCall_91
;	MPCall_92
;	MPCall_93
;	MPCall_94
;	MPCall_129

major_0x0b054	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16



;	                ReturnParamErrFromMPCall

;	Xrefs:
;	major_0x0b054
;	KCGetNextIDOwnedByProcess
;	NKLocateInfoRecord
;	MPCall_108
;	NKSetClockStep
;	KCGetPageSize
;	MPCall_95
;	KCPropogateExternalInterrupt
;	major_0x16b80

ReturnParamErrFromMPCall	;	OUTSIDE REFERER
	li		r3, -0x32
	b		CommonMPCallReturnPath



;	                     ReleaseAndReturnMPCallPrivilegedErr

;	Xrefs:
;	KCRegisterCpuPlugin
;	KCCreateProcess
;	MPCall_5
;	MPCall_6
;	MPCall_43
;	KCStartCPU
;	KCStopScheduling
;	KCRegisterThermalHandler
;	KCRegisterPMFHandler
;	KCMarkPMFTask
;	MPCall_115
;	KCRegisterExternalHandler
;	MPCall_16
;	MPCall_39
;	MPCall_17
;	MPCall_18
;	MPCall_19
;	MPCall_23
;	MPCall_24
;	MPCall_22
;	MPCall_21
;	MPCall_27
;	MPCall_29
;	MPCall_28
;	MPCall_26
;	MPCall_50
;	MPCall_51
;	MPCall_52
;	MPCall_53
;	MPCall_54
;	MPCall_41
;	MPCall_30
;	MPCall_31
;	MPCall_32
;	MPCall_65
;	MPCall_67
;	MPCall_66
;	MPCall_128
;	MPCall_7
;	MPCall_8
;	MPCall_9
;	MPCall_10
;	MPCall_14
;	MPCall_56
;	KCThrowException
;	MPCall_58
;	MPCall_59
;	MPCall_60
;	MPCall_61
;	MPCall_63
;	MPCall_114
;	KCSetTaskType
;	MPCall_71
;	KCSetTaskAddressSpace
;	MPCall_72
;	MPCall_73
;	MPCall_74
;	MPCall_75
;	MPCall_130
;	KCSetAreaAccess
;	MPCall_123
;	MPCall_77
;	MPCall_78
;	MPCall_80
;	MPCall_125
;	MPCall_81
;	MPCall_98
;	MPCall_82
;	KCMapPage
;	KCUnmapPages
;	KCMakePhysicallyContiguous
;	KCLockPages
;	KCUnlockPages
;	KCHoldPages
;	KCUnholdPages
;	MPCall_91
;	MPCall_92
;	MPCall_93
;	MPCall_94
;	MPCall_129

ReleaseAndReturnMPCallPrivilegedErr	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16
	li		r3, kMPPrivilegedErr
	b		CommonMPCallReturnPath



ReleaseAndReturnMPCallInvalidIDErr	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16



;	              ReturnMPCallInvalidIDErr

;	Xrefs:
;	ReleaseAndReturnMPCallPrivilegedErr
;	KCRegisterCpuPlugin
;	MPCall_35
;	MPCall_36
;	KCGetNextID
;	KCGetNextIDOwnedByProcess
;	MPCall_38
;	MPCall_62
;	KCCreateCpuStruct
;	KCSetBlueProcessID
;	MPCall_14
;	MPCall_79

ReturnMPCallInvalidIDErr	;	OUTSIDE REFERER
	li		r3, kMPInvalidIDErr
	b		CommonMPCallReturnPath



;	                     major_0x0b0cc

;	Xrefs:
;	KCLockPages
;	KCUnlockPages
;	KCHoldPages
;	KCUnholdPages

major_0x0b0cc	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16
	li		r3, -0x725a
	b		CommonMPCallReturnPath



;	               ReturnZeroFromMPCall_again

;	Xrefs:
;	MPCall_1

ReturnZeroFromMPCall_again	;	OUTSIDE REFERER
	li		r3,  0x00
	b		CommonMPCallReturnPath



;	                     AlternateMPCallReturnPath

;	Xrefs:
;	major_0x02964
;	major_0x02ccc
;	MPCall_55
;	MPCall_18
;	MPCall_23
;	MPCall_22
;	MPCall_27
;	MPCall_52
;	MPCall_67
;	MPCall_9
;	KCThrowException
;	MPCall_58
;	MPCall_60
;	MPCall_61
;	KCSetTaskAddressSpace
;	MPCall_81
;	MPCall_98

AlternateMPCallReturnPath	;	OUTSIDE REFERER
	crclr	cr2_eq
	b		TrulyCommonMPCallReturnPath

ReleaseAndReturnMPCall	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.SchLock, scratch=r16



;	                 CommonMPCallReturnPath

;	Xrefs:
;	MPCallBad
;	ReturnZeroFromMPCall
;	major_0x0af60
;	ReturnMPCallOOM
;	ReturnMPCallBlueBlocking
;	ReturnParamErrFromMPCall
;	ReleaseAndReturnMPCallPrivilegedErr
;	ReturnMPCallInvalidIDErr
;	major_0x0b0cc
;	ReturnZeroFromMPCall_again
;	AlternateMPCallReturnPath
;	KCGetCpuCount
;	MPCall_6
;	KCYieldWithHint
;	KCCpuPlugin
;	NKPrintHex
;	NKPrintDecimal
;	MPCall_11
;	MPCall_12
;	KCGetPageSizeClasses
;	KCGetPageSize
;	MPCall_70
;	KCCurrentAddressSpace
;	KCHomeAddressSpace
;	MPCall_72
;	MPCall_73
;	MPCall_84
;	KCGetFreePageCount
;	KCGetUnheldFreePageCount
;	major_0x16b80

CommonMPCallReturnPath	;	OUTSIDE REFERER
	crset	cr2_eq

TrulyCommonMPCallReturnPath	;	OUTSIDE REFERER
	mfsprg	r8, 0
	lwz		r9,  0x0134(r6)
	stw		r9,  0x0018(r8)

	bne-	cr2, @do_the_other_thing_instead
	bl		Restore_r14_r31
	b		skeleton_key
@do_the_other_thing_instead

	b		major_0x142dc



;	                     MPCall_0

	DeclareMPCall	0, MPCall_0

MPCall_0	;	OUTSIDE REFERER
	andi.	r16, r3,  0xfff
	mr		r30, r7
	mr		r29, r6
	bne+	ReturnMPCallOOM
	rlwinm.	r4, r3, 20, 12, 31
	lwz		r9,  0x06a8(r1)
	beq+	ReturnMPCallOOM
	cmplw	r4, r9
	bge+	ReturnMPCallOOM

	_Lock			PSA.HTABLock, scratch1=r17, scratch2=r18

	bl		VeryPopularFunction
	bge-	cr4, MPCall_0_0xd8
	bgt-	cr5, MPCall_0_0xd8
	bns-	cr7, MPCall_0_0xd8
	bgt-	cr7, MPCall_0_0xd8
	bltl+	cr5, VMDoSomethingWithTLB
	bgel+	cr5, VMSecondLastExportedFunc
	ori		r16, r16,  0x404
	li		r31,  0x03
	rlwimi	r9, r31,  0, 30, 31
	bl		VMDoSomeIO
	mr		r7, r30
	mr		r6, r29
	_AssertAndRelease	PSA.HTABLock, scratch=r16

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	rlwinm	r8, r9,  0,  0, 19
	mr		r9, r3

;	r1 = kdp
;	r8 = anywhere in new page (phys)
;	r9 = page_virt
	bl		ExtendPool
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	b		ReturnZeroFromMPCall

MPCall_0_0xd8
	mr		r7, r30
	mr		r6, r29
	_AssertAndRelease	PSA.HTABLock, scratch=r16
	b		ReturnMPCallOOM



;	                     MPCall_1

	DeclareMPCall	1, MPCall_1

MPCall_1	;	OUTSIDE REFERER
	b		ReturnZeroFromMPCall_again



;	               KCRegisterCpuPlugin


	DeclareMPCall	2, KCRegisterCpuPlugin

KCRegisterCpuPlugin	;	OUTSIDE REFERER
	mfsprg	r14, 0
	lwz		r15, EWA.PA_CurTask(r14)
	lwz		r16, ContextBlock.r6(r6)

	andi.	r8, r4, 0xfff		;	page alignment?
	bne+	ReturnMPCallOOM

	andi.	r8, r5, 0xfff		;	r5 page aligned and nonzero?
	cmpwi	cr1, r5, 0
	bne+	ReturnMPCallOOM
	beq+	cr1, ReturnMPCallOOM

	_Lock			PSA.SchLock, scratch1=r18, scratch2=r19

	mr.		r8, r3
	bne-	KCRegisterCpuPlugin_0x50
	mfsprg	r15, 0
	lwz		r14, -0x0338(r15)
	b		KCRegisterCpuPlugin_0x60

KCRegisterCpuPlugin_0x50
;	r8 = id
 	bl		LookupID
	cmpwi	r9, CoherenceGroup.kIDClass

	mr		r14, r8
	bne+	ReturnMPCallInvalidIDErr

KCRegisterCpuPlugin_0x60
	cmpwi	r16,  0x00
	bne-	KCRegisterCpuPlugin_0x74
	stw		r16,  0x0038(r14)
	stw		r16,  0x0034(r14)
	b		ReleaseAndReturnMPCallInvalidIDErr

KCRegisterCpuPlugin_0x74
	add		r17, r4, r5
	cmplw	r16, r4
	cmplw	cr1, r16, r17
	blt+	ReleaseAndReturnMPCallOOM
	bge+	cr1, ReleaseAndReturnMPCallOOM
	lwz		r19,  0x0038(r14)
	mr.		r19, r19
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r27, r4
	addi	r29, r1, 800
	bl		PagingFunc3
	beq+	ReleaseAndReturnMPCallOOM
	rlwinm	r18, r31,  0,  0, 19
	mr		r27, r16
	mr		r19, r16
	addi	r29, r1, 800
	bl		PagingFunc3
	beq+	ReleaseAndReturnMPCallOOM
	rlwimi	r19, r31,  0,  0, 19
	stw		r4,  0x0028(r14)
	stw		r18,  0x002c(r14)
	stw		r5,  0x0030(r14)
	stw		r16,  0x0034(r14)
	stw		r19,  0x0038(r14)
	lwz		r27,  0x0000(r19)
	addi	r29, r1, 800
	bl		PagingFunc3
	beq+	ReleaseAndReturnMPCallOOM
	rlwimi	r27, r31,  0,  0, 19
	stw		r27,  0x0040(r14)
	mfsprg	r16, 0
	lwz		r17, -0x001c(r16)
	stw		r17,  0x004c(r14)
	addi	r16, r19,  0x20
	stw		r16,  0x003c(r14)
	subi	r16, r16, 4
	lwz		r17,  0x001c(r19)
	cmplwi	r17,  0x40
	stw		r17,  0x0044(r14)
	bgt+	ReleaseAndReturnMPCallOOM

KCRegisterCpuPlugin_0x114
	lwzu	r27,  0x0004(r16)
	addi	r29, r1, 800
	bl		PagingFunc3
	beq+	ReleaseAndReturnMPCallOOM
	addi	r17, r17, -0x01
	rlwimi	r27, r31,  0,  0, 19
	cmpwi	r17,  0x00
	stw		r27,  0x0000(r16)
	bgt+	KCRegisterCpuPlugin_0x114
	_log	'CPU plugin registered^n'

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                   KCGetCpuCount

;	Called by MPProcessors and MPProcessorsScheduled

;	> r3    = 0:all, 1:scheduled

;	< r3    = cpu_count

	DeclareMPCall	3, KCGetCpuCount

KCGetCpuCount	;	OUTSIDE REFERER

	mfsprg	r15, 0
	lwz		r14, EWA.CPUBase + CPU.CgrpList + LLL.Freeform(r15)
	mr.		r8, r3

	lwz		r3, CoherenceGroup.CpuCount(r14)
	beq+	CommonMPCallReturnPath

	lwz		r3, CoherenceGroup.ScheduledCpuCount(r14)
	b		CommonMPCallReturnPath



;	ARG		AddressSpaceID r3
;	RET		AddressSpaceID r3, ??? r4, ProcessStructID r5

	DeclareMPCall	4, KCCreateProcess

KCCreateProcess	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	bne-	@spac_id_supplied
	lwz		r3, PSA.SystemAddressSpaceID(r1)
	mr		r8, r3
@spac_id_supplied

	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	cmpwi	r9, AddressSpace.kIDClass
	mr		r30, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	li		r8, 0x20 ;Process.Size
	bl		PoolAlloc

	mr.		r31, r8
	beq+	major_0x0af60

	li		r9, Process.kIDClass
	bl		MakeID

	cmpwi	r8,  0x00
	bne-	@did_not_fail
	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60
@did_not_fail

	stw		r8, Process.ID(r31)

	lisori	r16, Process.kSignature
	stw		r16, Process.Signature(r31)

	stw		r3, Process.SystemAddressSpaceID(r31)		;	NOT SYSTEM -- fix struct
	stw		r30, Process.SystemAddressSpacePtr(r31)

	lwz		r17, Process.AddressSpaceCount(r31)
	addi	r17, r17, 1
	stw		r17, Process.AddressSpaceCount(r31)

	mr		r5, r8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	5, MPCall_5

MPCall_5	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Process.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16,  0x0008(r31)
	rlwinm.	r17, r16,  0, 30, 30
	bne+	ReleaseAndReturnMPCallOOM
	ori		r16, r16,  0x02
	stw		r16,  0x0008(r31)
	mr		r8, r3

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     MPCall_6

;	Xrefs:
;	kcMPDispatch
;	KCStopScheduling
;	MPCall_9
;	KCThrowException

	DeclareMPCall	6, MPCall_6

MPCall_6	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Process.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16,  0x0008(r31)
	lwz		r17,  0x0010(r31)
	rlwinm.	r8, r16,  0, 30, 30
	cmpwi	cr1, r17,  0x00
	beq+	ReleaseAndReturnMPCallOOM
	bne+	cr1, ReleaseAndReturnMPCallOOM
	mr		r8, r3
	bl		DeleteID
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16
	mr		r8, r31
	bl		PoolFree
	b		ReturnZeroFromMPCall

MPCall_6_0x78	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mfsprg	r16, 0
	rlwinm.	r8, r7,  0, 10, 10
	lwz		r17,  0x0658(r1)
	lwz		r31, -0x0008(r16)
	beq-	MPCall_6_0xb4
	lwz		r8,  0x00cc(r17)
	rlwinm	r8, r8,  0, 24, 21
	oris	r8, r8,  0x8000
	stw		r8,  0x00cc(r17)

MPCall_6_0xb4
	mr		r8, r31
	bl		DequeueTask
	li		r16,  0x02
	stb		r16,  0x0019(r31)
	bl		TaskReadyAsPrev
	mr		r8, r31
	bl		major_0x14af8
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16
	b		CommonMPCallReturnPath



;	                  KCYieldWithHint


	DeclareMPCall	13, KCYieldWithHint

KCYieldWithHint	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mfsprg	r16, 0
	rlwinm.	r8, r7,  0, 10, 10
	lwz		r17,  0x0658(r1)
	lwz		r31, -0x0008(r16)
	beq-	KCYieldWithHint_0x68
	clrlwi.	r8, r3,  0x1f
	lwz		r8,  0x00cc(r17)
	rlwinm	r8, r8,  0, 24, 21
	oris	r8, r8,  0x8000
	stw		r8,  0x00cc(r17)
	beq-	KCYieldWithHint_0x68
	lbz		r16,  0x0019(r31)
	cmpwi	r16,  0x02
	bge-	KCYieldWithHint_0x7c
	mr		r8, r31
	bl		DequeueTask
	li		r16,  0x02
	stb		r16,  0x0019(r31)
	bl		TaskReadyAsNext
	b		KCYieldWithHint_0x7c

KCYieldWithHint_0x68
	mr		r8, r31
	bl		DequeueTask
	li		r16,  0x02
	stb		r16,  0x0019(r31)
	bl		TaskReadyAsPrev

KCYieldWithHint_0x7c
	mr		r8, r31
	bl		major_0x14af8
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16
	b		CommonMPCallReturnPath



	DeclareMPCall	33, MPCall_33

MPCall_33	;	OUTSIDE REFERER
	rlwinm.	r8, r7,  0, 10, 10						;	Contains CpuFlags
	bne+	ReturnMPCallBlueBlocking

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	b		MPCall_55_0x60




;	                     MPCall_55

;	Xrefs:
;	kcMPDispatch
;	MPCall_33

	DeclareMPCall	55, MPCall_55

MPCall_55	;	OUTSIDE REFERER
	rlwinm.	r8, r7,  0, 10, 10
	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.ExternalIntCount(r1)
	beq-	MPCall_55_0x60

	lwz		r17, PSA.OtherSystemContextPtr(r1)
	lwz		r18, KDP.PA_ECB(r1)
	cmpw	r16, r17
	stw		r16, PSA.OtherSystemContextPtr(r1)
	bne+	ReturnZeroFromMPCall

	lwz		r8, ContextBlock.PriorityShifty(r18)
	rlwinm	r8, r8, 0, 24, 21
	oris	r8, r8, 0x8000
	stw		r8, ContextBlock.PriorityShifty(r18)

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	;	if(-0x0410(r1) == -1) {-0x0410(r1) = 0; return 0;}
	lwz		r16, -0x0410(r1)
	cmpwi	r16, -0x01
	li		r16,  0x00
	bne-	MPCall_55_0x60
	stw		r16, -0x0410(r1)
	b		ReleaseAndReturnZeroFromMPCall



MPCall_55_0x60	;	OUTSIDE REFERER
	mfsprg	r16, 0
	li		r17, 1

	lwz		r31, EWA.PA_CurTask(r16)
	addi	r16, r31,  0x20

	stb		r17, Timer.Byte0(r16)

	;	High bit is possibly suspect? Or a flag?
	clrlwi	r3, r3, 1
	stw		r3, Timer.Time(r16)
	stw		r4, Timer.Time+4(r16)

	stw		r31, Timer.ParentTaskPtr(r16)

	mr		r8, r16
	bl		EnqueueTimer

	mr		r8, r31
	bl		DequeueTask

	addi	r16, r1, PSA.DelayQueue
	addi	r17, r31, Timer.QueueLLL
	stw		r16, LLL.Freeform(r17)

	InsertAsPrev	r17, r16, scratch=r18

	li		r3, 0
	b		AlternateMPCallReturnPath



	DeclareMPCall	34, MPCall_34

MPCall_34	;	OUTSIDE REFERER
	mr		r8, r3
	mr		r9, r4

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	beq+	major_0x0af60_0x20
	mr		r5, r8
	b		ReturnZeroFromMPCall



	DeclareMPCall	35, MPCall_35

MPCall_35	;	OUTSIDE REFERER
	mr		r8, r3
	bl		DeleteID
	cmpwi	r8,  0x01
	beq+	ReturnZeroFromMPCall
	b		ReturnMPCallInvalidIDErr



	DeclareMPCall	36, MPCall_36

MPCall_36	;	OUTSIDE REFERER
	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, 0		; invalid

	mr		r4, r9
	mr		r5, r8
	bne+	ReturnZeroFromMPCall
	b		ReturnMPCallInvalidIDErr



;	Replace the provided process/coherence/console ID with
;	the "next" one. IDs were opaque but were only longs.
;	Wrapped by MPGetNext*ID, which indirects the opaque ID
;	structure.
;	From MP docs: A coherence group is the set of processors
;	and other bus controllers that have cache-coherent
;	access to memory. Mac OS 9 defines only one coherence
;	group, which is all the processors that can access
;	internal memory (RAM). Other coherence groups are
;	possible; for example, a PCI card with its own memory
;	and processors can comprise a coherence group.

;	> r3    = kind (process=1,coherence=10,console=13)
;	> r4    = prev_id

;	< r3    = MP result code
;	< r4    = next_id

	DeclareMPCall	37, KCGetNextID

KCGetNextID	;	OUTSIDE REFERER
	mr		r8, r4
	mr		r9, r3
	bl		GetNextIDOfClass
	cmpwi	r8,  0x00
	mr		r4, r8
	bne+	ReturnZeroFromMPCall
	b		ReturnMPCallInvalidIDErr



;	Replace the provided address
;	space/task/queue/semaphore/critical
;	region/timer/event/notification ID with the "next" one.
;	IDs were opaque but were only longs. Wrapped by
;	MPGetNext*ID, which indirects the opaque ID structure.
;	Differs from KCGetNextID because it deals in
;	objects owned by a particular process.

;	Useful info about some poorly understood structures

;	ARG		ProcessID r3, IDClass r4, ID r5
;	RET		MPErr r3, IDClass r4, ID r5

	DeclareMPCall	116, KCGetNextIDOwnedByProcess

KCGetNextIDOwnedByProcess	;	OUTSIDE REFERER

	;	Confirm that owner ID in r3 is a Process

	mr		r8, r3
	bl		LookupID
	cmpwi	r9, Process.kIDClass
	bne+	ReturnMPCallInvalidIDErr


	;	Loop over IDs (and resolve them) until one is owned by the Process

@try_another_id
	mr		r8, r5
	mr		r9, r4

;	ARG		ID r8, IDClass r9
	bl		GetNextIDOfClass
;	RET		ID r8

	mr.		r5, r8
	beq+	ReturnMPCallInvalidIDErr

;	ARG		ID r8
	bl		LookupID
;	RET		Ptr r8, IDClass r9

	cmpwi	r4, 				Task.kIDClass
	cmpwi	cr1, r4,			Timer.kIDClass
	beq-						@task
	beq-	cr1,				@timer

	cmpwi	r4,					Queue.kIDClass
	cmpwi	cr1, r4,			Semaphore.kIDClass
	beq-						@queue
	beq-	cr1,				@semaphore

	cmpwi	r4,					CriticalRegion.kIDClass
	cmpwi	cr1, r4,			AddressSpace.kIDClass
	beq-						@critical_region
	beq-	cr1,				@address_space

	cmpwi	r4,					EventGroup.kIDClass
	cmpwi	cr1, r4,			Area.kIDClass
	beq-						@event_group
	beq-	cr1,				@area

	cmpwi	r4,					Notification.kIDClass
	cmpwi	cr1, r4,			ConsoleLog.kIDClass
	beq-						@notification
	beq-	cr1,				@console_log

	b		ReturnParamErrFromMPCall

@task
	lwz		r17, Task.ThingThatAlignVecHits(r8)
	lwz		r9,  Task.ProcessID(r8)

	rlwinm.	r17, r17,  0, 15, 15
	beq-	@not_owned_by_blue_process
	lwz		r9, PSA.blueProcessPtr(r1)
	lwz		r9, Task.ID(r9)
@not_owned_by_blue_process

	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@timer
	lwz		r9, Timer.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@queue
	lwz		r9, Queue.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@semaphore
	lwz		r9, Semaphore.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@critical_region
	lwz		r9, CriticalRegion.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@address_space
	lwz		r9, AddressSpace.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@event_group
	lwz		r9, EventGroup.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@area
	lwz		r9, Area.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@notification
	lwz		r9, Notification.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall

@console_log
	lwz		r9, ConsoleLog.ProcessID(r8)
	cmpw	r9, r3
	bne+	@try_another_id
	b		ReturnZeroFromMPCall



	DeclareMPCall	38, MPCall_38

MPCall_38	;	OUTSIDE REFERER
	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Process.kIDClass

	bne+	ReturnMPCallInvalidIDErr
	mr		r31, r8

MPCall_38_0x14
	mr		r8, r4
	li		r9,  0x02
	bl		GetNextIDOfClass
	cmpwi	r8,  0x00
	beq+	ReturnMPCallInvalidIDErr
	mr		r4, r8

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	lwz		r17,  0x0064(r8)
	lwz		r16,  0x0060(r8)
	rlwinm.	r17, r17,  0, 15, 15
	beq-	MPCall_38_0x48
	lwz		r16, -0x041c(r1)
	lwz		r16,  0x0000(r16)

MPCall_38_0x48
	cmpw	r16, r3
	beq+	ReturnZeroFromMPCall
	b		MPCall_38_0x14



	DeclareMPCall	62, MPCall_62

MPCall_62	;	OUTSIDE REFERER
	mr.		r8, r3
	bne-	MPCall_62_0x18
	mfsprg	r15, 0
	lwz		r31, -0x0338(r15)
	lwz		r3,  0x0000(r31)
	b		MPCall_62_0x24

MPCall_62_0x18
;	r8 = id
 	bl		LookupID
	cmpwi	r9, CoherenceGroup.kIDClass

	bne+	ReturnMPCallInvalidIDErr

MPCall_62_0x24
	mr		r8, r4
	li		r9,  0x07
	bl		GetNextIDOfClass
	cmpwi	r8,  0x00
	beq+	ReturnMPCallInvalidIDErr
	mr		r4, r8

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	lwz		r16,  0x0008(r8)
	lwz		r17,  0x0000(r16)
	cmpw	r17, r3
	bne+	MPCall_62_0x24
	b		ReturnZeroFromMPCall



	DeclareMPCall	42, KCCreateCpuStruct

KCCreateCpuStruct	;	OUTSIDE REFERER
	mr.		r8, r3
	bne-	KCCreateCpuStruct_0x14
	mfsprg	r15, 0
	lwz		r30, EWA.CPUBase + CPU.CgrpList + LLL.Freeform(r15)
	b		KCCreateCpuStruct_0x24

KCCreateCpuStruct_0x14
;	r8 = id
 	bl		LookupID
	cmpwi	r9, CoherenceGroup.kIDClass

	mr		r30, r8
	bne+	ReturnMPCallInvalidIDErr

KCCreateCpuStruct_0x24
	li		r8, 960

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	mr.		r31, r8
	beq+	major_0x0af60_0x20

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r9,  0x07

;	r1 = kdp
;	r9 = kind
	bl		MakeID
	cmpwi	r8,  0x00
	bne+	KCCreateCpuStruct_0x68
	mr		r8, r31
	bl		PoolFree
	b		major_0x0af60
KCCreateCpuStruct_0x68


	stw		r8, CPU.ID(r31)

	lisori	r16, CPU.kSignature

	stw		r8, ContextBlock.r6(r6)		; return ID in r6

	stw		r16, CPU.Signature(r31)

	lwz		r17,  0x0020(r30)
	addi	r17, r17,  0x01
	stw		r17,  0x0020(r30)
	addi	r16, r31,  0x08
	stw		r30,  0x0000(r16)
	stw		r30,  0x0008(r16)
	lwz		r17,  0x000c(r30)
	stw		r17,  0x000c(r16)
	stw		r16,  0x0008(r17)
	stw		r16,  0x000c(r30)

	lisori	r8, 11
	lisori	r8, 6
	stw		r8, CPU.Eff(r31)




	addi	r30, r31, CPU.EWABase


	addi	r8, r1, PSA.Base
	stw		r8, EWA.PA_PSA - EWA.Base(r30)

	stw		r1, EWA.PA_KDP - EWA.Base(r30)

	li		r8, 0
	stw		r8, EWA.PA_CurTask - EWA.Base(r30)


	;	Matches code in Init.s quite closely

	li		r8, -0x01
	sth		r4, 0x020a(r30)
	stb		r8, 0x0209(r30)		; interesting...

	lwz		r8, EWA.PA_IRP(r1)
	stw		r8, EWA.PA_IRP - EWA.Base(r30)

	lisori	r8, 'time'
	stw		r8, EWA.TimeList - EWA.Base + LLL.Signature(r30)

	li		r8, 0x04
	stb		r8, 0x0014(r30)

	li		r8, 0x01
	stb		r8, 0x0016(r30)

	li		r8, 0x00
	stb		r8, 0x0017(r30)

	lisori	r8, 0x7fffffff
	stw		r8, 0x0038(r30)

	oris	r8, r8, 0xffff
	stw		r8, 0x003c(r30)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	43, MPCall_43

MPCall_43	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CPU.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  0x0018(r31)
	lis		r17,  0x00
	ori		r17, r17,  0x09
	and.	r17, r17, r16
	bne+	ReleaseAndReturnMPCallOOM
	mfsprg	r15, 0
	li		r16,  0x04
	stw		r16, -0x0238(r15)
	lhz		r16,  0x022a(r31)
	stw		r16, -0x0234(r15)
	li		r8,  0x02

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	lwz		r17,  0x0008(r31)
	addi	r16, r31,  0x08
	lwz		r18,  0x0020(r17)
	addi	r18, r18, -0x01
	stw		r18,  0x0020(r17)
	lwz		r17,  0x0008(r16)
	lwz		r18,  0x000c(r16)
	stw		r17,  0x0008(r18)
	stw		r18,  0x000c(r17)
	li		r17,  0x00
	stw		r17,  0x0008(r16)
	stw		r17,  0x000c(r16)
	mr		r8, r31
	bl		PoolFree
	mr		r8, r3
	bl		DeleteID

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	44, KCStartCPU

;	ARG		CpuID r3

KCStartCPU	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
	bl		LookupID
	cmpwi	r9, CPU.kIDClass
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	mr		r30, r8
	lwz		r16, CPU.Eff(r30)
	rlwinm.	r8, r16,  0, 28, 28
	bne+	ReleaseAndReturnZeroFromMPCall

	mfsprg	r15, 0
	li		r16,  0x04
	stw		r16, -0x0238(r15)
	lhz		r16,  0x022a(r30)
	stw		r16, -0x0234(r15)


;	Put the boots in?

	_log	'SIGP kResetProcessor^n'
	li		r8, 2
	bl		SIGP
	cmpwi	r8, -0x7264
	cmpwi	cr1, r8, 0
	beq+	ReleaseAndReturnMPCallOOM
	bne+	cr1, ReleaseAndReturnMPCallOOM


;	Every CPU gets an idle task

	_log	'Creating idle task^n'
	mr		r31, r7
	rlwinm	r7, r7, 0, 13, 11
	lwz		r8, PSA.blueProcessPtr(r1)

;	ARG		EmpiricalCpuFeatures r7, Process *r8
	bl		CreateTask
;	RET		Task *r8

	mr		r7, r31
	mr.		r31, r8
	beq+	major_0x0af60

	stw		r31, CPU.IdleTaskPtr(r30)

	lisori	r8, 'idle'
	stw		r8, Task.Name(r31)

	lisori	r8, 0x00080040			;	clearly flags
	stw		r8, Task.ThingThatAlignVecHits(r31)

	li		r8, 1
	stw		r8, Task.Weight(r31)

	li		r8, Task.kIdlePriority
	stb		r8, Task.Priority(r31)

	;	whoa -- cpu structs arent this big?
	lhz		r8,  0x022a(r30)
	sth		r8, Task.MysteryHalf(r31)

	lwz		r8, Task.ContextBlock + ContextBlock.EmpiricalCpuFeatures(r31)
	_bset	r8, r8, 9
	stw		r8, Task.ContextBlock + ContextBlock.EmpiricalCpuFeatures(r31)


	lwz		r8, KDP.PA_NanoKernelCode(r1)
	llabel	r26, IdleCode
	add		r8, r8, r26
	stw		r8, Task.ContextBlock + ContextBlock.CodePtr(r31)

	;	better compare this with init code idle task
	lwz		r8, Task.ContextBlock + ContextBlock.MSR(r31)
	andi.	r8, r8,  0xbfcf
	stw		r8, Task.ContextBlock + ContextBlock.MSR(r31)


	_AssertAndRelease	PSA.SchLock, scratch=r16


	;	Some EWA/KDP stuff I do not understand
	mfsprg	r15, 0
	li		r16,  0x08
	stw		r16, -0x0238(r15)
	lhz		r16,  0x022a(r30)
	stw		r16, -0x0234(r15)

MPCall_44_0x15c
	_log	'SIGP kSynchClock^n'
	li		r8,  0x02

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	cmpwi	r8, -0x7264
	cmpwi	cr1, r8,  0x00
	beq+	MPCall_44_0x15c


	bne-	cr1, MPCall_Panic
	mfsprg	r15, 0
	li		r16,  0x01
	stw		r16, -0x0238(r15)
	lhz		r16,  0x022a(r30)
	stw		r16, -0x0234(r15)
	lwz		r16,  0x064c(r1)
	llabel	r17, major_0x14bcc
	add		r16, r16, r17
	stw		r16, -0x0230(r15)
	stw		r30, -0x022c(r15)

MPCall_44_0x1c0
	_log	'SIGP kStartProcessor^n'
	li		r8,  0x04

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	cmpwi	r8, -0x7264
	cmpwi	cr1, r8,  0x00
	beq+	MPCall_44_0x1c0
	bne-	cr1, MPCall_Panic
	_log	'Processor scheduled^n'
	b		ReturnZeroFromMPCall



;	                    KCStopScheduling


	DeclareMPCall	45, KCStopScheduling

KCStopScheduling	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, CPU.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r30, r8
	lwz		r16,  0x0018(r30)
	rlwinm.	r8, r16,  0, 28, 28

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	lwz		r31,  0x001c(r30)
	clrlwi.	r8, r16,  0x1f
	bne+	ReleaseAndReturnMPCallOOM
	lbz		r17,  0x0019(r31)
	cmpwi	r17,  0x00
	beq-	KCStopScheduling_0x94
	lwz		r17,  0x0064(r31)
	oris	r17, r17,  0x80
	stw		r17,  0x0064(r31)
	mr		r8, r31
	bl		DequeueTask
	li		r17,  0x00
	stb		r17,  0x0019(r31)
	mr		r8, r31
	bl		TaskReadyAsNext
	bl		CalculateTimeslice
	mr		r8, r31
	bl		major_0x14af8_0xa0
	lwz		r8,  0x064c(r1)
	llabel	r9, StopProcessor
	add		r8, r8, r9
	stw		r8,  0x01fc(r31)

KCStopScheduling_0x94
	_AssertAndRelease	PSA.SchLock + Lock.Count, scratch=r16
	b		MPCall_6_0x78



;	                      KCCpuPlugin


	DeclareMPCall	46, KCCpuPlugin

KCCpuPlugin	;	OUTSIDE REFERER
	li		r8,  0x00

;	r7 = flags
;	r8 = usually 2?
	bl		SIGP
	mr		r3, r8
	mr		r4, r9
	b		CommonMPCallReturnPath



	DeclareMPCall	47, MPCall_47

MPCall_47	;	OUTSIDE REFERER
	rlwinm.	r8, r7,  0, 12, 12
	lwz		r15,  0x00d8(r6)
	beq+	ReturnMPCallOOM
	cmpwi	r15,  0x00
	mr		r16, r2
	beq+	ReturnMPCallOOM
	mr		r17, r3
	mr		r18, r4
	mr		r19, r5
	bl		Save_v0_v31
	mr		r2, r16
	mr		r3, r17
	mr		r4, r18
	mr		r5, r19
	b		ReturnZeroFromMPCall



;	                      MPCall_48_Bad


	DeclareMPCall	48, MPCall_48_Bad

MPCall_48_Bad	;	OUTSIDE REFERER
	b		MPCallBad



;	                       NKxprintf


	DeclareMPCall	96, NKxprintf

NKxprintf	;	OUTSIDE REFERER
	rlwinm.	r9, r11,  0, 27, 27
	mr		r8, r3
	beq-	NKxprintf_0x1c
	li		r9,  0x00
	bl		V2P
	beq-	NKxprintf_0x24
	rlwimi	r8, r17,  0,  0, 19

NKxprintf_0x1c
	bl		PrintS
	b		ReturnZeroFromMPCall

NKxprintf_0x24
	_log	'NKxprintf (V->P translation error)^n'
	b		ReturnMPCallOOM



;	ARG		long r3, int r4 size (1:byte, 2:half, else:word)

	DeclareMPCall	97, NKPrintHex

NKPrintHex
	mr		r8, r3

	cmpwi	r4, 1
	cmpwi	cr1, r4, 2

	beq-	@byte
	beq-	cr1, @half


	bl		Printw
	b		CommonMPCallReturnPath

@half
	bl		Printh
	b		CommonMPCallReturnPath

@byte
	bl		Printb
	b		CommonMPCallReturnPath



	DeclareMPCall	124, NKPrintDecimal

NKPrintDecimal	;	OUTSIDE REFERER
	mr		r8, r3
	bl		Printd
	b		CommonMPCallReturnPath



;	                   KCSetBlueProcessID


	DeclareMPCall	99, KCSetBlueProcessID

KCSetBlueProcessID	;	OUTSIDE REFERER
	mfsprg	r16, 0
	rlwinm.	r8, r7,  0, 10, 10
	lwz		r31, EWA.PA_CurTask(r16)
	beq+	ReturnMPCallOOM
	mr		r8, r3

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	cmpwi	r9, Process.kIDClass
	bne+	ReturnMPCallInvalidIDErr
	stw		r3, Task.ProcessID(r31)
	stw		r4, 0x00ec(r31)
	b		ReturnZeroFromMPCall



;	                KCRegisterThermalHandler


	DeclareMPCall	104, KCRegisterThermalHandler

KCRegisterThermalHandler	;	OUTSIDE REFERER

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	mr.			r8, r3
	beq-		@is_zero
	bl			LookupID
	cmpwi		r9, Notification.kIDClass
	bne+		ReleaseAndReturnMPCallInvalidIDErr
@is_zero

	stw			r3, PSA.ThermalHandlerID(r1)

	b			ReleaseAndReturnZeroFromMPCall



;	                  KCRegisterPMFHandler


	DeclareMPCall	105, KCRegisterPMFHandler

KCRegisterPMFHandler	;	OUTSIDE REFERER

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	mr.			r8, r3
	beq-		@is_zero
	bl			LookupID
	cmpwi		r9, Notification.kIDClass
	bne+		ReleaseAndReturnMPCallInvalidIDErr
@is_zero

	stw			r3, PSA.PMFHandlerID(r1)

	b			ReleaseAndReturnZeroFromMPCall



;	                     KCMarkPMFTask


	DeclareMPCall	106, KCMarkPMFTask

KCMarkPMFTask	;	OUTSIDE REFERER

	_Lock		PSA.SchLock, scratch1=r16, scratch2=r17

	mfsprg		r30, 0
	mr.			r8, r3
	lwz			r31, EWA.PA_CurTask(r30)

	beq-		@use_blue_task_instead
	bl			LookupID
	cmpwi		r9, Task.kIDClass
	mr			r31, r8
	bne+		ReleaseAndReturnMPCallInvalidIDErr
@use_blue_task_instead

;	Insert bit 31 of r4 into bit 21 of these flags
	lwz			r17, Task.ThingThatAlignVecHits(r31)
	rlwimi		r17, r4, 10, 21, 21
	stw			r17, Task.ThingThatAlignVecHits(r31)


;	Don't know what this does!
	mr			r8, r31
	bl			major_0x14af8_0xa0

	b			ReleaseAndReturnZeroFromMPCall



;	ARG		int r6:
;				2:	SystemInfo
;				3:	DiagInfo
;				4:	NanoKernelInfo
;				5:	ProcessorInfo
;				6:	HWInfo
;				7:	ProcessorState

;	RET		Ptr r4, short r5 ver, short r6 len

	DeclareMPCall	107, NKLocateInfoRecord

NKLocateInfoRecord

	cmpwi	r3, 5
	cmpwi	cr1, r3, 2
	beq-	@ProcessorInfo
	beq-	cr1, @SystemInfo

	cmpwi	r3, 3
	cmpwi	cr1, r3, 4
	beq-	@DiagInfo
	beq-	cr1, @NanoKernelInfo

	cmpwi	r3, 7
	cmpwi	cr1, r3, 6
	beq-	@ProcessorState
	bne+	cr1, ReturnParamErrFromMPCall

	lwz		r4, KDP.InfoRecord + InfoRecord.NKHWInfoPtr(r1)
	lhz		r16, KDP.InfoRecord + InfoRecord.NKHWInfoLen(r1)
	lhz		r5,  KDP.InfoRecord + InfoRecord.NKHWInfoVer(r1)
	stw		r16, ContextBlock.r6(r6)
	b		ReturnZeroFromMPCall

@ProcessorState
	lwz		r4, KDP.InfoRecord + InfoRecord.NKProcessorStatePtr(r1)
	lhz		r16, KDP.InfoRecord + InfoRecord.NKProcessorStateLen(r1)
	lhz		r5, KDP.InfoRecord + InfoRecord.NKProcessorStateVer(r1)
	stw		r16, ContextBlock.r6(r6)
	b		ReturnZeroFromMPCall

@ProcessorInfo
	lwz		r4, KDP.InfoRecord + InfoRecord.NKProcessorInfoPtr(r1)
	lhz		r16, KDP.InfoRecord + InfoRecord.NKProcessorInfoLen(r1)
	lhz		r5, KDP.InfoRecord + InfoRecord.NKProcessorInfoVer(r1)
	stw		r16, ContextBlock.r6(r6)
	b		ReturnZeroFromMPCall

@NanoKernelInfo
	lwz		r4, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoPtr(r1)
	lhz		r16, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoLen(r1)
	lhz		r5, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoVer(r1)
	stw		r16, ContextBlock.r6(r6)
	b		ReturnZeroFromMPCall

@DiagInfo
	lwz		r4, KDP.InfoRecord + InfoRecord.NKDiagInfoPtr(r1)
	lhz		r16, KDP.InfoRecord + InfoRecord.NKDiagInfoLen(r1)
	lhz		r5, KDP.InfoRecord + InfoRecord.NKDiagInfoVer(r1)
	stw		r16, ContextBlock.r6(r6)
	b		ReturnZeroFromMPCall

@SystemInfo
	lwz		r4, KDP.InfoRecord + InfoRecord.NKSystemInfoPtr(r1)
	lhz		r16, KDP.InfoRecord + InfoRecord.NKSystemInfoLen(r1)
	lhz		r5, KDP.InfoRecord + InfoRecord.NKSystemInfoVer(r1)
	stw		r16, ContextBlock.r6(r6)
	b		ReturnZeroFromMPCall



	DeclareMPCall	108, MPCall_108

MPCall_108	;	OUTSIDE REFERER
	cmplwi	r3,  0x02
	bge+	ReturnParamErrFromMPCall
	mulli	r17, r3,  0x10
	addi	r18, r1,  0xf80
	add		r18, r17, r18
	lwz		r16,  0x0134(r6)
	stw		r4,  0x0000(r18)
	stw		r5,  0x0004(r18)
	stw		r16,  0x0008(r18)
	_log	'Clock rates for step '
	mr		r8, r3
	bl		Printd
	_log	'- Cpu '
	mr		r8, r4
	bl		Printd
	_log	'- Bus '
	mr		r8, r5
	bl		Printd
	_log	'- Dec '
	mr		r8, r16
	bl		Printd
	_log	'Hz^n'
	b		ReturnZeroFromMPCall



;	                     NKSetClockStep

;	Debug string matches MPLibrary!
;	0xf7e(r1) = clock_step (half-word)

;	> r3    = new_clock_step  # (half-word)

	DeclareMPCall	131, NKSetClockStep

NKSetClockStep	;	OUTSIDE REFERER
	mfsprg	r9, 0
	lwz		r8, -0x0338(r9)
	lwz		r9,  0x0024(r8)
	cmpwi	r9,  0x01
	bgt+	ReturnMPCallOOM
	lhz		r19,  0x0f7e(r1)
	_log	'NKSetClockStep - current '
	mr		r8, r19
	bl		Printd
	_log	' new '
	mr		r8, r3
	bl		Printd
	_log	'^n'
	cmplwi	r3,  0x02
	cmpw	cr1, r3, r19
	bge+	ReturnParamErrFromMPCall
	beq+	cr1, ReturnMPCallOOM
	mulli	r17, r3,  0x10
	addi	r18, r1,  0xf80
	sth		r17,  0x0f7e(r1)
	add		r18, r17, r18
	lwz		r16,  0x0000(r18)
	lwz		r17,  0x0004(r18)
	stw		r16,  0x0f24(r1)
	stw		r17,  0x0f28(r1)
	lwz		r16,  0x0f88(r1)
	stw		r16,  0x0f2c(r1)

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	lwz		r16,  0x0008(r18)
	stw		r16, -0x0438(r1)
	bgt-	cr1, NKSetClockStep_0xec
	lwz		r31, -0x0434(r1)
	lbz		r18,  0x0017(r31)
	cmpwi	r18,  0x00

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	mr		r8, r31
	bl		major_0x136c8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

NKSetClockStep_0xec
	lwz		r31, -0x0434(r1)
	lbz		r18,  0x0017(r31)
	cmpwi	r18,  0x01

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	bl		GetTime
	stw		r8,  0x0038(r31)
	stw		r9,  0x003c(r31)
	mr		r8, r31
	bl		EnqueueTimer

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	               NKSetClockDriftCorrection

;	There's a one-billion constant in here, for fractional
;	expression.
;	-0x36c(r1) = tb_drift_numerator
;	-0x368(r1) = tb_drift_denominator

;	> r3    = to

	DeclareMPCall	132, NKSetClockDriftCorrection

NKSetClockDriftCorrection	;	OUTSIDE REFERER
	lwz		r31, -0x0364(r1)
	mfsprg	r9, 0
	cmpwi	r31,  0x00
	beq+	ReturnMPCallOOM
	lwz		r8, -0x0338(r9)
	lwz		r9,  0x0024(r8)
	cmpwi	r9,  0x01
	bgt+	ReturnMPCallOOM
	lwz		r19,  0x0fa0(r1)
	cmpwi	r3,  0x00
	cmpw	cr1, r3, r19
	stw		r3,  0x0fa0(r1)
	beq-	NKSetClockDriftCorrection_0x12c
	beq+	cr1, ReturnZeroFromMPCall
	lis		r16,  0x3b9a
	ori		r16, r16,  0xca00
	lwz		r17,  0x0f88(r1)
	srwi	r17, r17,  7
	divw	r18, r16, r3
	cmpw	r18, r17
	bge-	NKSetClockDriftCorrection_0x64
	divw	r16, r16, r17
	mr		r18, r17
	divw	r17, r3, r16
	b		NKSetClockDriftCorrection_0x6c

NKSetClockDriftCorrection_0x64
	rlwinm	r17, r3,  2, 30, 30
	addi	r17, r17,  0x01

NKSetClockDriftCorrection_0x6c
	stw		r17, -0x036c(r1)
	stw		r18, -0x0368(r1)
	_log	'TB drift adjusted to '
	mr		r8, r3
	bl		Printd
	_log	' ppb ( '
	mr		r8, r17
	bl		Printd
	_log	'/ '
	mr		r8, r18
	bl		Printd
	_log	')^n'

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	lwz		r31, -0x0364(r1)
	lbz		r18,  0x0017(r31)
	cmpwi	r18,  0x01

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	bl		GetTime
	stw		r8,  0x0038(r31)
	stw		r9,  0x003c(r31)
	mr		r8, r31
	bl		EnqueueTimer

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

NKSetClockDriftCorrection_0x12c

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r17,  0x00
	stw		r17, -0x036c(r1)
	stw		r17, -0x0368(r1)
	lwz		r31, -0x0364(r1)
	lbz		r18,  0x0017(r31)
	cmpwi	r18,  0x00

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	mr		r8, r31
	bl		major_0x136c8

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	115, MPCall_115

MPCall_115	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, ConsoleLog.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r30,  0x000c(r31)
	cmpwi	r30,  0x00
	bne-	MPCall_115_0x94

	_Lock			PSA.DbugLock, scratch1=r16, scratch2=r17

	lwz		r30, -0x0404(r1)

MPCall_115_0x54
	addi	r30, r30,  0x01
	andi.	r29, r30,  0xfff
	bne-	MPCall_115_0x64
	lwz		r30, -0x1000(r30)

MPCall_115_0x64
	lbz		r16,  0x0000(r30)
	cmpwi	r16,  0x00
	beq+	MPCall_115_0x54
	stw		r30,  0x000c(r31)
	_AssertAndRelease	PSA.DbugLock, scratch=r16

MPCall_115_0x94
	cmpwi	r5,  0x00
	ble+	ReleaseAndReturnMPCallOOM
	rlwinm.	r9, r11,  0, 27, 27
	mr		r8, r4
	crmove	30, 2
	beq-	MPCall_115_0xd0
	li		r9,  0x00
	bl		MPCall_95_0x45c
	beq+	ReleaseAndReturnMPCallOOM
	add		r8, r4, r5
	li		r9,  0x00
	addi	r8, r8, -0x01
	mr		r30, r8
	bl		MPCall_95_0x45c
	beq+	ReleaseAndReturnMPCallOOM

MPCall_115_0xd0
	lwz		r28, -0x0404(r1)
	lwz		r29,  0x000c(r31)
	li		r5,  0x00
	not		r27, r4

MPCall_115_0xe0
	cmpw	r28, r29
	cmplw	cr1, r4, r30
	beq-	MPCall_115_0x144
	bgt-	cr1, MPCall_115_0x144
	rlwinm	r16, r4,  0,  0, 19
	mr		r8, r4
	beq-	cr7, MPCall_115_0x11c
	cmpw	r16, r27
	mr		r17, r26
	beq-	MPCall_115_0x11c
	mr		r27, r16
	li		r9,  0x00
	bl		MPCall_95_0x45c
	beq+	ReleaseAndReturnMPCallOOM
	mr		r26, r17

MPCall_115_0x11c
	rlwimi	r17, r4,  0, 20, 31
	lbz		r8,  0x0000(r29)
	addi	r29, r29,  0x01
	andi.	r16, r29,  0xfff
	bne+	MPCall_115_0x134
	lwz		r29, -0x1000(r29)

MPCall_115_0x134
	stb		r8,  0x0000(r17)
	addi	r5, r5,  0x01
	addi	r4, r4,  0x01
	b		MPCall_115_0xe0

MPCall_115_0x144
	stw		r29,  0x000c(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	               KCRegisterExternalHandler

;	Point external interrupts (thing PIHes) towards this notification


	DeclareMPCall	121, KCRegisterExternalHandler

KCRegisterExternalHandler

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.				r8, r3
	beq-			@zero
	bl				LookupID
	cmpwi			r9, Notification.kIDClass
	bne+			ReleaseAndReturnMPCallInvalidIDErr
@zero

	stw				r3, PSA.ExternalHandlerID(r1)

	b				ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	133, MPCall_133

MPCall_133	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	cmpw	r3, r0
	lwz		r16,  0x0edc(r1)
	li		r17,  0x0b
	blt-	MPCall_133_0x34
	and		r3, r3, r17
	or		r16, r16, r3
	b		MPCall_133_0x3c

MPCall_133_0x34
	orc		r3, r3, r17
	and		r16, r16, r3

MPCall_133_0x3c
	stw		r16,  0x0edc(r1)
	srawi	r16, r4, 16
	extsh	r17, r4
	cmpwi	r16, -0x01
	cmpwi	cr1, r17, -0x01
	beq-	MPCall_133_0x60
	bgt-	MPCall_133_0x5c
	li		r16,  0x00

MPCall_133_0x5c
	sth		r16, -0x0360(r1)

MPCall_133_0x60
	beq-	cr1, MPCall_133_0x70
	bgt-	cr1, MPCall_133_0x6c
	li		r17,  0x00

MPCall_133_0x6c
	sth		r17, -0x035e(r1)

MPCall_133_0x70
	srawi	r16, r5, 16
	extsh	r17, r5
	cmpwi	r16, -0x01
	cmpwi	cr1, r17, -0x01
	beq-	MPCall_133_0x90
	bgt-	MPCall_133_0x8c
	li		r16,  0x00

MPCall_133_0x8c
	sth		r16, -0x035c(r1)

MPCall_133_0x90
	beq-	cr1, MPCall_133_0xa0
	bgt-	cr1, MPCall_133_0x9c
	li		r17,  0x00

MPCall_133_0x9c
	sth		r17, -0x035a(r1)

MPCall_133_0xa0
;	r1 = kdp
	bl		ScreenConsole_redraw

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                 MPCall_Panic

;	Xrefs:
;	KCStartCPU

MPCall_Panic
	b		panic
