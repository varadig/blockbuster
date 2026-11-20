package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		#if (cheats && js)
		// ?exportboss=1: a főellenség-sprite-ok PNG-exportja (scripts/export-bosses.ps1)
		if (js.Browser.location.search.indexOf("exportboss=1") >= 0)
			flixel.FlxG.signals.postGameStart.addOnce(BossExport.run);
		// ?exporttiled=1: a Tiled sprite-előnézet erőforrásai (scripts/tiled-previews.ps1)
		if (js.Browser.location.search.indexOf("exporttiled=1") >= 0)
			flixel.FlxG.signals.postGameStart.addOnce(TiledExport.run);
		#end

		// Belső felbontás 480x270, arányos nagyítással kitölti az ablakot (pixeles hatás)
		// Tesztbuildben egyből a játék indul (a füstteszt a PlayState-et várja), egyébként a nyitóképernyő
		#if test
		addChild(new FlxGame(480, 270, PlayState, 60, 60, true));
		#else
		addChild(new FlxGame(480, 270, TitleState, 60, 60, true));
		#end

		// Kontroller (PS4 / Xbox) műveletei
		Pad.init();

		Perf.init();

		#if js
		TouchControls.init();
		#end

		#if js
		// F: teljes képernyő. Böngészőben közvetlenül a billentyűeseményből kérjük, mert a böngészők csak
		// felhasználói műveletre engedik (a játékciklusból kérve elutasíthatják). Az itch.io keretében
		// akkor működik, ha ott a teljes képernyő engedélyezve van.
		js.Browser.window.addEventListener("keydown", (e:js.html.KeyboardEvent) ->
		{
			if (e.code != "KeyF" || e.repeat)
				return;
			js.Syntax.code("var d = document;
				var p = d.fullscreenElement ? d.exitFullscreen() : d.documentElement.requestFullscreen();
				if (p && p.catch) p.catch(function () {});");
		});
		#end
	}
}
