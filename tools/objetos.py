#!/usr/bin/env python3
"""Los objetos del laberinto (dibujos de 8x8 de la ROM, en 16x16 como los pinta
`pinta_objeto`, 0x0BFA), con los colores y el ritmo del cartucho:

  cubo          0x11E6, amarillo 0xA0; si a Sparkie le falta carga, magenta 0xD0 y
                blanco 0xF0 alternando cada 4 cuadros (`pinta_cubos`, 0x092B)
  llamas        0x1326 pequena y 0x12AE mediana en gris 0xE0, grande 0x12AE en
                rojo 0x60 (`mueve_llamas`, 0x05B1)
  premio        0x1346, 0x1356 en blanco y 0x134E, 0x12CE en amarillo (0x05F8)
  bloque        0x120E en 0xC3; el que arde alterna 0x6A y 0xA6 cada 16 cuadros
                (`bloques_parpadean`, 0x07E8)
  ola           0x1EFB, en 0xF5, una por sentido (arriba, abajo, izquierda, derecha)
  disparo       0x1F7B, en 0xF0, igual

Uso: objetos.py <salida.gif>   (un paso cada 4 cuadros, 32 cuadros en total)
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp       # noqa: E402

ROM = open(os.path.join(os.path.dirname(AQUI), "sparkie.rom"), "rb").read()[:0x2000]
ORDEN = ((0, 0), (0, 8), (8, 0), (8, 8))    # arriba izq, abajo izq, arriba der, abajo der


def pinta(trozos):
    """trozos: [(dibujo de 8 bytes, color, ox, oy)] -> imagen de 16x16."""
    from PIL import Image
    im = Image.new("RGB", (16, 16))
    for dib, col, ox, oy in trozos:
        for y in range(8):
            b = ROM[dib + y]
            for x in range(8):
                v = (col >> 4) if b & (0x80 >> x) else (col & 15)
                im.putpixel((ox + x, oy + y), vdp.PALETA[v])
    return im


def objeto(dib, col):
    return pinta([(dib + 8 * k, col, ox, oy) for k, (ox, oy) in enumerate(ORDEN)])


def liso(dib, col):
    return pinta([(dib, col, ox, oy) for ox, oy in ORDEN])


def main(salida):
    from PIL import Image
    imgs = []
    for paso in range(8):
        t = paso * 4
        fila = [objeto(0x11E6, 0xA0), objeto(0x11E6, 0xF0 if t & 4 else 0xD0),
                objeto(0x1326, 0xE0), objeto(0x12AE, 0xE0), objeto(0x12AE, 0x60),
                pinta([(0x1346, 0xF0, 0, 0), (0x1356, 0xF0, 8, 0),
                       (0x134E, 0xA0, 0, 8), (0x12CE, 0xA0, 8, 8)]),
                liso(0x120E, 0xC3), liso(0x120E, 0xA6 if (t // 16) & 1 else 0x6A)]
        fila += [objeto(0x1EFB + 32 * k, 0xF5) for k in range(4)]
        fila += [objeto(0x1F7B + 32 * k, 0xF0) for k in range(4)]
        im = Image.new("RGB", (len(fila) * 22 + 4, 22))
        for i, f in enumerate(fila):
            im.paste(f, (4 + i * 22, 3))
        imgs.append(im.resize((im.width * 3, im.height * 3), Image.NEAREST))
    imgs[0].save(salida, save_all=True, append_images=imgs[1:], duration=[67] * 8, loop=0)
    print(salida)


if __name__ == "__main__":
    main(sys.argv[1])
