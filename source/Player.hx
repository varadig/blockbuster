package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;

class Player extends FlxSprite
{
	public static inline var RUN_SPEED:Float = 200;
	public static inline var GRAVITY:Float = 900;
	public static inline var JUMP_SPEED:Float = 330;

	/** Ennyi ideig még ugorhat, miután lelépett a peremről (coyote time). */
	static inline var COYOTE_TIME:Float = 0.08;
	/** Ennyi ideig "emlékszik" a túl korán lenyomott ugrásra (jump buffer). */
	static inline var JUMP_BUFFER:Float = 0.1;
	public static inline var SHOOT_COOLDOWN:Float = 0.18;

	/** cos(45°): az átlós lövés irányvektorának komponense. */
	static inline var DIAGONAL:Float = 0.70710678;

	/** Ugrás: Alt (Z/K tartalék); lövés: Space (X/J tartalék). */
	public static final JUMP_KEYS:Array<FlxKey> = [ALT, Z, K];
	public static final SHOOT_KEYS:Array<FlxKey> = [SPACE, X, J];

	public static inline var MAX_ENERGY:Float = 100;

	/** Energia: sérüléskor csökken, 0-nál vége a játéknak (nem a deprecated FlxObject.health). */
	public var energy:Float = MAX_ENERGY;

	/** Sérülés utáni rövid sérthetetlenség hátralévő ideje (valós mp). */
	public var hurtTimer:Float = 0;

	/** Két lövés közti idő; a gyorstüzelés bónusz csökkenti. */
	public var shootCooldown:Float = SHOOT_COOLDOWN;

	var coyoteTimer:Float = 0;
	var jumpBufferTimer:Float = 0;
	var shootTimer:Float = 0;

	var wasOnGround:Bool = false;

	/** A PlayState hívja, amikor a játékos lő: (x, y, irányX, irányY). */
	public var onShoot:(Float, Float, Float, Float) -> Void;

	/** Porfelhő ugráskor és földet éréskor: (x, y) a lábaknál. */
	public var onDust:(Float, Float) -> Void;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic(PixelArt.player(), true, PixelArt.PLAYER_W, PixelArt.PLAYER_H);
		animation.add("idle", [0], 1);
		animation.add("run", [1, 2, 3, 4], 12);
		animation.add("jump", [5], 1);
		animation.add("fall", [6], 1);
		animation.play("idle");
		setFacingFlip(LEFT, true, false);
		setFacingFlip(RIGHT, false, false);

		// A hitbox kisebb, mint a rajz (12x18), a lábak alul illeszkednek
		width = 12;
		height = 18;
		offset.set(2, 2);

		acceleration.y = GRAVITY;
		maxVelocity.set(RUN_SPEED, 600);
		drag.x = RUN_SPEED * 8;
	}

	override public function update(elapsed:Float):Void
	{
		// A lassítás (FlxG.timeScale) csak a környezetre hat: a játékos valós időben mozog
		elapsed /= FlxG.timeScale;
		if (hurtTimer > 0)
			hurtTimer -= elapsed;

		var left = FlxG.keys.anyPressed([LEFT, A]);
		var right = FlxG.keys.anyPressed([RIGHT, D]);
		var up = FlxG.keys.anyPressed([UP, W]);

		acceleration.x = 0;
		if (left && !right)
		{
			acceleration.x = -RUN_SPEED * 10;
			facing = LEFT;
		}
		else if (right && !left)
		{
			acceleration.x = RUN_SPEED * 10;
			facing = RIGHT;
		}

		// Ugrás coyote time-mal és bufferrel, hogy pontosnak érződjön
		var onGround = isTouching(FLOOR);
		coyoteTimer = onGround ? COYOTE_TIME : coyoteTimer - elapsed;
		jumpBufferTimer = FlxG.keys.anyJustPressed(JUMP_KEYS) ? JUMP_BUFFER : jumpBufferTimer - elapsed;

		if (onGround && !wasOnGround && onDust != null)
		{
			onDust(x + width / 2, y + height);
			Audio.play("land", 0.7);
		}
		wasOnGround = onGround;

		if (jumpBufferTimer > 0 && coyoteTimer > 0)
		{
			velocity.y = -JUMP_SPEED;
			jumpBufferTimer = 0;
			coyoteTimer = 0;
			Audio.play("jump");
			if (onDust != null)
				onDust(x + width / 2, y + height);
		}
		// Változó ugrásmagasság: ha elengedi, rövidebb ugrás
		if (velocity.y < 0 && !FlxG.keys.anyPressed(JUMP_KEYS))
			velocity.y *= 0.85;

		// Lövés: előre; felfelé nyíllal felfelé; felfelé + előre nyíllal 45 fokban átlósan
		shootTimer -= elapsed;
		if (shootTimer <= 0 && FlxG.keys.anyPressed(SHOOT_KEYS) && onShoot != null)
		{
			shootTimer = shootCooldown;
			var dir = facing == LEFT ? -1 : 1;
			if (up && left != right)
				onShoot(x + width / 2 + dir * 4, y + 3, dir * DIAGONAL, -DIAGONAL);
			else if (up)
				onShoot(x + width / 2, y, 0, -1);
			else
				onShoot(x + width / 2, y + height / 2 - 2, dir, 0);
		}

		// Animáció a mozgásállapot szerint
		if (!onGround)
			animation.play(velocity.y < 0 ? "jump" : "fall");
		else if (Math.abs(velocity.x) > 20)
			animation.play("run");
		else
			animation.play("idle");

		super.update(elapsed);
	}
}
