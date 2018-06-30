;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKCache
;	    FlushCaches
;	  NKInterrupts
;	    IntReturn
;	    wordfill
;	  NKThud
;	    panic
;	EXPORTS:
;	  InitIdleVecTable (=> NKInit)
;	  kcPowerDispatch (=> NKInit)


#### ##    ## #### ########    ##     ## ########  ######     ######## ########  ##       
 ##  ###   ##  ##     ##       ##     ## ##       ##    ##       ##    ##     ## ##       
 ##  ####  ##  ##     ##       ##     ## ##       ##             ##    ##     ## ##       
 ##  ## ## ##  ##     ##       ##     ## ######   ##             ##    ########  ##       
 ##  ##  ####  ##     ##        ##   ##  ##       ##             ##    ##     ## ##       
 ##  ##   ###  ##     ##         ## ##   ##       ##    ##       ##    ##     ## ##       
#### ##    ## ####    ##          ###    ########  ######        ##    ########  ######## 

;	When we are asked via a PowerDispatch call to put a CPU into a non-full-
;	on pwrmgt state, we will point its SPRG3 to this table. Any of these
;	three interrupts will return the CPU to full-on mode, and we will return
;	from the PowerDispatch call. Called at NK init time.

	align	kIntAlign

InitIdleVecTable

	mflr	r9
	llabel	r23, panic
	add		r23, r23, r25
	addi	r8, r1, PSA.VecBaseIdle
	li		r22, VecTable.Size
	bl		wordfill
	mtlr	r9
	llabel	r23, IntReturnToFullOn
	add		r23, r23, r25
	stw		r23, VecTable.SystemResetVector(r8)
	stw		r23, VecTable.ExternalIntVector(r8)
	stw		r23, VecTable.DecrementerVector(r8)
	blr


########  ####  ######  ########     ###    ########  ######  ##     ## 
##     ##  ##  ##    ## ##     ##   ## ##      ##    ##    ## ##     ## 
##     ##  ##  ##       ##     ##  ##   ##     ##    ##       ##     ## 
##     ##  ##   ######  ########  ##     ##    ##    ##       ######### 
##     ##  ##        ## ##        #########    ##    ##       ##     ## 
##     ##  ##  ##    ## ##        ##     ##    ##    ##    ## ##     ## 
########  ####  ######  ##        ##     ##    ##     ######  ##     ## 

;	Called using 68k `$FE0F` or PPC `twi ... 5`

;	ARG		selector r3 (0-11), ...

	align	kIntAlign

kcPowerDispatch

	mtcr	r7
	lwz		r4, KDP.TestIntMaskInit(r1)
	cmplwi	cr7, r3, 11
	mr		r9, r13
	bc		BO_IF, 8, @use_provided_mcr
	lwz		r9, PSA.MCR(r1)
@use_provided_mcr

	and.	r8, r4, r9
	bgt		cr7, PowerEarlyReturnError				; invalid selector
	bne		PowerEarlyReturnSuccess

	cmplwi	cr7, r3, 11
	beq		cr7, PwrInfiniteLoop

	cmplwi	cr7, r3, 8
	beq		cr7, PwrSuspendSystem

	cmplwi	cr7, r3, 9
	beq		cr7, PwrSetICTC

	;	Fall through to 0-7: PwrIdle



  #####           ########    #### ########  ##       ######## 
 ##   ##          ##    ##     ##  ##     ## ##       ##       
##     ##             ##       ##  ##     ## ##       ##       
##     ## #######    ##        ##  ##     ## ##       ######   
##     ##           ##         ##  ##     ## ##       ##       
 ##   ##            ##         ##  ##     ## ##       ##       
  #####             ##        #### ########  ######## ######## 

;	Selector 0-7

;	Set the CPU static pwrmgt state to doze, idle or sleep, then return to
;	full-on when we get an interrupt.

;	ARG		r3 & 1: which of the two pre-programmed pwrmgt states to invoke (see NKProcFlagsTbl.s)
;			r3 & 4: whether to flush L1 and L2 caches

;	Different 603+ chips have static power management states named "doze",
;	"nap" and "sleep". A state is selected by setting the corresponding bit
;	in HID0. The state is then invoked by setting MSR[POW]. The state is
;	ended by a decrementer interrupt (doze/nap only) or external interrupt.
;	This is a short term CPU-specific state, *not* system-wide "sleep".

;	Because the NK timer code sets the decrementer, we can be sure that we
;	will not miss a timer firing.

PwrIdle

	;	Get us some breathing room

	_RegRangeToContextBlock r26, r31


	;	Activate the interrupt table that will rouse the CPU

	mfsprg	r31, 3				; will restore r31 => SPRG3 after state exited
	addi	r8, r1, PSA.VecBaseIdle
	mtsprg	3, r8


	;	Save argument & 4 (run-cache-code flag)

	rlwinm	r26, r3, 0, 29, 29


	;	Choose from the NK's two pre-programmed pwrmgt states for this CPU.
	;	Fail if we find zero (e.g. on the 601).

	;	arg			pwrmgt state selector => r3
	;	r3 & 1		0=fail 1=DOZE 2=NAP 3=SLEEP
	;	------		---------------------------
	;	0			(CpuSpecificByte1 >> 6) & 3
	;	1			(CpuSpecificByte1 >> 4) & 3

	clrlwi	r3, r3, 30
	lbz		r8, KDP.CpuSpecificByte1(r1)
	slwi	r3, r3, 1
	addi	r3, r3, 26
	rlwnm	r3, r8, r3, 30, 31
	cmpwi	r3, 0
	beq		PowerEarlyRestoreReturnError


	;	Depending on pre-programmed flags, set:
	;		HID0[NHR] ("not hard reset" flag)
	;		HID0[ptrmgt state selected above]

	lbz		r9, KDP.CpuSpecificByte2(r1)
	cmpwi	r9, 0
	beq		@set_neither

	mfspr	r27, hid0			; will restore r27 => HID0 when system wakes below
	mr		r8, r27
	cmpwi	r9, 1
	beq		@set_only_nhr

	oris	r9, r3, 0x0100		; set bit 7
	srw		r9, r9, r9			; shift right by 0-3
	rlwimi	r8, r9, 0, 8, 10	; keep bits 8/9/10
@set_only_nhr

	oris	r8, r8, 1			; also set NHR
	mtspr	hid0, r8
@set_neither


	;	Flush L1 and L2 caches if argument & 4

	cmplwi	r26, 4
	beql	FlushCaches


	;	Set MSR bits to enter the selected pwrmgt state

	mfmsr	r8
	ori		r8, r8, 0x8002 		; Always set MSR[EE] and MSR[RI] so we can wake!
	cmplwi	r3, 0				; If using HID0[pwrmgt state], set MSR[POW] so it takes effect
	beq		@no_pow
	oris	r8, r8, 4
@no_pow
	sync						; Apply MSR!
	mtmsr	r8
	isync


	;	Loop while the state takes effect, then jump 4 bytes forward when we cop an interrupt

	b		*
IntReturnToFullOn


	;	Restore HID0 from r27, assuming that we mangled it

	lbz		r8, KDP.CpuSpecificByte2(r1)
	cmpwi	r8, 0
	beq		@hid_was_not_changed
	mtspr	hid0, r27
@hid_was_not_changed


	;	Restore registers and return successfully to caller.
	;	Not sure about the decrementer stuff.

	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1

	lis		r9, 0x7fff
	mfspr	r8, dec
	mtspr	dec, r9
	mtspr	dec, r8

	li		r3, 0

PowerCallRestoreReturn

	mtsprg	3, r31						; saved SPRG3 above

	_RegRangeFromContextBlock r26, r31

	b		IntReturn



;	Return islands for other calls

PowerEarlyRestoreReturnError
	li		r3, -0x7267
	b		PowerCallRestoreReturn

PowerEarlyReturnSuccess
	li		r3, 0
	b		IntReturn

PowerEarlyReturnError
	li		r3, -1
	b		IntReturn



 #######      ######  ##     ##  ######  ########  ######## ##    ## ########  
##     ##    ##    ## ##     ## ##    ## ##     ## ##       ###   ## ##     ## 
##     ##    ##       ##     ## ##       ##     ## ##       ####  ## ##     ## 
 #######      ######  ##     ##  ######  ########  ######   ## ## ## ##     ## 
##     ##          ## ##     ##       ## ##        ##       ##  #### ##     ## 
##     ##    ##    ## ##     ## ##    ## ##        ##       ##   ### ##     ## 
 #######      ######   #######   ######  ##        ######## ##    ## ########  

;	Selector 8

;	Put this, the last scheduled CPU, into SLEEP mode.
;	Save state. Call ActuallySuspend. Restore state. Return.

PwrSuspendSystem

	;	Cannot sleep if multiple CPUs are scheduled

	mfsprg	r9, 0
	lwz		r8, EWA.CPUBase + CPU.LLL + LLL.Freeform(r9)
	lwz		r9, CoherenceGroup.ScheduledCpuCount(r8)
	cmpwi	r9, 1
	li		r3, -0x7267
	bgt		IntReturn


	;	Some breathing room

	_RegRangeToContextBlock r26, r31


	bl		FlushCaches


	;	Disable both L1 caches (via HID0)

	mfspr	r9, hid0
	rlwinm	r9, r9, 0, 18, 16	; unset HID0[DCE] (data cache enable)
	rlwinm	r9, r9, 0, 17, 15	; unset HID0[ICE] (inst cache enable)
	mtspr	hid0, r9
	sync
	isync


	;	Disable L2 cache (via L2CR, if present)

	lwz		r26, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	andi.	r26, r26, 1 << NKProcessorInfo.hasL2CR
	beq		@no_need_to_deactivate_l2
	mfspr	r9, l2cr
	clrlwi	r9, r9, 1			; unset L2CR[L2E]
	mtspr	l2cr, r9
	sync
	isync
	addi	r8, r1, PSA.ProcessorState
	stw		r9, NKProcessorState.saveL2CR(r8)
@no_need_to_deactivate_l2


	;	Save some GPRs

	stw		r7, ContextBlock.Flags(r6)
	_RegRangeToContextBlock r2, r5
	_RegRangeToContextBlock r14, r25
	stw		r13, ContextBlock.CR(r6)


	;	Save floats

	andi.	r8, r11, 0x2000				;	MSR[FP]
	beq		@no_save_float
	mfmsr	r8
	ori		r8, r8, 0x2000				;	ensure that MSR bit is set?
	mtmsr	r8
	isync
	_FloatRangeToContextBlock f0, f16
	mffs	f0
	_FloatRangeToContextBlock f17, f31
	stfd	f0, ContextBlock.PageInSystemHeap(r6)			; ???
@no_save_float


	;	Save misc SPRs

	mfxer	r9
	addi	r16, r1, PSA.ProcessorState
	stw		r9, ContextBlock.XER(r6)
	mfctr	r9
	stw		r9, ContextBlock.CTR(r6)
	stw		r12, ContextBlock.FE000000(r6)
	stw		r10, NKProcessorState.saveSRR0(r16)
	stw		r11, NKProcessorState.saveSRR1(r16)
	mfspr	r9, hid0
	stw		r9, NKProcessorState.saveHID0(r16)


	;	Save timebase

@tb_retry
	mftbu	r9
	stw		r9, NKProcessorState.saveTBU(r16)
	mftb	r9
	stw		r9, NKProcessorState.saveTBL(r16)
	mftbu	r8
	lwz		r9, NKProcessorState.saveTBU(r16)
	cmpw	r8, r9
	bne		@tb_retry


	;	Save MSR

	mfmsr	r9
	stw		r9, NKProcessorState.saveMSR(r16)


	;	Save SDR1

	mfspr	r9, sdr1
	stw		r9, NKProcessorState.saveSDR1(r16)


	;	Save BAT registers

	mfspr	r9, dbat0u
	stw		r9, NKProcessorState.saveDBAT0u(r16)
	mfspr	r9, dbat0l
	stw		r9, NKProcessorState.saveDBAT0l(r16)
	mfspr	r9, dbat1u
	stw		r9, NKProcessorState.saveDBAT1u(r16)
	mfspr	r9, dbat1l
	stw		r9, NKProcessorState.saveDBAT1l(r16)
	mfspr	r9, dbat2u
	stw		r9, NKProcessorState.saveDBAT2u(r16)
	mfspr	r9, dbat2l
	stw		r9, NKProcessorState.saveDBAT2l(r16)
	mfspr	r9, dbat3u
	stw		r9, NKProcessorState.saveDBAT3u(r16)
	mfspr	r9, dbat3l
	stw		r9, NKProcessorState.saveDBAT3l(r16)
	mfspr	r9, ibat0u
	stw		r9, NKProcessorState.saveIBAT0u(r16)
	mfspr	r9, ibat0l
	stw		r9, NKProcessorState.saveIBAT0l(r16)
	mfspr	r9, ibat1u
	stw		r9, NKProcessorState.saveIBAT1u(r16)
	mfspr	r9, ibat1l
	stw		r9, NKProcessorState.saveIBAT1l(r16)
	mfspr	r9, ibat2u
	stw		r9, NKProcessorState.saveIBAT2u(r16)
	mfspr	r9, ibat2l
	stw		r9, NKProcessorState.saveIBAT2l(r16)
	mfspr	r9, ibat3u
	stw		r9, NKProcessorState.saveIBAT3u(r16)
	mfspr	r9, ibat3l
	stw		r9, NKProcessorState.saveIBAT3l(r16)


	;	Save SPRGs

	mfsprg	r9, 0
	stw		r9, NKProcessorState.saveSPRG0(r16)
	mfsprg	r9, 1
	stw		r9, NKProcessorState.saveSPRG1(r16)
	mfsprg	r9, 2
	stw		r9, NKProcessorState.saveSPRG2(r16)
	mfsprg	r9, 3
	stw		r9, NKProcessorState.saveSPRG3(r16)


	;	Save ContextBlock ptr

	stw		r6, NKProcessorState.saveContextPtr(r16)


	;	Do the thing. The BL gives us a useful restore address.

	bl		ActuallySuspend


	lwz		r1, EWA.r1(r1)
	addi	r16, r1, PSA.ProcessorState


	;	Do something evil to the segment registers?

	lisori	r8, 0x1000000
	lis		r9, 0
@srin_loop
	subis	r9, r9, 0x1000
	addis	r8, r8, -0x10
	mr.		r9, r9
	mtsrin	r8, r9
	bne		@srin_loop
	isync


	;	Reactivate L1 cache

	mfspr	r9, hid0
	li		r8, 0x800			; HID0[ICFI] invalidate icache
	ori		r8, r8, 0x200		; HID0[SPD] disable spec cache accesses
	or		r9, r9, r8
	mtspr	hid0, r9
	isync
	andc	r9, r9, r8			; now undo that?
	mtspr	hid0, r9
	isync
	ori		r9, r9, 0x8000		; set HID0[ICE]
	ori		r9, r9, 0x4000		; set HID0[DCE]
	mtspr	hid0, r9
	isync


	;	Reactivate L2 cache

	lwz		r26, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	andi.	r26, r26, 1 << NKProcessorInfo.hasL2CR
	beq		@no_need_to_reactivate_l2
	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.ProcessorL2DSize(r1)
	mr.		r8, r8
	beq		@no_need_to_reactivate_l2

	mfspr	r9, hid0
	rlwinm	r9, r9,  0, 12, 10
	mtspr	hid0, r9
	isync

	lwz		r9, NKProcessorState.saveL2CR(r16)
	mtspr	l2cr, r9
	sync
	isync
	lis		r8, 0x20		; set L2CR[L2I] to invalidate L2 cache
	or		r8, r9, r8
	mtspr	l2cr, r8
	sync
	isync

	;	spin while bottom bit (reserved) is set???
@l2_reactivate_loop
	mfspr	r8, l2cr
	rlwinm.	r8, r8, 31,  0,  0
	bne		@l2_reactivate_loop


	mfspr	r8, l2cr
	lisori	r9, 0xffdfffff		; unset bit 6 (reserved?)
	and		r8, r8, r9
	mtspr	l2cr, r8
	sync


	mfspr	r8, hid0
	oris	r8, r8, 0x0010		; set HID0[HIGH_BAT_EN] (was HID0[DOZE])
	mtspr	hid0, r8
	isync


	mfspr	r8, l2cr
	oris	r8, r8,  0x8000		; set L2CR[L2E]
	mtspr	l2cr, r8
	sync
	isync
@no_need_to_reactivate_l2


	;	Still working on this...

	lwz		r6, NKProcessorState.saveContextPtr(r16)
	lwz		r7, ContextBlock.Flags(r6)
	lwz		r13, ContextBlock.CR(r6)
	lwz		r9, ContextBlock.CTR(r6)
	mtctr	r9
	lwz		r12, ContextBlock.FE000000(r6)
	lwz		r9, ContextBlock.XER(r6)
	mtxer	r9
	lwz		r10, NKProcessorState.saveSRR0(r16)
	lwz		r11, NKProcessorState.saveSRR1(r16)


	;	Load some GPRs

	_RegRangeFromContextBlock r2, r5
	_RegRangeFromContextBlock r14, r15
	_RegRangeFromContextBlock r17, r31


	;	Load floats

	andi.	r8, r11, 0x2000				;	MSR[FP]
	beq		@no_restore_float
	mfmsr	r8
	ori		r8, r8, 0x2000				;	ensure that MSR bit is set?
	mtmsr	r8
	isync
	lfd		f31, ContextBlock.PageInSystemHeap(r6)			; bit odd
	_FloatRangeFromContextBlock f0, f8
	mtfsf	0xff, f31
	_FloatRangeFromContextBlock f9, f31
@no_restore_float


	;	Load HID0, plus ICE and DCE bits

	lwz		r9, NKProcessorState.saveHID0(r16)
	ori		r9, r9,  0x8000
	ori		r9, r9,  0x4000
	mtspr	hid0, r9
	sync
	isync


	;	Load timebase

	lwz		r9, NKProcessorState.saveTBU(r16)
	mtspr	tbu, r9
	lwz		r9, NKProcessorState.saveTBL(r16)
	mtspr	tbl, r9


	;	Set decrementer quite low?

	li		r9, 1
	mtspr	dec, r9


	;	Load MSR

	lwz		r9, NKProcessorState.saveMSR(r16)
	mtmsr	r9
	sync
	isync


	;	Load SDR1

	lwz		r9, NKProcessorState.saveSDR1(r16)
	mtspr	sdr1, r9


	;	Load SPRGs

	lwz		r9, NKProcessorState.saveSPRG0(r16)
	mtsprg	0, r9
	lwz		r9, NKProcessorState.saveSPRG1(r16)
	mtsprg	1, r9
	lwz		r9, NKProcessorState.saveSPRG2(r16)
	mtsprg	2, r9
	lwz		r9, NKProcessorState.saveSPRG3(r16)
	mtsprg	3, r9


	;	Load BAT registers

	lwz		r9, NKProcessorState.saveDBAT0u(r16)
	mtspr	dbat0u, r9
	lwz		r9, NKProcessorState.saveDBAT0l(r16)
	mtspr	dbat0l, r9
	lwz		r9, NKProcessorState.saveDBAT1u(r16)
	mtspr	dbat1u, r9
	lwz		r9, NKProcessorState.saveDBAT1l(r16)
	mtspr	dbat1l, r9
	lwz		r9, NKProcessorState.saveDBAT2u(r16)
	mtspr	dbat2u, r9
	lwz		r9, NKProcessorState.saveDBAT2l(r16)
	mtspr	dbat2l, r9
	lwz		r9, NKProcessorState.saveDBAT3u(r16)
	mtspr	dbat3u, r9
	lwz		r9, NKProcessorState.saveDBAT3l(r16)
	mtspr	dbat3l, r9
	lwz		r9, NKProcessorState.saveIBAT0u(r16)
	mtspr	ibat0u, r9
	lwz		r9, NKProcessorState.saveIBAT0l(r16)
	mtspr	ibat0l, r9
	lwz		r9, NKProcessorState.saveIBAT1u(r16)
	mtspr	ibat1u, r9
	lwz		r9, NKProcessorState.saveIBAT1l(r16)
	mtspr	ibat1l, r9
	lwz		r9, NKProcessorState.saveIBAT2u(r16)
	mtspr	ibat2u, r9
	lwz		r9, NKProcessorState.saveIBAT2l(r16)
	mtspr	ibat2l, r9
	lwz		r9, NKProcessorState.saveIBAT3u(r16)
	mtspr	ibat3u, r9
	lwz		r9, NKProcessorState.saveIBAT3l(r16)
	mtspr	ibat3l, r9


	;	And reclaim the register we were using for ProcessorState

	_RegRangeFromContextBlock r16, r16


	;	Hooray! We're back!

	li		r3, 0
	b		IntReturn



  ###  ######  ##     ##  ######  ########  ######## ##    ## ########  ###   
 ##   ##    ## ##     ## ##    ## ##     ## ##       ###   ## ##     ##   ##  
##    ##       ##     ## ##       ##     ## ##       ####  ## ##     ##    ## 
##     ######  ##     ##  ######  ########  ######   ## ## ## ##     ##    ## 
##          ## ##     ##       ## ##        ##       ##  #### ##     ##    ## 
 ##   ##    ## ##     ## ##    ## ##        ##       ##   ### ##     ##   ##  
  ###  ######   #######   ######  ##        ######## ##    ## ########  ###   

ActuallySuspend
	mflr	r9
	stw		r9, NKProcessorState.saveReturnAddr(r16)
	stw		r1, NKProcessorState.saveKernelDataPtr(r16)
	addi	r9, r16, NKProcessorState.saveKernelDataPtr - 4 ; so that 4(r9) goes to r1?
	li		r0, 0
	stw		r9, 0(0)
	lisori	r9, 'Lars'
	stw		r9, 4(0)


	mfspr	r9, hid0
	andis.	r9, r9, 0x0020		; mask: only HID0[SLEEP]
	mtspr	hid0, r9


	mfmsr	r8
	oris	r8, r8, 0x0004		; set MSR[POW] (but not yet)


	mfspr	r9, hid0
	ori		r9, r9,  0x8000		; set HID0[ICE]
	mtspr	hid0, r9


	;	Get address of this table => r9
	bl		@l
@l	mflr	r9
	addi	r9, r9, @table_of_sixteen_zeros - @l


	lisori	r1, 0xcafebabe


	b		@evil_aligned_sleep_loop
	align	8
@evil_aligned_sleep_loop
	sync
	mtmsr	r8							; sleep now
	isync
	cmpwi	r1, 0
	beq		@evil_aligned_sleep_loop	; re-sleep until the world is sane?
	lwz		r0, 0(r9)
	andi.	r1, r1, 0
	b		@evil_aligned_sleep_loop	; actually, there is no escape


	align	8
@table_of_sixteen_zeros
	dcb.b	16, 0



 #######      ######  ######## ########    ####  ######  ########  ######  
##     ##    ##    ## ##          ##        ##  ##    ##    ##    ##    ## 
##     ##    ##       ##          ##        ##  ##          ##    ##       
 ########     ######  ######      ##        ##  ##          ##    ##       
       ##          ## ##          ##        ##  ##          ##    ##       
##     ##    ##    ## ##          ##        ##  ##    ##    ##    ##    ## 
 #######      ######  ########    ##       ####  ######     ##     ######  

;	Selector 9

;	Set ICTC (Instruction Cache Throttling Control) register
;	(used to reduce temp without adjusting clock)

;	ARG		value r5

PwrSetICTC

	mtspr	1019, r5
	li		r3, 0
	b		IntReturn



   ##      ##      ##        #######   #######  ########  
 ####    ####      ##       ##     ## ##     ## ##     ## 
   ##      ##      ##       ##     ## ##     ## ##     ## 
   ##      ##      ##       ##     ## ##     ## ########  
   ##      ##      ##       ##     ## ##     ## ##        
   ##      ##      ##       ##     ## ##     ## ##        
 ######  ######    ########  #######   #######  ##        

;	Selector 11

PwrInfiniteLoop

	b		*
