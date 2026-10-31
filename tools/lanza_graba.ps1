# lanza_graba.ps1 -guion tools/guiones/x.tcl -salida work/x.bin: UN openMSX con
# tools/omsx_graba.tcl, fuera del sandbox, minimizado
param([string]$guion, [string]$salida, [string]$rom = "sparkie.rom", [string]$bp = "0x0038", [string]$ram = "0xE000 0x800", [string]$bp2 = "")
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz
$env:GRABA_SALIDA = $salida
$env:GRABA_GUION = $guion
$env:GRABA_BP = $bp
$env:GRABA_RAM = $ram
if ($bp2) { $env:GRABA_BP2 = $bp2 } else { Remove-Item Env:GRABA_BP2 -ErrorAction SilentlyContinue }
$args_ = @("-machine", "C-BIOS_MSX1_JP", "-cart", $rom, "-script", "tools/omsx_graba.tcl")
Start-Process -FilePath "C:\Program Files\openMSX\openmsx.exe" -ArgumentList $args_ -Wait -WindowStyle Minimized
