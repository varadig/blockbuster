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

/** Egy pálya: név, a teljesítendő küldetések (mind kell a főellenséghez), görgetési szorzó. */
typedef LevelDef = {name:String, goals:Array<QuestGoal>, speed:Float};

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
		{name: "CRATER FIELDS", goals: [{type: BOXES, target: 25}, {type: ENEMIES, target: 6}, {type: POWERUPS, target: 4}], speed: 1},
		{name: "ASHEN VALLEY", goals: [{type: BOXES, target: 40}, {type: STOMPS, target: 3}, {type: GOLD_BOXES, target: 3}], speed: 1.12},
		{name: "BLOOD MOON", goals: [{type: ENEMIES, target: 20}, {type: BOXES, target: 60}, {type: WEAPON_STACK, target: 3}], speed: 1.25},
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

	public static function levelDef(l:Int):LevelDef
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
