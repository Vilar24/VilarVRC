// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Vilar/EyeTrack"
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_EmissionMap("Emission", 2D) = "black" {}
		_ParallaxHeight("ParallaxHeight", 2D) = "white" {}
		_StylizedReflection("StylizedReflection", CUBE) = "black" {}
		_EyeOffset("EyeOffset", Float) = 0
		_Specular("Specular", Range( 0 , 1)) = 0
		_Glossiness("Smooth", Range( 0 , 1)) = 0
		_EmissionMapPower("EmissionPower", Range( 0 , 1)) = 0
		_Depth("Depth", Range( 0 , 1)) = 0.5236971
		_IrisSize("IrisSize", Range( 0 , 1)) = 0
		_FollowLimit("FollowLimit", Range( -1 , 1)) = 0
		_FollowPower("FollowPower", Range( 0 , 1)) = 0
		_CrossEye("CrossEye", Range( -1 , 1)) = 0
		_MaxPupilDialation("MaxPupilDialation", Range( 0 , 1)) = 0
		_PupilDialationFrequency("PupilDialationFrequency", Range( 0 , 1)) = 0
		_TwitchMagnitude("TwitchMagnitude", Range( 0 , 1)) = 0.1
		_TwitchShiftyness("TwitchShiftyness", Range( 0 , 1)) = 0
		_Backward("Backward", Range( 0 , 1)) = 0
		_MayaModel("MayaModel", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float3 viewDir;
		};

		uniform sampler2D _BumpMap;
		uniform samplerCUBE _StylizedReflection;
		uniform sampler2D _MainTex;
		uniform float _CrossEye;
		uniform float _EyeOffset;
		uniform float _Backward;
		uniform float _MayaModel;
		uniform float _FollowPower;
		uniform float _FollowLimit;
		uniform float _TwitchMagnitude;
		uniform float _TwitchShiftyness;
		uniform sampler2D _ParallaxHeight;
		uniform float _Depth;
		uniform float _IrisSize;
		uniform float _MaxPupilDialation;
		uniform float _PupilDialationFrequency;
		uniform sampler2D _EmissionMap;
		uniform float _EmissionMapPower;
		uniform float _Specular;
		uniform float _Glossiness;


		float2 ParallaxOcclusionCustom277( float3 normalWorld , sampler2D heightMap , float2 uvs , float3 viewWorld , float3 viewDirTan , float parallax , float refPlane )
		{
			float2 dx = ddx(uvs);
			float2 dy = ddy(uvs);
			float minSamples = 8;
			float maxSamples = 16;
			float3 result = 0;
			int stepIndex = 0;
			int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, (float)dot( normalWorld, viewWorld ) );
			float layerHeight = 1.0 / numSteps;
			float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
			uvs += refPlane * plane;
			float2 deltaTex = -plane * layerHeight;
			float2 prevTexOffset = 0;
			float prevRayZ = 1.0f;
			float prevHeight = 0.0f;
			float2 currTexOffset = deltaTex;
			float currRayZ = 1.0f - layerHeight;
			float currHeight = 0.0f;
			float intersection = 0;
			float2 finalTexOffset = 0;
			while ( stepIndex < numSteps + 1 )
			{
				currHeight = tex2Dgrad( heightMap, uvs + currTexOffset, dx, dy ).r;
				if ( currHeight > currRayZ )
				{
					stepIndex = numSteps + 1;
				}
				else
				{
					stepIndex++;
					prevTexOffset = currTexOffset;
					prevRayZ = currRayZ;
					prevHeight = currHeight;
					currTexOffset += deltaTex;
					currRayZ -= layerHeight;
				}
			}
			int sectionSteps = 2;
			int sectionIndex = 0;
			float newZ = 0;
			float newHeight = 0;
			while ( sectionIndex < sectionSteps )
			{
				intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
				finalTexOffset = prevTexOffset + intersection * deltaTex;
				newZ = prevRayZ - intersection * layerHeight;
				newHeight = tex2Dgrad( heightMap, uvs + finalTexOffset, dx, dy ).r;
				if ( newHeight > newZ )
				{
					currTexOffset = finalTexOffset;
					currHeight = newHeight;
					currRayZ = newZ;
					deltaTex = intersection * deltaTex;
					layerHeight = intersection * layerHeight;
				}
				else
				{
					prevTexOffset = finalTexOffset;
					prevHeight = newHeight;
					prevRayZ = newZ;
					deltaTex = ( 1 - intersection ) * deltaTex;
					layerHeight = ( 1 - intersection ) * layerHeight;
				}
				sectionIndex++;
			}
			return uvs + finalTexOffset;
		}


		float4x4 GenerateLookMatrix1( float3 target , float3 up )
		{
			float3 zaxis = normalize(target.xyz);
			float3 xaxis = normalize(cross(up, zaxis));
			float3 yaxis = cross(zaxis, xaxis);
			float4x4 lookMatrix = float4x4(xaxis.x, yaxis.x, zaxis.x, 0,xaxis.y, yaxis.y, zaxis.y, 0, xaxis.z, yaxis.z, zaxis.z, 0, 0, 0, 0, 1);
			return lookMatrix;
		}


		float3 GetLocalCameraPosition435( float3 up )
		{
			float3 centerEye = _WorldSpaceCameraPos.xyz; 
			#if UNITY_SINGLE_PASS_STEREO 
			int startIndex = unity_StereoEyeIndex; 
			unity_StereoEyeIndex = 0; 
			float3 leftEye = _WorldSpaceCameraPos; 
			unity_StereoEyeIndex = 1; 
			float3 rightEye = _WorldSpaceCameraPos;
			unity_StereoEyeIndex = startIndex;
			centerEye = lerp(leftEye, rightEye, 0.5);
			#endif 
			float3 cam = mul(unity_WorldToObject, float4(centerEye, 1)).xyz;
			return cam;
		}


		float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
		{
			original -= center;
			float C = cos( angle );
			float S = sin( angle );
			float t = 1 - C;
			float m00 = t * u.x * u.x + C;
			float m01 = t * u.x * u.y - S * u.z;
			float m02 = t * u.x * u.z + S * u.y;
			float m10 = t * u.x * u.y + S * u.z;
			float m11 = t * u.y * u.y + C;
			float m12 = t * u.y * u.z - S * u.x;
			float m20 = t * u.x * u.z - S * u.y;
			float m21 = t * u.y * u.z + S * u.x;
			float m22 = t * u.z * u.z + C;
			float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
			return mul( finalMatrix, original ) + center;
		}


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float Backward534 = round( _Backward );
			float3 lerpResult530 = lerp( float3(0,0,1) , float3(0,0,-1) , Backward534);
			float temp_output_515_0 = round( _MayaModel );
			float3 lerpResult511 = lerp( float3(0,0,1) , float3(0,1,0) , temp_output_515_0);
			float3 UpVector478 = lerpResult511;
			float3 up435 = UpVector478;
			float3 localGetLocalCameraPosition435435 = GetLocalCameraPosition435( up435 );
			float3 rotatedValue509 = RotateAroundAxis( float3( 0,0,0 ), localGetLocalCameraPosition435435, float3(1,0,0), -1.57 );
			float3 lerpResult518 = lerp( rotatedValue509 , localGetLocalCameraPosition435435 , UpVector478.y);
			float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
			float3 appendResult378 = (float3(( _EyeOffset / ase_objectScale.x ) , 0.0 , 0.0));
			float3 rotatedValue542 = RotateAroundAxis( float3( 0,0,0 ), appendResult378, float3(1,0,0), -1.57 );
			float3 lerpResult543 = lerp( rotatedValue542 , appendResult378 , UpVector478.y);
			float3 temp_output_375_0 = ( lerpResult518 + lerpResult543 );
			float3 normalizeResult384 = normalize( temp_output_375_0 );
			float3 normalizeResult364 = normalize( temp_output_375_0 );
			float dotResult362 = dot( normalizeResult364 , lerpResult530 );
			float3 lerpResult371 = lerp( lerpResult530 , normalizeResult384 , ( _FollowPower * saturate( ( 10.0 * ( dotResult362 - _FollowLimit ) ) ) ));
			float mulTime398 = _Time.y * 0.8;
			float temp_output_410_0 = round( mulTime398 );
			float2 temp_cast_0 = (temp_output_410_0).xx;
			float simplePerlin2D389 = snoise( temp_cast_0 );
			float2 temp_cast_1 = (( temp_output_410_0 + 123.234 )).xx;
			float simplePerlin2D403 = snoise( temp_cast_1 );
			float3 appendResult395 = (float3(( -0.5 + simplePerlin2D389 ) , ( -0.5 + simplePerlin2D403 ) , 0.0));
			float temp_output_418_0 = round( ( mulTime398 + 0.5 ) );
			float2 temp_cast_2 = (temp_output_418_0).xx;
			float simplePerlin2D425 = snoise( temp_cast_2 );
			float2 temp_cast_3 = (( temp_output_418_0 + 123.234 )).xx;
			float simplePerlin2D426 = snoise( temp_cast_3 );
			float3 appendResult424 = (float3(( -0.5 + simplePerlin2D425 ) , ( -0.5 + simplePerlin2D426 ) , 0.0));
			float3 lerpResult429 = lerp( appendResult395 , appendResult424 , saturate( ( fmod( mulTime398 , 1.0 ) * 14.0 ) ));
			float mulTime445 = _Time.y * ( 0.2 + ( 0.3 * _TwitchShiftyness ) );
			float2 temp_cast_4 = (mulTime445).xx;
			float simplePerlin2D447 = snoise( temp_cast_4 );
			float3 lerpResult453 = lerp( lerpResult429 , float3(0,0,0) , saturate( ( ( simplePerlin2D447 + -( _TwitchShiftyness + -0.5 ) ) * 14.0 ) ));
			float3 temp_output_382_0 = ( ( float3(1,0,0) * _CrossEye * _EyeOffset * 20.0 ) + lerpResult371 + ( _TwitchMagnitude * lerpResult453 ) );
			float3 lerpResult533 = lerp( temp_output_382_0 , ( float3(-1,-1,-1) * temp_output_382_0 ) , Backward534);
			float3 target1 = lerpResult533;
			float3 up1 = float3(0,1,0);
			float4x4 localGenerateLookMatrix11 = GenerateLookMatrix1( target1 , up1 );
			float Maya537 = temp_output_515_0;
			float4x4 lerpResult526 = lerp( mul( mul( float4x4(1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1), localGenerateLookMatrix11 ), float4x4(1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1) ) , localGenerateLookMatrix11 , Maya537);
			float3 ase_vertex3Pos = v.vertex.xyz;
			v.vertex.xyz = mul( lerpResult526, float4( ase_vertex3Pos , 0.0 ) ).xyz;
			v.normal = mul(lerpResult526, v.normal).xyz;
			v.tangent.xyz = mul(lerpResult526, v.tangent.xyz).xyz;
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			float3 NormalMap214 = UnpackNormal( tex2D( _BumpMap, i.uv_texcoord ) );
			o.Normal = NormalMap214;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float Backward534 = round( _Backward );
			float3 lerpResult530 = lerp( float3(0,0,1) , float3(0,0,-1) , Backward534);
			float temp_output_515_0 = round( _MayaModel );
			float3 lerpResult511 = lerp( float3(0,0,1) , float3(0,1,0) , temp_output_515_0);
			float3 UpVector478 = lerpResult511;
			float3 up435 = UpVector478;
			float3 localGetLocalCameraPosition435435 = GetLocalCameraPosition435( up435 );
			float3 rotatedValue509 = RotateAroundAxis( float3( 0,0,0 ), localGetLocalCameraPosition435435, float3(1,0,0), -1.57 );
			float3 lerpResult518 = lerp( rotatedValue509 , localGetLocalCameraPosition435435 , UpVector478.y);
			float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
			float3 appendResult378 = (float3(( _EyeOffset / ase_objectScale.x ) , 0.0 , 0.0));
			float3 rotatedValue542 = RotateAroundAxis( float3( 0,0,0 ), appendResult378, float3(1,0,0), -1.57 );
			float3 lerpResult543 = lerp( rotatedValue542 , appendResult378 , UpVector478.y);
			float3 temp_output_375_0 = ( lerpResult518 + lerpResult543 );
			float3 normalizeResult384 = normalize( temp_output_375_0 );
			float3 normalizeResult364 = normalize( temp_output_375_0 );
			float dotResult362 = dot( normalizeResult364 , lerpResult530 );
			float3 lerpResult371 = lerp( lerpResult530 , normalizeResult384 , ( _FollowPower * saturate( ( 10.0 * ( dotResult362 - _FollowLimit ) ) ) ));
			float mulTime398 = _Time.y * 0.8;
			float temp_output_410_0 = round( mulTime398 );
			float2 temp_cast_5 = (temp_output_410_0).xx;
			float simplePerlin2D389 = snoise( temp_cast_5 );
			float2 temp_cast_6 = (( temp_output_410_0 + 123.234 )).xx;
			float simplePerlin2D403 = snoise( temp_cast_6 );
			float3 appendResult395 = (float3(( -0.5 + simplePerlin2D389 ) , ( -0.5 + simplePerlin2D403 ) , 0.0));
			float temp_output_418_0 = round( ( mulTime398 + 0.5 ) );
			float2 temp_cast_7 = (temp_output_418_0).xx;
			float simplePerlin2D425 = snoise( temp_cast_7 );
			float2 temp_cast_8 = (( temp_output_418_0 + 123.234 )).xx;
			float simplePerlin2D426 = snoise( temp_cast_8 );
			float3 appendResult424 = (float3(( -0.5 + simplePerlin2D425 ) , ( -0.5 + simplePerlin2D426 ) , 0.0));
			float3 lerpResult429 = lerp( appendResult395 , appendResult424 , saturate( ( fmod( mulTime398 , 1.0 ) * 14.0 ) ));
			float mulTime445 = _Time.y * ( 0.2 + ( 0.3 * _TwitchShiftyness ) );
			float2 temp_cast_9 = (mulTime445).xx;
			float simplePerlin2D447 = snoise( temp_cast_9 );
			float3 lerpResult453 = lerp( lerpResult429 , float3(0,0,0) , saturate( ( ( simplePerlin2D447 + -( _TwitchShiftyness + -0.5 ) ) * 14.0 ) ));
			float3 temp_output_382_0 = ( ( float3(1,0,0) * _CrossEye * _EyeOffset * 20.0 ) + lerpResult371 + ( _TwitchMagnitude * lerpResult453 ) );
			float3 lerpResult533 = lerp( temp_output_382_0 , ( float3(-1,-1,-1) * temp_output_382_0 ) , Backward534);
			float3 target1 = lerpResult533;
			float3 up1 = float3(0,1,0);
			float4x4 localGenerateLookMatrix11 = GenerateLookMatrix1( target1 , up1 );
			float Maya537 = temp_output_515_0;
			float4x4 lerpResult526 = lerp( mul( mul( float4x4(1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1), localGenerateLookMatrix11 ), float4x4(1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1) ) , localGenerateLookMatrix11 , Maya537);
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_vertexTangent = mul( unity_WorldToObject, float4( ase_worldTangent, 0 ) );
			float3 normalizeResult251 = normalize( ase_vertexTangent );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3 ase_vertexBitangent = mul( unity_WorldToObject, float4( ase_worldBitangent, 0 ) );
			float3 normalizeResult252 = normalize( ase_vertexBitangent );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float3 normalizeResult250 = normalize( ase_vertexNormal );
			float3 temp_output_10_0 = mul( lerpResult526, float4( normalizeResult250 , 0.0 ) ).xyz;
			float3 normalizeResult231 = normalize( mul( NormalMap214, float3x3(mul( lerpResult526, float4( normalizeResult251 , 0.0 ) ).xyz, mul( lerpResult526, float4( normalizeResult252 , 0.0 ) ).xyz, temp_output_10_0) ) );
			float3 normalizeResult263 = normalize( mul( unity_ObjectToWorld, float4( normalizeResult231 , 0.0 ) ).xyz );
			float3 WorldNorma264 = normalizeResult263;
			float3 normalWorld277 = WorldNorma264;
			sampler2D heightMap277 = _ParallaxHeight;
			float2 uvs277 = i.uv_texcoord;
			float3 viewWorld277 = ase_worldViewDir;
			float3 viewDirTan277 = i.viewDir;
			float parallax277 = _Depth;
			float refPlane277 = 0.0;
			float2 localParallaxOcclusionCustom277277 = ParallaxOcclusionCustom277( normalWorld277 , heightMap277 , uvs277 , viewWorld277 , viewDirTan277 , parallax277 , refPlane277 );
			float2 temp_output_87_0 = ( localParallaxOcclusionCustom277277 + float2( -0.5,-0.5 ) );
			float2 normalizeResult89 = normalize( temp_output_87_0 );
			float temp_output_90_0 = length( temp_output_87_0 );
			float mulTime467 = _Time.y * ( 0.3 * _PupilDialationFrequency );
			float2 temp_cast_18 = (mulTime467).xx;
			float simplePerlin2D463 = snoise( temp_cast_18 );
			float smoothstepResult464 = smoothstep( 0.0 , 1.0 , simplePerlin2D463);
			float2 lerpResult142 = lerp( localParallaxOcclusionCustom277277 , ( ( normalizeResult89 * saturate( (( -0.5 * ( _MaxPupilDialation * smoothstepResult464 ) ) + (temp_output_90_0 - 0.0) * (_IrisSize - ( -0.5 * ( _MaxPupilDialation * smoothstepResult464 ) )) / (_IrisSize - 0.0)) ) ) + float2( 0.5,0.5 ) ) , saturate( ( ( temp_output_90_0 - _IrisSize ) * -10.0 ) ));
			o.Albedo = ( ( texCUBElod( _StylizedReflection, float4( ( float3(-1,-1,1) * reflect( mul( unity_WorldToCamera, float4( ase_worldViewDir , 0.0 ) ).xyz , mul( unity_WorldToCamera, float4( WorldNormalVector( i , NormalMap214 ) , 0.0 ) ).xyz ) ), (float)0) ).r * _LightColor0 * 1.5 ) + tex2D( _MainTex, lerpResult142 ) ).rgb;
			o.Emission = ( tex2D( _EmissionMap, lerpResult142 ) * _EmissionMapPower ).rgb;
			float3 normalizeResult259 = normalize( ase_worldViewDir );
			float dotResult166 = dot( normalizeResult259 , WorldNorma264 );
			float3 temp_cast_21 = (( _Specular * pow( saturate( dotResult166 ) , 2.0 ) )).xxx;
			o.Specular = temp_cast_21;
			o.Smoothness = _Glossiness;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma only_renderers d3d9 d3d11 glcore gles gles3 
		#pragma surface surf StandardSpecular keepalpha fullforwardshadows vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandardSpecular o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardSpecular, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=14101
-919;68;1577;949;6951.683;-116.7855;1.3;True;True
Node;AmplifyShaderEditor.RangedFloatNode;512;-6552.185,12.78741;Float;False;Property;_MayaModel;MayaModel;19;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;473;-6316.801,-280.6982;Float;False;Constant;_Vector8;Vector 8;18;0;Create;0,0,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;472;-6316.834,-133.9629;Float;False;Constant;_Vector7;Vector 7;18;0;Create;0,1,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RoundOpNode;515;-6272.199,15.88681;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;511;-6097.602,-154.2599;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0.0,0,0;False;2;FLOAT;0.0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;376;-6640.981,652.9735;Float;False;Property;_EyeOffset;EyeOffset;5;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;379;-6642.194,737.2867;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;496;-6110.78,1305.996;Float;False;2485.183;1380.016;;47;453;429;452;454;424;443;395;451;450;455;421;436;406;396;422;404;423;420;403;426;447;389;433;397;456;425;434;437;458;419;445;408;460;418;459;409;410;417;441;461;462;427;428;398;446;457;444;Twitch Noise;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;478;-5931.646,-159.5876;Float;False;UpVector;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;480;-6073.612,567.3346;Float;False;478;0;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;380;-6452.229,697.4312;Float;False;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;377;-6469.609,804.0137;Float;False;Constant;_Float7;Float 7;14;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;378;-6318.289,710.9395;Float;False;FLOAT3;4;0;FLOAT;0.0;False;1;FLOAT;0.0;False;2;FLOAT;0.0;False;3;FLOAT;0.0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;540;-6427.572,1062.026;Float;False;Constant;_Float1;Float 1;19;0;Create;-1.57;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;541;-6429.203,913.8405;Float;False;Constant;_Vector5;Vector 5;19;0;Create;1,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;435;-5843.541,628.1476;Float;False;float3 centerEye = _WorldSpaceCameraPos.xyz@ $#if UNITY_SINGLE_PASS_STEREO $int startIndex = unity_StereoEyeIndex@ $unity_StereoEyeIndex = 0@ $float3 leftEye = _WorldSpaceCameraPos@ $unity_StereoEyeIndex = 1@ $float3 rightEye = _WorldSpaceCameraPos@$unity_StereoEyeIndex = startIndex@$centerEye = lerp(leftEye, rightEye, 0.5)@$#endif $float3 cam = mul(unity_WorldToObject, float4(centerEye, 1)).xyz@$return cam@;3;False;1;True;up;FLOAT3;0,0,0;In;Get Local Camera Position;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;508;-5792.011,880.4205;Float;False;Constant;_Vector4;Vector 4;19;0;Create;1,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;510;-5790.38,1028.607;Float;False;Constant;_Float0;Float 0;19;0;Create;-1.57;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;444;-6060.277,1800.113;Float;False;Constant;_Float20;Float 20;17;0;Create;0.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;509;-5491.974,776.1075;Float;False;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0.0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;446;-5417.949,2401.754;Float;False;Constant;_Float21;Float 21;17;0;Create;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;457;-5550.225,2498.806;Float;False;Property;_TwitchShiftyness;TwitchShiftyness;17;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;428;-5477.431,1863.344;Float;False;Constant;_Float17;Float 17;17;0;Create;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;542;-6128.565,832.1276;Float;False;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0.0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;398;-5860.228,1805.502;Float;False;1;0;FLOAT;1.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;487;-5852.112,507.1786;Float;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;527;-6550.635,98.24334;Float;False;Property;_Backward;Backward;18;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;543;-5428.511,649.9743;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;427;-5323.428,1805.593;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;518;-5082.583,522.8668;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0.0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;462;-5236.461,2362.153;Float;False;Constant;_Float24;Float 24;17;0;Create;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;363;-4653.998,777.3982;Float;False;997.3206;499.8208;;11;535;367;530;504;529;370;368;369;366;362;364;In Front Threshold;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;461;-5222.461,2444.153;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;528;-6270.649,101.3427;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;529;-4635.934,1045.727;Float;False;Constant;_Vector13;Vector 13;19;0;Create;0,0,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RoundOpNode;410;-5167.713,1538.797;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;535;-4636.479,1196.033;Float;False;534;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;375;-4894.618,580.9334;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;460;-5058.461,2394.153;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;504;-4634.664,902.9797;Float;False;Constant;_Vector11;Vector 11;19;0;Create;0,0,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;409;-5222.619,1619.399;Float;False;Constant;_Float14;Float 14;16;0;Create;123.234;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;418;-5171.588,1913.254;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;441;-5395.807,2169.234;Float;False;Constant;_Float18;Float 18;17;0;Create;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;459;-4961.461,2580.153;Float;False;Constant;_Float22;Float 22;18;0;Create;-0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;534;-6128.795,95.05414;Float;False;Backward;-1;True;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;417;-5226.494,1993.856;Float;False;Constant;_Float10;Float 10;16;0;Create;123.234;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;364;-4413.24,834.5177;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FmodOpNode;437;-5207.302,2131.534;Float;False;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;445;-4931.363,2414.145;Float;False;1;0;FLOAT;1.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;458;-4808.339,2501.298;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;530;-4416.769,987.8237;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;434;-5228.342,2236.155;Float;False;Constant;_Float19;Float 19;17;0;Create;14;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;419;-5006.743,1954.666;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;408;-5002.869,1580.209;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;426;-4853.392,1979.572;Float;False;Simplex2D;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;389;-4857.487,1459.362;Float;False;Simplex2D;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;397;-4820.637,1378.442;Float;False;Constant;_Float9;Float 9;16;0;Create;-0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;420;-4824.511,1752.899;Float;False;Constant;_Float11;Float 11;16;0;Create;-0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;425;-4861.361,1833.819;Float;False;Simplex2D;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;447;-4740.405,2411.948;Float;False;Simplex2D;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;456;-4679.225,2496.806;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;433;-5073.334,2178.054;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;403;-4849.518,1605.115;Float;False;Simplex2D;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;362;-4239.56,861.9775;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;367;-4413.936,1118.865;Float;False;Property;_FollowLimit;FollowLimit;11;0;Create;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;396;-4595.849,1395.15;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;421;-4614.915,2018.702;Float;False;Constant;_Float16;Float 16;16;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;423;-4596.554,1913.76;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;455;-4532.954,2454.392;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;422;-4599.723,1769.607;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;450;-4548.715,2557.682;Float;False;Constant;_Float23;Float 23;17;0;Create;14;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;369;-4092.929,850.0869;Float;False;Constant;_Float6;Float 6;13;0;Create;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;404;-4592.68,1539.303;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;366;-4082.667,930.4948;Float;False;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;436;-4923.839,2176.461;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;406;-4611.042,1644.245;Float;False;Constant;_Float5;Float 5;16;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;451;-4393.703,2499.581;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;443;-4334.19,2099.719;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;395;-4428.773,1472.612;Float;False;FLOAT3;4;0;FLOAT;0.0;False;1;FLOAT;0.0;False;2;FLOAT;0.0;False;3;FLOAT;0.0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;424;-4432.647,1847.069;Float;False;FLOAT3;4;0;FLOAT;0.0;False;1;FLOAT;0.0;False;2;FLOAT;0.0;False;3;FLOAT;0.0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;368;-3936.537,880.8813;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;429;-4064.305,1613.357;Float;False;3;0;FLOAT3;0.0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0.0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;452;-4244.208,2497.988;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;370;-3801.381,882.5921;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;374;-3775.949,678.8667;Float;False;Property;_FollowPower;FollowPower;12;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;454;-4065.828,2029.371;Float;False;Constant;_Vector6;Vector 6;12;0;Create;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;453;-3796.539,2010.795;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0.0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;386;-5380.394,155.0096;Float;False;Constant;_Vector2;Vector 2;12;0;Create;1,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;412;-3557.299,1028.381;Float;False;Property;_TwitchMagnitude;TwitchMagnitude;16;0;Create;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;383;-5483.34,304.5711;Float;False;Property;_CrossEye;CrossEye;13;0;Create;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;373;-3483.443,703.1264;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;388;-5361.395,381.3661;Float;False;Constant;_10;10;16;0;Create;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;384;-3663.472,576.3245;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;385;-5140.363,258.4681;Float;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0.0,0,0;False;2;FLOAT;0,0,0;False;3;FLOAT;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;411;-3208.296,1120.675;Float;False;2;2;0;FLOAT;0,0,0;False;1;FLOAT3;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;371;-3295.666,551.3974;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;382;-2935.625,277.297;Float;False;3;3;0;FLOAT3;0.0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;532;-2768.841,109.9756;Float;False;Constant;_Vector14;Vector 14;20;0;Create;-1,-1,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;536;-2582.112,432.9915;Float;False;534;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;531;-2563.841,179.9756;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0.0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;533;-2379.157,375.3402;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;519;-2191.026,503.0161;Float;False;Constant;_Vector12;Vector 12;19;0;Create;0,1,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Matrix4X4Node;523;-2161.173,121.1635;Float;False;Constant;_Matrix0;Matrix 0;19;0;Create;1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CustomExpressionNode;1;-2005.25,431.8339;Float;False;float3 zaxis = normalize(target.xyz)@$float3 xaxis = normalize(cross(up, zaxis))@$float3 yaxis = cross(zaxis, xaxis)@$float4x4 lookMatrix = float4x4(xaxis.x, yaxis.x, zaxis.x, 0,xaxis.y, yaxis.y, zaxis.y, 0, xaxis.z, yaxis.z, zaxis.z, 0, 0, 0, 0, 1)@$return lookMatrix@$;6;False;2;True;target;FLOAT3;0,0,0;In;True;up;FLOAT3;0,0,0;In;GenerateLookMatrix;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.Matrix4X4Node;525;-2002.367,252.6803;Float;False;Constant;_Matrix1;Matrix 1;19;0;Create;1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;524;-1805.267,155.5804;Float;False;2;2;0;FLOAT4x4;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;537;-6113.763,13.11621;Float;False;Maya;-1;True;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;521;-1664.263,191.9612;Float;False;2;2;0;FLOAT4x4;0.0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0.0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.TangentVertexDataNode;223;-1104.025,417.6775;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BitangentVertexDataNode;225;-1113.609,593.6409;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;354;-4332.519,-1297.648;Float;False;692.4456;984.2021;Comment;8;277;27;150;279;149;278;280;29;ComputedUVs;1,1,1,1;0;0
Node;AmplifyShaderEditor.NormalVertexDataNode;8;-1102.725,250.686;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;538;-1675.113,470.1125;Float;False;537;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;526;-1448.362,322.5558;Float;False;3;0;FLOAT4x4;0.0;False;1;FLOAT4x4;0.0;False;2;FLOAT;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.NormalizeNode;250;-895.3977,257.3447;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;252;-889.9548,629.6013;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;27;-4245.138,-1231.216;Float;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;251;-881.6673,400.7412;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;22;-3523.521,-1278.859;Float;True;Property;_BumpMap;Normal;1;0;Create;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;226;-706.3069,573.7806;Float;False;2;2;0;FLOAT4x4;0.0,0,0;False;1;FLOAT3;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;229;-497.8315,350.6757;Float;False;370.1652;227.7619;Tangent Transform (To perturb normals);1;227;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-710.1921,458.13;Float;False;2;2;0;FLOAT4x4;0,0,0;False;1;FLOAT3;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;-702.084,285.9325;Float;False;2;2;0;FLOAT4x4;0.0,0,0;False;1;FLOAT3;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;214;-3235.835,-1278.784;Float;False;NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;230;-301.4922,261.8212;Float;False;214;0;1;FLOAT3;0
Node;AmplifyShaderEditor.MatrixFromVectors;227;-426.0369,412.3703;Float;False;FLOAT3x3;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;238;-86.44536,288.4688;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3x3;0.0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;283;-3429.669,-885.3046;Float;False;2283.171;809.6124;;28;327;467;139;154;140;94;464;466;463;465;142;147;97;96;98;145;89;144;99;146;91;141;90;92;87;88;469;470;Pupil Dialation;1,1,1,1;0;0
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;260;13.43571,202.5674;Float;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.NormalizeNode;231;69.26704,291.4679;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;261;237.9546,230.4723;Float;False;2;2;0;FLOAT4x4;0,0,0;False;1;FLOAT3;0.0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;468;-3919.212,-208.2118;Float;False;Property;_PupilDialationFrequency;PupilDialationFrequency;15;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;470;-3414.294,-320.5233;Float;False;Constant;_Float27;Float 27;18;0;Create;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;469;-3266.448,-310.6667;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;263;375.0744,230.7548;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;280;-4223.775,-485.1497;Float;False;Tangent;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;264;528.7341,225.3126;Float;False;WorldNorma;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-4306.341,-898.3617;Float;False;Property;_Depth;Depth;9;0;Create;0.5236971;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;278;-4240.505,-720.6521;Float;False;264;0;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;149;-4260.541,-1098.41;Float;True;Property;_ParallaxHeight;ParallaxHeight;3;0;Create;None;False;white;Auto;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;279;-4208.98,-637.2007;Float;False;World;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;467;-3127.26,-309.8237;Float;False;1;0;FLOAT;1.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;150;-4184.209,-805.7838;Float;False;Constant;_Float13;Float 13;16;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;466;-2907.943,-165.3017;Float;False;Constant;_Float26;Float 26;18;0;Create;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;465;-2906.943,-239.3017;Float;False;Constant;_Float25;Float 25;18;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;463;-2964.943,-314.3018;Float;False;Simplex2D;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;277;-3890.354,-892.9845;Float;False;float2 dx = ddx(uvs)@$float2 dy = ddy(uvs)@$float minSamples = 8@$float maxSamples = 16@$float3 result = 0@$int stepIndex = 0@$int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, (float)dot( normalWorld, viewWorld ) )@$float layerHeight = 1.0 / numSteps@$float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z )@$uvs += refPlane * plane@$float2 deltaTex = -plane * layerHeight@$float2 prevTexOffset = 0@$float prevRayZ = 1.0f@$float prevHeight = 0.0f@$float2 currTexOffset = deltaTex@$float currRayZ = 1.0f - layerHeight@$float currHeight = 0.0f@$float intersection = 0@$float2 finalTexOffset = 0@$while ( stepIndex < numSteps + 1 )${$	currHeight = tex2Dgrad( heightMap, uvs + currTexOffset, dx, dy ).r@$	if ( currHeight > currRayZ )$	{$		stepIndex = numSteps + 1@$	}$	else$	{$		stepIndex++@$		prevTexOffset = currTexOffset@$		prevRayZ = currRayZ@$		prevHeight = currHeight@$		currTexOffset += deltaTex@$		currRayZ -= layerHeight@$	}$}$int sectionSteps = 2@$int sectionIndex = 0@$float newZ = 0@$float newHeight = 0@$while ( sectionIndex < sectionSteps )${$	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ )@$	finalTexOffset = prevTexOffset + intersection * deltaTex@$	newZ = prevRayZ - intersection * layerHeight@$	newHeight = tex2Dgrad( heightMap, uvs + finalTexOffset, dx, dy ).r@$	if ( newHeight > newZ )$	{$		currTexOffset = finalTexOffset@$		currHeight = newHeight@$		currRayZ = newZ@$		deltaTex = intersection * deltaTex@$		layerHeight = intersection * layerHeight@$	}$	else$	{$		prevTexOffset = finalTexOffset@$		prevHeight = newHeight@$		prevRayZ = newZ@$		deltaTex = ( 1 - intersection ) * deltaTex@$		layerHeight = ( 1 - intersection ) * layerHeight@$	}$	sectionIndex++@$}$return uvs + finalTexOffset@;2;False;7;True;normalWorld;FLOAT3;0,0,0;In;True;heightMap;SAMPLER2D;0.0;In;True;uvs;FLOAT2;0,0;In;True;viewWorld;FLOAT3;0,0,0;In;True;viewDirTan;FLOAT3;0,0,0;In;True;parallax;FLOAT;0.0;In;True;refPlane;FLOAT;0.0;In;Parallax Occlusion Custom;7;0;FLOAT3;0,0,0;False;1;SAMPLER2D;0.0;False;2;FLOAT2;0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;0.0;False;6;FLOAT;0.0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;88;-2802.844,-666.1702;Float;False;Constant;_Vector0;Vector 0;13;0;Create;-0.5,-0.5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SmoothstepOpNode;464;-2728.943,-277.3018;Float;False;3;0;FLOAT;0.0;False;1;FLOAT;0.0;False;2;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;327;-3401.539,-827.7945;Float;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-2960.897,-396.3082;Float;False;Property;_MaxPupilDialation;MaxPupilDialation;14;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;140;-2558.902,-436.6277;Float;False;Constant;_Float15;Float 15;13;0;Create;-0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;154;-2543.747,-349.4044;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;87;-2596.882,-729.5692;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;353;-1530.35,-1551.237;Float;False;1532.296;565.0349;;14;298;289;299;297;303;359;360;325;316;357;355;326;358;323;FakeReflection;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;316;-1498.448,-1260.858;Float;False;214;0;1;FLOAT3;0
Node;AmplifyShaderEditor.LengthOpNode;90;-2392.419,-682.6799;Float;False;1;0;FLOAT2;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-2400.938,-606.2742;Float;False;Constant;_Float8;Float 8;13;0;Create;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;139;-2393.305,-404.2293;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;141;-2525.077,-530.9951;Float;False;Property;_IrisSize;IrisSize;10;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;91;-2070.918,-698.3043;Float;False;5;0;FLOAT;0.0;False;1;FLOAT;0.0;False;2;FLOAT;1.0;False;3;FLOAT;0.0;False;4;FLOAT;1.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;381;-959.3082,-343.7378;Float;False;874.4001;215.2001;;7;166;259;276;165;255;222;256;Kill Specular At Rim;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldToCameraMatrix;358;-1324.368,-1486.35;Float;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.WorldNormalVector;326;-1297.737,-1256.019;Float;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;323;-1285.958,-1410.062;Float;False;World;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;146;-1882.288,-352.4556;Float;False;Constant;_Float12;Float 12;15;0;Create;-10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;89;-2390.784,-766.0192;Float;False;1;0;FLOAT2;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;144;-1871.257,-449.8925;Float;False;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;165;-947.8755,-298.7689;Float;False;World;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;99;-1893.28,-697.5408;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;357;-1042.767,-1276.55;Float;False;2;2;0;FLOAT4x4;0,0,0;False;1;FLOAT3;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;355;-1040.67,-1381.25;Float;False;2;2;0;FLOAT4x4;0.0,0,0;False;1;FLOAT3;0.0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;259;-722.0087,-294.2001;Float;False;1;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector2Node;98;-1785.21,-609.7913;Float;False;Constant;_Vector1;Vector 1;13;0;Create;0.5,0.5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;145;-1724.184,-442.5388;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;360;-870.9727,-1496.949;Float;False;Constant;_Vector3;Vector 3;12;0;Create;-1,-1,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;-1739.143,-760.6382;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ReflectOpNode;325;-863.5193,-1340.326;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;276;-770.767,-212.8734;Float;False;264;0;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;359;-657.8707,-1411.749;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;147;-1584.462,-444.3773;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;166;-534.775,-271.7393;Float;False;2;0;FLOAT3;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;97;-1555.159,-660.9929;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.IntNode;303;-656.0817,-1291.22;Float;False;Constant;_Int0;Int 0;16;0;Create;0;0;1;INT;0
Node;AmplifyShaderEditor.SaturateNode;222;-394.9583,-302.4584;Float;False;1;0;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;297;-354.1881,-1205.871;Float;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;289;-491.6861,-1400.385;Float;True;Property;_StylizedReflection;StylizedReflection;4;0;Create;None;True;0;False;black;LockedToCube;False;Object;-1;MipLevel;Cube;6;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0.0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1.0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;299;-349.1009,-1079.575;Float;False;Constant;_Float4;Float 4;16;0;Create;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;256;-393.0351,-230.3413;Float;False;Constant;_Float3;Float 3;15;0;Create;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;142;-1312.043,-835.3046;Float;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;33;-244.388,-521.6429;Float;False;Property;_EmissionMapPower;EmissionPower;8;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;298;-140.6895,-1226.712;Float;False;3;3;0;FLOAT;0,0,0,0;False;1;COLOR;0;False;2;FLOAT;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;255;-233.8377,-281.4425;Float;False;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;7;-1104.979,93.55486;Float;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-266.4699,-918.2617;Float;True;Property;_MainTex;Albedo;0;0;Create;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;164;-336.0393,-425.6275;Float;False;Property;_Specular;Specular;6;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;31;-264.3959,-718.8957;Float;True;Property;_EmissionMap;Emission;2;0;Create;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;498;-4692.834,-141.1104;Float;False;545.1133;362.3372;;5;495;492;497;493;494;Color Debug;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;492;-4428.864,73.36301;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-699.8911,152.6463;Float;False;2;2;0;FLOAT4x4;0.0;False;1;FLOAT3;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;497;-4647.786,131.3064;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;129.025,-631.8177;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;495;-4453.405,-71.96432;Float;False;Constant;_Float28;Float 28;19;0;Create;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;288;221.5335,-1034.974;Float;False;2;2;0;COLOR;0.0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;286;96.93012,-722.2957;Float;False;214;0;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;493;-4663.215,-58.33155;Float;False;Constant;_Vector10;Vector 10;19;0;Create;1,1,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;494;-4287.345,37.09644;Float;False;2;2;0;FLOAT;0,0,0;False;1;FLOAT3;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-26.08187,-387.9476;Float;False;2;2;0;FLOAT;0.0;False;1;FLOAT;0.0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;30;-252.8009,-104.7871;Float;False;Property;_Glossiness;Smooth;7;0;Create;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;951.1072,-517.2842;Float;False;True;2;Float;ASEMaterialInspector;0;0;StandardSpecular;Vilar/EyeTrack;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;0;False;0;0;Opaque;0.5;True;True;0;False;Opaque;Geometry;All;True;True;True;True;True;False;False;False;False;False;False;False;False;True;True;True;True;False;0;255;255;0;0;0;0;0;0;0;0;False;2;15;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;OFF;OFF;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Absolute;0;;-1;-1;-1;-1;0;0;0;False;0;0;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;FLOAT;0.0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;515;0;512;0
WireConnection;511;0;473;0
WireConnection;511;1;472;0
WireConnection;511;2;515;0
WireConnection;478;0;511;0
WireConnection;380;0;376;0
WireConnection;380;1;379;1
WireConnection;378;0;380;0
WireConnection;378;1;377;0
WireConnection;378;2;377;0
WireConnection;435;0;480;0
WireConnection;509;0;508;0
WireConnection;509;1;510;0
WireConnection;509;3;435;0
WireConnection;542;0;541;0
WireConnection;542;1;540;0
WireConnection;542;3;378;0
WireConnection;398;0;444;0
WireConnection;487;0;480;0
WireConnection;543;0;542;0
WireConnection;543;1;378;0
WireConnection;543;2;487;1
WireConnection;427;0;398;0
WireConnection;427;1;428;0
WireConnection;518;0;509;0
WireConnection;518;1;435;0
WireConnection;518;2;487;1
WireConnection;461;0;446;0
WireConnection;461;1;457;0
WireConnection;528;0;527;0
WireConnection;410;0;398;0
WireConnection;375;0;518;0
WireConnection;375;1;543;0
WireConnection;460;0;462;0
WireConnection;460;1;461;0
WireConnection;418;0;427;0
WireConnection;534;0;528;0
WireConnection;364;0;375;0
WireConnection;437;0;398;0
WireConnection;437;1;441;0
WireConnection;445;0;460;0
WireConnection;458;0;457;0
WireConnection;458;1;459;0
WireConnection;530;0;504;0
WireConnection;530;1;529;0
WireConnection;530;2;535;0
WireConnection;419;0;418;0
WireConnection;419;1;417;0
WireConnection;408;0;410;0
WireConnection;408;1;409;0
WireConnection;426;0;419;0
WireConnection;389;0;410;0
WireConnection;425;0;418;0
WireConnection;447;0;445;0
WireConnection;456;0;458;0
WireConnection;433;0;437;0
WireConnection;433;1;434;0
WireConnection;403;0;408;0
WireConnection;362;0;364;0
WireConnection;362;1;530;0
WireConnection;396;0;397;0
WireConnection;396;1;389;0
WireConnection;423;0;420;0
WireConnection;423;1;426;0
WireConnection;455;0;447;0
WireConnection;455;1;456;0
WireConnection;422;0;420;0
WireConnection;422;1;425;0
WireConnection;404;0;397;0
WireConnection;404;1;403;0
WireConnection;366;0;362;0
WireConnection;366;1;367;0
WireConnection;436;0;433;0
WireConnection;451;0;455;0
WireConnection;451;1;450;0
WireConnection;443;0;436;0
WireConnection;395;0;396;0
WireConnection;395;1;404;0
WireConnection;395;2;406;0
WireConnection;424;0;422;0
WireConnection;424;1;423;0
WireConnection;424;2;421;0
WireConnection;368;0;369;0
WireConnection;368;1;366;0
WireConnection;429;0;395;0
WireConnection;429;1;424;0
WireConnection;429;2;443;0
WireConnection;452;0;451;0
WireConnection;370;0;368;0
WireConnection;453;0;429;0
WireConnection;453;1;454;0
WireConnection;453;2;452;0
WireConnection;373;0;374;0
WireConnection;373;1;370;0
WireConnection;384;0;375;0
WireConnection;385;0;386;0
WireConnection;385;1;383;0
WireConnection;385;2;376;0
WireConnection;385;3;388;0
WireConnection;411;0;412;0
WireConnection;411;1;453;0
WireConnection;371;0;530;0
WireConnection;371;1;384;0
WireConnection;371;2;373;0
WireConnection;382;0;385;0
WireConnection;382;1;371;0
WireConnection;382;2;411;0
WireConnection;531;0;532;0
WireConnection;531;1;382;0
WireConnection;533;0;382;0
WireConnection;533;1;531;0
WireConnection;533;2;536;0
WireConnection;1;0;533;0
WireConnection;1;1;519;0
WireConnection;524;0;523;0
WireConnection;524;1;1;0
WireConnection;537;0;515;0
WireConnection;521;0;524;0
WireConnection;521;1;525;0
WireConnection;526;0;521;0
WireConnection;526;1;1;0
WireConnection;526;2;538;0
WireConnection;250;0;8;0
WireConnection;252;0;225;0
WireConnection;251;0;223;0
WireConnection;22;1;27;0
WireConnection;226;0;526;0
WireConnection;226;1;252;0
WireConnection;224;0;526;0
WireConnection;224;1;251;0
WireConnection;10;0;526;0
WireConnection;10;1;250;0
WireConnection;214;0;22;0
WireConnection;227;0;224;0
WireConnection;227;1;226;0
WireConnection;227;2;10;0
WireConnection;238;0;230;0
WireConnection;238;1;227;0
WireConnection;231;0;238;0
WireConnection;261;0;260;0
WireConnection;261;1;231;0
WireConnection;469;0;470;0
WireConnection;469;1;468;0
WireConnection;263;0;261;0
WireConnection;264;0;263;0
WireConnection;467;0;469;0
WireConnection;463;0;467;0
WireConnection;277;0;278;0
WireConnection;277;1;149;0
WireConnection;277;2;27;0
WireConnection;277;3;279;0
WireConnection;277;4;280;0
WireConnection;277;5;29;0
WireConnection;277;6;150;0
WireConnection;464;0;463;0
WireConnection;464;1;465;0
WireConnection;464;2;466;0
WireConnection;327;0;277;0
WireConnection;154;0;94;0
WireConnection;154;1;464;0
WireConnection;87;0;327;0
WireConnection;87;1;88;0
WireConnection;90;0;87;0
WireConnection;139;0;140;0
WireConnection;139;1;154;0
WireConnection;91;0;90;0
WireConnection;91;1;92;0
WireConnection;91;2;141;0
WireConnection;91;3;139;0
WireConnection;91;4;141;0
WireConnection;326;0;316;0
WireConnection;89;0;87;0
WireConnection;144;0;90;0
WireConnection;144;1;141;0
WireConnection;99;0;91;0
WireConnection;357;0;358;0
WireConnection;357;1;326;0
WireConnection;355;0;358;0
WireConnection;355;1;323;0
WireConnection;259;0;165;0
WireConnection;145;0;144;0
WireConnection;145;1;146;0
WireConnection;96;0;89;0
WireConnection;96;1;99;0
WireConnection;325;0;355;0
WireConnection;325;1;357;0
WireConnection;359;0;360;0
WireConnection;359;1;325;0
WireConnection;147;0;145;0
WireConnection;166;0;259;0
WireConnection;166;1;276;0
WireConnection;97;0;96;0
WireConnection;97;1;98;0
WireConnection;222;0;166;0
WireConnection;289;1;359;0
WireConnection;289;2;303;0
WireConnection;142;0;327;0
WireConnection;142;1;97;0
WireConnection;142;2;147;0
WireConnection;298;0;289;1
WireConnection;298;1;297;0
WireConnection;298;2;299;0
WireConnection;255;0;222;0
WireConnection;255;1;256;0
WireConnection;2;1;142;0
WireConnection;31;1;142;0
WireConnection;492;0;493;0
WireConnection;492;1;497;0
WireConnection;9;0;526;0
WireConnection;9;1;7;0
WireConnection;497;0;375;0
WireConnection;32;0;31;0
WireConnection;32;1;33;0
WireConnection;288;0;298;0
WireConnection;288;1;2;0
WireConnection;494;0;495;0
WireConnection;494;1;492;0
WireConnection;168;0;164;0
WireConnection;168;1;255;0
WireConnection;0;0;288;0
WireConnection;0;1;286;0
WireConnection;0;2;32;0
WireConnection;0;3;168;0
WireConnection;0;4;30;0
WireConnection;0;11;9;0
WireConnection;0;12;10;0
ASEEND*/
//CHKSM=C69CD3D3AF2FC292BFB8B7C762480785348FC3FB