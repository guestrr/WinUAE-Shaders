/*
   WinUAE Mask Shader
   
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
	ui_min = -1; ui_max = 8;
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
	ui_label = "Mask 0 Strength";
	ui_tooltip = "Mask 0 Strength";
> = 0.4;

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


// #define slotwidth    3.00     // Slot Mask Width
#define double_slot  1.00     // Slot Mask Height (1.0 or 2.0)

 
// Shadow mask (1-4 from PD CRT Lottes shader).
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
	else if (shadowMask == 0)
	{
		pos.x = frac(pos.x*0.5);
		float mc = 1.0 - CGWG;
		if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
		else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
	}    
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 1)
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
	else if (shadowMask == 2)
	{
		pos.x = frac(pos.x/3.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3)
	{
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4)
	{
		pos.xy = floor(pos.xy*float2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}
	
	// Alternate mask 5
	else if (shadowMask == 5)
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

	// Alternate mask 6
	else if (shadowMask == 6)
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
	
	// Alternate mask 7
	else if (shadowMask == 7)
	{
		float mx = max(max(c.r,c.g),c.b);
		float maskTmp = min(1.6*max(mx-0.25,0.0)/(1.0-0.25) ,1.0 + 0.6*(1.0-mx));
		mask = float3(maskTmp,maskTmp,maskTmp);
		pos.x = frac(pos.x/2.0);
		float mTemp = 1.0 + 0.6*(1.0-mx);
		if  (pos.x < 0.5) mask = float3(mTemp,mTemp,mTemp);
	}    
	
	// Alternate mask 8
	else if (shadowMask == 8)
	{
		float mx = max(max(c.r,c.g),c.b); mx = pow(mx, 1.5);
		pos.x = frac(pos.x*0.5);
		float3 maskd = float3(0.0,0.0,0.0);
		float3 maskb = float3(1.0,1.0,1.0);
		if (pos.x < 0.5) { maskd.g = 1.0;  maskb.r = 0.75; maskb.b = 0.75; }
		else { maskd.r = 1.0; maskd.b = 1.0; maskb.g = 0.75;}
		mask = lerp(maskd, maskb, mx);
	}    
	
	return mask;
}   


float SlotMask(float2 pos, float3 c)
{
	if (slotmask == 0.0) return 1.0;
	
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


float3 WMASK(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Reading the texels

	float3 c = tex2D(ReShade::BackBuffer, uv).rgb;

	float3 color = pow(c, float3(1.0,1.0,1.0)*MaskGamma);
	
	float2 pos1 = floor(uv/ReShade::PixelSize);
	
	color*=Mask(pos1, c);
	
	color = min(color, 1.0);
	
	color*=SlotMask(pos1, c);
	
	color = pow(color, float3(1.0,1.0,1.0)/MaskGamma);
	
	return color;
}

technique WinUaeMask
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WMASK;
	}
}