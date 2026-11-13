# Blockbuster

Gyors tempójú, oldalnézetes 2D platformer Haxe + HaxeFlixel alapon.
A képernyő folyamatosan görget jobbra (egyre gyorsabban), fentről blokkok potyognak:
kerüld ki vagy lődd szét őket, és ne maradj le!

## Irányítás

| Billentyű | Funkció |
|---|---|
| ← → / A D | futás |
| Space / Z / K | ugrás (hosszan nyomva magasabb) |
| X / J | lövés előre |
| ↑ / W + lövés | lövés felfelé |
| R / Enter | újrakezdés |

## Szabályok

- Zuhanó blokk a fejedre = vége. A földet ért blokk akadály lesz, pár másodperc múlva eltűnik.
- Ha a kamera lehagy (kiesel a bal szélen) vagy szakadékba esel = vége.
- Pont: megtett távolság + 25 pont szétlőtt blokkonként.

## Fejlesztés

Szükséges: Haxe 4.3.x, és haxelibből `lime 8.3.2`, `openfl 9.5.2`, `flixel 6.2.1`.

```bash
haxelib install lime 8.3.2
haxelib install openfl 9.5.2
haxelib install flixel 6.2.1
```

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
