# Por dentro

## Rehacer la ROM

`make verify` ensambla `src/sparkie.asm` con pasmo y sale la ROM de 8 KB
**byte a byte**; repetida cuatro veces, da el volcado de 32 KB. `make sanity`
comprueba lo que el reensamblado no cubre: que ningún byte declarado como
datos se lea como código, y que los 8.192 estén explicados, como código
trazado o como datos con nombre. `make test` pasa los tests. La ROM no está en
el repositorio: hace falta ponerla en la raíz como `sparkie.rom` (el volcado de
GoodMSX, `[!]`, sha1 `b9c98b80...`).

| | bytes |
|---|---|
| código trazado | 5.039 |
| datos con nombre | 3.153 |
| sin explicar | 0 |

El listado lleva 1.114 comentarios en 2.736 instrucciones (40,7 %), 393
rutinas y etiquetas, ninguna por debajo del 10 % comentada, y ninguna rutina
llamada sin nombre.

## La página 0, sin la BIOS

INIT (`0x00CF`) corta las interrupciones, pone el modo 1, la pila en
`0xE7FF`, calla el PSG, monta la pantalla de Sony y borra 1.872 bytes de RAM
desde `0xE000`. A partir de ahí todo es del cartucho:

| | Qué hace |
|---|---|
| RST 10h | HL = HL + 2 * A: el elemento A de una tabla de palabras |
| RST 18h | la dirección DE al VDP |
| RST 20h | B bytes de HL a la VRAM |
| RST 30h | DE = la posición del objeto de IX |
| 0x0038 | la interrupción |

## La interrupción

Una vez por cuadro (`interrupcion`, 0x0038): los cuatro bloques de sonido y,
si Sparkie está vivo, la cuenta de la fase y el juego, repartido en cuadros
alternos. En los **impares**, Sparkie, los disparos, su carga y tres tandas de
enemigos; en los **pares**, la tanda 1, los cubos, las llamas, los bloques que
arden, el premio y los disparos borrados. El bucle principal (0x0134) solo
cuenta enemigos y casillas sin pintar, y atiende la muerte y el fin de la
fase.

## La pantalla, un mapa de bits

SCREEN 2 con la tabla de nombres puesta de 0 a 255 en los tres tercios
(0x11A4): cada casilla de 8x8 tiene su patrón propio, y dibujar es escribir
patrones y colores en su sitio. Una casilla son 8 bytes de patrón y 8 de color
(`pinta_casilla`, 0x0BCF); un objeto de 16x16, cuatro (`pinta_objeto`,
0x0BFA). Los personajes son sprites de 16x16; los patrones, 0x1800, cada
figura en cuatro sentidos.

## La RAM

| | |
|---|---|
| `0xE001` | el jugador en curso (1 el primero, 0 el segundo) |
| `0xE002`-`0xE00D` | Sparkie: posición, estado (bit 3 vivo, bits 0-1 la carga, nibble alto el sentido), su sprite |
| `0xE00E` | el mando: bits 7-4 arriba, abajo, izquierda, derecha; bit 3 el botón |
| `0xE00F`-`0xE03A` | la ola (hasta 20 casillas) y su punta |
| `0xE03B`-`0xE042` | los cuatro disparos |
| `0xE044` | cuántos enemigos hay |
| `0xE047` | los cuadros de la fase (2.048: más deprisa; 4.096: TIME OVER) |
| `0xE04E`-`0xE059` | cuántos enemigos hay en cada franja de dos filas |
| `0xE06F` | el récord |
| `0xE0A2`, `0xE0A3` | la opción del menú y el modo (demostración, partida acabada) |
| `0xE0B4`-`0xE0D3` | los cuatro bloques de sonido |
| `0xE12C`-`0xE1BB` | el laberinto: 24 filas de 6 bytes, dos bits por casilla |
| `0xE1BC`, `0xE1C8` | los tres cubos y las cinco llamas, con sus estados |
| `0xE1DC`-`0xE1F5` | los 13 enemigos; su estado, 0x20 bytes más allá |
| `0xE21C` | el premio |
| `0xE220`-`0xE247` | las cuatro listas de bloques que arden |
| `0xE24D`, `0xE24F`, `0xE250` | la puntuación, las vidas y la fase |
| `0xE258`, `0xE384` | la partida guardada de cada jugador (298 bytes) |
| `0xE4B0` | la tabla de sprites que se sube a la VRAM |

## El motor de sonido

Cuatro bloques de 8 bytes: la música en el canal A, el zumbido y los disparos
en el B, los efectos en el C y el ruido con el volumen del A. Cada nota es el
tono bajo, un byte con la duración (nibble alto), el bit "viene volumen" y el
tono alto, y el volumen si viene; con el bit 4 del volumen, el periodo de la
envolvente. `0x00` acaba un efecto (y vuelve el zumbido), `0xFF` calla el
bloque y `0xFE` pasa a la frase siguiente de la música, que se copia a
`0xE5DC`.

## Las herramientas

| | |
|---|---|
| `tools/z80trace.py`, `tools/mkasm.py` | el trazado y el listado |
| `tools/presupuesto.py`, `tools/densidad.py` | los bytes explicados y los comentarios |
| `tools/omsx_graba.tcl`, `tools/lanza_graba.ps1` | graban el cartucho en openMSX, cuadro a cuadro: VRAM, registros, RAM, PSG y tiempo |
| `tools/guiones/*.tcl` | lo que se pulsa (y los pokes) en cada grabación |
| `tools/vdp.py`, `tools/gifs.py` | el TMS9918 en Python y los GIF |
| `tools/laberintos.py` | los laberintos desde la ROM, y su cotejo con openMSX |
| `tools/personajes.py`, `tools/pantallas.py` | los sprites y las pantallas, ejecutando el cartucho con `tools/z80run.py`, y su cotejo |
| `tools/objetos.py` | los objetos del laberinto con sus colores |
| `tools/musica.py` | las músicas, ejecutando su motor |

## Los cotejos

| | Resultado |
|---|---|
| los cuatro laberintos contra la VRAM de openMSX | 0 bytes (3 y 4: las cuatro casillas del enemigo que pinta) |
| la fase 5 contra el laberinto 1 | 0 bytes |
| los patrones de los sprites | 0 de 2.048 |
| la pantalla de Sony y el menú | 0 de 16.384, registros iguales |
| la música de la fase y el aviso | 167 y 233 cuadros seguidos iguales |

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie (al menos seis instrucciones
desde una etiqueta hasta su `ret` o su salto sin condición, sin mirar
las direcciones). De los otros 62, **ninguno** comparte un solo
bloque con este.

La matriz entera, los 63 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
