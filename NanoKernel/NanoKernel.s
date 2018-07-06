	include		'MacErrors.a'
	include		'Multiprocessing.a'

	include		'InfoRecords.a'
	include		'EmulatorPublic.a'
	include		'NKPublic.a'
	include		'NKOpaque.a'

	include		'NKEquates.s'
	include		'NKMacros.s'

NKTop
	b			VMPanic



	org 0x0
Entry
	org 0xA4
bankLoop
	org 0xC8
FloatTables
	org 0x308
ProcessorInfoTbl
	org 0x374
FiguredOutProcessor
	org 0x468
Thud
Panic
VMPanic
	org 0x680
IntForEmulator_1
	org 0x740
PDM68kInterruptTable
	org 0x780
IntForEmulator_2
	org 0x840
IntForEmulator_3
	org 0x940
IntDecrementerSystem
	org 0x9C8
IntDecrementerAlternate
	org 0xA00
IntDSI
	org 0xB00
IntAlignment
	org 0xC00
FDP
	org	0xA38
loc_A38
	org	0xD50
loc_D50
	org 0x13F4
MemRetryDSI
	org 0x1498
MemRetryMachineCheck
	org 0x1874
IntISI
	org 0x18C4
major_0x039dc
	org 0x18D8
major_0x039dc_0x14
	org 0x18EC
IntMachineCheck
	org 0x18F8
PagingFunc1
	org 0x1C74
PagingFunc2
	org 0x1E70
PagingL2PWithBATs
	org 0x1EDC
PagingL2PWithoutBATs
	org 0x1F98
PagingFlushTLB
	org 0x1FB8
ExceptionMemRetried
	org 0x2034
LetBlueHandleOwnException
	org 0x20C0
ReturnFromExceptionFastPath
	org 0x20D8
KCallReturnFromException
	org 0x2194
LoadInterruptRegisters
	org 0x21DC
Exception
	org 0x2204
IntReturnToSystemContext
	org 0x2214
IntReturnToOtherBlueContext
	org 0x23AC
IntReturn
	org 0x23F0
major_0x02ccc
	org 0x2500
IntFPUnavail
	org 0x2550
major_0x03e18
	org 0x2558
IntHandleSpecialFPException
	org 0x2574
LoadFloatsFromContextBlock
	org 0x2600
bugger_around_with_floats
	org 0x269C
FloatTables_0



	org			0x289C

	include		'NKSoftInt.s'
	include		'NKLegacyVM.s'

NKBtm
