// Simple point upscaler
// License: Freeware

string name : NAME = "point";

float2 ps                       : TEXELSIZE;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "POINT";

texture SourceTexture	        : SOURCETEXTURE;

sampler	decal = sampler_state
{
	Texture	  = (SourceTexture);
	MinFilter = POINT;
	MagFilter = POINT;
};


struct out_vertex {
	float4 position : POSITION;
	float4 color    : COLOR;
	float2 t0       : TEXCOORD0;
}; 
 

out_vertex  VS_VERTEX(float3 position : POSITION, float2 texCoord : TEXCOORD0 )
{ 
	out_vertex OUT = (out_vertex)0;

	OUT.position = mul(float4(position,1.0),WorldViewProjection);
	OUT.t0 = texCoord;
	return OUT;  
}



float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	

    return float4(tex2D(decal, VAR.t0).rgb, 1.0);	
}



technique POINT
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_2_0 VS_VERTEX();
        PixelShader  = compile ps_2_0 PS_FRAGMENT(); 
    }  
}

