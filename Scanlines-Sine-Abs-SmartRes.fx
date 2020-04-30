/*
    Scanlines Sine Absolute Value
    An ultra light scanline shader
    by RiskyJumps
	license: public domain
*/

#define amp              1.250000
#define phase            0.500000
#define lines_black      0.000000
#define lines_white      1.000000

#define freq             0.500000
#define offset           0.000000
#define pi               3.141592654


string name : NAME = "point";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

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
	float  angle    : TEXCOORD1;	
}; 
 

out_vertex  VS_VERTEX(float3 position : POSITION, float2 texCoord : TEXCOORD0 )
{ 
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;

	out_vertex OUT = (out_vertex)0;

	OUT.position = mul(float4(position,1.0),WorldViewProjection);
	OUT.t0 = texCoord;
	
	float omega = 2.0 * pi * freq;  // Angular frequency
	
	OUT.angle = texCoord.y * omega / ps.y + phase;	
	return OUT;  
}


float4 scanline_sine_abs(float angle, float2 texCoord)
{
    float3 color = tex2D(decal, texCoord).xyz;
    float grid;
 
    float lines;
 
    lines = sin(angle);
    lines *= amp;
    lines += offset;
    lines = abs(lines) * (lines_white - lines_black) + lines_black;
    color *= lines;
 
    return color.xyzz;
}


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
    return scanline_sine_abs(VAR.angle, VAR.t0);	
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

