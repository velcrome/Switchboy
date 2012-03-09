

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWV: WORLDVIEW;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 TB ;
//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

float4x4 Tcol;

//light properties
float3 lPos <string uiname="Light Position";> = {0, 5, -2};       //light position in world space
float lAtt0 <String uiname="Light Attenuation 0"; float uimin=0.0;> = 0;
float lAtt1 <String uiname="Light Attenuation 1"; float uimin=0.0;> = 0.3;
float lAtt2 <String uiname="Light Attenuation 2"; float uimin=0.0;> = 0;
float4 lAmb  : COLOR <String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};
float4 lDiff : COLOR <String uiname="Diffuse Color";>  = {0.85, 0.85, 0.85, 1};
float4 lSpec : COLOR <String uiname="Specular Color";> = {0.35, 0.35, 0.35, 1};
float lPower <String uiname="Power"; float uimin=0.0;> = 25.0;     //shininess of specular highlight
float lRange <String uiname="Light Range"; float uimin=0.0;> = 10.0;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function

struct vs2ps
{
    float4 PosWVP: POSITION;
    float4 TexCd : TEXCOORD0;
    float3 LightDirV: TEXCOORD1;
    float2 UV: TEXCOORD2;
    float3 ViewDirV: TEXCOORD3;
    float4 colpos : TEXCOORD4;
    float3 PosW: TEXCOORD5;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

float3 lines (float p, float t){

   float3 Pos;

   float TWOPI = 3.14159 * 2 ;

   float tp = TWOPI * 2 / 3.0;
   float a = TWOPI * (t - p/3);
   float b = TWOPI * (-t - p/3);
   float c = TWOPI*(-t-p);
   float d = TWOPI*(-t+p);
   Pos.x = cos(a) * cos(b) * cos(TWOPI*p) * cos(TWOPI*t);
   Pos.y = cos(a+tp)*cos(b+tp)*cos(c+tp)*cos(TWOPI*(t-1));
   Pos.z = cos(a-tp)*cos(b-tp)*cos(d+tp)*cos(TWOPI*(t-2));
   
   return Pos;

}

vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
    
    PosO =  mul(PosO, TB);
    
    float p = PosO.x;
    float t = PosO.y;
    
    //transform positions
    PosO.xyz = lines(p, t);
    PosO.w = 1;

    Out.UV = float2(p, t);

    //world position
    Out.PosW = mul(PosO, tW);

    //inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);
    Out.LightDirV = mul(LightDirW, tV);

    //position (projected)
    Out.PosWVP  = mul(PosO, tWVP);

    //view direction
    Out.ViewDirV = -normalize(mul(PosO, tWV));

    Out.colpos = length(PosO);
    
    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------
float alpha;
float dist = 0.001;

float4 PS(vs2ps In): COLOR
{
     
    float u1, v1, u2, v2;
    float3 tang, bitang;
    float3 NormO, NormV;

    //to get neighbour in u direction
    u1 = In.UV.x + dist;
    u2 = In.UV.x - dist;

    //to get neighbour in v direction
    v1 = In.UV.y + dist;
    v2 = In.UV.y - dist;

    //get tangents
    tang   = (lines(u1, In.UV.y) - lines(u2, In.UV.y));
    bitang = (lines(In.UV.x, v1) - lines(In.UV.x, v2));

    //get normal
    NormO = cross(tang, bitang);
    
    //normal in view space
    NormV = mul(float4(NormO, 0), tV);
    NormV = normalize(NormV);
    
    float d = distance(In.PosW, lPos);
    float atten = 0;

    //compute attenuation only if vertex within lightrange
    if (d<lRange)
    {

       atten = 1/(saturate(lAtt0) + saturate(lAtt1) * d + saturate(lAtt2) * pow(d, 2));
    }
    float4 amb = lAmb * atten;
    amb.a = 1;

    //halfvector
    float3 H = normalize(In.ViewDirV + In.LightDirV);

    //compute blinn lighting
    float4 shades = lit(dot(NormV, In.LightDirV), dot(NormV, H), lPower);

    float4 diff = lDiff * shades.y * atten;
    diff.a = 1;
    //reflection vector (view space)
    float3 R = normalize(2 * dot(NormV, In.LightDirV) * NormV - In.LightDirV);
    //normalized view direction (view space)
    float3 V = normalize(In.ViewDirV);

    //calculate specular light
    float4 spec = pow(max(dot(R, V),0), lPower*.2) * lSpec;

    float4 col = tex2D(Samp, In.TexCd);
    col.rgb *= (amb + diff) + spec;
    col.a = alpha;
    return mul(col, Tcol);



    }

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}

technique TFixedFunction
{
    pass P0
    {
        //transforms
        WorldTransform[0]   = (tW);
        ViewTransform       = (tV);
        ProjectionTransform = (tP);

        //texturing
        Sampler[0] = (Samp);
        TextureTransform[0] = (tTex);
        TexCoordIndex[0] = 0;
        TextureTransformFlags[0] = COUNT2;
        //Wrap0 = U;  // useful when mesh is round like a sphere
        
        Lighting       = FALSE;

        //shaders
        VertexShader = NULL;
        PixelShader  = NULL;
    }
}
