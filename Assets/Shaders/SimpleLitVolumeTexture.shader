//WIP
Shader "Mandi/SimpleLitVolumeTexture"
{
    Properties
    {
        _MainTex("Texture", 3D) = "white" {}
        _Alpha("Alpha", Float) = 0.02
        _StepSize("Step Size", Float) = 0.01
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" "Queue" = "Transparent"}
            Blend One OneMinusSrcAlpha
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"

                //Max no of raymarched samples
                #define MAX_STEP_COUNT 512

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
                    float3 vectorToSurfaceFromLight: TEXCOORD3;
                };

                sampler3D _MainTex;
                float4 _MainTex_ST;
                float _Alpha;
                float _StepSize;


                // Vertex function
                v2f vert(appdata_base v)
                {
                     v2f o;

                     //Vertex in object space - this will be the starting point of raymarching
                     o.objectVertex = v.vertex;

                     //Calculate vector from camera to vertex in world space
                     float3 worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                     o.vectorToSurface = worldVertex - _WorldSpaceCameraPos;

                     //Accounting for lighting
                     o.vectorToSurfaceFromLight = worldVertex - _WorldSpaceLightPos0.xyz;

                     o.vertex = UnityObjectToClipPos(v.vertex);

                     return o;
                }

                float4 BlendUnder(float4 color, float4 newColor)
                {
                    color.rgb += newColor.rgb * newColor.a;
                    color.a *= newColor.a;
                    return color;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    //Start raymarching at the front surface of the object
                    float3 rayOrigin = i.objectVertex;

                    //Use vector from camera to object surface to get ray dir
                    float3 rayDirection = mul(unity_WorldToObject, float4(normalize(i.vectorToSurface), 1));

                    //Accounting for lighting
                    float3 rayDirectionFromLight = mul(unity_WorldToObject, float4(normalize(i.vectorToSurfaceFromLight), 1));

                    float4 color = float4(0, 0, 0, 0);
                    float3 samplePosition = rayOrigin;
                    float3 samplePositionForLight = rayOrigin;

                    float4 finalColor = float4(0, 0, 0, 0);

                    //Ray march through object space
                    for (int i = 0; i < MAX_STEP_COUNT; i++)
                    {
                        //medium
                        //Accumulate color only withn unity cube bounds
                        if (max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5f + EPSILON)
                        {
                            float4 sampledColor = tex3D(_MainTex, samplePosition + float3(0.5f, 0.5f, 0.5f));
                            sampledColor.a = (sampledColor.a) * _Alpha;
                            color = BlendUnder(color, sampledColor);
                            samplePosition += rayDirection * _StepSize;

                            //finalColor = mul((_LightColor0) * (MAX_STEP_COUNT / (MAX_STEP_COUNT - 0)) * 1, color);
                            //finalColor = mul(color, float4(1, 0, 0, 1))*0.5;

                            //we are only interested in scaling the values, so no mul but simple multiplication
                            //finalColor = color * float4(1, 0, 1, 1);
                            finalColor = color * (_LightColor0);

                            //float maxStep = MAX_STEP_COUNT;
                            //float iF = i;
                            //float coeff = (maxStep - iF) / (maxStep)*10;
                            //finalColor = color * (_LightColor0) *coeff;

                            //finalColor = (maxStep - iF) / (maxStep)*color  + (iF) / (maxStep)*color *(_LightColor0) * ((MAX_STEP_COUNT - i) / (MAX_STEP_COUNT)) * 10;
                            //finalColor = ((MAX_STEP_COUNT-i)/ MAX_STEP_COUNT)*color + (i/MAX_STEP_COUNT)*(color * (_LightColor0) * (MAX_STEP_COUNT / (MAX_STEP_COUNT - 0)));
                        }

                        //lighting
                        /*if (max(abs(samplePositionForLight.x), max(abs(samplePositionForLight.y), abs(samplePositionForLight.z))) < 0.5f + EPSILON)
                        {*/
                            //float iCoeff = ( i / 20);
                            //float lightPower = float((MAX_STEP_COUNT - iCoeff) / MAX_STEP_COUNT);
                            //color.rgb = color.rgb * (_LightColor0.rgb) * lightPower;
                            //samplePositionForLight += rayDirectionFromLight * _StepSize;
                        //}

                    }

                    return finalColor;
                }
                ENDCG
            }
        }
        FallBack off
}
