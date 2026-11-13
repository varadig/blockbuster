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

		// A lassítás ne lassítsa a menüt; folytatáskor visszaállítjuk
		savedTimeScale = FlxG.timeScale;
		FlxG.timeScale = 1;
		Audio.pauseMusic();
		Audio.play("blip");

		var title = new FlxText(0, 70, FlxG.width, "PAUSED", 16);
		title.alignment = CENTER;
		title.color = PixelArt.YELLOW;
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		menu = new MenuList(112, [() -> "RESUME", () -> "SETTINGS", () -> "QUIT TO TITLE"], 8, 16);
		menu.onSelect = i -> switch (i)
		{
			case 0: resume();
			case 1: openSubState(new SettingsSubState(true));
			default: quit();
		};
		add(menu);

		// Az aktív küldetések haladása az aktuális futásban
		add(new QuestPanel(166));

		var hint = new FlxText(0, 228, FlxG.width, "P / ESC  resume", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (menu.isReady() && subState == null && FlxG.keys.anyJustPressed([P, ESCAPE]))
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
		FlxG.switchState(TitleState.new);
	}
}
