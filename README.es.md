# Sparkie - desensamblado comentado

*(Also [in English](README.md).)*

El desensamblado comentado de **Sparkie** (Konami para Sony, 1983) para MSX: una ROM de 8 KB escrita para la página 0, que no usa la BIOS.

- **100 %** del binario explicado: 5.039 bytes de código y 3.153 de datos con nombre, ni un byte sin asignar.
- **40,7 %** del listado comentado, 393 rutinas y etiquetas, ninguna por debajo del 10 % de comentarios.
- El listado se reensambla en la ROM original **byte a byte** (y cuatro veces seguida da el volcado de 32 KB).
- Los cuatro laberintos, los personajes, la pantalla de Sony y el menú salen de los bytes del cartucho, cotejados con openMSX byte a byte; la partida, jugada en GIF; las dos músicas, de su propio motor de sonido; y un fallo del marcador a partir del millón de puntos.

La web: <https://antxiko.github.io/Sparkie-disassembly/es/>
(en inglés: <https://antxiko.github.io/Sparkie-disassembly/>).

## Reproducirlo

La imagen del cartucho no se distribuye. Pon la tuya en la raíz como `sparkie.rom` (sha256 `fc4a86f6...`) y ejecuta `make`. El detalle, en [POR DENTRO](docs/es/POR-DENTRO.md).

## Legal

El juego es de Konami, de Sony y de sus titulares. La licencia de `LICENSE` cubre solo las herramientas, los comentarios, el análisis y la documentación de aquí. Mira [AVISO-LEGAL.md](AVISO-LEGAL.md).
