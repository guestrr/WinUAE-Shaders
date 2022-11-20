/*
   WinUAE Mask Glow Shader
   
   Copyright (C) 2020 guest(r) - guest.r@gmail.com

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

uniform int shadowMask < __UNIFORM_SLIDER_INT1
	ui_min = -1; ui_max = 10;
	ui_label = "CRT Mask Type";
	ui_tooltip = "CRT Mask Type";
> = 0;

uniform float MaskGamma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 3.0;
	ui_label = "Mask Gamma";
	ui_tooltip = "Mask Gamma";
> = 2.2;

uniform float CGWG < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Mask 0,1,2,3 Strength";
	ui_tooltip = "Mask 0,1,2,3 Strength";
> = 0.33;

uniform float maskDark < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Dark";
	ui_tooltip = "Mask Dark";
> = 0.50;

uniform float maskLight < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Light";
	ui_tooltip = "Mask Light";
> = 1.40;

uniform float slotmask < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Slotmask Strength";
	ui_tooltip = "Slotmask Strength";
> = 0.0;

uniform int slotwidth < __UNIFORM_SLIDER_INT1
	ui_min = 2; ui_max = 6;
	ui_label = "Slot Mask Width";
	ui_tooltip = "Slot Mask Width";
> = 2; 

uniform int masksize < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 2;
	ui_label = "CRT Mask Size";
	ui_tooltip = "CRT Mask Size";
> = 1; 

uniform int smasksize < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 2;
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

texture Shinra01L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler Shinra01SL { Texture = Shinra01L; MinFilter = Linear; MagFilter = Linear; }; 

texture Shinra02L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Shinra02SL { Texture = Shinra02L; MinFilter = Linear; MagFilter = Linear; }; 

texture Shinra03L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Shinra03SL { Texture = Shinra03L; MinFilter = Linear; MagFilter = Linear; };  


float4 PASS_SH0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	float4 color = min(tex2D(ReShade::BackBuffer, uv),1.0);
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


#define double_slot  1.00     // Slot Mask Height (1.0 or 2.0)

 
// Shadow mask (4-7 from PD CRT Lottes shader).
float3 Mask(float2 pos, float3 c)
{
	pos = floor(pos/float(masksize));
	float3 mask = float3(maskDark, maskDark, maskDark);
	
	// No mask
	if (shadowMask == -1)
	{
		mask = float3(1.0,1.0,1.0);
	}       
	
	// Phosphor.
	else if (shadowMask == 0 || shadowMask == 2)
	{
		pos.x = frac(pos.x*0.5);
		float mc = 1.0 - CGWG;
		if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
		else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
	}    

	// RGB Mask.
	else if (shadowMask == 1)
	{
		pos.x = frac(pos.x/3.0);
		float mc = 1.1 - CGWG;
		mask = float3(mc, mc, mc);
		
		if      (pos.x < 0.333) mask.r = 1.0;
		else if (pos.x < 0.666) mask.g = 1.0;
		else                    mask.b = 1.0;
	} 

	// Phosphor.
	else if (shadowMask == 3)
	{
		pos.x = frac((pos.x + pos.y)*0.5);
		float mc = 1.0 - CGWG;
		if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
		else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
	}
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 4)
	{
		float line1 = maskLight;
		float odd  = 0.0;

		if (frac(pos.x/6.0) < 0.5)
			odd = 1.0;
		if (frac((pos.y + odd)/2.0) < 0.5)
			line1 = maskDark;

		pos.x = frac(pos.x/3.0);
    
		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
		
		mask*=line1;  
	} 

	// Aperture-grille.
	else if (shadowMask == 5)
	{
		pos.x = frac(pos.x/3.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 6)
	{
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 7)
	{
		pos.xy = floor(pos.xy*float2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}
	
	// Alternate mask 8
	else if (shadowMask == 8)
	{
		float mx = max(max(c.r,c.g),c.b);
		float fTemp = min( 1.25*max(mx-0.25,0.0)/(1.0-0.25) ,maskDark + 0.2*(1.0-maskDark)*mx);
		float3 maskTmp = float3(fTemp,fTemp,fTemp);
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);	
		mask = maskTmp;
		pos.x = frac(pos.x/2.0);
		if  (pos.x < 0.5)
		{	mask.r  = adj;
			mask.b  = adj;
		}
		else     mask.g = adj;
	}    

	// Alternate mask 9
	else if (shadowMask == 9)
	{
		float mx = max(max(c.r,c.g),c.b);
		float fTemp = min( 1.33*max(mx-0.25,0.0)/(1.0-0.25) ,maskDark + 0.225*(1.0-maskDark)*mx);
		float3 maskTmp = float3(fTemp,fTemp,fTemp);
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);
		mask = maskTmp;
		pos.x = frac(pos.x/3.0);
		if      (pos.x < 0.333) mask.r = adj;
		else if (pos.x < 0.666) mask.g = adj;
		else                    mask.b = adj; 
	}
	
	// Alternate mask 10
	else if (shadowMask == 10)
	{
		float mx = max(max(c.r,c.g),c.b);
		float maskTmp = min(1.6*max(mx-0.25,0.0)/(1.0-0.25) ,1.0 + 0.6*(1.0-mx));
		mask = float3(maskTmp,maskTmp,maskTmp);
		pos.x = frac(pos.x/2.0);
		float mTemp = 1.0 + 0.6*(1.0-mx);
		if  (pos.x < 0.5) mask = float3(mTemp,mTemp,mTemp);
	}    
	
	return mask;
}   


float SlotMask(float2 pos, float3 c)
{
	if (slotmask == 0.0) return 1.0;
	
	pos = floor(pos/float(smasksize));
	
	float mx = pow(max(max(c.r,c.g),c.b),1.33);
	float mlen = float(slotwidth)*2.0;
	float px = frac(pos.x/mlen);
	float py = floor(frac(pos.y/(2.0*double_slot))*2.0*double_slot);
	float slot_dark = lerp(1.0-slotmask, 1.0-0.80*slotmask, mx);
	float slot = 1.0 + 0.7*slotmask*(1.0-mx);
	if (py == 0.0 && px <  0.5) slot = slot_dark; else
	if (py == double_slot && px >= 0.5) slot = slot_dark;		
	
	return slot;
}

float3 declip(float3 c, float b)
{
	float m = max(max(c.r,c.g),c.b);
	if (m > b) c = c*b/m;
	return c;
} 

float3 WMASK(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{	
	float w3 = min(tex2D(ReShade::BackBuffer, uv).a, 1.0); if (w3 == 0.0) w3 = 1.0;
	float2 dx = float2(ReShade::PixelSize.x, 0.0);
	float3 color0 = tex2D(Shinra01SL, uv - dx).rgb;
	float3 color  = tex2D(Shinra01SL, uv).rgb;
	float3 color1 = tex2D(Shinra01SL, uv + dx).rgb;	
	float3 b11 = tex2D(Shinra03SL, uv).rgb;
	float3 mcolor = (color0+color+color1)/3.0;
	
	float2 pos1 = floor(uv/ReShade::PixelSize);
	
	float3 cmask = Mask(pos1, pow(mcolor, float3(1.0,1.0,1.0)/MaskGamma));
	
	float3 orig1 = color; float3 one = float3(1.0,1.0,1.0);
	
	if (shadowMask == 0 || shadowMask == 1 || shadowMask == 3) color = pow(color, float3(1.0,1.0,1.0)/MaskGamma);
	
	color*=cmask;

	if (shadowMask == 0 || shadowMask == 1 || shadowMask == 3) color = pow(color, float3(1.0,1.0,1.0)*MaskGamma);
	
	color = min(color, 1.0);
	
	color*=SlotMask(pos1, mcolor);

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