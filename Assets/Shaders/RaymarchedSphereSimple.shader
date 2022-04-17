Shader "Mandi/RaymarchedSphereSimple"
{
    Properties
    {
        _Radius("Radius", Float) = 0.4
        _Center("Center", Vector) = (0,0,0,0)
        _SphereColor("Color", Color) = (0,0,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define STEPS 100
            #define STEP_SIZE 0.0175

            float _Radius;
            float3 _Center;
            fixed4 _SphereColor;

            struct v2f {
                float4 position : SV_POSITION; // Clip space
                float3 worldPos : TEXCOORD1; // World position
            };

            // Vertex function
            v2f vert (appdata_base v)
            {
                 v2f o;
                 o.position = UnityObjectToClipPos(v.vertex);
                 o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                 return o;
            }

            float random(float2 pt, float seed)
            {
                const float a = 1.9898;
                const float b = 1.233;
                const float c = 48.543123;
                return frac(sin(dot(pt, float2(a, b))) * c);
            }

            fixed4 raymarch(float3 position, float3 direction)
            {
                for (int i = 0; i < STEPS; i++)
                {
                    float len = length(position - _Center.xyz);
                    if (len < _Radius) return (_SphereColor/len/0.85 * random(position,77));
                    position += direction * STEP_SIZE;
                }
                return fixed4(1, 1, 1, -1);
            }
            // Fragment function
            fixed4 frag(v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.worldPos - _WorldSpaceCameraPos);
                fixed4 col = raymarch(i.worldPos.xyz, viewDir);
                clip(col);
                return col;
            }
            ENDCG
        }
    }
    FallBack off
}
