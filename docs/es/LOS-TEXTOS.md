# Los textos

Todos los textos del cartucho, en inglés y en la fuente de 43 letras de
`0x14DE`: no hay más. Cada rótulo lleva su color, su columna, su fila y su
longitud delante de las letras (`pinta_rotulo`, 0x0288). La fuente no tiene
todas las letras: le faltan la Q, la X y la Z, que no salen en ningún texto.

| Dónde | Texto | Traducción |
|---|---|---|
| menú (0x1922) | SPARKIE | |
| menú | (C) Konami 1983 | (el logotipo de Konami son cinco letras de la fuente) |
| menú | HIGH-SCORE 000000 | RÉCORD |
| menú | "1" KEY 1 PLAYER W/ JOYSTICK | tecla "1": un jugador con mando |
| menú | "2" KEY 2 PLAYERS W/ JOYSTICK | tecla "2": dos jugadores con mando |
| menú | "3" KEY 1 PLAYER W/ KEYBOARD | tecla "3": un jugador con teclado |
| menú | "4" KEY 2 PLAYERS W/ KEYBOARD | tecla "4": dos jugadores con teclado |
| al empezar (0x19D6) | PLAYER 1 | JUGADOR 1 |
| marcador (0x0380) | 1P / 2P | J1 / J2 (parpadea el del que juega) |
| marcador | HIGH | RÉCORD |
| marcador | REST | VIDAS (las que quedan, sin contar la que se juega) |
| marcador | STAGE | FASE |
| cartel (0x01FE) | TIME OVER | SE ACABÓ EL TIEMPO |
| cartel (0x0E22) | GAME OVER | FIN DE LA PARTIDA |

Los dos ceros de detrás de cada puntuación del marcador ("00") son rótulos
fijos: los puntos van por centenas.

La pantalla de Sony no usa esta fuente: sus letras ("HIT BIT", la plataforma)
son caracteres de SCREEN 1 que el arranque copia de `0x11DE`, y el "SPARKIE" y
la línea de Konami de esa pantalla son la misma fuente vista desde la letra
0x60 de SCREEN 1.
