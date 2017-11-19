;	Contains the table used by InitBuiltin.s:OverrideProcessorInfo
;
;	If the Trampoline fails to pass in a signed HardwareInfo struct,
;	this is our first choice for populating ProcessorInfo.
;
;	Also contains a 'function' that will do the populating
;	(not very clever), and fall through to the end of the file,
;	where we expect to find Init.s:FinishInitBuiltin.

	macro				;	just to make the table below look nicer...
	PnfoTblEnt 	&a, &b, &c, &d, &e, &f, &g, &h, &i, &j, &k, &l, &m, &n, &o
	dc.l				&a * 1024, &b * 1024, &c * 1024
	dc.w				&d, &e, &f, &g, &h, &i, &j, &k, &l, &m, &n, &o
	endm

ProcessorInfoTable

;					- PageSize,  KB
;					|    - DataCacheTotalSize,  KB
;					|    |    - InstCacheTotalSize,  KB
;					|    |    |    - CoherencyBlockSize
;					|    |    |    |    - ReservationGranuleSize
;					|    |    |    |    |   - CombinedCaches
;					|    |    |    |    |   |    - InstCacheLineSize
;					|    |    |    |    |   |    |    - DataCacheLineSize
;					|    |    |    |    |   |    |    |    - DataCacheBlockSizeTouch
;					|    |    |    |    |   |    |    |    |    - InstCacheBlockSize
;					|    |    |    |    |   |    |    |    |    |    - DataCacheBlockSize
;					|    |    |    |    |   |    |    |    |    |    |   - InstCacheAssociativity
;					|    |    |    |    |   |    |    |    |    |    |   |   - DataCacheAssociativity
;					|    |    |    |    |   |    |    |    |    |    |   |   |     - TransCacheTotalSize
;					|    |    |    |    |   |    |    |    |    |    |   |   |     |   - TransCacheAssociativity

	PnfoTblEnt		4,  32,  32,  32,  32,  1,  64,  64,  32,  32,  32,  8,  8,  256,  2	; 0001 = 601
	PnfoTblEnt		4,   8,   8,  32,  32,  0,  32,  32,  32,  32,  32,  2,  2,   64,  2	; 0003 = 603
	PnfoTblEnt		4,  16,  16,  32,  32,  0,  32,  32,  32,  32,  32,  4,  4,  128,  2	; 0004 = 604
	PnfoTblEnt		4,  16,  16,  32,  32,  0,  32,  32,  32,  32,  32,  4,  4,   64,  2	; 0006 = 603e
	PnfoTblEnt		4,  16,  16,  32,  32,  0,  32,  32,  32,  32,  32,  4,  4,   64,  2	; 0007 = 750FX
	PnfoTblEnt		4,  32,  32,  32,  32,  0,  32,  32,  32,  32,  32,  8,  8,  128,  2	; 0008 = 750
	PnfoTblEnt		4,  32,  32,  32,  32,  0,  32,  32,  32,  32,  32,  4,  4,  128,  2	; 0009/a = ???
	PnfoTblEnt		4,  32,  32,  32,  32,  0,  32,  32,  32,  32,  32,  8,  8,  128,  2	; 000c = 7400
	PnfoTblEnt		4,  32,  32,  32,  32,  0,  32,  32,  32,  32,  32,  8,  8,  256,  4	; 000d = ???



OverrideProcessorInfo

@loop
	subic.	r9, r9, 4
	lwzx	r12, r11, r9
	stwx	r12, r10, r9
	bgt+	@loop
