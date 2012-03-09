//@author: dottore
//@description: 3d Velocity Cycle texture
//@tags: particles dynamic texture 
//@credits: 

//transforms
float4x4 tW: WORLD;

//data from the last frame
texture Queue <string uiname="Last Frame";>;
sampler SampQueue = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Queue);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//increment value
texture PosAdd <string uiname="RGB=XYZ increment values";>;
sampler SampAdd = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (PosAdd);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//reset position
texture ResPos <string uiname="RGB=XYZ reset velocity";>;
sampler SampResPos = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (ResPos);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    addressU = wrap;
};

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

float2 XYres;
float emitterCount;
float emitIndex;
float emitIndexPrev;
float velocityMult;

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 Pos  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //declare output struct
    vs2ps Out;
    
    //transform position
    Out.Pos = mul(Pos,tW);
    
    //transform texturecoordinates
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 posQueue = tex2D(SampQueue, In.TexCd);
    float4 PosVelAdd = tex2D(SampAdd, In.TexCd); 
    
    bool ResBang = 0;
    float index = In.TexCd.x*XYres.x + In.TexCd.y*XYres.x*XYres.y;       
    if(emitIndex >= emitIndexPrev)
      { ResBang = index > emitIndexPrev && index <= emitIndex;}
    else
      { ResBang = 1-(index < emitIndexPrev && index >= emitIndex); }
    
 /*   float indexU = 0;
    if(emitIndex >= emitIndexPrev)
      { indexU = (index - emitIndexPrev)/emitterCount ;}  
    else
      { indexU = 1-(index < emitIndexPrev && index >= emitIndex); }
   */  
    float4 resetPos = tex2D(SampResPos, float2(index/emitterCount,0));
  

if(ResBang)
         {
         return resetPos;
         }
         else
         {
         posQueue.rgb *= velocityMult;
         posQueue.rgb += PosVelAdd.rgb;
         posQueue.a = 0;
         return posQueue;
         }         
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
