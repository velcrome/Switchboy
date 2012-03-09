//@author: dottore
//@description: 2d Position Velocity Cycle texture
//@tags: particles dynamic texture 
//@credits: 

//transforms
float4x4 tW: WORLD;

//texture A: position of the last frame
texture PosQueue <string uiname="Position";>;
sampler SampQueue = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (PosQueue);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture B: value to add to curent position
texture PosVelAdd <string uiname="RG=Vel,BA=Acc Input Value";>;
sampler SampAdd = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (PosVelAdd);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture B: reset position
texture ResPos <string uiname="RG=Pos,BA=Vel Reset Value";>;
sampler SampResPos = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (ResPos);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    addressU = wrap;
};

float2 VelFactor <string uiname="Velocity Mult";>;

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
    float2 accCiclo = posQueue.ba ;
    
    
    bool ResBang = 0;
    float index = In.TexCd.x*XYres.x + In.TexCd.y*XYres.x*XYres.y;       
    if(emitIndex >= emitIndexPrev)
      { ResBang = index > emitIndexPrev && index <= emitIndex;}
    else
      { ResBang = 1-(index < emitIndexPrev && index >= emitIndex); }
    
    float indexU = 0;
    if(emitIndex >= emitIndexPrev)
      { indexU = (index - emitIndexPrev)/emitterCount ;}  
    else
      { indexU = 1-(index < emitIndexPrev && index >= emitIndex); }
    
    
    
    float4 resetPos = tex2D(SampResPos, float2(index/emitterCount,0));
  

if(ResBang)
         {
         return resetPos;
         }
         else
         {
         posQueue.ba += PosVelAdd.ba ;
         posQueue.ba *= VelFactor;
         posQueue.rg += PosVelAdd.rg + posQueue.ba  ;

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
