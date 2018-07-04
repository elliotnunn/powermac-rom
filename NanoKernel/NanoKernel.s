	include		'MacErrors.a'
	include		'Multiprocessing.a'

	include		'InfoRecords.a'
	include		'EmulatorPublic.a'
	include		'NKPublic.a'
	include		'NKOpaque.a'

	include		'NKEquates.s'
	include		'NKMacros.s'

NKTop
	include		'NKInit.s'

	align		5
IntPanicIsland
	b			Panic
	include		'NKExceptions.s'
	align		5
	include		'NKIntHandlers.s'
	align		5
	include		'NKFloatInts.s'
	align		6
	include		'NKIntMisc.s'

	align		5
	include		'NKPaging.s'
	align		5
	include		'NKTranslation.s'
	align		5
	include		'NKVMCalls.s'
	align		5
	include		'NKPowerCalls.s'
	align		5
	include		'NKRTASCalls.s'
	align		5
	include		'NKCache.s'

	;	Mostly MP calls:
	align		5
	include		'NKMPCalls.s'
	align		5
	include		'NKSync.s'
	align		5
	include		'NKTasks.s'
	align		5
	include		'NKAddressSpaces.s'

	align		5
	include		'NKPoolAllocator.s'
	align		5
	include		'NKTimers.s'
	align		5
	include		'NKScheduler.s'
	align		5
	include		'NKIndex.s'
	align		5
	include		'NKPrimaryIntHandlers.s'
	align		5
	include		'NKConsoleLog.s'
	align		5
	include		'NKSleep.s'
	align		5
	include		'NKThud.s'
	align		5
	include		'NKScreenConsole.s'
	align		5
	include		'NKAdditions.s'
	align		5
NKBtm
