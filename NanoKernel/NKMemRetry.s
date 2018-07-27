; Control flow between PRIMARY and SECONDARY optab routines:

; INTERRUPT HANDLER sets:
;  r14 = original interrupt MSR
;  r15 = MSR | MSR[DR]
;  r17 = pretend inst: 0-5 from optab || 6-10 rS/rD || 11-15 rA || 21-25 zero || 26-31 from optab
;  r18 = effective address attempted
;  r25 = dirty MRBase ptr
;  r26 = OpTab entry
;  r27 = instruction
;  LR = r25 = address of primary routine (jumped to)

; PRIMARY ROUTINE

; LOOP until SECONDARY ROUTINE calls, or is, an exit routine
    ; MRPriDone accepts:
    ;  r17 = pretend inst: 0-5 from optab || 6-10 rS/rD || 11-15 rA || 21-26 ?? || 27-30 accessLen || 31 isLoad (NB: what about bottom 6 bits??)
    ;  r19 = address first byte *after* the string to be accessed
    ;  r25 = dirty MRBase ptr
    ;  r26 = the original OpTab entry
    ;  EQ = should continue (NE => skip to MRDoSecondary)

    ; MRPriDone sets:
    ;  r25 = address of secondary routine
    ;  MSR = r15
    ;  SPRG3 = VecTblMemRetry
    ;  LR = r22 = address of MemAccess routine (jumped to)

    ; MemAccess routine accepts:
    ;  r17 = pretend inst as noted above (will be modified)
    ;  r19 = address first byte *after* the string to be accessed (not modified)
    ;  r20/r21 = right-justified data (stores only)

    ; MemAccess routine sets:
    ;  r17 = same but with len field decremented
    ;  r20/r21 = right-justified data (loads only)
    ;  r26 = scratch

    ; MRDoSecondary sets:
    ;  r17 = pretend inst as above
    ;  MSR = r14
    ;  SPRG3 = r24
    ;  userspace register rA in EWA = r18 (EA), and CR3.SO = 1 (skipped for r0 or if CR3.EQ)
    ;  LR = r25 = address of secondary routine (jumped to)

    ; SECONDARY ROUTINE

; EXIT ROUTINE



; registers in broad terms:
; r16 Flags (why not r7?)
;*r17 Status
;*r18 effective address
;*r19 end address
;*r20/r21 data
; r25 MemRetry pointer (often dirty)
; r26 OpTab entry
; r27 instruction


    _align 10
MRBase
    INCLUDE 'MROptabCode.s' ; c00:1154
    INCLUDE 'MRMemtabCode.s' ; 1154:13f4
    INCLUDE 'MRInterrupts.s' ; 13f4:14f4
    INCLUDE 'MROptab.s' ; 14f4:16f4
    INCLUDE 'MRMemtab.s' ; 16f4:17f4
;   INCLUDE 'MRUnknown.s' ; 17f4:1874
MRUnknown
    dcb.b 128, 0

    END

; There is definitely some structure here -- but what does it mean?? Crack the bastard...

;   metatabLine  %0001, MRSecLoad        ; 0
;   metatabLine  %0001, MRSecLoad        ; 1
;   metatabLine  %0001, MRSecLoad        ; 2
;   metatabLine  %0001, MRSecLoad        ; 3

    metatabLine  %0001, MRSecException   ; 4
;   metatabLine  %0001, MRSecLoadExt     ; 5
;   metatabLine  %0001, MRSecLoad        ; 6
    metatabLine  %0001, MRSecException   ; 7
    metatabLine  %0001, MRSecException   ; 8
;   metatabLine  %0011, MRSecLHBRX       ; 9
;   metatabLine  %0011, MRSecLWBRX       ; 10
    metatabLine  %0001, MRSecException   ; 11
    metatabLine  %0001, MRSecException   ; 12
    metatabLine  %0001, MRSecException   ; 13
;   metatabLine  %0001, MRSecLFSu        ; 14
;   metatabLine  %0001, MRSecLFDu        ; 15

;   metatabLine  %0001, MRSecDone        ; 16
;   metatabLine  %0001, MRSecDone        ; 17
;   metatabLine  %0001, MRSecDone        ; 18
;   metatabLine  %0001, MRSecDone        ; 19

;   metatabLine  %0001, MRSecLWARX       ; 20 ; MRSecLoad
;   metatabLine  %0001, MRSecException   ; 21
;   metatabLine  %0001, MRSecSTWCX       ; 22 ; MRSecDone
;   metatabLine  %0001, MRSecException   ; 23

    metatabLine  %0001, MRSecException   ; 24
    metatabLine  %0001, MRSecException   ; 25
;   metatabLine  %0011, MRSecLMW         ; 26
;   metatabLine  %0011, MRSecException   ; 27
    metatabLine  %0001, MRSecException   ; 28
    metatabLine  %0001, MRSecException   ; 29
;   metatabLine  %0011, MRSecSTMW        ; 30
;   metatabLine  %0011, MRSecException   ; 31


;   metatabLine  %0011, MRSecLSWix       ; 32
    metatabLine  %0011, MRSecLSWix       ; 33
    metatabLine  %0011, MRSecLSWix       ; 34
    metatabLine  %0011, MRSecLSWix       ; 35

;   metatabLine  %0011, MRSecStrStore    ; 36
    metatabLine  %0011, MRSecStrStore    ; 37
    metatabLine  %0011, MRSecStrStore    ; 38
    metatabLine  %0011, MRSecStrStore    ; 39

;   metatabLine  %0011, MRSecLSCBX     ; 40
    metatabLine  %0011, MRSecLSCBX     ; 41
    metatabLine  %0011, MRSecLSCBX     ; 42
    metatabLine  %0011, MRSecLSCBX     ; 43
    metatabLine  %0011, MRSecLSCBX     ; 44
    metatabLine  %0011, MRSecLSCBX     ; 45
    metatabLine  %0011, MRSecLSCBX     ; 46
    metatabLine  %0011, MRSecLSCBX     ; 47

;   metatabLine  %0011, MRSecDCBZ        ; 48
    metatabLine  %0001, MRSecException   ; 49
    metatabLine  %0001, MRSecException   ; 50
    metatabLine  %0001, MRSecException   ; 51
    metatabLine  %0001, MRSecException   ; 52 ; MRSecDone
    metatabLine  %0001, MRSecException   ; 53 ; FDP_0370
    metatabLine  %0001, MRSecException   ; 54 ; FDP_0384
    metatabLine  %0001, MRSecException   ; 55 ; FDP_0398
    metatabLine  %0001, MRSecException   ; 56 ; MRSecDone
    metatabLine  %0001, MRSecException   ; 57 ; MRSecDone
    metatabLine  %0001, MRSecException   ; 58 ; MRSecDone
    metatabLine  %0001, MRSecException   ; 59 ; MRSecDone
    metatabLine  %0001, MRSecException   ; 60
    metatabLine  %0001, MRSecException   ; 61
;   metatabLine  %0011, MRSecRedoNoTrace ; 62
;   metatabLine  %0001, MRSecException2  ; 63
