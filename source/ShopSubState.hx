package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;

/**
 * Bolt: az érmékből tartós fejlesztések és fegyverek ikonokkal. Pályavégén (`atLevelEnd`) a következő pálya előtt,
 * és a címképernyőről is nyílik. A megvett fegyver felszerelhető: a futás azzal indul.
 */
class ShopSubState extends FlxSubState
{
	static inline var ROW_Y:Int = 66;
	static inline var ROW_H:Int = 13;

	var atLevelEnd:Bool;
	var menu:MenuList;
	var coinText:FlxText;
	var info:FlxText;

	public function new(atLevelEnd:Bool)
	{
		super(0xf0101020);
		this.atLevelEnd = atLevelEnd;
	}

	/** Sorok: a fejlesztések, a pisztoly, a megvehető fegyverek, végül a kilépés. */
	function rowCount():Int
		return Upgrades.LIST.length + 1 + Upgrades.WEAPONS.length + 1;

	override public function create():Void
	{
		super.create();
		UiCam.apply(this); // a játék kameraeffektjei (shaderek) a menüt nem érintik
		Settings.load();

		var title = new FlxText(0, 22, FlxG.width, "SHOP", 16);
		title.alignment = CENTER;
		title.color = PixelArt.YELLOW;
		title.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		title.scrollFactor.set(0, 0);
		add(title);

		coinText = new FlxText(0, 46, FlxG.width, "", 8);
		coinText.alignment = CENTER;
		coinText.color = PixelArt.WHITE;
		coinText.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		coinText.scrollFactor.set(0, 0);
		add(coinText);

		var items:Array<Void->String> = [];
		for (i in 0...rowCount())
			items.push(() -> row(i));
		menu = new MenuList(ROW_Y, items, 8, ROW_H);
		menu.isDisabled = i -> !selectable(i);
		menu.onSelect = i -> activate(i);
		add(menu);

		// Ikonok a sorok mellett
		for (i in 0...rowCount() - 1)
		{
			var s = new FlxSprite(112, ROW_Y + i * ROW_H - 2);
			s.loadGraphic(iconFor(i), true, PixelArt.POWER_SIZE, PixelArt.POWER_SIZE);
			s.animation.frameIndex = 0;
			s.scrollFactor.set(0, 0);
			add(s);
		}

		info = new FlxText(0, 196, FlxG.width, "", 8);
		info.alignment = CENTER;
		info.color = PixelArt.LIGHT_GRAY;
		info.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		info.scrollFactor.set(0, 0);
		add(info);

		var hint = new FlxText(0, 226, FlxG.width, "UP / DOWN  select     SPACE  buy / equip     ESC  " + (atLevelEnd ? "skip" : "back"), 8);
		hint.alignment = CENTER;
		hint.color = PixelArt.GRAY;
		hint.setBorderStyle(OUTLINE, PixelArt.OUTLINE, 1);
		hint.scrollFactor.set(0, 0);
		add(hint);
	}

	function iconFor(i:Int):FlxGraphic
	{
		var nu = Upgrades.LIST.length;
		if (i < nu)
		{
			var ic = Upgrades.LIST[i].icon;
			return ic == "ARMOR" || ic == "BASEGUN" ? PixelArt.shopIcon(ic) : PixelArt.powerUp(Type.createEnum(PowerUp.PowerKind, ic));
		}
		if (i == nu)
			return PixelArt.shopIcon("BASEGUN");
		return PixelArt.powerUp(Upgrades.WEAPONS[i - nu - 1].kind);
	}

	/** Egy sor szövege. */
	function row(i:Int):String
	{
		var nu = Upgrades.LIST.length;
		if (i < nu)
		{
			var l = Upgrades.level(i), m = Upgrades.maxLevel(i);
			var c = Upgrades.nextCost(i);
			return '${Upgrades.LIST[i].name}   LV $l/$m   ' + (c == null ? "MAX" : '$c COINS');
		}
		if (i == nu)
			return "PISTOL   " + (Upgrades.equipped(-1) ? "EQUIPPED" : "EQUIP");
		if (i < nu + 1 + Upgrades.WEAPONS.length)
		{
			var w = i - nu - 1;
			var d = Upgrades.WEAPONS[w];
			return '${d.name}   ' + (Upgrades.equipped(w) ? "EQUIPPED" : (Upgrades.owns(w) ? "EQUIP" : '${d.cost} COINS'));
		}
		return atLevelEnd ? "NEXT LEVEL" : "BACK";
	}

	function selectable(i:Int):Bool
	{
		var nu = Upgrades.LIST.length;
		if (i < nu)
			return Upgrades.canBuy(i);
		if (i == nu)
			return !Upgrades.equipped(-1);
		if (i < nu + 1 + Upgrades.WEAPONS.length)
		{
			var w = i - nu - 1;
			return !Upgrades.equipped(w) && (Upgrades.owns(w) || Settings.coins >= Upgrades.WEAPONS[w].cost);
		}
		return true;
	}

	function activate(i:Int):Void
	{
		var nu = Upgrades.LIST.length;
		if (i < nu)
		{
			if (Upgrades.buy(i))
				Audio.play("coin");
		}
		else if (i <= nu + Upgrades.WEAPONS.length)
		{
			if (Upgrades.buyOrEquip(i - nu - 1))
				Audio.play("coin");
		}
		else
			leave();
	}

	function leave():Void
	{
		Audio.play("blip");
		close();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		coinText.text = 'COINS  ${Settings.coins}';
		var nu = Upgrades.LIST.length;
		var s = menu.selected;
		if (s < nu)
			info.text = Upgrades.LIST[s].desc;
		else if (s == nu)
			info.text = "The starting gun: one bullet at a time.";
		else if (s <= nu + Upgrades.WEAPONS.length)
			info.text = Upgrades.WEAPONS[s - nu - 1].desc + ". Starts every run equipped.";
		else
			info.text = atLevelEnd ? "Spend your coins before the next level." : "";
		if (menu.isReady() && (FlxG.keys.justPressed.ESCAPE || Pad.just(BACK)))
			leave();
	}
}
