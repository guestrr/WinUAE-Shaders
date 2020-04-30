/*
   CRT - Guest - Glow
   
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
#define brightboost1 1.55     // adjust brightness - dark pixels (1.0 to 2.0)
#define brightboost2 1.15     // adjust brightness - bright pixels (1.0 to 2.0)
#define saturation   1.00     // 1.0 is normal saturation
#define gammaOUT     0.55     // 1.0/gammaOUT to be regarded, input gamma is 2.0 
#define scanline     8.0      // scanline param, vertical sharpness
#define beam_min     1.15     // dark area beam min - narrow
#define beam_max     1.00     // bright area beam max - wide
#define h_sharp      1.7      // pixel sharpness
#define bloompix     0.50     // glow shape, more is harder
#define bloompixy    0.80     // glow shape, more is harder

#define glow         0.08     // glow ammount


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


float3 sw(float x, float3 color)
{
	float3 tmp = lerp(float3(beam_min,beam_min,beam_min),float3(beam_max,beam_max,beam_max), color);
	float3 ex = float3(x,x,x)*tmp;
	return exp2(-scanline*ex*ex);
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
	float3 ul = tex2D(decal, pC4     ).xyz; ul*=ul;
	float3 ur = tex2D(decal, pC4 + dx).xyz; ur*=ur;
	float3 dl = tex2D(decal, pC4 + dy).xyz; dl*=dl;
	float3 dr = tex2D(decal, pC4 + ps).xyz; dr*=dr;
	
	float lx = fp.x;        lx = pow(lx, h_sharp);
	float rx = 1.0 - fp.x;  rx = pow(rx, h_sharp);
	
	float3 color1 = (ur*lx + ul*rx)/(lx+rx);
	float3 color2 = (dr*lx + dl*rx)/(lx+rx);

// calculating scanlines
	
	float f = fp.y;

	color1*=lerp(brightboost1, brightboost2, max(max(color1.r,color1.g),color1.b));
	color2*=lerp(brightboost1, brightboost2, max(max(color2.r,color2.g),color2.b));

	color1 = min(color1, 1.05);
	color2 = min(color2, 1.05);

	float3 w1 = sw(f,color1);
	float3 w2 = sw(1.0-f,color2);
	float3 w3 = w1+w2;
	
	float3 color = color1*w1 + color2*w2;

	float2 x2 = 2.0*dx; float2 x3 = 3.0*dx;
	float2 y2 = 2.0*dy;

	float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-bloompix*wl3);
	float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-bloompix*wl2);
	float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-bloompix*wl1);
	float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-bloompix*wr1);
	float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-bloompix*wr2);
	float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-bloompix*wr3);	
	
	float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);
	
	float3 l3 = tex2D(decal, pC4 -x2 ).xyz; l3*=l3;
	float3 l2 = tex2D(decal, pC4 -dx ).xyz; l2*=l2;
	float3 l1 = tex2D(decal, pC4     ).xyz; l1*=l1;
	float3 r1 = tex2D(decal, pC4 +dx ).xyz; r1*=r1;
	float3 r2 = tex2D(decal, pC4 +x2 ).xyz; r2*=r2;
	float3 r3 = tex2D(decal, pC4 +x3 ).xyz; r3*=r3;

	float3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;
	
	l3 = tex2D(decal, pC4 -x2 -dy).xyz; l3*=l3;
	l2 = tex2D(decal, pC4 -dx -dy).xyz; l2*=l2;
	l1 = tex2D(decal, pC4     -dy).xyz; l1*=l1;
	r1 = tex2D(decal, pC4 +dx -dy).xyz; r1*=r1;
	r2 = tex2D(decal, pC4 +x2 -dy).xyz; r2*=r2;
	r3 = tex2D(decal, pC4 +x3 -dy).xyz; r3*=r3;
	
	float3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;	
	
	l3 = tex2D(decal, pC4 -x2 +dy).xyz; l3*=l3;
	l2 = tex2D(decal, pC4 -dx +dy).xyz; l2*=l2;
	l1 = tex2D(decal, pC4     +dy).xyz; l1*=l1;
	r1 = tex2D(decal, pC4 +dx +dy).xyz; r1*=r1;
	r2 = tex2D(decal, pC4 +x2 +dy).xyz; r2*=r2;
	r3 = tex2D(decal, pC4 +x3 +dy).xyz; r3*=r3;

	float3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

	l3 = tex2D(decal, pC4 -x2 +y2).xyz; l3*=l3;
	l2 = tex2D(decal, pC4 -dx +y2).xyz; l2*=l2;
	l1 = tex2D(decal, pC4     +y2).xyz; l1*=l1;
	r1 = tex2D(decal, pC4 +dx +y2).xyz; r1*=r1;
	r2 = tex2D(decal, pC4 +x2 +y2).xyz; r2*=r2;
	r3 = tex2D(decal, pC4 +x3 +y2).xyz; r3*=r3;
	
	float3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;	
	
	wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-bloompixy*wl2);
	wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-bloompixy*wl1);
	wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-bloompixy*wr1);
	wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-bloompixy*wr2);
	
	wt = 1.0/(wl2+wl1+wr1+wr2);	
	
	float3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;
	
	color += Bloom*glow; 
	
	color = pow(color, float3(0.55, 0.55, 0.55));
	
	float l = length(color);
	color = normalize(pow(color + float3(eps,eps,eps), float3(saturation,saturation,saturation)))*l;
	
    return float4(color, max(max(w3.r,w3.g),w3.b));	
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

