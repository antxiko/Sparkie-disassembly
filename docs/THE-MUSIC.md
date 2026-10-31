# The music

The cartridge has **two tunes**, both on PSG channel A. They are not
transcribed by hand: `tools/musica.py` **runs the cartridge's own sound
engine** with `tools/z80run.py` -`silencio` (0x0F96), the request, and every
frame `paso_de_sonido` (0x0FE9) on the four blocks, like the interrupt- and
logs what it writes to the PSG. The synthesiser turns it into audio.

**Checked against openMSX**: in a recorded game, the channel A registers (tone
and volume) match the executed engine frame by frame, **167 frames in a row**
for the stage tune (until Sparkie runs short of charge and the warning starts)
and **233** for the warning (until the death, whose noise uses channel A's
volume).

## The stage tune

`musica_de_fase` (0x10A3) asks for it when every stage is set up. Three phrases
in the list at `0x1C8E`: 1, 2, 1, 3, and back to the start. Here, until it
repeats (1,351 frames, 22.5 s) and eight more seconds fading out.

<audio controls src="audio/musica_fase.mp3"></audio>

## The low-charge warning

It plays as soon as Sparkie runs short of charge (`carga_de_sparkie`, 0x051F,
with the list at `0x1CDF`) and ends by itself: 497 frames, about 8 s.

<audio controls src="audio/musica_aviso.mp3"></audio>

## The rest, which is not music

The other blocks carry the effects: Sparkie's background **hum** (`0x1D11`, on
channel B, which starts again every time an effect ends), the shots, the bonus,
the enemy crashing and the death explosion, which opens the noise on all three
channels. In the demo nothing sounds.
