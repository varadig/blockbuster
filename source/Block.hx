package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/** Fentről potyogó blokk. Zuhanás közben halálos, földet érve akadály lesz, majd szétmorzsolódik. */
class Block extends FlxSprite
{
	static inline var LANDED_LIFETIME:Float = 5;
	static final COLORS = [0xffe8615a, 0xfff2a541, 0xffb46bd6, 0xff6bd68a];

	public var landed(default, null):Bool = false;
	/** Ennyi találat kell, hogy szétlőjük. */
	public var hp:Int = 2;

	var landedTimer:Float = 0;

	public function new()
	{
		super();
	}

	public function spawn(x:Float, y:Float, fallSpeed:Float):Void
	{
		var size = FlxG.random.int(2, 4) * 8;
		makeGraphic(size, size, COLORS[FlxG.random.int(0, COLORS.length - 1)], true);
		// Belső keret, hogy blokknak nézzen ki
		var dark = FlxColor.fromRGB(0, 0, 0, 90);
		for (i in 0...size)
		{
			pixels.setPixel32(i, 0, dark);
			pixels.setPixel32(i, size - 1, dark);
			pixels.setPixel32(0, i, dark);
			pixels.setPixel32(size - 1, i, dark);
		}
		dirty = true;

		reset(x - size / 2, y - size);
		hp = size >= 24 ? 3 : 2;
		alpha = 1;
		landed = false;
		immovable = false;
		velocity.set(0, fallSpeed);
		acceleration.set(0, 500);
		maxVelocity.set(0, 420);
	}

	/** Zuhanó blokk = halálos a játékosra. */
	public function isDangerous():Bool
	{
		return !landed && velocity.y > 40;
	}

	public function land():Void
	{
		if (landed)
			return;
		landed = true;
		landedTimer = LANDED_LIFETIME;
		immovable = true;
		velocity.set(0, 0);
		acceleration.set(0, 0);
		FlxG.camera.shake(0.004, 0.08);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!landed && isTouching(FLOOR))
			land();

		if (landed)
		{
			landedTimer -= elapsed;
			if (landedTimer < 1)
				alpha = 0.3 + 0.7 * Math.max(landedTimer, 0);
			if (landedTimer <= 0)
				kill();
		}

		// Kiesett a pályáról
		if (y > FlxG.camera.scroll.y + FlxG.height + 100)
			kill();
	}
}
