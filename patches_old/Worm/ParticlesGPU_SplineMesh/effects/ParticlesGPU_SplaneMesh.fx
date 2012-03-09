//@author: dottore
//@description: Places GPUmesh along a GPU spline . shading by phong directional
//@tags: 3d surface spline
//@credits: 
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;        //the models world matrix
float4x4 tV: VIEW ;         //view matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION ;
float4x4 tWV: WORLDVIEW ;

#include "Phong_Directional-Point.fxh"


//position texture
texture Tex <string uiname="Y Resampled Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = clamp;//mirror;
    AddressV = clamp;//mirror;
};

//normal texture
texture Tex2 <string uiname="Direction Texture";>;
sampler SampDir = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = clamp;//mirror;
    AddressV = clamp;//mirror;
};

float4x4 TransformW;
float4 cAmb : COLOR <String uiname="Color";>  = {1, 1, 1, 1};


// --------------------------------------------------------------------------------------------------
// --------FUNCTIONS---------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

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
                    0             , 0    , 0              , 0);
  }

//##############################################################################
// CONSTANT ####################################################################
//##############################################################################

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------
struct vs2ps0
{
    float4 PosWVP: POSITION ;
    float3 camera_position : TEXCOORD3 ;
    float3 camera_normal   : TEXCOORD4 ;
    float4 TexCd : TEXCOORD0 ;
};

// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

vs2ps0 VS0(
    float4 PosO : POSITION ,
    float3 NormO : NORMAL ,
    float TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps0 Out = (vs2ps0)0;

    PosO = mul(PosO, TransformW); //transform to orient the mesh
    NormO = mul(NormO, TransformW);
    
    // Placement UV
    float4 PlaceCoords = float4(TexCd,PosO.z+0.5, 0, 1);
    
    // get position and direction data from textures
    float4 particleData = tex2Dlod(Samp, PlaceCoords);   
    float3 SplineDirection = tex2Dlod(SampDir, PlaceCoords); 
    
    // get pitch and yaw from direction vector
    float pitch = asin(SplineDirection.y)/TwoPi;
    float yaw = atan2(-SplineDirection.x, -SplineDirection.z)/ TwoPi;
 
    // Evaluate rotation matrix
    float4x4 rotMatrix = Vrotate(pitch, yaw,0);
    
    // POSITION
    PosO.yx *= particleData.a;
    PosO.z = 0;
	float4 PosW = mul(PosO, rotMatrix) + float4(particleData.xyz,1);


    // NORMAL
    NormO = mul(NormO, rotMatrix);
    
    //then apply the tVP
    Out.PosWVP = mul(PosW, tVP);
    
    Out.camera_position = mul(PosW, tWV);

    Out.camera_normal = mul(NormO, tWV);

    return Out;
}


// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float4 PS0(vs2ps0 In): COLOR
{
    float4 color = 1;

    return color;
}

//##############################################################################
// PHONG DIRECTIONAL ###########################################################
//##############################################################################

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------
struct vs2ps1
{
    float4 PosWVP: POSITION ;
    float3 NormV: NORMAL ;
    float3 camera_position : TEXCOORD3 ;
    float3 camera_normal   : TEXCOORD4 ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 ViewDirV: TEXCOORD2 ;
};
// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

vs2ps1 VS1(
    float4 PosO : POSITION ,
    float3 NormO : NORMAL ,
    float TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps1 Out = (vs2ps1)0;

    PosO = mul(PosO, TransformW); //transform to orient the mesh
    NormO = mul(NormO, TransformW);
    
    // Placement UV
    float4 PlaceCoords = float4(TexCd,PosO.z+0.5, 0, 1);
    
    // get position and direction data from textures
    float4 particleData = tex2Dlod(Samp, PlaceCoords);   
    float3 SplineDirection = tex2Dlod(SampDir, PlaceCoords); 
    
    // get pitch and yaw from direction vector
    float pitch = asin(SplineDirection.y)/TwoPi;
    float yaw = atan2(-SplineDirection.x, -SplineDirection.z)/ TwoPi;
 
    // Evaluate rotation matrix
    float4x4 rotMatrix = Vrotate(pitch, yaw,0);
    
    // POSITION
    PosO.yx *= particleData.a;
    PosO.z = 0;
//    PosO = mul(PosO, TransformW); //transform to orient the mesh
	
    float4 PosW = mul(PosO, rotMatrix) + float4(particleData.xyz,1);


    // NORMAL
    NormO = mul(NormO, rotMatrix);

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));
    Out.ViewDirV = -normalize(mul(PosW, tWV));

    //then apply the tVP
    Out.PosWVP = mul(PosW, tVP);
    
    Out.camera_position = mul(PosW, tWV);

    Out.camera_normal = mul(NormO, tWV);

    
    return Out;
}


// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float4 PS1(vs2ps1 In): COLOR
{
    float4 color = PhongDirectional(In.NormV, In.ViewDirV, In.LightDirV);

    return color;
}

//##############################################################################
// PHONG POINT #################################################################
//##############################################################################

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------

struct vs2ps2
{
    float4 PosWVP: POSITION ;
    float4 PosW: TEXCOORD2 ;
    float3 camera_position : TEXCOORD4 ;
    float3 camera_normal   : TEXCOORD5 ;
    float3 NormV: NORMAL ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 ViewDirV: TEXCOORD3 ;

};

// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

// PLACE and DEFORM technique
vs2ps2 VS2(
    float4 PosO : POSITION ,
    float3 NormO : NORMAL ,
    float TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps2 Out = (vs2ps2)0;

    PosO = mul(PosO, TransformW); //transform to orient the mesh
    NormO = mul(NormO, TransformW);
    
    // Placement UV
    float4 PlaceCoords = float4(TexCd,PosO.z+0.5, 0, 1);
    
    // get position and direction data from textures
    float4 particleData = tex2Dlod(Samp, PlaceCoords);   
    float3 SplineDirection = tex2Dlod(SampDir, PlaceCoords); 
    
    // get pitch and yaw from direction vector
    float pitch = asin(SplineDirection.y)/TwoPi;
    float yaw = atan2(-SplineDirection.x, -SplineDirection.z)/ TwoPi;
 
    // Evaluate rotation matrix
    float4x4 rotMatrix = Vrotate(pitch, yaw,0);
    
    // POSITION
    PosO.yx *= particleData.a;
    PosO.z = 0;
    Out.PosW = mul(PosO, rotMatrix)+ float4(particleData.xyz,1);

    // NORMAL
    NormO = mul(NormO, rotMatrix);

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);

    //inverse light direction in view space
    Out.LightDirV = mul(LightDirW, tV);
    Out.ViewDirV = -normalize(mul(Out.PosW, tWV));

    //then apply the tVP
    Out.PosWVP = mul(Out.PosW, tVP);
    
    Out.camera_position = mul(Out.PosW, tWV);

    Out.camera_normal = mul(NormO, tWV);

    
    return Out;
}


// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float4 PS2(vs2ps2 In): COLOR
{
    float4 color = PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV);

    return color;
}



// -----------------------------------------------------------------------------
// TECHNIQUES:
// -----------------------------------------------------------------------------

technique Constant
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS0();
        PixelShader  = compile ps_3_0 PS0();
    }
}

technique PhongDirectionalTechnique
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS1();
        PixelShader  = compile ps_3_0 PS1();
    }
}

technique PhongPointTechnique
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS2();
        PixelShader  = compile ps_3_0 PS2();
    }
}




