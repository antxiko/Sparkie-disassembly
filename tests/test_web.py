"""La web, comprobada contra el listado: las cifras de la portada y el
barrido de nombres y ficheros de otros juegos de la serie."""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from test_listado import ASM, FILA, TAM      # noqa: E402

DOCS = os.path.join(RAIZ, "docs")

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu",
    "King's Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic", "Goonies", "Knightmare", "Twin Bee",
    "Penguin", "Bomber", "Circus Charlie", "Comic Bakery", "Magical Tree",
    "King Kong", "Vampire Killer", "Q*bert", "Qbert", "Quarth", "Metal Gear",
    "Space Manbow", "Salamander", "Parodius", "Contra", "Usas", "Galious",
    "Goemon", "Hinotori", "Shalom", "Rastan", "Dunk Shot", "Pennant",
    "Game Master", "Synthesizer", "Majutsushi", "Juno First", "Crazy Train",
    "Pooyan",
)

# La seccion del codigo compartido con los otros Konami de la serie los
# nombra a proposito: la escribe pon_en_webs.py, de MSX-disassembly-database.
_COMPARTIDO = re.compile(
    r"(?:^## |<h2[^>]*>)(?:Code shared with other Konami cartridges|"
    r"Código compartido con otros cartuchos de Konami)"
    r".*?(?=^## |<h2|</main>|<footer|\Z)", re.S | re.M)


def lee_texto(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def bytes_de_datos_del_listado():
    """Cuantos bytes salen en filas defb/defw: los DATOS del cartucho."""
    n = 0
    for ln in lee_texto(ASM).splitlines():
        m = FILA.match(ln)
        if not m:
            continue
        toks = [t for t in m.group(2).split(",") if t.strip()]
        n += len(toks) * (1 if m.group(1) == "b" else 2)
    return n


def densidad():
    return subprocess.run(
        [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
        capture_output=True, text=True, check=True).stdout


class LasCifrasDeLaPortada(unittest.TestCase):
    def setUp(self):
        import contenido_web
        self.w = contenido_web

    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(self.w.CODIGO + self.w.DATOS, TAM)

    def test_las_cifras_de_bytes_son_las_de_este_listado(self):
        datos = bytes_de_datos_del_listado()
        self.assertEqual(self.w.DATOS, datos)
        self.assertEqual(self.w.CODIGO, TAM - datos)

    def test_la_densidad_y_las_rutinas_son_las_del_listado(self):
        salida = densidad()
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertEqual(self.w.INSTRUCCIONES, int(m.group(1)))
        self.assertEqual(self.w.COMENTARIOS, int(m.group(2)))
        m = re.search(r"por debajo del 10 %, de (\d+)", salida)
        self.assertEqual(self.w.RUTINAS, int(m.group(1)))

    def test_las_paginas_dicen_las_mismas_cifras(self):
        es = lee_texto(os.path.join(DOCS, "es", "POR-DENTRO.md"))
        en = lee_texto(os.path.join(DOCS, "UNDER-THE-HOOD.md"))
        mil = lambda n, s: f"{n:,}".replace(",", s)   # noqa: E731
        for n in (self.w.CODIGO, self.w.DATOS, self.w.COMENTARIOS, self.w.INSTRUCCIONES):
            self.assertIn(mil(n, "."), es)
            self.assertIn(mil(n, ","), en)
        self.assertIn(self.w.densidad("es") + " %", es)
        self.assertIn(self.w.densidad("en") + "%", en)

    def test_la_ficha_dice_el_volcado(self):
        for idioma in ("es", "en"):
            ficha = " ".join(self.w.PORTADA[idioma]["ficha"])
            self.assertIn(self.w.SHA1[:8], ficha)


class SinNombresDeOtroJuego(unittest.TestCase):
    def _revisa(self, ruta):
        texto = _COMPARTIDO.sub("", lee_texto(ruta))
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, texto, "%s nombra a %s" % (ruta, juego))

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        cabeza = "\n".join(lee_texto(ASM).splitlines()[:30])
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, cabeza)

    def test_la_licencia_y_los_avisos_son_de_este_juego(self):
        for fn in ("LICENSE", "README.md", "README.es.md", "AVISO-LEGAL.md",
                   "LEGAL-NOTICE.md"):
            self._revisa(os.path.join(RAIZ, fn))
            self.assertIn("Sparkie", lee_texto(os.path.join(RAIZ, fn)))

    def test_las_herramientas_no_apuntan_a_otro_juego(self):
        for fn in os.listdir(os.path.join(RAIZ, "tools")):
            if fn.endswith((".py", ".sh", ".tcl", ".ps1")):
                texto = lee_texto(os.path.join(RAIZ, "tools", fn)).lower()
                for rom in re.findall(r"['\"/ ](\w+)\.rom", texto):
                    self.assertEqual(rom, "sparkie", "%s: %s.rom" % (fn, rom))

    def test_la_web_no_nombra_otro_juego(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if fn.endswith((".md", ".html")):
                    self._revisa(os.path.join(raiz, fn))


class LasImagenes(unittest.TestCase):
    def test_estan_todas_las_que_se_nombran(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md"):
                    continue
                texto = lee_texto(os.path.join(raiz, fn))
                for img in re.findall(r"\]\(((?:\.\./)?imagenes/[^)]+)\)", texto):
                    self.assertTrue(os.path.exists(os.path.normpath(os.path.join(raiz, img))),
                                    "%s: falta %s" % (fn, img))

    def test_los_dos_idiomas_tienen_las_mismas_imagenes(self):
        pares = [("THE-GAME.md", "LA-PARTIDA.md"), ("THE-MAZES.md", "LOS-LABERINTOS.md"),
                 ("THE-SEQUENCES.md", "LAS-SECUENCIAS.md"), ("THE-MUSIC.md", "LA-MUSICA.md")]
        for en, es in pares:
            ie = re.findall(r"imagenes/([^)]+)\)", lee_texto(os.path.join(DOCS, en)))
            ia = re.findall(r"imagenes/([^)]+)\)", lee_texto(os.path.join(DOCS, "es", es)))
            self.assertEqual(ie, ia, en)

    def test_cuatro_laberintos(self):
        for k in range(1, 5):
            self.assertTrue(os.path.exists(os.path.join(DOCS, "imagenes", "laberinto_%d.png" % k)))
        self.assertFalse(os.path.exists(os.path.join(DOCS, "imagenes", "laberinto_5.png")))


if __name__ == "__main__":
    unittest.main()
