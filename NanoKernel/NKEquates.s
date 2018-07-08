;_______________________________________________________________________
;	Equates for the whole NanoKernel
;_______________________________________________________________________


;	Helps with making equates
;	X = 0x00008000, Xbit=16, Xshift=15
	macro
	_bitEqu &bit, &name
&name equ 1 << (31-&bit)
bit&name equ &bit
shift&name equ 31 - &bit
	endm



kNanoKernelVersion		equ		$0228		


;	PowerPC Machine Status Register (MSR) bits
;	(borrowing the _bitEqu macro from NKInfoRecordsPriv.s)

	_bitEqu	13,	MsrPOW
	_bitEqu	15,	MsrILE
	_bitEqu	16,	MsrEE
	_bitEqu	17,	MsrPR
	_bitEqu	18,	MsrFP
	_bitEqu	19,	MsrME
	_bitEqu	20,	MsrFE0
	_bitEqu	21,	MsrSE
	_bitEqu	22,	MsrBE
	_bitEqu	23,	MsrFE1
	_bitEqu	25,	MsrIP
	_bitEqu	26,	MsrIR
	_bitEqu	27,	MsrDR
	_bitEqu	30,	MsrRI
	_bitEqu	31,	MsrLE


;	Special Purpose Registers (SPRs) not understood by MPW

l2cr					equ		1017


;	Alignment for NanoKernel interrupt routines (mostly Interrupts.s)

kIntAlign				equ		5



;	Junk


;	IRP is 10 pages below KDP (measured start to start)
;	This should be neatened up to describe the kernel global area
IRPOffset	equ		(-10) * 4096
kKDPfromIRP	equ		10 * 4096
kPoolOffsetFromGlobals equ (-7) * 4096				; goes all the way up to 24 bytes short of PSA



;	Branch instruction BO fields
;	(disregarding static prediction :)
BO_IF			equ		12
BO_IF_NOT		equ		4

Z				equ		0x80000000


;	SIGP (SIGnal Plugin) selectors used by the kernel:
kStartProcessor		equ		1	; r4 = target CPU idx, r5 = cpu's entry point, r6 = entry point's r3 (CPU struct ptr)
kStopProcessor		equ		3	; r4 = target CPU idx
kResetProcessor		equ		4	; r4 = target CPU idx
kAlert				equ		5	; r4 = target CPU idx? ; my name, has something to do with timers
kSIGP6				equ		6	; r4 = target CPU idx?
kSIGP7				equ		7	; r4 = target CPU idx?
kSynchClock			equ		8	; r4 = target CPU idx, 
kSIGP9				equ		9	; no args?
kGetProcessorTemp	equ		12	; r4 = selector (ignored on Core99), r5 = cpu ID ; my name
kSIGP17				equ		17	; r4 = target CPU idx?


; Exception cause equates
; System = FFFFFFFF, Alt = 7DF2F700 (ecInstPageFault and ecDataPageFault disabled), same +/- VM
ecNoException				equ		0		; Exception
ecSystemCall				equ		1		; ?
ecTrapInstr					equ		2		; Exception
ecFloatException			equ		3		; Exception
ecInvalidInstr				equ		4		; Exception
ecPrivilegedInstr			equ		5		; ?
ecMachineCheck				equ		7		; Exception
ecInstTrace					equ		8		; Exception
ecInstInvalidAddress		equ		10		; Exception
ecInstHardwareFault			equ		11		; Exception
ecInstPageFault				equ		12		; Exception
ecInstSupAccessViolation	equ		14		; Exception

;	Usually from MemRetryDSI (also IntAlignment and IntMachineCheck)
ecDataInvalidAddress		equ		18		; ExceptionMemRetried
ecDataHardwareFault			equ		19		; ExceptionMemRetried
ecDataPageFault				equ		20		; ExceptionMemRetried
ecDataWriteViolation		equ		21		; ExceptionMemRetried
ecDataSupAccessViolation	equ		22		; ExceptionMemRetried
ecDataSupWriteViolation		equ		23		; ?
ecUnknown24					equ		24		; ExceptionMemRetried


;	Runtime Flag equates
	_bitEqu	0,	Flag0
	_bitEqu	1,	Flag1
	_bitEqu	2,	Flag2
	_bitEqu	3,	Flag3
	_bitEqu	4,	Flag4
	_bitEqu	5,	Flag5
	_bitEqu	6,	Flag6
	_bitEqu	7,	Flag7
	_bitEqu	8,	FlagEmu
	_bitEqu	9,	Flag9
	_bitEqu	10,	FlagBlue
	_bitEqu	11,	Flag11
	_bitEqu	12,	FlagVec
	_bitEqu	13,	FlagHasMQ
	_bitEqu	14,	Flag14
	_bitEqu	15,	Flag15
	_bitEqu	16,	FlagSIGP
	_bitEqu	17,	Flag17
	_bitEqu	18,	Flag18
	_bitEqu	19,	Flag19
	_bitEqu	20,	FlagFE0
	_bitEqu	21,	FlagSE
	_bitEqu	22,	FlagBE
	_bitEqu	23,	FlagFE1
	_bitEqu	24,	Flag24
	_bitEqu	25,	Flag25
	_bitEqu	26,	Flag26
	_bitEqu	27,	FlagLowSaves
	_bitEqu	28,	Flag28
	_bitEqu	29,	Flag29
	_bitEqu	30,	Flag30
	_bitEqu	31,	Flag31
