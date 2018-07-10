	include		'MacErrors.a'
	include		'Multiprocessing.a'

	include		'InfoRecords.a'
	include		'EmulatorPublic.a'
	include		'NKPublic.a'
	include		'NKOpaque.a'

	include		'NKEquates.s'
	include		'NKMacros.s'

; I want these to be visibly wrong for the time being
FDP_TableBase
FDP_003C
loc_A38
FDP_011C
loc_D50
FDP_0DA0
MemRetryDSI
MemRetryMachineCheck

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

	include		'NKIntHandlers.s'
	include		'NKMemory.s'
	include		'NKExceptions.s'
	include		'NKFloatingPt.s'
	include		'NKSoftInt.s'
	include		'NKLegacyVM.s'

NKBtm
