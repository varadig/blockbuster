package;

import flixel.FlxG;
import flixel.FlxSprite;

/** Szétlőtt meteorból / ellenségből kipattanó érme: a talajon pattog, közelről a hős felé szívódik, idővel eltűnik. */
class Coin extends FlxSprite
{
	static inline var LIFETIME:Float = 9;
	static inline var MAGNET_RANGE:Float = 44;
	static inline var MAGNET_SPEED:Float = 170;

	/** A hős (a PlayState állítja be): a közeli érméket maga felé húzza. */
	public static var target:FlxSprite;

	var life:Float = 0;

	public function new()
	{
		super();
		loadGraphic(PixelArt.coin(), true, 8, 8);
		animation.add("spin", [0, 1, 2, 3], 10);
		elasticity = 0.45;
	}

	public function spawn(cx:Float, cy:Float):Void
	{
		reset(cx - 4, cy - 4);
		velocity.set(FlxG.random.float(-70, 70), FlxG.random.float(-210, -120));
		acceleration.y = 600;
		maxVelocity.y = 400;
		life = LIFETIME;
		alpha = 1;
		animation.play("spin", false, false, FlxG.random.int(0, 3));
	}

	override public function update(elapsed:Float):Void
	{
		// A lassítás a hős érméit sem lassítja
		elapsed /= FlxG.timeScale;
		super.update(elapsed);

		if (target != null && target.alive)
		{
			var dx = target.x + target.width / 2 - (x + 4);
			var dy = target.y + target.height / 2 - (y + 4);
			var d = Math.sqrt(dx * dx + dy * dy);
			if (d < MAGNET_RANGE && d > 0.5)
			{
				velocity.set(dx / d * MAGNET_SPEED, dy / d * MAGNET_SPEED);
				acceleration.y = 0;
			}
			else
				acceleration.y = 600;
		}

		life -= elapsed;
		// A vége előtt villog
		alpha = life < 2 ? (Std.int(life * 10) % 2 == 0 ? 1 : 0.3) : 1;
		if (life <= 0 || y > FlxG.height + 40)
			kill();
	}
}
