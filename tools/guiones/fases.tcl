# Las fases seguidas: "3" en el menu y, cada 500 cuadros, los 13 enemigos a
# cero (0xE1FC-0xE215): el bucle principal da la fase por acabada y monta la
# siguiente. 2600 cuadros: las cuatro fases y la vuelta a la primera.
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
proc guion {n} {
    if {$n % 500 == 250} {
        for {set a 0xE1FC} {$a < 0xE216} {incr a 2} { debug write memory $a 0 }
    }
    return [expr {$n >= 2600}]
}
