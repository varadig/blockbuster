package;

import flixel.FlxG;
import flixel.FlxSprite;

/** A főellenség fajtái: pályánként más (a 6. pálytól újra elölről). */
enum abstract BossKind(Int) from Int to Int
{
	/** Anyahajó: a képernyő tetején lebeg, meteorokat ejt, legyezőben lő, denevéreket hív. */
	var MOTHERSHIP = 0;
	/** Harckocsi: a talajon gurul, ágyúval lő, és bombákat vet fel az égre. */
	var TANK = 1;
	/** Kísértetféreg: lebeg és tekereg, az agyaras szájából lő és denevéreket köp. */
	var GHOST = 2;
	/** Izomtömeg: a talajon lépked, a kezében tartott gömböket hajítja, a szájából lő. */
	var BRUTE = 3;
	/** Háromszemű nyálka: a talajon vonaglik, a három szeméből lő, denevéreket hív. */
	var STALKER = 4;
	/** Bozontos gyilkos: egyszemű, a talajon vágtat és a hősre ront, tüskéket hullat az égből. */
	var KILLER = 5;
	/** Szőrös pók: nagy gömbölyű potroh, hosszú lábak; a lábaival a hős alatt tüskéket szúr fel, hálóval lelassítja. */
	var STRIDER = 6;
	/** Bolyhos óriás: két szemnyél, pattogó pihegolyókat gurít és spórákat fúj. */
	var PUFF = 7;
	/** A végső főellenség (a 9. pályán): a karmoló, előrehajló szörny; az előző főellenségek támadásait vegyíti, és sokkal több életereje van. */
	var FINAL = 8;
	/** A kiüresedett hold (a 9. pálya): lebegő, megrepedt hold; meteoreső-hívás, szilánk-sorozat és gravitációs örvény. */
	var HOLLOW = 9;
}

/**
 * Főellenség: a pálya végén érkezik, amikor a kamera megáll. Felváltva támad, a második fázisban
 * (fél életerő alatt) gyorsabban és több támadással. Pályánként erősebb. A kinézetet és a mozgást a `BossKind` adja.
 * Mindig a hős felé fordul (a sprite-ok alapból balra néznek, a másik irányba tükrözve rajzolódnak).
 */
class Boss extends FlxSprite
{
	/** Ennyi képpontnál közelebb a hős vízszintesen: nem fordul meg (különben remegne, ha pont fölötte jár). */
	static inline var TURN_DEADZONE:Float = 10;

	public var hp:Float;
	public var maxHp(default, null):Float;
	public var title(default, null):String = "MOTHERSHIP";
	public var kind(default, null):BossKind;
	/** Érkezés közben (beúszik jobbról) nem sebezhető. */
	public var entering(default, null):Bool = true;
	public var contactDamage(default, null):Float = 25;

	/** A hős: a főellenség mindig felé fordul. A PlayState állítja be. */
	public var target:FlxSprite;

	/**
	 * Támadás kérése a PlayState felé: 0 = meteorok, 1 = legyezőlövés, 2 = denevérek,
	 * 3 = ágyúlövések (harckocsi), 4 = aknavető / gömbhajítás, 5 = hármas szemlövés (nyálka),
	 * 7 = földrengés-hullámok az ugrás landolásakor (izomtömeg), 8 = slime-ok köpése (nyálka), 9 = tüskeeső (gyilkos),
	 * 10 = tüskék a hős alatt (pók), 11 = lassító háló (pók),
	 * 12 = pattogó pihegolyók, 13 = szálló spórák (bolyhos óriás), 15 = meteoreső-hívás, 16 = szilánk-sorozat, 17 = gravitációs örvény (kiüresedett hold).
	 * A 6 (kísértet lecsapása, gyilkos rárontása) a Boss saját mozgása, nem jut el a PlayState-ig.
	 */
	public var onAttack:(Boss, Int)->Void;

	/** A talaj felső éle a megadott x helyen (a talajon járóknak); null, ha nincs ott talaj. A PlayState állítja be. */
	public var groundTop:Float->Null<Float>;

	var t:Float = 0;
	var attackTimer:Float = 2;
	var attackIndex:Int = 0;
	var flashTimer:Float = 0;
	var level:Int;
	/** A talajon járó főellenség még nem ült rá a talajra (az első képkockában odaugrik). */
	var placed:Bool = false;
	/** Függőleges sebesség és a szakadék előtti várakozás ideje (talajon járó főellenségek). */
	var vy:Float = 0;
	var blockedT:Float = 0;
	static inline var GRAVITY:Float = 900;
	static inline var MAX_FALL:Float = 520;
	var animT:Float = 0;
	var prevX:Float = 0;
	/** A pillanatnyi forma neve (a végső főellenségnél változik), és hogy végső főellenség-e. */
	public var formName(default, null):String = "";
	public var isFinal(default, null):Bool = false;
	/** Átváltozás jelzése a PlayState felé: 0 = kezdődik, 1 = a forma kicserélődött, 2 = vége, 3 = megőrül (25% életerő alatt). */
	public var onMorph:(Boss, Int)->Void;
	/** Átváltozás: eltelt idő (-1 = nincs), a célforma, megtörtént-e már a csere; a következő átváltozásig hátralévő idő; megőrült-e. */
	var morphT:Float = -1;
	var morphTarget:BossKind = MOTHERSHIP;
	var morphSwapped:Bool = false;
	var formTimer:Float = 0;
	var berserk:Bool = false;
	/** Az óriás slime ugrásai közti idő, és hogy áll-e a talajon. */
	var slimeHop:Float = 1.5;
	var onGroundNow:Bool = false;
	/** Pislogás: > 0 = épp csukva (hátralévő idő); negatív = ennyi idő telt el a legutóbbi óta. */
	var blinkT:Float = -1;
	/** Lecsapás (kísértet): eltelt idő, -1 = nincs; a hős helyének pillanatképe. */
	var swoopT:Float = -1;
	var swoopX:Float = 0;
	var swoopY:Float = 0;
	var swoopLocked:Bool = false;
	/** Ugrás (izomtömeg): hátralévő idő, -1 = nincs; a pillanatnyi emelkedés (px) és az előző képkocka emelkedése. */
	var hopT:Float = -1;
	var hopLift:Float = 0;
	static inline var HOP_TIME:Float = 0.9;
	static inline var HOP_HEIGHT:Float = 70;

	public function new(level:Int, kind:BossKind = MOTHERSHIP)
	{
		super();
		this.level = level;
		isFinal = kind == FINAL;
		applyForm(kind);
		maxHp = hp = Config.bossBaseHp + level * Config.bossHpPerLevel;
		if (isFinal)
		{
			maxHp = hp = maxHp * 1.7; // a végső főellenség sokkal nehezebben pusztul el
			title = "THE FINAL SLIME";
			formTimer = 7; // az első átváltozásig óriás slime marad
		}
		// Beúszik a képernyő jobb széléről
		x = FlxG.camera.scroll.x + FlxG.width + 10;
		y = 30;
	}

	/**
	 * A főellenség kinézete és mérete a megadott formára. A végső főellenség ezzel változik át a korábbi főellenségek (és az
	 * óriás slime) között: a `kind` a pillanatnyi forma, így a mozgás és a támadások a formáé.
	 */
	function applyForm(k:BossKind):Void
	{
		kind = k;
		offset.set(0, 0);
		scale.set(1, 1);
		animation.destroyAnimations();
		switch (k)
		{
			case TANK:
				formName = "IRON CRAWLER";
				loadGraphic(PixelArt.bossTank(), true, PixelArt.TANK_W, PixelArt.TANK_H);
				animation.add("lights", [0, 1], 3);
			case GHOST:
				formName = "PHANTOM WYRM";
				loadGraphic(PixelArt.bossGhost(), true, PixelArt.GHOST_W, PixelArt.GHOST_H);
				animation.add("lights", [0, 1], 2);
			case BRUTE:
				formName = "MUSCLE MAW";
				loadGraphic(PixelArt.bossBrute(), true, PixelArt.BRUTE_W, PixelArt.BRUTE_H);
				animation.add("lights", [0, 1, 2, 3], 7); // járásciklus
				// A hitbox a törzs és a fej (a kinyújtott karok és a gömbök kilógnak belőle)
				width = 48;
				offset.x = (PixelArt.BRUTE_W - width) / 2;
			case FINAL:
				formName = "GIANT SLIME";
				loadGraphic(PixelArt.bossSlime(), true, PixelArt.BOSSSLIME_W, PixelArt.BOSSSLIME_H);
				animation.add("lights", [0, 1, 2, 3], 6); // hullámzó test
				width = 72;
				offset.x = (PixelArt.BOSSSLIME_W - width) / 2;
			case HOLLOW:
				formName = "THE HOLLOW MOON";
				loadGraphic(PixelArt.bossHollow(), true, PixelArt.HOLLOW_W, PixelArt.HOLLOW_H);
				animation.add("lights", [0, 1], 3); // lüktető repedés
			case PUFF:
				formName = "FLUFF GOLEM";
				loadGraphic(PixelArt.bossPuff(), true, PixelArt.PUFF_BOSS_W, PixelArt.PUFF_BOSS_H);
				animation.add("lights", [0, 1, 2, 3], 5); // járásciklus
				width = 52;
				offset.x = (PixelArt.PUFF_BOSS_W - width) / 2;
			case STRIDER:
				formName = "FUZZ STRIDER";
				loadGraphic(PixelArt.bossStrider(), true, PixelArt.STRIDER_W, PixelArt.STRIDER_H);
				animation.add("lights", [0, 1, 2, 3], 6); // járásciklus
				width = 64;
				offset.x = (PixelArt.STRIDER_W - width) / 2;
			case KILLER:
				formName = "THE KILLER";
				loadGraphic(PixelArt.bossKiller(), true, PixelArt.KILLER_W, PixelArt.KILLER_H);
				animation.add("lights", [0, 1, 2, 3], 7); // járásciklus
				width = 40;
				offset.x = (PixelArt.KILLER_W - width) / 2;
			case STALKER:
				formName = "THE WATCHER";
				loadGraphic(PixelArt.bossStalker(), true, PixelArt.STALKER_W, PixelArt.STALKER_H);
				animation.add("lights", [0, 1], 2.5);
			default:
				formName = "MOTHERSHIP";
				loadGraphic(PixelArt.boss(), true, PixelArt.BOSS_W, PixelArt.BOSS_H);
				animation.add("lights", [0, 1], 4);
		}
		if (!isFinal)
			title = formName;
		// A nyújtás/zsugorítás (nyálka-járás, átváltozás) a talp körül történjen
		origin.set(frameWidth / 2, frameHeight);
		animation.play("lights");
	}

	public function isPhase2():Bool
	{
		return hp < maxHp / 2;
	}

	/** Nem sebezhető: érkezés vagy átváltozás közben. */
	public function invulnerable():Bool
		return entering || morphT >= 0;

	/** A mozgás (amplitúdó, frekvencia) a formánál: az átváltozás ebből illeszti a mozgásfázist, hogy ne ugorjon a helye. */
	function moveParams(k:BossKind):Array<Float>
		return switch (k)
		{
			case TANK: [120, 0.55];
			case BRUTE: [90, 0.45];
			case FINAL: [110, 0.5];
			case PUFF: [100, 0.45];
			case STRIDER: [110, 0.4];
			case KILLER: [95, 0.5];
			case STALKER: [100, 0.6];
			case GHOST: [120, 0.7];
			case HOLLOW: [110, 0.5];
			default: [130, 0.8];
		}

	#if cheats
	/** Cheat: a végső főellenség azonnal új formára vált (ha éppen nem vált és nem érkezik). */
	public function cheatMorph():Void
	{
		if (isFinal && morphT < 0 && !entering)
			startMorph();
	}
	#end

	/** A végső főellenség új formát választ (az előzőtől eltérőt). */
	function startMorph():Void
	{
		var pool:Array<BossKind> = [FINAL, MOTHERSHIP, TANK, GHOST, BRUTE, STALKER, KILLER, STRIDER, PUFF, HOLLOW];
		pool.remove(kind);
		morphTarget = pool[FlxG.random.int(0, pool.length - 1)];
		morphT = 0;
		morphSwapped = false;
		formTimer = berserk ? FlxG.random.float(3.2, 4.4) : FlxG.random.float(9, 12);
		hopT = -1;
		hopLift = 0;
		swoopT = -1;
		if (onMorph != null)
			onMorph(this, 0);
	}

	/**
	 * Az átváltozás: a régi forma lila slime-má olvad (összenyomódik, színe elmegy), félúton kicserélődik a forma, majd az új
	 * kinyúlik a helyére, és a lila szín elhalványul. Közben nem sebezhető és nem támad.
	 */
	function updateMorph(dt:Float):Void
	{
		morphT += dt;
		var d1 = 0.6, d2 = 1.5;
		var k:Float;
		var sy:Float;
		if (morphT < d1)
		{
			var u = morphT / d1;
			k = u * u;
			scale.set(1 + 0.45 * k, 1 - 0.5 * k);
		}
		else
		{
			if (!morphSwapped)
			{
				morphSwapped = true;
				var cx = x + width / 2, bottom = y + height;
				applyForm(morphTarget);
				x = cx - width / 2;
				y = bottom - height;
				var left = FlxG.camera.scroll.x;
				var homeX = left + FlxG.width * 0.62 - width / 2;
				var m = moveParams(kind);
				t = Math.asin(Math.max(-1, Math.min(1, (x - homeX) / m[0]))) / m[1];
				attackIndex = 0;
				blinkT = -1;
				prevX = x;
				if (onMorph != null)
					onMorph(this, 1);
			}
			var u = Math.min(1, (morphT - d1) / (d2 - d1));
			k = 1 - u;
			sy = 1 - 0.5 * k + 0.14 * Math.sin(u * Math.PI * 3) * (1 - u);
			scale.set(1 + 0.45 * k, sy);
		}
		// Lila slime-szín: a színátvitel a lila felé tolódik, az átalakulás közepén a legerősebb
		var kk = Math.max(0, Math.min(1, k)) * 0.8;
		setColorTransform(1 - kk, 1 - kk, 1 - kk, 1, 176 * kk, 92 * kk, 214 * kk);
		if (morphT >= d2)
		{
			morphT = -1;
			scale.set(1, 1);
			setColorTransform();
			attackTimer = 0.9;
			if (onMorph != null)
				onMorph(this, 2);
		}
	}
	/** A talajon jár (követi a domborzatot), nem lebeg. */
	function grounded():Bool
	{
		return kind == TANK || kind == BRUTE || kind == STALKER || kind == KILLER || kind == STRIDER || kind == PUFF || kind == FINAL;
	}

	/** A sprite egy pontjának (sx a rajz bal széléről, balra néző állapotban) világ-x helye; ha tükrözve van, a másik oldalra esik. */
	function spriteX(sx:Float):Float
		return x - offset.x + (flipX ? frameWidth - sx : sx);

	/** A torkolat (ahonnan a lövések indulnak): harckocsinál az ágyúcső vége, kísértetnél és az izomtömegnél a száj, hajónál az alja. */
	public function muzzleX():Float
		return switch (kind)
		{
			case TANK: spriteX(2);
			case GHOST: spriteX(6);
			case BRUTE: spriteX(36);
			case STALKER: spriteX(28);
			case KILLER: spriteX(14);
			case STRIDER: spriteX(8);
			case PUFF: spriteX(36);
			default: x + width / 2;
		}

	public function muzzleY():Float
		return switch (kind)
		{
			case TANK: y + 10;
			case GHOST: y + 29;
			case BRUTE: y + 22;
			case STALKER: y + 53;
			case KILLER: y + 22;
			case HOLLOW: y + height / 2;
			case STRIDER: y + 52;
			case PUFF: y + 66;
			default: y + height - 4;
		}

	/** Aknavető / gömbhajítás kezdőpontja (`i` = 0 vagy 1): harckocsinál a torony, az izomtömegnél a két kéz. */
	public function launchX(i:Int):Float
		return switch (kind)
		{
			case TANK: spriteX(38);
			case BRUTE: spriteX(i == 0 ? 7 : 63);
			case STRIDER: spriteX(60); // a potroh hátulja
			default: x + width * 0.55;
		}

	public function launchY(i:Int):Float
		return switch (kind)
		{
			case TANK: y + 4;
			case BRUTE: y + (i == 0 ? 20 : 19);
			case STRIDER: y + 34;
			default: y + 4;
		}

	/** A nyálka szemeinek helye (`i` = 0..2): ezekből indul a hármas lövés. */
	public function eyeX(i:Int):Float
		return spriteX([12, 28, 44][i % 3]);

	public function eyeY(i:Int):Float
		return y + [15, 12, 14][i % 3];

	public function hit(damage:Float):Void
	{
		if (invulnerable())
			return;
		hp -= damage;
		flashTimer = 0.06;
		setColorTransform(1, 1, 1, 1, 150, 150, 150);
	}

	/** A támadási sorrend: fajtánként és fázisonként más. */
	function pattern():Array<Int>
	{
		var p2 = isPhase2();
		return switch (kind)
		{
			// Minden főellenségnek saját képességei vannak:
			// harckocsi: ágyúsorozat + aknavető; kísértet: legyező, denevérek + lecsapás a hősre;
			// izomtömeg: gömbhajítás + ugrás-földrengés (a hullámot át kell ugrani); nyálka: szemlövések + slime-ok köpése
			case TANK: p2 ? [3, 4, 3, 3, 4] : [3, 4];
			case GHOST: p2 ? [1, 6, 1, 2, 6] : [1, 6, 2, 1];
			case BRUTE: p2 ? [7, 4, 4, 7, 4] : [4, 7, 4];
			case STALKER: p2 ? [5, 8, 5, 5, 8] : [5, 8, 5];
			// bozontos gyilkos: rárontás a hősre + tüskeeső az égből (9)
			case KILLER: p2 ? [6, 9, 9, 6, 9] : [9, 6, 9];
			// szőrös pók: tüskék a hős alatt (10) és lassító háló (11)
			case STRIDER: p2 ? [10, 11, 10, 10, 11] : [10, 11, 10];
			// bolyhos óriás: pattogó pihegolyók (12) és fölfelé fújt, lassan szálló spórák (13)
			case PUFF: p2 ? [12, 13, 12, 12, 13] : [12, 13, 12];
			// óriás slime (a végső főellenség alapformája): slime-köpés (8) és ugrás-földrengés (7)
			case FINAL: p2 ? [7, 8, 8, 7] : [8, 7, 8];
			// kiüresedett hold: meteoreső-hívás (15), szilánk-sorozat (16), gravitációs örvény (17)
			case HOLLOW: p2 ? [16, 15, 16, 16, 17, 16, 16, 15] : [16, 16, 15, 16, 16, 17];
			default: p2 ? [0, 1, 0, 1, 2] : [0, 1];
		}
	}

	override public function update(elapsed:Float):Void
	{
		var left = FlxG.camera.scroll.x;
		var homeX = left + FlxG.width * 0.62 - width / 2;
		if (entering)
		{
			var nx = x - (grounded() ? 60 : 90) * elapsed;
			if (grounded() && !standable(nx))
			{
				// Szakadék előtt vár; ha sokáig nem jut tovább, a legközelebbi talajra kerül
				blockedT += elapsed;
				if (blockedT > 1.5)
				{
					x = nearestStandable(nx);
					blockedT = 0;
				}
			}
			else
			{
				x = nx;
				blockedT = 0;
			}
			if (grounded())
				followGround(elapsed);
			if (x <= homeX)
			{
				x = homeX;
				entering = false;
			}
		}
		else if (morphT >= 0)
		{
			// Átváltozás közben nem mozog és nem támad, csak a gravitáció hat rá
			updateMorph(elapsed);
			if (grounded())
				followGround(elapsed);
		}
		else
		{
			t += elapsed * (isPhase2() ? 1.4 : 1);
			switch (kind)
			{
				case TANK:
					// Gurul jobbra-balra a talajon, a terepet követve
					x = groundedX(homeX + Math.sin(t * 0.55) * 120, elapsed);
					followGround(elapsed);
				case BRUTE:
					// Nehézkesen lépked a talajon, kisebb úton, mint a harckocsi (az ugrás emelkedését előbb visszavesszük)
					x = groundedX(homeX + Math.sin(t * 0.45) * 90, elapsed);
					y += hopLift;
					followGround(elapsed);
				case FINAL:
					// Óriás slime: ide-oda csúszik és időnként nagyot ugrik
					x = groundedX(homeX + Math.sin(t * 0.5) * 110, elapsed);
					slimeHop -= elapsed;
					if (onGroundNow && slimeHop <= 0 && hopT < 0)
					{
						vy = -300;
						onGroundNow = false;
						slimeHop = FlxG.random.float(1.3, 2.1);
					}
					y += hopLift;
					followGround(elapsed);
				case PUFF:
					// Lomhán, ingadozva vonul a vastag lábain
					x = groundedX(homeX + Math.sin(t * 0.45) * 100, elapsed);
					followGround(elapsed);
				case STRIDER:
					// Hosszú lábain lassan, kimérten lépked
					x = groundedX(homeX + Math.sin(t * 0.4) * 110, elapsed);
					followGround(elapsed);
				case KILLER:
					// Nagy lépésekkel járőrözik a talajon (a rárontást a lecsapás-blokk adja hozzá)
					x = groundedX(homeX + Math.sin(t * 0.5) * 95, elapsed);
					followGround(elapsed);
				case STALKER:
					// A talajon vonaglik: hullámzó előre-hátra mozgás
					x = groundedX(homeX + Math.sin(t * 0.6) * 100 + Math.sin(t * 2.3) * 6, elapsed);
					followGround(elapsed);
				case HOLLOW:
					// Lassan, méltóságteljesen ringatózik az ég tetején
					x = homeX + Math.sin(t * 0.5) * 110;
					y = 26 + Math.sin(t * 1.1) * 14;
				case GHOST:
					// Tekergő, lassan hullámzó lebegés a képernyő jobb kétharmadán
					x = homeX + Math.sin(t * 0.7) * 120;
					y = 70 + Math.sin(t * 1.3) * 40 + Math.sin(t * 2.9) * 6;
				default:
					// Lebegés a képernyő jobb kétharmadán, nyolcas-szerű pályán
					x = homeX + Math.sin(t * 0.8) * 130;
					y = 30 + Math.sin(t * 1.7) * 12;
			}

			// Ugrás (izomtömeg): felszáll és visszaesik; landoláskor jön a földrengés-hullám
			if (hopT >= 0)
			{
				hopT -= elapsed;
				if (hopT <= 0)
				{
					hopT = -1;
					hopLift = 0;
					FlxG.camera.shake(0.012, 0.2);
					if (onAttack != null)
						onAttack(this, 7);
				}
				else
					hopLift = Math.sin((1 - hopT / HOP_TIME) * Math.PI) * HOP_HEIGHT;
			}
			y -= hopLift;

			// Lecsapás (kísértet): bepirosodva felkészül, aztán a hős helyére csap, és visszalebeg
			if (swoopT >= 0)
			{
				swoopT += elapsed;
				if (!swoopLocked && swoopT >= 0.5 && target != null)
				{
					swoopLocked = true;
					swoopX = target.x + target.width / 2 - width / 2;
					swoopY = Math.min(target.y + target.height / 2 - height / 2, 120);
				}
				var k:Float = swoopT < 0.5 ? 0 : (swoopT < 1.0 ? (swoopT - 0.5) / 0.5 : (swoopT < 1.15 ? 1 : Math.max(0, 1 - (swoopT - 1.15) / 0.7)));
				k = k * k * (3 - 2 * k);
				if (kind == GHOST)
				{
					x += (swoopX - x) * k;
					y += (swoopY - y) * k;
				}
				else
				{
					// Talajon járó (gyilkos): csak vízszintesen ront rá a hősre, és szakadékba nem rohan bele
					var nx = x + (swoopX - x) * k;
					if (standable(nx))
						x = nx;
				}
				if (flashTimer <= 0)
				{
					if (swoopT < 0.5 && Std.int(swoopT * 12) % 2 == 0)
						setColorTransform(1, 0.6, 0.6, 1, 70, 0, 0);
					else
						setColorTransform();
				}
				if (swoopT >= 1.85)
				{
					swoopT = -1;
					if (flashTimer <= 0)
						setColorTransform();
				}
			}

			// Végső főellenség: időnként új formára vált; 25% életerő alatt megőrül, és sűrűn váltogat
			if (isFinal)
			{
				var rage = hp < maxHp * 0.25;
				if (rage && !berserk)
				{
					berserk = true;
					formTimer = 0.2;
					if (onMorph != null)
						onMorph(this, 3);
				}
				else if (!rage && berserk)
					berserk = false; // (cheattel visszaállított életerőnél megnyugszik)
				formTimer -= elapsed;
				if (formTimer <= 0 && swoopT < 0 && hopT < 0)
					startMorph();
			}

			attackTimer -= elapsed;
			if (attackTimer <= 0 && morphT < 0)
			{
				// Pályánként gyorsabb támadássorozat (a 8. pályától áll meg a gyorsulás); megőrülve még gyorsabb
				attackTimer = (isPhase2() ? 1.05 : 1.7) * Math.max(0.55, 1 - level * 0.07) * (berserk ? 0.65 : 1) * (kind == HOLLOW ? 1.8 : 1);
				var pat = pattern();
				var a = pat[attackIndex % pat.length];
				attackIndex++;
				if (a == 6)
				{
					swoopT = 0;
					swoopLocked = false;
					attackTimer = Math.max(attackTimer, 2.2);
				}
				else if (a == 7)
				{
					hopT = HOP_TIME;
					attackTimer = Math.max(attackTimer, HOP_TIME + 0.9);
				}
				else if (onAttack != null)
					onAttack(this, a);
			}
		}

		// Az izomtömeg lába csak akkor lép, ha tényleg halad (állva és ugrás közben álló póz)
		if (kind == BRUTE || kind == KILLER || kind == STRIDER || kind == PUFF)
		{
			var moving = hopT < 0 && Math.abs(x - prevX) > 0.02;
			animation.paused = !moving;
			if (!moving)
				animation.frameIndex = 0;
			prevX = x;
		}

		// A bolyhos óriás időnként pislog: 0.15 mp-re a csukott szemű képkockák (4-7) látszanak
		if (kind == PUFF)
		{
			blinkT -= elapsed;
			if (blinkT <= -FlxG.random.float(2, 4))
				blinkT = 0.15;
			animation.frameIndex = animation.frameIndex % 4 + (blinkT > 0 ? 4 : 0);
		}

		// A nyálka járás közben nyúlik-zsugorodik a talpa körül
		animT += elapsed;
		if (kind == STALKER && morphT < 0)
		{
			var s = Math.sin(animT * 5);
			scale.set(1 + 0.05 * s, 1 - 0.07 * s);
		}

		// Mindig a hős felé néz (a rajz balra néz, ezért jobbra tükrözzük)
		if (target != null && target.alive)
		{
			var dx = target.x + target.width / 2 - (x + width / 2);
			if (dx > TURN_DEADZONE)
				flipX = true;
			else if (dx < -TURN_DEADZONE)
				flipX = false;
		}

		super.update(elapsed);

		if (flashTimer > 0)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
				setColorTransform();
		}
	}

	/** Van-e talaj a főellenség talpa alatt, ha a bal széle `nx`-nél van (bal láb, közép, jobb láb): szakadék fölé nem léphet. */
	function standable(nx:Float):Bool
	{
		if (groundTop == null)
			return true;
		for (k in [0.15, 0.5, 0.85])
			if (groundTop(nx + width * k) == null)
				return false;
		return true;
	}

	/**
	 * A talajon járó főellenség kívánt x helye (`desired`), szakadékot kerülve: ha ott nincs talaj, megáll (vagy ha már
	 * szakadék fölött áll, a legközelebbi szilárd talaj felé sétál), így sosem lebeg a semmi fölött.
	 */
	function groundedX(desired:Float, dt:Float):Float
	{
		if (standable(desired))
			return desired;
		if (standable(x))
			return x;
		var best = nearestStandable(x);
		var step = 120 * dt;
		return x + Math.max(-step, Math.min(step, best - x));
	}

	/** A legközelebbi olyan x (a `from` körül), ahol a főellenség talpa alatt talaj van; ha nincs, a `from`. */
	function nearestStandable(from:Float):Float
	{
		var d = 0;
		while (d <= 400)
		{
			if (standable(from - d))
				return from - d;
			if (standable(from + d))
				return from + d;
			d += 8;
		}
		return from;
	}

	/**
	 * Talajon járó főellenség: valódi gravitáció. Esik, amíg a talpa alatt nincs talaj; ráesve megáll, és ha a talaj emelkedik
	 * (lépcső), felkapaszkodik rá. A lebegő platformok nem számítanak. Ha mégis kiesne a pályáról, a legközelebbi talajra kerül.
	 */
	function followGround(dt:Float):Void
	{
		if (groundTop == null)
			return;
		if (!placed)
		{
			// Az első alkalommal ráteszi a talajra (ha az x-nél még nincs talaj, vár)
			var g0 = groundTop(x + width / 2);
			if (g0 == null)
				return;
			y = g0 - height + 1;
			vy = 0;
			placed = true;
			return;
		}
		vy = Math.min(vy + GRAVITY * dt, MAX_FALL);
		y += vy * dt;
		var top:Null<Float> = null;
		for (k in [0.15, 0.5, 0.85])
		{
			var gt = groundTop(x + width * k);
			if (gt != null && (top == null || gt < top))
				top = gt;
		}
		var wasOn = onGroundNow;
		onGroundNow = false;
		if (top != null && y + height >= top + 1)
		{
			// Nagy esés után (pl. az óriás slime ugrása) a föld megremeg
			if (!wasOn && vy > 250 && isFinal)
				FlxG.camera.shake(0.006, 0.1);
			y = top - height + 1;
			vy = 0;
			onGroundNow = true;
		}
		// Kiesett a pályáról: vissza a legközelebbi talajra
		if (y > FlxG.height + 30)
		{
			x = nearestStandable(x);
			y = 0;
			vy = 0;
		}
	}
}
