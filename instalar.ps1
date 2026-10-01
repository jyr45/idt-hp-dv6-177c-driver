$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$opts = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control').SystemStartOptions
if ($opts -notmatch 'TESTSIGNING') {
  bcdedit /set testsigning on
  Write-Host "`nModo de prueba activado. REINICIA el equipo y vuelve a ejecutar instalar.cmd." -ForegroundColor Yellow
  return
}
try { Enable-ComputerRestore -Drive 'C:\'; Checkpoint-Computer -Description 'Antes de instalar IDT 177C' -RestorePointType MODIFY_SETTINGS } catch { Write-Warning "Punto de restauracion no creado: $_" }

$dst = Join-Path $env:TEMP 'IDT_177C'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
Copy-Item "$here\driver" $dst -Recurse
$inf = "$dst\STWRT64.INF"
$t = [IO.File]::ReadAllText($inf)
if ($t -notmatch '(?m)^CatalogFile\s*=') { throw "El INF no tiene la linea CatalogFile" }

$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=IDT177C Test Signing' -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(3)
$cer = "$env:TEMP\idt177c.cer"
Export-Certificate -Cert $cert -FilePath $cer | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null

Remove-Item "$dst\stwrt64.cat" -ErrorAction SilentlyContinue
$cat = "$env:TEMP\stwrt64.cat"; Remove-Item $cat -ErrorAction SilentlyContinue
New-FileCatalog -Path $dst -CatalogFilePath $cat -CatalogVersion 2 | Out-Null
Set-AuthenticodeSignature -FilePath $cat -Certificate $cert | Out-Null
Copy-Item $cat "$dst\stwrt64.cat" -Force

pnputil /add-driver $inf /install
pnputil /scan-devices
Write-Host "`nListo. Reinicia y prueba el boton de mute." -ForegroundColor Green
