package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/** Fentről hulló meteor. Zuhanás közben halálos (tűzcsóvát húz), földet érve akadály lesz, majd szétporlad. */
class Block extends FlxSprite
{
	static inline var LANDED_LIFETIME:Float = 5;
	/** Kőszínek: barnásszürke, rozsdás, sötétlila, hamuszürke. */
	static final COLORS:Array<FlxColor> = [0xff6b5a52, 0xff7a4a3a, 0xff5a4a66, 0xff5c5c68];
	/** Zuhanás közbeni tűzcsóva-részecske kérése a PlayState felé (x, y). */
	public static var onTrail:(Float, Float)->Void;
	static inline var FLASH_TIME:Float = 0.06;

	public var landed(default, null):Bool = false;
	/** Ennyi találat kell, hogy szétlőjük. */
	public var hp:Int = 2;
	public var maxHp(default, null):Int = 2;
	/** Alapszín (a törmelék is ezt kapja). */
	public var baseColor(default, null):FlxColor = PixelArt.RED;
	/** Ha nem null, ez egy arany jutalommeteor, és szétlövéskor ezt a bónuszt dobja. */
	public var reward(default, null):Null<PowerUp.PowerKind> = null;

	var landedTimer:Float = 0;
	var flashTimer:Float = 0;
	var glintTimer:Float = 0;
	var trailTimer:Float = 0;

	public function new()
	{
		super();
	}

	public function spawn(x:Float, y:Float, fallSpeed:Float, ?reward:PowerUp.PowerKind):Void
	{
		this.reward = reward;
		// Az arany jutalommeteor legalább közepes méretű, hogy jól látsszon
		var size = (reward != null ? FlxG.random.int(3, 4) : FlxG.random.int(2, 4)) * 8;
		baseColor = reward != null ? 0xffd9a33a : COLORS[FlxG.random.int(0, COLORS.length - 1)];
		loadGraphic(PixelArt.meteor(size, baseColor, reward != null), true, size, size);
		animation.frameIndex = 0;

		reset(x - size / 2, y - size);
		maxHp = size >= 24 ? 3 : 2;
		hp = maxHp;
		flashTimer = 0;
		glintTimer = 0.5;
		setColorTransform();
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

	/** Találat: csökken a hp, rövid fehér villanás, és repedtebb képkocka. */
	public function hit(damage:Int = 1):Void
	{
		hp -= damage;
		if (hp > 0)
			animation.frameIndex = Math.round((maxHp - hp) / (maxHp - 1) * 2);
		flashTimer = FLASH_TIME;
		setColorTransform(1, 1, 1, alpha, 150, 150, 150);
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
		if (isOnScreen())
			Audio.play("thud", 0.45);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform(1, 1, 1, alpha);
		}
		else if (reward != null)
		{
			// Az arany meteor időnként felcsillan
			glintTimer -= elapsed;
			if (glintTimer <= 0)
			{
				glintTimer = 0.9;
				flashTimer = 0.1;
				setColorTransform(1, 1, 1, alpha, 90, 90, 90);
			}
		}

		// Zuhanás közben tűzcsóva (izzó részecskék a meteor mögött, felül)
		if (!landed && velocity.y > 40 && onTrail != null)
		{
			trailTimer -= elapsed;
			if (trailTimer <= 0)
			{
				trailTimer = 0.035;
				onTrail(x + width / 2 + FlxG.random.float(-width / 4, width / 4), y + FlxG.random.float(0, height / 3));
			}
		}

		// A `touching` a FlxObject.update-ben nullázódik, ezért itt (a super.update után) már a `wasTouching`
		// tartalmazza az előző ütközés eredményét. Az isTouching itt mindig hamis lenne.
		if (!landed && wasTouching.has(FLOOR))
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
