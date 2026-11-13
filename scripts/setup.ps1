# Fejlesztői környezet ellenőrzése és a függőségek telepítése (rögzített verziók).
# Futtatás: VS Code > Run Task > "Install dependencies (haxelib)", vagy:
#   powershell -ExecutionPolicy Bypass -File scripts/setup.ps1

$ErrorActionPreference = "Stop"

$haxeDir = "C:\HaxeToolkit\haxe"
$nekoDir = "C:\HaxeToolkit\neko"
if (-not (Test-Path "$haxeDir\haxe.exe")) {
    Write-Host "Haxe nem található itt: $haxeDir" -ForegroundColor Red
    Write-Host "Telepítsd a Haxe 4.3.6-ot (https://haxe.org/download/ vagy: winget install HaxeFoundation.Haxe --version 4.3.6)"
    exit 1
}
$env:HAXEPATH = $haxeDir
$env:NEKO_INSTPATH = $nekoDir
$env:Path = "$haxeDir;$nekoDir;$env:Path"

$version = (& haxe -version).Trim()
Write-Host "Haxe: $version"
if ($version -ne "4.3.6") {
    Write-Host "Figyelem: a projekt Haxe 4.3.6-tal készült (most: $version)." -ForegroundColor Yellow
}

# haxelib tároló beállítása, ha még nincs
& haxelib config *> $null
if ($LASTEXITCODE -ne 0) {
    New-Item -ItemType Directory -Force "$haxeDir\lib" | Out-Null
    & haxelib setup "$haxeDir\lib"
}

# A projekt ezekre a verziókra van írva (lásd CLAUDE.md / Project.xml)
$libs = [ordered]@{ "lime" = "8.3.2"; "openfl" = "9.5.2"; "flixel" = "6.2.1" }
foreach ($name in $libs.Keys) {
    $ver = $libs[$name]
    Write-Host "haxelib install $name $ver"
    & haxelib install $name $ver --always --quiet
    if ($LASTEXITCODE -ne 0) { throw "Nem sikerült telepíteni: $name $ver" }
    & haxelib set $name $ver --always | Out-Null
}

Write-Host ""
& haxelib list
Write-Host ""
Write-Host "Kész. Futtatás: VS Code > Run Task > 'Run HTML5 (browser)', vagy F5." -ForegroundColor Green
