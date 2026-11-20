# A 3-10. pálya Tiled-térképeinek (levels/*.tmx) és exportjainak (assets/levels/*.json) legenerálása, KIINDULÓPONTNAK.
# A generátor csak a nyers elrendezést adja (talaj, platformok, ellenségek, meteorzáporok, bónuszok); a kész .tmx fájlokat aztán
# Tiled-ben kézzel lehet szerkeszteni (docs/LEVELS.md). FIGYELEM: újrafuttatva felülírja a kézzel szerkesztett 03-10. pályákat!
# A 01. és 02. pályát nem érinti. Futtatás:
#   powershell -ExecutionPolicy Bypass -File scripts/generate-levels.ps1
# A kimenet végén kiírja a Quests.hx LEVELS-listájához való sorokat is.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Pálya-paraméterek: sorszám (1-től), fájlnév, név, téma, görgetési szorzó, a főellenség-aréna x-e, szakadék-esély, magag magja
$defs = @(
    @{ n = 3;  file = "03_blood_moon";    name = "BLOOD MOON";    theme = "NIGHT";  speed = 1.25; bx = 9100;  gap = 0.14; seed = 303 },
    @{ n = 4;  file = "04_frozen_ridge";  name = "FROZEN RIDGE";  theme = "ICE";    speed = 1.30; bx = 9500;  gap = 0.16; seed = 404 },
    @{ n = 5;  file = "05_toxic_marsh";   name = "TOXIC MARSH";   theme = "TOXIC";  speed = 1.35; bx = 9900;  gap = 0.18; seed = 505 },
    @{ n = 6;  file = "06_dune_sea";      name = "DUNE SEA";      theme = "DESERT"; speed = 1.40; bx = 10300; gap = 0.20; seed = 606 },
    @{ n = 7;  file = "07_glacier_night"; name = "GLACIER NIGHT"; theme = "ICE";    speed = 1.45; bx = 10700; gap = 0.20; seed = 707 },
    @{ n = 8;  file = "08_spore_hollow";  name = "SPORE HOLLOW";  theme = "TOXIC";  speed = 1.50; bx = 11100; gap = 0.22; seed = 808 },
    @{ n = 9;  file = "09_lunar_wastes";  name = "LUNAR WASTES";  theme = "DESERT"; speed = 1.55; bx = 11500; gap = 0.22; seed = 909 },
    @{ n = 10; file = "10_the_last_night"; name = "THE LAST NIGHT"; theme = "NIGHT"; speed = 1.60; bx = 11900; gap = 0.24; seed = 1010 }
)

$curses = @("SHROOM", "PIXEL", "TORCH", "GHOST", "TINYVIEW", "TINYHERO", "MAGNET", "ASCII")
$pickupKinds = @("ENERGY", "SPREAD", "RAPID", "HOMING", "ROCKET", "LASER", "GRENADE", "BONUS", "ENERGY", "HOMING")

function Prop($n, $t, $v, $pt = $null) { return @{ n = $n; t = $t; v = $v; pt = $pt } }

function Generate($def) {
    $rnd = New-Object System.Random $def.seed
    $L = $def.n
    $bx = $def.bx
    $len = $bx + 700
    $script:id = 0
    function NextId { $script:id++; return $script:id }

    $ground = New-Object System.Collections.ArrayList
    $segs = New-Object System.Collections.ArrayList   # {x,w,y}
    function AddSeg($x, $w, $y) { [void]$segs.Add(@{ x = $x; w = $w; y = $y }) }

    # --- Talaj -------------------------------------------------------------------------------------------------
    $x = 0; $y = 232
    AddSeg 0 480 232; $x = 480
    while ($x + 96 -lt $bx - 200) {
        $hadGap = $false
        if ($rnd.NextDouble() -lt $def.gap) {
            $g = 40 + 8 * $rnd.Next(0, 6)             # 40..80 px-es rés (a hős átugorja)
            $x += $g; $hadGap = $true
        }
        # Néha kis lépcső (3 lépcsőfok egyenként 16 px-et emelkedik), különben egy hosszabb szakasz kisebb szintkülönbséggel
        if (-not $hadGap -and $y -ge 232 -and $rnd.NextDouble() -lt 0.12 -and ($x + 300) -lt ($bx - 200)) {
            for ($i = 1; $i -le 3; $i++) { AddSeg $x 32 ($y - 16 * $i); $x += 32 }
            $y = $y - 48
            AddSeg $x 64 $y; $x += 64
            continue
        }
        $steps = @(-24, -12, 0, 0, 12, 24)
        $ny = $y + $steps[$rnd.Next(0, $steps.Count)]
        if ($ny -lt 184) { $ny = 184 }
        if ($ny -gt 232) { $ny = 232 }
        $w = 8 * $rnd.Next(10, 36)                     # 80..280 px
        if ($x + $w -gt $bx - 200) { $w = $bx - 200 - $x }
        if ($w -lt 48) { break }
        AddSeg $x $w $ny
        $x += $w; $y = $ny
    }
    # Főellenség-aréna: sík, összefüggő talaj a térkép végéig
    AddSeg $x ($len - $x) 220

    $gObjs = @()
    foreach ($s in $segs) {
        $gObjs += @{ id = (NextId); name = ""; cls = "Ground"; x = $s.x; y = $s.y; w = $s.w; h = (270 - $s.y); point = $false; props = @() }
    }

    # --- Platformok (egyirányúak, alulról átugorhatók) -----------------------------------------------------------
    $pObjs = @()
    foreach ($s in $segs) {
        if ($s.w -ge 112 -and $s.x -gt 600 -and $s.x -lt ($bx - 400) -and $rnd.NextDouble() -lt 0.45) {
            $pw = 8 * $rnd.Next(4, 9)
            $room = [int](($s.w - $pw - 48) / 8)
            if ($room -lt 0) { continue }
            $px = $s.x + 24 + 8 * $rnd.Next(0, $room + 1)
            $py = $s.y - (40 + 4 * $rnd.Next(0, 4))        # a platform alatt legalább 32 px hely marad
            $pObjs += @{ id = (NextId); name = ""; cls = "Platform"; x = $px; y = $py; w = $pw; h = 8; point = $false; props = @() }
        }
    }

    # --- Spawnok ---------------------------------------------------------------------------------------------------
    $sObjs = @()
    $sObjs += @{ id = (NextId); name = "Start"; cls = "Player"; x = 140; y = 232; w = 0; h = 0; point = $true; props = @() }

    # Meteorzáporok (téglalapok): egyre sűrűbbek
    $showerCount = 3 + [int]($L / 4)
    $expectedMeteors = 0.0; $expectedGold = 0.0
    for ($k = 0; $k -lt $showerCount; $k++) {
        $sx = 700 + [int]($k * (($bx - 2600) / [Math]::Max(1, $showerCount - 1)))
        $sw = 1700 + 100 * $rnd.Next(0, 5)
        $rate = [Math]::Round(0.8 + 0.1 * $L + 0.3 * $rnd.NextDouble(), 1)
        $gold = 5
        $sObjs += @{ id = (NextId); name = "Shower"; cls = "Shower"; x = $sx; y = 0; w = $sw; h = 270; point = $false; props = @(
                (Prop "rate" "float" $rate), (Prop "goldEvery" "int" $gold), (Prop "reward" "string" "RANDOM" "RewardKind")) }
        $secs = $sw / 110.0
        $expectedMeteors += $rate * $secs
        $expectedGold += $rate * $secs / $gold
    }
    # Meteoreső-pontok
    $fallCount = 2 + [int]($L / 3)
    for ($k = 0; $k -lt $fallCount; $k++) {
        $fx = 2600 + [int]($k * (($bx - 3800) / [Math]::Max(1, $fallCount - 1)))
        $cnt = 12 + $L
        $sObjs += @{ id = (NextId); name = "METEORFALL"; cls = "Meteorfall"; x = $fx; y = 232; w = 0; h = 0; point = $true; props = @(
                (Prop "count" "int" $cnt), (Prop "goldEvery" "int" 6), (Prop "span" "float" 520)) }
        $expectedMeteors += $cnt
    }

    # Ellenségek: a szakaszok közepén; a fajták a pálya sorszámával bővülnek
    $kinds = @("SLIME", "BAT")
    if ($L -ge 3) { $kinds += "TURRET" }
    if ($L -ge 4) { $kinds += "DRONE" }
    $enemyNormal = 0; $slimeBat = 0
    foreach ($s in $segs) {
        if ($s.x -lt 900 -or $s.x -gt ($bx - 300)) { continue }
        $chance = 0.40 + 0.03 * $L
        if ($rnd.NextDouble() -gt $chance) { continue }
        $kind = $kinds[$rnd.Next(0, $kinds.Count)]
        if ($kind -eq "TURRET" -and $s.w -lt 96) { $kind = "SLIME" }
        $cx = $s.x + [int]($s.w / 2)
        $ey = $s.y
        $count = 1
        if ($kind -eq "SLIME") { $ey = $s.y; $count = 1 + $rnd.Next(0, 2) }
        if ($kind -eq "BAT") { $ey = $s.y - (80 + 10 * $rnd.Next(0, 5)) }
        if ($kind -eq "DRONE") { $ey = 40 }
        $props = @((Prop "kind" "string" $kind "EnemyKind"))
        if ($count -gt 1) { $props += (Prop "count" "int" $count); $props += (Prop "spacing" "float" 28) }
        $sObjs += @{ id = (NextId); name = $kind; cls = "Enemy"; x = $cx; y = $ey; w = 0; h = 0; point = $true; props = $props }
        $enemyNormal += $count
        if ($kind -eq "SLIME" -or $kind -eq "BAT") { $slimeBat += $count }
        # Nehezebb szinten extra ellenség ugyanott, kicsit odébb
        if ($rnd.NextDouble() -lt 0.3) {
            $sObjs += @{ id = (NextId); name = "BAT"; cls = "Enemy"; x = ($cx + 60); y = ($s.y - 110); w = 0; h = 0; point = $true; props = @(
                    (Prop "kind" "string" "BAT" "EnemyKind"), (Prop "minDifficulty" "int" 2)) }
        }
    }

    # Bónuszok: kb. 1400 px-enként
    $pickups = 0; $pk = 0
    $px0 = 1500
    while ($px0 -lt ($bx - 500)) {
        $seg = $segs | Where-Object { $_.x -le $px0 -and ($_.x + $_.w) -gt $px0 } | Select-Object -First 1
        if ($seg) {
            $kind = $pickupKinds[$pk % $pickupKinds.Count]; $pk++
            $sObjs += @{ id = (NextId); name = $kind; cls = "Pickup"; x = $px0; y = ($seg.y - 8); w = 0; h = 0; point = $true; props = @(
                    (Prop "kind" "string" $kind "PowerKind"), (Prop "floating" "bool" "true")) }
            $pickups++
        }
        $px0 += 1300 + 100 * $rnd.Next(0, 5)
    }

    # Módosítók (a talajon fekvő tárgyak): kb. 2400 px-enként, mindig más
    $mx = 2200; $mk = $rnd.Next(0, $curses.Count)
    while ($mx -lt ($bx - 700)) {
        $seg = $segs | Where-Object { $_.x -le $mx -and ($_.x + $_.w) -gt $mx } | Select-Object -First 1
        if ($seg) {
            $kind = $curses[$mk % $curses.Count]; $mk++
            $sObjs += @{ id = (NextId); name = "Shroom"; cls = "Shroom"; x = $mx; y = $seg.y; w = 0; h = 0; point = $true; props = @((Prop "kind" "string" $kind)) }
        }
        $mx += 2300 + 100 * $rnd.Next(0, 4)
    }

    $tObjs = @(@{ id = (NextId); name = "Boss"; cls = "Boss"; x = $bx; y = 220; w = 0; h = 0; point = $true; props = @() })

    # --- Küldetések: a térképen elhelyezett tartalomból becsült, biztonságosan elérhető célok ---------------------------
    $boxes = [Math]::Max(20, [int]([Math]::Floor($expectedMeteors * 0.4 / 5) * 5))
    $enemies = [Math]::Max(6, [int][Math]::Floor($enemyNormal * 0.55))
    $third = switch ($L % 4) {
        0 { @{ type = "POWERUPS"; target = [Math]::Max(3, [Math]::Min(5, $pickups - 1)) } }
        1 { @{ type = "WEAPON_STACK"; target = 3 } }
        2 { @{ type = "STOMPS"; target = [Math]::Max(3, [int][Math]::Floor($slimeBat * 0.3)) } }
        default { @{ type = "GOLD_BOXES"; target = [Math]::Max(3, [Math]::Min(7, [int][Math]::Floor($expectedGold * 0.4))) } }
    }

    return @{ def = $def; len = $len; ground = $gObjs; platforms = $pObjs; spawns = $sObjs; triggers = $tObjs; maxId = $script:id
        quests = @(@{ type = "BOXES"; target = $boxes }, @{ type = "ENEMIES"; target = $enemies }, $third) }
}

# --- Kiírás: TMX ---------------------------------------------------------------------------------------------------
function Esc($s) { return [Security.SecurityElement]::Escape([string]$s) }

function TmxProp($p) {
    $v = Esc $p.v
    if ($p.pt) { return "        <property name=`"$($p.n)`" propertytype=`"$($p.pt)`" value=`"$v`" />" }
    if ($p.t -eq "string") { return "        <property name=`"$($p.n)`" value=`"$v`" />" }
    return "        <property name=`"$($p.n)`" type=`"$($p.t)`" value=`"$v`" />"
}

function TmxObj($o) {
    $attr = "id=`"$($o.id)`""
    if ($o.name) { $attr += " name=`"$(Esc $o.name)`"" }
    $attr += " class=`"$($o.cls)`" x=`"$($o.x)`" y=`"$($o.y)`""
    if (-not $o.point) { $attr += " width=`"$($o.w)`" height=`"$($o.h)`"" }
    if ($o.props.Count -eq 0 -and -not $o.point) { return "    <object $attr />" }
    $lines = @("    <object $attr>")
    if ($o.props.Count -gt 0) {
        $lines += "      <properties>"
        foreach ($p in $o.props) { $lines += (TmxProp $p).Replace("        <property", "        <property") }
        $lines += "      </properties>"
    }
    if ($o.point) { $lines += "      <point />" }
    $lines += "    </object>"
    return ($lines -join "`n")
}

function WriteTmx($lv) {
    $d = $lv.def
    $w = [int][Math]::Ceiling($lv.len / 8)
    $sb = New-Object Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine("<map version=`"1.10`" tiledversion=`"1.10.2`" orientation=`"orthogonal`" renderorder=`"right-down`" width=`"$w`" height=`"34`" tilewidth=`"8`" tileheight=`"8`" infinite=`"0`" nextlayerid=`"5`" nextobjectid=`"$($lv.maxId + 1)`">")
    [void]$sb.AppendLine('  <editorsettings>')
    [void]$sb.AppendLine("    <export target=`"../assets/levels/$($d.file).json`" format=`"json`" />")
    [void]$sb.AppendLine('  </editorsettings>')
    [void]$sb.AppendLine('  <properties>')
    [void]$sb.AppendLine("    <property name=`"name`" value=`"$($d.name)`" />")
    [void]$sb.AppendLine("    <property name=`"theme`" propertytype=`"ThemeKind`" value=`"$($d.theme)`" />")
    [void]$sb.AppendLine("    <property name=`"speed`" type=`"float`" value=`"$($d.speed.ToString([Globalization.CultureInfo]::InvariantCulture))`" />")
    [void]$sb.AppendLine('  </properties>')
    $groups = @(@(1, "ground", $lv.ground), @(2, "platforms", $lv.platforms), @(3, "spawns", $lv.spawns), @(4, "triggers", $lv.triggers))
    foreach ($g in $groups) {
        [void]$sb.AppendLine("  <objectgroup id=`"$($g[0])`" name=`"$($g[1])`">")
        foreach ($o in $g[2]) { [void]$sb.AppendLine((TmxObj $o)) }
        [void]$sb.AppendLine('  </objectgroup>')
    }
    [void]$sb.Append('</map>')
    [IO.File]::WriteAllText((Join-Path $root "levels\$($d.file).tmx"), $sb.ToString(), (New-Object Text.UTF8Encoding($true)))
}

# --- Kiírás: JSON (a Tiled exportjával azonos szerkezet) -------------------------------------------------------------
function JsonVal($p) {
    if ($p.t -eq "int") { return [string][int]$p.v }
    if ($p.t -eq "float") { return ([double]$p.v).ToString([Globalization.CultureInfo]::InvariantCulture) }
    if ($p.t -eq "bool") { return ([string]$p.v).ToLower() }
    return '"' + ([string]$p.v).Replace('\', '\\').Replace('"', '\"') + '"'
}

function JsonObj($o) {
    $f = @()
    $f += "`"height`":$($o.h)"
    $f += "`"id`":$($o.id)"
    $f += "`"name`":`"$($o.name)`""
    $f += "`"opacity`":1"
    if ($o.point) { $f += "`"point`":true" }
    if ($o.props.Count -gt 0) {
        $ps = @()
        foreach ($p in $o.props) {
            $jt = $p.t
            $ps += "{`"name`":`"$($p.n)`",`"type`":`"$jt`",`"value`":$(JsonVal $p)}"
        }
        $f += "`"properties`":[$($ps -join ',')]"
    }
    $f += "`"rotation`":0"
    $f += "`"type`":`"$($o.cls)`""
    $f += "`"visible`":true"
    $f += "`"width`":$($o.w)"
    $f += "`"x`":$($o.x)"
    $f += "`"y`":$($o.y)"
    return "{" + ($f -join ",") + "}"
}

function WriteJson($lv) {
    $d = $lv.def
    $w = [int][Math]::Ceiling($lv.len / 8)
    $layers = @()
    $groups = @(@(1, "ground", $lv.ground), @(2, "platforms", $lv.platforms), @(3, "spawns", $lv.spawns), @(4, "triggers", $lv.triggers))
    foreach ($g in $groups) {
        $objs = @(); foreach ($o in $g[2]) { $objs += (JsonObj $o) }
        $layers += "{`"draworder`":`"topdown`",`"id`":$($g[0]),`"name`":`"$($g[1])`",`"objects`":[$($objs -join ',')],`"opacity`":1,`"type`":`"objectgroup`",`"visible`":true,`"x`":0,`"y`":0}"
    }
    $speed = $d.speed.ToString([Globalization.CultureInfo]::InvariantCulture)
    $json = "{`"compressionlevel`":-1,`"height`":34,`"infinite`":false,`"layers`":[$($layers -join ',')],`"nextlayerid`":5,`"nextobjectid`":$($lv.maxId + 1),`"orientation`":`"orthogonal`","
    $json += "`"properties`":[{`"name`":`"name`",`"type`":`"string`",`"value`":`"$($d.name)`"},{`"name`":`"speed`",`"type`":`"float`",`"value`":$speed},{`"name`":`"theme`",`"type`":`"string`",`"value`":`"$($d.theme)`"}],"
    $json += "`"renderorder`":`"right-down`",`"tiledversion`":`"1.12.2`",`"tileheight`":8,`"tilesets`":[],`"tilewidth`":8,`"type`":`"map`",`"version`":`"1.10`",`"width`":$w}"
    [IO.File]::WriteAllText((Join-Path $root "assets\levels\$($d.file).json"), $json, (New-Object Text.UTF8Encoding($false)))
}

$hx = @()
foreach ($d in $defs) {
    $lv = Generate $d
    WriteTmx $lv       # előbb a .tmx, utána az export: az export legyen újabb a forrásnál (validate-levels.ps1)
    Start-Sleep -Milliseconds 50
    WriteJson $lv
    $goals = ($lv.quests | ForEach-Object { "{type: $($_.type), target: $($_.target)}" }) -join ", "
    $hx += "`t`t{name: `"$($d.name)`", goals: [$goals], speed: $($d.speed.ToString([Globalization.CultureInfo]::InvariantCulture)), map: `"assets/levels/$($d.file).json`"},"
    Write-Host ("{0,-2} {1,-18} hossz {2,5}, talaj {3,3}, platform {4,2}, spawn {5,3}" -f $d.n, $d.name, $lv.len, $lv.ground.Count, $lv.platforms.Count, $lv.spawns.Count)
}
Write-Host "`nQuests.hx LEVELS (3-10. pálya):"
$hx | ForEach-Object { Write-Host $_ }

