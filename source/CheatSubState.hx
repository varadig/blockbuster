package;

#if cheats
import Enemy.EnemyKind;
import PowerUp.PowerKind;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** Egy cheat-menüpont: felirat (dinamikus) és a művelet; a művelet true-val zárja be a menüt. */
typedef CheatItem =
{
	label:Void->String,
	run:Void->Bool
}

/**
 * Cheat-menü (F9): csak fejlesztői buildben (-debug, -Dtest, -Dcheats) van benne, a release-ben nincs.
 * Lapozható: a főlapról a kategóriákba lehet lépni; a legtöbb elem alkalmazza a hatást és bezár (a játék folytatódik),
 * a kapcsolók (GOD MODE stb.) nyitva maradnak.
 */
class CheatSubState extends FlxSubState
{
	/** A kijelölt görgetési sebességek (null = automatikus gyorsulás). */

	var game:PlayState;
	var menu:MenuList;
	var title:FlxText;
	var page:String = "main";
	/** A kért lapváltás: a menü saját frissítésén belül nem építhető újra, ezért az update végén történik. */
	var pendingPage:Null<String> = null;

	public function new(game:PlayState)
	{
		super(0xe0101020);
		this.game = game;
	}

	override public function create():Void
	{
		super.create();
		UiCam.apply(this); // a játék kameraeffektjei (shaderek) a menüt nem érintik

		title = new FlxText(0, 22, FlxG.width, "", 16);
		title.alignment = CENTER;
		title.color = PixelArt.powerColor(PowerKind.SHROOM);
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		var hint = new FlxText(0, 228, FlxG.width, "UP / DOWN  select     SPACE / ENTER  use     LEFT / RIGHT  change     ESC / F9 / R2  back", 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);

		buildPage("main");
	}

	function openPage(p:String):Void
	{
		pendingPage = p;
	}

	function buildPage(p:String):Void
	{
		page = p;
		if (menu != null)
		{
			remove(menu, true);
			menu.destroy();
		}
		var items = itemsFor(p);
		title.text = switch (p)
		{
			case "weapons": "WEAPONS";
			case "mods": "MODIFIERS";
			case "powers": "POWER-UPS";
			case "hazards": "HAZARDS";
			case "enemies": "ENEMIES";
			case "level": "LEVEL";
			case "boss": "BOSS";
			case "toggles": "TOGGLES";
			default: "CHEATS";
		};
		menu = new MenuList(48, [for (i in items) i.label], 8, 14);
		menu.onSelect = i ->
		{
			if (items[i].run())
				close();
		};
		menu.onAdjust = (i, dir) -> adjust(p, i, dir);
		add(menu);
	}

	/** Balra/jobbra: jelenleg egyik cheat soron sincs hatása. */
	function adjust(p:String, i:Int, dir:Int):Void
	{
	}

	function item(label:String, run:Void->Bool):CheatItem
	{
		return {label: () -> label, run: run};
	}

	function back():CheatItem
	{
		return item("BACK", () ->
		{
			openPage("main");
			return false;
		});
	}

	function sub(label:String, p:String):CheatItem
	{
		return item('$label >', () ->
		{
			openPage(p);
			return false;
		});
	}

	function power(label:String, kind:PowerKind):CheatItem
	{
		return item(label, () ->
		{
			game.cheatPower(kind);
			return true;
		});
	}

	/** A főellenség életerejét a maximum törtrészére állítja (a menü bezárul, hogy látszódjon). */
	function bossHp(label:String, fraction:Float):CheatItem
	{
		return item(label, () ->
		{
			game.cheatBossHp(fraction);
			return true;
		});
	}

	function curse(label:String, kind:PowerKind):CheatItem
	{
		return item(label, () ->
		{
			game.cheatCurse(kind);
			return true;
		});
	}

	function toggle(name:String, get:Void->Bool, set:Bool->Void):CheatItem
	{
		return {
			label: () -> '$name   < ${get() ? "ON" : "OFF"} >',
			run: () ->
			{
				set(!get());
				Audio.play("blip");
				return false;
			}
		};
	}

	function itemsFor(p:String):Array<CheatItem>
	{
		return switch (p)
		{
			case "weapons": [
					item("PISTOL (default)", () ->
					{
						game.cheatBaseWeapon(null);
						return true;
					}),
					item("ROCKET LAUNCHER", () ->
					{
						game.cheatBaseWeapon(PowerKind.ROCKET);
						return true;
					}),
					item("LASER", () ->
					{
						game.cheatBaseWeapon(PowerKind.LASER);
						return true;
					}),
					item("GRENADES", () ->
					{
						game.cheatBaseWeapon(PowerKind.GRENADE);
						return true;
					}),
					back()
				];
			case "mods": [
					item("SPREAD SHOT", () ->
					{
						game.cheatMod(PowerKind.SPREAD);
						return true;
					}),
					item("RAPID FIRE", () ->
					{
						game.cheatMod(PowerKind.RAPID);
						return true;
					}),
					item("HOMING", () ->
					{
						game.cheatMod(PowerKind.HOMING);
						return true;
					}),
					item("ALL", () ->
					{
						game.cheatMod(PowerKind.SPREAD);
						game.cheatMod(PowerKind.RAPID);
						game.cheatMod(PowerKind.HOMING);
						return true;
					}),
					item("CLEAR MODIFIERS", () ->
					{
						game.cheatClearMods();
						return true;
					}),
					back()
				];
			case "powers": [
					power("ENERGY +", PowerKind.ENERGY),
					item("FULL ENERGY", () ->
					{
						game.cheatFullEnergy();
						return true;
					}),
					power("BONUS POINTS", PowerKind.BONUS),
					back()
				];
			case "curses": [
					curse("MAGIC MUSHROOM", PowerKind.SHROOM),
					curse("PIXELATED", PowerKind.PIXEL),
					curse("FLASHLIGHT", PowerKind.TORCH),
					curse("INVISIBLE HERO", PowerKind.GHOST),
					curse("TUNNEL VISION", PowerKind.TINYVIEW),
					curse("TINY HERO", PowerKind.TINYHERO),
					curse("MAGNETIC ENEMIES", PowerKind.MAGNET),
					curse("ASCII MODE", PowerKind.ASCII),
					item("CLEAR ALL EFFECTS", () ->
					{
						game.cheatClearCurses();
						return true;
					}),
					back()
				];
			case "hazards": [
					item("SPAWN RANDOM MODIFIER ITEM", () ->
					{
						game.cheatShroom();
						return true;
					}),
					item("METEOR", () ->
					{
						game.cheatMeteor(false);
						return true;
					}),
					item("GOLDEN METEOR", () ->
					{
						game.cheatMeteor(true);
						return true;
					}),
					item("METEOR SHOWER", () ->
					{
						game.cheatShower();
						return true;
					}),
					item("METEOR FALL", () ->
					{
						game.cheatMeteorFall();
						return true;
					}),
					back()
				];
			case "enemies": [
					enemy("SLIME", EnemyKind.SLIME),
					enemy("BAT", EnemyKind.BAT),
					enemy("TURRET", EnemyKind.TURRET),
					enemy("DRONE", EnemyKind.DRONE),
					enemy("SPIDERLING", EnemyKind.SPIDERLING),
					back()
				];
			case "level": [
					item("SKIP TO BOSS", () ->
					{
						game.cheatSkipToBoss();
						return true;
					}),
					item("KILL BOSS", () ->
					{
						game.cheatKillBoss();
						return true;
					}),
					item("COMPLETE QUESTS", () ->
					{
						game.cheatCompleteQuests();
						return true;
					}),
					item("NEXT LEVEL", () ->
					{
						game.cheatNextLevel();
						return true;
					}),
					item("PREVIOUS LEVEL", () ->
					{
						game.cheatPreviousLevel();
						return true;
					}),
					item("SKIP TO FINAL BOSS", () ->
					{
						game.cheatSkipToFinalBoss();
						return true;
					}),
					back()
				];
			case "boss": [
					// Az első sor csak kijelzi az életerőt (kiválasztva frissül)
					{label: () -> game.cheatBossHpText(), run: () -> false},
					bossHp("BOSS HP 100%", 1.0),
					bossHp("BOSS HP 75%", 0.75),
					bossHp("BOSS HP 50% (2nd phase)", 0.5),
					bossHp("BOSS HP 30%", 0.3),
					bossHp("BOSS HP 24% (berserk)", 0.24),
					bossHp("BOSS HP 10%", 0.1),
					bossHp("BOSS HP 1", 0.0),
					toggle("LOCK BOSS HP (no damage)", () -> game.bossHpLock, v -> game.bossHpLock = v),
					item("FORCE MORPH (final boss)", () ->
					{
						game.cheatBossMorph();
						return true;
					}),
					item("KILL BOSS", () ->
					{
						game.cheatKillBoss();
						return true;
					}),
					back()
				];
			case "toggles": [
					toggle("GOD MODE", () -> game.godMode, v -> game.godMode = v),
					toggle("FREEZE POWER-UP TIMERS", () -> game.freezePowers, v -> game.freezePowers = v),
					toggle("NO SPAWNS", () -> game.noSpawns, v -> game.noSpawns = v),
					back()
				];
			default: [
					sub("WEAPONS", "weapons"),
					sub("WEAPON MODIFIERS", "mods"),
					sub("HERO EFFECTS (timed)", "curses"),
					sub("POWER-UPS", "powers"),
					sub("HAZARDS", "hazards"),
					sub("ENEMIES", "enemies"),
					sub("LEVEL", "level"),
					sub("BOSS", "boss"),
					sub("TOGGLES", "toggles"),
					item("CLOSE", () -> true)
				];
		}
	}

	function enemy(label:String, kind:EnemyKind):CheatItem
	{
		return item(label, () ->
		{
			game.cheatEnemy(kind);
			return true;
		});
	}

	var age:Int = 0;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		age++;
		if (pendingPage != null)
		{
			var p = pendingPage;
			pendingPage = null;
			buildPage(p);
			return;
		}
		if (age > 3 && menu.isReady() && (FlxG.keys.anyJustPressed([ESCAPE, F9]) || Pad.just(CHEAT) || Pad.just(BACK)))
		{
			if (page == "main")
				close();
			else
				openPage("main");
		}
	}
}
#end
