// this is a very basic template. use it to start writing your own effects.
// if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

int Index;
int ViewIndex: VIEWPORTINDEX;
int ViewCount: VIEWPORTCOUNT;

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
//float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

float4x4 tTexView <string uiname="Texture View Transform";>;                  //Texture Transform
float4x4 tTexProj <string uiname="Texture Projection Transform";>;                  //Texture Transform
float4x4 tTexViewPort <string uiname="Texture ViewPort Transform";>;                  //Texture Transform

float px = 1.0/1024;
float py = 1.0/1024;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float4 TexCV : TEXCOORD0;
    float4 TexCP : TEXCOORD1;
    float4 TexCS : TEXCOORD2;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

void TransformTex(
    float4 TexC,
    float4x4 tTexView,
    float4x4 tTexProj,
    float4x4 tTexViewPort,
    out float4 VTexC,
    out float4 PTexC,
    out float4 STexC)
{
    VTexC = mul(TexC, tTexView);
    PTexC = mul(VTexC, tTexProj);
    STexC = mul(PTexC, tTexViewPort);
    STexC = mul(STexC,
      float4x4( 0.5,  0.0, 0.0, 0.0,
                0.0, -0.5, 0.0, 0.0,
                0.0,  0.0, 1.0, 0.0,
                0.5,  0.5, 0.0, 1.0 ));
}

vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position, if not in viewport, then resize mesh subset to zero
   if (Index%ViewCount == ViewIndex) {
		Out.Pos = mul(PosO, tWVP);
    }
	else {
		Out.Pos = 0;
	}    
    //transform texturecoordinates
    //Out.TexCd = mul(TexCd, tTex);
    float4 TexC = PosO;
    TexC = mul(TexC, tW);
    TransformTex(TexC, tTexView, tTexProj, tTexViewPort, Out.TexCV, Out.TexCP, Out.TexCS);


    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float InCone(float3 TexCP)
{
    return max(sign(1-abs(TexCP.x)), 0.0) *
           max(sign(1-abs(TexCP.y)), 0.0) *
           max(sign(0.5-abs(TexCP.z-0.5)), 0.0);
}

float4 PS4(vs2ps In): COLOR
{
    In.TexCP.xyz = In.TexCP.xyz / In.TexCP.w;
    float3 col = InCone(In.TexCP);
    //float3 col = TexC;
    In.TexCS.xyz = In.TexCS.xyz / In.TexCS.w;

    float4 c = tex2D(Samp, In.TexCS)*2;

    c += tex2D(Samp, In.TexCS + float2( px, 0 ));
    c += tex2D(Samp, In.TexCS - float2( px, 0 ));
    c += tex2D(Samp, In.TexCS + float2( 0, py ));
    c += tex2D(Samp, In.TexCS - float2( 0, py ));

    col *= c/6;
    return float4(col, 1);
}

float4 PS(vs2ps In): COLOR
{
    In.TexCP.xyz = In.TexCP.xyz / In.TexCP.w;
    float3 col = InCone(In.TexCP);

    In.TexCS.xyz = In.TexCS.xyz / In.TexCS.w;

    col *= tex2D(Samp, In.TexCS);
    return float4(col, 1);
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TProject_sample4neighbours
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS4();
    }
}

technique TProject
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS();
    }
}

technique TFixedFunction
{
    pass P0
    {
        //transforms
        WorldTransform[0]   = (tW);
        ViewTransform       = (tV);
        ProjectionTransform = (tP);

        //texturing
        Sampler[0] = (Samp);
        TextureTransform[0] = (tTexView);
        TexCoordIndex[0] = 0;
        TextureTransformFlags[0] = COUNT2;
        //Wrap0 = U;  // useful when mesh is round like a sphere
        
        Lighting       = FALSE;

        //shaders
        VertexShader = NULL;
        PixelShader  = NULL;
    }
}
