# A levels/*.tmx térképek exportálása JSON-ba (assets/levels/) a Tiled parancssori exportjával.
# Futtatás: VS Code > Run Task > "Export Tiled levels", vagy:
#   powershell -ExecutionPolicy Bypass -File scripts/export-levels.ps1 [-Tiled "C:\Program Files\Tiled\tiled.exe"]
# Az export után fordítani kell, mert a JSON be van ágyazva a játékba (lime build html5).

param([string]$Tiled = "")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $Tiled) {
    foreach ($c in "$env:ProgramFiles\Tiled\tiled.exe", "${env:ProgramFiles(x86)}\Tiled\tiled.exe", "$env:LOCALAPPDATA\Programs\Tiled\tiled.exe") {
        if (Test-Path $c) { $Tiled = $c; break }
    }
    if (-not $Tiled) {
        $onPath = Get-Command tiled -ErrorAction SilentlyContinue
        if ($onPath) { $Tiled = $onPath.Source }
    }
}
if (-not $Tiled -or -not (Test-Path $Tiled)) {
    Write-Host "A Tiled nem található. Telepítsd (https://www.mapeditor.org), vagy add meg: -Tiled <út>\tiled.exe" -ForegroundColor Red
    Write-Host "Kézi alternatíva: nyisd meg a .tmx-et Tiled-ben, és File > Export (Ctrl+E): a cél már be van állítva az assets/levels/ mappába."
    exit 1
}

New-Item -ItemType Directory -Force (Join-Path $root "assets\levels") | Out-Null
foreach ($tmx in Get-ChildItem (Join-Path $root "levels") -Filter *.tmx) {
    $out = Join-Path $root ("assets\levels\" + $tmx.BaseName + ".json")
    Write-Host "Export: $($tmx.Name) -> assets/levels/$($tmx.BaseName).json"
    # A Tiled grafikus program: csak a Start-Process -Wait várja meg, és adja vissza a kilépési kódot
    $proc = Start-Process $Tiled -ArgumentList "--export-map", "json", "`"$($tmx.FullName)`"", "`"$out`"" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) { throw "A Tiled exportja nem sikerült: $($tmx.Name)" }
}

Write-Host "`nEllenőrzés..."
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tests\validate-levels.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Kész. Fordíts újra (Build HTML5), hogy a játék a friss pályákat használja." -ForegroundColor Green
