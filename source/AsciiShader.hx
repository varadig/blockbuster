package;

import flixel.system.FlxAssets.FlxShader;

/**
 * ASCII-mód (módosító): a kép `uCell` méretű cellákra esik szét, és mindegyik helyén egy színhelyes betű/jel látszik
 * (a cella átlagos fényessége választja a jelet: ' ' . : - + x # @), a színe a cella átlagos színe.
 * uSize: a kamera mérete pixelben, uCell: egy karakter cellája (a jel 5x7 pixeles, 1 px hézaggal).
 */
class AsciiShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform vec2 uSize;
		uniform vec2 uCell;

		float dotAt(vec2 ip, float x, float y)
		{
			return step(abs(ip.x - x), 0.5) * step(abs(ip.y - y), 0.5);
		}

		float rowOn(vec2 ip, float y, float x0, float x1)
		{
			return step(abs(ip.y - y), 0.5) * step(x0 - 0.5, ip.x) * step(ip.x, x1 + 0.5);
		}

		float colOn(vec2 ip, float x, float y0, float y1)
		{
			return step(abs(ip.x - x), 0.5) * step(y0 - 0.5, ip.y) * step(ip.y, y1 + 0.5);
		}

		float glyph(float lum, vec2 ip)
		{
			float r = 0.0;
			if (lum < 0.07)
				r = 0.0;
			else if (lum < 0.2)
				r = dotAt(ip, 2.0, 5.0); // .
			else if (lum < 0.32)
				r = max(dotAt(ip, 2.0, 2.0), dotAt(ip, 2.0, 5.0)); // :
			else if (lum < 0.44)
				r = rowOn(ip, 3.0, 1.0, 3.0); // -
			else if (lum < 0.56)
				r = max(rowOn(ip, 3.0, 0.0, 4.0), colOn(ip, 2.0, 1.0, 5.0)); // +
			else if (lum < 0.7)
			{
				// x: két átló
				for (int i = 0; i < 5; i++)
				{
					float k = float(i);
					r = max(r, dotAt(ip, k, 1.0 + k));
					r = max(r, dotAt(ip, 4.0 - k, 1.0 + k));
				}
			}
			else if (lum < 0.85)
				r = max(max(rowOn(ip, 2.0, 0.0, 4.0), rowOn(ip, 4.0, 0.0, 4.0)), max(colOn(ip, 1.0, 0.0, 6.0), colOn(ip, 3.0, 0.0, 6.0))); // #
			else
			{
				// @: tömör doboz két lyukkal
				r = step(-0.5, ip.x) * step(ip.x, 4.5) * step(-0.5, ip.y) * step(ip.y, 6.5);
				r *= 1.0 - dotAt(ip, 2.0, 2.0);
				r *= 1.0 - dotAt(ip, 2.0, 4.0);
			}
			return r;
		}

		void main()
		{
			vec2 p = openfl_TextureCoordv * uSize;
			vec2 origin = floor(p / uCell) * uCell;
			vec2 ip = floor(p - origin);

			vec4 s = flixel_texture2D(bitmap, (origin + uCell * 0.5) / uSize);
			s += flixel_texture2D(bitmap, (origin + uCell * vec2(0.25, 0.25)) / uSize);
			s += flixel_texture2D(bitmap, (origin + uCell * vec2(0.75, 0.25)) / uSize);
			s += flixel_texture2D(bitmap, (origin + uCell * vec2(0.25, 0.75)) / uSize);
			s += flixel_texture2D(bitmap, (origin + uCell * vec2(0.75, 0.75)) / uSize);
			s /= 5.0;

			// Gamma-korrekció: a játék sötét jeleneteiben is látszódjon elég betű
			float lum = min(1.0, pow(dot(s.rgb, vec3(0.299, 0.587, 0.114)), 0.5) * 1.15);
			float on = glyph(lum, ip);
			// A betű élénk, a cella saját színében; a háttér a színének sötét változata
			vec3 fg = clamp(s.rgb / max(max(s.r, max(s.g, s.b)), 0.15) * (0.6 + 0.4 * lum), 0.0, 1.0);
			vec3 bg = s.rgb * 0.3;
			gl_FragColor = vec4(mix(bg, fg, on), 1.0);
		}
	')
	public function new()
	{
		super();
		uSize.value = [480.0, 270.0];
		uCell.value = [6.0, 8.0];
	}
}
