# Una partida con el teclado: "3" en el menu (un jugador, teclado) y luego las
# flechas a ratos. 2400 cuadros.
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
set ::mov {0x80 0x40 0x10 0x20 0x80 0x20 0x10 0x40}
proc guion {n} {
    if {$n % 90 == 0} {
        foreach b {0x10 0x20 0x40 0x80} { keymatrixup 8 $b }
        keymatrixdown 8 [lindex $::mov [expr {($n / 90) % 8}]]
    }
    return [expr {$n >= 2400}]
}
