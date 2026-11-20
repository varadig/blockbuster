package;

/** Egy játszható karakter: kinézet (szín) és mozgása (a Config alapértékeihez viszonyított szorzók). */
typedef CharDef =
{
	var name:String;
	var tagline:String;
	/** A PixelArt.player színváltozata. */
	var skin:Int;
	/** Ugrás ereje (az ugrás kezdősebességének szorzója: a magasság ennek ~négyzetével nő). */
	var jump:Float;
	/** Futási sebesség szorzója. */
	var speed:Float;
	/** Súrlódás (megállás): kicsi = csúszik, nagy = azonnal megáll. */
	var friction:Float;
	/** A választóképernyő csíkjai (1-5): ugrás, sebesség, tapadás. */
	var stars:Array<Int>;
}

/** A három választható karakter; a választás a Settings.character-ben van (mentve). */
class Characters
{
	public static final LIST:Array<CharDef> = [
		{
			name: "BLAZE",
			tagline: "Balanced all-rounder",
			skin: 0,
			jump: 1.0,
			speed: 1.0,
			friction: 1.0,
			stars: [3, 3, 3]
		},
		{
			name: "ZIP",
			tagline: "Very fast, but slides on stopping",
			skin: 1,
			jump: 0.92,
			speed: 1.3,
			friction: 0.3,
			stars: [2, 5, 1]
		},
		{
			name: "ROCK",
			tagline: "Slow, jumps high, stops on a dime",
			skin: 2,
			jump: 1.18,
			speed: 0.82,
			friction: 2.2,
			stars: [5, 1, 5]
		}
	];

	public static function current():CharDef
	{
		var i = Settings.character;
		return LIST[i >= 0 && i < LIST.length ? i : 0];
	}
}
