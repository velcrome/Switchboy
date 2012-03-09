//@author: dottore
//@description: draws a Constant ParticlesGPU mesh using the TransformTexture and PerParticle color texture
//@tags: particles
//@credits: 
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tWVP: WORLDVIEWPROJECTION;


texture TexTransform <string uiname="Quad Transform Texture";>;
sampler SampTransform = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexTransform);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture PP Color
texture TexCol <string uiname="PP Color Texture";>;
sampler SampCol = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexCol);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture Texture
texture TexImage <string uiname="Texture";>;
sampler SampImage = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexImage);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = wrap;  //set here wrap/mirror/clamp
    AddressV = wrap;  //set here wrap/mirror/clamp
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;


// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

struct Particles2d
{
    float4 Pos : POSITION ;
    float4 TexCdTexture : TEXCOORD1 ;
    float4 Vcol : COLOR ;
};


// VERTEXSHADERS

Particles2d VS(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float4 TexCdTexture : TEXCOORD1 )
{
    //inititalize all fields of output struct with 0
    
    Particles2d Out = (Particles2d)0;

    //Transform Data from Transform texture
    
    float4 particleTransform = tex2Dlod(SampTransform, TexCd);
    float angle = particleTransform.b * 6.28318530717958;
    
    //prepare the transform matrix with position, angle and scale data from Transform texture
    
    float4x4 TransformMatrix = {cos(angle)        , sin(angle),          0, 0,
                               -sin(angle)        , cos(angle),          0, 0,
                               0                  , 0         ,          1, 0,
                               particleTransform.r, particleTransform.g, 0, 1};
    
    //Apply transform from texture to mesh vertices

    PosO.xy *= particleTransform.a;
    PosO = mul(PosO, TransformMatrix);
    Out.Pos = mul(PosO, tWVP);
    
    Out.TexCdTexture = mul(TexCdTexture, tTex);
    // Get Color from PerParticle color texture
    Out.Vcol = tex2Dlod(SampCol, TexCd);

    return Out;
}

// PIXELSHADERS:

float4 PS(Particles2d In): COLOR
{
    return In.Vcol * tex2D(SampImage, In.TexCdTexture);
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Particles_2d
{
pass P0
     {
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PS();
     }
}
