#!/usr/bin/env python3
"""La pantalla de Sony y el menu, EJECUTANDO el cartucho con tools/z80run.py:

  - Sony: `pantalla_de_sony` (0x10EA) hasta la pausa (0x1138), con los
    registros de 0x1649 (SCREEN 1);
  - el menu: lo que sigue, hasta que `pon_menu` (0x020C) empieza a esperar la
    tecla (0x0222), con los registros de 0x1651 (SCREEN 2).
Cada una se coteja byte a byte con la VRAM de openMSX del cuadro que se diga.

Uso: pantallas.py <dir> [grabacion.bin cuadro_sony cuadro_menu]
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from z80run import Z80      # noqa: E402

RAIZ = os.path.dirname(AQUI)


class C(Z80):
    def _escribir(self, d, v):
        if (d & 0xFFFF) >= 0x2000:
            self.mem[d & 0xFFFF] = v & 0xFF


def main(argv):
    rom = open(os.path.join(RAIZ, "sparkie.rom"), "rb").read()[:0x2000]
    z = C()
    z.carga(rom, 0)
    z.sp = 0xE7FF
    z.corre_hasta(0x00CF, 0x1138, tope=10_000_000)
    sony = (bytes(z.vdp.vram), rom[0x1649:0x1651])
    z.corre_hasta(0x1138, 0x0222, tope=80_000_000)
    menu = (bytes(z.vdp.vram), rom[0x1651:0x1659])
    for nom, (v, r) in (("sony", sony), ("menu", menu)):
        vdp.imagen(v, r, 2).save(os.path.join(argv[0], "%s.png" % nom))
    if len(argv) > 1:
        cs = list(vdp.cuadros(argv[1]))
        for nom, (v, r), n in (("sony", sony, argv[2]), ("menu", menu, argv[3])):
            suya = cs[int(n)]
            dif = sum(1 for a, b in zip(v, suya["vram"]) if a != b)
            print("%s contra el cuadro %s: %d bytes distintos de 16384, registros %s"
                  % (nom, n, dif, "iguales" if bytes(r) == suya["regs"] else "DISTINTOS"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
