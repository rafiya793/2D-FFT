# fft_vectorized.s  --  RISC-V Vector Extension FFT  (Milestone 3)
# .data section: index array used as source for twiddle generation
# The assignment requires initialising the input array in the data section
# as an index array [0.0, 1.0, 2.0, ...].  We pre-declare a table large
# enough for the maximum N/2 we ever test (N=32 -> 16 entries).  For larger
# N the vector loop falls back to vid.v-generated indices automatically.
    .data
    .align 4
.twiddle_index_table:
    .float  0.0,  1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0
    .float  8.0,  9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0

# .rodata: floating-point constants

    .section .rodata
    .align 2

.VEC_PI:            .float  3.14159265358979323846
.VEC_HALF_PI:       .float  1.57079632679489661923
.VEC_TWO_PI:        .float  6.28318530717958647692
.VEC_NEG_TWO_PI:    .float -6.28318530717958647692
.VEC_ONE:           .float  1.0
.VEC_NEG_ONE:       .float -1.0
.VEC_ZERO:          .float  0.0

# ---- Minimax polynomial coefficients for sin(x), valid on [-PI/2, PI/2] ----
# sin(x) ~ x*(1 + x^2*(C1 + x^2*(C2 + x^2*(C3 + x^2*C4))))
# Cephes single-precision coefficients (accurate to ~1e-7 over [-pi/2, pi/2]):
.SIN_C1:    .float -0.16666667163    # -1/6
.SIN_C2:    .float  0.00833333379    #  1/120
.SIN_C3:    .float -0.00019841270    # -1/5040
.SIN_C4:    .float  0.00000275573    #  1/362880

# ---- Minimax polynomial coefficients for cos(x), valid on [-PI/2, PI/2] ----
# cos(x) ~ 1 + x^2*(D1 + x^2*(D2 + x^2*(D3 + x^2*D4)))
.COS_D1:    .float -0.50000000000    # -1/2
.COS_D2:    .float  0.04166666567    #  1/24
.COS_D3:    .float -0.00138888889    # -1/720
.COS_D4:    .float  0.00002480158    #  1/40320

    .section .text
    .align 2


# SECTION 1 -- VECTOR TWIDDLE FACTOR GENERATION
# generate_twiddle_factors_vec(a0: real_ptr, a1: imag_ptr, a2: N)
#
# Register map (saved across the outer chunk loop):
#   s0 = real_ptr (cos output)
#   s1 = imag_ptr (sin output)
#   s2 = N/2  (total twiddle count)
#   s3 = k    (chunk base, integer index)
#   fs0 = step = -2*PI/N

    .globl generate_twiddle_factors_vec
generate_twiddle_factors_vec:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)
    sd      s2, 16(sp)
    sd      s3,  8(sp)
    fsd     fs0,  0(sp)

    mv      s0, a0              # real_ptr  (cos output)
    mv      s1, a1              # imag_ptr  (sin output)
    srli    s2, a2, 1           # N/2 = number of twiddles to generate

    # Precompute step = -2*PI / N  (scalar)
    la      t0, .VEC_NEG_TWO_PI
    flw     ft0, 0(t0)          # ft0 = -2*PI
    fcvt.s.w ft1, a2            # ft1 = (float)N
    fdiv.s  fs0, ft0, ft1       # fs0 = -2*PI/N

    li      s3, 0               # k = 0  (chunk base index)

    # Pointer to pre-declared index table in .data
    la      t6, .twiddle_index_table

.Ltwig_chunk_loop:
    beq     s3, s2, .Ltwig_done

    # ----- compute vl for this chunk -----
    sub     t0, s2, s3          # remaining = N/2 - k
    vsetvli t1, t0, e32, m1, ta, ma   # t1 = actual vl

    li      t2, 16
    bge     s3, t2, .Ltwig_use_vid

    # Load from pre-declared .data index array (floats): indices s3..s3+vl-1
    slli    t3, s3, 2           # byte offset = k * 4
    add     t3, t6, t3          # &table[k]
    vle32.v v0, (t3)            # v0 = [k.0, (k+1).0, ...]  (float)
    j       .Ltwig_got_index

.Ltwig_use_vid:
    # For indices >= 16: generate via vid.v + float convert + offset
    vid.v   v0                  # v0 = [0, 1, ..., vl-1]  (integer)
    vfcvt.f.xu.v v0, v0         # convert to float
    fcvt.s.w ft2, s3            # ft2 = (float)k
    vfadd.vf v0, v0, ft2        # v0 = [k.0, k+1.0, ...]

.Ltwig_got_index:
    vfmul.vf v1, v0, fs0        # v1 = angle[i] = k_i * (-2*PI/N), range [-PI,0]

    
    # We work with a = |angle| = -angle, which lies in [0, PI].
    # Load PI/2 as a scalar broadcast constant for comparisons.
    #
    la      t2, .VEC_HALF_PI
    flw     ft2, 0(t2)          # ft2 = PI/2
    la      t3, .VEC_PI
    flw     ft3, 0(t3)          # ft3 = PI

    # a = -angle  (negate so a >= 0)
    vfneg.v v5, v1              # v5 = a = |angle|, range [0, PI]

    # Build mask: Q1_mask[i] = 1 where a[i] > PI/2  (second quadrant)
    vmfgt.vf v0, v5, ft2        # v0 (mask) = (a > PI/2)

    # reduced = a  for Q0,  reduced = a - PI/2  for Q1
    # First copy v5 into v6 (so Q0 lanes keep value 'a' unchanged)
    vmv.v.v v6, v5              # v6 = a  (all lanes)
    # Then subtract PI/2 only where Q1 mask is set
    vfsub.vf v6, v6, ft2, v0.t # v6 = a - PI/2  where Q1, else a

    # Compute x^2
    vfmul.vv v2, v6, v6         # v2 = x^2  (x = reduced angle)

    # ---- cos_poly(x) = 1 + x^2*(D1 + x^2*(D2 + x^2*(D3 + x^2*D4))) ----
    la      t4, .COS_D4
    flw     ft4, 0(t4)
    vfmv.v.f v3, ft4            # v3 = D4

    la      t4, .COS_D3
    flw     ft4, 0(t4)
    vfmul.vv v3, v2, v3
    vfadd.vf v3, v3, ft4        # D3 + x^2*D4

    la      t4, .COS_D2
    flw     ft4, 0(t4)
    vfmul.vv v3, v2, v3
    vfadd.vf v3, v3, ft4        # D2 + x^2*(D3+...)

    la      t4, .COS_D1
    flw     ft4, 0(t4)
    vfmul.vv v3, v2, v3
    vfadd.vf v3, v3, ft4        # D1 + x^2*(D2+...)

    vfmul.vv v3, v2, v3         # x^2*(D1+...)
    la      t4, .VEC_ONE
    flw     ft4, 0(t4)
    vfadd.vf v3, v3, ft4        # v3 = cos_poly(x)

    # ---- sin_poly(x) = x*(1 + x^2*(C1 + x^2*(C2 + x^2*(C3 + x^2*C4)))) ----
    la      t4, .SIN_C4
    flw     ft4, 0(t4)
    vfmv.v.f v4, ft4            # v4 = C4

    la      t4, .SIN_C3
    flw     ft4, 0(t4)
    vfmul.vv v4, v2, v4
    vfadd.vf v4, v4, ft4        # C3 + x^2*C4

    la      t4, .SIN_C2
    flw     ft4, 0(t4)
    vfmul.vv v4, v2, v4
    vfadd.vf v4, v4, ft4        # C2 + x^2*(C3+...)

    la      t4, .SIN_C1
    flw     ft4, 0(t4)
    vfmul.vv v4, v2, v4
    vfadd.vf v4, v4, ft4        # C1 + x^2*(...)

    vfmul.vv v4, v2, v4         # x^2*(C1+...)
    la      t4, .VEC_ONE
    flw     ft4, 0(t4)
    vfadd.vf v4, v4, ft4        # 1 + x^2*(C1+...)
    vfmul.vv v4, v6, v4         # v4 = sin_poly(x) = x*(...)

    vfneg.v v7, v4              # v7 = -sin_poly(x)
    # v8 = v3 (cos_poly), already available

    vmerge.vvm v9, v3, v7, v0  # v9 = Q0: cos_poly, Q1: -sin_poly
                                # = cos(a) for all lanes

    vmerge.vvm v10, v4, v3, v0 # v10 = Q0: sin_poly, Q1: cos_poly
                                # = sin(a) for all lanes

    # twr[k] = cos(angle) = cos(a)   -> v9 as-is
    # twi[k] = sin(angle) = -sin(a)  -> negate v10
    vfneg.v v10, v10            # v10 = -sin(a) = sin(angle)

    slli    t3, s3, 2           # byte offset = k * 4
    add     t3, s0, t3
    vse32.v v9,  (t3)           # store cos (twr)

    slli    t3, s3, 2
    add     t3, s1, t3
    vse32.v v10, (t3)           # store sin (twi)

    add     s3, s3, t1          # k += vl
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

# SECTION 2 -- VECTOR BIT REVERSAL  (index computation only)
# bit_reverse_vec(a0: index_out (int* of length N), a1: log_n, a2: N)

    .globl bit_reverse_vec
bit_reverse_vec:
    addi    sp, sp, -48
    sd      ra,  40(sp)
    sd      s0,  32(sp)
    sd      s1,  24(sp)
    sd      s2,  16(sp)
    sd      s3,   8(sp)

    mv      s0, a0          # index_out
    mv      s1, a1          # log_n
    mv      s2, a2          # N  (total elements to process)
    li      s3, 0           # base index k

.Lbr_vec_chunk:
    beqz    s2, .Lbr_vec_done

    vsetvli t0, s2, e32, m1, ta, ma # t0 = vl

    # --- step 1: generate source indices [k, k+1, ..., k+vl-1] ---
    vid.v   v0                      # v0 = [0,1,...,vl-1]
    vmv.v.x v2, s3                  # v2 = [k,k,...,k]
    vadd.vv v0, v0, v2              # v0 = [k, k+1, ...]

    # --- step 2: bit-reverse v0 using shift-mask loop ---
    vmv.v.i v1, 0                   # v1 = result = 0
    mv      t1, s1                  # t1 = bits remaining (= log_n)

.Lbr_bit_loop:
    beqz    t1, .Lbr_bit_done

    vsll.vi v1, v1, 1               # result <<= 1
    vand.vi v3, v0, 1               # v3 = src & 1  (LSB)
    vor.vv  v1, v1, v3              # result |= LSB
    vsrl.vi v0, v0, 1               # src >>= 1

    addi    t1, t1, -1
    j       .Lbr_bit_loop

.Lbr_bit_done:
    # --- step 3: store reversed indices ---
    slli    t1, s3, 2
    add     t1, s0, t1              # &index_out[k]
    vse32.v v1, (t1)                # store vl words

    add     s3, s3, t0
    sub     s2, s2, t0
    j       .Lbr_vec_chunk

.Lbr_vec_done:
    ld      ra,  40(sp)
    ld      s0,  32(sp)
    ld      s1,  24(sp)
    ld      s2,  16(sp)
    ld      s3,   8(sp)
    addi    sp, sp, 48
    ret


# SECTION 3 -- VECTOR ARRAY REORDERING  (gather load)
# bit_reverse_array_vec(a0: xr, a1: xi, a2: N)

    .globl bit_reverse_array_vec
bit_reverse_array_vec:
    addi    sp, sp, -96
    sd      ra,  88(sp)
    sd      s0,  80(sp)
    sd      s1,  72(sp)
    sd      s2,  64(sp)
    sd      s3,  56(sp)
    sd      s4,  48(sp)
    sd      s5,  40(sp)

    mv      s0, a0          # xr
    mv      s1, a1          # xi
    mv      s2, a2          # N

    # --- allocate three arrays of N floats on the heap ---
    slli    t0, s2, 2       # N * 4 bytes
    mv      a0, t0
    call    malloc
    mv      s3, a0          # s3 = rev_idx

    slli    t0, s2, 2
    mv      a0, t0
    call    malloc
    mv      s4, a0          # s4 = tmp_r

    slli    t0, s2, 2
    mv      a0, t0
    call    malloc
    mv      s5, a0          # s5 = tmp_i

    # --- compute log_n = log2(N) via scalar helper ---
    mv      a0, s2
    call    log2_int
    mv      t3, a0          # t3 = log_n

    # --- bit_reverse_vec(rev_idx, log_n, N) ---
    mv      a0, s3
    mv      a1, t3
    mv      a2, s2
    call    bit_reverse_vec

    # --- convert rev_idx (element indices) to byte offsets (* 4) ---
    li      t4, 0           # chunk base
    mv      t5, s2          # remaining

.Lreorder_byte_off:
    beqz    t5, .Lreorder_byte_off_done
    vsetvli t0, t5, e32, m1, ta, ma
    slli    t1, t4, 2
    add     t2, s3, t1
    vle32.v v0, (t2)        # load rev_idx chunk
    vsll.vi v0, v0, 2       # * 4 = byte offset
    vse32.v v0, (t2)        # store back
    add     t4, t4, t0
    sub     t5, t5, t0
    j       .Lreorder_byte_off

.Lreorder_byte_off_done:

    # --- gather load: tmp_r[i] = xr[ rev_idx[i] ]  (byte-indexed) ---
    li      t4, 0
    mv      t5, s2

.Lreorder_gather:
    beqz    t5, .Lreorder_gather_done
    vsetvli t0, t5, e32, m1, ta, ma
    slli    t1, t4, 2

    # load byte-offset index vector
    add     t2, s3, t1
    vle32.v v2, (t2)        # v2 = byte offsets

    # gather xr
    vluxei32.v v3, (s0), v2
    add     t2, s4, t1
    vse32.v v3, (t2)        # tmp_r[i] = xr[rev[i]]

    # gather xi
    vluxei32.v v4, (s1), v2
    add     t2, s5, t1
    vse32.v v4, (t2)        # tmp_i[i] = xi[rev[i]]

    add     t4, t4, t0
    sub     t5, t5, t0
    j       .Lreorder_gather

.Lreorder_gather_done:

    # --- copy tmp_r -> xr, tmp_i -> xi ---
    li      t4, 0
    mv      t5, s2

.Lreorder_copy:
    beqz    t5, .Lreorder_copy_done
    vsetvli t0, t5, e32, m1, ta, ma
    slli    t1, t4, 2

    add     t2, s4, t1
    vle32.v v0, (t2)
    add     t2, s0, t1
    vse32.v v0, (t2)        # xr[i] = tmp_r[i]

    add     t2, s5, t1
    vle32.v v0, (t2)
    add     t2, s1, t1
    vse32.v v0, (t2)        # xi[i] = tmp_i[i]

    add     t4, t4, t0
    sub     t5, t5, t0
    j       .Lreorder_copy

.Lreorder_copy_done:
    # free heap buffers
    mv      a0, s3; call free
    mv      a0, s4; call free
    mv      a0, s5; call free

    ld      ra,  88(sp)
    ld      s0,  80(sp)
    ld      s1,  72(sp)
    ld      s2,  64(sp)
    ld      s3,  56(sp)
    ld      s4,  48(sp)
    ld      s5,  40(sp)
    addi    sp, sp, 96
    ret


# SECTION 4 -- VECTORISED ITERATIVE BUTTERFLY 
# fft_1d_iterative_vec(a0:xr, a1:xi, a2:twr, a3:twi, a4:N)

    .globl fft_1d_iterative_vec
fft_1d_iterative_vec:
    addi    sp, sp, -112
    sd      ra, 104(sp)
    sd      s0,  96(sp); sd s1,  88(sp); sd s2,  80(sp); sd s3,  72(sp)
    sd      s4,  64(sp); sd s5,  56(sp); sd s6,  48(sp); sd s7,  40(sp)
    sd      s8,  32(sp); sd s9,  24(sp)

    mv      s0, a0          # xr
    mv      s1, a1          # xi
    mv      s2, a2          # twr
    mv      s3, a3          # twi
    mv      s4, a4          # N

    # --- step 1: bit-reverse reorder ---
    mv      a0, s0
    mv      a1, s1
    mv      a2, s4
    call    bit_reverse_array_vec

    # --- step 2: outer stage loop  M = 2, 4, 8, ..., N ---
    li      s5, 2           # M = 2

.Lvec_M_loop:
    bgt     s5, s4, .Lvec_fft_done

    srli    s6, s5, 1       # L = M/2

    # FIX 3: step = N/M  -- use divu directly, no fragile loop
    divu    s7, s4, s5      # s7 = step = N/M

    # twiddle byte stride for strided load = step * 4
    slli    t6, s7, 2       # t6 = stride_bytes

    # --- block loop  k = 0, M, 2M, ... ---
    li      s8, 0           # k = 0

.Lvec_k_loop:
    bge     s8, s4, .Lvec_M_next

    # --- inner j-loop vectorised in chunks of vl ---
    li      s9, 0           # j_base = 0

.Lvec_j_chunk:
    bge     s9, s6, .Lvec_k_next    # while j_base < L

    # remaining = L - j_base
    sub     t0, s6, s9
    vsetvli t0, t0, e32, m1, ta, ma # t0 = actual vl

    # --- STRIDED LOAD of twiddle factors ---
    # twr base for this j_base: &twr[j_base * step]
    mul     t1, s9, s7              # j_base * step
    slli    t1, t1, 2               # * 4 (byte offset)
    add     t1, s2, t1              # &twr[j_base*step]
    vlse32.v v0, (t1), t6           # v0 = Wr[0..vl-1]  (strided)

    # FIX 2: twi pointer calculated cleanly -- no corrupt intermediate lines
    mul     t1, s9, s7              # j_base * step  (recalculate cleanly)
    slli    t1, t1, 2               # * 4
    add     t1, s3, t1              # &twi[j_base*step]
    vlse32.v v1, (t1), t6           # v1 = Wi[0..vl-1]  (strided)

    # --- unit-stride load of X2 = xr/xi[k+L+j_base .. k+L+j_base+vl-1] ---
    add     t2, s8, s6              # k + L
    add     t2, t2, s9              # k + L + j_base
    slli    t3, t2, 2
    add     t4, s0, t3
    vle32.v v2, (t4)                # v2 = X2r

    add     t4, s1, t3
    vle32.v v3, (t4)                # v3 = X2i

    # --- complex multiply: T = X2 * W ---
    # Tr = X2r*Wr - X2i*Wi
    vfmul.vv v4, v2, v0             # X2r * Wr
    vfmul.vv v5, v3, v1             # X2i * Wi
    vfsub.vv v6, v4, v5             # v6 = Tr

    # Ti = X2i*Wr + X2r*Wi
    vfmul.vv v4, v3, v0             # X2i * Wr
    vfmul.vv v5, v2, v1             # X2r * Wi
    vfadd.vv v7, v4, v5             # v7 = Ti

    # --- unit-stride load of X1 = xr/xi[k+j_base .. k+j_base+vl-1] ---
    add     t2, s8, s9              # k + j_base
    slli    t3, t2, 2
    add     t4, s0, t3
    vle32.v v8, (t4)                # v8 = X1r

    add     t4, s1, t3
    vle32.v v9, (t4)                # v9 = X1i

    # --- butterfly outputs ---
    vfadd.vv v10, v8, v6            # v10 = X1r + Tr
    vfadd.vv v11, v9, v7            # v11 = X1i + Ti
    vfsub.vv v12, v8, v6            # v12 = X1r - Tr
    vfsub.vv v13, v9, v7            # v13 = X1i - Ti

    # --- store X1 back to xr/xi[k+j_base] ---
    add     t2, s8, s9
    slli    t3, t2, 2
    add     t4, s0, t3
    vse32.v v10, (t4)

    add     t4, s1, t3
    vse32.v v11, (t4)

    # --- store X2 back to xr/xi[k+L+j_base] ---
    add     t2, s8, s6
    add     t2, t2, s9
    slli    t3, t2, 2
    add     t4, s0, t3
    vse32.v v12, (t4)

    add     t4, s1, t3
    vse32.v v13, (t4)

    add     s9, s9, t0              # j_base += vl
    j       .Lvec_j_chunk

.Lvec_k_next:
    add     s8, s8, s5              # k += M
    j       .Lvec_k_loop

.Lvec_M_next:
    slli    s5, s5, 1               # M <<= 1
    j       .Lvec_M_loop

.Lvec_fft_done:
    ld      ra, 104(sp)
    ld      s0,  96(sp); ld s1,  88(sp); ld s2,  80(sp); ld s3,  72(sp)
    ld      s4,  64(sp); ld s5,  56(sp); ld s6,  48(sp); ld s7,  40(sp)
    ld      s8,  32(sp); ld s9,  24(sp)
    addi    sp, sp, 112
    ret

#section 5 - FFt wrapper 

.globl fft_vec
fft_vec:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)
    sd      s2, 16(sp)
    sd      s3,  8(sp)
    sd      s4,  0(sp)

    mv      s0, a0
    mv      s1, a1
    mv      s2, a2

    srli    t0, s2, 1
    slli    t0, t0, 2
    mv      a0, t0
    call    malloc
    mv      s3, a0

    srli    t0, s2, 1
    slli    t0, t0, 2
    mv      a0, t0
    call    malloc
    mv      s4, a0

    mv      a0, s3
    mv      a1, s4
    mv      a2, s2
    call    generate_twiddle_factors_vec

    mv      a0, s0
    mv      a1, s1
    mv      a2, s3
    mv      a3, s4
    mv      a4, s2
    call    fft_1d_iterative_vec

    mv      a0, s3; call free
    mv      a0, s4; call free

    ld      ra, 40(sp)
    ld      s0, 32(sp)
    ld      s1, 24(sp)
    ld      s2, 16(sp)
    ld      s3,  8(sp)
    ld      s4,  0(sp)
    addi    sp, sp, 48
    ret

    
# END OF fft_vectorized.s
