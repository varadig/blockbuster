package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;

/**
 * Háttér: képernyőhöz rögzített égbolt és két parallax réteg (hegyek, fás dombok).
 * Minden réteg két egymás mellé tett példány, amit a kamera görgetésével együtt léptetünk.
 */
class Backdrop extends FlxGroup
{
	var layers:Array<{sprites:Array<FlxSprite>, factor:Float}> = [];

	/** @param moonX, moonY a hold közepe képernyő-koordinátában */
	public function new(moonX:Float = 298, moonY:Float = 46)
	{
		super();
		var sky = new FlxSprite(0, 0, PixelArt.sky(FlxG.width, FlxG.height));
		sky.scrollFactor.set(0, 0);
		add(sky);

		var moon = new FlxSprite(moonX - 13, moonY - 13, PixelArt.moon());
		moon.scrollFactor.set(0, 0);
		add(moon);

		var w = FlxG.width;
		addLayer(PixelArt.ridge("px_mountains", w, FlxG.height, 175, 70, 7, 0xff120d1c, 0xff4a2c4e, false), 0.15);
		addLayer(PixelArt.ridge("px_hills", w, FlxG.height, 215, 28, 21, 0xff1a1222, 0xff0a0810, true), 0.4);
	}

	function addLayer(graphic:FlxGraphic, factor:Float):Void
	{
		var sprites = [];
		for (i in 0...2)
		{
			var s = new FlxSprite(0, 0, graphic);
			s.scrollFactor.set(factor, 0);
			add(s);
			sprites.push(s);
		}
		layers.push({sprites: sprites, factor: factor});
	}

	override public function update(elapsed:Float):Void
	{
		for (layer in layers)
		{
			var w = layer.sprites[0].width;
			var base = Math.floor(FlxG.camera.scroll.x * layer.factor / w) * w;
			for (i in 0...layer.sprites.length)
				layer.sprites[i].x = base + i * w;
		}
		super.update(elapsed);
	}
}
