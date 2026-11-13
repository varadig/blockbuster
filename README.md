# Blockbuster

Gyors tempójú, oldalnézetes 2D platformer Haxe + HaxeFlixel alapon.
Komor, holdfényes éjszaka: a képernyő folyamatosan görget jobbra, fentről meteorok hullanak, és egyre több
ellenség jön. Teljesítsd a pálya küldetéseit, győzd le a főellenséget, és haladj tovább a következő pályára!

## Irányítás

| Billentyű | Funkció |
|---|---|
| ← → / A D | futás |
| Alt / Z / K | ugrás (hosszan nyomva magasabb) |
| Space / X / J | lövés előre |
| ↑ / W + lövés | lövés felfelé |
| ↑ / W + ← → + lövés | lövés 45 fokban, átlósan előre-fel |
| P / Esc | szünet (folytatás, beállítások, kilépés) |
| M | hang be/ki |
| F | teljes képernyő |
| R / Enter | újrakezdés (a játék vége után) |

## Szabályok

- A hősnek energiája van (100). A zuhanó meteor méret szerint 15 / 30 / 50 energiát sebez, utána rövid
  ideig sérthetetlen. Szakadékba esés vagy lemaradás 30 energia, és a hős visszakerül a pályára.
  20% alatt a csík piros és figyelmeztető hang szól.
- 0 energiánál **3-szor folytatható** (CONTINUE, 10 mp-es visszaszámlálás): teli energiával, a pontszám,
  a pálya és a küldetések megmaradnak. Utána vége.
- A földet ért meteor akadály lesz, pár másodperc múlva eltűnik.
- Pont: megtett távolság + extra pont szétlőtt meteoronként (méret szerint 25 / 40 / 60).
  A "+pont" felirat a pontszám-kijelzőhöz repül, és az felvillan. Csúcspontszám nehézségenként.
- **Varázsgomba** (lila, a talajon): hozzáérve 7 mp hallucináció – a kép hullámzik és színt vált.
  Lelőhető, át lehet ugrani.
- Az arany, csillogó jutalommeteorból szétlövéskor bónusz pattan ki; érintéssel veheted fel:

**Fegyverek** – egyszerre egy alapfegyver lehet; az új lecseréli a régit, lejártakor (12 mp) visszaáll a sima lövedék:

| Fegyver | Hatás |
|---|---|
| BULLET | alapfegyver, nincs saját bónusza |
| FLAMETHROWER | rövid hatótávú, folyamatos lángcsóva |
| LASER | nagyon gyors lézerlövedék, ami minden dobozon és ellenségen átmegy |
| DEATH RAY | ritka; azonnali, hosszú sugár – amin áthalad, az egy lövésre elpusztul |

**Kiegészítők** – egymásra rakódnak (12 mp), és bármelyik fegyverrel működnek, fegyverenként másképp:

| Kiegészítő | BULLET | FLAMETHROWER | LASER / DEATH RAY |
|---|---|---|---|
| RAPID FIRE | gyorsabb tüzelés | messzebbre ér | gyorsabb tüzelés |
| SPREAD SHOT | 3 lövedék legyezőben | szélesebb csóva | 3 sugár |
| HEAVY ROUNDS | nagyobb, átütő lövedék | nagyobb, erősebb láng | nagyobb sebzés / vastagabb sugár |

**Egyéb bónuszok:**

| Bónusz | Hatás |
|---|---|
| INVINCIBLE | sérthetetlenség 7 mp-ig, saját zenével; a ráeső meteor szétrobban. Lejárta előtt 2 mp-cel gyorsuló ketyegés, és a HUD-sávja villog |
| SLOW MOTION | a környezet lelassul (a hős és a lövései nem) 5 mp-ig, fokozatos be- és kiúszással |
| NUKE | ritka; minden meteor és ellenség elpusztul a képernyőn, a főellenség életerejének 20%-át viszi |
| BONUS | +250 pont |
| ENERGY | +35 energia |

Az aktív bónuszok névvel és hátralévő idővel a jobb felső sarokban látszanak.

## Ellenségek

Az idő múlásával egyre több és többféle ellenség jön (az új fajta érkezését figyelmeztetés jelzi):

| Ellenség | Megjelenik | Viselkedés | Pont |
|---|---|---|---|
| SLIME | 20 mp | a földön ugrálva közeledik; rá lehet ugrani | 50 |
| BAT | 45 mp | hullámvonalban repül, a hős közelében lecsap; rá lehet ugrani | 40 |
| TURRET | 75 mp | álló lövegtorony, a hősre lő | 80 |
| DRONE | 110 mp | a hős fölött lebeg és bombákat dob | 120 |

Ráugrással (stomp) dupla pont jár. Minden fegyver hat rájuk.

## Pályák, küldetések, főellenség

Minden pályának 3 küldetése van. Ha mind teljesül, a kamera lassan megáll, és megérkezik a főellenség
(MOTHERSHIP): meteorokat ejt (minden harmadik arany, bónusszal), legyezőben lő, fél életerő alatt gyorsabb,
és denevéreket hív. Legyőzése után „LEVEL CLEAR”, majd jön a következő, gyorsabb pálya új küldetésekkel:

| Pálya | Küldetések |
|---|---|
| 1 – CRATER FIELDS | 25 meteor, 6 ellenség, 4 bónusz felvétele |
| 2 – ASHEN VALLEY | 40 meteor, 3 ráugrás, 3 arany meteor |
| 3 – BLOOD MOON | 20 ellenség, 60 meteor, 3 fegyverbónusz egyszerre |
| 4-től | a 3. pálya egyre nagyobb célokkal és gyorsabb görgetéssel |

A küldetések a pálya elején, a szünetmenüben és a címképernyő QUESTS menüjében is látszanak.

## Beállítások

A címképernyőről és a szünetmenüből: zene- és effekthangerő, hang be/ki, nehézség (EASY / NORMAL / HARD,
csak a címképernyőn állítható). A beállítások mentve maradnak.

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

- **Kézzel:** *Package for itch.io* feladat (vagy `scripts/package-itch.ps1`) → `dist/blockbuster-html5.zip`, ezt kell feltölteni.
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
