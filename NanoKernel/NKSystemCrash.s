SystemCrash
	mfsprg0	r1
	stw		r0, KDP.ThudSavedR0(r1)

	mfspr	r0, sprg1
	stw		r0, KDP.ThudSavedR1(r1)

	stmw	r2, KDP.ThudSavedR2(r1)

	mfspr	r0, cr
	stw		r0, KDP.ThudSavedCR(r1)

	mfspr	r0, mq
	stw		r0, KDP.ThudSavedMQ(r1)

	mfspr	r0, xer
	stw		r0, KDP.ThudSavedXER(r1)

	mfspr	r0, sprg2
	stw		r0, KDP.ThudSavedSPRG2(r1)

	mfspr	r0, ctr
	stw		r0, KDP.ThudSavedCTR(r1)

	mfspr	r0, pvr
	stw		r0, KDP.ThudSavedPVR(r1)

	mfspr	r0, dsisr
	stw		r0, KDP.ThudSavedDSISR(r1)
	mfspr	r0, dar
	stw		r0, KDP.ThudSavedDAR(r1)

	mfspr	r0, tbu
	stw		r0, KDP.ThudSavedTBU(r1)

	mfspr	r0, tb
	stw		r0, KDP.ThudSavedTB(r1)

	mfspr	r0, dec
	stw		r0, KDP.ThudSavedDEC(r1)

	mfspr	r0, hid0
	stw		r0, KDP.ThudSavedHID0(r1)

	mfspr	r0, sdr1
	stw		r0, KDP.ThudSavedSDR(r1)

	mfspr	r0, srr0
	stw		r0, KDP.ThudSavedSRR0(r1)
	mfspr	r0, srr1
	stw		r0, KDP.ThudSavedSRR(r1)
	mfspr	r0, msr
	stw		r0, KDP.ThudSavedMSR(r1)

	mfsr	r0, 0
	stw		r0, KDP.ThudSavedSR0(r1)
	mfsr	r0, 1
	stw		r0, KDP.ThudSavedSR1(r1)
	mfsr	r0, 2
	stw		r0, KDP.ThudSavedSR2(r1)
	mfsr	r0, 3
	stw		r0, KDP.ThudSavedSR3(r1)
	mfsr	r0, 4
	stw		r0, KDP.ThudSavedSR4(r1)
	mfsr	r0, 5
	stw		r0, KDP.ThudSavedSR5(r1)
	mfsr	r0, 6
	stw		r0, KDP.ThudSavedSR6(r1)
	mfsr	r0, 7
	stw		r0, KDP.ThudSavedSR7(r1)
	mfsr	r0, 8
	stw		r0, KDP.ThudSavedSR8(r1)
	mfsr	r0, 9
	stw		r0, KDP.ThudSavedSR9(r1)
	mfsr	r0, 10
	stw		r0, KDP.ThudSavedSR10(r1)
	mfsr	r0, 11
	stw		r0, KDP.ThudSavedSR11(r1)
	mfsr	r0, 12
	stw		r0, KDP.ThudSavedSR12(r1)
	mfsr	r0, 13
	stw		r0, KDP.ThudSavedSR13(r1)
	mfsr	r0, 14
	stw		r0, KDP.ThudSavedSR14(r1)
	mfsr	r0, 15
	stw		r0, KDP.ThudSavedSR15(r1)

	mfspr	r0, msr
	ori		r0, r0, 0x2000
	mtmsr	r0
	stfd	f0, KDP.ThudSavedF0(r1)
	stfd	f1, KDP.ThudSavedF1(r1)
	stfd	f2, KDP.ThudSavedF2(r1)
	stfd	f3, KDP.ThudSavedF3(r1)
	stfd	f4, KDP.ThudSavedF4(r1)
	stfd	f5, KDP.ThudSavedF5(r1)
	stfd	f6, KDP.ThudSavedF6(r1)
	stfd	f7, KDP.ThudSavedF7(r1)
	stfd	f8, KDP.ThudSavedF8(r1)
	stfd	f9, KDP.ThudSavedF9(r1)
	stfd	f10, KDP.ThudSavedF10(r1)
	stfd	f11, KDP.ThudSavedF11(r1)
	stfd	f12, KDP.ThudSavedF12(r1)
	stfd	f13, KDP.ThudSavedF13(r1)
	stfd	f14, KDP.ThudSavedF14(r1)
	stfd	f15, KDP.ThudSavedF15(r1)
	stfd	f16, KDP.ThudSavedF16(r1)
	stfd	f17, KDP.ThudSavedF17(r1)
	stfd	f18, KDP.ThudSavedF18(r1)
	stfd	f19, KDP.ThudSavedF19(r1)
	stfd	f20, KDP.ThudSavedF20(r1)
	stfd	f21, KDP.ThudSavedF21(r1)
	stfd	f22, KDP.ThudSavedF22(r1)
	stfd	f23, KDP.ThudSavedF23(r1)
	stfd	f24, KDP.ThudSavedF24(r1)
	stfd	f25, KDP.ThudSavedF25(r1)
	stfd	f26, KDP.ThudSavedF26(r1)
	stfd	f27, KDP.ThudSavedF27(r1)
	stfd	f28, KDP.ThudSavedF28(r1)
	stfd	f29, KDP.ThudSavedF29(r1)
	stfd	f30, KDP.ThudSavedF30(r1)
	stfd	f31, KDP.ThudSavedF31(r1)
	mffs	f31
	lwz		r0, KDP.ThudSavedF31+4(r1)
	stfd	f31, KDP.ThudSavedF31+4(r1)
	stw		r0, KDP.ThudSavedF31+4(r1)

	mfspr	r0, lr
	stw		r0, KDP.ThudSavedLR(r1)

########################################################################

	lis		r2, 2			; Count down from 64k to find a zero
@nonzero
	lwzu	r0, -4(r2)
	mr.		r2, r2
	bne		@nonzero

@retryrtc					; Save RTC in "Mac/Smurf shared message mem"
	mfrtcu	r2
	mfrtcl	r3
	mfrtcu	r0
	xor.	r0, r0, r2
	bne		@retryrtc
	lwz		r1, KDP.SharedMemoryAddr(r1)
	stw		r2, 0(r1)
	ori		r3, r3, 1
	stw		r3, 4(r1)

	dcbf	0, r1
	sync

@loopforever
	lwz		r1, 0(0)
	addi	r1, r1, 1
	stw		r1, 0(0)
	li		r1, 0
	dcbst	r1, r1
	b		@loopforever
