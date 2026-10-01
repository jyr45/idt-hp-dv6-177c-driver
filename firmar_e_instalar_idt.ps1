$ErrorActionPreference = 'Stop'
$dst = 'C:\IDT_177C'
$inf = "$dst\STWRT64.INF"
if (-not (Test-Path $inf)) { throw "Falta $inf. Ejecuta primero instalar_idt_177c.ps1" }

# 1) Restaurar la referencia al catalogo en el INF
$raw = [IO.File]::ReadAllBytes($inf)
$bom = ($raw[0] -eq 0xFF -and $raw[1] -eq 0xFE)
$enc = if ($bom) { [Text.Encoding]::Unicode } else { [Text.Encoding]::Default }
$t = [IO.File]::ReadAllText($inf)
$t = $t -replace '(?m)^;CatalogFile removed \(test signing\)', 'CatalogFile=stwrt64.cat'
[IO.File]::WriteAllText($inf, $t, $enc)
Select-String $inf -Pattern '^CatalogFile' -Encoding Unicode | ForEach-Object Line

# 2) Certificado de prueba (autofirmado) y confianza como raiz + editor
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=IDT177C Test Signing' -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(3)
$cer = "$env:TEMP\idt177c.cer"
Export-Certificate -Cert $cert -FilePath $cer | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null

# 3) Crear y firmar el catalogo
Remove-Item "$dst\stwrt64.cat" -ErrorAction SilentlyContinue
$cat = "$env:TEMP\stwrt64.cat"
Remove-Item $cat -ErrorAction SilentlyContinue
New-FileCatalog -Path $dst -CatalogFilePath $cat -CatalogVersion 2 | Out-Null
Set-AuthenticodeSignature -FilePath $cat -Certificate $cert | Out-Null
Copy-Item $cat "$dst\stwrt64.cat" -Force

# 4) Instalar
pnputil /add-driver $inf /install
pnputil /scan-devices
Write-Host "`nListo. Pegame la salida completa." -ForegroundColor Green
