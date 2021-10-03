This can only work on anything rendered in the transparent pass or later.

Example shaders:
/Assets/Test/UnderwaterExampleShader.shader (very basic for example purposes)
/Assets/Test/UnderwaterSurfaceShader.shader (got this working but not correct as we do not have enough control)
/Assets/Test/UnderwaterTransparentShader.shader (same as example but with basic lighting added for testing)

The includes file:
/Assets/Crest/Crest/Shaders/Underwater/UnderwaterEffectIncludes.hlsl

The main function which adds the fog to the provided color and returns it:
ApplyUnderwaterFog(color, clip space position, world space position)

Function to check whether to apply fog (screen UV is same as you would use to sample depth texture etc):
IsUnderwater(screen uv)

Either apply underwater fog or Unity fog using above function.