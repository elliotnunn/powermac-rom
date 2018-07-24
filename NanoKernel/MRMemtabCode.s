; Each routine accepts:
;  r17 = pretend inst with (byteCount-1) in bits 28-30 (will be decremented)
;  r19 = address of byte to the right of the string to be loaded/saved
;  r26 as a scratch register
;  r20/r21 = right-justified data (stores only)

; Before jumping to MRDoneMemAccess or one of the MRFast paths, each routine sets:
;  r20/r21 = right-justified data (loads only)
;  r17 has byteCount field decremented
;  r26 = junk, not to be trusted

########################################################################

MRLoad1241
    lbz     r26, -8(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 0

MRLoad241
    lhz     r26, -7(r19)
    subi    r17, r17, 4
    insrwi  r20, r26, 16, 8
    b       MRLoad41

MRLoad141
    lbz     r26, -6(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 16

MRLoad41
    lwz     r26, -5(r19)
    subi    r17, r17, 8
    inslwi  r20, r26, 8, 24
    insrwi  r21, r26, 24, 0
    b       MRLoad1

MRLoad1421
    lbz     r26, -8(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 0

MRLoad421
    lwz     r26, -7(r19)
    subi    r17, r17, 8
    inslwi  r20, r26, 24, 8
    insrwi  r21, r26, 8, 0
    b       MRLoad21

MRLoad1221
    lbz     r26, -6(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 16

MRLoad221
    lhz     r26, -5(r19)
    subi    r17, r17, 4
    rlwimi  r20, r26, 24, 24, 31
    insrwi  r21, r26, 8, 0
    b       MRLoad21

MRLoad121
    lbz     r26, -4(r19)
    subi    r17, r17, 2
    insrwi  r21, r26, 8, 0

MRLoad21
    lhz     r26, -3(r19)
    subi    r17, r17, 4
    insrwi  r21, r26, 16, 8
    b       MRLoad1

MRLoad11
    lbz     r26, -2(r19)
    subi    r17, r17, 2
    insrwi  r21, r26, 8, 16

MRLoad1
    lbz     r26, -1(r19)
    insrwi  r21, r26, 8, 24
    b       MRDoneMemAccess

MRLoad242
    lhz     r26, -8(r19)
    subi    r17, r17, 4
    insrwi  r20, r26, 16, 0
    b       MRLoad42

MRLoad142
    lbz     r26, -7(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 8

MRLoad42
    lwz     r26, -6(r19)
    subi    r17, r17, 8
    inslwi  r20, r26, 16, 16
    insrwi  r21, r26, 16, 0
    b       MRLoad2Fast

MRLoad122
    lbz     r26, -5(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 24
    b       MRLoad22Fast

MRLoad12
    lbz     r26, -3(r19)
    subi    r17, r17, 2
    insrwi  r21, r26, 8, 8
    b       MRLoad2Fast

MRLoad44
    lwz     r20, -8(r19)
    subi    r17, r17, 8
    lwz     r21, -4(r19)
    b       MRDoneMemAccess

MRLoad124
    lbz     r26, -7(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 8

MRLoad24
    lhz     r26, -6(r19)
    subi    r17, r17, 4
    insrwi  r20, r26, 16, 16
    lwz     r21, -4(r19)
    b       MRDoneMemAccess

MRLoad14
    lbz     r26, -5(r19)
    subi    r17, r17, 2
    insrwi  r20, r26, 8, 24
    lwz     r21, -4(r19)
    b       MRDoneMemAccess

MRLoad8
    lwz     r20, -8(r19)
    lwz     r21, -4(r19)
    b       MRDoneMemAccess

########################################################################

MRStore1241
    srwi    r26, r20, 24
    stb     r26, -8(r19)
    subi    r17, r17, 2

MRStore241
    srwi    r26, r20, 8
    sth     r26, -7(r19)
    subi    r17, r17, 4
    b       MRStore41

MRStore141
    srwi    r26, r20, 8
    stb     r26, -6(r19)
    subi    r17, r17, 2

MRStore41
    srwi    r26, r21, 8
    insrwi  r26, r20, 8, 0
    stw     r26, -5(r19)
    subi    r17, r17, 8
    stb     r21, -1(r19)
    b       MRDoneMemAccess

MRStore1421
    srwi    r26, r20, 24
    stb     r26, -8(r19)
    subi    r17, r17, 2

MRStore421
    srwi    r26, r21, 24
    insrwi  r26, r20, 24, 0
    stw     r26, -7(r19)
    subi    r17, r17, 8
    b       MRStore21

MRStore1221
    srwi    r26, r20, 8
    stb     r26, -6(r19)
    subi    r17, r17, 2

MRStore221
    srwi    r26, r21, 24
    insrwi  r26, r20, 8, 16
    sth     r26, -5(r19)
    subi    r17, r17, 4
    b       MRStore21

MRStore121
    srwi    r26, r21, 24
    stb     r26, -4(r19)
    subi    r17, r17, 2

MRStore21
    srwi    r26, r21, 8
    sth     r26, -3(r19)
    subi    r17, r17, 4
    stb     r21, -1(r19)
    b       MRDoneMemAccess

MRStore11
    srwi    r26, r21, 8
    stb     r26, -2(r19)
    subi    r17, r17, 2

MRStore1
    stb     r21, -1(r19)
    b       MRDoneMemAccess

MRStore242
    srwi    r26, r20, 16
    sth     r26, -8(r19)
    subi    r17, r17, 4
    b       MRStore42

MRStore142
    srwi    r26, r20, 16
    stb     r26, -7(r19)
    subi    r17, r17, 2

MRStore42
    srwi    r26, r21, 16
    insrwi  r26, r20, 16, 0
    stw     r26, -6(r19)
    subi    r17, r17, 8
    sth     r21, -2(r19)
    b       MRDoneMemAccess

MRStore122
    stb     r20, -5(r19)
    subi    r17, r17, 2
    b       MRStore22Fast

MRStore12
    srwi    r26, r21, 16
    stb     r26, -3(r19)
    subi    r17, r17, 2

MRStore2
    sth     r21, -2(r19)
    b       MRDoneMemAccess

MRStore44
    stw     r20, -8(r19)
    subi    r17, r17, 8
    stw     r21, -4(r19)
    b       MRDoneMemAccess

MRStore124
    srwi    r26, r20, 16
    stb     r26, -7(r19)
    subi    r17, r17, 2

MRStore24
    sth     r20, -6(r19)
    subi    r17, r17, 4
    stw     r21, -4(r19)
    b       MRDoneMemAccess

MRStore14
    stb     r20, -5(r19)
    subi    r17, r17, 2
    stw     r21, -4(r19)
    b       MRDoneMemAccess

MRStore8
    stw     r20, -8(r19)
    stw     r21, -4(r19)
    b       MRDoneMemAccess
