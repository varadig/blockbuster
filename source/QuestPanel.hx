package;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

/** Az aktuális pálya küldetései haladással (pálya elején, szünetben, címképernyőn). */
class QuestPanel extends FlxTypedGroup<FlxText>
{
	var header:FlxText;
	var lines:Array<FlxText> = [];
	var showProgress:Bool;

	public function new(y:Float, showProgress:Bool = true)
	{
		super();
		this.showProgress = showProgress;

		header = makeText(y, PixelArt.YELLOW);
		for (i in 0...Quests.goals.length)
			lines.push(makeText(y + 14 + i * 12, PixelArt.WHITE));
		refresh();
	}

	function makeText(y:Float, color:Int):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, "", 8);
		t.alignment = CENTER;
		t.color = color;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		return t;
	}

	public function refresh():Void
	{
		header.text = 'LEVEL ${Quests.level + 1} - ${Quests.levelDef(Quests.level).name}   QUESTS ${Quests.completedCount()}/${Quests.goals.length}';
		for (i in 0...lines.length)
		{
			var done = Quests.done[i];
			var p = showProgress && !done ? '   ${Quests.progress(i)}/${Quests.target(i)}' : "";
			lines[i].text = (done ? "[X] " : "[ ] ") + Quests.text(i) + p;
			lines[i].color = done ? PixelArt.LIME : PixelArt.WHITE;
		}
	}

	override public function update(elapsed:Float):Void
	{
		refresh();
		super.update(elapsed);
	}
}
