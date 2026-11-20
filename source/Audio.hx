package;

import flixel.FlxG;
import flixel.sound.FlxSound;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.media.Sound;

/** Egy szintetizált hangréteg leírása. */
typedef Tone =
{
	dur:Float,
	wave:Int,
	f0:Float,
	/** Végfrekvencia (exponenciális csúszás f0-ról). */
	?f1:Float,
	/** Négyszögjel kitöltési tényezője (0..1). */
	?duty:Float,
	/** Arpeggio félhangokban; arpRate lépés/mp. */
	?arp:Array<Int>,
	?arpRate:Float,
	/** Az arpeggio az utolsó hangon megáll (nem ismétlődik). */
	?arpHold:Bool,
	?attack:Float,
	/** A lecsengés görbülete: (1-t)^decay. */
	?decay:Float,
	?vol:Float,
	/** Vibrato mélysége félhangban (6 Hz). */
	?vibrato:Float,
	/** Mintavétel-tartás: ennyi mintánként frissül a kimenet (durvább, "8 bites" hang). */
	?crush:Int,
	/** Késleltetés a hang elején (mp), több réteg időzítéséhez. */
	?delay:Float
}

/**
 * Amiga-stílusú hangok kódból: 8 bites, 22 kHz-es, szándékosan nem élsimított hullámformák,
 * enyhe aluláteresztő szűrővel (mint az A500 kimenete). Nincsenek hangfájlok.
 */
class Audio
{
	public static inline var RATE:Int = 22050;

	public static inline var SQUARE:Int = 0;
	public static inline var SAW:Int = 1;
	public static inline var TRI:Int = 2;
	public static inline var SINE:Int = 3;
	public static inline var NOISE:Int = 4;

	/** A zene alaphangereje; ezt szorozza a beállításokban megadott zenehangerő. */
	static inline var MUSIC_VOLUME:Float = 0.6;

	static var sounds = new Map<String, Sound>();
	/** A legutóbb legenerált WAV (a WebSfx regisztrációhoz). */
	static var lastWav:Bytes;
	static var musicSound:Sound;
	static var shieldSound:Sound;
	static var finalSound:Sound;
	/** Épp a végső főellenség zenéje szól. */
	static var finalPlaying:Bool = false;
	static var shieldMusic:FlxSound;
	static var initialized = false;

	/** Az összes hang legenerálása (egyszer, a nyitóképernyőn). */
	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;
		#if js
		WebSfx.init();
		#end

		// A némítást (M) a Settings kezeli és menti; a Flixel saját némító/hangerő gombjait kikapcsoljuk
		FlxG.sound.muteKeys = [];
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		Settings.load();

		add("shoot", [{dur: 0.09, wave: SQUARE, duty: 0.25, f0: 1500, f1: 320, decay: 1.4, vol: 0.45, crush: 2}]);
		add("spread", [
			{dur: 0.1, wave: SQUARE, duty: 0.5, f0: 1200, f1: 380, decay: 1.4, vol: 0.3, crush: 2},
			{dur: 0.1, wave: SQUARE, duty: 0.25, f0: 1260, f1: 400, decay: 1.4, vol: 0.3, crush: 2},
		]);
		add("heavy", [
			{dur: 0.22, wave: SAW, f0: 320, f1: 55, decay: 1.2, vol: 0.55, crush: 2},
			{dur: 0.12, wave: NOISE, f0: 3000, f1: 600, decay: 1.5, vol: 0.35},
		]);
		add("enemyshot", [{dur: 0.14, wave: SQUARE, duty: 0.5, f0: 520, f1: 260, decay: 1.2, vol: 0.3, crush: 3}]);
		add("bombdrop", [{dur: 0.3, wave: TRI, f0: 1400, f1: 500, decay: 0.6, vol: 0.25}]);
		add("bomb", [
			{dur: 0.55, wave: NOISE, f0: 2600, f1: 120, decay: 1.1, vol: 0.85, crush: 3},
			{dur: 0.35, wave: SINE, f0: 110, f1: 30, decay: 1, vol: 0.8},
		]);
		add("stomp", [
			{dur: 0.16, wave: SQUARE, duty: 0.5, f0: 330, f1: 990, decay: 1, vol: 0.4},
			{dur: 0.08, wave: NOISE, f0: 1200, f1: 400, decay: 1.4, vol: 0.3},
		]);
		add("warning", [{dur: 1.0, wave: SQUARE, duty: 0.5, f0: 740, arp: [0, -5], arpRate: 4, decay: 0.3, vol: 0.3}]);
		add("flame", [{dur: 0.16, wave: NOISE, f0: 1600, f1: 700, attack: 0.03, decay: 0.8, vol: 0.4, crush: 2}]);
		add("laser", [
			{dur: 0.13, wave: SQUARE, duty: 0.125, f0: 2600, f1: 900, decay: 1.2, vol: 0.32},
			{dur: 0.13, wave: SAW, f0: 1300, f1: 450, decay: 1.2, vol: 0.25},
		]);
		add("hit", [
			{dur: 0.05, wave: NOISE, f0: 7000, f1: 2500, decay: 1.2, vol: 0.4},
			{dur: 0.05, wave: SQUARE, f0: 260, f1: 140, decay: 1, vol: 0.25},
		]);
		add("explode", [
			{dur: 0.4, wave: NOISE, f0: 4500, f1: 250, decay: 1.3, vol: 0.75, crush: 2},
			{dur: 0.25, wave: SINE, f0: 140, f1: 38, decay: 1.2, vol: 0.7},
		]);
		add("thud", [
			{dur: 0.14, wave: SINE, f0: 95, f1: 40, decay: 1.3, vol: 0.6},
			{dur: 0.08, wave: NOISE, f0: 900, f1: 250, decay: 1.5, vol: 0.3},
		]);
		add("reward", [{dur: 0.32, wave: SQUARE, duty: 0.25, f0: 880, arp: [0, 4, 7, 12, 16, 19, 24], arpRate: 28, arpHold: true, decay: 0.8, vol: 0.35}]);
		add("powerup", [
			{dur: 0.5, wave: SQUARE, duty: 0.25, f0: 523, arp: [0, 4, 7, 12, 7, 12, 16, 19, 24], arpRate: 20, arpHold: true, decay: 0.7, vol: 0.4, vibrato: 0.15},
			{dur: 0.5, wave: TRI, f0: 261, arp: [0, 7, 12, 19], arpRate: 10, arpHold: true, decay: 0.8, vol: 0.3},
		]);
		add("heal", [{dur: 0.55, wave: TRI, f0: 440, arp: [0, 5, 9, 12, 17, 21, 24], arpRate: 15, arpHold: true, decay: 0.6, vol: 0.55, vibrato: 0.2}]);
		add("coin", [{dur: 0.38, wave: SQUARE, duty: 0.5, f0: 988, arp: [0, 5], arpRate: 14, arpHold: true, decay: 1.1, vol: 0.35}]);
		add("blip", [{dur: 0.035, wave: SQUARE, duty: 0.5, f0: 1760, decay: 1, vol: 0.18}]);
		add("jump", [{dur: 0.14, wave: SQUARE, duty: 0.5, f0: 260, f1: 720, decay: 1.2, vol: 0.28, crush: 2}]);
		add("land", [{dur: 0.06, wave: NOISE, f0: 1400, f1: 300, decay: 1.5, vol: 0.22}]);
		add("hurt", [
			{dur: 0.32, wave: SAW, f0: 520, f1: 70, decay: 1.1, vol: 0.55, crush: 3},
			{dur: 0.16, wave: NOISE, f0: 2200, f1: 300, decay: 1.4, vol: 0.4},
		]);
		add("fall", [{dur: 0.55, wave: SQUARE, duty: 0.5, f0: 900, f1: 110, decay: 0.8, vol: 0.35, vibrato: 0.4}]);
		add("alarm", [{dur: 0.09, wave: SQUARE, duty: 0.5, f0: 1047, decay: 0.6, vol: 0.22}]);
		add("powerdown", [{dur: 0.2, wave: SQUARE, duty: 0.25, f0: 440, arp: [12, 7, 0], arpRate: 15, arpHold: true, decay: 1, vol: 0.3}]);
		add("slowmo", [
			{dur: 0.7, wave: SAW, f0: 700, f1: 90, decay: 0.9, vol: 0.35, vibrato: 0.6, crush: 2},
			{dur: 0.7, wave: TRI, f0: 350, f1: 45, decay: 0.9, vol: 0.35},
		]);
		add("shield", [{dur: 0.55, wave: TRI, f0: 660, arp: [0, 7, 12, 19, 24, 19, 12, 7], arpRate: 40, decay: 0.8, vol: 0.45, vibrato: 0.2}]);
		add("start", [
			{dur: 0.45, wave: SQUARE, duty: 0.5, f0: 523, arp: [0, 4, 7, 12], arpRate: 12, arpHold: true, decay: 0.7, vol: 0.4},
			{dur: 0.45, wave: SQUARE, duty: 0.25, f0: 262, arp: [0, 4, 7, 12], arpRate: 12, arpHold: true, decay: 0.7, vol: 0.25},
		]);
		add("gameover", [
			{dur: 1.5, wave: SQUARE, duty: 0.5, f0: 440, arp: [0, -2, -4, -5, -7, -12], arpRate: 5, arpHold: true, decay: 0.6, vol: 0.4, vibrato: 0.25},
			{dur: 1.5, wave: TRI, f0: 220, arp: [0, -2, -4, -5, -7, -12], arpRate: 5, arpHold: true, decay: 0.6, vol: 0.4},
		]);
		add("clear", [
			{dur: 1.1, wave: SQUARE, duty: 0.5, f0: 523, arp: [0, 4, 7, 12, 7, 12, 16, 19, 24], arpRate: 9, arpHold: true, decay: 0.5, vol: 0.4, vibrato: 0.2},
			{dur: 1.1, wave: TRI, f0: 131, arp: [0, 7, 12, 19, 24], arpRate: 5, arpHold: true, decay: 0.5, vol: 0.45},
		]);

		add("deathray", [
			{dur: 0.45, wave: SAW, f0: 90, f1: 40, decay: 0.9, vol: 0.6, crush: 2},
			{dur: 0.3, wave: SQUARE, duty: 0.125, f0: 3200, f1: 400, decay: 1.1, vol: 0.3},
			{dur: 0.4, wave: NOISE, f0: 5000, f1: 800, decay: 1.2, vol: 0.3},
		]);
		add("nuke", [
			{dur: 1.4, wave: NOISE, f0: 3000, f1: 60, decay: 0.8, vol: 0.9, crush: 3},
			{dur: 1.0, wave: SINE, f0: 90, f1: 22, decay: 0.7, vol: 0.9},
			{dur: 0.5, wave: SQUARE, duty: 0.5, f0: 1800, f1: 200, decay: 1, vol: 0.25},
		]);
		add("trippy", [
			{dur: 0.9, wave: TRI, f0: 330, arp: [0, 3, 7, 11, 14, 11, 7, 3], arpRate: 14, decay: 0.6, vol: 0.45, vibrato: 0.9},
			{dur: 0.9, wave: SQUARE, duty: 0.25, f0: 166, f1: 120, decay: 0.7, vol: 0.2, vibrato: 1.2},
		]);
		add("tick", [{dur: 0.05, wave: SQUARE, duty: 0.25, f0: 1800, decay: 1.2, vol: 0.3}]);

		musicSound = toSound(Music.render(), 2, 0.55);
		#if js
		WebSfx.registerMusic("main", lastWav, 2);
		#end
		shieldSound = toSound(Music.renderShield(), 2, 0.6);
		#if js
		WebSfx.registerMusic("shield", lastWav, 2);
		#end
		finalSound = toSound(Music.renderFinal(), 2, 0.58);
		#if js
		WebSfx.registerMusic("final", lastWav, 2);
		// A hangerő / némítás változását minden képkockában követjük (a zene a Web Audio-n szól)
		FlxG.signals.postUpdate.add(syncWebMusic);
		#end
	}

	#if js
	/** Böngészőben a zene a Web Audio-n szól (WebSfx): a kért dal, a sérthetetlenség-zene és a szünet állapota. */
	static var wantMusic:Null<String> = null;
	static var shieldOn:Bool = false;
	static var musicPaused:Bool = false;

	static function syncWebMusic():Void
	{
		var name = shieldOn ? "shield" : wantMusic;
		var vol = MUSIC_VOLUME * Settings.musicVolume * (FlxG.sound.muted ? 0 : FlxG.sound.volume);
		WebSfx.music(Perf.noMusic ? null : name, vol, musicPaused);
	}
	#end

	/** Sérthetetlenség: a fő zene szünetel, helyette a gyors "csillag" dal szól. */
	public static function startShieldMusic():Void
	{
		if (shieldSound == null)
			return;
		#if js
		shieldOn = true;
		syncWebMusic();
		return;
		#end
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.pause();
		if (shieldMusic != null && shieldMusic.exists)
			shieldMusic.stop();
		shieldMusic = FlxG.sound.create(shieldSound);
		shieldMusic.looped = true;
		shieldMusic.volume = MUSIC_VOLUME * Settings.musicVolume;
		shieldMusic.play(true);
	}

	/** A sérthetetlenség vége: vissza a fő zenére. */
	public static function stopShieldMusic(resumeMain:Bool = true):Void
	{
		#if js
		shieldOn = false;
		syncWebMusic();
		return;
		#end
		if (shieldMusic != null && shieldMusic.exists)
			shieldMusic.stop();
		shieldMusic = null;
		if (resumeMain && FlxG.sound.music != null)
			FlxG.sound.music.resume();
	}

	/** Szünetmenü: minden zene megáll (és folytatható). */
	public static function pauseMusic():Void
	{
		#if js
		musicPaused = true;
		syncWebMusic();
		return;
		#end
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();
		if (shieldMusic != null && shieldMusic.exists)
			shieldMusic.pause();
	}

	public static function resumeMusic():Void
	{
		#if js
		musicPaused = false;
		syncWebMusic();
		return;
		#end
		if (shieldMusic != null && shieldMusic.exists)
			shieldMusic.resume();
		else if (FlxG.sound.music != null)
			FlxG.sound.music.resume();
	}

	public static function play(name:String, volume:Float = 1):Void
	{
		var s = sounds.get(name);
		if (Perf.noSfx)
			return; // ?nosfx=1: hangeffektek nélkül (lassulás-kereséshez)
		if (s != null && Settings.sfxVolume > 0)
		{
			var t0 = Perf.mark();
			#if js
			if (WebSfx.play(name, FlxG.sound.muted ? 0 : volume * Settings.sfxVolume * FlxG.sound.volume))
			{
				Perf.audio(t0);
				return;
			}
			#end
			FlxG.sound.play(s, volume * Settings.sfxVolume);
			Perf.audio(t0);
		}
	}

	/** A zene hangerejének frissítése a beállítás szerint (a menüből hívva). */
	public static function updateMusicVolume():Void
	{
		#if js
		syncWebMusic();
		return;
		#end
		if (FlxG.sound.music != null)
			FlxG.sound.music.volume = MUSIC_VOLUME * Settings.musicVolume;
		if (shieldMusic != null && shieldMusic.exists)
			shieldMusic.volume = MUSIC_VOLUME * Settings.musicVolume;
	}

	/** A háttérzene indítása (ha már szól, nem indul újra). */
	public static function playMusic():Void
	{
		if (musicSound == null || Perf.noMusic)
			return;
		#if js
		wantMusic = finalPlaying ? "final" : "main";
		syncWebMusic();
		return;
		#end
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			return;
		FlxG.sound.playMusic(musicSound, null, MUSIC_VOLUME * Settings.musicVolume, true);
	}

	/** A végső főellenség harcának zenéje (a fő zene helyett; ha már szól, nem indul újra). */
	public static function playFinalMusic():Void
	{
		if (finalSound == null || finalPlaying)
			return;
		finalPlaying = true;
		#if js
		wantMusic = "final";
		syncWebMusic();
		return;
		#end
		FlxG.sound.playMusic(finalSound, null, MUSIC_VOLUME * Settings.musicVolume, true);
	}

	/** Ha a végső főellenség zenéje szólt, vissza a fő zenére (pályaváltáskor, a főellenség legyőzésekor). */
	public static function restoreMainMusic():Void
	{
		if (!finalPlaying)
			return;
		finalPlaying = false;
		#if js
		wantMusic = "main";
		syncWebMusic();
		return;
		#end
		if (musicSound != null)
			FlxG.sound.playMusic(musicSound, null, MUSIC_VOLUME * Settings.musicVolume, true);
	}

	public static function stopMusic():Void
	{
		finalPlaying = false;
		#if js
		wantMusic = null;
		shieldOn = false;
		musicPaused = false;
		syncWebMusic();
		#end
		stopShieldMusic(false);
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
	}

	// --- Szintézis ---------------------------------------------------------------

	static function add(name:String, layers:Array<Tone>):Void
	{
		var mix:Array<Float> = [];
		for (t in layers)
		{
			var start = Std.int((t.delay != null ? t.delay : 0) * RATE);
			mixInto(mix, tone(t), start, 1);
		}
		sounds.set(name, toSound(mix, 1, 0.8));
		#if js
		WebSfx.register(name, lastWav); // böngészőben az effektek a Web Audio-n szólnak (a lime útja iPhone-on 100+ ms hívásonként)
		#end
	}

	/** `src`-t hozzáadja `dst`-hez a `start` mintától (szükség esetén megnyújtja). */
	public static function mixInto(dst:Array<Float>, src:Array<Float>, start:Int, gain:Float):Void
	{
		var end = start + src.length;
		while (dst.length < end)
			dst.push(0);
		for (i in 0...src.length)
			dst[start + i] += src[i] * gain;
	}

	/** Egy hullámforma-érték a fázisból (0..1). Zajnál a mintavett érték megy tovább. */
	public static inline function osc(wave:Int, phase:Float, duty:Float, noise:Float):Float
	{
		return switch (wave)
		{
			case SQUARE: phase < duty ? 1.0 : -1.0;
			case SAW: phase * 2 - 1;
			case TRI: 1 - 4 * Math.abs(phase - 0.5);
			case SINE: Math.sin(phase * Math.PI * 2);
			default: noise;
		}
	}

	/** Egy hangréteg kiszámolása mono mintákba. */
	public static function tone(t:Tone):Array<Float>
	{
		var n = Std.int(t.dur * RATE);
		var f1 = t.f1 != null ? t.f1 : t.f0;
		var duty = t.duty != null ? t.duty : 0.5;
		var attack = t.attack != null ? t.attack : 0.003;
		var decay = t.decay != null ? t.decay : 1.0;
		var vol = t.vol != null ? t.vol : 1.0;
		var crush = t.crush != null ? t.crush : 1;
		var vib = t.vibrato != null ? t.vibrato : 0.0;
		var arpRate = t.arpRate != null ? t.arpRate : 50.0;

		var out:Array<Float> = [];
		var phase = 0.0, noise = 0.0, held = 0.0;
		for (i in 0...n)
		{
			var time = i / RATE;
			var p = i / n;
			var f = t.f0 * Math.pow(f1 / t.f0, p);
			if (t.arp != null)
			{
				var idx = Std.int(time * arpRate);
				idx = t.arpHold == true ? Std.int(Math.min(idx, t.arp.length - 1)) : idx % t.arp.length;
				f *= Math.pow(2, t.arp[idx] / 12);
			}
			if (vib > 0)
				f *= Math.pow(2, vib * Math.sin(time * Math.PI * 12) / 12);

			phase += f / RATE;
			if (phase >= 1)
			{
				phase -= Math.ffloor(phase);
				noise = Math.random() * 2 - 1; // "pitched" zaj: periódusonként új érték, mint egy zajminta
			}
			var env = (time < attack ? time / attack : 1) * Math.pow(1 - p, decay);
			if (i % crush == 0)
				held = osc(t.wave, phase, duty, noise) * env * vol;
			out.push(held);
		}
		return out;
	}

	/**
	 * 8 bites WAV a mintákból (interleaved, ha sztereó), egypólusú aluláteresztő szűrővel.
	 * @param lp a szűrő együtthatója (1 = nincs szűrés, kisebb = tompább)
	 */
	public static function toSound(samples:Array<Float>, channels:Int, lp:Float):Sound
	{
		var dataLen = samples.length;
		var b = Bytes.alloc(44 + dataLen);
		function str(pos:Int, s:String)
			for (i in 0...s.length)
				b.set(pos + i, s.charCodeAt(i));
		str(0, "RIFF");
		b.setInt32(4, 36 + dataLen);
		str(8, "WAVE");
		str(12, "fmt ");
		b.setInt32(16, 16);
		b.setUInt16(20, 1); // PCM
		b.setUInt16(22, channels);
		b.setInt32(24, RATE);
		b.setInt32(28, RATE * channels); // bájt/mp (8 bit)
		b.setUInt16(32, channels); // blokkméret
		b.setUInt16(34, 8); // bit/minta
		str(36, "data");
		b.setInt32(40, dataLen);

		var state = [for (c in 0...channels) 0.0];
		for (i in 0...dataLen)
		{
			var c = i % channels;
			state[c] += (samples[i] - state[c]) * lp;
			var v = Math.max(-1, Math.min(1, state[c]));
			b.set(44 + i, Std.int(Math.round(v * 127)) + 128); // 8 bites előjel nélküli
		}
		lastWav = b;
		return Sound.fromAudioBuffer(AudioBuffer.fromBytes(b));
	}
}
