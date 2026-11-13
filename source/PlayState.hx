package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	/** A kamera kezdő és maximális automatikus görgetési sebessége (px/s). */
	static inline var SCROLL_START:Float = 60;
	static inline var SCROLL_MAX:Float = 170;
	/** Ennyivel nő a görgetési sebesség másodpercenként. */
	static inline var SCROLL_ACCEL:Float = 1.5;

	static inline var GROUND_Y:Float = 230;
	static inline var BULLET_SPEED:Float = 420;

	var player:Player;
	var ground:FlxTypedGroup<FlxSprite>;
	var blocks:FlxTypedGroup<Block>;
	var bullets:FlxTypedGroup<FlxSprite>;
	var debris:FlxTypedGroup<FlxSprite>;

	var hud:FlxText;
	var gameOverText:FlxText;

	var scrollSpeed:Float = SCROLL_START;
	var nextGroundX:Float = 0;
	var spawnTimer:Float = 1.5;
	var elapsedTotal:Float = 0;
	var blocksDestroyed:Int = 0;
	var dead:Bool = false;

	override public function create():Void
	{
		super.create();
		bgColor = FlxColor.fromRGB(27, 30, 43);

		ground = new FlxTypedGroup<FlxSprite>();
		blocks = new FlxTypedGroup<Block>();
		bullets = new FlxTypedGroup<FlxSprite>();
		debris = new FlxTypedGroup<FlxSprite>();

		add(ground);
		add(blocks);
		add(debris);
		add(bullets);

		// Kezdő biztonságos talaj, aztán generált szakaszok
		addGround(0, 360, GROUND_Y);
		nextGroundX = 360;
		generateGround();

		player = new Player(80, GROUND_Y - 40);
		player.onShoot = shoot;
		add(player);

		hud = new FlxText(6, 4, FlxG.width - 12, "", 8);
		hud.scrollFactor.set(0, 0);
		add(hud);

		gameOverText = new FlxText(0, 100, FlxG.width, "", 16);
		gameOverText.alignment = CENTER;
		gameOverText.scrollFactor.set(0, 0);
		gameOverText.visible = false;
		add(gameOverText);

		#if (js && test)
		// Csak automatikus tesztekhez: a böngészőből elérhető az állapot
		js.Syntax.code("window.__game = {0}", this);
		#end
	}

	override public function update(elapsed:Float):Void
	{
		if (dead)
		{
			super.update(elapsed);
			if (FlxG.keys.anyJustPressed([R, ENTER]))
				FlxG.resetState();
			return;
		}

		elapsedTotal += elapsed;
		scrollSpeed = Math.min(SCROLL_MAX, scrollSpeed + SCROLL_ACCEL * elapsed);
		FlxG.camera.scroll.x += scrollSpeed * elapsed;

		generateGround();
		updateSpawner(elapsed);

		super.update(elapsed);

		// Zuhanó blokk eltalálta a játékost -> vége (az ütközés előtt nézzük)
		FlxG.overlap(player, blocks, (p:Player, b:Block) -> if (b.isDangerous()) die());

		FlxG.collide(player, ground);
		FlxG.collide(blocks, ground);
		FlxG.collide(blocks, blocks);
		FlxG.collide(player, blocks);

		FlxG.overlap(bullets, blocks, onBulletHitBlock);
		FlxG.collide(bullets, ground, (b:FlxSprite, _) -> b.kill());

		// A játékos nem futhat ki a képernyő jobb szélén
		var right = FlxG.camera.scroll.x + FlxG.width - player.width;
		if (player.x > right)
		{
			player.x = right;
			player.velocity.x = Math.min(player.velocity.x, 0);
		}

		// Lemaradt a bal szélen, vagy leesett egy szakadékba
		if (player.x + player.width < FlxG.camera.scroll.x || player.y > FlxG.height + 40)
			die();

		cleanup();
		updateHud();
	}

	// --- Pálya -----------------------------------------------------------

	function addGround(x:Float, w:Float, y:Float, ?h:Float):Void
	{
		var g = ground.recycle(FlxSprite);
		if (h == null)
			h = FlxG.height - y + 40; // a talaj a képernyő aljáig ér
		g.makeGraphic(Std.int(w), Std.int(h), FlxColor.fromRGB(58, 64, 90), true);
		// Világos fűcsík a tetején
		g.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, 3), FlxColor.fromRGB(120, 210, 140));
		g.dirty = true;
		g.reset(x, y);
		g.immovable = true;
	}

	function generateGround():Void
	{
		var limit = FlxG.camera.scroll.x + FlxG.width * 2;
		while (nextGroundX < limit)
		{
			// Szakadék, egyre gyakrabban
			if (FlxG.random.bool(25 + Math.min(elapsedTotal, 60) * 0.5))
				nextGroundX += FlxG.random.int(40, 80);

			var w = FlxG.random.int(10, 30) * 8;
			var y = GROUND_Y - FlxG.random.int(0, 3) * 12;
			addGround(nextGroundX, w, y);

			// Néha egy lebegő platform a szakasz fölött
			if (FlxG.random.bool(35))
				addGround(nextGroundX + FlxG.random.int(0, Std.int(w / 2)), FlxG.random.int(4, 8) * 8, y - FlxG.random.int(50, 70), 8);

			nextGroundX += w;
		}
	}

	// --- Blokkok ----------------------------------------------------------

	function updateSpawner(elapsed:Float):Void
	{
		spawnTimer -= elapsed;
		if (spawnTimer > 0)
			return;

		// Idővel egyre sűrűbben jönnek
		var interval = Math.max(0.35, 1.3 - elapsedTotal * 0.012);
		spawnTimer = FlxG.random.float(interval * 0.6, interval * 1.4);

		// Főleg a játékos előtt potyognak, hogy kerülgetni kelljen
		var x = FlxG.camera.scroll.x + FlxG.random.float(0.35, 1.1) * FlxG.width;
		blocks.recycle(Block, Block.new).spawn(x, FlxG.camera.scroll.y - 10, FlxG.random.float(60, 140));
	}

	function shoot(x:Float, y:Float, dx:Float, dy:Float):Void
	{
		var b = bullets.recycle(FlxSprite);
		if (dy != 0)
			b.makeGraphic(3, 8, FlxColor.YELLOW);
		else
			b.makeGraphic(8, 3, FlxColor.YELLOW);
		b.reset(x - b.width / 2, y - b.height / 2);
		b.velocity.set(dx * BULLET_SPEED + (dx != 0 ? player.velocity.x * 0.5 : 0), dy * BULLET_SPEED);
	}

	function onBulletHitBlock(bullet:FlxSprite, block:Block):Void
	{
		bullet.kill();
		block.hp -= 1;
		block.color = FlxColor.fromRGB(170, 170, 170); // sérült blokk sötétebb
		if (block.hp <= 0)
		{
			spawnDebris(block);
			block.kill();
			blocksDestroyed++;
		}
	}

	function spawnDebris(block:Block):Void
	{
		for (i in 0...6)
		{
			var d = debris.recycle(FlxSprite);
			d.makeGraphic(3, 3, FlxColor.fromRGB(230, 230, 230));
			d.reset(block.x + block.width / 2, block.y + block.height / 2);
			d.velocity.set(FlxG.random.float(-120, 120), FlxG.random.float(-200, -40));
			d.acceleration.y = 600;
			d.alpha = 1;
		}
	}

	// --- Egyéb -------------------------------------------------------------

	function cleanup():Void
	{
		var left = FlxG.camera.scroll.x - 100;
		var right = FlxG.camera.scroll.x + FlxG.width + 100;
		ground.forEachAlive(g -> if (g.x + g.width < left) g.kill());
		bullets.forEachAlive(b -> if (b.x < left || b.x > right || b.y < -20) b.kill());
		debris.forEachAlive(d -> {
			d.alpha -= 0.03;
			if (d.alpha <= 0 || d.y > FlxG.height)
				d.kill();
		});
	}

	function score():Int
	{
		return Std.int(FlxG.camera.scroll.x / 10) + blocksDestroyed * 25;
	}

	function updateHud():Void
	{
		hud.text = 'PONT: ${score()}    BLOKK: $blocksDestroyed    SEBESSEG: ${Std.int(scrollSpeed)}';
	}

	function die():Void
	{
		if (dead)
			return;
		dead = true;
		player.kill();
		FlxG.camera.shake(0.015, 0.3);
		FlxG.camera.flash(FlxColor.RED, 0.2);
		gameOverText.text = 'VEGE!\nPont: ${score()}\n\nR / ENTER: ujra';
		gameOverText.visible = true;
	}
}
