/*
    CRT (Geom) shader

    Copyright (C) 2010-2012 cgwg, Themaister and DOLLS

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.

    (cgwg gave their consent to have the original version of this shader
    distributed under the GPL in this message:

        http://board.byuu.org/viewtopic.php?p=26075#p26075

        "Feel free to distribute my shaders under the GPL. After all, the
        barrel distortion code was taken from the Curvature shader, which is
        under the GPL."
*/


// Tweakable options
		
#define CRTgamma 2.4
#define monitorgamma 2.6
#define brightboost 1.0
#define saturation  1.1
#define sharpness   1.0   // 1.0 to 4.0
#define scanstr     0.33  // 0.3 dark, 0.4 bright


#define eps 1e-8

// Use the older, purely gaussian beam profile
//#define USEGAUSSIAN
		
		
// The name of this effect
string name : NAME = "CrtGeom";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "CrtGeom";

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

        // Macros.
        #define FIX(c) max(abs(c), 1e-5);
        #define PI 3.141592653589

        #ifdef LINEAR_PROCESSING
        #       define TEX2D(c) pow(tex2D(decal, (c)), float4(CRTgamma, CRTgamma, CRTgamma, CRTgamma))
        #else
        #       define TEX2D(c) tex2D(decal, (c))
        #endif

        // Calculate the influence of a scanline on the current pixel.
        //
        // 'distance' is the distance in texture coordinates from the current
        // pixel to the scanline in question.
        // 'color' is the colour of the scanline at the horizontal location of
        // the current pixel.
        float4 scanlineWeights(float distance, float4 color)
        {
                // "wid" controls the width of the scanline beam, for each RGB
                // channel The "weights" lines basically specify the formula
                // that gives you the profile of the beam, i.e. the intensity as
                // a function of distance from the vertical center of the
                // scanline. In this case, it is gaussian if width=2, and
                // becomes nongaussian for larger widths. Ideally this should
                // be normalized so that the integral across the beam is
                // independent of its width. That is, for a narrower beam
                // "weights" should have a higher peak at the center of the
                // scanline than for a wider beam.
        #ifdef USEGAUSSIAN
                float4 wid = 0.3 + 0.1 * pow(color, float4(3.0,3.0,3.0,3.0));
                float4 weights = float4(distance,distance,distance,distance) / wid;
                return 0.4 * exp(-weights * weights) / wid;
        #else
                float4 wid = 2.0 + 2.0 * pow(color, float4(4.0,4.0,4.0,4.0));
                float4 weights = float4(distance,distance,distance,distance) / scanstr;
                return 1.4 * exp(-pow(weights * pow(0.5 * wid, -0.5), wid)) / (0.6 + 0.2 * wid);
        #endif
        }
		
float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
				float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
				float2 ps = ps1*tmp;
					
				float2 TextureSize = float2(1.0/ps.x, 1.0/ps.y);
	
				// Calculating texel coordinates

				float2 size     = TextureSize;
				float2 inv_size = 1.0/TextureSize;
	
                // Here's a helpful diagram to keep in mind while trying to
                // understand the code:
                //
                //  |      |      |      |      |
                // -------------------------------
                //  |      |      |      |      |
                //  |  01  |  11  |  21  |  31  | <-- current scanline
                //  |      | @    |      |      |
                // -------------------------------
                //  |      |      |      |      |
                //  |  02  |  12  |  22  |  32  | <-- next scanline
                //  |      |      |      |      |
                // -------------------------------
                //  |      |      |      |      |
                //
                // Each character-cell represents a pixel on the output
                // surface, "@" represents the current pixel (always somewhere
                // in the bottom half of the current scan-line, or the top-half
                // of the next scanline). The grid of lines represents the
                // edges of the texels of the underlying texture.

                // Texture coordinates of the texel containing the active pixel.
                float2 xy = VAR.t0;

                //float cval = corner(xy);

                // Of all the pixels that are mapped onto the texel we are
                // currently rendering, which pixel are we currently rendering?
                float2 ratio_scale = xy * size - float2(0.5,0.5);

                float2 uv_ratio = frac(ratio_scale);

                // Snap to the center of the underlying texel.
                xy = (floor(ratio_scale) + float2(0.5,0.5)) / size;

                // Calculate Lanczos scaling coefficients describing the effect
                // of various neighbour texels in a scanline on the current
                // pixel.
                float4 coeffs = PI * float4(1.0 + uv_ratio.x, uv_ratio.x, 1.0 - uv_ratio.x, 2.0 - uv_ratio.x);

                // Prevent division by zero.
                coeffs = FIX(coeffs);

                // Lanczos2 kernel.
                coeffs = 2.0 * sin(coeffs) * sin(coeffs / 2.0) / (coeffs * coeffs);
				
				// Apply sharpness hack
				coeffs = sign(coeffs)*pow(abs(coeffs), float4(sharpness,sharpness,sharpness,sharpness));

                // Normalize.
                coeffs /= dot(coeffs, float4(1.0,1.0,1.0,1.0));

                // Calculate the effective colour of the current and next
                // scanlines at the horizontal location of the current pixel,
                // using the Lanczos coefficients above.
                float4 col  = clamp(
                        mul(coeffs, float4x4(
                                TEX2D(xy + float2(-inv_size.x, 0.0)),
                                TEX2D(xy),
                                TEX2D(xy + float2(inv_size.x, 0.0)),
                                TEX2D(xy + float2(2.0 * inv_size.x, 0.0))
                        )), 0.0, 1.0);
                float4 col2 = clamp(
                        mul(coeffs, float4x4(
                               TEX2D(xy + float2(-inv_size.x, inv_size.y)),
                               TEX2D(xy + float2(0.0, inv_size.y)),
                               TEX2D(xy + inv_size),
                               TEX2D(xy + float2(2.0 * inv_size.x, inv_size.y))
                        )), 0.0, 1.0);


                col  = pow(col , float4(CRTgamma,CRTgamma,CRTgamma,CRTgamma));
                col2 = pow(col2, float4(CRTgamma,CRTgamma,CRTgamma,CRTgamma));

                // Calculate the influence of the current and next scanlines on
                // the current pixel.
                float4 weights  = scanlineWeights(uv_ratio.y, col);
                float4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

                float3 mul_res  = (col * weights + col2 * weights2).rgb; // * float3(cval,cval,cval);

                // dot-mask emulation:
                // Output pixels are alternately tinted green and magenta.
                // float3 dotMaskWeights = lerp(
                //        float3(1.0, 0.7, 1.0),
                //        float3(0.7, 1.0, 0.7),
                //        floor(mod(mod_factor, 2.0))
                //    );

                // mul_res *= dotMaskWeights;

                // Convert the image gamma for display on our output device.
                mul_res = pow(mul_res, float3(1.0 / monitorgamma,1.0 / monitorgamma,1.0 / monitorgamma));

				// Saturation
				float l = length(mul_res);
				mul_res = normalize(pow(mul_res + eps, float3(saturation, saturation, saturation)))*l;		
				
                // Color the texel.
                return float4(mul_res*brightboost, 1.0);
}


//
// Technique
//

technique CrtGeom
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

