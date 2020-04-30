/*
   Hyllian's CRT Shader
  
   Copyright (C) 2011-2016 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

*/

#define SATURATION 1.0
#define VSCANLINES 0.0
#define InputGamma 2.5
#define OutputGamma 2.2
#define SHARPNESS 1.0      // 1.0 or 2.0
#define SHARPNESS2 1.0     // 1.0 to 3.0
#define COLOR_BOOST 1.5
#define RED_BOOST 1.0
#define GREEN_BOOST 1.0
#define BLUE_BOOST 1.0
#define SCANLINES_STRENGTH 1.0
#define BEAM_MIN_WIDTH 0.86
#define BEAM_MAX_WIDTH 1.0
#define CRT_ANTI_RINGING 0.8 


#define eps 1e-8

#define GAMMA_IN(color)     pow(color, float3(InputGamma, InputGamma, InputGamma))
#define GAMMA_OUT(color)    pow(color, float3(1.0 / OutputGamma, 1.0 / OutputGamma, 1.0 / OutputGamma)) 

// Horizontal cubic filter.

// Some known filters use these values:

//    B = 0.0, C = 0.0  =>  Hermite cubic filter.
//    B = 1.0, C = 0.0  =>  Cubic B-Spline filter.
//    B = 0.0, C = 0.5  =>  Catmull-Rom Spline filter. This is the default used in this shader.
//    B = C = 1.0/3.0   =>  Mitchell-Netravali cubic filter.
//    B = 0.3782, C = 0.3109  =>  Robidoux filter.
//    B = 0.2620, C = 0.3690  =>  Robidoux Sharp filter.
//    B = 0.36, C = 0.28  =>  My best config for ringing elimination in pixel art (Hyllian).


// For more info, see: http://www.imagemagick.org/Usage/img_diagrams/cubic_survey.gif

// Change these params to configure the horizontal filter.
const static float  B =  0.0; 
const static float  C =  0.5;  

const static float4x4 invX = float4x4(            (-B - 6.0*C)/6.0,         (3.0*B + 12.0*C)/6.0,     (-3.0*B - 6.0*C)/6.0,             B/6.0,
                                        (12.0 - 9.0*B - 6.0*C)/6.0, (-18.0 + 12.0*B + 6.0*C)/6.0,                      0.0, (6.0 - 2.0*B)/6.0,
                                       -(12.0 - 9.0*B - 6.0*C)/6.0, (18.0 - 15.0*B - 12.0*C)/6.0,      (3.0*B + 6.0*C)/6.0,             B/6.0,
                                                   (B + 6.0*C)/6.0,                           -C,                      0.0,               0.0);

												   
// The name of this effect
string name : NAME = "CrtHyllian";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "CrtHyllian";

texture SourceTexture	        : SOURCETEXTURE;
texture WorkingTexture          : WORKINGTEXTURE;

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
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;

    float3 color;
    float2 TextureSize = float2(SHARPNESS*1.0/ps.x, 1.0/ps.y);

    float2 dx = lerp(float2(1.0/TextureSize.x, 0.0), float2(0.0, 1.0/TextureSize.y), VSCANLINES);
    float2 dy = lerp(float2(0.0, 1.0/TextureSize.y), float2(1.0/TextureSize.x, 0.0), VSCANLINES);

    float2 pix_coord = VAR.t0*TextureSize+float2(-0.5,0.5);

    float2 tc = lerp((floor(pix_coord)+float2(0.5,0.5))/TextureSize, (floor(pix_coord)+float2(1.0,-0.5))/TextureSize, VSCANLINES);

    float2 fp = lerp(frac(pix_coord), frac(pix_coord.yx), VSCANLINES);

    float3 c00 = GAMMA_IN(tex2D(decal, tc     - dx - dy).xyz);
    float3 c01 = GAMMA_IN(tex2D(decal, tc          - dy).xyz);
    float3 c02 = GAMMA_IN(tex2D(decal, tc     + dx - dy).xyz);
    float3 c03 = GAMMA_IN(tex2D(decal, tc + 2.0*dx - dy).xyz);
    float3 c10 = GAMMA_IN(tex2D(decal, tc     - dx).xyz);
    float3 c11 = GAMMA_IN(tex2D(decal, tc         ).xyz);
    float3 c12 = GAMMA_IN(tex2D(decal, tc     + dx).xyz);
    float3 c13 = GAMMA_IN(tex2D(decal, tc + 2.0*dx).xyz);

    //  Get min/max samples
    float3 min_sample = min(min(c01,c11), min(c02,c12));
    float3 max_sample = max(max(c01,c11), max(c02,c12));

    float4x3 color_matrix0 = float4x3(c00, c01, c02, c03);
    float4x3 color_matrix1 = float4x3(c10, c11, c12, c13);

    float4 invX_Px  = mul(invX, float4(fp.x*fp.x*fp.x, fp.x*fp.x, fp.x, 1.0));
    
	invX_Px = sign(invX_Px)*pow(abs(invX_Px), float4(SHARPNESS2, SHARPNESS2, SHARPNESS2, SHARPNESS2));

	invX_Px = invX_Px/dot(invX_Px, float4(1.0, 1.0, 1.0, 1.0));
	
	float3 color0   = mul(invX_Px, color_matrix0);
    float3 color1   = mul(invX_Px, color_matrix1);

    // Anti-ringing
    float3 aux = color0;
    color0 = clamp(color0, min_sample, max_sample);
    color0 = lerp(aux, color0, CRT_ANTI_RINGING);
    aux = color1;
    color1 = clamp(color1, min_sample, max_sample);
    color1 = lerp(aux, color1, CRT_ANTI_RINGING);

    float pos0 = fp.y;
    float pos1 = 1.0 - fp.y;

    float3 lum0 = lerp(float3(BEAM_MIN_WIDTH,BEAM_MIN_WIDTH,BEAM_MIN_WIDTH), float3(BEAM_MAX_WIDTH,BEAM_MAX_WIDTH,BEAM_MAX_WIDTH), color0);
    float3 lum1 = lerp(float3(BEAM_MIN_WIDTH,BEAM_MIN_WIDTH,BEAM_MIN_WIDTH), float3(BEAM_MAX_WIDTH,BEAM_MAX_WIDTH,BEAM_MAX_WIDTH), color1);

    float3 d0 = clamp(pos0/(lum0+0.0000001), 0.0, 1.0);
    float3 d1 = clamp(pos1/(lum1+0.0000001), 0.0, 1.0);

    d0 = exp(-10.0*SCANLINES_STRENGTH*d0*d0);
    d1 = exp(-10.0*SCANLINES_STRENGTH*d1*d1);

    color = clamp(color0*d0+color1*d1, 0.0, 1.0);            

    color *= COLOR_BOOST*float3(RED_BOOST, GREEN_BOOST, BLUE_BOOST);

    color  = GAMMA_OUT(color);
	
	float l = length(color);
	color = normalize(pow(color + eps, float3(SATURATION,SATURATION,SATURATION)))*l;
	
    return float4(color, 1.0);	
}


//
// Technique
//

technique CrtHyllian
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

