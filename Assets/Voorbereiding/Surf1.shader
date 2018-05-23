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
		_A("Amplitude", Range(0,10)) = 1
	}
	SubShader {
		Tags { "RenderType" = "Opaque" "Queue"="Transparent-1" }
		LOD 200

		GrabPass {}

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow tessellate:tessDistance

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 4.6
		#include "Tessellation.cginc"

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

		sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _HeightMap;
		sampler2D _GlossMap;

		uniform sampler2D _GrabTexture;

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
		float _A;

		float4 _HeightMap_ST;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		float4 tessDistance(appdata_full v0, appdata_full v1, appdata_full v2)
		{
			float minDist = 1;
			float maxDist = 15.0;
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
		}

		void vert(inout appdata_full v) {
			//add worldspace animation
			float4 v0 = mul(unity_ObjectToWorld, v.vertex);

			float3 v1 = v0.xyz + float3(0.0005, 0, 0);
			float3 v2 = v0.xyz + float3(0, 0, 0.0005);

			float A = _A;	// amplitude
			float L = 1;	// wavelength
			float w = 2 * 3.1416 / L;
			float Q = 0.78;
			float2 D = float2(0, 1);

			float3 P0 = v0.xyz + half3(0, sin(v0.x) * 10, 0);
			float3 P1 = v1.xyz + half3(0, sin(v1.x) * 10, 0);
			float3 P2 = v2.xyz + half3(0, sin(v2.x) * 10, 0);

			float dotD0 = dot(P0.xz, D);
			float dotD1 = dot(P1.xz, D);
			float dotD2 = dot(P2.xz, D);

			float C0 = cos(w*dotD0 + _Time.y + sin(v0.x + cos(v0.z))*2);
			float S0 = sin(w*dotD0 + _Time.y + sin(v0.x + cos(v0.z))*2);

			float C1 = cos(w*dotD1 + _Time.y + sin(v1.x + cos(v1.z)) * 2);
			float S1 = sin(w*dotD1 + _Time.y + sin(v1.x + cos(v1.z)) * 2);

			float C2 = cos(w*dotD2 + _Time.y + sin(v2.x + cos(v2.z)) * 2);
			float S2 = sin(w*dotD2 + _Time.y + sin(v2.x + cos(v2.z)) * 2);

			float3 PA = float3(P0.x + Q*A*C0*D.x, A * S0, P0.z + Q*A*C0*D.y);
			float3 PB = float3(P1.x + Q*A*C1*D.x, A * S1, P1.z + Q*A*C1*D.y);
			float3 PC = float3(P2.x + Q*A*C2*D.x, A * S2, P2.z + Q*A*C2*D.y);

			v0.xyz = PA;

			float3 vna = cross(normalize(PC.xyz - PA.xyz), normalize(PB.xyz - PA.xyz));
			float3 vn = mul((float3x3)unity_ObjectToWorld, vna);

			v.normal = normalize(vn);
			v.vertex = mul(unity_WorldToObject, v0);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
			float2 worldUV = IN.worldPos.xz;

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex)// *_Color;
			
			float3 n1 = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap + half2(_Time.x * .1, _Time.x * .1)));
			float3 n2 = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap*2 - half2(_Time.x * .1, _Time.x * .1)));
			float3 n3 = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap*1.2 + half2(0, _Time.x * .1)));
			float3 n = n1 + n2 + n3 * .33333;

			o.Normal = lerp(o.Normal, n, _HeightPower * 2);
			
			float alpha = ( 1 - pow( dot(o.Normal, IN.viewDir), 2 ) ) + .1;
			fixed3 grabColor = tex2D(_GrabTexture, screenUV).rgb;

			float3 color = lerp(_Color, c, clamp(IN.worldPos.y * 2 + 0.05,0,1));
			
			o.Albedo = lerp( grabColor, color, alpha);

			float3 worldRefl = reflect(-IN.viewDir, o.Normal);

			half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
			half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;

			float gloss = tex2D(_GlossMap, IN.uv_MainTex).r;
			o.Smoothness = _Glossiness;
			o.Alpha = 1;
		}
		ENDCG


	}
	FallBack "Diffuse"
}
