package;

#if js
import flixel.FlxG;
import js.Browser;
import js.html.DivElement;
import js.html.PointerEvent;

/**
 * Képernyőgombok mobil böngészőhöz: HTML-elemek a vászon fölött (többujjas érintéssel), amik a `Pad` gombállapotait kapcsolják,
 * így a Player és a menük külön kód nélkül használják őket.
 *
 * Mikor jelenik meg: ha az eszköz érintős (`pointer: coarse`), az első érintésre, vagy a `?touch=1` URL-paraméterrel.
 * Csak játék közben látszik (PlayState, nyitott menü nélkül); a menükben az érintés egérkattintásként működik.
 * Kiosztás: bal oldalt irányok (◀ ▶, ▲ felfelé célzás, ▼ guggolás), jobb oldalt ugrás, lövés, töltött lövés; jobb felül szünet.
 */
class TouchControls
{
	/** A Pad gombindexei (PadAction), amiket az egyes képernyőgombok nyomnak. */
	static var held:Array<Bool> = [for (_ in 0...11) false];

	static var root:DivElement;
	/** Ha nem null, a következő gomb ebbe az elembe kerül a oot helyett (pl. a menü fölött is látszó gombok). */
	static var parentOverride:Null<js.html.Element>;
	static var enabled:Bool = false;
	static var shown:Bool = false;
	/** Gombonként (PadAction) hány ujj tartja éppen. */
	static var fingers:Map<Int, Int> = new Map();

	public static function init():Void
	{
		var w = Browser.window;
		var forced = ~/touch=1/.match(w.location.search);
		var coarse = w.matchMedia != null && w.matchMedia("(pointer: coarse)").matches;
		if (forced || coarse)
			enable();
		else
			js.Syntax.code("{0}.addEventListener('touchstart', {1}, {once: true, passive: true})", w, enable);
		FlxG.signals.preUpdate.add(updateVisibility);
		// Érintős eszközön az egérkurzor értelmetlen: a menük (MenuList, súgó…) bekapcsolnák, ezért minden képkocka végén elrejtjük
		FlxG.signals.postUpdate.add(hideCursor);
		// A teljes képernyő gomb minden eszközön látszik (desktopon is: az F billentyű mellett)
		buildFullscreenButton();
	}

	/** A Pad.poll hívja minden képkockában: a nyomott képernyőgombokat a gombállapotok közé keveri. */
	public static function apply(now:Array<Bool>):Void
	{
		if (!enabled)
			return;
		for (i in 0...now.length)
			// A játékgombok csak akkor számítanak, ha látszanak; a cheat-gomb (10) menü fölött is (a menü bezárásához)
			if (held[i] && (shown || i == 10))
				now[i] = true;
	}

	static function enable(?_):Void
	{
		if (enabled)
			return;
		enabled = true;
		Perf.lite = true; // telefonon olcsóbb effektek
		build();
	}

	static function hideCursor():Void
	{
		if (enabled && FlxG.mouse.visible)
			FlxG.mouse.visible = false;
	}

	static function updateVisibility():Void
	{
		if (!enabled || root == null)
			return;
		var want = Std.isOfType(FlxG.state, PlayState) && FlxG.state.subState == null;
		if (want == shown)
			return;
		shown = want;
		root.style.display = want ? "block" : "none";
		if (!want)
			releaseAll();
	}

	/**
	 * iOS Safari: a kétujjas nagyítás (gesturestart), a dupla koppintásos nagyítás és a hosszú nyomásra jövő kijelölés / nagyító ellen.
	 * A meta viewport user-scalable=no-t az iOS 10 óta figyelmen kívül hagyja, ezért az eseményeket kell letiltani.
	 */
	static function preventZoom():Void
	{
		js.Syntax.code("(function () {
			var opt = {passive: false};
			['gesturestart', 'gesturechange', 'gestureend'].forEach(function (n) { document.addEventListener(n, function (e) { e.preventDefault(); }, opt); });
			var last = 0;
			document.addEventListener('touchend', function (e) { var t = Date.now(); if (t - last < 350) e.preventDefault(); last = t; }, opt);
			document.addEventListener('dblclick', function (e) { e.preventDefault(); }, opt);
			document.addEventListener('selectstart', function (e) { e.preventDefault(); }, opt);
			document.addEventListener('contextmenu', function (e) { e.preventDefault(); }, opt);
		})()");
	}

	/**
	 * Teljes képernyő gomb (bal felül, mindig látszik, a menükben is): a böngészők csak felhasználói érintésre engedik, ezért a gomb
	 * saját eseménykezelőjéből kérjük. Androidon (Chrome) működik; iPad-en a webkit előtagos változattal. iPhone Safari-ban a teljes képernyő
	 * API a nem-videó elemekre nincs, ott a gomb rejtve marad, és az oldal "Add to Home Screen" (Főképernyőre) után önálló, teljes képernyős
	 * appként indul (az apple-mobile-web-app-capable meta miatt).
	 */
	static function buildFullscreenButton():Void
	{
		js.Syntax.code("(function (svg) {
			var d = document, root = d.documentElement;
			var head = d.head;
			function meta(n, c) { var m = d.createElement('meta'); m.name = n; m.content = c; head.appendChild(m); }
			meta('apple-mobile-web-app-capable', 'yes');
			meta('mobile-web-app-capable', 'yes');
			meta('apple-mobile-web-app-status-bar-style', 'black-translucent');
			var vp = d.getElementById('viewport');
			if (vp && vp.content.indexOf('viewport-fit') < 0) vp.content += ', viewport-fit=cover';
			var req = root.requestFullscreen || root.webkitRequestFullscreen || root.msRequestFullscreen;
			// Az oldal soha ne görgessen: a vászon mindig a látható területet tölti ki (iOS Safari eszköztára miatt ne legyen lelógó rész)
			d.documentElement.style.cssText += ';height:100%;overflow:hidden;';
			d.body.style.cssText += ';position:fixed;left:0;top:0;width:100%;height:100%;overflow:hidden;margin:0;';
			// iPhone: nincs teljes képernyő API; Főképernyőre téve (standalone) már teljes képernyős, ott nem kell gomb
			if (!req && (window.navigator.standalone || !/iPhone|iPod/.test(navigator.userAgent))) return;
			function isFs() { return !!(d.fullscreenElement || d.webkitFullscreenElement); }
			var b = d.createElement('div');
			b.innerHTML = svg;
			b.style.cssText = 'position:fixed;left:2vmin;top:2vmin;width:9vmin;height:9vmin;z-index:60;display:flex;align-items:center;justify-content:center;'
				+ 'box-sizing:border-box;border:2px solid rgba(255,255,255,0.55);border-radius:22%;background:rgba(20,24,40,0.38);color:rgba(255,255,255,0.85);'
				+ 'font:bold 5vmin sans-serif;user-select:none;-webkit-user-select:none;touch-action:none;';
			function hint() {
				var h = d.createElement('div');
				h.textContent = 'iPhone browsers cannot go full screen. Open the browser menu or Share sheet, choose Add to Home Screen, then launch the game from the new icon: it opens full screen.';
				h.style.cssText = 'position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);width:78%;z-index:70;padding:3vmin;border-radius:3vmin;background:rgba(10,12,24,0.92);'
					+ 'color:#fff;font:bold 4vmin sans-serif;text-align:center;border:2px solid rgba(255,255,255,0.6);';
				h.addEventListener('pointerup', function () { h.remove(); });
				d.body.appendChild(h);
				setTimeout(function () { h.remove(); }, 9000);
			}
			function toggle(e) {
				e.preventDefault(); e.stopPropagation();
				if (!req) { hint(); return; }
				try {
					var p;
					if (isFs()) p = (d.exitFullscreen || d.webkitExitFullscreen).call(d);
					else p = req.call(root);
					if (p && p.catch) p.catch(function () {});
				} catch (err) {}
			}
			// A teljes képernyő kérése érintés-felengedésből (felhasználói művelet) fut
			b.addEventListener('pointerup', toggle);
			b.addEventListener('click', toggle);
			function sync() { b.style.opacity = isFs() ? '0.35' : '1'; }
			d.addEventListener('fullscreenchange', sync);
			d.addEventListener('webkitfullscreenchange', sync);
			d.body.appendChild(b);
		})({0})", ICON_FULLSCREEN);
	}

	static function releaseAll():Void
	{
		for (i in 0...held.length)
			held[i] = false;
		fingers = new Map();
	}

	static function build():Void
	{
		var d = Browser.document;
		// Az oldal ne görgessen / nagyítson az érintésre
		d.body.style.setProperty("touch-action", "none");
		d.body.style.setProperty("-webkit-user-select", "none");
		d.body.style.setProperty("-webkit-touch-callout", "none");
		preventZoom();
		root = d.createDivElement();
		root.style.cssText = "position:fixed;left:0;top:0;width:100%;height:100%;pointer-events:none;display:none;z-index:50;"
			+ "user-select:none;-webkit-user-select:none;-webkit-touch-callout:none;touch-action:none;";
		d.body.appendChild(root);

		// Méret a rövidebb oldalhoz igazítva (vmin), hogy fekvő és álló nézetben is jó legyen
		var u = "vmin";
		// Bal oldal: irányok (alsó sor: ◀ ▼ ▶, fölötte: ▲ felfelé célzás); egy cella 15 vmin
		var cs = 15;
		button("LEFT", 2, 6, 4, cs, cs, u, [0]);
		button("DOWN", 2, 6, 4 + cs + 1, cs, cs, u, [3]);
		button("RIGHT", 2, 6, 4 + 2 * (cs + 1), cs, cs, u, [1]);
		button("UP", 2, 6 + cs + 1, 4 + cs + 1, cs, cs, u, [2]);
		// Jobb oldal: ugrás (nagy), lövés (nagy), töltés (kicsi)
		button("JUMP", 1, 6, 4, 19, 19, u, [4, 7]); // ugrás (a "megerősítés" is: folytatás-ajánlat, játék vége)
		button("FIRE", 1, 6 + 19 + 2, 4, 19, 19, u, [5]);
		button("CHG", 1, 6 + 19 + 2 + 19 + 2, 7, 13, 13, u, [6]);
		// Jobb felül: szünet
		button("II", 1, 2, 2, 9, 9, u, [9], true);
		#if cheats
		// Cheat-menü (F9 / R2 megfelelője): csak cheats buildben; a menü nyitva is látszik, hogy be lehessen zárni
		parentOverride = d.body;
		button("CHEAT", 1, 2, 13, 14, 9, u, [10], true);
		parentOverride = null;
		#end
	}

	/**
	 * Egy képernyőgomb. `side`: 2 = bal alsó kezdőponttól, 1 = jobb alsó; a `bottom`/`edge` a megfelelő szélektől mért távolság
	 * (a `top` jelzővel felülről mért). A `keys` a nyomott PadAction indexek.
	 */
	static function button(label:String, side:Int, bottom:Float, edge:Float, w:Float, h:Float, u:String, keys:Array<Int>, top:Bool = false):Void
	{
		var b = Browser.document.createDivElement();
		var vert = top ? "top:" + bottom + u : "bottom:" + bottom + u;
		var horiz = side == 2 ? "left:" + edge + u : "right:" + edge + u;
		b.style.cssText = "position:absolute;" + vert + ";" + horiz + ";width:" + w + u + ";height:" + h + u + ";pointer-events:auto;"
			+ "box-sizing:border-box;border:2px solid rgba(255,255,255,0.55);border-radius:22%;background:rgba(20,24,40,0.38);"
			+ "color:rgba(255,255,255,0.85);font:bold " + (w * 0.28) + u + " sans-serif;display:flex;align-items:center;justify-content:center;"
			+ "user-select:none;-webkit-user-select:none;touch-action:none;";
		var svg = iconFor(label);
		if (svg != null)
		{
			b.innerHTML = svg;
			b.style.color = "rgba(255,255,255,0.92)";
		}
		else
			b.textContent = label;
		// A gomb saját ujjait követjük pointerId alapján (több ujj egyszerre)
		var down:Map<Int, Bool> = new Map();
		function press(e:PointerEvent):Void
		{
			e.preventDefault();
			if (down.exists(e.pointerId))
				return;
			down.set(e.pointerId, true);
			for (k in keys)
				add(k, 1);
			b.style.background = "rgba(255,255,255,0.35)";
		}
		function release(e:PointerEvent):Void
		{
			if (!down.exists(e.pointerId))
				return;
			down.remove(e.pointerId);
			for (k in keys)
				add(k, -1);
			if (!down.keys().hasNext())
				b.style.background = "rgba(20,24,40,0.38)";
		}
		b.addEventListener("pointerdown", press);
		b.addEventListener("pointerup", release);
		b.addEventListener("pointercancel", release);
		b.addEventListener("pointerleave", release);
		b.addEventListener("contextmenu", (e) -> e.preventDefault());
		(parentOverride != null ? parentOverride : root).appendChild(b);
	}

	static function add(key:Int, delta:Int):Void
	{
		var n = (fingers.exists(key) ? fingers.get(key) : 0) + delta;
		if (n < 0)
			n = 0;
		fingers.set(key, n);
		held[key] = n > 0;
	}

	// --- Rajzolt ikonok (SVG): a szöveges nyilak (◀ ▶ …) iOS-en emoji-szerűen, csúnyán jelennek meg ---------------------------------

	static inline var SVG_HEAD = '<svg viewBox="0 0 24 24" style="width:60%;height:60%;display:block" xmlns="http://www.w3.org/2000/svg">';
	static inline var STROKE = ' fill="none" stroke="currentColor" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"';

	static function chevron(d:String):String
		return SVG_HEAD + '<path d="' + d + '"' + STROKE + '/></svg>';

	/** Teljes képernyő ikon: négy sarok-jel. */
	static inline var ICON_FULLSCREEN = '<svg viewBox="0 0 24 24" style="width:62%;height:62%;display:block" xmlns="http://www.w3.org/2000/svg">'
		+ '<path d="M4 9 V4 H9 M15 4 H20 V9 M20 15 V20 H15 M9 20 H4 V15" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';

	/** A gomb azonosítója -> rajzolt ikon (null: marad a szöveg). */
	static function iconFor(label:String):Null<String>
	{
		return switch (label)
		{
			case "LEFT": chevron("M15 4.5 L7.5 12 L15 19.5");
			case "RIGHT": chevron("M9 4.5 L16.5 12 L9 19.5");
			case "UP": chevron("M4.5 15 L12 7.5 L19.5 15");
			case "DOWN": chevron("M4.5 9 L12 16.5 L19.5 9");
			// Ugrás: két egymás fölötti felfelé nyíl (emelkedés)
			case "JUMP": chevron("M5 12.5 L12 5.5 L19 12.5 M5 19.5 L12 12.5 L19 19.5");
			// Lövés: jobbra repülő lövedék, mögötte sebességvonalak
			case "FIRE": SVG_HEAD + '<path d="M9 8.5 H15 Q20.5 8.5 21 12 Q20.5 15.5 15 15.5 H9 Z" fill="currentColor"/>'
				+ '<path d="M2.5 9 H6 M2.5 12 H5 M2.5 15 H6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
			// Töltés: részben töltött gyűrű, közepén pont
			case "CHG": SVG_HEAD + '<circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-dasharray="32 18" transform="rotate(-90 12 12)"/>'
				+ '<circle cx="12" cy="12" r="2.8" fill="currentColor"/></svg>';
			case "II": SVG_HEAD + '<rect x="6" y="4.5" width="4.2" height="15" rx="1.2" fill="currentColor"/><rect x="13.8" y="4.5" width="4.2" height="15" rx="1.2" fill="currentColor"/></svg>';
			default: null;
		}
	}
}
#end
