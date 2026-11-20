# Tiled-pályák tesztje fejnélküli Edge-ben (a játék -Dtest buildje kell, kiszolgálva az 3000-es porton).
#   haxelib run lime build html5 -Dtest
#   (a build/export/html5/bin kiszolgálása: haxelib run lime test html5, vagy bármely statikus szerver)
#   powershell -ExecutionPolicy Bypass -File tests/levels.ps1 [-Url http://127.0.0.1:3000/]
# A kilépési kód 1, ha valamelyik ellenőrzés elbukott.
param([string]$Url = "http://127.0.0.1:3000/", [string]$Out = (Join-Path $env:TEMP "moonshard-tests"))

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\cdp-lib.ps1"
$script:fails = 0

function Check($name, $ok, $detail = "") {
    if ($ok) { Write-Host "PASS  $name" -ForegroundColor Green }
    else { Write-Host "FAIL  $name  $detail" -ForegroundColor Red; $script:fails++ }
}

# A tesztek közben a hős nem halhat meg; a kamera szükség szerint befagyasztható
$prep = @'
(() => {
  const g = window.__game;
  setInterval(() => { if (!g.dead) g.player.energy = 100; }, 20);
  window.__freeze = () => { window.__fz = setInterval(() => { g.scrollSpeed = 0; g.spawnTimer = 999; g.enemyTimer = 999; }, 5); };
  window.__unfreeze = () => { clearInterval(window.__fz); };
  window.__freeze();
  return true;
})()
'@

try {
    Start-Cdp "$($Url)?level=0" $Out
    Start-Sleep -Seconds 4
    Js $prep | Out-Null

    # --- 1. Betöltés -------------------------------------------------------------------
    $l = Js "(() => { const g = window.__game, L = g.lvl; return { loaded: !!L, name: L && L.name, ground: L && L.ground.length, spawns: L && L.spawns.length, showers: L && L.showers.length, bossX: L && L.bossX, live: g.ground.countLiving(), err: window.__loader.lastError, quests: window.__quests.goals.map((x, i) => window.__quests.text(i)) }; })()"
    Check "pálya betöltve a beágyazott assetből" ($l.loaded -eq $true) "hiba: $($l.err)"
    Check "a térkép neve" ($l.name -eq "CRATER FIELDS")
    Check "talajok, spawnok, záporok" ($l.ground -gt 30 -and $l.spawns -gt 10 -and $l.showers -eq 3) "ground=$($l.ground) spawns=$($l.spawns) showers=$($l.showers)"
    Check "Boss trigger" ($l.bossX -eq 9120)
    Check "kezdőablak talaja korlátos (lusta létrehozás)" ($l.live -gt 0 -and $l.live -le 25) "live=$($l.live)"
    Check "a küldetések megmaradnak" ($l.quests.Count -eq 3)
    $ahead = Js "(() => { const g = window.__game; const sx = g.player.get_camera().scroll.x; return g.ground.members.some(m => m.alive && m.height > 20 && m.width > 60 && m.x > sx + 150); })()"
    Check "van talaj a hős előtt (a smoke.js feltétele)" ($ahead -eq $true)

    # --- 2. Streaming ------------------------------------------------------------------
    Js "window.__game.seek(4000)" | Out-Null
    Start-Sleep -Milliseconds 400
    $s = Js "(() => { const g = window.__game; const live = g.ground.members.filter(m => m.alive); return { n: live.length, minRight: Math.min(...live.map(m => m.x + m.width)), covers: live.some(m => m.height > 20 && m.x <= 4140 && m.x + m.width >= 4140), top: g.lvl.groundTop(4140) }; })()"
    Check "seek után a talaj a kamera körül van" ($s.minRight -gt 3800 -and $s.covers -eq $true) "minRight=$($s.minRight)"

    # --- 3. Spawnok ----------------------------------------------------------------------
    $t = Js @'
(async () => {
  const g = window.__game, L = g.lvl;
  const sp = L.spawns.find(s => s.type === 0 && s.enemy === 2); // TURRET
  g.seek(sp.trigger - 30);
  await new Promise(r => setTimeout(r, 200));
  const before = g.enemies.countLiving();
  g.player.get_camera().scroll.x = sp.trigger + 2;
  await new Promise(r => setTimeout(r, 700));
  const e = g.enemies.members.find(m => m.alive && m.kind === 2);
  return { before, found: !!e, dx: e ? Math.abs(e.x + e.width / 2 - sp.x) : -1, bottom: e ? e.y + e.height : -1, top: L.groundTop(sp.x) };
})()
'@
    Check "turret: nem volt előtte, megjelenik" ($t.before -le 0 -and $t.found -eq $true) "before=$($t.before) found=$($t.found)"
    Check "turret a talaj tetején áll, a pontos x-nél" ($t.dx -lt 1.5 -and [Math]::Abs($t.bottom - $t.top) -lt 3) "dx=$($t.dx) bottom=$($t.bottom) top=$($t.top)"

    $m = Js @'
(async () => {
  const g = window.__game, L = g.lvl;
  const sp = L.spawns.find(s => s.type === 2); // SHROOM
  g.seek(sp.trigger - 30);
  g.player.setPosition(g.player.get_camera().scroll.x + 20, 100);
  await new Promise(r => setTimeout(r, 200));
  g.player.get_camera().scroll.x = sp.trigger + 2;
  await new Promise(r => setTimeout(r, 400));
  const s = g.shrooms.members.find(m => m.alive);
  return { found: !!s, bottom: s ? s.y + s.height : -1, top: L.groundTop(sp.x) };
})()
'@
    Check "varázsgomba a talajon" ($m.found -eq $true -and [Math]::Abs($m.bottom - $m.top) -lt 2) "bottom=$($m.bottom) top=$($m.top)"

    $p = Js @'
(async () => {
  const g = window.__game, L = g.lvl;
  const sp = L.spawns.find(s => s.type === 1); // PICKUP
  g.seek(sp.trigger - 30);
  g.player.setPosition(g.player.get_camera().scroll.x + 20, 100);
  await new Promise(r => setTimeout(r, 200));
  g.player.get_camera().scroll.x = sp.trigger + 2;
  await new Promise(r => setTimeout(r, 300));
  const p = g.pickups.members.find(m => m.alive);
  const found = !!p;
  const persistent = p ? p.persistent : null;
  await new Promise(r => setTimeout(r, 10500)); // a sima bónusz 9 mp után eltűnne
  return { found, persistent, stillAlive: p ? p.alive : false };
})()
'@
    Check "elhelyezett bónusz megjelenik és tartós" ($p.found -eq $true -and $p.persistent -eq $true)
    Check "a bónusz 10 mp után is megvan" ($p.stillAlive -eq $true)

    $w = Js @'
(async () => {
  const g = window.__game, L = g.lvl;
  const sh = L.showers[0];
  g.seek(sh.x + 80);
  g.player.setPosition(g.player.get_camera().scroll.x + 20, 100);
  const b0 = g.blocksDestroyed;
  await new Promise(r => setTimeout(r, 3500));
  return { meteors: g.blocks.countLiving() + (g.blocksDestroyed - b0) };
})()
'@
    Check "meteorzápor meteorokat hoz" ($w.meteors -ge 1) "meteors=$($w.meteors)"

    # --- 4. Főellenség és pályaváltás -----------------------------------------------------
    Js "window.__unfreeze()" | Out-Null
    Js "(() => { const g = window.__game; g.seek(g.lvl.bossX - 175); g.enemies.forEachAlive(e => e.kill()); g.blocks.forEachAlive(b => b.kill()); return 1; })()" | Out-Null
    $seen = @{}
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        $st = Js "window.__game.levelState"
        $seen[$st] = $true
        if ($st -eq "BOSS") { break }
    }
    # A főellenség beúszása közben sebezhetetlen: megvárjuk
    for ($i = 0; $i -lt 40; $i++) {
        if ((Js "(() => { const b = window.__game.boss; return !!b && !b.entering; })()") -eq $true) { break }
        Start-Sleep -Milliseconds 250
    }
    Check "BOSS_INTRO majd BOSS állapot a trigger után" ($seen.ContainsKey("BOSS_INTRO") -and $seen.ContainsKey("BOSS")) ("látott: " + ($seen.Keys -join ","))
    $b = Js "(() => { const g = window.__game; return { cam: g.player.get_camera().scroll.x, arena: g.bossArenaX, speed: g.scrollSpeed, boss: !!g.boss }; })()"
    Check "a kamera az arénánál áll" ($b.cam -le $b.arena + 0.5 -and $b.speed -eq 0 -and $b.boss -eq $true) "cam=$($b.cam) arena=$($b.arena) speed=$($b.speed)"
    Shot "levels_boss.png"

    $scoreBefore = Js "window.__game.score()"
    Js "window.__game.damageBoss(1e9)" | Out-Null
    $clear = Js "window.__game.levelState"
    Check "a főellenség legyőzése után CLEAR" ($clear -eq "CLEAR") "állapot: $clear"
    Start-Sleep -Seconds 5
    $n = Js "(() => { const g = window.__game, Q = window.__quests; return { level: Q.level, name: g.lvl && g.lvl.name, cam: g.player.get_camera().scroll.x, enemies: g.enemies.countLiving(), boss: !!g.boss, state: g.levelState, px: g.player.x + g.player.width / 2, startX: g.lvl && g.lvl.startX, score: g.score(), quests: Q.done.filter(d => d).length }; })()"
    Check "a 2. pálya töltődött be" ($n.level -eq 1 -and $n.name -eq "ASHEN VALLEY") "level=$($n.level) name=$($n.name)"
    Check "a kamera és a hős a kezdőponton, a világ üres" ($n.cam -lt 120 -and $n.enemies -le 0 -and $n.boss -eq $false -and $n.state -eq "PLAYING" -and [Math]::Abs($n.px - $n.startX) -lt 40) "cam=$($n.cam) enemies=$($n.enemies) px=$($n.px)"
    Check "a pontszám nem esik vissza a pályaváltáskor" ($n.score -ge $scoreBefore) "előtte=$scoreBefore utána=$($n.score)"
    Check "az új pálya küldetései nulláról indulnak" ($n.quests -eq 0)
    Shot "levels_level2.png"

    # --- 5. Procedurális tartalék a térképek után -------------------------------------------
    $f = Js "(() => { const g = window.__game; g.nextLevel(); return { level: window.__quests.level, lvlNull: g.lvl === null, live: g.ground.countLiving(), name: window.__quests.levelDef(window.__quests.level).name }; })()"
    Start-Sleep -Milliseconds 600
    $f2 = Js "(() => { const g = window.__game; g.updateSpawner(0); return { live: g.ground.countLiving(), state: g.levelState }; })()"
    Check "a 3. pálya procedurális (BLOOD MOON)" ($f.level -eq 2 -and $f.lvlNull -eq $true -and $f2.live -gt 0 -and $f2.state -eq "PLAYING") "name=$($f.name) live=$($f2.live)"

    # --- 6. Hibás és szélső térképek ------------------------------------------------------------
    $bad = Js @'
(() => {
  const L = window.__loader;
  const r = {};
  r.json = L.inject('bad-json', '{nope') === null;
  const base = { orientation: 'orthogonal', infinite: false, tilewidth: 8, tileheight: 8, width: 100, height: 34 };
  const layer = (objects) => [{ type: 'objectgroup', name: 'x', objects }];
  const ground = (id, x, w) => ({ id, class: 'Ground', x, y: 232, width: w, height: 38 });
  const boss = { id: 90, class: 'Boss', x: 600, y: 232, point: true };
  const end = { id: 91, class: 'End', x: 600, y: 232, point: true };
  const ply = { id: 92, class: 'Player', x: 100, y: 232, point: true };
  r.noTrigger = L.inject('no-trigger', JSON.stringify(Object.assign({}, base, { layers: layer([ground(1, 0, 800), ply]) }))) === null;
  r.noTriggerMsg = L.lastError;
  r.noGround = L.inject('no-ground', JSON.stringify(Object.assign({}, base, { layers: layer([ply, end]) }))) === null;
  r.overlap = L.inject('overlap', JSON.stringify(Object.assign({}, base, { layers: layer([ground(1, 0, 500), ground(2, 300, 500), ply, end]) }))) === null;
  r.overlapMsg = L.lastError;
  r.noGroundAtStart = L.inject('no-start-ground', JSON.stringify(Object.assign({}, base, { layers: layer([ground(1, 400, 500), ply, end]) }))) === null;
  r.infinite = L.inject('infinite', JSON.stringify(Object.assign({}, base, { infinite: true, layers: layer([ground(1, 0, 800), ply, end]) }))) === null;
  // Érvényes, de hibás objektumokat tartalmazó térkép: az objektumok kimaradnak, a térkép betölt
  const ok = L.inject('ok', JSON.stringify(Object.assign({}, base, { layers: layer([ground(1, 0, 800), ply, end,
    { id: 10, class: 'Enemy', x: 300, y: 232, point: true, properties: [{ name: 'kind', type: 'string', value: 'NOPE' }] },
    { id: 11, class: 'Enemy', x: 320, y: 232, point: true, properties: [{ name: 'kind', type: 'string', value: 'slime' }, { name: 'count', type: 'int', value: 3 }] },
    { id: 12, class: 'Whatever', x: 1, y: 1 }]) })));
  r.okLoaded = !!ok;
  r.okSpawns = ok ? ok.spawns.length : -1;
  r.okEnemyCount = ok && ok.spawns[0] ? ok.spawns[0].count : -1;
  r.okWarnings = ok ? ok.warnings.length : -1;
  return r;
})()
'@
    Check "rossz JSON -> null" ($bad.json -eq $true)
    Check "hiányzó Boss/End -> null" ($bad.noTrigger -eq $true -and $bad.noTriggerMsg -match "Boss") $bad.noTriggerMsg
    Check "hiányzó talaj -> null" ($bad.noGround -eq $true)
    Check "átfedő talaj -> null" ($bad.overlap -eq $true -and $bad.overlapMsg -match "átfedő") $bad.overlapMsg
    Check "nincs talaj a kezdőpont alatt -> null" ($bad.noGroundAtStart -eq $true)
    Check "infinite térkép -> null" ($bad.infinite -eq $true)
    Check "hibás objektumok kimaradnak, a térkép betölt (kisbetűs enum, alapértékek)" ($bad.okLoaded -eq $true -and $bad.okSpawns -eq 1 -and $bad.okEnemyCount -eq 3 -and $bad.okWarnings -ge 2) ($bad | ConvertTo-Json -Compress)

    # Hibás térkép a játékban: tartalék a procedurális generálásra, nem omlik össze
    $fb = Js @'
(async () => {
  const g = window.__game, Q = window.__quests;
  Q.LEVELS[0].map = 'bad-json';
  Q.resetCache();
  Q.startLevel(0);
  g.beginLevel(0, false);
  await new Promise(r => setTimeout(r, 800));
  return { lvlNull: g.lvl === null, live: g.ground.countLiving(), dead: g.dead, errors: window.__errors };
})()
'@
    Check "hibás térkép: procedurális tartalék, nincs összeomlás" ($fb.lvlNull -eq $true -and $fb.live -gt 0 -and @($fb.errors).Count -eq 0) ($fb | ConvertTo-Json -Compress)

    # End trigger (főellenség nélküli pálya)
    $en = Js @'
(async () => {
  const g = window.__game, Q = window.__quests;
  Q.LEVELS[0].map = 'ok';
  Q.resetCache();
  Q.startLevel(0);
  g.beginLevel(0, false);
  g.seek(200);
  g.player.setPosition(250, 100);
  await new Promise(r => setTimeout(r, 1500));
  return { state: g.levelState, lvl: !!g.lvl };
})()
'@
    Check "End trigger lezárja a pályát" ($en.lvl -eq $true -and $en.state -eq "CLEAR") ($en | ConvertTo-Json -Compress)

    Check "nem volt JS-hiba" (@((Js "window.__errors")).Count -eq 0) ((Js "window.__errors") -join "; ")
}
finally {
    Stop-Cdp
}

if ($script:fails -gt 0) { Write-Host "`n$script:fails ellenőrzés elbukott." -ForegroundColor Red; exit 1 }
Write-Host "`nMinden ellenőrzés rendben." -ForegroundColor Green
