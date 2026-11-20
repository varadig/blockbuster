# Moonshard – projekt jegyzetek (a fejlesztői munkacím: Blockbuster; a projektmappa és a mentési kulcsok neve emiatt még lockbuster, a mentések megőrzése miatt nem változtatjuk)

- Nyelv/engine: Haxe 4.3.6, HaxeFlixel 6.2.1 (lime 8.3.2, openfl 9.5.2). Csak ezekre a verziókra írj kódot.
- Build: `haxelib run lime build html5` (teszthez `-Dtest`: egyből a PlayState indul, `window.__game`-ben elérhető, és fókusz nélkül sem áll meg).
- Füstteszt: `export/html5/bin` kiszolgálása a 8765-ös porton, majd `node tests/smoke.js`.
- Belső felbontás 480x270 (Main.hx), az ablak 960x540.
- Grafika kódból generált pixel art (`PixelArt.hx`, Sweetie 16 alapú paletta), nincsenek képfájlok. A pályák Tiled JSON-ból jönnek (`assets/levels/*.json`, beágyazva); a .tmx források a `levels/` mappában vannak, leírásuk: `docs/LEVELS.md`.
- Megjelenítés: böngészőben a vászon kitölti az ablakot (Project.xml: html5 width/height = 0), `RatioScaleMode` arányos nagyítás 16:9-ben, `camera.pixelPerfectRender` + antialiasing nélkül.
- Hang is kódból generált (`Audio.hx` szintetizátor + 8 bites WAV, `Music.hx` tracker-dal), nincsenek hangfájlok.
- Ne használd a deprecated `FlxObject.health`-et; a blokkoknak saját `hp`, a játékosnak `energy` mezője van.
- A `FlxG.worldBounds`-ot görgetéskor a kamerával együtt kell mozgatni, különben a távoli objektumok nem ütköznek.
- A `PowerKind` és a `BulletKind` neveiben van átfedés (LASER, ROCKET, GRENADE): a PlayState-ben `BulletKind.X` alakban hivatkozz.
- Kommentek magyarul, a játék UI szövegei angolul.

## Felépítés
- `source/Main.hx` – FlxGame indítása (TitleState; `-Dtest` esetén PlayState)
- `source/TitleState.hx` – nyitóképernyő: ládás logó, menü (START / SETTINGS), csúcspontszám
- `source/PlayState.hx` – hőst követő kamera (`updateCamera`: csak előre, `bossArenaX`-nél megáll), becsapódás-jelzők (`updateImpactMarks`), töltésjelző, talaj (Tiled-térképből `streamGround`, tartalékként procedurális `generateGround`), `beginLevel` (pályaváltás), `updateAuthored` (szerkesztett spawnok), meteor-spawner, fegyverek, bónuszok, energia, HUD
- `source/LevelData.hx`, `source/LevelLoader.hx` – a Tiled JSON export feldolgozása (alapértékek, validálás, élárnyékolás); végzetes hibánál `null`, és a pálya procedurális lesz
- `source/PauseSubState.hx`, `source/SettingsSubState.hx`, `source/MenuList.hx` – szünet, beállítások, menülista
- `source/Settings.hx` – hangerők, némítás, nehézség (mentve) és a nehézség szorzói
- `source/HiScore.hx` – csúcspontszám nehézségenként (FlxSave)
- `source/Themes.hx` – pályatémák (`Themes.current`: a PixelArt ég/hold/hegy/talaj generálása ebből színez, kulcsai témánként cache-eltek); a PlayState `applyTheme`-je a pálya indulásakor (beginLevel) váltja: térkép `theme` tulajdonság > pálya sorszáma (`Themes.forLevel`). `source/Backdrop.hx` – égbolt, hold, parallax rétegek és időjárás-részecskék
- `source/Audio.hx`, `source/Music.hx` – szintetizált hangeffektek és háttérzene
- `source/Coin.hx`, `source/Upgrades.hx`, `source/ShopSubState.hx` – érmék (`PlayState.dropCoins`, `Settings.coins`, mentve), tartós fejlesztések (`Settings.upgrades`; hatásuk: `damagePlayer`, `shoot` alap lövedék, `updatePowers` tüzelési idő, `Player.applyUpgrades`), bolt pályavégén (`openShop`) és a címképernyőről A bolt a fegyvereket is árulja (`Upgrades.WEAPONS`, `Settings.ownedWeapons` / `loadout`).
- Pályák bővítése: `Meteorfall` objektum (`SpawnType.METEORFALL`, `PlayState.meteorFall`), procedurális pályán `stormTimer`. A `scripts/export-levels.ps1` a Tiled-et `Start-Process -Wait`-tel indítja (GUI program, különben nem várja meg).
- `source/Characters.hx`, `source/CharacterSelectState.hx` – 3 választható hős (`Settings.character`, mentve; `PixelArt.player(skin)` színváltozat): csak a mozgás különbözik (ugrás, sebesség, súrlódás). START → karakterválasztó → PlayState; `-Dtest` build egyből PlayState. Futásnyom: `Player.onRun` → `PlayState.spawnRunFx`
- `source/Player.hx` – mozgás (coyote time, jump buffer, változó ugrásmagasság), lövés
- `source/Block.hx` – hulló meteor (`PixelArt.meteor`, tűzcsóva `Block.onTrail`): zuhanva halálos, földet érve akadály, aztán eltűnik
- `source/PowerUp.hx` – `PowerKind` enum: fegyver-kiegészítők (SPREAD, RAPID), alapfegyverek (ROCKET, LASER, GRENADE), BONUS, ENERGY és a módosítók (`PowerUp.CURSES`: SHROOM, PIXEL, TORCH, GHOST, TINYVIEW, TINYHERO, MAGNET, a talajon fekvő tárgyak: `PlayState.placeCurse`, időzítés `curseTimers`/`applyCurse`/`updateCurses`, Config: `modifiers.*`)
- `source/Enemy.hx` – ellenségek (`EnemyKind`: SLIME / BAT / TURRET / DRONE) viselkedése; a PlayState spawnolja és kezeli az ütközéseket
- `source/Quests.hx` – pályák (`LEVELS`, opcionális `map`: Tiled-térkép, ami felülírja a nevet, a sebességet és a küldetéseket) és pályánként 3 küldetés. Térképes pályán a főellenség a térkép `Boss` pontjánál jön; procedurális pályán a küldetések teljesítése hívja (`onAllComplete`). `QuestPanel.hx`, `QuestsSubState.hx` a kijelzéshez
- Bevezető folyamat: TitleState (csak a menü) -> `IntroState` (történet, gépírás) -> `HelpSubState(true)` (irányítás-képernyő) -> `CharacterSelectState`. Főellenség-sorrend: `PlayState.BOSS_ORDER` (9-esével ismétlődik; a 9. pálya: HOLLOW, a kiüresedett hold: támadás 15-17, `gravityT`), a 10. pálya (`FINAL_LEVEL`) a végső.
- Végső főellenség (a 10. pálya, `PlayState.FINAL_LEVEL`): óriás slime (`BossKind.FINAL`, `PixelArt.bossSlime`), ami a korábbi főellenségek formáira vált (`Boss.applyForm` cseréli a `kind`-ot, így a mozgás és a támadások a formáé; `startMorph`/`updateMorph`: lila slime-má olvadás, csere, kinyúlás; `onMorph` -> `PlayState.bossMorph`); 25% alatt megőrül (`berserk`). Cheat: `CheatSubState` BOSS oldal (életerő %, zárolás, kényszerített átváltozás), LEVEL oldal (PREVIOUS LEVEL, SKIP TO FINAL BOSS). Új módosító: ASCII (`AsciiShader`), pókcsípés-tipsy (`PlayState.tipsyBites`, `Player.tipsy`), guggolás (`Player.crouching`).
- `source/Boss.hx` – főellenség, `BossKind` (pálya % 8; a talajon járók valódi gravitációval esnek és nem lépnek szakadék fölé: `followGround`, `standable`, `groundedX`; mindig a hős felé fordul: `target`, `flipX`, a torkolatok `spriteX`-szel tükröződnek): BRUTE (4. pálya, `PixelArt.bossBrute`, gömbhajítás = támadás 4 a kezekből) és STALKER (5., `PixelArt.bossStalker`, hármas szemlövés = támadás 5), KILLER (6., `PixelArt.bossKiller`, rárontás + tüskeeső), STRIDER (7., `PixelArt.bossStrider`, tüskék a hős alatt + lassító háló), PUFF (8., `PixelArt.bossPuff`, pattogó pihegolyók + szálló spórák), MOTHERSHIP, TANK (2. pálya, rajz alapján, `PixelArt.bossTank`, a talajon gurul, ágyú + aknavető), GHOST (3. pálya, `PixelArt.bossGhost`, lebeg, szájból lő); sprite-építő: `PixelArt.paintBoss`. Támadások `onAttack`-on át, a PlayState kezeli (`levelState`: PLAYING / BOSS_INTRO / BOSS / CLEAR)
- A HUD külön `hudCam` kamerán van (`PlayState.add` felülírása: minden `FlxText` és a `hudAdding` alatt létrehozott elem a `hudLayer`-re kerül), hogy a shaderek ne hassanak rá; új HUD-elem is így kerüljön be. `source/HallucinationShader.hx`, `PixelateShader.hx`, `TorchShader.hx` – kamera ShaderFilter-ek a módosítókhoz (a `PlayState.refreshFilters` állítja össze az aktív szűrőket)
- Platformok egyirányúak (`allowCollisions = UP` az `addGround`-ban). Főellenség-aréna: `arenaMode` (a generátor sík, szakadékmentes), `fillArenaGaps` (betömi a szakadékokat), `buildArenaPlatforms` (két egyirányú platform ~44 px magasan, hogy át lehessen ugrani a főellenséget); a végső főellenségnek külön zene (`Audio.playFinalMusic` / `restoreMainMusic`, `Music.renderFinal`).
- Continue: `continuesLeft` (3), `die()` → folytatás-ajánlat, `gameOver()` → végleges vége
- `source/Bullet.hx` – lövedék (`BulletKind`: NORMAL / LASER / ROCKET / GRENADE), sebzés, átütés; a rakéta és a gránát az első találatnál robban (`PlayState.detonate` → `blast`: hatósugár `Bullet.radius`)
- Fegyverek: egy alapfegyver (`baseWeapon`: null = pisztoly, ROCKET, LASER, GRENADE; a bolt-felszerelés `Upgrades.loadoutKind()`, végtelen idejű: `baseWeaponTimer = INFINITY`) + egymásra rakódó kiegészítők (`weaponTimers`: SPREAD, RAPID), lásd `PowerUp.BASE_WEAPONS` / `PowerUp.MODS`
- `source/PixelArt.hx` – sprite-ok, talajtextúra, égbolt és parallax hegyek generálása (cache-elve)

## Eszközök
- `.vscode/` – VS Code beállítások, feladatok (build, futtatás, csomagolás, publikálás), ajánlott bővítmények
- `scripts/setup.ps1` – függőségek telepítése (rögzített verziók); `scripts/package-itch.ps1` – itch.io zip a `dist/`-be;
  `scripts/publish-itch.ps1` – feltöltés butlerrel (`itch.config.json`). A .ps1 fájlok UTF-8 BOM-mal mentendők (PowerShell 5.1 miatt).
- Az 1-10. pálya Tiled-térkép (3-10.: `scripts/generate-levels.ps1` generálta kiindulópontnak, utána kézzel szerkesztendő; ne futtasd újra), a 11.-től procedurális.
- Pályák: `levels/` (Tiled projekt és .tmx), `scripts/export-levels.ps1` (Tiled CLI export), `tests/validate-levels.ps1` (statikus ellenőrzés), `tests/levels.ps1` + `tests/cdp-lib.ps1` (fejnélküli Edge teszt `-Dtest` builddel, Node nélkül). Hibakereső URL-paraméterek (`?level=`, `?map=`, `?x=`) csak debug/teszt buildben. Export után újra kell fordítani (a JSON be van ágyazva).
- Hangolás: `assets/config/game.json` (beágyazva) → `source/Config.hx` (alapértékek, tartományok, `Config.load()` a TitleState/PlayState/Settings elején); leírás: `docs/CONFIG.md`. Új hangolható érték: mezőt vegyél fel a `Config`-ba + az `apply()`-ba, és a kulcsot a game.json-ba és a docs/CONFIG.md-be. A PlayState/Player konstansai `static var X(get, never)` tulajdonságok a Config-ra.
- Cheatek csak `#if cheats` alatt (`-debug`, `-Dtest`, `-Dcheats`; Project.xml `haxedef`): `CheatSubState` (F9), `PlayState.cheat*` függvények. Release-ben nem fordulnak ki: új cheat-kódot mindig `#if cheats` közé írj, és ellenőrizd, hogy a release JS nem tartalmazza (`CheatSubState`, `cheatPowerName`).
- Billentyűk: `Controls.hx` (műveletenként két billentyű, mentve; `Controls.held/just(Action)`; a Player, a szünet és a némítás ezt használja), átállítás: `ControlsSubState` (Beállítások > CONTROLS), súgó: `HelpSubState` (címképernyő és szünetmenü HELP). A menük billentyűi fixek. Új beviteli helyen a `Controls`-t használd a hardcode-olt billentyű helyett.
- Kontroller: `Pad.hx` (a Main `Pad.init()`-je minden képkocka elején felméri a gombokat; `Pad.held/just(PadAction)`), a billentyűs ellenőrzések mellé `|| Pad...` kerül. Új beviteli helyen mindkettőt kezeld.
- Lövés: Space folyamatos tűz, az M (`Player.CHARGE_KEYS`) nyomva tartva tölt (`Player.charge` 0..1, `Config.chargeTime`/`chargeMin`), felengedéskor `onShoot(x,y,dx,dy,charge)` töltött lövést kér; a `PlayState.shoot` fegyverenként értelmezi a töltést. A némítás az N billentyű. A varázsgomba nem lőhető (nincs lövedék-ütközés vele).
- Menüben a lapváltást (`MenuList` callbackből) ne építsd újra szinkron: a régi menü update-je még fut (lásd `CheatSubState.pendingPage`).
- A Flixel `countLiving()` üres csoportnál -1-et ad, a `touching` pedig a `super.update()`-ben nullázódik (utána a `wasTouching` az érvényes).
# HaxeFlixel Projekt Szabályok

## Környezet és Verziók
- Nyelv: Haxe 4.3+
- Motor: HaxeFlixel 5.x (OpenFL / Lime)
- Célplatform: HashLink (`hl`) / HTML5

## Parancsok
- Fordítás és futtatás: `lime test hl` (vagy `lime test html5`)
- Csak fordítás ellenőrzéshez: `lime build hl`

## Kódolási konvenciók
- Forráskód helye: `source/` mappa.
- Használj modern HaxeFlixel 5.x API-t (pl. `FlxG.keys.justPressed`, ne elavult 4.x szintaxist).
- Mindig adj meg típusokat a változóknak és függvényeknek.
- Hibajavításnál futtasd a `lime build hl` parancsot a módosítás ellenőrzéséhez.
- Mobil böngésző: `TouchControls.hx` (csak `#if js`): a vászon fölé HTML-gombok (◀ ▶ ▲ ▼, JUMP, FIRE, CHG, szünet), amik a `Pad` gombállapotait kapcsolják (`Pad.poll` → `TouchControls.apply`), így a Player/menük külön kód nélkül használják. Megjelenik: `pointer: coarse` eszközön, az első érintésre, vagy `?touch=1`-gyel; csak a PlayState-ben, nyitott menü nélkül. A menük érintésre egérkattintásként működnek.
- Telefonról / másik gépről: `scripts/serve-lan.ps1` (a lime csomagolt http-server-e 0.0.0.0-n, kiírja a LAN címeket; `-OpenFirewall` rendszergazdaként felvesz egy bejövő TCP szabályt). A `Public` hálózati profilon a Windows tűzfal alapból blokkol. A tesztszerverek (HttpListener, 127.0.0.1) csak helyben érhetők el.
- Telefonról / másik gépről: `scripts/serve-lan.ps1` (a lime csomagolt http-server-e 0.0.0.0-n, kiírja a LAN címeket; `-OpenFirewall` rendszergazdaként felvesz egy bejövő TCP szabályt). A `Public` hálózati profilon a Windows tűzfal alapból blokkol. A tesztszerverek (HttpListener, 127.0.0.1) csak helyben érhetők el.
- Teljesítmény: `Perf.hx`. `?fps=1`: mérőkijelző (FPS, képkocka átlag/legrosszabb, update/draw idő, lassú képkockák, aktív szűrők); `Perf.lite` (érintős eszközön vagy `?lite=1`): fele annyi időjárás-részecske (`Perf.scale`). Forró ciklusokban (`updateBlockSupport`, `updateHoming`) indexes ciklus kell closure helyett (GC), a blokk-támasz csak minden 3. képkockában fut.
- Mobilon a cheat-menü: `TouchControls` CHEAT gombja (jobb felül, csak `#if cheats` buildben, a menü fölött is látszik a bezáráshoz); a menü pontjai koppintással választhatók. Build után mindig ellenőrizd a fordítási hibát (`lime build ... | grep -E "\.hx:[0-9]+"`), mert a hiba csendben a régi JS-t hagyja.
- Élő napló telefonról: `scripts/serve-lan.ps1` a `scripts/devserver.js`-t indítja (a lime csomagolt node-jával, 0.0.0.0, statikus kiszolgálás + `POST /__log`). Az URL-hez `?log=1`-et fűzve a `Perf.hx` másodpercenként elküldi az FPS/update/draw méréseket, az eszköz adatait, a JS-hibákat és az eseményeket (`Perf.log("event", ...)`: meteorzápor, főellenség); a szerver színesen kiírja a terminálba. Új naplóponthoz: `Perf.log(fajta, adat)`. A napló fájlba is íródik: `logs/phone.log` (olvasható) és `logs/phone.jsonl` (nyers); a `logs/` nincs verziókezelve. A szervert újra kell indítani a változás után.
- Globális ranglista (Supabase REST): `Leaderboard.hx` (kliens: `submit` / `fetch`, név és eszköz-azonosító a mentésben), `LeaderboardSubState.hx` (játék végén 3 betűs névbeírás, utána a lista; címképernyőről csak a lista), `Config.leaderboard*` (`game.json` > `leaderboard`: url / key / table; üresen a funkció rejtve). A `PlayState.gameOver` nyitja meg; cheat-buildben nem lehet beküldeni, kivéve a `?lburl=` tesztparaméterrel (a `scripts/devserver.js` mock-ra). Beállítás és SQL: `docs/LEADERBOARD.md`.
- Főellenség-sprite export PNG-be: `scripts/export-bosses.ps1` (teszt-build + `?exportboss=1` -> `BossExport.hx` -> fejnélküli Edge menti) -> `art/bosses/<név>_sheet_1x.png`, `_sheet_x8.png`, `_frameN_x8.png` (8x-os, éles pixelekkel). Új főellenség esetén vedd fel a `BossExport.run` listájába; a futás végén normál buildet hagy az `export\html5\bin`-ben.
- Tiled sprite-előnézet: a pont-objektumok csempe-objektumok (`levels/objects.tsj`, `levels/sprites/`); tábla: `TiledSprites.hx`, export: `TiledExport.hx` (`?exporttiled=1`), előkészítés: `scripts/tiled-previews.ps1` (+ `.js`); a `LevelLoader` a `gid` objektumok horgonypontját számolja vissza (alsó közép / közép / bal alsó). Új objektumtípusnál a TiledSprites-t és a TiledExport.sprite-ot is bővítsd.
