/*
	Gaussian-kernel TV Upscaler	
	version : 0.3
	Author: aliaspider - aliaspider@gmail.com
	License: GPLv3      	
*/
 
//------------------------------------------------------------------------------------//
// CONFIG :

// this will define the bandwidth of the signal per scanline
// a value of 640.0 or double the game horizontal resolution
// work well for most cases.
// you can set it to 512 to get full transparancy in snes
// games that use the psoeudo-hires video mode.
// higher BANDWIDTH = sharper image
#define BANDWIDTH 640.0


// scanline width
// scanlines will start to disappear with a value of 1.88.
// a value of 2.0 will produce a scanlines free image.
// lower values might require a higher resolution
// to display correctly
#define SCANLINE_WIDTH 1.2


// gamma of the current display device
// try reducing this value if the image feels too bright
#define OUTPUTG2	2.2


// gamma of the emulated CRT-TV
#define INPUTG2		2.4	
 
  
// horizontal computation range or the shader,
// increasing this value will increase performance requieremnts
// you might need to increase it if you notice
// some artifacts appearing with lower bandwidth settings.
// you only need to set this to the lowest value that doesnt 
// cause artifacts to appears.
// default : 2
#define X_RANGE 2


// CONFIG END.
//------------------------------------------------------------------------------------//

	
string name : NAME = "GTU";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "GTU";

texture SourceTexture	        : SOURCETEXTURE;

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





float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;

#define GAMMAOUT(c0)	(pow(c0, float3(1.0/OUTPUTG2,1.0/OUTPUTG2,1.0/OUTPUTG2)))
#define GAMMAIN(c)		(pow(c, float3(INPUTG2,INPUTG2,INPUTG2)))
#define pi			3.14159265358
#define a(x) abs(x)
#define d(x,b) (pi*b*min(a(x)+0.5,1.0/b))
#define e(x,b) (pi*b*min(max(a(x)-0.5,-1.0/b),1.0/b))
#define STU(x,b) ((d(x,b)+sin(d(x,b))-e(x,b)-sin(e(x,b)))/(2.0*pi))
#define GAUSS(x,w) ((sqrt(2.0) / (w)) * (exp((-2.0 * pi * (x) * (x)) / ((w) * (w)))))
#define X(i) (offset.x-(i))
#define Y(j) (offset.y-(j))
#define SOURCE(i,j) float2(VAR.t0 - float2(X(i),Y(j))*ps.xy)
#define C(i,j) (GAMMAIN(tex2D(decal, SOURCE(i,j)).xyz))
#define VAL(i,j) (C(i,j)*STU(X(i),((BANDWIDTH/2.0)*ps.x))*GAUSS(Y(j),SCANLINE_WIDTH))

	float2	offset	= frac((VAR.t0 / ps) - 0.5);
	float3	tempColor = float3(0.0, 0.0, 0.0);	

#if (X_RANGE > 6)
	tempColor+=VAL(-6.0,-1.0)+VAL(-6.0,0.0)+VAL(-6.0,1.0)+VAL(-6.0,2.0);
	tempColor+=VAL(7.0,-1.0)+VAL(7.0,0.0)+VAL(7.0,1.0)+VAL(7.0,2.0);
#endif
#if (X_RANGE > 5)
	tempColor+=VAL(-5.0,-1.0)+VAL(-5.0,0.0)+VAL(-5.0,1.0)+VAL(-5.0,2.0);
	tempColor+=VAL(6.0,-1.0)+VAL(6.0,0.0)+VAL(6.0,1.0)+VAL(6.0,2.0);
#endif
#if (X_RANGE > 4)
	tempColor+=VAL(-4.0,-1.0)+VAL(-4.0,0.0)+VAL(-4.0,1.0)+VAL(-4.0,2.0);
	tempColor+=VAL(5.0,-1.0)+VAL(5.0,0.0)+VAL(5.0,1.0)+VAL(5.0,2.0);
#endif
#if (X_RANGE > 3)
	tempColor+=VAL(-3.0,-1.0)+VAL(-3.0,0.0)+VAL(-3.0,1.0)+VAL(-3.0,2.0);
	tempColor+=VAL(4.0,-1.0)+VAL(4.0,0.0)+VAL(4.0,1.0)+VAL(4.0,2.0);
#endif
#if (X_RANGE > 2)
	tempColor+=VAL(-2.0,-1.0)+VAL(-2.0,0.0)+VAL(-2.0,1.0)+VAL(-2.0,2.0);
	tempColor+=VAL(3.0,-1.0)+VAL(3.0,0.0)+VAL(3.0,1.0)+VAL(3.0,2.0);
#endif
#if (X_RANGE > 1)
	tempColor+=VAL(-1.0,-1.0)+VAL(-1.0,0.0)+VAL(-1.0,1.0)+VAL(-1.0,2.0);
	tempColor+=VAL(2.0,-1.0)+VAL(2.0,0.0)+VAL(2.0,1.0)+VAL(2.0,2.0);
#endif
	tempColor+=VAL(0.0,-1.0)+VAL(0.0,0.0)+VAL(0.0,1.0)+VAL(0.0,2.0);
	tempColor+=VAL(1.0,-1.0)+VAL(1.0,0.0)+VAL(1.0,1.0)+VAL(1.0,2.0);		

	return float4(GAMMAOUT(tempColor), 1.0);	
}



technique GTU
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}
