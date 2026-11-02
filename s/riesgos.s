# TEST 2 - Saltos y riesgos.
.include "check.inc"

# BTEST op, ra, rb, esperado
#   Hace "op ra, rb, destino". Si se toma, las 2 addi siguientes se anulan -> t0 = 4.
#   Si no se toma, se ejecutan las 3 -> t0 = 7.
.equ TOMADO,    4
.equ NO_TOMADO, 7
.macro BTEST op, ra, rb, esperado
    li   t0, 0
    \op  \ra, \rb, 1f
    addi t0, t0, 1
    addi t0, t0, 2
1:  addi t0, t0, 4
    CHECK t0, \esperado
.endm

_boot:
    INIT
    li   a1, 0                # 0
    li   a2, 1                # 1
    li   a3, -1               # -1 (sin signo es el mayor)
    li   a4, 0x7FFFFFFF       # MAX con signo
    li   a5, 0x80000000       # MIN con signo (sin signo es mayor que MAX)

    # ---- saltos condicionales: uno tomado y uno no tomado de cada ----
    BTEST beq,  a1, a1, TOMADO       # 0 == 0
    BTEST beq,  a1, a2, NO_TOMADO    # 0 == 1
    BTEST bne,  a1, a2, TOMADO       # 0 != 1
    BTEST bne,  a3, a3, NO_TOMADO    # -1 != -1
    BTEST blt,  a3, a1, TOMADO       # -1 < 0 con signo
    BTEST blt,  a1, a3, NO_TOMADO    # 0 < -1 con signo
    BTEST bge,  a2, a2, TOMADO       # 1 >= 1
    BTEST bge,  a3, a1, NO_TOMADO    # -1 >= 0 con signo
    BTEST bltu, a1, a3, TOMADO       # 0 < 0xFFFFFFFF sin signo
    BTEST bltu, a3, a1, NO_TOMADO    # 0xFFFFFFFF < 0 sin signo
    BTEST bgeu, a3, a1, TOMADO       # 0xFFFFFFFF >= 0 sin signo
    BTEST bgeu, a4, a5, NO_TOMADO    # 0x7FFFFFFF >= 0x80000000 sin signo

    # ---- salto hacia atras: bucle 10+9+...+1 ----
    li   t3, 10
    li   t0, 0
1:  add  t0, t0, t3
    addi t3, t3, -1
    bne  t3, x0, 1b
    CHECK t0, 55

    # ---- jal: guarda la direccion de retorno y anula la instruccion siguiente ----
    li   t0, 0
    jal  t4, 1f
0:  addi t0, t0, 1               # anulada
    addi t0, t0, 2               # anulada
1:  addi t0, t0, 16
    lui  t3, %hi(0b)
    addi t3, t3, %lo(0b)         # t3 = direccion de la instruccion tras el jal
    sub  t4, t4, t3
    CHECK t0, 16
    CHECK t4, 0                  # el enlace guardado era esa direccion

    # ---- jalr ----
    li   t0, 0
    lui  t3, %hi(2f)
    addi t3, t3, %lo(2f)
    jalr t4, 0(t3)
0:  addi t0, t0, 1               # anulada
2:  addi t0, t0, 16
    lui  t3, %hi(0b)
    addi t3, t3, %lo(0b)
    sub  t4, t4, t3
    CHECK t0, 16
    CHECK t4, 0

    # ---- llamada y retorno ----
    li   t0, 0
    jal  ra, f1
    addi t0, t0, 1000            # se ejecuta al volver
    j    9f
f1: addi t0, t0, 10
    ret
9:
    CHECK t0, 1010

    # ---- load seguido INMEDIATAMENTE de una instruccion que usa su resultado ----
    la   s1, datos               # 0x80FF7F01, 0x12345678, 7
    lw   t0, 0(s1)
    addi t0, t0, 1
    CHECK t0, 0x80FF7F02         # como rs1
    li   t2, 0x100
    lw   t0, 4(s1)
    sub  t0, t2, t0
    CHECK t0, 0xEDCBAA88         # como rs2: 0x100 - 0x12345678
    lw   t0, 8(s1)
    add  t0, t0, t0
    CHECK t0, 14                 # como rs1 y rs2
    lw   t0, 0(s1)
    sw   t0, 12(s1)              # como dato de un store
    lw   t0, 12(s1)
    CHECK t0, 0x80FF7F01
    la   t2, ptr
    lw   t3, 0(t2)               # t3 = direccion de cadena
    lw   t0, 0(t3)               # como direccion de otro load
    CHECK t0, 0xC0DE1234
    li   t1, 0x12345678
    lw   t0, 4(s1)
    beq  t0, t1, 1f              # como operando de un salto
    li   t0, 99
1:  CHECK t0, 0x12345678
    lw   t0, 0(s1)
    li   t0, 7                   # escribe el mismo registro: gana la ultima
    CHECK t0, 7
    lb   t0, 3(s1)
    addi t0, t0, 0               # con extension de signo
    CHECK t0, 0xFFFFFF80

    # ---- lo que sigue a un salto tomado NO debe tener efecto ----
    li   t2, 0x55
    beq  x0, x0, 1f
    lw   t2, 0(s1)               # load anulado: t2 no cambia
1:  addi t0, t2, 0
    CHECK t0, 0x55
    li   t2, 0x1111
    sw   t2, 16(s1)
    li   t2, 0x77
    jal  x0, 1f
    sw   t2, 16(s1)              # store anulado: la memoria no cambia
1:  lw   t0, 16(s1)
    CHECK t0, 0x1111
    lw   t3, 4(s1)               # un load justo ANTES del salto SI se completa
    beq  x0, x0, 1f
    addi t2, t3, 0               # anulada
1:  addi t0, t3, 0
    CHECK t0, 0x12345678

    # ---- un salto en la sombra de otro salto tomado tampoco salta ----
    li   t0, 0
    beq  x0, x0, 1f
    beq  x0, x0, 3f              # en la sombra: NO debe saltar
1:  addi t0, t0, 8
    j    4f
3:  addi t0, t0, 100             # solo se llega aqui si algo fallo
4:  CHECK t0, 8
    li   t0, 0
    jal  x0, 1f
    jal  x0, 3f                  # en la sombra: NO debe saltar
1:  addi t0, t0, 8
    j    4f
3:  addi t0, t0, 100
4:  CHECK t0, 8

    # ---- bucle que acumula: suma de un vector (5 -3 100 0 -77 42 7 -1) ----
    la   t3, vec
    li   t4, 8
    li   t0, 0
1:  lw   t2, 0(t3)
    add  t0, t0, t2
    addi t3, t3, 4
    addi t4, t4, -1
    bne  t4, x0, 1b
    CHECK t0, 73

    END

.data
.balign 4
datos:  .word 0x80FF7F01, 0x12345678, 7, 0, 0
ptr:    .word cadena
cadena: .word 0xC0DE1234
vec:    .word 5, -3, 100, 0, -77, 42, 7, -1
