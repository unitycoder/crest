// Crest Ocean System

// This file is subject to the MIT License as seen in the root of this folder structure (LICENSE)

#ifndef CREST_UNDERWATER_EFFECT_INCLUDES_INCLUDED
#define CREST_UNDERWATER_EFFECT_INCLUDES_INCLUDED

// For this to work with a surface shader, adhere to the following:
// - wrap anything the compiler complains about with "#ifndef SHADER_TARGET_SURFACE_ANALYSIS".
// - const is not supported and wrapping is too much trouble.
// https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/master/CGIncludes/HLSLSupport.cginc
#ifdef SHADER_TARGET_SURFACE_ANALYSIS
bool IsUnderwater(float2 a) { return a; }
half3 ApplyUnderwaterFog(half3 a, float4 b, float3 c) { return a + b + c; }
#else // SHADER_TARGET_SURFACE_ANALYSIS

UNITY_DECLARE_SCREENSPACE_TEXTURE(_CrestOceanMaskTexture);

half3 _CrestDiffuse;
half3 _CrestDiffuseGrazing;

#if CREST_SHADOWS_ON
half3 _CrestDiffuseShadow;
#endif

#define CREST_NO_MSAA_HELPERS

#if CREST_SUBSURFACESCATTERING_ON
half3 _CrestSubSurfaceColour;
half _CrestSubSurfaceBase;
half _CrestSubSurfaceSun;
half _CrestSubSurfaceSunFallOff;
#endif

half3 _CrestAmbientLighting;
half4 _CrestDepthFogDensity;

#include "../OceanConstants.hlsl"
#include "../OceanGlobals.hlsl"
#include "../OceanInputsDriven.hlsl"
#include "../OceanShaderHelpers.hlsl"
#include "../OceanLightingHelpers.hlsl"
#include "../OceanHelpersNew.hlsl"

half3 ScatterColour
(
	const half3 i_ambientLighting,
	const half3 i_lightCol,
	const half3 i_lightDir,
	const half3 i_view,
	const float i_shadow
)
{
	// Base colour.
	float v = abs(i_view.y);
	half3 col = lerp(_CrestDiffuse, _CrestDiffuseGrazing, 1. - pow(v, 1.0));

#if CREST_SHADOWS_ON
	col = lerp(_CrestDiffuseShadow, col, i_shadow);
#endif

#if CREST_SUBSURFACESCATTERING_ON
	{
		col *= i_ambientLighting;

		// Approximate subsurface scattering - add light when surface faces viewer. Use geometry normal - don't need high freqs.
		half towardsSun = pow(max(0., dot(i_lightDir, -i_view)), _CrestSubSurfaceSunFallOff);
		half3 subsurface = (_CrestSubSurfaceBase + _CrestSubSurfaceSun * towardsSun) * _CrestSubSurfaceColour.rgb * i_lightCol * i_shadow;
		col += subsurface;
	}
#endif // CREST_SUBSURFACESCATTERING_ON

	return col;
}

bool IsUnderwater(const float2 screenUV)
{
	return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CrestOceanMaskTexture, screenUV).x == UNDERWATER_MASK_BELOW_SURFACE;
}

half3 ApplyUnderwaterFog(const half3 color, const float4 positionCS, const float3 positionWS)
{
	half3 lightColor = _LightColor0.rgb;
	float3 lightDirection = WorldSpaceLightDir(positionWS);
	float pixelZ = CrestLinearEyeDepth(positionCS.z);
	half3 view =  normalize(_WorldSpaceCameraPos - positionWS);

	half shadow = 1.0;
#if CREST_SHADOWS_ON
	{
		// Offset slice so that we do not get high frequency detail. But never use last lod as this has crossfading.
		int sliceIndex = clamp(_CrestDataSliceOffset, 0, _SliceCount - 2);
		const float3 uv = WorldToUV(_WorldSpaceCameraPos.xz, _CrestCascadeData[sliceIndex], sliceIndex);
		// Camera should be at center of LOD system so no need for blending (alpha, weights, etc).
		shadow = _LD_TexArray_Shadow.SampleLevel(LODData_linear_clamp_sampler, uv, 0.0).x;
		shadow = saturate(1.0 - shadow);
	}
#endif // CREST_SHADOWS_ON

	half3 scatterColor = ScatterColour
	(
		_CrestAmbientLighting,
		lightColor,
		lightDirection,
		view,
		shadow
	);

	return lerp(color, scatterColor, saturate(1.0 - exp(-_CrestDepthFogDensity.xyz * pixelZ)));
}

#endif // !SHADER_TARGET_SURFACE_ANALYSIS
#endif // CREST_UNDERWATER_EFFECT_INCLUDES_INCLUDED
