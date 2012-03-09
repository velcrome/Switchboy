// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

float4x4 tW: WORLD;
float4x4 tV: VIEW;
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//TEXTURES/////////////////////////////

//SOURCE 1 /////////////////////////////////
texture Tex <string uiname="SourceTexture1";>;
float4x4 tTex: TEXTUREMATRIX <string uiname="Source1Transform";>;
sampler Samp = sampler_state
{
    Texture   = (Tex);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = Clamp;
    AddressV  = Clamp;
};


//SOURCE 2 /////////////////////////////////
texture Tex2 <string uiname="SourceTexture2";>;
float4x4 tTex2: TEXTUREMATRIX <string uiname="Source2Transform";>;
sampler Samp2 = sampler_state
{
    Texture   = (Tex2);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    //AddressU  = Clamp;
    AddressU  = mirror;
    AddressV  = mirror;
};

//DOTS TEXTURE /////////////////////////////
#define IMG_DIVS 4.0
#define DOWNSIZE (1.0/IMG_DIVS)

texture DotTex <float3 Dimensions = { 16.0, 16.0, 32.0 };string UIName = "DotVolumeTexture";>;
sampler3D DotSampler = sampler_state
{
    Texture = (DotTex);
    AddressU  = Wrap;
    AddressV  = Wrap;
    AddressW  = Clamp;
    MinFilter = Linear;
    MipFilter = Linear;
    MagFilter = Linear;
};

//NOISY TEXTURE //////////////////////////////
texture Texnoise <string uiname="Texturenoise";>;
float4x4 tTexnoise: TEXTUREMATRIX <string uiname="Texturenoise Transform";>;
sampler Sampnoise = sampler_state
{
    Texture   = (Texnoise);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};


//tweakables////
//pin for the amount of mask to use as alpha
float Src02Alpha
<
    string uiname="Source2 Transparency";
    float uimin=0.0;
    float uimax=1.0;
> = 0.0;


//material properties
float4 cAmb : COLOR <String uiname="Color";>  = {1, 1, 1, 1};

//sobel edge detection
int TexWidth <string uiname="Texture Width";> = 512;
int TexHeight <string uiname="Texture Heihgt";> = 512;

float thresh;

//blur
float2 Center = { 0.5, 0.5 };

float BlurStart <
    string UIName = "Blur start";
    string UIWidget = "slider";
    float UIMin = 0.0f; float UIMax = 1.0f; float UIStep = 0.01f;
> = 1.0f;

float BlurWidth <
    string UIName = "Blur width";
    string UIWidget = "slider";
    float UIMin = -1.0f; float UIMax = 1.0f; float UIStep = 0.01f;
> = -0.2f;

//dots
float4 make_tones(float3 Pos : POSITION, float3 Size : PSIZE) : COLOR {
	float2 delta = Pos.xy - float2(0.5,0.5);
	float d = dot(delta,delta);
	float rSquared = (Pos.z*Pos.z)/2.0;
	float n2 = (d<rSquared) ? 1.0 : 0.0;
	return float4(n2,n2,n2,1.0);
	return float4(Pos,1.0);
}

float DotsNumber =  40.0 ;

//noise
float displace;

float4x4 tCol ;
float4x4 tCol2 ;

//------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
struct vs2ps
{
    float4 Pos        : POSITION;
    float4 TexCd      : TEXCOORD0;
    float4 TexCd2     : TEXCOORD1;
    float4 TexCddot   : TEXCOORD2;
    float4 TexCdnoise : TEXCOORD3;
};


vs2ps VS(
    float4 Pos         : POSITION,
    float4 TexCd       : TEXCOORD0,
    float4 TexCd2      : TEXCOORD1,
    float4 TexCddot    : TEXCOORD2,
    float4 TexCdnoise  : TEXCOORD3
   )
{
    vs2ps Out = (vs2ps)0;

    Out.Pos = mul(Pos, tWVP);
    Out.TexCdnoise = mul(TexCd, tTexnoise);
    Out.TexCd2 = mul(TexCd, tTex2);
    Out.TexCd = mul(TexCd, tTex);

    return Out;
    }

////VS RADIAL BLUR////////////////////////////////////////////////////////////////////////////////////////
 vs2ps VS_RadialBlur(
 float4 Pos : POSITION,
 float4 TexCd : TEXCOORD0 )
 {
    vs2ps OUT= (vs2ps)0;
    
    OUT.Pos = mul(Pos,tWVP);
    OUT.TexCd = mul(TexCd  - Center,tTex);
    
    return OUT;
}

////VS QUAD////////////////////////////////////////////////////////////////////////////////////////
struct vertexOutput {
    float4 HPosition: POSITION;
    float4 UV  : TEXCOORD0;
};

vertexOutput VS_Quad(float4 Position : POSITION,float4 TexCoord : TEXCOORD0)
{
    vertexOutput OUT = (vertexOutput)0;
    OUT.HPosition = mul((float4(Position)),tWVP);
    OUT.UV = mul(TexCoord,tTex);

    return OUT;
}

// -------------------------------------------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// -------------------------------------------------------------------------------------------------------------------------------------

//Blend////////////////////////////////////////////////
float4 PS_Blend(vs2ps In): COLOR
{
    float4 Col = { 0.0, 0.0, 0.0, 1.00000 };

    float4 Col1 = tex2D(Samp, In.TexCd);
    float4 Col2 = tex2D(Samp2, In.TexCd2);

    Col = lerp(Col2, Col1, 1-Src02Alpha);

    return mul(Col,tCol);
}

//Add//////////////////////////////////////////////////
float4 PS_Add(vs2ps In): COLOR
{
    float4 Col = { 0.0, 0.0, 0.0, 1.00000 };

    float4 Col1 = tex2D(Samp, In.TexCd);
    float4 Col2 = tex2D(Samp2, In.TexCd2);
    
    float4 temp = {0.0,0.0,0.0,1.0};

    temp = Col1 + Col2;

    if (temp.r > 1.0){temp.r = 1.0;}
    if (temp.g > 1.0){temp.g = 1.0;}
    if (temp.b > 1.0){temp.b = 1.0;}

    Col = lerp(temp, Col1, 1-Src02Alpha);

    return mul(Col,tCol);

}

//Multiply//////////////////////////////////////////////////
float4 PS_Multiply(vs2ps In): COLOR
{

    float4 Col = { 0.0, 0.0, 0.0, 1.00000 };
    //source texture lookup
    float4 Col1 = tex2D(Samp, In.TexCd);
    // the mask texture lookup
    float4 Col2 = tex2D(Samp2, In.TexCd2);

    Col2.r = Col2.r * Col1.r;
    Col2.g = Col2.g * Col1.g;
    Col2.b = Col2.b * Col1.b;

    Col.r = lerp(Col2.r, Col1.r, 1-Src02Alpha);
    Col.g = lerp(Col2.g, Col1.g, 1-Src02Alpha);
    Col.b = lerp(Col2.b, Col1.b, 1-Src02Alpha);
    Col.a = lerp(Col2.a, Col1.a, 1-Src02Alpha);

    return mul(Col,tCol);
}

//Mask1//////////////////////////////////////////////////
float4 PS_Mask(vs2ps In): COLOR
{

    float4 col = tex2D(Samp, In.TexCd)*cAmb;
    float4 col2 = tex2D(Samp2, In.TexCd2)*cAmb;
    float4 tcol2 = mul(col2,tCol2);

     float bw = 0.2989*col2.r + 0.5870*col2.g + 0.1140*col2.b;

    //col = bw < thresh ? col : col2;

    float4 col3 = lerp(col, tcol2, saturate(bw*(1/thresh)));
    return mul(col3,tCol);
}

//SobelEdge//////////////////////////////////////////////////
float4 sobelEdgeDetection(float2 cTex, sampler sTex, float width, float height)
{
	width  = 1 /float (width/2.0);
	height = 1 /float (height/2.0);

	float2 sampleOffsets[8] ={
					-width,	-height, 	// upper row
					 0.0,		-height,
					 width,	-height,
					-width,	 0.0,		// center row
					 width,	 0.0,
					-width,	 height,	// bottom row
					 0.0,		 height,
					 width,	 height,
				};


int i =0;
float4 c = .5;
float2 texCoords;
float4 texSamples[8];
float4 vertGradient;
float4 horzGradient;


	for(i =0; i < 8; i++)
	{
		texCoords = cTex + sampleOffsets[i]; // add sample offsets stored in c10-c17 (inclusive)
		// take sample
		texSamples[i] = tex2D(sTex, texCoords);
		// convert to b&w
		texSamples[i] = dot(texSamples[i], .333333f);
	}

	// VERTICAL Gradient
	vertGradient = -(texSamples[0] + texSamples[5] + 2*texSamples[3]);
	vertGradient += (texSamples[2] + texSamples[7] + 2*texSamples[4]);
	// Horizontal Gradient
	horzGradient = -(texSamples[0] + texSamples[2] + 2*texSamples[1]);
	horzGradient += (texSamples[5] + texSamples[7] + 2*texSamples[6]);

	// we could approximate by adding the abs value..but we have the horse power

	c = sqrt( horzGradient*horzGradient + vertGradient*vertGradient );
	return c;

}

float4 PS_Sobel(float2 TexCd: TEXCOORD0): COLOR0
{
   float4 c = sobelEdgeDetection(TexCd, Samp, float(TexWidth), float(TexHeight));
   return c;
}

//RADIAL BLUR///////////////////////////////////////////////////////
half4 PS_RadialBlur(float2 TexCd: TEXCOORD0,uniform sampler2D tex,
			   		uniform int nsamples): COLOR
{
    half4 c = 0;
    // this loop will be unrolled by compiler and the constants precalculated:
    for(int i=0; i<nsamples; i++) {
    	float scale = BlurStart + BlurWidth*(i/(float) (nsamples-1));
    	c += tex2D(Samp, TexCd.xy * scale + Center );}
   	c /= nsamples;
   	
    return mul(c,tCol);
}

//TONES///////////////////////////////////////////////////////////////
float4 PS_Tone(vs2ps IN) : COLOR
{

    float4 scnC = tex2D(Samp,IN.TexCd);//+tex2D(Samp2,IN.TexCd2);
    float lum = dot(float3(.2,.7,.1),scnC.xyz);
    float3 lx = float3((DotsNumber*IMG_DIVS*IN.TexCd.xy),lum);
    float4 dotC = tex3D(DotSampler,lx);//+tex2D(Samp,IN.TexCd2);
    float4 result = float4(dotC.xyz,1.0);
    float4 col = result*scnC;
    //float4 col2 = tex2D(Samp2, IN.TexCd2);
    //float4 col3 = col + col2;
    return mul(col,tCol);
}

//DISPLACE/////////////////////////////////////////////////////////////
float4 PS_Displace(vs2ps In) : COLOR
{
       float2 disp = displace*(((float4)tex2D(Sampnoise, In.TexCdnoise)));
       float4 texCol = tex2D(Samp,In.TexCd + disp);
       float4 col = mul(texCol,tCol);
       return col;
}

//Difference////////////////////////////////////////////////
float4 PS_Difference(vs2ps In): COLOR
{
    float4 Col = { 0.0, 0.0, 0.0, 1.00000 };

    float4 Col1 = tex2D(Samp, In.TexCd);
    float4 Col2 = tex2D(Samp2, In.TexCd2);
    float4 temp = {0.0,0.0,0.0,1.0};

    temp.r = abs(Col1.r-Col2.r);
    temp.g = abs(Col1.g-Col2.g);
    temp.b = abs(Col1.b-Col2.b);

    Col = lerp(temp, Col1, 1-Src02Alpha);
    return mul(Col,tCol);
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Blend
{
    pass  P0
    {
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 PS_Blend();
    }
}

technique Add
{
    pass  P0
    {
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 PS_Add();
    }
}

technique Multiply
{
    pass  P0
    {
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 PS_Multiply();
    }
}

technique Mask {
pass P0
{
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS_Mask();
    }
}

technique SobelEdge {
pass P0
{
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS_Sobel();
    }
}

technique RadialBlur {
pass p0
{
		
        VertexShader = compile vs_2_0 VS_RadialBlur();
        PixelShader  = compile ps_2_0 PS_RadialBlur(Samp,16);
    }
}

technique Halftone {
pass p0
{
         VertexShader = compile vs_2_0 VS_Quad();
         PixelShader = compile ps_2_0 PS_Tone();
    }
}

technique Displace {
pass p0
{
         VertexShader = compile vs_2_0 VS();
         PixelShader  = compile ps_2_a PS_Displace();
    }
}

technique Difference
{
    pass  P0
    {
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 PS_Difference();
    }
}

//EOF//////////////////////////////////////////////////////////////////////////////////////////////////////////
