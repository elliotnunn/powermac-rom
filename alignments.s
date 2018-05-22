mrBase equ r19
mrScratch equ r26
mrCtr equ r17
mrHigh equ r20
mrLow equ r21


MRLoad1241
		lbz		mrScratch, -8(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 0

MRLoad241
		lhz		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 4
		insrwi	mrHigh, mrScratch, 16, 8
		b		MRLoad41

MRLoad141
		lbz		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 16

MRLoad41
		lwz		mrScratch, -5(mrBase)
		subi	mrCtr, mrCtr, 8
		inslwi	mrHigh, mrScratch, 8, 24
		insrwi	mrLow, mrScratch, 24, 0
		b		MRLoad1

MRLoad1421
		lbz		mrScratch, -8(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 0

MRLoad421
		lwz		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 8
		inslwi	mrHigh, mrScratch, 24, 8
		insrwi	mrLow, mrScratch, 8, 0
		b		MRLoad21

MRLoad1221
		lbz		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 16

MRLoad221
		lhz		mrScratch, -5(mrBase)
		subi	mrCtr, mrCtr, 4
		rlwimi	mrHigh, mrScratch, 24, 24, 31
		insrwi	mrLow, mrScratch, 8, 0
		b		MRLoad21

MRLoad121
		lbz		mrScratch, -4(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrLow, mrScratch, 8, 0

MRLoad21
		lhz		mrScratch, -3(mrBase)
		subi	mrCtr, mrCtr, 4
		insrwi	mrLow, mrScratch, 16, 8
		b		MRLoad1

MRLoad11
		lbz		mrScratch, -2(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrLow, mrScratch, 8, 16

MRLoad1
		lbz		mrScratch, -1(mrBase)
		insrwi	mrLow, mrScratch, 8, 24
		b		MRExecuted

MRLoad242
		lhz		mrScratch, -8(mrBase)
		subi	mrCtr, mrCtr, 4
		insrwi	mrHigh, mrScratch, 16, 0
		b		MRLoad42

MRLoad142
		lbz		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 8

MRLoad42
		lwz		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 8
		inslwi	mrHigh, mrScratch, 16, 16
		insrwi	mrLow, mrScratch, 16, 0
		b		MRLoad2

MRLoad122
		lbz		mrScratch, -5(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 24
		b		MRLoad22

MRLoad12
		lbz		mrScratch, -3(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrLow, mrScratch, 8, 8
		b		MRLoad2

MRLoad44
		lwz		mrHigh, -8(mrBase)
		subi	mrCtr, mrCtr, 8
		lwz		mrLow, -4(mrBase)
		b		MRExecuted

MRLoad124
		lbz		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 8

MRLoad24
		lhz		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 4
		insrwi	mrHigh, mrScratch, 16, 16
		lwz		mrLow, -4(mrBase)
		b		MRExecuted

MRLoad14
		lbz		mrScratch, -5(mrBase)
		subi	mrCtr, mrCtr, 2
		insrwi	mrHigh, mrScratch, 8, 24
		lwz		mrLow, -4(mrBase)
		b		MRExecuted

MRLoad4
		bc		BO_IF, 23, @atomic
		lwz		mrLow, -4(mrBase)
		b		MRExecuted
@atomic
		li		mrScratch, -4
		lwarx	mrLow, mrScratch, mrBase
		b		MRExecuted

MRLoad8
		lwz		mrHigh, -8(mrBase)
		lwz		mrLow, -4(mrBase)
		b		MRExecuted

MRLoadVector
		clrrwi	mrScratch, r25, 10
		rlwimi	mrScratch, mrCtr, 14, 24, 28
		addi	mrScratch, mrScratch, LVXArray - FDP
		mtlr	mrScratch
		mr		mrScratch, r18
		_bset	r11, r11, 6
		blr

MRStore1241
		srwi	mrScratch, mrHigh, 24
		stb		mrScratch, -8(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore241
		srwi	mrScratch, mrHigh, 8
		sth		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 4
		b		MRStore41

MRStore141
		srwi	mrScratch, mrHigh, 8
		stb		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore41
		srwi	mrScratch, mrLow, 8
		insrwi	mrScratch, mrHigh, 8, 0
		stw		mrScratch, -5(mrBase)
		subi	mrCtr, mrCtr, 8
		stb		mrLow, -1(mrBase)
		b		MRExecuted

MRStore1421
		srwi	mrScratch, mrHigh, 24
		stb		mrScratch, -8(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore421
		srwi	mrScratch, mrLow, 24
		insrwi	mrScratch, mrHigh, 24, 0
		stw		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 8
		b		MRStore21

MRStore1221
		srwi	mrScratch, mrHigh, 8
		stb		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore221
		srwi	mrScratch, mrLow, 24
		insrwi	mrScratch, mrHigh, 8, 16
		sth		mrScratch, -5(mrBase)
		subi	mrCtr, mrCtr, 4
		b		MRStore21

MRStore121
		srwi	mrScratch, mrLow, 24
		stb		mrScratch, -4(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore21
		srwi	mrScratch, mrLow, 8
		sth		mrScratch, -3(mrBase)
		subi	mrCtr, mrCtr, 4
		stb		mrLow, -1(mrBase)
		b		MRExecuted

MRStore11
		srwi	mrScratch, mrLow, 8
		stb		mrScratch, -2(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore1
		stb		mrLow, -1(mrBase)
		b		MRExecuted

MRStore242
		srwi	mrScratch, mrHigh, 16
		sth		mrScratch, -8(mrBase)
		subi	mrCtr, mrCtr, 4
		b		MRStore42

MRStore142
		srwi	mrScratch, mrHigh, 16
		stb		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore42
		srwi	mrScratch, mrLow, 16
		insrwi	mrScratch, mrHigh, 16, 0
		stw		mrScratch, -6(mrBase)
		subi	mrCtr, mrCtr, 8
		sth		mrLow, -2(mrBase)
		b		MRExecuted

MRStore122
		stb		mrHigh, -5(mrBase)
		subi	mrCtr, mrCtr, 2
		b		MRStore22

MRStore12
		srwi	mrScratch, mrLow, 16
		stb		mrScratch, -3(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore2
		sth		mrLow, -2(mrBase)
		b		MRExecuted

MRStore44
		stw		mrHigh, -8(mrBase)
		subi	mrCtr, mrCtr, 8
		stw		mrLow, -4(mrBase)
		b		MRExecuted

MRStore124
		srwi	mrScratch, mrHigh, 16
		stb		mrScratch, -7(mrBase)
		subi	mrCtr, mrCtr, 2

MRStore24
		sth		mrHigh, -6(mrBase)
		subi	mrCtr, mrCtr, 4
		stw		mrLow, -4(mrBase)
		b		MRExecuted

MRStore14
		stb		mrHigh, -5(mrBase)
		subi	mrCtr, mrCtr, 2
		stw		mrLow, -4(mrBase)
		b		MRExecuted

MRStore4
		bc		BO_IF, 23, @atomic
		stw		mrLow, -4(mrBase)
		b		MRExecuted
@atomic
		li		mrScratch, -4
		stwcx.	mrLow, mrScratch, mrBase
		isync
		mfcr	mrScratch
		rlwimi	r13, mrScratch, 0, 0, 3
		b		MRExecuted

MRStore8
		stw		mrHigh, -8(mrBase)
		stw		mrLow, -4(mrBase)
		b		MRExecuted

MRStoreVector
		clrrwi	mrScratch, r25, 10
		rlwimi	mrScratch, mrCtr, 14, 24, 28
		addi	mrScratch, mrScratch, STVXArray - FDP
		mtlr	mrScratch
		mr		mrScratch, r18
		_bset	r11, r11, 6
		blr

		HalfWordTableEntry		  0,	MRStoreVector
		HalfWordTableEntry		  1,	MRStoreVector
		HalfWordTableEntry		  2,	MRStoreVector
		HalfWordTableEntry		  3,	MRStoreVector
		HalfWordTableEntry		  4,	MRStoreVector
		HalfWordTableEntry		  5,	MRStoreVector
		HalfWordTableEntry		  6,	MRStoreVector
		HalfWordTableEntry		  7,	MRStoreVector

		HalfWordTableEntry		  8,	MRLoadVector
		HalfWordTableEntry		  9,	MRLoadVector
		HalfWordTableEntry		 10,	MRLoadVector
		HalfWordTableEntry		 11,	MRLoadVector
		HalfWordTableEntry		 12,	MRLoadVector
		HalfWordTableEntry		 13,	MRLoadVector
		HalfWordTableEntry		 14,	MRLoadVector
		HalfWordTableEntry		 15,	MRLoadVector

		HalfWordTableEntry		 16,	MRStore1
		HalfWordTableEntry		 17,	MRStore1
		HalfWordTableEntry		 18,	MRStore1
		HalfWordTableEntry		 19,	MRStore1
		HalfWordTableEntry		 20,	MRStore1
		HalfWordTableEntry		 21,	MRStore1
		HalfWordTableEntry		 22,	MRStore1
		HalfWordTableEntry		 23,	MRStore1

		HalfWordTableEntry		 24,	MRLoad1
		HalfWordTableEntry		 25,	MRLoad1
		HalfWordTableEntry		 26,	MRLoad1
		HalfWordTableEntry		 27,	MRLoad1
		HalfWordTableEntry		 28,	MRLoad1
		HalfWordTableEntry		 29,	MRLoad1
		HalfWordTableEntry		 30,	MRLoad1
		HalfWordTableEntry		 31,	MRLoad1

		HalfWordTableEntry		 32,	MRStore2
		HalfWordTableEntry		 33,	MRStore11
		HalfWordTableEntry		 34,	MRStore2
		HalfWordTableEntry		 35,	MRStore11
		HalfWordTableEntry		 36,	MRStore2
		HalfWordTableEntry		 37,	MRStore11
		HalfWordTableEntry		 38,	MRStore2
		HalfWordTableEntry		 39,	MRStore11

		HalfWordTableEntry		 40,	MRLoad2
		HalfWordTableEntry		 41,	MRLoad11
		HalfWordTableEntry		 42,	MRLoad2
		HalfWordTableEntry		 43,	MRLoad11
		HalfWordTableEntry		 44,	MRLoad2
		HalfWordTableEntry		 45,	MRLoad11
		HalfWordTableEntry		 46,	MRLoad2
		HalfWordTableEntry		 47,	MRLoad11

		HalfWordTableEntry		 48,	MRStore12
		HalfWordTableEntry		 49,	MRStore21
		HalfWordTableEntry		 50,	MRStore12
		HalfWordTableEntry		 51,	MRStore21
		HalfWordTableEntry		 52,	MRStore12
		HalfWordTableEntry		 53,	MRStore21
		HalfWordTableEntry		 54,	MRStore12
		HalfWordTableEntry		 55,	MRStore21

		HalfWordTableEntry		 56,	MRLoad12
		HalfWordTableEntry		 57,	MRLoad21
		HalfWordTableEntry		 58,	MRLoad12
		HalfWordTableEntry		 59,	MRLoad21
		HalfWordTableEntry		 60,	MRLoad12
		HalfWordTableEntry		 61,	MRLoad21
		HalfWordTableEntry		 62,	MRLoad12
		HalfWordTableEntry		 63,	MRLoad21

		HalfWordTableEntry		 64,	MRStore4
		HalfWordTableEntry		 65,	MRStore121
		HalfWordTableEntry		 66,	MRStore22
		HalfWordTableEntry		 67,	MRStore121
		HalfWordTableEntry		 68,	MRStore4
		HalfWordTableEntry		 69,	MRStore121
		HalfWordTableEntry		 70,	MRStore22
		HalfWordTableEntry		 71,	MRStore121

		HalfWordTableEntry		 72,	MRLoad4
		HalfWordTableEntry		 73,	MRLoad121
		HalfWordTableEntry		 74,	MRLoad22
		HalfWordTableEntry		 75,	MRLoad121
		HalfWordTableEntry		 76,	MRLoad4
		HalfWordTableEntry		 77,	MRLoad121
		HalfWordTableEntry		 78,	MRLoad22
		HalfWordTableEntry		 79,	MRLoad121

		HalfWordTableEntry		 80,	MRStore14
		HalfWordTableEntry		 81,	MRStore41
		HalfWordTableEntry		 82,	MRStore14
		HalfWordTableEntry		 83,	MRStore221
		HalfWordTableEntry		 84,	MRStore14
		HalfWordTableEntry		 85,	MRStore41
		HalfWordTableEntry		 86,	MRStore14
		HalfWordTableEntry		 87,	MRStore221

		HalfWordTableEntry		 88,	MRLoad14
		HalfWordTableEntry		 89,	MRLoad41
		HalfWordTableEntry		 90,	MRLoad122
		HalfWordTableEntry		 91,	MRLoad221
		HalfWordTableEntry		 92,	MRLoad14
		HalfWordTableEntry		 93,	MRLoad41
		HalfWordTableEntry		 94,	MRLoad122
		HalfWordTableEntry		 95,	MRLoad221

		HalfWordTableEntry		 96,	MRStore24
		HalfWordTableEntry		 97,	MRStore141
		HalfWordTableEntry		 98,	MRStore42
		HalfWordTableEntry		 99,	MRStore1221
		HalfWordTableEntry		100,	MRStore24
		HalfWordTableEntry		101,	MRStore141
		HalfWordTableEntry		102,	MRStore42
		HalfWordTableEntry		103,	MRStore1221

		HalfWordTableEntry		104,	MRLoad24
		HalfWordTableEntry		105,	MRLoad141
		HalfWordTableEntry		106,	MRLoad42
		HalfWordTableEntry		107,	MRLoad1221
		HalfWordTableEntry		108,	MRLoad24
		HalfWordTableEntry		109,	MRLoad141
		HalfWordTableEntry		110,	MRLoad42
		HalfWordTableEntry		111,	MRLoad1221

		HalfWordTableEntry		112,	MRStore124
		HalfWordTableEntry		113,	MRStore241
		HalfWordTableEntry		114,	MRStore142
		HalfWordTableEntry		115,	MRStore421
		HalfWordTableEntry		116,	MRStore124
		HalfWordTableEntry		117,	MRStore241
		HalfWordTableEntry		118,	MRStore142
		HalfWordTableEntry		119,	MRStore421

		HalfWordTableEntry		120,	MRLoad124
		HalfWordTableEntry		121,	MRLoad241
		HalfWordTableEntry		122,	MRLoad142
		HalfWordTableEntry		123,	MRLoad421
		HalfWordTableEntry		124,	MRLoad124
		HalfWordTableEntry		125,	MRLoad241
		HalfWordTableEntry		126,	MRLoad142
		HalfWordTableEntry		127,	MRLoad421

		HalfWordTableEntry		128,	MRStore8
		HalfWordTableEntry		129,	MRStore1241
		HalfWordTableEntry		130,	MRStore242
		HalfWordTableEntry		131,	MRStore1421
		HalfWordTableEntry		132,	MRStore44
		HalfWordTableEntry		133,	MRStore1241
		HalfWordTableEntry		134,	MRStore242
		HalfWordTableEntry		135,	MRStore1421

		HalfWordTableEntry		136,	MRLoad8
		HalfWordTableEntry		137,	MRLoad1241
		HalfWordTableEntry		138,	MRLoad242
		HalfWordTableEntry		139,	MRLoad1421
		HalfWordTableEntry		140,	MRLoad44
		HalfWordTableEntry		141,	MRLoad1241
		HalfWordTableEntry		142,	MRLoad242
		HalfWordTableEntry		143,	MRLoad1421

