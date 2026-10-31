# GAME OVER: en el cuadro 60 se deja una sola vida (0xE24F = 1) y Sparkie se
# queda quieto hasta que algo lo mata.
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
proc guion {n} {
    if {$n == 60} { debug write memory 0xE24F 1 }
    return [expr {$n >= 1500}]
}
