;	AUTO-GENERATED SYMBOL LIST
;	EXPORTS:
;	  ProcessorFlagsTable (=> NKInit)

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

;	CpuSpecificByte2:
HID0_NHR_only				equ		1			; Idle Power calls should set the HID0[NHR] bit
HID0_NHR_and_sleep			equ		2			; ...and the HID0 bit that potentiates MSR[POW]
HID0_neither				equ		0

;	See NKPowerCalls for info on CpuSpecificByte1. Its upper nybble specifies how to idle the CPU.

	;		CpuSpecificByte
	;			1		2						ProcessorFlags															CPU
	;			-		-						--------------															---
	PflgTblEnt	0x03,	HID0_NHR_only,			0																		; 0**0
	PflgTblEnt	0x00,	HID0_neither,			0																		; 0**1 = 601
	PflgTblEnt	0x03,	HID0_NHR_only,			0																		; 0**2
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		0																		; 0**3 = 603
	PflgTblEnt	0x0a,	HID0_NHR_only,			0																		; 0**4 = 604
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		0																		; 0**5
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		0																		; 0**6 = 603e
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		0																		; 0**7 = 750FX
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU								; 0**8 = 750
	PflgTblEnt	0x0a,	HID0_NHR_only,			0																		; 0**9
	PflgTblEnt	0x0a,	HID0_NHR_only,			0																		; 0**a
	PflgTblEnt	0x03,	HID0_NHR_only,			0																		; 0**b
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< hasMSSregs	; 0**c = 7400
	PflgTblEnt	0x0b,	HID0_NHR_and_sleep,		0																		; 0**d
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 0**e
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 0**f

	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< hasMSSregs	; 8**0 = 7450 (see note below)
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< hasMSSregs	; 8**1 = 7445/55
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**2 = 7447 (OS X only)
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**3
	PflgTblEnt	0x03,	HID0_NHR_only,			0																		; 8**4
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**5
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**6
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**7
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**8
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**9
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**a
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**b
	PflgTblEnt	0x1b,	HID0_NHR_and_sleep,		1<< hasL2CR | 1<< hasPLRUL1 | 1<< hasTAU | 1<< hasVMX | 1<< hasMSSregs	; 8**c = 7410
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**d
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**e
	PflgTblEnt	0x03,	HID0_NHR_and_sleep,		0																		; 8**f

;	NB: PPC 7450 ("G4e") and its descendants (744x/745x) lack the HID0[DOZE] bit (they have HID0[HIGH_BAT_EN] instead).
;	Therefore the upper nybble of CpuSpecificByte1 should be 0, or 2 for NAP (works), or 3 for SLEEP (freezes).

	endwith
