//This file contains the vertex, fragment, and Geometry functions for both the ForwardBase and Forward Add pass.
#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
#define V2F_SHADOW_CASTER_NOPOS float3 vec : TEXCOORD0;
#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos) o.vec = mul(unity_ObjectToWorld, v[i].vertex).xyz - _LightPositionRange.xyz; opos = o.pos;
#else
#define V2F_SHADOW_CASTER_NOPOS
#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos,p,n) \
        opos = UnityClipSpaceShadowCasterPos(p, n); \
        opos = UnityApplyLinearShadowBias(opos);
#endif

const float F3 = 0.3333333;
const float G3 = 0.1666667;
float3 random3(float3 c) {
	float j = 4096.0*sin(dot(c, float3(17.0, 59.4, 15.0)));
	float3 r;
	r.z = frac(512.0*j);
	j *= .125;
	r.x = frac(512.0*j);
	j *= .125;
	r.y = frac(512.0*j);
	return r - 0.5;
}

float random(float2 uv)
{
	return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453123);
}

float simplex3d(float3 p) {
	/* 1. find current tetrahedron T and it's four vertices */
	/* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
	/* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

	/* calculate s and x */
	float3 s = floor(p + dot(p, float3(F3, F3, F3)));
	float3 x = p - s + dot(s, float3(G3, G3, G3));

	/* calculate i1 and i2 */
	float3 e = step(float3(0, 0, 0), x - x.yzx);
	float3 i1 = e * (1.0 - e.zxy);
	float3 i2 = 1.0 - e.zxy*(1.0 - e);

	/* x1, x2, x3 */
	float3 x1 = x - i1 + G3;
	float3 x2 = x - i2 + 2.0*G3;
	float3 x3 = x - 1.0 + 3.0*G3;

	/* 2. find four surflets and store them in d */
	float4 w, d;

	/* calculate surflet weights */
	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);

	/* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
	w = max(0.6 - w, 0.0);

	/* calculate surflet components */
	d.x = dot(random3(s), x);
	d.y = dot(random3(s + i1), x1);
	d.z = dot(random3(s + i2), x2);
	d.w = dot(random3(s + 1.0), x3);

	/* multiply d by w^4 */
	w *= w;
	w *= w;
	d *= w;

	/* 3. return the sum of the four surflets */
	return dot(d, float4(52.0, 52.0, 52.0, 52.0));
}

float4x4 YRotationMatrix(float degrees)
{
	float alpha = degrees * UNITY_PI / 180.0;
	float s = sin(alpha);
	float c = cos(alpha);
	//But how can I insert the pivot???
	return float4x4(
		c, 0, -s, 0,
		0, 1, 0, 0,
		s, 0, c, 0,
		0, 0, 0, 1);
}

float4 GetVertex(float4 p1, float4 p2, float4 p3, float4 p4, int index) {
	float4 v[12] =
	{
		p1, p2, p3,
		p2, p1, p4,
		p3, p2, p4,
		p1, p3, p4
	};
	return v[index];
}

float3 GetNormal(float4 p1, float4 p2, float4 p3, float4 p4, float3 n1, float3 n2, float3 n3, int index) {
	float4 calcIndex[12] = 
	{
		p1, p2, p3,
		p1, p2, p4,
		p2, p3, p4,
		p3, p1, p4
	};

	int generateIndex = index / 3;
	float3 generatedNormal = normalize(cross(normalize(calcIndex[generateIndex + 1] - calcIndex[generateIndex]), normalize(calcIndex[generateIndex + 2] - calcIndex[generateIndex])));

	float3 n[12] =
	{
		n1, n2, n3,
		-generatedNormal, -generatedNormal, -generatedNormal,
		-generatedNormal, -generatedNormal, -generatedNormal,
		-generatedNormal, -generatedNormal, -generatedNormal
	};
	return n[index];
}

float2 GetUV(float2 uv1, float2 uv2, float2 uv3, float2 uv4, int index) {
	float2 uv[12] =
	{
		uv1, uv2, uv3,
		uv2, uv1, uv4,
		uv3, uv2, uv4,
		uv1, uv3, uv4
		//uv2 + 10, uv1 + 10, uv4 + 10,
		//uv3 + 10, uv2 + 10, uv4 + 10,
		//uv1 + 10, uv3 + 10, uv4 + 10
	};
	return uv[index];
}

float3 GetTangent(float3 tan1, float3 tan2, float3 tan3, int index) {
	float3 tan[12] =
	{
		tan1, tan2, tan3,
		tan2, tan2, tan2,
		tan3, tan3, tan3,
		tan1, tan1, tan1
	};
	return tan[index];
}

v2g vert (appdata v)
{
    v2g o = (v2g)0;
    o.vertex = v.vertex;
    o.uv = v.uv;
    
    #if defined(UNITY_PASS_FORWARDBASE)
        o.uv1 = v.uv1;
        o.uv2 = v.uv2;
    #endif
    
    o.normal = v.normal;
    o.tangent = v.tangent;

    return o;
}


[maxvertexcount(12)]
void geom(triangle v2g v[3], uint triangleID: SV_PrimitiveID, inout TriangleStream<g2f> tristream)
{
	g2f o = (g2f)0;
	float4 centerPoint = v[0].vertex;

	float lightup = float2(0,0);
	if (_DissolveCoverage > 0.001) {
	float4 triCenter = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
	triCenter = float4(triCenter.xyz, 1);
	float3 averageNormal = normalize((v[0].normal, v[1].normal, v[2].normal) / 3);
	float3 averageEdgeLength = (length(v[1].vertex - v[0].vertex) + length(v[2].vertex - v[1].vertex) + length(v[2].vertex - v[0].vertex)) / 3;
	float3 offsetNormal = float3(1, 0, 0);
	offsetNormal += 5 * float3(1, 0, 0) * simplex3d(triCenter * 6 + float3(_Time.x * 3.1562, _Time.x*1.712, _Time.x*2.17));
	offsetNormal += 5 * float3(0, 1, 0) * simplex3d(triCenter * 7 + float3(_Time.x * 1.51, _Time.x*0.94, _Time.x*1.18));

	float dist = simplex3d(triCenter * 3 + float3(_Time.x * 3.11, _Time.x * 2.13, _Time.x * 0.31));
	float dissolvecover = (_DissolveCoverage - 0.2) * 4 - triCenter.y * 1;
	dist += dissolvecover + random(float2(triangleID, triangleID+100))*0.1;
	lightup = max(0,(dist * 3 - 1.5) * 10 + sin(dist * 100 + _Time.x * 10) * 0);
	dist = saturate(dist * 3 - 2);

	centerPoint = triCenter - float4(averageNormal * averageEdgeLength * (saturate(dist * 50)+0.1), 0);

	v[0].vertex = mul(YRotationMatrix(dist * 3000 * _DissolveDistance), (v[0].vertex - triCenter))*(1 - dist) + triCenter;
	v[1].vertex = mul(YRotationMatrix(dist * 3000 * _DissolveDistance), (v[1].vertex - triCenter))*(1 - dist) + triCenter;
	v[2].vertex = mul(YRotationMatrix(dist * 3000 * _DissolveDistance), (v[2].vertex - triCenter))*(1 - dist) + triCenter;
	centerPoint = mul(YRotationMatrix(dist * 3000 * _DissolveDistance), (centerPoint - triCenter))*(1 - dist) + triCenter;
	float3 bitan = normalize(cross(v[0].normal, v[0].tangent));
	offsetNormal = v[0].normal * offsetNormal.x + v[0].tangent * offsetNormal.y + bitan * offsetNormal.z;

	v[0].vertex += float4(offsetNormal, 0) * dist * _DissolveDistance;
	v[1].vertex += float4(offsetNormal, 0) * dist * _DissolveDistance;
	v[2].vertex += float4(offsetNormal, 0) * dist * _DissolveDistance;
	centerPoint += float4(offsetNormal, 0) * dist * _DissolveDistance;
}

	
	int triCount = 3;
	if (_DissolveCoverage > 0.001) triCount = 12;

	for (int i = 0; i < triCount; i++)
	{
		float4 vertex = GetVertex(v[0].vertex, v[1].vertex, v[2].vertex, centerPoint, i);
		float3 normal = GetNormal(v[0].vertex, v[1].vertex, v[2].vertex, centerPoint, v[0].normal, v[1].normal, v[2].normal, i);
		float2 uv = GetUV(v[0].uv, v[1].uv, v[2].uv, (v[0].uv + v[1].uv + v[2].uv) / 3, i);
		float3 tang = GetTangent(v[0].tangent, v[1].tangent, v[2].tangent, i);
		float3 bitan = GetTangent(cross(v[0].normal, v[0].tangent.xyz) * v[0].tangent.w, cross(v[1].normal, v[1].tangent.xyz) * v[0].tangent.w, cross(v[2].normal, v[2].tangent.xyz) * v[2].tangent.w, i);
		o.pos = UnityObjectToClipPos(vertex);
		o.uv = TRANSFORM_TEX(uv, _MainTex);
		#if defined(UNITY_PASS_FORWARDBASE)
		o.bary = float3(saturate(i%3-1), saturate((i+1)%3-1), saturate((i+2)%3-1));
		o.uv1 = float2(lightup, saturate(i-3));
		//o.uv2 = v[0].uv2;
		#endif
		
		//Only pass needed things through for shadow caster
		#if !defined(UNITY_PASS_SHADOWCASTER)
		float3 worldNormal = UnityObjectToWorldNormal(normal);
		float3 tangent = UnityObjectToWorldDir(tang);
		float3 bitangent = UnityObjectToWorldDir(bitan);

		o.btn[0] = bitangent;
		o.btn[1] = tangent;
		o.btn[2] = worldNormal;
		o.worldPos = mul(unity_ObjectToWorld, vertex);
		o.objPos = vertex;
		o.objNormal = normal;
		UNITY_TRANSFER_SHADOW(o, o.uv);
		#else
		TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, o.pos, vertex, normal);
		#endif

		tristream.Append(o);
		if (i%3==2) tristream.RestartStrip();
	}

}
			
fixed4 frag (g2f i) : SV_Target
{
        //Return only this if in the shadowcaster
    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #else
        return CustomStandardLightingBRDF(i);
    #endif
}