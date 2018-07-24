    MACRO
    optabRow &upperSix, &lowerSix, &flags, &primLabel, &secLabel
    DC.W (&lowerSix << 10) | (&upperSix << 4) | &flags              ; 0-5 lowerSix, 6-11 upperSix, 12-15 flags
    DC.W ((&primLabel - MRTop) << 6) | ((&secLabel - MRTop) >> 2)   ; 16-23 primary routine, 24-31 secondary routine
    ENDM

MROptabX
    optabRow  20, 09, %0000, MRPrimPlainLoad,  MRSecLWARX       ; Xopcd=00000(101)00=020=LWARX
    optabRow  21, 17, %0000, MRCrash,          MRSecFail        ; Xopcd=00010(101)00=084
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00100(101)00=148
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00110(101)00=212
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01000(101)00=276
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01010(101)00=340
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01100(101)00=404
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01110(101)00=468
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10000(101)00=532
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10010(101)00=596
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10100(101)00=660
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10110(101)00=724
    optabRow  03, 17, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=11000(101)00=788
    optabRow  06, 09, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=11010(101)00=852
    optabRow  19, 16, %0000, MRPrimPlainStore, MRExit           ; Xopcd=11100(101)00=916
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11110(101)00=980
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00001(101)00=052
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00011(101)00=116
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00101(101)00=180
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00111(101)00=244
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01001(101)00=308
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01011(101)00=372
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01101(101)00=436
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01111(101)00=500
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10001(101)00=564
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10011(101)00=628
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10101(101)00=692
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10111(101)00=756
    optabRow  03, 17, %0000, MRPrimUpdLoad,    MRSecLoad        ; Xopcd=11001(101)00=820
    optabRow  27, 17, %0011, MRCrash,          MRSecFail        ; Xopcd=11011(101)00=884
    optabRow  19, 16, %0000, MRPrimUpdStore,   MRExit           ; Xopcd=11101(101)00=948
    optabRow  31, 16, %0010, MRCrash,          MRSecFail        ; Xopcd=11111(101)00=1012
    optabRow  03, 17, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=00000(101)01=021=LDX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00010(101)01=085
    optabRow  19, 16, %0000, MRPrimPlainStore, MRExit           ; Xopcd=00100(101)01=149=STDX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00110(101)01=213
    optabRow  40, 09, %1011, MRPrimUnknown,    MRSecUnknown     ; Xopcd=01000(101)01=277
    optabRow  06, 09, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=01010(101)01=341
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01100(101)01=405
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01110(101)01=469
    optabRow  32, 09, %1011, MRPrimLSWX,       MRSecLSWix       ; Xopcd=10000(101)01=533=LSWX
    optabRow  32, 09, %1111, MRPrimLSWI,       MRSecLSWix       ; Xopcd=10010(101)01=597=LSWI
    optabRow  36, 08, %0010, MRPrimSTSWX,      MRSecStrStore    ; Xopcd=10100(101)01=661=STSWX
    optabRow  36, 08, %1110, MRPrimSTSWI,      MRSecStrStore    ; Xopcd=10110(101)01=725=STSWI
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11000(101)01=789
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11010(101)01=853
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11100(101)01=917
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11110(101)01=981
    optabRow  03, 17, %0000, MRPrimUpdLoad,    MRSecLoad        ; Xopcd=00001(101)01=053=LDUX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00011(101)01=117
    optabRow  19, 16, %0000, MRPrimUpdStore,   MRExit           ; Xopcd=00101(101)01=181=STDUX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00111(101)01=245
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01001(101)01=309
    optabRow  06, 09, %0000, MRPrimUpdLoad,    MRExit           ; Xopcd=01011(101)01=373=LWAUX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01101(101)01=437
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01111(101)01=501
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10001(101)01=565
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10011(101)01=629
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10101(101)01=693
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10111(101)01=757
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11001(101)01=821
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11011(101)01=885
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11101(101)01=949
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11111(101)01=1013
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00000(101)10=022
    optabRow  62, 03, %0010, MRPrimUpdLoad,    MRSecCacheWang   ; Xopcd=00010(101)10=086
    optabRow  22, 09, %0000, MRPrimPlainStore, MRSecSTWCX       ; Xopcd=00100(101)10=150=STWCX.
    optabRow  23, 16, %0000, MRCrash,          MRSecFail        ; Xopcd=00110(101)10=214
    optabRow  62, 03, %0010, MRPrimUpdLoad,    MRSecCacheWang   ; Xopcd=01000(101)10=278=DCBT
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01010(101)10=342
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01100(101)10=406
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01110(101)10=470
    optabRow  10, 09, %0010, MRPrimUpdLoad,    MRSecLWBRX       ; Xopcd=10000(101)10=534=LWBRX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10010(101)10=598
    optabRow  18, 08, %0000, MRPrimSTWBRX,     MRExit           ; Xopcd=10100(101)10=662=STWBRX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10110(101)10=726
    optabRow  09, 05, %0010, MRPrimUpdLoad,    MRSecLHBRX       ; Xopcd=11000(101)10=790=LHBRX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11010(101)10=854
    optabRow  17, 04, %0000, MRPrimSTHBRX,     MRExit           ; Xopcd=11100(101)10=918=STHBRX
    optabRow  62, 03, %0010, MRPrimUpdLoad,    MRSecCacheWang   ; Xopcd=11110(101)10=982=ICBI
    optabRow  62, 03, %0010, MRPrimUpdLoad,    MRSecCacheWang   ; Xopcd=00001(101)10=054=DCBST
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00011(101)10=118
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=00101(101)10=182
    optabRow  62, 03, %0010, MRPrimUpdLoad,    MRSecCacheWang   ; Xopcd=00111(101)10=246=DCBTST
    optabRow  63, 01, %0000, MRPrimPlainLoad,  MRIOInstFail     ; Xopcd=01001(101)10=310=ECIWX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01011(101)10=374
    optabRow  63, 00, %0000, MRPrimPlainStore, MRIOInstFail     ; Xopcd=01101(101)10=438=ECOWX
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=01111(101)10=502
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10001(101)10=566
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10011(101)10=630
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10101(101)10=694
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=10111(101)10=758
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11001(101)10=822
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11011(101)10=886
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11101(101)10=950
    optabRow  48, 16, %0010, MRPrimDCBZ,       MRSecDCBZ        ; Xopcd=11111(101)10=1014=DCBZ
MROptabD
    optabRow  02, 09, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=00000(101)11=023=LWZX   Dopcd=(1)00000=32=LWZ
    optabRow  00, 03, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=00010(101)11=087=LBZX   Dopcd=(1)00010=34=LBZ
    optabRow  18, 08, %0000, MRPrimPlainStore, MRExit           ; Xopcd=00100(101)11=151=STWX   Dopcd=(1)00100=36=STW
    optabRow  16, 02, %0000, MRPrimPlainStore, MRExit           ; Xopcd=00110(101)11=215=STBX   Dopcd=(1)00110=38=STB
    optabRow  01, 05, %0000, MRPrimPlainLoad,  MRSecLoad        ; Xopcd=01000(101)11=279=LHZX   Dopcd=(1)01000=40=LHZ
    optabRow  05, 05, %0000, MRPrimPlainLoad,  MRSecLoadExt     ; Xopcd=01010(101)11=343=LHAX   Dopcd=(1)01010=42=LHA
    optabRow  17, 04, %0000, MRPrimPlainStore, MRExit           ; Xopcd=01100(101)11=407=STHX   Dopcd=(1)01100=44=STH
    optabRow  26, 09, %0011, MRPrimUpdLoad,    MRSecLMW         ; Xopcd=01110(101)11=471        Dopcd=(1)01110=46=LMW
    optabRow  14, 09, %0000, MRPrimPlainLoad,  MRSecLFSu        ; Xopcd=10000(101)11=535=LFSX   Dopcd=(1)10000=48=LFS
    optabRow  15, 17, %0000, MRPrimPlainLoad,  MRSecLFDu        ; Xopcd=10010(101)11=599=LFDX   Dopcd=(1)10010=50=LFD
    optabRow  18, 08, %0000, MRPrimSTFSx,      MRExit           ; Xopcd=10100(101)11=663=STFSX  Dopcd=(1)10100=52=STFS
    optabRow  19, 16, %0000, MRPrimSTFDx,      MRExit           ; Xopcd=10110(101)11=727=STFDX  Dopcd=(1)10110=54=STFD
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11000(101)11=791        Dopcd=(1)11000=56
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11010(101)11=855        Dopcd=(1)11010=58
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11100(101)11=919        Dopcd=(1)11100=60
    optabRow  18, 08, %0000, MRPrimSTFDx,      MRExit           ; Xopcd=11110(101)11=983=STFIWX Dopcd=(1)11110=62
    optabRow  02, 09, %0000, MRPrimUpdLoad,    MRSecLoad        ; Xopcd=00001(101)11=055=LWZUX  Dopcd=(1)00001=33=LWZU
    optabRow  00, 03, %0000, MRPrimUpdLoad,    MRSecLoad        ; Xopcd=00011(101)11=119=LBZUX  Dopcd=(1)00011=35=LBZU
    optabRow  18, 08, %0000, MRPrimUpdStore,   MRExit           ; Xopcd=00101(101)11=183=STWUX  Dopcd=(1)00101=37=STWU
    optabRow  16, 02, %0000, MRPrimUpdStore,   MRExit           ; Xopcd=00111(101)11=247=STBUX  Dopcd=(1)00111=39=STBU
    optabRow  01, 05, %0000, MRPrimUpdLoad,    MRSecLoad        ; Xopcd=01001(101)11=311=LHZUX  Dopcd=(1)01001=41=LHZU
    optabRow  05, 05, %0000, MRPrimUpdLoad,    MRSecLoadExt     ; Xopcd=01011(101)11=375=LHAUX  Dopcd=(1)01011=43=LHAU
    optabRow  17, 04, %0000, MRPrimUpdStore,   MRExit           ; Xopcd=01101(101)11=439=STHUX  Dopcd=(1)01101=45=STHU
    optabRow  30, 08, %0010, MRPrimUpdStore,   MRSecSTMW        ; Xopcd=01111(101)11=503        Dopcd=(1)01111=47=STMW
    optabRow  14, 09, %0000, MRPrimUpdLoad,    MRSecLFSu        ; Xopcd=10001(101)11=567=LFSUX  Dopcd=(1)10001=49=LFSU
    optabRow  15, 17, %0000, MRPrimUpdLoad,    MRSecLFDu        ; Xopcd=10011(101)11=631=LFDUX  Dopcd=(1)10011=51=LFDU
    optabRow  18, 08, %0000, MRPrimSTFSUx,     MRExit           ; Xopcd=10101(101)11=695=STFSUX Dopcd=(1)10101=53=STFSU
    optabRow  19, 16, %0000, MRPrimSTFDUx,     MRExit           ; Xopcd=10111(101)11=759=STFDUX Dopcd=(1)10111=55=STFDU
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11001(101)11=823        Dopcd=(1)11001=57
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11011(101)11=887        Dopcd=(1)11011=59
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11101(101)11=951        Dopcd=(1)11101=61
    optabRow  63, 01, %0000, MRCrash,          MRSecFail        ; Xopcd=11111(101)11=1015       Dopcd=(1)11111=63
