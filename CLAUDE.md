# Blockbuster – projekt jegyzetek

- Nyelv/engine: Haxe 4.3.6, HaxeFlixel 6.2.1 (lime 8.3.2, openfl 9.5.2). Csak ezekre a verziókra írj kódot.
- Build: `haxelib run lime build html5` (teszthez `-Dtest`: egyből a PlayState indul, `window.__game`-ben elérhető, és fókusz nélkül sem áll meg).
- Füstteszt: `export/html5/bin` kiszolgálása a 8765-ös porton, majd `node tests/smoke.js`.
- Belső felbontás 480x270 (Main.hx), az ablak 960x540.
- Grafika kódból generált pixel art (`PixelArt.hx`, Sweetie 16 alapú paletta), nincsenek asset fájlok.
- Megjelenítés: böngészőben a vászon kitölti az ablakot (Project.xml: html5 width/height = 0), `RatioScaleMode` arányos nagyítás 16:9-ben, `camera.pixelPerfectRender` + antialiasing nélkül.
- Hang is kódból generált (`Audio.hx` szintetizátor + 8 bites WAV, `Music.hx` tracker-dal), nincsenek hangfájlok.
- Ne használd a deprecated `FlxObject.health`-et; a blokkoknak saját `hp`, a játékosnak `energy` mezője van.
- A `FlxG.worldBounds`-ot görgetéskor a kamerával együtt kell mozgatni, különben a távoli objektumok nem ütköznek.
- A `PowerKind` és a `BulletKind` neveiben van átfedés (FLAME, LASER): a PlayState-ben `BulletKind.X` alakban hivatkozz.
- Kommentek magyarul, a játék UI szövegei angolul.

## Felépítés
- `source/Main.hx` – FlxGame indítása (TitleState; `-Dtest` esetén PlayState)
- `source/TitleState.hx` – nyitóképernyő: ládás logó, menü (START / SETTINGS), csúcspontszám
- `source/PlayState.hx` – auto-scroll kamera, procedurális talaj, blokk-spawner, fegyverek, bónuszok, energia, HUD
- `source/PauseSubState.hx`, `source/SettingsSubState.hx`, `source/MenuList.hx` – szünet, beállítások, menülista
- `source/Settings.hx` – hangerők, némítás, nehézség (mentve) és a nehézség szorzói
- `source/HiScore.hx` – csúcspontszám nehézségenként (FlxSave)
- `source/Backdrop.hx` – égbolt, hold és parallax rétegek
- `source/Audio.hx`, `source/Music.hx` – szintetizált hangeffektek és háttérzene
- `source/Player.hx` – mozgás (coyote time, jump buffer, változó ugrásmagasság), lövés
- `source/Block.hx` – hulló meteor (`PixelArt.meteor`, tűzcsóva `Block.onTrail`): zuhanva halálos, földet érve akadály, aztán eltűnik
- `source/PowerUp.hx` – `PowerKind` enum és a jutalomdobozból kieső, felvehető bónusz
- `source/Enemy.hx` – ellenségek (`EnemyKind`: SLIME / BAT / TURRET / DRONE) viselkedése; a PlayState spawnolja és kezeli az ütközéseket
- `source/Quests.hx` – pályák (`LEVELS`) és pályánként 3 küldetés; ha mind kész, `onAllComplete` → főellenség. `QuestPanel.hx`, `QuestsSubState.hx` a kijelzéshez
- `source/Boss.hx` – főellenség (anyahajó): támadások `onAttack`-on át, a PlayState kezeli (`levelState`: PLAYING / BOSS_INTRO / BOSS / CLEAR)
- `source/HallucinationShader.hx` – varázsgomba-hatás (kamera ShaderFilter: hullámzás, színeltolás)
- Continue: `continuesLeft` (3), `die()` → folytatás-ajánlat, `gameOver()` → végleges vége
- `source/Bullet.hx` – lövedék (`BulletKind`: NORMAL / FLAME / LASER), sebzés, élettartam, átütés; a DEATH RAY nem lövedék, hanem azonnali sugár (`PlayState.fireDeathRay`)
- Fegyverek: egy alapfegyver (`baseWeapon`: null = BULLET, FLAME, LASER, DEATHRAY) + egymásra rakódó kiegészítők (`weaponTimers`: SPREAD, RAPID, HEAVY), lásd `PowerUp.BASE_WEAPONS` / `PowerUp.MODS`
- `source/PixelArt.hx` – sprite-ok, talajtextúra, égbolt és parallax hegyek generálása (cache-elve)

## Eszközök
- `.vscode/` – VS Code beállítások, feladatok (build, futtatás, csomagolás, publikálás), ajánlott bővítmények
- `scripts/setup.ps1` – függőségek telepítése (rögzített verziók); `scripts/package-itch.ps1` – itch.io zip a `dist/`-be;
  `scripts/publish-itch.ps1` – feltöltés butlerrel (`itch.config.json`). A .ps1 fájlok UTF-8 BOM-mal mentendők (PowerShell 5.1 miatt).
