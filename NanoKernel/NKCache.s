 ######     ###     ######  ##     ## ########     ######     ###    ##       ##       
##    ##   ## ##   ##    ## ##     ## ##          ##    ##   ## ##   ##       ##       
##        ##   ##  ##       ##     ## ##          ##        ##   ##  ##       ##       
##       ##     ## ##       ######### ######      ##       ##     ## ##       ##       
##       ######### ##       ##     ## ##          ##       ######### ##       ##       
##    ## ##     ## ##    ## ##     ## ##          ##    ## ##     ## ##       ##       
 ######  ##     ##  ######  ##     ## ########     ######  ##     ## ######## ######## 

;	Enable/disable/probe the L1/2 data/inst cache

;	Probably called using an unknown 68k F-trap. Not usually called on my
;	G4, but can be tested by hacking the MPCall table. Uses fancy new CPU
;	features (MSSCR0), so probably not legacy code. For CPU accelerator
;	cards? `FlushCache` needs to be nopped out to prevent a crash.

;	ARGUMENT (r3)
;		r3.hi = action flags
;			enable specified caches		$8000
;			disable specified caches	$4000
;			report pre-change state		$2000
;			also enable (???)			$1000
;			enable/disable I-cache		$0800
;			enable/disable D-cache		$0400
;
;		r3.lo = which cache (L1/2)
;			level 1						1
;			level 2						2
;
;	RETURN VALUE (r3)
;		r3.hi = pre-change state flags (resemble action flags)
;			both caches disabled		$4000
;			either cache enabled		$8000
;			I-cache enabled				$0800
;			D-cache enabled				$0400
;
;		r3.lo = return status
;			success						0
;			failure						< 0
;			checked L1 but did not set	1
;			checked L2 but did not set	2

;	DeclareMPCall 199, kcCacheDispatch			; DEBUG

kcCacheDispatch

	_RegRangeToContextBlock r21, r23			; get some breathing room

;	_log	'kcCacheDispatch '					; DEBUG
;	mr		r8, r3								; DEBUG
;	bl		printw								; DEBUG
;	_log	'^n'								; DEBUG

	clrlwi	r8, r3, 16							; bad selector
	cmplwi	r8, 2
	bgt-	@fail_bad_selector

	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	andi.	r8, r8, 1 << NKProcessorInfo.hasL2CR
	beq-	CacheCallFailNoL2					; no L2CR => fail (what about 601?)

	rlwinm.	r9, r3, 0, 2, 2						; if flagged, get cache state in r23
	bnel-	CacheCallGetInfoForReturnValue		; (otherwise, r23 is undefined)

	srwi	r8, r3, 30							; cannot enable *and* disable
	cmpwi	r8, 3
	beq-	CacheCallFailBadFlags

	clrlwi	r8, r3, 16							; go to main code for level 1/2 cache
	cmplwi	r8, 1
	beq-	CacheCallDispatchL1
	cmplwi	r8, 2
	beq-	CacheCallDispatchL2

@fail_bad_selector								; fall through => bad selector
	lisori	r3, -2
	b		CacheCallReturn



  ### ##          ##   ###   
 ##   ##        ####     ##  
##    ##          ##      ## 
##    ##          ##      ## 
##    ##          ##      ## 
 ##   ##          ##     ##  
  ### ########  ###### ###   

CacheCallDispatchL1

	rlwinm.	r9, r3, 0, 1, 1
	bne-	CacheCallL1DisableSelected

	rlwinm.	r9, r3, 0, 0, 0
	bne-	CacheCallL1EnableSelected

	rlwinm.	r9, r3, 0, 3, 3						; ???

	bl		FlushCaches

	b		CacheCallReturn



CacheCallL1DisableSelected

	bl		FlushCaches

	rlwinm	r22, r3, 0, 4, 5					; shift arg bits to align with HID0[DCE/ICE]
	srwi	r22, r22, 12
	mfspr	r21, hid0
	andc	r21, r21, r22						; HID0 &= ~mybits
	sync
	mtspr	hid0, r21

	li		r3, 0
	b		CacheCallReturn



CacheCallL1EnableSelected

	rlwinm	r22, r3, 0, 4, 5					; shift arg bits to align with HID0[DCE/ICE]
	srwi	r22, r22, 12
	mfspr	r21, hid0
	or		r21, r21, r22						; HID0 |= mybits
	sync
	mtspr	hid0, r21

	li		r3, 0
	b		CacheCallReturn



  ### ##        #######  ###   
 ##   ##       ##     ##   ##  
##    ##              ##    ## 
##    ##        #######     ## 
##    ##       ##           ## 
 ##   ##       ##          ##  
  ### ######## ######### ###   

CacheCallDispatchL2

	rlwinm.	r9, r3, 0, 1, 1
	bne-	CacheCallL2DisableSelected

	rlwinm.	r9, r3, 0, 0, 0
	bne-	CacheCallL2EnableSelected

	rlwinm.	r9, r3, 0, 3, 3
	bne-	CacheCallL2Flag3					; goes to DisableSelected

	rlwinm.	r9, r3, 0, 2, 2
	;bne removed?

	bne-	CacheCallReturn



CacheCallFailBadFlags

	lisori	r3, -4
	b		CacheCallReturn



CacheCallL2Flag3

	bl		CacheCallL2DisableSelected			; typo? should be `b`



CacheCallL2EnableSelected

	mfspr	r21, l2cr							; fail if L2CR[L2E] already set
	sync
	andis.	r21, r21, 0x8000
	bne-	CacheCallReturn

	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.ProcessorL2DSize(r1)
	and.	r8, r8, r8
	beq-	CacheCallFailNoL2					; fail if zero-sized cache reported

	mfspr	r21, hid0							; save HID0

	rlwinm	r8, r21, 0, 12, 10					; clear HID0[DPM] (dynamic power management)
	mtspr	hid0, r8							; presumably to keep L2 working while we wait?
	sync

	addi	r8, r1, PSA.ProcessorState
	lwz		r8, NKProcessorState.saveL2CR(r8)
	and.	r8, r8, r8
	beq-	CacheCallReturn						; fail if zero L2CR was saved?
	sync

	lis		r9, 0x0020							; set L2CR[GI] (global invalidate)
	or		r8, r8, r9
	mtspr	l2cr, r8
	sync
@inval_loop
	mfspr	r8, l2cr							; check L2CR[IP] (invalidate progress)
	sync
	andi.	r9, r8, 1
	bne+	@inval_loop

	lis		r9, 0x0020							; clear L2CR[GI]
	andc	r8, r8, r9
	mtspr	l2cr, r8
	sync

	lis		r9, 0x8000							; set L2CR[L2E] (L2 enable)
	or		r8, r8, r9
	mtspr	l2cr, r8
	sync

	mtspr	hid0, r21							; restore HID0
	sync

	li		r3, 0								; return successfully
	b		CacheCallReturn



CacheCallFailNoL2

	li		r3, -2
	b		CacheCallReturn



CacheCallL2DisableSelected

	mfspr	r22, l2cr							; return if already disabled per L2CR[L2E]
	sync
	andis.	r22, r22, 0x8000
	beq-	CacheCallReturn

	bl		FlushCaches

	mfspr	r22, l2cr							; clear L2CR[L2E]
	sync
	clrlwi	r22, r22, 1
	mtspr	l2cr, r22
	sync

	addi	r8, r1, PSA.ProcessorState
	stw		r22, NKProcessorState.saveL2CR(r8)	; update saveL2CR
	sync

	rlwinm	r22, r22, 0, 7, 3					; clear L2CR[3/5/6] (all reserved)
	oris	r22, r22, 0x0010					; set L2CR[13] (also reserved)
	mtspr	l2cr, r22
	sync

	;b		CacheCallReturn						; fall through



  ### ########  ######## ######## ##     ## ########  ##    ## ###   
 ##   ##     ## ##          ##    ##     ## ##     ## ###   ##   ##  
##    ##     ## ##          ##    ##     ## ##     ## ####  ##    ## 
##    ########  ######      ##    ##     ## ########  ## ## ##    ## 
##    ##   ##   ##          ##    ##     ## ##   ##   ##  ####    ## 
 ##   ##    ##  ##          ##    ##     ## ##    ##  ##   ###   ##  
  ### ##     ## ########    ##     #######  ##     ## ##    ## ###   

CacheCallReturn

	ori		r23, r23, 0xffff		; put the r23.hi from CacheCallGetInfoForReturnValue into r3.hi
	oris	r3, r3, 0xffff
	and		r3, r3, r23

CacheCallReturnWithoutFlags
	_RegRangeFromContextBlock r21, r23
	sync

;	_log	'Return '				; DEBUG
;	mr		r8, r3					; DEBUG
;	bl		printw					; DEBUG
;	_log	'^n'					; DEBUG

	b		IntReturn



  ### ########  ########   #######  ########  ######## ###   
 ##   ##     ## ##     ## ##     ## ##     ## ##         ##  
##    ##     ## ##     ## ##     ## ##     ## ##          ## 
##    ########  ########  ##     ## ########  ######      ## 
##    ##        ##   ##   ##     ## ##     ## ##          ## 
 ##   ##        ##    ##  ##     ## ##     ## ##         ##  
  ### ##        ##     ##  #######  ########  ######## ###   

;	RET		r23.hi = flags describing state of specified cache (see top of file)

CacheCallGetInfoForReturnValue

	clrlwi	r8, r3, 16

	cmplwi	r8, 1
	beq-	@level1
	cmplwi	r8, 2
	beq-	@level2

	lisori	r3, -5
	b		CacheCallReturnWithoutFlags

@level1
	mfspr	r21, hid0
	rlwinm.	r21, r21, 12, 4, 5
	beq-	@all_off

	oris	r23, r21, 0x8000
	blr

@level2
	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.ProcessorL2DSize(r1)
	and.	r8, r8, r8
	beq+	CacheCallFailNoL2

	mfspr	r21, hid0				; same bits as above
	rlwinm	r21, r21, 12, 4, 5

	mfspr	r22, l2cr				; L2-D is on if L1-D is on and L2CR[DO] is cleared
	rlwinm	r22, r22, 5, 4, 4
	andc	r21, r21, r22

	mfspr	r22, l2cr				; then again, both L2s are off if L2CR[L2E] is cleared
	andis.	r22, r22, 0x8000
	beq-	@all_off

	or		r23, r21, r22
	blr

@all_off
	lisori	r23, 0x40000000
	blr



######## ##       ##     ##  ######  ##     ##    ######## ##     ## ##    ##  ######   ######  
##       ##       ##     ## ##    ## ##     ##    ##       ##     ## ###   ## ##    ## ##    ## 
##       ##       ##     ## ##       ##     ##    ##       ##     ## ####  ## ##       ##       
######   ##       ##     ##  ######  #########    ######   ##     ## ## ## ## ##        ######  
##       ##       ##     ##       ## ##     ##    ##       ##     ## ##  #### ##             ## 
##       ##       ##     ## ##    ## ##     ##    ##       ##     ## ##   ### ##    ## ##    ## 
##       ########  #######   ######  ##     ##    ##        #######  ##    ##  ######   ######  

;	Flush L1 and L2 caches
;	Also used by NKPowerCalls.s

;	ARG		KDP *r1, ContextBlock *r6
;	CLOB	r8, r9, cr

FlushCaches

;	blr										; DEBUG

	;	Be cautious

	mfctr	r8
	stw		r25, ContextBlock.r25(r6)
	stw		r24, ContextBlock.r24(r6)
	stw		r8, ContextBlock.KernelCTR(r6)


	;	Flush level 1

	lhz		r25, KDP.ProcessorInfo + NKProcessorInfo.DataCacheLineSize(r1)
	and.	r25, r25, r25					; r25 = L1-D line size
	cntlzw	r8, r25
	beq-	@return
	subfic	r9, r8, 31						; r9 = logb(L1-D line size)

	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.DataCacheTotalSize(r1)
	and.	r8, r8, r8						; r8 = L1-D size
	beq-	@return

	lwz		r24, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	mtcr	r24

	bc		BO_IF, 31 - NKProcessorInfo.hasMSSregs, @use_SPRs_to_invalidate
											; => go away to handle weird CPUs

	bc		BO_IF_NOT, 31 - NKProcessorInfo.hasPLRUL1, @no_pseudo_lru
	slwi	r24, r8, 1
	add		r8, r8, r24
	srwi	r8, r8, 1						; be generous with pseudo-LRU caches
@no_pseudo_lru

	srw		r8, r8, r9
	mtctr	r8								; loop counter = cache/line

	lwz		r8, KDP.PA_ConfigInfo(r1)		; fill the cache with Mac ROM
	lwz		r9, NKConfigurationInfo.ROMImageBaseOffset(r8)
	add		r8, r8, r9

@loop_L1
	lwzux	r9, r8, r25
	bdnz+	@loop_L1


	;	Flush level 2 (very similar to above)

	lwz		r24, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	andi.	r24, r24, 1 << NKProcessorInfo.hasL2CR
	beq-	@return							; return if L2CR unavailable

	mfspr	r24, l2cr
	andis.	r24, r24, 0x8000
	beq-	@return							; return if L2 off (per L2CR[L2E])

	lhz		r25, KDP.ProcessorInfo + NKProcessorInfo.ProcessorL2DBlockSize(r1)
	and.	r25, r25, r25					; r25 = L2-D line size
	cntlzw	r8, r25
	beq-	@return
	subfic	r9, r8, 31						; r9 = logb(L2-D line size)

	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.ProcessorL2DSize(r1)
	and.	r8, r8, r8						; r8 = L2-D size
	beq-	@return

	srw		r8, r8, r9
	mtctr	r8								; loop counter = cache/line

	mfspr	r24, l2cr						; set L2CR[DO] (disables L2-I)
	oris	r24, r24, 0x0040
	mtspr	l2cr, r24
	isync

	lwz		r8, KDP.PA_ConfigInfo(r1)		; fill the cache with Mac ROM
	lwz		r9, NKConfigurationInfo.ROMImageBaseOffset(r8)
	add		r8, r8, r9

	addis	r8, r8, 0x19					; start high in ROM and count backwards
	neg		r25, r25

@loop_L2
	lwzux	r9, r8, r25
	bdnz+	@loop_L2

	rlwinm	r24, r24, 0, 10, 8
	mtspr	l2cr, r24						; clear L2CR[DO] (reenables L2-I)
	isync


	;	Done (this return path is also called from the sneaky code below)

@return
	lwz		r8, ContextBlock.KernelCTR(r6)
	lwz		r25, ContextBlock.r25(r6)
	lwz		r24, ContextBlock.r24(r6)
	sync
	mtctr	r8
	blr


;	If "hasMSSregs" flag (my name) is set in ProcessorFlags, L1 and L2 can
;	instead be flushed by clobbering reserved bits in MSSCR0 and L2CR
;	respectively.

@use_SPRs_to_invalidate

	;	Flush level 1: set MSSCR0[8] and spin until it clears

	dssall									; AltiVec needs to know

	sync
	mfspr	r8, msscr0
	oris	r8, r8, 0x0080
	mtspr	msscr0, r8
	sync
@loop_msscr0
	mfspr	r8, msscr0
	sync
	andis.	r8, r8, 0x0080
	bne+	@loop_msscr0


	;	Flush level 2: set L2CR[4] and spin until it clears

	mfspr	r8, l2cr
	ori		r8, r8, 0x0800
	mtspr	l2cr, r8
	sync
@loop_l2cr
	mfspr	r8, l2cr
	sync
	andi.	r8, r8, 0x0800
	bne+	@loop_l2cr


	;	Jump back up to main code path to return

	b		@return



;	Called when we cop a machine check with the "L1 data cache error"
;	flag set in SRR1, followed by an interrupt return. Same trick as
;	above.

;	CLOB	r8, cr

FlushL1CacheUsingMSSCR0

	;	Return if MSSCR0 unavailable

	lwz		r8, KDP.ProcessorInfo + NKProcessorInfo.ProcessorFlags(r1)
	mtcr	r8
	bclr	BO_IF_NOT, 31-NKProcessorInfo.hasMSSregs


	;	Flush level 1: set MSSCR0[8] and spin until it clears

	dssall									; AltiVec needs to know

	sync
	mfspr	r8, msscr0
	oris	r8, r8, 0x0080
	mtspr	msscr0, r8
	sync
@loop_msscr0
	mfspr	r8, msscr0
	sync
	andis.	r8, r8, 0x0080
	bne+	@loop_msscr0

	blr
