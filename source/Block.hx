package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * Fentről hulló meteor, 4 méretben (8 / 16 / 24 / 32 px). Zuhanás közben halálos (tűzcsóvát húz), földet érve akadály lesz,
 * majd szétporlad. Az izzó (`hot`) meteor földet érve még egy ideig forró: az érintése sebez.
 */
class Block extends FlxSprite
{
	static inline var LANDED_LIFETIME:Float = 5;
	/** Kőszínek: barnásszürke, rozsdás, sötétlila, hamuszürke. */
	static final COLORS:Array<FlxColor> = [0xff6b5a52, 0xff7a4a3a, 0xff5a4a66, 0xff5c5c68];
	/** Zuhanás közbeni tűzcsóva-részecske kérése a PlayState felé (x, y). */
	public static var onTrail:(Float, Float)->Void;
	static inline var FLASH_TIME:Float = 0.06;
	/** Méretfokozatonként a találatszám (8 / 16 / 24 / 32 px). */
	static final TIER_HP:Array<Int> = [1, 2, 3, 3];
	/** A véletlen méret súlyai (a legkisebb ritkább, mint a többi). */
	static final TIER_WEIGHTS:Array<Float> = [10, 30, 35, 25];
	/** Az izzás kihűlése: az utolsó ennyi másodpercben halványul. */
	static inline var COOL_TIME:Float = 1;

	public var landed(default, null):Bool = false;
	/** Méretfokozat: 0 = 8 px, 1 = 16 px, 2 = 24 px, 3 = 32 px. */
	public var tier(default, null):Int = 1;
	/** Ennyi találat kell, hogy szétlőjük. */
	public var hp:Int = 2;
	public var maxHp(default, null):Int = 2;
	/** Alapszín (a törmelék is ezt kapja). */
	public var baseColor(default, null):FlxColor = PixelArt.RED;
	/** Ha nem null, ez egy arany jutalommeteor, és szétlövéskor ezt a bónuszt dobja. */
	public var reward(default, null):Null<PowerUp.PowerKind> = null;
	/** Izzó meteor: zuhanva vörösen parázslik, földet érve még `Config.hotMeteorTime` ideig forró (érintése sebez). */
	public var hot(default, null):Bool = false;
	/** Egy másik meteoron fekvő meteor legurulási iránya (-1 / +1; 0 = még nincs). */
	public var rollSign:Int = 0;

	var landedTimer:Float = 0;
	var hotTimer:Float = 0;
	var heatClock:Float = 0;
	var flashTimer:Float = 0;
	var glintTimer:Float = 0;
	var trailTimer:Float = 0;

	public function new()
	{
		super();
	}

	/** Új meteor a (x, y) alsó-középpontnál, véletlen méretben; kis eséllyel izzó. */
	public function spawn(x:Float, y:Float, fallSpeed:Float, ?reward:PowerUp.PowerKind, forceHot:Bool = false):Void
	{
		// Az arany jutalommeteor legalább közepes méretű, hogy jól látsszon
		var tier = reward != null ? FlxG.random.int(2, 3) : FlxG.random.weightedPick(TIER_WEIGHTS);
		var hot = forceHot || (reward == null && FlxG.random.bool(Config.hotMeteorChance));
		init(tier, reward, hot);
		reset(x - width / 2, y - height);
		velocity.set(0, fallSpeed);
	}

	function init(tier:Int, reward:Null<PowerUp.PowerKind>, hot:Bool):Void
	{
		this.tier = tier;
		this.reward = reward;
		this.hot = hot;
		var size = (tier + 1) * 8;
		baseColor = reward != null ? 0xffd9a33a : COLORS[FlxG.random.int(0, COLORS.length - 1)];
		loadGraphic(PixelArt.meteor(size, baseColor, reward != null), true, size, size);
		animation.frameIndex = 0;

		maxHp = TIER_HP[tier];
		hp = maxHp;
		flashTimer = 0;
		angle = 0; // újrahasznosításkor ne maradjon elfordulás
		rollSign = 0;
		glintTimer = 0.5;
		hotTimer = 0;
		heatClock = FlxG.random.float(0, 6);
		setColorTransform();
		alpha = 1;
		landed = false;
		immovable = false;
		acceleration.set(0, 500);
		maxVelocity.set(0, 420);
	}

	/** Zuhanó blokk = halálos a játékosra. */
	public function isDangerous():Bool
	{
		return !landed && velocity.y > 40;
	}

	/** Földet ért, de még izzik: az érintése sebez. */
	public function isHot():Bool
	{
		return hot && landed && hotTimer > 0;
	}

	/** Találat: csökken a hp, rövid fehér villanás, és repedtebb képkocka. */
	public function hit(damage:Int = 1):Void
	{
		hp -= damage;
		if (hp > 0 && maxHp > 1)
			animation.frameIndex = Math.round((maxHp - hp) / (maxHp - 1) * 2);
		flashTimer = FLASH_TIME;
		setColorTransform(1, 1, 1, alpha, 150, 150, 150);
	}

	/** Elvették alóla a támaszt: újra zuhan (mint egy frissen hullott meteor, földet érve újra akadály lesz). */
	public function release():Void
	{
		landed = false;
		landedTimer = 0;
		hotTimer = 0;
		immovable = false;
		alpha = 1;
		velocity.set(0, 0);
		acceleration.set(0, 500);
		maxVelocity.set(0, 420);
		// A korábbi ütközés ne érvényesüljön újra (különben rögtön "földet érne")
		touching = flixel.util.FlxDirectionFlags.NONE;
		wasTouching = flixel.util.FlxDirectionFlags.NONE;
	}

	public function land():Void
	{
		if (landed)
			return;
		landed = true;
		landedTimer = LANDED_LIFETIME;
		if (hot)
		{
			hotTimer = Config.hotMeteorTime;
			landedTimer += hotTimer;
		}
		immovable = true;
		velocity.set(0, 0);
		acceleration.set(0, 0);
		FlxG.camera.shake(tier == 0 ? 0.002 : 0.004, 0.08);
		if (isOnScreen())
			Audio.play("thud", tier == 0 ? 0.3 : 0.45);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Gördülés: a talajon (pl. mágnes hatására) vízszintesen mozgó meteor a mozgása irányába forog, a kerületi sebességnek megfelelően
		// (a szög = megtett út / sugár); a levegőben mozgó (mágnesezett) meteor lassabban pörög
		if (Math.abs(velocity.x) > 0.5)
			angle += velocity.x / Math.max(4, width / 2) * 57.2958 * elapsed * (landed ? 1 : 0.4);

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

		if (hot && flashTimer <= 0)
			updateHeat(elapsed);

		// Zuhanás közben tűzcsóva (izzó részecskék a meteor mögött, felül)
		if (!landed && velocity.y > 40 && onTrail != null)
		{
			trailTimer -= elapsed;
			if (trailTimer <= 0)
			{
				trailTimer = Perf.lite ? 0.08 : 0.045;
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

	/** Az izzás megjelenítése: zuhanva enyhe vörös parázs, földön lüktető narancs fény, ami a végén kihűl; közben szikrák szállnak. */
	function updateHeat(dt:Float):Void
	{
		heatClock += dt;
		var heat = 0.35;
		if (landed)
		{
			hotTimer = Math.max(0, hotTimer - dt);
			heat = Math.min(1, hotTimer / COOL_TIME);
			if (onTrail != null && hotTimer > 0 && FlxG.random.bool(Math.min(1, dt * 5) * 100))
				onTrail(x + FlxG.random.float(2, Math.max(3, width - 2)), y + 1);
		}
		var pulse = 0.75 + 0.25 * Math.sin(heatClock * 10);
		var h = heat * pulse;
		setColorTransform(1, 1 - 0.25 * heat, 1 - 0.5 * heat, alpha, 120 * h, 50 * h, 0);
		if (landed && hotTimer <= 0)
		{
			hot = false;
			setColorTransform(1, 1, 1, alpha);
		}
	}
}
