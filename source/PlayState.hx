package;

import Bullet.BulletKind;
import Enemy.EnemyKind;
import PowerUp.PowerKind;
import Quests.QuestType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	/** A kamera kezdő és maximális automatikus görgetési sebessége (px/s). */
	static inline var SCROLL_START:Float = 60;
	static inline var SCROLL_MAX:Float = 170;
	/** Ennyivel nő a görgetési sebesség másodpercenként. */
	static inline var SCROLL_ACCEL:Float = 1.5;
	/** A futás elején ennyi ideig áll a kamera, hogy legyen idő felkészülni. */
	static inline var START_GRACE:Float = 1.5;

	static inline var GROUND_Y:Float = 230;
	static inline var BULLET_SPEED:Float = 420;

	/** Ennyi százalék eséllyel jutalomdoboz egy új blokk. */
	static inline var REWARD_CHANCE:Float = 12;
	/** Bónuszok időtartama (valós másodperc, a lassítás nem nyújtja meg). */
	static inline var WEAPON_TIME:Float = 12;
	static inline var SHIELD_TIME:Float = 7;
	/** Ennyivel a sérthetetlenség lejárta előtt kezdődik a figyelmeztetés. */
	static inline var SHIELD_WARNING:Float = 2;
	static inline var SLOWMO_TIME:Float = 5;
	static inline var SLOWMO_SCALE:Float = 0.55;
	/** A lassításba be- és kiúszás ideje (valós mp). */
	static inline var SLOWMO_RAMP_IN:Float = 0.6;
	static inline var SLOWMO_RAMP_OUT:Float = 1.2;
	static inline var RAPID_COOLDOWN:Float = 0.07;
	static inline var FLAME_SPEED:Float = 230;
	/** A lézer újratöltési ideje (RAPID-dal rövidebb). */
	static inline var LASER_COOLDOWN:Float = 0.24;
	static inline var LASER_SPEED:Float = 900;
	/** A halálsugár újratöltési ideje (RAPID-dal rövidebb). */
	static inline var DEATHRAY_COOLDOWN:Float = 0.7;
	static inline var DEATHRAY_COOLDOWN_RAPID:Float = 0.32;
	static inline var LASER_COOLDOWN_RAPID:Float = 0.1;
	static inline var BONUS_POINTS:Int = 250;
	static inline var ENERGY_REFILL:Float = 35;
	/** Szakadékba esés vagy lemaradás ára. */
	static inline var FALL_DAMAGE:Float = 30;
	/** Sérülés utáni sérthetetlenség (valós mp). */
	static inline var HURT_TIME:Float = 1.3;
	/** Ez alatt az arány alatt piros az energiacsík. */
	static inline var LOW_ENERGY:Float = 0.2;
	static inline var ENERGY_BAR_W:Int = 70;
	static final SHIELD_COLORS:Array<FlxColor> = [PixelArt.CYAN, PixelArt.YELLOW, PixelArt.LIME, 0xfff277a8];

	/** Az ellenségfajták megjelenési ideje (mp a futás elejétől), az EnemyKind sorrendjében. */
	static final ENEMY_UNLOCK:Array<Float> = [20, 45, 75, 110];
	static final ENEMY_WARNING:Array<String> = ["SLIMES INCOMING!", "BATS INCOMING!", "TURRETS AHEAD!", "BOMBER DRONES!"];
	static inline var ENEMY_SHOT_SPEED:Float = 130;
	static inline var ENEMY_SHOT_DAMAGE:Float = 12;
	static inline var BOMB_DAMAGE:Float = 20;
	static inline var BOMB_RADIUS:Float = 28;
	/** Ráugrás után ekkora sebességgel pattan fel a hős. */
	static inline var STOMP_BOUNCE:Float = 260;

	static inline var MAX_CONTINUES:Int = 3;
	/** Ennyi másodperc van dönteni a folytatásról. */
	static inline var CONTINUE_TIME:Float = 10;
	/** A varázsgomba hatásának ideje (valós mp). */
	static inline var TRIP_TIME:Float = 7;
	static inline var BOSS_CONTACT_DAMAGE:Float = 25;

	var player:Player;
	var ground:FlxTypedGroup<FlxSprite>;
	var blocks:FlxTypedGroup<Block>;
	var bullets:FlxTypedGroup<Bullet>;
	var debris:FlxTypedGroup<FlxSprite>;
	var pickups:FlxTypedGroup<PowerUp>;
	var enemies:FlxTypedGroup<Enemy>;
	/** Ellenséges lövedékek és bombák (ID: 0 = lövedék, 1 = bomba). */
	var enemyShots:FlxTypedGroup<FlxSprite>;
	/** Ennyi ellenségfajta jelent már meg. */
	var enemyKindsUnlocked:Int = 0;
	var enemyTimer:Float = 0;
	var enemiesDefeated:Int = 0;

	// --- Pályák és főellenség ---
	/** PLAYING: normál játék; BOSS_INTRO: a kamera lassul, figyelmeztetés; BOSS: harc; CLEAR: pálya vége. */
	var levelState:String = "PLAYING";
	var levelStateTimer:Float = 0;
	var boss:Boss;
	var bossDrops:Int = 0;
	var bossBarBack:FlxSprite;
	var bossBar:FlxSprite;
	var bossName:FlxText;
	/** Az aktuális pálya görgetési szorzója. */
	var levelSpeed:Float = 1;
	/** Az aktuális pályán eltöltött idő. */
	var levelTime:Float = 0;

	// --- Folytatás (continue) ---
	var continuesLeft:Int = MAX_CONTINUES;
	var continuePrompt:Bool = false;
	var continueTimer:Float = 0;

	// --- Varázsgomba / hallucináció ---
	var shrooms:FlxTypedGroup<FlxSprite>;
	var shroomTimer:Float = 30;
	var tripTimer:Float = 0;
	var tripTime:Float = 0;
	var tripShader:HallucinationShader;
	/** A futás eleji küldetéslista (néhány másodperc után eltűnik). */
	var questPanel:QuestPanel;
	var questPanelTimer:Float = 5;
	/** Lebegő feliratok (+pont, bónusz neve) – képernyőhöz rögzítve. */
	var popups:FlxTypedGroup<FlxText>;

	var scoreText:FlxText;
	var infoText:FlxText;
	var energyLabel:FlxText;
	var energyPct:FlxText;
	var energyBack:FlxSprite;
	var energyTrail:FlxSprite;
	var energyFill:FlxSprite;
	/** Az utánfutó sáv aránya: sérüléskor lassan zárkózik fel a valós energiához. */
	var energyTrailRatio:Float = 1;
	/** Sérülés után a csík egy pillanatra felvillan. */
	var energyHit:Float = 0;
	var alarmTimer:Float = 0;
	var gameOverText:FlxText;
	var deathDim:FlxSprite;
	var scoreScaleTween:FlxTween;
	var scoreColorTween:FlxTween;
	/** Aktív bónuszok kijelzése a jobb felső sarokban: ikon + fogyó csík. */
	var powerSlots:Array<{
		icon:FlxSprite,
		name:FlxText,
		time:FlxText,
		back:FlxSprite,
		bar:FlxSprite,
		kind:Null<PowerKind>
	}> = [];
	/** Az előző képkockában aktív bónuszok hátralévő ideje (új felvétel / újratöltés felismeréséhez). */
	var lastPowerLeft = new Map<PowerKind, Float>();

	var scrollSpeed:Float = SCROLL_START;
	/** A nehézségi szint szorzója a görgetésre (a futás elején rögzítve). */
	var scrollMul:Float = 1;
	var nextGroundX:Float = 0;
	/** Az utoljára generált fő talajszakasz (a peremek sötétítéséhez). */
	var lastGround:FlxSprite;
	var lastGroundY:Float = GROUND_Y;
	var spawnTimer:Float = 1.5;
	var elapsedTotal:Float = 0;
	var blocksDestroyed:Int = 0;
	/** Megszerzett extra pont (szétlőtt dobozok, bónuszok). */
	var bonusPoints:Int = 0;
	/** A kijelzőn már megjelent extra pont: akkor nő, amikor a repülő "+pont" felirat odaér. */
	var shownBonus:Int = 0;
	var dead:Bool = false;

	/** Aktív kiegészítők (SPREAD / RAPID / HEAVY) hátralévő ideje (egymásra rakódnak). */
	var weaponTimers = new Map<PowerKind, Float>();
	/** Az aktuális alapfegyver (FLAME / LASER), null = sima lövedék (BULLET). */
	var baseWeapon:Null<PowerKind> = null;
	var baseWeaponTimer:Float = 0;
	/** A lézersugarak látványa (rövid ideig látszanak). */
	var beams:FlxTypedGroup<FlxSprite>;
	var laserTimer:Float = 0;
	var flameSoundTimer:Float = 0;
	var shieldTimer:Float = 0;
	var shieldTickTimer:Float = 0;
	var slowTimer:Float = 0;
	/** A belassulás előrehaladása (0..1). */
	var slowIn:Float = 0;

	override public function create():Void
	{
		super.create();
		bgColor = PixelArt.OUTLINE;
		FlxG.timeScale = 1;
		// Valós idő szerinti léptetés: alacsonyabb FPS-nél se lassuljon le a játék (alapból fix 1/60 mp/képkocka).
		// Egy képkocka legfeljebb 1/20 mp lehet, hogy egy akadásnál se repüljön át semmi a talajon.
		FlxG.fixedTimestep = false;
		FlxG.maxElapsed = 0.05;
		// Nagyobb ütközési tűrés: alacsony FPS-nél (nagyobb lépésekkel) se essen át semmi a talajon
		flixel.FlxObject.SEPARATE_BIAS = 10;

		// Az ablakhoz igazodó, arányos nagyítás (16:9, szükség esetén keskeny sávokkal); éles, nem simított pixelek
		FlxG.scaleMode = new RatioScaleMode();
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;

		// Az Alt az ugrás: a böngésző ne kapja meg (különben a menüsorra ugrana a fókusz).
		// A nyilak már alapból tiltva vannak, így az Alt+Bal nyíl sem lapoz vissza.
		if (FlxG.keys.preventDefaultKeys != null && !FlxG.keys.preventDefaultKeys.contains(FlxKey.ALT))
			FlxG.keys.preventDefaultKeys.push(FlxKey.ALT);

		Audio.init(); // ha a nyitóképernyő már legenerálta, nem csinál semmit
		Audio.playMusic();

		// A nehézség a futás elején rögzül (játék közben nem állítható)
		Settings.load();
		scrollMul = Settings.scrollMul();
		scrollSpeed = SCROLL_START * scrollMul * Quests.levelDef(0).speed;

		add(new Backdrop());

		ground = new FlxTypedGroup<FlxSprite>();
		blocks = new FlxTypedGroup<Block>();
		bullets = new FlxTypedGroup<Bullet>();
		debris = new FlxTypedGroup<FlxSprite>();
		pickups = new FlxTypedGroup<PowerUp>();
		popups = new FlxTypedGroup<FlxText>();

		enemies = new FlxTypedGroup<Enemy>();
		enemyShots = new FlxTypedGroup<FlxSprite>();
		beams = new FlxTypedGroup<FlxSprite>();

		shrooms = new FlxTypedGroup<FlxSprite>();

		add(ground);
		add(shrooms);
		add(pickups);
		add(blocks);
		add(enemies);
		add(debris);
		add(bullets);
		add(enemyShots);
		add(beams);

		// Zuhanó meteorok tűzcsóvája
		Block.onTrail = spawnEmber;
		tripShader = new HallucinationShader();

		// Pálya és küldetések: az 1. pályával indul; ha mind kész, jön a főellenség
		Quests.startLevel(0);
		Quests.onComplete = showQuestComplete;
		Quests.onAllComplete = startBossIntro;
		levelSpeed = Quests.levelDef(0).speed;

		// Kezdő biztonságos talaj, aztán generált szakaszok
		lastGround = addGround(0, 360, GROUND_Y);
		lastGroundY = GROUND_Y;
		nextGroundX = 360;
		generateGround();

		player = new Player(140, GROUND_Y - 40);
		player.onShoot = shoot;
		player.onDust = spawnDust;
		add(player);

		// Sötét vignetta a képernyő szélein (a világ fölött, a HUD alatt)
		var vignette = new FlxSprite(0, 0, PixelArt.vignette(FlxG.width, FlxG.height));
		vignette.scrollFactor.set(0, 0);
		add(vignette);

		createHud();

		questPanel = new QuestPanel(70);
		add(questPanel);

		add(popups);

		#if (js && test)
		// Csak automatikus tesztekhez: a böngészőből elérhető az állapot,
		// és fókusz nélkül (fejnélküli böngészőben) sem áll meg a játék
		js.Syntax.code("window.__game = {0}; window.__quests = {1}", this, Quests);
		FlxG.autoPause = false;
		#end
	}

	override public function update(elapsed:Float):Void
	{
		// F: teljes képernyő (natív buildben; böngészőben a Main kezeli közvetlenül a billentyűeseményből)
		#if !js
		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;
		#end
		if (FlxG.keys.justPressed.M)
			Settings.toggleMute();

		if (dead)
		{
			if (continuePrompt)
			{
				// Folytatás: visszaszámlálás, közben a játék áll
				continueTimer -= elapsed;
				updateContinueText();
				if (FlxG.keys.anyJustPressed([SPACE, ENTER, X, J]))
					doContinue();
				else if (FlxG.keys.justPressed.ESCAPE || continueTimer <= 0)
					gameOver();
				return;
			}
			super.update(elapsed);
			if (FlxG.keys.anyJustPressed([R, ENTER]))
				FlxG.resetState();
			else if (FlxG.keys.justPressed.ESCAPE)
				FlxG.switchState(TitleState.new);
			return;
		}

		// Szünet: P vagy ESC (a szünetmenü alatt a játék nem frissül)
		if (FlxG.keys.anyJustPressed([P, ESCAPE]))
		{
			openSubState(new PauseSubState());
			return;
		}

		// A bónuszok ideje valós időben fogy, lassítás alatt is
		var realElapsed = elapsed / FlxG.timeScale;

		elapsedTotal += elapsed;
		levelTime += elapsed;
		switch (levelState)
		{
			case "PLAYING":
				var top = SCROLL_MAX * scrollMul * levelSpeed;
				scrollSpeed = Math.min(top, scrollSpeed + SCROLL_ACCEL * scrollMul * levelSpeed * elapsed);
			case "BOSS_INTRO":
				// A kamera fokozatosan megáll a főellenség előtt
				scrollSpeed *= Math.pow(0.15, elapsed);
				if (scrollSpeed < 2)
					scrollSpeed = 0;
			default:
				scrollSpeed = 0;
		}
		if (elapsedTotal > START_GRACE)
			FlxG.camera.scroll.x += scrollSpeed * elapsed;

		generateGround();
		if (levelState == "PLAYING")
		{
			updateSpawner(elapsed);
			updateEnemySpawner(elapsed);
			updateShroomSpawner(elapsed);
		}
		updateLevel(realElapsed);
		updateTrip(realElapsed);

		// A futás eleji küldetéslista néhány másodperc után elhalványul
		if (questPanel.visible)
		{
			questPanelTimer -= realElapsed;
			var a = Math.min(1, questPanelTimer);
			questPanel.forEach(t -> t.alpha = a);
			if (questPanelTimer <= 0)
				questPanel.visible = false;
		}

		// Az ütközés csak FlxG.worldBounds-on belül működik, ami alapból csak a kezdő
		// képernyőt fedi le, ezért a görgető kamerával együtt kell mozgatni.
		FlxG.worldBounds.set(FlxG.camera.scroll.x - 100, -200, FlxG.width * 2 + 200, FlxG.height + 400);
		updatePowers(realElapsed);

		super.update(elapsed);

		// Zuhanó blokk eltalálta a játékost (az ütközés előtt nézzük)
		FlxG.overlap(player, blocks, onPlayerTouchBlock);

		FlxG.collide(player, ground);
		FlxG.collide(blocks, ground);
		FlxG.collide(blocks, blocks);
		// Csak a földet ért doboz akadály; a zuhanó (sérülés utáni sérthetetlenség alatt) átesik a hősön, nem nyomja le
		FlxG.overlap(player, blocks, null, (p:Player, b:Block) -> !b.isDangerous() && flixel.FlxObject.separate(p, b));
		FlxG.collide(pickups, ground);

		FlxG.overlap(player, pickups, collectPowerUp);
		FlxG.overlap(bullets, blocks, onBulletHitBlock);
		// A láng átcsaphat a talaj fölött, a többi lövedék a talajba csapódik
		FlxG.overlap(bullets, ground, (b:Bullet, _) -> if (b.kind != BulletKind.FLAME) b.kill());

		// Ellenségek: a földi fajták a talajon állnak, a repülők nem ütköznek vele
		FlxG.overlap(enemies, ground, null, (e:Enemy, g:FlxSprite) -> e.usesGround && flixel.FlxObject.separate(e, g));
		FlxG.overlap(bullets, enemies, onBulletHitEnemy);
		FlxG.overlap(player, enemies, onPlayerTouchEnemy);
		FlxG.overlap(enemyShots, player, onShotHitPlayer);
		FlxG.overlap(enemyShots, ground, (s:FlxSprite, _) -> shotHitGround(s));

		// Varázsgomba: hozzáérve hallucináció, lelőhető
		FlxG.overlap(player, shrooms, (p:Player, s:FlxSprite) -> eatShroom(s));
		FlxG.overlap(bullets, shrooms, (b:Bullet, s:FlxSprite) -> shootShroom(b, s));

		// Főellenség
		if (boss != null && boss.alive)
		{
			FlxG.overlap(bullets, boss, onBulletHitBoss);
			FlxG.overlap(player, boss, (p:Player, b:Boss) -> if (shieldTimer <= 0 && player.hurtTimer <= 0 && !b.entering) damagePlayer(BOSS_CONTACT_DAMAGE, false));
		}

		// Elért értékek a küldetésekhez (a túlélési idő pályánként számít)
		Quests.reach(SCORE, score());
		Quests.reach(SURVIVE, Std.int(levelTime));

		// A játékos nem futhat ki a képernyő jobb szélén
		var right = FlxG.camera.scroll.x + FlxG.width - player.width;
		if (player.x > right)
		{
			player.x = right;
			player.velocity.x = Math.min(player.velocity.x, 0);
		}

		// Lemaradt a bal szélen, vagy leesett egy szakadékba: energiát veszít, és visszakerül a pályára
		if (player.x + player.width < FlxG.camera.scroll.x || player.y > FlxG.height + 40)
		{
			if (damagePlayer(FALL_DAMAGE, true))
				respawnPlayer();
		}

		cleanup();
		updateHud(realElapsed);
	}

	// --- Pálya -----------------------------------------------------------

	function addGround(x:Float, w:Float, y:Float, ?h:Float):FlxSprite
	{
		var g = ground.recycle(FlxSprite);
		var platform = h != null;
		if (h == null)
			h = FlxG.height - y + 40; // a talaj a képernyő aljáig ér
		g.makeGraphic(Std.int(w), Std.int(h), FlxColor.TRANSPARENT, true);
		PixelArt.paintGround(g.pixels, Std.int(x), Std.int(y), platform);
		g.dirty = true;
		g.reset(x, y);
		g.immovable = true;
		return g;
	}

	function generateGround():Void
	{
		var limit = FlxG.camera.scroll.x + FlxG.width * 2;
		while (nextGroundX < limit)
		{
			// Szakadék, egyre gyakrabban
			var gap = FlxG.random.bool((25 + Math.min(elapsedTotal, 60) * 0.5) * Settings.gapMul());
			if (gap)
				nextGroundX += FlxG.random.int(40, 80);

			var w = FlxG.random.int(10, 30) * 8;
			var y = GROUND_Y - FlxG.random.int(0, 3) * 12;
			var g = addGround(nextGroundX, w, y);

			// Látható peremek sötétítése: szakadéknál teljes magasságban, szintkülönbségnél csak a kiálló rész
			if (lastGround != null)
			{
				var full = Std.int(FlxG.height);
				if (gap || y < lastGroundY)
					PixelArt.paintEdge(g.pixels, false, gap ? full : Std.int(lastGroundY - y));
				if (gap || y > lastGroundY)
					PixelArt.paintEdge(lastGround.pixels, true, gap ? full : Std.int(y - lastGroundY));
				g.dirty = lastGround.dirty = true;
			}
			lastGround = g;
			lastGroundY = y;

			// Néha egy lebegő platform a szakasz fölött
			if (FlxG.random.bool(35))
				addGround(nextGroundX + FlxG.random.int(0, Std.int(w / 2)), FlxG.random.int(4, 8) * 8, y - FlxG.random.int(50, 70), 8);

			nextGroundX += w;
		}
	}

	// --- Blokkok ----------------------------------------------------------

	function updateSpawner(elapsed:Float):Void
	{
		spawnTimer -= elapsed;
		if (spawnTimer > 0)
			return;

		// Idővel egyre sűrűbben jönnek
		var interval = Math.max(0.35, 1.3 - elapsedTotal * 0.012) * Settings.spawnIntervalMul();
		spawnTimer = FlxG.random.float(interval * 0.6, interval * 1.4);

		// Főleg a játékos előtt potyognak, hogy kerülgetni kelljen
		var x = FlxG.camera.scroll.x + FlxG.random.float(0.35, 1.1) * FlxG.width;
		var reward = FlxG.random.bool(Settings.rewardChance()) ? PowerUp.random() : null;
		blocks.recycle(Block, Block.new).spawn(x, FlxG.camera.scroll.y - 10, FlxG.random.float(60, 140), reward);
	}

	function onPlayerTouchBlock(p:Player, b:Block):Void
	{
		if (!b.isDangerous())
			return;
		// Sérthetetlenül a ránk eső doboz szétrobban (és pontot ér)
		if (shieldTimer > 0)
		{
			destroyBlock(b);
			return;
		}
		// Sérülés után rövid ideig a dobozok átesnek rajtunk
		if (player.hurtTimer > 0)
			return;
		// Energiát veszítünk, a doboz pont nélkül szétporlad
		damagePlayer(blockDamage(b), false);
		spawnDebris(b);
		b.kill();
	}

	/** Nagyobb doboz nagyobbat üt. */
	function blockDamage(b:Block):Float
	{
		return switch (Std.int(b.width))
		{
			case 16: 15;
			case 24: 30;
			default: 50;
		}
	}

	/**
	 * Energia levonása visszajelzéssel. Ha elfogy, vége a játéknak.
	 * @param fall szakadék/lemaradás (nincs hátralökés, utána a hívó visszahelyezi a játékost)
	 * @return true, ha a játékos életben maradt
	 */
	function damagePlayer(amount:Float, fall:Bool):Bool
	{
		amount = Math.round(amount * Settings.damageMul()); // nehézség szerint
		player.energy = Math.max(0, player.energy - amount);
		var cx = player.x + player.width / 2;
		var t = newPopup('-${Std.int(amount)}', 0xffff5a5a, cx, fall ? FlxG.camera.scroll.y + 60 : player.y);
		if (fall)
			t.x = Math.max(t.x, 20);
		FlxTween.tween(t, {y: t.y - 18, alpha: 0}, 0.9, {ease: FlxEase.quadIn, onComplete: _ -> t.kill()});
		energyHit = 0.4;
		Audio.play(fall ? "fall" : "hurt");

		if (player.energy <= 0)
		{
			die();
			return false;
		}

		FlxG.camera.shake(0.01, 0.15);
		FlxG.camera.flash(0x60ff3040, 0.15);
		player.hurtTimer = HURT_TIME;
		if (!fall)
			player.velocity.set(player.facing == LEFT ? 110 : -110, -200); // hátralökés
		return true;
	}

	/** Szakadék vagy lemaradás után a játékost egy biztos talajszakasz fölé tesszük, a képernyő bal harmadába. */
	function respawnPlayer():Void
	{
		var target = FlxG.camera.scroll.x + 140;
		var best:FlxSprite = null;
		ground.forEachAlive(g ->
		{
			if (g.height < 20) // lebegő platform nem jó
				return;
			if (g.x + g.width < FlxG.camera.scroll.x + 60 || g.x > FlxG.camera.scroll.x + FlxG.width - 60)
				return;
			if (best == null || Math.abs(g.x + g.width / 2 - target) < Math.abs(best.x + best.width / 2 - target))
				best = g;
		});

		var px = target, py = 40.0;
		if (best != null)
		{
			px = Math.max(best.x + 4, Math.min(target, best.x + best.width - player.width - 4));
			px = Math.max(px, FlxG.camera.scroll.x + 60);
			py = best.y - player.height - 40;
		}
		player.setPosition(px, py);
		player.velocity.set(0, 0);
		spawnDust(px + player.width / 2, py + player.height);
	}

	function onBulletHitBlock(bullet:Bullet, block:Block):Void
	{
		if (!block.alive || !bullet.alive)
			return;

		// A lézer átmegy mindenen, de minden dobozt csak egyszer sebez
		if (bullet.kind == BulletKind.LASER)
		{
			if (!bullet.firstHitOn(block))
				return;
			block.hit(bullet.damage);
			if (block.hp <= 0)
				destroyBlock(block);
			else
				Audio.play("hit");
			return;
		}

		var hpBefore = block.hp;
		block.hit(bullet.damage);
		// Átütés: ami sebzés megmaradt, azzal a lövedék továbbrepül
		bullet.damage -= hpBefore;
		if (bullet.damage <= 0)
			bullet.kill();
		if (block.hp <= 0)
			destroyBlock(block);
		else if (bullet.kind != BulletKind.FLAME) // a láng sistergése a lángszóró hangjában van
			Audio.play("hit");
	}

	/** Szétlőtt doboz: törmelék, extra pont, és ha jutalomdoboz volt, kipattan a bónusz. */
	function destroyBlock(block:Block):Void
	{
		spawnDebris(block);
		blocksDestroyed++;
		Quests.add(BOXES);
		var cx = block.x + block.width / 2;
		addBonus(blockPoints(block), cx, block.y);
		Audio.play("explode", 0.8);
		if (block.reward != null)
		{
			pickups.recycle(PowerUp, PowerUp.new).spawn(cx, block.y + block.height / 2, block.reward);
			FlxG.camera.flash(0x40ffcd75, 0.12);
			Audio.play("reward");
			Quests.add(GOLD_BOXES);
		}
		block.kill();
	}

	/** Nagyobb doboz több pontot ér. */
	function blockPoints(block:Block):Int
	{
		return switch (Std.int(block.width))
		{
			case 16: 25;
			case 24: 40;
			default: 60;
		}
	}

	function spawnDebris(block:Block):Void
	{
		var chip = PixelArt.chip(block.baseColor);
		for (i in 0...Std.int(4 + block.width / 4))
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chip);
			d.reset(block.x + FlxG.random.float(0, block.width), block.y + FlxG.random.float(0, block.height));
			d.velocity.set(FlxG.random.float(-120, 120), FlxG.random.float(-200, -40));
			d.acceleration.y = 600;
			d.alpha = 1;
		}
	}

	/** Kis porfelhő a játékos lábánál (ugrás, érkezés). */
	function spawnDust(x:Float, y:Float):Void
	{
		for (i in 0...4)
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(PixelArt.dust());
			d.reset(x - 1 + FlxG.random.float(-4, 4), y - 3);
			d.velocity.set(FlxG.random.float(-35, 35), FlxG.random.float(-25, -5));
			d.acceleration.y = 0;
			d.alpha = 0.9;
		}
	}

	// --- Ellenségek ----------------------------------------------------------

	/** Az idő múlásával új ellenségfajták jelennek meg (figyelmeztetéssel), és egyre sűrűbben jönnek. */
	function updateEnemySpawner(elapsed:Float):Void
	{
		if (enemyKindsUnlocked < ENEMY_UNLOCK.length && elapsedTotal >= ENEMY_UNLOCK[enemyKindsUnlocked])
		{
			showWarning(ENEMY_WARNING[enemyKindsUnlocked]);
			// Az új fajtából rögtön jön egy, hogy lássuk, mivel állunk szemben
			spawnEnemy(enemyKindsUnlocked);
			enemyKindsUnlocked++;
			enemyTimer = 3;
		}
		if (enemyKindsUnlocked == 0)
			return;

		enemyTimer -= elapsed;
		if (enemyTimer > 0)
			return;
		var interval = Math.max(2.0, 6 - (elapsedTotal - ENEMY_UNLOCK[0]) * 0.025) * Settings.spawnIntervalMul();
		enemyTimer = FlxG.random.float(interval * 0.7, interval * 1.3);

		// Az újabb fajták ritkábbak, a régebbiek gyakoribbak
		var kinds = [for (k in 0...enemyKindsUnlocked) k];
		var weights = [for (k in kinds) 4.0 - k * 0.8];
		spawnEnemy(FlxG.random.getObject(kinds, weights));
	}

	function spawnEnemy(kindIndex:Int):Void
	{
		var kind:EnemyKind = cast kindIndex;
		var x = FlxG.camera.scroll.x + FlxG.width + 10;
		var y = 0.0;
		switch (kind)
		{
			case SLIME:
				y = 120;
			case BAT:
				y = FlxG.random.float(60, 150);
			case TURRET:
				// Egy talajszakasz tetejére, a képernyőn kívül jobbra
				var spot:FlxSprite = null;
				ground.forEachAlive(g ->
				{
					if (spot == null && g.height > 20 && g.x > x - 20 && g.x < x + 200 && g.width >= 40)
						spot = g;
				});
				if (spot == null)
					return;
				x = spot.x + FlxG.random.float(8, spot.width - PixelArt.TURRET_SIZE - 8);
				y = spot.y - PixelArt.TURRET_SIZE;
			case DRONE:
				y = FlxG.random.float(28, 45);
		}
		var e = enemies.recycle(Enemy, Enemy.new);
		e.spawn(kind, x, y);
		e.target = player;
		e.onFire = enemyFire;
	}

	/** Ellenséges lövés a hős felé, vagy bomba a drónból. */
	function enemyFire(e:Enemy, type:Int):Void
	{
		var s = enemyShots.recycle(FlxSprite);
		s.ID = type;
		if (type == 0)
		{
			s.loadGraphic(PixelArt.enemyShot());
			var sx = e.flipX ? e.x + e.width : e.x;
			s.reset(sx - s.width / 2, e.y + 4);
			var dx = player.x + player.width / 2 - s.x, dy = player.y + player.height / 2 - s.y;
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			s.velocity.set(dx / len * ENEMY_SHOT_SPEED, dy / len * ENEMY_SHOT_SPEED);
			s.acceleration.set(0, 0);
			Audio.play("enemyshot", 0.7);
		}
		else
		{
			s.loadGraphic(PixelArt.bomb());
			s.reset(e.x + e.width / 2 - s.width / 2, e.y + e.height);
			s.velocity.set(e.velocity.x * 0.5, 30);
			s.acceleration.set(0, 400);
			Audio.play("bombdrop", 0.6);
		}
	}

	function onBulletHitEnemy(bullet:Bullet, e:Enemy):Void
	{
		if (!e.alive || !bullet.alive)
			return;
		if (bullet.kind == BulletKind.LASER)
		{
			// A lézer átmegy, minden ellenséget egyszer sebez
			if (!bullet.firstHitOn(e))
				return;
			e.hit(bullet.damage);
		}
		else
		{
			// Átütés: ami sebzés megmaradt, azzal a lövedék továbbrepül
			var hpBefore = e.hp;
			e.hit(bullet.damage);
			bullet.damage -= hpBefore;
			if (bullet.damage <= 0)
				bullet.kill();
		}
		if (e.hp <= 0)
			killEnemy(e, false);
		else if (bullet.kind != BulletKind.FLAME)
			Audio.play("hit");
	}

	/**
	 * Hős és ellenség találkozása: felülről ráugorva (ha lehet) elpusztítja,
	 * sérthetetlenül szétzúzza, egyébként energiát veszít.
	 */
	function onPlayerTouchEnemy(p:Player, e:Enemy):Void
	{
		if (!e.alive)
			return;
		var stomp = player.velocity.y > 0 && player.y + player.height - e.y < 8;
		if (stomp && e.stompable)
		{
			player.velocity.y = -STOMP_BOUNCE;
			killEnemy(e, true);
			return;
		}
		if (shieldTimer > 0)
		{
			killEnemy(e, false);
			return;
		}
		if (stomp)
		{
			// Nem ráugorható ellenség: visszapattan róla, de nem sérül
			player.velocity.y = -STOMP_BOUNCE * 0.7;
			return;
		}
		if (player.hurtTimer > 0)
			return;
		damagePlayer(e.contactDamage, false);
	}

	function killEnemy(e:Enemy, stomped:Bool):Void
	{
		var chip = PixelArt.chip(e.baseColor);
		for (i in 0...8)
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chip);
			d.reset(e.x + FlxG.random.float(0, e.width), e.y + FlxG.random.float(0, e.height));
			d.velocity.set(FlxG.random.float(-120, 120), FlxG.random.float(-200, -40));
			d.acceleration.y = 600;
			d.alpha = 1;
		}
		enemiesDefeated++;
		addBonus(stomped ? e.points * 2 : e.points, e.x + e.width / 2, e.y);
		Audio.play(stomped ? "stomp" : "explode", 0.8);
		Quests.add(ENEMIES);
		if (stomped)
			Quests.add(STOMPS);
		e.kill();
	}

	function onShotHitPlayer(s:FlxSprite, p:Player):Void
	{
		if (!s.alive)
			return;
		if (s.ID == 1)
		{
			explode(s);
			return;
		}
		s.kill();
		if (shieldTimer > 0 || player.hurtTimer > 0)
			return;
		damagePlayer(ENEMY_SHOT_DAMAGE, false);
	}

	function shotHitGround(s:FlxSprite):Void
	{
		if (!s.alive)
			return;
		if (s.ID == 1)
			explode(s);
		else
			s.kill();
	}

	/** Bomba robbanása: törmelék, rázkódás, és sebzés, ha a hős a közelben van. */
	function explode(s:FlxSprite):Void
	{
		var cx = s.x + s.width / 2, cy = s.y + s.height / 2;
		s.kill();
		var chip = PixelArt.chip(PixelArt.ORANGE);
		for (i in 0...12)
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chip);
			d.reset(cx, cy);
			d.velocity.set(FlxG.random.float(-160, 160), FlxG.random.float(-220, -40));
			d.acceleration.y = 600;
			d.alpha = 1;
		}
		FlxG.camera.shake(0.008, 0.15);
		Audio.play("bomb");
		var px = player.x + player.width / 2, py = player.y + player.height / 2;
		var dist = Math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
		if (dist < BOMB_RADIUS && shieldTimer <= 0 && player.hurtTimer <= 0)
			damagePlayer(BOMB_DAMAGE, false);
	}

	function removeText(t:FlxText):Void
	{
		remove(t, true);
		t.destroy();
	}

	/** Nagy, villogó figyelmeztetés a képernyő közepén (új ellenségfajta). */
	function showWarning(text:String):Void
	{
		var t = new FlxText(0, 96, FlxG.width, "WARNING!\n" + text, 16);
		t.alignment = CENTER;
		t.color = 0xffff5a5a;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		Audio.play("warning");
		FlxTween.num(0, 1, 2.2, {onComplete: _ -> FlxTween.tween(t, {alpha: 0}, 0.4, {onComplete: _ -> removeText(t)})},
			v -> t.visible = Std.int(v * 12) % 2 == 0 || v > 0.6);
	}

	/** Teljesített küldetés: felirat felülről, hang, jutalompont a pontszámhoz repülve. */
	function showQuestComplete(questText:String, points:Int):Void
	{
		var title = new FlxText(0, -40, FlxG.width, "QUEST COMPLETE!", 16);
		var sub = new FlxText(0, -20, FlxG.width, questText, 8);
		for (t in [title, sub])
		{
			t.alignment = CENTER;
			t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
			t.scrollFactor.set(0, 0);
			add(t);
		}
		title.color = PixelArt.YELLOW;
		sub.color = PixelArt.WHITE;
		Audio.play("clear");
		FlxG.camera.flash(0x40ffcd75, 0.25);
		FlxTween.tween(title, {y: 40}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(sub, {y: 60}, 0.4, {
			ease: FlxEase.backOut,
			onComplete: _ ->
			{
				addBonus(points, FlxG.camera.scroll.x + FlxG.width / 2, FlxG.camera.scroll.y + 74);
				for (t in [title, sub])
					FlxTween.tween(t, {alpha: 0}, 0.5, {startDelay: 1.8, onComplete: _ -> removeText(t)});
			}
		});
	}

	// --- Lövés --------------------------------------------------------------

	/** Aktív-e egy kiegészítő (SPREAD / RAPID / HEAVY). */
	inline function has(kind:PowerKind):Bool
	{
		return weaponTimers.exists(kind);
	}

	/**
	 * Lövés az aktuális alapfegyverrel (BULLET / FLAME / LASER – egyszerre csak egy), a kiegészítők
	 * fegyverenként másképp hatnak:
	 * - RAPID: lövedék és lézer gyorsabban tüzel, a láng messzebbre ér
	 * - SPREAD: 3 lövedék / 3 lézersugár / szélesebb lángcsóva
	 * - HEAVY: nagyobb sebzés (a sima lövedék átüt)
	 */
	function shoot(x:Float, y:Float, dx:Float, dy:Float):Void
	{
		var spread = has(SPREAD), heavy = has(HEAVY), rapid = has(RAPID);

		switch (baseWeapon)
		{
			case FLAME:
				// Előre lőve kicsit felfelé dől, hogy ne a földet égesse
				var cone = spread ? 0.5 : 0.22;
				var lift = dy == 0 ? cone * 0.5 : 0;
				for (i in 0...2)
				{
					var a = FlxG.random.float(-cone, cone) - lift;
					var r = dx < 0 ? -a : a;
					fireFlame(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), heavy, rapid);
				}
				if (flameSoundTimer <= 0)
				{
					flameSoundTimer = 0.12;
					Audio.play("flame", 0.6);
				}

			case LASER:
				if (laserTimer > 0)
					return;
				laserTimer = rapid ? LASER_COOLDOWN_RAPID : LASER_COOLDOWN;
				for (r in fanAngles(spread, dx, dy))
					fireLaser(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), heavy ? 3 : 1);
				Audio.play("laser", 0.8);

			case DEATHRAY:
				if (laserTimer > 0)
					return;
				laserTimer = rapid ? DEATHRAY_COOLDOWN_RAPID : DEATHRAY_COOLDOWN;
				for (r in fanAngles(spread, dx, dy))
					fireDeathRay(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r));
				Audio.play("deathray");

			default:
				for (r in fanAngles(spread, dx, dy))
					fireBullet(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), heavy ? 3 : 1, heavy);
				// Gyorstüzelésnél halkabb, hogy ne legyen fárasztó
				Audio.play(heavy ? "heavy" : (spread ? "spread" : "shoot"), rapid ? 0.55 : 1);
		}
	}

	/**
	 * A legyező szögei. Előre lőve felfelé dől (különben az alsó lövedék rögtön a földbe csapódna),
	 * felfelé/átlósan szimmetrikus. Balra lőve tükrözzük, hogy akkor is felfelé szórjon.
	 */
	function fanAngles(spread:Bool, dx:Float, dy:Float):Array<Float>
	{
		if (!spread)
			return [0.0];
		var angles = dy != 0 ? [-0.21, 0.0, 0.21] : [0.0, -0.18, -0.36];
		return dx < 0 ? [for (a in angles) -a] : angles;
	}

	function fireBullet(x:Float, y:Float, dx:Float, dy:Float, damage:Int, heavy:Bool):Void
	{
		// Grafika az irány szerint: vízszintes, függőleges vagy átlós (balra tükrözve)
		var graphic = if (heavy) PixelArt.heavyBullet(); else if (Math.abs(dy) < 0.38) PixelArt.bulletH(); else if (Math.abs(dx) < 0.38)
			PixelArt.bulletV(); else PixelArt.bulletD();
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(graphic);
		b.setup(BulletKind.NORMAL, damage);
		b.flipX = dx < 0;
		b.reset(x - b.width / 2, y - b.height / 2);
		var speed = heavy ? BULLET_SPEED * 0.8 : BULLET_SPEED;
		// Előre (vízszintesen vagy átlósan) lőve a lövedék örökli a futás sebességének felét
		b.velocity.set(dx * speed + (Math.abs(dx) > 0.5 ? player.velocity.x * 0.5 : 0), dy * speed);
	}

	/**
	 * Lángrészecske: lassul, nő, elhalványul. HEAVY: nagyobb és erősebb;
	 * RAPID: gyorsabb és tovább él, vagyis messzebbre ér a csóva.
	 */
	function fireFlame(x:Float, y:Float, dx:Float, dy:Float, heavy:Bool, rapid:Bool):Void
	{
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(PixelArt.flame(), true, PixelArt.FLAME_SIZE, PixelArt.FLAME_SIZE);
		var life = FlxG.random.float(0.3, 0.42) * (heavy ? 1.2 : 1) * (rapid ? 1.35 : 1);
		b.setup(BulletKind.FLAME, heavy ? 2 : 1, life, heavy ? 2.3 : 1.7);
		b.flipX = false;
		b.reset(x - b.width / 2 + dx * 6, y - b.height / 2 + dy * 6);
		var speed = FLAME_SPEED * FlxG.random.float(0.85, 1.15) * (rapid ? 1.5 : 1);
		b.velocity.set(dx * speed + player.velocity.x * 0.6, dy * speed);
		b.drag.set(160, 160);
	}

	/** Lézerlövedék: nagyon gyors, minden dobozon és ellenségen átmegy (mindegyiket egyszer sebzi). */
	function fireLaser(x:Float, y:Float, dx:Float, dy:Float, damage:Int):Void
	{
		var graphic = if (Math.abs(dy) < 0.38) PixelArt.laserH(); else if (Math.abs(dx) < 0.38) PixelArt.laserV(); else PixelArt.laserD();
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(graphic);
		b.setup(BulletKind.LASER, damage);
		b.flipX = dx < 0;
		// A lövedék a torkolattól indul előre
		b.reset(x - b.width / 2 + dx * b.width / 2, y - b.height / 2 + dy * b.height / 2);
		b.velocity.set(dx * LASER_SPEED, dy * LASER_SPEED);
	}

	/**
	 * Halálsugár: azonnali, a lövés pillanatában elpusztít minden dobozt és ellenséget az útjában
	 * (sebzéstől függetlenül), egészen a talajig vagy a képernyő széléig.
	 */
	function fireDeathRay(x:Float, y:Float, dx:Float, dy:Float):Void
	{
		var maxLen = FlxG.width * 1.2;
		var len = 0.0;
		var hitBlocks:Array<Block> = [];
		var hitEnemies:Array<Enemy> = [];
		while (len < maxLen)
		{
			var px = x + dx * len, py = y + dy * len;
			if (py < FlxG.camera.scroll.y - 8 || pointHits(ground, px, py))
				break;
			blocks.forEachAlive(b -> if (!hitBlocks.contains(b) && contains(b, px, py)) hitBlocks.push(b));
			enemies.forEachAlive(e -> if (!hitEnemies.contains(e) && contains(e, px, py)) hitEnemies.push(e));
			len += 3;
		}

		// Amin áthalad, az egy lövésre elpusztul
		for (b in hitBlocks)
			destroyBlock(b);
		for (e in hitEnemies)
			killEnemy(e, false);

		// Látvány: a sugár hosszára nyújtott, elforgatott csík, ami elhalványul (HEAVY-vel vastagabb)
		var beam = beams.recycle(FlxSprite);
		beam.loadGraphic(PixelArt.deathRayBeam());
		beam.reset(x, y - beam.height / 2);
		beam.origin.set(0, beam.height / 2);
		beam.scale.set(Math.max(1, len), has(HEAVY) ? 2 : 1);
		beam.angle = Math.atan2(dy, dx) * 180 / Math.PI;
		beam.alpha = 1;
		FlxTween.cancelTweensOf(beam);
		FlxTween.tween(beam, {alpha: 0}, 0.22, {onComplete: _ -> beam.kill()});
		FlxG.camera.shake(0.004, 0.08);
	}

	static inline function contains(s:FlxSprite, px:Float, py:Float):Bool
	{
		return px >= s.x && px <= s.x + s.width && py >= s.y && py <= s.y + s.height;
	}

	function pointHits(group:FlxTypedGroup<FlxSprite>, px:Float, py:Float):Bool
	{
		for (g in group.members)
			if (g != null && g.alive && contains(g, px, py))
				return true;
		return false;
	}

	// --- Bónuszok -------------------------------------------------------------

	function collectPowerUp(p:Player, pu:PowerUp):Void
	{
		if (!pu.alive)
			return;
		pu.kill();
		var kind = pu.kind;
		var color = PixelArt.powerColor(kind);
		var cx = player.x + player.width / 2;

		switch (kind)
		{
			case FLAME | LASER | DEATHRAY:
				// Alapfegyver: lecseréli az előzőt (ugyanazt újra felvéve az ideje visszatöltődik)
				baseWeapon = kind;
				baseWeaponTimer = WEAPON_TIME;
				Quests.reach(WEAPON_STACK, weaponStack());
				Audio.play("powerup");
			case SPREAD | RAPID | HEAVY:
				// Kiegészítő: egymásra rakódnak, bármelyik alapfegyverrel működnek
				weaponTimers.set(kind, WEAPON_TIME);
				Quests.reach(WEAPON_STACK, weaponStack());
				Audio.play("powerup");
			case SHIELD:
				// Saját zene szól alatta (újra felvéve csak az idő töltődik vissza)
				if (shieldTimer <= 0)
					Audio.startShieldMusic();
				shieldTimer = SHIELD_TIME;
				shieldTickTimer = 0;
				Audio.play("shield");
			case SLOWMO:
				// Fokozatosan lassul be (updatePowers); újra felvéve csak az idő töltődik vissza, nem ugrik vissza
				if (slowTimer <= 0)
					slowIn = 0;
				slowTimer = SLOWMO_TIME;
				Audio.play("slowmo");
			case BONUS:
				addBonus(BONUS_POINTS, cx, player.y - 8);
				Audio.play("coin");
			case ENERGY:
				player.energy = Math.min(Player.MAX_ENERGY, player.energy + ENERGY_REFILL);
				Audio.play("heal");
			case NUKE:
				nuke();
			case SHROOM:
				// nem jutalom (a gomba a pályán van), ide nem jut el
		}

		Quests.add(POWERUPS);
		announce(PowerUp.label(kind), color, cx, player.y - 4);
		FlxG.camera.flash(((color : Int) & 0xffffff) | 0x50000000, 0.15);
	}

	/** Egyszerre aktív fegyverbónuszok száma (alapfegyver + kiegészítők) a küldetéshez. */
	function weaponStack():Int
	{
		var n = baseWeapon != null ? 1 : 0;
		for (k in weaponTimers.keys())
			n++;
		return n;
	}

	/** Bónuszok idejének léptetése és hatásaik (fegyver, sérthetetlenség villogása, lassítás). */
	function updatePowers(dt:Float):Void
	{
		if (baseWeapon != null)
		{
			baseWeaponTimer -= dt;
			if (baseWeaponTimer <= 0)
			{
				baseWeapon = null; // vissza a sima lövedékre
				Audio.play("powerdown");
			}
		}
		for (k in PowerUp.MODS)
		{
			if (!weaponTimers.exists(k))
				continue;
			var left = weaponTimers.get(k) - dt;
			if (left <= 0)
			{
				weaponTimers.remove(k);
				Audio.play("powerdown");
			}
			else
				weaponTimers.set(k, left);
		}
		laserTimer -= dt;
		flameSoundTimer -= dt;

		// A láng folyamatosan, sűrűn "tüzel" (a RAPID nála a hatótávot növeli); a lézer saját újratöltéssel (laserTimer)
		var rapid = has(RAPID);
		player.shootCooldown = switch (baseWeapon)
		{
			case FLAME: 0.045;
			case LASER | DEATHRAY: 0.05;
			default: rapid ? RAPID_COOLDOWN : Player.SHOOT_COOLDOWN;
		}

		if (shieldTimer > 0)
		{
			shieldTimer -= dt;
			// Szivárványos villogás; a vége előtt pislog, hogy látsszon, mindjárt lejár
			player.color = SHIELD_COLORS[Std.int(shieldTimer * 12) % SHIELD_COLORS.length];
			player.visible = shieldTimer > SHIELD_WARNING || Std.int(shieldTimer * 16) % 2 == 0;

			// Lejárat előtti figyelmeztetés: gyorsuló ketyegés; látványban csak a HUD-sáv villog (updateHud)
			if (shieldTimer <= SHIELD_WARNING && shieldTimer > 0)
			{
				shieldTickTimer -= dt;
				if (shieldTickTimer <= 0)
				{
					shieldTickTimer = 0.08 + shieldTimer * 0.12; // egyre sűrűbb
					Audio.play("tick");
				}
			}
			if (shieldTimer <= 0)
			{
				player.color = FlxColor.WHITE;
				player.visible = true;
				Audio.stopShieldMusic();
				Audio.play("powerdown");
			}
		}
		else
		{
			// Sérülés utáni sérthetetlenség alatt gyorsan pislog
			player.visible = player.hurtTimer <= 0 || Std.int(player.hurtTimer * 20) % 2 == 0;
		}

		if (slowTimer > 0)
		{
			slowTimer -= dt;
			// Átmenet: felvételkor SLOWMO_RAMP_IN alatt lassul be, a végén SLOWMO_RAMP_OUT alatt gyorsul vissza
			slowIn = Math.min(1, slowIn + dt / SLOWMO_RAMP_IN);
			var out = Math.max(0, Math.min(1, slowTimer / SLOWMO_RAMP_OUT));
			var amount = FlxEase.quadInOut(slowIn) * FlxEase.quadInOut(out);
			FlxG.timeScale = 1 - (1 - SLOWMO_SCALE) * amount;
			if (slowTimer <= 0)
				FlxG.timeScale = 1;
		}
	}

	// --- Pontozás és feliratok ----------------------------------------------

	function score():Int
	{
		return Std.int(FlxG.camera.scroll.x / 10) + bonusPoints;
	}

	/**
	 * Extra pont: a "+N" felirat felugrik a forrásnál, majd a pontszám-kijelzőhöz repül.
	 * A kijelzett pontszám csak akkor nő, amikor odaér (és a kijelző felvillan).
	 */
	function addBonus(points:Int, worldX:Float, worldY:Float):Void
	{
		bonusPoints += points;

		var t = newPopup('+$points', PixelArt.YELLOW, worldX, worldY);
		var startY = t.y;
		FlxTween.tween(t, {y: startY - 14}, 0.3, {
			ease: FlxEase.quadOut,
			onComplete: _ -> FlxTween.tween(t, {x: scoreText.x + scoreText.width - t.width / 2, y: scoreText.y}, 0.45, {
				ease: FlxEase.quadIn,
				onComplete: _ ->
				{
					t.kill();
					shownBonus += points;
				Audio.play("blip", 0.6);
					bumpScore();
				}
			})
		});
	}

	/** Bónusz neve a játékos fölött: felúszik és elhalványul. */
	function announce(text:String, color:FlxColor, worldX:Float, worldY:Float):Void
	{
		var t = newPopup(text, color, worldX, worldY - 10);
		FlxTween.tween(t, {y: t.y - 22, alpha: 0}, 1.1, {
			ease: FlxEase.quadIn,
			onComplete: _ -> t.kill()
		});
	}

	function newPopup(text:String, color:FlxColor, worldX:Float, worldY:Float):FlxText
	{
		var t = popups.recycle(FlxText, () ->
		{
			var t = new FlxText(0, 0, 0, "", 8);
			t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
			t.scrollFactor.set(0, 0);
			t;
		});
		FlxTween.cancelTweensOf(t);
		t.text = text;
		t.color = color;
		t.alpha = 1;
		// Világkoordinátából képernyő-koordináta (a felirat a kamerához van rögzítve)
		t.reset(Math.round(worldX - FlxG.camera.scroll.x - t.width / 2), Math.round(worldY - FlxG.camera.scroll.y - t.height));
		return t;
	}

	/** A pontszám-kijelző megugrik és sárgán felvillan. */
	function bumpScore():Void
	{
		if (scoreScaleTween != null)
			scoreScaleTween.cancel();
		if (scoreColorTween != null)
			scoreColorTween.cancel();
		scoreText.scale.set(1.6, 1.6);
		scoreScaleTween = FlxTween.tween(scoreText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});
		scoreColorTween = FlxTween.color(scoreText, 0.45, PixelArt.YELLOW, PixelArt.WHITE);
	}

	// --- HUD -------------------------------------------------------------------

	/** Energiacsík: 20% fölött zöld, alatta piros és villog; a frissen elvesztett rész fehéren fogy el. */
	function updateEnergyBar(dt:Float):Void
	{
		var ratio = player.energy / Player.MAX_ENERGY;
		if (ratio >= energyTrailRatio)
			energyTrailRatio = ratio; // töltődéskor nincs utánfutás
		else
			energyTrailRatio = Math.max(ratio, energyTrailRatio - dt * 0.5);

		energyFill.scale.x = ratio;
		energyTrail.scale.x = energyTrailRatio;
		energyTrail.visible = energyTrailRatio > ratio;

		var low = ratio <= LOW_ENERGY;
		// Alacsony energiánál figyelmeztető csipogás
		if (low && !dead)
		{
			alarmTimer -= dt;
			if (alarmTimer <= 0)
			{
				alarmTimer = 0.9;
				Audio.play("alarm");
			}
		}
		else
			alarmTimer = 0;
		energyFill.color = low ? 0xffe8303c : PixelArt.GREEN;
		energyLabel.color = low ? 0xffff5a5a : PixelArt.WHITE;
		energyPct.text = Std.int(Math.ceil(ratio * 100)) + "%";
		energyPct.color = energyLabel.color;

		// Alacsony energiánál a csík pulzál; sérüléskor a felirat pirosan-fehéren villog
		var blinkOn = !low || Std.int(FlxG.game.ticks / 150) % 2 == 0;
		energyFill.alpha = blinkOn ? 1 : 0.45;
		if (energyHit > 0)
		{
			energyHit -= dt;
			var c:FlxColor = Std.int(energyHit * 20) % 2 == 0 ? FlxColor.WHITE : 0xffff5a5a;
			energyLabel.color = energyPct.color = c;
		}
	}

	function createHud():Void
	{
		scoreText = new FlxText(6, 4, 0, "SCORE 0", 8);
		scoreText.color = PixelArt.WHITE;
		scoreText.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		scoreText.scrollFactor.set(0, 0);
		add(scoreText);

		// Energiacsík a pontszám alatt: sötét keret, fehér "utánfutó" sáv (a frissen elvesztett rész), színes kitöltés
		energyLabel = new FlxText(6, 16, 0, "ENERGY", 8);
		energyLabel.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		var barX = 48, barY = 20;
		energyBack = new FlxSprite(barX - 1, barY - 1).makeGraphic(ENERGY_BAR_W + 2, 7, PixelArt.OUTLINE);
		energyBack.pixels.fillRect(new openfl.geom.Rectangle(1, 1, ENERGY_BAR_W, 5), PixelArt.DARK_GRAY);
		energyBack.dirty = true;
		energyTrail = new FlxSprite(barX, barY).makeGraphic(ENERGY_BAR_W, 5, FlxColor.WHITE);
		energyFill = new FlxSprite(barX, barY).makeGraphic(ENERGY_BAR_W, 5, FlxColor.WHITE);
		// Felső világos csík a kitöltésen a pixeles térhatásért
		energyFill.pixels.fillRect(new openfl.geom.Rectangle(0, 0, ENERGY_BAR_W, 1), 0xffd8ffd8);
		energyFill.dirty = true;
		energyPct = new FlxText(barX + ENERGY_BAR_W + 4, 16, 0, "100%", 8);
		energyPct.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		for (s in ([energyLabel, energyBack, energyTrail, energyFill, energyPct] : Array<FlxSprite>))
		{
			s.origin.set(0, 0);
			s.scrollFactor.set(0, 0);
			add(s);
		}

		infoText = new FlxText(110, 4, 0, "", 8);
		infoText.color = PixelArt.LIGHT_GRAY;
		infoText.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		infoText.scrollFactor.set(0, 0);
		add(infoText);

		// Bónusz-slotok a jobb felső sarokban: ikon, név, hátralévő másodperc és fogyó csík.
		// Egyszerre legfeljebb 3 lehet aktív: fegyver, sérthetetlenség, lassítás.
		var slotW = 96;
		var textX = PixelArt.POWER_SIZE + 3;
		var barW = slotW - textX;
		for (i in 0...7)
		{
			var x = FlxG.width - 6 - slotW;
			var y = 4 + i * 15;
			var icon = new FlxSprite(x, y);
			var name = new FlxText(x + textX - 1, y - 3, 0, "", 8);
			var time = new FlxText(x + textX, y - 3, barW, "", 8);
			time.alignment = RIGHT;
			time.color = PixelArt.WHITE;
			for (t in [name, time])
				t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
			var back = new FlxSprite(x + textX, y + 9).makeGraphic(barW, 3, PixelArt.OUTLINE);
			var bar = new FlxSprite(back.x, back.y).makeGraphic(barW, 3, FlxColor.WHITE);
			bar.origin.set(0, 0);
			for (s in ([icon, back, bar, name, time] : Array<FlxSprite>))
			{
				s.scrollFactor.set(0, 0);
				s.visible = false;
				add(s);
			}
			powerSlots.push({icon: icon, name: name, time: time, back: back, bar: bar, kind: null});
		}

		// A főellenség neve és életerő-csíkja (felül középen, csak a harc alatt látszik)
		bossName = new FlxText(0, 30, FlxG.width, "", 8);
		bossName.alignment = CENTER;
		bossName.color = PixelArt.WHITE;
		bossName.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		var bossBarW = 180;
		bossBarBack = new FlxSprite((FlxG.width - bossBarW) / 2 - 1, 42).makeGraphic(bossBarW + 2, 6, PixelArt.OUTLINE);
		bossBar = new FlxSprite((FlxG.width - bossBarW) / 2, 43).makeGraphic(bossBarW, 4, FlxColor.WHITE);
		bossBar.origin.set(0, 0);
		for (s in ([bossName, bossBarBack, bossBar] : Array<FlxSprite>))
		{
			s.scrollFactor.set(0, 0);
			s.visible = false;
			add(s);
		}

		// Sötét háttér a continue / game over felirat alá, hogy olvasható legyen
		deathDim = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xc0050308);
		deathDim.scrollFactor.set(0, 0);
		deathDim.visible = false;
		add(deathDim);

		gameOverText = new FlxText(0, 80, FlxG.width, "", 16);
		gameOverText.color = PixelArt.YELLOW;
		gameOverText.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		gameOverText.alignment = CENTER;
		gameOverText.scrollFactor.set(0, 0);
		gameOverText.visible = false;
		add(gameOverText);
	}

	function updateHud(dt:Float):Void
	{
		updateEnergyBar(dt);

		scoreText.text = 'SCORE ${Std.int(FlxG.camera.scroll.x / 10) + shownBonus}';
		scoreText.origin.set(0, scoreText.height / 2); // a megugrás balról, középmagasságból
		infoText.text = 'LEVEL ${Quests.level + 1}   QUESTS ${Quests.completedCount()}/${Quests.goals.length}   METEORS $blocksDestroyed   CONTINUES $continuesLeft';

		var active:Array<{kind:PowerKind, left:Float, total:Float}> = [];
		if (baseWeapon != null)
			active.push({kind: baseWeapon, left: baseWeaponTimer, total: WEAPON_TIME});
		for (k in PowerUp.MODS)
			if (weaponTimers.exists(k))
				active.push({kind: k, left: weaponTimers.get(k), total: WEAPON_TIME});
		if (shieldTimer > 0)
			active.push({kind: SHIELD, left: shieldTimer, total: SHIELD_TIME});
		if (slowTimer > 0)
			active.push({kind: SLOWMO, left: slowTimer, total: SLOWMO_TIME});
		if (tripTimer > 0)
			active.push({kind: SHROOM, left: tripTimer, total: TRIP_TIME});

		for (i in 0...powerSlots.length)
		{
			var slot = powerSlots[i];
			var on = i < active.length;
			slot.icon.visible = slot.name.visible = slot.time.visible = slot.back.visible = slot.bar.visible = on;
			if (!on)
			{
				slot.kind = null;
				continue;
			}
			var a = active[i];
			if (slot.kind != a.kind)
			{
				slot.kind = a.kind;
				var color = PixelArt.powerColor(a.kind);
				slot.icon.loadGraphic(PixelArt.powerUp(a.kind), true, PixelArt.POWER_SIZE, PixelArt.POWER_SIZE);
				slot.name.text = PowerUp.shortName(a.kind);
				slot.name.color = color;
				slot.bar.color = color;
			}
			// Frissen felvett vagy újratöltött bónusznál az ikon megugrik (a slotok elcsúszásánál nem)
			if (!lastPowerLeft.exists(a.kind) || a.left > lastPowerLeft.get(a.kind) + 0.5)
			{
				FlxTween.cancelTweensOf(slot.icon.scale);
				slot.icon.scale.set(1.8, 1.8);
				FlxTween.tween(slot.icon.scale, {x: 1, y: 1}, 0.35, {ease: FlxEase.backOut});
			}
			slot.time.text = Std.string(Math.ceil(a.left)) + "s";
			slot.bar.scale.x = Math.max(0, a.left / a.total);
			// Lejárat előtt a csík és az idő villog
			var blink = a.left > 2 || Std.int(a.left * 8) % 2 == 0;
			slot.bar.visible = blink;
			// A sérthetetlenség lejárta előtt a teljes sor (ikon, név) is villog – ez az egyetlen látható figyelmeztetés
			var warn = a.kind == SHIELD && a.left <= SHIELD_WARNING;
			slot.icon.visible = !warn || Std.int(a.left * 10) % 2 == 0;
			slot.name.color = warn && Std.int(a.left * 10) % 2 == 0 ? 0xffff5a5a : PixelArt.powerColor(a.kind);
			slot.time.color = a.left > 2 ? PixelArt.WHITE : PixelArt.RED;
		}

		lastPowerLeft.clear();
		for (a in active)
			lastPowerLeft.set(a.kind, a.left);
	}

	// --- Egyéb -------------------------------------------------------------

	function cleanup():Void
	{
		var left = FlxG.camera.scroll.x - 100;
		var right = FlxG.camera.scroll.x + FlxG.width + 100;
		ground.forEachAlive(g -> if (g.x + g.width < left) g.kill());
		bullets.forEachAlive(b -> if (b.x < left || b.x > right || b.y < -20) b.kill());
		enemies.forEachAlive(e -> if (e.x + e.width < left + 60) e.kill());
		enemyShots.forEachAlive(s -> if (s.x < left || s.x > right || s.y > FlxG.height + 20 || s.y < -40) s.kill());
		pickups.forEachAlive(p -> if (p.x + p.width < FlxG.camera.scroll.x - 20) p.kill());
		shrooms.forEachAlive(s -> if (s.x + s.width < left) s.kill());
		debris.forEachAlive(d -> {
			d.alpha -= 0.03;
			if (d.alpha <= 0 || d.y > FlxG.height)
				d.kill();
		});
	}

	// --- Meteor-csóva, varázsgomba, atom ---------------------------------------------

	/** Izzó parázs a zuhanó meteor mögött. */
	function spawnEmber(x:Float, y:Float):Void
	{
		var d = debris.recycle(FlxSprite);
		d.loadGraphic(PixelArt.chip(FlxG.random.bool(60) ? PixelArt.ORANGE : PixelArt.YELLOW));
		d.reset(x - 1, y - 1);
		d.velocity.set(FlxG.random.float(-15, 15), FlxG.random.float(-50, -20));
		d.acceleration.y = 0;
		d.alpha = 0.85;
	}

	/** Varázsgombák: 30 mp után időnként egy-egy a talajon, a képernyőn kívül jobbra. */
	function updateShroomSpawner(elapsed:Float):Void
	{
		shroomTimer -= elapsed;
		if (shroomTimer > 0)
			return;
		shroomTimer = FlxG.random.float(12, 20);
		var x0 = FlxG.camera.scroll.x + FlxG.width + 10;
		var spot:FlxSprite = null;
		ground.forEachAlive(g ->
		{
			if (spot == null && g.height > 20 && g.x > x0 - 20 && g.x < x0 + 200 && g.width >= 40)
				spot = g;
		});
		if (spot == null)
			return;
		var s = shrooms.recycle(FlxSprite);
		s.loadGraphic(PixelArt.shroom(), true, PixelArt.SHROOM_SIZE, PixelArt.SHROOM_SIZE);
		s.animation.add("glow", [0, 1], 3);
		s.animation.play("glow");
		s.reset(spot.x + FlxG.random.float(8, spot.width - 18), spot.y - PixelArt.SHROOM_SIZE);
		s.immovable = true;
	}

	/** Hozzáért a gombához: hallucináció (torzuló, színeltolódó kép). */
	function eatShroom(s:FlxSprite):Void
	{
		if (!s.alive)
			return;
		s.kill();
		if (tripTimer <= 0)
			tripTime = 0;
		tripTimer = TRIP_TIME;
		Audio.play("trippy");
		announce(PowerUp.label(SHROOM), PixelArt.powerColor(SHROOM), player.x + player.width / 2, player.y - 4);
		puff(s, 0xffb05cd6);
	}

	/** Lelőtt gomba: spóra-felhő, kevés pont. */
	function shootShroom(b:Bullet, s:FlxSprite):Void
	{
		if (!s.alive || !b.alive)
			return;
		if (b.kind != BulletKind.LASER)
			b.kill();
		s.kill();
		puff(s, 0xffb05cd6);
		addBonus(20, s.x + s.width / 2, s.y);
		Audio.play("hit");
	}

	function puff(s:FlxSprite, color:FlxColor):Void
	{
		var chip = PixelArt.chip(color);
		for (i in 0...8)
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chip);
			d.reset(s.x + s.width / 2, s.y + s.height / 2);
			d.velocity.set(FlxG.random.float(-60, 60), FlxG.random.float(-90, -10));
			d.acceleration.y = 80;
			d.alpha = 1;
		}
	}

	/** A hallucináció shadere: be- és kiúszik, közben hullámzik és színt vált. */
	function updateTrip(dt:Float):Void
	{
		if (tripTimer <= 0)
			return;
		tripTimer -= dt;
		tripTime += dt;
		var amount = Math.min(1, tripTime / 0.8) * Math.min(1, Math.max(0, tripTimer) / 1.2);
		tripShader.uTime.value = [tripTime];
		tripShader.uAmount.value = [amount];
		if (FlxG.camera.filters == null || FlxG.camera.filters.length == 0)
			FlxG.camera.filters = [new openfl.filters.ShaderFilter(tripShader)];
		if (tripTimer <= 0)
			FlxG.camera.filters = [];
	}

	/** Atom: vakító villanás, minden ellenség, meteor és lövedék elpusztul a képernyőn; a főellenség sokat sérül. */
	function nuke():Void
	{
		FlxG.camera.flash(FlxColor.WHITE, 0.7);
		FlxG.camera.shake(0.025, 0.5);
		Audio.play("nuke");
		for (b in blocks.members.copy())
			if (b != null && b.alive && b.isOnScreen())
				destroyBlock(b);
		for (e in enemies.members.copy())
			if (e != null && e.alive && e.isOnScreen())
				killEnemy(e, false);
		enemyShots.forEachAlive(s -> s.kill());
		if (boss != null && boss.alive)
			damageBoss(boss.maxHp * 0.2);
	}

	// --- Pályák és főellenség -------------------------------------------------------

	/** A pálya összes küldetése kész: a kamera lassan megáll, figyelmeztetés, aztán jön a főellenség. */
	function startBossIntro():Void
	{
		if (levelState != "PLAYING")
			return;
		levelState = "BOSS_INTRO";
		levelStateTimer = 3;
		showWarning("BOSS APPROACHING!");
	}

	function updateLevel(dt:Float):Void
	{
		switch (levelState)
		{
			case "BOSS_INTRO":
				levelStateTimer -= dt;
				if (levelStateTimer <= 0)
					spawnBoss();
			case "BOSS":
				if (boss != null && boss.alive)
				{
					bossBar.scale.x = Math.max(0, boss.hp / boss.maxHp);
					// Második fázisban vörösebb csík
					bossBar.color = boss.isPhase2() ? 0xffff5a5a : PixelArt.DEATHRAY_COLOR;
				}
			case "CLEAR":
				levelStateTimer -= dt;
				if (levelStateTimer <= 0)
					nextLevel();
			default:
		}
	}

	function spawnBoss():Void
	{
		levelState = "BOSS";
		boss = new Boss(Quests.level);
		boss.onAttack = bossAttack;
		insert(members.indexOf(enemies) + 1, boss); // az ellenségek mellé, a HUD és a vignetta alá
		bossDrops = 0;
		bossName.text = '${boss.title}  -  LEVEL ${Quests.level + 1}';
		for (s in ([bossName, bossBarBack, bossBar] : Array<FlxSprite>))
			s.visible = true;
		Audio.play("warning");
	}

	/** A főellenség támadásai. */
	function bossAttack(b:Boss, attack:Int):Void
	{
		switch (attack)
		{
			case 0:
				// Meteorok a hajó alól; minden harmadik arany (bónusszal), hogy fel lehessen erősödni
				for (i in 0...2)
				{
					bossDrops++;
					var reward = bossDrops % 3 == 0 ? PowerUp.random() : null;
					var m = blocks.recycle(Block, Block.new);
					m.spawn(b.x + b.width / 2 + (i == 0 ? -14 : 14), b.y + b.height + 30, 60, reward);
				}
				Audio.play("bombdrop", 0.7);
			case 1:
				// Legyezőlövés a hős felé
				var cx = b.x + b.width / 2, cy = b.y + b.height - 4;
				var base = Math.atan2(player.y + player.height / 2 - cy, player.x + player.width / 2 - cx);
				var count = b.isPhase2() ? 5 : 3;
				for (i in 0...count)
				{
					var a = base + (i - (count - 1) / 2) * 0.22;
					var s = enemyShots.recycle(FlxSprite);
					s.ID = 0;
					s.loadGraphic(PixelArt.enemyShot());
					s.reset(cx - 2, cy);
					s.velocity.set(Math.cos(a) * ENEMY_SHOT_SPEED * 1.1, Math.sin(a) * ENEMY_SHOT_SPEED * 1.1);
					s.acceleration.set(0, 0);
				}
				Audio.play("enemyshot");
			default:
				// Denevérek hívása
				for (i in 0...2)
				{
					var e = enemies.recycle(Enemy, Enemy.new);
					e.spawn(BAT, b.x + b.width / 2 + (i == 0 ? -20 : 20), b.y + 10);
					e.target = player;
					e.onFire = enemyFire;
				}
		}
	}

	function onBulletHitBoss(bullet:Bullet, b:Boss):Void
	{
		if (!bullet.alive || !b.alive || b.entering)
			return;
		if (bullet.kind == BulletKind.LASER)
		{
			if (!bullet.firstHitOn(b))
				return;
		}
		else
			bullet.kill();
		damageBoss(bullet.damage);
		if (bullet.kind != BulletKind.FLAME)
			Audio.play("hit", 0.6);
	}

	function damageBoss(amount:Float):Void
	{
		if (boss == null || !boss.alive || boss.entering)
			return;
		boss.hit(amount);
		if (boss.hp <= 0)
			defeatBoss();
	}

	/** A főellenség felrobban: robbanássorozat, nagy jutalom, "LEVEL CLEAR", aztán a következő pálya. */
	function defeatBoss():Void
	{
		var b = boss;
		var cx = b.x + b.width / 2, cy = b.y + b.height / 2;
		b.kill();
		for (s in ([bossName, bossBarBack, bossBar] : Array<FlxSprite>))
			s.visible = false;
		for (k in 0...5)
		{
			var delay = k * 0.18;
			FlxTween.num(0, 1, delay + 0.01, {
				onComplete: _ ->
				{
					var chip = PixelArt.chip(k % 2 == 0 ? PixelArt.ORANGE : PixelArt.YELLOW);
					for (i in 0...10)
					{
						var d = debris.recycle(FlxSprite);
						d.loadGraphic(chip);
						d.reset(cx + FlxG.random.float(-24, 24), cy + FlxG.random.float(-10, 10));
						d.velocity.set(FlxG.random.float(-180, 180), FlxG.random.float(-240, -40));
						d.acceleration.y = 600;
						d.alpha = 1;
					}
					Audio.play("bomb");
					FlxG.camera.shake(0.012, 0.15);
				}
			});
		}
		enemyShots.forEachAlive(s -> s.kill());
		addBonus(2500 * (Quests.level + 1), cx, cy);
		Quests.add(ENEMIES);
		levelState = "CLEAR";
		levelStateTimer = 4;

		var t = new FlxText(0, 90, FlxG.width, 'LEVEL ${Quests.level + 1} CLEAR!', 16);
		t.alignment = CENTER;
		t.color = PixelArt.YELLOW;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		FlxTween.tween(t, {alpha: 0}, 0.6, {startDelay: 3.2, onComplete: _ -> removeText(t)});
		Audio.play("clear");
	}

	/** Következő pálya: új küldetések, gyorsabb görgetés, újra indul a kamera. */
	function nextLevel():Void
	{
		var l = Quests.level + 1;
		Quests.startLevel(l);
		levelSpeed = Quests.levelDef(l).speed;
		scrollSpeed = SCROLL_START * scrollMul * levelSpeed;
		levelState = "PLAYING";
		levelTime = 0;
		boss = null;
		// Az új pálya elején egy kis energia és a küldetések kiírása
		player.energy = Math.min(Player.MAX_ENERGY, player.energy + 30);
		questPanel.visible = true;
		questPanelTimer = 5;
		showLevelBanner();
	}

	function showLevelBanner():Void
	{
		var t = new FlxText(0, 40, FlxG.width, 'LEVEL ${Quests.level + 1}\n${Quests.levelDef(Quests.level).name}', 16);
		t.alignment = CENTER;
		t.color = PixelArt.WHITE;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		FlxTween.tween(t, {alpha: 0}, 0.6, {startDelay: 2.4, onComplete: _ -> removeText(t)});
	}

	// --- Halál és folytatás ---------------------------------------------------------

	/** Elfogyott az energia: ha van még folytatás, felajánljuk, különben vége. */
	function die():Void
	{
		if (dead)
			return;
		dead = true;
		FlxG.timeScale = 1;
		FlxG.camera.filters = [];
		tripTimer = 0;
		player.kill();
		FlxG.camera.shake(0.015, 0.3);
		FlxG.camera.flash(FlxColor.RED, 0.2);

		if (continuesLeft > 0)
		{
			continuePrompt = true;
			continueTimer = CONTINUE_TIME;
			Audio.pauseMusic();
			Audio.play("powerdown");
			updateContinueText();
			gameOverText.visible = true;
			deathDim.visible = true;
			questPanel.visible = false;
			return;
		}
		gameOver();
	}

	function updateContinueText():Void
	{
		var s = Std.int(Math.max(0, Math.ceil(continueTimer)));
		gameOverText.text = 'CONTINUE?\n$s\n\nSPACE / ENTER: continue ($continuesLeft left)\nESC: give up';
		gameOverText.color = Std.int(continueTimer * 4) % 2 == 0 ? PixelArt.YELLOW : PixelArt.WHITE;
	}

	/** Folytatás: teli energia, rövid sérthetetlenség, a hős visszakerül a pályára; a pontszám és a küldetések megmaradnak. */
	function doContinue():Void
	{
		continuesLeft--;
		continuePrompt = false;
		dead = false;
		gameOverText.visible = false;
		deathDim.visible = false;
		gameOverText.color = PixelArt.YELLOW;
		player.revive();
		player.energy = Player.MAX_ENERGY;
		player.hurtTimer = 3;
		respawnPlayer();
		enemyShots.forEachAlive(s -> s.kill());
		// A hős közvetlen közelében zuhanó meteorok eltűnnek, hogy ne sérüljön rögtön
		blocks.forEachAlive(b -> if (b.isDangerous() && Math.abs(b.x - player.x) < 60) b.kill());
		Audio.resumeMusic();
		Audio.play("start");
		FlxG.camera.flash(0x60ffffff, 0.3);
	}

	/** Végleges játék vége: pontszám, csúcspontszám, újrakezdés. */
	function gameOver():Void
	{
		dead = true;
		continuePrompt = false;
		gameOverText.color = PixelArt.YELLOW;
		Audio.stopMusic();
		Audio.play("gameover");

		var finalScore = score();
		var previousBest = HiScore.get();
		HiScore.submit(finalScore);
		var record = finalScore > previousBest ? "\nNEW HI-SCORE!" : '\nHi-score: $previousBest';
		gameOverText.text = 'GAME OVER  (${Settings.difficultyName()})\nScore: $finalScore$record\n\nR / ENTER: restart\nESC: title';
		gameOverText.visible = true;
		deathDim.visible = true;
	}
}
