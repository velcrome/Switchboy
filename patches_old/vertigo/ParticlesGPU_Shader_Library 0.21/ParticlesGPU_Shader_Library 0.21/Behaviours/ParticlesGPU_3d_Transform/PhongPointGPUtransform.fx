//@author: dottore
//@help: draws a ParticlesGPUtransform mesh with basic pixel based lightning with point light
//@tags: shading, blinn, particles, transform
//@credits: vvvv group

// -----------------------------------------------------------------------------
// PARAMETERS:
// -----------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (DX9)
float4x4 tWV: WORLDVIEW;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (DX9)

//------------------------------------------------------------------
// TRANSFORM TEXTURE INPUT  
//------------------------------------------------------------------
texture TexTransform <string uiname="Transform Texture";>;
sampler SampTransform = sampler_state    //sampler for doing the texture-lookup

{
    Texture   = (TexTransform);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

#include "PhongPoint.fxh"

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //set the sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;
float4x4 tColor <string uiname="Color Transform";>;

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

struct vs2ps
{
    float4 PosWVP: POSITION;
    float4 TexCd : TEXCOORD0;
    float3 LightDirV: TEXCOORD1;
    float3 NormV: TEXCOORD2;
    float3 ViewDirV: TEXCOORD3;
    float3 PosW: TEXCOORD4;
};

// -----------------------------------------------------------------------------
// VERTEXSHADERS
// -----------------------------------------------------------------------------

vs2ps VS(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

//------------------------------------------------------------------
// APPLY TRANSFORM TEXTURE TO POSITION AND NORMAL   
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
NormO = mul(NormO, Vrotate(TRow2.b, TRow2.a, TRow3.r));

//Apply translate
PosO.xyz += TRow1.rgb;

    Out.PosW = mul(PosO, tW);

    //inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);
    Out.LightDirV = mul(LightDirW, tV);
    
    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));

    //position (projected)
    Out.PosWVP  = mul(PosO, tWVP);
    Out.TexCd = mul(TexCd, tTex);
    Out.ViewDirV = -normalize(mul(PosO, tWV));
    return Out;
}

// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float foo(float bar)
{
    return bar;
}

float Alpha <float uimin=0.0; float uimax=1.0;> = 1;

float4 PS(vs2ps In): COLOR
{
    //In.TexCd = In.TexCd / In.TexCd.w; // for perpective texture projections (e.g. shadow maps) ps_2_0
    
    float4 col = tex2D(Samp, In.TexCd);

    col.rgb *= PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV);
    col.a *= Alpha;

    return mul(col, tColor);
}


// -----------------------------------------------------------------------------
// TECHNIQUES:
// -----------------------------------------------------------------------------

technique TPhongPoint
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}

technique TFallbackGouraudPointFF
{
    pass P0
    {
        //transformations
        WorldTransform[0]   = (tW);
        ViewTransform       = (tV);
        ProjectionTransform = (tP);

        //material
        MaterialAmbient  = {1, 1, 1, 1};
        MaterialDiffuse  = {1, 1, 1, 1};
        MaterialSpecular = {1, 1, 1, 1};
        MaterialPower    = (lPower);

        //texturing
        Sampler[0] = (Samp);
        TextureTransform[0] = (tTex);
        TexCoordIndex[0] = 0;
        TextureTransformFlags[0] = COUNT2;
        //Wrap0 = U;  // useful when mesh is round like a sphere

        //lighting
        LightEnable[0] = TRUE;
        Lighting       = TRUE;
        SpecularEnable = TRUE;
        
        LightType[0]     = POINT;
        LightAmbient[0]  = (lAmb);
        LightDiffuse[0]  = (lDiff);
        LightSpecular[0] = (lSpec);
        LightPosition[0] = (lPos);
        LightRange[0]    = (lRange);
        LightAttenuation0[0] = (lAtt0);
        LightAttenuation1[0] = (lAtt1);
        LightAttenuation2[0] = (lAtt2);

        //shading
        ShadeMode = GOURAUD;
        VertexShader = NULL;
        PixelShader  = NULL;
    }
}