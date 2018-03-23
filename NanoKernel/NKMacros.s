	MACRO
	_log 	&s
		BL		@paststring
		STRING	AsIs
		DC.B	&s, 0, 0
		ALIGN	2
@paststring
		mflr	r8
		BL		PrintS
	ENDM

	;	Cool macro for one-line debug calls
	MACRO
	_wlog	&s1, &reg, &s2, &scratch==r8

	if		&TYPE('ExtraNKLogging') != 'UNDEFINED'
		mr		&scratch, r8

		_log	&s1
		_log	'[ '

		mr		r8, &reg
		bl		PrintW

		_log	']'
		_log	&s2

		mr		r8, &scratch
	endif

	ENDM

	MACRO
	_wlogh	&s1, &reg, &s2, &scratch==r8

	if		&TYPE('ExtraNKLogging') != 'UNDEFINED'
		mr		&scratch, r8

		_log	&s1
		_log	'[ '

		mr		r8, &reg
		bl		PrintH

		_log	']'
		_log	&s2

		mr		r8, &scratch
	endif

	ENDM

	MACRO
	_clog	&s

	if		&TYPE('ExtraNKLogging') != 'UNDEFINED'
		_log	&s
	endif

	ENDM


	MACRO
	LHHI	&reg, &val
	lis		(&reg), ((&val) >> 16) & 0xffff
	ENDM


	MACRO
	LLHI	&reg, &val
	ori		(&reg), (&reg), (&val) & 0xffff
	ENDM


	MACRO
	lisori	&reg, &val
	lis		&reg, ((&val) >> 16) & 0xffff
	ori		&reg, &reg, (&val) & 0xffff
	ENDM

	MACRO
	llabel	&reg, &val
	lisori	&reg, &val - NKTop
	ENDM



				MACRO
				_lstart				&reg, &val
				LHHI				(&reg), (&val)
HalfLoadedWord	set					(&val)
HalfLoadedReg	set					(&reg)
				ENDM


	MACRO
	_lfinish
		LLHI	HalfLoadedReg, HalfLoadedWord
	ENDM


	MACRO
	InitList					&ptr, &sig, &scratch==r8
		_lstart					&scratch, &sig
		stw						&ptr, LLL.Next(&ptr)
		_lfinish
		stw						&ptr, LLL.Prev(&ptr)
		stw						&scratch, LLL.Signature(&ptr)
	ENDM


	;	Next is 8, Prev is C

	MACRO
	InsertAsPrev		&el, &next, &scratch==r18

	stw		&next,		LLL.Next(&el)
	lwz		&scratch,	LLL.Prev(&next)
	stw		&scratch,	LLL.Prev(&el)
	stw		&el,		LLL.Next(&scratch)
	stw		&el,		LLL.Prev(&next)

	ENDM


	MACRO
	InsertAsNext		&el, &prev, &scratch==r18

	stw		&prev,		LLL.Prev(&el)
	lwz		&scratch,	LLL.Next(&prev)
	stw		&scratch,	LLL.Next(&el)
	stw		&el,		LLL.Prev(&scratch)
	stw		&el,		LLL.Next(&prev)

	ENDM


	MACRO
	RemoveFromList		&el, &scratch1==r17, &scratch2==r18

	;	Point neighbours of el up and down at each other
	lwz		&scratch1, 8(&el)
	lwz		&scratch2, 12(&el)
	stw		&scratch1, 8(&scratch2)
	stw		&scratch2, 12(&scratch1)

	;	Zero out the pointers in el
	li		&scratch1, 0
	stw		&scratch1, 8(&el)
	stw		&scratch1, 12(&el)

	ENDM


	MACRO
	_Lock		&lockoffset, &scratch1==r17, &scratch2==r18
		mr		&scratch1, r8
		mr		&scratch2, r9
		addi	r8, r1, &lockoffset
		bl		AcquireLock
		mr		r8, &scratch1
		mr		r9, &scratch2
	ENDM

	MACRO
	_AssertAndRelease		&lockoffset, &scratch==r18
		sync
		lwz		&scratch, &lockoffset(r1)
		cmpwi	cr1, &scratch, 0
		li		&scratch, 0
		bne+	cr1, @okay
		mflr	&scratch
		bl		panic

@okay	stw		&scratch, &lockoffset(r1)
	ENDM

	MACRO
	_bset			&dest, &src, &bit

	IF &bit < 16
		oris&dot	&dest, &src, 1 << (15 - (&bit))
	ELSE
		ori&dot		&dest, &src, 1 << (31 - (&bit))
	ENDIF

	ENDM

	MACRO
	_bclr			&dest, &src, &bit

_bclr_rbit set &bit+1
	if _bclr_rbit > 31
_bclr_rbit set 0
	endif

_bclr_lbit set &bit-1
	if _bclr_lbit < 0
_bclr_lbit set 31
	endif

	rlwinm&dot		&dest, &src, 0, _bclr_rbit, _bclr_lbit

	ENDM

	MACRO
	_band			&dest, &src, &bit

	IF &bit < 16
		andis&dot	&dest, &src, 1 << (15 - (&bit))
	ELSE
		andi&dot	&dest, &src, 1 << (31 - (&bit))
	ENDIF

	ENDM


	MACRO
	_b_if_time_gt	&lhi, &rhi, &targ

	cmpw	&lhi, &rhi
	cmplw	cr1, &lhi + 1, &rhi + 1
	bgt		&targ
	blt		@fallthru
	bgt		cr1, &targ
@fallthru

	ENDM


	MACRO
	_b_if_time_le	&lhi, &rhi, &targ

	cmpw	&lhi, &rhi
	cmplw	cr1, &lhi + 1, &rhi + 1
	blt		&targ
	bgt		@fallthru
	ble		cr1, &targ
@fallthru

	ENDM


	MACRO
	_RegRangeToContextBlock &first, &last

	stw		&first, $104+8*(&first)(r6)

	IF &first != &last
	_RegRangeToContextBlock &first+1, &last
	ENDIF

	ENDM


	MACRO
	_RegRangeFromContextBlock &first, &last

	lwz		&first, $104+8*(&first)(r6)

	IF &first != &last
	_RegRangeFromContextBlock &first+1, &last
	ENDIF

	ENDM


	MACRO
	_FloatRangeToContextBlock &first, &last

	stfd	&first, ContextBlock.FloatRegisters+8*(&first)(r6)

	IF &first != &last
	_FloatRangeToContextBlock &first+1, &last
	ENDIF

	ENDM


	MACRO
	_FloatRangeFromContextBlock &first, &last

	lfd		&first, ContextBlock.FloatRegisters+8*(&first)(r6)

	IF &first != &last
	_FloatRangeFromContextBlock &first+1, &last
	ENDIF

	ENDM
