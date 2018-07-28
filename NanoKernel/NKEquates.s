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



kNanoKernelVersion		equ		$0101	


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
ecNoException				equ		0
ecSystemCall				equ		1
ecTrapInstr					equ		2
ecFloatException			equ		3
ecInvalidInstr				equ		4
ecPrivilegedInstr			equ		5
ecMachineCheck				equ		7
ecInstTrace					equ		8
ecInstInvalidAddress		equ		10
ecInstHardwareFault			equ		11
ecInstPageFault				equ		12
ecInstSupAccessViolation	equ		14
ecDataInvalidAddress		equ		18
ecDataHardwareFault			equ		19
ecDataPageFault				equ		20
ecDataWriteViolation		equ		21
ecDataSupAccessViolation	equ		22
ecDataSupWriteViolation		equ		23
ecUnknown24					equ		24


; FLAGS r7/cr

crMaskAll equ %11111111

; Bits 0-7 (CR0-CR1): Exception Cause Number (see equates)
crMaskExceptionNum equ %11000000
maskExceptionNum  equ 0xFF000000

crMaskFlags equ %00111111
maskFlags  equ 0x00FFFFFF

; Bits 8-15 (CR2-CR3) Global Flags
crMaskGlobalFlags equ %00110000
maskGlobalFlags  equ 0x00FF0000
	_bitEqu	8,	GlobalFlagSystem				; raised when System (Emulator) Context is running
	_bitEqu	13,	GlobalFlagMQReg					; raised when POWER "Multiply-Quotient" register is present

; Bits 24-31 (CR6-CR7) Context Flags
crMaskContextFlags equ %00001111
maskContextFlags  equ 0x0000FFFF
	; Bits 20-23 (CR5) MSR Flags FE0/SE/BE/FE1:
crMaskMsrFlags equ %00000100
maskMsrFlags  equ 0x00000F00
	; Bits 24-31 (CR6-CR7) Other Context Flags:
	_bitEqu	26,	ContextFlagTraceWhenDone		; raised when MSR[SE] is up but we get an unrelated interrupt
	_bitEqu	27,	ContextFlagMemRetryErr			; raised when an exception is raised during MemRetry
	_bitEqu	31,	ContextFlagResumeMemRetry		; allows MemRetry to be resumed (raised by userspace?)


mrOpflag1 equ cr3_lt
mrOpflag2 equ cr3_gt
mrOpflag3 equ cr3_eq
mrFlagDidLoad equ cr3_so
