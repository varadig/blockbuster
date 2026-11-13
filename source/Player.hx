package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class Player extends FlxSprite
{
	public static inline var RUN_SPEED:Float = 200;
	public static inline var GRAVITY:Float = 900;
	public static inline var JUMP_SPEED:Float = 330;

	/** Ennyi ideig még ugorhat, miután lelépett a peremről (coyote time). */
	static inline var COYOTE_TIME:Float = 0.08;
	/** Ennyi ideig "emlékszik" a túl korán lenyomott ugrásra (jump buffer). */
	static inline var JUMP_BUFFER:Float = 0.1;
	static inline var SHOOT_COOLDOWN:Float = 0.18;

	var coyoteTimer:Float = 0;
	var jumpBufferTimer:Float = 0;
	var shootTimer:Float = 0;

	/** A PlayState hívja, amikor a játékos lő: (x, y, irányX, irányY). */
	public var onShoot:(Float, Float, Float, Float) -> Void;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		makeGraphic(12, 18, FlxColor.fromRGB(80, 200, 255));
		acceleration.y = GRAVITY;
		maxVelocity.set(RUN_SPEED, 600);
		drag.x = RUN_SPEED * 8;
	}

	override public function update(elapsed:Float):Void
	{
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
		jumpBufferTimer = FlxG.keys.anyJustPressed([SPACE, Z, K]) ? JUMP_BUFFER : jumpBufferTimer - elapsed;

		if (jumpBufferTimer > 0 && coyoteTimer > 0)
		{
			velocity.y = -JUMP_SPEED;
			jumpBufferTimer = 0;
			coyoteTimer = 0;
		}
		// Változó ugrásmagasság: ha elengedi, rövidebb ugrás
		if (velocity.y < 0 && !FlxG.keys.anyPressed([SPACE, Z, K]))
			velocity.y *= 0.85;

		// Lövés: X/J, felfelé nyíllal együtt felfelé lő
		shootTimer -= elapsed;
		if (shootTimer <= 0 && FlxG.keys.anyPressed([X, J]) && onShoot != null)
		{
			shootTimer = SHOOT_COOLDOWN;
			if (up)
				onShoot(x + width / 2, y, 0, -1);
			else
				onShoot(x + width / 2, y + height / 2 - 2, facing == LEFT ? -1 : 1, 0);
		}

		super.update(elapsed);
	}
}
