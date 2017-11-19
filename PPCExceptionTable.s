HASH1		equ		978
HASH2		equ		979
ICMP		equ		981
DCMP		equ		977
IMISS		equ		980
DMISS		equ		976
RPA			equ		982



	macro
	Vanilla			&idx

@start
	b		@jump1
	b		@jump2

@jump1
	;	r1 -> SPRG1
	;	LR -> SPRG2
	;	targ -> r1
	;	optr -> LR
	mtsprg	1, r1
	mflr	r1
	mtsprg	2, r1
	mfsprg	r1, 3
	lwz		r1, &idx(r1)
	mtlr	r1
	blrl
	dc.l	@start - TableStart
	mflr	r1

@jump2
	mtsprg	1, r1
	mfsprg	r1, 3
	mtsprg	2, r1
	mtlr	r1
	lwz		r1, &idx(r1)
	dc.l	@start - TableStart
	blrl

	endm



TableStart



;	0000-00ff: For software use only

	org		0x0000
	mtsprg	1, r1
	mfsprg	r1, 3
	lwz		r1, 0x00BC(r1)
	mtlr	r1
	blrl


	org		0x0080
	dc.l	0x0000D000                ; '....' (invalid instruction)



;	0100-0fff: Architecture-defined exceptions

	org		0x0100
	b		$+0x0008                  ; 0x00000108
	b		$+0x0050                  ; 0x00000154
	mtsprg	1, r1
	mfcr	r1
	mtsprg	2, r1
	mfsrr1	r1
	mtcrf	255, r1
	bne		cr7, RTASFairyDust
	mfspr	r1, HID0
	mtcrf	255, r1
	bns		cr3, RTASFairyDust
	mfsprg	r1, 2
	mtcrf	255, r1
	mflr	r1
	mtsprg	2, r1
	mfsprg	r1, 3
	lwz		r1, 0x0004(r1)
	mtlr	r1
	blrl
	dc.l	0x00000100                ; '....' (invalid instruction)


	org		0x180
PerfMon
	mtsprg	2, r1
	mfsprg	r1, 3
	stw		r2, 0x0000(r1)
	mfsprg	r2, 2
	rlwinm	r2, r2, 26, 24, 29
	lwzx	r1, r2, r1
	mflr	r2
	mtlr	r1
	mfsprg	r1, 2
	mtsprg	2, r2
	mfsprg	r2, 3
	lwz		r2, 0x0000(r2)
	blr


	org		0x0200			;	Machine Check
	Vanilla	0x0008


	org		0x0300			;	Data Storage
	Vanilla	0x000C


	org		0x0400			;	Instruction Storage
	Vanilla	0x0010


	org		0x0500			;	External
	Vanilla	0x0014


	org		0x0600			;	Alignment
	Vanilla	0x0018


	org		0x0700			;	Program
	Vanilla	0x001C


	org		0x0800			;	FP Unavailable
	Vanilla	0x0020


	org		0x0900			;	Decrementer
	Vanilla	0x0024


	org		0x0A00
	Vanilla	0x0028


	org		0x0B00
	Vanilla	0x002C


	org		0x0C00			;	System Call
	Vanilla	0x0030


	org		0x0D00			;	Trace
	Vanilla	0x0034


	org		0x0E00
	Vanilla	0x0038


	;	Performance monitor???

	org		0x0F00
	mtsprg	1, r1
	li		r1, 0xF00
	b		PerfMon

	org		0x0F20
	mtsprg	1, r1
	li		r1, 0xF20
	b		PerfMon




;	1000-2fff: Implementation-specific exceptions

	org		0x1000
	mfspr	r2, HASH1
	lwz		r1, 0x0000(r2)
	mfctr	r0
	mfspr	r3, ICMP
	cmpw	r1, r3
	beq		$+0x001C                  ; 0x00001030
	li		r1, 7
	mtctr	r1
	lwzu	r1, 0x0008(r2)
	cmpw	r1, r3
	bdnzf	cr0_EQ, $-0x0008           ; 0x00001020
	bne		$+0x0038                  ; 0x00001064
	lwz		r1, 0x0004(r2)
	mtctr	r0
	andi.	r3, r1, 0x0008
	bne		$+0x006C                  ; 0x000010A8
	mfspr	r0, IMISS
	mfsrr1	r3
	mtcrf	128, r3
	mtspr	RPA, r1
	ori		r1, r1, 0x0100
	srwi	r1, r1, 8
	dc.l	0x7C0007E4                ; '|...' (invalid instruction)
	stb		r1, 0x0006(r2)
	rfi
	andi.	r1, r3, 0x0040
	bne		$+0x0014                  ; 0x0000107C
	mfspr	r2, HASH2
	lwz		r1, 0x0000(r2)
	ori		r3, r3, 0x0040
	b		$-0x0068                  ; 0x00001010
	mfsrr1	r3
	clrlwi	r2, r3, 16
	oris	r2, r2, 0x4000
	mtctr	r0
	mtsrr1	r2
	mfmsr	r0
	xoris	r0, r0, 0x0002
	mtcrf	128, r3
	mtmsr	r0
	isync
	b		$-0x0CA4                  ; 0x00000400
	mfsrr1	r3
	clrlwi	r2, r3, 16
	oris	r2, r2, 0x1000
	b		$-0x0028                  ; 0x0000108C


	org		0x1100
	mfspr	r2, HASH1
	lwz		r1, 0x0000(r2)
	mfctr	r0
	mfspr	r3, DCMP
	cmpw	r1, r3
	beq		$+0x001C                  ; 0x00001130
	li		r1, 7
	mtctr	r1
	lwzu	r1, 0x0008(r2)
	cmpw	r1, r3
	bdnzf	cr0_EQ, $-0x0008           ; 0x00001120
	bne		$+0x0034                  ; 0x00001160
	lwz		r1, 0x0004(r2)
	mtctr	r0
	mfspr	r0, DMISS
	mfsrr1	r3
	mtcrf	128, r3
	mtspr	RPA, r1
	ori		r1, r1, 0x0100
	srwi	r1, r1, 8
	dc.l	0x7C0007A4                ; '|...' (invalid instruction)
	stb		r1, 0x0006(r2)
	rfi
	nop
	andi.	r1, r3, 0x0040
	bne		$+0x013C                  ; 0x000012A0
	mfspr	r2, HASH2
	lwz		r1, 0x0000(r2)
	ori		r3, r3, 0x0040
	b		$-0x0064                  ; 0x00001110


	org		0x1200
	mfspr	r2, HASH1
	lwz		r1, 0x0000(r2)
	mfctr	r0
	mfspr	r3, DCMP
	cmpw	r1, r3
	beq		$+0x001C                  ; 0x00001230
	li		r1, 7
	mtctr	r1
	lwzu	r1, 0x0008(r2)
	cmpw	r1, r3
	bdnzf	cr0_EQ, $-0x0008           ; 0x00001220
	bne		$+0x003C                  ; 0x00001268
	lwz		r1, 0x0004(r2)
	mtctr	r0
	slwi.	r3, r1, 30
	bge		$+0x0044                  ; 0x00001280
	andi.	r3, r1, 0x0001
	bne		$+0x0054                  ; 0x00001298
	mfspr	r0, DMISS
	mfsrr1	r3
	mtcrf	128, r3
	ori		r1, r1, 0x0180
	mtspr	RPA, r1
	dc.l	0x7C0007A4                ; '|...' (invalid instruction)
	sth		r1, 0x0006(r2)
	rfi
	andi.	r1, r3, 0x0040
	bne		$+0x0034                  ; 0x000012A0
	mfspr	r2, HASH2
	lwz		r1, 0x0000(r2)
	ori		r3, r3, 0x0040
	b		$-0x006C                  ; 0x00001210
	mfsrr1	r0
	extrwi	r0, r0, 1, 17
	mfspr	r3, DMISS
	mfsrin	r3, r3
	rlwnm.	r3, r3, r0, 1, 1
	beq		$-0x004C                  ; 0x00001248
	lis		r1, 2048
	b		$+0x000C                  ; 0x000012A8
	lis		r1, 16384
	mtctr	r0
	mfsrr1	r3
	rlwimi	r1, r3, 9, 6, 6
	clrlwi	r2, r3, 16
	mtsrr1	r2
	mtdsisr	r1
	mfspr	r1, DMISS
	andi.	r2, r2, 0x0001
	beq+      $+0x0008                  ; 0x000012CC
	xori	r1, r1, 0x0007
	mtdar	r1
	mfmsr	r0
	xoris	r0, r0, 0x0002
	mtcrf	128, r3
	mtmsr	r0
	isync
	b		$-0x0FE4                  ; 0x00000300


	org		0x1300
	Vanilla	0x004C


	org		0x1400
	Vanilla	0x0050


	org		0x1500
	Vanilla	0x0054


	org		0x1600
	Vanilla	0x0058


	org		0x1700
	Vanilla	0x005C


	org		0x1800
	Vanilla	0x0060


	org		0x1900
	Vanilla	0x0064


	org		0x1A00
	Vanilla	0x0068


	org		0x1B00
	Vanilla	0x006C


	org		0x1C00
	Vanilla	0x0070


	org		0x1D00
	Vanilla	0x0074


	org		0x1E00
	Vanilla	0x0078


	org		0x1F00
	Vanilla	0x007C


	org		0x2000
	Vanilla	0x0080


	org		0x2100
	Vanilla	0x0084


	org		0x2200
	Vanilla	0x0088


	org		0x2300
	Vanilla	0x008C


	org		0x2400
	Vanilla	0x0090


	org		0x2500
	Vanilla	0x0094


	org		0x2600
	Vanilla	0x0098


	org		0x2700
	Vanilla	0x009C


	org		0x2800
	Vanilla	0x00A0


	org		0x2900
	Vanilla	0x00A4


	org		0x2A00
	Vanilla	0x00A8


	org		0x2B00
	Vanilla	0x00AC


	org		0x2C00
	Vanilla	0x00B0


	org		0x2D00
	Vanilla	0x00B4


	org		0x2E00
	Vanilla	0x00B8


	org		0x2F00
	Vanilla	0x00BC



;	Outside the exception table, but called by it:

    org			0x3000
RTASFairyDust
    mr          r21,r3

    li          r0,0

    lwz         r5, 0(r21)
    lwz         r4, 4(r21)

    lwz         r9, 12(r21)
    lwz         r3, 12(r9)

    lwz         r6,  8(r21)
    lwz         r8, 16(r21)
    lwz         r22,24(r21)
    lwz         r23,28(r21)

    bl          @clrbats

    lis         r7,   'RT'
    ori         r7,r7,'AS'

	; Soo, we jump to *(arg + 24) the ugly way
    mtlr    r22
    blr

@clrbats
    mtdbatl 0,r0
    mtdbatu 0,r0
    mtdbatl 1,r0
    mtdbatu 1,r0
    mtdbatl 2,r0
    mtdbatu 2,r0
    mtdbatl 3,r0
    mtdbatu 3,r0
    mtibatl 0,r0
    mtibatu 0,r0
    mtibatl 1,r0
    mtibatu 1,r0
    mtibatl 2,r0
    mtibatu 2,r0
    mtibatl 3,r0
    mtibatu 3,r0
    isync

    blr
