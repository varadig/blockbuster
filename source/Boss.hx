package;

import flixel.FlxG;
import flixel.FlxSprite;

/**
 * Főellenség (anyahajó): a pálya küldetéseinek teljesítése után érkezik, amikor a kamera megáll.
 * A képernyő felső részén lebeg, és felváltva támad: meteorokat ejt, legyezőben lő, a második fázisban
 * (fél életerő alatt) denevéreket is hív, és gyorsabban támad. Pályánként erősebb.
 */
class Boss extends FlxSprite
{
	public var hp:Float;
	public var maxHp(default, null):Float;
	public var title(default, null):String = "MOTHERSHIP";
	/** Érkezés közben (beúszik jobbról) nem sebezhető. */
	public var entering(default, null):Bool = true;
	public var contactDamage(default, null):Float = 25;

	/** Támadás kérése a PlayState felé: 0 = meteorok, 1 = legyezőlövés, 2 = denevérek. */
	public var onAttack:(Boss, Int)->Void;

	var t:Float = 0;
	var attackTimer:Float = 2;
	var attackIndex:Int = 0;
	var flashTimer:Float = 0;
	var level:Int;

	public function new(level:Int)
	{
		super();
		this.level = level;
		loadGraphic(PixelArt.boss(), true, PixelArt.BOSS_W, PixelArt.BOSS_H);
		animation.add("lights", [0, 1], 4);
		animation.play("lights");
		maxHp = hp = 90 + level * 50;
		// Beúszik a képernyő jobb széléről
		x = FlxG.camera.scroll.x + FlxG.width + 10;
		y = 30;
	}

	public function isPhase2():Bool
	{
		return hp < maxHp / 2;
	}

	public function hit(damage:Float):Void
	{
		if (entering)
			return;
		hp -= damage;
		flashTimer = 0.06;
		setColorTransform(1, 1, 1, 1, 150, 150, 150);
	}

	override public function update(elapsed:Float):Void
	{
		var left = FlxG.camera.scroll.x;
		var homeX = left + FlxG.width * 0.62 - width / 2;
		if (entering)
		{
			x -= 90 * elapsed;
			if (x <= homeX)
			{
				x = homeX;
				entering = false;
			}
		}
		else
		{
			t += elapsed * (isPhase2() ? 1.4 : 1);
			// Lebegés a képernyő jobb kétharmadán, nyolcas-szerű pályán
			x = homeX + Math.sin(t * 0.8) * 130;
			y = 30 + Math.sin(t * 1.7) * 12;

			attackTimer -= elapsed;
			if (attackTimer <= 0)
			{
				attackTimer = isPhase2() ? 1.05 : 1.7;
				// Támadási sorrend: meteor, lövés, meteor, lövés, (2. fázisban) denevérek
				var pattern = isPhase2() ? [0, 1, 0, 1, 2] : [0, 1];
				var a = pattern[attackIndex % pattern.length];
				attackIndex++;
				if (onAttack != null)
					onAttack(this, a);
			}
		}

		super.update(elapsed);

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform();
		}
	}
}
