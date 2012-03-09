//@author: dottore
//@description: Draws particlesGPU getting info from data texture
//@tags: 2d particles
//@credits: 

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION;


//position texture
texture TexData <string uiname="Data Texture";>;
sampler SampData = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexData);          //apply a texture to the sampler
    MipFilter = Point;         //sampler states
    MinFilter = Point;
    MagFilter = Point;
};

//texture Color
texture TexCol <string uiname="Texture";>;
sampler SampCol = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexCol);          //apply a texture to the sampler
    MipFilter = Linear;         //sampler states
    MinFilter = Linear;
    MagFilter = Linear;
};
float4x4 tTexCol: TEXTUREMATRIX <string uiname="Texture Transform";>;

float4 Color : COLOR ;
//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos : POSITION;
    float4 TexCdCol : TEXCOORD1;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 Pos : POSITION,
    float4 TexCd : TEXCOORD0,
    float4 TexCdCol : TEXCOORD1)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //get the position info from the Position-velocity texture:
    float2 particlePosition = tex2Dlod(SampData, TexCd).rg;
    
    //apply the tW (points at the mesh position)
    Pos = mul(Pos, tW);
    //now apply the position taken from the texture
    Pos.xy += particlePosition;
    //then apply the tVP
    Out.Pos = mul(Pos, tVP);

    Out.TexCdCol = mul(TexCdCol, tTexCol);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 Col = tex2D(SampCol, In.TexCdCol) ;

    return Col * Color ;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TConstant
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
