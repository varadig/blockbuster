package;

#if js
import haxe.io.Bytes;

/**
 * Hang közvetlenül a Web Audio API-val (csak böngészőben): hangeffektek és zene.
 *
 * - Az effektek: a lime/Flixel útja (`FlxG.sound.play`) iPhone-on hívásonként 100-180 ms-ot vett igénybe (a naplóban: "aud 276ms/5x worst 179").
 *   Itt minden effekt egyszer `AudioBuffer`-be kerül, lejátszáskor csak egy `BufferSource` + `Gain` jön létre (< 1 ms).
 * - A zene: a lime hangmotorja iPhone-on nem indult el ("Failed to start the audio device"), ezért a zenét is itt játsszuk, egy hurkolt forrással.
 *
 * A hangkörnyezet (AudioContext) az iOS miatt az első érintésre / kattintásra / billentyűre indul és éled fel (resume). Amíg nem fut, az effektek
 * a lime útjára esnek vissza; a zene a kért állapotot megjegyzi, és a környezet indulásakor kezdi el.
 */
class WebSfx
{
	static var ctx:Dynamic;
	static var buffers:Map<String, Dynamic> = new Map();
	static var pending:Map<String, Bytes> = new Map();
	/** Egyszerre szóló effektek: ennél több fölött a további effekt elmarad (védi a CPU-t). */
	static inline var MAX_VOICES:Int = 10;
	static var active:Int = 0;
	static var logged:Bool = false;
	static var playLogged:Int = 0;

	// --- Zene ------------------------------------------------------------------------------------------------------------
	static var musicBuffers:Map<String, Dynamic> = new Map();
	static var musicPending:Map<String, {wav:Bytes, ch:Int}> = new Map();
	/** A kért zenei állapot (az Audio állítja): melyik dal, hangerő, szünetel-e. */
	static var wName:Null<String> = null;
	static var wVol:Float = 0.5;
	static var wPaused:Bool = false;
	/** Az épp szóló (vagy szüneteltetett) dal, forrása, hangereje, a kezdés ideje és a lejátszási pozíció (mp) szünetkor. */
	static var curName:Null<String> = null;
	static var curSrc:Dynamic = null;
	static var curGain:Dynamic = null;
	static var startedAt:Float = 0;
	static var offset:Float = 0;

	/** Egy effekt WAV-ja (a generáláskor hívja az Audio). */
	public static function register(name:String, wav:Bytes):Void
	{
		pending.set(name, wav);
		if (ctx != null)
			decode(name, wav);
	}

	/** Egy zenei dal WAV-ja (8 bites, `ch` csatornás, interleaved). */
	public static function registerMusic(name:String, wav:Bytes, ch:Int):Void
	{
		musicPending.set(name, {wav: wav, ch: ch});
		if (ctx != null)
			scheduleMusicDecode(name, wav, ch);
	}

	/**
	 * A zene dekódolása (több százezer minta) nem blokkolja az indulást: a dalok egymás után, rövid késleltetéssel kerülnek sorra, és a fő dal az első.
	 * A hangkörnyezet már az induláskor létrejön (felhasználói művelet nélkül is, suspended állapotban), így az első érintésre csak fel kell éleszteni.
	 */
	static var musicSeq:Int = 0;

	static function scheduleMusicDecode(name:String, wav:Bytes, ch:Int):Void
	{
		var delay = 50 + 350 * musicSeq++;
		haxe.Timer.delay(() ->
		{
			if (musicBuffers.exists(name))
				return;
			var t0 = Perf.mark();
			decodeMusic(name, wav, ch);
			Perf.log("sfx", {what: "music-decoded", name: name, ms: Perf.mark() - t0});
			applyMusic();
		}, Std.int(delay));
	}

	/** A hangkörnyezet indításának / felélesztésének bekötése a felhasználói műveletekre. */
	public static function init():Void
	{
		ensureCtx();
		var handler = (_:Dynamic) -> unlock();
		for (n in ["touchend", "pointerup", "click", "keydown"])
			js.Browser.document.addEventListener(n, handler, true);
	}

	/** A hangkörnyezet létrehozása (egyszer); a már regisztrált hangokat dekódolja, a zenét ütemezve. */
	static function ensureCtx():Void
	{
		if (ctx != null)
			return;
		try
		{
			ctx = js.Syntax.code("new (window.AudioContext || window.webkitAudioContext)()");
			for (name => wav in pending)
				decode(name, wav);
			for (name => m in musicPending)
				scheduleMusicDecode(name, m.wav, m.ch);
			applyMusic();
		}
		catch (e:Dynamic)
		{
			ctx = null;
			Perf.log("sfx", {what: "ctx-fail", err: Std.string(e)});
		}
	}

	static function unlock():Void
	{
		try
		{
			ensureCtx();
			if (ctx.state != "running")
				js.Syntax.code("{0}.resume().then(function () { {1}('resume-ok', {0}.state); {2}(); }, function (e) { {1}('resume-fail', String(e)); })", ctx, report, applyMusic);
			startSilentLoop();
			// iOS: a csengetés-némító kapcsoló ne némítsa a játék hangját (Safari 16.4+: audioSession)
			js.Syntax.code("if (navigator.audioSession) navigator.audioSession.type = 'playback'");
			// Egy néma minta lejátszása teljesen feloldja a hangot iOS-en
			js.Syntax.code("(function (c) { var b = c.createBuffer(1, 1, 22050), s = c.createBufferSource(); s.buffer = b; s.connect(c.destination); s.start(0); })({0})", ctx);
			js.Syntax.code("window.__sfx = {0}", {ctx: ctx, buffers: buffers, info: () -> {name: curName, playing: curSrc != null, paused: wPaused, vol: wVol, music: [for (k in musicBuffers.keys()) k]}}); // tesztelhetőség
			if (!logged)
			{
				logged = true;
				var n = 0;
				for (_ in buffers.keys())
					n++;
				var m = 0;
				for (_ in musicBuffers.keys())
					m++;
				Perf.log("sfx", {what: "unlock", state: ctx.state, buffers: n, music: m, sampleRate: ctx.sampleRate});
			}
		}
		catch (e:Dynamic)
		{
			Perf.log("sfx", {what: "unlock-fail", err: Std.string(e)});
		}
	}

	static function report(what:String, detail:String):Void
		Perf.log("sfx", {what: what, detail: detail});

	static var silent:Dynamic;

	/**
	 * Néma, végtelenített HTML-hang: iOS-en ettől a lap hang-munkamenete "lejátszás" típusú lesz, és a Web Audio nem némul a
	 * csengetés-kapcsoló miatt (a HTML médiaelemek a kapcsolótól függetlenül szólnak). Régóta használt megoldás iOS-re.
	 */
	static function startSilentLoop():Void
	{
		if (silent != null)
			return;
		try
		{
			var n = 800;
			var b = Bytes.alloc(44 + n);
			function str(pos:Int, s:String)
				for (i in 0...s.length)
					b.set(pos + i, s.charCodeAt(i));
			str(0, "RIFF");
			b.setInt32(4, 36 + n);
			str(8, "WAVE");
			str(12, "fmt ");
			b.setInt32(16, 16);
			b.setUInt16(20, 1);
			b.setUInt16(22, 1);
			b.setInt32(24, 8000);
			b.setInt32(28, 8000);
			b.setUInt16(32, 1);
			b.setUInt16(34, 8);
			str(36, "data");
			b.setInt32(40, n);
			for (i in 0...n)
				b.set(44 + i, 128);
			var uri = "data:audio/wav;base64," + haxe.crypto.Base64.encode(b);
			silent = js.Syntax.code("(function (u, rep) { var a = document.createElement('audio'); a.src = u; a.loop = true; a.setAttribute('playsinline', ''); a.setAttribute('webkit-playsinline', ''); a.preload = 'auto'; var p = a.play(); if (p && p.then) p.then(function () { rep('silent-loop-ok', ''); }, function (e) { rep('silent-loop-fail', String(e)); }); return a; })({0}, {1})", uri, report);
		}
		catch (e:Dynamic)
		{
			report("silent-loop-error", Std.string(e));
		}
	}

	/**
	 * A WAV (44 bájtos fejléc + 8 bites, előjel nélküli minták) közvetlen átalakítása AudioBuffer-ré. A `decodeAudioData`-t nem használjuk:
	 * a Safari nem minden 8 bites WAV-ot fogad el, és a hibát csendben nyelné le.
	 */
	static function toBuffer(wav:Bytes, ch:Int):Dynamic
	{
		var frames = Std.int((wav.length - 44) / ch);
		var buf:Dynamic = ctx.createBuffer(ch, frames, Audio.RATE);
		for (c in 0...ch)
		{
			var data:Dynamic = buf.getChannelData(c);
			for (i in 0...frames)
				data[i] = (wav.get(44 + i * ch + c) - 128) / 127;
		}
		return buf;
	}

	static function decode(name:String, wav:Bytes):Void
	{
		try
			buffers.set(name, toBuffer(wav, 1))
		catch (e:Dynamic)
			Perf.log("sfx", {what: "decode-fail", name: name, err: Std.string(e)});
	}

	static function decodeMusic(name:String, wav:Bytes, ch:Int):Void
	{
		try
			musicBuffers.set(name, toBuffer(wav, ch))
		catch (e:Dynamic)
			Perf.log("sfx", {what: "music-decode-fail", name: name, err: Std.string(e)});
	}

	/** Lejátssza az effektet; igaz, ha a Web Audio kezelte (akkor is, ha némítva van), hamis, ha a lime útját kell használni. */
	public static function play(name:String, volume:Float):Bool
	{
		if (ctx == null || ctx.state != "running")
			return false;
		var buf = buffers.get(name);
		if (buf == null)
			return false;
		if (volume <= 0 || active >= MAX_VOICES)
			return true;
		if (playLogged < 3)
		{
			playLogged++;
			Perf.log("sfx", {what: "play", name: name, vol: volume, state: ctx.state});
		}
		active++;
		js.Syntax.code("(function (c, b, v, done) {
			var s = c.createBufferSource(); s.buffer = b;
			var g = c.createGain(); g.gain.value = v;
			s.connect(g); g.connect(c.destination);
			s.onended = done; s.start(0);
		})({0}, {1}, {2}, {3})", ctx, buf, volume, function() active--);
		return true;
	}

	// --- Zene vezérlése --------------------------------------------------------------------------------------------------

	/** A kért zenei állapot: `name` dal (null = nincs zene), hangerő, szünet. Ha a hangkörnyezet még nem indult, az első érintéskor lép életbe. */
	public static function music(name:Null<String>, volume:Float, paused:Bool):Void
	{
		wName = name;
		wVol = volume;
		wPaused = paused;
		applyMusic();
	}

	/** A kért állapot érvényesítése (idempotens): dalváltás, szünet / folytatás, hangerő. */
	static function applyMusic():Void
	{
		if (ctx == null)
			return;
		try
		{
			// Dalváltás: a régi forrás leáll, az új a legelejéről indul
			if (wName != curName)
			{
				stopSource();
				curName = wName;
				offset = 0;
			}
			if (curName != null && curSrc == null && !wPaused && musicBuffers.exists(curName))
				startSource();
			else if (curSrc != null && wPaused)
			{
				// Szünet: megjegyezzük, hol tartott, és leállítjuk (a BufferSource nem szüneteltethető)
				var dur:Float = musicBuffers.get(curName).duration;
				offset = (offset + (ctx.currentTime - startedAt)) % dur;
				stopSource();
			}
			if (curGain != null)
				curGain.gain.value = wVol;
		}
		catch (e:Dynamic)
		{
			Perf.log("sfx", {what: "music-fail", err: Std.string(e)});
		}
	}

	static function startSource():Void
	{
		var r:Dynamic = js.Syntax.code("(function (c, b, v, off) {
			var s = c.createBufferSource(); s.buffer = b; s.loop = true;
			var g = c.createGain(); g.gain.value = v;
			s.connect(g); g.connect(c.destination);
			s.start(0, off);
			return {s: s, g: g};
		})({0}, {1}, {2}, {3})", ctx, musicBuffers.get(curName), wVol, offset);
		curSrc = r.s;
		curGain = r.g;
		startedAt = ctx.currentTime;
		Perf.log("sfx", {what: "music-start", name: curName, state: ctx.state, offset: offset});
	}

	static function stopSource():Void
	{
		if (curSrc != null)
		{
			try
				curSrc.stop()
			catch (e:Dynamic) {}
			curSrc = null;
			curGain = null;
		}
	}
}
#end
