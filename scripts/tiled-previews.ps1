# Tiled sprite-előnézet: a pálya-objektumok (Player, Enemy, Pickup, Shroom, Meteor, Meteorfall, Boss, End) a játék saját sprite-jaival látszanak a Tiled-ben.
#   powershell -ExecutionPolicy Bypass -File scripts/tiled-previews.ps1 [-NoExport]
# Lépések: (1) a .tmx-ek mentése a levels\.backup-previews mappába (csak egyszer), (2) teszt-build + fejnélküli Edge a ?exporttiled=1 címmel ->
# levels/objects.tsj + levels/sprites/*.png, (3) a Tiled projekt osztályai csempére is használhatók, (4) a pont-objektumok cseréje csempe-objektumokra a .tmx-ekben
# (scripts/tiled-previews.js, idempotens), (5) a .tmx-ek JSON-exportja (scripts/export-levels.ps1; -NoExport kihagyja), (6) normál build.
# Új sprite / objektumtípus esetén: source/TiledSprites.hx + source/TiledExport.hx, majd újra ez a script.
param([switch]$NoExport, [int]$Port = 3051)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $env:HAXEPATH -and (Test-Path "C:\HaxeToolkit\haxe")) { $env:HAXEPATH = "C:\HaxeToolkit\haxe" }
$levels = Join-Path $root "levels"

$bak = Join-Path $levels ".backup-previews"
if (-not (Test-Path $bak)) {
    New-Item -ItemType Directory $bak | Out-Null
    Copy-Item (Join-Path $levels "*.tmx") $bak
    Write-Host "A .tmx-ek mentve: $bak" -ForegroundColor DarkGray
}

Write-Host "Teszt-build..." -ForegroundColor Cyan
$o = & haxelib run lime build html5 -Dtest 2>&1
$errs = $o | Select-String -Pattern "\.hx:[0-9]+"
if ($errs) { $errs | ForEach-Object { Write-Host $_ -ForegroundColor Red }; exit 1 }

$node = Join-Path (haxelib libpath lime).Trim() "templates\bin\node\node-windows.exe"
if (-not (Test-Path $node)) { $node = (Get-Command node).Source }
$srv = Start-Process $node -ArgumentList "`"$PSScriptRoot\devserver.js`"", "`"$root\export\html5\bin`"", $Port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
try {
    . "$root\tests\cdp-lib.ps1"
    Start-Cdp "http://127.0.0.1:$Port/?exporttiled=1" (Join-Path $root "tests\out")
    $n = 0
    for ($i = 0; $i -lt 40 -and $n -eq 0; $i++) { Start-Sleep -Seconds 1; $n = [int](Js "window.__tiledFiles ? Object.keys(window.__tiledFiles).length : 0") }
    if ($n -eq 0) { throw "Az export nem készült el (window.__tiledFiles üres)." }
    foreach ($name in ((Js "Object.keys(window.__tiledFiles).join('|')") -split '\|')) {
        $path = Join-Path $levels $name
        New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
        $v = Js "window.__tiledFiles['$name']"
        if ($name -like "*.png") { [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($v)) }
        else { [IO.File]::WriteAllText($path, $v, (New-Object System.Text.UTF8Encoding($false))) }
    }
    Write-Host "$n fájl mentve: $levels" -ForegroundColor Green
}
finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}

# a projekt osztályai csempe-objektumként is használhatók (a csempe osztálya az objektumé lesz)
$proj = Join-Path $levels "blockbuster.tiled-project"
$p = Get-Content $proj -Raw -Encoding UTF8
$p2 = $p -replace '"useAs":\s*\["object"\]', '"useAs": ["object", "tile"]'
if ($p2 -ne $p) { [IO.File]::WriteAllText($proj, $p2, (New-Object System.Text.UTF8Encoding($false))) }

& $node (Join-Path $PSScriptRoot "tiled-previews.js") $levels
if ($LASTEXITCODE -ne 0) { throw "A .tmx átalakítás nem sikerült." }

if (-not $NoExport) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "export-levels.ps1")
}
& haxelib run lime build html5 2>&1 | Out-Null
Write-Host "Kész. Nyisd meg a pályát a Tiled-ben (levels\blockbuster.tiled-project)." -ForegroundColor Green
