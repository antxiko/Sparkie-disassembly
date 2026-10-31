# Una partida guiada: "3" en el menu; Sparkie a la derecha hasta dos casillas
# del cubo de abajo (x 80), boton; luego arriba, y el boton cada 40 cuadros.
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
set ::fase 0
set ::t0 0
proc suelta_todo {} { foreach b {0x01 0x10 0x20 0x40 0x80} { keymatrixup 8 $b } }
proc guion {n} {
    set x [debug read memory 0xE002]
    set vivo [expr {[debug read memory 0xE004] & 8}]
    switch $::fase {
        0 { if {$vivo && [debug read memory 0xE0A3] == 0} { keymatrixdown 8 0x80; set ::fase 1 } }
        1 { if {$x >= 80} { suelta_todo; keymatrixdown 8 0x01; set ::t0 $n; set ::fase 2 } }
        2 { if {$n - $::t0 > 10} { suelta_todo; keymatrixdown 8 0x10; set ::t0 $n; set ::fase 3 } }
        3 { if {$n - $::t0 > 60} { suelta_todo; keymatrixdown 8 0x20; set ::t0 $n; set ::fase 4 } }
        4 { if {($n - $::t0) % 40 == 0} { keymatrixdown 8 0x01 } elseif {($n - $::t0) % 40 == 8} { keymatrixup 8 0x01 } }
    }
    return [expr {$n >= 1500}]
}
