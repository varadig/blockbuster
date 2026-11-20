package;

import flixel.FlxG;
import flixel.FlxSprite;
import Characters.CharDef;
import flixel.input.keyboard.FlxKey;

class Player extends FlxSprite
{
	// A hangolható értékek a Config-ból jönnek (assets/config/game.json)
	public static var RUN_SPEED(get, never):Float;
	public static var GRAVITY(get, never):Float;
	public static var JUMP_SPEED(get, never):Float;
	public static var SHOOT_COOLDOWN(get, never):Float;
	public static var MAX_ENERGY(get, never):Float;

	static inline function get_RUN_SPEED():Float return Config.runSpeed;
	static inline function get_GRAVITY():Float return Config.gravity;
	static inline function get_JUMP_SPEED():Float return Config.jumpSpeed;
	static inline function get_SHOOT_COOLDOWN():Float return Config.shootCooldown;
	static inline function get_MAX_ENERGY():Float return Config.maxEnergy;

	/** Ennyi ideig még ugorhat, miután lelépett a peremről (coyote time). */
	static inline var COYOTE_TIME:Float = 0.08;
	/** Ennyi ideig "emlékszik" a túl korán lenyomott ugrásra (jump buffer). */
	static inline var JUMP_BUFFER:Float = 0.1;

	/** cos(45°): az átlós lövés irányvektorának komponense. */
	static inline var DIAGONAL:Float = 0.70710678;


	/** A választott karakter (Settings.character). */
	public var def:CharDef;

	/** A karakter legnagyobb energiája. */
	public var maxEnergy:Float = MAX_ENERGY;

	/** Energia: sérüléskor csökken, 0-nál vége a játéknak (nem a deprecated FlxObject.health). */
	public var energy:Float = MAX_ENERGY;

	/** A futás legnagyobb sebessége (a karakter szorzójával). */
	public var runSpeed:Float = Config.runSpeed;

	/** Guggolás: a hitbox ennyiszeresére alacsonyodik, a lövés alacsonyan indul, a mozgás lassabb. */
	static inline var CROUCH_K:Float = 0.55;
	static inline var CROUCH_SPEED:Float = 0.45;

	/** Ittas ingadozás erőssége (0 = nincs, 1 = legerősebb); a PlayState állítja a pókcsípések száma szerint. */
	public var tipsy:Float = 0;
	var tipsyClock:Float = 0;

	/** Guggol-e (lefelé nyíl a földön). */
	public var crouching(default, null):Bool = false;

	/** A PlayState adja: van-e fölöttünk elég hely a felálláshoz (különben a hős guggolva marad, pl. alacsony mennyezet alatt). */
	public var canStand:() -> Bool;

	/** Lassítás szorzója (1 = normál); a PlayState állítja minden képkockában a ráragadt slime-ok szerint. */
	public var speedMul:Float = 1;

	/** A lövés töltöttsége: 0 = nincs töltés, különben 0.2 (alig töltött) .. 1 (teljesen feltöltve). */
	public var charge:Float = 0;

	/** A töltés sebességének szorzója (a PlayState állítja: RAPID gyorsít). */
	public var chargeBoost:Float = 1;

	/** A torkolat helye és a lövés iránya (minden képkockában frissül; a töltésjelző is ide rajzol). */
	public var aimX:Float = 0;
	public var aimY:Float = 0;
	public var aimDX:Float = 1;
	public var aimDY:Float = 0;

	/** Sérülés utáni rövid sérthetetlenség hátralévő ideje (valós mp). */
	public var hurtTimer:Float = 0;

	/** Két lövés közti idő; a gyorstüzelés bónusz csökkenti. */
	public var shootCooldown:Float = SHOOT_COOLDOWN;

	var coyoteTimer:Float = 0;
	var jumpBufferTimer:Float = 0;
	var shootTimer:Float = 0;
	/** A lövés gombja le van nyomva, és a töltés fut (a gombnyomás pillanatában indul). */
	var charging:Bool = false;
	var held:Float = 0;

	var wasOnGround:Bool = false;

	/** A PlayState hívja, amikor a játékos lő: (x, y, irányX, irányY, töltöttség). Töltöttség 0 = sima lövés. */
	public var onShoot:(Float, Float, Float, Float, Float) -> Void;

	/** Futás közben a lábak mögé szálló por és sebességcsíkok: (x, y a talpnál, mozgásirány -1/1, sebesség 0..1, fékezés-e). */
	public var onRun:(Float, Float, Float, Float, Bool) -> Void;

	var runTimer:Float = 0;

	/** Porfelhő ugráskor és földet éréskor: (x, y) a lábaknál. */
	public var onDust:(Float, Float) -> Void;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		def = Characters.current();
		maxEnergy = MAX_ENERGY * Upgrades.energyMul();
		energy = maxEnergy;
		runSpeed = Config.runSpeed * def.speed;
		loadGraphic(PixelArt.player(def.skin), true, PixelArt.PLAYER_W, PixelArt.PLAYER_H);
		animation.add("idle", [0], 1);
		animation.add("run", [1, 2, 3, 4], 12);
		animation.add("jump", [5], 1);
		animation.add("fall", [6], 1);
		animation.play("idle");
		setFacingFlip(LEFT, true, false);
		setFacingFlip(RIGHT, false, false);

		// A hitbox kisebb, mint a rajz (12x18), a lábak alul illeszkednek; a nagyítás a talpközéppont körül történik
		origin.set(PixelArt.PLAYER_W / 2, PixelArt.PLAYER_H);
		width = 12;
		height = 18;
		width = 12;
		height = 18;
		applySize(1);

		acceleration.y = GRAVITY;
		maxVelocity.set(runSpeed, 600);
		drag.x = runSpeed * 8 * def.friction;
	}

	/** A hős mérete (1 = normál; kisebb = összezsugorított hős). A talp pontja helyben marad. */
	public var sizeScale(default, null):Float = 1;

	/**
	 * Méretezés: a hitbox (12x18) és a rajz is `s`-szeresére változik a talpközéppont körül.
	 * A rajz alja egybeesik a hitbox aljával, ezért az offset = (rajz-közép - hitbox-közép, rajzmagasság - hitboxmagasság).
	 */
	public function applySize(s:Float):Void
	{
		var oldW = width, oldH = height;
		sizeScale = s;
		// Guggolva a hitbox alacsonyabb és a rajz összenyomódik (a talp pontja közben nem mozdul)
		var k = crouching ? CROUCH_K : 1;
		scale.set(s * (crouching ? 1.08 : 1), s * k);
		width = 12 * s;
		height = 18 * s * k;
		offset.set(PixelArt.PLAYER_W / 2 - width / 2, PixelArt.PLAYER_H - height);
		if (oldW > 0)
		{
			// A talp ugyanott marad: a hitbox alja és közepe nem mozdul
			x += (oldW - width) / 2;
			y += oldH - height;
		}
	}

	/** A bolt fejlesztései (energia) érvénybe lépnek; a megnövekedett rész rögtön betelik. */
	public function applyUpgrades():Void
	{
		var m = MAX_ENERGY * Upgrades.energyMul();
		energy += Math.max(0, m - maxEnergy);
		maxEnergy = m;
	}

	override public function update(elapsed:Float):Void
	{
		// A lassítás (FlxG.timeScale) csak a környezetre hat: a játékos valós időben mozog
		elapsed /= FlxG.timeScale;
		if (hurtTimer > 0)
			hurtTimer -= elapsed;

		var left = Controls.held(LEFT) || Pad.held(LEFT);
		var right = Controls.held(RIGHT) || Pad.held(RIGHT);
		var up = Controls.held(UP) || Pad.held(UP);

		// A sebességhatár és a fékezés a pillanatnyi futási sebességhez igazodik (a ráragadt slime lassít)
		// Guggolás: lefelé nyíl a földön (az ugrás kilép belőle); felállni csak akkor lehet, ha van fölöttünk hely
		var wantCrouch = isTouching(FLOOR) && (Controls.held(DOWN) || Pad.held(DOWN)) && !up;
		if (wantCrouch != crouching && (wantCrouch || !isTouching(FLOOR) || canStand == null || canStand()))
		{
			crouching = wantCrouch;
			applySize(sizeScale);
		}

		var spd = runSpeed * speedMul * (crouching ? CROUCH_SPEED : 1);
		if (tipsy > 0)
			tipsyClock += elapsed;
		maxVelocity.x = spd;
		drag.x = spd * 8 * def.friction;

		acceleration.x = 0;
		if (left && !right)
		{
			acceleration.x = -spd * 10;
			facing = LEFT;
		}
		else if (right && !left)
		{
			acceleration.x = spd * 10;
			facing = RIGHT;
		}

		// Tipsy (pókcsípés): a hőst ide-oda sodorja az ingadozás, annál erősebben, minél több csípés van rajta
		if (tipsy > 0)
			acceleration.x += Math.sin(tipsyClock * 2.6 + Math.sin(tipsyClock * 0.9) * 2) * tipsy * spd * 6;

		// Ugrás coyote time-mal és bufferrel, hogy pontosnak érződjön
		var onGround = isTouching(FLOOR);
		coyoteTimer = onGround ? COYOTE_TIME : coyoteTimer - elapsed;
		jumpBufferTimer = Controls.just(JUMP) || Pad.just(JUMP) ? JUMP_BUFFER : jumpBufferTimer - elapsed;

		if (onGround && !wasOnGround && onDust != null)
		{
			onDust(x + width / 2, y + height);
			Audio.play("land", 0.7);
		}
		wasOnGround = onGround;

		if (jumpBufferTimer > 0 && coyoteTimer > 0)
		{
			velocity.y = -JUMP_SPEED * def.jump;
			jumpBufferTimer = 0;
			coyoteTimer = 0;
			Audio.play("jump");
			if (onDust != null)
				onDust(x + width / 2, y + height);
		}
		// Változó ugrásmagasság: ha elengedi, rövidebb ugrás
		if (velocity.y < 0 && !Controls.held(JUMP) && !Pad.held(JUMP))
			velocity.y *= 0.85;

		// Célzás: előre; felfelé nyíllal felfelé; felfelé + előre nyíllal 45 fokban átlósan;
		// a levegőben lefelé nyíllal lefelé, lefelé + előre nyíllal 45 fokban átlósan lefelé
		var dir = facing == LEFT ? -1 : 1;
		var down = !onGround && !up && (Controls.held(DOWN) || Pad.held(DOWN));
		if (down && left != right)
		{
			aimX = x + width / 2 + dir * 4;
			aimY = y + height - 3;
			aimDX = dir * DIAGONAL;
			aimDY = DIAGONAL;
		}
		else if (down)
		{
			aimX = x + width / 2;
			aimY = y + height;
			aimDX = 0;
			aimDY = 1;
		}
		else if (up && left != right)
		{
			aimX = x + width / 2 + dir * 4;
			aimY = y + 3;
			aimDX = dir * DIAGONAL;
			aimDY = -DIAGONAL;
		}
		else if (up)
		{
			aimX = x + width / 2;
			aimY = y;
			aimDX = 0;
			aimDY = -1;
		}
		else
		{
			aimX = x + width / 2;
			// Guggolva a lövés a talajhoz közel indul: az alacsony tárgyakat (kis meteor, slime) is eltalálja
			aimY = crouching ? y + height - 3 : y + height / 2 - 2;
			aimDX = dir;
			aimDY = 0;
		}

		// Lövés: a lövés gombja (Controls.SHOOT) nyomva tartva folyamatos sorozat; a töltés gombja (CHARGE) nyomva tartva tölt, és a
		// felengedéskor egyetlen, nagyobb tűzerejű lövés megy ki. Az irányt a lövés pillanatában választjuk.
		shootTimer -= elapsed;
		if (shootTimer <= 0 && !charging && (Controls.held(SHOOT) || Pad.held(SHOOT)) && onShoot != null)
		{
			shootTimer = shootCooldown;
			onShoot(aimX, aimY, aimDX, aimDY, 0);
		}
		if (Controls.just(CHARGE) || Pad.just(CHARGE))
		{
			charging = true;
			held = 0;
		}
		if (charging)
		{
			if (Controls.held(CHARGE) || Pad.held(CHARGE))
			{
				held += elapsed;
				var full = Config.chargeTime / chargeBoost;
				charge = held < Config.chargeMin ? 0 : Math.min(1, 0.2 + 0.8 * (held - Config.chargeMin) / full);
			}
			else
			{
				if (charge > 0 && onShoot != null)
				{
					shootTimer = Math.max(shootTimer, shootCooldown);
					onShoot(aimX, aimY, aimDX, aimDY, charge);
				}
				charging = false;
				charge = 0;
				held = 0;
			}
		}

		// Futás- és fékezésnyom: por a lábak mögött; fékezéskor (csúszás) sűrűbben
		runTimer -= elapsed;
		if (onGround && onRun != null && runTimer <= 0)
		{
			var speedNow = Math.abs(velocity.x);
			var braking = speedNow > 90 && (acceleration.x == 0 || acceleration.x * velocity.x < 0);
			if (speedNow > 40)
			{
				runTimer = braking ? 0.03 : 0.075;
				onRun(x + width / 2, y + height, velocity.x < 0 ? -1 : 1, Math.min(1, speedNow / (runSpeed * speedMul)), braking);
			}
		}

		// Animáció a mozgásállapot szerint
		if (!onGround)
			animation.play(velocity.y < 0 ? "jump" : "fall");
		else if (crouching)
			animation.play("idle");
		else if (Math.abs(velocity.x) > 20)
			animation.play("run");
		else
			animation.play("idle");

		super.update(elapsed);
	}
}
