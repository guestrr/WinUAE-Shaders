/*
   WinUAE Mask Glow Shader (Advanced)
   
   Copyright (C) 2020-2022 guest(r) - guest.r@gmail.com

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

uniform float warpX  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.5;
	ui_label = "CurvatureX";
	ui_tooltip = "CurvatureX";
> = 0.0;

uniform float warpY  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.5;
	ui_label = "CurvatureY";
	ui_tooltip = "CurvatureY";
> = 0.0;

uniform float c_shape  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.05; ui_max = 0.6;
	ui_label = "Curvature Shape";
	ui_tooltip = "Curvature Shape";
> = 0.25;

uniform float bsize1  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 3.0;
	ui_label = "Border Size";
	ui_tooltip = "Border Size";
> = 0.02;

uniform float sborder  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 2.0;
	ui_label = "Border Intensity";
	ui_tooltip = "Border Intensity";
> = 0.75;

uniform int shadowMask < __UNIFORM_SLIDER_INT1
	ui_min = -1; ui_max = 12;
	ui_label = "CRT Mask Type";
	ui_tooltip = "CRT Mask Type";
> = 0;

uniform float MaskGamma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 3.0;
	ui_label = "Mask Gamma";
	ui_tooltip = "Mask Gamma";
> = 2.2;

uniform float maskstr < __UNIFORM_SLIDER_FLOAT1
	ui_min = -0.5; ui_max = 1.0;
	ui_label = "Mask Strength masks: 0, 5-13";
	ui_tooltip = "Mask Strength masks: 0, 5-13";
> = 0.33;

uniform float mcut < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Strength Low (masks: 5-10, 13)";
	ui_tooltip = "Mask Strength Low (masks: 5-10, 13)";
> = 1.10;

uniform int mshift < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 8;
	ui_label = "Mask Shift/Stagger";
	ui_tooltip = "Mask Shift/Stagger";
> = 0; 

uniform int mask_layout < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 1;
	ui_label = "Mask Layout: RGB or BGR (check LCD panel)";
	ui_tooltip = "Mask Layout: RGB or BGR (check LCD panel)";
> = 0; 

uniform float maskDark < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Dark (masks 1-4)";
	ui_tooltip = "Mask Dark (masks 1-4)";
> = 0.50;

uniform float maskLight < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Light";
	ui_tooltip = "Mask Light";
> = 1.50;

uniform float slotmask < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Slotmask Strength Bright Pixels";
	ui_tooltip = "Slotmask Strength Bright Pixels";
> = 0.0;

uniform float slotmask1 < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Slotmask Strength Dark Pixels";
	ui_tooltip = "Slotmask Strength Dark Pixels";
> = 0.0;

uniform int slotwidth < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 8;
	ui_label = "Slot Mask Width";
	ui_tooltip = "Slot Mask Width";
> = 2; 

uniform int double_slot < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 4;
	ui_label = "Slot Mask Heigth";
	ui_tooltip = "Slot Mask Heigth";
> = 1; 

uniform int masksize < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 3;
	ui_label = "CRT Mask Size";
	ui_tooltip = "CRT Mask Size";
> = 1; 

uniform int smasksize < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 3;
	ui_label = "Slot Mask Size";
	ui_tooltip = "Slot Mask Size";
> = 1; 

uniform float bloom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Bloom Strength";
	ui_tooltip = "Bloom Strength";
> = 0.0;

uniform float halation < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Halation Strength";
	ui_tooltip = "Halation Strength";
> = 0.0;

uniform float glow < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.25;
	ui_label = "Glow Strength";
	ui_tooltip = "Glow Strength";
> = 0.0;


uniform float glow_size < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 6.0;
	ui_label = "Glow Size";
	ui_tooltip = "Glow Size";
> = 2.0;

uniform float wclip < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Scanline preservation w. Bloom";
	ui_tooltip = "Scanline preservation w. Bloom";
> = 0.5;

uniform float decons < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Deconvergence Strength";
	ui_tooltip = "Deconvergence Strength";
> = 1.0;


uniform float deconrr < __UNIFORM_SLIDER_FLOAT1
	ui_min = -8.0; ui_max = 8.0;
	ui_label = "Deconvergence Red Horizontal";
	ui_tooltip = "Deconvergence Red Horizontal";
> = 0.0;

uniform float deconrg < __UNIFORM_SLIDER_FLOAT1
	ui_min = -8.0; ui_max = 8.0;
	ui_label = "Deconvergence Green Horizontal";
	ui_tooltip = "Deconvergence Green Horizontal";
> = 0.0;

uniform float deconrb < __UNIFORM_SLIDER_FLOAT1
	ui_min = -8.0; ui_max = 8.0;
	ui_label = "Deconvergence Blue Horizontal";
	ui_tooltip = "Deconvergence Blue Horizontal";
> = 0.0;

uniform float deconrry < __UNIFORM_SLIDER_FLOAT1
	ui_min = -8.0; ui_max = 8.0;
	ui_label = "Deconvergence Red Vertical";
	ui_tooltip = "Deconvergence Red Vertical";
> = 0.0;

uniform float deconrgy < __UNIFORM_SLIDER_FLOAT1
	ui_min = -8.0; ui_max = 8.0;
	ui_label = "Deconvergence Green Vertical";
	ui_tooltip = "Deconvergence Green Vertical";
> = 0.0;

uniform float deconrby < __UNIFORM_SLIDER_FLOAT1
	ui_min = -8.0; ui_max = 8.0;
	ui_label = "Deconvergence Blue Vertical";
	ui_tooltip = "Deconvergence Blue Vertical";
> = 0.0;


texture Shinra01L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler Shinra01SL { Texture = Shinra01L; MinFilter = Linear; MagFilter = Linear; }; 

texture Shinra02L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Shinra02SL { Texture = Shinra02L; MinFilter = Linear; MagFilter = Linear; }; 

texture Shinra03L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Shinra03SL { Texture = Shinra03L; MinFilter = Linear; MagFilter = Linear; };  


float4 PASS_SH0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, uv);
	color = min(color, 1.0);
	return float4 (pow(color.rgb, float3(1.0, 1.0, 1.0) * MaskGamma),1.0);
}


float4 PASS_SH1(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
		float4 color = tex2D(Shinra01SL, uv) * 0.19744746769063704;
		color += tex2D(Shinra01SL, uv + float2(1.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.1746973469158936;
		color += tex2D(Shinra01SL, uv - float2(1.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.1746973469158936;
		color += tex2D(Shinra01SL, uv + float2(2.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.12099884565428047;
		color += tex2D(Shinra01SL, uv - float2(2.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.12099884565428047;
		color += tex2D(Shinra01SL, uv + float2(3.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.06560233156931679;
		color += tex2D(Shinra01SL, uv - float2(3.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.06560233156931679;
		color += tex2D(Shinra01SL, uv + float2(4.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.027839605612666265;
		color += tex2D(Shinra01SL, uv - float2(4.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.027839605612666265;
		color += tex2D(Shinra01SL, uv + float2(5.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.009246250740395456;
		color += tex2D(Shinra01SL, uv - float2(5.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.009246250740395456;
		color += tex2D(Shinra01SL, uv + float2(6.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.002403157286908872;
		color += tex2D(Shinra01SL, uv - float2(6.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.002403157286908872;		
		color += tex2D(Shinra01SL, uv + float2(7.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.00048872837522002;
		color += tex2D(Shinra01SL, uv - float2(7.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.00048872837522002;
		
	return color;
}

float4 PASS_SH2(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
		float4 color = tex2D(Shinra02SL, uv) * 0.19744746769063704;
		color += tex2D(Shinra02SL, uv + float2(0.0, 1.0*glow_size * ReShade::PixelSize.y)) * 0.1746973469158936;
		color += tex2D(Shinra02SL, uv - float2(0.0, 1.0*glow_size * ReShade::PixelSize.y)) * 0.1746973469158936;
		color += tex2D(Shinra02SL, uv + float2(0.0, 2.0*glow_size * ReShade::PixelSize.y)) * 0.12099884565428047;
		color += tex2D(Shinra02SL, uv - float2(0.0, 2.0*glow_size * ReShade::PixelSize.y)) * 0.12099884565428047;
		color += tex2D(Shinra02SL, uv + float2(0.0, 3.0*glow_size * ReShade::PixelSize.y)) * 0.06560233156931679;
		color += tex2D(Shinra02SL, uv - float2(0.0, 3.0*glow_size * ReShade::PixelSize.y)) * 0.06560233156931679;
		color += tex2D(Shinra02SL, uv + float2(0.0, 4.0*glow_size * ReShade::PixelSize.y)) * 0.027839605612666265;
		color += tex2D(Shinra02SL, uv - float2(0.0, 4.0*glow_size * ReShade::PixelSize.y)) * 0.027839605612666265;
		color += tex2D(Shinra02SL, uv + float2(0.0, 5.0*glow_size * ReShade::PixelSize.y)) * 0.009246250740395456;
		color += tex2D(Shinra02SL, uv - float2(0.0, 5.0*glow_size * ReShade::PixelSize.y)) * 0.009246250740395456;
		color += tex2D(Shinra02SL, uv + float2(0.0, 6.0*glow_size * ReShade::PixelSize.y)) * 0.002403157286908872;
		color += tex2D(Shinra02SL, uv - float2(0.0, 6.0*glow_size * ReShade::PixelSize.y)) * 0.002403157286908872;
		color += tex2D(Shinra02SL, uv + float2(0.0, 7.0*glow_size * ReShade::PixelSize.y)) * 0.00048872837522002;
		color += tex2D(Shinra02SL, uv - float2(0.0, 7.0*glow_size * ReShade::PixelSize.y)) * 0.00048872837522002;
		
	return color;
} 


 
// Shadow mask (1-4 from PD CRT Lottes shader).

float3 Mask(float2 pos, float mx)
{
	float2 pos0 = pos;
	pos.y = floor(pos.y/masksize);
	float next_line = float(frac(pos.y*0.5) > 0.25);
	pos0.x = pos0.x + next_line * mshift;
	pos = floor(pos0/masksize);

	float3 mask = float3(maskDark, maskDark, maskDark);
	float3 one = float3(1.0.xxx);
	float dark_compensate  = lerp(max( clamp( lerp (mcut, maskstr, mx),0.0, 1.0) - 0.4, 0.0) + 1.0, 1.0, mx);
	float mc = 1.0 - max(maskstr, 0.0);	
	
	// No mask
	if (shadowMask == -1.0)
	{
		mask = float3(1.0.xxx);
	}       
	
	// Phosphor.
	else if (shadowMask == 0.0)
	{
		pos.x = frac(pos.x*0.5);
		if (pos.x < 0.49) { mask.r = 1.0; mask.g = mc; mask.b = 1.0; }
		else { mask.r = mc; mask.g = 1.0; mask.b = mc; }
	}    
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 1.0)
	{
		float lline = maskLight;
		float odd  = 0.0;

		if (frac(pos.x/6.0) < 0.49)
			odd = 1.0;
		if (frac((pos.y + odd)/2.0) < 0.49)
			lline = maskDark;

		pos.x = frac(pos.x/3.0);
    
		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                  mask.b = maskLight;
		
		mask*=lline;  
	} 

	// Aperture-grille.
	else if (shadowMask == 2.0)
	{
		pos.x = frac(pos.x/3.0);

		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                  mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3.0)
	{
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                  mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4.0)
	{
		pos.xy = floor(pos.xy*float2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                  mask.b = maskLight;
	}
	
	// Trinitron mask 5
	else if (shadowMask == 5.0)
	{
		mask = float3(0.0.xxx);		
		pos.x = frac(pos.x/2.0);
		if  (pos.x < 0.49)
		{	mask.r  = 1.0;
			mask.b  = 1.0;
		}
		else     mask.g = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// Trinitron mask 6
	else if (shadowMask == 6.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/3.0);
		if      (pos.x < 0.3) mask.r = 1.0;
		else if (pos.x < 0.6) mask.g = 1.0;
		else                  mask.b = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}
	
	// BW Trinitron mask 7
	else if (shadowMask == 7.0)
	{
		mask = float3(0.0.xxx);		
		pos.x = frac(pos.x/2.0);
		if  (pos.x < 0.49)
		{	mask  = 0.0.xxx;
		}
		else     mask = 1.0.xxx;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// BW Trinitron mask 8
	else if (shadowMask == 8.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/3.0);
		if      (pos.x < 0.3) mask = 0.0.xxx;
		else if (pos.x < 0.6) mask = 1.0.xxx;
		else                  mask = 1.0.xxx;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// Magenta - Green - Black mask
	else if (shadowMask == 9.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/3.0);
		if      (pos.x < 0.3) mask    = 0.0.xxx;
		else if (pos.x < 0.6) mask.rb = 1.0.xx;
		else                  mask.g  = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;	
	}  
	
	// RGBX
	else if (shadowMask == 10.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x * 0.25);
		if      (pos.x < 0.2)  mask  = 0.0.xxx;
		else if (pos.x < 0.4)  mask.r = 1.0;
		else if (pos.x < 0.7)  mask.g = 1.0;	
		else                   mask.b = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;		
	}  

	// 4k mask
	else if (shadowMask == 11.0)
	{
		mask = float3(mc.xxx);
		pos.x = frac(pos.x * 0.25);
		if      (pos.x < 0.2)  mask.r  = 1.0;
		else if (pos.x < 0.4)  mask.rg = 1.0.xx;
		else if (pos.x < 0.7)  mask.gb = 1.0.xx;	
		else                   mask.b  = 1.0;	
	}     
	else if (shadowMask == 12.0)
	{
		mask = float3(mc.xxx);
		pos.x = frac(pos.x * 0.25);
		if      (pos.x < 0.2)  mask.r  = 1.0;
		else if (pos.x < 0.4)  mask.rb = 1.0.xx;
		else if (pos.x < 0.7)  mask.gb = 1.0.xx;	
		else                   mask.g  = 1.0;	
	}     
 
	return mask;
}

float SlotMask(float2 pos, float m)
{
	if ((slotmask + slotmask1) == 0.0) return 1.0;
	else
	{
	pos = floor(pos/smasksize);
	float mlen = slotwidth*2.0;
	float px = frac(pos.x/mlen);
	float py = floor(frac(pos.y/(2.0*double_slot))*2.0*double_slot);
	float slot_dark = lerp(1.0-slotmask1, 1.0-slotmask, m);
	float slot = 1.0;
	if (py == 0.0 && px <  0.5) slot = slot_dark; else
	if (py == double_slot && px >= 0.5) slot = slot_dark;		
	
	return slot;
	}
}    

float3 declip(float3 c, float b)
{
	float m = max(max(c.r,c.g),c.b);
	if (m > b) c = c*b/m;
	return c;
} 

float2 Warp(float2 pos)
{
	pos  = pos*2.0-1.0;    
	pos  = lerp(pos, float2(pos.x*rsqrt(1.0-c_shape*pos.y*pos.y), pos.y*rsqrt(1.0-c_shape*pos.x*pos.x)), float2(warpX, warpY)/c_shape);
	return pos*0.5 + 0.5;
}

float corner(float2 pos) {
	float2 b = float2(bsize1, bsize1) *  float2(1.0, ReShade::PixelSize.x/ReShade::PixelSize.y) * 0.05;
	pos = clamp(pos, 0.0, 1.0);
	pos = abs(2.0*(pos - 0.5));
	float2 res = (bsize1 == 0.0) ? 1.0.xx : lerp(0.0.xx, 1.0.xx, smoothstep(1.0.xx, 1.0.xx-b, sqrt(pos)));
	res = pow(res, sborder.xx);	
	return sqrt(res.x*res.y);
} 


void fetch_pixel (inout float3 c, inout float3 b, float2 coord, float2 bcoord)
{
		float stepx = ReShade::PixelSize.x;
		float stepy = ReShade::PixelSize.y;
		
		float ds = decons;
				
		float2 dx = float2(stepx, 0.0);
		float2 dy = float2(0.0, stepy);		
		
		float posx = 2.0*coord.x - 1.0;
		float posy = 2.0*coord.y - 1.0;

		float2 rc = deconrr * dx + deconrry*dy;
		float2 gc = deconrg * dx + deconrgy*dy;
		float2 bc = deconrb * dx + deconrby*dy;		

		float r1 = tex2D(Shinra01SL, coord + rc).r;
		float g1 = tex2D(Shinra01SL, coord + gc).g;
		float b1 = tex2D(Shinra01SL, coord + bc).b;

		float3 d = float3(r1, g1, b1);
		c = clamp(lerp(c, d, ds), 0.0, 1.0);
		
		r1 = tex2D(Shinra03SL, bcoord + rc).r;
		g1 = tex2D(Shinra03SL, bcoord + gc).g;
		b1 = tex2D(Shinra03SL, bcoord + bc).b;

		d = float3(r1, g1, b1);
		b = clamp(lerp(b, d, ds), 0.0, 1.0);
}


float3 WMASK(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{	
	
	float2 coord = Warp(uv);
	
	float w3 = min(tex2D(ReShade::BackBuffer, coord).a, 1.0); if (w3 == 0.0) w3 = 1.0;
	float2 dx = float2(0.00075, 0.0);
	float3 color0 = tex2D(Shinra01SL, coord - dx).rgb;
	float3 color  = tex2D(Shinra01SL, coord).rgb;
	float3 color1 = tex2D(Shinra01SL, coord + dx).rgb;	
	float3 b11 = tex2D(Shinra03SL, coord).rgb;

	fetch_pixel(color, b11, coord, coord); 

	float3 mcolor = max(max(color0,color),color1);
	float mx = max(max(mcolor.r, mcolor.g), mcolor.b);
	mx = pow(mx, 1.4/MaskGamma);
	
	float2 pos1 = floor(uv/ReShade::PixelSize);
	
	float3 cmask = Mask(pos1, mx);
	
	if (mask_layout > 0.5) cmask = cmask.rbg;
 	
	float3 orig1 = color; float3 one = float3(1.0,1.0,1.0);
	
	color*=cmask;
	
	color = min(color, 1.0);
	
	color*=SlotMask(pos1, mx);

	float3 Bloom1 = 2.0*b11*b11;
	Bloom1 = min(Bloom1, 0.75);
	float bmax = max(max(Bloom1.r,Bloom1.g),Bloom1.b);
	float pmax = 0.85;
	Bloom1 = min(Bloom1, pmax*bmax)/pmax;
	
	Bloom1 = lerp(min( Bloom1, color), Bloom1, 0.5*(orig1+color));
	
	Bloom1 = bloom*Bloom1;
	
	color = color + Bloom1;
	color = color + glow*b11;
	
	color = min(color, 1.0); 

	color = declip(color, pow(w3,wclip));
	
	color = min(color, lerp(min(cmask,1.0),one,0.5));

	float maxb = max(max(b11.r,b11.g),b11.b);
	maxb = sqrt(maxb);
	float3 Bloom = b11;
	float colmx = max(max(orig1.r,orig1.g),orig1.b)/w3;

	Bloom = lerp(0.5*(Bloom + Bloom*Bloom), Bloom*Bloom, colmx);	
	color = color + (0.75+maxb)*Bloom*(0.75 + 0.70*pow(colmx,0.33333))*lerp(1.0,w3,0.5*colmx)*lerp(one,cmask,0.35 + 0.4*maxb)*halation; 

	color = pow(color, float3(1.0,1.0,1.0)/MaskGamma);

	color = color*corner(coord);
	
	return color;
}

technique WinUaeMask
{
	
	pass bloom1
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH0;
		RenderTarget = Shinra01L; 		
	}
	
	pass bloom2
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH1;
		RenderTarget = Shinra02L; 		
	}

	pass bloom3
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH2;
		RenderTarget = Shinra03L; 		
	}	 
	
	pass mask
	{
		VertexShader = PostProcessVS;
		PixelShader = WMASK;
	}
}