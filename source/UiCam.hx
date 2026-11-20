package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;

/**
 * A játék közbeni menük (szünet, bolt, beállítások, küldetések, cheat) kamerája: a PlayState HUD-kamerája,
 * amire nem hatnak a módosítók shaderei. Címképernyőről nyitva nincs ilyen kamera, ott a menük a szokásos módon rajzolnak.
 */
class UiCam
{
	public static var cam:Null<FlxCamera>;

	/** A menü ezen a kamerán rajzol (ha van érvényes UI-kamera); a substate `create`-jében hívandó. */
	public static function apply(s:FlxState):Void
	{
		if (cam != null && FlxG.cameras.list.contains(cam))
			s.cameras = [cam];
	}
}
