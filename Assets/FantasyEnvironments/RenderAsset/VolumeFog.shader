Shader "Custom/VolumeFog"
{
     Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MaxDistance("Max distance", float) = 100
        _StepSize("Step size", Range(0.1, 20)) = 1
        _MaxSteps("Max Steps", Range(1, 256)) = 64
        _DensityMultiplier("Density multiplier", Range(0, 10)) = 1
        _NoiseOffset("Noise offset", float) = 0
        
        _FogNoise("Fog noise", 3D) = "white" {}
        _NoiseTiling("Noise tiling", float) = 1
        _DensityThreshold("Density threshold", Range(0, 1)) = 0.1
        
        [HDR]_LightContribution("Light contribution", Color) = (1, 1, 1, 1)
        _LightScattering("Light scattering", Range(0, 1)) = 0.2
        _FogOpacity("Fog Opacity", Range(0, 1)) = 1

         [Toggle]_UseAdditionalLights("Use Point / Spot Lights", Float) = 0
        _MaxAdditionalLights("Max Additional Lights", Range(0, 16)) = 4
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

              #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            float4 _Color;

            float _MaxDistance;
            float _StepSize;
            int _MaxSteps;

            float _DensityMultiplier;
            float _DensityThreshold;

            float _NoiseOffset;
            float _NoiseTiling;

            float4 _LightContribution;

            float _LightScattering;
            float _FogOpacity;

            float _UseAdditionalLights;
            int _MaxAdditionalLights;

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
            
            float3 CalculateMainLightFog(
                float3 rayPos,
                float3 rayDir,
                float density,
                float transmittance
            )
            {
                float4 shadowCoord =
                    TransformWorldToShadowCoord(rayPos);

                Light mainLight =
                    GetMainLight(shadowCoord);

                float cosTheta =
                    dot(rayDir, mainLight.direction);

                float phase =
                    henyey_greenstein(
                        cosTheta,
                        _LightScattering
                    ) * 10.0;

                float3 scattering =
                    mainLight.color.rgb *
                    mainLight.shadowAttenuation *
                    phase;

                return
                    scattering *
                    density *
                    transmittance *
                    _StepSize *
                    _LightContribution.rgb;
            }

            float3 CalculateAdditionalLightsFog(
                float3 rayPos,
                float3 rayDir,
                float density,
                float transmittance
            )
            {
                float3 result = 0;

                #ifdef _ADDITIONAL_LIGHTS

                if (_UseAdditionalLights > 0.5)
                {
                    uint lightCount =
                        GetAdditionalLightsCount();

                    lightCount =
                        min(lightCount, (uint)_MaxAdditionalLights);

                    for (uint i = 0; i < lightCount; i++)
                    {
                        Light light =
                            GetAdditionalLight(i, rayPos);

                        float cosTheta =
                            dot(rayDir, light.direction);

                        float phase =
                            henyey_greenstein(
                                cosTheta,
                                _LightScattering
                            ) * 10.0;

                        float attenuation =
                            light.distanceAttenuation *
                            light.shadowAttenuation;

                        float3 scattering =
                            light.color.rgb *
                            attenuation *
                            phase;

                        result +=
                            scattering *
                            density *
                            transmittance *
                            _StepSize *
                            _LightContribution.rgb;
                    }
                }

                #endif

                return result;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 sceneColor =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_LinearClamp,
                        IN.texcoord
                    );

                float depth =
                    SampleSceneDepth(IN.texcoord);

                float3 worldPos =
                    ComputeWorldSpacePosition(
                        IN.texcoord,
                        depth,
                        UNITY_MATRIX_I_VP
                    );

                float3 cameraPos =
                    _WorldSpaceCameraPos;

                float3 viewVector =
                    worldPos - cameraPos;

                float viewLength =
                    length(viewVector);

                float3 rayDir =
                    normalize(viewVector);

                float distLimit =
                    min(viewLength, _MaxDistance);

                float2 pixelCoords =
                    IN.texcoord *
                    _BlitTexture_TexelSize.zw;

                float distTravelled =
                    InterleavedGradientNoise(
                        pixelCoords,
                        (int)(_Time.y / max(HALF_EPS, unity_DeltaTime.x))
                    ) * _NoiseOffset;

                float transmittance = 1.0;

                float3 fogLighting = 0;

                for (int stepIndex = 0; stepIndex < _MaxSteps; stepIndex++)
                {
                    if (distTravelled >= distLimit)
                        break;

                    float3 rayPos =
                        cameraPos +
                        rayDir * distTravelled;

                    float density =
                        get_density(rayPos);

                    if (density > 0.001)
                    {
                        fogLighting +=
                            CalculateMainLightFog(
                                rayPos,
                                rayDir,
                                density,
                                transmittance
                            );

                        fogLighting +=
                            CalculateAdditionalLightsFog(
                                rayPos,
                                rayDir,
                                density,
                                transmittance
                            );

                        transmittance *=
                            exp(-density * _StepSize);

                        if (transmittance < 0.01)
                            break;
                    }

                    distTravelled += _StepSize;
                }

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
