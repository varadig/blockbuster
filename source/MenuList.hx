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
		// A menükben látszik az egérkurzor, és a menüpontok egérrel is kiválaszthatók; a játékban a PlayState elrejti
		FlxG.mouse.useSystemCursor = false; // a Flixel saját kurzora
		FlxG.mouse.visible = true;
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
		updateMouse();
		if (FlxG.keys.anyJustPressed([UP, W]) || Pad.just(UP))
		{
			selected = (selected - 1 + n) % n;
			Audio.play("blip");
		}
		else if (FlxG.keys.anyJustPressed([DOWN, S]) || Pad.just(DOWN))
		{
			selected = (selected + 1) % n;
			Audio.play("blip");
		}
		else if ((FlxG.keys.anyJustPressed([LEFT, A]) || Pad.just(LEFT)) && onAdjust != null && !disabled(selected))
			onAdjust(selected, -1);
		else if ((FlxG.keys.anyJustPressed([RIGHT, D]) || Pad.just(RIGHT)) && onAdjust != null && !disabled(selected))
			onAdjust(selected, 1);
		else if ((FlxG.keys.anyJustPressed([SPACE, ENTER, X, J]) || Pad.just(CONFIRM)) && onSelect != null && !disabled(selected))
			onSelect(selected);
		refresh();
	}

	/** A menüsor indexe az egér alatt (a képernyő-koordinátában), vagy -1. */
	function rowAt(mx:Float, my:Float):Int
	{
		if (mx < 40 || mx > FlxG.width - 40)
			return -1;
		for (i in 0...members.length)
		{
			var t = members[i];
			if (my >= t.y - 1 && my < t.y + t.height + 1)
				return i;
		}
		return -1;
	}

	/**
	 * Egér: ráhúzva kijelöl, bal kattintás kiválaszt (mint az Enter), jobb kattintás vagy az egérgörgő állít (mint a jobbra/balra nyíl).
	 * A játék képernyő-koordinátáját használja (a PlayState-ben a kamera elgörgethet, azt nem számítjuk bele).
	 */
	function updateMouse():Void
	{
		var mx = FlxG.mouse.viewX, my = FlxG.mouse.viewY;
		var row = rowAt(mx, my);
		if (row < 0)
			return;
		if (FlxG.mouse.justMoved && row != selected)
		{
			selected = row;
			Audio.play("blip");
		}
		if (row != selected)
			return;
		if (FlxG.mouse.justPressed && onSelect != null && !disabled(row))
			onSelect(row);
		else if ((FlxG.mouse.justPressedRight || FlxG.mouse.wheel > 0) && onAdjust != null && !disabled(row))
			onAdjust(row, 1);
		else if (FlxG.mouse.wheel < 0 && onAdjust != null && !disabled(row))
			onAdjust(row, -1);
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
