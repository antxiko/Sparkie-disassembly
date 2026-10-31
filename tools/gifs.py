#!/usr/bin/env python3
"""Los GIF de la web: tramos de las grabaciones de openMSX (tools/guiones/*.tcl,
grabados con tools/lanza_graba.ps1 -bp2 0x11CC), pintados con tools/vdp.py.

Uso: gifs.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402

# (fichero, grabacion, desde, hasta): los cuadros los dice tools/eventos (ver
# la pagina EN-EL-EMULADOR): el cambio de modo, de estado de Sparkie, etc.
TRAMOS = [
    ("sony_y_menu.gif", "atraccion", 0, 121),
    ("demostracion.gif", "atraccion", 121, 380),
    ("cubo_y_ola.gif", "cubo", 45, 330),
    ("carga_y_muerte.gif", "cubo", 330, 760),
    ("disparos.gif", "dispara", 556, 1000),
    ("bloques_que_arden.gif", "dispara", 1994, 2300),
    ("premio.gif", "premio", 45, 300),
    ("time_over.gif", "tiempo", 120, 560),
    ("game_over.gif", "gameover", 780, 1190),
]


def main(salida):
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for fichero, grab, desde, hasta in TRAMOS:
        n, s = vdp.gif(os.path.join(raiz, "work", grab + ".bin"),
                       os.path.join(salida, fichero), desde, hasta, cada=2, tope_ms=4000)
        print("%-24s %4d imagenes, %5.1f s, %7d bytes" % (
            fichero, n, s, os.path.getsize(os.path.join(salida, fichero))))


if __name__ == "__main__":
    main(sys.argv[1])
