BAT			RECORD 0, INCR
U			ds.l 1
L			ds.l 1
	ENDR

########################################################################

MemLayout	RECORD 0, INCR
SegMapPtr	ds.l 1
BatMap		ds.l 1 ; packed array of 4-bit indices into BATs
	ENDR

########################################################################

VecTbl					RECORD 0, INCR
						ds.l	1	; 00 ; scratch for IVT?
SystemResetVector		ds.l	1	; 04 ; called by    IVT+100 (system reset)
MachineCheckVector		ds.l	1	; 08 ; called by    IVT+200 (machine check)
DSIVector				ds.l	1	; 0c ; called by    IVT+300 (DSI)
ISIVector				ds.l	1	; 10 ; called by    IVT+400 (ISI)
ExternalIntVector		ds.l	1	; 14 ; called by    IVT+500 (external interrupt)
AlignmentIntVector		ds.l	1	; 18 ; called by    IVT+600 (alignment)
ProgramIntVector		ds.l	1	; 1c ; called by    IVT+700 (program)
FPUnavailVector			ds.l	1	; 20 ; called by    IVT+KDP.BATs + 0xa0 (FP unavail)
DecrementerVector		ds.l	1	; 24 ; called by    IVT+900 (decrementer)
ReservedVector1			ds.l	1	; 28 ; called by    IVT+a00 (reserved)
ReservedVector2			ds.l	1	; 2c ; called by    IVT+b00 (reserved)
SyscallVector			ds.l	1	; 30 ; called by    IVT+c00 (system call)
TraceVector				ds.l	1	; 34 ; called by    IVT+d00 (trace)
FPAssistVector			ds.l	1	; 38 ; called by    IVT+e00 (FP assist)
PerfMonitorVector		ds.l	1	; 3c ; called by    IVT+f00 (perf monitor)
						ds.l	1	; 40 ;
						ds.l	1	; 44 ;
						ds.l	1	; 48 ;
						ds.l	1	; 4c ; Vectors from here downwards are called from
						ds.l	1	; 50 ; odd places in the IVT????
						ds.l	1	; 54 ;
						ds.l	1	; 58 ; seems AltiVec-related
ThermalEventVector		ds.l	1	; 5c ;
						ds.l	1	; 60 ;
						ds.l	1	; 64 ;
						ds.l	1	; 68 ;
						ds.l	1	; 6c ;
						ds.l	1	; 70 ;
						ds.l	1	; 74 ;
						ds.l	1	; 78 ;
						ds.l	1	; 7c ;
						ds.l	1	; 80 ; shares with TraceVector in Y and G
						ds.l	1	; 84 ;
						ds.l	1	; 88 ;
						ds.l	1	; 8c ;
						ds.l	1	; 90 ;
						ds.l	1	; 94 ;
						ds.l	1	; 98 ;
						ds.l	1	; 9c ;
						ds.l	1	; a0 ;
						ds.l	1	; a4 ;
						ds.l	1	; a8 ;
						ds.l	1	; ac ;
						ds.l	1	; b0 ;
						ds.l	1	; b4 ;
						ds.l	1	; b8 ;
						ds.l	1	; bc ; called by IVT+0 (reserved)
Size					equ		*
	ENDR

########################################################################

KCallTbl				RECORD 0, INCR
ReturnFromException		ds.l	1	; 00, trap  0
RunAlternateContext		ds.l	1	; 04, trap  1
ResetSystem				ds.l	1	; 08, trap  2 ; 68k RESET
VMDispatch				ds.l	1	; 0c, trap  3 ; 68k $FE0A
PrioritizeInterrupts	ds.l	1	; 10, trap  4
PowerDispatch			ds.l	1	; 14, trap  5 ; 68k $FEOF
RTASDispatch			ds.l	1	; 18, trap  6
CacheDispatch			ds.l	1	; 1c, trap  7
MPDispatch				ds.l	1	; 20, trap  8
						ds.l	1	; 24, trap  9
						ds.l	1	; 28, trap 10
						ds.l	1	; 2c, trap 11
CallAdapterProcPPC		ds.l	1	; 30, trap 12
						ds.l	1	; 34, trap 13
CallAdapterProc68k		ds.l	1	; 38, trap 14
SystemCrash				ds.l	1	; 3c, trap 15
Size					equ		*
	ENDR

########################################################################

PME						RECORD 0, INCR ; PageMap Entry
LBase					ds.w	1	; 0 ; (base - segment) >> 12
PageCount				ds.w	1	; 2 ; page count MINUS ONE
PBaseAndFlags			ds.l	1	; 4 ; PBase page aligned

PBaseBits				equ		20
FirstFlagBit			equ		20
FirstFlag				equ		0x800

DaddyFlag				equ		0x800
CountingFlag			equ		0x400
PhysicalIsRelativeFlag	equ		0x200

; try not to use the equates above; they are dicey
TopFieldMask			equ		0xe00

Size					equ		*
	ENDR

########################################################################

KDP						RECORD 0x80, INCR
r0						ds.l	1	; 000 ; used for quick register saves at interrupt time
r1						ds.l	1	; 004
r2						ds.l	1	; 008
r3						ds.l	1	; 00c
r4						ds.l	1	; 010
r5						ds.l	1	; 014
r6						ds.l	1	; 018
r7						ds.l	1	; 01c
r8						ds.l	1	; 020
r9						ds.l	1	; 024
r10						ds.l	1	; 028
r11						ds.l	1	; 02c
r12						ds.l	1	; 030
r13						ds.l	1	; 034
r14						ds.l	1	; 038
r15						ds.l	1	; 03c
r16						ds.l	1	; 040
r17						ds.l	1	; 044
r18						ds.l	1	; 048
r19						ds.l	1	; 04c
r20						ds.l	1	; 050
r21						ds.l	1	; 054
r22						ds.l	1	; 058
r23						ds.l	1	; 05c
r24						ds.l	1	; 060
r25						ds.l	1	; 064
r26						ds.l	1	; 068
r27						ds.l	1	; 06c
r28						ds.l	1	; 070
r29						ds.l	1	; 074
r30						ds.l	1	; 078
r31						ds.l	1	; 07c

SegMaps
SegMap32SupInit			ds.l	32	; 080:100
SegMap32UsrInit			ds.l	32	; 100:180
SegMap32CPUInit			ds.l	32	; 180:200
SegMap32OvlInit			ds.l	32	; 200:280

BATs					ds.l	32	; 280:300

CurIBAT0				ds		BAT	; 300:308
CurIBAT1				ds		BAT	; 308:310
CurIBAT2				ds		BAT	; 310:318
CurIBAT3				ds		BAT	; 318:320
CurDBAT0				ds		BAT	; 320:328
CurDBAT1				ds		BAT	; 328:330
CurDBAT2				ds		BAT	; 330:338
CurDBAT3				ds		BAT	; 338:340

NCBPointerCache
NCBCacheLA0				ds.l	1	; 340
NCBCachePA0				ds.l	1	; 344
NCBCacheLA1				ds.l	1	; 348
NCBCachePA1				ds.l	1	; 34c
NCBCacheLA2				ds.l	1	; 350
NCBCachePA2				ds.l	1	; 354
NCBCacheLA3				ds.l	1	; 358
NCBCachePA3				ds.l	1	; 35c
NCBPointerCacheEnd

VecTblSystem			ds	VecTbl	; 360:420 ; when 68k emulator is running, *or* any MTask
VecTblAlternate			ds	VecTbl	; 420:4e0 ; native PowerPC in blue task
VecTblMemRetry			ds	VecTbl	; 4e0:5a0 ; "FDP" instruction emulation

FloatEmScratch			ds.d	1	; 5a0:5a8
TopOfFreePages			ds.l	1	; 5a8 ; gotten from the old SPRG0
						ds.l	1	; 5ac
PARPerSegmentPLEPtrs	ds.l	4	; 5b0:5c0 ; for each PAR segment, a ptr into the PAR PageList
FloatingPtTemp1			ds.l	1	; 5c0
FloatingPtTemp2			ds.l	1	; 5c4

SupervisorMemLayout		ds	MemLayout	; 5c8:5d0
UserMemLayout			ds	MemLayout	; 5d0:5d8
CpuMemLayout			ds	MemLayout	; 5d8:5e0
OverlayMemLayout		ds	MemLayout	; 5e0:5e8
CurrentMemLayout		ds	MemLayout	; 5e8:5f0

KCallTbl				ds	KCallTbl	; 5f0:630

PA_ConfigInfo			ds.l	1	; 630
PA_EmulatorData			ds.l	1	; 634
KernelMemoryBase		ds.l	1	; 638
KernelMemoryEnd			ds.l	1	; 63c ; Top of HTAB (and entire kernel reserved area). Set by Init.s
PA_RelocatedLowMemInit	ds.l	1	; 640 ; From ConfigInfo. Ptr to Mac LowMem vars, which Init.s sets up
SharedMemoryAddr		ds.l	1	; 644 ; From ConfigInfo. Not sure what latest use is.
LA_EmulatorKernelTrapTable ds.l	1	; 648 ; Calculated from ConfigInfo.
PA_NanoKernelCode		ds.l	1	; 64c ; Calculated by NanoKernel itself.
PA_FDP					ds.l	1	; 650 ; See notes in NanoKernel. Very interesting.
LA_ECB					ds.l	1	; 654 ; Logical ptr into EDP.
PA_ECB					ds.l	1	; 658 ; gets called "system context"
PA_ContextBlock			ds.l	1	; 65c ; moved to EWA (per-CPU) in NKv2
Flags					ds.l	1	; 660 ; moved to EWA (per-CPU) in NKv2
Enables					ds.l	1	; 664 ; moved to EWA (per-CPU) in NKv2
OtherContextDEC			ds.l	1	; 668 ; ticks the *inactive* context has left out of 1s
PA_PageMapEnd			ds.l	1	; 66c ; Set at the same time as PA_PageMapStart below...
TestIntMaskInit			ds.l	1	; 670 ; These are all copied from ConfigInfo...
PostIntMaskInit			ds.l	1	; 674
ClearIntMaskInit		ds.l	1	; 678
PA_EmulatorIplValue		ds.l	1	; 67c ; Physical ptr into EDP
DebugIntPtr				ds.l	1	; 680 ; Within (debug?) shared memory
PA_PageMapStart			ds.l	1	; 684 ; Physical ptr to PageMap (= KDP+0x920)
PageAttributeInit		ds.l	1	; 688 ; defaults for page table entries (see ConfigInfo)

HtabTempPage			ds.l	1	; 68c
HtabTempEntryPtr		ds.l	1	; 690
NewestPageInHtab		ds.l	1	; 694
ApproxCurrentPTEG		ds.l	1	; 698
OverflowingPTEG			ds.l	1	; 69c

PTEGMask				ds.l	1	; 6a0
HTABORG					ds.l	1	; 6a4
VMLogicalPages			ds.l	1	; 6a8 ; set at init and changed by VMInit
TotalPhysicalPages		ds.l	1	; 6ac ; does not take into acct maximum MacOS memory
PARPageListPtr			ds.l	1	; 6b0 ; VM puts this in system heap
VMMaxVirtualPages		ds.l	1	; 6b4 ; always 5fffe000, even with VM on

						org		0x700
CrashTop
CrashR0					ds.l	1	; 700
CrashR1					ds.l	1	; 704
CrashR2					ds.l	1	; 708
CrashR3					ds.l	1	; 70c
CrashR4					ds.l	1	; 710
CrashR5					ds.l	1	; 714
CrashR6					ds.l	1	; 718
CrashR7					ds.l	1	; 71c
CrashR8					ds.l	1	; 720
CrashR9					ds.l	1	; 724
CrashR10				ds.l	1	; 728
CrashR11				ds.l	1	; 72c
CrashR12				ds.l	1	; 730
CrashR13				ds.l	1	; 734
CrashR14				ds.l	1	; 738
CrashR15				ds.l	1	; 73c
CrashR16				ds.l	1	; 740
CrashR17				ds.l	1	; 744
CrashR18				ds.l	1	; 748
CrashR19				ds.l	1	; 74c
CrashR20				ds.l	1	; 750
CrashR21				ds.l	1	; 754
CrashR22				ds.l	1	; 758
CrashR23				ds.l	1	; 75c
CrashR24				ds.l	1	; 760
CrashR25				ds.l	1	; 764
CrashR26				ds.l	1	; 768
CrashR27				ds.l	1	; 76c
CrashR28				ds.l	1	; 770
CrashR29				ds.l	1	; 774
CrashR30				ds.l	1	; 778
CrashR31				ds.l	1	; 77c
CrashCR					ds.l	1	; 780
CrashMQ					ds.l	1	; 784
CrashXER				ds.l	1	; 788
CrashLR					ds.l	1	; 78c
CrashCTR				ds.l	1	; 790
CrashPVR				ds.l	1	; 794
CrashDSISR				ds.l	1	; 798
CrashDAR				ds.l	1	; 79c
CrashRTCU				ds.l	1	; 7a0
CrashRTCL				ds.l	1	; 7a4
CrashDEC				ds.l	1	; 7a8
CrashHID0				ds.l	1	; 7ac
CrashSDR1				ds.l	1	; 7b0
CrashSRR0				ds.l	1	; 7b4
CrashSRR1				ds.l	1	; 7b8
CrashMSR				ds.l	1	; 7bc
CrashSR0				ds.l	1	; 7c0
CrashSR1				ds.l	1	; 7c4
CrashSR2				ds.l	1	; 7c8
CrashSR3				ds.l	1	; 7cc
CrashSR4				ds.l	1	; 7d0
CrashSR5				ds.l	1	; 7d4
CrashSR6				ds.l	1	; 7d8
CrashSR7				ds.l	1	; 7dc
CrashSR8				ds.l	1	; 7e0
CrashSR9				ds.l	1	; 7e4
CrashSR10				ds.l	1	; 7e8
CrashSR11				ds.l	1	; 7ec
CrashSR12				ds.l	1	; 7f0
CrashSR13				ds.l	1	; 7f4
CrashSR14				ds.l	1	; 7f8
CrashSR15				ds.l	1	; 7fc
CrashF0					ds.d	1	; 800
CrashF1					ds.d	1	; 808
CrashF2					ds.d	1	; 810
CrashF3					ds.d	1	; 818
CrashF4					ds.d	1	; 820
CrashF5					ds.d	1	; 828
CrashF6					ds.d	1	; 830
CrashF7					ds.d	1	; 838
CrashF8					ds.d	1	; 840
CrashF9					ds.d	1	; 848
CrashF10				ds.d	1	; 850
CrashF11				ds.d	1	; 858
CrashF12				ds.d	1	; 860
CrashF13				ds.d	1	; 868
CrashF14				ds.d	1	; 870
CrashF15				ds.d	1	; 878
CrashF16				ds.d	1	; 880
CrashF17				ds.d	1	; 888
CrashF18				ds.d	1	; 890
CrashF19				ds.d	1	; 898
CrashF20				ds.d	1	; 8a0
CrashF21				ds.d	1	; 8a8
CrashF22				ds.d	1	; 8b0
CrashF23				ds.d	1	; 8b8
CrashF24				ds.d	1	; 8c0
CrashF25				ds.d	1	; 8c8
CrashF26				ds.d	1	; 8d0
CrashF27				ds.d	1	; 8d8
CrashF28				ds.d	1	; 8e0
CrashF29				ds.d	1	; 8e8
CrashF30				ds.d	1	; 8f0
CrashF31				ds.d	1	; 8f8
CrashFPSCR				ds.l	1	; 900
CrashKernReturn			ds.l	1	; 904
CrashUnknown			ds.l	1	; 908
CrashBtm

						org		0xCC0
SysInfo					ds	NKSystemInfo		; cc0:d80
DiagInfo				ds	NKDiagInfo			; d80:e80
NKInfo					ds	NKNanoKernelInfo	; e80:f80
ProcInfo				ds	NKProcessorInfo		; f80:fc0

InfoRecBlk				ds.b	64	; fc0:1000 ; Access using ptr equates in InfoRecords
	ENDR
