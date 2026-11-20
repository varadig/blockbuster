package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Ranglista-ablak két lépésben:
 *  1. névbeírás (csak ha `score` meg van adva: játék vége után): 3 betűs arcade név. Billentyű: fel/le betűt vált, balra/jobbra lép, betű begépelhető,
 *     Enter beküld; kontroller: iránygombok + megerősítés; érintés/egér: a betűk fölötti ▲ / alatti ▼ jelre koppintás, OK / SKIP gomb.
 *  2. a lista: a legjobb 10 nehézségenként (balra/jobbra vagy a fejlécre koppintva vált), a frissen beküldött sor kiemelve.
 */
class LeaderboardSubState extends FlxSubState
{
	static inline var ROW_H:Int = 16;
	static inline var LIST_Y:Int = 62;

	var score:Int;
	var level:Int;
	/** Névbeírás fázis (különben lista). */
	var entering:Bool;
	var ready:Bool = false;

	// Névbeírás
	var letters:Array<Int> = [];
	var cursor:Int = 0;
	var sending:Bool = false;
	var failed:Bool = false;
	var letterTexts:Array<FlxText> = [];
	var upTexts:Array<FlxText> = [];
	var downTexts:Array<FlxText> = [];
	var okText:FlxText;
	var status:FlxText;

	// Lista
	var tab:Int = 1; // 0 EASY, 1 NORMAL, 2 HARD
	var header:FlxText;
	var rows:Array<Array<FlxText>> = [];
	var highlight:FlxSprite;
	var info:FlxText;
	var token:Int = 0;

	static var DIFFS:Array<String> = ["EASY", "NORMAL", "HARD"];

	/** `score` < 0: csak a lista (címképernyőről). */
	public function new(score:Int = -1, level:Int = 0)
	{
		super(0xff101020);
		this.score = score;
		this.level = level;
		entering = score >= 0 && Leaderboard.canSubmit();
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this);
		tab = Settings.difficulty;
		for (c in Leaderboard.savedName().split(""))
			letters.push(c.charCodeAt(0));
		if (entering)
			buildEntry();
		else
			buildList();
	}

	function text(x:Float, y:Float, w:Float, s:String, size:Int, color:FlxColor, align:flixel.text.FlxText.FlxTextAlign = CENTER):FlxText
	{
		var t = new FlxText(x, y, w, s, size);
		t.alignment = align;
		t.color = color;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		return t;
	}

	// --- 1. névbeírás ---------------------------------------------------------------------------------------------------

	function buildEntry():Void
	{
		text(0, 30, FlxG.width, "GAME OVER", 16, PixelArt.RED);
		text(0, 58, FlxG.width, 'SCORE  $score    (${Settings.difficultyName()})', 12, PixelArt.YELLOW);
		text(0, 88, FlxG.width, "ENTER YOUR NAME", 8, PixelArt.LIGHT_GRAY);
		for (i in 0...Leaderboard.NAME_LEN)
		{
			var x = FlxG.width / 2 - 66 + i * 44;
			upTexts.push(text(x, 104, 40, "^", 12, PixelArt.GRAY));
			letterTexts.push(text(x, 118, 40, "A", 24, PixelArt.WHITE));
			downTexts.push(text(x, 148, 40, "v", 12, PixelArt.GRAY));
		}
		okText = text(FlxG.width / 2 + 78, 124, 70, "OK", 16, PixelArt.GREEN);
		status = text(0, 190, FlxG.width, "", 8, PixelArt.CYAN);
		text(0, 244, FlxG.width, "UP / DOWN: letter   LEFT / RIGHT: position   ENTER: send", 8, PixelArt.GRAY);
		refreshEntry();
	}

	function refreshEntry():Void
	{
		for (i in 0...Leaderboard.NAME_LEN)
		{
			letterTexts[i].text = String.fromCharCode(letters[i]);
			letterTexts[i].color = (i == cursor) ? PixelArt.YELLOW : PixelArt.WHITE;
			upTexts[i].color = downTexts[i].color = (i == cursor) ? PixelArt.CYAN : PixelArt.GRAY;
		}
		okText.alpha = sending ? 0.4 : 1;
		// Kihagyni csak sikertelen küldés után lehet (hogy offline se akadjon el a játékos); egyébként nincs "vissza"
		status.text = sending ? "SENDING..." : (failed ? "COULD NOT SEND - ENTER: retry   ESC / TAP HERE: skip" : "");
		status.color = failed ? PixelArt.RED : PixelArt.CYAN;
	}

	function changeLetter(i:Int, d:Int):Void
	{
		var c = letters[i] - 65 + d;
		letters[i] = 65 + ((c % 26) + 26) % 26;
		Audio.play("tick");
		refreshEntry();
	}

	function submit():Void
	{
		if (sending)
			return;
		sending = true;
		failed = false;
		refreshEntry();
		var name = [for (c in letters) String.fromCharCode(c)].join("");
		Leaderboard.submit(name, score, level, ok ->
		{
			sending = false;
			if (ok)
			{
				Audio.play("powerup");
				entering = false;
				clearEntry();
				buildList();
			}
			else
			{
				failed = true;
				refreshEntry();
			}
		});
	}

	function clearEntry():Void
	{
		for (m in members.copy())
			if (m != null)
			{
				remove(m, true);
				m.destroy();
			}
		letterTexts = [];
		upTexts = [];
		downTexts = [];
	}

	/** Lenyomva tartott fel / le: az első lépés után késleltetéssel ismétel (gyorsan lehet görgetni a betűk között). */
	var holdDir:Int = 0;
	var holdTime:Float = 0;

	function updateEntry(elapsed:Float):Void
	{
		if (sending)
			return;
		var n = Leaderboard.NAME_LEN;

		// Pozíció váltása: balra / jobbra (nyilak vagy A / D, kontroller)
		if (FlxG.keys.anyJustPressed([LEFT, A]) || Pad.just(LEFT))
		{
			cursor = (cursor + n - 1) % n;
			Audio.play("blip");
			refreshEntry();
		}
		else if (FlxG.keys.anyJustPressed([RIGHT, D]) || Pad.just(RIGHT))
		{
			cursor = (cursor + 1) % n;
			Audio.play("blip");
			refreshEntry();
		}

		// A kijelölt betű váltása: fel / le (nyilak vagy W / S, kontroller); nyomva tartva ismétel
		var up = FlxG.keys.anyPressed([UP, W]) || Pad.held(UP);
		var down = FlxG.keys.anyPressed([DOWN, S]) || Pad.held(DOWN);
		var dir = up && !down ? 1 : (down && !up ? -1 : 0);
		if (dir == 0)
		{
			holdDir = 0;
			holdTime = 0;
		}
		else if (dir != holdDir)
		{
			holdDir = dir;
			holdTime = 0;
			changeLetter(cursor, dir);
		}
		else
		{
			var before = holdTime;
			holdTime += elapsed;
			// 0,35 mp után 0,08 mp-enként ismétel
			if (holdTime >= 0.35 && Math.floor((holdTime - 0.35) / 0.08) > Math.floor((before - 0.35) / 0.08) || (holdTime >= 0.35 && before < 0.35))
				changeLetter(cursor, dir);
		}

		// Beküldés: Enter / Space / megerősítés (nincs "vissza": a név beírása után a lista jön)
		if (FlxG.keys.anyJustPressed([ENTER, SPACE]) || Pad.just(CONFIRM))
			submit();
		else if (failed && (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK)))
		{
			close();
			return;
		}

		// Egér / érintés
		if (FlxG.mouse.justPressed)
		{
			var p = FlxG.mouse.getViewPosition(cameras != null && cameras.length > 0 ? cameras[0] : null);
			for (i in 0...n)
			{
				var x = letterTexts[i].x;
				if (p.x >= x && p.x < x + 40)
				{
					if (p.y >= 98 && p.y < 118)
					{
						cursor = i;
						changeLetter(i, 1);
					}
					else if (p.y >= 144 && p.y < 168)
					{
						cursor = i;
						changeLetter(i, -1);
					}
					else if (p.y >= 118 && p.y < 144)
					{
						cursor = i;
						refreshEntry();
					}
				}
			}
			if (p.x >= okText.x && p.x < okText.x + 70 && p.y >= 118 && p.y < 146)
				submit();
			else if (failed && p.y >= 184 && p.y < 204)
			{
				// Sikertelen küldés után a státuszsorra koppintva ki lehet hagyni
				close();
				p.put();
				return;
			}
			p.put();
		}
	}

	// --- 2. lista -------------------------------------------------------------------------------------------------------

	function buildList():Void
	{
		text(0, 12, FlxG.width, "LEADERBOARD", 16, PixelArt.YELLOW);
		header = text(0, 40, FlxG.width, "", 8, PixelArt.CYAN);
		highlight = new FlxSprite(110, LIST_Y, null);
		highlight.makeGraphic(260, ROW_H - 2, 0x40ffcd75);
		highlight.scrollFactor.set(0, 0);
		highlight.visible = false;
		add(highlight);
		rows = [];
		for (i in 0...Leaderboard.LIMIT)
		{
			var y = LIST_Y + i * ROW_H;
			rows.push([
				text(114, y, 30, "", 8, PixelArt.LIGHT_GRAY, LEFT),
				text(146, y, 50, "", 8, PixelArt.WHITE, LEFT),
				text(190, y, 90, "", 8, PixelArt.WHITE, RIGHT),
				text(290, y, 74, "", 8, PixelArt.GRAY, RIGHT)
			]);
		}
		info = text(0, 120, FlxG.width, "", 8, PixelArt.LIGHT_GRAY);
		text(0, 244, FlxG.width, "LEFT / RIGHT: difficulty   ESC / TAP: back", 8, PixelArt.GRAY);
		loadTab();
	}

	function loadTab():Void
	{
		var diff = DIFFS[tab];
		header.text = [for (i in 0...3) i == tab ? '[ ${DIFFS[i]} ]' : DIFFS[i]].join("     ");
		for (r in rows)
			for (t in r)
				t.text = "";
		highlight.visible = false;
		info.text = "LOADING...";
		var my = ++token;
		Leaderboard.fetch(diff, list ->
		{
			if (my != token || !exists)
				return; // közben másik fülre váltottak, vagy bezárták
			if (list == null)
			{
				info.text = "OFFLINE  -  could not load the leaderboard";
				return;
			}
			info.text = list.length == 0 ? "NO SCORES YET - BE THE FIRST!" : "";
			var found = false;
			for (i in 0...list.length)
			{
				var e = list[i];
				rows[i][0].text = '${i + 1}.';
				rows[i][1].text = e.name;
				rows[i][2].text = Std.string(e.score);
				rows[i][3].text = 'LV ${e.level + 1}';
				if (!found && diff == Settings.difficultyName() && e.name == Leaderboard.lastName && e.score == Leaderboard.lastScore)
				{
					found = true;
					highlight.y = LIST_Y + i * ROW_H - 1;
					highlight.visible = true;
					for (t in rows[i])
						t.color = PixelArt.YELLOW;
				}
			}
		});
	}

	function updateList():Void
	{
		if (FlxG.keys.anyJustPressed([LEFT, A]) || Pad.just(LEFT))
			switchTab(-1);
		else if (FlxG.keys.anyJustPressed([RIGHT, D]) || Pad.just(RIGHT))
			switchTab(1);
		else if (FlxG.keys.anyJustPressed([ESCAPE, ENTER, SPACE]) || Pad.just(BACK) || Pad.just(CONFIRM))
		{
			Audio.play("blip");
			close();
		}
		else if (FlxG.mouse.justPressed)
		{
			var p = FlxG.mouse.getViewPosition(cameras != null && cameras.length > 0 ? cameras[0] : null);
			// A fejlécre koppintva fület vált (bal / jobb harmad), máshová koppintva bezár
			if (p.y >= 34 && p.y < 56)
				switchTab(p.x < FlxG.width / 2 ? -1 : 1);
			else
			{
				Audio.play("blip");
				close();
			}
			p.put();
		}
	}

	function switchTab(d:Int):Void
	{
		tab = (tab + d + 3) % 3;
		Audio.play("blip");
		loadTab();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		FlxG.mouse.useSystemCursor = false;
		FlxG.mouse.visible = true;
		// Az első képkockában a megnyitó gombnyomást még nem vesszük figyelembe
		if (!ready)
		{
			ready = true;
			return;
		}
		if (entering)
			updateEntry(elapsed);
		else
			updateList();
	}
}
