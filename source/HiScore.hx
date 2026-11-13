package;

import flixel.util.FlxSave;

/** A legjobb pontszám tartós tárolása nehézségi szintenként (böngészőben localStorage, natívan fájl). */
class HiScore
{
	static var save:FlxSave;

	static function bind():FlxSave
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("blockbuster");
		}
		return save;
	}

	/** A NORMAL szint a korábbi "hiscore" kulcsot használja, hogy a régi rekord megmaradjon. */
	static function field():String
	{
		return switch (Settings.difficulty)
		{
			case EASY: "hiscore_easy";
			case HARD: "hiscore_hard";
			default: "hiscore";
		}
	}

	public static function get():Int
	{
		var v:Null<Int> = Reflect.field(bind().data, field());
		return v != null ? v : 0;
	}

	/** Eltárolja, ha jobb az eddiginél. */
	public static function submit(score:Int):Void
	{
		if (score <= get())
			return;
		var s = bind();
		Reflect.setField(s.data, field(), score);
		s.flush();
	}
}
