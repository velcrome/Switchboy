//@author: dottore
//@description: A simple combination of vertex and pixel shaders with velvety edge effects.
//              Great for any model that needs that "feeling of softness."
//@tags: soft, organic,point-light
//@credits: nVidia


/*********************************************************************NVMH3****
*******************************************************************************
$Revision: #4 $

Copyright NVIDIA Corporation 2008
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
*AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL NVIDIA OR ITS SUPPLIERS
BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY
LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF
NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

/*****************************************************************/
/*** EFFECT-SPECIFIC CODE BEGINS HERE ****************************/
/*****************************************************************/


/******* Lighting Macros *******/
/** To use "Object-Space" lighting definitions, change these two macros: **/
#define LIGHT_COORDS "World"
// #define OBJECT_SPACE_LIGHTS /* Define if LIGHT_COORDS is "Object" */

/**** UNTWEAKABLES: Hidden & Automatically-Tracked Parameters **********/

// transform object vertices to world-space:
float4x4 gWorldXf : World < string UIWidget="None"; >;
// transform object normals, tangents, & binormals to world-space:
float4x4 gWorldITXf : WorldInverseTranspose < string UIWidget="None"; >;
// transform object vertices to view space and project them in perspective:
float4x4 gWvpXf : WorldViewProjection < string UIWidget="None"; >;
// provide tranform from "view" or "eye" coords back to world-space:
float4x4 gViewIXf : ViewInverse < string UIWidget="None"; >;

/************* TWEAKABLES **************/

/// Point Lamp 0 ////////////
float3 gLamp0Pos : POSITION <
    string Object = "PointLight0";
    string UIName =  "Lamp 0 Position";
    string Space = (LIGHT_COORDS);
> = {-0.5f,2.0f,1.25f};

float4 gLamp0Color  : COLOR <String uiname="Lamp Specular";>  = {0.15, 0.15, 0.15, 1};


// surface color

float4 gSurfaceColor  : COLOR <String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};


float4 gFuzzySpecColor  : COLOR <String uiname="Fuzzy Color";>  = {0.15, 0.15, 0.15, 1};

float4 gSubColor  : COLOR <String uiname="Subtract Color";>  = {0.15, 0.15, 0.15, 1};


float gRollOff <
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.05;
	string UIName = "Edge Rolloff";
> = 0.3;

///

texture gColorTexture : DIFFUSE <
    string ResourceName = "default_color.dds";
    string UIName =  "Diffuse Texture";
    string ResourceType = "2D";
>;

sampler2D gColorSampler = sampler_state {
    Texture = <gColorTexture>;
#if DIRECT3D_VERSION >= 0xa00
    Filter = MIN_MAG_MIP_LINEAR;
#else /* DIRECT3D_VERSION < 0xa00 */
    MinFilter = Linear;
    MipFilter = Linear;
    MagFilter = Linear;
#endif /* DIRECT3D_VERSION */
    AddressU = Wrap;
    AddressV = Wrap;
};  

// shared shadow mapping supported in Cg version

/************* DATA STRUCTS **************/

/* data from application vertex buffer */
struct appdata {
    float3 Position	: POSITION;
    float4 UV		: TEXCOORD0;
    float4 Normal	: NORMAL;
    float4 Tangent	: TANGENT0;
    float4 Binormal	: BINORMAL0;
};

/* data passed from vertex shader to pixel shader */
struct vertexOutput {
    float4 HPosition	: POSITION;
    float2 UV		: TEXCOORD0;
    // The following values are passed in "World" coordinates since
    //   it tends to be the most flexible and easy for handling
    //   reflections, sky lighting, and other "global" effects.
    float3 LightVec	: TEXCOORD1;
    float3 WorldNormal	: TEXCOORD2;
    float3 WorldTangent	: TEXCOORD3;
    float3 WorldBinormal : TEXCOORD4;
    float3 WorldView	: TEXCOORD5;
};

/* data passed from vertex shader to pixel shader */
struct shadedVertexOutput {
    float4 HPosition	: POSITION;
    float2 UV		: TEXCOORD0;
    float4 diffCol	: COLOR0;
    float4 specCol	: COLOR1;
};

/*********** vertex shader ******/

shadedVertexOutput velvetVS(appdata IN,
    uniform float4x4 WorldITXf, // our four standard "untweakable" xforms
	uniform float4x4 WorldXf,
	uniform float4x4 ViewIXf,
	uniform float4x4 WvpXf,
    uniform float3 SurfaceColor,
    uniform float3 FuzzySpecColor,
    uniform float3 SubColor,
    uniform float RollOff,
    uniform float3 LampPos
) {
    shadedVertexOutput OUT;
    float3 Nn = normalize(mul(IN.Normal,WorldITXf).xyz);
    float4 Po = float4(IN.Position.xyz,1);
    OUT.HPosition = mul(Po,WvpXf);
    float3 Pw = mul(Po,WorldXf).xyz;
    float3 Ln = normalize(LampPos - Pw);
    float ldn = dot(Ln,Nn);
    float diffComp = max(0,ldn);
    float3 diffContrib = diffComp * SurfaceColor;
    float subLamb = smoothstep(-RollOff,1.0,ldn) - smoothstep(0.0,1.0,ldn);
    subLamb = max(0.0,subLamb);
    float3 subContrib = subLamb * SubColor;
    OUT.UV = IN.UV.xy;
    float3 Vn = normalize(ViewIXf[3].xyz - Pw);
    float vdn = 1.0-dot(Vn,Nn);
    float3 vecColor = vdn.xxx;
    OUT.diffCol = float4((subContrib+diffContrib).xyz,1);
    OUT.specCol = float4((vecColor*FuzzySpecColor).xyz,1);
    return OUT;
}

/*********** Generic Vertex Shader ******/

vertexOutput std_VS(appdata IN,
	uniform float4x4 WorldITXf, // our four standard "untweakable" xforms
	uniform float4x4 WorldXf,
	uniform float4x4 ViewIXf,
	uniform float4x4 WvpXf,
	uniform float3 LampPos) {
    vertexOutput OUT = (vertexOutput)0;
    OUT.WorldNormal = mul(IN.Normal,WorldITXf).xyz;
    OUT.WorldTangent = mul(IN.Tangent,WorldITXf).xyz;
    OUT.WorldBinormal = mul(IN.Binormal,WorldITXf).xyz;
    float4 Po = float4(IN.Position.xyz,1); // homogeneous location
    float4 Pw = mul(Po,WorldXf);	// convert to "world" space
#ifdef OBJECT_SPACE_LIGHTS
    float4 Lo = float4(LampPos.xyz,1.0); // homogeneous coordinates
    float4 Lw = mul(Lo,WorldXf);	// convert to "world" space
    OUT.LightVec = (Lw.xyz - Pw.xyz);
#else /* !OBJECT_SPACE_LIGHTS -- standard world-space lights */
    OUT.LightVec = (LampPos - Pw.xyz);
#endif /* !OBJECT_SPACE_LIGHTS */
#ifdef FLIP_TEXTURE_Y
    OUT.UV = float2(IN.UV.x,(1.0-IN.UV.y));
#else /* !FLIP_TEXTURE_Y */
    OUT.UV = IN.UV.xy;
#endif /* !FLIP_TEXTURE_Y */
    OUT.WorldView = normalize(ViewIXf[3].xyz - Pw.xyz);
    OUT.HPosition = mul(Po,WvpXf);
    return OUT;
}

/** pixel shader  **/

void velvet_shared(vertexOutput IN,
			float3 SurfaceColor,
			uniform float3 FuzzySpecColor,
			uniform float3 SubColor,
			uniform float RollOff,
			out float3 DiffuseContrib,
			out float3 SpecularContrib)
{
    float3 Ln = normalize(IN.LightVec.xyz);
    float3 Nn = normalize(IN.WorldNormal);
    float3 Vn = normalize(IN.WorldView);
    float3 Hn = normalize(Vn + Ln);
    float ldn = dot(Ln,Nn);
    float diffComp = max(0,ldn);
    float vdn = 1.0-dot(Vn,Nn);
    float3 diffContrib = diffComp * SurfaceColor;
    float subLamb = smoothstep(-RollOff,1.0,ldn) - smoothstep(0.0,1.0,ldn);
    subLamb = max(0.0,subLamb);
    float3 subContrib = subLamb * SubColor;
    float3 vecColor = vdn.xxx;
    DiffuseContrib = (subContrib+diffContrib).xyz;
    SpecularContrib = (vecColor*FuzzySpecColor).xyz;
}

float4 velvetPS(vertexOutput IN,
		uniform float3 SurfaceColor,
		uniform float3 FuzzySpecColor,
		uniform float3 SubColor,
		uniform float RollOff
) : COLOR {
    float3 diffContrib;
    float3 specContrib;
	velvet_shared(IN,SurfaceColor,FuzzySpecColor,SubColor,RollOff,
			diffContrib,specContrib);
    float3 result = diffContrib + specContrib;
    return float4(result,1);
}

float4 velvetPS_t(vertexOutput IN,
		    uniform float3 SurfaceColor,
		    uniform sampler2D ColorSampler,
		    uniform float3 FuzzySpecColor,
		    uniform float3 SubColor,
		    uniform float RollOff
) : COLOR {
    float3 diffContrib;
    float3 specContrib;
	velvet_shared(IN,SurfaceColor,FuzzySpecColor,SubColor,RollOff,
			diffContrib,specContrib);
    float3 map = tex2D(ColorSampler,IN.UV.xy).xyz;
    float3 result = specContrib + (map * diffContrib);
    return float4(result,1);
}

float4 velvetPS_pass(shadedVertexOutput IN) : COLOR {
    float4 result = IN.diffCol + IN.specCol;
    return float4(result.xyz,1);
}

float4 velvetPS_pass_t(shadedVertexOutput IN,
		    uniform sampler2D ColorSampler
) : COLOR {
    float4 map = tex2D(ColorSampler,IN.UV.xy);
    float4 result = IN.specCol + (map * IN.diffCol);
    return float4(result.xyz,1);
}

///////////////////////////////////////
/// TECHNIQUES ////////////////////////
///////////////////////////////////////

technique Simple <
	string Script = "Pass=p0;";
> {
    pass p0 <
	string Script = "Draw=geometry;";
    > {
        VertexShader = compile vs_3_0 std_VS(gWorldITXf,gWorldXf,
				gViewIXf,gWvpXf,
				gLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = true;
		CullMode = None;
        PixelShader = compile ps_3_0 velvetPS(gSurfaceColor,
				    gFuzzySpecColor,gSubColor,gRollOff);
    }
}


technique Textured <
	string Script = "Pass=p0;";
> {
    pass p0 <
	string Script = "Draw=geometry;";
    > {
        VertexShader = compile vs_3_0 std_VS(gWorldITXf,gWorldXf,
				gViewIXf,gWvpXf,
				gLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = true;
		CullMode = None;
        PixelShader = compile ps_3_0 velvetPS_t(gSurfaceColor,gColorSampler,
				    gFuzzySpecColor,gSubColor,gRollOff);
    }
}


technique VertexSimple <
	string Script = "Pass=p0;";
> {
    pass p0 <
	string Script = "Draw=geometry;";
    > {
        VertexShader = compile vs_3_0 velvetVS(gWorldITXf,gWorldXf,
				gViewIXf,gWvpXf,
			    gSurfaceColor,
			    gFuzzySpecColor,
			    gSubColor,
			    gRollOff,
			    gLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = true;
		CullMode = None;
        PixelShader = compile ps_3_0 velvetPS_pass();
    }
}

technique VertexTextured <
	string Script = "Pass=p0;";
> {
    pass p0 <
	string Script = "Draw=geometry;";
    > {
        VertexShader = compile vs_3_0 velvetVS(gWorldITXf,gWorldXf,
				gViewIXf,gWvpXf,
			    gSurfaceColor,
			    gFuzzySpecColor,
			    gSubColor,
			    gRollOff,
			    gLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = true;
		CullMode = None;
        PixelShader = compile ps_3_0 velvetPS_pass_t(gColorSampler);
    }
}

/***************************** eof ***/
