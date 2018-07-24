; Control flow between PRIMARY and SECONDARY optab routines:

; INTERRUPT HANDLER sets:
;  r14 = original interrupt MSR
;  r15 = MSR | MSR[DR]
;  r17 = pretend inst: 0-5 from optab || 6-10 rS/rD || 11-15 rA || 21-25 zero || 26-31 from optab
;  r18 = effective address attempted
;  r25 = dirty MRTop ptr
;  r26 = OpTab entry
;  r27 = instruction
;  LR = r25 = address of primary routine (jumped to)

; PRIMARY ROUTINE

; LOOP until SECONDARY ROUTINE calls, or is, an exit routine
    ; MRDoMemAccess accepts:
    ;  r17 = pretend inst: 0-5 from optab || 6-10 rS/rD || 11-15 rA || 21-27 ?? || 28-30 byteCount-1 || 31 isLoad (NB: what about bottom 6 bits??)
    ;  r19 = address first byte *after* the string to be accessed
    ;  r25 = dirty MRTop ptr
    ;  r26 = the original OpTab entry
    ;  EQ = should continue (NE => skip to MRDoneMemAccess)

    ; MRDoMemAccess sets:
    ;  r25 = address of secondary routine
    ;  MSR = r15
    ;  SPRG3 = VecTblMemRetry
    ;  LR = r22 = address of MemAccess routine (jumped to)

    ; MemAccess routine accepts:
    ;  r17 = pretend inst as noted above (will be modified)
    ;  r19 = address first byte *after* the string to be accessed (not modified)
    ;  r20/r21 = right-justified data (stores only)

    ; MemAccess routine sets:
    ;  r17 = same but with byteCount field decremented
    ;  r20/r21 = right-justified data (loads only)
    ;  r26 = scratch

    ; MRDoneMemAccess sets:
    ;  r17 = pretend inst as above
    ;  MSR = r14
    ;  SPRG3 = r24
    ;  userspace register rA in EWA = r18 (EA), and CR3.SO = 1 (skipped for r0 or if CR3.EQ)
    ;  LR = r25 = address of secondary routine (jumped to)

    ; SECONDARY ROUTINE

; EXIT ROUTINE

    _align 10
MRTop
    INCLUDE 'MROptabCode.s' ; c00:1154
    INCLUDE 'MRMemtabCode.s' ; 1154:13f4
    INCLUDE 'MRInterrupts.s' ; 13f4:14f4
    INCLUDE 'MROptab.s' ; 14f4:16f4
    INCLUDE 'MRMemtab.s' ; 16f4:17f4
    INCLUDE 'MRUnknown.s' ; 17f4:1874
