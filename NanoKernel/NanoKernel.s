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


	
	org			0x23AC
IntReturn

	org			0x18F8
PagingFunc1

	org			0x468
VMPanic
Panic

	org			0x30cc

	include		'NKVMCalls.s'

NKBtm
