package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/** Ellenségfajták, a megjelenésük sorrendjében. */
enum abstract EnemyKind(Int) to Int
{
	/** A földön ugrálva közeledik. Rá lehet ugrani. */
	var SLIME = 0;
	/** Hullámvonalban repül, a hős közelében lecsap. Rá lehet ugrani. */
	var BAT = 1;
	/** Álló lövegtorony, a hősre lő. */
	var TURRET = 2;
	/** A hős fölött lebeg és bombákat dob, aztán elrepül. */
	var DRONE = 3;
	/** A pók főellenség kicsinyei: követik a hőst a talajon, a csípésük "tipsy" hatást ad. Csak a főellenség hívja (nincs a spawn-listán). */
	var SPIDERLING = 4;
}

class Enemy extends FlxSprite
{
	public var kind(default, null):EnemyKind = SLIME;
	public var hp:Int = 1;
	/** Ráugrással elpusztítható. */
	public var stompable(default, null):Bool = false;
	/** A talajjal ütközik (a repülők nem). */
	public var usesGround(default, null):Bool = false;
	public var contactDamage(default, null):Float = 15;
	public var points(default, null):Int = 50;
	/** A törmelék színe. */
	public var baseColor(default, null):FlxColor = PixelArt.PLUM;

	/** A célpont (a hős). */
	public var target:FlxSprite;
	/** Lövés/bombadobás kérése a PlayState felé: (ellenség, 0 = lövedék, 1 = bomba). */
	public var onFire:(Enemy, Int)->Void;

	/** A slime a hősre tapadt: nem sebez, hanem lassítja, és `Config.slimeStickTime` múlva leesik. */
	public var stuck(default, null):Bool = false;
	/** Egy ráragadt slime lepottyanása (a PlayState fröcskölést rajzol). */
	public static var onDetach:Enemy->Void;

	var life:Float = 0;
	var stuckTimer:Float = 0;
	var stuckSlot:Int = 0;
	var timer:Float = 0;
	var t:Float = 0;
	var baseY:Float = 0;
	var diving:Bool = false;
	var flashTimer:Float = 0;
	var fireFlash:Float = 0;

	public function new()
	{
		super();
	}

	public function spawn(kind:EnemyKind, x:Float, y:Float):Void
	{
		this.kind = kind;
		t = 0;
		diving = false;
		stuck = false;
		flashTimer = 0;
		fireFlash = 0;
		setColorTransform();
		velocity.set(0, 0);
		acceleration.set(0, 0);
		maxVelocity.set(10000, 10000);
		immovable = false;
		flipX = false;

		switch (kind)
		{
			case SLIME:
				loadGraphic(PixelArt.slime(), true, PixelArt.SLIME_W, PixelArt.SLIME_H);
				hp = 2;
				stompable = true;
				usesGround = true;
				contactDamage = 0; // nem sebez: ráragad a hősre és lelassítja
				points = 50;
				baseColor = 0xffb05cd6;
				acceleration.y = 600;
				timer = FlxG.random.float(0.4, 1.2);
			case BAT:
				loadGraphic(PixelArt.bat(), true, PixelArt.BAT_W, PixelArt.BAT_H);
				animation.add("fly", [0, 1], 8);
				animation.play("fly");
				hp = 1;
				stompable = true;
				usesGround = false;
				contactDamage = 12;
				points = 40;
				baseColor = PixelArt.PLUM;
			case TURRET:
				loadGraphic(PixelArt.turret(), true, PixelArt.TURRET_SIZE, PixelArt.TURRET_SIZE);
				hp = 4;
				stompable = false;
				usesGround = true;
				contactDamage = 10;
				points = 80;
				baseColor = PixelArt.GRAY;
				acceleration.y = 600;
				timer = 1.2;
			case SPIDERLING:
				loadGraphic(PixelArt.spiderling(), true, PixelArt.SPIDERLING_W, PixelArt.SPIDERLING_H);
				animation.add("crawl", [0, 1], 10);
				animation.play("crawl");
				hp = 1;
				stompable = true;
				usesGround = true;
				contactDamage = 0; // nem sebez: a csípése ittassá teszi a hőst
				points = 30;
				baseColor = 0xff7a5a44;
				acceleration.y = 600;
				timer = FlxG.random.float(0.4, 1);
				life = 14;
			case DRONE:
				loadGraphic(PixelArt.drone(), true, PixelArt.DRONE_W, PixelArt.DRONE_H);
				animation.add("spin", [0, 1], 16);
				animation.play("spin");
				hp = 5;
				stompable = false;
				usesGround = false;
				contactDamage = 15;
				points = 120;
				baseColor = PixelArt.ORANGE;
				timer = 1.5;
		}
		reset(x, y);
		baseY = y;
		alpha = 1;
	}

	/** Tiled-ben elhelyezett ellenség: a (px, py) a talppont-közép, nem a bal-felső sarok. A spawn() után hívandó. */
	public function place(px:Float, py:Float):Void
	{
		x = px - width / 2;
		y = py - height;
		baseY = y;
	}

	/** Találat: hp csökken, rövid fehér villanás. */
	public function hit(damage:Int):Void
	{
		hp -= damage;
		flashTimer = 0.06;
		setColorTransform(1, 1, 1, 1, 160, 160, 160);
	}

	override public function update(elapsed:Float):Void
	{
		t += elapsed;
		switch (kind)
		{
			case SLIME:
				updateSlime(elapsed);
			case BAT:
				updateBat(elapsed);
			case TURRET:
				updateTurret(elapsed);
			case DRONE:
				updateDrone(elapsed);
			case SPIDERLING:
				updateSpiderling(elapsed);
		}

		super.update(elapsed);

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform();
		}

		// Leesett vagy elrepült a pályáról
		if (y > FlxG.camera.scroll.y + FlxG.height + 60 || y < FlxG.camera.scroll.y - 80)
			kill();
	}

	/** A slime ráragad a hősre (a `slot` a már rajta levők száma, hogy ne egy ponton álljanak). */
	public function attach(hero:FlxSprite, slot:Int):Void
	{
		stuck = true;
		stuckTimer = Config.slimeStickTime;
		stuckSlot = slot;
		target = hero;
		usesGround = false;
		stompable = false;
		velocity.set(0, 0);
		acceleration.set(0, 0);
	}

	/** A pók kicsinye: a talajon a hős felé mászik (mindkét irányba), közelében ugrik; 14 mp után elporlad. */
	function updateSpiderling(dt:Float):Void
	{
		life -= dt;
		if (life <= 0)
		{
			kill();
			return;
		}
		if (isTouching(FLOOR) && target != null)
		{
			var dx = target.x + target.width / 2 - (x + width / 2);
			var dir = dx < 0 ? -1 : 1;
			velocity.x = dir * 72;
			flipX = dir > 0;
			timer -= dt;
			if (timer <= 0 && Math.abs(dx) < 100)
			{
				velocity.y = -150;
				timer = FlxG.random.float(0.8, 1.4);
			}
		}
	}

	function updateSlime(dt:Float):Void
	{
		if (stuck)
		{
			// A hős lábára tapadva utazik; a lejártakor lepottyan és elolvad
			stuckTimer -= dt;
			if (target != null)
			{
				x = target.x + target.width / 2 - width / 2 + (stuckSlot - 1) * 4;
				y = target.y + target.height - height + 2 - stuckSlot * 2;
			}
			animation.frameIndex = Std.int(t * 5) % 2 == 0 ? 1 : 0;
			if (stuckTimer <= 0 || target == null || !target.alive)
			{
				stuck = false;
				if (onDetach != null)
					onDetach(this);
				kill();
			}
			return;
		}
		var onGround = isTouching(FLOOR);
		velocity.x = -55;
		timer -= dt;
		if (onGround && timer <= 0)
		{
			velocity.y = -190;
			timer = FlxG.random.float(0.8, 1.8);
		}
		// A földön összenyomódik, ugrás közben kinyúlik
		animation.frameIndex = onGround && Std.int(t * 4) % 2 == 0 ? 1 : 0;
	}

	function updateBat(dt:Float):Void
	{
		if (!diving)
		{
			velocity.x = -85;
			y = baseY + Math.sin(t * 3) * 20;
			// Ha a hős közel van előtte, lecsap rá
			if (target != null && target.alive && x > target.x && x - target.x < 140)
			{
				diving = true;
				var dx = target.x - x, dy = target.y - y;
				var len = Math.sqrt(dx * dx + dy * dy);
				velocity.set(dx / len * 150, dy / len * 150);
			}
		}
		flipX = velocity.x > 0;
	}

	function updateTurret(dt:Float):Void
	{
		velocity.x = 0;
		if (target != null)
			flipX = target.x > x; // a cső a hős felé néz
		timer -= dt;
		if (timer <= 0 && isOnScreen() && target != null && target.alive)
		{
			timer = 2.4;
			fireFlash = 0.12;
			if (onFire != null)
				onFire(this, 0);
		}
		if (fireFlash > 0)
			fireFlash -= dt;
		animation.frameIndex = fireFlash > 0 ? 1 : 0;
	}

	function updateDrone(dt:Float):Void
	{
		if (t < 12)
		{
			// A hős fölé igyekszik, kicsit lebegve
			var goal = target != null ? target.x + target.width / 2 - width / 2 : x;
			velocity.x = Math.max(-110, Math.min(110, (goal - x) * 1.5 + 60));
			y = baseY + Math.sin(t * 2.5) * 4;
			timer -= dt;
			if (timer <= 0 && isOnScreen())
			{
				timer = 1.6;
				if (onFire != null)
					onFire(this, 1);
			}
		}
		else
		{
			// Lejárt az ideje: felfelé elrepül
			velocity.set(40, -90);
		}
	}
}
