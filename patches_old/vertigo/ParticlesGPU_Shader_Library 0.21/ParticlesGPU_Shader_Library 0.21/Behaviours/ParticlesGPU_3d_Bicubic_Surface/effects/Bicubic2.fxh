// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//texture size XY
float2 size_source;

//filter texture
texture TexFilter <string uiname="Filter Texture";>;

//filter sampler
sampler1D SampFilter = sampler_state
{
    Texture   = (TexFilter);     //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    addressU = wrap;
    addressV = wrap;
};

double3 filter(double x)
{
  x = frac(x);
  double x2 = x*x;
  double x3 = x2*x;
  double w0 = (  -x3 + 3*x2 - 3*x + 1)/6.0;
  double w1 = ( 3*x3 - 6*x2       + 4)/6.0;
  double w2 = (-3*x3 + 3*x2 + 3*x + 1)/6.0;
  double w3 = x3/6;
  
  double h0 = 1 - w1/(w0+w1) + x;
  double h1 = 1 + w3/(w2+w3) - x;
  
  return double3(h0, h1, w0+w1);
}

bool UseKernelTexture;

//texture lookup
float4 tex2Dbicubic(sampler s, float2 tex)
{

//pixel size XY
  double2 pix = 1.0/size_source;

  //calc filter texture coordinates
  double2 w = tex*size_source-float2(0.5, 0.5);

  // fetch offsets and weights from filter function
  double3 hg_x = UseKernelTexture ? tex1D(SampFilter, w.x ).xyz : filter(-w.x);
  double3 hg_y = UseKernelTexture ? tex1D(SampFilter, w.y ).xyz : filter(-w.y);

  double2 e_x = {pix.x, 0};
  double2 e_y = {0, pix.y};

  // determine linear sampling coordinates
  double2 coord_source10 = tex + hg_x.x * e_x;
  double2 coord_source00 = tex - hg_x.y * e_x;
  double2 coord_source11 = coord_source10 + hg_y.x * e_y;
  double2 coord_source01 = coord_source00 + hg_y.x * e_y;
  coord_source10 = coord_source10 - hg_y.y * e_y;
  coord_source00 = coord_source00 - hg_y.y * e_y;

  // fetch four linearly interpolated inputs
  float4 tex_source00 = tex2D( s, coord_source00 );
  float4 tex_source10 = tex2D( s, coord_source10 );
  float4 tex_source01 = tex2D( s, coord_source01 );
  float4 tex_source11 = tex2D( s, coord_source11 );

  // weight along y direction
  tex_source00 = lerp( tex_source00, tex_source01, hg_y.z );
  tex_source10 = lerp( tex_source10, tex_source11, hg_y.z );

  // weight along x direction
  tex_source00 = lerp( tex_source00, tex_source10, hg_x.z );

  return tex_source00;
}

// -------------------------------------------------------------------------

