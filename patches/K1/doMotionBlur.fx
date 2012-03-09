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

texture velmap <string uiname="Velocity map";>;
sampler VMSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (velmap);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

texture scene<string uiname="Original scene";>;
sampler ScnSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (scene);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 tVmap: TEXTUREMATRIX <string uiname="Velocity map Transform";>;

float4x4 tOscn: TEXTUREMATRIX <string uiname="Original scene Transform";>;

float blurV
<
    string uiname="Blur amount";
> = 1;
float fov;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float4 VmCd : TEXCOORD0;
    float4 OsCd : TEXCOORD1;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
    float4 VmCd : TEXCOORD0,
    float4 OsCd : TEXCOORD1)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.Pos = mul(PosO, tWVP);
    
    //transform texturecoordinates
    Out.VmCd = mul(VmCd, tVmap);

    //transform the mask texture cordinates
    Out.OsCd = mul(VmCd, tOscn);
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------
float4 mblur4(vs2ps In):Color
{
    float4 outColor = { 0.0, 0.0, 0.0, 1.00000 };
    //source texture lookup
    float4 vmap = tex2D(VMSamp, In.VmCd);
    // the mask texture lookup
    float4 oscn = tex2D(ScnSamp, In.OsCd);
    
    float4 vel = (vmap - 0.502)*blurV*2;
    
    // vmap - 0.502 is sharp (correct)
    // and .5 is blurry when nothing moves...
    // WHY???!!!
    
    if ((fov!=0) && (abs(fov)!=0.5)) {
    	vel.x -= (vel.z * (In.VmCd.x*2-1)) * (0.25/abs(fov-0.5));
    	vel.y -= (vel.z * (In.VmCd.y*2-1)) * (0.25/abs(fov-0.5));
    }
    vel *= (1-abs(fov-0.5)*1.6)*1.5; //some correction
    //float4 temp = vel; //return for debugging
    float4 toscd = In.OsCd+vel/2;
    toscd += -vel/4;
    float4 Coscn1 = tex2D(ScnSamp, toscd);
    toscd += -vel/4;
    float4 Coscn2 = tex2D(ScnSamp, toscd);
    toscd += -vel/4;
    float4 Coscn3 = tex2D(ScnSamp, toscd);
    toscd += -vel/4;
    float4 Coscn4 = tex2D(ScnSamp, toscd);
    oscn += Coscn1 + Coscn2 + Coscn3 + Coscn4;
    outColor = oscn/5;
    
    return outColor;
}

float4 mblur8(vs2ps In):Color
{
    float4 outColor = { 0.0, 0.0, 0.0, 1.00000 };
    //source texture lookup
    float4 vmap = tex2D(VMSamp, In.VmCd);
    // the mask texture lookup
    float4 oscn = tex2D(ScnSamp, In.OsCd);
    
    float4 vel = (vmap - 0.502)*blurV*2;
    
    // vmap - 0.502 is sharp (correct)
    // and .5 is blurry when nothing moves...
    // WHY???!!!
    
    if ((fov!=0) && (abs(fov)!=0.5)) {
    	vel.x -= (vel.z * (In.VmCd.x*2-1)) * (0.25/abs(fov-0.5));
    	vel.y -= (vel.z * (In.VmCd.y*2-1)) * (0.25/abs(fov-0.5));
    }
    vel *= (1-abs(fov-0.5)*1.6)*1.5; //some correction
    //float4 temp = vel; //return for debugging
    float4 toscd = In.OsCd+vel/4;
    toscd += -vel/8;
    float4 Coscn1 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn2 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn3 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn4 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn5 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn6 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn7 = tex2D(ScnSamp, toscd);
    toscd += -vel/8;
    float4 Coscn8 = tex2D(ScnSamp, toscd);
    oscn += Coscn1 + Coscn2 + Coscn3 + Coscn4 + Coscn5 + Coscn6 + Coscn7 + Coscn8;
    outColor = oscn/9;
    return outColor;
}

float4 mblur16(vs2ps In):Color
{
    float4 outColor = { 0.0, 0.0, 0.0, 1.00000 };
    float4 vmap = tex2D(VMSamp, In.VmCd);
    float4 oscn = tex2D(ScnSamp, In.OsCd);
    
    float4 vel = (vmap - 0.502)*blurV*2;
    
    // vmap - 0.502 is sharp (correct)
    // and .5 is blurry when nothing moves...
    // WHY???!!!
    
    if ((fov!=0) && (abs(fov)!=0.5)) {
    	vel.x -= (vel.z * (In.VmCd.x*2-1)) * (0.25/abs(fov-0.5));
    	vel.y -= (vel.z * (In.VmCd.y*2-1)) * (0.25/abs(fov-0.5));
    }
    vel *= (1-abs(fov-0.5)*1.6)*1.5; //some correction
    //float4 temp = vel; //return for debugging
    float4 toscd = In.OsCd + vel/2;
    toscd += -vel/16;
    float4 Coscn1 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn2 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn3 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn4 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn5 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn6 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn7 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn8 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn9 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn10 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn11 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn12 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn13 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn14 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn15 = tex2D(ScnSamp, toscd);
    toscd += -vel/16;
    float4 Coscn16 = tex2D(ScnSamp, toscd);
    oscn += Coscn1 + Coscn2 + Coscn3 + Coscn4 + Coscn5 + Coscn6 + Coscn7 + Coscn8 + Coscn9 + Coscn10 + Coscn11 + Coscn12 + Coscn13 + Coscn14 + Coscn15 + Coscn16;
    outColor = oscn/17;
    return outColor;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique four_samples
{
    pass  P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 mblur4();
    }
}
technique eight_samples
{
    pass  P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 mblur8();
    }
}
technique sixteen_samples
{
    pass  P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 mblur16();
    }
}