;	Registers passed in by HardwareInit
rCI set r3 ; NKConfigurationInfo
rPI set r4 ; NKProcessorInfo
rSI set r5 ; NKSystemInfo
rDI set r6 ; NKDiagInfo

;	Other registers we use
rED set r8 ; Emulator Data Page

########################################################################

	li		r0, 0		; Zero lots of fields

########################################################################

ClearSPRs
	mtsr	0, r0
	mtsr	1, r0
	mtsr	2, r0
	mtsr	3, r0
	mtsr	4, r0
	mtsr	5, r0
	mtsr	6, r0
	mtsr	7, r0
	mtsr	8, r0
	mtsr	9, r0
	mtsr	10, r0
	mtsr	11, r0
	mtsr	12, r0
	mtsr	13, r0
	mtsr	14, r0
	mtsr	15, r0

	mtspr	rtcl, r0
	mtspr	rtcu, r0

########################################################################

AlignFirstBankToPAR
	lwz		r12, NKConfigurationInfo.PA_RelocatedLowMemInit(rCI)	; Scoop the ram before this ptr out of banks
																	; so that PAR starts at PA_RelocatedLowMemInit
	lwz		r11, NKSystemInfo.Bank0Start(rSI)
	add		r11, r11, r12
	stw		r11, NKSystemInfo.Bank0Start(rSI)

	lwz		r11, NKSystemInfo.Bank0Size(rSI)
	subf	r11, r12, r11
	stw		r11, NKSystemInfo.Bank0Size(rSI)

	lwz		r11, NKSystemInfo.PhysicalMemorySize(rSI)
	subf	r11, r12, r11
	stw		r11, NKSystemInfo.PhysicalMemorySize(rSI)

########################################################################

InitKernelMemory
	lwz		r15, NKSystemInfo.PhysicalMemorySize(rSI)	; Size the HTAB for 2 entries per page
	subi	r15, r15, 1
	cntlzw	r12, r15
	lis		r14, 0x00ff									; r14 = size-1
	srw		r14, r14, r12
	ori		r14, r14, 0xffff							; Obey architecture min and max size
	clrlwi	r14, r14, 9


	addis	r15, r15, 0x40								; Size the PageList
	rlwinm	r15, r15, 32-10, 10, 19						; (4b entry per page, total rounded to nearest page)


	add		r15, r15, r14								; Total = PageList + KDP/EDP (2 pages) + HTAB
	addi	r15, r15, 0x2001


	addi	r10, rSI, NKSystemInfo.EndOfBanks			; Choose which bank of physical RAM to use
@nextbank												; (no need to edit the bank table)
	lwz		r11, -4(r10)
	lwzu	r12, -8(r10)
	add		r11, r12, r11								; r12 = bank start, r11 = bank end

	andc	r13, r11, r14								; Check if HTAB fits in this bank,
	subf	r13, r15, r13								; while remaining aligned to its own size
	cmplw	r13, r12
	blt		@nextbank
	cmplw	r13, r11
	bgt		@nextbank


	add		r12, r13, r15								; base of address range we will use
	subf	r12, r14, r12								; r12 = ptr to HTAB (inside address range)
	inslwi	r12, r14, 16, 16							; SDR1 = HTABORG || HTABMASK (16b each)
	mtspr	sdr1, r12


	clrrwi	r11, r12, 16								; Init KDP, 2 pages below HTAB
	subi	r1, r11, 0x2000
	lwz		r11, KDP.CrashSDR1(r1)
	mtsprg	0, r1
	cmpw	r12, r11
	lis		r11, 0x7fff
	bne		@did_not_panic
	subf	r11, r13, r1
	addi	r11, r11, KDP.CrashTop
@did_not_panic

	subf	r12, r14, r15								; Erase all of kernel globals, except crash data
	subi	r12, r12, 1
@eraseloop
	subic.	r12, r12, 4
	subf	r10, r11, r12
	cmplwi	cr7, r10, KDP.CrashBtm - KDP.CrashTop
	ble		cr7, @skipwrite
	stwx	r0, r13, r12
@skipwrite
	bne		@eraseloop

########################################################################

CopyInfoRecords
	addi	r11, r1, KDP.ProcInfo
	li		r10, NKProcessorInfo.Size
@loop_procinfo
	subic.	r10, r10, 4
	lwzx	r12, rPI, r10
	stwx	r12, r11, r10
	bgt		@loop_procinfo

	addi	r11, r1, KDP.SysInfo
	li		r10, NKSystemInfo.Size
@loop_sysinfo
	subic.	r10, r10, 4
	lwzx	r12, rSI, r10
	stwx	r12, r11, r10
	bgt		@loop_sysinfo

	addi	r11, r1, KDP.DiagInfo
	li		r10, NKDiagInfo.Size
@loop_diaginfo
	subic.	r10, r10, 4
	lwzx	r12, rDI, r10
	stwx	r12, r11, r10
	bgt		@loop_diaginfo

########################################################################

InitKernelGlobals
	stw		rCI, KDP.ConfigInfoPtr(r1)

	addi	r12, r14, 1
	stw		r12, KDP.SysInfo.HashTableSize(r1)

	addi	rED, r1, 0x1000
	stw		rED, KDP.EDPPtr(r1)

	stw		r13, KDP.KernelMemoryBase(r1)
	add		r12, r13, r15
	stw		r12, KDP.KernelMemoryEnd(r1)

	lwz		r12, NKConfigurationInfo.PA_RelocatedLowMemInit(rCI)
	stw		r12, KDP.LowMemPtr(r1)

	lwz		r12, NKConfigurationInfo.SharedMemoryAddr(rCI)
	stw		r12, KDP.SharedMemoryAddr(r1)

	lwz		r12, NKConfigurationInfo.LA_EmulatorCode(rCI)
	lwz		r11, NKConfigurationInfo.KernelTrapTableOffset(rCI)
	add		r12, r12, r11
	stw		r12, KDP.EmuKCallTblPtrLogical(r1)

	bl		* + 4
	mflr	r12
	addi	r12, r12, 4 - *
	stw		r12, KDP.CodeBase(r1)

	_kaddr	r12, r12, MRBase
	stw		r12, KDP.MRBase(r1)

	lwz		r12, NKConfigurationInfo.LA_EmulatorData(rCI)
	lwz		r11, NKConfigurationInfo.ECBOffset(rCI)
	add		r12, r12, r11
	stw		r12, KDP.ECBPtrLogical(r1)

	add		r12, rED, r11
	stw		r12, KDP.ECBPtr(r1)
	stw		r12, KDP.CurCBPtr(r1)

	lwz		r12, NKConfigurationInfo.TestIntMaskInit(rCI)
	stw		r12, KDP.TestIntMaskInit(r1)
	lwz		r12, NKConfigurationInfo.ClearIntMaskInit(rCI)
	stw		r12, KDP.ClearIntMaskInit(r1)
	lwz		r12, NKConfigurationInfo.PostIntMaskInit(rCI)
	stw		r12, KDP.PostIntMaskInit(r1)

	lwz		r12, NKConfigurationInfo.IplValueOffset(rCI)
	add		r12, rED, r12
	stw		r12, KDP.EmuIntLevelPtr(r1)

	lwz		r12, NKConfigurationInfo.SharedMemoryAddr(rCI)
	addi	r12, r12, 0x7c
	stw		r12, KDP.DebugIntPtr(r1)

	lwz		r12, NKConfigurationInfo.PageAttributeInit(rCI)
	stw		r12, KDP.PageAttributeInit(r1)

	addi	r13, r1, KDP.PageMap
	lwz		r12, NKConfigurationInfo.PageMapInitSize(rCI)
	stw		r13, KDP.PageMapStartPtr(r1)
	add		r13, r13, r12
	stw		r13, KDP.PageMapEndPtr(r1)

########################################################################

InitInfoRecords
	lwz		r11, NKConfigurationInfo.LA_InfoRecord(rCI)

	addi	r12, r11, 0xFC0
	stw		r12, 0xFC0(r1)
	stw		r0, 0xFC4(r1)

	addi	r12, r11, 0xFC8
	stw		r12, 0xFC8(r1)
	stw		r0, 0xFCC(r1)

	addi	r12, r11, 0xFD0
	stw		r12, 0xFD0(r1)
	stw		r0, 0xFD4(r1)

	addi	r12, r11, KDP.ProcInfo
	stw		r12, NKProcessorInfoPtr & 0xFFF(r1)
	li		r12, 0x100
	sth		r12, NKProcessorInfoVer & 0xFFF(r1)
	li		r12, NKProcessorInfo.Size
	sth		r12, NKProcessorInfoLen & 0xFFF(r1)

	addi	r12, r11, KDP.NKInfo
	stw		r12, NKNanoKernelInfoPtr & 0xFFF(r1)
	li		r12, kNanoKernelVersion
	sth		r12, NKNanoKernelInfoVer & 0xFFF(r1)
	li		r12, NKNanoKernelInfo.Size
	sth		r12, NKNanoKernelInfoLen & 0xFFF(r1)

	addi	r12, r11, KDP.DiagInfo
	stw		r12, NKDiagInfoPtr & 0xFFF(r1)
	li		r12, 0x100
	sth		r12, NKDiagInfoVer & 0xFFF(r1)
	li		r12, NKDiagInfo.Size
	sth		r12, NKDiagInfoLen & 0xFFF(r1)

	addi	r12, r11, KDP.SysInfo
	stw		r12, NKSystemInfoPtr & 0xFFF(r1)
	li		r12, 0x102
	sth		r12, NKSystemInfoVer & 0xFFF(r1)
	li		r12, NKSystemInfo.Size
	sth		r12, NKSystemInfoLen & 0xFFF(r1)

	addi	r12, r11, KDP.ProcInfo
	stw		r12, 0xFF8(r1)
	li		r12, 0x100
	sth		r12, 0xFFC(r1)
	li		r12, NKProcessorInfo.Size
	sth		r12, 0xFFE(r1)

########################################################################

InitProcessorInfo
	mfpvr	r12
	stw		r12, KDP.ProcInfo.ProcessorVersionReg(r1)
	srwi	r12, r12, 16
	lwz		r11, KDP.CodeBase(r1)
	addi	r10, r1, KDP.ProcInfo.Ovr
	li		r9, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr

	cmpwi	r12, 1 ; 601
	_kaddr	r11, r11, ProcessorInfoTable
	beq		CopyProcessorInfo

	cmpwi	r12, 3 ; 603
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq		CopyProcessorInfo

	cmpwi	r12, 4 ; 604
	addi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	beq		CopyProcessorInfo

	subi	r11, r11, NKProcessorInfo.OvrEnd - NKProcessorInfo.Ovr
	b		CopyProcessorInfo

ProcessorInfoTable
; 601
	dc.l	0x1000		; PageSize
	dc.l	0x8000		; DataCacheTotalSize
	dc.l	0x8000		; InstCacheTotalSize
	dc.w	0x20		; CoherencyBlockSize
	dc.w	0x20		; ReservationGranuleSize
	dc.w	1			; CombinedCaches
	dc.w	0x40		; InstCacheLineSize
	dc.w	0x40		; DataCacheLineSize
	dc.w	0x20		; DataCacheBlockSizeTouch
	dc.w	0x20		; InstCacheBlockSize
	dc.w	0x20		; DataCacheBlockSize
	dc.w	8			; InstCacheAssociativity
	dc.w	8			; DataCacheAssociativity
	dc.w	0x100		; TransCacheTotalSize
	dc.w	2			; TransCacheAssociativity

; 603
	dc.l	0x1000		; PageSize
	dc.l	0x2000		; DataCacheTotalSize
	dc.l	0x2000		; InstCacheTotalSize
	dc.w	0x20		; CoherencyBlockSize
	dc.w	0x20		; ReservationGranuleSize
	dc.w	0			; CombinedCaches
	dc.w	0x20		; InstCacheLineSize
	dc.w	0x20		; DataCacheLineSize
	dc.w	0x20		; DataCacheBlockSizeTouch
	dc.w	0x20		; InstCacheBlockSize
	dc.w	0x20		; DataCacheBlockSize
	dc.w	2			; InstCacheAssociativity
	dc.w	2			; DataCacheAssociativity
	dc.w	0x40		; TransCacheTotalSize
	dc.w	2			; TransCacheAssociativity

; 604
	dc.l	0x1000		; PageSize
	dc.l	0x4000		; DataCacheTotalSize
	dc.l	0x4000		; InstCacheTotalSize
	dc.w	0x20		; CoherencyBlockSize
	dc.w	0x20		; ReservationGranuleSize
	dc.w	0			; CombinedCaches
	dc.w	0x20		; InstCacheLineSize
	dc.w	0x20		; DataCacheLineSize
	dc.w	0x20		; DataCacheBlockSizeTouch
	dc.w	0x20		; InstCacheBlockSize
	dc.w	0x20		; DataCacheBlockSize
	dc.w	4			; InstCacheAssociativity
	dc.w	4			; DataCacheAssociativity
	dc.w	0x40		; TransCacheTotalSize
	dc.w	2			; TransCacheAssociativity

CopyProcessorInfo
@loop
	subic.	r9, r9, 4
	lwzx	r12, r11, r9
	stwx	r12, r10, r9
	bgt		@loop

########################################################################

InitEmulator
	lwz		r11, NKConfigurationInfo.BootVersionOffset(rCI)		; Copy 16b boot ver string
	lwz		r12, NKConfigurationInfo.BootstrapVersion(rCI)			; ("Boot PDM 601 1.0")
	stwux	r12, r11, rED											; into emulator data area
	lwz		r12, NKConfigurationInfo.BootstrapVersion + 4(rCI)
	stw		r12, 4(r11)
	lwz		r12, NKConfigurationInfo.BootstrapVersion + 8(rCI)
	stw		r12, 8(r11)
	lwz		r12, NKConfigurationInfo.BootstrapVersion + 12(rCI)
	stw		r12, 12(r11)


	lwz		r12, NKConfigurationInfo.LA_EmulatorCode(rCI)		; Prepare the System ContextBlock:
	lwz		r11, NKConfigurationInfo.EmulatorEntryOffset(rCI)
	add		r12, r11, r12
	lwz		r11, NKConfigurationInfo.ECBOffset(rCI)					; address of declared Emu entry point
	add		r11, r11, rED
	stw		r12, CB.ExceptionOriginAddr(r11)

	lwz		r12, NKConfigurationInfo.LA_EmulatorData(rCI)			; address of Emu global page
	stw		r12, CB.ExceptionOriginR3(r11)

	lwz		r12, NKConfigurationInfo.LA_DispatchTable(rCI)			; address of 512kb Emu dispatch table
	stw		r12, CB.ExceptionOriginR4(r11)

	lwz		r12, KDP.EmuKCallTblPtrLogical(r1)						; address of KCallReturnFromException trap
	stw		r12, CB.ExceptionHandlerRetAddr(r11)


	lwz		r10, KDP.LowMemPtr(r1)								; Zero out bottom 8k of Low Memory
	li		r9, 0x2000
@zeroloop
	subic.	r9, r9, 4
	stwx	r0, r10, r9
	bne		@zeroloop


	lwz		r11, NKConfigurationInfo.MacLowMemInitOffset(rCI)	; Read address/value pairs from ConfigInfo
	lwz		r10, KDP.LowMemPtr(r1)								; and apply them to Low Memory
	lwzux	r9, r11, rCI
@setloop
	mr.		r9, r9
	beq		@donelm
	lwzu	r12, 4(r11)
	stwx	r12, r10, r9
	lwzu	r9, 4(r11)
	b		@setloop
@donelm


	mfpvr	r7													; Calculate Flags:
	srwi	r7, r7, 16
	cmpwi	r7, 1
	lis		r7, FlagEmu >> 16										; we will enter System Context (all CPUs)
	bne		@not_601
	_bset	r7, r7, bitFlagHasMQ									; but only 601 has MQ register
@not_601
	stw		r7, KDP.Flags(r1)


	lwz		r10, KDP.EmuKCallTblPtrLogical(r1)					; Start at KCallReturnFromException trap


	mfmsr	r14													; Calculate the user space MSR
	andi.	r14, r14, MsrIP											; (not sure why the dot)
	ori		r15, r14, MsrME | MsrDR | MsrRI							; does r15 even get used?
	ori		r11, r14, MsrEE | MsrPR | MsrME | MsrIR | MsrDR | MsrRI	; <- this is the real one


	li		r13, 0												; Zero important registers (r13=CR, r12=LR)
	li		r12, 0
	li		r0, 0
	li		r2, 0
	li		r3, 0
	li		r4, 0

########################################################################

ResetContextClock
	lwz		r8, KDP.ProcInfo.DecClockRateHz(r1)
	stw		r8, KDP.OtherContextDEC(r1)
	mtdec	r8

########################################################################

	b		Reset
