package;

import Controls.Action;
import PowerUp.PowerKind;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** Súgó: 3 oldal (irányítás és cél, fegyverek és bónuszok, veszélyek és hatások). Balra / jobbra lapoz, Esc bezár. A billentyűk a mostani kiosztást mutatják. */
class HelpSubState extends FlxSubState
{
	static inline var FULL_PAGES:Int = 3;

	/** Játék előtti irányítás-képernyő: csak az 1. oldal, Enterrel megy tovább. */
	var single:Bool;
	var pages(get, never):Int;

	function get_pages():Int
		return single ? 1 : FULL_PAGES;

	var page:Int = 0;
	var body:Array<FlxSprite> = [];
	var pageText:FlxText;
	var title:FlxText;
	var ready:Bool = false;

	public function new(single:Bool = false)
	{
		super(single ? 0xff101020 : 0xf0101020); // a játék előtti képernyő alatt ne látszódjon át a történet
		this.single = single;
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this);
		FlxG.mouse.useSystemCursor = false;
		FlxG.mouse.visible = true;

		title = text(0, 8, FlxG.width, "", 16, PixelArt.YELLOW, CENTER);
		pageText = text(0, 246, FlxG.width, "", 8, PixelArt.GRAY, CENTER);
		build();
	}

	function text(x:Float, y:Float, w:Float, s:String, size:Int, color:Int, align:flixel.text.FlxText.FlxTextAlign = LEFT):FlxText
	{
		var t = new FlxText(x, y, w, s, size);
		t.alignment = align;
		t.color = color;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		return t;
	}

	function clearBody():Void
	{
		for (s in body)
		{
			remove(s, true);
			s.destroy();
		}
		body = [];
	}

	function line(x:Float, y:Float, s:String, color:Int = PixelArt.WHITE):Void
	{
		body.push(text(x, y, FlxG.width - x - 8, s, 8, color));
	}

	function build():Void
	{
		clearBody();
		pageText.text = single ? "PRESS  ENTER  TO CONTINUE" : 'PAGE ${page + 1} / $pages    LEFT / RIGHT  turn page    ESC  close';
		switch (page)
		{
			case 0: pageControls();
			case 1: pageWeapons();
			default: pageHazards();
		}
	}

	/** 1. oldal: cél és irányítás (a mostani kiosztással). */
	function pageControls():Void
	{
		title.text = single ? "CONTROLS" : "HOW TO PLAY";
		line(14, 30, "Dodge the falling meteors, shoot them for points and coins.", PixelArt.LIGHT_GRAY);
		line(14, 41, "Finish the 3 quests of a level to call its boss. Beat the boss to clear the level.", PixelArt.LIGHT_GRAY);
		var y = 60;
		var rows:Array<Action> = [LEFT, RIGHT, UP, DOWN, JUMP, SHOOT, CHARGE, PAUSE, MUTE];
		var descr = [
			"run left", "run right", "aim up (+ LEFT / RIGHT: diagonal)", "crouch / aim down in the air", "hold for a higher jump", "hold: rapid fire",
			"hold, then release: big shot", "pause menu", "sound on / off"
		];
		for (i in 0...rows.length)
		{
			line(14, y + i * 13, Controls.NAMES[i], PixelArt.CYAN);
			line(150, y + i * 13, Controls.label(rows[i]), PixelArt.YELLOW);
			line(236, y + i * 13, descr[i], PixelArt.LIGHT_GRAY);
		}
		line(14, 182, "Change keys in SETTINGS > CONTROLS.   F  fullscreen.", PixelArt.GRAY);
		line(14, 196, "GAMEPAD   stick: move   X: jump   SQUARE: shoot   CIRCLE: charge   OPTIONS: pause", PixelArt.GRAY);
		line(14, 214, "TIPS   Jump up through floating platforms from below. Crouch to hit low targets.", PixelArt.LIGHT_GRAY);
		line(14, 225, "Use the arena platforms to jump over a boss. Power-ups run out: watch the timers.", PixelArt.LIGHT_GRAY);
	}

	/** 2. oldal: fegyverek és bónuszok ikonnal. */
	function pageWeapons():Void
	{
		title.text = "WEAPONS & POWER-UPS";
		var items:Array<{k:PowerKind, d:String}> = [
			{k: SPREAD, d: "three-way spread shot (stacks with the others)"},
			{k: RAPID, d: "faster firing and faster charging"},
			{k: HOMING, d: "shots curve toward the nearest enemy (every weapon)"},
			{k: ROCKET, d: "explodes on impact; the charged shot is bigger"},
			{k: LASER, d: "fast beam that passes through everything"},
			{k: GRENADE, d: "arcing grenade with a big blast radius"},
			{k: ENERGY, d: "refills some energy"},
			{k: BONUS, d: "extra points"},
		];
		var y = 32;
		for (it in items)
		{
			var icon = new FlxSprite(14, y - 1);
			icon.loadGraphic(PixelArt.powerUp(it.k), true, PixelArt.POWER_SIZE, PixelArt.POWER_SIZE);
			icon.scrollFactor.set(0, 0);
			add(icon);
			body.push(icon);
			line(32, y, PowerUp.shortName(it.k), PixelArt.powerColor(it.k));
			line(112, y, it.d, PixelArt.LIGHT_GRAY);
			y += 19;
		}
		line(14, 190, "Gold meteors drop a power-up. Weapons you pick up are lost at the end of a level;", PixelArt.GRAY);
		line(14, 201, "the weapon bought in the SHOP is your starting weapon. Coins buy upgrades.", PixelArt.GRAY);
		line(14, 215, "If you lose all continues the run ends: coins and shop weapons are reset.", PixelArt.GRAY);
	}

	/** 3. oldal: veszélyek és a hőst érő hatások. */
	function pageHazards():Void
	{
		title.text = "HAZARDS & EFFECTS";
		var rows:Array<Array<String>> = [
			["METEORS", "falling ones hurt (bigger = more); landed ones are obstacles that roll"],
			["GLOWING", "a glowing meteor stays hot after landing: touching it burns"],
			["SLIME", "does no damage, but sticks to your legs and slows you down"],
			["SPIDERLING", "its bite makes you tipsy: more bites = stronger (timed)"],
			["BOSSES", "each boss has its own attacks; the final boss changes shape"],
			["SHROOM", "trippy screen            PIXELATED   big pixels"],
			["FLASHLIGHT", "only the area around you is lit      TUNNEL   narrow view"],
			["INVISIBLE", "you cannot see your hero      TINY HERO   you shrink"],
			["MAGNETIC", "meteors slide toward you      ASCII   the world turns into letters"],
		];
		var y = 32;
		for (r in rows)
		{
			line(14, y, r[0], PixelArt.CYAN);
			line(100, y, r[1], PixelArt.LIGHT_GRAY);
			y += 15;
		}
		line(14, 176, "Timed effects (right side of the screen) wear off by themselves.", PixelArt.GRAY);
		line(14, 190, "Energy refills a little at the start of every level.", PixelArt.GRAY);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!ready)
		{
			ready = true;
			return;
		}
		var move = 0;
		if (single)
		{
			if (FlxG.keys.anyJustPressed([ENTER, SPACE, ESCAPE]) || Pad.just(CONFIRM) || Pad.just(START) || FlxG.mouse.justPressed)
			{
				Audio.play("start");
				close();
			}
			return;
		}
		if (FlxG.keys.anyJustPressed([RIGHT, D]) || Pad.just(RIGHT) || FlxG.mouse.wheel < 0 || FlxG.mouse.justPressed)
			move = 1;
		else if (FlxG.keys.anyJustPressed([LEFT, A]) || Pad.just(LEFT) || FlxG.mouse.wheel > 0 || FlxG.mouse.justPressedRight)
			move = -1;
		if (move != 0)
		{
			page = (page + move + pages) % pages;
			Audio.play("blip");
			build();
		}
		if (FlxG.keys.anyJustPressed([ESCAPE, ENTER]) || Pad.just(BACK) || Pad.just(CONFIRM))
		{
			Audio.play("blip");
			close();
		}
	}
}
