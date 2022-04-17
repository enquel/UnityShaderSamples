Shader "Mandi/SimpleVolumeTextureShader"
{
    Properties
    {
        _MainTex("Texture", 3D) = "white" {}
        _Alpha("Alpha", Float) = 0.02
        _StepSize("Step Size", Float) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent"}
        Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //Max no of raymarched samples
            #define MAX_STEP_COUNT 128

            //Allowed floating point inaccuracy
            #define EPSILON 0.00001f

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION; //probably this is itfloat4 position : SV_POSITION; // Clip space
                float3 objectVertex : TEXCOORD1;
                float3 vectorToSurface: TEXCOORD2;
            };

            sampler3D _MainTex;
            float4 _MainTex_ST;
            float _Alpha;
            float _StepSize;


            // Vertex function
            v2f vert (appdata_base v)
            {
                 v2f o;

                 //Vertex in object space - this will be the starting point of raymarching
                 o.objectVertex = v.vertex;

                 //Calculate vector from camera to vertex in world space
                 float3 worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                 o.vectorToSurface = worldVertex - _WorldSpaceCameraPos;

                 o.vertex = UnityObjectToClipPos(v.vertex);
                 return o;
            }

            float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += (1.0 - color.a) * newColor.a;
                return color;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //Start raymarching at the front surface of the object
                float3 rayOrigin = i.objectVertex;

                //Use vector from camera to object surface to get ray dir
                float3 rayDirection = mul(unity_WorldToObject, float4(normalize(i.vectorToSurface), 1));

                float4 color = float4(0, 0, 0, 0);
                float3 samplePosition = rayOrigin;

                //Ray march through object space
                for (int i = 0; i < MAX_STEP_COUNT; i++)
                {
                    //Accumulate color only withn unity cube bounds
                    if (max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5f + EPSILON)
                    {
                        float4 sampledColor = tex3D(_MainTex, samplePosition + float3(0.5f, 0.5f, 0.5f));
                        sampledColor.a *= _Alpha;
                        color = BlendUnder(color, sampledColor);
                        samplePosition += rayDirection * _StepSize;
                    }
                }

                return color;
            }
            ENDCG
        }
    }
    FallBack off
}
