package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Bevezető történet a játék indítása előtt: a háttérben a holdas égbolt, a szöveg gépírásszerűen jelenik meg.
 * Enter / Space / kattintás: először kiírja az egész szöveget, másodszor továbblép (az irányítás-képernyőre, aztán a karakterválasztóra).
 */
class IntroState extends FlxState
{
	static final STORY:Array<String> = [
		"Long ago the Moon cracked in two.",
		"",
		"Its shards still drift across the night,",
		"calling down a rain of burning stone.",
		"",
		"One hero is still awake, with a blaster",
		"and a stubborn heart.",
		"",
		"Survive the meteor rain. Beat the guardians",
		"of the shards. Bring the Moon back.",
	];

	static inline var CHARS_PER_SEC:Float = 32;

	var text:FlxText;
	var full:String;
	var shown:Float = 0;
	var hint:FlxText;
	var done:Bool = false;
	var leaving:Bool = false;
	var time:Float = 0;

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = false;
		Settings.load();
		Audio.init();
		Themes.current = Themes.NIGHT;
		FlxG.camera.bgColor = PixelArt.OUTLINE;
		add(new Backdrop(380, 52, 0));

		full = STORY.join("\n");
		text = new FlxText(0, 78, FlxG.width, "", 8);
		text.alignment = CENTER;
		text.color = PixelArt.WHITE;
		text.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		text.scrollFactor.set(0, 0);
		add(text);

		hint = new FlxText(0, 236, FlxG.width, "ENTER  continue", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);

		FlxG.camera.fade(PixelArt.OUTLINE, 0.6, true);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		time += elapsed;
		if (leaving)
			return;

		if (!done)
		{
			shown += CHARS_PER_SEC * elapsed;
			var n = Std.int(Math.min(shown, full.length));
			text.text = full.substr(0, n);
			if (n >= full.length)
				done = true;
		}
		hint.visible = done ? Std.int(time * 2) % 2 == 0 : true;
		hint.text = done ? "ENTER  continue" : "ENTER  skip";

		var confirm = FlxG.keys.anyJustPressed([ENTER, SPACE]) || Pad.just(CONFIRM) || Pad.just(START);
		if (confirm || FlxG.mouse.justPressed)
		{
			if (!done)
			{
				done = true;
				shown = full.length;
				text.text = full;
			}
			else
				next();
		}
		else if (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK))
			FlxG.switchState(TitleState.new);
	}

	/** A történet után az irányítás-képernyő, majd a karakterválasztó. */
	function next():Void
	{
		leaving = true;
		Audio.play("blip");
		var s = new HelpSubState(true);
		s.closeCallback = () -> FlxG.switchState(CharacterSelectState.new);
		openSubState(s);
	}
}
