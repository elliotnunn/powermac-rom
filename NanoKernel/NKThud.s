
	align	5


panic	;	OUTSIDE REFERER
	crset	cr1_eq
	b		panic_common

panic_non_interactive
	crclr	cr1_eq

panic_common
	mfsprg	r1, 0
	stmw	r29, EWA.ThudSavedR29(r1)
	lwz		r1, EWA.PA_KDP(r1)
	mflr	r29

	_Lock			PSA.ThudLock, scratch1=r30, scratch2=r31

	stw		r29, KDP.ThudSavedLR(r1)
	stw		r0, KDP.ThudSavedR0(r1)
	mfsprg	r0, 1
	stw		r0, KDP.ThudSavedR1(r1)
	stw		r2, KDP.ThudSavedR2(r1)
	mfsprg	r2, 0
	lmw		r29, EWA.ThudSavedR29(r2)
	stmw	r3, KDP.ThudSavedR3(r1)
	mfcr	r0
	stw		r0, KDP.ThudSavedCR(r1)


;	Save the silly multiply-quotient register

	mfspr	r0, pvr
	rlwinm.	r0, r0,  0,  0, 14
	bne		@no_mq
	dialect	POWER
	mfmq	r0
	dialect	PowerPC
	stw		r0, KDP.ThudSavedMQ(r1)
@no_mq

	mfxer	r0
	stw		r0, KDP.ThudSavedXER(r1)
	mfsprg	r0, 2
	stw		r0, KDP.ThudSavedSPRG2(r1)
	mfctr	r0
	stw		r0, KDP.ThudSavedCTR(r1)
	mfspr	r0, pvr
	stw		r0, KDP.ThudSavedPVR(r1)
	mfspr	r0, dsisr
	stw		r0, KDP.ThudSavedDSISR(r1)
	mfspr	r0, dar
	stw		r0, KDP.ThudSavedDAR(r1)


;	Save the time

	mfpvr	r0
	rlwinm.	r0, r0,  0,  0, 14
	bne		@not_601

@rtcloop
	dialect	POWER
	mfrtcu	r0
	mfrtcl	r2
	mfrtcu	r3
	dialect	PowerPC
	cmpw	r0, r3
	bne		@rtcloop

	stw		r0, KDP.ThudSavedTBU(r1)
	stw		r2, KDP.ThudSavedTB(r1)
	b		@end_if_601
@not_601

@tbloop
	mftbu	r0
	mftb	r2
	mftbu	r3
	cmpw	r0, r3
	bne		@tbloop
	stw		r0, KDP.ThudSavedTBU(r1)
	stw		r2, KDP.ThudSavedTB(r1)
@end_if_601


	mfspr	r0, dec
	stw		r0,  0x07a8(r1)
	mfspr	r0, hid0
	stw		r0,  0x07ac(r1)
	mfspr	r0, sdr1
	stw		r0,  0x07b0(r1)
	mfspr	r0, srr0
	stw		r0,  0x07b4(r1)
	mfspr	r0, srr1
	stw		r0,  0x07b8(r1)
	mfmsr	r0
	stw		r0,  0x07bc(r1)
	mfsr	r0, 0
	stw		r0,  0x07c0(r1)
	mfsr	r0, 1
	stw		r0,  0x07c4(r1)
	mfsr	r0, 2
	stw		r0,  0x07c8(r1)
	mfsr	r0, 3
	stw		r0,  0x07cc(r1)
	mfsr	r0, 4
	stw		r0,  0x07d0(r1)
	mfsr	r0, 5
	stw		r0,  0x07d4(r1)
	mfsr	r0, 6
	stw		r0,  0x07d8(r1)
	mfsr	r0, 7
	stw		r0,  0x07dc(r1)
	mfsr	r0, 8
	stw		r0,  0x07e0(r1)
	mfsr	r0, 9
	stw		r0,  0x07e4(r1)
	mfsr	r0, 10
	stw		r0,  0x07e8(r1)
	mfsr	r0, 11
	stw		r0,  0x07ec(r1)
	mfsr	r0, 12
	stw		r0,  0x07f0(r1)
	mfsr	r0, 13
	stw		r0,  0x07f4(r1)
	mfsr	r0, 14
	stw		r0,  0x07f8(r1)
	mfsr	r0, 15
	stw		r0,  0x07fc(r1)


	mfmsr	r0
	_bset	r0, r0, MSR_FPbit
	mtmsr	r0
	isync

	stfd	f0,  0x0800(r1)
	stfd	f1,  0x0808(r1)
	stfd	f2,  0x0810(r1)
	stfd	f3,  0x0818(r1)
	stfd	f4,  0x0820(r1)
	stfd	f5,  0x0828(r1)
	stfd	f6,  0x0830(r1)
	stfd	f7,  0x0838(r1)
	stfd	f8,  0x0840(r1)
	stfd	f9,  0x0848(r1)
	stfd	f10,  0x0850(r1)
	stfd	f11,  0x0858(r1)
	stfd	f12,  0x0860(r1)
	stfd	f13,  0x0868(r1)
	stfd	f14,  0x0870(r1)
	stfd	f15,  0x0878(r1)
	stfd	f16,  0x0880(r1)
	stfd	f17,  0x0888(r1)
	stfd	f18,  0x0890(r1)
	stfd	f19,  0x0898(r1)
	stfd	f20,  0x08a0(r1)
	stfd	f21,  0x08a8(r1)
	stfd	f22,  0x08b0(r1)
	stfd	f23,  0x08b8(r1)
	stfd	f24,  0x08c0(r1)
	stfd	f25,  0x08c8(r1)
	stfd	f26,  0x08d0(r1)
	stfd	f27,  0x08d8(r1)
	stfd	f28,  0x08e0(r1)
	stfd	f29,  0x08e8(r1)
	stfd	f30,  0x08f0(r1)
	stfd	f31,  0x08f8(r1)
	mffs	f31
	lwz		r0,  0x08fc(r1)
	stfd	f31,  0x08fc(r1)
	stw		r0,  0x08fc(r1)
	bne		cr1, @0x260

	if		&TYPE('NKDebugShim') != 'UNDEFINED'
			b		@go_here_to_use_saved_debug_command
	endif

@0x23c
	lwz		r1, 0(0)
	addi	r1, r1, 1
	stw		r1, 0(0)

	li		r1, 0
	dcbst	r1, r1

	bl		getchar

;	gets kdp from print!!!
	cmpwi	r8, -0x01
	bne		@0x260
	b		@0x23c

@0x260
	lwz		r8,  0x0edc(r1)
	ori		r8, r8,  0x02
	stw		r8,  0x0edc(r1)
	_log	'½ NanoKernel debugger^n'

@prompt

	if		&TYPE('NKDebugShim') != 'UNDEFINED'
		b		@NKDebugShimCode
	endif

	_log	'½ '	;	thats an omega, btw
	li		r17,  0x00			;	r17 = charcount
	stw		r17, -0x08fc(r1)

@input_busywait
	bl		getchar
	cmpwi	r8, -1
	beq		@input_busywait

	mr		r16, r8
	cmpwi	r16, 8				; backspace
	cmpwi	cr1, r17, 0
	bne		@not_backspace
	ble		cr1, @input_busywait


	;	Backspace, wipe position, then backspace again!
	subi	r17, r17, 1
	li		r8, 8
	bl		Printc
	li		r8, ' '
	bl		Printc
	li		r8, 8
	bl		Printc

	b		@input_busywait
@not_backspace

	;	If 
	cmpwi	cr2, r17, 95
	addi	r18, r1, -0x960			;	prepare to copy the line!
	blt		cr2, @short_line
	_log	'^b'
	b		@input_busywait

@0x30c
	addi	r17, r17, 1				;	accept the character as an addition to the line
	mr		r8, r16
	bl		Printc
	b		@input_busywait
@short_line

	cmpwi	r16, 13
	stbx	r16, r17, r18
	bne		@0x30c
	li		r16,  0x00
	stbx	r16, r17, r18
	_log	'^n'


@go_here_to_use_saved_debug_command


;	Now a line is expected to be committed:

	addi	r15, r1, -0x960

;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	beq		@prompt
	bl		@load_commands
	mflr	r16
	bl		@load_tbl
	mflr	r17

;	r16 = command strings
;	r17 = lut
	bl		cmd_lookup
;	cr0 = found
;	r17 = ptr to lut entry

	bne		@bad_command
	bl		@load_tbl
	mflr	r16
	lwz		r17,  0x0000(r17)
	add		r16, r16, r17
	mtlr	r16

	blr

@bad_command
	_log	'???^n'
	b		@prompt

@load_commands
	blrl
	string	CString
	dc.b	'dm'
	dc.b	'dml'
	dc.b	'g'
	dc.b	'id'
	dc.b	'kd'
	dc.b	'td'
	dc.b	'?'
	dc.b	'help'
	dc.b	0xff
	align	2

@load_tbl
	blrl

@tbl
	dc.l	@cmd_dumpmem_physical - @tbl
	dc.l	@cmd_dumpmem_logical - @tbl
	dc.l	@cmd_goto - @tbl
	dc.l	@cmd_opaque_id_info - @tbl
	dc.l	@cmd_display_kern_data - @tbl
	dc.l	@cmd_dump_registers - @tbl
	dc.l	@cmd_help - @tbl
	dc.l	@cmd_help - @tbl
	dc.l	0

@cmd_help
	_log	'Commands:^n'
	_log	' dm  address [length]  -- Display physical^n'
	_log	' dml address [length]  -- Display logical^n'
	_log	' g  [address]          -- Go resume^n'
	_log	' id [-all -p -t -tm -q -s -r -c -sp -e -cg -a -n -nc]^n'
	_log	' id  idvalue           -- Obtain opaque ID info^n'
	_log	' kd                    -- Display kernel data^n'
	_log	' td                    -- Dump registers^n'
	b		@prompt

@cmd_dumpmem_physical
;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	beq		@missing_physical_addr
	bl		major_0x187b0
	bne		@bad_length_1
	mr		r30, r16
	li		r31,  0x10

;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	beq		@0x5e0
	bl		major_0x187b0
	bne		@bad_length_1
	mr		r31, r16

@0x5e0
	addi	r31, r31,  0x03
	rlwinm	r31, r31,  0,  0, 29
	mr		r16, r30
	mr		r17, r31
	bl		print_memory
	b		@prompt

@missing_physical_addr
	_log	'Need a physical address^n'
	b		@prompt

@bad_length_1
	_log	'Length must be a hexadecimal value^n'
	b		@prompt

@cmd_dumpmem_logical
	_log	'Logical memory^n'

;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	beq		@missing_logical_addr
	bl		major_0x187b0
	bne		@bad_length_2
	mr		r30, r16
	li		r31,  0x10

;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	beq		@0x6b0
	bl		major_0x187b0
	bne		@bad_length_2
	mr		r31, r16

@0x6b0
	addi	r31, r31,  0x03
	rlwinm	r31, r31,  0,  0, 29
	mr		r16, r30
	mr		r17, r31
	bl		print_memory_logical
	b		@prompt

@missing_logical_addr
	_log	'Need a logical address^n'
	b		@prompt

@bad_length_2
	_log	'Length must be a hexadecimal value^n'
	b		@prompt

@cmd_goto
;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	lwz		r31,  0x0904(r1)
	beq		@0x748
	bl		major_0x187b0
	bne		@bad_resume_address
	stw		r16,  0x0904(r1)

@0x748

@NKDebugShimCode
	_log	'Resuming at '
	lwz		r31,  0x0904(r1)
	mr		r8, r31
	bl		Printw
	_log	' - wish me luck.^n'
	bl		prereturn
	lwz		r8,  0x0904(r1)

	_AssertAndRelease	PSA.ThudLock, scratch=r9

	mtlr	r8
	blr

@bad_resume_address
	_log	'Need hexadecimal value for resume address^n'
	b		@prompt

@cmd_opaque_id_info
;	r15 = start
	bl		next_cmd_word
;	r15 = ptr
;	r16 = char

	cmpwi	r16,  0x00
	beq		@missing_opaque_id
	bl		@load_id_args
	mflr	r16
	li		r17,  0x00

;	r16 = command strings
;	r17 = lut
	bl		cmd_lookup
;	cr0 = found
;	r17 = ptr to lut entry

	bne		@0x884
	li		r29,  0x00
	li		r30,  0x00
	srwi	r31, r17,  2

@0x82c
	mr		r8, r30
	mr		r9, r31
	bl		GetNextIDOfClass
	mr.		r30, r8
	beq		@0x868
	mr		r8, r8
	bl		Printw
	addi	r29, r29,  0x01
	andi.	r29, r29,  0x07
	bne		@0x82c
	_log	'^n'
	b		@0x82c

@0x868
	cmpwi	r29,  0x00
	beq		@prompt
	_log	'^n'
	b		@prompt

@0x884
	bl		major_0x187b0
	bne		@bad_opaque_id
	mr		r30, r16
	mr		r8, r16

;	r8 = id
	bl		LookupID
;	r8 = something not sure what
;	r9 = 0:inval, 1:proc, 2:task, 3:timer, 4:q, 5:sema, 6:cr, 7:cpu, 8:addrspc, 9:evtg, 10:cohg, 11:area, 12:not, 13:log

	mr		r31, r8
	_log	'ID '
	mr		r8, r30
	bl		Printw
	bl		@load_id_kind_strings
	mflr	r17
	slwi	r18, r9,  4
	add		r8, r17, r18
	bl		PrintS
	cmpwi	r9,  0x00
	beq		@0x978
	_log	' at '
	mr		r8, r31
	bl		Printw
	_log	'^n'
	mr		r16, r31
	bl		@load_more_jumps
	mflr	r17
	slwi	r18, r9,  2
	lwzx	r17, r17, r18
	bl		print_memory
	b		@prompt

@missing_opaque_id
	_log	'Need an opaque ID^n'
	b		@prompt

@bad_opaque_id
	_log	'ID must be a hexadecimal value^n'
	b		@prompt

@0x978
	_log	'^n'
	b		@prompt

@load_id_kind_strings
	blrl
	string	CString
	dc.b	'is invalid.    '
	dc.b	'Process        '
	dc.b	'Task           '
	dc.b	'Timer          '
	dc.b	'Queue          '
	dc.b	'Semaphore      '
	dc.b	'Critical Region'
	dc.b	'Cpu            '
	dc.b	'Address Space  '
	dc.b	'Event Group    '
	dc.b	'Coherence Group'
	dc.b	'Area           '
	dc.b	'Notification   '
	dc.b	'Console Log    '
	align	2

@load_more_jumps
	blrl
	dc.l	0
	dc.l	Process.Size
	dc.l	Task.Size
	dc.l	Timer.Size
	dc.l	Queue.Size
	dc.l	Semaphore.Size
	dc.l	CriticalRegion.Size
	dc.l	CPU.Size
	dc.l	AddressSpace.Size
	dc.l	EventGroup.Size
	dc.l	CoherenceGroup.Size
	dc.l	Area.Size
	dc.l	Notification.Size
	dc.l	ConsoleLog.Size

@load_id_args
	blrl
	dc.b	'-all'
	dc.b	'-p'
	dc.b	'-t'
	dc.b	'-tm'
	dc.b	'-q'
	dc.b	'-s'
	dc.b	'-r'
	dc.b	'-c'
	dc.b	'-sp'
	dc.b	'-e'
	dc.b	'-cg'
	dc.b	'-a'
	dc.b	'-n'
	dc.b	'-nc'
	dc.b	0xff
	align	2

@cmd_display_kern_data
	mfsprg	r17, 0

	_log	'Kernel version '
	lhz		r8, KDP.InfoRecord + InfoRecord.NKNanoKernelInfoVer(r1)
	bl		Printh

	_log	'Code base '
	lwz		r8, KDP.PA_NanoKernelCode(r1)
	bl		Printw

	_log	'PSA '
	addi	r8, r17, PSA.Base
	bl		Printw

	_log	'KDP '
	mr		r8, r1
	bl		Printw

	_log	'EDP '
	lwz		r8, KDP.PA_EmulatorData(r1)
	bl		Printw

	_log	'^nCurrent EWA '
	mr		r8, r17
	bl		Printw

	_log	' is CPU '
	lhz		r8, EWA.CPUIndex(r17)
	bl		Printh

	_log	' ID-'
	lwz		r8, -0x0340(r17)
	bl		Printw

	lwz		r18, EWA.PA_CurTask(r17)
	_log	'^nCurrent task '
	mr		r8, r18
	bl		Printw

	_log	'ID-'
	lwz		r8, Task.ID(r18)
	bl		Printw

	_log	'name \"'
	lwz		r8, Task.Name(r18)
	rotlwi	r8, r8, 8
	bl		Printc
	rotlwi	r8, r8, 8
	bl		Printc
	rotlwi	r8, r8, 8
	bl		Printc
	rotlwi	r8, r8, 8
	bl		Printc

	_log	'\" Owning process '
	lwz		r8,  0x006c(r18)
	bl		Printw

	_log	' ID-'
	lwz		r8,  0x0060(r18)
	bl		Printw

	_log	'^nAddress Space '
	lwz		r18, -0x001c(r17)
	mr		r8, r18
	bl		Printw

	_log	' ID-'
	lwz		r8,  0x0000(r18)
	bl		Printw

	_log	'^n'

	bl		print_xpt_info
	b		@prompt

@cmd_dump_registers
	_log	'Kernel registers:^n'
	bl		print_sprgs
	bl		print_sprs
	_log	'^n'
	bl		print_segment_registers
	_log	'^n'
	bl		print_gprs
	b		@prompt



	mflr	r16
	lwz		r17,  0x07b4(r1)
	rlwinm	r17, r17, 16, 16, 27
	cmpwi	r17,  0x6800
	bne		major_0x18040_0x100
	lwz		r17,  0x071c(r1)
	srwi	r17, r17, 16
	andi.	r17, r17,  0xffa0
	cmpwi	r17,  0x2a0
	bne		major_0x18040_0x64
	_log	'Caused by emulator termination request^n'
	b		major_0x18040_0x9c

major_0x18040_0x64
	_log	'Caused by unhandled emulator exception^n'

major_0x18040_0x9c
	lwz		r17,  0x079c(r1)
	lwz		r18,  0x0704(r1)
	subf	r17, r18, r17
	cmpwi	r17,  0x100
	cmpwi	cr1, r17, -0x100
	bgt		major_0x18040_0x100
	blt		cr1, major_0x18040_0x100
	_log	'Looks like interrupt stack overflow by os or application^n'

major_0x18040_0x100
	mtlr	r16
	blr



print_xpt_info	;	OUTSIDE REFERER
	mflr	r16
	lwz		r18,  0x064c(r1)
	llabel	r18, NKBtm
	add		r19, r18, r19
	_log	'Termination caller '
	lwz		r20,  0x0904(r1)
	mr		r8, r20
	bl		Printw
	subf.	r21, r18, r20
	cmplw	cr1, r20, r19
	blt		print_xpt_info_0x84
	bge		cr1, print_xpt_info_0x84
	_log	'( NK+'
	mr		r8, r21
	bl		Printw
	_log	')^n'

print_xpt_info_0x84
	_log	' Last exception at '
	mfspr	r8, srr1
	bl		Printw
	mfspr	r8, srr0
	bl		Printw
	mfspr	r8, srr0
	subf.	r21, r18, r8
	cmplw	cr1, r8, r19
	blt		print_xpt_info_0xf8
	bge		cr1, print_xpt_info_0xf8
	_log	'( NK+'
	mr		r8, r21
	bl		Printw
	_log	')'

print_xpt_info_0xf8
	_log	'^n'
	mtlr	r16
	blr



;	                      print_sprgs

;	Goldmine. Tells me what the SPRGs do!

print_sprgs	;	OUTSIDE REFERER
	mflr	r16
	_log	'SPRGs  ewa: '
	mfsprg	r8, 0
	bl		Printw
	_log	' r1: '
	mfsprg	r8, 1
	bl		Printw
	_log	' lr: '
	mfsprg	r8, 2
	bl		Printw
	_log	' vecBase: '
	mfsprg	r8, 3
	bl		Printw
	_log	'^n'
	mtlr	r16
	blr



;	                       print_sprs

;	Both user-mode and supervisor-only

print_sprs	;	OUTSIDE REFERER
	mflr	r16
	_log	'       cr:  '
	lwz		r8,  0x0780(r1)
	bl		Printw
	_log	'xer: '
	lwz		r8,  0x0788(r1)
	bl		Printw
	_log	'ctr: '
	lwz		r8,  0x0790(r1)
	bl		Printw
	_log	'lr: '
	lwz		r8,  0x078c(r1)
	bl		Printw
	_log	'^n       dsisr: '
	lwz		r8,  0x0798(r1)
	bl		Printw
	_log	'dar:'
	lwz		r8,  0x079c(r1)
	bl		Printw
	_log	'pvr: '
	lwz		r8,  0x0794(r1)
	bl		Printw
	_log	'^n'
	mtlr	r16
	blr



print_segment_registers	;	OUTSIDE REFERER
	mflr	r16
	_log	' sr0-sr7  '
	li		r17,  0x08
	mtctr	r17
	li		r18,  0x00

print_segment_registers_0x28
	mfsrin	r8, r18
	addis	r18, r18,  0x1000
	bl		Printw
	bdnz	print_segment_registers_0x28
	_log	'^n sr8-sr15 '
	li		r17,  0x08
	mtctr	r17

print_segment_registers_0x5c
	mfsrin	r8, r18
	addis	r18, r18,  0x1000
	bl		Printw
	bdnz	print_segment_registers_0x5c
	_log	'^n'
	mtlr	r16
	blr



print_gprs	;	OUTSIDE REFERER
	mflr	r16
	addi	r17, r1,  0x6fc
	_log	' r0-r7    '
	li		r18,  0x08
	mtctr	r18

print_gprs_0x28
	lwzu	r8,  0x0004(r17)
	bl		Printw
	bdnz	print_gprs_0x28
	_log	'^n r8-r15   '
	li		r18,  0x08
	mtctr	r18

print_gprs_0x58
	lwzu	r8,  0x0004(r17)
	bl		Printw
	bdnz	print_gprs_0x58
	_log	'^n r16-r23  '
	li		r18,  0x08
	mtctr	r18

print_gprs_0x88
	lwzu	r8,  0x0004(r17)
	bl		Printw
	bdnz	print_gprs_0x88
	_log	'^n r24-r31  '
	li		r18,  0x08
	mtctr	r18

print_gprs_0xb8
	lwzu	r8,  0x0004(r17)
	bl		Printw
	bdnz	print_gprs_0xb8
	_log	'^n'
	mtlr	r16
	blr



print_memory	;	OUTSIDE REFERER
	mflr	r18
	srwi	r17, r17,  4

print_memory_0x8
	mr		r8, r16
	bl		Printw
	_log	' '
	lwz		r8,  0x0000(r16)
	bl		Printw
	lwz		r8,  0x0004(r16)
	bl		Printw
	lwz		r8,  0x0008(r16)
	bl		Printw
	lwz		r8,  0x000c(r16)
	bl		Printw
	_log	'  *'
	li		r8,  0x10
	addi	r16, r16, -0x01
	mtctr	r8

print_memory_0x60
	lbzu	r8,  0x0001(r16)
	cmpwi	r8,  0xff
	beq		print_memory_0x74
	cmpwi	r8,  0x20
	bgt		print_memory_0x78

print_memory_0x74
	li		r8,  0x20

print_memory_0x78
	bl		Printc
	bdnz	print_memory_0x60
	_log	'*^n'
	addi	r16, r16,  0x01
	addi	r17, r17, -0x01
	bl		getchar
	cmpwi	r8, -0x01
	bne		print_memory_0xb0
	cmpwi	r17,  0x00
	bne		print_memory_0x8

print_memory_0xb0
	_log	'^n'
	mtlr	r18
	blr



print_memory_logical	;	OUTSIDE REFERER
	mflr	r18
	srwi	r17, r17,  4

print_memory_logical_0x8
	mr		r8, r16
	bl		Printw
	_log	' '
	li		r19,  0x10

print_memory_logical_0x24
	mr		r27, r16
	bl		PagingFunc1
	beq		print_memory_logical_0x5c
	blt		print_memory_logical_0x48
	_log	'..'
	b		print_memory_logical_0x6c

print_memory_logical_0x48
	_log	'--'
	b		print_memory_logical_0x6c

print_memory_logical_0x5c
	bl		PagingL2PWithoutBATs
	rlwimi	r31, r27,  0, 20, 31
	lbz		r8,  0x0000(r31)
	bl		print_unknown

print_memory_logical_0x6c
	addi	r16, r16,  0x01
	addi	r19, r19, -0x01
	andi.	r8, r19,  0x03
	bne		print_memory_logical_0x84
	li		r8,  0x20
	bl		Printc

print_memory_logical_0x84
	cmpwi	r19,  0x00
	bgt		print_memory_logical_0x24
	_log	'  *'
	li		r8,  0x10
	addi	r16, r16, -0x10
	mtctr	r8

print_memory_logical_0xac
	mr		r27, r16
	bl		PagingFunc1
	li		r8,  0x20
	bne		print_memory_logical_0xdc
	bl		PagingL2PWithoutBATs
	rlwimi	r31, r27,  0, 20, 31
	lbz		r8,  0x0000(r31)
	cmpwi	r8,  0xff
	beq		print_memory_logical_0xd8
	cmpwi	r8,  0x20
	bgt		print_memory_logical_0xdc

print_memory_logical_0xd8
	li		r8,  0x20

print_memory_logical_0xdc
	bl		Printc
	addi	r16, r16,  0x01
	bdnz	print_memory_logical_0xac
	_log	'*^n'
	addi	r17, r17, -0x01
	bl		getchar
	cmpwi	r8, -0x01
	bne		print_memory_logical_0x114
	cmpwi	r17,  0x00
	bne		print_memory_logical_0x8

print_memory_logical_0x114
	_log	'^n'
	mtlr	r18
	blr



;	> r16   = command strings
;	> r17   = lut

;	< cr0   = found
;	< r17   = ptr to lut entry

cmd_lookup	;	OUTSIDE REFERER
	addi	r15, r15, -0x01
	addi	r16, r16, -0x01
	mr		r18, r15

cmd_lookup_0xc
	lbzu	r21,  0x0001(r16)
	lbzu	r20,  0x0001(r15)
	cmpwi	r21,  0xff
	cmpwi	cr1, r21,  0x00
	beq		cmd_lookup_0x44
	beq		cr1, cmd_lookup_0x50
	cmpw	r20, r21
	beq		cmd_lookup_0xc

cmd_lookup_0x2c
	lbzu	r21,  0x0001(r16)
	cmpwi	r21,  0x00
	bne		cmd_lookup_0x2c

cmd_lookup_0x38
	addi	r17, r17,  0x04
	mr		r15, r18
	b		cmd_lookup_0xc

cmd_lookup_0x44
	addi	r15, r18,  0x01
	cmpw	r15, r18
	blr

cmd_lookup_0x50
	cmpwi	r20,  0x20
	beqlr
	cmpwi	r20,  0x00
	beqlr
	b		cmd_lookup_0x38



;	> r15   = start

;	< r15   = ptr
;	< r16   = char

next_cmd_word	;	OUTSIDE REFERER
	addi	r15, r15, -0x01

next_cmd_word_0x4
	lbzu	r16,  0x0001(r15)
	cmpwi	r16,  0x20
	beq		next_cmd_word_0x4
	blr



major_0x187b0	;	OUTSIDE REFERER
	addi	r15, r15, -0x01
	li		r16,  0x00

major_0x187b0_0x8
	lbzu	r17,  0x0001(r15)
	cmplwi	r17,  0x30
	cmplwi	cr1, r17,  0x39
	blt		major_0x187b0_0x28
	bgt		cr1, major_0x187b0_0x28
	slwi	r16, r16,  4
	rlwimi	r16, r17,  0, 28, 31
	b		major_0x187b0_0x8

major_0x187b0_0x28
	cmplwi	r17,  0x61
	cmplwi	cr1, r17,  0x66
	blt		major_0x187b0_0x48
	bgt		cr1, major_0x187b0_0x48
	addi	r17, r17, -0x57
	slwi	r16, r16,  4
	rlwimi	r16, r17,  0, 28, 31
	b		major_0x187b0_0x8

major_0x187b0_0x48
	cmplwi	r17,  0x41
	cmplwi	cr1, r17,  0x46
	blt		major_0x187b0_0x68
	bgt		cr1, major_0x187b0_0x68
	addi	r17, r17, -0x37
	slwi	r16, r16,  4
	rlwimi	r16, r17,  0, 28, 31
	b		major_0x187b0_0x8

major_0x187b0_0x68
	cmpwi	r17,  0x00
	beqlr
	cmpwi	r17,  0x20
	blr


prereturn	;	OUTSIDE REFERER
	lwz		r1, EWA.PA_KDP(r1)

	mfmsr	r0
	_bset	r0, r0, MSR_FPbit
	mtmsr	r0
	isync

	lfd		f31,  0x08fc(r1)
	mtfsf	0xff, f31
	lfd		f0,  0x0800(r1)
	lfd		f1,  0x0808(r1)
	lfd		f2,  0x0810(r1)
	lfd		f3,  0x0818(r1)
	lfd		f4,  0x0820(r1)
	lfd		f5,  0x0828(r1)
	lfd		f6,  0x0830(r1)
	lfd		f7,  0x0838(r1)
	lfd		f8,  0x0840(r1)
	lfd		f9,  0x0848(r1)
	lfd		f10,  0x0850(r1)
	lfd		f11,  0x0858(r1)
	lfd		f12,  0x0860(r1)
	lfd		f13,  0x0868(r1)
	lfd		f14,  0x0870(r1)
	lfd		f15,  0x0878(r1)
	lfd		f16,  0x0880(r1)
	lfd		f17,  0x0888(r1)
	lfd		f18,  0x0890(r1)
	lfd		f19,  0x0898(r1)
	lfd		f20,  0x08a0(r1)
	lfd		f21,  0x08a8(r1)
	lfd		f22,  0x08b0(r1)
	lfd		f23,  0x08b8(r1)
	lfd		f24,  0x08c0(r1)
	lfd		f25,  0x08c8(r1)
	lfd		f26,  0x08d0(r1)
	lfd		f27,  0x08d8(r1)
	lfd		f28,  0x08e0(r1)
	lfd		f29,  0x08e8(r1)
	lfd		f30,  0x08f0(r1)
	lfd		f31,  0x08f8(r1)

	lwz		r0,  0x07c0(r1)
	mtsr	 0x00, r0
	lwz		r0,  0x07c4(r1)
	mtsr	 0x01, r0
	lwz		r0,  0x07c8(r1)
	mtsr	 0x02, r0
	lwz		r0,  0x07cc(r1)
	mtsr	 0x03, r0
	lwz		r0,  0x07d0(r1)
	mtsr	 0x04, r0
	lwz		r0,  0x07d4(r1)
	mtsr	 0x05, r0
	lwz		r0,  0x07d8(r1)
	mtsr	 0x06, r0
	lwz		r0,  0x07dc(r1)
	mtsr	 0x07, r0
	lwz		r0,  0x07e0(r1)
	mtsr	 0x08, r0
	lwz		r0,  0x07e4(r1)
	mtsr	 0x09, r0
	lwz		r0,  0x07e8(r1)
	mtsr	 0x0a, r0
	lwz		r0,  0x07ec(r1)
	mtsr	 0x0b, r0
	lwz		r0,  0x07f0(r1)
	mtsr	 0x0c, r0
	lwz		r0,  0x07f4(r1)
	mtsr	 0x0d, r0
	lwz		r0,  0x07f8(r1)
	mtsr	 0x0e, r0
	lwz		r0,  0x07fc(r1)
	mtsr	 0x0f, r0

	lwz		r0,  0x07a8(r1)
	mtspr	dec, r0

	lwz		r0,  0x07b4(r1)
	mtspr	srr0, r0
	lwz		r0,  0x07b8(r1)
	mtspr	srr1, r0

	lwz		r0,  0x07bc(r1)
	mtmsr	r0

	mfpvr	r0
	rlwinm.	r0, r0,  0,  0, 14

	bne		@not_601
	lwz		r0,  0x0784(r1)
	mtspr	mq, r0
@not_601

	lwz		r0,  0x0788(r1)
	mtxer	r0
	lwz		r0,  0x078c(r1)
	mtsprg	2, r0
	lwz		r0,  0x0790(r1)
	mtctr	r0

	;	Only because this crashes QEMU

	if		&TYPE('NKDebugShim') = 'UNDEFINED'
		lwz		r0,  0x0794(r1)
		mtspr	pvr, r0
	endif

	lwz		r0,  0x0798(r1)
	mtspr	dsisr, r0
	lwz		r0,  0x079c(r1)
	mtspr	dar, r0
	lwz		r0,  0x0780(r1)
	mtcr	r0
	lwz		r0,  0x0700(r1)
	lwz		r2,  0x0704(r1)
	mtsprg	1, r2
	lmw		r2,  0x0708(r1)


	blr

	align	5
