	include 'InfoRecords.a'

	include 'NKStructs.s'
	include 'NKEquates.s'
	include 'NKMacros.s'

CodeBase
	include 'NKInit.s'
	include 'NKSystemCrash.s'
	include 'NKHotInts.s'
	include 'NKColdInts.s'

    _align 10
MRBase
    include 'MROptabCode.s' ; c00:1154
    include 'MRMemtabCode.s' ; 1154:13f4
    include 'MRInterrupts.s' ; 13f4:14f4
    include 'MROptab.s' ; 14f4:16f4
    include 'MRMemtab.s' ; 16f4:17f4
    include 'MRRestab.s' ; 17f4:1874

	include 'NKMemory.s'
	include 'NKExceptions.s'
	include 'NKFloatingPt.s'
	include 'NKSoftInts.s'
	include 'NKLegacyVM.s'
