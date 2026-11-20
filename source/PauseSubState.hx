package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** Szünetmenü (P vagy ESC): folytatás, beállítások, kilépés a címképernyőre. */
class PauseSubState extends FlxSubState
{
	var menu:MenuList;
	var savedTimeScale:Float = 1;

	public function new()
	{
		super(0xa0101020);
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this); // a játék kameraeffektjei (shaderek) a menüt nem érintik

		// A lassítás ne lassítsa a menüt; folytatáskor visszaállítjuk
		savedTimeScale = FlxG.timeScale;
		FlxG.timeScale = 1;
		Audio.pauseMusic();
		Audio.play("blip");

		var title = new FlxText(0, 22, FlxG.width, "PAUSED", 16);
		title.alignment = CENTER;
		title.color = PixelArt.YELLOW;
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		menu = new MenuList(54, [() -> "RESUME", () -> "HELP", () -> "SETTINGS", () -> "QUIT TO TITLE"], 8, 15);
		menu.onSelect = i -> switch (i)
		{
			case 0: resume();
			case 1: openSubState(new HelpSubState());
			case 2: openSubState(new SettingsSubState(true));
			default: quit();
		};
		add(menu);

		// Az aktív küldetések haladása az aktuális futásban
		add(new QuestPanel(128));

		// Ami a HUD-ról lekerült: a hátralévő continue-ok és az érmék
		var stat = new FlxText(0, 206, FlxG.width, 'CONTINUES ${PlayState.menuContinues}     COINS ${Settings.coins}', 8);
		stat.alignment = CENTER;
		stat.color = PixelArt.LIGHT_GRAY;
		stat.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		stat.scrollFactor.set(0, 0);
		add(stat);

		var hint = new FlxText(0, 224, FlxG.width, "P / ESC  resume", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);
	}

	/** A megnyitás utáni első képkockák: a megnyitó gombnyomás még "friss", ezért nem zárhat be rögtön. */
	var age:Int = 0;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		age++;
		if (age > 3 && menu.isReady() && subState == null && ((Controls.just(PAUSE) || FlxG.keys.justPressed.ESCAPE) || Pad.just(START) || Pad.just(BACK)))
			resume();
	}

	function resume():Void
	{
		FlxG.timeScale = savedTimeScale;
		Audio.resumeMusic();
		Audio.play("blip");
		close();
	}

	function quit():Void
	{
		FlxG.timeScale = 1;
		Audio.stopMusic();
		Settings.resetRun(); // a futás feladása: az érmék és a bolti fegyverek elvesznek
		FlxG.switchState(TitleState.new);
	}
}
