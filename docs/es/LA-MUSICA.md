# La música

El cartucho tiene **dos músicas**, las dos en el canal A del PSG. No están
grabadas a mano: `tools/musica.py` **ejecuta el motor de sonido del propio
cartucho** con `tools/z80run.py` -`silencio` (0x0F96), la petición, y en cada
cuadro `paso_de_sonido` (0x0FE9) con los cuatro bloques, como la
interrupción- y apunta lo que escribe en el PSG. El sintetizador lo convierte
en audio.

**Cotejadas con openMSX**: en una partida grabada, los registros del canal A
(tono y volumen) coinciden cuadro a cuadro con los del motor ejecutado, **167
cuadros seguidos** la de la fase (hasta que a Sparkie le falta carga y entra
el aviso) y **233** el aviso (hasta la muerte, cuyo ruido usa el volumen del
canal A).

## La música de la fase

La pide `musica_de_fase` (0x10A3) al montar cada fase. Tres frases en la lista
de `0x1C8E`: 1, 2, 1, 3, y vuelta a empezar. Aquí, hasta que se repite
(1.351 cuadros, 22,5 s) y ocho segundos más que se apagan.

<audio controls src="../audio/musica_fase.mp3"></audio>

## El aviso de la carga baja

Suena en cuanto a Sparkie le falta carga (`carga_de_sparkie`, 0x051F, con la
lista de `0x1CDF`) y se acaba sola: 497 cuadros, unos 8 s.

<audio controls src="../audio/musica_aviso.mp3"></audio>

## El resto, que no es música

Los otros bloques llevan los efectos: el **zumbido** de fondo de Sparkie
(`0x1D11`, en el canal B, que vuelve a empezar cada vez que acaba un efecto),
los disparos, el premio, el enemigo que choca y la explosión de la muerte, que
abre el ruido en los tres canales. En la demostración no suena nada.
