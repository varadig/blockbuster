package;

/** Küldetéstípusok. */
enum abstract QuestType(String) from String to String
{
	var BOXES = "meteors";
	var GOLD_BOXES = "gold";
	var ENEMIES = "enemies";
	var STOMPS = "stomps";
	var POWERUPS = "powerups";
	var SCORE = "score";
	var SURVIVE = "survive";
	var WEAPON_STACK = "stack";
}

typedef QuestGoal = {type:QuestType, target:Int};

/**
 * Egy pálya: név, küldetések, görgetési szorzó és opcionálisan a Tiled-térkép (asset útvonal).
 * Térképes pályán a térkép nevét, sebességét és küldetéseit felülírhatja (lásd LevelLoader), a főellenség a
 * térképen kijelölt helyen jön; térkép nélkül a pálya procedurálisan generálódik, és a küldetések teljesítése hívja a főellenséget.
 */
typedef LevelDef = {name:String, goals:Array<QuestGoal>, speed:Float, ?map:String};

/**
 * Pálya-alapú küldetések: minden pályának 3 rögzített küldetése van, ezeket a pályán kell teljesíteni.
 * Ha mind kész, jön a főellenség (PlayState), a legyőzése után a következő pálya, új küldetésekkel.
 */
class Quests
{
	static final TEXTS:Map<String, String> = [
		BOXES => "Destroy {n} meteors",
		GOLD_BOXES => "Shoot {n} golden meteors",
		ENEMIES => "Defeat {n} enemies",
		STOMPS => "Stomp {n} enemies",
		POWERUPS => "Collect {n} power-ups",
		SCORE => "Reach {n} points",
		SURVIVE => "Survive {n} seconds",
		WEAPON_STACK => "Have {n} weapon power-ups at once",
	];

	/** A pályák; az utolsó után a pályák ennek fokozatosan nehezebb változatai. */
	public static final LEVELS:Array<LevelDef> = [
		{name: "CRATER FIELDS", goals: [{type: BOXES, target: 25}, {type: ENEMIES, target: 6}, {type: POWERUPS, target: 4}], speed: 1, map: "assets/levels/01_crater_fields.json"},
		{name: "ASHEN VALLEY", goals: [{type: BOXES, target: 40}, {type: STOMPS, target: 3}, {type: GOLD_BOXES, target: 3}], speed: 1.12, map: "assets/levels/02_ashen_valley.json"},
		{name: "BLOOD MOON", goals: [{type: BOXES, target: 50}, {type: ENEMIES, target: 12}, {type: GOLD_BOXES, target: 5}], speed: 1.25, map: "assets/levels/03_blood_moon.json"},
		{name: "FROZEN RIDGE", goals: [{type: BOXES, target: 55}, {type: ENEMIES, target: 17}, {type: POWERUPS, target: 4}], speed: 1.3, map: "assets/levels/04_frozen_ridge.json"},
		{name: "TOXIC MARSH", goals: [{type: BOXES, target: 70}, {type: ENEMIES, target: 18}, {type: WEAPON_STACK, target: 3}], speed: 1.35, map: "assets/levels/05_toxic_marsh.json"},
		{name: "DUNE SEA", goals: [{type: BOXES, target: 80}, {type: ENEMIES, target: 22}, {type: STOMPS, target: 6}], speed: 1.4, map: "assets/levels/06_dune_sea.json"},
		{name: "GLACIER NIGHT", goals: [{type: BOXES, target: 85}, {type: ENEMIES, target: 20}, {type: GOLD_BOXES, target: 5}], speed: 1.45, map: "assets/levels/07_glacier_night.json"},
		{name: "SPORE HOLLOW", goals: [{type: BOXES, target: 100}, {type: ENEMIES, target: 24}, {type: POWERUPS, target: 4}], speed: 1.5, map: "assets/levels/08_spore_hollow.json"},
		{name: "LUNAR WASTES", goals: [{type: BOXES, target: 100}, {type: ENEMIES, target: 26}, {type: WEAPON_STACK, target: 3}], speed: 1.55, map: "assets/levels/09_lunar_wastes.json"},
		{name: "THE LAST NIGHT", goals: [{type: BOXES, target: 110}, {type: ENEMIES, target: 26}, {type: STOMPS, target: 8}], speed: 1.6, map: "assets/levels/10_the_last_night.json"},
	];

	/** Az aktuális pálya (0-tól). */
	public static var level(default, null):Int = 0;
	public static var goals(default, null):Array<QuestGoal> = [];
	public static var done(default, null):Array<Bool> = [];

	/** Egy küldetés teljesült: (szöveg, jutalompont). */
	public static var onComplete:(String, Int)->Void;
	/** A pálya összes küldetése teljesült (jöhet a főellenség). */
	public static var onAllComplete:Void->Void;

	/** A pálya számlálói fajtánként. */
	static var run:Map<String, Int> = new Map();
	static var allFired:Bool = false;

	/** Az összefésült pályaleírások (a térkép felülírásaival), pályánként gyorsítótárazva. */
	static var defCache:Map<Int, LevelDef> = new Map();

	/** Gyorsítótár törlése (tesztek: a LEVELS vagy a betöltött térképek módosítása után). */
	public static function resetCache():Void
	{
		defCache = new Map();
	}

	public static function levelDef(l:Int):LevelDef
	{
		var c = defCache.get(l);
		if (c != null)
			return c;
		var d = baseDef(l);
		if (d.map != null)
		{
			var lvl = LevelLoader.load(d.map);
			if (lvl != null)
				d = merge(d, lvl);
		}
		defCache.set(l, d);
		return d;
	}

	/** A térkép felülírja a nevet, a sebességet és (helyenként) a küldetéseket. */
	static function merge(d:LevelDef, lvl:LevelData):LevelDef
	{
		var goals = d.goals.copy();
		for (i in 0...goals.length)
			if (i < lvl.goals.length && lvl.goals[i] != null)
				goals[i] = lvl.goals[i];
		#if (debug || test)
		for (w in lvl.warnings.concat(LevelLoader.questWarnings(lvl, goals)))
			trace('[LevelLoader] ${lvl.source}: $w');
		#end
		return {
			name: lvl.name != "" ? lvl.name : d.name,
			goals: goals,
			speed: lvl.speed > 0 ? lvl.speed : d.speed,
			map: d.map
		};
	}

	static function baseDef(l:Int):LevelDef
	{
		if (l < LEVELS.length)
			return LEVELS[l];
		// Az utolsó pálya után: ugyanazok a küldetések, egyre nagyobb célokkal és gyorsabb görgetéssel
		var last = LEVELS[LEVELS.length - 1];
		var extra = l - (LEVELS.length - 1);
		return {
			name: 'DEEP NIGHT ${extra}',
			goals: [for (g in last.goals) {type: g.type, target: Math.round(g.target * (1 + 0.35 * extra))}],
			speed: last.speed + 0.08 * extra
		};
	}

	/** Új pálya: a számlálók nulláról indulnak. */
	public static function startLevel(l:Int):Void
	{
		level = l;
		goals = levelDef(l).goals.copy();
		done = [for (g in goals) false];
		run = new Map();
		allFired = false;
	}

	public static function add(type:QuestType, n:Int = 1):Void
	{
		run.set(type, value(type) + n);
		check();
	}

	/** Elért érték (pl. pontszám); csak a maximum számít. */
	public static function reach(type:QuestType, v:Int):Void
	{
		if (v <= value(type))
			return;
		run.set(type, v);
		check();
	}

	static function value(type:QuestType):Int
	{
		var v = run.get(type);
		return v != null ? v : 0;
	}

	public static function target(i:Int):Int
	{
		return goals[i].target;
	}

	public static function text(i:Int):String
	{
		return StringTools.replace(TEXTS.get(goals[i].type), "{n}", Std.string(target(i)));
	}

	public static function progress(i:Int):Int
	{
		return Std.int(Math.min(target(i), value(goals[i].type)));
	}

	public static function reward(i:Int):Int
	{
		return 300 * (level + 1);
	}

	public static function completedCount():Int
	{
		var n = 0;
		for (d in done)
			if (d)
				n++;
		return n;
	}

	static function check():Void
	{
		for (i in 0...goals.length)
			if (!done[i] && progress(i) >= target(i))
			{
				done[i] = true;
				if (onComplete != null)
					onComplete(text(i), reward(i));
			}
		if (!allFired && completedCount() == goals.length)
		{
			allFired = true;
			if (onAllComplete != null)
				onAllComplete();
		}
	}
}
