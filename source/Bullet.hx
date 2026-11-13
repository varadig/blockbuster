package;

import flixel.FlxG;
import flixel.FlxSprite;

/** Lövedékfajták (a halálsugár nem lövedék, hanem azonnali sugár – lásd PlayState.fireDeathRay). */
enum abstract BulletKind(Int)
{
	/** Sima lövedék; a nehéz változat a maradék sebzésével átüt. */
	var NORMAL = 0;
	/** Lángrészecske: rövid élet, nő és elhalványul, találatkor elég. */
	var FLAME = 1;
	/** Lézer: nagyon gyors, minden dobozon és ellenségen átmegy, mindegyiket egyszer sebzi. */
	var LASER = 2;
}

class Bullet extends FlxSprite
{
	public var damage:Int = 1;
	public var kind:BulletKind = NORMAL;

	/** Hátralévő élettartam (valós mp); negatív = korlátlan. */
	var life:Float = -1;
	var maxLife:Float = 1;
	var maxScale:Float = 1;
	/** A lézer által már eltalált dobozok és ellenségek (mindegyiket csak egyszer sebzi). */
	var hitTargets:Array<FlxSprite> = [];

	public function new()
	{
		super();
	}

	/** Közös előkészítés újrahasznosításkor. */
	public function setup(kind:BulletKind, damage:Int, life:Float = -1, maxScale:Float = 1):Void
	{
		this.kind = kind;
		this.damage = damage;
		this.life = life;
		this.maxLife = life;
		this.maxScale = maxScale;
		hitTargets.resize(0);
		scale.set(1, 1);
		alpha = 1;
		drag.set(0, 0);
	}

	/** A lézer ezt a célt még nem sebezte (és mostantól sebzettnek jelöli). */
	public function firstHitOn(target:FlxSprite):Bool
	{
		if (hitTargets.contains(target))
			return false;
		hitTargets.push(target);
		return true;
	}

	override public function update(elapsed:Float):Void
	{
		// A játékos lövedékei sem lassulnak a lassítás alatt
		elapsed /= FlxG.timeScale;
		super.update(elapsed);

		if (life >= 0)
		{
			life -= elapsed;
			if (life <= 0)
			{
				kill();
				return;
			}
			if (kind == FLAME)
			{
				// Az élet előrehaladtával: izzó mag -> sárga -> narancs -> füst, közben nő és halványul
				var t = 1 - life / maxLife;
				animation.frameIndex = Std.int(Math.min(3, t * 4));
				var s = 1 + (maxScale - 1) * t;
				scale.set(s, s);
				alpha = t < 0.6 ? 1 : 1 - (t - 0.6) / 0.4;
			}
		}
	}
}
