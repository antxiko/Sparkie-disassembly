# Sparkie quieto en la salida, mirando a la derecha, y el boton cada 12
# cuadros: los enemigos que bajan por el pasillo de abajo se llevan los disparos.
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
proc guion {n} {
    if {$n % 12 == 0} { keymatrixdown 8 0x01 } elseif {$n % 12 == 4} { keymatrixup 8 0x01 }
    return [expr {$n >= 2400}]
}
