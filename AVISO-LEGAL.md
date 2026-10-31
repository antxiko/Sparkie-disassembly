# Aviso legal y atribucion

*(Also available [in English](LEGAL-NOTICE.md).)*

## De quien es cada cosa

**El juego no es nuestro.** *Sparkie* lo hizo **Konami** y lo publico **Sony** para MSX en 1983, en un cartucho de 8 KB. Todos los derechos sobre el juego
siguen siendo de sus titulares.

**Lo que si es nuestro** son las herramientas de este repositorio, los
comentarios del listado, el analisis y la documentacion. Eso se publica con la
licencia de `LICENSE`.

## Que hay en este repositorio

El fichero `src/sparkie.asm` es el desensamblado comentado del cartucho. Se publica
para la **preservacion, el estudio y la documentacion** de un titulo que es
parte de la historia del software del MSX.

La imagen del cartucho (`.rom`) **no** se distribuye aqui. Quien quiera volver a
montar el listado tiene que poner la suya, y el `Makefile` comprueba su sha256
antes de hacer nada.

## En que se apoya

En nada de nadie. Todo lo que se afirma aqui sale de leer este binario o de medirlo corriendo en openMSX, y cada afirmacion lleva su evidencia al lado: la instruccion que lee un dato, la tabla que cierra exactamente donde tiene que cerrar, o la medida hecha en el emulador. Lo que no esta cerrado se dice que no lo esta. Para orientarse sobre las reglas sirvio la ficha del juego en LaunchBox; las reglas que se cuentan estan comprobadas en el codigo.

## Si eres uno de los autores

Si trabajaste en *Sparkie* o tienes derechos sobre el juego, y preferirias que este
material no estuviera publicado, **dilo y se retira, sin discusion**. La
intencion de este trabajo es justo la contraria de perjudicarte: es dejar
constancia de como se hizo.
