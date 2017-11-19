;	Contains the table used by Init.s:SetProcessorFlags, and a label to find it with.
;
;	Using this table, three fields in KDP are set:
;		KDP.CpuSpecificByte1
;		KDP.CpuSpecificByte2 (immediately follows Byte1)
;		KDP.ProcessorInfo.ProcessorFlags

ProcessorFlagsTable
	dcb.b	32 * (1 + 1 + 4), 0
ProcessorFlagsTableEnd



PflgTblCtr		set		0

	macro
	PflgTblEnt		&CpuSpecificByte1, &CpuSpecificByte2, &ProcessorFlags

@fb
	org		ProcessorFlagsTable + PflgTblCtr
	dc.b	&CpuSpecificByte1
	org		ProcessorFlagsTable + 32 + PflgTblCtr
	dc.b	&CpuSpecificByte2
	org		ProcessorFlagsTable + 64 + 4*PflgTblCtr
	dc.l	&ProcessorFlags
	org		@fb
PflgTblCtr	set		PflgTblCtr + 1

	endm



	with	NKProcessorInfo

	;   CpuSpecificByte
	;           1     2    ProcessorFlags                                                             CPU
	;           ----  -  ------------------------------------------------------------------------     -----------------------
	PflgTblEnt	0x03, 1, 0																			; 0**0
	PflgTblEnt	0x00, 0, 0																			; 0**1 = 601
	PflgTblEnt	0x03, 1, 0																			; 0**2
	PflgTblEnt	0x1b, 2, 0																			; 0**3 = 603
	PflgTblEnt	0x0a, 1, 0																			; 0**4 = 604
	PflgTblEnt	0x1b, 2, 0																			; 0**5
	PflgTblEnt	0x1b, 2, 0																			; 0**6 = 603e
	PflgTblEnt	0x1b, 2, 0																			; 0**7 = 750FX
	PflgTblEnt	0x1b, 2, 1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU									; 0**8 = 750
	PflgTblEnt	0x0a, 1, 0																			; 0**9
	PflgTblEnt	0x0a, 1, 0																			; 0**a
	PflgTblEnt	0x03, 1, 0																			; 0**b
	PflgTblEnt	0x1b, 2, 1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< unknownFlag	; 0**c = 7400
	PflgTblEnt	0x0b, 2, 0																			; 0**d
	PflgTblEnt	0x03, 2, 0																			; 0**e
	PflgTblEnt	0x03, 2, 0																			; 0**f

	PflgTblEnt	0x03, 2, 1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< unknownFlag	; 8**0 = 7450
	PflgTblEnt	0x1b, 2, 1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< unknownFlag	; 8**1 = 7445/55
	PflgTblEnt	0x03, 2, 0																			; 8**2 = 7447 (OS X only)
	PflgTblEnt	0x03, 2, 0																			; 8**3
	PflgTblEnt	0x03, 1, 0																			; 8**4
	PflgTblEnt	0x03, 2, 0																			; 8**5
	PflgTblEnt	0x03, 2, 0																			; 8**6
	PflgTblEnt	0x03, 2, 0																			; 8**7
	PflgTblEnt	0x03, 2, 0																			; 8**8
	PflgTblEnt	0x03, 2, 0																			; 8**9
	PflgTblEnt	0x03, 2, 0																			; 8**a
	PflgTblEnt	0x03, 2, 0																			; 8**b
	PflgTblEnt	0x1b, 2, 1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< unknownFlag	; 8**c = 7410
	PflgTblEnt	0x03, 2, 0																			; 8**d
	PflgTblEnt	0x03, 2, 0																			; 8**e
	PflgTblEnt	0x03, 2, 0																			; 8**f

	endwith
