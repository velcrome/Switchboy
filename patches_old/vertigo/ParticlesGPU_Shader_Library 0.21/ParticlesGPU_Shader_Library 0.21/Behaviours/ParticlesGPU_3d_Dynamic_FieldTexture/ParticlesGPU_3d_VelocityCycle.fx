//@author: dottore
//@description: 3d Velocity Cycle texture
//@tags: particles dynamic texture 
//@credits: 

//transforms
float4x4 tW: WORLD;
float2 XYres;
float emitterCount;
float emitIndex;
float emitIndexPrev;
float CycleMult = 1;

//data from the last frame
texture lastFrame <string uiname="Last Frame";>;
sampler SampLastFrame = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (lastFrame);          //apply a texture to the sampler
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
texture ResValue <string uiname="RGB=XYZ reset values";>;
sampler SampResValue = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (ResValue);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//position texture
texture TexData <string uiname="Position Texture";>;
sampler SampData = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexData);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};


texture Field <string uiname="Field Texture";>;
sampler3D SampField = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Field);          //apply a texture to the sampler
    MipFilter = point;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    addressU = border;
    addressV = border;
    addressW = border;
};

float4x4 FieldTransform <string uiname="inverse (FieldTexture transform * scale0.5)";>;
float4x4 FieldRotate <string uiname="FieldTexture Rotate transform";>;
float fieldMult;

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

float4 PS1(vs2ps In): COLOR
{
    float4 posQueue = tex2D(SampLastFrame, In.TexCd);
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
    float4 resetPos = tex2D(SampResValue, float2(index/emitterCount,0));
  
if(ResBang)
         {
         return float4(resetPos.xyz, 1);
         }
         else
         {
         posQueue.rgb *= CycleMult;
         posQueue.rgb += PosVelAdd.rgb;
         posQueue.a = 0;
         return posQueue;

         }         
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

float4 PS2(vs2ps In): COLOR
{
    float4 posQueue = tex2D(SampLastFrame, In.TexCd);
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
    float4 resetPos = tex2D(SampResValue, float2(index/emitterCount,0));
  
if(ResBang)
         {
         return resetPos;
         }
         else
         {
         posQueue.rgb *= CycleMult;
         posQueue.rgb += PosVelAdd.rgb;
         //apply the vector Field texture
         	float4 Position = tex2D(SampData, In.TexCd);
         	float4 fieldValue = tex3D(SampField, mul(float4(Position.rgb,1), FieldTransform)/2 + 0.5);
		 	fieldValue = mul(fieldValue, FieldRotate);
		 	posQueue.rgb += fieldValue.rgb * fieldMult;
		 
         posQueue.a = 0;
         return posQueue;
         }         
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique VelocityCycle3D
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS1();
    }
}

technique VelocityCycle3D_FieldTexture
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS2();
    }
}
