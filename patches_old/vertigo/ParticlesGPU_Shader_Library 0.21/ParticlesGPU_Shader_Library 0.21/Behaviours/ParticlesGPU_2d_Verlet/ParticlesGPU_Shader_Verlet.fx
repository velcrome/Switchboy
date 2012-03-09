float4x4 tW: WORLD ;

float ry <String uiname="Pixel Diameter Y";> = 1/1024;

//texture A: last frame data:  (R=xPos ; G=yPos ; B=Lenght ; A= ....)
texture lastFrame <string uiname="Last Frame data: R=xPos ; G=yPos ; B=xVel ; A=yVel";>;
sampler SampLastFrame = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (lastFrame);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture B: Target (R=xPos ; G=yPos ; B=Lenght ; A=Energy)
texture Target <string uiname="Target data: R=xPos ; G=yPos ; B=Lenght ; A= ...";>;
sampler SampTarget = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Target);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

float Damper <string uiname="Damper";>;

//the data structure: "vertexsha der to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION ;
    float4 TexCd : TEXCOORD0 ;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION ,
    float4 TexCd : TEXCOORD0 )
{
    //declare output struct
    vs2ps Out ;

    //transform position
    Out.Pos = mul(PosO, tW) ;

    //transform texturecoordinates
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
float4 oldData = tex2D(SampLastFrame,In.TexCd);
float4 targetTex = tex2D(SampTarget,In.TexCd);
float4 targetData = tex2D(SampLastFrame, float2(In.TexCd.x, In.TexCd.y-ry));

if (In.TexCd.y>0)  ////Verlet simulation
         {
         float2 distVec = targetData.rg - oldData.rg;

         oldData.rg += (length(distVec)-targetTex.b) * Damper * normalize(distVec) ;
         
         }
         else
         {
         oldData = targetTex;
         }
         
if (targetTex.a)
   {
    oldData.rg = targetTex.rg;
   }

return  oldData ;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Verlet
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
