# Teljes kiadás egy lépésben: pályák ellenőrzése -> release (nem teszt) HTML5 build -> ellenőrzés (nincs benne cheat) -> itch.io zip -> feltöltés.
#
#   powershell -ExecutionPolicy Bypass -File scripts/release.ps1                (mindent: build, zip, publikálás)
#   powershell -ExecutionPolicy Bypass -File scripts/release.ps1 -SkipPublish   (csak build + zip + ellenőrzés, nincs feltöltés)
#   powershell -ExecutionPolicy Bypass -File scripts/release.ps1 -SkipValidate  (a pályák ellenőrzése nélkül)
#
# VS Code: Run Task > "Release (build + package + publish)" vagy "Release (build + package, no publish)".
# A feltöltés beállításai: itch.config.json; bejelentkezés és az első feltöltés teendői: scripts/publish-itch.ps1 és docs/ITCH.md.

param(
    [switch]$SkipPublish,
    [switch]$SkipValidate
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Step($n, $text) { Write-Host "`n[$n] $text" -ForegroundColor Cyan }
function Fail($text) { Write-Host "HIBA: $text" -ForegroundColor Red; exit 1 }

$total = if ($SkipPublish) { 3 } else { 4 }

# --- 1. Pályák ellenőrzése -----------------------------------------------------------
if (-not $SkipValidate) {
    Step "1/$total" "Pályák ellenőrzése (tests/validate-levels.ps1)"
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tests\validate-levels.ps1")
    if ($LASTEXITCODE -ne 0) { Fail "a pályák ellenőrzése hibát talált, a kiadás megáll." }
}
else {
    Step "1/$total" "Pályák ellenőrzése kihagyva (-SkipValidate)"
}

# --- 2. Release build + zip ----------------------------------------------------------
Step "2/$total" "Release HTML5 build és csomagolás (scripts/package-itch.ps1)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts\package-itch.ps1")
if ($LASTEXITCODE -ne 0) { Fail "a build vagy a csomagolás nem sikerült." }

# --- 3. A csomag ellenőrzése ---------------------------------------------------------
Step "3/$total" "A kiadás ellenőrzése"
$bin = Join-Path $root "export\html5\bin"
$js = Get-ChildItem $bin -Filter *.js | Select-Object -First 5
if (-not $js) { Fail "nincs lefordított .js az export\html5\bin mappában." }
if (@($js).Count -ne 1) { Fail "több .js van a bin mappában ($($js.Name -join ', ')): maradék régi build kerülhet a zipbe." }
$text = [IO.File]::ReadAllText($js[0].FullName)
foreach ($forbidden in @("CheatSubState", "cheatPowerName", "cheatSkipToBoss", "window.__game")) {
    if ($text.Contains($forbidden)) { Fail "a release build tartalmazza a fejlesztői kódot: '$forbidden'. Release-ben nem lehet cheat." }
}
$zip = Join-Path $root "dist\moonshard-html5.zip"
if (-not (Test-Path $zip)) { Fail "a zip nem készült el: $zip" }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$entries = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    $names = $entries.Entries | ForEach-Object { $_.FullName }
}
finally { $entries.Dispose() }
if ($names -notcontains "index.html") { Fail "az index.html nincs a zip gyökerében." }
Write-Host ("OK: {0} ({1} MB), nincs benne cheat-kód, index.html a gyökérben." -f $zip, [math]::Round((Get-Item $zip).Length / 1MB, 2)) -ForegroundColor Green

# --- 4. Feltöltés --------------------------------------------------------------------
if ($SkipPublish) {
    Write-Host "`nA feltöltés kihagyva (-SkipPublish). A zip kézi feltöltésre kész: $zip" -ForegroundColor Yellow
    exit 0
}
Step "4/$total" "Feltöltés itch.io-ra (scripts/publish-itch.ps1 -NoBuild)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts\publish-itch.ps1") -NoBuild
if ($LASTEXITCODE -ne 0) { Fail "a feltöltés nem sikerült." }

Write-Host "`nA kiadás kész." -ForegroundColor Green
