package;

/**
 * Egy pálya témája: az égbolt, a hold (vagy nap), a háttérhegyek, a talaj színei és az időjárás-részecskék.
 * Csak a megjelenést érinti. Tiled-ben a térkép `theme` tulajdonsága választja (lásd docs/LEVELS.md).
 */
typedef Theme =
{
	var name:String;
	/** Az égbolt 4 színsávja fentről lefelé (a horizont színe az utolsó). */
	var sky:Array<Int>;
	/** A csillagok sűrűsége az alap (NIGHT) szorzójában; 0 = nincs csillag. */
	var stars:Float;
	/** A hold: világos, árnyék, perem, sötét perem színe. */
	var moon:Array<Int>;
	/** A háttérhegyek: kitöltés, él, hósapka színe (0 = nincs hósapka). */
	var ridge:Array<Int>;
	/** A közeli dombok: kitöltés, él. */
	var hills:Array<Int>;
	/** A talaj mélységi sávjai (felülről lefelé, 4 szín). */
	var dirt:Array<Int>;
	/** A talaj teteje: fénypont, alap, árnyék. */
	var grass:Array<Int>;
	/** Időjárás-részecskék: "" (nincs), "snow", "ash", "spores", "sand". */
	var particles:String;
}

/** A pályatémák. A `current` a PixelArt generálásait (ég, hold, hegyek, talaj) irányítja. */
class Themes
{
	public static final NIGHT:Theme = {
		name: "NIGHT",
		sky: [0xff07060d, 0xff110c1c, 0xff1f1328, 0xff3a1a2c],
		stars: 1,
		moon: [0xffe0896e, 0xffa8483e, 0xffc96a55, 0xff5a1f24],
		ridge: [0xff120d1c, 0xff4a2c4e, 0xff4e4460],
		hills: [0xff1a1222, 0xff0a0810],
		dirt: [0xff5a3a2e, 0xff432a22, 0xff2e1c19, 0xff1a1012],
		grass: [0xff6e8f4e, 0xff3f6640, 0xff22403a],
		particles: ""
	};

	public static final ASH:Theme = {
		name: "ASH",
		sky: [0xff0d0506, 0xff2a0d0d, 0xff5a1a10, 0xffb8451e],
		stars: 0.15,
		moon: [0xffffa040, 0xffd0601c, 0xffff7a2a, 0xff8a2a10],
		ridge: [0xff180a0a, 0xff7a2a18, 0],
		hills: [0xff1c0e0c, 0xff0c0505],
		dirt: [0xff4a4040, 0xff383030, 0xff261f1f, 0xff141010],
		grass: [0xffc0622a, 0xff6a5a52, 0xff2c2422],
		particles: "ash"
	};

	public static final ICE:Theme = {
		name: "ICE",
		sky: [0xff050a1a, 0xff0c1c3a, 0xff1d3d6b, 0xff6aa0c8],
		stars: 1.3,
		moon: [0xffe8f4ff, 0xffa8c0d8, 0xffcfe2f2, 0xff6080a0],
		ridge: [0xff1a2b4a, 0xff6a9ac4, 0xffe8f4ff],
		hills: [0xff12203a, 0xff08101e],
		dirt: [0xff5a6e8c, 0xff3e5070, 0xff2a3a58, 0xff182236],
		grass: [0xffeaf6ff, 0xffc4dcf0, 0xff8aa8c8],
		particles: "snow"
	};

	public static final DESERT:Theme = {
		name: "DESERT",
		sky: [0xff2a1040, 0xff7a2e5a, 0xffd0603a, 0xfff0a050],
		stars: 0.3,
		moon: [0xffffe08a, 0xffe8a840, 0xfff0b84a, 0xffb06a20],
		ridge: [0xff5a2a3a, 0xffc0603a, 0],
		hills: [0xff7a3a30, 0xff3a1a1a],
		dirt: [0xffc08a50, 0xff9a6a3a, 0xff6e4a2a, 0xff3e2a1a],
		grass: [0xffe8c47a, 0xffd0a45a, 0xff9a7a3a],
		particles: "sand"
	};

	public static final TOXIC:Theme = {
		name: "TOXIC",
		sky: [0xff04100a, 0xff0a2a14, 0xff1a4a1c, 0xff5a8a1a],
		stars: 0.6,
		moon: [0xffc8ff5a, 0xff6aa020, 0xff9ae03a, 0xff2a5a10],
		ridge: [0xff0c2418, 0xff3a8a3a, 0],
		hills: [0xff0a1a10, 0xff040a06],
		dirt: [0xff4a3a5a, 0xff382a48, 0xff261c34, 0xff140e1c],
		grass: [0xff9aff4a, 0xff4ab02a, 0xff1a5a2a],
		particles: "spores"
	};

	public static final ALL:Array<Theme> = [NIGHT, ASH, ICE, DESERT, TOXIC];

	/** A mostani pálya témája (a PlayState állítja be a pálya indulásakor; a PixelArt ebből rajzol). */
	public static var current:Theme = NIGHT;

	/** Név szerint (kis-nagybetűtől függetlenül); ismeretlen vagy üres név = null. */
	public static function find(name:Null<String>):Null<Theme>
	{
		if (name == null)
			return null;
		var n = name.toUpperCase();
		for (t in ALL)
			if (t.name == n)
				return t;
		return null;
	}

	/** Az alap téma a pálya sorszámához (a térkép `theme` tulajdonsága ezt felülírja): a 4. pályától körbe jár. */
	public static function forLevel(l:Int):Theme
	{
		if (l <= 0)
			return NIGHT;
		if (l == 1)
			return ASH;
		if (l == 2)
			return NIGHT;
		return [ICE, TOXIC, DESERT][(l - 3) % 3];
	}
}
