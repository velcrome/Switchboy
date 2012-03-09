//@author: dottore
//@description: Draws a surface using the data position texture. shading by phong directional
//@tags: 3d surface
//@credits: 
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;        //the models world matrix
float4x4 tV: VIEW ;         //view matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION ;
float4x4 tWV: WORLDVIEW ;
float4x4 tWVP: WORLDVIEWPROJECTION ;


float2 XYres <string uiname="Mesh resolution";>;

#include "PhongDirectional.fxh"

//position texture
texture Tex <string uiname="Data Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Position Texture Transform";>;

//Image texture
texture Tex2 <string uiname="Image Texture";>;
sampler SampImage = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};

float4x4 tTexImage: TEXTUREMATRIX <string uiname="Image Texture Transform";>;
float Alpha = 1;

// --------------------------------------------------------------------------------------------------
// STRUCT:
// --------------------------------------------------------------------------------------------------

struct vs2ps
{
    float4 PosWVP: POSITION ;
    float3 NormV: NORMAL ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 ViewDirV: TEXCOORD3 ;

};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS:
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    float4 TexCdPos = mul(TexCd, tTex);

    float4 particleData = tex2Dlod(Samp, TexCdPos);   //position data per vertices

    // position of the vertices before and after in X axis
    float4 particleData1 = tex2Dlod(Samp, float4( TexCdPos.x - (1/XYres.x) ,  TexCdPos.y ,1,1));
    float4 particleData2 = tex2Dlod(Samp, float4( TexCdPos.x + (1/XYres.x) ,  TexCdPos.y ,1,1));
    // position of the vertices before and after in Y axis
    float4 particleData3 = tex2Dlod(Samp, float4( TexCdPos.x ,  TexCdPos.y - (1/XYres.y) ,1,1));
    float4 particleData4 = tex2Dlod(Samp, float4( TexCdPos.x ,  TexCdPos.y + (1/XYres.y) ,1,1));

    float3 tang = particleData2.xyz - particleData1.xyz;
    float3 bitang = particleData3.xyz - particleData4.xyz; 

    float3 NormO = normalize(cross(bitang, tang));
    
    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    PosO.xyz = particleData.xyz;
    //PosO = mul(PosO, tW);

    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));
    Out.ViewDirV = -normalize(mul(PosO, tWV));

    Out.TexCd =  mul(TexCd, tTexImage);
    //then apply the tVP
    Out.PosWVP = mul(PosO, tWVP);
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 col = PhongDirectional(In.NormV, In.ViewDirV, In.LightDirV);
    col *= tex2D(SampImage, In.TexCd);
    col.a *= Alpha;
    return col ;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Surface_PhongDirectional
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
