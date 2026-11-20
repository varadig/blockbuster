# Pályák szerkesztése Tiled-ben

A pályák a [Tiled](https://www.mapeditor.org) térképszerkesztőben készülnek. A játék a Tiled **JSON exportját**
olvassa be; a grafikát (talaj, ellenségek, meteorok) továbbra is a játék rajzolja kódból, a Tiled-ben csak
**objektumok** (téglalapok és pontok) vannak, csempekészlet nincs.

Az 1-10. pálya mind Tiled-térkép (a 3-10. kiindulópontját a `scripts/generate-levels.ps1` generálta, ezeket szabadon szerkesztheted; a generátort újrafuttatni nem érdemes, felülírná a kézi munkát). A 11. pályától ("DEEP NIGHT n") a játék a régi módon,
procedurálisan generálja.

## Munkafolyamat

1. Telepítsd a Tiled-et (1.10 vagy újabb ajánlott; az egyedi osztályokhoz legalább 1.9 kell).
2. Nyisd meg a `levels/blockbuster.tiled-project` projektet (File → Open File or Project). Ebben vannak az
   egyedi típusok, ezért az objektumok `kind`, `reward` stb. mezői legördülő listaként jelennek meg.
3. Nyisd meg a pályát (`levels/01_crater_fields.tmx`) vagy készíts újat (lásd lent), és szerkeszd.
4. Exportálás JSON-ba az `assets/levels/` mappába:
   - a meglévő térképeknél a **File → Export** (Ctrl+E) a megadott helyre ment (a `.tmx`-ben be van állítva
     a `../assets/levels/<név>.json` cél);
   - új térképnél egyszer: **File → Export As…**, formátum: *JSON map files*, mentés az `assets/levels/` mappába;
   - parancssorból: `scripts/export-levels.ps1` (VS Code: *Export Tiled levels*), ez a Tiled
     `--export-map` parancsát használja, majd lefuttatja az ellenőrzést.
5. **Fordítsd újra a játékot**, mert a JSON be van ágyazva (`lime build html5`, VS Code: *Build HTML5*).
   Gyors próbához használd a lent leírt hibakereső paramétereket.
6. Új pályánál vedd fel a `source/Quests.hx` `LEVELS` listájába a `map: "assets/levels/<fájl>.json"` mezőt.

Mentés előtt/után érdemes lefuttatni az ellenőrzőt: `powershell -ExecutionPolicy Bypass -File tests/validate-levels.ps1`.

## Új pálya készítése

1. File → New → New Map: *Orthogonal*, *Tile layer format* mindegy, *Fixed* méret, csempe **8 × 8 px**,
   magasság **34** sor, szélesség a pálya hossza csempében (pl. 1200 = 9600 px).
   (A térképen csemperéteg nem kell, csak objektumrétegek.)
2. Hozz létre négy objektumréteget: `ground`, `platforms`, `spawns`, `triggers`.
3. Rajzolj **téglalapokat** (Insert Rectangle, R) a `ground` és `platforms` rétegre, és **pontokat**
   (Insert Point, I) a `spawns` és `triggers` rétegre; az objektum **Class** mezőjében add meg a típust (lásd lent).
4. A hosszt a hős tempójához mérd: a kamera a hőst követi (futási sebesség ~200 px/s), a `speed` szorzónak nincs hatása;
   9600 px kb. 50-80 másodperc futás.
5. Állítsd be a térkép tulajdonságait (Map → Map Properties) és az exportcélt (lásd Munkafolyamat).

Tippek: kapcsold be a rács illesztését (View → Snap to Grid), és az 1 px-nél kisebb eltéréseket kerüld;
a játék minden értéket egész pixelre kerekít.

## A formátum

### Koordináták

Pixelben, bal-felső origóval, a világkoordinátával megegyezően. A függőleges méret 270 px
(a játék belső felbontása 480 × 270). A talajszint a mintapályákon y = 232 körül van; a hős kb. 60 px magasra ugrik,
és kb. 146 px távolságra, így a rések legfeljebb ~100 px-esek legyenek, a lépcsők legfeljebb ~48 px-esek.

### Térkép-tulajdonságok

| Név | Típus | Jelentés |
|---|---|---|
| `name` | string | A pálya neve (a feliratokon és a küldetéspanelen) |
| `speed` | float | Görgetési szorzó (alap: a `LEVELS` bejegyzés értéke) |
| `quest1Type`, `quest1Target` … `quest3Type`, `quest3Target` | string, int | Opcionális: felülírja az adott küldetést. Típusok: `meteors`, `gold`, `enemies`, `stomps`, `powerups`, `score`, `survive`, `stack` |
| `bossLevel` | int | A főellenség erőssége (alap: a pálya sorszáma, 0-tól) |
| `theme` | string | A pálya témája: `NIGHT`, `ASH`, `ICE`, `DESERT`, `TOXIC` (a Tiled projektben legördülő lista). Az ég, a hold/nap, a hegyek, a talaj színét és az időjárás-részecskéket (hó, hamu, spórák, homok) adja. Nélküle a pálya sorszáma szerinti alap: 1. NIGHT, 2. ASH, 3. NIGHT, aztán ICE → TOXIC → DESERT körbe |

### Rétegek és osztályok

Minden réteg objektumréteg (csoportrétegek is használhatók; a rejtett rétegeket és a rejtett objektumokat a játék kihagyja).
Az objektum **Class** mezője számít; ha üres, a réteg neve dönt (`ground` → Ground, `platforms` → Platform).

| Class | Alak | Tulajdonságok (alapérték) | Leírás |
|---|---|---|---|
| `Ground` | téglalap | – | A `y` a talaj felszíne, a magasság nem számít: a talaj a képernyő aljáig rajzolódik. A talajok ne fedjék át egymást; a közöttük lévő üres rész a rés. A szélek sötétítését (rés, lépcső) a játék számolja |
| `Platform` | téglalap | – | Lebegő platform, `y` a teteje, a magasság legalább 8 px. **Egyirányú**: alulról és oldalról átjárható (fel lehet ugrani rá), csak felülről tart |
| `Player` | pont | – | A hős kezdőpontja (a **talppont**); legyen alatta talaj |
| `Enemy` | pont | `kind` (SLIME, BAT, TURRET, DRONE; kötelező), `count` (1), `spacing` (24), `lead` (496), `minDifficulty` (0) | `count` darab egymástól `spacing` px-re. A TURRET a talaj tetejére igazodik. Az első előfordulásnál a játék figyelmeztetést mutat |
| `Pickup` | pont | `kind` (PowerKind; kötelező), `floating` (true), `lead` (496), `minDifficulty` | Kézzel elhelyezett bónusz, nem jár le |
| `Shroom` | pont | `lead` (496), `minDifficulty` | Varázsgomba a talajon (a talaj tetejére igazodik) |
| `Meteor` | pont | `reward` (NONE), `speed` (100), `lead` (384), `minDifficulty` | Egyetlen meteor a pont fölött; `reward`-dal arany |
| `Shower` | téglalap | `rate` (1; meteor/mp), `goldEvery` (0; minden n-edik arany, 0 = egy sem), `reward` (RANDOM), `fallMin` (60), `fallMax` (140), `minDifficulty` | Meteorzápor, amíg a képernyő átfedi a téglalapot; a nehézségi szint skálázza a gyakoriságot |
| `Meteorfall` | pont | `count` (14), `span` (520), `goldEvery` (0), `reward` (RANDOM), `fallMin` (70), `fallMax` (150), `lead` (560), `minDifficulty` | **Meteoreső**: a kamera `x − lead`-nél eléri a pontot, "METEOR FALL!" figyelmeztetés, 1,3 mp múlva `count` meteor hullik egyszerre a képernyő szélességében (`span` px-en szétosztva, kis késleltetéssel). A nehézség a darabszámot skálázza. A becsapódás-jelzők mutatják, hova esnek |
| `Boss` | pont | – | A főellenség-aréna **bal széle**: a kamera `x − 160`-nál lefékez, és `x`-nél megáll; ott jön a főellenség. Az aréna talaja legyen összefüggő `x − 160` … `x + 480` között |
| `End` | pont | – | Főellenség nélküli pálya vége: ha a képernyő jobb széle eléri az `x`-et, a pálya véget ér. Csak akkor használd, ha nincs `Boss` |

- **Enumok:** `PowerKind` (Pickup): SPREAD, RAPID, HOMING, ROCKET, LASER, GRENADE, BONUS, ENERGY. A `Shroom` pont opcionális `kind` tulajdonsága egy módosító: SHROOM, PIXEL, TORCH, GHOST, TINYVIEW, TINYHERO, MAGNET (nélküle véletlen).
  `reward`: NONE, RANDOM vagy egy PowerKind.
- A `Enemy`, `Pickup`, `Shroom`, `Meteor` pontjának `(x, y)` a **talppont-közepe** (a hős kezdőpontja is).
  A `lead` megadja, hogy az objektum a kamera bal szélétől `x − lead`-nél jelenik meg
  (alapból épp a képernyő jobb szélén kívül).
- A `minDifficulty` (0 = EASY, 1 = NORMAL, 2 = HARD): az ennél könnyebb szinten az objektum nem jelenik meg,
  így nehezebb szinten extra ellenségeket lehet elhelyezni.
- Hiányzó tulajdonságokat a játék az alapértékkel pótolja (a Tiled az alapértéket nem mindig exportálja).
- A pálya végét a `Boss` (vagy `End`) határozza meg. A küldetések látszanak és pontot adnak, de a főellenséget
  nem ők hívják (procedurális pályán igen).

### Hibakezelés

- **Végzetes hiba** (rossz JSON, nem orthogonal vagy infinite térkép, nincs talaj, nincs `Boss`/`End`, nincs talaj
  a kezdőpont alatt, átfedő talaj): a játék naplózza (`trace`), és az adott pályát procedurálisan generálja.
- **Kisebb hiba** (ismeretlen osztály vagy enumérték, hiányzó `kind`, nem támogatott alak): az adott objektum
  kimarad, és a `LevelData.warnings`-ba kerül.
- Teszt- és debug buildben a figyelmeztetések a böngésző konzoljára is kiíródnak, többek között ha a főellenség-aréna talaja nem összefüggő,
  vagy ha egy küldetés célja a pályán elhelyezett tartalomból nem érhető el (becslés).

## Hibakereső paraméterek

Csak debug és `-Dtest` buildben (a normál buildben nincsenek benne), az URL-ben:

| Paraméter | Hatás |
|---|---|
| `?level=1` | Az adott (0-tól számolt) pályával indul |
| `?map=assets/levels/uj.json` | Az induló pálya térképe helyett ezt tölti be (csak beágyazott asset) |
| `?x=4000` | A kamerát és a hőst az adott x pozícióra ugrasztja (az előtte levő spawnokat átugorja) |

Példa: `http://127.0.0.1:3000/?level=0&x=8800` a főellenség közelében indul.

## Tesztek

- `tests/validate-levels.ps1`: statikus ellenőrzés a `assets/levels/*.json`-on (böngésző nélkül).
- `tests/levels.ps1`: fejnélküli Edge-ben futó végigpróbálás (betöltés, talaj-streaming, spawnok, zápor, főellenség,
  pályaváltás, procedurális tartalék, hibás térképek). Teszt-buildet kér: `haxelib run lime build html5 -Dtest`.

## Sprite-előnézet a Tiled-ben

A pálya-objektumok (Player, Enemy, Pickup, Shroom, Meteor, Meteorfall, Boss, End) a Tiled-ben a játék saját sprite-jaival látszanak: **csempe-objektumok** a `levels/objects.tsj` csempekészletből
(`levels/sprites/*.png`, a játék `PixelArt` rajzaiból). A Ground, Platform és Shower továbbra is téglalap (színes kitöltéssel).

- Új objektum: húzd be a csempét az `objects` csempekészletből (Insert Tile, T); a Class és az alap `kind` vele jön. A `kind` / `reward` tulajdonság átírása **nem cseréli** a sprite-ot: másik fajtához másik csempét válassz.
- A csempe-objektum helye a Tiled-ben a sprite bal alsó sarka; a játék a horgonypontot számolja vissza (talppont: alsó közép; bónusz / meteor: közép; Boss / End: bal alsó) – az objektumot ne méretezd át.
- Előkészítés / frissítés: `scripts/tiled-previews.ps1` (VS Code: *Tiled sprite previews*): kiexportálja a sprite-okat, a pont-objektumokat csempékre cseréli a .tmx-ekben (idempotens; az eredeti .tmx-ek mentve: `levels/.backup-previews`), újraexportálja a JSON-t. Kód: `TiledSprites.hx` (táblázat), `TiledExport.hx` (`?exporttiled=1`), a betöltő: `LevelLoader` (`gid` kezelés).
- A `scripts/generate-levels.ps1` pontokat ír: futtatása után (nem ajánlott) futtasd újra a `tiled-previews.ps1`-et.
