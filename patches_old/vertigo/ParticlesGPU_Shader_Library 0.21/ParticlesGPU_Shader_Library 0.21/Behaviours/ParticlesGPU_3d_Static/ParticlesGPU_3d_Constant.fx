//@author: dottore
//@description: draws a Constant ParticlesGPU mesh using 2 TransformTextures
//@tags: particles 3d
//@credits: tonfilm  

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tVP: VIEWPROJECTION ;


texture TexTransform <string uiname="Transform_1 Texture";>;
sampler SampTransform = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexTransform);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

texture TexTransform2 <string uiname="Transform_2 Texture";>;
sampler SampTransform2 = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexTransform2);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture Texture
texture TexImage <string uiname="Texture";>;
sampler SampImage = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexImage);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = wrap;  //set here wrap/mirror/clamp
    AddressV = wrap;  //set here wrap/mirror/clamp
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//material properties
float4 cAmb : COLOR <String uiname="Color";>  = {1, 1, 1, 1};

// --------------------------------------------------------------------------------------------------
// --------FUNCTIONS---------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

#define minTwoPi -6.28318531
#define TwoPi 6.28318531

//rotate point by quaternion

float3 rotPbyQ (float3 p, float4 q){

   return  p*(q.x*q.x - q.y*q.y - q.z*q.z - q.w*q.w) +
         2*q.yzw*dot(q.yzw, p) + 2*cross(p, q.yzw)*q.x;

}

//rotate point by euler angles

float3 rotate(float3 pt, float pitch, float yaw, float roll)
{

  pitch *= minTwoPi;
  yaw    = minTwoPi*(yaw+0.25);
  roll  *= minTwoPi;

  pt.xyz = float3(-pt.z, pt.y, pt.x);

  float4 es;
  float coy = cos(yaw*0.5);
  float siy = sin(yaw*0.5);

  es.x = cos(0.5*(roll+pitch))*coy;
  es.y = sin(0.5*(roll-pitch))*siy;
  es.z = cos(0.5*(roll-pitch))*siy;
  es.w = sin(0.5*(roll+pitch))*coy;

  return rotPbyQ(pt, es);

// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

}
struct Particles2d
{
    float4 Pos : POSITION;
    float4 TexCdTexture : TEXCOORD1;
};


// VERTEXSHADERS

Particles2d VS(
    float4 PosO : POSITION,
    float4 TexCd : TEXCOORD0,
    float4 TexCdTexture : TEXCOORD1)
{
    //inititalize all fields of output struct with 0
    
    Particles2d Out = (Particles2d)0;

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
    
    Out.TexCdTexture = mul(TexCdTexture, tTex);

    return Out;
}

// PIXELSHADERS:

float4 PS(Particles2d In): COLOR
{
    return tex2D(SampImage, In.TexCdTexture)*cAmb;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Particles_2d
{
pass P0
     {
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PS();
     }
}
