package;

import flixel.system.FlxAssets.FlxShader;

/**
 * Pixelesítés (módosító): az egész kép `uBlock` belső pixel széles blokkokra esik szét (nehezebb látni).
 * uSize: a kamera mérete pixelben.
 */
class PixelateShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uBlock;
		uniform vec2 uSize;

		void main()
		{
			vec2 p = openfl_TextureCoordv * uSize;
			p = (floor(p / uBlock) + 0.5) * uBlock;
			gl_FragColor = flixel_texture2D(bitmap, p / uSize);
		}
	')
	public function new()
	{
		super();
		uBlock.value = [1.0];
		uSize.value = [480.0, 270.0];
	}
}
