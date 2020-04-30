/*
   Lanczos HiRes SmartRes Shader
   
   Copyright (C)2020 guest(r) - guest.r@gmail.com
   
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


// The name of this effect
string name : NAME = "Lanczos";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "Lanczos";

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
	OUT.t0 = texCoord * 1.00001;
	return OUT;  
}

#define floatpi  1.5707963267948966192313216916398
#define      pi  3.1415926535897932384626433832795


float l(float x)
{ 
  if (x==0.0) return pi*floatpi;
  else
  return sin(x*floatpi)*sin(x*pi)/(x*x);
}

float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;
	ps.x*=0.5;
	
	float2 OGL2Pos = VAR.t0 / ps - float2(0.5,0.5);
	float2 fp = frac(OGL2Pos);
	float fp1 = fp.x;
	float2 dx = float2(ps.x,0.0);
	float2 dy = float2(0.0, ps.y);
	
	float2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;	
	
	// Reading the texels
	float2 x2 = 2.0*dx;
	float2 x3 = x2+ dx;

	float wl4 = 3.0 + fp1;	wl4*=0.5; wl4 = l(wl4);
	float wl3 = 2.0 + fp1;	wl3*=0.5; wl3 = l(wl3);
	float wl2 = 1.0 + fp1;	wl2*=0.5; wl2 = l(wl2);
	float wl1 =       fp1;	wl1*=0.5; wl1 = l(wl1);
	float wr1 = 1.0 - fp1;	wr1*=0.5; wr1 = l(wr1);
	float wr2 = 2.0 - fp1;	wr2*=0.5; wr2 = l(wr2);
	float wr3 = 3.0 - fp1;	wr3*=0.5; wr3 = l(wr3);
	float wr4 = 4.0 - fp1;	wr4*=0.5; wr4 = l(wr4);

	float wtt =  1.0/(wl4+wl3+wl2+wl1+wr1+wr2+wr3+wr4);

	pC4-=dy;	
	float3 l4 = tex2D(decal, pC4 - x2 - dx).rgb;
	float3 l3 = tex2D(decal, pC4 - x2).rgb;	
	float3 l2 = tex2D(decal, pC4 - dx).rgb;
	float3 l1 = tex2D(decal, pC4     ).rgb;
	float3 r1 = tex2D(decal, pC4 + dx).rgb;
	float3 r2 = tex2D(decal, pC4 + x2).rgb;
	float3 r3 = tex2D(decal, pC4 + x2 + dx).rgb;
	float3 r4 = tex2D(decal, pC4 + x2 + x2).rgb;
	
	float3 color1 = (wl4*l4+wl3*l3+wl2*l2+wl1*l1+wr1*r1+wr2*r2+wr3*r3+wr4*r4)*wtt;
	
	pC4+=dy;
	l4 = tex2D(decal, pC4 - x2 - dx).rgb;
	l3 = tex2D(decal, pC4 - x2).rgb;	
	l2 = tex2D(decal, pC4 - dx).rgb;
	l1 = tex2D(decal, pC4     ).rgb;
	r1 = tex2D(decal, pC4 + dx).rgb;
	r2 = tex2D(decal, pC4 + x2).rgb;
	r3 = tex2D(decal, pC4 + x2 + dx).rgb;
	r4 = tex2D(decal, pC4 + x2 + x2).rgb;
	
	float3 color2 = (wl4*l4+wl3*l3+wl2*l2+wl1*l1+wr1*r1+wr2*r2+wr3*r3+wr4*r4)*wtt;

	pC4+=dy;
	l4 = tex2D(decal, pC4 - x2 - dx).rgb;
	l3 = tex2D(decal, pC4 - x2).rgb;	
	l2 = tex2D(decal, pC4 - dx).rgb;
	l1 = tex2D(decal, pC4     ).rgb;
	r1 = tex2D(decal, pC4 + dx).rgb;
	r2 = tex2D(decal, pC4 + x2).rgb;
	r3 = tex2D(decal, pC4 + x2 + dx).rgb;
	r4 = tex2D(decal, pC4 + x2 + x2).rgb;
	
	float3 color3 = (wl4*l4+wl3*l3+wl2*l2+wl1*l1+wr1*r1+wr2*r2+wr3*r3+wr4*r4)*wtt;

	pC4+=dy;
	l4 = tex2D(decal, pC4 - x2 - dx).rgb;
	l3 = tex2D(decal, pC4 - x2).rgb;	
	l2 = tex2D(decal, pC4 - dx).rgb;
	l1 = tex2D(decal, pC4     ).rgb;
	r1 = tex2D(decal, pC4 + dx).rgb;
	r2 = tex2D(decal, pC4 + x2).rgb;
	r3 = tex2D(decal, pC4 + x2 + dx).rgb;
	r4 = tex2D(decal, pC4 + x2 + x2).rgb;
	
	float3 color4 = (wl4*l4+wl3*l3+wl2*l2+wl1*l1+wr1*r1+wr2*r2+wr3*r3+wr4*r4)*wtt;	

	float wt2 = 1.0 + fp.y;	wt2 = l(wt2);
	float wt1 =       fp.y;	wt1 = l(wt1);
	float wb1 = 1.0 - fp.y;	wb1 = l(wb1);
	float wb2 = 2.0 - fp.y; wb2 = l(wb2);
	
	float3 color = (wt2*color1 + wt1*color2 + wb1*color3 + wb2*color4)/(wt2+wt1+wb1+wb2);

    return float4(color, 1.0);	
}


//
// Technique
//

technique Lanczos
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

