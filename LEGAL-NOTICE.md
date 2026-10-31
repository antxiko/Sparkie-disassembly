# Legal notice and attribution

*(Tambien disponible [en castellano](AVISO-LEGAL.md).)*

## Who owns what

**The game is not ours.** *Sparkie* was made by **Konami** and published by **Sony** for the MSX in 1983, on an 8 KB cartridge. All rights over the game remain with
their holders.

**What is ours** are the tools in this repository, the comments in the listing,
the analysis and the documentation. Those are published under the licence in
`LICENSE`.

## What is in this repository

The file `src/sparkie.asm` is the commented disassembly of the cartridge. It is
published for the **preservation, study and documentation** of a title that is
part of the history of MSX software.

The cartridge image (`.rom`) is **not** distributed here. Whoever wants to
rebuild the listing has to supply their own, and the `Makefile` checks its
sha256 before doing anything.

## What it rests on

Nobody else's work. Everything stated here comes from reading this binary or from measuring it running in openMSX, and each claim carries its evidence next to it: the instruction that reads a datum, the table that ends exactly where it has to end, or the measurement made in the emulator. What is not settled is said not to be. The game's LaunchBox entry helped as a first orientation on the rules; the rules told here are checked in the code.

## If you are one of the authors

If you worked on *Sparkie* or hold rights over the game, and you would rather this
material were not published, **say so and it comes down, no argument**. The
intent of this work is the opposite of harming you: it is to put on record how
it was made.
