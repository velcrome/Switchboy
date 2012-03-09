//@author: dottore
//@description: 3d Position Cycle texture
//@tags: particles dynamic texture 
//@credits: 

//transforms
float4x4 tW: WORLD;
float2 XYres;
float emitterCount;

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

float4x4 FieldsTransform <string uiname="inverse (FieldsTexture * scale0.5)";>;
float4x4 FieldsRotate <string uiname="Fields Rotate transform";>;
float fieldsMult;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION ;
    float2 TexCd : TEXCOORD0 ;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 Pos  : POSITION ,
    float4 TexCd : TEXCOORD0 )
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
    
    float index = In.TexCd.x*XYres.x + In.TexCd.y*XYres.x*XYres.y;           
    float4 resetPos = tex2D(SampResValue, float2(index/emitterCount,0));
  

if(PosVelAdd.a) //take the reset bang from the alpha of velocity cycle
         {
         return resetPos;
         }
         else
         {
         posQueue.rgb += PosVelAdd.rgb;
         return posQueue;
         }         
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

float4 PS2(vs2ps In): COLOR
{
    float4 posQueue = tex2D(SampLastFrame, In.TexCd);
    float4 PosVelAdd = tex2D(SampAdd, In.TexCd); 
    
    float index = In.TexCd.x*XYres.x + In.TexCd.y*XYres.x*XYres.y;       
    float4 resetValue = tex2D(SampResValue, float2(index/emitterCount,0));
  

if(PosVelAdd.a) //take the reset bang from the alpha of velocity cycle
         {
         return resetValue;
         }
      else
         {
         posQueue.rgb += PosVelAdd.rgb;
         //apply the vector Field texture
         	float4 fieldsValue = tex3D(SampField, mul(float4(posQueue.rgb,1), FieldsTransform)/2 + 0.5);
		 	fieldsValue = mul(fieldsValue, FieldsRotate);
		 	posQueue.rgb += fieldsValue.rgb * fieldsMult;	 	
		 	
         return posQueue;
         }         
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique PositionCycle3D
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS1();
    }
}

technique PositionCycle3D_FieldTexture
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS2();
    }
}
