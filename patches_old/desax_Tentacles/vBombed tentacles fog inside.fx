// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW  : WORLD;        //the models world matrix
float4x4 tV  : VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tWV : WORLDVIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tP  : PROJECTION;   //projection matrix as set via Renderer (EX9)

float4x4 TT ;
float4x4 NoiseMatrix = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};

//light properties
float3 lDir <string uiname="Light Direction";> = {0, -5, 2};        //light direction in world space
float4 lAmb  : COLOR <String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};
float4 lDiff : COLOR <String uiname="Diffuse Color";>  = {0.85, 0.85, 0.85, 1};
float4 lSpec : COLOR <String uiname="Specular Color";> = {0.35, 0.35, 0.35, 1};
float lPower <String uiname="Power"; float uimin=0.0;> = 25.0;     //shininess of specular highlight

#define BSIZE 32
#define FULLSIZE 66
#define NOISEFRAC 0.03125

const float4 NTab[66] = {
                -0.854611,-0.453029,0.25378,0,
		-0.84528,-0.456307,-0.278002,1,
		-0.427197,0.847095,-0.316122,2,
		0.670266,-0.496104,0.551928,3,
		-0.675674,-0.713842,0.184102,4,
		-0.0373602,-0.600265,0.798928,5,
		-0.939116,-0.119538,0.322135,6,
		0.818521,0.278224,0.502609,7,
		0.105335,-0.765291,0.635007,8,
		-0.634436,-0.298693,0.712933,9,
		-0.532414,-0.603311,-0.593761,10,
		0.411375,0.0976618,0.906219,11,
		0.798824,-0.416379,-0.434175,12,
		-0.691156,0.585681,-0.423415,13,
		0.612298,0.0777332,0.786797,14,
		0.264612,-0.262848,0.927842,15,
		-0.70809,0.0548396,-0.703989,16,
		0.933195,-0.294222,-0.206349,17,
		0.788936,-0.466718,-0.399692,18,
		-0.540183,-0.824413,0.168954,19,
		0.469322,-0.184125,0.863617,20,
		-0.84773,0.292229,-0.44267,21,
		0.450832,0.650314,-0.611427,22,
		0.906378,-0.247125,-0.342647,23,
		-0.995052,0.0271277,-0.0955848,24,
		-0.0252277,-0.778349,0.627325,25,
		0.991428,0.128623,0.0229457,26,
		-0.842581,-0.290688,0.453384,27,
		-0.662511,-0.500545,-0.557256,28,
		0.650245,-0.692099,-0.313338,29,
		0.636901,0.768918,-0.0558766,30,
		-0.437006,0.872104,-0.220138,31,
		-0.854611,-0.453029,0.25378,0,
		-0.84528,-0.456307,-0.278002,1,
		-0.427197,0.847095,-0.316122,2,
		0.670266,-0.496104,0.551928,3,
		-0.675674,-0.713842,0.184102,4,
		-0.0373602,-0.600265,0.798928,5,
		-0.939116,-0.119538,0.322135,6,
		0.818521,0.278224,0.502609,7,
		0.105335,-0.765291,0.635007,8,
		-0.634436,-0.298693,0.712933,9,
		-0.532414,-0.603311,-0.593761,10,
		0.411375,0.0976618,0.906219,11,
		0.798824,-0.416379,-0.434175,12,
		-0.691156,0.585681,-0.423415,13,
		0.612298,0.0777332,0.786797,14,
		0.264612,-0.262848,0.927842,15,
		-0.70809,0.0548396,-0.703989,16,
		0.933195,-0.294222,-0.206349,17,
		0.788936,-0.466718,-0.399692,18,
		-0.540183,-0.824413,0.168954,19,
		0.469322,-0.184125,0.863617,20,
		-0.84773,0.292229,-0.44267,21,
		0.450832,0.650314,-0.611427,22,
		0.906378,-0.247125,-0.342647,23,
		-0.995052,0.0271277,-0.0955848,24,
		-0.0252277,-0.778349,0.627325,25,
		0.991428,0.128623,0.0229457,26,
		-0.842581,-0.290688,0.453384,27,
		-0.662511,-0.500545,-0.557256,28,
		0.650245,-0.692099,-0.313338,29,
		0.636901,0.768918,-0.0558766,30,
		-0.437006,0.872104,-0.220138,31,
		-0.854611,-0.453029,0.25378,0,
		-0.84528,-0.456307,-0.278002,1};

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;
float4x4 tColor <string uiname="Color Transform";>;

float timer : TIME;

float TurbDensity <string uiname="Turbulence Density";
	float UIMin = 0.01;
	float UIMax = 8.0;
	float UIStep = 0.001;>
        = 2.27;

float Disp <string uiname="Displacement";
      float UIMin = 0.0;
      float UIMax = 2.0;
      float UIStep = 0.01;>
      = 1.6;

float Sharp <string uiname="Sharpness";
	float UIMin = 0.1;
	float UIMax = 5.0;
	float UIStep = 0.1;>
        = 1.90;

float Speed <string uiname="Speed";
	float UIMin = 0.01;
	float UIMax = 1.0;
	float UIStep = 0.001;>
        = 0.3;

//float4 dd[5] = {0,2,3,1, 2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,5,5 };


struct vs2ps
{
    float4 PosWVP: POSITION;
    float4 TexCd : TEXCOORD0;
    float3 LightDirV: TEXCOORD1;
    float3 NormV: TEXCOORD2;
    float3 ViewDirV: TEXCOORD3;
    float3 Pos: TEXCOORD4;
};

#define TWOPI 6.28318531
#define PI 3.14159265

// --------------------------------------------------------------------------------------------------
// FUNCTIONS:
// --------------------------------------------------------------------------------------------------

float gridSpaceX;
float gridSpaceY;

float gridOffsetX;
float gridOffsetY;

float gridScaleX = 1;
float gridScaleY = 1;
float param1 = 1;
float param2 = 1;
float param3 = 1;
float param4 = 1;

float3 cone(float u, float theta)
 {

   float3 p;
   float a = ((gridScaleX-u) / gridScaleX) * param1;// * (param2 * (cos(u*param3)+1) + 1);

   float3 offset;

   p.x = a * cos(theta);
   p.y = a * sin(theta);
   p.z = u ;

   offset.x = u * cos(param2*TWOPI - u);
   offset.y = u * cos(param3*TWOPI - u);
   offset.z = 0;

   return p+offset*param4;
}

// this is the smoothstep function f(t) = 3t^2 - 2t^3, without the normalization
float3 scurve3D(float3 t) { return t*t*( float3(3,3,3) - float3(2,2,2)*t); }
float2 scurve2D(float2 t) { return t*t*( float2(3,3) - float2(2,2)*t); }
float  scurve1D(float  t) { return t*t*(3.0-2.0*t); }

// 3D version
float noise3D(float3 v,
const uniform float4 pg[FULLSIZE])
{
    v = v + float3(10000.0, 10000.0, 10000.0);   // hack to avoid negative numbers

    float3 i = frac(v * NOISEFRAC) * BSIZE;   // index between 0 and BSIZE-1
    float3 f = frac(v);            // fractional position

// lookup in permutation table
    float2 p;
    p.x = pg[ i[0]     ].w;
    p.y = pg[ i[0] + 1 ].w;
    p = p + i[1];

    float4 b;
    b.x = pg[ p[0] ].w;
    b.y = pg[ p[1] ].w;
    b.z = pg[ p[0] + 1 ].w;
    b.w = pg[ p[1] + 1 ].w;
    b = b + i[2];

// compute dot products between gradients and vectors
    float4 r;
    r[0] = dot( pg[ b[0] ].xyz, f );
    r[1] = dot( pg[ b[1] ].xyz, f - float3(1.0, 0.0, 0.0) );
    r[2] = dot( pg[ b[2] ].xyz, f - float3(0.0, 1.0, 0.0) );
    r[3] = dot( pg[ b[3] ].xyz, f - float3(1.0, 1.0, 0.0) );

    float4 r1;
    r1[0] = dot( pg[ b[0] + 1 ].xyz, f - float3(0.0, 0.0, 1.0) );
    r1[1] = dot( pg[ b[1] + 1 ].xyz, f - float3(1.0, 0.0, 1.0) );
    r1[2] = dot( pg[ b[2] + 1 ].xyz, f - float3(0.0, 1.0, 1.0) );
    r1[3] = dot( pg[ b[3] + 1 ].xyz, f - float3(1.0, 1.0, 1.0) );

// interpolate
    f = scurve3D(f);
    r = lerp( r, r1, f[2] );
    r = lerp( r.xyyy, r.zwww, f[1] );
    return lerp( r.x, r.y, f[0] );
}
// 2D version
float noise2D(float2 v, const uniform float4 pg[FULLSIZE])
{
    v = v + (10000.0).xx;

    float2 i = frac(v * NOISEFRAC) * BSIZE;   // index between 0 and BSIZE-1
    float2 f = frac(v);            // fractional position

    // lookup in permutation table
    float2 p;
    p[0] = pg[ i[0]   ].w;
    p[1] = pg[ i[0]+1 ].w;
    p = p + i[1];

    // compute dot products between gradients and vectors
    float4 r;
    r[0] = dot( pg[ p[0] ].xy,   f);
    r[1] = dot( pg[ p[1] ].xy,   f - float2(1.0, 0.0) );
    r[2] = dot( pg[ p[0]+1 ].xy, f - float2(0.0, 1.0) );
    r[3] = dot( pg[ p[1]+1 ].xy, f - float2(1.0, 1.0) );

    // interpolate
    f = scurve2D(f);
    r = lerp( r.xyyy, r.zwww, f[1] );
    return lerp( r.x, r.y, f[0] );
}

// 1D version
float noise1D(float v, const uniform float4 pg[FULLSIZE])
{
    v = v + 10000.0f;

    float i = frac(v * NOISEFRAC) * BSIZE;   // index between 0 and BSIZE-1
    float f = frac(v);            // fractional position

    // compute dot products between gradients and vectors
    float2 r;
    r[0] = pg[i].x * f;
    r[1] = pg[i + 1].x * (f - 1.0f);

    // interpolate
    f = scurve1D(f);
    return lerp( r[0], r[1], f);
}

float3 vBombFunc3D(float u, float v)
{

    float4 PosO = float4(cone(u, v), 1);
    float4 noisePos = TurbDensity*mul(PosO+(Speed*timer),NoiseMatrix);
    float i = (noise3D(noisePos.xyz, NTab) + 1.0) * 0.5f;
    // displacement along normal
    float ni = pow(abs(i),Sharp);
    i -=  0.5;
    //i = sign(i) * pow(i,Sharpness);

    // we will use our own "normal" vector because the default geom is a sphere
    float4 Nn = float4(normalize(PosO).xyz,0);

    return  PosO - (Nn * (ni-0.5) * Disp);
}

float3 vBombFunc2D(float u, float v)
{

    float4 PosO = float4(cone(u, v), 1);
    float4 noisePos = TurbDensity*mul(PosO+(Speed*timer),NoiseMatrix);
    float i = (noise2D(noisePos.xy, NTab) + 1.0) * 0.5f;
    // displacement along normal
    float ni = pow(abs(i),Sharp);
    i -=  0.5;
    //i = sign(i) * pow(i,Sharpness);

    // we will use our own "normal" vector because the default geom is a sphere
    float4 Nn = float4(normalize(PosO).xyz,0);

    return  PosO - (Nn * (ni-0.5) * Disp);
}

float3 vBombFunc1D(float u, float v)
{

    float4 PosO = float4(cone(u, v), 1);
    float4 noisePos = TurbDensity*mul(PosO+(Speed*timer),NoiseMatrix);
    float i = (noise1D(noisePos.y, NTab) + 1.0) * 0.5f;
    // displacement along normal
    float ni = pow(abs(i),Sharp);
    i -=  0.5;
    //i = sign(i) * pow(i,Sharpness);

    // we will use our own "normal" vector because the default geom is a sphere
    float4 Nn = float4(normalize(PosO).xyz,0);

    return  PosO - (Nn * (ni-0.5) * Disp);
}

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

float3 campos;

vs2ps VS_vBomb3D(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
    PosO =  mul(PosO, TT);
    
    float x, y, z, u, v;
    float u2, v2;
    float3 tang, bitang;

    //map u and v
    gridScaleX *= PI;
    gridScaleY *= TWOPI;

    u = (PosO.x + gridOffsetX) * gridScaleX;
    v = (PosO.y + gridOffsetY) * gridScaleY;

    //to get neighbour in u direction
    u2 = (PosO.x + gridSpaceX + gridOffsetX) * gridScaleX;

    //to get neighbour in v direction
    v2 = (PosO.y + gridSpaceY + gridOffsetY) * gridScaleY;

    //get position
    PosO.xyz = vBombFunc3D(u, v);

    //get position of neighbours
    tang   = vBombFunc3D(u2, v);
    bitang = vBombFunc3D(u, v2);

    //get tangent and bitangent
    tang   -= PosO.xyz;
    bitang -= PosO.xyz;

    //get normal
    NormO = cross(tang, bitang);
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));

    //position (projected)
    Out.PosWVP  = mul(PosO, tWVP);
    Out.Pos = mul(PosO, tWV);
    Out.TexCd = mul(TexCd, tTex);
    Out.ViewDirV = -normalize(mul(PosO, tWV));
    return Out;
}

vs2ps VS_vBomb2D(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
    PosO =  mul(PosO, TT);
    
    float x, y, z, u, v;
    float u2, v2;
    float3 tang, bitang;

    //map u and v
    gridScaleX *= PI;
    gridScaleY *= TWOPI;

    u = (PosO.x + gridOffsetX) * gridScaleX;
    v = (PosO.y + gridOffsetY) * gridScaleY;

    //to get neighbour in u direction
    u2 = (PosO.x + gridSpaceX + gridOffsetX) * gridScaleX;

    //to get neighbour in v direction
    v2 = (PosO.y + gridSpaceY + gridOffsetY) * gridScaleY;

    //get position
    PosO.xyz = vBombFunc2D(u, v);

    //get position of neighbours
    tang   = vBombFunc2D(u2, v);
    bitang = vBombFunc2D(u, v2);

    //get tangent and bitangent
    tang   -= PosO.xyz;
    bitang -= PosO.xyz;

    //get normal
    NormO = cross(tang, bitang);
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));

    //position (projected)
    Out.PosWVP  = mul(PosO, tWVP);
    //
    Out.Pos = mul(PosO, tWV);
    Out.TexCd = mul(TexCd, tTex);
    Out.ViewDirV = -normalize(mul(PosO, tWV));
    return Out;
}

vs2ps VS_vBomb1D(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
    PosO =  mul(PosO, TT);
    
    float x, y, z, u, v, pi;
    float u2, v2;
    float3 tang, bitang;
    pi = 3.14159265;

    //map u and v
    gridScaleX *= PI;
    gridScaleY *= TWOPI;

    u = (PosO.x + gridOffsetX) * gridScaleX;
    v = (PosO.y + gridOffsetY) * gridScaleY;

    //to get neighbour in u direction
    u2 = (PosO.x + gridSpaceX + gridOffsetX) * gridScaleX;

    //to get neighbour in v direction
    v2 = (PosO.y + gridSpaceY + gridOffsetY) * gridScaleY;

    //get position
    PosO.xyz = vBombFunc1D(u, v);

    //get position of neighbours
    tang   = vBombFunc1D(u2, v);
    bitang = vBombFunc1D(u, v2);

    //get tangent and bitangent
    tang   -= PosO.xyz;
    bitang -= PosO.xyz;

    //get normal
    NormO = cross(tang, bitang);
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));

    //position (projected)
    Out.PosWVP  = mul(PosO, tWVP);
    Out.Pos = mul(PosO, tWV);
    Out.TexCd = mul(TexCd, tTex);
    Out.ViewDirV = -normalize(mul(PosO, tWV));
    return Out;
}
// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 fogCol : Color;
float fogScale;

float4 PS(vs2ps In): COLOR
{
    //In.TexCd = In.TexCd / In.TexCd.w; // for perpective texture projections (e.g. shadow maps) ps_2_0

    lAmb.a = 1;
    //halfvector
    float3 H = normalize(In.ViewDirV + In.LightDirV);

    //compute blinn lighting
    float3 shades = lit(dot(In.NormV, In.LightDirV), dot(In.NormV, H), lPower);

    float4 diff = lDiff * shades.y;
    diff.a = 1;

    //reflection vector (view space)
    float3 R = normalize(2 * dot(In.NormV, In.LightDirV) * In.NormV - In.LightDirV);
    //normalized view direction (view space)
    float3 V = normalize(In.ViewDirV);

    //calculate specular light
    float4 spec = pow(max(dot(R, V),0), lPower*.2) * lSpec;

    float4 col = tex2D(Samp, In.TexCd);
    col.rgb *= (lAmb + diff) + spec;

    float dist = saturate(length(campos-In.Pos)*fogScale*0.02-0.06);

    return lerp(mul(col, tColor), fogCol, dist);
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique vBomb3D
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS_vBomb3D();
        PixelShader = compile ps_2_a PS();
    }
}
technique vBomb2D
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS_vBomb2D();
        PixelShader = compile ps_2_a PS();
    }
}
technique vBomb1D
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS_vBomb1D();
        PixelShader = compile ps_2_a PS();
    }
}
