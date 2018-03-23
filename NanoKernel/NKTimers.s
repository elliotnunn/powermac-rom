Local_Panic		set		*
				b		panic



;	                       InitTMRQs

;	Xrefs:
;	setup

InitTMRQs	;	OUTSIDE REFERER
	addi	r9, r1, -0xa84
	lis		r8,  0x544d
	ori		r8, r8,  0x5251
	stw		r8,  0x0004(r9)
	stw		r9,  0x0008(r9)
	stw		r9,  0x000c(r9)
	li		r8,  0x00
	stb		r8,  0x0014(r9)
	li		r8,  0x01
	stb		r8,  0x0016(r9)
	stb		r8,  0x0017(r9)
	lis		r8,  0x7fff
	ori		r8, r8,  0xffff
	mtspr	dec, r8
	stw		r8,  0x0038(r9)
	oris	r8, r8,  0xffff
	stw		r8,  0x003c(r9)
	mfspr	r8, pvr
	rlwinm.	r8, r8,  0,  0, 14
	beq-	InitTMRQs_0x7c
	mflr	r30
	li		r8,  0x40

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	mr.		r31, r8
	beq+	Local_Panic
	stw		r31, -0x0434(r1)
	li		r9,  0x07
	stb		r9,  0x0014(r31)
	li		r9,  0x01
	stb		r9,  0x0016(r31)
	mtlr	r30

InitTMRQs_0x7c
	mfspr	r8, pvr
	rlwinm.	r8, r8,  0,  0, 14
	beq-	InitTMRQs_0xb4
	mflr	r30
	li		r8,  0x40

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	mr.		r31, r8
	beq+	Local_Panic
	stw		r31, -0x0364(r1)
	li		r9,  0x08
	stb		r9,  0x0014(r31)
	li		r9,  0x01
	stb		r9,  0x0016(r31)
	mtlr	r30

InitTMRQs_0xb4


;	Activate the NanoDebugger (whatever that is...)

	lwz		r30, KDP.PA_ConfigInfo(r1)
	lhz		r31, NKConfigurationInfo.Debug(r30)
	cmplwi	r31, NKConfigurationInfo.DebugThreshold
	blt-	@nodebug

	lwz		r31, NKConfigurationInfo.DebugFlags(r30)
	rlwinm.	r8, r31, 0, NKConfigurationInfo.NanodbgrFlagBit, NKConfigurationInfo.NanodbgrFlagBit
	beq-	@nodebug

	lwz		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)
	_bset	r8, r8, NKNanoKernelInfo.NanodbgrFlagBit
	stw		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.ConfigFlags(r1)

	mflr	r30

	li		r8, Timer.Size
	bl		PoolAllocClear					;	one of those weird queue structures
	mr.		r31, r8
	beq+	Local_Panic

	li		r9, Timer.kKind6
	stb		r9, Timer.Kind(r31)

	li		r9, 1
	stb		r9, Timer.KeepAfterFiring(r31)

	bl		GetTime
	stw		r8, Timer.Time(r31)
	stw		r9, Timer.Time+4(r31)

	mr		r8, r31
	bl		EnqueueTimer

	_log	'Nanodebugger activated.^n'

	mtlr	r30
@nodebug
	blr



;	                     TimerDispatch

;	Xrefs:
;	IntDecrementer
;	TimerFire0

TimerTable

	dc.l	TimerFireUnknownKind - NKTop	; Timer.kKind0
	dc.l	TimerFire1 - NKTop				; Timer.kKind1
	dc.l	TimerFire2 - NKTop				; Timer.kKind2
	dc.l	TimerFire3 - NKTop				; Timer.kKind3
	dc.l	TimerFire4 - NKTop				; Timer.kKind4
	dc.l	TimerFire5 - NKTop				; Timer.kKind5
	dc.l	TimerFire6 - NKTop				; Timer.kKind6
	dc.l	TimerFire7 - NKTop				; Timer.kKind7
	dc.l	TimerFire8 - NKTop				; Timer.kKind8

TimerDispatch	;	OUTSIDE REFERER
	mflr	r19
	mfsprg	r18, 0
	stw		r19, EWA.TimerDispatchLR(r18)

TimerDispatch_0x30	;	OUTSIDE REFERER
	mfspr	r8, pvr
	rlwinm.	r8, r8,  0,  0, 14
	beq-	@is_601

;not 601
@gettime_loop_non_601
	mftbu	r8
	mftb	r9
	mftbu	r16
	cmpw	r8, r16
	bne-	@gettime_loop_non_601
	b		@common

@is_601
@gettime_loop_601
	mfspr	r8, rtcu
	mfspr	r9, rtcl
	mfspr	r16, rtcu
	cmpw	r8, r16
	bne-	@gettime_loop_601

	dialect	POWER

	liu		r16, 1000000000 >> 16
	oril	r16, r16, 1000000000 & 0xffff

	mfmq	r17
	mul		r8, r16, r8
	mfmq	r16
	mtmq	r17
	
	mfxer	r17
	a		r9, r16, r9
	aze		r8, r8
	mtxer	r17

	dialect	PowerPC
@common



	lbz		r19, EWA.GlobalTimeIsValid(r18)
	addi	r30, r18, EWA.Base
	cmpwi	r19, 1
	lwz		r16, EWA.GlobalTime - EWA.Base(r30)
	bne-	timer_earlier_than_sometime
	lwz		r17, EWA.GlobalTime + 4 - EWA.Base(r30)

	_b_if_time_gt	r16, r8, timer_earlier_than_sometime
@skipbranch
	li		r19,  0x00
	stw		r30, -0x0254(r18)
	stb		r19,  0x0017(r30)
	b		TimerFire4_0x10

timer_earlier_than_sometime
	lwz		r30, -0x0a7c(r1)
	lwz		r16,  0x0038(r30)
	lwz		r17,  0x003c(r30)

	_b_if_time_gt	r16, r8, TimerDispatch_0x188

	RemoveFromList		r30, scratch1=r19, scratch2=r20
	lwz		r19,  0x064c(r1)
	lbz		r20, Timer.Kind(r30)
	rlwimi	r19, r20,  2, 23, 29
	cmplwi	r20,  0x09
	llabel	r20, TimerTable
	li		r21,  0x00
	add		r20, r20, r19
	bgel+	Local_Panic
	stb		r21,  0x0017(r30)
	lwz		r20,  0x0000(r20)
	add		r20, r20, r19
	mtlr	r20
	stw		r30, -0x0254(r18)
	blr

TimerDispatch_0x144
	mfsprg	r18, 0
	lwz		r30, -0x0254(r18)
	lbz		r19,  0x0016(r30)
	cmpwi	r19,  0x01
	lwz		r8,  0x0000(r30)
	beq+	TimerDispatch_0x30
	bl		DeleteID
	mr		r8, r30
	bl		PoolFree
	lwz		r8,  0x001c(r30)
	cmpwi	r8,  0x00
	beq-	TimerDispatch_0x180
	bl		PoolFree
	li		r8,  0x00
	stw		r8,  0x001c(r30)

TimerDispatch_0x180:
	mfsprg	r18, 0
	b		TimerDispatch_0x30

TimerDispatch_0x188
	lwz		r19, EWA.TimerDispatchLR(r18)
	mtlr	r19
	b		AdjustDecForTMRQGivenCurTimeAndTripTime



;	                    StartTimeslicing

;	Xrefs:
;	setup

StartTimeslicing	;	OUTSIDE REFERER
	mfsprg	r19, 0

	li		r8, 1
	stb		r8, EWA.GlobalTimeIsValid(r19)

	li		r8, 0
	stw		r8, -0x02e8(r19)
	stw		r8, -0x02e4(r19)
	
	mflr	r19
	_log	'Starting timeslicing^n'
	mtlr	r19




;	CLOB	r8/r9, r16-r21

AdjustDecForTMRQ

	mflr	r19
	bl		GetTime
	mtlr	r19




;	ARG		TimeBase r8/r9 curTime
;	CLOB	r16-r21

AdjustDecForTMRQGivenCurTime

;	This should get the most distant time???
	lwz		r18, PSA.TimerQueue + LLL.Next(r1)
	lwz		r16, Timer.Time(r18)
	lwz		r17, Timer.Time+4(r18)




;	ARG		TimeBase r8/r9 curTime, TimeBase r16/r17 TripTime
;	CLOB	r18-r21

AdjustDecForTMRQGivenCurTimeAndTripTime

	mfxer	r20
	mfsprg	r19, 0

	lis		r21, 0x7fff
	lbz		r18, EWA.GlobalTimeIsValid(r19)
	ori		r21, r21, 0xffff
	cmpwi	r18, 1

	;	r16/r17 = soonest(last timer, global PSA time if available)

	bne-	global_time_invalid
	lwz		r18, EWA.GlobalTime(r19)
	lwz		r19, EWA.GlobalTime+4(r19)

	_b_if_time_le	r16, r18, last_timer_fires_sooner
	mr		r17, r19
	mr		r16, r18
last_timer_fires_sooner
global_time_invalid


	;	Subtract the current time (or what we were passed in r8/r9) from that time
	subfc	r17, r9, r17
	subfe.	r16, r8, r16
	mtxer	r20

	blt-	@that_time_has_passed				;	hi bit of r16 = 1
	bne-	@that_time_is_in_future				;	
	cmplw	r16, r21							;	typo? should be r17???
	bgt-	@that_time_is_in_future				;	will never be taken...

;	When the times are roughly equal?
	mtspr	dec, r17
	blr

@that_time_is_in_future
	mtspr	dec, r21
	blr

@that_time_has_passed
	mtspr	dec, r21
	mtspr	dec, r16							;	this makes nearly no sense!
	blr



;	                     TimerFire0                      

;	Xrefs:
;	TimerDispatch

TimerFireUnknownKind
	_log	'TimerInformation.kind is zero??^n'



;	                     TimerFire1                      

;	Xrefs:
;	TimerDispatch
;	TimerFire0

TimerFire1	;	OUTSIDE REFERER
	bl		Local_Panic
	lwz		r18,  0x0018(r30)
	stw		r16,  0x0080(r18)
	stw		r17,  0x0084(r18)
	lwz		r8,  0x0018(r30)
	li		r16,  0x00
	lbz		r17,  0x0018(r8)
	lwz		r19,  0x0088(r8)
	cmpwi	r17,  0x00
	stw		r16,  0x011c(r19)
	bne-	TimerFire1_0x64
	addi	r16, r8,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r19
	li		r17,  0x01
	stb		r17,  0x0019(r8)
	bl		TaskReadyAsPrev
	bl		CalculateTimeslice
	bl		FlagSchEvaluationIfTaskRequires
	b		TimerDispatch_0x144

TimerFire1_0x64
	lwz		r16,  0x0064(r8)
	rlwinm.	r16, r16,  0, 30, 30



;	                     TimerFire2                      

;	Xrefs:
;	TimerDispatch
;	TimerFire1

TimerFire2	;	OUTSIDE REFERER
	bne+	TimerDispatch_0x144
	bl		Local_Panic
	lwz		r18,  0x0018(r30)
	stw		r16,  0x0080(r18)
	stw		r17,  0x0084(r18)
	lwz		r8,  0x0018(r30)
	li		r16, -0x7270
	lbz		r17,  0x0018(r8)
	lwz		r18,  0x0088(r8)
	cmpwi	r17,  0x00
	bne-	TimerFire3_0x8
	stw		r16,  0x011c(r18)
	lwz		r8,  0x0008(r8)
	lwz		r8,  0x0000(r8)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	cmpwi	cr1, r9,  0x05
	beq-	TimerFire2_0x8c
	beq-	cr1, TimerFire2_0x7c
	cmpwi	r9,  0x09
	cmpwi	cr1, r9,  0x06
	beq-	TimerFire2_0x6c
	bne+	cr1, Local_Panic
	lwz		r16,  0x0020(r8)
	addi	r16, r16, -0x01
	stw		r16,  0x0020(r8)
	b		TimerFire2_0x98

TimerFire2_0x6c
	lwz		r16,  0x001c(r8)
	addi	r16, r16, -0x01
	stw		r16,  0x001c(r8)
	b		TimerFire2_0x98

TimerFire2_0x7c
	lwz		r16,  0x001c(r8)
	addi	r16, r16, -0x01
	stw		r16,  0x001c(r8)
	b		TimerFire2_0x98

TimerFire2_0x8c
	lwz		r16,  0x002c(r8)
	addi	r16, r16, -0x01
	stw		r16,  0x002c(r8)

TimerFire2_0x98
	lwz		r8,  0x0018(r30)
	addi	r16, r8,  0x08
	RemoveFromList		r16, scratch1=r17, scratch2=r18
	bl		TaskReadyAsPrev



;	                     TimerFire3                      

;	Xrefs:
;	TimerDispatch
;	TimerFire2

TimerFire3	;	OUTSIDE REFERER
	bl		FlagSchEvaluationIfTaskRequires
	b		TimerDispatch_0x144

TimerFire3_0x8	;	OUTSIDE REFERER
	b		Local_Panic



;	                     major_0x13258                      

;	Dead code -- probably removed from TimerTable

	lwz		r8,  0x0018(r30)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r31, r8
	bne-	major_0x13258_0x68
	lwz		r16,  0x0024(r31)
	lwz		r8,  0x001c(r30)
	cmpwi	r16,  0x00
	cmpwi	cr1, r8,  0x00
	beq-	major_0x13258_0x40
	lwz		r17,  0x0028(r31)
	mr.		r8, r17
	lwz		r17,  0x0008(r17)
	beq-	major_0x13258_0x68
	stw		r17,  0x0028(r31)
	b		major_0x13258_0x4c

major_0x13258_0x40
	beq-	cr1, major_0x13258_0x68
	li		r16,  0x00
	stw		r16,  0x001c(r30)

major_0x13258_0x4c
	lwz		r16,  0x0020(r30)
	lwz		r17,  0x0024(r30)
	lwz		r18,  0x0028(r30)
	stw		r16,  0x0010(r8)
	stw		r17,  0x0014(r8)
	stw		r18,  0x0018(r8)
	bl		EnqueueMessage		; Message *r8, Queue *r31

major_0x13258_0x68
	lwz		r8,  0x0034(r30)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Semaphore.kIDClass

	mr		r31, r8
	bne-	major_0x13258_0x80
	bl		SignalSemaphore

major_0x13258_0x80
	lwz		r8,  0x002c(r30)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass

	mr		r31, r8



;	                     TimerFire4                      

;	Xrefs:
;	TimerDispatch
;	major_0x13258

TimerFire4	;	OUTSIDE REFERER
	bne-	TimerFire4_0xc
	lwz		r8,  0x0030(r30)
	bl		SetEvent

TimerFire4_0xc
	b		TimerDispatch_0x144

TimerFire4_0x10	;	OUTSIDE REFERER
	mfsprg	r28, 0
	lwz		r29, -0x0008(r28)
	mr		r8, r29
	bl		TaskUnready
	lbz		r17,  0x0019(r29)
	cmpwi	r17,  0x02
	bge-	TimerFire4_0x64
	mr		r8, r29
	lwz		r16,  0x0038(r30)
	lwz		r17,  0x003c(r30)
	bl		clear_cr0_lt
	bge-	TimerFire4_0x50
	mr		r8, r29
	bl		TaskReadyAsPrev
	bl		CalculateTimeslice
	b		TimerFire5_0x8

TimerFire4_0x50
	li		r18,  0x02
	stb		r18,  0x0019(r29)
	mr		r8, r29
	bl		TaskReadyAsPrev
	b		TimerFire5_0x8

TimerFire4_0x64
	mr		r8, r29



;	                     TimerFire5                      

;	Xrefs:
;	TimerDispatch
;	TimerFire4

TimerFire5	;	OUTSIDE REFERER
	bl		TaskReadyAsPrev
	bl		major_0x149d4

TimerFire5_0x8	;	OUTSIDE REFERER
	bl		FlagSchEvaluationIfTaskRequires
	mfsprg	r18, 0
	b		TimerDispatch_0x30



;	                     major_0x13364                      

;	Dead code -- probably removed from TimerTable

	_log	'Heartbeat: Ext '
	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.ExternalIntCount(r1)
	mr		r8, r16
	bl		printd

	_log	'Alerts '
	lwz		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.AlertCount(r1)
	mr		r8, r16
	bl		printd

	_log	'Blue cpu-'
	lwz		r17, PSA.PA_BlueTask(r1)
	lhz		r16, Task.CPUIndex(r17)
	mr		r8, r16
	bl		printb

	_log	'state-'
	lbz		r16, Task.State(r17)
	mr		r8, r16
	bl		printb

	_log	'scr-'
	lwz		r16, KDP.PA_ECB(r1)
	lwz		r18, KDP.PostIntMaskInit(r1)
	lwz		r16, ContextBlock.CR(r16)
	and		r16, r16, r18
	mr		r8, r16
	bl		printw

	_log	'mcr-'
	lwz		r16, PSA.MCR(r1)
	mr		r8, r16
	bl		printw

	_log	'IPL-'
	lwz		r16, KDP.PA_EmulatorIplValue(r1)
	lhz		r16, 0(r16)
	mr		r8, r16
	bl		printh

	_log	'eSR-'
	lwz		r16, KDP.PA_ECB(r1)
	lwz		r16, ContextBlock.r25(r16)
	andi.	r16, r16, 7
	mr		r8, r16
	bl		printb
	_log	'^n'

	mfxer	r19
	lwz		r16,  0x0038(r30)
	lwz		r17,  0x003c(r30)
	lwz		r18,  0x0f2c(r1)
	slwi	r18, r18,  3
	addc	r17, r17, r18



;	                     TimerFire7                      

;	Xrefs:
;	TimerDispatch
;	major_0x13364

TimerFire7	;	OUTSIDE REFERER
	addze	r16, r16
	stw		r16,  0x0038(r30)
	stw		r17,  0x003c(r30)
	mtxer	r19
	mr		r8, r30
	bl		EnqueueTimer
	b		TimerDispatch_0x144



;	                     major_0x134d8                      

;	Dead code -- probably removed from TimerTable

	lwz		r18, -0x0438(r1)
	lwz		r19,  0x0f88(r1)
	subf.	r19, r18, r19
	ble-	TimerFire8_0x1c
	srwi	r19, r19, 11
	mfxer	r20

major_0x134d8_0x18
	mftbu	r16
	mftb	r17,  0x10c
	mftbu	r18
	cmpw	r16, r18
	li		r18,  0x00
	bne-	major_0x134d8_0x18
	mttb	r18
	addc	r17, r17, r19
	addze	r16, r16
	mttbu	r16
	mttb	r17
	lwz		r18, -0x0438(r1)
	srwi	r18, r18, 11



;	                     TimerFire8                      

;	Xrefs:
;	TimerDispatch
;	major_0x134d8

TimerFire8	;	OUTSIDE REFERER
	addc	r17, r17, r18
	addze	r16, r16
	stw		r16,  0x0038(r30)
	stw		r17,  0x003c(r30)
	mtxer	r20
	mr		r8, r30
	bl		EnqueueTimer

TimerFire8_0x1c	;	OUTSIDE REFERER
	b		TimerDispatch_0x144



;	                     major_0x13544                      

;	Dead code -- probably removed from TimerTable

	lwz		r19, -0x036c(r1)
	mfxer	r20
	cmpwi	cr1, r19,  0x00
	srawi	r8, r19, 31
	beq-	cr1, TimerFire6_0x4

major_0x13544_0x14
	mftbu	r16
	mftb	r17,  0x10c
	mftbu	r18
	cmpw	r16, r18
	li		r18,  0x00
	bne-	major_0x13544_0x14
	mttb	r18
	addc	r19, r17, r19
	adde	r18, r16, r8
	mttbu	r18
	mttb	r19
	bgt-	cr1, major_0x13544_0x64

major_0x13544_0x44
	mftbu	r18
	mftb	r19,  0x10c
	mftbu	r8
	cmpw	r18, r8
	bne-	major_0x13544_0x44
	subfc	r19, r17, r19
	subfe.	r18, r16, r18
	blt+	major_0x13544_0x44

major_0x13544_0x64
	lwz		r18, -0x0368(r1)
	addc	r17, r17, r18
	addze	r16, r16
	stw		r16,  0x0038(r30)



;	                     TimerFire6                      

;	Xrefs:
;	TimerDispatch
;	major_0x13544

TimerFire6	;	OUTSIDE REFERER
	stw		r17,  0x003c(r30)

TimerFire6_0x4	;	OUTSIDE REFERER
	mtxer	r20
	beq+	cr1, TimerDispatch_0x144
	mr		r8, r30
	bl		EnqueueTimer
	b		TimerDispatch_0x144



;	                     major_0x135d0                      

;	Dead code -- probably removed from TimerTable

	mfxer	r19
	lwz		r16,  0x0038(r30)
	lwz		r17,  0x003c(r30)
	lwz		r18,  0x0f2c(r1)
	srwi	r18, r18,  1
	addc	r17, r17, r18
	addze	r16, r16
	stw		r16,  0x0038(r30)
	stw		r17,  0x003c(r30)
	mtxer	r19
	mr		r8, r30
	bl		EnqueueTimer
	bl		getchar
	cmpwi	r8, -0x01
	beq+	TimerDispatch_0x144
	bl		panic_non_interactive
	b		TimerDispatch_0x144



;	                  EnqueueTimer

;	Xrefs:
;	MPCall_55
;	NKSetClockStep
;	NKSetClockDriftCorrection
;	MPCall_18
;	MPCall_23
;	MPCall_27
;	MPCall_52
;	MPCall_31
;	InitTMRQs

;	ARG		Timer *r8
;	CLOB	r16-r20

EnqueueTimer	;	OUTSIDE REFERER

	;	Keep the trip-time of this timer in r16/r17
	lwz		r16, Timer.Time(r8)
	lwz		r17, Timer.Time+4(r8)

	;	r20 = timer being considered
	;	r18/r19 = trip-time of timer being condidered
	lwz     r20, PSA.TimerQueue + TimerQueueStruct.LLL + LLL.Next(r1)
	lwz		r18, Timer.Time(r20)
	lwz		r19, Timer.Time+4(r20)

	;	First try to insert at head of global TMRQ
	cmpw	r16, r18
	cmplw	cr1, r17, r19
	bgt-	@insert_further_ahead
	blt-	@insert_at_tail
	bge-	cr1, @insert_further_ahead

@insert_at_tail
	addi	r20, r1, PSA.TimerQueue + TimerQueueStruct.LLL

	li		r18, 1
	stb		r18, Timer.Byte3(r8)

	;	Insert at the very back of the queue
	lwz		r19, LLL.Freeform(r8)
	lwz		r9, LLL.Freeform(r20)
	stw		r9, LLL.Freeform(r8)				;	my freeform = considered freeform
	lwz		r9, LLL.Next(r20)
	stw		r9, LLL.Next(r8)					;	my next = next of considered
	stw		r20, LLL.Prev(r8)					;	my prev = considered
	stw		r8, LLL.Prev(r9)					;	prev of next of considered = me
	stw		r8, LLL.Next(r20)					;	next of considered = me
	stw		r19, LLL.Freeform(r8)				;	my freeform = my original freeform

	b		AdjustDecForTMRQ

@insert_further_ahead
	lwz		r20, PSA.TimerQueue + TimerQueueStruct.LLL + LLL.Prev(r1)

@searchloop
	lwz		r18, Timer.Time(r20)
	lwz		r19, Timer.Time+4(r20)
	cmpw	r16, r18
	cmplw	cr1, r17, r19
	bgt-	@insert_after_this_one
	blt-	@next
	bge-	cr1, @insert_after_this_one

@next
	lwz		r20, LLL.Prev(r20)
	b		@searchloop

@insert_after_this_one
	li		r18, 1
	stb		r18, Timer.Byte3(r8)

	lwz		r19, LLL.Freeform(r8)
	lwz		r9, LLL.Freeform(r20)
	stw		r9, LLL.Freeform(r8)				;	my freeform = considered freeform
	lwz		r9, LLL.Next(r20)
	stw		r9, LLL.Next(r8)					;	my next = next of considered
	stw		r20, LLL.Prev(r8)					;	my prev = considered
	stw		r8, LLL.Prev(r9)					;	prev of next of considered = me
	stw		r8, LLL.Next(r20)					;	next of considered = me
	stw		r19, LLL.Freeform(r8)				;	my freeform = my original freeform

	blr



;	Remove a Timer from the global timer firing queue (TMRQ).
;	If the Timer was to be the next to fire, then perform the
;	standard decrementer rollover adjustment.

;	ARG		Timer *r8

DequeueTimer
	lwz		r16, Timer.QueueLLL + LLL.FreeForm(r8)
	cmpwi	r16, 0
	lwz		r18, PSA.TimerQueue + TimerQueueStruct.LLL + LLL.Next(r1)
	beq+	Local_Panic

	RemoveFromList		r8, scratch1=r16, scratch2=r17

	li		r16, 0
	cmpw	r18, r8
	stb		r16, Timer.Byte3(r8)

	beq+	AdjustDecForTMRQ

	blr



;	                 TimebaseTicksPerPeriod

;	Xrefs:
;	MPCall_18
;	MPCall_23
;	MPCall_27
;	MPCall_52
;	MPCall_31
;	InitRDYQs

;	Get the number of timebase ticks in a specified period

;	ARG		long r8 period (positive for ms, negative for us)

TimebaseTicksPerPeriod
	mr.		r17, r8
	li		r19, 250
	lwz		r9, KDP.ProcessorInfo + NKProcessorInfo.DecClockRateHz(r1)

	bgt+	@period_positive
	blt+	@period_negative
	li		r8, 0
	li		r9, 0
	blr						;	fail
@period_negative
	neg		r17, r17
	lisori	r19, 250000
@period_positive

	divw	r19, r9, r19

	mullw	r9, r19, r17
	mulhw	r8, r19, r17

	srwi	r9, r9, 2
	rlwimi	r9, r8, 30, 0, 1
	srwi	r8, r8, 2

	blr




;	Xrefs:
;	NKSetClockStep
;	NKSetClockDriftCorrection
;	MPCall_18
;	MPCall_23
;	MPCall_27
;	MPCall_52
;	MPCall_40
;	MPCall_32
;	CreateTask
;	InitTMRQs
;	AdjustDecForTMRQ
;	RescheduleAndReturn
;	major_0x14548

;	RET		long r8 tbu, long r9 tbl
;	CLOB	r16, r17

GetTime

	mfpvr	r8
	rlwinm.	r8, r8, 0, 0, 14
	beq-	@is_601

@retry_timebase:
	mftbu	r8
	mftb	r9
	mftbu	r16
	cmpw	r8, r16
	bne-	@retry_timebase

	b		@return

@is_601
	dialect	POWER		;	disassembled this in POWER mode!
	
@retry_rtc
	mfrtcu	r8
	mfrtcl	r9
	mfrtcu	r16
	cmp		0, r8, r16

	dialect	PowerPC
	bne-	@retry_rtc		;	POWER chokes on hints?
	dialect	POWER

	liu		r16, 1000000000 >> 16
	oril	r16, r16, 1000000000 & 0xffff

	mfmq	r17
	mul		r8, r16, r8
	mfmq	r16
	mtmq	r17
	
	mfxer	r17
	a		r9, r16, r9
	aze		r8, r8
	mtxer	r17

	dialect POWERPC

@return
	blr
