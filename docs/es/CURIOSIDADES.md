# Curiosidades

## Un fallo: el marcador se rompe al pasar del millón

Los puntos van por centenas y el marcador pinta cuatro cifras
(`pinta_cifras`, 0x1846). Con **10.000 centenas o más** -un millón de puntos-
la conversión da una quinta cifra, y la segunda pasada (0x185A) convierte
`HL = 0xE249`, **una dirección de la RAM**, en vez de la puntuación. Ejecutando
la rutina del cartucho con 10.000, 10.050 y 12.345 centenas, las tres veces
pinta lo mismo: **7929**. El récord, que usa la misma rutina, igual.

## La pantalla de Sony está hecha de código

El arranque pone SCREEN 1 y copia **2.048 bytes desde `0x11DE`** como tabla de
letras (`pantalla_de_sony`, 0x10EA). Ese trozo de la ROM son los dibujos del
juego, la fuente, tablas y textos... y **594 bytes de código**. La pantalla solo nombra 57 de esas 256
letras, y los dibujos que necesita están metidos **entre las rutinas**: los
triángulos de la plataforma de "HIT BIT" son dieciséis bytes en `0x13DE`, justo
después del `ret` de 0x13DC; otros en `0x1426`, `0x145E` y `0x149E`, entre
tablas del juego. Y la tabla de colores, de 32 bytes desde `0x1636`, lee los
trece últimos de las dos tablas de registros del VDP que van detrás.

## Ocho kilobytes en la página 0

El volcado son 32 KB, pero son **los mismos 8 KB cuatro veces**: el cartucho no
decodifica las líneas de dirección altas y se ve igual en toda la memoria. Y el
programa está escrito para la **página 0**, donde vive la BIOS: la cabecera da
INIT en `0x00CF`, y la BIOS lo llama con CALSLT, que pone el cartucho en la
página de la dirección a la que salta. Desde ahí **no vuelve a la BIOS
nunca**: sus RST (0x0010-0x0030) son suyos, la interrupción de `0x0038`
también, y el VDP, el PSG y el teclado se manejan con OUT e IN.

## El enemigo que pinta

El enemigo de la tanda 8 (el magenta, uno por laberinto en el 3 y el 4)
**pinta de azul las casillas que pisa** mientras tiene la vida entera
(`siguiente_enemigo`, 0x06EA), igual que Sparkie: le ayuda a acabar la fase.
Se ve al cotejar los laberintos con openMSX: son las únicas cuatro casillas
distintas, las de su salida, que pinta en su primer paso.

## La cruz partida en dos

Los bloques que arden se copian a cuatro listas de diez bytes, cinco bloques
como mucho (0x0A3D). El laberinto 4 trae un grupo de nueve: la copia lo parte
en la cruz del centro y el rombo de la derecha, que arden por separado.

## TIME OVER también paga

Al llegar a 4.096 cuadros sale TIME OVER, pero la fase se acaba por el mismo
camino que las demás (`fin_de_fase`, 0x01A3): con el premio de las casillas
pintadas, contadas en esa misma vuelta del bucle.

## Restos

- **RST 28h** (`0x0028`): `rst 18h / ld a,c`, que caería en el relleno de
  `0x002A`. Ninguna instrucción hace RST 28h.
- **`dec (ix+20h)`** en `0x071E`, detrás de un `jp`: no salta nadie ahí.
- **`0x0A73`**: cuatro bytes iguales a la salida de Sparkie de `0x141A` (X
  0x28, Y 0xB0, estado 0x1F), que nadie lee.
- **Los patrones de sprite 0xB4-0xC3**: en la vuelta 3 de la carga de figuras,
  128 bytes se suben tal cual (0x1159). Ningún sprite del juego usa esos
  patrones: el mayor que se pinta, fuera de la cola gastada, es 0xB3.
- **Dibujos sin usar**: el de `0x1206` (a cuadros) y seis triángulos en
  `0x136E`, que solo sube la copia del arranque y la pantalla de Sony no
  nombra.
- **`0x1FFB`**: cinco bytes al final de la ROM, `5B FF FF FF 04`, que no lee
  nadie.
- `disparos_dan` (0x0D24) mira **16** huecos de enemigos, y solo hay 13: los
  tres de más tienen el estado a cero y no cuentan.

## El volcado

El volcado de 32 KB (GoodMSX, `[!]`, sha1 `b9c98b80...`) es el que se usa. Su
primera mitad, 16 KB, es exactamente el volcado que openMSX da por verificado
para este juego (sha1 `e0e8ed63...`).

## Preguntas abiertas

- **Quién lo hizo.** El cartucho no tiene créditos ni la marca oculta que
  Konami puso en cartuchos posteriores.
- **Los cinco bytes de `0x1FFB`**: si son una suma de comprobación o un resto
  de la grabación de la ROM, no se sabe.
