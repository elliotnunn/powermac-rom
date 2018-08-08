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

ispaged equ cr4_lt

;r4=pg, r9=areapgcnt // cr[16]=ispaged, r16/r15/cr[20-31]=68kPTE/ptr/attrs, r8/r9/r14=PTE-hi/lo/ptr

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
    cmplwi  r3, MaxVMCallCount
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
    vmtabLine   getPTEntryGivenPage     ; 19 getPTEntryGivenPage: given a page, get its 68K PTE
    vmtabLine   setPTEntryGivenPage     ; 20 setPTEntryGivenPage: given a page & 68K pte, set the real PTE
    vmtabLine   VMPTest                 ; 21 VMPTest: ask why we got this page fault
    vmtabLine   VMLRU                   ; 22 VMLRU: least recently used?
    vmtabLine   VMMarkUndefined         ; 23 VMMarkUndefined
    vmtabLine   VMMakePageWriteThrough  ; 24 VMMakePageWriteThrough
    vmtabLine   VMAllocateMemory        ; 25 VMAllocateMemory: Page:A0, Count:A1, BusAlignMask:D1

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
    lwz     r8, KDP.PARPerSegmentPLEPtrs + 0(r1)
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
    addi    r3, r1, KDP.PARPerSegmentPLEPtrs
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
    bl      RemovePTEFromHTAB

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
    bl      major_0x09c9c
    stw     r9,  KDP.VMPageArray(r1)
    mr      r15, r9
    srwi    r7, r5, 12
    add     r7, r7, r6
    addi    r7, r7, -0x01
    bl      major_0x09c9c
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
    bl      major_0x09c9c
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
    lwz     r8, KDP.PARPerSegmentPLEPtrs + 0(r1)
    stw     r7, KDP.VMLogicalPages(r1)
    stw     r8, KDP.VMPageArray(r1)

    b       vmRet

########################################################################

VMExchangePages
    bl      PageInfo
    bc      BO_IF_NOT, ispaged, vmRetNeg1               ; must be in pageable area
    bc      BO_IF, 21, vmRetNeg1
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1       ; must be resident
    bc      BO_IF, bM68pteInhibcache, vmRetNeg1         ; must not have special properties
    bc      BO_IF_NOT, bM68pteNonwritethru, vmRetNeg1
    bcl     BO_IF, M68pteInHTAB, RemovePTEFromHTAB      ; if in HTAB, must be removed
    mr      r6, r15                                     ; r6 = src 68k PTE ptr

    mr      r4, r5
    mr      r5, r16                                     ; r5 = src 68k PTE
    lwz     r9, KDP.VMLogicalPages(r1)
    bl      PageInfo
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    bc      BO_IF, 21, vmRetNeg1
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1
    bc      BO_IF, bM68pteInhibcache, vmRetNeg1
    bc      BO_IF_NOT, bM68pteNonwritethru, vmRetNeg1
    bcl     BO_IF, M68pteInHTAB, RemovePTEFromHTAB

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
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1
    srwi    r3, r9, 12
    b       vmRet

########################################################################

getPTEntryGivenPage
    bl      PageInfo
    mr      r3, r16
    bc      BO_IF_NOT, bM68pteResident, vmRet
    rlwimi  r3, r9, 0, 0xFFFFF000
    b       vmRet

########################################################################

VMIsInited
    bl      PageInfo
    bc      BO_IF, bM68pteResident, vmRet1
    rlwinm  r3, r16, 16, 31, 31
    b       vmRet

########################################################################

VMIsResident
    bl      PageInfo
    rlwinm  r3, r16, 0, 1 ; M68pteResident
    b       vmRet

########################################################################

VMIsUnmodified
    bl      PageInfo
    rlwinm  r3, r16, bM68pteModified + 1, 1
    xori    r3, r3, 1
    b       vmRet

########################################################################

VMLRU ; For each resident page: save Update bit and clear original
    slwi    r9, r9, 2                   ; (r9 is VMLogicalPages)
    lwz     r15, KDP.VMPageArray(r1)
    lwz     r14, KDP.HTABORG(r1)
    add     r15, r15, r9                ; r15 = loop PageArray ptr
    srwi    r4, r9, 2                   ; r4 = loop counter

    li      r5, LpteReference           ; for clearing bits with andc
    li      r6, M68pteUpdate

@loop ; over every logical page
    lwzu    r16, -4(r15)
    subi    r4, r4, 1
    mtcr    r16
    cmpwi   r4, 0

    rlwinm  r7, r16, 23, 7FFFFFF8       ; r7 = offset of PPC PTE (if any)
    bc      BO_IF_NOT, bM68pteResident, @nonresident

    bc      BO_IF_NOT, bM68pteInHTAB, @not_in_htab
    add     r14, r14, r7                ; If PPC PTE in HTAB, copy its Ref
    lwz     r9, 4(r14)                  ; bit back to 68k PTE and clear
    _mvbit  r16, bM68pteUpdate, r9, bLpteReference
    andc    r9, r9, r5
    bl      ChangeNativeLowerPTE
    subf    r14, r7, r14
@not_in_htab

    _mvbit  r16, bM68pteSavedUpdate, r16, bM68pteUpdate
    andc    r16, r16, r6                ; save Update and clear original
    stw     r16, 0(r15)                 ; save changed 68k PTE
@nonresident

    bne     @loop
    b       vmRet

########################################################################

VMMakePageCacheable
; PPC: W=0, I=0
; 68k: Nonwritethru=0, Inhibcache=0
    bl      PageInfo
    rlwinm  r7, r16, 0, M68pteInhibcache | M68pteNonwritethru
    cmpwi   r7, M68pteNonwritethru
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1
    beq     vmRet
    bc      BO_IF_NOT, ispaged, vmRetNeg1

    bcl     BO_IF_NOT, M68pteInHTAB, VMSecondLastExportedFunc

    rlwinm  r16, r16, 0, ~(M68pteInhibcache | M68pteNonwritethru)
    rlwinm  r9, r9,  0, ~(LpteWritethru | LpteInhibcache)
    ori     r16, r16, M68pteNonwritethru
    bl      ChangeNativeAnd68kPTEs

    b       vmRet

########################################################################

VMMakePageWriteThrough
    bl      PageInfo
    rlwinm. r7, r16,  0, 25, 26
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1
    beq     vmRet
    bc      BO_IF_NOT, ispaged, VMMakePageWriteThrough_0x3c
    bcl     BO_IF_NOT, M68pteInHTAB, VMSecondLastExportedFunc
    rlwinm  r16, r16,  0, 27, 24
    rlwinm  r9, r9,  0, 27, 24
    ori     r9, r9,  0x40
    bl      ChangeNativeAnd68kPTEs
    b       VMMakePageNonCacheable_0x3c

VMMakePageWriteThrough_0x3c
    rlwinm  r7, r4, 16, 28, 31
    cmpwi   r7,  0x09
    blt     vmRetNeg1
    bc		BO_IF_NOT, M68pteInhibcache, vmRetNeg1
    lwz     r5,  0x000c(r15)
    andi.   r6, r5,  0xe01
    cmpwi   r6,  0xa01
    beq     VMMakePageWriteThrough_0xec
    addi    r15, r15, -0x08
    lwz     r5,  0x0004(r15)
    lhz     r6,  0x0000(r15)
    andi.   r5, r5,  0xc00
    lhz     r5,  0x0002(r15)
    bne     vmRetNeg1
    addi    r5, r5,  0x01
    add     r6, r6, r5
    xor     r6, r6, r4
    andi.   r6, r6,  0xffff
    bne     vmRetNeg1
    sth     r5,  0x0002(r15)
    b       PageSetCommon

VMMakePageWriteThrough_0xec
    lwz     r5,  0x0000(r15)
    lwz     r6,  0x0004(r15)
    stw     r5,  0x0008(r15)
    stw     r6,  0x000c(r15)
    slwi    r5, r4, 16
    stw     r5,  0x0000(r15)
    slwi    r5, r4, 12
    ori     r5, r5,  0x42
    stw     r5,  0x0004(r15)

########################################################################

PageSetCommon
    lwz     r15, KDP.PTEGMask(r1)
    lwz     r14, KDP.HTABORG(r1)
    slwi    r6, r4, 12
    mfsrin  r6, r6
    rlwinm  r8, r6,  7,  0, 20
    xor     r6, r6, r4
    slwi    r7, r6,  6
    and     r15, r15, r7
    rlwimi  r8, r4, 22, 26, 31
    crset   cr0_eq
    oris    r8, r8,  0x8000

PageSetCommon_0x2c
    lwzux   r7, r14, r15
    lwz     r15,  0x0008(r14)
    lwz     r6,  0x0010(r14)
    lwz     r5,  0x0018(r14)
    cmplw   cr1, r7, r8
    cmplw   cr2, r15, r8
    cmplw   cr3, r6, r8
    cmplw   cr4, r5, r8
    beq     cr1, PageSetCommon_0xc8
    beq     cr2, PageSetCommon_0xc4
    beq     cr3, PageSetCommon_0xc0
    beq     cr4, PageSetCommon_0xbc
    lwzu    r7,  0x0020(r14)
    lwz     r15,  0x0008(r14)
    lwz     r6,  0x0010(r14)
    lwz     r5,  0x0018(r14)
    cmplw   cr1, r7, r8
    cmplw   cr2, r15, r8
    cmplw   cr3, r6, r8
    cmplw   cr4, r5, r8
    beq     cr1, PageSetCommon_0xc8
    beq     cr2, PageSetCommon_0xc4
    beq     cr3, PageSetCommon_0xc0
    beq     cr4, PageSetCommon_0xbc
    crnot   2, 2
    lwz     r15, KDP.PTEGMask(r1)
    lwz     r14, KDP.HTABORG(r1)
    slwi    r6, r4, 12
    mfsrin  r6, r6
    xor     r6, r6, r4
    not     r6, r6
    slwi    r7, r6,  6
    and     r15, r15, r7
    xori    r8, r8,  0x40
    bne     PageSetCommon_0x2c
    b       vmRet

PageSetCommon_0xbc
    addi    r14, r14,  0x08

PageSetCommon_0xc0
    addi    r14, r14,  0x08

PageSetCommon_0xc4
    addi    r14, r14,  0x08

PageSetCommon_0xc8
;   bl      RemovePageFromTLB
    li      r8,  0x00
    li      r9,  0x00
    bl      ChangeNativePTE
    b       vmRet

########################################################################

VMMakePageNonCacheable
    bl      PageInfo
    rlwinm  r7, r16,  0, 25, 26
    cmpwi   r7,  0x60
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1
    beq     vmRet
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    bl		BO_IF_NOT, 20, VMSecondLastExportedFunc
    rlwinm  r9, r9,  0, 27, 24
    ori     r16, r16,  0x60
    ori     r9, r9,  0x20
    bl      ChangeNativeAnd68kPTEs

VMMakePageNonCacheable_0x3c
    rlwinm  r4, r9,  0,  0, 19
    addi    r5, r4, 0x20
    li      r7,  0x1000
    li      r8, 0x40

VMMakePageNonCacheable_0x50
    subf.   r7, r8, r7
    dcbf    r7, r4
    dcbf    r7, r5
    bne     VMMakePageNonCacheable_0x50
    b       vmRet

########################################################################

VMMarkBacking
    bl      PageInfo
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    bc      BO_IF, 21, vmRetNeg1
    bcl     BO_IF, M68pteInHTAB, RemovePTEFromHTAB
    rlwimi  r16, r5, 16, 15, 15
    li      r7,  0x01
    andc    r16, r16, r7
    stw     r16,  0x0000(r15)
    b       vmRet

########################################################################

VMMarkCleanUnused
    bl      PageInfo
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    bc      BO_IF_NOT, bM68pteResident, vmRetNeg1
    bl		BO_IF_NOT, 20, VMSecondLastExportedFunc
    li      r7,  0x180
    andc    r9, r9, r7
    ori     r16, r16,  0x100
    bl      ChangeNativeAnd68kPTEs
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

VMMarkResident
    bl      PageInfo
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    bc      BO_IF, bM68pteResident, vmRetNeg1
    bcl     BO_IF, M68pteInHTAB, SystemCrash
    rlwimi  r16, r5, 12,  0, 19
    ori     r16, r16,  0x01
    stw     r16,  0x0000(r15)
    bl      VMSecondLastExportedFunc
    bl      ChangeNativeAnd68kPTEs
    b       vmRet

########################################################################

VMPTest
    srwi    r4, r4, 12
    cmplw   r4, r9
    li      r3,  0x4000
    bge     vmRet
    bl      PageInfo
    li      r3,  0x400
    bc      BO_IF_NOT, bM68pteResident, vmRet
    li      r3,  0x00
    ori     r3, r3,  0x8000
    bc      BO_IF_NOT, bM68pteWriteProtect, vmRet
    cmpwi   r6,  0x00
    beq     vmRet
    li      r3,  0x800
    b       vmRet

########################################################################

setPTEntryGivenPage
    mr      r6, r4
    mr      r4, r5
    bl      PageInfo
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    xor     r7, r16, r6
    li      r3,  0x461
    rlwimi  r3, r16, 24, 29, 29
    and.    r3, r3, r7
    bne     vmRetNeg1
    andi.   r7, r7,  0x11c
    xor     r16, r16, r7
    stw     r16,  0x0000(r15)
    bc      BO_IF_NOT, bM68pteInHTAB, vmRet
    rlwimi  r9, r16,  5, 23, 23
    rlwimi  r9, r16,  3, 24, 24
    rlwimi  r9, r16, 30, 31, 31
    bl      ChangeNativeLowerPTE
    b       vmRet

########################################################################

VMShouldClean
    bl      PageInfo
    bc      BO_IF_NOT, bM68pteResident, vmRet0
    bc      BO_IF, bM68pteUpdate, vmRet0
    bc      BO_IF_NOT, bM68pteModified, vmRet0
    bc      BO_IF_NOT, ispaged, vmRetNeg1
    xori    r16, r16,  0x10
    ori     r16, r16,  0x100
    stw     r16,  0x0000(r15)
    bc      BO_IF_NOT, bM68pteInHTAB, vmRet1
    xori    r9, r9,  0x80
    bl      ChangeNativeLowerPTE
    b       vmRet1

########################################################################

VMAllocateMemory
    lwz     r7,  KDP.VMPageArray(r1)
    lwz     r8, KDP.PARPerSegmentPLEPtrs + 0(r1)
    cmpwi   cr6, r5,  0x00
    cmpw    cr7, r7, r8
    or      r7, r4, r6
    rlwinm. r7, r7,  0,  0, 11
    bc		BO_IF_NOT, M68pteInhibcache, vmRetNeg1
    lwz     r9, KDP.VMLogicalPages(r1)
    bne     cr7, vmRetNeg1
    mr      r7, r4
    bne     vmRetNeg1
    mr      r4, r9
    slwi    r6, r6, 12
    addi    r5, r5, -0x01

VMAllocateMemory_0x74
    addi    r4, r4, -0x01
    bl      PageInfo
    bcl     BO_IF, M68pteInHTAB, RemovePTEFromHTAB
    lwz     r9, KDP.VMLogicalPages(r1)
    subf    r8, r4, r9
    cmplw   cr7, r5, r8
    and.    r8, r16, r6
    bge     cr7, VMAllocateMemory_0x74
    bne     VMAllocateMemory_0x74
    cmpwi   cr6, r6,  0x00
    beq     cr6, VMAllocateMemory_0xc0
    slwi    r8, r5,  2
    lwzx    r8, r15, r8
    slwi    r14, r5, 12
    add     r14, r14, r16
    xor     r8, r8, r14
    rlwinm. r8, r8,  0,  0, 19
    bne     VMAllocateMemory_0x74

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

; This function gets sent an page for a page in the main mac os memory
; area and returns a bunch of useful info on it. Return values that
; mention HTAB are undefined when the PTE is not in the HTAB HTAB
; residence is determined by bit 20 (value 0x800) of the PTE. This is
; often checked by a bltl cr5

PageInfo ; r4=pg, r9=areapgcnt // cr[16]=ispaged, r16/r15/cr[20-31]=68kPTE/ptr/attrs, r8/r9/r14=PTE-hi/lo/ptr
    cmplw   cr4, r4, r9
    lwz     r15, KDP.VMPageArray(r1)        ; r15 = Page List base
    slwi    r8, r4, 2                       ; r18 = Page List Entry offset
    bge     cr4, @not_par

@ple_or_pte ; 
    lwzux   r16, r15, r8                    ; Get Page List Entry (will return ptr in r15)
    lwz     r14, KDP.HTABORG(r1)            ; ...which might point to a Page Table Entry
    mtcrf   %00000111, r16                  ; Set all flags in CR (but not RealPgNum)
    rlwinm  r8, r16, 23, 9, 28              ; r8 = Page Table Entry offset
    rlwinm  r9, r16, 0, 0, 19
    bclr    BO_IF_NOT, bM68pteInHTAB                   ; Page not in Page Table, so return the Page List Entry.
    bc      BO_IF_NOT, bM68pteResident, SystemCrash      ; panic if the PTE is in the HTAB but isn't mapped to a real page??

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
    beq     @range
    beq     cr6, @single
    bne     cr7, vmRetNeg1

    slwi    r8, r8,  2
    rlwinm  r15, r9, 22,  0, 29
    crset   cr4_lt
    b       @ple_or_pte

@range
    slwi    r8, r8, 12
    add     r9, r9, r8

@single
    rlwinm  r16, r9,  0,  0, 19
    crclr   cr4_lt
    rlwinm  r9, r9,  0, 22, 19
    rlwimi  r16, r9,  1, 25, 25
    rlwimi  r16, r9, 31, 26, 26
    xori    r16, r16,  0x20
    rlwimi  r16, r9, 29, 27, 27
    rlwimi  r16, r9, 28, 28, 28
    rlwimi  r16, r9,  2, 29, 29
    ori     r16, r16,  0x01
    mtcrf   %00000111, r16
    blr     

########################################################################

;updates stored PTE and HTAB entry for PTE
;r16 is PTE value
;r15 is address of stored PTE
;r8 is lower word of HTAB entry
;r9 is upper word of HTAB entry
;r14 is address of HTAB entry
ChangeNativeAnd68kPTEs
    stw     r16, 0(r15)
ChangeNativePTE
    stw     r8, 0(r14)
ChangeNativeLowerPTE
    stw     r9, 4(r14)      ;upper word of HTAB entry contains valid bit

    slwi    r8, r4, 12
    sync
    tlbie   r8
    sync    

    blr

########################################################################

;Removes a page from the HTAB.
;
;also updates NK statistics?
;r9 is low word of HTAB entry
;r14 ia address of HTAB entry
;r15 is address of stored PTE
;r16 is PTE value
RemovePTEFromHTAB
    lwz     r8, KDP.NKInfo.HashTableDeleteCount(r1);update a value in NanoKernelInfo
    rlwinm  r16, r16,  0, 21, 19    ;update PTE flags to indicate not in HTAB
    addi    r8, r8,  0x01
    stw     r8, KDP.NKInfo.HashTableDeleteCount(r1)
    rlwimi  r16, r9,  0,  0, 19 ;move page# back into PTE

    _clrNCBCache scr=r8

    li      r8,  0x00   ;0 upper HTAB word
    li      r9,  0x00   ;0 lower HTAB word
    b       ChangeNativeAnd68kPTEs   ;update stored PTE and invalidate HTAB entry

########################################################################

VMSecondLastExportedFunc
    lwz     r8, KDP.PTEGMask(r1)
VMLastExportedFunc
    lwz     r14, KDP.HTABORG(r1)
    slwi    r9, r4, 12
    mfsrin  r6, r9
    xor     r9, r6, r4
    slwi    r7, r9,  6
    and     r8, r8, r7
    lwzux   r7, r14, r8
    lwz     r8,  0x0008(r14)
    lwz     r9,  0x0010(r14)
    lwz     r5,  0x0018(r14)
    cmpwi   r7,  0x00
    cmpwi   cr1, r8,  0x00
    cmpwi   cr2, r9,  0x00
    cmpwi   cr3, r5,  0x00
    bge     VMLastExportedFunc_0x87
    bge     cr1, VMLastExportedFunc_0x83
    bge     cr2, VMLastExportedFunc_0x7f
    bge     cr3, VMLastExportedFunc_0x7b
    lwzu    r7,  0x0020(r14)
    lwz     r8,  0x0008(r14)
    lwz     r9,  0x0010(r14)
    lwz     r5,  0x0018(r14)
    cmpwi   r7,  0x00
    cmpwi   cr1, r8,  0x00
    cmpwi   cr2, r9,  0x00
    cmpwi   cr3, r5,  0x00
    bge     VMLastExportedFunc_0x87
    bge     cr1, VMLastExportedFunc_0x83
    bge     cr2, VMLastExportedFunc_0x7f
    blt     cr3, VMLastExportedFunc_0xd7

VMLastExportedFunc_0x7b
    addi    r14, r14,  0x08

VMLastExportedFunc_0x7f
    addi    r14, r14,  0x08

VMLastExportedFunc_0x83
    addi    r14, r14,  0x08

VMLastExportedFunc_0x87
    lwz     r9, KDP.NKInfo.HashTableCreateCount(r1)
    rlwinm  r8, r6,  7,  1, 24
    addi    r9, r9,  0x01
    stw     r9, KDP.NKInfo.HashTableCreateCount(r1)
    rlwimi  r8, r4, 22, 26, 31
    lwz     r9, KDP.PageAttributeInit(r1)
    oris    r8, r8,  0x8000
    rlwimi  r9, r16,  0,  0, 19
    rlwimi  r9, r16, 5, 23, 23
    rlwimi  r9, r16,  3, 24, 24
    rlwimi  r9, r16, 31, 26, 26
    rlwimi  r9, r16,  1, 25, 25
    xori    r9, r9,  0x40
    rlwimi  r9, r16, 30, 31, 31
    lwz     r7, KDP.HTABORG(r1)
    ori     r16, r16,  0x801
    subf    r7, r7, r14
    rlwimi  r16, r7,  9,  0, 19
    blr     

VMLastExportedFunc_0xd7
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
    b       PageInfo

########################################################################

major_0x09c9c
    addi    r8, r1, KDP.PARPerSegmentPLEPtrs
    lwz     r9, KDP.VMPhysicalPages(r1)
    rlwimi  r8, r7, 18, 28, 29
    cmplw   r7, r9
    lwz     r8,  0x0000(r8)
    rlwinm  r7, r7,  2, 14, 29
    bge     vmRetNeg1
    lwzx    r9, r8, r7
    rlwinm  r9, r9,  0,  0, 19
    blr     
