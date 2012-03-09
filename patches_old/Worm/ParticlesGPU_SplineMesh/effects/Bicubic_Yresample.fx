// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture Tex <string uiname="Texture";>;

//samplers
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    addressU = clamp;
    addressV = clamp;

};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

// --------------------------------------------------------------------------------------------------
// PARAMETERS:     (bicubic function)
// --------------------------------------------------------------------------------------------------

//texture size XY
float2 size_source;

//filter texture
texture TexFilter <string uiname="Filter Texture";>;

//filter sampler
sampler1D SampFilter = sampler_state
{
    Texture   = (TexFilter);     //apply a texture to the sampler
    MipFilter = linear;//sampler states
    MinFilter = linear;
    MagFilter = linear;
    addressU = wrap;
    addressV = wrap;
};

float3 filter(float x)
{
  x = frac(x);
  float x2 = x*x;
  float x3 = x2*x;
  float w0 = (  -x3 + 3*x2 - 3*x + 1)/6.0;
  float w1 = ( 3*x3 - 6*x2       + 4)/6.0;
  float w2 = (-3*x3 + 3*x2 + 3*x + 1)/6.0;
  float w3 = x3/6;
  
  float h0 = 1 - w1/(w0+w1) + x;
  float h1 = 1 + w3/(w2+w3) - x;
  
  return float3(h0, h1, w0+w1);
}

bool UseKernelTexture;


//texture lookup
float4 tex2Dbicubic(sampler s, float2 tex)
{

//pixel size XY
  float2 pix = 1.0/size_source;

  //calc filter texture coordinates
  float2 w = tex*size_source-float2(0.5, 0.5);

  // fetch offsets and weights from filter function
  float3 hg_x = 0;//tex1D(SampFilter, w.x ).xyz;
  float3 hg_y = UseKernelTexture ? tex1D(SampFilter, w.y ).xyz : filter(-w.y); ////////tex1D(SampFilter, w.y ).xyz;

  float2 e_x = 0;//////////////////////// {pix.x, 0};
  float2 e_y = {0, pix.y};

  // determine linear sampling coordinates
  float2 coord_source10 = tex ;//////////////////////+ hg_x.x * e_x;
  float2 coord_source00 = tex ;///////////////////////- hg_x.y * e_x;
  float2 coord_source11 = 0;//coord_source10 + hg_y.x * e_y;
  float2 coord_source01 = coord_source00 + hg_y.x * e_y;
  coord_source10 = coord_source10 - hg_y.y * e_y;
  coord_source00 = coord_source00 - hg_y.y * e_y;

  // fetch four linearly interpolated inputs
  float4 tex_source00 = tex2D( s, coord_source00 );
  float4 tex_source10 = tex2D( s, coord_source10 );
  float4 tex_source01 = tex2D( s, coord_source01 );
  float4 tex_source11 = tex2D( s, coord_source11 );

  // weight along y direction
  tex_source00 = lerp( tex_source00, tex_source01, hg_y.z );
  //tex_source10 = lerp( tex_source10, tex_source11, hg_y.z );

  // weight along x direction
  tex_source00 = lerp( tex_source00, tex_source10, hg_x.z );

  return tex_source00;
}

// -------------------------------------------------------------------------

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0
    )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.Pos = mul(PosO, tWVP);

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PSbic(vs2ps In): COLOR
{     
    // Position
    return tex2Dbicubic(Samp, In.TexCd);
}


technique Bicubic
{
    pass p0
    {
		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PSbic();
    }
}
