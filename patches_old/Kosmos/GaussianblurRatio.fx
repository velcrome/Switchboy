  //@author: dottore
  //@description: gaussian blur with correct aspect ratio
  //@tags: blur
  //@credits: sanch

// -------------------------------------------------------------------------------------------------------------------------------------
// PARAMETERS:
// -------------------------------------------------------------------------------------------------------------------------------------

//transforms
float4x4 tWVP: WORLDVIEWPROJECTION;


texture g_txSrcColor;
sampler2D g_samSrcColor = sampler_state
{
    Texture = <g_txSrcColor>;
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Linear;
    MipFilter = Linear;
};
float4x4 tTex <string uiname="Texture Transform";>;


float blur = 0 ;
int2 XYres = 128 ;

//////////////////////////////////////////////////////////////////


struct VS_OUTPUT
{
    float4 Pos  : POSITION;
    float2 TexC : TEXCOORD0;
};

VS_OUTPUT VS(
    float4 Pos  : POSITION,
    float2 TexC : TEXCOORD)
{
    //inititalize all fields of output struct with 0
    VS_OUTPUT Out = (VS_OUTPUT)0;

    //transform position
    Out.Pos = mul(Pos, tWVP);
    //transform texturecoordinates
    Out.TexC = mul(TexC, tTex);

    return Out;
}



/////////////////////////////////////////// Pixel Shader: 	HorizontalBlur

float4 gaussianbluryPS( float2 Tex : TEXCOORD0 ) : COLOR0
{  static const int g_cKernelSize = 13;

float2 mult = 1.0f/XYres * blur;
float2 TexelKernel[13] =
{
    { -6, 0 },
    { -5, 0 },
    { -4, 0 },
    { -3, 0 },
    { -2, 0 },
    { -1, 0 },
    {  0, 0 },
    {  1, 0 },
    {  2, 0 },
    {  3, 0 },
    {  4, 0 },
    {  5, 0 },
    {  6, 0 },
};



 const float BlurWeights[13] =
{
    0.002216,
    0.008764,
    0.026995,
    0.064759,
    0.120985,
    0.176033,
    0.199471,
    0.176033,
    0.120985,
    0.064759,
    0.026995,
    0.008764,
    0.002216,
};

    float4 Color = 0;

    for (int i = 0; i < 13; i++)
    {    
        Color += tex2D( g_samSrcColor, Tex + TexelKernel[i].yx * mult) * BlurWeights[i];
    }
    
    return Color;
}

///////////////////////////////////////////////////////////////


float4 gaussianblurxPS( float2 Tex : TEXCOORD0 ) : COLOR0
{  static const int g_cKernelSize = 13;

 float2 mult = 1.0f/XYres * blur;

float2 TexelKernel[13] =
{
    { -6, 0 },
    { -5, 0 },
    { -4, 0 },
    { -3, 0 },
    { -2, 0 },
    { -1, 0 },
    {  0, 0 },
    {  1, 0 },
    {  2, 0 },
    {  3, 0 },
    {  4, 0 },
    {  5, 0 },
    {  6, 0 },
};



 const float BlurWeights[13] =
{
    0.002216,
    0.008764,
    0.026995,
    0.064759,
    0.120985,
    0.176033,
    0.199471,
    0.176033,
    0.120985,
    0.064759,
    0.026995,
    0.008764,
    0.002216,
};

    float4 Color = 0;

    for (int i = 0; i < 13; i++)
    {
        Color += tex2D( g_samSrcColor, Tex + TexelKernel[i].xy * mult) * BlurWeights[i];
    }

    return Color;
}

//////////////////////////////////////////////////////////////////



technique gaussianBlurx
{
    pass p0
    {
        VertexShader = compile vs_1_0 VS();
        PixelShader = compile ps_2_0 gaussianblurxPS();
        ZEnable = false;
    }
}
technique GaussianBlur_y
{
    pass p0
    {
        VertexShader = compile vs_1_0 VS();
        PixelShader = compile ps_2_0 gaussianbluryPS();
        ZEnable = false;
    }
}
