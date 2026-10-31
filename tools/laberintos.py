#!/usr/bin/env python3
"""Los cuatro laberintos dibujados desde la ROM, como los monta el cartucho.

Lo mismo que hacen `desempaqueta_laberinto` (0x09D0) y `pinta_fase` (0x02AB):
  - el mapa de 72 bytes, un bit por casilla: 1 muro, 0 pasillo;
  - los bloques (valor 2), por grupos;
  - y cada casilla con su dibujo y su color (`pon_casilla`, 0x0889):
      0 pasillo  0x120E, 0x11 (negro sobre negro)
      2 bloque   0x120E, 0xC3 (verde oscuro sobre verde claro)
      3 muro     0x1216, 0xFC (blanco sobre verde oscuro)
  - encima, los cubos (0x11E6, amarillo 0xA0, `pinta_cubos`) y las llamas
    grandes (0x12AE, rojo 0x60, `mueve_llamas`), en 16x16 (`pinta_objeto`).
La pantalla es un mapa de bits (nombres de 0 a 255): la casilla (x, y) tiene el
patron en y * 256 + (x + 1) * 8 y el color 0x2000 mas alla; la columna 0 es el
borde.

Uso: laberintos.py <salida_dir> [grabacion.bin cuadro1 cuadro2 cuadro3 cuadro4]
     con la grabacion de openMSX (tools/omsx_graba.tcl), coteja cada uno con
     la VRAM del cuadro dado: patrones y colores de las 24 x 24 casillas.
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(0, os.path.join(os.path.dirname(AQUI), "tests"))
import vdp                                   # noqa: E402
from test_listado import laberinto, LABERINTOS   # noqa: E402

REGS = bytes([0x02, 0xE2, 0x0E, 0xFF, 0x03, 0x76, 0x03, 0x01])   # 0x1651


def casilla(vram, rom, x, y, dibujo, color):
    a = y * 256 + (x + 1) * 8
    vram[a:a + 8] = rom[dibujo:dibujo + 8]
    vram[0x2000 + a:0x2000 + a + 8] = bytes([color]) * 8


def objeto(vram, rom, x, y, dibujo, color):
    """`pinta_objeto` (0x0BFA): arriba izq, abajo izq, arriba der, abajo der."""
    for k, (dx, dy) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
        casilla(vram, rom, x + dx, y + dy, dibujo + 8 * k, color)


def pinta(rom, a):
    vram = bytearray(0x4000)
    vram[0x3800:0x3B00] = bytes(range(256)) * 3
    vram[0x3B00] = 0xD0
    lab = laberinto(rom, a)
    valor = [[3 if b else 0 for b in fila] for fila in lab["mapa"]]
    for g in lab["grupos"]:
        for x, y in g:
            for dx in (0, 1):
                for dy in (0, 1):
                    valor[y + dy][x + dx] = 2
    for y in range(24):
        for x in range(24):
            v = valor[y][x]
            dib, col = {0: (0x120E, 0x11), 2: (0x120E, 0xC3), 3: (0x1216, 0xFC)}[v]
            casilla(vram, rom, x, y, dib, col)
    for x, y in lab["cubos"]:
        objeto(vram, rom, x, y, 0x11E6, 0xA0)
    for x, y in lab["llamas"]:
        if x:
            objeto(vram, rom, x, y, 0x12AE, 0x60)
    return vram, lab


def coteja(mia, suya):
    """Bytes distintos en los patrones y colores de las 24 x 24 casillas."""
    dif = []
    for y in range(24):
        for x in range(1, 25):
            a = y * 256 + x * 8
            for t in (0, 0x2000):
                for i in range(8):
                    if mia[t + a + i] != suya[t + a + i]:
                        dif.append((x - 1, y, "color" if t else "patron"))
    return dif


def main(argv):
    rom = open(os.path.join(os.path.dirname(AQUI), "sparkie.rom"), "rb").read()[:0x2000]
    salida = argv[0]
    os.makedirs(salida, exist_ok=True)
    vrams = []
    for k, a in enumerate(LABERINTOS):
        vram, lab = pinta(rom, a)
        vrams.append(vram)
        im = vdp.imagen(bytes(vram), REGS, escala=2).crop((0, 0, 200 * 2, 192 * 2))
        im.save(os.path.join(salida, "laberinto_%d.png" % (k + 1)))
    if len(argv) > 1:
        cs = list(vdp.cuadros(argv[1]))
        for k, n in enumerate(argv[2:6]):
            suya = cs[int(n)]["vram"]
            dif = coteja(vrams[k], suya)
            casillas = sorted(set((x, y) for x, y, _ in dif))
            print("laberinto %d contra el cuadro %s: %d bytes distintos en %d casillas %s"
                  % (k + 1, n, len(dif), len(casillas), casillas[:12]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
