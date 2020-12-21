// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Vilar/EyeV2AutoTrack"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Albedo("Albedo", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_NormalPower("NormalPower", Range( 0 , 1)) = 1
		_Emission("Emission", 2D) = "black" {}
		_EmissionPower("EmissionPower", Range( 0 , 1)) = 0
		_Scelera("Scelera", Color) = (0.6470588,0.6185122,0.6185122,0)
		_ParallaxHeight("ParallaxHeight", 2D) = "white" {}
		_StylizedReflection("StylizedReflection", CUBE) = "black" {}
		_Blood("Blood", Color) = (0.4705882,0.3737024,0.3737024,0)
		_IrisRing("IrisRing", Color) = (1,0,0,1)
		_Specular("Specular", Range( 0 , 1)) = 0
		_Smooth("Smooth", Range( 0 , 1)) = 0
		_LensBumpPower("LensBumpPower", Range( 0 , 1)) = 0
		_Depth("Depth", Range( 0 , 1)) = 0.5236971
		_FollowLimit("FollowLimit", Range( -1 , 1)) = 0
		_FollowPower("FollowPower", Range( 0 , 1)) = 0
		_IrisBlend("IrisBlend", Range( 0 , 0.3)) = 0
		_CrossEye("CrossEye", Range( -1 , 1)) = 0
		_IrisSize("IrisSize", Range( 0 , 1)) = 0
		_PupilDialationMagnitude("PupilDialationMagnitude", Range( 0 , 1)) = 1
		_PupilDialationFrequency("PupilDialationFrequency", Range( 0 , 1)) = 0
		_TwitchMagnitude("TwitchMagnitude", Range( 0 , 1)) = 0.1
		_TwitchShiftyness("TwitchShiftyness", Range( 0 , 1)) = 0
		_Backward("Backward", Range( 0 , 1)) = 0
		_MayaModel("MayaModel", Range( 0 , 1)) = 0
		_EyeOffset("EyeOffset", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.5
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float3 vertexToFrag560;
			float3 viewDir;
		};

		uniform sampler2D _MainTex;
		uniform float _CrossEye;
		uniform float _EyeOffset;
		uniform float _Backward;
		uniform float _MayaModel;
		uniform float _FollowPower;
		uniform float _FollowLimit;
		uniform float _TwitchMagnitude;
		uniform float _TwitchShiftyness;
		uniform sampler2D _Normal;
		uniform float _IrisSize;
		uniform float _NormalPower;
		uniform float _IrisBlend;
		uniform float _LensBumpPower;
		uniform samplerCUBE _StylizedReflection;
		uniform sampler2D _Albedo;
		uniform sampler2D _ParallaxHeight;
		uniform float _Depth;
		uniform float _PupilDialationFrequency;
		uniform float _PupilDialationMagnitude;
		uniform float4 _Scelera;
		uniform float4 _Blood;
		uniform float4 _IrisRing;
		uniform sampler2D _Emission;
		uniform float _EmissionPower;
		uniform float _Specular;
		uniform float _Smooth;


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


		float4x4 GenerateLookMatrix1( float3 target, float3 up )
		{
			float3 zaxis = normalize(target.xyz);
			float3 xaxis = normalize(cross(up, zaxis));
			float3 yaxis = cross(zaxis, xaxis);
			float4x4 lookMatrix = float4x4(xaxis.x, yaxis.x, zaxis.x, 0,xaxis.y, yaxis.y, zaxis.y, 0, xaxis.z, yaxis.z, zaxis.z, 0, 0, 0, 0, 1);
			return lookMatrix;
		}


		float2 ParallaxOcclusionDialated600( float3 normalWorld, sampler2D heightMap, float2 uvs, float3 viewWorld, float3 viewDirTan, float parallax, float refPlane, float currentDialation, float irisSize )
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
			float2 dialatedUV = 0;
			float dialatedCenterDist = 0;
			while ( stepIndex < numSteps + 1 )
			{
				dialatedUV = uvs + currTexOffset - float2(0.5,0.5);
				dialatedCenterDist = length(dialatedUV);
				dialatedCenterDist = max(0, currentDialation + dialatedCenterDist * (irisSize - currentDialation) / irisSize);
				dialatedUV = normalize(dialatedUV) * dialatedCenterDist;
				dialatedUV +=  float2(0.5,0.5);
				currHeight = tex2Dgrad( heightMap, dialatedUV, dx, dy ).r;
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
				dialatedUV = uvs + finalTexOffset - float2(0.5,0.5);
				dialatedCenterDist = length(dialatedUV);
				dialatedCenterDist = max(0, currentDialation + dialatedCenterDist * (irisSize - currentDialation) / irisSize);
				dialatedUV = normalize(dialatedUV) * dialatedCenterDist;
				dialatedUV +=  float2(0.5,0.5);
				newZ = prevRayZ - intersection * layerHeight;
				newHeight = tex2Dgrad( heightMap, dialatedUV, dx, dy ).r;
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
			return dialatedUV;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float temp_output_528_0 = round( _Backward );
			float3 lerpResult530 = lerp( float3(0,0,1) , float3(0,0,-1) , temp_output_528_0);
			float temp_output_515_0 = round( _MayaModel );
			float3 lerpResult511 = lerp( float3(0,0,1) , float3(0,1,0) , temp_output_515_0);
			float3 up435 = lerpResult511;
			float3 localGetLocalCameraPosition435 = GetLocalCameraPosition435( up435 );
			float3 rotatedValue509 = RotateAroundAxis( float3( 0,0,0 ), localGetLocalCameraPosition435, float3(1,0,0), -1.57 );
			float3 lerpResult518 = lerp( rotatedValue509 , localGetLocalCameraPosition435 , lerpResult511.y);
			float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
			float3 appendResult378 = (float3(( _EyeOffset / ase_objectScale.x ) , 0.0 , 0.0));
			float3 rotatedValue542 = RotateAroundAxis( float3( 0,0,0 ), appendResult378, float3(1,0,0), -1.57 );
			float3 lerpResult543 = lerp( rotatedValue542 , appendResult378 , lerpResult511.y);
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
			float3 lerpResult533 = lerp( temp_output_382_0 , ( temp_output_382_0 * float3(-1,-1,-1) ) , temp_output_528_0);
			float3 target1 = lerpResult533;
			float3 up1 = float3(0,1,0);
			float4x4 localGenerateLookMatrix1 = GenerateLookMatrix1( target1 , up1 );
			float4x4 lerpResult526 = lerp( mul( mul( float4x4(1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1), localGenerateLookMatrix1 ), float4x4(1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1) ) , localGenerateLookMatrix1 , temp_output_515_0);
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 temp_output_9_0 = mul( lerpResult526, float4( ase_vertex3Pos , 0.0 ) ).xyz;
			v.vertex.xyz = temp_output_9_0;
			v.vertex.w = 1;
			float3 ase_vertexNormal = v.normal.xyz;
			float3 normalizeResult250 = normalize( ase_vertexNormal );
			float3 temp_output_10_0 = mul( lerpResult526, float4( normalizeResult250 , 0.0 ) ).xyz;
			v.normal = temp_output_10_0;
			v.tangent = mul( lerpResult526, v.tangent );
			o.vertexToFrag560 = temp_output_10_0;
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			float3 _Vector0 = float3(0,0,1);
			float2 temp_output_612_0 = ( ( frac( i.uv_texcoord ) + float2( 0,0 ) ) + float2( -0.5,-0.5 ) );
			float2 temp_output_613_0 = ( temp_output_612_0 * ( 1.0 / _IrisSize ) );
			float2 temp_output_615_0 = saturate( ( temp_output_613_0 + float2( 0.5,0.5 ) ) );
			float smoothstepResult620 = smoothstep( ( 0.45 - _IrisBlend ) , 0.45 , length( temp_output_613_0 ));
			float3 lerpResult631 = lerp( UnpackScaleNormal( tex2D( _Normal, temp_output_615_0 ), _NormalPower ) , _Vector0 , smoothstepResult620);
			float3 lerpResult622 = lerp( _Vector0 , lerpResult631 , _LensBumpPower);
			o.Normal = lerpResult622;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float3 normalWorld600 = i.vertexToFrag560;
			sampler2D heightMap600 = _ParallaxHeight;
			float2 uvs600 = temp_output_615_0;
			float3 viewWorld600 = ase_worldViewDir;
			float3 viewDirTan600 = i.viewDir;
			float parallax600 = _Depth;
			float refPlane600 = 0.0;
			float mulTime578 = _Time.y * ( 0.3 * _PupilDialationFrequency );
			float2 temp_cast_5 = (mulTime578).xx;
			float simplePerlin2D580 = snoise( temp_cast_5 );
			float temp_output_602_0 = (0.0 + (simplePerlin2D580 - -1.0) * (1.0 - 0.0) / (1.0 - -1.0));
			float smoothstepResult605 = smoothstep( 0.5 , ( 0.5 + 0.02 ) , distance( temp_output_615_0 , float2( 0.5,0.5 ) ));
			float lerpResult603 = lerp( ( -0.5 * ( 0.5 * temp_output_602_0 ) ) , 0.0 , smoothstepResult605);
			float currentDialation600 = ( lerpResult603 * _PupilDialationMagnitude );
			float irisSize600 = 0.5;
			float2 localParallaxOcclusionDialated600 = ParallaxOcclusionDialated600( normalWorld600 , heightMap600 , uvs600 , viewWorld600 , viewDirTan600 , parallax600 , refPlane600 , currentDialation600 , irisSize600 );
			float smoothstepResult629 = smoothstep( 0.0 , 0.5 , length( temp_output_612_0 ));
			float4 lerpResult636 = lerp( _Scelera , _Blood , smoothstepResult629);
			float4 lerpResult638 = lerp( tex2D( _Albedo, localParallaxOcclusionDialated600 ) , lerpResult636 , smoothstepResult620);
			float4 lerpResult639 = lerp( lerpResult638 , _IrisRing , ( ( ( -cos( ( smoothstepResult620 * 6.283 ) ) + 1.0 ) * 0.5 ) * _IrisRing.a ));
			o.Albedo = ( ( texCUBElod( _StylizedReflection, float4( ( float3(-1,-1,1) * reflect( mul( unity_WorldToCamera, float4( ase_worldViewDir , 0.0 ) ).xyz , mul( unity_WorldToCamera, float4( (WorldNormalVector( i , lerpResult622 )) , 0.0 ) ).xyz ) ), (float)0) ).r * ase_lightColor * 1.5 ) + lerpResult639 ).rgb;
			float4 color641 = IsGammaSpace() ? float4(0,0,0,0) : float4(0,0,0,0);
			float4 lerpResult640 = lerp( ( tex2D( _Emission, localParallaxOcclusionDialated600 ) * _EmissionPower ) , color641 , smoothstepResult620);
			o.Emission = lerpResult640.rgb;
			float3 temp_cast_8 = (_Specular).xxx;
			o.Specular = temp_cast_8;
			o.Smoothness = _Smooth;
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
			#pragma target 3.5
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 customPack2 : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack2.xyz = customInputData.vertexToFrag560;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.vertexToFrag560 = IN.customPack2.xyz;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
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
Version=18707
123;39;1211;978;1861.945;1635.866;1.818082;True;False
Node;AmplifyShaderEditor.CommentaryNode;565;-6437.792,-186.5789;Inherit;False;5835.063;3289.539;Comment;57;363;376;379;380;377;378;540;541;508;510;509;542;543;375;374;373;384;388;383;386;371;385;532;382;531;533;519;1;523;524;525;521;512;473;472;515;511;527;528;487;435;518;526;223;8;251;250;10;224;561;560;7;9;563;252;225;226;VERT;0.8620691,0,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;512;-6401.991,193.194;Float;False;Property;_MayaModel;MayaModel;25;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;379;-6335.261,1924.793;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RoundOpNode;515;-6122.004,196.293;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;376;-6318.048,1843.48;Float;False;Property;_EyeOffset;EyeOffset;26;0;Create;True;0;0;False;0;False;0;-0.4085;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;472;-6166.64,46.44303;Float;False;Constant;_Vector7;Vector 7;18;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;473;-6166.606,-100.2929;Float;False;Constant;_Vector8;Vector 8;18;0;Create;True;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;380;-6145.296,1884.938;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;377;-6162.676,1991.52;Float;False;Constant;_Float7;Float 7;14;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;511;-5947.408,26.14604;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;496;-6456.72,3468.663;Inherit;False;2829.95;1395.959;;49;411;412;445;447;453;454;452;429;424;395;443;451;406;436;404;450;422;455;423;421;396;403;433;456;425;420;397;389;426;408;419;434;458;437;417;459;441;418;409;460;410;461;427;462;398;428;457;446;444;Twitch Noise;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector3Node;508;-5485.076,2067.927;Float;False;Constant;_Vector4;Vector 4;19;0;Create;True;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;435;-5536.605,1815.654;Float;False;float3 centerEye = _WorldSpaceCameraPos.xyz@ $#if UNITY_SINGLE_PASS_STEREO $int startIndex = unity_StereoEyeIndex@ $unity_StereoEyeIndex = 0@ $float3 leftEye = _WorldSpaceCameraPos@ $unity_StereoEyeIndex = 1@ $float3 rightEye = _WorldSpaceCameraPos@$unity_StereoEyeIndex = startIndex@$centerEye = lerp(leftEye, rightEye, 0.5)@$#endif $float3 cam = mul(unity_WorldToObject, float4(centerEye, 1)).xyz@$return cam@;3;False;1;True;up;FLOAT3;0,0,0;In;;Float;False;Get Local Camera Position;True;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;444;-6406.22,3962.78;Float;False;Constant;_Float20;Float 20;17;0;Create;True;0;0;False;0;False;0.8;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;378;-6011.355,1898.446;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;540;-6120.639,2249.533;Float;False;Constant;_Float1;Float 1;19;0;Create;True;0;0;False;0;False;-1.57;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;541;-6122.27,2101.346;Float;False;Constant;_Vector5;Vector 5;19;0;Create;True;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;510;-5483.445,2216.114;Float;False;Constant;_Float0;Float 0;19;0;Create;True;0;0;False;0;False;-1.57;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;457;-5896.167,4661.477;Float;False;Property;_TwitchShiftyness;TwitchShiftyness;23;0;Create;True;0;0;False;0;False;0;0.188;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;446;-5763.891,4564.422;Float;False;Constant;_Float21;Float 21;17;0;Create;True;0;0;False;0;False;0.3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;428;-5823.373,4026.011;Float;False;Constant;_Float17;Float 17;17;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;398;-6206.17,3968.169;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;509;-5185.038,1963.614;Inherit;False;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;487;-5545.176,1694.685;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RotateAboutAxisNode;542;-5821.63,2019.634;Inherit;False;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;461;-5568.403,4606.824;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;462;-5582.403,4524.821;Float;False;Constant;_Float24;Float 24;17;0;Create;True;0;0;False;0;False;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;518;-4775.647,1710.373;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;543;-5121.576,1837.481;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;363;-4500.404,2133.46;Inherit;False;997.3206;499.8208;;10;367;530;504;529;370;368;369;366;362;364;In Front Threshold;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;427;-5669.371,3968.261;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;527;-6400.44,278.6499;Float;False;Property;_Backward;Backward;24;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;418;-5517.53,4075.921;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;417;-5572.436,4156.523;Float;False;Constant;_Float10;Float 10;16;0;Create;True;0;0;False;0;False;123.234;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;460;-5404.403,4556.821;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;529;-4482.34,2401.789;Float;False;Constant;_Vector13;Vector 13;19;0;Create;True;0;0;False;0;False;0,0,-1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RoundOpNode;528;-6120.454,281.7491;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;375;-4569.989,1867.854;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;459;-5307.403,4742.825;Float;False;Constant;_Float22;Float 22;18;0;Create;True;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;441;-5741.75,4331.901;Float;False;Constant;_Float18;Float 18;17;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;504;-4481.07,2259.042;Float;False;Constant;_Vector11;Vector 11;19;0;Create;True;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;409;-5568.561,3782.066;Float;False;Constant;_Float14;Float 14;16;0;Create;True;0;0;False;0;False;123.234;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;410;-5513.655,3701.464;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;530;-4263.178,2343.886;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;434;-5574.284,4398.825;Float;False;Constant;_Float19;Float 19;17;0;Create;True;0;0;False;0;False;14;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FmodOpNode;437;-5553.244,4294.202;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;408;-5348.811,3742.876;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;364;-4259.648,2190.58;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;445;-5273.875,4561.38;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;419;-5352.685,4117.333;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;458;-5154.28,4663.969;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;367;-4260.345,2474.928;Float;False;Property;_FollowLimit;FollowLimit;15;0;Create;True;0;0;False;0;False;0;0.4;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;403;-5195.46,3767.782;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;420;-5170.453,3915.566;Float;False;Constant;_Float11;Float 11;16;0;Create;True;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;447;-5091.491,4555.753;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;362;-4085.968,2218.039;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;433;-5419.276,4340.722;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;389;-5203.429,3622.029;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;426;-5199.334,4142.24;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;397;-5166.579,3541.109;Float;False;Constant;_Float9;Float 9;16;0;Create;True;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;425;-5207.303,3996.486;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;456;-5025.167,4659.477;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;422;-4945.665,3932.274;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;396;-4941.791,3557.817;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;436;-5269.781,4339.128;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;421;-4960.856,4181.37;Float;False;Constant;_Float16;Float 16;16;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;423;-4942.496,4076.428;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;406;-4956.983,3806.912;Float;False;Constant;_Float5;Float 5;16;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;366;-3929.075,2286.557;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;450;-4894.656,4720.354;Float;False;Constant;_Float23;Float 23;17;0;Create;True;0;0;False;0;False;14;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;369;-3939.337,2206.149;Float;False;Constant;_Float6;Float 6;13;0;Create;True;0;0;False;0;False;10;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;404;-4938.622,3701.97;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;455;-4878.896,4617.063;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;443;-4680.132,4262.387;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;368;-3782.945,2236.943;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;451;-4739.645,4662.251;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;395;-4774.715,3635.279;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;424;-4778.589,4009.736;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;454;-4411.77,4192.039;Float;False;Constant;_Vector6;Vector 6;12;0;Create;True;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;429;-4410.247,3776.024;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;452;-4590.15,4660.659;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;608;-2638.85,-2818.432;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;374;-3602.498,1951.021;Float;False;Property;_FollowPower;FollowPower;16;0;Create;True;0;0;False;0;False;0;0.852;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;370;-3647.788,2238.654;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;388;-3450.482,1713.633;Float;False;Constant;_10;10;16;0;Create;True;0;0;False;0;False;20;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;453;-4142.48,4173.462;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;412;-4144.348,4060.303;Float;False;Property;_TwitchMagnitude;TwitchMagnitude;22;0;Create;True;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;383;-3572.427,1636.838;Float;False;Property;_CrossEye;CrossEye;18;0;Create;True;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;645;-2398.013,-2814.75;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector3Node;386;-3469.482,1487.276;Float;False;Constant;_Vector2;Vector 2;12;0;Create;True;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;373;-3324.993,1963.281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;384;-3356.021,1855.479;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;610;-2520.24,-3043.062;Float;False;Property;_IrisSize;IrisSize;19;0;Create;True;0;0;False;0;False;0;0.557;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;609;-2228.237,-2813.432;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;411;-3816.471,4105.45;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;371;-3170.215,1878.552;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;385;-3229.45,1590.735;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;354;-2544.498,-1530.722;Inherit;False;2796.808;1067.613;Comment;26;606;603;574;572;573;605;582;577;576;604;602;580;578;575;581;468;600;277;149;279;29;280;150;632;647;650;ComputedUVs;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;611;-2159.229,-3058.354;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;612;-2072.76,-2836.414;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-0.5,-0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector3Node;532;-2962.386,1979.514;Float;False;Constant;_Vector14;Vector 14;20;0;Create;True;0;0;False;0;False;-1,-1,-1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;581;-2208.292,-1055.723;Float;False;Constant;_Float2;Float 2;18;0;Create;True;0;0;False;0;False;0.3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;468;-2493.207,-1004.077;Float;False;Property;_PupilDialationFrequency;PupilDialationFrequency;21;0;Create;True;0;0;False;0;False;0;0.352;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;382;-2957.928,1855.319;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;575;-2057.91,-1045.866;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;613;-1930.253,-2838.422;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;531;-2735.339,1931.008;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;519;-2529.265,2001.872;Float;False;Constant;_Vector12;Vector 12;19;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;533;-2578.214,1872.812;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;616;-1992.333,-3325.173;Float;False;Property;_IrisBlend;IrisBlend;17;0;Create;True;0;0;False;0;False;0;0.082;0;0.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;578;-1921.257,-1045.023;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;614;-1771.681,-2838.419;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;1;-2333.842,1926.553;Float;False;float3 zaxis = normalize(target.xyz)@$float3 xaxis = normalize(cross(up, zaxis))@$float3 yaxis = cross(zaxis, xaxis)@$float4x4 lookMatrix = float4x4(xaxis.x, yaxis.x, zaxis.x, 0,xaxis.y, yaxis.y, zaxis.y, 0, xaxis.z, yaxis.z, zaxis.z, 0, 0, 0, 0, 1)@$return lookMatrix@$;6;False;2;True;target;FLOAT3;0,0,0;In;;Float;False;True;up;FLOAT3;0,0,0;In;;Float;False;GenerateLookMatrix;True;False;0;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.LengthOpNode;617;-1773.344,-3106.829;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Matrix4X4Node;523;-2415.351,1639.307;Float;False;Constant;_Matrix0;Matrix 0;19;0;Create;True;0;0;False;0;False;1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.RangedFloatNode;569;-892.2629,-1801.451;Inherit;False;Property;_NormalPower;NormalPower;3;0;Create;True;0;0;False;0;False;1;0.114;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;615;-1635.193,-2832.402;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;618;-1653.71,-3337.166;Inherit;False;2;0;FLOAT;0.45;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;580;-1758.939,-1049.501;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;602;-1519.687,-1121.872;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;632;-1410.119,-697.3104;Inherit;False;Constant;_Float12;Float 12;23;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;524;-2124.215,1720.58;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.Vector3Node;619;-1076.689,-3032.309;Inherit;False;Constant;_Vector0;Vector 0;14;0;Create;True;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SmoothstepOpNode;620;-1466.206,-3120.772;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.45;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;22;-574.3146,-1907.61;Inherit;True;Property;_Normal;Normal;2;0;Create;True;0;0;False;0;False;-1;None;adf80cd0b34441547b9dc95257a1cb4e;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Matrix4X4Node;525;-2413.641,1779.095;Float;False;Constant;_Matrix1;Matrix 1;19;0;Create;True;0;0;False;0;False;1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;521;-1970.807,1758.338;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.DistanceOpNode;604;-1116.284,-792.8164;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;631;-1068.167,-2594.408;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;621;-991.1981,-2714.829;Inherit;False;Property;_LensBumpPower;LensBumpPower;13;0;Create;True;0;0;False;0;False;0;0.489;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;577;-1139.127,-1128.67;Float;False;Constant;_Float8;Float 8;13;0;Create;True;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;606;-1112.975,-658.6573;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.02;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;8;-1671.154,1653.8;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;576;-1123.973,-1041.447;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;605;-944.2028,-789.9005;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;250;-1463.827,1660.459;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;624;-1367.342,-3562.909;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;6.283;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;526;-1739.747,2036.38;Inherit;False;3;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CommentaryNode;353;-145.9124,-2266.921;Inherit;False;1532.296;565.0349;;13;298;289;299;297;303;359;360;325;357;355;326;358;323;FakeReflection;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;622;-673.0771,-2852.27;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;582;-973.5299,-1096.272;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;323;98.47964,-2125.746;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;603;-734.1035,-1009.291;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;625;-1205.342,-3562.909;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;647;-960.0709,-580.6;Float;False;Property;_PupilDialationMagnitude;PupilDialationMagnitude;20;0;Create;True;0;0;False;0;False;1;0.352;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldToCameraMatrix;358;60.06961,-2202.033;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.WorldNormalVector;326;86.70059,-1971.703;Inherit;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;-1270.513,1689.047;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LengthOpNode;627;-1773.001,-3200.035;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;650;-569.29,-890.452;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;279;-423.4268,-829.7342;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;150;-398.6554,-998.3173;Float;False;Constant;_Float13;Float 13;16;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-520.7863,-1090.895;Float;False;Property;_Depth;Depth;14;0;Create;True;0;0;False;0;False;0.5236971;0.187;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;149;-474.9874,-1290.944;Float;True;Property;_ParallaxHeight;ParallaxHeight;7;0;Create;True;0;0;False;0;False;None;0fe5a352f0aad6649bbef0a46c653588;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;280;-438.2218,-677.6832;Float;False;Tangent;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NegateNode;626;-1038.667,-3564.133;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;355;343.7676,-2096.934;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexToFragmentNode;560;-1060.343,1703.486;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;357;341.6707,-1992.234;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;628;-868.0929,-3567.235;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;600;-56.60433,-922.2889;Float;False;float2 dx = ddx(uvs)@$float2 dy = ddy(uvs)@$float minSamples = 8@$float maxSamples = 16@$float3 result = 0@$int stepIndex = 0@$int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, (float)dot( normalWorld, viewWorld ) )@$float layerHeight = 1.0 / numSteps@$float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z )@$uvs += refPlane * plane@$float2 deltaTex = -plane * layerHeight@$float2 prevTexOffset = 0@$float prevRayZ = 1.0f@$float prevHeight = 0.0f@$float2 currTexOffset = deltaTex@$float currRayZ = 1.0f - layerHeight@$float currHeight = 0.0f@$float intersection = 0@$float2 finalTexOffset = 0@$float2 dialatedUV = 0@$float dialatedCenterDist = 0@$while ( stepIndex < numSteps + 1 )${$	dialatedUV = uvs + currTexOffset - float2(0.5,0.5)@$	dialatedCenterDist = length(dialatedUV)@$	dialatedCenterDist = max(0, currentDialation + dialatedCenterDist * (irisSize - currentDialation) / irisSize)@$	dialatedUV = normalize(dialatedUV) * dialatedCenterDist@$	dialatedUV +=  float2(0.5,0.5)@$	currHeight = tex2Dgrad( heightMap, dialatedUV, dx, dy ).r@$	if ( currHeight > currRayZ )$	{$		stepIndex = numSteps + 1@$	}$	else$	{$		stepIndex++@$		prevTexOffset = currTexOffset@$		prevRayZ = currRayZ@$		prevHeight = currHeight@$		currTexOffset += deltaTex@$		currRayZ -= layerHeight@$	}$}$int sectionSteps = 2@$int sectionIndex = 0@$float newZ = 0@$float newHeight = 0@$while ( sectionIndex < sectionSteps )${$	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ )@$	finalTexOffset = prevTexOffset + intersection * deltaTex@$	dialatedUV = uvs + finalTexOffset - float2(0.5,0.5)@$	dialatedCenterDist = length(dialatedUV)@$	dialatedCenterDist = max(0, currentDialation + dialatedCenterDist * (irisSize - currentDialation) / irisSize)@$	dialatedUV = normalize(dialatedUV) * dialatedCenterDist@$	dialatedUV +=  float2(0.5,0.5)@$	newZ = prevRayZ - intersection * layerHeight@$	newHeight = tex2Dgrad( heightMap, dialatedUV, dx, dy ).r@$	if ( newHeight > newZ )$	{$		currTexOffset = finalTexOffset@$		currHeight = newHeight@$		currRayZ = newZ@$		deltaTex = intersection * deltaTex@$		layerHeight = intersection * layerHeight@$	}$	else$	{$		prevTexOffset = finalTexOffset@$		prevHeight = newHeight@$		prevRayZ = newZ@$		deltaTex = ( 1 - intersection ) * deltaTex@$		layerHeight = ( 1 - intersection ) * layerHeight@$	}$	sectionIndex++@$}$return dialatedUV@;2;False;9;True;normalWorld;FLOAT3;0,0,0;In;;Float;False;True;heightMap;SAMPLER2D;0.0;In;;Float;False;True;uvs;FLOAT2;0,0;In;;Float;False;True;viewWorld;FLOAT3;0,0,0;In;;Float;False;True;viewDirTan;FLOAT3;0,0,0;In;;Float;False;True;parallax;FLOAT;0;In;;Float;False;True;refPlane;FLOAT;0;In;;Float;False;True;currentDialation;FLOAT;0;In;;Float;False;True;irisSize;FLOAT;0;In;;Float;False;Parallax Occlusion Dialated;True;False;0;9;0;FLOAT3;0,0,0;False;1;SAMPLER2D;0.0;False;2;FLOAT2;0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;634;1007.668,-2574.487;Inherit;False;Property;_Blood;Blood;9;0;Create;True;0;0;False;0;False;0.4705882,0.3737024,0.3737024,0;0.02205884,0.02189665,0.02189665,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;360;513.4648,-2212.633;Float;False;Constant;_Vector3;Vector 3;12;0;Create;True;0;0;False;0;False;-1,-1,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ReflectOpNode;325;520.9183,-2056.01;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;629;-1027.793,-3257.354;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;633;981.9465,-2754.731;Inherit;False;Property;_Scelera;Scelera;6;0;Create;True;0;0;False;0;False;0.6470588,0.6185122,0.6185122,0;0.08088235,0.07850344,0.07850344,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;635;1025.234,-2989.386;Inherit;False;Property;_IrisRing;IrisRing;10;0;Create;True;0;0;False;0;False;1,0,0,1;0,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;636;1288.219,-2625.693;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;359;726.5669,-2127.433;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;630;-693.7766,-3563.811;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;303;728.3558,-2006.904;Float;False;Constant;_Int0;Int 0;16;0;Create;True;0;0;False;0;False;0;0;False;0;1;INT;0
Node;AmplifyShaderEditor.SamplerNode;2;1117.968,-1633.946;Inherit;True;Property;_Albedo;Albedo;1;0;Create;True;0;0;False;0;False;-1;None;fb74b5fe038f5ef488fdc90cfc2f0f83;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;638;1478.639,-2627.165;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightColorNode;297;1030.249,-1921.555;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;299;1035.337,-1795.259;Float;False;Constant;_Float4;Float 4;16;0;Create;True;0;0;False;0;False;1.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;1140.05,-1237.327;Float;False;Property;_EmissionPower;EmissionPower;5;0;Create;True;0;0;False;0;False;0;0.205;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;31;1120.042,-1434.58;Inherit;True;Property;_Emission;Emission;4;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;637;1375.69,-3131.718;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;289;892.7515,-2116.069;Inherit;True;Property;_StylizedReflection;StylizedReflection;8;0;Create;True;0;0;False;0;False;-1;None;504df9e52643429478e418b6a0562535;True;0;False;black;LockedToCube;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;1513.463,-1347.502;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;639;1675.353,-2958.159;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;7;-1673.408,1496.669;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;641;1267.917,-2461.537;Inherit;False;Constant;_Color0;Color 0;25;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;298;1243.748,-1942.396;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;572;-1487.169,-931.3439;Float;False;Constant;_Float3;Float 3;18;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;226;-1271.926,2201.684;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexToFragmentNode;561;-1065.484,1839.763;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;642;1463.143,-1625.872;Inherit;True;Property;_MainTex;MainTex;0;0;Create;True;0;0;True;0;False;-1;None;fb74b5fe038f5ef488fdc90cfc2f0f83;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;640;1806.534,-2394.729;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;251;-1454.897,1856.655;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-1278.621,1861.244;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;277;-53.15267,-1294.319;Float;False;float2 dx = ddx(uvs)@$float2 dy = ddy(uvs)@$float minSamples = 8@$float maxSamples = 16@$float3 result = 0@$int stepIndex = 0@$int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, (float)dot( normalWorld, viewWorld ) )@$float layerHeight = 1.0 / numSteps@$float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z )@$uvs += refPlane * plane@$float2 deltaTex = -plane * layerHeight@$float2 prevTexOffset = 0@$float prevRayZ = 1.0f@$float prevHeight = 0.0f@$float2 currTexOffset = deltaTex@$float currRayZ = 1.0f - layerHeight@$float currHeight = 0.0f@$float intersection = 0@$float2 finalTexOffset = 0@$while ( stepIndex < numSteps + 1 )${$	currHeight = tex2Dgrad( heightMap, uvs + currTexOffset, dx, dy ).r@$	if ( currHeight > currRayZ )$	{$		stepIndex = numSteps + 1@$	}$	else$	{$		stepIndex++@$		prevTexOffset = currTexOffset@$		prevRayZ = currRayZ@$		prevHeight = currHeight@$		currTexOffset += deltaTex@$		currRayZ -= layerHeight@$	}$}$int sectionSteps = 2@$int sectionIndex = 0@$float newZ = 0@$float newHeight = 0@$while ( sectionIndex < sectionSteps )${$	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ )@$	finalTexOffset = prevTexOffset + intersection * deltaTex@$	newZ = prevRayZ - intersection * layerHeight@$	newHeight = tex2Dgrad( heightMap, uvs + finalTexOffset, dx, dy ).r@$	if ( newHeight > newZ )$	{$		currTexOffset = finalTexOffset@$		currHeight = newHeight@$		currRayZ = newZ@$		deltaTex = intersection * deltaTex@$		layerHeight = intersection * layerHeight@$	}$	else$	{$		prevTexOffset = finalTexOffset@$		prevHeight = newHeight@$		prevRayZ = newZ@$		deltaTex = ( 1 - intersection ) * deltaTex@$		layerHeight = ( 1 - intersection ) * layerHeight@$	}$	sectionIndex++@$}$return uvs + finalTexOffset@;2;False;7;True;normalWorld;FLOAT3;0,0,0;In;;Float;False;True;heightMap;SAMPLER2D;0.0;In;;Float;False;True;uvs;FLOAT2;0,0;In;;Float;False;True;viewWorld;FLOAT3;0,0,0;In;;Float;False;True;viewDirTan;FLOAT3;0,0,0;In;;Float;False;True;parallax;FLOAT;0;In;;Float;False;True;refPlane;FLOAT;0;In;;Float;False;Parallax Occlusion Custom;True;False;0;7;0;FLOAT3;0,0,0;False;1;SAMPLER2D;0.0;False;2;FLOAT2;0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;0;False;6;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;573;-1488.169,-857.3438;Float;False;Constant;_Float26;Float 26;18;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BitangentVertexDataNode;225;-1679.228,2221.544;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SmoothstepOpNode;574;-1309.168,-969.3444;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;288;1901.244,-1839.711;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;164;1850.445,-1290.831;Float;False;Property;_Specular;Specular;11;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;563;-1050.246,1554.55;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-1268.32,1555.76;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;252;-1455.574,2257.505;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TangentVertexDataNode;223;-1672.454,1820.791;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;30;1849.877,-1211.456;Float;False;Property;_Smooth;Smooth;12;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2447.219,-1584.336;Float;False;True;-1;3;ASEMaterialInspector;0;0;StandardSpecular;Vilar/EyeV2AutoTrack;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;5;d3d9;d3d11;glcore;gles;gles3;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Absolute;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;515;0;512;0
WireConnection;380;0;376;0
WireConnection;380;1;379;1
WireConnection;511;0;473;0
WireConnection;511;1;472;0
WireConnection;511;2;515;0
WireConnection;435;0;511;0
WireConnection;378;0;380;0
WireConnection;378;1;377;0
WireConnection;378;2;377;0
WireConnection;398;0;444;0
WireConnection;509;0;508;0
WireConnection;509;1;510;0
WireConnection;509;3;435;0
WireConnection;487;0;511;0
WireConnection;542;0;541;0
WireConnection;542;1;540;0
WireConnection;542;3;378;0
WireConnection;461;0;446;0
WireConnection;461;1;457;0
WireConnection;518;0;509;0
WireConnection;518;1;435;0
WireConnection;518;2;487;1
WireConnection;543;0;542;0
WireConnection;543;1;378;0
WireConnection;543;2;487;1
WireConnection;427;0;398;0
WireConnection;427;1;428;0
WireConnection;418;0;427;0
WireConnection;460;0;462;0
WireConnection;460;1;461;0
WireConnection;528;0;527;0
WireConnection;375;0;518;0
WireConnection;375;1;543;0
WireConnection;410;0;398;0
WireConnection;530;0;504;0
WireConnection;530;1;529;0
WireConnection;530;2;528;0
WireConnection;437;0;398;0
WireConnection;437;1;441;0
WireConnection;408;0;410;0
WireConnection;408;1;409;0
WireConnection;364;0;375;0
WireConnection;445;0;460;0
WireConnection;419;0;418;0
WireConnection;419;1;417;0
WireConnection;458;0;457;0
WireConnection;458;1;459;0
WireConnection;403;0;408;0
WireConnection;447;0;445;0
WireConnection;362;0;364;0
WireConnection;362;1;530;0
WireConnection;433;0;437;0
WireConnection;433;1;434;0
WireConnection;389;0;410;0
WireConnection;426;0;419;0
WireConnection;425;0;418;0
WireConnection;456;0;458;0
WireConnection;422;0;420;0
WireConnection;422;1;425;0
WireConnection;396;0;397;0
WireConnection;396;1;389;0
WireConnection;436;0;433;0
WireConnection;423;0;420;0
WireConnection;423;1;426;0
WireConnection;366;0;362;0
WireConnection;366;1;367;0
WireConnection;404;0;397;0
WireConnection;404;1;403;0
WireConnection;455;0;447;0
WireConnection;455;1;456;0
WireConnection;443;0;436;0
WireConnection;368;0;369;0
WireConnection;368;1;366;0
WireConnection;451;0;455;0
WireConnection;451;1;450;0
WireConnection;395;0;396;0
WireConnection;395;1;404;0
WireConnection;395;2;406;0
WireConnection;424;0;422;0
WireConnection;424;1;423;0
WireConnection;424;2;421;0
WireConnection;429;0;395;0
WireConnection;429;1;424;0
WireConnection;429;2;443;0
WireConnection;452;0;451;0
WireConnection;370;0;368;0
WireConnection;453;0;429;0
WireConnection;453;1;454;0
WireConnection;453;2;452;0
WireConnection;645;0;608;0
WireConnection;373;0;374;0
WireConnection;373;1;370;0
WireConnection;384;0;375;0
WireConnection;609;0;645;0
WireConnection;411;0;412;0
WireConnection;411;1;453;0
WireConnection;371;0;530;0
WireConnection;371;1;384;0
WireConnection;371;2;373;0
WireConnection;385;0;386;0
WireConnection;385;1;383;0
WireConnection;385;2;376;0
WireConnection;385;3;388;0
WireConnection;611;1;610;0
WireConnection;612;0;609;0
WireConnection;382;0;385;0
WireConnection;382;1;371;0
WireConnection;382;2;411;0
WireConnection;575;0;581;0
WireConnection;575;1;468;0
WireConnection;613;0;612;0
WireConnection;613;1;611;0
WireConnection;531;0;382;0
WireConnection;531;1;532;0
WireConnection;533;0;382;0
WireConnection;533;1;531;0
WireConnection;533;2;528;0
WireConnection;578;0;575;0
WireConnection;614;0;613;0
WireConnection;1;0;533;0
WireConnection;1;1;519;0
WireConnection;617;0;613;0
WireConnection;615;0;614;0
WireConnection;618;1;616;0
WireConnection;580;0;578;0
WireConnection;602;0;580;0
WireConnection;524;0;523;0
WireConnection;524;1;1;0
WireConnection;620;0;617;0
WireConnection;620;1;618;0
WireConnection;22;1;615;0
WireConnection;22;5;569;0
WireConnection;521;0;524;0
WireConnection;521;1;525;0
WireConnection;604;0;615;0
WireConnection;631;0;22;0
WireConnection;631;1;619;0
WireConnection;631;2;620;0
WireConnection;606;0;632;0
WireConnection;576;0;632;0
WireConnection;576;1;602;0
WireConnection;605;0;604;0
WireConnection;605;1;632;0
WireConnection;605;2;606;0
WireConnection;250;0;8;0
WireConnection;624;0;620;0
WireConnection;526;0;521;0
WireConnection;526;1;1;0
WireConnection;526;2;515;0
WireConnection;622;0;619;0
WireConnection;622;1;631;0
WireConnection;622;2;621;0
WireConnection;582;0;577;0
WireConnection;582;1;576;0
WireConnection;603;0;582;0
WireConnection;603;2;605;0
WireConnection;625;0;624;0
WireConnection;326;0;622;0
WireConnection;10;0;526;0
WireConnection;10;1;250;0
WireConnection;627;0;612;0
WireConnection;650;0;603;0
WireConnection;650;1;647;0
WireConnection;626;0;625;0
WireConnection;355;0;358;0
WireConnection;355;1;323;0
WireConnection;560;0;10;0
WireConnection;357;0;358;0
WireConnection;357;1;326;0
WireConnection;628;0;626;0
WireConnection;600;0;560;0
WireConnection;600;1;149;0
WireConnection;600;2;615;0
WireConnection;600;3;279;0
WireConnection;600;4;280;0
WireConnection;600;5;29;0
WireConnection;600;6;150;0
WireConnection;600;7;650;0
WireConnection;600;8;632;0
WireConnection;325;0;355;0
WireConnection;325;1;357;0
WireConnection;629;0;627;0
WireConnection;636;0;633;0
WireConnection;636;1;634;0
WireConnection;636;2;629;0
WireConnection;359;0;360;0
WireConnection;359;1;325;0
WireConnection;630;0;628;0
WireConnection;2;1;600;0
WireConnection;638;0;2;0
WireConnection;638;1;636;0
WireConnection;638;2;620;0
WireConnection;31;1;600;0
WireConnection;637;0;630;0
WireConnection;637;1;635;4
WireConnection;289;1;359;0
WireConnection;289;2;303;0
WireConnection;32;0;31;0
WireConnection;32;1;33;0
WireConnection;639;0;638;0
WireConnection;639;1;635;0
WireConnection;639;2;637;0
WireConnection;298;0;289;1
WireConnection;298;1;297;0
WireConnection;298;2;299;0
WireConnection;226;0;526;0
WireConnection;226;1;252;0
WireConnection;561;0;224;0
WireConnection;640;0;32;0
WireConnection;640;1;641;0
WireConnection;640;2;620;0
WireConnection;251;0;223;0
WireConnection;224;0;526;0
WireConnection;224;1;251;0
WireConnection;277;0;560;0
WireConnection;277;1;149;0
WireConnection;277;2;615;0
WireConnection;277;3;279;0
WireConnection;277;4;280;0
WireConnection;277;5;29;0
WireConnection;277;6;150;0
WireConnection;574;0;602;0
WireConnection;574;1;572;0
WireConnection;574;2;573;0
WireConnection;288;0;298;0
WireConnection;288;1;639;0
WireConnection;563;0;9;0
WireConnection;9;0;526;0
WireConnection;9;1;7;0
WireConnection;252;0;225;0
WireConnection;0;0;288;0
WireConnection;0;1;622;0
WireConnection;0;2;640;0
WireConnection;0;3;164;0
WireConnection;0;4;30;0
WireConnection;0;11;9;0
WireConnection;0;12;10;0
ASEEND*/
//CHKSM=F75EFB733F947CE31DC89B7D228E109BF0CCD2EA