package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** Beállítások: zene- és effekthangerő, hang be/ki, nehézség. A nyitóképernyőről és a szünetmenüből is nyílik. */
class SettingsSubState extends FlxSubState
{
	/** Játék közben a nehézség nem állítható (a rekordok nehézségenként külön számítanak). */
	var inGame:Bool;
	var menu:MenuList;
	var info:FlxText;

	public function new(inGame:Bool)
	{
		super(0xf0101020);
		this.inGame = inGame;
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this); // a játék kameraeffektjei (shaderek) a menüt nem érintik
		Settings.load();

		var title = new FlxText(0, 46, FlxG.width, "SETTINGS", 16);
		title.alignment = CENTER;
		title.color = PixelArt.YELLOW;
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		menu = new MenuList(86, [
			() -> 'MUSIC VOLUME   < ${pct(Settings.musicVolume)} >',
			() -> 'EFFECTS VOLUME   < ${pct(Settings.sfxVolume)} >',
			() -> 'SOUND   < ${Settings.muted ? "OFF" : "ON"} >',
			() -> 'DIFFICULTY   < ${Settings.difficultyName()} >',
			() -> "CONTROLS",
			() -> "BACK",
		], 8, 16);
		menu.isDisabled = i -> i == 3 && inGame;
		menu.onAdjust = adjust;
		menu.onSelect = i -> switch (i)
		{
			case 2 | 3: adjust(i, 1);
			case 4: Audio.play("blip"); openSubState(new ControlsSubState());
			case 5: back();
			default:
		};
		add(menu);

		info = new FlxText(0, 188, FlxG.width, "", 8);
		info.alignment = CENTER;
		info.color = PixelArt.LIGHT_GRAY;
		info.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		info.scrollFactor.set(0, 0);
		add(info);

		var hint = new FlxText(0, 222, FlxG.width, "UP / DOWN  select     LEFT / RIGHT  change     ESC  back", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);
	}

	static function pct(v:Float):String
	{
		return Std.string(Math.round(v * 100)) + "%";
	}

	function adjust(i:Int, dir:Int):Void
	{
		switch (i)
		{
			case 0:
				Settings.musicVolume = clamp01(Settings.musicVolume + dir * 0.1);
				Audio.updateMusicVolume();
				Audio.play("blip");
			case 1:
				Settings.sfxVolume = clamp01(Settings.sfxVolume + dir * 0.1);
				Audio.play("coin"); // azonnal hallani, milyen hangos
			case 2:
				Settings.toggleMute();
				Audio.play("blip");
			case 3:
				var d:Int = Settings.difficulty;
				Settings.difficulty = (d + dir + 3) % 3;
				Audio.play("blip");
			default:
		}
		Settings.store();
	}

	static function clamp01(v:Float):Float
	{
		return Math.round(Math.max(0, Math.min(1, v)) * 10) / 10;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		info.text = switch (menu.selected)
		{
			case 3: inGame ? "Difficulty can only be changed on the title screen." : difficultyInfo();
			default: "";
		};

		if (menu.isReady() && (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK)))
			back();
	}

	function difficultyInfo():String
	{
		return switch (Settings.difficulty)
		{
			case EASY: "Fewer meteors, less damage, more rewards.";
			case HARD: "More meteors, more damage, fewer rewards.";
			default: "The intended experience.";
		}
	}

	function back():Void
	{
		Settings.store();
		Audio.play("blip");
		close();
	}
}
