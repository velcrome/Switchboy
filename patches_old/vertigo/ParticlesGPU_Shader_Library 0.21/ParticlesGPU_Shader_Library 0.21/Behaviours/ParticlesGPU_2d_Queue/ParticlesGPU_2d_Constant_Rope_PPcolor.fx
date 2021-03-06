//@author: dottore
//@description: draws a Constant particlesGPU Rope mesh using data textures and PPcolor texture;
//              the angle of the rope segments is taken from the B channel of the data texture.
//@tags: 2d particles rope GPU 
//@credits: 

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;       
float4x4 tVP: VIEWPROJECTION ;

float Yres <string uiname="Mesh resolution";>;

//Data texture
texture Tex <string uiname="Data Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    AddressU = Clamp;
    AddressV = Clamp;
};

//PP Color texture
texture PPColTex <string uiname="PP Color Texture";>;
sampler SampPPCol = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (PPColTex);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    AddressU = Clamp;
    AddressV = Clamp;
};

//texture
texture Texture <string uiname="Texture";>;
sampler SampTexture = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Texture);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

// --------------------------------------------------------------------------------------------------
// STRUCT:
// --------------------------------------------------------------------------------------------------

struct vs2ps
{
    float4 Pos : POSITION ;
    float4 TexCd1 : TEXCOORD0 ;
    float2 TexCd2 : TEXCOORD1 ;
    float4 Vcol : COLOR ;      
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS:
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO : POSITION ,
    float4 TexCd1 : TEXCOORD0 ,
    float4 TexCd2 : TEXCOORD1 )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
    
    float4 particleData = tex2Dlod(Samp, TexCd1);
            
    float4x4 TransformMatrix = {cos(particleData.b) , sin(particleData.b) , 0, 0,
                                -sin(particleData.b), cos(particleData.b) , 0, 0,
                                0             , 0             , 1, 0,
                                particleData.r, particleData.g, 0, 1};
    
    //apply the tW (points at the mesh position)
    PosO = mul(PosO, TransformMatrix);
    PosO = mul(PosO, tW);

    //then apply the tVP
    Out.Pos = mul(PosO, tVP);
    Out.TexCd2 = mul(TexCd2,tTex);
    
    Out.Vcol = tex2Dlod(SampPPCol, TexCd1);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------


float4 PS(vs2ps In): COLOR
{
    return  In.Vcol * tex2D(SampTexture, In.TexCd2) ;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Rope
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
