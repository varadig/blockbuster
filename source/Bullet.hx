package;

import flixel.FlxG;
import flixel.FlxSprite;

/** Lövedékfajták. */
enum abstract BulletKind(Int)
{
	/** Sima (pisztoly) lövedék; a töltött változat a maradék sebzésével átüt. */
	var NORMAL = 0;
	/** Lézer: nagyon gyors, minden dobozon és ellenségen átmegy, mindegyiket egyszer sebzi. */
	var LASER = 2;
	/** Rakéta: egyenesen repül, az első találatnál (doboz, ellenség, talaj) robban. */
	var ROCKET = 3;
	/** Gránát: ívben repül, az első találatnál nagy hatósugárban robban. */
	var GRENADE = 4;
}

class Bullet extends FlxSprite
{
	public var damage:Int = 1;
	public var kind:BulletKind = NORMAL;
	/** Robbanó lövedéknél a hatósugár (px) és a töltöttség. */
	public var radius:Float = 0;
	/** Nyomkövető: a PlayState minden képkockában a legközelebbi ellenség felé fordítja. */
	public var homing:Bool = false;
	/** A lövedék kora (mp): a robbanó lövedék biztosítéka ennyi után felrobbantja, hogy ne maradjon a levegőben. */
	public var age:Float = 0;

	/** A lézer által már eltalált dobozok és ellenségek (mindegyiket csak egyszer sebzi). */
	var hitTargets:Array<FlxSprite> = [];

	public function new()
	{
		super();
	}

	/** Közös előkészítés újrahasznosításkor. */
	public function setup(kind:BulletKind, damage:Int, radius:Float = 0):Void
	{
		this.kind = kind;
		this.damage = damage;
		this.radius = radius;
		homing = false;
		age = 0;
		hitTargets.resize(0);
		scale.set(1, 1);
		offset.set(0, 0); // a töltött lövedék updateHitbox-a után újrahasznosítva ne maradjon eltolás
		angle = 0;
		angularVelocity = 0; // a gránát pörgése ne maradjon meg a rakétán (a lövedékek újrahasznosítva vannak)
		alpha = 1;
		drag.set(0, 0);
		acceleration.set(0, 0);
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
		age += elapsed;
		super.update(elapsed);
	}
}
