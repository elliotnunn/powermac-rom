Local_Panic		set		*
				b		panic



;	                     major_0x02964

;	Xrefs:
;	major_0x02ccc

major_0x02964	;	OUTSIDE REFERER
	b		AlternateMPCallReturnPath



;	                     major_0x02980

;	Xrefs:
;	major_0x02ccc
;	major_0x03548
;	IntDSIOtherOther
;	IntMachineCheckMemRetry
;	major_0x039dc
;	IntMachineCheck
;	MaskedInterruptTaken
;	major_0x03be0
;	major_0x04180
;	kcRunAlternateContext
;	major_0x046d0
;	IntExternalOrange
;	IntProgram
;	IntTrace
;	FDP_1214

	align	5

major_0x02980	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mtsprg	3, r24
	lwz		r9, -0x000c(r1)
	rlwinm	r23, r17, 31, 27, 31
	rlwnm.	r9, r9, r8,  0x00,  0x00
	bsol-	cr3, major_0x02980_0x100
	lwz		r6, -0x0014(r1)
	ori		r7, r16,  0x10
	neg		r23, r23
	mtcrf	 0x3f, r7
	add		r19, r19, r23
	rlwimi	r7, r8, 24,  0,  7
	lwz		r1, -0x0004(r1)
	slwi	r8, r8,  2
	add		r8, r8, r1
	lwz		r9,  0x0dc0(r8)
	addi	r9, r9,  0x01
	stw		r9,  0x0dc0(r8)
	srwi	r9, r7, 24
	mfsprg	r1, 0
	lwz		r8,  0x0000(r1)
	stw		r8,  0x0104(r6)
	lwz		r8,  0x001c(r1)
	stw		r8,  0x013c(r6)
	lwz		r8,  0x0020(r1)
	stw		r8,  0x0144(r6)
	lwz		r8,  0x0024(r1)
	stw		r8,  0x014c(r6)
	lwz		r8,  0x0028(r1)
	stw		r8,  0x0154(r6)
	lwz		r8,  0x002c(r1)
	stw		r8,  0x015c(r6)
	lwz		r8,  0x0030(r1)
	stw		r8,  0x0164(r6)
	lwz		r8,  0x0034(r1)
	stw		r8,  0x016c(r6)
	cmpwi	cr1, r9,  0x14
	blt-	cr4, major_0x04a20_0x18
	bne-	cr2, major_0x02ccc_0x310
	blt-	major_0x02980_0xa8
	bne-	cr1, major_0x02980_0x178
	b		major_0x02ccc_0x310

major_0x02980_0xa8
	mfsprg	r1, 0
	stw		r10,  0x0084(r6)
	stw		r12,  0x008c(r6)
	stw		r3,  0x0094(r6)
	stw		r4,  0x009c(r6)
	lwz		r8, -0x000c(r1)
	stw		r7,  0x0040(r6)
	stw		r8,  0x0044(r6)
	li		r8,  0x00
	lwz		r10,  0x004c(r6)
	stw		r8, -0x000c(r1)
	lwz		r1, -0x0004(r1)
	lwz		r4,  0x0054(r6)
	lwz		r3,  0x0654(r1)
	blt-	cr2, major_0x02980_0xec
	lwz		r3,  0x05b4(r1)
	rlwinm	r11, r11,  0, 17, 15

major_0x02980_0xec
	lwz		r12,  0x0648(r1)
	bsol-	cr6, major_0x02980_0x114
	rlwinm	r7, r7,  0, 29, 16
	rlwimi	r11, r7,  0, 20, 23
	b		skeleton_key

major_0x02980_0x100
	lwz		r2,  0x0008(r1)
	lwz		r3,  0x000c(r1)
	lwz		r4,  0x0010(r1)
	lwz		r5,  0x0014(r1)
	blr

major_0x02980_0x114	;	OUTSIDE REFERER
	mfsprg	r8, 0
	stw		r17,  0x0064(r6)
	stw		r20,  0x0068(r6)
	stw		r21,  0x006c(r6)
	stw		r19,  0x0074(r6)
	stw		r18,  0x007c(r6)
	lmw		r14,  0x0038(r8)
	blr

major_0x02980_0x134	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mtcrf	 0x3f, r7
	lwz		r9, -0x000c(r1)
	lwz		r1, -0x0004(r1)
	rlwnm.	r9, r9, r8,  0x00,  0x00
	rlwimi	r7, r8, 24,  0,  7
	slwi	r8, r8,  2
	add		r8, r8, r1
	lwz		r9,  0x0dc0(r8)
	addi	r9, r9,  0x01
	stw		r9,  0x0dc0(r8)
	srwi	r9, r7, 24
	blt-	cr4, major_0x04a20_0x18
	bne-	cr2, major_0x02ccc_0x2a4
	cmpwi	cr1, r9,  0x0c
	blt+	major_0x02980_0xa8
	beq-	cr1, major_0x02ccc_0x2a4

major_0x02980_0x178	;	OUTSIDE REFERER
	lwz		r1, -0x0004(r1)
	lwz		r9,  0x0658(r1)
	addi	r8, r1,  0x360
	mtsprg	3, r8
	bltl-	cr2, major_0x02ccc_0x108

major_0x02980_0x18c	;	OUTSIDE REFERER
	mfsprg	r1, 0
	lwz		r8, -0x000c(r1)
	stw		r7,  0x0000(r6)
	stw		r8,  0x0004(r6)
	bns-	cr6, major_0x02980_0x1b8
	stw		r17,  0x0024(r6)
	stw		r20,  0x0028(r6)
	stw		r21,  0x002c(r6)
	stw		r19,  0x0034(r6)
	stw		r18,  0x003c(r6)
	lmw		r14,  0x0038(r1)

major_0x02980_0x1b8
	mfxer	r8
	stw		r13,  0x00dc(r6)
	stw		r8,  0x00d4(r6)
	stw		r12,  0x00ec(r6)
	mfctr	r8
	stw		r10,  0x00fc(r6)
	stw		r8,  0x00f4(r6)
	ble-	cr3, major_0x02980_0x1e8
	lwz		r8,  0x00c4(r9)
	mfspr	r12, mq
	mtspr	mq, r8
	stw		r12,  0x00c4(r6)

major_0x02980_0x1e8
	lwz		r8,  0x0004(r1)
	stw		r8,  0x010c(r6)
	stw		r2,  0x0114(r6)
	stw		r3,  0x011c(r6)
	stw		r4,  0x0124(r6)
	lwz		r8,  0x0018(r1)
	stw		r5,  0x012c(r6)
	stw		r8,  0x0134(r6)
	stw		r14,  0x0174(r6)
	stw		r15,  0x017c(r6)
	stw		r16,  0x0184(r6)
	stw		r17,  0x018c(r6)
	stw		r18,  0x0194(r6)
	stw		r19,  0x019c(r6)
	stw		r20,  0x01a4(r6)
	stw		r21,  0x01ac(r6)
	stw		r22,  0x01b4(r6)
	stw		r23,  0x01bc(r6)
	stw		r24,  0x01c4(r6)
	stw		r25,  0x01cc(r6)
	stw		r26,  0x01d4(r6)
	andi.	r8, r11,  0x2000
	stw		r27,  0x01dc(r6)
	stw		r28,  0x01e4(r6)
	stw		r29,  0x01ec(r6)
	stw		r30,  0x01f4(r6)
	stw		r31,  0x01fc(r6)
	bnel-	major_0x03e18_0xb4
	bge-	cr3, major_0x02980_0x260
	bl		Save_v0_v31

major_0x02980_0x260
	stw		r11,  0x00a4(r6)
	lwz		r8,  0x0000(r9)
	stw		r9, -0x0014(r1)
	xoris	r7, r7,  0x80
	rlwimi	r11, r8,  0, 20, 23
	mr		r6, r9
	rlwimi	r7, r8,  0, 17, 31
	andi.	r8, r11,  0x900
	lwz		r8,  0x0004(r6)
	lwz		r13,  0x00dc(r6)
	stw		r8, -0x000c(r1)
	lwz		r8,  0x00d4(r6)
	lwz		r12,  0x00ec(r6)
	mtxer	r8
	lwz		r8,  0x00f4(r6)
	lwz		r10,  0x00fc(r6)
	mtctr	r8
	bnel-	major_0x03e18_0x8
	lwarx	r8, 0, r1
	sync
	stwcx.	r8, 0, r1
	lwz		r29,  0x00d8(r6)
	lwz		r8,  0x010c(r6)
	cmpwi	r29,  0x00
	stw		r8,  0x0004(r1)
	lwz		r28,  0x0210(r29)
	beq-	major_0x02980_0x2d0
	mtspr	vrsave, r28

major_0x02980_0x2d0
	lwz		r2,  0x0114(r6)
	lwz		r3,  0x011c(r6)
	lwz		r4,  0x0124(r6)
	lwz		r8,  0x0134(r6)
	lwz		r5,  0x012c(r6)
	stw		r8,  0x0018(r1)
	lwz		r14,  0x0174(r6)
	lwz		r15,  0x017c(r6)
	lwz		r16,  0x0184(r6)
	lwz		r17,  0x018c(r6)
	lwz		r18,  0x0194(r6)
	lwz		r19,  0x019c(r6)
	lwz		r20,  0x01a4(r6)
	lwz		r21,  0x01ac(r6)
	lwz		r22,  0x01b4(r6)
	lwz		r23,  0x01bc(r6)
	lwz		r24,  0x01c4(r6)
	lwz		r25,  0x01cc(r6)
	lwz		r26,  0x01d4(r6)
	lwz		r27,  0x01dc(r6)
	lwz		r28,  0x01e4(r6)
	lwz		r29,  0x01ec(r6)
	lwz		r30,  0x01f4(r6)
	lwz		r31,  0x01fc(r6)



;	                      skeleton_key

;	Called when a Gary reset trap is called. When else?

;	Xrefs:
;	major_0x02980
;	IntDecrementer
;	IntISI
;	IntMachineCheck
;	major_0x03be0
;	IntPerfMonitor
;	IntThermalEvent
;	kcRunAlternateContext
;	kcResetSystem
;	IntProgram
;	IntExternalYellow
;	kcVMDispatch
;	major_0x09e28
;	major_0x0a600
;	kcRTASDispatch
;	kcCacheDispatch
;	CommonMPCallReturnPath
;	CommonPIHPath

skeleton_key	;	OUTSIDE REFERER
	andi.	r8, r7,  0x30
	mfsprg	r1, 0
	bnel-	major_0x02ccc
	li		r8,  0x00
	stw		r7, -0x0010(r1)
	stw		r8, -0x0114(r1)
	b		major_0x142a8



;	                     major_0x02ccc

;	Xrefs:
;	major_0x02980
;	skeleton_key

major_0x02ccc	;	OUTSIDE REFERER
	mtcrf	 0x3f, r7
	bns-	cr6, major_0x02ccc_0x18
	rlwinm	r7, r7,  0, 28, 26
	bso-	cr7, major_0x02ccc_0x30
	rlwinm	r7, r7,  0, 27, 25
	b		major_0x02ccc_0x2c

major_0x02ccc_0x18
	bne-	cr6, major_0x02ccc_0x2c
	rlwinm	r7, r7,  0, 27, 25
	stw		r7, -0x0010(r1)
	li		r8,  0x08
	b		major_0x02980_0x134

major_0x02ccc_0x2c
	blr

major_0x02ccc_0x30
	rlwinm.	r8, r7,  0,  8,  8
	beq-	major_0x02ccc_0x108
	stw		r7, -0x0010(r1)
	lwz		r8,  0x0104(r6)
	stw		r8,  0x0000(r1)
	stw		r2,  0x0008(r1)
	stw		r3,  0x000c(r1)
	stw		r4,  0x0010(r1)
	stw		r5,  0x0014(r1)
	lwz		r8,  0x013c(r6)
	stw		r8,  0x001c(r1)
	lwz		r8,  0x0144(r6)
	stw		r8,  0x0020(r1)
	lwz		r8,  0x014c(r6)
	stw		r8,  0x0024(r1)
	lwz		r8,  0x0154(r6)
	stw		r8,  0x0028(r1)
	lwz		r8,  0x015c(r6)
	stw		r8,  0x002c(r1)
	lwz		r8,  0x0164(r6)
	stw		r8,  0x0030(r1)
	lwz		r8,  0x016c(r6)
	stw		r8,  0x0034(r1)
	stmw	r14,  0x0038(r1)
	lwz		r8, -0x0004(r1)
	lwz		r17,  0x0024(r9)
	lwz		r20,  0x0028(r9)
	lwz		r21,  0x002c(r9)
	lwz		r19,  0x0034(r9)
	lwz		r18,  0x003c(r9)
	rlwinm	r16, r7,  0, 28, 26
	lwz		r25,  0x0650(r8)
	rlwinm.	r22, r17, 31, 27, 31
	add		r19, r19, r22
	rlwimi	r25, r17,  7, 25, 30
	lhz		r26,  0x0d20(r25)
	rlwimi	r25, r19,  1, 28, 30
	stw		r16, -0x0010(r1)
	rlwimi	r26, r26,  8,  8, 15		; copy hi byte of entry to second byte of word
	rlwimi	r25, r17,  4, 23, 27
	mtcrf	 0x10, r26					; so the second nybble of the entry is copied to cr3
	lha		r22,  0x0c00(r25)
	addi	r23, r8,  0x4e0
	add		r22, r22, r25
	mfsprg	r24, 3
	mtlr	r22
	mtsprg	3, r23
	mfmsr	r14
	ori		r15, r14,  0x10
	mtmsr	r15
	isync
	rlwimi	r25, r26,  2, 22, 29		; apparently the lower byte of the entry is an FDP (code?) offset, /4!
	bnelr-
	b		FDP_011c



major_0x02ccc_0x108	;	OUTSIDE REFERER
	bl		Save_r14_r31		; r8 := EWA

	lwz		r31, EWA.PA_CurTask(r8)
	lwz		r8,  0x00f4(r31)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Queue.kIDClass

	mr		r30, r8
	bnel-	major_0x02ccc_0x20c
	lwz		r28,  0x0028(r30)
	cmpwi	r28,  0x00
	beql-	major_0x02ccc_0x20c

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r29,  0x0064(r31)
	ori		r29, r29,  0x200
	ori		r29, r29,  0x1000
	stw		r29,  0x0064(r31)
	lwz		r17,  0x0008(r28)
	stw		r17,  0x0028(r30)
	lwz		r17,  0x0000(r31)
	stw		r17,  0x0010(r28)
	li		r18, -0x7271
	stw		r18,  0x0014(r28)
	stw		r18,  0x00f8(r31)
	stw		r10,  0x0018(r28)
	_log	'Blue task suspended. Notifying exception handler - srr1/0 '
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw
	_log	'lr '
	mr		r8, r12
	bl		Printw
	_log	'^n'
	mr		r31, r30
	mr		r8, r28
	bl		major_0x0c8b4
	b		major_0x142dc

major_0x02ccc_0x20c
	mflr	r16
	_log	'Blue task terminated - no exception handler registered - srr1/0 '
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw
	_log	'lr '
	mr		r8, r12
	bl		Printw
	_log	'^n'
	mtlr	r16
	b		Local_Panic

major_0x02ccc_0x2a4	;	OUTSIDE REFERER
	bsol+	cr6, Local_Panic

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	mr		r30, r10
	lwz		r29,  0x0018(r8)
	lwz		r31, -0x0008(r8)
	stw		r29,  0x0134(r6)
	stw		r30,  0x0074(r6)
	stw		r7,  0x0040(r6)
	lwz		r1, -0x0004(r1)

	_Lock			PSA.SchLock, scratch1=r28, scratch2=r29

	mr		r8, r31
	bl		major_0x13e4c
	lwz		r16,  0x0064(r31)
	srwi	r8, r7, 24
	rlwinm.	r16, r16,  0,  9,  9
	cmpwi	cr1, r8,  0x0c
	bne-	major_0x02ccc_0x524
	bne-	cr1, major_0x02ccc_0x524
	lwz		r8,  0x00e0(r31)
	addi	r8, r8,  0x01
	stw		r8,  0x00e0(r31)
	b		major_0x02ccc_0x380

major_0x02ccc_0x310	;	OUTSIDE REFERER
	bnsl+	cr6, Local_Panic
	bl		major_0x02980_0x114
	stw		r10,  0x0084(r6)
	rlwinm	r7, r7,  0, 28, 26

;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	lwz		r30,  0x0074(r6)
	lwz		r29,  0x0018(r8)
	lwz		r31, -0x0008(r8)
	stw		r29,  0x0134(r6)
	stw		r7,  0x0040(r6)
	lwz		r1, -0x0004(r1)

	_Lock			PSA.SchLock, scratch1=r28, scratch2=r29

	mr		r8, r31
	bl		major_0x13e4c
	lwz		r16,  0x0064(r31)
	srwi	r8, r7, 24
	rlwinm.	r16, r16,  0,  9,  9
	cmpwi	cr1, r8,  0x14
	bne-	major_0x02ccc_0x524
	bne-	cr1, major_0x02ccc_0x524
	lwz		r8,  0x00e4(r31)
	addi	r8, r8,  0x01
	stw		r8,  0x00e4(r31)

major_0x02ccc_0x380
	mfsprg	r14, 0
	rlwinm	r7, r7,  0, 27, 25
	rlwinm	r7, r7,  0,  0, 30
	lwz		r29, -0x00e4(r14)
	lis		r17,  0x4152
	ori		r17, r17,  0x4541
	lwz		r16,  0x0004(r29)
	cmplw	r16, r17
	bnel+	Local_Panic
	lwz		r17,  0x0034(r29)
	addi	r17, r17,  0x01
	stw		r17,  0x0034(r29)
	lwz		r8,  0x0018(r29)

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	lwz		r16,  0x06b4(r1)
	cmpwi	r9,  0x0c
	cmpwi	cr1, r16,  0x00
	mr		r26, r8
	bne-	major_0x02ccc_0x430
	beq-	cr1, major_0x02ccc_0x3d4
	beq-	cr2, major_0x02ccc_0x430

major_0x02ccc_0x3d4
	lwz		r16,  0x0064(r31)
	addi	r17, r31,  0x08
	addi	r18, r31, 160
	stw		r18,  0x0000(r17)
	stw		r18,  0x0008(r17)
	lwz		r19,  0x000c(r18)
	stw		r19,  0x000c(r17)
	stw		r17,  0x0008(r19)
	stw		r17,  0x000c(r18)
	li		r17,  0x01
	ori		r16, r16,  0x2000
	stw		r17,  0x00b0(r31)
	stw		r16,  0x0064(r31)
	rlwinm	r30, r30,  0,  0, 19
	lwz		r27,  0x0000(r29)
	lwz		r28,  0x0000(r31)
	stw		r30,  0x0010(r26)
	stw		r27,  0x0014(r26)
	stw		r28,  0x0018(r26)
	mr		r30, r26
	bl		major_0x0db04
	cmpwi	r8,  0x00
	beq+	major_0x02964

major_0x02ccc_0x430
	mfcr	r28
	li		r8,  0x1c
	beq-	cr2, major_0x02ccc_0x4a8
	bl		PoolAlloc_with_crset
	mr.		r26, r8
	beq-	major_0x02ccc_0x50c
	addi	r17, r31,  0x08
	addi	r18, r31, 160
	stw		r18,  0x0000(r17)
	stw		r18,  0x0008(r17)
	lwz		r19,  0x000c(r18)
	stw		r19,  0x000c(r17)
	stw		r17,  0x0008(r19)
	stw		r17,  0x000c(r18)
	li		r17,  0x01
	stw		r17,  0x00b0(r31)
	lwz		r27,  0x0000(r29)
	lis		r8,  0x6e6f
	ori		r8, r8,  0x7465
	lwz		r29,  0x00a0(r31)
	stw		r27,  0x0010(r26)
	stw		r29,  0x0014(r26)
	stw		r8,  0x0004(r26)
	stw		r30,  0x0018(r26)
	mr		r8, r26
	addi	r31, r1, -0xa24
	bl		major_0x0c8b4
	lwz		r8, -0x0410(r1)
	bl		major_0x0dce8
	b		AlternateMPCallReturnPath

major_0x02ccc_0x4a8
	mr		r8, r31
	bl		TaskReadyAsPrev
	sync
	lwz		r31, PSA.SchLock + Lock.Count(r1)
	cmpwi	cr1, r31,  0x00
	li		r31,  0x00
	bne+	cr1, major_0x02ccc_0x4cc
	mflr	r31
	bl		panic

major_0x02ccc_0x4cc
	stw		r31, PSA.SchLock + Lock.Count(r1)
	mtcr	r28
	bns-	cr6, major_0x02ccc_0x504
	lwz		r8,  0x0064(r6)
	lwz		r9,  0x0068(r6)
	stw		r8,  0x0024(r6)
	stw		r9,  0x0028(r6)
	lwz		r8,  0x006c(r6)
	lwz		r9,  0x0074(r6)
	stw		r8,  0x002c(r6)
	stw		r9,  0x0034(r6)
	lwz		r8,  0x007c(r6)
	stw		r8,  0x003c(r6)
	crclr	cr6_so

major_0x02ccc_0x504
;	r6 = ewa
	bl		Restore_r14_r31
	b		major_0x02980_0x178

major_0x02ccc_0x50c
	li		r16,  0x02
	stb		r16,  0x0019(r31)
	mr		r8, r31
	bl		TaskReadyAsPrev
	bl		major_0x14af8_0xa0
	b		AlternateMPCallReturnPath

major_0x02ccc_0x524
	b		FuncExportedFromTasks



;	                     IntDecrementer

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDecrementer	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	lwz		r8,  0x05a0(r1)
	rlwinm.	r9, r11,  0, 16, 16
	cmpwi	cr1, r8,  0x00
	beq-	MaskedInterruptTaken
	beq-	cr1, IntDecrementer_0x54

	stw		r16,  0x0184(r6)
	stw		r17,  0x018c(r6)
	stw		r18,  0x0194(r6)
	stw		r25,  0x01cc(r6)
	bl		major_0x14a98
	ble-	IntDecrementer_0x48
	lwz		r8, -0x09d4(r1)
	mtspr	dec, r8
	lwz		r16,  0x0184(r6)
	lwz		r17,  0x018c(r6)
	lwz		r18,  0x0194(r6)
	b		skeleton_key

IntDecrementer_0x48
	lwz		r16,  0x0184(r6)
	lwz		r17,  0x018c(r6)
	lwz		r18,  0x0194(r6)

IntDecrementer_0x54
;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)


	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8,  0x0e8c(r1)
	addi	r8, r8,  0x01
	stw		r8,  0x0e8c(r1)
	bl		TimerDispatch
	sync
	lwz		r8, PSA.SchLock + Lock.Count(r1)
	cmpwi	cr1, r8,  0x00
	li		r8,  0x00
	bne+	cr1, IntDecrementer_0x9c
	mflr	r8
	bl		panic

IntDecrementer_0x9c
	stw		r8, PSA.SchLock + Lock.Count(r1)

;	r6 = ewa
	bl		Restore_r14_r31
	b		skeleton_key



;	                         IntDSI

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDSI	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r2,  0x0008(r1)
	mfsprg	r11, 1
	stw		r0,  0x0000(r1)
	stw		r11,  0x0004(r1)
	li		r0,  0x00
	mfspr	r10, srr0
	mfspr	r11, srr1
	mfsprg	r12, 2
	mfcr	r13
	mfsprg	r24, 3
	lwz		r16, -0x0010(r1)
	lwz		r1, -0x0004(r1)
	mfspr	r26, dsisr
	addi	r23, r1,  0x4e0
	andis.	r28, r26,  0x400
	mtsprg	3, r23
	mfmsr	r14
	bne-	major_0x03324_0x9c
	ori		r15, r14,  0x10
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync



;	                     major_0x03324

;	Xrefs:
;	IntDSI
;	FDP_1214

major_0x03324	;	OUTSIDE REFERER
	rlwinm.	r18, r27, 18, 25, 29
	lwz		r25,  0x0650(r1)
	li		r21,  0x00
	mfsprg	r1, 0
	beq-	major_0x03324_0x18
	lwzx	r18, r1, r18

major_0x03324_0x18
	andis.	r26, r27,  0xec00
	lwz		r16, -0x0010(r1)
	rlwinm	r17, r27,  0,  6, 15
	rlwimi	r16, r16, 27, 26, 26
	bge-	major_0x03324_0x58
	rlwimi	r25, r27,  7, 26, 29
	rlwimi	r25, r27, 12, 25, 25
	lwz		r26,  0x0b80(r25)
	extsh	r23, r27
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	mtcr	r26
	add		r18, r18, r23
	crclr	cr5_so
	rlwimi	r17, r26,  6, 26,  5
	blr

major_0x03324_0x58
	rlwimi	r25, r27, 27, 26, 29
	rlwimi	r25, r27,  0, 25, 25
	rlwimi	r25, r27,  6, 23, 24
	rlwimi	r25, r27,  4, 22, 22
	lwz		r26,  0x0800(r25)
	rlwinm	r23, r27, 23, 25, 29
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	mtcr	r26
	lwzx	r23, r1, r23
	crclr	cr5_so
	rlwimi	r17, r26,  6, 26,  5
	add		r18, r18, r23
	blelr-	cr3
	neg		r23, r23
	add		r18, r18, r23
	blr

major_0x03324_0x9c	;	OUTSIDE REFERER
	ori		r15, r14,  0x10
	mr		r28, r16
	mfspr	r18, dar
	mfspr	r19, dsisr
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync
	mtsprg	3, r24
	lwz		r1, -0x0004(r1)
	mr		r31, r19
	mr		r8, r18
	li		r9,  0x00
	bl		V2P
	mr		r16, r28
	crset	cr3_so
	mfsprg	r1, 0
	beq-	major_0x03324_0x12c
	mr		r18, r8
	rlwinm	r28, r27, 13, 25, 29
	andis.	r9, r31,  0x200
	rlwimi	r18, r17,  0,  0, 19
	beq-	major_0x03324_0x118
	lwzx	r31, r1, r28
	stwcx.	r31, 0, r18
	sync
	dcbf	0, r18
	mfcr	r31
	rlwimi	r13, r31,  0,  0,  3
	b		FDP_0da0

major_0x03324_0x118
	lwarx	r31, 0, r18
	sync
	dcbf	0, r18
	stwx	r31, r1, r28
	b		FDP_0da0

major_0x03324_0x12c
	subi	r10, r10, 4
	b		FDP_0da0



;	                      IntAlignment

;	Xrefs:
;	"vec"

;	This int handler is our best foothold into the FDP!

	align	kIntAlign

IntAlignment	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r2,  0x0008(r1)
	mfsprg	r11, 1
	stw		r0,  0x0000(r1)
	stw		r11,  0x0004(r1)
	li		r0,  0x00

	lwz		r11, EWA.PA_CurTask(r1)
	lwz		r16, EWA.Flags(r1)
	lwz		r21, Task.ThingThatAlignVecHits(r11)
	lwz		r1, -0x0004(r1)		;	wha???

	lwz		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.MisalignmentCount(r1)
	addi	r11, r11, 1
	stw		r11, KDP.NanoKernelInfo + NKNanoKernelInfo.MisalignmentCount(r1)

	mfspr	r10, srr0
	mfspr	r11, srr1
	mfsprg	r12, 2
	mfcr	r13
	mfsprg	r24, 3
	mfspr	r27, dsisr
	mfspr	r18, dar

	rlwinm.	r21, r21,  0,  9,  9		;	KDP.ThingThatAlignVecHits

	addi	r23, r1, KDP.RedVecBase

	bne-	major_0x03548_0x20

	;	DSISR for misaligned X-form instruction:

	;	(0) 0 (14)||(15) 29:30 (16)||(17) 25 (17)||(18) 21:24 (21)||(22) rD (26)||(27) rA? (31)

	;	DSISR for misaligned D-form instruction:
	
	;	(0)        zero        (16)||(17)  5 (17)||(18)  1:4  (21)||(22) rD (26)||(27) rA? (31)

FDP_TableBase		equ		0xa00

	;	Virtual PC might put the thing in MSR_LE mode
	rlwinm.	r21, r11, 0, MSR_LEbit, MSR_LEbit			;	msr bits in srr1

	;	Get the FDP and F.O. if we were in MSR_LE mode
	lwz		r25,  KDP.PA_FDP(r1)
	bne-	major_0x03548_0x20


	rlwinm.	r21, r27, 17, 30, 31	; evaluate hi two bits of XO (or 0 for d-form?)

	rlwinm	r17, r27, 16,  6, 15	; save src and dest register indices in r17

	mfsprg	r1, 0

	rlwimi	r25, r27, 24, 23, 29	; add constant fields from dsisr (*4) to FDP


	rlwimi	r16, r16, 27, 26, 26	; AllCpuFeatures: copy bit 21 to bit 26

	bne-	@regidx

	;	D-form (immediate-indexed) instruction
	lwz		r26,  FDP_TableBase + 4*(0x40 + 0x20)(r25)	; use upper quarter of table
	mfmsr	r14
	rlwimi	r25, r26, 26, 22, 29	; third byte of lookup value is a /4 code offset in FDP
	mtlr	r25						; so get ready to go there
	ori		r15, r14,  0x10
	mtcr	r26
	rlwimi	r17, r26,  6, 26,  5	; wrap some shite around the register values
	crclr	cr5_so
	blr

@regidx
	;	X-form (register-indexed) instruction
	lwz		r26,  FDP_TableBase(r25)
	mfmsr	r14
	mtsprg	3, r23
	rlwimi	r25, r26, 26, 22, 29
	mtlr	r25
	ori		r15, r14,  0x10
	mtcr	r26
	rlwimi	r17, r26,  6, 26,  5
	crclr	23						; unset bit 23 = cr5_so
	bgelr-	cr3						; jump now if bit 12 is off

	;	if bit 12 was on, turn on paging and fetch the offending insn
	;	and also activate the Red vector table
	mtmsr	r15
	isync
	lwz		r27,  0x0000(r10)
	mtmsr	r14
	isync
	mtsprg	3, r24
	blr



;	                     major_0x03548

;	Xrefs:
;	IntAlignment
;	major_0x05808

major_0x03548	;	OUTSIDE REFERER
	sync
	mtmsr	r14
	isync
	mflr	r23
	icbi	0, r23
	sync
	isync
	blr

major_0x03548_0x20	;	OUTSIDE REFERER
	li		r8,  0x00
	lis		r17, -0x100
	mtcr	r8
	mr		r19, r18
	rlwimi	r17, r27,  7, 31, 31
	xori	r17, r17,  0x01
	li		r8,  0x18
	b		major_0x02980



;	                    IntDSIOtherOther

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDSIOtherOther	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mfspr	r31, dsisr
	mfspr	r27, dar
	andis.	r28, r31,  0xc030
	lwz		r1, -0x0004(r1)
	bne-	IntDSIOtherOther_0x1c8
	mfspr	r30, srr1
	andi.	r28, r30,  0x4000
	mfsprg	r30, 0
	beq-	IntDSIOtherOther_0x100
	stw		r8, -0x00e0(r30)
	stw		r9, -0x00dc(r30)
	mfcr	r8
	stw		r16, -0x00d8(r30)
	stw		r17, -0x00d4(r30)
	stw		r18, -0x00d0(r30)
	stw		r19, -0x00cc(r30)
	stw		r8, -0x00c8(r30)
	lwz		r8, -0x001c(r30)
	mr		r9, r27
	bl		FindAreaAbove
	lwz		r16,  0x0024(r8)
	lwz		r17,  0x0028(r8)
	cmplw	r27, r16
	cmplw	cr7, r27, r17
	blt-	IntDSIOtherOther_0xe0
	bgt-	cr7, IntDSIOtherOther_0xe0
	mr		r31, r8
	mr		r8, r27
	bl		MPCall_95_0x1e4
	beq-	IntDSIOtherOther_0xe0
	lwz		r8,  0x0000(r30)
	lwz		r16,  0x0098(r31)
	rlwinm	r28, r8,  0, 29, 30
	cmpwi	cr7, r28,  0x04
	cmpwi	r28,  0x02
	beq-	cr7, IntDSIOtherOther_0xe0
	beq-	IntDSIOtherOther_0xe0

IntDSIOtherOther_0x98
	addi	r17, r31,  0x90
	cmpw	r16, r17
	addi	r17, r16,  0x14
	beq-	IntDSIOtherOther_0x158
	lwz		r9,  0x0010(r16)
	add		r9, r9, r17

IntDSIOtherOther_0xb0
	lwz		r18,  0x0000(r17)
	cmplw	cr7, r17, r9
	lwz		r19,  0x0004(r17)
	bgt-	cr7, IntDSIOtherOther_0xd8
	cmplw	r27, r18
	cmplw	cr7, r27, r19
	blt-	IntDSIOtherOther_0xd0
	ble-	cr7, IntDSIOtherOther_0xe0

IntDSIOtherOther_0xd0
	addi	r17, r17,  0x08
	b		IntDSIOtherOther_0xb0

IntDSIOtherOther_0xd8
	lwz		r16,  0x0008(r16)
	b		IntDSIOtherOther_0x98

IntDSIOtherOther_0xe0
	mfsprg	r30, 0
	mfspr	r31, dsisr
	lwz		r8, -0x00e0(r30)
	lwz		r9, -0x00dc(r30)
	lwz		r16, -0x00d8(r30)
	lwz		r17, -0x00d4(r30)
	lwz		r18, -0x00d0(r30)
	lwz		r19, -0x00cc(r30)

IntDSIOtherOther_0x100
	andis.	r28, r31,  0x800
	addi	r29, r1, 800
	bnel-	PagingFunc3
	li		r28,  0x43
	and		r28, r31, r28
	cmpwi	cr7, r28,  0x43
	beql+	Local_Panic
	mfsprg	r28, 2
	mtlr	r28
	bne-	cr7, IntDSIOtherOther_0x144
	mfspr	r28, srr0
	addi	r28, r28,  0x04
	lwz		r26,  0x0e90(r1)
	mtspr	srr0, r28
	addi	r26, r26,  0x01
	stw		r26,  0x0e90(r1)
	b		IntDSIOtherOther_0x19c

IntDSIOtherOther_0x144
	andi.	r28, r31,  0x03
	li		r8,  0x16
	beq+	major_0x02980
	li		r8,  0x15
	b		major_0x02980

IntDSIOtherOther_0x158
	mfsprg	r30, 0
	lwz		r16,  0x0f00(r1)
	lwz		r8, -0x00c8(r30)
	addi	r16, r16,  0x01
	mtcr	r8
	lwz		r9, -0x00dc(r30)
	stw		r16,  0x0f00(r1)
	lwz		r16, -0x00d8(r30)
	lwz		r17, -0x00d4(r30)
	lwz		r18, -0x00d0(r30)
	lwz		r19, -0x00cc(r30)
	lwz		r8, -0x00e0(r30)
	mfspr	r29, srr1
	mfsprg	r28, 2
	rlwinm	r29, r29,  0, 18, 16
	mtlr	r28
	mtspr	srr1, r29

IntDSIOtherOther_0x19c
	mfsprg	r1, 1
	rlwinm	r26, r25, 30, 24, 31
	rfi
	dcb.b	32, 0


IntDSIOtherOther_0x1c8
	andis.	r28, r31,  0x8010
	bne-	IntMachineCheckMemRetry_0x14c

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	bl		PagingFunc1
	sync
	lwz		r28, -0x0b90(r1)
	cmpwi	cr1, r28,  0x00
	li		r28,  0x00
	bne+	cr1, IntDSIOtherOther_0x208
	mflr	r28
	bl		panic

IntDSIOtherOther_0x208
	stw		r28, -0x0b90(r1)
	mfsprg	r28, 2
	mtlr	r28
	beq+	IntDSIOtherOther_0x19c
	li		r8,  0x12
	bge+	major_0x02980
	li		r8,  0x14
	b		major_0x02980



;	                IntMachineCheckMemRetry

;	Xrefs:
;	"vec"
;	IntDSIOtherOther

IntMachineCheckMemRetry	;	OUTSIDE REFERER
	mfsprg	r1, 0
	mr		r28, r8

	lwz		r27, EWA.CPUBase + CPU.ID(r1)
	_log	'CPU '
	mr		r8, r27
	bl		Printw

	_log	'MemRetry machine check - last EA '
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r27,  0x0694(r1)
	mr		r8, r27
	bl		Printw

	_log	' SRR1 '
	mfspr	r8, srr1
	mr		r8, r8
	bl		Printw

	_log	' SRR0 '
	mfspr	r8, srr0
	mr		r8, r8
	bl		Printw
	_log	'^n'

	mr		r8, r28
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r27,  0x0694(r1)
	subf	r28, r19, r27
	cmpwi	r28, -0x10
	blt-	IntMachineCheckMemRetry_0x14c
	cmpwi	r28,  0x10
	bgt-	IntMachineCheckMemRetry_0x14c

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r29

	lwz		r28,  0x0e98(r1)
	addi	r28, r28,  0x01
	stw		r28,  0x0e98(r1)
	lwz		r29,  0x0698(r1)
	li		r28,  0x00
	stw		r28,  0x0000(r29)
	mfspr	r28, pvr
	rlwinm.	r28, r28,  0,  0, 14
	sync
	tlbie	r27
	beq-	IntMachineCheckMemRetry_0x124
	sync
	tlbsync

IntMachineCheckMemRetry_0x124
	sync
	isync
	sync
	lwz		r28, -0x0b90(r1)
	cmpwi	cr1, r28,  0x00
	li		r28,  0x00
	bne+	cr1, IntMachineCheckMemRetry_0x148
	mflr	r28
	bl		panic

IntMachineCheckMemRetry_0x148
	stw		r28, -0x0b90(r1)

IntMachineCheckMemRetry_0x14c	;	OUTSIDE REFERER
	cmplw	r10, r19
	li		r8,  0x13
	bne+	major_0x02980
	mfsprg	r1, 0
	mtsprg	3, r24
	lmw		r14,  0x0038(r1)
	li		r8,  0x0b
	b		major_0x02980_0x134



;	                         IntISI

;	Xrefs:
;	"vec"

	align	kIntAlign

IntISI	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	andis.	r8, r11,  0x4020
	beq-	major_0x039dc_0x14
	mfsprg	r8, 0
	stmw	r14,  0x0038(r8)

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	mr		r27, r10
	bl		PagingFunc1
	sync
	lwz		r28, -0x0b90(r1)
	cmpwi	cr1, r28,  0x00
	li		r28,  0x00
	bne+	cr1, IntISI_0x50
	mflr	r28
	bl		panic

IntISI_0x50
	stw		r28, -0x0b90(r1)
	mfsprg	r8, 0
	bne-	major_0x039dc
	mfsprg	r24, 3
	mfmsr	r14
	ori		r15, r14,  0x10
	addi	r23, r1,  0x4e0
	mtsprg	3, r23
	mr		r19, r10
	mtmsr	r15
	isync
	lbz		r23,  0x0000(r19)
	sync
	mtmsr	r14
	isync
	mfsprg	r8, 0
	mtsprg	3, r24
	lmw		r14,  0x0038(r8)
	b		skeleton_key



;	                     major_0x039dc

;	Xrefs:
;	IntISI
;	IntDSIOther

major_0x039dc	;	OUTSIDE REFERER
	lmw		r14,  0x0038(r8)
	li		r8,  0x0c
	blt+	major_0x02980_0x134
	li		r8,  0x0a
	b		major_0x02980_0x134

major_0x039dc_0x14	;	OUTSIDE REFERER
	andis.	r8, r11,  0x800
	li		r8,  0x0e
	bne+	major_0x02980_0x134
	li		r8,  0x0b
	b		major_0x02980_0x134



;	                    IntMachineCheck

;	Xrefs:
;	"vec"

IntMachineCheck	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	lwz		r9, EWA.CPUBase + CPU.ID(r8)
	_log	'CPU '
	mr		r8, r9
	bl		Printw

	_log	'Machine check at '		; srr1/srr0
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw

	_log	'- last unmapped EA '
	lwz		r8,  0x0694(r1)
	mr		r8, r8
	bl		Printw
	_log	'^n'

	rlwinm.	r8, r11,  0,  2,  2
	beq-	IntMachineCheck_0xa4
	bl		kcCacheDispatch_0x39c
	b		skeleton_key

IntMachineCheck_0xa4
	li		r8,  0x07
	b		major_0x02980_0x134



;	                     MaskedInterruptTaken

;	Xrefs:
;	IntDecrementer
;	IntPerfMonitor
;	IntThermalEvent
;	IntExternalYellow

MaskedInterruptTaken	;	OUTSIDE REFERER
	_log	'*** CPU MALFUNCTION - Masked interrupt punched through. SRR1/0 '
	mr		r8, r11
	bl		Printw
	mr		r8, r10
	bl		Printw
	_log	'^n'
	lis		r10, -0x4523
	ori		r10, r10,  0xcb00
	li		r8,  0x07
	b		major_0x02980_0x134



;	                      IntDSIOther

;	Xrefs:
;	"vec"

	align	kIntAlign

IntDSIOther	;	OUTSIDE REFERER
	mfspr	r8, dsisr
	rlwimi	r11, r8,  0,  0,  9
	andis.	r8, r11,  0x4020
	beq+	major_0x039dc_0x14
	mfsprg	r8, 0
	stmw	r14,  0x0038(r8)
	lwz		r1, -0x0004(r8)

	_Lock			PSA.HTABLock, scratch1=r28, scratch2=r31

	mfspr	r27, dar
	bl		PagingFunc1
	sync
	lwz		r28, -0x0b90(r1)
	cmpwi	cr1, r28,  0x00
	li		r28,  0x00
	bne+	cr1, IntDSIOther_0x58
	mflr	r28
	bl		panic

IntDSIOther_0x58
	stw		r28, -0x0b90(r1)
	mfsprg	r8, 0
	bne+	major_0x039dc
	lmw		r14,  0x0038(r8)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




;	                     major_0x03be0

;	Xrefs:
;	"sup"

	align	kIntAlign

;	dead code?

	dc.l	0x81610e40
	dc.l	0x7d8a6378
	dc.l	0x396b0001
	dc.l	0x91610e40
	dc.l	0x7d7b02a6
	dc.l	0x50e7deb4

kcReturnFromException	;	OUTSIDE REFERER
	ori		r11, r11,  0x8000
	mtcrf	 0x3f, r7
	cmplwi	cr1, r3,  0x01
	blt-	cr4, major_0x04a20_0x18
	blt-	cr1, major_0x03be0_0x58
	beq-	cr1, major_0x03be0_0x90
	addi	r8, r3, -0x20
	lwz		r9,  0x0eac(r1)
	cmplwi	r8,  0xe0
	addi	r9, r9,  0x01
	stw		r9,  0x0eac(r1)
	mfsprg	r1, 0
	rlwimi	r7, r3, 24,  0,  7
	blt-	major_0x03be0_0xe8
	li		r8,  0x02
	b		major_0x02980_0x134

major_0x03be0_0x58
	mfsprg	r1, 0
	lwz		r8,  0x0040(r6)
	lwz		r10,  0x0084(r6)
	rlwimi	r7, r8,  0, 17,  7
	lwz		r8,  0x0044(r6)
	rlwimi	r11, r7,  0, 20, 23
	stw		r8, -0x000c(r1)
	andi.	r8, r11,  0x900
	lwz		r12,  0x008c(r6)
	lwz		r3,  0x0094(r6)
	lwz		r4,  0x009c(r6)
	bnel-	major_0x03e18
	addi	r9, r6,  0x40
	b		skeleton_key

major_0x03be0_0x90
	lwz		r9,  0x0ea8(r1)
	lwz		r8,  0x0040(r6)
	addi	r9, r9,  0x01
	stw		r9,  0x0ea8(r1)
	mfsprg	r1, 0
	lwz		r10,  0x0084(r6)
	rlwimi	r7, r8,  0, 17,  7
	lwz		r8,  0x0044(r6)
	mtcrf	 0x0f, r7
	rlwimi	r11, r7,  0, 20, 23
	stw		r8, -0x000c(r1)
	lwz		r12,  0x008c(r6)
	lwz		r3,  0x0094(r6)
	lwz		r4,  0x009c(r6)
	bne-	cr2, major_0x03be0_0xe8
	bns-	cr6, major_0x03be0_0xe8
	stmw	r14,  0x0038(r1)
	lwz		r17,  0x0064(r6)
	lwz		r20,  0x0068(r6)
	lwz		r21,  0x006c(r6)
	lwz		r19,  0x0074(r6)
	lwz		r18,  0x007c(r6)

major_0x03be0_0xe8
	beq+	cr2, major_0x02980_0x178
	crclr	cr6_so
	mfspr	r10, srr0
	li		r8,  0x02
	b		major_0x02980_0x134



;	                   save_all_registers

;	Xrefs:
;	IntPerfMonitor
;	IntThermalEvent

	align	5

save_all_registers	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stw		r6,  0x0018(r1)
	mfsprg	r6, 1
	stw		r6,  0x0004(r1)
	lwz		r6, -0x0014(r1)
	stw		r0,  0x0104(r6)
	stw		r7,  0x013c(r6)
	stw		r8,  0x0144(r6)
	stw		r9,  0x014c(r6)
	stw		r10,  0x0154(r6)
	stw		r11,  0x015c(r6)
	stw		r12,  0x0164(r6)
	stw		r13,  0x016c(r6)
	li		r0,  0x00
	mfspr	r10, srr0
	mfspr	r11, srr1
	mfcr	r13
	mfsprg	r12, 2
	lwz		r7, -0x0010(r1)
	lwz		r1, -0x0004(r1)

;	r6 = ewa
	b		Save_r14_r31
;	r8 = sprg0 (not used by me)



;	How we arrive here:
;
;		PowerPC exception vector saved r1/LR in SPRG1/2 and
;		jumped where directed by the vecTable pointed to by
;		SPRG3. That function bl'ed here.
;
;
;	When we arrive here:
;
;		r1 is saved in SPRG1 (r1 itself is junk)
;		LR is saved in SPRG2 (LR itself contains return addr)
;
;
;	Before we return:
;
;		Reg		Contains			Original saved in
;		---------------------------------------------
;		 r0		0					ContextBlock
;		 r1		KDP					EWA
;		 r2		(itself)					
;		 r3		(itself)
;		 r4		(itself)
;		 r5		(itself)
;		 r6		ContextBlock		EWA
;		 r7		AllCpuFeatures		ContextBlock
;		 r8		EWA					ContextBlock
;		 r9		(itself)			ContextBlock
;		r10		SRR0				ContextBlock
;		r11		SRR1				ContextBlock
;		r12		LR					ContextBlock
;		r13		CR					ContextBlock
;
;
;	Can be followed up by a call to Save_r14_r31,
;	(which will put them in the ContextBlock too).

	align	5

int_prepare

	;	Get EWA pointer in r1 (phew)
	mfsprg	r1, 0

	;	Save r6 in EWA
	stw		r6, EWA.r6(r1)

	;	Save pre-interrupt r1 (which SPRG1 held) to EWA
	mfsprg	r6, 1
	stw		r6, EWA.r1(r1)

	;	Get ContextBlock pointer in r6 (phew)
	lwz		r6, EWA.PA_ContextBlock(r1)

	;	Save r0, r7-r13 in ContextBlock
	stw		r0, ContextBlock.r0(r6)
	stw		r7, ContextBlock.r7(r6)
	stw		r8, ContextBlock.r8(r6)
	stw		r9, ContextBlock.r9(r6)
	stw		r10, ContextBlock.r10(r6)
	stw		r11, ContextBlock.r11(r6)
	stw		r12, ContextBlock.r12(r6)
	stw		r13, ContextBlock.r13(r6)

	;	Zero r0 (convenient)
	li		r0, 0

	;	Make some useful special registers conveniently available
	mfspr	r10, srr0
	mfspr	r11, srr1
	mfcr	r13
	mfsprg	r12, 2

	;	Point r8 to EWA
	mr		r8, r1

	;	Features in r7, KDP in r8
	lwz		r7, EWA.Flags(r1)
	lwz		r1, EWA.PA_KDP(r1)

	blr



;	                      IntFPUnavail

;	Xrefs:
;	"vec"

	align	kIntAlign

IntFPUnavail	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stw		r11, -0x0290(r1)
	stw		r6, -0x028c(r1)
	lwz		r6, -0x0004(r1)
	lwz		r11,  0x0e88(r6)
	addi	r11, r11,  0x01
	stw		r11,  0x0e88(r6)
	mfspr	r11, srr1
	ori		r11, r11,  0x2000
	mtspr	srr1, r11
	mfmsr	r11
	ori		r11, r11,  0x2000
	lwz		r6, -0x0014(r1)
	mtmsr	r11
	isync
	bl		LoadFloatsFromContextBlock
	lwz		r11, -0x0290(r1)
	lwz		r6, -0x028c(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




;	                     major_0x03e18

;	Xrefs:
;	major_0x02980
;	major_0x03be0
;	IntFPUnavail
;	kcRTASDispatch

major_0x03e18	;	OUTSIDE REFERER
	rlwinm.	r8, r11,  0, 18, 18
	bnelr-

major_0x03e18_0x8	;	OUTSIDE REFERER
	lwz		r8,  0x00e4(r6)
	rlwinm.	r8, r8,  1,  0,  0
	mfmsr	r8
	ori		r8, r8,  0x2000
	beqlr-
	mtmsr	r8
	isync
	ori		r11, r11,  0x2000

LoadFloatsFromContextBlock	;	OUTSIDE REFERER
	lfd		f31,  0x00e0(r6)
	lfd		f0,  0x0200(r6)
	lfd		f1,  0x0208(r6)
	lfd		f2,  0x0210(r6)
	lfd		f3,  0x0218(r6)
	lfd		f4,  0x0220(r6)
	lfd		f5,  0x0228(r6)
	lfd		f6,  0x0230(r6)
	lfd		f7,  0x0238(r6)
	mtfsf	 0xff, f31
	lfd		f8,  0x0240(r6)
	lfd		f9,  0x0248(r6)
	lfd		f10,  0x0250(r6)
	lfd		f11,  0x0258(r6)
	lfd		f12,  0x0260(r6)
	lfd		f13,  0x0268(r6)
	lfd		f14,  0x0270(r6)
	lfd		f15,  0x0278(r6)
	lfd		f16,  0x0280(r6)
	lfd		f17,  0x0288(r6)
	lfd		f18,  0x0290(r6)
	lfd		f19,  0x0298(r6)
	lfd		f20,  0x02a0(r6)
	lfd		f21,  0x02a8(r6)
	lfd		f22,  0x02b0(r6)
	lfd		f23,  0x02b8(r6)
	lfd		f24,  0x02c0(r6)
	lfd		f25,  0x02c8(r6)
	lfd		f26,  0x02d0(r6)
	lfd		f27,  0x02d8(r6)
	lfd		f28,  0x02e0(r6)
	lfd		f29,  0x02e8(r6)
	lfd		f30,  0x02f0(r6)
	lfd		f31,  0x02f8(r6)
	blr





major_0x03e18_0xb4	;	OUTSIDE REFERER
	mfmsr	r8
	ori		r8, r8,  0x2000
	mtmsr	r8
	isync
	rlwinm	r11, r11,  0, 19, 17
	stfd	f0,  0x0200(r6)
	stfd	f1,  0x0208(r6)
	stfd	f2,  0x0210(r6)
	stfd	f3,  0x0218(r6)
	stfd	f4,  0x0220(r6)
	stfd	f5,  0x0228(r6)
	stfd	f6,  0x0230(r6)
	stfd	f7,  0x0238(r6)
	stfd	f8,  0x0240(r6)
	stfd	f9,  0x0248(r6)
	stfd	f10,  0x0250(r6)
	stfd	f11,  0x0258(r6)
	stfd	f12,  0x0260(r6)
	stfd	f13,  0x0268(r6)
	stfd	f14,  0x0270(r6)
	stfd	f15,  0x0278(r6)
	stfd	f16,  0x0280(r6)
	stfd	f17,  0x0288(r6)
	stfd	f18,  0x0290(r6)
	stfd	f19,  0x0298(r6)
	stfd	f20,  0x02a0(r6)
	stfd	f21,  0x02a8(r6)
	stfd	f22,  0x02b0(r6)
	stfd	f23,  0x02b8(r6)
	mffs	f0
	stfd	f24,  0x02c0(r6)
	stfd	f25,  0x02c8(r6)
	stfd	f26,  0x02d0(r6)
	stfd	f27,  0x02d8(r6)
	stfd	f28,  0x02e0(r6)
	stfd	f29,  0x02e8(r6)
	stfd	f30,  0x02f0(r6)
	stfd	f31,  0x02f8(r6)
	stfd	f0,  0x00e0(r6)
	blr




;	indexed emulation code, mofo

;two instructions per load-store register

	macro
	CreateFloatJumpTable	&opcode, &dest, &highest==31

	if		&highest > 0
		CreateFloatJumpTable	&opcode, &dest, highest = (&highest) - 1
	endif

	&opcode		(&highest), -0x2e0(r1)
	b			&dest

	endm


FloatLoadJumpTable
	CreateFloatJumpTable	lfd, FDP_0da0


FloatSaveJumpTable
	CreateFloatJumpTable	stfd, FDP_003c




;	                     major_0x04180

;	Xrefs:
;	IntPerfMonitor

	align	6

major_0x04180	;	OUTSIDE REFERER
	stw		r6, -0x0290(r1)
	stw		r10, -0x028c(r1)
	stw		r11, -0x0288(r1)
	lwz		r6, -0x0014(r1)
	lwz		r10,  0x00d8(r6)
	mfspr	r11, srr1
	cmpwi	r10,  0x00
	beql-	major_0x04180_0x9c
	oris	r11, r11,  0x200
	stw		r9, -0x027c(r1)
	mtspr	srr1, r11
	mfmsr	r11
	oris	r11, r11,  0x200
	mtmsr	r11
	isync
	bl		Restore_v0_v31
	lwz		r8, -0x0004(r1)
	lwz		r11,  0x0ed4(r8)
	addi	r11, r11,  0x01
	stw		r11,  0x0ed4(r8)
	mtcr	r13
	lwz		r6, -0x0290(r1)
	lwz		r10, -0x028c(r1)
	lwz		r11, -0x0288(r1)
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	lwz		r9, -0x027c(r1)
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0


major_0x04180_0x9c
	mtcr	r13
	lwz		r6, -0x0290(r1)
	lwz		r10, -0x028c(r1)
	lwz		r11, -0x0288(r1)
	lwz		r13, -0x0284(r1)

;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	li		r8,  0x04
	b		major_0x02980_0x134



;	                     IntPerfMonitor

;	Xrefs:
;	"vec"

	align	kIntAlign

IntPerfMonitor	;	OUTSIDE REFERER
	mtlr	r1
	mfsprg	r1, 0
	stw		r8, -0x0280(r1)
	stw		r13, -0x0284(r1)
	mflr	r8
	mfcr	r13
	cmpwi	r8,  0xf20
	beq+	major_0x04180
	mtcr	r13
	lwz		r13, -0x0284(r1)
	lwz		r8, -0x0280(r1)
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq+	MaskedInterruptTaken

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, -0x0414(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne-	IntPerfMonitor_0x88
	lwz		r16, -0x0340(r28)
	lwz		r17, -0x0008(r28)
	stw		r16,  0x0010(r30)
	lwz		r16,  0x0000(r17)
	stw		r16,  0x0014(r30)
	mfspr	r16, 955
	stw		r16,  0x0018(r30)
	bl		major_0x0db04

IntPerfMonitor_0x88
	sync
	lwz		r8, PSA.SchLock + Lock.Count(r1)
	cmpwi	cr1, r8,  0x00
	li		r8,  0x00
	bne+	cr1, IntPerfMonitor_0xa4
	mflr	r8
	bl		panic

IntPerfMonitor_0xa4
	stw		r8, PSA.SchLock + Lock.Count(r1)

;	r6 = ewa
	bl		Restore_r14_r31
	b		skeleton_key



;	                    IntThermalEvent

;	Xrefs:
;	"vec"

	align	kIntAlign

IntThermalEvent	;	OUTSIDE REFERER
	bl		save_all_registers
	mr		r28, r8
	rlwinm.	r9, r11,  0, 16, 16
	beq+	MaskedInterruptTaken
	_log	'Thermal event^n'

	_Lock			PSA.SchLock, scratch1=r8, scratch2=r9

	lwz		r8, -0x0418(r1)

;	r8 = id
 	bl		LookupID
	cmpwi	r9, Notification.kIDClass

	mr		r30, r8
	bne-	IntThermalEvent_0x68
	lwz		r16, -0x0340(r28)
	stw		r16,  0x0010(r30)
	bl		major_0x0db04

IntThermalEvent_0x68
	sync
	lwz		r8, PSA.SchLock + Lock.Count(r1)
	cmpwi	cr1, r8,  0x00
	li		r8,  0x00
	bne+	cr1, IntThermalEvent_0x84
	mflr	r8
	bl		panic

IntThermalEvent_0x84
	stw		r8, PSA.SchLock + Lock.Count(r1)

;	r6 = ewa
	bl		Restore_r14_r31
	b		skeleton_key



;	                     kcRunAlternateContext

;	Xrefs:
;	"sup"

	align	kIntAlign

kcRunAlternateContext	;	OUTSIDE REFERER
	mtcrf	 0x3f, r7
	bnel+	cr2, skeleton_key
	and.	r8, r4, r13
	lwz		r9,  0x0340(r1)
	rlwinm	r8, r3,  0,  0, 25
	cmpw	cr1, r8, r9
	bne+	skeleton_key
	lwz		r9,  0x0344(r1)
	bne-	cr1, major_0x043a0_0x48

major_0x043a0_0x24
	addi	r8, r1,  0x420
	mtsprg	3, r8
	lwz		r8,  0x0648(r1)
	mtcrf	 0x3f, r7
	mfsprg	r1, 0
	clrlwi	r7, r7,  0x08
	stw		r8,  0x005c(r9)
	stw		r9, -0x0014(r1)
	b		major_0x02980_0x18c

major_0x043a0_0x48
	lwz		r9,  0x0348(r1)
	cmpw	cr1, r8, r9
	beq-	cr1, major_0x043a0_0x130
	lwz		r9,  0x0350(r1)
	cmpw	cr1, r8, r9
	beq-	cr1, major_0x043a0_0x110
	lwz		r9,  0x0358(r1)
	cmpw	cr1, r8, r9
	beq-	cr1, major_0x043a0_0xf0
	mfsprg	r1, 0
	stmw	r14,  0x0038(r1)
	lwz		r1, -0x0004(r1)
	cmpw	cr1, r8, r6
	beq-	cr1, major_0x043a0_0x154
	mr		r27, r8
	addi	r29, r1, 800
	bl		PagingFunc3
	clrlwi	r23, r8,  0x14
	beq-	major_0x043a0_0x154
	cmplwi	r23,  0xd00
	mr		r9, r8
	mr		r8, r31
	ble-	major_0x043a0_0xc4
	addi	r27, r27,  0x1000
	addi	r29, r1, 800
	bl		PagingFunc3
	beq-	major_0x043a0_0x154
	addi	r31, r31, -0x1000
	xor		r23, r8, r31
	rlwinm.	r23, r23,  0, 25, 22
	bne-	major_0x043a0_0x154

major_0x043a0_0xc4
	clrlwi	r23, r31,  0x1e
	cmpwi	r23,  0x03
	rlwimi	r8, r9,  0, 20, 31
	beq-	major_0x043a0_0x154
	lwz		r23,  0x0ea4(r1)
	addi	r23, r23,  0x01
	stw		r23,  0x0ea4(r1)
	mfsprg	r1, 0
	lmw		r14,  0x0038(r1)
	lwz		r1, -0x0004(r1)
	stw		r8,  0x035c(r1)

major_0x043a0_0xf0
	lwz		r8,  0x0350(r1)
	stw		r9,  0x0350(r1)
	stw		r8,  0x0358(r1)
	lwz		r9,  0x035c(r1)
	lwz		r8,  0x0354(r1)
	stw		r9,  0x0354(r1)
	stw		r8,  0x035c(r1)
	lwz		r9,  0x0350(r1)

major_0x043a0_0x110
	lwz		r8,  0x0348(r1)
	stw		r9,  0x0348(r1)
	stw		r8,  0x0350(r1)
	lwz		r9,  0x0354(r1)
	lwz		r8,  0x034c(r1)
	stw		r9,  0x034c(r1)
	stw		r8,  0x0354(r1)
	lwz		r9,  0x0348(r1)

major_0x043a0_0x130
	lwz		r8,  0x0340(r1)
	stw		r9,  0x0340(r1)
	stw		r9,  0x05b4(r1)
	stw		r8,  0x0348(r1)
	lwz		r9,  0x034c(r1)
	lwz		r8,  0x0344(r1)
	stw		r9,  0x0344(r1)
	stw		r8,  0x034c(r1)
	b		major_0x043a0_0x24

major_0x043a0_0x154
	mfsprg	r1, 0
	lmw		r14,  0x0038(r1)
	lwz		r1, -0x0004(r1)
	li		r8,  0x02
	b		major_0x02980_0x134



;	                        wordfill

;	Xrefs:
;	setup
;	FillIndigo

;	> r8    = dest
;	> r22   = len in bytes
;	> r23   = fillword

wordfill	;	OUTSIDE REFERER
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne+	wordfill
	blr



;	                       kcResetSystem

;	Handle a 68k reset trap.
;	Some messing around with 601 RTC vs later timebase
;	registers.
;	If Gary Davidian's first name and birthdate were in the
;	68k's A0/A1 (the 'skeleton key'), do something.
;	Otherwise, farm it out to non_skeleton_reset_trap.

;	Xrefs:
;	"sup"

;	> r3    = a0
;	> r4    = a1

	align	kIntAlign

kcResetSystem	;	OUTSIDE REFERER
;	r6 = ewa
	bl		Save_r14_r31
;	r8 = sprg0 (not used by me)

	;	Check for 601 (rtc vs timebase)
	mfpvr	r9
	rlwinm.	r9, r9, 0,  0, 14

	;	This xoris/cmplwi technique is very cool
	xoris	r8, r3, 'Ga'

	beq-	@is_601
	mftb	r9
	b		@endif_601
@is_601
	dialect	POWER
	mfrtcl	r9
	dialect	PowerPC
@endif_601

	;	Not sure why this would need to hit cr0?
	andis.	r9, r9,  0xffff

	cmplwi	r8, 'ry'
	bne-	non_skeleton_reset_trap

	;	r4 (i.e. A1) == 5 May 1956?
	xoris	r8, r4, 0x0505
	cmplwi	r8,     0x1956
	bne-	non_skeleton_reset_trap

	andc	r11, r11, r5
	lwz		r8, ContextBlock.r7(r6)
	or		r11, r11, r8

	_log	'Skeleton key inserted at'

	mr		r8, r11
	bl		Printw

	mr		r8, r10
	bl		Printw

	_log	'^n'
	
	b		skeleton_key



;	                non_skeleton_reset_trap

;	A 68k reset trap without Gary Davidian's magic numbers.

;	Xrefs:
;	kcResetSystem

non_skeleton_reset_trap

	_log	'ResetSystem trap entered^n'

	lwz		r8, KDP.OldKDP(r1)

	cmpwi	r8, 0
	beq+	ResetBuiltinKernel

	_log	'Unplugging the replacement nanokernel^n'

	lwz		r8, KDP.OldKDP(r1)
	mfsprg	r1, 0
	addi	r9, r8, KDP.YellowVecBase
	mtsprg	0, r8		;	old NK has only one EWA!
	mtsprg	3, r9

	lwz		r9, EWA.r1(r1)
	stw		r9, EWA.r1(r8)

	lwz		r9, EWA.r6(r1)
	stw		r9, EWA.r6(r8)

	stw		r6,  0x065c(r8)
	stw		r7,  0x0660(r8)			; ??????????

	lwz		r9, -0x000c(r1)
	stw		r9,  0x0664(r8)

;	r6 = ewa
	bl		Restore_r14_r31
	subi	r10, r10, 4
	lwz		r1, -0x0004(r1)

;	sprg0 = for r1 and r6
;	r1 = kdp
;	r6 = register restore area
;	r7 = flag to insert into XER
;	r10 = new srr0 (return location)
;	r11 = new srr1
;	r12 = lr restore
;	r13 = cr restore
	b		int_teardown



;	                      kcPrioritizeInterrupts

;	Xrefs:
;	"sup"
;	setup
;	IntExternalYellow

;	> r1    = kdp

kcPrioritizeInterrupts	;	OUTSIDE REFERER
	lwz		r9, KDP.PA_InterruptHandler(r1)
	mtlr	r9
	blr



;	Move registers from CB to EWA, and Thud.

	align	kIntAlign

kcThud

	stw		r2, EWA.r2(r1)
	stw		r3, EWA.r3(r1)
	stw		r4, EWA.r4(r1)
	stw		r5, EWA.r5(r1)

	lwz		r8, ContextBlock.r7(r6)
	lwz		r9, ContextBlock.r8(r6)
	stw		r8, EWA.r7(r1)
	stw		r9, EWA.r8(r1)

	lwz		r8, ContextBlock.r9(r6)
	lwz		r9, ContextBlock.r10(r6)
	stw		r8, EWA.r9(r1)
	stw		r9, EWA.r10(r1)

	lwz		r8, ContextBlock.r11(r6)
	lwz		r9, ContextBlock.r12(r6)
	stw		r8, EWA.r11(r1)
	stw		r9, EWA.r12(r1)

	lwz		r8, ContextBlock.r13(r6)
	stw		r8, EWA.r13(r1)

	stmw	r14, EWA.r14(r1)

	bl		Local_Panic



;	                     major_0x046d0

;	Xrefs:
;	"vec"
;	kcThud

major_0x046d0	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	li		r8,  0x02
	b		major_0x02980_0x134



;	                     IntExternalOrange

;	Xrefs:
;	"vec"

	align	kIntAlign

IntExternalOrange	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	mtcrf	 0x3f, r7
	bnel+	cr2, Local_Panic
	li		r8,  0x00
	b		major_0x02980_0x134



;	                       IntProgram

;	Xrefs:
;	"vec"

	align	kIntAlign

IntProgram	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	lwz		r8,  0x0648(r1)
	mtcr	r11
	xor		r8, r10, r8
	bne-	cr3, IntProgram_0x144
	cmplwi	r8,  0x00
	cmplwi	cr1, r8,  0x20
	beq-	IntProgram_0x120
	beq-	cr1, IntProgram_0x120
	cmplwi	r8,  0x0c
	cmplwi	cr1, r8,  0x40
	beq-	IntProgram_0x120
	blt-	cr1, IntProgram_0x110
	bne-	cr6, IntProgram_0x58
	stw		r14,  0x0174(r6)
	mfsprg	r14, 3
	addi	r8, r1, -0x750
	mfmsr	r9
	mtsprg	3, r8
	ori		r8, r9,  0x10
	mtmsr	r8
	isync

IntProgram_0x58
	lwz		r8,  0x0000(r10)
	bne-	cr6, IntProgram_0x74
	isync
	mtmsr	r9
	isync
	mtsprg	3, r14
	lwz		r14,  0x0174(r6)

IntProgram_0x74
	mtcr	r7
	xoris	r8, r8,  0xfff
	cmplwi	r8,  0x10
	cmplwi	cr1, r8,  0x00
	bge-	IntProgram_0x150
	cmplwi	cr7, r8,  0x08
	cmplwi	r8,  0x03
	slwi	r8, r8,  2
	beq-	cr1, IntProgram_0xac
	beq-	cr7, IntProgram_0xd0
	beq-	IntProgram_0xac
	blt-	cr4, IntProgram_0x150
	blt-	cr2, IntProgram_0xac
	ble-	cr2, IntProgram_0x150

IntProgram_0xac
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9,  0x01
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)

IntProgram_0xbc
	lwz		r8, KDP.NanoKernelCallTable(r8)
	mtlr	r8
	addi	r10, r10,  0x04
	rlwimi	r7, r7, 27, 26, 26
	blr

IntProgram_0xd0
	lwz		r9,  0x0104(r6)
	add		r8, r8, r1
	cmpwi	r9, -0x01
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	addi	r9, r9,  0x01
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	bne+	IntProgram_0xbc
	addi	r10, r10,  0x04
	rlwimi	r7, r7, 27, 26, 26
	mfsprg	r8, 0
	rlwimi	r13, r7,  8,  2,  2
	lwz		r9, -0x0008(r8)
	xoris	r13, r13,  0x2000
	lwz		r8,  0x00ec(r9)
	stw		r8,  0x0104(r6)
	b		skeleton_key

IntProgram_0x110
	mtcr	r7
	blt-	cr4, IntProgram_0x150
	blt-	cr2, IntProgram_0x120
	ble-	cr2, IntProgram_0x150

IntProgram_0x120
	add		r8, r8, r1
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	lwz		r10, KDP.NanoKernelCallTable(r8)
	addi	r9, r9,  0x01
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts(r8)
	mtlr	r10
	mr		r10, r12
	rlwimi	r7, r7, 27, 26, 26
	blr

IntProgram_0x144
	blt+	cr3, FDP_1214
	bgt-	cr3, FDP_1214
	bso-	cr2, IntProgram_0x160

IntProgram_0x150
	rlwinm	r8, r11, 17, 28, 29
	addi	r8, r8,  0x4b3
	rlwnm	r8, r8, r8,  0x1c,  0x1f
	b		major_0x02980_0x134

IntProgram_0x160
	li		r8,  0x03
	bso+	cr3, major_0x02980_0x134
	addi	r10, r10,  0x04
	rlwimi	r7, r7, 27, 26, 26
	b		major_0x02980_0x134



;	                   IntExternalYellow

;	Xrefs:
;	"vec"

	align	kIntAlign

IntExternalYellow	;	OUTSIDE REFERER

	bl		int_prepare

	;	RET		r0 = 0
	;			r1 = KernelData
	;			r6 = ECB
	;			r7 = AllCpuFeatures
	;			r8 = EWA (pretend KDP)
	;			r10 = SRR0
	;			r11 = SRR1
	;			r12 = LR from SPRG2
	;			r13 = CR


	;	Sanity check

	rlwinm.	r9, r11, 0, MSR_EEbit, MSR_EEbit
	beq+	MaskedInterruptTaken


	;	How many CPUs?

	lwz		r9, EWA.CPUBase + CPU.CgrpList + LLL.Freeform(r8)
	lwz		r9, CoherenceGroup.CpuCount(r9)
	cmpwi	r9, 2


	;	Uniprocessor machine: go straight to PIH

	blt+	kcPrioritizeInterrupts


	;	Multiprocessor machine: signal another CPU?

	bl		Save_r14_r31

	li		r9, 9
	stw		r9, -0x0238(r8)

	li		r8, 1
	bl		SIGP

	bl		Restore_r14_r31

	;	These do not match any public Apple error codes?
	cmpwi	r8, -0x725e
	cmpwi	cr1, r8, -0x725d
	cmpwi	cr2, r8, -0x725f

	beq+	kcPrioritizeInterrupts
	beq+	cr1, skeleton_key
	bne+	cr2, kcPrioritizeInterrupts
	
	mfsprg	r9, 0
	li		r8,  0x01
	stb		r8, -0x0118(r9)
	b		skeleton_key



;	                          SIGP

;	Really need to figure out what this does...

;	Xrefs:
;	IntExternalYellow
;	MPCall_43
;	KCStartCPU
;	KCCpuPlugin
;	major_0x14af8
;	MPCall_103

;	> r7    = flags
;	> r8    = usually 2?

	align	5

SIGP	;	OUTSIDE REFERER
	mfsprg	r23, 0
	mtcr	r7
	lwz		r16, -0x001c(r23)
	slwi	r20, r3,  2
	stw		r16, -0x02ac(r23)
	blt-	cr4, major_0x04a20_0x18
	cmpwi	cr2, r8,  0x00
	lwz		r18, -0x0238(r23)
	beq-	cr2, SIGP_0x28
	slwi	r20, r18,  2

SIGP_0x28
	lwz		r22, -0x0338(r23)
	li		r8, -0x7266
	lwz		r17,  0x0038(r22)
	lwz		r16,  0x0044(r22)
	mr.		r17, r17
	beqlr-
	slwi	r16, r16,  2
	li		r8, -0x7267
	cmplw	r20, r16
	bgelr-
	stw		r10, -0x02d0(r23)
	stw		r11, -0x02cc(r23)
	stw		r12, -0x02c8(r23)
	stw		r13, -0x02c4(r23)
	mfxer	r16
	mfctr	r17
	stw		r16, -0x02c0(r23)
	mflr	r16
	stw		r17, -0x02bc(r23)
	stw		r16, -0x02b8(r23)
	stw		r6, -0x02b4(r23)
	stw		r7, -0x02b0(r23)
	lwz		r9, -0x001c(r23)
	lwz		r8,  0x004c(r22)
	cmpw	r9, r8
	beq-	SIGP_0x94
	bl		SetAddrSpcRegisters

SIGP_0x94
	lwz		r16,  0x0004(r23)
	lwz		r17,  0x0018(r23)
	stw		r16,  0x010c(r6)
	stw		r2,  0x0114(r6)
	stw		r3,  0x011c(r6)
	stw		r4,  0x0124(r6)
	stw		r5,  0x012c(r6)
	stw		r17,  0x0134(r6)
	lwz		r17,  0x0648(r1)
	lhz		r16, -0x0116(r23)
	lwz		r19, -0x0964(r1)
	slwi	r16, r16,  2
	rlwinm	r19, r19,  0, 18, 15
	lwz		r8,  0x003c(r22)
	lwz		r9,  0x0040(r22)
	lwzx	r20, r8, r20
	lwz		r18,  0x0000(r20)
	mtlr	r17
	mtspr	srr0, r18
	mtspr	srr1, r19
	lwzx	r1, r9, r16
	lwz		r2,  0x0004(r20)
	srwi	r3, r16,  2
	ori		r7, r7,  0x8000
	mr		r16, r6
	stw		r7, -0x0010(r23)
	addi	r6, r23, -0x318
	stw		r6, -0x0014(r23)
	beq-	cr2, SIGP_0x128
	lwz		r4, -0x0234(r23)
	lwz		r5, -0x0230(r23)
	lwz		r6, -0x022c(r23)
	lwz		r7, -0x0228(r23)
	lwz		r8, -0x0224(r23)
	lwz		r9, -0x0220(r23)
	lwz		r10, -0x021c(r23)
	rfi

SIGP_0x128
	lwz		r6,  0x0134(r16)
	lwz		r7,  0x013c(r16)
	lwz		r8,  0x0144(r16)
	lwz		r9,  0x014c(r16)
	lwz		r10,  0x0154(r16)
	rfi



;	                     major_0x04a20

;	Xrefs:
;	"vec"
;	major_0x02980
;	major_0x03be0
;	SIGP

major_0x04a20	;	OUTSIDE REFERER
	mfsprg	r23, 0
	lwz		r6, -0x0014(r23)
	lwz		r7, -0x0010(r23)
	lwz		r1, -0x0004(r23)
	mfspr	r10, srr0
	mfspr	r11, srr1

major_0x04a20_0x18	;	OUTSIDE REFERER
	mfsprg	r23, 0
	lwz		r7, -0x02b0(r23)
	andis.	r8, r11,  0x02
	stw		r7, -0x0010(r23)
	bne-	major_0x04a20_0x30
	li		r3, -0x7265

major_0x04a20_0x30
	lwz		r8, -0x02ac(r23)
	lwz		r9, -0x001c(r23)
	cmpw	r9, r8
	beq-	major_0x04a20_0x44
	bl		SetAddrSpcRegisters

major_0x04a20_0x44
	lwz		r10, -0x02d0(r23)
	lwz		r11, -0x02cc(r23)
	lwz		r12, -0x02c8(r23)
	lwz		r13, -0x02c4(r23)
	lwz		r8, -0x02c0(r23)
	lwz		r9, -0x02bc(r23)
	mtxer	r8
	lwz		r8, -0x02b8(r23)
	lwz		r6, -0x02b4(r23)
	mtctr	r9
	stw		r6, -0x0014(r23)
	mtlr	r8
	mr		r8, r3
	mr		r9, r4
	lwz		r16,  0x010c(r6)
	lwz		r2,  0x0114(r6)
	lwz		r3,  0x011c(r6)
	lwz		r4,  0x0124(r6)
	lwz		r5,  0x012c(r6)
	lwz		r17,  0x0134(r6)
	stw		r16,  0x0004(r23)
	stw		r17,  0x0018(r23)
	blr



;	                       IntSyscall

;	Not fully sure about this one

;	Xrefs:
;	"vec"

IntSyscall	;	OUTSIDE REFERER

	;	Only r1 and LR have been saved, so these compares clobber cr0

	cmpwi	r0, -3
	bne-	@not_minus_3

	;	sc -3:

		;	unset MSR_PR bit
		mfspr	r1, srr1
		rlwinm.	r0, r1, 26, 26, 27	; nonsense code?
		rlwinm	r1, r1,  0, 18, 16
		blt-	@dont_unset_pr		; r0 should never have bit 0 set
		mtspr	srr1, r1
	@dont_unset_pr

		;	restore LR from SPRG2, r1 from SPRG1
		mfsprg	r1, 2
		mtlr	r1
		mfsprg	r1, 1

		rfi

@not_minus_3
	cmpwi	r0, -1
	mfsprg	r1, 0
	bne-	@not_minus_1

	;	sc -1: mess around with flags

		lwz		r0, -0x0010(r1)
		mfsprg	r1, 2
		rlwinm.	r0, r0,  0, 10, 10
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_minus_1
	cmpwi	r0, -2
	bne-	@not_any_special

	;	sc -2: more flag nonsense?

		lwz		r0, -0x0010(r1)
		lwz		r1, -0x0008(r1)
		rlwinm.	r0, r0,  0, 10, 10
		lwz		r0,  0x00ec(r1)
		mfsprg	r1, 2
		mtlr	r1
		mfsprg	r1, 1
		rfi

@not_any_special
	
	;	Positive numbered syscalls are a fast path to MPDispatch (twi 31, r31, 8)

	bl		int_prepare			;	Save the usual suspects and get comfy

;		Reg		Contains			Original saved in
;		---------------------------------------------
;		 r0		0					ContextBlock
;		 r1		KDP					EWA
;		 r2		(itself)					
;		 r3		(itself)
;		 r4		(itself)
;		 r5		(itself)
;		 r6		ContextBlock		EWA
;		 r7		AllCpuFeatures		ContextBlock
;		 r8		EWA					ContextBlock
;		 r9		(itself)			ContextBlock
;		r10		SRR0				ContextBlock
;		r11		SRR1				ContextBlock
;		r12		LR					ContextBlock
;		r13		CR					ContextBlock

	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 32(r1)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.NanoKernelCallCounts + 8*4(r1)

	;	Not sure what to make of these
	_bset	r11, r11, 14
	rlwimi	r7, r7, 27, 26, 26

	b		kcMPDispatch



;	                        IntTrace

;	Xrefs:
;	"vec"

	align	kIntAlign

IntTrace	;	OUTSIDE REFERER
;	r6 = saved at *(ewa + 0x18)
;	sprg1 = saved at *(ewa + 4)
;	rN (0,7,8,9,10,11,12,13, not r1) = saved at *(*(ewa - 0x14) + 0x104 + 8*N)
	bl		int_prepare
;	r0 = 0
;	r1 = *(ewa - 4)
;	r6 = kdp
;	r7 = *(ewa - 0x10) # flags?
;	r8 = ewa
;	r10 = srr0
;	r11 = srr1
;	r12 = sprg2
;	r13 = cr

	li		r8,  0x08
	b		major_0x02980_0x134



;	                   IgnoreSoftwareInt

;	Xrefs:
;	"vec"

	align	kIntAlign

IgnoreSoftwareInt	;	OUTSIDE REFERER
	mfspr	r1, srr0
	addi	r1, r1,  0x04
	mtspr	srr0, r1
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0




;	                     HandlePerfMonitorInt

;	Xrefs:
;	"vec"

	align	kIntAlign

HandlePerfMonitorInt	;	OUTSIDE REFERER
	mfspr	r1, srr1
	oris	r1, r1,  0x200
	mtspr	srr1, r1
	mfsprg	r1, 2
	mtlr	r1
	mfsprg	r1, 1
	rfi
	dcb.b	32, 0

