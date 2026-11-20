package;

import Themes.Theme;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;

/**
 * Háttér: képernyőhöz rögzített égbolt, 1-3 hold (változó fázissal), élő égi események (hullócsillagok, a hold körül köröző
 * űrhajó, csészealj, műhold, üstökös; pályánként más összeállításban), két parallax réteg (hegyek, domb/fa sziluett) és a téma
 * időjárás-részecskéi. A színeket a `Themes.current` adja (lásd Themes.hx).
 * Minden parallax réteg két egymás mellé tett példány, amit a kamera görgetésével együtt léptetünk.
 */
class Backdrop extends FlxGroup
{
	/** Pályánként (8-asával ismétlődve) a holdak száma és az égi események bitmaszkja. */
	static final MOON_COUNT:Array<Int> = [1, 2, 1, 3, 2, 1, 3, 2];
	static inline var EV_ORBIT:Int = 1; // kis űrhajó köröz a hold körül
	static inline var EV_UFO:Int = 2; // csészealj átrepül
	static inline var EV_SAT:Int = 4; // műhold halad át
	static inline var EV_COMET:Int = 8; // üstökös húz el
	static final EVENTS:Array<Int> = [EV_ORBIT, EV_SAT, EV_UFO, EV_ORBIT | EV_SAT, EV_SAT | EV_COMET, EV_ORBIT | EV_UFO, EV_COMET, EV_ORBIT];

	var layers:Array<{sprites:Array<FlxSprite>, factor:Float}> = [];
	var parts:Array<{s:FlxSprite, vx:Float, vy:Float, phase:Float, sway:Float}> = [];
	var theme:Theme;
	var time:Float = 0;

	var moons:Array<{s:FlxSprite, r:Int, vx:Float, baseY:Float, phase:Float}> = [];
	var events:Int = 0;
	var rnd:FlxRandom;

	// Hullócsillagok: kis készlet újrahasznosítva; a sorban várakozók (késleltetés mp) a meteoreső előtti csoportos hullásnak
	var streaks:Array<{s:FlxSprite, life:Float, max:Float}> = [];
	var pending:Array<Float> = [];
	var starT:Float = 5;

	var ship:FlxSprite;
	var orbitMoon:Int = 0;
	var orbitA:Float = 0;
	var ufo:FlxSprite;
	var ufoT:Float = 10;
	var sat:FlxSprite;
	var satT:Float = 8;
	var comet:FlxSprite;
	var cometT:Float = 18;

	/**
	 * @param moonX, moonY ha meg van adva: egyetlen, telihold a megadott közepű helyen (cím- és karakterválasztó képernyő)
	 * @param level a pálya sorszáma (0-tól): ez dönt a holdak számáról, fázisáról és az égi eseményekről
	 */
	public function new(moonX:Float = -1, moonY:Float = -1, level:Int = 0)
	{
		super();
		theme = Themes.current;
		rnd = new FlxRandom(level * 7919 + 13);
		var sky = new FlxSprite(0, 0, PixelArt.sky(FlxG.width, FlxG.height));
		sky.scrollFactor.set(0, 0);
		add(sky);

		var single = moonX >= 0;
		createMoons(single, moonX, moonY, level);
		events = single ? 0 : EVENTS[level % EVENTS.length];
		createSkyActors();

		var w = FlxG.width;
		var n = theme.name;
		addLayer(PixelArt.ridge("px_mountains_" + n, w, FlxG.height, 175, 70, 7, theme.ridge[0], theme.ridge[1], false, theme.ridge[2]), 0.15);
		addLayer(PixelArt.ridge("px_hills_" + n, w, FlxG.height, 215, 28, 21, theme.hills[0], theme.hills[1], true), 0.4);
		createParticles();
	}

	/** 1-3 hold különböző méretben, fázisban és (kicsit) színben; lassan sodródnak az égen. */
	function createMoons(single:Bool, moonX:Float, moonY:Float, level:Int):Void
	{
		var count = single ? 1 : MOON_COUNT[level % MOON_COUNT.length];
		var radii = [13, 8, 6];
		for (i in 0...count)
		{
			// Az első hold a legnagyobb; a fázis véletlen, de a legelső pálya főholdja telihold
			var phase = (i == 0 && level == 0) || single ? 4 : rnd.int(1, 7);
			var r = radii[i];
			var s = new FlxSprite(0, 0, PixelArt.moon(r, phase, i == 0 ? 0 : (i == 1 ? 1 : 2)));
			var cx = single ? moonX : (i + 0.5) / count * FlxG.width * 0.95 + rnd.float(-24, 24) + 24;
			var cy = single ? moonY : rnd.float(36, 84);
			if (!single && i == 0 && count == 1)
				cx = 298; // az egyetlen hold a megszokott helyén
			s.x = cx - r;
			s.y = cy - r;
			s.scrollFactor.set(0, 0);
			add(s);
			moons.push({s: s, r: r, vx: single ? 0 : rnd.float(0.3, 0.9), baseY: s.y, phase: rnd.float(0, 6.28)});
		}
		orbitMoon = moons.length - 1;
	}

	function createSkyActors():Void
	{
		for (i in 0...6)
		{
			var s = new FlxSprite(0, 0, PixelArt.streak(20, 3, 0xffcfe8ff));
			s.origin.set(19, 1); // a feje a forgáspont
			s.scrollFactor.set(0, 0);
			s.exists = false;
			add(s);
			streaks.push({s: s, life: 0, max: 1});
		}
		if (events & EV_ORBIT != 0)
		{
			ship = new FlxSprite(0, 0, PixelArt.tinyShip());
			ship.scrollFactor.set(0, 0);
			add(ship);
		}
		if (events & EV_UFO != 0)
		{
			ufo = new FlxSprite(0, 0);
			ufo.loadGraphic(PixelArt.ufo(), true, 12, 6);
			ufo.animation.add("blink", [0, 1], 4);
			ufo.animation.play("blink");
			ufo.scrollFactor.set(0, 0);
			ufo.exists = false;
			add(ufo);
		}
		if (events & EV_SAT != 0)
		{
			sat = new FlxSprite(0, 0);
			sat.makeGraphic(2, 2, 0xffffffff);
			sat.scrollFactor.set(0, 0);
			sat.exists = false;
			add(sat);
		}
		if (events & EV_COMET != 0)
		{
			comet = new FlxSprite(0, 0, PixelArt.streak(46, 5, 0xffffe8a8));
			comet.origin.set(45, 2);
			comet.scrollFactor.set(0, 0);
			comet.exists = false;
			add(comet);
		}
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

	/** Időjárás: kis, a képernyőhöz rögzített részecskék, amik körbeérnek a szélén. */
	function createParticles():Void
	{
		var kind = theme.particles;
		if (kind == "")
			return;
		var count = switch (kind)
		{
			case "snow": 60;
			case "ash": 50;
			case "spores": 34;
			default: 44; // sand
		}
		var colors:Array<FlxColor> = switch (kind)
		{
			case "snow": [0xffffffff, 0xffd8ecff, 0xffa8c8e8];
			case "ash": [0xff8a7a72, 0xff5a4a46, 0xffff8a3a];
			case "spores": [0xffc8ff5a, 0xff7ae03a, 0xff4ab02a];
			default: [0xfff0d090, 0xffd0a45a, 0xffe8c47a];
		}
		count = Perf.scale(count);
		for (i in 0...count)
		{
			var size = FlxG.random.bool(25) ? 2 : 1;
			var s = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			s.makeGraphic(size, size, colors[FlxG.random.int(0, colors.length - 1)]);
			s.scrollFactor.set(0, 0);
			s.alpha = FlxG.random.float(0.45, 0.9);
			add(s);
			var vx = 0.0, vy = 0.0;
			switch (kind)
			{
				case "snow":
					vx = FlxG.random.float(-6, 4);
					vy = FlxG.random.float(14, 30);
				case "ash":
					vx = FlxG.random.float(-14, 4);
					vy = FlxG.random.float(8, 22);
				case "spores":
					vx = FlxG.random.float(-5, 5);
					vy = -FlxG.random.float(6, 18);
				default:
					vx = FlxG.random.float(60, 130);
					vy = FlxG.random.float(-4, 8);
			}
			parts.push({s: s, vx: vx, vy: vy, phase: FlxG.random.float(0, 6.28), sway: kind == "sand" ? 0 : FlxG.random.float(4, 14)});
		}
	}

	/**
	 * Hullócsillag-raj: `count` csillag indul `duration` mp alatt szétosztva (a meteoreső előtt, mintha abból jönne a zápor).
	 */
	public function shootingStars(count:Int, duration:Float):Void
	{
		for (i in 0...count)
			pending.push(i * duration / count + FlxG.random.float(0, 0.15));
	}

	function launchStar():Void
	{
		for (st in streaks)
			if (!st.s.exists)
			{
				var a = FlxG.random.float(22, 48);
				var right = FlxG.random.bool();
				var deg = right ? a : 180 - a;
				var speed = FlxG.random.float(220, 320);
				var rad = deg * Math.PI / 180;
				st.s.reset(right ? FlxG.random.float(-6, FlxG.width * 0.7) : FlxG.random.float(FlxG.width * 0.3, FlxG.width + 6), FlxG.random.float(0, 70));
				st.s.angle = deg;
				st.s.velocity.set(Math.cos(rad) * speed, Math.sin(rad) * speed);
				st.s.alpha = 1;
				st.max = st.life = FlxG.random.float(0.7, 1.1);
				return;
			}
	}

	override public function update(elapsed:Float):Void
	{
		time += elapsed;
		for (layer in layers)
		{
			var w = layer.sprites[0].width;
			var base = Math.floor(FlxG.camera.scroll.x * layer.factor / w) * w;
			for (i in 0...layer.sprites.length)
				layer.sprites[i].x = base + i * w;
		}
		for (p in parts)
		{
			p.s.x += (p.vx + Math.sin(time * 1.3 + p.phase) * p.sway) * elapsed;
			p.s.y += p.vy * elapsed;
			// Körbeér a képernyő szélén
			if (p.s.x > FlxG.width)
				p.s.x -= FlxG.width + 4;
			else if (p.s.x < -4)
				p.s.x += FlxG.width + 4;
			if (p.s.y > FlxG.height)
				p.s.y -= FlxG.height + 4;
			else if (p.s.y < -4)
				p.s.y += FlxG.height + 4;
		}
		updateSky(elapsed);
		super.update(elapsed);
	}

	/** A holdak lassú sodródása és az égi események. */
	function updateSky(dt:Float):Void
	{
		for (m in moons)
		{
			m.s.x += m.vx * dt;
			m.s.y = m.baseY + Math.sin(time * 0.25 + m.phase) * 1.5;
			if (m.s.x > FlxG.width + m.r)
				m.s.x = -m.r * 2;
		}

		// Hullócsillagok: időnként egy-egy, és a kért csoportos hullás
		starT -= dt;
		if (starT <= 0)
		{
			starT = FlxG.random.float(6, 14);
			launchStar();
		}
		var i = pending.length;
		while (i-- > 0)
		{
			pending[i] -= dt;
			if (pending[i] <= 0)
			{
				pending.splice(i, 1);
				launchStar();
			}
		}
		for (st in streaks)
			if (st.s.exists)
			{
				st.life -= dt;
				st.s.alpha = Math.min(1, st.life / (st.max * 0.4));
				if (st.life <= 0)
					st.s.exists = false;
			}

		// A hold körül köröző kis űrhajó: az első fele a hold előtt, a második mögötte (eltűnik)
		if (ship != null)
		{
			orbitA += dt * 0.7;
			var m = moons[orbitMoon];
			var cx = m.s.x + m.r, cy = m.s.y + m.r;
			var rx = m.r + 11, ry = 5 + m.r * 0.25;
			var sn = Math.sin(orbitA);
			ship.x = cx + Math.cos(orbitA) * rx - ship.width / 2;
			ship.y = cy + sn * ry - ship.height / 2 + m.r * 0.2;
			ship.visible = sn > 0;
			ship.flipX = true; // az elöl látszó félkörön balra halad
		}

		// Csészealj: időnként átrepül az égen, imbolyogva
		if (ufo != null)
		{
			if (!ufo.exists)
			{
				ufoT -= dt;
				if (ufoT <= 0)
				{
					ufoT = FlxG.random.float(16, 28);
					var dir = FlxG.random.bool() ? 1 : -1;
					ufo.reset(dir > 0 ? -14 : FlxG.width + 2, FlxG.random.float(26, 80));
					ufo.velocity.set(dir * FlxG.random.float(30, 46), 0);
				}
			}
			else
			{
				ufo.y += Math.sin(time * 5) * 0.25;
				if (ufo.x > FlxG.width + 16 || ufo.x < -20)
					ufo.exists = false;
			}
		}

		// Műhold: lassú, villogó pont
		if (sat != null)
		{
			if (!sat.exists)
			{
				satT -= dt;
				if (satT <= 0)
				{
					satT = FlxG.random.float(12, 22);
					var dir = FlxG.random.bool() ? 1 : -1;
					sat.reset(dir > 0 ? -4 : FlxG.width + 2, FlxG.random.float(22, 70));
					sat.velocity.set(dir * 13, FlxG.random.float(-1.5, 1.5));
				}
			}
			else
			{
				sat.alpha = Std.int(time * 3) % 2 == 0 ? 1 : 0.35;
				if (sat.x > FlxG.width + 6 || sat.x < -8)
					sat.exists = false;
			}
		}

		// Üstökös: nagy, lassú, hosszú csóvájú
		if (comet != null)
		{
			if (!comet.exists)
			{
				cometT -= dt;
				if (cometT <= 0)
				{
					cometT = FlxG.random.float(22, 36);
					var right = FlxG.random.bool();
					var deg = right ? FlxG.random.float(12, 22) : 180 - FlxG.random.float(12, 22);
					var rad = deg * Math.PI / 180;
					comet.reset(right ? -10 : FlxG.width + 10, FlxG.random.float(10, 50));
					comet.angle = deg;
					comet.velocity.set(Math.cos(rad) * 52, Math.sin(rad) * 52);
				}
			}
			else if (comet.x > FlxG.width + 60 || comet.x < -70 || comet.y > 140)
				comet.exists = false;
		}
	}
}
