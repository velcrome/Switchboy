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

//Source 0 texture and sampler 
texture RightFaceMap <string uiname="RightFace";>;
sampler RightFaceMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (RightFaceMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

//Source 1 texture and sampler 
texture LeftFaceMap <string uiname="LeftFace";>;
sampler LeftFaceMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (LeftFaceMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

//Source 2 texture and sampler 
texture UpFaceMap <string uiname="UpFace";>;
sampler UpFaceMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (UpFaceMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

//Source 3 texture and sampler 
texture DownFaceMap <string uiname="DownFace";>;
sampler DownFaceMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (DownFaceMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

//Source 4 texture and sampler 
texture FrontFaceMap <string uiname="FrontFace";>;
sampler FrontFaceMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (FrontFaceMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

//Source 5 texture and sampler 
texture BackFaceMap <string uiname="BackFace";>;
sampler BackFaceMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (BackFaceMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

texture DistortionMap <string uiname="DistortionMap";>;
sampler DistortionMapSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (DistortionMap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};


//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 Src01Cd : TEXCOORD0;
    float2 Src02Cd : TEXCOORD1;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
    float4 Src01Cd : TEXCOORD0,
    float4 Src02Cd : TEXCOORD1)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.Pos = mul(PosO, tWVP);
    
    //transform texturecoordinates
    Out.Src01Cd = mul(Src01Cd, 1);

    //transform the mask texture cordinates
    Out.Src02Cd = mul(Src02Cd, 1);
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 psDomeDistort(vs2ps In):Color
{
	float4 imageColor = tex2D(DistortionMapSamp, In.Src01Cd);
	float3 abs=abs(imageColor.xyz);

	float4 outColor;
	float2 tex2;
	
	if(abs.x>abs.y && abs.x>abs.z)
	{
		tex2.x=0.5f-imageColor.z/imageColor.x*0.5f;		
		if(imageColor.x>0)
		{
			tex2.y=0.5f-imageColor.y/imageColor.x*0.5f;	
			outColor = tex2D(RightFaceMapSamp, tex2);			
		}
		else			   
		{
			tex2.y=0.5f+imageColor.y/imageColor.x*0.5f;			
			outColor = tex2D(LeftFaceMapSamp, tex2);			
		}
	}
	else if(abs.y>abs.x && abs.y>abs.z)
	{
		float l = imageColor.y*2;
		tex2.x=0.5f+imageColor.x/l;	
		if(imageColor.y>0) 
		{
			tex2.y=0.5f+imageColor.z/l;			
			outColor = tex2D(UpFaceMapSamp, tex2);	
		}
		else			   
		{
			tex2.y=0.5f-imageColor.z/l;				
			outColor = tex2D(DownFaceMapSamp, tex2);		
		}
	}
	else
	{
		float l = imageColor.z*2;
		tex2.x=0.5f+imageColor.x/l;
		if(imageColor.z>0) 
		{
			tex2.y=0.5f-imageColor.y/l;			
			outColor = tex2D(FrontFaceMapSamp, tex2);			
		}
		else			  
		{
			tex2.y=0.5f+imageColor.y/l;			
			outColor = tex2D(BackFaceMapSamp, tex2);			
		}			
	}
			
	outColor.rgb = outColor.rgb*imageColor.w;
	outColor.a=1.f;
	return outColor;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Blend
{
    pass  P0
    {
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 psDomeDistort();
    }
}
