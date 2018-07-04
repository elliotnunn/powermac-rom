;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKConsoleLog
;	    printw
;	  NKIndex
;	    DeleteID
;	    GetNextIDOfClass
;	    LookupID
;	    MakeID
;	  NKMPCalls
;	    CommonMPCallReturnPath
;	    ReleaseAndMPCallWasBad
;	    ReleaseAndReturnMPCall
;	    ReleaseAndReturnMPCallInvalidIDErr
;	    ReleaseAndReturnMPCallOOM
;	    ReleaseAndReturnMPCallPrivilegedErr
;	    ReleaseAndReturnParamErrFromMPCall
;	    ReleaseAndReturnZeroFromMPCall
;	    ReleaseAndScrambleMPCall
;	    ReturnMPCallInvalidIDErr
;	    ReturnMPCallOOM
;	    ReturnParamErrFromMPCall
;	    ReturnZeroFromMPCall
;	    major_0x0b0cc
;	  NKPoolAllocator
;	    PoolAllocClear
;	    PoolFree
;	  NKSync
;	    CauseNotification
;	    SetEvent
;	  NKThud
;	    panic
;	EXPORTS:
;	  CreateArea (=> NKVMCalls)
;	  CreateAreasFromPageMap (=> NKInit)
;	  DeletePTE (=> NKVMCalls)
;	  FindAreaAbove (=> NKIntHandlers, NKPaging, NKTasks, NKVMCalls)
;	  FreePageListPush (=> NKInit)
;	  GetPTEFromPLE (=> NKVMCalls)
;	  InitFreePageList (=> NKInit)
;	  InvalPTE (=> NKVMCalls)
;	  MPCall_95_0x254 (=> NKPaging)
;	  NKCreateAddressSpaceSub (=> NKInit)
;	  SetPTE (=> NKVMCalls)
;	  SpaceGetPagePLE (=> NKIntHandlers, NKPaging, NKVMCalls)
;	  SpaceL2PIgnoringBATs (=> NKMPCalls)
;	  SpaceL2PUsingBATs (=> NKIntHandlers, NKMPCalls)



 #####                              ######                         ###                                    
#     # #####    ##    ####  ###### #     #   ##   #    # #  ####   #   ####  #        ##   #    # #####  
#       #    #  #  #  #    # #      #     #  #  #  ##   # # #    #  #  #      #       #  #  ##   # #    # 
 #####  #    # #    # #      #####  ######  #    # # #  # # #       #   ####  #      #    # # #  # #    # 
      # #####  ###### #      #      #       ###### #  # # # #       #       # #      ###### #  # # #    # 
#     # #      #    # #    # #      #       #    # #   ## # #    #  #  #    # #      #    # #   ## #    # 
 #####  #      #    #  ####  ###### #       #    # #    # #  ####  ###  ####  ###### #    # #    # #####  

SpacePanicIsland
	b		panic



###                #######                      ######                       #                      
 #  #    # # ##### #       #####  ###### ###### #     #   ##    ####  ###### #       #  ####  ##### 
 #  ##   # #   #   #       #    # #      #      #     #  #  #  #    # #      #       # #        #   
 #  # #  # #   #   #####   #    # #####  #####  ######  #    # #      #####  #       #  ####    #   
 #  #  # # #   #   #       #####  #      #      #       ###### #  ### #      #       #      #   #   
 #  #   ## #   #   #       #   #  #      #      #       #    # #    # #      #       # #    #   #   
### #    # #   #   #       #    # ###### ###### #       #    #  ####  ###### ####### #  ####    #   

InitFreePageList
	addi	r9, r1, PSA.FreeList

	InitList	r9, 'PHYS', scratch=r8

	li		r8, 0
	stw		r8, PSA.FreePageCount(r1)
	stw		r8, PSA.UnheldFreePageCount(r1)
	stw		r8, PSA.ZeroedByInitFreeList3(r1)

	lwz		r8, PSA.OtherSystemAddrSpcPtr(r1)
	stw		r8, PSA.OtherSystemAddrSpcPtr2(r1)

	blr



 #####                                       #                                #######                      ######                       #     #               
#     # #####  ######   ##   ##### ######   # #   #####  ######   ##    ####  #       #####   ####  #    # #     #   ##    ####  ###### ##   ##   ##   #####  
#       #    # #       #  #    #   #       #   #  #    # #       #  #  #      #       #    # #    # ##  ## #     #  #  #  #    # #      # # # #  #  #  #    # 
#       #    # #####  #    #   #   #####  #     # #    # #####  #    #  ####  #####   #    # #    # # ## # ######  #    # #      #####  #  #  # #    # #    # 
#       #####  #      ######   #   #      ####### #####  #      ######      # #       #####  #    # #    # #       ###### #  ### #      #     # ###### #####  
#     # #   #  #      #    #   #   #      #     # #   #  #      #    # #    # #       #   #  #    # #    # #       #    # #    # #      #     # #    # #      
 #####  #    # ###### #    #   #   ###### #     # #    # ###### #    #  ####  #       #    #  ####  #    # #       #    #  ####  ###### #     # #    # #      

;	Pretty obvious from log output.

CreateAreasFromPageMap

	;	The kind of crap we have to do without a stack
	mflr	r16
	mfcr	r17
	stw		r16, EWA.SpacesSavedLR(r1)
	stw		r17, EWA.SpacesSavedCR(r1)

	_log	'Converting PMDTs to areas^n'

	lwz		r17, PSA.UnheldFreePageCount(r1)
	lwz		r16, KDP.TotalPhysicalPages(r1)
	add		r17, r17, r16
	stw		r17, PSA.UnheldFreePageCount(r1)


;_______________________________________________________________________
;	Code to increment a loop that:
;		iterates over segmap entries, and
;		iterates over PMDTs, starting at the one
;			ref'd by the segmap entry
;_______________________________________________________________________

	addi	r27, r1, KDP.SegMaps - 8
	lis		r26, 0

@next_segment_entry
	_wlog	'SEGMENT ', r26, '^n'

	lwzu	r25, 8(r27)

	b		@this_pmdt
@next_pmdt
	addi	r25, r25, PMDT.Size
@this_pmdt


;_______________________________________________________________________
;	Now we enter the loop body:
;		r27 points to segmap entry
;		r25 points to the PMDT
;		r26 equals the base address of this segment
;_______________________________________________________________________


	;	Load the contents of the PMDT.

	lwz		r17, PMDT.PBaseAndFlags(r25)
	_wlog	'    PMDT PBaseAndFlags ', r17, ' '

	lhz		r15, PMDT.LBase(r25)
	_wlogh	'LBase ', r15, ' '

	andi.	r8, r17, $800 | $400 | $200		; interested in 3 PBase flags

	lhz		r16, PMDT.PageCount(r25)
	_wlogh	'PageCount ', r16, '^n', scratch=r9	; cannot clobber r8 here


	;	Based on those flags, do one of two things
	cmplwi	r8,      0
	cmplwi	cr1, r8, $800 | $400
	beq		@pmdt_flags_are_zero
	beq		cr1, @pmdt_flags_are_c00

	;	Else if not a full-segment PMDT, next PMDT
	cmplwi	cr2, r15,  0x0000
	cmplwi	cr3, r16,  0xffff
	bne		cr2, @next_pmdt
	bne		cr3, @next_pmdt

	;	Else if there are segments remaining (16 total), next segment.
	addis	r26, r26, 0x1000
	cmplwi	r26, 0					; once it wraps to zero, we're done
	bne		@next_segment_entry

	;	Else create special one-page Areas to catch naughty pointer derefs,
	;	then return.

		;	61F168F1 (magic bus error incantation)

		li		r8, Area.Size
		bl		PoolAllocClear
		mr.		r31, r8
		beq		SpacePanicIsland

		lwz		r8, EWA.PA_CurAddressSpace(r1)
		stw		r8, Area.AddressSpacePtr(r31)

		lisori	r15, 0x68f168f1
		stw		r15, Area.LogicalBase(r31)

		li		r16, 0x1000
		stw		r16, Area.Length(r31)

		lisori	r8, 0x00008000
		stw		r8, Area.LogicalSeparation(r31)

		li		r8, 0
		stw		r8, 0x001c(r31)

		lisori	r8, 0x0000e00c
		stw		r8, 0x0020(r31)

		mr		r8, r31
		bl		CreateArea

		cmpwi	r9, noErr
		beq		@success_68f168f1
		mr		r8, r31
		bl		PoolFree
@success_68f168f1


		;	DEADBEEF (all over the place)

		li		r8, Area.Size
		bl		PoolAllocClear
		mr.		r31, r8
		beq		SpacePanicIsland

		lwz		r8, EWA.PA_CurAddressSpace(r1)
		stw		r8, Area.AddressSpacePtr(r31)

		lisori	r15, 0xdeadbeef
		stw		r15, Area.LogicalBase(r31)

		li		r16, 0x1000
		stw		r16, Area.Length(r31)

		lisori	r8, 0x00008000
		stw		r8, Area.LogicalSeparation(r31)

		li		r8, 0
		stw		r8, 0x001c(r31)

		lisori	r8, 0x0000e00c
		stw		r8, 0x0020(r31)

		mr		r8, r31
		bl		CreateArea

		cmpwi	r9, noErr
		beq		@success_deadbeef
		mr		r8, r31
		bl		PoolFree
@success_deadbeef


		;	Done -- return.
		lwz		r16, EWA.SpacesSavedLR(r1)
		lwz		r17, EWA.SpacesSavedCR(r1)
		mtlr	r16
		mtcr	r17
		blr


	;	ONE OF THE "FLAGS" CASES: all tests bits unset

@pmdt_flags_are_zero
	_clog	'        pmdt_flags_are_zero^n'

	;	Apparently other iterations leave this to find?
		lwz		r8, EWA.SpacesDeferredAreaPtr(r1)
		cmpwi	r8, 0
		beq		@thing_is_zero

		bl		CreateArea
		cmpwi	r9, noErr
		bne		SpacePanicIsland

		li		r8, 0
		stw		r8, EWA.SpacesDeferredAreaPtr(r1)
@thing_is_zero



	li		r8, Area.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		SpacePanicIsland

	;	Reload PMDT details
	lwz		r17, PMDT.PBaseAndFlags(r25)
	lhz		r15, PMDT.LBase(r25)
	lhz		r16, PMDT.PageCount(r25)

	;	Why do we need to sign the area? Isn't it 'AREA'?
	lisori	r8, 'area'
	stw		r8, Area.Signature(r31)

	;	Set r15/r16 to true logical base/length
	slwi	r15, r15, 12
	addi	r16, r16, 1
	add		r15, r15, r26			; add a page, I think
	slwi	r16, r16, 12

	lwz		r8, KDP.NanoKernelInfo + NKNanoKernelInfo.blueProcessID(r1)
	stw		r8, Area.ProcessID(r31)

	lwz		r8, EWA.PA_CurAddressSpace(r1)
	stw		r8, Area.AddressSpacePtr(r31)

	stw		r15, Area.LogicalBase(r31)

	stw		r16, Area.Length(r31)
	stw		r16, Area.BytesMapped(r31)

	li		r8, 0
	stw		r8, Area.LogicalSeparation(r31)

	lwz		r18,  0x007c(r31)
	rlwinm	r9, r17,  0,  0, 19
	stw		r9,  0x0070(r31)
	andi.	r16, r17,  0x03
	bne		@_20c
	ori		r17, r17,  0x02
@_20c

	bl		major_0x10d38_0x58
	stw		r18,  0x001c(r31)


@_214



	lisori	r8, 0x0000e00c
	stw		r8, 0x0020(r31)


	;	Try to create the Area. If we succeed then do the next PMDT.
	mr		r8, r31
	bl		CreateArea
	cmpwi	r9, noErr
	mr		r31, r8
	beq		@next_pmdt

	;	If CreateArea failed, assume that it was due to overlap with another Area.

		;	Find that AboveArea that we impinged on (=> r24).
		lwz		r9, Area.LogicalBase(r31)
		lwz		r8, Area.AddressSpacePtr(r31)
		bl		FindAreaAbove
		mr		r24, r8

		;	Shorten our FailedArea to fit below AboveArea.
		lwz		r15, Area.LogicalBase(r31)
		lwz		r16, Area.LogicalBase(r24)
		lwz		r17, Area.LogicalEnd(r31)
		subf.	r16, r15, r16						; r16 = offset of found area from this one
		stw		r17, EWA.SpacesSavedAreaBase(r1)	; ???
		stw		r16, Area.Length(r31)				; we will try again, with no overlap

		beq		@found_area_has_same_base

		;	If FoundArea < FailedArea, panic (impossible for FindAreaAbove to return this)
			bltl	SpacePanicIsland							; below would be impossible

		;	If AboveArea > FailedArea, create NewArea (=> r30)
			mr		r8, r31
			bl		CreateArea

			cmpwi	r9, noErr							; strike three
			mr		r30, r8
			bnel	SpacePanicIsland

			;	If AboveArea.LogicalEnd >= FailedArea.LogicalEnd then continue to next PMDT.
				lwz		r15, Area.LogicalEnd(r24)
				lwz		r16, EWA.SpacesSavedAreaBase(r1)
				subf.	r16, r15, r16
				ble		@next_pmdt

			;	Else replace FailedArea with an Area copied from NewArea
					li		r8, Area.Size
					bl		PoolAllocClear
					mr.		r31, r8
					beq		SpacePanicIsland

					li		r8, Area.Size - 4
@area_copy_loop
					lwzx	r9, r8, r30
					stwx	r9, r8, r31
					cmpwi	r8, 0
					subi	r8, r8, 4
					bgt		@area_copy_loop
@found_area_has_same_base

		;	Else (AboveArea == ThisArea), do nothing special (endif)


		lwz		r9, Area.LogicalBase(r31)

		lwz		r15,  0x0028(r24)
		lwz		r16, EWA.SpacesSavedAreaBase(r1)		; this is FailedArea.LogicalEnd
		subf.	r16, r15, r16
		addi	r15, r15, 1
		blel	SpacePanicIsland

		stw		r16, Area.Length(r31)
		stw		r15, Area.LogicalBase(r31)
		subf	r9, r9, r15
		lwz		r8,  0x0070(r31)
		add		r8, r8, r9
		stw		r8,  0x0070(r31)
		b		@_214




@pmdt_flags_are_c00
	_clog	'        pmdt_flags_are_c00^n'
	li		r8, Area.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		SpacePanicIsland

	lwz		r17,  0x0004(r25)
	lhz		r15,  0x0000(r25)
	lhz		r16,  0x0002(r25)
	lis		r8,  0x6172
	ori		r8, r8,  0x6561
	stw		r8, Area.Signature(r31)
	slwi	r15, r15, 12
	addi	r16, r16,  0x01
	add		r15, r15, r26
	slwi	r16, r16, 12
	lwz		r8,  0x0ec0(r1)
	stw		r8, Area.ProcessID(r31)
	lwz		r8, EWA.PA_CurAddressSpace(r1)
	stw		r8, Area.AddressSpacePtr(r31)
	stw		r15, Area.LogicalBase(r31)
	stw		r16, Area.Length(r31)
	stw		r16, Area.BytesMapped(r31)
	li		r8,  0x00
	stw		r8, Area.LogicalSeparation(r31)
	li		r8,  0x07
	stw		r8,  0x001c(r31)
	lis		r8,  0x00
	ori		r8, r8,  0x600c
	stw		r8,  0x0020(r31)
	rlwinm	r8, r17, 22,  0, 29
	stw		r8,  0x0040(r31)
	lwz		r8, Area.Flags(r31)
	ori		r8, r8,  0x40
	lwz		r9, PSA.FreePageCount(r1)
	cmpwi	r9, noErr

	bgt		@_374
	ori		r8, r8,  0x80
@_374

	stw		r8, Area.Flags(r31)
	cmpwi	r15,  0x00

	bne		@_388
	stw		r31, EWA.SpacesDeferredAreaPtr(r1)
	b		@next_pmdt
@_388

	lwz		r18, EWA.SpacesDeferredAreaPtr(r1)
	cmpwi	r18,  0x00
	beq		@_3c8
	lwz		r8,  0x0024(r18)
	lwz		r9,  0x002c(r18)
	add		r19, r8, r9
	cmplw	r19, r15
	bne		@_3c8
	add		r9, r9, r16
	addi	r19, r9, -0x01
	stw		r9,  0x002c(r18)
	stw		r9,  0x0038(r18)
	stw		r19,  0x0028(r18)
	mr		r8, r31
	bl		PoolFree
	b		@next_pmdt
@_3c8

	lwz		r8, Area.Flags(r31)
	ori		r8, r8,  0x80
	stw		r8, Area.Flags(r31)
	mr		r8, r31
	bl		CreateArea
	cmpwi	r9, noErr
	bne		SpacePanicIsland
	b		@next_pmdt



#     # ######   #####               ######                        #####                   #####                                            
##   ## #     # #     # ###### ##### #     #   ##    ####  ###### #     # # ###### ###### #     # #        ##    ####   ####  ######  ####  
# # # # #     # #       #        #   #     #  #  #  #    # #      #       #     #  #      #       #       #  #  #      #      #      #      
#  #  # ######  #  #### #####    #   ######  #    # #      #####   #####  #    #   #####  #       #      #    #  ####   ####  #####   ####  
#     # #       #     # #        #   #       ###### #  ### #            # #   #    #      #       #      ######      #      # #           # 
#     # #       #     # #        #   #       #    # #    # #      #     # #  #     #      #     # #      #    # #    # #    # #      #    # 
#     # #        #####  ######   #   #       #    #  ####  ######  #####  # ###### ######  #####  ###### #    #  ####   ####  ######  ####  

;	The number of page size classes, 1 to n.

;	MPPageSizeClass MPGetPageSizeClasses(void )

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: yes

	DeclareMPCall	68, MPGetPageSizeClasses

MPGetPageSizeClasses

	li		r3, 1
	b		CommonMPCallReturnPath



#     # ######   #####               ######                        #####                  
##   ## #     # #     # ###### ##### #     #   ##    ####  ###### #     # # ###### ###### 
# # # # #     # #       #        #   #     #  #  #  #    # #      #       #     #  #      
#  #  # ######  #  #### #####    #   ######  #    # #      #####   #####  #    #   #####  
#     # #       #     # #        #   #       ###### #  ### #            # #   #    #      
#     # #       #     # #        #   #       #    # #    # #      #     # #  #     #      
#     # #        #####  ######   #   #       #    #  ####  ######  #####  # ###### ###### 

;	The page size in bytes.

;	ByteCount MPGetPageSize(MPPageSizeClass pageClass)

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: yes

	DeclareMPCall	69, MPGetPageSize

MPGetPageSize

	cmpwi	r3, 1
	bne		ReturnParamErrFromMPCall

	lwz		r3, KDP.ProcessorInfo + NKProcessorInfo.PageSize(r1)
	b		CommonMPCallReturnPath



#     # ######   #####                                       #                                               #####                              
##   ## #     # #     # #####  ######   ##   ##### ######   # #   #####  #####  #####  ######  ####   ####  #     # #####    ##    ####  ###### 
# # # # #     # #       #    # #       #  #    #   #       #   #  #    # #    # #    # #      #      #      #       #    #  #  #  #    # #      
#  #  # ######  #       #    # #####  #    #   #   #####  #     # #    # #    # #    # #####   ####   ####   #####  #    # #    # #      #####  
#     # #       #       #####  #      ######   #   #      ####### #    # #    # #####  #           #      #       # #####  ###### #      #      
#     # #       #     # #   #  #      #    #   #   #      #     # #    # #    # #   #  #      #    # #    # #     # #      #    # #    # #      
#     # #        #####  #    # ###### #    #   #   ###### #     # #####  #####  #    # ######  ####   ####   #####  #      #    #  ####  ###### 

;	ARG		MPCoherenceID r3
;	RET		OSStatus r3, MPAddressSpaceID r4

;	Straight MPLibrary wrapper: no
;	In Universal Interfaces: no

	DeclareMPCall	70, MPCreateAddressSpace

MPCreateAddressSpace

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mfsprg	r16, 0
	lwz		r17, EWA.PA_CurTask(r16)

	mr		r8, r3

	lwz		r9, Area.AddressSpacePtr(r17)
	lwz		r16, AddressSpace.Flags(r9)
	rlwinm.	r16, r16, 0, AddressSpace.kFlag30, AddressSpace.kFlag30
	bne		ReleaseAndReturnMPCallOOM

	bl		NKCreateAddressSpaceSub

	_AssertAndRelease	PSA.SchLock, scratch=r16

	mr.		r3, r8
	li		r4, 0
	bne		CommonMPCallReturnPath			; failure

	lwz		r4, AddressSpace.ID(r9)
	b		CommonMPCallReturnPath			; success



#     # #    #  #####                                       #                                               #####                               #####                
##    # #   #  #     # #####  ######   ##   ##### ######   # #   #####  #####  #####  ######  ####   ####  #     # #####    ##    ####  ###### #     # #    # #####  
# #   # #  #   #       #    # #       #  #    #   #       #   #  #    # #    # #    # #      #      #      #       #    #  #  #  #    # #      #       #    # #    # 
#  #  # ###    #       #    # #####  #    #   #   #####  #     # #    # #    # #    # #####   ####   ####   #####  #    # #    # #      #####   #####  #    # #####  
#   # # #  #   #       #####  #      ######   #   #      ####### #    # #    # #####  #           #      #       # #####  ###### #      #            # #    # #    # 
#    ## #   #  #     # #   #  #      #    #   #   #      #     # #    # #    # #   #  #      #    # #    # #     # #      #    # #    # #      #     # #    # #    # 
#     # #    #  #####  #    # ###### #    #   #   ###### #     # #####  #####  #    # ######  ####   ####   #####  #      #    #  ####  ######  #####   ####  #####  

;	ARG		MPCoherenceID r8 owningcgrp		; 0 to use mobo cgrp
;			Process *r9 owningPROC

;	RET		osErr r8
;			AddressSpace *r9

NKCreateAddressSpaceSub
	cmpwi	r8, 0
	mr		r27, r9			; Save the process arg for later
	mflr	r30

	;	Use the motherboard coherence group if none is provided in r8
	bne		@cgrp_provided
	mfsprg	r15, 0
	lwz		r28, EWA.CPUBase + CPU.LLL + LLL.Freeform(r15)

	b		@got_cgrp

@cgrp_provided
	bl		LookupID			; takes id in r8, returns ptr in r8 and kind in r9

	cmpwi	r9, CoherenceGroup.kIDClass
	mr		r28, r8
	bne		@fail_notcgrp
	lwz		r28, CoherenceGroup.LLL + LLL.Next(r28)

@got_cgrp


	;	Read the SpecialPtr of this cgrp element in list of the owning CpuStruct
	;	But why? cgrp.LLL.Freeform does not seem to be set for the mobo cgrp
	lwz		r29, LLL.Freeform(r28)


	;	Boast (including the SpecialPtr)
	_log	'NKCreateAddressSpaceSub - group at 0x'

	mr		r8, r28
	bl		printw

	mr		r8, r29
	bl		printw

	_log	'^n'


	;	Create the AddressSpace
	li		r8, AddressSpace.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		@fail_OOM


	;	Give the addr spc a copy of the SpecialPtr of its parent cgrp
	stw		r29, AddressSpace.ParentCoherenceSpecialPtr(r31)


	;	Give the addr spc an ID
	li		r9, AddressSpace.kIDClass
	bl		MakeID

	cmpwi	r8, 0x00
	beq		@fail_MakeID

	stw		r8, AddressSpace.ID(r31)


	;	Increment a counter in the cgrp (modulo a million, fail on overflow)
	lwz		r16, CoherenceGroup.Incrementer(r28)
	addi	r16, r16, 1
	clrlwi.	r16, r16, 12
	beq		@fail_toomanycalls
	stw		r16, CoherenceGroup.Incrementer(r28)


	;	Fill segment register fields in the address space struct like so:
	;	(8 bits = 0x20) || (4 bits = word idx) || (20 bits = prev call count)

	addi	r16, r16, -1
	li		r17, 0x40 - 4
	oris	r16, r16, 0x2000
	addi	r18, r31, AddressSpace.SRs

@fill_loop
	cmpwi	r17, 0
	rlwimi	r16, r17, 18, 8, 11		; = index (15, 14, 13...) << 20
	stwx	r16, r17, r18
	addi	r17, r17, -4
	bne		@fill_loop


	;	Sign the addr spc struct
	lisori	r8, AddressSpace.kSignature
	stw		r8, AddressSpace.Signature(r31)


	;	Create an empty linked list of 'rsrv's (what are they?)
	addi	r16, r31, AddressSpace.RsrvList
	InitList		r16, 'rsrv', scratch=r17


	;	Create a linked list with one Area
	addi	r16, r31, AddressSpace.AreaList
	InitList		r16, 'area', scratch=r17

		;	Allocate the Area, check for errors
		li		r8, Area.Size
		bl		PoolAllocClear
		mr.		r29, r8
		beq		@fail_OOM_again

		;	Sign the Area
		lisori	r8, Area.kSignature
		stw		r8, Area.Signature(r29)

		;	Pop some constants in
		lisori	r8, -1
		stw		r8, Area.LogicalBase(r29)
		stw		r8, Area.LogicalEnd(r29)
		li		r8, 256
		stw		r8, Area.Flags(r29)

		;	Give it a copy of the ID of its parent address space
		lwz		r8, AddressSpace.ID(r31)
		stw		r8, Area.AddressSpaceID(r29)

		;	Point the SpecialPtr to it and insert it in the list
		addi	r16, r31, AddressSpace.AreaList
		addi	r29, r29, Area.LLL
		stw		r16, LLL.Freeform(r29)
		InsertAsPrev	r29, r16, scratch=r17


	;	Point this struct by ID to its owning Process,
	;	and increment a counter in that struct.
	lwz		r18, Process.ID(r27)
	stw		r18, AddressSpace.ProcessID(r31)

	lwz		r17, Process.AddressSpaceCount(r27)
	addi	r17, r17, 1
	stw		r17, Process.AddressSpaceCount(r27)


	;	Done, with no errors
	li		r8, 0			; kMPNoErr
	mr		r9, r31			; ptr to new AddressSpace
	b		@return

@fail_OOM_again
	lwz		r8,Area.ID(r31)

@fail_toomanycalls
	bl		DeleteID
	mr		r8, r31
	bl		PoolFree
	li		r8, kMPInsufficientResourcesErr
	b		@return

@fail_MakeID
	mr		r8, r31
	bl		PoolFree

@fail_OOM
	li		r8, -29294
	b		@return

@fail_notcgrp
	li		r8, kMPInvalidIDErr

@return
	mtlr	r30
	blr



#     # ######  ######                                       #                                               #####                              
##   ## #     # #     # ###### #      ###### ##### ######   # #   #####  #####  #####  ######  ####   ####  #     # #####    ##    ####  ###### 
# # # # #     # #     # #      #      #        #   #       #   #  #    # #    # #    # #      #      #      #       #    #  #  #  #    # #      
#  #  # ######  #     # #####  #      #####    #   #####  #     # #    # #    # #    # #####   ####   ####   #####  #    # #    # #      #####  
#     # #       #     # #      #      #        #   #      ####### #    # #    # #####  #           #      #       # #####  ###### #      #      
#     # #       #     # #      #      #        #   #      #     # #    # #    # #   #  #      #    # #    # #     # #      #    # #    # #      
#     # #       ######  ###### ###### ######   #   ###### #     # #####  #####  #    # ######  ####   ####   #####  #      #    #  ####  ###### 

;	ARG		MPAddressSpaceID r3
;	RET		OSStatus r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	71, MPDeleteAddressSpace

MPDeleteAddressSpace

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	mr		r31, r8

	;	Die if a Task is using this Space
	lwz		r16, AddressSpace.TaskCount(r31)
	cmpwi	r16, 0
	bne		ReleaseAndReturnMPCallOOM

	;	Die if the Space has a non-empty RsrvList
	addi	r16, r31, AddressSpace.RsrvList
	lwz		r17, AddressSpace.RsrvList + LLL.Next(r31)
	cmpw	r16, r17
	bne		ReleaseAndReturnMPCallOOM

	;	Die if the Space has a non-empty AreaList
	addi	r16, r31, AddressSpace.AreaList
	lwz		r17, AddressSpace.AreaList + LLL.Next(r31)
	cmpw	r16, r17
	bne		ReleaseAndReturnMPCallOOM

	lwz		r8, AddressSpace.ProcessID(r31)
	bl		LookupID
	lwz		r17, Process.AddressSpaceCount(r8)
	subi	r17, r17, 1
	stw		r17, Process.AddressSpaceCount(r8)

	;	Kill
	lwz		r8, AddressSpace.ID(r31)
	bl		DeleteID
	mr		r8, r31
	bl		PoolFree

	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####                                              #                                               #####                              
##   ## #     # #     # #    # #####  #####  ###### #    # #####   # #   #####  #####  #####  ######  ####   ####  #     # #####    ##    ####  ###### 
# # # # #     # #       #    # #    # #    # #      ##   #   #    #   #  #    # #    # #    # #      #      #      #       #    #  #  #  #    # #      
#  #  # ######  #       #    # #    # #    # #####  # #  #   #   #     # #    # #    # #    # #####   ####   ####   #####  #    # #    # #      #####  
#     # #       #       #    # #####  #####  #      #  # #   #   ####### #    # #    # #####  #           #      #       # #####  ###### #      #      
#     # #       #     # #    # #   #  #   #  #      #   ##   #   #     # #    # #    # #   #  #      #    # #    # #     # #      #    # #    # #      
#     # #        #####   ####  #    # #    # ###### #    #   #   #     # #####  #####  #    # ######  ####   ####   #####  #      #    #  ####  ###### 

;	RET		MPAddressSpaceID r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	117, MPCurrentAddressSpace

MPCurrentAddressSpace

	mfsprg	r16, 0
	lwz		r17, EWA.PA_CurAddressSpace(r16)
	lwz		r3, AddressSpace.ID(r17)
	b		CommonMPCallReturnPath



#     # ######  #     #                         #                                               #####                              
##   ## #     # #     #  ####  #    # ######   # #   #####  #####  #####  ######  ####   ####  #     # #####    ##    ####  ###### 
# # # # #     # #     # #    # ##  ## #       #   #  #    # #    # #    # #      #      #      #       #    #  #  #  #    # #      
#  #  # ######  ####### #    # # ## # #####  #     # #    # #    # #    # #####   ####   ####   #####  #    # #    # #      #####  
#     # #       #     # #    # #    # #      ####### #    # #    # #####  #           #      #       # #####  ###### #      #      
#     # #       #     # #    # #    # #      #     # #    # #    # #   #  #      #    # #    # #     # #      #    # #    # #      
#     # #       #     #  ####  #    # ###### #     # #####  #####  #    # ######  ####   ####   #####  #      #    #  ####  ###### 

;	RET		MPAddressSpaceID r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	118, MPHomeAddressSpace

MPHomeAddressSpace

	mfsprg	r16, 0
	lwz		r17, EWA.PA_CurTask(r16)
	lwz		r18, Task.OwningProcessPtr(r17)
	lwz		r19, Process.SystemAddressSpacePtr(r18)
	lwz		r3, AddressSpace.ID(r19)
	b		CommonMPCallReturnPath



#     # ######   #####               #######                         #                                               #####                              
##   ## #     # #     # ###### #####    #      ##    ####  #    #   # #   #####  #####  #####  ######  ####   ####  #     # #####    ##    ####  ###### 
# # # # #     # #       #        #      #     #  #  #      #   #   #   #  #    # #    # #    # #      #      #      #       #    #  #  #  #    # #      
#  #  # ######   #####  #####    #      #    #    #  ####  ####   #     # #    # #    # #    # #####   ####   ####   #####  #    # #    # #      #####  
#     # #             # #        #      #    ######      # #  #   ####### #    # #    # #####  #           #      #       # #####  ###### #      #      
#     # #       #     # #        #      #    #    # #    # #   #  #     # #    # #    # #   #  #      #    # #    # #     # #      #    # #    # #      
#     # #        #####  ######   #      #    #    #  ####  #    # #     # #####  #####  #    # ######  ####   ####   #####  #      #    #  ####  ###### 

;	ARG		MPTaskID r3, MPAddressSpaceID r4
;	RET		OSStatus r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	119, MPSetTaskAddressSpace

MPSetTaskAddressSpace

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17


	;	Get Task and do some checks

	mr		r8, r3
	bl		LookupID
	mr		r31, r8
	cmpwi	r9, Task.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	lwz		r16, Task.Flags(r31)
	mtcr	r16

	li		r3, kMPTaskAbortedErr
	bc		BO_IF, Task.kFlagAborted, ReleaseAndReturnMPCall

	bc		BO_IF_NOT, Task.kFlagStopped, ReleaseAndReturnMPCallOOM

	lbz		r16, Task.State(r31)
	cmpwi	r16, 0
	bne		ReleaseAndReturnMPCallOOM


	;	Get Address Space and do some checks

	mr		r8, r4
	bl		LookupID
	mr		r30, r8

	lwz		r16, Task.ProcessID(r31)
	cmpwi	r9, AddressSpace.kIDClass
	lwz		r17, AddressSpace.ProcessID(r30)
	bne		ReleaseAndReturnMPCallInvalidIDErr

	;	The Task and Address Space must already share a process ID
	cmpw	r16, r17
	bne		ReleaseAndReturnMPCallOOM

	lwz		r17, Task.AddressSpacePtr(r31)

	;	Decrement old Address Space
	lwz		r16, AddressSpace.TaskCount(r17)
	subi	r16, r16, 1
	stw		r16, AddressSpace.TaskCount(r17)

	;	Increment old Address Space
	lwz		r16, AddressSpace.TaskCount(r30)
	addi	r16, r16, 1
	stw		r16, AddressSpace.TaskCount(r30)

	stw		r30, Task.AddressSpacePtr(r31)


	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####                                       #                         
##   ## #     # #     # #####  ######   ##   ##### ######   # #   #####  ######   ##   
# # # # #     # #       #    # #       #  #    #   #       #   #  #    # #       #  #  
#  #  # ######  #       #    # #####  #    #   #   #####  #     # #    # #####  #    # 
#     # #       #       #####  #      ######   #   #      ####### #####  #      ###### 
#     # #       #     # #   #  #      #    #   #   #      #     # #   #  #      #    # 
#     # #        #####  #    # ###### #    #   #   ###### #     # #    # ###### #    # 

;	This MP call does some of the heavy lifting for the MPLibrary function
;	of the same name. No pages are mapped into the Area.

;	ARG		AddressSpaceID r3 (optional)
;			long r4 PTEConfig
;			long r5 length
;			long r6 LogicalSeparation
;			long r7 flagsAndMinAlign
;			char *r8 LogicalBase
;	RET		r3 OSErr
;			char *r8 LogicalBase
;			AreaID r9

;	Hint: in the 9.2.2 System MPLibrary, MPCreateArea calls a syscall
;	wrapper function at code offset 0x7fa8, with arguments pointing to save
;	locations for r8 and r9.

	DeclareMPCall	72, MPCreateArea

MPCreateArea

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	;	If !r3 then use the current address space
	mr.		r8, r3
	mfsprg	r28, 0
	lwz		r30, EWA.PA_CurAddressSpace(r28)
	beq		@use_current_space

	;	... else use the one specified.
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass
	mr		r30, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
@use_current_space

	;	Allocate the new Area
	li		r8, Area.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		ReleaseAndScrambleMPCall

	;	Populate
	stw		r30, Area.AddressSpacePtr(r31)

	stw		r4, Area.PTEConfig(r31)

	stw		r5, Area.Length(r31)

	lwz		r8, ContextBlock.r6(r6)
	stw		r8, Area.LogicalSeparation(r31)

	lwz		r8, ContextBlock.r7(r6)
	stw		r8, Area.FlagsAndMinAlign(r31)

	lwz		r8, ContextBlock.r8(r6)
	stw		r8, Area.LogicalBase(r31)

	;	"Create" the area
	mr		r8, r31
	bl		CreateArea

	_AssertAndRelease	PSA.SchLock, scratch=r16

	mr.		r3, r9
	bne		@error

	;	CreateArea returned successfully
	lwz		r8, Area.LogicalBase(r31)
	stw		r8, ContextBlock.r8(r6)

	lwz		r8, Area.ID(r31)
	stw		r8, ContextBlock.r9(r6)

	b		CommonMPCallReturnPath

@error
	bl		PoolFree
	b		CommonMPCallReturnPath



 #####                                       #                         
#     # #####  ######   ##   ##### ######   # #   #####  ######   ##   
#       #    # #       #  #    #   #       #   #  #    # #       #  #  
#       #    # #####  #    #   #   #####  #     # #    # #####  #    # 
#       #####  #      ######   #   #      ####### #####  #      ###### 
#     # #   #  #      #    #   #   #      #     # #   #  #      #    # 
 #####  #    # ###### #    #   #   ###### #     # #    # ###### #    # 

;	This function actually gets passed its own structure.
;	What the frick?

;	Always returns via ReturnFromCreateArea

;	ARG		Area *r8
;	RET		ID r8, osErr r9

CreateArea	;	OUTSIDE REFERER

	;	Always returns via ReturnFromCreateArea
	mflr	r16
	mfsprg	r9, 0
	stw		r16, EWA.CreateAreaSavedLR(r9)
	stmw	r25, EWA.CreateAreaSavedR25(r9)

	;	Keep the structure itself in r31 for the duration.
	;	r8 must be used for other things
	mr		r31, r8

	;	For if we need to return early
	li		r9, paramErr


	lwz		r16, Area.Flags(r31)
	lwz		r17,  0x0020(r31)
	rlwinm.	r16, r16,  0, 28, 28

	lisori	r16, 0xfffc13e0		; if bit 28 = 0
	beq		@use_other
	lisori	r16, 0xfff99be0		; if bit 28 = 1
@use_other

	and.	r16, r16, r17
	bne		ReturnFromCreateArea

	andi.	r16, r17,  0x1f
	cmpwi	cr1, r16,  0x0c
	beq		CreateArea_0x50
	blt		cr1, ReturnFromCreateArea

CreateArea_0x50
	bne		CreateArea_0x5c
	ori		r17, r17,  0x0c
	stw		r17,  0x0020(r31)

CreateArea_0x5c
	andi.	r16, r17,  0x1f
	li		r18, -0x01
	slw		r18, r18, r16
	stw		r18,  0x0078(r31)
	rlwinm.	r16, r17, 27, 27, 31
	bne		ReturnFromCreateArea
	addi	r16, r16,  0x0c
	li		r18, -0x01
	slw		r18, r18, r16
	stw		r18,  0x007c(r31)
	neg		r16, r18
	not		r19, r18
	stw		r16,  0x0068(r31)
	lwz		r16, Area.Length(r31)
	add		r16, r16, r19
	and.	r16, r16, r18
	stw		r16, Area.Length(r31)
	beq		ReturnFromCreateArea
	lwz		r18,  0x001c(r31)
	lis		r16, -0x01
	ori		r16, r16,  0xff10
	and.	r16, r16, r18
	bne		ReturnFromCreateArea
	lwz		r16,  0x0070(r31)
	li		r17,  0x200
	rlwimi	r17, r16,  0,  0, 19
	bl		major_0x10cb8 ; PTE r16/r17, control r18 // PTE r16/r17
	stw		r16,  0x0070(r31)
	stw		r17,  0x0074(r31)
	mr		r8, r31

	li		r9, Area.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	beq		major_0x10320

	stw		r8, Area.ID(r31)
	mfsprg	r16, 0
	lwz		r17, -0x0008(r16)
	lwz		r18,  0x0060(r17)
	lwz		r30, Area.AddressSpacePtr(r17)
	stw		r18, Area.ProcessID(r31)
	lwz		r16, Area.AddressSpacePtr(r31)
	lwz		r17,  0x0000(r16)
	stw		r17, Area.AddressSpaceID(r31)
	lwz		r16,  0x0008(r30)
	rlwinm.	r16, r16,  0, 30, 30
	bne		major_0x10320_0x64
	lis		r16,  0x4152
	ori		r16, r16,  0x4541
	stw		r16, Area.Signature(r31)
	lwz		r17,  0x0020(r31)
	lwz		r16, Area.LogicalSeparation(r31)
	addi	r16, r16,  0xfff
	rlwinm	r16, r16,  0,  0, 19
	stw		r16, Area.LogicalSeparation(r31)
	rlwinm	r16, r17,  0, 17, 18
	cmplwi	cr7, r16,  0x6000
	rlwinm.	r16, r17,  0, 17, 17
	beq		cr7, CreateArea_0x150
	bne		CreateArea_0x150
	crset	cr7_gt
	crclr	cr7_lt

CreateArea_0x150
	rlwinm.	r16, r17,  0, 17, 18
	lwz		r18, Area.LogicalBase(r31)
	lwz		r19, Area.Length(r31)
	blt		cr7, CreateArea_0x16c
	bne		CreateArea_0x170
	li		r18,  0x00
	b		CreateArea_0x170

CreateArea_0x16c
	subf	r18, r19, r18

CreateArea_0x170
	lwz		r16,  0x0078(r31)
	and		r18, r18, r16
	stw		r18, Area.LogicalBase(r31)
	add		r16, r18, r19
	addi	r16, r16, -0x01
	stw		r16, Area.LogicalEnd(r31)


	;	Major hint here...

	_log	' CreateArea [ '
	mr		r8, r18
	bl		Printw
	mr		r8, r16
	bl		Printw
	_log	'] ID '


	lwz		r8, Area.ID(r31)
	mr		r8, r8
	bl		Printw


	bgt		cr7, CreateArea_0x1f4
	blt		cr7, CreateArea_0x218
	_log	'placed'
	b		CreateArea_0x234

CreateArea_0x1f4
	_log	'placed at or above'
	b		CreateArea_0x234

CreateArea_0x218
	_log	'placed below'

CreateArea_0x234
	lwz		r8, Area.AddressSpacePtr(r31)
	lwz		r16, Area.LogicalEnd(r31)
	lwz		r9, Area.LogicalBase(r31)
	cmplw	r9, r16
	bge		major_0x10320_0x64
	bl		FindAreaAbove
	mr		r30, r8
	lwz		r14, Area.LogicalBase(r31)
	lwz		r15, Area.LogicalEnd(r31)
	lwz		r16, Area.LogicalSeparation(r31)
	lwz		r17,  0x0024(r30)
	lwz		r18,  0x0028(r30)
	lwz		r19,  0x0030(r30)
	lwz		r21, Area.AddressSpacePtr(r31)
	cmpwi	r17, -0x01
	add		r8, r15, r16
	add		r9, r15, r19
	beq		CreateArea_0x2b8
	cmplw	r8, r17
	cmplw	cr1, r9, r17
	bge		CreateArea_0x28c
	blt		cr1, CreateArea_0x2b8

CreateArea_0x28c
	beq		cr7, major_0x10320_0x64
	_log	' ... bc search^n'
	bgt		cr7, CreateArea_0x34c
	b		CreateArea_0x31c

CreateArea_0x2b8
	addi	r21, r21,  0x20
	lwz		r20,  0x0060(r30)
	cmpw	r20, r21
	beq		CreateArea_0x39c
	addi	r20, r20, -0x54
	lwz		r17,  0x0024(r20)
	lwz		r18,  0x0028(r20)
	lwz		r19,  0x0030(r20)
	add		r8, r18, r16
	add		r9, r18, r19
	cmplw	r8, r14
	cmplw	cr1, r9, r14
	bge		CreateArea_0x2f0
	blt		cr1, CreateArea_0x374

CreateArea_0x2f0
	beq		cr7, major_0x10320_0x64
	_log	' ... ab search^n'
	bgt		cr7, CreateArea_0x34c
	b		CreateArea_0x31c

CreateArea_0x31c
	subf	r8, r19, r17
	subf	r9, r16, r17
	cmplw	r8, r9
	lwz		r21, Area.Length(r31)
	ble		CreateArea_0x334
	mr		r8, r9

CreateArea_0x334
	subf	r8, r21, r8
	cmplw	r8, r14
	addi	r18, r8,  0x01
	lwz		r19, Area.Length(r31)
	bge		major_0x10320_0x64
	b		CreateArea_0x170

CreateArea_0x34c
	add		r8, r18, r19
	add		r9, r18, r16
	lwz		r20,  0x0078(r31)
	cmplw	r8, r9
	neg		r21, r20
	bge		CreateArea_0x368
	mr		r8, r9

CreateArea_0x368
	add		r18, r8, r21
	lwz		r19, Area.Length(r31)
	b		CreateArea_0x170

CreateArea_0x374
	addi	r19, r31,  0x54
	addi	r20, r20,  0x54
	lwz		r16,  0x0000(r20)
	stw		r16,  0x0000(r19)
	lwz		r16,  0x0008(r20)
	stw		r16,  0x0008(r19)
	stw		r20,  0x000c(r19)
	stw		r19,  0x000c(r16)
	stw		r19,  0x0008(r20)
	b		CreateArea_0x3b8

CreateArea_0x39c
	addi	r19, r31,  0x54
	stw		r20,  0x0000(r19)
	InsertAsNext	r19, r20, scratch=r16

CreateArea_0x3b8
	addi	r16, r31,  0x90
	InitList	r16, 'fenc', scratch=r17
	lwz		r16,  0x0020(r31)
	lwz		r17, Area.Flags(r31)
	rlwinm.	r8, r16,  0, 16, 16
	bne		CreateArea_0x64c
	rlwinm.	r8, r17,  0, 25, 25
	bne		CreateArea_0x41c
	lwz		r8, Area.Length(r31)
	rlwinm	r8, r8, 22, 10, 29
	mr		r29, r8

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	cmpwi	r8,  0x00
	stw		r8,  0x0040(r31)
	beq		CreateArea_0x460
	lwz		r9, Area.Length(r31)
	srwi	r9, r9, 12
	bl		major_0x10284
	lwz		r17, Area.Flags(r31)
	ori		r17, r17,  0x10
	stw		r17, Area.Flags(r31)

CreateArea_0x41c
	lwz		r17, Area.Flags(r31)
	andi.	r8, r17,  0x88
	lwz		r8, Area.Length(r31)
	bne		CreateArea_0x45c
	rlwinm	r8, r8, 21, 11, 30
	mr		r29, r8

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	cmpwi	r8,  0x00
	stw		r8,  0x003c(r31)
	beq		CreateArea_0x460
	lwz		r9, Area.Length(r31)
	srwi	r9, r9, 12
	bl		major_0x102a8
	lwz		r16, Area.Flags(r31)
	ori		r16, r16,  0x01
	stw		r16, Area.Flags(r31)

CreateArea_0x45c
	b		CreateArea_0x64c

CreateArea_0x460
	cmpwi	r29,  0xfd8
	ble		major_0x10320_0x20

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r17, Area.Flags(r31)
	li		r27,  0x00
	rlwinm.	r8, r17,  0, 25, 25
	bne		CreateArea_0x4b4
	lwz		r27, Area.Length(r31)
	srwi	r27, r27, 12
	cmpwi	r27,  0x400
	ble		CreateArea_0x4ac
	ori		r17, r17,  0x20
	stw		r17, Area.Flags(r31)
	addi	r27, r27,  0x400

CreateArea_0x4ac
	addi	r27, r27,  0x3ff
	srwi	r27, r27, 10

CreateArea_0x4b4
	lwz		r8, Area.Flags(r31)
	li		r29,  0x00
	rlwinm.	r9, r8,  0, 28, 28
	bne		CreateArea_0x4e8
	lwz		r29, Area.Length(r31)
	srwi	r29, r29, 12
	cmpwi	r29,  0x800
	ble		CreateArea_0x4e0
	ori		r8, r8,  0x02
	stw		r8, Area.Flags(r31)
	addi	r29, r29,  0x800

CreateArea_0x4e0
	addi	r29, r29,  0x7ff
	srwi	r29, r29, 11

CreateArea_0x4e8
	lwz		r18, PSA.FreePageCount(r1)
	add.	r8, r27, r29
	ble		major_0x102c8
	cmpw	r8, r18
	bgt		major_0x102c8
	lwz		r16, PSA.FreePageCount(r1)
	lwz		r17, PSA.UnheldFreePageCount(r1)
	subf	r16, r8, r16
	subf	r17, r8, r17
	stw		r16, PSA.FreePageCount(r1)
	stw		r17, PSA.UnheldFreePageCount(r1)
	mr.		r18, r27
	beq		CreateArea_0x5a0
	lwz		r16, PSA.FreeList + LLL.Next(r1)
	RemoveFromList		r16, scratch1=r17, scratch2=r19
	addi	r18, r18, -0x01
	stw		r16,  0x0040(r31)
	cmpwi	r18,  0x00
	lwz		r17, PSA.FreeList + LLL.Next(r1)
	mr		r8, r16
	subi	r16, r16, 4
	bgt		CreateArea_0x564
	li		r9,  0x400
	bl		major_0x10284
	b		CreateArea_0x5a0

CreateArea_0x564
	RemoveFromList		r17, scratch1=r19, scratch2=r20
	addi	r18, r18, -0x01
	stwu	r17,  0x0004(r16)
	mr		r8, r17
	li		r9,  0x400
	bl		major_0x10284
	lwz		r17, PSA.FreeList + LLL.Next(r1)
	cmpwi	r18,  0x00
	bgt		CreateArea_0x564

CreateArea_0x5a0
	mr.		r18, r29
	beq		CreateArea_0x62c
	lwz		r16, PSA.FreeList + LLL.Next(r1)
	RemoveFromList		r16, scratch1=r17, scratch2=r19
	addi	r18, r18, -0x01
	stw		r16,  0x003c(r31)
	cmpwi	r18,  0x00
	lwz		r17, PSA.FreeList + LLL.Next(r1)
	mr		r8, r16
	subi	r16, r16, 4
	bgt		CreateArea_0x5f0
	li		r9,  0x800
	bl		major_0x102a8
	b		CreateArea_0x62c

CreateArea_0x5f0
	RemoveFromList		r17, scratch1=r19, scratch2=r20
	addi	r18, r18, -0x01
	stwu	r17,  0x0004(r16)
	mr		r8, r17
	li		r9,  0x800
	bl		major_0x102a8
	lwz		r17, PSA.FreeList + LLL.Next(r1)
	cmpwi	r18,  0x00
	bgt		CreateArea_0x5f0

CreateArea_0x62c
	_AssertAndRelease	PSA.PoolLock, scratch=r16

CreateArea_0x64c
	lwz		r16, Area.Flags(r31)
	rlwinm.	r8, r16,  0, 28, 28
	beq		CreateArea_0x67c
	lwz		r16,  0x0044(r31)
	addi	r17, r31,  0x44
	stw		r16,  0x0000(r17)
	InsertAsPrev	r17, r16, scratch=r18
	b		major_0x10320_0x94

CreateArea_0x67c
	addi	r16, r31,  0x44
	InitList	r16, 'AKA ', scratch=r17
	b		major_0x10320_0x94



major_0x10284	;	OUTSIDE REFERER
	subi	r8, r8, 4
	addi	r9, r9, -0x01
	lwz		r20,  0x0074(r31)
	ori		r20, r20,  0x200

major_0x10284_0x10
	cmpwi	r9, noErr
	stwu	r20,  0x0004(r8)
	addi	r9, r9, -0x01
	bgt		major_0x10284_0x10
	blr



major_0x102a8	;	OUTSIDE REFERER
	addi	r8, r8, -0x02
	addi	r9, r9, -0x01
	li		r20,  0x7fff

major_0x102a8_0xc
	cmpwi	r9, noErr
	sthu	r20,  0x0002(r8)
	addi	r9, r9, -0x01
	bgt		major_0x102a8_0xc
	blr



major_0x102c8	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	addi	r30, r8,  0x08
	lwz		r8, PSA.AgerID(r1)
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r26, r8
	bne		major_0x10320_0x20
	li		r8,  0x02
	stw		r8,  0x0010(r26)
	stw		r30,  0x0014(r26)
	li		r29,  0x00
	stw		r29,  0x0018(r26)
	mr		r30, r26
	bl		CauseNotification
	b		major_0x10320_0x20



major_0x10320	;	OUTSIDE REFERER
	mr		r8, r31
	li		r9, -29294
	b		ReturnFromCreateArea

	;	Dead code:
	lwz		r8, Area.ID(r31)
	bl		DeleteID
	mr		r8, r31
	li		r9, kMPInvalidIDErr
	b		ReturnFromCreateArea

major_0x10320_0x20	;	OUTSIDE REFERER
	addi	r19, r31,  0x54
	RemoveFromList		r19, scratch1=r16, scratch2=r17
	lwz		r16, Area.Flags(r31)
	lwz		r8,  0x0040(r31)
	rlwinm.	r16, r16,  0, 25, 25
	bne		major_0x10320_0x58
	cmpwi	r8,  0x00
	bnel	PoolFree

major_0x10320_0x58
	lwz		r8,  0x003c(r31)
	cmpwi	r8,  0x00
	bnel	PoolFree

major_0x10320_0x64	;	OUTSIDE REFERER
	_log	' ... skipped^n'
	lwz		r8, Area.ID(r31)
	bl		DeleteID
	mr		r8, r31
	li		r9, kMPInsufficientResourcesErr
	b		ReturnFromCreateArea

major_0x10320_0x94	;	OUTSIDE REFERER
	_log	' ... created^n'
	mr		r8, r31
	li		r9,  0x00



ReturnFromCreateArea
	mfsprg	r16, 0
	lwz		r17, EWA.CreateAreaSavedLR(r16)
	mtlr	r17
	lmw		r25, EWA.CreateAreaSavedR25(r16)
	blr



;	ARG		AddressSpace *r8, 
;	RET		Area *r8

FindAreaAbove	;	OUTSIDE REFERER
	lwz		r8, AddressSpace.AreaList + LLL.Next(r8)

@loop
	subi	r8, r8, Area.LLL

	;	Return an area such that:
	;		max(Area.LogicalBase, Area.LogicalEnd) >= r9
	lwz		r16, Area.LogicalBase(r8)
	lwz		r17, Area.LogicalEnd(r8)
	cmplw	r16, r9
	cmplw	cr1, r17, r9
	bgelr
	bgelr	cr1

	;	Iterate over linked list
	lwz		r8, Area.LLL + LLL.Next(r8)
	b		@loop



#     # ######   #####                                       #                              #                         
##   ## #     # #     # #####  ######   ##   ##### ######   # #   #      #   ##    ####    # #   #####  ######   ##   
# # # # #     # #       #    # #       #  #    #   #       #   #  #      #  #  #  #       #   #  #    # #       #  #  
#  #  # ######  #       #    # #####  #    #   #   #####  #     # #      # #    #  ####  #     # #    # #####  #    # 
#     # #       #       #####  #      ######   #   #      ####### #      # ######      # ####### #####  #      ###### 
#     # #       #     # #   #  #      #    #   #   #      #     # #      # #    # #    # #     # #   #  #      #    # 
#     # #        #####  #    # ###### #    #   #   ###### #     # ###### # #    #  ####  #     # #    # ###### #    # 

;	This MP call does most of the work for the same-named MPLibrary
;	function. An "alias" Area is created from a template. This code is very
;	similar to regular MPCreateArea above, so differences are commented.

;	ARG		AreaID r3										; Alias-specific
;			long r4 PTEConfig
;			long r5 length
;			long r6 LogicalSeparation
;			long r7 flagsAndMinAlign
;			char *r8 LogicalBase
;			long r9 unknown									; Alias-specific
;	RET		r3 OSErr
;			char *r8 LogicalBase
;			AreaID r10										; Alias-specific

	DeclareMPCall	73, MPCreateAliasArea

MPCreateAliasArea

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	;	Confirm that the template Area is not itself an alias
	mr		r30, r8
	lwz		r16, Area.Flags(r30)
	rlwinm.	r8, r16, 0, Area.kAliasFlag, Area.kAliasFlag
	bne		ReleaseAndReturnParamErrFromMPCall

	;	Allocate the new Area
	li		r8, Area.Size
	bl		PoolAllocClear
	mr.		r31, r8
	beq		ReleaseAndScrambleMPCall

	;	Populate
	mfsprg	r28, 0
	lwz		r8, EWA.PA_CurAddressSpace(r28)
	stw		r8, Area.AddressSpacePtr(r31)

	stw		r3, Area.ParentAreaID(r31)						; Alias-specific

	stw		r30, Area.AliasLLL + LLL.Freeform(r31)			; Alias-specific

	stw		r4, Area.PTEConfig(r31)

	stw		r5, Area.Length(r31)

	lwz		r8, ContextBlock.r6(r6)
	stw		r8, Area.LogicalSeparation(r31)

	lwz		r8, ContextBlock.r7(r6)
	stw		r8, Area.FlagsAndMinAlign(r31)

	lwz		r8, ContextBlock.r8(r6)
	stw		r8, Area.LogicalBase(r31)

	lwz		r8, ContextBlock.r9(r6)							; Alias-specific
	stw		r8,  0x0080(r31)

	li		r8, 1 << (31 - Area.kAliasFlag)					; Alias-specific
	stw		r8, Area.Flags(r31)

	;	"Create" the area (everything after here is identical to MPCreateArea)
	mr		r8, r31
	bl		CreateArea

	_AssertAndRelease	PSA.SchLock, scratch=r16

	mr.		r3, r9
	bne		@error

	;	CreateArea returned successfully
	lwz		r8, Area.LogicalBase(r31)
	stw		r8, ContextBlock.r8(r6)

	lwz		r8, Area.ID(r31)
	stw		r8, ContextBlock.r10(r6)						; Alias-specific

	b		CommonMPCallReturnPath

	;	...or not
@error
	bl		PoolFree
	b		CommonMPCallReturnPath



#     # ######  ######                                       #                         
##   ## #     # #     # ###### #      ###### ##### ######   # #   #####  ######   ##   
# # # # #     # #     # #      #      #        #   #       #   #  #    # #       #  #  
#  #  # ######  #     # #####  #      #####    #   #####  #     # #    # #####  #    # 
#     # #       #     # #      #      #        #   #      ####### #####  #      ###### 
#     # #       #     # #      #      #        #   #      #     # #   #  #      #    # 
#     # #       ######  ###### ###### ######   #   ###### #     # #    # ###### #    # 

;	Delete an Area: the eponymous MPLibrary function is a simple wrapper

;	1. Only works on unprivileged Areas with no mapped pages.
;	2. Remove from parent address space.
;	3. Remove from template Area's alias list if applicable.
;	4. Delete the "PageMap" array if present.
;	5. Delete the "Fault Counter" array if present.
;	6. Delete the structure from the pool.

;	ARG		AreaID r3
;	RET		OSErr r3

	DeclareMPCall	74, MPDeleteArea

MPDeleteArea

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	;	Look up and validate
	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	;	If pages are still mapped in, fail with OOM
	;	If area is privileged, fail with privileged
	lwz		r17, Area.BytesMapped(r31)
	lwz		r29, Area.Flags(r31)
	cmpwi	cr1, r17, 0
	rlwinm.	r8, r29, 0, Area.kPrivilegedFlag, Area.kPrivilegedFlag
	bne		cr1, ReleaseAndReturnMPCallOOM
	bne		ReleaseAndReturnMPCallPrivilegedErr

	;	If is alias area and is not at back of queue (???), fail with OOM
	rlwinm.	r8, r29, 0, Area.kAliasFlag, Area.kAliasFlag
	lwz		r16, Area.AliasLLL + LLL.Next(r31)
	bne		@dont_check_for_nonempty_alias
	addi	r17, r31, Area.AliasLLL
	cmpw	r16, r17
	bne		ReleaseAndReturnMPCallOOM
@dont_check_for_nonempty_alias

	;	HTAB lock wraps around all Address Space structures?

	_Lock			PSA.HTABLock, scratch1=r18, scratch2=r9

	;	Remove from parent address space
	addi	r16, r31, Area.LLL
	RemoveFromList	r16, scratch1=r17, scratch2=r18

	;	Remove from template area's list of aliases, if necessary
	rlwinm.	r8, r29, 0, Area.kAliasFlag, Area.kAliasFlag
	addi	r16, r31, Area.AliasLLL
	beq		@not_alias_so_dont_remove_from_alias_list
	RemoveFromList	r16, scratch1=r17, scratch2=r18
@not_alias_so_dont_remove_from_alias_list

	_AssertAndRelease	PSA.HTABLock, scratch=r18


	;	DELETE PAGEMAP (array of [array of] per-page data)
	;	There are a few cases here...

	lwz		r8, Area.PageMapArrayPtr(r31)
	rlwinm.	r16, r29, 0, Area.kDontOwnPageMapArray, Area.kDontOwnPageMapArray
	cmpwi	cr1, r8, 0
	bne		@no_pagemap
	rlwinm.	r16, r29, 0, Area.kPageMapArrayInPool, Area.kPageMapArrayInPool
	beq		cr1, @no_pagemap
	bne		@pagemap_in_pool


	;	If PageMap occupies whole pages then return those pages
	;	directly to the free list without bothering the pool

	;	(Pool lock still protects free list)
	_Lock			PSA.PoolLock, scratch1=r18, scratch2=r9

	rlwinm.	r16, r29, 0, Area.kPageMapArrayIs2D, Area.kPageMapArrayIs2D
	beq		@pagemap_is_1d


	;	CASE: 2D array, all in whole pages

	;	r19 := size of ptr array in primary page
	lwz		r19, Area.Length(r31)
	mr		r20, r8
	srwi	r19, r19, 12
	addi	r19, r19, 0x3ff
	srwi	r19, r19, 10
	slwi	r19, r19, 2

	;	Free every second-level page
	subi	r19, r19, 4
@2d_pagemap_delete_loop
	lwzx	r8, r19, r20
	bl		FreePageListPush ; PhysicalPage *r8
	cmpwi	r19, 0
	subi	r19, r19, 4
	bgt		@2d_pagemap_delete_loop

	mr		r8, r20


	;	COMMON CASE: single first-level page of 2D or 1D-in-whole-page case

@pagemap_is_1d
	bl		FreePageListPush ; PhysicalPage *r8

	_AssertAndRelease	PSA.PoolLock, scratch=r18

	b		@pagemap_deleted


	;	CASE: 1D array in pool block (not whole page)

@pagemap_in_pool
	bl		PoolFree


@pagemap_deleted
@no_pagemap


	;	DELETE FAULT COUNTER ARRAY
	;	Again, the code to manage the cases is tricky.

	lwz		r8, Area.FaultCtrArrayPtr(r31)
	rlwinm.	r16, r29, 0, Area.kFaultCtrArrayInPool, Area.kFaultCtrArrayInPool
	cmpwi	cr1, r8, 0
	beq		cr1, @no_faultctr
	bne		@faultctr_in_pool


	;	Whole-page cases require us to get the Pool lock manually (for free list)
	_Lock			PSA.PoolLock, scratch1=r18, scratch2=r9

	rlwinm.	r16, r29, 0, Area.kFaultCtrArrayIs2D, Area.kFaultCtrArrayIs2D
	beq		@faultctr_is_1d


	;	CASE: 2D array, all in whole pages

	;	Once again, r19 = the size of the primary array
	lwz		r19, Area.Length(r31)
	mr		r20, r8
	srwi	r19, r19, 12
	addi	r19, r19, 0x7ff
	srwi	r19, r19, 11
	slwi	r19, r19, 2

	;	Free every second-level page
	subi	r19, r19, 4
@2d_faultctr_delete_loop
	lwzx	r8, r19, r20
	bl		FreePageListPush ; PhysicalPage *r8
	cmpwi	r19, 0
	subi	r19, r19, 4
	bgt		@2d_faultctr_delete_loop

	mr		r8, r20


	;	COMMON CASE: single first-level page of 2D or 1D-in-whole-page case

@faultctr_is_1d
	bl		FreePageListPush ; PhysicalPage *r8

	_AssertAndRelease	PSA.PoolLock, scratch=r18

	b		@faultctr_deleted


	;	CASE: 1D array in pool block (not whole page)

@faultctr_in_pool
	bl		PoolFree


@faultctr_deleted
@no_faultctr


	;	Delete the struct from the pool
	lwz		r8, Area.ID(r31)
	bl		DeleteID
	mr		r8, r31
	bl		PoolFree


	;	Return noErr
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####                  #                          #####                  
##   ## #     # #     # ###### #####   # #   #####  ######   ##   #     # # ###### ###### 
# # # # #     # #       #        #    #   #  #    # #       #  #  #       #     #  #      
#  #  # ######   #####  #####    #   #     # #    # #####  #    #  #####  #    #   #####  
#     # #             # #        #   ####### #####  #      ######       # #   #    #      
#     # #       #     # #        #   #     # #   #  #      #    # #     # #  #     #      
#     # #        #####  ######   #   #     # #    # ###### #    #  #####  # ###### ###### 

;	ARG		MPAreaID r3, flag_24_means_change_left_side r4

;	Straight MPLibrary wrapper: no
;	In Universal Interfaces: no

	DeclareMPCall	75, MPSetAreaSize

MPSetAreaSize

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr

	;	Chase Daniel about this field!
	lwz		r16, Area.FlagsAndMinAlign(r31)
	rlwinm.	r8, r16, 0, 16, 16
	bne		ReleaseAndReturnMPCallOOM

	lwz		r18, Area.DefaultAlignmentMask(r31)
	lwz		r17, Area.Length(r31)
	and.	r5, r5, r18
	and		r17, r17, r18
	ble		ReleaseAndReturnParamErrFromMPCall


	;	DECIDE: MAKE BIGGER OR MAKE SMALLER?

	subf.	r27, r17, r5							; r27 = how much space to add
	beq		ReleaseAndReturnZeroFromMPCall			; area is already this size (ignoring change)
	bgt		@SHRINK_AREA							; not actually allowed


;EXPAND AREA

	rlwinm.	r8, r4,  0, 24, 24
	lwz		r28, Area.LogicalBase(r31)
	lwz		r29, Area.LogicalEnd(r31)
	bne		@expand_downwards

;expand upwards ; (replace LogicalBase with new LogicalEnd)
	add		r28, r27, r29
	addi	r28, r28, 1
	b		@endif

@expand_downwards ; (replace LogicalEnd with new LogicalBase)
	subf	r29, r27, r28
	subi	r29, r29, 1
@endif


	_Lock			PSA.PoolLock, scratch1=r14, scratch2=r15
	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15


	;	Free pages from LogicalBase to LogicalEnd, flushing PTEs that might conflict (a million iterations???)

	lwz		r27, Area.PageSize(r31)

@freelist_loop
	mr		r8, r28
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland

	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7

	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, @there_is_no_page_to_free

	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30

	;	Unset PLE bit kPLEFlagHasPhysPage and free the physical page
	lwz		r17, 0(r30)
	_bclr	r17, r17, Area.kPLEFlagHasPhysPage
	rlwinm	r8, r17, 0, 0xfffff000
	stw		r17, 0(r30)
	bl		FreePageListPush ; PhysicalPage *r8

@there_is_no_page_to_free

	add		r28, r28, r27
	cmplw	r28, r29
	ble		@freelist_loop



	rlwinm.	r8, r4,  0, 24, 24
	lwz		r28, Area.LogicalBase(r31)
	beq		@_138

	lwz		r27,  0x0068(r31)
	add		r29, r29, r27

@_100
	mr		r8, r28
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	mr		r26, r30
	mr		r8, r29
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	lwz		r17,  0x0000(r30)
	stw		r17,  0x0000(r26)
	lwz		r16, Area.LogicalEnd(r31)
	add		r28, r28, r27
	add		r29, r29, r27
	cmplw	r29, r16
	ble		@_100

@_138

	_AssertAndRelease	PSA.HTABLock, scratch=r8


	lwz		r16, Area.Flags(r31)
	rlwinm.	r8, r16,  0, 25, 25
	bne		@_16c

	rlwinm.	r8, r16,  0, 27, 27
	bne		@_16c


@_16c
	_AssertAndRelease	PSA.PoolLock, scratch=r8
	b		@_190

@_190
	rlwinm.	r8, r4,  0, 24, 24
	lwz		r16, Area.LogicalBase(r31)
	bne		@_1b0
	add		r17, r16, r5
	addi	r17, r17, -0x01
	stw		r5, Area.Length(r31)
	stw		r17, Area.LogicalEnd(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@_1b0
	lwz		r17, Area.LogicalEnd(r31)
	subf	r16, r5, r17
	stw		r5, Area.Length(r31)
	addi	r16, r16,  0x01
	stw		r16, Area.LogicalBase(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall


@SHRINK_AREA

	rlwinm.	r8, r4,  0, 24, 24
	lwz		r28, Area.LogicalBase(r31)
	lwz		r29, Area.LogicalEnd(r31)
	bne		ReleaseAndMPCallWasBad

	add		r28, r27, r29
	addi	r28, r28,  0x01

	b		@_1ec
	;	Dead code:
	subf	r29, r27, r28
	subi	r29, r29, 1
@_1ec

	b		ReleaseAndMPCallWasBad



#     # ######   #####                #####                ######                          #                                       
##   ## #     # #     # ###### ##### #     # #    # #####  #     #   ##    ####  ######   # #    ####   ####  ######  ####   ####  
# # # # #     # #       #        #   #       #    # #    # #     #  #  #  #    # #       #   #  #    # #    # #      #      #      
#  #  # ######   #####  #####    #    #####  #    # #####  ######  #    # #      #####  #     # #      #      #####   ####   ####  
#     # #             # #        #         # #    # #    # #       ###### #  ### #      ####### #      #      #           #      # 
#     # #       #     # #        #   #     # #    # #    # #       #    # #    # #      #     # #    # #    # #      #    # #    # 
#     # #        #####  ######   #    #####   ####  #####  #       #    #  ####  ###### #     #  ####   ####  ######  ####   ####  

;	Straight MPLibrary wrapper: almost
;	In Universal Interfaces: no

	DeclareMPCall	130, MPSetSubPageAccess

MPSetSubPageAccess

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lis		r16, -0x01
	ori		r16, r16,  0xfff8
	lwz		r17,  0x0020(r31)
	and.	r16, r16, r4
	bne		ReleaseAndReturnParamErrFromMPCall
	rlwinm.	r8, r17,  0, 16, 16
	bne		ReleaseAndReturnParamErrFromMPCall
	mr		r29, r5
	lwz		r18,  0x0134(r6)
	lwz		r19,  0x0068(r31)
	lwz		r16, Area.LogicalBase(r31)
	cmplw	r18, r19
	add		r28, r18, r29
	bge		ReleaseAndReturnParamErrFromMPCall
	lwz		r17,  0x007c(r31)
	addi	r28, r28, -0x01
	lwz		r18,  0x0020(r31)
	lwz		r19, Area.LogicalEnd(r31)
	cmplw	cr1, r29, r16
	cmplw	cr2, r28, r19
	blt		cr1, ReleaseAndReturnParamErrFromMPCall
	bgt		cr2, ReleaseAndReturnParamErrFromMPCall
	xor		r8, r28, r29
	rlwinm.	r8, r8,  0,  0, 19
	bne		ReleaseAndReturnParamErrFromMPCall

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r29
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	beq		SpacePanicIsland
	rlwinm	r8, r16,  0, 29, 30
	lwz		r16,  0x0000(r30)
	cmpwi	cr7, r8,  0x04
	beq		cr7, ReleaseAndReturnParamErrFromMPCall
	lwz		r16,  0x0098(r31)

MPCall_130_0xe8
	addi	r17, r31,  0x90
	cmpw	r16, r17
	addi	r17, r16,  0x14
	beq		MPCall_130_0x11c
	lwz		r8,  0x0010(r16)
	cmplwi	r8,  0x1f8
	add		r9, r8, r17
	blt		MPCall_130_0x110
	lwz		r16,  0x0008(r16)
	b		MPCall_130_0xe8

MPCall_130_0x110
	addi	r8, r8,  0x08
	addi	r9, r9,  0x08
	b		MPCall_130_0x15c

MPCall_130_0x11c
	li		r8,  0x214

;	r1 = kdp
;	r8 = size
	bl		PoolAllocClear
;	r8 = ptr

	mr.		r16, r8
	beq		ReleaseAndScrambleMPCall
	addi	r18, r31,  0x90
	lis		r17,  0x4645
	ori		r17, r17,  0x4e43
	stw		r17,  0x0004(r16)
	stw		r18,  0x0000(r16)
	InsertAsPrev	r16, r18, scratch=r19
	li		r8,  0x00
	addi	r9, r16,  0x14

MPCall_130_0x15c
	stw		r8,  0x0010(r16)
	stw		r29,  0x0000(r9)
	stw		r28,  0x0004(r9)

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r29
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland

	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7

	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, MPCall_130_0x19c

	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30

MPCall_130_0x19c
	lwz		r17,  0x0000(r30)
	li		r16,  0x06
	rlwimi	r17, r16,  0, 29, 30
	stw		r17,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####                  #                            #                                       
##   ## #     # #     # ###### #####   # #   #####  ######   ##     # #    ####   ####  ######  ####   ####  
# # # # #     # #       #        #    #   #  #    # #       #  #   #   #  #    # #    # #      #      #      
#  #  # ######   #####  #####    #   #     # #    # #####  #    # #     # #      #      #####   ####   ####  
#     # #             # #        #   ####### #####  #      ###### ####### #      #      #           #      # 
#     # #       #     # #        #   #     # #   #  #      #    # #     # #    # #    # #      #    # #    # 
#     # #        #####  ######   #   #     # #    # ###### #    # #     #  ####   ####  ######  ####   ####  

;	ARG		MPAreaID r3, bits_to_set r4, bits_to_unset r5, start r6, len r7
;	RET		OSStatus r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	76, MPSetAreaAccess

MPSetAreaAccess

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	;	Fail if any bits other than these are set in r4
	lisori	r16, ~%11101111
	and.	r16, r16, r4
	bne		ReleaseAndReturnParamErrFromMPCall

	;	Or in r5
	lisori	r16, ~%11101111
	and.	r16, r16, r5
	bne		ReleaseAndReturnParamErrFromMPCall

	;	Get more args
	lwz		r29, ContextBlock.r6(r6)
	lwz		r18, ContextBlock.r7(r6)

	;	Figure out whether the Area covers the specified range
	lwz		r16, Area.LogicalBase(r31)
	add		r28, r18, r29
	lwz		r17, Area.DefaultAlignmentMask(r31) ; unused?
	subi	r28, r28, 1
	lwz		r18, Area.FlagsAndMinAlign(r31)
	lwz		r19, Area.LogicalEnd(r31)

	;	Check that range lies within Area (cr1/2).
	;	Also, two cases depending on FlagsAndMinAlign bit 16
	rlwinm.	r8, r18, 0, 16, 16
	cmplw	cr1, r29, r16
	cmplw	cr2, r28, r19
	blt		cr1, ReleaseAndReturnParamErrFromMPCall
	bgt		cr2, ReleaseAndReturnParamErrFromMPCall
	bne		@BIT_16_SET


;BIT 16 CLEAR

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

@pageloop
	mr		r8, r29
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland

	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7

	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, @no_physical_page
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30
@no_physical_page

	lwz		r17, 0(r30)
	bl		major_0x10d38

	and		r8, r4, r5
	orc		r9, r4, r5
	or		r18, r18, r8
	and		r18, r18, r9

	lwz		r17, 0(r30)

	rlwinm.	r8, r18,  0, 26, 26
	bc		BO_IF_NOT, 31, @118
	bgt		cr6, @118
	beq		@118

	;	Remove the page in question from the data cache
	rlwinm	r9, r17, 0, 0xFFFFF000
	lwz		r8, Area.PageSize(r31)
@dcache_flush_loop
	subi	r8, r8, 32
	dcbf	r8, r9
	cmpwi	r8, 0
	bgt		@dcache_flush_loop
	sync

	;	Also from the inst cache
	lwz		r8, Area.PageSize(r31)
@icache_flush_loop
	subi	r8, r8, 32
	icbi	r8, r9
	cmpwi	r8, 0
	bgt		@icache_flush_loop
	isync

@118
	bl		major_0x10cb8 ; PTE r16/r17, control r18 // PTE r16/r17

	lwz		r19, Area.PageSize(r31)
	stw		r17, 0(r30)
	add		r29, r29, r19
	subf.	r8, r29, r28
	bge		@pageloop
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

@BIT_16_SET

	bne		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r18,  0x001c(r31)
	and		r8, r4, r5
	orc		r9, r4, r5
	or		r18, r18, r8
	and		r18, r18, r9
	stw		r18,  0x001c(r31)
	lwz		r16,  0x0070(r31)
	lwz		r17,  0x0074(r31)
	bl		major_0x10cb8 ; PTE r16/r17, control r18 // PTE r16/r17
	stw		r16,  0x0070(r31)
	stw		r17,  0x0074(r31)

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	lwz		r27,  0x0068(r31)
	mr		r28, r19

@1a4
	mr		r8, r29
	lwz		r9, Area.AddressSpacePtr(r31)
	bl		SpaceL2PIgnoringBATs ; LogicalPage *r8, MPAddressSpace *r9 // PhysicalPage *r17
	beq		@1bc
	bl		InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bl		DeletePTE ; PTE *r18, PLE *r30

@1bc
	add		r29, r29, r27
	subf.	r8, r29, r28
	bge		@1a4
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	ARG		PTE r16, PTE r17, control r18
;	RET		PTE r16, PTE r17
;	CLOB	CR


major_0x10cb8 ; PTE r16/r17, control r18 // PTE r16/r17

	rlwinm	r16, r16,  0, 0xFFFFFF87		;	fill these in again...
	rlwinm	r17, r17,  0, 0xFFFFFF1F		;	
	rlwinm	r16, r16,  0, 0xFFFFFFFC		;	clear
	rlwinm	r17, r17,  0, 0xFFFFFFF9		;	


	;	Load control argument into condition register
	;	Note: this is a pretty expensive operation, not in hot path

	mtcr	r18


	bge		cr6, @80_not_set				;	if(control & 0x80) {
	ori		r17, r17, 0x80					;		PTE2 |= 0x80; //set referenced bit
	ori		r16, r16, 0x08					;		PTE1 |= 0x08; //set guard bit
@80_not_set									;	}


	ble		cr6, @40_not_set				;	if(control & 0x40) {
	ori		r16, r16, 0x40					;		PTE1 |= 0x40; //set change bit
	b		@40_endif						;	} else {
@40_not_set
	ori		r17, r17, 0x20					;		PTE2 |= 0x20; //set W bit
@40_endif									;	}


	bne		cr6, @20_not_set				;	if(control & 0x20) {
	ori		r17, r17,  0x40					;		PTE2 |= 0x40; //set change bit
	ori		r16, r16,  0x20					;		PTE1 |= 0x20; //set W bit
@20_not_set									;	}


	ble		cr7, @04_not_set				;	if(control & 0x04) {
@04_not_set									;	}


	bge		cr7, @08_not_set				;	if(control & 0x08) {
	ori		r17, r17, 0x06					;		PTE2 |= 0x06; //set leftmost protection bit and reserved bit
	ori		r16, r16, 0x01					;		PTE1 |= 0x01; //set rightmost protection bit
	b		@block_endif					;	}
@08_not_set
	bne		cr7, @02_not_set				;	else if(control & 0x02) {
	ori		r17, r17, 0x00					;		PTE2 |= 0x00; //useless instruction?
	ori		r16, r16, 0x02					;		PTE1 |= 0x02; //set second protection bit
	b		@block_endif					;	}
@02_not_set
	bc		BO_IF_NOT, 31, @01_not_set				;	else if(control & 0x01) {
	ori		r17, r17, 0x04					;		PTE2 |= 0x04; //set reserved bit.
	ori		r16, r16, 0x03					;		PTE1 |= 0x03: //set both protection bits
	b		@block_endif					;	}
@01_not_set									;	else {
	ori		r17, r17, 0x02					;		PTE2 |= 0x02; //set second protection bit
	ori		r16, r16, 0x00					;		PTE1 |= 0x00; //useless instruction?
@block_endif								;	}


	ori		r16, r16,  0x10					;	PTE1 |= 0x10; //set M bit


	blr										;	return (PTE1, PTE2);



major_0x10d38 ; PLE r17

	andi.	r16, r17, %110

	li		r18, 0

	cmpwi	cr0, r16, %010
	cmpwi	cr1, r16, %110
	beq		cr0, @disconcordant

	li		r18, %100
	andi.	r16, r17, %100
	ori		r18, r18, %001					; may as well have set both P bits in r8?
	bne		@disconcordant
	ori		r18, r18, %010
@disconcordant

	bne		cr1, major_0x10d38_0x30
	ori		r18, r18, 0x8

major_0x10d38_0x30
	andi.	r16, r17, 0x20
	bne		major_0x10d38_0x3c
	ori		r18, r18, 0x40

major_0x10d38_0x3c
	andi.	r16, r17, 0x40
	beq		major_0x10d38_0x48
	ori		r18, r18, 0x20

major_0x10d38_0x48
	andi.	r16, r17, 0x80
	beq		major_0x10d38_0x54
	ori		r18, r18, 0x80

major_0x10d38_0x54
	blr



major_0x10d38_0x58	;	OUTSIDE REFERER
	andi.	r16, r17,  0x03
	li		r18,  0x04
	cmpwi	cr1, r16,  0x01
	beq		major_0x10d38_0x78
	andi.	r16, r17,  0x01
	ori		r18, r18,  0x01
	bne		major_0x10d38_0x78
	ori		r18, r18,  0x02

major_0x10d38_0x78
	bne		cr1, major_0x10d38_0x80
	ori		r18, r18,  0x08

major_0x10d38_0x80
	andi.	r16, r17,  0x40
	beq		major_0x10d38_0x8c
	ori		r18, r18,  0x40

major_0x10d38_0x8c
	andi.	r16, r17,  0x20
	beq		major_0x10d38_0x98
	ori		r18, r18,  0x20

major_0x10d38_0x98
	andi.	r16, r17,  0x08
	beq		major_0x10d38_0xa4
	ori		r18, r18,  0x80

major_0x10d38_0xa4
	blr



#     # ######   #####                  #                            #                                       
##   ## #     # #     # ###### #####   # #   #####  ######   ##     # #    ####   ####  ######  ####   ####  
# # # # #     # #       #        #    #   #  #    # #       #  #   #   #  #    # #    # #      #      #      
#  #  # ######  #  #### #####    #   #     # #    # #####  #    # #     # #      #      #####   ####   ####  
#     # #       #     # #        #   ####### #####  #      ###### ####### #      #      #           #      # 
#     # #       #     # #        #   #     # #   #  #      #    # #     # #    # #    # #      #    # #    # 
#     # #        #####  ######   #   #     # #    # ###### #    # #     #  ####   ####  ######  ####   ####  

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: no

	DeclareMPCall	123, MPGetAreaAccess

MPGetAreaAccess

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	lwz		r18,  0x0020(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	rlwinm.	r8, r18,  0, 16, 16
	lwz		r5,  0x001c(r31)

;	r1 = kdp
	bne		ReleaseAndReturnZeroFromMPCall

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30
	lwz		r17,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	bl		major_0x10d38
	mr		r5, r18

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####                  #                         ######                                       ######                                              
##   ## #     # #     # ###### #####   # #   #####  ######   ##   #     #   ##    ####  #    # # #    #  ####  #     # #####   ####  #    # # #####  ###### #####  
# # # # #     # #       #        #    #   #  #    # #       #  #  #     #  #  #  #    # #   #  # ##   # #    # #     # #    # #    # #    # # #    # #      #    # 
#  #  # ######   #####  #####    #   #     # #    # #####  #    # ######  #    # #      ####   # # #  # #      ######  #    # #    # #    # # #    # #####  #    # 
#     # #             # #        #   ####### #####  #      ###### #     # ###### #      #  #   # #  # # #  ### #       #####  #    # #    # # #    # #      #####  
#     # #       #     # #        #   #     # #   #  #      #    # #     # #    # #    # #   #  # #   ## #    # #       #   #  #    #  #  #  # #    # #      #   #  
#     # #        #####  ######   #   #     # #    # ###### #    # ######  #    #  ####  #    # # #    #  ####  #       #    #  ####    ##   # #####  ###### #    # 

;	Does the blue task always get these notifications?

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

;	ARG		AreaID r3, NotificationID r4, long r5
;	RET		OSErr r3

	DeclareMPCall	77, MPSetAreaBackingProvider

MPSetAreaBackingProvider

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	;	Expect Area ID in r3
	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	;	r4 optionally contains...
	mr.		r8, r4
	beq		@no_notification

	;	a Notification ID
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
@no_notification

	stw		r4, Area.BackingProviderID(r31)
	stw		r5, Area.BackingProviderMisc(r31)

	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####                               #######  #####  
##   ## #     # #     #   ##   #      #              #    #  #     # 
# # # # #     # #        #  #  #      #                  #   #     # 
#  #  # ######  #       #    # #      #                 #     #####  
#     # #       #       ###### #      #                #     #     # 
#     # #       #     # #    # #      #                #     #     # 
#     # #        #####  #    # ###### ######  ######   #      #####  

;	Dump Area info to userspace

	DeclareMPCall	78, MPCall_78

MPCall_78	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	cmpwi	r4,  0x01
	bne		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5,  0x00
	bne		MPCall_78_0x68
	li		r16,  0x01
	stw		r16,  0x0134(r6)
	lwz		r16, Area.ProcessID(r31)
	stw		r16,  0x013c(r6)
	lwz		r16, Area.AddressSpaceID(r31)
	stw		r16,  0x0144(r6)
	lwz		r16,  0x0014(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_78_0x68
	cmplwi	r5,  0x10
	bne		MPCall_78_0x9c
	lwz		r16,  0x0018(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x001c(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0020(r31)
	stw		r16,  0x0144(r6)
	lwz		r16, Area.LogicalBase(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_78_0x9c
	cmplwi	r5,  0x20
	bne		MPCall_78_0xd0
	lwz		r16, Area.Length(r31)
	stw		r16,  0x0134(r6)
	lwz		r16, Area.LogicalSeparation(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0034(r31)
	stw		r16,  0x0144(r6)
	lwz		r16, Area.BytesMapped(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_78_0xd0
	cmplwi	r5,  0x30
	bne		MPCall_78_0xfc
	lwz		r16,  0x0068(r31)
	stw		r16,  0x0134(r6)
	lwz		r16,  0x0080(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0084(r31)
	stw		r16,  0x0144(r6)
	li		r16,  0x0c
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_78_0xfc
	cmpwi	r5,  0x3c
	bne		ReleaseAndReturnParamErrFromMPCall
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               #     #                        #                         ### ######  
##   ## #     # #     # ###### ##### ##    # ###### #    # #####   # #   #####  ######   ##    #  #     # 
# # # # #     # #       #        #   # #   # #       #  #    #    #   #  #    # #       #  #   #  #     # 
#  #  # ######  #  #### #####    #   #  #  # #####    ##     #   #     # #    # #####  #    #  #  #     # 
#     # #       #     # #        #   #   # # #        ##     #   ####### #####  #      ######  #  #     # 
#     # #       #     # #        #   #    ## #       #  #    #   #     # #   #  #      #    #  #  #     # 
#     # #        #####  ######   #   #     # ###### #    #   #   #     # #    # ###### #    # ### ######  

;	OSStatus MPGetNextAreaID(MPAddressSpaceID owningSpaceID, MPAreaID *areaID)

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: yes

	DeclareMPCall	79, MPGetNextAreaID

MPGetNextAreaID

	mr.		r8, r3
	mfsprg	r28, 0
	lwz		r31, EWA.PA_CurAddressSpace(r28)
	beq		MPCall_79_0x20
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne		ReturnMPCallInvalidIDErr
	mr		r31, r8

MPCall_79_0x20
	lwz		r3, Area.ID(r31)

MPCall_79_0x24
	mr		r8, r4
	li		r9,  0x0b
	bl		GetNextIDOfClass
	cmpwi	r8,  0x00
	beq		ReturnMPCallInvalidIDErr
	mr		r4, r8
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cgrp, 11:area, 12:not, 13:log

	lwz		r16,  0x0010(r8)
	cmpw	r16, r3
	bne		MPCall_79_0x24
	b		ReturnZeroFromMPCall



#     # ######   #####                  #                         #######                         #                                              
##   ## #     # #     # ###### #####   # #   #####  ######   ##   #       #####   ####  #    #   # #   #####  #####  #####  ######  ####   ####  
# # # # #     # #       #        #    #   #  #    # #       #  #  #       #    # #    # ##  ##  #   #  #    # #    # #    # #      #      #      
#  #  # ######  #  #### #####    #   #     # #    # #####  #    # #####   #    # #    # # ## # #     # #    # #    # #    # #####   ####   ####  
#     # #       #     # #        #   ####### #####  #      ###### #       #####  #    # #    # ####### #    # #    # #####  #           #      # 
#     # #       #     # #        #   #     # #   #  #      #    # #       #   #  #    # #    # #     # #    # #    # #   #  #      #    # #    # 
#     # #        #####  ######   #   #     # #    # ###### #    # #       #    #  ####  #    # #     # #####  #####  #    # ######  ####   ####  

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: yes

	DeclareMPCall	80, MPGetAreaFromAddress

MPGetAreaFromAddress

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	mfsprg	r9, 0
	bne		MPCall_80_0x2c
	lwz		r8, EWA.PA_CurAddressSpace(r9)
	b		MPCall_80_0x38

MPCall_80_0x2c 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr

MPCall_80_0x38
	mr		r9, r4
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	li		r5,  0x00
	cmplw	r16, r4
	bgt		ReleaseAndReturnParamErrFromMPCall
	lwz		r5,  0x0000(r8)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               #     #                        #                         #######                         #                                              
##   ## #     # #     # ###### ##### ##    # ###### #    # #####   # #   #####  ######   ##   #       #####   ####  #    #   # #   #####  #####  #####  ######  ####   ####  
# # # # #     # #       #        #   # #   # #       #  #    #    #   #  #    # #       #  #  #       #    # #    # ##  ##  #   #  #    # #    # #    # #      #      #      
#  #  # ######  #  #### #####    #   #  #  # #####    ##     #   #     # #    # #####  #    # #####   #    # #    # # ## # #     # #    # #    # #    # #####   ####   ####  
#     # #       #     # #        #   #   # # #        ##     #   ####### #####  #      ###### #       #####  #    # #    # ####### #    # #    # #####  #           #      # 
#     # #       #     # #        #   #    ## #       #  #    #   #     # #   #  #      #    # #       #   #  #    # #    # #     # #    # #    # #   #  #      #    # #    # 
#     # #        #####  ######   #   #     # ###### #    #   #   #     # #    # ###### #    # #       #    #  ####  #    # #     # #####  #####  #    # ######  ####   ####  

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: yes

	DeclareMPCall	125, MPGetNextAreaFromAddress

MPGetNextAreaFromAddress

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	mfsprg	r9, 0
	bne		MPCall_125_0x2c
	lwz		r8, EWA.PA_CurAddressSpace(r9)
	b		MPCall_125_0x38

MPCall_125_0x2c 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr

MPCall_125_0x38
	mr		r9, r4
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	li		r5,  0x00
	cmplw	r16, r4
	bgt		MPCall_125_0x58
	lwz		r8,  0x005c(r8)
	addi	r8, r8, -0x54

MPCall_125_0x58
	lwz		r9,  0x002c(r8)
	cmpwi	r9, noErr
	beq		ReleaseAndReturnParamErrFromMPCall
	lwz		r5,  0x0000(r8)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               ######                                                #                                              
##   ## #     # #     # ###### ##### #     # #    # #   #  ####  #  ####    ##   #        # #   #####  #####  #####  ######  ####   ####  
# # # # #     # #       #        #   #     # #    #  # #  #      # #    #  #  #  #       #   #  #    # #    # #    # #      #      #      
#  #  # ######  #  #### #####    #   ######  ######   #    ####  # #      #    # #      #     # #    # #    # #    # #####   ####   ####  
#     # #       #     # #        #   #       #    #   #        # # #      ###### #      ####### #    # #    # #####  #           #      # 
#     # #       #     # #        #   #       #    #   #   #    # # #    # #    # #      #     # #    # #    # #   #  #      #    # #    # 
#     # #        #####  ######   #   #       #    #   #    ####  #  ####  #    # ###### #     # #####  #####  #    # ######  ####   ####  

;	Straight MPLibrary wrapper: no
;	In Universal Interfaces: no

	DeclareMPCall	81, MPGetPhysicalAddress

MPGetPhysicalAddress

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	lwz		r18,  0x0020(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	rlwinm.	r8, r18,  0, 16, 16
	lwz		r19,  0x0070(r31)
	beq		MPCall_81_0x70
	lwz		r17, Area.BytesMapped(r31)
	rlwinm	r19, r19,  0,  0, 19
	cmpwi	r17,  0x00
	subf	r18, r16, r4
	beq		ReleaseAndReturnParamErrFromMPCall
	add		r5, r18, r19

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_81_0x70
	li		r3,  0x00

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, MPCall_81_0xc8
	mr		r5, r17
	rlwimi	r5, r4,  0, 20, 31

MPCall_81_0xa4
	_AssertAndRelease	PSA.HTABLock, scratch=r8
	b		ReleaseAndReturnMPCall

MPCall_81_0xc8
	li		r3, kMPInsufficientResourcesErr
	b		MPCall_81_0xa4



#     # ######   #####               ######                                             #######                                  
##   ## #     # #     # ###### ##### #     # #    # #   #  ####  #  ####    ##   #      #       #    # ##### ###### #    # ##### 
# # # # #     # #       #        #   #     # #    #  # #  #      # #    #  #  #  #      #        #  #    #   #      ##   #   #   
#  #  # ######  #  #### #####    #   ######  ######   #    ####  # #      #    # #      #####     ##     #   #####  # #  #   #   
#     # #       #     # #        #   #       #    #   #        # # #      ###### #      #         ##     #   #      #  # #   #   
#     # #       #     # #        #   #       #    #   #   #    # # #    # #    # #      #        #  #    #   #      #   ##   #   
#     # #        #####  ######   #   #       #    #   #    ####  #  ####  #    # ###### ####### #    #   #   ###### #    #   #   

;	Straight MPLibrary wrapper: no
;	In Universal Interfaces: no

	DeclareMPCall	98, MPGetPhysicalExtent

MPGetPhysicalExtent

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	mr		r31, r8
	bne		ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	mr		r29, r5
	add		r5, r5, r4
	lwz		r18,  0x0020(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r20, Area.BytesMapped(r31)
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r20,  0x00
	beq		MPCall_98_0x84
	beq		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r19,  0x0070(r31)
	subf	r18, r16, r4
	rlwinm	r19, r19,  0,  0, 19
	add		r16, r18, r19
	stw		r16,  0x0134(r6)
	stw		r29,  0x013c(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_98_0x84

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	mr		r28, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	crclr	cr3_eq
	li		r3,  0x00
	bso		cr7, MPCall_98_0xc4
	crset	cr3_eq
	li		r3, kMPInsufficientResourcesErr

MPCall_98_0xc4
	rlwimi	r17, r4,  0, 20, 31
	rlwinm	r29, r17,  0,  0, 19
	stw		r17,  0x0134(r6)

MPCall_98_0xd0
	lwz		r16,  0x0068(r31)
	add		r28, r28, r16
	add		r29, r29, r16
	cmplw	cr2, r28, r5
	bgt		cr2, MPCall_98_0x140
	mr		r8, r28
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	rlwinm	r17, r17,  0,  0, 19
	crxor	31, 31, 14
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, MPCall_98_0x10c
	beq		cr3, MPCall_98_0xd0
	cmplw	r29, r17
	beq		MPCall_98_0xd0

MPCall_98_0x10c
	lwz		r16,  0x007c(r31)
	and		r28, r28, r16
	subf	r16, r4, r28

MPCall_98_0x118
	stw		r16,  0x013c(r6)
	_AssertAndRelease	PSA.HTABLock, scratch=r8
	b		ReleaseAndReturnMPCall

MPCall_98_0x140
	addi	r5, r5,  0x01
	beq		cr3, MPCall_98_0x170
	mr		r8, r28
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	rlwinm	r17, r17,  0,  0, 19
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, MPCall_98_0x170
	cmplw	r29, r17
	bne		MPCall_98_0x170
	subf	r16, r4, r5
	b		MPCall_98_0x118

MPCall_98_0x170
	lwz		r16,  0x007c(r31)
	and		r28, r28, r16
	cmplw	r5, r28
	bge		MPCall_98_0x184
	mr		r28, r5

MPCall_98_0x184
	subf	r16, r4, r28
	b		MPCall_98_0x118



#     # ######  ######                                                #                         
##   ## #     # #     # ######  ####  #  ####  ##### ###### #####    # #    ####  ###### #####  
# # # # #     # #     # #      #    # # #        #   #      #    #  #   #  #    # #      #    # 
#  #  # ######  ######  #####  #      #  ####    #   #####  #    # #     # #      #####  #    # 
#     # #       #   #   #      #  ### #      #   #   #      #####  ####### #  ### #      #####  
#     # #       #    #  #      #    # # #    #   #   #      #   #  #     # #    # #      #   #  
#     # #       #     # ######  ####  #  ####    #   ###### #    # #     #  ####  ###### #    # 

;	ARG		MPNotificationID r3
;	RET		OSStatus r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	82, MPRegisterAger

MPRegisterAger

	;	May only register the ager once
	lwz		r8, PSA.AgerID(r1)
	cmpwi	r8, 0
	bne		ReturnMPCallOOM

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr

	stw		r3, PSA.AgerID(r1)

	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               #######                      ######                       
##   ## #     # #     # ###### ##### #       #####  ###### ###### #     #   ##    ####  ###### 
# # # # #     # #       #        #   #       #    # #      #      #     #  #  #  #    # #      
#  #  # ######  #  #### #####    #   #####   #    # #####  #####  ######  #    # #      #####  
#     # #       #     # #        #   #       #####  #      #      #       ###### #  ### #      
#     # #       #     # #        #   #       #   #  #      #      #       #    # #    # #      
#     # #        #####  ######   #   #       #    # ###### ###### #       #    #  ####  ###### 

;	Pop page from system free list

;	RET		OSStatus r3, PhysicalPage *r4

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: no

	DeclareMPCall	83, MPGetFreePage

MPGetFreePage

	_Lock				PSA.PoolLock, scratch1=r16, scratch2=r17
	bl		FreePageListPop ; // PhysicalPage *r8
	_AssertAndRelease	PSA.PoolLock, scratch=r16

	;	Success
	mr.		r4, r8
	bne		ReturnZeroFromMPCall

	;	Failure. Fall through to something horrible!

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17



#     #                         #                                       #     #                   #                         
##   ## #    #  ####  #    #   # #   #####   ####  #    # #    # #####  #  #  # # ##### #    #   # #    ####  ###### #####  
# # # # #    # #    # #   #   #   #  #    # #    # #    # ##   # #    # #  #  # #   #   #    #  #   #  #    # #      #    # 
#  #  # #    # #      ####   #     # #    # #    # #    # # #  # #    # #  #  # #   #   ###### #     # #      #####  #    # 
#     # #    # #      #  #   ####### #####  #    # #    # #  # # #    # #  #  # #   #   #    # ####### #  ### #      #####  
#     # #    # #    # #   #  #     # #   #  #    # #    # #   ## #    # #  #  # #   #   #    # #     # #    # #      #   #  
#     #  ####   ####  #    # #     # #    #  ####   ####  #    # #####   ## ##  #   #   #    # #     #  ####  ###### #    # 

FailMPCallAndNotifyAgerWeNeedPages

	lwz		r8, PSA.AgerID(r1)
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallOOM

	lwz		r8, Notification.EventGroupID(r31)
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass
	mr		r31, r8
	bne		ReleaseAndReturnMPCallOOM

	;	Huh? Event Groups are 32 bytes. Bug?
	lwz		r8, 0x20(r31)
	bl		SetEvent

	b		ReleaseAndReturnMPCallOOM



#######                      ######                       #                      ######                
#       #####  ###### ###### #     #   ##    ####  ###### #       #  ####  ##### #     #  ####  #####  
#       #    # #      #      #     #  #  #  #    # #      #       # #        #   #     # #    # #    # 
#####   #    # #####  #####  ######  #    # #      #####  #       #  ####    #   ######  #    # #    # 
#       #####  #      #      #       ###### #  ### #      #       #      #   #   #       #    # #####  
#       #   #  #      #      #       #    # #    # #      #       # #    #   #   #       #    # #      
#       #    # ###### ###### #       #    #  ####  ###### ####### #  ####    #   #        ####  #      

;	Requires PoolLock to be acquired!

FreePageListPop ; // PhysicalPage *r8

	addi	r18, r1, PSA.FreeList
	lwz		r8, PSA.FreeList + LLL.Next(r1)
	cmpw	r8, r18
	beq		@fail

	RemoveFromList		r8, scratch1=r16, scratch2=r17

	lwz		r16, PSA.FreePageCount(r1)
	subi	r16, r16, 1
	stw		r16, PSA.FreePageCount(r1)

	;	Daniel found the bug here!
	lwz		r17, LLL.Signature(r8)
	mfspr	r16, dec
	eqv.	r17, r18, r17

	stw		r16, 0(r8)
	bne		SpacePanicIsland
	stw		r16, 4(r8)
	stw		r16, 8(r8)
	stw		r16, 12(r8)

	blr

@fail
	li		r8, 0
	blr



#     # ######  ######               #######                      ######                       
##   ## #     # #     # #    # ##### #       #####  ###### ###### #     #   ##    ####  ###### 
# # # # #     # #     # #    #   #   #       #    # #      #      #     #  #  #  #    # #      
#  #  # ######  ######  #    #   #   #####   #    # #####  #####  ######  #    # #      #####  
#     # #       #       #    #   #   #       #####  #      #      #       ###### #  ### #      
#     # #       #       #    #   #   #       #   #  #      #      #       #    # #    # #      
#     # #       #        ####    #   #       #    # ###### ###### #       #    #  ####  ###### 

;	Checks some junk in the page first (consider removing this)

;	ARG		PhysicalPage *r3
;	RET		OSStatus r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	84, MPPutFreePage

MPPutFreePage

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, 4(r3)
	lwz		r17, 0(r3)

	addi	r18, r1, PSA.FreeList
	eqv.	r16, r16, r17
	cmpw	cr1, r17, r18
	bne		@succeed
	bne		cr1, @succeed

	li		r3, paramErr
	b		@return

@succeed
	mr		r8, r3
	bl		FreePageListPush ; PhysicalPage *r8
	li		r3, 0

@return
	_AssertAndRelease	PSA.PoolLock, scratch=r16

	b		CommonMPCallReturnPath



#######                      ######                       #                      ######                       
#       #####  ###### ###### #     #   ##    ####  ###### #       #  ####  ##### #     # #    #  ####  #    # 
#       #    # #      #      #     #  #  #  #    # #      #       # #        #   #     # #    # #      #    # 
#####   #    # #####  #####  ######  #    # #      #####  #       #  ####    #   ######  #    #  ####  ###### 
#       #####  #      #      #       ###### #  ### #      #       #      #   #   #       #    #      # #    # 
#       #   #  #      #      #       #    # #    # #      #       # #    #   #   #       #    # #    # #    # 
#       #    # ###### ###### #       #    #  ####  ###### ####### #  ####    #   #        ####   ####  #    # 

FreePageListPush ; PhysicalPage *r8

	;	Must be an actual page-aligned address
	clrlwi.	r9, r8, 20
	addi	r9, r1, PSA.FreeList
	bne		SpacePanicIsland


	;	This is probably an alternative to heavyweight locks around the free list

	stw		r9, 0(r8)		;	store &parent in Freeform field

	InsertAsPrev	r8, r9, scratch=r16

	not		r9, r9
	stw		r9, 4(r8)		;	store ^&parent in Signature field


	lwz		r8, PSA.FreePageCount(r1)
	addi	r8, r8, 1
	stw		r8, PSA.FreePageCount(r1)

	blr



#     # ######   #####               #######                      ######                        #####                             
##   ## #     # #     # ###### ##### #       #####  ###### ###### #     #   ##    ####  ###### #     #  ####  #    # #    # ##### 
# # # # #     # #       #        #   #       #    # #      #      #     #  #  #  #    # #      #       #    # #    # ##   #   #   
#  #  # ######  #  #### #####    #   #####   #    # #####  #####  ######  #    # #      #####  #       #    # #    # # #  #   #   
#     # #       #     # #        #   #       #####  #      #      #       ###### #  ### #      #       #    # #    # #  # #   #   
#     # #       #     # #        #   #       #   #  #      #      #       #    # #    # #      #     # #    # #    # #   ##   #   
#     # #        #####  ######   #   #       #    # ###### ###### #       #    #  ####  ######  #####   ####   ####  #    #   #   

;	RET		r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	100, MPGetFreePageCount

MPGetFreePageCount

	lwz		r3, PSA.FreePageCount(r1)
	b		CommonMPCallReturnPath



#     # ######   #####               #     #                                    ######                        #####                             
##   ## #     # #     # ###### ##### #     # #    # #    # ###### #      #####  #     #   ##    ####  ###### #     #  ####  #    # #    # ##### 
# # # # #     # #       #        #   #     # ##   # #    # #      #      #    # #     #  #  #  #    # #      #       #    # #    # ##   #   #   
#  #  # ######  #  #### #####    #   #     # # #  # ###### #####  #      #    # ######  #    # #      #####  #       #    # #    # # #  #   #   
#     # #       #     # #        #   #     # #  # # #    # #      #      #    # #       ###### #  ### #      #       #    # #    # #  # #   #   
#     # #       #     # #        #   #     # #   ## #    # #      #      #    # #       #    # #    # #      #     # #    # #    # #   ##   #   
#     # #        #####  ######   #    #####  #    # #    # ###### ###### #####  #       #    #  ####  ######  #####   ####   ####  #    #   #   

;	RET		r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	101, MPGetUnheldPageCount

MPGetUnheldPageCount

	lwz		r3, PSA.UnheldFreePageCount(r1)
	b		CommonMPCallReturnPath



#     # ######  #     #               ######                       
##   ## #     # ##   ##   ##   #####  #     #   ##    ####  ###### 
# # # # #     # # # # #  #  #  #    # #     #  #  #  #    # #      
#  #  # ######  #  #  # #    # #    # ######  #    # #      #####  
#     # #       #     # ###### #####  #       ###### #  ### #      
#     # #       #     # #    # #      #       #    # #    # #      
#     # #       #     # #    # #      #       #    #  ####  ###### 

;	ARG		MPAreaID r3

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	85, MPMapPage

MPMapPage

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	lwz		r16, Area.Flags(r31)
	rlwinm.	r8, r16, 0, Area.kAliasFlag, Area.kAliasFlag
	bne		ReleaseAndReturnParamErrFromMPCall

	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	lwz		r19, Area.FlagsAndMinAlign(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall

	rlwinm.	r8, r19, 0, 16, 16				; test Contig bit of FlagsAndMinAlign
	cmplw	cr1, r4, r16
	lwz		r20, Area.BytesMapped(r31)
	beq		@not_contig_area
	bne		cr1, ReleaseAndReturnParamErrFromMPCall

;is contig area

	cmpwi	r20, 0
	lwz		r8, Area.ContigPTETemplate(r31)
	bne		ReleaseAndReturnMPCallOOM
	rlwimi	r8, r5, 0, 0xFFFFF000
	lwz		r18, Area.DefaultAlignmentMask(r31)
	lwz		r20, Area.Length(r31)
	stw		r8, Area.ContigPTETemplate(r31)
	stw		r20, Area.BytesMapped(r31)

	b		ReleaseAndReturnZeroFromMPCall

@not_contig_area

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland

	lwz		r29, 0(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14

	rlwinm.	r8, r29, 0, 31, 31
	bne		ReleaseAndReturnMPCallOOM

	lwz		r17, ContextBlock.r6(r6)
	rlwinm.	r8, r17, 0, 30, 30
	bne		KCMapPage_0x12c

	_Lock				PSA.PoolLock, scratch1=r16, scratch2=r17
	bl		FreePageListPop ; // PhysicalPage *r8
	_AssertAndRelease	PSA.PoolLock, scratch=r16

	mr.		r5, r8
	beq		FailMPCallAndNotifyAgerWeNeedPages

KCMapPage_0x12c
	lwz		r17,  0x0134(r6)
	rlwinm.	r8, r17,  0, 29, 29
	beq		KCMapPage_0x17c
	rlwinm.	r8, r29,  0, 25, 25
	lwz		r18,  0x0068(r31)

KCMapPage_0x140
	addi	r18, r18, -0x20
	bne		KCMapPage_0x174
	dcbst	r18, r5

KCMapPage_0x14c
	cmpwi	cr1, r18,  0x00
	bgt		cr1, KCMapPage_0x140
	sync
	lwz		r18,  0x0068(r31)

KCMapPage_0x15c
	addi	r18, r18, -0x20
	icbi	r18, r5
	cmpwi	cr1, r18,  0x00
	bgt		cr1, KCMapPage_0x15c
	isync
	b		KCMapPage_0x17c

KCMapPage_0x174
	dcbf	r18, r5
	b		KCMapPage_0x14c

KCMapPage_0x17c
	lwz		r18,  0x0068(r31)
	andi.	r29, r29,  0x7e7
	ori		r29, r29,  0x01
	rlwimi	r29, r5,  0,  0, 19
	lwz		r17, Area.BytesMapped(r31)
	stw		r29,  0x0000(r30)
	add		r17, r17, r18
	stw		r17, Area.BytesMapped(r31)
	lwz		r17,  0x0134(r6)
	clrlwi.	r8, r17,  0x1f

;	r1 = kdp
	beq		ReleaseAndReturnZeroFromMPCall
	lwz		r5,  0x0068(r31)
	b		HoldPages



#     # ######  #     #                             ######                              
##   ## #     # #     # #    # #    #   ##   #####  #     #   ##    ####  ######  ####  
# # # # #     # #     # ##   # ##  ##  #  #  #    # #     #  #  #  #    # #      #      
#  #  # ######  #     # # #  # # ## # #    # #    # ######  #    # #      #####   ####  
#     # #       #     # #  # # #    # ###### #####  #       ###### #  ### #           # 
#     # #       #     # #   ## #    # #    # #      #       #    # #    # #      #    # 
#     # #        #####  #    # #    # #    # #      #       #    #  ####  ######  ####  

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	86, MPUnmapPages

MPUnmapPages

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r8,  0x0134(r6)
	lwz		r16, Area.Flags(r31)
	rlwinm.	r16, r16,  0, 28, 28
	bne		ReleaseAndReturnParamErrFromMPCall
	clrlwi.	r8, r8,  0x1f
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	lwz		r19,  0x0020(r31)
	crmove	14, 2
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r29,  0x0068(r31)
	lwz		r20, Area.BytesMapped(r31)
	rlwinm.	r8, r19,  0, 16, 16
	cmplw	cr1, r4, r16
	beq		KCUnmapPages_0xd8
	bne		cr1, ReleaseAndReturnParamErrFromMPCall
	cmpwi	r20,  0x00
	li		r20,  0x00
	ble		ReleaseAndReturnMPCallOOM
	stw		r20, Area.BytesMapped(r31)

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	li		r30,  0x00

KCUnmapPages_0xac
	mr		r8, r4
	lwz		r9, Area.AddressSpacePtr(r31)
	bl		SpaceL2PIgnoringBATs ; LogicalPage *r8, MPAddressSpace *r9 // PhysicalPage *r17
	beq		KCUnmapPages_0xc4
	bl		InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bl		DeletePTE ; PTE *r18, PLE *r30

KCUnmapPages_0xc4
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge		KCUnmapPages_0xac
	crclr	cr3_eq
	b		KCUnmapPages_0x158

KCUnmapPages_0xd8
	bne		cr3, KCUnmapPages_0xf4

	_Lock			PSA.PoolLock, scratch1=r14, scratch2=r15


KCUnmapPages_0xf4

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	lwz		r28, Area.BytesMapped(r31)

KCUnmapPages_0x110
	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, KCUnmapPages_0x148
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30
	lwz		r18,  0x0000(r30)
	subf	r28, r29, r28
	rlwinm	r18, r18,  0,  0, 30
	stw		r18,  0x0000(r30)
	bne		cr3, KCUnmapPages_0x148
	rlwinm	r8, r18,  0,  0, 19

;	r1 = kdp
;	r8 = maybe the page
	bl		FreePageListPush ; PhysicalPage *r8

KCUnmapPages_0x148
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge		KCUnmapPages_0x110
	stw		r28, Area.BytesMapped(r31)

KCUnmapPages_0x158
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	bne		cr3, ReleaseAndReturnZeroFromMPCall
	_AssertAndRelease	PSA.PoolLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######  #     #                      ######                                                           #####                                                           
##   ## #     # ##   ##   ##   #    # ###### #     # #    # #   #  ####  #  ####    ##   #      #      #   # #     #  ####  #    # ##### #  ####  #    #  ####  #    #  ####  
# # # # #     # # # # #  #  #  #   #  #      #     # #    #  # #  #      # #    #  #  #  #      #       # #  #       #    # ##   #   #   # #    # #    # #    # #    # #      
#  #  # ######  #  #  # #    # ####   #####  ######  ######   #    ####  # #      #    # #      #        #   #       #    # # #  #   #   # #      #    # #    # #    #  ####  
#     # #       #     # ###### #  #   #      #       #    #   #        # # #      ###### #      #        #   #       #    # #  # #   #   # #  ### #    # #    # #    #      # 
#     # #       #     # #    # #   #  #      #       #    #   #   #    # # #    # #    # #      #        #   #     # #    # #   ##   #   # #    # #    # #    # #    # #    # 
#     # #       #     # #    # #    # ###### #       #    #   #    ####  #  ####  #    # ###### ######   #    #####   ####  #    #   #   #  ####   ####   ####   ####   ####  

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	127, MPMakePhysicallyContiguous

MPMakePhysicallyContiguous

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mr		r27, r5
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne		ReleaseAndReturnParamErrFromMPCall

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r27, r4
	li		r28, -0x01

NKMakePhysicallyContiguous_0x80
	mr		r8, r27
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, NKMakePhysicallyContiguous_0x150
	rlwinm	r8, r17,  0,  0, 19
	cmpwi	r28, -0x01
	cmpw	cr1, r28, r8
	mr		r28, r8
	beq		NKMakePhysicallyContiguous_0xac
	bne		cr1, NKMakePhysicallyContiguous_0xe0

NKMakePhysicallyContiguous_0xac
	add		r27, r27, r29
	add		r28, r28, r29
	subf.	r8, r27, r5
	bge		NKMakePhysicallyContiguous_0x80
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

NKMakePhysicallyContiguous_0xe0
	_AssertAndRelease	PSA.HTABLock, scratch=r14

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	addi	r18, r1, PSA.FreeList
	lwz		r8, PSA.FreeList + LLL.Next(r1)
	cmpw	r8, r18
	beq		NKMakePhysicallyContiguous_0x174
	b		NKMakePhysicallyContiguous_0x174

	;	Dead code:
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	b		ReleaseAndReturnZeroFromMPCall

NKMakePhysicallyContiguous_0x150
	_AssertAndRelease	PSA.HTABLock, scratch=r16
	b		ReleaseAndReturnMPCallOOM

NKMakePhysicallyContiguous_0x174
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	b		ReleaseAndReturnMPCallOOM



#     # ######  #                            ######                              
##   ## #     # #        ####   ####  #    # #     #   ##    ####  ######  ####  
# # # # #     # #       #    # #    # #   #  #     #  #  #  #    # #      #      
#  #  # ######  #       #    # #      ####   ######  #    # #      #####   ####  
#     # #       #       #    # #      #  #   #       ###### #  ### #           # 
#     # #       #       #    # #    # #   #  #       #    # #    # #      #    # 
#     # #       #######  ####   ####  #    # #       #    #  ####  ######  ####  

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	87, MPLockPages

MPLockPages

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mr		r27, r5
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne		ReleaseAndReturnParamErrFromMPCall
	mr		r27, r4
	li		r28,  0x00

KCLockPages_0x68
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	rlwinm	r17, r18, 24, 25, 31
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0x7f
	addi	r28, r28,  0x01
	beq		KCLockPages_0x94
	addi	r28, r28, -0x01
	bge		cr1, major_0x0b0cc

KCLockPages_0x94
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge		KCLockPages_0x68

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	subf.	r16, r28, r16
	ble		KCLockPages_0xc8
	stw		r16, PSA.UnheldFreePageCount(r1)

KCLockPages_0xc8
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	ble		ReleaseAndReturnMPCallOOM
	mr		r27, r4

KCLockPages_0xf0
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		SpacePanicIsland
	lhz		r18,  0x0000(r30)
	rlwinm.	r17, r18,  0, 16, 16
	bne		KCLockPages_0x10c
	li		r18, -0x8000

KCLockPages_0x10c
	rlwinm	r17, r18, 24, 25, 31
	addi	r17, r17,  0x01
	rlwimi	r18, r17,  8, 17, 23
	sth		r18,  0x0000(r30)
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge		KCLockPages_0xf0

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######  #     #                                    ######                              
##   ## #     # #     # #    # #       ####   ####  #    # #     #   ##    ####  ######  ####  
# # # # #     # #     # ##   # #      #    # #    # #   #  #     #  #  #  #    # #      #      
#  #  # ######  #     # # #  # #      #    # #      ####   ######  #    # #      #####   ####  
#     # #       #     # #  # # #      #    # #      #  #   #       ###### #  ### #           # 
#     # #       #     # #   ## #      #    # #    # #   #  #       #    # #    # #      #    # 
#     # #        #####  #    # ######  ####   ####  #    # #       #    #  ####  ######  ####  

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	88, MPUnlockPages

MPUnlockPages

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne		ReleaseAndReturnParamErrFromMPCall
	mr		r27, r4

KCUnlockPages_0x60
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	rlwinm	r17, r18, 24, 25, 31
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0x00
	beq		major_0x0b0cc
	addi	r28, r28,  0x01
	beq		cr1, major_0x0b0cc
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge		KCUnlockPages_0x60
	li		r28,  0x00

KCUnlockPages_0x98
	mr		r8, r4
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	rlwinm	r17, r18, 24, 25, 31
	addi	r17, r17, -0x01
	rlwimi	r18, r17,  8, 17, 23
	clrlwi.	r8, r18,  0x11
	bne		KCUnlockPages_0xc4
	rlwinm	r18, r18,  0, 17, 15
	addi	r28, r28,  0x01

KCUnlockPages_0xc4
	sth		r18,  0x0000(r30)
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge		KCUnlockPages_0x98

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	add		r16, r16, r28
	stw		r16, PSA.UnheldFreePageCount(r1)
	_AssertAndRelease	PSA.PoolLock, scratch=r16

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######  #     #                      ######                              
##   ## #     # #     #  ####  #      #####  #     #   ##    ####  ######  ####  
# # # # #     # #     # #    # #      #    # #     #  #  #  #    # #      #      
#  #  # ######  ####### #    # #      #    # ######  #    # #      #####   ####  
#     # #       #     # #    # #      #    # #       ###### #  ### #           # 
#     # #       #     # #    # #      #    # #       #    # #    # #      #    # 
#     # #       #     #  ####  ###### #####  #       #    #  ####  ######  ####  
                                                                                 
;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	89, MPHoldPages

MPHoldPages

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8



#     #                      ######                              
#     #  ####  #      #####  #     #   ##    ####  ######  ####  
#     # #    # #      #    # #     #  #  #  #    # #      #      
####### #    # #      #    # ######  #    # #      #####   ####  
#     # #    # #      #    # #       ###### #  ### #           # 
#     # #    # #      #    # #       #    # #    # #      #    # 
#     #  ####  ###### #####  #       #    #  ####  ######  ####  

HoldPages

	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne		ReleaseAndReturnParamErrFromMPCall
	mr		r27, r4
	li		r28,  0x00

KCHoldPages_0x64
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	clrlwi	r17, r18,  0x18
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0xff
	addi	r28, r28,  0x01
	beq		KCHoldPages_0x90
	addi	r28, r28, -0x01
	bge		cr1, major_0x0b0cc

KCHoldPages_0x90
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge		KCHoldPages_0x64

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	subf.	r16, r28, r16
	ble		KCHoldPages_0xc4
	stw		r16, PSA.UnheldFreePageCount(r1)

KCHoldPages_0xc4
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	ble		ReleaseAndReturnMPCallOOM
	mr		r27, r4

KCHoldPages_0xec
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		SpacePanicIsland
	lhz		r18,  0x0000(r30)
	rlwinm.	r17, r18,  0, 16, 16
	bne		KCHoldPages_0x108
	li		r18, -0x8000

KCHoldPages_0x108
	clrlwi	r17, r18,  0x18
	addi	r17, r17,  0x01
	rlwimi	r18, r17,  0, 24, 31
	sth		r18,  0x0000(r30)
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge		KCHoldPages_0xec

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######  #     #                                    ######                              
##   ## #     # #     # #    # #    #  ####  #      #####  #     #   ##    ####  ######  ####  
# # # # #     # #     # ##   # #    # #    # #      #    # #     #  #  #  #    # #      #      
#  #  # ######  #     # # #  # ###### #    # #      #    # ######  #    # #      #####   ####  
#     # #       #     # #  # # #    # #    # #      #    # #       ###### #  ### #           # 
#     # #       #     # #   ## #    # #    # #      #    # #       #    # #    # #      #    # 
#     # #        #####  #    # #    #  ####  ###### #####  #       #    #  ####  ######  ####  

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	90, MPUnholdPages

MPUnholdPages

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne		ReleaseAndReturnParamErrFromMPCall
	mr		r27, r4

KCUnholdPages_0x60
	mr		r8, r27
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	clrlwi	r17, r18,  0x18
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0x00
	beq		major_0x0b0cc
	addi	r28, r28,  0x01
	beq		cr1, major_0x0b0cc
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge		KCUnholdPages_0x60
	li		r28,  0x00

KCUnholdPages_0x98
	mr		r8, r4
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	clrlwi	r17, r18,  0x18
	addi	r17, r17, -0x01
	rlwimi	r18, r17,  0, 24, 31
	clrlwi.	r8, r18,  0x11
	bne		KCUnholdPages_0xc4
	rlwinm	r18, r18,  0, 17, 15
	addi	r28, r28,  0x01

KCUnholdPages_0xc4
	sth		r18,  0x0000(r30)
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge		KCUnholdPages_0x98

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	add		r16, r16, r28
	stw		r16, PSA.UnheldFreePageCount(r1)
	_AssertAndRelease	PSA.PoolLock, scratch=r16

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               ######                          #                                                           
##   ## #     # #     # ###### ##### #     #   ##    ####  ######   # #   ##### ##### #####  # #####  #    # ##### ######  ####  
# # # # #     # #       #        #   #     #  #  #  #    # #       #   #    #     #   #    # # #    # #    #   #   #      #      
#  #  # ######  #  #### #####    #   ######  #    # #      #####  #     #   #     #   #    # # #####  #    #   #   #####   ####  
#     # #       #     # #        #   #       ###### #  ### #      #######   #     #   #####  # #    # #    #   #   #           # 
#     # #       #     # #        #   #       #    # #    # #      #     #   #     #   #   #  # #    # #    #   #   #      #    # 
#     # #        #####  ######   #   #       #    #  ####  ###### #     #   #     #   #    # # #####   ####    #   ######  ####  

;	ARG		MPAreaID r3, LogicalPage *r4
;	RET		OSStatus r3, PageAttrs r5

	DeclareMPCall	91, MPGetPageAttributes

MPGetPageAttributes

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

	;	Check that the passed address lies within the area
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	;	Find the Page List Entry
	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		@release_lock_return_oom

	;	Clear the PTE from the HTAB
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30

	;	Get the PLE, and then we're clear of the HTAB lock
	lwz		r29, 0(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14

	mr		r8, r4
	bl		MPCall_95_0x254

	li		r19, 0
	beq		@_ac
	lhz		r19, 0(r30)
@_ac

	andi.	r5, r29,  0x319
	rlwinm.	r8, r19,  0, 16, 16
	rlwimi	r5, r19,  0, 16, 16
	beq		ReleaseAndReturnZeroFromMPCall

	rlwinm.	r8, r19,  0, 17, 23
	beq		ReleaseAndReturnZeroFromMPCall

	ori		r5, r5,  0x4000
	b		ReleaseAndReturnZeroFromMPCall

@release_lock_return_oom
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	b		ReleaseAndReturnMPCallOOM



#     # ######   #####               ######                          #                                                           
##   ## #     # #     # ###### ##### #     #   ##    ####  ######   # #   ##### ##### #####  # #####  #    # ##### ######  ####  
# # # # #     # #       #        #   #     #  #  #  #    # #       #   #    #     #   #    # # #    # #    #   #   #      #      
#  #  # ######   #####  #####    #   ######  #    # #      #####  #     #   #     #   #    # # #####  #    #   #   #####   ####  
#     # #             # #        #   #       ###### #  ### #      #######   #     #   #####  # #    # #    #   #   #           # 
#     # #       #     # #        #   #       #    # #    # #      #     #   #     #   #   #  # #    # #    #   #   #      #    # 
#     # #        #####  ######   #   #       #    #  ####  ###### #     #   #     #   #    # # #####   ####    #   ######  ####  

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	92, MPSetPageAttributes

MPSetPageAttributes

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.Flags(r31)
	rlwinm.	r8, r16,  0, 28, 28
	bne		ReleaseAndReturnParamErrFromMPCall
	lwz		r29,  0x0134(r6)
	li		r8,  0x318
	andc.	r9, r5, r8
	bne		ReleaseAndReturnParamErrFromMPCall
	andc.	r9, r29, r8
	bne		ReleaseAndReturnParamErrFromMPCall
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		MPCall_92_0xd8
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, MPCall_92_0x9c
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30

MPCall_92_0x9c
	lwz		r16,  0x0000(r30)
	and		r8, r5, r29
	orc		r9, r5, r29
	or		r16, r16, r8
	and		r16, r16, r9
	stw		r16,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_92_0xd8
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	b		ReleaseAndReturnMPCallOOM



#     # ######   #####               ######                          #                  
##   ## #     # #     # ###### ##### #     #   ##    ####  ######   # #    ####  ###### 
# # # # #     # #       #        #   #     #  #  #  #    # #       #   #  #    # #      
#  #  # ######  #  #### #####    #   ######  #    # #      #####  #     # #      #####  
#     # #       #     # #        #   #       ###### #  ### #      ####### #  ### #      
#     # #       #     # #        #   #       #    # #    # #      #     # #    # #      
#     # #        #####  ######   #   #       #    #  ####  ###### #     #  ####  ###### 

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: no

	DeclareMPCall	93, MPGetPageAge

MPGetPageAge

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	mr		r8, r4
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	rlwinm.	r8, r18,  0, 16, 16
	li		r5,  0x00

;	r1 = kdp
	bne		ReleaseAndReturnZeroFromMPCall
	clrlwi	r5, r18,  0x11

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               ######                          #                  
##   ## #     # #     # ###### ##### #     #   ##    ####  ######   # #    ####  ###### 
# # # # #     # #       #        #   #     #  #  #  #    # #       #   #  #    # #      
#  #  # ######   #####  #####    #   ######  #    # #      #####  #     # #      #####  
#     # #             # #        #   #       ###### #  ### #      ####### #  ### #      
#     # #       #     # #        #   #       #    # #    # #      #     # #    # #      
#     # #        #####  ######   #   #       #    #  ####  ###### #     #  ####  ###### 

;	Straight MPLibrary wrapper: yes
;	In Universal Interfaces: no

	DeclareMPCall	94, MPSetPageAge

MPSetPageAge

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	mr		r8, r4
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	cmplwi	r5,  0x7fff
	bgt		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	rlwinm.	r8, r18,  0, 16, 16
	bne		ReleaseAndReturnMPCallOOM
	rlwimi	r18, r5,  0, 17, 31
	sth		r18,  0x0000(r30)

	_Lock			PSA.HTABLock, scratch1=r16, scratch2=r17

	mr		r8, r4
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	bl		GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7
	bc		BO_IF_NOT, Area.kPLEFlagHasPhysPage, MPCall_94_0xa0
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7
	bcl		BO_IF, Area.kPLEFlagIsInHTAB, DeletePTE ; PTE *r18, PLE *r30

MPCall_94_0xa0
	_AssertAndRelease	PSA.HTABLock, scratch=r16

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######   #####               ######                       #     #                      #                             #####                                    
##   ## #     # #     # ###### ##### #     #   ##    ####  ###### #     #  ####  #      #####  #        ####   ####  #    # #     #  ####  #    # #    # #####  ####  
# # # # #     # #       #        #   #     #  #  #  #    # #      #     # #    # #      #    # #       #    # #    # #   #  #       #    # #    # ##   #   #   #      
#  #  # ######  #  #### #####    #   ######  #    # #      #####  ####### #    # #      #    # #       #    # #      ####   #       #    # #    # # #  #   #    ####  
#     # #       #     # #        #   #       ###### #  ### #      #     # #    # #      #    # #       #    # #      #  #   #       #    # #    # #  # #   #        # 
#     # #       #     # #        #   #       #    # #    # #      #     # #    # #      #    # #       #    # #    # #   #  #     # #    # #    # #   ##   #   #    # 
#     # #        #####  ######   #   #       #    #  ####  ###### #     #  ####  ###### #####  #######  ####   ####  #    #  #####   ####   ####  #    #   #    ####  

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: no

	DeclareMPCall	129, MPGetPageHoldLockCounts

MPGetPageHoldLockCounts

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne		ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalEnd(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt		ReleaseAndReturnParamErrFromMPCall
	bgt		cr1, ReleaseAndReturnParamErrFromMPCall
	mr		r8, r4
	bl		MPCall_95_0x254
	beq		ReleaseAndReturnParamErrFromMPCall
	lhz		r18,  0x0000(r30)
	li		r5,  0x00
	rlwinm.	r8, r18,  0, 16, 16
	li		r16,  0x00
	beq		MPCall_129_0x6c
	rlwinm	r16, r18, 24, 25, 31
	clrlwi	r5, r18,  0x18

MPCall_129_0x6c
	stw		r16,  0x0134(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



#     # ######  #######                 #     #                         ######                       
##   ## #     # #       # #    # #####  #     # #  ####  ##### # #    # #     #   ##    ####  ###### 
# # # # #     # #       # ##   # #    # #     # # #    #   #   # ##  ## #     #  #  #  #    # #      
#  #  # ######  #####   # # #  # #    # #     # # #        #   # # ## # ######  #    # #      #####  
#     # #       #       # #  # # #    #  #   #  # #        #   # #    # #       ###### #  ### #      
#     # #       #       # #   ## #    #   # #   # #    #   #   # #    # #       #    # #    # #      
#     # #       #       # #    # #####     #    #  ####    #   # #    # #       #    #  ####  ###### 

;	Straight MPLibrary wrapper: returns value via passed ptr
;	In Universal Interfaces: no

	DeclareMPCall	95, MPFindVictimPage

MPFindVictimPage

	or.		r8, r3, r4

	bne		@not_naughty
	li		r16, 0
	stw		r16, KDP.VMMaxVirtualPages(r1)
	_log	'Areas capability probe detected^n'
	b		ReturnParamErrFromMPCall
@not_naughty

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r28, -0x01
	li		r4,  0x00
	li		r5,  0x00
	lwz		r8, PSA.UnheldFreePageCount(r1)
	cmpwi	r8,  0x00
	ble		ReleaseAndReturnMPCallOOM
	lwz		r27, PSA.DecClockRateHzCopy(r1)
	srwi	r27, r27, 15
	mfspr	r8, dec
	subf	r27, r27, r8
	lwz		r8, PSA.OtherSystemAddrSpcPtr2(r1)
	lwz		r9, PSA.ZeroedByInitFreeList3(r1)
	mr		r30, r9
	bl		FindAreaAbove
	mr		r31, r8
	lwz		r29, Area.LogicalBase(r31)
	cmplw	r29, r30
	bgt		MPCall_95_0xa8
	mr		r29, r30

MPCall_95_0xa8
	crset	cr2_eq

MPCall_95_0xac
	mfspr	r9, dec
	subf.	r9, r27, r9
	blt		MPCall_95_0x1c8

MPCall_95_0xb8
	lwz		r8,  0x0020(r31)
	lwz		r9,  0x0018(r31)
	rlwinm.	r8, r8,  0, 16, 16
	cmpwi	cr1, r3,  0x00
	bne		MPCall_95_0x19c
	beq		cr1, MPCall_95_0xe0
	cmpwi	cr3, r9,  0x00
	beq		cr3, MPCall_95_0xe0
	cmpw	cr1, r9, r3
	bne		cr1, MPCall_95_0x19c

MPCall_95_0xe0
	lwz		r9, Area.Flags(r31)
	rlwinm.	r8, r9,  0, 28, 28
	bne		MPCall_95_0x19c
	rlwinm.	r8, r9,  0, 23, 23
	bne		MPCall_95_0x19c

	_Lock			PSA.HTABLock, scratch1=r16, scratch2=r17

	mr		r8, r29
	bl		SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq
	beq		SpacePanicIsland
	_AssertAndRelease	PSA.HTABLock, scratch=r16
	lwz		r16,  0x0000(r30)
	clrlwi.	r8, r16,  0x1f
	beq		MPCall_95_0x180
	mr		r8, r29
	bl		MPCall_95_0x254
	beq		MPCall_95_0x1c8
	lhz		r17,  0x0000(r30)
	rlwinm.	r8, r17,  0, 16, 16
	clrlwi	r17, r17,  0x11
	bne		MPCall_95_0x180
	cmpw	r17, r28
	crclr	cr2_eq
	ble		MPCall_95_0x180
	mr		r28, r17
	lwz		r4, Area.ID(r31)
	cmplwi	r17,  0x7fff
	mr		r5, r29
	bge		MPCall_95_0x1c8

MPCall_95_0x180
	lwz		r8,  0x0068(r31)
	lwz		r9, Area.LogicalEnd(r31)
	add		r29, r29, r8
	subf.	r9, r9, r29
	bge		MPCall_95_0x19c
	bne		cr2, MPCall_95_0xac
	b		MPCall_95_0xb8

MPCall_95_0x19c
	lwz		r8,  0x0054(r31)
	lwz		r9,  0x005c(r31)
	cmpw	r8, r9
	addi	r31, r9, -0x54
	lwz		r29, Area.LogicalBase(r31)
	bne		MPCall_95_0x1c0
	lwz		r9,  0x0008(r8)
	addi	r31, r9, -0x54
	lwz		r29, Area.LogicalBase(r31)

MPCall_95_0x1c0
	bne		cr2, MPCall_95_0xac
	b		MPCall_95_0xb8

MPCall_95_0x1c8
	cmpwi	r4,  0x00
	stw		r29, PSA.ZeroedByInitFreeList3(r1)
	beq		ReleaseAndReturnMPCallOOM
	lwz		r8,  0x0068(r31)
	add		r8, r8, r5
	stw		r8, PSA.ZeroedByInitFreeList3(r1)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



 #####                               #####               ######                       ######  #       ####### 
#     # #####    ##    ####  ###### #     # ###### ##### #     #   ##    ####  ###### #     # #       #       
#       #    #  #  #  #    # #      #       #        #   #     #  #  #  #    # #      #     # #       #       
 #####  #    # #    # #      #####  #  #### #####    #   ######  #    # #      #####  ######  #       #####   
      # #####  ###### #      #      #     # #        #   #       ###### #  ### #      #       #       #       
#     # #      #    # #    # #      #     # #        #   #       #    # #    # #      #       #       #       
 #####  #      #    #  ####  ######  #####  ######   #   #       #    #  ####  ###### #       ####### ####### 

SpaceGetPagePLE ; LogicalPage *r8, Area *r31 // PLE *r30, notfound cr0.eq

	lwz		r16, Area.LogicalBase(r31)
	lwz		r18, Area.Flags(r31)
	lwz		r30, Area.PageMapArrayPtr(r31)

	;	r17 = offset of ptr into area
	subf	r17, r16, r8

@loop_that_would_totally_happen_but_not

	;	Fail if Area has no page map array.
	;	r17 = offset of page's entry in page map (entries are 4b)
	cmpwi	r30, 0
	rlwinm	r17, r17, (32-10), 10, 29
	beqlr

	;	Do another level of lookups if the array is 2D
	;	(i.e. the Area contains more than 1k pages)
	rlwinm.	r16, r18,  0, Area.kPageMapArrayIs2D, Area.kPageMapArrayIs2D
	rlwinm	r16, r17, (32-10), 20, 29		; offset of secondary ptr in page map
	beq		@not_2d
	rlwinm	r17, r17,  0, 20, 29
	lwzx	r30, r30, r16
@not_2d

	;	Return r30, a pointer to the list entry
	;	cr0.eq if we failed
	add.	r30, r30, r17
	blr

	;	Dead code:
	lwz		r16, Area.LogicalBase(r31)
	lwz		r18, Area.Flags(r31)
	lwz		r30,  0x0040(r31)

	rlwinm.	r17, r18, 0, Area.kAliasFlag, Area.kAliasFlag
	subf	r17, r16, r8
	beq		@loop_that_would_totally_happen_but_not

	lwz		r30, Area.AliasLLL(r31)
	lwz		r18, 0x80(r31)
	subi	r30, r30, Area.AliasLLL
	subf	r17, r16, r8
	add		r17, r17, r18
	lwz		r18, Area.Flags(r30)
	lwz		r30, Area.PageMapArrayPtr(r30)
	b		@loop_that_would_totally_happen_but_not



MPCall_95_0x254	;	OUTSIDE REFERER
	lwz		r16, Area.LogicalBase(r31)
	lwz		r18, Area.Flags(r31)
	lwz		r30,  0x003c(r31)
	rlwinm.	r17, r18,  0, Area.kAliasFlag, Area.kAliasFlag
	subf	r17, r16, r8
	beq		MPCall_95_0x288

	lwz		r30,  0x0044(r31)
	lwz		r18,  0x0080(r31)
	addi	r30, r30, -0x44
	subf	r17, r16, r8
	add		r17, r17, r18
	lwz		r18,  0x0008(r30)
	lwz		r30,  0x003c(r30)

MPCall_95_0x288
	cmpwi	r30,  0x00
	rlwinm	r17, r17, 21, 11, 30
	beqlr
	rlwinm.	r16, r18,  0, 30, 30
	rlwinm	r16, r17, 22, 20, 29
	beq		MPCall_95_0x2a8
	rlwinm	r17, r17,  0, 20, 30
	lwzx	r30, r30, r16

MPCall_95_0x2a8
	add.	r30, r30, r17
	blr



 #####               ######  ####### ####### #######                      ######  #       ####### 
#     # ###### ##### #     #    #    #       #       #####   ####  #    # #     # #       #       
#       #        #   #     #    #    #       #       #    # #    # ##  ## #     # #       #       
#  #### #####    #   ######     #    #####   #####   #    # #    # # ## # ######  #       #####   
#     # #        #   #          #    #       #       #####  #    # #    # #       #       #       
#     # #        #   #          #    #       #       #   #  #    # #    # #       #       #       
 #####  ######   #   #          #    ####### #       #    #  ####  #    # #       ####### ####### 

;	If a logical page (of an Area of an AddressSpace) is featured in the HTAB,
;	its NanoKernel Page List Entry (PLE) should point at that PowerPC Page Table
;	Entry (PTE, of a PTEG in the HTAB). If there is a physical page mapped to
;	that logical page, but it is not yet in the HTAB, then the PLE will point
;	directly to the page.

GetPTEFromPLE ; PLE *r30 // PTE r16/r17, PTE *r18, PTEflags cr0, PLEflags cr5-7

	lwz		r19, 0(r30)						; r19 = contents of page list entry
	lwz		r18, KDP.HTABORG(r1)			; r18 = HTAB base, in case like me you were confused

	mtcrf	%00000111, r19					; cr5-7 = flags from PLE

	;	Returning early because we are not in HTAB? Cook up a fake PTE.
	rlwinm	r17, r19, 0, 0, 19				; lower has RPN
	rlwinm	r16, r19, (32-9), 0+9, 19+9		; will actually use this as PTE offset within HTAB!

	bclr	BO_IF_NOT, Area.kPLEFlagHasPhysPage
	bclr	BO_IF_NOT, Area.kPLEFlagIsInHTAB

	;	r16/r17 = PTE
	;	r18 = &PTE
	lwzux	r16, r18, r16
	lwz		r17, 4(r18)

	;	Die if V bit is not set (entry is invalid).
	;	Return flags.
	mtcrf	%10000000, r16
	bc		BO_IF_NOT, 0, SpacePanicIsland

	blr



###                             ######  ####### ####### 
 #  #    # #    #   ##   #      #     #    #    #       
 #  ##   # #    #  #  #  #      #     #    #    #       
 #  # #  # #    # #    # #      ######     #    #####   
 #  #  # # #    # ###### #      #          #    #       
 #  #   ##  #  #  #    # #      #          #    #       
### #    #   ##   #    # ###### #          #    ####### 

InvalPTE ; page *r8, PTE r16/r17, PTE *r18, PLE *r30 // PLEflags cr5-7

	;	Special-case 601.
	;	Clear V bit of PTE.
	mfspr	r14, pvr
	_bclr	r16, r16, 0
	rlwinm.	r14, r14, 0, 0xFFFE0000
	stw		r16, 0(r18)

	;	Now that HTAB is touched, bump our page from the TLB
	sync
	tlbie	r8
	beq		@is_601
	sync
	tlbsync
@is_601
	sync
	isync

	;	Prepare to re-set V bit, but return if there is no PLE
	cmpwi	r30, 0

	;	Be needlessly sure that these registers don't get clobbered
	lwz		r14, 0(r30)				; r14 = PLE
	lwz		r17, 4(r18)				; r17 = lower PTE
	_bset	r16, r16, 0				; r16 = upper PTE

	beqlr

	;	Continue if there is a PLE involved... INTERESTING PART
	rlwimi	r14, r17, (32-3), 27, 27		; lowest two bits of VSID into 27/28 of PLE
	rlwimi	r14, r17, (32-5), 28, 28

	;	Slightly update the cond reg with the new PLE
	;	(flags 27 and 28, others should be unchanged)
	mtcrf	%00000111, r14			; set CR (is return value)
	stw		r14, 0(r30)				; save that PLE

	blr



 #####               ######  ####### ####### 
#     # ###### ##### #     #    #    #       
#       #        #   #     #    #    #       
 #####  #####    #   ######     #    #####   
      # #        #   #          #    #       
#     # #        #   #          #    #       
 #####  ######   #   #          #    ####### 

SetPTE ; PTE r16/r17, PTE *r18

	stw		r17, 4(r18)
	eieio
	stw		r16, 0(r18)
	sync
	blr



######                                    ######  ####### ####### 
#     # ###### #      ###### ##### ###### #     #    #    #       
#     # #      #      #        #   #      #     #    #    #       
#     # #####  #      #####    #   #####  ######     #    #####   
#     # #      #      #        #   #      #          #    #       
#     # #      #      #        #   #      #          #    #       
######  ###### ###### ######   #   ###### #          #    ####### 

DeletePTE ; PTE *r18, PLE *r30

	lwz		r14, 0(r30)

	_InvalNCBPointerCache scratch=r16

foo set KDP.NanoKernelInfo + NKNanoKernelInfo.HashTableDeleteCount
	lwz		r16, foo(r1)
	_bclr	r14, r14, Area.kPLEFlagIsInHTAB
	addi	r16, r16, 1
	stw		r16, foo(r1)

	;	Change "PLE>PTE>page" to "PLE>page"
	rlwimi	r14, r17, 0, 0xfffff000

	;	Fully zero the PTE.
	;	But only zero the PLE if the ptr is non-null.
	cmpwi	r30, 0
	li		r16, 0
	li		r17, 0
	beq		SetPTE ; PTE r16/r17, PTE *r18
	stw		r14, 0(r30)
	b		SetPTE ; PTE r16/r17, PTE *r18



 #####                              #        #####  ######  #     #                        ######     #    #######        
#     # #####    ##    ####  ###### #       #     # #     # #     #  ####  # #    #  ####  #     #   # #      #     ####  
#       #    #  #  #  #    # #      #             # #     # #     # #      # ##   # #    # #     #  #   #     #    #      
 #####  #    # #    # #      #####  #        #####  ######  #     #  ####  # # #  # #      ######  #     #    #     ####  
      # #####  ###### #      #      #       #       #       #     #      # # #  # # #  ### #     # #######    #         # 
#     # #      #    # #    # #      #       #       #       #     # #    # # #   ## #    # #     # #     #    #    #    # 
 #####  #      #    #  ####  ###### ####### ####### #        #####   ####  # #    #  ####  ######  #     #    #     ####  

SpaceL2PUsingBATs ; LogicalPage *r8, MPAddressSpace *r9 // PhysicalPage *r17

	MACRO
	_v2pguts 						; cr0.eq = match
	rlwimi	r19, r16, 15, 0, 14		; r19 = 0000 (4b) || BEPI (11b) || 11111111111111111 (17b) = bits that needn't match
	xor		r17, r8, r16			; xor the two things we are comparing
	andc.	r17, r17, r19			; mask away the bits that needn't match
	ENDM


	;	Use current Address Space if none specified

	mr.		r19, r9
	mfsprg	r17, 0
	bne		@addrspc_provided
	lwz		r19, EWA.PA_CurAddressSpace(r17)
@addrspc_provided


	;	Search all 8 UBAT registers for one that contains our effective address

	addi	r18, r19, AddressSpace.BATs

	lwz		r16, 0(r18)
	li		r19, -1
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	beq		@bat_yes

	lwzu	r16, 8(r18)
	_v2pguts
	bne		@bat_no

@bat_yes
	andi.	r17, r16, 1						; cr0.eq = !UBAT[Vp]
	rlwinm	r19, r19, 0, 8, 19
	lwzu	r17, 4(r18)						; r17 = LBAT
	and		r19, r8, r19
	or		r17, r17, r19
	bnelr									; succeed if UBAT[Vp] is set

@bat_no



 #####                              #        #####  ######  ###                                             ######     #    #######        
#     # #####    ##    ####  ###### #       #     # #     #  #   ####  #    #  ####  #####  # #    #  ####  #     #   # #      #     ####  
#       #    #  #  #  #    # #      #             # #     #  #  #    # ##   # #    # #    # # ##   # #    # #     #  #   #     #    #      
 #####  #    # #    # #      #####  #        #####  ######   #  #      # #  # #    # #    # # # #  # #      ######  #     #    #     ####  
      # #####  ###### #      #      #       #       #        #  #  ### #  # # #    # #####  # #  # # #  ### #     # #######    #         # 
#     # #      #    # #    # #      #       #       #        #  #    # #   ## #    # #   #  # #   ## #    # #     # #     #    #    #    # 
 #####  #      #    #  ####  ###### ####### ####### #       ###  ####  #    #  ####  #    # # #    #  ####  ######  #     #    #     ####  

SpaceL2PIgnoringBATs ; LogicalPage *r8, MPAddressSpace *r9 // PhysicalPage *r17

	;	r17 = segment descriptor (from addrspc or actual register)

	cmpwi	r9, 0
	addi	r16, r9, AddressSpace.SRs
	beq		@no_addrspc_provided

;addrspc provided
	rlwinm	r17, r8, (32-26), 26, 29
	lwzx	r17, r16, r17
	b		@endif_addrspc

@no_addrspc_provided
	mfsrin	r17, r8

@endif_addrspc


	;	Do the "(VSID || page index) -> PTEG address" hashing function
	;	Remember, PTEG = 8 x 8b PTEs

	;	r18 = physical address of 64b PTEG to search
	;	r16 = upper PTE to check for (V, VSID and API fields)

	rlwinm	r16, r8, 10, 26, 31			; set API field of r16
	rlwimi	r16, r17, 7, 1, 24			; set VSID field of r16
	rlwinm	r9, r8, 32-6, 10, 25		; r9 = page index in bits 0x003FFFC0
	_bset	r16, r16, 0					; set V(alid) bit of r16 to 1
	rlwinm	r17, r17, 6, 7, 25
	xor		r9, r9, r17					; r9 ^= (VSID & 0x7FFFF) in bits 0x01FFFFC0

	lwz		r17, KDP.PTEGMask(r1)
	lwz		r18, KDP.HTABORG(r1)

	and		r9, r9, r17					; r9 %= HTAB size
	or.		r18, r18, r9				; r18 = &HTAB + r9 = &PTEG


	;	This is tightly coded, but is obviously searching the PTEG for a match with r16

@try_other_four_PTEs
	lwz		r17, 0*8(r18)				; load this upper PTE
	lwz		r9, 1*8(r18)				; and the next upper PTE
	cmpw	cr6, r16, r17
	lwz		r17, 2*8(r18)				; and the next upper PTE
	cmpw	cr7, r16, r9
	lwzu	r9, 3*8(r18)				; and the next upper PTE, and update

	bne		cr6, @nope

@yes_this_one
	lwzu	r17, -20(r18)
	blr

@nope
	cmpw	cr6, r16, r17
	lwzu	r17, 8(r18)
	beq		cr7, @yes_this_one

	cmpw	cr7, r16, r9
	lwzu	r9, 8(r18)
	beq		cr6, @yes_this_one

	cmpw	cr6, r16, r17
	lwzu	r17, 8(r18)
	beq		cr7, @yes_this_one

	cmpw	cr7, r16, r9
	lwzu	r9, 8(r18)
	beq		cr6, @yes_this_one

	cmpw	cr6, r16, r17
	lwzu	r17, -12(r18)
	beqlr	cr7

	cmpw	cr7, r16, r9
	lwzu	r17, 8(r18)
	beqlr	cr6

	lwzu	r17, 8(r18)
	beqlr	cr7

	lwz		r17, KDP.PTEGMask(r1)

	xori	r16, r16, 0x40				; try the other four PTEs in this PTEG
	andi.	r9, r16, 0x40				; but if that bit went back to 0 from 1 then we're out of PTEs!

	addi	r18, r18, -0x3c
	xor		r18, r18, r17

	bne		@try_other_four_PTEs

	blr									; fail
