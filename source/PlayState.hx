package;

import Bullet.BulletKind;
import Enemy.EnemyKind;
import LevelData;
import PowerUp.PowerKind;
import Quests.QuestType;
import Boss.BossKind;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	/** A kamera kezdő és maximális automatikus görgetési sebessége (px/s). */
	static var SCROLL_START(get, never):Float;
	static inline function get_SCROLL_START():Float return Config.scrollStart;
	static var SCROLL_MAX(get, never):Float;
	static inline function get_SCROLL_MAX():Float return Config.scrollMax;
	/** Ennyivel nő a görgetési sebesség másodpercenként. */
	static var SCROLL_ACCEL(get, never):Float;
	static inline function get_SCROLL_ACCEL():Float return Config.scrollAccel;
	/** A futás elején ennyi ideig áll a kamera, hogy legyen idő felkészülni. */
	static var START_GRACE(get, never):Float;
	static inline function get_START_GRACE():Float return Config.startGrace;

	static inline var GROUND_Y:Float = 230;
	static var BULLET_SPEED(get, never):Float;
	static inline function get_BULLET_SPEED():Float return Config.bulletSpeed;

	/** Bónuszok időtartama (valós másodperc, a lassítás nem nyújtja meg). */
	static var WEAPON_TIME(get, never):Float;
	static inline function get_WEAPON_TIME():Float return Config.weaponTime;
	static var RAPID_COOLDOWN(get, never):Float;
	static inline function get_RAPID_COOLDOWN():Float return Config.rapidCooldown;
	/** A lézer újratöltési ideje (RAPID-dal rövidebb). */
	static var LASER_COOLDOWN(get, never):Float;
	static inline function get_LASER_COOLDOWN():Float return Config.laserCooldown;
	static var LASER_SPEED(get, never):Float;
	static inline function get_LASER_SPEED():Float return Config.laserSpeed;
	static var LASER_COOLDOWN_RAPID(get, never):Float;
	static inline function get_LASER_COOLDOWN_RAPID():Float return Config.laserCooldownRapid;
	static var BONUS_POINTS(get, never):Int;
	static inline function get_BONUS_POINTS():Int return Config.bonusPoints;
	static var ENERGY_REFILL(get, never):Float;
	static inline function get_ENERGY_REFILL():Float return Config.energyRefill;
	/** Szakadékba esés vagy lemaradás ára. */
	static var FALL_DAMAGE(get, never):Float;
	static inline function get_FALL_DAMAGE():Float return Config.damageFall;
	/** Sérülés utáni sérthetetlenség (valós mp). */
	static var HURT_TIME(get, never):Float;
	static inline function get_HURT_TIME():Float return Config.hurtTime;
	/** Ez alatt az arány alatt piros az energiacsík. */
	static inline var LOW_ENERGY:Float = 0.2;
	static inline var ENERGY_BAR_W:Int = 70;

	/** Az ellenségfajták megjelenési ideje (mp a futás elejétől), az EnemyKind sorrendjében. */
	static var ENEMY_UNLOCK(get, never):Array<Float>;
	static inline function get_ENEMY_UNLOCK():Array<Float> return Config.enemyUnlock;
	/** A végső főellenség pályája (0-tól: a 10. pálya); a 9. pályán a kiüresedett hold jön. */
	static inline var FINAL_LEVEL:Int = 9;

	/** A (nem végső) főellenségek sorrendje pályánként, 9-esével ismétlődve. */
	static final BOSS_ORDER:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 9];
	static final ENEMY_WARNING:Array<String> = ["SLIMES INCOMING!", "BATS INCOMING!", "TURRETS AHEAD!", "BOMBER DRONES!"];
	static var ENEMY_SHOT_SPEED(get, never):Float;
	static inline function get_ENEMY_SHOT_SPEED():Float return Config.enemyShotSpeed;
	static var ENEMY_SHOT_DAMAGE(get, never):Float;
	static inline function get_ENEMY_SHOT_DAMAGE():Float return Config.damageEnemyShot;
	static var BOMB_DAMAGE(get, never):Float;
	static inline function get_BOMB_DAMAGE():Float return Config.damageBomb;
	static var BOMB_RADIUS(get, never):Float;
	static inline function get_BOMB_RADIUS():Float return Config.bombRadius;
	/** Ráugrás után ekkora sebességgel pattan fel a hős. */
	static var STOMP_BOUNCE(get, never):Float;
	static inline function get_STOMP_BOUNCE():Float return Config.stompBounce;

	static var MAX_CONTINUES(get, never):Int;
	static inline function get_MAX_CONTINUES():Int return Config.continues;
	/** Ennyi másodperc van dönteni a folytatásról. */
	static var CONTINUE_TIME(get, never):Float;
	static inline function get_CONTINUE_TIME():Float return Config.continueTime;
	/** A varázsgomba hatásának ideje (valós mp). */
	static var TRIP_TIME(get, never):Float;
	static inline function get_TRIP_TIME():Float return Config.tripTime;
	static var BOSS_CONTACT_DAMAGE(get, never):Float;
	static inline function get_BOSS_CONTACT_DAMAGE():Float return Config.damageBossContact;

	var player:Player;
	var ground:FlxTypedGroup<FlxSprite>;
	var blocks:FlxTypedGroup<Block>;
	var bullets:FlxTypedGroup<Bullet>;
	var debris:FlxTypedGroup<FlxSprite>;
	var pickups:FlxTypedGroup<PowerUp>;
	var enemies:FlxTypedGroup<Enemy>;
	/** Ellenséges lövedékek és bombák (ID: 0 = lövedék, 1 = bomba). */
	var enemyShots:FlxTypedGroup<FlxSprite>;
	/** Talajon futó lökéshullámok (izomtömeg): külön csoport, mert saját kinézetük és ütközésük van. */
	var shockwaves:FlxTypedGroup<FlxSprite>;
	/** A gravitációs örvény hátralévő ideje (mp). */
	var gravityT:Float = 0;
	/** A kiüresedett hold nagy figyelmeztetései csak az első alkalommal jelennek meg a harcban. */
	var moonfallWarned:Bool = false;
	var gravityWarned:Bool = false;
	/** Pókcsípések hátralévő idejei (mp): minden csípés külön fogy; a számuk adja a tipsy erősségét. */
	var tipsyBites:Array<Float> = [];
	var tipsyClock:Float = 0;
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

	// --- Tiled-pálya (null = procedurális generálás) ---
	var lvl:Null<LevelData>;
	/** A következő létrehozandó talaj / spawn indexe a rendezett listákban. */
	var groundIdx:Int = 0;
	var spawnIdx:Int = 0;
	/** Zápor-állapot spawn-azonosítónként: felgyűlt törtmeteor és a kiadott meteorok száma. */
	var showerAcc:Map<Int, Float> = new Map();
	var showerCount:Map<Int, Int> = new Map();
	/** A főellenség-aréna bal széle: a kamera itt megáll (negatív = nincs). */
	var bossArenaX:Float = -1;
	/** A főellenség-aréna készül/kész: a procedurális talaj sík és szakadékmentes; a platformok felépültek-e. */
	var arenaMode:Bool = false;
	var arenaBuilt:Bool = false;
	/** Képkocka-számláló: a blokk-támasz ellenőrzés csak minden 3. képkockában fut. */
	var supportTick:Int = 0;
	/** Élő törmelék/parázs sprite-ok száma (a cleanup frissíti; a spawnEmber korlátozza vele a parázsokat). */
	var debrisLive:Int = 0;
	/** Már bemutatott ellenségfajták (az első előfordulásnál figyelmeztetés). */
	var seenKinds:Map<Int, Bool> = new Map();
	/** Az előző pályákon megtett út pontja (a kamera pályánként nullázódik). */
	var distBase:Int = 0;
	#if (js && cheats)
	var debugMap:Null<String> = null;
	var debugLevel:Int = 0;
	var debugSeekX:Float = -1;
	#end

	// --- Folytatás (continue) ---
	var continuesLeft:Int = 3; // a create() állítja be a Config.continues értékére
	var continuePrompt:Bool = false;
	var continueTimer:Float = 0;

	// --- Varázsgomba / hallucináció ---
	var shrooms:FlxTypedGroup<FlxSprite>;
	var shroomTimer:Float = 30; // a beginLevel állítja be a Config.shroomFirst értékére
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
	var coinIcon:FlxSprite;
	var coinText:FlxText;
	/** A szünetmenü ezt mutatja: a hátralévő continue-ok (a PlayState frissíti). */
	public static var menuContinues:Int = 3;
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
	#if cheats
	/** Fejlesztői jelzés a HUD alján (aktív cheatek). */
	var devTag:FlxText;
	#end
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

	/** A nehézségi szint szorzója a görgetésre (a futás elején rögzítve). */
	var scrollMul:Float = 1;
	var nextGroundX:Float = 0;
	/** Az utoljára generált fő talajszakasz (a peremek sötétítéséhez). */
	var lastGround:FlxSprite;
	var lastGroundY:Float = GROUND_Y;
	var spawnTimer:Float = 1.5;
	/** Procedurális pályán: ennyi mp múlva jön a következő meteoreső. */
	var stormTimer:Float = 18;
	var elapsedTotal:Float = 0;
	var blocksDestroyed:Int = 0;
	/** Megszerzett extra pont (szétlőtt dobozok, bónuszok). */
	var bonusPoints:Int = 0;
	/** A kijelzőn már megjelent extra pont: akkor nő, amikor a repülő "+pont" felirat odaér. */
	var shownBonus:Int = 0;
	var dead:Bool = false;

	/** Aktív kiegészítők (SPREAD / RAPID) hátralévő ideje (egymásra rakódnak). */
	var weaponTimers = new Map<PowerKind, Float>();
	/** Az aktuális alapfegyver (ROCKET / LASER / GRENADE), null = pisztoly. A bolt-felszerelés végtelen ideig tart. */
	var baseWeapon:Null<PowerKind> = null;
	var baseWeaponTimer:Float = 0;
	/** Robbanás-körök (rakéta, gránát) látványa. */
	var beams:FlxTypedGroup<FlxSprite>;
	var laserTimer:Float = 0;

	var backdrop:Backdrop;
	var backdropLevel:Int = -1;

	/** Témaváltás: a háttér újraépül az új színekkel, a talaj a következő generálástól (beginLevel) az új színeket kapja. */
	function applyTheme(t:Themes.Theme, level:Int = 0):Void
	{
		// Minden pályához új háttér épül (a holdak száma és fázisa, az égi események pályánként mások)
		if (t == Themes.current && backdrop != null && backdropLevel == level)
			return;
		backdropLevel = level;
		Themes.current = t;
		if (backdrop != null)
		{
			remove(backdrop, true);
			backdrop.destroy();
		}
		backdrop = new Backdrop(-1, -1, level);
		insert(0, backdrop);
	}

	/** A HUD kamerája (shader nélkül) és rétege; minden FlxText és a HUD elemei ide kerülnek (lásd `add`). */
	var hudCam:FlxCamera;
	var hudLayer:FlxGroup;
	var hudAdding:Bool = false;

	/** Szünetmenü, bolt stb. a játékterületre rajzol: közben a HUD-kamera rejtve van (az update-ben újra látszik). */
	override public function openSubState(subState:flixel.FlxSubState):Void
	{
		hudLayer.visible = false; // a HUD a menü alatt rejtve van (a menü ugyanazon a, shader nélküli kamerán rajzol)
		Pad.swallow(); // a megnyitó gombnyomás (Start / R2) ne zárja be rögtön a menüt
		super.openSubState(subState);
	}

	/** A szövegek és a HUD (hudAdding közben létrehozott elemek) a HUD-rétegre kerülnek, a többi a játékra. */
	override public function add(basic:flixel.FlxBasic):flixel.FlxBasic
	{
		if (hudAdding || Std.isOfType(basic, FlxText))
			return hudLayer.add(basic);
		return super.add(basic);
	}

	override public function create():Void
	{
		super.create();
		Config.load();
		continuesLeft = MAX_CONTINUES;
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

		// A HUD külön kamerán van: a módosítók (pixelesítés, zseblámpa, hallucináció…) shaderei csak a játékterületre hatnak
		hudCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		hudCam.bgColor = FlxColor.TRANSPARENT;
		hudCam.pixelPerfectRender = true;
		hudCam.antialiasing = false;
		FlxG.cameras.add(hudCam, false);
		UiCam.cam = hudCam;
		hudLayer = new FlxGroup();
		hudLayer.cameras = [hudCam];
		super.add(hudLayer);

		// Az Alt az ugrás: a böngésző ne kapja meg (különben a menüsorra ugrana a fókusz).
		// A nyilak már alapból tiltva vannak, így az Alt+Bal nyíl sem lapoz vissza.
		if (FlxG.keys.preventDefaultKeys != null && !FlxG.keys.preventDefaultKeys.contains(FlxKey.ALT))
			FlxG.keys.preventDefaultKeys.push(FlxKey.ALT);

		Audio.init(); // ha a nyitóképernyő már legenerálta, nem csinál semmit
		Audio.playMusic();

		// A nehézség a futás elején rögzül (játék közben nem állítható)
		Settings.load();
		scrollMul = Settings.scrollMul();

		backdrop = new Backdrop();
		add(backdrop);

		ground = new FlxTypedGroup<FlxSprite>();
		blocks = new FlxTypedGroup<Block>();
		bullets = new FlxTypedGroup<Bullet>();
		debris = new FlxTypedGroup<FlxSprite>();
		pickups = new FlxTypedGroup<PowerUp>();
		popups = new FlxTypedGroup<FlxText>();

		enemies = new FlxTypedGroup<Enemy>();
		enemyShots = new FlxTypedGroup<FlxSprite>();
		shockwaves = new FlxTypedGroup<FlxSprite>();
		beams = new FlxTypedGroup<FlxSprite>();

		shrooms = new FlxTypedGroup<FlxSprite>();

		add(ground);
		impactMarks = new FlxTypedGroup<FlxSprite>();
		add(impactMarks);
		add(shrooms);
		coins = new FlxTypedGroup<Coin>();
		add(pickups);
		add(coins);
		add(blocks);
		add(enemies);
		add(debris);
		add(bullets);
		add(enemyShots);
		add(shockwaves);
		add(beams);

		// Zuhanó meteorok tűzcsóvája
		Block.onTrail = spawnEmber;
		Enemy.onDetach = slimeSplat;
		tripShader = new HallucinationShader();
		baseWeapon = Upgrades.loadoutKind(); // a bolt-felszerelés (alapból pisztoly: null)
		baseWeaponTimer = Math.POSITIVE_INFINITY;

		// Küldetések: teljesítéskor felirat és jutalom. Térképes (Tiled) pályán a főellenség a térképen kijelölt
		// helyen jön, nem a küldetések teljesítésére; procedurális pályán a küldetések hívják.
		Quests.onComplete = showQuestComplete;
		Quests.onAllComplete = () -> if (lvl == null) startBossIntro();

		player = new Player(140, GROUND_Y - 40);
		player.onShoot = shoot;
		player.canStand = standRoom;
		player.onDust = spawnDust;
		player.onRun = spawnRunFx;
		Coin.target = player;
		add(player);
		createChargeFx();

		// Az 1. pálya (hibakereső módban a ?level= paraméter szerinti)
		var firstLevel = 0;
		#if (js && cheats)
		var params = queryParams();
		if (params.exists("level"))
			firstLevel = Std.int(Math.max(0, Std.parseInt(params.get("level"))));
		if (params.exists("map"))
		{
			debugMap = params.get("map");
			debugLevel = firstLevel;
		}
		if (params.exists("x"))
			debugSeekX = Std.parseFloat(params.get("x"));
		#end
		Quests.startLevel(firstLevel);
		beginLevel(firstLevel, true);
		#if (js && cheats)
		if (debugSeekX >= 0)
			seek(debugSeekX);
		#end

		// Sötét vignetta a képernyő szélein (a világ fölött, a HUD alatt)
		var vignette = new FlxSprite(0, 0, PixelArt.vignette(FlxG.width, FlxG.height));
		vignette.scrollFactor.set(0, 0);
		add(vignette);
		createCurseFx();

		hudAdding = true;
		createHud();

		questPanel = new QuestPanel(70);
		add(questPanel);

		add(popups);
		popups.cameras = [hudCam];
		hudAdding = false;

		#if (js && test)
		// Csak automatikus tesztekhez: a böngészőből elérhető az állapot,
		// és fókusz nélkül (fejnélküli böngészőben) sem áll meg a játék
		js.Syntax.code("window.__game = {0}; window.__quests = {1}; window.__loader = {2}; window.__config = {3}; window.__settings = {4}", this, Quests, LevelLoader, Config, Settings);
		FlxG.autoPause = false;
		#end
	}

	override public function update(elapsed:Float):Void
	{
		hudLayer.visible = true; // (menü megnyitásakor az openSubState rejti el)
		// Játék közben nincs egérkurzor (a menük, amik a PlayState fölött nyílnak, maguk kapcsolják be)
		if (subState == null && FlxG.mouse.visible)
			FlxG.mouse.visible = false;
		// F: teljes képernyő (natív buildben; böngészőben a Main kezeli közvetlenül a billentyűeseményből)
		#if !js
		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;
		#end
		if (Controls.just(MUTE))
			Settings.toggleMute();

		if (dead)
		{
			if (continuePrompt)
			{
				// Folytatás: visszaszámlálás, közben a játék áll
				continueTimer -= elapsed;
				updateContinueText();
				if (FlxG.keys.anyJustPressed([SPACE, ENTER, X, J]) || Pad.just(CONFIRM) || Pad.just(START))
					doContinue();
				else if (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK) || continueTimer <= 0)
					gameOver();
				return;
			}
			super.update(elapsed);
			if (FlxG.keys.anyJustPressed([R, ENTER]) || Pad.just(CONFIRM) || Pad.just(START))
				FlxG.resetState();
			else if (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK))
				FlxG.switchState(TitleState.new);
			return;
		}

		// Szünet: P vagy ESC (a szünetmenü alatt a játék nem frissül)
		if ((Controls.just(PAUSE) || FlxG.keys.justPressed.ESCAPE) || Pad.just(START))
		{
			openSubState(new PauseSubState());
			return;
		}

		#if cheats
		// F10: egyből a főellenséghez
		if (FlxG.keys.justPressed.F10)
		{
			Leaderboard.cheated = true;
			cheatSkipToBoss();
		}
		if (FlxG.keys.justPressed.F9 || Pad.just(CHEAT))
		{
			Leaderboard.cheated = true;
			openSubState(new CheatSubState(this));
			return;
		}
		#end

		// A bónuszok ideje valós időben fogy, lassítás alatt is
		var realElapsed = elapsed / FlxG.timeScale;

		elapsedTotal += elapsed;
		levelTime += elapsed;
		updateCamera(realElapsed);

		generateGround();
		// A NO SPAWNS cheat csak a spawnolást tiltja: a főellenség-trigger és a pályavég továbbra is működik
		var spawning = true;
		#if cheats
		spawning = !noSpawns;
		#end
		if (levelState == "PLAYING")
		{
			if (lvl != null)
				updateAuthored(elapsed, spawning);
			else if (spawning)
			{
				updateSpawner(elapsed);
				updateEnemySpawner(elapsed);
				updateShroomSpawner(elapsed);
			}
		}
		updateLevel(realElapsed);
		updateTrip(realElapsed);
		updateTipsy(realElapsed);

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
		// A ráragadt slime-ok lassítják a hőst (több slime szorzódik, de egy alsó határ alá nem megy)
		player.speedMul = Math.max(0.3, Math.pow(Config.slimeSlow, stuckSlimes()));
		// Gravitációs örvény (a kiüresedett hold támadása): a hőst a főellenség felé húzza
		if (gravityT > 0)
		{
			gravityT -= elapsed;
			if (boss != null && boss.alive && !dead)
				player.velocity.x += (boss.x + boss.width / 2 > player.x + player.width / 2 ? 1 : -1) * 520 * elapsed;
		}
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
		if (++supportTick % 3 == 0)
			updateBlockSupport();

		FlxG.overlap(player, pickups, collectPowerUp);
		FlxG.collide(coins, ground);
		FlxG.overlap(player, coins, collectCoin);
		FlxG.overlap(bullets, blocks, onBulletHitBlock);
		// A lövedékek a talajba csapódnak (a rakéta és a gránát robban)
		FlxG.overlap(bullets, ground, (b:Bullet, _) -> if (b.kind == BulletKind.ROCKET || b.kind == BulletKind.GRENADE) detonate(b) else b.kill());

		// Ellenségek: a földi fajták a talajon állnak, a repülők nem ütköznek vele
		FlxG.overlap(enemies, ground, null, (e:Enemy, g:FlxSprite) -> e.usesGround && flixel.FlxObject.separate(e, g));
		FlxG.overlap(bullets, enemies, onBulletHitEnemy);
		FlxG.overlap(player, enemies, onPlayerTouchEnemy);
		FlxG.overlap(enemyShots, player, onShotHitPlayer);
		FlxG.overlap(bullets, enemyShots, onBulletHitShot);
		FlxG.overlap(enemyShots, ground, (s:FlxSprite, _) -> shotHitGround(s));
		updateShockwaves(elapsed);

		// Varázsgomba: hozzáérve hallucináció. Nehezítő elem, ezért nem lehet lelőni: a lövedékek átmennek rajta (kikerülni vagy átugrani kell)
		FlxG.overlap(player, shrooms, (p:Player, s:FlxSprite) -> eatShroom(s));

		// Főellenség
		if (boss != null && boss.alive)
		{
			FlxG.overlap(bullets, boss, onBulletHitBoss);
			FlxG.overlap(player, boss, (p:Player, b:Boss) -> if (player.hurtTimer <= 0 && !b.invulnerable()) damagePlayer(BOSS_CONTACT_DAMAGE, false));
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

		// A kamera csak előre megy, ezért a bal szélen sem lehet kifutni
		var left = FlxG.camera.scroll.x;
		if (player.x < left)
		{
			player.x = left;
			player.velocity.x = Math.max(player.velocity.x, 0);
		}

		// Leesett egy szakadékba: energiát veszít, és visszakerül a pályára
		if (player.y > FlxG.height + 40)
		{
			if (damagePlayer(FALL_DAMAGE, true))
				respawnPlayer();
		}

		updateImpactMarks();
		updateChargeFx();
		updateHoming(realElapsed);
		// Rakéta: tűzcsóva és füst a farkából (a lövedék a haladási irányába néz)
		bullets.forEachAlive(b ->
		{
			if (b.kind == BulletKind.ROCKET && FlxG.random.bool(70))
			{
				var len = Math.max(1, Math.sqrt(b.velocity.x * b.velocity.x + b.velocity.y * b.velocity.y));
				spawnEmber(b.x + b.width / 2 - b.velocity.x / len * (b.width / 2 + 1), b.y + b.height / 2 - b.velocity.y / len * (b.width / 2 + 1));
			}
		});
		cleanup();
		updateHud(realElapsed);
	}

	/**
	 * Gravitáció a földet ért meteoroknak: ha egy doboz alól eltűnt a támasz (szétlőtték vagy elporladt az alatta
	 * levő), a fölötte levő újra leesik. Támasz: talaj vagy másik földet ért doboz a talpa alatt (vízszintes átfedéssel).
	 */
	function updateBlockSupport():Void
	{
		// Indexes ciklusok, closure nélkül (a GC-t nem terheli), és csak minden 3. képkockában: a támasz lassan változik
		var bl = blocks.members;
		var gr = ground.members;
		for (b in bl)
		{
			if (b == null || !b.alive || !b.exists || !b.landed)
				continue;
			var bottom = b.y + b.height;
			var onGround = false;
			var under:Block = null;
			for (g in gr)
				if (g != null && g.alive && g.exists && g.x < b.x + b.width - 1 && g.x + g.width > b.x + 1 && Math.abs(g.y - bottom) <= 3)
				{
					onGround = true;
					break;
				}
			if (!onGround)
				for (o in bl)
					if (o != null && o != b && o.alive && o.exists && o.landed && o.x < b.x + b.width - 1 && o.x + o.width > b.x + 1 && Math.abs(o.y - bottom) <= 3)
					{
						under = o;
						break;
					}
			if (!onGround && under == null)
			{
				// Elvették alóla a támaszt (vagy legurult a pereméről): újra leesik, a lendületét megtartva
				var vx = b.velocity.x;
				b.release();
				b.velocity.x = vx * 0.6;
				continue;
			}
			if (!onGround && under != null)
			{
				// Egy másik meteoron fekszik (nem talajon): legurul róla, a támasz közepétől távolodva
				var off = (b.x + b.width / 2) - (under.x + under.width / 2);
				if (b.rollSign == 0 || Math.abs(off) > 2)
					b.rollSign = off > 2 ? 1 : (off < -2 ? -1 : (b.rollSign != 0 ? b.rollSign : (FlxG.random.bool() ? 1 : -1)));
				var v = b.rollSign * 46.0;
				var nx = b.x + v * FlxG.elapsed * 3; // 3 képkockánként fut, ezért a lépés is háromszoros
				var blocked = false;
				for (g in gr)
					if (g != null && g.alive && g.exists && nx < g.x + g.width && nx + b.width > g.x && b.y < g.y + g.height && b.y + b.height - 1 > g.y)
					{
						blocked = true;
						break;
					}
				if (!blocked)
					for (o in bl)
						if (o != null && o != b && o.alive && o.exists && o.landed && nx < o.x + o.width && nx + b.width > o.x && b.y < o.y + o.height && b.y + b.height - 1 > o.y)
						{
							blocked = true;
							break;
						}
				if (blocked)
				{
					// Falba ütközött: a másik irányba próbál legurulni
					b.rollSign = -b.rollSign;
					b.velocity.x = 0;
				}
				else
					b.velocity.x = v;
			}
		}
	}
	// --- Érmék és bolt ---------------------------------------------------------------

	/** `n` érme pattan ki a (cx, cy) pontból. */
	function dropCoins(cx:Float, cy:Float, n:Int):Void
	{
		for (i in 0...n)
			coins.recycle(Coin, Coin.new).spawn(cx + FlxG.random.float(-4, 4), cy);
	}

	function collectCoin(p:Player, c:Coin):Void
	{
		if (!c.alive)
			return;
		c.kill();
		Settings.coins++;
		Settings.store();
		Audio.play("coin", 0.5);
	}

	/** A pálya vége után a bolt nyílik, bezárásakor jön a következő pálya. */
	function openShop():Void
	{
		levelState = "SHOP";
		var s = new ShopSubState(true);
		s.closeCallback = nextLevel;
		openSubState(s);
	}

	// --- Becsapódás-jelző és töltésjelző ------------------------------------------------

	/** A zuhanó meteorok várható becsapódási helyének jelzői (minden képkockában újrarajzolva). */
	var impactMarks:FlxTypedGroup<FlxSprite>;
	/** A kipattanó érmék. */
	var coins:FlxTypedGroup<Coin>;
	var chargeBack:FlxSprite;
	var chargeFill:FlxSprite;
	var chargeOrb:FlxSprite;
	var lastCharge:Float = 0;

	function newMark():FlxSprite
	{
		var s = new FlxSprite();
		s.makeGraphic(1, 1, FlxColor.WHITE);
		s.origin.set(0, 0); // a nyújtás a bal felső saroktól indul
		return s;
	}

	/**
	 * Minden zuhanó meteor alatt: a talajon (vagy egy már földet ért doboz tetején) villogó piros sáv a meteor
	 * szélességében + halvány függőleges vonal a meteortól odáig. Minél közelebb a meteor, annál erősebb.
	 * Szakadék fölött nincs jelző (oda esve a meteor ártalmatlan).
	 */
	function updateImpactMarks():Void
	{
		impactMarks.forEachAlive(m -> m.kill());
		var pulse = Std.int(elapsedTotal * 14) % 2 == 0;
		blocks.forEachAlive(b ->
		{
			if (!b.isDangerous())
				return;
			var bottom = b.y + b.height;
			var land = Math.POSITIVE_INFINITY;
			ground.forEachAlive(g ->
			{
				if (g.x < b.x + b.width && g.x + g.width > b.x && g.y >= bottom - 2 && g.y < land)
					land = g.y;
			});
			blocks.forEachAlive(o ->
			{
				if (o != b && o.landed && o.x < b.x + b.width && o.x + o.width > b.x && o.y >= bottom - 2 && o.y < land)
					land = o.y;
			});
			if (land == Math.POSITIVE_INFINITY)
				return;

			var dist = Math.max(0, land - bottom);
			var near = 1 - Math.min(1, dist / 220); // 0 = messze, 1 = mindjárt becsapódik

			var line = impactMarks.recycle(FlxSprite, newMark);
			line.reset(Math.round(b.x + b.width / 2), Math.round(bottom));
			line.scale.set(1, Math.max(1, dist));
			line.color = 0xffff5a5a;
			line.alpha = 0.12 + 0.2 * near;

			var bar = impactMarks.recycle(FlxSprite, newMark);
			bar.reset(Math.round(b.x) - 3, Math.round(land) - 3);
			bar.scale.set(b.width + 6, 3);
			bar.color = pulse ? 0xffff5a5a : 0xffffcd75;
			bar.alpha = 0.8 + 0.2 * near;
		});
	}

	function createChargeFx():Void
	{
		chargeBack = new FlxSprite().makeGraphic(18, 4, PixelArt.OUTLINE);
		chargeFill = new FlxSprite().makeGraphic(16, 2, FlxColor.WHITE);
		chargeFill.origin.set(0, 0);
		chargeOrb = new FlxSprite().makeGraphic(16, 16, FlxColor.TRANSPARENT, true);
		flixel.util.FlxSpriteUtil.drawCircle(chargeOrb, 8, 8, 7, FlxColor.WHITE);
		for (s in [chargeBack, chargeFill, chargeOrb])
		{
			s.visible = false;
			add(s);
		}
	}

	/** Töltés közben: a torkolatnál növekvő, villogó gömb, a hős feje fölött töltöttség-csík (színe a szinttel nő). */
	function updateChargeFx():Void
	{
		var c = player.charge;
		var on = c > 0 && !dead;
		chargeBack.visible = chargeFill.visible = chargeOrb.visible = on;
		if (!on)
		{
			lastCharge = 0;
			return;
		}
		var full = c >= 1;
		var color:FlxColor = full ? (Std.int(elapsedTotal * 20) % 2 == 0 ? PixelArt.WHITE : PixelArt.YELLOW) : (c > 0.6 ? PixelArt.YELLOW : (c > 0.35 ? PixelArt.CYAN : PixelArt.SKY));

		chargeBack.setPosition(Math.round(player.x + player.width / 2 - 9), Math.round(player.y - 8));
		chargeFill.setPosition(chargeBack.x + 1, chargeBack.y + 1);
		chargeFill.scale.set(c, 1);
		chargeFill.color = color;

		var s = 0.25 + c * 0.75 + (full ? 0.12 * Math.sin(elapsedTotal * 40) : 0);
		chargeOrb.scale.set(s, s);
		chargeOrb.setPosition(player.aimX + player.aimDX * 5 - 8, player.aimY + player.aimDY * 5 - 8);
		chargeOrb.color = color;
		chargeOrb.alpha = 0.7 + 0.3 * Math.sin(elapsedTotal * 30);

		if (full && lastCharge < 1)
			Audio.play("tick", 1);
		lastCharge = c;
	}

	// --- Kamera ----------------------------------------------------------

	/** A hős a képernyő szélességének ekkora részénél áll (a többi a előre látszik). */
	static inline var CAMERA_LEAD:Float = 0.4;

	/**
	 * A kamera a hőst követi (lágyan), de csak előre: a már elhagyott talaj és a spawnolt elemek a bal oldalon
	 * eltűnnek. A főellenség arénájánál megáll; procedurális főellenségnél és a pálya végén áll.
	 */
	function updateCamera(dt:Float):Void
	{
		var cam = FlxG.camera.scroll;
		if (levelState == "PLAYING" || bossArenaX >= 0)
		{
			var target = player.x + player.width / 2 - FlxG.width * CAMERA_LEAD;
			if (target > cam.x)
				cam.x += (target - cam.x) * Math.min(1, dt * 8);
		}
		if (bossArenaX >= 0 && cam.x > bossArenaX)
			cam.x = bossArenaX;
	}

	// --- Pálya -----------------------------------------------------------

	/**
	 * Talaj vagy platform (h megadva) létrehozása. Az edgeL / edgeR a bal / jobb perem sötétítendő sorainak
	 * száma (rés vagy lépcső mellett); a procedurális generátor ezt utólag festi.
	 */
	function addGround(x:Float, w:Float, y:Float, ?h:Float, edgeL:Int = 0, edgeR:Int = 0):FlxSprite
	{
		var g = ground.recycle(FlxSprite);
		var platform = h != null;
		if (h == null)
			h = FlxG.height - y + 40; // a talaj a képernyő aljáig ér
		g.makeGraphic(Std.int(w), Std.int(h), FlxColor.TRANSPARENT, true);
		PixelArt.paintGround(g.pixels, Std.int(x), Std.int(y), platform);
		if (edgeL > 0)
			PixelArt.paintEdge(g.pixels, false, edgeL);
		if (edgeR > 0)
			PixelArt.paintEdge(g.pixels, true, edgeR);
		g.dirty = true;
		g.reset(x, y);
		g.immovable = true;
		// A lebegő platform egyirányú: alulról és oldalról átjárható (fel lehet ugrani rá), csak felülről tart
		g.allowCollisions = platform ? flixel.util.FlxDirectionFlags.UP : flixel.util.FlxDirectionFlags.ANY;
		return g;
	}

	/** Tiled-ből jövő talaj: a nagyon széles téglalapot ~320 px-es darabokra vágja (egy darab festése olcsó marad). */
	function addAuthored(r:GroundRect):Void
	{
		if (r.platform)
		{
			addGround(r.x, r.w, r.y, r.h);
			return;
		}
		var maxW = 320.0;
		if (r.w <= maxW)
		{
			addGround(r.x, r.w, r.y, null, r.edgeL, r.edgeR);
			return;
		}
		var n = Math.ceil(r.w / maxW);
		var cw = Math.ceil(r.w / n);
		var x = r.x;
		for (i in 0...Std.int(n))
		{
			var last = i == Std.int(n) - 1;
			var w = last ? r.x + r.w - x : cw;
			addGround(x, w, r.y, null, i == 0 ? r.edgeL : 0, last ? r.edgeR : 0);
			x += w;
		}
	}

	/** A kamera előtti ablakban (mint a procedurális generátornál) létrehozza a következő Tiled-talajokat. */
	function streamGround():Void
	{
		var limit = FlxG.camera.scroll.x + FlxG.width * 2;
		while (groundIdx < lvl.ground.length && lvl.ground[groundIdx].x < limit)
			addAuthored(lvl.ground[groundIdx++]);
	}

	function generateGround():Void
	{
		if (lvl != null)
		{
			streamGround();
			return;
		}
		var limit = FlxG.camera.scroll.x + FlxG.width * 2;
		while (nextGroundX < limit)
		{
			// Szakadék, egyre gyakrabban
			var gap = !arenaMode && FlxG.random.bool((32 + Math.min(elapsedTotal, 60) * 0.6) * Settings.gapMul());
			if (gap)
				nextGroundX += FlxG.random.int(40, 80);

			var w = FlxG.random.int(10, 30) * 8;
			var y = arenaMode && lastGround != null ? lastGroundY : GROUND_Y - FlxG.random.int(0, 3) * 12;
			// Járhatóság: a gyengébb karakter (kb. 50 px ugrás, 140 px táv) is átjusson. Szakadék után legfeljebb 24 px-et
			// lehet felfelé lépni, szakadék nélkül legfeljebb 36-ot.
			if (lastGround != null)
				y = Std.int(Math.max(y, lastGroundY - (gap ? 24 : 36)));
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

			// Néha egy lebegő platform a szakasz fölött. Végig a saját szakasz fölött marad, és a széleitől távol (24 px), különben
			// a szomszéd (magasabb) talaj fölé lógva a hős feje beleütközne, és nem férne át alatta. A magassága elérhető (<= 50).
			var pw = Std.int(Math.min(FlxG.random.int(4, 8) * 8, w - 48));
			if (pw >= 32 && FlxG.random.bool(50))
				addGround(nextGroundX + FlxG.random.int(24, w - pw - 24), pw, y - FlxG.random.int(40, 50), 8);

			nextGroundX += w;
		}
	}

	// --- Pálya betöltése és a szerkesztett (Tiled) pálya működése ---------------------------

	/**
	 * Új pálya kezdete (a Quests.startLevel után): térkép betöltése, a világ és a kamera visszaállítása,
	 * a játékos a kezdőpontra. A fegyverek és az energia megmaradnak. Térkép nélkül (vagy hibás térképnél)
	 * a pálya procedurálisan generálódik.
	 */
	function beginLevel(l:Int, first:Bool):Void
	{
		var def = Quests.levelDef(l);
		levelSpeed = def.speed;

		var path = def.map;
		#if (js && cheats)
		if (debugMap != null && l == debugLevel)
			path = debugMap;
		#end
		lvl = path != null ? LevelLoader.load(path) : null;

		// A pálya témája: a térkép `theme` tulajdonsága, különben a pálya sorszáma szerinti alap
		var theme = Themes.find(lvl != null ? lvl.theme : null);
		applyTheme(theme != null ? theme : Themes.forLevel(l), l);

		// A megtett út pontja megmarad, a kamera visszaáll
		distBase += Std.int(FlxG.camera.scroll.x / 10);
		FlxG.camera.scroll.set(0, 0);
		ground.forEachAlive(s -> s.kill());
		blocks.forEachAlive(s -> s.kill());
		enemies.forEachAlive(s -> s.kill());
		enemyShots.forEachAlive(s -> s.kill());
		shockwaves.forEachAlive(s -> s.kill());
		pickups.forEachAlive(s -> s.kill());
		coins.forEachAlive(s -> s.kill());
		shrooms.forEachAlive(s -> s.kill());
		bullets.forEachAlive(s -> s.kill());
		debris.forEachAlive(s -> s.kill());
		beams.forEachAlive(s -> s.kill());
		if (boss != null && boss.alive)
			boss.kill();
		boss = null;

		groundIdx = 0;
		spawnIdx = 0;
		showerAcc = new Map();
		showerCount = new Map();
		bossArenaX = -1;
		arenaMode = false;
		arenaBuilt = false;
		gravityT = 0;
		Audio.restoreMainMusic();
		spawnTimer = 1.5;
		stormTimer = 18;
		enemyTimer = 0;
		shroomTimer = Config.shroomFirst;
		levelState = "PLAYING";
		levelStateTimer = 0;
		levelTime = 0;

		if (lvl != null)
		{
			player.setPosition(lvl.startX - player.width / 2, lvl.startY - player.height);
		}
		else
		{
			// Procedurális pálya: biztonságos kezdő talaj, aztán generált szakaszok, friss nehézségi ív
			if (!first)
			{
				elapsedTotal = 0;
				enemyKindsUnlocked = 0;
			}
			lastGround = addGround(0, 360, GROUND_Y);
			lastGroundY = GROUND_Y;
			nextGroundX = 360;
			player.setPosition(140, GROUND_Y - 40);
		}
		player.velocity.set(0, 0);
		player.hurtTimer = first ? 0 : 2;
		generateGround();
	}

	/** A szerkesztett pálya léptetése: a kamera helyzete szerint megjelenő elemek, meteorzáporok, főellenség, pályavég. */
	function updateAuthored(dt:Float, spawning:Bool = true):Void
	{
		var cam = FlxG.camera.scroll.x;
		var diff = Settings.difficultyIndex();

		while (spawnIdx < lvl.spawns.length && lvl.spawns[spawnIdx].trigger <= cam)
		{
			var sp = lvl.spawns[spawnIdx++];
			if (spawning && sp.minDifficulty <= diff)
				triggerSpawn(sp);
		}

		// Meteorzáporok: amíg a képernyő átfedi a téglalapot; a nehézség a gyakoriságot skálázza
		for (s in lvl.showers)
		{
			if (!spawning || s.minDifficulty > diff || cam + FlxG.width < s.x || cam > s.x + s.w)
				continue;
			var acc = showerAcc.exists(s.id) ? showerAcc.get(s.id) : 0.0;
			acc += dt * s.rate / Settings.spawnIntervalMul();
			while (acc >= 1)
			{
				acc -= 1;
				showerShot(s);
			}
			showerAcc.set(s.id, acc);
		}

		if (lvl.bossX >= 0)
		{
			// A kamera a főellenség előtt lefékez, és az aréna szélénél megáll
			if (cam >= lvl.bossX - 160)
			{
				bossArenaX = lvl.bossX;
				startBossIntro();
			}
		}
		else if (lvl.endX >= 0 && cam + FlxG.width >= lvl.endX)
			finishLevel();
	}

	function triggerSpawn(sp:Spawn):Void
	{
		switch (sp.type)
		{
			case SpawnType.ENEMY:
				var kind:EnemyKind = sp.enemy;
				var ki:Int = kind;
				if (!seenKinds.exists(ki))
				{
					seenKinds.set(ki, true);
					showWarning(ENEMY_WARNING[ki]);
				}
				for (i in 0...sp.count)
				{
					var px = sp.x + i * sp.spacing;
					var py = sp.y;
					if (kind == EnemyKind.TURRET)
					{
						var gt = lvl.groundTop(px);
						if (gt == null)
							continue;
						py = gt;
					}
					spawnEnemyAt(kind, px, py);
				}
			case SpawnType.PICKUP:
				pickups.recycle(PowerUp, PowerUp.new).place(sp.x, sp.y, sp.power, sp.floating);
			case SpawnType.SHROOM:
				var gt = lvl.groundTop(sp.x);
				placeCurse(sp.x, gt != null ? gt : sp.y, sp.power != null ? sp.power : PowerUp.randomCurse());
			case SpawnType.METEORFALL:
				meteorFall(sp.count, sp.w, sp.fallMin, sp.fallMax, sp.goldEvery, sp.power, sp.randomReward);
			case SpawnType.METEOR:
				var reward = sp.randomReward ? PowerUp.random() : sp.power;
				spawnMeteor(sp.x, sp.speed, reward);
			default:
		}
	}

	/** Egy meteor a zápor-téglalapból: a képernyőhöz képest a hős előtt, mint a procedurális meteoroknál. */
	function showerShot(s:Spawn):Void
	{
		var n = (showerCount.exists(s.id) ? showerCount.get(s.id) : 0) + 1;
		showerCount.set(s.id, n);
		var reward:Null<PowerKind> = null;
		if (s.goldEvery > 0 && n % s.goldEvery == 0)
			reward = s.randomReward ? PowerUp.random() : s.power;
		var x = FlxG.camera.scroll.x + FlxG.random.float(0.35, 1.1) * FlxG.width;
		spawnMeteor(x, FlxG.random.float(s.fallMin, s.fallMax), reward);
	}

	/**
	 * Meteoreső: figyelmeztetés, majd (2,2 mp múlva) `count` meteor hullik a képernyő szélességében egy kis szórással
	 * (a becsapódás-jelzők megmutatják, hova). Minden `goldEvery`-edik arany. A nehézség a darabszámot skálázza.
	 */
	function meteorFall(count:Int, span:Float, fallMin:Float, fallMax:Float, goldEvery:Int, reward:Null<PowerKind>, randomReward:Bool):Void
	{
		// Hosszabb, feltűnő figyelmeztetés felül (nem takarja az ellenség-figyelmeztetést): felirat, vörös villanás, riasztás
		showWarning("METEOR FALL!", 40, 2.4);
		Perf.log("event", {what: "METEOR FALL", count: count});
		// Az ég előre jelzi: hullócsillagok raja előzi meg a meteorzáport (a meteorok 2.2 mp múlva kezdenek hullani)
		if (backdrop != null)
			backdrop.shootingStars(9, 2.0);
		FlxG.camera.flash(0x50ff3040, 0.3);
		FlxTimer.wait(0.9, () -> if (!dead) Audio.play("alarm"));
		FlxTimer.wait(1.7, () -> if (!dead) Audio.play("alarm"));
		count = Std.int(Math.max(2, Math.round(count / Settings.spawnIntervalMul())));
		FlxTimer.wait(2.2, () ->
		{
			if (dead)
				return;
			var x0 = FlxG.camera.scroll.x + 30;
			var step = span / count;
			for (i in 0...count)
			{
				var gold = goldEvery > 0 && (i + 1) % goldEvery == 0;
				var r:Null<PowerKind> = gold ? (randomReward ? PowerUp.random() : reward) : null;
				var mx = x0 + i * step + FlxG.random.float(-step * 0.3, step * 0.3);
				var fall = FlxG.random.float(fallMin, fallMax);
				FlxTimer.wait(FlxG.random.float(0, 0.9), () ->
				{
					if (!dead)
						spawnMeteor(mx, fall, r);
				});
			}
		});
	}

	function spawnMeteor(x:Float, fallSpeed:Float, ?reward:PowerKind, forceHot:Bool = false):Void
	{
		blocks.recycle(Block, Block.new).spawn(x, FlxG.camera.scroll.y - 10, fallSpeed, reward, forceHot);
	}

	/** Ellenség a talppont-közép (px, py) helyén. */
	function spawnEnemyAt(kind:EnemyKind, px:Float, py:Float):Void
	{
		var e = enemies.recycle(Enemy, Enemy.new);
		e.spawn(kind, 0, 0);
		e.place(px, py);
		e.target = player;
		e.onFire = enemyFire;
	}

	#if cheats
	/** Hibakeresés: a kamerát és a hőst a pálya x pozíciójára ugrasztja (az előtte levő spawnokat átugorja). */
	public function seek(x:Float):Void
	{
		if (lvl == null)
			return;
		FlxG.camera.scroll.x = x;
		ground.forEachAlive(g -> g.kill());
		groundIdx = 0;
		while (groundIdx < lvl.ground.length && lvl.ground[groundIdx].x + lvl.ground[groundIdx].w < x - 100)
			groundIdx++;
		spawnIdx = 0;
		while (spawnIdx < lvl.spawns.length && lvl.spawns[spawnIdx].trigger <= x)
			spawnIdx++;
		streamGround();
		var px = x + 140;
		var gt = lvl.groundTop(px);
		player.setPosition(px, (gt != null ? gt : 150) - player.height);
		player.velocity.set(0, 0);
		levelTime = Math.max(levelTime, START_GRACE + 1);
	}

	#if js
	/** Az URL lekérdezési paraméterei (?level=1&map=assets/levels/x.json&x=4000). */
	static function queryParams():Map<String, String>
	{
		var m = new Map<String, String>();
		var q = js.Browser.location.search;
		if (q != null && q.length > 1)
			for (pair in q.substr(1).split("&"))
			{
				var kv = pair.split("=");
				if (kv.length == 2)
					m.set(StringTools.urlDecode(kv[0]), StringTools.urlDecode(kv[1]));
			}
		return m;
	}
	#end
	#end

	// --- Blokkok ----------------------------------------------------------

	function updateSpawner(elapsed:Float):Void
	{
		// Időnként meteoreső: sok meteor egyszerre (egyre több)
		stormTimer -= elapsed;
		if (stormTimer <= 0)
		{
			stormTimer = FlxG.random.float(22, 34);
			meteorFall(10 + Quests.level * 2, FlxG.width * 0.95, 70, 150, 6, null, true);
		}

		spawnTimer -= elapsed;
		if (spawnTimer > 0)
			return;

		// Idővel egyre sűrűbben jönnek
		var interval = Math.max(Config.meteorIntervalMin, Config.meteorIntervalStart - elapsedTotal * Config.meteorIntervalDecay) * Settings.spawnIntervalMul();
		spawnTimer = FlxG.random.float(interval * 0.6, interval * 1.4);

		// Főleg a játékos előtt potyognak, hogy kerülgetni kelljen
		var x = FlxG.camera.scroll.x + FlxG.random.float(0.35, 1.1) * FlxG.width;
		var reward = FlxG.random.bool(Settings.rewardChance()) ? PowerUp.random() : null;
		spawnMeteor(x, FlxG.random.float(60, 140), reward);
	}

	/** Van-e fölötte elég hely, hogy a guggoló hős felálljon (a talaj, platformok és a földet ért meteorok nem lehetnek a fejében). */
	function standRoom():Bool
	{
		var bottom = player.y + player.height;
		var top = bottom - 18 * player.sizeScale - 1;
		var free = true;
		function hits(o:FlxSprite):Void
		{
			if (o.allowCollisions == flixel.util.FlxDirectionFlags.UP)
				return; // az egyirányú platform a fejünkön átmegy
			if (free && o.x < player.x + player.width && o.x + o.width > player.x && o.y < bottom - 0.5 && o.y + o.height > top)
				free = false;
		}
		ground.forEachAlive(hits);
		blocks.forEachAlive(b -> if (b.landed) hits(b));
		return free;
	}

	function onPlayerTouchBlock(p:Player, b:Block):Void
	{
		// Az izzó, már földet ért meteor érintése sebez (a meteor marad, a hős hátralökődik)
		if (b.isHot())
		{
			if (player.hurtTimer <= 0)
				damagePlayer(Config.damageMeteorHot, false);
			return;
		}
		if (!b.isDangerous())
			return;
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
			case 8, 16: Config.damageMeteorSmall;
			case 24: Config.damageMeteorMedium;
			default: Config.damageMeteorLarge;
		}
	}

	/**
	 * Energia levonása visszajelzéssel. Ha elfogy, vége a játéknak.
	 * @param fall szakadék/lemaradás (nincs hátralökés, utána a hívó visszahelyezi a játékost)
	 * @return true, ha a játékos életben maradt
	 */
	function damagePlayer(amount:Float, fall:Bool):Bool
	{
		#if cheats
		if (godMode)
			return true;
		#end
		amount = Math.max(1, Math.round(amount * Settings.damageMul() * Upgrades.armorMul())); // nehézség és páncél szerint
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
		if (bullet.kind == BulletKind.ROCKET || bullet.kind == BulletKind.GRENADE)
		{
			detonate(bullet);
			return;
		}

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
		else
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
		// Néha érme is kipattan (nagyobb dobozból gyakrabban, a jutalommeteorból mindig)
		var coinChance = block.width <= 16 ? 30 : (block.width <= 24 ? 40 : 55);
		if (block.reward != null)
			dropCoins(cx, block.y + block.height / 2, 3);
		else if (FlxG.random.bool(coinChance))
			dropCoins(cx, block.y + block.height / 2, 1);
		dropCurseLoot(cx, Config.curseDropMeteor);
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
			case 8: 15;
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

	/**
	 * Futás- és fékezésnyom: por szál a lábak mögül, gyors futásnál halvány sebességcsíkok a törzs mögött;
	 * fékezéskor (csúszós karakternél hosszan) sűrűbb, nagyobb porfelhő a haladási irányban.
	 */
	function spawnRunFx(fx:Float, fy:Float, dir:Float, speed:Float, braking:Bool):Void
	{
		for (i in 0...(braking ? 2 : 1))
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(PixelArt.dust());
			d.reset(fx - dir * FlxG.random.float(2, 7) - 1, fy - 3 - FlxG.random.float(0, 2));
			if (braking)
				d.velocity.set(dir * FlxG.random.float(10, 50), FlxG.random.float(-45, -10)); // fékezéskor előre fröccsen
			else
				d.velocity.set(-dir * FlxG.random.float(8, 35), FlxG.random.float(-28, -6));
			d.acceleration.set(0, 0);
			d.alpha = 0.8;
		}
		if (!braking && speed > 0.7 && FlxG.random.bool(55))
		{
			var s = debris.recycle(FlxSprite);
			s.loadGraphic(PixelArt.speedLine());
			s.reset(fx - dir * 10 - 3, player.y + FlxG.random.float(3, player.height - 3));
			s.velocity.set(-dir * 20, 0);
			s.acceleration.set(0, 0);
			s.alpha = 0.55;
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
		var interval = Math.max(Config.enemyIntervalMin, Config.enemyIntervalStart - (elapsedTotal - ENEMY_UNLOCK[0]) * 0.025) * Settings.spawnIntervalMul();
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
			case SPIDERLING:
				return; // csak a pók főellenség hívja
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

	/** Hány slime ragadt most a hősre. */
	function stuckSlimes():Int
	{
		var n = 0;
		enemies.forEachAlive(e -> if (e.stuck) n++);
		return n;
	}

	/** Egy pókcsípés: a tipsy erőssége a számukkal nő (legfeljebb Config.tipsyMax), mindegyik Config.tipsyTime ideig hat. */
	function addTipsyBite():Void
	{
		if (tipsyBites.length >= Std.int(Config.tipsyMax))
			tipsyBites.shift(); // a legrégebbi helyére az új, így a hatás frissül
		tipsyBites.push(Config.tipsyTime);
		Audio.play("hit", 0.6);
		announce("TIPSY x" + tipsyBites.length, 0xffc9a0ff, player.x + player.width / 2, player.y - 6);
		refreshFilters();
	}

	/** A csípések fogynak; a képernyő hullámzása és a hős ingadozása az aktív csípések számával arányos. */
	function updateTipsy(dt:Float):Void
	{
		if (tipsyBites.length == 0)
		{
			player.tipsy = 0;
			return;
		}
		tipsyClock += dt;
		var i = tipsyBites.length;
		while (i-- > 0)
		{
			tipsyBites[i] -= dt;
			if (tipsyBites[i] <= 0)
				tipsyBites.splice(i, 1);
		}
		var s = Math.min(1, tipsyBites.length / Config.tipsyMax);
		player.tipsy = s;
		if (tipsyBites.length == 0)
			refreshFilters();
		else if (tripTimer <= 0)
		{
			// A hallucináció shaderét gyengébben használjuk: enyhe hullámzás, ami a csípések számával erősödik
			tripShader.uTime.value = [tipsyClock];
			tripShader.uAmount.value = [0.1 + 0.4 * s];
		}
	}

	/** A hősről lepottyanó slime: zöldes-lila fröcskölés. */
	function slimeSplat(e:Enemy):Void
	{
		var chip = PixelArt.chip(e.baseColor);
		for (i in 0...6)
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chip);
			d.reset(e.x + FlxG.random.float(0, e.width), e.y + e.height - 2);
			d.velocity.set(FlxG.random.float(-50, 50), FlxG.random.float(-90, -20));
			d.acceleration.y = 600;
			d.alpha = 1;
		}
	}

	function onBulletHitEnemy(bullet:Bullet, e:Enemy):Void
	{
		// A hősre ragadt slime-ot a lövedékek nem találják (a hős testén ülne)
		if (!e.alive || !bullet.alive || e.stuck)
			return;
		if (bullet.kind == BulletKind.ROCKET || bullet.kind == BulletKind.GRENADE)
		{
			detonate(bullet);
			return;
		}
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
		else
			Audio.play("hit");
	}

	/**
	 * Hős és ellenség találkozása: felülről ráugorva (ha lehet) elpusztítja,
	 * sérthetetlenül szétzúzza, egyébként energiát veszít.
	 */
	function onPlayerTouchEnemy(p:Player, e:Enemy):Void
	{
		if (!e.alive || e.stuck)
			return;
		var stomp = player.velocity.y > 0 && player.y + player.height - e.y < 8;
		if (stomp && e.stompable)
		{
			player.velocity.y = -STOMP_BOUNCE;
			killEnemy(e, true);
			return;
		}
		if (e.kind == EnemyKind.SPIDERLING)
		{
			// Csípés: a kicsi pók eltűnik, a hős pedig ittasan ingadozik (több csípés = erősebb, időkorlátos)
			slimeSplat(e);
			e.kill();
			addTipsyBite();
			return;
		}
		if (e.kind == EnemyKind.SLIME)
		{
			// A slime nem sebez: a hős lábára tapad és lelassítja (legfeljebb 3 lehet rajta egyszerre)
			var n = stuckSlimes();
			if (n < 3)
			{
				e.attach(player, n);
				Audio.play("hit", 0.6);
				announce("STUCK!", PixelArt.LIME, player.x + player.width / 2, player.y - 6);
			}
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
		dropCurseLoot(e.x + e.width / 2, Config.curseDropEnemy);
		addBonus(stomped ? e.points * 2 : e.points, e.x + e.width / 2, e.y);
		if (FlxG.random.bool(55))
			dropCoins(e.x + e.width / 2, e.y + e.height / 2, FlxG.random.int(1, 2));
		Audio.play(stomped ? "stomp" : "explode", 0.8);
		Quests.add(ENEMIES);
		if (stomped)
			Quests.add(STOMPS);
		e.kill();
	}

	/** A bolyhos óriás pihegolyói (pattogók és spórák) lelőhetők: szétpukkannak. A többi ellenséges lövedéket nem lehet lelőni. */
	function onBulletHitShot(bullet:Bullet, s:FlxSprite):Void
	{
		if (!bullet.alive || !s.alive || !(s.ID == 4 || s.ID >= 10))
			return;
		if (bullet.kind == BulletKind.ROCKET || bullet.kind == BulletKind.GRENADE)
		{
			detonate(bullet);
			return;
		}
		var chip = PixelArt.chip(0xffd9c8f0);
		for (i in 0...5)
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chip);
			d.reset(s.x + s.width / 2, s.y + s.height / 2);
			d.velocity.set(FlxG.random.float(-70, 70), FlxG.random.float(-90, -10));
			d.acceleration.y = 400;
			d.alpha = 1;
		}
		s.kill();
		Audio.play("hit", 0.5);
		if (bullet.kind != BulletKind.LASER)
			bullet.kill();
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
		if (player.hurtTimer > 0)
			return;
		damagePlayer(ENEMY_SHOT_DAMAGE, false);
	}

	function shotHitGround(s:FlxSprite):Void
	{
		if (!s.alive)
			return;
		if (s.ID >= 10)
		{
			// Pattogó pihegolyó: minden talajérintésnél felpattan, a 3. után eltűnik
			if (s.ID == 10)
				s.kill();
			else
			{
				s.ID--;
				s.y -= 3;
				s.velocity.y = -190;
			}
			return;
		}
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
		if (dist < BOMB_RADIUS && player.hurtTimer <= 0)
			damagePlayer(BOMB_DAMAGE, false);
	}

	function removeText(t:FlxText):Void
	{
		remove(t, true);
		hudLayer.remove(t, true);
		t.destroy();
	}

	/** Nagy, villogó figyelmeztetés a képernyő közepén (új ellenségfajta). */
	function showWarning(text:String, y:Float = 96, seconds:Float = 2.2):Void
	{
		var t = new FlxText(0, y, FlxG.width, "WARNING!\n" + text, 16);
		t.alignment = CENTER;
		t.color = 0xffff5a5a;
		t.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		t.scrollFactor.set(0, 0);
		add(t);
		Audio.play("warning");
		FlxTween.num(0, 1, seconds, {onComplete: _ -> FlxTween.tween(t, {alpha: 0}, 0.4, {onComplete: _ -> removeText(t)})},
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

	/** Aktív-e egy kiegészítő (SPREAD / RAPID). */
	inline function has(kind:PowerKind):Bool
	{
		return weaponTimers.exists(kind);
	}

	/**
	 * Lövés az aktuális alapfegyverrel (pisztoly / ROCKET / LASER / GRENADE – egyszerre csak egy), a kiegészítők:
	 * - RAPID: gyorsabb tüzelés (a várakozási idő rövidül; a töltést is gyorsítja)
	 * - SPREAD: 3 lövedék / 3 rakéta / 3 gránát / 3 lézersugár legyezőben
	 * A `c` a töltöttség: 0 = sima lövés (Space), 0.2..1 = töltött lövés (M felengedésekor): nagyobb, erősebb, nagyobb robbanás.
	 */
	function shoot(x:Float, y:Float, dx:Float, dy:Float, c:Float = 0):Void
	{
		var spread = has(SPREAD), rapid = has(RAPID);
		var charged = c > 0;
		if (charged)
			FlxG.camera.shake(0.002 + 0.004 * c, 0.1);

		switch (baseWeapon)
		{
			case ROCKET:
				for (r in fanAngles(spread, dx, dy))
					fireRocket(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), c);
				Audio.play("heavy", charged ? 1 : 0.8);

			case GRENADE:
				for (r in fanAngles(spread, dx, dy))
					fireGrenade(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), c);
				Audio.play("bombdrop", 0.7);

			case LASER:
				// A töltött lövés a lézer újratöltését is kivárja, de nem akad el rajta
				if (laserTimer > 0 && !charged)
					return;
				laserTimer = rapid ? LASER_COOLDOWN_RAPID : LASER_COOLDOWN;
				for (r in fanAngles(spread, dx, dy))
					fireLaser(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), 1 + Std.int(c * 5), c);
				Audio.play("laser", charged ? 1 : 0.8);

			default:
				// Pisztoly: egylövetű; töltve nagy, átütő lövedék
				for (r in fanAngles(spread, dx, dy))
					fireBullet(x, y, dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r), 1 + Upgrades.weaponBonus() + (charged ? 2 + Std.int(c * 5) : 0),
						charged, c);
				// Gyorsan lőve halkabb, hogy ne legyen fárasztó
				Audio.play(charged ? "heavy" : (spread ? "spread" : "shoot"), rapid && !charged ? 0.55 : 1);
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

	function fireBullet(x:Float, y:Float, dx:Float, dy:Float, damage:Int, big:Bool, c:Float = 0):Void
	{
		// Grafika az irány szerint: vízszintes, függőleges vagy átlós (balra tükrözve); a töltött lövedék nagy golyó
		// Nyomkövetőnél mindig a vízszintes grafika van, a haladási irányba forgatva (kanyarodás közben is)
		var homing = has(HOMING) && !big;
		var graphic = if (big) PixelArt.heavyBullet(); else if (homing || Math.abs(dy) < 0.38) PixelArt.bulletH(); else if (Math.abs(dx) < 0.38)
			PixelArt.bulletV(); else PixelArt.bulletD();
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(graphic);
		b.setup(BulletKind.NORMAL, damage);
		if (c > 0)
		{
			// Töltött lövedék: a töltöttséggel nagyobb (a találati terület is)
			b.scale.set(1 + c * 1.4, 1 + c * 1.4);
			b.updateHitbox();
		}
		b.flipX = !homing && dx < 0;
		b.flipY = !homing && dy > 0.3; // lefelé lőve függőlegesen tükrözve
		if (homing)
		{
			b.homing = true;
			b.angle = Math.atan2(dy, dx) * 180 / Math.PI;
		}
		else if (big && has(HOMING))
			b.homing = true; // a töltött golyó is követ (nem forog)
		b.reset(x - b.width / 2, y - b.height / 2);
		var speed = big ? BULLET_SPEED * 0.9 : BULLET_SPEED;
		// Előre (vízszintesen vagy átlósan) lőve a lövedék örökli a futás sebességének felét
		b.velocity.set(dx * speed + (Math.abs(dx) > 0.5 ? player.velocity.x * 0.5 : 0), dy * speed);
	}

	/** Lézerlövedék: nagyon gyors, minden dobozon és ellenségen átmegy (mindegyiket egyszer sebzi). */
	function fireLaser(x:Float, y:Float, dx:Float, dy:Float, damage:Int, c:Float = 0):Void
	{
		// Nyomkövető lézer: mindig vízszintes rajz, ami a haladási irányába fordul (mint a nyomkövető pisztolylövedék)
		var homing = has(HOMING);
		// Legyezős (SPREAD) lövésnél is a pontos haladási irányba forgatott vízszintes rajz kell, különben a ferde sugár vízszintes vonalként csúszna
		var rotated = homing || has(SPREAD);
		var graphic = if (rotated || Math.abs(dy) < 0.38) PixelArt.laserH(); else if (Math.abs(dx) < 0.38) PixelArt.laserV(); else PixelArt.laserD();
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(graphic);
		b.setup(BulletKind.LASER, damage);
		b.homing = homing;
		if (c > 0)
		{
			// Töltött lézer: vastagabb és hosszabb
			b.scale.set(1 + c * 1.2, 1 + c * 1.2);
			b.updateHitbox();
		}
		b.flipX = !rotated && dx < 0;
		b.flipY = !rotated && dy > 0.3; // lefelé lőve függőlegesen tükrözve
		// A lövedék a torkolattól indul előre
		b.reset(x - b.width / 2 + dx * b.width / 2, y - b.height / 2 + dy * b.height / 2);
		b.velocity.set(dx * LASER_SPEED, dy * LASER_SPEED);
		if (rotated)
			b.angle = Math.atan2(dy, dx) * 180 / Math.PI;
	}

	/** Rakéta: gyorsulva egyenesen repül, az első találatnál robban (töltve nagyobb és erősebb). */
	function fireRocket(x:Float, y:Float, dx:Float, dy:Float, c:Float):Void
	{
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(PixelArt.rocket());
		b.setup(BulletKind.ROCKET, Config.rocketDamage + Std.int(c * 4), Config.rocketRadius * (1 + c * 0.9));
		b.homing = has(HOMING);
		b.flipY = false;
		if (c > 0)
		{
			b.scale.set(1 + c * 0.6, 1 + c * 0.6);
			b.updateHitbox();
		}
		b.reset(x - b.width / 2 + dx * 4, y - b.height / 2 + dy * 4);
		b.angle = Math.atan2(dy, dx) * 180 / Math.PI;
		b.velocity.set(dx * Config.rocketSpeed + (Math.abs(dx) > 0.5 ? player.velocity.x * 0.4 : 0), dy * Config.rocketSpeed);
		b.acceleration.set(dx * 200, dy * 200);
	}

	/** Gránát: ívben repül (gravitáció), az első találatnál nagy hatósugárban robban. */
	function fireGrenade(x:Float, y:Float, dx:Float, dy:Float, c:Float):Void
	{
		var b = bullets.recycle(Bullet, Bullet.new);
		b.loadGraphic(PixelArt.grenade());
		b.setup(BulletKind.GRENADE, Config.grenadeDamage + Std.int(c * 5), Config.grenadeRadius * (1 + c * 0.7));
		b.homing = has(HOMING);
		b.flipY = false;
		b.reset(x - b.width / 2, y - b.height / 2);
		var sp = Config.grenadeSpeed * (1 + c * 0.35);
		// Előre dobva felfelé is lendül, hogy ívet írjon le
		b.velocity.set(dx * sp + (Math.abs(dx) > 0.5 ? player.velocity.x * 0.5 : 0), dy * sp - (dy == 0 ? 120 : 40));
		b.acceleration.y = 520;
		b.angularVelocity = dx < 0 ? -420 : 420;
	}

	/**
	 * Nyomkövető kiegészítő: a `homing` lövedékek a hatótávon belüli legközelebbi ellenség (vagy főellenség) felé
	 * kanyarodnak, a sebességük megmarad. A rakéta és a (forgatott) pisztolylövedék a haladási irányába néz.
	 */
	function updateHoming(dt:Float):Void
	{
		var any = false;
		for (b in bullets.members)
			if (b != null && b.alive && b.exists && b.homing)
			{
				any = true;
				break;
			}
		var range2 = Config.homingRange * Config.homingRange;
		if (!any)
			return;
		bullets.forEachAlive(b ->
		{
			if (!b.homing)
				return;
			// Biztosíték: egy idő után a lövedék már nem követ (nem kering örökké a cél körül)
			if (b.age > 2.2 && b.kind != BulletKind.GRENADE)
			{
				b.homing = false;
				return;
			}
			var cx = b.x + b.width / 2, cy = b.y + b.height / 2;
			var best:FlxSprite = null;
			var bestD = range2;
			enemies.forEachAlive(e ->
			{
				var dx = e.x + e.width / 2 - cx, dy = e.y + e.height / 2 - cy;
				var d = dx * dx + dy * dy;
				if (d < bestD)
				{
					bestD = d;
					best = e;
				}
			});
			if (boss != null && boss.alive && !boss.entering)
			{
				var dx = boss.x + boss.width / 2 - cx, dy = boss.y + boss.height / 2 - cy;
				var d = dx * dx + dy * dy;
				if (d < bestD)
				{
					bestD = d;
					best = boss;
				}
			}
			// A gránát célpont nélkül ívben esik (gravitáció), célpontnál nyomkövetve repül, nem lebeg
			if (b.kind == BulletKind.GRENADE)
				b.acceleration.y = best != null ? 0 : 520;
			if (best == null)
				return;
			var speed = Math.sqrt(b.velocity.x * b.velocity.x + b.velocity.y * b.velocity.y);
			if (speed < 1)
				return;
			var cur = Math.atan2(b.velocity.y, b.velocity.x);
			var want = Math.atan2(best.y + best.height / 2 - cy, best.x + best.width / 2 - cx);
			var diff = want - cur;
			while (diff > Math.PI)
				diff -= 2 * Math.PI;
			while (diff < -Math.PI)
				diff += 2 * Math.PI;
			// A gyors lövedék (lézer) arányosan élesebben fordul, különben a kanyarsugara hatalmas lenne
			var maxTurn = Config.homingTurn * dt * (b.kind == BulletKind.LASER ? 2.2 : 1);
			// Közelről a célhoz képest arányosan élesebben fordul (speed / távolság), különben a kanyarsugara miatt körözne a cél körül
			var dist = Math.max(10, Math.sqrt(bestD));
			maxTurn = Math.max(maxTurn, 3.0 * speed / dist * dt);
			cur += Math.max(-maxTurn, Math.min(maxTurn, diff));
			b.velocity.set(Math.cos(cur) * speed, Math.sin(cur) * speed);
			if (b.kind == BulletKind.ROCKET)
				b.acceleration.set(Math.cos(cur) * 200, Math.sin(cur) * 200);
			if (b.kind == BulletKind.ROCKET || b.kind == BulletKind.NORMAL || b.kind == BulletKind.LASER)
				b.angle = cur * 180 / Math.PI;
		});
		// Biztosíték: a levegőben maradt robbanó lövedék egy idő után felrobban (nyomkövetés közben sem keringhet örökké)
		bullets.forEachAlive(b ->
		{
			if ((b.kind == BulletKind.GRENADE && b.age > 2.6) || (b.kind == BulletKind.ROCKET && b.age > 3.5))
				detonate(b);
		});
	}

	/** A robbanó lövedék (rakéta, gránát) felrobban a mostani helyén. */
	function detonate(b:Bullet):Void
	{
		if (!b.alive)
			return;
		var cx = b.x + b.width / 2, cy = b.y + b.height / 2;
		var r = b.radius, d = b.damage;
		b.kill();
		blast(cx, cy, r, d);
	}

	/** A (px, py) pont és egy sprite téglalapjának távolsága (0, ha a pont bent van). */
	static function rectDist(s:FlxSprite, px:Float, py:Float):Float
	{
		var dx = Math.max(s.x - px, Math.max(0, px - (s.x + s.width)));
		var dy = Math.max(s.y - py, Math.max(0, py - (s.y + s.height)));
		return Math.sqrt(dx * dx + dy * dy);
	}

	/**
	 * Robbanás: a `r` sugarú körben minden doboz, ellenség, ellenséges lövedék és a főellenség sebződik (a hős nem).
	 * Látvány: táguló kör, törmelék, rázkódás.
	 */
	function blast(cx:Float, cy:Float, r:Float, damage:Int):Void
	{
		var ring = beams.recycle(FlxSprite);
		ring.loadGraphic(PixelArt.blast());
		ring.reset(cx - PixelArt.BLAST_SIZE / 2, cy - PixelArt.BLAST_SIZE / 2);
		ring.angle = 0;
		FlxTween.cancelTweensOf(ring);
		ring.alpha = 1;
		var full = r * 2 / PixelArt.BLAST_SIZE;
		ring.scale.set(full * 0.4, full * 0.4);
		FlxTween.tween(ring.scale, {x: full, y: full}, 0.18, {ease: FlxEase.quadOut});
		FlxTween.tween(ring, {alpha: 0}, 0.28, {startDelay: 0.1, onComplete: _ -> ring.kill()});

		var chips = [PixelArt.chip(PixelArt.ORANGE), PixelArt.chip(PixelArt.YELLOW)];
		for (i in 0...Std.int(6 + r / 4))
		{
			var d = debris.recycle(FlxSprite);
			d.loadGraphic(chips[i % 2]);
			d.reset(cx, cy);
			d.velocity.set(FlxG.random.float(-1.6, 1.6) * r * 2, FlxG.random.float(-2.2, -0.2) * r * 2);
			d.acceleration.set(0, 600);
			d.alpha = 1;
		}
		FlxG.camera.shake(0.003 + r * 0.00009, 0.14);
		Audio.play("bomb", 0.8);

		for (b in blocks.members.copy())
			if (b != null && b.alive && rectDist(b, cx, cy) <= r)
			{
				b.hit(damage);
				if (b.hp <= 0)
					destroyBlock(b);
			}
		for (e in enemies.members.copy())
			if (e != null && e.alive && rectDist(e, cx, cy) <= r)
			{
				e.hit(damage);
				if (e.hp <= 0)
					killEnemy(e, false);
			}
		enemyShots.forEachAlive(s -> if (rectDist(s, cx, cy) <= r) s.kill());
		if (boss != null && boss.alive && !boss.entering && rectDist(boss, cx, cy) <= r)
			damageBoss(damage);
	}

	// --- Bónuszok -------------------------------------------------------------

	function collectPowerUp(p:Player, pu:PowerUp):Void
	{
		if (!pu.alive)
			return;
		pu.kill();
		applyPower(pu.kind);
	}

	/** A bónusz hatása (felvételkor, és a cheat-menüből is ez fut). */
	function applyPower(kind:PowerKind):Void
	{
		var color = PixelArt.powerColor(kind);
		var cx = player.x + player.width / 2;

		switch (kind)
		{
			case ROCKET | LASER | GRENADE:
				// Alapfegyver: lecseréli az előzőt (ugyanazt újra felvéve az ideje visszatöltődik)
				baseWeapon = kind;
				baseWeaponTimer = WEAPON_TIME;
				Quests.reach(WEAPON_STACK, weaponStack());
				Audio.play("powerup");
			case SPREAD | RAPID | HOMING:
				// Kiegészítő: egymásra rakódnak, bármelyik alapfegyverrel működnek
				weaponTimers.set(kind, WEAPON_TIME);
				Quests.reach(WEAPON_STACK, weaponStack());
				Audio.play("powerup");
			case BONUS:
				addBonus(BONUS_POINTS, cx, player.y - 8);
				Audio.play("coin");
			case ENERGY:
				player.energy = Math.min(player.maxEnergy, player.energy + ENERGY_REFILL);
				Audio.play("heal");
			case SHROOM | PIXEL | TORCH | GHOST | TINYVIEW | TINYHERO | MAGNET | ASCII:
				// Módosító: nem jutalom, a talajon fekvő tárgyból jön (applyCurse feliratozza)
				applyCurse(kind);
				return;
		}

		Quests.add(POWERUPS);
		announce(PowerUp.label(kind), color, cx, player.y - 4);
		FlxG.camera.flash(((color : Int) & 0xffffff) | 0x50000000, 0.15);
	}

	/** Egyszerre aktív fegyverbónuszok száma (időkorlátos alapfegyver + kiegészítők) a küldetéshez. */
	function weaponStack():Int
	{
		var n = baseWeapon != null && baseWeaponTimer < Math.POSITIVE_INFINITY ? 1 : 0;
		for (k in weaponTimers.keys())
			n++;
		return n;
	}

	/** Bónuszok idejének léptetése és hatásaik (fegyver, kiegészítők, módosítók). */
	function updatePowers(dt:Float):Void
	{
		#if cheats
		if (freezePowers)
		{
			if (baseWeapon != null && baseWeaponTimer < Math.POSITIVE_INFINITY)
				baseWeaponTimer = WEAPON_TIME;
			for (k in weaponTimers.keys())
				weaponTimers.set(k, WEAPON_TIME);
		}
		#end
		if (baseWeapon != null)
		{
			baseWeaponTimer -= dt;
			if (baseWeaponTimer <= 0)
			{
				// Lejárt: vissza a bolt-felszereléshez (alapból a pisztoly)
				baseWeapon = Upgrades.loadoutKind();
				baseWeaponTimer = Math.POSITIVE_INFINITY;
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

		// Két lövés közti legrövidebb idő: a RAPID (sorozatlövő) minden fegyvernél gyorsít
		var rapid = has(RAPID);
		var cd = switch (baseWeapon)
		{
			case ROCKET: Config.rocketCooldown * (rapid ? Config.rapidMul : 1);
			case GRENADE: Config.grenadeCooldown * (rapid ? Config.rapidMul : 1);
			case LASER: 0.05; // a lézer saját újratöltéssel is bír (laserTimer)
			default: rapid ? RAPID_COOLDOWN : Player.SHOOT_COOLDOWN;
		}
		player.shootCooldown = cd * Upgrades.cooldownMul();
		// A sorozatlövő a töltést is gyorsítja
		player.chargeBoost = rapid ? 1.6 : 1;

		// Sérülés utáni sérthetetlenség alatt gyorsan pislog
		player.visible = player.hurtTimer <= 0 || Std.int(player.hurtTimer * 20) % 2 == 0;

		updateCurses(dt);
	}

	// --- Módosítók (időkorlátos, a hőst nehezítő hatások) -------------------------------

	/** A talajon fekvő módosító tárgyak hatásának hátralévő ideje (a SHROOM a tripTimer-ben van). */
	var curseTimers:Map<PowerKind, Float> = new Map();
	var pixelShader:PixelateShader;
	var torchShader:TorchShader;
	var pixelFilter:openfl.filters.ShaderFilter;
	var tripFilter:openfl.filters.ShaderFilter;
	var torchFilter:openfl.filters.ShaderFilter;
	var asciiShader:AsciiShader;
	var asciiFilter:openfl.filters.ShaderFilter;
	var filterMask:Int = 0;
	var viewFrames:Array<FlxSprite> = [];
	var viewAmount:Float = 0;

	function curseTime(k:PowerKind):Float
	{
		return switch (k)
		{
			case SHROOM: TRIP_TIME;
			case PIXEL: Config.pixelTime;
			case TORCH: Config.torchTime;
			case GHOST: Config.ghostTime;
			case TINYVIEW: Config.viewTime;
			case TINYHERO: Config.tinyTime;
			case MAGNET: Config.magnetTime;
			case ASCII: Config.asciiTime;
			default: 0;
		}
	}

	/** A módosító hátralévő ideje (0 = nem aktív). */
	function curseLeft(k:PowerKind):Float
	{
		if (k == SHROOM)
			return tripTimer;
		return curseTimers.exists(k) ? curseTimers.get(k) : 0;
	}

	/** Módosító bekapcsolása (újra felvéve csak az idő töltődik vissza). */
	function applyCurse(k:PowerKind):Void
	{
		if (k == SHROOM)
		{
			if (tripTimer <= 0)
				tripTime = 0;
			tripTimer = TRIP_TIME;
		}
		else
		{
			var fresh = !curseTimers.exists(k);
			curseTimers.set(k, curseTime(k));
			if (fresh && k == TINYHERO)
				player.applySize(Config.tinyScale);
		}
		Audio.play("trippy");
		announce(PowerUp.label(k), PixelArt.powerColor(k), player.x + player.width / 2, player.y - 4);
	}

	function endCurse(k:PowerKind):Void
	{
		switch (k)
		{
			case TINYHERO:
				player.applySize(1);
			case GHOST:
				player.alpha = 1;
			case MAGNET:
				blocks.forEachAlive(b ->
				{
					if (!b.landed)
						b.acceleration.x = 0;
					b.velocity.x = 0; // a leesett (csúszó) dobozok is megállnak
					if (!b.landed)
						b.maxVelocity.x = 0;
				});
			default:
		}
	}

	/**
	 * Mágnes: a földet ért meteor a talajon a hős felé csúszik (a hatótávon belül), de nem megy bele falba,
	 * másik földet ért dobozba; a peremen túlcsúszva elveszti a támaszt és leesik (updateBlockSupport).
	 */
	function slideLanded(b:Block, px:Float, dt:Float):Void
	{
		var dx = px - (b.x + b.width / 2);
		if (Math.abs(dx) > Config.magnetRange || Math.abs(dx) < 6)
		{
			b.velocity.x = 0;
			return;
		}
		var v = (dx > 0 ? 1 : -1) * Config.magnetSpeed * 0.6;
		var nx = b.x + v * dt;
		var blocked = false;
		ground.forEachAlive(g ->
		{
			if (!blocked && nx < g.x + g.width && nx + b.width > g.x && b.y < g.y + g.height && b.y + b.height - 1 > g.y)
				blocked = true;
		});
		blocks.forEachAlive(o ->
		{
			if (!blocked && o != b && o.landed && nx < o.x + o.width && nx + b.width > o.x && b.y < o.y + o.height && b.y + b.height > o.y)
				blocked = true;
		});
		b.velocity.x = blocked ? 0 : v;
	}

	/** Az összes módosító azonnali megszüntetése (halálkor, cheat). */
	function clearCurses():Void
	{
		for (k in [for (k in curseTimers.keys()) k])
			endCurse(k);
		curseTimers = new Map();
		tripTimer = 0;
		tipsyBites = [];
		player.tipsy = 0;
		viewAmount = 0;
		for (v in viewFrames)
			v.visible = false;
		filterMask = -1;
		refreshFilters();
	}

	/** A kamera shaderei az aktív módosítók szerint (csak változáskor állítjuk át). */
	function refreshFilters():Void
	{
		var mask = (curseTimers.exists(PIXEL) ? 1 : 0) | (tripTimer > 0 || tipsyBites.length > 0 ? 2 : 0) | (curseTimers.exists(TORCH) ? 4 : 0) | (curseTimers.exists(ASCII) ? 8 : 0);
		if (mask == filterMask)
			return;
		filterMask = mask;
		var list:Array<openfl.filters.BitmapFilter> = [];
		if (mask & 1 != 0)
			list.push(pixelFilter);
		if (mask & 2 != 0)
			list.push(tripFilter);
		if (mask & 4 != 0)
			list.push(torchFilter);
		if (mask & 8 != 0)
			list.push(asciiFilter);
		FlxG.camera.filters = list;
	}

	function createCurseFx():Void
	{
		pixelShader = new PixelateShader();
		torchShader = new TorchShader();
		pixelFilter = new openfl.filters.ShaderFilter(pixelShader);
		tripFilter = new openfl.filters.ShaderFilter(tripShader);
		torchFilter = new openfl.filters.ShaderFilter(torchShader);
		asciiShader = new AsciiShader();
		asciiShader.uSize.value = [FlxG.width, FlxG.height];
		asciiFilter = new openfl.filters.ShaderFilter(asciiShader);
		// Összezsugorított látómező: négy fekete sáv a képernyő szélén
		for (i in 0...4)
		{
			var s = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			s.origin.set(0, 0);
			s.scrollFactor.set(0, 0);
			s.visible = false;
			add(s);
			viewFrames.push(s);
		}
	}

	/** A módosítók időzítése és hatása minden képkockában. */
	function updateCurses(dt:Float):Void
	{
		#if cheats
		if (freezePowers)
			for (k in curseTimers.keys())
				curseTimers.set(k, curseTime(k));
		#end
		for (k in [for (k in curseTimers.keys()) k])
		{
			var left = curseTimers.get(k) - dt;
			if (left <= 0)
			{
				curseTimers.remove(k);
				endCurse(k);
				Audio.play("powerdown");
			}
			else
				curseTimers.set(k, left);
		}

		// Pixelesítés és zseblámpa: shader-paraméterek
		if (curseTimers.exists(PIXEL))
		{
			pixelShader.uBlock.value = [Config.pixelBlock];
			pixelShader.uSize.value = [FlxG.width, FlxG.height];
		}
		if (curseTimers.exists(TORCH))
		{
			var left = curseTimers.get(TORCH);
			// Be- és kiúszás: a fénykör fokozatosan szűkül / tágul
			var k = Math.min(1, (Config.torchTime - left) / 0.6) * Math.min(1, left / 0.6);
			torchShader.uCenter.value = [
				player.x + player.width / 2 - FlxG.camera.scroll.x,
				player.y + player.height / 2 - FlxG.camera.scroll.y
			];
			torchShader.uRadius.value = [Config.torchRadius * (1 + 3 * (1 - k))];
			torchShader.uSize.value = [FlxG.width, FlxG.height];
		}

		// Láthatatlan hős
		if (curseTimers.exists(GHOST))
			player.alpha = Config.ghostAlpha;

		// Összezsugorított látómező: a sávok be- és kicsúsznak
		var viewOn = curseTimers.exists(TINYVIEW);
		viewAmount = Math.max(0, Math.min(1, viewAmount + (viewOn ? dt * 2.5 : -dt * 2.5)));
		for (i in 0...4)
			viewFrames[i].visible = viewAmount > 0;
		if (viewAmount > 0)
		{
			// A látható ablak a hős köré záródik (a képernyő szélén belül marad); a hős a közepe fölött áll, hogy a talaj is látsszon
			var vw = FlxG.width * (1 - 2 * Config.viewMarginX), vh = FlxG.height * (1 - 2 * Config.viewMarginY);
			var hx = player.x + player.width / 2 - FlxG.camera.scroll.x, hy = player.y + player.height / 2 - FlxG.camera.scroll.y;
			var wx = Math.max(0, Math.min(FlxG.width - vw, hx - vw / 2)), wy = Math.max(0, Math.min(FlxG.height - vh, hy - vh * 0.6));
			var x0 = wx * viewAmount, y0 = wy * viewAmount;
			var w0 = FlxG.width + (vw - FlxG.width) * viewAmount, h0 = FlxG.height + (vh - FlxG.height) * viewAmount;
			viewFrames[0].setPosition(0, 0);
			viewFrames[0].scale.set(FlxG.width, y0);
			viewFrames[1].setPosition(0, y0 + h0);
			viewFrames[1].scale.set(FlxG.width, Math.max(0, FlxG.height - y0 - h0));
			viewFrames[2].setPosition(0, y0);
			viewFrames[2].scale.set(x0, h0);
			viewFrames[3].setPosition(x0 + w0, y0);
			viewFrames[3].scale.set(Math.max(0, FlxG.width - x0 - w0), h0);
		}

		// Mágnes: a meteorok, ellenséges lövedékek és a repülő ellenségek lassan a hős felé tartanak
		if (curseTimers.exists(MAGNET))
		{
			var px = player.x + player.width / 2, py = player.y + player.height / 2;
			blocks.forEachAlive(b ->
			{
				// A már leesett meteorok is a hős felé csúsznak a földön
				if (b.landed)
				{
					slideLanded(b, px, dt);
					return;
				}
				if (!b.isDangerous())
					return;
				var dx = px - (b.x + b.width / 2);
				if (Math.abs(dx) < Config.magnetRange)
				{
					b.maxVelocity.x = Config.magnetSpeed;
					b.acceleration.x = (dx > 0 ? 1 : -1) * Config.magnetForce;
				}
			});
			enemyShots.forEachAlive(s ->
			{
				if (s.ID != 0)
					return;
				var dx = px - s.x, dy = py - s.y;
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				if (len < Config.magnetRange)
				{
					s.velocity.x += dx / len * Config.magnetForce * 0.6 * dt;
					s.velocity.y += dy / len * Config.magnetForce * 0.6 * dt;
				}
			});
			enemies.forEachAlive(e ->
			{
				if (e.usesGround)
					return;
				var dx = px - (e.x + e.width / 2), dy = py - (e.y + e.height / 2);
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				if (len < Config.magnetRange)
				{
					e.x += dx / len * Config.magnetSpeed * 0.4 * dt;
					e.y += dy / len * Config.magnetSpeed * 0.4 * dt;
				}
			});
		}

		refreshFilters();
	}

	// --- Pontozás és feliratok ----------------------------------------------

	function score():Int
	{
		return distBase + Std.int(FlxG.camera.scroll.x / 10) + bonusPoints;
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
		var ratio = player.energy / player.maxEnergy;
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

		// Érme-számláló az energiacsík alatt: forgó érme ikon és a darabszám (a bónusz-slotok a jobb szélen vannak, nem takarják)
		coinIcon = new FlxSprite(6, 28);
		coinIcon.loadGraphic(PixelArt.coin(), true, 8, 8);
		coinIcon.animation.add("spin", [0, 1, 2, 3], 6);
		coinIcon.animation.play("spin");
		coinIcon.scrollFactor.set(0, 0);
		add(coinIcon);
		coinText = new FlxText(17, 26, 0, "0", 8);
		coinText.color = PixelArt.YELLOW;
		coinText.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		coinText.scrollFactor.set(0, 0);
		add(coinText);

		infoText = new FlxText(110, 4, 0, "", 8);
		infoText.color = PixelArt.LIGHT_GRAY;
		infoText.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		infoText.scrollFactor.set(0, 0);
		add(infoText);

		// Bónusz-slotok a jobb felső sarokban: ikon, név, hátralévő másodperc és fogyó csík.
		// Egyszerre több is aktív lehet: időkorlátos fegyver, kiegészítők, módosítók.
		var slotW = 96;
		var textX = PixelArt.POWER_SIZE + 3;
		var barW = slotW - textX;
		for (i in 0...9)
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

		#if cheats
		devTag = new FlxText(6, FlxG.height - 12, FlxG.width - 12, "", 8);
		devTag.color = 0xffff5ac8;
		devTag.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		devTag.scrollFactor.set(0, 0);
		add(devTag);
		#end

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
		#if cheats
		devTag.text = cheatTagText();
		#end
		updateEnergyBar(dt);

		scoreText.text = 'SCORE ${distBase + Std.int(FlxG.camera.scroll.x / 10) + shownBonus}';
		scoreText.origin.set(0, scoreText.height / 2); // a megugrás balról, középmagasságból
		// A küldetések, a continue-ok és a szünet csak a menüben látszanak; a HUD-on a pálya és a lelőtt meteorok
		infoText.text = 'LEVEL ${Quests.level + 1}   METEORS $blocksDestroyed';
		coinText.text = Std.string(Settings.coins);
		menuContinues = continuesLeft;

		var active:Array<{kind:PowerKind, left:Float, total:Float}> = [];
		if (baseWeapon != null && baseWeaponTimer < Math.POSITIVE_INFINITY)
			active.push({kind: baseWeapon, left: baseWeaponTimer, total: WEAPON_TIME});
		for (k in PowerUp.MODS)
			if (weaponTimers.exists(k))
				active.push({kind: k, left: weaponTimers.get(k), total: WEAPON_TIME});
		for (k in PowerUp.CURSES)
			if (curseLeft(k) > 0)
				active.push({kind: k, left: curseLeft(k), total: curseTime(k)});

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
			slot.icon.visible = true;
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
		coins.forEachAlive(c -> if (c.x + c.width < FlxG.camera.scroll.x - 20) c.kill());
		shrooms.forEachAlive(s -> if (s.x + s.width < left) s.kill());
		var live = 0;
		for (d in debris.members)
		{
			if (d == null || !d.alive || !d.exists)
				continue;
			d.alpha -= 0.03;
			if (d.alpha <= 0 || d.y > FlxG.height)
				d.kill();
			else
				live++;
		}
		debrisLive = live;
	}

	// --- Meteor-csóva, varázsgomba, atom ---------------------------------------------

	/** Izzó parázs a zuhanó meteor mögött. */
	function spawnEmber(x:Float, y:Float):Void
	{
		// Meteorzáporban (sok zuhanó meteor) a parázsok száma korlátos: egyébként több száz sprite lenne egyszerre
		if (debrisLive >= (Perf.lite ? 30 : 130))
			return;
		debrisLive++;
		var d = debris.recycle(FlxSprite);
		// A grafikát csak akkor töltjük újra, ha más színű (a loadGraphic képkockánként drága, és szemetet termel)
		var g = PixelArt.chip(FlxG.random.bool(60) ? PixelArt.ORANGE : PixelArt.YELLOW);
		if (d.graphic != g)
			d.loadGraphic(g);
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
		shroomTimer = FlxG.random.float(Config.shroomIntervalMin, Config.shroomIntervalMax);
		var x0 = FlxG.camera.scroll.x + FlxG.width + 10;
		var spot:FlxSprite = null;
		ground.forEachAlive(g ->
		{
			if (spot == null && g.height > 20 && g.x > x0 - 20 && g.x < x0 + 200 && g.width >= 40)
				spot = g;
		});
		if (spot == null)
			return;
		placeCurse(spot.x + FlxG.random.float(8, spot.width - 18) + PixelArt.SHROOM_SIZE / 2, spot.y, PowerUp.randomCurse());
	}

	/**
	 * Módosító tárgy mint loot: chance % eséllyel a (cx) alatti talajra kerül egy véletlen módosító (a súlyok szerint). Egyszerre legfeljebb
	 * Config.curseMaxItems tárgy lehet a pályán, hogy ne legyen túl sok.
	 */
	function dropCurseLoot(cx:Float, chance:Float):Void
	{
		if (!FlxG.random.bool(chance) || shrooms.countLiving() >= Std.int(Config.curseMaxItems))
			return;
		var gt = groundTopAt(cx);
		if (gt == null)
			return;
		placeCurse(cx, gt, PowerUp.randomCurse());
	}

	/** Módosító tárgy a talajon (varázsgomba, pixelesítő, zseblámpa…): (cx, groundY) a talppont-közép. */
	function placeCurse(cx:Float, groundY:Float, kind:PowerKind):Void
	{
		var s = shrooms.recycle(FlxSprite);
		s.ID = Type.enumIndex(kind);
		if (kind == SHROOM)
		{
			s.loadGraphic(PixelArt.shroom(), true, PixelArt.SHROOM_SIZE, PixelArt.SHROOM_SIZE);
			s.animation.add("glow", [0, 1], 3);
		}
		else
		{
			s.loadGraphic(PixelArt.powerUp(kind), true, PixelArt.POWER_SIZE, PixelArt.POWER_SIZE);
			s.animation.add("glow", [0, 1], 5);
		}
		s.animation.play("glow");
		s.reset(cx - s.width / 2, groundY - s.height);
		s.immovable = true;
	}

	/** Hozzáért a módosító tárgyhoz: a hatás időre bekapcsol (a gomba hallucináció, a többi lásd PowerKind). */
	function eatShroom(s:FlxSprite):Void
	{
		if (!s.alive)
			return;
		s.kill();
		var kind = Type.createEnumIndex(PowerKind, s.ID);
		applyCurse(kind);
		puff(s, PixelArt.powerColor(kind));
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
	}

	// --- Pályák és főellenség -------------------------------------------------------

	/** A pálya összes küldetése kész: a kamera lassan megáll, figyelmeztetés, aztán jön a főellenség. */
	function startBossIntro():Void
	{
		if (levelState != "PLAYING")
			return;
		levelState = "BOSS_INTRO";
		arenaMode = true; // a főellenség-aréna talaja ettől kezdve folytonos és sík
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
					if (!arenaBuilt && !boss.entering)
					{
						arenaBuilt = true;
						// A pókos (STRIDER) pályán nincs platform: a pók a hős alá szúr, a platformról nem lehetne kitérni
						if (boss.kind != BossKind.STRIDER)
							buildArenaPlatforms();
					}
					bossBar.scale.x = Math.max(0, boss.hp / boss.maxHp);
					// Második fázisban vörösebb csík
					bossBar.color = boss.isPhase2() ? 0xffff5a5a : 0xffd04cff;
				}
			case "CLEAR":
				levelStateTimer -= dt;
				if (levelStateTimer <= 0)
					openShop();
			default:
		}
	}

	/** A talaj felső éle az x helyen (a lebegő platformokat nem számítva); null, ha ott szakadék van. */
	function groundTopAt(px:Float):Null<Float>
	{
		var best:Null<Float> = null;
		ground.forEachAlive(g ->
		{
			if (g.height >= 20 && px >= g.x && px <= g.x + g.width && (best == null || g.y < best))
				best = g.y;
		});
		return best;
	}

	/**
	 * A főellenség-aréna talaja: az esetleges szakadékokat betömi (a boss ne lebegjen, a hős se essen be egy szakadékba, miközben a
	 * főellenség fölött ugrál). A szomszédos talajszakaszok közti üres részt a bal oldali szakasz magasságában tölti ki.
	 */
	function fillArenaGaps(from:Float, to:Float):Void
	{
		var segs:Array<FlxSprite> = [];
		ground.forEachAlive(g ->
		{
			if (g.height >= 20 && g.x + g.width > from && g.x < to)
				segs.push(g);
		});
		segs.sort((a, b) -> a.x < b.x ? -1 : (a.x > b.x ? 1 : 0));
		for (i in 0...segs.length - 1)
		{
			var a = segs[i], b = segs[i + 1];
			var start = a.x + a.width, end = b.x;
			if (end - start > 2)
				addGround(start, end - start, a.y);
		}
	}

	/**
	 * Egyirányú platformok az arénában, amikre alulról fel lehet ugrani: egy a bal, egy a jobb szélen, kb. 44 px magasan.
	 * Innen a hős (kb. 60 px-es ugrással) át tud ugrani a főellenség fölött. A főellenség nem veszi figyelembe őket.
	 */
	function buildArenaPlatforms():Void
	{
		var cam = FlxG.camera.scroll.x;
		for (spec in [[cam + 12.0, 72.0], [cam + FlxG.width - 12 - 56, 56.0]])
		{
			var gt = groundTopAt(spec[0] + spec[1] / 2);
			if (gt == null)
				continue;
			addGround(spec[0], spec[1], gt - 44, 8);
		}
	}

	function spawnBoss():Void
	{
		levelState = "BOSS";
		Perf.log("event", {what: "BOSS", level: Quests.level});
		boss = new Boss(lvl != null && lvl.bossLevel >= 0 ? lvl.bossLevel : Quests.level, Quests.level == FINAL_LEVEL ? BossKind.FINAL : BOSS_ORDER[Quests.level % BOSS_ORDER.length]);
		moonfallWarned = false;
		gravityWarned = false;
		boss.target = player;
		fillArenaGaps(FlxG.camera.scroll.x - 200, FlxG.camera.scroll.x + 800);
		arenaBuilt = false;
		if (boss.isFinal)
			Audio.playFinalMusic();
		boss.groundTop = groundTopAt;
		boss.onAttack = bossAttack;
		boss.onMorph = bossMorph;
		insert(members.indexOf(enemies) + 1, boss); // az ellenségek mellé, a HUD és a vignetta alá
		bossDrops = 0;
		bossName.text = '${boss.title}  -  LEVEL ${Quests.level + 1}';
		for (s in ([bossName, bossBarBack, bossBar] : Array<FlxSprite>))
			s.visible = true;
		Audio.play("warning");
	}

	/**
	 * A végső főellenség átváltozásának látványa: 0 = a régi forma lila slime-má olvad (lila villanás, cseppek), 1 = a forma
	 * kicserélődik (fröccsenés, rázkódás, új név a sávon), 2 = az új forma kész (fehér villanás), 3 = megőrül (vörös figyelmeztetés).
	 */
	function bossMorph(b:Boss, phase:Int):Void
	{
		var cx = b.x + b.width / 2, cy = b.y + b.height / 2;
		function goo(n:Int, spread:Float):Void
		{
			var chips = [PixelArt.chip(0xffb05cd6), PixelArt.chip(0xffe0a8ff), PixelArt.chip(PixelArt.PLUM)];
			for (i in 0...n)
			{
				var d = debris.recycle(FlxSprite);
				d.loadGraphic(chips[i % 3]);
				d.reset(cx + FlxG.random.float(-b.width / 2, b.width / 2), cy + FlxG.random.float(-b.height / 2, b.height / 2));
				d.velocity.set(FlxG.random.float(-spread, spread), FlxG.random.float(-spread * 1.3, -20));
				d.acceleration.y = 500;
				d.alpha = 1;
			}
		}
		switch (phase)
		{
			case 0:
				FlxG.camera.flash(0x50b05cd6, 0.25);
				goo(14, 90);
				Audio.play("powerdown", 0.8);
			case 1:
				goo(30, 190);
				FlxG.camera.shake(0.012, 0.25);
				Audio.play("bomb", 0.6);
				bossName.text = '${b.title}  -  ${b.formName}';
			case 2:
				FlxG.camera.flash(0x50ffffff, 0.15);
				Audio.play("powerup", 0.7);
			default:
				showWarning("THE SLIME GOES BERSERK!", 40, 2.6);
				FlxG.camera.flash(0x70ff3040, 0.4);
				Audio.play("alarm");
		}
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
					if (b.kind == BossKind.TANK || b.kind == BossKind.BRUTE || b.kind == BossKind.STALKER)
						// A földön álló főellenség (harckocsi, izomtömeg, nyálka): a meteorok fentről, a hős környékén hullanak
						spawnMeteor(player.x + player.width / 2 + FlxG.random.float(-70, 70), FlxG.random.float(70, 110), reward);
					else
						blocks.recycle(Block, Block.new).spawn(b.x + b.width / 2 + (i == 0 ? -14 : 14), b.y + b.height + 30, 60, reward);
				}
				Audio.play("bombdrop", 0.7);
			case 1:
				// Legyezőlövés a hős felé
				var cx = b.muzzleX(), cy = b.muzzleY();
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
			case 3:
				// Harckocsi: három gyors ágyúlövés a hős felé az ágyú torkolatából
				for (i in 0...3)
					FlxTimer.wait(i * 0.18, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var mx = b.muzzleX(), my = b.muzzleY();
						var a = Math.atan2(player.y + player.height / 2 - my, player.x + player.width / 2 - mx);
						var s = enemyShots.recycle(FlxSprite);
						s.ID = 0;
						s.loadGraphic(PixelArt.enemyShot());
						s.reset(mx - 2, my - 2);
						s.velocity.set(Math.cos(a) * ENEMY_SHOT_SPEED * 1.3, Math.sin(a) * ENEMY_SHOT_SPEED * 1.3);
						s.acceleration.set(0, 0);
						Audio.play("enemyshot", 0.8);
					});
			case 4:
				// Harckocsi aknavető / az izomtömeg gömbhajítása: két bomba repül a toronyból (kezekből) a hős felé (ívben, a földet érve robban)
				for (i in 0...2)
				{
					var s = enemyShots.recycle(FlxSprite);
					s.ID = 1;
					s.loadGraphic(PixelArt.bomb());
					s.reset(b.launchX(i) - s.width / 2, b.launchY(i));
					var dx = player.x + player.width / 2 - s.x + (i == 0 ? -24 : 24);
					s.velocity.set(FlxG.random.float(0.8, 1.1) * dx * 0.55, -230 - i * 40);
					s.acceleration.set(0, 400);
				}
				Audio.play("bombdrop", 0.8);
			case 7:
				// Izomtömeg földrengése: az ugrás landolásakor két alacsony lökéshullám fut végig a talajon mindkét irányba
				// (át kell ugrani rajta); a 2. fázisban egy második pár is jön
				var waves = b.isPhase2() ? 2 : 1;
				for (w in 0...waves)
					FlxTimer.wait(w * 0.45, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						for (dir in [-1, 1])
							spawnShockwave(b.x + b.width / 2 + dir * 18, dir);
						FlxG.camera.shake(0.006, 0.12);
						Audio.play("bomb", 0.6);
					});
			case 12:
				// Bolyhos óriás: pattogó pihegolyókat gurít a hős felé (3-szor pattannak a talajon, aztán eltűnnek)
				var puffs = b.isPhase2() ? 3 : 2;
				for (i in 0...puffs)
					FlxTimer.wait(i * 0.35, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var s = enemyShots.recycle(FlxSprite);
						s.ID = 13; // 10 + a hátralévő pattanások
						s.loadGraphic(PixelArt.puff());
						s.reset(b.muzzleX() - 4, b.muzzleY() - 4);
						var dir = player.x + player.width / 2 < b.x + b.width / 2 ? -1 : 1;
						s.velocity.set(dir * FlxG.random.float(70, 110), -FlxG.random.float(90, 150));
						s.acceleration.set(0, 500);
						Audio.play("enemyshot", 0.5);
					});
			case 13:
				// Bolyhos óriás: a tetejéről spórákat fúj fel, amik lassan szállnak le a hős környékén
				var spores = b.isPhase2() ? 10 : 7;
				for (i in 0...spores)
					FlxTimer.wait(i * 0.07, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var s = enemyShots.recycle(FlxSprite);
						s.ID = 4; // spóra: lelőhető (mint a pattogó pihegolyók, ID >= 10)
						s.loadGraphic(PixelArt.puff());
						s.reset(b.x + b.width / 2 - 4 + FlxG.random.float(-18, 18), b.y + 14);
						var dx = player.x + player.width / 2 - s.x + FlxG.random.float(-60, 60);
						s.velocity.set(dx * 0.4, -FlxG.random.float(110, 190));
						s.acceleration.set(0, 90);
					});
				Audio.play("bombdrop", 0.5);
			case 15:
				// Kiüresedett hold: hullócsillagok jelzik, aztán izzó meteorok zúdulnak a hős környékére
				if (backdrop != null)
					backdrop.shootingStars(7, 1.1);
				// A nagy felirat csak az első alkalommal; később csak a hullócsillagok és a hang jelzik (ne legyen állandó riasztás)
				if (!moonfallWarned)
				{
					moonfallWarned = true;
					showWarning("MOONFALL!", 60, 1.5);
				}
				Audio.play("alarm", 0.5);
				var rocks = b.isPhase2() ? 8 : 5;
				for (i in 0...rocks)
					FlxTimer.wait(1.1 + i * 0.14, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						spawnMeteor(player.x + player.width / 2 + FlxG.random.float(-130, 130), FlxG.random.float(90, 150), null, true);
					});
			case 16:
				// Kiüresedett hold: szilánk-sorozat legyezőben a hős felé
				var sx = b.muzzleX(), sy = b.muzzleY();
				var base16 = Math.atan2(player.y + player.height / 2 - sy, player.x + player.width / 2 - sx);
				var shards = b.isPhase2() ? 7 : 5;
				for (i in 0...shards)
				{
					var a = base16 + (i - (shards - 1) / 2) * 0.26;
					var s = enemyShots.recycle(FlxSprite);
					s.ID = 0;
					s.loadGraphic(PixelArt.enemyShot());
					s.reset(sx - 2, sy - 2);
					s.velocity.set(Math.cos(a) * ENEMY_SHOT_SPEED * 1.15, Math.sin(a) * ENEMY_SHOT_SPEED * 1.15);
					s.acceleration.set(0, 0);
				}
				Audio.play("enemyshot");
			case 17:
				// Kiüresedett hold: gravitációs örvény: ~2.4 mp-ig a hold felé húzza a hőst (futással ellen lehet állni); táguló gyűrűk jelzik
				gravityT = 2.4;
				if (!gravityWarned)
				{
					gravityWarned = true;
					showWarning("GRAVITY WELL!", 60, 1.6);
				}
				Audio.play("trippy", 0.6);
				for (k in 0...5)
					FlxTimer.wait(k * 0.45, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var ring = new FlxSprite(b.x + b.width / 2 - 32, b.y + b.height / 2 - 32);
						ring.makeGraphic(64, 64, FlxColor.TRANSPARENT, true);
						flixel.util.FlxSpriteUtil.drawCircle(ring, 32, 32, 30, FlxColor.TRANSPARENT, {thickness: 2, color: 0xffb05cd6});
						ring.alpha = 0.9;
						ring.scale.set(0.3, 0.3);
						add(ring);
						FlxTween.tween(ring.scale, {x: 3.2, y: 3.2}, 1.0, {ease: FlxEase.quadOut});
						FlxTween.tween(ring, {alpha: 0}, 1.0, {onComplete: _ ->
						{
							remove(ring, true);
							ring.destroy();
						}});
					});
			case 10:
				// Pók: a lábaival tüskéket szúr fel a hős alatt; előbb vörös jelző villan a talajon, aztán feltör a tüske
				var spots = b.isPhase2() ? [0.0, -50.0, 50.0] : [0.0, 45.0];
				for (i in 0...spots.length)
					spawnEruption(player.x + player.width / 2 + spots[i], 0.9 + i * 0.3);
				Audio.play("bombdrop", 0.5);
			case 11:
				// Pók: kis pókokat dob ki magából a potrohából; ezek követik a hőst, és a csípésük "tipsy" hatást ad
				var kids = b.isPhase2() ? 3 : 2;
				for (i in 0...kids)
					FlxTimer.wait(i * 0.3, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var e = enemies.recycle(Enemy, Enemy.new);
						e.spawn(EnemyKind.SPIDERLING, b.launchX(0) - 6, b.launchY(0));
						var dir = player.x + player.width / 2 < b.x + b.width / 2 ? -1 : 1;
						e.velocity.set(dir * FlxG.random.float(50, 100), -FlxG.random.float(130, 190));
						e.target = player;
						e.onFire = enemyFire;
						Audio.play("enemyshot", 0.6);
					});
			case 9:
				// A gyilkos tüskéket hullat: a hátából felrepülnek, és ívben a hős környékére hullanak vissza
				var spikes = b.isPhase2() ? 7 : 5;
				for (i in 0...spikes)
					FlxTimer.wait(i * 0.12, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var s = enemyShots.recycle(FlxSprite);
						s.ID = 0;
						s.loadGraphic(PixelArt.enemyShot());
						s.reset(b.x + b.width / 2 - 2, b.y + 28);
						var dx = player.x + player.width / 2 - s.x + FlxG.random.float(-40, 40);
						s.velocity.set(dx * 0.55, -FlxG.random.float(220, 300));
						s.acceleration.set(0, 380);
					});
				Audio.play("bombdrop", 0.6);
			case 8:
				// A nyálka slime-okat köp a talajra: a hősre ragadva lelassítják
				var n = b.isPhase2() ? 3 : 2;
				for (i in 0...n)
					FlxTimer.wait(i * 0.4, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						spawnEnemyAt(EnemyKind.SLIME, b.x + b.width * 0.3, b.y + b.height);
						Audio.play("enemyshot", 0.6);
					});
			case 5:
				// A háromszemű nyálka: a három szeméből egymás után egy-egy célzott lövés a hős felé
				for (i in 0...3)
					FlxTimer.wait(i * 0.16, () ->
					{
						if (b == null || !b.alive || dead)
							return;
						var mx = b.eyeX(i), my = b.eyeY(i);
						var a = Math.atan2(player.y + player.height / 2 - my, player.x + player.width / 2 - mx);
						var s = enemyShots.recycle(FlxSprite);
						s.ID = 0;
						s.loadGraphic(PixelArt.enemyShot());
						s.reset(mx - 2, my - 2);
						s.velocity.set(Math.cos(a) * ENEMY_SHOT_SPEED * 1.2, Math.sin(a) * ENEMY_SHOT_SPEED * 1.2);
						s.acceleration.set(0, 0);
						Audio.play("enemyshot", 0.7);
					});
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

	/**
	 * Lökéshullám a talajon: a talaj felszínén futó, fényes hullámtaréj (additív fény, kihunyó hullámgyűrűkkel és porral),
	 * ami követi a domborzatot. Az ütközése csak a talajszintet fedi: át kell ugrani rajta.
	 */
	function spawnShockwave(px:Float, dir:Int):Void
	{
		var s = shockwaves.recycle(FlxSprite);
		s.loadGraphic(PixelArt.shockwave(), true, PixelArt.WAVE_W, PixelArt.WAVE_H);
		s.animation.add("wave", [0, 1, 2, 3], 14);
		s.animation.play("wave");
		s.blend = openfl.display.BlendMode.ADD;
		s.flipX = dir < 0;
		// A sprite jobbra fut, a taréj a jobb szélén (x 16..31); a hitbox csak a taréj, a talaj felett 10 px
		s.width = 16;
		s.height = 10;
		s.offset.set(dir > 0 ? 16 : 0, PixelArt.WAVE_H - 10);
		s.reset(px - 8, 0);
		s.velocity.set(dir * 130, 0);
		s.acceleration.set(0, 0);
		s.ID = 0;
		var gt = groundTopAt(px);
		s.y = (gt != null ? gt : 200) - s.height;
	}

	/** A lökéshullámok követik a talajt, port vernek fel, megsebzik a hőst, és eltűnnek a talaj végén / a képernyőn kívül. */
	function updateShockwaves(dt:Float):Void
	{
		shockwaves.forEachAlive(s ->
		{
			var front = s.x + (s.velocity.x > 0 ? s.width : 0);
			var gt = groundTopAt(front);
			if (gt == null || s.x < FlxG.camera.scroll.x - 40 || s.x > FlxG.camera.scroll.x + FlxG.width + 40)
			{
				s.kill();
				return;
			}
			s.y = gt - s.height;
			s.ID++;
			if (s.ID % 5 == 0)
				spawnRunFx(front, gt, s.velocity.x > 0 ? 1 : -1, 0.2, true);
			if (player.alive && player.hurtTimer <= 0 && s.overlaps(player))
				damagePlayer(ENEMY_SHOT_DAMAGE, false);
		});
	}

	/** Tüske tör fel a talajból a `px` helyen `delay` mp múlva; addig vörös jelző villog. Aki a tüske fölött áll, sebződik. */
	function spawnEruption(px:Float, delay:Float):Void
	{
		var gt = groundTopAt(px);
		if (gt == null)
			return;
		var m = new FlxSprite(px - 7, gt - 3);
		m.makeGraphic(14, 3, 0xffff5a5a);
		m.alpha = 0.3;
		add(m);
		FlxTween.tween(m, {alpha: 1}, delay);
		FlxTimer.wait(delay, () ->
		{
			remove(m, true);
			m.destroy();
			if (dead)
				return;
			// Valódi tüske-sprite: gyorsan kinő a talajból (alulról nyúlik), aztán elhalványul
			var s = new FlxSprite(px - PixelArt.SPIKE_W / 2, gt - PixelArt.SPIKE_H);
			s.loadGraphic(PixelArt.spike());
			s.origin.set(PixelArt.SPIKE_W / 2, PixelArt.SPIKE_H);
			s.scale.y = 0.1;
			add(s);
			FlxTween.tween(s.scale, {y: 1}, 0.08);
			FlxTween.tween(s, {alpha: 0}, 0.35, {startDelay: 0.25, onComplete: _ ->
			{
				remove(s, true);
				s.destroy();
			}});
			FlxG.camera.shake(0.006, 0.1);
			Audio.play("stomp", 0.7);
			if (player.alive && player.hurtTimer <= 0 && player.x + player.width > px - 6 && player.x < px + 6 && player.y + player.height > gt - 34 && player.y < gt)
				damagePlayer(BOMB_DAMAGE, false);
		});
	}

	function onBulletHitBoss(bullet:Bullet, b:Boss):Void
	{
		if (!bullet.alive || !b.alive || b.invulnerable())
			return;
		if (bullet.kind == BulletKind.ROCKET || bullet.kind == BulletKind.GRENADE)
		{
			detonate(bullet);
			return;
		}
		if (bullet.kind == BulletKind.LASER)
		{
			if (!bullet.firstHitOn(b))
				return;
		}
		else
			bullet.kill();
		damageBoss(bullet.damage);
		Audio.play("hit", 0.6);
	}

	function damageBoss(amount:Float):Void
	{
		if (boss == null || !boss.alive || boss.entering)
			return;
		#if cheats
		if (bossHpLock)
			return;
		#end
		boss.hit(amount);
		if (boss.hp <= 0)
			defeatBoss();
	}

	/** A főellenség felrobban: robbanássorozat, nagy jutalom, "LEVEL CLEAR", aztán a következő pálya. */
	function defeatBoss():Void
	{
		Audio.restoreMainMusic();
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
		shockwaves.forEachAlive(s -> s.kill());
		addBonus(2500 * (Quests.level + 1), cx, cy);
		// A főellenség érméi egyből a pénztárcába kerülnek (a pálya váltásakor a földön levők eltűnnének)
		var bossCoins = 12 + 4 * Quests.level;
		Settings.coins += bossCoins;
		Settings.store();
		announce('+$bossCoins COINS', PixelArt.YELLOW, cx, cy - 20);
		Quests.add(ENEMIES);
		finishLevel();
	}

	/** A pálya vége: "LEVEL CLEAR", aztán a következő pálya (a főellenség legyőzése vagy a térkép End triggere). */
	function finishLevel():Void
	{
		levelState = "CLEAR";
		levelStateTimer = 4;
		// A pálya végén a felvett fegyverek és módosítók elvesznek; az alap a megvásárolt (felszerelt) fegyver.
		// (A bolt után a nextLevel újra beállítja, hogy az épp megvett fegyver is érvényesüljön.)
		resetWeapons();
		clearCurses();

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
		resetWeapons();
		clearCurses();
		beginLevel(l, false);
		FlxG.camera.fade(PixelArt.OUTLINE, 0.4, true);
		// Az új pálya elején egy kis energia és a küldetések kiírása
		player.applyUpgrades();
		player.energy = Math.min(player.maxEnergy, player.energy + 30);
		questPanel.visible = true;
		questPanelTimer = 5;
		showLevelBanner();
	}

	/** A pályán felvett fegyverek és kiegészítők elvesznek; a bolt-felszerelés (megvásárolt fegyver) marad. */
	function resetWeapons():Void
	{
		baseWeapon = Upgrades.loadoutKind();
		baseWeaponTimer = Math.POSITIVE_INFINITY;
		weaponTimers = new Map();
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

	// --- Cheatek (csak fejlesztői buildben: -debug, -Dtest vagy -Dcheats; a release-ben nincsenek benne) -----

	#if cheats
	/** Sérthetetlen: nincs sebzés (a szakadékba esés is csak visszahelyez). */
	public var godMode:Bool = false;
	/** A bónuszok ideje nem fogy (fegyverek, sérthetetlenség, lassítás, hallucináció). */
	public var freezePowers:Bool = false;
	/** Ki van kapcsolva a meteorok, ellenségek, gombák és a pálya spawnolása. */
	public var noSpawns:Bool = false;

	/** Alapfegyver kiválasztása (null = pisztoly; időkorlátos). */
	public function cheatBaseWeapon(kind:Null<PowerKind>):Void
	{
		baseWeapon = kind;
		baseWeaponTimer = WEAPON_TIME;
		announce(kind == null ? "PISTOL" : PowerUp.shortName(kind), PixelArt.WHITE, player.x + player.width / 2, player.y - 4);
	}

	/** Egy kiegészítő (SPREAD / RAPID) bekapcsolása. */
	public function cheatMod(kind:PowerKind):Void
	{
		weaponTimers.set(kind, WEAPON_TIME);
		announce(PowerUp.shortName(kind), PixelArt.powerColor(kind), player.x + player.width / 2, player.y - 4);
	}

	public function cheatClearMods():Void
	{
		weaponTimers = new Map();
	}

	/** Bármelyik bónusz hatása, mintha felvetted volna. */
	public function cheatPower(kind:PowerKind):Void
	{
		applyPower(kind);
	}

	/** Bónusz a PowerKind nevével (a cheat-menü és a tesztek is használhatják); false, ha ismeretlen név. */
	public function cheatPowerName(name:String):Bool
	{
		for (k in Type.allEnums(PowerKind))
			if (Std.string(k) == name)
			{
				applyPower(k);
				return true;
			}
		return false;
	}

	public function cheatFullEnergy():Void
	{
		player.energy = player.maxEnergy;
	}

	/** A talaj felszíne az adott x-nél a már létrehozott talajszakaszok közül; null, ha nincs. */
	function groundYAt(x:Float):Null<Float>
	{
		var found:Null<Float> = null;
		ground.forEachAlive(g ->
		{
			if (g.height > 20 && x >= g.x && x <= g.x + g.width)
				found = g.y;
		});
		return found;
	}

	/** A hős előtt, a képernyőn belül (nem a szélén): a cheatek ide teszik a dolgokat. */
	function cheatSpotX(ahead:Float):Float
	{
		return Math.min(FlxG.camera.scroll.x + FlxG.width - 40, player.x + ahead);
	}

	public function cheatShroom():Void
	{
		var x = cheatSpotX(110);
		var gy = groundYAt(x);
		placeCurse(x, gy != null ? gy : GROUND_Y, PowerUp.randomCurse());
	}

	/** Egy módosító azonnali bekapcsolása (mintha felvetted volna a tárgyat). */
	public function cheatCurse(kind:PowerKind):Void
	{
		applyCurse(kind);
	}

	/** Az összes módosító megszüntetése. */
	public function cheatClearCurses():Void
	{
		clearCurses();
	}


	public function cheatEnemy(kindIndex:Int):Void
	{
		var kind:EnemyKind = cast kindIndex;
		var x = cheatSpotX(140);
		var gy = groundYAt(x);
		var y:Float = switch (kind)
		{
			case EnemyKind.BAT: 120;
			case EnemyKind.DRONE: 40;
			default: gy != null ? gy : GROUND_Y;
		}
		spawnEnemyAt(kind, x, y);
	}

	/** Meteor a hős fölé-elé: sima vagy arany (jutalmat ad). */
	public function cheatMeteor(gold:Bool):Void
	{
		spawnMeteor(cheatSpotX(70), 100, gold ? PowerUp.random() : null);
	}

	/** Egy rövid meteorzápor a képernyő jobb felén. */
	public function cheatShower():Void
	{
		for (i in 0...10)
			new flixel.util.FlxTimer().start(i * 0.15, _ -> spawnMeteor(FlxG.camera.scroll.x + FlxG.random.float(0.3, 1.0) * FlxG.width, FlxG.random.float(80, 160), null));
	}

	/** Meteoreső figyelmeztetéssel, mint a pályákon. */
	public function cheatMeteorFall():Void
	{
		meteorFall(14, 520, 70, 150, 6, null, true);
	}

	/** Térképes pályán a főellenség-aréna elé ugrik, procedurálison azonnal indítja a főellenséget. */
	public function cheatSkipToBoss():Void
	{
		if (levelState != "PLAYING")
			return;
		if (lvl != null && lvl.bossX >= 0)
			seek(lvl.bossX - 150); // a kamera a trigger (bossX - 160) után áll meg, így a főellenség rögtön indul
		else
			startBossIntro();
	}

	/** Cheat: a főellenség életereje nem csökken (hogy egy állapotot nyugodtan lehessen tesztelni). */
	public var bossHpLock:Bool = false;

	/** Cheat: a főellenség életerejét a maximum adott törtrészére állítja (legalább 1 HP). */
	public function cheatBossHp(fraction:Float):Void
	{
		if (boss != null && boss.alive)
			boss.hp = Math.max(1, boss.maxHp * fraction);
	}

	/** Cheat: a főellenség életereje szövegesen (a menü sorához). */
	public function cheatBossHpText():String
	{
		if (boss == null || !boss.alive)
			return "NO BOSS";
		return 'BOSS HP: ${Std.int(boss.hp)} / ${Std.int(boss.maxHp)} (${Std.int(boss.hp / boss.maxHp * 100)}%)';
	}

	/** Cheat: a végső főellenség azonnali átváltozása. */
	public function cheatBossMorph():Void
	{
		if (boss != null && boss.alive)
			boss.cheatMorph();
	}

	/** A főellenség azonnali legyőzése (ha éppen van). */
	public function cheatKillBoss():Void
	{
		if (boss != null && boss.alive)
			defeatBoss();
	}

	public function cheatNextLevel():Void
	{
		if (boss != null && boss.alive)
			boss.kill();
		for (s in ([bossName, bossBarBack, bossBar] : Array<FlxSprite>))
			s.visible = false;
		nextLevel();
	}

	/** Ugrás egy tetszőleges pályára (0-tól): új küldetések, a felvett fegyverek és módosítók törlődnek. */
	public function cheatGotoLevel(l:Int):Void
	{
		l = Std.int(Math.max(0, l));
		if (boss != null && boss.alive)
			boss.kill();
		for (s in ([bossName, bossBarBack, bossBar] : Array<FlxSprite>))
			s.visible = false;
		Quests.startLevel(l);
		resetWeapons();
		clearCurses();
		beginLevel(l, false);
		FlxG.camera.fade(PixelArt.OUTLINE, 0.4, true);
		player.applyUpgrades();
		player.energy = player.maxEnergy;
		questPanel.visible = true;
		questPanelTimer = 5;
		showLevelBanner();
	}

	public function cheatPreviousLevel():Void
	{
		cheatGotoLevel(Quests.level - 1);
	}

	/** Egyből a végső főellenséghez (a 9. pálya főellenségéhez). */
	public function cheatSkipToFinalBoss():Void
	{
		cheatGotoLevel(FINAL_LEVEL);
		cheatSkipToBoss();
	}

	public function cheatCompleteQuests():Void
	{
		for (g in Quests.goals.copy())
			Quests.add(g.type, 100000);
	}


	/** A hibakereső jelzés szövege a HUD alján. */
	function cheatTagText():String
	{
		var t = "DEV  F9: CHEATS  F10: BOSS";
		if (godMode)
			t += "  GOD";
		if (freezePowers)
			t += "  POWERS-FROZEN";
		if (noSpawns)
			t += "  NO-SPAWNS";
		return t;
	}
	#end

	// --- Halál és folytatás ---------------------------------------------------------

	/** Elfogyott az energia: ha van még folytatás, felajánljuk, különben vége. */
	function die():Void
	{
		if (dead)
			return;
		dead = true;
		FlxG.timeScale = 1;
		clearCurses();
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
		player.energy = player.maxEnergy;
		player.hurtTimer = 3;
		respawnPlayer();
		enemyShots.forEachAlive(s -> s.kill());
		shockwaves.forEachAlive(s -> s.kill());
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
		// Végleges vég: teljes reset az érmékben és a fegyverekben is (a megvásárolt fegyverek elvesznek, újra a pisztoly az alap)
		var lostInfo = Settings.resetRun();
		var lostText = (lostInfo.coins > 0 ? '\nCoins lost: ${lostInfo.coins}' : "") + (lostInfo.weapons ? "\nShop weapons lost" : "");
		gameOverText.text = 'GAME OVER  (${Settings.difficultyName()})\nScore: $finalScore$record$lostText\n\nR / ENTER: restart\nESC: title';
		gameOverText.visible = true;
		deathDim.visible = true;
		// Globális ranglista: névbeírás és a lista (ha be van állítva és van pont)
		if (Leaderboard.canSubmit() && finalScore > 0)
			openSubState(new LeaderboardSubState(finalScore, Quests.level));
	}
}
