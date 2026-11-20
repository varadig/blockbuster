package;

import Controls.Action;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;

/**
 * Billentyűk átállítása: minden művelethez két billentyű; a sort kiválasztva (Enter / kattintás) a következő lenyomott billentyű lesz az új.
 * Balra / jobbra (vagy jobb kattintás, görgő) váltja, melyik helyet állítjuk. Esc megszakít, Delete / Backspace törli a helyet.
 */
class ControlsSubState extends FlxSubState
{
	var menu:MenuList;
	var hint:FlxText;
	/** Melyik hely (0 vagy 1) van kijelölve a sorokban. */
	var slot:Int = 0;
	/** Épp melyik sor vár billentyűre (-1 = egyik sem), és hány képkocka telt el azóta (az indító gombnyomást kihagyjuk). */
	var capturing:Int = -1;
	var capAge:Int = 0;

	public function new()
	{
		super(0xf0101020);
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this);

		var title = new FlxText(0, 12, FlxG.width, "CONTROLS", 16);
		title.alignment = CENTER;
		title.color = PixelArt.YELLOW;
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		var n = Controls.ACTIONS.length;
		var rows:Array<Void->String> = [for (i in 0...n) () -> rowText(i)];
		rows.push(() -> "RESET TO DEFAULTS");
		rows.push(() -> "BACK");
		menu = new MenuList(40, rows, 8, 14);
		menu.onAdjust = (i, dir) ->
		{
			if (i < n)
			{
				slot = 1 - slot;
				Audio.play("blip");
			}
		};
		menu.onSelect = i ->
		{
			if (i < n)
			{
				capturing = i;
				capAge = 0;
				Audio.play("blip");
			}
			else if (i == n)
			{
				Controls.reset();
				Audio.play("coin");
			}
			else
				back();
		};
		add(menu);

		hint = new FlxText(0, 222, FlxG.width, "", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);
	}

	function rowText(i:Int):String
	{
		var a:Action = Controls.ACTIONS[i];
		var s = Controls.slots(a);
		function cell(k:Int):String
		{
			var name = Controls.keyName(s[k]);
			if (capturing == i && slot == k)
				return "PRESS A KEY...";
			return (menu != null && menu.selected == i && slot == k) ? '[$name]' : name;
		}
		return '${Controls.NAMES[i]}   ${cell(0)}  /  ${cell(1)}';
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (capturing >= 0)
		{
			menu.active = false;
			hint.text = "Press the new key   ESC cancel   DELETE clear";
			capAge++;
			if (capAge > 2)
			{
				var k:FlxKey = FlxG.keys.firstJustPressed();
				if ((k : Int) > 0)
				{
					if (k == FlxKey.ESCAPE)
						capturing = -1;
					else if (k == FlxKey.DELETE || k == FlxKey.BACKSPACE)
					{
						Controls.clear(Controls.ACTIONS[capturing], slot);
						capturing = -1;
					}
					else if (Controls.allowed(k))
					{
						Controls.set(Controls.ACTIONS[capturing], slot, k);
						Audio.play("coin");
						capturing = -1;
					}
					else
						Audio.play("hurt");
					if (capturing < 0)
						menu.active = true;
				}
			}
			return;
		}
		hint.text = "ENTER change   LEFT / RIGHT  other key   ESC  back";
		if (menu.isReady() && (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK)))
			back();
	}

	function back():Void
	{
		Audio.play("blip");
		close();
	}
}
