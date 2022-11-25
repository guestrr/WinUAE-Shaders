/*
   CRT - A2080 - HiRes SmartRes Shader
   
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


#define brightboost1 1.50     // adjust brightness - dark pixels (1.0 to 2.0)
#define brightboost2 1.15     // adjust brightness - bright pixels (1.0 to 2.0)
#define scanline1    4.50     // scanline shape, center (3.0 to 12.0)
#define scanline2    9.00     // scanline shape, edges (6.0 to 15.0)
#define beam_min     0.60     // dark area beam min - narrow (0.5 to 2.0)
#define beam_max     1.10     // bright area beam max - wide (0.5 to 2.0)
#define s_beam       0.80     // overgrown bright beam (0.0 to 1.0)
#define h_sharp      3.25     // pixel sharpness (1.0 to 10.0)
#define cubic        1.10     // 'cubic sharpness' from 0.0 to 2.0
#define gamma_out    1.85     // gamma out


// The name of this effect
string name : NAME = "A2080";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "A2080";

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


float st(float x)
{
	return exp2(-10.0*x*x);
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
	float fp1 = fp.x;
	float2 dx = float2(ps.x,0.0);
	float2 dy = float2(0.0, ps.y);
	
	float2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;	
	
	// Reading the texels
	float2 x2 = 2.0*dx;
	float2 x3 = x2+ dx;
	
	float zero = lerp(0.0, exp2(-h_sharp), cubic);

	float wl4 = 3.0 + fp1;	wl4*=0.5;
	float wl3 = 2.0 + fp1;	wl3*=0.5;	
	float wl2 = 1.0 + fp1;	wl2*=0.5;
	float wl1 =       fp1;	wl1*=0.5;
	float wr1 = 1.0 - fp1;	wr1*=0.5;
	float wr2 = 2.0 - fp1;	wr2*=0.5;
	float wr3 = 3.0 - fp1;	wr3*=0.5;
	float wr4 = 4.0 - fp1;	wr4*=0.5;

	wl4*=wl4; wl4 = exp2(-h_sharp*wl4); float sl4 = wl4;
	wl3*=wl3; wl3 = exp2(-h_sharp*wl3); float sl3 = wl3;
	wl2*=wl2; wl2 = exp2(-h_sharp*wl2); float sl2 = wl2;
	wl1*=wl1; wl1 = exp2(-h_sharp*wl1);	float sl1 = wl1;
	wr1*=wr1; wr1 = exp2(-h_sharp*wr1);	float sr1 = wr1;
	wr2*=wr2; wr2 = exp2(-h_sharp*wr2);	float sr2 = wr2;
	wr3*=wr3; wr3 = exp2(-h_sharp*wr3);	float sr3 = wr3;
	wr4*=wr4; wr4 = exp2(-h_sharp*wr4);	float sr4 = wr4;	

	wl4 = max(wl4 - zero, lerp(0.0,lerp(-0.08, -0.000, fp1),float(cubic > 0.05)));
	wl3 = max(wl3 - zero, lerp(0.0,lerp(-0.20, -0.080, fp1),float(cubic > 0.05)));
	wl2 = max(wl2 - zero, 0.0);
	wl1 = max(wl1 - zero, 0.0);
	wr1 = max(wr1 - zero, 0.0);	
	wr2 = max(wr2 - zero, 0.0);	
	wr3 = max(wr3 - zero, lerp(0.0,lerp(-0.20, -0.080, 1.-fp1),float(cubic > 0.05)));
	wr4 = max(wr4 - zero, lerp(0.0,lerp(-0.08, -0.000, 1.-fp1),float(cubic > 0.05)));

	float wtt =  1.0/(wl4+wl3+wl2+wl1+wr1+wr2+wr3+wr4);
	float wts =  1.0/(sl4+sl3+sl2+sl1+sr1+sr2+sr3+sr4);

	float3 l4 = tex2D(decal, pC4 - x2 - dx).rgb; l4*=l4;
	float3 l3 = tex2D(decal, pC4 - x2).rgb; l3*=l3;	
	float3 l2 = tex2D(decal, pC4 - dx).rgb; l2*=l2;
	float3 l1 = tex2D(decal, pC4     ).rgb; l1*=l1;
	float3 r1 = tex2D(decal, pC4 + dx).rgb; r1*=r1;
	float3 r2 = tex2D(decal, pC4 + x2).rgb; r2*=r2;
	float3 r3 = tex2D(decal, pC4 + x2 + dx).rgb; r3*=r3;
	float3 r4 = tex2D(decal, pC4 + x2 + x2).rgb; r4*=r4;
	
	float3 color1 = (wl4*l4+wl3*l3+wl2*l2+wl1*l1+wr1*r1+wr2*r2+wr3*r3+wr4*r4)*wtt;
	
	float3 colmin = min(min(l3,l1),min(r1,r3)); colmin = min(colmin, min(l2,r2));
	float3 colmax = max(max(l3,l1),max(r1,r3)); colmax = max(colmax, max(l2,r2));
	
	if (cubic > 0.05) color1 = clamp(color1, colmin, colmax);
	
	l1*=l1; l1*=l1; r1*=r1; r1*=r1; l2*=l2; l2*=l2; r2*=r2; r2*=r2;
	l3*=l3; l3*=l3; r3*=r3; r3*=r3; l4*=l4; l4*=l4; r4*=r4; r4*=r4;
	
	float3 scolor1 = (sl4*l4+sl3*l3+sl2*l2+sl1*l1+sr1*r1+sr2*r2+sr3*r3+sr4*r4)*wts;
	scolor1 = pow(scolor1, float3(1.0,1.0,1.0)/4.0);
	
	scolor1 = lerp(color1, scolor1, 1.1);
	
	pC4+=dy;
	l4 = tex2D(decal, pC4 - x2 - dx).rgb; l4*=l4;
	l3 = tex2D(decal, pC4 - x2).rgb; l3*=l3;	
	l2 = tex2D(decal, pC4 - dx).rgb; l2*=l2;
	l1 = tex2D(decal, pC4     ).rgb; l1*=l1;
	r1 = tex2D(decal, pC4 + dx).rgb; r1*=r1;
	r2 = tex2D(decal, pC4 + x2).rgb; r2*=r2;
	r3 = tex2D(decal, pC4 + x2 + dx).rgb; r3*=r3;
	r4 = tex2D(decal, pC4 + x2 + x2).rgb; r4*=r4;
	
	float3 color2 = (wl4*l4+wl3*l3+wl2*l2+wl1*l1+wr1*r1+wr2*r2+wr3*r3+wr4*r4)*wtt;
	
	colmin = min(min(l3,l1),min(r1,r3)); colmin = min(colmin, min(l2,r2));
	colmax = max(max(l3,l1),max(r1,r3)); colmax = max(colmax, max(l2,r2));
	
	if (cubic > 0.05) color2 = clamp(color2, colmin, colmax);
	
	l1*=l1; l1*=l1; r1*=r1; r1*=r1; l2*=l2; l2*=l2; r2*=r2; r2*=r2;
	l3*=l3; l3*=l3; r3*=r3; r3*=r3; l4*=l4; l4*=l4; r4*=r4; r4*=r4;
	
	float3 scolor2 = (sl4*l4+sl3*l3+sl2*l2+sl1*l1+sr1*r1+sr2*r2+sr3*r3+sr4*r4)*wts;
	scolor2 = pow(scolor2, float3(1.0,1.0,1.0)/4.0);
	
	scolor2 = lerp(color2, scolor2, 1.1);
	
	float f1 = fp.y;
	float f2 = 1.0 - fp.y;
	
	float3 color;
	float t1 = st(f1);
	float t2 = st(f2);
	float wt = 1.0/(t1+t2);
	
// calculating scanlines

	float scan1 = lerp(scanline1, scanline2, f1);
	float scan2 = lerp(scanline1, scanline2, f2);
	
	float3 sctemp = (t1*scolor1 + t2*scolor2)*wt;
	
	float3 ref1 = lerp(sctemp, scolor1, s_beam); ref1 = pow(ref1, lerp(float3(1.15,1.15,1.15), float3(0.65,0.65,0.65), ref1));
	float3 ref2 = lerp(sctemp, scolor2, s_beam); ref2 = pow(ref2, lerp(float3(1.15,1.15,1.15), float3(0.65,0.65,0.65), ref2));
	
	float3 w1 = sw2(f1, ref1, scan1);
	float3 w2 = sw2(f2, ref2, scan2);

	color1*=lerp(brightboost1, brightboost2, max(max(color1.r,color1.g),color1.b));
	color2*=lerp(brightboost1, brightboost2, max(max(color2.r,color2.g),color2.b));

	color1 = saturate(color1);
	color2 = saturate(color2);

	color = w1*color1 + w2*color2;
	float3 w3 = w1 + w2;

	float3 color1g = pow(color, float3(1.0,1.0,1.0)/gamma_out);

    return float4(color1g, max(max(w3.r,w3.g),w3.b));	
}


//
// Technique
//

technique A2080
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

