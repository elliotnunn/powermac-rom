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
	org 0xC38
FDP_003C
	org	0xA38
loc_A38
	org 0xD18
FDP_011C
	org	0xD50
loc_D50
FDP_0DA0
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

	include		'NKMemory.s'
	include		'NKExceptions.s'
	include		'NKFloatingPt.s'
	include		'NKSoftInt.s'
	include		'NKLegacyVM.s'

NKBtm
