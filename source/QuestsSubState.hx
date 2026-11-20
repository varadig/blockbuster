package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** A címképernyő küldetés-ablaka: az aktív küldetések és a rang. */
class QuestsSubState extends FlxSubState
{
	var ready:Bool = false;

	public function new()
	{
		super(0xf0101020);
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this); // a játék kameraeffektjei (shaderek) a menüt nem érintik

		var title = new FlxText(0, 60, FlxG.width, "QUESTS", 16);
		title.alignment = CENTER;
		title.color = PixelArt.YELLOW;
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		// Az első pálya küldetései (a játék mindig az 1. pályával indul)
		Quests.startLevel(0);
		add(new QuestPanel(100, false));

		var info = new FlxText(0, 160, FlxG.width,
			"Complete all quests of a level to face its boss.\nDefeat the boss to advance to the next level.", 8);
		info.alignment = CENTER;
		info.color = PixelArt.LIGHT_GRAY;
		info.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		info.scrollFactor.set(0, 0);
		add(info);

		var hint = new FlxText(0, 222, FlxG.width, "ESC / SPACE  back", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		// Az első képkockában a megnyitó gombnyomást még nem vesszük figyelembe
		FlxG.mouse.useSystemCursor = false; // a Flixel saját kurzora
		FlxG.mouse.visible = true;
		if (ready && (FlxG.keys.anyJustPressed([ESCAPE, SPACE, ENTER]) || Pad.just(BACK) || Pad.just(CONFIRM) || FlxG.mouse.justPressed))
		{
			Audio.play("blip");
			close();
		}
		ready = true;
	}
}
