# Programa de ejemplo (práctica 1): cadena de addi dependientes + carga de una
# variable de .data. Termina escribiendo 0x900D (PASS) o 1 (FAIL) en el mailbox.
.global _boot
.text

_boot:                    /* x0  = 0    0x000 */
    addi x1 , x0,   1000  /* x1  = 1000 0x3E8 */
    addi x2 , x1,   2000  /* x2  = 3000 0xBB8 */
    addi x3 , x2,  -1000  /* x3  = 2000 0x7D0 */
    addi x4 , x3,  -2000  /* x4  = 0    0x000 */
    addi x5 , x4,   1000  /* x5  = 1000 0x3E8 */

    la   x6, variable
    addi x6, x6, 4        /* x6 = &variable + 4 */
    lw   x7, -4(x6)       /* x7 = 0xdeadbeef (load + uso inmediato) */
    li   x8, 0xdeadbeef
    bne  x7, x8, fail
    li   x9, 1000
    bne  x5, x9, fail

    li   x10, 0x10000     /* mailbox */
    li   x11, 0x900D
    sw   x11, 0(x10)      /* PASS */
1:  j    1b

fail:
    li   x10, 0x10000
    li   x11, 1
    sw   x11, 0(x10)
2:  j    2b

.data
variable:
    .word 0xdeadbeef
