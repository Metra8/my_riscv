# ---------------------------------------------------------------------------
# check.inc - macros para los tests. Se incluye con:  .include "check.inc"
#
#   INIT                 al principio del test
#   CHECK reg, esperado  comprueba un resultado
#   END                  al final del test
#
# Reservados (no usar en los tests): a0, s11, t5, t6
#
# CHECK compara el registro con el valor esperado. Si no coincide, el test falla
# y escribe en el mailbox el nº de la comprobación. Además acumula la diferencia
# en a0, de modo que aunque un salto estuviese roto el error llegaría al final.
# END escribe 0x900D (PASS) en el mailbox si todo fue correcto.
# ---------------------------------------------------------------------------
.global _boot
.text

.macro INIT
    li   a0, 0              # acumulador de errores
    li   s11, 0             # nº de comprobación
.endm

.macro CHECK reg, expected
    addi s11, s11, 1
    li   t6, \expected
    xor  t6, \reg, t6       # 0 si coincide
    or   a0, a0, t6         # acumula
    beqz t6, 1f
    j    fail
1:
.endm

.macro END
    li   t6, 0x900D
    xor  a0, a0, t6         # a0 == 0  ->  0x900D
    li   t5, 0x10000        # mailbox
    sw   a0, 0(t5)
1:  j    1b
fail:
    li   t5, 0x10000
    sw   s11, 0(t5)         # nº de la comprobación que falló
2:  j    2b
.endm
