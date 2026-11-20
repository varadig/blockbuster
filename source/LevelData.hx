package;

import Enemy.EnemyKind;
import PowerUp.PowerKind;
import Quests.QuestGoal;

/** Talaj vagy lebegő platform a Tiled-pályán (a talaj a képernyő aljáig rajzolódik). */
typedef GroundRect =
{
	x:Float,
	y:Float,
	w:Float,
	h:Float,
	platform:Bool,
	/** A bal / jobb perem sötétítendő sorainak száma (rés vagy lépcső mellett), a betöltő számolja. */
	edgeL:Int,
	edgeR:Int
}

enum abstract SpawnType(Int)
{
	var ENEMY = 0;
	var PICKUP = 1;
	var SHROOM = 2;
	var METEOR = 3;
	var SHOWER = 4;
	/** Meteoreső: figyelmeztetés, majd sok meteor egyszerre hullik a képernyő szélességében. */
	var METEORFALL = 5;
}

/** Egy kézzel elhelyezett elem. Az (x, y) a talppont-közép (ellenség, bónusz, gomba, meteor) vagy a téglalap bal-felső sarka (zápor). */
typedef Spawn =
{
	id:Int,
	type:SpawnType,
	x:Float,
	y:Float,
	w:Float,
	h:Float,
	/** Ekkor a kamera bal széle mellett kell megjelennie (x - lead). */
	trigger:Float,
	enemy:Null<EnemyKind>,
	power:Null<PowerKind>,
	/** A jutalom véletlenszerű (RANDOM). */
	randomReward:Bool,
	count:Int,
	spacing:Float,
	floating:Bool,
	speed:Float,
	/** Zápor: meteor / mp. */
	rate:Float,
	/** Zápor: minden ennyiedik meteor arany (0 = egy sem). */
	goldEvery:Int,
	fallMin:Float,
	fallMax:Float,
	/** 0 = EASY, 1 = NORMAL, 2 = HARD: ennél könnyebb szinten nem jelenik meg. */
	minDifficulty:Int
}

/** Egy Tiled-ből exportált, feldolgozott pálya. */
class LevelData
{
	public var name:String = "";
	/** A pálya témája (Themes.hx: NIGHT, ASH, ICE, DESERT, TOXIC); üres = a pálya sorszáma szerinti alap. */
	public var theme:String = "";
	/** Görgetési szorzó; negatív = nincs megadva (a LevelDef értéke marad). */
	public var speed:Float = -1;
	public var length:Float = 0;
	/** Talajok és platformok x szerint rendezve. */
	public var ground:Array<GroundRect> = [];
	/** Pontszerű spawnok a megjelenési x szerint rendezve. */
	public var spawns:Array<Spawn> = [];
	public var showers:Array<Spawn> = [];
	/** A játékos kezdőpontja (a talppont). */
	public var startX:Float = 140;
	public var startY:Float = 232;
	/** A főellenség-aréna bal széle; negatív = nincs. */
	public var bossX:Float = -1;
	public var endX:Float = -1;
	/** A főellenség erőssége; negatív = a pálya sorszáma. */
	public var bossLevel:Int = -1;
	/** A térkép felülírja a küldetéseket (3 hely; null = az alapértelmezett marad). */
	public var goals:Array<Null<QuestGoal>> = [null, null, null];
	public var source:String = "";
	public var warnings:Array<String> = [];

	public function new() {}

	/** A talaj felszíne az adott x-nél (platform nélkül); null, ha ott nincs talaj. */
	public function groundTop(px:Float):Null<Float>
	{
		for (g in ground)
			if (!g.platform && px >= g.x && px <= g.x + g.w)
				return g.y;
		return null;
	}
}
