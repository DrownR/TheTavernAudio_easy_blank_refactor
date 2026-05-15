Shader "Custom/VolumeFog"
{
     Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MaxDistance("Max distance", float) = 100
        _StepSize("Step size", Range(0.1, 20)) = 1
        _DensityMultiplier("Density multiplier", Range(0, 10)) = 1
        _NoiseOffset("Noise offset", float) = 0
        
        _FogNoise("Fog noise", 3D) = "white" {}
        _NoiseTiling("Noise tiling", float) = 1
        _DensityThreshold("Density threshold", Range(0, 1)) = 0.1
        
        [HDR]_LightContribution("Light contribution", Color) = (1, 1, 1, 1)
        _LightScattering("Light scattering", Range(0, 1)) = 0.2
        _FogOpacity("Fog Opacity", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {

           HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            float4 _Color;

            float _MaxDistance;
            float _StepSize;

            float _DensityMultiplier;
            float _DensityThreshold;

            float _NoiseOffset;
            float _NoiseTiling;

            float4 _LightContribution;

            float _LightScattering;
            float _FogOpacity;

            TEXTURE3D(_FogNoise);

            float henyey_greenstein(float cosTheta, float g)
            {
                float g2 = g * g;

                return
                    (1.0 - g2) /
                    (4.0 * PI * pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5));
            }

            float get_density(float3 worldPos)
            {
                float3 uvw =
                    worldPos *
                    0.01 *
                    _NoiseTiling;

                float4 noise =
                    SAMPLE_TEXTURE3D_LOD(
                        _FogNoise,
                        sampler_TrilinearRepeat,
                        uvw,
                        0
                    );

                float density =
                    dot(noise.rgb, float3(0.3333, 0.3333, 0.3333));

                density =
                    saturate(density - _DensityThreshold) *
                    _DensityMultiplier;

                return density;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // SCENE COLOR

                float4 sceneColor =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_LinearClamp,
                        IN.texcoord
                    );

                // DEPTH

                float depth =
                    SampleSceneDepth(IN.texcoord);

                float3 worldPos =
                    ComputeWorldSpacePosition(
                        IN.texcoord,
                        depth,
                        UNITY_MATRIX_I_VP
                    );

                // VIEW RAY

                float3 cameraPos =
                    _WorldSpaceCameraPos;

                float3 viewVector =
                    worldPos - cameraPos;

                float viewLength =
                    length(viewVector);

                float3 rayDir =
                    normalize(viewVector);

                // RAYMARCH SETUP

                float2 pixelCoords =
                    IN.texcoord *
                    _BlitTexture_TexelSize.zw;

                float distLimit =
                    min(viewLength, _MaxDistance);

                float distTravelled =
                    InterleavedGradientNoise(
                        pixelCoords,
                        (int)(_Time.y / max(HALF_EPS, unity_DeltaTime.x))
                    ) * _NoiseOffset;

                float transmittance = 1.0;

                float3 fogLighting = 0;

                // RAYMARCH

                while(distTravelled < distLimit)
                {
                    float3 rayPos =
                        cameraPos +
                        rayDir * distTravelled;

                    float density =
                        get_density(rayPos);

                    if(density > 0.001)
                    {
                        float4 shadowCoord =
                            TransformWorldToShadowCoord(rayPos);

                        Light mainLight =
                            GetMainLight(shadowCoord);

                        float cosTheta =
                            dot(
                                rayDir,
                                -mainLight.direction
                            );

                        float phase =
                            henyey_greenstein(
                                cosTheta,
                                _LightScattering
                            ) * 10;

                        float3 scattering =
                            mainLight.color.rgb *
                            mainLight.shadowAttenuation *
                            phase;

                        fogLighting +=
                            scattering *
                            density *
                            transmittance *
                            _StepSize *
                            _LightContribution.rgb;

                        transmittance *=
                            exp(-density * _StepSize);

                        if(transmittance < 0.01)
                            break;
                    }

                    distTravelled += _StepSize;
                }

                // FINAL COMPOSITION

               float fogAmount =
                    (1.0 - saturate(transmittance)) *
                    _FogOpacity;

                float3 finalFog =
                    (_Color.rgb * fogAmount) +
                    fogLighting;

                float3 finalColor =
                    lerp(
                        sceneColor.rgb,
                        finalFog,
                        fogAmount
                    );

                return float4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}
