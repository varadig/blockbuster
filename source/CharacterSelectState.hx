package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Karakterválasztó a játék előtt: balra/jobbra választ, Space/Enter indít, ESC vissza a címképernyőre. */
class CharacterSelectState extends FlxState
{
	static inline var GROUND_Y:Int = 150;
	static inline var HERO_SCALE:Int = 3;
	static final STAT_NAMES:Array<String> = ["JUMP", "SPEED", "GRIP"];
	static inline var STAR_COUNT:Int = 5;

	var sel:Int = 0;
	var heroes:Array<FlxSprite> = [];
	var names:Array<FlxText> = [];
	var panel:FlxSprite;
	var tagline:FlxText;
	var statBars:Array<Array<FlxSprite>> = [];
	var arrowL:FlxText;
	var arrowR:FlxText;
	var time:Float = 0;
	var starting:Bool = false;

	override public function create():Void
	{
		super.create();
		Config.load();
		Settings.load();
		bgColor = PixelArt.OUTLINE;
		Themes.current = Themes.NIGHT; // a címképernyő és a karakterválasztó az alap éjszakai témát használja
		FlxG.timeScale = 1;
		FlxG.scaleMode = new RatioScaleMode();
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		Audio.init();

		add(new Backdrop(432, 112));

		var ground = new FlxSprite(0, GROUND_Y);
		ground.makeGraphic(FlxG.width, FlxG.height - GROUND_Y, FlxColor.TRANSPARENT, true);
		PixelArt.paintGround(ground.pixels, 0, GROUND_Y, false);
		ground.dirty = true;
		add(ground);

		var vignette = new FlxSprite(0, 0, PixelArt.vignette(FlxG.width, FlxG.height));
		add(vignette);

		add(label(0, 14, FlxG.width, "CHOOSE YOUR HERO", 16, PixelArt.YELLOW));

		sel = Std.int(Math.max(0, Math.min(Characters.LIST.length - 1, Settings.character)));

		panel = new FlxSprite().makeGraphic(120, 92, 0x66000000);
		add(panel);

		var n = Characters.LIST.length;
		for (i in 0...n)
		{
			var def = Characters.LIST[i];
			var cx = columnX(i);
			var hero = new FlxSprite();
			hero.loadGraphic(PixelArt.player(def.skin), true, PixelArt.PLAYER_W, PixelArt.PLAYER_H);
			hero.animation.add("idle", [0], 1);
			hero.animation.add("run", [1, 2, 3, 4], 10);
			hero.scale.set(HERO_SCALE, HERO_SCALE);
			hero.updateHitbox();
			hero.setPosition(cx - hero.width / 2, GROUND_Y - hero.height + 1);
			add(hero);
			heroes.push(hero);

			var name = label(cx - 60, 76, 120, def.name, 16, PixelArt.WHITE);
			add(name);
			names.push(name);
		}

		tagline = label(0, 160, FlxG.width, "", 8, PixelArt.CYAN);
		add(tagline);

		// Értékek: négy sor, soronként 5 csík
		for (r in 0...STAT_NAMES.length)
		{
			var y = 174 + r * 12;
			var l = label(150, y - 1, 80, STAT_NAMES[r], 8, PixelArt.LIGHT_GRAY);
			l.alignment = LEFT;
			add(l);
			var row:Array<FlxSprite> = [];
			for (k in 0...STAR_COUNT)
			{
				var s = new FlxSprite(236 + k * 14, y).makeGraphic(12, 6, FlxColor.WHITE);
				add(s);
				row.push(s);
			}
			statBars.push(row);
		}

		arrowL = label(0, 100, 20, "<", 16, PixelArt.YELLOW);
		arrowR = label(0, 100, 20, ">", 16, PixelArt.YELLOW);
		add(arrowL);
		add(arrowR);

		add(label(0, 232, FlxG.width, "LEFT / RIGHT  choose     SPACE / CLICK  start     ESC  back", 8, PixelArt.GRAY));

		refresh();
		FlxG.camera.fade(PixelArt.OUTLINE, 0.3, true);
	}

	function columnX(i:Int):Float
	{
		return FlxG.width / 2 + (i - (Characters.LIST.length - 1) / 2) * 150;
	}

	function label(x:Float, y:Float, w:Float, text:String, size:Int, color:FlxColor):FlxText
	{
		var t = new FlxText(x, y, w, text, size);
		t.alignment = CENTER;
		t.color = color;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		return t;
	}

	/** A kijelölés szerinti megjelenés: a választott hős fut és világít, a többi áll és sötétebb. */
	function refresh():Void
	{
		var def = Characters.LIST[sel];
		for (i in 0...heroes.length)
		{
			var on = i == sel;
			heroes[i].animation.play(on ? "run" : "idle");
			heroes[i].color = on ? FlxColor.WHITE : 0xff6a7490;
			names[i].color = on ? PixelArt.WHITE : PixelArt.GRAY;
		}
		var cx = columnX(sel);
		panel.setPosition(cx - 60, 72);
		arrowL.x = cx - 74;
		arrowR.x = cx + 54;
		tagline.text = def.tagline;
		for (r in 0...STAT_NAMES.length)
			for (k in 0...STAR_COUNT)
				statBars[r][k].color = k < def.stars[r] ? PixelArt.LIME : PixelArt.DARK_GRAY;
	}

	function choose(dir:Int):Void
	{
		var n = Characters.LIST.length;
		sel = (sel + dir + n) % n;
		Audio.play("blip");
		refresh();
	}

	var startTimer:Float = 0;
	var switched:Bool = false;

	function start():Void
	{
		starting = true;
		Settings.character = sel;
		Settings.store();
		Audio.play("start");
		FlxG.camera.flash(0x60ffffff, 0.2);
		// force = true: a megnyitáskor induló fade-in (0,3 mp) még futhat; a Flixel a nem erőltetett fade-et eldobja, a callback pedig sosem hívódna meg
		FlxG.camera.fade(PixelArt.OUTLINE, 0.5, false, () -> FlxG.switchState(PlayState.new), true);
		startTimer = 0;
	}

	override public function update(elapsed:Float):Void
	{
		time += elapsed;
		super.update(elapsed);

		// A nyilak finoman ide-oda mozognak
		var wob = Math.round(Math.sin(time * 8) * 2);
		arrowL.x = columnX(sel) - 74 - wob;
		arrowR.x = columnX(sel) + 54 + wob;

		if (starting)
		{
			// Biztosíték: ha a fade-callback valamiért nem futna le, a játék akkor is elindul
			startTimer += elapsed;
			if (startTimer > 1.2 && !switched)
			{
				switched = true;
				FlxG.switchState(PlayState.new);
			}
			return;
		}
		// Egér: a hős fölé húzva kijelölődik, egy kattintás kiválasztja és indítja a játékot
		FlxG.mouse.useSystemCursor = false; // a Flixel saját kurzora
		FlxG.mouse.visible = true;
		for (i in 0...Characters.LIST.length)
			if (Math.abs(FlxG.mouse.viewX - columnX(i)) < 70)
			{
				if (FlxG.mouse.justMoved && i != sel)
					while (sel != i)
						choose(i > sel ? 1 : -1);
				if (FlxG.mouse.justPressed)
				{
					while (sel != i)
						choose(i > sel ? 1 : -1);
					start();
					return;
				}
				break;
			}		if (FlxG.keys.anyJustPressed([LEFT, A]) || Pad.just(LEFT))
			choose(-1);
		else if (FlxG.keys.anyJustPressed([RIGHT, D]) || Pad.just(RIGHT))
			choose(1);
		else if (FlxG.keys.anyJustPressed([SPACE, ENTER, X, J]) || Pad.just(CONFIRM) || Pad.just(START))
			start();
		else if (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK))
			FlxG.switchState(TitleState.new);
	}
}
