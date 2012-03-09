//@author: dottore
//@description: Draws a surface using the data position texture. shading by normals
//@tags: 3d surface
//@credits: 

//transforms
float4x4 tW: WORLD ;        //the models world matrix
float4x4 tV: VIEW ;         //view matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION ;
float4x4 tWV: WORLDVIEW ;
float4x4 tWVP: WORLDVIEWPROJECTION ;


float2 XYres <string uiname="Mesh resolution";>;

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

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

// --------------------------------------------------------------------------------------------------
// STRUCT:
// --------------------------------------------------------------------------------------------------

struct vs2ps
{
    float4 PosWVP: POSITION ;
    float3 NormV: NORMAL ;
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
    
    TexCd = mul(TexCd, tTex);

    float4 particleData = tex2Dlod(Samp, TexCd);   //position data per vertices
    // position of the vertices before and after in X axis
    float4 particleData1 = tex2Dlod(Samp, float4( TexCd.x - (1/XYres.x) ,  TexCd.y ,1,1));
    float4 particleData2 = tex2Dlod(Samp, float4( TexCd.x + (1/XYres.x) ,  TexCd.y ,1,1));
    // position of the vertices before and after in Y axis
    float4 particleData3 = tex2Dlod(Samp, float4( TexCd.x ,  TexCd.y - (1/XYres.y) ,1,1));
    float4 particleData4 = tex2Dlod(Samp, float4( TexCd.x ,  TexCd.y + (1/XYres.y) ,1,1));

    float3 tang = particleData2.xyz - particleData1.xyz;
    float3 bitang = particleData3.xyz - particleData4.xyz; 
    
    //apply the tW
    PosO.xyz = particleData.xyz;
    //apply the tVP
    Out.PosWVP = mul(PosO, tWVP);

    //normals in world space
    Out.NormV = normalize(cross(tang, bitang));
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    return float4 (In.NormV/2 + 0.5 ,1);
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Surface_Normals
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
