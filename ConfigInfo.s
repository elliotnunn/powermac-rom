;	ROM version of NKConfigurationInfo struct, based on Mac OS ROM 8=9=10.
;	Lives at ROM + 0x30d000 (and other addresses on OldWorld).

;	From start of ConfigInfo to end of LoMemInit = 4k:



;	Auto-align fields

	aligning on



	import	RomTop, RomBtm
	import	Mac68kRomTop, Mac68kRomBtm
	import	ExTblTop
	import	NKTop
	import	EmTop, EmBtm, EmEntry, EmKernelTrapTable
	import	OpcodeTblTop, OpcodeTblBtm



ConfigInfo

; These sums are not checked on NewWorld, but :Tools:ToolSource:RiscLayout.c calcs them anyway
	dcb.l	8, 0						; 000 ; ROMByteCheckSums		; ROM Checksums - one word for each of 8 byte lanes
	dcb.l	2, 0						; 020 ; ROMCheckSum64			; ROM Checksum - 64 bit sum of doublewords

	dc.l	RomTop-ConfigInfo			; 028 ; ROMImageBaseOffset		; Offset of Base of total ROM image
	dc.l	RomBtm-RomTop				; 02c ; ROMImageSize			; Number of bytes in ROM image
	dc.l	0							; 030 ; ROMImageVersion			; ROM Version number for entire ROM

; ROM component Info (offsets are from base of ConfigInfo page)
	dc.l	Mac68kRomTop-ConfigInfo		; 034 ; Mac68KROMOffset			; Offset of base of Macintosh 68K ROM
	dc.l	Mac68kRomBtm-Mac68kRomTop	; 038 ; Mac68KROMSize			; Number of bytes in Macintosh 68K ROM
	
	dc.l	ExTblTop-ConfigInfo			; 03c ; ExceptionTableOffset	; Offset of base of PowerPC Exception Table Code
	dc.l	0xc000						; 040 ; ExceptionTableSize		; Number of bytes in PowerPC Exception Table Code (generous)

	dc.l	RomTop+0x320000-ConfigInfo	; 044 ; HWInitCodeOffset		; Offset of base of Hardware Init Code (no longer exists)
	dc.l	0x10000						; 048 ; HWInitCodeSize			; Number of bytes in Hardware Init Code

	dc.l	NKTop-ConfigInfo			; 04c ; KernelCodeOffset		; Offset of base of NanoKernel Code
	dc.l	0x10000						; 050 ; KernelCodeSize			; Number of bytes in NanoKernel Code (too small)

	dc.l	EmTop-ConfigInfo			; 054 ; EmulatorCodeOffset		; Offset of base of Emulator Code
	dc.l	EmBtm-EmTop					; 058 ; EmulatorCodeSize		; Number of bytes in Emulator Code

	dc.l	OpcodeTblTop-ConfigInfo		; 05c ; OpcodeTableOffset		; Offset of base of Opcode Table
	dc.l	OpcodeTblBtm-OpcodeTblTop	; 060 ; OpcodeTableSize			; Number of bytes in Opcode Table

; Offsets within the Emulator Data Page.
	string	AsIs
@s	dc.b	'NewWorld v1.0'				; 064 ; BootstrapVersion		; Bootstrap loader version info
	org		@s + 16

	dc.l	0xf00						; 074 ; BootVersionOffset		; offset within EmulatorData of BootstrapVersion
	dc.l	0x100						; 078 ; ECBOffset				; offset within EmulatorData of ECB
	dc.l	0x070						; 07c ; IplValueOffset			; offset within EmulatorData of IplValue

; Offsets within the Emulator Code.
	dc.l	EmEntry-EmTop				; 080 ; EmulatorEntryOffset		; offset within Emulator Code of entry point
	dc.l	EmKernelTrapTable-EmTop		; 084 ; KernelTrapTableOffset	; offset within Emulator Code of KernelTrapTable

; Interrupt Passing Masks.
	dc.l	0x00200000					; 088 ; TestIntMaskInit			; initial value for test interrupt mask
	dc.l	0xff9fffff					; 08c ; ClearIntMaskInit		; initial value for clear interrupt mask
	dc.l	0x00e00000					; 090 ; PostIntMaskInit			; initial value for post interrupt mask
	dc.l	0x808e0000					; 094 ; LA_InterruptCtl			; logical address of Interrupt Control I/O page
	dc.b	6							; 098 ; InterruptHandlerKind	; kind of handler to use

	dc.l	0x5fffe000					; 09c ; LA_InfoRecord			; logical address of InfoRecord page
	dc.l	0x68ffe000					; 0a0 ; LA_KernelData			; logical address of KernelData page
	dc.l	0x68fff000					; 0a4 ; LA_EmulatorData			; logical address of EmulatorData page
	dc.l	0x68080000					; 0a8 ; LA_DispatchTable		; logical address of Dispatch Table
	dc.l	0x68060000					; 0ac ; LA_EmulatorCode			; logical address of Emulator Code

	dc.l	LowMemVals-ConfigInfo	; 0b0 ; MacLowMemInitOffset		; offset to list of LowMem addr/data values


;
;	Then the pagemap init stuff is filled by the trampoline at boot
;


; Address Space Mapping
	dc.l	0							; 0b4 ; PageAttributeInit		; default WIMG, PP settings for PTE creation
	dc.l	0							; 0b8 ; PageMapInitSize			; size of page mapping info
	dc.l	0							; 0bc ; PageMapInitOffset		; offset to page mapping info (from base of ConfigInfo)
	dc.l	0							; 0c0 ; PageMapIRPOffset		; offset of InfoRecord map info (from base of PageMap)
	dc.l	0							; 0c4 ; PageMapKDPOffset		; offset of KernelData map info (from base of PageMap)
	dc.l	0							; 0c8 ; PageMapEDPOffset		; offset of EmulatorData map info (from base of PageMap)

	dcb.l	32, 0						; 0cc ; SegMap32SupInit				; 32 bit mode Segment Map Supervisor space
	dcb.l	32, 0						; 14c ; SegMap32UsrInit				; 32 bit mode Segment Map User space
	dcb.l	32, 0						; 1cc ; SegMap32CPUInit				; 32 bit mode Segment Map CPU space
	dcb.l	32, 0						; 24c ; SegMap32OvlInit				; 32 bit mode Segment Map Overlay mode

	dcb.l	32, 0						; 2cc ; BATRangeInit			; BAT mapping ranges

	dc.l	0							; 34c ; BatMap32SupInit				; 32 bit mode BAT Map Supervisor space
	dc.l	0							; 350 ; BatMap32UsrInit				; 32 bit mode BAT Map User space
	dc.l	0							; 354 ; BatMap32CPUInit				; 32 bit mode BAT Map CPU space
	dc.l	0							; 358 ; BatMap32OvlInit				; 32 bit mode BAT Map Overlay mode

; Only needed for Smurf
	dc.l	0							; 35c ; SharedMemoryAddr		; physical address of Mac/Smurf shared message mem

	dc.l	-1							; 360 ; PA_RelocatedLowMemInit	; physical address of RelocatedLowMem

	dc.l	0x330000 - 0x30d000			; 364 ; OpenFWBundleOffset		; Offset of base of OpenFirmware PEF Bundle
	dc.l	0x20000						; 368 ; OpenFWBundleSize		; Number of bytes in OpenFirmware PEF Bundle

	dc.l	0xff800000					; 36c ; LA_OpenFirmware			; logical address of Open Firmware
	dc.l	0x00400000					; 370 ; PA_OpenFirmware			; physical address of Open Firmware
	dc.l	0xfff0c000					; 374 ; LA_HardwarePriv			; logical address of HardwarePriv callback

;	There are still some fixed-location fields here that the Trampoline will populate,
;	but the ROM we are building contains just zeros.



;
;	Key/value pairs for initializing Low Memory Globals.
;	(at the end of ConfigInfo's 4k max size)
;

;	A wee little macro to write LoMem key/value pairs *below* the asm location counter

	macro
	LowMem	&addr, &val
@b
	org		@b - 4
	dc.l	&val
	org		@b - 8
	dc.l	&addr
	org		@b - 8
	endm


;	Sentinel zero at end (late address) of list

	org		4096 - 4
	dc.l	0
	org		4096 - 4


;	The table (older RISC versions have more in here.)

	;	The 68k emulator's cold-start vector, points to a "JMP StartBoot"
	;	instruction in the 68k ROM header. (Normally this value would be
	;	read from the ROM while it was overlaid on RAM at cold start, but
	;	why emulate that on a PowerPC?)

	;	SheepShaver patches the 68k reset vector around this location,
	;	but assumed offset 0xfd8.

	LowMem	0x00000004,		0xffc0002a

LowMemVals
