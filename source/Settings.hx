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

/** Játékbeállítások (hangerők, némítás, nehézség) tartós mentéssel. */
class Settings
{
	public static var musicVolume:Float = 0.7;
	public static var sfxVolume:Float = 0.8;
	public static var muted:Bool = false;
	public static var difficulty:Difficulty = NORMAL;

	static var save:FlxSave;

	public static function load():Void
	{
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
		save.data.difficulty = (difficulty : Int);
		save.flush();
	}

	public static function toggleMute():Void
	{
		muted = !muted;
		FlxG.sound.muted = muted;
		store();
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

	// --- A nehézség hatásai (szorzók a NORMAL-hoz képest) ---------------------------

	/** Görgetési sebesség. */
	public static function scrollMul():Float
		return pick(0.85, 1, 1.18);

	/** Két doboz közti idő (nagyobb = ritkább). */
	public static function spawnIntervalMul():Float
		return pick(1.35, 1, 0.75);

	/** A dobozok és a szakadék sebzése. */
	public static function damageMul():Float
		return pick(0.6, 1, 1.4);

	/** Jutalomdoboz esélye (%). */
	public static function rewardChance():Float
		return pick(16, 12, 9);

	/** Szakadék esélyének szorzója. */
	public static function gapMul():Float
		return pick(0.7, 1, 1.25);

	static inline function pick(easy:Float, normal:Float, hard:Float):Float
	{
		return switch (difficulty)
		{
			case EASY: easy;
			case HARD: hard;
			default: normal;
		}
	}
}
