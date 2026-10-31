# omsx_vuelca.tcl - la VRAM, los 8 registros del VDP y la RAM 0xE000-0xE7FF en
# los instantes de VUELCA_T (segundos emulados), para pintarlos con tools/vdp.py
# (cada volcado en el mismo formato que un cuadro de omsx_graba.tcl).
set OUT $::env(VUELCA_SALIDA)
file mkdir $OUT
set throttle off
proc vuelca {t} {
    set f [open [format "%s/t%05.1f.bin" $::OUT $t] w]
    fconfigure $f -translation binary
    puts -nonewline $f "V[debug read_block {VDP regs} 0 8][debug read_block memory 0xE000 0x800][debug read_block {PSG regs} 0 16][binary format d [machine_info time]][binary format c 16][join [lmap i {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15} {string cat [binary format c $i] [debug read_block VRAM [expr {$i*1024}] 1024]}] {}]"
    close $f
}
foreach t $::env(VUELCA_T) { after time $t [list vuelca $t] }
after time [expr {[lindex [lsort -real $::env(VUELCA_T)] end] + 1}] exit
