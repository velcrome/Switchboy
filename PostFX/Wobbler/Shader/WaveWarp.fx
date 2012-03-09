// this is a very basic template. use it to start writing your own effects.
// if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture Tex <string uiname="Texture";>;

sampler sampler0 = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = BORDER;
    AddressV  = BORDER;
};

float width;
float height;
float cosa;
float sina;
float time;
bool pinning;
const float TWOPI = 6.28318531;

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //declare output struct
    vs2ps Out;

    //transform position
    Out.Pos = mul(PosO, tWVP);
    
    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 col = tex2D(sampler0, In.TexCd);
    return col;
}
float4 fragSine(vs2ps In) : COLOR
{
    float2 dir = float2(cosa, sina);
    float2x2 R = float2x2(cosa, sina, -1.0*sina, cosa);    //column-major order
    float2 xy = float2(In.TexCd);
    float4 col = tex2D(sampler0,
       xy);
        float sheight = lerp(0.0, 0.5, height);
    xy -= sheight/2.0*dir;
    float2 rxy = mul(R, xy);
    xy += dir*sheight*sin(fmod(lerp(0.5, 45.0, width)*rxy.y+time, TWOPI));
    if (pinning)    //OS X workaround
        xy = clamp(abs(xy), 0.01, 0.99);
    col = tex2D(sampler0,
       xy);
    return col;
} ;

float4 fragSquare(vs2ps In)      : COLOR
 {
    float2 dir = float2(cosa, sina);
    float2x2 R = float2x2(cosa, sina, -1.0*sina, cosa);    //column-major order
    float2 xy = float2(In.TexCd);
        float sheight = lerp(0.0, 0.5, height);
    xy -= sheight/2.0*dir;
    float2 rxy = mul(R, xy);
    float one = 1.0;
    xy += dir*sheight*step(0.5, fmod(lerp(1.0, 45.0, width)*rxy.y+time, one));
    if (pinning)    //OS X workaround
       xy = clamp(abs(xy), 0.01, 0.99);
    float4 col = tex2D(sampler0,
       xy);
    return col;
 } ;

float4 fragSawtooth(vs2ps In): COLOR
 {
    float2 dir = float2(cosa, sina);
    float2x2 R = float2x2(cosa, sina, -1.0*sina, cosa);    //column-major order
    float2 xy = float2(In.TexCd);
        float sheight = lerp(0.0, 0.5, height);
    xy -= sheight/2.0*dir;
    float2 rxy = mul(R, xy);
    float one = 1.0;
    xy += dir*sheight*fmod(lerp(1.0, 45.0, width)*rxy.y+time, one);
        if (pinning)    //OS X workaround
                xy = clamp(abs(xy), 0.01, 0.99);
    float4 col = tex2D(sampler0,
       xy);
    return col;
 } ;


float4 fragTriangle(vs2ps In): COLOR
{
    float2 dir = float2(cosa, sina);
    float2x2 R = float2x2(cosa, sina, -1.0*sina, cosa);    //column-major order
    float2 xy = float2(In.TexCd);
        float sheight = lerp(0.0, 0.5, height);
    xy -= sheight/2.0*dir;
    float2 rxy = mul(R, xy);
    float one = 1.0;
    xy += dir*sheight*abs(2.0*fmod(lerp(1.0, 45.0, width)*rxy.y+time, one)-1.0);
        if (pinning)    //OS X workaround
                xy = clamp(abs(xy), 0.01, 0.99);
    float4 col = tex2D(sampler0,
       xy);
    return col;
 } ;

float rand(float2 co){
        return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

float4 fragNoise(vs2ps In): COLOR
{
   float2 dir = float2(cosa, sina);
   float2x2 R = float2x2(cosa, sina, -1.0*sina, cosa);    //column-major order
    float2 xy = float2(In.TexCd);
        float sheight = lerp(0.0, 0.1, height);
   xy -= sheight/2.0*dir;
    float2 rxy = mul(R, xy);
        float swidth = width + 0.1;
        float scale = 200.0;
   xy += dir*sheight*rand(float2(rxy.y*swidth*scale-frac(rxy.y*swidth*scale)+time, rxy.y*swidth*scale-frac(rxy.y*swidth*scale)+time));
        if (pinning)    //OS X workaround
                xy = clamp(abs(xy), 0.01, 0.99);
    float4 col = tex2D(sampler0,
       xy);
    return col;
} ;

 
// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Sine
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 fragSine();
    }
}

technique Square
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 fragSquare();
    }
}

technique Sawtooth
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 fragSawtooth();
    }
}

technique Triangle
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 fragTriangle();
    }
}

technique Noise
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 fragNoise();
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
        Sampler[0] = (sampler0);
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
