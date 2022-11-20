/*
   Hyllian's DDT Sharp Shader
   
   Copyright (C) 2011-2016 Hyllian/Jararaca - sergiogdb@gmail.com

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
 


string name : NAME = "DDT-Sharp";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "DDT";

texture SourceTexture	        : SOURCETEXTURE;

sampler	decal = sampler_state
{
	Texture	  = (SourceTexture);
	MinFilter = POINT;
	MagFilter = POINT;
};


#define WP1  1.0
#define WP2  1.0
#define WP3 -1.0

const static float3 Y = float3(.2126, .7152, .0722);

float luma(float3 color)
{
  return dot(color, Y);
}

float3 bilinear(float p, float q, float3 A, float3 B, float3 C, float3 D)
{
	return ((1.0-p)*(1.0-q)*A + p*(1.0-q)*B + (1.0-p)*q*C + p*q*D);
} 

// **VS**

struct out_vertex {
	float4 position : POSITION;
	float4 color    : COLOR;
	float2 t0       : TEXCOORD0;
}; 
 

out_vertex  DDT_VERTEX(float3 position : POSITION, float2 texCoord : TEXCOORD0 )
{ 
	out_vertex OUT = (out_vertex)0;
	OUT.position = mul(float4(position,1.0),WorldViewProjection);
	OUT.t0 = texCoord * 1.00001;
	return OUT;  
}


// **PS**

float4 DDT_FRAGMENT ( in out_vertex VAR ) : COLOR
{
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;

	float2 coord = (floor(VAR.t0/ps) + 0.5)*ps;

	float2 pos = frac(VAR.t0/ps)-float2(0.5, 0.5); // pos = pixel position
	float2 dir = sign(pos); // dir = pixel direction

	float2 g1 = dir*float2(ps.x,0.0);
	float2 g2 = dir*float2(0.0,ps.y);

//    A1 B1
// A0 A  B  B2
// C0 C  D  D2
//    C3 D3

	float3 A = tex2D(decal, coord       ).xyz;
	float3 B = tex2D(decal, coord +g1   ).xyz;
	float3 C = tex2D(decal, coord    +g2).xyz;
	float3 D = tex2D(decal, coord +g1+g2).xyz;

	float3 A1 = tex2D(decal, coord    -g2).xyz;
	float3 B1 = tex2D(decal, coord +g1-g2).xyz;
	float3 A0 = tex2D(decal, coord -g1   ).xyz;
	float3 C0 = tex2D(decal, coord -g1+g2).xyz;

	float3 B2 = tex2D(decal, coord +2*g1     ).xyz;
	float3 D2 = tex2D(decal, coord +2*g1+  g2).xyz;
	float3 C3 = tex2D(decal, coord      +2*g2).xyz;
	float3 D3 = tex2D(decal, coord   +g1+2*g2).xyz;

	float a = luma(A);
	float b = luma(B);
	float c = luma(C);
	float d = luma(D);

	float a1 = luma(A1);
	float b1 = luma(B1);
	float a0 = luma(A0);
	float c0 = luma(C0);

	float b2 = luma(B2);
	float d2 = luma(D2);
	float c3 = luma(C3);
	float d3 = luma(D3);

	float p = abs(pos.x);
	float q = abs(pos.y);

	float k = distance(pos,g1);
	float l = distance(pos,g2);

	float wd1 = WP1*abs(a-d) + WP2*(abs(b-a1) + abs(b-d2) + abs(c-a0) + abs(c-d3)) + WP3*(abs(a1-d2) + abs(a0-d3));
	float wd2 = WP1*abs(b-c) + WP2*(abs(a-b1) + abs(a-c0) + abs(d-b2) + abs(d-c3)) + WP3*(abs(b1-c0) + abs(b2-c3));

	if ( wd1 < wd2 )
	{
		if (k < l)
		{
			C = A + D - B;
		}
		else
		{
			B = A + D - C;
		}
	}
	else if (wd1 > wd2)
	{
		D = B + C - A;
	}

	float3 color = bilinear(p, q, A, B, C, D);

	return float4(color, 1.0); 
}

technique DDT
{
   pass P0
   {
     VertexShader = compile vs_3_0 DDT_VERTEX();
     PixelShader  = compile ps_3_0 DDT_FRAGMENT();
   }  
}
