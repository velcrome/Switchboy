
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (DX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (DX9)
float4x4 tWVP: WORLDVIEWPROJECTION;

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
texture Tex <string uiname="Texture";>;
float4x4 tTex <string uiname="Texture Transform";>;                  //Texture Transform
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //set the sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
float4x4 tColor  <string uiname="Color Transform";>;

struct VS_OUTPUT
{
    float4 Pos    : POSITION;
    float4 TexC : TEXCOORD0;

};


///////////////////////////////////////////////////// vertex shaders //////////




VS_OUTPUT VS_RadialBlur(float4 Pos : POSITION, float4 TexC : TEXCOORD0 )
                                           {
			   		
    VS_OUTPUT OUT= (VS_OUTPUT)0;
    OUT.Pos = mul(Pos,tWVP);
    OUT.TexC = mul(TexC  - Center,tTex);
    return OUT;
}


//////////////////////////////////////////////////////////// pixel shaders /////


half4 PS_RadialBlur(float2 TexC: TEXCOORD0,uniform sampler2D tex,
			   		uniform int nsamples): COLOR

{

    half4 c = 0;
    // this loop will be unrolled by compiler and the constants precalculated:
    for(int i=0; i<nsamples; i++) {
    	float scale = BlurStart + BlurWidth*(i/(float) (nsamples-1));
    	c += tex2D(Samp, TexC.xy * scale + Center );
   	}
   	c /= nsamples;
    return c;
} 




////////////////////////////////////////////////////////// techniques /////////


technique RadialBlur {
    pass p0  {
		
		VertexShader = compile vs_2_0 VS_RadialBlur();
		PixelShader  = compile ps_2_0 PS_RadialBlur(Samp,16);
    }
}




