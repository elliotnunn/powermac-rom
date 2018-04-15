;	This file is tricky. Along with the file immediately before it,
;	Interrupts.s, it emulates unsupported PowerPC instructions.
;	This mechanism is heavily optimized, and the jumping between
;	tables (which I have tried to describe as well as I can) is
;	very confusing.

;	It is called 'FDP' because of a long-ago confusion about what it did.

;	Some of the mnemonics might look a bit odd, because I used MPW
;	to disassemble instead of ppcdisasm.py or gas.

;	The init code puts a pointer to 'FDP' in the part of the KDP that is
;	mostly shared with NKv1. Therefore this is probably deep Davidianian
;	magic. The tables here contain relative references to other tables
;	in Interrupts.s. What a mess.


		align	11


FDP


FDP_panic
		bl		panic


FDP_0004
		b		FDP_024C


;	This stuff is for emulating float storage instructions

FDP_0008	;	stfs(x)
		rlwinm	r17, r17, 0, 16, 10


FDP_000c	;	stfsu(x)
		crclr	cr7_SO
		b		FDP_001C


FDP_0014	;	stfd(x), stfiwx
		rlwinm	r17, r17, 0, 16, 10


FDP_0018	;	stfdu(x)
		crset	cr7_SO


FDP_001c	;	called from above
		clrrwi	r19, r25, 10
		rlwimi	r19, r17, 14, 24, 28
		addi	r19, r19, FloatSaveJumpTable - FDP
		mtlr	r19
		rlwimi	r14, r11, 0, 18, 18
		mtmsr	r14
		isync
		blr


FDP_003c	;	Called by the jump table in the previous file
		ori		r11, r11, 0x2000
		lwz		r20, -0x02E0(r1)
		lwz		r21, -0x02DC(r1)
		bso		cr7, FDP_00E8
		extrwi	r23, r20, 11, 1
		cmpwi	r23, 896
		insrwi	r20, r20, 27, 2
		inslwi	r20, r21, 3, 29
		mr		r21, r20
		bgt		FDP_00E8
		cmpwi	r23, 874
		clrrwi	r21, r20, 31
		blt		FDP_00E8
		oris	r20, r20, 0x0080
		neg		r23, r23
		clrlwi	r20, r20, 8
		srw		r20, r20, r23
		rlwimi	r21, r20, 31, 9, 31
		b		FDP_00E8


FDP_0088	;	stwbrx
		rlwinm	r28, r17, 13, 25, 29
		lwbrx	r21, r1, r28
		b		FDP_00E4


FDP_0094	;	sthbrx
		rlwinm	r28, r17, 13, 25, 29
		addi	r21, r1, 2
		lhbrx	r21, r21, r28
		b		FDP_00E4


FDP_00a4	;	sthu(x)
		rlwinm	r28, r17, 13, 25, 29
		lwzx	r21, r1, r28
		b		FDP_00E8


FDP_00b0	;	stwcx.
		rlwinm	r28, r17, 13, 25, 29
		lwzx	r21, r1, r28


FDP_00b8	;	lwarx
		crset	cr5_SO
		b		FDP_00E4


FDP_00c0	;	lbzu(x), stbu(x), lhau(x), stmw
		clrrwi	r18, r18, 4
		rlwimi	r15, r11, 0, 6, 6
		b		FDP_00E4


FDP_00cc	;	lwzu(x)
		clrrwi	r18, r18, 1
		b		FDP_00E4


FDP_00d4	;	lbz(x)
		clrrwi	r18, r18, 2
		b		FDP_00E4


FDP_00dc	;	ecowx, sth(x)
		rlwinm	r28, r17, 13, 25, 29
		lwzx	r21, r1, r28


FDP_00e4	;	eciwx, lwz(x), lbz(x), lhz(x), lha(x), lfs(x), lfd(x)
		rlwinm	r17, r17, 0, 16, 10


FDP_00e8	;	lwbrx, lhbrx, lmw, lhzu(x), lhfsu(x), lfdu(x)
		extrwi.	r22, r17, 5, 26
		add		r19, r18, r22
		b		FDP_03AC


FDP_00f4
		srwi	r23, r21, 16
		sth		r23, -0x0004(r19)
		subi	r17, r17, 4
		sth		r21, -0x0002(r19)
		b		FDP_011C


FDP_0108
		lhz		r23, -0x0004(r19)
		subi	r17, r17, 4
		insrwi	r21, r23, 16, 0


FDP_0114
		lhz		r23, -0x0002(r19)
		insrwi	r21, r23, 16, 16


FDP_011c	;	exported, r25 = address of routine in MixedTable
		li		r0, -3
		sc
		bl		major_0x03548
		rlwinm.	r28, r17, 18, 25, 29
		mtlr	r25
		mfsprg	r1, 0
		cror	cr0_EQ, cr0_EQ, cr3_EQ
		mtsprg	3, r24
		beqlr
		crset	cr3_SO
		stwx	r18, r1, r28
		blr


FDP_014C
		extsh	r21, r21


FDP_0150
		rlwinm	r28, r17, 13, 25, 29
		crset	cr3_SO
		stwx	r21, r1, r28


FDP_015C
		b		FDP_0dA0


FDP_0160
		slwi	r21, r21, 16


FDP_0164
		rlwinm	r28, r17, 13, 25, 29
		crset	cr3_SO
		stwbrx	r21, r1, r28
		b		FDP_0dA0


FDP_0174
		b		FDP_0fA8

FDP_0178
		clrrwi	r23, r25, 10
		rlwimi	r23, r17, 14, 24, 28
		addi	r23, r23, FloatLoadJumpTable - FDP
		mtlr	r23
		stw		r20, -0x02E0(r1)
		stw		r21, -0x02DC(r1)
		rlwimi	r14, r11, 0, 18, 18
		mtmsr	r14
		isync
		ori		r11, r11, 0x2000
		blr


FDP_01a4
		rlwinm.	r28, r17, 13, 25, 29
		rlwinm	r23, r17, 18, 25, 29
		cmpw	cr7, r28, r23
		addis	r17, r17, 32
		beq		FDP_01BC
		beq		cr7, FDP_01C0


FDP_01bc
		stwx	r21, r1, r28


FDP_01c0
		cmpwi	r28, 124
		li		r22, 9
		insrwi	r17, r22, 6, 26
		addi	r19, r19, 4
		bne		FDP_03AC
		b		FDP_0dA0


FDP_01d8
		addis	r17, r17, 32
		rlwinm.	r28, r17, 13, 25, 29
		beq		FDP_0dA0
		lwzx	r21, r1, r28
		li		r22, 8
		insrwi	r17, r22, 6, 26
		addi	r19, r19, 4
		b		FDP_03AC


FDP_01f8	;	dcbz
		lwz		r21, -0x0004(r1)
		lhz		r21, 0x0F4A(r21)
		neg		r21, r21
		and		r19, r18, r21
		b		FDP_0224


FDP_020c
		lwz		r21, -0x0004(r1)
		lhz		r21, 0x0F4A(r21)
		subi	r21, r21, 8
		and.	r22, r19, r21
		clrrwi	r19, r19, 3
		beq		FDP_0dA0


FDP_0224
		li		r22, 16
		insrwi.	r17, r22, 6, 26
		addi	r19, r19, 8
		li		r20, 0
		li		r21, 0
		b		FDP_03AC


FDP_023c
		rlwinm	r16, r16, 0, 28, 25
		subi	r10, r10, 4
		stw		r16, -0x0010(r1)
		b		FDP_0dA0


FDP_024c
		li		r8, 18
		b		major_0x02980


FDP_0254	;	stswi
		subi	r22, r27, 2048
		extrwi	r22, r22, 5, 16
		b		FDP_0270


FDP_0260	;	stswx
		mfxer	r22
		andi.	r22, r22, 0x007F
		subi	r22, r22, 1
		beq		FDP_0dA0


FDP_0270
		rlwimi	r17, r22, 4, 21, 25
		not		r22, r22
		insrwi	r17, r22, 2, 4
		mr		r19, r18
		b		FDP_0e60


FDP_0284
		andi.	r22, r17, 0x07C0
		addis	r28, r17, 32
		rlwimi	r17, r28, 0, 6, 10
		subi	r17, r17, 64
		bne		FDP_0e60
		b		FDP_0dA0


FDP_029c	;	lswi
		subi	r22, r27, 2048
		extrwi	r22, r22, 5, 16
		addis	r28, r27, 992
		rlwimi	r17, r28, 22, 16, 20
		b		FDP_02C4


FDP_02b0	;	lswx
		mfxer	r22
		andi.	r22, r22, 0x007F
		rlwimi	r17, r27, 0, 16, 20
		subi	r22, r22, 1
		beq		FDP_0dA0


FDP_02c4
		andis.	r23, r17, 0x001F
		rlwimi	r17, r22, 4, 21, 25
		not		r22, r22
		insrwi	r17, r22, 2, 4
		mr		r19, r18
		bne		FDP_0eC8
		rlwimi	r17, r17, 5, 11, 15
		b		FDP_0eC8


FDP_02e4
		andi.	r22, r17, 0x07C0
		rlwinm	r28, r17, 13, 25, 29
		bne		FDP_0e9C
		rlwinm	r22, r17, 9, 27, 28
		slw		r21, r21, r22
		b		FDP_0e9C


FDP_02fc
		rlwinm.	r22, r17, 28, 25, 29
		rlwinm	r28, r17, 13, 25, 29
		bne		FDP_0eF4
		rlwinm	r23, r17, 9, 27, 28
		slw		r21, r21, r23
		b		FDP_0eF4


FDP_0314	;	unknown table entries
		mfxer	r22


FDP_0318
		andi.	r22, r22, 0x007F
		rlwimi	r17, r27, 0, 16, 20
		insrwi	r17, r27, 1, 3
		cmpw	cr7, r27, r22
		beq		FDP_0f80
		subi	r22, r22, 1
		andis.	r23, r17, 0x001F
		rlwimi	r17, r22, 4, 21, 25
		not		r22, r22
		insrwi	r17, r22, 2, 4
		mr		r19, r18
		bne		FDP_0eC8
		rlwimi	r17, r17, 5, 11, 15
		b		FDP_0eC8


FDP_0350	;	stw(x)
		li		r20, 11040
		b		FDP_1024


FDP_0358	;	stwu(x)
		clrrwi	r18, r18, 1
		li		r20, 11296
		b		FDP_1024


FDP_0364	;	stb(x)
		clrrwi	r18, r18, 2
		li		r20, 11552
		b		FDP_1024


FDP_0370
		subi	r23, r1, 736
		li		r20, 10016
		insrwi	r23, r18, 4, 28
		stb		r21, 0x0000(r23)
		b		FDP_1000


FDP_0384
		subi	r23, r1, 736
		li		r20, 10272
		insrwi	r23, r18, 4, 28
		sth		r21, 0x0000(r23)
		b		FDP_1000


FDP_0398
		subi	r23, r1, 736
		li		r20, 10528
		insrwi	r23, r18, 4, 28
		stw		r21, 0x0000(r23)
		b		FDP_1000


FDP_03ac
		lwz		r1, -0x0004(r1)
		clrrwi	r25, r25, 10
		insrwi	r25, r19, 3, 28
		insrwi	r25, r17, 5, 23
		lha		r22, 0x0C00(r25)
		addi	r23, r1, 1248
		add		r22, r22, r25
		mfsprg	r1, 0
		mtlr	r22
		ori		r15, r15, 0x4000
		mtsprg	3, r23
		mtmsr	r15
		isync
		insrwi	r25, r26, 8, 22
		bnelr
		b		FDP_011C


FDP_03ec
		lbz		r23, -0x0008(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 0


FDP_03f8
		lhz		r23, -0x0007(r19)
		subi	r17, r17, 4
		insrwi	r20, r23, 16, 8
		b		FDP_0414


FDP_0408
		lbz		r23, -0x0006(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 16


FDP_0414
		lwz		r23, -0x0005(r19)
		subi	r17, r17, 8
		inslwi	r20, r23, 8, 24
		insrwi	r21, r23, 24, 0
		b		FDP_0490


FDP_0428
		lbz		r23, -0x0008(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 0

FDP_0434
		lwz		r23, -0x0007(r19)
		subi	r17, r17, 8
		inslwi	r20, r23, 24, 8
		insrwi	r21, r23, 8, 0
		b		FDP_0474


FDP_0448
		lbz		r23, -0x0006(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 16


FDP_0454
		lhz		r23, -0x0005(r19)
		subi	r17, r17, 4
		rlwimi	r20, r23, 24, 24, 31
		insrwi	r21, r23, 8, 0
		b		FDP_0474


FDP_0468
		lbz		r23, -0x0004(r19)
		subi	r17, r17, 2
		insrwi	r21, r23, 8, 0


FDP_0474
		lhz		r23, -0x0003(r19)
		subi	r17, r17, 4
		insrwi	r21, r23, 16, 8
		b		FDP_0490


FDP_0484
		lbz		r23, -0x0002(r19)
		subi	r17, r17, 2
		insrwi	r21, r23, 8, 16


FDP_0490
		lbz		r23, -0x0001(r19)
		insrwi	r21, r23, 8, 24
		b		FDP_011C


FDP_049c
		lhz		r23, -0x0008(r19)
		subi	r17, r17, 4
		insrwi	r20, r23, 16, 0
		b		FDP_04B8


FDP_04ac
		lbz		r23, -0x0007(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 8


FDP_04b8
		lwz		r23, -0x0006(r19)
		subi	r17, r17, 8
		inslwi	r20, r23, 16, 16
		insrwi	r21, r23, 16, 0
		b		FDP_0114


FDP_04cc
		lbz		r23, -0x0005(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 24
		b		FDP_0108


FDP_04dc
		lbz		r23, -0x0003(r19)
		subi	r17, r17, 2
		insrwi	r21, r23, 8, 8
		b		FDP_0114


FDP_04ec
		lwz		r20, -0x0008(r19)
		subi	r17, r17, 8
		lwz		r21, -0x0004(r19)
		b		FDP_011C


FDP_04fc
		lbz		r23, -0x0007(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 8


FDP_0508
		lhz		r23, -0x0006(r19)
		subi	r17, r17, 4
		insrwi	r20, r23, 16, 16
		lwz		r21, -0x0004(r19)
		b		FDP_011C


FDP_051c
		lbz		r23, -0x0005(r19)
		subi	r17, r17, 2
		insrwi	r20, r23, 8, 24
		lwz		r21, -0x0004(r19)
		b		FDP_011C


FDP_0530
		bso		cr5, FDP_053C
		lwz		r21, -0x0004(r19)
		b		FDP_011C


FDP_053c
		li		r23, -4
		lwarx	r21, r23, r19
		b		FDP_011C


FDP_0548
		lwz		r20, -0x0008(r19)
		lwz		r21, -0x0004(r19)
		b		FDP_011C


FDP_0554
		clrrwi	r23, r25, 10
		rlwimi	r23, r17, 14, 24, 28
		addi	r23, r23, 9760
		mtlr	r23
		mr		r23, r18
		oris	r11, r11, 0x0200
		blr


FDP_0570
		srwi	r23, r20, 24
		stb		r23, -0x0008(r19)
		subi	r17, r17, 2


FDP_057c
		srwi	r23, r20, 8
		sth		r23, -0x0007(r19)
		subi	r17, r17, 4
		b		FDP_0598


FDP_058c
		srwi	r23, r20, 8
		stb		r23, -0x0006(r19)
		subi	r17, r17, 2


FDP_0598
		srwi	r23, r21, 8
		insrwi	r23, r20, 8, 0
		stw		r23, -0x0005(r19)
		subi	r17, r17, 8
		stb		r21, -0x0001(r19)
		b		FDP_011C


FDP_05b0
		srwi	r23, r20, 24
		stb		r23, -0x0008(r19)
		subi	r17, r17, 2


FDP_05bc
		srwi	r23, r21, 24
		insrwi	r23, r20, 24, 0
		stw		r23, -0x0007(r19)
		subi	r17, r17, 8
		b		FDP_05FC


FDP_05d0
		srwi	r23, r20, 8
		stb		r23, -0x0006(r19)
		subi	r17, r17, 2


FDP_05dc
		srwi	r23, r21, 24
		insrwi	r23, r20, 8, 16
		sth		r23, -0x0005(r19)
		subi	r17, r17, 4
		b		FDP_05FC


FDP_05f0
		srwi	r23, r21, 24
		stb		r23, -0x0004(r19)
		subi	r17, r17, 2


FDP_05fc
		srwi	r23, r21, 8
		sth		r23, -0x0003(r19)
		subi	r17, r17, 4
		stb		r21, -0x0001(r19)
		b		FDP_011C


FDP_0610
		srwi	r23, r21, 8
		stb		r23, -0x0002(r19)
		subi	r17, r17, 2


FDP_061c
		stb		r21, -0x0001(r19)
		b		FDP_011C


FDP_0624
		srwi	r23, r20, 16
		sth		r23, -0x0008(r19)
		subi	r17, r17, 4
		b		FDP_0640


FDP_0634
		srwi	r23, r20, 16
		stb		r23, -0x0007(r19)
		subi	r17, r17, 2


FDP_0640
		srwi	r23, r21, 16
		insrwi	r23, r20, 16, 0
		stw		r23, -0x0006(r19)
		subi	r17, r17, 8
		sth		r21, -0x0002(r19)
		b		FDP_011C


FDP_0658
		stb		r20, -0x0005(r19)
		subi	r17, r17, 2
		b		FDP_00F4


FDP_0664
		srwi	r23, r21, 16
		stb		r23, -0x0003(r19)
		subi	r17, r17, 2


FDP_0670
		sth		r21, -0x0002(r19)
		b		FDP_011C


FDP_0678
		stw		r20, -0x0008(r19)
		subi	r17, r17, 8
		stw		r21, -0x0004(r19)
		b		FDP_011C


FDP_0688
		srwi	r23, r20, 16
		stb		r23, -0x0007(r19)
		subi	r17, r17, 2


FDP_0694
		sth		r20, -0x0006(r19)
		subi	r17, r17, 4
		stw		r21, -0x0004(r19)
		b		FDP_011C


FDP_06a4
		stb		r20, -0x0005(r19)
		subi	r17, r17, 2
		stw		r21, -0x0004(r19)
		b		FDP_011C


FDP_06b4
		bso		cr5, FDP_06C0
		stw		r21, -0x0004(r19)
		b		FDP_011C


FDP_06c0
		li		r23, -4
		stwcx.	r21, r23, r19
		isync
		mfcr	r23
		rlwimi	r13, r23, 0, 0, 3
		b		FDP_011C


FDP_06d8
		stw		r20, -0x0008(r19)
		stw		r21, -0x0004(r19)
		b		FDP_011C


FDP_06e4
		clrrwi	r23, r25, 10
		rlwimi	r23, r17, 14, 24, 28
		addi	r23, r23, 10784
		mtlr	r23
		mr		r23, r18
		oris	r11, r11, 0x0200
		blr






;	                     major_0x05f00

	;	Which to use? Probably align.
		align	9
;	org		FDP + 0x800



		macro
		MisalignmentOpcodeTableEntry	&hihalf, &primaryfunc, &secondaryfunc

		dc.w	&hihalf
		dc.b	(&primaryfunc - FDP) >> 2
		dc.b	(&secondaryfunc - FDP) >> 2

		endm



		macro
		MisalignmentOpcodeTableMacro	&FirstTable


;	X-form extended opcodes:    0    4    8   12   16   20   24   28
;	                                                  lwarx

		MisalignmentOpcodeTableEntry	0x2540,		FDP_00b8,	FDP_0150


;	X-form extended opcodes:   64   68   72   76   80   84   88   92

		MisalignmentOpcodeTableEntry	0x4550,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  128  132  136  140  144  148  152  156

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  192  196  200  204  208  212  216  220

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  256  260  264  268  272  276  280  284

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  320  324  328  332  336  340  344  348

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  384  388  392  396  400  404  408  412

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  448  452  456  460  464  468  472  476

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  512  516  520  524  528  532  536  540

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  576  580  584  588  592  596  600  604

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  640  644  648  652  656  660  664  668

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  704  708  712  716  720  724  728  732

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  768  772  776  780  784  788  792  796

		MisalignmentOpcodeTableEntry	0x4430,		FDP_00e4,	FDP_0150


;	X-form extended opcodes:  832  836  840  844  848  852  856  860

		MisalignmentOpcodeTableEntry	0x2460,		FDP_00e4,	FDP_0150


;	X-form extended opcodes:  896  900  904  908  912  916  920  924

		MisalignmentOpcodeTableEntry	0x4130,		FDP_00dc,	FDP_015C


;	X-form extended opcodes:  960  964  968  972  976  980  984  988

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:   32   36   40   44   48   52   56   60

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:   96  100  104  108  112  116  120  124

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  160  164  168  172  176  180  184  188

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  224  228  232  236  240  244  248  252

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  288  292  296  300  304  308  312  316

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  352  356  360  364  368  372  376  380

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  416  420  424  428  432  436  440  444

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  480  484  488  492  496  500  504  508

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  544  548  552  556  560  564  568  572

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  608  612  616  620  624  628  632  636

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  672  676  680  684  688  692  696  700

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  736  740  744  748  752  756  760  764

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  800  804  808  812  816  820  824  828

		MisalignmentOpcodeTableEntry	0x4430,		FDP_00e8,	FDP_0150


;	X-form extended opcodes:  864  868  872  876  880  884  888  892

		MisalignmentOpcodeTableEntry	0x45b3,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  928  932  936  940  944  948  952  956

		MisalignmentOpcodeTableEntry	0x4130,		FDP_00a4,	FDP_015C


;	X-form extended opcodes:  992  996 1000 1004 1008 1012 1016 1020

		MisalignmentOpcodeTableEntry	0x41f2,		FDP_panic,	FDP_0004


;	X-form extended opcodes:    1    5    9   13   17   21   25   29

		MisalignmentOpcodeTableEntry	0x4430,		FDP_00e4,	FDP_0150


;	X-form extended opcodes:   65   69   73   77   81   85   89   93

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  129  133  137  141  145  149  153  157

		MisalignmentOpcodeTableEntry	0x4130,		FDP_00dc,	FDP_015C


;	X-form extended opcodes:  193  197  201  205  209  213  217  221

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  257  261  265  269  273  277  281  285

		MisalignmentOpcodeTableEntry	0x268b,		FDP_0314,	FDP_02FC


;	X-form extended opcodes:  321  325  329  333  337  341  345  349

		MisalignmentOpcodeTableEntry	0x2460,		FDP_00e4,	FDP_0150


;	X-form extended opcodes:  385  389  393  397  401  405  409  413

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  449  453  457  461  465  469  473  477

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                  lswx
;	X-form extended opcodes:  513  517  521  525  529  533  537  541

		MisalignmentOpcodeTableEntry	0x260b,		FDP_02b0,	FDP_02E4


;	                                                  lswi
;	X-form extended opcodes:  577  581  585  589  593  597  601  605

		MisalignmentOpcodeTableEntry	0x260f,		FDP_029c,	FDP_02E4


;	                                                  stswx
;	X-form extended opcodes:  641  645  649  653  657  661  665  669

		MisalignmentOpcodeTableEntry	0x2242,		FDP_0260,	FDP_0284


;	                                                  stswi
;	X-form extended opcodes:  705  709  713  717  721  725  729  733

		MisalignmentOpcodeTableEntry	0x224e,		FDP_0254,	FDP_0284


;	X-form extended opcodes:  769  773  777  781  785  789  793  797

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  833  837  841  845  849  853  857  861

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  897  901  905  909  913  917  921  925

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  961  965  969  973  977  981  985  989

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:   33   37   41   45   49   53   57   61

		MisalignmentOpcodeTableEntry	0x4430,		FDP_00e8,	FDP_0150


;	X-form extended opcodes:   97  101  105  109  113  117  121  125

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  161  165  169  173  177  181  185  189

		MisalignmentOpcodeTableEntry	0x4130,		FDP_00a4,	FDP_015C


;	X-form extended opcodes:  225  229  233  237  241  245  249  253

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  289  293  297  301  305  309  313  317

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  353  357  361  365  369  373  377  381

		MisalignmentOpcodeTableEntry	0x2460,		FDP_00e8,	FDP_015C


;	X-form extended opcodes:  417  421  425  429  433  437  441  445

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  481  485  489  493  497  501  505  509

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  545  549  553  557  561  565  569  573

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  609  613  617  621  625  629  633  637

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  673  677  681  685  689  693  697  701

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  737  741  745  749  753  757  761  765

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  801  805  809  813  817  821  825  829

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  865  869  873  877  881  885  889  893

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  929  933  937  941  945  949  953  957

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  993  997 1001 1005 1009 1013 1017 1021

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:    2    6   10   14   18   22   26   30

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:   66   70   74   78   82   86   90   94

		MisalignmentOpcodeTableEntry	0x0fe2,		FDP_00e8,	FDP_023C


;	X-form extended opcodes:  130  134  138  142  146  150  154  158
;	                                                  stwcx.

		MisalignmentOpcodeTableEntry	0x2160,		FDP_00b0,	FDP_015C


;	X-form extended opcodes:  194  198  202  206  210  214  218  222

		MisalignmentOpcodeTableEntry	0x4170,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  258  262  266  270  274  278  282  286

		MisalignmentOpcodeTableEntry	0x0fe2,		FDP_00e8,	FDP_023C


;	X-form extended opcodes:  322  326  330  334  338  342  346  350

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  386  390  394  398  402  406  410  414

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  450  454  458  462  466  470  474  478

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                  lwbrx
;	X-form extended opcodes:  514  518  522  526  530  534  538  542

		MisalignmentOpcodeTableEntry	0x24a2,		FDP_00e8,	FDP_0164


;	X-form extended opcodes:  578  582  586  590  594  598  602  606

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                 stwbrx
;	X-form extended opcodes:  642  646  650  654  658  662  666  670

		MisalignmentOpcodeTableEntry	0x2120,		FDP_0088,	FDP_015C


;	X-form extended opcodes:  706  710  714  718  722  726  730  734

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                  lhbrx
;	X-form extended opcodes:  770  774  778  782  786  790  794  798

		MisalignmentOpcodeTableEntry	0x1492,		FDP_00e8,	FDP_0160


;	X-form extended opcodes:  834  838  842  846  850  854  858  862

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                 sthbrx
;	X-form extended opcodes:  898  902  906  910  914  918  922  926

		MisalignmentOpcodeTableEntry	0x1110,		FDP_0094,	FDP_015C


;	X-form extended opcodes:  962  966  970  974  978  982  986  990

		MisalignmentOpcodeTableEntry	0x0fe2,		FDP_00e8,	FDP_023C


;	X-form extended opcodes:   34   38   42   46   50   54   58   62

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004
	else
		MisalignmentOpcodeTableEntry	0x0fe2,		FDP_00e8,	FDP_023C
	endif


;	X-form extended opcodes:   98  102  106  110  114  118  122  126

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  162  166  170  174  178  182  186  190

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  226  230  234  238  242  246  250  254

		MisalignmentOpcodeTableEntry	0x0fe2,		FDP_00e8,	FDP_023C


;	                                                  eciwx
;	X-form extended opcodes:  290  294  298  302  306  310  314  318

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_00e4,	FDP_024C


;	X-form extended opcodes:  354  358  362  366  370  374  378  382

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                  ecowx
;	X-form extended opcodes:  418  422  426  430  434  438  442  446

		MisalignmentOpcodeTableEntry	0x03f0,		FDP_00dc,	FDP_024C


;	X-form extended opcodes:  482  486  490  494  498  502  506  510

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  546  550  554  558  562  566  570  574

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  610  614  618  622  626  630  634  638

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  674  678  682  686  690  694  698  702

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  738  742  746  750  754  758  762  766

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  802  806  810  814  818  822  826  830

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  866  870  874  878  882  886  890  894

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  930  934  938  942  946  950  954  958

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                  dcbz
;	X-form extended opcodes:  994  998 1002 1006 1010 1014 1018 1022

		MisalignmentOpcodeTableEntry	0x4302,		FDP_01f8,	FDP_020C


;	                                                  lwzx
;	X-form extended opcodes:    3    7   11   15   19   23   27   31
;	D-form opcodes:             0   32
;	                               lwz

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x0f50,		FDP_00e4,	FDP_0370
	else
		MisalignmentOpcodeTableEntry	0x2420,		FDP_00e4,	FDP_0150
	endif


;	                                                  lbzx
;	X-form extended opcodes:   67   71   75   79   83   87   91   95
;	D-form opcodes:             2   34
;	                               lbz

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x2770,		FDP_00d4,	FDP_0398
	else
		MisalignmentOpcodeTableEntry	0x0c00,		FDP_00e4,	FDP_0150
	endif


;	                                                  stwx
;	X-form extended opcodes:  131  135  139  143  147  151  155  159
;	D-form opcodes:             4   36
;	                               stw

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x0b90,		FDP_0350,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x2120,		FDP_00dc,	FDP_015C
	endif


;	                                                  stbx
;	X-form extended opcodes:  195  199  203  207  211  215  219  223
;	D-form opcodes:             6   38
;	                               stb

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x23b0,		FDP_0364,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x0900,		FDP_00dc,	FDP_015C
	endif


;	                                                  lhzx
;	X-form extended opcodes:  259  263  267  271  275  279  283  287
;	D-form opcodes:             8   40
;	                               lhz

		MisalignmentOpcodeTableEntry	0x1410,		FDP_00e4,	FDP_0150

;	                                                  lhax
;	X-form extended opcodes:  323  327  331  335  339  343  347  351
;	D-form opcodes:            10   42
;	                               lha      

		MisalignmentOpcodeTableEntry	0x1450,		FDP_00e4,	FDP_014C


;	                                                  sthx
;	X-form extended opcodes:  387  391  395  399  403  407  411  415
;	D-form opcodes:            12   44
;	                               sth

		MisalignmentOpcodeTableEntry	0x1110,		FDP_00dc,	FDP_015C


;	X-form extended opcodes:  451  455  459  463  467  471  475  479
;	D-form opcodes:            14   46
;	                               lmw

		MisalignmentOpcodeTableEntry	0x25a3,		FDP_00e8,	FDP_01A4


;	                                                  lfsx
;	X-form extended opcodes:  515  519  523  527  531  535  539  543
;	D-form opcodes:            16   48
;	                               lfs

		MisalignmentOpcodeTableEntry	0x24e0,		FDP_00e4,	FDP_0174


;	                                                  lfdx
;	X-form extended opcodes:  579  583  587  591  595  599  603  607
;	D-form opcodes:            18   50
;	                               lfd

		MisalignmentOpcodeTableEntry	0x44f0,		FDP_00e4,	FDP_0178


;	                                                  stfsx
;	X-form extended opcodes:  643  647  651  655  659  663  667  671
;	D-form opcodes:            20   52
;	                               stfs

		MisalignmentOpcodeTableEntry	0x2120,		FDP_0008,	FDP_015C


;	                                                  stfdx
;	X-form extended opcodes:  707  711  715  719  723  727  731  735
;	D-form opcodes:            22   54
;	                               stfd

		MisalignmentOpcodeTableEntry	0x4130,		FDP_0014,	FDP_015C


;	X-form extended opcodes:  771  775  779  783  787  791  795  799
;	D-form opcodes:            24   56

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  835  839  843  847  851  855  859  863
;	D-form opcodes:            26   58

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  899  903  907  911  915  919  923  927
;	D-form opcodes:            28   60

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	                                                 stfiwx
;	X-form extended opcodes:  963  967  971  975  979  983  987  991
;	D-form opcodes:            30   62

		MisalignmentOpcodeTableEntry	0x2120,		FDP_0014,	FDP_015C


;	                                                  lwzux
;	X-form extended opcodes:   35   39   43   47   51   55   59   63
;	D-form opcodes:             1   33
;	                               lwzu

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x1760,		FDP_00cc,	FDP_0384
	else
		MisalignmentOpcodeTableEntry	0x2420,		FDP_00e8,	FDP_0150
	endif


;	                                                  lbzux
;	X-form extended opcodes:   99  103  107  111  115  119  123  127
;	D-form opcodes:             3   35
;	                               lbzu

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x8740,		FDP_00c0,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x0c00,		FDP_00e8,	FDP_0150
	endif


;	                                                  stwux
;	X-form extended opcodes:  163  167  171  175  179  183  187  191
;	D-form opcodes:             5   37
;	                               stwu

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x23a0,		FDP_0358,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x2120,		FDP_00a4,	FDP_015C
	endif


;	                                                  stbux
;	X-form extended opcodes:  227  231  235  239  243  247  251  255
;	D-form opcodes:             7   39
;	                               stbu

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x8380,		FDP_00c0,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x0900,		FDP_00a4,	FDP_015C
	endif


;	                                                  lhzux
;	X-form extended opcodes:  291  295  299  303  307  311  315  319
;	D-form opcodes:             9   41
;	                               lhzu

		MisalignmentOpcodeTableEntry	0x1410,		FDP_00e8,	FDP_0150


;	                                                  lhaux
;	X-form extended opcodes:  355  359  363  367  371  375  379  383
;	D-form opcodes:            11   43
;	                               lhau

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x8740,		FDP_00c0,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x1450,		FDP_00e8,	FDP_014C
	endif


;	                                                  sthux
;	X-form extended opcodes:  419  423  427  431  435  439  443  447
;	D-form opcodes:            13   45
;	                               sthu

		MisalignmentOpcodeTableEntry	0x1110,		FDP_00a4,	FDP_015C


;	X-form extended opcodes:  483  487  491  495  499  503  507  511
;	D-form opcodes:            15   47
;	                               stmw

	if	&FirstTable
		MisalignmentOpcodeTableEntry	0x8380,		FDP_00c0,	FDP_015C
	else
		MisalignmentOpcodeTableEntry	0x21e2,		FDP_00a4,	FDP_01D8
	endif


;	                                                  lfsux
;	X-form extended opcodes:  547  551  555  559  563  567  571  575
;	D-form opcodes:            17   49
;	                               lfsu

		MisalignmentOpcodeTableEntry	0x24e0,		FDP_00e8,	FDP_0174


;	                                                  lfdux
;	X-form extended opcodes:  611  615  619  623  627  631  635  639
;	D-form opcodes:            19   51
;	                               lfdu

		MisalignmentOpcodeTableEntry	0x44f0,		FDP_00e8,	FDP_0178


;	                                                 stfsux
;	X-form extended opcodes:  675  679  683  687  691  695  699  703
;	D-form opcodes:            21   53
;	                              stfsu

		MisalignmentOpcodeTableEntry	0x2120,		FDP_000c,	FDP_015C


;	                                                 stfdux
;	X-form extended opcodes:  739  743  747  751  755  759  763  767
;	D-form opcodes:            23   55
;	                              stfdu

		MisalignmentOpcodeTableEntry	0x4130,		FDP_0018,	FDP_015C


;	X-form extended opcodes:  803  807  811  815  819  823  827  831
;	D-form opcodes:            25   57

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  867  871  875  879  883  887  891  895
;	D-form opcodes:            27   59

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  931  935  939  943  947  951  955  959
;	D-form opcodes:            29   61

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004


;	X-form extended opcodes:  995  999 1003 1007 1011 1015 1019 1023
;	D-form opcodes:            31   63

		MisalignmentOpcodeTableEntry	0x07f0,		FDP_panic,	FDP_0004

		endm



		MisalignmentOpcodeTableMacro	1
		MisalignmentOpcodeTableMacro	0







		macro
		HalfWordTableEntry		&n, &target

@flashback
		org		HalfWordTable + 2*&n
		dc.w	&target - FDP - 2*&n
		org		@flashback

		endm

HalfWordTable										;	FDP + 0xc00
		dcb.w	144, 0xcafe;(FDP_panic - FDP) - (* - HalfWordTable)


		HalfWordTableEntry		  0,	FDP_06e4
		HalfWordTableEntry		  1,	FDP_06e4
		HalfWordTableEntry		  2,	FDP_06e4
		HalfWordTableEntry		  3,	FDP_06e4
		HalfWordTableEntry		  4,	FDP_06e4
		HalfWordTableEntry		  5,	FDP_06e4
		HalfWordTableEntry		  6,	FDP_06e4
		HalfWordTableEntry		  7,	FDP_06e4

		HalfWordTableEntry		  8,	FDP_0554
		HalfWordTableEntry		  9,	FDP_0554
		HalfWordTableEntry		 10,	FDP_0554
		HalfWordTableEntry		 11,	FDP_0554
		HalfWordTableEntry		 12,	FDP_0554
		HalfWordTableEntry		 13,	FDP_0554
		HalfWordTableEntry		 14,	FDP_0554
		HalfWordTableEntry		 15,	FDP_0554

		HalfWordTableEntry		 16,	FDP_061c
		HalfWordTableEntry		 17,	FDP_061c
		HalfWordTableEntry		 18,	FDP_061c
		HalfWordTableEntry		 19,	FDP_061c
		HalfWordTableEntry		 20,	FDP_061c
		HalfWordTableEntry		 21,	FDP_061c
		HalfWordTableEntry		 22,	FDP_061c
		HalfWordTableEntry		 23,	FDP_061c

		HalfWordTableEntry		 24,	FDP_0490
		HalfWordTableEntry		 25,	FDP_0490
		HalfWordTableEntry		 26,	FDP_0490
		HalfWordTableEntry		 27,	FDP_0490
		HalfWordTableEntry		 28,	FDP_0490
		HalfWordTableEntry		 29,	FDP_0490
		HalfWordTableEntry		 30,	FDP_0490
		HalfWordTableEntry		 31,	FDP_0490

		HalfWordTableEntry		 32,	FDP_0670
		HalfWordTableEntry		 33,	FDP_0610
		HalfWordTableEntry		 34,	FDP_0670
		HalfWordTableEntry		 35,	FDP_0610
		HalfWordTableEntry		 36,	FDP_0670
		HalfWordTableEntry		 37,	FDP_0610
		HalfWordTableEntry		 38,	FDP_0670
		HalfWordTableEntry		 39,	FDP_0610

		HalfWordTableEntry		 40,	FDP_0114
		HalfWordTableEntry		 41,	FDP_0484
		HalfWordTableEntry		 42,	FDP_0114
		HalfWordTableEntry		 43,	FDP_0484
		HalfWordTableEntry		 44,	FDP_0114
		HalfWordTableEntry		 45,	FDP_0484
		HalfWordTableEntry		 46,	FDP_0114
		HalfWordTableEntry		 47,	FDP_0484

		HalfWordTableEntry		 48,	FDP_0664
		HalfWordTableEntry		 49,	FDP_05fc
		HalfWordTableEntry		 50,	FDP_0664
		HalfWordTableEntry		 51,	FDP_05fc
		HalfWordTableEntry		 52,	FDP_0664
		HalfWordTableEntry		 53,	FDP_05fc
		HalfWordTableEntry		 54,	FDP_0664
		HalfWordTableEntry		 55,	FDP_05fc

		HalfWordTableEntry		 56,	FDP_04dc
		HalfWordTableEntry		 57,	FDP_0474
		HalfWordTableEntry		 58,	FDP_04dc
		HalfWordTableEntry		 59,	FDP_0474
		HalfWordTableEntry		 60,	FDP_04dc
		HalfWordTableEntry		 61,	FDP_0474
		HalfWordTableEntry		 62,	FDP_04dc
		HalfWordTableEntry		 63,	FDP_0474

		HalfWordTableEntry		 64,	FDP_06b4
		HalfWordTableEntry		 65,	FDP_05f0
		HalfWordTableEntry		 66,	FDP_00f4
		HalfWordTableEntry		 67,	FDP_05f0
		HalfWordTableEntry		 68,	FDP_06b4
		HalfWordTableEntry		 69,	FDP_05f0
		HalfWordTableEntry		 70,	FDP_00f4
		HalfWordTableEntry		 71,	FDP_05f0

		HalfWordTableEntry		 72,	FDP_0530
		HalfWordTableEntry		 73,	FDP_0468
		HalfWordTableEntry		 74,	FDP_0108
		HalfWordTableEntry		 75,	FDP_0468
		HalfWordTableEntry		 76,	FDP_0530
		HalfWordTableEntry		 77,	FDP_0468
		HalfWordTableEntry		 78,	FDP_0108
		HalfWordTableEntry		 79,	FDP_0468

		HalfWordTableEntry		 80,	FDP_06a4
		HalfWordTableEntry		 81,	FDP_0598
		HalfWordTableEntry		 82,	FDP_0658
		HalfWordTableEntry		 83,	FDP_05dc
		HalfWordTableEntry		 84,	FDP_06a4
		HalfWordTableEntry		 85,	FDP_0598
		HalfWordTableEntry		 86,	FDP_0658
		HalfWordTableEntry		 87,	FDP_05dc

		HalfWordTableEntry		 88,	FDP_051c
		HalfWordTableEntry		 89,	FDP_0414
		HalfWordTableEntry		 90,	FDP_04cc
		HalfWordTableEntry		 91,	FDP_0454
		HalfWordTableEntry		 92,	FDP_051c
		HalfWordTableEntry		 93,	FDP_0414
		HalfWordTableEntry		 94,	FDP_04cc
		HalfWordTableEntry		 95,	FDP_0454

		HalfWordTableEntry		 96,	FDP_0694
		HalfWordTableEntry		 97,	FDP_058c
		HalfWordTableEntry		 98,	FDP_0640
		HalfWordTableEntry		 99,	FDP_05d0
		HalfWordTableEntry		100,	FDP_0694
		HalfWordTableEntry		101,	FDP_058c
		HalfWordTableEntry		102,	FDP_0640
		HalfWordTableEntry		103,	FDP_05d0

		HalfWordTableEntry		104,	FDP_0508
		HalfWordTableEntry		105,	FDP_0408
		HalfWordTableEntry		106,	FDP_04b8
		HalfWordTableEntry		107,	FDP_0448
		HalfWordTableEntry		108,	FDP_0508
		HalfWordTableEntry		109,	FDP_0408
		HalfWordTableEntry		110,	FDP_04b8
		HalfWordTableEntry		111,	FDP_0448

		HalfWordTableEntry		112,	FDP_0688
		HalfWordTableEntry		113,	FDP_057c
		HalfWordTableEntry		114,	FDP_0634
		HalfWordTableEntry		115,	FDP_05bc
		HalfWordTableEntry		116,	FDP_0688
		HalfWordTableEntry		117,	FDP_057c
		HalfWordTableEntry		118,	FDP_0634
		HalfWordTableEntry		119,	FDP_05bc

		HalfWordTableEntry		120,	FDP_04fc
		HalfWordTableEntry		121,	FDP_03f8
		HalfWordTableEntry		122,	FDP_04ac
		HalfWordTableEntry		123,	FDP_0434
		HalfWordTableEntry		124,	FDP_04fc
		HalfWordTableEntry		125,	FDP_03f8
		HalfWordTableEntry		126,	FDP_04ac
		HalfWordTableEntry		127,	FDP_0434

		HalfWordTableEntry		128,	FDP_06d8
		HalfWordTableEntry		129,	FDP_0570
		HalfWordTableEntry		130,	FDP_0624
		HalfWordTableEntry		131,	FDP_05b0
		HalfWordTableEntry		132,	FDP_0678
		HalfWordTableEntry		133,	FDP_0570
		HalfWordTableEntry		134,	FDP_0624
		HalfWordTableEntry		135,	FDP_05b0

		HalfWordTableEntry		136,	FDP_0548
		HalfWordTableEntry		137,	FDP_03ec
		HalfWordTableEntry		138,	FDP_049c
		HalfWordTableEntry		139,	FDP_0428
		HalfWordTableEntry		140,	FDP_04ec
		HalfWordTableEntry		141,	FDP_03ec
		HalfWordTableEntry		142,	FDP_049c
		HalfWordTableEntry		143,	FDP_0428




		macro
		MixedTableEntry		&flags, &target

		dc.b	&flags
		dc.b	(&target - FDP) >> 2

		endm

;	this is the d20 table
MixedTable
		MixedTableEntry		%01,	FDP_0150
		MixedTableEntry		%01,	FDP_0150
		MixedTableEntry		%01,	FDP_0150
		MixedTableEntry		%01,	FDP_0150
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_014C
		MixedTableEntry		%01,	FDP_0150
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%11,	FDP_0160
		MixedTableEntry		%11,	FDP_0164
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0174
		MixedTableEntry		%01,	FDP_0178
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_0150
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%11,	FDP_01A4
		MixedTableEntry		%11,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%11,	FDP_01D8
		MixedTableEntry		%11,	FDP_0004
		MixedTableEntry		%11,	FDP_02E4
		MixedTableEntry		%11,	FDP_02E4
		MixedTableEntry		%11,	FDP_02E4
		MixedTableEntry		%11,	FDP_02E4
		MixedTableEntry		%11,	FDP_0284
		MixedTableEntry		%11,	FDP_0284
		MixedTableEntry		%11,	FDP_0284
		MixedTableEntry		%11,	FDP_0284
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_02FC
		MixedTableEntry		%11,	FDP_020C
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_0370
		MixedTableEntry		%01,	FDP_0384
		MixedTableEntry		%01,	FDP_0398
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_015C
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%01,	FDP_0004
		MixedTableEntry		%11,	FDP_023C
		MixedTableEntry		%01,	FDP_024C



FDP_0DA0
		li		r0, -3
		sc
		andi.	r23, r16, 0x0020
		addi	r10, r10, 4
		mfsprg	SP, 0
		mtsrr0	r10
		mtsrr1	r11
		bne		FDP_0E30
		mtlr	r12
		bns		cr3, FDP_0DFC


FDP_0DC8
		mtcrf	255, r13
		lmw		r2, 0x0008(SP)
		lwz		r0, 0x0000(SP)
		lwz		SP, 0x0004(SP)
		rfi
		dcb.b	32, 0


FDP_0DFC
		mtcrf	255, r13
		lmw		r10, 0x0028(SP)
		lwz		r0, 0x0000(SP)
		lwz		SP, 0x0004(SP)
		rfi
		dcb.b	32, 0


FDP_0E30
		mfsprg	r24, 3
		mtsprg	2, r12
		rlwinm	r16, r16, 0, 27, 25
		lwz		r12, 0x0034(r24)
		stw		r16, -0x0010(SP)
		mtcrf	255, r13
		mtlr	r12
		lmw		r2, 0x0008(SP)
		lwz		r0, 0x0000(SP)
		lwz		SP, 0x0004(SP)
		mtsprg	1, SP
		blrl


FDP_0E60
		andi.	r23, r17, 0x07C0
		rlwinm	r28, r17, 13, 25, 29
		lwzx	r21, SP, r28
		li		r22, 8
		insrwi	r17, r22, 6, 26
		addi	r19, r19, 4
		bne		FDP_03AC
		rlwinm	r22, r17, 9, 27, 28
		srw		r21, r21, r22
		extrwi	r22, r17, 2, 4
		neg		r22, r22
		add		r19, r19, r22
		addi	r22, r22, 4
		insrwi.	r17, r22, 5, 26
		b		FDP_03AC


FDP_0E9C
		rlwinm	r23, r17, 18, 25, 29
		cmpw	cr7, r28, r23
		rlwinm	r23, r17, 23, 25, 29
		cmpw	cr6, r28, r23
		beq		cr7, FDP_0EB8
		beq		cr6, FDP_0EB8
		stwx	r21, SP, r28


FDP_0EB8
		addis	r28, r17, 32
		rlwimi	r17, r28, 0, 6, 10
		subi	r17, r17, 64
		beq		FDP_0DA0


FDP_0EC8
		andi.	r23, r17, 0x07C0
		li		r22, 9
		insrwi	r17, r22, 6, 26
		addi	r19, r19, 4
		bne		FDP_03AC
		extrwi	r22, r17, 2, 4
		neg		r22, r22
		add		r19, r19, r22
		addi	r22, r22, 4
		insrwi.	r17, r22, 5, 26
		b		FDP_03AC


FDP_0EF4
		rlwinm	r23, r17, 18, 25, 29
		cmpw	cr7, r28, r23
		rlwinm	r23, r17, 23, 25, 29
		cmpw	cr6, r28, r23
		beq		cr7, FDP_0F10
		beq		cr6, FDP_0F10
		stwx	r21, SP, r28


FDP_0F10
		addis	r28, r17, 32
		rlwimi	r17, r28, 0, 6, 10
		subi	r17, r17, 64
		not		r22, r22
		rlwimi	r22, r17, 6, 30, 31
		li		r28, 1
		mfxer	r23
		extrwi	r23, r23, 8, 16
		srwi	r20, r21, 24
		cmpw	cr7, r20, r23
		add.	r22, r22, r28
		beq		cr7, FDP_0F80
		beq		FDP_0F80
		extrwi	r20, r21, 8, 8
		cmpw	cr7, r20, r23
		add.	r22, r22, r28
		beq		cr7, FDP_0F80
		beq		FDP_0F80
		extrwi	r20, r21, 8, 16
		cmpw	cr7, r20, r23
		add.	r22, r22, r28
		beq		cr7, FDP_0F80
		beq		FDP_0F80
		clrlwi	r20, r21, 24
		cmpw	cr7, r20, r23
		add.	r22, r22, r28
		beq		cr7, FDP_0F80
		bne		FDP_0EC8


FDP_0F80
		rlwinm.	r28, r17, 0, 3, 3
		mfxer	r23
		add		r22, r22, r23
		insrwi	r23, r22, 7, 25
		mtxer	r23
		beq		FDP_0DA0
		mfcr	r23
		clrlwi	r23, r23, 30
		insrwi	r13, r23, 4, 0
		b		FDP_0DA0


FDP_0FA8
		clrrwi	r20, r21, 31
		xor.	r21, r20, r21
		beq		FDP_0178
		rlwinm.	r23, r21, 16, 17, 24
		addi	r23, r23, 128
		rlwimi	r20, r21, 29, 5, 31
		extsh	r23, r23
		rlwimi	r20, r21, 0, 1, 1
		slwi	r21, r21, 29
		subi	r23, r23, 16512
		rlwimi	r20, r23, 0, 2, 4
		bne		FDP_0178
		srwi	r21, r21, 20
		insrwi	r21, r20, 20, 0
		cntlzw	r23, r21
		slw		r21, r21, r23
		neg		r23, r23
		rlwimi	r20, r21, 21, 12, 31
		addi	r23, r23, 896
		slwi	r21, r21, 21
		insrwi	r20, r23, 11, 1
		b		FDP_0178


FDP_1000
		clrrwi	r21, r25, 10
		rlwimi	r21, r17, 14, 24, 28
		rlwimi	r14, r11, 0, 6, 6
		add		r21, r21, r20
		mtmsr	r14
		mtlr	r21
		isync
		oris	r11, r11, 0x0200
		blr


FDP_1024
		clrrwi	r19, r25, 10
		rlwimi	r19, r17, 14, 24, 28
		add		r19, r19, r20
		mtlr	r19
		rlwimi	r14, r11, 0, 6, 6
		subi	r23, SP, 736
		mtmsr	r14
		insrwi	r23, r18, 4, 28
		isync
		blr


FDP_104c
		oris	r11, r11, 0x0200
		lbz		r21, 0x0000(r23)
		b		FDP_00E4


FDP_1058
		oris	r11, r11, 0x0200
		lhz		r21, 0x0000(r23)
		b		FDP_00E4


FDP_1064
		oris	r11, r11, 0x0200
		lwz		r21, 0x0000(r23)
		b		FDP_00E4









;	Called by setup. QEMU naturally complains.

;	SPRs:
;MMCR0		equ		952		;	monitor control register 0
MMCR1		equ		956		;	monitor control register 1
MMCR2		equ		944		;	monitor control register 2
;PMC1		equ		953		;	performance counter 1
;PMC2		equ		954		;	performance counter 2
PMC3		equ		957		;	performance counter 3
PMC4		equ		958		;	performance counter 4
BAMR		equ		951		;	breakpoint address mask register 1
;SIA		equ		955		;	sampled instruction address 1
;SDA		equ		959		;	sampled data address (604 only?)


		macro
		TestSPR		&dest, &goodgpr, &badgpr, &spr

		mtspr		&spr, &goodgpr
		not			&badgpr, &goodgpr
		mfspr		&badgpr, &spr
		xor&dot		&dest, &goodgpr, &badgpr

		endm



ProbePerfMonitor	;	OUTSIDE REFERER

	;	We will populate r23 with bit fields describing perf monitor capabilities
		li			r23, 0


	;	Temporarily disable program interrupts (leave old handler in r20)
		lwz			r21, KDP.PA_NanoKernelCode(r1)
		lwz			r20, KDP.YellowVecBase + VecTable.ProgramIntVector(r1)
		llabel		r18, IgnoreSoftwareInt
		add			r21, r18, r21
		stw			r21, KDP.YellowVecBase + VecTable.ProgramIntVector(r1)



	;	SET BIT 31 if all the 604 perf monitor registers work

		li			r18, 0

		TestSPR		r17, r18, r19, MMCR0
		TestSPR		r19, r18, r19, PMC1
		or			r17, r17, r19
		TestSPR		r19, r18, r19, PMC2
		or			r17, r17, r19
		TestSPR		r19, r18, r19, SIA
		or.			r17, r17, r19

		bne			@dont_set_bit_31
		_bset		r23, r23, 31
@dont_set_bit_31

	;	ONLY test for bits 28-30 if bit 31 was just set...

		mr.			r23, r23
		beq			@stop_testing_perf_monitor

		;	SET BIT 30 if all the 750 perf monitor registers work

			TestSPR		r17, r18, r19, MMCR1
			TestSPR		r19, r18, r19, PMC3
			or			r17, r17, r19
			TestSPR		r19, r18, r19, PMC4
			or.			r17, r17, r19

			bne			@dont_set_bit_30
			_bset		r23, r23, 30
@dont_set_bit_30

		;	SET BIT 29 if SDA (604 but not 750) works

			li			r18, 0xaaa0
			TestSPR.	r17, r18, r19, SDA

			beq			@dont_set_bit_29
			_bset		r23, r23, 29
@dont_set_bit_29

		;	SET BIT 28 if EVEN MORE perf monitor registers work

			li			r18,  0x00
			TestSPR		r17, r18, r19, MMCR2

			li			r18,  0x00
			TestSPR		r19, r18, r19, BAMR

			or.			r17, r17, r19

			bne			@dont_set_bit_28
			_bset		r23, r23, 28
@dont_set_bit_28

@stop_testing_perf_monitor


	;	Restore program interrupts
		stw			r20,  KDP.YellowVecBase + VecTable.ProgramIntVector(r1)


	;	Test r23 and save
		mr.			r23, r23
		stw			r23, KDP.PerfMonitorBits(r1)


	;	Set HiLevelPerfMonitorBits
		li			r23, 0
		_bset		r23, r23, 14
		_bset		r23, r23, 15


	;	SET BIT 18 if any perf monitor features present
		beq			* + 8
			_bset	r23, r23, 18


	;	And save
		stw			r23, KDP.HiLevelPerfMonitorBits(r1)


	;	Now do some insane arithmetic with the decrementer clock. TBE.

		lisori		r20, 0x80587ff3
		lisori		r21, 0xd62611e3

	;	Left-justify the decrementer clock rate
		lwz			r19, KDP.ProcessorInfo + NKProcessorInfo.DecClockRateHz(r1)
		cntlzw		r23, r19
		slw			r19, r19, r23

		cmpw		cr1, r20, r19
		addi		r23, r23,  0x02
		xor.		r24, r24, r24
		bge			cr1, ProbePerfMonitor_0x180
		addi		r23, r23, -0x01

ProbePerfMonitor_0x160
		cmpwi		cr1, r20,  0x00
		slwi		r20, r20,  1
		rlwimi		r20, r21,  1, 31, 31
		cmplw		cr2, r20, r19
		rlwinm.		r24, r24,  1,  0, 30
		slwi		r21, r21,  1
		blt			cr1, ProbePerfMonitor_0x180
		blt			cr2, ProbePerfMonitor_0x188

ProbePerfMonitor_0x180
		subf		r20, r19, r20
		ori			r24, r24,  0x01

ProbePerfMonitor_0x188
		bge			ProbePerfMonitor_0x160
		stw			r24,  0x05bc(r1)
		stb			r23,  0x05b8(r1)
		li			r21,  0x20
		subf		r21, r23, r21
		stb			r21,  0x05bb(r1)
		blr



FDPEmulateInstruction

		mfsprg	r1, 0
		lwz		r8,  0x0104(r6)
		stw		r8,  0x0000(r1)
		stw		r2,  0x0008(r1)
		stw		r3,  0x000c(r1)
		stw		r4,  0x0010(r1)
		stw		r5,  0x0014(r1)
		stmw	r14,  0x0038(r1)
		mr		r16, r7
		lwz		r7,  0x013c(r6)
		stw		r7,  0x001c(r1)
		lwz		r8,  0x0144(r6)
		stw		r8,  0x0020(r1)
		lwz		r9,  0x014c(r6)
		stw		r9,  0x0024(r1)
		lwz		r23,  0x0154(r6)
		stw		r23,  0x0028(r1)
		lwz		r23,  0x015c(r6)
		stw		r23,  0x002c(r1)
		lwz		r23,  0x0164(r6)
		stw		r23,  0x0030(r1)
		lwz		r23,  0x016c(r6)
		stw		r23,  0x0034(r1)
		lwz		r1, -0x0004(r1)
		addi	r22, r6,  0xc4
		lwz		r23,  0x0ea0(r1)
		lwz		r25,  0x0650(r1)
		addi	r23, r23,  0x01
		stw		r23,  0x0ea0(r1)
		mfsprg	r24, 3
		addi	r23, r1,  0x4e0
		mfmsr	r14
		ori		r15, r14,  0x10
		mtsprg	3, r23
		mtmsr	r15
		isync
		lwz		r27,  0x0000(r10)
		mtmsr	r14
		isync
		mtsprg	3, r24
		srwi	r23, r27, 26
		cmpwi	cr6, r23,  0x09
		cmpwi	r23,  0x16
		cmpwi	cr1, r23,  0x1f
		lwz		r20,  0x05b8(r1)
		rlwinm	r21, r16, 15, 14, 14
		neg		r21, r21
		rlwimi	r21, r16, 14, 16, 16
		or		r21, r21, r20
		rlwimi	r21, r27,  0, 21, 31
		rlwimi	r16, r16, 27, 26, 26
		mfsprg	r1, 0
		rlwinm	r17, r27, 13, 25, 29
		rlwinm	r18, r27, 18, 25, 29
		beq		cr6, FDP_1214_0x2b4
		mtcrf	 0x3f, r21
		rlwinm	r19, r27, 23, 25, 29
		beq		FDP_1bd0
		bne		cr1, FDP_1324
		rlwinm	r21, r27,  2, 24, 28
		add		r21, r21, r25
		lwz		r20,  0x1374(r21)
		rlwinm	r23, r27, 26, 27, 31
		lwz		r21,  0x1378(r21)
		rotlw.	r20, r20, r23
		add		r21, r21, r25
		mtlr	r21
		bltlr

FDP_1324
		ble		cr1, FDP_1338
		lis		r20,  0x5556
		ori		r20, r20,  0x5500
		rotlw.	r20, r20, r23
		blt		FDP_1c18

FDP_1338
		mtcrf	 0x70, r11
		li		r8,  0x04
		ble		cr3, FDP_1354


FDP_1344
		mtcrf	 0x0f, r11
		li		r8,  0x04
		ble		cr4, FDP_1354
		li		r8,  0x05

FDP_1354
		lwz		r6, -0x0004(r1)
		lwz		r9,  0x0ea0(r6)
		lmw		r14,  0x0038(r1)
		addi	r9, r9, -0x01
		stw		r9,  0x0ea0(r6)
		lwz		r6, -0x0014(r1)
		lwz		r7, -0x0010(r1)
		b		major_0x02980_0x134



;	What the hell is this?
ProgramIntTable
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00910091, FDP_148c - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x10301030, 0x0000151c
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00328000, 0x000016d0
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x0080a000, 0x00001c18
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x55545502, 0x00001c20
		dc.l	0x0f000f0c, 0x00001ad0
		dc.l	0x0a008a08, 0x00001aa8
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x80008000, 0x00001b8c
		dc.l	0x00000000, FDP_1338 - FDP
		dc.l	0x00000000, FDP_1338 - FDP

FDP_1474
		stw		r20, 0(r22)


FDP_1478
		bns		cr7, FDP_1484
		mfcr	r23
		rlwimi	r13, r23, 0, 0, 3

FDP_1484
		stwx	r21, r1, r17
		b		FDP_0da0

FDP_148c
		bns		cr2, FDP_1338
		lwzx	r18, SP, r18
		bge		cr6, FDP_14EC
		bgt		cr5, FDP_14B0
		mr.		r21, r18
		crxor	cr5_SO, cr5_SO, cr0_LT
		bns		cr5, FDP_1478
		neg.	r21, r18
		b		FDP_1478

FDP_14b0
		li		r21, 0
		addo.	r21, r18, r21
		crxor	cr5_SO, cr5_SO, cr0_LT
		bns		cr5, FDP_1478
		nego.	r21, r18
		b		FDP_1478

FDP_1214_0x2b4
		mtcrf	0x3f, r21
		bns		cr2, FDP_1338
		lwzx	r18, r1, r18
		extsh	r19, r27
		cmpw	cr1, r19, r18
		subf	r21, r21, r21
		blt		cr1, FDP_1484
		subf	r21, r18, r19
		b		FDP_1484

FDP_14ec
		lwzx	r19, SP, r19
		bgt		cr5, FDP_1508
		cmpw	cr1, r19, r18
		sub.	r21, r21, r21
		blt		cr1, FDP_1478
		sub.	r21, r19, r18
		b		FDP_1478


FDP_1508
		cmpw	cr1, r19, r18
		subo.	r21, r21, r21
		blt		cr1, FDP_1478
		subo.	r21, r19, r18
		b		FDP_1478
		bge		cr2, FDP_1338
		lwzx	r19, SP, r19
		lwzx	r18, SP, r18
		bne		cr5, FDP_16B8
		cmpwi	cr1, r19, 0
		bgt		cr6, FDP_1548
		lwz		r24, 0(r22)
		srwi	r21, r24, 31
		add.	r21, r21, r18
		bne		FDP_1590
		mr		r18, r24


FDP_1548
		cmpwi	r19, -1
		bgt		cr5, FDP_1574
		beq		FDP_1568
		beq		cr1, FDP_1580
		divw	r21, r18, r19


FDP_155c
		mullw	r20, r21, r19
		sub.	r20, r18, r20
		b		FDP_1474


FDP_1568
		neg		r21, r18
		sub.	r20, r18, r18
		b		FDP_1474


FDP_1574
		divwo	r21, r18, r19
		beq		FDP_1568
		bne		cr1, FDP_155C


FDP_1580
		rlwinm	r23, r18, 2, 30, 30
		subi	r21, r23, 1
		mr.		r20, r18
		b		FDP_1474


FDP_1590
		mfxer	r26			; XER = 1
		beq		cr1, FDP_1698
		cmpwi	r19, 0
		cmpwi	cr1, r18, 0
		crxor	cr1_SO, cr0_LT, cr1_LT
		bge		FDP_15AC
		neg		r19, r19


FDP_15ac
		bge		cr1, FDP_15B8
		subfic	r24, r24, 0
		subfze	r18, r18


FDP_15b8
		cmplw	r18, r19
		bge		FDP_1698
		cntlzw	r21, r19
		xor		r18, r18, r24
		slw		r19, r19, r21
		rotlw	r18, r18, r21
		slw		r24, r24, r21
		xor		r18, r18, r24
		srwi	r23, r19, 16
		divwu	r20, r18, r23
		mullw	r23, r20, r23
		sub		r18, r18, r23
		slwi	r18, r18, 16
		inslwi	r18, r24, 16, 16
		slwi	r24, r24, 16
		clrlwi	r23, r19, 16
		mullw	r23, r20, r23
		subc	r18, r18, r23
		subfe.	r23, r23, r23
		add		r24, r24, r20
		bge		FDP_161C


FDP_160c
		addc	r18, r18, r19
		addze.	r23, r23
		subi	r24, r24, 1
		blt		FDP_160C


FDP_161c
		srwi	r23, r19, 16
		divwu	r20, r18, r23
		mullw	r23, r20, r23
		sub		r18, r18, r23
		slwi	r18, r18, 16
		inslwi	r18, r24, 16, 16
		slwi	r24, r24, 16
		clrlwi	r23, r19, 16
		mullw	r23, r20, r23
		subc	r18, r18, r23
		subfe.	r23, r23, r23
		add		r24, r24, r20
		bge		FDP_1660


FDP_1650
		addc	r18, r18, r19
		addze.	r23, r23
		subi	r24, r24, 1
		blt		FDP_1650


FDP_1660
		srw		r20, r18, r21
		mr.		r21, r24
		bge		cr1, FDP_1670
		neg		r20, r20


FDP_1670
		bns		cr1, FDP_1678
		neg.	r21, r21


FDP_1678
		ble		cr5, FDP_168C
		crxor	cr0_LT, cr0_LT, cr1_SO
		rlwinm	r26, r26, 0, 2, 0
		bge		FDP_168C
		oris	r26, r26, 0xC000


FDP_168c
		mtxer	r26			; XER = 1
		mr.		r20, r20
		b		FDP_1474


FDP_1698
		ble		cr5, FDP_16A0
		oris	r26, r26, 0xC000


FDP_16a0
		mtxer	r26			; XER = 1
		not		r21, r18
		srwi	r23, r18, 31
		mr.		r20, r24
		add		r21, r23, r21
		b		FDP_1474


FDP_16b8
		mulhw	r21, r18, r19
		bgt		cr5, FDP_16C8
		mullw.	r20, r18, r19
		b		FDP_1474


FDP_16c8
		mullwo.	r20, r18, r19
		b		FDP_1474
		bgt		cr6, FDP_18D8
		bgt		cr5, FDP_1A64
		cmpwi	r18, 64
		cmpwi	cr1, r18, 0
		cmpwi	cr6, r18, 4
		bso		cr5, FDP_1938
		bge		FDP_17F8
		crclr	cr0_LT
		beq		cr1, FDP_1734
		beq		cr6, FDP_1740
		cmpwi	cr1, r18, 20
		cmpwi	cr6, r18, 24
		beq		cr1, FDP_1750
		beq		cr6, FDP_17C8
		cmpwi	cr1, r18, 32
		cmpwi	cr6, r18, 36
		beq		cr1, FDP_17D4
		beq		cr6, FDP_17E8
		cmpwi	cr6, r18, 16
		lwzx	r18, SP, r18
		lwzx	r19, SP, r19
		add.	r21, r18, r19
		beq		cr6, FDP_1750
		bne		cr3, FDP_1338
		b		FDP_1B54


FDP_1734
		bge		cr2, FDP_1338
		lwz		r21, 0(r22)
		b		FDP_1478


FDP_1740
		bne		cr3, FDP_1338
		mtcrf	%10000000, r13
		dc.l	0x7EA102A7		; mfxer r21 | bit 31
		b		FDP_1478


FDP_1750
		ble		cr2, FDP_1338
		lwz		r22, -0x0004(SP)


FDP_1758
		mftbu	r20
		mftb	r21
		mftbu	r23
		cmplw	cr1, r23, r20
		bne-	cr1, FDP_1758
		lwz		r23, 0x05BC(r22)
		lbz		r18, 0x05B8(r22)
		lbz		r19, 0x05BB(r22)
		mullw	r22, r20, r23
		mulhwu	r24, r21, r23
		add		r22, r22, r24
		bne		cr6, FDP_17A8
		cmplw	cr1, r22, r24
		srw		r22, r22, r19
		mulhwu	r21, r20, r23
		bge+	cr1, FDP_179C
		addi	r21, r21, 1


FDP_179c
		slw		r21, r21, r18
		add		r21, r21, r22
		b		FDP_1478


FDP_17a8
		mullw	r21, r21, r23
		srw		r21, r21, r19
		slw		r22, r22, r18
		add		r21, r21, r22
		lis		r23, 15258
		ori		r23, r23, 0xCA00
		mulhwu	r21, r21, r23
		b		FDP_1478


FDP_17c8
		bne		cr2, FDP_1338
		mfdec	r21			; DEC = 22
		b		FDP_1478


FDP_17d4
		bne		cr3, FDP_1338
		mtcrf	%10000000, r13
		mtlr	r12			; LR = 8
		dc.l	0x7EA802A7		; mflr r21 | bit 31
		b		FDP_1478


FDP_17e8
		bne		cr3, FDP_1338
		mtcrf	%10000000, r13
		dc.l	0x7EA902A7		; mfctr r21 | bit 31
		b		FDP_1478


FDP_17f8
		lwz		r23, -0x0004(SP)
		mtcrf	%10000000, r13
		lwz		r23, 0x05C0(r23)
		extrwi	r19, r27, 10, 11
		cmplwi	cr1, r19, 0x03E8
		beq		cr1, FDP_187C
		clrlslwi	r23, r23, 28, 20
		bne		cr4, FDP_1344
		mtcrf	32, r23
		cmplwi	cr1, r19, 0x031D
		beq		cr1, FDP_1898
		cmplwi	cr1, r19, 0x033D
		beq		cr1, FDP_18A0
		cmplwi	cr1, r19, 0x035D
		beq		cr1, FDP_18A8
		cmplwi	cr1, r19, 0x037D
		beq		cr1, FDP_18B0
		bgt		cr2, FDP_1848
		cmplwi	cr1, r19, 0x03FD
		beq		cr1, FDP_18D0


FDP_1848
		bne		cr2, FDP_1344
		cmplwi	cr1, r19, 0x039D
		beq		cr1, FDP_18B8
		cmplwi	cr1, r19, 0x03BD
		beq		cr1, FDP_18C0
		cmplwi	cr1, r19, 0x03DD
		beq		cr1, FDP_18C8
		bge		cr2, FDP_1344
		cmplwi	cr1, r19, 0x021D
		beq		cr1, FDP_1888
		cmplwi	cr1, r19, 0x02FD
		beq		cr1, FDP_1890
		b		FDP_1344


FDP_187c
		ble		cr4, FDP_1344
		dc.l	0x7EBF42A7		; mfpvr r21 | bit 31
		b		FDP_1478


FDP_1888
		dc.l	0x7EB0EAA7		; mfspr	r21, MMCR2 | bit 31
		b		FDP_1478


FDP_1890
		dc.l	0x7EB7EAA7		; mfspr	r21, BAMR | bit 31
		b		FDP_1478


FDP_1898
		dc.l	0x7EB8EAA7		; mfspr	r21, MMCR0 | bit 31
		b		FDP_1478


FDP_18a0
		dc.l	0x7EB9EAA7		; mfspr	r21, PMC1 | bit 31
		b		FDP_1478


FDP_18a8
		dc.l	0x7EBAEAA7		; mfspr	r21, PMC2 | bit 31
		b		FDP_1478


FDP_18b0
		dc.l	0x7EBBEAA7		; mfspr	r21, SIA | bit 31
		b		FDP_1478


FDP_18b8
		dc.l	0x7EBCEAA7		; mfspr	r21, MMCR1 | bit 31
		b		FDP_1478


FDP_18c0
		dc.l	0x7EBDEAA7		; mfspr	r21, PMC3 | bit 31
		b		FDP_1478


FDP_18c8
		dc.l	0x7EBEEAA7		; mfspr	r21, PMC4 | bit 31
		b		FDP_1478


FDP_18d0
		dc.l	0x7EBFEAA7		; mfspr	r21, SDA | bit 31
		b		FDP_1478


FDP_18d8
		extrwi	r23, r27, 10, 11
		cmplwi	cr1, r23, 0x0188
		cmplwi	cr6, r23, 0x01A8
		cror	cr0_EQ, cr1_EQ, cr6_EQ
		bne		FDP_1338


FDP_18ec
		DIALECT	POWER
		mfrtcu	r20			; RTCU = 4
		mfrtcl	r21			; RTCL = 5
		mfrtcu	r23			; RTCU = 4
		DIALECT	PowerPC

		xor.	r23, r23, r20
		lis		r23, 15258
		ori		r23, r23, 0xCA00
		bne-	FDP_18EC
		mfspr	r24, MQ			; 0
		crset	cr3_SO
		mullw	r19, r20, r23
		mtspr	MQ, r24			; 0
		add		r21, r21, r19
		beq		cr1, FDP_1484
		cmplw	r21, r19
		mulhwu	r21, r20, r23
		mtspr	MQ, r24			; 0
		bge		FDP_1484
		addi	r21, r21, 1
		b		FDP_1484


FDP_1938
		lwzx	r17, SP, r17
		bge		FDP_1998
		mr.		r17, r17
		beq		cr1, FDP_1964
		bne		cr3, FDP_1338
		beq		cr6, FDP_1970
		cmpwi	cr1, r18, 32
		cmpwi	cr6, r18, 36
		beq		cr1, FDP_197C
		beq		cr6, FDP_198C
		b		FDP_1B54


FDP_1964
		bge		cr2, FDP_1338
		stw		r17, 0(r22)
		b		FDP_1B54


FDP_1970
		mtcrf	%10000000, r13
		dc.l	0x7E2103A7		; mtxer r17 | bit 31
		b		FDP_1B54


FDP_197c
		mtcrf	%10000000, r13
		mr		r12, r17
		dc.l	0x7E2803A7		; mtlr r17 | bit 31
		b		FDP_1B54


FDP_198c
		mtcrf	%10000000, r13
		dc.l	0x7E2903A7		; mtctr r17 | bit 31
		b		FDP_1B54


FDP_1998
		lwz		r23, -0x0004(SP)
		bne		cr4, FDP_1344
		lwz		r23, 0x05C0(r23)
		mtcrf	%10000000, r13
		clrlslwi	r23, r23, 28, 20
		extrwi	r19, r27, 10, 11
		mtcrf	32, r23
		cmplwi	cr1, r19, 0x031D
		beq		cr1, FDP_1A24
		cmplwi	cr1, r19, 0x033D
		beq		cr1, FDP_1A2C
		cmplwi	cr1, r19, 0x035D
		beq		cr1, FDP_1A34
		cmplwi	cr1, r19, 0x037D
		beq		cr1, FDP_1A3C
		bgt		cr2, FDP_19E0
		cmplwi	cr1, r19, 0x03FD
		beq		cr1, FDP_1A5C


FDP_19e0
		bne		cr2, FDP_1344
		cmplwi	cr1, r19, 0x039D
		beq		cr1, FDP_1A44
		cmplwi	cr1, r19, 0x03BD
		beq		cr1, FDP_1A4C
		cmplwi	cr1, r19, 0x03DD
		beq		cr1, FDP_1A54
		bge		cr2, FDP_1344
		cmplwi	cr1, r19, 0x021D
		beq		cr1, FDP_1A14
		cmplwi	cr1, r19, 0x02FD
		beq		cr1, FDP_1A1C
		b		FDP_1344


FDP_1a14
		dc.l	0x7E30EBA7		; mtspr r17, MMCR2 | bit 31
		b		FDP_1B54


FDP_1a1c
		dc.l	0x7E37EBA7		; mtspr r17, BAMR | bit 31
		b		FDP_1B54


FDP_1a24
		dc.l	0x7E38EBA7		; mtspr r17, MMCR0 | bit 31
		b		FDP_1B54


FDP_1a2c
		dc.l	0x7E39EBA7		; mtspr r17, PMC1 | bit 31
		b		FDP_1B54


FDP_1a34
		dc.l	0x7E3AEBA7		; mtspr r17, PMC2 | bit 31
		b		FDP_1B54


FDP_1a3c
		dc.l	0x7E3BEBA7		; mtspr r17, SIA | bit 31
		b		FDP_1B54


FDP_1a44
		dc.l	0x7E3CEBA7		; mtspr r17, MMCR1 | bit 31
		b		FDP_1B54


FDP_1a4c
		dc.l	0x7E3DEBA7		; mtspr r17, PMC3 | bit 31
		b		FDP_1B54


FDP_1a54
		dc.l	0x7E3EEBA7		; mtspr r17, PMC4 | bit 31
		b		FDP_1B54


FDP_1a5c
		dc.l	0x7E3FEBA7		; mtspr r17, SDA | bit 31
		b		FDP_1B54


FDP_1a64
		lwz		r23, -0x0004(SP)
		bge		cr3, FDP_1338
		extrwi.	r18, r27, 4, 12
		rlwinm	r21, r27, 16, 28, 30
		cmpwi	cr1, r21, 10
		addi	r18, r18, 6808
		lbzx	r18, r25, r18
		addi	r21, r23, 3872
		beq		cr1, FDP_1A90
		lhzx	r21, r21, r18
		b		FDP_1478


FDP_1a90
		lwzx	r21, r21, r18
		b		FDP_1478

		DIALECT	POWER
		dozi	SP, r4, 9252
		dozi	r17, r8, 10784
		dc.l	0x2c2e1814		; cmpdi r14, 6164
		DIALECT	PowerPC

		subfic	r17, r4, 9252
		lwzx	r19, SP, r19
		clrlwi	r19, r19, 27
		bso		cr5, FDP_1B1C
		bns		cr2, FDP_1338
		lwzx	r17, SP, r17
		lis		r23, -32768
		lwzx	r21, SP, r18
		srw		r23, r23, r19
		srw		r17, r17, r19
		b		FDP_1C08
		bgt		cr6, FDP_1B18
		lwzx	r19, SP, r19
		clrlwi	r19, r19, 26
		bge		cr6, FDP_1B1C
		cmpwi	r19, 31
		crnot	cr5_SO, cr5_SO
		ble		FDP_1B1C
		bge		cr2, FDP_1338
		lwz		r20, 0(r22)
		li		r23, -1
		clrlwi	r19, r19, 27
		bgt		cr5, FDP_1B0C
		slw		r23, r23, r19
		and.	r21, r20, r23
		b		FDP_1B50


FDP_1b0c
		srw		r23, r23, r19
		and.	r21, r20, r23
		b		FDP_1B50


FDP_1b18
		extrwi	r19, r27, 5, 16


FDP_1b1c
		bge		cr2, FDP_1338
		lwzx	r17, SP, r17
		bgt		cr5, FDP_1B64
		slw.	r21, r17, r19
		rotlw	r20, r17, r19
		bge		cr6, FDP_1B4C
		li		r23, -1
		slw		r23, r23, r19


FDP_1b3c
		lwz		r19, 0(r22)
		andc	r23, r19, r23
		or.		r21, r21, r23
		bns		cr5, FDP_1B50


FDP_1b4c
		stw		r20, 0(r22)


FDP_1b50
		stwx	r21, r1, r18


FDP_1b54
		bns		cr7, FDP_0da0
		mfcr	r23
		rlwimi	r13, r23,  0,  0,  3
		b		FDP_0da0


FDP_1b64
		neg		r20, r19
		rotlw	r20, r17, r20
		beq		cr5, FDP_1B84
		srw.	r21, r17, r19
		bge		cr6, FDP_1B4C
		li		r23, -1
		srw		r23, r23, r19
		b		FDP_1B3C


FDP_1b84
		sraw.	r21, r17, r19
		b		FDP_1B4C
		bns		cr2, FDP_1338
		lwzx	r19, SP, r19
		lwzx	r17, SP, r17
		bgt		cr5, FDP_1BBC
		li		r21, -1
		sub		r19, r19, r17
		not		r19, r19
		clrlwi	r19, r19, 27
		neg		r17, r17
		slw		r21, r21, r19
		rotlw.	r21, r21, r17
		b		FDP_1B50


FDP_1bbc
		lwzx	r21, SP, r18
		and		r17, r17, r19
		andc	r21, r21, r19
		or.		r21, r21, r17
		b		FDP_1B50


FDP_1bd0
		bns		cr2, FDP_1338
		lwzx	r17, r1, r17
		rlwinm	r20, r27, 26, 27, 31
		lwzx	r19, r1, r19
		rlwinm	r21, r27, 31, 27, 31
		li		r23, -0x01
		subf	r21, r20, r21
		not		r21, r21
		clrlwi	r21, r21,  0x1b
		neg		r20, r20
		slw		r23, r23, r21
		lwzx	r21, r1, r18
		rotlw	r23, r23, r20
		rotlw	r17, r17, r19


FDP_1c08
		and		r17, r17, r23
		andc	r21, r21, r23
		or.		r21, r21, r17
		b		FDP_1b50


FDP_1c18
		ble		cr3, FDP_1338
		b		major_0x03324
		bgt		cr6, FDP_1C18
		bge		cr4, FDP_1338
		b		major_0x03324



		align	5

FDP_1c40	;	OUTSIDE REFERER
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

		mfsprg	r1, 0
		lwz		r8,  0x0104(r6)
		stw		r8,  0x0000(r1)
		stw		r2,  0x0008(r1)
		stw		r3,  0x000c(r1)
		stw		r4,  0x0010(r1)
		stw		r5,  0x0014(r1)
		stmw	r14,  0x0038(r1)
		mr		r16, r7
		lwz		r7,  0x013c(r6)
		stw		r7,  0x001c(r1)
		lwz		r8,  0x0144(r6)
		stw		r8,  0x0020(r1)
		lwz		r9,  0x014c(r6)
		stw		r9,  0x0024(r1)
		lwz		r23,  0x0154(r6)
		stw		r23,  0x0028(r1)
		lwz		r23,  0x015c(r6)
		stw		r23,  0x002c(r1)
		lwz		r23,  0x0164(r6)
		stw		r23,  0x0030(r1)
		lwz		r23,  0x016c(r6)
		stw		r23,  0x0034(r1)
		lwz		r1, -0x0004(r1)
		addi	r22, r6,  0xc4
		mfsprg	r24, 3
		addi	r23, r1,  0x4e0
		mfmsr	r14
		oris	r14, r14,  0x200
		ori		r15, r14,  0x10
		mtsprg	3, r23
		mtmsr	r15
		isync
		lwz		r27,  0x0000(r10)
		mtmsr	r14
		isync
		mtsprg	3, r24
		lwz		r24,  0x00d8(r6)
		addi	r24, r24,  0x00
		li		r8,  0x00
		stvx	v0, r24, r8
		li		r9,  0x10
		stvx	v1, r24, r9
		li		r8,  0x20
		stvx	v2, r24, r8
		li		r9,  0x30
		stvx	v3, r24, r9
		li		r8,  0x40
		stvx	v4, r24, r8
		li		r9,  0x50
		stvx	v5, r24, r9
		li		r8,  0x60
		stvx	v6, r24, r8
		li		r9,  0x70
		stvx	v7, r24, r9
		li		r8,  0x80
		stvx	v8, r24, r8
		li		r9,  0x90
		stvx	v9, r24, r9
		li		r8, 160
		stvx	v10, r24, r8
		li		r9,  0xb0
		stvx	v11, r24, r9
		li		r8,  0xc0
		stvx	v12, r24, r8
		li		r9,  0xd0
		stvx	v13, r24, r9
		li		r8,  0xe0
		stvx	v14, r24, r8
		li		r9, 240
		stvx	v15, r24, r9
		li		r8,  0x100
		stvx	v16, r24, r8
		li		r9,  0x110
		stvx	v17, r24, r9
		li		r8,  0x120
		stvx	v18, r24, r8
		li		r9,  0x130
		stvx	v19, r24, r9
		li		r8, 320
		stvx	v20, r24, r8
		li		r9,  0x150
		stvx	v21, r24, r9
		li		r8,  0x160
		stvx	v22, r24, r8
		li		r9,  0x170
		stvx	v23, r24, r9
		li		r8,  0x180
		stvx	v24, r24, r8
		li		r9, 400
		stvx	v25, r24, r9
		li		r8,  0x1a0
		stvx	v26, r24, r8
		li		r9,  0x1b0
		stvx	v27, r24, r9
		li		r8,  0x1c0
		stvx	v28, r24, r8
		li		r9,  0x1d0
		stvx	v29, r24, r9
		li		r8, 480
		stvx	v30, r24, r8
		li		r9,  0x1f0
		stvx	v31, r24, r9
		lwz		r23,  0x0ed8(r1)
		lwz		r25,  0x0650(r1)
		addi	r23, r23,  0x01
		stw		r23,  0x0ed8(r1)
		rlwinm.	r8, r27, 26,  0,  0
		rlwinm	r9, r27, 24, 30, 31
		cmpwi	cr1, r9,  0x03
		cmpwi	cr2, r9,  0x00
		rlwinm	r17, r27, 15, 23, 27
		rlwinm	r18, r27, 20, 23, 27
		rlwinm	r19, r27, 25, 23, 27
		blt		FDP_1c40_0x398
		beq		cr2, FDP_1c40_0x43c
		bgt		cr1, FDP_1c40_0x278
		lvx		v3, r24, r19
		vspltisw	v31,  0x00
		vspltisw	v29,  0x01
		vcfux	v29, v29,  0x00
		vspltisw	v30, -0x01
		vspltisw	v22,  0x09
		vsrw	v28, v30, v22
		vslw	v27, v30, v30
		vnor	v26, v28, v27
		vsraw	v24, v3, v30
		vand	v23, v3, v28
		vcmpequw	v23, v23, v31
		vand	v22, v3, v26
		vcmpequw	v22, v22, v31
		vandc	v25, v22, v23
		lwz		r9,  0x064c(r1)
		llabel	r8, blergh
		add		r9, r9, r8
		rlwinm	r8, r27, 28, 26, 29
		add		r9, r9, r8
		mtlr	r9
		blr

blergh
		b		panic
		b		panic
		b		panic
		b		panic
		b		major_0x07ac0_0x14c
		b		major_0x07ac0_0x100
		b		major_0x07ac0_0x24c
		b		major_0x07ac0_0x220
		b		FDP_1c40_0x4d0
		b		FDP_1c40_0x4e0
		b		FDP_1c40_0x4f0
		b		FDP_1c40_0x500
		b		panic
		b		panic
		b		FDP_1c40_0x514
		b		major_0x07980_0x100

FDP_1c40_0x274	;	OUTSIDE REFERER
		stvx	v1, r24, r17

FDP_1c40_0x278
		li		r8,  0x00
		lvx		v0, r24, r8
		li		r8,  0x10
		lvx		v1, r24, r8
		li		r8,  0x20
		lvx		v2, r24, r8
		li		r8,  0x30
		lvx		v3, r24, r8
		li		r8,  0x40
		lvx		v4, r24, r8
		li		r8,  0x50
		lvx		v5, r24, r8
		li		r8,  0x60
		lvx		v6, r24, r8
		li		r8,  0x70
		lvx		v7, r24, r8
		li		r8,  0x80
		lvx		v8, r24, r8
		li		r8,  0x90
		lvx		v9, r24, r8
		li		r8, 160
		lvx		v10, r24, r8
		li		r8,  0xb0
		lvx		v11, r24, r8
		li		r8,  0xc0
		lvx		v12, r24, r8
		li		r8,  0xd0
		lvx		v13, r24, r8
		li		r8,  0xe0
		lvx		v14, r24, r8
		li		r8, 240
		lvx		v15, r24, r8
		li		r8,  0x100
		lvx		v16, r24, r8
		li		r8,  0x110
		lvx		v17, r24, r8
		li		r8,  0x120
		lvx		v18, r24, r8
		li		r8,  0x130
		lvx		v19, r24, r8
		li		r8, 320
		lvx		v20, r24, r8
		li		r8,  0x150
		lvx		v21, r24, r8
		li		r8,  0x160
		lvx		v22, r24, r8
		li		r8,  0x170
		lvx		v23, r24, r8
		li		r8,  0x180
		lvx		v24, r24, r8
		li		r8, 400
		lvx		v25, r24, r8
		li		r8,  0x1a0
		lvx		v26, r24, r8
		li		r8,  0x1b0
		lvx		v27, r24, r8
		li		r8,  0x1c0
		lvx		v28, r24, r8
		li		r8,  0x1d0
		lvx		v29, r24, r8
		li		r8, 480
		lvx		v30, r24, r8
		li		r8,  0x1f0
		lvx		v31, r24, r8
		andi.	r23, r16,  0x20
		addi	r10, r10,  0x04
		mfsprg	r1, 0
		mtspr	srr0, r10
		mtspr	srr1, r11
		bne		FDP_0E30
		mtlr	r12
		b		FDP_0DC8

FDP_1c40_0x398
		rlwinm	r22, r27, 30, 23, 27
		mfmsr	r14
		ori		r15, r14,  0x2000
		mtmsr	r15
		isync
		rlwinm.	r8, r11,  0, 18, 18
		beq		FDP_1c40_0x3cc
		stfd	f0,  0x0200(r6)
		mffs	f0
		stfd	f1,  0x0208(r6)
		stfd	f2,  0x0210(r6)
		stfd	f3,  0x0218(r6)
		stfd	f0,  0x00e0(r6)

FDP_1c40_0x3cc
		dc.l	0xff80010c
		crmove	30, 2
		rlwinm.	r9, r27, 31,  0,  0
		li		r8,  0x03
		crmove	26, 0

FDP_1c40_0x3e0
		lfsx	f0, r24, r18
		addic.	r8, r8, -0x01
		lfsx	f1, r24, r19
		lfsx	f2, r24, r22
		bne		cr6, FDP_1c40_0x408
		fnmsubs	f3, f0, f2, f1
		stfsx	f3, r24, r17
		addi	r24, r24,  0x04
		bge		FDP_1c40_0x3e0
		b		FDP_1c40_0x418

FDP_1c40_0x408
		fmadds	f3, f0, f2, f1
		stfsx	f3, r24, r17
		addi	r24, r24,  0x04
		bge		FDP_1c40_0x3e0

FDP_1c40_0x418
		addi	r24, r24, -0x10
		beq		cr7, FDP_1c40_0x278
		lfd		f0,  0x00e0(r6)
		mtfsf	 0xff, f0
		lfd		f0,  0x0200(r6)
		lfd		f1,  0x0208(r6)
		lfd		f2,  0x0210(r6)
		lfd		f3,  0x0218(r6)
		b		FDP_1c40_0x278

FDP_1c40_0x43c
		mfmsr	r14
		ori		r15, r14,  0x2000
		mtmsr	r15
		isync
		rlwinm.	r8, r11,  0, 18, 18
		beq		FDP_1c40_0x468
		stfd	f0,  0x0200(r6)
		mffs	f0
		stfd	f1,  0x0208(r6)
		stfd	f3,  0x0218(r6)
		stfd	f0,  0x00e0(r6)

FDP_1c40_0x468
		dc.l	0xff80010c
		crmove	30, 2
		rlwinm.	r9, r27, 25,  0,  0
		li		r8,  0x03
		crmove	26, 0

FDP_1c40_0x47c
		lfsx	f0, r24, r18
		addic.	r8, r8, -0x01
		lfsx	f1, r24, r19
		bne		cr6, FDP_1c40_0x4a0
		fsubs	f3, f0, f1
		stfsx	f3, r24, r17
		addi	r24, r24,  0x04
		bge		FDP_1c40_0x47c
		b		FDP_1c40_0x4b0

FDP_1c40_0x4a0
		fadds	f3, f0, f1
		stfsx	f3, r24, r17
		addi	r24, r24,  0x04
		bge		FDP_1c40_0x47c

FDP_1c40_0x4b0
		addi	r24, r24, -0x10
		beq		cr7, FDP_1c40_0x278
		lfd		f0,  0x00e0(r6)
		mtfsf	 0xff, f0
		lfd		f0,  0x0200(r6)
		lfd		f1,  0x0208(r6)
		lfd		f3,  0x0218(r6)
		b		FDP_1c40_0x278

FDP_1c40_0x4d0
		vsel	v22, v31, v27, v24
		vsel	v23, v3, v22, v25
		vrfin	v1, v23
		b		FDP_1c40_0x274

FDP_1c40_0x4e0
		vsel	v22, v31, v27, v24
		vsel	v23, v3, v22, v25
		vrfiz	v1, v23
		b		FDP_1c40_0x274

FDP_1c40_0x4f0
		vsel	v22, v29, v27, v24
		vsel	v23, v3, v22, v25
		vrfip	v1, v23
		b		FDP_1c40_0x274

FDP_1c40_0x500
		vor		v29, v29, v27
		vsel	v22, v31, v29, v24
		vsel	v23, v3, v22, v25
		vrfim	v1, v23
		b		FDP_1c40_0x274

FDP_1c40_0x514
		vsel	v23, v3, v31, v25
		lwz		r9,  0x064c(r1)
		llabel	r8, FDP_2180
		add		r8, r8, r9
		srwi	r9, r18,  1
		add		r8, r8, r9
		mtlr	r8
		blr



		align	6

FDP_2180
		dc.l	0x1020BB8A
		b		FDP_1c40_0x274
		dc.l	0x1021BB8A
		b		FDP_1c40_0x274
		dc.l	0x1022BB8A
		b		FDP_1c40_0x274
		dc.l	0x1023BB8A
		b		FDP_1c40_0x274
		dc.l	0x1024BB8A
		b		FDP_1c40_0x274
		dc.l	0x1025BB8A
		b		FDP_1c40_0x274
		dc.l	0x1026BB8A
		b		FDP_1c40_0x274
		dc.l	0x1027BB8A
		b		FDP_1c40_0x274
		dc.l	0x1028BB8A
		b		FDP_1c40_0x274
		dc.l	0x1029BB8A
		b		FDP_1c40_0x274
		dc.l	0x102ABB8A
		b		FDP_1c40_0x274
		dc.l	0x102BBB8A
		b		FDP_1c40_0x274
		dc.l	0x102CBB8A
		b		FDP_1c40_0x274
		dc.l	0x102DBB8A
		b		FDP_1c40_0x274
		dc.l	0x102EBB8A
		b		FDP_1c40_0x274
		dc.l	0x102FBB8A
		b		FDP_1c40_0x274
		dc.l	0x1030BB8A
		b		FDP_1c40_0x274
		dc.l	0x1031BB8A
		b		FDP_1c40_0x274
		dc.l	0x1032BB8A
		b		FDP_1c40_0x274
		dc.l	0x1033BB8A
		b		FDP_1c40_0x274
		dc.l	0x1034BB8A
		b		FDP_1c40_0x274
		dc.l	0x1035BB8A
		b		FDP_1c40_0x274
		dc.l	0x1036BB8A
		b		FDP_1c40_0x274
		dc.l	0x1037BB8A
		b		FDP_1c40_0x274
		dc.l	0x1038BB8A
		b		FDP_1c40_0x274
		dc.l	0x1039BB8A
		b		FDP_1c40_0x274
		dc.l	0x103ABB8A
		b		FDP_1c40_0x274
		dc.l	0x103BBB8A
		b		FDP_1c40_0x274
		dc.l	0x103CBB8A
		b		FDP_1c40_0x274
		dc.l	0x103DBB8A
		b		FDP_1c40_0x274
		dc.l	0x103EBB8A
		b		FDP_1c40_0x274
		dc.l	0x103FBB8A
		b		FDP_1c40_0x274

major_0x07980_0x100	;	OUTSIDE REFERER
		vsel	v23, v3, v31, v25
		lwz		r9,  0x064c(r1)
		llabel	r8, FDP_22c0
		add		r8, r8, r9
		srwi	r9, r18,  1
		add		r8, r8, r9
		mtlr	r8
		blr



		align	6

FDP_22c0
		dc.l	0x1020BBCA
		b		FDP_1c40_0x274
		dc.l	0x1021BBCA
		b		FDP_1c40_0x274
		dc.l	0x1022BBCA
		b		FDP_1c40_0x274
		dc.l	0x1023BBCA
		b		FDP_1c40_0x274
		dc.l	0x1024BBCA
		b		FDP_1c40_0x274
		dc.l	0x1025BBCA
		b		FDP_1c40_0x274
		dc.l	0x1026BBCA
		b		FDP_1c40_0x274
		dc.l	0x1027BBCA
		b		FDP_1c40_0x274
		dc.l	0x1028BBCA
		b		FDP_1c40_0x274
		dc.l	0x1029BBCA
		b		FDP_1c40_0x274
		dc.l	0x102ABBCA
		b		FDP_1c40_0x274
		dc.l	0x102BBBCA
		b		FDP_1c40_0x274
		dc.l	0x102CBBCA
		b		FDP_1c40_0x274
		dc.l	0x102DBBCA
		b		FDP_1c40_0x274
		dc.l	0x102EBBCA
		b		FDP_1c40_0x274
		dc.l	0x102FBBCA
		b		FDP_1c40_0x274
		dc.l	0x1030BBCA
		b		FDP_1c40_0x274
		dc.l	0x1031BBCA
		b		FDP_1c40_0x274
		dc.l	0x1032BBCA
		b		FDP_1c40_0x274
		dc.l	0x1033BBCA
		b		FDP_1c40_0x274
		dc.l	0x1034BBCA
		b		FDP_1c40_0x274
		dc.l	0x1035BBCA
		b		FDP_1c40_0x274
		dc.l	0x1036BBCA
		b		FDP_1c40_0x274
		dc.l	0x1037BBCA
		b		FDP_1c40_0x274
		dc.l	0x1038BBCA
		b		FDP_1c40_0x274
		dc.l	0x1039BBCA
		b		FDP_1c40_0x274
		dc.l	0x103ABBCA
		b		FDP_1c40_0x274
		dc.l	0x103BBBCA
		b		FDP_1c40_0x274
		dc.l	0x103CBBCA
		b		FDP_1c40_0x274
		dc.l	0x103DBBCA
		b		FDP_1c40_0x274
		dc.l	0x103EBBCA
		b		FDP_1c40_0x274
		dc.l	0x103FBBCA
		b		FDP_1c40_0x274

major_0x07ac0_0x100	;	OUTSIDE REFERER
		bl		major_0x07d80_0x20
		vspltisw	v19,  0x01
		vadduwm	v22, v22, v19
		vspltisw	v23, -0x07
		vsrw	v21, v23, v23
		vsubuwm	v23, v21, v22
		vspltisw	v21, -0x09
		vslw	v23, v23, v21
		vrsqrtefp	v19, v23
		vslw	v20, v3, v22
		vor		v23, v29, v27
		vsel	v23, v31, v23, v24
		vsel	v21, v3, v23, v25
		vandc	v25, v25, v24
		vrsqrtefp	v20, v20
		vrsqrtefp	v21, v21
		vmaddfp	v1, v20, v19, v27
		vsel	v1, v21, v1, v25
		b		FDP_1c40_0x274

major_0x07ac0_0x14c	;	OUTSIDE REFERER
		bl		major_0x07d80_0x20
		vspltisw	v19,  0x01
		vadduwm	v22, v22, v19
		vslw	v20, v3, v22
		vsel	v20, v31, v20, v25
		vrefp	v20, v20
		vspltisw	v21, -0x09
		vandc	v23, v20, v27
		vsrw	v23, v23, v21
		mfvscr	v29
		vsrw	v19, v30, v19
		vsrw	v19, v19, v21
		vaddubs	v23, v22, v23
		mtvscr	v29
		vcmpequw	v22, v23, v19
		vslw	v23, v23, v21
		vsel	v23, v20, v23, v26
		vand	v22, v22, v28
		vsel	v23, v23, v31, v22
		vsel	v20, v31, v27, v24
		vsel	v1, v23, v30, v20
		vspltisw	v19,  0x01
		vslw	v22, v3, v19
		vspltisw	v23, -0x04
		vsraw	v22, v22, v21
		vsraw	v22, v22, v19
		vcmpgtuw	v23, v22, v23
		vcmpequw	v19, v22, v30
		vandc	v23, v23, v19
		vspltisw	v19,  0x02
		vsubuwm	v22, v22, v19
		vslw	v22, v22, v21
		vsel	v22, v3, v22, v26
		vsel	v22, v31, v22, v23
		vrefp	v22, v22
		vspltisw	v19,  0x01
		vandc	v22, v22, v27
		vslw	v29, v19, v21
		vor		v28, v28, v29
		vcmpgtuw	v28, v22, v28
		vsrw	v29, v29, v19
		vsel	v22, v22, v31, v26
		vsrw	v22, v22, v19
		vor		v22, v22, v29
		vsel	v19, v19, v31, v28
		vsrw	v22, v22, v19
		vor		v22, v22, v20
		vsel	v1, v1, v22, v23
		vor		v25, v25, v23
		vsel	v23, v3, v31, v25
		vrefp	v23, v23
		vsel	v1, v23, v1, v25
		b		FDP_1c40_0x274

major_0x07ac0_0x220	;	OUTSIDE REFERER
		bl		major_0x07d80_0x20
		vspltisw	v19,  0x01
		vadduwm	v22, v22, v19
		vslw	v20, v3, v22
		vsel	v23, v3, v20, v25
		vlogefp	v23, v23
		vsubsws	v22, v31, v22
		vcfsx	v22, v22,  0x00
		vaddfp	v1, v22, v23
		vsel	v1, v23, v1, v25
		b		FDP_1c40_0x274

major_0x07ac0_0x24c	;	OUTSIDE REFERER
		lwz		r9,  0x064c(r1)
		llabel	r8, FDP_2590
		add		r8, r8, r9
		lvx		v23, 0, r8
		vspltw	v21, v23,  0x03
		vspltw	v20, v23,  0x00
		vcmpgefp	v21, v3, v21
		vcmpgtfp	v20, v3, v20
		vspltw	v19, v23,  0x02
		vandc	v22, v21, v20
		vsel	v29, v31, v3, v22
		vaddfp	v29, v29, v19
		vsel	v19, v3, v29, v22
		vexptefp	v1, v19
		vspltisw	v25, -0x09
		vspltw	v23, v23,  0x01
		vsrw	v19, v1, v25
		vspltisw	v29,  0x01
		vsubuwm	v19, v23, v19
		vslw	v26, v29, v25
		vsel	v28, v31, v1, v28
		vor		v28, v28, v26
		vsrw	v28, v28, v19
		vsel	v1, v1, v28, v22
		b		FDP_1c40_0x274



		align	5

FDP_2580
		dc.l	0x17030202
		dc.l	0x01010101
		dc.l	0x00000000
		dc.l	0x00000000

FDP_2590
		dc.l	0xc2fc0004
		dc.l	0x00000041
		dc.l	0x42800000
		dc.l	0xc3150001

major_0x07d80_0x20	;	OUTSIDE REFERER
		vspltisw	v23, 9
		vslw		v19, v3, v23
		lwz			r9,  0x064c(r1)
		llabel		r8, FDP_2580
		add			r8, r8, r9
		lvx			v23, 0, r8
		vperm		v22, v23, v23, v19
		vspltisw	v21, 4
		vsrw		v21, v19, v21
		vperm		v21, v23, v23, v21
		li			r8, 0
		lvsl		v20, r8, r8
		vspltisw	v23, 3
		vslw		v20, v20, v23
		vspltisb	v23, 4
		vaddubm		v19, v20, v23
		vspltw		v20, v20, 0
		vspltw		v19, v19, 0
		vaddubm		v21, v21, v20
		vaddubm		v22, v22, v19
		vminub		v22, v22, v21
		vsldoi		v21, v22, v22, 2
		vminub		v22, v22, v21
		vsldoi		v21, v22, v22,1
		vminub		v22, v22, v21
		vspltisw	v21, -8
		vsrw		v22, v22, v21
		blr



;	No clue what this does

		align	5

FDP_2620
		dc.l	0x7C00B8CE
		b		FDP_011C
		dc.l	0x7C20B8CE
		b		FDP_011C
		dc.l	0x7C40B8CE
		b		FDP_011C
		dc.l	0x7C60B8CE
		b		FDP_011C
		dc.l	0x7C80B8CE
		b		FDP_011C
		dc.l	0x7CA0B8CE
		b		FDP_011C
		dc.l	0x7CC0B8CE
		b		FDP_011C
		dc.l	0x7CE0B8CE
		b		FDP_011C
		dc.l	0x7D00B8CE
		b		FDP_011C
		dc.l	0x7D20B8CE
		b		FDP_011C
		dc.l	0x7D40B8CE
		b		FDP_011C
		dc.l	0x7D60B8CE
		b		FDP_011C
		dc.l	0x7D80B8CE
		b		FDP_011C
		dc.l	0x7DA0B8CE
		b		FDP_011C
		dc.l	0x7DC0B8CE
		b		FDP_011C
		dc.l	0x7DE0B8CE
		b		FDP_011C
		dc.l	0x7E00B8CE
		b		FDP_011C
		dc.l	0x7E20B8CE
		b		FDP_011C
		dc.l	0x7E40B8CE
		b		FDP_011C
		dc.l	0x7E60B8CE
		b		FDP_011C
		dc.l	0x7E80B8CE
		b		FDP_011C
		dc.l	0x7EA0B8CE
		b		FDP_011C
		dc.l	0x7EC0B8CE
		b		FDP_011C
		dc.l	0x7EE0B8CE
		b		FDP_011C
		dc.l	0x7F00B8CE
		b		FDP_011C
		dc.l	0x7F20B8CE
		b		FDP_011C
		dc.l	0x7F40B8CE
		b		FDP_011C
		dc.l	0x7F60B8CE
		b		FDP_011C
		dc.l	0x7F80B8CE
		b		FDP_011C
		dc.l	0x7FA0B8CE
		b		FDP_011C
		dc.l	0x7FC0B8CE
		b		FDP_011C
		dc.l	0x7FE0B8CE
		b		FDP_011C
		dc.l	0x7C00B80E
		b		FDP_0DA0
		dc.l	0x7C20B80E
		b		FDP_0DA0
		dc.l	0x7C40B80E
		b		FDP_0DA0
		dc.l	0x7C60B80E
		b		FDP_0DA0
		dc.l	0x7C80B80E
		b		FDP_0DA0
		dc.l	0x7CA0B80E
		b		FDP_0DA0
		dc.l	0x7CC0B80E
		b		FDP_0DA0
		dc.l	0x7CE0B80E
		b		FDP_0DA0
		dc.l	0x7D00B80E
		b		FDP_0DA0
		dc.l	0x7D20B80E
		b		FDP_0DA0
		dc.l	0x7D40B80E
		b		FDP_0DA0
		dc.l	0x7D60B80E
		b		FDP_0DA0
		dc.l	0x7D80B80E
		b		FDP_0DA0
		dc.l	0x7DA0B80E
		b		FDP_0DA0
		dc.l	0x7DC0B80E
		b		FDP_0DA0
		dc.l	0x7DE0B80E
		b		FDP_0DA0
		dc.l	0x7E00B80E
		b		FDP_0DA0
		dc.l	0x7E20B80E
		b		FDP_0DA0
		dc.l	0x7E40B80E
		b		FDP_0DA0
		dc.l	0x7E60B80E
		b		FDP_0DA0
		dc.l	0x7E80B80E
		b		FDP_0DA0
		dc.l	0x7EA0B80E
		b		FDP_0DA0
		dc.l	0x7EC0B80E
		b		FDP_0DA0
		dc.l	0x7EE0B80E
		b		FDP_0DA0
		dc.l	0x7F00B80E
		b		FDP_0DA0
		dc.l	0x7F20B80E
		b		FDP_0DA0
		dc.l	0x7F40B80E
		b		FDP_0DA0
		dc.l	0x7F60B80E
		b		FDP_0DA0
		dc.l	0x7F80B80E
		b		FDP_0DA0
		dc.l	0x7FA0B80E
		b		FDP_0DA0
		dc.l	0x7FC0B80E
		b		FDP_0DA0
		dc.l	0x7FE0B80E
		b		FDP_0DA0
		dc.l	0x7C00B84E
		b		FDP_0DA0
		dc.l	0x7C20B84E
		b		FDP_0DA0
		dc.l	0x7C40B84E
		b		FDP_0DA0
		dc.l	0x7C60B84E
		b		FDP_0DA0
		dc.l	0x7C80B84E
		b		FDP_0DA0
		dc.l	0x7CA0B84E
		b		FDP_0DA0
		dc.l	0x7CC0B84E
		b		FDP_0DA0
		dc.l	0x7CE0B84E
		b		FDP_0DA0
		dc.l	0x7D00B84E
		b		FDP_0DA0
		dc.l	0x7D20B84E
		b		FDP_0DA0
		dc.l	0x7D40B84E
		b		FDP_0DA0
		dc.l	0x7D60B84E
		b		FDP_0DA0
		dc.l	0x7D80B84E
		b		FDP_0DA0
		dc.l	0x7DA0B84E
		b		FDP_0DA0
		dc.l	0x7DC0B84E
		b		FDP_0DA0
		dc.l	0x7DE0B84E
		b		FDP_0DA0
		dc.l	0x7E00B84E
		b		FDP_0DA0
		dc.l	0x7E20B84E
		b		FDP_0DA0
		dc.l	0x7E40B84E
		b		FDP_0DA0
		dc.l	0x7E60B84E
		b		FDP_0DA0
		dc.l	0x7E80B84E
		b		FDP_0DA0
		dc.l	0x7EA0B84E
		b		FDP_0DA0
		dc.l	0x7EC0B84E
		b		FDP_0DA0
		dc.l	0x7EE0B84E
		b		FDP_0DA0
		dc.l	0x7F00B84E
		b		FDP_0DA0
		dc.l	0x7F20B84E
		b		FDP_0DA0
		dc.l	0x7F40B84E
		b		FDP_0DA0
		dc.l	0x7F60B84E
		b		FDP_0DA0
		dc.l	0x7F80B84E
		b		FDP_0DA0
		dc.l	0x7FA0B84E
		b		FDP_0DA0
		dc.l	0x7FC0B84E
		b		FDP_0DA0
		dc.l	0x7FE0B84E
		b		FDP_0DA0
		dc.l	0x7C00B88E
		b		FDP_0DA0
		dc.l	0x7C20B88E
		b		FDP_0DA0
		dc.l	0x7C40B88E
		b		FDP_0DA0
		dc.l	0x7C60B88E
		b		FDP_0DA0
		dc.l	0x7C80B88E
		b		FDP_0DA0
		dc.l	0x7CA0B88E
		b		FDP_0DA0
		dc.l	0x7CC0B88E
		b		FDP_0DA0
		dc.l	0x7CE0B88E
		b		FDP_0DA0
		dc.l	0x7D00B88E
		b		FDP_0DA0
		dc.l	0x7D20B88E
		b		FDP_0DA0
		dc.l	0x7D40B88E
		b		FDP_0DA0
		dc.l	0x7D60B88E
		b		FDP_0DA0
		dc.l	0x7D80B88E
		b		FDP_0DA0
		dc.l	0x7DA0B88E
		b		FDP_0DA0
		dc.l	0x7DC0B88E
		b		FDP_0DA0
		dc.l	0x7DE0B88E
		b		FDP_0DA0
		dc.l	0x7E00B88E
		b		FDP_0DA0
		dc.l	0x7E20B88E
		b		FDP_0DA0
		dc.l	0x7E40B88E
		b		FDP_0DA0
		dc.l	0x7E60B88E
		b		FDP_0DA0
		dc.l	0x7E80B88E
		b		FDP_0DA0
		dc.l	0x7EA0B88E
		b		FDP_0DA0
		dc.l	0x7EC0B88E
		b		FDP_0DA0
		dc.l	0x7EE0B88E
		b		FDP_0DA0
		dc.l	0x7F00B88E
		b		FDP_0DA0
		dc.l	0x7F20B88E
		b		FDP_0DA0
		dc.l	0x7F40B88E
		b		FDP_0DA0
		dc.l	0x7F60B88E
		b		FDP_0DA0
		dc.l	0x7F80B88E
		b		FDP_0DA0
		dc.l	0x7FA0B88E
		b		FDP_0DA0
		dc.l	0x7FC0B88E
		b		FDP_0DA0
		dc.l	0x7FE0B88E
		b		FDP_0DA0
		dc.l	0x7C00B9CE
		b		FDP_011C
		dc.l	0x7C20B9CE
		b		FDP_011C
		dc.l	0x7C40B9CE
		b		FDP_011C
		dc.l	0x7C60B9CE
		b		FDP_011C
		dc.l	0x7C80B9CE
		b		FDP_011C
		dc.l	0x7CA0B9CE
		b		FDP_011C
		dc.l	0x7CC0B9CE
		b		FDP_011C
		dc.l	0x7CE0B9CE
		b		FDP_011C
		dc.l	0x7D00B9CE
		b		FDP_011C
		dc.l	0x7D20B9CE
		b		FDP_011C
		dc.l	0x7D40B9CE
		b		FDP_011C
		dc.l	0x7D60B9CE
		b		FDP_011C
		dc.l	0x7D80B9CE
		b		FDP_011C
		dc.l	0x7DA0B9CE
		b		FDP_011C
		dc.l	0x7DC0B9CE
		b		FDP_011C
		dc.l	0x7DE0B9CE
		b		FDP_011C
		dc.l	0x7E00B9CE
		b		FDP_011C
		dc.l	0x7E20B9CE
		b		FDP_011C
		dc.l	0x7E40B9CE
		b		FDP_011C
		dc.l	0x7E60B9CE
		b		FDP_011C
		dc.l	0x7E80B9CE
		b		FDP_011C
		dc.l	0x7EA0B9CE
		b		FDP_011C
		dc.l	0x7EC0B9CE
		b		FDP_011C
		dc.l	0x7EE0B9CE
		b		FDP_011C
		dc.l	0x7F00B9CE
		b		FDP_011C
		dc.l	0x7F20B9CE
		b		FDP_011C
		dc.l	0x7F40B9CE
		b		FDP_011C
		dc.l	0x7F60B9CE
		b		FDP_011C
		dc.l	0x7F80B9CE
		b		FDP_011C
		dc.l	0x7FA0B9CE
		b		FDP_011C
		dc.l	0x7FC0B9CE
		b		FDP_011C
		dc.l	0x7FE0B9CE
		b		FDP_011C
		dc.l	0x7C00B90E
		b		FDP_104C
		dc.l	0x7C20B90E
		b		FDP_104C
		dc.l	0x7C40B90E
		b		FDP_104C
		dc.l	0x7C60B90E
		b		FDP_104C
		dc.l	0x7C80B90E
		b		FDP_104C
		dc.l	0x7CA0B90E
		b		FDP_104C
		dc.l	0x7CC0B90E
		b		FDP_104C
		dc.l	0x7CE0B90E
		b		FDP_104C
		dc.l	0x7D00B90E
		b		FDP_104C
		dc.l	0x7D20B90E
		b		FDP_104C
		dc.l	0x7D40B90E
		b		FDP_104C
		dc.l	0x7D60B90E
		b		FDP_104C
		dc.l	0x7D80B90E
		b		FDP_104C
		dc.l	0x7DA0B90E
		b		FDP_104C
		dc.l	0x7DC0B90E
		b		FDP_104C
		dc.l	0x7DE0B90E
		b		FDP_104C
		dc.l	0x7E00B90E
		b		FDP_104C
		dc.l	0x7E20B90E
		b		FDP_104C
		dc.l	0x7E40B90E
		b		FDP_104C
		dc.l	0x7E60B90E
		b		FDP_104C
		dc.l	0x7E80B90E
		b		FDP_104C
		dc.l	0x7EA0B90E
		b		FDP_104C
		dc.l	0x7EC0B90E
		b		FDP_104C
		dc.l	0x7EE0B90E
		b		FDP_104C
		dc.l	0x7F00B90E
		b		FDP_104C
		dc.l	0x7F20B90E
		b		FDP_104C
		dc.l	0x7F40B90E
		b		FDP_104C
		dc.l	0x7F60B90E
		b		FDP_104C
		dc.l	0x7F80B90E
		b		FDP_104C
		dc.l	0x7FA0B90E
		b		FDP_104C
		dc.l	0x7FC0B90E
		b		FDP_104C
		dc.l	0x7FE0B90E
		b		FDP_104C
		dc.l	0x7C00B94E
		b		FDP_1058
		dc.l	0x7C20B94E
		b		FDP_1058
		dc.l	0x7C40B94E
		b		FDP_1058
		dc.l	0x7C60B94E
		b		FDP_1058
		dc.l	0x7C80B94E
		b		FDP_1058
		dc.l	0x7CA0B94E
		b		FDP_1058
		dc.l	0x7CC0B94E
		b		FDP_1058
		dc.l	0x7CE0B94E
		b		FDP_1058
		dc.l	0x7D00B94E
		b		FDP_1058
		dc.l	0x7D20B94E
		b		FDP_1058
		dc.l	0x7D40B94E
		b		FDP_1058
		dc.l	0x7D60B94E
		b		FDP_1058
		dc.l	0x7D80B94E
		b		FDP_1058
		dc.l	0x7DA0B94E
		b		FDP_1058
		dc.l	0x7DC0B94E
		b		FDP_1058
		dc.l	0x7DE0B94E
		b		FDP_1058
		dc.l	0x7E00B94E
		b		FDP_1058
		dc.l	0x7E20B94E
		b		FDP_1058
		dc.l	0x7E40B94E
		b		FDP_1058
		dc.l	0x7E60B94E
		b		FDP_1058
		dc.l	0x7E80B94E
		b		FDP_1058
		dc.l	0x7EA0B94E
		b		FDP_1058
		dc.l	0x7EC0B94E
		b		FDP_1058
		dc.l	0x7EE0B94E
		b		FDP_1058
		dc.l	0x7F00B94E
		b		FDP_1058
		dc.l	0x7F20B94E
		b		FDP_1058
		dc.l	0x7F40B94E
		b		FDP_1058
		dc.l	0x7F60B94E
		b		FDP_1058
		dc.l	0x7F80B94E
		b		FDP_1058
		dc.l	0x7FA0B94E
		b		FDP_1058
		dc.l	0x7FC0B94E
		b		FDP_1058
		dc.l	0x7FE0B94E
		b		FDP_1058
		dc.l	0x7C00B98E
		b		FDP_1064
		dc.l	0x7C20B98E
		b		FDP_1064
		dc.l	0x7C40B98E
		b		FDP_1064
		dc.l	0x7C60B98E
		b		FDP_1064
		dc.l	0x7C80B98E
		b		FDP_1064
		dc.l	0x7CA0B98E
		b		FDP_1064
		dc.l	0x7CC0B98E
		b		FDP_1064
		dc.l	0x7CE0B98E
		b		FDP_1064
		dc.l	0x7D00B98E
		b		FDP_1064
		dc.l	0x7D20B98E
		b		FDP_1064
		dc.l	0x7D40B98E
		b		FDP_1064
		dc.l	0x7D60B98E
		b		FDP_1064
		dc.l	0x7D80B98E
		b		FDP_1064
		dc.l	0x7DA0B98E
		b		FDP_1064
		dc.l	0x7DC0B98E
		b		FDP_1064
		dc.l	0x7DE0B98E
		b		FDP_1064
		dc.l	0x7E00B98E
		b		FDP_1064
		dc.l	0x7E20B98E
		b		FDP_1064
		dc.l	0x7E40B98E
		b		FDP_1064
		dc.l	0x7E60B98E
		b		FDP_1064
		dc.l	0x7E80B98E
		b		FDP_1064
		dc.l	0x7EA0B98E
		b		FDP_1064
		dc.l	0x7EC0B98E
		b		FDP_1064
		dc.l	0x7EE0B98E
		b		FDP_1064
		dc.l	0x7F00B98E
		b		FDP_1064
		dc.l	0x7F20B98E
		b		FDP_1064
		dc.l	0x7F40B98E
		b		FDP_1064
		dc.l	0x7F60B98E
		b		FDP_1064
		dc.l	0x7F80B98E
		b		FDP_1064
		dc.l	0x7FA0B98E
		b		FDP_1064
		dc.l	0x7FC0B98E
		b		FDP_1064
		dc.l	0x7FE0B98E
		b		FDP_1064
