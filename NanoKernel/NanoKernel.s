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


printw
Exception
IntReturnToOtherBlueContext
LookupID
ResetBuiltinKernel
LoadInterruptRegisters
MaskedInterruptTaken
save_all_registers
kcMPDispatch
PagingL2PWithBATs
Restore_v0_v31
SchExitInterrupt
SchRestoreStartingAtR14
SchSaveStartingAtR14
SchSwitchSpace
CauseNotification
FDPEmulateInstruction
ReturnFromExceptionFastPath

	
	org			0x23AC
IntReturn

	org			0x18F8
PagingFunc1

	org			0x468
VMPanic
IntPanicIsland
Panic

	org			0x289C

	include		'NKIntMisc.s'
	include		'NKVMCalls.s'

NKBtm
