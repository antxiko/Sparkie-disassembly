"""Lo que se afirma del cartucho, comprobado contra sus bytes.

Corre con el cartucho delante y sin el: cuando no esta, la imagen se rehace
desde las filas defb/defw del listado, que si viaja con el repositorio. Sin el
cartucho solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "sparkie.rom")
ASM = os.path.join(RAIZ, "src", "sparkie.asm")
NOTAS = os.path.join(RAIZ, "src", "sparkie.notes")
ORG = 0x0000
TAM = 8192

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")

# La fuente de 0x14DE, letra a letra (las cinco piezas del logotipo de Konami
# no tienen letra).
FUENTE = "© KONAMI0123456789BCDEFGHJLPRSTUVWY-/\""


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()[:TAM]
    return imagen_desde_el_listado()


def texto(rom, a):
    """Un rotulo de 0x0288: color, X, Y, longitud y las letras."""
    n = rom[a + 3]
    return "".join(FUENTE[b] if b < len(FUENTE) else "?" for b in rom[a + 4:a + 4 + n])


def laberinto(rom, a):
    """El laberinto de la ROM: el mapa de 24x24, los objetos, los bloques y
    donde acaba (lo mismo que hace 0x09D0)."""
    mapa = []
    for f in range(24):
        bits = (rom[a + 3 * f] << 16) | (rom[a + 3 * f + 1] << 8) | rom[a + 3 * f + 2]
        mapa.append([(bits >> (23 - c)) & 1 for c in range(24)])
    p = a + 72
    cubos = [(rom[p + 2 * i], rom[p + 2 * i + 1]) for i in range(3)]
    llamas = [(rom[p + 6 + 2 * i], rom[p + 7 + 2 * i]) for i in range(5)]
    enemigos = [(rom[p + 16 + 2 * i], rom[p + 17 + 2 * i]) for i in range(9)]
    premio = (rom[p + 34], rom[p + 35])
    p += 36
    grupos, grupo = [], []
    while True:
        x = rom[p]
        p += 1
        if x == 0:
            grupos.append(grupo)
            grupo = []
            x = rom[p]
            p += 1
            if x == 0:
                break
        grupo.append((x, rom[p]))
        p += 1
    return dict(mapa=mapa, cubos=cubos, llamas=llamas, enemigos=enemigos,
                premio=premio, grupos=[g for g in grupos if g], fin=p)


LABERINTOS = (0x19E2, 0x1A6A, 0x1AF5, 0x1B91)


class Cabecera(unittest.TestCase):
    def test_ab_e_init_en_la_pagina_0(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(rom[2] | (rom[3] << 8), 0x00CF)

    def test_solo_usa_init(self):
        self.assertEqual(lee()[4:16], b"\x00" * 12)

    def test_el_volcado_son_cuatro_copias_de_8_kb(self):
        """Con el cartucho delante, sus cuatro cuartos; sin el, el listado
        tiene que dar los 8 KB enteros."""
        if os.path.exists(ROM):
            with open(ROM, "rb") as f:
                d = f.read()
            self.assertEqual(len(d), 32768)
            for k in range(1, 4):
                self.assertEqual(d[k * TAM:(k + 1) * TAM], d[:TAM])
        self.assertEqual(len(lee()), TAM)

    def test_la_interrupcion_es_suya(self):
        """0x0038 empieza guardando registros, no es un hueco."""
        self.assertEqual(lee()[0x38], 0xF5)        # push af


class Textos(unittest.TestCase):
    def test_los_dos_carteles(self):
        rom = lee()
        self.assertEqual(texto(rom, 0x01FE), "TIME  OVER")
        self.assertEqual(texto(rom, 0x0E22), "GAME  OVER")

    def test_el_menu(self):
        rom = lee()
        self.assertEqual(texto(rom, 0x1922), "SPARKIE")
        self.assertEqual(texto(rom, 0x1952), '"1" KEY 1 PLAYER  W/ JOYSTICK')
        self.assertEqual(texto(rom, 0x19B5), '"4" KEY 2 PLAYERS W/ KEYBOARD')
        self.assertEqual(texto(rom, 0x19D6), "PLAYER 1")

    def test_el_marcador(self):
        rom = lee()
        a, vistos = 0x0380, []
        for _ in range(8):
            vistos.append(texto(rom, a))
            a += 4 + rom[a + 3]
        self.assertEqual(vistos, ["1P", "HIGH", "REST", "STAGE", "00", "00", "2P", "00"])
        self.assertEqual(a, 0x03B7)


class Laberintos(unittest.TestCase):
    def test_cuatro_seguidos_que_acaban_en_la_musica(self):
        rom = lee()
        for k, a in enumerate(LABERINTOS):
            fin = laberinto(rom, a)["fin"]
            siguiente = LABERINTOS[k + 1] if k < 3 else 0x1C17
            self.assertEqual(fin, siguiente, hex(a))

    def test_el_borde_es_muro(self):
        rom = lee()
        for a in LABERINTOS:
            m = laberinto(rom, a)["mapa"]
            self.assertEqual(m[0], [1] * 24)
            self.assertEqual(m[23], [1] * 24)
            self.assertTrue(all(f[0] and f[23] for f in m))

    def cuatro(self, lab, x, y):
        return [lab["mapa"][y + dy][x + dx] for dy in (0, 1) for dx in (0, 1)]

    def test_los_cubos_tapan_muro_y_el_premio_y_las_llamas_pasillo(self):
        """Los tres cubos estan sobre cuatro casillas de muro, que se abren
        al cogerlos (0x0444); el premio y las llamas, sobre pasillo."""
        rom = lee()
        for a in LABERINTOS:
            lab = laberinto(rom, a)
            for x, y in lab["cubos"]:
                self.assertEqual(self.cuatro(lab, x, y), [1] * 4, hex(a))
            for x, y in [lab["premio"]] + [c for c in lab["llamas"] if c[0]]:
                self.assertEqual(self.cuatro(lab, x, y), [0] * 4, hex(a))

    def test_la_tabla_de_0x0aa9(self):
        """0x0AA9 carga las cuatro direcciones con `ld hl,nn`."""
        rom = lee()
        for op, a in zip((0x0AAC, 0x0AB1, 0x0AB6, 0x0ABA), LABERINTOS):
            self.assertEqual(rom[op], 0x21)
            self.assertEqual(rom[op + 1] | (rom[op + 2] << 8), a)


class Sonido(unittest.TestCase):
    def test_la_musica_de_la_fase_vuelve_a_empezar(self):
        rom = lee()
        lista = [rom[0x1C8E + 2 * i] | (rom[0x1C8F + 2 * i] << 8) for i in range(5)]
        self.assertEqual(lista, [0x1C17, 0x1C3C, 0x1C17, 0x1C61, 0])

    def test_el_aviso_se_acaba(self):
        rom = lee()
        lista = [rom[0x1CDF + 2 * i] | (rom[0x1CE0 + 2 * i] << 8) for i in range(8)]
        self.assertEqual(lista[-1], 0xFFFF)

    def test_cada_frase_cabe_hasta_la_siguiente(self):
        rom = lee()
        for a, sig in ((0x1C17, 0x1C3C), (0x1C3C, 0x1C61), (0x1C61, 0x1C8E),
                       (0x1C98, 0x1CBB), (0x1CBB, 0x1CDA), (0x1CDA, 0x1CDF)):
            self.assertEqual(a + 1 + rom[a], sig)
            self.assertEqual(rom[sig - 1], 0xFE)


class ElListado(unittest.TestCase):
    def test_densidad_y_flojas(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertGreaterEqual(int(m.group(2)) * 100, 40 * int(m.group(1)))
        self.assertIn("---- 0 rutinas por debajo del 10 %", salida)

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_cada_comentario_en_su_instruccion(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "valida_c.py"), ASM, NOTAS],
            capture_output=True, text=True, check=True).stdout
        self.assertIn("0 fuera de sitio, 0 repetidos", salida)


if __name__ == "__main__":
    unittest.main()
