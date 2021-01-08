Shader "Vilar/GeometryDissolve"
{
	Properties
	{
        [Header(MAIN)]
        [Enum(Unity Default, 0, Non Linear, 1)]_LightProbeMethod("Light Probe Sampling", Int) = 0
        //[Enum(UVs, 0, Triplanar World, 1, Triplanar Object, 2)]_TextureSampleMode("Texture Mode", Int) = 0
        [Enum(Opaque, 0, Cutout, 1)] _Mode("Texture Mode", Int) = 0
        //_TriplanarFalloff("Triplanar Blend", Range(0.5,1)) = 1
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        
        [Space(16)]
        [Header(NORMALS)]
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(-1,1)) = 1
        
        [Space(16)]
        [Header(METALLIC)]
        _MetallicGlossMap("Metallic Map", 2D) = "black" {}
        _Reflectance("Reflectance", Range(0,1)) = 0.5
        [Header(VRCHAT FALLBACK VALUES)]
        _Metallic("Metallic", Range(0,1)) = 0
        _Glossiness("Smoothness", Range(0,1)) = 0
        
        [Space(16)]
        [Header(EMISSION)]
        _EmissionMap("Emission Map", 2D) = "black" {}

        [Space(16)]
        [Header(CLEARCOAT)]
        _ClearcoatMap("Clearcoat Map", 2D) = "white" {}
        _Clearcoat("Clearcoat", Range(0,1)) = 0
        _ClearcoatGlossiness("Clearcoat Smoothness", Range(0,1)) = 0.5
        
				[Space(16)]
				[Header(AMBIENTBOOST)]
				_AmbientBoostGround("Ambient Boost Ground", Color) = (0,0,0,1)
        _AmbientBoostHorizon("Ambient Boost Horizon", Color) = (0,0,0,1)
        _AmbientBoostSky("Ambient Boost Sky", Color) = (0,0,0,1)
				_AmbientBoost("Ambient Boost", Range(0,1)) = 0

        [Space(16)]
        [Header(DISSOLVE)]
				_WireframeColor("Wireframe Color", Color) = (1,1,1,1)
				_WireframeColor2("Wireframe Color 2", Color) = (1,1,1,1)
				_WireframeSmoothing("Wireframe Smoothing", Range(0,1)) = 1
				_WireframeThickness("Wireframe Coverage", Range(0,1)) = 1
 				_DissolveDistance("Dissolve Distance", Range(0,1)) = 1
				_DissolveCoverage("Dissolve Coverage", Range(0,1)) = 1

        //[Space(16)]
        //[Header(SUBSURFACE)]
        //_SubsurfaceColor("Subsurface Color", Color) = (1,1,1,1)
        
        //#TESS![Space(16)]
        //#TESS![Header(GEOMETRYTESSELLATION SETTINGS)]
        //#TESS![Enum(Uniform, 0, Edge Length, 1, Distance, 2)]_TessellationMode("Tessellation Mode", Int) = 1
        //#TESS!_TessellationUniform("Tessellation Factor", Range(0,1)) = 0.05
        //#TESS!_TessClose("Tessellation Close", Float) = 10
        //#TESS!_TessFar("Tessellation Far", Float) = 50
        
        //[Space(16)]
        //[Header(LIGHTMAPPING HACKS)]
        //_SpecularLMOcclusion("Specular Occlusion", Range(0,1)) = 0
        //_SpecLMOcclusionAdjust("Spec Occlusion Sensitiviy", Range(0,1)) = 0.2
        //_LMStrength("Lightmap Strength", Range(0,1)) = 1
        //_RTLMStrength("Realtime Lightmap Strength", Range(0,1)) = 1
    }
	SubShader
	{
		Tags { "Queue"="Geometry" }

		Pass
		{
            Tags {"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
            #pragma geometry geom
			#pragma fragment frag
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile_fwdbase 
            #define GEOMETRY

            #ifndef UNITY_PASS_FORWARDBASE
                #define UNITY_PASS_FORWARDBASE
            #endif
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
			};

			struct v2g
			{
                float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float4 tangent : TEXCOORD4;
			};

            struct g2f
            {
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float3 btn[3] : TEXCOORD3; //TEXCOORD2, TEXCOORD3 | bitangent, tangent, worldNormal
                float3 worldPos : TEXCOORD6;
                float3 objPos : TEXCOORD7;
                float3 objNormal : TEXCOORD8;
								float3 bary : texcoord10;
                SHADOW_COORDS(9)
            };

            #include "Defines.cginc"
            #include "LightingFunctions.cginc"
            #include "LightingBRDF.cginc"
			#include "VertFragGeom.cginc"
			
			ENDCG
		}

        Pass
		{
            Tags {"LightMode"="ForwardAdd"}
            Blend One One
            ZWrite Off
            
			CGPROGRAM
			#pragma vertex vert
            #pragma geometry geom
			#pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #define GEOMETRY

            #ifndef UNITY_PASS_FORWARDADD
                #define UNITY_PASS_FORWARDADD
            #endif
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
			};

			struct v2g
			{
                float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 tangent : TEXCOORD2;
			};

            struct g2f
            {
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 btn[3] : TEXCOORD1; //TEXCOORD2, TEXCOORD3 | bitangent, tangent, worldNormal
                float3 worldPos : TEXCOORD4;
                float3 objPos : TEXCOORD5;
                float3 objNormal : TEXCOORD6;
                SHADOW_COORDS(7)
            };

			
            #include "Defines.cginc"
            #include "LightingFunctions.cginc"
            #include "LightingBRDF.cginc"
			#include "VertFragGeom.cginc"
			
			ENDCG
		}

        Pass
        {
            Tags{"LightMode" = "ShadowCaster"} //Removed "DisableBatching" = "True". If issues arise re-add this.
            Cull Off
            CGPROGRAM
            #include "UnityCG.cginc" 
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            #pragma multi_compile_shadowcaster
            #define GEOMETRY
            
            #ifndef UNITY_PASS_SHADOWCASTER
                #define UNITY_PASS_SHADOWCASTER
            #endif
            
            struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
			};

			struct v2g
			{
                float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 tangent : TEXCOORD2;
			};

            struct g2f
            {
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
            };

            #include "Defines.cginc"
            #include "VertFragGeom.cginc"
            ENDCG
        }
	}
}
