//@author: dottore
//@description: Queue texture of incoming data.
//@tags: queue texture
//@credits: 
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;  		//the models world matrix
float Yres <String uiname="Y Resolution";> ;

//Queue texture
texture QueueTex <string uiname="Queue Texture";>;
sampler SampQueue = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (QueueTex);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    AddressU = Clamp;
    AddressV = Clamp;
};

//Heads texture
texture HeadsTex  <string uiname="Heads Texture";>;
sampler SampHeads = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (HeadsTex);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    AddressU = Clamp;
    AddressV = Clamp;
};

bool insert ;
bool reset;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos : POSITION ;
    float2 TexCd : TEXCOORD0 ;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 Pos : POSITION ,
    float2 TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
    //transform position
    Out.Pos = mul(Pos, tW);
    //transform texturecoordinates
    Out.TexCd= TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
 float4 Data;
 float4 Heads = tex2D(SampHeads, In.TexCd);
 
 if (In.TexCd.y > 1/Yres)
      { Data = tex2D(SampQueue, float2(In.TexCd.x,In.TexCd.y - insert/Yres )); }
 else { Data = Heads; }

 if (reset) { Data = Heads; }
    
 return Data;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique QueueTexture
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
