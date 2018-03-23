;_______________________________________________________________________
;	Equates for the whole NanoKernel
;_______________________________________________________________________


kNanoKernelVersion		equ		$0228		


;	PowerPC Machine Status Register (MSR) bits
;	(borrowing the _bitEqu macro from NKInfoRecordsPriv.s)

	_bitEqu	MSR_POW, 13
	_bitEqu	MSR_ILE, 15
	_bitEqu	MSR_EE, 16
	_bitEqu	MSR_PR, 17
	_bitEqu	MSR_FP, 18
	_bitEqu	MSR_ME, 19
	_bitEqu	MSR_FE0, 20
	_bitEqu	MSR_SE, 21
	_bitEqu	MSR_BE, 22
	_bitEqu	MSR_FE1, 23
	_bitEqu	MSR_IP, 25
	_bitEqu	MSR_IR, 26
	_bitEqu	MSR_DR, 27
	_bitEqu	MSR_RI, 30
	_bitEqu	MSR_LE, 31


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
