package;

import flixel.system.FlxAssets.FlxShader;

/**
 * Zseblámpa (módosító): csak a `uCenter` (képernyő-pixel) körüli `uRadius` sugarú kör látszik, a többi sötét.
 * uSize: a kamera mérete pixelben.
 */
class TorchShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform vec2 uCenter;
		uniform float uRadius;
		uniform vec2 uSize;

		void main()
		{
			vec4 c = flixel_texture2D(bitmap, openfl_TextureCoordv);
			float d = distance(openfl_TextureCoordv * uSize, uCenter);
			// Puha szél: a kör belseje teljes fényű, a pereme felé elsötétül
			float k = 1.0 - smoothstep(uRadius * 0.55, uRadius, d);
			gl_FragColor = vec4(c.rgb * k, c.a);
		}
	')
	public function new()
	{
		super();
		uCenter.value = [240.0, 135.0];
		uRadius.value = [48.0];
		uSize.value = [480.0, 270.0];
	}
}
