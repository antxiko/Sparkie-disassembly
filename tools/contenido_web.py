#!/usr/bin/env python3
"""EL CONTENIDO de la web de este cartucho: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Todas las cifras de aqui estan medidas sobre este cartucho, con las
herramientas de tools/: CODIGO y DATOS los imprime tools/presupuesto.py
(make sanity), INSTRUCCIONES, COMENTARIOS y RUTINAS los da tools/densidad.py
(make densidad: "de N" rutinas, "N instrucciones, M comentarios").
"""

NOMBRE = "Sparkie"
ANIO = 1983
REPOSITORIO = "https://github.com/antxiko/Sparkie-disassembly"
SHA1 = "b9c98b80216983f97e28293b576ca9be3602c1a1"

CODIGO = 5039
DATOS = 3153
RUTINAS = 393
INSTRUCCIONES = 2736
COMENTARIOS = 1114


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Sparkie</em> lo hizo Konami y lo public&oacute; Sony para MSX en "
          "1983, en un cartucho de 8 KB. Todos los derechos sobre el juego siguen "
          "siendo de sus titulares. Este trabajo es de preservaci&oacute;n, estudio "
          "y documentaci&oacute;n, y la imagen del cartucho no se distribuye.",
    "en": "<em>Sparkie</em> was made by Konami and published by Sony for the MSX in "
          "1983, on an 8 KB cartridge. All rights in the game remain with their "
          "holders. This is preservation, study and documentation work, and the "
          "cartridge image is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Sparkie - desensamblado comentado",
        claim="Los cuatro laberintos dibujados desde la ROM, jugados en GIF: el cubo "
              "y su ola, los disparos, los bloques que arden, el premio, la carga que "
              "se gasta, TIME OVER y GAME OVER; los personajes animados, los textos, "
              "las dos m&uacute;sicas de su propio motor y un marcador que se rompe "
              "al pasar del mill&oacute;n.",
        ficha=["Konami para Sony - <b>(c) Konami 1983</b>",
               "Cartucho de <b>8 KB</b> en la p&aacute;gina 0 (el volcado: cuatro "
               "copias, 32 KB)", "<b>MSX</b>", "Volcado <b>b9c98b80...</b>"],
        aviso="<b>Aqu&iacute; no hay capturas del juego.</b> Los laberintos, los "
              "personajes, la pantalla de Sony y el men&uacute; salen de los bytes "
              "del cartucho (cotejados con openMSX byte a byte), y los GIF son el "
              "cartucho <b>funcionando en openMSX</b>: en cada cuadro se apuntan la "
              "VRAM y los registros del VDP, y <b>c&oacute;digo nuestro los pinta</b>.",
    ),
    "en": dict(
        titulo="Sparkie - commented disassembly",
        claim="The four mazes drawn from the ROM, played in GIF: the bucket and its "
              "wave, the shots, the burning blocks, the bonus, the draining charge, "
              "TIME OVER and GAME OVER; the animated characters, the texts, the two "
              "tunes from its own engine and a score that breaks past one million.",
        ficha=["Konami for Sony - <b>(c) Konami 1983</b>",
               "<b>8 KB</b> cartridge in page 0 (the dump: four copies, 32 KB)",
               "<b>MSX</b>", "Dump <b>b9c98b80...</b>"],
        aviso="<b>There are no screenshots of the game here.</b> The mazes, the "
              "characters, the Sony screen and the menu come from the cartridge's "
              "bytes (checked against openMSX byte by byte), and the GIFs are the "
              "cartridge <b>running in openMSX</b>: on every frame the VRAM and the "
              "VDP registers are logged, and <b>our own code paints them</b>.",
    ),
}

# Los tres bloques: el juego | curiosidades | por dentro.
# (en, es, titulo en, titulo es, que hay en, que hay es)
PAGINAS = [
    [("THE-GAME.html", "LA-PARTIDA.html", "The game", "La partida",
      "the rules as the code has them, the characters and the objects, and every "
      "moment of a game played in GIF",
      "las reglas como las tiene el c&oacute;digo, los personajes y los objetos, y "
      "cada momento de una partida jugado en GIF"),
     ("THE-MAZES.html", "LOS-LABERINTOS.html", "The mazes", "Los laberintos",
      "the four mazes drawn from the ROM, what each one holds, and why there are only four",
      "los cuatro laberintos dibujados desde la ROM, lo que trae cada uno y por "
      "qu&eacute; solo hay cuatro"),
     ("THE-SEQUENCES.html", "LAS-SECUENCIAS.html", "The sequences", "Las secuencias",
      "the Sony screen, the menu and the demo",
      "la pantalla de Sony, el men&uacute; y la demostraci&oacute;n"),
     ("THE-TEXTS.html", "LOS-TEXTOS.html", "The texts", "Los textos",
      "every text in the cartridge, with its translation",
      "todos los textos del cartucho, con su traducci&oacute;n"),
     ("THE-MUSIC.html", "LA-MUSICA.html", "The music", "La m&uacute;sica",
      "the two tunes, from its own sound engine and checked against openMSX",
      "las dos m&uacute;sicas, de su propio motor de sonido y cotejadas con openMSX")],
    [("CURIOSITIES.html", "CURIOSIDADES.html", "Curiosities", "Curiosidades",
      "the bugs, the Sony screen made of code, the enemy that paints, the leftovers, "
      "the open questions",
      "los fallos, la pantalla de Sony hecha de c&oacute;digo, el enemigo que pinta, "
      "los restos, las preguntas abiertas")],
    [("UNDER-THE-HOOD.html", "POR-DENTRO.html", "Under the hood", "Por dentro",
      "rebuilding the ROM, page 0 without the BIOS, the interrupt, the bitmap screen, "
      "the RAM, the sound engine and the tools",
      "rehacer la ROM, la p&aacute;gina 0 sin la BIOS, la interrupci&oacute;n, la "
      "pantalla como mapa de bits, la RAM, el motor de sonido y las herramientas")],
]

# Repositorio nuevo: no hay paginas viejas que redirigir.
VIEJAS = {}

LOGOTIPO = "logotipo.png"
