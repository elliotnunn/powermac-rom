kVersion equ 0x0101   

########################################################################

; Machine Status Register (MSR)
    _bitequate 13, MsrPOW
    _bitequate 15, MsrILE
    _bitequate 16, MsrEE
    _bitequate 17, MsrPR
    _bitequate 18, MsrFP
    _bitequate 19, MsrME
    _bitequate 20, MsrFE0
    _bitequate 21, MsrSE
    _bitequate 22, MsrBE
    _bitequate 23, MsrFE1
    _bitequate 25, MsrIP
    _bitequate 26, MsrIR
    _bitequate 27, MsrDR
    _bitequate 30, MsrRI
    _bitequate 31, MsrLE

########################################################################

; BO field values for "bc" (condition branch) instructions
BO_IF       equ 12
BO_IF_NOT   equ 4

########################################################################

; "Exception cause" codes
ecNoException               equ 0
ecSystemCall                equ 1
ecTrapInstr                 equ 2
ecFloatException            equ 3
ecInvalidInstr              equ 4
ecPrivilegedInstr           equ 5
ecMachineCheck              equ 7
ecInstTrace                 equ 8
ecInstInvalidAddress        equ 10
ecInstHardwareFault         equ 11
ecInstPageFault             equ 12
ecInstSupAccessViolation    equ 14
ecDataInvalidAddress        equ 18
ecDataHardwareFault         equ 19
ecDataPageFault             equ 20
ecDataWriteViolation        equ 21
ecDataSupAccessViolation    equ 22
ecDataSupWriteViolation     equ 23
ecUnknown24                 equ 24

########################################################################

; NanoKernel flags (often in Cond Reg or r7)
crMaskAll equ %11111111

; Bits 0-7 (CR0-CR1): Exception Cause Number (see equates)
crMaskExceptionNum equ %11000000
maskExceptionNum  equ 0xFF000000

crMaskFlags equ %00111111
maskFlags  equ 0x00FFFFFF

; Bits 8-15 (CR2-CR3) Global Flags
crMaskGlobalFlags equ %00110000
maskGlobalFlags  equ 0x00FF0000
    _bitequate 8,  GlobalFlagSystem            ; raised when System (Emulator) Context is running
    _bitequate 13, GlobalFlagMQReg             ; raised when pre-PowerPC MQ register is present

; Bits 24-31 (CR6-CR7) Context Flags
crMaskContextFlags equ %00001111
maskContextFlags  equ 0x0000FFFF
    ; Bits 20-23 (CR5) MSR Flags FE0/SE/BE/FE1:
crMaskMsrFlags equ %00000100
maskMsrFlags  equ 0x00000F00
    ; Bits 24-31 (CR6-CR7) Other Context Flags:
    _bitequate 26, ContextFlagTraceWhenDone    ; raised when MSR[SE] is up but we get an unrelated interrupt
    _bitequate 27, ContextFlagMemRetryErr      ; raised when an exception is raised during MemRetry
    _bitequate 31, ContextFlagResumeMemRetry   ; allows MemRetry to be resumed (raised by userspace?)

########################################################################

; MemRetry flags in CR3
    _bitequate cr3_lt, mrSkipInstLoad       ; misalignment handler need not read the instruction
    _bitequate cr3_gt, mrXformIgnoreIdxReg  ; instruction is X-form but without an rB field
    _bitequate cr3_eq, mrSuppressUpdate     ; instruction may not update base reg in-place
    _bitequate cr3_so, mrChangedRegInEWA    ; have "loaded" a new reg value (i.e. saved into EWA)

########################################################################

; PowerPC Page Table Entries
; (The Page Table is called the "HTAB" for "Hash Table", but Page Table
; Entries and Entry Groups are called "PTEs" and "PTEGs".)

; Upper word of a Page Table Entry (PTE):
    _bitequate 0,  UpteValid    ; [V] if valid then a signed compare will raise the LT bit
UpteVSID equ 0x7FFFFF80         ; bits 1-24 = Virtual Segment ID (allows one HTAB to hold many addr spaces)
    _bitequate 25, UpteHash     ; [H] set if this PTE is placed according to secondary hash
UpteAPI  equ 0x0000003F         ; bits 26-31 = Abbreviated Page Index (the EA bits that aren't implicit in the hash)

; Lower word of a Page Table Entry (PTE):
    ; bits 0-19 hold the Real Page Number (RPN, the address of the physical page)
    ; bits 20-22 are reserved
    _bitequate 23, LpteReference    ; [R] set by arch when page is read
    _bitequate 24, LpteChange       ; [C] set by arch when page is written
    _bitequate 25, LpteWritethru    ; [W] these are the "WIMG" memory access policy bits
    _bitequate 26, LpteInhibcache   ; [I]
    _bitequate 27, LpteMemcoher     ; [M]
    _bitequate 28, LpteGuardwrite   ; [G]
    ; bit 29 is reserved
    _bitequate 30, LpteP0           ; [P0] supervisor and user access policy bits (check these)
    _bitequate 31, LpteP1           ; [P1]

; Some combinations from the v1 Trampoline:
ATTR_RW_Locked      equ LpteMemcoher
ATTR_RW             equ LpteMemcoher | LpteP0
ATTR_RO             equ LpteMemcoher | LpteP0 | LpteP1
ATTR_IO_Locked      equ LpteInhibcache | LpteGuardwrite
ATTR_IO             equ LpteInhibcache | LpteGuardwrite | LpteP0
ATTR_RO_Quiet       equ LpteWritethru | LpteMemcoher | LpteP0 | LpteP1
ATTR_RO_Locked      equ LpteChange | LpteMemcoher | LpteP0 | LpteP1
ATTR_RO_LockedQuiet equ LpteWritethru | LpteChange | LpteMemcoher | LpteP0 | LpteP1

; "PMDTs" (described below) imitate the lower word of a PTE.

########################################################################

; "PMDTs" (PageMap somethings?) are the elements of the global PageMap.
; Each one describes how a contiguous range of effective addresses is
; stored in physical memory.

; A PMDT itself does not say which 256MB "segment" of the logical space
; space contains its area, but only describes the location and size of the
; area within a segment. Each of the four system "address spaces"
; (Supervisor, User, CPU and Overlay) has a "Segment Map": an array of 16
; pointer/segment-register pairs, one per segment. Each segment pointer
; refers to a location within the PageMap. To list the PMDTs associated
; with a segment, it is necessary to start at the referenced location
; within the PageMap and iterate over PMDTs until a special end-of-segment
; value is encountered. The SegMaps and the PageMap are initialized from
; templates in the ConfigInfo when the NanoKernel starts.

PMDT                    RECORD 0, INCR
PageIdx                 ds.w 1 ; area location within 256MB segment
PageCount               ds.w 1 ; area size in pages, minus one
Word2                   ds.l 1 ; second word is similar to a lower PTE word (20-bit RPN + 12-bit Attrs)
Size                    equ  8
    ENDR
; bits 0-19 of Word2, like a PTE, contain a Real Page Number (RPN) that can actually have several uses
; bits 20-31 of Word2 contain bits ("Pattrs") that guide PMDT interpretation (especially of RPN)

EveryPattr              equ 0xE01 ; The union of every bit below (NB: E00 bits are reserved in a PowerPC PTE)

; When Pattr_NotPTE=1, the PMDT is a pageable area or another special value:
Pattr_NotPTE            equ 0x800
Pattr_Paged             equ 0x400 ; Pageable area with RPN = (68k Page Descriptor array ptr) / 4

PMDT_InvalidAddress     equ 0xA00 ; Known combinations when Pattr_NotPTE=1...
PMDT_Available          equ 0xA01
PMDT_Paged              equ 0xC00 ; = Pattr_NotPTE + Pattr_Paged (can be created by VMAllocateMemory)

; When Pattr_NotPTE=0, the PMDT describes a non-pageable area, and these apply:
Pattr_PTE_Single        equ 0x400 ; Only one page
Pattr_PTE_Rel           equ 0x200 ; RPN is ConfigInfo-relative

PMDT_PTE_Range          equ 0x000 ; Known combinations when Pattr_NotPTE=0...
PMDT_PTE_Range_Rel      equ 0x200
PMDT_PTE_Single         equ 0x400
PMDT_PTE_Single_Rel     equ 0x600

; Other attrs (not in EveryPattr) are used, but they tend to be copied
; directly into the PTE.

########################################################################

; 68k Page Descriptors
; A handful of special PMDTs describe the MacOS "Primary Address Range"
; (the contiguous RAM starting at address 0 and containing the sys and app
; heaps etc). Instead of referring directly to physical pages, each of
; these PMDTs has in its RPN field a pointer to an array of 68k Page
; Descriptors! These are in the 68k 4k-page format, and could also be
; called 68k Page Table Entries. Besides being friendly to old 68k code
; using the VMDispatch trap (FE0A), this provides a convenient way to
; store state for individual logical pages and to allow them to use
; discontiguous physical backing.

    ; Bits 0-19:
    ;   if M68pdInHTAB: native PTE index relative to HTABORG
    ;   else:           physical page address
    _bitequate 20, M68pdInHTAB          ; [11 UR]  (reserved bit) page in PowerPC HTAB
    _bitequate 21, M68pdGlobal          ; [10 G]   kernel-held page (page immune to PFLUSH)
    _bitequate 22, M68pdFrozenUsed      ; [9 U1]   copied from Used by VMLRU
    _bitequate 23, M68pdShouldClean     ; [8 U0]   set whenever VMShouldClean returns 1
    _bitequate 24, M68pdSupProtect      ; [7 S]    supervisor access only
    _bitequate 25, M68pdCacheinhib      ; [6 CM1]  like PPC Inhibcache
    _bitequate 26, M68pdCacheNotIO      ; [5 CM0]  like inverse of PPC Writethru
    _bitequate 27, M68pdModified        ; [4 M]    like PPC Change
    _bitequate 28, M68pdUsed            ; [3 U]    like PPC Reference
    _bitequate 29, M68pdWriteProtect    ; [2 WP]
    _bitequate 30, M68pdIndirect        ; [1 PDT1] would make this a ptr to another PD (not used)
    _bitequate 31, M68pdResident        ; [0 PDT0]

    _bitequate 15, M68pdInited          ; special bit that only applies to non-resident "backing-marked" pages

; Cache Mode (CM) bits:
;   CM1/CM0  Meaning
;     00     Cachable,Write-through
;     01     Cachable,Copyback
;     10     Noncachable,Serialized
;     11     Noncachable
; Therefore CM1 (M68pdCacheinhib) should match PPC Inhibcache,
; and CM0 (M68pdCacheNotIO) should be inverse of PPC Writethru

; User Page Attribute (U) bits:
;   In the 68k arch these are user-defined, but they are exposed on
;   the external bus when the logical page is accessed.

########################################################################

VecTbl                  RECORD 0, INCR ; SPRG3 vector table (looked up by ROM vectors)
                        ds.l    1   ; 00 ; scratch for IVT
SystemReset             ds.l    1   ; 04 ; from IVT+100
MachineCheck            ds.l    1   ; 08 ; from IVT+200
DSI                     ds.l    1   ; 0c ; from IVT+300
ISI                     ds.l    1   ; 10 ; from IVT+400
External                ds.l    1   ; 14 ; from IVT+500
Alignment               ds.l    1   ; 18 ; from IVT+600
Program                 ds.l    1   ; 1c ; from IVT+700
FPUnavail               ds.l    1   ; 20 ; from IVT+800
Decrementer             ds.l    1   ; 24 ; from IVT+900
ReservedVector1         ds.l    1   ; 28 ; from IVT+a00
ReservedVector2         ds.l    1   ; 2c ; from IVT+b00
Syscall                 ds.l    1   ; 30 ; from IVT+c00
Trace                   ds.l    1   ; 34 ; from IVT+d00
FPAssist                ds.l    1   ; 38 ; from IVT+e00
PerfMonitor             ds.l    1   ; 3c ; from IVT+f00
                        ds.l    1   ; 40
                        ds.l    1   ; 44
                        ds.l    1   ; 48
                        ds.l    1   ; 4c ; Vectors from here downwards are called from
                        ds.l    1   ; 50 ; odd places in the IVT
                        ds.l    1   ; 54
                        ds.l    1   ; 58 ; seems AltiVec-related
ThermalEvent            ds.l    1   ; 5c
                        ds.l    1   ; 60
                        ds.l    1   ; 64
                        ds.l    1   ; 68
                        ds.l    1   ; 6c
                        ds.l    1   ; 70
                        ds.l    1   ; 74
                        ds.l    1   ; 78
                        ds.l    1   ; 7c
OtherTrace              ds.l    1   ; 80
                        ds.l    1   ; 84
                        ds.l    1   ; 88
                        ds.l    1   ; 8c
                        ds.l    1   ; 90
                        ds.l    1   ; 94
                        ds.l    1   ; 98
                        ds.l    1   ; 9c
                        ds.l    1   ; a0
                        ds.l    1   ; a4
                        ds.l    1   ; a8
                        ds.l    1   ; ac
                        ds.l    1   ; b0
                        ds.l    1   ; b4
                        ds.l    1   ; b8
                        ds.l    1   ; bc ; from IVT+0
Size                    equ     *
    ENDR

########################################################################

KCallTbl                RECORD 0, INCR ; NanoKernel call table
ReturnFromException     ds.l    1   ; 00, trap  0
RunAlternateContext     ds.l    1   ; 04, trap  1
ResetSystem             ds.l    1   ; 08, trap  2 ; 68k RESET
VMDispatch              ds.l    1   ; 0c, trap  3 ; 68k $FE0A
PrioritizeInterrupts    ds.l    1   ; 10, trap  4
PowerDispatch           ds.l    1   ; 14, trap  5 ; 68k $FEOF
RTASDispatch            ds.l    1   ; 18, trap  6
CacheDispatch           ds.l    1   ; 1c, trap  7
MPDispatch              ds.l    1   ; 20, trap  8
                        ds.l    1   ; 24, trap  9
                        ds.l    1   ; 28, trap 10
                        ds.l    1   ; 2c, trap 11
CallAdapterProcPPC      ds.l    1   ; 30, trap 12
                        ds.l    1   ; 34, trap 13
CallAdapterProc68k      ds.l    1   ; 38, trap 14
SystemCrash             ds.l    1   ; 3c, trap 15
Size                    equ     *
    ENDR

########################################################################

MemMap      RECORD 0, INCR
SegMapPtr   ds.l 1 ; ptr to array of sixteen 8-byte (ptr/flags) records; ptr is to first PMDT for seg
BatMap      ds.l 1 ; packed array of 4-bit indices into BATs
    ENDR

########################################################################

BAT         RECORD 0, INCR
U           ds.l 1
L           ds.l 1
    ENDR

########################################################################

KDP                     RECORD 0, INCR ; Kernel Data Page
r0                      ds.l    1   ; 000 ; used for quick register saves at interrupt time
r1                      ds.l    1   ; 004
r2                      ds.l    1   ; 008
r3                      ds.l    1   ; 00c
r4                      ds.l    1   ; 010
r5                      ds.l    1   ; 014
r6                      ds.l    1   ; 018
r7                      ds.l    1   ; 01c
r8                      ds.l    1   ; 020
r9                      ds.l    1   ; 024
r10                     ds.l    1   ; 028
r11                     ds.l    1   ; 02c
r12                     ds.l    1   ; 030
r13                     ds.l    1   ; 034
r14                     ds.l    1   ; 038
r15                     ds.l    1   ; 03c
r16                     ds.l    1   ; 040
r17                     ds.l    1   ; 044
r18                     ds.l    1   ; 048
r19                     ds.l    1   ; 04c
r20                     ds.l    1   ; 050
r21                     ds.l    1   ; 054
r22                     ds.l    1   ; 058
r23                     ds.l    1   ; 05c
r24                     ds.l    1   ; 060
r25                     ds.l    1   ; 064
r26                     ds.l    1   ; 068
r27                     ds.l    1   ; 06c
r28                     ds.l    1   ; 070
r29                     ds.l    1   ; 074
r30                     ds.l    1   ; 078
r31                     ds.l    1   ; 07c

SegMaps
SegMap32SupInit         ds.l    32  ; 080:100
SegMap32UsrInit         ds.l    32  ; 100:180
SegMap32CPUInit         ds.l    32  ; 180:200
SegMap32OvlInit         ds.l    32  ; 200:280

BATs                    ds.l    32  ; 280:300

CurIBAT0                ds BAT      ; 300:308
CurIBAT1                ds BAT      ; 308:310
CurIBAT2                ds BAT      ; 310:318
CurIBAT3                ds BAT      ; 318:320
CurDBAT0                ds BAT      ; 320:328
CurDBAT1                ds BAT      ; 328:330
CurDBAT2                ds BAT      ; 330:338
CurDBAT3                ds BAT      ; 338:340

NCBPointerCache
NCBCacheLA0             ds.l    1   ; 340
NCBCachePA0             ds.l    1   ; 344
NCBCacheLA1             ds.l    1   ; 348
NCBCachePA1             ds.l    1   ; 34c
NCBCacheLA2             ds.l    1   ; 350
NCBCachePA2             ds.l    1   ; 354
NCBCacheLA3             ds.l    1   ; 358
NCBCachePA3             ds.l    1   ; 35c
NCBPointerCacheEnd

VecTblSystem            ds  VecTbl  ; 360:420 ; user-space (system context)
VecTblAlternate         ds  VecTbl  ; 420:4e0 ; user-space (alternate context)
VecTblMemRetry          ds  VecTbl  ; 4e0:5a0 ; kernel MemRetry code

FloatScratch            ds.d    1   ; 5a0:5a8
                        ds.l    1   ; 5a8
                        ds.l    1   ; 5ac
PhysicalPageArray       ds.l    4   ; 5b0:5c0 ; actually one ptr per segment
FloatingPtTemp1         ds.l    1   ; 5c0
FloatingPtTemp2         ds.l    1   ; 5c4

SupervisorMap           ds MemMap   ; 5c8:5d0
UserMap                 ds MemMap   ; 5d0:5d8
CpuMap                  ds MemMap   ; 5d8:5e0
OverlayMap              ds MemMap   ; 5e0:5e8
CurMap                  ds MemMap   ; 5e8:5f0

KCallTbl                ds KCallTbl ; 5f0:630

ConfigInfoPtr           ds.l    1   ; 630
EDPPtr                  ds.l    1   ; 634
KernelMemoryBase        ds.l    1   ; 638
KernelMemoryEnd         ds.l    1   ; 63c
LowMemPtr               ds.l    1   ; 640 ; physical address of MacOS Low Memory
SharedMemoryAddr        ds.l    1   ; 644 ; debug?
EmuKCallTblPtrLogical   ds.l    1   ; 648
CodeBase                ds.l    1   ; 64c
MRBase                  ds.l    1   ; 650
ECBPtrLogical           ds.l    1   ; 654 ; Emulator/System ContextBlock
ECBPtr                  ds.l    1   ; 658
ContextPtr              ds.l    1   ; 65c ; moved to EWA (per-CPU) in NKv2
Flags                   ds.l    1   ; 660 ; moved to EWA (per-CPU) in NKv2
Enables                 ds.l    1   ; 664 ; moved to EWA (per-CPU) in NKv2
OtherContextDEC         ds.l    1   ; 668 ; ticks that the *inactive* context has left out of 1s
PageMapEndPtr           ds.l    1   ; 66c ; et at the same time as PageMapStartPtr below
TestIntMaskInit         ds.l    1   ; 670
PostIntMaskInit         ds.l    1   ; 674 ; CR flags to set when posting an interrupt to the Emulator
ClearIntMaskInit        ds.l    1   ; 678 ; CR flags to clear (as mask) when clearing an interrupt
EmuIntLevelPtr          ds.l    1   ; 67c ; physical ptr to an Emulator global
DebugIntPtr             ds.l    1   ; 680 ; within (debug?) shared memory
PageMapStartPtr         ds.l    1   ; 684
PageAttributeInit       ds.l    1   ; 688 ; defaults for PLE/PTE?
HtabSingleEA            ds.l    1   ; 68c ; PMDT_PTE_Single page most recently put into HTAB
HtabSinglePTE           ds.l    1   ; 690 ; and a ptr to its PTE
HtabLastEA              ds.l    1   ; 694
HtabLastPTE             ds.l    1   ; 698
HtabLastOverflow        ds.l    1   ; 69c
PTEGMask                ds.l    1   ; 6a0
HTABORG                 ds.l    1   ; 6a4
VMLogicalPages          ds.l    1   ; 6a8 ; size of VM Manager's address space
VMPhysicalPages         ds.l    1   ; 6ac ; how many pages VM Manager may use
VMPageArray             ds.l    1   ; 6b0 ; array of 68k Page Descriptors

                        org     0x700
CrashTop
CrashR0                 ds.l    1   ; 700
CrashR1                 ds.l    1   ; 704
CrashR2                 ds.l    1   ; 708
CrashR3                 ds.l    1   ; 70c
CrashR4                 ds.l    1   ; 710
CrashR5                 ds.l    1   ; 714
CrashR6                 ds.l    1   ; 718
CrashR7                 ds.l    1   ; 71c
CrashR8                 ds.l    1   ; 720
CrashR9                 ds.l    1   ; 724
CrashR10                ds.l    1   ; 728
CrashR11                ds.l    1   ; 72c
CrashR12                ds.l    1   ; 730
CrashR13                ds.l    1   ; 734
CrashR14                ds.l    1   ; 738
CrashR15                ds.l    1   ; 73c
CrashR16                ds.l    1   ; 740
CrashR17                ds.l    1   ; 744
CrashR18                ds.l    1   ; 748
CrashR19                ds.l    1   ; 74c
CrashR20                ds.l    1   ; 750
CrashR21                ds.l    1   ; 754
CrashR22                ds.l    1   ; 758
CrashR23                ds.l    1   ; 75c
CrashR24                ds.l    1   ; 760
CrashR25                ds.l    1   ; 764
CrashR26                ds.l    1   ; 768
CrashR27                ds.l    1   ; 76c
CrashR28                ds.l    1   ; 770
CrashR29                ds.l    1   ; 774
CrashR30                ds.l    1   ; 778
CrashR31                ds.l    1   ; 77c
CrashCR                 ds.l    1   ; 780
CrashMQ                 ds.l    1   ; 784
CrashXER                ds.l    1   ; 788
CrashLR                 ds.l    1   ; 78c
CrashCTR                ds.l    1   ; 790
CrashPVR                ds.l    1   ; 794
CrashDSISR              ds.l    1   ; 798
CrashDAR                ds.l    1   ; 79c
CrashRTCU               ds.l    1   ; 7a0
CrashRTCL               ds.l    1   ; 7a4
CrashDEC                ds.l    1   ; 7a8
CrashHID0               ds.l    1   ; 7ac
CrashSDR1               ds.l    1   ; 7b0
CrashSRR0               ds.l    1   ; 7b4
CrashSRR1               ds.l    1   ; 7b8
CrashMSR                ds.l    1   ; 7bc
CrashSR0                ds.l    1   ; 7c0
CrashSR1                ds.l    1   ; 7c4
CrashSR2                ds.l    1   ; 7c8
CrashSR3                ds.l    1   ; 7cc
CrashSR4                ds.l    1   ; 7d0
CrashSR5                ds.l    1   ; 7d4
CrashSR6                ds.l    1   ; 7d8
CrashSR7                ds.l    1   ; 7dc
CrashSR8                ds.l    1   ; 7e0
CrashSR9                ds.l    1   ; 7e4
CrashSR10               ds.l    1   ; 7e8
CrashSR11               ds.l    1   ; 7ec
CrashSR12               ds.l    1   ; 7f0
CrashSR13               ds.l    1   ; 7f4
CrashSR14               ds.l    1   ; 7f8
CrashSR15               ds.l    1   ; 7fc
CrashF0                 ds.d    1   ; 800
CrashF1                 ds.d    1   ; 808
CrashF2                 ds.d    1   ; 810
CrashF3                 ds.d    1   ; 818
CrashF4                 ds.d    1   ; 820
CrashF5                 ds.d    1   ; 828
CrashF6                 ds.d    1   ; 830
CrashF7                 ds.d    1   ; 838
CrashF8                 ds.d    1   ; 840
CrashF9                 ds.d    1   ; 848
CrashF10                ds.d    1   ; 850
CrashF11                ds.d    1   ; 858
CrashF12                ds.d    1   ; 860
CrashF13                ds.d    1   ; 868
CrashF14                ds.d    1   ; 870
CrashF15                ds.d    1   ; 878
CrashF16                ds.d    1   ; 880
CrashF17                ds.d    1   ; 888
CrashF18                ds.d    1   ; 890
CrashF19                ds.d    1   ; 898
CrashF20                ds.d    1   ; 8a0
CrashF21                ds.d    1   ; 8a8
CrashF22                ds.d    1   ; 8b0
CrashF23                ds.d    1   ; 8b8
CrashF24                ds.d    1   ; 8c0
CrashF25                ds.d    1   ; 8c8
CrashF26                ds.d    1   ; 8d0
CrashF27                ds.d    1   ; 8d8
CrashF28                ds.d    1   ; 8e0
CrashF29                ds.d    1   ; 8e8
CrashF30                ds.d    1   ; 8f0
CrashF31                ds.d    1   ; 8f8
CrashFPSCR              ds.l    1   ; 900
CrashKernReturn         ds.l    1   ; 904
CrashUnknown1           ds.l    1   ; 908
CrashUnknown2           ds.l    1   ; 90c
CrashBtm

PageMap                 ds.b    0x1a8   ; 910:ab8

                        org     0xCC0
SysInfo                 ds  NKSystemInfo        ; cc0:d80
DiagInfo                ds  NKDiagInfo          ; d80:e80
NKInfo                  ds  NKNanoKernelInfo    ; e80:f80
ProcInfo                ds  NKProcessorInfo     ; f80:fc0

InfoRecBlk              ds.b    64  ; fc0:1000 ; Access using ptr equates in InfoRecords
    ENDR

########################################################################

KernelState             RECORD 0,INCR
Flags                   ds.l    1   ; 00
Enables                 ds.l    1   ; 04

Handler                 ds.d    1   ; 08
HandlerArg              ds.d    1   ; 10
HandlerReturn           ds.d    1   ; 18

MemRet17                ds.d    1   ; 20 ; MemRetry state
MemRetData              ds.d    1   ; 28
MemRet19                ds.d    1   ; 30
MemRet18                ds.d    1   ; 38
    ENDR

########################################################################

CB                      RECORD 0,INCR ; ContextBlock (Emulator/System or Native/Alternate)

InterState              ds  KernelState ; 000:040 ; for switching between contexts
IntraState              ds  KernelState ; 040:080 ; for raising/disposing exceptions within a context

FaultSrcPC              ds.d    1   ; 080 ; saved when starting an exception handler
FaultSrcLR              ds.d    1   ; 088
FaultSrcR3              ds.d    1   ; 090
FaultSrcR4              ds.d    1   ; 098

MSR                     ds.d    1   ; 0a0
                        ds.d    1   ; 0a8
                        ds.d    1   ; 0b0
                        ds.d    1   ; 0b8
MQ                      ds.d    1   ; 0c0 ; 601 only
                        ds.d    1   ; 0c8
XER                     ds.d    1   ; 0d0
CR                      ds.d    1   ; 0d8
FPSCR                   ds.d    1   ; 0e0 ; unsure, mffs/mtfs?
LR                      ds.d    1   ; 0e8
CTR                     ds.d    1   ; 0f0
PC                      ds.d    1   ; 0f8

r0                      ds.d    1   ; 100 ; big-endian, so 32-bit value stored in second word
r1                      ds.d    1   ; 108
r2                      ds.d    1   ; 110
r3                      ds.d    1   ; 118
r4                      ds.d    1   ; 120
r5                      ds.d    1   ; 128
r6                      ds.d    1   ; 130
r7                      ds.d    1   ; 138
r8                      ds.d    1   ; 140
r9                      ds.d    1   ; 148
r10                     ds.d    1   ; 150
r11                     ds.d    1   ; 158
r12                     ds.d    1   ; 160
r13                     ds.d    1   ; 168
r14                     ds.d    1   ; 170
r15                     ds.d    1   ; 178
r16                     ds.d    1   ; 180
r17                     ds.d    1   ; 188
r18                     ds.d    1   ; 190
r19                     ds.d    1   ; 198
r20                     ds.d    1   ; 1a0
r21                     ds.d    1   ; 1a8
r22                     ds.d    1   ; 1b0
r23                     ds.d    1   ; 1b8
r24                     ds.d    1   ; 1c0
r25                     ds.d    1   ; 1c8
r26                     ds.d    1   ; 1d0
r27                     ds.d    1   ; 1d8
r28                     ds.d    1   ; 1e0
r29                     ds.d    1   ; 1e8
r30                     ds.d    1   ; 1f0
r31                     ds.d    1   ; 1f8

f0                      ds.d    1   ; 200
f1                      ds.d    1   ; 208
f2                      ds.d    1   ; 210
f3                      ds.d    1   ; 218
f4                      ds.d    1   ; 220
f5                      ds.d    1   ; 228
f6                      ds.d    1   ; 230
f7                      ds.d    1   ; 238
f8                      ds.d    1   ; 240
f9                      ds.d    1   ; 248
f10                     ds.d    1   ; 250
f11                     ds.d    1   ; 258
f12                     ds.d    1   ; 260
f13                     ds.d    1   ; 268
f14                     ds.d    1   ; 270
f15                     ds.d    1   ; 278
f16                     ds.d    1   ; 280
f17                     ds.d    1   ; 288
f18                     ds.d    1   ; 290
f19                     ds.d    1   ; 298
f20                     ds.d    1   ; 2a0
f21                     ds.d    1   ; 2a8
f22                     ds.d    1   ; 2b0
f23                     ds.d    1   ; 2b8
f24                     ds.d    1   ; 2c0
f25                     ds.d    1   ; 2c8
f26                     ds.d    1   ; 2d0
f27                     ds.d    1   ; 2d8
f28                     ds.d    1   ; 2e0
f29                     ds.d    1   ; 2e8
f30                     ds.d    1   ; 2f0
f31                     ds.d    1   ; 2f8

Size                    equ     *
    ENDR
