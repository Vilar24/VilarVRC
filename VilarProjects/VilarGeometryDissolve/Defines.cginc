sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _MetallicGlossMap;
sampler2D _BumpMap;
sampler2D _ClearcoatMap;
float4 _Color;
float4 _SubsurfaceColor;
float _Metallic;
float _Glossiness;
float _Reflectance;
float _Clearcoat;
float _ClearcoatGlossiness;
float _BumpScale;

float _VertexOffset;
float _TessellationUniform;
float _TessClose;
float _TessFar;

float _SpecularLMOcclusion;
float _SpecLMOcclusionAdjust;
float _TriplanarFalloff;
float _LMStrength;
float _RTLMStrength;

int _TextureSampleMode;
int _LightProbeMethod;
int _TessellationMode;

sampler2D _EmissionMap;
sampler2D _OcclusionMap;
float4 _AmbientBoostGround;
float4 _AmbientBoostHorizon;
float4 _AmbientBoostSky;
float _AmbientBoost;
float _DissolveCoverage;
float _DissolveDistance;
float _WireframeSmoothing;
float _WireframeThickness;
float4 _WireframeColor;
float4 _WireframeColor2;
int _Mode;
int _SmoothnessTextureChannel=0;