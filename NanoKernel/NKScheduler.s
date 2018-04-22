Local_Panic		set		*
				b		panic



#### ##    ## #### ######## ########  ########  ##    ##  #######   ######  
 ##  ###   ##  ##     ##    ##     ## ##     ##  ##  ##  ##     ## ##    ## 
 ##  ####  ##  ##     ##    ##     ## ##     ##   ####   ##     ## ##       
 ##  ## ## ##  ##     ##    ########  ##     ##    ##    ##     ##  ######  
 ##  ##  ####  ##     ##    ##   ##   ##     ##    ##    ##  ## ##       ## 
 ##  ##   ###  ##     ##    ##    ##  ##     ##    ##    ##    ##  ##    ## 
#### ##    ## ####    ##    ##     ## ########     ##     ##### ##  ######  

;	Create the queues that hold unblocked tasks ready to be run.

;	There are four ready queues (RDYQs), all in the PSA:
;	1. critical
;	2. latency protection (newly unblocked tasks)
;	3. nominal
;	4. idle

;	Each one has a "time cake" that gets divided among its tasks.
;	For critical it is ~1ms, successively multiplying by 8.

SchInit

	li		r16, 0
	stw		r16, KDP.NanoKernelInfo + NKNanoKernelInfo.TaskCount(r1)

	mflr	r20

	;	Get a time doubleword approximating 1ms (for critical priority)
	li		r8, -1042			; negative args are in usec
	bl		TimebaseTicksPerPeriod
	mr		r16, r8				; hi
	mr		r17, r9				; lo

	mtlr	r20

	;	These priority flags (top 4 bits) denote the state of each queue
	li		r23, 0
	stw		r23, PSA.PriorityFlags(r1)


	;	Populate one RDYQ for each of the four task priorities
	addi	r9, r1, PSA.ReadyQueues

	;	r23 = index of queue, r16/r17 = time cake
@loop

	;	Empty linked list
	lisori	r8, ReadyQueue.kSignature
	stw		r8, LLL.Signature(r9)
	stw		r9, LLL.Next(r9)
	stw		r9, LLL.Prev(r9)

	;	... with a priority flag in its freeform field!
	lis		r8, 0x8000 ; ...0000
	srw		r8, r8, r23
	stw		r8, LLL.Freeform(r9)

	;	Zero some shit
	li		r8, 0
	stw		r8, ReadyQueue.Counter(r9)		; incremented by SchRdyTaskNow/Next
	stw		r8, ReadyQueue.TotalWeight(r9)	

	;	1ms for critical, successively 8x for other queues
	stw		r16, ReadyQueue.Timecake(r9)
	stw		r17, ReadyQueue.Timecake + 4(r9)

	;	Show off a bit
	mflr	r20

	_log	'Init ready queue '

	mr		r8, r23				; the priority (1,2,3,4)
	bl		printw

	mr		r8, r16				; the time cake
	bl		printw

	mr		r8, r17
	bl		printw

	_log	'^n'

	mtlr	r20

	;	Multiply time by 8 for the next iteration
	slwi	r16, r16, 3
	rlwimi	r16, r17, 3, 29, 31
	slwi	r17, r17, 3

	;	Only do four of these
	addi	r23, r23, 1
	cmpwi	r23, 4
	addi	r9, r9, 32 ;ReadyQueue.Size
	blt		@loop



	;	DO SOMETHING ELSE:

	;	If the low nybble is empty, set ContextBlock.PriorityShifty to 2.
	lwz		r16, KDP.PA_ECB(r1)
	lwz		r17, ContextBlock.PriorityShifty(r16)
	andi.	r9, r17, 0xF
	li		r17, 2
	bnelr

	stw		r17, ContextBlock.PriorityShifty(r16)
	blr



 ######     ###    ##     ## ########     ######   ########  ########   ######  
##    ##   ## ##   ##     ## ##          ##    ##  ##     ## ##     ## ##    ## 
##        ##   ##  ##     ## ##          ##        ##     ## ##     ## ##       
 ######  ##     ## ##     ## ######      ##   #### ########  ########   ######  
      ## #########  ##   ##  ##          ##    ##  ##        ##   ##         ## 
##    ## ##     ##   ## ##   ##          ##    ##  ##        ##    ##  ##    ## 
 ######  ##     ##    ###    ########     ######   ##        ##     ##  ######  

;	...to (ECB *)r6
;	(and also copy SPRG0 to r8)

SchSaveStartingAtR14
	li			r8, ContextBlock.r16 & -32
	dcbtst		r8, r6
		stw		r14, ContextBlock.r14(r6)
		stw		r15, ContextBlock.r15(r6)

SchSaveStartingAtR16
	li			r8, ContextBlock.r20 & -32
		stw		r16, ContextBlock.r16(r6)
	dcbtst		r8, r6
		stw		r17, ContextBlock.r17(r6)
		stw		r18, ContextBlock.r18(r6)
		stw		r19, ContextBlock.r19(r6)

SchSaveStartingAtR20
	li			r8, ContextBlock.r24 & -32
		stw		r20, ContextBlock.r20(r6)
	dcbtst		r8, r6
		stw		r21, ContextBlock.r21(r6)
		stw		r22, ContextBlock.r22(r6)
		stw		r23, ContextBlock.r23(r6)

SchSaveStartingAtR24
	li			r8, ContextBlock.r28 & -32
		stw		r24, ContextBlock.r24(r6)
	dcbtst		r8, r6
		stw		r25, ContextBlock.r25(r6)
		stw		r26, ContextBlock.r26(r6)
		stw		r27, ContextBlock.r27(r6)
		stw		r28, ContextBlock.r28(r6)
		stw		r29, ContextBlock.r29(r6)
		stw		r30, ContextBlock.r30(r6)
		stw		r31, ContextBlock.r31(r6)

	mfsprg		r8, 0
	blr



##        #######     ###    ########      ######   ########  ########   ######  
##       ##     ##   ## ##   ##     ##    ##    ##  ##     ## ##     ## ##    ## 
##       ##     ##  ##   ##  ##     ##    ##        ##     ## ##     ## ##       
##       ##     ## ##     ## ##     ##    ##   #### ########  ########   ######  
##       ##     ## ######### ##     ##    ##    ##  ##        ##   ##         ## 
##       ##     ## ##     ## ##     ##    ##    ##  ##        ##    ##  ##    ## 
########  #######  ##     ## ########      ######   ##        ##     ##  ######  

;	...from (ECB *)r6

SchRestoreStartingAtR14
	li			r31, ContextBlock.r16 & -32
	dcbt		r31, r6
		lwz		r14, ContextBlock.r14(r6)
		lwz		r15, ContextBlock.r15(r6)

SchRestoreStartingAtR16
	li			r31, ContextBlock.r20 & -32
		lwz		r16, ContextBlock.r16(r6)
	dcbt		r31, r6
		lwz		r17, ContextBlock.r17(r6)
		lwz		r18, ContextBlock.r18(r6)
		lwz		r19, ContextBlock.r19(r6)

SchRestoreStartingAtR20
	li			r31, ContextBlock.r24 & -32
		lwz		r20, ContextBlock.r20(r6)
	dcbt		r31, r6
		lwz		r21, ContextBlock.r21(r6)
		lwz		r22, ContextBlock.r22(r6)
		lwz		r23, ContextBlock.r23(r6)

SchRestoreStartingAtR24
	li			r31, ContextBlock.r28 & -32
		lwz		r24, ContextBlock.r24(r6)
	dcbt		r31, r6
		lwz		r25, ContextBlock.r25(r6)
		lwz		r26, ContextBlock.r26(r6)
		lwz		r27, ContextBlock.r27(r6)
		lwz		r28, ContextBlock.r28(r6)
		lwz		r29, ContextBlock.r29(r6)
		lwz		r30, ContextBlock.r30(r6)
		lwz		r31, ContextBlock.r31(r6)

	blr



 ######     ###    ##     ## ########    ######## ########  ########   ######  
##    ##   ## ##   ##     ## ##          ##       ##     ## ##     ## ##    ## 
##        ##   ##  ##     ## ##          ##       ##     ## ##     ## ##       
 ######  ##     ## ##     ## ######      ######   ########  ########   ######  
      ## #########  ##   ##  ##          ##       ##        ##   ##         ## 
##    ## ##     ##   ## ##   ##          ##       ##        ##    ##  ##    ## 
 ######  ##     ##    ###    ########    ##       ##        ##     ##  ######  

;	...to (ECB *)r6
;	(but first set the MSR_FP bit in MSR, but *unset* it in r11)

Save_f0_f31
	mfmsr	r8
	rlwinm	r11, r11, 0, MSR_FPbit+1, MSR_FPbit-1
	_bset	r8, r8, MSR_FPbit
	mtmsr	r8
	isync

	li		r8,  0x220
	stfd	f0,  0x0200(r6)
	dcbtst	r8, r6
	stfd	f1,  0x0208(r6)
	stfd	f2,  0x0210(r6)
	stfd	f3,  0x0218(r6)
	li		r8,  0x240
	stfd	f4,  0x0220(r6)
	dcbtst	r8, r6
	stfd	f5,  0x0228(r6)
	stfd	f6,  0x0230(r6)
	stfd	f7,  0x0238(r6)
	li		r8,  0x260
	stfd	f8,  0x0240(r6)
	dcbtst	r8, r6
	stfd	f9,  0x0248(r6)
	stfd	f10,  0x0250(r6)
	stfd	f11,  0x0258(r6)
	li		r8, 640
	stfd	f12,  0x0260(r6)
	dcbtst	r8, r6
	stfd	f13,  0x0268(r6)
	stfd	f14,  0x0270(r6)
	stfd	f15,  0x0278(r6)
	li		r8,  0x2a0
	stfd	f16,  0x0280(r6)
	dcbtst	r8, r6
	stfd	f17,  0x0288(r6)
	stfd	f18,  0x0290(r6)
	stfd	f19,  0x0298(r6)
	li		r8,  0x2c0
	stfd	f20,  0x02a0(r6)
	dcbtst	r8, r6
	stfd	f21,  0x02a8(r6)
	stfd	f22,  0x02b0(r6)
	stfd	f23,  0x02b8(r6)
	li		r8,  0x2e0
	stfd	f24,  0x02c0(r6)
	dcbtst	r8, r6
	stfd	f25,  0x02c8(r6)
	stfd	f26,  0x02d0(r6)
	stfd	f27,  0x02d8(r6)
	mffs	f0
	stfd	f28,  0x02e0(r6)
	stfd	f29,  0x02e8(r6)
	stfd	f30,  0x02f0(r6)
	stfd	f31,  0x02f8(r6)
	stfd	f0,  0x00e0(r6)
	blr



##        #######     ###    ########     ##     ## ########   ######  
##       ##     ##   ## ##   ##     ##    ##     ## ##     ## ##    ## 
##       ##     ##  ##   ##  ##     ##    ##     ## ##     ## ##       
##       ##     ## ##     ## ##     ##    ##     ## ########   ######  
##       ##     ## ######### ##     ##     ##   ##  ##   ##         ## 
##       ##     ## ##     ## ##     ##      ## ##   ##    ##  ##    ## 
########  #######  ##     ## ########        ###    ##     ##  ######  

Restore_v0_v31	;	OUTSIDE REFERER
	li		r8,  0x200
	mfspr	r11, vrsave
	lvxl	v0, r8, r10
	mtcr	r11
	mtvscr	v0
	lwz		r8, -0x0004(r1)
	li		r9, PSA.VectorRegInitWord
	lvx		v31, r8, r9
	vor		v0, v31, v31
	bge		major_0x13988_0x108
	li		r8,  0x00
	lvx		v0, r8, r10

major_0x13988_0x108
	vor		v1, v31, v31
	ble		major_0x13988_0x118
	li		r9,  0x10
	lvx		v1, r9, r10

major_0x13988_0x118
	vor		v2, v31, v31
	bne		major_0x13988_0x128
	li		r8,  0x20
	lvx		v2, r8, r10

major_0x13988_0x128
	vor		v3, v31, v31
	bns		major_0x13988_0x138
	li		r9,  0x30
	lvx		v3, r9, r10

major_0x13988_0x138
	vor		v4, v31, v31
	bge		cr1, major_0x13988_0x148
	li		r8,  0x40
	lvx		v4, r8, r10

major_0x13988_0x148
	vor		v5, v31, v31
	ble		cr1, major_0x13988_0x158
	li		r9,  0x50
	lvx		v5, r9, r10

major_0x13988_0x158
	vor		v6, v31, v31
	bne		cr1, major_0x13988_0x168
	li		r8,  0x60
	lvx		v6, r8, r10

major_0x13988_0x168
	vor		v7, v31, v31
	bns		cr1, major_0x13988_0x178
	li		r9,  0x70
	lvx		v7, r9, r10

major_0x13988_0x178
	vor		v8, v31, v31
	bge		cr2, major_0x13988_0x188
	li		r8,  0x80
	lvx		v8, r8, r10

major_0x13988_0x188
	vor		v9, v31, v31
	ble		cr2, major_0x13988_0x198
	li		r9,  0x90
	lvx		v9, r9, r10

major_0x13988_0x198
	vor		v10, v31, v31
	bne		cr2, major_0x13988_0x1a8
	li		r8, 160
	lvx		v10, r8, r10

major_0x13988_0x1a8
	vor		v11, v31, v31
	bns		cr2, major_0x13988_0x1b8
	li		r9,  0xb0
	lvx		v11, r9, r10

major_0x13988_0x1b8
	vor		v12, v31, v31
	bge		cr3, major_0x13988_0x1c8
	li		r8,  0xc0
	lvx		v12, r8, r10

major_0x13988_0x1c8
	vor		v13, v31, v31
	ble		cr3, major_0x13988_0x1d8
	li		r9,  0xd0
	lvx		v13, r9, r10

major_0x13988_0x1d8
	vor		v14, v31, v31
	bne		cr3, major_0x13988_0x1e8
	li		r8,  0xe0
	lvx		v14, r8, r10

major_0x13988_0x1e8
	vor		v15, v31, v31
	bns		cr3, major_0x13988_0x1f8
	li		r9, 240
	lvx		v15, r9, r10

major_0x13988_0x1f8
	vor		v16, v31, v31
	bge		cr4, major_0x13988_0x208
	li		r8,  0x100
	lvx		v16, r8, r10

major_0x13988_0x208
	vor		v17, v31, v31
	ble		cr4, major_0x13988_0x218
	li		r9,  0x110
	lvx		v17, r9, r10

major_0x13988_0x218
	vor		v18, v31, v31
	bne		cr4, major_0x13988_0x228
	li		r8,  0x120
	lvx		v18, r8, r10

major_0x13988_0x228
	vor		v19, v31, v31
	bns		cr4, major_0x13988_0x238
	li		r9,  0x130
	lvx		v19, r9, r10

major_0x13988_0x238
	vor		v20, v31, v31
	bge		cr5, major_0x13988_0x248
	li		r8, 320
	lvx		v20, r8, r10

major_0x13988_0x248
	vor		v21, v31, v31
	ble		cr5, major_0x13988_0x258
	li		r9,  0x150
	lvx		v21, r9, r10

major_0x13988_0x258
	vor		v22, v31, v31
	bne		cr5, major_0x13988_0x268
	li		r8,  0x160
	lvx		v22, r8, r10

major_0x13988_0x268
	vor		v23, v31, v31
	bns		cr5, major_0x13988_0x278
	li		r9,  0x170
	lvx		v23, r9, r10

major_0x13988_0x278
	vor		v24, v31, v31
	bge		cr6, major_0x13988_0x288
	li		r8,  0x180
	lvx		v24, r8, r10

major_0x13988_0x288
	vor		v25, v31, v31
	ble		cr6, major_0x13988_0x298
	li		r9, 400
	lvx		v25, r9, r10

major_0x13988_0x298
	vor		v26, v31, v31
	bne		cr6, major_0x13988_0x2a8
	li		r8,  0x1a0
	lvx		v26, r8, r10

major_0x13988_0x2a8
	vor		v27, v31, v31
	bns		cr6, major_0x13988_0x2b8
	li		r9,  0x1b0
	lvx		v27, r9, r10

major_0x13988_0x2b8
	vor		v28, v31, v31
	bge		cr7, major_0x13988_0x2c8
	li		r8,  0x1c0
	lvx		v28, r8, r10

major_0x13988_0x2c8
	vor		v29, v31, v31
	ble		cr7, major_0x13988_0x2d8
	li		r9,  0x1d0
	lvx		v29, r9, r10

major_0x13988_0x2d8
	vor		v30, v31, v31
	bne		cr7, major_0x13988_0x2e8
	li		r8, 480
	lvx		v30, r8, r10

major_0x13988_0x2e8
	vor		v31, v31, v31
	bns		cr7, major_0x13988_0x2f8
	li		r9,  0x1f0
	lvx		v31, r9, r10

major_0x13988_0x2f8
	blr



 ######     ###    ##     ## ########    ##     ## ########   ######  
##    ##   ## ##   ##     ## ##          ##     ## ##     ## ##    ## 
##        ##   ##  ##     ## ##          ##     ## ##     ## ##       
 ######  ##     ## ##     ## ######      ##     ## ########   ######  
      ## #########  ##   ##  ##           ##   ##  ##   ##         ## 
##    ## ##     ##   ## ##   ##            ## ##   ##    ##  ##    ## 
 ######  ##     ##    ###    ########       ###    ##     ##  ######  

	align	4		;	????

Save_v0_v31	;	OUTSIDE REFERER
	mfspr	r5, vrsave
	lwz		r2,  0x00d8(r6)
	cmplwi	r2,  0x00
	beqlr
	andis.	r3, r11,  0x200
	stw		r5,  0x0210(r2)
	beqlr
	mfmsr	r3
	rlwinm	r11, r11,  0,  7,  5
	oris	r3, r3,  0x200
	mtmsr	r3
	isync
	li		r3,  0x00
	li		r4,  0x10
	mtcr	r5
	stvx	v0, r3, r2
	stvxl	v1, r4, r2
	mfvscr	v0
	li		r3,  0x200
	stvx	v0, r3, r2
	bne		Save_v0_v31_0x5c
	li		r3,  0x20
	stvx	v2, r3, r2

Save_v0_v31_0x5c
	bns		Save_v0_v31_0x68
	li		r4,  0x30
	stvx	v3, r4, r2

Save_v0_v31_0x68
	bge		cr1, Save_v0_v31_0x74
	li		r3,  0x40
	stvx	v4, r3, r2

Save_v0_v31_0x74
	ble		cr1, Save_v0_v31_0x80
	li		r4,  0x50
	stvx	v5, r4, r2

Save_v0_v31_0x80
	bne		cr1, Save_v0_v31_0x8c
	li		r3,  0x60
	stvx	v6, r3, r2

Save_v0_v31_0x8c
	bns		cr1, Save_v0_v31_0x98
	li		r4,  0x70
	stvx	v7, r4, r2

Save_v0_v31_0x98
	bge		cr2, Save_v0_v31_0xa4
	li		r3,  0x80
	stvx	v8, r3, r2

Save_v0_v31_0xa4
	ble		cr2, Save_v0_v31_0xb0
	li		r4,  0x90
	stvx	v9, r4, r2

Save_v0_v31_0xb0
	bne		cr2, Save_v0_v31_0xbc
	li		r3, 160
	stvx	v10, r3, r2

Save_v0_v31_0xbc
	bns		cr2, Save_v0_v31_0xc8
	li		r4,  0xb0
	stvx	v11, r4, r2

Save_v0_v31_0xc8
	bge		cr3, Save_v0_v31_0xd4
	li		r3,  0xc0
	stvx	v12, r3, r2

Save_v0_v31_0xd4
	ble		cr3, Save_v0_v31_0xe0
	li		r4,  0xd0
	stvx	v13, r4, r2

Save_v0_v31_0xe0
	bne		cr3, Save_v0_v31_0xec
	li		r3,  0xe0
	stvx	v14, r3, r2

Save_v0_v31_0xec
	bns		cr3, Save_v0_v31_0xf8
	li		r4, 240
	stvx	v15, r4, r2

Save_v0_v31_0xf8
	bge		cr4, Save_v0_v31_0x104
	li		r3,  0x100
	stvx	v16, r3, r2

Save_v0_v31_0x104
	ble		cr4, Save_v0_v31_0x110
	li		r4,  0x110
	stvx	v17, r4, r2

Save_v0_v31_0x110
	bne		cr4, Save_v0_v31_0x11c
	li		r3,  0x120
	stvx	v18, r3, r2

Save_v0_v31_0x11c
	bns		cr4, Save_v0_v31_0x128
	li		r4,  0x130
	stvx	v19, r4, r2

Save_v0_v31_0x128
	bge		cr5, Save_v0_v31_0x134
	li		r3, 320
	stvx	v20, r3, r2

Save_v0_v31_0x134
	ble		cr5, Save_v0_v31_0x140
	li		r4,  0x150
	stvx	v21, r4, r2

Save_v0_v31_0x140
	bne		cr5, Save_v0_v31_0x14c
	li		r3,  0x160
	stvx	v22, r3, r2

Save_v0_v31_0x14c
	bns		cr5, Save_v0_v31_0x158
	li		r4,  0x170
	stvx	v23, r4, r2

Save_v0_v31_0x158
	bge		cr6, Save_v0_v31_0x164
	li		r3,  0x180
	stvx	v24, r3, r2

Save_v0_v31_0x164
	ble		cr6, Save_v0_v31_0x170
	li		r4, 400
	stvx	v25, r4, r2

Save_v0_v31_0x170
	bne		cr6, Save_v0_v31_0x17c
	li		r3,  0x1a0
	stvx	v26, r3, r2

Save_v0_v31_0x17c
	bns		cr6, Save_v0_v31_0x188
	li		r4,  0x1b0
	stvx	v27, r4, r2

Save_v0_v31_0x188
	bge		cr7, Save_v0_v31_0x194
	li		r3,  0x1c0
	stvx	v28, r3, r2

Save_v0_v31_0x194
	ble		cr7, Save_v0_v31_0x1a0
	li		r4,  0x1d0
	stvx	v29, r4, r2

Save_v0_v31_0x1a0
	bne		cr7, Save_v0_v31_0x1ac
	li		r3, 480
	stvx	v30, r3, r2

Save_v0_v31_0x1ac
	bns		cr7, Save_v0_v31_0x1b8
	li		r4,  0x1f0
	stvx	v31, r4, r2

Save_v0_v31_0x1b8
	blr




########    ###     ######  ##    ##    ##     ## ##    ## ########  ########  ##    ## 
   ##      ## ##   ##    ## ##   ##     ##     ## ###   ## ##     ## ##     ##  ##  ##  
   ##     ##   ##  ##       ##  ##      ##     ## ####  ## ##     ## ##     ##   ####   
   ##    ##     ##  ######  #####       ##     ## ## ## ## ########  ##     ##    ##    
   ##    #########       ## ##  ##      ##     ## ##  #### ##   ##   ##     ##    ##    
   ##    ##     ## ##    ## ##   ##     ##     ## ##   ### ##    ##  ##     ##    ##    
   ##    ##     ##  ######  ##    ##     #######  ##    ## ##     ## ########     ##    

;	Remove a task from its RDYQ, cleaning up the queue structures behind me.
;	If a queue is empty, unset the priority flag of the queue in
;	PSA.PriorityFlags. Also set the mysterious EWA.SchEvalFlag to 1.

;	ARG		Task *r8
;	CLOB	r16, r17, r18

SchTaskUnrdy

	lwz		r17, Task.QueueMember + LLL.Next( r8)
	lbz		r18, Task.State( r8)

	addi	r16, r8, Task.QueueMember

	;	Panic if State==0, return early if this task is not enqueued (i.e. LLL.Next==0)
	cmpwi	cr1, r18, 0
	cmpwi	r17, 0
	beq		cr1, Local_Panic
	beq		@return_early

	RemoveFromList	r16, scratch1=r17, scratch2=r18

	;	The queue of which this task was formerly a member
	lwz		r17, LLL.Freeform(r16)

	;	Tidy up by subtracting this tasks weight from the Q weight
	lwz		r16, Task.Weight(r8)
	lwz		r18, ReadyQueue.TotalWeight(r17)
	subf	r18, r16, r18
	stw		r18, ReadyQueue.TotalWeight(r17)

	;	Decrement the Q counter
	lwz		r18, ReadyQueue.Counter(r17)
	subi	r18, r18, 1
	stw		r18, ReadyQueue.Counter(r17)

	;	Optimised below: a bit confusing

	cmpwi	r18, 0						;	Crash if we popped from an empty queue!
	lwz		r16, PSA.PriorityFlags(r1)
	blt		Local_Panic
	bne		@return_early
	lwz		r18, ReadyQueue.LLL + LLL.Freeform(r17)
	andc	r16, r16, r18				;	If this queue is empty then unset the corresponding
	stw		r16, PSA.PriorityFlags(r1)	;	bit in PSA.PriorityFlags
@return_early

	li		r16, 0
	stb		r16, Task.State(r8)

	mfsprg  r17, 0
	li		r16, 1
	stb		r16, EWA.SchEvalFlag(r17)
	blr



########    ###     ######  ##    ##    ########  ########  ##    ## 
   ##      ## ##   ##    ## ##   ##     ##     ## ##     ##  ##  ##  
   ##     ##   ##  ##       ##  ##      ##     ## ##     ##   ####   
   ##    ##     ##  ######  #####       ########  ##     ##    ##    
   ##    #########       ## ##  ##      ##   ##   ##     ##    ##    
   ##    ##     ## ##    ## ##   ##     ##    ##  ##     ##    ##    
   ##    ##     ##  ######  ##    ##    ##     ## ########     ##    

;	These two entry cases specify different directions of queue insertion

;	ARG		Task *r8
;	CLOB	r16, r17, r18

SchRdyTaskLater
	crclr	cr1_eq
	b		_SchRdyTaskCommon
SchRdyTaskNow						; not much point in doing this unless you then flag a scheduler evaluation
	crset	cr1_eq
_SchRdyTaskCommon

	lwz		r16, Task.QueueMember + LLL.Next(r8)
	lis		r17, 0x8000 ; ...0000
	cmpwi	r16, 0
	lbz		r18, Task.Priority(r8)
	bne		Local_Panic


	;	Set the KDP priority flag for this task.
	;	Leave pointer to target RDYQ in r17.

	lwz		r16, PSA.PriorityFlags(r1)
	srw		r17, r17, r18
	mulli	r18, r18, 32 ;ReadyQueue.Size
	or		r16, r16, r17
	addi	r17, r1, PSA.ReadyQueues
	stw		r16, PSA.PriorityFlags(r1)
	add		r17, r17, r18


	;	What decrements this counter?
	lwz		r18, ReadyQueue.Counter(r17)
	addi	r18, r18, 1
	stw		r18, ReadyQueue.Counter(r17)


	lwz		r16, Task.Weight(r8)
	lwz		r18, ReadyQueue.TotalWeight(r17)
	add		r18, r18, r16
	stw		r18, ReadyQueue.TotalWeight(r17)


	addi	r16, r8, Task.QueueMember

	bne		cr1, @as_next


	stw				r17, LLL.Freeform(r16)
	InsertAsPrev	r16, r17, scratch=r18


	b		@endif
@as_next

	stw				r17, LLL.Freeform(r16)
	InsertAsNext	r16, r17, scratch=r18

@endif


	li		r16, 1
	stb		r16, Task.State(r8)
	blr



 ######  ########         ########     ###    ########     ######  ######## ######## 
##    ## ##     ##   ##   ##     ##   ## ##      ##       ##    ## ##          ##    
##       ##     ##   ##   ##     ##  ##   ##     ##       ##       ##          ##    
 ######  ########  ###### ########  ##     ##    ##        ######  ######      ##    
      ## ##   ##     ##   ##     ## #########    ##             ## ##          ##    
##    ## ##    ##    ##   ##     ## ##     ##    ##       ##    ## ##          ##    
 ######  ##     ##        ########  ##     ##    ##        ######  ########    ##    

;	Set the segment and block allocation table registers according to the 
;	SPAC structure passed in. On non-601 machines, unset the "guarded" bit
;	of the WIMG field of each lower BAT register.
;
;	And apparently there is a second, undocumented batch of BAT registers!

;	ARG		AddressSpace *r8, AddressSpace *r9 (can be zero?)

SchSwitchSpace

	;	This is the only function that hits this counter
	lwz		r17, KDP.NanoKernelInfo + NKNanoKernelInfo.AddrSpcSetCtr(r1)
	addi	r17, r17, 1
	stw		r17, KDP.NanoKernelInfo + NKNanoKernelInfo.AddrSpcSetCtr(r1)

	;	Check that we have the right guy (a 'SPAC')
	lwz		r16, AddressSpace.Signature(r8)
	lisori	r17, AddressSpace.kSignature
	cmpw	r16, r17
	bne		Local_Panic

	;	Intend to skip the dssall instruction if Altivec is... present? absent?
	rlwinm.	r16, r7, 0, EWA.kFlagVec, EWA.kFlagVec			;	seems to be leftover from Init.s Altivec testing

	;	Apply the address space to the segment registers
	isync
	lwz		r16, AddressSpace.SRs + 0(r8)
	lwz		r17, AddressSpace.SRs + 4(r8)
	mtsr	0, r16
	mtsr	1, r17
	lwz		r16, AddressSpace.SRs + 8(r8)
	lwz		r17, AddressSpace.SRs + 12(r8)
	mtsr	2, r16
	mtsr	3, r17
	lwz		r16, AddressSpace.SRs + 16(r8)
	lwz		r17, AddressSpace.SRs + 20(r8)
	mtsr	4, r16
	mtsr	5, r17
	lwz		r16, AddressSpace.SRs + 24(r8)
	lwz		r17, AddressSpace.SRs + 28(r8)
	mtsr	6, r16
	mtsr	7, r17
	lwz		r16, AddressSpace.SRs + 32(r8)
	lwz		r17, AddressSpace.SRs + 36(r8)
	mtsr	8, r16
	mtsr	9, r17
	lwz		r16, AddressSpace.SRs + 40(r8)
	lwz		r17, AddressSpace.SRs + 44(r8)
	mtsr	10, r16
	mtsr	11, r17
	lwz		r16, AddressSpace.SRs + 48(r8)
	lwz		r17, AddressSpace.SRs + 52(r8)
	mtsr	12, r16
	mtsr	13, r17
	lwz		r16, AddressSpace.SRs + 56(r8)
	lwz		r17, AddressSpace.SRs + 60(r8)
	mtsr	14, r16
	mtsr	15, r17

	beq		@skip_dssall
	dssall					;	flush pending vector ops?
@skip_dssall

	;	Point KDP at this SPAC
	mfsprg	r16, 0			;	paranoid
	isync
	stw		r8, EWA.PA_CurAddressSpace(r16)


	;	The 601 has a special code path for populating the BATs
	mfpvr	r16
	rlwinm.	r16, r16, 0, 0, 14
	cmpwi	cr1, r9, 0			;	arg r9 is 0 when called from Init.s
	beq		@is_601


	;	Fill the BATs on "real" PowerPC CPUs

		lwz		r16, AddressSpace.BAT0U(r8)
		lwz		r17, AddressSpace.BAT0U(r9)
		cmplw	r16, r17

		lwz		r17, AddressSpace.BAT0L(r8)
		beq		cr1, @definitely_set_BAT0
		beq		@skip_setting_BAT0

@definitely_set_BAT0			; r9 is zero or the addrspc bats match low physical memory
		mtspr	dbat0u, r0
		mtspr	dbat0l, r17
		rlwinm	r17, r17, 0, 29, 27
		mtspr	dbat0u, r16
		mtspr	ibat0u, r0
		mtspr	ibat0l, r17
		mtspr	ibat0u, r16
@skip_setting_BAT0


		lwz		r16, AddressSpace.BAT1U(r8)
		lwz		r17, AddressSpace.BAT1U(r9)
		cmplw	r16, r17
		lwz		r17, AddressSpace.BAT1L(r8)
		beq		cr1, @definitely_set_BAT1
		beq		@skip_setting_BAT1

@definitely_set_BAT1
		mtspr	dbat1u, r0
		mtspr	dbat1l, r17
		rlwinm	r17, r17, 0, 29, 27
		mtspr	dbat1u, r16
		mtspr	ibat1u, r0
		mtspr	ibat1l, r17
		mtspr	ibat1u, r16
@skip_setting_BAT1


		lwz		r16, AddressSpace.BAT2U(r8)
		lwz		r17, AddressSpace.BAT2U(r9)
		cmplw	r16, r17
		lwz		r17, AddressSpace.BAT2L(r8)
		beq		cr1, @definitely_set_BAT2
		beq		@skip_setting_BAT2

@definitely_set_BAT2
		mtspr	dbat2u, r0
		mtspr	dbat2l, r17
		rlwinm	r17, r17, 0, 29, 27
		mtspr	dbat2u, r16
		mtspr	ibat2u, r0
		mtspr	ibat2l, r17
		mtspr	ibat2u, r16
@skip_setting_BAT2


		lwz		r16, AddressSpace.BAT3U(r8)
		lwz		r17, AddressSpace.BAT3U(r9)
		cmplw	r16, r17
		lwz		r17, AddressSpace.BAT3L(r8)
		beq		cr1, @definitely_set_BAT3
		beqlr
@definitely_set_BAT3

		mtspr	dbat3u, r0
		mtspr	dbat3l, r17
		rlwinm	r17, r17, 0, 29, 27
		mtspr	dbat3u, r16
		mtspr	ibat3u, r0
		mtspr	ibat3l, r17
		mtspr	ibat3u, r16
@skip_setting_BAT3


@return
	blr

	;	This is the crazy cpu case
@is_601
	lwz		r16, 0x0080(r8)
	lwz		r17, 0x0080(r9)
	cmplw	r16, r17
	lwz		r17, 0x0084(r8)
	beq		cr1, SetAddrSpcRegisters_0x284
	beq		SetAddrSpcRegisters_0x29c

SetAddrSpcRegisters_0x284:
	rlwimi	r16, r17, 0, 25, 31
	mtspr	ibat0u, r16
	lwz		r16, 0x0080(r8)
	rlwimi	r17, r16, 30, 26, 31
	rlwimi	r17, r16, 6, 25, 25
	mtspr	ibat0l, r17

SetAddrSpcRegisters_0x29c:
	lwz		r16, 0x0088(r8)
	lwz		r17, 0x0088(r9)
	cmplw	r16, r17
	lwz		r17, 0x008c(r8)
	beq		cr1, SetAddrSpcRegisters_0x2b4
	beq		SetAddrSpcRegisters_0x2cc

SetAddrSpcRegisters_0x2b4:
	rlwimi	r16, r17, 0, 25, 31
	mtspr	ibat1u, r16
	lwz		r16, 0x0088(r8)
	rlwimi	r17, r16, 30, 26, 31
	rlwimi	r17, r16, 6, 25, 25
	mtspr	ibat1l, r17

SetAddrSpcRegisters_0x2cc:
	lwz		r16, 0x0090(r8)
	lwz		r17, 0x0090(r9)
	cmplw	r16, r17
	lwz		r17, 0x0094(r8)
	beq		cr1, SetAddrSpcRegisters_0x2e4
	beq		SetAddrSpcRegisters_0x2fc

SetAddrSpcRegisters_0x2e4:
	rlwimi	r16, r17, 0, 25, 31
	mtspr	ibat2u, r16
	lwz		r16, 0x0090(r8)
	rlwimi	r17, r16, 30, 26, 31
	rlwimi	r17, r16, 6, 25, 25
	mtspr	ibat2l, r17

SetAddrSpcRegisters_0x2fc:
	lwz		r16, 0x0098(r8)
	lwz		r17, 0x0098(r9)
	cmplw	r16, r17
	lwz		r17, 0x009c(r8)
	beq		cr1, SetAddrSpcRegisters_0x314
	beqlr

SetAddrSpcRegisters_0x314:
	rlwimi	r16, r17, 0, 25, 31
	mtspr	ibat3u, r16
	lwz		r16, 0x0098(r8)
	rlwimi	r17, r16, 30, 26, 31
	rlwimi	r17, r16, 6, 25, 25
	mtspr	ibat3l, r17
	blr
	


;	Always and only jumped to by IntReturn

SchReturn

	lbz		r8, EWA.SchEvalFlag(r1)
	rlwinm.	r9, r7, 0, 16, 16
	lwz		r1, EWA.PA_KDP(r1)
	cmpwi	cr1, r8, 0

	bne		SchExitInterrupt
	beq+	cr1, SchExitInterrupt

	bl		SchSaveStartingAtR14
	_Lock		PSA.SchLock, scratch1=r27, scratch2=r28



;	Either fallen through from SchReturn, or jumped to by
;	TrulyCommonMPCallReturnPath when it wants to block the caller

;	SchLock should be acquired before now!

SchEval
	mfsprg	r14, 0

	li		r8, 0
	stb		r8, EWA.SchEvalFlag(r14)

	lwz		r31, EWA.PA_CurTask(r14)
	lwz		r1, EWA.PA_KDP(r14)

	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.SchEvalCount(r1)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.SchEvalCount(r1)

	bl		SchFiddlePriorityShifty
	lbz		r27,  0x0019(r31)
	blt		major_0x142dc_0x58
	li		r26,  0x01
	beq		major_0x142dc_0x38
	li		r26,  0x00

major_0x142dc_0x38
	cmpw	r27, r26
	mr		r8, r31
	beq		major_0x142dc_0x58
	bl		SchTaskUnrdy
	stb		r26,  0x0019(r31)
	mr		r8, r31
	bl		SchRdyTaskNow
	bl		CalculateTimeslice


major_0x142dc_0x58	;	OUTSIDE REFERER
	lwz		r27, PSA.PriorityFlags(r1)

major_0x142dc_0x5c
	mr		r30, r31
	cmpwi	r27,  0x00
	cntlzw	r26, r27
	beq		major_0x142dc_0x140
	addi	r25, r1, PSA.CriticalReadyQ
	mulli	r26, r26,  0x20
	add		r26, r26, r25
	lwz		r29,  0x0008(r26)
	addi	r30, r29, -0x08

major_0x142dc_0x80
	lhz		r28, EWA.CPUIndex(r14)
	lwz		r24,  0x0064(r30)
	lhz		r25,  0x001a(r30)
	rlwinm.	r8, r24,  0, 25, 26
	cmpw	cr1, r25, r28
	beq		major_0x142dc_0xb8
	beq		cr1, major_0x142dc_0xb8
	lwz		r29,  0x0008(r29)
	addi	r30, r29, -0x08
	cmpw	r29, r26
	bne		major_0x142dc_0x80
	lwz		r25,  0x0000(r26)
	andc	r27, r27, r25
	b		major_0x142dc_0x5c

major_0x142dc_0xb8
	lbz		r25,  0x0018(r31)
	lbz		r28,  0x0019(r30)
	lbz		r27,  0x0019(r31)
	cmpwi	cr1, r25,  0x02
	cmpw	cr2, r28, r27
	bne		cr1, major_0x142dc_0xd8
	blt		cr2, major_0x142dc_0xd8
	mr		r30, r31

major_0x142dc_0xd8	;	OUTSIDE REFERER
	lwz		r28,  0x0010(r30)
	addi	r29, r30,  0x08
	cmpwi	r28,  0x00
	lwz		r26,  0x0008(r30)
	beq		major_0x142dc_0x140
	RemoveFromList		r29, scratch1=r28, scratch2=r27
	lwz		r27,  0x001c(r30)
	lwz		r28,  0x0014(r26)
	subf	r28, r27, r28
	stw		r28,  0x0014(r26)
	lwz		r28,  0x0010(r26)
	lwz		r27, PSA.PriorityFlags(r1)
	addi	r28, r28, -0x01
	cmpwi	r28,  0x00
	stw		r28,  0x0010(r26)
	bltl	Local_Panic
	bne		major_0x142dc_0x140
	lwz		r28,  0x0000(r26)
	andc	r27, r27, r28
	stw		r27, PSA.PriorityFlags(r1)

major_0x142dc_0x140
	lwz		r25,  0x0064(r30)
	li		r26,  0x00

	rlwinm.	r8, r25,  0, 21, 22
	andc	r27, r25, r8
	beq+	major_0x142dc_0x184
	ori		r27, r27,  0x200
	stb		r26,  0x0018(r30)
	stw		r27,  0x0064(r30)
	addi	r25, r1, PSA.DbugQueue
	addi	r26, r30,  0x08
	stw		r25,  0x0000(r26)
	InsertAsPrev	r26, r25, scratch=r27
	b		major_0x142dc_0x58
major_0x142dc_0x184

	cmpw	cr3, r30, r31
	rlwinm.	r8, r25,  0, 27, 27
	bne		cr3, _SchPreempt
	bne		_SchPreempt


	;	Don't preempt, keep running the same task

	bl		GetTime
	bl		major_0x148ec
	lwz		r27,  0x0064(r31)
	mfsprg	r14, 0
	rlwinm.	r8, r27,  0,  8,  8
	rlwimi	r11, r27, 24, 29, 29
	beq+	major_0x142dc_0x1bc
	lwz		r10,  0x00fc(r6)
	_bclr	r27, r27, Task.kFlag8
	stw		r27,  0x0064(r31)

major_0x142dc_0x1bc
	li		r27,  0x02
	lbz		r28,  0x0019(r31)
	stb		r27,  0x0018(r31)
	stb		r28, -0x0117(r14)
	_AssertAndRelease	PSA.SchLock, scratch=r27

;	r6 = ewa
	bl		SchRestoreStartingAtR14



;	SchLock should be released before here

SchExitInterrupt
	lwz		r8,  0x0edc(r1)
	mfsprg	r1, 0
	mtlr	r12
	mtspr	srr0, r10
	mtspr	srr1, r11
	rlwinm.	r8, r8,  0, 27, 27
	beq		SchExitInterrupt_0x2c
	mfxer	r8
	rlwinm	r8, r8,  0, 23, 21
	rlwimi	r8, r7, 19, 23, 23
	mtxer	r8

SchExitInterrupt_0x2c
	mtcr	r13
	lwz		r10,  0x0154(r6)
	lwz		r11,  0x015c(r6)
	lwz		r12,  0x0164(r6)
	lwz		r13,  0x016c(r6)
	lwz		r7,  0x013c(r6)
	lwz		r8,  0x0144(r6)
	lwz		r9,  0x014c(r6)
	lwz		r0,  0x0104(r6)
	lwz		r6,  0x0018(r1)
	lwz		r1,  0x0004(r1)
	rfi
	dcb.b	32, 0




;	ARG		outgoing_cb *r6, EWA *r14, incoming_task *r30, task_to_save_to *r31

_SchPreempt

	;	Save info for the previous task

	lwz		r16, Task.Flags(r31)
	stw		r30, EWA.SchSavedIncomingTask(r14)					; will clobber r30
	_bclr	r16, r16, Task.kFlag26
	stw		r6, Task.ContextBlockPtr(r31)
	mfsprg	r8, 3
	stw		r16, Task.Flags(r31)
	stw		r8, Task.VecBase(r31)


	;	Spam its context block

	lwz		r8, EWA.Enables(r14)
	stw		r7, ContextBlock.Flags(r6)
	stw		r8, ContextBlock.Enables(r6)
	mfxer	r8
	stw		r13, ContextBlock.CR(r6)
	stw		r8, ContextBlock.XER(r6)
	stw		r12, ContextBlock.LR(r6)
	mfctr	r8
	stw		r10, ContextBlock.CodePtr(r6)
	stw		r8, ContextBlock.KernelCTR(r6)

	mfspr	r8, pvr
	rlwinm.	r8, r8, 0, 0, 14
	bne		@not_601
	mfspr	r8, mq
	stw		r8, ContextBlock.MQ(r6)
@not_601

	lwz		r8, EWA.r1(r14)
	stw		r8, ContextBlock.r1(r6)
	stw		r2, ContextBlock.r2(r6)
	stw		r3, ContextBlock.r3(r6)
	andi.	r8, r11, MSR_FP
	stw		r4, ContextBlock.r4(r6)
	lwz		r8, EWA.r6(r14)
	stw		r5, ContextBlock.r5(r6)
	stw		r8, ContextBlock.r6(r6)
	bnel	Save_f0_f31

	lwz		r31, EWA.PA_CurTask(r14)							; sly aside: r30 = new, r31 = current
	lwz		r30, EWA.SchSavedIncomingTask(r14)

	rlwinm.	r8, r7, 0, EWA.kFlagVec, EWA.kFlagVec
	bnel	Save_v0_v31
	stw		r11, ContextBlock.MSR(r6)


	;	Bump current task's preemption ctr

	lwz		r8, Task.PreemptCtr(r31)
	addi	r8, r8, 1
	stw		r8, Task.PreemptCtr(r31)


	;	No clue

	bl		GetTime
	bl		major_0x148ec


	;	Update EWA global to match this task, and set task's state to 2
	mfsprg	r14, 0
	li		r27, 2
	lbz		r28, Task.Priority(r30)
	stb		r27, Task.State(r30)
	stb		r28, EWA.TaskPriority(r14)

	;	If incoming task is not already running, and running task is not in a queue, re-ready the running task
	cmplw	r30, r31
	lwz		r16, Task.QueueMember + LLL.Next(r31)
	beq		@no
	cmpwi	r16, 0
	mr		r8, r31
	beql	SchRdyTaskNow
@no


	;	Play more with the incoming task

	mfsprg	r19, 0

	li		r8, 0
	stb		r8, EWA.SchEvalFlag(r19)

	lhz		r8, EWA.CPUIndex(r19)
	lwz		r6, Task.ContextBlockPtr(r30)
	lwz		r28, EWA.CPUBase + CPU.ID(r19)
	sth		r8, Task.CPUIndex(r30)
	stw		r28, Task.CpuID(r30)

	stw		r30, EWA.PA_CurTask(r19)

	stw		r6, EWA.PA_ContextBlock(r19)

	lwz		r7, ContextBlock.Flags(r6)
	lwz		r28, ContextBlock.Enables(r6)
	stw		r7, EWA.Flags(r19)
	stw		r28, EWA.Enables(r19)

	lwz		r27, Task.Flags(r30)
	lwz		r13, ContextBlock.CR(r6)
	ori		r27, r27, 1 << (31 - Task.kFlag26)
	lwz		r11,  0x00a4(r6)
	lwz		r8,  0x00f0(r30)
	rlwimi	r11, r27, 24, 29, 29
	_bclr	r27, r27, Task.kFlag8
	mtsprg	3, r8
	stw		r27, Task.Flags(r30)


	;	Switch address space if necessary

	lwz		r18, Task.AddressSpacePtr(r30)
	lwz		r9, EWA.PA_CurAddressSpace(r19)
	cmpw	r18, r9
	beq		@same_space
	mr		r8, r18
	bl		SchSwitchSpace
@same_space


	mfsprg	r19, 0


	;	Is this the blue task? If so, do we need to interrupt it?

	mtcr	r7
	lisori	r28, 1 << (31 - Task.kFlagSchToInterruptEmu)
	bc		BO_IF_NOT, EWA.kFlagBlue, @NO_BLUE_INTERRUPT
	and.	r28, r28, r27
	li		r8, 0
	beq		@NO_BLUE_INTERRUPT


	;	TRIGGER AN INTERRUPT IN THE BLUE TASK

	andc	r27, r27, r28
	lwz		r29, PSA.MCR(r1)
	stw		r27, Task.Flags(r30)						; unset the task flag that got us here
	stw		r8, PSA.MCR(r1)
	bc		BO_IF, EWA.kFlagEmu, @already_in_system_context
	bcl		BO_IF, 27, Local_Panic


	;	Need to switch blue task from alternate context to system context

	clrlwi	r8, r7, 8
	stw		r8, ContextBlock.Flags(r6)

	lwz		r6, KDP.PA_ECB(r1)

	addi	r26, r1, KDP.VecBaseSystem
	mtsprg	3, r26
	stw		r26, Task.VecBase(r30)

	stw		r6, EWA.PA_ContextBlock(r19)
	stw		r6, Task.ContextBlockPtr(r30)

	lwz		r7, ContextBlock.Flags(r6)
	lwz		r26, ContextBlock.Enables(r6)
	mtcr	r7
	stw		r26, EWA.Enables(r19)

	lwz		r13, ContextBlock.CR(r6)
	lwz		r11, ContextBlock.MSR(r6)

	bcl		BO_IF, 27, Local_Panic

	rlwimi	r11, r7, 0, 20, 23							; apply MSR[FE0/SE/BE/FE1]
	rlwimi	r7, r8, 0, 9, 16							; keep flags 9-16 from alternate context
	rlwimi	r11, r27, 24, 29, 29						; MSR[PMM] = Task.kFlagPerfMon

	stw		r7, EWA.Flags(r19)
@already_in_system_context


	;	Blue task now (or was already) in system context (i.e. 68k emulator is running)

	lwz		r17, ContextBlock.PriorityShifty(r6)
	ori		r17, r17, 0x100
	stw		r17, ContextBlock.PriorityShifty(r6)


	;	EDP.INTM_L = PSA.Pending68kInt (presumably the emulator polls this)

	lhz		r17, PSA.Pending68kInt(r1)
	lwz		r18, KDP.PA_EmulatorIplValue(r1)
	cmplwi	r17, 0xffff									; i.e. (short)(-1)
	lwz		r26, KDP.PostIntMaskInit(r1)
	beq		@no_change_to_int_level						; would this ever happen?

	sth		r17, 0(r18)
	li		r17, -1
	sth		r17, PSA.Pending68kInt(r1)
@no_change_to_int_level


	;	Fiddle with the emulator's Condition Register ("int mask")

	cmpwi	r29, 0
	or		r13, r13, r29
	bne		@did_set_bits_in_mask
	lwz		r29,  KDP.ClearIntMaskInit(r1)
	and		r13, r13, r29
@did_set_bits_in_mask

@NO_BLUE_INTERRUPT


	;	Back to the common path for preemption (pretty boring)

	lwz		r29,  0x00d8(r6)
	cmpwi	r29,  0x00
	lwz		r8,  0x0210(r29)
	beq		_SchPreempt_0x220
	mtspr	vrsave, r8
_SchPreempt_0x220

	lwz		r8,  0x00d4(r6)
	lwz		r12,  0x00ec(r6)
	mtxer	r8
	lwz		r8,  0x00f4(r6)
	lwz		r10,  0x00fc(r6)
	mtctr	r8
	mfspr	r8, pvr
	rlwinm.	r8, r8,  0,  0, 14
	bne		_SchPreempt_0x24c
	lwz		r8,  0x00c4(r6)
	mtspr	mq, r8

_SchPreempt_0x24c
	li		r9,  0x124
	lwz		r8,  0x010c(r6)
	dcbt	r9, r6
	lwz		r2,  0x0114(r6)
	stw		r8,  0x0004(r19)
	lwz		r3,  0x011c(r6)
	li		r9,  0x184
	lwz		r4,  0x0124(r6)
	dcbt	r9, r6
	lwz		r8,  0x0134(r6)
	lwz		r5,  0x012c(r6)
	stw		r8,  0x0018(r19)
	lwz		r14,  0x0174(r6)
	lwz		r15,  0x017c(r6)
	li		r9, 420
	lwz		r16,  0x0184(r6)
	dcbt	r9, r6
	lwz		r17,  0x018c(r6)
	lwz		r18,  0x0194(r6)
	lwz		r19,  0x019c(r6)
	li		r9,  0x1c4
	lwz		r20,  0x01a4(r6)
	dcbt	r9, r6
	lwz		r21,  0x01ac(r6)
	lwz		r22,  0x01b4(r6)
	lwz		r23,  0x01bc(r6)
	li		r9,  0x1e4
	lwz		r24,  0x01c4(r6)
	dcbt	r9, r6
	lwz		r25,  0x01cc(r6)
	lwz		r26,  0x01d4(r6)
	lwz		r27,  0x01dc(r6)
	andi.	r8, r11,  0x2900
	lwz		r28,  0x01e4(r6)
	lwz		r29,  0x01ec(r6)
	lwz		r30,  0x01f4(r6)
	lwz		r31,  0x01fc(r6)

	beq		_SchPreempt_0x380
	mfmsr	r8
	ori		r8, r8,  0x2000
	ori		r11, r11,  0x2000
	mtmsr	r8
	isync
	lfd		f31,  0x00e0(r6)
	lfd		f0,  0x0200(r6)
	lfd		f1,  0x0208(r6)
	lfd		f2,  0x0210(r6)
	lfd		f3,  0x0218(r6)
	lfd		f4,  0x0220(r6)
	lfd		f5,  0x0228(r6)
	lfd		f6,  0x0230(r6)
	lfd		f7,  0x0238(r6)
	mtfsf	 0xff, f31
	lfd		f8,  0x0240(r6)
	lfd		f9,  0x0248(r6)
	lfd		f10,  0x0250(r6)
	lfd		f11,  0x0258(r6)
	lfd		f12,  0x0260(r6)
	lfd		f13,  0x0268(r6)
	lfd		f14,  0x0270(r6)
	lfd		f15,  0x0278(r6)
	lfd		f16,  0x0280(r6)
	lfd		f17,  0x0288(r6)
	lfd		f18,  0x0290(r6)
	lfd		f19,  0x0298(r6)
	lfd		f20,  0x02a0(r6)
	lfd		f21,  0x02a8(r6)
	lfd		f22,  0x02b0(r6)
	lfd		f23,  0x02b8(r6)
	lfd		f24,  0x02c0(r6)
	lfd		f25,  0x02c8(r6)
	lfd		f26,  0x02d0(r6)
	lfd		f27,  0x02d8(r6)
	lfd		f28,  0x02e0(r6)
	lfd		f29,  0x02e8(r6)
	lfd		f30,  0x02f0(r6)
	lfd		f31,  0x02f8(r6)
_SchPreempt_0x380

	_AssertAndRelease	PSA.SchLock, scratch=r8

	b		SchExitInterrupt



major_0x148ec	;	OUTSIDE REFERER
	mfxer	r20
	mfsprg	r21, 0
	lwz		r19,  0x00cc(r31)
	lwz		r18,  0x00c8(r31)
	subfc	r19, r19, r9
	subfe	r18, r18, r8
	lwz		r17,  0x00c4(r31)
	lwz		r16,  0x00c0(r31)
	addc	r17, r17, r19
	adde	r16, r16, r18
	stw		r17,  0x00c4(r31)
	stw		r16,  0x00c0(r31)
	lwz		r17,  0x00dc(r31)
	lwz		r16,  0x00d8(r31)
	andi.	r22, r17,  0x01
	bne		major_0x148ec_0x58
	subfc	r17, r19, r17
	subfe.	r16, r18, r16
	bge		major_0x148ec_0x54
	li		r16,  0x00
	li		r17,  0x00

major_0x148ec_0x54
	stw		r16,  0x00d8(r31)

major_0x148ec_0x58
	rlwinm	r17, r17,  0,  0, 30
	stw		r17,  0x00dc(r31)
	lwz		r17,  0x00fc(r31)
	andi.	r22, r17,  0x01
	bne		major_0x148ec_0x78
	subf.	r17, r19, r17
	bge		major_0x148ec_0x78
	li		r17,  0x00

major_0x148ec_0x78
	rlwinm	r17, r17,  0,  0, 30
	stw		r17,  0x00fc(r31)
	stw		r8,  0x00c8(r30)
	stw		r9,  0x00cc(r30)
	lwz		r18,  0x0008(r30)
	lbz		r19,  0x0019(r30)
	lwz		r18,  0x0010(r18)
	cmpwi	cr1, r19,  0x02
	cmpwi	r18,  0x00
	bge		cr1, major_0x148ec_0xb0
	lwz		r16,  0x00fc(r30)
	lwz		r17,  0x00fc(r30)
	srawi	r16, r16, 31
	b		major_0x148ec_0xc8

major_0x148ec_0xb0
	lwz		r16,  0x00d8(r30)
	lwz		r17,  0x00dc(r30)
	bgt		major_0x148ec_0xc8
	bne		cr1, major_0x148ec_0xc8
	li		r16,  0x00
	lwz		r17,  0x0f2c(r1)

major_0x148ec_0xc8
	addc	r17, r17, r9
	adde	r16, r16, r8
	stw		r17, -0x02e4(r21)
	stw		r16, -0x02e8(r21)
	mtxer	r20
	li		r16,  0x01
	stb		r16, -0x0309(r21)
	b		SetTimesliceFromCurTime



;	Almost certain this was hand-written. Has a typo, and some
;	instructions the compiler rarely touched, and is in hot path.

;	ARG		Task *r8

major_0x149d4	;	OUTSIDE REFERER
	crset	cr1_eq
	b		major_0x149d4_0xc

CalculateTimeslice	;	OUTSIDE REFERER
	crclr	cr1_eq

major_0x149d4_0xc:


	;	CALCULATE TASK'S TIMESLICE

	;	Get task info
	lwz		r18, Task.QueueMember + LLL.Next(r8)
	lwz		r16, Task.QueueMember + LLL.Freeform(r8)		; points to RDYQ
	cmpwi	r18, 0
	lwz		r17, Task.Weight(r8)
	beq		Local_Panic

	;	Get queue info
	lwz		r18, ReadyQueue.TotalWeight(r16)
	lwz		r19, ReadyQueue.Timecake(r16)
	lwz		r20, ReadyQueue.Timecake + 4(r16)

	;	Skip calculation if only task in queue
	cmpw	r18, r17
	rlwinm	r17, r17, 10, 0, 22		; r17 *= 1024, but with minor masking typo?
	beq		@is_only_weighted_task

	divw.	r18, r17, r18			; r8 = my share of this queue's weight, out of 1024
	ble		@no_time				; if not specified, fall back on 1/1024

	;	t = t * r18 = my share of queue's time, out of 1024
	mulhw	r17, r20, r18
	mullw	r19, r19, r18
	mullw	r20, r20, r18
	add		r19, r19, r17
@no_time

	;	t = t / 1024 = my share of queue's time
	srwi	r20, r20, 10
	rlwimi	r20, r19, 22, 0, 9
	srwi	r19, r19, 10
@is_only_weighted_task

	;	NOW: r19 || r20 == task's slice of queue Timecake, in TB/DEC units


	lbz		r18, Task.Priority(r8)
	cmpwi	r18, Task.kNominalPriority
	ori		r20, r20, 1						; why make this odd?
	bge		@nominal_or_idle

;critical or latency protected
	stw		r20, 0x00fc(r8)
	blr

@nominal_or_idle
	lwz		r16, 0x00d8(r8)
	lwz		r17, 0x00dc(r8)
	bc		BO_IF, cr1_eq, @definitely_do_the_thing

	cmpwi	r16, 0
	cmplwi	cr2, r17, 0
	blt		@definitely_do_the_thing
	bgtlr
	bgtlr	cr2

@definitely_do_the_thing
;double-int is negative or zero
	mfxer	r18
	addc	r20, r20, r17
	adde	r19, r19, r16
	mtxer	r18
	rlwinm	r20, r20, 0, 0, 30

	li		r18, 1
	stw		r19, 0x00d8(r8)
	stw		r20, 0x00dc(r8)
	stw		r18, 0x00fc(r8)
	blr




clear_cr0_lt	;	OUTSIDE REFERER
	crclr	cr0_lt
	blr



SchFiddlePriorityShifty	;	OUTSIDE REFERER

	rlwinm	r8, r7, EWA.kFlagBlue,  0,  0
	lwz		r18, KDP.PA_ECB(r1)
	nand.	r8, r8, r8
	lwz		r17, ContextBlock.PriorityShifty(r18)
	bltlr ; return if flag 10 was unset

	cmpwi	r17, 0
	rlwinm	r9, r17,  0, 22, 22
	blt		@pshifty_high_bit_set

	cmpwi	r9,  0x200
	lwz		r16, ContextBlock.r25(r18)
	beq		@pshifty_bit_22_set

	clrlwi	r8, r16, 29
	clrlwi	r9, r17, 28
	cmpwi	r8, 6
	bgt		@pshifty_bit_22_set
	cmpw	r8, r9
	bltlr
	cmpw	r8, r8

@pshifty_bit_22_set
	ori		r17, r17, 0x100
	stw		r17, ContextBlock.PriorityShifty(r18)
	blr

@pshifty_high_bit_set
	clrlwi	r17, r17, 1
	stw		r17, ContextBlock.PriorityShifty(r18)
	blr



######## ##          ###     ######      ######## ##     ##    ###    ##       
##       ##         ## ##   ##    ##     ##       ##     ##   ## ##   ##       
##       ##        ##   ##  ##           ##       ##     ##  ##   ##  ##       
######   ##       ##     ## ##   ####    ######   ##     ## ##     ## ##       
##       ##       ######### ##    ##     ##        ##   ##  ######### ##       
##       ##       ##     ## ##    ##     ##         ## ##   ##     ## ##       
##       ######## ##     ##  ######      ########    ###    ##     ## ######## 

;	ARG		Task *r8

FlagSchEvaluationIfTaskRequires	;	OUTSIDE REFERER

	lwz		r16, Task.Flags(r8)
	mfsprg	r15, 0

	rlwinm.	r16, r16, 0, Task.kFlag25, Task.kFlag26
	bne		FlagSchEval

	addi	r16, r15, EWA.CPUBase
	lbz		r17, Task.Priority(r8)
	lwz		r19, CPU.LLL + LLL.Freeform(r16)


	;	Uniprocessor systems:
	;	Flag a reevaluation on this, the only CPU

	lwz		r14, CoherenceGroup.ScheduledCpuCount(r19)
	cmpwi	r14, 2
	blt		FlagSchEval


	;	Multiprocessor systems:
	;	Find the best CPU to flag a 

	lwz		r14, CoherenceGroup.CpuCount(r19)
	mr		r18, r16
	b		@loopentry

	;	r19 = motherboard coherence group
	;	r14 = loop counter
	;	r16 = current CPU pointer

@loop_hit_the_coherence_group
	lwz		r16, CoherenceGroup.CPUList + LLL.Next(r19)
@loop
	subi	r16, r16, CPU.LLL

@loopentry
	subi	r14, r14, 1

	lbz		r20, CPU.EWA + EWA.TaskPriority(r16)
	lwz		r21, CPU.Flags(r16)

	cmpw	cr1, r17, r20
	rlwinm.	r21, r21, 0, CPU.kFlagScheduled, CPU.kFlagScheduled

	bge		cr1, @cpu_not_best_for_task
	beq		@cpu_not_best_for_task

	mr		r17, r20
	mr		r18, r16
@cpu_not_best_for_task

	lwz		r16, CPU.LLL + LLL.Next(r16)		;	next element

	cmpwi	cr1, r14, 0
	cmpw	r16, r19

	ble		cr1, @exit_loop
	beq		@loop_hit_the_coherence_group		;	skip the owner of the linked list

	b		@loop
@exit_loop

	;	r17 = least-important priority being executed on any CPU
	;	r18 = pointer to that CPU

	;	No suitable CPU found (all running important-er tasks)
	lbz		r16, Task.Priority(r8)
	cmpw	r17, r16
	blelr

	;	Was this CPU the most suitable?
	lhz		r17, EWA.CPUIndex(r15)
	lhz		r18, CPU.EWA + EWA.CPUIndex(r18)
	cmpw	r18, r17
	bne		AlertSchEvalOnOtherCPU
	; otherwise fall through to FlagSchEvalOnThisCPU


	;	RETURN PATHS

	;	To force a scheduler evaluation to run on *this* CPU when returning from
	;	*this* interrupt, just raise a flag.

FlagSchEvalOnThisCPU
	li		r16, 1
	stb		r16, EWA.SchEvalFlag(r15)
	blr


	;	Public function! Can go to FlagSchEvalOnThisCPU or AlertSchEvalOnOtherCPU

FlagSchEval
	mfsprg	r15, 0
	lhz		r18, Task.CPUIndex(r8)
	lhz		r17, EWA.CPUIndex(r15)
	cmpw	r17, r18
	beq		FlagSchEvalOnThisCPU


	;	To force a scheduler evaluation to run on *another* CPU, we interrupt it

AlertSchEvalOnOtherCPU
	lwz		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.AlertCount(r1)
	addi	r9, r9, 1
	stw		r9, KDP.NanoKernelInfo + NKNanoKernelInfo.AlertCount(r1)

	li		r16, kAlert
	stw		r16, EWA.SIGPSelector(r15)
	stw		r18, EWA.SIGPCallR4(r15)

	li		r8, 2
	b		SIGP								;	returns to link register



NewCpuEntryPoint

	;	This func gets passed its CPU struct in r3,
	;	which lets us find its real EWA pointer.
	addi	r1, r3, CPU.EWA
	mtsprg	0, r1

	;	Get KDP
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r8, KDP.HTABORG(r1)
	lwz		r9, KDP.PTEGMask(r1)

	;	Set SDR1 (same as the main ones)
	srwi	r9, r9, 16
	or		r9, r8, r9
	sync
	mtspr	sdr1, r9
	sync

	_log	'Sch: Symmetric Multiprocessing^n'
	_log	'Sch: On CPU '
	lhz		r8, CPU.EWA + EWA.CPUIndex(r3)
	bl		Printh
	_log	' ID-'
	lwz		r8, -0x0340(r3)
	bl		Printw

	_log	' SDR1: '
	mr		r8, r9
	bl		Printw

	_log	' CpuDescriptor: '
	mr		r8, r3
	bl		Printw

	_log	' KDP: '
	mr		r8, r1
	bl		Printw

	_log	'^n'

	bl		PagingFlushTLB
	

	;	This is important to figure out:

	_log	'Sch: Starting SMP idle task^n'

	_Lock			PSA.SchLock, scratch1=r27, scratch2=r28

	mfsprg	r14, 0
	lwz		r31, CPU.IdleTaskPtr(r3)

	li		r8, 0
	stb		r8, EWA.SchEvalFlag(r14)

	lwz		r6, Task.ContextBlockPtr(r31)

	stw		r31, EWA.PA_CurTask(r14)

	stw		r6, EWA.PA_ContextBlock(r14)

	lwz		r7, ContextBlock.Flags(r6)
	lwz		r28, ContextBlock.Enables(r6)
	stw		r7, EWA.Flags(r14)
	stw		r28, EWA.Enables(r14)

	lwz		r8, Task.VecBase(r31)
	mtsprg	3, r8

	lwz		r10, ContextBlock.CodePtr(r6)
	lwz		r11, ContextBlock.MSR(r6)
	lwz		r13, ContextBlock.CR(r6)
	lwz		r12, ContextBlock.LR(r6)

	_log	'EWA '
	mr		r8, r14
	bl		Printw

	_log	'ContextPtr '
	mr		r8, r6
	bl		Printw

	_log	'Flags '
	mr		r8, r7
	bl		Printw

	_log	'Enables '
	mr		r8, r28
	bl		Printw
	_log	'^n'

	addi	r16, r31, Task.QueueMember
	RemoveFromList		r16, scratch1=r17, scratch2=r18

	li		r16, 2
	stb		r16, Task.State(r31)

	lwz		r16, Task.Flags(r31)
	ori		r16, r16, 0x20
	stw		r16, Task.Flags(r31)

	mfsprg	r14, 0

	lbz		r8, Task.Priority(r31)
	stb		r8, EWA.TaskPriority(r14)

	lwz		r8, Task.AddressSpacePtr(r31)
	li		r9, 0
	bl		SchSwitchSpace

	_log	'Adding idle task 0x'
	mr		r8, r31
	bl		Printw
	_log	'to the ready queue^n'

	mr		r8, r31
	bl		SchRdyTaskNow
	bl		CalculateTimeslice
	lwz		r16, CPU.Flags(r3)
	ori		r16, r16, 8
	stw		r16, CPU.Flags(r3)

	lwz		r17, Task.QueueMember + LLL.Freeform(r3)
	lwz		r16,  0x0024(r17)
	addi	r16, r16,  0x01
	stw		r16,  0x0024(r17)

	li		r8, 1
	mtspr	dec, r8

	_log	'Sch: Going to '
	mr		r8, r11					; MSR
	bl		Printw
	mr		r8, r10					; PC
	bl		Printw
	_log	'^n'

	mr		r30, r31
	b		major_0x142dc_0xd8


	b		major_0x142dc_0x58



SchIdleTask

	li		r31, 0
	lisori	r20, 'idle'
	lisori	r21, 'task'
	lisori	r22, 'RenŽ'
	lisori	r23, 'Alan'
	lisori	r24, 'Jim '
	lisori	r25, 'Alex'
	lisori	r26, 'Derr'
	lisori	r27, 'ick '

@loop

	;	Kill some time
	mr		r30, r1
	mr		r1, r2
	mr		r2, r5
	mr		r5, r6
	mr		r6, r7
	mr		r7, r8
	mr		r8, r9
	mr		r9, r10
	mr		r10, r11
	mr		r11, r12
	mr		r12, r13
	mr		r13, r14
	mr		r14, r15
	mr		r15, r16
	mr		r16, r17
	mr		r17, r18
	mr		r18, r19
	mr		r19, r20
	mr		r20, r21
	mr		r21, r22
	mr		r22, r23
	mr		r23, r24
	mr		r24, r25
	mr		r25, r26
	mr		r26, r27
	mr		r27, r28
	mr		r28, r29
	mr		r29, r30

	;	If the loop started with r31==0, make another round of syscalls
	cmpwi	r31, 0
	beq		@make_calls

	;	But if we counted down from >=1 to zero, then just do that again
	subi	r31, r31, 1
	cmplwi	r31, 0
	bgt		@startagain

@make_calls


	;	Check that CPU plugin trusts this CPU

	li		r3, kGetProcessorTemp
	li		r4, 1			; 2nd arg ignored
	li		r0, 46			; KCCpuPlugin
	sc
	cmpwi	r3, 0
	beq		@startagain


	li		r3, 1
	li		r4, 0
	twi		31, r31, 5		; PowerCall(1)
	cmpwi	r3, 0
	beq		@startagain

	lisori	r31, 10*1000000

@startagain
	b		@loop



SchIdleTaskStopper
	mfmsr	r30
	andi.	r29, r30,  0x7fff
	mtmsr	r29
	mfsprg	r2, 0
	lwz		r1, -0x0004(r2)

	_Lock			PSA.SchLock, scratch1=r16, scratch2=r17

	addi	r31, r2, -0x340
	lwz		r16,  0x0018(r31)
	rlwinm	r16, r16,  0, 29, 27
	stw		r16,  0x0018(r31)
	sync	
	lwz		r17,  0x0008(r31)
	lwz		r16,  0x0024(r17)
	addi	r16, r16, -0x01
	stw		r16,  0x0024(r17)
	lwz		r8,  0x001c(r31)
	li		r9,  0x00
	stw		r9,  0x001c(r31)
	bl		SchTaskUnrdy
	addi	r16, r1, PSA.DelayQueue
	addi	r17, r8,  0x08
	stw		r16,  0x0000(r17)
	InsertAsPrev	r17, r16, scratch=r18
	bl		TasksFuncThatIsNotAMPCall
	_AssertAndRelease	PSA.SchLock, scratch=r16
	_log	'SIGP kStopProcessor^n'
	li		r3, kStopProcessor
	lhz		r4, CPU.EWA + EWA.CPUIndex(r31)

	;	Use twi to call MPCpuPlugin(3, myCpuID)
	li		r0, 46
	twi		31, r31, 8
	_log	'Stop didn''t work - going to sleep.^n'

SchIdleTaskStopper_0x10c
	lis		r5,  0x7fff
	ori		r5, r5,  0xffff
	mtdec	r5

	li		r3, 6
	li		r4, 0
	twi		31, r31, 5
	b		SchIdleTaskStopper_0x10c
