;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKConsoleLog
;	    printw
;	  NKExceptions
;	    Exception
;	    IntReturn
;	    IntReturnToOtherBlueContext
;	  NKIndex
;	    LookupID
;	  NKInit
;	    ResetBuiltinKernel
;	  NKIntHandlers
;	    LoadInterruptRegisters
;	    MaskedInterruptTaken
;	    save_all_registers
;	  NKMPCalls
;	    kcMPDispatch
;	  NKPaging
;	    PagingL2PWithBATs
;	  NKScheduler
;	    Restore_v0_v31
;	    SchExitInterrupt
;	    SchRestoreStartingAtR14
;	    SchSaveStartingAtR14
;	    SchSwitchSpace
;	  NKSync
;	    CauseNotification
;	  NKTranslation
;	    FDPEmulateInstruction
;	EXPORTS:
;	  HandlePerfMonitorInt (=> NKInit)
;	  IgnoreSoftwareInt (=> NKInit, NKTranslation)
;	  IntExternalAlternate (=> NKInit)
;	  IntExternalSystem (=> NKInit)
;	  IntPerfMonitor (=> NKInit)
;	  IntProgram (=> NKInit)
;	  IntReturnFromSIGP (=> NKExceptions, NKIntHandlers)
;	  IntSyscall (=> NKInit)
;	  IntThermalEvent (=> NKInit)
;	  IntTrace (=> NKInit)
;	  SIGP (=> NKMPCalls, NKScheduler, NKSleep)
;	  kcPrioritizeInterrupts (=> NKInit)
;	  kcResetSystem (=> NKInit)
;	  kcRunAlternateContext (=> NKInit)
;	  kcThud (=> NKInit)
;	  major_0x046d0 (=> NKInit)
;	  major_0x04a20 (=> NKInit)
;	  wordfill (=> NKInit, NKPowerCalls)



major_0x04180	;	OUTSIDE REFERER
	stw		r6, -0x0290(r1)
	stw		r10, -0x028c(r1)
	stw		r11, -0x0288(r1)
	lwz		r6, -0x0014(r1)
	lwz		r10,  0x00d8(r6)
	mfspr	r11, srr1
	cmpwi	r10,  0x00
	beql	major_0x04180_0x9c
	oris	r11, r11,  0x200
	stw		r9, -0x027c(r1)
	mtspr	srr1, r11
	mfmsr	r11
	oris	r11, r11,  0x200
	mtmsr	r11
	isync
	bl		Restore_v0_v31
	lwz		r8, -0x0004(r1)
	lwz		r11,  0x0ed4(r8)
	addi	r11, r11,  0x01
	stw		r11,  0x0ed4(r8)
	mtcr	r13
	lwz		r6, -0x0290(r1)
	lwz		r10, -0x028c(r1)
	lwz		r11, -0x0288(r1)
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	lwz		r9, -0x027c(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0


major_0x04180_0x9c
	mtcr	r13
	lwz		r6, -0x0290(r1)
	lwz		r10, -0x028c(r1)
	lwz		r11, -0x0288(r1)
	lwz		r13, -0x0284(r1)


	bl		LoadInterruptRegisters

	li		r8, ecInvalidInstr
	b		Exception



###              ######                       #     #                                     
 #  #    # ##### #     # ###### #####  ###### ##   ##  ####  #    # # #####  ####  #####  
 #  ##   #   #   #     # #      #    # #      # # # # #    # ##   # #   #   #    # #    # 
 #  # #  #   #   ######  #####  #    # #####  #  #  # #    # # #  # #   #   #    # #    # 
 #  #  # #   #   #       #      #####  #      #     # #    # #  # # #   #   #    # #####  
 #  #   ##   #   #       #      #   #  #      #     # #    # #   ## #   #   #    # #   #  
### #    #   #   #       ###### #    # #      #     #  ####  #    # #   #    ####  #    # 

	align	kIntAlign

IntPerfMonitor	;	OUTSIDE REFERER
	mtlr	r1
	mfsprg	r1, 0
	stw		r8, -0x0280(r1)
	stw		r13, -0x0284(r1)
	mflr	r8
	mfcr	r13
	cmpwi	r8,  0xf20
	beq		major_0x04180
	mtcr	r13
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq		MaskedInterruptTaken

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, PSA.PMFHandlerID(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne		IntPerfMonitor_0x88
	lwz		r16, -0x0340(r28)
	lwz		r17, -0x0008(r28)
	stw		r16,  0x0010(r30)
	lwz		r16,  0x0000(r17)
	stw		r16,  0x0014(r30)
	mfspr	r16, 955
	stw		r16,  0x0018(r30)
	bl		CauseNotification

IntPerfMonitor_0x88
	_AssertAndRelease	PSA.SchLock, scratch=r8

;	r6 = ewa
	bl		SchRestoreStartingAtR14
	b		IntReturn



;	Notify the Thermal Handler

	align	kIntAlign

IntThermalEvent	;	OUTSIDE REFERER
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq		MaskedInterruptTaken
	_log	'Thermal event^n'

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, PSA.ThermalHandlerID(r1)
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	mr		r30, r8
	bne		@no_thermal_handler

	lwz		r16, EWA.CPUBase + CPU.ID(r28)
	stw		r16, Notification.MsgWord1(r30)
	bl		CauseNotification
@no_thermal_handler

	_AssertAndRelease	PSA.SchLock, scratch=r8
	bl		SchRestoreStartingAtR14
	b		IntReturn



              ######                   #                                                           #####                                          
#    #  ####  #     # #    # #    #   # #   #      ##### ###### #####  #    #   ##   ##### ###### #     #  ####  #    # ##### ###### #    # ##### 
#   #  #    # #     # #    # ##   #  #   #  #        #   #      #    # ##   #  #  #    #   #      #       #    # ##   #   #   #       #  #    #   
####   #      ######  #    # # #  # #     # #        #   #####  #    # # #  # #    #   #   #####  #       #    # # #  #   #   #####    ##     #   
#  #   #      #   #   #    # #  # # ####### #        #   #      #####  #  # # ######   #   #      #       #    # #  # #   #   #        ##     #   
#   #  #    # #    #  #    # #   ## #     # #        #   #      #   #  #   ## #    #   #   #      #     # #    # #   ##   #   #       #  #    #   
#    #  ####  #     #  ####  #    # #     # ######   #   ###### #    # #    # #    #   #   ######  #####   ####  #    #   #   ###### #    #   #   

;	We can assume that this is being called from the emulator

;	We accept a logical NCB ptr but the kernel needs a physical one.
;	So we keep a four-entry cache in KDP, mapping logical NCB ptrs
;	to physical ones. But when are there multiple alt contexts?

;	ARG		flags? r3, mask r4

	align	kIntAlign

kcRunAlternateContext

	mtcrf	0x3f, r7

	bcl		BO_IF_NOT, EWA.kFlagBlue, IntReturn

	and.	r8, r4, r13
	lwz		r9, KDP.NCBCacheLA0(r1)
	rlwinm	r8, r3, 0, 0, 25
	cmpw	cr1, r8, r9
	bne		IntReturn
	lwz		r9, KDP.NCBCachePA0(r1)
	bne		cr1, @search_cache


@found_physical_in_cache ; can come here from below after a more thorough search

	addi	r8, r1, KDP.VecBaseAlternate ; the only use of this vector table?
	mtsprg	3, r8

	lwz		r8, KDP.LA_EmulatorKernelTrapTable(r1)
	mtcrf	0x3f, r7
	mfsprg	r1, 0
	clrlwi	r7, r7, 8
	stw		r8, ContextBlock.LA_EmulatorKernelTrapTable(r9)

	stw		r9, EWA.PA_ContextBlock(r1)

	b		IntReturnToOtherBlueContext


@search_cache

	lwz		r9, KDP.NCBCacheLA1(r1)
	cmpw	cr1, r8, r9
	beq		cr1, @found_in_slot_1

	lwz		r9, KDP.NCBCacheLA2(r1)
	cmpw	cr1, r8, r9
	beq		cr1, @found_in_slot_2

	lwz		r9, KDP.NCBCacheLA3(r1)
	cmpw	cr1, r8, r9
	beq		cr1, @found_in_slot_3


	;	No luck with the cache

	mfsprg	r1, 0
	stmw	r14, EWA.r14(r1)
	lwz		r1, EWA.PA_KDP(r1)

	cmpw	cr1, r8, r6
	beq		cr1, @fail

	mr		r27, r8
	addi	r29, r1, KDP.BATs + 0xa0
	bl		PagingL2PWithBATs
	clrlwi	r23, r8, 20
	beq		@fail

	cmplwi	r23, 0x0d00
	mr		r9, r8
	mr		r8, r31
	ble		@not_straddling_pages

	addi	r27, r27, 0x1000
	addi	r29, r1, KDP.BATs + 0xa0
	bl		PagingL2PWithBATs
	beq		@fail

	subi	r31, r31, 0x1000
	xor		r23, r8, r31
	rlwinm.	r23, r23, 0, 25, 22
	bne		@fail ; because physical pages are discontiguous
@not_straddling_pages

	clrlwi	r23, r31, 30
	cmpwi	r23, 3
	rlwimi	r8, r9, 0, 20, 31
	beq		@fail


	;	Found a non-cached physical address for this NCB!

	lwz		r23, KDP.NanoKernelInfo + NKNanoKernelInfo.NCBPtrCacheMissCount(r1)
	addi	r23, r23, 1
	stw		r23, KDP.NanoKernelInfo + NKNanoKernelInfo.NCBPtrCacheMissCount(r1)


	;	Stick it in cache slot 3

	mfsprg	r1, 0
	lmw		r14, EWA.r14(r1)
	lwz		r1, EWA.PA_KDP(r1)
	stw		r8, KDP.NCBCachePA3(r1)


@found_in_slot_3 ; so promote to slot 2

	lwz		r8, KDP.NCBCacheLA2(r1)
	stw		r9, KDP.NCBCacheLA2(r1)
	stw		r8, KDP.NCBCacheLA3(r1)

	lwz		r9, KDP.NCBCachePA3(r1)
	lwz		r8, KDP.NCBCachePA2(r1)
	stw		r9, KDP.NCBCachePA2(r1)
	stw		r8, KDP.NCBCachePA3(r1)

	lwz		r9, KDP.NCBCacheLA2(r1)


@found_in_slot_2 ; so promote to slot 1

	lwz		r8, KDP.NCBCacheLA1(r1)
	stw		r9, KDP.NCBCacheLA1(r1)
	stw		r8, KDP.NCBCacheLA2(r1)

	lwz		r9, KDP.NCBCachePA2(r1)
	lwz		r8, KDP.NCBCachePA1(r1)
	stw		r9, KDP.NCBCachePA1(r1)
	stw		r8, KDP.NCBCachePA2(r1)

	lwz		r9, KDP.NCBCacheLA1(r1)


@found_in_slot_1 ; so promote to slot 0, save elsewhere, and push on

	lwz		r8, KDP.NCBCacheLA0(r1)
	stw		r9, KDP.NCBCacheLA0(r1)
	stw		r9, KDP.LA_NCB(r1)
	stw		r8, KDP.NCBCacheLA1(r1)

	lwz		r9, KDP.NCBCachePA1(r1)
	lwz		r8, KDP.NCBCachePA0(r1)
	stw		r9, KDP.NCBCachePA0(r1)
	stw		r8, KDP.NCBCachePA1(r1)

	b		@found_physical_in_cache


@fail

	mfsprg	r1, 0
	lmw		r14, EWA.r14(r1)
	lwz		r1, EWA.PA_KDP(r1)
	li		r8, ecTrapInstr
	b		Exception



;	> r8    = dest
;	> r22   = len in bytes
;	> r23   = fillword

wordfill	;	OUTSIDE REFERER
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne		wordfill
	blr



              ######                              #####                                   
#    #  ####  #     # ######  ####  ###### ##### #     # #   #  ####  ##### ###### #    # 
#   #  #    # #     # #      #      #        #   #        # #  #        #   #      ##  ## 
####   #      ######  #####   ####  #####    #    #####    #    ####    #   #####  # ## # 
#  #   #      #   #   #           # #        #         #   #        #   #   #      #    # 
#   #  #    # #    #  #      #    # #        #   #     #   #   #    #   #   #      #    # 
#    #  ####  #     # ######  ####  ######   #    #####    #    ####    #   ###### #    # 

;	Handle a 68k reset trap.

;	If A0(r3)/A1(r4) == 'Gary'/$05051955, load the register list in A3? Or is this now disabled?

;	New SRR0 = SRR0 & ~r5(D0) | r7(D2)

	align	kIntAlign

kcResetSystem	;	OUTSIDE REFERER
;	r6 = ewa
	bl		SchSaveStartingAtR14
;	r8 = sprg0 (not used by me)

	;	Check for 601 (rtc vs timebase)
	mfpvr	r9
	rlwinm.	r9, r9, 0,  0, 14

	;	This xoris/cmplwi technique is very cool
	xoris	r8, r3, 'Ga'

	beq		@is_601
	mftb	r9
	b		@endif_601
@is_601
	dialect	POWER
	mfrtcl	r9
	dialect	PowerPC
@endif_601

	;	Not sure why this would need to hit cr0?
	andis.	r9, r9,  0xffff

	cmplwi	r8, 'ry'
	bne		NonGaryReset

	;	r4 (i.e. A1) == 5 May 1956?
	xoris	r8, r4, 0x0505
	cmplwi	r8,     0x1956
	bne		NonGaryReset

	andc	r11, r11, r5
	lwz		r8, ContextBlock.r7(r6)
	or		r11, r11, r8

	_log	'Skeleton key inserted at'

	mr		r8, r11
	bl		Printw

	mr		r8, r10
	bl		Printw

	_log	'^n'
	
	b		IntReturn



;	                NonGaryReset

;	A 68k reset trap without Gary Davidian's magic numbers.

NonGaryReset

	_log	'ResetSystem trap entered^n'

	lwz		r8, KDP.OldKDP(r1)

	cmpwi	r8, 0
	beq		ResetBuiltinKernel

	_log	'Unplugging the replacement nanokernel^n'

	lwz		r8, KDP.OldKDP(r1)
	mfsprg	r1, 0
	addi	r9, r8, KDP.VecBaseSystem
	mtsprg	0, r8		;	old NK has only one EWA!
	mtsprg	3, r9

	lwz		r9, EWA.r1(r1)
	stw		r9, EWA.r1(r8)

	lwz		r9, EWA.r6(r1)
	stw		r9, EWA.r6(r8)

	stw		r6,  0x065c(r8)
	stw		r7,  0x0660(r8)			; ??????????

	lwz		r9, EWA.Enables(r1)
	stw		r9,  0x0664(r8)

;	r6 = ewa
	bl		SchRestoreStartingAtR14
	subi	r10, r10, 4
	lwz		r1, -0x0004(r1)

;	sprg0 = for r1 and r6
;	r1 = kdp
;	r6 = register restore area
;	r7 = flag to insert into XER
;	r10 = new srr0 (return location)
;	r11 = new srr1
;	r12 = lr restore
;	r13 = cr restore
	b		SchExitInterrupt



              ######                                                 ###                                                              
#    #  ####  #     # #####  #  ####  #####  # ##### # ###### ######  #  #    # ##### ###### #####  #####  #    # #####  #####  ####  
#   #  #    # #     # #    # # #    # #    # #   #   #     #  #       #  ##   #   #   #      #    # #    # #    # #    #   #   #      
####   #      ######  #    # # #    # #    # #   #   #    #   #####   #  # #  #   #   #####  #    # #    # #    # #    #   #    ####  
#  #   #      #       #####  # #    # #####  #   #   #   #    #       #  #  # #   #   #      #####  #####  #    # #####    #        # 
#   #  #    # #       #   #  # #    # #   #  #   #   #  #     #       #  #   ##   #   #      #   #  #   #  #    # #        #   #    # 
#    #  ####  #       #    # #  ####  #    # #   #   # ###### ###### ### #    #   #   ###### #    # #    #  ####  #        #    ####  

;	> r1    = kdp

kcPrioritizeInterrupts	;	OUTSIDE REFERER
	lwz		r9, KDP.PA_InterruptHandler(r1)
	mtlr	r9
	blr



;	Move registers from CB to EWA, and Thud.

	align	kIntAlign

kcThud

	stw		r2, EWA.r2(r1)
	stw		r3, EWA.r3(r1)
	stw		r4, EWA.r4(r1)
	stw		r5, EWA.r5(r1)

	lwz		r8, ContextBlock.r7(r6)
	lwz		r9, ContextBlock.r8(r6)
	stw		r8, EWA.r7(r1)
	stw		r9, EWA.r8(r1)

	lwz		r8, ContextBlock.r9(r6)
	lwz		r9, ContextBlock.r10(r6)
	stw		r8, EWA.r9(r1)
	stw		r9, EWA.r10(r1)

	lwz		r8, ContextBlock.r11(r6)
	lwz		r9, ContextBlock.r12(r6)
	stw		r8, EWA.r11(r1)
	stw		r9, EWA.r12(r1)

	lwz		r8, ContextBlock.r13(r6)
	stw		r8, EWA.r13(r1)

	stmw	r14, EWA.r14(r1)

	bl		IntPanicIsland



major_0x046d0	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	li		r8, ecTrapInstr
	b		Exception



###              #######                                                    #                                                          
 #  #    # ##### #       #    # ##### ###### #####  #    #   ##   #        # #   #      ##### ###### #####  #    #   ##   ##### ###### 
 #  ##   #   #   #        #  #    #   #      #    # ##   #  #  #  #       #   #  #        #   #      #    # ##   #  #  #    #   #      
 #  # #  #   #   #####     ##     #   #####  #    # # #  # #    # #      #     # #        #   #####  #    # # #  # #    #   #   #####  
 #  #  # #   #   #         ##     #   #      #####  #  # # ###### #      ####### #        #   #      #####  #  # # ######   #   #      
 #  #   ##   #   #        #  #    #   #      #   #  #   ## #    # #      #     # #        #   #      #   #  #   ## #    #   #   #      
### #    #   #   ####### #    #   #   ###### #    # #    # #    # ###### #     # ######   #   ###### #    # #    # #    #   #   ###### 

;	For when the alternate context is running?

	align	kIntAlign

IntExternalAlternate

	bl		LoadInterruptRegisters
	mtcrf	0x3f, r7
	bcl		BO_IF_NOT, EWA.kFlagBlue, IntPanicIsland
	li		r8, ecNoException
	b		Exception



###              ######                                            
 #  #    # ##### #     # #####   ####   ####  #####    ##   #    # 
 #  ##   #   #   #     # #    # #    # #    # #    #  #  #  ##  ## 
 #  # #  #   #   ######  #    # #    # #      #    # #    # # ## # 
 #  #  # #   #   #       #####  #    # #  ### #####  ###### #    # 
 #  #   ##   #   #       #   #  #    # #    # #   #  #    # #    # 
### #    #   #   #       #    #  ####   ####  #    # #    # #    # 

	align	kIntAlign

IntProgram

	bl		LoadInterruptRegisters

	lwz		r8, KDP.LA_EmulatorKernelTrapTable(r1)
	mtcr	r11						; UNUSUAL to have SRR1 in condition register
	xor		r8, r10, r8
	bc		BO_IF_NOT, 14, @not_trap


	;	Program interrupt caused by a trap instruction


	;	From the table of twis in the emulator code image? Then return will be to LR.

	cmplwi	cr0, r8, NanoKernelCallTable.ReturnFromException
	cmplwi	cr1, r8, NanoKernelCallTable.MPDispatch
	beq		cr0, @emutrap_0_return_from_exception
	beq		cr1, @emutrap_8_mpdispatch
	cmplwi	cr0, r8, NanoKernelCallTable.VMDispatch
	cmplwi	cr1, r8, NanoKernelCallTable.Size
	beq		cr0, @emutrap_3_vmdispatch
	blt		cr1, @emutrap_other


	;	Not from the emulator image? Return will be to next instruction,
	;	and we will read the trap instruction from memory

	;	If !MSR[IR], turn on MSR[DR] for just a moment
	bc		BO_IF_NOT, 26, @_IntProgram_0x58
	stw		r14, ContextBlock.r14(r6)
	mfsprg	r14, 3
	addi	r8, r1, PSA.VecBasePIH
	mfmsr	r9
	mtsprg	3, r8
	_bset	r8, r9, 27				; turn on data paging (MSR[DR]) for just a sec
	mtmsr	r8
	isync
@_IntProgram_0x58

	;	Get the offending instruction!
	lwz		r8, 0(r10)

	;	If !MSR[IR], restore MSR
	bc		BO_IF_NOT, 26, @_IntProgram_0x74
	isync
	mtmsr	r9
	isync
	mtsprg	3, r14
	lwz		r14, ContextBlock.r14(r6)
@_IntProgram_0x74


	;	Switch from SRR1-in-CR to Flags-in-CR

	mtcr	r7


	;	Read the bottom half of the non-emu-image trap instruction, getting trapnum*8 in r8
	xoris	r8, r8, 0xfff
	cmplwi	cr0, r8, NanoKernelCallTable.Size / 4
	cmplwi	cr1, r8, NanoKernelCallTable.ReturnFromException / 4
	bge		cr0, @trap_too_high
	cmplwi	cr7, r8, NanoKernelCallTable.MPDispatch / 4
	cmplwi	cr0, r8, NanoKernelCallTable.VMDispatch / 4
	slwi	r8, r8, 2
	beq		cr1, @nonemu_return_from_exception
	beq		cr7, @nonemu_mpdispatch
	beq		cr0, @nonemu_vmdispatch

	;	Fall through to some hard truths
	bc		BO_IF, 16, @_IntProgram_0x150
	bc		BO_IF, 8, @_IntProgram_0xac
	bc		BO_IF_NOT, 9, @_IntProgram_0x150

@nonemu_return_from_exception
@nonemu_vmdispatch
@_IntProgram_0xac
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9,  1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)

@nonemu_go
	lwz		r8, KDP.NanoKernelCallTable(r8)
	mtlr	r8
	addi	r10, r10, 4
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlagBE into EWA.kFlag26
	blr

@nonemu_mpdispatch
	lwz		r9, ContextBlock.r0(r6)
	add		r8, r8, r1
	cmpwi	r9, -1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	bne		@nonemu_go

	;	Non-emu MPDispatch trap with r0 == -1: muck around a bit?
	addi	r10, r10, 4
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlagBE into EWA.kFlag26
	mfsprg	r8, 0
	rlwimi	r13, r7, 8, 2, 2
	lwz		r9, EWA.PA_CurTask(r8)
	xoris	r13, r13,  0x2000
	lwz		r8, Task.SomeLabelField(r9)
	stw		r8, ContextBlock.r0(r6)
	b		IntReturn


@emutrap_other
@_IntProgram_0x110
	mtcr	r7
	bc		BO_IF, 16, @_IntProgram_0x150
	bc		BO_IF, 8, @_IntProgram_0x120
	bc		BO_IF_NOT, 9, @_IntProgram_0x150

@emutrap_0_return_from_exception
@emutrap_8_mpdispatch
@emutrap_3_vmdispatch
@_IntProgram_0x120
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	lwz		r10, KDP.NanoKernelCallTable(r8)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	mtlr	r10
	mr		r10, r12								; return to whatever the emulator left in the PPC link register
	rlwimi	r7, r7, 27, 26, 26
	blr


	;	Program interrupt not caused by a trap instruction: consult SRR1 bits 11-13

@not_trap
	bc		BO_IF+1, 12, FDPEmulateInstruction		; illegal instruction exception
	bc		BO_IF,   13, FDPEmulateInstruction		; privileged instruction exception
	bc		BO_IF,   11, @floating_point_exception	; floating point exception

@trap_too_high
@_IntProgram_0x150
	rlwinm	r8, r11, 17, 28, 29						; whoa
	addi	r8, r8,  0x4b3
	rlwnm	r8, r8, r8, 28, 31
	b		Exception

@floating_point_exception
	li		r8, ecFloatException

	bc		BO_IF, 15, Exception			; if SRR0 points to subsequent instr
	addi	r10, r10, 4								; if SRR0 points to offending instr
	rlwimi	r7, r7, 27, 26, 26						; copy EWA.kFlagBE into EWA.kFlag26
	b		Exception



	align	kIntAlign

IntExternalSystem

	bl		LoadInterruptRegisters


	;	Sanity check

	rlwinm.	r9, r11, 0, MSR_EEbit, MSR_EEbit
	beq		MaskedInterruptTaken


	;	How many CPUs?

	lwz		r9, EWA.CPUBase + CPU.LLL + LLL.Freeform(r8)
	lwz		r9, CoherenceGroup.CpuCount(r9)
	cmpwi	r9, 2


	;	Uniprocessor machine: go straight to PIH

	blt		kcPrioritizeInterrupts


	;	Check with the CPU plugin whether this is an interprocessor interrupt
	;	(i.e. an alert to flag a scheduler evaluation)

	bl		SchSaveStartingAtR14

	li		r9, kSIGP9
	stw		r9, EWA.SIGPSelector(r8)
	li		r8, 1						;	args are in EWA
	bl		SIGP
	bl		SchRestoreStartingAtR14

	cmpwi	cr0, r8, -29278				;	real external interrupt
	cmpwi	cr1, r8, -29277				;	ignore
	cmpwi	cr2, r8, -29279				;	interprocessor interrupt!
										;	else: real external interrupt

	beq		cr0, kcPrioritizeInterrupts
	beq		cr1, IntReturn
	bne		cr2, kcPrioritizeInterrupts
	
	mfsprg	r9, 0						;	"alert" => run scheduler evaluation
	li		r8, 1
	stb		r8, EWA.SchEvalFlag(r9)
	b		IntReturn					;	goes to SchReturn



 #####  ###  #####  ######  
#     #  #  #     # #     # 
#        #  #       #     # 
 #####   #  #  #### ######  
      #  #  #     # #       
#     #  #  #     # #       
 #####  ###  #####  #       

;	"SIGnal Plugin": Call the CPU plugin PEF bundle synchronously.
;	(blue address space but in supervisor mode without interrupts)

;	ARG:

;	if r8 == 0, i.e. userspace MPCpuPlugin call:
;		r3 => routine selector
;		executing CPU index => r3
;		r4-10 => r4-10

;	if r8 != 0, i.e. internal NanoKernel call:
;		EWA.SIGPSelector => routine selector
;		executing CPU index => r3
;		PlugCallR4-10 => r4-10

;	For most NK SIGPs, r4 contains the index of the CPU being operated on

	align	5

SIGP

	mfsprg	r23, 0
	mtcr	r7

	;	r20 = offset into CPU plugin dispatch table = routine number * 4
	;
	lwz		r16, EWA.PA_CurAddressSpace(r23)
	slwi	r20, r3, 2
	stw		r16, EWA.SIGPSpacOnResume(r23)
	bc		BO_IF, EWA.kFlagSIGP, IntReturnFromSIGP			; not sure about this
	cmpwi	cr2, r8, 0
	lwz		r18, EWA.SIGPSelector(r23)
	beq		cr2, @args_in_registers
	slwi	r20, r18, 2
@args_in_registers

	;	Check that a CPU plugin is installed and that the
	;	plugin dispatch table includes this command number.
	lwz		r22, EWA.CPUBase + CPU.LLL + LLL.Freeform(r23)
	li		r8, -0x7266
	lwz		r17, CoherenceGroup.PA_CpuPluginDesc(r22)
	lwz		r16, CoherenceGroup.CpuPluginSelectorCount(r22)
	mr.		r17, r17
	beqlr
	slwi	r16, r16,  2
	li		r8, -0x7267
	cmplw	r20, r16
	bgelr

	;	Save some registers in advance of this unusual "upcall".
	stw		r10, EWA.SIGPSavedR10(r23)
	stw		r11, EWA.SIGPSavedR11(r23)
	stw		r12, EWA.SIGPSavedR12(r23)
	stw		r13, EWA.SIGPSavedR13(r23)
	mfxer	r16
	mfctr	r17
	stw		r16, EWA.SIGPSavedXER(r23)
	mflr	r16
	stw		r17, EWA.SIGPSavedCTR(r23)
	stw		r16, EWA.SIGPSavedLR(r23)	; obviously this is getting revisited somewhere
	stw		r6, EWA.SIGPSavedR6(r23)
	stw		r7, EWA.SIGPSavedR7(r23)

	;	Change to the CPU plugin's preferred address space.
	lwz		r9, EWA.PA_CurAddressSpace(r23)
	lwz		r8, CoherenceGroup.CpuPluginSpacePtr(r22)
	cmpw	r9, r8
	beq		@noNeedToSwitchSpace
	bl		SchSwitchSpace
@noNeedToSwitchSpace

	;	Save user registers to ContextBlock (odd way to do this).
	lwz		r16, EWA.r1(r23)
	lwz		r17, EWA.r6(r23)
	stw		r16, ContextBlock.r1(r6)
	stw		r2, ContextBlock.r2(r6)
	stw		r3, ContextBlock.r3(r6)
	stw		r4, ContextBlock.r4(r6)
	stw		r5, ContextBlock.r5(r6)
	stw		r17, ContextBlock.r6(r6)

	;	Return address for CPU plugin code (=> twi 31, r31, 0 => kcReturnFromException)
	lwz		r17, KDP.LA_EmulatorKernelTrapTable + NanoKernelCallTable.ReturnFromException(r1)

	;	Need CPU index to look up the CPU plugin stack pointer in a table
	lhz		r16, EWA.CPUIndex(r23)

	;	MSR for CPU plugin with EE (external ints) and PR (problem state) switched off
	lwz		r19, PSA.UserModeMSR(r1)
	slwi	r16, r16, 2
	rlwinm	r19, r19, 0, 18, 15

	;	SRR0 (=> program counter) = TOC[routine_idx][first long]
	;	r1 (stack ptr) = stackPtrs[cpu_idx]
	;	r2 (RTOC) = TOC[routine_idx][second long]
	lwz		r8, CoherenceGroup.PA_CpuPluginTOC(r22)
	lwz		r9, CoherenceGroup.PA_CpuPluginStackPtrs(r22)
	lwzx	r20, r8, r20
	lwz		r18, 0(r20)
	mtlr	r17
	mtspr	srr0, r18
	mtspr	srr1, r19
	lwzx	r1, r9, r16
	lwz		r2, 4(r20)

	;	r3 (first arg) = CPU index
	srwi	r3, r16, 2

	;	Flags |= 0x8000
	_bset	r7, r7, EWA.kFlagSIGP
	mr		r16, r6
	stw		r7, EWA.Flags(r23)

	;	Not sure where this ContextBlock comes from?
	addi	r6, r23, -0x318
	stw		r6, EWA.PA_ContextBlock(r23)

	beq		cr2, @args_in_registers_2

;args not in registers
	lwz		r4, EWA.SIGPCallR4(r23)
	lwz		r5, EWA.SIGPCallR5(r23)
	lwz		r6, EWA.SIGPCallR6(r23)
	lwz		r7, EWA.SIGPCallR7(r23)
	lwz		r8, EWA.SIGPCallR8(r23)
	lwz		r9, EWA.SIGPCallR9(r23)
	lwz		r10, EWA.SIGPCallR10(r23)

	;	Go.
	rfi

@args_in_registers_2
	lwz		r6, ContextBlock.r6(r16)
	lwz		r7, ContextBlock.r7(r16)
	lwz		r8, ContextBlock.r8(r16)
	lwz		r9, ContextBlock.r9(r16)
	lwz		r10, ContextBlock.r10(r16)

	;	Go.
	rfi



major_0x04a20

	mfsprg	r23, 0
	lwz		r6, -0x0014(r23)
	lwz		r7, -0x0010(r23)
	lwz		r1, -0x0004(r23)
	mfspr	r10, srr0
	mfspr	r11, srr1



IntReturnFromSIGP

	mfsprg	r23, 0
	lwz		r7, EWA.SIGPSavedR7(r23)
	andis.	r8, r11, 0x0002						; MSR bit 14??
	stw		r7, -0x0010(r23)
	bne		@msr_14_set
	li		r3, -29285
@msr_14_set

	;	Restore address space
	lwz		r8, EWA.SIGPSpacOnResume(r23)
	lwz		r9, EWA.PA_CurAddressSpace(r23)
	cmpw	r9, r8
	beq		@no_switch_space
	bl		SchSwitchSpace
@no_switch_space

	lwz		r10, EWA.SIGPSavedR10(r23)
	lwz		r11, EWA.SIGPSavedR11(r23)
	lwz		r12, EWA.SIGPSavedR12(r23)
	lwz		r13, EWA.SIGPSavedR13(r23)
	lwz		r8, EWA.SIGPSavedXER(r23)
	lwz		r9, EWA.SIGPSavedCTR(r23)
	mtxer	r8
	lwz		r8, EWA.SIGPSavedLR(r23)
	lwz		r6, EWA.SIGPSavedR6(r23)
	mtctr	r9
	stw		r6, EWA.PA_ContextBlock(r23)
	mtlr	r8
	mr		r8, r3
	mr		r9, r4
	lwz		r16, ContextBlock.r1(r6)
	lwz		r2, ContextBlock.r2(r6)
	lwz		r3, ContextBlock.r3(r6)
	lwz		r4, ContextBlock.r4(r6)
	lwz		r5, ContextBlock.r5(r6)
	lwz		r17, ContextBlock.r6(r6)
	stw		r16, EWA.r1(r23)
	stw		r17, EWA.r6(r23)

	blr



###               #####                                           
 #  #    # ##### #     # #   #  ####   ####    ##   #      #      
 #  ##   #   #   #        # #  #      #    #  #  #  #      #      
 #  # #  #   #    #####    #    ####  #      #    # #      #      
 #  #  # #   #         #   #        # #      ###### #      #      
 #  #   ##   #   #     #   #   #    # #    # #    # #      #      
### #    #   #    #####    #    ####   ####  #    # ###### ###### 

;	                       IntSyscall

;	Not fully sure about this one

IntSyscall	;	OUTSIDE REFERER

	;	Only r1 and LR have been saved, so these compares clobber cr0

	cmpwi	r0, -3
	bne		@not_minus_3

	;	sc -3: used by FDP to go back to supervisor mode after instruction emulation.
	;	For security reasons, FDP goes into user mode when it emulates loads and stores.
	;	This is how it goes back into supervisor mode afterwards. During instruction emulation
	;	it has data paging on, but keeps instruction paging off. User Mode code never has instruction
	;	paging disabled, so this is not a privilege escalation.

		;	unset MSR_PR bit
		mfspr	r1, srr1
		rlwinm.	r0, r1, 26, 26, 27	;move MSR_IR bit to sign bit (and a few others that don't matter)
		_bclr	r1, r1, 17
		blt		@not_in_FDP		; only do if MSR_IR = 0 (MSR_IR is sign bit, so it is < 0 if it is true)
		mtspr	srr1, r1
	@not_in_FDP

		;	restore LR from SPRG2, r1 from SPRG1
		mfsprg	r1, 2
		mtlr	r1
		mfsprg	r1, 1

		rfi

@not_minus_3
	cmpwi	r0, -1
	mfsprg	r1, 0
	bne		@not_minus_1

	;	sc -1: quick-test whether "this task" is blue (cr0.eq if not blue)

		lwz		r0, EWA.Flags(r1)
		mfsprg	r1, 2
		rlwinm.	r0, r0, 0, EWA.kFlagBlue, EWA.kFlagBlue
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_minus_1
	cmpwi	r0, -2
	bne		@not_any_special

	;	sc -2: more flag nonsense?

		lwz		r0, EWA.Flags(r1)
		lwz		r1, -0x0008(r1)
		rlwinm.	r0, r0,  0, 10, 10
		lwz		r0,  0x00ec(r1)
		mfsprg	r1, 2
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_any_special
	
	;	Positive numbered syscalls are a fast path to MPDispatch (twi 31, r31, 8)

	bl		LoadInterruptRegisters			;	Save the usual suspects and get comfy

	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 32(r1)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 8*4(r1)

	;	Not sure what to make of these
	_bset	r11, r11, 14
	rlwimi	r7, r7, 27, 26, 26

	b		kcMPDispatch



###              #######                             
 #  #    # #####    #    #####    ##    ####  ###### 
 #  ##   #   #      #    #    #  #  #  #    # #      
 #  # #  #   #      #    #    # #    # #      #####  
 #  #  # #   #      #    #####  ###### #      #      
 #  #   ##   #      #    #   #  #    # #    # #      
### #    #   #      #    #    # #    #  ####  ###### 

	align	kIntAlign

IntTrace	;	OUTSIDE REFERER

	bl		LoadInterruptRegisters

	li		r8, ecInstTrace
	b		Exception



###                                     #####                                                  ###              
 #   ####  #    #  ####  #####  ###### #     #  ####  ###### ##### #    #   ##   #####  ######  #  #    # ##### 
 #  #    # ##   # #    # #    # #      #       #    # #        #   #    #  #  #  #    # #       #  ##   #   #   
 #  #      # #  # #    # #    # #####   #####  #    # #####    #   #    # #    # #    # #####   #  # #  #   #   
 #  #  ### #  # # #    # #####  #            # #    # #        #   # ## # ###### #####  #       #  #  # #   #   
 #  #    # #   ## #    # #   #  #      #     # #    # #        #   ##  ## #    # #   #  #       #  #   ##   #   
###  ####  #    #  ####  #    # ######  #####   ####  #        #   #    # #    # #    # ###### ### #    #   #   

	align	kIntAlign

IgnoreSoftwareInt	;	OUTSIDE REFERER
	mfspr	r1, srr0
	addi	r1, r1,  0x04
	mtspr	srr0, r1
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




#     #                                    ######                       #     #                                     ###              
#     #   ##   #    # #####  #      ###### #     # ###### #####  ###### ##   ##  ####  #    # # #####  ####  #####   #  #    # ##### 
#     #  #  #  ##   # #    # #      #      #     # #      #    # #      # # # # #    # ##   # #   #   #    # #    #  #  ##   #   #   
####### #    # # #  # #    # #      #####  ######  #####  #    # #####  #  #  # #    # # #  # #   #   #    # #    #  #  # #  #   #   
#     # ###### #  # # #    # #      #      #       #      #####  #      #     # #    # #  # # #   #   #    # #####   #  #  # #   #   
#     # #    # #   ## #    # #      #      #       #      #   #  #      #     # #    # #   ## #   #   #    # #   #   #  #   ##   #   
#     # #    # #    # #####  ###### ###### #       ###### #    # #      #     #  ####  #    # #   #    ####  #    # ### #    #   #   

	align	kIntAlign

HandlePerfMonitorInt	;	OUTSIDE REFERER
	mfspr	r1, srr1
	oris	r1, r1,  0x200
	mtspr	srr1, r1
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0
