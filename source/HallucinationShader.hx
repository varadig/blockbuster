package;

import flixel.system.FlxAssets.FlxShader;

/**
 * Hallucináció (varázsgomba): hullámzó torzítás és színeltolódás az egész képen.
 * uAmount: 0 = nincs hatás, 1 = teljes; uTime: idő másodpercben.
 */
class HallucinationShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;
		uniform float uAmount;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			// Hullámzás: vízszintes és függőleges szinuszos eltolás
			uv.x += sin(uv.y * 22.0 + uTime * 4.0) * 0.012 * uAmount;
			uv.y += cos(uv.x * 17.0 + uTime * 3.1) * 0.010 * uAmount;
			vec4 c = flixel_texture2D(bitmap, uv);

			// Kromatikus szétcsúszás: a vörös és kék csatorna kicsit máshonnan jön
			float off = 0.006 * uAmount;
			c.r = mix(c.r, flixel_texture2D(bitmap, uv + vec2(off, 0.0)).r, uAmount);
			c.b = mix(c.b, flixel_texture2D(bitmap, uv - vec2(off, 0.0)).b, uAmount);

			// Lassan forgó színárnyalat-eltolás
			float a = uTime * 1.6;
			vec3 tint = vec3(0.5 + 0.5 * sin(a), 0.5 + 0.5 * sin(a + 2.094), 0.5 + 0.5 * sin(a + 4.188));
			c.rgb = mix(c.rgb, c.rgb * (0.6 + tint * 0.9), 0.55 * uAmount);

			gl_FragColor = c;
		}
	')
	public function new()
	{
		super();
		uTime.value = [0.0];
		uAmount.value = [0.0];
	}
}
