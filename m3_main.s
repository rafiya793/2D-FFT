# main_vectorized.s 

# __printf_chk wrapper
    .text
    .align 1
    .globl __printf_chk
    .type  __printf_chk, @function
__printf_chk:
    mv      a0, a1
    mv      a1, a2
    mv      a2, a3
    mv      a3, a4
    mv      a4, a5
    mv      a5, a6
    mv      a6, a7
    tail    printf

    .globl my_sin
my_sin:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    call    sinf
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl my_cos
my_cos:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    call    cosf
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl log2_int
log2_int:
    li      t0, 1
    li      a1, 0
.Llog2_loop:
    bge     t0, a0, .Llog2_done
    slli    t0, t0, 1
    addi    a1, a1, 1
    j       .Llog2_loop
.Llog2_done:
    mv      a0, a1
    ret

    .section    .rodata
    .align  3
.LC1:
    .string "OK"
    .align  3
.LC2:
    .string "FAIL"
    .align  3
.LC3:
    .string "PASS"
    .align  3
.LC4:
    .string "\n--- Twiddle Factor Generation  N=%d ---\n"
    .align  3
.LC5:
    .string "  Expected: twr[k]=cos(-2*PI*k/N)  twi[k]=sin(-2*PI*k/N)\n"
    .align  3
.LC8:
    .string "  k=%d  cos=%9.6f (exp %9.6f)  sin=%9.6f (exp %9.6f)  %s\n"
    .align  3
.LC9:
    .string "  Result: %s  |  Cycles: %lu\n"

# ---------------------------------------------------------------------------
# test_twiddle
# ---------------------------------------------------------------------------
    .text
    .align  1
    .type   test_twiddle, @function
test_twiddle:
    addi    sp,sp,-160
    sd  s2,128(sp)
    srai    s2,a0,1
    sd  s1,136(sp)
    slli    s1,s2,2
    sd  s0,144(sp)
    mv  s0,a0
    mv  a0,s1
    sd  ra,152(sp)
    sd  s9,72(sp)
    sd  s10,64(sp)
    sd  s3,120(sp)
    sd  s4,112(sp)
    sd  s5,104(sp)
    sd  s6,96(sp)
    sd  s7,88(sp)
    sd  s8,80(sp)
    sd  s11,56(sp)
    fsd fs0,40(sp)
    fsd fs1,32(sp)
    fsd fs2,24(sp)
    call    malloc
    mv  s10,a0
    mv  a0,s1
    call    malloc
    mv  a2,s0
    la  a1,.LC4
    mv  s9,a0
    li  a0,1
    call    __printf_chk
    la  a0,.LC5
    call    puts
    rdcycle s1
    mv  a2,s0
    mv  a1,s9
    mv  a0,s10
    call    generate_twiddle_factors_vec
    rdcycle s11
    sub a5,s11,s1
    sd  a5,0(sp)
    fcvt.s.w    fs2,s0
    mv  s11,s10
    mv  s1,s9
    li  s0,0
    li  s7,1
    addi    s6,sp,12
    addi    s5,sp,8
    flw fs1,.LC6,a5
    flw fs0,.LC7,a5
    la  s8,.LC2
    la  s4,.LC1
    la  s3,.LC8
    j   .Lt1L5
.Lt1L18:
    fsub.s  fa3,fa3,fa1
    fabs.s  fa3,fa3
    flt.s   a4,fa3,fs0
    bne a4,zero,.Lt1L2
    mv  a7,s8
    li  s7,0
.Lt1L2:
    fmv.x.d a4,fa4
    fmv.x.d a3,fa5
    mv  a2,s0
    mv  a1,s3
    li  a0,1
    addiw   s0,s0,1
    call    __printf_chk
    addi    s11,s11,4
    addi    s1,s1,4
    beq s2,s0,.Lt1L17
.Lt1L5:
    fcvt.s.w    fa0,s0
    mv  a1,s5
    mv  a0,s6
    fmul.s  fa0,fa0,fs1
    fdiv.s  fa0,fa0,fs2
    call    sincosf
    flw fa5,0(s11)
    flw fa4,8(sp)
    flw fa3,0(s1)
    flw fa1,12(sp)
    fsub.s  fa2,fa5,fa4
    fcvt.d.s    fa0,fa3
    fcvt.d.s    fa5,fa5
    fcvt.d.s    fa4,fa4
    fmv.x.d a5,fa0
    fabs.s  fa2,fa2
    fcvt.d.s    fa0,fa1
    mv  a7,s4
    flt.s   a4,fa2,fs0
    fmv.x.d a6,fa0
    bne a4,zero,.Lt1L18
    li  s7,0
    mv  a7,s8
    j   .Lt1L2
.Lt1L17:
    la  a2,.LC3
    bne s7,zero,.Lt1L6
    la  a2,.LC2
.Lt1L6:
    ld  a3,0(sp)
    la  a1,.LC9
    li  a0,1
    call    __printf_chk
    mv  a0,s10
    call    free
    ld  s0,144(sp)
    ld  ra,152(sp)
    ld  s1,136(sp)
    ld  s2,128(sp)
    ld  s3,120(sp)
    ld  s4,112(sp)
    ld  s5,104(sp)
    ld  s6,96(sp)
    ld  s7,88(sp)
    ld  s8,80(sp)
    ld  s10,64(sp)
    ld  s11,56(sp)
    fld fs0,40(sp)
    fld fs1,32(sp)
    fld fs2,24(sp)
    mv  a0,s9
    ld  s9,72(sp)
    addi    sp,sp,160
    tail    free
    .size   test_twiddle, .-test_twiddle

# ---------------------------------------------------------------------------
# test_bit_reverse_array
# ---------------------------------------------------------------------------
    .section    .rodata
    .align  3
.LC10:
    .string "\n--- Array Reordering  N=%d ---\n"
    .align  3
.LC11:
    .string "  Input: xr=[0,1,...,%d]  Expected: xr[i]=bit_reverse(i)\n\n"
    .align  3
.LC13:
    .string "  xr[%2d] = %5.0f  (expected %d)  %s\n"
    .text
    .align  1
    .type   test_bit_reverse_array, @function
test_bit_reverse_array:
    addi    sp,sp,-128
    sd  s0,112(sp)
    slli    s0,a0,2
    sd  s4,80(sp)
    mv  s4,a0
    mv  a0,s0
    sd  ra,120(sp)
    sd  s1,104(sp)
    sd  s2,96(sp)
    sd  s3,88(sp)
    sd  s5,72(sp)
    sd  s6,64(sp)
    sd  s7,56(sp)
    sd  s8,48(sp)
    sd  s9,40(sp)
    sd  s10,32(sp)
    sd  s11,24(sp)
    fsd fs0,8(sp)
    call    malloc
    li  a1,4
    mv  s1,a0
    mv  a0,s4
    call    calloc
    mv  s3,a0
    mv  a0,s0
    call    malloc
    mv  s2,a0
    li  a5,0
    li  a3,1
.LbraL20:
    mv  a6,a5
    addiw   a5,a5,1
    sllw    a4,a3,a5
    blt a4,s4,.LbraL20
    mv  s6,s1
    mv  s5,s2
    mv  t1,s2
    mv  a7,s1
    li  s0,0
.LbraL22:
    fcvt.s.w    fa5,s0
    mv  a3,s0
    li  a4,0
    fsw fa5,0(a7)
    li  a5,0
.LbraL21:
    andi    a1,a3,1
    slliw   a5,a5,1
    mv  a2,a4
    or  a5,a5,a1
    sraiw   a3,a3,1
    addiw   a4,a4,1
    bne a6,a2,.LbraL21
    sw  a5,0(t1)
    addiw   a5,s0,1
    addi    a7,a7,4
    addi    t1,t1,4
    beq s4,a5,.LbraL33
    mv  s0,a5
    j   .LbraL22
.LbraL33:
    mv  a2,s4
    la  a1,.LC10
    li  a0,1
    call    __printf_chk
    mv  a2,s0
    la  a1,.LC11
    li  a0,1
    call    __printf_chk
    rdcycle s7
    mv  a2,s4
    mv  a1,s3
    mv  a0,s1
    call    bit_reverse_array_vec
    rdcycle s11
    li  s4,0
    sub s11,s11,s7
    li  s9,1
    flw fs0,.LC12,a5
    la  s8,.LC1
    la  s10,.LC2
    la  s7,.LC13
    j   .LbraL24
.LbraL28:
    mv  s4,a5
.LbraL24:
    lw  a4,0(s5)
    flw fa4,0(s6)
    mv  a2,s4
    fcvt.s.w    fa5,a4
    mv  a1,s7
    fsub.s  fa5,fa4,fa5
    fcvt.d.s    fa4,fa4
    mv  a5,s8
    addi    s6,s6,4
    fmv.x.d a3,fa4
    fabs.s  fa5,fa5
    addi    s5,s5,4
    flt.s   a6,fa5,fs0
    bne a6,zero,.LbraL23
    mv  a5,s10
    li  s9,0
.LbraL23:
    li  a0,1
    call    __printf_chk
    addiw   a5,s4,1
    bne s0,s4,.LbraL28
    la  a2,.LC3
    bne s9,zero,.LbraL25
    la  a2,.LC2
.LbraL25:
    mv  a3,s11
    la  a1,.LC9
    li  a0,1
    call    __printf_chk
    mv  a0,s1
    call    free
    mv  a0,s3
    call    free
    ld  s0,112(sp)
    ld  ra,120(sp)
    ld  s1,104(sp)
    ld  s3,88(sp)
    ld  s4,80(sp)
    ld  s5,72(sp)
    ld  s6,64(sp)
    ld  s7,56(sp)
    ld  s8,48(sp)
    ld  s9,40(sp)
    ld  s10,32(sp)
    ld  s11,24(sp)
    fld fs0,8(sp)
    mv  a0,s2
    ld  s2,96(sp)
    addi    sp,sp,128
    tail    free
    .size   test_bit_reverse_array, .-test_bit_reverse_array

# ---------------------------------------------------------------------------
# test_fft_iterative.isra.0
# Uses fft_vec 
# ---------------------------------------------------------------------------
    .section    .rodata
    .align  3
.LC14:
    .string ""
    .align  3
.LC15:
    .string "<-- UNEXPECTED"
    .align  3
.LC17:
    .string "\n--- Iterative FFT  N=%d  tone at bin k=%d ---\n"
    .align  3
.LC18:
    .string "  Input: xr[n] = cos(2*pi*%d*n/%d),  xi[n] = 0\n\n"
    .align  3
.LC19:
    .string "  Bin   Real        Imag        Magnitude"
    .align  3
.LC20:
    .string "  ----  ----------  ----------  ---------"
    .align  3
.LC21:
    .string "  [%2d]  %10.4f  %10.4f  %9.4f  %s\n"
    .text
    .align  1
    .type   test_fft_iterative.isra.0, @function
test_fft_iterative.isra.0:
    addi    sp,sp,-176
    sd  s0,160(sp)
    mv  s0,a0
    slli    a0,a0,2
    sd  ra,168(sp)
    sd  s1,152(sp)
    sd  s3,136(sp)
    sd  s4,128(sp)
    mv  s3,a1
    sd  s5,120(sp)
    sd  s6,112(sp)
    sd  s9,88(sp)
    sd  s10,80(sp)
    sd  s11,72(sp)
    fsd fs0,56(sp)
    fsd fs1,48(sp)
    sd  s2,144(sp)
    sd  s7,104(sp)
    sd  s8,96(sp)
    fsd fs2,40(sp)
    fsd fs3,32(sp)
    call    malloc
    li  a1,4
    mv  s6,a0
    srai    s11,s0,1
    mv  a0,s0
    call    calloc
    mv  s10,a0
    sd  s10,8(sp)
    # Fill xr[n] = cos(2*pi*k_tone*n/N)
    fcvt.s.w    fs0,s3
    flw fa5,.LC16,a5
    fcvt.s.w    fs1,s0
    fmul.s  fs0,fs0,fa5
    mv  s1,s6
    mv  s5,s6
    li  s4,0
.LfftL35:
    fcvt.s.w    fa0,s4
    addi    s5,s5,4
    mv  s2,s4
    fmul.s  fa0,fa0,fs0
    addiw   s4,s4,1
    fdiv.s  fa0,fa0,fs1
    call    cosf
    fsw fa0,-4(s5)
    bne s0,s4,.LfftL35
    mv  a3,s3
    mv  a2,s0
    la  a1,.LC17
    li  a0,1
    call    __printf_chk
    mv  a3,s0
    mv  a2,s3
    la  a1,.LC18
    li  a0,1
    call    __printf_chk
    # Run FFT via wrapper -- no manual twiddle allocation needed
    rdcycle s4
    ld  s8,8(sp)
    mv  a0,s6
    mv  a1,s8
    mv  a2,s0
    call    fft_vec
    rdcycle a5
    la  a0,.LC19
    sub a5,a5,s4
    sd  a5,24(sp)
    call    puts
    la  a0,.LC20
    call    puts
    fmv.w.x fs3,zero
    li  s7,1
    li  s10,0
    flw fs2,.LC12,a5
    subw    s0,s0,s3
    la  s5,.LC14
    la  s4,.LC21
    j   .LfftL42
.LfftL40:
    fabs.s  fa5,fa5
    fcvt.d.s    fs0,fs0
    fcvt.d.s    fa0,fa0
    fcvt.d.s    fs1,fs1
    flt.s   t3,fa5,fs2
    fmv.x.d a5,fa0
    fmv.x.d a4,fs1
    fmv.x.d a3,fs0
    mv  a6,s5
    addi    s1,s1,4
    bne t3,zero,.LfftL41
    la  a6,.LC15
    li  s7,0
.LfftL41:
    mv  a2,s10
    mv  a1,s4
    li  a0,1
    call    __printf_chk
    addi    s8,s8,4
    addiw   a5,s10,1
    beq s2,s10,.LfftL52
    mv  s10,a5
.LfftL42:
    flw fs1,0(s8)
    flw fs0,0(s1)
    fmul.s  fa0,fs1,fs1
    fmadd.s fa0,fs0,fs0,fa0
    frflags a4
    flt.s   a5,fa0,fs3
    fsflags a4
    bne a5,zero,.LfftL50
    fsqrt.s fa0,fa0
.LfftL38:
    mv  a2,s10
    mv  a1,s4
    beq s3,s10,.LfftL39
    fmv.s   fa5,fa0
    bne s0,s10,.LfftL40
.LfftL39:
    fcvt.s.w    fa5,s11
    fsub.s  fa5,fa0,fa5
    j   .LfftL40
.LfftL52:
    la  a2,.LC3
    bne s7,zero,.LfftL43
    la  a2,.LC2
.LfftL43:
    ld  a3,24(sp)
    la  a1,.LC9
    li  a0,1
    call    __printf_chk
    mv  a0,s6
    call    free
    ld  a0,8(sp)
    call    free
    ld  s0,160(sp)
    ld  ra,168(sp)
    ld  s1,152(sp)
    ld  s2,144(sp)
    ld  s3,136(sp)
    ld  s4,128(sp)
    ld  s5,120(sp)
    ld  s6,112(sp)
    ld  s7,104(sp)
    ld  s8,96(sp)
    ld  s9,88(sp)
    ld  s10,80(sp)
    ld  s11,72(sp)
    fld fs0,56(sp)
    fld fs1,48(sp)
    fld fs2,40(sp)
    fld fs3,32(sp)
    addi    sp,sp,176
    ret
.LfftL50:
    call    sqrtf
    j   .LfftL38
    .size   test_fft_iterative.isra.0, .-test_fft_iterative.isra.0

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
    .section    .rodata
    .align  3
.LC22:
    .string "============================================================"
    .align  3
.LC23:
    .string "  FFT Milestone 3 -- RISC-V Vector (RVV) Implementation"
    .align  3
.LC24:
    .string "  SECTION 1: TWIDDLE FACTOR GENERATION"
    .align  3
.LC25:
    .string "  SECTION 2: BIT REVERSAL"
    .align  3
.LC26:
    .string "\n--- Bit Reversal  N=%d  log_n=%d ---\n"
    .align  3
.LC27:
    .string "  bit_reverse(%d) = %u  (expected %u)  %s\n"
    .align  3
.LC28:
    .string "  SECTION 3: ARRAY REORDERING"
    .align  3
.LC29:
    .string "  SECTION 4 + 5: ITERATIVE FFT + WRAPPER"
    .align  3
.LC30:
    .string "Small (N=8)"
    .align  3
.LC31:
    .string "Medium (N=16)"
    .align  3
.LC32:
    .string "Large (N=32)"
    .align  3
.LC33:
    .string "  PERFORMANCE COMPARISON TABLE"
    .align  3
.LC34:
    .string "Data (bytes)"
    .align  3
.LC35:
    .string "Stack (bytes)"
    .align  3
.LC36:
    .string "Cycles"
    .align  3
.LC37:
    .string "Size"
    .align  3
.LC38:
    .string "  %-15s  %12s  %15s  %12s\n"
    .align  3
.LC39:
    .string "------------"
    .align  3
.LC40:
    .string "---------------"
    .align  3
.LC41:
    .string "  %-15s  %12lu  %15d  %12d\n"
    .align  3
.LC42:
    .string "\n  Notes:"
    .align  3
.LC43:
    .string "  - Cycles via RISC-V rdcycle CSR"
    .align  3
.LC44:
    .string "  - Stack includes VLA temp buffers in bit_reverse_array_vec"
    .align  3
.LC45:
    .string "  - Data = heap: xr + xi + twr + twi arrays"
    .align  3
.LC46:
    .string "  - For N=1024: stack ~ %d bytes, data ~ %d bytes\n"
    .align  3
.LC47:
    .string "  ALL SECTIONS COMPLETE"

    .section    .text.startup,"ax",@progbits
    .align  1
    .globl  main
    .type   main, @function
main:
    addi    sp,sp,-208
    la  a0,.LC22
    sd  ra,200(sp)
    sd  s0,192(sp)
    sd  s1,184(sp)
    sd  s2,176(sp)
    sd  s3,168(sp)
    sd  s4,160(sp)
    sd  s5,152(sp)
    sd  s6,144(sp)
    sd  s7,136(sp)
    sd  s8,128(sp)
    sd  s9,120(sp)
    sd  s10,112(sp)
    sd  s11,104(sp)
    fsd fs0,88(sp)
    fsd fs1,80(sp)
    call    puts
    la  a0,.LC23
    call    puts
    la  a0,.LC22
    call    puts
    la  a0,.LC22
    call    puts
    la  a0,.LC24
    call    puts
    la  a0,.LC22
    call    puts
    li  a0,8
    call    test_twiddle
    li  a0,16
    call    test_twiddle
    la  a0,.LC22
    call    puts
    la  a0,.LC25
    call    puts
    la  a0,.LC22
    call    puts
    li  a6,3
    li  a4,5
    li  a5,7
    slli    a6,a6,33
    slli    a4,a4,32
    slli    a5,a5,32
    li  a7,4
    addi    a6,a6,2
    addi    a4,a4,1
    addi    a5,a5,3
    li  a3,3
    li  a2,8
    la  a1,.LC26
    li  a0,1
    sw  a7,44(sp)
    sd  a6,48(sp)
    sd  a4,56(sp)
    sd  a5,64(sp)
    call    __printf_chk
    rdcycle s0
    addi    s8,sp,8
    li  a2,8
    li  a1,3
    mv  a0,s8
    call    bit_reverse_vec
    rdcycle s5
    addi    s6,sp,40
    sub s5,s5,s0
    mv  s10,s6
    mv  s0,s8
    li  a4,0
    li  s3,1
    li  s1,0
    la  s4,.LC2
    la  s7,.LC1
    la  s9,.LC27
    li  s2,8
    j   .LmL56
.LmL70:
    lw  a4,0(s10)
.LmL56:
    lw  a3,0(s0)
    mv  a5,s7
    beq a3,a4,.LmL54
    li  s3,0
    mv  a5,s4
.LmL54:
    mv  a2,s1
    mv  a1,s9
    li  a0,1
    addiw   s1,s1,1
    call    __printf_chk
    addi    s0,s0,4
    addi    s10,s10,4
    bne s1,s2,.LmL70
    la  a2,.LC3
    bne s3,zero,.LmL57
    la  a2,.LC2
.LmL57:
    mv  a3,s5
    la  a1,.LC9
    li  a0,1
    call    __printf_chk
    la  a0,.LC22
    call    puts
    la  a0,.LC28
    call    puts
    la  a0,.LC22
    call    puts
    li  a0,8
    call    test_bit_reverse_array
    li  a0,16
    call    test_bit_reverse_array
    la  a0,.LC22
    call    puts
    la  a0,.LC29
    call    puts
    la  a0,.LC22
    call    puts
    li  a1,1
    li  a0,8
    call    test_fft_iterative.isra.0
    li  a1,3
    li  a0,16
    call    test_fft_iterative.isra.0
    li  a1,5
    li  a0,32
    call    test_fft_iterative.isra.0

    # Performance table: store N values and label pointers
    li  a5,8
    sw  a5,8(sp)
    li  a5,16
    sw  a5,12(sp)
    li  a5,32
    sw  a5,16(sp)

    la  a5,.LC30
    sd  a5,40(sp)
    la  a5,.LC31
    sd  a5,48(sp)
    la  a5,.LC32
    sd  a5,56(sp)

    li  a0,10
    call    putchar

    la  a0,.LC22
    call    puts
    la  a0,.LC33
    call    puts
    la  a0,.LC22
    call    puts

    la  a5,.LC34
    la  a4,.LC35
    la  a3,.LC36
    la  a2,.LC37
    la  a1,.LC38
    li  a0,1
    call    __printf_chk

    la  a5,.LC39
    la  a4,.LC40
    mv  a3,a5
    mv  a2,a4
    la  a1,.LC38
    li  a0,1
    call    __printf_chk

    addi    s8,sp,8
    addi    s6,sp,40
    addi    s10,sp,64
    lw      s1,0(s8)
    flw     fs1,.LC16,a5
    la      s9,.LC41

.LmL63:
    slli    a0,s1,2
    call    malloc
    mv  s5,a0

    srliw   s2,s1,31
    addw    s2,s2,s1
    sraiw   s0,s2,1
    li  a1,4
    mv  a0,s1
    call    calloc
    mv  s7,a0

 
    slli    s2,s0,2
    mv  a0,s2
    call    malloc
    mv  s3,a0

    mv  a0,s2
    call    malloc
    mv  s4,a0

    mv  a0,s3
    mv  a1,s4
    mv  a2,s1
    call    generate_twiddle_factors_vec

    ble s1,zero,.LmL62
    fcvt.s.w    fs0,s1
    mv  s11,s5
    li  s0,0
.LmL61:
    fcvt.s.w    fa0,s0
    addi    s11,s11,4
    addiw   s0,s0,1
    fmul.s  fa0,fa0,fs1
    fdiv.s  fa0,fa0,fs0
    call    cosf
    fsw fa0,-4(s11)
    bne s0,s1,.LmL61

.LmL62:
    rdcycle s0
    mv  a0,s5
    mv  a1,s7
    mv  a2,s3
    mv  a3,s4
    mv  a4,s1
    call    fft_1d_iterative_vec
    rdcycle a2
    sub a2,a2,s0

    srliw   t0,s1,1
    slli    a4,s1,1
    addw    a4,a4,t0
    addw    a4,a4,t0
    slli    a4,a4,2
    addi    a4,a4,96

    slli    a3,s1,3
    addi    a3,a3,15
    andi    a3,a3,-16
    addi    a3,a3,96

    ld  a1,0(s6)
    mv  a5,a4
    mv  a4,a3
    mv  a3,a2
    mv  a2,a1
    la  a1,(.LC41)
    li  a0,1
    call    __printf_chk

    mv  a0,s5; call free
    mv  a0,s7; call free
    mv  a0,s3; call free
    mv  a0,s4; call free

    addi    s6,s6,8
    addi    s8,s8,4
    beq s10,s6,.LmL71

    lw  s1,0(s8)
    j   .LmL63

.LmL71:
    la  a0,.LC42
    call    puts
    la  a0,.LC43
    call    puts
    la  a0,.LC44
    call    puts
    la  a0,.LC45
    call    puts
    li  a2,8192
    li  a3,12288
    addi    a2,a2,96
    la  a1,.LC46
    li  a0,1
    call    __printf_chk
    li  a0,10
    call    putchar
    la  a0,.LC22
    call    puts
    la  a0,.LC47
    call    puts
    la  a0,.LC22
    call    puts

    ld  ra,200(sp)
    ld  s0,192(sp)
    ld  s1,184(sp)
    ld  s2,176(sp)
    ld  s3,168(sp)
    ld  s4,160(sp)
    ld  s5,152(sp)
    ld  s6,144(sp)
    ld  s7,136(sp)
    ld  s8,128(sp)
    ld  s9,120(sp)
    ld  s10,112(sp)
    ld  s11,104(sp)
    fld fs0,88(sp)
    fld fs1,80(sp)
    li  a0,0
    addi    sp,sp,208
    jr  ra
    .size   main, .-main

    .section    .rodata.cst4,"aM",@progbits,4
    .align  2
.LC6:
    .word   -1060565029
    .align  2
.LC7:
    .word   953267991
    .align  2
.LC12:
    .word   1056964608
    .align  2
.LC16:
    .word   1086918619