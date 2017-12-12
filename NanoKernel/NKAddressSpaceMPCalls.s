Local_Panic		set		*
				b		panic



InitFreeList
	addi	r9, r1, PSA.FreeList

	InitList	r9, 'PHYS', scratch=r8

	li		r8, 0
	stw		r8, PSA.FreePageCount(r1)
	stw		r8, PSA.UnheldFreePageCount(r1)
	stw		r8, PSA.ZeroedByInitFreeList3(r1)

	lwz		r8, PSA.OtherSystemAddrSpcPtr(r1)
	stw		r8, PSA.OtherSystemAddrSpcPtr2(r1)

	blr



;	                 convert_pmdts_to_areas

;	Pretty obvious from log output.

;	Xrefs:
;	setup

convert_pmdts_to_areas	;	OUTSIDE REFERER

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
	beq-	@pmdt_flags_are_zero
	beq-	cr1, @pmdt_flags_are_c00

	;	Else if not a full-segment PMDT, next PMDT
	cmplwi	cr2, r15,  0x0000
	cmplwi	cr3, r16,  0xffff
	bne+	cr2, @next_pmdt
	bne+	cr3, @next_pmdt

	;	Else if there are segments remaining (16 total), next segment.
	addis	r26, r26, 0x1000
	cmplwi	r26, 0					; once it wraps to zero, we're done
	bne+	@next_segment_entry

	;	Else create special one-page Areas to catch naughty pointer derefs,
	;	then return.

		;	61F168F1 (magic bus error incantation)

		li		r8, Area.Size
		bl		PoolAlloc
		mr.		r31, r8
		beq+	Local_Panic

		lwz		r8, EWA.PA_CurAddressSpace(r1)
		stw		r8, Area.AddressSpacePtr(r31)

		lisori	r15, 0x68f168f1
		stw		r15, Area.LogicalBase(r31)

		li		r16, 0x1000
		stw		r16, Area.Length(r31)

		lisori	r8, 0x00008000
		stw		r8, Area.Zero(r31)

		li		r8, 0
		stw		r8, 0x001c(r31)

		lisori	r8, 0x0000e00c
		stw		r8, 0x0020(r31)

		mr		r8, r31
		bl		createarea

		cmpwi	r9, noErr
		beq-	@success_68f168f1
		mr		r8, r31
		bl		PoolFree
@success_68f168f1


		;	DEADBEEF (all over the place)

		li		r8, Area.Size
		bl		PoolAlloc
		mr.		r31, r8
		beq+	Local_Panic

		lwz		r8, EWA.PA_CurAddressSpace(r1)
		stw		r8, Area.AddressSpacePtr(r31)

		lisori	r15, 0xdeadbeef
		stw		r15, Area.LogicalBase(r31)

		li		r16, 0x1000
		stw		r16, Area.Length(r31)

		lisori	r8, 0x00008000
		stw		r8, Area.Zero(r31)

		li		r8, 0
		stw		r8, 0x001c(r31)

		lisori	r8, 0x0000e00c
		stw		r8, 0x0020(r31)

		mr		r8, r31
		bl		createarea

		cmpwi	r9, noErr
		beq-	@success_deadbeef
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
		beq-	@thing_is_zero

		bl		createarea
		cmpwi	r9, noErr
		bne+	Local_Panic

		li		r8, 0
		stw		r8, EWA.SpacesDeferredAreaPtr(r1)
@thing_is_zero



	li		r8, Area.Size
	bl		PoolAlloc
	mr.		r31, r8
	beq+	Local_Panic

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
	stw		r16, Area.Length2(r31)

	li		r8, 0
	stw		r8, Area.Zero(r31)

	lwz		r18,  0x007c(r31)
	rlwinm	r9, r17,  0,  0, 19
	stw		r9,  0x0070(r31)
	andi.	r16, r17,  0x03
	bne-	@_20c
	ori		r17, r17,  0x02
@_20c

	bl		major_0x10d38_0x58
	stw		r18,  0x001c(r31)


@_214



	lisori	r8, 0x0000e00c
	stw		r8, 0x0020(r31)


	;	Try to create the Area. If we succeed then do the next PMDT.
	mr		r8, r31
	bl		createarea
	cmpwi	r9, noErr
	mr		r31, r8
	beq+	@next_pmdt

	;	If CreateArea failed, assume that it was due to overlap with another Area.

		;	Find that AboveArea that we impinged on (=> r24).
		lwz		r9, Area.LogicalBase(r31)
		lwz		r8, Area.AddressSpacePtr(r31)
		bl		FindAreaAbove
		mr		r24, r8

		;	Shorten our FailedArea to fit below AboveArea.
		lwz		r15, Area.LogicalBase(r31)
		lwz		r16, Area.LogicalBase(r24)
		lwz		r17, Area.LogicalBase2(r31)
		subf.	r16, r15, r16						; r16 = offset of found area from this one
		stw		r17, EWA.SpacesSavedAreaBase(r1)	; ???
		stw		r16, Area.Length(r31)				; we will try again, with no overlap

		beq-	@found_area_has_same_base

		;	If FoundArea < FailedArea, panic (impossible for FindAreaAbove to return this)
			bltl+	Local_Panic							; below would be impossible

		;	If AboveArea > FailedArea, create NewArea (=> r30)
			mr		r8, r31
			bl		createarea

			cmpwi	r9, noErr							; strike three
			mr		r30, r8
			bnel+	Local_Panic

			;	If AboveArea.LogicalBase2 >= FailedArea.LogicalBase2 then continue to next PMDT.
				lwz		r15, Area.LogicalBase2(r24)
				lwz		r16, EWA.SpacesSavedAreaBase(r1)
				subf.	r16, r15, r16
				ble+	@next_pmdt

			;	Else replace FailedArea with an Area copied from NewArea
					li		r8, Area.Size
					bl		PoolAlloc
					mr.		r31, r8
					beq+	Local_Panic

					li		r8, Area.Size - 4
@area_copy_loop
					lwzx	r9, r8, r30
					stwx	r9, r8, r31
					cmpwi	r8, 0
					subi	r8, r8, 4
					bgt+	@area_copy_loop
@found_area_has_same_base

		;	Else (AboveArea == ThisArea), do nothing special (endif)


		lwz		r9, Area.LogicalBase(r31)

		lwz		r15,  0x0028(r24)
		lwz		r16, EWA.SpacesSavedAreaBase(r1)		; this is FailedArea.LogicalBase2
		subf.	r16, r15, r16
		addi	r15, r15, 1
		blel+	Local_Panic

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
	bl		PoolAlloc
	mr.		r31, r8
	beq+	Local_Panic

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
	stw		r16, Area.Length2(r31)
	li		r8,  0x00
	stw		r8, Area.Zero(r31)
	li		r8,  0x07
	stw		r8,  0x001c(r31)
	lis		r8,  0x00
	ori		r8, r8,  0x600c
	stw		r8,  0x0020(r31)
	rlwinm	r8, r17, 22,  0, 29
	stw		r8,  0x0040(r31)
	lwz		r8, Area.TwoFiftySix(r31)
	ori		r8, r8,  0x40
	lwz		r9, -0x0430(r1)
	cmpwi	r9, noErr

	bgt-	@_374
	ori		r8, r8,  0x80
@_374

	stw		r8, Area.TwoFiftySix(r31)
	cmpwi	r15,  0x00

	bne-	@_388
	stw		r31, EWA.SpacesDeferredAreaPtr(r1)
	b		@next_pmdt
@_388

	lwz		r18, EWA.SpacesDeferredAreaPtr(r1)
	cmpwi	r18,  0x00
	beq-	@_3c8
	lwz		r8,  0x0024(r18)
	lwz		r9,  0x002c(r18)
	add		r19, r8, r9
	cmplw	r19, r15
	bne-	@_3c8
	add		r9, r9, r16
	addi	r19, r9, -0x01
	stw		r9,  0x002c(r18)
	stw		r9,  0x0038(r18)
	stw		r19,  0x0028(r18)
	mr		r8, r31
	bl		PoolFree
	b		@next_pmdt
@_3c8

	lwz		r8, Area.TwoFiftySix(r31)
	ori		r8, r8,  0x80
	stw		r8, Area.TwoFiftySix(r31)
	mr		r8, r31
	bl		createarea
	cmpwi	r9, noErr
	bne+	Local_Panic
	b		@next_pmdt





;	                  KCGetPageSizeClasses


;	> r1    = kdp

;	< r3    = pageClass

	DeclareMPCall	68, KCGetPageSizeClasses

KCGetPageSizeClasses	;	OUTSIDE REFERER
	li		r3,  0x01
	b		CommonMPCallReturnPath



;	                     KCGetPageSize


;	> r1    = kdp
;	> r3    = pageClass

;	< r3    = byteCount

	DeclareMPCall	69, KCGetPageSize

KCGetPageSize	;	OUTSIDE REFERER
	cmpwi	r3,  0x01
	bne+	ReturnParamErrFromMPCall
	lwz		r3,  0x0f30(r1)
	b		CommonMPCallReturnPath



	DeclareMPCall	70, MPCall_70

MPCall_70	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mfsprg	r16, 0
	lwz		r17, -0x0008(r16)
	mr		r8, r3
	lwz		r9, Area.AddressSpacePtr(r17)
	lwz		r16,  0x0008(r9)
	rlwinm.	r16, r16,  0, 30, 30
	bne+	ReleaseAndReturnMPCallOOM
	bl		NKCreateAddressSpaceSub
	_AssertAndRelease	PSA.SchLock, scratch=r16
	mr.		r3, r8
	li		r4,  0x00
	bne+	CommonMPCallReturnPath
	lwz		r4,  0x0000(r9)
	b		CommonMPCallReturnPath



;	ARG		MPCoherenceID r8 owningcgrp		; 0 to use mobo cgrp
;			Process *r9 owningPROC

;	RET		osErr r8
;			AddressSpace *r9

NKCreateAddressSpaceSub
	cmpwi	r8, 0
	mr		r27, r9			; Save the process arg for later
	mflr	r30

	;	Use the motherboard coherence group if none is provided in r8
	bne-	@cgrp_provided
	mfsprg	r15, 0
	lwz		r28, EWA.CPUBase + CPU.CgrpList + LLL.Freeform(r15)

	b		@got_cgrp

@cgrp_provided
	bl		LookupID			; takes id in r8, returns ptr in r8 and kind in r9

	cmpwi	r9, CoherenceGroup.kIDClass
	mr		r28, r8
	bne-	@fail_notcgrp
	lwz		r28, CoherenceGroup.GRPSList + LLL.Next(r28)

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
	bl		PoolAlloc
	mr.		r31, r8
	beq-	@fail_OOM


	;	Give the addr spc a copy of the SpecialPtr of its parent cgrp
	stw		r29, AddressSpace.ParentCoherenceSpecialPtr(r31)


	;	Give the addr spc an ID
	li		r9, AddressSpace.kIDClass
	bl		MakeID

	cmpwi	r8, 0x00
	beq-	@fail_MakeID

	stw		r8, AddressSpace.ID(r31)


	;	Increment a counter in the cgrp (modulo a million, fail on overflow)
	lwz		r16, CoherenceGroup.Incrementer(r28)
	addi	r16, r16, 1
	clrlwi.	r16, r16, 12
	beq-	@fail_toomanycalls
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
	bne+	@fill_loop


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
		bl		PoolAlloc
		mr.		r29, r8
		beq-	@fail_OOM_again

		;	Sign the Area
		lisori	r8, Area.kSignature
		stw		r8, Area.Signature(r29)

		;	Pop some constants in
		lisori	r8, -1
		stw		r8, Area.LogicalBase(r29)
		stw		r8, Area.LogicalBase2(r29)
		li		r8, 256
		stw		r8, Area.TwoFiftySix(r29)

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
	li		r8, -0x726e
	b		@return

@fail_notcgrp
	li		r8, kMPInvalidIDErr

@return
	mtlr	r30
	blr



	DeclareMPCall	71, MPCall_71

MPCall_71	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.ProcessID(r31)
	cmpwi	r16,  0x00
	bne+	ReleaseAndReturnMPCallOOM
	addi	r16, r31,  0x10
	lwz		r17,  0x0018(r31)
	cmpw	r16, r17
	bne+	ReleaseAndReturnMPCallOOM
	addi	r16, r31,  0x20
	lwz		r17, Area.LogicalBase2(r31)
	cmpw	r16, r17
	bne+	ReleaseAndReturnMPCallOOM
	lwz		r8,  0x0074(r31)

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cgrp, 11:area, 12:not, 13:log

	lwz		r17,  0x0018(r8)
	addi	r17, r17, -0x01
	stw		r17,  0x0018(r8)
	lwz		r8, Area.ID(r31)
	bl		DeleteID
	mr		r8, r31
	bl		PoolFree

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                 KCCurrentAddressSpace


	DeclareMPCall	117, KCCurrentAddressSpace

KCCurrentAddressSpace	;	OUTSIDE REFERER
	mfsprg	r16, 0
	lwz		r17, EWA.PA_CurAddressSpace(r16)
	lwz		r3, AddressSpace.ID(r17)
	b		CommonMPCallReturnPath



;	                   KCHomeAddressSpace


	DeclareMPCall	118, KCHomeAddressSpace

KCHomeAddressSpace	;	OUTSIDE REFERER
	mfsprg	r16, 0
	lwz		r17, EWA.PA_CurTask(r16)
	lwz		r18, Task.OwningProcessPtr(r17)
	lwz		r19, Process.SystemAddressSpacePtr(r18)
	lwz		r3, AddressSpace.ID(r19)
	b		CommonMPCallReturnPath



;	                 KCSetTaskAddressSpace


	DeclareMPCall	119, KCSetTaskAddressSpace

KCSetTaskAddressSpace	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cgrp, 11:area, 12:not, 13:log

	mr		r31, r8
	cmpwi	r9,  0x02
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  0x0064(r31)
	mtcr	r16
	li		r3, -0x7271
	beq+	cr7, ReleaseAndReturnMPCall
	bne+	cr5, ReleaseAndReturnMPCallOOM
	lbz		r16,  0x0018(r31)
	cmpwi	r16,  0x00
	bne+	ReleaseAndReturnMPCallOOM
	mr		r8, r4

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cgrp, 11:area, 12:not, 13:log

	mr		r30, r8
	lwz		r16,  0x0060(r31)
	cmpwi	r9,  0x08
	lwz		r17,  0x0074(r30)
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	cmpw	r16, r17
	bne+	ReleaseAndReturnMPCallOOM
	lwz		r17,  0x0070(r31)
	lwz		r16,  0x000c(r17)
	addi	r16, r16, -0x01
	stw		r16,  0x000c(r17)
	lwz		r16,  0x000c(r30)
	addi	r16, r16,  0x01
	stw		r16,  0x000c(r30)
	stw		r30,  0x0070(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	72, MPCall_72

MPCall_72	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	mfsprg	r28, 0
	lwz		r30, EWA.PA_CurAddressSpace(r28)
	beq-	MPCall_72_0x38

;	r8 = id
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	mr		r30, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr

MPCall_72_0x38
	li		r8, 160

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	mr.		r31, r8
	beq+	major_0x0af60
	stw		r30, Area.AddressSpacePtr(r31)
	stw		r4,  0x001c(r31)
	stw		r5, Area.Length(r31)
	lwz		r8,  0x0134(r6)
	stw		r8, Area.Zero(r31)
	lwz		r8,  0x013c(r6)
	stw		r8,  0x0020(r31)
	lwz		r8,  0x0144(r6)
	stw		r8, Area.LogicalBase(r31)
	mr		r8, r31
	bl		createarea
	_AssertAndRelease	PSA.SchLock, scratch=r16

MPCall_72_0x90
	stw		r16, PSA.SchLock + Lock.Count(r1)
	mr.		r3, r9
	bne-	MPCall_72_0xb0
	lwz		r8, Area.LogicalBase(r31)
	stw		r8,  0x0144(r6)
	lwz		r8, Area.ID(r31)
	stw		r8,  0x014c(r6)
	b		CommonMPCallReturnPath

MPCall_72_0xb0
	bl		PoolFree
	b		CommonMPCallReturnPath



;	                       createarea

;	Xrefs:
;	convert_pmdts_to_areas
;	MPCall_72
;	MPCall_73

;	This function actually gets passed its own structure.
;	What the frick?

;	Always returns via ReturnFromCreateArea

;	ARG		Area *r8
;	RET		ID r8, osErr r9

createarea	;	OUTSIDE REFERER

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


	lwz		r16, Area.TwoFiftySix(r31)
	lwz		r17,  0x0020(r31)
	rlwinm.	r16, r16,  0, 28, 28

	lisori	r16, 0xfffc13e0		; if bit 28 = 0
	beq-	@use_other
	lisori	r16, 0xfff99be0		; if bit 28 = 1
@use_other

	and.	r16, r16, r17
	bne-	ReturnFromCreateArea

	andi.	r16, r17,  0x1f
	cmpwi	cr1, r16,  0x0c
	beq-	createarea_0x50
	blt-	cr1, ReturnFromCreateArea

createarea_0x50
	bne-	createarea_0x5c
	ori		r17, r17,  0x0c
	stw		r17,  0x0020(r31)

createarea_0x5c
	andi.	r16, r17,  0x1f
	li		r18, -0x01
	slw		r18, r18, r16
	stw		r18,  0x0078(r31)
	rlwinm.	r16, r17, 27, 27, 31
	bne-	ReturnFromCreateArea
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
	beq-	ReturnFromCreateArea
	lwz		r18,  0x001c(r31)
	lis		r16, -0x01
	ori		r16, r16,  0xff10
	and.	r16, r16, r18
	bne-	ReturnFromCreateArea
	lwz		r16,  0x0070(r31)
	li		r17,  0x200
	rlwimi	r17, r16,  0,  0, 19
	bl		major_0x10cb8
	stw		r16,  0x0070(r31)
	stw		r17,  0x0074(r31)
	mr		r8, r31

	li		r9, Area.kIDClass
	bl		MakeID
	cmpwi	r8, 0
	beq-	major_0x10320

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
	bne-	major_0x10320_0x64
	lis		r16,  0x4152
	ori		r16, r16,  0x4541
	stw		r16, Area.Signature(r31)
	lwz		r17,  0x0020(r31)
	lwz		r16, Area.Zero(r31)
	addi	r16, r16,  0xfff
	rlwinm	r16, r16,  0,  0, 19
	stw		r16, Area.Zero(r31)
	rlwinm	r16, r17,  0, 17, 18
	cmplwi	cr7, r16,  0x6000
	rlwinm.	r16, r17,  0, 17, 17
	beq-	cr7, createarea_0x150
	bne-	createarea_0x150
	crset	cr7_gt
	crclr	cr7_lt

createarea_0x150
	rlwinm.	r16, r17,  0, 17, 18
	lwz		r18, Area.LogicalBase(r31)
	lwz		r19, Area.Length(r31)
	blt-	cr7, createarea_0x16c
	bne-	createarea_0x170
	li		r18,  0x00
	b		createarea_0x170

createarea_0x16c
	subf	r18, r19, r18

createarea_0x170
	lwz		r16,  0x0078(r31)
	and		r18, r18, r16
	stw		r18, Area.LogicalBase(r31)
	add		r16, r18, r19
	addi	r16, r16, -0x01
	stw		r16, Area.LogicalBase2(r31)


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


	bgt-	cr7, createarea_0x1f4
	blt-	cr7, createarea_0x218
	_log	'placed'
	b		createarea_0x234

createarea_0x1f4
	_log	'placed at or above'
	b		createarea_0x234

createarea_0x218
	_log	'placed below'

createarea_0x234
	lwz		r8, Area.AddressSpacePtr(r31)
	lwz		r16, Area.LogicalBase2(r31)
	lwz		r9, Area.LogicalBase(r31)
	cmplw	r9, r16
	bge-	major_0x10320_0x64
	bl		FindAreaAbove
	mr		r30, r8
	lwz		r14, Area.LogicalBase(r31)
	lwz		r15, Area.LogicalBase2(r31)
	lwz		r16, Area.Zero(r31)
	lwz		r17,  0x0024(r30)
	lwz		r18,  0x0028(r30)
	lwz		r19,  0x0030(r30)
	lwz		r21, Area.AddressSpacePtr(r31)
	cmpwi	r17, -0x01
	add		r8, r15, r16
	add		r9, r15, r19
	beq-	createarea_0x2b8
	cmplw	r8, r17
	cmplw	cr1, r9, r17
	bge-	createarea_0x28c
	blt-	cr1, createarea_0x2b8

createarea_0x28c
	beq-	cr7, major_0x10320_0x64
	_log	' ... bc search^n'
	bgt-	cr7, createarea_0x34c
	b		createarea_0x31c

createarea_0x2b8
	addi	r21, r21,  0x20
	lwz		r20,  0x0060(r30)
	cmpw	r20, r21
	beq-	createarea_0x39c
	addi	r20, r20, -0x54
	lwz		r17,  0x0024(r20)
	lwz		r18,  0x0028(r20)
	lwz		r19,  0x0030(r20)
	add		r8, r18, r16
	add		r9, r18, r19
	cmplw	r8, r14
	cmplw	cr1, r9, r14
	bge-	createarea_0x2f0
	blt-	cr1, createarea_0x374

createarea_0x2f0
	beq-	cr7, major_0x10320_0x64
	_log	' ... ab search^n'
	bgt-	cr7, createarea_0x34c
	b		createarea_0x31c

createarea_0x31c
	subf	r8, r19, r17
	subf	r9, r16, r17
	cmplw	r8, r9
	lwz		r21, Area.Length(r31)
	ble-	createarea_0x334
	mr		r8, r9

createarea_0x334
	subf	r8, r21, r8
	cmplw	r8, r14
	addi	r18, r8,  0x01
	lwz		r19, Area.Length(r31)
	bge-	major_0x10320_0x64
	b		createarea_0x170

createarea_0x34c
	add		r8, r18, r19
	add		r9, r18, r16
	lwz		r20,  0x0078(r31)
	cmplw	r8, r9
	neg		r21, r20
	bge-	createarea_0x368
	mr		r8, r9

createarea_0x368
	add		r18, r8, r21
	lwz		r19, Area.Length(r31)
	b		createarea_0x170

createarea_0x374
	addi	r19, r31,  0x54
	addi	r20, r20,  0x54
	lwz		r16,  0x0000(r20)
	stw		r16,  0x0000(r19)
	lwz		r16,  0x0008(r20)
	stw		r16,  0x0008(r19)
	stw		r20,  0x000c(r19)
	stw		r19,  0x000c(r16)
	stw		r19,  0x0008(r20)
	b		createarea_0x3b8

createarea_0x39c
	addi	r19, r31,  0x54
	stw		r20,  0x0000(r19)
	stw		r20,  0x000c(r19)
	lwz		r16,  0x0008(r20)
	stw		r16,  0x0008(r19)
	stw		r19,  0x000c(r16)
	stw		r19,  0x0008(r20)

createarea_0x3b8
	addi	r16, r31,  0x90
	lis		r17,  0x6665
	stw		r16,  0x0008(r16)
	ori		r17, r17,  0x6e63
	stw		r16,  0x000c(r16)
	stw		r17,  0x0004(r16)
	lwz		r16,  0x0020(r31)
	lwz		r17, Area.TwoFiftySix(r31)
	rlwinm.	r8, r16,  0, 16, 16
	bne-	createarea_0x64c
	rlwinm.	r8, r17,  0, 25, 25
	bne-	createarea_0x41c
	lwz		r8, Area.Length(r31)
	rlwinm	r8, r8, 22, 10, 29
	mr		r29, r8

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	cmpwi	r8,  0x00
	stw		r8,  0x0040(r31)
	beq-	createarea_0x460
	lwz		r9, Area.Length(r31)
	srwi	r9, r9, 12
	bl		major_0x10284
	lwz		r17, Area.TwoFiftySix(r31)
	ori		r17, r17,  0x10
	stw		r17, Area.TwoFiftySix(r31)

createarea_0x41c
	lwz		r17, Area.TwoFiftySix(r31)
	andi.	r8, r17,  0x88
	lwz		r8, Area.Length(r31)
	bne-	createarea_0x45c
	rlwinm	r8, r8, 21, 11, 30
	mr		r29, r8

;	r1 = kdp
;	r8 = size
	bl		PoolAlloc
;	r8 = ptr

	cmpwi	r8,  0x00
	stw		r8,  0x003c(r31)
	beq-	createarea_0x460
	lwz		r9, Area.Length(r31)
	srwi	r9, r9, 12
	bl		major_0x102a8
	lwz		r16, Area.TwoFiftySix(r31)
	ori		r16, r16,  0x01
	stw		r16, Area.TwoFiftySix(r31)

createarea_0x45c
	b		createarea_0x64c

createarea_0x460
	cmpwi	r29,  0xfd8
	ble-	major_0x10320_0x20

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r17, Area.TwoFiftySix(r31)
	li		r27,  0x00
	rlwinm.	r8, r17,  0, 25, 25
	bne-	createarea_0x4b4
	lwz		r27, Area.Length(r31)
	srwi	r27, r27, 12
	cmpwi	r27,  0x400
	ble-	createarea_0x4ac
	ori		r17, r17,  0x20
	stw		r17, Area.TwoFiftySix(r31)
	addi	r27, r27,  0x400

createarea_0x4ac
	addi	r27, r27,  0x3ff
	srwi	r27, r27, 10

createarea_0x4b4
	lwz		r8, Area.TwoFiftySix(r31)
	li		r29,  0x00
	rlwinm.	r9, r8,  0, 28, 28
	bne-	createarea_0x4e8
	lwz		r29, Area.Length(r31)
	srwi	r29, r29, 12
	cmpwi	r29,  0x800
	ble-	createarea_0x4e0
	ori		r8, r8,  0x02
	stw		r8, Area.TwoFiftySix(r31)
	addi	r29, r29,  0x800

createarea_0x4e0
	addi	r29, r29,  0x7ff
	srwi	r29, r29, 11

createarea_0x4e8
	lwz		r18, -0x0430(r1)
	add.	r8, r27, r29
	ble-	major_0x102c8
	cmpw	r8, r18
	bgt-	major_0x102c8
	lwz		r16, -0x0430(r1)
	lwz		r17, PSA.UnheldFreePageCount(r1)
	subf	r16, r8, r16
	subf	r17, r8, r17
	stw		r16, -0x0430(r1)
	stw		r17, PSA.UnheldFreePageCount(r1)
	mr.		r18, r27
	beq-	createarea_0x5a0
	lwz		r16, -0x0448(r1)
	lwz		r17,  0x0008(r16)
	lwz		r19,  0x000c(r16)
	stw		r17,  0x0008(r19)
	stw		r19,  0x000c(r17)
	li		r17,  0x00
	stw		r17,  0x0008(r16)
	stw		r17,  0x000c(r16)
	addi	r18, r18, -0x01
	stw		r16,  0x0040(r31)
	cmpwi	r18,  0x00
	lwz		r17, -0x0448(r1)
	mr		r8, r16
	subi	r16, r16, 4
	bgt-	createarea_0x564
	li		r9,  0x400
	bl		major_0x10284
	b		createarea_0x5a0

createarea_0x564
	lwz		r19,  0x0008(r17)
	lwz		r20,  0x000c(r17)
	stw		r19,  0x0008(r20)
	stw		r20,  0x000c(r19)
	li		r19,  0x00
	stw		r19,  0x0008(r17)
	stw		r19,  0x000c(r17)
	addi	r18, r18, -0x01
	stwu	r17,  0x0004(r16)
	mr		r8, r17
	li		r9,  0x400
	bl		major_0x10284
	lwz		r17, -0x0448(r1)
	cmpwi	r18,  0x00
	bgt+	createarea_0x564

createarea_0x5a0
	mr.		r18, r29
	beq-	createarea_0x62c
	lwz		r16, -0x0448(r1)
	lwz		r17,  0x0008(r16)
	lwz		r19,  0x000c(r16)
	stw		r17,  0x0008(r19)
	stw		r19,  0x000c(r17)
	li		r17,  0x00
	stw		r17,  0x0008(r16)
	stw		r17,  0x000c(r16)
	addi	r18, r18, -0x01
	stw		r16,  0x003c(r31)
	cmpwi	r18,  0x00
	lwz		r17, -0x0448(r1)
	mr		r8, r16
	subi	r16, r16, 4
	bgt-	createarea_0x5f0
	li		r9,  0x800
	bl		major_0x102a8
	b		createarea_0x62c

createarea_0x5f0
	lwz		r19,  0x0008(r17)
	lwz		r20,  0x000c(r17)
	stw		r19,  0x0008(r20)
	stw		r20,  0x000c(r19)
	li		r19,  0x00
	stw		r19,  0x0008(r17)
	stw		r19,  0x000c(r17)
	addi	r18, r18, -0x01
	stwu	r17,  0x0004(r16)
	mr		r8, r17
	li		r9,  0x800
	bl		major_0x102a8
	lwz		r17, -0x0448(r1)
	cmpwi	r18,  0x00
	bgt+	createarea_0x5f0

createarea_0x62c
	_AssertAndRelease	PSA.PoolLock, scratch=r16

createarea_0x64c
	lwz		r16, Area.TwoFiftySix(r31)
	rlwinm.	r8, r16,  0, 28, 28
	beq-	createarea_0x67c
	lwz		r16,  0x0044(r31)
	addi	r17, r31,  0x44
	stw		r16,  0x0000(r17)
	stw		r16,  0x0008(r17)
	lwz		r18,  0x000c(r16)
	stw		r18,  0x000c(r17)
	stw		r17,  0x0008(r18)
	stw		r17,  0x000c(r16)
	b		major_0x10320_0x94

createarea_0x67c
	addi	r16, r31,  0x44
	lis		r17,  0x414b
	stw		r16,  0x0008(r16)
	ori		r17, r17,  0x4120
	stw		r16,  0x000c(r16)
	stw		r17,  0x0004(r16)
	b		major_0x10320_0x94



;	                     major_0x10284

;	Xrefs:
;	createarea

major_0x10284	;	OUTSIDE REFERER
	subi	r8, r8, 4
	addi	r9, r9, -0x01
	lwz		r20,  0x0074(r31)
	ori		r20, r20,  0x200

major_0x10284_0x10
	cmpwi	r9, noErr
	stwu	r20,  0x0004(r8)
	addi	r9, r9, -0x01
	bgt+	major_0x10284_0x10
	blr



;	                     major_0x102a8

;	Xrefs:
;	createarea

major_0x102a8	;	OUTSIDE REFERER
	addi	r8, r8, -0x02
	addi	r9, r9, -0x01
	li		r20,  0x7fff

major_0x102a8_0xc
	cmpwi	r9, noErr
	sthu	r20,  0x0002(r8)
	addi	r9, r9, -0x01
	bgt+	major_0x102a8_0xc
	blr



;	                     major_0x102c8

;	Xrefs:
;	createarea

major_0x102c8	;	OUTSIDE REFERER
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	addi	r30, r8,  0x08
	lwz		r8, -0x0420(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r26, r8
	bne-	major_0x10320_0x20
	li		r8,  0x02
	stw		r8,  0x0010(r26)
	stw		r30,  0x0014(r26)
	li		r29,  0x00
	stw		r29,  0x0018(r26)
	mr		r30, r26
	bl		major_0x0db04
	b		major_0x10320_0x20



;	                     major_0x10320

;	Xrefs:
;	IntDSIOtherOther
;	PagingFunc1
;	MPCall_60
;	convert_pmdts_to_areas
;	createarea
;	major_0x102c8
;	MPCall_80
;	MPCall_125
;	MPCall_95

major_0x10320	;	OUTSIDE REFERER
	mr		r8, r31
	li		r9, -0x726e
	b		ReturnFromCreateArea
	dc.l	0x811f0000
	dc.l	0x48004fd1
	dc.l	0x7fe8fb78
	dc.l	0x39208d8d
	dc.l	0x4800009c

major_0x10320_0x20	;	OUTSIDE REFERER
	addi	r19, r31,  0x54
	lwz		r16,  0x0008(r19)
	lwz		r17,  0x000c(r19)
	stw		r16,  0x0008(r17)
	stw		r17,  0x000c(r16)
	li		r16,  0x00
	stw		r16,  0x0008(r19)
	stw		r16,  0x000c(r19)
	lwz		r16, Area.TwoFiftySix(r31)
	lwz		r8,  0x0040(r31)
	rlwinm.	r16, r16,  0, 25, 25
	bne-	major_0x10320_0x58
	cmpwi	r8,  0x00
	bnel-	PoolFree

major_0x10320_0x58
	lwz		r8,  0x003c(r31)
	cmpwi	r8,  0x00
	bnel-	PoolFree

major_0x10320_0x64	;	OUTSIDE REFERER
	_log	' ... skipped^n'
	lwz		r8, Area.ID(r31)
	bl		DeleteID
	mr		r8, r31
	li		r9, -0x7272
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
	;		max(Area.LogicalBase, Area.LogicalBase2) >= r9
	lwz		r16, Area.LogicalBase(r8)
	lwz		r17, Area.LogicalBase2(r8)
	cmplw	r16, r9
	cmplw	cr1, r17, r9
	bgelr-
	bgelr-	cr1

	;	Iterate over linked list
	lwz		r8, Area.LLL + LLL.Next(r8)
	b		@loop



	DeclareMPCall	73, MPCall_73

MPCall_73	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3
 	bl		LookupID
	cmpwi	r9, Area.kIDClass
	bne+	ReleaseAndReturnMPCallInvalidIDErr

	mr		r30, r8
	lwz		r16,  0x0008(r30)
	rlwinm.	r8, r16,  0, 28, 28
	bne+	major_0x0b054

	li		r8, Area.Size
	bl		PoolAlloc
	mr.		r31, r8
	beq+	major_0x0af60

	mfsprg	r28, 0
	lwz		r8, EWA.PA_CurAddressSpace(r28)
	stw		r8, Area.AddressSpacePtr(r31)
	stw		r3,  0x0014(r31)
	stw		r30,  0x0044(r31)
	stw		r4,  0x001c(r31)
	stw		r5, Area.Length(r31)
	lwz		r8,  0x0134(r6)
	stw		r8, Area.Zero(r31)
	lwz		r8,  0x013c(r6)
	stw		r8,  0x0020(r31)
	lwz		r8,  0x0144(r6)
	stw		r8, Area.LogicalBase(r31)
	lwz		r8,  0x014c(r6)
	stw		r8,  0x0080(r31)
	li		r8,  0x08
	stw		r8, Area.TwoFiftySix(r31)
	mr		r8, r31
	bl		createarea
	_AssertAndRelease	PSA.SchLock, scratch=r16

MPCall_73_0xb0
	stw		r16, PSA.SchLock + Lock.Count(r1)
	mr.		r3, r9
	bne-	MPCall_73_0xd0
	lwz		r8, Area.LogicalBase(r31)
	stw		r8,  0x0144(r6)
	lwz		r8, Area.ID(r31)
	stw		r8,  0x0154(r6)
	b		CommonMPCallReturnPath

MPCall_73_0xd0
	bl		PoolFree
	b		CommonMPCallReturnPath



	DeclareMPCall	74, MPCall_74

MPCall_74	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r17, Area.Length2(r31)
	lwz		r29, Area.TwoFiftySix(r31)
	cmpwi	cr1, r17,  0x00
	rlwinm.	r8, r29,  0, 29, 29
	bne+	cr1, ReleaseAndReturnMPCallOOM
	bne+	ReleaseAndReturnMPCallPrivilegedErr
	rlwinm.	r8, r29,  0, 28, 28
	lwz		r16,  0x004c(r31)
	bne-	MPCall_74_0x5c
	addi	r17, r31,  0x44
	cmpw	r16, r17
	bne+	ReleaseAndReturnMPCallOOM

MPCall_74_0x5c

	_Lock			PSA.HTABLock, scratch1=r18, scratch2=r9

	addi	r16, r31,  0x54
	lwz		r17,  0x0008(r16)
	lwz		r18,  0x000c(r16)
	stw		r17,  0x0008(r18)
	stw		r18,  0x000c(r17)
	li		r17,  0x00
	stw		r17,  0x0008(r16)
	stw		r17,  0x000c(r16)
	rlwinm.	r8, r29,  0, 28, 28
	addi	r16, r31,  0x44
	beq-	MPCall_74_0xbc
	lwz		r17,  0x0008(r16)
	lwz		r18,  0x000c(r16)
	stw		r17,  0x0008(r18)
	stw		r18,  0x000c(r17)
	li		r17,  0x00
	stw		r17,  0x0008(r16)
	stw		r17,  0x000c(r16)

MPCall_74_0xbc
	_AssertAndRelease	PSA.HTABLock, scratch=r18
	lwz		r8,  0x0040(r31)
	rlwinm.	r16, r29,  0, 25, 25
	cmpwi	cr1, r8,  0x00
	bne-	MPCall_74_0x178
	rlwinm.	r16, r29,  0, 27, 27
	beq-	cr1, MPCall_74_0x178
	bne-	MPCall_74_0x174

	_Lock			PSA.PoolLock, scratch1=r18, scratch2=r9

	rlwinm.	r16, r29,  0, 26, 26
	beq-	MPCall_74_0x14c
	lwz		r19, Area.Length(r31)
	mr		r20, r8
	srwi	r19, r19, 12
	addi	r19, r19,  0x3ff
	srwi	r19, r19, 10
	slwi	r19, r19,  2
	subi	r19, r19, 4

MPCall_74_0x134
	lwzx	r8, r19, r20

;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page
	cmpwi	r19,  0x00
	subi	r19, r19, 4
	bgt+	MPCall_74_0x134
	mr		r8, r20

MPCall_74_0x14c
;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page
	_AssertAndRelease	PSA.PoolLock, scratch=r18
	b		MPCall_74_0x178

MPCall_74_0x174
	bl		PoolFree

MPCall_74_0x178
	lwz		r8,  0x003c(r31)
	clrlwi.	r16, r29,  0x1f
	cmpwi	cr1, r8,  0x00
	beq-	cr1, MPCall_74_0x20c
	bne-	MPCall_74_0x208

	_Lock			PSA.PoolLock, scratch1=r18, scratch2=r9

	rlwinm.	r16, r29,  0, 30, 30
	beq-	MPCall_74_0x1e0
	lwz		r19, Area.Length(r31)
	mr		r20, r8
	srwi	r19, r19, 12
	addi	r19, r19,  0x7ff
	srwi	r19, r19, 11
	slwi	r19, r19,  2
	subi	r19, r19, 4

MPCall_74_0x1c8
	lwzx	r8, r19, r20

;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page
	cmpwi	r19,  0x00
	subi	r19, r19, 4
	bgt+	MPCall_74_0x1c8
	mr		r8, r20

MPCall_74_0x1e0
;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page
	_AssertAndRelease	PSA.PoolLock, scratch=r18
	b		MPCall_74_0x20c

MPCall_74_0x208
	bl		PoolFree

MPCall_74_0x20c
	lwz		r8, Area.ID(r31)
	bl		DeleteID
	mr		r8, r31
	bl		PoolFree

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	75, MPCall_75

MPCall_75	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16,  0x0020(r31)
	rlwinm.	r8, r16,  0, 16, 16
	bne+	ReleaseAndReturnMPCallOOM
	lwz		r18,  0x007c(r31)
	lwz		r17, Area.Length(r31)
	and.	r5, r5, r18
	and		r17, r17, r18
	ble+	major_0x0b054
	subf.	r27, r17, r5

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	bgt-	MPCall_75_0x1c8
	rlwinm.	r8, r4,  0, 24, 24
	lwz		r28, Area.LogicalBase(r31)
	lwz		r29, Area.LogicalBase2(r31)
	bne-	MPCall_75_0x74
	add		r28, r27, r29
	addi	r28, r28,  0x01
	b		MPCall_75_0x7c

MPCall_75_0x74
	subf	r29, r27, r28
	addi	r29, r29, -0x01

MPCall_75_0x7c

	_Lock			PSA.PoolLock, scratch1=r14, scratch2=r15


	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	lwz		r27,  0x0068(r31)

MPCall_75_0xb0
	mr		r8, r28
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bns-	cr7, MPCall_75_0xe0
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348
	lwz		r17,  0x0000(r30)
	rlwinm	r17, r17,  0,  0, 30
	rlwinm	r8, r17,  0,  0, 19
	stw		r17,  0x0000(r30)

;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page

MPCall_75_0xe0
	add		r28, r28, r27
	cmplw	r28, r29
	ble+	MPCall_75_0xb0
	rlwinm.	r8, r4,  0, 24, 24
	lwz		r28, Area.LogicalBase(r31)
	beq-	MPCall_75_0x138
	lwz		r27,  0x0068(r31)
	add		r29, r29, r27

MPCall_75_0x100
	mr		r8, r28
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	mr		r26, r30
	mr		r8, r29
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	lwz		r17,  0x0000(r30)
	stw		r17,  0x0000(r26)
	lwz		r16, Area.LogicalBase2(r31)
	add		r28, r28, r27
	add		r29, r29, r27
	cmplw	r29, r16
	ble+	MPCall_75_0x100

MPCall_75_0x138
	_AssertAndRelease	PSA.HTABLock, scratch=r8
	lwz		r16, Area.TwoFiftySix(r31)
	rlwinm.	r8, r16,  0, 25, 25
	bne-	MPCall_75_0x16c
	rlwinm.	r8, r16,  0, 27, 27
	bne-	MPCall_75_0x16c

MPCall_75_0x16c
	_AssertAndRelease	PSA.PoolLock, scratch=r8
	b		MPCall_75_0x190

MPCall_75_0x190
	rlwinm.	r8, r4,  0, 24, 24
	lwz		r16, Area.LogicalBase(r31)
	bne-	MPCall_75_0x1b0
	add		r17, r16, r5
	addi	r17, r17, -0x01
	stw		r5, Area.Length(r31)
	stw		r17, Area.LogicalBase2(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_75_0x1b0
	lwz		r17, Area.LogicalBase2(r31)
	subf	r16, r5, r17
	stw		r5, Area.Length(r31)
	addi	r16, r16,  0x01
	stw		r16, Area.LogicalBase(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_75_0x1c8
	rlwinm.	r8, r4,  0, 24, 24
	lwz		r28, Area.LogicalBase(r31)
	lwz		r29, Area.LogicalBase2(r31)
	bne+	ReleaseAndMPCallWasBad
	add		r28, r27, r29
	addi	r28, r28,  0x01
	b		MPCall_75_0x1ec
	dc.l	0x7fbbe050
	dc.l	0x3bbdffff

MPCall_75_0x1ec
	b		ReleaseAndMPCallWasBad



	DeclareMPCall	130, MPCall_130

MPCall_130	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lis		r16, -0x01
	ori		r16, r16,  0xfff8
	lwz		r17,  0x0020(r31)
	and.	r16, r16, r4
	bne+	major_0x0b054
	rlwinm.	r8, r17,  0, 16, 16
	bne+	major_0x0b054
	mr		r29, r5
	lwz		r18,  0x0134(r6)
	lwz		r19,  0x0068(r31)
	lwz		r16, Area.LogicalBase(r31)
	cmplw	r18, r19
	add		r28, r18, r29
	bge+	major_0x0b054
	lwz		r17,  0x007c(r31)
	addi	r28, r28, -0x01
	lwz		r18,  0x0020(r31)
	lwz		r19, Area.LogicalBase2(r31)
	cmplw	cr1, r29, r16
	cmplw	cr2, r28, r19
	blt+	cr1, major_0x0b054
	bgt+	cr2, major_0x0b054
	xor		r8, r28, r29
	rlwinm.	r8, r8,  0,  0, 19
	bne+	major_0x0b054

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r29
	bl		MPCall_95_0x1e4
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	beq+	Local_Panic
	rlwinm	r8, r16,  0, 29, 30
	lwz		r16,  0x0000(r30)
	cmpwi	cr7, r8,  0x04
	beq+	cr7, major_0x0b054
	lwz		r16,  0x0098(r31)

MPCall_130_0xe8
	addi	r17, r31,  0x90
	cmpw	r16, r17
	addi	r17, r16,  0x14
	beq-	MPCall_130_0x11c
	lwz		r8,  0x0010(r16)
	cmplwi	r8,  0x1f8
	add		r9, r8, r17
	blt-	MPCall_130_0x110
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
	bl		PoolAlloc
;	r8 = ptr

	mr.		r16, r8
	beq+	major_0x0af60
	addi	r18, r31,  0x90
	lis		r17,  0x4645
	ori		r17, r17,  0x4e43
	stw		r17,  0x0004(r16)
	stw		r18,  0x0000(r16)
	stw		r18,  0x0008(r16)
	lwz		r19,  0x000c(r18)
	stw		r19,  0x000c(r16)
	stw		r16,  0x0008(r19)
	stw		r16,  0x000c(r18)
	li		r8,  0x00
	addi	r9, r16,  0x14

MPCall_130_0x15c
	stw		r8,  0x0010(r16)
	stw		r29,  0x0000(r9)
	stw		r28,  0x0004(r9)

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r29
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bns-	cr7, MPCall_130_0x19c
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348

MPCall_130_0x19c
	lwz		r17,  0x0000(r30)
	li		r16,  0x06
	rlwimi	r17, r16,  0, 29, 30
	stw		r17,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                    KCSetAreaAccess


	DeclareMPCall	76, KCSetAreaAccess

KCSetAreaAccess	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lis		r16, -0x01
	ori		r16, r16,  0xff10
	and.	r16, r16, r4
	bne+	major_0x0b054
	lis		r16, -0x01
	ori		r16, r16,  0xff10
	and.	r16, r16, r5
	bne+	major_0x0b054
	lwz		r29,  0x0134(r6)
	lwz		r18,  0x013c(r6)
	lwz		r16, Area.LogicalBase(r31)
	add		r28, r18, r29
	lwz		r17,  0x007c(r31)
	addi	r28, r28, -0x01
	lwz		r18,  0x0020(r31)
	lwz		r19, Area.LogicalBase2(r31)
	rlwinm.	r8, r18,  0, 16, 16
	cmplw	cr1, r29, r16
	cmplw	cr2, r28, r19
	blt+	cr1, major_0x0b054
	bgt+	cr2, major_0x0b054
	bne-	KCSetAreaAccess_0x154

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15


KCSetAreaAccess_0x9c
	mr		r8, r29
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bns-	cr7, KCSetAreaAccess_0xb8
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348

KCSetAreaAccess_0xb8
	lwz		r17,  0x0000(r30)
	bl		major_0x10d38
	and		r8, r4, r5
	orc		r9, r4, r5
	or		r18, r18, r8
	and		r18, r18, r9
	lwz		r17,  0x0000(r30)
	rlwinm.	r8, r18,  0, 26, 26
	bns-	cr7, KCSetAreaAccess_0x118
	bgt-	cr6, KCSetAreaAccess_0x118
	beq-	KCSetAreaAccess_0x118
	rlwinm	r9, r17,  0,  0, 19
	lwz		r8,  0x0068(r31)

KCSetAreaAccess_0xec
	addi	r8, r8, -0x20
	dcbf	r8, r9
	cmpwi	r8,  0x00
	bgt+	KCSetAreaAccess_0xec
	sync
	lwz		r8,  0x0068(r31)

KCSetAreaAccess_0x104
	addi	r8, r8, -0x20
	icbi	r8, r9
	cmpwi	r8,  0x00
	bgt+	KCSetAreaAccess_0x104
	isync

KCSetAreaAccess_0x118
	bl		major_0x10cb8
	lwz		r19,  0x0068(r31)
	stw		r17,  0x0000(r30)
	add		r29, r29, r19
	subf.	r8, r29, r28
	bge+	KCSetAreaAccess_0x9c
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

KCSetAreaAccess_0x154
	bne+	cr1, major_0x0b054
	lwz		r18,  0x001c(r31)
	and		r8, r4, r5
	orc		r9, r4, r5
	or		r18, r18, r8
	and		r18, r18, r9
	stw		r18,  0x001c(r31)
	lwz		r16,  0x0070(r31)
	lwz		r17,  0x0074(r31)
	bl		major_0x10cb8
	stw		r16,  0x0070(r31)
	stw		r17,  0x0074(r31)

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	lwz		r27,  0x0068(r31)
	mr		r28, r19

KCSetAreaAccess_0x1a4
	mr		r8, r29
	lwz		r9, Area.AddressSpacePtr(r31)
	bl		MPCall_95_0x45c
	beq-	KCSetAreaAccess_0x1bc
	bl		MPCall_95_0x2e0
	bl		MPCall_95_0x348

KCSetAreaAccess_0x1bc
	add		r29, r29, r27
	subf.	r8, r29, r28
	bge+	KCSetAreaAccess_0x1a4
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	ARG		PTE r16, PTE r17, control r18
;	RET		PTE r16, PTE r17
;	CLOB	CR


major_0x10cb8

	rlwinm	r16, r16,  0, 0xFFFFFF87		;	fill these in again...
	rlwinm	r17, r17,  0, 0xFFFFFF1F		;	
	rlwinm	r16, r16,  0, 0xFFFFFFFC		;	
	rlwinm	r17, r17,  0, 0xFFFFFFF9		;	


	;	Load control argument into condition register
	;	Note: this is a pretty expensive operation, not in hot path

	mtcr	r18


	bge-	cr6, @80_not_set				;	if(control & 0x80) {
	ori		r17, r17, 0x80					;		PTE2 |= 0x80; //set referenced bit
	ori		r16, r16, 0x08					;		PTE1 |= 0x08; //set guard bit
@80_not_set									;	}


	ble-	cr6, @40_not_set				;	if(control & 0x40) {
	ori		r16, r16, 0x40					;		PTE1 |= 0x40; //set change bit
	b		@40_endif						;	} else {
@40_not_set
	ori		r17, r17, 0x20					;		PTE2 |= 0x20; //set W bit
@40_endif									;	}


	bne-	cr6, @20_not_set				;	if(control & 0x20) {
	ori		r17, r17,  0x40					;		PTE2 |= 0x40; //set change bit
	ori		r16, r16,  0x20					;		PTE1 |= 0x20; //set W bit
@20_not_set									;	}


	ble-	cr7, @04_not_set				;	if(control & 0x04) {
@04_not_set									;	}


	bge-	cr7, @08_not_set				;	if(control & 0x08) {
	ori		r17, r17, 0x06					;		PTE2 |= 0x06; //set leftmost protection bit and reserved bit
	ori		r16, r16, 0x01					;		PTE1 |= 0x01; //set rightmost protection bit
	b		@block_endif					;	}
@08_not_set
	bne-	cr7, @02_not_set				;	else if(control & 0x02) {
	ori		r17, r17, 0x00					;		PTE2 |= 0x00; //useless instruction?
	ori		r16, r16, 0x02					;		PTE1 |= 0x02; //set second protection bit
	b		@block_endif					;	}
@02_not_set
	bns-	cr7, @01_not_set				;	else if(control & 0x01) {
	ori		r17, r17, 0x04					;		PTE2 |= 0x04; //set reserved bit.
	ori		r16, r16, 0x03					;		PTE1 |= 0x03: //set both protection bits
	b		@block_endif					;	}
@01_not_set									;	else {
	ori		r17, r17, 0x02					;		PTE2 |= 0x02; //set second protection bit
	ori		r16, r16, 0x00					;		PTE1 |= 0x00; //useless instruction?
@block_endif								;	}


	ori		r16, r16,  0x10					;	PTE1 |= 0x10; //set M bit


	blr										;	return (PTE1, PTE2);



;	                     major_0x10d38

;	Xrefs:
;	convert_pmdts_to_areas
;	KCSetAreaAccess
;	MPCall_123

major_0x10d38	;	OUTSIDE REFERER
	andi.	r16, r17,  0x06
	li		r18,  0x00
	cmpwi	r16,  0x02
	cmpwi	cr1, r16,  0x06
	beq-	major_0x10d38_0x28
	li		r18,  0x04
	andi.	r16, r17,  0x04
	ori		r18, r18,  0x01
	bne-	major_0x10d38_0x28
	ori		r18, r18,  0x02

major_0x10d38_0x28
	bne-	cr1, major_0x10d38_0x30
	ori		r18, r18,  0x08

major_0x10d38_0x30
	andi.	r16, r17,  0x20
	bne-	major_0x10d38_0x3c
	ori		r18, r18,  0x40

major_0x10d38_0x3c
	andi.	r16, r17,  0x40
	beq-	major_0x10d38_0x48
	ori		r18, r18,  0x20

major_0x10d38_0x48
	andi.	r16, r17,  0x80
	beq-	major_0x10d38_0x54
	ori		r18, r18,  0x80

major_0x10d38_0x54
	blr

major_0x10d38_0x58	;	OUTSIDE REFERER
	andi.	r16, r17,  0x03
	li		r18,  0x04
	cmpwi	cr1, r16,  0x01
	beq-	major_0x10d38_0x78
	andi.	r16, r17,  0x01
	ori		r18, r18,  0x01
	bne-	major_0x10d38_0x78
	ori		r18, r18,  0x02

major_0x10d38_0x78
	bne-	cr1, major_0x10d38_0x80
	ori		r18, r18,  0x08

major_0x10d38_0x80
	andi.	r16, r17,  0x40
	beq-	major_0x10d38_0x8c
	ori		r18, r18,  0x40

major_0x10d38_0x8c
	andi.	r16, r17,  0x20
	beq-	major_0x10d38_0x98
	ori		r18, r18,  0x20

major_0x10d38_0x98
	andi.	r16, r17,  0x08
	beq-	major_0x10d38_0xa4
	ori		r18, r18,  0x80

major_0x10d38_0xa4
	blr



	DeclareMPCall	123, MPCall_123

MPCall_123	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	lwz		r18,  0x0020(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	rlwinm.	r8, r18,  0, 16, 16
	lwz		r5,  0x001c(r31)

;	r1 = kdp
	bne+	ReleaseAndReturnZeroFromMPCall

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348
	lwz		r17,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	bl		major_0x10d38
	mr		r5, r18

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	77, MPCall_77

MPCall_77	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mr.		r8, r4
	beq-	MPCall_77_0x40

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr

MPCall_77_0x40
	stw		r4,  0x0018(r31)
	stw		r5,  0x0084(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	78, MPCall_78

MPCall_78	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	cmpwi	r4,  0x01
	bne+	major_0x0b054
	cmplwi	r5,  0x00
	bne-	MPCall_78_0x68
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
	bne-	MPCall_78_0x9c
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
	bne-	MPCall_78_0xd0
	lwz		r16, Area.Length(r31)
	stw		r16,  0x0134(r6)
	lwz		r16, Area.Zero(r31)
	stw		r16,  0x013c(r6)
	lwz		r16,  0x0034(r31)
	stw		r16,  0x0144(r6)
	lwz		r16, Area.Length2(r31)
	stw		r16,  0x014c(r6)
	li		r16,  0x10
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_78_0xd0
	cmplwi	r5,  0x30
	bne-	MPCall_78_0xfc
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
	bne+	major_0x0b054
	li		r16,  0x00
	stw		r16,  0x0154(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	79, MPCall_79

MPCall_79	;	OUTSIDE REFERER
	mr.		r8, r3
	mfsprg	r28, 0
	lwz		r31, EWA.PA_CurAddressSpace(r28)
	beq-	MPCall_79_0x20

;	r8 = id
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne+	ReturnMPCallInvalidIDErr
	mr		r31, r8

MPCall_79_0x20
	lwz		r3, Area.ID(r31)

MPCall_79_0x24
	mr		r8, r4
	li		r9,  0x0b
	bl		GetNextIDOfClass
	cmpwi	r8,  0x00
	beq+	ReturnMPCallInvalidIDErr
	mr		r4, r8

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cgrp, 11:area, 12:not, 13:log

	lwz		r16,  0x0010(r8)
	cmpw	r16, r3
	bne+	MPCall_79_0x24
	b		ReturnZeroFromMPCall



	DeclareMPCall	80, MPCall_80

MPCall_80	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	mfsprg	r9, 0
	bne-	MPCall_80_0x2c
	lwz		r8, EWA.PA_CurAddressSpace(r9)
	b		MPCall_80_0x38

MPCall_80_0x2c
;	r8 = id
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr

MPCall_80_0x38
	mr		r9, r4
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	li		r5,  0x00
	cmplw	r16, r4
	bgt+	major_0x0b054
	lwz		r5,  0x0000(r8)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	125, MPCall_125

MPCall_125	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr.		r8, r3
	mfsprg	r9, 0
	bne-	MPCall_125_0x2c
	lwz		r8, EWA.PA_CurAddressSpace(r9)
	b		MPCall_125_0x38

MPCall_125_0x2c
;	r8 = id
 	bl		LookupID
	cmpwi	r9, AddressSpace.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr

MPCall_125_0x38
	mr		r9, r4
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	li		r5,  0x00
	cmplw	r16, r4
	bgt-	MPCall_125_0x58
	lwz		r8,  0x005c(r8)
	addi	r8, r8, -0x54

MPCall_125_0x58
	lwz		r9,  0x002c(r8)
	cmpwi	r9, noErr
	beq+	major_0x0b054
	lwz		r5,  0x0000(r8)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	81, MPCall_81

MPCall_81	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	lwz		r18,  0x0020(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	rlwinm.	r8, r18,  0, 16, 16
	lwz		r19,  0x0070(r31)
	beq-	MPCall_81_0x70
	lwz		r17, Area.Length2(r31)
	rlwinm	r19, r19,  0,  0, 19
	cmpwi	r17,  0x00
	subf	r18, r16, r4
	beq+	major_0x0b054
	add		r5, r18, r19

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_81_0x70
	li		r3,  0x00

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		MPCall_95_0x1e4
	bl		MPCall_95_0x2b0
	bns-	cr7, MPCall_81_0xc8
	mr		r5, r17
	rlwimi	r5, r4,  0, 20, 31

MPCall_81_0xa4
	_AssertAndRelease	PSA.HTABLock, scratch=r8
	b		ReleaseAndReturnMPCall

MPCall_81_0xc8
	li		r3, -0x7272
	b		MPCall_81_0xa4



	DeclareMPCall	98, MPCall_98

MPCall_98	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallInvalidIDErr
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	mr		r29, r5
	add		r5, r5, r4
	lwz		r18,  0x0020(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r20, Area.Length2(r31)
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r20,  0x00
	beq-	MPCall_98_0x84
	beq+	cr1, major_0x0b054
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
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	crclr	cr3_eq
	li		r3,  0x00
	bso-	cr7, MPCall_98_0xc4
	crset	cr3_eq
	li		r3, -0x7272

MPCall_98_0xc4
	rlwimi	r17, r4,  0, 20, 31
	rlwinm	r29, r17,  0,  0, 19
	stw		r17,  0x0134(r6)

MPCall_98_0xd0
	lwz		r16,  0x0068(r31)
	add		r28, r28, r16
	add		r29, r29, r16
	cmplw	cr2, r28, r5
	bgt-	cr2, MPCall_98_0x140
	mr		r8, r28
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	rlwinm	r17, r17,  0,  0, 19
	crxor	31, 31, 14
	bns-	cr7, MPCall_98_0x10c
	beq+	cr3, MPCall_98_0xd0
	cmplw	r29, r17
	beq+	MPCall_98_0xd0

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
	beq-	cr3, MPCall_98_0x170
	mr		r8, r28
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	rlwinm	r17, r17,  0,  0, 19
	bns-	cr7, MPCall_98_0x170
	cmplw	r29, r17
	bne-	MPCall_98_0x170
	subf	r16, r4, r5
	b		MPCall_98_0x118

MPCall_98_0x170
	lwz		r16,  0x007c(r31)
	and		r28, r28, r16
	cmplw	r5, r28
	bge-	MPCall_98_0x184
	mr		r28, r5

MPCall_98_0x184
	subf	r16, r4, r28
	b		MPCall_98_0x118



	DeclareMPCall	82, MPCall_82

MPCall_82	;	OUTSIDE REFERER
	lwz		r8, -0x0420(r1)
	cmpwi	r8,  0x00
	bne+	ReturnMPCallOOM

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	stw		r3, -0x0420(r1)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     MPCall_83

;	Xrefs:
;	kcMPDispatch
;	KCMapPage

	DeclareMPCall	83, MPCall_83

MPCall_83	;	OUTSIDE REFERER

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	bl		MPCall_83_0x90
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	mr.		r4, r8
	bne+	ReturnZeroFromMPCall

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17


MPCall_83_0x5c	;	OUTSIDE REFERER
	lwz		r8, -0x0420(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallOOM
	lwz		r8,  0x001c(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, EventGroup.kIDClass

	mr		r31, r8
	bne+	ReleaseAndReturnMPCallOOM
	lwz		r8,  0x0020(r31)
	bl		major_0x0d35c
	b		ReleaseAndReturnMPCallOOM

MPCall_83_0x90	;	OUTSIDE REFERER
	addi	r18, r1, -0x450
	lwz		r8, -0x0448(r1)
	cmpw	r8, r18
	beq-	MPCall_83_0xec
	lwz		r16,  0x0008(r8)
	lwz		r17,  0x000c(r8)
	stw		r16,  0x0008(r17)
	stw		r17,  0x000c(r16)
	li		r16,  0x00
	stw		r16,  0x0008(r8)
	stw		r16,  0x000c(r8)
	lwz		r16, -0x0430(r1)
	addi	r16, r16, -0x01
	stw		r16, -0x0430(r1)
	lwz		r17,  0x0004(r8)
	mfspr	r16, dec
	eqv.	r17, r18, r17
	stw		r16,  0x0000(r8)
	bne+	Local_Panic
	stw		r16,  0x0004(r8)
	stw		r16,  0x0008(r8)
	stw		r16,  0x000c(r8)
	blr

MPCall_83_0xec
	li		r8,  0x00
	blr



	DeclareMPCall	84, MPCall_84

MPCall_84	;	OUTSIDE REFERER

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16,  0x0004(r3)
	lwz		r17,  0x0000(r3)
	addi	r18, r1, -0x450
	eqv.	r16, r16, r17
	cmpw	cr1, r17, r18
	bne-	MPCall_84_0x3c
	bne-	cr1, MPCall_84_0x3c
	li		r3, -0x32
	b		MPCall_84_0x48

MPCall_84_0x3c
	mr		r8, r3

;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page
	li		r3,  0x00

MPCall_84_0x48
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	b		CommonMPCallReturnPath



;	                   free_list_add_page

;	Xrefs:
;	setup
;	MPCall_74
;	MPCall_75
;	MPCall_84
;	KCUnmapPages

;	> r1    = kdp
;	> r8    = maybe the page

free_list_add_page	;	OUTSIDE REFERER

	;	Must be an actual page-aligned address
	clrlwi.	r9, r8, 20
	addi	r9, r1, PSA.FreeList
	bne+	Local_Panic


	;	This is probably an alternative to heavyweight locks around the free list

	stw		r9, 0(r8)		;	store &parent in Freeform field

	InsertAsPrev	r8, r9, scratch=r16

	not		r9, r9
	stw		r9, 4(r8)		;	store ^&parent in Signature field


	lwz		r8, PSA.FreePageCount(r1)
	addi	r8, r8, 1
	stw		r8, PSA.FreePageCount(r1)

	blr



;	                   KCGetFreePageCount


	DeclareMPCall	100, KCGetFreePageCount

KCGetFreePageCount	;	OUTSIDE REFERER
	lwz		r3, PSA.FreePageCount(r1)
	b		CommonMPCallReturnPath



;	                KCGetUnheldFreePageCount


	DeclareMPCall	101, KCGetUnheldFreePageCount

KCGetUnheldFreePageCount	;	OUTSIDE REFERER
	lwz		r3, PSA.UnheldFreePageCount(r1)
	b		CommonMPCallReturnPath



;	                       KCMapPage


	DeclareMPCall	85, KCMapPage

KCMapPage	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.TwoFiftySix(r31)
	rlwinm.	r8, r16,  0, 28, 28
	bne+	major_0x0b054
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	lwz		r19,  0x0020(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	rlwinm.	r8, r19,  0, 16, 16
	cmplw	cr1, r4, r16
	lwz		r20, Area.Length2(r31)
	beq-	KCMapPage_0x8c
	bne+	cr1, major_0x0b054
	cmpwi	r20,  0x00
	lwz		r8,  0x0070(r31)
	bne+	ReleaseAndReturnMPCallOOM
	rlwimi	r8, r5,  0,  0, 19
	lwz		r18,  0x007c(r31)
	lwz		r20, Area.Length(r31)
	stw		r8,  0x0070(r31)
	stw		r20, Area.Length2(r31)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

KCMapPage_0x8c

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	lwz		r29,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	clrlwi.	r8, r29,  0x1f
	bne+	ReleaseAndReturnMPCallOOM
	lwz		r17,  0x0134(r6)
	rlwinm.	r8, r17,  0, 30, 30
	bne-	KCMapPage_0x12c

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	bl		MPCall_83_0x90
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	mr.		r5, r8
	beq+	MPCall_83_0x5c

KCMapPage_0x12c
	lwz		r17,  0x0134(r6)
	rlwinm.	r8, r17,  0, 29, 29
	beq-	KCMapPage_0x17c
	rlwinm.	r8, r29,  0, 25, 25
	lwz		r18,  0x0068(r31)

KCMapPage_0x140
	addi	r18, r18, -0x20
	bne-	KCMapPage_0x174
	dcbst	r18, r5

KCMapPage_0x14c
	cmpwi	cr1, r18,  0x00
	bgt+	cr1, KCMapPage_0x140
	sync
	lwz		r18,  0x0068(r31)

KCMapPage_0x15c
	addi	r18, r18, -0x20
	icbi	r18, r5
	cmpwi	cr1, r18,  0x00
	bgt+	cr1, KCMapPage_0x15c
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
	lwz		r17, Area.Length2(r31)
	stw		r29,  0x0000(r30)
	add		r17, r17, r18
	stw		r17, Area.Length2(r31)
	lwz		r17,  0x0134(r6)
	clrlwi.	r8, r17,  0x1f

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	lwz		r5,  0x0068(r31)
	b		KCHoldPages_0x2c



;	                      KCUnmapPages


	DeclareMPCall	86, KCUnmapPages

KCUnmapPages	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r8,  0x0134(r6)
	lwz		r16, Area.TwoFiftySix(r31)
	rlwinm.	r16, r16,  0, 28, 28
	bne+	major_0x0b054
	clrlwi.	r8, r8,  0x1f
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	lwz		r19,  0x0020(r31)
	crmove	14, 2
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r29,  0x0068(r31)
	lwz		r20, Area.Length2(r31)
	rlwinm.	r8, r19,  0, 16, 16
	cmplw	cr1, r4, r16
	beq-	KCUnmapPages_0xd8
	bne+	cr1, major_0x0b054
	cmpwi	r20,  0x00
	li		r20,  0x00
	ble+	ReleaseAndReturnMPCallOOM
	stw		r20, Area.Length2(r31)

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	li		r30,  0x00

KCUnmapPages_0xac
	mr		r8, r4
	lwz		r9, Area.AddressSpacePtr(r31)
	bl		MPCall_95_0x45c
	beq-	KCUnmapPages_0xc4
	bl		MPCall_95_0x2e0
	bl		MPCall_95_0x348

KCUnmapPages_0xc4
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge+	KCUnmapPages_0xac
	crclr	cr3_eq
	b		KCUnmapPages_0x158

KCUnmapPages_0xd8
	bne-	cr3, KCUnmapPages_0xf4

	_Lock			PSA.PoolLock, scratch1=r14, scratch2=r15


KCUnmapPages_0xf4

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	lwz		r28, Area.Length2(r31)

KCUnmapPages_0x110
	mr		r8, r4
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bns-	cr7, KCUnmapPages_0x148
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348
	lwz		r18,  0x0000(r30)
	subf	r28, r29, r28
	rlwinm	r18, r18,  0,  0, 30
	stw		r18,  0x0000(r30)
	bne-	cr3, KCUnmapPages_0x148
	rlwinm	r8, r18,  0,  0, 19

;	r1 = kdp
;	r8 = maybe the page
	bl		free_list_add_page

KCUnmapPages_0x148
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge+	KCUnmapPages_0x110
	stw		r28, Area.Length2(r31)

KCUnmapPages_0x158
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	bne+	cr3, ReleaseAndReturnZeroFromMPCall
	_AssertAndRelease	PSA.PoolLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	               KCMakePhysicallyContiguous


	DeclareMPCall	127, KCMakePhysicallyContiguous

KCMakePhysicallyContiguous	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mr		r27, r5
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne+	major_0x0b054

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r27, r4
	li		r28, -0x01

NKMakePhysicallyContiguous_0x80
	mr		r8, r27
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bns-	cr7, NKMakePhysicallyContiguous_0x150
	rlwinm	r8, r17,  0,  0, 19
	cmpwi	r28, -0x01
	cmpw	cr1, r28, r8
	mr		r28, r8
	beq-	NKMakePhysicallyContiguous_0xac
	bne-	cr1, NKMakePhysicallyContiguous_0xe0

NKMakePhysicallyContiguous_0xac
	add		r27, r27, r29
	add		r28, r28, r29
	subf.	r8, r27, r5
	bge+	NKMakePhysicallyContiguous_0x80
	_AssertAndRelease	PSA.HTABLock, scratch=r14

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

NKMakePhysicallyContiguous_0xe0
	_AssertAndRelease	PSA.HTABLock, scratch=r14

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	addi	r18, r1, -0x450
	lwz		r8, -0x0448(r1)
	cmpw	r8, r18
	beq-	NKMakePhysicallyContiguous_0x174
	b		NKMakePhysicallyContiguous_0x174
	dc.l	0x7c0004ac				;	probably dead code, not a jump table
	dc.l	0x8201f530
	dc.l	0x2c900000
	dc.l	0x3a000000
	dc.l	0x40a6000c
	dc.l	0x7e0802a6
	dc.l	0x48005905
	dc.l	0x9201f530
	dc.l	0x4bff9554

NKMakePhysicallyContiguous_0x150
	_AssertAndRelease	PSA.HTABLock, scratch=r16
	b		ReleaseAndReturnMPCallOOM

NKMakePhysicallyContiguous_0x174
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	b		ReleaseAndReturnMPCallOOM



;	                      KCLockPages


	DeclareMPCall	87, KCLockPages

KCLockPages	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	mr		r27, r5
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne+	major_0x0b054
	mr		r27, r4
	li		r28,  0x00

KCLockPages_0x68
	mr		r8, r27
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	rlwinm	r17, r18, 24, 25, 31
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0x7f
	addi	r28, r28,  0x01
	beq-	KCLockPages_0x94
	addi	r28, r28, -0x01
	bge+	cr1, major_0x0b0cc

KCLockPages_0x94
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge+	KCLockPages_0x68

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	subf.	r16, r28, r16
	ble-	KCLockPages_0xc8
	stw		r16, PSA.UnheldFreePageCount(r1)

KCLockPages_0xc8
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	ble+	ReleaseAndReturnMPCallOOM
	mr		r27, r4

KCLockPages_0xf0
	mr		r8, r27
	bl		MPCall_95_0x254
	beq+	Local_Panic
	lhz		r18,  0x0000(r30)
	rlwinm.	r17, r18,  0, 16, 16
	bne-	KCLockPages_0x10c
	li		r18, -0x8000

KCLockPages_0x10c
	rlwinm	r17, r18, 24, 25, 31
	addi	r17, r17,  0x01
	rlwimi	r18, r17,  8, 17, 23
	sth		r18,  0x0000(r30)
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge+	KCLockPages_0xf0

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     KCUnlockPages


	DeclareMPCall	88, KCUnlockPages

KCUnlockPages	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne+	major_0x0b054
	mr		r27, r4

KCUnlockPages_0x60
	mr		r8, r27
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	rlwinm	r17, r18, 24, 25, 31
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0x00
	beq+	major_0x0b0cc
	addi	r28, r28,  0x01
	beq+	cr1, major_0x0b0cc
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge+	KCUnlockPages_0x60
	li		r28,  0x00

KCUnlockPages_0x98
	mr		r8, r4
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	rlwinm	r17, r18, 24, 25, 31
	addi	r17, r17, -0x01
	rlwimi	r18, r17,  8, 17, 23
	clrlwi.	r8, r18,  0x11
	bne-	KCUnlockPages_0xc4
	rlwinm	r18, r18,  0, 17, 15
	addi	r28, r28,  0x01

KCUnlockPages_0xc4
	sth		r18,  0x0000(r30)
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge+	KCUnlockPages_0x98

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	add		r16, r16, r28
	stw		r16, PSA.UnheldFreePageCount(r1)
	_AssertAndRelease	PSA.PoolLock, scratch=r16

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                      KCHoldPages


;	Xrefs:
;	kcMPDispatch
;	KCMapPage

	DeclareMPCall	89, KCHoldPages

KCHoldPages	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8

KCHoldPages_0x2c	;	OUTSIDE REFERER
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne+	major_0x0b054
	mr		r27, r4
	li		r28,  0x00

KCHoldPages_0x64
	mr		r8, r27
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	clrlwi	r17, r18,  0x18
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0xff
	addi	r28, r28,  0x01
	beq-	KCHoldPages_0x90
	addi	r28, r28, -0x01
	bge+	cr1, major_0x0b0cc

KCHoldPages_0x90
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge+	KCHoldPages_0x64

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	subf.	r16, r28, r16
	ble-	KCHoldPages_0xc4
	stw		r16, PSA.UnheldFreePageCount(r1)

KCHoldPages_0xc4
	_AssertAndRelease	PSA.PoolLock, scratch=r16
	ble+	ReleaseAndReturnMPCallOOM
	mr		r27, r4

KCHoldPages_0xec
	mr		r8, r27
	bl		MPCall_95_0x254
	beq+	Local_Panic
	lhz		r18,  0x0000(r30)
	rlwinm.	r17, r18,  0, 16, 16
	bne-	KCHoldPages_0x108
	li		r18, -0x8000

KCHoldPages_0x108
	clrlwi	r17, r18,  0x18
	addi	r17, r17,  0x01
	rlwimi	r18, r17,  0, 24, 31
	sth		r18,  0x0000(r30)
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge+	KCHoldPages_0xec

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     KCUnholdPages


	DeclareMPCall	90, KCUnholdPages

KCUnholdPages	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	add		r5, r5, r4
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	addi	r5, r5, -0x01
	cmplw	r4, r16
	cmplw	cr1, r5, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	lwz		r19,  0x0020(r31)
	lwz		r29,  0x0068(r31)
	rlwinm.	r8, r19,  0, 16, 16
	bne+	major_0x0b054
	mr		r27, r4

KCUnholdPages_0x60
	mr		r8, r27
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	clrlwi	r17, r18,  0x18
	rlwinm.	r8, r18,  0, 16, 16
	cmpwi	cr1, r17,  0x00
	beq+	major_0x0b0cc
	addi	r28, r28,  0x01
	beq+	cr1, major_0x0b0cc
	add		r27, r27, r29
	subf.	r8, r27, r5
	bge+	KCUnholdPages_0x60
	li		r28,  0x00

KCUnholdPages_0x98
	mr		r8, r4
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	clrlwi	r17, r18,  0x18
	addi	r17, r17, -0x01
	rlwimi	r18, r17,  0, 24, 31
	clrlwi.	r8, r18,  0x11
	bne-	KCUnholdPages_0xc4
	rlwinm	r18, r18,  0, 17, 15
	addi	r28, r28,  0x01

KCUnholdPages_0xc4
	sth		r18,  0x0000(r30)
	add		r4, r4, r29
	subf.	r8, r4, r5
	bge+	KCUnholdPages_0x98

	_Lock			PSA.PoolLock, scratch1=r16, scratch2=r17

	lwz		r16, PSA.UnheldFreePageCount(r1)
	add		r16, r16, r28
	stw		r16, PSA.UnheldFreePageCount(r1)
	_AssertAndRelease	PSA.PoolLock, scratch=r16

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	91, MPCall_91

MPCall_91	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		MPCall_95_0x1e4
	beq-	MPCall_91_0xcc
	bl		MPCall_95_0x2b0
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348
	lwz		r29,  0x0000(r30)
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	mr		r8, r4
	bl		MPCall_95_0x254
	li		r19,  0x00
	beq-	MPCall_91_0xac
	lhz		r19,  0x0000(r30)

MPCall_91_0xac
	andi.	r5, r29,  0x319
	rlwinm.	r8, r19,  0, 16, 16
	rlwimi	r5, r19,  0, 16, 16

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	rlwinm.	r8, r19,  0, 17, 23

;	r1 = kdp
	beq+	ReleaseAndReturnZeroFromMPCall
	ori		r5, r5,  0x4000

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_91_0xcc
	_AssertAndRelease	PSA.HTABLock, scratch=r14
	b		ReleaseAndReturnMPCallOOM



	DeclareMPCall	92, MPCall_92

MPCall_92	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.TwoFiftySix(r31)
	rlwinm.	r8, r16,  0, 28, 28
	bne+	major_0x0b054
	lwz		r29,  0x0134(r6)
	li		r8,  0x318
	andc.	r9, r5, r8
	bne+	major_0x0b054
	andc.	r9, r29, r8
	bne+	major_0x0b054
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054

	_Lock			PSA.HTABLock, scratch1=r14, scratch2=r15

	mr		r8, r4
	bl		MPCall_95_0x1e4
	beq-	MPCall_92_0xd8
	bl		MPCall_95_0x2b0
	bns-	cr7, MPCall_92_0x9c
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348

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



	DeclareMPCall	93, MPCall_93

MPCall_93	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	mr		r8, r4
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	rlwinm.	r8, r18,  0, 16, 16
	li		r5,  0x00

;	r1 = kdp
	bne+	ReleaseAndReturnZeroFromMPCall
	clrlwi	r5, r18,  0x11

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	94, MPCall_94

MPCall_94	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	mr		r8, r4
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	cmplwi	r5,  0x7fff
	bgt+	major_0x0b054
	lhz		r18,  0x0000(r30)
	rlwinm.	r8, r18,  0, 16, 16
	bne+	ReleaseAndReturnMPCallOOM
	rlwimi	r18, r5,  0, 17, 31
	sth		r18,  0x0000(r30)

	_Lock			PSA.HTABLock, scratch1=r16, scratch2=r17

	mr		r8, r4
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	bl		MPCall_95_0x2b0
	bns-	cr7, MPCall_94_0xa0
	bltl-	cr5, MPCall_95_0x2e0
	bltl-	cr5, MPCall_95_0x348

MPCall_94_0xa0
	_AssertAndRelease	PSA.HTABLock, scratch=r16

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



	DeclareMPCall	129, MPCall_129

MPCall_129	;	OUTSIDE REFERER

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	mr		r8, r3

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Area.kIDClass

	bne+	ReleaseAndReturnMPCallInvalidIDErr
	mr		r31, r8
	lwz		r16, Area.LogicalBase(r31)
	lwz		r17, Area.LogicalBase2(r31)
	cmplw	r4, r16
	cmplw	cr1, r4, r17
	blt+	major_0x0b054
	bgt+	cr1, major_0x0b054
	mr		r8, r4
	bl		MPCall_95_0x254
	beq+	major_0x0b054
	lhz		r18,  0x0000(r30)
	li		r5,  0x00
	rlwinm.	r8, r18,  0, 16, 16
	li		r16,  0x00
	beq-	MPCall_129_0x6c
	rlwinm	r16, r18, 24, 25, 31
	clrlwi	r5, r18,  0x18

MPCall_129_0x6c
	stw		r16,  0x0134(r6)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall



;	                     MPCall_95

;	Xrefs:
;	major_0x03324
;	IntDSIOtherOther
;	PagingFunc1
;	kcMPDispatch
;	NKxprintf
;	MPCall_115
;	MPCall_75
;	MPCall_130
;	KCSetAreaAccess
;	MPCall_123
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

	DeclareMPCall	95, MPCall_95

MPCall_95	;	OUTSIDE REFERER
	or.		r8, r3, r4
	bne-	MPCall_95_0x44
	li		r16,  0x00
	stw		r16,  0x06b4(r1)
	_log	'Areas capability probe detected^n'
	b		ReturnParamErrFromMPCall

MPCall_95_0x44

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	li		r28, -0x01
	li		r4,  0x00
	li		r5,  0x00
	lwz		r8, PSA.UnheldFreePageCount(r1)
	cmpwi	r8,  0x00
	ble+	ReleaseAndReturnMPCallOOM
	lwz		r27, -0x0438(r1)
	srwi	r27, r27, 15
	mfspr	r8, dec
	subf	r27, r27, r8
	lwz		r8, -0x03f8(r1)
	lwz		r9, -0x03f4(r1)
	mr		r30, r9
	bl		FindAreaAbove
	mr		r31, r8
	lwz		r29, Area.LogicalBase(r31)
	cmplw	r29, r30
	bgt-	MPCall_95_0xa8
	mr		r29, r30

MPCall_95_0xa8
	crset	cr2_eq

MPCall_95_0xac
	mfspr	r9, dec
	subf.	r9, r27, r9
	blt-	MPCall_95_0x1c8

MPCall_95_0xb8
	lwz		r8,  0x0020(r31)
	lwz		r9,  0x0018(r31)
	rlwinm.	r8, r8,  0, 16, 16
	cmpwi	cr1, r3,  0x00
	bne-	MPCall_95_0x19c
	beq-	cr1, MPCall_95_0xe0
	cmpwi	cr3, r9,  0x00
	beq-	cr3, MPCall_95_0xe0
	cmpw	cr1, r9, r3
	bne-	cr1, MPCall_95_0x19c

MPCall_95_0xe0
	lwz		r9, Area.TwoFiftySix(r31)
	rlwinm.	r8, r9,  0, 28, 28
	bne-	MPCall_95_0x19c
	rlwinm.	r8, r9,  0, 23, 23
	bne-	MPCall_95_0x19c

	_Lock			PSA.HTABLock, scratch1=r16, scratch2=r17

	mr		r8, r29
	bl		MPCall_95_0x1e4
	beq+	Local_Panic
	_AssertAndRelease	PSA.HTABLock, scratch=r16
	lwz		r16,  0x0000(r30)
	clrlwi.	r8, r16,  0x1f
	beq-	MPCall_95_0x180
	mr		r8, r29
	bl		MPCall_95_0x254
	beq-	MPCall_95_0x1c8
	lhz		r17,  0x0000(r30)
	rlwinm.	r8, r17,  0, 16, 16
	clrlwi	r17, r17,  0x11
	bne-	MPCall_95_0x180
	cmpw	r17, r28
	crclr	cr2_eq
	ble-	MPCall_95_0x180
	mr		r28, r17
	lwz		r4, Area.ID(r31)
	cmplwi	r17,  0x7fff
	mr		r5, r29
	bge-	MPCall_95_0x1c8

MPCall_95_0x180
	lwz		r8,  0x0068(r31)
	lwz		r9, Area.LogicalBase2(r31)
	add		r29, r29, r8
	subf.	r9, r9, r29
	bge-	MPCall_95_0x19c
	bne+	cr2, MPCall_95_0xac
	b		MPCall_95_0xb8

MPCall_95_0x19c
	lwz		r8,  0x0054(r31)
	lwz		r9,  0x005c(r31)
	cmpw	r8, r9
	addi	r31, r9, -0x54
	lwz		r29, Area.LogicalBase(r31)
	bne-	MPCall_95_0x1c0
	lwz		r9,  0x0008(r8)
	addi	r31, r9, -0x54
	lwz		r29, Area.LogicalBase(r31)

MPCall_95_0x1c0
	bne+	cr2, MPCall_95_0xac
	b		MPCall_95_0xb8

MPCall_95_0x1c8
	cmpwi	r4,  0x00
	stw		r29, -0x03f4(r1)
	beq+	ReleaseAndReturnMPCallOOM
	lwz		r8,  0x0068(r31)
	add		r8, r8, r5
	stw		r8, -0x03f4(r1)

;	r1 = kdp
	b		ReleaseAndReturnZeroFromMPCall

MPCall_95_0x1e4	;	OUTSIDE REFERER
	lwz		r16, Area.LogicalBase(r31)
	lwz		r18, Area.TwoFiftySix(r31)
	lwz		r30,  0x0040(r31)
	subf	r17, r16, r8
	cmpwi	r30,  0x00
	rlwinm	r17, r17, 22, 10, 29
	beqlr-
	rlwinm.	r16, r18,  0, 26, 26
	rlwinm	r16, r17, 22, 20, 29
	beq-	MPCall_95_0x214
	rlwinm	r17, r17,  0, 20, 29
	lwzx	r30, r30, r16

MPCall_95_0x214
	add.	r30, r30, r17
	blr

	dc.l	0x821f0024	;	again, probably just dead code
	dc.l	0x825f0008
	dc.l	0x83df0040
	dc.l	0x56510739
	dc.l	0x7e304050
	dc.l	0x4182ffc4
	dc.l	0x83df0044
	dc.l	0x825f0080
	dc.l	0x3bdeffbc
	dc.l	0x7e304050
	dc.l	0x7e319214
	dc.l	0x825e0008
	dc.l	0x83de0040
	dc.l	0x4bffffa4

MPCall_95_0x254	;	OUTSIDE REFERER
	lwz		r16, Area.LogicalBase(r31)
	lwz		r18, Area.TwoFiftySix(r31)
	lwz		r30,  0x003c(r31)
	rlwinm.	r17, r18,  0, 28, 28
	subf	r17, r16, r8
	beq-	MPCall_95_0x288
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
	beqlr-
	rlwinm.	r16, r18,  0, 30, 30
	rlwinm	r16, r17, 22, 20, 29
	beq-	MPCall_95_0x2a8
	rlwinm	r17, r17,  0, 20, 30
	lwzx	r30, r30, r16

MPCall_95_0x2a8
	add.	r30, r30, r17
	blr

MPCall_95_0x2b0	;	OUTSIDE REFERER
	lwz		r19,  0x0000(r30)
	lwz		r18,  0x06a4(r1)
	mtcrf	 0x07, r19
	rlwinm	r17, r19,  0,  0, 19
	rlwinm	r16, r19, 23,  9, 28
	bnslr-	cr7
	bgelr-	cr5
	lwzux	r16, r18, r16
	lwz		r17,  0x0004(r18)
	mtcrf	 0x80, r16
	bge+	Local_Panic
	blr

MPCall_95_0x2e0	;	OUTSIDE REFERER
	mfspr	r14, pvr
	clrlwi	r16, r16,  0x01
	rlwinm.	r14, r14,  0,  0, 14
	stw		r16,  0x0000(r18)
	sync
	tlbie	r8
	beq-	MPCall_95_0x304
	sync
	tlbsync

MPCall_95_0x304
	sync
	isync
	cmpwi	r30,  0x00
	lwz		r14,  0x0000(r30)
	lwz		r17,  0x0004(r18)
	oris	r16, r16,  0x8000
	beqlr-
	rlwimi	r14, r17, 29, 27, 27
	rlwimi	r14, r17, 27, 28, 28
	mtcrf	 0x07, r14
	stw		r14,  0x0000(r30)
	blr

MPCall_95_0x334
	stw		r17,  0x0004(r18)
	eieio
	stw		r16,  0x0000(r18)
	sync
	blr

MPCall_95_0x348	;	OUTSIDE REFERER
	lwz		r14,  0x0000(r30)
	li		r16, -0x01
	stw		r16,  0x0340(r1)
	stw		r16,  0x0348(r1)
	stw		r16,  0x0350(r1)
	stw		r16,  0x0358(r1)
	lwz		r16,  0x0e98(r1)
	rlwinm	r14, r14,  0, 21, 19
	addi	r16, r16,  0x01
	stw		r16,  0x0e98(r1)
	rlwimi	r14, r17,  0,  0, 19
	cmpwi	r30,  0x00
	li		r16,  0x00
	li		r17,  0x00
	beq+	MPCall_95_0x334
	stw		r14,  0x0000(r30)
	b		MPCall_95_0x334

V2P	;	OUTSIDE REFERER
	mr.		r19, r9
	mfsprg	r17, 0
	bne-	MPCall_95_0x39c
	lwz		r19, EWA.PA_CurAddressSpace(r17)

MPCall_95_0x39c
	addi	r18, r19,  0x80
	lwz		r16,  0x0000(r18)
	li		r19, -0x01
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	beq-	MPCall_95_0x444
	lwzu	r16,  0x0008(r18)
	rlwimi	r19, r16, 15,  0, 14
	xor		r17, r8, r16
	andc.	r17, r17, r19
	bne-	MPCall_95_0x45c

MPCall_95_0x444
	andi.	r17, r16,  0x01
	rlwinm	r19, r19,  0,  8, 19
	lwzu	r17,  0x0004(r18)
	and		r19, r8, r19
	or		r17, r17, r19
	bnelr-

MPCall_95_0x45c	;	OUTSIDE REFERER
	cmpwi	r9, noErr
	addi	r16, r9,  0x30
	beq-	MPCall_95_0x474
	rlwinm	r17, r8,  6, 26, 29
	lwzx	r17, r16, r17
	b		MPCall_95_0x478

MPCall_95_0x474
	mfsrin	r17, r8

MPCall_95_0x478
	rlwinm	r16, r8, 10, 26, 31
	rlwimi	r16, r17,  7,  1, 24
	rlwinm	r9, r8, 26, 10, 25
	oris	r16, r16,  0x8000
	rlwinm	r17, r17,  6,  7, 25
	xor		r9, r9, r17
	lwz		r17,  0x06a0(r1)
	lwz		r18,  0x06a4(r1)
	and		r9, r9, r17
	or.		r18, r18, r9

MPCall_95_0x4a0
	lwz		r17,  0x0000(r18)
	lwz		r9,  0x0008(r18)
	cmpw	cr6, r16, r17
	lwz		r17,  0x0010(r18)
	cmpw	cr7, r16, r9
	lwzu	r9,  0x0018(r18)
	bne-	cr6, MPCall_95_0x4c4

MPCall_95_0x4bc
	lwzu	r17, -0x0014(r18)
	blr

MPCall_95_0x4c4
	cmpw	cr6, r16, r17
	lwzu	r17,  0x0008(r18)
	beq+	cr7, MPCall_95_0x4bc
	cmpw	cr7, r16, r9
	lwzu	r9,  0x0008(r18)
	beq+	cr6, MPCall_95_0x4bc
	cmpw	cr6, r16, r17
	lwzu	r17,  0x0008(r18)
	beq+	cr7, MPCall_95_0x4bc
	cmpw	cr7, r16, r9
	lwzu	r9,  0x0008(r18)
	beq+	cr6, MPCall_95_0x4bc
	cmpw	cr6, r16, r17
	lwzu	r17, -0x000c(r18)
	beqlr-	cr7
	cmpw	cr7, r16, r9
	lwzu	r17,  0x0008(r18)
	beqlr-	cr6
	lwzu	r17,  0x0008(r18)
	beqlr-	cr7
	lwz		r17,  0x06a0(r1)
	xori	r16, r16,  0x40
	andi.	r9, r16,  0x40
	addi	r18, r18, -0x3c
	xor		r18, r18, r17
	bne+	MPCall_95_0x4a0
	blr
