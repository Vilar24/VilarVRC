//Since this is shared, and the output structs/input structs are all slightly differently named in each shader template, just handle them all here.
float4 CustomStandardLightingBRDF(
    #if defined(GEOMETRY)
        g2f i
    #elif defined(TESSELLATION)
        vertexOutput i
    #else
        v2f i
    #endif
    )
{
    //LIGHTING PARAMS
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    float3 lightDir = getLightDir(i.worldPos);
    float4 lightCol = _LightColor0;

    //NORMAL
    float3 normalMap = UnpackNormal(tex2D(_BumpMap, i.uv));
    float3 worldNormal = getNormal(normalMap, i.btn[0], i.btn[1], i.btn[2]);

    //METALLIC SMOOTHNESS
    float4 metallicGlossMap = tex2D(_MetallicGlossMap, i.uv);
    float4 metallicSmoothness = getMetallicSmoothness(metallicGlossMap);

    //DIFFUSE
    fixed4 diffuse = tex2D(_MainTex, i.uv) * _Color;
    fixed4 diffuseColor = diffuse; //Store for later use, we alter it after.
    diffuse.rgb *= (1-metallicSmoothness.x);

		//OCCLUSION
    float4 occlusionMap = tex2D(_OcclusionMap, i.uv);
		float occlusion = occlusionMap.r;

		//EMISSION
		float4 emission = tex2D(_EmissionMap, i.uv);
#if defined(UNITY_PASS_FORWARDBASE)
		float3 deltas = fwidth(i.bary);
		float3 smoothing = deltas * _WireframeSmoothing;
		float3 thickness = deltas * _WireframeThickness;
		i.bary = smoothstep(thickness, thickness + smoothing, i.bary);
		float minBary = min(i.bary.x, min(i.bary.y, i.bary.z));
		minBary = saturate(minBary);
		minBary *= 1-i.uv1.y*0.5;
		minBary = 1 - minBary;
		emission.rgb += i.uv1.x * lerp(_WireframeColor, _WireframeColor2, saturate(1-i.uv1.x*0.1)) * minBary;
#endif

    //LIGHTING VECTORS
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 halfVector = normalize(lightDir + viewDir);
    float3 reflViewDir = reflect(-viewDir, worldNormal);
    float3 reflLightDir = reflect(lightDir, worldNormal);

    //DOT PRODUCTS FOR LIGHTING
    float ndl = saturate(dot(lightDir, worldNormal));
    float vdn = abs(dot(viewDir, worldNormal));
    float rdv = saturate(dot(reflLightDir, float4(-viewDir, 0)));

    //LIGHTING
    float3 lighting = float3(0,0,0);

    #if defined(LIGHTMAP_ON)
        float3 indirectDiffuse = 0;
        float3 directDiffuse = getLightmap(i.uv1, worldNormal, i.worldPos);
        #if defined(DYNAMICLIGHTMAP_ON)
            float3 realtimeLM = getRealtimeLightmap(i.uv2, worldNormal);
            directDiffuse += realtimeLM;
        #endif
    #else
        float3 indirectDiffuse;
        if(_LightProbeMethod == 0)
        {
            indirectDiffuse = ShadeSH9(float4(worldNormal, 1));
        }
        else
        {
            float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
            indirectDiffuse.r = shEvaluateDiffuseL1Geomerics(L0.r, unity_SHAr.xyz, worldNormal);
            indirectDiffuse.g = shEvaluateDiffuseL1Geomerics(L0.g, unity_SHAg.xyz, worldNormal);
            indirectDiffuse.b = shEvaluateDiffuseL1Geomerics(L0.b, unity_SHAb.xyz, worldNormal);
        }

        float3 directDiffuse = ndl * attenuation * _LightColor0;
    #endif

    float3 indirectSpecular = getIndirectSpecular(i.worldPos, diffuseColor, vdn, metallicSmoothness, reflViewDir, indirectDiffuse, viewDir, directDiffuse);
    float3 directSpecular = getDirectSpecular(lightCol, diffuseColor, metallicSmoothness, rdv, attenuation);

    lighting = diffuse * (directDiffuse + indirectDiffuse) * occlusion + emission; 
    lighting += directSpecular; 
    lighting += indirectSpecular;
		lighting += emission;

    float al = 1;
    #if defined(alphablend)
        al = diffuseColor.a;
    #endif

    return float4(lighting, al);
}