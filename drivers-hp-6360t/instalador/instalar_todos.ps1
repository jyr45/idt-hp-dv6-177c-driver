param([switch]$SoloProbar)   # -SoloProbar: muestra que haria, sin instalar nada

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$log  = Join-Path $here ("instalacion_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
Start-Transcript -Path $log | Out-Null

Write-Host "=== Drivers HP 6360t ===" -ForegroundColor Cyan
if ($SoloProbar) { Write-Host "(modo prueba: no se instalara nada)" -ForegroundColor Yellow }

# Aviso si no parece ser el equipo correcto
$modelo = (Get-CimInstance Win32_ComputerSystem).Model
Write-Host "Equipo detectado: $modelo"
if ($modelo -notmatch '6360|6460|8460') {
  Write-Warning "Este pack es para la HP 6360t / ProBook 6360b. Tu equipo es: $modelo"
  if (-not $SoloProbar) {
    $r = Read-Host "Continuar de todos modos? (S/N)"
    if ($r -notmatch '^[sS]') { Stop-Transcript | Out-Null; return }
  }
}

# Punto de restauracion
if (-not $SoloProbar) {
  try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
    Checkpoint-Computer -Description 'Antes de instalar drivers HP 6360t' -RestorePointType MODIFY_SETTINGS
    Write-Host "Punto de restauracion creado." -ForegroundColor Green
  } catch { Write-Warning "No se pudo crear el punto de restauracion: $_" }
}

# Drivers estandar (todos menos el audio parcheado)
$paquetes = Get-ChildItem (Join-Path $here 'drivers') -Directory | Sort-Object Name
$ok = 0; $fallo = @(); $reiniciar = $false
foreach ($p in $paquetes) {
  $inf = Get-ChildItem $p.FullName -Filter *.inf -File | Select-Object -First 1
  if (-not $inf) { Write-Warning "Sin .inf en $($p.Name)"; continue }
  Write-Host "`n> $($p.Name)" -ForegroundColor White
  if ($SoloProbar) { Write-Host "  pnputil /add-driver `"$($inf.Name)`" /install"; $ok++; continue }
  pnputil /add-driver $inf.FullName /install
  switch ($LASTEXITCODE) {
    0       { $ok++ }
    3010    { $ok++; $reiniciar = $true }
    default { $fallo += "$($p.Name) (codigo $LASTEXITCODE)" }
  }
}

# Audio IDT parcheado (opcional)
$audio = Join-Path $here 'audio-IDT-177C\instalar.ps1'
if (Test-Path $audio) {
  Write-Host "`nAudio IDT 92HD81B1C parcheado (LED del boton de silencio)." -ForegroundColor Cyan
  Write-Host "Requiere activar el 'modo de prueba' de firma de Windows y reiniciar."
  if ($SoloProbar) {
    Write-Host "  (preguntaria si instalar el audio IDT)"
  } else {
    $r = Read-Host "Instalar tambien el audio IDT parcheado? (S/N)"
    if ($r -match '^[sS]') { & $audio }
  }
}

if (-not $SoloProbar) { pnputil /scan-devices | Out-Null }

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Correctos: $ok de $($paquetes.Count)"
if ($fallo.Count) { Write-Host "Con error:" -ForegroundColor Red; $fallo | ForEach-Object { Write-Host "  - $_" } }
if ($reiniciar -or $ok -gt 0) { Write-Host "Reinicia el equipo para terminar." -ForegroundColor Yellow }
Write-Host "Registro: $log"
Stop-Transcript | Out-Null
