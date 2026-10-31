# El premio: en el cuadro 60 dos de los tres cubos se dan por cogidos (su estado,
# 0xE1C2 y 0xE1C4, a cero): queda uno y 0x0639 saca el premio. Sparkie va a la
# derecha por el pasillo de abajo y sube por el centro hasta el premio.
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
proc guion {n} {
    if {$n == 60} { debug write memory 0xE1C2 0; debug write memory 0xE1C4 0 }
    set x [debug read memory 0xE002]
    if {$n == 70} { keymatrixdown 8 0x80 }
    if {$n > 70 && $x >= 80} { keymatrixup 8 0x80; keymatrixdown 8 0x20 }
    return [expr {$n >= 700}]
}
