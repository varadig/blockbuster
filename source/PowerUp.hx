package;

import flixel.FlxG;
import flixel.FlxSprite;

/** A bónuszok és módosítók fajtái. */
enum PowerKind
{
	// Fegyver-kiegészítők (egymásra rakódnak, minden alapfegyverre hatnak)
	SPREAD; // hármas szórólövés
	RAPID; // sorozatlövő: gyorsabb tüzelés az aktuális fegyverrel
	HOMING; // nyomkövető: a lövedékek a legközelebbi ellenség felé kanyarodnak
	// Alapfegyverek (egyszerre egy; az alap a pisztoly: egylövetű, nincs saját bónusza)
	ROCKET; // rakétavető: becsapódáskor robban
	LASER; // lézer: nagyon gyors lövedék, ami minden dobozon és ellenségen átmegy
	GRENADE; // gránát: ívben repül, becsapódáskor nagy hatósugárban robban
	// Egyszeri bónuszok
	BONUS; // extra pont
	ENERGY; // energia visszatöltése
	// Módosítók: időkorlátos, a hőst nehezítő hatások (a talajon fekvő tárgyak; a konfigban állíthatók)
	SHROOM; // varázsgomba: hallucináció
	PIXEL; // pixelesítés: nagyobb pixelek
	TORCH; // zseblámpa: csak a hős környéke látszik
	GHOST; // láthatatlan hős
	TINYVIEW; // összezsugorított látómező
	TINYHERO; // összezsugorított hős
	MAGNET; // az ellenfelek (meteorok, lövedékek) lassan követik a hőst
	ASCII; // ASCII-mód: pixelek helyett színhelyes betűk/jelek
}

/** Felvehető bónusz: kipattan a szétlőtt dobozból, leesik a földre, és egy ideig ott marad. */
class PowerUp extends FlxSprite
{
	static inline var LIFETIME:Float = 9;

	public var kind(default, null):PowerKind = BONUS;

	var life:Float = 0;
	/** A kézzel elhelyezett bónusz nem tűnik el, csak ha elgörgetődik. */
	var persistent:Bool = false;

	public static function label(kind:PowerKind):String
	{
		return switch (kind)
		{
			case SPREAD: "SPREAD SHOT!";
			case RAPID: "RAPID FIRE!";
			case HOMING: "HOMING SHOTS!";
			case ROCKET: "ROCKET LAUNCHER!";
			case LASER: "LASER!";
			case GRENADE: "GRENADES!";
			case BONUS: "BONUS!";
			case ENERGY: "ENERGY +35!";
			case SHROOM: "WHOA... TRIPPY!";
			case PIXEL: "PIXELATED!";
			case TORCH: "LIGHTS OUT!";
			case GHOST: "INVISIBLE!";
			case TINYVIEW: "TUNNEL VISION!";
			case TINYHERO: "TINY HERO!";
			case MAGNET: "ATTRACTED!";
			case ASCII: "ASCII MODE!";
		}
	}

	/** Rövid név a HUD-slothoz. */
	public static function shortName(kind:PowerKind):String
	{
		return switch (kind)
		{
			case SPREAD: "SPREAD";
			case RAPID: "RAPID FIRE";
			case HOMING: "HOMING";
			case ROCKET: "ROCKET";
			case LASER: "LASER";
			case GRENADE: "GRENADE";
			case BONUS: "BONUS";
			case ENERGY: "ENERGY";
			case SHROOM: "TRIPPING";
			case PIXEL: "PIXELATED";
			case TORCH: "FLASHLIGHT";
			case GHOST: "INVISIBLE";
			case TINYVIEW: "TUNNEL";
			case TINYHERO: "TINY HERO";
			case MAGNET: "MAGNETIC";
			case ASCII: "ASCII";
		}
	}

	/**
	 * Időkorlátos alapfegyver-bónuszok: az új lecseréli a régit; lejártukkor visszaáll a bolt-felszerelés
	 * (alapból a pisztoly, aminek nincs saját bónusza).
	 */
	public static final BASE_WEAPONS:Array<PowerKind> = [ROCKET, LASER, GRENADE];

	/** Kiegészítők: egymásra rakódnak, és mindegyik alapfegyverre hatnak (fegyverenként másképp). */
	public static final MODS:Array<PowerKind> = [SPREAD, RAPID, HOMING];

	/** Módosítók (a hőst nehezítik, időkorlátosak): a talajon fekvő tárgyak, vagy a gomba. */
	public static final CURSES:Array<PowerKind> = [SHROOM, PIXEL, TORCH, GHOST, TINYVIEW, TINYHERO, MAGNET, ASCII];

	/** Véletlen jutalom, súlyozva (módosító nem lehet). */
	public static function random():PowerKind
	{
		return FlxG.random.getObject([SPREAD, RAPID, HOMING, ROCKET, LASER, GRENADE, BONUS, ENERGY], [16, 16, 12, 14, 14, 14, 14, 24]);
	}

	/** Véletlen módosító a konfig súlyai szerint. */
	public static function randomCurse():PowerKind
	{
		return FlxG.random.getObject(CURSES, Config.curseWeights);
	}

	public function new()
	{
		super();
	}

	/** Tiled-ben elhelyezett bónusz: nem jár le, és lebeg vagy leesik a talajra. A (cx, bottomY) a talppont-közép. */
	public function place(cx:Float, bottomY:Float, kind:PowerKind, floating:Bool):Void
	{
		spawn(cx, bottomY - PixelArt.POWER_SIZE / 2, kind);
		persistent = true;
		velocity.set(0, 0);
		acceleration.y = floating ? 0 : 500;
	}

	public function spawn(cx:Float, cy:Float, kind:PowerKind):Void
	{
		this.kind = kind;
		loadGraphic(PixelArt.powerUp(kind), true, PixelArt.POWER_SIZE, PixelArt.POWER_SIZE);
		animation.add("glow", [0, 1], 5);
		animation.play("glow");
		reset(cx - width / 2, cy - height / 2);
		velocity.set(FlxG.random.float(-30, 30), -170);
		acceleration.y = 500;
		maxVelocity.y = 300;
		drag.x = 60;
		life = LIFETIME;
		visible = true;
		persistent = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!persistent)
		{
			life -= elapsed;
			// Az utolsó két másodpercben villog, mielőtt eltűnik
			if (life < 2)
				visible = Std.int(life * 10) % 2 == 0;
			if (life <= 0)
				kill();
		}
		if (y > FlxG.camera.scroll.y + FlxG.height + 50)
			kill();
	}
}
