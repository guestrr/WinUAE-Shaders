/*
   Hyllian's jinc windowed-jinc 2-lobe with anti-ringing Shader
   
   Copyright (C) 2011-2014 Hyllian/Jararaca - sergiogdb@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

      /*
         This is an approximation of Jinc(x)*Jinc(x*r1/r2) for x < 2.5,
         where r1 and r2 are the first two zeros of jinc function.
         For a jinc 2-lobe best approximation, use A=0.5 and B=0.825.
      */  
 
 
string name : NAME = "Jinc";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "Jinc";

texture SourceTexture	        : SOURCETEXTURE;

sampler	decal = sampler_state
{
	Texture	  = (SourceTexture);
	MinFilter = POINT;
	MagFilter = POINT;
};


#define JINC2_WINDOW_SINC 0.42
#define JINC2_SINC 0.92
#define JINC2_AR_STRENGTH 0.75

#define halfpi  1.5707963267948966192313216916398
#define pi    3.1415926535897932384626433832795
#define wa    (JINC2_WINDOW_SINC*pi)
#define wb    (JINC2_SINC*pi)

// Calculates the distance between two points
float d(float2 pt1, float2 pt2)
{
  float2 v = pt2 - pt1;
  return sqrt(dot(v,v));
}

float3 min4(float3 a, float3 b, float3 c, float3 d)
{
    return min(a, min(b, min(c, d)));
}
float3 max4(float3 a, float3 b, float3 c, float3 d)
{
    return max(a, max(b, max(c, d)));
}

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

float4 resampler(float4 x)
{
	float4 res;
	res = (x==float4(0.0, 0.0, 0.0, 0.0)) ?  float4(wa*wb,wa*wb,wa*wb,wa*wb)  :  sin(x*wa)*sin(x*wb)/(x*x);
	return res;
}
	
float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
      float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
      float2 ps = ps1*tmp;

      float3 color;
      float4x4 weights;

      float2 dx = float2(1.0, 0.0);
      float2 dy = float2(0.0, 1.0);

      float2 pc = VAR.t0/ps;

      float2 tc = (floor(pc-float2(0.5,0.5))+float2(0.5,0.5));
     
      weights[0] = resampler(float4(d(pc, tc    -dx    -dy), d(pc, tc           -dy), d(pc, tc    +dx    -dy), d(pc, tc+2.0*dx    -dy)));
      weights[1] = resampler(float4(d(pc, tc    -dx       ), d(pc, tc              ), d(pc, tc    +dx       ), d(pc, tc+2.0*dx       )));
      weights[2] = resampler(float4(d(pc, tc    -dx    +dy), d(pc, tc           +dy), d(pc, tc    +dx    +dy), d(pc, tc+2.0*dx    +dy)));
      weights[3] = resampler(float4(d(pc, tc    -dx+2.0*dy), d(pc, tc       +2.0*dy), d(pc, tc    +dx+2.0*dy), d(pc, tc+2.0*dx+2.0*dy)));

      dx = dx*ps;
      dy = dy*ps;
      tc = tc*ps;
     
     // reading the texels
     
      float3 c00 = tex2D(decal, tc    -dx    -dy).xyz;
      float3 c10 = tex2D(decal, tc           -dy).xyz;
      float3 c20 = tex2D(decal, tc    +dx    -dy).xyz;
      float3 c30 = tex2D(decal, tc+2.0*dx    -dy).xyz;
      float3 c01 = tex2D(decal, tc    -dx       ).xyz;
      float3 c11 = tex2D(decal, tc              ).xyz;
      float3 c21 = tex2D(decal, tc    +dx       ).xyz;
      float3 c31 = tex2D(decal, tc+2.0*dx       ).xyz;
      float3 c02 = tex2D(decal, tc    -dx    +dy).xyz;
      float3 c12 = tex2D(decal, tc           +dy).xyz;
      float3 c22 = tex2D(decal, tc    +dx    +dy).xyz;
      float3 c32 = tex2D(decal, tc+2.0*dx    +dy).xyz;
      float3 c03 = tex2D(decal, tc    -dx+2.0*dy).xyz;
      float3 c13 = tex2D(decal, tc       +2.0*dy).xyz;
      float3 c23 = tex2D(decal, tc    +dx+2.0*dy).xyz;
      float3 c33 = tex2D(decal, tc+2.0*dx+2.0*dy).xyz;

      //  Get min/max samples
      float3 min_sample = min4(c11, c21, c12, c22);
      float3 max_sample = max4(c11, c21, c12, c22);

      color = mul(weights[0], float4x3(c00, c10, c20, c30));
      color+= mul(weights[1], float4x3(c01, c11, c21, c31));
      color+= mul(weights[2], float4x3(c02, c12, c22, c32));
      color+= mul(weights[3], float4x3(c03, c13, c23, c33));
      color = color/(dot(mul(weights, float4(1.0,1.0,1.0,1.0)), 1.0));

      // Anti-ringing
      float3 aux = color;
      color = clamp(color, min_sample, max_sample);

      color = lerp(aux, color, JINC2_AR_STRENGTH);
 
      // final sum and weight normalization
      return float4(color, 1.0); 
}


//
// Technique
//

technique Jinc
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

