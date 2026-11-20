package;

/** Egy 4 ütemes minta: ütemenkénti akkord, dallam (ütemenként 16 token; null = nincs dallam), dob-változat. */
typedef Pattern =
{
	chords:Array<String>,
	lead:Array<String>,
	drums:String,
	/** 16-od hi-hat a 8-adok helyett (pörgősebb). */
	?hats16:Bool
}

/**
 * Tracker-stílusú háttérzene (mint egy 4 csatornás Amiga MOD), kódból renderelve.
 * Csatornák az Amiga-féle sztereó elosztással: 1 dallam és 4 dob balra, 2 basszus és 3 arpeggio jobbra.
 * A dal: a-moll, 128 BPM, 16 sor/ütem, 4 ütem/minta.
 */
class Music
{
	static inline var BPM:Float = 128;
	static inline var SHIELD_BPM:Float = 168;
	static inline var ROWS_PER_BAR:Int = 16;
	/** Egy tracker-"tick" (50 Hz, PAL): az arpeggio ilyen ütemben vált hangot. */
	static inline var TICK:Float = 1 / 50;

	/** Minták: 4 ütem akkordja, dallam (ütemenként 16 token: hang, '.' kitartás, '-' csend), dob-változat. */
	static final PATTERNS:Array<Pattern> = [
		// 0: intro – nincs dallam, a dob fokozatosan indul
		{chords: ["Am", "F", "C", "G"], lead: null, drums: "intro"},
		// 1: A téma
		{
			chords: ["Am", "F", "C", "G"],
			lead: [
				"E5 . . . A5 . G5 . E5 . . . D5 . C5 .",
				"C5 . . . F5 . E5 . C5 . . . A4 . C5 .",
				"G4 . . . C5 . D5 . E5 . . . G5 . E5 .",
				"D5 . . . B4 . . . G4 . A4 . B4 . D5 .",
			],
			drums: "main"
		},
		// 2: B téma – magasabban
		{
			chords: ["Am", "F", "C", "G"],
			lead: [
				"A5 . . . . . E5 . A5 . B5 . C6 . B5 .",
				"A5 . . . . . F5 . A5 . C6 . A5 . F5 .",
				"G5 . . . . . E5 . G5 . C6 . E6 . D6 .",
				"B5 . . . . . G5 . D6 . . . B5 . G5 .",
			],
			drums: "main",
			hats16: true
		},
		// 3: híd – d-moll, a-moll, E-dúr (feszültség a visszatérés előtt)
		{
			chords: ["Dm", "Am", "E", "E"],
			lead: [
				"F5 . . . E5 . D5 . A4 . . . D5 . F5 .",
				"E5 . . . C5 . A4 . E5 . . . A5 . G5 .",
				"G#5 . . . . . E5 . B4 . . . E5 . G#5 .",
				"B5 . . . A5 . G#5 . F#5 . E5 . D5 . B4 .",
			],
			drums: "main"
		},
	];

	static final ORDER = [0, 1, 2, 3, 1, 2];

	/** Sérthetetlenség alatti gyors, dúr "csillag" dal: futó arpeggio-dallam, egy rövid ismétlődő minta. */
	static final SHIELD_PATTERNS:Array<Pattern> = [
		{
			chords: ["C", "F", "C", "G"],
			lead: [
				"C5 . E5 . G5 . E5 . C5 . E5 . G5 . C6 .",
				"F5 . A5 . C6 . A5 . F5 . A5 . C6 . F6 .",
				"E5 . G5 . C6 . G5 . E5 . G5 . C6 . E6 .",
				"G5 . B5 . D6 . B5 . G5 . B5 . D6 . G6 .",
			],
			drums: "main",
			hats16: true
		},
	];

	/** A végső főellenség témája: sötétebb, gyorsabb (156 BPM), e-moll hangulat, tolakodó 16-od hi-hattel. */
	static final FINAL_PATTERNS:Array<Pattern> = [
		{chords: ["Em", "Em", "C", "B"], lead: null, drums: "intro"},
		{
			chords: ["Em", "C", "Am", "B"],
			lead: [
				"E5 . E5 . G5 . E5 . B5 . A5 . G5 . F#5 .",
				"E5 . E5 . G5 . E5 . C6 . B5 . G5 . E5 .",
				"C5 . C5 . E5 . C5 . A5 . G5 . E5 . C5 .",
				"D#5 . F#5 . B5 . A5 . F#5 . D#5 . B4 . .",
			],
			drums: "main",
			hats16: true
		},
		{
			chords: ["Em", "C", "D", "B"],
			lead: [
				"B5 . . B5 . . B5 . C6 . B5 . G5 . E5 .",
				"G5 . . G5 . . G5 . A5 . G5 . E5 . C5 .",
				"A5 . . A5 . . A5 . B5 . A5 . F#5 . D5 .",
				"F#5 . A5 . B5 . D#6 . E6 . . . . . . .",
			],
			drums: "main",
			hats16: true
		},
	];

	static final FINAL_BPM:Float = 156;

	/** A végső főellenség zenéje. */
	public static function renderFinal():Array<Float>
	{
		return renderSong(FINAL_PATTERNS, [0, 1, 2, 1, 2], FINAL_BPM);
	}
	/** Dobminták ütemenként (x = ütés); a "main" utolsó ütemében pergő-felvezetés. */
	static final KICK = "x.......x.x.....";
	static final SNARE = "....x.......x...";
	static final SNARE_FILL = "....x.......x.xx";
	static final HAT = "..x...x...x...x.";
	static final HAT_16 = "x.x.x.x.x.x.x.x.";

	/** A teljes dal renderelése interleaved sztereó mintákba. */
	public static function render():Array<Float>
	{
		return renderSong(PATTERNS, ORDER, BPM);
	}

	public static function renderShield():Array<Float>
	{
		return renderSong(SHIELD_PATTERNS, [0, 0], SHIELD_BPM);
	}

	static function renderSong(patterns:Array<Pattern>, order:Array<Int>, bpm:Float):Array<Float>
	{
		var rate = Audio.RATE;
		var rowLen = 60 / bpm / 4 * rate; // minta/sor
		var totalRows = order.length * 4 * ROWS_PER_BAR;
		var n = Std.int(Math.ceil(totalRows * rowLen));
		var left = [for (i in 0...n) 0.0];
		var right = [for (i in 0...n) 0.0];

		// Dobminták (egyszer kiszámolva, mint a MOD sample-ök)
		var kick = Audio.tone({dur: 0.2, wave: Audio.SINE, f0: 170, f1: 42, decay: 1.5, vol: 1});
		Audio.mixInto(kick, Audio.tone({dur: 0.012, wave: Audio.NOISE, f0: 8000, decay: 1, vol: 0.5}), 0, 1);
		var snare = Audio.tone({dur: 0.17, wave: Audio.NOISE, f0: 6000, f1: 1800, decay: 1.6, vol: 0.8});
		Audio.mixInto(snare, Audio.tone({dur: 0.08, wave: Audio.TRI, f0: 230, f1: 150, decay: 1.2, vol: 0.6}), 0, 1);
		var hat = Audio.tone({dur: 0.04, wave: Audio.NOISE, f0: 10000, decay: 2, vol: 0.6});

		// Amiga-sztereó: bal csatornák 75% balra, jobbak 75% jobbra (a teljes szétválasztás fejhallgatón fárasztó)
		function put(src:Array<Float>, start:Int, gain:Float, isLeft:Bool)
		{
			var gl = gain * (isLeft ? 0.75 : 0.25);
			var gr = gain * (isLeft ? 0.25 : 0.75);
			for (i in 0...src.length)
			{
				var j = start + i;
				if (j >= n)
					break;
				left[j] += src[i] * gl;
				right[j] += src[i] * gr;
			}
		}

		var row = 0;
		for (pi in order)
		{
			var pat = patterns[pi];
			for (bar in 0...4)
			{
				var chord = parseChord(pat.chords[bar]);
				var barStart = row + bar * ROWS_PER_BAR;

				// --- 4. csatorna: dob ---
				var intro = pat.drums == "intro";
				var snareLine = (!intro && bar == 3) ? SNARE_FILL : SNARE;
				var hatLine = pat.hats16 == true ? HAT_16 : HAT;
				for (r in 0...ROWS_PER_BAR)
				{
					var s = Std.int((barStart + r) * rowLen);
					if (KICK.charAt(r) == "x")
						put(kick, s, 0.75, true);
					if (snareLine.charAt(r) == "x" && (!intro || bar >= 2))
						put(snare, s, 0.5, true);
					if (hatLine.charAt(r) == "x")
						put(hat, s, 0.22, true);
				}

				// --- 2. csatorna: basszus, nyolcadok gyök/oktáv váltakozva ---
				var bassRoot = chord.root;
				while (bassRoot > 47)
					bassRoot -= 12;
				while (bassRoot < 36)
					bassRoot += 12;
				var r = 0;
				while (r < ROWS_PER_BAR)
				{
					var midi = bassRoot + ((r % 4 == 2) ? 12 : 0);
					var note = bass(freq(midi), Std.int(rowLen * 2));
					put(note, Std.int((barStart + r) * rowLen), 0.42, false);
					r += 2;
				}

				// --- 3. csatorna: klasszikus tracker-arpeggio (akkordhangok tickenként), negyedenként újraütve ---
				var arpRoot = chord.root;
				while (arpRoot < 57)
					arpRoot += 12;
				while (arpRoot > 68)
					arpRoot -= 12;
				var offsets = [0, chord.minor ? 3 : 4, 7];
				var beat = 0;
				while (beat < ROWS_PER_BAR)
				{
					var note = arpeggio(arpRoot, offsets, Std.int(rowLen * 4));
					put(note, Std.int((barStart + beat) * rowLen), 0.16, false);
					beat += 4;
				}

				// --- 1. csatorna: dallam ---
				if (pat.lead != null)
				{
					var tokens = pat.lead[bar].split(" ");
					var t = 0;
					while (t < tokens.length)
					{
						var tok = tokens[t];
						if (tok == "." || tok == "-")
						{
							t++;
							continue;
						}
						// Hossz: a hangot követő '.' tokenek száma + 1
						var len = 1;
						while (t + len < tokens.length && tokens[t + len] == ".")
							len++;
						var note = lead(freq(noteToMidi(tok)), Std.int(rowLen * len));
						put(note, Std.int((barStart + t) * rowLen), 0.32, true);
						t += len;
					}
				}
			}
			row += 4 * ROWS_PER_BAR;
		}

		// Normalizálás és összefésülés (interleaved sztereó)
		var peak = 0.0;
		for (i in 0...n)
			peak = Math.max(peak, Math.max(Math.abs(left[i]), Math.abs(right[i])));
		var g = peak > 0 ? 0.92 / peak : 1;
		var out:Array<Float> = [];
		for (i in 0...n)
		{
			out.push(left[i] * g);
			out.push(right[i] * g);
		}
		return out;
	}

	// --- Hangszerek -----------------------------------------------------------------

	/** Dallam: 25%-os négyszög, késleltetett vibratóval, kitartással és rövid elengedéssel. */
	static function lead(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var phase = 0.0;
		var release = Std.int(0.03 * rate);
		for (i in 0...len)
		{
			var t = i / rate;
			var vib = t > 0.15 ? Math.sin(t * Math.PI * 11) * 0.25 : 0;
			phase += f * Math.pow(2, vib / 12) / rate;
			phase -= Math.ffloor(phase);
			var env = 0.65 + 0.35 * Math.exp(-t * 10);
			if (i > len - release)
				env *= (len - i) / release;
			out.push(Audio.osc(Audio.SQUARE, phase, 0.25, 0) * env);
		}
		return out;
	}

	/** Basszus: fűrész + négyszög keverék, pengetett (gyorsan lecsengő) burkoló. */
	static function bass(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var phase = 0.0;
		var release = Std.int(0.015 * rate);
		for (i in 0...len)
		{
			var t = i / rate;
			phase += f / rate;
			phase -= Math.ffloor(phase);
			var v = Audio.osc(Audio.SAW, phase, 0.5, 0) * 0.6 + Audio.osc(Audio.SQUARE, phase, 0.5, 0) * 0.4;
			var env = 0.35 + 0.65 * Math.exp(-t * 9);
			if (i > len - release)
				env *= (len - i) / release;
			out.push(v * env);
		}
		return out;
	}

	/** Arpeggio: az akkordhangok tickenként (50 Hz) váltakoznak, lecsengő hangerővel. */
	static function arpeggio(root:Int, offsets:Array<Int>, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var phase = 0.0;
		for (i in 0...len)
		{
			var t = i / rate;
			var f = freq(root + offsets[Std.int(t / TICK) % offsets.length]);
			phase += f / rate;
			phase -= Math.ffloor(phase);
			var env = Math.exp(-t * 3.5) * Math.min(1, (len - i) / (0.01 * rate));
			out.push(Audio.osc(Audio.SQUARE, phase, 0.5, 0) * env);
		}
		return out;
	}

	// --- Hangmagasság ---------------------------------------------------------------

	static inline function freq(midi:Float):Float
	{
		return 440 * Math.pow(2, (midi - 69) / 12);
	}

	static final NOTE_INDEX = ["C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11];

	/** "G#5" -> MIDI hangszám. */
	static function noteToMidi(s:String):Int
	{
		var n = NOTE_INDEX.get(s.charAt(0));
		var i = 1;
		if (s.charAt(1) == "#")
		{
			n++;
			i++;
		}
		var octave = Std.parseInt(s.substr(i));
		return (octave + 1) * 12 + n;
	}

	/** "Am", "F", "Dm", "E" -> gyökhang (3. oktáv) és moll-e. */
	static function parseChord(s:String):{root:Int, minor:Bool}
	{
		var minor = s.length > 1 && s.charAt(s.length - 1) == "m";
		var name = minor ? s.substr(0, s.length - 1) : s;
		return {root: noteToMidi(name + "3"), minor: minor};
	}
}
