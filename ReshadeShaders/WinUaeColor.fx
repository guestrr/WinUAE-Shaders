/*
    WinUAE Color Shader
   
   Copyright (C) 2020 guest(r), Dr. Venom - guest.r@gmail.com

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

#include "ReShadeUI.fxh"
#include "ReShade.fxh"


uniform int CP < __UNIFORM_SLIDER_INT1
	ui_min = -1; ui_max = 5;
	ui_label = "Color Profile (-1 : All OFF)";
	ui_tooltip = "Color Profile (-1 : All OFF)";
> = 0;

uniform int CS < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 3;
	ui_label = "Color Space: sRGB, DCI-P3, Adobe RGB, Rec.2020";
	ui_tooltip = "Color Space: sRGB, DCI-P3, Adobe RGB, Rec.2020";
> = 0;

uniform float WP < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Color Temperature";
	ui_tooltip = "Color Temperature";
> = 0.0;

uniform float saturation < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Color Saturation";
	ui_tooltip = "Color Saturation";
> = 1.0;

uniform float contrast < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Color Contrast";
	ui_tooltip = "Color Contrast";
> = 0.0;

uniform float brightness < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 3.0;
	ui_label = "Color Brightness";
	ui_tooltip = "Color Brightness";
> = 1.0;

float contr( float3 c)
{
	float mx = max(max(c.r,c.g),c.b);
	float mxc = lerp(mx, mx*mx*(3.0-2.0*mx), mx);
	mxc = lerp(mx, mxc, contrast);
	return mxc/(mx+0.00001);
}

float3 plant (float3 tar, float r)
{
	float t = max(max(tar.r,tar.g),tar.b) + 0.00001;
	return tar * r / t;
}
 
float4 WUColor(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{

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


float3x3 D65_to_XYZ = float3x3 (
           0.4306190,  0.2220379,  0.0201853,
           0.3415419,  0.7066384,  0.1295504,
           0.1783091,  0.0713236,  0.9390944);

float3x3 XYZ_to_D65 = float3x3 (
           3.0628971, -0.9692660,  0.0678775,
          -1.3931791,  1.8760108, -0.2288548,
          -0.4757517,  0.0415560,  1.0693490);
		   
float3x3 D50_to_XYZ = float3x3 (
           0.4552773,  0.2323025,  0.0145457,
           0.3675500,  0.7077956,  0.1049154,
           0.1413926,  0.0599019,  0.7057489);
		   
float3x3 XYZ_to_D50 = float3x3 (
           2.9603944, -0.9787684,  0.0844874,
          -1.4678519,  1.9161415, -0.2545973,
          -0.4685105,  0.0334540,  1.4216174);		    

	// Reading the texels

	float3 c   = tex2D(ReShade::BackBuffer, uv      ).rgb;
	float  w   = tex2D(ReShade::BackBuffer, uv      ).a;

	float3 scolor1 = plant(pow(c, float3(saturation, saturation, saturation)), max(max(c.r,c.g),c.b));
	float luma = dot(c, float3(0.299, 0.587, 0.114));
	float3 scolor2 = lerp(float3(luma, luma, luma), c, saturation);
	c = (saturation > 1.0) ? scolor1 : scolor2;

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

	color = pow(color, float3(1.0,1.0,1.0)*2.4);


	float3 warmer = mul(transpose(D50_to_XYZ),color);
	warmer = mul(transpose(XYZ_to_D65),warmer);
	warmer = clamp(warmer, 0.000000, 1.0);	
	
	float3 cooler = mul(transpose(D65_to_XYZ),color);
	cooler = mul(transpose(XYZ_to_D50),cooler);
	cooler = clamp(cooler, 0.000000, 1.0);	
	
	float m = abs(WP);
	
	float3 comp = (WP < 0.0) ? cooler : warmer;
	
	color = lerp(color, comp, m); 

	color = pow(color, float3(1.0,1.0,1.0)/2.4);
	color = clamp(color, 0.0, 1.0);
	
	color*=contr(color);
	
	return float4(clamp(color*brightness, 0.0, 1.0),w);
}

technique WinUaeColor
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WUColor;
	}
}
