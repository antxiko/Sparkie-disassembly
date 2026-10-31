; ==========================================================================
; SPARKIE - Konami para Sony - MSX1 (1983) - ROM de 8 KB vista en las cuatro paginas
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x00000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x00CF), en la
;   pagina 0; STATEMENT, DEVICE y TEXT a cero
;   0x0000..0x0010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 0000
	defw 000cfh,00000h,00000h,00000h,00000h,00000h,00000h	; 0002

; ======================================================================
; CODIGO 0x0010..0x0028  (24 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; RST 10h: HL = HL + 2*A. El acarreo del doble va a H aqui, y el de la suma en 0x01FA, que es donde sigue.
; ----------------------------------------------------------------------
rst_hl_mas_2a:		; RST 10h: HL += 2*A (elemento A de una tabla de palabras)
	add a,a			;0010   ; A*2
	jr nc,L_0014		;0011   ; sin acarreo, H se queda
	inc h			;0013   ; el bit que sale va a H
L_0014:
	add a,l			;0014   ; y se suma a L
	jp rst_hl_mas_2a_fin		;0015   ; el resto, fuera de los ocho bytes del RST

; ----------------------------------------------------------------------
; RST 18h: la direccion de la VRAM en DE (E el byte bajo, D el alto con el bit 6 puesto si es para escribir)
; ----------------------------------------------------------------------
rst_vdp_direccion:		; RST 18h: pone la direccion DE en el VDP
	ld a,e			;0018   ; el byte bajo primero
	out (099h),a		;0019
	nop			;001b   ; espera del VDP entre las dos escrituras
	ld a,d			;001c   ; y el alto, con el bit de escritura
	out (099h),a		;001d
	ret			;001f

; ----------------------------------------------------------------------
; RST 20h: B bytes de HL a la VRAM
; ----------------------------------------------------------------------
rst_vdp_copia:		; RST 20h: copia B bytes de HL a la VRAM
	ld a,(hl)			;0020   ; el byte de la ROM o la RAM
	out (098h),a		;0021   ; al puerto de datos del VDP
	nop			;0023   ; espera del VDP
	inc hl			;0024   ; siguiente
	djnz rst_vdp_copia		;0025   ; B veces
	ret			;0027

; ----------------------------------------------------------------------
; DATOS rst_28_sin_uso: RST 28h: `rst 18h / ld a,c`, que caeria en el relleno
;   de 0x002A. Ninguna instruccion del cartucho hace RST 28h (el trazado no
;   llega) ni lo apunta
;   0x0028..0x002a  (2 bytes)
DATA_rst_28_sin_uso:
	defb 0dfh,079h	; 0028

; ======================================================================
; CODIGO 0x002a..0x0037  (13 bytes)
; ======================================================================


vdp_rellena:		; B bytes iguales (A) a la VRAM, desde la direccion ya puesta
	out (098h),a		;002a   ; el mismo byte cada vez
	nop			;002c
	djnz vdp_rellena		;002d   ; B veces
	ret			;002f

; ----------------------------------------------------------------------
; RST 30h: DE = la posicion del objeto al que apunta IX (X en E, Y en D)
; ----------------------------------------------------------------------
rst_pos_de_ix:		; RST 30h: DE = (IX+0), (IX+1)
	ld e,(ix+000h)		;0030   ; la X
	ld d,(ix+001h)		;0033   ; la Y
	ret			;0036

; ----------------------------------------------------------------------
; DATOS relleno_0037: el byte que falta hasta 0x0038, a cero
;   0x0037..0x0038  (1 bytes)
DATA_relleno_0037:
	defb 000h	; 0037

; ======================================================================
; CODIGO 0x0038..0x01fe  (454 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA INTERRUPCION DEL VDP. Con el cartucho en la pagina 0, el `im 1` de INIT la manda aqui. Mueve los cuatro bloques de sonido, y si Sparkie esta vivo cuenta el cuadro y mueve el juego: en los cuadros impares Sparkie, sus chispas y tres enemigos; en los pares el cuarto enemigo, los cubos, las llamas, los muros que se abren y el premio.
; ----------------------------------------------------------------------
interrupcion:		; El juego entero cuelga de aqui, una vez por cuadro
	push af			;0038   ; se guarda todo: el programa principal sigue en su bucle
	push iy		;0039
	push ix		;003b
	push bc			;003d
	push de			;003e
	push hl			;003f
	in a,(099h)		;0040   ; lee el registro de estado del VDP, que baja la peticion
	ld b,004h		;0042   ; los cuatro bloques de sonido
	ld hl,0e0adh		;0044   ; 0xE0AD + 8: el primero esta en 0xE0B4
L_0047:
	ld a,004h		;0047   ; al siguiente bloque (8 bytes)
	rst 10h			;0049
	push hl			;004a
	push bc			;004b
	call paso_de_sonido		;004c   ; un paso de su sonido
	pop bc			;004f
	pop hl			;0050
	djnz L_0047		;0051
	call sparkie_vivo		;0053   ; Sparkie vivo? (bit 3 de 0xE004)
	jr z,L_00C5		;0056   ; no: solo suena
	ld a,(0e0a6h)		;0058   ; la espera del fin de fase tambien para el juego
	or a			;005b
	jr nz,L_00C5		;005c
	ld hl,(0e047h)		;005e   ; un cuadro mas de la fase
	inc hl			;0061
	ld (0e047h),hl		;0062
	push hl			;0065
	bit 4,l		;0066   ; cada 16 cuadros se cambia de color
	ld a,0f0h		;0068   ; blanco sobre negro
	jr z,L_006E		;006a
	ld a,011h		;006c   ; o negro: el rotulo del jugador parpadea
L_006E:
	push af			;006e
	call jugador		;006f   ; que jugador juega?
	ld hl,00381h		;0072   ; el texto de "1P"
	jr nz,L_007A		;0075
	ld hl,003ach		;0077   ; o el de "2P"
L_007A:
	pop af			;007a
	call pinta_rotulo_color		;007b   ; lo pinta con el color de turno
	pop hl			;007e
	bit 0,l		;007f   ; los cuadros pares a 0x00AA
	jr z,L_00AA		;0081
	call mueve_sparkie		;0083   ; IMPAR: Sparkie se mueve
	call disparos_dan		;0086   ; las chispas apagan a los enemigos que tocan
	call carga_de_sparkie		;0089   ; la punta de la mecha
	ld a,002h		;008c   ; enemigo 2
	ld ix,0e1e4h		;008e   ; los enemigos a partir del segundo
	call mueve_enemigos		;0092
	ld a,004h		;0095   ; enemigo 3
	call mueve_enemigos		;0097
	ld a,008h		;009a   ; enemigo 4
	call mueve_enemigos		;009c
	ld hl,0e048h		;009f   ; a los 2048 cuadros (bit 3 de 0xE048)...
	bit 3,(hl)		;00a2
	jr z,L_00C2		;00a4
	set 7,(hl)		;00a6   ; ...se marca el bit 7: los enemigos van mas deprisa
	jr L_00C2		;00a8
L_00AA:
	ld a,001h		;00aa   ; PAR: el enemigo 1
	ld ix,0e1dch		;00ac
	call mueve_enemigos		;00b0
	call pinta_cubos		;00b3   ; los cubos, con su color
	call mueve_llamas		;00b6   ; las llamas
	call bloques_que_arden		;00b9   ; el muro que se abre
	call premio		;00bc   ; el premio del centro
	call borra_disparos		;00bf   ; las chispas, borradas
L_00C2:
	call sonido_de_muerte		;00c2   ; Sparkie muerto? apaga la musica
L_00C5:
	pop hl			;00c5
	pop de			;00c6
	pop bc			;00c7
	pop ix		;00c8
	pop iy		;00ca
	pop af			;00cc
	ei			;00cd   ; se reabre la interrupcion antes de volver
	ret			;00ce

; ----------------------------------------------------------------------
; INIT. La BIOS llega aqui con el cartucho en la pagina 0 y ya no se vuelve: pila propia en 0xE7FF, la interrupcion en modo 1 (que salta a 0x0038, de este programa), el PSG callado, la pantalla de Sony y el menu.
; ----------------------------------------------------------------------
init:		; INIT: la maquina entera para el juego
	di			;00cf   ; sin interrupciones hasta acabar de montar la pantalla
	im 1		;00d0   ; modo 1: la interrupcion va a 0x0038
	ld sp,0e7ffh		;00d2   ; la pila, al final de los 2 KB de RAM que usa
	call silencio		;00d5   ; el PSG en silencio
	call pantalla_de_sony		;00d8   ; la pantalla de Sony y los graficos en la VRAM
	ld bc,00750h		;00db   ; 0xE000-0xE750 a cero
	ld hl,0e000h		;00de   ; desde 0xE000
	ld de,0e001h		;00e1
	ld (hl),l			;00e4   ; L = 0: el primer byte a cero, y LDIR lo arrastra
	ldir		;00e5   ; 1872 bytes
	ld a,001h		;00e7   ; la opcion 1 del menu (un jugador, mando)
	ld (0e0a2h),a		;00e9
menu:		; El menu, y la demostracion si nadie elige
	call pon_menu		;00ec   ; el menu (o la demostracion si nadie pulsa)
partida_nueva:		; Empieza una partida (o la demostracion)
	ld hl,0e0a5h		;00ef   ; el modo que ha dejado el menu pasa a 0xE0A3
	ld b,(hl)			;00f2
	xor a			;00f3
	ld (hl),a			;00f4
	dec hl			;00f5
	ld (hl),a			;00f6
	dec hl			;00f7
	ld (hl),b			;00f8
	ld hl,0e1bch		;00f9   ; los objetos y la ocupacion de los dos jugadores, a cero
	ld b,09ch		;00fc
	xor a			;00fe
	call rellena		;00ff
	ld a,003h		;0102   ; tres vidas
	ld (0e24fh),a		;0104
	ld a,00fh		;0107   ; las cuatro listas de muros, disponibles
	ld (0e251h),a		;0109
	ld hl,019e2h		;010c   ; el laberinto 1
	call laberinto_jugador2		;010f   ; para el jugador 2 (0xE001 = 0)
	call laberinto_jugador1		;0112   ; y para el 1, que empieza
vida_nueva:		; Con cada vida y cada fase: monta la pantalla del jugador en curso
	call jugador		;0115   ; el jugador en curso
	jr nz,L_011F		;0118
	call laberinto_jugador2		;011a   ; el 2: su laberinto, nuevo
	jr L_0122		;011d
L_011F:
	call laberinto_jugador1		;011f   ; el 1: el suyo
L_0122:
	call pinta_fase		;0122   ; la pantalla de la fase
	ld a,(0e0a2h)		;0125   ; opcion par (dos jugadores)?
	rrca			;0128
	jr c,bucle_principal		;0129
	ld hl,(0e4a5h)		;012b   ; la puntuacion del jugador 2 en su sitio del marcador
	ld de,00718h		;012e
	call pinta_cifras		;0131
bucle_principal:		; El bucle de la fase: lo que no se mueve en la interrupcion
	ei			;0134   ; a partir de aqui el juego va por la interrupcion
	xor a			;0135
	ld b,00dh		;0136   ; las 13 posiciones de los enemigos...
	ld hl,0e1fch		;0138   ; los estados de los enemigos (0xE1DC + 0x20)
	call cuenta_bit3		;013b   ; ...cuantas tienen el bit 3 (el enemigo en juego)
	ld (0e044h),a		;013e   ; se apunta
	or a			;0141
	jr z,fin_de_fase		;0142   ; ninguno: la fase se acaba
	ld de,00000h		;0144   ; cuenta las casillas del laberinto que siguen a cero (sin pintar)
	ld h,e			;0147   ; HL = 0: la cuenta
	ld l,e			;0148
L_0149:
	call lee_casilla		;0149   ; la casilla (E, D)
	or a			;014c
	jr nz,L_0150		;014d
	inc hl			;014f   ; a cero: una mas
L_0150:
	ld a,018h		;0150   ; 24 casillas por fila...
	call siguiente_casilla		;0152   ; ...y 24 filas
	jr nz,L_0149		;0155
	ld (0e071h),hl		;0157   ; lo que queda sin pintar
	ld a,h			;015a
	or l			;015b
	jr z,fin_de_fase		;015c   ; todo pintado: la fase se acaba
	ld a,(0e048h)		;015e   ; 4096 cuadros (bit 4 de 0xE048)?
	bit 4,a		;0161
	jr z,L_016F		;0163
	ld hl,001feh		;0165   ; "TIME  OVER"
	di			;0168
	call pinta_rotulo		;0169
	ei			;016c
	jr fin_de_fase		;016d   ; y la fase se acaba
L_016F:
	call muerte		;016f   ; la muerte de Sparkie, si le toca
	ld hl,0e0a3h		;0172   ; el modo
	ld a,(hl)			;0175
	or a			;0176
	jr z,bucle_principal		;0177   ; partida normal: sigue el bucle
	rrca			;0179   ; bit 0, la demostracion?
	jr nc,fin_de_partida		;017a
	ld e,a			;017c
	push hl			;017d
	call boton_de_salida		;017e   ; en la demostracion, el boton
	pop hl			;0181
	jr z,L_0188		;0182   ; nadie pulsa: sigue
	inc hl			;0184   ; pulsado: empieza la partida con la opcion de B
	ld a,b			;0185
	jr L_019C		;0186
L_0188:
	ld a,e			;0188   ; la demostracion acaba sola
	rrca			;0189
	jr nc,bucle_principal		;018a
	call pon_menu		;018c   ; vuelve al menu
	jp partida_nueva		;018f
fin_de_partida:		; Bit 7 de 0xE0A3: se acabo la partida
	bit 7,(hl)		;0192   ; bit 7: partida acabada?
	jr z,bucle_principal		;0194
	inc hl			;0196   ; 0xE0A4: a quien le toca
	ld a,(hl)			;0197
	or a			;0198
	jp z,menu		;0199   ; a nadie: al menu
L_019C:
	di			;019c   ; la partida con la opcion que se ha pulsado
	call menu_al_empezar		;019d
	jp partida_nueva		;01a0
fin_de_fase:		; La fase acabada: espera, cuenta el premio y monta la siguiente
	call silencio		;01a3   ; el PSG en silencio
	call zumbido		;01a6   ; el zumbido de fondo, otra vez
	ld hl,0e0a6h		;01a9   ; la espera del fin de fase: para el juego
	ld a,0ffh		;01ac
L_01AE:
	ld b,0ffh		;01ae   ; 255 vueltas...
L_01B0:
	djnz L_01B0		;01b0
	inc (hl)			;01b2   ; ...por cada paso de 0xE0A6
	cp (hl)			;01b3
	jr nz,L_01AE		;01b4
	di			;01b6   ; se acaba la espera (0xE0A6 a cero al pasar de 0xFF)
	inc (hl)			;01b7
	ld a,00fh		;01b8   ; las cuatro listas de muros, otra vez disponibles
	ld (0e251h),a		;01ba
	call silencio		;01bd
	ld b,00ah		;01c0   ; una pausa
	call pausa		;01c2
	ld hl,0e250h		;01c5   ; la fase siguiente
	inc (hl)			;01c8
	call laberinto_de_fase		;01c9   ; su laberinto (0xE250 & 3: hay cuatro)
	push hl			;01cc
	call premio_de_fase		;01cd   ; el premio por las casillas que quedan
	pop hl			;01d0
	jp vida_nueva		;01d1   ; y se monta la pantalla
cuenta_bit3:		; A = A + cuantos de los B objetos de HL (de 2 en 2) tienen el bit 3 puesto
	bit 3,(hl)		;01d4   ; el bit 3: en juego
	jr z,L_01D9		;01d6
	inc a			;01d8   ; uno mas
L_01D9:
	inc hl			;01d9   ; el siguiente, dos bytes mas alla
	inc hl			;01da
	djnz cuenta_bit3		;01db
	ret			;01dd
laberinto_jugador2:		; El laberinto de HL para el jugador 2 (0xE001 = 0), guardado en 0xE384
	push hl			;01de
	call desempaqueta_laberinto		;01df   ; desempaqueta el laberinto y sus objetos
	xor a			;01e2   ; el jugador 2
	call pon_jugador		;01e3   ; en curso
	inc a			;01e6   ; y su copia se guarda en 0xE384
	call copia_jugador2		;01e7
	pop hl			;01ea
	ret			;01eb
laberinto_jugador1:		; Lo mismo para el jugador 1 (0xE001 = 1), guardado en 0xE258
	push hl			;01ec
	call desempaqueta_laberinto		;01ed   ; desempaqueta el laberinto
	ld a,001h		;01f0   ; el jugador 1
	call pon_jugador		;01f2
	call copia_jugador1		;01f5   ; y su copia en 0xE258
	pop hl			;01f8
	ret			;01f9
rst_hl_mas_2a_fin:		; El final de RST 10h: L = A, y el acarreo a H
	ld l,a			;01fa   ; el byte bajo
	ret nc			;01fb   ; sin acarreo, listo
	inc h			;01fc   ; con acarreo, H + 1
	ret			;01fd

; ----------------------------------------------------------------------
; DATOS texto_time_over: color 0xF1, X 7, Y 11, 10 letras: "TIME  OVER"
;   (formato de 0x0288: color, X, Y, longitud y las letras en la fuente de
;   0x14DE)
;   0x01fe..0x020c  (14 bytes)
DATA_texto_time_over:
	defb 0f1h,007h,00bh,00ah	; 01fe
	defb 01eh,007h,006h,015h,001h,001h,003h,020h,015h,01ch	; 0202  ....... ..

; ======================================================================
; CODIGO 0x020c..0x0380  (372 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MENU: los siete rotulos de 0x1922 y la espera de una tecla del 1 al 4 (fila 0 del teclado). Con el boton apretado se salta a la demostracion; si nadie pulsa en 85 pasos, empieza la demostracion.
; ----------------------------------------------------------------------
pon_menu:		; El menu de 0x1922 y la tecla del 1 al 4
	call boton_de_salida		;020c   ; el boton ya apretado?
	jr nz,menu_al_empezar		;020f   ; si: directo a la partida
	ld d,000h		;0211   ; desde la fila 0...
	call borra_pantalla		;0213   ; ...la pantalla en blanco
	call pinta_menu		;0216   ; los siete rotulos del menu
	ld hl,(0e06fh)		;0219   ; el record...
	ld de,00911h		;021c   ; ...en X 0x11, Y 9 (detras de "HIGH-SCORE")
	call pinta_cifras		;021f
	ld d,055h		;0222   ; 85 vueltas de espera
L_0224:
	ld a,d			;0224
	or a			;0225
	jp nz,L_022F		;0226   ; quedan?
	inc a			;0229   ; no: la demostracion
	ld (0e0a5h),a		;022a
	jr pausa_y_borra		;022d
L_022F:
	ld a,050h		;022f   ; la fila 0 del teclado
	out (0aah),a		;0231
	in a,(0a9h)		;0233   ; lee las teclas (0 = pulsada)
	ld b,004h		;0235   ; cuatro teclas: 1, 2, 3 y 4
	rra			;0237   ; fuera la del 0
	ld c,000h		;0238   ; C = la tecla que se mira
L_023A:
	inc c			;023a
	rra			;023b   ; la siguiente, al acarreo
	jr nc,L_0248		;023c   ; pulsada!
	djnz L_023A		;023e
	ld b,001h		;0240   ; ninguna: un rato...
	call pausa		;0242
	dec d			;0245   ; ...y otra vuelta
	jr L_0224		;0246
L_0248:
	ld a,c			;0248   ; la opcion elegida
	ld (0e0a2h),a		;0249
	ld d,008h		;024c   ; se borra desde la fila 8
	call borra_pantalla		;024e   ; y se pasa a la partida
	jr anuncia_partida		;0251
menu_al_empezar:		; El boton en el menu: la pantalla en blanco, y la partida
	ld d,000h		;0253   ; toda la pantalla en blanco
	call borra_pantalla		;0255
	ld b,002h		;0258   ; y los dos primeros rotulos
	call pinta_rotulos_1922		;025a
anuncia_partida:		; "PLAYER 1" y la opcion elegida, y una pausa
	ld hl,019d6h		;025d   ; "PLAYER 1"
	call pinta_rotulo		;0260
	ld a,(0e0a2h)		;0263   ; la opcion...
	ld hl,003b7h		;0266   ; ...con su texto de la lista de 0x03B7
	dec a			;0269
	call palabra		;026a
	ex de,hl			;026d
	call pinta_rotulo		;026e   ; y se pinta
pausa_y_borra:		; Una pausa y la pantalla en blanco
	ld b,00ch		;0271   ; un rato
	call pausa		;0273
	ld d,000h		;0276   ; desde la fila 0, todo en blanco
	jp borra_pantalla		;0278
pinta_menu:		; Los siete rotulos de 0x1922
	ld b,007h		;027b   ; siete
pinta_rotulos_1922:		; B rotulos seguidos desde 0x1922
	ld hl,01922h		;027d
pinta_rotulos:		; B rotulos seguidos desde HL
	push bc			;0280
	call pinta_rotulo		;0281   ; uno
	pop bc			;0284
	djnz pinta_rotulos		;0285   ; y el siguiente, que viene detras
	ret			;0287
pinta_rotulo:		; Un rotulo: color, X, Y, longitud y las letras
	ld a,(hl)			;0288   ; el color
	inc hl			;0289
pinta_rotulo_color:		; Lo mismo con el color en A (HL en la X)
	ld e,(hl)			;028a   ; X
	inc hl			;028b
	ld d,(hl)			;028c   ; Y
	inc hl			;028d
	ld b,(hl)			;028e   ; cuantas letras
	inc hl			;028f
pinta_letras:		; B letras de HL en (E, D), con el color de B' (la fuente, 0x14DE)
	push hl			;0290
	exx			;0291   ; al juego de registros de la fuente
	ld de,014deh		;0292   ; la fuente de 0x14DE
	ld h,d			;0295
	ld l,e			;0296
	ld b,a			;0297   ; el color, a B'
	exx			;0298
	ld a,(hl)			;0299   ; la letra...
	rlca			;029a   ; ...por 4
	rlca			;029b   ; (el doble lo hace RST 10h)
	exx			;029c
	rst 10h			;029d   ; por 2 mas: HL' = la fuente + 8 * letra
	push hl			;029e   ; sus ocho bytes
	ld a,b			;029f
	exx			;02a0
	pop hl			;02a1   ; HL = las letras
	call pinta_casilla		;02a2   ; la letra en su casilla, con su color
	inc e			;02a5   ; la casilla siguiente
	pop hl			;02a6
	inc hl			;02a7   ; la letra siguiente
	djnz pinta_letras		;02a8   ; B letras
	ret			;02aa

; ----------------------------------------------------------------------
; LA PANTALLA DE LA FASE: el marcador, el laberinto casilla a casilla desde la RAM, Sparkie en su sitio de salida, los enemigos marcados en la ocupacion, la musica y las cifras.
; ----------------------------------------------------------------------
pinta_fase:		; Monta la pantalla de la fase desde la RAM del jugador
	call sprites_fuera		;02ab   ; sprites fuera
	ld hl,00380h		;02ae   ; los rotulos del marcador
	ld a,(0e0a2h)		;02b1   ; con dos jugadores...
	rrca			;02b4
	ld b,006h		;02b5   ; seis rotulos
	jr c,L_02BB		;02b7
	inc b			;02b9   ; ...ocho: tambien "2P" y su cifra
	inc b			;02ba
L_02BB:
	call pinta_rotulos		;02bb   ; pintados
	ld de,00000h		;02be   ; el laberinto desde la casilla (0, 0)
L_02C1:
	call lee_casilla		;02c1   ; lo que hay en la casilla
	ld c,0c3h		;02c4   ; el color de los bloques
	call pon_casilla		;02c6   ; se pinta
	ld a,018h		;02c9   ; 24 por fila, 24 filas
	call siguiente_casilla		;02cb
	jr nz,L_02C1		;02ce
	ld bc,00004h		;02d0   ; Sparkie de salida: los 4 bytes de 0x141A
	ld de,0e002h		;02d3
	push de			;02d6
	pop ix		;02d7
	ld hl,0141ah		;02d9
	ldir		;02dc
	ld a,010h		;02de   ; el mando, como si pidiera a la derecha
	ld (0e00eh),a		;02e0
	call pon_sprite_sparkie		;02e3   ; su sprite
	call borra_ola		;02e6   ; sin agua ni disparos
	ld b,00bh		;02e9   ; la ocupacion de las 11 franjas, a 1
	ld hl,0e04eh		;02eb
	ld a,001h		;02ee
	call rellena		;02f0
	ld b,00bh		;02f3   ; los 11 enemigos de 0xE1E4
	ld ix,0e1e4h		;02f5
L_02F9:
	push bc			;02f9
	rst 30h			;02fa   ; donde esta
	ld a,(ix+020h)		;02fb   ; los que tienen vida...
	and 003h		;02fe
	jr z,L_0305		;0300
	call entra_en_franja		;0302   ; ...se apuntan en su franja
L_0305:
	inc ix		;0305
	inc ix		;0307
	pop bc			;0309
	djnz L_02F9		;030a
	call silencio		;030c   ; silencio
	call musica_de_fase		;030f   ; la musica de la fase
	ld a,007h		;0312   ; siete llamas encendidas, de entrada
	ld (0e044h),a		;0314
	ld hl,00000h		;0317   ; el reloj de la fase a cero
	ld (0e047h),hl		;031a
	xor a			;031d   ; ningun muro abriendose
	ld (0e252h),a		;031e
	ld l,000h		;0321   ; la puntuacion, sin sumar nada
	call suma_puntos		;0323
	ld de,0131ah		;0326   ; la fase en X 0x1A, Y 0x13
	ld a,(0e250h)		;0329   ; 0xE250 cuenta desde 0
	inc a			;032c
	ld l,a			;032d
	call pinta_dos_cifras		;032e
pinta_vidas:		; Las vidas que quedan (menos la que se juega), salvo en la demostracion
	ld a,(0e0a3h)		;0331   ; en la demostracion no
	rlca			;0334
	ret c			;0335
	ld de,00f1ah		;0336   ; en X 0x1A, Y 0x0F
	ld a,(0e24fh)		;0339   ; las vidas...
	dec a			;033c   ; ...menos la que se esta jugando
	ld l,a			;033d
pinta_dos_cifras:		; L en decimal con 0x1846 y dos casillas en blanco detras
	ld h,000h		;033e
	push de			;0340
	call pinta_cifras		;0341   ; las cifras
	pop de			;0344
	xor a			;0345   ; y dos casillas en blanco
	call pinta_casilla		;0346
	inc e			;0349
	jp pinta_casilla		;034a
borra_pantalla:		; La pantalla en blanco desde la fila D
	ld e,000h		;034d
borra_desde:		; Casilla a casilla, en blanco, hasta la fila 24
	xor a			;034f   ; casilla vacia
	call pinta_casilla		;0350
	ld a,01eh		;0353   ; 30 por fila (con el marcador)
	call siguiente_casilla		;0355
	jr nz,borra_desde		;0358
sprites_fuera:		; Los 31 sprites a Y 0xC0 (fuera) y el 0xD0 que corta la lista, a la VRAM
	ld hl,0e4b0h		;035a   ; la copia de la tabla de sprites
	ld b,000h		;035d   ; el sprite 0
L_035F:
	ld (hl),0c0h		;035f   ; Y 0xC0: debajo de la pantalla
	inc hl			;0361
	ld (hl),0ffh		;0362   ; X
	inc hl			;0364
	ld a,b			;0365   ; el patron: 4 * numero
	rlca			;0366
	rlca			;0367
	ld (hl),a			;0368
	inc hl			;0369
	ld (hl),000h		;036a   ; color 0
	inc hl			;036c
	inc b			;036d
	ld a,b			;036e
	cp 01fh		;036f   ; 31 sprites
	jr nz,L_035F		;0371
	ld (hl),0d0h		;0373   ; y el 0xD0 que acaba la lista
	ld de,07b00h		;0375   ; a la tabla de atributos (0x3B00)
	ld hl,0e4b0h		;0378
	ld b,07dh		;037b   ; 125 bytes
	rst 18h			;037d
	rst 20h			;037e
	ret			;037f

; ----------------------------------------------------------------------
; DATOS rotulos_del_marcador: ocho rotulos (formato de 0x0288): "1P", "HIGH",
;   "REST", "STAGE", "00", "00", "2P" y "00". 0x0381 y 0x03AC son los de "1P"
;   y "2P" sin su color: la interrupcion los pinta con el del parpadeo
;   0x0380..0x03b7  (55 bytes)
DATA_rotulos_del_marcador:
	defb 0f1h,018h,001h,002h	; 0380
	defb 009h,01bh	; 0384
	defb 081h,018h,009h,004h	; 0386
	defb 018h,007h,017h,018h	; 038a
	defb 0f1h,018h,00dh,004h	; 038e
	defb 01ch,015h,01dh,01eh	; 0392
	defb 0f1h,018h,011h,005h	; 0396
	defb 01dh,01eh,005h,017h,015h	; 039a
	defb 0f1h,01ch,003h,002h	; 039f
	defb 008h,008h	; 03a3
	defb 0f1h,01ch,00bh,002h	; 03a5
	defb 008h,008h	; 03a9
	defb 0f1h,018h,005h,002h	; 03ab
	defb 00ah,01bh	; 03af
	defb 0f1h,01ch,007h,002h	; 03b1
	defb 008h,008h	; 03b5

; ----------------------------------------------------------------------
; DATOS textos_de_las_opciones: los cuatro rotulos del menu (0x1952, 0x1973,
;   0x1994, 0x19B5): 0x025D pinta el de la opcion elegida
;   0x03b7..0x03bf  (8 bytes)
DATA_textos_de_las_opciones:
	defw 01952h,01973h,01994h,019b5h	; 03b7

; ======================================================================
; CODIGO 0x03bf..0x071e  (863 bytes)
; ======================================================================


siguiente_casilla:		; E + 1; al llegar a A, E = 0 y D + 1. Z cuando D llega a 24
	inc e			;03bf   ; la columna siguiente
	cp e			;03c0   ; se acaba la fila?
	ret nz			;03c1
	ld e,000h		;03c2   ; la primera columna...
	inc d			;03c4   ; ...de la fila siguiente
	ld a,d			;03c5
	cp 018h		;03c6   ; Z: las 24 filas hechas
	ret			;03c8

; ----------------------------------------------------------------------
; SPARKIE, en los cuadros impares. Con la ola en marcha solo avanza la ola. Si no, lee el mando: con el boton, junto a un cubo coge el agua, y si no dispara; con un sentido, gira si la casilla lo deja y avanza.
; ----------------------------------------------------------------------
mueve_sparkie:		; Sparkie: el mando, la ola, los disparos y el paso
	call lee_mando		;03c9   ; lee el mando (o la demostracion)
	ld hl,0e039h		;03cc   ; la ola: su punta
	ld d,(hl)			;03cf   ; la Y de la punta
	inc hl			;03d0
	ld a,d			;03d1
	or (hl)			;03d2   ; cero los dos: no hay ola
	jp nz,sigue_ola		;03d3   ; en marcha: un paso de la ola
	ld a,(0e0bdh)		;03d6   ; el sonido del bloque 2 (los disparos) sonando...
	or a			;03d9
	ret nz			;03da   ; ...y Sparkie no se mueve
	ld ix,0e002h		;03db   ; Sparkie
	rst 30h			;03df   ; su posicion
	call sentidos_libres		;03e0   ; que sentidos deja su casilla
	ld a,(0e00eh)		;03e3   ; el mando
	or a			;03e6
	ret z			;03e7   ; nada pulsado: quieto
	bit 3,a		;03e8   ; el boton
	jr nz,boton		;03ea
	ld hl,0e007h		;03ec   ; los sentidos libres
	and (hl)			;03ef   ; lo pedido que se puede
	and 0f0h		;03f0
	jr nz,L_03F8		;03f2   ; algo: eso
	ld a,(0e004h)		;03f4   ; si no, seguir como iba, si se puede
	and (hl)			;03f7
L_03F8:
	jp po,L_03FD		;03f8   ; dos sentidos a la vez (paridad par)...
	and 0c0h		;03fb   ; ...se queda el vertical
L_03FD:
	ld (0e008h),a		;03fd   ; el sentido elegido
	or a			;0400
	ret z			;0401   ; ninguno: quieto
	and 0f0h		;0402
	ld b,a			;0404
	ld hl,0e004h		;0405   ; al nibble alto de 0xE004
	ld a,(hl)			;0408
	and 00fh		;0409
	or b			;040b
	ld (hl),a			;040c
	rst 30h			;040d   ; donde estaba
	ld a,002h		;040e   ; dos puntos por paso
	ld (0e06eh),a		;0410
	call da_paso		;0413   ; un paso
	call casilla_de_debajo		;0416   ; la casilla de debajo...
	ld a,001h		;0419   ; ...queda pintada (1)
	call pinta_bloque		;041b
pon_sprite_sparkie:		; El sprite de Sparkie, a la tabla de la VRAM
	jp sprite_sparkie		;041e
boton:		; El boton: el cubo de delante o los disparos
	rst 30h			;0421   ; la posicion...
	call a_casillas		;0422   ; ...en casillas
	ld a,(0e004h)		;0425   ; hacia donde mira
	ld b,002h		;0428   ; dos casillas mas alla
	call mueve_de		;042a
	ld hl,0e1bch		;042d   ; hay uno de los tres cubos?
	ld b,003h		;0430
	call busca_posicion		;0432
	or a			;0435
	jp z,dispara		;0436   ; no: dispara
	dec a			;0439   ; el cubo (0-2)
	ld (0e037h),a		;043a
	ld hl,0e1bch		;043d   ; su posicion
	call palabra		;0440
	push de			;0443
	xor a			;0444   ; sus cuatro casillas, a pasillo
	call pinta_bloque		;0445
	pop de			;0448
	push hl			;0449
	ld a,003h		;044a   ; su estado (6 bytes despues)
	rst 10h			;044c
	res 3,(hl)		;044d   ; fuera de juego
	pop hl			;044f
	xor a			;0450   ; y su posicion a cero
	ld (hl),a			;0451
	inc hl			;0452
	ld (hl),a			;0453
	call zumbido		;0454   ; el sonido
	ld ix,0e039h		;0457   ; la ola sale de la casilla del cubo
	call pon_posicion		;045b
paso_de_ola:		; La ola avanza una casilla en sentido contrario al que mira Sparkie (del cubo hacia el), hasta 10 o hasta un muro
	call libres_en_casilla		;045e   ; los sentidos libres en la punta
	ld a,(0e004h)		;0461   ; hacia donde mira Sparkie
	call bit_de_sentido		;0464   ; el contrario, de la tabla de 0x14D6
	ld a,(0e007h)		;0467   ; lo libre en la punta
	and (hl)			;046a   ; se puede seguir hacia ahi?
	jr z,acaba_ola		;046b   ; no: la ola se acaba
	ld hl,01efbh		;046d   ; el dibujo de la ola, segun ese sentido
	call dibujo_y_casilla		;0470   ; y la casilla siguiente
	ld a,0f5h		;0473   ; blanco sobre azul
	call pinta_objeto		;0475
	ld a,(0e038h)		;0478   ; apuntada en la lista de 0xE00F
	ld hl,0e00fh		;047b
	rst 10h			;047e   ; HL = 0xE00F + 2 * casillas hechas
	ld (hl),e			;047f   ; la X
	inc hl			;0480
	ld (hl),d			;0481   ; la Y
	inc hl			;0482
	ld hl,0e038h		;0483   ; una casilla mas
	inc (hl)			;0486   ; una mas
	ld ix,0e039h		;0487   ; la punta nueva
	call pon_posicion		;048b
	ld a,003h		;048e   ; la carga de Sparkie, entera (3)
	ld hl,0e004h		;0490   ; al estado de Sparkie
	or (hl)			;0493
	ld (hl),a			;0494
	inc hl			;0495   ; y su cuenta, a cero
	xor a			;0496
	ld (hl),a			;0497
	ret			;0498
bit_de_sentido:		; HL = la entrada de 0x14D6 del primer bit puesto de A
	ld hl,014d5h		;0499   ; 0x14D6 - 1
L_049C:
	inc hl			;049c   ; la siguiente
	rlca			;049d   ; hasta el primer bit a uno
	jr nc,L_049C		;049e
	ret			;04a0
dibujo_y_casilla:		; Segun el sentido (A): HL + 32 por cada sentido que se salta, y DE a la casilla de al lado
	ld bc,00020h		;04a1   ; 32 bytes por dibujo
	dec d			;04a4   ; arriba: Y - 1
	rlca			;04a5
	ret c			;04a6
	inc d			;04a7   ; abajo: Y + 1
	inc d			;04a8
	add hl,bc			;04a9
	rlca			;04aa
	ret c			;04ab
	dec d			;04ac   ; izquierda: X - 1
	dec e			;04ad
	add hl,bc			;04ae
	rlca			;04af
	ret c			;04b0
	inc e			;04b1   ; derecha: X + 1
	inc e			;04b2
	add hl,bc			;04b3
	ret			;04b4
puede_seguir:		; Z si la casilla de DE no deja seguir hacia donde mira Sparkie
	call sentidos_libres		;04b5   ; los sentidos libres
	push bc			;04b8
	ld a,(0e004h)		;04b9   ; el de Sparkie
	and 0f0h		;04bc
	ld b,a			;04be
	ld a,(0e007h)		;04bf   ; los dos a la vez
	and b			;04c2
	pop bc			;04c3
	ret			;04c4
acaba_ola:		; Borra las 20 casillas de la ola, para su sonido y vuelve la musica
	ld hl,0e00fh		;04c5   ; las casillas de la ola
	ld b,014h		;04c8   ; 20
	call repinta_lista		;04ca   ; repintadas como estaban
	call calla_bloque2		;04cd   ; el bloque 2, en silencio
	call musica_de_fase		;04d0   ; la musica, otra vez
borra_ola:		; 0xE00F-0xE03A a cero: la ola y los disparos
	ld b,02ch		;04d3   ; 44 bytes
	ld hl,0e00fh		;04d5
	xor a			;04d8
	jp rellena		;04d9
sigue_ola:		; La ola en marcha: un paso desde su punta
	ld ix,0e039h		;04dc   ; la punta
	rst 30h			;04e0
	jp paso_de_ola		;04e1
dispara:		; Cuatro disparos seguidos delante de Sparkie, mientras la casilla deje
	rst 30h			;04e4
	call puede_seguir		;04e5   ; se puede disparar hacia ahi?
	ret z			;04e8   ; no se puede: nada
	ld hl,01cfbh		;04e9   ; el sonido del disparo
	ld (0e0bch),hl		;04ec   ; al bloque 2
	xor a			;04ef
	ld (0e0c1h),a		;04f0   ; sin envolvente
	rst 30h			;04f3
	call casilla_de_debajo		;04f4   ; la casilla de debajo
	ld b,004h		;04f7   ; cuatro
	ld hl,0e03bh		;04f9   ; sus posiciones, en 0xE03B
L_04FC:
	push bc			;04fc
	push hl			;04fd
	push de			;04fe
	call a_puntos		;04ff   ; a puntos
	call puede_seguir		;0502   ; sigue habiendo paso?
	pop de			;0505
	jr z,L_051C		;0506   ; no: aqui se acaba
	ld hl,01f7bh		;0508   ; el dibujo del disparo, segun el sentido
	call dibujo_y_casilla		;050b
	ld a,0f0h		;050e   ; blanco
	call pinta_objeto		;0510
	pop hl			;0513
	pop bc			;0514
	ld (hl),e			;0515   ; apuntado
	inc hl			;0516
	ld (hl),d			;0517
	inc hl			;0518
	djnz L_04FC		;0519
	ret			;051b
L_051C:
	pop hl			;051c
	pop bc			;051d
	ret			;051e
carga_de_sparkie:		; La carga de Sparkie: sin la entera se gasta un punto cada 87 cuadros impares (de 0x80 a 0xD7, el bit 7 es la marca del aviso), y a cero muere
	ld hl,0e004h		;051f   ; el estado de Sparkie
	push hl			;0522
	pop ix		;0523
	call bits_bajos_a_3		;0525   ; carga entera (3)?
	jp z,cola_entera		;0528   ; si: solo el sprite
	inc hl			;052b   ; la cuenta, en 0xE005
	bit 7,(hl)		;052c   ; el aviso ya ha sonado?
	jr nz,L_0540		;052e
	ld a,(0e0a3h)		;0530   ; en la demostracion no suena
	rrca			;0533
	jr c,L_0540		;0534
	set 7,(hl)		;0536   ; marcado
	push hl			;0538
	ld hl,01cdfh		;0539   ; el aviso de la carga baja
	call musica_de_aviso		;053c
	pop hl			;053f
L_0540:
	ld a,(hl)			;0540   ; la cuenta llega a 0xD7? (87 pasos desde 0x80)
	cp 0d7h		;0541
	jr nz,L_0553		;0543
	ld a,080h		;0545   ; se vuelve a empezar desde 0x80, con la marca
	and (hl)			;0547
	ld (hl),a			;0548
	dec hl			;0549
	ld a,(hl)			;054a   ; la carga
	and 003h		;054b
	jr z,L_0557		;054d   ; a cero: Sparkie se apaga
	dec (hl)			;054f   ; un punto menos
L_0550:
	jp cola_gastada		;0550   ; y su sprite
L_0553:
	inc (hl)			;0553   ; un cuadro mas
	dec hl			;0554
	jr L_0550		;0555
L_0557:
	res 3,(hl)		;0557   ; la carga a cero: Sparkie muerto
	ret			;0559
casilla_de_debajo:		; DE (puntos) + 4, a casillas: la casilla sobre la que esta el objeto
	ld a,e			;055a   ; X + 4
	add a,004h		;055b
	ld e,a			;055d
	ld a,d			;055e   ; Y + 4
	add a,004h		;055f
	ld d,a			;0561
	jp a_casillas		;0562   ; a casillas

; ----------------------------------------------------------------------
; LAS CINCO LLAMAS (0xE1C8, estado en 0xE1D2: bit 3 encendida, bits 0-1 su tamano; cuenta en 0xE1D3). Cada disparo que la toca le quita un punto; con menos de cinco enemigos en juego, cada 128 pasos pierde otro; si no esta entera, cada 128 pasos crece uno. A cero se apaga (300 puntos). La llama entera mata a Sparkie si la toca.
; ----------------------------------------------------------------------
mueve_llamas:		; Las cinco llamas: tamano, disparos, dibujo
	ld a,005h		;0565   ; cinco
	ld ix,0e1c8h		;0567   ; sus posiciones
	ld hl,0e1d2h		;056b   ; y sus estados
L_056E:
	push af			;056e
	bit 3,(hl)		;056f   ; encendida?
	jr z,L_05D5		;0571
	ld a,(0e044h)		;0573   ; cuantos enemigos hay
	cp 005h		;0576
	jr nc,L_0584		;0578   ; cinco o mas: no se gasta
	call cuenta_hasta_128		;057a   ; la cuenta llega a 128?
	jr nz,L_0584		;057d
	ld (ix+00bh),000h		;057f   ; se vuelve a empezar
	dec (hl)			;0583   ; y la llama baja un punto
L_0584:
	push hl			;0584
	rst 30h			;0585   ; donde esta
	call toca_disparo		;0586   ; la toca un disparo?
	pop hl			;0589
	dec a			;058a
	jr nz,L_058E		;058b
	dec (hl)			;058d   ; si: un punto menos
L_058E:
	ld a,003h		;058e   ; le queda tamano?
	and (hl)			;0590
	jr nz,L_05A1		;0591
	res 3,(hl)		;0593   ; no: apagada
	push hl			;0595
	ld l,003h		;0596   ; 300 puntos (la cifra va por centenas)
	call suma_puntos		;0598
	rst 30h			;059b
	call repinta_uno		;059c   ; y sus casillas, repintadas
	jr L_05D4		;059f
L_05A1:
	call bits_bajos_a_3		;05a1   ; entera?
	push hl			;05a4
	jr z,L_05B1		;05a5
	call cuenta_hasta_128		;05a7   ; no: crece cada 128 pasos
	jr nz,L_05B1		;05aa
	ld (ix+00bh),000h		;05ac
	inc (hl)			;05b0   ; un punto mas
L_05B1:
	ld a,(hl)			;05b1   ; el tamano
	and 003h		;05b2
	ld b,a			;05b4
	dec b			;05b5   ; 1: la pequena
	ld hl,01326h		;05b6
	ld a,0e0h		;05b9
	jr z,L_05D0		;05bb
	dec b			;05bd   ; 2: la mediana
	ld a,0e0h		;05be
	ld hl,012aeh		;05c0
	jr z,L_05D0		;05c3
	push hl			;05c5   ; 3: la grande...
	call toca_a_sparkie_casilla		;05c6   ; ...toca a Sparkie?
	or a			;05c9
	call nz,mata_sparkie		;05ca   ; y lo mata
	ld a,060h		;05cd   ; en rojo
	pop hl			;05cf
L_05D0:
	rst 30h			;05d0
	call pinta_objeto		;05d1   ; se dibuja
L_05D4:
	pop hl			;05d4
L_05D5:
	inc ix		;05d5   ; la llama siguiente
	inc ix		;05d7
	inc hl			;05d9
	inc hl			;05da
	pop af			;05db
	dec a			;05dc
	jp nz,L_056E		;05dd
	ret			;05e0
cuenta_hasta_128:		; Suma uno a la cuenta de HL+1; Z cuando llega a 0x80
	inc hl			;05e1
	inc (hl)			;05e2   ; un paso mas
	ld a,080h		;05e3   ; 128?
	cp (hl)			;05e5
	dec hl			;05e6
	ret			;05e7

; ----------------------------------------------------------------------
; EL PREMIO (0xE21C, estado en 0xE21E, cuenta en 0xE21F). Sale en su casilla cuando solo queda un cubo, se queda 255 pasos, y si Sparkie lo toca da 1.000 puntos por fase (10.000 a partir de la decima).
; ----------------------------------------------------------------------
premio:		; El premio del laberinto: cuando sale, su dibujo y quien lo coge
	ld ix,0e21ch		;05e8   ; el premio
	rst 30h			;05ec   ; su casilla
	bit 3,(ix+002h)		;05ed   ; fuera?
	jr z,premio_sale		;05f1
	inc (ix+003h)		;05f3   ; un paso mas en pantalla
	ld a,0f0h		;05f6   ; blanco
	ld hl,01346h		;05f8   ; sus cuatro casillas
	call pinta_casilla		;05fb
	inc de			;05fe
	ld hl,01356h		;05ff
	call pinta_casilla		;0602
	dec de			;0605
	inc d			;0606
	ld a,0a0h		;0607   ; la mitad de abajo en amarillo
	ld hl,0134eh		;0609
	call pinta_casilla		;060c
	inc de			;060f
	ld hl,012ceh		;0610
	call pinta_casilla		;0613
	ld a,(ix+003h)		;0616   ; se acaba el tiempo?
	cp 0ffh		;0619
	jr z,L_0630		;061b
	call toca_a_sparkie_casilla		;061d   ; Sparkie lo toca?
	or a			;0620
	ret z			;0621
	ld hl,01cefh		;0622   ; su sonido
	ld (0e0c4h),hl		;0625
	ld a,003h		;0628
	ld (0e0c9h),a		;062a
	call puntos_premio		;062d   ; y los puntos
L_0630:
	rst 30h			;0630   ; se borra
	call repinta_uno		;0631
	ld (ix+002h),080h		;0634   ; y no vuelve
	ret			;0638
premio_sale:		; El premio sale cuando solo queda uno de los tres cubos
	bit 7,(ix+002h)		;0639   ; ya ha salido?
	ret nz			;063d
	xor a			;063e   ; cuantos cubos quedan
	ld hl,0e1c2h		;063f
	ld b,003h		;0642
	call cuenta_bit3		;0644
	dec a			;0647   ; uno?
	ret nz			;0648
	set 3,(ix+002h)		;0649   ; sale
	ret			;064d
mata_sparkie:		; Sparkie muerto: bit 3 de 0xE004 a cero
	ld hl,0e004h		;064e   ; el estado de Sparkie
	res 3,(hl)		;0651   ; ya no esta vivo
	ret			;0653

; ----------------------------------------------------------------------
; LOS ENEMIGOS: 13 huecos de 2 bytes desde 0xE1DC (su estado, 0x20 bytes mas alla: bit 3 vivo, bits 0-1 la vida, bit 2 despedido). Se mueven por tandas de cuatro desde IX, una tanda por llamada; A dice cual (1, 2, 4 u 8, a 0xE006), y la tanda 8 tiene uno solo. Los de la tanda 1 son las llamitas que suelta una llama grande; los demas, los del laberinto y los que salen de los bloques que arden. La ola los apaga (1.000 puntos); el que toca a Sparkie lo mata, y el que toca su cola le quita carga.
; ----------------------------------------------------------------------
mueve_enemigos:		; Una tanda de hasta cuatro enemigos desde IX
	ld (0e006h),a		;0654   ; la tanda
	xor a			;0657   ; el primero
L_0658:
	push af			;0658
un_enemigo:		; Un enemigo: nacer, apagarse, chocar, perseguir
	call tanda_1		;0659   ; tanda 1?
	jr nc,L_0665		;065c
	bit 3,(ix+020h)		;065e   ; y el hueco vacio...
	call z,suelta_llamita		;0662   ; ...una llama grande puede soltar una llamita
L_0665:
	bit 3,(ix+020h)		;0665   ; vivo?
	jp z,siguiente_enemigo		;0669
	call toca_la_ola		;066c   ; la punta de la ola lo toca?
	or a			;066f
	jr z,L_0684		;0670
	rst 30h			;0672   ; si: fuera de su franja
	call sale_de_franja		;0673
	call sprite_fuera		;0676   ; su sprite fuera
	res 3,(ix+020h)		;0679   ; apagado
	ld l,00ah		;067d   ; 1.000 puntos
	call suma_puntos		;067f
	jr siguiente_enemigo		;0682
L_0684:
	call tanda_1		;0684   ; tanda 1?
	jr nc,L_0692		;0687
	bit 0,(ix+020h)		;0689   ; la llamita sin el bit 0...
	jp z,sin_vida		;068d
	jr L_0698		;0690
L_0692:
	call vida_entera		;0692   ; los demas, con la vida a medias...
	jp c,herido		;0695   ; ...se quedan quietos (0x0765)
L_0698:
	call toca_la_cola		;0698   ; toca la cola de Sparkie?
	or a			;069b
	jp nz,quita_carga		;069c   ; si: le quita carga
	call toca_a_sparkie		;069f   ; toca a Sparkie?
	or a			;06a2
	jr z,L_06AE		;06a3
	call tanda_1		;06a5   ; las llamitas no matan...
	jp c,L_06AE		;06a8
	call mata_sparkie		;06ab   ; ...los demas si
L_06AE:
	call tanda_1		;06ae   ; las llamitas a 2 puntos por paso...
	ld a,002h		;06b1
	jr c,L_06B7		;06b3
	ld a,001h		;06b5   ; ...los demas a 1
L_06B7:
	ld hl,(0e047h)		;06b7   ; pasados 2048 cuadros de la fase...
	bit 3,h		;06ba
	jr z,L_06CA		;06bc
	rlc h		;06be   ; ...y con el bit 7 de 0xE048...
	jr c,L_06C8		;06c0
	rst 30h			;06c2
	push af			;06c3
	call ajusta_a_casilla		;06c4   ; ...se ajusta a su casilla
	pop af			;06c7
L_06C8:
	ld a,002h		;06c8   ; y todos a 2
L_06CA:
	ld (0e06eh),a		;06ca   ; la velocidad
	rst 30h			;06cd
	call elige_sentido		;06ce   ; hacia Sparkie
	rst 30h			;06d1
	ld a,(0e009h)		;06d2   ; el sentido elegido
	ld (0e008h),a		;06d5
	and 0f0h		;06d8
	ld b,a			;06da
	ld a,(ix+020h)		;06db   ; al nibble alto de su estado
	and 00fh		;06de
	or b			;06e0
	ld (ix+020h),a		;06e1
	call da_paso		;06e4   ; un paso
	call sprite_enemigo		;06e7   ; y su sprite
siguiente_enemigo:		; El siguiente de la tanda; la tanda 8 tiene uno solo, y con la vida entera pinta la casilla que pisa
	ld a,(0e006h)		;06ea   ; la tanda 8?
	bit 3,a		;06ed
	jr z,L_0704		;06ef
	pop af			;06f1
	bit 3,(ix+020h)		;06f2   ; vivo?
	ret z			;06f6
	call vida_entera		;06f7   ; con la vida a medias no pinta
	ret c			;06fa
	rst 30h			;06fb
	call casilla_de_debajo		;06fc   ; la casilla de debajo...
	ld a,001h		;06ff   ; ...queda pintada (1): el de la tanda 8 pinta el suelo como Sparkie
	jp pinta_bloque		;0701
L_0704:
	inc ix		;0704   ; el siguiente hueco
	inc ix		;0706
	pop af			;0708
	ld hl,0e006h		;0709
	inc a			;070c   ; el cuarto ya?
	cp 004h		;070d
	ret z			;070f
	push af			;0710
	call por_16		;0711   ; su numero, al nibble alto de 0xE006
	ld b,a			;0714
	ld a,(hl)			;0715
	and 00fh		;0716
	or b			;0718
	ld (hl),a			;0719
	pop af			;071a
	jp L_0658		;071b   ; y otra vuelta

; ----------------------------------------------------------------------
; DATOS dec_sin_uso_071E: `dec (ix+20h)` detras del `jp 0x0658`: no salta
;   nadie aqui (0x0721 se llama por su etiqueta)
;   0x071e..0x0721  (3 bytes)
DATA_dec_sin_uso_071E:
	defb 0ddh,035h,020h	; 071e

; ======================================================================
; CODIGO 0x0721..0x0a73  (850 bytes)
; ======================================================================


enemigo_herido:		; El enemigo herido, quieto: blanco con un punto de vida, azul claro con dos
	call vida_entera		;0721   ; cuanta vida
	dec a			;0724
	ld a,00fh		;0725   ; uno: blanco
	jr z,L_072B		;0727
	ld a,007h		;0729   ; dos: azul claro
L_072B:
	ld (0e04dh),a		;072b   ; el color forzado
	call sprite_enemigo		;072e   ; el sprite
L_0731:
	jr $-71		;0731   ; al siguiente
sprite_fuera:		; El sprite del enemigo A (o de Sparkie con 0x10) fuera de la pantalla
	ld a,(0e006h)		;0733
sprite_fuera_a:		; Lo mismo con el tipo en A (0x10 Sparkie)
	rst 30h			;0736   ; se guarda su posicion
	push de			;0737
	ld de,0c8ffh		;0738   ; X 0xFF, Y 0xC8: fuera de la pantalla
	call pon_posicion		;073b
	cp 010h		;073e   ; Sparkie?
	jr nz,L_0747		;0740
	call sprite_sparkie		;0742   ; su sprite
	jr L_074A		;0745
L_0747:
	call sprite_enemigo		;0747   ; el del enemigo
L_074A:
	pop de			;074a   ; la posicion de antes
	jp pon_posicion		;074b
sin_vida:		; El enemigo sin vida: la primera vez da puntos y toma el sentido de Sparkie; luego vuela hasta chocar (0x0CAC)
	bit 2,(ix+020h)		;074e   ; ya volando?
	jr nz,L_0760		;0752
	call despedido		;0754   ; a su casilla y con el sentido de Sparkie
	set 2,(ix+020h)		;0757   ; marcado
	call puntos_despedido		;075b   ; 100 o 200 puntos
	jr L_0731		;075e
L_0760:
	call vuela		;0760   ; sigue volando
	jr L_0731		;0763
herido:		; Con la vida a medias el enemigo se queda quieto; cada 50 pasos recupera un punto, y con la vida entera vuelve a su casilla y a moverse
	or a			;0765   ; sin vida: sale despedido
	jr z,sin_vida		;0766
	ld a,(ix+021h)		;0768   ; la cuenta
	cp 032h		;076b   ; 50?
	jr z,L_0775		;076d
	inc (ix+021h)		;076f   ; un paso mas
	jp enemigo_herido		;0772
L_0775:
	xor a			;0775   ; a cero
	ld (ix+021h),a		;0776
	inc (ix+020h)		;0779   ; un punto de vida mas
	call vida_entera		;077c   ; ya entera?
	jr nz,herido		;077f
	call ajusta_a_casilla		;0781   ; a su casilla
	jp un_enemigo		;0784
quita_carga:		; Un enemigo en la cola de Sparkie: con la carga entera le quita un punto
	ld hl,0e004h		;0787   ; la carga de Sparkie
	call bits_bajos_a_3		;078a   ; entera?
	jp nz,L_06AE		;078d
	dec (hl)			;0790   ; un punto menos
	jr L_0731		;0791
tanda_1:		; Acarreo si la tanda que se mueve es la 1 (las llamitas)
	ld a,(0e006h)		;0793
	rrca			;0796
	ret			;0797
vida_entera:		; Z si los bits 0-1 del estado del enemigo (IX+0x20) estan a 3
	ld a,(ix+020h)		;0798
	jr bits_a_3		;079b
bits_bajos_a_3:		; Z si los bits 0-1 de (HL) estan a 3
	ld a,(hl)			;079d
bits_a_3:		; Z si los bits 0-1 de A estan a 3
	and 003h		;079e   ; los bits 0-1
	cp 003h		;07a0   ; a 3?
	ret			;07a2

; ----------------------------------------------------------------------
; LOS BLOQUES QUE ARDEN. Con menos de cinco enemigos, en los cuadros con el bit 5 de la cuenta, se elige al azar (registro R) una de las cuatro listas de 0xE220 que no haya ardido aun (mascara 0xE251). Sus bloques parpadean en rojo y amarillo durante 128 cuadros, se vuelven pasillo y de la primera casilla sale un enemigo.
; ----------------------------------------------------------------------
bloques_que_arden:		; Elige una lista de bloques, los hace parpadear y suelta un enemigo
	ld a,(0e252h)		;07a3   ; ya hay una ardiendo?
	or a			;07a6
	jr nz,bloques_parpadean		;07a7
	ld a,(0e044h)		;07a9   ; cinco enemigos o mas: nada
	cp 005h		;07ac
	ret nc			;07ae
	ld a,(0e047h)		;07af   ; solo en los cuadros con el bit 5
	bit 5,a		;07b2
	ret z			;07b4
	ld hl,0e251h		;07b5   ; las listas que quedan
	ld a,r		;07b8   ; al azar
	and (hl)			;07ba
	ret z			;07bb   ; ninguna: nada
	ld d,080h		;07bc   ; D va marcando la lista
	ld b,a			;07be
	ld a,0fbh		;07bf   ; 0xFB + 5: la lista 0 empieza en 0xE220 (10 bytes cada una)
	ld c,005h		;07c1
L_07C3:
	add a,c			;07c3   ; cinco bytes mas por lista
	rlc d		;07c4
	rrc b		;07c6   ; el primer bit puesto del azar
	jr nc,L_07C3		;07c8
	ld c,a			;07ca
	ld a,d			;07cb   ; esa lista...
	xor 0ffh		;07cc
	and (hl)			;07ce   ; ...ya no vuelve a salir
	ld (hl),a			;07cf
	ld a,c			;07d0
	ld hl,0e220h		;07d1   ; su direccion
	rst 10h			;07d4
	ld (0e253h),hl		;07d5
bloques_parpadean:		; La cuenta de la lista que arde: parpadea cada 16 cuadros, y a los 128 se abre
	ld hl,0e252h		;07d8   ; un paso mas
	inc (hl)			;07db
	ld a,(hl)			;07dc
	cp 080h		;07dd   ; 128?
	jr z,bloques_abiertos		;07df
	ld a,(0e047h)		;07e1   ; cada 16 cuadros
	ld b,a			;07e4
	and 00fh		;07e5
	ret nz			;07e7
	bit 4,b		;07e8   ; rojo sobre amarillo...
	ld a,06ah		;07ea
	jr z,L_07F0		;07ec
	ld a,0a6h		;07ee   ; ...o amarillo sobre rojo
L_07F0:
	ld c,a			;07f0
	ld a,002h		;07f1   ; los bloques (2) con ese color
	jp pinta_lista		;07f3
bloques_abiertos:		; Los bloques de la lista, a pasillo (0), y un enemigo en el primer hueco libre de los cuatro de 0xE1E8
	xor a			;07f6   ; la cuenta a cero
	ld (0e252h),a		;07f7
	call pinta_lista		;07fa   ; a pasillo
	ld b,004h		;07fd   ; cuatro huecos
	ld ix,0e1e8h		;07ff
L_0803:
	bit 3,(ix+020h)		;0803   ; ocupado?
	jr z,L_0810		;0807
	inc ix		;0809
	inc ix		;080b
	djnz L_0803		;080d
	ret			;080f
L_0810:
	ld a,04bh		;0810   ; vivo, con la vida entera y mirando abajo
	ld (ix+020h),a		;0812
	ld e,(hl)			;0815   ; en la primera casilla de la lista
	inc hl			;0816
	ld d,(hl)			;0817
	call a_puntos		;0818   ; a puntos
	call pon_posicion		;081b
	jp entra_en_franja		;081e   ; y en su franja
pinta_lista:		; Las casillas de la lista de 0xE253 (hasta cinco) con el valor A y el color C
	ld hl,(0e253h)		;0821
	push hl			;0824
	ld d,a			;0825
	ld b,005h		;0826   ; cinco como mucho
L_0828:
	push af			;0828
	ld a,(hl)			;0829
	or a			;082a   ; un cero la acaba
	jr nz,L_0830		;082b
	pop af			;082d
	jr L_083C		;082e
L_0830:
	ld e,a			;0830   ; su casilla
	inc hl			;0831
	ld d,(hl)			;0832
	inc hl			;0833
	pop af			;0834
	push bc			;0835
	call pinta_bloque		;0836   ; sus cuatro casillas
	pop bc			;0839
	djnz L_0828		;083a
L_083C:
	pop hl			;083c
	ret			;083d
elige_sentido:		; El sentido del enemigo hacia Sparkie: el que acerca, y si no se puede, otro al azar
	push de			;083e
	call sentidos_libres		;083f   ; los sentidos libres
	ld bc,(0e002h)		;0842   ; donde esta Sparkie
	pop de			;0846
	ld hl,0e009h		;0847
	ld a,c			;084a   ; la X
	cp e			;084b
	ld (hl),000h		;084c   ; misma columna: ninguno horizontal
	jr z,L_0856		;084e
	ld (hl),010h		;0850   ; derecha...
	jr nc,L_0856		;0852
	ld (hl),020h		;0854   ; ...o izquierda
L_0856:
	ld a,b			;0856   ; la Y
	cp d			;0857
	jr nz,L_0860		;0858
	ld a,030h		;085a   ; misma fila: ninguno vertical
	and (hl)			;085c
	ld (hl),a			;085d
	jr L_0868		;085e
L_0860:
	jr c,L_0866		;0860
	set 6,(hl)		;0862   ; abajo
	jr L_0868		;0864
L_0866:
	set 7,(hl)		;0866   ; arriba
L_0868:
	call sentido_del_enemigo		;0868   ; entre lo que acerca y lo libre
	ld a,(0e009h)		;086b
	and 0c0h		;086e
	ret z			;0870
	call franja_llena		;0871   ; en vertical: la franja de destino esta llena?
	or a			;0874
	call nz,otro_sentido		;0875   ; si: otro sentido
	ret			;0878
pinta_bloque:		; Las cuatro casillas de un objeto de 16x16 (DE, DE+1 en X, en Y) con el valor A
	call pon_casilla		;0879
	inc e			;087c   ; la de la derecha
	call pon_casilla		;087d
	inc d			;0880   ; la de abajo a la derecha
	call pon_casilla		;0881
	dec e			;0884   ; la de abajo
	call pon_casilla		;0885
	ret			;0888

; ----------------------------------------------------------------------
; UNA CASILLA: el valor A (0-3) a sus dos bits de 0xE12C y el dibujo a la pantalla. 0 pasillo (negro), 1 pintado (azul), 2 bloque (con el color de C), 3 muro (el dibujo de 0x1216, blanco sobre verde).
; ----------------------------------------------------------------------
pon_casilla:		; La casilla (E, D) a A en el mapa y en la pantalla
	push hl			;0889
	push bc			;088a
	push de			;088b
	push af			;088c
	call casilla_en_ram		;088d   ; su byte (DE) y su sitio en el byte (A, de 0 a 3)
	ld b,a			;0890   ; cuantas vueltas...
	inc b			;0891
	ld a,0fch		;0892   ; ...a la mascara de dos bits
	ld c,b			;0894
L_0895:
	rrca			;0895   ; dos bits por casilla
	rrca			;0896
	djnz L_0895		;0897
	ld b,c			;0899   ; C = la mascara
	ld c,a			;089a
	pop af			;089b   ; el valor nuevo
	push af			;089c
L_089D:
	rrca			;089d   ; a su sitio
	rrca			;089e
	djnz L_089D		;089f
	ld b,a			;08a1
	ld a,(de)			;08a2   ; el byte del mapa
	and c			;08a3   ; sin los dos bits viejos
	or b			;08a4   ; con los nuevos
	ld (de),a			;08a5
	pop af			;08a6
	pop de			;08a7
	pop bc			;08a8
	push af			;08a9
	ld b,011h		;08aa   ; pasillo: negro sobre negro
	ld hl,0120eh		;08ac   ; con el dibujo liso
	or a			;08af
	jr z,L_08C0		;08b0
	ld b,044h		;08b2   ; pintado: azul
	dec a			;08b4
	jr z,L_08C0		;08b5
	ld b,c			;08b7   ; bloque: el color que trae C
	dec a			;08b8
	jr z,L_08C0		;08b9
	ld b,0fch		;08bb   ; muro: blanco sobre verde
	ld hl,01216h		;08bd   ; con el dibujo del muro
L_08C0:
	ld a,b			;08c0
	call pinta_casilla		;08c1   ; a la pantalla
	pop af			;08c4
	pop hl			;08c5
	ret			;08c6
da_paso:		; Un paso del objeto IX en el sentido de 0xE008, llevando la cuenta de las franjas
	call sale_de_franja		;08c7   ; sale de su franja
	ld a,(0e008h)		;08ca   ; el sentido
	call mueve_a_velocidad		;08cd   ; tantos puntos como diga 0xE06E
	call pon_posicion		;08d0   ; la posicion nueva
entra_en_franja:		; Uno mas en la franja de dos filas de DE
	push de			;08d3
	push hl			;08d4
	call franja		;08d5
	inc (hl)			;08d8   ; uno mas
	jr L_08E1		;08d9
sale_de_franja:		; Uno menos en la franja de DE
	push de			;08db
	push hl			;08dc
	call franja		;08dd
	dec (hl)			;08e0   ; uno menos
L_08E1:
	pop hl			;08e1
	pop de			;08e2
	ret			;08e3
franja:		; HL = el contador de 0xE04E de la franja de DE: (fila + 2) / 2
	call a_casillas		;08e4   ; a casillas
	inc d			;08e7   ; la fila + 2...
	inc d			;08e8
	res 0,d		;08e9   ; ...par...
	rrc d		;08eb   ; ...entre dos
	ld b,d			;08ed
	ld hl,0e04eh		;08ee   ; 0xE04E + franja - 1
L_08F1:
	inc hl			;08f1
	djnz L_08F1		;08f2
	dec hl			;08f4
	ret			;08f5
mueve_a_velocidad:		; Mueve DE en el sentido de A tantos puntos como 0xE06E
	ex af,af'			;08f6
	ld a,(0e06eh)		;08f7   ; la velocidad
	ld b,a			;08fa
	ex af,af'			;08fb
mueve_de:		; Mueve DE B puntos en el sentido de A (bit 7 arriba, 6 abajo, 5 izquierda, 4 derecha)
	rlca			;08fc   ; arriba?
	jr nc,L_0903		;08fd
	ld a,d			;08ff
	sub b			;0900   ; Y - B
	ld d,a			;0901
	ret			;0902
L_0903:
	rlca			;0903   ; abajo?
	jr nc,L_090A		;0904
	ld a,d			;0906
	add a,b			;0907   ; Y + B
	ld d,a			;0908
	ret			;0909
L_090A:
	rlca			;090a   ; izquierda?
	jr nc,L_0911		;090b
	ld a,e			;090d
	sub b			;090e   ; X - B
	ld e,a			;090f
	ret			;0910
L_0911:
	ld a,e			;0911   ; derecha: X + B
	add a,b			;0912
	ld e,a			;0913
	ret			;0914

; ----------------------------------------------------------------------
; LOS TRES CUBOS (0xE1BC, estado en 0xE1C2): amarillos mientras Sparkie tiene la carga entera; si le falta, parpadean en blanco y magenta cada 4 cuadros.
; ----------------------------------------------------------------------
pinta_cubos:		; Los tres cubos con su color
	ld ix,0e1bch		;0915   ; sus posiciones
	xor a			;0919
pinta_un_cubo:		; Un cubo (IX) con su color
	push af			;091a
	bit 3,(ix+006h)		;091b   ; en juego?
	jr z,L_093E		;091f
	ld a,(0e004h)		;0921   ; la carga de Sparkie
	ld h,0a0h		;0924   ; amarillo
	call bits_a_3		;0926   ; entera?
	jr nc,L_0936		;0929
	ld a,(0e047h)		;092b   ; si no, el bit 2 de la cuenta...
	ld h,0d0h		;092e   ; ...magenta...
	bit 2,a		;0930
	jr z,L_0936		;0932
	ld h,0f0h		;0934   ; ...o blanco
L_0936:
	ld a,h			;0936
	ld hl,011e6h		;0937   ; el dibujo del cubo
	rst 30h			;093a   ; en su sitio
	call pinta_objeto		;093b
L_093E:
	pop af			;093e   ; el siguiente
	inc ix		;093f
	inc ix		;0941
	inc a			;0943
	cp 003h		;0944
	ret z			;0946
	jr pinta_un_cubo		;0947
franja_llena:		; A = 1 si la franja hacia donde va el enemigo (arriba o abajo) tiene ya cuatro
	rst 30h			;0949
franja_llena_de:		; Lo mismo desde DE
	call franja		;094a   ; la franja de ahora
	ld a,(0e009h)		;094d   ; el sentido
	dec hl			;0950   ; la de arriba...
	rlca			;0951
	jr c,L_0959		;0952
	inc hl			;0954   ; ...o la misma...
	rlca			;0955
	jr nc,L_0959		;0956
	inc hl			;0958   ; ...o la de abajo
L_0959:
	ld a,(hl)			;0959   ; cuantos hay
	cp 004h		;095a   ; menos de cuatro: A = 0
	ld a,000h		;095c
	ret c			;095e
	inc a			;095f   ; cuatro o mas: A = 1
	ret			;0960
otro_sentido:		; Un sentido libre que no sea el pedido, y si no hay, cualquiera libre
	ld a,(0e009h)		;0961   ; lo que no se habia pedido
	xor 0f0h		;0964
	ld b,a			;0966
	ld a,(0e007h)		;0967   ; entre lo libre
	and 0f0h		;096a
	and b			;096c
	or a			;096d
	jp nz,L_0974		;096e   ; hay algo
	ld a,(0e007h)		;0971   ; si no, lo libre
L_0974:
	ld (0e009h),a		;0974
	ret			;0977
toca_disparo:		; A = 1 si alguno de los cuatro disparos esta en la casilla DE
	ld b,004h		;0978   ; cuatro
	ld hl,0e03bh		;097a   ; las posiciones de los disparos
	call busca_posicion		;097d   ; esta DE?
	or a			;0980
	ret z			;0981
	ld a,001h		;0982
	ret			;0984

; ----------------------------------------------------------------------
; LLAMITAS: cada ocho cuadros pares, una llama grande al azar suelta una llamita en el hueco libre (si su franja no esta llena).
; ----------------------------------------------------------------------
suelta_llamita:		; Una llama grande al azar pone una llamita en el hueco IX
	ld a,(0e047h)		;0985   ; solo cuando los bits 1-3 de la cuenta estan a uno
	and 00eh		;0988
	cp 00eh		;098a
	ret nz			;098c
	ld hl,0e1d2h		;098d   ; los estados de las cinco llamas
	ld bc,00500h		;0990
L_0993:
	call bits_bajos_a_3		;0993   ; grande?
	jr nz,L_099B		;0996
	scf			;0998   ; si: un uno...
	jr L_099C		;0999
L_099B:
	xor a			;099b   ; ...si no, un cero
L_099C:
	rl c		;099c   ; al mapa de bits de C
	inc hl			;099e
	inc hl			;099f
	djnz L_0993		;09a0
	ld b,c			;09a2   ; las grandes
	ld a,r		;09a3   ; al azar
	and 01fh		;09a5
	and b			;09a7
	or a			;09a8
	ret z			;09a9   ; ninguna
	ld b,004h		;09aa   ; la primera del azar
L_09AC:
	rrca			;09ac
	jr c,L_09B1		;09ad
	djnz L_09AC		;09af
L_09B1:
	ld a,b			;09b1   ; su posicion
	ld hl,0e1c8h		;09b2
	call palabra		;09b5
	call a_puntos		;09b8   ; a puntos
	push de			;09bb
	xor a			;09bc   ; sin sentido
	ld (0e009h),a		;09bd
	call franja_llena_de		;09c0   ; su franja esta llena?
	pop de			;09c3
	or a			;09c4
	ret nz			;09c5   ; si: nada
	call pon_posicion		;09c6   ; la llamita, en la llama
	ld (ix+020h),019h		;09c9   ; viva, vida 1, mirando a la derecha
	jp entra_en_franja		;09cd   ; y en su franja

; ----------------------------------------------------------------------
; EL LABERINTO DE LA ROM (HL) A LA RAM. Los 72 primeros bytes son el mapa a un bit por casilla (24 filas de 3 bytes): cada bit sale doble, 00 pasillo o 11 muro. Detras: los tres cubos, las cinco llamas, los nueve enemigos, la casilla del premio, y los bloques por grupos separados por un cero (dos ceros acaban). Los grupos se copian a las cuatro listas de bloques que arden, diez bytes como mucho cada una: un grupo de mas de cinco bloques se parte (la cruz del laberinto 4: 5 y 4). Los cubos tapan cuatro casillas de muro, que se abren al cogerlos (0x0444).
; ----------------------------------------------------------------------
desempaqueta_laberinto:		; El laberinto de HL a 0xE12C, con sus objetos y sus bloques
	push hl			;09d0   ; el mapa de la RAM...
	xor a			;09d1
	ld hl,0e12ch		;09d2
	ld b,0f4h		;09d5   ; ...244 bytes...
	call rellena		;09d7   ; ...a cero
	pop hl			;09da
	ld de,0e12ch		;09db   ; el destino
	ex de,hl			;09de
	ld b,048h		;09df   ; 72 bytes de la ROM
L_09E1:
	ld c,008h		;09e1   ; ocho bits cada uno
	ld a,(de)			;09e3
L_09E4:
	rlca			;09e4   ; el bit
	jr nc,L_09EC		;09e5
	rl (hl)		;09e7   ; uno: entra un 1...
	scf			;09e9   ; ...y otro
	jr L_09EE		;09ea
L_09EC:
	rl (hl)		;09ec   ; cero: entra el 0...
L_09EE:
	rl (hl)		;09ee   ; ...y el que sale del primero, tambien 0
	dec c			;09f0   ; un bit menos
	ex af,af'			;09f1
	ld a,c			;09f2
	or a			;09f3
	jr z,L_09FE		;09f4
	cp 004h		;09f6   ; cuatro casillas hechas...
	jr nz,L_09FB		;09f8
	inc hl			;09fa   ; ...al byte siguiente
L_09FB:
	ex af,af'			;09fb
	jr L_09E4		;09fc
L_09FE:
	inc de			;09fe   ; el byte siguiente
	inc hl			;09ff
	djnz L_09E1		;0a00
	ex de,hl			;0a02
	ld bc,00006h		;0a03   ; los tres cubos
	ldir		;0a06
	ld de,0e1c8h		;0a08   ; las cinco llamas
	ld c,00ah		;0a0b
	ldir		;0a0d
	ld de,0e1e4h		;0a0f   ; los nueve enemigos
	ld c,012h		;0a12
	ldir		;0a14
	ld de,0e21ch		;0a16   ; la casilla del premio
	ld c,002h		;0a19
	ldir		;0a1b
	push hl			;0a1d   ; los bloques empiezan aqui
L_0A1E:
	ld a,(hl)			;0a1e   ; un byte
	inc hl			;0a1f
	or a			;0a20
	jr nz,L_0A28		;0a21   ; distinto de cero: la X
	ld a,(hl)			;0a23   ; cero: separa grupos
	inc hl			;0a24
	or a			;0a25
	jr z,L_0A34		;0a26   ; dos ceros: se acaba
L_0A28:
	ld e,a			;0a28   ; la X
	ld d,(hl)			;0a29   ; la Y
	inc hl			;0a2a
	ld c,0c3h		;0a2b   ; verde oscuro sobre verde
	ld a,002h		;0a2d   ; bloque (2)
	call pinta_bloque		;0a2f   ; sus cuatro casillas
	jr L_0A1E		;0a32
L_0A34:
	pop hl			;0a34   ; otra vez desde los bloques
	ld b,004h		;0a35   ; los cuatro primeros grupos...
	ld de,0e220h		;0a37   ; ...a 0xE220, de 10 en 10
	ex de,hl			;0a3a
L_0A3B:
	push bc			;0a3b
	push hl			;0a3c
	ld b,00ah		;0a3d   ; hasta diez bytes
L_0A3F:
	ld a,(de)			;0a3f
	inc de			;0a40
	ld (hl),a			;0a41
	inc hl			;0a42
	or a			;0a43   ; el cero tambien se copia y acaba el grupo
	jr z,L_0A48		;0a44
	djnz L_0A3F		;0a46
L_0A48:
	pop hl			;0a48   ; la lista siguiente
	ld a,005h		;0a49
	rst 10h			;0a4b
	pop bc			;0a4c
	djnz L_0A3B		;0a4d
	ld hl,0e1bch		;0a4f   ; los cubos con posicion: estado 8 (en juego)
	ld de,0e1c2h		;0a52
	ld bc,00308h		;0a55
	call pon_estados		;0a58
	ld hl,0e1c8h		;0a5b   ; las llamas con posicion: 0x0F (encendida y grande)
	ld de,0e1d2h		;0a5e
	ld bc,0050fh		;0a61
	call pon_estados		;0a64
	ld hl,0e1e4h		;0a67   ; los enemigos con posicion...
	ld de,0e204h		;0a6a
	ld bc,franja_llena_de+1		;0a6d   ; ...nueve, con 0x4B (vivo, vida entera, mirando abajo): es `ld bc,0x094B`
	jp pon_estados		;0a70

; ----------------------------------------------------------------------
; DATOS salida_de_sparkie_sin_uso: 28 B0 1F 00: los mismos cuatro bytes que
;   0x141A (X 0x28, Y 0xB0, estado 0x1F). Detras del `jp 0x0A77` y sin nadie
;   que los lea
;   0x0a73..0x0a77  (4 bytes)
DATA_salida_de_sparkie_sin_uso:
	defb 028h,0b0h,01fh,000h	; 0a73

; ======================================================================
; CODIGO 0x0a77..0x0b82  (267 bytes)
; ======================================================================


pon_estados:		; A los B objetos de HL con posicion, el estado C en DE (de 2 en 2)
	xor a			;0a77
	or (hl)			;0a78   ; posicion a cero: hueco vacio
	jr z,L_0A7D		;0a79
	ld a,c			;0a7b   ; el estado
	ld (de),a			;0a7c
L_0A7D:
	inc hl			;0a7d   ; el siguiente
	inc hl			;0a7e
	inc de			;0a7f
	inc de			;0a80
	djnz pon_estados		;0a81
	ret			;0a83
copia_jugador1:		; A = 0: sale la partida guardada del jugador 1 (0xE258); si no, se guarda alli la que esta en curso
	ld hl,0e258h		;0a84   ; la del jugador 1
	jr copia_partida		;0a87
copia_jugador2:		; Lo mismo con la del jugador 2 (0xE384)
	ld hl,0e384h		;0a89   ; la del jugador 2
copia_partida:		; A = 0: de la copia a 0xE12C; A distinto de 0: de 0xE12C a la copia
	ld de,0e12ch		;0a8c   ; la partida en curso
	or a			;0a8f
	jr z,L_0A93		;0a90   ; guardar: al reves
	ex de,hl			;0a92
L_0A93:
	ld bc,0012ah		;0a93   ; 298 bytes: mapa, objetos, puntos, vidas y fase
	ldir		;0a96
	ld hl,0e250h		;0a98   ; la fase
	call laberinto_de_fase		;0a9b   ; su laberinto
	ld de,0e1e4h		;0a9e   ; y sus enemigos, de vuelta a la salida
	ld a,02ch		;0aa1   ; 88 bytes mas alla (72 + 6 + 10)
	rst 10h			;0aa3
	ld bc,00012h		;0aa4
	ldir		;0aa7
laberinto_de_fase:		; HL = el laberinto de la fase (HL): hay cuatro y se repiten
	ld a,(hl)			;0aa9   ; la fase, de cuatro en cuatro
	and 003h		;0aaa
	ld hl,019e2h		;0aac   ; el primero
	ret z			;0aaf
	dec a			;0ab0
	ld hl,01a6ah		;0ab1
	ret z			;0ab4
	dec a			;0ab5
	ld hl,01af5h		;0ab6
	ret z			;0ab9
	ld hl,01b91h		;0aba
	ret			;0abd

; ----------------------------------------------------------------------
; LOS SPRITES. Cada tanda de enemigos tiene cinco en la tabla de la VRAM desde 0x3B04 (Sparkie es el 0 y su cola el 17). El patron y el color salen de la tabla de 0x0B82; el sentido suma lo de 0x1498; y cada 8 cuadros se alterna el dibujo (menos en la tanda 1).
; ----------------------------------------------------------------------
sprite_enemigo:		; El sprite del enemigo IX, a la VRAM
	ld a,(0e006h)		;0abe   ; la tanda
	push af			;0ac1
	call patron_y_color		;0ac2   ; su patron y su color
	ld b,(ix+020h)		;0ac5   ; el sentido...
	call sentido_y_atributos		;0ac8   ; ...suma al patron
	pop af			;0acb
	ld b,a			;0acc   ; B = C = la tanda
	ld c,a			;0acd
	ld a,0f6h		;0ace   ; 0xF6 + 10 por cada bit que se salta
L_0AD0:
	add a,00ah		;0ad0   ; cinco sprites mas por tanda
	rrc c		;0ad2
	jr nc,L_0AD0		;0ad4
	ld hl,07b04h		;0ad6   ; desde el sprite 1
	rst 10h			;0ad9
	ld a,b			;0ada   ; el enemigo dentro de la tanda
	and 0f0h		;0adb
	rrca			;0add
	rrca			;0ade
	rrca			;0adf
	rst 10h			;0ae0
sube_sprite:		; Los cuatro bytes de 0xE00A a la direccion de la VRAM HL
	ex de,hl			;0ae1
	ld b,004h		;0ae2   ; Y, X, patron y color
	rst 18h			;0ae4
	ld hl,0e00ah		;0ae5
	rst 20h			;0ae8
	ret			;0ae9
sprite_sparkie:		; El sprite de Sparkie (el 0)
	ld a,010h		;0aea   ; patron y color de Sparkie
	call patron_y_color		;0aec
	ld a,(0e004h)		;0aef   ; hacia donde va
	and 0f0h		;0af2
	ld b,a			;0af4
	call sentido_y_atributos		;0af5
	ld hl,07b00h		;0af8   ; el sprite 0
	jr sube_sprite		;0afb
cola_entera:		; La cola de Sparkie con la carga entera (patron 0x94, amarillo)
	ld a,020h		;0afd   ; patron y color de la cola
	call patron_y_color		;0aff
	jr pon_cola		;0b02
cola_gastada:		; La cola con la carga a medias: patron 0xC4 + 16 por punto, en rojo
	ld a,(hl)			;0b04
	ld hl,006c4h		;0b05   ; 0x06C4 no es una direccion: E = 0xC4 y D = 6 (rojo)
	and 003h		;0b08
	rlca			;0b0a
	rlca			;0b0b
	rlca			;0b0c
	rst 10h			;0b0d   ; 16 patrones por punto de carga
	ex de,hl			;0b0e
pon_cola:		; La cola, 16 puntos detras de Sparkie: su posicion queda en 0xE11F
	push de			;0b0f
	ld a,(0e004h)		;0b10   ; hacia donde va Sparkie
	push af			;0b13
	call bit_de_sentido		;0b14   ; el sentido contrario (0x14D6)
	ld a,(hl)			;0b17
	ld b,010h		;0b18   ; 16 puntos
	ld de,(0e002h)		;0b1a   ; desde Sparkie
	call mueve_de		;0b1e
	ld ix,0e11fh		;0b21   ; la cola
	call pon_posicion		;0b25
	pop af			;0b28
	pop de			;0b29
	and 0f0h		;0b2a
	ld b,a			;0b2c
	call sentido_y_atributos		;0b2d   ; el sentido, al patron
	ld hl,07b44h		;0b30   ; el sprite 17
	jr sube_sprite		;0b33
patron_y_color:		; DE = patron (E) y color (D) del primer bit puesto de A en la tabla de 0x0B82, mas el paso de la animacion
	push af			;0b35
	ld hl,00b82h		;0b36   ; la tabla
L_0B39:
	rrca			;0b39   ; el bit
	jr c,L_0B40		;0b3a
	inc hl			;0b3c   ; la entrada siguiente
	inc hl			;0b3d
	jr L_0B39		;0b3e
L_0B40:
	ld e,(hl)			;0b40   ; patron
	inc hl			;0b41
	ld d,(hl)			;0b42   ; color
	pop af			;0b43
	rrca			;0b44   ; la tanda 1 no se anima
	ld a,000h		;0b45
	jr c,L_0B53		;0b47
	ld a,(0e047h)		;0b49   ; el bit 3 de la cuenta...
	bit 3,a		;0b4c
	ld a,010h		;0b4e   ; ...16 patrones mas
	jr z,L_0B53		;0b50
	xor a			;0b52
L_0B53:
	add a,e			;0b53   ; al patron
	ld e,a			;0b54
	ret			;0b55
sentido_y_atributos:		; El patron + el sentido de B (0x1498), y los cuatro bytes del sprite a 0xE00A
	ld hl,01498h		;0b56   ; la tabla de los sentidos
	ld c,004h		;0b59
	xor a			;0b5b
L_0B5C:
	rlc b		;0b5c   ; el primer bit puesto, desde arriba
	jr c,L_0B63		;0b5e
	inc hl			;0b60
	jr L_0B5C		;0b61
L_0B63:
	ld a,(hl)			;0b63   ; al patron
	add a,e			;0b64
	ld e,a			;0b65
	push hl			;0b66
	ld hl,0e00dh		;0b67   ; el color...
	ld a,(0e04dh)		;0b6a   ; ...o el forzado de 0xE04D
	or a			;0b6d
	ld (hl),d			;0b6e
	jr z,L_0B76		;0b6f
	ld (hl),a			;0b71
	xor a			;0b72
	ld (0e04dh),a		;0b73   ; que solo vale una vez
L_0B76:
	dec hl			;0b76
	ld (hl),e			;0b77   ; el patron
	rst 30h			;0b78   ; la posicion
	dec hl			;0b79
	ld (hl),e			;0b7a   ; X
	ld a,d			;0b7b   ; Y - 8: la de la pantalla
	sub 008h		;0b7c
	dec hl			;0b7e
	ld (hl),a			;0b7f
	pop hl			;0b80
	ret			;0b81

; ----------------------------------------------------------------------
; DATOS patron_y_color_por_tipo: seis parejas (patron, color) por el bit de A
;   en 0x0B35: tanda 1 (0x04, rojo), tanda 2 (0x34, amarillo claro), tanda 4
;   (0x14, rojo claro), tanda 8 (0x54, magenta), Sparkie (0x74, rojo oscuro) y
;   la cola entera (0x94, amarillo)
;   0x0b82..0x0b8e  (12 bytes)
DATA_patron_y_color_por_tipo:
	defb 004h,006h	; 0b82
	defb 034h,00bh	; 0b84
	defb 014h,009h	; 0b86
	defb 054h,00dh	; 0b88
	defb 074h,008h	; 0b8a
	defb 094h,00ah	; 0b8c

; ======================================================================
; CODIGO 0x0b8e..0x0e22  (660 bytes)
; ======================================================================


busca_posicion:		; A = el numero (desde 1) de la pareja DE entre las B de HL, o 0
	ld c,b			;0b8e
L_0B8F:
	ld a,(hl)			;0b8f   ; la X
	cp e			;0b90
	jr nz,L_0B9C		;0b91
	inc hl			;0b93
	ld a,(hl)			;0b94   ; la Y
	cp d			;0b95
	jr nz,L_0B9D		;0b96
	ld a,c			;0b98   ; el numero
	sub b			;0b99
	inc a			;0b9a
	ret			;0b9b
L_0B9C:
	inc hl			;0b9c
L_0B9D:
	inc hl			;0b9d
	djnz L_0B8F		;0b9e
	xor a			;0ba0   ; no esta
	ret			;0ba1
repinta_uno:		; Las cuatro casillas de DE, otra vez desde el mapa
	ld b,001h		;0ba2   ; uno solo
	push af			;0ba4
	push bc			;0ba5
	jr L_0BB5		;0ba6
repinta_lista:		; Las cuatro casillas de cada pareja de HL (hasta B o un cero), desde el mapa
	push hl			;0ba8
L_0BA9:
	push bc			;0ba9
	ld a,(hl)			;0baa   ; un cero acaba
	or a			;0bab
	jr nz,L_0BB1		;0bac
	pop bc			;0bae
	pop hl			;0baf
	ret			;0bb0
L_0BB1:
	ld e,a			;0bb1   ; la pareja
	inc hl			;0bb2
	ld d,(hl)			;0bb3
	inc hl			;0bb4
L_0BB5:
	call repinta_casilla		;0bb5   ; la de arriba a la izquierda
	inc e			;0bb8   ; a la derecha
	call repinta_casilla		;0bb9
	inc d			;0bbc   ; abajo a la derecha
	call repinta_casilla		;0bbd
	dec e			;0bc0   ; abajo
	call repinta_casilla		;0bc1
	pop bc			;0bc4
	djnz L_0BA9		;0bc5
	pop hl			;0bc7
	ret			;0bc8
repinta_casilla:		; La casilla DE con lo que dice el mapa
	call lee_casilla		;0bc9   ; su valor
	jp pon_casilla		;0bcc
pinta_casilla:		; Una casilla de 8x8: 8 bytes de patron (HL) y 8 de color (A)
	ex af,af'			;0bcf
	push hl			;0bd0
	push de			;0bd1
	push bc			;0bd2
	inc e			;0bd3   ; una columna a la derecha: el borde de la izquierda
	ld a,008h		;0bd4   ; ocho bytes
	ld (0e000h),a		;0bd6
	call direccion_de_casilla		;0bd9   ; la direccion de su patron
	rst 20h			;0bdc   ; el patron
	ld a,020h		;0bdd   ; la tabla de color, 0x2000 mas alla
	add a,d			;0bdf
	ld d,a			;0be0
	call pon_direccion		;0be1
	ex af,af'			;0be4   ; el color
L_0BE5:
	call vdp_rellena		;0be5   ; ocho veces
	pop bc			;0be8
	pop de			;0be9
	pop hl			;0bea
	ret			;0beb
direccion_de_casilla:		; DE = el patron de la casilla (E, D): E * 8, D con el bit de escritura
	ld b,003h		;0bec
L_0BEE:
	rlc e		;0bee   ; X * 8
	djnz L_0BEE		;0bf0
	set 6,d		;0bf2   ; escritura
pon_direccion:		; La direccion DE al VDP, y B = los bytes de 0xE000
	ld a,(0e000h)		;0bf4
	ld b,a			;0bf7
	rst 18h			;0bf8
	ret			;0bf9
pinta_objeto:		; Un objeto de 16x16: los cuatro patrones de HL (arriba izquierda, abajo izquierda, arriba derecha, abajo derecha) y el color A en las dos filas
	ex af,af'			;0bfa
	push hl			;0bfb
	push de			;0bfc
	push bc			;0bfd
	inc e			;0bfe   ; el borde de la izquierda
	ld a,008h		;0bff
	ld (0e000h),a		;0c01
	call direccion_de_casilla		;0c04   ; arriba a la izquierda
	call copia_al_vdp		;0c07   ; sus ocho bytes
	inc d			;0c0a   ; abajo a la izquierda
	call copia_en		;0c0b
	dec d			;0c0e
	ld a,008h		;0c0f   ; la columna de la derecha
	add a,e			;0c11
	ld e,a			;0c12
	call copia_en		;0c13   ; arriba a la derecha
	inc d			;0c16   ; abajo a la derecha
	call copia_en		;0c17
	dec d			;0c1a
	ld a,e			;0c1b   ; la columna de la izquierda otra vez
	sub 008h		;0c1c
	ld e,a			;0c1e
	ld a,010h		;0c1f   ; 16 bytes de color por fila: las dos casillas
	ld (0e000h),a		;0c21
	ld a,020h		;0c24   ; la tabla de color
	add a,d			;0c26
	ld d,a			;0c27
	call pon_direccion		;0c28
	ex af,af'			;0c2b
L_0C2C:
	out (098h),a		;0c2c   ; el color
	nop			;0c2e
	djnz L_0C2C		;0c2f
	inc d			;0c31   ; la fila de abajo
	push af			;0c32
	call pon_direccion		;0c33
	pop af			;0c36
	jr L_0BE5		;0c37
copia_al_vdp:		; B bytes de HL al VDP
	ld a,(hl)			;0c39
	out (098h),a		;0c3a   ; al puerto de datos
	nop			;0c3c
	inc hl			;0c3d
	djnz copia_al_vdp		;0c3e
	ret			;0c40
copia_en:		; La direccion DE y B bytes de HL
	call pon_direccion		;0c41
	jp copia_al_vdp		;0c44

; ----------------------------------------------------------------------
; LOS SENTIDOS LIBRES en el punto DE (a 0xE007, bit 7 arriba, 6 abajo, 5 izquierda, 4 derecha). Entre dos casillas solo se puede seguir o volver; en una casilla justa se miran las dos casillas que pisaria un objeto de 16 puntos en cada sentido (0x14BF), y el sentido vale si las dos son pasillo.
; ----------------------------------------------------------------------
sentidos_libres:		; Los sentidos por los que puede seguir un objeto de 16x16 en DE
	ld hl,0e007h		;0c47
	ld a,d			;0c4a   ; la Y no cae en casilla...
	and 007h		;0c4b
	ld a,0c0h		;0c4d   ; ...solo arriba y abajo
	ld (hl),a			;0c4f   ; solo vertical...
	ret nz			;0c50   ; ...si la Y no es de casilla
	ld a,e			;0c51   ; la X no cae en casilla...
	and 007h		;0c52
	ld a,030h		;0c54   ; ...solo izquierda y derecha
	ld (hl),a			;0c56   ; solo horizontal...
	ret nz			;0c57   ; ...si la X no es de casilla
	ld (hl),000h		;0c58   ; en casilla justa: se miran los cuatro
	ld hl,014bfh		;0c5a   ; dos desplazamientos por sentido
	ld b,004h		;0c5d   ; cuatro sentidos
L_0C5F:
	push bc			;0c5f
	ld bc,00200h		;0c60   ; dos casillas, cuantas libres en C
L_0C63:
	ld a,(hl)			;0c63   ; la Y de la casilla que se mira
	add a,d			;0c64
	ld d,a			;0c65
	inc hl			;0c66
	ld a,(hl)			;0c67   ; la X
	add a,e			;0c68
	ld e,a			;0c69
	inc hl			;0c6a
	call casilla_libre		;0c6b   ; libre?
	jr z,L_0C71		;0c6e
	inc c			;0c70   ; una mas
L_0C71:
	djnz L_0C63		;0c71
	ld a,002h		;0c73   ; las dos?
	cp c			;0c75
	pop bc			;0c76
	push hl			;0c77
	jr z,L_0C7D		;0c78
	xor a			;0c7a   ; no: ese sentido no
	jr L_0C84		;0c7b
L_0C7D:
	ld hl,014b7h		;0c7d   ; si: su bit, de 0x14B7
	ld a,b			;0c80
	dec a			;0c81
	rst 10h			;0c82
	ld a,(hl)			;0c83
L_0C84:
	ld hl,0e007h		;0c84   ; se suma a los libres
	or (hl)			;0c87
	ld (hl),a			;0c88
	pop hl			;0c89
	djnz L_0C5F		;0c8a   ; el sentido siguiente
	ret			;0c8c
casilla_libre:		; NZ si la casilla del punto DE (+1, +1) es pasillo o pintada; Z si es bloque o muro
	push bc			;0c8d
	push de			;0c8e
	call a_casillas		;0c8f   ; a casillas
	inc d			;0c92   ; la de abajo a la derecha
	inc e			;0c93
	call lee_casilla		;0c94   ; su valor
	pop de			;0c97
	pop bc			;0c98
	rrca			;0c99   ; el bit 1 (bloque y muro lo tienen) al acarreo
	rrca			;0c9a
	ld a,001h		;0c9b   ; 1 - acarreo
	sbc a,000h		;0c9d
	and a			;0c9f
	ret			;0ca0
despedido:		; El enemigo sin vida: a su casilla, y sale hacia donde mira Sparkie
	call ajusta_a_casilla		;0ca1   ; a su casilla
	ld a,(0e004h)		;0ca4   ; el sentido de Sparkie
	and 0f0h		;0ca7
	ld (ix+021h),a		;0ca9   ; es el suyo ahora
vuela:		; Cuatro puntos mas en ese sentido; al chocar, se apaga con su sonido
	rst 30h			;0cac
	call sale_de_franja		;0cad   ; fuera de su franja
	call puede_volar		;0cb0   ; puede seguir?
	or a			;0cb3
	jr z,L_0CC9		;0cb4
	ld b,004h		;0cb6   ; cuatro puntos
	call mueve_de		;0cb8
	call pon_posicion		;0cbb
	call entra_en_franja		;0cbe   ; en la franja nueva
	ld a,00fh		;0cc1   ; en blanco
	ld (0e04dh),a		;0cc3
	jp sprite_enemigo		;0cc6   ; su sprite
L_0CC9:
	ld hl,01cf5h		;0cc9   ; contra la pared: su sonido
	ld (0e0c4h),hl		;0ccc
	ld a,001h		;0ccf
	ld (0e0c9h),a		;0cd1
	res 3,(ix+020h)		;0cd4   ; apagado
	jp sprite_fuera		;0cd8   ; sprite fuera
puede_volar:		; Lo libre del punto DE en el sentido de IX+0x21
	push de			;0cdb
	call sentidos_libres		;0cdc
	pop de			;0cdf
	ld a,(0e007h)		;0ce0   ; lo libre
	and (ix+021h)		;0ce3   ; y el sentido
	ret			;0ce6
toca_la_ola:		; A = 1 si la punta de la ola esta a menos de 8 puntos del enemigo IX (en la misma fila o columna)
	ld de,(0e039h)		;0ce7   ; la punta, en casillas
	call a_puntos		;0ceb   ; a puntos
	ex de,hl			;0cee
	jr cerca		;0cef
toca_la_cola:		; Lo mismo con la cola de Sparkie (0xE11F)
	ld hl,(0e11fh)		;0cf1
	jr cerca		;0cf4
toca_a_sparkie_casilla:		; Lo mismo entre la casilla del objeto IX y Sparkie
	rst 30h			;0cf6
	call a_puntos		;0cf7   ; a puntos
toca_a_sparkie:		; Lo mismo entre DE y Sparkie (0xE002)
	ld hl,(0e002h)		;0cfa
	jr L_0D00		;0cfd
cerca:		; A = 1 si el punto HL y el objeto IX estan en la misma fila o columna a menos de 8 puntos
	rst 30h			;0cff   ; el objeto
L_0D00:
	ld a,h			;0d00   ; la misma Y?
	cp d			;0d01
	jr z,L_0D0A		;0d02
	ld a,l			;0d04   ; la misma X?
	cp e			;0d05
	jr z,L_0D15		;0d06
	xor a			;0d08   ; ni una ni otra: lejos
	ret			;0d09
L_0D0A:
	ld a,l			;0d0a   ; misma Y: la distancia en X
	cp e			;0d0b
	jr c,L_0D11		;0d0c
	sub e			;0d0e
	jr L_0D1E		;0d0f
L_0D11:
	ld a,e			;0d11
	sub l			;0d12
	jr L_0D1E		;0d13
L_0D15:
	ld a,h			;0d15   ; misma X: la distancia en Y
	cp d			;0d16
	jr c,L_0D1C		;0d17
	sub d			;0d19
	jr L_0D1E		;0d1a
L_0D1C:
	ld a,d			;0d1c
	sub h			;0d1d
L_0D1E:
	cp 008h		;0d1e   ; menos de 8: acarreo...
	ld a,000h		;0d20   ; ...a A
	adc a,a			;0d22
	ret			;0d23
disparos_dan:		; Cada disparo quita un punto de vida al primer enemigo que toca (de los 16 huecos de 0xE1DC)
	ld hl,0e03bh		;0d24   ; los cuatro disparos
	ld b,004h		;0d27
L_0D29:
	push bc			;0d29
	ld ix,0e1dch		;0d2a   ; los enemigos
	ld a,(hl)			;0d2e   ; el disparo
	or a			;0d2f
	jr z,L_0D4E		;0d30   ; no hay: se acaba
	ld e,a			;0d32
	inc hl			;0d33
	ld d,(hl)			;0d34
	inc hl			;0d35
	push hl			;0d36
	call a_puntos		;0d37   ; a puntos
	ex de,hl			;0d3a
	ld b,010h		;0d3b   ; 16 huecos
L_0D3D:
	call cerca		;0d3d   ; lo toca?
	or a			;0d40
	jr z,L_0D50		;0d41
	ld a,(ix+020h)		;0d43   ; le queda vida?
	and 003h		;0d46
	jr z,L_0D50		;0d48
	dec (ix+020h)		;0d4a   ; un punto menos, y este disparo ya no da a mas
	pop hl			;0d4d
L_0D4E:
	pop bc			;0d4e
	ret			;0d4f
L_0D50:
	inc ix		;0d50   ; el siguiente hueco
	inc ix		;0d52
	djnz L_0D3D		;0d54
	pop hl			;0d56   ; el disparo siguiente
	pop bc			;0d57
	djnz L_0D29		;0d58
	ret			;0d5a
borra_disparos:		; Los disparos se repintan desde el mapa y su lista queda a cero
	ld hl,0e03bh		;0d5b   ; la lista
	ld b,004h		;0d5e
	xor a			;0d60
	or (hl)			;0d61   ; hay alguno?
	jr z,L_0D67		;0d62
	call repinta_lista		;0d64   ; sus casillas, como estaban
L_0D67:
	ld b,008h		;0d67   ; ocho bytes a cero
	xor a			;0d69
rellena:		; B bytes de A desde HL
	ld (hl),a			;0d6a
	inc hl			;0d6b
	djnz rellena		;0d6c
	ret			;0d6e
sonido_de_muerte:		; Sparkie muerto: los cuatro bloques al sonido de 0x1D0B y el ruido abierto
	call sparkie_vivo		;0d6f   ; vivo: nada
	ret nz			;0d72
	call silencio		;0d73   ; silencio
	ld a,(0e0a3h)		;0d76   ; en la demostracion, sin sonido
	rrca			;0d79
	ret c			;0d7a
	ld hl,01d0bh		;0d7b   ; los cuatro bloques...
	ld (0e0b4h),hl		;0d7e
	ld (0e0bch),hl		;0d81
	ld (0e0c4h),hl		;0d84
	ld (0e0cch),hl		;0d87
	ld hl,0e0b1h		;0d8a   ; ...con su tiempo a 0x70
	ld de,00008h		;0d8d
	ld b,004h		;0d90
L_0D92:
	add hl,de			;0d92
	ld (hl),070h		;0d93
	djnz L_0D92		;0d95
	ld a,007h		;0d97   ; el registro 7 del PSG...
	out (0a0h),a		;0d99
	ld a,080h		;0d9b   ; ...con el ruido en los tres canales
	out (0a1h),a		;0d9d
	ret			;0d9f

; ----------------------------------------------------------------------
; LA MUERTE DE SPARKIE: la explosion (el patron 0) en su sitio, la espera del sonido, una vida menos, el cambio de jugador si son dos, y "GAME  OVER" si se acaban.
; ----------------------------------------------------------------------
muerte:		; Sparkie muerto: explosion, vidas y siguiente jugador
	call sparkie_vivo		;0da0   ; sigue vivo: nada
	ret nz			;0da3
	ld ix,0e002h		;0da4   ; Sparkie
	ld a,010h		;0da8   ; su sprite fuera
	call sprite_fuera_a		;0daa
	rst 30h			;0dad   ; donde estaba
	ld a,d			;0dae   ; Y...
	ld d,e			;0daf
	sub 008h		;0db0   ; ...- 8
	ld e,a			;0db2
	ld (0e00ah),de		;0db3   ; la explosion: X e Y
	ld hl,00600h		;0db7   ; patron 0, rojo
	ld (0e00ch),hl		;0dba
	ld h,07bh		;0dbd   ; en el sprite 0
	call sube_sprite		;0dbf
espera_muerte:		; La espera: el sonido de la muerte, o un rato en la demostracion
	ld hl,0e0a3h		;0dc2
	set 1,(hl)		;0dc5   ; la demostracion se acaba con la muerte
	ld a,(0e0a3h)		;0dc7
	rrca			;0dca   ; en la demostracion...
	jr nc,L_0DD4		;0dcb
	ld b,020h		;0dcd   ; ...un rato
	call pausa		;0dcf
	jr L_0DDA		;0dd2
L_0DD4:
	ld a,(0e0cdh)		;0dd4   ; el bloque 4 sigue sonando?
	or a			;0dd7
	jr nz,espera_muerte		;0dd8
L_0DDA:
	di			;0dda   ; una vida menos
	ld hl,0e24fh		;0ddb
	dec (hl)			;0dde
	jr z,sin_vidas		;0ddf   ; quedan: el otro jugador, si lo hay
	call cambia_jugador		;0de1
	jr sigue_jugando		;0de4
sin_vidas:		; Sin vidas: el otro jugador si le quedan, y si no, la partida acabada
	call cambia_jugador		;0de6   ; a quien le toca
	or a			;0de9
	jr z,L_0DF3		;0dea
	ld hl,0e0a3h		;0dec   ; a nadie: bit 7, la partida acabada
	ld a,080h		;0def
	or (hl)			;0df1
	ld (hl),a			;0df2
L_0DF3:
	xor a			;0df3
	ld (0e0a4h),a		;0df4
	ld hl,00e22h		;0df7   ; "GAME  OVER"
	call pinta_rotulo		;0dfa
	ld d,010h		;0dfd   ; 16 vueltas...
L_0DFF:
	call boton_de_salida		;0dff   ; ...o el boton
	jr nz,sigue_jugando		;0e02
	ld b,001h		;0e04
	call pausa		;0e06
	dec d			;0e09
	jr nz,L_0DFF		;0e0a
sigue_jugando:		; Las llamitas fuera y la pantalla otra vez
	xor a			;0e0c   ; los estados de los cuatro primeros huecos, a cero
	ld hl,0e1fch		;0e0d
	ld b,008h		;0e10
	call rellena		;0e12
	jp pinta_fase		;0e15   ; la pantalla de la fase
quedan_vidas:		; NZ si le quedan vidas al jugador en curso
	ld a,(0e24fh)		;0e18
	or a			;0e1b
	ret			;0e1c
jugador:		; A = 0xE001: 1 el jugador 1, 0 el jugador 2
	ld a,(0e001h)		;0e1d
	or a			;0e20
	ret			;0e21

; ----------------------------------------------------------------------
; DATOS texto_game_over: color 0xF1, X 7, Y 11, 10 letras: "GAME  OVER"
;   0x0e22..0x0e30  (14 bytes)
DATA_texto_game_over:
	defb 0f1h,007h,00bh,00ah	; 0e22
	defb 017h,005h,006h,015h,001h,001h,003h,020h,015h,01ch	; 0e26  ....... ..

; ======================================================================
; CODIGO 0x0e30..0x11de  (942 bytes)
; ======================================================================


sparkie_vivo:		; NZ si Sparkie esta vivo (bit 3 de 0xE004)
	ld hl,0e004h		;0e30
	bit 3,(hl)		;0e33
	ret			;0e35
boton_de_salida:		; El boton del mando 1 (opcion 1) o la barra (opcion 3), +1 si la opcion era de dos jugadores; NZ si se ha pulsado
	ld a,00fh		;0e36   ; el registro 15 del PSG...
	out (0a0h),a		;0e38
	ld a,08fh		;0e3a   ; ...con el mando 1
	call lee_puerto		;0e3c   ; se lee
	ld b,001h		;0e3f   ; opcion 1
	rrca			;0e41   ; pulsado?
	jr c,L_0E4E		;0e42
	call lee_teclado		;0e44   ; el teclado
	ld b,003h		;0e47   ; opcion 3
	rrca			;0e49
	jr c,L_0E4E		;0e4a
	xor a			;0e4c   ; nada
	ret			;0e4d
L_0E4E:
	ld hl,0e0a2h		;0e4e   ; la opcion de antes
	ld a,(hl)			;0e51
	rrca			;0e52   ; de un jugador: se queda
	jr c,L_0E56		;0e53
	inc b			;0e55   ; de dos: la de dos
L_0E56:
	ld (hl),b			;0e56   ; la opcion
	inc hl			;0e57
	inc hl			;0e58
	ld (hl),b			;0e59   ; y a quien le toca
	ld a,b			;0e5a
	or a			;0e5b
	ret			;0e5c
cambia_jugador:		; Guarda al que jugaba y saca al otro si le quedan vidas. A = 0 sigue alguien; distinto de 0, ninguno
	call jugador		;0e5d   ; quien jugaba?
	jr z,cambia_a_jugador1		;0e60
	ld a,001h		;0e62   ; el 1: se guarda
	call copia_jugador1		;0e64
	ld a,(0e0a2h)		;0e67   ; un jugador solo...
	rrca			;0e6a
	ret c			;0e6b   ; ...se queda
	xor a			;0e6c   ; el 2
	call pon_jugador		;0e6d
	call copia_jugador2		;0e70   ; sale su partida
	call quedan_vidas		;0e73   ; le quedan vidas?
	ld a,000h		;0e76   ; si: sigue el 2
	ret nz			;0e78
	ld a,001h		;0e79   ; no: vuelve el 1
	call pon_jugador		;0e7b
	xor a			;0e7e
	call copia_jugador1		;0e7f
	ld a,001h		;0e82   ; ninguno
	ret			;0e84
cambia_a_jugador1:		; Jugaba el 2: se guarda y sale el 1 si le quedan vidas
	ld a,001h		;0e85   ; se guarda el 2
	call copia_jugador2		;0e87
	ld a,001h		;0e8a   ; el 1
	call pon_jugador		;0e8c
	xor a			;0e8f   ; sale su partida
	call copia_jugador1		;0e90
	call quedan_vidas		;0e93   ; le quedan vidas?
	ld a,000h		;0e96   ; si: sigue el 1
	ret nz			;0e98
	xor a			;0e99   ; no: vuelve el 2
	call pon_jugador		;0e9a
	call copia_jugador2		;0e9d
	ld a,002h		;0ea0   ; ninguno
	ret			;0ea2

; ----------------------------------------------------------------------
; LOS PUNTOS van por centenas: el marcador pinta cuatro cifras y los dos ceros de detras son un rotulo fijo (0x039F). Con 30.000 hay una vida mas, una sola vez.
; ----------------------------------------------------------------------
puntos_despedido:		; 100 puntos por una llamita despedida, 200 por los demas
	ld a,(0e006h)		;0ea3   ; la tanda
	rrca			;0ea6
	ld l,001h		;0ea7   ; 100
	jr c,suma_puntos		;0ea9
	inc l			;0eab   ; 200
	jr suma_puntos		;0eac
premio_de_fase:		; El premio de la fase: 10.000 con todo pintado; si no, (500 - casillas sin pintar) / 10 centenas
	ld hl,(0e071h)		;0eae   ; las casillas sin pintar
	ld a,h			;0eb1
	or l			;0eb2
	jr z,diez_mil		;0eb3   ; ninguna: 10.000
	ld de,001f4h		;0eb5   ; 500...
	ex de,hl			;0eb8
	xor a			;0eb9
	sbc hl,de		;0eba   ; ...menos las que quedan
	ld bc,0000ah		;0ebc   ; entre 10
	ld d,a			;0ebf
L_0EC0:
	sbc hl,bc		;0ec0
	inc d			;0ec2
	jr nc,L_0EC0		;0ec3
	dec d			;0ec5   ; el cociente
	ld l,d			;0ec6
	jr suma_puntos		;0ec7
puntos_premio:		; El premio del laberinto: 1.000 por fase hasta la novena, 10.000 desde la decima
	ld a,(0e250h)		;0ec9   ; la fase
	cp 009h		;0ecc
	jr c,L_0ED4		;0ece   ; desde la decima...
diez_mil:		; 10.000 puntos
	ld l,064h		;0ed0   ; ...100 centenas
	jr suma_puntos		;0ed2
L_0ED4:
	inc a			;0ed4   ; fase + 1...
	ld l,a			;0ed5
	ld h,000h		;0ed6
	ld b,009h		;0ed8   ; ...por 10
L_0EDA:
	add a,l			;0eda
	djnz L_0EDA		;0edb
	ld l,a			;0edd
suma_puntos:		; Suma L centenas, pinta la puntuacion, da la vida extra y lleva el record
	ld h,000h		;0ede
	ld de,(0e24dh)		;0ee0   ; la puntuacion
	add hl,de			;0ee4   ; mas lo ganado
	ld (0e24dh),hl		;0ee5
	push hl			;0ee8
	ld de,00318h		;0ee9   ; en X 0x18, Y 3 (el jugador 1)...
	call jugador		;0eec
	jr nz,L_0EF3		;0eef
	ld d,007h		;0ef1   ; ...o Y 7 (el jugador 2)
L_0EF3:
	call pinta_cifras		;0ef3   ; se pinta
	pop de			;0ef6
	ld a,(0e255h)		;0ef7   ; la vida extra ya dada?
	or a			;0efa
	jr nz,L_0F10		;0efb
	ld hl,0012ch		;0efd   ; 300 centenas...
	xor a			;0f00
	sbc hl,de		;0f01
	jr nc,L_0F10		;0f03   ; ...sin pasar: nada
	inc a			;0f05   ; dada
	ld (0e255h),a		;0f06
	ld hl,0e24fh		;0f09
	inc (hl)			;0f0c   ; una vida mas...
	call pinta_vidas		;0f0d   ; ...y se pinta
L_0F10:
	ld hl,(0e06fh)		;0f10   ; el record
	push hl			;0f13
	ld de,00b18h		;0f14   ; en X 0x18, Y 0x0B
	call pinta_cifras		;0f17
	pop hl			;0f1a
	ld de,(0e24dh)		;0f1b   ; la puntuacion
	push de			;0f1f
	xor a			;0f20
	sbc hl,de		;0f21   ; el record es mayor: nada
	pop hl			;0f23
	ret nc			;0f24
	ld (0e06fh),hl		;0f25   ; record nuevo
	ld de,00b18h		;0f28   ; y se pinta
	jp pinta_cifras		;0f2b

; ----------------------------------------------------------------------
; EL MANDO, a 0xE00E con los bits de los sentidos (7 arriba, 6 abajo, 5 izquierda, 4 derecha) y el boton en el 3. Las opciones 1 y 2 leen el mando del puerto de cada jugador (registro 14 del PSG, el puerto elegido en el 15); la 3 y la 4, los cursores y la barra (fila 8 del teclado). En la demostracion el mando son los sentidos libres de la casilla.
; ----------------------------------------------------------------------
lee_mando:		; El mando del jugador en curso, a 0xE00E
	ld a,(0e0a2h)		;0f2e   ; la opcion
	cp 003h		;0f31
	jr nc,lee_teclado		;0f33   ; 3 o 4: teclado
	ld a,00fh		;0f35   ; el registro 15
	out (0a0h),a		;0f37
	call jugador		;0f39   ; el jugador 2...
	ld a,0cfh		;0f3c   ; ...el mando del puerto 2
	jr z,lee_puerto		;0f3e
	ld a,08fh		;0f40   ; el 1, el del puerto 1
lee_puerto:		; El puerto de mando que dice A, del registro 14: seis bits a C, el 0 pulsado pasa a 1
	out (0a1h),a		;0f42   ; se elige el puerto
	ld a,00eh		;0f44   ; el registro 14
	out (0a0h),a		;0f46
	in a,(0a2h)		;0f48   ; se lee
	ld bc,00600h		;0f4a   ; seis bits: arriba, abajo, izquierda, derecha y los dos botones
L_0F4D:
	rrca			;0f4d   ; el bit
	jr nc,L_0F54		;0f4e
	rlc c		;0f50   ; suelto: entra lo de arriba de C (un cero)
	jr L_0F57		;0f52
L_0F54:
	scf			;0f54   ; pulsado: entra un uno
	rl c		;0f55
L_0F57:
	djnz L_0F4D		;0f57
	rlc c		;0f59   ; dos vueltas mas: arriba queda en el bit 7 y el boton A en el 3
	rlc c		;0f5b
	ld a,c			;0f5d
guarda_mando:		; A a 0xE00E; en la demostracion, los sentidos libres y el PSG callado
	ld (0e00eh),a		;0f5e   ; el mando
	push af			;0f61
	ld a,(0e0a3h)		;0f62   ; la demostracion?
	rrca			;0f65
	jr nc,L_0F71		;0f66
	call silencio		;0f68   ; sin sonido
	ld a,(0e007h)		;0f6b   ; lo libre hace de mando
	ld (0e00eh),a		;0f6e
L_0F71:
	pop af			;0f71
	jp boton_una_vez		;0f72   ; el boton, solo al apretarlo
lee_teclado:		; Los cursores y la barra de la fila 8, al formato del mando (0x1488)
	ld a,058h		;0f75   ; la fila 8 del teclado
	out (0aah),a		;0f77
	out (0aah),a		;0f79
	in a,(0a9h)		;0f7b   ; se lee
	ld b,a			;0f7d
	rra			;0f7e   ; los cursores...
	rra			;0f7f
	rra			;0f80
	rra			;0f81
	cpl			;0f82   ; ...a 1 los pulsados
	and 00fh		;0f83
	ld hl,01488h		;0f85   ; a sentidos, por la tabla de 0x1488
	add a,l			;0f88
	ld l,a			;0f89
	jr nc,L_0F8D		;0f8a
	inc h			;0f8c
L_0F8D:
	ld a,(hl)			;0f8d
	rrc b		;0f8e   ; la barra, en el bit 0
	jr c,L_0F94		;0f90
	set 3,a		;0f92   ; pulsada: el boton
L_0F94:
	jr guarda_mando		;0f94

; ----------------------------------------------------------------------
; EL SONIDO: cuatro bloques de 8 bytes (0xE0B4 musica en el canal A, 0xE0BC el zumbido y los disparos en el B, 0xE0C4 los efectos en el C, 0xE0CC el ruido con el volumen del A). Cada bloque: +0/+1 el puntero, +2 la espera de la nota, +3 el registro del tono (0, 2, 4 o 6), +4/+5 la cuenta del paso y su recarga, +6/+7 la envolvente. Cada nota: el tono bajo, un byte con la duracion (nibble alto), el bit 3 (viene el volumen) y el tono alto (bits 0-2), y el volumen si viene; con el bit 4 del volumen, dos bytes del periodo de la envolvente. 0x00 acaba (y vuelve el zumbido), 0xFF calla el bloque, 0xFE pasa a la frase siguiente de la musica.
; ----------------------------------------------------------------------
silencio:		; Los cuatro bloques callados, el volumen de la musica a 5 y solo los tonos abiertos
	call calla_bloque1		;0f96
	call calla_bloque2		;0f99
	call calla_bloque3		;0f9c
	call calla_bloque4		;0f9f
	ld a,005h		;0fa2   ; el volumen de la musica
	ld (0e610h),a		;0fa4
	ld a,007h		;0fa7   ; el registro 7 del PSG...
	out (0a0h),a		;0fa9
	ld a,0b8h		;0fab   ; ...tonos si, ruido no
	out (0a1h),a		;0fad
	ret			;0faf
calla_bloque4:		; El bloque del ruido: a cero, volumen del canal A a cero, registro 6
	ld hl,0e0cch		;0fb0
	ld a,008h		;0fb3
	call calla_bloque		;0fb5
	ld a,006h		;0fb8   ; su registro: el del ruido
	ld (0e0cfh),a		;0fba
	ret			;0fbd
calla_bloque3:		; El bloque 3: canal C, registro 4
	ld hl,0e0c4h		;0fbe
	ld a,00ah		;0fc1
	call calla_bloque		;0fc3
	ld a,004h		;0fc6   ; tono del canal C
	ld (0e0c7h),a		;0fc8
	ret			;0fcb
calla_bloque2:		; El bloque 2: canal B, registro 2
	ld hl,0e0bch		;0fcc
	ld a,009h		;0fcf
	call calla_bloque		;0fd1
	ld a,002h		;0fd4   ; tono del canal B
	ld (0e0bfh),a		;0fd6
	ret			;0fd9
calla_bloque1:		; El bloque 1 (la musica): canal A, registro 0
	ld hl,0e0b4h		;0fda
	ld a,008h		;0fdd
calla_bloque:		; El volumen A a cero y los 8 bytes de HL a ese valor
	ld b,008h		;0fdf
	call registro_a_cero		;0fe1   ; el volumen del canal, a cero
L_0FE4:
	ld (hl),a			;0fe4   ; el bloque entero
	inc hl			;0fe5
	djnz L_0FE4		;0fe6
	ret			;0fe8
paso_de_sonido:		; Un cuadro del bloque de HL+1: la cuenta, la espera, y la nota siguiente al PSG
	ld a,(hl)			;0fe9   ; el bloque tiene puntero?
	or a			;0fea
	ret z			;0feb
	inc hl			;0fec   ; +3
	inc hl			;0fed
	inc hl			;0fee
	ld a,(hl)			;0fef   ; la cuenta del paso
	or a			;0ff0
	jp nz,un_paso_menos		;0ff1   ; corre: un cuadro menos
	inc hl			;0ff4
	ld a,(hl)			;0ff5   ; se recarga
	dec hl			;0ff6
	ld (hl),a			;0ff7   ; la recarga
	dec hl			;0ff8
	dec hl			;0ff9
	dec hl			;0ffa
	dec hl			;0ffb   ; +0: el puntero
	ld e,(hl)			;0ffc   ; el puntero
	inc hl			;0ffd
	ld d,(hl)			;0ffe
	inc hl			;0fff
	ld a,(hl)			;1000   ; la espera de la nota
	or a			;1001
	jr nz,un_paso_menos		;1002   ; corre: un paso menos
	ld a,(de)			;1004   ; el byte
	or a			;1005
	jp z,fin_de_efecto		;1006   ; 0x00: acaba
	inc a			;1009
	jr z,calla_este		;100a   ; 0xFF: calla
	inc a			;100c
	jp z,frase_siguiente		;100d   ; 0xFE: la frase siguiente
	inc hl			;1010
	ld a,(hl)			;1011   ; el registro del tono
	ld c,0a1h		;1012
	ex de,hl			;1014
	out (0a0h),a		;1015   ; se elige
	outi		;1017   ; el tono bajo
	push af			;1019
	push de			;101a
	pop ix		;101b   ; IX = el puntero de la nota
	ld a,(hl)			;101d   ; el byte de la duracion...
	ld (ix-001h),a		;101e   ; ...entero a la espera (luego se queda con su nibble alto)
	pop af			;1021
	inc a			;1022   ; el registro del tono alto
	cp 007h		;1023   ; el 7: es el ruido, que no tiene
	jr z,L_1030		;1025
	ld b,a			;1027
	out (0a0h),a		;1028
	ld a,(hl)			;102a
	and 007h		;102b   ; sus tres bits
	out (0a1h),a		;102d
	ld a,b			;102f
L_1030:
	bit 0,(ix+003h)		;1030   ; la envolvente sonando?
	ld b,(ix+004h)		;1034
	inc hl			;1037
	jr nz,dispara_envolvente		;1038
	dec hl			;103a
	bit 3,(hl)		;103b   ; viene el volumen?
	inc hl			;103d
	jr z,nota_hecha		;103e
	cp 007h		;1040   ; el ruido usa el volumen del canal A
	jr nz,L_1046		;1042
	ld a,001h		;1044
L_1046:
	rrca			;1046   ; el registro del volumen: 8, 9 o 10
	add a,088h		;1047
	out (0a0h),a		;1049
	outi		;104b   ; el volumen
	dec hl			;104d
	ld b,(hl)			;104e
	bit 4,(hl)		;104f   ; con envolvente?
	inc hl			;1051
	jr z,nota_hecha		;1052
	push bc			;1054
	ld (ix+003h),001h		;1055   ; marcada
	ld (ix+004h),b		;1059
	ld a,00bh		;105c   ; su periodo, registros 11...
	out (0a0h),a		;105e
	outi		;1060
	inc a			;1062
	out (0a0h),a		;1063   ; ...y 12
	outi		;1065
	pop bc			;1067
dispara_envolvente:		; El registro 13 (la forma) para que la envolvente vuelva a empezar
	ld a,00dh		;1068
	out (0a0h),a		;106a
	out (c),b		;106c   ; la forma
nota_hecha:		; El puntero nuevo y la espera de la nota (el nibble alto)
	ex de,hl			;106e
	dec hl			;106f   ; el puntero
	dec hl			;1070
	ld (hl),d			;1071
	dec hl			;1072
	ld (hl),e			;1073
	inc hl			;1074
	inc hl			;1075
	xor a			;1076   ; la espera: el nibble alto del byte de duracion
	rrd		;1077
un_paso_menos:		; Un paso menos de la cuenta
	dec (hl)			;1079
	ret			;107a
calla_este:		; 0xFF: el bloque sin puntero y su canal sin volumen; el del ruido calla todo
	push hl			;107b
	pop ix		;107c
	dec hl			;107e
	ld (hl),a			;107f   ; el puntero, a cero
	ld (ix+004h),a		;1080   ; sin envolvente
	inc hl			;1083
	inc hl			;1084
	ld a,(hl)			;1085   ; el registro del tono
	cp 006h		;1086   ; el ruido?
	jp z,silencio		;1088   ; calla todo
	srl a		;108b   ; el registro del volumen: 8 + tono / 2
	add a,008h		;108d
registro_a_cero:		; El registro A del PSG a cero
	out (0a0h),a		;108f
	xor a			;1091
	out (0a1h),a		;1092
	ret			;1094
fin_de_efecto:		; 0x00: el bloque 2 callado y el zumbido otra vez
	call calla_bloque2		;1095
zumbido:		; El zumbido de 0x1D11 en el bloque 2
	ld hl,01d11h		;1098   ; el zumbido
	ld (0e0bch),hl		;109b
	xor a			;109e   ; sin envolvente
	ld (0e0c1h),a		;109f
	ret			;10a2
musica_de_fase:		; La musica de la fase (la lista de 0x1C8E), con el volumen de 0xE610
	ld a,001h		;10a3   ; la musica con su volumen
	ld hl,01c8eh		;10a5   ; la lista
	jr pon_lista		;10a8
musica_de_aviso:		; La lista de HL, con el tiempo fijo de 4 (la de la carga baja)
	xor a			;10aa
pon_lista:		; La lista de frases de HL
	ld (0e0bah),a		;10ab   ; con volumen o sin el
	ld (0e60eh),hl		;10ae   ; la lista
frase_siguiente:		; La frase siguiente de la lista: copiada a 0xE5DC y al bloque 1
	ld hl,(0e60eh)		;10b1   ; la lista
	ld e,(hl)			;10b4   ; la frase
	inc hl			;10b5
	ld d,(hl)			;10b6
	inc hl			;10b7
	ld (0e60eh),hl		;10b8   ; la siguiente, para la vez que viene
	ex de,hl			;10bb
	ld a,h			;10bc   ; cero: la lista vuelve a empezar
	or l			;10bd
	jr z,musica_de_fase		;10be
	ld a,h			;10c0   ; 0xFFFF: la musica se acaba
	and l			;10c1
	inc a			;10c2
	jp z,calla_bloque1		;10c3
	ld b,000h		;10c6   ; el primer byte es la longitud
	ld c,(hl)			;10c8
	inc hl			;10c9
	ld de,0e5dch		;10ca   ; a 0xE5DC
	ldir		;10cd
	ld a,(0e0bah)		;10cf
	ld c,a			;10d2
	call calla_bloque1		;10d3   ; el bloque 1 a cero
	ld hl,0e5dch		;10d6   ; su puntero
	ld (0e0b4h),hl		;10d9
	or c			;10dc   ; el tiempo...
	jr z,L_10E4		;10dd
	ld a,(0e610h)		;10df   ; ...de 0xE610
	jr L_10E6		;10e2
L_10E4:
	ld a,004h		;10e4   ; ...o 4
L_10E6:
	ld (0e0b9h),a		;10e6   ; la recarga del paso
	ret			;10e9

; ----------------------------------------------------------------------
; LA PANTALLA DE SONY. SCREEN 1 (los registros de 0x1649) con 2048 bytes desde 0x11DE como letras -codigo incluido: solo se ven las que nombra la tabla de 0x1659-, los colores de 0x1636 y los nombres de 0x1659. Despues de la pausa, SCREEN 2 (los registros de 0x1651), los sprites girados y la tabla de nombres de 0 a 255.
; ----------------------------------------------------------------------
pantalla_de_sony:		; La pantalla de Sony, la pausa, y el VDP listo para el juego
	ld hl,01649h		;10ea   ; SCREEN 1
	call pon_registros		;10ed
	ld de,04000h		;10f0   ; la VRAM entera...
	ld bc,00040h		;10f3   ; ...16 KB a cero
	rst 18h			;10f6
	call vdp_ceros		;10f7
	ld de,04800h		;10fa   ; las letras de SCREEN 1 en 0x0800...
	ld bc,00008h		;10fd   ; ...2048 bytes...
	ld hl,011deh		;1100   ; ...desde 0x11DE
	rst 18h			;1103
L_1104:
	rst 20h			;1104   ; 256 cada vuelta
	dec c			;1105
	jr nz,L_1104		;1106
	ld de,04780h		;1108   ; los colores (0x0780), 32 bytes
	ld b,020h		;110b
	ld hl,01636h		;110d
	rst 18h			;1110
	rst 20h			;1111
	ld de,0444bh		;1112   ; el logotipo: fila 2...
	ld b,00ah		;1115
	ld hl,01659h		;1117
	rst 18h			;111a
	rst 20h			;111b
	ld de,0446bh		;111c   ; ...fila 3
	ld b,00ah		;111f
	rst 18h			;1121
	rst 20h			;1122
	ld de,04500h		;1123   ; "HIT BIT" desde la fila 8
	ld b,0e0h		;1126
	rst 18h			;1128
	rst 20h			;1129
	ld de,0462ch		;112a   ; "SPARKIE"
	ld b,007h		;112d
	rst 18h			;112f
	rst 20h			;1130
	ld de,0468ah		;1131   ; "(C) Konami 1983"
	ld b,00ch		;1134
	rst 18h			;1136
	rst 20h			;1137
	ld b,018h		;1138   ; la pausa
	call pausa		;113a
	ld hl,01651h		;113d   ; SCREEN 2
	call pon_registros		;1140
	ld d,000h		;1143   ; la pantalla en blanco
	call borra_pantalla		;1145
	ld de,05800h		;1148   ; los patrones de los sprites (0x1800)
	rst 18h			;114b
	ld hl,01d1bh		;114c   ; el 0: la explosion, tal cual
	ld b,020h		;114f
	rst 20h			;1151
	ld b,00eh		;1152   ; 14 figuras
carga_figura:		; Una figura de 0x1D3B en sus cuatro sentidos: girada, reflejada, girada al otro lado y tal cual
	ld a,b			;1154   ; en la vuelta 3...
	cp 003h		;1155
	jr nz,L_1160		;1157
	push hl			;1159   ; ...128 bytes tal cual (los patrones 0xB4-0xC3)
	exx			;115a
	pop hl			;115b
	ld b,080h		;115c
	rst 20h			;115e
	exx			;115f
L_1160:
	push bc			;1160
	push hl			;1161
	ld de,0e0f4h		;1162   ; al tampon
	call copia_32		;1165
	xor a			;1168   ; girada (mirando abajo)
	call gira_figura		;1169
	ld b,020h		;116c   ; a la VRAM
	ld hl,0e0d4h		;116e
	rst 20h			;1171
	pop hl			;1172
	push hl			;1173
	ld de,0e0f4h		;1174
	call copia_32		;1177   ; al tampon otra vez
	call refleja_figura		;117a   ; reflejada (mirando a la derecha)
	ld b,020h		;117d
	ld hl,0e0f4h		;117f
	rst 20h			;1182
	pop hl			;1183
	push hl			;1184
	ld de,0e0f4h		;1185
	call copia_32		;1188   ; al tampon otra vez
	ld a,0ffh		;118b   ; girada al otro lado (mirando arriba)
	call gira_figura		;118d
	ld b,020h		;1190
	ld hl,0e0d4h		;1192
	rst 20h			;1195
	pop hl			;1196
	ld b,020h		;1197   ; y tal cual (mirando a la izquierda)
	rst 20h			;1199
	pop bc			;119a
	djnz carga_figura		;119b   ; la siguiente
	ld de,07800h		;119d   ; la tabla de nombres (0x3800)
	rst 18h			;11a0
	xor a			;11a1   ; de 0 a 255...
	ld d,003h		;11a2
L_11A4:
	push af			;11a4   ; una pausa para el VDP
	pop af			;11a5
	out (098h),a		;11a6
	inc a			;11a8
	jr nz,L_11A4		;11a9
	dec d			;11ab   ; ...tres veces: un mapa de bits
	jr nz,L_11A4		;11ac
	ld bc,00018h		;11ae   ; los patrones de los tres tercios...
	ld de,04000h		;11b1   ; ...6 KB a cero
	jp vdp_ceros		;11b4
pon_registros:		; Los 8 registros del VDP desde HL
	ld b,008h		;11b7
	ld d,080h		;11b9   ; el registro 0, con el bit 7 de la escritura
L_11BB:
	ld e,(hl)			;11bb   ; su valor
	rst 18h			;11bc
	inc hl			;11bd
	inc d			;11be   ; el siguiente
	djnz L_11BB		;11bf
	ret			;11c1
vdp_ceros:		; C veces 256 ceros (con B a cero) desde la direccion DE
	rst 18h			;11c2
	xor a			;11c3
L_11C4:
	call vdp_rellena		;11c4   ; 256 cada vez
	dec c			;11c7
	jr nz,L_11C4		;11c8
	ret			;11ca
pausa:		; B vueltas de 0x411A
	push hl			;11cb
L_11CC:
	ld hl,0411ah		;11cc   ; una vuelta
L_11CF:
	dec hl			;11cf   ; cuenta atras...
	ld a,h			;11d0
	or l			;11d1   ; ...hasta cero
	jr nz,L_11CF		;11d2
	djnz L_11CC		;11d4   ; B vueltas
	pop hl			;11d6
	ret			;11d7
copia_32:		; 32 bytes de HL a DE
	ld bc,00020h		;11d8
	ldir		;11db
	ret			;11dd

; ----------------------------------------------------------------------
; DATOS letra_lisa_de_sony: 0xFF x 8: la letra 0 de la pantalla de Sony (el
;   fondo de su logotipo)
;   0x11de..0x11e6  (8 bytes)
DATA_letra_lisa_de_sony:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 11de  ........

; ----------------------------------------------------------------------
; DATOS dibujo_cubo: el cubo, 16x16 en el orden de 0x0BFA (arriba izquierda,
;   abajo izquierda, arriba derecha, abajo derecha)
;   0x11e6..0x1206  (32 bytes)
DATA_dibujo_cubo:
	defb 003h,00fh,018h,030h,020h,030h,03ch,017h	; 11e6  ...0 0<.
	defb 017h,01bh,01ch,00ch,00fh,00fh,00fh,007h	; 11ee  ........
	defb 0c0h,0f0h,018h,00ch,004h,00ch,03ch,0e8h	; 11f6  ......<.
	defb 0e8h,0d8h,038h,030h,0f0h,0f0h,0f0h,0e0h	; 11fe  ..80....

; ----------------------------------------------------------------------
; DATOS dibujo_sin_uso_1206: un 8x8 a cuadros que ninguna instruccion pinta:
;   solo lo sube como letra 5 la copia del arranque, y la pantalla de Sony no
;   la nombra
;   0x1206..0x120e  (8 bytes)
DATA_dibujo_sin_uso_1206:
	defb 0dfh,0aah,055h,0aah,0d3h,02ah,0ddh,0bbh	; 1206  ..U..*..

; ----------------------------------------------------------------------
; DATOS dibujo_casilla: la casilla del laberinto: la misma para el pasillo
;   (negro sobre negro), lo pintado (azul sobre azul) y el bloque (verde
;   oscuro sobre verde)
;   0x120e..0x1216  (8 bytes)
DATA_dibujo_casilla:
	defb 0c9h,05dh,010h,046h,051h,014h,0c5h,0d1h	; 120e  .].FQ...

; ----------------------------------------------------------------------
; DATOS dibujo_muro: el muro: un triangulo
;   0x1216..0x121e  (8 bytes)
DATA_dibujo_muro:
	defb 000h,0beh,09eh,08eh,086h,082h,080h,0ffh	; 1216  ........

; ----------------------------------------------------------------------
; DATOS letras_hit_bit: las letras 8 a 0x19 de la pantalla de Sony: "HIT BIT"
;   y su sombra
;   0x121e..0x12ae  (144 bytes)
DATA_letras_hit_bit:
	defb 000h,000h,000h,000h,003h,00fh,00eh,00fh	; 121e  ........
	defb 000h,000h,000h,0fch,0ffh,003h,000h,000h	; 1226  ........
	defb 000h,000h,000h,000h,060h,0e3h,0e3h,067h	; 122e  ....`..g
	defb 000h,000h,000h,03fh,0ffh,0e0h,0c0h,080h	; 1236  ...?....
	defb 000h,000h,000h,080h,0e0h,0f0h,078h,03ch	; 123e  ......x<
	defb 000h,000h,000h,000h,0feh,0ffh,03fh,03bh	; 1246  ......?;
	defb 000h,000h,000h,000h,01fh,01fh,087h,0c7h	; 124e  ........
	defb 000h,000h,000h,000h,0cfh,0cfh,003h,001h	; 1256  ........
	defb 000h,000h,000h,000h,0e3h,0e3h,0c1h,0e3h	; 125e  ........
	defb 000h,000h,000h,000h,0f0h,0f0h,0c0h,080h	; 1266  ........
	defb 00fh,007h,000h,00ch,00eh,00fh,00dh,000h	; 126e  ........
	defb 0feh,0ffh,0ffh,001h,000h,081h,0ffh,0ffh	; 1276  ........
	defb 007h,0c7h,0e7h,0e7h,0e3h,0e3h,0c0h,000h	; 127e  ........
	defb 080h,080h,080h,080h,0c0h,0e0h,0ffh,03fh	; 1286  .......?
	defb 03ch,03ch,03ch,03ch,078h,0f0h,0e0h,080h	; 128e  <<<<x...
	defb 039h,038h,038h,038h,038h,0feh,0feh,000h	; 1296  98888...
	defb 0e7h,0f7h,07fh,03fh,01fh,00fh,007h,000h	; 129e  ...?....
	defb 0f7h,07eh,03ch,03ch,03ch,0ffh,0ffh,000h	; 12a6  .~<<<...

; ----------------------------------------------------------------------
; DATOS dibujo_llama: la llama mediana y grande, 16x16
;   0x12ae..0x12ce  (32 bytes)
DATA_dibujo_llama:
	defb 000h,000h,009h,013h,03bh,01fh,08fh,05fh	; 12ae  ....;.._
	defb 07dh,07dh,03fh,03fh,01fh,01fh,039h,021h	; 12b6  }}??..9!
	defb 080h,088h,0c8h,0c8h,0dah,0f9h,0f2h,0f2h	; 12be  ........
	defb 0f6h,076h,07ch,07ch,0f8h,0f8h,09ch,084h	; 12c6  .v||....

; ----------------------------------------------------------------------
; DATOS premio_abajo_derecha: el cuarto de abajo a la derecha del premio
;   (0x0610)
;   0x12ce..0x12d6  (8 bytes)
DATA_premio_abajo_derecha:
	defb 0f0h,0f0h,0f0h,0e0h,0e0h,0e0h,0e0h,0c0h	; 12ce  ........

; ----------------------------------------------------------------------
; DATOS dibujo_sin_uso_12D6: ocho ceros: la letra 0x1F, que ni la pantalla de
;   Sony nombra ni pinta el juego
;   0x12d6..0x12de  (8 bytes)
DATA_dibujo_sin_uso_12D6:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 12d6  ........

; ----------------------------------------------------------------------
; DATOS piezas_de_sony: las letras 0x20-0x28 de la pantalla de Sony: la
;   plataforma de "HIT BIT"
;   0x12de..0x1326  (72 bytes)
DATA_piezas_de_sony:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 12de  ........
	defb 0f8h,0f8h,0f8h,0f8h,0ffh,0ffh,0ffh,0ffh	; 12e6  ........
	defb 0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h	; 12ee  ........
	defb 0e7h,0e7h,0e7h,000h,000h,000h,000h,0ffh	; 12f6  ........
	defb 0ffh,0ffh,0ffh,000h,000h,0ffh,0ffh,0ffh	; 12fe  ........
	defb 0c3h,0c3h,0c3h,003h,003h,0c3h,0c3h,0c3h	; 1306  ........
	defb 0c0h,0e0h,0f0h,0f8h,0fch,0fch,0feh,0feh	; 130e  ........
	defb 0feh,0feh,0feh,0feh,0feh,0fch,0f8h,0f0h	; 1316  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 131e  ........

; ----------------------------------------------------------------------
; DATOS dibujo_llama_pequena: la llama pequena, 16x16
;   0x1326..0x1346  (32 bytes)
DATA_dibujo_llama_pequena:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1326  ........
	defb 001h,007h,00fh,01fh,00dh,01dh,039h,021h	; 132e  ......9!
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1336  ........
	defb 080h,0e0h,0f0h,0f8h,0b0h,0b8h,09ch,084h	; 133e  ........

; ----------------------------------------------------------------------
; DATOS premio_tres_cuartos: el premio: arriba a la izquierda (0x1346), abajo
;   a la izquierda (0x134E) y arriba a la derecha (0x1356)
;   0x1346..0x135e  (24 bytes)
DATA_premio_tres_cuartos:
	defb 000h,001h,003h,003h,007h,00fh,00fh,01fh	; 1346  ........
	defb 00fh,00fh,00fh,007h,007h,007h,007h,003h	; 134e  ........
	defb 080h,080h,0c0h,0e0h,0e0h,0f0h,0f8h,0f8h	; 1356  ........

; ----------------------------------------------------------------------
; DATOS piezas_de_sony_2: las letras 0x30 y 0x31 de la pantalla de Sony
;   0x135e..0x136e  (16 bytes)
DATA_piezas_de_sony_2:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 135e  ........
	defb 080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh	; 1366  ........

; ----------------------------------------------------------------------
; DATOS dibujos_sin_uso_136E: seis triangulos iguales al de 0x139E: las letras
;   0x32-0x37, que la pantalla de Sony no nombra y el juego no pinta
;   0x136e..0x139e  (48 bytes)
DATA_dibujos_sin_uso_136E:
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 136e  ........
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 1376  ........
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 137e  ........
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 1386  ........
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 138e  ........
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 1396  ........

; ----------------------------------------------------------------------
; DATOS piezas_de_sony_3: las letras 0x38-0x3B de la pantalla de Sony
;   0x139e..0x13be  (32 bytes)
DATA_piezas_de_sony_3:
	defb 0ffh,0ffh,0feh,0feh,0fch,0f8h,0e0h,080h	; 139e  ........
	defb 0ffh,0ffh,0ffh,000h,000h,0ffh,0ffh,0ffh	; 13a6  ........
	defb 0c3h,0c3h,0c3h,003h,003h,0c3h,0c3h,0c3h	; 13ae  ........
	defb 0ffh,000h,000h,000h,000h,0e7h,0e7h,0e7h	; 13b6  ........

; ======================================================================
; CODIGO 0x13be..0x13dd  (31 bytes)
; ======================================================================


a_casillas:		; DE en puntos a DE en casillas: / 8 - 1
	ld a,d			;13be   ; la Y
	call entre_8		;13bf
	dec a			;13c2   ; menos el borde
	ld d,a			;13c3
	ld a,e			;13c4   ; la X
	call entre_8		;13c5
	dec a			;13c8
	ld e,a			;13c9
	ret			;13ca
a_puntos:		; DE en casillas a DE en puntos: (+ 1) * 8
	ld a,d			;13cb   ; la Y, con el borde
	inc a			;13cc
	rlca			;13cd
	rlca			;13ce
	rlca			;13cf
	ld d,a			;13d0
	ld a,e			;13d1   ; la X
	inc a			;13d2
	rlca			;13d3
	rlca			;13d4
	rlca			;13d5
	ld e,a			;13d6
	ret			;13d7
por_16:		; A * 16 (el nibble bajo al alto)
	rlca			;13d8
	rlca			;13d9
	rlca			;13da
	rlca			;13db
	ret			;13dc

; ----------------------------------------------------------------------
; DATOS relleno_13DD: un cero detras del `ret` de 0x13DC: el ultimo byte de la
;   letra 0x3F, que no sale
;   0x13dd..0x13de  (1 bytes)
DATA_relleno_13DD:
	defb 000h	; 13dd

; ----------------------------------------------------------------------
; DATOS piezas_de_sony_4: las letras 0x40 y 0x41 de la pantalla de Sony: dos
;   triangulos
;   0x13de..0x13ee  (16 bytes)
DATA_piezas_de_sony_4:
	defb 0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h	; 13de  ........
	defb 0ffh,07fh,03fh,01fh,00fh,007h,003h,001h	; 13e6  ..?.....

; ======================================================================
; CODIGO 0x13ee..0x141a  (44 bytes)
; ======================================================================


lee_casilla:		; A = el valor (0-3) de la casilla (E, D) del laberinto
	push hl			;13ee
	push de			;13ef
	call casilla_en_ram		;13f0   ; su byte y su sitio
	ex de,hl			;13f3
	or a			;13f4   ; la primera del byte...
	jr nz,L_13FC		;13f5
	ld a,(hl)			;13f7   ; ...los bits 7-6
	and 0c0h		;13f8
	jr L_1405		;13fa
L_13FC:
	cp 001h		;13fc   ; la segunda...
	jr nz,L_1409		;13fe
	ld a,(hl)			;1400   ; ...los bits 5-4
	and 030h		;1401
	rlca			;1403
	rlca			;1404
L_1405:
	rlca			;1405   ; a los bits 1-0
	rlca			;1406
	jr L_1417		;1407
L_1409:
	cp 002h		;1409   ; la tercera...
	jr nz,L_1414		;140b
	ld a,(hl)			;140d   ; ...los bits 3-2
	and 00ch		;140e
	rrca			;1410
	rrca			;1411
	jr L_1417		;1412
L_1414:
	ld a,(hl)			;1414   ; la cuarta: los bits 1-0
	and 003h		;1415
L_1417:
	pop de			;1417
	pop hl			;1418
	ret			;1419

; ----------------------------------------------------------------------
; DATOS salida_de_sparkie: X 0x28, Y 0xB0, estado 0x1F (vivo, carga entera,
;   mirando a la derecha) y su cuenta: lo copia 0x02D0 a 0xE002
;   0x141a..0x141e  (4 bytes)
DATA_salida_de_sparkie:
	defb 028h,0b0h,01fh,000h	; 141a

; ----------------------------------------------------------------------
; DATOS dibujo_sin_uso_141E: un circulo de 8x8 (el de la marca de copyright,
;   sin la C): la letra 0x48, que la pantalla de Sony no nombra
;   0x141e..0x1426  (8 bytes)
DATA_dibujo_sin_uso_141E:
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 141e  <B....B<

; ----------------------------------------------------------------------
; DATOS piezas_de_sony_5: la letra 0x49 de la pantalla de Sony: un triangulo
;   0x1426..0x142e  (8 bytes)
DATA_piezas_de_sony_5:
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,0ffh	; 1426  .....?..

; ======================================================================
; CODIGO 0x142e..0x145e  (48 bytes)
; ======================================================================


casilla_en_ram:		; DE = el byte del laberinto de la casilla (E, D) y A = su sitio en el byte (0-3): 0xE12C + 6 * Y + X / 4
	ld a,e			;142e   ; X / 4
	and 0fch		;142f
	rrca			;1431
	rrca			;1432
	ex af,af'			;1433
	ld a,e			;1434   ; X & 3: el sitio
	and 003h		;1435
	ld c,a			;1437
	ex af,af'			;1438
	ld hl,0e12ch		;1439
	ld e,a			;143c
	ld b,006h		;143d   ; seis bytes por fila
L_143F:
	add a,d			;143f
	djnz L_143F		;1440
	ld e,a			;1442
	ld d,000h		;1443
	add hl,de			;1445   ; sumado a 0xE12C
	ex de,hl			;1446
	ld a,c			;1447
	ret			;1448
entre_8:		; A / 8
	and 0f8h		;1449
	rrca			;144b
	rrca			;144c
	rrca			;144d
	ret			;144e
libres_en_casilla:		; Los sentidos libres de la casilla DE
	push de			;144f
	call a_puntos		;1450   ; a puntos
	call sentidos_libres		;1453
	pop de			;1456
	ret			;1457
palabra:		; DE = la palabra A de la tabla HL (y HL en ella)
	rst 10h			;1458   ; HL + 2 * A
	ld e,(hl)			;1459
	inc hl			;145a
	ld d,(hl)			;145b
	dec hl			;145c
	ret			;145d

; ----------------------------------------------------------------------
; DATOS piezas_de_sony_6: la letra 0x50 de la pantalla de Sony (una barra) y
;   la 0x51, a cero y sin usar
;   0x145e..0x146e  (16 bytes)
DATA_piezas_de_sony_6:
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h	; 145e  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1466  ........

; ======================================================================
; CODIGO 0x146e..0x1488  (26 bytes)
; ======================================================================


boton_una_vez:		; El boton solo cuenta al apretarlo: si ya estaba, se quita de 0xE00E. A = 1 si esta apretado
	bit 3,a		;146e   ; apretado?
	jr z,L_1483		;1470
	ld b,a			;1472
	ld a,(0e11eh)		;1473   ; ya lo estaba?
	or a			;1476
	jr z,L_147F		;1477
	ld a,b			;1479
	res 3,a		;147a   ; si: no cuenta
	ld (0e00eh),a		;147c
L_147F:
	ld a,001h		;147f   ; apretado
	jr L_1484		;1481
L_1483:
	xor a			;1483   ; suelto
L_1484:
	ld (0e11eh),a		;1484
	ret			;1487

; ----------------------------------------------------------------------
; DATOS teclas_a_sentidos: las 16 combinaciones de los cursores (izquierda,
;   arriba, abajo, derecha) al formato del mando: 0x1488 + teclas
;   0x1488..0x1498  (16 bytes)
DATA_teclas_a_sentidos:
	defb 000h,020h,080h,0a0h,040h,060h,000h,000h,010h,000h,090h,000h,050h,000h,000h,000h	; 1488  . ..@`......P...

; ----------------------------------------------------------------------
; DATOS patron_por_sentido: lo que suma al patron cada sentido (arriba 8,
;   abajo 0, izquierda 0x0C, derecha 4): el sprite girado que toca
;   0x1498..0x149c  (4 bytes)
DATA_patron_por_sentido:
	defb 008h,000h,00ch,004h	; 1498

; ----------------------------------------------------------------------
; DATOS relleno_149C: dos ceros: el final de la letra 0x57, que no sale
;   0x149c..0x149e  (2 bytes)
DATA_relleno_149C:
	defb 000h,000h	; 149c

; ----------------------------------------------------------------------
; DATOS piezas_de_sony_7: la letra 0x58 de la pantalla de Sony
;   0x149e..0x14a6  (8 bytes)
DATA_piezas_de_sony_7:
	defb 0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h	; 149e  ........

; ----------------------------------------------------------------------
; DATOS relleno_14A6: ocho ceros: la letra 0x59, que no sale
;   0x14a6..0x14ae  (8 bytes)
DATA_relleno_14A6:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 14a6  ........

; ======================================================================
; CODIGO 0x14ae..0x14b7  (9 bytes)
; ======================================================================


ajusta_a_casilla:		; El objeto IX justo en su casilla
	call a_casillas		;14ae
	call a_puntos		;14b1
	jp pon_posicion		;14b4

; ----------------------------------------------------------------------
; DATOS bit_por_sentido: el bit de cada sentido para 0x0C7D, de dos en dos
;   bytes: 0x40 abajo, 0x20 izquierda, 0x80 arriba y 0x10 derecha
;   0x14b7..0x14bf  (8 bytes)
DATA_bit_por_sentido:
	defb 040h,000h	; 14b7
	defb 020h,000h	; 14b9
	defb 080h,000h	; 14bb
	defb 010h,000h	; 14bd

; ----------------------------------------------------------------------
; DATOS casillas_a_mirar: por cada sentido, en el orden en que se miran
;   (derecha, arriba, izquierda, abajo), dos saltos acumulados (Y, X) de las
;   casillas que pisaria un objeto de 16x16
;   0x14bf..0x14cf  (16 bytes)
DATA_casillas_a_mirar:
	defb 000h,008h,0f8h,000h	; 14bf
	defb 0ffh,0f8h,000h,0f8h	; 14c3
	defb 001h,0ffh,008h,000h	; 14c7
	defb 009h,001h,000h,008h	; 14cb

; ======================================================================
; CODIGO 0x14cf..0x14d6  (7 bytes)
; ======================================================================


pon_posicion:		; La posicion DE al objeto IX
	ld (ix+000h),e		;14cf
	ld (ix+001h),d		;14d2
	ret			;14d5

; ----------------------------------------------------------------------
; DATOS sentido_contrario: el contrario de cada sentido (arriba, abajo,
;   izquierda, derecha): 0x40, 0x80, 0x10, 0x20
;   0x14d6..0x14da  (4 bytes)
DATA_sentido_contrario:
	defb 040h,080h,010h,020h	; 14d6

; ======================================================================
; CODIGO 0x14da..0x14de  (4 bytes)
; ======================================================================


pon_jugador:		; 0xE001 = A
	ld (0e001h),a		;14da
	ret			;14dd

; ----------------------------------------------------------------------
; DATOS fuente: 43 letras de 8x8: (C), espacio, K O N A M I, del 0 al 9, B C D
;   E F G H J L P R S T U V W Y, guion, barra, comillas y el logotipo de
;   Konami en cinco piezas
;   0x14de..0x1636  (344 bytes)
DATA_fuente:
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 14de  <B....B<
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 14e6  ........
	defb 022h,024h,028h,030h,028h,024h,022h,000h	; 14ee  "$(0($".
	defb 018h,024h,042h,042h,042h,024h,018h,000h	; 14f6  .$BBB$..
	defb 022h,022h,032h,02ah,026h,022h,022h,000h	; 14fe  ""2*&"".
	defb 018h,024h,042h,07eh,042h,042h,042h,000h	; 1506  .$B~BBB.
	defb 042h,066h,05ah,05ah,042h,042h,042h,000h	; 150e  BfZZBBB.
	defb 01ch,008h,008h,008h,008h,008h,01ch,000h	; 1516  ........
	defb 03ch,042h,046h,05ah,062h,042h,03ch,000h	; 151e  <BFZbB<.
	defb 008h,018h,038h,008h,008h,008h,008h,000h	; 1526  ..8.....
	defb 03ch,042h,002h,00ch,030h,040h,07eh,000h	; 152e  <B..0@~.
	defb 03ch,042h,002h,01eh,002h,042h,03ch,000h	; 1536  <B...B<.
	defb 004h,00ch,014h,024h,07eh,004h,004h,000h	; 153e  ...$~...
	defb 07ch,040h,078h,004h,002h,044h,038h,000h	; 1546  |@x..D8.
	defb 01ch,020h,040h,07ch,042h,042h,03ch,000h	; 154e  . @|BB<.
	defb 07eh,002h,004h,008h,010h,010h,010h,000h	; 1556  ~.......
	defb 03ch,042h,042h,03ch,042h,042h,03ch,000h	; 155e  <BB<BB<.
	defb 03ch,042h,042h,03eh,002h,004h,038h,000h	; 1566  <BB>..8.
	defb 07ch,022h,022h,03ch,022h,022h,07ch,000h	; 156e  |""<""|.
	defb 01ch,022h,040h,040h,040h,022h,01ch,000h	; 1576  ."@@@"..
	defb 038h,024h,022h,022h,022h,024h,038h,000h	; 157e  8$"""$8.
	defb 03eh,020h,020h,03ch,020h,020h,03eh,000h	; 1586  >  <  >.
	defb 03eh,020h,020h,03ch,020h,020h,020h,000h	; 158e  >  <   .
	defb 01ch,022h,040h,04eh,042h,022h,01ch,000h	; 1596  ."@NB"..
	defb 022h,022h,022h,03eh,022h,022h,022h,000h	; 159e  """>""".
	defb 004h,004h,004h,004h,044h,044h,038h,000h	; 15a6  ....DD8.
	defb 020h,020h,020h,020h,020h,020h,03eh,000h	; 15ae        >.
	defb 03ch,022h,022h,03ch,020h,020h,020h,000h	; 15b6  <""<   .
	defb 03ch,022h,022h,03ch,028h,024h,022h,000h	; 15be  <""<($".
	defb 03ch,042h,040h,03ch,002h,042h,03ch,000h	; 15c6  <B@<.B<.
	defb 03eh,008h,008h,008h,008h,008h,008h,000h	; 15ce  >.......
	defb 022h,022h,022h,022h,022h,022h,01ch,000h	; 15d6  """"""..
	defb 042h,042h,042h,024h,024h,018h,018h,000h	; 15de  BBB$$...
	defb 042h,042h,042h,05ah,05ah,066h,042h,000h	; 15e6  BBBZZfB.
	defb 022h,022h,022h,01ch,008h,008h,008h,000h	; 15ee  """.....
	defb 000h,000h,000h,07eh,000h,000h,000h,000h	; 15f6  ...~....
	defb 000h,002h,004h,008h,010h,020h,040h,000h	; 15fe  ..... @.
	defb 066h,066h,044h,000h,000h,000h,000h,000h	; 1606  ffD.....
	defb 003h,067h,06eh,07ch,079h,079h,07fh,06fh	; 160e  .gn|yy.o
	defb 080h,000h,000h,03dh,0adh,0adh,0adh,03dh	; 1616  ...=...=
	defb 000h,000h,000h,0ceh,063h,06fh,06bh,06fh	; 161e  ....coko
	defb 000h,000h,000h,07ch,056h,056h,056h,056h	; 1626  ...|VVVV
	defb 000h,000h,0c0h,000h,0c0h,0c0h,0c0h,0c0h	; 162e  ........

; ----------------------------------------------------------------------
; DATOS colores_de_sony: los colores de SCREEN 1 de las letras 0x00-0x97; la
;   copia lee 32 bytes y los 13 que faltan son las dos tablas de registros que
;   siguen
;   0x1636..0x1649  (19 bytes)
DATA_colores_de_sony:
	defb 001h,050h,050h,050h,020h,080h,0f0h,02fh,04fh,0f0h,070h,024h,0f0h,0f0h,0f0h,0f0h	; 1636  .PPP ../O.p$....
	defb 0f0h,0f0h,0f0h	; 1646

; ----------------------------------------------------------------------
; DATOS registros_screen1: los 8 registros del VDP de la pantalla de Sony:
;   SCREEN 1, nombres en 0x0400, letras en 0x0800, colores en 0x0780
;   0x1649..0x1651  (8 bytes)
DATA_registros_screen1:
	defb 000h,0e0h,001h,01eh,001h,00eh,000h,001h	; 1649  ........

; ----------------------------------------------------------------------
; DATOS registros_screen2: los 8 del juego: SCREEN 2 con sprites de 16x16,
;   nombres en 0x3800, patrones en 0x0000, colores en 0x2000, sprites en
;   0x3B00 y 0x1800, fondo negro
;   0x1651..0x1659  (8 bytes)
DATA_registros_screen2:
	defb 002h,0e2h,00eh,0ffh,003h,076h,003h,001h	; 1651  .....v..

; ----------------------------------------------------------------------
; DATOS nombres_de_sony: la tabla de nombres de la pantalla de Sony por
;   trozos: el logotipo (10 + 10 en 0x044B y 0x046B), "HIT BIT" (224 en
;   0x0500), "SPARKIE" (7 en 0x062C) y la linea de Konami (12 en 0x068A)
;   0x1659..0x1760  (263 bytes)
DATA_nombres_de_sony:
	defb 008h,009h,00ah,00bh,00ch,00dh,00eh,00fh,010h,011h	; 1659  ..........
	defb 012h,013h,014h,015h,016h,017h,018h,000h,019h,000h	; 1663  ..........
	defb 000h,000h,000h,000h,000h,000h,020h,022h,020h,000h,028h,000h,020h,020h,020h,000h	; 166d  ...... " .(.   .
	defb 000h,000h,020h,020h,026h,000h,028h,000h,020h,020h,020h,000h,000h,000h,000h,000h	; 167d  ..  &.(.   .....
	defb 000h,000h,000h,000h,000h,000h,020h,023h,020h,000h,020h,000h,000h,021h,000h,000h	; 168d  ...... # . ..!..
	defb 000h,000h,024h,025h,027h,000h,020h,000h,000h,021h,000h,000h,000h,000h,000h,000h	; 169d  ..$%'. ..!......
	defb 000h,000h,000h,000h,000h,000h,020h,020h,020h,000h,020h,000h,000h,020h,000h,000h	; 16ad  ......   . .. ..
	defb 000h,000h,020h,020h,026h,000h,020h,000h,000h,020h,000h,000h,000h,000h,000h,000h	; 16bd  ..  &. .. ......
	defb 000h,000h,000h,000h,049h,030h,020h,03bh,020h,030h,020h,030h,030h,020h,030h,030h	; 16cd  ....I0 ; 0 00 00
	defb 030h,030h,039h,03ah,020h,030h,020h,030h,030h,020h,030h,031h,000h,000h,000h,000h	; 16dd  009: 0 00 01....
	defb 000h,000h,000h,049h,030h,030h,020h,058h,020h,040h,020h,040h,030h,020h,040h,030h	; 16ed  ...I00 X @ @0 @0
	defb 030h,041h,020h,020h,038h,041h,020h,030h,041h,020h,030h,030h,031h,000h,000h,000h	; 16fd  0A  8A 0A 001...
	defb 000h,000h,049h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h	; 170d  ..I0000000000000
	defb 030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,030h,031h,000h,000h	; 171d  00000000000001..
	defb 000h,000h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h	; 172d  ..PPPPPPPPPPPPPP
	defb 050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,050h,000h,000h	; 173d  PPPPPPPPPPPPPP..
	defb 07dh,07bh,065h,07ch,062h,067h,075h,060h,061h,086h,087h,088h,089h,08ah,000h,069h	; 174d  }{e|bgu`a......i
	defb 071h,070h,06bh	; 175d

; ======================================================================
; CODIGO 0x1760..0x1801  (161 bytes)
; ======================================================================


gira_cuarto:		; Un cuarto de 8x8 de HL girado a DE (A = 0 un sentido, A distinto de 0 el otro)
	push de			;1760
	ld c,008h		;1761   ; ocho filas
L_1763:
	ld b,008h		;1763   ; ocho bits
	pop de			;1765
	push de			;1766
	or a			;1767   ; de abajo arriba...
	jr nz,L_1771		;1768
	inc de			;176a   ; ...desde la fila 7
	inc de			;176b
	inc de			;176c
	inc de			;176d
	inc de			;176e
	inc de			;176f
	inc de			;1770
L_1771:
	sla (hl)		;1771   ; el bit de la izquierda...
	push hl			;1773
	ld h,d			;1774
	ld l,e			;1775
	rr (hl)		;1776   ; ...entra en la columna de destino
	pop hl			;1778
	dec de			;1779   ; la fila de destino siguiente
	or a			;177a
	jr z,L_177F		;177b
	inc de			;177d
	inc de			;177e
L_177F:
	djnz L_1771		;177f
	inc hl			;1781   ; la fila siguiente del origen
	dec c			;1782
	jr nz,L_1763		;1783
	pop de			;1785
	ret			;1786
gira_figura:		; Los cuatro cuartos del tampon de 0xE0F4 girados a 0xE0D4, y en su orden
	push hl			;1787
	push de			;1788
	push af			;1789
	ld hl,0e0ech		;178a   ; desde 0xE0F4...
	ld de,0e0cch		;178d   ; ...a 0xE0D4
	ld b,004h		;1790   ; cuatro cuartos
L_1792:
	push bc			;1792
	ld bc,00008h		;1793
	add hl,bc			;1796
	push hl			;1797
	ex de,hl			;1798
	add hl,bc			;1799
	ex de,hl			;179a
	push de			;179b
	call gira_cuarto		;179c   ; uno
	pop de			;179f
	pop hl			;17a0
	pop bc			;17a1
	djnz L_1792		;17a2
	or a			;17a4   ; un sentido...
	jr nz,L_17B2		;17a5
	ld iy,01801h		;17a7   ; ...con su orden de cuartos
	ld b,003h		;17ab
	call ordena_cuartos		;17ad
	jr L_17BB		;17b0
L_17B2:
	ld iy,01805h		;17b2   ; o el otro
	ld b,005h		;17b6
	call ordena_cuartos		;17b8
L_17BB:
	pop af			;17bb
	pop de			;17bc
	pop hl			;17bd
	ret			;17be
refleja:		; Los 32 bytes de HL reflejados de izquierda a derecha
	ld c,020h		;17bf
L_17C1:
	ld b,008h		;17c1   ; ocho bits
	ld a,(hl)			;17c3
L_17C4:
	sla a		;17c4   ; el de la izquierda pasa a la derecha
	rr (hl)		;17c6
	djnz L_17C4		;17c8
	inc hl			;17ca
	dec c			;17cb
	jr nz,L_17C1		;17cc
	ret			;17ce
refleja_figura:		; La figura del tampon reflejada, con sus cuartos cambiados de lado
	push hl			;17cf
	push de			;17d0
	push af			;17d1
	ld hl,0e0f4h		;17d2   ; el tampon
	call refleja		;17d5
	ld iy,0180bh		;17d8   ; el orden de los cuartos
	ld b,006h		;17dc
	call ordena_cuartos		;17de
	jr L_17BB		;17e1
copia_8:		; 8 bytes de HL a DE
	ld bc,00008h		;17e3
	ldir		;17e6
	ret			;17e8
ordena_cuartos:		; B cuartos de 8 bytes del tampon de 0xE0D4, en el orden de la tabla IY
	push bc			;17e9
	call cuarto_de_iy		;17ea   ; el origen
	ex de,hl			;17ed
	call siguiente_cuarto		;17ee   ; el destino
	call copia_8		;17f1   ; se copia
	pop bc			;17f4
	djnz ordena_cuartos		;17f5
siguiente_cuarto:		; IY + 1, y HL = 0xE0D4 + 2 * (IY)
	inc iy		;17f7
cuarto_de_iy:		; HL = 0xE0D4 + 2 * (IY)
	ld a,(iy+000h)		;17f9   ; la posicion...
	ld hl,0e0d4h		;17fc   ; ...en el tampon
	rst 10h			;17ff
	ret			;1800

; ----------------------------------------------------------------------
; DATOS orden_de_cuartos: cadenas de copias de 8 bytes (destino, origen,
;   origen...) entre los cuartos del tampon de 0xE0D4, en pasos de 2 bytes: al
;   girar en un sentido (0x1801, 3 copias), en el otro (0x1805, 5) y al
;   reflejar (0x180B, 6)
;   0x1801..0x1812  (17 bytes)
DATA_orden_de_cuartos:
	defb 020h,000h,00ch,020h,020h,000h,004h,00ch,008h,020h,020h,010h,018h,020h,014h,01ch	; 1801   ..  ....  .. ..
	defb 020h	; 1811

; ======================================================================
; CODIGO 0x1812..0x191a  (264 bytes)
; ======================================================================


a_decimal:		; HL en BCD a 0xE24A: cinco cifras
	push de			;1812
	ex de,hl			;1813
	ld hl,0e24ah		;1814   ; el tampon
	ld (hl),000h		;1817
	ld bc,02710h		;1819   ; decenas de millar
	call cifra		;181c
	inc hl			;181f
	ld bc,003e8h		;1820   ; millares
	call cifra		;1823
	ld bc,00064h		;1826   ; centenas
	call cifra		;1829
	inc hl			;182c
	ld bc,0000ah		;182d   ; decenas
	call cifra		;1830
	ld a,e			;1833   ; y unidades
	rld		;1834
	pop de			;1836
	ret			;1837
cifra:		; Una cifra: cuantas veces cabe BC en DE
	ex de,hl			;1838
	sub a			;1839
L_183A:
	sbc hl,bc		;183a   ; se resta
	jr c,L_1841		;183c
	inc a			;183e   ; una vez mas
	jr L_183A		;183f
L_1841:
	add hl,bc			;1841   ; se deshace la ultima
	ex de,hl			;1842
	rld		;1843   ; la cifra entra en el tampon
	ret			;1845

; ----------------------------------------------------------------------
; FALLO: con 10.000 centenas o mas (1.000.000 de puntos) la primera conversion da una quinta cifra, y la segunda (0x185A) convierte HL = 0xE249, que es una direccion y no la puntuacion: el marcador pinta siempre 7929 (medido ejecutando esta rutina con 10.000, 10.050 y 12.345).
; ----------------------------------------------------------------------
pinta_cifras:		; HL en decimal, cuatro cifras desde (E, D), en blanco
	call a_decimal		;1846   ; a decimal
	sub a			;1849
	ld hl,0e24ah		;184a   ; la primera cifra
	rrd		;184d
	or a			;184f   ; a cero: cuatro cifras
	jr z,L_185D		;1850
	ld hl,0e248h		;1852   ; si no: 0xE248-0xE249 a cero...
	ld (hl),000h		;1855
	inc hl			;1857
	ld (hl),000h		;1858
	call a_decimal		;185a   ; ...y otra conversion, con HL = 0xE249
L_185D:
	ld c,004h		;185d   ; cuatro cifras
	ld hl,0e24bh		;185f
L_1862:
	sub a			;1862   ; la cifra
	rld		;1863
	push hl			;1865
	ld hl,0151eh		;1866   ; el 0 de la fuente
	ld b,a			;1869   ; ocho bytes por cifra
	or a			;186a
	jr z,L_1872		;186b
L_186D:
	call hl_mas_8		;186d
	djnz L_186D		;1870
L_1872:
	ld a,0f0h		;1872   ; blanco
	call pinta_casilla		;1874   ; se pinta
	pop hl			;1877
	dec c			;1878
	ret z			;1879
	bit 0,c		;187a   ; dos cifras por byte
	jr nz,L_187F		;187c
	inc hl			;187e
L_187F:
	inc e			;187f   ; la casilla siguiente
	jr L_1862		;1880
hl_mas_8:		; HL + 8
	push af			;1882
	ld a,l			;1883   ; el byte bajo...
	add a,008h		;1884   ; ...mas 8
	ld l,a			;1886
	jr nc,L_188A		;1887   ; sin acarreo, listo
	inc h			;1889   ; con acarreo, H + 1
L_188A:
	pop af			;188a
	ret			;188b

; ----------------------------------------------------------------------
; EL SENTIDO DEL ENEMIGO: de los libres sin dar la vuelta, el que acerca a Sparkie en vertical o en horizontal (el azar del registro R elige cual se mira primero); si ninguno acerca, uno libre al azar; si no hay otro, la vuelta.
; ----------------------------------------------------------------------
sentido_del_enemigo:		; Elige el sentido del enemigo IX entre lo libre (0xE007) y lo que acerca (0xE009)
	call contrario_del_enemigo		;188c   ; el sentido de ahora, al reves
	cpl			;188f   ; todo menos la vuelta...
	ld hl,0e007h		;1890
	and (hl)			;1893   ; ...entre lo libre
	jr z,da_la_vuelta		;1894   ; nada: da la vuelta
	ld (0e11ch),a		;1896   ; lo que se puede
	ld a,r		;1899   ; al azar
	sra a		;189b
	sra a		;189d
	jr nc,L_18B0		;189f   ; vertical u horizontal
	ld a,(0e009h)		;18a1   ; lo que acerca en vertical
	and 0c0h		;18a4
	ld hl,0e11ch		;18a6
	and (hl)			;18a9
	jr z,libre_al_azar		;18aa   ; no se puede
	ld (0e009h),a		;18ac   ; eso
	ret			;18af
L_18B0:
	ld a,(0e009h)		;18b0   ; lo que acerca en horizontal
	and 030h		;18b3
	ld hl,0e11ch		;18b5
	and (hl)			;18b8
	jr z,libre_al_azar		;18b9   ; no se puede
	ld (0e009h),a		;18bb   ; eso
	ret			;18be
da_la_vuelta:		; El sentido contrario
	call contrario_del_enemigo		;18bf
	ld (0e009h),a		;18c2
	ret			;18c5
primero_libre:		; El primer sentido libre, desde el bit 7
	ld hl,0e11ch		;18c6
	ld b,000h		;18c9
	scf			;18cb   ; desde arriba
L_18CC:
	ld a,b			;18cc   ; el bit siguiente
	rra			;18cd
	ld b,a			;18ce
	and (hl)			;18cf   ; libre?
	jr z,L_18CC		;18d0
	ld (0e009h),a		;18d2
	ret			;18d5
libre_al_azar:		; Dos intentos con un sentido al azar; si no, el primero libre
	ld b,002h		;18d6
L_18D8:
	push bc			;18d8
	ld a,r		;18d9   ; de 1 a 4
	and 003h		;18db
	inc a			;18dd
	ld b,a			;18de
	xor a			;18df
	scf			;18e0
L_18E1:
	rra			;18e1   ; su bit
	djnz L_18E1		;18e2
	ld hl,0e11ch		;18e4
	and (hl)			;18e7   ; libre?
	pop bc			;18e8
	jr z,L_18EF		;18e9
	ld (0e009h),a		;18eb   ; eso
	ret			;18ee
L_18EF:
	djnz L_18D8		;18ef
	jr primero_libre		;18f1
contrario_del_enemigo:		; A = el sentido contrario al del enemigo IX (0x191A -> 0x191E)
	ld a,(ix+020h)		;18f3   ; su sentido
	and 0f0h		;18f6
	ld hl,0191ah		;18f8
	ld de,0191eh		;18fb
	call traduce		;18fe
	ret			;1901
traduce:		; Busca A entre los 4 de HL y devuelve el de la misma posicion de DE (0 si no esta)
	push de			;1902
	push hl			;1903
	ld b,004h		;1904
L_1906:
	cp (hl)			;1906   ; este?
	inc hl			;1907
	jr z,L_1911		;1908
	djnz L_1906		;190a
	ld a,000h		;190c   ; no esta: 0
	pop hl			;190e
	pop de			;190f
	ret			;1910
L_1911:
	dec hl			;1911   ; su posicion
	pop de			;1912
	or a			;1913
	sbc hl,de		;1914
	pop de			;1916
	add hl,de			;1917   ; en la otra tabla
	ld a,(hl)			;1918
	ret			;1919

; ----------------------------------------------------------------------
; DATOS sentidos: arriba, abajo, izquierda y derecha: 0x80, 0x40, 0x20, 0x10
;   0x191a..0x191e  (4 bytes)
DATA_sentidos:
	defb 080h,040h,020h,010h	; 191a

; ----------------------------------------------------------------------
; DATOS sentidos_contrarios: sus contrarios: 0x40, 0x80, 0x10, 0x20
;   0x191e..0x1922  (4 bytes)
DATA_sentidos_contrarios:
	defb 040h,080h,010h,020h	; 191e

; ----------------------------------------------------------------------
; DATOS textos_del_menu: siete rotulos (color, X, Y, longitud y letras):
;   "SPARKIE", "(C) Konami 1983" (con el logotipo de cinco piezas),
;   "HIGH-SCORE     00" y las cuatro opciones: "\"1\" KEY 1 PLAYER  W/
;   JOYSTICK", "\"2\" KEY 2 PLAYERS W/ JOYSTICK", "\"3\" KEY 1 PLAYER  W/
;   KEYBOARD" y "\"4\" KEY 2 PLAYERS W/ KEYBOARD"
;   0x1922..0x19d6  (180 bytes)
DATA_textos_del_menu:
	defb 0f0h,00bh,004h,007h	; 1922
	defb 01dh,01bh,005h,01ch,002h,007h,015h	; 1926
	defb 0f0h,009h,006h,00ch	; 192d
	defb 000h,001h,026h,027h,028h,029h,02ah,001h,009h,011h,010h,00bh	; 1931  ..&'()*.....
	defb 0f0h,006h,009h,011h	; 193d
	defb 018h,007h,017h,018h,023h,01dh,013h,003h,01ch,015h,001h,001h,001h,001h,001h,008h,008h	; 1941  ....#............
	defb 070h,001h,00dh,01dh	; 1952
	defb 025h,009h,025h,001h,002h,015h,022h,001h,009h,001h,01bh,01ah,005h,022h,015h,01ch,001h,001h,021h,024h,001h,019h,003h,022h,01dh,01eh,007h,013h,002h	; 1956  %.%..."......"....!$...".....
	defb 070h,001h,00fh,01dh	; 1973
	defb 025h,00ah,025h,001h,002h,015h,022h,001h,00ah,001h,01bh,01ah,005h,022h,015h,01ch,01dh,001h,021h,024h,001h,019h,003h,022h,01dh,01eh,007h,013h,002h	; 1977  %.%..."......"....!$...".....
	defb 0a0h,001h,012h,01dh	; 1994
	defb 025h,00bh,025h,001h,002h,015h,022h,001h,009h,001h,01bh,01ah,005h,022h,015h,01ch,001h,001h,021h,024h,001h,002h,015h,022h,012h,003h,005h,01ch,014h	; 1998  %.%..."......"....!$...".....
	defb 0a0h,001h,014h,01dh	; 19b5
	defb 025h,00ch,025h,001h,002h,015h,022h,001h,00ah,001h,01bh,01ah,005h,022h,015h,01ch,01dh,001h,021h,024h,001h,002h,015h,022h,012h,003h,005h,01ch,014h	; 19b9  %.%..."......"....!$...".....

; ----------------------------------------------------------------------
; DATOS texto_player_1: "PLAYER 1" en X 11, Y 9
;   0x19d6..0x19e2  (12 bytes)
DATA_texto_player_1:
	defb 0f0h,00bh,009h,008h	; 19d6
	defb 01bh,01ah,005h,022h,015h,01ch,001h,009h	; 19da  ..."....

; ----------------------------------------------------------------------
; DATOS laberinto1_mapa: el laberinto 1: 24 filas de 3 bytes, un bit por
;   casilla (1 muro, 0 pasillo)
;   0x19e2..0x1a2a  (72 bytes)
DATA_laberinto1_mapa:
	defb 0ffh,0ffh,0ffh	; 19e2
	defb 080h,000h,001h	; 19e5
	defb 080h,000h,001h	; 19e8
	defb 09fh,099h,0f9h	; 19eb
	defb 09fh,099h,0f9h	; 19ee
	defb 09eh,018h,079h	; 19f1
	defb 09eh,018h,079h	; 19f4
	defb 099h,099h,099h	; 19f7
	defb 099h,099h,099h	; 19fa
	defb 080h,000h,001h	; 19fd
	defb 080h,000h,001h	; 1a00
	defb 09fh,099h,0f9h	; 1a03
	defb 09fh,099h,0f9h	; 1a06
	defb 080h,000h,001h	; 1a09
	defb 080h,000h,001h	; 1a0c
	defb 099h,099h,099h	; 1a0f
	defb 099h,099h,099h	; 1a12
	defb 080h,018h,001h	; 1a15
	defb 080h,018h,001h	; 1a18
	defb 09fh,099h,0f9h	; 1a1b
	defb 09fh,099h,0f9h	; 1a1e
	defb 080h,018h,001h	; 1a21
	defb 080h,018h,001h	; 1a24
	defb 0ffh,0ffh,0ffh	; 1a27

; ----------------------------------------------------------------------
; DATOS laberinto1_objetos: los tres cubos (X, Y en casillas), las cinco
;   llamas, los nueve enemigos (X, Y en puntos; 0 = hueco vacio) y la casilla
;   del premio
;   0x1a2a..0x1a4e  (36 bytes)
DATA_laberinto1_objetos:
	defb 005h,005h,011h,005h,00bh,015h	; 1a2a
	defb 005h,00dh,011h,00dh,00dh,003h,009h,003h,000h,000h	; 1a30  ..........
	defb 000h,000h,000h,000h,030h,010h,090h,010h,030h,050h,090h,050h,000h,000h,000h,000h,000h,000h	; 1a3a  ....0...0P.P......
	defb 00bh,00dh	; 1a4c

; ----------------------------------------------------------------------
; DATOS laberinto1_bloques: los bloques (X, Y en casillas), por grupos
;   separados por un cero y acabados en dos: los cuatro primeros grupos son
;   las listas que arden
;   0x1a4e..0x1a6a  (28 bytes)
DATA_laberinto1_bloques:
	defb 009h,00bh,000h,00bh,009h,000h,00dh,00bh,000h,005h,00fh,003h,011h,005h,011h,007h	; 1a4e  ................
	defb 011h,000h,011h,00fh,00fh,011h,011h,011h,013h,011h,000h,000h	; 1a5e  ............

; ----------------------------------------------------------------------
; DATOS laberinto2_mapa: el laberinto 2: 24 filas de 3 bytes, un bit por
;   casilla (1 muro, 0 pasillo)
;   0x1a6a..0x1ab2  (72 bytes)
DATA_laberinto2_mapa:
	defb 0ffh,0ffh,0ffh	; 1a6a
	defb 080h,018h,001h	; 1a6d
	defb 080h,018h,001h	; 1a70
	defb 099h,099h,099h	; 1a73
	defb 099h,099h,099h	; 1a76
	defb 081h,080h,061h	; 1a79
	defb 081h,080h,061h	; 1a7c
	defb 099h,099h,099h	; 1a7f
	defb 099h,099h,099h	; 1a82
	defb 080h,018h,001h	; 1a85
	defb 080h,018h,001h	; 1a88
	defb 0ffh,09fh,09fh	; 1a8b
	defb 0ffh,09fh,09fh	; 1a8e
	defb 080h,000h,001h	; 1a91
	defb 080h,000h,001h	; 1a94
	defb 099h,099h,0f9h	; 1a97
	defb 099h,099h,0f9h	; 1a9a
	defb 081h,099h,081h	; 1a9d
	defb 081h,099h,081h	; 1aa0
	defb 09fh,099h,099h	; 1aa3
	defb 09fh,099h,099h	; 1aa6
	defb 080h,000h,007h	; 1aa9
	defb 080h,000h,007h	; 1aac
	defb 0ffh,0ffh,0ffh	; 1aaf

; ----------------------------------------------------------------------
; DATOS laberinto2_objetos: los tres cubos (X, Y en casillas), las cinco
;   llamas, los nueve enemigos (X, Y en puntos; 0 = hueco vacio) y la casilla
;   del premio
;   0x1ab2..0x1ad6  (36 bytes)
DATA_laberinto2_objetos:
	defb 001h,00bh,011h,005h,015h,015h	; 1ab2
	defb 003h,005h,009h,001h,015h,001h,013h,00dh,00dh,011h	; 1ab8  ..........
	defb 000h,000h,000h,000h,050h,040h,070h,030h,040h,010h,080h,010h,000h,000h,000h,000h,000h,000h	; 1ac2  ....P@p0@.........
	defb 009h,009h	; 1ad4

; ----------------------------------------------------------------------
; DATOS laberinto2_bloques: los bloques (X, Y en casillas), por grupos
;   separados por un cero y acabados en dos: los cuatro primeros grupos son
;   las listas que arden
;   0x1ad6..0x1af5  (31 bytes)
DATA_laberinto2_bloques:
	defb 011h,00bh,000h,011h,011h,013h,011h,011h,013h,000h,00bh,00dh,000h,005h,007h,000h	; 1ad6  ................
	defb 001h,001h,003h,001h,001h,003h,000h,005h,00fh,003h,011h,005h,011h,000h,000h	; 1ae6  ...............

; ----------------------------------------------------------------------
; DATOS laberinto3_mapa: el laberinto 3: 24 filas de 3 bytes, un bit por
;   casilla (1 muro, 0 pasillo)
;   0x1af5..0x1b3d  (72 bytes)
DATA_laberinto3_mapa:
	defb 0ffh,0ffh,0ffh	; 1af5
	defb 080h,000h,001h	; 1af8
	defb 080h,000h,001h	; 1afb
	defb 09eh,049h,039h	; 1afe
	defb 09eh,04fh,039h	; 1b01
	defb 080h,04fh,039h	; 1b04
	defb 080h,000h,001h	; 1b07
	defb 09eh,000h,001h	; 1b0a
	defb 082h,079h,0f9h	; 1b0d
	defb 082h,000h,007h	; 1b10
	defb 0f2h,000h,007h	; 1b13
	defb 0f2h,079h,0f9h	; 1b16
	defb 082h,040h,039h	; 1b19
	defb 082h,040h,001h	; 1b1c
	defb 09eh,049h,001h	; 1b1f
	defb 080h,049h,039h	; 1b22
	defb 080h,049h,039h	; 1b25
	defb 09fh,0c9h,039h	; 1b28
	defb 080h,009h,001h	; 1b2b
	defb 080h,009h,039h	; 1b2e
	defb 09fh,0c9h,039h	; 1b31
	defb 080h,000h,001h	; 1b34
	defb 080h,000h,001h	; 1b37
	defb 0ffh,0ffh,0ffh	; 1b3a

; ----------------------------------------------------------------------
; DATOS laberinto3_objetos: los tres cubos (X, Y en casillas), las cinco
;   llamas, los nueve enemigos (X, Y en puntos; 0 = hueco vacio) y la casilla
;   del premio
;   0x1b3d..0x1b61  (36 bytes)
DATA_laberinto3_objetos:
	defb 001h,00ah,00dh,004h,015h,009h	; 1b3d
	defb 004h,005h,00ah,001h,011h,006h,004h,00ah,00ah,00ch	; 1b43  ..........
	defb 000h,000h,028h,010h,048h,010h,088h,010h,058h,050h,088h,050h,000h,000h,000h,000h,010h,030h	; 1b4d  ..(.H...XP.P.....0
	defb 00dh,009h	; 1b5f

; ----------------------------------------------------------------------
; DATOS laberinto3_bloques: los bloques (X, Y en casillas), por grupos
;   separados por un cero y acabados en dos: los cuatro primeros grupos son
;   las listas que arden
;   0x1b61..0x1b91  (48 bytes)
DATA_laberinto3_bloques:
	defb 012h,00dh,013h,00dh,000h,007h,003h,000h,010h,003h,010h,004h,000h,00dh,00eh,00dh	; 1b61  ................
	defb 010h,00dh,012h,00dh,013h,000h,007h,00bh,007h,00dh,003h,00fh,005h,00fh,007h,00fh	; 1b71  ................
	defb 000h,003h,012h,005h,012h,007h,012h,008h,012h,000h,012h,011h,013h,011h,000h,000h	; 1b81  ................

; ----------------------------------------------------------------------
; DATOS laberinto4_mapa: el laberinto 4: 24 filas de 3 bytes, un bit por
;   casilla (1 muro, 0 pasillo)
;   0x1b91..0x1bd9  (72 bytes)
DATA_laberinto4_mapa:
	defb 0ffh,0ffh,0ffh	; 1b91
	defb 080h,000h,001h	; 1b94
	defb 080h,000h,001h	; 1b97
	defb 093h,024h,0c9h	; 1b9a
	defb 090h,000h,009h	; 1b9d
	defb 080h,000h,001h	; 1ba0
	defb 082h,066h,041h	; 1ba3
	defb 092h,000h,049h	; 1ba6
	defb 0e0h,000h,007h	; 1ba9
	defb 0e0h,066h,007h	; 1bac
	defb 092h,066h,049h	; 1baf
	defb 080h,000h,001h	; 1bb2
	defb 080h,000h,001h	; 1bb5
	defb 092h,066h,049h	; 1bb8
	defb 080h,066h,001h	; 1bbb
	defb 080h,000h,001h	; 1bbe
	defb 092h,000h,049h	; 1bc1
	defb 082h,066h,041h	; 1bc4
	defb 080h,018h,001h	; 1bc7
	defb 090h,018h,009h	; 1bca
	defb 093h,024h,0c9h	; 1bcd
	defb 080h,000h,001h	; 1bd0
	defb 080h,000h,001h	; 1bd3
	defb 0ffh,0ffh,0ffh	; 1bd6

; ----------------------------------------------------------------------
; DATOS laberinto4_objetos: los tres cubos (X, Y en casillas), las cinco
;   llamas, los nueve enemigos (X, Y en puntos; 0 = hueco vacio) y la casilla
;   del premio
;   0x1bd9..0x1bfd  (36 bytes)
DATA_laberinto4_objetos:
	defb 001h,008h,015h,008h,00bh,012h	; 1bd9
	defb 004h,001h,012h,001h,007h,00dh,012h,00eh,000h,000h	; 1bdf  ..........
	defb 000h,000h,038h,010h,050h,010h,078h,010h,040h,040h,080h,040h,000h,000h,000h,000h,010h,038h	; 1be9  ..8.P.x.@@.@.....8
	defb 00bh,00fh	; 1bfb

; ----------------------------------------------------------------------
; DATOS laberinto4_bloques: los bloques (X, Y en casillas), por grupos
;   separados por un cero y acabados en dos: los cuatro primeros grupos son
;   las listas que arden
;   0x1bfd..0x1c17  (26 bytes)
DATA_laberinto4_bloques:
	defb 00bh,009h,009h,00bh,00bh,00bh,00dh,00bh,00bh,00dh,012h,007h,011h,008h,013h,008h	; 1bfd  ................
	defb 012h,009h,000h,001h,001h,000h,015h,015h,000h,000h	; 1c0d  ..........

; ----------------------------------------------------------------------
; DATOS frase_1: la primera frase de la musica de la fase: su longitud (0x24)
;   y las notas del canal A, con la envolvente; acaba en 0xFE
;   0x1c17..0x1c3c  (37 bytes)
DATA_frase_1:
	defb 024h,03ch,028h,010h,0ffh,005h,047h,020h,035h,020h,047h,010h,03ch,010h,03ch,020h	; 1c17  $<(...G 5 G.<.< 
	defb 03ch,040h,047h,020h,03ch,020h,047h,020h,035h,020h,03ch,010h,047h,010h,047h,020h	; 1c27  <@G < G 5 <.G.G 
	defb 047h,040h,059h,020h,0feh	; 1c37

; ----------------------------------------------------------------------
; DATOS frase_2: la segunda (0x24 bytes)
;   0x1c3c..0x1c61  (37 bytes)
DATA_frase_2:
	defb 024h,050h,028h,010h,0ffh,005h,047h,020h,059h,020h,06ah,010h,050h,010h,050h,020h	; 1c3c  $P(...G Y j.P.P 
	defb 050h,040h,059h,020h,050h,020h,047h,020h,059h,020h,06ah,010h,050h,010h,050h,020h	; 1c4c  P@Y P G Y j.P.P 
	defb 050h,040h,077h,020h,0feh	; 1c5c

; ----------------------------------------------------------------------
; DATOS frase_3: la tercera (0x2C bytes)
;   0x1c61..0x1c8e  (45 bytes)
DATA_frase_3:
	defb 02ch,050h,028h,010h,0ffh,005h,047h,020h,06ah,020h,059h,010h,050h,010h,050h,020h	; 1c61  ,P(...G j Y.P.P 
	defb 047h,020h,06ah,020h,059h,010h,059h,010h,059h,040h,059h,040h,06ah,010h,077h,010h	; 1c71  G j Y.Y.Y@Y@j.w.
	defb 059h,010h,06ah,010h,047h,010h,050h,010h,035h,010h,03ch,010h,0feh	; 1c81  Y.j.G.P.5.<..

; ----------------------------------------------------------------------
; DATOS musica_de_fase: la lista de frases: 1, 2, 1, 3 y un cero, que vuelve a
;   empezar
;   0x1c8e..0x1c98  (10 bytes)
DATA_musica_de_fase:
	defw 01c17h,01c3ch,01c17h,01c61h,00000h	; 1c8e

; ----------------------------------------------------------------------
; DATOS frase_aviso_1: la primera frase del aviso de la carga baja (0x22
;   bytes)
;   0x1c98..0x1cbb  (35 bytes)
DATA_frase_aviso_1:
	defb 022h,03eh,019h,00ah,0eeh,010h,051h,011h,0eeh,010h,03eh,011h,0eeh,010h,051h,011h	; 1c98  ">....Q...>...Q.
	defb 0eeh,010h,03eh,011h,0ddh,011h,0c2h,011h,0a9h,011h,091h,011h,07bh,011h,065h,011h	; 1ca8  ..>.........{.e.
	defb 051h,011h,0feh	; 1cb8

; ----------------------------------------------------------------------
; DATOS frase_aviso_2: la segunda (0x1E bytes)
;   0x1cbb..0x1cda  (31 bytes)
DATA_frase_aviso_2:
	defb 01eh,03eh,019h,00ah,00ch,011h,0e1h,010h,0eeh,010h,00ch,011h,03eh,021h,0c9h,020h	; 1cbb  .>..........>!. 
	defb 0e1h,010h,0eeh,010h,00ch,011h,01ch,011h,03eh,011h,065h,011h,01ch,011h,0feh	; 1ccb  ........>.e....

; ----------------------------------------------------------------------
; DATOS frase_aviso_3: la tercera: una nota (4 bytes)
;   0x1cda..0x1cdf  (5 bytes)
DATA_frase_aviso_3:
	defb 004h,03eh,029h,00ah,0feh	; 1cda

; ----------------------------------------------------------------------
; DATOS musica_de_aviso: su lista: 1, 1, 2, 1, 1, 2, 3 y 0xFFFF, que la acaba
;   0x1cdf..0x1cef  (16 bytes)
DATA_musica_de_aviso:
	defw 01c98h,01c98h,01cbbh,01c98h,01c98h,01cbbh,01cdah,0ffffh	; 1cdf

; ----------------------------------------------------------------------
; DATOS sonido_premio: el premio cogido (bloque 3): dos notas y 0xFF
;   0x1cef..0x1cf5  (6 bytes)
DATA_sonido_premio:
	defb 06ah,028h,00bh,040h,020h,0ffh	; 1cef

; ----------------------------------------------------------------------
; DATOS sonido_choque: el enemigo despedido contra la pared (bloque 3): dos
;   notas y 0xFF
;   0x1cf5..0x1cfb  (6 bytes)
DATA_sonido_choque:
	defb 080h,038h,00bh,080h,031h,0ffh	; 1cf5

; ----------------------------------------------------------------------
; DATOS sonido_disparo: los disparos (bloque 2): siete notas que bajan y 0xFF
;   0x1cfb..0x1d0b  (16 bytes)
DATA_sonido_disparo:
	defb 06ch,018h,00dh,064h,010h,060h,010h,050h,010h,044h,010h,040h,010h,03ch,010h,0ffh	; 1cfb  l..d.`.P.D.@.<..

; ----------------------------------------------------------------------
; DATOS sonido_muerte: la muerte de Sparkie, en los cuatro bloques: una nota
;   con la envolvente y 0xFF
;   0x1d0b..0x1d11  (6 bytes)
DATA_sonido_muerte:
	defb 0fch,02fh,010h,000h,040h,0ffh	; 1d0b

; ----------------------------------------------------------------------
; DATOS sonido_zumbido: el zumbido de fondo (bloque 2): cuatro notas y 0x00,
;   que lo vuelve a poner
;   0x1d11..0x1d1b  (10 bytes)
DATA_sonido_zumbido:
	defb 080h,018h,00bh,07ah,010h,070h,010h,060h,010h,000h	; 1d11  ...z.p.`..

; ----------------------------------------------------------------------
; DATOS sprite_explosion: la explosion de Sparkie, 16x16 (cuatro cuartos de
;   8x8): el patron 0, sin girar
;   0x1d1b..0x1d3b  (32 bytes)
DATA_sprite_explosion:
	defb 0a9h,055h,0abh,053h,0aeh,04dh,03bh,0f7h	; 1d1b  .U.S.M;.
	defb 0f7h,03bh,04dh,0aeh,053h,0abh,055h,0a9h	; 1d23  .;M.S.U.
	defb 095h,0aah,0d5h,0cah,075h,0b2h,0dch,095h	; 1d2b  ....u...
	defb 0efh,0dch,0b2h,075h,0cah,0d5h,0aah,095h	; 1d33  ...u....

; ----------------------------------------------------------------------
; DATOS sprites_figuras: las 14 figuras de 16x16 mirando a la izquierda, que
;   0x1154 sube en cuatro sentidos: la llamita (0x1D3B), dos de los enemigos
;   de la tanda 4, dos de la tanda 2, dos de la tanda 8, dos de Sparkie, dos
;   de la cola con la carga entera y tres de la cola gastada
;   0x1d3b..0x1efb  (448 bytes)
DATA_sprites_figuras:
	defb 000h,000h,000h,000h,006h,00fh,00fh,01ch	; 1d3b  ........
	defb 03ch,01eh,007h,003h,001h,000h,000h,000h	; 1d43  <.......
	defb 000h,000h,030h,030h,078h,0f8h,0fch,098h	; 1d4b  ..00x...
	defb 090h,0d0h,0e0h,0e0h,0c0h,080h,000h,000h	; 1d53  ........
	defb 000h,001h,006h,01fh,03fh,07fh,049h,06dh	; 1d5b  ....?.Im
	defb 06dh,07fh,03fh,01fh,009h,01bh,03fh,000h	; 1d63  m.?...?.
	defb 04eh,0b4h,0aeh,0dch,0d2h,0ech,0d0h,0f0h	; 1d6b  N.......
	defb 0e0h,0e0h,0c0h,080h,000h,000h,000h,000h	; 1d73  ........
	defb 001h,001h,006h,01fh,03fh,07fh,06dh,06dh	; 1d7b  ....?.mm
	defb 049h,07fh,03fh,01fh,010h,031h,073h,000h	; 1d83  I.?..1s.
	defb 0a8h,068h,0d4h,034h,0c8h,0f8h,0e8h,0f0h	; 1d8b  .h.4....
	defb 0f0h,0c0h,0c0h,080h,080h,080h,080h,000h	; 1d93  ........
	defb 000h,001h,007h,00fh,01fh,01fh,015h,00ah	; 1d9b  ........
	defb 015h,03fh,03fh,021h,039h,03fh,03fh,000h	; 1da3  .??!9??.
	defb 000h,000h,000h,000h,000h,018h,03ch,03ch	; 1dab  ......<<
	defb 038h,0f8h,0f8h,008h,0c8h,0f8h,0f8h,000h	; 1db3  8.......
	defb 0c0h,070h,03ch,03eh,03fh,01fh,015h,00ah	; 1dbb  .p<>?...
	defb 015h,03fh,03fh,021h,027h,03fh,03fh,000h	; 1dc3  .??!'??.
	defb 000h,000h,000h,000h,000h,018h,03ch,03ch	; 1dcb  ......<<
	defb 038h,0f8h,0f8h,008h,038h,0f8h,0f8h,000h	; 1dd3  8...8...
	defb 000h,000h,003h,007h,00fh,01fh,032h,072h	; 1ddb  ......2r
	defb 072h,072h,03fh,01fh,00fh,00fh,01ch,01eh	; 1de3  rr?.....
	defb 000h,0c0h,080h,038h,070h,0e6h,07ch,07fh	; 1deb  ...8p.|.
	defb 07ch,078h,0f8h,0feh,0fch,0f0h,03ah,03ch	; 1df3  |x....:<
	defb 000h,000h,003h,007h,00fh,01fh,032h,072h	; 1dfb  ......2r
	defb 072h,072h,03fh,01fh,00fh,00fh,007h,007h	; 1e03  rr?.....
	defb 000h,0e0h,080h,03dh,072h,0e5h,07ch,07fh	; 1e0b  ...=r.|.
	defb 07ch,078h,0f9h,0feh,0fch,0f0h,038h,0bch	; 1e13  |x....8.
	defb 000h,007h,00fh,01fh,03fh,024h,024h,036h	; 1e1b  ....?$$6
	defb 0f6h,0bfh,01fh,00fh,09fh,0d0h,078h,000h	; 1e23  ......x.
	defb 000h,0e3h,0feh,0f8h,0fch,0fch,0fch,0fch	; 1e2b  ........
	defb 0ffh,0fdh,0f8h,0f9h,0efh,003h,00eh,000h	; 1e33  ........
	defb 000h,007h,00fh,01fh,03fh,024h,024h,024h	; 1e3b  ....?$$$
	defb 02dh,03fh,01fh,00fh,007h,002h,01fh,000h	; 1e43  -?......
	defb 000h,0e3h,0feh,0f8h,0fch,0fch,0fch,0fch	; 1e4b  ........
	defb 0fch,0fch,0f8h,0f0h,0e0h,040h,0f0h,000h	; 1e53  .....@..
	defb 000h,0e0h,010h,008h,004h,002h,001h,000h	; 1e5b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1e63  ........
	defb 000h,000h,000h,000h,000h,001h,002h,084h	; 1e6b  ........
	defb 078h,000h,000h,000h,000h,000h,000h,000h	; 1e73  x.......
	defb 000h,0e0h,010h,008h,004h,002h,001h,000h	; 1e7b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1e83  ........
	defb 000h,000h,000h,000h,000h,000h,000h,080h	; 1e8b  ........
	defb 078h,004h,002h,001h,000h,000h,000h,000h	; 1e93  x.......
	defb 008h,0f4h,038h,014h,028h,000h,000h,000h	; 1e9b  ..8.(...
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1ea3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1eab  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1eb3  ........
	defb 000h,0e0h,010h,008h,004h,003h,003h,005h	; 1ebb  ........
	defb 002h,000h,000h,000h,000h,000h,000h,000h	; 1ec3  ........
	defb 000h,000h,000h,000h,080h,040h,080h,040h	; 1ecb  .....@.@
	defb 080h,000h,000h,000h,000h,000h,000h,000h	; 1ed3  ........
	defb 000h,0e0h,010h,008h,004h,002h,001h,000h	; 1edb  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 1ee3  ........
	defb 000h,000h,000h,000h,000h,000h,014h,08ah	; 1eeb  ........
	defb 07ch,08ah,014h,000h,000h,000h,000h,000h	; 1ef3  |.......

; ----------------------------------------------------------------------
; DATOS dibujo_ola: la ola, 16x16 en el orden de 0x0BFA, una por sentido:
;   arriba, abajo, izquierda y derecha (0x04A1)
;   0x1efb..0x1f7b  (128 bytes)
DATA_dibujo_ola:
	defb 03bh,07eh,0ceh,096h,0dch,07dh,03fh,00fh	; 1efb  ;~...}?.
	defb 01bh,01bh,009h,007h,003h,003h,003h,003h	; 1f03  ........
	defb 0dch,0e6h,0ceh,0fch,0d8h,0b0h,0e0h,0fch	; 1f0b  ........
	defb 036h,066h,0ech,0f8h,070h,040h,070h,0c0h	; 1f13  6f..p@p.
	defb 003h,007h,002h,00eh,01fh,037h,066h,06ch	; 1f1b  .....7fl
	defb 03fh,007h,00dh,01bh,03fh,073h,067h,03bh	; 1f23  ?...?sg;
	defb 0c0h,0c0h,0c0h,0c0h,0e0h,090h,0d8h,0d8h	; 1f2b  ........
	defb 0f0h,0fch,0beh,03bh,069h,073h,07eh,0dch	; 1f33  ...;is~.
	defb 000h,060h,0f1h,0b9h,09dh,057h,0fbh,0ffh	; 1f3b  .`...W..
	defb 087h,0f3h,07fh,0efh,0deh,0c6h,06ch,038h	; 1f43  ......l8
	defb 000h,060h,0f0h,098h,0cch,0fdh,0bfh,099h	; 1f4b  .`......
	defb 0ffh,0efh,088h,0f0h,060h,000h,000h,000h	; 1f53  ....`...
	defb 000h,000h,000h,003h,007h,008h,0fbh,0ffh	; 1f5b  ........
	defb 0cch,0feh,05fh,019h,00ch,007h,003h,000h	; 1f63  .._.....
	defb 01ch,036h,063h,07bh,0f7h,0feh,0cfh,0e1h	; 1f6b  .6c{....
	defb 0ffh,0dfh,0eah,0b9h,09dh,08fh,006h,000h	; 1f73  ........

; ----------------------------------------------------------------------
; DATOS dibujo_disparo: el disparo, igual: arriba, abajo, izquierda y derecha
;   0x1f7b..0x1ffb  (128 bytes)
DATA_dibujo_disparo:
	defb 007h,00fh,00fh,007h,001h,001h,001h,000h	; 1f7b  ........
	defb 007h,00fh,00fh,007h,001h,001h,001h,000h	; 1f83  ........
	defb 0e0h,0f0h,0f0h,0e0h,080h,080h,080h,000h	; 1f8b  ........
	defb 0e0h,0f0h,0f0h,0e0h,080h,080h,080h,000h	; 1f93  ........
	defb 000h,001h,001h,001h,007h,00fh,00fh,00eh	; 1f9b  ........
	defb 000h,001h,001h,001h,007h,00fh,00fh,00eh	; 1fa3  ........
	defb 000h,080h,080h,080h,0e0h,0f0h,0f0h,0e0h	; 1fab  ........
	defb 000h,080h,080h,080h,0e0h,0f0h,0f0h,0e0h	; 1fb3  ........
	defb 000h,000h,000h,000h,060h,0f0h,0f0h,0feh	; 1fbb  ....`...
	defb 0feh,0f0h,0f0h,060h,000h,000h,000h,000h	; 1fc3  ...`....
	defb 000h,000h,000h,000h,060h,0f0h,0f0h,0feh	; 1fcb  ....`...
	defb 0feh,0f0h,0f0h,060h,000h,000h,000h,000h	; 1fd3  ...`....
	defb 000h,000h,000h,000h,006h,00fh,00fh,07fh	; 1fdb  ........
	defb 07fh,00fh,00fh,006h,000h,000h,000h,000h	; 1fe3  ........
	defb 000h,000h,000h,000h,006h,00fh,00fh,07fh	; 1feb  ........
	defb 07fh,00fh,00fh,006h,000h,000h,000h,000h	; 1ff3  ........

; ----------------------------------------------------------------------
; DATOS cola_de_la_rom: 5B FF FF FF 04: detras del ultimo dibujo, sin nadie
;   que los lea
;   0x1ffb..0x2000  (5 bytes)
DATA_cola_de_la_rom:
	defb 05bh,0ffh,0ffh,0ffh,004h	; 1ffb
