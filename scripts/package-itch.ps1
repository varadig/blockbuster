# Normál (nem teszt) HTML5 build, majd itch.io-ra feltölthető zip: dist/blockbuster-html5.zip
# Az index.html a zip gyökerébe kerül, ahogy az itch.io elvárja.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$env:HAXEPATH = "C:\HaxeToolkit\haxe"
$env:NEKO_INSTPATH = "C:\HaxeToolkit\neko"
$env:Path = "C:\HaxeToolkit\haxe;C:\HaxeToolkit\neko;$env:Path"

& haxelib run lime build html5
if ($LASTEXITCODE -ne 0) { throw "A build nem sikerült." }

New-Item -ItemType Directory -Force dist | Out-Null
$zip = Join-Path $root "dist\blockbuster-html5.zip"
if (Test-Path $zip) { Remove-Item $zip }
# A Windows beépített tar-ja szabványos (perjeles útvonalú) zip-et készít
& "$env:SystemRoot\System32\tar.exe" -a -c -f $zip -C "export\html5\bin" *
if ($LASTEXITCODE -ne 0) { throw "A csomagolás nem sikerült." }

Write-Host "Kész: $zip ($([math]::Round((Get-Item $zip).Length / 1MB, 2)) MB)" -ForegroundColor Green
