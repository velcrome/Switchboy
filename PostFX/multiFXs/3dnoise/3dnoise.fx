//shading:         constant color
//lighting model:  none
//lighting type:   none

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)
float4x4 tWVP: WORLDVIEWPROJECTION;

//material properties
texture permTexture2d;
texture permGradTexture;

sampler permSampler2d = sampler_state
{
    texture =  <permTexture2d>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MAGFILTER = POINT;
    MINFILTER = POINT;
    MIPFILTER = NONE;
};

sampler permGradSampler = sampler_state
{
    texture = <permGradTexture>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MAGFILTER = POINT;
    MINFILTER = POINT;
    MIPFILTER = NONE;
};

float4x4 tTex;



int octaves =1;
float lacunarity = 1;
float gain = 0.05;
float offset = 1.0;
//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos : POSITION;
    float4 TexCd : TEXCOORD0;
};
float3 fade(float3 t)
{
	return t * t * t * (t * (t * 6 - 15) + 10); // new curve
}

float4 perm2d(float2 p)
{
	return tex2D(permSampler2d, p);
}

float gradperm(float x, float3 p)
{
	return dot(tex1D(permGradSampler, x), p);
}


float inoise(float3 p)
{
	float3 P = fmod(floor(p), 256.0);
  	p -= floor(p);
	float3 f = fade(p);

	P = P / 256.0;


	float4 AA = perm2d(P.xy) + P.z;


  	return lerp( lerp( lerp( gradperm(AA.x, p ),
                             gradperm(AA.z, p + float3(-1, 0, 0) ), f.x),
                       lerp( gradperm(AA.y, p + float3(0, -1, 0) ),
                             gradperm(AA.w, p + float3(-1, -1, 0) ), f.x), f.y),

                 lerp( lerp( gradperm(AA.x+(1.0 / 256.0), p + float3(0, 0, -1) ),
                             gradperm(AA.z+(1.0 / 256.0), p + float3(-1, 0, -1) ), f.x),
                       lerp( gradperm(AA.y+(1.0 / 256.0), p + float3(0, -1, -1) ),
                             gradperm(AA.w+(1.0 / 256.0), p + float3(-1, -1, -1) ), f.x), f.y), f.z);
}


float fBm(float3 p, int octaves, float lacunarity = 2.0, float gain = 0.5)
{
	float freq = 1.0f,
	      amp  = 0.5f;
	float sum  = 0.0f;
	for(int i=0; i < octaves; i++) {
		sum += inoise(p*freq)*amp;
		freq *= lacunarity;
		amp *= gain;
	}
	return sum;
}

float turbulence(float3 p, int octaves, float lacunarity = 2.0, float gain = 0.5)
{
	float sum = 0;
	float freq = 1.0, amp = 1.0;
	for(int i=0; i < octaves; i++) {
		sum += abs(inoise(p*freq))*amp;
		freq *= lacunarity;
		amp *= gain;
	}
	return sum;
}


float ridge(float h, float offset)
{
    h = abs(h);
    h = offset - h;
    h = h * h;
    return h;
}

float ridgedmf(float3 p, int octaves, float lacunarity, float gain = 0.05, float offset = 1.0)
{
	float sum = 0;
	float freq = 1.0;
	float amp = 0.5;
	float prev = 1.0;
	for(int i=0; i < octaves; i++)
	{
		float n = ridge(inoise(p*freq), offset);
		sum += n*amp*prev;
		prev = n;
		freq *= lacunarity;
		amp *= gain;
	}
	return sum;
}
// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 Pos : POSITION,
    float4 TexCd : TEXCOORD0)
{

    vs2ps Out = (vs2ps)0;


    Out.Pos = mul(Pos, tWVP);
    Out.TexCd = mul(Pos,tTex);



    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
 float3 p = In.TexCd;

 float4 result = ridgedmf(p,octaves,lacunarity, gain, offset) ;
 result.a =1;
 return result;
}
           
    
 float4 PS2(vs2ps In): COLOR
{
  float3 p = In.TexCd;

  float4 result = turbulence(p,octaves, gain, offset);
   result.a =1;
 return result;
}
 float4 PS3(vs2ps In): COLOR
{
  float3 p = In.TexCd;

  float4 result = fBm(p,octaves,lacunarity, gain);
   result.a =1;
 return result;
}
// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique multifractal_noise
{
    pass P0
    {

        VertexShader = compile vs_1_1 VS();
        PixelShader = compile ps_3_0 PS();
    }
}

technique turbulency
{

    pass P0
    {

        VertexShader = compile vs_1_1 VS();
        PixelShader = compile ps_3_0 PS2();
    }
}
technique fractal_sum
{

    pass P0
    {

        VertexShader = compile vs_1_1 VS();
        PixelShader = compile ps_3_0 PS3();
    }
}
