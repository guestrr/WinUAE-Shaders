/*
   CRT - Scanline
   
   Copyright (C) 2017-2020 guest(r) - guest.r@gmail.com

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
#define brightboost1 1.60     // adjust brightness - dark pixels (1.0 to 2.0)
#define brightboost2 1.15     // adjust brightness - bright pixels (1.0 to 2.0)
#define saturation   1.1      // 1.0 is normal saturation
#define scanline1    4.0      // scanline param, vertical sharpness
#define scanline2   12.0      // scanline param, vertical sharpness
#define beam_min     1.32     // dark area beam min - narrow
#define beam_max     1.15     // bright area beam max - wide
#define h_sharp      2.0      // pixel sharpness
#define gammaIN      2.0      // input gamma
#define gammaOUT     2.0      // output gamma

#define eps 1e-8


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

float st(float x)
{
	return exp2(-8.0*x*x);
} 

float3 sw(float x, float3 color, float scanline)
{	
	float mx = max(max(color.r, color.g),color.b);
	x = lerp (x, beam_min*x, max(x-0.4*mx,0.0));
	float3 tmp = lerp(1.2*float3(beam_min,beam_min,beam_min),float3(beam_max,beam_max,beam_max), color);
	float3 ex = float3(x,x,x)*tmp;
	return exp2(-scanline*ex*ex)/(0.6+0.4*color);
}

float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;
	
	float2 OGL2Pos = VAR.t0 / ps - float2(0.5,0.5);
	float2 fp = frac(OGL2Pos);
	float2 dx = float2(ps.x,0.0);
	float2 dy = float2(0.0, ps.y);
	
	float2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;	
	
	// Reading the texels
	float3 ul = tex2D(decal, pC4     ).xyz; ul = pow(ul, float3(gammaIN,gammaIN,gammaIN));
	float3 ur = tex2D(decal, pC4 + dx).xyz; ur = pow(ur, float3(gammaIN,gammaIN,gammaIN));
	float3 dl = tex2D(decal, pC4 + dy).xyz; dl = pow(dl, float3(gammaIN,gammaIN,gammaIN));
	float3 dr = tex2D(decal, pC4 + ps).xyz; dr = pow(dr, float3(gammaIN,gammaIN,gammaIN));
	
	float lx = fp.x;        lx = pow(lx, h_sharp);
	float rx = 1.0 - fp.x;  rx = pow(rx, h_sharp);
	
	float3 color1 = (ur*lx + ul*rx)/(lx+rx);
	float3 color2 = (dr*lx + dl*rx)/(lx+rx);

// calculating scanlines
	
	float f = fp.y;
	
	float shape1 = lerp(scanline1, scanline2, f);
	float shape2 = lerp(scanline1, scanline2, 1.0-f);	 	
	
	float wt1 = st(f);
	float wt2 = st(1.0-f);
	
	float3 color0 = color1*wt1 + color2*wt2;
	color0 = color0/(wt1+wt2); 	
	
	color1*=lerp(brightboost1, brightboost2, max(max(color1.r,color1.g),color1.b));
	color2*=lerp(brightboost1, brightboost2, max(max(color2.r,color2.g),color2.b));

	color1 = min(color1, 1.05);
	color2 = min(color2, 1.05);
	
	float3 color = color2*sw(1.0-f,color0,shape1) + color1*sw(f,color0,shape2);

	color = pow(color, float3(1.0/gammaOUT, 1.0/gammaOUT, 1.0/gammaOUT));
	
	float l = length(color);
	color = normalize(pow(color + eps, float3(saturation,saturation,saturation)))*l;
	
    return float4(color, 1.0);	
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

