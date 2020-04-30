/*
   4xSoft Lite "SmartRes" shader
   
   Copyright (C) 2019 guest(r) - guest.r@gmail.com

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

string name : NAME = "soft";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "soft";

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
	OUT.t0 = texCoord * 1.00001;
	return OUT;  
}

float3 SoftLite (float2 pos, float2 ps)
{
	float4 yx = 0.25*float4(ps, -ps);
	float4 xy = 0.50*float4(ps, -ps);
	
	float3 c11 = tex2D(decal, pos        ).xyz;
	float3 c00 = tex2D(decal, pos + xy.zw).xyz;
	float3 c20 = tex2D(decal, pos + xy.xw).xyz;
	float3 c22 = tex2D(decal, pos + xy.xy).xyz;
	float3 c02 = tex2D(decal, pos + xy.zy).xyz;
	float3 s00 = tex2D(decal, pos + yx.zw).xyz;
	float3 s20 = tex2D(decal, pos + yx.xw).xyz;
	float3 s22 = tex2D(decal, pos + yx.xy).xyz;
	float3 s02 = tex2D(decal, pos + yx.zy).xyz;
	float3 dt = float3(1.0,1.0,1.0);
	
	float d1=dot(abs(c00-c22),dt)+1e-4;
	float d2=dot(abs(c20-c02),dt)+1e-4;
	float m1=dot(abs(s00-s22),dt)+1e-4;
	float m2=dot(abs(s02-s20),dt)+1e-4;

	float3 t2=(d1*(c20+c02)+d2*(c00+c22))/(2.0*(d1+d2));
	
	return .25*(c11+t2+(m2*(s00+s22)+m1*(s02+s20))/(m1+m2));
}


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;
	
	return float4(SoftLite(VAR.t0,ps),1.0);
}



technique soft
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

