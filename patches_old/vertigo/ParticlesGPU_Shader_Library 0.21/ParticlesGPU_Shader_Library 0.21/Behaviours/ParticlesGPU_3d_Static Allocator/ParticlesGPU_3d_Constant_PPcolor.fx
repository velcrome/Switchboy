//@author: dottore
//@description: draws a Constant particlesGPU mesh using 2 data textures and PPcolor color texture
//@tags: 3d particles  
//@credits: tonfilm
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tVP: VIEWPROJECTION;


texture TexTransform <string uiname="Transform Texture 1";>;
sampler SampTransform = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexTransform);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

texture TexTransform2 <string uiname="Transform Texture 2";>;
sampler SampTransform2 = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexTransform2);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

texture PPcolor <string uiname="PP Color Texture";>;
sampler SampCol = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (PPcolor);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

// --------------------------------------------------------------------------------------------------
// --------FUNCTIONS---------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

#define minTwoPi -6.283185307179586476925286766559
#define TwoPi 6.283185307179586476925286766559

//rotate point by quaternion

float3 rotPbyQ (float3 p, float4 q){

   return  p*(q.x*q.x - q.y*q.y - q.z*q.z - q.w*q.w) +
         2*q.yzw*dot(q.yzw, p) + 2*cross(p, q.yzw)*q.x;

}

//rotate point by euler angles

float3 rotate(float3 point, float pitch, float yaw, float roll)
{

  pitch *= minTwoPi;
  yaw    = minTwoPi*(yaw+0.25);
  roll  *= minTwoPi;

  point.xyz = float3(-point.z, point.y, point.x);

  float4 es;
  float coy = cos(yaw*0.5);
  float siy = sin(yaw*0.5);

  es.x = cos(0.5*(roll+pitch))*coy;
  es.y = sin(0.5*(roll-pitch))*siy;
  es.z = cos(0.5*(roll-pitch))*siy;
  es.w = sin(0.5*(roll+pitch))*coy;

  return rotPbyQ(point, es);

// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

}
struct Particles3d
{
    float4 Pos : POSITION ;
    float4 Vcol : COLOR ;
};


// VERTEXSHADERS

Particles3d VS(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float4 TexCdTexture : TEXCOORD1 )
{
    //inititalize all fields of output struct with 0
    
    Particles3d Out = (Particles3d)0;

    //Transform Data from Transform texture
    
    float4 Transform = tex2Dlod(SampTransform, TexCd);
    float3 Transform2 = tex2Dlod(SampTransform2, TexCd);

    //Apply scale
    PosO.xyz *= Transform.w;
    
    //Apply rotation
    PosO.xyz = rotate(PosO.xyz, Transform2.x, Transform2.y, Transform2.z);

    //Apply translate
    PosO.xyz += Transform.xyz;
    
    Out.Pos = mul(PosO, tVP);
    
    Out.Vcol = tex2Dlod(SampCol, TexCd);

    return Out;
}

// PIXELSHADERS:

float4 PS(Particles3d In): COLOR
{
    return In.Vcol ;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Particles_3d
{
pass P0
     {
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PS();
     }
}
