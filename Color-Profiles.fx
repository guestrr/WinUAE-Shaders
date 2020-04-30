/*
   CRT Color Profiles
   
   Copyright (C) 2019 guest(r) and Dr. Venom
   
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


#define CP  4.0  //  color profile, -1.0 to 5.0
#define CS  1.0  //  color space, 0.0 - sRGB, 1.0 - DCI-P3, 2.0 - Adobe RGB, 3.0 - Rec.2020

#define saturation   1.00     // 1.0 is normal saturation, 2.0 high saturation

#define eps 1e-5

string name : NAME = "D50";

float2 ps                       : TEXELSIZE;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "D50";

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
	OUT.t0 = texCoord;
	return OUT;  
}


float3x3 Profile0 = float3x3(
 0.412391,  0.357584,  0.180481,
 0.212639,  0.715169,  0.072192,
 0.019331,  0.119195,  0.950532
);

float3x3 Profile1 = float3x3(
 0.430554,  0.341550,  0.178352,
 0.222004,  0.706655,  0.071341,
 0.020182,  0.129553,  0.939322
);

float3x3 Profile2 = float3x3(
 0.396686,  0.372504,  0.181266,
 0.210299,  0.713766,  0.075936,
 0.006131,  0.115356,  0.967571
);

float3x3 Profile3 = float3x3(
 0.393521,  0.365258,  0.191677,
 0.212376,  0.701060,  0.086564,
 0.018739,  0.111934,  0.958385
);

float3x3 Profile4 = float3x3(
 0.392258,  0.351135,  0.166603,
 0.209410,  0.725680,  0.064910,
 0.016061,  0.093636,  0.850324
);

float3x3 Profile5 = float3x3(
 0.377923,  0.317366,  0.207738,
 0.195679,  0.722319,  0.082002,
 0.010514,  0.097826,  1.076960
);


float3x3 ToSRGB = float3x3(
 3.240970, -1.537383, -0.498611,
-0.969244,  1.875968,  0.041555,
 0.055630, -0.203977,  1.056972
);
 
float3x3 ToDCI = float3x3(
 2.725394,  -1.018003,  -0.440163,
-0.795168,   1.689732,   0.022647,
 0.041242,  -0.087639,   1.100929
);

float3x3 ToAdobe = float3x3(
 2.041588, -0.565007, -0.344731,
-0.969244,  1.875968,  0.041555,
 0.013444, -0.118362,  1.015175
);

float3x3 ToREC = float3x3(
 1.716651, -0.355671, -0.253366,
-0.666684,  1.616481,  0.015769,
 0.017640, -0.042771,  0.942103
); 


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	float3 c = tex2D(decal, VAR.t0).rgb;
	float  w = tex2D(decal, VAR.t0).a;
	
	float p;
	float3x3 m_out = ToSRGB;
	
	if (CS == 0.0) { p = 2.4; m_out =  ToSRGB; } else
	if (CS == 1.0) { p = 2.6; m_out =  ToDCI;  } else
	if (CS == 2.0) { p = 2.2; m_out =  ToAdobe;} else
	if (CS == 3.0) { p = 2.4; m_out =  ToREC;  }
	
	float3 color = pow(c, float3(p,p,p));
	
	float3x3 m_in = Profile0;

	if (CP == 0.0) { m_in = Profile0; } else	
	if (CP == 1.0) { m_in = Profile1; } else
	if (CP == 2.0) { m_in = Profile2; } else
	if (CP == 3.0) { m_in = Profile3; } else
	if (CP == 4.0) { m_in = Profile4; } else
	if (CP == 5.0) { m_in = Profile5; }

	color = mul(m_in,color);
	color = mul(m_out,color);
	
	color = clamp(color, 0.0, 1.0);
	
	float r = 1.0/p;
	color = pow(color, float3(r,r,r));	
	
	if (CP == -1.0) color = c;
	
	float l = length(color);
	
	color.r = pow(color.r + eps, saturation);
	color.g = pow(color.g + eps, saturation);
	color.b = pow(color.b + eps, saturation);	
	
	color = normalize(color)*l;	
	
    return float4(color,w);	
}


technique D50
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

