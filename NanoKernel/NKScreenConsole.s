ScreenConsoleX			equ		24
ScreenConsoleY			equ		22


	if		&TYPE('ExtraNKLogging') != 'UNDEFINED'
ScreenConsoleWidth		equ		800-24
ScreenConsoleHeight		equ		900-22
	else
ScreenConsoleWidth		equ		588
ScreenConsoleHeight		equ		502
	endif

ScreenConsoleBG			equ		0xfffffeee
ScreenConsoleFG			equ		0x44444444



	align	6			; odd!
;	                     InitScreenConsole

;	Xrefs:
;	replace_old_kernel
;	new_world
;	undo_failed_kernel_replacement

;	> r1    = kdp

InitScreenConsole	;	OUTSIDE REFERER
	stmw	r29, -0x0110(r1)
	lis		r30, -0x01
	ori		r30, r30,  0x7000
	add		r30, r30, r1
	addi	r31, r30,  0x2000
	addi	r30, r30,  0x04

InitScreenConsole_0x18
	cmplw	r30, r31
	addi	r29, r31,  0x04
	bge-	InitScreenConsole_0x2c
	stwu	r29, -0x1000(r31)
	b		InitScreenConsole_0x18

InitScreenConsole_0x2c
	addi	r31, r30,  0x1000
	stw		r30, -0x0004(r31)
	stw		r30, -0x0404(r1)
	stw		r30, -0x0400(r1)
	li		r29,  ScreenConsoleY
	sth		r29, -0x0360(r1)
	li		r29,  ScreenConsoleX
	sth		r29, -0x035e(r1)
	li		r29,  ScreenConsoleHeight
	sth		r29, -0x035c(r1)
	li		r29,  ScreenConsoleWidth
	sth		r29, -0x035a(r1)
	li		r29,  0x5e
	sth		r29, -0x0358(r1)
	li		r29,  0x30
	sth		r29, -0x0356(r1)
	lmw		r29, -0x0110(r1)
	blr



;	                   ScreenConsole_putchar

;	Xrefs:
;	PrintS
;	Printd
;	print_digity_common
;	Printc

;	> r1    = kdp

ScreenConsole_putchar	;	OUTSIDE REFERER
	lwz		r30, -0x0404(r1)
	stb		r29,  0x0000(r30)
	addi	r30, r30,  0x01
	andi.	r29, r30,  0xfff
	stw		r30, -0x0404(r1)
	bnelr-
	lwz		r30, -0x1000(r30)
	stw		r30, -0x0404(r1)
	blr



;	                    ScreenConsole_redraw

;	Xrefs:
;	MPCall_133
;	PrintS

;	> r1    = kdp

ScreenConsole_redraw	;	OUTSIDE REFERER
	stmw	r2, -0x03e8(r1)
	mflr	r14
	mfcr	r15
	stw		r14, -0x03f0(r1)
	stw		r15, -0x03ec(r1)
	addi	r26, r1, -0x690
	mfsprg	r2, 3
	mtsprg	3, r26
	lwz		r26,  0x0edc(r1)
	andi.	r26, r26,  0x08
	beq-	major_0x18bec
	lwz		r14, -0x0404(r1)
	lwz		r15, -0x0400(r1)
	cmpw	r14, r15
	beq-	major_0x18bec
	bl		major_0x18c18

ScreenConsole_redraw_0x40
	li		r9,  0x00
	li		r10,  0x00
	li		r25,  0x20
	bl		major_0x18e54
	bl		major_0x19018
	mflr	r21
	bl		major_0x18e24
	bl		funny_thing
	bl		major_0x18e24
	bl		funny_thing
	lwz		r14, -0x0404(r1)
	lwz		r15, -0x0400(r1)
	li		r16,  0x00

ScreenConsole_redraw_0x74
	cmpw	r14, r15
	beq-	ScreenConsole_redraw_0x118
	lbz		r25,  0x0000(r15)
	addi	r15, r15,  0x01
	andi.	r17, r15,  0xfff
	bne+	ScreenConsole_redraw_0x90
	lwz		r15, -0x1000(r15)

ScreenConsole_redraw_0x90
	cmplwi	r25,  0x0d
	cmplwi	cr1, r25,  0x0a
	beq+	ScreenConsole_redraw_0x74
	beq-	cr1, ScreenConsole_redraw_0xc0
	cmpwi	r25,  0x00
	cmpwi	cr1, r25,  0x07
	beq+	ScreenConsole_redraw_0x74
	beq-	cr1, ScreenConsole_redraw_0xe4
	bl		major_0x18e54
	lhz		r17, -0x0358(r1)
	cmpw	r9, r17
	blt+	ScreenConsole_redraw_0x74

ScreenConsole_redraw_0xc0
	cmpwi	r16,  0x00
	bne-	ScreenConsole_redraw_0xcc
	mr		r16, r15

ScreenConsole_redraw_0xcc
	bl		funny_thing
	lhz		r17, -0x0356(r1)
	cmpw	r10, r17
	blt+	ScreenConsole_redraw_0x74
	stw		r16, -0x0400(r1)
	b		ScreenConsole_redraw_0x40

ScreenConsole_redraw_0xe4
	lhz		r17, -0x0356(r1)
	addi	r17, r17, -0x01
	cmpw	r10, r17
	blt+	ScreenConsole_redraw_0x74
	lwz		r17, -0x0438(r1)
	slwi	r25, r17,  2
	add		r25, r25, r17
	mfspr	r17, dec
	subf	r17, r25, r17

ScreenConsole_redraw_0x108
	mfspr	r25, dec
	subf.	r25, r17, r25
	bge+	ScreenConsole_redraw_0x108
	b		ScreenConsole_redraw_0x74

ScreenConsole_redraw_0x118
	bl		funny_thing_0x8
	mfspr	r31, pvr
	rlwinm.	r31, r31,  0,  0, 14
	li		r31,  0x00
	bne-	ScreenConsole_redraw_0x140
	mtspr	ibat3l, r31
	isync
	mtspr	ibat3u, r18
	mtspr	ibat3l, r19
	b		ScreenConsole_redraw_0x150

ScreenConsole_redraw_0x140
	mtspr	dbat3u, r31
	isync
	mtspr	dbat3l, r19
	mtspr	dbat3u, r18

ScreenConsole_redraw_0x150
	isync



;	                     major_0x18bec

;	Xrefs:
;	ScreenConsole_redraw
;	major_0x18c18

major_0x18bec	;	OUTSIDE REFERER
	mtsprg	3, r2
	lwz		r14, -0x03f0(r1)
	lwz		r15, -0x03ec(r1)
	mtlr	r14
	mtcr	r15
	lmw		r2, -0x03e8(r1)
	blr



;	                     major_0x18c08

;	Xrefs:
;	major_0x18c18

major_0x18c08	;	OUTSIDE REFERER
	mfsrin	r31, r27
	cmpwi	r31,  0x00
	beqlr-
	b		PagingFunc4



;	                     major_0x18c18

;	Xrefs:
;	ScreenConsole_redraw

major_0x18c18	;	OUTSIDE REFERER
	mflr	r13
	lwz		r27, -0x08f8(r1)
	cmpwi	r27,  0x00
	bne-	major_0x18c18_0x40
	lwz		r27,  0x0630(r1)
	lhz		r31,  0x0378(r27)
	cmpwi	r31,  0x00
	beq-	major_0x18c18_0x40
	lwz		r31,  0x037c(r27)
	cmpwi	r31,  0x00
	beq-	major_0x18c18_0x40
	stw		r31, -0x08f8(r1)
	lhz		r31,  0x0384(r27)
	sth		r31, -0x08f4(r1)
	lhz		r31,  0x0386(r27)
	sth		r31, -0x08f2(r1)

major_0x18c18_0x40
	li		r27,  0x8a4
	bl		major_0x18c08
	beq-	major_0x18c18_0xe0
	rlwimi.	r27, r31,  0,  0, 19
	ble-	major_0x18c18_0xe0
	lwz		r27,  0x0000(r27)
	cmpwi	r27,  0x00
	ble-	major_0x18c18_0xe0
	bl		major_0x18c08
	beq-	major_0x18c18_0xe0
	rlwimi	r27, r31,  0,  0, 19
	lwz		r27,  0x0000(r27)
	cmpwi	r27,  0x00
	ble-	major_0x18c18_0xe0
	addi	r27, r27,  0x16
	bl		major_0x18c08
	beq-	major_0x18c18_0xe0
	rlwimi	r27, r31,  0,  0, 19
	lwz		r27,  0x0000(r27)
	cmpwi	r27,  0x00
	ble-	major_0x18c18_0xe0
	bl		major_0x18c08
	beq-	major_0x18c18_0xe0
	rlwimi	r27, r31,  0,  0, 19
	lwz		r27,  0x0000(r27)
	cmpwi	r27,  0x00
	ble-	major_0x18c18_0xe0
	bl		major_0x18c08
	beq-	major_0x18c18_0xe0
	rlwimi	r27, r31,  0,  0, 19
	lwz		r3,  0x0000(r27)
	lhz		r5,  0x0004(r27)
	andi.	r5, r5,  0x7fff
	lhz		r6,  0x0020(r27)
	srwi	r6, r6,  3
	cmplwi	r6,  0x08
	bgt-	major_0x18c18_0xe0
	stw		r3, -0x08f8(r1)
	sth		r5, -0x08f4(r1)
	sth		r6, -0x08f2(r1)

major_0x18c18_0xe0
	lwz		r3, -0x08f8(r1)
	lhz		r5, -0x08f4(r1)
	lhz		r6, -0x08f2(r1)
	cmpwi	r3,  0x00
	bne-	major_0x18d5c
	b		major_0x18bec



;	                     major_0x18d10

	dc.l	0x3c608180
	dc.l	0x60630200
	dc.l	0x38a00340
	dc.l	0x38c00001
	dc.l	0x4800003c
	dc.l	0x3c60a600
	dc.l	0x60638000
	dc.l	0x38a00400
	dc.l	0x38c00001
	dc.l	0x48000028
	dc.l	0x3c609600
	dc.l	0x60638000
	dc.l	0x38a00400
	dc.l	0x38c00001
	dc.l	0x48000014
	dc.l	0x3c609600
	dc.l	0x60638000
	dc.l	0x38a00400
	dc.l	0x38c00001



;	                     major_0x18d5c

;	Xrefs:
;	major_0x18c18

major_0x18d5c	;	OUTSIDE REFERER
	cmpwi	cr4, r6,  0x02
	bl		major_0x19ab0
	blt-	cr4, major_0x18d5c_0x18
	bl		major_0x19b00
	beq-	cr4, major_0x18d5c_0x18
	bl		load_log_colours

major_0x18d5c_0x18
	mflr	r24
	mfspr	r31, pvr
	rlwinm.	r31, r31,  0,  0, 14
	li		r31,  0x00
	bne-	major_0x18d5c_0x3c
	mfspr	r19, ibat3l
	mfspr	r18, ibat3u
	mtspr	ibat3l, r31
	b		major_0x18d5c_0x48

major_0x18d5c_0x3c
	mfspr	r18, dbat3u
	mfspr	r19, dbat3l
	mtspr	dbat3u, r31

major_0x18d5c_0x48
	isync
	rlwinm	r29, r3,  0,  0,  7
	beq-	major_0x18d5c_0x70
	li		r30,  0x7e
	or		r30, r30, r29
	li		r31,  0x32
	or		r31, r31, r29
	mtspr	dbat3l, r31
	mtspr	dbat3u, r30
	b		major_0x18d5c_0x88

major_0x18d5c_0x70
	li		r30,  0x32
	or		r30, r30, r29
	li		r31,  0x5f
	or		r31, r31, r29
	mtspr	ibat3u, r30
	mtspr	ibat3l, r31

major_0x18d5c_0x88
	isync
	mfmsr	r22
	lhz		r29, -0x0360(r1)
	lhz		r30, -0x035c(r1)
	subf	r29, r29, r30
	li		r30,  0x0a
	divw	r29, r29, r30
	sth		r29, -0x0356(r1)
	lhz		r29, -0x035e(r1)
	lhz		r30, -0x035a(r1)
	subf	r29, r29, r30
	li		r30,  0x06
	divw	r29, r29, r30
	sth		r29, -0x0358(r1)
	mtlr	r13
	blr



;	                     major_0x18e24

;	Xrefs:
;	ScreenConsole_redraw

major_0x18e24	;	OUTSIDE REFERER
	mflr	r12

major_0x18e24_0x4
	lhz		r25, -0x0358(r1)
	cmpw	cr1, r9, r25
	lbz		r25,  0x0000(r21)
	cmplwi	r25,  0x00
	addi	r21, r21,  0x01
	beq-	major_0x18e24_0x28
	bge+	cr1, major_0x18e24_0x4
	bl		major_0x18e54
	b		major_0x18e24_0x4

major_0x18e24_0x28
	mtlr	r12
	blr



;	                     major_0x18e54

;	Xrefs:
;	ScreenConsole_redraw
;	major_0x18e24
;	funny_thing

major_0x18e54	;	OUTSIDE REFERER
	mflr	r13
	cmpwi	cr4, r6,  0x02
	bl		load_log_font
	mflr	r23
	add		r23, r25, r23
	mulli	r27, r5,  0x0a
	mullw	r27, r27, r10
	mulli	r7, r9,  0x06
	mullw	r7, r7, r6
	add		r7, r7, r27
	add		r7, r7, r3
	lhz		r27, -0x0360(r1)
	lhz		r28, -0x035e(r1)
	mullw	r27, r5, r27
	mullw	r28, r6, r28
	add		r7, r7, r27
	add		r7, r7, r28
	subf.	r27, r3, r7
	blt-	major_0x18e54_0x174
	li		r8,  0x00

major_0x18e54_0x50
	beq-	cr4, major_0x18e54_0x9c
	bgt-	cr4, major_0x18e54_0xe0
	lbz		r27,  0x0000(r23)
	rlwinm	r27, r27, 28, 28, 29
	lwzx	r28, r24, r27
	lbz		r27,  0x0000(r23)
	rlwinm	r27, r27,  0, 26, 29
	lwzx	r27, r24, r27
	ori		r22, r22,  0x10
	mtmsr	r22
	isync
	sth		r28,  0x0000(r7)
	sth		r27,  0x0004(r7)
	srwi	r27, r27, 16
	sth		r27,  0x0002(r7)
	rlwinm	r22, r22,  0, 28, 26
	mtmsr	r22
	isync
	b		major_0x18e54_0x160

major_0x18e54_0x9c
	lbz		r28,  0x0000(r23)
	rlwinm	r27, r28, 28, 28, 29
	lwzx	r27, r24, r27
	rlwinm	r29, r28, 30, 28, 29
	lwzx	r29, r24, r29
	rlwinm	r30, r28,  0, 28, 29
	lwzx	r30, r24, r30
	ori		r22, r22,  0x10
	mtmsr	r22
	isync
	stw		r27,  0x0000(r7)
	stw		r29,  0x0004(r7)
	stw		r30,  0x0008(r7)
	rlwinm	r22, r22,  0, 28, 26
	mtmsr	r22
	isync
	b		major_0x18e54_0x160

major_0x18e54_0xe0
	lbz		r28,  0x0000(r23)
	rlwinm	r27, r28, 27, 29, 29
	lwzx	r27, r24, r27
	rlwinm	r29, r28, 28, 29, 29
	lwzx	r29, r24, r29
	rlwinm	r30, r28, 29, 29, 29
	lwzx	r30, r24, r30
	rlwinm	r31, r28, 30, 29, 29
	lwzx	r31, r24, r31
	ori		r22, r22,  0x10
	mtmsr	r22
	isync
	stw		r27,  0x0000(r7)
	stw		r29,  0x0004(r7)
	stw		r30,  0x0008(r7)
	stw		r31,  0x000c(r7)
	rlwinm	r22, r22,  0, 28, 26
	mtmsr	r22
	isync
	rlwinm	r27, r28, 31, 29, 29
	lwzx	r27, r24, r27
	rlwinm	r29, r28,  0, 29, 29
	lwzx	r29, r24, r29
	ori		r22, r22,  0x10
	mtmsr	r22
	isync
	stw		r27,  0x0010(r7)
	stw		r29,  0x0014(r7)
	rlwinm	r22, r22,  0, 28, 26
	mtmsr	r22
	isync
	b		major_0x18e54_0x160

major_0x18e54_0x160
	addi	r8, r8,  0x01
	cmplwi	r8,  0x0a
	add		r7, r7, r5
	addi	r23, r23,  0x100
	blt+	major_0x18e54_0x50

major_0x18e54_0x174
	addi	r9, r9,  0x01
	mtlr	r13
	blr



;	                      funny_thing

;	Xrefs:
;	ScreenConsole_redraw

funny_thing	;	OUTSIDE REFERER
	crclr	cr2_eq
	b		funny_thing_0xc

funny_thing_0x8	;	OUTSIDE REFERER
	crset	cr2_eq

funny_thing_0xc
	mflr	r12

funny_thing_0x10
	lhz		r25, -0x0358(r1)
	cmpw	r9, r25
	bge-	funny_thing_0x28
	li		r25,  0x20
	bl		major_0x18e54
	b		funny_thing_0x10

funny_thing_0x28
	beq-	cr2, funny_thing_0x3c
	li		r9,  0x00
	addi	r10, r10,  0x01
	li		r25,  0x20
	bl		major_0x18e54

funny_thing_0x3c
	mtlr	r12
	blr



;	Xrefs:
;	ScreenConsole_redraw

major_0x19018	;	OUTSIDE REFERER
	
	blrl

	string	CString
	dc.b	'              NanoKernel Log '
	dc.b	'              -------------- '
	align	2



;	Unfortunately inaccessible

	blrl
	
	string	CString
	dc.b	'              System Termination '
	dc.b	'              ------------------ '
	align	2



;	                     load_log_font

;	Xrefs:
;	major_0x18e54

load_log_font	;	OUTSIDE REFERER
	blrl
	dc.l	0x907070f0
	dc.l	0xf0f06000
	dc.l	0xe0008090
	dc.l	0xf0007070
	dc.l	0xe0e0e0e0
	dc.l	0xe09070f0
	dc.l	0x70f070f0
	dc.l	0xf070e090
	dc.l	0
	dc.l	0x20000000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00000008
	dc.l	0x20400000
	dc.l	0x50200010
	dc.l	0x68505000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x70000000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00001800
	dc.l	0
	dc.l	0
	dc.l	0x18000000
	dc.l	0x00000040
	dc.l	0x68680000
	dc.l	0
	dc.l	0
	dc.l	0x00500000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0xd0808080
	dc.l	0x80809000
	dc.l	0x90008090
	dc.l	0x80088080
	dc.l	0x90909090
	dc.l	0x90d08080
	dc.l	0x80808080
	dc.l	0x80809090
	dc.l	0x00205050
	dc.l	0x70786020
	dc.l	0x10200000
	dc.l	0x00000008
	dc.l	0x70207070
	dc.l	0x10f870f8
	dc.l	0x70700000
	dc.l	0x00000070
	dc.l	0x7070f070
	dc.l	0xf0f8f870
	dc.l	0x88700888
	dc.l	0x80888870
	dc.l	0xf070f070
	dc.l	0xf8888888
	dc.l	0x8888f830
	dc.l	0x40302000
	dc.l	0x20008000
	dc.l	0x08001800
	dc.l	0x80202080
	dc.l	0x20000000
	dc.l	0
	dc.l	0x20000000
	dc.l	0x00000010
	dc.l	0x20200000
	dc.l	0x00500020
	dc.l	0xb8000010
	dc.l	0x40200068
	dc.l	0x30001040
	dc.l	0x20001040
	dc.l	0x20006810
	dc.l	0x40200068
	dc.l	0x10402000
	dc.l	0x00300060
	dc.l	0x88007830
	dc.l	0
	dc.l	0
	dc.l	0x00001040
	dc.l	0x880020f8
	dc.l	0xf8002038
	dc.l	0x30700000
	dc.l	0x20200000
	dc.l	0x20000000
	dc.l	0x00000020
	dc.l	0xb0b00000
	dc.l	0x00005050
	dc.l	0x20600000
	dc.l	0x50000000
	dc.l	0x00003030
	dc.l	0
	dc.l	0x40202010
	dc.l	0x00201020
	dc.l	0x00201020
	dc.l	0x30201020
	dc.l	0x20002068
	dc.l	0x70482020
	dc.l	0x00280050
	dc.l	0xb06060e0
	dc.l	0xe0e0f020
	dc.l	0xe0208090
	dc.l	0xe0086060
	dc.l	0x90909090
	dc.l	0x90b060e0
	dc.l	0x80e060e0
	dc.l	0xe0b0e090
	dc.l	0x002050f8
	dc.l	0xa8a89020
	dc.l	0x20102020
	dc.l	0x00000008
	dc.l	0x88608888
	dc.l	0x30808008
	dc.l	0x88880000
	dc.l	0x10004088
	dc.l	0x88888888
	dc.l	0x88808088
	dc.l	0x88200890
	dc.l	0x80d8c888
	dc.l	0x88888888
	dc.l	0x20888888
	dc.l	0x88880820
	dc.l	0x40105000
	dc.l	0x10008000
	dc.l	0x08002000
	dc.l	0x80000080
	dc.l	0x20000000
	dc.l	0
	dc.l	0x20000000
	dc.l	0x00000010
	dc.l	0x20206800
	dc.l	0x702070f8
	dc.l	0x88708820
	dc.l	0x205050b0
	dc.l	0x48002020
	dc.l	0x50502020
	dc.l	0x5050b020
	dc.l	0x205050b0
	dc.l	0x20205050
	dc.l	0x20480090
	dc.l	0x4800a848
	dc.l	0xe0e0f410
	dc.l	0x50007870
	dc.l	0x00202020
	dc.l	0x50001048
	dc.l	0x50002048
	dc.l	0x48880000
	dc.l	0x00000018
	dc.l	0x20082000
	dc.l	0x00000070
	dc.l	0x70707800
	dc.l	0x0000a050
	dc.l	0x40200000
	dc.l	0x00880884
	dc.l	0x00004048
	dc.l	0x20000000
	dc.l	0xa0505020
	dc.l	0x50102050
	dc.l	0x50102050
	dc.l	0x20102050
	dc.l	0x100050b0
	dc.l	0x00300050
	dc.l	0x00500020
	dc.l	0x90101080
	dc.l	0x80809070
	dc.l	0x9030f0a0
	dc.l	0x80281010
	dc.l	0x90909090
	dc.l	0x90901080
	dc.l	0x80801080
	dc.l	0x8090a090
	dc.l	0x00200050
	dc.l	0xa0b0a000
	dc.l	0x4008a820
	dc.l	0x00000010
	dc.l	0x98200808
	dc.l	0x50f0f008
	dc.l	0x88882020
	dc.l	0x20f82008
	dc.l	0xe8888880
	dc.l	0x88808080
	dc.l	0x882008a0
	dc.l	0x80a8a888
	dc.l	0x88888880
	dc.l	0x20888888
	dc.l	0x50881020
	dc.l	0x20108800
	dc.l	0x0078f070
	dc.l	0x78707078
	dc.l	0xf0202090
	dc.l	0x20f0b070
	dc.l	0xf078b078
	dc.l	0x708888a8
	dc.l	0x8888f810
	dc.l	0x2020b000
	dc.l	0x88708880
	dc.l	0xc8888800
	dc.l	0
	dc.l	0x30700000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x70482080
	dc.l	0xa000a888
	dc.l	0x10105c20
	dc.l	0x0010a088
	dc.l	0xd8204010
	dc.l	0xf8901820
	dc.l	0x50f82048
	dc.l	0x48887070
	dc.l	0x20200010
	dc.l	0x20702000
	dc.l	0x00000088
	dc.l	0x8888a000
	dc.l	0x0000a0a0
	dc.l	0x60402020
	dc.l	0x88881030
	dc.l	0x0000e8e8
	dc.l	0x70000000
	dc.l	0x40000000
	dc.l	0
	dc.l	0
	dc.l	0x58000000
	dc.l	0x00200000
	dc.l	0x00000020
	dc.l	0
	dc.l	0x90e0e0f0
	dc.l	0xf0f09070
	dc.l	0xe0f80040
	dc.l	0x8068e0e0
	dc.l	0xe0e0e0e0
	dc.l	0xe090e0f0
	dc.l	0x70f0e0f0
	dc.l	0x80609060
	dc.l	0x002000f8
	dc.l	0x70504000
	dc.l	0x400870f8
	dc.l	0x00f80010
	dc.l	0xa8201030
	dc.l	0x90088810
	dc.l	0x70880000
	dc.l	0x40001010
	dc.l	0xa8f8f080
	dc.l	0x88f0f098
	dc.l	0xf82008c0
	dc.l	0x80889888
	dc.l	0xf088f070
	dc.l	0x20888888
	dc.l	0x20502020
	dc.l	0x20100000
	dc.l	0x00888888
	dc.l	0x88882088
	dc.l	0x882020a0
	dc.l	0x20a8c888
	dc.l	0x8888c880
	dc.l	0x208888a8
	dc.l	0x50881020
	dc.l	0x20100000
	dc.l	0x88888080
	dc.l	0xa8888878
	dc.l	0x78787878
	dc.l	0x78887070
	dc.l	0x70702020
	dc.l	0x2020b070
	dc.l	0x70707070
	dc.l	0x88888888
	dc.l	0x203070e0
	dc.l	0x9030a890
	dc.l	0xc8685c00
	dc.l	0x00f8a098
	dc.l	0xa8f82020
	dc.l	0x20902810
	dc.l	0x50502038
	dc.l	0x3088a898
	dc.l	0x4020f820
	dc.l	0x70885048
	dc.l	0x90000088
	dc.l	0x8888a050
	dc.l	0
	dc.l	0x00000050
	dc.l	0x88882048
	dc.l	0x00004848
	dc.l	0x20200000
	dc.l	0x1c70f870
	dc.l	0xf8f87070
	dc.l	0x70707070
	dc.l	0xf0708888
	dc.l	0x88200000
	dc.l	0
	dc.l	0
	dc.l	0x48484848
	dc.l	0x003048f8
	dc.l	0x38307800
	dc.l	0x78f83830
	dc.l	0x00107070
	dc.l	0x10484870
	dc.l	0x00007038
	dc.l	0x38383838
	dc.l	0x00200050
	dc.l	0x2868a800
	dc.l	0x4008a820
	dc.l	0x00000020
	dc.l	0xc8202008
	dc.l	0xf8088820
	dc.l	0x88782000
	dc.l	0x20f82020
	dc.l	0xf0888880
	dc.l	0x88808088
	dc.l	0x882088a0
	dc.l	0x80888888
	dc.l	0x80888808
	dc.l	0x208888a8
	dc.l	0x50204020
	dc.l	0x10100000
	dc.l	0x00888880
	dc.l	0x88f82088
	dc.l	0x882020e0
	dc.l	0x20a88888
	dc.l	0x88888070
	dc.l	0x208888a8
	dc.l	0x20882010
	dc.l	0x20200000
	dc.l	0xf88880f0
	dc.l	0x98888888
	dc.l	0x88888888
	dc.l	0x88808888
	dc.l	0x88882020
	dc.l	0x2020c888
	dc.l	0x88888888
	dc.l	0x88888888
	dc.l	0x2000a880
	dc.l	0x48307890
	dc.l	0xa8880000
	dc.l	0x0020f0a8
	dc.l	0xd8201040
	dc.l	0xf8904820
	dc.l	0x50502000
	dc.l	0x0088b8a8
	dc.l	0x802008a0
	dc.l	0x20705090
	dc.l	0x480000f8
	dc.l	0xf888b0a8
	dc.l	0x70f80000
	dc.l	0x0000f888
	dc.l	0x88504048
	dc.l	0x10404848
	dc.l	0x20000000
	dc.l	0xe0888088
	dc.l	0x80802020
	dc.l	0x20208888
	dc.l	0xf8888888
	dc.l	0x88200000
	dc.l	0
	dc.l	0
	dc.l	0x48484848
	dc.l	0x384850f8
	dc.l	0x40204038
	dc.l	0x40601048
	dc.l	0x40300808
	dc.l	0x30504848
	dc.l	0x48884840
	dc.l	0x40404040
	dc.l	0
	dc.l	0xa8a89000
	dc.l	0x20102020
	dc.l	0x00000020
	dc.l	0x88204088
	dc.l	0x10888820
	dc.l	0x88080000
	dc.l	0x10004000
	dc.l	0x80888888
	dc.l	0x88808088
	dc.l	0x88208890
	dc.l	0x80888888
	dc.l	0x80888888
	dc.l	0x208850d8
	dc.l	0x88208020
	dc.l	0x10100000
	dc.l	0x00988880
	dc.l	0x88802088
	dc.l	0x88202090
	dc.l	0x20a88888
	dc.l	0x88888008
	dc.l	0x209850a8
	dc.l	0x50884010
	dc.l	0x20200000
	dc.l	0x88f88080
	dc.l	0x88888888
	dc.l	0x88888888
	dc.l	0x8880f8f8
	dc.l	0xf8f82020
	dc.l	0x20208888
	dc.l	0x88888888
	dc.l	0x88888888
	dc.l	0x2000a080
	dc.l	0x28002888
	dc.l	0xc8680000
	dc.l	0x00f8a0c8
	dc.l	0x00200000
	dc.l	0x20904848
	dc.l	0x50502078
	dc.l	0x7850a0c8
	dc.l	0x88200840
	dc.l	0x20808890
	dc.l	0x48000088
	dc.l	0x8888a0b8
	dc.l	0
	dc.l	0x00000050
	dc.l	0x88208030
	dc.l	0x20204848
	dc.l	0x20000000
	dc.l	0x00f8f0f8
	dc.l	0xf0f02020
	dc.l	0x20208888
	dc.l	0xf8888888
	dc.l	0x88200000
	dc.l	0
	dc.l	0
	dc.l	0x48783030
	dc.l	0x10487020
	dc.l	0x30007010
	dc.l	0x70201048
	dc.l	0x40101030
	dc.l	0x78703070
	dc.l	0x68d87040
	dc.l	0x30303030
	dc.l	0x00200000
	dc.l	0x70906800
	dc.l	0x10200000
	dc.l	0x20002040
	dc.l	0x7020f870
	dc.l	0x10707020
	dc.l	0x70700020
	dc.l	0x00000020
	dc.l	0x7088f070
	dc.l	0xf0f88070
	dc.l	0x88707088
	dc.l	0xf8888870
	dc.l	0x80708870
	dc.l	0x20702088
	dc.l	0x8820f830
	dc.l	0x083000f8
	dc.l	0x0068f078
	dc.l	0x78782078
	dc.l	0x88202088
	dc.l	0x20a88870
	dc.l	0xf07880f0
	dc.l	0x18682050
	dc.l	0x8878f810
	dc.l	0x20200000
	dc.l	0x88888880
	dc.l	0x88888898
	dc.l	0x98989898
	dc.l	0x98788080
	dc.l	0x80802020
	dc.l	0x20208888
	dc.l	0x88888888
	dc.l	0x98989898
	dc.l	0x0000a888
	dc.l	0x90002888
	dc.l	0xb0100000
	dc.l	0x0040a088
	dc.l	0x00f87070
	dc.l	0x20e830f8
	dc.l	0x50502000
	dc.l	0x00d87870
	dc.l	0x70200040
	dc.l	0x2000f848
	dc.l	0x90a80088
	dc.l	0x8888a0a0
	dc.l	0
	dc.l	0x00002020
	dc.l	0x78200084
	dc.l	0x10404848
	dc.l	0x70002050
	dc.l	0x48888088
	dc.l	0x80802020
	dc.l	0x20208888
	dc.l	0x50888888
	dc.l	0x88200000
	dc.l	0
	dc.l	0x20001000
	dc.l	0x30484848
	dc.l	0x10584800
	dc.l	0x08004010
	dc.l	0x40001048
	dc.l	0x40102008
	dc.l	0x10481048
	dc.l	0x58a84840
	dc.l	0x08080808
	dc.l	0
	dc.l	0x20000000
	dc.l	0
	dc.l	0x20000040
	dc.l	0
	dc.l	0
	dc.l	0x00000020
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00080000
	dc.l	0
	dc.l	0
	dc.l	0x08000000
	dc.l	0
	dc.l	0x00000008
	dc.l	0x00002000
	dc.l	0
	dc.l	0x80080000
	dc.l	0
	dc.l	0x00080008
	dc.l	0x20400000
	dc.l	0x888870f8
	dc.l	0x88707068
	dc.l	0x68686868
	dc.l	0x68207878
	dc.l	0x78782020
	dc.l	0x20208870
	dc.l	0x70707070
	dc.l	0x68686868
	dc.l	0x000070f0
	dc.l	0x880028b0
	dc.l	0x00e00000
	dc.l	0x0000b870
	dc.l	0
	dc.l	0x00800000
	dc.l	0x00002000
	dc.l	0
	dc.l	0
	dc.l	0x20000000
	dc.l	0x00000088
	dc.l	0x88707858
	dc.l	0
	dc.l	0
	dc.l	0x08200000
	dc.l	0
	dc.l	0x20002050
	dc.l	0xb488f888
	dc.l	0xf8f87070
	dc.l	0x70708888
	dc.l	0x00887070
	dc.l	0x70000000
	dc.l	0
	dc.l	0x10002000
	dc.l	0x00484848
	dc.l	0x10384800
	dc.l	0x70004010
	dc.l	0x40003830
	dc.l	0x70387870
	dc.l	0x10481070
	dc.l	0x48887038
	dc.l	0x70707070
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x40000000
	dc.l	0
	dc.l	0
	dc.l	0x00000040
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00000070
	dc.l	0x0000c000
	dc.l	0
	dc.l	0x80080000
	dc.l	0
	dc.l	0x00700000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00400000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00002000
	dc.l	0x70000080
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x00800000
	dc.l	0x0000c000
	dc.l	0
	dc.l	0
	dc.l	0xc0000000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0x70000000
	dc.l	0
	dc.l	0x000040a0
	dc.l	0x48000000
	dc.l	0
	dc.l	0x00007070
	dc.l	0x00700000
	dc.l	0
	dc.l	0
	dc.l	0x30003000



;	                     major_0x19ab0

;	Xrefs:
;	major_0x18d5c

	align	4

major_0x19ab0	;	OUTSIDE REFERER
	blrl
	dc.l	0x06060606
	dc.l	0x060606ff
	dc.l	0x0606ff06
	dc.l	0x0606ffff
	dc.l	0x06ff0606
	dc.l	0x06ff06ff
	dc.l	0x06ffff06
	dc.l	0x06ffffff
	dc.l	0xff060606
	dc.l	0xff0606ff
	dc.l	0xff06ff06
	dc.l	0xff06ffff
	dc.l	0xffff0606
	dc.l	0xffff06ff
	dc.l	0xffffff06
	dc.l	0xffffffff



;	                     major_0x19b00

;	Xrefs:
;	major_0x18d5c

	align	4

major_0x19b00	;	OUTSIDE REFERER
	blrl
	dc.l	0xff7eff7e
	dc.l	0xff7e0000
	dc.l	0x0000ff7e
	dc.l	0



;	                    load_log_colours

;	Each word is RGB with the high byte ignored. Background
;	and text.

;	Xrefs:
;	major_0x18d5c

	align	4

load_log_colours	;	OUTSIDE REFERER
	blrl
	dc.l	ScreenConsoleBG
	dc.l	ScreenConsoleFG
