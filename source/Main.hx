package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		// Belső felbontás 480x270, az ablak 2x-esen nagyít (pixeles hatás)
		addChild(new FlxGame(480, 270, PlayState, 60, 60, true));
	}
}
