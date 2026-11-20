package;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

/** A játékvezérlő műveletei. */
enum abstract PadAction(Int) to Int
{
	var LEFT = 0;
	var RIGHT = 1;
	var UP = 2;
	var DOWN = 3;
	var JUMP = 4;
	var SHOOT = 5;
	var CHARGE = 6;
	var CONFIRM = 7;
	var BACK = 8;
	var START = 9;
	/** Cheat-menü (csak fejlesztői buildben használja a játék): PS4 R2. */
	var CHEAT = 10;
}

/**
 * Kontroller-támogatás (pl. PS4 / Xbox): a Flixel logikai gombkiosztását használja, így PS4-nél
 * A = Kereszt (X), B = Kör, X = Négyzet, Y = Háromszög.
 *
 * - bal kar / D-pad: mozgás és menü; felfelé: célzás felfelé
 * - Kereszt: ugrás (menüben: választ); Négyzet vagy R1: lövés (nyomva tartva folyamatos);
 *   Kör vagy R2: töltött lövés; Options (START): szünet; Kör: vissza a menüben
 *
 * A Main a minden képkocka elején meghívja a `poll`-t; a "just" állapotok így a billentyűkéhez hasonlóan
 * egy képkockáig igazak. Kontroller nélkül minden hamis.
 */
class Pad
{
	static inline var COUNT:Int = 11;
	static inline var STICK:Float = 0.5;

	static var now:Array<Bool> = [for (_ in 0...COUNT) false];
	static var before:Array<Bool> = [for (_ in 0...COUNT) false];

	/** A "friss" gombnyomások elfogyasztása (állapotváltáskor, pl. menü megnyitásakor): az adott képkockában már nem számítanak újnak. */
	public static function swallow():Void
	{
		for (i in 0...COUNT)
			before[i] = now[i];
	}

	public static function init():Void
	{
		FlxG.signals.preUpdate.add(poll);
	}

	static function pad():Null<FlxGamepad>
	{
		var g = FlxG.gamepads.lastActive;
		if (g != null && g.connected)
			return g;
		g = FlxG.gamepads.firstActive;
		return g != null && g.connected ? g : null;
	}

	static function poll():Void
	{
		for (i in 0...COUNT)
		{
			before[i] = now[i];
			now[i] = false;
		}
		pollPad();
		#if js
		TouchControls.apply(now); // érintős képernyőgombok (mobil böngésző)
		#end
	}

	static function pollPad():Void
	{
		var g = pad();
		if (g == null)
			return;

		var x = g.getXAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
		var y = g.getYAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
		function p(id:FlxGamepadInputID):Bool return g.checkStatus(id, flixel.input.FlxInput.FlxInputState.PRESSED);
		now[LEFT] = x < -STICK || p(FlxGamepadInputID.DPAD_LEFT);
		now[RIGHT] = x > STICK || p(FlxGamepadInputID.DPAD_RIGHT);
		now[UP] = y < -STICK || p(FlxGamepadInputID.DPAD_UP);
		now[DOWN] = y > STICK || p(FlxGamepadInputID.DPAD_DOWN);
		now[JUMP] = p(FlxGamepadInputID.A);
		now[SHOOT] = p(FlxGamepadInputID.X) || p(FlxGamepadInputID.RIGHT_SHOULDER);
		now[CHARGE] = p(FlxGamepadInputID.B);
		now[CHEAT] = p(FlxGamepadInputID.RIGHT_TRIGGER) || p(FlxGamepadInputID.RIGHT_TRIGGER_BUTTON);
		now[CONFIRM] = p(FlxGamepadInputID.A) || p(FlxGamepadInputID.X);
		now[BACK] = p(FlxGamepadInputID.B);
		now[START] = p(FlxGamepadInputID.START);
	}

	/** Le van nyomva (vagy a kar arra áll). */
	public static inline function held(a:PadAction):Bool
		return now[a];

	/** Ebben a képkockában nyomták le (vagy lépett a kar a küszöb fölé). */
	public static inline function just(a:PadAction):Bool
		return now[a] && !before[a];
}
