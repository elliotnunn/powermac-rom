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
