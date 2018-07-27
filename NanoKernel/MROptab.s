    MACRO
    optabRow &upperSix, &lowerSix, &flags, &primLabel, &secLabel
    IF &TYPE('&upperSix') = 'UNDEFINED'                               ; 0-5 lowerSix
orUpperSix set 63
    ELSE
orUpperSix set &upperSix
    ENDIF

    IF &TYPE('&lowerSix') = 'UNDEFINED'                               ; 6-11 upperSix
orLowerSix set 1
    ELSE
orLowerSix set &lowerSix
    ENDIF

    IF &TYPE('&flags') = 'UNDEFINED'                                  ; 12-15 flags
orFlags set 1
    ELSE
orFlags set &flags
    ENDIF

    DC.W (orLowerSix << 10) | (orUpperSix << 4) | orFlags

    IF &TYPE('&primLabel') = 'UNDEFINED'                              ; 16-23 primary routine
        DC.B (MRPriCrash - MRBase) >> 2
    ELSE
        DC.B (&primLabel - MRBase) >> 2
    ENDIF
    IF &TYPE('&secLabel') = 'UNDEFINED'                               ; 24-31 secondary routine
        DC.B (MRSecException - MRBase) >> 2
    ELSE
        DC.B (&secLabel - MRBase) >> 2
    ENDIF
    ENDM

; LEGEND      .. metatab index (r17 bits 0-5, dflt=63)
;                  .... access size (r17 bits 27-30) and (L)oad/(S)tore (r17 bit 31)
;
;                        . mrOpflag1        }
;                         . mrOpflag2       } cr3 flags,
;                          . mrOpflag3      } all unset by default
;                           . mrFlagDidLoad }
;
;                              primary routine   secondary routine  X-form extended opcode  D-form opcode
;                              (dflt=MRPriCrash) (dflt=MRSecExc'n)
;                              ................  ................   ....................... .................

MROptabX
    optabRow  20,  4,L, %0000, MRPriPlainLoad,   MRSecLWARX       ; 00000(101)00=020=LWARX                       metatabLine  %0001, MRSecLWARX       ; 20
    optabRow  21,  8,L, %0000, MRPriCrash,       MRSecException   ; 00010(101)00=084=LDARX                       metatabLine  %0001, MRSecException   ; 21
    optabRow  ,    ,,   ,      ,                                  ; 00100(101)00=148
    optabRow  ,    ,,   ,      ,                                  ; 00110(101)00=212
    optabRow  ,    ,,   ,      ,                                  ; 01000(101)00=276
    optabRow  ,    ,,   ,      ,                                  ; 01010(101)00=340
    optabRow  ,    ,,   ,      ,                                  ; 01100(101)00=404
    optabRow  ,    ,,   ,      ,                                  ; 01110(101)00=468
    optabRow  ,    ,,   ,      ,                                  ; 10000(101)00=532
    optabRow  ,    ,,   ,      ,                                  ; 10010(101)00=596
    optabRow  ,    ,,   ,      ,                                  ; 10100(101)00=660
    optabRow  ,    ,,   ,      ,                                  ; 10110(101)00=724
    optabRow  3,   8,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 11000(101)00=788                             metatabLine  %0001, MRSecLoad        ; 3
    optabRow  6,   4,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 11010(101)00=852                             metatabLine  %0001, MRSecLoad        ; 6
    optabRow  19,  8,S, %0000, MRPriPlainStore,  MRSecDone        ; 11100(101)00=916                             metatabLine  %0001, MRSecDone        ; 19
    optabRow  ,    ,,   ,      ,                                  ; 11110(101)00=980
    optabRow  ,    ,,   ,      ,                                  ; 00001(101)00=052
    optabRow  ,    ,,   ,      ,                                  ; 00011(101)00=116
    optabRow  ,    ,,   ,      ,                                  ; 00101(101)00=180
    optabRow  ,    ,,   ,      ,                                  ; 00111(101)00=244
    optabRow  ,    ,,   ,      ,                                  ; 01001(101)00=308
    optabRow  ,    ,,   ,      ,                                  ; 01011(101)00=372
    optabRow  ,    ,,   ,      ,                                  ; 01101(101)00=436
    optabRow  ,    ,,   ,      ,                                  ; 01111(101)00=500
    optabRow  ,    ,,   ,      ,                                  ; 10001(101)00=564
    optabRow  ,    ,,   ,      ,                                  ; 10011(101)00=628
    optabRow  ,    ,,   ,      ,                                  ; 10101(101)00=692
    optabRow  ,    ,,   ,      ,                                  ; 10111(101)00=756
    optabRow  3,   8,L, %0000, MRPriUpdLoad,     MRSecLoad        ; 11001(101)00=820                             metatabLine  %0001, MRSecLoad        ; 3
    optabRow  27,  8,L, %0011, MRPriCrash,       MRSecException   ; 11011(101)00=884                             metatabLine  %0011, MRSecException   ; 27
    optabRow  19,  8,S, %0000, MRPriUpdStore,    MRSecDone        ; 11101(101)00=948                             metatabLine  %0001, MRSecDone        ; 19
    optabRow  31,  8,S, %0010, MRPriCrash,       MRSecException   ; 11111(101)00=1012                            metatabLine  %0011, MRSecException   ; 31
    optabRow  3,   8,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 00000(101)01=021=LDX                         metatabLine  %0001, MRSecLoad        ; 3
    optabRow  ,    ,,   ,      ,                                  ; 00010(101)01=085
    optabRow  19,  8,S, %0000, MRPriPlainStore,  MRSecDone        ; 00100(101)01=149=STDX                        metatabLine  %0001, MRSecDone        ; 19
    optabRow  ,    ,,   ,      ,                                  ; 00110(101)01=213
    optabRow  40,  4,L, %1011, MRPriLSCBX,       MRSecLSCBX       ; 01000(101)01=277=LSCBX (POWER)               metatabLine  %0011, MRSecLSCBX       ; 40
    optabRow  6,   4,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 01010(101)01=341=LWAX                        metatabLine  %0001, MRSecLoad        ; 6
    optabRow  ,    ,,   ,      ,                                  ; 01100(101)01=405
    optabRow  ,    ,,   ,      ,                                  ; 01110(101)01=469
    optabRow  32,  4,L, %1011, MRPriLSWX,        MRSecLSWix       ; 10000(101)01=533=LSWX                        metatabLine  %0011, MRSecLSWix       ; 32
    optabRow  32,  4,L, %1111, MRPriLSWI,        MRSecLSWix       ; 10010(101)01=597=LSWI                        metatabLine  %0011, MRSecLSWix       ; 32
    optabRow  36,  4,S, %0010, MRPriSTSWX,       MRSecStrStore    ; 10100(101)01=661=STSWX                       metatabLine  %0011, MRSecStrStore    ; 36
    optabRow  36,  4,S, %1110, MRPriSTSWI,       MRSecStrStore    ; 10110(101)01=725=STSWI                       metatabLine  %0011, MRSecStrStore    ; 36
    optabRow  ,    ,,   ,      ,                                  ; 11000(101)01=789
    optabRow  ,    ,,   ,      ,                                  ; 11010(101)01=853
    optabRow  ,    ,,   ,      ,                                  ; 11100(101)01=917
    optabRow  ,    ,,   ,      ,                                  ; 11110(101)01=981
    optabRow  3,   8,L, %0000, MRPriUpdLoad,     MRSecLoad        ; 00001(101)01=053=LDUX                        metatabLine  %0001, MRSecLoad        ; 3
    optabRow  ,    ,,   ,      ,                                  ; 00011(101)01=117
    optabRow  19,  8,S, %0000, MRPriUpdStore,    MRSecDone        ; 00101(101)01=181=STDUX                       metatabLine  %0001, MRSecDone        ; 19
    optabRow  ,    ,,   ,      ,                                  ; 00111(101)01=245
    optabRow  ,    ,,   ,      ,                                  ; 01001(101)01=309
    optabRow  6,   4,L, %0000, MRPriUpdLoad,     MRSecDone        ; 01011(101)01=373=LWAUX                       metatabLine  %0001, MRSecLoad        ; 6
    optabRow  ,    ,,   ,      ,                                  ; 01101(101)01=437
    optabRow  ,    ,,   ,      ,                                  ; 01111(101)01=501
    optabRow  ,    ,,   ,      ,                                  ; 10001(101)01=565
    optabRow  ,    ,,   ,      ,                                  ; 10011(101)01=629
    optabRow  ,    ,,   ,      ,                                  ; 10101(101)01=693
    optabRow  ,    ,,   ,      ,                                  ; 10111(101)01=757
    optabRow  ,    ,,   ,      ,                                  ; 11001(101)01=821
    optabRow  ,    ,,   ,      ,                                  ; 11011(101)01=885
    optabRow  ,    ,,   ,      ,                                  ; 11101(101)01=949
    optabRow  ,    ,,   ,      ,                                  ; 11111(101)01=1013
    optabRow  ,    ,,   ,      ,                                  ; 00000(101)10=022
    optabRow  62,  1,L, %0010, MRPriUpdLoad,     MRSecRedoNoTrace ; 00010(101)10=086                             metatabLine  %0011, MRSecRedoNoTrace ; 62
    optabRow  22,  4,L, %0000, MRPriPlainStore,  MRSecSTWCX       ; 00100(101)10=150=STWCX.                      metatabLine  %0001, MRSecSTWCX       ; 22
    optabRow  23,  8,S, %0000, MRPriCrash,       MRSecException   ; 00110(101)10=214=STDCX.                      metatabLine  %0001, MRSecException   ; 23
    optabRow  62,  1,L, %0010, MRPriUpdLoad,     MRSecRedoNoTrace ; 01000(101)10=278=DCBT                        metatabLine  %0011, MRSecRedoNoTrace ; 62
    optabRow  ,    ,,   ,      ,                                  ; 01010(101)10=342
    optabRow  ,    ,,   ,      ,                                  ; 01100(101)10=406
    optabRow  ,    ,,   ,      ,                                  ; 01110(101)10=470
    optabRow  10,  4,L, %0010, MRPriUpdLoad,     MRSecLWBRX       ; 10000(101)10=534=LWBRX                       metatabLine  %0011, MRSecLWBRX       ; 10
    optabRow  ,    ,,   ,      ,                                  ; 10010(101)10=598
    optabRow  18,  4,S, %0000, MRPriSTWBRX,      MRSecDone        ; 10100(101)10=662=STWBRX                      metatabLine  %0001, MRSecDone        ; 18
    optabRow  ,    ,,   ,      ,                                  ; 10110(101)10=726
    optabRow  9,   2,L, %0010, MRPriUpdLoad,     MRSecLHBRX       ; 11000(101)10=790=LHBRX                       metatabLine  %0011, MRSecLHBRX       ; 9
    optabRow  ,    ,,   ,      ,                                  ; 11010(101)10=854
    optabRow  17,  2,S, %0000, MRPriSTHBRX,      MRSecDone        ; 11100(101)10=918=STHBRX                      metatabLine  %0001, MRSecDone        ; 17
    optabRow  62,  1,L, %0010, MRPriUpdLoad,     MRSecRedoNoTrace ; 11110(101)10=982=ICBI                        metatabLine  %0011, MRSecRedoNoTrace ; 62
    optabRow  62,  1,L, %0010, MRPriUpdLoad,     MRSecRedoNoTrace ; 00001(101)10=054=DCBST                       metatabLine  %0011, MRSecRedoNoTrace ; 62
    optabRow  ,    ,,   ,      ,                                  ; 00011(101)10=118
    optabRow  ,    ,,   ,      ,                                  ; 00101(101)10=182
    optabRow  62,  1,L, %0010, MRPriUpdLoad,     MRSecRedoNoTrace ; 00111(101)10=246=DCBTST                      metatabLine  %0011, MRSecRedoNoTrace ; 62
    optabRow  63,  0,L, %0000, MRPriPlainLoad,   MRSecException2  ; 01001(101)10=310=ECIWX                       metatabLine  %0001, MRSecException2  ; 63
    optabRow  ,    ,,   ,      ,                                  ; 01011(101)10=374
    optabRow  63,  0,S, %0000, MRPriPlainStore,  MRSecException2  ; 01101(101)10=438=ECOWX                       metatabLine  %0001, MRSecException2  ; 63
    optabRow  ,    ,,   ,      ,                                  ; 01111(101)10=502
    optabRow  ,    ,,   ,      ,                                  ; 10001(101)10=566
    optabRow  ,    ,,   ,      ,                                  ; 10011(101)10=630
    optabRow  ,    ,,   ,      ,                                  ; 10101(101)10=694
    optabRow  ,    ,,   ,      ,                                  ; 10111(101)10=758
    optabRow  ,    ,,   ,      ,                                  ; 11001(101)10=822
    optabRow  ,    ,,   ,      ,                                  ; 11011(101)10=886
    optabRow  ,    ,,   ,      ,                                  ; 11101(101)10=950
    optabRow  48,  8,S, %0010, MRPriDCBZ,        MRSecDCBZ        ; 11111(101)10=1014=DCBZ                       metatabLine  %0011, MRSecDCBZ        ; 48
MROptabD
    optabRow  2,   4,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 00000(101)11=023=LWZX    (1)00000=32=LWZ     metatabLine  %0001, MRSecLoad        ; 2
    optabRow  0,   1,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 00010(101)11=087=LBZX    (1)00010=34=LBZ     metatabLine  %0001, MRSecLoad        ; 0
    optabRow  18,  4,S, %0000, MRPriPlainStore,  MRSecDone        ; 00100(101)11=151=STWX    (1)00100=36=STW     metatabLine  %0001, MRSecDone        ; 18
    optabRow  16,  1,S, %0000, MRPriPlainStore,  MRSecDone        ; 00110(101)11=215=STBX    (1)00110=38=STB     metatabLine  %0001, MRSecDone        ; 16
    optabRow  1,   2,L, %0000, MRPriPlainLoad,   MRSecLoad        ; 01000(101)11=279=LHZX    (1)01000=40=LHZ     metatabLine  %0001, MRSecLoad        ; 1
    optabRow  5,   2,L, %0000, MRPriPlainLoad,   MRSecLoadExt     ; 01010(101)11=343=LHAX    (1)01010=42=LHA     metatabLine  %0001, MRSecLoadExt     ; 5
    optabRow  17,  2,S, %0000, MRPriPlainStore,  MRSecDone        ; 01100(101)11=407=STHX    (1)01100=44=STH     metatabLine  %0001, MRSecDone        ; 17
    optabRow  26,  4,L, %0011, MRPriUpdLoad,     MRSecLMW         ; 01110(101)11=471         (1)01110=46=LMW     metatabLine  %0011, MRSecLMW         ; 26
    optabRow  14,  4,L, %0000, MRPriPlainLoad,   MRSecLFSu        ; 10000(101)11=535=LFSX    (1)10000=48=LFS     metatabLine  %0001, MRSecLFSu        ; 14
    optabRow  15,  8,L, %0000, MRPriPlainLoad,   MRSecLFDu        ; 10010(101)11=599=LFDX    (1)10010=50=LFD     metatabLine  %0001, MRSecLFDu        ; 15
    optabRow  18,  4,S, %0000, MRPriSTFSx,       MRSecDone        ; 10100(101)11=663=STFSX   (1)10100=52=STFS    metatabLine  %0001, MRSecDone        ; 18
    optabRow  19,  8,S, %0000, MRPriSTFDx,       MRSecDone        ; 10110(101)11=727=STFDX   (1)10110=54=STFD    metatabLine  %0001, MRSecDone        ; 19
    optabRow  ,    ,,   ,      ,                                  ; 11000(101)11=791         (1)11000=56
    optabRow  ,    ,,   ,      ,                                  ; 11010(101)11=855         (1)11010=58
    optabRow  ,    ,,   ,      ,                                  ; 11100(101)11=919         (1)11100=60
    optabRow  18,  4,S, %0000, MRPriSTFDx,       MRSecDone        ; 11110(101)11=983=STFIWX  (1)11110=62         metatabLine  %0001, MRSecDone        ; 18
    optabRow  2,   4,L, %0000, MRPriUpdLoad,     MRSecLoad        ; 00001(101)11=055=LWZUX   (1)00001=33=LWZU    metatabLine  %0001, MRSecLoad        ; 2
    optabRow  0,   1,L, %0000, MRPriUpdLoad,     MRSecLoad        ; 00011(101)11=119=LBZUX   (1)00011=35=LBZU    metatabLine  %0001, MRSecLoad        ; 0
    optabRow  18,  4,S, %0000, MRPriUpdStore,    MRSecDone        ; 00101(101)11=183=STWUX   (1)00101=37=STWU    metatabLine  %0001, MRSecDone        ; 18
    optabRow  16,  1,S, %0000, MRPriUpdStore,    MRSecDone        ; 00111(101)11=247=STBUX   (1)00111=39=STBU    metatabLine  %0001, MRSecDone        ; 16
    optabRow  1,   2,L, %0000, MRPriUpdLoad,     MRSecLoad        ; 01001(101)11=311=LHZUX   (1)01001=41=LHZU    metatabLine  %0001, MRSecLoad        ; 1
    optabRow  5,   2,L, %0000, MRPriUpdLoad,     MRSecLoadExt     ; 01011(101)11=375=LHAUX   (1)01011=43=LHAU    metatabLine  %0001, MRSecLoadExt     ; 5
    optabRow  17,  2,S, %0000, MRPriUpdStore,    MRSecDone        ; 01101(101)11=439=STHUX   (1)01101=45=STHU    metatabLine  %0001, MRSecDone        ; 17
    optabRow  30,  4,S, %0010, MRPriUpdStore,    MRSecSTMW        ; 01111(101)11=503         (1)01111=47=STMW    metatabLine  %0011, MRSecSTMW        ; 30
    optabRow  14,  4,L, %0000, MRPriUpdLoad,     MRSecLFSu        ; 10001(101)11=567=LFSUX   (1)10001=49=LFSU    metatabLine  %0001, MRSecLFSu        ; 14
    optabRow  15,  8,L, %0000, MRPriUpdLoad,     MRSecLFDu        ; 10011(101)11=631=LFDUX   (1)10011=51=LFDU    metatabLine  %0001, MRSecLFDu        ; 15
    optabRow  18,  4,S, %0000, MRPriSTFSUx,      MRSecDone        ; 10101(101)11=695=STFSUX  (1)10101=53=STFSU   metatabLine  %0001, MRSecDone        ; 18
    optabRow  19,  8,S, %0000, MRPriSTFDUx,      MRSecDone        ; 10111(101)11=759=STFDUX  (1)10111=55=STFDU   metatabLine  %0001, MRSecDone        ; 19
    optabRow  ,    ,,   ,      ,                                  ; 11001(101)11=823         (1)11001=57
    optabRow  ,    ,,   ,      ,                                  ; 11011(101)11=887         (1)11011=59
    optabRow  ,    ,,   ,      ,                                  ; 11101(101)11=951         (1)11101=61
    optabRow  ,    ,,   ,      ,                                  ; 11111(101)11=1015        (1)11111=63
