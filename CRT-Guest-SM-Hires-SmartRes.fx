/*
   CRT - Guest - SM  Shader
   
   Copyright (C) 2019-2020 guest(r) - guest.r@gmail.com
   
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


#define brightboost1 1.40     // adjust brightness - dark pixels (1.0 to 2.0)
#define brightboost2 1.15     // adjust brightness - bright pixels (1.0 to 2.0)
#define stype        0.00     // scanline type (0.0, 1.0, 2.0)
#define scanline1    4.50     // scanline shape, center (3.0 to 12.0)
#define scanline2   10.00     // scanline shape, edges (6.0 to 15.0)
#define beam_min     0.80     // dark area beam min - narrow (0.5 to 2.0)
#define beam_max     1.00     // bright area beam max - wide (0.5 to 2.0)
#define s_beam       0.80     // overgrown bright beam (0.0 to 1.0)
#define saturation1  1.75     // scanline saturation (0.0 to 4.0)
#define h_sharp      2.00     // pixel sharpness (1.0 to 7.0)
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
	return exp2(-10.0*x*x);
}  

float st1(float x, float scan)
{
	return exp2(-scan*x*x);
}  

float3 sw1(float x, float3 color, float scan)
{
	float bmin = (2.75 - 1.75*stype)*beam_min;
	float3 tmp = lerp(float3(bmin,bmin,bmin),float3(beam_max,beam_max,beam_max), color);
	tmp = lerp(float3(beam_max,beam_max,beam_max), tmp, pow(float3(x,x,x), color + 0.30));
	float3 ex = float3(x,x,x)*tmp;
	float3 res = exp2(-scan*ex*ex);
	float mx = max(max(res.r,res.g),res.b);
	return lerp(float3(mx,mx,mx), res, 2.0*x - 0.1);
}

float3 sw2(float x, float3 color, float scan)
{	
	float mx1 = max(max(color.r,color.g),color.b);
	float3 ex = lerp(2.0*float3(beam_min,beam_min,beam_min), float3(beam_max,beam_max,beam_max), color);
	float3 m = min(0.3 + 0.35*ex, 1.0);
	ex = x*ex; 
	float3 xx = ex*ex;
	xx = lerp(xx, ex*xx, m);
	float3 res = exp2(-1.25*scan*xx);
	float mx2 = max(max(res.r,res.g),res.b);
	float br = clamp(lerp(0.20, 0.50, 2.0*(beam_min-1.0)),0.10, 0.60);
	return lerp(float3(mx2,mx2,mx2), res, 0.50)/(1.0 - br + br*mx1);
}

float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;
	ps.x*=0.5;
	
	float2 OGL2Pos = VAR.t0 / ps - float2(0.5,0.5);
	float2 fp = frac(OGL2Pos);
	float2 dx = float2(ps.x,0.0);
	float2 dy = float2(0.0, ps.y);
	
	float2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;	
	
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

	float3 color1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;
	
	l2*=l2*l2; l2*=l2;  l1*=l1*l1; l1*=l1; l3*=l3*l3; l3*=l3;
	r2*=r2*r2; r2*=r2;  r1*=r1*r1; r1*=r1; r3*=r3*r3; r3*=r3;

	float3 scolor1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;
	scolor1 = pow(scolor1, float3(1.0,1.0,1.0)/6.0);
	scolor1 = lerp(color1, scolor1, 1.25);
	
	pC4+=dy;
	l3 = tex2D(decal, pC4 -x2).xyz; l3*=l3;
	l2 = tex2D(decal, pC4 -dx).xyz; l2*=l2;
	l1 = tex2D(decal, pC4    ).xyz; l1*=l1;
	r1 = tex2D(decal, pC4 +dx).xyz; r1*=r1;
	r2 = tex2D(decal, pC4 +x2).xyz; r2*=r2;
	r3 = tex2D(decal, pC4 +x3).xyz; r3*=r3;
	
	float3 color2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

	l2*=l2*l2; l2*=l2;  l1*=l1*l1; l1*=l1; l3*=l3*l3; l3*=l3;
	r2*=r2*r2; r2*=r2;  r1*=r1*r1; r1*=r1; r3*=r3*r3; r3*=r3;

	float3 scolor2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;
	scolor2 = pow(scolor2, float3(1.0,1.0,1.0)/6.0);
	scolor2 = lerp(color2, scolor2, 1.25);
	
	float f1 = fp.y;
	float f2 = 1.0 - fp.y;
	float f3 = frac(VAR.t0.y / ps.y); f3 = abs(f3-0.5);
	
	float3 color;
	float t1 = st(f1);
	float t2 = st(f2);
	
// calculating scanlines
	
	float scan1 = lerp(scanline1, scanline2, f1);
	float scan2 = lerp(scanline1, scanline2, f2);
	float scan0 = lerp(scanline1, scanline2, f3);
	f3 = st1(f3,scan0);
	f3 = f3*f3*(3.0-2.0*f3);
	
	float3 sctemp = (t1*scolor1 + t2*scolor2)/(t1+t2);
	
	float3 ref1 = lerp(sctemp, scolor1, s_beam);
	float3 ref2 = lerp(sctemp, scolor2, s_beam);	
	
	float3 w1, w2 = float3(0.0,0.0,0.0);

	if (stype < 2.0)
	{
		w1 = sw1(f1, ref1, scan1);
		w2 = sw1(f2, ref2, scan2);
	}
	else
	{
		w1 = sw2(f1, ref1, scan1);
		w2 = sw2(f2, ref2, scan2);
	}

	color1*=lerp(brightboost1, brightboost2, max(max(color1.r,color1.g),color1.b));
	color2*=lerp(brightboost1, brightboost2, max(max(color2.r,color2.g),color2.b));

	color1 = min(color1, 1.05);
	color2 = min(color2, 1.05);

	color = w1*color1 + w2*color2;
	float3 w3 = w1+w2;
	
	color = min(color,1.0);	
	
	float3 color1g = pow(color, float3(1.0,1.0,1.0)/2.1);

	if (!(stype == 1.0))
	{
		float3 color2g = pow(color, float3(1.0,1.0,1.0)/gamma_out);			
		float mx1 = max(max(color1g.r,color1g.g),color1g.b) + 1e-12;	
		float mx2 = max(max(color2g.r,color2g.g),color2g.b);
		color1g*=mx2/mx1;		
	}
	
    return float4(color1g, max(max(w3.r,w3.g),w3.b));	
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

