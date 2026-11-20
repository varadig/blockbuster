package;

import Enemy.EnemyKind;
import LevelData;
import PowerUp.PowerKind;
import Quests.QuestGoal;
import Quests.QuestType;
import haxe.Json;
import openfl.utils.Assets;

/**
 * Tiled JSON export beolvasása. A pálya csak objektumrétegeket tartalmaz (téglalapok és pontok),
 * a grafikát a játék rajzolja. A formátum leírása: docs/LEVELS.md.
 *
 * Hibakezelés: a végzetes hibák (rossz JSON, hiányzó talaj stb.) `null`-t adnak vissza és naplózódnak,
 * ilyenkor a játék a procedurális generátorra esik vissza. A kisebb hibák kihagyják az adott objektumot,
 * és a `LevelData.warnings`-ba kerülnek.
 */
class LevelLoader
{
	/** A képernyő magassága: ennyi sort sötétítünk, ha a talaj széle teljes magasságban látszik (rés). */
	static inline var FULL_EDGE:Int = 270;

	static final QUEST_TYPES:Array<String> = ["meteors", "gold", "enemies", "stomps", "powerups", "score", "survive", "stack"];
	static final ENEMY_KINDS:Map<String, EnemyKind> = ["SLIME" => EnemyKind.SLIME, "BAT" => EnemyKind.BAT, "TURRET" => EnemyKind.TURRET, "DRONE" => EnemyKind.DRONE];

	static var cache:Map<String, Null<LevelData>> = new Map();

	/** A legutóbbi betöltési hiba (tesztekhez). */
	public static var lastError:Null<String> = null;

	/** Betöltés az beágyazott assetből (gyorsítótárazva). */
	public static function load(path:String):Null<LevelData>
	{
		if (cache.exists(path))
			return cache.get(path);
		var text:Null<String> = null;
		try
		{
			text = Assets.getText(path);
		}
		catch (e:Dynamic) {}
		if (text == null)
		{
			fail(path, "az asset nem található (a Project.xml <assets> szakaszát és a fájl nevét ellenőrizd)");
			cache.set(path, null);
			return null;
		}
		return inject(path, text);
	}

	/** Pálya betöltése szövegből és gyorsítótárba tétele (tesztek és hibakeresés; hiba esetén null kerül a gyorsítótárba). */
	public static function inject(path:String, text:String):Null<LevelData>
	{
		var data:Null<LevelData> = null;
		try
		{
			data = parse(text, path);
		}
		catch (e:Dynamic)
		{
			fail(path, Std.string(e));
		}
		cache.set(path, data);
		return data;
	}

	public static function clearCache():Void
	{
		cache = new Map();
	}

	static function fail(path:String, msg:String):Void
	{
		lastError = msg;
		trace('[LevelLoader] $path: $msg');
	}

	// --- Feldolgozás --------------------------------------------------------------------

	/** A Tiled JSON feldolgozása; végzetes hibánál String-et dob. */
	public static function parse(text:String, source:String):LevelData
	{
		var root:Dynamic = Json.parse(text);
		if (Reflect.field(root, "orientation") != "orthogonal")
			throw "csak orthogonal térkép támogatott";
		if (Reflect.field(root, "infinite") == true)
			throw "végtelen (infinite) térkép nem támogatott: Map > Map Properties > Infinite kikapcsolva legyen";

		var lvl = new LevelData();
		lvl.source = source;
		var tw:Float = num(Reflect.field(root, "tilewidth"), 8);
		lvl.length = Math.round(num(Reflect.field(root, "width"), 0) * tw);

		var mp = props(root);
		lvl.name = str(mp, "name", "");
		lvl.theme = str(mp, "theme", "").toUpperCase();
		if (lvl.theme != "" && Themes.find(lvl.theme) == null)
		{
			lvl.warnings.push('ismeretlen "theme": "${lvl.theme}", az alap téma lesz');
			lvl.theme = "";
		}
		if (mp.exists("speed"))
			lvl.speed = num(mp.get("speed"), -1);
		lvl.bossLevel = Std.int(num(mp.get("bossLevel"), -1));
		for (i in 0...3)
		{
			var t = str(mp, 'quest${i + 1}Type', "").toLowerCase();
			var n = Std.int(num(mp.get('quest${i + 1}Target'), 0));
			if (t != "" && n > 0)
			{
				if (QUEST_TYPES.contains(t))
					lvl.goals[i] = {type: (t : QuestType), target: n};
				else
					lvl.warnings.push('quest${i + 1}Type ismeretlen: "$t"');
			}
		}

		var nextId = 0;
		var playerSet = false;
		var layers:Array<Dynamic> = Reflect.field(root, "layers");
		if (layers == null)
			throw "nincs réteg";
		// a csempe-objektumok (sprite-előnézet) csempekészletének első gid-je (a Tiled mentéskor újraszámolhatja)
		var objFirst = 1;
		var tss:Null<Array<Dynamic>> = Reflect.field(root, "tilesets");
		if (tss != null)
			for (ts in tss)
				if (str2(Reflect.field(ts, "source")).indexOf("objects") >= 0)
					objFirst = Std.int(num(Reflect.field(ts, "firstgid"), 1));
		for (layer in flatten(layers))
		{
			if (Reflect.field(layer, "type") != "objectgroup" || Reflect.field(layer, "visible") == false)
				continue;
			var layerName = str2(Reflect.field(layer, "name")).toLowerCase();
			var objects:Array<Dynamic> = Reflect.field(layer, "objects");
			if (objects == null)
				continue;
			for (o in objects)
			{
				if (Reflect.field(o, "visible") == false)
					continue;
				var id = Std.int(num(Reflect.field(o, "id"), nextId++));
				var cls = str2(Reflect.field(o, "class"));
				if (cls == "")
					cls = str2(Reflect.field(o, "type")); // régebbi Tiled
				if (cls == "")
					cls = switch (layerName)
					{
						case "ground": "Ground";
						case "platforms": "Platform";
						default: "";
					}
				var key = cls.toLowerCase();
				var rx = num(Reflect.field(o, "x"), 0);
				var ry = num(Reflect.field(o, "y"), 0);
				var w = Math.round(num(Reflect.field(o, "width"), 0));
				var h = Math.round(num(Reflect.field(o, "height"), 0));
				var p = props(o);
				var where = 'objektum #$id ("${str2(Reflect.field(o, "name"))}", $cls)';
				// csempe-objektum (sprite-előnézet): a Tiled-ben a bal alsó sarok az origó; a pont a sprite horgonyán van (TiledSprites)
				var gid:Null<Int> = Reflect.field(o, "gid");
				if (gid != null)
				{
					var ti = (gid & 0x0FFFFFFF) - objFirst;
					if (ti < 0 || ti >= TiledSprites.TILES.length)
					{
						lvl.warnings.push('$where: ismeretlen csempe-objektum (gid $gid), kihagyva');
						continue;
					}
					var td = TiledSprites.TILES[ti];
					if (cls == "")
						cls = td.cls;
					key = cls.toLowerCase();
					if (td.def != null)
						for (f in Reflect.fields(td.def))
							if (!p.exists(f))
								p.set(f, Reflect.field(td.def, f));
					switch (td.anchor)
					{
						case "b": rx += w / 2;
						case "c":
							rx += w / 2;
							ry -= h / 2;
						default:
					}
				}
				var x = Math.round(rx);
				var y = Math.round(ry);

				if (Reflect.field(o, "polygon") != null || Reflect.field(o, "ellipse") == true)
				{
					lvl.warnings.push('$where: csak téglalap és pont támogatott, kihagyva');
					continue;
				}

				switch (key)
				{
					case "ground":
						if (w <= 0)
							lvl.warnings.push('$where: nulla szélességű talaj, kihagyva');
						else
							lvl.ground.push({x: x, y: y, w: w, h: 0, platform: false, edgeL: 0, edgeR: 0});
					case "platform":
						if (w <= 0)
							lvl.warnings.push('$where: nulla szélességű platform, kihagyva');
						else
							lvl.ground.push({x: x, y: y, w: w, h: Math.max(8, h), platform: true, edgeL: 0, edgeR: 0});
					case "player":
						lvl.startX = x;
						lvl.startY = y;
						playerSet = true;
					case "boss":
						lvl.bossX = x;
					case "end":
						lvl.endX = x;
					case "enemy":
						var kind = ENEMY_KINDS.get(str(p, "kind", "").toUpperCase());
						if (kind == null)
						{
							lvl.warnings.push('$where: hiányzó vagy ismeretlen "kind", kihagyva');
							continue;
						}
						var sp = newSpawn(id, SpawnType.ENEMY, x, y, p, FlxG_WIDTH + 16);
						sp.enemy = kind;
						sp.count = Std.int(Math.max(1, num(p.get("count"), 1)));
						sp.spacing = num(p.get("spacing"), 24);
						lvl.spawns.push(sp);
					case "pickup":
						var pk = parsePower(str(p, "kind", ""));
						if (pk == null || PowerUp.CURSES.contains(pk))
						{
							lvl.warnings.push('$where: hiányzó vagy ismeretlen "kind", kihagyva');
							continue;
						}
						var sp = newSpawn(id, SpawnType.PICKUP, x, y, p, FlxG_WIDTH + 16);
						sp.power = pk;
						sp.floating = bool(p.get("floating"), true);
						lvl.spawns.push(sp);
					case "shroom":
						// Módosító tárgy; a "kind" (SHROOM, PIXEL, TORCH, GHOST, TINYVIEW, TINYHERO, MAGNET, ASCII) opcionális: nélküle véletlen
						var sp = newSpawn(id, SpawnType.SHROOM, x, y, p, FlxG_WIDTH + 16);
						var ck = parsePower(str(p, "kind", ""));
						if (ck != null && PowerUp.CURSES.contains(ck))
							sp.power = ck;
						lvl.spawns.push(sp);
					case "meteor":
						var sp = newSpawn(id, SpawnType.METEOR, x, y, p, Math.round(FlxG_WIDTH * 0.8));
						applyReward(sp, str(p, "reward", ""), lvl.warnings, where);
						sp.speed = num(p.get("speed"), 100);
						lvl.spawns.push(sp);
					case "meteorfall":
						var sp = newSpawn(id, SpawnType.METEORFALL, x, y, p, 560);
						sp.count = Std.int(Math.max(2, num(p.get("count"), 14)));
						sp.w = Math.max(100, num(p.get("span"), 520));
						sp.goldEvery = Std.int(num(p.get("goldEvery"), 0));
						sp.fallMin = num(p.get("fallMin"), 70);
						sp.fallMax = Math.max(sp.fallMin, num(p.get("fallMax"), 150));
						applyReward(sp, str(p, "reward", "RANDOM"), lvl.warnings, where);
						lvl.spawns.push(sp);
					case "shower":
						if (w <= 0)
						{
							lvl.warnings.push('$where: a zápor téglalap legyen (szélesség > 0), kihagyva');
							continue;
						}
						var sp = newSpawn(id, SpawnType.SHOWER, x, y, p, 0);
						sp.w = w;
						sp.h = h;
						sp.rate = Math.max(0.05, num(p.get("rate"), 1));
						sp.goldEvery = Std.int(num(p.get("goldEvery"), 0));
						sp.fallMin = num(p.get("fallMin"), 60);
						sp.fallMax = Math.max(sp.fallMin, num(p.get("fallMax"), 140));
						applyReward(sp, str(p, "reward", "RANDOM"), lvl.warnings, where);
						lvl.showers.push(sp);
					default:
						lvl.warnings.push('$where: ismeretlen osztály, kihagyva');
				}
			}
		}

		if (!playerSet)
			lvl.warnings.push('nincs Player pont, az alapértelmezett kezdőpont (${lvl.startX}, ${lvl.startY}) lesz');
		if (lvl.bossX < 0 && lvl.endX < 0)
			throw "nincs Boss vagy End trigger: a pálya sosem érne véget";
		var hasGround = false;
		for (g in lvl.ground)
			if (!g.platform)
				hasGround = true;
		if (!hasGround)
			throw "nincs Ground téglalap";

		lvl.ground.sort((a, b) -> a.x != b.x ? (a.x < b.x ? -1 : 1) : (a.y < b.y ? -1 : 1));
		lvl.spawns.sort((a, b) -> a.trigger != b.trigger ? (a.trigger < b.trigger ? -1 : 1) : a.id - b.id);
		lvl.showers.sort((a, b) -> a.x < b.x ? -1 : (a.x > b.x ? 1 : 0));

		computeEdges(lvl);

		if (lvl.groundTop(lvl.startX) == null)
			throw 'nincs talaj a játékos kezdőpontja alatt (x=${lvl.startX})';
		if (lvl.bossX >= 0)
			checkArena(lvl);

		return lvl;
	}

	/** Élárnyékolás a szomszédokból: rés esetén teljes magasság, lépcsőnél csak a kiálló rész (mint a procedurális generátornál). */
	static function computeEdges(lvl:LevelData):Void
	{
		var prev:Null<GroundRect> = null;
		for (g in lvl.ground)
		{
			if (g.platform)
				continue;
			if (prev != null)
			{
				if (g.x < prev.x + prev.w - 1)
					throw 'átfedő talaj: x=${g.x} (az előző talaj vége: ${prev.x + prev.w})';
				if (g.x > prev.x + prev.w + 1)
				{
					g.edgeL = FULL_EDGE;
					prev.edgeR = FULL_EDGE;
				}
				else if (g.y < prev.y)
					g.edgeL = Std.int(prev.y - g.y);
				else if (g.y > prev.y)
					prev.edgeR = Std.int(g.y - prev.y);
			}
			prev = g;
		}
		if (prev != null)
			prev.edgeR = FULL_EDGE;
	}

	/** A főellenség-aréna [bossX-160, bossX+480] legyen összefüggő talaj. */
	static function checkArena(lvl:LevelData):Void
	{
		var from = lvl.bossX - 160, to = lvl.bossX + 480;
		var covered = from;
		for (g in lvl.ground)
		{
			if (g.platform || g.x + g.w < covered - 1)
				continue;
			if (g.x > covered + 1)
				break;
			covered = Math.max(covered, g.x + g.w);
		}
		if (covered < to - 1)
			lvl.warnings.push('a főellenség-aréna talaja nem összefüggő: x=${from}..${to}, de csak x=${covered}-ig van talaj');
	}

	/**
	 * Küldetés-megvalósíthatóság becslése a kézzel elhelyezett elemekből (csak figyelmeztetés).
	 * A zápor meteorjait a bejárási idő alapján becsüli (~110 px/s átlagos görgetés).
	 */
	public static function questWarnings(lvl:LevelData, goals:Array<QuestGoal>):Array<String>
	{
		var out:Array<String> = [];
		var enemies = 0, stompables = 0, pickups = 0, gold = 0, meteors = 0.0;
		for (sp in lvl.spawns)
		{
			if (sp.minDifficulty > 1)
				continue;
			switch (sp.type)
			{
				case SpawnType.ENEMY:
					enemies += sp.count;
					if (sp.enemy == EnemyKind.SLIME || sp.enemy == EnemyKind.BAT)
						stompables += sp.count;
				case SpawnType.PICKUP:
					pickups++;
				case SpawnType.METEORFALL:
					meteors += sp.count;
					if (sp.goldEvery > 0)
					{
						gold += Std.int(sp.count / sp.goldEvery);
						pickups += Std.int(sp.count / sp.goldEvery);
					}
				case SpawnType.METEOR:
					meteors++;
					if (sp.power != null || sp.randomReward)
					{
						gold++;
						pickups++;
					}
				default:
			}
		}
		var speed = lvl.speed > 0 ? lvl.speed : 1;
		for (sp in lvl.showers)
		{
			var n = sp.rate * sp.w / (110 * speed);
			meteors += n;
			if (sp.goldEvery > 0)
			{
				gold += Std.int(n / sp.goldEvery);
				pickups += Std.int(n / sp.goldEvery);
			}
		}
		for (g in goals)
		{
			var gt:String = g.type;
			var have:Float = switch (gt)
			{
				case "meteors": meteors;
				case "enemies": enemies;
				case "stomps": stompables;
				case "powerups": pickups;
				case "gold": gold;
				case "survive": lvl.length / (110 * speed);
				default: -1;
			}
			if (have >= 0 && have < g.target)
				out.push('küldetés "${g.type}" cél ${g.target}, de a pályán csak kb. ${Std.int(have)} érhető el');
		}
		return out;
	}

	// --- Segédek --------------------------------------------------------------------------

	/** A Tiled kép szélessége (játék-felbontás); a "lead" alapértékekhez. */
	static inline var FlxG_WIDTH:Int = 480;

	static function newSpawn(id:Int, type:SpawnType, x:Float, y:Float, p:Map<String, Dynamic>, defaultLead:Float):Spawn
	{
		var lead = num(p.get("lead"), defaultLead);
		return {
			id: id,
			type: type,
			x: x,
			y: y,
			w: 0,
			h: 0,
			trigger: x - lead,
			enemy: null,
			power: null,
			randomReward: false,
			count: 1,
			spacing: 24,
			floating: true,
			speed: 100,
			rate: 1,
			goldEvery: 0,
			fallMin: 60,
			fallMax: 140,
			minDifficulty: Std.int(num(p.get("minDifficulty"), 0))
		};
	}

	/** A "reward" tulajdonság: NONE (vagy üres) = nincs, RANDOM = véletlen bónusz, különben egy PowerKind neve. */
	static function applyReward(sp:Spawn, value:String, warnings:Array<String>, where:String):Void
	{
		var v = value.toUpperCase();
		if (v == "" || v == "NONE")
			return;
		if (v == "RANDOM")
		{
			sp.randomReward = true;
			return;
		}
		var pk = parsePower(v);
		if (pk == null || PowerUp.CURSES.contains(pk))
			warnings.push('$where: ismeretlen "reward": "$value", nem lesz jutalom');
		else
			sp.power = pk;
	}

	static function parsePower(name:String):Null<PowerKind>
	{
		var n = name.toUpperCase();
		for (k in Type.allEnums(PowerKind))
			if (Std.string(k) == n)
				return k;
		return null;
	}

	/** A csoportrétegek kibontása, a rétegek sorrendjében. */
	static function flatten(layers:Array<Dynamic>):Array<Dynamic>
	{
		var out:Array<Dynamic> = [];
		for (l in layers)
		{
			if (Reflect.field(l, "type") == "group")
			{
				if (Reflect.field(l, "visible") != false)
					for (c in flatten(Reflect.field(l, "layers")))
						out.push(c);
			}
			else
				out.push(l);
		}
		return out;
	}

	/** A Tiled `properties` tömbje név → érték térképpé. */
	static function props(o:Dynamic):Map<String, Dynamic>
	{
		var m = new Map<String, Dynamic>();
		var arr:Null<Array<Dynamic>> = Reflect.field(o, "properties");
		if (arr != null)
			for (p in arr)
			{
				var name:Null<String> = Reflect.field(p, "name");
				if (name != null)
					m.set(name, Reflect.field(p, "value"));
			}
		return m;
	}

	static function str(m:Map<String, Dynamic>, name:String, def:String):String
	{
		var v = m.get(name);
		return v == null ? def : StringTools.trim(Std.string(v));
	}

	static function str2(v:Dynamic):String
	{
		return v == null ? "" : StringTools.trim(Std.string(v));
	}

	static function num(v:Dynamic, def:Float):Float
	{
		if (v == null)
			return def;
		var f = Std.parseFloat(Std.string(v));
		return Math.isNaN(f) ? def : f;
	}

	static function bool(v:Dynamic, def:Bool):Bool
	{
		if (v == null)
			return def;
		var s = Std.string(v).toLowerCase();
		return s == "true" || s == "1";
	}
}
