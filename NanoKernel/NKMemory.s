;	AUTO-GENERATED SYMBOL LIST

########################################################################
########################################################################

PutPTE ; EA r27 // PTE r30/r31, EQ=Success, GT=Invalid, LT=Fault
	lwz		r29, KDP.CurMap.SegMapPtr(r1)	; late addition: r29 used to be an argument
	rlwinm	r28, r27, 7, 0x0000000F << 3	; convert segment of passed ptr to offset into SegMap
	lwzx	r29, r29, r28					; r29 = ptr to start of segment in PageMap		
	rlwinm	r28, r27, 20, 0x0000FFFF		; r27 = page index within SegMap
	lhz		r30, PME.LBase(r29)
	b		@find_pme

@try_next_pme						; Point r29 to the PageMapEntry that concerns this page
	lhzu	r30, 8(r29)						; get another PME.LBase
@find_pme
	lhz		r31, PME.PageCount(r29)
	subf	r30, r30, r28					; r30 = page index within area
	cmplw	cr7, r30, r31
	bgt		cr7, @try_next_pme

	lwz		r28, KDP.HtabTempEntryPtr(r1)	; (remove temp PTE if present)
	lwz		r31, PME.PBaseAndFlags(r29)
	cmpwi	cr7, r28, 0						; (remove temp PTE if present)
	extlwi.	r26, r31, 2, 20					; DaddyFlag and CountingFlag in top bits
	bne		cr7, @remove_temp_pte			; (remove temp PTE if present)
	blt		@daddy_flag						; >>>>> DaddyFlag = 1
@return_remove_temp_pte						; (optimized: if LT then to jumps to @daddy_flag)
	bgt		@create_temp_pte				; >>>>> DaddyFlag = 0, CountingFlag = 1
	;	fallthru							; >>>>> DaddyFlag = 0, CountingFlag = 0

########################################################################
; CODE TO CREATE A PAGE TABLE ENTRY
									; <<<<< Fallthru from main entry point (top two flags of PME are zero)
	slwi	r28, r30, 12
	add		r31, r31, r28					; r31 = physical page ptr plus 12 bits of PageMapEntry flags

@return_daddy_flag					; <<<<< @daddy_flag comes here
@return_create_temp_pte				; <<<<< @create_temp_pte comes here (r31=pageptr, r26=0x5A5A)
	mfsrin	r30, r27				; HASH FUNCTION: get address of PTEG
	rlwinm	r28, r27, 26, 10, 25			; r28 = (1st arg of XOR) * 64b
	rlwinm	r30, r30, 6, 7, 25				; r30 = (2nd arg of XOR) * 64b
	xor		r28, r28, r30					; r28 (hash output * 64b) = r28 ^ r30
	lwz		r30, KDP.PTEGMask(r1)
	lwz		r29, KDP.HTABORG(r1)
	and		r28, r28, r30
	or.		r29, r29, r28					; result (PTEG address) into r29

@retry_other_pteg					; <<<<< @no_blanks_in_pteg can return here after doing sec'dary hash
	lwz		r30, 0(r29)				; Take address of PTEG in r29, find empty/"invalid" PTE within (optimized!)
	lwz		r28, 8(r29)
	cmpwi	cr6, r30, 0
	lwz		r30, 16(r29)
	cmpwi	cr7, r28, 0
	lwzu	r28, 24(r29)
	bge		cr6, @found_blank_pte
	cmpwi	cr6, r30, 0
	lwzu	r30, 8(r29)
	bge		cr7, @found_blank_pte
	cmpwi	cr7, r28, 0
	lwzu	r28, 8(r29)
	bge		cr6, @found_blank_pte
	cmpwi	cr6, r30, 0
	lwzu	r30, 8(r29)
	bge		cr7, @found_blank_pte
	cmpwi	cr7, r28, 0
	lwzu	r28, 8(r29)
	bge		cr6, @found_blank_pte
	cmpwi	cr6, r30, 0
	addi	r29, r29, 8
	bge		cr7, @found_blank_pte
	cmpwi	cr7, r28, 0
	addi	r29, r29, 8
	bge		cr6, @found_blank_pte
	rlwinm	r28, r31, 0, 26, 26				; wImg bit in PTE???
	addi	r29, r29, 8						; Leave PTE + 24 in r29
	blt		cr7, @no_blanks_in_pteg			; >>>>> This might cause PutPTE to return an error (BNE)

@found_blank_pte					; Take PTE address (plus 24) in r29, draft PTE[lo] in r31
	cmpwi	r26, 0							; NOTE: top bit of r31 will be set if sec'dary hash func was used
	mfsrin	r28, r27
	extrwi	r30, r27, 6, 4					; PTE[API/26-31] taken from upper 6 bits of offset-within-segment
	stw		r27, KDP.HtabLastEA(r1)
	ori		r31, r31, 0x100					; set PTE[R(eference)]
	rlwimi	r30, r31, 27, 25, 25			; set PTE[H(ash func ID)] to cheeky topmost bit of the phys addr in r31
	rlwinm	r31, r31, 0, 21, 19				; unset upper reserved bit in PTE[lo]
	insrwi	r30, r28, 24, 1					; get PTE[VSID] from segment register
	stw		r31, -20(r29)					; PTE[lo] = r31
	oris	r30, r30, 0x8000				; set PTE[V(alid)]
	sync									; because we just wanged the page table
	stwu	r30, -24(r29)					; PTE[hi] = r30

	lwz		r28, KDP.NKInfo.HashTableCreateCount(r1)
	stw		r29, KDP.ApproxCurrentPTEG(r1)
	addi	r28, r28, 1
	stw		r28, KDP.NKInfo.HashTableCreateCount(r1)
	beqlr									; >>>>> RETURN "BEQ" if we got to "Case 1" directly

	cmpwi	r26, 0x5A5A				; Special value set so that we take note of this new temporary PTE?
	bne		@notemp
	stw		r29, KDP.HtabTempEntryPtr(r1)
	cmpw	r29, r29						; >>>>> RETURN "BEQ" if we got to "Case 1" via @create_temp_pte
	blr
@notemp

	lwz		r28, 0(r26)				; Otherwise, we got here via @daddy_flag? Looks nonsensical.
	lwz		r30, KDP.HTABORG(r1)
	ori		r28, r28, 0x801
	subf	r30, r30, r29
	cmpw	r29, r29
	rlwimi	r28, r30, 9, 0, 19
	stw		r28, 0(r26)
	blr										; >>>>> RETURN "BEQ" otherwise

########################################################################
; Helpful code that jumps back to roughly where it started
@remove_temp_pte
	lwz		r28, KDP.NKInfo.HashTableDeleteCount(r1)
	lwz		r29, KDP.HtabTempEntryPtr(r1)
	addi	r28, r28, 1
	stw		r28, KDP.NKInfo.HashTableDeleteCount(r1)
	li		r28, 0
	stw		r28, 0(r29)
	lwz		r29, KDP.HtabTempPage(r1)
	stw		r28, KDP.HtabTempPage(r1)
	stw		r28, KDP.HtabTempEntryPtr(r1)
	sync
	tlbie	r29
	sync
	bge		@return_remove_temp_pte		; Optimization: would otherwise branch to a "blt @daddy_flag"

########################################################################
; r30 = page index within area, r31 = PBaseAndFlags
@daddy_flag
	extlwi.	r28, r31, 2, 21					; top bits of r28 = CountingFlag, PhysicalIsRelativeFlag
	bge		@return_via_pf2					; if !CountingFlag: return (if !PIRFlag: via PF2)

	rlwinm	r28, r30, 2, 0xFFFFFFFC			; r28 = pageIdxInArea * 4
	rlwinm	r26, r31, 22, 0xFFFFFFFC		; r26 = PIRFlag << 31 | BtmBit << 22 | physBase * 4
	lwzux	r28, r26, r28					; this makes no sense!!

	lwz		r31, KDP.PageAttributeInit(r1)
	andi.	r30, r28, 0x881
	rlwimi	r31, r28, 0, 0xFFFFF000
	cmplwi	r30, 1
	cmplwi	cr7, r30, 0x81
	ori		r31, r31, 0x100
	rlwimi	r31, r28, 3, 24, 24
	rlwimi	r31, r28, 31, 26, 26
	rlwimi	r31, r28, 1, 25, 25
	xori	r31, r31, 0x40
	rlwimi	r31, r28, 30, 31, 31
	beq		@return_daddy_flag
	bltlr	cr7
	bl		SystemCrash

########################################################################
; Helpful code that jumps back to roughly where it started
@create_temp_pte					; Make "temp" PageMapEntry, when flags look like 0x800
	ori		r28, r27, 0xfff			; r27 = passed ptr, r31 = PBaseAndFlags
	stw		r28, KDP.HtabTempPage(r1)
	rlwinm	r31, r31, 0, 22, 19				; clear CountingFlag in r31
	li		r26, 0x5A5A						; set magic number in r26 so that KDP.HtabTempEntryPtr gets set
	b		@return_create_temp_pte

########################################################################
; Helpful return code for @daddy_flag
@return_via_pf2
	bgtlr
	addi	r29, r1, KDP.SupervisorMap
	b		SetMap

########################################################################
; So try the secondary hashing function, if we haven't already
@no_blanks_in_pteg
	cmplw	cr6, r28, r26
	subi	r29, r29, 64 + 16
	ble		cr6, @search_for_matching_pte
	crnot	cr0_eq, cr0_eq
	lwz		r30, KDP.PTEGMask(r1)
	xori	r31, r31, 0x800
	xor		r29, r29, r30
	beq		@retry_other_pteg

########################################################################
@search_for_matching_pte			; r29 = full PTEG
	lwz		r26, KDP.OverflowingPTEG(r1)	; this could be zero
	crclr	cr6_eq							; prepare to return "failure"
	rlwimi	r26, r29, 0, -64
	addi	r29, r26, 8
	b		@first_pte

@rethink_pte_search
	bne		cr6, @next_pte
	mr		r26, r29

@next_pte
	cmpw	cr6, r29, r26
	addi	r29, r29, 8
@first_pte
	rlwimi	r29, r26, 0, 0, 25
	lwz		r31, 4(r29)
	lwz		r30, 0(r29)
	beq		cr6, @got_pte
	rlwinm	r28, r31, 30, 25, 25
	andc.	r28, r28, r30					; R && !H (i.e. page has been read and is not in "secondary hash" PTEG)
	bne		@next_pte						; if so, 
@got_pte

########################################################################

	clrlwi	r28, r31, 30
	cmpwi	cr7, r28, 0
	clrrwi	r28, r31, 12
	cmpw	r28, r1
	lwz		r30, KDP.ContextPtr(r1)

	beq		cr7, @rethink_pte_search
	addi	r31, r30, 768-1
	beq		@rethink_pte_search

	rlwinm	r30, r30, 0, 0xFFFFF000
	cmpwi	cr7, r28, 30
	lwz		r30, 0(r29)
	rlwinm	r31, r31, 0, 0xFFFFF000
	cmpwi	r28, 31
	rlwinm	r31, r30, 0, 0x00000040
	beq		cr7, @rethink_pte_search
	extlwi	r28, r30, 4, 1
	beq		@rethink_pte_search
	neg		r31, r31
	insrwi	r28, r30, 6, 4
	xor		r31, r31, r29
	rlwimi	r28, r30, 5, 10, 19
	rlwinm	r31, r31, 6, 10, 19
	xor		r28, r28, r31

	lwz		r26, KDP.CurMap.SegMapPtr(r1)
	rlwinm	r30, r28, (32-25), 0x00000078
	lwzx	r26, r26, r30						; r26 pts into PageMap @ current segment

@tinyloop										; find the last non-blank PME in the segment
	lhz		r30, PME.LBase(r26)
	rlwinm	r31, r28, 20, 0x0000FFFF
	subf	r30, r30, r31
	lhz		r31, PME.PageCount(r26)
	addi	r26, r26, 8
	cmplw	cr7, r30, r31
	lwz		r31, PME.PBaseAndFlags - 8(r26)
	andi.	r31, r31, 0xe01
	cmpwi	r31, 0xa01
	bgt		cr7, @tinyloop
	beq		@tinyloop

	lwz		r26, PME.PBaseAndFlags - 8(r26)		; got that PME (26)
	slwi	r30, r30, 2
	extrwi	r31, r26, 2, 20
	cmpwi	cr7, r31, 3							; not a DaddyFlag + CountingFlag? Try again!

	lwz		r31, KDP.NKInfo.HashTableOverflowCount(r1)
	stw		r29, KDP.OverflowingPTEG(r1)
	addi	r31, r31, 1
	stw		r31, KDP.NKInfo.HashTableOverflowCount(r1)
	lwz		r31, KDP.NKInfo.HashTableDeleteCount(r1)
	stw		r30, 0(r29)
	addi	r31, r31, 1
	stw		r31, KDP.NKInfo.HashTableDeleteCount(r1)

	sync
	tlbie	r28
	sync

	_InvalNCBPointerCache scratch=r28

	bne		cr7, PutPTE					; not a DaddyFlag + CountingFlag? Retriable...

	rlwinm	r26, r26, 22, 0xFFFFFFFC			; PIRFlag << 31 | BtmBit << 22 | physBase * 4
	lwzux	r28, r26, r30
	lwz		r31, 4(r29)
	andi.	r30, r28, 0x800
	rlwinm	r30, r28, (32-9), 0x007FFFF8
	xor		r30, r30, r29
	beq		SystemCrash
	andi.	r30, r30, 0xffff
	xori	r28, r28, 0x800
	bne		SystemCrash
	rlwimi	r28, r31, 0, 0, 19					; r28 = EA of victim of overflow
	rlwimi	r28, r31, 29, 27, 27
	rlwimi	r28, r31, 27, 28, 28
	stw		r28, 0(r26)

	b		PutPTE

########################################################################
########################################################################

SetMap ; MemMap r29
	lwz		r28, MemMap.SegMapPtr(r29)
	stw		r28, KDP.CurMap.SegMapPtr(r1)
	addi	r28, r28, 16*8 + 4
	lis		r31, 0

@next_seg										; SEGMENT REGISTERS
	lwzu	r30, -8(r28)
	subis	r31, r31, 0x1000
	mr.		r31, r31
	mtsrin	r30, r31
	bne		@next_seg

	mfpvr	r31
	lwz		r28, MemMap.BatMap(r29)
	andis.	r31, r31, 0xFFFE
	addi	r29, r1, 0
	stw		r28, KDP.CurMap.BatMap(r1)
	beq		@601

	rlwimi	r29, r28, 7, 0x00000078		; BATS, non-601
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	ibat0u, r30
	mtspr	ibat0l, r31
	stw		r30, KDP.CurIBAT0.U(r1)
	stw		r31, KDP.CurIBAT0.L(r1)

	rlwimi	r29, r28, 11, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	ibat1u, r30
	mtspr	ibat1l, r31
	stw		r30, KDP.CurIBAT1.U(r1)
	stw		r31, KDP.CurIBAT1.L(r1)

	rlwimi	r29, r28, 15, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	ibat2u, r30
	mtspr	ibat2l, r31
	stw		r30, KDP.CurIBAT2.U(r1)
	stw		r31, KDP.CurIBAT2.L(r1)

	rlwimi	r29, r28, 19, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	ibat3u, r30
	mtspr	ibat3l, r31
	stw		r30, KDP.CurIBAT3.U(r1)
	stw		r31, KDP.CurIBAT3.L(r1)

	rlwimi	r29, r28, 23, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	dbat0u, r30
	mtspr	dbat0l, r31
	stw		r30, KDP.CurDBAT0.U(r1)
	stw		r31, KDP.CurDBAT0.L(r1)

	rlwimi	r29, r28, 27, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	dbat1u, r30
	mtspr	dbat1l, r31
	stw		r30, KDP.CurDBAT1.U(r1)
	stw		r31, KDP.CurDBAT1.L(r1)

	rlwimi	r29, r28, 31, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	dbat2u, r30
	mtspr	dbat2l, r31
	stw		r30, KDP.CurDBAT2.U(r1)
	stw		r31, KDP.CurDBAT2.L(r1)

	rlwimi	r29, r28, 3, 0x00000078
	lwz		r30, KDP.BATs + BAT.U(r29)
	lwz		r31, KDP.BATs + BAT.L(r29)
	mtspr	dbat3u, r30
	mtspr	dbat3l, r31
	stw		r30, KDP.CurDBAT3.U(r1)
	stw		r31, KDP.CurDBAT3.L(r1)

	cmpw	r29, r29
	blr

@601
	rlwimi	r29, r28, 7, 25, 28
	lwz		r30, KDP.BATs + 0(r29)
	lwz		r31, KDP.BATs + 4(r29)
	stw		r30, 0x0300(r1)
	stw		r31, 0x0304(r1)
	stw		r30, 0x0320(r1)
	stw		r31, 0x0324(r1)
	rlwimi	r30, r31, 0, 25, 31
	mtspr	ibat0u, r30
	lwz		r30, KDP.BATs + 0(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30, 6, 25, 25
	mtspr	ibat0l, r31
	rlwimi	r29, r28, 11, 25, 28
	lwz		r30, KDP.BATs + 0(r29)
	lwz		r31, KDP.BATs + 4(r29)
	stw		r30, 0x0308(r1)
	stw		r31, 0x030c(r1)
	stw		r30, 0x0328(r1)
	stw		r31, 0x032c(r1)
	rlwimi	r30, r31, 0, 25, 31
	mtspr	ibat1u, r30
	lwz		r30, KDP.BATs + 0(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30, 6, 25, 25
	mtspr	ibat1l, r31
	rlwimi	r29, r28, 15, 25, 28
	lwz		r30, KDP.BATs + 0(r29)
	lwz		r31, KDP.BATs + 4(r29)
	stw		r30, 0x0310(r1)
	stw		r31, 0x0314(r1)
	stw		r30, 0x0330(r1)
	stw		r31, 0x0334(r1)
	rlwimi	r30, r31, 0, 25, 31
	mtspr	ibat2u, r30
	lwz		r30, KDP.BATs + 0(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30, 6, 25, 25
	mtspr	ibat2l, r31
	rlwimi	r29, r28, 19, 25, 28
	lwz		r30, KDP.BATs + 0(r29)
	lwz		r31, KDP.BATs + 4(r29)
	stw		r30, 0x0318(r1)
	stw		r31, 0x031c(r1)
	stw		r30, 0x0338(r1)
	stw		r31, 0x033c(r1)
	rlwimi	r30, r31, 0, 25, 31
	mtspr	ibat3u, r30
	lwz		r30, KDP.BATs + 0(r29)
	rlwimi	r31, r30, 30, 26, 31
	rlwimi	r31, r30, 6, 25, 25
	mtspr	ibat3l, r31
	cmpw	r29, r29
	blr

########################################################################
########################################################################

GetPhysical ; EA r27, batPtr r29 // PA r31, EQ=Fail
	lwz		r30, 0(r29)
	li		r28, -1
	rlwimi	r28, r30, 15, 0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	beq		@_54
	lwzu	r30, 8(r29)
	rlwimi	r28, r30, 15, 0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	beq		@_54
	lwzu	r30, 8(r29)
	rlwimi	r28, r30, 15, 0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	beq		@_54
	lwzu	r30, 8(r29)
	rlwimi	r28, r30, 15, 0, 14
	xor		r31, r27, r30
	andc.	r31, r31, r28
	bne		GetPhysicalFromHTAB

@_54
	andi.	r31, r30, 1
	rlwinm	r28, r28, 0, 8, 19
	lwzu	r31, 4(r29)
	and		r28, r27, r28
	or		r31, r31, r28
	bnelr

GetPhysicalFromHTAB ; EA r27 // PA r31, EQ=Fail
	mfsrin	r31, r27
	rlwinm	r30, r27, 10, 26, 31
	rlwimi	r30, r31, 7, 1, 24
	rlwinm	r28, r27, 26, 10, 25
	oris	r30, r30, 0x8000
	rlwinm	r31, r31, 6, 7, 25
	xor		r28, r28, r31
	lwz		r31, KDP.PTEGMask(r1)
	lwz		r29, KDP.HTABORG(r1)
	and		r28, r28, r31
	or.		r29, r29, r28

@_2c
	lwz		r31, 0(r29)
	lwz		r28, 8(r29)
	cmpw	cr6, r30, r31
	lwz		r31, 16(r29)
	cmpw	cr7, r30, r28
	lwzu	r28, 24(r29)
	bne		cr6, @_50

@_48
	lwzu	r31, -0x0014(r29)
	blr

@_50
	cmpw	cr6, r30, r31
	lwzu	r31, 8(r29)
	beq		cr7, @_48
	cmpw	cr7, r30, r28
	lwzu	r28, 8(r29)
	beq		cr6, @_48
	cmpw	cr6, r30, r31
	lwzu	r31, 8(r29)
	beq		cr7, @_48
	cmpw	cr7, r30, r28
	lwzu	r28, 8(r29)
	beq		cr6, @_48
	cmpw	cr6, r30, r31
	lwzu	r31, -0x000c(r29)
	beqlr	cr7
	cmpw	cr7, r30, r28
	lwzu	r31, 8(r29)
	beqlr	cr6
	lwzu	r31, 8(r29)
	beqlr	cr7
	lwz		r31, KDP.PTEGMask(r1)
	xori	r30, r30, 0x40
	andi.	r28, r30, 0x40
	addi	r29, r29, -0x3c
	xor		r29, r29, r31
	bne		@_2c
	blr

########################################################################
########################################################################

FlushTLB
	lhz		r29, KDP.ProcInfo.TransCacheTotalSize(r1)
	slwi	r29, r29, 11
@loop
	subi	r29, r29, 4096
	cmpwi	r29, 0
	tlbie	r29
	bgt		@loop
	sync
	blr
