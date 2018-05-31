Shader "Render Depth" {
	SubShader{
		Tags{ "RenderType" = "Opaque" }
		Pass
		{
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"

				struct v2f {
					float4 pos : SV_POSITION;
					float2 depth : TEXCOORD0;
				};

				v2f vert(appdata_base v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					UNITY_TRANSFER_DEPTH(o.depth);
					return o;
				}

				half4 frag(v2f i) : SV_Target{
					float d = 1 - ( distance(_WorldSpaceCameraPos.xyz, i.pos.xyz / i.pos.w) / _ProjectionParams.z );
					return float4(d, d, d, 1);
				}
			ENDCG
		}
	}
}