# A konfiguráció, a hős követő sebessége, a gomba, az automata lövés és a cheat-menü tesztje fejnélküli Edge-ben.
# Teszt-build kell: `haxelib run lime build html5 -Dtest`, kiszolgálva a 3000-es porton.
#   powershell -ExecutionPolicy Bypass -File tests/features.ps1 [-Url http://127.0.0.1:3000/]
param([string]$Url = "http://127.0.0.1:3000/", [string]$Out = (Join-Path $env:TEMP "moonshard-tests"))

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\cdp-lib.ps1"
$script:fails = 0

function Check($name, $ok, $detail = "") {
    if ($ok) { Write-Host "PASS  $name" -ForegroundColor Green }
    else { Write-Host "FAIL  $name  $detail" -ForegroundColor Red; $script:fails++ }
}
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 70; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 140 }

try {
    Start-Cdp "$($Url)?level=0" $Out
    Start-Sleep -Seconds 4
    Js @'
(() => {
  const g = window.__game;
  setInterval(() => { if (!g.dead) g.player.energy = Math.max(g.player.energy, 100); }, 20);
  window.__fz = null;
  window.__freeze = () => { if (!window.__fz) window.__fz = setInterval(() => { g.scrollSpeed = 0; }, 5); };
  window.__unfreeze = () => { clearInterval(window.__fz); window.__fz = null; };
  return true;
})()
'@ | Out-Null

    # --- 1. Konfiguráció ---------------------------------------------------------------------
    $c = Js "(() => { const C = window.__config; return { run: C.runSpeed, follow: C.followRatio, scrollMax: C.scrollMax, dmgLarge: C.damageMeteorLarge, unlock: C.enemyUnlock, warn: C.warnings }; })()"
    Check "a game.json betöltődött, az értékek az alapértékek" ($c.run -eq 200 -and $c.follow -eq 1.35 -and $c.scrollMax -eq 170 -and $c.dmgLarge -eq 50 -and @($c.unlock).Count -eq 4) ($c | ConvertTo-Json -Compress)
    Check "nincs konfigurációs figyelmeztetés" (@($c.warn).Count -eq 0) ($c.warn -join "; ")
    $cc = Js @'
(() => {
  const C = window.__config;
  C.loadFromText(JSON.stringify({ player: { runSpeed: 99999, followRatio: "x" }, damage: { fall: -5 }, scroll: { max: 300 }, difficulty: { scrollMul: [1, 2] }, spawning: { enemyUnlock: [5, 10, 15, 20] } }));
  const r = { run: C.runSpeed, follow: C.followRatio, fall: C.damageFall, max: C.scrollMax, mul: C.scrollMul, unlock: C.enemyUnlock, warns: C.warnings.length };
  C.loadFromText(JSON.stringify({}));
  return r;
})()
'@
    Check "tartományon kívüli érték a határra szorul, hibás érték marad az, ami volt" ($cc.run -eq 1500 -and $cc.follow -eq 1.35 -and $cc.fall -eq 0 -and $cc.warns -ge 3) ($cc | ConvertTo-Json -Compress)
    Check "a beállított értékek hatnak, a hibás tömb nem" ($cc.max -eq 300 -and @($cc.mul).Count -eq 3 -and $cc.mul[1] -eq 1 -and $cc.unlock[0] -eq 5)
    $bad = Js "(() => { try { window.__config.loadFromText('{nope'); return 'no-throw'; } catch (e) { return 'throws'; } })()"
    Check "hibás JSON-nál a loadFromText kivételt dob (a load() ezt elnyeli)" ($bad -eq "throws")
    # Visszaállítás az alapértékekre
    Js "(() => { window.__config.loadFromText(JSON.stringify({ player: { runSpeed: 200, followRatio: 1.35 }, damage: { fall: 30 }, scroll: { max: 170 }, spawning: { enemyUnlock: [20, 45, 75, 110] } })); return 1; })()" | Out-Null

    # --- 2. A hős követi a kamera sebességét ----------------------------------------------------
    Js "(() => { const g = window.__game; g.noSpawns = true; g.cheatScroll(300); g.levelTime = 99; return 1; })()" | Out-Null
    Start-Sleep -Milliseconds 600
    $r = Js "(() => { const g = window.__game; return { scroll: g.scrollSpeed, run: g.player.runSpeed }; })()"
    Check "kamera 300 px/s-nál a hős sebességhatára legalább 1,35x" ($r.scroll -ge 299 -and $r.run -ge 300 * 1.35 - 1) "scroll=$($r.scroll) run=$($r.run)"
    Js "(() => { const g = window.__game; g.respawnPlayer(); g.player.setPosition(g.player.get_camera().scroll.x + 80, 150); g.player.velocity.set(0, 0); return 1; })()" | Out-Null
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    $v = Js "(async () => { let m = 0; const t0 = performance.now(); while (performance.now() - t0 < 900) { m = Math.max(m, window.__game.player.velocity.x); await new Promise(r => setTimeout(r, 15)); } return m; })()"
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    Check "a hős futási sebessége meghaladja a kamerát (a legnagyobb sebesség > 320)" ($v -gt 320) "vmax=$v"
    Js "window.__game.cheatScroll(null)" | Out-Null
    # Lassú kameránál az alap futási sebesség marad
    Js "(() => { window.__game.cheatScroll(60); return 1; })()" | Out-Null
    Start-Sleep -Milliseconds 400
    $slow = Js "window.__game.player.runSpeed"
    Check "lassú kameránál az alap futási sebesség marad (200)" ($slow -eq 200) "run=$slow"
    Js "window.__game.cheatScroll(null)" | Out-Null

    # --- 3. A gomba nem lőhető -------------------------------------------------------------------
    Js "(() => { const g = window.__game; g.cheatScroll(0); g.respawnPlayer(); return 1; })()" | Out-Null
    Start-Sleep -Milliseconds 400
    $s = Js @'
(async () => {
  const g = window.__game;
  g.shrooms.forEachAlive(s => s.kill());
  g.cheatShroom();
  const s = g.shrooms.members.find(m => m.alive);
  for (let i = 0; i < 6; i++) { g.fireBullet(s.x - 40, s.y + s.height / 2, 1, 0, 1, false); await new Promise(r => setTimeout(r, 40)); }
  g.fireLaser(s.x - 60, s.y + s.height / 2, 1, 0, 1);
  g.cheatPowerName('NUKE');
  await new Promise(r => setTimeout(r, 500));
  return { found: !!s, alive: s.alive };
})()
'@
    Check "a gomba megvan, a lövések, a lézer és az atom sem pusztítja el" ($s.found -eq $true -and $s.alive -eq $true)

    # --- 4. Automata lövés ------------------------------------------------------------------------
    $a = Js @'
(async () => {
  const g = window.__game, S = window.__settings;
  g.cheatBaseWeapon(null);
  // A lövedékobjektumok újrahasznosulnak, ezért a lövések számát a fireBullet hívásaiból számoljuk
  let fired = 0; const orig = g.fireBullet.bind(g); g.fireBullet = (...a) => { fired++; return orig(...a); };
  const count = async (ms) => { fired = 0; const t0 = performance.now(); while (performance.now() - t0 < ms) await new Promise(r => setTimeout(r, 15)); return fired; };
  S.autoFire = false;
  const off = await count(800);
  S.autoFire = true;
  const on = await count(800);
  S.autoFire = false;
  g.fireBullet = orig;
  return { off, on };
})()
'@
    Check "automata lövés nélkül, gombnyomás nélkül nincs lövés" ($a.off -le 0) "off=$($a.off)"
    Check "automata lövéssel gombnyomás nélkül lő" ($a.on -ge 3) "on=$($a.on)"
    $persist = Js "(() => { const S = window.__settings; S.autoFire = true; S.store(); return Object.values(localStorage).some(v => String(v).includes('autoFire')); })()"
    Check "az automata lövés mentődik a localStorage-ba" ($persist -eq $true)
    Js "(() => { window.__settings.autoFire = false; window.__settings.store(); return 1; })()" | Out-Null

    # --- 5. Cheat-menü (F9) ---------------------------------------------------------------------------
    Tap "F9" "F9" 120
    Start-Sleep -Milliseconds 250
    Shot "features_cheat_menu.png"
    Check "az F9 megnyitja a cheat-menüt" ((Js "!!window.__game.subState") -eq $true)
    Tap "Enter" "Enter" 13           # WEAPONS
    Start-Sleep -Milliseconds 250
    Shot "features_cheat_weapons.png"
    $pg = Js "window.__game.subState ? window.__game.subState.page : null"
    Check "Enter: a WEAPONS lap nyílik" ($pg -eq "weapons") "page=$pg"
    Tap "ArrowDown" "ArrowDown" 40   # FLAMETHROWER
    Tap "ArrowDown" "ArrowDown" 40   # LASER
    Tap "Enter" "Enter" 13
    Start-Sleep -Milliseconds 300
    $w = Js "(() => { const g = window.__game; return { base: g.baseWeapon ? g.baseWeapon._hx_name : null, open: !!g.subState }; })()"
    Check "a menüből kiválasztott LASER aktív, a menü bezárult" ($w.base -eq "LASER" -and $w.open -eq $false) ($w | ConvertTo-Json -Compress)
    Tap "F9" "F9" 120
    Tap "Escape" "Escape" 27
    Start-Sleep -Milliseconds 200
    Check "ESC bezárja a menüt a főlapról" ((Js "!!window.__game.subState") -eq $false)

    # --- 6. Minden fegyver, kiegészítő és bónusz kipróbálható ---------------------------------------------
    foreach ($n in "FLAME", "LASER", "DEATHRAY") {
        $x = Js @"
(async () => {
  const g = window.__game;
  g.bullets.forEachAlive(b => b.kill()); g.beams.forEachAlive(b => b.kill());
  const ok = g.cheatPowerName('$n');
  g.laserTimer = 0;
  g.shoot(g.player.x + 6, g.player.y + 7, 1, 0);
  await new Promise(r => setTimeout(r, 60));
  return { ok, base: g.baseWeapon ? g.baseWeapon._hx_name : null, shots: Math.max(0, g.bullets.countLiving()), beams: Math.max(0, g.beams.countLiving()) };
})()
"@
        Check "fegyver $n : aktív és lő" ($x.ok -eq $true -and $x.base -eq $n -and ($x.shots + $x.beams) -ge 1) ($x | ConvertTo-Json -Compress)
    }
    $mods = Js "(() => { const g = window.__game; return ['SPREAD','RAPID','HEAVY'].map(n => g.cheatPowerName(n)); })()"
    $slots = Js "window.__game.weaponStack()"
    Check "a három kiegészítő és az alapfegyver egymásra rakódik (4)" (@($mods | Where-Object { $_ -eq $true }).Count -eq 3 -and $slots -eq 4) "stack=$slots"
    $p = Js "(() => { const g = window.__game; const r = {}; for (const n of ['SHIELD','SLOWMO','BONUS','ENERGY','NUKE']) r[n] = g.cheatPowerName(n); r.shieldT = g.shieldTimer; r.slowT = g.slowTimer; return r; })()"
    Check "védelem, lassítás, bónusz, energia, atom mind alkalmazható" ($p.SHIELD -and $p.SLOWMO -and $p.BONUS -and $p.ENERGY -and $p.NUKE -and $p.shieldT -gt 0 -and $p.slowT -gt 0) ($p | ConvertTo-Json -Compress)
    Js "(() => { const g = window.__game; g.shieldTimer = 0; g.slowTimer = 0; g.cheatClearMods(); g.cheatBaseWeapon(null); return 1; })()" | Out-Null

    # --- 7. Nehezítők kipróbálása --------------------------------------------------------------------------
    $h = Js @'
(async () => {
  const g = window.__game;
  g.noSpawns = true;
  // A meteorok egy része a hősre esik és eltűnik, ezért a kiadott meteorokat a spawnMeteor hívásaiból számoljuk
  let spawned = 0; const origMeteor = g.spawnMeteor.bind(g); g.spawnMeteor = (...a) => { spawned++; return origMeteor(...a); };
  g.shrooms.forEachAlive(s => s.kill()); g.enemies.forEachAlive(e => e.kill()); g.blocks.forEachAlive(b => b.kill());
  g.cheatShroom();
  const shroom = g.shrooms.members.some(m => m.alive);
  g.cheatTrip();
  const trip = g.tripTimer > 0;
  for (let i = 0; i < 4; i++) g.cheatEnemy(i);
  const kinds = g.enemies.members.filter(e => e.alive).map(e => e.kind).sort();
  g.cheatMeteor(false); g.cheatMeteor(true);
  g.cheatShower();
  await new Promise(r => setTimeout(r, 2200));
  g.spawnMeteor = origMeteor;
  return { shroom, trip, kinds, meteors: spawned };
})()
'@
    Check "gomba, hallucináció, mind a 4 ellenség, meteorok és zápor előhívható" ($h.shroom -and $h.trip -and @($h.kinds).Count -ge 4 -and $h.meteors -ge 6) ($h | ConvertTo-Json -Compress)
    Js "(() => { const g = window.__game; g.tripTimer = 0.01; g.enemies.forEachAlive(e => e.kill()); g.blocks.forEachAlive(b => b.kill()); return 1; })()" | Out-Null

    # --- 8. Kapcsolók ---------------------------------------------------------------------------------------
    $t = Js @'
(async () => {
  const g = window.__game, r = {};
  // god mode
  g.godMode = true; g.player.hurtTimer = 0;
  const e0 = g.player.energy;
  r.godReturn = g.damagePlayer(80, false);
  r.godEnergy = g.player.energy === e0;
  g.godMode = false;
  // freeze power timers
  g.cheatPowerName('SHIELD');
  g.freezePowers = true;
  await new Promise(r => setTimeout(r, 1600));
  r.frozenShield = g.shieldTimer;
  g.freezePowers = false;
  await new Promise(r => setTimeout(r, 1000));
  r.runningShield = g.shieldTimer;
  g.shieldTimer = 0;
  // no spawns
  g.noSpawns = true; g.spawnTimer = 50; g.cheatScroll(null); g.levelState = 'PLAYING';
  await new Promise(r => setTimeout(r, 800));
  r.noSpawnTimer = g.spawnTimer;
  g.noSpawns = false;
  // scroll override
  g.cheatScroll(120);
  await new Promise(r => setTimeout(r, 300));
  r.scroll = g.scrollSpeed;
  g.cheatScroll(null);
  r.tag = g.cheatTagText();
  return r;
})()
'@
    Check "GOD MODE: nincs sebzés" ($t.godReturn -eq $true -and $t.godEnergy -eq $true)
    Check "FREEZE POWER-UP TIMERS: a sérthetetlenség ideje áll, kapcsoló nélkül fogy" ($t.frozenShield -ge 6.9 -and $t.runningShield -lt 6.5) "frozen=$($t.frozenShield) running=$($t.runningShield)"
    Check "NO SPAWNS: a meteor-időzítő nem fogy" ($t.noSpawnTimer -ge 49.9) "timer=$($t.noSpawnTimer)"
    Check "SCROLL SPEED: kézi sebesség" ($t.scroll -eq 120) "scroll=$($t.scroll)"

    # --- 9. Pályaműveletek ---------------------------------------------------------------------------------------
    Js "(() => { const g = window.__game; g.noSpawns = true; g.cheatScroll(null); return 1; })()" | Out-Null
    Js "window.__game.cheatCompleteQuests()" | Out-Null
    Check "COMPLETE QUESTS: mind a 3 küldetés kész" ((Js "window.__quests.completedCount()") -eq 3)
    Js "window.__game.cheatSkipToBoss()" | Out-Null
    $seen = @{}
    for ($i = 0; $i -lt 40; $i++) { Start-Sleep -Milliseconds 250; $st = Js "window.__game.levelState"; $seen[$st] = $true; if ($st -eq "BOSS" -and (Js "!window.__game.boss.entering")) { break } }
    Check "SKIP TO BOSS: BOSS_INTRO majd BOSS" ($seen.ContainsKey("BOSS_INTRO") -and $seen.ContainsKey("BOSS")) ($seen.Keys -join ",")
    Js "window.__game.cheatKillBoss()" | Out-Null
    Check "KILL BOSS: CLEAR állapot" ((Js "window.__game.levelState") -eq "CLEAR")
    Js "window.__game.cheatNextLevel()" | Out-Null
    $nl = Js "(() => ({ level: window.__quests.level, state: window.__game.levelState }))()"
    Check "NEXT LEVEL: a következő pálya indul" ($nl.level -ge 1 -and $nl.state -eq "PLAYING") ($nl | ConvertTo-Json -Compress)

    Check "nem volt JS-hiba" (@((Js "window.__errors")).Count -eq 0) ((Js "window.__errors") -join "; ")
}
catch { Write-Host "A teszt kivételt dobott: $($_.Exception.Message)" -ForegroundColor Red; $script:fails++ }
finally { Stop-Cdp }

if ($script:fails -gt 0) { Write-Host "`n$script:fails ellenőrzés elbukott." -ForegroundColor Red; exit 1 }
Write-Host "`nMinden ellenőrzés rendben." -ForegroundColor Green
