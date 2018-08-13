; Frequently-used interrupt handlers

kHotIntAlign equ 6

########################################################################

    _align kHotIntAlign
ExternalInt0
    mfsprg  r1, 0                           ; Init regs and increment ctr
    stw     r0, KDP.r0(r1)
    stw     r2, KDP.r2(r1)
    lwz     r2, KDP.NKInfo.ExternalIntCount(r1)
    stw     r3, KDP.r3(r1)
    addi    r2, r2, 1
    stw     r2, KDP.NKInfo.ExternalIntCount(r1)

    mfmsr   r2                              ; Save a self-ptr to FF880000... why?
    lis     r3, 0xFF88
    _ori    r0, r2, MsrDR
    stw     r4, KDP.r4(r1)
    stw     r5, KDP.r5(r1)
    mfsrr0  r4
    mfsrr1  r5
    mtmsr   r0
    stw     r3, 0(r3)
    mtmsr   r2
    mtsrr0  r4
    mtsrr1  r5
    lwz     r4, KDP.r4(r1)
    lwz     r5, KDP.r5(r1)

    lwz     r2, KDP.DebugIntPtr(r1)         ; Query the shared mem (debug?) for int num
    mfcr    r0
    lha     r2, 0(r2)
    lwz     r3, KDP.EmuIntLevelPtr(r1)
    rlwinm. r2, r2, 0, 0x80000007
    ori     r2, r2, 0x8000
    sth     r2, 0(r3)
    mfsprg  r2, 2
    lwz     r3, KDP.r3(r1)
    mtlr    r2
    beq     @clear                          ; 0 -> clear interrupt
    bgt     @return                         ; negative -> no interrupt flag
                                            ; positive -> post interrupt

    lwz     r2, KDP.PostIntMaskInit(r1)     ; Post an interrupt via Cond Reg
    or      r0, r0, r2

@return
    mtcr    r0                              ; Set CR and return
    lwz     r0, KDP.r0(r1)
    lwz     r2, KDP.r2(r1)
    mfsprg  r1, 1
    rfi

@clear
    lwz     r2, KDP.ClearIntMaskInit(r1)    ; Clear an interrupt via Cond Reg
    and     r0, r0, r2
    b       @return

########################################################################

    _align kHotIntAlign
IntLookupTable
    dc.b    0, 1, 2, 2, 4, 4, 4, 4
    dc.b    3, 3, 3, 3, 4, 4, 4, 4
    dc.b    4, 4, 4, 4, 4, 4, 4, 4
    dc.b    4, 4, 4, 4, 4, 4, 4, 4
    dc.b    7, 7, 7, 7, 7, 7, 7, 7
    dc.b    7, 7, 7, 7, 7, 7, 7, 7
    dc.b    7, 7, 7, 7, 7, 7, 7, 7
    dc.b    7, 7, 7, 7, 7, 7, 7, 7

    _align kHotIntAlign
ExternalInt1
    mfsprg  r1, 0                           ; Init regs and increment ctr
    stw     r0, KDP.r0(r1)
    stw     r2, KDP.r2(r1)
    lwz     r2, KDP.NKInfo.ExternalIntCount(r1)
    stw     r3, KDP.r3(r1)
    addi    r2, r2, 1
    stw     r2, KDP.NKInfo.ExternalIntCount(r1)

    lis     r2, 0x50F3                      ; Query OpenPIC at 50F2A000
    mfmsr   r3
    _ori    r0, r3, MsrDR
    stw     r4, KDP.r4(r1)
    stw     r5, KDP.r5(r1)
    mfsrr0  r4
    mfsrr1  r5
    mtmsr   r0
    li      r0, 0xC0
    stb     r0, -0x6000(r2)
    eieio
    lbz     r0, -0x6000(r2)
    mtmsr   r3
    mtsrr0  r4
    mtsrr1  r5
    lwz     r4, KDP.r4(r1)
    lwz     r5, KDP.r5(r1)

    lwz     r3, KDP.CodeBase(r1)            ; Loop that number up in the table
    rlwimi  r3, r0, 0, 0x0000003F
    lbz     r2, IntLookupTable-CodeBase(r3)
    mfcr    r0
    lwz     r3, KDP.EmuIntLevelPtr(r1)
    clrlwi. r2, r2, 29
    sth     r2, 0(r3)
    mfsprg  r2, 2
    lwz     r3, KDP.r3(r1)
    mtlr    r2
    beq     @clear                          ; 0 -> clear interrupt
                                            ; nonzero -> post interrupt

    lwz     r2, KDP.PostIntMaskInit(r1)     ; Post an interrupt via Cond Reg
    or      r0, r0, r2

@return
    mtcr    r0                              ; Set CR and return
    lwz     r0, KDP.r0(r1)
    lwz     r2, KDP.r2(r1)
    mfsprg  r1, 1
    rfi

@clear
    lwz     r2, KDP.ClearIntMaskInit(r1)    ; Clear an interrupt via Cond Reg
    and     r0, r0, r2
    b       @return

########################################################################

    _align kHotIntAlign
ExternalInt2
    mfsprg  r1, 0                           ; Init regs and increment ctr
    stw     r0, KDP.r0(r1)
    stw     r2, KDP.r2(r1)
    lwz     r2, KDP.NKInfo.ExternalIntCount(r1)
    stw     r3, KDP.r3(r1)
    addi    r2, r2, 1
    stw     r2, KDP.NKInfo.ExternalIntCount(r1)

    lis     r2, 0xF300                      ; Query OpenPIC at F3000028/C
    mfmsr   r0
    _ori    r3, r0, MsrDR
    stw     r4, KDP.r4(r1)
    stw     r5, KDP.r5(r1)
    mfsrr0  r4
    mfsrr1  r5
    mtmsr   r3
    lis     r3, 0x8000
    stw     r3, 0x28(r2)
    eieio
    lwz     r3, 0x2C(r2)
    mtmsr   r0
    mtsrr0  r4
    mtsrr1  r5
    lwz     r4, KDP.r4(r1)
    lwz     r5, KDP.r5(r1)

    mfcr    r0
                                            ; Interpret OpenPic result:
    rlwinm. r2, r3, 0, 11, 11               ; bit 11 -> 7
    li      r2, 7
    bne     @gotnum

    rlwinm  r2, r3, 0, 15, 16               ; bit 15-16/21/31 -> 4
    rlwimi. r2, r3, 0, 21, 31
    li      r2, 4
    bne     @gotnum

    rlwinm. r2, r3, 0, 18, 18               ; bit 18 -> 3
    li      r2, 3
    bne     @gotnum

    andis.  r2, r3, 0x7FEA                  ; bit 1-10/12/14/19-20 -> 2
    rlwimi. r2, r3, 0, 19, 20
    li      r2, 2
    bne     @gotnum

    extrwi. r2, r3, 1, 13                   ; bit 13 -> 1
                                            ; else -> 0

@gotnum
    lwz     r3, KDP.EmuIntLevelPtr(r1)
    sth     r2, 0(r3)
    mfsprg  r2, 2
    lwz     r3, KDP.r3(r1)
    mtlr    r2
    beq     @clear                          ; 0 -> clear interrupt
                                            ; nonzero -> post interrupt

    lwz     r2, KDP.PostIntMaskInit(r1)     ; Post an interrupt via Cond Reg
    or      r0, r0, r2

@return
    mtcr    r0                              ; Set CR and return
    lwz     r0, KDP.r0(r1)
    lwz     r2, KDP.r2(r1)
    mfsprg  r1, 1
    rfi

@clear
    lwz     r2, KDP.ClearIntMaskInit(r1)    ; Clear an interrupt via Cond Reg
    and     r0, r0, r2
    b       @return

########################################################################

    _align kHotIntAlign
DecrementerIntSys
; Increment the Sys/Alt CPU clocks, and the Dec-int counter
    mfsprg  r1, 0
    stmw    r2, KDP.r2(r1)
    mfdec   r31
    lwz     r30, KDP.OtherContextDEC(r1)

DecCommon ; DEC for Alternate=r30, System=r31
    mfxer   r29                         ; we will do carries

    lwz     r28, KDP.ProcInfo.DecClockRateHz(r1)
    stw     r28, KDP.OtherContextDEC(r1)
    mtdec   r28                         ; reset Sys and Alt decrementers

    subf    r31, r31, r28               ; System ticks actually elapsed
    subf    r30, r30, r28               ; Alternate ticks actually elapsed

    lwz     r28, KDP.NKInfo.SysContextCpuTime+4(r1)
    lwz     r27, KDP.NKInfo.SysContextCpuTime(r1)
    addc    r28, r28, r31
    addze   r27, r27
    stw     r28, KDP.NKInfo.SysContextCpuTime+4(r1)
    stw     r27, KDP.NKInfo.SysContextCpuTime(r1)

    lwz     r28, KDP.NKInfo.AltContextCpuTime+4(r1)
    lwz     r27, KDP.NKInfo.AltContextCpuTime(r1)
    addc    r28, r28, r30
    addze   r27, r27
    stw     r28, KDP.NKInfo.AltContextCpuTime+4(r1)
    stw     r27, KDP.NKInfo.AltContextCpuTime(r1)

    mtxer   r29

    stw     r0, KDP.r0(r1)
    mfsprg  r31, 1
    stw     r31, KDP.r1(r1)

    lwz     r31, KDP.NKInfo.DecrementerIntCount(r1)
    addi    r31, r31, 1
    stw     r31, KDP.NKInfo.DecrementerIntCount(r1)

    lmw     r27, KDP.r27(r1)
    mfsprg  r1, 2
    mtlr    r1
    mfsprg  r1, 1
    rfi

DecrementerIntAlt
    mfsprg  r1, 0
    stmw    r2, KDP.r2(r1)
    lwz     r31, KDP.OtherContextDEC(r1)
    mfdec   r30
    b       DecCommon

########################################################################

    _align kHotIntAlign
DataStorageInt ; to MemRetry! (see MROptab.s for register info)
    mfsprg  r1, 0
    stmw    r2, KDP.r2(r1)
    mfsprg  r11, 1
    stw     r0, KDP.r0(r1)
    stw     r11, KDP.r1(r1)

    mfsrr0  r10
    mfsrr1  r11
    mfsprg  r12, 2
    mfcr    r13

    mfmsr   r14
    _ori    r15, r14, MsrDR
    mtmsr   r15
    lwz     r27, 0(r10)                 ; r27 = instruction
    mtmsr   r14

EmulateDataAccess
    rlwinm. r18, r27, 18, 25, 29        ; r16 = 4 * rA (r0 wired to 0)
    lwz     r25, KDP.MRBase(r1)
    li      r21, 0
    beq     @r0
    lwzx    r18, r1, r18                ; r16 = contents of rA
@r0
    andis.  r26, r27, 0xec00            ; determine instruction form
    lwz     r16, KDP.Flags(r1)
    mfsprg  r24, 3
    rlwinm  r17, r27, 0, 6, 15          ; set MR status reg
    _mvbit  r16, bContextFlagTraceWhenDone, r16, bMsrSE
    bge     @xform

;dform
    rlwimi  r25, r27, 7, 26, 29
    rlwimi  r25, r27, 12, 25, 25
    lwz     r26, MROptabD-MRBase(r25)   ; last quarter of the X-form table, index = major opcode bits 51234
    extsh   r23, r27                    ; r23 = register offset field, sign-extended
    rlwimi  r25, r26, 26, 22, 29
    mtlr    r25                         ; dest = r25 = first of two function ptrs in table entry
    mtcr    r26                         ; using the flags in the arbitrary upper 16 bits of the table entry?
    add     r18, r18, r23               ; r18 = EA
    rlwimi  r17, r26, 6, 26, 5          ; set MR status reg
    blr

@xform
    rlwimi  r25, r27, 27, 26, 29
    rlwimi  r25, r27, 0, 25, 25
    rlwimi  r25, r27, 6, 23, 24
    lwz     r26, MROptabX-MRBase(r25)   ; index = extended opcode bits 8940123
    rlwinm  r23, r27, 23, 25, 29        ; need to calculate EA (this part gets rB)
    rlwimi  r25, r26, 26, 22, 29        ; prepare to jump to the primary routine
    mtlr    r25
    mtcr    r26
    lwzx    r23, r1, r23                ; get rB from saved registers
    rlwimi  r17, r26, 6, 26, 5          ; set MR status reg)
    add     r18, r18, r23               ; r18 = EA
    bclr    BO_IF_NOT, mrXformIgnoreIdxReg
    neg     r23, r23
    add     r18, r18, r23
    blr

########################################################################

    _align kHotIntAlign
AlignmentInt ; to MemRetry! (see MROptab.s for register info)
    mfsprg  r1, 0
    stmw    r2, KDP.r2(r1)

    lwz     r11, KDP.NKInfo.MisalignmentCount(r1)
    addi    r11, r11, 1
    stw     r11, KDP.NKInfo.MisalignmentCount(r1)

    mfsprg  r11, 1
    stw     r0, KDP.r0(r1)
    stw     r11, KDP.r1(r1)

    mfsrr0  r10
    mfsrr1  r11
    mfsprg  r12, 2
    mfcr    r13
    mfsprg  r24, 3
    mfdsisr r27
    mfdar   r18

    extrwi. r21, r27, 2, 15             ; determine instruction form using DSISR
    lwz     r25, KDP.MRBase(r1)
    rlwinm  r17, r27, 16, 0x03FF0000    ; insert rS/rD field from DSISR into MR status reg
    lwz     r16, KDP.Flags(r1)
    rlwimi  r25, r27, 24, 23, 29        ; look up DSISR opcode field in MROptab
    _mvbit  r16, bContextFlagTraceWhenDone, r16, bMsrSE
    bne     @xform

;dform
    lwz     r26, MROptabD-MRBase(r25)   ; last quarter of the X-form table, index = major opcode bits 51234
    mfmsr   r14
    rlwimi  r25, r26, 26, 22, 29        ; prepare to jump to the primary routine
    mtlr    r25
    _ori    r15, r14, MsrDR
    mtcr    r26
    rlwimi  r17, r26, 6, 26, 5          ; set the rest of the MR status register
    blr

@xform
    lwz     r26, MROptabX-MRBase(r25)   ; index = extended opcode bits 8940123
    mfmsr   r14
    rlwimi  r25, r26, 26, 22, 29        ; prepare to jump to the primary routine
    mtlr    r25
    _ori    r15, r14, MsrDR
    mtcr    r26
    rlwimi  r17, r26, 6, 26, 5
    bclr    BO_IF_NOT, mrSkipInstLoad
    mtmsr   r15
    lwz     r27, 0(r10)
    mtmsr   r14
    blr
