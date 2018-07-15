VecTbl					RECORD 0, INCR ; SPRG3 vector table (looked up by ROM vectors)
						ds.l	1	; 00 ; scratch for IVT
SystemReset				ds.l	1	; 04 ; from IVT+100
MachineCheck			ds.l	1	; 08 ; from IVT+200
DSI						ds.l	1	; 0c ; from IVT+300
ISI						ds.l	1	; 10 ; from IVT+400
External				ds.l	1	; 14 ; from IVT+500
Alignment				ds.l	1	; 18 ; from IVT+600
Program					ds.l	1	; 1c ; from IVT+700
FPUnavail				ds.l	1	; 20 ; from IVT+800
Decrementer				ds.l	1	; 24 ; from IVT+900
ReservedVector1			ds.l	1	; 28 ; from IVT+a00
ReservedVector2			ds.l	1	; 2c ; from IVT+b00
Syscall					ds.l	1	; 30 ; from IVT+c00
Trace					ds.l	1	; 34 ; from IVT+d00
FPAssist				ds.l	1	; 38 ; from IVT+e00
PerfMonitor				ds.l	1	; 3c ; from IVT+f00
						ds.l	1	; 40
						ds.l	1	; 44
						ds.l	1	; 48
						ds.l	1	; 4c ; Vectors from here downwards are called from
						ds.l	1	; 50 ; odd places in the IVT
						ds.l	1	; 54
						ds.l	1	; 58 ; seems AltiVec-related
ThermalEvent			ds.l	1	; 5c
						ds.l	1	; 60
						ds.l	1	; 64
						ds.l	1	; 68
						ds.l	1	; 6c
						ds.l	1	; 70
						ds.l	1	; 74
						ds.l	1	; 78
						ds.l	1	; 7c
OtherTrace				ds.l	1	; 80
						ds.l	1	; 84
						ds.l	1	; 88
						ds.l	1	; 8c
						ds.l	1	; 90
						ds.l	1	; 94
						ds.l	1	; 98
						ds.l	1	; 9c
						ds.l	1	; a0
						ds.l	1	; a4
						ds.l	1	; a8
						ds.l	1	; ac
						ds.l	1	; b0
						ds.l	1	; b4
						ds.l	1	; b8
						ds.l	1	; bc ; from IVT+0
Size					equ		*
	ENDR

########################################################################

KCallTbl				RECORD 0, INCR ; NanoKernel call table
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

KDP						RECORD 0, INCR ; Kernel Data Page
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

ConfigInfoPtr			ds.l	1	; 630
EDPPtr					ds.l	1	; 634
KernelMemoryBase		ds.l	1	; 638
KernelMemoryEnd			ds.l	1	; 63c
LowMemPtr				ds.l	1	; 640 ; physical address of PAR Low Memory
SharedMemoryAddr		ds.l	1	; 644 ; debug?
EmuKCallTblPtrLogical 	ds.l	1	; 648
NKCodePtr				ds.l	1	; 64c
RetryCodePtr			ds.l	1	; 650
ECBPtrLogical			ds.l	1	; 654 ; Emulator/System ContextBlock
ECBPtr					ds.l	1	; 658
CurCBPtr				ds.l	1	; 65c ; moved to EWA (per-CPU) in NKv2
Flags					ds.l	1	; 660 ; moved to EWA (per-CPU) in NKv2
Enables					ds.l	1	; 664 ; moved to EWA (per-CPU) in NKv2
OtherContextDEC			ds.l	1	; 668 ; ticks that the *inactive* context has left out of 1s
PageMapEndPtr			ds.l	1	; 66c ; et at the same time as PageMapStartPtr below
TestIntMaskInit			ds.l	1	; 670
PostIntMaskInit			ds.l	1	; 674 ; CR flags to set when posting an interrupt to the Emulator
ClearIntMaskInit		ds.l	1	; 678 ; CR flags to clear (as mask) when clearing an interrupt
EmuIntLevelPtr			ds.l	1	; 67c ; physical ptr to an Emulator global
DebugIntPtr				ds.l	1	; 680 ; within (debug?) shared memory
PageMapStartPtr			ds.l	1	; 684
PageAttributeInit		ds.l	1	; 688 ; defaults for PLE/PTE?
HtabTempPage			ds.l	1	; 68c ; a page that lives temporarily in the HTAB (per its PME)
HtabTempEntryPtr		ds.l	1	; 690 ; ptr to that PME
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
CrashUnknown1			ds.l	1	; 908
CrashUnknown2			ds.l	1	; 90c
CrashBtm

PageMap					ds.b	0x1a8	; 910:ab8

						org		0xCC0
SysInfo					ds	NKSystemInfo		; cc0:d80
DiagInfo				ds	NKDiagInfo			; d80:e80
NKInfo					ds	NKNanoKernelInfo	; e80:f80
ProcInfo				ds	NKProcessorInfo		; f80:fc0

InfoRecBlk				ds.b	64	; fc0:1000 ; Access using ptr equates in InfoRecords
	ENDR

########################################################################

CB						RECORD 0,INCR ; ContextBlock (Emulator/System or Native/Alternate)
Flags					ds.l	1	; 000
Enables					ds.l	1	; 004
						ds.l	1	; 008
						ds.l	1	; 00c
						ds.l	1	; 010
						ds.l	1	; 014
						ds.l	1	; 018
						ds.l	1	; 01c
						ds.l	1	; 020
LowSave17				ds.l	1	; 024
LowSave20				ds.l	1	; 028
LowSave21				ds.l	1	; 02c
						ds.l	1	; 030
LowSave19				ds.l	1	; 034
						ds.l	1	; 038
LowSave18				ds.l	1	; 03c

ExceptionOriginFlags	ds.l	1	; 040 ; from before exception
ExceptionOriginEnables	ds.l	1	; 044 ; from before exception
						ds.l	1	; 048
ExceptionHandler		ds.l	1	; 04c
						ds.l	1	; 050
ExceptionHandlerR4		ds.l	1	; 054
						ds.l	1	; 058
ExceptionHandlerRetAddr ds.l	1	; 05c
						ds.l	1	; 060
PropagateR17			ds.l	1	; 064
PropagateR20			ds.l	1	; 068
PropagateR21			ds.l	1	; 06c
						ds.l	1	; 070
PropagateR19			ds.l	1	; 074
						ds.l	1	; 078
PropagateR18			ds.l	1	; 07c

						ds.l	1	; 080
ExceptionOriginAddr		ds.l	1	; 084
						ds.l	1	; 088
ExceptionOriginLR		ds.l	1	; 08c
						ds.l	1	; 090
ExceptionOriginR3		ds.l	1	; 094
						ds.l	1	; 098
ExceptionOriginR4		ds.l	1	; 09c
						ds.l	1	; 0a0
MSR						ds.l	1	; 0a4
						ds.l	1	; 0a8
						ds.l	1	; 0ac
						ds.l	1	; 0b0
						ds.l	1	; 0b4
						ds.l	1	; 0b8
						ds.l	1	; 0bc
						ds.l	1	; 0c0
MQ						ds.l	1	; 0c4 ; 601 only
						ds.l	1	; 0c8
						ds.l	1	; 0cc
						ds.l	1	; 0d0
XER						ds.l	1	; 0d4
						ds.l	1	; 0d8
CR						ds.l	1	; 0dc
						ds.l	1	; 0e0
						ds.l	1	; 0e4
						ds.l	1	; 0e8
LR						ds.l	1	; 0ec
						ds.l	1	; 0f0
CTR						ds.l	1	; 0f4
						ds.l	1	; 0f8
SRR0					ds.l	1	; 0fc
						ds.l	1
r0						ds.l	1	; 104
						ds.l	1
r1						ds.l	1	; 10c
						ds.l	1
r2						ds.l	1	; 114
						ds.l	1
r3						ds.l	1	; 11c
						ds.l	1
r4						ds.l	1	; 124
						ds.l	1
r5						ds.l	1	; 12c
						ds.l	1
r6						ds.l	1	; 134
						ds.l	1
r7						ds.l	1	; 13c
						ds.l	1
r8						ds.l	1	; 144
						ds.l	1
r9						ds.l	1	; 14c
						ds.l	1
r10						ds.l	1	; 154
						ds.l	1
r11						ds.l	1	; 15c
						ds.l	1
r12						ds.l	1	; 164
						ds.l	1
r13						ds.l	1	; 16c
						ds.l	1
r14						ds.l	1	; 174
						ds.l	1
r15						ds.l	1	; 17c
						ds.l	1
r16						ds.l	1	; 184
						ds.l	1
r17						ds.l	1	; 18c
						ds.l	1
r18						ds.l	1	; 194
						ds.l	1
r19						ds.l	1	; 19c
						ds.l	1
r20						ds.l	1	; 1a4
						ds.l	1
r21						ds.l	1	; 1ac
						ds.l	1
r22						ds.l	1	; 1b4
						ds.l	1
r23						ds.l	1	; 1bc
						ds.l	1
r24						ds.l	1	; 1c4
						ds.l	1
r25						ds.l	1	; 1cc
						ds.l	1
r26						ds.l	1	; 1d4
						ds.l	1
r27						ds.l	1	; 1dc
						ds.l	1
r28						ds.l	1	; 1e4
						ds.l	1
r29						ds.l	1	; 1ec
						ds.l	1
r30						ds.l	1	; 1f4
						ds.l	1
r31						ds.l	1	; 1fc
FloatRegisters			ds.d	32	; 200:300
						endr
