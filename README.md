# Moonshard

Gyors tempójú, oldalnézetes 2D platformer Haxe + HaxeFlixel alapon.
Komor, holdfényes éjszaka: a kamera a hőst követi jobbra, fentről meteorok hullanak, és egyre több
ellenség jön. Teljesítsd a pálya küldetéseit, győzd le a főellenséget, és haladj tovább a következő pályára!

## Irányítás
Alapkiosztás; minden billentyű átállítható a **Beállítások > Controls** menüben, a **Help** a mostani kiosztást mutatja.

| Billentyű | Funkció |
|---|---|
| A D / ← → | futás |
| Space / Z | ugrás (hosszan nyomva magasabb) |
| Le / S | guggolás a földön: kisebb célpont, lassabb mozgás, és a lövés alacsonyan indul (az alacsony tárgyakat is eltalálja) |
| J / X | lövés előre (nyomva tartva folyamatos sorozat) |
| L / C (nyomva tartva) | töltött lövés: tölt, és **felengedéskor** egyetlen nagyobb tűzerejű lövés megy ki (töltésjelző a hősnél) |
| ↑ / W + lövés | lövés felfelé |
| ↑ / W + ← → + lövés | lövés 45 fokban, átlósan előre-fel |
| ↓ / S (a levegőben) + lövés | lövés lefelé; ↓ + ← → + lövés: 45 fokban lefelé |
| P / Esc | szünet (folytatás, beállítások, kilépés) |
| Kontroller (PS4 / Xbox) | bal kar / D-pad: mozgás, menü; Kereszt (A): ugrás, választás; Négyzet (X) / R1: lövés; Kör (B): töltött lövés (menüben: vissza); Options (Start): szünet; R2: cheat-menü (csak fejlesztői buildben) |
| N | hang be/ki |
| F | teljes képernyő |
| F9 | cheat-menü (csak fejlesztői buildben, a release-ben nincs) |
| F10 | egyből a főellenséghez (csak fejlesztői buildben) |
| R / Enter | újrakezdés (a játék vége után) |

## Szabályok

- **Témák**: a pályáknak különböző megjelenésük van (ég, hold/nap, hegyek, talaj, időjárás): NIGHT (vérhold), ASH (hamu, vulkáni ég), ICE (hó, jég), DESERT (homok, alkony), TOXIC (savas zöld, spórák). A Tiled-térkép `theme` tulajdonsága állítja (lásd docs/LEVELS.md); a témák színei a `source/Themes.hx`-ben vannak.
- **Meteoreső** (METEOR FALL!): 2 mp-es, feltűnő figyelmeztetés (felirat, vörös villanás, riasztás), majd 12-20 meteor hullik egyszerre a képernyő szélességében (minden hatodik arany); az 1-2. pályán 3-4 helyen, a procedurális pályákon 22-34 mp-enként. Utána gyakran energiabónusz vár. A pályákon több akadály (rések, falak, lépcsők, platformok), több ellenség és módosító tárgy is van.
- **Főellenségek**: az 1. pálya anyahajó, a 2. harckocsi (**IRON CRAWLER**: ágyúsorozat, ívben dobott bombák, a 2. fázisban meteorok), a 3. kísértetféreg (**PHANTOM WYRM**: agyaras szájából lő, denevéreket köp). A 4. pálya **MUSCLE MAW** (gömbhajítás, ugrás + talajon futó lökéshullám), az 5. **THE WATCHER** (szemlövések, slime-köpés), a 6. **THE KILLER** (rárontás, tüskeeső). a 7. **FUZZ STRIDER** (szőrös pók: a hős alatt feltörő tüskék, lassító háló). a 8. **FLUFF GOLEM** (bolyhos óriás: pattogó pihegolyók, szálló spórák), a 9. **THE HOLLOW MOON** (kiüresedett hold: meteoreső-hívás, szilánk-sorozat, gravitációs örvény). A 10. pálya a végső főellenség: egy óriás slime (**THE FINAL SLIME**), ami a korábbi főellenségekké változik át, 25% életerő alatt megőrül és sűrűn váltogat. Utána (a 11. pálytól) újra elölről. A talajon járók gravitációval esnek, és nem sétálnak szakadék fölé.
- **Érmék és bolt**: a szétlőtt meteorokból és ellenségekből néha érme pattan ki (érintéssel, közelről magától felveszed; a főellenség 12+ érmét ad egyből). Az érmék mentve vannak, és a pálya végén a **bolt** nyílik (a címképernyőn is: SHOP), ikonokkal:
  - fejlesztések: **ARMOR** (-10% sebzés/szint, 5 szint), **PISTOL POWER** (+1 sebzés/szint, 3), **ENERGY** (+15%/szint, 4), **FIRE RATE** (-10% várakozás/szint, 3);
  - fegyverek (egyszeri ár, utána felszerelhető): **ROCKET LAUNCHER**, **LASER**, **GRENADES**. A felszerelt fegyver végtelen ideig tart, és a futás vele indul; az árak az `Upgrades.hx`-ben vannak.
- **Karakter**: a START után három hős közül lehet választani, mozgásuk különbözik (a `source/Characters.hx`-ben állítható):
  - **BLAZE**: kiegyensúlyozott;
  - **ZIP**: nagyon gyors, de csúszik megálláskor (kis súrlódás), kisebbet ugrik;
  - **ROCK**: lassú, magasra ugrik, azonnal megáll (nagy súrlódás).
  Futás közben por száll a lábak mögül, gyors futásnál sebességcsíkok is; fékezéskor (csúszós hősnél hosszan) nagyobb porfelhő jön.
- **Becsapódás-jelző**: minden zuhanó meteor alatt villogó sáv mutatja, hová csapódik be (szakadék fölött nincs jelző). A földet ért meteorok egymáson állnak: ha az alsót kilövöd, a felette levő leesik.
- **Töltött lövés**: az M nyomva tartása tölt (a sorozatlövő gyorsítja), felengedéskor egy nagy lövés: nagyobb, erősebb, átütő lövedék / nagyobb robbanású rakéta és gránát / vastagabb lézer.
- A kamera csak előre követi a hőst (a már elhagyott rész nem jön vissza); a hős a képernyő bal szélén sem futhat ki.
- A hősnek energiája van (100). A zuhanó meteor méret szerint 15 / 30 / 50 energiát sebez, utána rövid
  ideig sérthetetlen. Szakadékba esés 30 energia, és a hős visszakerül a pályára.
  20% alatt a csík piros és figyelmeztető hang szól.
- 0 energiánál **3-szor folytatható** (CONTINUE, 10 mp-es visszaszámlálás): teli energiával, a pontszám,
  a pálya és a küldetések megmaradnak. Utána vége.
- Pont: megtett távolság + extra pont szétlőtt meteoronként (méret szerint 25 / 40 / 60).
  A "+pont" felirat a pontszám-kijelzőhöz repül, és az felvillan. Csúcspontszám nehézségenként.
- Az arany, csillogó jutalommeteorból szétlövéskor bónusz pattan ki; érintéssel veheted fel.

**Fegyverek** – a hős **pisztollyal** indul (egylövetű; a boltban felszerelhető másik fegyver is). A pályán talált fegyverbónusz (12 mp) lecseréli az aktuálisat; lejártakor visszaáll a felszerelt fegyver:

| Fegyver | Hatás |
|---|---|
| PISTOL | alapfegyver, egylövetű; töltve nagy, átütő golyó |
| ROCKET LAUNCHER | rakéta, becsapódáskor közepes hatósugárban robban; lassabban tüzel |
| LASER | nagyon gyors lézerlövedék, ami minden dobozon és ellenségen átmegy |
| GRENADE | ívben repülő gránát, becsapódáskor **nagy hatósugárban** robban |

A robbanás minden meteort, ellenséget és ellenséges lövedéket elpusztít a körben (a hőst nem sebzi), és a főellenséget is sebzi.

**Fegyver-kiegészítők** – egymásra rakódnak (12 mp), és bármelyik fegyverrel működnek:

| Kiegészítő | Hatás |
|---|---|
| RAPID FIRE (sorozatlövő) | gyorsabb tüzelés az aktuális fegyverrel, gyorsabb töltés |
| SPREAD SHOT | 3 lövedék / rakéta / gránát / lézersugár legyezőben |
| HOMING (nyomkövető) | a pisztolylövedék, a rakéta és a gránát a legközelebbi ellenség (vagy főellenség) felé kanyarodik |

**Egyéb bónuszok:** BONUS (+250 pont), ENERGY (+35 energia).

**Módosítók** – időkorlátos, a hőst nehezítő hatások; a talajon fekvő tárgyak (a varázsgomba is ilyen), hozzáérve bekapcsolnak. Nem lehet lelőni őket. Az idők, erősségek és a gyakoriság a `game.json` `modifiers` szakaszában állíthatók:

| Módosító | Hatás |
|---|---|
| MAGIC MUSHROOM (SHROOM) | hallucináció: a kép hullámzik és színt vált |
| PIXELATED (PIXEL) | még nagyobb pixelek (nehezebb látni) |
| FLASHLIGHT (TORCH) | csak a hős és egy kis kör körülötte látszik |
| INVISIBLE (GHOST) | láthatatlan hős |
| TUNNEL (TINYVIEW) | összezsugorított látómező: a hős körüli kis ablak látszik |
| TINY HERO (TINYHERO) | összezsugorított hős |
| MAGNETIC (MAGNET) | a zuhanó és a már leesett meteorok (a földön csúsznak), az ellenséges lövedékek és a repülő ellenségek lassan a hős felé tartanak |

Az aktív bónuszok és módosítók névvel és hátralévő idővel a jobb felső sarokban látszanak. A HUD és a feliratok külön kamerán vannak, ezért a módosítók (pixelesítés, zseblámpa, hallucináció…) shaderei rájuk nem hatnak, mindig jól olvashatók.

## Ellenségek

Az idő múlásával egyre több és többféle ellenség jön (az új fajta érkezését figyelmeztetés jelzi):

| Ellenség | Megjelenik | Viselkedés | Pont |
|---|---|---|---|
| SLIME | 20 mp | a földön ugrálva közeledik; rá lehet ugrani | 50 |
| BAT | 45 mp | hullámvonalban repül, a hős közelében lecsap; rá lehet ugrani | 40 |
| TURRET | 75 mp | álló lövegtorony, a hősre lő | 80 |
| DRONE | 110 mp | a hős fölött lebeg és bombákat dob | 120 |

Ráugrással (stomp) dupla pont jár. Minden fegyver hat rájuk (a robbanások is).

## Pályák, küldetések, főellenség

Minden pályának 3 küldetése van. A kamera a pálya végén lassan megáll, és megérkezik a főellenség
(MOTHERSHIP): meteorokat ejt (minden harmadik arany, bónusszal), legyezőben lő, fél életerő alatt gyorsabb,
és denevéreket hív. Legyőzése után „LEVEL CLEAR”, majd jön a következő, gyorsabb pálya új küldetésekkel:

| Pálya | Típus | Küldetések |
|---|---|---|
| 1 – CRATER FIELDS | Tiled, ~9800 px | 25 meteor, 6 ellenség, 4 bónusz felvétele |
| 2 – ASHEN VALLEY | Tiled, ~12200 px | 40 meteor, 3 ráugrás, 3 arany meteor |
| 3 – BLOOD MOON | Tiled, ~9800 px | 50 meteor, 12 ellenség, 5 arany meteor |
| 4 – FROZEN RIDGE | Tiled, ~10200 px | 55 meteor, 17 ellenség, 4 bónusz |
| 5 – TOXIC MARSH | Tiled, ~10600 px | 70 meteor, 18 ellenség, 3 fegyverbónusz egyszerre |
| 6 – DUNE SEA | Tiled, ~11000 px | 80 meteor, 22 ellenség, 6 ráugrás |
| 7 – GLACIER NIGHT | Tiled, ~11400 px | 85 meteor, 20 ellenség, 5 arany meteor |
| 8 – SPORE HOLLOW | Tiled, ~11800 px | 100 meteor, 24 ellenség, 4 bónusz |
| 9 – LUNAR WASTES | Tiled, ~12200 px | 100 meteor, 26 ellenség, 3 fegyverbónusz egyszerre |
| 10 – THE LAST NIGHT | Tiled, ~12600 px | 110 meteor, 26 ellenség, 8 ráugrás; a végső főellenség |
| 11-től (DEEP NIGHT n) | procedurális | egyre nagyobb célokkal és gyorsabb görgetéssel |

- **Tiled-pályákon** (1–10; a 3–10. kiindulópontját a scripts/generate-levels.ps1 generálta, kézzel szerkeszthető a levels/ mappában) a talaj, a platformok, az ellenségek, a gombák, a bónuszok, a meteorzáporok és a főellenség
  helye kézzel van elhelyezve; a főellenség a pályán kijelölt helyen jön, a küldetések pontot adnak, de nem kapuk.
- **Procedurális pályákon** (3-tól) a terep és a meteorok, ellenségek véletlenszerűen generálódnak, és a főellenség
  a három küldetés teljesítése után jön.

A küldetések a pálya elején, a szünetmenüben és a címképernyő QUESTS menüjében is látszanak.

### Pályák szerkesztése (Tiled)

A pályák a [Tiled](https://www.mapeditor.org) szerkesztőben készülnek: nyisd meg a `levels/blockbuster.tiled-project`
projektet, szerkeszd a `.tmx`-et, exportáld JSON-ba (`assets/levels/`), majd fordítsd újra a játékot.
A teljes leírás (formátum, objektumtípusok, hibakereső paraméterek): [`docs/LEVELS.md`](docs/LEVELS.md).

## Beállítások

A címképernyőről és a szünetmenüből: zene- és effekthangerő, hang be/ki, **automata lövés** (a lövés gombnyomás nélkül folyamatos;
a nyilakkal célzol), nehézség (EASY / NORMAL / HARD, csak a címképernyőn állítható). A beállítások mentve maradnak.

### Gyorsuló játék

Ha a kamera begyorsul, a hős is gyorsabban futhat: a futási sebessége legalább 1,35-szöröse a kamera sebességének
(`player.followRatio`), így lépést lehet tartani.

### Finomhangolás és cheatek

- Az értékek (sebességek, sebzések, időzítések, nehézségi szorzók) az `assets/config/game.json` fájlban hangolhatók, módosítás után
  újra kell fordítani: [`docs/CONFIG.md`](docs/CONFIG.md).
- A fejlesztői (nem release) buildben **F9** a cheat-menü: minden fegyver, kiegészítő, bónusz és nehezítő kipróbálható,
  van GOD MODE, bónuszidő-befagyasztás, és spawn-kikapcsolás. Fejlesztői build: `-Dcheats` (VS Code:
  *Build HTML5 (dev, cheats)*), a `-debug` és a `-Dtest` build is az. A release-ben a cheatek nincsenek benne.

## Hang

Minden hang és a zene kódból szintetizált (`Audio.hx`, `Music.hx`): 8 bites, 22 kHz-es, Amiga-stílusú
hangminták és egy 4 csatornás, tracker-szerű dal. Nincsenek hangfájlok.

## Fejlesztés

Szükséges: Haxe 4.3.6, és haxelibből `lime 8.3.2`, `openfl 9.5.2`, `flixel 6.2.1`
(a verziók a `Project.xml`-ben rögzítve vannak).

Függőségek telepítése egy lépésben:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

### VS Code

A `.vscode` mappa kész projektbeállítást tartalmaz:

- **Bővítmények** (megnyitáskor felajánlja): Haxe (`nadako.vshaxe`) és Lime (`openfl.lime-vscode-extension`).
- **Feladatok** (Terminal → Run Task): *Install dependencies*, *Build HTML5* (Ctrl+Shift+B),
  *Run HTML5 (browser)*, *Build HTML5 (test)*, *Build HashLink*, *Package for itch.io*, *Publish to itch.io*, *Clean*.
- **F5**: a Lime bővítménnyel fordít és futtat (a célt a státuszsorban lehet választani, pl. HTML5).
- A Haxe útvonala (`C:/HaxeToolkit`) a beállításokban és a feladatokban közvetlenül meg van adva,
  így akkor is működik, ha a rendszer PATH-ja hibás.

### Közzététel itch.io-n
**Egy lépésben:** VS Code *Run Task > Release (build + package + publish)* (vagy `scripts/release.ps1`): pályák ellenőrzése, release build, cheat-mentesség ellenőrzése, zip, feltöltés. Feltöltés nélkül: *Release (build + package, no publish)* (`-SkipPublish`).
Az oldal szövegei, beállításai és képei: `docs/ITCH.md`, `docs/itch/`.


- **Kézzel:** *Package for itch.io* feladat (vagy `scripts/package-itch.ps1`) → `dist/moonshard-html5.zip`, ezt kell feltölteni.
- **Automatikusan:** *Publish to itch.io* feladat (`scripts/publish-itch.ps1`) – buildel, majd az itch.io hivatalos
  `butler` eszközével feltölti (csak a változásokat). Egyszeri beállítás:
  1. `itch.config.json`: `"user"` = itch.io felhasználónév, `"game"` = a projekt URL-neve.
  2. Az első futtatáskor a butler letöltődik a `tools/` mappába, és böngészős bejelentkezést kér
     (vagy `BUTLER_API_KEY` környezeti változó).
  3. Az első feltöltés után az itch.io-n a „html5” fájlnál egyszer be kell pipálni:
     *This file will be played in the browser*. A további feltöltések ezt a fájlt frissítik.

Futtatás böngészőben:

```bash
haxelib run lime test html5
```

Natív (HashLink) build:

```bash
haxelib run lime test hl
```

Automatikus füstteszt (Playwright): `haxelib run lime build html5 -Dtest`, majd szolgáld ki az
`export/html5/bin` mappát (pl. `python3 -m http.server 8765`) és `node tests/smoke.js`.
