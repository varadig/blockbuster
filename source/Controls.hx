package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

/** A játék billentyűzettel állítható műveletei (a gamepadet a Pad kezeli). */
enum abstract Action(Int) to Int
{
	var LEFT = 0;
	var RIGHT = 1;
	var UP = 2;
	var DOWN = 3;
	var JUMP = 4;
	var SHOOT = 5;
	var CHARGE = 6;
	var PAUSE = 7;
	var MUTE = 8;
}

/**
 * Billentyűkiosztás: minden művelethez két billentyű rendelhető (pl. A és a balra nyíl), a beállításokban átállítható, és mentve van.
 * Alapkiosztás: mozgás WASD vagy nyilak, ugrás Space vagy Z, lövés J vagy X, töltött lövés L vagy C, szünet P vagy Esc, némítás N.
 * A menük billentyűi (fel/le/balra/jobbra, Enter/Space, Esc) fixek, hogy a kiosztás elállítása után se lehessen kizárni magunkat.
 */
class Controls
{
	public static final ACTIONS:Array<Action> = [LEFT, RIGHT, UP, DOWN, JUMP, SHOOT, CHARGE, PAUSE, MUTE];
	public static final NAMES:Array<String> = [
		"MOVE LEFT", "MOVE RIGHT", "AIM UP", "CROUCH / AIM DOWN", "JUMP", "SHOOT (HOLD)", "CHARGED SHOT (HOLD)", "PAUSE", "MUTE"
	];

	static final DEFAULTS:Array<Array<FlxKey>> = [
		[A, LEFT], [D, RIGHT], [W, UP], [S, DOWN], [SPACE, Z], [J, X], [L, C], [P, ESCAPE], [N, NONE]
	];

	/** Ezeket nem lehet hozzárendelni (a menü és a fejlesztői billentyűk). */
	static final RESERVED:Array<FlxKey> = [ENTER, F9, F10, F11, F12, NONE];

	static var keys:Array<Array<FlxKey>>;
	static var save:FlxSave;

	public static function load():Void
	{
		if (keys != null)
			return;
		keys = [for (r in DEFAULTS) r.copy()];
		save = new FlxSave();
		save.bind("blockbuster_controls");
		var d:Dynamic = save.data.keys;
		if (d != null && Std.isOfType(d, Array))
		{
			var rows:Array<Dynamic> = d;
			for (i in 0...Std.int(Math.min(rows.length, keys.length)))
			{
				var r:Array<Int> = rows[i];
				for (s in 0...2)
					if (r != null && s < r.length)
						keys[i][s] = r[s];
			}
		}
	}

	public static function store():Void
	{
		load();
		save.data.keys = [for (r in keys) [for (k in r) (k : Int)]];
		save.flush();
	}

	/** A művelet két billentyűje (az üres hely FlxKey.NONE). */
	public static function slots(a:Action):Array<FlxKey>
	{
		load();
		return keys[a];
	}

	static function active(a:Action):Array<FlxKey>
	{
		load();
		return [for (k in keys[a]) if (k != NONE) k];
	}

	/** Nyomva tartják-e a művelet valamelyik billentyűjét. */
	public static function held(a:Action):Bool
	{
		var k = active(a);
		return k.length > 0 && FlxG.keys.anyPressed(k);
	}

	/** Épp most nyomták-e le. */
	public static function just(a:Action):Bool
	{
		var k = active(a);
		return k.length > 0 && FlxG.keys.anyJustPressed(k);
	}

	public static function allowed(k:FlxKey):Bool
	{
		return RESERVED.indexOf(k) < 0 && (k : Int) > 0;
	}

	/** Billentyű rövid neve a feliratokhoz. */
	public static function keyName(k:FlxKey):String
	{
		if (k == NONE)
			return "-";
		var n = k.toString();
		return switch (n)
		{
			case "ESCAPE": "ESC";
			case "BACKSPACE": "BKSP";
			case "PAGEUP": "PGUP";
			case "PAGEDOWN": "PGDN";
			case "CONTROL": "CTRL";
			case "ZERO": "0";
			case "ONE": "1";
			case "TWO": "2";
			case "THREE": "3";
			case "FOUR": "4";
			case "FIVE": "5";
			case "SIX": "6";
			case "SEVEN": "7";
			case "EIGHT": "8";
			case "NINE": "9";
			default: n;
		}
	}

	/** A művelet billentyűi szövegesen, pl. "A / LEFT". */
	public static function label(a:Action):String
	{
		var names = [for (k in active(a)) keyName(k)];
		return names.length > 0 ? names.join(" / ") : "-";
	}

	/** A művelet első billentyűje (rövid kijelzéshez). */
	public static function first(a:Action):String
	{
		var k = active(a);
		return k.length > 0 ? keyName(k[0]) : "-";
	}

	/** Billentyű hozzárendelése egy művelet `slot`-jához; ha másik művelet is használta, annak helye üres lesz (nincs ütközés). */
	public static function set(a:Action, slot:Int, key:FlxKey):Void
	{
		load();
		for (r in keys)
			for (s in 0...2)
				if (r[s] == key)
					r[s] = NONE;
		keys[a][slot] = key;
		store();
	}

	public static function clear(a:Action, slot:Int):Void
	{
		load();
		keys[a][slot] = NONE;
		store();
	}

	public static function reset():Void
	{
		load();
		keys = [for (r in DEFAULTS) r.copy()];
		store();
	}
}
