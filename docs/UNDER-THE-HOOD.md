# Under the hood

## Rebuilding the ROM

`make verify` assembles `src/sparkie.asm` with pasmo and out comes the 8 KB ROM
**byte for byte**; repeated four times, it gives the 32 KB dump. `make sanity`
checks what reassembling does not cover: that no byte declared as data is read
as code, and that all 8,192 are explained, as traced code or as named data.
`make test` runs the tests. The ROM is not in the repository: it has to be put
in the root as `sparkie.rom` (the GoodMSX dump, `[!]`, sha1 `b9c98b80...`).

| | bytes |
|---|---|
| traced code | 5,039 |
| named data | 3,153 |
| unexplained | 0 |

The listing carries 1,114 comments on 2,736 instructions (40.7%), 393 routines
and labels, none under 10% commented, and no called routine without a name.

## Page 0, without the BIOS

INIT (`0x00CF`) disables interrupts, sets mode 1, the stack at `0xE7FF`,
silences the PSG, builds the Sony screen and clears 1,872 bytes of RAM from
`0xE000`. From there everything belongs to the cartridge:

| | What it does |
|---|---|
| RST 10h | HL = HL + 2 * A: element A of a word table |
| RST 18h | address DE to the VDP |
| RST 20h | B bytes from HL to VRAM |
| RST 30h | DE = the position of the IX object |
| 0x0038 | the interrupt |

## The interrupt

Once per frame (`interrupcion`, 0x0038): the four sound blocks and, if Sparkie
is alive, the stage counter and the game, shared out over alternate frames. On
**odd** frames, Sparkie, the shots, its charge and three enemy batches; on
**even** ones, batch 1, the buckets, the flames, the burning blocks, the bonus
and the shots wiped. The main loop (0x0134) only counts enemies and unpainted
squares, and handles death and the end of the stage.

## The screen, a bitmap

SCREEN 2 with the name table set from 0 to 255 in the three thirds (0x11A4):
every 8x8 square has its own pattern, and drawing is writing patterns and
colours in place. A square is 8 bytes of pattern and 8 of colour
(`pinta_casilla`, 0x0BCF); a 16x16 object, four of them (`pinta_objeto`,
0x0BFA). The characters are 16x16 sprites; the patterns, at 0x1800, every
figure in four directions.

## The RAM

| | |
|---|---|
| `0xE001` | the current player (1 the first, 0 the second) |
| `0xE002`-`0xE00D` | Sparkie: position, state (bit 3 alive, bits 0-1 the charge, high nibble the direction), its sprite |
| `0xE00E` | the joystick: bits 7-4 up, down, left, right; bit 3 the button |
| `0xE00F`-`0xE03A` | the wave (up to 20 squares) and its tip |
| `0xE03B`-`0xE042` | the four shots |
| `0xE044` | how many enemies there are |
| `0xE047` | the stage frames (2,048: faster; 4,096: TIME OVER) |
| `0xE04E`-`0xE059` | how many enemies in each band of two rows |
| `0xE06F` | the high score |
| `0xE0A2`, `0xE0A3` | the menu option and the mode (demo, game over) |
| `0xE0B4`-`0xE0D3` | the four sound blocks |
| `0xE12C`-`0xE1BB` | the maze: 24 rows of 6 bytes, two bits per square |
| `0xE1BC`, `0xE1C8` | the three buckets and the five flames, with their states |
| `0xE1DC`-`0xE1F5` | the 13 enemies; their state, 0x20 bytes further on |
| `0xE21C` | the bonus |
| `0xE220`-`0xE247` | the four lists of burning blocks |
| `0xE24D`, `0xE24F`, `0xE250` | the score, the lives and the stage |
| `0xE258`, `0xE384` | each player's saved game (298 bytes) |
| `0xE4B0` | the sprite table uploaded to VRAM |

## The sound engine

Four 8-byte blocks: the music on channel A, the hum and the shots on B, the
effects on C and the noise with A's volume. Each note is the low tone, a byte
with the duration (high nibble), the "volume follows" bit and the high tone,
and the volume if it follows; with bit 4 of the volume, the envelope period.
`0x00` ends an effect (and the hum comes back), `0xFF` silences the block and
`0xFE` moves to the next music phrase, which is copied to `0xE5DC`.

## The tools

| | |
|---|---|
| `tools/z80trace.py`, `tools/mkasm.py` | the trace and the listing |
| `tools/presupuesto.py`, `tools/densidad.py` | the explained bytes and the comments |
| `tools/omsx_graba.tcl`, `tools/lanza_graba.ps1` | record the cartridge in openMSX frame by frame: VRAM, registers, RAM, PSG and time |
| `tools/guiones/*.tcl` | what is pressed (and the pokes) in each recording |
| `tools/vdp.py`, `tools/gifs.py` | the TMS9918 in Python and the GIFs |
| `tools/laberintos.py` | the mazes from the ROM, and their check against openMSX |
| `tools/personajes.py`, `tools/pantallas.py` | the sprites and the screens, running the cartridge with `tools/z80run.py`, and their check |
| `tools/objetos.py` | the maze objects with their colours |
| `tools/musica.py` | the tunes, running its engine |

## The checks

| | Result |
|---|---|
| the four mazes against the openMSX VRAM | 0 bytes (3 and 4: the four squares of the painting enemy) |
| stage 5 against maze 1 | 0 bytes |
| the sprite patterns | 0 of 2,048 |
| the Sony screen and the menu | 0 of 16,384, registers equal |
| the stage tune and the warning | 167 and 233 frames in a row equal |
