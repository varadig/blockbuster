# Statikus ellenőrzés az exportált Tiled-pályákon (assets/levels/*.json), böngésző nélkül.
#   powershell -ExecutionPolicy Bypass -File tests/validate-levels.ps1
# Ellenőrzi a formátumot (docs/LEVELS.md), az enumértékeket, a talaj rendezettségét és átfedéseit,
# a Player és a Boss/End meglétét, a főellenség-aréna folytonosságát és hogy az export nem régebbi a .tmx-nél.
# A küldetés-megvalósíthatóságot a játék betöltője becsüli (teszt/debug buildben trace-ként írja ki).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$levelDir = Join-Path $root "assets\levels"
$tmxDir = Join-Path $root "levels"

$enemyKinds = "SLIME", "BAT", "TURRET", "DRONE"
$powerKinds = "SPREAD", "RAPID", "HOMING", "ROCKET", "LASER", "GRENADE", "BONUS", "ENERGY"
$rewardKinds = @("NONE", "RANDOM") + $powerKinds
$classes = "ground", "platform", "player", "enemy", "pickup", "shroom", "meteor", "shower", "meteorfall", "boss", "end"

$errors = 0
$warnings = 0
function Err($file, $msg) { Write-Host "ERROR  $file : $msg" -ForegroundColor Red; $script:errors++ }
function Warn($file, $msg) { Write-Host "WARN   $file : $msg" -ForegroundColor Yellow; $script:warnings++ }

function Get-Layers($layers) {
    foreach ($l in $layers) {
        if ($l.type -eq "group") { Get-Layers $l.layers } else { $l }
    }
}

function Get-Prop($o, $name, $default = $null) {
    if ($o.properties) { foreach ($p in $o.properties) { if ($p.name -eq $name) { return $p.value } } }
    return $default
}

$files = Get-ChildItem $levelDir -Filter *.json
if (-not $files) { Err $levelDir "nincs pályafájl"; exit 1 }

foreach ($f in $files) {
    $name = $f.Name
    try { $m = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { Err $name "érvénytelen JSON: $($_.Exception.Message)"; continue }

    if ($m.orientation -ne "orthogonal") { Err $name "csak orthogonal térkép támogatott" }
    if ($m.infinite -eq $true) { Err $name "a térkép végtelen (infinite)" }
    $themeProp = Get-Prop $m 'theme' ''
    if ($themeProp -and @('NIGHT', 'ASH', 'ICE', 'DESERT', 'TOXIC') -notcontains "$themeProp".ToUpper()) { Warn $name "ismeretlen theme: '$themeProp' (az alap téma lesz)" }

    $ground = @(); $platforms = @(); $players = 0; $boss = $null; $end = $null; $seenIds = @{}
    foreach ($layer in (Get-Layers $m.layers)) {
        if ($layer.type -ne "objectgroup" -or $layer.visible -eq $false) { continue }
        foreach ($o in $layer.objects) {
            if ($o.visible -eq $false) { continue }
            if ($seenIds.ContainsKey($o.id)) { Err $name "ismétlődő objektumazonosító: $($o.id)" }
            $seenIds[$o.id] = $true
            $cls = $o.class; if (-not $cls) { $cls = $o.type }
            if (-not $cls) { $cls = switch ($layer.name.ToLower()) { "ground" { "Ground" } "platforms" { "Platform" } default { "" } } }
            $c = "$cls".ToLower()
            $where = "#$($o.id) ($cls)"
            if ($classes -notcontains $c) { Warn $name "$where ismeretlen osztály: kihagyja a játék"; continue }
            switch ($c) {
                "ground" { $ground += [pscustomobject]@{ x = [math]::Round($o.x); y = [math]::Round($o.y); w = [math]::Round($o.width) } }
                "platform" { $platforms += [pscustomobject]@{ x = [math]::Round($o.x); y = [math]::Round($o.y); w = [math]::Round($o.width); h = [math]::Round($o.height) } }
                "player" { $players++; $px = [math]::Round($o.x) }
                "boss" { $boss = [math]::Round($o.x) }
                "end" { $end = [math]::Round($o.x) }
                "enemy" {
                    $k = "$(Get-Prop $o 'kind' '')".ToUpper()
                    if ($enemyKinds -notcontains $k) { Warn $name "$where ismeretlen vagy hiányzó kind: '$k'" }
                }
                "pickup" {
                    $k = "$(Get-Prop $o 'kind' '')".ToUpper()
                    if ($powerKinds -notcontains $k) { Warn $name "$where ismeretlen vagy hiányzó kind: '$k'" }
                }
                { $_ -in "meteor", "shower", "meteorfall" } {
                    $r = "$(Get-Prop $o 'reward' $(if ($c -in "shower", "meteorfall") { 'RANDOM' } else { 'NONE' }))".ToUpper()
                    if ($r -ne "" -and $rewardKinds -notcontains $r) { Warn $name "$where ismeretlen reward: '$r'" }
                    if ($c -eq "shower" -and $o.width -le 0) { Warn $name "$where a zápor téglalap legyen" }
                }
            }
        }
    }

    $g = $ground | Sort-Object x, y
    if (-not $g) { Err $name "nincs Ground téglalap"; continue }
    for ($i = 1; $i -lt $g.Count; $i++) {
        $prevEnd = $g[$i - 1].x + $g[$i - 1].w
        if ($g[$i].x -lt $prevEnd - 1) { Err $name "átfedő talaj: x=$($g[$i].x) (az előző vége: $prevEnd)" }
    }
    # Járhatóság: a hős 18 px magas, ~60 px magasra ugrik és ~146 px messzire; a lassabb/gyengébb karakterhez ennél szűkebb a határ
    for ($i = 1; $i -lt $g.Count; $i++) {
        $gap = $g[$i].x - ($g[$i - 1].x + $g[$i - 1].w); $rise = $g[$i - 1].y - $g[$i].y
        if ($gap -gt 100) { Err $name "túl széles rés: x=$($g[$i].x) ($gap px, legfeljebb ~100 lehet)" }
        if ($rise -gt 48) { Err $name "túl magas lépcső: x=$($g[$i].x) ($rise px, legfeljebb ~48 lehet)" }
        if ($gap -gt 56 -and $rise -gt 24) { Warn $name "rés ($gap px) és emelkedő ($rise px) együtt nehezen ugorható: x=$($g[$i].x)" }
    }
    foreach ($p in $platforms) {
        foreach ($r in $g) {
            if ($r.x -ge $p.x + $p.w -or $r.x + $r.w -le $p.x) { continue }
            $clear = $r.y - ($p.y + $p.h)
            if ($clear -lt 26) { Err $name "a platform (x=$($p.x), y=$($p.y)) alatt csak $clear px hely van a talaj (x=$($r.x), y=$($r.y)) fölött: a 18 px magas hős beszorul (legalább 26 kell)" }
        }
    }
    if ($players -ne 1) { Warn $name "pontosan egy Player pont kell ($players van); hiányában az alapértelmezett kezdőpont lesz" }
    if ($players -ge 1 -and -not ($g | Where-Object { $px -ge $_.x -and $px -le $_.x + $_.w })) { Err $name "nincs talaj a játékos kezdőpontja alatt (x=$px)" }
    if ($null -eq $boss -and $null -eq $end) { Err $name "nincs Boss vagy End trigger: a pálya sosem érne véget" }
    if ($null -ne $boss) {
        $covered = $boss - 160; $to = $boss + 480
        foreach ($r in $g) { if ($r.x + $r.w -lt $covered - 1) { continue }; if ($r.x -gt $covered + 1) { break }; $covered = [math]::Max($covered, $r.x + $r.w) }
        if ($covered -lt $to - 1) { Warn $name "a főellenség-aréna talaja nem összefüggő ($($boss - 160)..$to), csak x=$covered-ig van talaj" }
    }

    # Az export legyen frissebb a .tmx forrásnál
    $tmx = Join-Path $tmxDir ($f.BaseName + ".tmx")
    if ((Test-Path $tmx) -and (Get-Item $tmx).LastWriteTime -gt $f.LastWriteTime.AddSeconds(2)) {
        Warn $name "a .tmx forrás újabb, mint az export: exportáld újra (Tiled: Ctrl+E, vagy scripts/export-levels.ps1)"
    }
    Write-Host ("OK     {0}: {1} talajtéglalap, Boss={2}, End={3}" -f $name, $ground.Count, $boss, $end) -ForegroundColor Green
}

if ($errors -gt 0) { Write-Host "`n$errors hiba, $warnings figyelmeztetés." -ForegroundColor Red; exit 1 }
Write-Host "`nNincs hiba ($warnings figyelmeztetés)." -ForegroundColor Green
