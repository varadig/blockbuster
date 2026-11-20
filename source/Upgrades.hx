package;

import PowerUp.PowerKind;

typedef UpgradeDef =
{
	var name:String;
	var desc:String;
	var costs:Array<Int>;
	/** A bolt-ikon: egy PowerKind neve (a bónusz-ikon) vagy "ARMOR" / "BASEGUN" (PixelArt.shopIcon). */
	var icon:String;
}

typedef WeaponDef =
{
	var kind:PowerKind;
	var name:String;
	var desc:String;
	var cost:Int;
}

/** Az érmékből a boltban megvehető tartós fejlesztések és fegyverek (állapotuk a Settings-ben van, mentve). */
class Upgrades
{
	public static inline var ARMOR:Int = 0;
	public static inline var WEAPON:Int = 1;
	public static inline var ENERGY:Int = 2;
	public static inline var FIRE_RATE:Int = 3;

	/** A costs hossza a legnagyobb szint; az i. elem a (i+1). szint ára. */
	public static final LIST:Array<UpgradeDef> = [
		{name: "ARMOR", desc: "Take 10% less damage per level", costs: [30, 60, 110, 180, 270], icon: "ARMOR"},
		{name: "PISTOL POWER", desc: "+1 damage with the pistol per level", costs: [50, 120, 220], icon: "BASEGUN"},
		{name: "ENERGY", desc: "+15% maximum energy per level", costs: [30, 70, 130, 210], icon: "ENERGY"},
		{name: "FIRE RATE", desc: "10% faster shooting per level", costs: [40, 100, 180], icon: "RAPID"}
	];

	/** Megvásárolható fegyverek: egyszeri ár, utána felszerelhető (a futás ezzel indul, és a bónusz lejártakor ide tér vissza). */
	public static final WEAPONS:Array<WeaponDef> = [
		{kind: ROCKET, name: "ROCKET LAUNCHER", desc: "Rockets that explode on impact", cost: 120},
		{kind: LASER, name: "LASER", desc: "Fast beam that pierces everything", cost: 160},
		{kind: GRENADE, name: "GRENADES", desc: "Lobbed bombs with a big blast radius", cost: 100}
	];

	public static function level(i:Int):Int
	{
		Settings.load();
		return Settings.upgrades[i];
	}

	public static function maxLevel(i:Int):Int
		return LIST[i].costs.length;

	/** A következő szint ára; null, ha már a legmagasabb szinten van. */
	public static function nextCost(i:Int):Null<Int>
	{
		var l = level(i);
		return l >= maxLevel(i) ? null : LIST[i].costs[l];
	}

	public static function canBuy(i:Int):Bool
	{
		var c = nextCost(i);
		return c != null && Settings.coins >= c;
	}

	public static function buy(i:Int):Bool
	{
		if (!canBuy(i))
			return false;
		Settings.coins -= nextCost(i);
		Settings.upgrades[i]++;
		Settings.store();
		return true;
	}

	// --- Fegyverek ---

	public static function owns(w:Int):Bool
	{
		Settings.load();
		return Settings.ownedWeapons[w] != 0;
	}

	/** A fegyver felszerelve van-e (w = a WEAPONS indexe; -1 = a pisztoly). */
	public static function equipped(w:Int):Bool
		return Settings.loadout == w + 1;

	/** Megvétel (ha még nincs meg és van rá pénz) és felszerelés; ha már a tiéd, csak felszereli. */
	public static function buyOrEquip(w:Int):Bool
	{
		Settings.load();
		if (w >= 0 && !owns(w))
		{
			if (Settings.coins < WEAPONS[w].cost)
				return false;
			Settings.coins -= WEAPONS[w].cost;
			Settings.ownedWeapons[w] = 1;
		}
		Settings.loadout = w + 1;
		Settings.store();
		return true;
	}

	/** Az indulófegyver; null = pisztoly. */
	public static function loadoutKind():Null<PowerKind>
	{
		Settings.load();
		var l = Settings.loadout;
		return l >= 1 && l <= WEAPONS.length && owns(l - 1) ? WEAPONS[l - 1].kind : null;
	}

	/** A kapott sebzés szorzója. */
	public static function armorMul():Float
		return 1 - 0.1 * level(ARMOR);

	/** A pisztoly többletsebzése. */
	public static function weaponBonus():Int
		return level(WEAPON);

	public static function energyMul():Float
		return 1 + 0.15 * level(ENERGY);

	/** A lövések közti idő szorzója. */
	public static function cooldownMul():Float
		return 1 - 0.1 * level(FIRE_RATE);
}
