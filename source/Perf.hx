package;

import flixel.FlxG;

/**
 * Teljesítmény-segédek: "lite" mód (olcsóbb effektek telefonon), mérőkijelző és távoli napló.
 *
 * - `Perf.lite`: igaz érintős eszközön (a TouchControls kapcsolja be) vagy `?lite=1`-gyel; a Backdrop kevesebb időjárás-részecskét rajzol.
 * - `?fps=1`: kis kijelző a képernyő tetején: FPS, a képkocka átlag / legrosszabb ideje, a frissítés (update) és a rajzolás (draw) ideje,
 *   a 25 ms-nál hosszabb képkockák száma (ezek az akadások) és az aktív kamera-szűrők száma.
 * - `?log=1`: a mérések másodpercenként a szerverre mennek (`POST /__log`), ahol a `scripts/serve-lan.ps1` élőben kiírja a terminálba
 *   (telefonról is). Az eszköz adatait, a JS-hibákat és a lassulásokat is elküldi. Nem kell hozzá a kijelző (`?fps=1`).
 */
class Perf
{
	/** Olcsóbb megjelenítés (kevesebb részecske). */
	public static var lite:Bool = false;

	/** ?nosfx=1: a hangeffektek ki vannak kapcsolva (A/B teszt: a hang okozza-e az akadást). */
	public static var noSfx:Bool = false;

	/** `?nosound=1`: sem hangeffekt, sem zene (A/B teszt: a hang-e az oka a lassulásnak). */
	public static var noMusic:Bool = false;

	/** Időbélyeg (ms) a méréshez; JS-en kívül 0. */
	public static inline function mark():Float
	{
		#if js
		return js.Browser.window.performance.now();
		#else
		return 0;
		#end
	}

	/** Egy Audio.play hívás idejének hozzáadása a másodpercenkénti összeghez. */
	public static inline function audio(t0:Float):Void
	{
		#if js
		audMs += mark() - t0;
		audN++;
		if (mark() - t0 > audWorst)
			audWorst = mark() - t0;
		#end
	}

	#if js
	static var audMs:Float = 0;
	static var audN:Int = 0;
	static var audWorst:Float = 0;
	#end

	/** Részecskeszám skálázása: lite módban a fele. */
	public static inline function scale(n:Int):Int
		return lite ? Std.int(Math.max(1, n / 2)) : n;

	#if js
	static var box:js.html.DivElement;
	static var logging:Bool = false;
	static var lastStamp:Float = 0;
	static var updStart:Float = 0;
	static var drwStart:Float = 0;
	static var frames:Int = 0;
	static var sum:Float = 0;
	static var worst:Float = 0;
	static var slow:Int = 0;
	static var updSum:Float = 0;
	static var drwSum:Float = 0;
	static var windowStart:Float = 0;
	static var lastKey:String = "";
	/** A képkockák közötti üresjárat: a postDraw vége -> a következő preUpdate. Ami itt van, az a Flixelen kívül (OpenFL render, GPU, böngésző, hang) telik. */
	static var lastPostDraw:Float = 0;
	static var gapSum:Float = 0;
	/** Érintés- / mutatóesemények száma az utolsó másodpercben. */
	static var touchEv:Int = 0;

	static inline function now():Float
		return js.Browser.window.performance.now();

	/** Naplóüzenet a szervernek (a `?log=1` módban); hálózati hiba esetén csendben eldobja. */
	public static function log(kind:String, data:Dynamic):Void
	{
		if (!logging)
			return;
		try
		{
			var body = haxe.Json.stringify({t: Std.int(Date.now().getTime()), kind: kind, data: data});
			var nav:Dynamic = js.Browser.navigator;
			if (nav.sendBeacon != null)
				nav.sendBeacon("/__log", body);
			else
			{
				var r = new js.html.XMLHttpRequest();
				r.open("POST", "/__log", true);
				r.send(body);
			}
		}
		catch (e:Dynamic) {}
	}
	#else
	public static inline function log(kind:String, data:Dynamic):Void {}
	#end

	public static function init():Void
	{
		#if js
		var q = js.Browser.location.search;
		if (~/lite=1/.match(q))
			lite = true;
		noMusic = ~/nosound=1/.match(q);
		noSfx = noMusic || ~/nosfx=1/.match(q);
		var show = ~/fps=1/.match(q);
		logging = ~/log=1/.match(q);
		if (!show && !logging)
			return;
		if (show)
		{
			box = js.Browser.document.createDivElement();
			box.style.cssText = "position:fixed;left:50%;top:0;transform:translateX(-50%);z-index:100;pointer-events:none;padding:2px 6px;"
				+ "font:11px monospace;color:#9fff9f;background:rgba(0,0,0,0.6);white-space:pre;text-align:center;";
			js.Browser.document.body.appendChild(box);
		}
		if (logging)
		{
			var w = js.Browser.window;
			log("hello", {
				canvas: canvasInfo(),
				ua: js.Browser.navigator.userAgent,
				screen: w.screen.width + "x" + w.screen.height,
				inner: w.innerWidth + "x" + w.innerHeight,
				dpr: w.devicePixelRatio,
				touchPoints: Reflect.field(js.Browser.navigator, "maxTouchPoints"),
				url: js.Browser.location.href
			});
			w.addEventListener("error", (e:js.html.ErrorEvent) -> log("error", {msg: e.message, src: e.filename, line: e.lineno, stack: e.error != null ? Std.string(Reflect.field(e.error, "stack")).substr(0, 700) : null}));
			w.addEventListener("unhandledrejection", (e:Dynamic) -> log("error", {msg: "unhandledrejection: " + Std.string(e.reason)}));
			// A vászon / ablak méretváltozása (forgatás, teljes képernyő) is érdekes
			w.addEventListener("resize", () -> log("resize", {inner: w.innerWidth + "x" + w.innerHeight, canvas: canvasInfo()}));
			// A vászon mérete a lime késői beállítása után is: 3 mp-cel az indulás után
			haxe.Timer.delay(() -> log("canvas", canvasInfo()), 3000);
		}
		if (logging)
		{
			var cnt = (_:Dynamic) -> touchEv++;
			for (n in ["touchmove", "pointermove", "touchstart", "pointerdown"])
				js.Browser.document.addEventListener(n, cnt, true);
		}
		lastStamp = now();
		windowStart = lastStamp;
		FlxG.signals.preUpdate.add(() ->
		{
			var t = now();
			if (lastPostDraw > 0)
				gapSum += t - lastPostDraw;
			var dt = t - lastStamp;
			lastStamp = t;
			frames++;
			sum += dt;
			if (dt > worst)
				worst = dt;
			if (dt > 25)
				slow++;
			updStart = t;
		});
		FlxG.signals.postUpdate.add(() -> updSum += now() - updStart);
		FlxG.signals.preDraw.add(() -> drwStart = now());
		FlxG.signals.postDraw.add(() ->
		{
			lastPostDraw = now();
			drwSum += lastPostDraw - drwStart;
			if (lastStamp - windowStart >= 1000 && frames > 0)
				report();
		});
		#end
	}

	#if js
	/** A vászon tényleges mérete (képpont és CSS) és a nagyítás: a túl nagy háttérméret lassítja a rajzolást. */
	static function canvasInfo():Dynamic
	{
		var cv:js.html.CanvasElement = cast js.Browser.document.querySelector("canvas");
		var vv:Dynamic = Reflect.field(js.Browser.window, "visualViewport");
		if (cv == null)
			return {none: true};
		return {
			px: cv.width + "x" + cv.height,
			css: cv.clientWidth + "x" + cv.clientHeight,
			zoom: vv != null ? vv.scale : null,
			vv: vv != null ? Std.int(vv.width) + "x" + Std.int(vv.height) : null
		};
	}

	/** A Web Audio környezet állapota (running / suspended / ...): iOS-en érintésig suspended. */
	static function audioState():String
	{
		return js.Syntax.code("(window.Howler && Howler.ctx) ? Howler.ctx.state : 'n/a'");
	}

	static function report():Void
	{
		var filters = FlxG.camera.filters == null ? 0 : FlxG.camera.filters.length;
		var fps = Std.int(1000 * frames / sum);
		var avg = sum / frames, upd = updSum / frames, drw = drwSum / frames;
		if (box != null)
			box.textContent = fps + " fps  avg " + r1(avg) + " ms  worst " + r1(worst) + " ms  slow " + slow + "\n" + "update " + r1(upd) + " ms  draw " + r1(drw)
				+ " ms  filters " + filters + (lite ? "  LITE" : "");
		if (logging)
		{
			// Játékállapot: melyik állapot, szint, mennyi doboz / törmelék él (ha a PlayState fut)
			var st = FlxG.state;
			var name = Type.getClassName(Type.getClass(st));
			var info:Dynamic = {state: name == null ? "?" : name};
			if (Std.isOfType(st, PlayState))
			{
				var ps:Dynamic = st;
				info.level = Quests.level;
				info.levelState = ps.levelState;
				info.blocks = Std.int(Math.max(0, ps.blocks.countLiving())); // a Flixel üres csoportnál -1-et ad
				info.debris = ps.debrisLive;
				info.enemies = Std.int(Math.max(0, ps.enemies.countLiving()));
				info.bullets = Std.int(Math.max(0, ps.bullets.countLiving()));
				info.sub = ps.subState != null;
			}
			log("perf", {
				fps: fps,
				avg: r1(avg),
				worst: r1(worst),
				slow: slow,
				upd: r1(upd),
				drw: r1(drw),
				filters: filters,
				gap: r1(gapSum / frames),
				ev: touchEv,
				actx: audioState(),
				aud: r1(audMs) + "ms/" + audN + "x worst " + r1(audWorst),
				nosfx: noSfx,
				lite: lite,
				game: info
			});
		}
		gapSum = 0;
		touchEv = 0;
		audMs = 0;
		audN = 0;
		audWorst = 0;
		frames = 0;
		sum = 0;
		worst = 0;
		slow = 0;
		updSum = 0;
		drwSum = 0;
		windowStart = lastStamp;
	}

	static function r1(v:Float):Float
		return Math.round(v * 10) / 10;
	#end
}
