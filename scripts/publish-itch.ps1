# Automatikus (újra)publikálás itch.io-ra a hivatalos "butler" eszközzel.
#
# Egyszeri beállítás:
#   1. itch.config.json: "user" = az itch.io felhasználóneved, "game" = a projekt URL-neve
#      (https://<user>.itch.io/<game>).
#   2. Bejelentkezés: futtasd egyszer a "Publish to itch.io" feladatot; ha még nem vagy bejelentkezve,
#      a butler megnyitja a böngészőt az engedélyezéshez. (Alternatíva: BUTLER_API_KEY környezeti változó,
#      kulcs: https://itch.io/user/settings/api-keys)
#   3. Az első feltöltés után az itch.io-n a projekt Edit oldalán ennél a fájlnál ("html5" csatorna)
#      egyszer be kell pipálni: "This file will be played in the browser", majd Save.
#      A későbbi feltöltések ugyanezt a fájlt frissítik, a beállítás megmarad.
#
# Futtatás: VS Code > Run Task > "Publish to itch.io", vagy:
#   powershell -ExecutionPolicy Bypass -File scripts/publish-itch.ps1

param([switch]$NoBuild) # -NoBuild: a build már kész (pl. scripts/release.ps1), csak feltölt

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# --- Beállítások ---------------------------------------------------------------
$config = Get-Content (Join-Path $root "itch.config.json") -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($config.user)) {
    Write-Host 'Állítsd be az itch.io felhasználónevedet az itch.config.json fájlban ("user").' -ForegroundColor Red
    exit 1
}
$target = "$($config.user)/$($config.game):$($config.channel)"

# --- butler beszerzése (egyszer, a tools/butler mappába) ---------------------------
$butlerDir = Join-Path $root "tools\butler"
$butler = Join-Path $butlerDir "butler.exe"
if (-not (Test-Path $butler)) {
    $onPath = Get-Command butler -ErrorAction SilentlyContinue
    if ($onPath) {
        $butler = $onPath.Source
    }
    else {
        Write-Host "butler letöltése az itch.io hivatalos tárolójából..."
        New-Item -ItemType Directory -Force $butlerDir | Out-Null
        $zip = Join-Path $butlerDir "butler.zip"
        Invoke-WebRequest "https://broth.itch.zone/butler/windows-amd64/LATEST/archive/default" -OutFile $zip -UseBasicParsing
        Expand-Archive $zip -DestinationPath $butlerDir -Force
        Remove-Item $zip
    }
}
& $butler -V

# --- Build ------------------------------------------------------------------------
$env:HAXEPATH = "C:\HaxeToolkit\haxe"
$env:NEKO_INSTPATH = "C:\HaxeToolkit\neko"
$env:Path = "C:\HaxeToolkit\haxe;C:\HaxeToolkit\neko;$env:Path"
if (-not $NoBuild) {
    & haxelib run lime build html5
    if ($LASTEXITCODE -ne 0) { throw "A build nem sikerült." }
}

# Verzió: Project.xml meta version + git rövid hash (ha van)
[xml]$project = Get-Content (Join-Path $root "Project.xml")
$version = $project.project.meta.version
$hash = (& git rev-parse --short HEAD 2>$null)
if ($LASTEXITCODE -eq 0 -and $hash) {
    $dirty = (& git status --porcelain 2>$null)
    $version = "$version+$hash" + $(if ($dirty) { "-dirty" } else { "" })
}

# --- Feltöltés --------------------------------------------------------------------
# A butler csak a változásokat tölti fel; ha még nincs bejelentkezve, böngészős engedélyezést kér.
Write-Host "Feltöltés: $target (verzió: $version)"
& $butler push "export\html5\bin" $target --userversion $version
if ($LASTEXITCODE -ne 0) { throw "A feltöltés nem sikerült." }

& $butler status $target
Write-Host "Kész: https://$($config.user).itch.io/$($config.game)" -ForegroundColor Green
