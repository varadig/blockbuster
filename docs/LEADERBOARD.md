# Globális ranglista (Supabase)

A játék a pontszámokat egy Supabase táblába küldi (REST), és onnan olvassa a legjobb 10-et nehézségenként. Amíg az URL és a kulcs üres
(`assets/config/game.json` > `leaderboard`), a funkció nem látszik a játékban (nincs LEADERBOARD menüpont, nincs névbeírás).

## Beállítás

1. Hozz létre egy ingyenes projektet a <https://supabase.com> oldalon.
2. SQL Editor → futtasd:

```sql
create table public.scores (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name       text not null check (name ~ '^[A-Z]{3}$'),
  score      int  not null check (score between 0 and 1000000),
  level      int  not null check (level between 0 and 99),
  difficulty text not null check (difficulty in ('EASY', 'NORMAL', 'HARD')),
  character  text check (character is null or length(character) <= 12),
  device     text check (device is null or length(device) <= 32)
);

create index scores_diff_score on public.scores (difficulty, score desc);

alter table public.scores enable row level security;

-- Bárki olvashat és beküldhet, de módosítani / törölni nem lehet (nincs rá szabály).
create policy "read scores"   on public.scores for select to anon using (true);
create policy "insert scores" on public.scores for insert to anon with check (true);
```

A `check` megkötések a táblán érvényesülnek (3 nagybetű, ésszerű pontszám-tartomány), így a hibás sorokat a szerver elutasítja.

3. Project Settings → API: másold ki a **Project URL**-t és az **anon public** kulcsot (ez nyilvános kulcs, a védelmet a Row Level Security adja).
4. `assets/config/game.json`:

```json
"leaderboard": {
  "url": "https://<projekt>.supabase.co",
  "key": "<anon public kulcs>",
  "table": "scores"
}
```

5. Fordítsd újra (a JSON be van ágyazva): `haxelib run lime build html5`. Utána a címképernyőn megjelenik a LEADERBOARD menüpont, a játék vége
   után pedig a 3 betűs névbeírás.

## Működés

- Játék végén (`PlayState.gameOver`) a `LeaderboardSubState` kéri a nevet (billentyűzet: nyilak + betűk, Enter; érintés: ▲/▼ a betűk fölött/alatt, OK), majd
  beküldi (`Leaderboard.submit`) és megmutatja a listát a friss sor kiemelésével. A név megjegyződik (`lbname` a mentésben).
- A lista nehézségenként külön (EASY / NORMAL / HARD), balra/jobbra vagy a fejlécre koppintva vált. Munkamenetenként gyorsítótárazott, a beküldés érvényteleníti.
- Hálózati hiba esetén a lista "OFFLINE" üzenetet mutat, a beküldés újrapróbálható vagy kihagyható; a játék működése nem függ tőle.
- Cheat-buildben (`-debug`, `-Dtest`, `-Dcheats`) nem lehet pontot beküldeni, hogy a tesztelés ne szennyezze a listát.

## Korlátok / csalás

A kulcs és a kliens kódja nyilvános, ezért egy elszánt játékos közvetlenül is beküldhet pontot (a tábla megkötései csak az értelmetlen értékeket zárják ki).
Ha ez gondot okoz: Supabase Edge Function a beküldésre (pl. sebességkorlát eszközönként: a `device` mező erre való), vagy a pontok utólagos szűrése az SQL szerkesztőben.

## Tesztelés szerver nélkül

A `scripts/devserver.js` tartalmaz egy memóriában tárolt Supabase-mockot (`/rest/v1/scores`). Cheat-buildben az URL-paraméterek felülírják a beállítást és
engedik a beküldést:

```
http://127.0.0.1:<port>/?lburl=http://127.0.0.1:<port>&lbkey=x
```
