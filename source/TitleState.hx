package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/** Nyitóképernyő: ládákból rakott logó, futó hős a görgő tájban, irányítás, csúcspontszám. */
class TitleState extends FlxState
{
	static inline var GROUND_Y:Int = 230;
	static inline var SCROLL_SPEED:Float = 45;
	static final LOGO_COLORS:Array<FlxColor> = [PixelArt.RED, PixelArt.ORANGE, PixelArt.YELLOW, PixelArt.LIME, PixelArt.CYAN, PixelArt.SKY];

	var letters:Array<FlxSprite> = [];
	var lettersLanded:Array<Bool> = [];
	var logoY:Float = 34;
	var grounds:Array<FlxSprite> = [];
	var menu:MenuList;
	var hiText:FlxText;
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
		FlxG.fixedTimestep = false; // valós idő szerinti léptetés (lásd PlayState)
		FlxG.maxElapsed = 0.05;
		FlxG.scaleMode = new RatioScaleMode();
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		// Hangok és zene legenerálása (egyszer); megszólalni csak az első gombnyomás után tudnak
		Audio.init();
		Audio.stopMusic();

		add(new Backdrop(432, 112));

		// Két talajcsík egymás után; ami kigördül balra, az előre ugrik és újrarajzolódik
		for (i in 0...2)
		{
			var g = new FlxSprite(i * FlxG.width, GROUND_Y);
			g.makeGraphic(FlxG.width, FlxG.height - GROUND_Y, FlxColor.TRANSPARENT, true);
			PixelArt.paintGround(g.pixels, Std.int(g.x), GROUND_Y, false);
			g.dirty = true;
			add(g);
			grounds.push(g);
		}

		// Futó hős a képernyő bal oldalán
		var hero = new FlxSprite(70, GROUND_Y - PixelArt.PLAYER_H);
		hero.loadGraphic(PixelArt.player(Characters.current().skin), true, PixelArt.PLAYER_W, PixelArt.PLAYER_H);
		hero.animation.add("run", [1, 2, 3, 4], 12);
		hero.animation.play("run");
		hero.scrollFactor.set(0, 0);
		add(hero);

		var vignette = new FlxSprite(0, 0, PixelArt.vignette(FlxG.width, FlxG.height));
		vignette.scrollFactor.set(0, 0);
		add(vignette);

		createLogo();

		var tagline = new FlxText(0, logoY + 38, FlxG.width, "DODGE  -  BLAST  -  SURVIVE", 8);
		styleText(tagline, PixelArt.CYAN);
		add(tagline);

		menu = new MenuList(86, [() -> "START GAME", () -> "QUESTS", () -> 'SHOP   ${Settings.coins} COINS', () -> "HELP"].concat(Leaderboard.configured() ? [() -> "LEADERBOARD"] : []).concat([() -> "SETTINGS"]), Leaderboard.configured() ? 14 : 16, Leaderboard.configured() ? 15 : 17);
		menu.onSelect = i -> switch (i)
		{
			case 0: startGame();
			case 1: Audio.play("blip"); openSubState(new QuestsSubState());
			case 2: Audio.play("blip"); openSubState(new ShopSubState(false));
			case 3: Audio.play("blip"); openSubState(new HelpSubState());
			case 4 if (Leaderboard.configured()): Audio.play("blip"); openSubState(new LeaderboardSubState());
			default: openSettings();
		};
		add(menu);


		hiText = new FlxText(0, 6, FlxG.width, "", 8);
		styleText(hiText, PixelArt.WHITE);
		add(hiText);
		refreshHiScore();

		FlxG.camera.fade(PixelArt.OUTLINE, 0.4, true);
	}

	/** Csúcspontszám a kiválasztott nehézséghez. */
	function refreshHiScore():Void
	{
		var hi = HiScore.get();
		hiText.text = 'HI-SCORE (${Settings.difficultyName()})  $hi';
	}

	function openSettings():Void
	{
		Audio.play("blip");
		var s = new SettingsSubState(false);
		s.closeCallback = refreshHiScore;
		openSubState(s);
	}

	function startGame():Void
	{
		starting = true;
		Leaderboard.cheated = false; // új futás: a cheat-jelölés törlődik
		Settings.resetRun(); // minden új futás tiszta lappal indul (akkor is, ha az előző a böngésző bezárásával ért véget)
		Audio.play("start");
		FlxG.camera.flash(0x60ffffff, 0.2);
		FlxG.camera.fade(PixelArt.OUTLINE, 0.6, false, () -> FlxG.switchState(IntroState.new), true); // force: a nyitó fade-in közben is lefusson
	}

	function styleText(t:FlxText, color:FlxColor):Void
	{
		t.alignment = CENTER;
		t.color = color;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
	}

	/** A logó betűi egymás után beesnek és lepattannak. */
	function createLogo():Void
	{
		var word = "MOONSHARD";
		var letterW = 5 * PixelArt.LOGO_CELL;
		var gap = 3;
		var totalW = word.length * letterW + (word.length - 1) * gap;
		var x0 = Std.int((FlxG.width - totalW) / 2);
		for (i in 0...word.length)
		{
			var s = new FlxSprite(x0 + i * (letterW + gap), -40, PixelArt.logoLetter(word.charAt(i), LOGO_COLORS[i % LOGO_COLORS.length]));
			s.scrollFactor.set(0, 0);
			add(s);
			letters.push(s);
			lettersLanded.push(false);
			var idx = i;
			FlxTween.tween(s, {y: logoY}, 0.7, {
				startDelay: 0.25 + i * 0.07,
				ease: FlxEase.bounceOut,
				onComplete: _ -> lettersLanded[idx] = true
			});
		}
	}

	override public function update(elapsed:Float):Void
	{
		time += elapsed;
		FlxG.camera.scroll.x += SCROLL_SPEED * elapsed;

		// Talajcsíkok léptetése
		for (g in grounds)
			if (g.x + g.width < FlxG.camera.scroll.x)
			{
				g.x += g.width * grounds.length;
				PixelArt.paintGround(g.pixels, Std.int(g.x), GROUND_Y, false);
				g.dirty = true;
			}

		// A leérkezett betűk finoman hullámoznak
		for (i in 0...letters.length)
			if (lettersLanded[i])
				letters[i].y = logoY + Math.round(Math.sin(time * 3 + i * 0.55) * 2);

		// Indításkor a menü villog és nem fogad több bemenetet
		menu.active = !starting;
		if (starting)
			menu.visible = Std.int(time * 16) % 2 == 0;

		#if !js
		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;
		#end
		if (Controls.just(MUTE))
			Settings.toggleMute();

		super.update(elapsed);
	}
}
