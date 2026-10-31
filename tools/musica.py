#!/usr/bin/env python3
"""Las musicas de Sparkie, EJECUTANDO su propio motor de sonido.

No se reescribe el motor: tools/z80run.py ejecuta el codigo del cartucho. Este
juego no llama a la BIOS (escribe en el PSG con `out (0xA0)` / `out (0xA1)`),
asi que no hace falta trampa ninguna: los 8 KB van en 0x0000, como los ve el
programa, y cada escritura del PSG se apunta.

Cada pieza:
  - `silencio` (0x0F96), como hace el juego antes de empezarla;
  - la peticion: `musica_de_fase` (0x10A3) o `musica_de_aviso` (0x10AA, con
    HL = 0x1CDF);
  - y cada cuadro, lo mismo que la interrupcion (0x0047): `paso_de_sonido`
    (0x0FE9) con HL en los cuatro bloques, 0xE0B5, 0xE0BD, 0xE0C5 y 0xE0CD.
La musica de la fase vuelve a empezar (la lista acaba en 0x0000): se ve cuando
la RAM del sonido se repite, y el MP3 da una vuelta mas y se apaga.

Uso:  musica.py registros fase|aviso [cuadros]  |  todas docs/audio
"""
import hashlib
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import motor_musica as mm            # noqa: E402
from z80run import Z80                # noqa: E402

RAIZ = os.path.dirname(AQUI)
ROM = os.path.join(RAIZ, "sparkie.rom")
HZ = 60
BLOQUES = (0xE0B5, 0xE0BD, 0xE0C5, 0xE0CD)

# (clave, fichero, titulo es, titulo en, peticion)
PIEZAS = [
    ("fase", "musica_fase.mp3", "La música de la fase", "The stage tune",
     "`musica_de_fase` (0x10A3), al montar cada fase"),
    ("aviso", "musica_aviso.mp3", "El aviso de la carga baja", "The low-charge warning",
     "`musica_de_aviso` (0x10AA) con la lista de 0x1CDF, cuando a Sparkie le falta carga"),
]


class Cartucho(Z80):
    def __init__(self, rom):
        super().__init__()
        self.escrituras = []
        self.maq = mm.MaquinaMusica(self.escrituras)
        self.vdp = self.maq.vdp
        self.carga(rom[:0x2000], 0)

    def _escribir(self, d, v):
        if (d & 0xFFFF) < 0x2000:
            return                        # la ROM no se escribe
        self.mem[d & 0xFFFF] = v & 0xFF


def arranca(rom, clave):
    z = Cartucho(rom)
    z.sp = 0xE7FF
    z.maq.psg[7] = 0xB8
    z.corre(0x0F96)
    if clave == "fase":
        z.corre(0x10A3)
    else:
        z.hl = 0x1CDF
        z.corre(0x10AA)
    return z


def cuadro(z):
    z.escrituras.clear()
    for b in BLOQUES:
        z.hl = b
        z.corre(0x0FE9)
    return list(z.escrituras)


def ejecuta(rom, clave, maximo=HZ * 300):
    """(cuadros, vuelta): las escrituras de cada cuadro y el cuadro al que vuelve."""
    z = arranca(rom, clave)
    previas = list(z.escrituras)
    cuadros, vistos = [], {}
    for n in range(maximo):
        escr = cuadro(z)
        if n == 0:
            escr = previas + escr
        cuadros.append(escr)
        estado = bytes(z.mem[0xE0B4:0xE0D4]) + bytes(z.mem[0xE5DC:0xE612])
        h = hashlib.sha1(estado).digest()
        if h in vistos:
            return cuadros, vistos[h]
        vistos[h] = n + 1
        if z.mem[0xE0B5] == 0 and all(z.mem[b] == 0 for b in BLOQUES[2:]) and n > 10:
            return cuadros, None          # la musica se ha callado
    return cuadros, None


def main(argv):
    rom = open(ROM, "rb").read()
    if argv[0] == "registros":
        cuadros, vuelta = ejecuta(rom, argv[1], int(argv[2]) if len(argv) > 2 else HZ * 300)
        for i, escr in enumerate(cuadros):
            print("%5d %s" % (i, " ".join("%X=%02X" % rv for rv in escr)))
        print("cuadros: %d, vuelve al %s" % (len(cuadros), vuelta))
    elif argv[0] == "todas":
        os.makedirs(argv[1], exist_ok=True)
        for clave, fichero, *_ in PIEZAS:
            cuadros, vuelta = ejecuta(rom, clave)
            todo, fundido = mm.desarrolla(cuadros, vuelta, HZ)
            mm.a_mp3(mm.sintetiza(todo, HZ), os.path.join(argv[1], fichero), fundido, HZ)
            print("%s: %d cuadros (%.1f s), vuelve al %s -> %s" % (
                clave, len(cuadros), len(cuadros) / HZ, vuelta, fichero))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
