.option pic
	.text
	.section	.rodata
	.align	3
.LC2:
	.string	"[%d] %7.4f + %7.4fi\n"
	.text
	.align	2
	.globl	print_fft
	.type	print_fft, @function
print_fft:
	addi	sp,sp,-64
	sd	ra,56(sp)
	sd	s0,48(sp)
	addi	s0,sp,64
	sd	a0,-40(s0)
	sd	a1,-48(s0)
	mv	a5,a2
	sw	a5,-52(s0)
	sw	zero,-20(s0)
	j	.L2
.L3:
	lw	a5,-20(s0)
	slli	a5,a5,2
	ld	a4,-40(s0)
	add	a5,a4,a5
	flw	fa5,0(a5)
	fcvt.d.s	fa4,fa5
	lw	a5,-20(s0)
	slli	a5,a5,2
	ld	a4,-48(s0)
	add	a5,a4,a5
	flw	fa5,0(a5)
	fcvt.d.s	fa5,fa5
	lw	a5,-20(s0)
	fmv.x.d	a3,fa5
	fmv.x.d	a2,fa4
	mv	a1,a5
	lla	a0,.LC2
	call	printf@plt
	lw	a5,-20(s0)
	addiw	a5,a5,1
	sw	a5,-20(s0)
.L2:
	lw	a5,-20(s0)
	mv	a4,a5
	lw	a5,-52(s0)
	sext.w	a4,a4
	sext.w	a5,a5
	blt	a4,a5,.L3
	nop
	nop
	ld	ra,56(sp)
	ld	s0,48(sp)
	addi	sp,sp,64
	jr	ra
	.section	.rodata
	.align	3
.LC3:
	.string	"  [%d] %.4f\n"
	.text
	.align	2
	.globl	print_array
	.type	print_array, @function
print_array:
	addi	sp,sp,-48
	sd	ra,40(sp)
	sd	s0,32(sp)
	addi	s0,sp,48
	sd	a0,-40(s0)
	mv	a5,a1
	sw	a5,-44(s0)
	sw	zero,-20(s0)
	j	.L5
.L6:
	lw	a5,-20(s0)
	slli	a5,a5,2
	ld	a4,-40(s0)
	add	a5,a4,a5
	flw	fa5,0(a5)
	fcvt.d.s	fa5,fa5
	lw	a5,-20(s0)
	fmv.x.d	a2,fa5
	mv	a1,a5
	lla	a0,.LC3
	call	printf@plt
	lw	a5,-20(s0)
	addiw	a5,a5,1
	sw	a5,-20(s0)
.L5:
	lw	a5,-20(s0)
	mv	a4,a5
	lw	a5,-44(s0)
	sext.w	a4,a4
	sext.w	a5,a5
	blt	a4,a5,.L6
	nop
	nop
	ld	ra,40(sp)
	ld	s0,32(sp)
	addi	sp,sp,48
	jr	ra
	.align	2
	.type	read_cycles, @function
read_cycles:
	addi	sp,sp,-32
	sd	s0,24(sp)
	addi	s0,sp,32
#APP
	rdcycle a5
#NO_APP
	sd	a5,-24(s0)
	ld	a5,-24(s0)
	mv	a0,a5
	ld	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.align	2
	.type	stack_iterative, @function
stack_iterative:
	addi	sp,sp,-32
	sd	s0,24(sp)
	addi	s0,sp,32
	mv	a5,a0
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a4,a5
	mv	a5,a4
	slliw	a5,a5,1
	addw	a5,a5,a4
	slliw	a5,a5,2
	sext.w	a5,a5
	addiw	a5,a5,96
	sext.w	a5,a5
	mv	a0,a5
	ld	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.align	2
	.type	stack_recursive, @function
stack_recursive:
	addi	sp,sp,-48
	sd	s0,40(sp)
	addi	s0,sp,48
	mv	a5,a0
	sw	a5,-36(s0)
	sw	zero,-24(s0)
	lw	a5,-36(s0)
	sw	a5,-20(s0)
	j	.L12
.L13:
	lw	a5,-20(s0)
	sraiw	a5,a5,1
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	addiw	a5,a5,1
	sw	a5,-24(s0)
.L12:
	lw	a5,-20(s0)
	sext.w	a4,a5
	li	a5,1
	bgt	a4,a5,.L13
	lw	a5,-36(s0)
	mv	a4,a5
	mv	a5,a4
	slliw	a5,a5,1
	addw	a5,a5,a4
	slliw	a5,a5,2
	sext.w	a5,a5
	addiw	a5,a5,48
	sext.w	a4,a5
	lw	a5,-24(s0)
	addiw	a5,a5,1
	sext.w	a5,a5
	mv	a3,a5
	mv	a5,a3
	slliw	a5,a5,3
	subw	a5,a5,a3
	slliw	a5,a5,4
	sext.w	a5,a5
	addw	a5,a4,a5
	sext.w	a5,a5
	mv	a0,a5
	ld	s0,40(sp)
	addi	sp,sp,48
	jr	ra

	.section	.rodata
	.align	3
.LC27:	.string	"============================================"
.LC28:	.string	"  BIT REVERSAL TEST (n=8, log2(n)=3)"
.LC30:	.string	"reverse_bits(0, 3) = %d  (expected 0)  [000 -> 000]\n"
.LC31:	.string	"reverse_bits(1, 3) = %d  (expected 4)  [001 -> 100]\n"
.LC32:	.string	"reverse_bits(2, 3) = %d  (expected 2)  [010 -> 010]\n"
.LC33:	.string	"reverse_bits(3, 3) = %d  (expected 6)  [011 -> 110]\n"
.LC34:	.string	"reverse_bits(4, 3) = %d  (expected 1)  [100 -> 001]\n"
.LC35:	.string	"reverse_bits(5, 3) = %d  (expected 5)  [101 -> 101]\n"
.LC36:	.string	"reverse_bits(6, 3) = %d  (expected 3)  [110 -> 011]\n"
.LC37:	.string	"reverse_bits(7, 3) = %d  (expected 7)  [111 -> 111]\n"
.LC39:	.string	"  ARRAY REORDERING TEST"
.LC40:	.string	"Before reorder:"
.LC41:	.string	"After reorder (expected: 0 4 2 6 1 5 3 7):"
.LC42:	.string	"  CORRECTNESS CHECK  (step function, n=8)"
.LC43:	.string	"\n--- Iterative FFT ---"
.LC44:	.string	"\n--- Recursive FFT ---"
.LC47:	.string	"  SUMMARY TABLE"
.LC52:	.string	"N"
.LC51:	.string	"Iter Cycles"
.LC50:	.string	"Rec Cycles"
.LC49:	.string	"Iter Mem(B)"
.LC48:	.string	"Rec Mem(B)"
.LC53:	.string	"%-6s %-12s %-12s %-12s %-12s\n"
.LC55:	.string	"------"
.LC54:	.string	"------------"
.LC56:	.string	"%-6d %-12lu %-12lu %-12d %-12d\n"
	# xr = {0,1,2,3,4,5,6,7} as IEEE 754 floats
	.align	3
.LC0:
	.word	0
	.word	1065353216
	.word	1073741824
	.word	1077936128
	.word	1082130432
	.word	1084227584
	.word	1086324736
	.word	1088421888
	# step fn: {1,1,1,1,0,0,0,0} as IEEE 754 floats
	.align	3
.LC1:
	.word	1065353216
	.word	1065353216
	.word	1065353216
	.word	1065353216
	.word	0
	.word	0
	.word	0
	.word	0

	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-288
	sd	ra,280(sp)
	sd	s0,272(sp)
	sd	s1,264(sp)
	addi	s0,sp,288

	# ── BIT REVERSAL TEST ──────────────────────────────────────
	lla	a0,.LC27; call puts@plt
	lla	a0,.LC28; call puts@plt
	lla	a0,.LC27; call puts@plt
	li a1,3; li a0,0; call reverse_bits@plt; mv a1,a0; lla a0,.LC30; call printf@plt
	li a1,3; li a0,1; call reverse_bits@plt; mv a1,a0; lla a0,.LC31; call printf@plt
	li a1,3; li a0,2; call reverse_bits@plt; mv a1,a0; lla a0,.LC32; call printf@plt
	li a1,3; li a0,3; call reverse_bits@plt; mv a1,a0; lla a0,.LC33; call printf@plt
	li a1,3; li a0,4; call reverse_bits@plt; mv a1,a0; lla a0,.LC34; call printf@plt
	li a1,3; li a0,5; call reverse_bits@plt; mv a1,a0; lla a0,.LC35; call printf@plt
	li a1,3; li a0,6; call reverse_bits@plt; mv a1,a0; lla a0,.LC36; call printf@plt
	li a1,3; li a0,7; call reverse_bits@plt; mv a1,a0; lla a0,.LC37; call printf@plt

	# ── ARRAY REORDERING TEST ──────────────────────────────────
	lla	a0,.LC27; call puts@plt
	lla	a0,.LC39; call puts@plt
	lla	a0,.LC27; call puts@plt
	lla	a5,.LC0
	ld a2,0(a5); ld a3,8(a5); ld a4,16(a5); ld a5,24(a5)
	sd a2,-104(s0); sd a3,-96(s0); sd a4,-88(s0); sd a5,-80(s0)
	sw zero,-72(s0); sw zero,-68(s0); sw zero,-64(s0); sw zero,-60(s0)
	sw zero,-56(s0); sw zero,-52(s0); sw zero,-48(s0); sw zero,-44(s0)
	lla	a0,.LC40; call puts@plt
	addi a0,s0,-104; li a1,8; call print_array
	addi a5,s0,-104; addi a4,s0,-72; li a2,8; mv a1,a4; mv a0,a5
	call	bit_reverse_array@plt
	lla	a0,.LC41; call puts@plt
	addi a0,s0,-104; li a1,8; call print_array

	# ── CORRECTNESS CHECK n=8 ──────────────────────────────────
	lla	a0,.LC27; call puts@plt
	lla	a0,.LC42; call puts@plt
	lla	a0,.LC27; call puts@plt
	li a5,8; sw a5,-272(s0)
	# malloc tw_r, tw_i (n/2 * 4 bytes)
	lw a5,-272(s0); srliw a4,a5,31; addw a5,a4,a5; sraiw a5,a5,1; sext.w a5,a5; slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-264(s0)
	lw a5,-272(s0); srliw a4,a5,31; addw a5,a4,a5; sraiw a5,a5,1; sext.w a5,a5; slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-256(s0)
	lw a5,-272(s0); mv a2,a5; ld a1,-256(s0); ld a0,-264(s0)
	call	generate_twiddle_factors@plt
	# load x_r={1,1,1,1,0,0,0,0} x_i={0...} onto stack
	lla a5,.LC1; ld a2,0(a5); ld a3,8(a5); ld a4,16(a5); ld a5,24(a5)
	sd a2,-168(s0); sd a3,-160(s0); sd a4,-152(s0); sd a5,-144(s0)
	sw zero,-136(s0); sw zero,-132(s0); sw zero,-128(s0); sw zero,-124(s0)
	sw zero,-120(s0); sw zero,-116(s0); sw zero,-112(s0); sw zero,-108(s0)
	lla	a0,.LC43; call puts@plt
	lw a4,-272(s0); addi a1,s0,-136; addi a5,s0,-168; ld a3,-256(s0); ld a2,-264(s0); mv a0,a5
	call	fft_1d_iterative@plt
	lw a3,-272(s0); addi a4,s0,-136; addi a5,s0,-168; mv a2,a3; mv a1,a4; mv a0,a5
	call	print_fft
	# reload x_r2, x_i2
	lla a5,.LC1; ld a2,0(a5); ld a3,8(a5); ld a4,16(a5); ld a5,24(a5)
	sd a2,-104(s0); sd a3,-96(s0); sd a4,-88(s0); sd a5,-80(s0)
	sw zero,-72(s0); sw zero,-68(s0); sw zero,-64(s0); sw zero,-60(s0)
	sw zero,-56(s0); sw zero,-52(s0); sw zero,-48(s0); sw zero,-44(s0)
	lla	a0,.LC44; call puts@plt
	lw a4,-272(s0); addi a1,s0,-72; addi a5,s0,-104; ld a3,-256(s0); ld a2,-264(s0); mv a0,a5
	call	fft_1d_recursive@plt
	lw a3,-272(s0); addi a4,s0,-72; addi a5,s0,-104; mv a2,a3; mv a1,a4; mv a0,a5
	call	print_fft
	ld a0,-264(s0); call free@plt
	ld a0,-256(s0); call free@plt

	# ── SUMMARY TABLE ──────────────────────────────────────────
	lla	a0,.LC27; call puts@plt
	lla	a0,.LC47; call puts@plt
	lla	a0,.LC27; call puts@plt
	lla a5,.LC48; lla a4,.LC49; lla a3,.LC50; lla a2,.LC51; lla a1,.LC52; lla a0,.LC53; call printf@plt
	lla a5,.LC54; lla a4,.LC54; lla a3,.LC54; lla a2,.LC54; lla a1,.LC55; lla a0,.LC53; call printf@plt
	# sizes on stack
	li a5,8;  sw a5,-72(s0)
	li a5,16; sw a5,-68(s0)
	li a5,32; sw a5,-64(s0)
	sw zero,-284(s0)
	j	.L29
.L34:
	lw a5,-284(s0); slli a5,a5,2; addi a5,a5,-32; add a5,a5,s0; lw a5,-40(a5); sw a5,-268(s0)
	# malloc tw_r, tw_i
	lw a5,-268(s0); srliw a4,a5,31; addw a5,a4,a5; sraiw a5,a5,1; sext.w a5,a5; slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-248(s0)
	lw a5,-268(s0); srliw a4,a5,31; addw a5,a4,a5; sraiw a5,a5,1; sext.w a5,a5; slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-240(s0)
	lw a5,-268(s0); mv a2,a5; ld a1,-240(s0); ld a0,-248(s0); call generate_twiddle_factors@plt
	# malloc ir, ii
	lw a5,-268(s0); slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-232(s0)
	lw a5,-268(s0); slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-224(s0)
	# fill ir[k]=(float)k, ii[k]=0
	sw zero,-280(s0); j .L30
.L31:
	lw a5,-280(s0); slli a5,a5,2; ld a4,-232(s0); add a5,a4,a5; lw a4,-280(s0); fcvt.s.w fa5,a4; fsw fa5,0(a5)
	lw a5,-280(s0); slli a5,a5,2; ld a4,-224(s0); add a5,a4,a5; sw zero,0(a5)
	lw a5,-280(s0); addiw a5,a5,1; sw a5,-280(s0)
.L30:
	lw a5,-280(s0); mv a4,a5; lw a5,-268(s0); sext.w a4,a4; sext.w a5,a5; blt a4,a5,.L31
	# measure iterative
	call read_cycles; sd a0,-216(s0)
	lw a5,-268(s0); mv a4,a5; ld a3,-240(s0); ld a2,-248(s0); ld a1,-224(s0); ld a0,-232(s0)
	call fft_1d_iterative@plt
	call read_cycles; mv a4,a0; ld a5,-216(s0); sub a5,a4,a5; sd a5,-208(s0)
	# malloc rr, ri
	lw a5,-268(s0); slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-200(s0)
	lw a5,-268(s0); slli a5,a5,2; mv a0,a5; call malloc@plt; sd a0,-192(s0)
	# fill rr[k]=(float)k, ri[k]=0
	sw zero,-276(s0); j .L32
.L33:
	lw a5,-276(s0); slli a5,a5,2; ld a4,-200(s0); add a5,a4,a5; lw a4,-276(s0); fcvt.s.w fa5,a4; fsw fa5,0(a5)
	lw a5,-276(s0); slli a5,a5,2; ld a4,-192(s0); add a5,a4,a5; sw zero,0(a5)
	lw a5,-276(s0); addiw a5,a5,1; sw a5,-276(s0)
.L32:
	lw a5,-276(s0); mv a4,a5; lw a5,-268(s0); sext.w a4,a4; sext.w a5,a5; blt a4,a5,.L33
	# measure recursive
	call read_cycles; sd a0,-184(s0)
	lw a5,-268(s0); mv a4,a5; ld a3,-240(s0); ld a2,-248(s0); ld a1,-192(s0); ld a0,-200(s0)
	call fft_1d_recursive@plt
	call read_cycles; mv a4,a0; ld a5,-184(s0); sub a5,a4,a5; sd a5,-176(s0)
	# print row
	lw a5,-268(s0); mv a0,a5; call stack_iterative; mv s1,a0
	lw a5,-268(s0); mv a0,a5; call stack_recursive; mv a5,a0
	lw a1,-268(s0); mv a4,s1; ld a3,-176(s0); ld a2,-208(s0)
	lla a0,.LC56; call printf@plt
	# free
	ld a0,-248(s0); call free@plt; ld a0,-240(s0); call free@plt
	ld a0,-232(s0); call free@plt; ld a0,-224(s0); call free@plt
	ld a0,-200(s0); call free@plt; ld a0,-192(s0); call free@plt
	lw a5,-284(s0); addiw a5,a5,1; sw a5,-284(s0)
.L29:
	lw a5,-284(s0); sext.w a4,a5; li a5,2; ble a4,a5,.L34
	li	a0,0
	ld	ra,280(sp); ld s0,272(sp); ld s1,264(sp)
	addi	sp,sp,288
	jr	ra