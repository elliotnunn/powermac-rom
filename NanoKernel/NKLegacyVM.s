; AUTO-GENERATED SYMBOL LIST
; IMPORTS:
;   NKExceptions
;     ReturnFromInt
;   NKMemory
;     PutPTE
;   NKSystemCrash
;     SystemCrash
; EXPORTS:
;   KCallVMDispatch (=> NKReset)

; This file is a horrible mess. It needs a do-over.

; Registers used throughout: (maybe we'll just call these "conventions")
vmrMisc1        equ r8
vmrMisc2        equ r9
vmrPtePtr       equ r14
vmr68PtePtr     equ r15
vmr68Pte        equ r16


########################################################################

KCallVMDispatch
    stw     r7, KDP.Flags(r1)
    lwz     r7, KDP.CodeBase(r1)
    cmplwi  r3, (VMTabEnd-VMTab)/4
    insrwi  r7, r3, 7, 24
    lhz     r8, VMTab-CodeBase(r7)
    lwz     r9, KDP.VMLogicalPages(r1)
    add     r8, r8, r7
    mtlr    r8

    lwz     r6, KDP.r6(r1)
    stw     r14, KDP.r14(r1)
    stw     r15, KDP.r15(r1)
    stw     r16, KDP.r16(r1)

    bltlr
    b       vmRetNeg1

VMTab ; Placeholders indented
    MACRO
    vmtabLine &label
    DC.W (&label-CodeBase) - (* - VMtab)
    ENDM

    vmtabLine   VMInit                  ;  0 VMInit: init the MMU virtual space
    vmtabLine       vmRet               ;  1 VMUnInit: un-init the MMU virtual space
    vmtabLine       vmRet               ;  2 VMFinalInit: last chance to init after new memory dispatch is installed

    vmtabLine   VMIsResident            ;  3 VMIsResident: ask about page status
    vmtabLine   VMIsUnmodified          ;  4 VMIsUnmodified: ask about page status
    vmtabLine   VMIsInited              ;  5 VMIsInited: ask about page status
    vmtabLine   VMShouldClean           ;  6 VMShouldClean: ask about page status

    vmtabLine   VMMarkResident          ;  7 VMMarkResident: set page status 
    vmtabLine   VMMarkBacking           ;  8 VMMarkBacking: set page status
    vmtabLine   VMMarkCleanUnused       ;  9 VMMarkCleanUnused: set page status

    vmtabLine   VMGetPhysicalPage       ; 10 VMGetPhysicalPage: return phys page given log page
    vmtabLine       vmRetNeg1           ; 11 VMGetPhysicalAddress: return phys address given log page (can be different from above!)
    vmtabLine   VMExchangePages         ; 12 VMExchangePages: exchange physical page contents
    vmtabLine       vmRet               ; 13 VMReload: reload the ATC with specified page
    vmtabLine       vmRet               ; 14 VMFlushAddressTranslationCache: just do it
    vmtabLine       vmRet               ; 15 VMFlushDataCache: wack the data cache
    vmtabLine       vmRet               ; 16 VMFlushCodeCache: wack the code cache
    vmtabLine   VMMakePageCacheable     ; 17 VMMakePageCacheable: make it so...
    vmtabLine   VMMakePageNonCacheable  ; 18 VMMakePageNonCacheable: make it so...
    vmtabLine   VMGetPTEntryGivenPage   ; 19 VMGetPTEntryGivenPage: given a page, get its 68K PTE
    vmtabLine   VMSetPTEntryGivenPage   ; 20 VMSetPTEntryGivenPage: given a page & 68K pte, set the real PTE
    vmtabLine   VMPTest                 ; 21 VMPTest: ask why we got this page fault
    vmtabLine   VMLRU                   ; 22 VMLRU: least recently used?
    vmtabLine   VMMarkUndefined         ; 23 VMMarkUndefined
    vmtabLine   VMMakePageWriteThrough  ; 24 VMMakePageWriteThrough
    vmtabLine   VMAllocateMemory        ; 25 VMAllocateMemory: Page:A0, Count:A1, BusAlignMask:D1
VMTabEnd

########################################################################

vmRetNeg1
    li      r3, -1
    b       vmRet
vmRet0
    li      r3, 0
    b       vmRet
vmRet1
    li      r3, 1
vmRet
    lwz     r14, KDP.r14(r1)
    lwz     r15, KDP.r15(r1)
    lwz     r16, KDP.r16(r1)
    lwz     r7, KDP.Flags(r1)
    lwz     r6, KDP.ContextPtr(r1)
    b       ReturnFromInt

########################################################################

VMInit
    lwz     r7, KDP.VMPageArray(r1)          ; check that zero seg isn't empty
    lwz     r8, KDP.SegmentPageArrays + 0(r1)
    cmpw    r7, r8
    bne     vmRet1

    stw     r4, KDP.VMLogicalPages(r1)          ; resize PAR

    stw     r5, KDP.VMPageArray(r1)          ; where did NK find this???

    lwz     r6, KDP.CurMap.SegMapPtr(r1)
    li      r5,  0x00
    li      r4,  0x00

VMInit_BigLoop
    lwz     r8,  0x0000(r6)
    addi    r6, r6,  0x08
    lhz     r3,  0x0000(r8)
    lhz     r7,  0x0002(r8)
    lwz     r8,  0x0004(r8)
    addi    r7, r7,  0x01
    cmpwi   cr1, r3,  0x00
    andi.   r3, r8,  0xc00
    cmpwi   r3,  0xc00
    bne     VMInit_0x110
    bnel    cr1, SystemCrash
    rlwinm  r15, r8, 22,  0, 29
    addi    r3, r1, KDP.SegmentPageArrays
    rlwimi  r3, r5,  2, 28, 29
    stw     r15,  0x0000(r3)
    slwi    r3, r5, 16
    cmpw    r3, r4
    bnel    SystemCrash

VMInit_0xa8
    lwz     r16,  0x0000(r15)
    addi    r7, r7, -0x01
    andi.   r3, r16,  0x01
    beql    SystemCrash
    andi.   r3, r16,  0x800
    beq     VMInitple_or_pte0
    lwz     r14, KDP.HTABORG(r1)
    rlwinm  r3, r16, 23,  9, 28
    lwzux   r8, r14, r3
    lwz     r9,  0x0004(r14)
    andis.  r3, r8,  0x8000
    beql    SystemCrash
    andi.   r3, r9,  0x03
    cmpwi   r3,  0x00
    beql    SystemCrash
    rlwinm  r3, r16, 17, 22, 31
    rlwimi  r3, r8, 10, 16, 21
    rlwimi  r3, r8, 21, 12, 15
    cmpw    r3, r4
    bnel    SystemCrash
;   bl      RemovePageFromTLB
    bl      DeletePTE

VMInitple_or_pte0
    cmpwi   r7,  0x00
    addi    r15, r15,  0x04
    addi    r4, r4,  0x01
    bne     VMInit_0xa8

VMInit_0x110
    addi    r5, r5,  0x01
    cmpwi   r5, 4
    bne     VMInit_BigLoop



    lwz     r7, KDP.VMPhysicalPages(r1)
    cmpw    r4, r7
    bnel    SystemCrash
    lwz     r5,  KDP.VMPageArray(r1)
    lwz     r4, KDP.VMLogicalPages(r1)
    andi.   r7, r5,  0xfff

    li      r3,  0x02
    bne     VMInit_Fail

    lis     r7, 4
    cmplw   r7, r4

    li      r3,  0x03
    blt     VMInit_Fail

    addi    r7, r4,  0x3ff
    srwi    r6, r7, 10
    srwi    r8, r5, 12
    add     r8, r8, r6
    lwz     r9, KDP.VMPhysicalPages(r1)
    cmplw   r8, r9

    li      r3,  0x04
    bgt     VMInit_Fail

    cmplw   r4, r9

    li      r3,  0x05
    blt     VMInit_Fail

    srwi    r7, r5, 12
    bl      QuickGetPhysical
    stw     r9,  KDP.VMPageArray(r1)
    mr      r15, r9
    srwi    r7, r5, 12
    add     r7, r7, r6
    addi    r7, r7, -0x01
    bl      QuickGetPhysical
    subf    r9, r15, r9
    srwi    r9, r9, 12
    addi    r9, r9,  0x01
    cmpw    r9, r6

    li      r3,  0x06
    bne     VMInit_Fail

    stw     r4, KDP.VMLogicalPages(r1)
    slwi    r7, r4, 12
    stw     r7, KDP.SysInfo.LogicalMemorySize(r1) ; bug in NKv2??
    slwi    r7, r4,  2
    li      r8,  0x00

VMInit_0x1d4
    subi    r7, r7, 4
    cmpwi   r7,  0x00
    stwx    r8, r15, r7
    bne     VMInit_0x1d4
    lwz     r7, KDP.VMPhysicalPages(r1)
    slwi    r6, r7,  2

VMInit_0x1ec
    subi    r6, r6, 4
    srwi    r7, r6,  2
    bl      QuickGetPhysical
    cmpwi   r6,  0x00
    ori     r16, r9,  0x21
    stwx    r16, r15, r6
    bne     VMInit_0x1ec
    lwz     r15,  KDP.VMPageArray(r1)
    srwi    r7, r5, 10
    add     r15, r15, r7
    lwz     r5, KDP.VMLogicalPages(r1)

VMInit_0x218
    lwz     r16,  0x0000(r15)
    andi.   r7, r16,  0x01
    beql    SystemCrash
    ori     r16, r16,  0x404
    stw     r16,  0x0000(r15)
    addi    r5, r5, -0x400
    cmpwi   r5,  0x00
    addi    r15, r15,  0x04
    bgt     VMInit_0x218
    lwz     r6, KDP.CurMap.SegMapPtr(r1)
    li      r9, 0
    ori     r7, r9,  0xffff
    li      r8,  0xa00

VMInit_0x250
    lwz     r3,  0x0000(r6)
    addi    r6, r6,  0x08
    stw     r7,  0x0000(r3)
    stw     r8,  0x0004(r3)
    stw     r7,  0x0008(r3)
    stw     r8,  0x000c(r3)
    addi    r9, r9, 1
    cmpwi   r9, 3
    ble     VMInit_0x250
    lwz     r6, KDP.CurMap.SegMapPtr(r1)
    lwz     r9, KDP.VMLogicalPages(r1)
    lwz     r15,  KDP.VMPageArray(r1)

VMInit_0x288
    lwz     r8,  0x0000(r6)
    lis     r7,  0x01
    rlwinm. r3, r9, 16, 16, 31
    bne     VMInit_0x29c
    mr      r7, r9

VMInit_0x29c
    subf.   r9, r7, r9
    addi    r7, r7, -0x01
    stw     r7,  0x0000(r8)
    rlwinm  r7, r15, 10, 22, 19
    ori     r7, r7,  0xc00
    stw     r7,  0x0004(r8)
    addis   r15, r15,  0x04
    addi    r6, r6,  0x08
    bne     VMInit_0x288

    b       vmRet0

VMInit_Fail
    lwz     r7, KDP.VMPhysicalPages(r1)
    lwz     r8, KDP.SegmentPageArrays + 0(r1)
    stw     r7, KDP.VMLogicalPages(r1)
    stw     r8, KDP.VMPageArray(r1)

    b       vmRet

########################################################################

VMExchangePages
    bl      PageInfo
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1                ; not a paged area
    bc      BO_IF, 21, vmRetNeg1
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1        ; must be resident
    bc      BO_IF, bM68pdCacheinhib, vmRetNeg1          ; must not have special properties
    bc      BO_IF_NOT, bM68pdCacheNotIO, vmRetNeg1
    bcl     BO_IF, bM68pdInHTAB, DeletePTE       ; if in HTAB, must be removed
    mr      r6, r15                                     ; r6 = src 68k PTE ptr

    mr      r4, r5
    mr      r5, r16                                     ; r5 = src 68k PTE
    lwz     r9, KDP.VMLogicalPages(r1)
    bl      PageInfo
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1
    bc      BO_IF, 21, vmRetNeg1
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1
    bc      BO_IF, bM68pdCacheinhib, vmRetNeg1
    bc      BO_IF_NOT, bM68pdCacheNotIO, vmRetNeg1
    bcl     BO_IF, bM68pdInHTAB, DeletePTE

    stw     r5, 0(r15)                                  ; swap 68k PTEs (in that big flat list)                                  
    stw     r16, 0(r6)

    rlwinm  r4, r5, 0, 0xFFFFF000                       ; get clean physical ptrs to both pages
    rlwinm  r5, r16, 0, 0xFFFFF000

    li      r9, 0x1000
    li      r6, 4
@copyloop
    subf.   r9, r6, r9
    lwzx    r7, r4, r9
    lwzx    r8, r5, r9
    stwx    r7, r5, r9
    stwx    r8, r4, r9
    bne     @copyloop

    b       vmRet

########################################################################

VMGetPhysicalPage
    bl      PageInfo
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1
    srwi    r3, r9, 12
    b       vmRet

########################################################################

VMGetPTEntryGivenPage
    bl      PageInfo
    mr      r3, r16
    bc      BO_IF_NOT, bM68pdResident, vmRet
    rlwimi  r3, r9, 0, 0xFFFFF000
    b       vmRet

########################################################################

VMIsInited
    bl      PageInfo
    bc      BO_IF, bM68pdResident, vmRet1
    rlwinm  r3, r16, 16, 31, 31
    b       vmRet

########################################################################

VMIsResident
    bl      PageInfo
    rlwinm  r3, r16, 0, 1 ; M68pdResident
    b       vmRet

########################################################################

VMIsUnmodified
    bl      PageInfo
    rlwinm  r3, r16, bM68pdModified + 1, 1
    xori    r3, r3, 1
    b       vmRet

########################################################################

VMLRU ; For each resident page: save Used bit and clear original
    slwi    r9, r9, 2                   ; (r9 is VMLogicalPages)
    lwz     r15, KDP.VMPageArray(r1)
    lwz     r14, KDP.HTABORG(r1)
    add     r15, r15, r9                ; r15 = loop PageArray ptr
    srwi    r4, r9, 2                   ; r4 = loop counter

    li      r5, LpteReference           ; r5/r6 or clearing bits with andc
    li      r6, M68pdUsed

@loop ; over every logical page
    lwzu    r16, -4(r15)
    subi    r4, r4, 1
    mtcr    r16
    cmpwi   r4, 0

    rlwinm  r7, r16, 23, 0x7FFFFFFC     ; r7 = offset of PPC PTE (if any)
    bc      BO_IF_NOT, bM68pdResident, @nonresident

    bc      BO_IF_NOT, bM68pdInHTAB, @not_in_htab
    add     r14, r14, r7                ; If PPC PTE in HTAB, copy its Ref
    lwz     r9, 4(r14)                  ; bit back to 68k PTE and clear
    _mvbit  r16, bM68pdUsed, r9, bLpteReference
    andc    r9, r9, r5
    bl      SaveLowerPTE
    subf    r14, r7, r14
@not_in_htab

    _mvbit  r16, bM68pdFrozenUsed, r16, bM68pdUsed
    andc    r16, r16, r6                ; save Used and clear original
    stw     r16, 0(r15)                 ; save changed 68k PTE
@nonresident

    bne     @loop
    b       vmRet

########################################################################

VMMakePageCacheable
; PPC: LpteWritethru(W)=0, LpteInhibcache(I)=0
; 68k: M68pdCacheNotIO(CM0)=1, M68pdCacheinhib(CM1)=0 ["Cachable,Copyback"]
    bl      PageInfo
    rlwinm  r7, r16, 0, M68pdCacheNotIO | M68pdCacheinhib   ; test CM0/CM1
    cmpwi   r7, M68pdCacheNotIO
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1            ; not resident!
    beq     vmRet                                           ; already write-through
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1                    ; not a paged area, so fail!

    bcl     BO_IF_NOT, bM68pdInHTAB, QuickCalcPTE           ; need to have a PPC PTE

    rlwinm  r16, r16, 0, ~(M68pdCacheinhib | M68pdCacheNotIO)
    rlwinm  r9, r9,  0, ~(LpteWritethru | LpteInhibcache)
    ori     r16, r16, M68pdCacheNotIO
    bl      SavePTEAnd68kPD

    b       vmRet

########################################################################

VMMakePageWriteThrough
; PPC: LpteWritethru(W)=1, LpteInhibcache(I)=0
; 68k: M68pdCacheNotIO(CM0)=0, M68pdCacheinhib(CM1)=0 ["Cachable,Write-through"]
    bl      PageInfo
    rlwinm. r7, r16, 0, M68pdCacheNotIO | M68pdCacheinhib   ; test CM0/CM1
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1            ; not resident!
    beq     vmRet                                           ; already write-through
    bc      BO_IF_NOT, cr4_lt, @not_paged                   ; not a paged area, so use PMDT!

    bcl     BO_IF_NOT, bM68pdInHTAB, QuickCalcPTE           ; need to have a PPC PTE

    rlwinm  r16, r16, 0, ~(M68pdCacheNotIO | M68pdCacheinhib)
    rlwinm  r9, r9, 0, ~(LpteWritethru | LpteInhibcache)
    ori     r9, r9, LpteWritethru
    bl      SavePTEAnd68kPD

    b       vmFlushPageAndReturn

@not_paged ; so try to find a free PMDT to use (quite messy)
    rlwinm  r7, r4, 16, 0xF                                 ; address must be in segments 8-F
    cmpwi   r7, 9
    blt     vmRetNeg1

    bc      BO_IF_NOT, bM68pdCacheinhib, vmRetNeg1          ; must already be cache-inhibited??

    lwz     r5, PMDT.Size + PMDT.Word2(r15)                 ; take over the following PMDT if
    andi.   r6, r5, EveryPattr                              ; it is "available"
    cmpwi   r6, PMDT_Available
    beq     @next_pmdt_free

; no free PMDT... hijack the previous one if it is PMDT_PTE_Range
    subi    r15, r15, PMDT.Size
    lwz     r5, PMDT.Word2(r15)
    lhz     r6, PMDT.PageIdx(r15)
    andi.   r5, r5, Pattr_NotPTE | Pattr_PTE_Single
    lhz     r5, PMDT.PageCount(r15)
    bne     vmRetNeg1                                       ; demand PMDT_PTE_Range
    addi    r5, r5, 1
    add     r6, r6, r5
    xor     r6, r6, r4
    andi.   r6, r6, 0xffff                                  ; does the previous PMDT abut this one?
    bne     vmRetNeg1
    sth     r5, PMDT.PageCount(r15)
    b       @edited_pmdt

@next_pmdt_free ; so replace it with copy of current one, then turn current one into PMDT_PTE_Range
    lwz     r5, 0(r15)                                      ; copy current PMDT to next
    lwz     r6, 4(r15)
    stw     r5, PMDT.Size + 0(r15)
    stw     r6, PMDT.Size + 4(r15)

    slwi    r5, r4, 16                                      ; PMDT PageIdx=this, PageCount=single
    stw     r5, 0(r15)
    slwi    r5, r4, 12                                      ; PMDT RPN = logical address of page
    ori     r5, r5, LpteWritethru | LpteP0                  ; and raise these flags too
    stw     r5, PMDT.Word2(r15)

@edited_pmdt ; now to delete any existing PTE derived from the original PMDT
    lwz     r15, KDP.PTEGMask(r1)                           ; hash to find the PTEG
    lwz     r14, KDP.HTABORG(r1)
    slwi    r6, r4, 12
    mfsrin  r6, r6
    rlwinm  r8, r6, 7, UpteValid | UpteVSID
    xor     r6, r6, r4
    slwi    r7, r6, 6
    and     r15, r15, r7
    rlwimi  r8, r4, 22, UpteAPI
    crset   cr0_eq                                          ; clear cr0_eq when trying the secondary hash
;    _ori    r8, r8, UpteValid                               ; r8 = the exact upper PTE word to search
    nop

@secondary_hash
    lwzux   r7, r14, r15                                    ; search the primary or secondary PTEG for r8
    lwz     r15, 8(r14)
    lwz     r6, 16(r14)
    lwz     r5, 24(r14)
    cmplw   cr1, r7, r8
    cmplw   cr2, r15, r8
    cmplw   cr3, r6, r8
    cmplw   cr4, r5, r8
    beq     cr1, @pte_at_r14
    beq     cr2, @pte_at_r14_plus_8
    beq     cr3, @pte_at_r14_plus_16
    beq     cr4, @pte_at_r14_plus_24
    lwzu    r7, 32(r14)
    lwz     r15, 8(r14)
    lwz     r6, 16(r14)
    lwz     r5, 24(r14)
    cmplw   cr1, r7, r8
    cmplw   cr2, r15, r8
    cmplw   cr3, r6, r8
    cmplw   cr4, r5, r8
    beq     cr1, @pte_at_r14
    beq     cr2, @pte_at_r14_plus_8
    beq     cr3, @pte_at_r14_plus_16
    beq     cr4, @pte_at_r14_plus_24

    crnot   cr0_eq, cr0_eq                                  ; can't find it => try again with secondary hash
    lwz     r15, KDP.PTEGMask(r1)
    lwz     r14, KDP.HTABORG(r1)
    slwi    r6, r4, 12
    mfsrin  r6, r6
    xor     r6, r6, r4
    not     r6, r6
    slwi    r7, r6, 6
    and     r15, r15, r7
    xori    r8, r8, UpteHash
    bc      BO_IF_NOT, cr0_eq, @secondary_hash
    b       vmRet

@pte_at_r14_plus_24
    addi    r14, r14, 8
@pte_at_r14_plus_16
    addi    r14, r14, 8
@pte_at_r14_plus_8
    addi    r14, r14, 8
@pte_at_r14                                                 ; found PTE based on original PMDT => delete it
    li      r8, 0
    li      r9, 0
    bl      SavePTE
    b       vmRet

########################################################################

VMMakePageNonCacheable ; set WI=01 and CM0/CM1=11
    bl      PageInfo
    rlwinm  r7, r16, 0, M68pdCacheNotIO | M68pdCacheinhib
    cmpwi   r7, M68pdCacheNotIO | M68pdCacheinhib   ; these should both end up set
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1
    beq     vmRet
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1            ; not a paged area

    bcl     BO_IF_NOT, bM68pdInHTAB, QuickCalcPTE

    rlwinm  r9, r9,  0, ~(LpteWritethru | LpteInhibcache)
    ori     r16, r16, M68pdCacheNotIO | M68pdCacheinhib
    ori     r9, r9, LpteInhibcache

    bl      SavePTEAnd68kPD
    ; Fall through to vmFlushPageAndReturn

########################################################################

vmFlushPageAndReturn ; When making page write-though or noncacheable
    rlwinm  r4, r9, 0, 0xFFFFF000
    addi    r5, r4, 32
    li      r7, 0x1000
    li      r8, 64
@loop
    subf.   r7, r8, r7
    dcbf    r7, r4
    dcbf    r7, r5
    bne     @loop
    b       vmRet

########################################################################

VMMarkBacking
    bl      PageInfo
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1    ; not a paged area
    bc      BO_IF, bM68pdGlobal, vmRetNeg1

    bcl     BO_IF, bM68pdInHTAB, DeletePTE

    _mvbit  r16, 15, r5, 31
    li      r7, M68pdResident
    andc    r16, r16, r7
    stw     r16, 0(r15)

    b       vmRet

########################################################################

VMMarkCleanUnused
    bl      PageInfo
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1    ; not a paged area
    bc      BO_IF_NOT, bM68pdResident, vmRetNeg1

    bcl     BO_IF_NOT, bM68pdInHTAB, QuickCalcPTE

    li      r7, LpteReference | LpteChange
    andc    r9, r9, r7
    ori     r16, r16, M68pdModified
    bl      SavePTEAnd68kPD

    b       vmRet

########################################################################

VMMarkUndefined
    cmplw   r4, r9
    cmplw   cr1, r5, r9
    add     r7, r4, r5
    cmplw   cr2, r7, r9
    bge     vmRetNeg1
    bgt     cr1, vmRetNeg1
    bgt     cr2, vmRetNeg1
    lwz     r15,  KDP.VMPageArray(r1)
    slwi    r8, r7,  2
    li      r7,  0x01

VMMarkUndefined_0x28
    subi    r8, r8, 4
    subf.   r5, r7, r5
    lwzx    r16, r15, r8
    blt     vmRet
    rlwimi  r16, r6,  7, 24, 24
    stwx    r16, r15, r8
    b       VMMarkUndefined_0x28

########################################################################

VMMarkResident ; physical page number in a0/r5
    bl      PageInfo
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1        ; not a paged area!
    bc      BO_IF, bM68pdResident, vmRetNeg1    ; already resident!
    bcl     BO_IF, bM68pdInHTAB, SystemCrash    ; corrupt 68k PD!

    rlwimi  r16, r5, 12, 0xFFFFF000             ; make up a 68k PD
    ori     r16, r16, M68pdResident             ; save it
    stw     r16, 0(r15)

    bl      QuickCalcPTE                        ; make up a PPC PTE
    bl      SavePTEAnd68kPD                     ; save it

    b       vmRet

########################################################################

VMPTest ; return reason for fault on page a0/r4, based on action in d1/r6
    srwi    r4, r4, 12          ; because it was outside a paged area?
    cmplw   r4, r9
    li      r3, 1 << 14
    bge     vmRet

    bl      PageInfo            ; because the page was non-resident?
    li      r3, 1 << 10
    bc      BO_IF_NOT, bM68pdResident, vmRet

    li      r3, 0               ; unknown!
    ori     r3, r3, 1 << 15
    bc      BO_IF_NOT, bM68pdWriteProtect, vmRet
    cmpwi   r6, 0
    beq     vmRet

    li      r3, 1 << 11         ; because wrote to write-protected page
    b       vmRet               ; (requires d1/r6 to be non-zero)

########################################################################

VMSetPTEntryGivenPage
    mr      r6, r4
    mr      r4, r5
    bl      PageInfo
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1    ; not a paged area

    xor     r7, r16, r6         ; r17 = bits to be changed

                                ; cannot change G/CM0/CM1/PTD0 with this call
    li      r3, M68pdGlobal | M68pdCacheinhib | M68pdCacheNotIO | M68pdResident
    _mvbit  r3, bM68pdWriteProtect, r16, bM68pdGlobal ; cannot change WP if G is set
    and.    r3, r3, r7
    bne     vmRetNeg1           ; fail if trying to change a forbidden bit

    andi.   r7, r7, M68pdShouldClean | M68pdModified | M68pdUsed | M68pdWriteProtect
    xor     r16, r16, r7        ; silently refuse to change U0/M/U/WP
    stw     r16, 0(r15)         ; save new 68k PD

    bc      BO_IF_NOT, bM68pdInHTAB, vmRet          ; edit PPC PTE if applicable
    _mvbit  r9, bLpteReference, r16, bM68pdUsed
    _mvbit  r9, bLpteChange, r16, bM68pdModified
    _mvbit  r9, bLpteP1, r16, bM68pdWriteProtect
    bl      SaveLowerPTE
    b       vmRet

########################################################################

VMShouldClean ; is this page is a good candidate for writing to disk?
    bl      PageInfo
    bc      BO_IF_NOT, bM68pdResident, vmRet0   ; already paged out: no
    bc      BO_IF, bM68pdUsed, vmRet0           ; been read recently: no
    bc      BO_IF_NOT, bM68pdModified, vmRet0   ; unwritten ('clean'): no
    bc      BO_IF_NOT, cr4_lt, vmRetNeg1        ; not a paged area: error

    xori    r16, r16, M68pdModified             ; clear 68k-PD[M]
    ori     r16, r16, M68pdShouldClean          ; set user-defined bit
    stw     r16, 0(r15)

    bc      BO_IF_NOT, bM68pdInHTAB, vmRet1     ; clear PPC-PTE[C]
    xori    r9, r9, LpteChange                  ; (if necessary)
    bl      SaveLowerPTE
    b       vmRet1                              ; return yes!

########################################################################

VMAllocateMemory
    lwz     r7, KDP.VMPageArray(r1)
    lwz     r8, KDP.SegmentPageArrays(r1)
    cmpwi   cr6, r5, 0
    cmpw    cr7, r7, r8
    or      r7, r4, r6                          ; r4/r6 are page numbers?
    rlwinm. r7, r7, 0, 0xFFF00000
    ble     cr6, vmRetNeg1
    lwz     r9, KDP.VMLogicalPages(r1)
    bne     cr7, vmRetNeg1                      ; diff page arrays: already inited?
    mr      r7, r4
    bne     vmRetNeg1
    mr      r4, r9
    slwi    r6, r6, 12
    subi    r5, r5, 1

@for_each_logical_page
    subi    r4, r4, 1
    bl      PageInfo                            
    bcl     BO_IF, bM68pdInHTAB, DeletePTE      ; clear from HTAB

    lwz     r9, KDP.VMLogicalPages(r1)
    subf    r8, r4, r9
    cmplw   cr7, r5, r8
    and.    r8, r16, r6
    bge     cr7, @for_each_logical_page
    bne     @for_each_logical_page

    cmpwi   cr6, r6, 0
    beq     cr6, VMAllocateMemory_0xc0
    slwi    r8, r5, 2
    lwzx    r8, r15, r8
    slwi    r14, r5, 12
    add     r14, r14, r16
    xor     r8, r8, r14
    rlwinm. r8, r8,  0,  0, 19
    bne     @for_each_logical_page

VMAllocateMemory_0xc0
    lis     r9, 4
    cmplw   cr7, r7, r9
    rlwinm. r9, r7,  0,  0, 11
    bge     cr7, vmRetNeg1
    bne     vmRetNeg1
    lwz     r14, KDP.CurMap.SegMapPtr(r1)
    rlwinm  r9, r7, 19, 25, 28
    lwzx    r14, r14, r9
    clrlwi  r9, r7,  0x10
    lhz     r8,  0x0000(r14)
    b       VMAllocateMemory_0xf4

VMAllocateMemory_0xf0
    lhzu    r8,  0x0008(r14)

VMAllocateMemory_0xf4
    lhz     r16,  0x0002(r14)
    subf    r8, r8, r9
    cmplw   cr7, r8, r16
    ble     cr7, VMAllocateMemory_0xf0
    add     r8, r8, r5
    cmplw   cr7, r8, r16
    ble     cr7, vmRetNeg1
    lwz     r16,  0x0004(r14)
    slwi    r8, r7, 16
    andi.   r16, r16,  0xe01
    cmpwi   r16,  0xa01
    or      r8, r8, r5
    addi    r5, r5,  0x01
    bne     vmRetNeg1
    stw     r8,  0x0000(r14)
    bnel    cr6, VMAllocateMemory_0x2e8
    rotlwi  r15, r15,  0x0a
    ori     r15, r15,  0xc00
    stw     r15,  0x0004(r14)
    lwz     r7, KDP.VMPhysicalPages(r1)
    subf    r7, r5, r7
    stw     r7, KDP.VMPhysicalPages(r1)
    stw     r7, KDP.VMLogicalPages(r1)
    slwi    r8, r7, 12
    stw     r8, KDP.SysInfo.UsableMemorySize(r1)
    stw     r8, KDP.SysInfo.LogicalMemorySize(r1)

    addi    r14, r1, 120
    lwz     r15,  KDP.VMPageArray(r1)
    li      r8, 0
    addi    r7, r7, -0x01
    ori     r8, r8, 0xffff

VMAllocateMemory_0x34c
    cmplwi  r7,  0xffff
    lwzu    r16,  0x0008(r14)
    rotlwi  r9, r15,  0x0a
    ori     r9, r9,  0xc00
    stw     r8,  0x0000(r16)
    stw     r9,  0x0004(r16)
    addis   r15, r15,  0x04
    addis   r7, r7, -0x01
    bgt     VMAllocateMemory_0x34c
    sth     r7,  0x0002(r16)
    b       vmRet1



VMAllocateMemory_0x2e8
    lwz     r16,  0x0000(r15)
    lwz     r7, KDP.VMPhysicalPages(r1)
    lwz     r8,  KDP.VMPageArray(r1)
    slwi    r7, r7,  2
    add     r7, r7, r8
    slwi    r8, r5,  2
    subf    r7, r8, r7
    cmplw   r15, r7
    beqlr   
    subi    r7, r7, 4

VMAllocateMemory_0x310
    lwzx    r9, r15, r8
    cmplw   r15, r7
    stw     r9,  0x0000(r15)
    addi    r15, r15,  0x04
    blt     VMAllocateMemory_0x310

VMAllocateMemory_0x324
    cmpwi   r8,  0x04
    subi    r8, r8, 4
    stwu    r16,  0x0004(r7)
    addi    r16, r16,  0x1000
    bgt     VMAllocateMemory_0x324
    blr     

########################################################################

; Given the index of a page (r4/A0), this function queries its 68k Page
; Descriptor (PD) and, if it is currently in the HTAB, its PowerPC Page
; Table Entry (PTE). This information is returned in registers, with the
; attribute flags of the 68k PD additionally placed in Condition Register
; bits for easy testing. The page must be within the VM address space
; (i.e. < VMLogicalPages), or cr4_lt will be cleared to indicate an error.
; VMLogicalPages must be passed in r9 (as set by VMDispatch).

; Return values:
;   if in paged area: cr4_lt         =  1
;                     r16/r15/cr5-7  =  68k Page Descriptor [PD/pointer/attr-bits]
;                     r8/r9/r14      =  PowerPC Page Table Entry [PTE-high/PTE-low/pointer]
;
;   if not paged:     cr4_lt         =  0
;                     r16/cr5-7      =  fake 68k Page Descriptor [PD/attr-bits]
;                     r15            =  PMDT pointer

PageInfo
    cmplw   cr4, r4, r9
    lwz     r15, KDP.VMPageArray(r1)        ; r15 = Page List base
    slwi    r8, r4, 2                       ; r18 = Page List Entry offset
    bge     cr4, @not_par

@paged ; 
    lwzux   r16, r15, r8                    ; Get Page List Entry (will return ptr in r15)
    lwz     r14, KDP.HTABORG(r1)            ; ...which might point to a Page Table Entry
    mtcrf   %00000111, r16                  ; Set all flags in CR (but not RealPgNum)
    rlwinm  r8, r16, 23, 9, 28              ; r8 = Page Table Entry offset
    rlwinm  r9, r16, 0, 0, 19
    bclr    BO_IF_NOT, bM68pdInHTAB                   ; Page not in Page Table, so return the Page List Entry.
    bc      BO_IF_NOT, bM68pdResident, SystemCrash      ; panic if the PTE is in the HTAB but isn't mapped to a real page??

    lwzux   r8, r14, r8                     ; r8/r9 = PTE
    lwz     r9, 4(r14)
    mtcrf   %10000000, r8                   ; set CR bit 0 to Valid bit
    rlwimi  r16, r9, 29, 27, 27             ; Memcoher = Change (for return flags)
    rlwimi  r16, r9, 27, 28, 28             ; Guardwrite = Reference (for return flags)
    mtcrf   %00000111, r16
    bclr    BO_IF, 0                        ; Page in Page Table, so return the Page Table Entry.
    bl      SystemCrash                     ; (Crash if PTE is invalid)

@not_par ; Code outside VM Manager address space
    lis     r9, 4                           ; Check that page is outside VM Manager's 0-1GB area but
    cmplw   cr4, r4, r9                     ; still a valid page number (i.e. under 0x100000)
    rlwinm. r9, r4, 0, 0xFFF00000
    blt     cr4, vmRetNeg1             ; (Else return -1)
    bne     vmRetNeg1

    lwz     r15, KDP.CurMap.SegMapPtr(r1)   ; r15 = Segment Map base
    rlwinm  r9, r4, 19, 25, 28              ; r9 = offset into Segment Map = segment number * 8
    lwzx    r15, r15, r9                    ; Ignore Seg flags, get pointer into Page Map
    clrlwi  r9, r4, 16                      ; r9 = index of this page within its Segment

    lhz     r8, PMDT.PageIdx(r15)              ; Big ugly loop to find the relevant Page Map Entry
    b       @pmloop_enter
@pmloop
    lhzu    r8, PMDT.Size(r15)               ; PMDT.PageIdx of next entry
@pmloop_enter
    lhz     r16, PMDT.PageCount(r15)
    subf    r8, r8, r9
    cmplw   cr4, r8, r16
    bgt     cr4, @pmloop                    ; Nope, not this entry

    lwz     r9, PMDT.Word2(r15)
    andi.   r16, r9, Pattr_NotPTE | Pattr_PTE_Single
    cmpwi   cr6, r16, Pattr_PTE_Single
    cmpwi   cr7, r16, Pattr_NotPTE | Pattr_PTE_Single
    beq     @range_pmdt
    beq     cr6, @single_pmdt
    bne     cr7, vmRetNeg1

    slwi    r8, r8,  2
    rlwinm  r15, r9, 22,  0, 29
    crset   cr4_lt                          ; return "is paged"
    b       @paged

@range_pmdt
    slwi    r8, r8, 12
    add     r9, r9, r8
@single_pmdt
    rlwinm  r16, r9, 0, 0xFFFFF000          ; fabricate a 68k Page Descriptor
    crclr   cr4_lt                          ; return "is not paged"
    rlwinm  r9, r9,  0, ~PMDT_68k
    _mvbit  r16, bM68pdCacheinhib, r9, bLpteInhibcache
    _mvbit  r16, bM68pdCacheNotIO, r9, bLpteWritethru
    xori    r16, r16, M68pdCacheNotIO
    _mvbit  r16, bM68pdModified, r9, bLpteChange
    _mvbit  r16, bM68pdUsed, r9, bLpteChange
    _mvbit  r16, bM68pdWriteProtect, r9, bLpteP1
    ori     r16, r16, M68pdResident

    mtcrf   %00000111, r16                  ; extract flags from it
    blr     

########################################################################

SavePTEAnd68kPD
    stw     r16, 0(r15)     ; save r16 (PD) into r15 (PD ptr)
SavePTE
    stw     r8, 0(r14)      ; save r8 (upper PTE) into r14 (PTE ptr)
SaveLowerPTE
    stw     r9, 4(r14)      ; save r9 (lower PTE) into r14 (PTE ptr) + 4

    slwi    r8, r4, 12      ; trash TLB
    sync
    tlbie   r8
    sync    

    blr

########################################################################

DeletePTE
    lwz     r8, KDP.NKInfo.HashTableDeleteCount(r1)
    rlwinm  r16, r16, 0, ~M68pdInHTAB
    addi    r8, r8, 1
    stw     r8, KDP.NKInfo.HashTableDeleteCount(r1)
    rlwimi  r16, r9, 0, 0xFFFFF000      ; edit new 68k PD

    _clrNCBCache scr=r8                 ; page can now move, so clr NCBs

    li      r8, 0                       ; zero new PPC PTE
    li      r9, 0

    b       SavePTEAnd68kPD

########################################################################

; Calculate a new PowerPC PTE for a page that is not currently in the
; HTAB. The new PTE (and new ptr) will be in the usual r8/r9 and r14, and
; the new 68k PD (and unchanged ptr) will be in the usual r16 and r15.
; Because it tries a quick path but falls back on the big fat PutPTE, this
; function may or may not actually put the PowerPC and 68k structures into
; place. The caller must do this.

QuickCalcPTE
    lwz     r8, KDP.PTEGMask(r1)        ; Calculate hash to find PTEG
    lwz     r14, KDP.HTABORG(r1)
    slwi    r9, r4, 12
    mfsrin  r6, r9
    xor     r9, r6, r4
    slwi    r7, r9, 6
    and     r8, r8, r7

    lwzux   r7, r14, r8                 ; Find an invalid PTE in the right PTEG...
    lwz     r8, 8(r14)
    lwz     r9, 16(r14)
    lwz     r5, 24(r14)
    cmpwi   cr0, r7, 0
    cmpwi   cr1, r8, 0
    cmpwi   cr2, r9, 0
    cmpwi   cr3, r5, 0
    bge     cr0, @pte_at_r14
    bge     cr1, @pte_at_r14_plus_8
    bge     cr2, @pte_at_r14_plus_16
    bge     cr3, @pte_at_r14_plus_24
    lwzu    r7, 32(r14)
    lwz     r8, 8(r14)
    lwz     r9, 16(r14)
    lwz     r5, 24(r14)
    cmpwi   cr0, r7, 0
    cmpwi   cr1, r8, 0
    cmpwi   cr2, r9, 0
    cmpwi   cr3, r5, 0
    bge     cr0, @pte_at_r14
    bge     cr1, @pte_at_r14_plus_8
    bge     cr2, @pte_at_r14_plus_16
    blt     cr3, @heavyweight           ; (no free slot, so use PutPTE and rerun PageInfo)
@pte_at_r14_plus_24
    addi    r14, r14, 8
@pte_at_r14_plus_16
    addi    r14, r14, 8
@pte_at_r14_plus_8
    addi    r14, r14, 8
@pte_at_r14                             ; ... and put a pointer in r14.

; Quick path: there is a PTE slot that the caller can fill
    lwz     r9, KDP.NKInfo.HashTableCreateCount(r1)
    rlwinm  r8, r6,  7, UpteVSID            ; r8 will be new upper PTE
    addi    r9, r9, 1
    stw     r9, KDP.NKInfo.HashTableCreateCount(r1)
    rlwimi  r8, r4, 22, UpteAPI
    lwz     r9, KDP.PageAttributeInit(r1)   ; r9 will be new lower PTE
;    _ori    r8, r8, UpteValid
    nop
    _mvbit  r9, bLpteReference, r16, bM68pdUsed
    _mvbit  r9, bLpteChange, r16, bM68pdModified
    _mvbit  r9, bLpteInhibcache, r16, bM68pdCacheinhib
    _mvbit  r9, bLpteWritethru, r16, bM68pdCacheNotIO
    xori    r9, r9, M68pdCacheinhib
    _mvbit  r9, bLpteP1, r16, bM68pdWriteProtect

    lwz     r7, KDP.HTABORG(r1)
    ori     r16, r16, M68pdInHTAB | M68pdResident
    subf    r7, r7, r14
    rlwimi  r16, r7, 9, 0xFFFFF000      ; put PTE ptr info into 68k PD
    blr     

@heavyweight ; Slow path: the full PutPTE, with all its weird registers!
    mr      r7, r27
    mr      r8, r29
    mr      r9, r30
    mr      r5, r31
    mr      r16, r28
    mr      r14, r26
    mflr    r6
    slwi    r27, r4, 12
    bl      PutPTE
    bnel    SystemCrash
    mr      r27, r7
    mr      r29, r8
    mr      r30, r9
    mr      r31, r5
    mr      r28, r16
    mr      r26, r14
    mtlr    r6

    lwz     r9, KDP.VMLogicalPages(r1)
    b       PageInfo                    ; <= r4

########################################################################

; Assumes that the page numbered r4 is within the paged area, resident,
; and not in the HTAB. Returns a physical pointer in r9.

QuickGetPhysical
    addi    r8, r1, KDP.SegmentPageArrays
    lwz     r9, KDP.VMPhysicalPages(r1)
    rlwimi  r8, r7, 18, 0xF * 4
    cmplw   r7, r9
    lwz     r8, 0(r8)
    rlwinm  r7, r7, 2, 0xFFFF * 4
    bge     vmRetNeg1
    lwzx    r9, r8, r7              ; r9 = 68k PD
    rlwinm  r9, r9, 0, 0xFFFFF000
    blr     
