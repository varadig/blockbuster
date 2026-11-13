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
	public static function player():FlxGraphic
	{
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

		return sheet("px_player", [
			frame(legsIdle, false),
			frame(legsRun1, false),
			frame(legsRun2, true),
			frame(legsRun3, false),
			frame(legsRun4, true),
			frame(legsJump, false),
			fallFrame,
		], [
			"K" => OUTLINE,
			"B" => BLUE,
			"b" => SKY,
			"C" => CYAN,
			"W" => WHITE,
			"R" => RED,
			"r" => ORANGE,
			"G" => YELLOW,
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

	public static inline var FLAME_SIZE:Int = 7;

	/** Lángrészecske 4 képkockája: fehéren izzó mag -> sárga -> narancs -> vörös füst. */
	public static function flame():FlxGraphic
	{
		return sheet("px_flame", [
			["..yy...", ".yWWy..", "yWWWWy.", "yWWWWy.", ".yWWy..", "..yy...", "......."],
			["..oo...", ".oyyo..", "oyWyyo.", "oyyyyo.", ".oyyo..", "..oo...", "......."],
			[".......", "..rr...", ".roor..", ".roYor.", "..ror..", "...r...", "......."],
			[".......", ".......", "..pp...", ".prrp..", "..pp...", ".......", "......."],
		], ["W" => WHITE, "y" => YELLOW, "Y" => YELLOW, "o" => ORANGE, "r" => RED, "p" => PLUM]);
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

	public static inline var DEATHRAY_COLOR:Int = 0xffd04cff;

	/**
	 * Halálsugár egy 1 pixel széles keresztmetszete (halvány lila szél, lila, fehér mag);
	 * a PlayState a sugár hosszára nyújtja és az irányába forgatja.
	 */
	public static function deathRayBeam():FlxGraphic
	{
		return sheet("px_deathray_beam", [["g", "p", "W", "W", "W", "p", "g"]], ["g" => 0x80d04cff, "p" => DEATHRAY_COLOR, "W" => WHITE]);
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
		"HEAVY" => [
			"........",
			".XXXX...",
			"XXXXXXX.",
			"XXXXXXXX",
			"XXXXXXXX",
			"XXXXXXX.",
			".XXXX...",
			"........",
		],
		"SHIELD" => [
			"...XX...",
			"...XX...",
			"XXXXXXXX",
			".XXXXXX.",
			"..XXXX..",
			".XXXXXX.",
			".XX..XX.",
			"X......X",
		],
		"SLOWMO" => [
			"XXXXXXXX",
			".X....X.",
			"..XXXX..",
			"...XX...",
			"...XX...",
			"..X..X..",
			".XXXXXX.",
			"XXXXXXXX",
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
		"FLAME" => [
			"...X....",
			"..XX....",
			"..XXX.X.",
			".XXXXXX.",
			".XXX.XX.",
			"XXX..XXX",
			"XX....XX",
			".XXXXXX.",
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
		"NUKE" => [
			"X..XX..X",
			".X.XX.X.",
			"..XXXX..",
			"XXX..XXX",
			"XXX..XXX",
			"..XXXX..",
			".X.XX.X.",
			"X..XX..X",
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
		"DEATHRAY" => [
			".XXXXXX.",
			"XXXXXXXX",
			"X..XX..X",
			"X..XX..X",
			"XXXXXXXX",
			".XXX.XX.",
			".X.XX.X.",
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
	];

	public static function powerColor(kind:PowerUp.PowerKind):FlxColor
	{
		return switch (kind)
		{
			case SPREAD: 0xffc8a0ff;
			case RAPID: YELLOW;
			case HEAVY: 0xfff277a8;
			case FLAME: ORANGE;
			case LASER: 0xffff5a5a;
			case DEATHRAY: DEATHRAY_COLOR;
			case NUKE: 0xffb6ff3c;
			case SHROOM: 0xffff5ac8;
			case SHIELD: CYAN;
			case SLOWMO: SKY;
			case BONUS: LIME;
			case ENERGY: GREEN;
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

	// --- Logó ---------------------------------------------------------------------

	public static inline var LOGO_CELL:Int = 7;

	/** 5x5-ös betűk a "BLOCKBUSTER" logóhoz; a cellák mindig oldalukkal kapcsolódnak (átlós érintkezés szétesőnek látszik). */
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
					c = hash(wx, 11) > 0.85 ? GRASS : GRASS_TOP;
				else if (y < grass - 1)
					c = (y == 1 && hash(wx, 13) > 0.6) ? GRASS_TOP : GRASS;
				else if (y == grass - 1)
					c = GRASS_DARK;
				else if (platform)
					c = stoneBrick(wx, y, h);
				else
					c = dirt(wx, y - grass, worldY + y);

				// Lebegő platformnak mindkét oldala látszik, sötét kerettel
				if (platform && (x == 0 || x == w - 1))
					c = y < grass ? GRASS_DARK : OUTLINE;
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
		var x = right ? bmd.width - 1 : 0;
		for (y in 0...Std.int(Math.min(rows, bmd.height)))
		{
			bmd.setPixel32(x, y, y < 3 ? GRASS_DARK : DIRT_DEEPEST);
			// Belső, halványabb második oszlop a térhatásért
			if (y >= 3)
				bmd.setPixel32(right ? x - 1 : x + 1, y, DIRT_DEEP);
		}
	}

	static function dirt(wx:Int, depth:Int, wy:Int):Int
	{
		// Mélységgel sötétedő sávok, ditherelt átmenettel
		var bands = [DIRT_TOP, DIRT_MID, DIRT_DEEP, DIRT_DEEPEST];
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
			return DIRT_TOP;
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
		var key = "px_sky";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		// Komor, lilás-vöröses éjszaka
		var bands = [0xff07060d, 0xff110c1c, 0xff1f1328, NIGHT_HORIZON];
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
				if (y < h * 0.6 && s > 0.9975)
					c = s > 0.9993 ? LIGHT_GRAY : GRAY;
				bmd.setPixel32(x, y, c);
			}
		}

		bmd.unlock();
		return store(key, bmd);
	}

	static inline var MOON_LIT:Int = 0xffe0896e;
	static inline var MOON_SHADE:Int = 0xffa8483e;
	static inline var MOON_RIM:Int = 0xffc96a55;

	/** Hold sarlóval és kráterekkel (külön sprite, hogy képernyőnként máshová lehessen tenni). */
	public static function moon():FlxGraphic
	{
		var key = "px_moon";
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var r = 13, mx = 13, my = 13;
		var bmd = new BitmapData(27, 27, true, 0);
		for (y in -r...r + 1)
			for (x in -r...r + 1)
			{
				var d = x * x + y * y;
				if (d > r * r)
					continue;
				// Vérvörös hold: világos oldal, árnyékoldal, sötétebb perem
				var lit = true;
				var c = MOON_LIT;
				var sx = x - 5, sy = y + 3; // árnyékoldal eltolt körrel
				if (sx * sx + sy * sy > (r + 1) * (r + 1))
				{
					c = MOON_SHADE;
					lit = false;
				}
				if (d > (r - 1) * (r - 1))
					c = lit ? MOON_RIM : 0xff5a1f24;
				bmd.setPixel32(mx + x, my + y, c);
			}
		for (cr in [[-4, -3, 2], [3, 4, 3], [-2, 6, 1], [5, -5, 1]])
			for (y in -cr[2]...cr[2] + 1)
				for (x in -cr[2]...cr[2] + 1)
					if (x * x + y * y <= cr[2] * cr[2])
						bmd.setPixel32(mx + cr[0] + x, my + cr[1] + y, MOON_SHADE);
		return store(key, bmd);
	}

	/**
	 * Vízszintesen ismételhető hegy-/domb-sziluett. A profil csak egész periódusú szinuszokból áll,
	 * így a széle pontosan illeszkedik.
	 */
	public static function ridge(key:String, w:Int, h:Int, baseY:Float, amp:Float, seed:Int, fill:Int, edge:Int, trees:Bool):FlxGraphic
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
				if (!trees && tops[x] < snowLine)
				{
					// Hósapka a csúcsokon: vastagsága a csúcs magasságával nő, az alja ditherelt
					var depth = (snowLine - tops[x]) * 0.8;
					var d = (y - tops[x]) / depth;
					if (d < 1 && d < 1.6 - bayer(x, y))
						c = 0xff4e4460; // fakó, holdfényes hó
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
