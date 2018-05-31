Shader "Unlit/Unlit_pre"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Lightramp ("Light Ramp", 2D) = "white" {}
        _Shininess ("Shininess", Range(0,1)) = 0.5
        _ClipDistance ("Clip Distance", Range(0,100)) = 1
	}
	SubShader
	{
		Tags {"LightMode"="ForwardBase" "Queue"="Transparent-1"}
		LOD 100


        GrabPass {}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

            #pragma target 4.6
			
			#include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
                float3 color : COLOR;
                float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				//UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldReflect : TEXCOORD3;
                float4 screenPos : TEXCOORD4;
                fixed4 diff : COLOR0;
			};

			sampler2D _MainTex;
            sampler2D _Lightramp;
			float4 _MainTex_ST;
            half _Shininess;

            uniform sampler2D _GrabTexture;

            uniform float3 _ClipPosition;
            float _ClipDistance;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                //per vertex
                float3 viewNormal = normalize(UnityWorldSpaceViewDir(o.worldNormal));
                o.worldReflect = reflect(-viewNormal, o.worldNormal);
                //strange bug when reading from cubemap with this position...
                o.worldReflect.x = -o.worldReflect.x;

                half nl = ( dot(o.worldNormal, _WorldSpaceLightPos0.xyz) + 1 ) * .5;//LAMBERT: max(0, dot(o.worldNormal, _WorldSpaceLightPos0.xyz));
                // factor in the light color
                o.diff = nl;// * _LightColor0;

                o.screenPos = ComputeGrabScreenPos(o.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                if ( distance(i.worldPos.xyz, _ClipPosition) > _ClipDistance ) discard;

                half2 toonUV = half2(i.diff.r,0);
                fixed3 lightColor = tex2D(_Lightramp, toonUV).rgb;

                half2 screenUV = i.screenPos.xy / i.screenPos.w;
                fixed4 grabColor = tex2D(_GrabTexture, screenUV);

                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldNormal));
                float3 lightDir = _WorldSpaceLightPos0.xyz - i.worldPos;
                float lDist = length(lightDir);
                lightDir = normalize(lightDir);

                float3 H = normalize( lightDir + viewDir );
                float spec = pow( saturate( dot( H, i.worldNormal ) ), 48);

                // sample the default reflection cubemap, using the reflection vector
                half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.worldReflect);
                // decode cubemap data into actual color
                half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR);

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= lightColor.rgb;

                col.rgb += skyColor.rgb * _Shininess;

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
