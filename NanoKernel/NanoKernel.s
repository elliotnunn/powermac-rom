    include 'InfoRecords.a'

    include 'NKMacros.s'
    include 'NKEquates.s'

CodeBase
    include 'NKInit.s'
    include 'NKSystemCrash.s'
    include 'NKHotInts.s'

; Persistent MemRetry registers:
;   r17 = status (0-5 MRRestab entry || 6-10 src/dest register || 11-15 base register || 21-25 ?? || 26-30 access len || 31 0=Store/1=Load)
;   r18 = EA of memory
;   r19 = EA of byte after memory
;   r20/r21 = loaded data/data to store

; Other MemRetry registers:
;   r14 = saved MSR
;   r15 = temp MSR
;   r16 = Flags
;   r22/r23 = scratch
;   r24 = saved VecBase
;   r25 = MemRetry ptr (do not trust low 10 bits)
;   r26 = Optab entry (sec routine ptr in low 8 bits might be set on DSI)
;   r27 = instruction
;   r28 = offset of register field in EWA (= reg num * 4)
;   r29/r31 = scratch

    _align 10
MRBase
    include 'MROptabCode.s'
    include 'MRMemtabCode.s'
    include 'MRInterrupts.s'
    include 'MROptab.s'
    include 'MRMemtab.s'
    include 'MRRestab.s'

    include 'NKColdInts.s'
    include 'NKMemory.s'
    include 'NKExceptions.s'
    include 'NKFloatingPt.s'
    include 'NKSoftInts.s'
    include 'NKLegacyVM.s'
