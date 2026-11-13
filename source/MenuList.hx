package;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Egyszerű függőleges menü: fel/le választ, balra/jobbra állít, Space/Enter kiválaszt.
 * A feliratok függvények, így mindig az aktuális értéket mutatják (pl. hangerő).
 */
class MenuList extends FlxTypedGroup<FlxText>
{
	public var selected:Int = 0;
	public var onSelect:Int->Void;
	/** Balra/jobbra állítás: (index, irány -1/+1). */
	public var onAdjust:(Int, Int)->Void;
	/** Letiltott sor (pl. nehézség játék közben): kiválasztani nem lehet, halványan látszik. */
	public var isDisabled:Int->Bool;

	var labels:Array<Void->String>;
	/** Az első képkockában nem figyelünk a billentyűkre (a megnyitó gombnyomás ne válasszon ki rögtön valamit). */
	var ready:Bool = false;
	var time:Float = 0;

	public function new(y:Float, labels:Array<Void->String>, size:Int = 8, spacing:Int = 14)
	{
		super();
		this.labels = labels;
		for (i in 0...labels.length)
		{
			var t = new FlxText(0, y + i * spacing, FlxG.width, "", size);
			t.alignment = CENTER;
			t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
			t.scrollFactor.set(0, 0);
			add(t);
		}
		refresh();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		time += elapsed;
		if (!ready)
		{
			ready = true;
			refresh();
			return;
		}

		var n = labels.length;
		if (FlxG.keys.anyJustPressed([UP, W]))
		{
			selected = (selected - 1 + n) % n;
			Audio.play("blip");
		}
		else if (FlxG.keys.anyJustPressed([DOWN, S]))
		{
			selected = (selected + 1) % n;
			Audio.play("blip");
		}
		else if (FlxG.keys.anyJustPressed([LEFT, A]) && onAdjust != null && !disabled(selected))
			onAdjust(selected, -1);
		else if (FlxG.keys.anyJustPressed([RIGHT, D]) && onAdjust != null && !disabled(selected))
			onAdjust(selected, 1);
		else if (FlxG.keys.anyJustPressed([SPACE, ENTER, X, J]) && onSelect != null && !disabled(selected))
			onSelect(selected);
		refresh();
	}

	/** Igaz, ha ez már nem az első képkocka (a hívó is használhatja ugyanerre a célra). */
	public function isReady():Bool
	{
		return ready;
	}

	function disabled(i:Int):Bool
	{
		return isDisabled != null && isDisabled(i);
	}

	function refresh():Void
	{
		for (i in 0...members.length)
		{
			var t = members[i];
			var label = labels[i]();
			var sel = i == selected;
			t.text = sel ? '> $label <' : label;
			t.color = disabled(i) ? PixelArt.GRAY : (sel ? (Std.int(time * 4) % 2 == 0 ? PixelArt.YELLOW : FlxColor.WHITE) : PixelArt.LIGHT_GRAY);
		}
	}
}
