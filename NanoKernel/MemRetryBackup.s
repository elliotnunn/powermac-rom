	MACRO
	MRTblEntry &word, &func1, &func2
	dc.w &word
	dc.b (&func1 - FDP) >> 2
	dc.b (&func2 - FDP) >> 2
	ENDM

	MRTblEntry 0x2540, FDP_00B8, FDP_0150 ; lwarx
	MRTblEntry 0x4550, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E4, FDP_0150
	MRTblEntry 0x2460, FDP_00E4, FDP_0150
	MRTblEntry 0x4130, FDP_00DC, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E8, FDP_0150
	MRTblEntry 0x45b3, FDP_xxxx, FDP_0004
	MRTblEntry 0x4130, FDP_00A4, FDP_015C
	MRTblEntry 0x41f2, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E4, FDP_0150
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4130, FDP_00DC, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x268b, FDP_0314, FDP_02FC
	MRTblEntry 0x2460, FDP_00E4, FDP_0150
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x260b, FDP_02B0, FDP_02E4 ; lswx
	MRTblEntry 0x260f, FDP_029C, FDP_02E4 ; lswi
	MRTblEntry 0x2242, FDP_0260, FDP_0284 ; stswx
	MRTblEntry 0x224e, FDP_0254, FDP_0284 ; stswi
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E8, FDP_0150
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4130, FDP_00A4, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x2460, FDP_00E8, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x2160, FDP_00B0, FDP_015C ; stwcx.
	MRTblEntry 0x4170, FDP_xxxx, FDP_0004
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x24a2, FDP_00E8, FDP_0164 ; lwbrx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x2120, FDP_0088, FDP_015C ; stwbrx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x1492, FDP_00E8, FDP_0160 ; lhbrx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x1110, FDP_0094, FDP_015C ; sthbrx
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x07f0, FDP_00E4, FDP_024C ; eciwx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x03f0, FDP_00DC, FDP_024C ; ecowx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4302, FDP_01F8, FDP_020C ; dcbz
	MRTblEntry 0x0f50, FDP_00E4, FDP_0370 ; lwz(x)
	MRTblEntry 0x2770, FDP_00D4, FDP_0398 ; lbz(x)
	MRTblEntry 0x0b90, FDP_0350, FDP_015C ; stw(x)
	MRTblEntry 0x23b0, FDP_0364, FDP_015C ; stb(x)
	MRTblEntry 0x1410, FDP_00E4, FDP_0150 ; lhz(x)
	MRTblEntry 0x1450, FDP_00E4, FDP_014C ; lha(x)
	MRTblEntry 0x1110, FDP_00DC, FDP_015C ; sth(x)
	MRTblEntry 0x25a3, FDP_00E8, FDP_01A4 ; lmw
	MRTblEntry 0x24e0, FDP_00E4, FDP_0174 ; lfs(x)
	MRTblEntry 0x44f0, FDP_00E4, FDP_0178 ; lfd(x)
	MRTblEntry 0x2120, FDP_0008, FDP_015C ; stfs(x)
	MRTblEntry 0x4130, FDP_0014, FDP_015C ; stfd(x)
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x2120, FDP_0014, FDP_015C ; stfiwx
	MRTblEntry 0x1760, FDP_00CC, FDP_0384 ; lwzu(x)
	MRTblEntry 0x8740, FDP_00C0, FDP_015C ; lbzu(x)
	MRTblEntry 0x23a0, FDP_0358, FDP_015C ; stwu(x)
	MRTblEntry 0x8380, FDP_00C0, FDP_015C ; stbu(x)
	MRTblEntry 0x1410, FDP_00E8, FDP_0150 ; lhzu(x)
	MRTblEntry 0x8740, FDP_00C0, FDP_015C ; lhau(x)
	MRTblEntry 0x1110, FDP_00A4, FDP_015C ; sthu(x)
	MRTblEntry 0x8380, FDP_00C0, FDP_015C ; stmw
	MRTblEntry 0x24e0, FDP_00E8, FDP_0174 ; lfsu(x)
	MRTblEntry 0x44f0, FDP_00E8, FDP_0178 ; lfdu(x)
	MRTblEntry 0x2120, FDP_000C, FDP_015C ; stfsu(x)
	MRTblEntry 0x4130, FDP_0018, FDP_015C ; stfdu(x)
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004

	MRTblEntry 0x2540, FDP_00B8, FDP_0150 ; lwarx
	MRTblEntry 0x4550, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E4, FDP_0150
	MRTblEntry 0x2460, FDP_00E4, FDP_0150
	MRTblEntry 0x4130, FDP_00DC, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E8, FDP_0150
	MRTblEntry 0x45b3, FDP_xxxx, FDP_0004
	MRTblEntry 0x4130, FDP_00A4, FDP_015C
	MRTblEntry 0x41f2, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E4, FDP_0150
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4130, FDP_00DC, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x268b, FDP_0314, FDP_02FC
	MRTblEntry 0x2460, FDP_00E4, FDP_0150
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x260b, FDP_02B0, FDP_02E4 ; lswx
	MRTblEntry 0x260f, FDP_029C, FDP_02E4 ; lswi
	MRTblEntry 0x2242, FDP_0260, FDP_0284 ; stswx
	MRTblEntry 0x224e, FDP_0254, FDP_0284 ; stswi
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4430, FDP_00E8, FDP_0150
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4130, FDP_00A4, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x2460, FDP_00E8, FDP_015C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x2160, FDP_00B0, FDP_015C ; stwcx.
	MRTblEntry 0x4170, FDP_xxxx, FDP_0004
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x24a2, FDP_00E8, FDP_0164 ; lwbrx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x2120, FDP_0088, FDP_015C ; stwbrx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x1492, FDP_00E8, FDP_0160 ; lhbrx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x1110, FDP_0094, FDP_015C ; sthbrx
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x0fe2, FDP_00E8, FDP_023C
	MRTblEntry 0x07f0, FDP_00E4, FDP_024C ; eciwx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x03f0, FDP_00DC, FDP_024C ; ecowx
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x4302, FDP_01F8, FDP_020C ; dcbz
	MRTblEntry 0x2420, FDP_00E4, FDP_0150 ; lwz(x)
	MRTblEntry 0x0c00, FDP_00E4, FDP_0150 ; lbz(x)
	MRTblEntry 0x2120, FDP_00DC, FDP_015C ; stw(x)
	MRTblEntry 0x0900, FDP_00DC, FDP_015C ; stb(x)
	MRTblEntry 0x1410, FDP_00E4, FDP_0150 ; lhz(x)
	MRTblEntry 0x1450, FDP_00E4, FDP_014C ; lha(x)
	MRTblEntry 0x1110, FDP_00DC, FDP_015C ; sth(x)
	MRTblEntry 0x25a3, FDP_00E8, FDP_01A4 ; lmw
	MRTblEntry 0x24e0, FDP_00E4, FDP_0174 ; lfs(x)
	MRTblEntry 0x44f0, FDP_00E4, FDP_0178 ; lfd(x)
	MRTblEntry 0x2120, FDP_0008, FDP_015C ; stfs(x)
	MRTblEntry 0x4130, FDP_0014, FDP_015C ; stfd(x)
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x2120, FDP_0014, FDP_015C ; stfiwx
	MRTblEntry 0x2420, FDP_00E8, FDP_0150 ; lwzu(x)
	MRTblEntry 0x0c00, FDP_00E8, FDP_0150 ; lbzu(x)
	MRTblEntry 0x2120, FDP_00A4, FDP_015C ; stwu(x)
	MRTblEntry 0x0900, FDP_00A4, FDP_015C ; stbu(x)
	MRTblEntry 0x1410, FDP_00E8, FDP_0150 ; lhzu(x)
	MRTblEntry 0x1450, FDP_00E8, FDP_014C ; lhau(x)
	MRTblEntry 0x1110, FDP_00A4, FDP_015C ; sthu(x)
	MRTblEntry 0x21e2, FDP_00A4, FDP_01D8 ; stmw
	MRTblEntry 0x24e0, FDP_00E8, FDP_0174 ; lfsu(x)
	MRTblEntry 0x44f0, FDP_00E8, FDP_0178 ; lfdu(x)
	MRTblEntry 0x2120, FDP_000C, FDP_015C ; stfsu(x)
	MRTblEntry 0x4130, FDP_0018, FDP_015C ; stfdu(x)
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
	MRTblEntry 0x07f0, FDP_xxxx, FDP_0004
