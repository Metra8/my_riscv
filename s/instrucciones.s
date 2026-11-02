# TEST 1 - Cada instrucción con valores límite.
.include "check.inc"

_boot:
    INIT
    li   a1, 0x7FFFFFFF       # MAX (mayor positivo)
    li   a2, 0x80000000       # MIN (menor negativo)
    li   a3, 1
    li   a4, -1               # 0xFFFFFFFF
    li   a5, 5
    li   a6, 3

    # ---- tipo R ----
    add  t0, a1, a3
    CHECK t0, 0x80000000      # MAX + 1 = MIN
    sub  t0, a2, a3
    CHECK t0, 0x7FFFFFFF      # MIN - 1 = MAX
    and  t0, a5, a6
    CHECK t0, 1               # 101 & 011
    or   t0, a5, a6
    CHECK t0, 7               # 101 | 011
    xor  t0, a5, a6
    CHECK t0, 6               # 101 ^ 011
    sll  t0, a3, a6
    CHECK t0, 8               # 1 << 3
    li   t1, 31
    srl  t0, a2, t1
    CHECK t0, 1               # 0x80000000 >> 31 (lógico)
    sra  t0, a2, t1
    CHECK t0, 0xFFFFFFFF      # 0x80000000 >> 31 (aritmético)
    slt  t0, a4, a3
    CHECK t0, 1               # -1 < 1 con signo
    sltu t0, a4, a3
    CHECK t0, 0               # 0xFFFFFFFF < 1 sin signo

    # ---- tipo I ----
    addi t0, a1, 1
    CHECK t0, 0x80000000      # MAX + 1
    slti t0, a4, 0
    CHECK t0, 1               # -1 < 0
    sltiu t0, a4, 0
    CHECK t0, 0               # 0xFFFFFFFF < 0 sin signo
    xori t0, a4, 0x7FF
    CHECK t0, 0xFFFFF800
    ori  t0, a2, 0x7FF
    CHECK t0, 0x800007FF
    andi t0, a4, 0x7FF
    CHECK t0, 0x7FF
    slli t0, a3, 31
    CHECK t0, 0x80000000      # 1 << 31
    srli t0, a2, 31
    CHECK t0, 1               # lógico
    srai t0, a2, 31
    CHECK t0, 0xFFFFFFFF      # aritmético

    # ---- LUI, AUIPC, x0 ----
    lui  t0, 0x12345
    CHECK t0, 0x12345000
au1: auipc t0, 0x12345         # pc de esta instrucción + 0x12345000
    lui  t2, %hi(au1)
    addi t2, t2, %lo(au1)     # t2 = dirección de au1
    sub  t0, t0, t2
    CHECK t0, 0x12345000
    addi x0, x0, 5            # escribir en x0 se ignora
    CHECK x0, 0

    # ---- fence, ecall y ebreak: no hacen nada ----
    li   t0, 5
    fence
    ecall
    ebreak
    CHECK t0, 5

    # ---- loads (datos = 0x80FF7F01, 0x12345678) ----
    la   s0, datos
    lb   t0, 3(s0)
    CHECK t0, 0xFFFFFF80      # 0x80 con signo
    lbu  t0, 3(s0)
    CHECK t0, 0x80            # sin signo
    lh   t0, 2(s0)
    CHECK t0, 0xFFFF80FF      # 0x80FF con signo
    lhu  t0, 2(s0)
    CHECK t0, 0x80FF          # sin signo
    lw   t0, 4(s0)
    CHECK t0, 0x12345678
    addi t2, s0, 8
    lw   t0, -4(t2)           # offset negativo
    CHECK t0, 0x12345678

    # ---- stores: zona+4 no debe cambiar ----
    la   s1, zona
    li   t2, 0xA5A5A5A5
    sw   t2, 4(s1)
    li   t2, 0x11
    sb   t2, 0(s1)
    li   t2, 0x22
    sb   t2, 1(s1)
    li   t2, 0x33
    sb   t2, 2(s1)
    li   t2, 0x44
    sb   t2, 3(s1)
    lw   t0, 0(s1)
    CHECK t0, 0x44332211      # 4 sb, cada uno en su byte
    li   t2, 0xBBAA
    sh   t2, 0(s1)
    li   t2, 0xDDCC
    sh   t2, 2(s1)
    lw   t0, 0(s1)
    CHECK t0, 0xDDCCBBAA      # 2 sh
    li   t2, 0x89ABCDEF
    sw   t2, 0(s1)
    lw   t0, 0(s1)
    CHECK t0, 0x89ABCDEF      # sw
    lw   t0, 4(s1)
    CHECK t0, 0xA5A5A5A5      # la palabra vecina sigue igual

    END

.data
.balign 4
datos: .word 0x80FF7F01, 0x12345678
zona:  .space 8
