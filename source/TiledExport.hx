package;

#if (cheats && js)
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;

/**
 * A Tiled sprite-előnézet erőforrásai (csak fejlesztői buildben, `?exporttiled=1`): levels/objects.tsj (képgyűjtemény-csempekészlet) és levels/sprites/*.png
 * a játék saját sprite-jaiból (az első képkocka), valamint levels/previews/<pálya>.png: a pálya talaja / platformjai a játék saját festésével az égbolt előtt (a Tiled háttér-képrétege; a téglalapok szerkesztése után a script újrafuttatásával frissül). A kimenet: `window.__tiledFiles` (fájlnév -> szöveg / base64 PNG);
 * a `scripts/tiled-previews.ps1` ezt menti fájlba, és a pont-objektumokat csempe-objektumokra cseréli a .tmx-ekben.
 */
class TiledExport
{
	static function png(bmd:BitmapData):String
	{
		var ba = bmd.encode(new Rectangle(0, 0, bmd.width, bmd.height), new PNGEncoderOptions());
		return Base64.encode(Bytes.ofData(ba));
	}

	static function crop(src:BitmapData, w:Int, h:Int):BitmapData
	{
		var out = new BitmapData(w, h, true, 0);
		out.copyPixels(src, new Rectangle(0, 0, w, h), new openfl.geom.Point(0, 0));
		return out;
	}

	/** A cél-pálya zászlója (a pálya vége): oszlop és háromszög lobogó. */
	static function flag():BitmapData
	{
		var b = new BitmapData(14, 24, true, 0);
		b.fillRect(new Rectangle(1, 0, 2, 24), 0xFFE8E8E8);
		for (y in 1...9)
			b.fillRect(new Rectangle(3, y, Std.int(Math.max(1, 11 - Math.abs(y - 4) * 2.5)), 1), 0xFFE04040);
		return b;
	}

	static function sprite(name:String):BitmapData
	{
		var P = PixelArt;
		if (StringTools.startsWith(name, "enemy_"))
			return switch (name.substr(6))
			{
				case "slime": crop(P.slime().bitmap, P.SLIME_W, P.SLIME_H);
				case "bat": crop(P.bat().bitmap, P.BAT_W, P.BAT_H);
				case "turret": crop(P.turret().bitmap, P.TURRET_SIZE, P.TURRET_SIZE);
				default: crop(P.drone().bitmap, P.DRONE_W, P.DRONE_H);
			}
		if (StringTools.startsWith(name, "pickup_") || (StringTools.startsWith(name, "shroom_")))
		{
			var kind = Type.createEnum(PowerUp.PowerKind, name.substr(name.indexOf("_") + 1).toUpperCase());
			return crop(P.powerUp(kind).bitmap, P.POWER_SIZE, P.POWER_SIZE);
		}
		return switch (name)
		{
			case "player": crop(P.player().bitmap, P.PLAYER_W, P.PLAYER_H);
			case "shroom": crop(P.shroom().bitmap, P.SHROOM_SIZE, P.SHROOM_SIZE);
			case "meteor", "meteorfall": crop(P.meteor(16, 0xff9a8a7a, false).bitmap, 16, 16);
			case "meteor_gold": crop(P.meteor(16, 0xffd9a33a, true).bitmap, 16, 16);
			case "boss": crop(P.boss().bitmap, P.BOSS_W, P.BOSS_H);
			default: flag();
		}
	}

	static function o(pairs:Array<Dynamic>):Dynamic
	{
		var r:Dynamic = {};
		var i = 0;
		while (i < pairs.length)
		{
			Reflect.setField(r, pairs[i], pairs[i + 1]);
			i += 2;
		}
		return r;
	}

	/** A pálya talaj-előnézete: égbolt-színátmenet + a talaj és a platformok a játék festésével (a Tiled háttérképe). */
	static function terrain(lvl:LevelData, theme:Themes.Theme):BitmapData
	{
		Themes.current = theme;
		var W = 0;
		for (g in lvl.ground)
			W = Std.int(Math.max(W, Math.ceil(g.x + g.w)));
		W = Std.int(Math.max(W, Math.ceil(lvl.bossX + 480)));
		var H = 270;
		var base = new BitmapData(W, H, true, 0xFF000000);
		var sky = theme.sky;
		for (y in 0...H)
		{
			var t = y / (H - 1) * (sky.length - 1);
			var i = Std.int(Math.min(sky.length - 2, Math.floor(t)));
			var f = t - i;
			var a = sky[i], b = sky[i + 1];
			var c = 0xFF000000;
			for (sh in [16, 8, 0])
				c |= Std.int(((a >> sh) & 0xFF) * (1 - f) + ((b >> sh) & 0xFF) * f) << sh;
			base.fillRect(new Rectangle(0, y, W, 1), c);
		}
		for (g in lvl.ground)
		{
			var gh = g.platform ? Std.int(Math.max(8, g.h)) : H - Std.int(g.y) + 40;
			var sub = new BitmapData(Std.int(g.w), gh, true, 0);
			PixelArt.paintGround(sub, Std.int(g.x), Std.int(g.y), g.platform);
			if (g.edgeL > 0)
				PixelArt.paintEdge(sub, false, g.edgeL);
			if (g.edgeR > 0)
				PixelArt.paintEdge(sub, true, g.edgeR);
			base.copyPixels(sub, new Rectangle(0, 0, sub.width, sub.height), new openfl.geom.Point(g.x, g.y), null, null, true);
		}
		return base;
	}

	public static function run():Void
	{
		var files:Dynamic = {};
		var dims:Dynamic = {};
		var prevTheme = Themes.current;
		for (i in 0...Quests.LEVELS.length)
		{
			var def = Quests.LEVELS[i];
			if (def.map == null)
				continue;
			var lvl = LevelLoader.load(def.map);
			if (lvl == null)
				continue;
			var th = Themes.find(lvl.theme);
			if (th == null)
				th = Themes.forLevel(i);
			var img = terrain(lvl, th);
			var base = def.map.substring(def.map.lastIndexOf("/") + 1, def.map.lastIndexOf("."));
			Reflect.setField(files, "previews/" + base + ".png", png(img));
			Reflect.setField(dims, base, {w: img.width, h: img.height});
		}
		Themes.current = prevTheme;
		Reflect.setField(files, "previews/previews.json", Json.stringify(dims));
		var tiles:Array<Dynamic> = [];
		var mw = 0, mh = 0;
		for (i in 0...TiledSprites.TILES.length)
		{
			var td = TiledSprites.TILES[i];
			var b = sprite(td.name);
			mw = Std.int(Math.max(mw, b.width));
			mh = Std.int(Math.max(mh, b.height));
			Reflect.setField(files, "sprites/" + td.name + ".png", png(b));
			var props:Array<Dynamic> = [];
			if (td.def != null)
				for (f in Reflect.fields(td.def))
					props.push(o(["name", f, "type", "string", "value", Reflect.field(td.def, f)]));
			var t = o(["id", i, "image", "sprites/" + td.name + ".png", "imagewidth", b.width, "imageheight", b.height, "type", td.cls]);
			if (props.length > 0)
				Reflect.setField(t, "properties", props);
			tiles.push(t);
		}
		Reflect.setField(files, "objects.tsj", Json.stringify(o([
			"type", "tileset", "name", "objects", "version", "1.10", "tiledversion", "1.10.2", "tilewidth", mw, "tileheight", mh, "tilecount", tiles.length,
			"columns", 0, "margin", 0, "spacing", 0, "grid", o(["height", 1, "orientation", "orthogonal", "width", 1]), "tiles", tiles
		]), null, "\t"));
		js.Syntax.code("window.__tiledFiles = {0}", files);
	}
}
#end
