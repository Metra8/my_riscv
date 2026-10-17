# Flujo de trabajo: de ensamblador RISC-V a simulación con Verilator

Guía para compilar un programa en ensamblador RV32I, convertirlo a un fichero
de memoria `.hex` y simularlo sobre el core RISC-V (SystemVerilog) con Verilator.

## 1. Requisitos

| Herramienta                          | Para qué sirve                                     |
| ------------------------------------ | -------------------------------------------------- |
| `riscv64-elf-gcc` / `riscv64-elf-as` | Ensamblar y enlazar el programa                    |
| `riscv64-elf-objcopy`                | Convertir el ELF en un `.hex` para `$readmemh`     |
| `verilator` (>= 5.x)                 | Compilar y simular el diseño (`--binary --timing`) |

Comprueba que están instaladas:

```bash
riscv64-elf-gcc --version
riscv64-elf-objcopy --version
verilator --version
```

> El prefijo del toolchain depende de la distribución. En Arch es
> `riscv64-elf-`; en Debian/Ubuntu suele ser `riscv64-unknown-elf-`
> o `riscv64-linux-gnu-`. Usa el que tengas instalado en todos los comandos.

## 2. Estructura del proyecto

```
arq_dig/
├── program.s            # programa en ensamblador
├── program.elf          # (generado) ejecutable enlazado
├── hex/
│   └── program.hex      # (generado) imagen de memoria
├── sv/
│   ├── riscv_pkg.sv     # paquete: opcodes, códigos de la ALU
│   ├── alu.sv
│   ├── fetch.sv
│   ├── decoder.sv
│   ├── regfile.sv
│   ├── memory.sv        # memoria de doble puerto
│   ├── core.sv
│   ├── flist.f          # lista de ficheros
│   └── tb/
│       └── riscv_tb.sv  # testbench
└── obj_dir/             # (generado por Verilator)
```

Todos los comandos se lanzan **desde la raíz del proyecto** (`arq_dig/`),
porque el testbench busca `hex/program.hex` con ruta relativa.

## 3. Paso 1: ensamblar y enlazar

```bash
riscv64-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0x0 \
    program.s -o program.elf
```

| Opción         | Significado                                               |
| -------------- | --------------------------------------------------------- |
| `-march=rv32i` | Solo el juego base de enteros de 32 bits (sin M, A, C...) |
| `-mabi=ilp32`  | ABI de 32 bits sin coma flotante                          |
| `-nostdlib`    | No enlaza libc ni el código de arranque (`crt0`)          |
| `-Ttext=0x0`   | La sección `.text` empieza en la dirección 0              |

Con `-Ttext=0x0` la primera instrucción (`_boot`) queda en la dirección 0,
que es donde arranca el PC tras el reset. La sección `.data` la coloca el
enlazador después, normalmente alineada a página (p. ej. `0x1020`).

Para inspeccionar el resultado:

```bash
riscv64-elf-objdump -d program.elf          # desensamblado
riscv64-elf-objdump -s -j .data program.elf # contenido de .data
riscv64-elf-nm program.elf                  # direcciones de los símbolos
```

## 4. Paso 2: generar el `.hex`

```bash
mkdir -p hex
riscv64-elf-objcopy -O verilog --verilog-data-width=4 program.elf hex/program.hex
```

`--verilog-data-width=4` es **imprescindible**: la memoria del diseño es de
32 bits (`logic [31:0] mem[...]`) y `$readmemh` guarda una palabra por cada
valor del fichero. Sin esa opción, objcopy escribe un byte por valor y cada
byte acaba ocupando una palabra completa de la memoria.

Formato correcto del resultado (una palabra de 32 bits por valor, ya en
little-endian, con las direcciones `@` expresadas en palabras):

```
@00000000
3E800093
7D008113
...
@00000408
DEADBEEF
```

Comprueba que la dirección `@` de `.data` coincide con la dirección en bytes
dividida entre 4. Por ejemplo, `0x1020 / 4 = 0x408`.

| Formato                      | Aspecto           | ¿Válido para esta memoria? |
| ---------------------------- | ----------------- | -------------------------- |
| Sin `--verilog-data-width`   | `93 00 80 3E ...` | No (un byte por entrada)   |
| Con `--verilog-data-width=4` | `3E800093 ...`    | Sí                         |

## 5. Paso 3: compilar con Verilator

```bash
verilator --binary -Wall --timing -Isv \
    sv/tb/riscv_tb.sv sv/riscv_pkg.sv sv/alu.sv sv/fetch.sv \
    sv/decoder.sv sv/regfile.sv sv/memory.sv sv/core.sv \
    --top riscv_tb
```

| Opción           | Significado                                                       |
| ---------------- | ----------------------------------------------------------------- |
| `--binary`       | Genera directamente un ejecutable de simulación                   |
| `-Wall`          | Activa todos los avisos de lint (cualquier aviso aborta el build) |
| `--timing`       | Soporta `#delays` y `@(posedge clk)` en el testbench              |
| `-Isv`           | Directorio de búsqueda de ficheros incluidos                      |
| `--top riscv_tb` | Módulo de nivel superior                                          |

Alternativa usando la lista de ficheros:

```bash
verilator --binary -Wall --timing -Isv -f sv/flist.f --top riscv_tb
```

El orden importa: el paquete `riscv_pkg.sv` debe aparecer antes de los
módulos que lo importan. El testbench puede ir en cualquier posición porque
no usa el paquete.

Si todo va bien termina sin avisos y crea el ejecutable
`obj_dir/Vriscv_tb`.

## 6. Paso 4: ejecutar la simulación

```bash
./obj_dir/Vriscv_tb
```

El testbench termina de una de estas formas:

| Salida                         | Significado                                                                                                 |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| `*** PASS ***`                 | El programa escribió `0x900D` en el mailbox y el nº de instrucciones ilegales coincide con `EXPECT_ILLEGAL` |
| `*** FAIL: test N ***`         | El programa escribió `N` (distinto de `0x900D`) en el mailbox                                               |
| `*** FAIL: X ilegales ... ***` | Pasó los tests pero el nº de ilegales no es el esperado                                                     |
| `*** TIMEOUT ... ***`          | Pasaron `MAX_CYCLES` ciclos sin escribir en el mailbox                                                      |

El mailbox es la dirección de byte `0x10000`. Para terminar el programa
con éxito hay que escribir allí:

```asm
    li  t0, 0x10000
    li  t1, 0x900D
    sw  t1, 0(t0)
```

Esto solo funcionará cuando estén implementados `store` y el puerto B de datos.

Se pueden cambiar los parámetros del testbench sin editarlo:

```bash
verilator --binary -Wall --timing -Isv ... --top riscv_tb \
    -GHEX_FILE=\"hex/otro.hex\" -GMAX_CYCLES=50000 -GEXPECT_ILLEGAL=2
```

## 7. Ver formas de onda (opcional)

Añade `--trace` al compilar y, en el testbench, un `initial` con
`$dumpfile("dump.vcd"); $dumpvars(0, riscv_tb);`. Después:

```bash
gtkwave dump.vcd
```

## 8. Script de todo el flujo

Guárdalo como `run.sh` (con `chmod +x run.sh`):

```bash
#!/usr/bin/env bash
set -euo pipefail

PREFIX=riscv64-elf-
SRC=${1:-program.s}

mkdir -p hex
${PREFIX}gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0x0 "$SRC" -o program.elf
${PREFIX}objcopy -O verilog --verilog-data-width=4 program.elf hex/program.hex

verilator --binary -Wall --timing -Isv -f sv/flist.f --top riscv_tb
./obj_dir/Vriscv_tb
```

## 9. Problemas frecuentes

| Síntoma                                                             | Causa probable                                                                 | Solución                                                                  |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| `%Error: Exiting due to N warning(s)`                               | `-Wall` convierte los avisos en errores                                        | Corregir el aviso, o `/* verilator lint_off CODIGO */` si es intencionado |
| El programa ejecuta basura o instrucciones ilegales desde el inicio | `.hex` generado sin `--verilog-data-width=4`                                   | Regenerar el `.hex` (paso 2)                                              |
| `$readmemh: Standard inputs ... file not found`                     | Se lanza desde otro directorio                                                 | Ejecutar desde la raíz del proyecto                                       |
| Avisos de instrucción ilegal tras la última instrucción             | La memoria vale 0 después del programa y el opcode 0 es ilegal                 | Normal si el programa no termina escribiendo en el mailbox                |
| `TIMEOUT`                                                           | El programa no escribe en el mailbox, o el core aún no implementa store/saltos | Completar el core o ajustar el programa                                   |
| `Package/class 'riscv_pkg' not found`                               | El paquete está después de sus usuarios en la lista de ficheros                | Poner `riscv_pkg.sv` antes que los módulos que lo importan                |
| `riscv64-elf-gcc: command not found`                                | Prefijo del toolchain distinto                                                 | Usar `riscv64-unknown-elf-` u otro prefijo instalado                      |

## 10. Limpieza

```bash
rm -rf obj_dir program.elf hex/program.hex
```
