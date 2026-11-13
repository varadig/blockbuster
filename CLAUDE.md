# Blockbuster – projekt jegyzetek

- Nyelv/engine: Haxe 4.3.6, HaxeFlixel 6.2.1 (lime 8.3.2, openfl 9.5.2). Csak ezekre a verziókra írj kódot.
- Build: `haxelib run lime build html5` (teszthez `-Dtest`, ez a `window.__game`-be teszi a PlayState-et).
- Füstteszt: `export/html5/bin` kiszolgálása a 8765-ös porton, majd `node tests/smoke.js`.
- Belső felbontás 480x270 (Main.hx), az ablak 960x540.
- Grafika egyelőre kódból generált (makeGraphic), nincsenek asset fájlok.
- Ne használd a deprecated `FlxObject.health`-et; a blokkoknak saját `hp` mezőjük van.
- Kommentek és UI szövegek magyarul.

## Felépítés
- `source/Main.hx` – FlxGame indítása
- `source/PlayState.hx` – auto-scroll kamera, procedurális talaj, blokk-spawner, lövedékek, pontozás
- `source/Player.hx` – mozgás (coyote time, jump buffer, változó ugrásmagasság), lövés
- `source/Block.hx` – potyogó blokk: zuhanva halálos, földet érve akadály, aztán eltűnik
