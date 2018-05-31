Shader "Unlit/unlit_pre2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_UpTex("Texture", 2D) = "black" {}
		_Ambient("Ambient Color", Color) = (0,0,0,0)
		_NormalMap("Normal Map", 2D) = "blue" {}
		//_Alpha("Opacity", Range(0,1)) = 1
	}
	SubShader
	{
		Tags { 
			"RenderType"="Transparent" 
			"Queue"="Transparent-1"
		}
		LOD 100

		//ZTest Always
		//Blend SrcAlpha OneMinusSrcAlpha

		//Cull front

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				//additional values we can request from the vertices (careful: not all meshes contain all types of data)
				//float2 uv2 : TEXCOORD1;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;

				//custom values we can calculate in the vertex shader
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float3 worldReflect : TEXCOORD4;
				float3 objectNormal : TEXCOORD5;
			};

			sampler2D _MainTex;
			sampler2D _UpTex;
			float4 _MainTex_ST;

			sampler2D _NormalMap;
			float4 _NormalMap_ST;	//scale & transform values

			fixed4 _Ambient;
			uniform half _Alpha;
			
			uniform float3 _ClipPosition;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				//calculate our custom output values
				//worldPos
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//worldNormal
				o.worldNormal = normalize( mul(unity_ObjectToWorld, v.normal ) );
				o.objectNormal = v.normal;

				//screenPos
				o.screenPos = ComputeScreenPos(o.vertex);

				//worldReflect
				//here we need the view direction!
				float3 viewDir = normalize(o.worldPos - _WorldSpaceCameraPos);
				o.worldReflect = reflect(viewDir, o.worldNormal);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				if (distance(_ClipPosition, i.worldPos) > 2) discard;

				// sample the default reflection cubemap, using the reflection vector
				half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.worldReflect);
				// decode cubemap data into actual color
				half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

				float3 norm = i.objectNormal;
				fixed3 nMap = UnpackNormal(tex2D(_NormalMap, i.uv));
				norm.rg += nMap.rg * .5;
				norm = mul(unity_ObjectToWorld, norm);

				float worldYLighting = (dot(norm, half3(0, 1, 0)) + 1) * .5;
				
				half tScale = 4;
				fixed4 r = tex2D(_MainTex, i.worldPos.yz * tScale);
				fixed4 g = tex2D(_MainTex, i.worldPos.xz * tScale);
				fixed4 b = tex2D(_MainTex, i.worldPos.xy * tScale);

				float3 blend = abs(i.worldNormal);
				blend *= blend;

				fixed4 c = blend.r * r + blend.g * g + blend.b * b;

				fixed4 upTex = tex2D(_UpTex, i.worldPos.xz * tScale);
				float upLerp = max(0, dot(norm, half3(0, 1, 0)));

				// sample the texture
				fixed4 col = lerp(c, upTex, upLerp);// tex2D(_MainTex, i.worldPos.xz * tScale);

				col.rgb *= clamp( worldYLighting + _Ambient, 0, 1 );

				//could add this based on an input property
				//col.rgb += skyColor * .15;

				return half4(col.rgb, _Alpha);
			}
			ENDCG
		}
		
		/*
		Cull back
		Pass
		{
			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
			// make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

			struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			//additional values we can request from the vertices (careful: not all meshes contain all types of data)
			//float2 uv2 : TEXCOORD1;
			float3 normal : NORMAL;
			float4 color : COLOR;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;

			//custom values we can calculate in the vertex shader
			float3 worldPos : TEXCOORD1;
			float3 worldNormal : TEXCOORD2;
			float4 screenPos : TEXCOORD3;
			float3 worldReflect : TEXCOORD4;
			float3 objectNormal : TEXCOORD5;
		};

		sampler2D _MainTex;
		sampler2D _UpTex;
		float4 _MainTex_ST;

		sampler2D _NormalMap;
		float4 _NormalMap_ST;	//scale & transform values

		fixed4 _Ambient;
		half _Alpha;

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);

			//calculate our custom output values
			//worldPos
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			//worldNormal
			o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
			o.objectNormal = v.normal;

			//screenPos
			o.screenPos = ComputeScreenPos(o.vertex);

			//worldReflect
			//here we need the view direction!
			float3 viewDir = normalize(o.worldPos - _WorldSpaceCameraPos);
			o.worldReflect = reflect(viewDir, o.worldNormal);

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			// sample the default reflection cubemap, using the reflection vector
			half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.worldReflect);
			// decode cubemap data into actual color
			half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

			float3 norm = i.objectNormal;
			fixed3 nMap = UnpackNormal(tex2D(_NormalMap, i.uv));
			norm.rg += nMap.rg * .5;
			norm = mul(unity_ObjectToWorld, norm);

			float worldYLighting = (dot(norm, half3(0, 1, 0)) + 1) * .5;

			half tScale = 4;
			fixed4 r = tex2D(_MainTex, i.worldPos.yz * tScale);
			fixed4 g = tex2D(_MainTex, i.worldPos.xz * tScale);
			fixed4 b = tex2D(_MainTex, i.worldPos.xy * tScale);

			float3 blend = abs(i.worldNormal);
			blend *= blend;

			fixed4 c = blend.r * r + blend.g * g + blend.b * b;

			fixed4 upTex = tex2D(_UpTex, i.worldPos.xz * tScale);
			float upLerp = max(0, dot(norm, half3(0, 1, 0)));

			// sample the texture
			fixed4 col = lerp(c, upTex, upLerp);// tex2D(_MainTex, i.worldPos.xz * tScale);

			col.rgb *= clamp(worldYLighting + _Ambient, 0, 1);

			//could add this based on an input property
			//col.rgb += skyColor * .15;

			return half4(col.rgb, _Alpha);
		}
			ENDCG
		}
		*/
	}
}
