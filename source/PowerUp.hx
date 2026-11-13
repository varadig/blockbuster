package;

import flixel.FlxG;
import flixel.FlxSprite;

/** A jutalomdobozokból kieső bónuszok fajtái. */
enum PowerKind
{
	SPREAD; // hármas szórólövés
	RAPID; // gyorstüzelés
	HEAVY; // nagy, átütő lövedék
	FLAME; // lángszóró: rövid hatótáv, folyamatos égetés
	LASER; // lézer: nagyon gyors lövedék, ami minden dobozon átmegy
	DEATHRAY; // halálsugár: azonnali sugár, ami mindent elpusztít, amin áthalad
	SHIELD; // időkorlátos sérthetetlenség
	SLOWMO; // lassított idő
	BONUS; // extra pont
	ENERGY; // energia visszatöltése
	NUKE; // atom: elpusztít mindent a képernyőn
	SHROOM; // varázsgomba hatása (hallucináció) – csak a HUD-kijelzéshez, nem jutalom
}

/** Felvehető bónusz: kipattan a szétlőtt dobozból, leesik a földre, és egy ideig ott marad. */
class PowerUp extends FlxSprite
{
	static inline var LIFETIME:Float = 9;

	public var kind(default, null):PowerKind = BONUS;

	var life:Float = 0;

	public static function label(kind:PowerKind):String
	{
		return switch (kind)
		{
			case SPREAD: "SPREAD SHOT!";
			case RAPID: "RAPID FIRE!";
			case HEAVY: "HEAVY ROUNDS!";
			case FLAME: "FLAMETHROWER!";
			case LASER: "LASER!";
			case DEATHRAY: "DEATH RAY!";
			case SHIELD: "INVINCIBLE!";
			case SLOWMO: "SLOW MOTION!";
			case BONUS: "BONUS!";
			case ENERGY: "ENERGY +35!";
			case NUKE: "NUKE!";
			case SHROOM: "WHOA... TRIPPY!";
		}
	}

	/** Rövid név a HUD-slothoz. */
	public static function shortName(kind:PowerKind):String
	{
		return switch (kind)
		{
			case SPREAD: "SPREAD";
			case RAPID: "RAPID FIRE";
			case HEAVY: "HEAVY";
			case FLAME: "FLAME";
			case LASER: "LASER";
			case DEATHRAY: "DEATH RAY";
			case SHIELD: "INVINCIBLE";
			case SLOWMO: "SLOW-MO";
			case BONUS: "BONUS";
			case ENERGY: "ENERGY";
			case NUKE: "NUKE";
			case SHROOM: "HALLUCINATING";
		}
	}

	/**
	 * Alapfegyverek: egyszerre csak egy lehet (az új lecseréli a régit); lejártukkor visszaáll a sima lövedék (BULLET),
	 * aminek nincs saját bónusza.
	 */
	public static final BASE_WEAPONS:Array<PowerKind> = [FLAME, LASER, DEATHRAY];

	/** Kiegészítők: egymásra rakódnak, és mindegyik alapfegyverre hatnak (fegyverenként másképp). */
	public static final MODS:Array<PowerKind> = [SPREAD, RAPID, HEAVY];

	/** Véletlen jutalom, súlyozva. */
	public static function random():PowerKind
	{
		return FlxG.random.getObject([SPREAD, RAPID, HEAVY, FLAME, LASER, DEATHRAY, SHIELD, SLOWMO, BONUS, ENERGY, NUKE], [16, 16, 13, 14, 14, 6, 13, 10, 14, 24, 5]);
	}

	public function new()
	{
		super();
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
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		life -= elapsed;
		// Az utolsó két másodpercben villog, mielőtt eltűnik
		if (life < 2)
			visible = Std.int(life * 10) % 2 == 0;
		if (life <= 0 || y > FlxG.camera.scroll.y + FlxG.height + 50)
			kill();
	}
}
