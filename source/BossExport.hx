package;

#if (cheats && js)
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;

/**
 * A főellenség-sprite-ok exportja PNG-be (további felhasználásra): csak fejlesztői buildben, a `?exportboss=1` URL-paraméterrel.
 * Mindegyik főellenségről: a teljes képkocka-sor 1x-esen és nagyítva, valamint az egyes képkockák nagyítva (egész számú, élesre nagyított pixelek).
 * A kimenet a `window.__bossPng`-ben (név -> base64 PNG); a `scripts/export-bosses.ps1` ezt menti fájlba.
 */
class BossExport
{
	/** A nagyítás szorzója a "jó minőségű" változatokhoz. */
	static inline var SCALE:Int = 8;

	static function png(bmd:BitmapData):String
	{
		var ba = bmd.encode(new Rectangle(0, 0, bmd.width, bmd.height), new PNGEncoderOptions());
		return Base64.encode(Bytes.ofData(ba));
	}

	/** Élesre (legközelebbi szomszéd) nagyított másolat, a darabot a (sx, sy, w, h) téglalapból véve. */
	static function scaled(src:BitmapData, sx:Int, sy:Int, w:Int, h:Int, k:Int):BitmapData
	{
		var out = new BitmapData(w * k, h * k, true, 0);
		for (y in 0...h)
			for (x in 0...w)
			{
				var c = src.getPixel32(sx + x, sy + y);
				if ((c >>> 24) != 0)
					out.fillRect(new Rectangle(x * k, y * k, k, k), c);
			}
		return out;
	}

	public static function run():Void
	{
		var list:Array<{name:String, g:FlxGraphic, w:Int, h:Int}> = [
			{name: "mothership", g: PixelArt.boss(), w: PixelArt.BOSS_W, h: PixelArt.BOSS_H},
			{name: "tank", g: PixelArt.bossTank(), w: PixelArt.TANK_W, h: PixelArt.TANK_H},
			{name: "ghost", g: PixelArt.bossGhost(), w: PixelArt.GHOST_W, h: PixelArt.GHOST_H},
			{name: "brute", g: PixelArt.bossBrute(), w: PixelArt.BRUTE_W, h: PixelArt.BRUTE_H},
			{name: "stalker", g: PixelArt.bossStalker(), w: PixelArt.STALKER_W, h: PixelArt.STALKER_H},
			{name: "killer", g: PixelArt.bossKiller(), w: PixelArt.KILLER_W, h: PixelArt.KILLER_H},
			{name: "strider", g: PixelArt.bossStrider(), w: PixelArt.STRIDER_W, h: PixelArt.STRIDER_H},
			{name: "puff", g: PixelArt.bossPuff(), w: PixelArt.PUFF_BOSS_W, h: PixelArt.PUFF_BOSS_H},
			{name: "hollow", g: PixelArt.bossHollow(), w: PixelArt.HOLLOW_W, h: PixelArt.HOLLOW_H},
			{name: "slime_final", g: PixelArt.bossSlime(), w: PixelArt.BOSSSLIME_W, h: PixelArt.BOSSSLIME_H}
		];
		var out:Dynamic = {};
		for (b in list)
		{
			var bmd = b.g.bitmap;
			var frames = Std.int(bmd.width / b.w);
			Reflect.setField(out, b.name + "_sheet_1x.png", png(bmd));
			Reflect.setField(out, b.name + "_sheet_x" + SCALE + ".png", png(scaled(bmd, 0, 0, bmd.width, bmd.height, SCALE)));
			for (f in 0...frames)
				Reflect.setField(out, b.name + "_frame" + f + "_x" + SCALE + ".png", png(scaled(bmd, f * b.w, 0, b.w, b.h, SCALE)));
		}
		js.Syntax.code("window.__bossPng = {0}", out);
	}
}
#end
