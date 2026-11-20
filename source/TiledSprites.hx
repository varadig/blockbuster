package;

/** Egy Tiled-objektum-csempe: sprite-fájl neve, Class, a horgonypont és az alap tulajdonságok. */
typedef TiledTile =
{
	name:String,
	cls:String,
	/** Hol van az objektum "pontja" a sprite-on: "b" alsó közép (talppont), "c" közép, "bl" bal alsó sarok. */
	anchor:String,
	?def:Dynamic
}

/**
 * A Tiled-ben a pont-objektumok helyett csempe-objektumok vannak (levels/objects.tsj: a játék sprite-jai), hogy a térképen látszódjon, mi micsoda.
 * A tábla sorrendje a csempekészlet `id`-ja; a `LevelLoader` a gid-ből ezt használja, ha az objektumnak nincs saját osztálya / tulajdonsága.
 * Az objektum helye a Tiled-ben a sprite bal alsó sarka: a betöltő a `anchor` szerint számolja vissza a pontot (pl. "b": x + szélesség/2, y).
 */
class TiledSprites
{
	public static final POWERS = ["SPREAD", "RAPID", "HOMING", "ROCKET", "LASER", "GRENADE", "BONUS", "ENERGY"];
	public static final CURSES = ["SHROOM", "PIXEL", "TORCH", "GHOST", "TINYVIEW", "TINYHERO", "MAGNET", "ASCII"];
	public static final ENEMIES = ["SLIME", "BAT", "TURRET", "DRONE"];

	public static final TILES:Array<TiledTile> = build();

	static function build():Array<TiledTile>
	{
		var l:Array<TiledTile> = [{name: "player", cls: "Player", anchor: "b"}];
		for (e in ENEMIES)
			l.push({name: "enemy_" + e.toLowerCase(), cls: "Enemy", anchor: "b", def: {kind: e}});
		for (p in POWERS)
			l.push({name: "pickup_" + p.toLowerCase(), cls: "Pickup", anchor: "c", def: {kind: p}});
		l.push({name: "shroom", cls: "Shroom", anchor: "b"});
		for (c in CURSES)
			l.push({name: "shroom_" + c.toLowerCase(), cls: "Shroom", anchor: "b", def: {kind: c}});
		l.push({name: "meteor", cls: "Meteor", anchor: "c"});
		l.push({name: "meteor_gold", cls: "Meteor", anchor: "c", def: {reward: "RANDOM"}});
		l.push({name: "meteorfall", cls: "Meteorfall", anchor: "c"});
		l.push({name: "boss", cls: "Boss", anchor: "bl"});
		l.push({name: "end", cls: "End", anchor: "bl"});
		return l;
	}
}
