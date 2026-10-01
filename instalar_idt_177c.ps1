$ErrorActionPreference = 'Stop'

# 0) Comprobar que el modo de prueba ya esta ACTIVO (requiere reinicio previo)
$opts = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control').SystemStartOptions
if ($opts -notmatch 'TESTSIGNING') { throw "El modo de prueba aun no esta activo. Reinicia el equipo y vuelve a ejecutar." }

# 1) Punto de restauracion
try {
  Enable-ComputerRestore -Drive 'C:\'
  Checkpoint-Computer -Description 'Antes de instalar IDT 177C modificado' -RestorePointType MODIFY_SETTINGS
} catch { Write-Warning "Punto de restauracion no creado: $_ (Windows limita 1 cada 24 h; ya existe uno de hoy)" }

# 2) Copiar el paquete original de HP (sp65008, IDT 6.10.6498)
$src = 'C:\Users\Admin\AppData\Local\Temp\claude\C--Users-Admin\5f1a82b8-9dfe-4da6-bea3-1b4e795a8262\scratchpad\ex_sp65008\WDM'
$dst = 'C:\IDT_177C'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
Copy-Item $src $dst -Recurse

# 3) Agregar SUBSYS_103C177C al INF (copiando la linea de 17CE)
$inf = "$dst\STWRT64.INF"
$raw = [IO.File]::ReadAllBytes($inf)
$bom = ($raw[0] -eq 0xFF -and $raw[1] -eq 0xFE)
$txt = if ($bom) { [Text.Encoding]::Unicode.GetString($raw) } else { [Text.Encoding]::Default.GetString($raw) }
$out = New-Object System.Collections.Generic.List[string]
foreach ($l in ($txt -split "`r?`n")) {
  $out.Add($l)
  if ($l -match 'DEV_7605&SUBSYS_103C17CE\s*$') { $out.Add(($l -replace '17CE','177C')) }
}
$new = $out -join "`r`n"
$bytes = if ($bom) { [Text.Encoding]::Unicode.GetPreamble() + [Text.Encoding]::Unicode.GetBytes($new) } else { [Text.Encoding]::Default.GetBytes($new) }
[IO.File]::WriteAllBytes($inf, $bytes)
Select-String $inf -Pattern '103C177C' | ForEach-Object Line

# 4) Mapear 177C al mismo perfil de configuracion que 17CE (WRT_M11-6E.INI)
$ini = "$dst\stwrt64.ini"
$c = [IO.File]::ReadAllText($ini)
$c = $c -replace '(HDAUDIO\\FUNC_01&VEN_111D&DEV_7605&SUBSYS_103C17CE=WRT_M11-6E\.INI)', "`$1`r`nHDAUDIO\FUNC_01&VEN_111D&DEV_7605&SUBSYS_103C177C=WRT_M11-6E.INI"
[IO.File]::WriteAllText($ini, $c)
Select-String $ini -Pattern '177C' | ForEach-Object Line

# 5) Quitar la referencia al catalogo (su hash ya no coincide) e instalar
$t = [IO.File]::ReadAllText($inf)
$t = $t -replace '(?m)^CatalogFile\s*=.*\r?$', ';CatalogFile removed (test signing)'
[IO.File]::WriteAllText($inf, $t, $(if ($bom) { [Text.Encoding]::Unicode } else { [Text.Encoding]::Default }))
pnputil /add-driver "$dst\STWRT64.INF" /install
pnputil /scan-devices
Write-Host "`nListo. Revisa si el LED cambia al silenciar. Si pnputil dio error, avisame con el texto exacto." -ForegroundColor Green

