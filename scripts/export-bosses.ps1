# A főellenség-sprite-ok exportja PNG-be (további felhasználásra): art/bosses/<név>_sheet_1x.png, _sheet_x8.png, _frameN_x8.png
#   powershell -ExecutionPolicy Bypass -File scripts/export-bosses.ps1 [-Out art\bosses]
# Működés: teszt-build (a cheats-es BossExport-tal) -> helyi szerver -> fejnélküli Edge a ?exportboss=1 címmel -> a window.__bossPng fájlba mentése.
# Végül normál (nem teszt) buildet hagy az export\html5\bin mappában.
param([string]$Out = "art\bosses", [int]$Port = 3047)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $env:HAXEPATH -and (Test-Path "C:\HaxeToolkit\haxe")) { $env:HAXEPATH = "C:\HaxeToolkit\haxe" }
$dest = Join-Path $root $Out
New-Item -ItemType Directory -Force $dest | Out-Null

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
    Start-Cdp "http://127.0.0.1:$Port/?exportboss=1" (Join-Path $root "tests\out")
    $n = 0
    for ($i = 0; $i -lt 40 -and $n -eq 0; $i++) { Start-Sleep -Seconds 1; $n = [int](Js "window.__bossPng ? Object.keys(window.__bossPng).length : 0") }
    if ($n -eq 0) { throw "Az export nem készült el (window.__bossPng üres)." }
    $names = (Js "Object.keys(window.__bossPng).join('|')") -split '\|'
    foreach ($name in $names) {
        $b64 = Js "window.__bossPng['$name']"
        [IO.File]::WriteAllBytes((Join-Path $dest $name), [Convert]::FromBase64String($b64))
    }
    Write-Host "$($names.Count) fájl mentve: $dest" -ForegroundColor Green
}
finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
    & haxelib run lime build html5 2>&1 | Out-Null
}
