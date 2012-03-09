//@author: dottore
//@help: draws a ParticlesGPUtransform mesh with constant color
//@tags: template, basic, particles, transform
//@credits: vvvv Group 

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tVP: VIEWPROJECTION ;


texture TexTransform <string uiname="Transform Texture";>;
sampler SampTransform = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexTransform);          //apply a texture to the sampler
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

//------------------------------------------------------------------
// GET ANGLE MATRIX  
//------------------------------------------------------------------

#define minTwoPi -6.283185307179586476925286766559
#define TwoPi 6.283185307179586476925286766559

float4x4 Vrotate(float rotX, 
		 float rotY, 
		 float rotZ)
  {
   rotX *= TwoPi;
   rotY *= TwoPi;
   rotZ *= TwoPi;
   float sx = sin(rotX);
   float cx = cos(rotX);
   float sy = sin(rotY);
   float cy = cos(rotY);
   float sz = sin(rotZ);
   float cz = cos(rotZ);

   return float4x4( cz*cy+sz*sx*sy, sz*cx, cz*-sy+sz*sx*cy, 0,
                   -sz*cy+cz*sx*sy, cz*cx, sz*sy+cz*sx*cy , 0,
                    cx * sy       ,-sx   , cx * cy        , 0,
                    0             , 0    , 0              , 1);
  }


// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------


struct vs2ps
{
    float4 Pos : POSITION;
    float4 TexCdTexture : TEXCOORD1;
};


// VERTEXSHADERS

vs2ps VS(
    float4 PosO : POSITION,
    float4 TexCd : TEXCOORD0,
    float4 TexCdTexture : TEXCOORD1)
{
    //inititalize all fields of output struct with 0
    
    vs2ps Out = (vs2ps)0;

//------------------------------------------------------------------
// APPLY TRANSFORM TEXTURE TO POSITION   
//------------------------------------------------------------------

//Transform Data from Transform texture
float4 TRow1 = tex2Dlod(SampTransform, float4(TexCd.x, 0.1667, 0, 0));
float4 TRow2 = tex2Dlod(SampTransform, float4(TexCd.x, 0.5000, 0, 0));
float4 TRow3 = tex2Dlod(SampTransform, float4(TexCd.x, 0.8333, 0, 0));

//ApplyCenter
PosO.xyz -= float3(TRow3.g, TRow3.b, TRow3.a);

//Apply scale
PosO.xyz *= float3(TRow1.a, TRow2.r, TRow2.g);

//Apply rotation
PosO = mul(PosO, Vrotate(TRow2.b, TRow2.a, TRow3.r));

//Apply translate
PosO.xyz += TRow1.rgb;

    
    Out.Pos = mul(PosO, tVP);
    
    Out.TexCdTexture = mul(TexCdTexture, tTex);

    return Out;
}

// PIXELSHADERS:

float4 PS(vs2ps In): COLOR
{
    return tex2D(SampImage, In.TexCdTexture)*cAmb;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Particles_3d_Transform
{
pass P0
     {
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PS();
     }
}
