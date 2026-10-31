# The texts

Every text in the cartridge, in English and in the 43-letter font at `0x14DE`:
there are no more. Each caption carries its colour, column, row and length
before the letters (`pinta_rotulo`, 0x0288). The font does not have every
letter: it lacks Q, X and Z, which appear in no text.

| Where | Text | Meaning |
|---|---|---|
| menu (0x1922) | SPARKIE | |
| menu | (C) Konami 1983 | (the Konami logo is five letters of the font) |
| menu | HIGH-SCORE 000000 | the high score |
| menu | "1" KEY 1 PLAYER W/ JOYSTICK | key "1": one player with joystick |
| menu | "2" KEY 2 PLAYERS W/ JOYSTICK | key "2": two players with joysticks |
| menu | "3" KEY 1 PLAYER W/ KEYBOARD | key "3": one player with keyboard |
| menu | "4" KEY 2 PLAYERS W/ KEYBOARD | key "4": two players with keyboard |
| at the start (0x19D6) | PLAYER 1 | |
| score panel (0x0380) | 1P / 2P | (the current player's one flashes) |
| score panel | HIGH | the high score |
| score panel | REST | lives left, not counting the one being played |
| score panel | STAGE | |
| caption (0x01FE) | TIME OVER | |
| caption (0x0E22) | GAME OVER | |

The two zeros after each score in the panel ("00") are fixed captions: points
come in hundreds.

The Sony screen does not use this font: its letters ("HIT BIT", the platform)
are SCREEN 1 characters that the start-up copies from `0x11DE`, and that
screen's "SPARKIE" and Konami line are the same font seen from SCREEN 1's
character 0x60.
