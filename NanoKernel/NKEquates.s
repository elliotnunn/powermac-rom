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
IRPOffset	equ		(-10) * 4096
kKDPfromIRP	equ		10 * 4096




noErr					equ		0
