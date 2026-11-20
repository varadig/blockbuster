package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * Kódból generált pixelgrafika (nincsenek asset fájlok).
 * A paletta a Sweetie 16-ra épül, néhány földszínnel kiegészítve.
 * A kész grafikák a FlxG.bitmap cache-be kerülnek (persist), így újraindításkor sem rajzoljuk újra őket.
 */
class PixelArt
{
	// --- Paletta ------------------------------------------------------------
	public static inline var OUTLINE:Int = 0xff1a1c2c;
	public static inline var PLUM:Int = 0xff5d275d;
	public static inline var RED:Int = 0xffb13e53;
	public static inline var ORANGE:Int = 0xffef7d57;
	public static inline var YELLOW:Int = 0xffffcd75;
	public static inline var LIME:Int = 0xffa7f070;
	public static inline var GREEN:Int = 0xff38b764;
	public static inline var TEAL:Int = 0xff257179;
	public static inline var NAVY:Int = 0xff29366f;
	public static inline var BLUE:Int = 0xff3b5dc9;
	public static inline var SKY:Int = 0xff41a6f6;
	public static inline var CYAN:Int = 0xff73eff7;
	public static inline var WHITE:Int = 0xfff4f4f4;
	public static inline var LIGHT_GRAY:Int = 0xff94b0c2;
	public static inline var GRAY:Int = 0xff566c86;
	public static inline var DARK_GRAY:Int = 0xff333c57;

	static inline var DIRT_TOP:Int = 0xff5a3a2e;
	static inline var DIRT_MID:Int = 0xff432a22;
	static inline var DIRT_DEEP:Int = 0xff2e1c19;
	static inline var DIRT_DEEPEST:Int = 0xff1a1012;
	// Sötétebb, fakóbb fű a komorabb hangulathoz
	static inline var GRASS_TOP:Int = 0xff6e8f4e;
	static inline var GRASS:Int = 0xff3f6640;
	static inline var GRASS_DARK:Int = 0xff22403a;
	static inline var NIGHT_HORIZON:Int = 0xff3a1a2c;

	/** 4x4-es Bayer mátrix a rendezett ditheringhez. */
	static final BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];

	// --- Általános segédek ----------------------------------------------------

	/** Determinisztikus 0..1 közötti zaj egy egész koordinátapárra. */
	public static inline function hash(x:Float, y:Float):Float
	{
		var v = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
		return v - Math.floor(v);
	}

	static inline function bayer(x:Int, y:Int):Float
	{
		return (BAYER[(y & 3) * 4 + (x & 3)] + 0.5) / 16;
	}

	static function store(key:String, bmd:BitmapData):FlxGraphic
	{
		var g = FlxG.bitmap.add(bmd, false, key);
		g.persist = true;
		g.destroyOnNoUse = false;
		return g;
	}

	/**
	 * Karakteres "rajzból" készít sprite sheetet: minden képkocka sorok tömbje,
	 * a karakterek a palettából kapnak színt, a '.' átlátszó. A képkockák vízszintesen egymás mellé kerülnek.
	 */
	public static function sheet(key:String, frames:Array<Array<String>>, palette:Map<String, Int>):FlxGraphic
	{
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var fh = frames[0].length;
		var fw = 0;
		for (frame in frames)
			for (row in frame)
				fw = Std.int(Math.max(fw, row.length));

		var bmd = new BitmapData(fw * frames.length, fh, true, 0);
		for (f in 0...frames.length)
			for (y in 0...fh)
			{
				var row = frames[f][y];
				for (x in 0...row.length)
				{
					var c = palette.get(row.charAt(x));
					if (c != null)
						bmd.setPixel32(f * fw + x, y, c);
				}
			}
		return store(key, bmd);
	}

	// --- Játékos ----------------------------------------------------------------

	public static inline var PLAYER_W:Int = 16;
	public static inline var PLAYER_H:Int = 20;

	/** Képkockák: 0 áll, 1-4 fut, 5 ugrik, 6 esik. */
	public static function player(skin:Int = 0):FlxGraphic
	{
		// Színváltozatok: [test, test világos, sál, sál világos, öv]
		var colors = switch (skin)
		{
			case 1: [RED, ORANGE, YELLOW, LIME, WHITE]; // ZIP
			case 2: [GREEN, LIME, ORANGE, YELLOW, LIGHT_GRAY]; // ROCK
			default: [BLUE, SKY, RED, ORANGE, YELLOW]; // BLAZE
		}
		// Sisakos kis futó, jobbra néz; vörös sál lobog mögötte
		var head = [
			".....KKKKKK.....",
			"....KbbbbbBK....",
			"...KbbBBBBBBK...",
			"...KbBBKKKKKKK..",
			"...KBBKCCCWCCK..",
			"...KBBKCCCCCCK..",
			"...KBBBKKKKKK...",
			"....KBBBBBBK....",
			"..rRRRRRRRRK....",
		];
		var torso = [
			".rRRKBBbbBBK....",
			"rR..KBBbbBKbK...",
			"r...KBBBBBKbK...",
			"....KBBBBBBKK...",
			"....KGGGGGGK....",
		];
		// Lábak: 6 sor képkockánként
		var legsIdle = [
			"....KBBKKBBK....",
			"....KBBKKBBK....",
			"....KBBKKBBK....",
			"....KDDKKDDK....",
			"...KDDDKKDDDK...",
			"...KKKKKKKKKK...",
		];
		var legsRun1 = [
			"....KBBBBBBK....",
			"...KBBKKKBBK....",
			"..KBBK...KBBK...",
			".KDDK.....KDDK..",
			".KDDDK....KDDDK.",
			"..KKKK.....KKKK.",
		];
		var legsRun2 = [
			"....KBBKKBBK....",
			"....KBBKKBBK....",
			"....KBBKKDDK....",
			"....KDDKKDDDK...",
			"...KDDDKKKKK....",
			"...KKKKK........",
		];
		var legsRun3 = [
			"....KBBBBBBK....",
			"....KBBKKBBK....",
			"...KBBK.KBBK....",
			"..KDDK..KDDK....",
			".KDDDK..KDDDK...",
			".KKKKK..KKKKK...",
		];
		var legsRun4 = [
			"....KBBKKBBK....",
			"....KBBKKBBK....",
			"....KDDKKBBK....",
			"...KDDDKKDDK....",
			"....KKKKKDDDK...",
			"........KKKKK...",
		];
		var legsJump = [
			"....KBBBBBBK....",
			"...KBBKKKBBBK...",
			"..KDDK...KDDK...",
			"..KDDDK..KDDDK..",
			"...KKK....KKK...",
			"................",
		];
		var legsFall = [
			"....KBBKKBBK....",
			"...KBBK..KBBK...",
			"..KBBK....KBBK..",
			"..KDDK....KDDK..",
			".KDDDK....KDDDK.",
			".KKKK......KKKK.",
		];

		// Futás közben a felsőtest minden második képkockán egy pixellel lejjebb ugrik (bólintás)
		function frame(legs:Array<String>, bob:Bool):Array<String>
		{
			var top = head.concat(torso);
			if (bob)
				top = ["................"].concat(top.slice(0, top.length - 1));
			return top.concat(legs);
		}

		// Esés közben a sál felfelé lobog
		var fallFrame = frame(legsFall, false);
		fallFrame[8] = "...KRRRRRRRK.r..";
		fallFrame[9] = "....KBBbbBBKRr..";

		return sheet(skin == 0 ? "px_player" : "px_player" + skin, [
			frame(legsIdle, false),
			frame(legsRun1, false),
			frame(legsRun2, true),
			frame(legsRun3, false),
			frame(legsRun4, true),
			frame(legsJump, false),
			fallFrame,
		], [
			"K" => OUTLINE,
			"B" => colors[0],
			"b" => colors[1],
			"C" => CYAN,
			"W" => WHITE,
			"R" => colors[2],
			"r" => colors[3],
			"G" => colors[4],
			"D" => DARK_GRAY,
		]);
	}

	// --- Lövedék, törmelék, por --------------------------------------------

	public static function bulletH():FlxGraphic
	{
		return sheet("px_bullet_h", [["..rYYY..", "rrYYWWWW", "..rYYY.."]], ["Y" => YELLOW, "W" => WHITE, "r" => ORANGE]);
	}

	public static function bulletV():FlxGraphic
	{
		return sheet("px_bullet_v", [[".W.", "YWY", "YWY", "YYY", "rYr", ".r.", ".r.", "..."]], ["Y" => YELLOW, "W" => WHITE, "r" => ORANGE]);
	}

	// --- Ellenségek ----------------------------------------------------------------

	public static inline var SLIME_W:Int = 16;
	public static inline var SLIME_H:Int = 12;

	/** Ugráló slime: 0 = alap, 1 = összenyomott. */
	public static function slime():FlxGraphic
	{
		return sheet("px_slime", [
			[
				"................", "......KKKK......", "....KKmmmmKK....", "...KmmllmmmmK...", "..KmllmmmmmmmK..", "..KmmWKmmWKmmK..",
				".KmmmWKmmWKmmmK.", ".KmmmmmmmmmmmmK.", "KmmmmmmmmmmmmmmK", "KpmmmmmmmmmmmmpK", ".KppppppppppppK.", "..KKKKKKKKKKKK..",
			],
			[
				"................", "................", ".....KKKKKK.....", "...KKmmllmmmKK..", "..KmllmmmmmmmmK.", ".KmmmWKmmmWKmmmK",
				".KmmmWKmmmWKmmmK", "KmmmmmmmmmmmmmmK", "KmmmmmmmmmmmmmmK", "KpmmmmmmmmmmmmpK", "KppppppppppppppK", ".KKKKKKKKKKKKKK.",
			],
		], ["K" => OUTLINE, "m" => 0xffb05cd6, "l" => 0xffe0a8ff, "p" => PLUM, "W" => WHITE]);
	}

	public static inline var SPIDERLING_W:Int = 12;
	public static inline var SPIDERLING_H:Int = 8;

	/** A pók kicsinye (2 képkocka: váltakozó lábak): barna test, vörös szemek, fehér csipeszek elöl (balra néz). */
	public static function spiderling():FlxGraphic
	{
		return sheet("px_spiderling", [
			[
				"...KKKKKK...", "..KbbbbbbK..", ".KwbrbbrbbK.", ".KwbbbbbbbK.", "KdKbbbbbbKdK", "K.KddddddK.K", "K..K.KK.K..K", "............",
			],
			[
				"...KKKKKK...", "..KbbbbbbK..", ".KwbrbbrbbK.", ".KwbbbbbbbK.", ".KdbbbbbbdK.", "KK.KddddK.KK", ".K.K.KK.K.K.", "............",
			],
		], ["K" => OUTLINE, "b" => 0xff7a5a44, "d" => 0xff4a3426, "r" => RED, "w" => WHITE]);
	}

	public static inline var SPIKE_W:Int = 12;
	public static inline var SPIKE_H:Int = 36;

	/** Talajból feltörő csontszínű tüske (a hegye felül): világos bal és sötét jobb oldal, sötét körvonal. */
	public static function spike():FlxGraphic
	{
		var key = "px_spike";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var bmd = new BitmapData(SPIKE_W, SPIKE_H, true, 0);
		var c = (SPIKE_W - 1) / 2;
		for (y in 0...SPIKE_H)
		{
			var hw = 0.8 + y / (SPIKE_H - 1) * 5.0;
			for (x in 0...SPIKE_W)
			{
				var d = x - c;
				if (Math.abs(d) > hw)
					continue;
				var edge = Math.abs(d) > hw - 1.1 || y == SPIKE_H - 1;
				var col:Int = edge ? OUTLINE : (d < -0.5 ? 0xfff4ead8 : (d < 1.5 ? 0xffd8c8b0 : 0xff9a8870));
				bmd.setPixel32(x, y, col);
			}
		}
		return store(key, bmd);
	}

	public static inline var BAT_W:Int = 16;
	public static inline var BAT_H:Int = 10;

	/** Denevér: 0 = szárny fent, 1 = szárny lent. */
	public static function bat():FlxGraphic
	{
		return sheet("px_bat", [
			[
				"KK............KK", "KwK..........KwK", "KwwK..K..K..KwwK", ".KwwKKdKKdKKwwK.", "..KwwddddddwwK..", "...KddYddYddK...",
				"....KddddddK....", ".....KdKKdK.....", "......K..K......", "................",
			],
			[
				"................", "................", "......K..K......", ".....KdKKdK.....", "....KddddddK....", "...KddYddYddK...",
				"..KwwddddddwwK..", ".KwwKKddddKKwwK.", "KwwK..KKKK..KwwK", "KKK..........KKK",
			],
		], ["K" => OUTLINE, "w" => 0xff8a4fa0, "d" => PLUM, "Y" => YELLOW]);
	}

	public static inline var TURRET_SIZE:Int = 14;

	/** Lövegtorony (cső balra): 0 = alap, 1 = torkolattűz. */
	public static function turret():FlxGraphic
	{
		var body = [
			"..............", ".....KKKK.....", "....KllllK....", "...KlggggdK...", "KKKKgrrgggdK..", "KllllrrggggdK.", "KKKKggggggddK.",
			"...KdgggggddK.", "..KKKKKKKKKKKK", "..KdldddddldK.", "..KddddddddddK", ".KdddddddddddK", ".KKKKKKKKKKKKK", "..............",
		];
		var fire = body.copy();
		fire[4] = "YKKKgrrgggdK..";
		fire[5] = "YllllrrggggdK.";
		return sheet("px_turret", [body, fire], ["K" => OUTLINE, "l" => LIGHT_GRAY, "g" => GRAY, "d" => DARK_GRAY, "r" => 0xffff5a5a, "Y" => YELLOW]);
	}

	public static inline var DRONE_W:Int = 18;
	public static inline var DRONE_H:Int = 10;

	/** Bombázó drón: két képkocka a forgó légcsavarokhoz. */
	public static function drone():FlxGraphic
	{
		var a = [
			".lllll.....lllll..", "...K.........K....", "..KKKKKKKKKKKKKK..", ".KyyoyyoyyoyyoyyK.", "KyyyyyyyyyyyyyyyyK", "KddddddrrddddddddK",
			".KdddddddddddddK..", "..KKKKKdddKKKKK...", ".......KdK........", "........K.........",
		];
		var b = a.copy();
		b[0] = "...l.........l....";
		return sheet("px_drone", [a, b], ["K" => OUTLINE, "l" => LIGHT_GRAY, "y" => YELLOW, "o" => ORANGE, "d" => DARK_GRAY, "r" => 0xffff5a5a]);
	}

	/** Ellenséges lövedék (vörös gömb). */
	public static function enemyShot():FlxGraphic
	{
		return sheet("px_enemy_shot", [[".KrK.", "KrYrK", "rYWYr", "KrYrK", ".KrK."]], ["K" => OUTLINE, "r" => 0xffff5a5a, "Y" => YELLOW, "W" => WHITE]);
	}

	/** Bomba égő kanóccal. */
	public static function bomb():FlxGraphic
	{
		return sheet("px_bomb", [["...Y..", "..K...", ".KKKK.", "KddddK", "KdlddK", "KddddK", "KddddK", ".KKKK."]],
			["K" => OUTLINE, "d" => DARK_GRAY, "l" => LIGHT_GRAY, "Y" => YELLOW]);
	}

	/** Átlós (jobbra-fel) lövedék; balra lőve tükrözzük. */
	public static function bulletD():FlxGraphic
	{
		return sheet("px_bullet_d", [["....WW", "...YWW", "..YYY.", ".rY...", "rr....", "r....."]], ["Y" => YELLOW, "W" => WHITE, "r" => ORANGE]);
	}

	/** Lézerlövedék: fehér mag, vörös szél. Irány szerint vízszintes, függőleges vagy átlós. */
	public static function laserH():FlxGraphic
	{
		return sheet("px_laser_h", [["rrrrrrrrrrrrrrrrrrrrrr", "WWWWWWWWWWWWWWWWWWWWWW", "rrrrrrrrrrrrrrrrrrrrrr"]], ["W" => WHITE, "r" => 0xffff5a5a]);
	}

	public static function laserV():FlxGraphic
	{
		return sheet("px_laser_v", [[for (i in 0...22) "rWr"]], ["W" => WHITE, "r" => 0xffff5a5a]);
	}

	public static function laserD():FlxGraphic
	{
		var rows = [];
		for (y in 0...16)
		{
			var s = "";
			for (x in 0...16)
			{
				var d = x + y - 15; // a jobb-fel átló
				s += d == 0 ? "W" : (d == 1 || d == -1 ? "r" : ".");
			}
			rows.push(s);
		}
		return sheet("px_laser_d", [rows], ["W" => WHITE, "r" => 0xffff5a5a]);
	}

	/** Rakéta (vízszintes, jobbra néz; a PlayState az irányába forgatja): szürke test, vörös orr, láng a végén. */
	public static function rocket():FlxGraphic
	{
		return sheet("px_rocket", [["..LLLLRR..", "yoLWWLLRR.", "YYLLLLLLRR", "yoLWWLLRR.", "..LLLLRR.."]],
			["L" => LIGHT_GRAY, "W" => WHITE, "R" => RED, "y" => YELLOW, "Y" => YELLOW, "o" => ORANGE]);
	}

	/** Gránát: zöld, gömbölyű, tetején gyújtószerkezet. */
	public static function grenade():FlxGraphic
	{
		return sheet("px_grenade", [["...KK..", "..KYK..", ".KGGGK.", "KGgGGGK", "KGGGGdK", ".KdddK.", "..KKK.."]],
			["K" => OUTLINE, "G" => 0xff4a7f3a, "g" => LIME, "d" => TEAL, "Y" => YELLOW]);
	}

	public static inline var BLAST_SIZE:Int = 64;

	/** Robbanás-kör (a PlayState a hatósugárhoz nyújtja és elhalványítja): narancs belső, sárga szél. */
	public static function blast():FlxGraphic
	{
		var key = "px_blast";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var s = BLAST_SIZE, c = (s - 1) / 2;
		var bmd = new BitmapData(s, s, true, 0);
		for (y in 0...s)
			for (x in 0...s)
			{
				var d = Math.sqrt((x - c) * (x - c) + (y - c) * (y - c)) / c;
				if (d > 1)
					continue;
				bmd.setPixel32(x, y, d > 0.86 ? 0xfffff0a0 : (d > 0.6 ? 0xb0ffcd75 : 0x80ef7d57));
			}
		return store(key, bmd);
	}

	/** A bolt ikonjai (12x12, egy képkocka): páncél és alappisztoly; a többihez a bónusz-ikonok (powerUp) valók. */
	public static function shopIcon(name:String):FlxGraphic
	{
		var key = "px_shop_" + name;
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var glyph = name == "ARMOR" ? ["XXXXXXXX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX", ".XXXXXX.", "..XXXX..", "...XX...", "........"] : [
			"........", "XXXXXXX.", "XXXXXXXX", "XXXXXXX.", "..XX....", "..XX....", "........", "........"
		];
		var base:FlxColor = name == "ARMOR" ? CYAN : LIGHT_GRAY;
		var s = POWER_SIZE, last = POWER_SIZE - 1;
		var bmd = new BitmapData(s, s, true, 0);
		var hi = base.getLightened(0.45), sh = base.getDarkened(0.3);
		for (y in 0...s)
			for (x in 0...s)
			{
				var edgeX = x == 0 || x == last, edgeY = y == 0 || y == last;
				if (edgeX && edgeY)
					continue;
				var c:Int = base;
				if (edgeX || edgeY)
					c = OUTLINE;
				else if (x == 1 || y == 1)
					c = hi;
				else if (x == last - 1 || y == last - 1)
					c = sh;
				bmd.setPixel32(x, y, c);
			}
		for (y in 0...8)
			for (x in 0...8)
				if (glyph[y].charAt(x) == "X")
					bmd.setPixel32(2 + x, 2 + y, OUTLINE);
		return store(key, bmd);
	}

	// --- Érme ---------------------------------------------------------------------

	/** Forgó érme (8x8, 4 képkocka). */
	public static function coin():FlxGraphic
	{
		var f0 = ["..KKKK..", ".KYYYYK.", "KYWYYoYK", "KYWYYoYK", "KYYYYoYK", "KYYYooYK", ".KYYYYK.", "..KKKK.."];
		var f1 = ["...KK...", "..KYYK..", ".KYWYoK.", ".KYWYoK.", ".KYYYoK.", ".KYYooK.", "..KYYK..", "...KK..."];
		var f2 = ["...KK...", "..KYoK..", "..KYoK..", "..KYoK..", "..KYoK..", "..KYoK..", "..KYoK..", "...KK..."];
		return sheet("px_coin", [f0, f1, f2, f1], ["K" => OUTLINE, "Y" => YELLOW, "W" => WHITE, "o" => ORANGE]);
	}

	public static function heavyBullet():FlxGraphic
	{
		return sheet("px_bullet_heavy", [["..oo..", ".oYYo.", "oYWWYo", "oYWWYo", ".oYYo.", "..oo.."]], ["o" => ORANGE, "Y" => YELLOW, "W" => WHITE]);
	}

	// --- Bónuszok ---------------------------------------------------------------

	public static inline var POWER_SIZE:Int = 12;

	/** 8x8-as ikonok a bónuszokhoz (sötéttel rajzolva a színes kapszulára). */
	static final POWER_ICONS:Map<String, Array<String>> = [
		"SPREAD" => [
			".....XX.",
			"...XX...",
			".XX.....",
			"XXXXXXXX",
			".XX.....",
			"...XX...",
			".....XX.",
			"........",
		],
		"RAPID" => [
			"....XXX.",
			"...XXX..",
			"..XXX...",
			".XXXXXX.",
			"...XXX..",
			"..XXX...",
			".XX.....",
			"X.......",
		],
		"BONUS" => [
			"........",
			".XXXXXX.",
			"XX.XX.XX",
			"XXXXXXXX",
			".XX..XX.",
			"..XXXX..",
			"...XX...",
			"........",
		],
		"LASER" => [
			"........",
			"XX......",
			"XXX.....",
			"XXXXXXXX",
			"XXXXXXXX",
			"XXX.....",
			"XX......",
			"........",
		],
		"SHROOM" => [
			"..XXXX..",
			".XX.XXX.",
			"XXXXX.XX",
			"XXXXXXXX",
			"...XX...",
			"...XX...",
			"..XXXX..",
			"........",
		],
		"ENERGY" => [
			"........",
			"...XX...",
			"...XX...",
			".XXXXXX.",
			".XXXXXX.",
			"...XX...",
			"...XX...",
			"........",
		],
		"HOMING" => [
			"...XX...",
			".XX..XX.",
			"X..XX..X",
			"X.XXXX.X",
			"X.XXXX.X",
			"X..XX..X",
			".XX..XX.",
			"...XX...",
		],
		"ROCKET" => [
			"......XX",
			"....XXXX",
			"..XXXXX.",
			"XXXXXXX.",
			"XXXXXXX.",
			"..XXXXX.",
			"....XXXX",
			"......XX",
		],
		"GRENADE" => [
			"....XX..",
			"...XX.X.",
			"..XXXX..",
			".XXXXXX.",
			".XXXXXX.",
			".XXXXXX.",
			"..XXXX..",
			"........",
		],
		"PIXEL" => [
			"XX..XX..",
			"XX..XX..",
			"..XX..XX",
			"..XX..XX",
			"XX..XX..",
			"XX..XX..",
			"..XX..XX",
			"..XX..XX",
		],
		"TORCH" => [
			"..XXXX..",
			".XXXXXX.",
			"..XXXX..",
			"..XXXX..",
			"...XX...",
			"...XX...",
			"...XX...",
			"...XX...",
		],
		"GHOST" => [
			"..XXXX..",
			".XXXXXX.",
			".X.XX.X.",
			".XXXXXX.",
			".XXXXXX.",
			".XXXXXX.",
			".XX.XX..",
			"........",
		],
		"TINYVIEW" => [
			"XXXXXXXX",
			"X......X",
			"X.XXXX.X",
			"X.XXXX.X",
			"X.XXXX.X",
			"X.XXXX.X",
			"X......X",
			"XXXXXXXX",
		],
		"TINYHERO" => [
			"........",
			"........",
			"...XX...",
			"..XXXX..",
			"...XX...",
			"..X..X..",
			"........",
			"........",
		],
		"ASCII" => [
			"..XXXX..",
			".X....X.",
			"X..XX..X",
			"X.X..X.X",
			"X.X.XXX.",
			"X..X....",
			".X....X.",
			"..XXXX..",
		],
		"MAGNET" => [
			".XX..XX.",
			".XX..XX.",
			".XX..XX.",
			".XX..XX.",
			".XXXXXX.",
			".XXXXXX.",
			"..XXXX..",
			"........",
		],
	];

	public static function powerColor(kind:PowerUp.PowerKind):FlxColor
	{
		return switch (kind)
		{
			case SPREAD: 0xffc8a0ff;
			case RAPID: YELLOW;
			case HOMING: 0xff7af0ff;
			case ROCKET: ORANGE;
			case LASER: 0xffff5a5a;
			case GRENADE: 0xff8fcf5a;
			case BONUS: LIME;
			case ENERGY: GREEN;
			// Módosítók (időkorlátosak, a hőst nehezítik): lilás-rózsaszín tónusok
			case SHROOM: 0xffff5ac8;
			case PIXEL: 0xffb05cd6;
			case TORCH: 0xffffd36b;
			case GHOST: 0xffa8b8e8;
			case TINYVIEW: 0xff6aa8ff;
			case TINYHERO: 0xff9af0c8;
			case MAGNET: 0xffff7a7a;
			case ASCII: 0xff6aff8a;
		}
	}

	/** Bónusz-kapszula: lekerekített, színes négyzet sötét ikonnal; 2 képkocka (alap, felizzó). */
	public static function powerUp(kind:PowerUp.PowerKind):FlxGraphic
	{
		var name = Std.string(kind);
		var key = "px_power_" + name;
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var s = POWER_SIZE, last = POWER_SIZE - 1;
		var bmd = new BitmapData(s * 2, s, true, 0);
		for (f in 0...2)
		{
			var base = f == 0 ? powerColor(kind) : powerColor(kind).getLightened(0.3);
			var hi = base.getLightened(0.45), sh = base.getDarkened(0.3);
			for (y in 0...s)
				for (x in 0...s)
				{
					var edgeX = x == 0 || x == last, edgeY = y == 0 || y == last;
					if (edgeX && edgeY)
						continue; // lekerekített sarok
					var c:Int = base;
					if (edgeX || edgeY || ((x == 1 || x == last - 1) && (y == 1 || y == last - 1)))
						c = OUTLINE;
					else if (x == 1 || y == 1)
						c = hi;
					else if (x == last - 1 || y == last - 1)
						c = sh;
					bmd.setPixel32(f * s + x, y, c);
				}
			var icon = POWER_ICONS.get(name);
			for (y in 0...icon.length)
				for (x in 0...icon[y].length)
					if (icon[y].charAt(x) == "X")
						bmd.setPixel32(f * s + 2 + x, 2 + y, OUTLINE);
		}
		return store(key, bmd);
	}

	/** Kis kétszínű forgács (blokk-törmelék). */
	public static function chip(color:FlxColor):FlxGraphic
	{
		var key = "px_chip_" + color.toHexString();
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var bmd = new BitmapData(3, 3, true, color);
		bmd.setPixel32(0, 0, color.getLightened(0.4));
		bmd.setPixel32(2, 2, color.getDarkened(0.4));
		bmd.setPixel32(2, 0, 0);
		return store(key, bmd);
	}

	public static function dust():FlxGraphic
	{
		return sheet("px_dust", [[".L.", "LWL", ".L."]], ["L" => LIGHT_GRAY, "W" => WHITE]);
	}

	/** Sebességcsík (6x1): halvány, futás közben a hős mögött. */
	public static function speedLine():FlxGraphic
	{
		return sheet("px_speedline", [["LLLLLL"]], ["L" => LIGHT_GRAY]);
	}

	// --- Meteor -------------------------------------------------------------------

	/**
	 * Meteor sheet: 3 képkocka (ép, repedt, nagyon repedt – izzó láva-repedésekkel).
	 * Szabálytalan peremű szikla, bal-felső fény, kráterek. Az arany meteor csillog.
	 */
	public static function meteor(size:Int, base:FlxColor, golden:Bool):FlxGraphic
	{
		var key = "px_meteor_" + size + "_" + base.toHexString() + (golden ? "_g" : "");
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var hi = base.getLightened(0.3), sh = base.getDarkened(0.35), sh2 = base.getDarkened(0.6);
		var lava:Int = golden ? WHITE : ORANGE;
		var c = (size - 1) / 2, r = size / 2 - 0.5;

		// Szabálytalan perem: 10 szektor, mindegyik kicsit más sugárral, simán átmenve
		function radius(ang:Float):Float
		{
			var s = (ang + Math.PI) / (Math.PI * 2) * 10;
			var k0 = Math.floor(s) % 10, k1 = (k0 + 1) % 10, f = s - Math.floor(s);
			var a = hash(k0, size * 3 + (golden ? 7 : 0)), b = hash(k1, size * 3 + (golden ? 7 : 0));
			return r * (0.82 + 0.18 * (a + (b - a) * f));
		}
		function inside(x:Int, y:Int):Bool
		{
			if (x < 0 || y < 0 || x >= size || y >= size)
				return false;
			var dx = x - c, dy = y - c;
			return Math.sqrt(dx * dx + dy * dy) <= radius(Math.atan2(dy, dx));
		}

		var bmd = new BitmapData(size * 3, size, true, 0);
		for (f in 0...3)
		{
			var ox = f * size;
			for (y in 0...size)
				for (x in 0...size)
				{
					if (!inside(x, y))
						continue;
					var col:Int = base;
					if (!inside(x - 1, y) || !inside(x + 1, y) || !inside(x, y - 1) || !inside(x, y + 1))
						col = OUTLINE;
					else
					{
						var l = ((x - c) + (y - c)) / r;
						if (l < -0.75)
							col = hi;
						else if (l > 0.6)
							col = sh;
						if (golden && hash(x + ox, y) > 0.93)
							col = WHITE; // csillogó szemcsék
					}
					bmd.setPixel32(ox + x, y, col);
				}

			// Kráterek: sötét mélyedés, a bal-felső peremén fény
			var craters = size >= 24 ? 3 : 2;
			for (i in 0...craters)
			{
				var cx = Std.int(c + (hash(i, size) - 0.5) * r * 1.0);
				var cy = Std.int(c + (hash(i + 9, size) - 0.5) * r * 1.0);
				var cr = size >= 24 ? 2 : 1;
				for (y in -cr...cr + 1)
					for (x in -cr...cr + 1)
					{
						if (x * x + y * y > cr * cr || !inside(cx + x + 1, cy + y + 1) || !inside(cx + x - 1, cy + y - 1))
							continue;
						bmd.setPixel32(ox + cx + x, cy + y, (x + y < -cr + 1) ? hi : sh2);
					}
			}

			// Izzó repedések: a 2. képkockán egy, a 3.-on több
			if (f > 0)
			{
				var rnd = new FlxRandom(size * 17 + ((base : Int) & 0xffff) + 1);
				for (i in 0...(f == 1 ? 1 : 3))
				{
					var px = Std.int(c + rnd.float(-r * 0.4, r * 0.4)), py = Std.int(c + rnd.float(-r * 0.4, r * 0.4));
					var dirX = rnd.int(-1, 1), dirY = rnd.int(-1, 1);
					if (dirX == 0 && dirY == 0)
						dirX = 1;
					for (s in 0...Std.int(size * 0.45))
					{
						if (!inside(px - 1, py) || !inside(px + 1, py) || !inside(px, py - 1) || !inside(px, py + 1))
							break;
						bmd.setPixel32(ox + px, py, s % 3 == 0 ? YELLOW : lava);
						px += dirX + (rnd.bool(30) ? rnd.int(-1, 1) : 0);
						py += dirY + (rnd.bool(30) ? rnd.int(-1, 1) : 0);
					}
				}
			}
		}
		return store(key, bmd);
	}

	// --- Hangulat, veszélyek, főellenség ---------------------------------------------

	/** Sötét, ditherelt vignetta a képernyő szélein (a komorabb hangulathoz). */
	public static function vignette(w:Int, h:Int):FlxGraphic
	{
		var key = "px_vignette";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var bmd = new BitmapData(w, h, true, 0);
		for (y in 0...h)
			for (x in 0...w)
			{
				var nx = x / (w - 1) * 2 - 1, ny = y / (h - 1) * 2 - 1;
				var d = Math.sqrt(nx * nx * 0.7 + ny * ny);
				var a = Math.max(0, Math.min(1, (d - 0.6) / 0.6));
				// Ditherelt fokozatok, hogy pixeles maradjon
				var level = Math.floor(a * 4 + bayer(x, y) - 0.5);
				if (level > 0)
					bmd.setPixel32(x, y, (Std.int(Math.min(4, level) * 0x26) << 24) | 0x050308);
			}
		return store(key, bmd);
	}

	public static inline var SHROOM_SIZE:Int = 10;

	/** Varázsgomba: lila kalap, fehér pöttyök; 2 képkocka (lüktető fény). */
	public static function shroom():FlxGraphic
	{
		var a = ["...KKKK...", ".KKpWppKK.", "KpppppWppK", "KpWppppppK", "KPPPPPPPPK", ".KKKssKKK.", "...KssK...", "...KsSK...", "..KssSSK..", "..KKKKKK.."];
		var b = [for (row in a) StringTools.replace(row, "p", "P")];
		return sheet("px_shroom", [a, b], ["K" => OUTLINE, "p" => 0xffb05cd6, "P" => 0xffe0a8ff, "W" => WHITE, "s" => 0xffe8dcc8, "S" => 0xffb8a890]);
	}

	public static inline var BOSS_W:Int = 56;
	public static inline var BOSS_H:Int = 26;

	/** Főellenség: anyahajó kupolával, a peremén villogó fényekkel (2 képkocka). */
	public static function boss():FlxGraphic
	{
		var key = "px_boss";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var w = BOSS_W, h = BOSS_H;
		function inEllipse(x:Float, y:Float, cx:Float, cy:Float, rx:Float, ry:Float):Bool
		{
			var dx = (x - cx) / rx, dy = (y - cy) / ry;
			return dx * dx + dy * dy <= 1;
		}
		function part(x:Int, y:Int):Int
		{
			// 0 = semmi, 1 = kupola, 2 = törzs, 3 = alj
			if (y <= 10 && inEllipse(x, y, 27.5, 10, 10, 8))
				return 1;
			if (inEllipse(x, y, 27.5, 15, 27, 6.5))
				return 2;
			if (inEllipse(x, y, 27.5, 19, 15, 5.5))
				return 3;
			return 0;
		}
		var bmd = new BitmapData(w * 2, h, true, 0);
		for (f in 0...2)
			for (y in 0...h)
				for (x in 0...w)
				{
					var p = part(x, y);
					if (p == 0)
						continue;
					var edge = part(x - 1, y) == 0 || part(x + 1, y) == 0 || part(x, y - 1) == 0 || part(x, y + 1) == 0;
					var col:Int = switch (p)
					{
						case 1: (x < 25 && y < 7) ? WHITE : (y < 6 ? CYAN : SKY);
						case 2: y < 14 ? LIGHT_GRAY : (y < 17 ? GRAY : DARK_GRAY);
						default: y > 21 ? OUTLINE : DARK_GRAY;
					}
					if (edge)
						col = OUTLINE;
					// Fénysor a törzs közepén, képkockánként váltakozó színnel
					if (p == 2 && y == 15 && !edge && x % 6 < 2)
						col = ((Std.int(x / 6) + f) % 2 == 0) ? 0xffff5a5a : YELLOW;
					// Vonósugár-kibocsátó alul
					if (p == 3 && y == 21 && x >= 25 && x <= 30)
						col = f == 0 ? LIME : GREEN;
					bmd.setPixel32(f * w + x, y, col);
				}
		return store(key, bmd);
	}

	/**
	 * Főellenség-sprite építője: a `draw` a képkocka pixeleit a `put(x, y, szín)` hívásokkal festi (0 = átlátszó),
	 * utána minden alakzat köré automatikus sötét körvonal kerül. A képkockák vízszintesen egymás mellé kerülnek.
	 */
	static function paintBoss(key:String, w:Int, h:Int, frames:Int, draw:(Int, (Int, Int, Int) -> Void) -> Void):FlxGraphic
	{
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var bmd = new BitmapData(w * frames, h, true, 0);
		for (f in 0...frames)
		{
			var map = [for (_ in 0...w * h) 0];
			draw(f, (x, y, c) ->
			{
				if (x >= 0 && x < w && y >= 0 && y < h)
					map[y * w + x] = c;
			});
			function at(x:Int, y:Int):Int
				return x < 0 || x >= w || y < 0 || y >= h ? 0 : map[y * w + x];
			for (y in 0...h)
				for (x in 0...w)
				{
					var c = at(x, y);
					if (c == 0 && (at(x - 1, y) != 0 || at(x + 1, y) != 0 || at(x, y - 1) != 0 || at(x, y + 1) != 0))
						c = OUTLINE;
					if (c != 0)
						bmd.setPixel32(f * w + x, y, c);
				}
		}
		return store(key, bmd);
	}

	static inline function inEll(x:Float, y:Float, cx:Float, cy:Float, rx:Float, ry:Float):Bool
	{
		var dx = (x - cx) / rx, dy = (y - cy) / ry;
		return dx * dx + dy * dy <= 1;
	}

	public static inline var TANK_W:Int = 64;
	public static inline var TANK_H:Int = 40;

	/**
	 * A 2. pálya főellenség: harckocsi (kézi rajz alapján): lánctalpas test három kerékkel, dobozos felépítmény két mérges szemmel,
	 * kupolás torony antennával és balra néző hosszú ágyú. 2 képkocka (pislogás, forgó kerekek, villogó antenna).
	 */
	public static function bossTank():FlxGraphic
	{
		return paintBoss("px_boss_tank", TANK_W, TANK_H, 2, (f, put) ->
		{
			// Lánctalpas test: lefelé keskenyedő trapéz
			for (y in 29...39)
			{
				var inset = Std.int((y - 29) * 0.6);
				for (x in 8 + inset...61 - inset)
					put(x, y, y <= 30 ? GRAY : (y >= 37 ? OUTLINE : DARK_GRAY));
			}
			// Kerekek: világos gyűrű, forgó "csavar" a közepén
			for (cx in [20, 34, 48])
				for (y in 31...38)
					for (x in cx - 3...cx + 4)
						if (inEll(x, y, cx, 34, 3.4, 3.4))
							put(x, y, inEll(x, y, cx + (f == 0 ? 0 : 1), 34 + (f == 0 ? -1 : 0), 1, 1) ? OUTLINE : LIGHT_GRAY);

			// Dobozos felépítmény
			for (y in 15...29)
				for (x in 12...57)
					put(x, y, y == 28 ? OUTLINE : (y < 17 ? LIME : (y < 25 ? GREEN : TEAL)));

			// Szemek: fehér, balra néző pupilla, befelé lejtő (mérges) szemöldök; a 2. képkockán pislog
			for (ex in [26, 42])
			{
				var top = f == 0 ? 19 : 20;
				for (y in top...23)
					for (x in ex - 3...ex + 4)
						put(x, y, WHITE);
				for (y in top + 1...top + 3)
					for (x in ex - 3...ex - 1)
						put(x, y, OUTLINE);
				for (i in 0...8)
				{
					var bx = ex < 30 ? ex - 4 + i : ex + 4 - i;
					put(bx, 16 + Std.int(i / 3), OUTLINE);
				}
			}

			// Ágyú balra (hosszú cső, torkolatgyűrűvel)
			for (x in 2...31)
				for (y in 9...12)
					put(x, y, y == 9 ? GRAY : DARK_GRAY);
			for (y in 8...13)
				for (x in 2...6)
					put(x, y, y == 8 || y == 12 ? DARK_GRAY : GRAY);

			// Kupolás torony a felépítményen
			for (y in 5...16)
				for (x in 28...49)
					if (inEll(x, y, 38.5, 15, 10, 9.5))
						put(x, y, y < 8 ? LIME : (y < 12 ? GREEN : TEAL));

			// Antenna villogó heggyel
			for (y in 1...6)
				put(40, y, GRAY);
			put(40, 1, f == 0 ? RED : YELLOW);
			put(40, 2, f == 0 ? RED : ORANGE);
		});
	}

	public static inline var GHOST_W:Int = 64;
	public static inline var GHOST_H:Int = 56;

	/**
	 * A 3. pálya főellenség: kísértetféreg (kézi rajz alapján): nagy fej egyetlen résszemmel, balra nyíló agyaras szájjal,
	 * a teste jobbra-le kanyarodik, és ujjas "lábban" végződik. 2 képkocka (tátogó száj, mozgó lábujjak).
	 */
	public static function bossGhost():FlxGraphic
	{
		return paintBoss("px_boss_ghost", GHOST_W, GHOST_H, 2, (f, put) ->
		{
			for (y in 1...GHOST_H - 1)
				for (x in 4...GHOST_W - 1)
				{
					var inside = inEll(x, y, 24, 20, 17, 19) || inEll(x, y, 32, 34, 15, 12) || inEll(x, y, 40, 46, 17, 8) || inEll(x, y, 53, 43, 9, 11);
					if (!inside)
						continue;
					var s = x * 0.4 + y * 0.8;
					put(x, y, s < 24 ? 0xffe6e0fa : (s < 42 ? 0xffc0b6e6 : 0xff8f82c2));
				}

			// Lábujjak közti rések
			var toe = 0xff6a5ea0;
			for (x in 47...54)
				put(x, 38 + f, toe);
			for (x in 46...54)
				put(x, 48 - f, toe);

			// Száj: sötét üreg, vöröses nyelv, agyarak fent és lent
			var mry = f == 0 ? 5.5 : 7;
			for (y in 20...38)
				for (x in 4...22)
					if (inEll(x, y, 13, 29, 8.5, mry))
						put(x, y, y > 30 ? 0xff7a1f3a : 0xff2a1030);
			for (fx in [9, 13, 17])
			{
				var ty = Std.int(29 - mry * Math.sqrt(Math.max(0, 1 - ((fx - 13) / 8.5) * ((fx - 13) / 8.5)))) + 1;
				put(fx, ty, WHITE);
				put(fx, ty + 1, WHITE);
				put(fx + 1, ty, WHITE);
				put(fx, ty + 2, WHITE);
				var by = Std.int(29 + mry * Math.sqrt(Math.max(0, 1 - ((fx + 2 - 13) / 8.5) * ((fx + 2 - 13) / 8.5)))) - 1;
				put(fx + 2, by, WHITE);
				put(fx + 2, by - 1, WHITE);
			}

			// Egyetlen résszem, sárga fénnyel
			for (y in 10...17)
			{
				put(21, y, YELLOW);
				put(23, y, YELLOW);
				put(22, y, OUTLINE);
			}
		});
	}

	/** Vonalszakasz-lánc festése `r` sugarú ecsettel (karok, nyelv, szemnyél): a `col` adja egy pixel színét. */
	static function tube(put:(Int, Int, Int) -> Void, pts:Array<Array<Float>>, r:Float, col:(Int, Int) -> Int):Void
	{
		for (i in 0...pts.length - 1)
		{
			var a = pts[i], b = pts[i + 1];
			var n = Std.int(Math.max(Math.abs(b[0] - a[0]), Math.abs(b[1] - a[1]))) * 2 + 1;
			for (k in 0...n + 1)
			{
				var px = a[0] + (b[0] - a[0]) * k / n, py = a[1] + (b[1] - a[1]) * k / n;
				for (y in Std.int(py - r) - 1...Std.int(py + r) + 2)
					for (x in Std.int(px - r) - 1...Std.int(px + r) + 2)
						if ((x - px) * (x - px) + (y - py) * (y - py) <= r * r)
							put(x, y, col(x, y));
			}
		}
	}

	public static inline var BRUTE_W:Int = 72;
	public static inline var BRUTE_H:Int = 80;

	/**
	 * A 4. pálya főellenség: izomtömeg (kézi rajz alapján): tojásdad test két bozontos mellfolttal, széles, fogas szájú fej
	 * mérges szemekkel, két behajlított kar sötét gömbökkel a kezekben, terpesz láb.
	 * 4 képkockás járásciklus: 0 és 2 álló, az 1-en a bal, a 3-on a jobb láb emelkedik, a test ilyenkor 1 px-et lejjebb ül; a száj és a gömbök is mozognak.
	 */
	public static function bossBrute():FlxGraphic
	{
		return paintBoss("px_boss_brute", BRUTE_W, BRUTE_H, 4, (f, rawPut) ->
		{
			var cx = 36;
			var bob = (f == 1 || f == 3) ? 1 : 0; // a test a lépések között lejjebb ül
			var fm = f % 2;
			// A test a járással együtt lüktet; a lábak fixen állnak (rawPut)
			var put = (x:Int, y:Int, c:Int) -> rawPut(x, y + bob, c);
			function skin(x:Int, y:Int):Int
			{
				var s = x * 0.5 + y * 0.6;
				return s < 34 ? LIME : (s < 56 ? GREEN : TEAL);
			}

			// Lábak: lefelé kifelé tartó oszlopok, kifelé néző lábfejjel
			for (side in [-1, 1])
			{
				// Lépésciklus lábanként (a két láb fél ciklussal eltolva): előre lép és letaposik (-5), hátracsúszik (-1), hátul
				// ellök (+5), majd felemelve előrehozza (0, 5 px magasan). A láb a csípőtől a talpig megdől a lépéssel.
				var p = (f + (side > 0 ? 2 : 0)) % 4;
				var swing = [-5, -1, 5, 0][p];
				var lift = [0, 0, 0, 5][p];
				for (y in 56...75 - lift)
				{
					var c = cx + side * (9 + (y - 56) * 0.35) + swing * (y - 56) / 18;
					for (x in Std.int(c - 4)...Std.int(c + 5))
						rawPut(x, y, skin(x, y));
				}
				var fc = cx + side * (9 + 18 * 0.35) + swing;
				for (y in 74 - lift...79 - lift)
					for (x in Std.int(side < 0 ? fc - 10 : fc - 3)...Std.int(side < 0 ? fc + 4 : fc + 11))
						rawPut(x, y, y == 74 - lift ? GREEN : TEAL);
			}

			// Törzs: felül széles, lefelé keskenyedő tojásforma
			for (y in 28...61)
			{
				var dy = (y - 40) / 12;
				var hw:Float = y < 40 ? 17 * Math.sqrt(Math.max(0, 1 - dy * dy)) : 17 - (y - 40) * 0.6;
				for (x in Std.int(Math.ceil(cx - hw))...Std.int(cx + hw) + 1)
					put(x, y, skin(x, y));
			}

			// Bozontos mellfoltok közepükön egy-egy ponttal
			for (px in [28, 44])
				for (y in 40...53)
					for (x in px - 6...px + 7)
					{
						var d = Math.sqrt((x - px) * (x - px) + (y - 46) * (y - 46));
						if (d <= 4.6 + ((x * 7 + y * 13) % 3 == 0 ? 1.0 : 0))
							put(x, y, 0xff1c6b52);
					}
			for (px in [28, 44])
			{
				put(px, 46, OUTLINE);
				put(px + 1, 46, OUTLINE);
			}

			// Alsó rész: sötét háromszög
			for (y in 57...63)
			{
				var hw = 6 - (y - 57) * 1.1;
				for (x in Std.int(Math.ceil(cx - hw))...Std.int(cx + hw) + 1)
					put(x, y, (x + y) % 3 == 0 ? OUTLINE : PLUM);
			}

			// Karok: a bal kar kifelé, majd felfelé; a jobb kar kifelé, majd horogszerűen felkunkorodik
			tube(put, [[21, 38], [11, 43], [8, 29]], 3, skin);
			tube(put, [[51, 38], [62, 44], [67, 38], [64, 28]], 3.2, skin);

			// Fej: széles ovális, alul sötétebb
			for (y in 6...31)
				for (x in cx - 16...cx + 17)
					if (inEll(x, y, cx, 18, 15, 12))
						put(x, y, y < 12 ? LIME : (y < 26 ? GREEN : TEAL));

			// Száj: sötét üreg, fent és lent fogakkal
			var ry = fm == 0 ? 5.0 : 6.5;
			for (y in 14...31)
				for (x in cx - 12...cx + 13)
					if (inEll(x, y, cx, 22, 11, ry))
						put(x, y, y > 24 ? 0xff7a1f3a : 0xff2a1030);
			var ty = Std.int(22 - ry) + 1;
			for (tx in [28, 32, 36, 40])
				for (yy in ty...ty + 3)
				{
					put(tx, yy, WHITE);
					put(tx + 1, yy, WHITE);
				}
			var by = Std.int(22 + ry) - 1;
			for (tx in [30, 34, 38])
				for (yy in by - 1...by + 1)
				{
					put(tx, yy, WHITE);
					put(tx + 1, yy, WHITE);
				}

			// Szemek: fehér, balra néző pupilla, befelé lejtő (mérges) szemöldök
			for (ex in [26, 46])
			{
				for (y in 6...9)
					for (x in ex - 2...ex + 3)
						put(x, y, WHITE);
				put(ex - 2, 7, OUTLINE);
				put(ex - 2, 8, OUTLINE);
				put(ex - 1, 7, OUTLINE);
				for (i in 0...5)
					put(ex < cx ? ex - 3 + i : ex + 3 - i, 3 + Std.int(i / 2.5), OUTLINE);
			}

			// Sötét gömbök a kezekben (spirálos mintával)
			function orb(ox:Int, oy:Int, r:Float):Void
			{
				for (y in Std.int(oy - r) - 1...Std.int(oy + r) + 2)
					for (x in Std.int(ox - r) - 1...Std.int(ox + r) + 2)
					{
						var d = Math.sqrt((x - ox) * (x - ox) + (y - oy) * (y - oy));
						if (d > r)
							continue;
						var a = Math.atan2(y - oy, x - ox);
						var band = Std.int(Math.abs(Math.floor(d * 0.9 - a * 0.8 + fm * 1.5))) % 2;
						put(x, y, band == 0 ? 0xff3b2a6b : OUTLINE);
					}
				put(Std.int(ox - r * 0.45), Std.int(oy - r * 0.45), LIGHT_GRAY);
			}
			orb(7, 22 - fm, 4.4);
			orb(63, 21 - fm, 6);
		});
	}

	public static inline var HOLLOW_W:Int = 80;
	public static inline var HOLLOW_H:Int = 80;

	/**
	 * A 9. pálya főellenség: a kiüresedett hold: nagy, kráteres, megrepedt holdkorong, a repedésen át izzó mag lüktet
	 * (2 képkocka). Világos bal felső, sötét jobb alsó oldal.
	 */
	public static function bossHollow():FlxGraphic
	{
		return paintBoss("px_boss_hollow", HOLLOW_W, HOLLOW_H, 2, (f, put) ->
		{
			var cx = 39.5, cy = 39.5, r = 37.0;
			for (y in 0...HOLLOW_H)
				for (x in 0...HOLLOW_W)
				{
					var dx = x - cx, dy = y - cy;
					if (dx * dx + dy * dy > r * r)
						continue;
					var s = dx * 0.5 + dy * 0.6 + hash(x, y) * 5;
					put(x, y, s < -16 ? 0xffe6e0f4 : (s < 12 ? 0xffc4bcdc : (s < 28 ? 0xff8a82a8 : 0xff5a5478)));
				}
			// Kráterek: sötét mélyedés, a bal-felső peremén fény
			for (c in [[26, 26, 6], [54, 28, 4], [48, 54, 7], [22, 52, 3], [58, 44, 3]])
				for (y in c[1] - c[2]...c[1] + c[2] + 1)
					for (x in c[0] - c[2]...c[0] + c[2] + 1)
					{
						var d = (x - c[0]) * (x - c[0]) + (y - c[1]) * (y - c[1]);
						if (d <= c[2] * c[2])
							put(x, y, (x - c[0] + y - c[1]) < -c[2] * 0.6 ? 0xffe6e0f4 : 0xff6a6488);
					}
			// A repedés: lila perem, sárga-fehér izzó mag (a 2. képkockán világosabb)
			var crack:Array<Array<Float>> = [[48, 3], [42, 15], [47, 27], [38, 39], [44, 53], [33, 64], [36, 77]];
			var glow = f == 0 ? 0xffd04cff : 0xffff7ae8;
			var core = f == 0 ? 0xffffcd75 : 0xfffff2c0;
			tube(put, crack, 2.4, (x, y) -> glow);
			tube(put, crack, 1.1, (x, y) -> core);
			// Mellékrepedések
			tube(put, [[44, 53], [56, 58], [64, 66]], 1.2, (x, y) -> glow);
			tube(put, [[47, 27], [58, 24], [68, 18]], 1.2, (x, y) -> glow);
		});
	}
	public static inline var BOSSSLIME_W:Int = 88;
	public static inline var BOSSSLIME_H:Int = 64;

	/**
	 * A végső főellenség alapformája: óriás lila slime (a kis slime ellenség nagy változata): fényes kupola, belül buborékok,
	 * mérges szemek és vigyorgó, fogas száj. 4 képkocka: a test hullámzik (nyúlik-zsugorodik), a száj tátog.
	 */
	public static function bossSlime():FlxGraphic
	{
		return paintBoss("px_boss_slime", BOSSSLIME_W, BOSSSLIME_H, 4, (f, put) ->
		{
			var sx = [1.0, 1.07, 1.0, 0.95][f], sy = [1.0, 0.9, 1.0, 1.08][f];
			var rx = 41.0 * sx, ry = 54.0 * sy;
			var cx = 44.0, by = BOSSSLIME_H - 1;
			function inside(x:Int, y:Int):Bool
			{
				var dx = (x - cx) / rx, dy = (y - by) / ry;
				return y <= by && dx * dx + dy * dy <= 1;
			}
			var base = 0xffb05cd6, light = 0xffe0a8ff, shade = 0xff8a45ab, dark = PLUM;
			for (y in 0...BOSSSLIME_H)
				for (x in 0...BOSSSLIME_W)
				{
					if (!inside(x, y))
						continue;
					var l = ((x - cx) + (y - by)) / (rx * 0.9);
					var c:Int = base;
					if (l < -0.85)
						c = light;
					else if (l > 0.25)
						c = shade;
					if (y > by - 4)
						c = dark; // alsó, sötét perem
					put(x, y, c);
				}
			// Fényes folt a bal felső kupolán és néhány buborék a testben
			for (y in 8...20)
				for (x in 18...36)
					if (inside(x, y) && inEll(x, y, 26, 14, 8, 4))
						put(x, y, 0xfff4e6ff);
			for (b in [[60, 40, 4], [70, 46, 3], [24, 46, 3], [50, 50, 2]])
				for (y in b[1] - b[2]...b[1] + b[2] + 1)
					for (x in b[0] - b[2]...b[0] + b[2] + 1)
						if (inEll(x, y, b[0], b[1], b[2], b[2]) && inside(x, y))
							put(x, y, (x + y) % 2 == 0 ? light : base);
			// Szemek: fehér, balra néző pupilla, mérges szemöldök
			for (ex in [32, 56])
			{
				for (y in 21...32)
					for (x in ex - 6...ex + 7)
						if (inEll(x, y, ex, 26, 6, 5))
							put(x, y, WHITE);
				for (y in 24...29)
					for (x in ex - 4...ex - 1)
						put(x, y, OUTLINE);
				for (i in 0...9)
					put(ex < cx ? ex - 6 + i : ex + 6 - i, 18 + Std.int(i / 3), OUTLINE);
			}
			// Száj: széles, fogas, tátogó
			var open = f % 2 == 0 ? 3 : 6;
			for (y in 38...38 + open + 2)
				for (x in 24...65)
					if (inEll(x, y, 44, 38, 20, open + 1) && y >= 38)
						put(x, y, 0xff2a1030);
			for (tx in 26...63)
				if ((tx - 26) % 5 == 0)
				{
					put(tx, 38, WHITE);
					put(tx, 39, WHITE);
					put(tx + 1, 38, WHITE);
				}
		});
	}
	public static inline var PUFF_BOSS_W:Int = 72;
	public static inline var PUFF_BOSS_H:Int = 96;

	/** Bolyhos lila pihegolyó (8x8): a bolyhos óriás pattogó és szálló lövedéke. */
	public static function puff():FlxGraphic
	{
		var key = "px_puff";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var bmd = new BitmapData(8, 8, true, 0);
		for (y in 0...8)
			for (x in 0...8)
			{
				var dx = x - 3.5, dy = y - 3.5, d = Math.sqrt(dx * dx + dy * dy);
				if (d > 3.9)
					continue;
				bmd.setPixel32(x, y, d > 3.0 ? OUTLINE : ((dx + dy) < -1.5 ? 0xfff0e6ff : 0xffb09ad8));
			}
		return store(key, bmd);
	}

	/**
	 * A 8. pálya főellenség: bolyhos óriás (kézi rajz alapján): hullámos szélű, felhőszerű, széles test két vastag lábbal és közöttük
	 * boltívvel, a tetején két hullámzó szemnyélen mérges szemek. 4 képkockás járásciklus (a lábak váltva emelkednek, a test lüktet).
	 */
	public static function bossPuff():FlxGraphic
	{
		// 8 képkocka: 0-3 nyitott szemmel, 4-7 ugyanaz csukott szemmel (a pislogáshoz)
		return paintBoss("px_boss_puff", PUFF_BOSS_W, PUFF_BOSS_H, 8, (fAll, rawPut) ->
		{
			var f = fAll % 4;
			var closed = fAll >= 4;
			var bob = (f == 1 || f == 3) ? 1 : 0;
			var put = (x:Int, y:Int, c:Int) -> rawPut(x, y + bob, c);
			// Bolyhos textúra: puha, ívelt árnyékok cellánként
			function fluff(x:Int, y:Int):Int
			{
				var cx = (x + (Std.int(y / 7) % 2) * 3) % 7, cy = y % 7;
				var s = x * 0.25 + y * 0.35;
				if (cx == 0 && cy < 4)
					return 0xff7e6bb0;
				return s < 20 ? 0xfff0e6ff : (s < 34 ? 0xffd9c8f0 : 0xffb09ad8);
			}
			// Hullámos (felhőszerű) szél
			function wob(y:Int, k:Int):Int
				return Math.round(1.8 * Math.sin(y * 0.85 + k));

			// Lábak: két vastag oszlop a test két szélén, váltva emelkednek
			for (side in [-1, 1])
			{
				var lift = ((f == 1 && side < 0) || (f == 3 && side > 0)) ? 4 : 0;
				var l = side < 0 ? 10 : 44, r = side < 0 ? 28 : 62;
				for (y in 60...95 - lift)
					for (x in l + wob(y, side)...r + wob(y, side + 3) + 1)
						rawPut(x, y, fluff(x, y));
			}
			// Törzs: széles, hullámos téglalap
			for (y in 24...68)
				for (x in 12 + wob(y, 1)...60 + wob(y, 4) + 1)
					put(x, y, fluff(x, y));
			// Bolyhos felső perem (púpok)
			for (x in 12...61)
				for (dy in 0...Std.int(2 + 2 * Math.abs(Math.sin(x * 0.55))))
					put(x, 23 - dy, fluff(x, 23 - dy));

			// Két hullámzó szemnyél és a szemek
			for (e in [[30, 27, 27, 12], [42, 27, 45, 12]])
				tube(put, [[e[0], e[1]], [e[2], 19], [e[0] + (f == 1 ? 1 : (f == 3 ? -1 : 0)), e[3]]], 1.4, (x, y) -> 0xffb09ad8);
			for (ex in [30, 42])
			{
				for (y in 3...14)
					for (x in ex - 5...ex + 6)
						if (inEll(x, y, ex, 9, 5, 5))
							put(x, y, closed ? 0xffd9c8f0 : WHITE); // csukott szemnél bőrszínű szemhéj
				if (closed)
				{
					for (x in ex - 4...ex + 5)
						put(x, 10, OUTLINE);
				}
				else
				{
					put(ex - 2, 9, OUTLINE);
					put(ex - 2, 10, OUTLINE);
					put(ex - 3, 9, OUTLINE);
				}
			}
			// Mérges szemöldök: befelé lejtő
			for (i in 0...6)
			{
				put(24 + i, 0 + Std.int(i / 2.5), OUTLINE);
				put(48 - i, 0 + Std.int(i / 2.5), OUTLINE);
			}
		});
	}

	public static inline var STRIDER_W:Int = 88;
	public static inline var STRIDER_H:Int = 84;

	/**
	 * A 7. pálya főellenség: szőrös pók (kézi rajz alapján): nagy gömbölyű, csíkosan szőrös potroh, balra egy kisebb ovális fej
	 * kunkorodó szarvval és vörös szemekkel, alatta hat hosszú, vékony láb. 4 képkockás járásciklus (a lábak két csoportban váltva lépnek).
	 */
	public static function bossStrider():FlxGraphic
	{
		return paintBoss("px_boss_strider", STRIDER_W, STRIDER_H, 4, (f, rawPut) ->
		{
			var bob = (f == 1 || f == 3) ? 1 : 0;
			var put = (x:Int, y:Int, c:Int) -> rawPut(x, y + bob, c);
			function fur(x:Int, y:Int):Int
			{
				var s = x * 0.3 + y * 0.45 + hash(x, y) * 5;
				return s < 26 ? 0xff9b7a58 : (s < 42 ? 0xff7a5a44 : 0xff4a3426);
			}
			var legCol = (x:Int, y:Int) -> hash(x, y) > 0.8 ? 0xff5a4030 : 0xff3b2a1e;

			// Hat hosszú láb: két csoport (páros / páratlan), a lépés közben az egyik csoport felemelkedik
			for (i in 0...6)
			{
				var g = i % 2;
				// A lábak a potroh alatt, a vászon szélén belül maradnak (a hátsó láb se lógjon ki és vágódjon le)
				var bx = 32 + i * 8;
				var lifted = (f == 1 && g == 0) || (f == 3 && g == 1);
				var swing = lifted ? -4 : (((f + g) % 2 == 0) ? 2 : -2);
				var lift = lifted ? 5 : 0;
				var out = (i - 2.5) * 3.5;
				tube(rawPut, [[bx, 54], [bx + out, 70 - lift / 2], [bx + out * 0.6 + swing, 83 - lift]], 1.5, legCol);
			}

			// Potroh: nagy gömb, függőleges szőrcsíkokkal
			for (y in 2...58)
				for (x in 28...88)
					if (inEll(x, y, 58, 30, 28, 27))
						put(x, y, ((x * 13) % 7 == 0 && (x + y) % 6 < 4) ? 0xff3b2a1e : fur(x, y));

			// Fej: kisebb ovális, a bal oldalon
			for (y in 37...63)
				for (x in 6...38)
					if (inEll(x, y, 22, 50, 15, 12))
						put(x, y, fur(x, y + 8));

			// Kunkorodó szarv a fej bal oldalán
			tube(put, [[9, 46], [3, 52], [5, 60]], 1.5, (x, y) -> 0xff3b2a1e);

			// Szemek: három vörös folt, a középpontjukban egy fényponttal
			for (e in [[17, 45], [22, 48], [14, 51]])
			{
				for (dy in 0...2)
					for (dx in 0...2)
						put(e[0] + dx, e[1] + dy, RED);
				put(e[0], e[1], YELLOW);
			}
			// Száj
			for (x in 11...18)
				put(x, 58, OUTLINE);
		});
	}

	public static inline var KILLER_W:Int = 64;
	public static inline var KILLER_H:Int = 90;

	/**
	 * A 6. pálya főellenség: a bozontos gyilkos (kézi rajz alapján): gömbölyű fej egyetlen nagy szemmel és balra nyíló, fogas
	 * szájjal, hosszú nyak, két lelógó bozontos kar karmos kézzel, magas bozontos lábak. Balra néz. 4 képkockás járásciklus
	 * (mint az izomtömegnél: lépésenként lengő láb, bólogató test, pislogó szem).
	 */
	public static function bossKiller():FlxGraphic
	{
		return paintBoss("px_boss_killer", KILLER_W, KILLER_H, 4, (f, rawPut) ->
		{
			var bob = (f == 1 || f == 3) ? 1 : 0;
			var put = (x:Int, y:Int, c:Int) -> rawPut(x, y + bob, c);
			// Bozontos szőr: bal-felső fény, a szélek csipkések (a zaj az x/y függvénye, így képkockánként stabil)
			function fur(x:Int, y:Int):Int
			{
				var s = x * 0.4 + y * 0.5 + hash(x, y) * 7;
				return s < 30 ? 0xff7a5a8c : (s < 52 ? 0xff4a3560 : 0xff2c2040);
			}
			function jag(y:Int, k:Int):Int
				return hash(y, k) > 0.5 ? 1 : -1;

			// Lábak: magasak, szálkásak, lépésciklussal
			for (side in [-1, 1])
			{
				var p = (f + (side > 0 ? 2 : 0)) % 4;
				var swing = [-4, -1, 4, 0][p];
				var lift = [0, 0, 0, 5][p];
				for (y in 64...87 - lift)
				{
					var c = 32 + side * 9 + swing * (y - 64) / 22;
					var hw = 5 + jag(y, 7 + side);
					for (x in Std.int(c - hw)...Std.int(c + hw) + 1)
						rawPut(x, y, fur(x, y));
				}
			}

			// Törzs: bozontos trapéz
			for (y in 36...70)
			{
				var hw = 17 - (y - 36) * 0.12 + jag(y, 3);
				for (x in Std.int(Math.ceil(32 - hw))...Std.int(32 + hw) + 1)
					put(x, y, fur(x, y));
			}

			// Karok: a törzs két oldalán lelógó, csipkés szélű hasábok, alul karmos kézzel
			for (side in [-1, 1])
			{
				var ax = 32 + side * 23;
				var sway = (f == 1 ? 1 : (f == 3 ? -1 : 0)) * side;
				for (y in 38...72)
				{
					var hw = 6 + jag(y, 11 + side);
					for (x in Std.int(ax - hw + sway)...Std.int(ax + hw + sway) + 1)
						put(x, y, fur(x, y));
				}
				for (k in -1...2)
					for (y in 72...79)
						put(ax + sway + k * 4, y, y > 75 ? LIGHT_GRAY : fur(ax, y));
			}

			// Hosszú nyak és a gömbölyű fej
			for (y in 24...40)
				for (x in 30...43)
					put(x, y, fur(x, y));
			for (y in 2...32)
				for (x in 14...46)
					if (inEll(x, y, 30, 17, 15, 14))
						put(x, y, y < 10 ? 0xff7a5a8c : (y < 22 ? 0xff4a3560 : 0xff2c2040));

			// Fogas száj a bal oldalon: sötét üreg, fent és lent csipkés fogak
			var open = f % 2 == 0 ? 5.0 : 7.0;
			for (y in 14...31)
				for (x in 12...30)
					if (inEll(x, y, 20, 23, 9, open))
						put(x, y, y > 24 ? 0xff7a1f3a : 0xff2a1030);
			var tt = Std.int(23 - open) + 1;
			for (tx in [13, 16, 19, 22, 25])
			{
				put(tx, tt, WHITE);
				put(tx, tt + 1, WHITE);
				put(tx + 1, tt, WHITE);
			}
			var tb = Std.int(23 + open) - 2;
			for (tx in [14, 18, 22])
			{
				put(tx, tb, WHITE);
				put(tx, tb + 1, WHITE);
			}

			// Egyetlen nagy szem: fehér ovális, vörös pupilla balra, a 2. és 4. képkockán félig hunyt
			var ey = 8;
			for (y in ey...ey + 10)
				for (x in 30...38)
					if (inEll(x, y, 34, ey + 5, 4, 5))
						put(x, y, (f % 2 == 1 && y < ey + 3) ? 0xff4a3560 : WHITE);
			for (y in ey + 3...ey + 8)
				for (x in 31...34)
					put(x, y, RED);
			put(31, ey + 4, OUTLINE);
		});
	}

	public static inline var WAVE_W:Int = 32;
	public static inline var WAVE_H:Int = 14;

	/**
	 * Lökéshullám a talajon (jobbra fut, a taréj a jobb szélén): fényes, domború hullámtaréj, mögötte kihunyó, ditherelt
	 * hullámgyűrűk és porszemek. 4 képkocka (a gyűrűk haladnak). Additív keveréssel rajzoljuk, így fényhatásnak hat, nem tömör blokknak.
	 */
	public static function shockwave():FlxGraphic
	{
		var key = "px_shockwave";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var w = WAVE_W, h = WAVE_H;
		var bmd = new BitmapData(w * 4, h, true, 0);
		function argb(a:Int, c:Int):Int
			return (a << 24) | (c & 0xffffff);
		for (f in 0...4)
		{
			var xc = 24.0 + f * 0.5;
			for (x in 0...w)
			{
				var dx = x - xc;
				var dome = Math.abs(dx) <= 7 ? 9 * Math.sqrt(1 - (dx / 7) * (dx / 7)) : 0.0;
				// Mögötte haladó, halványodó hullámok
				var ripple = 0.0;
				if (dx < -7)
				{
					var fade = Math.max(0, 1 - (-dx - 7) / 18);
					ripple = Math.max(0, 3.5 * Math.sin(-dx * 0.55 - f * 1.5708)) * fade;
				}
				var hh = Math.max(dome, ripple);
				var top = h - 1 - Math.round(hh);
				if (hh < 0.6)
				{
					// Porszem a talaj mentén
					if (hash(x + f * 31, 5) > 0.82)
						bmd.setPixel32(f * w + x, h - 1, argb(0x70, LIGHT_GRAY));
					continue;
				}
				bmd.setPixel32(f * w + x, top, argb(0xff, WHITE));
				if (top + 1 < h)
					bmd.setPixel32(f * w + x, top + 1, argb(0xe0, YELLOW));
				for (y in top + 2...h)
				{
					if (bayer(x, y) > 0.65)
						continue;
					var a = Std.int(0xb0 * (1 - (y - top) / (hh + 2)));
					if (a > 0)
						bmd.setPixel32(f * w + x, y, argb(a, ORANGE));
				}
			}
		}
		return store(key, bmd);
	}

	public static inline var STALKER_W:Int = 56;
	public static inline var STALKER_H:Int = 84;

	/**
	 * Az 5. pálya főellenség: háromszemű nyálka (kézi rajz alapján): magas, körte alakú test, tetején három szemnyél mérges
	 * szemöldökkel, a testen hullámos száj, alul két lebenyes láb. Balra néz (a pupillák). 2 képkocka (hullámzó száj, hunyorgó szemek).
	 */
	public static function bossStalker():FlxGraphic
	{
		return paintBoss("px_boss_stalker", STALKER_W, STALKER_H, 2, (f, put) ->
		{
			function skin(x:Int, y:Int):Int
			{
				var s = x * 0.4 + y * 0.5;
				return s < 30 ? SKY : (s < 46 ? BLUE : NAVY);
			}

			// Test: felül kerek, lefelé lassan szűkül, alul két lebeny
			for (y in 31...84)
				for (x in 0...STALKER_W)
				{
					var inside = inEll(x, y, 28, 47, 22, 16) || (y >= 47 && y <= 74 && Math.abs(x - 28) <= 21 - (y - 47) * 0.28)
						|| inEll(x, y, 19, 77, 8.5, 7) || inEll(x, y, 37, 77, 8.5, 7);
					if (!inside || (y > 78 && Math.abs(x - 28) <= 1))
						continue;
					put(x, y, skin(x, y));
				}

			// Szemnyelek hullámzó vonallal, a szemgolyók a tetején
			var eyes = [[12, 15, 18, 34], [28, 12, 28, 32], [44, 14, 38, 34]];
			for (e in eyes)
				tube(put, [[e[2] + Math.sin(f * 1.6) * 1.2, e[3]], [(e[0] + e[2]) / 2 + (f == 0 ? 1.5 : -1.5), (e[1] + e[3]) / 2], [e[0], e[1] + 4]], 1.7, skin);
			for (e in eyes)
			{
				for (y in e[1] - 5...e[1] + 6)
					for (x in e[0] - 5...e[0] + 6)
						if (inEll(x, y, e[0], e[1], 5, 5))
							put(x, y, (f == 1 && y < e[1] - 2) ? BLUE : WHITE); // a 2. képkockán hunyorog
				put(e[0] - 3, e[1], OUTLINE);
				put(e[0] - 2, e[1], OUTLINE);
				put(e[0] - 3, e[1] + 1, OUTLINE);
				put(e[0] - 2, e[1] + 1, OUTLINE);
			}

			// Mérges szemöldök: két ferde vonás és egy vízszintes
			for (i in 0...6)
			{
				put(6 + i, 1 + Std.int(i / 2.5), OUTLINE);
				put(49 - i, 1 + Std.int(i / 2.5), OUTLINE);
				put(25 + i, 3, OUTLINE);
			}

			// Hullámos száj egy ponttal a bal végén
			for (x in 14...43)
			{
				var yy = 53 + Math.round(Math.sin((x + f * 2) * 0.9) * 1.5);
				put(x, yy, OUTLINE);
				put(x, yy + 1, OUTLINE);
			}
			put(11, 56, OUTLINE);
		});
	}

	// --- Logó ---------------------------------------------------------------------

	public static inline var LOGO_CELL:Int = 7;

	/** 5x5-ös betűk a "MOONSHARD" logóhoz; a cellák mindig oldalukkal kapcsolódnak (átlós érintkezés szétesőnek látszik). */
	static final LOGO_FONT:Map<String, Array<String>> = [
		"B" => ["XXXX.", "X..XX", "XXXX.", "X..XX", "XXXX."],
		"L" => ["X....", "X....", "X....", "X....", "XXXXX"],
		"O" => ["XXXXX", "X...X", "X...X", "X...X", "XXXXX"],
		"C" => ["XXXXX", "X....", "X....", "X....", "XXXXX"],
		"K" => ["X..XX", "X.XX.", "XXX..", "X.XX.", "X..XX"],
		"U" => ["X...X", "X...X", "X...X", "X...X", "XXXXX"],
		"S" => ["XXXXX", "X....", "XXXXX", "....X", "XXXXX"],
		"T" => ["XXXXX", "..X..", "..X..", "..X..", "..X.."],
		"E" => ["XXXXX", "X....", "XXXX.", "X....", "XXXXX"],
		"R" => ["XXXX.", "X..XX", "XXXX.", "X.XX.", "X..XX"],
		"M" => ["XX.XX", "XXXXX", "X.X.X", "X...X", "X...X"],
		"N" => ["XX..X", "XXX.X", "X.XXX", "X..XX", "X...X"],
		"H" => ["X...X", "X...X", "XXXXX", "X...X", "X...X"],
		"A" => [".XXX.", "X...X", "XXXXX", "X...X", "X...X"],
		"D" => ["XXXX.", "X...X", "X...X", "X...X", "XXXX."],
	];

	/** Logóbetű: minden "pixel" egy apró, fazettás láda. */
	public static function logoLetter(letter:String, base:FlxColor):FlxGraphic
	{
		var key = "px_logo_" + letter + "_" + base.toHexString();
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var c = LOGO_CELL;
		var rows = LOGO_FONT.get(letter);
		function filled(gx:Int, gy:Int):Bool
			return gx >= 0 && gy >= 0 && gx < 5 && gy < 5 && rows[gy].charAt(gx) == "X";

		var hi = base.getLightened(0.45), sh = base.getDarkened(0.35), seam = base.getDarkened(0.18);
		var shadow = 2;
		var bmd = new BitmapData(5 * c + shadow, 5 * c + shadow, true, 0);

		// Vetett árnyék
		for (gy in 0...5)
			for (gx in 0...5)
				if (filled(gx, gy))
					bmd.fillRect(new openfl.geom.Rectangle(gx * c + shadow, gy * c + shadow, c, c), 0xff0d0e18);

		// Tömör betű: körvonal csak a forma szélén, a ládák között halvány varrat
		for (gy in 0...5)
			for (gx in 0...5)
			{
				if (!filled(gx, gy))
					continue;
				var l = filled(gx - 1, gy), r = filled(gx + 1, gy), u = filled(gx, gy - 1), d = filled(gx, gy + 1);
				for (y in 0...c)
					for (x in 0...c)
					{
						var col:Int = base;
						if ((x == 0 && !l) || (x == c - 1 && !r) || (y == 0 && !u) || (y == c - 1 && !d))
							col = OUTLINE;
						else if ((y == 1 && !u) || (x == 1 && !l))
							col = hi;
						else if ((y == c - 2 && !d) || (x == c - 2 && !r))
							col = sh;
						else if ((x == c - 1 && r) || (y == c - 1 && d))
							col = seam;
						else if (x == 2 && y == 2)
							col = hi; // csillanás minden ládán
						bmd.setPixel32(gx * c + x, gy * c + y, col);
					}
			}
		return store(key, bmd);
	}

	// --- Talaj ------------------------------------------------------------------

	/**
	 * Talajszakasz megrajzolása egy már létrehozott bitmapre. A mintázat a világkoordinátától függ,
	 * így az egymás melletti szakaszok folytonosnak látszanak.
	 */
	public static function paintGround(bmd:BitmapData, worldX:Int, worldY:Int, platform:Bool):Void
	{
		var th = Themes.current;
		var gTop = th.grass[0], gMid = th.grass[1], gDark = th.grass[2];
		var w = bmd.width, h = bmd.height;
		bmd.lock();
		for (x in 0...w)
		{
			var wx = worldX + x;
			// Fűréteg vastagsága oszloponként változik (csipkés átmenet)
			var grass = 3 + (hash(wx, 1) > 0.55 ? 1 : 0) + (hash(Math.floor(wx / 2), 7) > 0.7 ? 1 : 0);
			if (platform)
				grass = hash(wx, 3) > 0.5 ? 3 : 2;

			for (y in 0...h)
			{
				var c:Int;
				if (y == 0)
					c = hash(wx, 11) > 0.85 ? gMid : gTop;
				else if (y < grass - 1)
					c = (y == 1 && hash(wx, 13) > 0.6) ? gTop : gMid;
				else if (y == grass - 1)
					c = gDark;
				else if (platform)
					c = stoneBrick(wx, y, h);
				else
					c = dirt(wx, y - grass, worldY + y);

				// Lebegő platformnak mindkét oldala látszik, sötét kerettel
				if (platform && (x == 0 || x == w - 1))
					c = y < grass ? gDark : OUTLINE;
				bmd.setPixel32(x, y, c);
			}
		}
		bmd.unlock();
	}

	/**
	 * Talajszakasz bal vagy jobb peremének sötétítése a felső `rows` sorban
	 * (csak ahol a perem tényleg látszik: szakadék vagy szintkülönbség).
	 */
	public static function paintEdge(bmd:BitmapData, right:Bool, rows:Int):Void
	{
		var th = Themes.current;
		var x = right ? bmd.width - 1 : 0;
		for (y in 0...Std.int(Math.min(rows, bmd.height)))
		{
			bmd.setPixel32(x, y, y < 3 ? th.grass[2] : th.dirt[3]);
			// Belső, halványabb második oszlop a térhatásért
			if (y >= 3)
				bmd.setPixel32(right ? x - 1 : x + 1, y, th.dirt[2]);
		}
	}

	static function dirt(wx:Int, depth:Int, wy:Int):Int
	{
		// Mélységgel sötétedő sávok, ditherelt átmenettel
		var bands = Themes.current.dirt;
		var t = depth / 18;
		var i = Std.int(Math.min(t, bands.length - 1));
		var c = bands[i];
		if (i < bands.length - 1 && (t - i) > bayer(wx, depth))
			c = bands[i + 1];

		// Kavicsok: 8x7-es cellánként legfeljebb egy, 3x2 pixeles
		var cellX = Math.floor(wx / 8), cellY = Math.floor(wy / 7);
		if (hash(cellX, cellY) > 0.72)
		{
			var px = cellX * 8 + Std.int(hash(cellX, cellY + 50) * 5);
			var py = cellY * 7 + 1 + Std.int(hash(cellX + 50, cellY) * 4);
			var dx = wx - px, dy = wy - py;
			if (dx >= 0 && dx < 3 && dy >= 0 && dy < 2 && !(dy == 1 && dx == 0))
				return (dx == 0 || dy == 0) && !(dx == 2 && dy == 0) ? LIGHT_GRAY : GRAY;
		}
		// Apró világosabb szemcsék
		if (hash(wx, wy) > 0.96)
			return bands[0];
		return c;
	}

	static function stoneBrick(wx:Int, y:Int, h:Int):Int
	{
		if (y == h - 1)
			return OUTLINE;
		// Eltolt téglasorok: 8 széles, 3 magas téglák habarccsal
		var row = Std.int((y - 3) / 3);
		var offset = (row & 1) * 4;
		if ((y - 3) % 3 == 2 && y < h - 2)
			return DARK_GRAY;
		if (((wx + offset) & 7) == 0)
			return DARK_GRAY;
		if ((y - 3) % 3 == 0)
			return LIGHT_GRAY;
		return GRAY;
	}

	// --- Háttér --------------------------------------------------------------

	/** Éjszakai égbolt ditherelt színátmenettel, csillagokkal és holddal (képernyőhöz rögzített). */
	public static function sky(w:Int, h:Int):FlxGraphic
	{
		var th = Themes.current;
		var key = "px_sky_" + th.name;
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		// A téma színsávjai (alapból komor, lilás-vöröses éjszaka)
		var bands = th.sky;
		var starA = 1 - 0.0025 * th.stars, starB = 1 - 0.0007 * th.stars;
		var bmd = new BitmapData(w, h, true, 0);
		bmd.lock();
		for (y in 0...h)
		{
			var t = y / h * (bands.length - 1);
			var i = Std.int(t);
			for (x in 0...w)
			{
				var c = bands[i];
				if (i < bands.length - 1 && (t - i) > bayer(x, y))
					c = bands[i + 1];
				var s = hash(x, y);
				if (th.stars > 0 && y < h * 0.6 && s > starA)
					c = s > starB ? LIGHT_GRAY : GRAY;
				bmd.setPixel32(x, y, c);
			}
		}

		bmd.unlock();
		return store(key, bmd);
	}


	/**
	 * Hold `r` sugárral, a megadott fázissal (0..7: 0 újhold, 2 első negyed, 4 telihold, 6 utolsó negyed; 1, 3 növekvő, 5, 7 fogyó)
	 * és színváltozattal (0 = a téma színe, 1 = hidegebb, 2 = sötétebb). A nem megvilágított rész halvány "hamuszürke fény".
	 * Külön sprite, hogy képernyőnként máshová lehessen tenni.
	 */
	public static function moon(r:Int = 13, phase:Int = 4, tint:Int = 0):FlxGraphic
	{
		var th = Themes.current;
		var key = "px_moon_" + th.name + "_" + r + "_" + phase + "_" + tint;
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var cols:Array<Int> = [for (c in th.moon) tint == 1 ? (FlxColor.interpolate(c, 0xff8ab4ff, 0.35) : Int) : (tint == 2 ? (FlxColor.fromInt(c).getDarkened(0.25) : Int) : c)];
		var size = r * 2 + 1;
		var bmd = new BitmapData(size, size, true, 0);
		var p = phase / 8.0;
		var cosv = Math.cos(p * Math.PI * 2);
		var litAt = new Map<Int, Bool>();
		for (y in -r...r + 1)
			for (x in -r...r + 1)
			{
				var d = x * x + y * y;
				if (d > r * r)
					continue;
				// A terminátor: a lemez fele (ellipszis) – növekvő holdnál a jobb, fogyónál a bal oldal világos
				var chord = Math.sqrt(Math.max(0, r * r - y * y));
				var xt = cosv * chord;
				var lit = phase == 4 || (p <= 0.5 ? x >= xt : x <= -xt);
				if (phase == 0)
					lit = false;
				litAt.set((y + r) * size + (x + r), lit);
				if (lit)
				{
					var c = cols[0];
					var sx = x - r * 0.38, sy = y + r * 0.23; // árnyékoldal eltolt körrel (3D hatás)
					if (sx * sx + sy * sy > (r + 1) * (r + 1))
						c = cols[1];
					if (d > (r - 1) * (r - 1))
						c = cols[2];
					bmd.setPixel32(r + x, r + y, c);
				}
				else
					bmd.setPixel32(r + x, r + y, (0x55 << 24) | (cols[3] & 0xffffff));
			}
		// Kráterek (csak a megvilágított részen)
		for (cr in [[-4, -3, 2], [3, 4, 3], [-2, 6, 1], [5, -5, 1]])
		{
			var rad = Math.max(1, Math.round(cr[2] * r / 13));
			var cx = Math.round(cr[0] * r / 13), cy = Math.round(cr[1] * r / 13);
			for (y in -Std.int(rad)...Std.int(rad) + 1)
				for (x in -Std.int(rad)...Std.int(rad) + 1)
				{
					var px = cx + x, py = cy + y;
					if (x * x + y * y <= rad * rad && px * px + py * py < (r - 1) * (r - 1) && litAt.get((py + r) * size + (px + r)) == true)
						bmd.setPixel32(r + px, r + py, cols[1]);
				}
		}
		return store(key, bmd);
	}

	/** Kis űrhajó (10x5, jobbra néz): a hold körül köröz. */
	public static function tinyShip():FlxGraphic
	{
		return sheet("px_tinyship", [["..KKKK....", ".KWWWWKK..", "KWWCCWWWKK", ".KRKKKKK..", "..KK......"]], ["K" => OUTLINE, "W" => LIGHT_GRAY, "C" => CYAN, "R" => RED]);
	}

	/** Repülő csészealj (12x6), 2 képkocka: váltakozó fények. */
	public static function ufo():FlxGraphic
	{
		return sheet("px_ufo", [
			["....KKKK....", "..KKCCCCKK..", ".KWWWWWWWWK.", "KGGGGGGGGGGK", ".KKYKYKYKYK.", "..K.K..K.K.."],
			["....KKKK....", "..KKCCCCKK..", ".KWWWWWWWWK.", "KGGGGGGGGGGK", ".KKRKRKRKRK.", "..K.K..K.K.."],
		], ["K" => OUTLINE, "C" => CYAN, "W" => LIGHT_GRAY, "G" => GRAY, "Y" => YELLOW, "R" => RED]);
	}

	/** Csóvás fénycsík (hullócsillag, üstökös): a feje jobbra, a csóva balra halványul. */
	public static function streak(w:Int, h:Int, color:Int):FlxGraphic
	{
		var key = "px_streak_" + w + "_" + h + "_" + color;
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var bmd = new BitmapData(w, h, true, 0);
		for (x in 0...w)
		{
			var f = Math.pow(x / (w - 1), 1.7);
			for (y in 0...h)
			{
				var mid = (h - 1) / 2;
				var edge = 1 - Math.abs(y - mid) / (mid + 0.5) * 0.65;
				var a = Std.int(255 * f * edge);
				var c = x >= w - 2 ? WHITE : color;
				bmd.setPixel32(x, y, (a << 24) | (c & 0xffffff));
			}
		}
		return store(key, bmd);
	}
	/**
	 * Vízszintesen ismételhető hegy-/domb-sziluett. A profil csak egész periódusú szinuszokból áll,
	 * így a széle pontosan illeszkedik.
	 */
	public static function ridge(key:String, w:Int, h:Int, baseY:Float, amp:Float, seed:Int, fill:Int, edge:Int, trees:Bool, snow:Int = 0):FlxGraphic
	{
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var rnd = new FlxRandom(seed);
		var waves = [for (k in [1, 2, 3, 5, 8]) {k: k, a: rnd.float(0.4, 1) / Math.sqrt(k), p: rnd.float(0, Math.PI * 2)}];
		var total = 0.0;
		for (wv in waves)
			total += wv.a;

		function top(x:Int):Int
		{
			var v = 0.0;
			for (wv in waves)
			{
				// |sin| a hegyesebb csúcsokért
				var s = Math.sin(wv.k * Math.PI * 2 * x / w + wv.p);
				v += wv.a * (trees ? s : 1 - Math.abs(s) * 2);
			}
			return Std.int(baseY - v / total * amp);
		}

		var bmd = new BitmapData(w, h, true, 0);
		bmd.lock();
		var tops = [for (x in 0...w) top(x)];
		var minTop = h;
		for (t in tops)
			minTop = Std.int(Math.min(minTop, t));
		var snowLine = minTop + amp * 0.35;

		for (x in 0...w)
		{
			var prev = tops[(x - 1 + w) % w];
			for (y in tops[x]...h)
			{
				var c = fill;
				if (!trees && snow != 0 && tops[x] < snowLine)
				{
					// Hósapka a csúcsokon: vastagsága a csúcs magasságával nő, az alja ditherelt
					var depth = (snowLine - tops[x]) * 0.8;
					var d = (y - tops[x]) / depth;
					if (d < 1 && d < 1.6 - bayer(x, y))
						c = snow; // hósapka (a téma színe)
				}
				bmd.setPixel32(x, y, c);
			}
			// Összefüggő perem: a függőleges lépcsőket is kitöltjük
			if (!trees)
				for (y in Std.int(Math.min(prev, tops[x]))...tops[x] + 1)
					bmd.setPixel32(x, y, tops[x] < snowLine ? 0xff7d6e8c : edge);
		}

		// Fenyőfa-sziluettek a domb tetején (körbeérő koordinátákkal)
		if (trees)
		{
			var x = rnd.int(0, 20);
			while (x < w)
			{
				var th = rnd.int(7, 15);
				var base = tops[x] + 2;
				for (dy in 0...th)
				{
					var half = Std.int((dy + 1) / 2.2) + (dy % 3 == 0 ? 0 : 1);
					if (dy < 2)
						half = 0;
					for (dx in -half...half + 1)
						bmd.setPixel32((x + dx + w) % w, base - th + dy, edge);
				}
				bmd.setPixel32(x, base, edge);
				x += rnd.int(6, 26);
			}
		}
		bmd.unlock();
		return store(key, bmd);
	}
}
