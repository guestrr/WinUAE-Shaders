// Warmer colors shader


#define WP 100.0  // from -100 to 100 "percent" of conversion


string name : NAME = "D50";

float2 ps                       : TEXELSIZE;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "D50";

texture SourceTexture	        : SOURCETEXTURE;
texture WorkingTexture          : WORKINGTEXTURE;

sampler	decal = sampler_state
{
	Texture	  = (SourceTexture);
	MinFilter = LINEAR;
	MagFilter = LINEAR;
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

float3x3 D50_XYZ = float3x3
(
  0.4360747,  0.3850649,  0.1430804,
  0.2225045,  0.7168786,  0.0606169,
  0.0139322,  0.0971045,  0.7141733
);

float3x3 XYZ_D65 = float3x3
(
  3.2404542, -1.5371385, -0.4985314,
 -0.9692660,  1.8760108,  0.0415560,
  0.0556434, -0.2040259,  1.0572252
);

float3x3 D65_XYZ = float3x3
(
  0.4306190,  0.3415419,  0.1783091,
  0.2220379,  0.7066384,  0.0713236,
  0.0201853,  0.1295504,  0.9390944
);

float3x3 XYZ_D50 = float3x3
(
  2.9603944, -1.4678519, -0.4685105,
 -0.9787684,  1.9161415,  0.0334540,
  0.0844874, -0.2545973,  1.4216174
);



float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float3 c = tex2D(decal, VAR.t0).rgb;
	float  w = tex2D(decal, VAR.t0).a;
	
	float3 p = float3(2.4,2.4,2.4);
	float3 c1 = pow(c, p);
	
	float3 c50 = mul(c1,D50_XYZ);
	float3 c65 = mul(c50,XYZ_D65);
	
	float m = WP/100.0;
	
	float3 color = (1.0-m)*c1 + m*c65; 	
	
	color = pow(color, 1.0/p);
	
	float3 cooler = mul(D65_XYZ,c);
	cooler = mul(XYZ_D50,cooler);
	
	color = lerp(color, cooler, 0.15);
	
    return float4(color,w);	
}



technique D50
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

