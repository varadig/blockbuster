package;

import haxe.Json;
import openfl.utils.Assets;

/**
 * Finomhangolható játékértékek az `assets/config/game.json` fájlból (beágyazva, módosítás után újra kell fordítani).
 * Az alapértékek itt vannak a kódban: ha a fájl hiányzik, hibás, vagy egy kulcs kimarad, az alapérték él.
 * A tartományon kívüli értéket a betöltő a határra szorítja, és naplózza. A leírás: docs/CONFIG.md.
 */
class Config
{
	public static inline var PATH:String = "assets/config/game.json";

	// --- player ---
	public static var runSpeed:Float = 200;
	/** A hős futási sebessége legalább ennyiszerese a kamera sebességének, hogy a gyorsuló görgetéssel is lépést lehessen tartani. */
	public static var followRatio:Float = 1.35;
	public static var jumpSpeed:Float = 330;
	public static var gravity:Float = 900;
	public static var maxEnergy:Float = 100;
	public static var hurtTime:Float = 1.3;
	public static var shootCooldown:Float = 0.18;
	public static var chargeTime:Float = 1.0;
	public static var chargeMin:Float = 0.18;

	// --- scroll ---
	public static var scrollStart:Float = 60;
	public static var scrollMax:Float = 170;
	public static var scrollAccel:Float = 1.5;
	public static var startGrace:Float = 1.5;

	// --- damage ---
	public static var damageMeteorSmall:Float = 15;
	public static var damageMeteorMedium:Float = 30;
	public static var damageMeteorLarge:Float = 50;
	public static var damageFall:Float = 30;
	public static var damageEnemyShot:Float = 12;
	public static var damageBomb:Float = 20;
	public static var damageBossContact:Float = 25;
	/** Az izzó (földet ért, még forró) meteor érintésének sebzése. */
	public static var damageMeteorHot:Float = 20;

	// --- powerups ---
	public static var weaponTime:Float = 12;
	public static var energyRefill:Float = 35;
	public static var bonusPoints:Int = 250;

	// --- weapons ---
	public static var bulletSpeed:Float = 420;
	public static var laserSpeed:Float = 900;
	public static var rapidCooldown:Float = 0.07;
	public static var laserCooldown:Float = 0.24;
	public static var laserCooldownRapid:Float = 0.1;
	public static var rocketSpeed:Float = 230;
	public static var rocketCooldown:Float = 0.55;
	public static var rocketRadius:Float = 30;
	public static var rocketDamage:Int = 4;
	public static var grenadeSpeed:Float = 190;
	public static var grenadeCooldown:Float = 0.8;
	public static var grenadeRadius:Float = 58;
	public static var grenadeDamage:Int = 5;
	/** A sorozatlövő (RAPID) a rakéta és a gránát várakozási idejét ennyiszeresére szorítja. */
	public static var rapidMul:Float = 0.5;
	/** Nyomkövető lövedék: hatótáv (px) és fordulási sebesség (rad/s). */
	public static var homingRange:Float = 260;
	public static var homingTurn:Float = 5;

	// --- modifiers (időkorlátos, a hőst nehezítő hatások; a varázsgomba ideje: shroom.tripTime) ---
	public static var pixelTime:Float = 12;
	/** ASCII-mód ideje (mp). */
	public static var asciiTime:Float = 12;
	/** A pixelesítés blokkmérete (belső pixelben; 1 = nincs hatás). */
	public static var pixelBlock:Float = 4;
	public static var torchTime:Float = 12;
	/** A zseblámpa fényköre (belső pixelben). */
	public static var torchRadius:Float = 48;
	public static var ghostTime:Float = 8;
	/** A láthatatlan hős átlátszatlansága (0 = teljesen láthatatlan). */
	public static var ghostAlpha:Float = 0;
	public static var viewTime:Float = 10;
	/** Az összezsugorított látómezőnél a képernyő széléből eltakart rész (a szélesség / magasság törtrésze oldalanként). */
	public static var viewMarginX:Float = 0.2;
	public static var viewMarginY:Float = 0.2;
	public static var tinyTime:Float = 12;
	/** Az összezsugorított hős mérete (1 = normál). */
	public static var tinyScale:Float = 0.55;
	public static var magnetTime:Float = 12;
	/** A mágnes gyorsulása (px/s²), legnagyobb oldalsebessége (px/s) és hatótávja (px). */
	public static var magnetForce:Float = 110;
	public static var magnetSpeed:Float = 80;
	public static var magnetRange:Float = 260;
	/** Melyik módosító mennyire gyakori: SHROOM, PIXEL, TORCH, GHOST, TINYVIEW, TINYHERO, MAGNET, ASCII. */
	public static var curseWeights:Array<Float> = [24, 12, 12, 10, 10, 10, 12, 22];
	/** Módosító tárgy esélye (%) szétlőtt meteorból és legyőzött ellenségből (loot); legfeljebb ennyi tárgy lehet egyszerre a pályán. */
	public static var curseDropMeteor:Float = 5;
	public static var curseDropEnemy:Float = 12;
	public static var curseMaxItems:Float = 3;

	// --- spawning ---
	public static var meteorIntervalStart:Float = 1.3;
	public static var meteorIntervalMin:Float = 0.35;
	/** Ennyivel csökken a meteorok közti idő másodpercenként (procedurális pályán). */
	public static var meteorIntervalDecay:Float = 0.012;
	public static var enemyUnlock:Array<Float> = [20, 45, 75, 110];
	public static var enemyIntervalStart:Float = 6;
	public static var enemyIntervalMin:Float = 2;
	public static var enemyShotSpeed:Float = 130;
	public static var bombRadius:Float = 28;
	public static var stompBounce:Float = 260;
	/** Az izzó meteor esélye (%) a nem jutalom meteorok közt; földet érve ennyi ideig (mp) forró marad. */
	public static var hotMeteorChance:Float = 18;
	public static var hotMeteorTime:Float = 4.5;
	/** A ráragadt slime: ennyi ideig (mp) tapad, és ennyiszeresére lassítja a hőst (több slime szorzódik, de 0.3 alá nem megy). */
	public static var slimeStickTime:Float = 4;
	public static var slimeSlow:Float = 0.6;
	/** Pókcsípés: a "tipsy" (ittas ingadozás) egy csípésének ideje (mp) és a legtöbb egyszerre számító csípés (a hatás erőssége ezzel arányos). */
	public static var tipsyTime:Float = 6;
	public static var tipsyMax:Float = 5;

	// --- shroom ---
	/** Az első varázsgomba megjelenése procedurális pályán (mp). */
	public static var shroomFirst:Float = 15;
	public static var shroomIntervalMin:Float = 8;
	public static var shroomIntervalMax:Float = 14;

	/** Globális ranglista (Supabase): URL, nyilvános anon kulcs és a tábla neve; üresen a funkció ki van kapcsolva (docs/LEADERBOARD.md). */
	public static var leaderboardUrl:String = "";
	public static var leaderboardKey:String = "";
	public static var leaderboardTable:String = "scores";
	/** Teszt: a ranglista-URL az URL-paraméterből jött (cheats buildben csak így lehet beküldeni). */
	public static var leaderboardTest:Bool = false;
	public static var tripTime:Float = 7;

	// --- game ---
	public static var continues:Int = 3;
	public static var continueTime:Float = 10;
	public static var bossBaseHp:Float = 110;
	public static var bossHpPerLevel:Float = 95;

	// --- difficulty (easy / normal / hard) ---
	public static var scrollMul:Array<Float> = [0.85, 1, 1.18];
	public static var spawnIntervalMul:Array<Float> = [1.35, 1, 0.75];
	public static var damageMul:Array<Float> = [0.6, 1, 1.4];
	/** Jutalommeteor esélye (%). */
	public static var rewardChance:Array<Float> = [16, 12, 9];
	public static var gapMul:Array<Float> = [0.7, 1, 1.25];

	/** A betöltés figyelmeztetései (a hibás vagy tartományon kívüli értékek). */
	public static var warnings:Array<String> = [];

	static var loaded:Bool = false;

	/** Betöltés az beágyazott assetből; hiba esetén az alapértékek maradnak. Többször is hívható (csak egyszer olvas). */
	public static function load():Void
	{
		if (loaded)
			return;
		loaded = true;
		var text:Null<String> = null;
		try
		{
			text = Assets.getText(PATH);
		}
		catch (e:Dynamic) {}
		if (text == null)
		{
			warn('$PATH nem található, az alapértékek élnek');
			return;
		}
		try
		{
			apply(Json.parse(text));
		}
		catch (e:Dynamic)
		{
			warn('$PATH hibás (${Std.string(e)}), az alapértékek élnek');
		}
	}

	/** Tesztekhez: a konfiguráció betöltése szövegből (a már betöltött értékek felülíródnak). */
	public static function loadFromText(text:String):Void
	{
		warnings = [];
		apply(Json.parse(text));
		loaded = true;
	}

	static function apply(root:Dynamic):Void
	{
		warnings = [];
		runSpeed = n(root, "player.runSpeed", runSpeed, 40, 1500);
		followRatio = n(root, "player.followRatio", followRatio, 1, 4);
		jumpSpeed = n(root, "player.jumpSpeed", jumpSpeed, 100, 1000);
		gravity = n(root, "player.gravity", gravity, 200, 4000);
		maxEnergy = n(root, "player.maxEnergy", maxEnergy, 10, 10000);
		hurtTime = n(root, "player.hurtTime", hurtTime, 0, 10);
		shootCooldown = n(root, "player.shootCooldown", shootCooldown, 0.02, 2);
		chargeTime = n(root, "player.chargeTime", chargeTime, 0.2, 10);
		chargeMin = n(root, "player.chargeMin", chargeMin, 0.05, 2);

		scrollStart = n(root, "scroll.start", scrollStart, 0, 600);
		scrollMax = n(root, "scroll.max", scrollMax, 10, 1200);
		scrollAccel = n(root, "scroll.accel", scrollAccel, 0, 100);
		startGrace = n(root, "scroll.startGrace", startGrace, 0, 20);

		damageMeteorSmall = n(root, "damage.meteorSmall", damageMeteorSmall, 0, 1000);
		damageMeteorMedium = n(root, "damage.meteorMedium", damageMeteorMedium, 0, 1000);
		damageMeteorLarge = n(root, "damage.meteorLarge", damageMeteorLarge, 0, 1000);
		damageFall = n(root, "damage.fall", damageFall, 0, 1000);
		damageEnemyShot = n(root, "damage.enemyShot", damageEnemyShot, 0, 1000);
		damageBomb = n(root, "damage.bomb", damageBomb, 0, 1000);
		damageBossContact = n(root, "damage.bossContact", damageBossContact, 0, 1000);
		damageMeteorHot = n(root, "damage.meteorHot", damageMeteorHot, 0, 1000);

		weaponTime = n(root, "powerups.weaponTime", weaponTime, 1, 600);
		energyRefill = n(root, "powerups.energyRefill", energyRefill, 0, 1000);
		bonusPoints = Std.int(n(root, "powerups.bonusPoints", bonusPoints, 0, 1000000));

		bulletSpeed = n(root, "weapons.bulletSpeed", bulletSpeed, 50, 3000);
		laserSpeed = n(root, "weapons.laserSpeed", laserSpeed, 100, 5000);
		rapidCooldown = n(root, "weapons.rapidCooldown", rapidCooldown, 0.02, 2);
		laserCooldown = n(root, "weapons.laserCooldown", laserCooldown, 0.02, 5);
		laserCooldownRapid = n(root, "weapons.laserCooldownRapid", laserCooldownRapid, 0.02, 5);
		rocketSpeed = n(root, "weapons.rocketSpeed", rocketSpeed, 50, 3000);
		rocketCooldown = n(root, "weapons.rocketCooldown", rocketCooldown, 0.05, 10);
		rocketRadius = n(root, "weapons.rocketRadius", rocketRadius, 4, 300);
		rocketDamage = Std.int(n(root, "weapons.rocketDamage", rocketDamage, 1, 1000));
		grenadeSpeed = n(root, "weapons.grenadeSpeed", grenadeSpeed, 50, 3000);
		grenadeCooldown = n(root, "weapons.grenadeCooldown", grenadeCooldown, 0.05, 10);
		grenadeRadius = n(root, "weapons.grenadeRadius", grenadeRadius, 4, 400);
		grenadeDamage = Std.int(n(root, "weapons.grenadeDamage", grenadeDamage, 1, 1000));
		rapidMul = n(root, "weapons.rapidMul", rapidMul, 0.1, 1);
		homingRange = n(root, "weapons.homingRange", homingRange, 20, 2000);
		homingTurn = n(root, "weapons.homingTurn", homingTurn, 0.1, 50);

		pixelTime = n(root, "modifiers.pixelTime", pixelTime, 1, 600);
		asciiTime = n(root, "modifiers.asciiTime", asciiTime, 1, 600);
		pixelBlock = n(root, "modifiers.pixelBlock", pixelBlock, 1, 40);
		torchTime = n(root, "modifiers.torchTime", torchTime, 1, 600);
		torchRadius = n(root, "modifiers.torchRadius", torchRadius, 8, 400);
		ghostTime = n(root, "modifiers.ghostTime", ghostTime, 1, 600);
		ghostAlpha = n(root, "modifiers.ghostAlpha", ghostAlpha, 0, 1);
		viewTime = n(root, "modifiers.viewTime", viewTime, 1, 600);
		viewMarginX = n(root, "modifiers.viewMarginX", viewMarginX, 0, 0.45);
		viewMarginY = n(root, "modifiers.viewMarginY", viewMarginY, 0, 0.45);
		tinyTime = n(root, "modifiers.tinyTime", tinyTime, 1, 600);
		tinyScale = n(root, "modifiers.tinyScale", tinyScale, 0.2, 1);
		magnetTime = n(root, "modifiers.magnetTime", magnetTime, 1, 600);
		magnetForce = n(root, "modifiers.magnetForce", magnetForce, 0, 3000);
		magnetSpeed = n(root, "modifiers.magnetSpeed", magnetSpeed, 0, 1000);
		magnetRange = n(root, "modifiers.magnetRange", magnetRange, 20, 2000);
		curseWeights = arr(root, "modifiers.weights", curseWeights, 8, 0, 1000);
		curseDropMeteor = n(root, "modifiers.dropMeteor", curseDropMeteor, 0, 100);
		curseDropEnemy = n(root, "modifiers.dropEnemy", curseDropEnemy, 0, 100);
		curseMaxItems = n(root, "modifiers.maxItems", curseMaxItems, 1, 20);

		meteorIntervalStart = n(root, "spawning.meteorIntervalStart", meteorIntervalStart, 0.1, 30);
		meteorIntervalMin = n(root, "spawning.meteorIntervalMin", meteorIntervalMin, 0.05, 30);
		meteorIntervalDecay = n(root, "spawning.meteorIntervalDecay", meteorIntervalDecay, 0, 1);
		enemyUnlock = arr(root, "spawning.enemyUnlock", enemyUnlock, 4, 0, 3600);
		enemyIntervalStart = n(root, "spawning.enemyIntervalStart", enemyIntervalStart, 0.2, 120);
		enemyIntervalMin = n(root, "spawning.enemyIntervalMin", enemyIntervalMin, 0.2, 120);
		enemyShotSpeed = n(root, "spawning.enemyShotSpeed", enemyShotSpeed, 20, 1000);
		bombRadius = n(root, "spawning.bombRadius", bombRadius, 4, 200);
		stompBounce = n(root, "spawning.stompBounce", stompBounce, 50, 800);
		hotMeteorChance = n(root, "spawning.hotMeteorChance", hotMeteorChance, 0, 100);
		hotMeteorTime = n(root, "spawning.hotMeteorTime", hotMeteorTime, 0.5, 60);
		slimeStickTime = n(root, "spawning.slimeStickTime", slimeStickTime, 0.5, 60);
		slimeSlow = n(root, "spawning.slimeSlow", slimeSlow, 0.1, 1);
		tipsyTime = n(root, "spawning.tipsyTime", tipsyTime, 0.5, 120);
		tipsyMax = n(root, "spawning.tipsyMax", tipsyMax, 1, 20);

		shroomFirst = n(root, "shroom.first", shroomFirst, 0, 3600);
		shroomIntervalMin = n(root, "shroom.intervalMin", shroomIntervalMin, 1, 600);
		shroomIntervalMax = Math.max(shroomIntervalMin, n(root, "shroom.intervalMax", shroomIntervalMax, 1, 600));
		tripTime = n(root, "shroom.tripTime", tripTime, 1, 120);

		leaderboardUrl = StringTools.trim(str(root, "leaderboard.url", leaderboardUrl));
		while (StringTools.endsWith(leaderboardUrl, "/"))
			leaderboardUrl = leaderboardUrl.substr(0, leaderboardUrl.length - 1);
		leaderboardKey = StringTools.trim(str(root, "leaderboard.key", leaderboardKey));
		leaderboardTable = StringTools.trim(str(root, "leaderboard.table", leaderboardTable));

		#if (cheats && js)
		// Teszteléshez: ?lburl=http://...&lbkey=... felülírja a ranglista-beállítást (csak cheats buildben)
		var q = js.Browser.location.search;
		var mu = ~/lburl=([^&]+)/;
		if (mu.match(q))
		{
			leaderboardUrl = StringTools.urlDecode(mu.matched(1));
			leaderboardTest = true;
		}
		var mk = ~/lbkey=([^&]+)/;
		if (mk.match(q))
			leaderboardKey = StringTools.urlDecode(mk.matched(1));
		#end

		continues = Std.int(n(root, "game.continues", continues, 0, 99));
		continueTime = n(root, "game.continueTime", continueTime, 1, 120);
		bossBaseHp = n(root, "boss.baseHp", bossBaseHp, 1, 100000);
		bossHpPerLevel = n(root, "boss.hpPerLevel", bossHpPerLevel, 0, 100000);

		scrollMul = arr(root, "difficulty.scrollMul", scrollMul, 3, 0.2, 4);
		spawnIntervalMul = arr(root, "difficulty.spawnIntervalMul", spawnIntervalMul, 3, 0.1, 10);
		damageMul = arr(root, "difficulty.damageMul", damageMul, 3, 0, 10);
		rewardChance = arr(root, "difficulty.rewardChance", rewardChance, 3, 0, 100);
		gapMul = arr(root, "difficulty.gapMul", gapMul, 3, 0, 5);
	}

	// --- Segédek ---

	/** Szám a "szakasz.kulcs" útvonalon; hiányzó kulcs = alapérték, hibás vagy tartományon kívüli = figyelmeztetés. */
	static function n(root:Dynamic, path:String, def:Float, min:Float, max:Float):Float
	{
		var v = lookup(root, path);
		if (v == null)
			return def;
		var f = Std.parseFloat(Std.string(v));
		if (Math.isNaN(f))
		{
			warn('$path: "$v" nem szám, marad: $def');
			return def;
		}
		if (f < min || f > max)
		{
			var c = Math.max(min, Math.min(max, f));
			warn('$path: $f a megengedett tartományon ($min..$max) kívül van, $c lesz');
			return c;
		}
		return f;
	}

	/** Szöveg a "szakasz.kulcs" útvonalon; hiányzó kulcs = alapérték. */
	static function str(root:Dynamic, path:String, def:String):String
	{
		var v = lookup(root, path);
		return v == null ? def : Std.string(v);
	}

	/** Számtömb pontosan `len` elemmel (pl. az enemyUnlock vagy a nehézségi szintek); hibás hossz = alapérték. */
	static function arr(root:Dynamic, path:String, def:Array<Float>, len:Int, min:Float, max:Float):Array<Float>
	{
		var v:Dynamic = lookup(root, path);
		if (v == null)
			return def;
		if (!Std.isOfType(v, Array) || (v : Array<Dynamic>).length != len)
		{
			warn('$path: $len elemű tömb kell, marad az alapérték');
			return def;
		}
		var out:Array<Float> = [];
		for (i in 0...len)
		{
			var f = Std.parseFloat(Std.string((v : Array<Dynamic>)[i]));
			if (Math.isNaN(f))
			{
				warn('$path[$i] nem szám, marad az alapérték');
				out.push(def[i]);
			}
			else if (f < min || f > max)
			{
				warn('$path[$i]: $f a tartományon ($min..$max) kívül van');
				out.push(Math.max(min, Math.min(max, f)));
			}
			else
				out.push(f);
		}
		return out;
	}

	static function lookup(root:Dynamic, path:String):Dynamic
	{
		var cur:Dynamic = root;
		for (part in path.split("."))
		{
			if (cur == null || !Reflect.hasField(cur, part))
				return null;
			cur = Reflect.field(cur, part);
		}
		return cur;
	}

	static function warn(msg:String):Void
	{
		warnings.push(msg);
		trace('[Config] $msg');
	}
}
