#!/usr/bin/env python3
"""Los personajes de Sparkie, animados como los anima el cartucho.

Los patrones de los sprites salen de EJECUTAR `pantalla_de_sony` (0x10EA) con
tools/z80run.py: es la rutina que sube la explosion y las 14 figuras de 0x1D3B
en sus cuatro sentidos a 0x1800. Se cotejan byte a byte con la VRAM de openMSX.

Cada tipo lleva el patron y el color de la tabla de 0x0B82 (`patron_y_color`);
el sentido suma lo de 0x1498 (arriba 8, abajo 0, izquierda 0x0C, derecha 4); y
cada 8 cuadros el dibujo alterna con el de 16 patrones mas alla (0x0B49), menos
la tanda 1. La cola gastada no alterna: un dibujo por punto de carga (0x0B04).

Uso: personajes.py <salida.gif> [grabacion.bin cuadro]   (con la grabacion, coteja)
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from z80run import Z80      # noqa: E402

RAIZ = os.path.dirname(AQUI)

# (nombre, patron, color, anima): de la tabla de 0x0B82 y de 0x0B04
TIPOS = [
    ("Sparkie", 0x74, 0x08, True),
    ("cola, carga entera", 0x94, 0x0A, True),
    ("cola, carga 2", 0xE4, 0x06, False),
    ("cola, carga 1", 0xD4, 0x06, False),
    ("cola, carga 0", 0xC4, 0x06, False),
    ("tanda 1: la llamita", 0x04, 0x06, False),
    ("tanda 2", 0x34, 0x0B, True),
    ("tanda 4", 0x14, 0x09, True),
    ("tanda 8", 0x54, 0x0D, True),
    ("la explosion", 0x00, 0x06, False),
]
SENTIDOS = (0x08, 0x00, 0x0C, 0x04)        # arriba, abajo, izquierda, derecha


def patrones():
    rom = open(os.path.join(RAIZ, "sparkie.rom"), "rb").read()[:0x2000]

    class C(Z80):
        def _escribir(self, d, v):
            if (d & 0xFFFF) >= 0x2000:
                self.mem[d & 0xFFFF] = v & 0xFF
    z = C()
    z.carga(rom, 0)
    z.sp = 0xE7FF
    z.corre(0x10EA, tope=60_000_000)
    return bytes(z.vdp.vram[0x1800:0x2000])


def figura(pat, n, color):
    """Un sprite de 16x16 (patron n) a una imagen con su color."""
    from PIL import Image
    im = Image.new("RGB", (16, 16), (0, 0, 0))
    for q in range(4):
        ox, oy = (q // 2) * 8, (q % 2) * 8
        for y in range(8):
            b = pat[(n + q) * 8 + y]
            for x in range(8):
                if b & (0x80 >> x):
                    im.putpixel((ox + x, oy + y), vdp.PALETA[color])
    return im


def main(argv):
    from PIL import Image
    pat = patrones()
    if len(argv) > 1:
        suya = list(vdp.cuadros(argv[1]))[int(argv[2])]["vram"][0x1800:0x2000]
        dif = sum(1 for a, b in zip(pat, suya) if a != b)
        print("patrones de los sprites contra openMSX: %d bytes distintos de 2048" % dif)
    esc, celda = 3, 16 * 3 + 12
    ancho = 4 * celda
    cuadros = []
    for paso in range(2):                    # 8 cuadros cada uno
        im = Image.new("RGB", (ancho, len(TIPOS) * celda + 8), (0, 0, 0))
        for f, (nom, base, col, anima) in enumerate(TIPOS):
            for k, s in enumerate(SENTIDOS):
                n = base + (0x10 * paso if anima else 0) + (0 if base == 0 else s)
                fig = figura(pat, n, col).resize((16 * esc, 16 * esc), Image.NEAREST)
                im.paste(fig, (6 + k * celda, f * celda + 6))
        cuadros.append(im)
    cuadros[0].save(argv[0], save_all=True, append_images=cuadros[1:],
                    duration=[133, 133], loop=0)
    print(argv[0])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
