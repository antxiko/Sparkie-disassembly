# Curiosities

## A bug: the score breaks past one million

Points come in hundreds and the score panel shows four digits
(`pinta_cifras`, 0x1846). With **10,000 hundreds or more** -one million points-
the conversion gives a fifth digit, and the second pass (0x185A) converts
`HL = 0xE249`, **a RAM address**, instead of the score. Running the cartridge's
routine with 10,000, 10,050 and 12,345 hundreds, all three times it paints the
same: **7929**. The high score, which uses the same routine, too.

## The Sony screen is made of code

The start-up sets SCREEN 1 and copies **2,048 bytes from `0x11DE`** as the
character table (`pantalla_de_sony`, 0x10EA). That stretch of the ROM is the
game's drawings, the font, tables and texts... and **594 bytes of code**. The
screen only names 57 of those 256 characters, and the drawings it needs sit
**between the routines**: the triangles of the "HIT BIT" platform are sixteen
bytes at `0x13DE`, right after the `ret` at 0x13DC; others at `0x1426`,
`0x145E` and `0x149E`, among the game's tables. And the 32-byte colour table
from `0x1636` reads the last thirteen from the two VDP register tables that
follow it.

## Eight kilobytes in page 0

The dump is 32 KB, but it is **the same 8 KB four times**: the cartridge does
not decode the high address lines and looks the same all over memory. And the
program is written for **page 0**, where the BIOS lives: the header gives INIT
at `0x00CF`, and the BIOS calls it with CALSLT, which puts the cartridge in the
page of the address it jumps to. From there it **never goes back to the
BIOS**: its RSTs (0x0010-0x0030) are its own, so is the interrupt at `0x0038`,
and the VDP, the PSG and the keyboard are driven with OUT and IN.

## The enemy that paints

The batch 8 enemy (the magenta one, one per maze in 3 and 4) **paints blue the
squares it steps on** while it has full life (`siguiente_enemigo`, 0x06EA),
just like Sparkie: it helps to finish the stage. It shows when the mazes are
checked against openMSX: they are the only four different squares, the ones
of its start, which it paints on its first step.

## The cross split in two

The burning blocks are copied into four lists of ten bytes, five blocks at most
(0x0A3D). Maze 4 brings a group of nine: the copy splits it into the cross in
the middle and the diamond on the right, which burn separately.

## TIME OVER pays too

At 4,096 frames TIME OVER comes up, but the stage ends the same way as the
others (`fin_de_fase`, 0x01A3): with the bonus for the painted squares,
counted in that same turn of the loop.

## Leftovers

- **RST 28h** (`0x0028`): `rst 18h / ld a,c`, which would fall into the fill
  at `0x002A`. No instruction does RST 28h.
- **`dec (ix+20h)`** at `0x071E`, after a `jp`: nothing jumps there.
- **`0x0A73`**: four bytes equal to Sparkie's start at `0x141A` (X 0x28, Y
  0xB0, state 0x1F), which nothing reads.
- **Sprite patterns 0xB4-0xC3**: in round 3 of the figure loading, 128 bytes
  are uploaded as they are (0x1159). No sprite in the game uses those patterns:
  the highest one painted, apart from the worn tail, is 0xB3.
- **Unused drawings**: the one at `0x1206` (a checkerboard) and six triangles
  at `0x136E`, which only the start-up copy uploads and the Sony screen does
  not name.
- **`0x1FFB`**: five bytes at the end of the ROM, `5B FF FF FF 04`, which
  nothing reads.
- `disparos_dan` (0x0D24) checks **16** enemy slots, and there are only 13: the
  three extra ones have their state at zero and do not count.

## The dump

The 32 KB dump (GoodMSX, `[!]`, sha1 `b9c98b80...`) is the one used. Its first
half, 16 KB, is exactly the dump openMSX regards as verified for this game
(sha1 `e0e8ed63...`).

## Open questions

- **Who made it.** The cartridge has no credits nor the hidden mark Konami put
  in later cartridges.
- **The five bytes at `0x1FFB`**: whether they are a checksum or a leftover of
  the ROM burning is not known.
