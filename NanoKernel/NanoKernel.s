    include 'InfoRecords.a'

    include 'NKStructs.s'
    include 'NKEquates.s'
    include 'NKMacros.s'

CodeBase
    include 'NKInit.s'
    include 'NKSystemCrash.s'
    include 'NKHotInts.s'

    _align 10
MRBase
    include 'MROptabCode.s'
    include 'MRMemtabCode.s'
    include 'MRInterrupts.s'
    include 'MROptab.s'
    include 'MRMemtab.s'
    include 'MRRestab.s'

    include 'NKColdInts.s'
    include 'NKMemory.s'
    include 'NKExceptions.s'
    include 'NKFloatingPt.s'
    include 'NKSoftInts.s'
    include 'NKLegacyVM.s'
