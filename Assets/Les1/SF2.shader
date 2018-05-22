Shader "Custom/SF2" {
	Properties{
		//FORMAT: variableName("description", type) = defaultValue
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "blue" {}
		_NormalStrength("Normal Strength", Range(0,1)) = 0.5
		_Displacement("Displacement Map", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types, adds a vertex function named "vert"
		//		tells the system to add shadows for those changed vertices, and asks to tessellate using the "tessDistance" function
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow tessellate:tessDistance

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		//includes tessellation code pre-written by Unity
		#include "Tessellation.cginc"

		//These map to the input properties, make sure the names are exactly the same!
		sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _Displacement;

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		half _NormalStrength;

		//Add variables to this struct based on the Unity manual page: Surface Shader input structure (https://docs.unity3d.com/Manual/SL-SurfaceShaders.html)
		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMap;
			float3 viewDir;
			float4 screenPos;
			float3 worldPos;
		};

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		//This function was taken from the examples, but we needed to change appdata to appdata_full (Unity 2018 didn't recognize it)
			//it calculates how much tessellation (1 = none, higher = more subdivisions) to perform based on distance to Camera
		float4 tessDistance (appdata_full v0, appdata_full v1, appdata_full v2) {
			float minDist = 5.0;
			float maxDist = 15.0;
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, 16);
		}

		//this is a fixed tessellation function that always subdivides 32x (a high amount normally only used for very close, high-detail objects)
		float4 tess() {
			return 32;
		}

		//vertex function, note that it's a "void" function, but contains an "inout" parameter
		void vert (inout appdata_full v) {
			
			//Als we in "world space" willen animeren moeten we vertalen naar worldspace, iets doen, en dan weer terug vertalen
			//Daarvoor gebruiken we default "matrix" variabelen van Unity:
				//unity_ObjectToWorld
				//unity_WorldToObject
			float4 worldPos = mul(unity_ObjectToWorld, v.vertex);	//volgorde hiervan is belangrijk: eerst matrix, dan positie!
			//DOE IETS (simpele golf animatie over de x-as van de wereld)
			worldPos.y += sin(_Time.z + worldPos.x * 10) * 0.1;
			v.vertex = mul(unity_WorldToObject, worldPos);

			//Object-space displacement map op basis van een grijs-waarde heightmap (vandaar dat we alleen het rood kanaal gebruiken)
			half height = tex2Dlod(_Displacement, float4(v.texcoord.xy, 0, 0)).r;
			v.vertex.xyz += v.normal * height * _NormalStrength;// abs(sin(_Time.z));
			//v.vertex.y += sin( _Time.z + v.vertex.x * 10 ) * 0.1;
		}


		//surface function
		void surf (Input IN, inout SurfaceOutputStandard o) {
			//reads a texture sampler with a UV coordinate
			//fixed is a "fixed floating point" number, good for storing colors
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);// +half2(0, _Time.x));// *_Color;
			
			//screenSpace UV (divide by W to remove distance/scale information)
			//half2 screenUV = IN.screenPos.xy / IN.screenPos.w;

			//worldSpace UV, XZ is the "floor plane"
			//half2 worldUV = IN.worldPos.xz;;

			//fixed4 c = tex2D(_MainTex, screenUV);
			//fixed4 c = tex2D(_MainTex, worldUV);

			o.Albedo = c.rgb;// sin(_Time.rbr);// half3(abs(sin(_Time.y)), 0, 0);
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness * c.a;
			o.Alpha = c.a;

			//this function would manually calculate a normal direction based on an RGB normal texture
			//( normal.rgb - .5 ) * 2
			half3 blue = half3(0, 0, 1);
			//here we rely on UnpackNormal to do the above calculation for us, and lerp between blue (no normal changes) and the unpacked normal based on a slider
			half3 unpackedNormal = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
			o.Normal = lerp(blue, unpackedNormal, _NormalStrength);

			//often used fresnel calculation to create "rim lights"
			half fresnel = 1 - dot(IN.viewDir, o.Normal);
			o.Emission = pow(fresnel, 4);// *abs(sin(_Time.w));
		}
		ENDCG
	}
	FallBack "Diffuse"
}
