package;

import flixel.FlxG;
import flixel.util.FlxSave;

/** Nehézségi szintek. */
enum abstract Difficulty(Int) from Int to Int
{
	var EASY = 0;
	var NORMAL = 1;
	var HARD = 2;
}

/** Játékbeállítások (hangerők, némítás, karakter, nehézség) tartós mentéssel. */
class Settings
{
	public static var musicVolume:Float = 0.7;
	public static var sfxVolume:Float = 0.8;
	public static var muted:Bool = false;
	/** A választott karakter indexe (Characters.LIST), mentve. */
	public static var character:Int = 0;
	/** Összegyűjtött érmék (a boltban költhetők) és a fejlesztések szintjei (Upgrades), mentve. */
	public static var coins:Int = 0;
	public static var upgrades:Array<Int> = [0, 0, 0, 0];
	/** Megvásárolt fegyverek (Upgrades.WEAPONS sorrendjében: 0/1) és a felszerelt indulófegyver (0 = pisztoly, 1.. = a WEAPONS i-1. eleme). */
	public static var ownedWeapons:Array<Int> = [0, 0, 0];
	public static var loadout:Int = 0;
	public static var difficulty:Difficulty = NORMAL;

	static var save:FlxSave;

	public static function load():Void
	{
		Config.load();
		if (save != null)
			return;
		save = new FlxSave();
		save.bind("blockbuster_settings");
		var d = save.data;
		if (d.musicVolume != null)
			musicVolume = d.musicVolume;
		if (d.sfxVolume != null)
			sfxVolume = d.sfxVolume;
		if (d.muted != null)
			muted = d.muted;
		if (d.coins != null)
			coins = d.coins;
		if (d.upgrades != null)
		{
			var u:Array<Int> = d.upgrades;
			for (i in 0...upgrades.length)
				if (i < u.length)
					upgrades[i] = u[i];
		}
		if (d.ownedWeapons != null)
		{
			var w:Array<Int> = d.ownedWeapons;
			for (i in 0...ownedWeapons.length)
				if (i < w.length)
					ownedWeapons[i] = w[i];
		}
		if (d.loadout != null)
			loadout = d.loadout;
		if (d.character != null)
			character = d.character;
		if (d.difficulty != null)
			difficulty = d.difficulty;
		FlxG.sound.muted = muted;
	}

	public static function store():Void
	{
		load();
		save.data.musicVolume = musicVolume;
		save.data.sfxVolume = sfxVolume;
		save.data.muted = muted;
		save.data.character = character;
		save.data.coins = coins;
		save.data.upgrades = upgrades;
		save.data.ownedWeapons = ownedWeapons;
		save.data.loadout = loadout;
		save.data.difficulty = (difficulty : Int);
		save.flush();
	}

	/**
	 * Egy futás vége (game over, kilépés a címképernyőre) vagy egy új futás kezdete: az érmék és a boltban vásárolt fegyverek elvesznek
	 * (újra a pisztoly az alap). A tartós fejlesztések (páncél stb.) megmaradnak. Visszaadja, mi veszett el (a game over képernyőnek).
	 */
	public static function resetRun():{coins:Int, weapons:Bool}
	{
		load();
		var lost = {coins: coins, weapons: false};
		for (i in 0...ownedWeapons.length)
		{
			if (ownedWeapons[i] != 0)
				lost.weapons = true;
			ownedWeapons[i] = 0;
		}
		loadout = 0;
		coins = 0;
		store();
		return lost;
	}

	public static function toggleMute():Void
	{
		muted = !muted;
		FlxG.sound.muted = muted;
		store();
	}

	/** 0 = EASY, 1 = NORMAL, 2 = HARD (a Tiled-objektumok minDifficulty értékéhez). */
	public static function difficultyIndex():Int
	{
		return (difficulty : Int);
	}

	public static function difficultyName(?d:Difficulty):String
	{
		return switch (d != null ? d : difficulty)
		{
			case EASY: "EASY";
			case HARD: "HARD";
			default: "NORMAL";
		}
	}

	// --- A nehézség hatásai (az értékek az assets/config/game.json "difficulty" szakaszából) -----------

	/** Görgetési sebesség. */
	public static function scrollMul():Float
		return pick(Config.scrollMul);

	/** Két doboz közti idő (nagyobb = ritkább). */
	public static function spawnIntervalMul():Float
		return pick(Config.spawnIntervalMul);

	/** A dobozok és a szakadék sebzése. */
	public static function damageMul():Float
		return pick(Config.damageMul);

	/** Jutalomdoboz esélye (%). */
	public static function rewardChance():Float
		return pick(Config.rewardChance);

	/** Szakadék esélyének szorzója. */
	public static function gapMul():Float
		return pick(Config.gapMul);

	/** A konfigurációs tömb (easy, normal, hard) aktuális nehézséghez tartozó eleme. */
	static inline function pick(values:Array<Float>):Float
	{
		return values[(difficulty : Int)];
	}
}
