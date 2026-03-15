# =============================================================================
# fft_milestone2.s
# Combined RISC-V Assembly — Milestone 2
#
# Sections (in order):
#   1. Math Helper Functions  (my_sin, my_cos, my_exp, log2_int)
#   2. Twiddle Factor Generation
#   3. Bit Reversal           (reverse_bits)
#   4. Array Reordering       (bit_reverse_array)
#   5. Iterative FFT          (fft_1d_iterative)
#   6. Recursive FFT          (recursive_butterfly_core, fft_1d_recursive)
# =============================================================================


# =============================================================================
# SECTION 1 — CONSTANTS (merged .rodata from all files)
# =============================================================================
    .section .rodata
    .align 2

# PI constants (used by my_sin, my_cos, twiddle generation)
PI:         .word   0x40490FDB      # IEEE 754: pi       = 3.14159265
TWO_PI:     .word   0x40C90FDB      # IEEE 754: 2*pi     = 6.28318531
NEG_PI:     .word   0xC0490FDB      # IEEE 754: -pi      = -3.14159265
HALF_PI:    .word   0x3FC90FDB      # IEEE 754: pi/2     = 1.57079633

ONE:        .float  1.0

# my_sin Taylor series divisors  (x^3/3!, x^5/5!, ... — successive products)
SIN_D1:     .float  6.0             # 3*2
SIN_D2:     .float  20.0            # 5*4
SIN_D3:     .float  42.0            # 7*6
SIN_D4:     .float  72.0            # 9*8
SIN_D5:     .float  110.0           # 11*10
SIN_D6:     .float  156.0           # 13*12

# my_cos Taylor series divisors  (x^2/2!, x^4/4!, ...)
COS_D1:     .float  2.0             # 2*1
COS_D2:     .float  12.0            # 4*3
COS_D3:     .float  30.0            # 6*5
COS_D4:     .float  56.0            # 8*7
COS_D5:     .float  90.0            # 10*9
COS_D6:     .float  132.0           # 12*11


# =============================================================================
# SECTION 2 — MATH HELPER FUNCTIONS
# =============================================================================
    .section .text
    .align 2

# -----------------------------------------------------------------------------
# float my_sin(float x)
#   In:  fa0 = x (radians, any range)
#   Out: fa0 = sin(x)
#   Uses Taylor series after range-reducing x to [-pi, pi]
# -----------------------------------------------------------------------------
    .globl my_sin
my_sin:
    la      a0, PI
    flw     fa1, 0(a0)              # fa1 = PI
    la      a0, TWO_PI
    flw     fa2, 0(a0)              # fa2 = TWO_PI
    la      a0, NEG_PI
    flw     fa3, 0(a0)              # fa3 = -PI

    # Range reduction: while x > PI,  x -= 2*PI
sin_reduce_pos:
    fle.s   a1, fa0, fa1
    bnez    a1, sin_reduce_neg
    fsub.s  fa0, fa0, fa2
    j       sin_reduce_pos

    # Range reduction: while x < -PI, x += 2*PI
sin_reduce_neg:
    fle.s   a1, fa3, fa0
    bnez    a1, sin_taylor
    fadd.s  fa0, fa0, fa2
    j       sin_reduce_neg

    # Taylor: sin(x) = x - x^3/6 - x^5/20 - x^7/42 - x^9/72 - x^11/110 - x^13/156
sin_taylor:
    fmul.s  fa1, fa0, fa0           # fa1 = x^2
    fmv.s   fa4, fa0                # fa4 = running sum, starts at x
    fmv.s   fa5, fa0                # fa5 = current term, starts at x

    la      a0, SIN_D1; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, SIN_D2; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, SIN_D3; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, SIN_D4; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, SIN_D5; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, SIN_D6; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    fmv.s   fa0, fa4
    ret

# -----------------------------------------------------------------------------
# float my_cos(float x)
#   In:  fa0 = x (radians, any range)
#   Out: fa0 = cos(x)
#   Uses Taylor series: cos(x) = 1 - x^2/2 - x^4/12 - ... (same range reduction)
# -----------------------------------------------------------------------------
    .globl my_cos
my_cos:
    la      a0, PI;    flw fa1, 0(a0)
    la      a0, TWO_PI; flw fa2, 0(a0)
    la      a0, NEG_PI; flw fa3, 0(a0)

cos_reduce_pos:
    fle.s   a1, fa0, fa1
    bnez    a1, cos_reduce_neg
    fsub.s  fa0, fa0, fa2
    j       cos_reduce_pos

cos_reduce_neg:
    fle.s   a1, fa3, fa0
    bnez    a1, cos_taylor
    fadd.s  fa0, fa0, fa2
    j       cos_reduce_neg

    # Taylor: cos(x) = 1 - x^2/2 - x^4/12 - x^6/30 - x^8/56 - x^10/90 - x^12/132
cos_taylor:
    fmul.s  fa1, fa0, fa0           # x^2
    la      a0, ONE
    flw     fa4, 0(a0)              # sum = 1.0
    flw     fa5, 0(a0)              # term = 1.0

    la      a0, COS_D1; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, COS_D2; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, COS_D3; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, COS_D4; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, COS_D5; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    la      a0, COS_D6; flw fa2, 0(a0); fneg.s fa3, fa1
    fdiv.s  fa3, fa3, fa2; fmul.s fa5, fa5, fa3; fadd.s fa4, fa4, fa5

    fmv.s   fa0, fa4
    ret

# -----------------------------------------------------------------------------
# float my_exp(float x)
#   In:  fa0 = x
#   Out: fa0 = e^x
#   Uses 12-term Taylor series; handles negative x via 1/e^|x|
# -----------------------------------------------------------------------------
    .globl my_exp
my_exp:
    fmv.w.x fa1, zero
    feq.s   a1, fa0, fa1
    beqz    a1, exp_check_neg
    la      a0, ONE; flw fa0, 0(a0)
    ret

exp_check_neg:
    li      a2, 0
    flt.s   a1, fa0, fa1
    beqz    a1, exp_loop_init
    li      a2, 1
    fneg.s  fa0, fa0

exp_loop_init:
    la      a0, ONE
    flw     fa1, 0(a0)              # res  = 1.0
    flw     fa2, 0(a0)              # term = 1.0
    li      a3, 1                   # i = 1

exp_loop:
    fcvt.s.w fa3, a3
    fdiv.s  fa3, fa0, fa3
    fmul.s  fa2, fa2, fa3
    fadd.s  fa1, fa1, fa2
    addi    a3, a3, 1
    li      a0, 13
    blt     a3, a0, exp_loop

    beqz    a2, exp_done
    la      a0, ONE; flw fa0, 0(a0)
    fdiv.s  fa0, fa0, fa1
    ret

exp_done:
    fmv.s   fa0, fa1
    ret

# -----------------------------------------------------------------------------
# int log2_int(int n)
#   In:  a0 = n
#   Out: a0 = floor(log2(n)), or -1 if n <= 0
# -----------------------------------------------------------------------------
    .globl log2_int
log2_int:
    bgt     a0, zero, log2_loop
    li      a0, -1
    ret

log2_loop:
    li      a1, 0
log2_loop_body:
    li      a2, 1
    ble     a0, a2, log2_done
    srai    a0, a0, 1
    addi    a1, a1, 1
    j       log2_loop_body
log2_done:
    mv      a0, a1
    ret


# =============================================================================
# SECTION 3 — TWIDDLE FACTOR GENERATION
# Computes N/2 complex twiddle factors W_N^k = e^(-j*2*pi*k/N) for k=0..N/2-1
# Forward FFT: angle = -2*pi*k/N   (negative exponent convention)
# Inverse FFT: angle = +2*pi*k/N
# Stores cos(angle) -> real[], sin(angle) -> imag[]
# =============================================================================
    .align 2
    .globl generate_twiddle_factors
    .globl generate_inverse_twiddle_factors

# Internal: twiddle_generator_internal(a0:real_ptr, a1:imag_ptr, a2:n, a3:is_inverse)
twiddle_generator_internal:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    sd      s3, 24(sp)
    fsd     fs0, 16(sp)
    fsd     fs1,  8(sp)

    mv      s0, a0
    mv      s1, a1
    srli    s2, a2, 1               # s2 = N/2 (number of twiddles needed)

    # step = (is_inverse ? +2*PI : -2*PI) / n
    la      t0, TWO_PI
    flw     ft0, 0(t0)              # ft0 = 2*PI
    beqz    a3, .L_twig_fwd_sign   # forward: negate
    j       .L_twig_calc_step
.L_twig_fwd_sign:
    fneg.s  ft0, ft0                # forward FFT uses negative exponent
.L_twig_calc_step:
    fcvt.s.w ft1, a2                # (float)n
    fdiv.s  fs0, ft0, ft1           # fs0 = step = ±2*PI/n

    li      s3, 0                   # k = 0
.L_twig_loop:
    bge     s3, s2, .L_twig_done

    # angle = k * step
    fcvt.s.w fa0, s3
    fmul.s  fa0, fa0, fs0
    fmv.s   fs1, fa0                # save angle

    call    my_cos
    slli    t0, s3, 2; add t1, s0, t0
    fsw     fa0, 0(t1)              # real[k] = cos(angle)

    fmv.s   fa0, fs1
    call    my_sin
    slli    t0, s3, 2; add t1, s1, t0
    fsw     fa0, 0(t1)              # imag[k] = sin(angle)

    addi    s3, s3, 1
    j       .L_twig_loop

.L_twig_done:
    ld      ra, 56(sp); ld s0, 48(sp); ld s1, 40(sp)
    ld      s2, 32(sp); ld s3, 24(sp)
    fld     fs0, 16(sp); fld fs1, 8(sp)
    addi    sp, sp, 64
    ret

generate_twiddle_factors:
    li      a3, 0                   # is_inverse = false
    j       twiddle_generator_internal

generate_inverse_twiddle_factors:
    li      a3, 1                   # is_inverse = true
    j       twiddle_generator_internal


# =============================================================================
# SECTION 4 — BIT REVERSAL
# reverse_bits: reverses the lower log_n bits of an integer x
# =============================================================================
    .align 2
    .globl reverse_bits

# reverse_bits(a0: x, a1: log_n) -> a0 = bit-reversed x
reverse_bits:
    li      t0, 0                   # result = 0
    li      t1, 0                   # bit counter
.L_rev_loop:
    bge     t1, a1, .L_rev_done
    slli    t0, t0, 1               # result <<= 1
    andi    t2, a0, 1               # grab LSB of x
    or      t0, t0, t2             # result |= LSB
    srli    a0, a0, 1               # x >>= 1
    addi    t1, t1, 1
    j       .L_rev_loop
.L_rev_done:
    mv      a0, t0
    ret


# =============================================================================
# SECTION 5 — ARRAY REORDERING
# bit_reverse_array: reorders input arrays in-place using bit-reversal permutation
# Swaps x_r[i] with x_r[rev(i)] and x_i[i] with x_i[rev(i)] for all i where rev(i) > i
# =============================================================================
    .align 2
    .globl bit_reverse_array

# bit_reverse_array(a0: xr, a1: xi, a2: n)
bit_reverse_array:
    addi    sp, sp, -64
    sd      ra, 56(sp); sd s0, 48(sp); sd s1, 40(sp)
    sd      s2, 32(sp); sd s3, 24(sp); sd s4, 16(sp)

    mv      s0, a0                  # xr
    mv      s1, a1                  # xi
    mv      s2, a2                  # n

    mv      a0, s2
    call    log2_int                # a0 = log2(n)
    mv      s3, a0                  # s3 = log_n

    li      s4, 0                   # i = 0
.L_arr_loop:
    bge     s4, s2, .L_arr_done

    mv      a0, s4; mv a1, s3
    call    reverse_bits            # a0 = rev(i)

    bge     s4, a0, .L_arr_next    # only swap if rev(i) > i (avoid double-swap)

    slli    t0, s4, 2; slli t1, a0, 2
    add     t2, s0, t0; add t3, s0, t1
    flw     ft0, 0(t2); flw ft1, 0(t3)
    fsw     ft1, 0(t2); fsw ft0, 0(t3)   # swap xr[i] <-> xr[rev(i)]

    add     t2, s1, t0; add t3, s1, t1
    flw     ft0, 0(t2); flw ft1, 0(t3)
    fsw     ft1, 0(t2); fsw ft0, 0(t3)   # swap xi[i] <-> xi[rev(i)]

.L_arr_next:
    addi    s4, s4, 1
    j       .L_arr_loop
.L_arr_done:
    ld      ra, 56(sp); ld s0, 48(sp); ld s1, 40(sp)
    ld      s2, 32(sp); ld s3, 24(sp); ld s4, 16(sp)
    addi    sp, sp, 64
    ret


# =============================================================================
# SECTION 6 — ITERATIVE FFT
# Cooley-Tukey iterative (in-place, decimation-in-time):
#   1. Bit-reverse reorder input (inlined for performance)
#   2. Butterfly stages: for M = 2, 4, 8, ..., N
#      for each block of M, for each j in [0, M/2):
#        T = W * X[k + M/2 + j]
#        X[k+j]       = X[k+j] + T
#        X[k+M/2+j]   = X[k+j] - T
# =============================================================================
    .align 2
    .globl fft_1d_iterative
    .globl butterfly_iterative

# fft_1d_iterative(a0:xr, a1:xi, a2:twr, a3:twi, a4:n)
#   Wrapper entry point. Delegates to butterfly_iterative.
fft_1d_iterative:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp); sd s1, 24(sp)
    sd      s2, 16(sp); sd s3,  8(sp); sd s4, 0(sp)
    mv      s0, a0; mv s1, a1; mv s2, a2; mv s3, a3; mv s4, a4
    li      t0, 1
    ble     s4, t0, .L_fft1d_iter_done
    mv      a0, s0; mv a1, s1; mv a2, s2; mv a3, s3; mv a4, s4
    call    butterfly_iterative
.L_fft1d_iter_done:
    ld      ra, 40(sp)
    ld      s0, 32(sp); ld s1, 24(sp)
    ld      s2, 16(sp); ld s3,  8(sp); ld s4, 0(sp)
    addi    sp, sp, 48
    ret

# butterfly_iterative(a0:xr, a1:xi, a2:twr, a3:twi, a4:n)
#   Full in-place iterative Cooley-Tukey FFT (bit-reversal + butterfly stages).
butterfly_iterative:
    addi    sp, sp, -128
    sd      ra, 120(sp)
    sd      s0, 112(sp); sd s1, 104(sp); sd s2,  96(sp); sd s3,  88(sp); sd s4, 80(sp)
    sd      s5,  72(sp); sd s6,  64(sp); sd s7,  56(sp); sd s8,  48(sp); sd s9, 40(sp)
    sd      s10, 32(sp)

    mv      s0, a0                  # xr
    mv      s1, a1                  # xi
    mv      s2, a2                  # tw_r
    mv      s3, a3                  # tw_i
    mv      s4, a4                  # n

    # --- Inlined bit-reversal ---
    li      s10, 0
    mv      t0, s4
.L_it_log_loop:
    srli    t0, t0, 1
    beqz    t0, .L_it_start_br
    addi    s10, s10, 1
    j       .L_it_log_loop

.L_it_start_br:
    li      s5, 0
.L_it_br_outer:
    bge     s5, s4, .L_it_start_butterfly
    li      t0, 0; mv t1, s5; li t2, 0
.L_it_br_inner:
    bge     t2, s10, .L_it_br_swap
    slli    t0, t0, 1
    andi    t3, t1, 1; or t0, t0, t3
    srli    t1, t1, 1
    addi    t2, t2, 1
    j       .L_it_br_inner
.L_it_br_swap:
    bge     s5, t0, .L_it_br_next
    slli    t2, s5, 2; slli t3, t0, 2
    add     t4, s0, t2; add t5, s0, t3
    flw     ft0, 0(t4); flw ft1, 0(t5); fsw ft1, 0(t4); fsw ft0, 0(t5)
    add     t4, s1, t2; add t5, s1, t3
    flw     ft0, 0(t4); flw ft1, 0(t5); fsw ft1, 0(t4); fsw ft0, 0(t5)
.L_it_br_next:
    addi    s5, s5, 1
    j       .L_it_br_outer

    # --- Butterfly stages ---
.L_it_start_butterfly:
    li      s5, 2                   # M = 2 (outer stage loop)
.L_it_M_loop:
    bgt     s5, s4, .L_it_done

    srli    s8, s5, 1               # L = M/2

    # Compute twiddle step = n/M (as integer, for indexing tw array)
    mv      t0, s4; mv t1, s5; li s9, 0
.L_it_step:                         # FIX: renamed from .L_calc_step to avoid collision
    ble     t0, t1, .L_it_step_found
    srli    t0, t0, 1
    addi    s9, s9, 1
    j       .L_it_step
.L_it_step_found:
    li      t0, 1; sll s9, t0, s9  # s9 = n/M

    li      s6, 0                   # k = 0
.L_it_k_loop:
    bge     s6, s4, .L_it_M_next

    li      s7, 0                   # j = 0
.L_it_j_loop:
    bge     s7, s8, .L_it_k_next

    add     t0, s6, s7              # idx1 = k+j
    add     t1, t0, s8              # idx2 = k+j+L
    mul     t2, s7, s9              # tw_idx = j * (n/M)

    slli    t3, t2, 2
    add     t4, s2, t3; add t5, s3, t3
    flw     ft0, 0(t4); flw ft1, 0(t5)   # Wr, Wi

    slli    t3, t1, 2
    add     t4, s0, t3; add t5, s1, t3
    flw     ft2, 0(t4); flw ft3, 0(t5)   # X2r, X2i

    # T = X2 * W  (complex multiply)
    fmul.s  ft4, ft2, ft0; fmul.s ft5, ft3, ft1; fsub.s ft6, ft4, ft5  # Tr
    fmul.s  ft4, ft2, ft1; fmul.s ft5, ft3, ft0; fadd.s ft7, ft4, ft5  # Ti

    slli    t3, t0, 2
    add     t4, s0, t3; add t5, s1, t3
    flw     ft8, 0(t4); flw ft9, 0(t5)   # Ar, Ai

    fadd.s  ft10, ft8, ft6; fadd.s ft11, ft9, ft7
    fsw     ft10, 0(t4); fsw ft11, 0(t5)  # X[idx1] = A + T

    fsub.s  ft10, ft8, ft6; fsub.s ft11, ft9, ft7
    slli    t3, t1, 2; add t4, s0, t3; add t5, s1, t3
    fsw     ft10, 0(t4); fsw ft11, 0(t5)  # X[idx2] = A - T

    addi    s7, s7, 1
    j       .L_it_j_loop
.L_it_k_next:
    add     s6, s6, s5
    j       .L_it_k_loop
.L_it_M_next:
    slli    s5, s5, 1
    j       .L_it_M_loop

.L_it_done:
    ld      ra, 120(sp)
    ld      s0, 112(sp); ld s1, 104(sp); ld s2,  96(sp); ld s3,  88(sp); ld s4, 80(sp)
    ld      s5,  72(sp); ld s6,  64(sp); ld s7,  56(sp); ld s8,  48(sp); ld s9, 40(sp)
    ld      s10, 32(sp)
    addi    sp, sp, 128
    ret


# =============================================================================
# SECTION 7 — RECURSIVE FFT
# Cooley-Tukey recursive (decimation-in-time):
#   fft_1d_recursive: bit-reverse reorder, then call recursive_butterfly_core
#   recursive_butterfly_core(xr, xi, offset, n, N_full, twr, twi):
#     if half_n != 1: recurse on left half, then right half
#     butterfly: for j in [0, half_n): combine pairs using twiddle factors
# =============================================================================
    .align 2
    .globl fft_1d_recursive
    .globl butterfly_recursive
    .globl recursive_butterfly_core

# -----------------------------------------------------------------------------
# fft_1d_recursive(a0:xr, a1:xi, a2:twr, a3:twi, a4:n)
# -----------------------------------------------------------------------------
fft_1d_recursive:
    addi    sp, sp, -48
    sd      ra, 40(sp); sd s0, 32(sp); sd s1, 24(sp)
    sd      s2, 16(sp); sd s3,  8(sp); sd s4,  0(sp)

    mv      s0, a0                  # xr
    mv      s1, a1                  # xi
    mv      s2, a2                  # tw_r
    mv      s3, a3                  # tw_i
    mv      s4, a4                  # n

    mv      a0, s0; mv a1, s1; mv a2, s4
    call    bit_reverse_array       # reorder in-place

    li      t0, 1
    ble     s4, t0, .L_fft1d_done

    # recursive_butterfly_core(xr, xi, offset=0, n, N_full=n, twr, twi)
    mv      a0, s0; mv a1, s1
    li      a2, 0                   # offset
    mv      a3, s4                  # n
    mv      a4, s4                  # N_full
    mv      a5, s2                  # tw_r
    mv      a6, s3                  # tw_i
    call    recursive_butterfly_core

.L_fft1d_done:
    ld      ra, 40(sp); ld s0, 32(sp); ld s1, 24(sp)
    ld      s2, 16(sp); ld s3,  8(sp); ld s4,  0(sp)
    addi    sp, sp, 48
    ret

# -----------------------------------------------------------------------------
# butterfly_recursive(a0:xr, a1:xi, a2:twr, a3:twi, a4:n)
#   Thin wrapper — calls recursive_butterfly_core with offset=0, N_full=n
# -----------------------------------------------------------------------------
butterfly_recursive:
    li      t0, 1
    ble     a4, t0, .L_bfly_rec_ret
    mv      t1, a2; mv t2, a3; mv t3, a4
    mv      a5, t1; mv a6, t2
    mv      a3, t3; mv a4, t3
    li      a2, 0
    tail    recursive_butterfly_core
.L_bfly_rec_ret:
    ret

# -----------------------------------------------------------------------------
# recursive_butterfly_core(a0:xr, a1:xi, a2:offset, a3:n, a4:N_full, a5:twr, a6:twi)
#   Frame: 112 bytes — saves ra, s0-s8 (integer), fs2-fs5 (float callee-saved)
# -----------------------------------------------------------------------------
recursive_butterfly_core:

    srai    t0, a3, 1               # half_n = n >> 1

    # Base case: if half_n == 1, skip recursion, go straight to butterfly
    li      t1, 1
    beq     t0, t1, .L_rbc_butterfly

    # If n <= 1, nothing to do
    ble     a3, t1, .L_rbc_ret

    # --- PROLOGUE ---
    addi    sp, sp, -112
    sd      ra,  104(sp); sd s0,  96(sp); sd s1,  88(sp); sd s2,  80(sp)
    sd      s3,   72(sp); sd s4,  64(sp); sd s5,  56(sp); sd s6,  48(sp)
    sd      s7,   40(sp); sd s8,  32(sp)
    fsd     fs2,  24(sp); fsd fs3, 16(sp); fsd fs4,  8(sp); fsd fs5,  0(sp)

    mv      s0, a0; mv s1, a1; mv s2, a2
    mv      s3, a3; mv s4, a4; mv s5, a5; mv s6, a6
    srai    s7, s3, 1               # half_n
    divw    s8, s4, s3              # stride = N_full / n

    # Recurse left half: (xr, xi, offset, half_n, N_full, twr, twi)
    mv      a0, s0; mv a1, s1; mv a2, s2
    mv      a3, s7; mv a4, s4; mv a5, s5; mv a6, s6
    call    recursive_butterfly_core

    # Recurse right half: (xr, xi, offset+half_n, half_n, N_full, twr, twi)
    mv      a0, s0; mv a1, s1
    addw    a2, s2, s7              # offset + half_n
    mv      a3, s7; mv a4, s4; mv a5, s5; mv a6, s6
    call    recursive_butterfly_core

    j       .L_rbc_loop_setup

.L_rbc_butterfly:
    # Base case entry point — set up frame and s-regs from a-regs
    addi    sp, sp, -112
    sd      ra,  104(sp); sd s0,  96(sp); sd s1,  88(sp); sd s2,  80(sp)
    sd      s3,   72(sp); sd s4,  64(sp); sd s5,  56(sp); sd s6,  48(sp)
    sd      s7,   40(sp); sd s8,  32(sp)
    fsd     fs2,  24(sp); fsd fs3, 16(sp); fsd fs4,  8(sp); fsd fs5,  0(sp)

    mv      s0, a0; mv s1, a1; mv s2, a2
    mv      s3, a3; mv s4, a4; mv s5, a5; mv s6, a6
    srai    s7, s3, 1               # half_n = 1 (for base case)
    divw    s8, s4, s3              # stride = N_full / n

.L_rbc_loop_setup:
    mv      t3, s0                  # t3 = xr (float*)
    mv      t4, s1                  # t4 = xi (float*)
    li      t1, 0                   # j = 0

.L_rbc_loop:
    bge     t1, s7, .L_rbc_epilogue

    # tw_idx = j * stride
    mulw    t2, t1, s8
    slli    t5, t2, 2
    add     t6, s5, t5; flw ft0, 0(t6)   # Wr = tw_r[tw_idx]
    add     t6, s6, t5; flw ft1, 0(t6)   # Wi = tw_i[tw_idx]

    # Br, Bi = x[offset + half_n + j]
    addw    t2, s2, s7; addw t2, t2, t1
    slli    t5, t2, 2
    add     t6, t3, t5; flw ft2, 0(t6)   # Br
    add     t6, t4, t5; flw ft3, 0(t6)   # Bi

    # Tr = Br*Wr - Bi*Wi,  Ti = Bi*Wr + Br*Wi
    fmul.s  ft4, ft2, ft0; fmul.s ft5, ft3, ft1; fsub.s ft6, ft4, ft5  # Tr
    fmul.s  ft4, ft3, ft0; fmul.s ft5, ft2, ft1; fadd.s ft7, ft4, ft5  # Ti

    # Ar, Ai = x[offset + j]
    addw    t2, s2, t1
    slli    t5, t2, 2
    add     t6, t3, t5; flw fs2, 0(t6)   # Ar (callee-saved)
    add     t6, t4, t5; flw fs3, 0(t6)   # Ai

    # x[offset+j] = Ar+Tr, Ai+Ti
    fadd.s  fs4, fs2, ft6; fadd.s fs5, fs3, ft7
    addw    t2, s2, t1; slli t5, t2, 2
    add     t6, t3, t5; fsw fs4, 0(t6)
    add     t6, t4, t5; fsw fs5, 0(t6)

    # x[offset+half_n+j] = Ar-Tr, Ai-Ti
    fsub.s  fs4, fs2, ft6; fsub.s fs5, fs3, ft7
    addw    t2, s2, s7; addw t2, t2, t1; slli t5, t2, 2
    add     t6, t3, t5; fsw fs4, 0(t6)
    add     t6, t4, t5; fsw fs5, 0(t6)

    addi    t1, t1, 1
    j       .L_rbc_loop

.L_rbc_epilogue:
    ld      ra,  104(sp); ld s0,  96(sp); ld s1,  88(sp); ld s2,  80(sp)
    ld      s3,   72(sp); ld s4,  64(sp); ld s5,  56(sp); ld s6,  48(sp)
    ld      s7,   40(sp); ld s8,  32(sp)
    fld     fs2,  24(sp); fld fs3, 16(sp); fld fs4,  8(sp); fld fs5,  0(sp)
    addi    sp, sp, 112
    ret

.L_rbc_ret:
    ret


# =============================================================================
