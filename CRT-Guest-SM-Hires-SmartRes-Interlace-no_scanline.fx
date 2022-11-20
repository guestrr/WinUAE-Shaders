/*
   CRT - Guest - SM "Interlace" - dense shader
   
   Copyright (C) 2019-2022 guest(r) - guest.r@gmail.com
   
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


#define brightboost1 1.25     // adjust brightness - dark pixels (1.0 to 2.0)
#define brightboost2 1.10     // adjust brightness - bright pixels (1.0 to 2.0)
#define stype        0.00     // scanline type (0.0, 1.0, 2.0)
#define scanline1    4.00     // scanline shape, center (3.0 to 12.0)
#define scanline2    6.00     // scanline shape, edges (6.0 to 15.0)
#define beam_min     0.80     // dark area beam min - narrow (0.5 to 2.0)
#define beam_max     1.00     // bright area beam max - wide (0.5 to 2.0)
#define s_beam       0.80     // overgrown bright beam (0.0 to 1.0)
#define saturation1  1.75     // scanline saturation (0.0 to 4.0)
#define h_sharp      2.50     // pixel sharpness (1.0 to 7.0)
#define gamma_out    2.30     // gamma out


// The name of this effect
string name : NAME = "CrtGuest";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "CrtGuest";

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
	OUT.t0 = texCoord * 1.000001;
	return OUT;  
}


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : float2(ir.x, 1.0);
	float2 ps = ps1*tmp;
	ps.x*=0.5;
	
	float2 OGL2Pos = VAR.t0 / ps - float2(0.5,0.5);
	float2 fp = frac(OGL2Pos);
	float2 dx = float2(ps.x,0.0);
	float2 dy = float2(0.0,ps.y);
	
	float2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;
	
	pC4.y = VAR.t0.y;
	
	// Reading the texels
	float2 x2 = 2.0*dx;
	float2 x3 = x2+ dx;
	
	float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-h_sharp*wl3);	
	float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-h_sharp*wl2);
	float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-h_sharp*wl1);
	float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-h_sharp*wr1);
	float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-h_sharp*wr2);
	float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-h_sharp*wr3);

	float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

	float3 l3 = tex2D(decal, pC4 -x2).xyz; l3*=l3;
	float3 l2 = tex2D(decal, pC4 -dx).xyz; l2*=l2;
	float3 l1 = tex2D(decal, pC4    ).xyz; l1*=l1;
	float3 r1 = tex2D(decal, pC4 +dx).xyz; r1*=r1;
	float3 r2 = tex2D(decal, pC4 +x2).xyz; r2*=r2;
	float3 r3 = tex2D(decal, pC4 +x3).xyz; r3*=r3;

	float3 color = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;
	
	color = min(color,1.0);	
	
    return float4(sqrt(color), 1.0);	
}


//
// Technique
//

technique CrtGuest
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

