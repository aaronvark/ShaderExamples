// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Surf1" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_GlossMap("Gloss Map", 2D) = "black" {}
		_NormalMap("Normal Map", 2D) = "blue" {}
		_HeightMap("Height Map", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Tess("Tessellation", Range(1,64)) = 1.0
		_HeightPower("Height Map Influence", Range(0,1)) = 0.1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow tessellate:tessDistance

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 4.6
		#include "Tessellation.cginc"

		sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _HeightMap;
		sampler2D _GlossMap;

		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMap;
			float2 uv_HeightMap;
			float3 viewDir;
			float4 screenPos;
			float3 worldPos;
			//float3 worldRefl; INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;
		float _Tess;
		float _HeightPower;
		fixed4 _Color;

		float4 _HeightMap_ST;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		float4 tessFixed() {
			return _Tess;
		}

		float4 tessDistance(appdata_full v0, appdata_full v1, appdata_full v2)
		{
			float minDist = 1;
			float maxDist = 10.0;
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
		}

		void vert(inout appdata_full v) {
			//calculate world position
			float2 uv = TRANSFORM_TEX(v.texcoord.xy, _HeightMap);
			float4 norm = tex2Dlod(_HeightMap, float4(uv,0,0));
			v.vertex.xyz += v.normal * norm.r * _HeightPower;// +sin(_Time.y + v.texcoord.x * 6.28)*.05;// sin(_Time.y) * .5 + .5;

			//add worldspace animation
			float4 worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
			worldPos.y += sin(_Time.y + worldPos.x ) *.1f;
			v.vertex.xyz = mul(unity_WorldToObject, worldPos);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
			float2 worldUV = IN.worldPos.xz;

			fixed4 c = tex2D (_MainTex, IN.uv_NormalMap) * _Color;
			
			//tri-planar mapping example
			/*
			float3 blend = normalize(max(abs(IN.worldNormal), 0.000001));
			float b = blend.x + blend.y + blend.z;
			blend /= half3(b, b, b);

			float4 xaxis = tex2D(_MainTex, IN.worldPos.yz);
			float4 yaxis = tex2D(_MainTex, IN.worldPos.xz);
			float4 zaxis = tex2D(_MainTex, IN.worldPos.xy);
			float4 tex = xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
			*/
			// blend the results of the 3 planar projections.
			//writing to o.Normal messes up the tri-planar mapping!
			o.Normal = lerp(half3(0, 0, 1), UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap)), _HeightPower * 2);// UnpackNormal(nxaxis * blend.x + nyaxis * blend.y + nzaxis * blend.z);
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex);// c.rgb;//abs(sin(_Time.zyy));

			float3 worldRefl = reflect(-IN.viewDir, o.Normal);

			half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
			half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

			float normalDot = 1 - dot(IN.viewDir, o.Normal);
			o.Emission = abs(cos(_Time.z)) * .25 * normalDot * skyColor;

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;

			float gloss = tex2D(_GlossMap, IN.uv_MainTex).r;
			o.Smoothness = _Glossiness * gloss;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
