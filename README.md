# Sparkie - commented disassembly

*(También [en castellano](README.es.md).)*

The commented disassembly of **Sparkie** (Konami for Sony, 1983) for the MSX: an 8 KB ROM written for page 0, which does not use the BIOS.

- **100%** of the binary explained: 5,039 bytes of code and 3,153 of named data, not one byte unassigned.
- **40.7%** of the listing commented, 393 routines and labels, none under 10% comments.
- The listing reassembles into the original ROM **byte for byte** (and four times in a row gives the 32 KB dump).
- The four mazes, the characters, the Sony screen and the menu come from the cartridge's bytes, checked against openMSX byte by byte; the game, played in GIF; the two tunes, from its own sound engine; and a score bug past one million points.

The website: <https://antxiko.github.io/Sparkie-disassembly/>
(in Spanish: <https://antxiko.github.io/Sparkie-disassembly/es/>).

## Reproducing it

The cartridge image is not distributed. Put yours in the root as `sparkie.rom` (sha256 `fc4a86f6...`) and run `make`. The details, in [UNDER THE HOOD](docs/UNDER-THE-HOOD.md).

## Legal

The game belongs to Konami, Sony and their rights holders. The licence in `LICENSE` covers only the tools, comments, analysis and documentation here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
