Shader "Unlit/UnderwaterTransparentShader"
{
	Properties
	{
		_Color ("Color", Color) = (0.5, 0.5, 0.5, 0.5)
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Back

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert alpha
			#pragma fragment frag alpha

			#pragma multi_compile_fog

			#pragma multi_compile _ VERTEXLIGHT_ON

			#pragma multi_compile __ CREST_SUBSURFACESCATTERING_ON
			#pragma multi_compile __ CREST_SHADOWS_ON

			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityStandardBRDF.cginc"

			#include "/Assets/Crest/Crest/Shaders/Underwater/UnderwaterEffectIncludes.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 worldPos : TEXCOORD2;
				half4 screenPos : TEXCOORD4;
			};

			float4 _Color;
			float _Metallic;
			float _Smoothness;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				UNITY_TRANSFER_FOG(o, o.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 view = normalize(_WorldSpaceCameraPos - i.worldPos);

				float3 specularTint;
				float oneMinusReflectivity;
				fixed3 color = _Color.rgb;
				color = DiffuseAndSpecularFromMetallic(
					color, _Metallic, specularTint, oneMinusReflectivity
				);

				UnityLight light;
				light.color = _LightColor0.rgb;
				light.dir = _WorldSpaceLightPos0.xyz;
				light.ndotl = DotClamped(i.normal, light.dir);
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;
// #if defined(VERTEXLIGHT_ON)
// 				indirectLight.diffuse = i.vertexLightColor;
// #endif
				indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));

				color = UNITY_BRDF_PBS(
					color, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, view,
					light, indirectLight
				);

				// CREST
				float2 screenUV = i.screenPos.xy / i.screenPos.w;

				// Only apply underwater fog when underwater; otherwise, apply Unity fog.
				if (CrestIsUnderwater(screenUV))
				{
					color.rgb = CrestApplyUnderwaterFog(color.rgb, i.vertex, i.worldPos);
				}
				else
				{
					UNITY_APPLY_FOG(i.fogCoord, color);
				}
				// ENDCREST

				return fixed4(color, _Color.a);
			}
			ENDCG
		}
	}
}
