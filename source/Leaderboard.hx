package;

import flixel.util.FlxSave;
import haxe.Http;
import haxe.Json;

/** Egy ranglista-sor. */
typedef LbEntry =
{
	name:String,
	score:Int,
	level:Int
}

/**
 * Globális ranglista (Supabase REST): `assets/config/game.json` > `leaderboard.url` / `leaderboard.key` (az anon kulcs nyilvános, a védelmet a
 * táblán a Row Level Security adja; lásd docs/LEADERBOARD.md). Ha nincs beállítva, a funkció nem látszik a játékban.
 *
 * - `submit`: egy pontszám beküldése (3 betűs név, szint, nehézség).
 * - `fetch`: a legjobb 10 egy nehézségen; a munkamenetben gyorsítótárazott (nehézségenként), a beküldés érvényteleníti.
 * Cheat-buildben (-debug / -Dtest / -Dcheats) beküldeni nem lehet, hogy a tesztelés ne szennyezze a listát.
 */
class Leaderboard
{
	public static inline var NAME_LEN:Int = 3;
	public static inline var LIMIT:Int = 10;

	static var save:FlxSave;
	static var cache:Map<String, Array<LbEntry>> = new Map();

	/** Cheat-buildben: igaz, ha a futás közben megnyitották a cheat-menüt vagy cheat-gombot használtak (az ilyen futás pontja nem küldhető be). */
	public static var cheated:Bool = false;

	/** A legutóbb beküldött sor (a lista kiemeléséhez). */
	public static var lastName:String = "";
	public static var lastScore:Int = -1;

	/** Be van-e állítva a szolgáltatás (URL + kulcs). */
	public static function configured():Bool
		return Config.leaderboardUrl != "" && Config.leaderboardKey != "";

	/** Lehet-e pontot beküldeni (cheat-buildben nem). */
	public static function canSubmit():Bool
	{
		#if cheats
		return configured() && (Config.leaderboardTest || !cheated); // cheat-buildben csak tiszta (cheat nélküli) futás küldhető be
		#else
		return configured();
		#end
	}

	static function bind():FlxSave
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("blockbuster");
		}
		return save;
	}

	/** A játékos mentett neve (3 nagybetű), alapból "AAA". */
	public static function savedName():String
	{
		var v:Null<String> = Reflect.field(bind().data, "lbname");
		return v != null && v.length == NAME_LEN ? v : "AAA";
	}

	public static function saveName(name:String):Void
	{
		var s = bind();
		Reflect.setField(s.data, "lbname", name);
		s.flush();
	}

	/** Eszközönként egyszer generált véletlen azonosító (a későbbi szűréshez / visszaélés-kereséshez), nem személyes adat. */
	static function device():String
	{
		var s = bind();
		var v:Null<String> = Reflect.field(s.data, "lbdevice");
		if (v == null)
		{
			v = "";
			for (i in 0...16)
				v += StringTools.hex(Std.random(16)).toLowerCase();
			Reflect.setField(s.data, "lbdevice", v);
			s.flush();
		}
		return v;
	}

	static function request(path:String, post:Null<String>, onOk:String->Void, onFail:String->Void):Void
	{
		var h = new Http(Config.leaderboardUrl + "/rest/v1/" + path);
		h.setHeader("apikey", Config.leaderboardKey);
		h.setHeader("Authorization", "Bearer " + Config.leaderboardKey);
		if (post != null)
		{
			h.setHeader("Content-Type", "application/json");
			h.setHeader("Prefer", "return=minimal");
			h.setPostData(post);
		}
		h.onData = onOk;
		h.onError = onFail;
		try
			h.request(post != null)
		catch (e:Dynamic)
			onFail(Std.string(e));
	}

	/** Pontszám beküldése; `done(true)` siker esetén. */
	public static function submit(name:String, score:Int, level:Int, done:Bool->Void):Void
	{
		if (!canSubmit())
		{
			done(false);
			return;
		}
		var body = Json.stringify({
			name: name,
			score: score,
			level: level,
			difficulty: Settings.difficultyName(),
			character: Characters.current().name,
			device: device()
		});
		request(Config.leaderboardTable, body, _ ->
		{
			lastName = name;
			lastScore = score;
			cache.remove(Settings.difficultyName());
			saveName(name);
			done(true);
		}, _ -> done(false));
	}

	/** A legjobb `LIMIT` sor az adott nehézségen (EASY / NORMAL / HARD); `done(null)` hiba esetén. */
	public static function fetch(difficulty:String, done:Null<Array<LbEntry>>->Void):Void
	{
		if (cache.exists(difficulty))
		{
			done(cache.get(difficulty));
			return;
		}
		if (!configured())
		{
			done(null);
			return;
		}
		var path = Config.leaderboardTable + "?select=name,score,level&difficulty=eq." + difficulty + "&order=score.desc&limit=" + LIMIT;
		request(path, null, text ->
		{
			try
			{
				var rows:Array<Dynamic> = Json.parse(text);
				var out:Array<LbEntry> = [for (r in rows) {name: Std.string(r.name), score: Std.int(r.score), level: Std.int(r.level)}];
				cache.set(difficulty, out);
				done(out);
			}
			catch (e:Dynamic)
				done(null);
		}, _ -> done(null));
	}
}
