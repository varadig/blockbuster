# Moonshard

**English** · [Magyar](README.hu.md)

A fast-paced, side-scrolling 2D platformer built with Haxe and HaxeFlixel.
A gloomy, moonlit night: the camera follows the hero to the right, meteors rain from above, and more and more enemies arrive. Complete the level missions, defeat the boss, and move on to the next level.

## Controls

Default layout. Every key can be rebound in **Settings > Controls**, and **Help** shows the current layout.

| Key | Action |
|---|---|
| A D / ← → | run |
| Space / Z | jump (hold for a higher jump) |
| Down / S | crouch on the ground: smaller target, slower movement, and shots start low (hits low objects too) |
| J / X | shoot forward (hold for continuous fire) |
| L / C (hold) | charged shot: charges, and **on release** fires one larger, stronger shot (charge indicator on the hero) |
| Up / W + shoot | shoot upward |
| Up / W + ← → + shoot | shoot diagonally up-forward at 45° |
| Down / S (in the air) + shoot | shoot downward; Down + ← → + shoot: 45° downward |
| P / Esc | pause (resume, settings, quit) |
| Gamepad (PS4 / Xbox) | left stick / D-pad: move and menus; Cross (A): jump and select; Square (X) / R1: shoot; Circle (B): charged shot (in menus: back); Options (Start): pause; R2: cheat menu (development builds only) |
| N | sound on/off |
| F | fullscreen |
| F9 | cheat menu (development builds only, not in release) |
| F10 | jump straight to the boss (development builds only) |
| R / Enter | restart (after game over) |

## Rules

- **Themes:** levels have different looks (sky, moon/sun, mountains, ground, weather): NIGHT (blood moon), ASH (ash, volcanic sky), ICE (snow, ice), DESERT (sand, dusk), TOXIC (acid green, spores). The Tiled map's `theme` property sets it (see docs/LEVELS.md). The theme colors are in `source/Themes.hx`.
- **Meteor storm** (METEOR FALL!): a 2-second, very visible warning (caption, red flash, alarm), then 12–20 meteors fall at once across the screen width (every sixth one is gold). Levels 1–2 have it at 3–4 spots, procedural levels every 22–34 s. Often an energy bonus follows. Levels have obstacles (gaps, walls, steps, platforms), more enemies, and modifier items.
- **Bosses:** level 1 is a mothership, level 2 a tank (**IRON CRAWLER**: cannon bursts, arcing bombs, meteors in phase 2), level 3 a ghost worm (**PHANTOM WYRM**: shoots from its fanged mouth, spits bats). Level 4 **MUSCLE MAW** (throws balls, jump + ground shockwave), level 5 **THE WATCHER** (eye beams, slime spit), level 6 **THE KILLER** (charges, spike drops), level 7 **FUZZ STRIDER** (hairy spider: spikes erupt under the hero, slowing webs), level 8 **FLUFF GOLEM** (fluffy giant: bouncing fuzz balls, floating spores), level 9 **THE HOLLOW MOON** (emptied moon: calls meteor storms, shard bursts, gravity vortex). Level 10 is the final boss, **THE FINAL SLIME**: a giant slime that turns into the earlier bosses; below 25% health it goes berserk and switches forms often. After that (from level 11) the cycle restarts. Ground-walking bosses fall with gravity and do not step over pits.
- **Coins and shop:** shot-down meteors and enemies sometimes drop coins (touch them; nearby ones are collected automatically). The boss drops 12+ coins at once. Coins are saved, and at the end of a level the **shop** opens (also from the title screen: SHOP):
  - upgrades: **ARMOR** (-10% damage per level, 5 levels), **PISTOL POWER** (+1 damage per level, 3), **ENERGY** (+15% per level, 4), **FIRE RATE** (-10% delay per level, 3);
  - weapons (one-time price, then equippable): **ROCKET LAUNCHER**, **LASER**, **GRENADES**. An equipped weapon lasts forever, and runs start with it. Prices are in `Upgrades.hx`.
- **Characters:** after START you choose one of three heroes, each with different movement (set in `source/Characters.hx`):
  - **BLAZE**: balanced;
  - **ZIP**: very fast, but slides when stopping (low friction), jumps a bit lower;
  - **ROCK**: slow, jumps high, stops instantly (high friction).
  Dust trails behind running feet, with speed lines at high speed. Braking kicks up a bigger dust cloud (longer for the sliding hero).
- **Impact markers:** every falling meteor shows a flashing strip where it will land (none over pits). Meteors that have landed stack on each other: if you shoot the bottom one, the one above falls.
- **Charged shot:** holding M charges (rapid fire speeds this up). On release you get one big shot: a larger, stronger, piercing projectile, a bigger-blast rocket or grenade, or a thicker laser.
- The camera only follows the hero forward (already passed areas do not come back). The hero cannot run off the left edge of the screen.
- The hero has energy (100). A falling meteor deals 15 / 30 / 50 depending on size, then there is a short invulnerability. Falling into a pit costs 30 energy, and the hero is returned to the level.
  Below 20% the bar turns red and a warning sounds.
- At 0 energy you can **continue 3 times** (CONTINUE, 10 s countdown): you come back with full energy, and your score, level and missions are kept. After that it is game over.
- Score: distance travelled + bonus points for each shot-down meteor (25 / 40 / 60 by size). A "+points" label flies to the score counter, which flashes. High scores are kept per difficulty.
- Shooting the gold, sparkling bonus meteor drops a bonus; touch it to collect it.

**Weapons:** the hero starts with a **pistol** (single shot; the shop can equip another weapon). A weapon bonus found in a level (12 s) replaces the current weapon. When it expires, the equipped weapon returns:

| Weapon | Effect |
|---|---|
| PISTOL | basic weapon, single shot; charged: large piercing bullet |
| ROCKET LAUNCHER | rockets explode on impact in a medium radius; slower fire |
| LASER | very fast laser bolt that passes through every crate and enemy |
| GRENADE | grenade thrown in an arc, explodes on impact in a **large** radius |

Explosions destroy every meteor, enemy and enemy projectile in their radius (they do not hurt the hero), and also damage the boss.

**Weapon add-ons:** they stack (12 s each) and work with any weapon:

| Add-on | Effect |
|---|---|
| RAPID FIRE | faster fire with the current weapon, faster charging |
| SPREAD SHOT | 3 bullets / rockets / grenades / laser beams in a fan |
| HOMING | pistol bullets, rockets and grenades curve toward the nearest enemy (or the boss) |

**Other bonuses:** BONUS (+250 points), ENERGY (+35 energy).

**Modifiers:** time-limited effects that make the hero's life harder. They are items lying on the ground (the magic mushroom is one too) and activate when touched. They cannot be shot. Timing, strength and frequency are set in the `modifiers` section of `game.json`:

| Modifier | Effect |
|---|---|
| MAGIC MUSHROOM (SHROOM) | hallucination: the picture wobbles and shifts color |
| PIXELATED (PIXEL) | even bigger pixels (harder to see) |
| FLASHLIGHT (TORCH) | only the hero and a small circle around it are visible |
| INVISIBLE (GHOST) | invisible hero |
| TUNNEL (TINYVIEW) | shrunken field of view: only a small window around the hero is visible |
| TINY HERO (TINYHERO) | shrunken hero |
| MAGNETIC (MAGNET) | falling and already-landed meteors (sliding on the ground), enemy projectiles and flying enemies slowly drift toward the hero |

Active bonuses and modifiers show their name and remaining time in the top-right corner. The HUD and captions are on a separate camera, so modifier shaders (pixelation, flashlight, hallucination…) do not affect them. They always stay readable.

## Enemies

As time passes, more and more enemies arrive (a warning announces each new type):

| Enemy | Appears at | Behavior | Points |
|---|---|---|---|
| SLIME | 20 s | hops toward you on the ground; can be stomped | 50 |
| BAT | 45 s | flies in a wave, swoops down near the hero; can be stomped | 40 |
| TURRET | 75 s | stationary gun turret, fires at the hero | 80 |
| DRONE | 110 s | hovers above the hero and drops bombs | 120 |

Stomping gives double points. Every weapon hits them (explosions too).

## Levels, missions, boss

Each level has 3 missions. At the end of a level the camera slowly stops, and the boss (MOTHERSHIP) arrives: it drops meteors (every third one is gold, with a bonus), fires in a fan, gets faster below half health, and summons bats. After defeating it you get "LEVEL CLEAR", then the next, faster level with new missions:

| Level | Type | Missions |
|---|---|---|
| 1 – CRATER FIELDS | Tiled, ~9800 px | 25 meteors, 6 enemies, collect 4 bonuses |
| 2 – ASHEN VALLEY | Tiled, ~12200 px | 40 meteors, 3 stomps, 3 gold meteors |
| 3 – BLOOD MOON | Tiled, ~9800 px | 50 meteors, 12 enemies, 5 gold meteors |
| 4 – FROZEN RIDGE | Tiled, ~10200 px | 55 meteors, 17 enemies, 4 bonuses |
| 5 – TOXIC MARSH | Tiled, ~10600 px | 70 meteors, 18 enemies, 3 weapon bonuses at once |
| 6 – DUNE SEA | Tiled, ~11000 px | 80 meteors, 22 enemies, 6 stomps |
| 7 – GLACIER NIGHT | Tiled, ~11400 px | 85 meteors, 20 enemies, 5 gold meteors |
| 8 – SPORE HOLLOW | Tiled, ~11800 px | 100 meteors, 24 enemies, 4 bonuses |
| 9 – LUNAR WASTES | Tiled, ~12200 px | 100 meteors, 26 enemies, 3 weapon bonuses at once |
| 10 – THE LAST NIGHT | Tiled, ~12600 px | 110 meteors, 26 enemies, 8 stomps; the final boss |
| 11+ (DEEP NIGHT n) | procedural | ever-larger goals and faster scrolling |

- **Tiled levels** (1–10; the starting point of 3–10 was generated by `scripts/generate-levels.ps1` and can be edited by hand in `levels/`): ground, platforms, enemies, mushrooms, bonuses, meteor storms and the boss are placed by hand. The boss appears at the spot marked in the level. Missions award points but do not gate progress.
- **Procedural levels** (from 3): terrain, meteors and enemies are generated randomly, and the boss comes after the three missions are completed.

Missions are shown at the start of a level, in the pause menu, and in the QUESTS menu on the title screen.

### Editing levels (Tiled)

Levels are made in [Tiled](https://www.mapeditor.org): open the `levels/blockbuster.tiled-project` project, edit the `.tmx`, export to JSON (`assets/levels/`), then rebuild the game. Full guide (format, object types, debug parameters): [`docs/LEVELS.md`](docs/LEVELS.md).

## Settings

From the title screen and the pause menu: music and effects volume, sound on/off, **auto-fire** (shooting continues without pressing the button; you aim with the arrows), and difficulty (EASY / NORMAL / HARD, set on the title screen only). Settings are saved.

### Speeding up

When the camera speeds up, the hero can run faster too: its running speed is at least 1.35× the camera speed (`player.followRatio`), so it can keep up.

### Tuning and cheats

- Values (speeds, damage, timings, difficulty multipliers) are in `assets/config/game.json`. Rebuild after changing them: [`docs/CONFIG.md`](docs/CONFIG.md).
- In development (non-release) builds, **F9** opens the cheat menu: every weapon, add-on, bonus and modifier can be tried, with GOD MODE, bonus-timer freeze, and spawn-off. Development build: `-Dcheats` (VS Code: *Build HTML5 (dev, cheats)*). The `-debug` and `-Dtest` builds include it too. Release builds contain no cheats.

## Sound

All sounds and music are synthesized in code (`Audio.hx`, `Music.hx`): 8-bit, 22 kHz, Amiga-style sample sounds and a 4-channel, tracker-style song. There are no sound files.

## Development

Requirements: Haxe 4.3.6, and from haxelib `lime 8.3.2`, `openfl 9.5.2`, `flixel 6.2.1` (pinned in `Project.xml`).

Install dependencies in one step:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

### VS Code

The `.vscode` folder has a ready-made project setup:

- **Extensions** (offered on opening): Haxe (`nadako.vshaxe`) and Lime (`openfl.lime-vscode-extension`).
- **Tasks** (Terminal → Run Task): *Install dependencies*, *Build HTML5* (Ctrl+Shift+B), *Run HTML5 (browser)*, *Build HTML5 (test)*, *Build HashLink*, *Package for itch.io*, *Publish to itch.io*, *Clean*.
- **F5**: builds and runs with the Lime extension (pick the target in the status bar, e.g. HTML5).
- The Haxe path (`C:/HaxeToolkit`) is set directly in the settings and tasks, so it works even if the system PATH is wrong.

### Run in a browser

```bash
haxelib run lime test html5
```

Native (HashLink) build:

```bash
haxelib run lime test hl
```

Automated smoke test (Playwright): `haxelib run lime build html5 -Dtest`, then serve `export/html5/bin` (for example `python3 -m http.server 8765`) and run `node tests/smoke.js`.

### Publishing on itch.io

**One step:** VS Code *Run Task > Release (build + package + publish)* (or `scripts/release.ps1`): checks the levels, release build, verifies there are no cheats, zips, uploads. Without uploading: *Release (build + package, no publish)* (`-SkipPublish`). The page text, settings and images are in `docs/ITCH.md` and `docs/itch/`.

- **Manually:** the *Package for itch.io* task (or `scripts/package-itch.ps1`) creates `dist/moonshard-html5.zip`, which you upload.
- **Automatically:** the *Publish to itch.io* task (`scripts/publish-itch.ps1`) builds, then uploads with itch.io's official `butler` tool (changes only). One-time setup:
  1. `itch.config.json`: `"user"` = your itch.io username, `"game"` = the project's URL name.
  2. On the first run, butler is downloaded to `tools/`, and it asks you to log in through the browser (or set the `BUTLER_API_KEY` environment variable).
  3. After the first upload, on itch.io tick *This file will be played in the browser* once for the `html5` file. Later uploads update that file.

Haxe code comments are in Hungarian; the game's UI text is in English.
