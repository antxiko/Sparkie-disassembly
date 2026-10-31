# lanza_vuelca.ps1 -salida work/v -t "1 2 3": UN openMSX con tools/omsx_vuelca.tcl
param([string]$salida, [string]$t, [string]$rom = "sparkie.rom")
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz
$env:VUELCA_SALIDA = $salida
$env:VUELCA_T = $t
$args_ = @("-machine", "C-BIOS_MSX1_JP", "-cart", $rom, "-script", "tools/omsx_vuelca.tcl")
Start-Process -FilePath "C:\Program Files\openMSX\openmsx.exe" -ArgumentList $args_ -Wait -WindowStyle Minimized
