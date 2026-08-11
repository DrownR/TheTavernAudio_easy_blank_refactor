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
        
        _LightContribution("Light contribution", Range(0, 10)) = 1
        _LightScattering("Light scattering", Range(0, 1)) = 0.2
        _FogOpacity("Fog Opacity", Range(0, 1)) = 1

        [Toggle]_UseAdditionalLights("Use Point / Spot Lights", Float) = 0
        _MaxAdditionalLights("Max Additional Lights", Range(0, 16)) = 4

        _MainLightFogIntensity("Main Light Fog Intensity", Range(0, 10)) = 1

        _AdditionalLightsFogIntensity("Additional Lights Fog Intensity", Range(0, 10)) = 1

        _FogMoveSpeed("Fog Move Speed", Range(0, 5)) = 0.25
        _FogMoveDirection("Fog Move Direction", Vector) = (1, 0.2, 0.3, 0)

        _FogTurbulence("Fog Turbulence", Range(0, 2)) = 0.5
        _FogSecondarySpeed("Fog Secondary Speed", Range(0, 5)) = 0.15
        _FogSecondaryScale("Fog Secondary Scale", Range(0.1, 5)) = 2.0

        [Header(Height Fog)]
        _HeightFogColor("Height Fog Color", Color) = (0.6, 0.65, 0.7, 1)
        _HeightFogDensity("Height Fog Density", Range(0, 2)) = 0.15
        _HeightFogStart("Height Fog Start Distance", Float) = 0
        _HeightFogMaxDistance("Height Fog Max Distance", Float) = 100

        _FogHeight("Fog Height", Float) = 5
        _HeightFogIntensity("Height Fog Intensity", Range(0, 1)) = 1

        _HeightFogNoiseTiling("Height Fog Noise Tiling", Float) = 1
        _HeightFogNoiseStrength("Height Fog Noise Strength", Range(0, 5)) = 0.5
        _HeightFogNoiseSpeed("Height Fog Noise Speed", Range(0, 5)) = 0.2
        _HeightFogNoiseDirection("Height Fog Noise Direction", Vector) = (1, 0, 0.3, 0)

        _HeightFogBaseY("Height Fog Base Y", Float) = 0
        _HeightFogVerticalFalloff("Height Fog Vertical Falloff", Range(0.01, 50)) = 6
        _HeightFogCurvePower("Height Fog Curve Power", Range(0.2, 8)) = 2

        _HeightFalloffNoiseStrength("Height Falloff Noise Strength", Range(0, 2)) = 0.5
        _HeightFalloffNoiseScale("Height Falloff Noise Scale", Range(0, 3)) = 0.7

        _HeightFogDistanceFalloff("Height Fog Distance Falloff", Range(0.01, 10)) = 2
        _HeightFogDistancePower("Height Fog Distance Power", Range(0.2, 8)) = 1

        [Header(Sun Direction Fog Mask)]
        _UseSunDirectionFogMask("Use Sun Direction Fog Mask", Float) = 1
        _SunFogDirectionPower("Sun Fog Direction Power", Range(1, 32)) = 8
        _SunFogDirectionThreshold("Sun Fog Direction Threshold", Range(0, 1)) = 0.2
        _SunFogDirectionIntensity("Sun Fog Direction Intensity", Range(0, 5)) = 1

        _HeightEdgeNoiseScale("Height Edge Noise Scale", Range(0, 3)) = 1
        _HeightEdgeNoiseStrength("Height Edge Noise Strength", Float) = 2
        _HeightEdgeNoiseSpeed("Height Edge Noise Speed", Range(0, 5)) = 0.15
        _HeightEdgeSoftness("Height Edge Softness", Range(0, 1400)) = 2
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

            float _LightContribution;

            float _LightScattering;
            float _FogOpacity;

            float _UseAdditionalLights;
            int _MaxAdditionalLights;

            float _MainLightFogIntensity;

            float _AdditionalLightsFogIntensity;

            float _FogMoveSpeed;
            float4 _FogMoveDirection;

            float _FogTurbulence;
            float _FogSecondarySpeed;
            float _FogSecondaryScale;

            float4 _HeightFogColor;
            float _HeightFogDensity;
            float _HeightFogStart;
            float _HeightFogMaxDistance;

            float _FogHeight;
            float _HeightFogIntensity;

            float _HeightFogNoiseTiling;
            float _HeightFogNoiseStrength;
            float _HeightFogNoiseSpeed;
            float4 _HeightFogNoiseDirection;

            float _HeightFogBaseY;
            float _HeightFogVerticalFalloff;
            float _HeightFogCurvePower;

            float _HeightFalloffNoiseStrength;
            float _HeightFalloffNoiseScale;

            float _HeightFogDistanceFalloff;
            float _HeightFogDistancePower;

            float _UseSunDirectionFogMask;
            float _SunFogDirectionPower;
            float _SunFogDirectionThreshold;
            float _SunFogDirectionIntensity;

            float _HeightEdgeNoiseScale;
            float _HeightEdgeNoiseStrength;
            float _HeightEdgeNoiseSpeed;
            float _HeightEdgeSoftness;

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
               float time = _Time.y;

               float3 baseUVW = worldPos * 0.01 * _NoiseTiling;

               float3 moveDir = normalize(_FogMoveDirection.xyz + 0.0001);

               float3 uvw1 = baseUVW + moveDir * time * _FogMoveSpeed;

               float3 uvw2 =
                    baseUVW * _FogSecondaryScale +
                    float3(-moveDir.z, moveDir.x, moveDir.y) *
                    time *
                    _FogSecondarySpeed;

               float3 uvw3 =
                    baseUVW * 0.5 +
                    float3(moveDir.y, -moveDir.z, moveDir.x) *
                    time *
                    (_FogMoveSpeed * 0.35);

               float noise1 = dot(
                    SAMPLE_TEXTURE3D_LOD(_FogNoise, sampler_TrilinearRepeat, uvw1, 0).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

               float noise2 = dot(
                    SAMPLE_TEXTURE3D_LOD(_FogNoise, sampler_TrilinearRepeat, uvw2, 0).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

               float noise3 = dot(
                    SAMPLE_TEXTURE3D_LOD(_FogNoise, sampler_TrilinearRepeat, uvw3, 0).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

               float density =
                    noise1 * 0.6 +
                    noise2 * 0.3 +
                    noise3 * 0.1;

               density += (noise2 - 0.5) * _FogTurbulence * 0.25;

               density = saturate(density - _DensityThreshold);
               density *= _DensityMultiplier;

               return density;
           }

            float CalculateSunDirectionMask(float3 rayDir, float3 lightDirection)
            {
                if (_UseSunDirectionFogMask < 0.5)
                    return 1.0;

                // В URP mainLight.direction обычно направление, КУДА светит солнце.
                // Нам нужно направление К солнцу, поэтому минус.
                float3 directionToSun = normalize(lightDirection);

                float sunDot = saturate(dot(rayDir, directionToSun));

                float mask = smoothstep(
                    _SunFogDirectionThreshold,
                    1.0,
                    sunDot
                );

                mask = pow(mask, _SunFogDirectionPower);

                return mask * _SunFogDirectionIntensity;
            }

            
           float CalculateHeightFog(float3 worldPos, float distanceFromCamera)
            {
                float distance01 = saturate(
                    (distanceFromCamera - _HeightFogStart) /
                    max(0.001, _HeightFogMaxDistance - _HeightFogStart)
                );

                // Экспоненциальный рост по длине
                float distanceFactor =
                    1.0 - exp(-distance01 * _HeightFogDistanceFalloff);

                // Дополнительная художественная кривая
                distanceFactor = pow(saturate(distanceFactor), _HeightFogDistancePower);

               float3 noiseDir = normalize(_HeightFogNoiseDirection.xyz + 0.0001);

               float3 edgeUVW =
                    worldPos * 0.01 * _HeightEdgeNoiseScale +
                    noiseDir * _Time.y * _HeightEdgeNoiseSpeed;

                float edgeNoise = dot(
                    SAMPLE_TEXTURE3D_LOD(
                        _FogNoise,
                        sampler_TrilinearRepeat,
                        edgeUVW,
                        0
                    ).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

                edgeNoise = edgeNoise * 2.0 - 1.0;

                float variedFogHeight =
                    _FogHeight + edgeNoise * _HeightEdgeNoiseStrength;

                float3 falloffUVW =
                    worldPos * 0.01 * _HeightFalloffNoiseScale +
                    float3(-noiseDir.z, noiseDir.x, noiseDir.y) *
                    _Time.y *
                    _HeightFogNoiseSpeed *
                    0.35;

                float falloffNoise = dot(
                    SAMPLE_TEXTURE3D_LOD(
                        _FogNoise,
                        sampler_TrilinearRepeat,
                        falloffUVW,
                        0
                    ).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

                falloffNoise = falloffNoise * 2.0 - 1.0;

                float variedFalloff =
                    _HeightFogVerticalFalloff *
                    (1.0 + falloffNoise * _HeightFalloffNoiseStrength);

                variedFalloff = max(0.001, variedFalloff);

                float normalizedHeight =
                    saturate(
                        (variedFogHeight - worldPos.y) /
                        max(0.001, variedFalloff)
                    );

                    // Мягкий переход, не линейная стенка
                normalizedHeight = smoothstep(0.0, 1.0, normalizedHeight);


                // Экспоненциальное усиление ближе к земле
                float heightDepth =
                    max(0.0, variedFogHeight - worldPos.y);

                float exponentialHeight =
                    1.0 - exp(-heightDepth / variedFalloff);


                // Управление кривой
                float heightFactor =
                    pow(saturate(exponentialHeight * normalizedHeight), _HeightFogCurvePower);
                    
                float height01 = saturate(
                    (variedFogHeight - worldPos.y) /
                    max(0.001, _HeightEdgeSoftness)
                );

                heightFactor = smoothstep(0.0, 1.0, height01);
                
                float3 noiseUVW =
                    worldPos * 0.01 * _HeightFogNoiseTiling +
                    noiseDir * _Time.y * _HeightFogNoiseSpeed;

                float noise = dot(
                    SAMPLE_TEXTURE3D_LOD(
                        _FogNoise,
                        sampler_TrilinearRepeat,
                        noiseUVW,
                        0
                    ).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

                float3 noiseUVW2 =
                    worldPos * 0.01 * _HeightFogNoiseTiling * 2.3 +
                    float3(-noiseDir.z, noiseDir.y, noiseDir.x) *
                    _Time.y *
                    _HeightFogNoiseSpeed *
                    0.45;

                float noise2 = dot(
                    SAMPLE_TEXTURE3D_LOD(
                        _FogNoise,
                        sampler_TrilinearRepeat,
                        noiseUVW2,
                        0
                    ).rgb,
                    float3(0.3333, 0.3333, 0.3333)
                );

                noise = noise * 0.7 + noise2 * 0.3;
                noise = lerp(1.0, noise, _HeightFogNoiseStrength);

                float fogAmount = 1.0 - exp(
                    -distanceFromCamera *
                    _HeightFogDensity *
                    heightFactor *
                    distanceFactor *
                    noise
                );

                return saturate(fogAmount * distanceFactor * _HeightFogIntensity);
            }

            float3 CalculateMainLightFog(
                float3 rayPos,
                float3 rayDir,
                float density,
                float transmittance
            )
            {
                float4 shadowCoord = TransformWorldToShadowCoord(rayPos);

                Light mainLight = GetMainLight(shadowCoord);

                float cosTheta = dot(rayDir, -mainLight.direction);

                float phase = henyey_greenstein( cosTheta, _LightScattering ) * 10.0;

                float sunDirectionMask = CalculateSunDirectionMask(rayDir, mainLight.direction);

                float3 scattering =
                    mainLight.color.rgb *
                    mainLight.shadowAttenuation *
                    phase *
                    sunDirectionMask;

                return
                    scattering *
                    density *
                    transmittance *
                    _StepSize *
                    _LightContribution*
                    _MainLightFogIntensity;
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
                   uint lightCount = GetAdditionalLightsCount();
                   uint maxLights = min(lightCount, (uint)_MaxAdditionalLights);

                   for (uint i = 0; i < maxLights; i++)
                   {
                        Light light = GetAdditionalLight(i, rayPos);

                        float cosTheta = dot(rayDir, -light.direction);
                        float phase = henyey_greenstein(cosTheta, _LightScattering) * 10.0;

                        float attenuation = light.distanceAttenuation * light.shadowAttenuation;

                        float3 scattering = light.color.rgb *  attenuation * phase;

                        result +=
                            scattering *
                            density *
                            transmittance *
                            _StepSize *
                            _LightContribution *
                            _AdditionalLightsFogIntensity;
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

                float depth = SampleSceneDepth(IN.texcoord);

                float3 worldPos =
                    ComputeWorldSpacePosition(
                        IN.texcoord,
                        depth,
                        UNITY_MATRIX_I_VP
                    );

                float3 cameraPos = _WorldSpaceCameraPos;

                float3 viewVector = worldPos - cameraPos;

                float viewLength = length(viewVector);

                float heightFogAmount = CalculateHeightFog(worldPos, viewLength);

                float3 rayDir = normalize(viewVector);

                float distLimit = min(viewLength, _MaxDistance);

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

                    float3 rayPos =  cameraPos + rayDir * distTravelled;

                    float density =  get_density(rayPos);                

                    if (density <= 0.001)
                    {
                        distTravelled += _StepSize;
                        continue;
                    }

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

                        transmittance *=  exp(-density * _StepSize);

                        if (transmittance < 0.01)
                            break;
                    }

                    distTravelled += _StepSize;
                }

                float fogAmount =
                    (1.0 - saturate(transmittance)) *
                    _FogOpacity;

                float3 finalFog = (_Color.rgb * fogAmount) + fogLighting;

                float3 finalColor = lerp(
                    sceneColor.rgb,
                    finalFog,
                    fogAmount
                );

                finalColor = lerp(
                    finalColor,
                    _HeightFogColor.rgb,
                    heightFogAmount
                );

                return float4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}
