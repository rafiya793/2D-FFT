# fft_2d.s  --  Milestone 4: 2D FFT Pipeline (RISC-V RVV) 
# Complete working implementation with M3 building blocks + M4 functions.
# Compile:  riscv64-linux-gnu-gcc     -march=rv64gcv -mabi=lp64d -static     -Wl,-Ttext=0x20000000     -o fft_service fft_service.s -lm
# Run:     qemu-riscv64 -cpu rv64,v=on ./fft_service < /dev/null
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
    .size __printf_chk, .-__printf_chk

    .globl log2_int
    .type  log2_int, @function
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
    .size log2_int, .-log2_int

    .section .rodata
    .align 3
.VEC_NEG_TWO_PI:    .float -6.2831853072
.VEC_HALF_PI:       .float  1.5707963268
.VEC_ONE:           .float  1.0
.VEC_ZERO:          .float  0.0
.COS_D1:  .float -0.4999999963
.COS_D2:  .float  0.0416666418
.COS_D3:  .float -0.0013888397
.COS_D4:  .float  0.0000247609
.SIN_C1:  .float -0.1666666664
.SIN_C2:  .float  0.0083333315
.SIN_C3:  .float -0.0001984090
.SIN_C4:  .float  0.0000027526
.LOG_ONE:  .float  1.0
.LStr_sep:      .string "============================================================"
.LStr_title:    .string "  FFT Milestone 4 -- 2D FFT Pipeline (RISC-V RVV)"
.LStr_sec1:     .string "  SECTION: 2D FFT + HIGH-PASS FILTER"
.LStr_running:  .string "  Running 2D FFT on %dx%d image...\n"
.LStr_done:     .string "  Done. Cycles: %lu\n"
.LStr_written:  .string "  File written successfully."
.LStr_err_open: .string "  ERROR: could not open fft_result.bin"
.LStr_perf_hdr: .string "  PERFORMANCE TABLE"
.LStr_perf_col: .string "  %-10s  %12s  %15s  %12s\n"
.LStr_perf_row: .string "  %-10s  %12lu  %15d  %12d\n"
.LStr_allsec:   .string "  ALL SECTIONS COMPLETE"
.LStr_size_8:   .string "8x8"
.LStr_size_16:  .string "16x16"
.LStr_size_32:  .string "32x32"
.LStr_col_size: .string "Size"
.LStr_col_cyc:  .string "Cycles"
.LStr_col_stk:  .string "Stack (bytes)"
.LStr_col_dat:  .string "Data (bytes)"
.LFname:        .string "fft_result.bin"
.LFname8:       .string "fft_result_8.bin"
.LFname16:      .string "fft_result_16.bin"
.LFname32:      .string "fft_result_32.bin"

    .section .data
    .align 2
.twiddle_index_table:
    .float 0.0,  1.0,  2.0,  3.0
    .float 4.0,  5.0,  6.0,  7.0
    .float 8.0,  9.0, 10.0, 11.0
    .float 12.0, 13.0, 14.0, 15.0

# 8x8 mixed test image
    .align 2
 .Limg8:
.float 0,0,0,0,0,0,0,0
.float 0,0,0,0,0,0,0,0
.float 0,0,1,1,1,1,0,0
.float 0,0,1,1,1,1,0,0
.float 0,0,1,1,1,1,0,0
.float 0,0,1,1,1,1,0,0
.float 0,0,0,0,0,0,0,0
.float 0,0,0,0,0,0,0,0

    .Limg16:
    .float 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .float 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .float 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
    .float 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .float 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .float 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .align 2

.Limg32:
        .float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,1.0000,1.0000,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,1.0000,1.0000,0.2980,0.2980,1.0000,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,1.0000,1.0000,0.2980,0.2980,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.6510,0.8235,0.6510,0.2980,0.4784,0.2980,0.2980,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.6510,0.2980,0.2980,0.6549,0.6549,0.2980,1.0000,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.6549,0.6549,0.6549,0.2980,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.6549,0.6549,0.6549,0.6549,0.6549,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.2980,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.2980,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.2980,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.6549,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.4784,0.6549,0.6549,0.6549,0.6549,0.6549,0.8275,0.8275,0.6549,0.6549,0.6549,0.6549,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.4784,0.6549,0.6549,0.6549,0.6549,0.8275,0.8275,0.8275,0.6549,0.6549,0.6549,0.6549,0.2980,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.4784,0.6549,0.6549,0.6549,0.6549,0.8275,0.8275,0.8275,0.6549,0.6549,0.6549,0.6549,0.2980,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.6510,0.2980,0.4784,0.6549,0.6549,0.6549,0.8275,0.8275,0.8275,0.8275,0.8275,0.6549,0.6549,0.6549,0.2980,0.2980,0.6510,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.4784,0.6549,0.6549,0.7412,0.8275,0.8275,0.8275,0.8275,0.8275,0.6549,0.6549,0.6549,0.2980,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.6549,0.6549,0.7412,0.8275,0.8275,0.8275,0.8275,0.8275,0.6549,0.6549,0.6549,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,0.2980,0.2980,0.6549,0.7412,0.8275,0.8275,0.8275,0.8275,0.8275,0.6549,0.6549,0.2980,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
.float 1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000,1.0000
    .align 2

    .text
    .align 1
    .globl generate_twiddle_factors_vec
    .type  generate_twiddle_factors_vec, @function
generate_twiddle_factors_vec:
    addi    sp, sp, -48
    sd      ra,  40(sp)
    sd      s0,  32(sp)
    sd      s1,  24(sp)
    sd      s2,  16(sp)
    sd      s3,   8(sp)
    fsd     fs0,  0(sp)
    mv      s0, a0
    mv      s1, a1
    srli    s2, a2, 1
    mv      s3, zero
    la      t0, .VEC_NEG_TWO_PI
    flw     ft0, 0(t0)
    fcvt.s.w ft1, a2
    fdiv.s  fs0, ft0, ft1
    la      t6, .twiddle_index_table
.Ltwig_chunk_loop:
    beq     s3, s2, .Ltwig_done
    sub     t0, s2, s3
    vsetvli t1, t0, e32, m1, ta, ma
    li      t2, 16
    bge     s3, t2, .Ltwig_use_vid
    slli    t3, s3, 2
    add     t3, t6, t3
    vle32.v v0, (t3)
    j       .Ltwig_got_index
.Ltwig_use_vid:
    vid.v   v0
    vfcvt.f.xu.v v0, v0
    fcvt.s.w ft2, s3
    vfadd.vf v0, v0, ft2
.Ltwig_got_index:
    vfmul.vf v1, v0, fs0
    la      t2, .VEC_HALF_PI
    flw     ft2, 0(t2)
    vfneg.v  v5, v1
    vmfgt.vf v0, v5, ft2
    vmv.v.v  v6, v5
    vfsub.vf v6, v6, ft2, v0.t
    vfmul.vv v2, v6, v6
    la      t4, .COS_D4;   flw ft4, 0(t4);   vfmv.v.f v3, ft4
    la      t4, .COS_D3;   flw ft4, 0(t4);   vfmul.vv v3, v2, v3;   vfadd.vf v3, v3, ft4
    la      t4, .COS_D2;   flw ft4, 0(t4);   vfmul.vv v3, v2, v3;   vfadd.vf v3, v3, ft4
    la      t4, .COS_D1;   flw ft4, 0(t4);   vfmul.vv v3, v2, v3;   vfadd.vf v3, v3, ft4
    vfmul.vv v3, v2, v3
    la      t4, .VEC_ONE;  flw ft4, 0(t4);   vfadd.vf v3, v3, ft4
    la      t4, .SIN_C4;   flw ft4, 0(t4);   vfmv.v.f v4, ft4
    la      t4, .SIN_C3;   flw ft4, 0(t4);   vfmul.vv v4, v2, v4;   vfadd.vf v4, v4, ft4
    la      t4, .SIN_C2;   flw ft4, 0(t4);   vfmul.vv v4, v2, v4;   vfadd.vf v4, v4, ft4
    la      t4, .SIN_C1;   flw ft4, 0(t4);   vfmul.vv v4, v2, v4;   vfadd.vf v4, v4, ft4
    vfmul.vv v4, v2, v4
    la      t4, .VEC_ONE;  flw ft4, 0(t4);   vfadd.vf v4, v4, ft4
    vfmul.vv v4, v6, v4
    vfneg.v  v7, v4
    vmerge.vvm v9,  v3, v7, v0
    vmerge.vvm v10, v4, v3, v0
    vfneg.v v10, v10
    slli    t3, s3, 2
    add     t3, s0, t3
    vse32.v v9, (t3)
    slli    t3, s3, 2
    add     t3, s1, t3
    vse32.v v10, (t3)
    add     s3, s3, t1
    j       .Ltwig_chunk_loop
.Ltwig_done:
    fld     fs0,  0(sp)
    ld      s3,   8(sp)
    ld      s2,  16(sp)
    ld      s1,  24(sp)
    ld      s0,  32(sp)
    ld      ra,  40(sp)
    addi    sp, sp, 48
    ret
    .size generate_twiddle_factors_vec, .-generate_twiddle_factors_vec

    .globl bit_reverse_vec
    .type  bit_reverse_vec, @function
bit_reverse_vec:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)
    sd      s2, 16(sp)
    sd      s3,  8(sp)
    mv      s0, a0
    mv      s1, a1
    mv      s2, a2
    li      s3, 0
.Lbr_vec_chunk:
    beqz    s2, .Lbr_vec_done
    vsetvli t0, s2, e32, m1, ta, ma
    vid.v   v0
    vmv.v.x v2, s3
    vadd.vv v0, v0, v2
    vmv.v.i v1, 0
    mv      t1, s1
.Lbr_bit_loop:
    beqz    t1, .Lbr_bit_done
    vsll.vi v1, v1, 1
    vand.vi v3, v0, 1
    vor.vv  v1, v1, v3
    vsrl.vi v0, v0, 1
    addi    t1, t1, -1
    j       .Lbr_bit_loop
.Lbr_bit_done:
    slli    t1, s3, 2
    add     t1, s0, t1
    vse32.v v1, (t1)
    add     s3, s3, t0
    sub     s2, s2, t0
    j       .Lbr_vec_chunk
.Lbr_vec_done:
    ld      s3,  8(sp)
    ld      s2, 16(sp)
    ld      s1, 24(sp)
    ld      s0, 32(sp)
    ld      ra, 40(sp)
    addi    sp, sp, 48
    ret
    .size bit_reverse_vec, .-bit_reverse_vec

    .globl bit_reverse_array_vec
    .type  bit_reverse_array_vec, @function
bit_reverse_array_vec:
    addi    sp, sp, -96
    sd      ra, 88(sp)
    sd      s0, 80(sp)
    sd      s1, 72(sp)
    sd      s2, 64(sp)
    sd      s3, 56(sp)
    sd      s4, 48(sp)
    sd      s5, 40(sp)
    mv      s0, a0
    mv      s1, a1
    mv      s2, a2
    slli    a0, s2, 2
    call    malloc
    mv      s3, a0
    slli    a0, s2, 2
    call    malloc
    mv      s4, a0
    slli    a0, s2, 2
    call    malloc
    mv      s5, a0
    mv      a0, s2
    call    log2_int
    mv      a1, a0
    mv      a0, s3
    mv      a2, s2
    call    bit_reverse_vec
    li      t4, 0
    mv      t5, s2
.Lreorder_scale:
    beqz    t5, .Lreorder_gather
    vsetvli t0, t5, e32, m1, ta, ma
    slli    t1, t4, 2
    add     t2, s3, t1
    vle32.v v0, (t2)
    vsll.vi v0, v0, 2
    vse32.v v0, (t2)
    add     t4, t4, t0
    sub     t5, t5, t0
    j       .Lreorder_scale
.Lreorder_gather:
    li      t4, 0
    mv      t5, s2
.Lgather_loop:
    beqz    t5, .Lreorder_gather_done
    vsetvli t0, t5, e32, m1, ta, ma
    slli    t1, t4, 2
    add     t2, s3, t1
    vle32.v v2, (t2)
    vluxei32.v v3, (s0), v2
    add     t2, s4, t1
    vse32.v v3, (t2)
    vluxei32.v v4, (s1), v2
    add     t2, s5, t1
    vse32.v v4, (t2)
    add     t4, t4, t0
    sub     t5, t5, t0
    j       .Lgather_loop
.Lreorder_gather_done:
    li      t4, 0
    mv      t5, s2
.Lreorder_copy:
    beqz    t5, .Lreorder_copy_done
    vsetvli t0, t5, e32, m1, ta, ma
    slli    t1, t4, 2
    add     t2, s4, t1;  vle32.v v0, (t2)
    add     t2, s0, t1;  vse32.v v0, (t2)
    add     t2, s5, t1;  vle32.v v0, (t2)
    add     t2, s1, t1;  vse32.v v0, (t2)
    add     t4, t4, t0
    sub     t5, t5, t0
    j       .Lreorder_copy
.Lreorder_copy_done:
    mv      a0, s3;  call free
    mv      a0, s4;  call free
    mv      a0, s5;  call free
    ld      s5, 40(sp)
    ld      s4, 48(sp)
    ld      s3, 56(sp)
    ld      s2, 64(sp)
    ld      s1, 72(sp)
    ld      s0, 80(sp)
    ld      ra, 88(sp)
    addi    sp, sp, 96
    ret
    .size bit_reverse_array_vec, .-bit_reverse_array_vec

    .globl fft_1d_iterative_vec
    .type  fft_1d_iterative_vec, @function
fft_1d_iterative_vec:
    addi    sp, sp, -112
    sd      ra, 104(sp)
    sd      s0,  96(sp)
    sd      s1,  88(sp)
    sd      s2,  80(sp)
    sd      s3,  72(sp)
    sd      s4,  64(sp)
    sd      s5,  56(sp)
    sd      s6,  48(sp)
    sd      s7,  40(sp)
    sd      s8,  32(sp)
    sd      s9,  24(sp)
    mv      s0, a0
    mv      s1, a1
    mv      s2, a2
    mv      s3, a3
    mv      s4, a4
    mv      a0, s0
    mv      a1, s1
    mv      a2, s4
    call    bit_reverse_array_vec
    li      s5, 2
.Lvec_M_loop:
    bgt     s5, s4, .Lvec_fft_done
    srli    s6, s5, 1
    divu    s7, s4, s5
    slli    t6, s7, 2
    li      s8, 0
.Lvec_k_loop:
    bge     s8, s4, .Lvec_M_next
    li      s9, 0
.Lvec_j_chunk:
    bge     s9, s6, .Lvec_k_next
    sub     t0, s6, s9
    vsetvli t0, t0, e32, m1, ta, ma
    mul     t1, s9, s7
    slli    t1, t1, 2
    add     t1, s2, t1
    vlse32.v v0, (t1), t6
    mul     t1, s9, s7
    slli    t1, t1, 2
    add     t1, s3, t1
    vlse32.v v1, (t1), t6
    add     t2, s8, s6
    add     t2, t2, s9
    slli    t3, t2, 2
    add     t4, s0, t3;  vle32.v v2, (t4)
    add     t4, s1, t3;  vle32.v v3, (t4)
    vfmul.vv v4, v2, v0
    vfmul.vv v5, v3, v1
    vfsub.vv v6, v4, v5
    vfmul.vv v4, v3, v0
    vfmul.vv v5, v2, v1
    vfadd.vv v7, v4, v5
    add     t2, s8, s9
    slli    t3, t2, 2
    add     t4, s0, t3;  vle32.v v8, (t4)
    add     t4, s1, t3;  vle32.v v9, (t4)
    vfadd.vv v10, v8, v6
    vfadd.vv v11, v9, v7
    vfsub.vv v12, v8, v6
    vfsub.vv v13, v9, v7
    add     t2, s8, s9
    slli    t3, t2, 2
    add     t4, s0, t3;  vse32.v v10, (t4)
    add     t4, s1, t3;  vse32.v v11, (t4)
    add     t2, s8, s6
    add     t2, t2, s9
    slli    t3, t2, 2
    add     t4, s0, t3;  vse32.v v12, (t4)
    add     t4, s1, t3;  vse32.v v13, (t4)
    add     s9, s9, t0
    j       .Lvec_j_chunk
.Lvec_k_next:
    add     s8, s8, s5
    j       .Lvec_k_loop
.Lvec_M_next:
    slli    s5, s5, 1
    j       .Lvec_M_loop
.Lvec_fft_done:
    ld      s9,  24(sp)
    ld      s8,  32(sp)
    ld      s7,  40(sp)
    ld      s6,  48(sp)
    ld      s5,  56(sp)
    ld      s4,  64(sp)
    ld      s3,  72(sp)
    ld      s2,  80(sp)
    ld      s1,  88(sp)
    ld      s0,  96(sp)
    ld      ra, 104(sp)
    addi    sp, sp, 112
    ret
    .size fft_1d_iterative_vec, .-fft_1d_iterative_vec

        .globl ifft_1d_iterative_vec
    .type  ifft_1d_iterative_vec, @function
ifft_1d_iterative_vec:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)
    sd      s1, 8(sp)
    sd      s2, 0(sp)
    
    mv      s0, a0          # xr array
    mv      s1, a1          # xi array
    mv      s2, a4          # N
    
    # Step 1: Swap real and imaginary
    li      t0, 0
.Lswap_loop:
    bge     t0, s2, .Lswap_done
    slli    t1, t0, 2
    add     t2, s0, t1      # &xr[i]
    add     t3, s1, t1      # &xi[i]
    flw     ft0, 0(t2)      # temp = xr[i]
    flw     ft1, 0(t3)      # temp = xi[i]
    fsw     ft1, 0(t2)      # xr[i] = xi[i]
    fsw     ft0, 0(t3)      # xi[i] = xr[i]
    addi    t0, t0, 1
    j       .Lswap_loop
.Lswap_done:
    
    # Step 2: Forward FFT on swapped data
    mv      a0, s0
    mv      a1, s1
    # a2=twr, a3=twi already set by caller
    mv      a4, s2
    call    fft_1d_iterative_vec
    
    # Step 3: Swap back
    li      t0, 0
.Lswap_back_loop:
    bge     t0, s2, .Lswap_back_done
    slli    t1, t0, 2
    add     t2, s0, t1
    add     t3, s1, t1
    flw     ft0, 0(t2)
    flw     ft1, 0(t3)
    fsw     ft1, 0(t2)
    fsw     ft0, 0(t3)
    addi    t0, t0, 1
    j       .Lswap_back_loop
.Lswap_back_done:
    
    # Step 4: Divide by N
    fcvt.s.w ft2, s2
    li      t0, 0
.Ldiv_loop:
    bge     t0, s2, .Ldiv_done
    slli    t1, t0, 2
    add     t2, s0, t1
    add     t3, s1, t1
    flw     ft0, 0(t2)
    flw     ft1, 0(t3)
    fdiv.s  ft0, ft0, ft2
    fdiv.s  ft1, ft1, ft2
    fsw     ft0, 0(t2)
    fsw     ft1, 0(t3)
    addi    t0, t0, 1
    j       .Ldiv_loop
.Ldiv_done:
    
    ld      s2, 0(sp)
    ld      s1, 8(sp)
    ld      s0, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    ret
    .size ifft_1d_iterative_vec, .-ifft_1d_iterative_vec

    .globl fft_2d
    .type  fft_2d, @function
fft_2d:
    addi    sp, sp, -128
    sd      ra,  120(sp)
    sd      s0,  112(sp)
    sd      s1,  104(sp)
    sd      s2,   96(sp)
    sd      s3,   88(sp)
    sd      s4,   80(sp)
    sd      s5,   72(sp)
    sd      s6,   64(sp)
    sd      s7,   56(sp)
    sd      s8,   48(sp)
    sd      s9,   40(sp)
    sd      s10,  32(sp)
    sd      s11,  24(sp)
    mv      s0, a0
    mv      s1, a1
    mv      s2, a2
    mv      s3, a3
    mv      s4, a4
    mv      s5, a5
    li      s6, 0
    slli    s8, s5, 2
.Lrow_fft_loop:
    bge     s6, s4, .Lrow_fft_done
    mul     t0, s6, s5
    slli    t0, t0, 2
    add     a0, s0, t0
    add     a1, s1, t0
    mv      a2, s2
    mv      a3, s3
    mv      a4, s5
    call    fft_1d_iterative_vec
    addi    s6, s6, 1
    j       .Lrow_fft_loop
.Lrow_fft_done:
    slli    a0, s4, 2
    call    malloc
    mv      s9, a0
    slli    a0, s4, 2
    call    malloc
    mv      s10, a0
    li      s6, 0
.Lcol_fft_loop:
    bge     s6, s5, .Lcol_fft_done
    li      t4, 0
.Lgather_col:
    bge     t4, s4, .Lgather_col_done
    mul     t0, t4, s5
    add     t0, t0, s6
    slli    t0, t0, 2
    add     t1, s0, t0
    flw     ft0, 0(t1)
    slli    t2, t4, 2
    add     t2, s9, t2
    fsw     ft0, 0(t2)
    add     t1, s1, t0
    flw     ft0, 0(t1)
    slli    t2, t4, 2
    add     t2, s10, t2
    fsw     ft0, 0(t2)
    addi    t4, t4, 1
    j       .Lgather_col
.Lgather_col_done:
    mv      a0, s9
    mv      a1, s10
    mv      a2, s2
    mv      a3, s3
    mv      a4, s4
    call    fft_1d_iterative_vec
    li      t4, 0
.Lscatter_col:
    bge     t4, s4, .Lscatter_col_done
    mul     t0, t4, s5
    add     t0, t0, s6
    slli    t0, t0, 2
    slli    t2, t4, 2
    add     t2, s9, t2
    flw     ft0, 0(t2)
    add     t1, s0, t0
    fsw     ft0, 0(t1)
    slli    t2, t4, 2
    add     t2, s10, t2
    flw     ft0, 0(t2)
    add     t1, s1, t0
    fsw     ft0, 0(t1)
    addi    t4, t4, 1
    j       .Lscatter_col
.Lscatter_col_done:
    addi    s6, s6, 1
    j       .Lcol_fft_loop
.Lcol_fft_done:
    mv      a0, s9;  call free
    mv      a0, s10; call free
    ld      ra,  120(sp)
    ld      s0,  112(sp)
    ld      s1,  104(sp)
    ld      s2,   96(sp)
    ld      s3,   88(sp)
    ld      s4,   80(sp)
    ld      s5,   72(sp)
    ld      s6,   64(sp)
    ld      s7,   56(sp)
    ld      s8,   48(sp)
    ld      s9,   40(sp)
    ld      s10,  32(sp)
    ld      s11,  24(sp)
    addi    sp, sp, 128
    ret
    .size fft_2d, .-fft_2d

        .globl ifft_2d
    .type  ifft_2d, @function
ifft_2d:
    addi    sp, sp, -128
    sd      ra,  120(sp)
    sd      s0,  112(sp)
    sd      s1,  104(sp)
    sd      s2,   96(sp)
    sd      s3,   88(sp)
    sd      s4,   80(sp)
    sd      s5,   72(sp)
    sd      s6,   64(sp)
    sd      s7,   56(sp)
    sd      s8,   48(sp)
    sd      s9,   40(sp)
    sd      s10,  32(sp)
    sd      s11,  24(sp)
    mv      s0, a0          # xr
    mv      s1, a1          # xi
    mv      s2, a2          # twr
    mv      s3, a3          # twi
    mv      s4, a4          # rows
    mv      s5, a5          # cols
    
    # Row-wise inverse FFT
    li      s6, 0
.Lifft_row_loop:
    bge     s6, s4, .Lifft_row_done
    mul     t0, s6, s5
    slli    t0, t0, 2
    add     a0, s0, t0
    add     a1, s1, t0
    mv      a2, s2
    mv      a3, s3
    mv      a4, s5
    call    ifft_1d_iterative_vec
    addi    s6, s6, 1
    j       .Lifft_row_loop
.Lifft_row_done:
    
    # Column-wise 
    slli    a0, s4, 2
    call    malloc
    mv      s9, a0
    slli    a0, s4, 2
    call    malloc
    mv      s10, a0
    
    li      s6, 0
.Lifft_col_loop:
    bge     s6, s5, .Lifft_col_done
    li      t4, 0
.Lifft_gather_col:
    bge     t4, s4, .Lifft_gather_col_done
    mul     t0, t4, s5
    add     t0, t0, s6
    slli    t0, t0, 2
    add     t1, s0, t0
    flw     ft0, 0(t1)
    slli    t2, t4, 2
    add     t2, s9, t2
    fsw     ft0, 0(t2)
    add     t1, s1, t0
    flw     ft0, 0(t1)
    slli    t2, t4, 2
    add     t2, s10, t2
    fsw     ft0, 0(t2)
    addi    t4, t4, 1
    j       .Lifft_gather_col
.Lifft_gather_col_done:
    mv      a0, s9
    mv      a1, s10
    mv      a2, s2
    mv      a3, s3
    mv      a4, s4
    call    ifft_1d_iterative_vec
    li      t4, 0
.Lifft_scatter_col:
    bge     t4, s4, .Lifft_scatter_col_done
    mul     t0, t4, s5
    add     t0, t0, s6
    slli    t0, t0, 2
    slli    t2, t4, 2
    add     t2, s9, t2
    flw     ft0, 0(t2)
    add     t1, s0, t0
    fsw     ft0, 0(t1)
    slli    t2, t4, 2
    add     t2, s10, t2
    flw     ft0, 0(t2)
    add     t1, s1, t0
    fsw     ft0, 0(t1)
    addi    t4, t4, 1
    j       .Lifft_scatter_col
.Lifft_scatter_col_done:
    addi    s6, s6, 1
    j       .Lifft_col_loop
.Lifft_col_done:
    mv      a0, s9;  call free
    mv      a0, s10; call free
    ld      ra,  120(sp)
    ld      s0,  112(sp)
    ld      s1,  104(sp)
    ld      s2,   96(sp)
    ld      s3,   88(sp)
    ld      s4,   80(sp)
    ld      s5,   72(sp)
    ld      s6,   64(sp)
    ld      s7,   56(sp)
    ld      s8,   48(sp)
    ld      s9,   40(sp)
    ld      s10,  32(sp)
    ld      s11,  24(sp)
    addi    sp, sp, 128
    ret
    .size ifft_2d, .-ifft_2d

.globl compute_magnitude_log
    .type  compute_magnitude_log, @function
compute_magnitude_log:
    addi    sp, sp, -64
    sd      ra,  56(sp)
    sd      s0,  48(sp)
    sd      s1,  40(sp)
    sd      s2,  32(sp)
    sd      s3,  24(sp)
    sd      s4,  16(sp)
    mv      s0, a0
    mv      s1, a1
    mv      s2, a2
    mv      s3, a3
    li      s4, 0
.Lmag_loop:
    bge     s4, s3, .Lmag_done
    slli    t0, s4, 2
    add     t1, s0, t0
    flw     fa0, 0(t1)
    add     t1, s1, t0
    flw     fa1, 0(t1)
    
    fmul.s  ft0, fa0, fa0
    fmul.s  ft1, fa1, fa1
    fadd.s  fa0, ft0, ft1
    
    fsqrt.s fa0, fa0
    
    la      t1, .LOG_ONE
    flw     ft0, 0(t1)
    fadd.s  fa0, fa0, ft0
    call    logf
    
    slli    t0, s4, 2
    add     t1, s2, t0
    fsw     fa0, 0(t1)
    addi    s4, s4, 1
    j       .Lmag_loop
.Lmag_done:
    ld      s4,  16(sp)
    ld      s3,  24(sp)
    ld      s2,  32(sp)
    ld      s1,  40(sp)
    ld      s0,  48(sp)
    ld      ra,  56(sp)
    addi    sp, sp, 64
    ret
    .size compute_magnitude_log, .-compute_magnitude_log 

        .globl compute_magnitude_linear
    .type  compute_magnitude_linear, @function

compute_magnitude_linear:
        li      t0, 0           # t0 = loop index (i = 0)
.Lmag_lin_loop:
        bge     t0, a3, .Lmag_lin_done
        
        slli    t1, t0, 2       # t1 = i * 4 (byte offset)
        add     t2, a0, t1      # t2 = &xr[i]
        flw     ft0, 0(t2)      # ft0 = xr[i]
        
        add     t3, a1, t1      # t3 = &xi[i]
        flw     ft1, 0(t3)      # ft1 = xi[i]
        
        # Real^2 + Imag^2
        fmul.s  ft2, ft0, ft0   # ft2 = xr[i]^2
        fmul.s  ft3, ft1, ft1   # ft3 = xi[i]^2
        fadd.s  ft4, ft2, ft3   # ft4 = xr[i]^2 + xi[i]^2
        
        fsqrt.s ft5, ft4        # ft5 = sqrt(xr[i]^2 + xi[i]^2)
        
        add     t4, a2, t1      # t4 = &out[i]
        fsw     ft5, 0(t4)      # Store raw magnitude
        
        addi    t0, t0, 1       # i++
        j       .Lmag_lin_loop
.Lmag_lin_done:
        ret
        .size compute_magnitude_linear, .-compute_magnitude_linear

# my_exp  --  Exponential via Taylor Series 
    .globl my_exp
    .type  my_exp, @function
my_exp:
    fmv.w.x fa1, zero
    feq.s   a1, fa0, fa1
    beqz    a1, exp_check_neg
    la      a0, .VEC_ONE
    flw     fa0, 0(a0)               # e^0 = 1.0
    ret

exp_check_neg:
    li      a2, 0
    flt.s   a1, fa0, fa1
    beqz    a1, exp_loop_init
    li      a2, 1
    fneg.s  fa0, fa0                 # work with |x|

exp_loop_init:
    la      a0, .VEC_ONE
    flw     fa1, 0(a0)               # res = 1.0
    flw     fa2, 0(a0)               # term = 1.0
    li      a3, 1

exp_loop:
    fcvt.s.w fa3, a3
    fdiv.s  fa3, fa0, fa3
    fmul.s  fa2, fa2, fa3
    fadd.s  fa1, fa1, fa2
    addi    a3, a3, 1
    li      a0, 13                   # 12-term series limit
    blt     a3, a0, exp_loop
    
    beqz    a2, exp_done
    la      a0, .VEC_ONE
    flw     fa0, 0(a0)
    fdiv.s  fa0, fa0, fa1            # 1 / e^|x|
    ret

exp_done:
    fmv.s   fa0, fa1
    ret
    .size my_exp, .-my_exp

.globl highpass_filter
    .type  highpass_filter, @function
highpass_filter:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    fsd     fs0, 16(sp)
    fsd     fs1,  8(sp)
    
    mv      s0, a0          # s0 = xr pointer
    mv      s1, a1          # s1 = xi pointer
    mv      s2, a2          # s2 = DIM (N)
    
    # Calculate 2 * sigma^2
    fcvt.s.w fs0, s2        # fs0 = (float)N
    li      t0, 5
    fcvt.s.w ft0, t0        # ft0 = 5.0
    fdiv.s  fs0, fs0, ft0   # fs0 = sigma = N / 5.0
    fmul.s  fs0, fs0, fs0   # fs0 = sigma^2
    li      t0, 2
    fcvt.s.w ft0, t0        # ft0 = 2.0
    fmul.s  fs0, fs0, ft0   # fs0 = 2 * sigma^2
    
    # Load 1.0f constant
    la      t0, .VEC_ONE
    flw     fs1, 0(t0)      # fs1 = 1.0f

    li      t0, 0           # t0 = row (u)
.Lhp_row_loop:
    bge     t0, s2, .Lhp_done
    li      t1, 0           # t1 = col (v)
.Lhp_col_loop:
    bge     t1, s2, .Lhp_col_done
    
    # du = min(u, N - u)
    mv      t2, t0
    sub     t3, s2, t0
    bge     t2, t3, .Luse_t3_u
    j       .Lgot_du
.Luse_t3_u:
    mv      t2, t3
.Lgot_du:                   # t2 = du

    # dv = min(v, N - v)
    mv      t3, t1
    sub     t4, s2, t1
    bge     t3, t4, .Luse_t4_v
    j       .Lgot_dv
.Luse_t4_v:
    mv      t3, t4
.Lgot_dv:                   # t3 = dv
    
    # D^2 = du^2 + dv^2
    mul     t2, t2, t2      # t2 = du^2
    mul     t3, t3, t3      # t3 = dv^2
    add     t2, t2, t3      # t2 = D^2
    
    # Convert D^2 to float
    fcvt.s.w fa0, t2        # fa0 = (float)D^2
    
    # Compute exponent: -D^2 / (2 * sigma^2)
    fneg.s  fa0, fa0        # fa0 = -D^2
    fdiv.s  fa0, fa0, fs0   # fa0 = -D^2 / (2 * sigma^2)
    
    # Save caller-saved loop registers t0 and t1 before function call
    addi    sp, sp, -16
    sd      t0, 8(sp)
    sd      t1, 0(sp)
    
    # Jumps to your custom exponential function 
    call    my_exp          # fa0 = my_exp(-D^2 / (2 * sigma^2))
    
    # Restore loop registers t0 and t1
    ld      t0, 8(sp)
    ld      t1, 0(sp)
    addi    sp, sp, 16
    
    # weight = 1.0f - my_exp(...)
    fsub.s  fa0, fs1, fa0   # fa0 = 1.0f - fa0
    
    # Apply weight: xr[u][v] *= weight, xi[u][v] *= weight
    mul     t2, t0, s2
    add     t2, t2, t1
    slli    t2, t2, 2
    
    add     t3, s0, t2
    flw     ft2, 0(t3)
    fmul.s  ft2, ft2, fa0   # xr * weight
    fsw     ft2, 0(t3)
    
    add     t3, s1, t2
    flw     ft2, 0(t3)
    fmul.s  ft2, ft2, fa0   # xi * weight
    fsw     ft2, 0(t3)
    
    addi    t1, t1, 1
    j       .Lhp_col_loop
.Lhp_col_done:
    addi    t0, t0, 1
    j       .Lhp_row_loop
.Lhp_done:
    fld     fs1,  8(sp)
    fld     fs0, 16(sp)
    ld      s2, 32(sp)
    ld      s1, 40(sp)
    ld      s0, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret
    .size highpass_filter, .-highpass_filter

    .type run_fft2d_test, @function
run_fft2d_test:
    addi    sp, sp, -192
    sd      ra,  184(sp)
    sd      s0,  176(sp)
    sd      s1,  168(sp)
    sd      s2,  160(sp)
    sd      s3,  152(sp)
    sd      s4,  144(sp)
    sd      s5,  136(sp)
    sd      s6,  128(sp)
    sd      s7,  120(sp)
    sd      s8,  112(sp)
    sd      s9,  104(sp)
    sd      s10,  96(sp)
    sd      s11,  88(sp)
    mv      s0, a0
    mv      s1, a1
    sd      a2, 80(sp)  
    mv      s2, a2
    sd      a3, 8(sp)       # save filename pointer on stack at sp+8
    mv      a3, s0
    mv      a2, s0
    la      a1, .LStr_running
    li      a0, 1
    call    __printf_chk
    mul     s3, s0, s0
    slli    a0, s3, 2
    call    malloc
    mv      s4, a0
    slli    a0, s3, 2
    call    malloc
    mv      s5, a0
    fcvt.s.w ft10, zero
    li      t4, 0
.Lzero_xi:
    bge     t4, s3, .Lzero_xi_done
    slli    t0, t4, 2
    add     t1, s5, t0
    fsw     ft10, 0(t1)
    addi    t4, t4, 1
    j       .Lzero_xi
.Lzero_xi_done:
    li      t4, 0
.Lcopy_img:
    bge     t4, s3, .Lcopy_img_done
    slli    t0, t4, 2
    add     t1, s1, t0
    flw     ft0, 0(t1)
    add     t1, s4, t0
    fsw     ft0, 0(t1)
    addi    t4, t4, 1
    j       .Lcopy_img
.Lcopy_img_done:
    srli    t0, s0, 1
    slli    a0, t0, 2
    call    malloc
    mv      s6, a0
    srli    t0, s0, 1
    slli    a0, t0, 2
    call    malloc
    mv      s7, a0
    mv      a0, s6
    mv      a1, s7
    mv      a2, s0
    call    generate_twiddle_factors_vec
    slli    a0, s3, 2
    call    malloc
    mv      s8, a0
    slli    a0, s3, 2
    call    malloc
    mv      s9, a0
    rdcycle t4
    sd      t4, 0(sp)
    mv      a0, s4
    mv      a1, s5
    mv      a2, s6
    mv      a3, s7
    mv      a4, s0
    mv      a5, s0
    call    fft_2d
    rdcycle t5
    ld      t4, 0(sp)
    sub     t5, t5, t4
    sd      t5, 0(sp)
    mv      a0, s4
    mv      a1, s5
    mv      a2, s8
    mv      a3, s3
    call    compute_magnitude_log
    slli    a0, s3, 2
    call    malloc
    mv      s10, a0
    slli    a0, s3, 2
    call    malloc
    mv      s11, a0
    li      t4, 0
.Lcopy_xr2:
    bge     t4, s3, .Lcopy_xr2_done
    slli    t0, t4, 2
    add     t1, s4, t0
    flw     ft0, 0(t1)
    add     t1, s10, t0
    fsw     ft0, 0(t1)
    addi    t4, t4, 1
    j       .Lcopy_xr2
.Lcopy_xr2_done:
    li      t4, 0
.Lcopy_xi2:
    bge     t4, s3, .Lcopy_xi2_done
    slli    t0, t4, 2
    add     t1, s5, t0
    flw     ft0, 0(t1)
    add     t1, s11, t0
    fsw     ft0, 0(t1)
    addi    t4, t4, 1
    j       .Lcopy_xi2
.Lcopy_xi2_done:
    mv      a0, s10
    mv      a1, s11
    mv      a2, s0
    srli    a3, s0, 2                # threshold = 2 
    call    highpass_filter
     mv      a0, s10        # filtered xr
    mv      a1, s11        # filtered xi
    mv      a2, s6         # twr
    mv      a3, s7         # twi
    mv      a4, s0         # rows = N
    mv      a5, s0         # cols = N
    call    ifft_2d        
    mv      a0, s10
    mv      a1, s11
    mv      a2, s9
    mv      a3, s3
    call    compute_magnitude_linear
    li      a0, -100
    ld      a1, 8(sp)       # load filename pointer from stack
    li      a2, 0x241
    li      a3, 0x1A4
    li      a7, 56
    ecall
    mv      s10, a0
    blt     s10, zero, .Lwrite_err
    addi    sp, sp, -16
    sw      s0, 0(sp)
    mv      a0, s10
    mv      a1, sp
    li      a2, 4
    li      a7, 64
    ecall
    sw      s0, 0(sp)
    mv      a0, s10
    mv      a1, sp
    li      a2, 4
    li      a7, 64
    ecall
    addi    sp, sp, 16
    slli    t0, s3, 2
    mv      a0, s10
    mv      a1, s8
    mv      a2, t0
    li      a7, 64
    ecall
    slli    t0, s3, 2
    mv      a0, s10
    mv      a1, s9
    mv      a2, t0
    li      a7, 64
    ecall
    mv      a0, s10
    li      a7, 57
    ecall
    la      a0, .LStr_written
    call    puts
    j       .Lwrite_done
.Lwrite_err:
    la      a0, .LStr_err_open
    call    puts
.Lwrite_done:
    ld      t5, 0(sp)
    mv      a2, t5
    la      a1, .LStr_done
    li      a0, 1
    call    __printf_chk
    mv      a0, s4;   call free
    mv      a0, s5;   call free
    mv      a0, s6;   call free
    mv      a0, s7;   call free
    mv      a0, s8;   call free
    mv      a0, s9;   call free
    ld      a0, 0(sp)
    li      a1, 336
    li      t0, 12
    mul     t0, t0, s0
    add     a1, a1, t0
    li      t0, 6
    mul     t0, t0, s3
    add     t0, t0, s0
    slli    a2, t0, 2
    ld      ra,  184(sp)
    ld      s0,  176(sp)
    ld      s1,  168(sp)
    ld      s2,  160(sp)
    ld      s3,  152(sp)
    ld      s4,  144(sp)
    ld      s5,  136(sp)
    ld      s6,  128(sp)
    ld      s7,  120(sp)
    ld      s8,  112(sp)
    ld      s9,  104(sp)
    ld      s10,  96(sp)
    ld      s11,  88(sp)
    addi    sp, sp, 192
    ret
    .size run_fft2d_test, .-run_fft2d_test



.section .text.startup,"ax",@progbits
    .align 1
    .globl main
    .type  main, @function
main:
    addi    sp, sp, -80       
    sd      ra, 72(sp)
    sd      s0, 64(sp)
    sd      s1, 56(sp)
    sd      s2, 48(sp)
    sd      s3, 40(sp)
    sd      s4, 32(sp)
    sd      s5, 24(sp)
    sd      s6, 16(sp)

.Lstream_loop:
    li      a0, 0              # stdin
    mv      a1, sp            
    li      a2, 4
    li      a7, 63
    ecall
    blez    a0, .Lstream_exit  

    lw      s0, 0(sp)          # s0 = N 
    mul     s1, s0, s0         # s1 = N*N

    # Allocate xr 
    slli    a0, s1, 2
    call    malloc
    mv      s2, a0

    # Allocate xi and zero it 
    slli    a0, s1, 2
    call    malloc
    mv      s3, a0
    li      t0, 0
    fcvt.s.w ft0, zero
.Lzero_xi_s:
    bge     t0, s1, .Lzero_xi_s_done
    slli    t1, t0, 2
    add     t1, s3, t1
    fsw     ft0, 0(t1)
    addi    t0, t0, 1
    j       .Lzero_xi_s
.Lzero_xi_s_done:

    # Read N*N floats into xr (loop until all bytes received) 
    slli    s6, s1, 2          # s6 = total byte count
    mv      t0, s2             # write pointer
    mv      t1, s6             # remaining
.Lread_pixels:
    beqz    t1, .Lread_pixels_done
    li      a0, 0
    mv      a1, t0
    mv      a2, t1
    li      a7, 63
    ecall
    blez    a0, .Lstream_exit
    add     t0, t0, a0
    sub     t1, t1, a0
    j       .Lread_pixels
.Lread_pixels_done:

    # Twiddle factors 
    srli    t0, s0, 1
    slli    a0, t0, 2
    call    malloc
    mv      s4, a0             # twr

    srli    t0, s0, 1
    slli    a0, t0, 2
    call    malloc
    mv      s5, a0             # twi

    mv      a0, s4
    mv      a1, s5
    mv      a2, s0
    call    generate_twiddle_factors_vec

    #Forward 2D FFT 
    mv      a0, s2
    mv      a1, s3
    mv      a2, s4
    mv      a3, s5
    mv      a4, s0
    mv      a5, s0
    call    fft_2d

    # Highpass filter 
    mv      a0, s2
    mv      a1, s3
    mv      a2, s0
    call    highpass_filter

    # Inverse 2D FFT 
    mv      a0, s2
    mv      a1, s3
    mv      a2, s4
    mv      a3, s5
    mv      a4, s0
    mv      a5, s0
    call    ifft_2d

    # Linear magnitude back into xr
    mv      a0, s2
    mv      a1, s3
    mv      a2, s2
    mv      a3, s1
    call    compute_magnitude_linear

    # Write result to stdout (loop until all bytes sent) 
    mv      t0, s2
    mv      t1, s6
.Lwrite_pixels:
    beqz    t1, .Lwrite_pixels_done
    li      a0, 1
    mv      a1, t0
    mv      a2, t1
    li      a7, 64
    ecall
    blez    a0, .Lstream_exit
    add     t0, t0, a0
    sub     t1, t1, a0
    j       .Lwrite_pixels
.Lwrite_pixels_done:

    # Free and loop
    mv      a0, s2;  call free
    mv      a0, s3;  call free
    mv      a0, s4;  call free
    mv      a0, s5;  call free
    j       .Lstream_loop

.Lstream_exit:
    li      a0, 0
    ld      ra, 72(sp)
    ld      s0, 64(sp)
    ld      s1, 56(sp)
    ld      s2, 48(sp)
    ld      s3, 40(sp)
    ld      s4, 32(sp)
    ld      s5, 24(sp)
    ld      s6, 16(sp)
    addi    sp, sp, 80
    ret
    .size main, .-main
