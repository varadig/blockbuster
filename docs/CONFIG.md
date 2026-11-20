# Finomhangolás: `assets/config/game.json`

A játék hangolható értékei egy JSON fájlban vannak (`assets/config/game.json`). A fájl **be van ágyazva** a játékba,
ezért **módosítás után újra kell fordítani** (VS Code: *Build HTML5*, vagy `haxelib run lime build html5`).

- A `source/Config.hx`-ben vannak az alapértékek: ha a fájl hiányzik, hibás, vagy egy kulcs kimarad, az alapérték él.
  Ezért elég csak azt a kulcsot megtartani, amit módosítani akarsz.
- Minden értéknek van megengedett tartománya. Ha ezen kívül esik, a játék a határra szorítja, és naplózza
  (`trace`, a böngésző konzoljára kerül a `[Config]` előtaggal). Nem szám típusú érték is figyelmeztetést ad, és az alapérték marad.
- A `_readme` és minden ismeretlen kulcs figyelmen kívül marad.
- A nehézségi szintek (`difficulty`) szorzói 3 elemű tömbök: `[easy, normal, hard]`.

## Szakaszok és kulcsok

### `player`
| Kulcs | Alap | Tartomány | Hatás |
|---|---|---|---|
| `runSpeed` | 200 | 40–1500 | A hős alap futási sebessége (px/s) |
| `followRatio` | 1.35 | 1–4 | Nincs hatása (a kamera a hőst követi, nem görget) |
| `jumpSpeed` | 330 | 100–1000 | Az ugrás kezdősebessége (px/s) |
| `gravity` | 900 | 200–4000 | A hős gravitációja (px/s²) |
| `maxEnergy` | 100 | 10–10000 | A legnagyobb energia (a százalékos kijelző ehhez viszonyít) |
| `hurtTime` | 1.3 | 0–10 | Sérülés utáni sérthetetlenség (mp) |
| `shootCooldown` | 0.18 | 0.02–2 | Két lövés közti idő a sima lövedéknél (mp), Space nyomva tartva |
| `chargeTime` | 1.0 | 0.2–10 | A teljes feltöltődés ideje (mp) a `chargeMin` után; a karakter szorzójával, RAPID-dal rövidebb |
| `chargeMin` | 0.18 | 0.05–2 | Ennyi ideig kell nyomva tartani az M-et, hogy a felengedés töltött lövést adjon |

### `scroll` (nincs hatása: a kamera a hőst követi, nem görget)
| Kulcs | Alap | Tartomány | Hatás |
|---|---|---|---|
| `start` | 60 | 0–600 | A kamera kezdő sebessége (px/s) |
| `max` | 170 | 10–1200 | A kamera legnagyobb sebessége (a pálya `speed` szorzójával és a nehézséggel szorozva) |
| `accel` | 1.5 | 0–100 | A gyorsulás (px/s²) |
| `startGrace` | 1.5 | 0–20 | A pálya elején ennyi ideig áll a kamera (mp) |

### `damage`
`meteorSmall` (15), `meteorMedium` (30), `meteorLarge` (50): a zuhanó meteor sebzése a mérete szerint.
A 8 px-es apró darab a `meteorSmall` sebzést adja. `meteorHot` (20): az izzó, már földet ért meteor érintése.
`fall` (30): szakadékba esés vagy lemaradás. `enemyShot` (12), `bomb` (20), `bossContact` (25).
Tartomány mindegyiknél 0–1000. A nehézségi szint `damageMul` szorzója ezekre is hat.

### `powerups`
| Kulcs | Alap | Hatás |
|---|---|---|
| `weaponTime` | 12 | Az időkorlátos fegyverek és kiegészítők ideje (mp) |
| `energyRefill` | 35 | Az ENERGY bónusz gyógyítása |
| `bonusPoints` | 250 | A BONUS bónusz pontja |

### `weapons`
`bulletSpeed` (420), `laserSpeed` (900), `rocketSpeed` (230), `grenadeSpeed` (190): a lövedékek sebessége (px/s).
`rapidCooldown` (0.07): a sorozatlövő (RAPID) lövésköze a pisztolynál. `laserCooldown` (0.24) és `laserCooldownRapid` (0.1): a lézer újratöltése, RAPID nélkül és azzal (mp).
`rocketCooldown` (0.55) és `grenadeCooldown` (0.8): a rakéta és a gránát várakozási ideje; a RAPID ezt `rapidMul` (0.5) szeresére szorítja.
`homingRange` (260) és `homingTurn` (5): a nyomkövető kiegészítő hatótávja (px) és fordulási sebessége (rad/s). `rocketRadius` (30) és `grenadeRadius` (58): a robbanás hatósugara (px); `rocketDamage` (4) és `grenadeDamage` (5): a robbanás sebzése (töltve nő).

### `modifiers` (időkorlátos, a hőst nehezítő hatások)
| Kulcs | Alap | Hatás |
|---|---|---|
| `dropMeteor` / `dropEnemy` / `maxItems` | 5 / 12 / 3 | Módosító tárgy loot: esélye (%) szétlőtt meteorból és legyőzött ellenségből, és legfeljebb hány tárgy lehet egyszerre a pályán |
| `asciiTime` | 12 | ASCII-mód: az idő (mp); a pixelek helyett színhelyes betűk/jelek látszanak (6x8 px-es cellák) |
| `pixelTime` / `pixelBlock` | 12 / 4 | PIXELATED: az idő (mp) és a blokkméret (belső pixel) |
| `torchTime` / `torchRadius` | 12 / 48 | FLASHLIGHT: az idő és a fénykör sugara (px) |
| `ghostTime` / `ghostAlpha` | 8 / 0 | INVISIBLE: az idő és a hős átlátszatlansága (0 = teljesen láthatatlan) |
| `viewTime` | 10 | TUNNEL: az idő |
| `viewMarginX` / `viewMarginY` | 0.2 / 0.2 | TUNNEL: a szélesség / magasság ekkora része takarva oldalanként (0–0.45) |
| `tinyTime` / `tinyScale` | 12 / 0.55 | TINY HERO: az idő és a hős mérete |
| `magnetTime` | 12 | MAGNETIC: az idő |
| `magnetForce` / `magnetSpeed` / `magnetRange` | 110 / 80 / 260 | MAGNETIC: a meteorok oldalirányú gyorsulása (px/s²), legnagyobb oldalsebessége (px/s), és a hatótáv (px) |
| `weights` | `[24,12,12,10,10,10,12,22]` | Melyik módosító mennyire gyakori: SHROOM, PIXEL, TORCH, GHOST, TINYVIEW, TINYHERO, MAGNET, ASCII |

### `shroom` (a módosító tárgyak megjelenése procedurális pályán)
`first` (15): az első tárgy megjelenése (mp), `intervalMin` / `intervalMax` (8 / 14): a tárgyak közti idő,
`tripTime` (7): a varázsgomba hallucinációjának hossza.

### `spawning`
| Kulcs | Alap | Hatás |
|---|---|---|
| `meteorIntervalStart` | 1.3 | Két meteor közti idő a procedurális pályán induláskor (mp) |
| `meteorIntervalMin` | 0.35 | A legkisebb meteorköz |
| `meteorIntervalDecay` | 0.012 | Ennyivel csökken a meteorköz másodpercenként |
| `enemyUnlock` | `[20, 45, 75, 110]` | Procedurális pályán ekkor jelenik meg a SLIME, BAT, TURRET, DRONE (4 elemű tömb, mp) |
| `enemyIntervalStart` / `enemyIntervalMin` | 6 / 2 | Az ellenségek közti idő kezdete és alja |
| `enemyShotSpeed` | 130 | Az ellenséges lövedék sebessége |
| `bombRadius` | 28 | A drónbomba robbanásának sugara (px) |
| `stompBounce` | 260 | A hős visszapattanása ráugrás után |
| `hotMeteorChance` / `hotMeteorTime` | 18 / 4.5 | Az izzó meteor esélye (%), és hogy földet érve meddig forró (mp) |
| `slimeStickTime` / `slimeSlow` | 4 / 0.6 | A ráragadt slime ideje (mp) és a hős sebességének szorzója (több slime szorzódik, 0.3 alá nem megy) |
| `tipsyTime` / `tipsyMax` | 6 / 5 | A pók kicsinyeinek csípése: egy csípés hatása ennyi ideig (mp) tart; minél több csípés van egyszerre (legfeljebb `tipsyMax`), annál erősebb az ingadozás és a képernyő hullámzása |

A Tiled-pályákon az ellenségeket és meteorokat a térkép helyezi el (lásd `docs/LEVELS.md`), az itteni időzítések csak a procedurális pályákra hatnak.

### `game`, `boss`
`game.continues` (3): ennyiszer lehet folytatni, `game.continueTime` (10): a visszaszámlálás (mp).
`boss.baseHp` (110) és `boss.hpPerLevel` (95): a főellenség életereje `baseHp + pályaszám × hpPerLevel` (a pályaszám 0-tól indul). Pályánként a támadássorozat is gyorsul (7%-kal, legfeljebb 45%-kal).

### `difficulty` (mindegyik `[easy, normal, hard]`)
| Kulcs | Alap | Hatás |
|---|---|---|
| `scrollMul` | `[0.85, 1, 1.18]` | A görgetési sebesség szorzója |
| `spawnIntervalMul` | `[1.35, 1, 0.75]` | A meteorok és ellenségek közti idő szorzója (nagyobb = ritkább) |
| `damageMul` | `[0.6, 1, 1.4]` | A sebzés szorzója |
| `rewardChance` | `[16, 12, 9]` | Az arany jutalommeteor esélye (%) a procedurális pályán |
| `gapMul` | `[0.7, 1, 1.25]` | A szakadékok gyakorisága a procedurális pályán |

## Beállítások és konfiguráció

A **Settings** menüben állítható dolgok (zene- és effekthangerő, hang, **automata lövés**, nehézség) a játékos saját beállításai, a böngészőben
mentődnek (localStorage). A konfigurációs fájl ettől független: a játék működésének hangolására való, és minden játékosra ugyanaz.

## Cheatek és kipróbálás

A fejlesztői (nem release) buildben **F9** a cheat-menü: minden fegyver, kiegészítő és bónusz, a nehezítők (gomba, hallucináció, meteorok,
ellenségek), pályaműveletek és kapcsolók (GOD MODE, a bónuszidők befagyasztása és spawnolás kikapcsolása).
Fejlesztői build: `haxelib run lime build html5 -Dcheats` (VS Code: *Build HTML5 (dev, cheats)*), de a `-debug` és a `-Dtest` build is az.
A **release buildben a cheat-menü nincs benne** (nem csak rejtett: a kód ki sem fordul).
