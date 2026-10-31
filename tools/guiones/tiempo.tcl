# TIME OVER: "3" en el menu y, en el cuadro 60, la cuenta de la fase a 0x0FC0:
# 64 cuadros despues llega a 0x1000 (bit 4 de 0xE048).
after time 8 { keymatrixdown 0 0x08 }
after time 8.5 { keymatrixup 0 0x08 }
proc guion {n} {
    if {$n == 60} { debug write memory 0xE047 0xC0; debug write memory 0xE048 0x0F }
    return [expr {$n >= 600}]
}
