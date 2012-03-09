//@author: dottore
//@description: draws a Constant ParticlesGPU Sprites mesh using the DataTexture
//@tags: particles sprites
//@credits: Viktor Vicsek for Sprites Function

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;
float4x4 tP: PROJECTION ;
float4x4 tVP: VIEWPROJECTION ;

texture TexData <string uiname="Data Texture";>;
sampler SampData = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexData);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

/////connect this input to the BackBufferHeight output of the renderer
float ViewportHeight;
/////decide if you want perspective
bool calcPerspective<string uiname="Calculate Scale From Perspective";>;
//yet to be done: allow rotating the TexCoords coz the quads cant be rotated
//float rotation<string uiname="Rotate Texcoords";>;


//Color Texture
texture Texture <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Texture);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};

float4 Color :COLOR = 1;

// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

struct vs2ps
{
    float4 Pos : POSITION ;
    float4 TexCd2 : TEXCOORD2 ;
    float Size : PSIZE ;
};


// VERTEXSHADERS

vs2ps VS(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float4 TexCd2 : TEXCOORD2 )
{
    //inititalize all fields of output struct with 0
    
    vs2ps Out = (vs2ps)0;

    //Transform Data from Transform texture
    
    float3 particleTransform = tex2Dlod(SampData, TexCd).xyz;
    
    PosO = mul(PosO, tW);
    PosO.xy += particleTransform.xy;
    Out.Pos = mul(PosO, tVP);
    
    Out.TexCd2 = TexCd2;
    
    if(calcPerspective){
                        Out.Size = particleTransform.z * tP / Out.Pos.w * ViewportHeight/2;
                        }
    else{
         Out.Size = particleTransform.z;
        }
    return Out;
}

// PIXELSHADERS:

float4 PS(vs2ps In): COLOR
{
    return tex2D(Samp, In.TexCd2) * Color;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Particles_2d_Sprites
{
pass P0
     {
/////the next 3 statements are important:
     FillMode = POINT;
     PointScaleEnable = true;
     PointSpriteEnable = true;

     
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PS();
     }
}
