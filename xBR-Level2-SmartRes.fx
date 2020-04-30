/*
   Hyllian's xBR-lv2b Shader (with Accuracy feature)
   
   Copyright (C) 2011-2015 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

   Incorporates some of the ideas from SABR shader. Thanks to Joshua Street.
*/
 
// Uncomment just one of the three params below to choose the corner detection
//#define CORNER_A
//#define CORNER_B
#define CORNER_C
//#define CORNER_D

#define XBR_SCALE 4.0
 
// The name of this effect
string name : NAME = "xBR";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "xBR";

texture SourceTexture	        : SOURCETEXTURE;
texture WorkingTexture          : WORKINGTEXTURE;

sampler	decal = sampler_state
{
	Texture	  = (SourceTexture);
	MinFilter = POINT;
	MagFilter = POINT;
};


#define XBR_Y_WEIGHT 48.0
#define XBR_EQ_THRESHOLD 15.0
#define XBR_LV2_COEFFICIENT 2.0 

const static float3 rgbw           = float3(14.352, 28.176, 5.472); 
const static float coef            = 2.0;
const static float4 eq_threshold   = float4(15.0, 15.0, 15.0, 15.0);
const static float y_weight        = 48.0;
const static float u_weight        = 7.0;
const static float v_weight        = 6.0;
const static float3x3 yuv          = float3x3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
const static float3x3 yuv_weighted = float3x3(y_weight*yuv[0], u_weight*yuv[1], v_weight*yuv[2]);
const static float4 epsilon        = float4(1e-12, 0.0, 0.0, 0.0);   

float4 df(float4 A, float4 B)
{
	return float4(abs(A-B));
}

float c_df(float3 c1, float3 c2) {
                        float3 df = abs(c1 - c2);
                        return df.r + df.g + df.b;
                }

bool4 eq(float4 A, float4 B)
{
	return (df(A, B) < eq_threshold);
}

float4 weighted_distance(float4 a, float4 b, float4 c, float4 d, float4 e, float4 f, float4 g, float4 h)
{
	return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}


struct out_vertex {
	float4 position : POSITION;
	float4 color    : COLOR;
	float2 t0       : TEXCOORD0;
}; 
 

out_vertex  VS_VERTEX(float3 position : POSITION, float2 texCoord : TEXCOORD0 )
{ 
	out_vertex OUT = (out_vertex)0;

	OUT.position = mul(float4(position,1),WorldViewProjection);

	//    A1 B1 C1
	// A0  A  B  C C4
	// D0  D  E  F F4
	// G0  G  H  I I4
	//    G5 H5 I5

	// This line fix a bug in ATI cards.
	texCoord = texCoord * float2(1.0001, 1.0001);

	OUT.t0 = texCoord;
	return OUT;  
}


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	bool4 edr, edri, edr_left, edr_up, px; // px = pixel, edr = edge detection rule
	bool4 interp_restriction_lv0, interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
	bool4 nc, nc30, nc60, nc45; // new_color
	float4 fx, fx_left, fx_up;

 	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;
  
	float2 fp = frac(VAR.t0/ps);
	float4 delta         = float4(1.0/XBR_SCALE, 1.0/XBR_SCALE, 1.0/XBR_SCALE, 1.0/XBR_SCALE);
	float4 deltaL        = float4(0.5/XBR_SCALE, 1.0/XBR_SCALE, 0.5/XBR_SCALE, 1.0/XBR_SCALE);
	float4 deltaU        = deltaL.yxwz; 
	
    float2 TexCoord_0 = (floor(VAR.t0/ps) + float2(0.5,0.5))*ps;

	float x = ps.x;
	float y = ps.y;
	
    float2 dx         = float2( x, 0.0);
    float2 dy         = float2( 0.0, y);
    float2 x2         = float2( 2.0*x , 0.0);
    float2 y2         = float2( 0.0 , 2.0*y);
    float4 xy         = float4( x, y,-x,-y);  
    float4 zw         = float4( 2.0*x , y,-2.0*x ,-y);  
    float4 wz         = float4( x, 2.0*y ,-x,-2.0*y );  
	
    float3 A  = tex2D(decal, TexCoord_0 + xy.zw ).xyz;
    float3 B  = tex2D(decal, TexCoord_0     -dy ).xyz;
    float3 C  = tex2D(decal, TexCoord_0 + xy.xw ).xyz;
    float3 D  = tex2D(decal, TexCoord_0 - dx    ).xyz;
    float3 E  = tex2D(decal, TexCoord_0         ).xyz;
    float3 F  = tex2D(decal, TexCoord_0 + dx    ).xyz;
    float3 G  = tex2D(decal, TexCoord_0 + xy.zy ).xyz;
    float3 H  = tex2D(decal, TexCoord_0     +dy ).xyz;
    float3 I  = tex2D(decal, TexCoord_0 + xy.xy ).xyz;
    float3 A1 = tex2D(decal, TexCoord_0 + wz.zw ).xyz;
    float3 C1 = tex2D(decal, TexCoord_0 + wz.xw ).xyz;
    float3 A0 = tex2D(decal, TexCoord_0 + zw.zw ).xyz;
    float3 G0 = tex2D(decal, TexCoord_0 + zw.zy ).xyz;
    float3 C4 = tex2D(decal, TexCoord_0 + zw.xw ).xyz;
    float3 I4 = tex2D(decal, TexCoord_0 + zw.xy ).xyz;
    float3 G5 = tex2D(decal, TexCoord_0 + wz.zy ).xyz;
    float3 I5 = tex2D(decal, TexCoord_0 + wz.xy ).xyz;
    float3 B1 = tex2D(decal, TexCoord_0 - y2    ).xyz;
    float3 D0 = tex2D(decal, TexCoord_0 - x2    ).xyz;
    float3 H5 = tex2D(decal, TexCoord_0 + y2    ).xyz;
    float3 F4 = tex2D(decal, TexCoord_0 + x2    ).xyz;


	float4 b = mul( float4x3(B, D, H, F), yuv_weighted[0] );
	float4 c = mul( float4x3(C, A, G, I), yuv_weighted[0] );
	float4 e = mul( float4x3(E, E, E, E), yuv_weighted[0] );
	float4 d = b.yzwx;
	float4 f = b.wxyz;
	float4 g = c.zwxy;
	float4 h = b.zwxy;
	float4 i = c.wxyz;

	float4 i4 = mul( float4x3(I4, C1, A0, G5), yuv_weighted[0] );
	float4 i5 = mul( float4x3(I5, C4, A1, G0), yuv_weighted[0] );
	float4 h5 = mul( float4x3(H5, F4, B1, D0), yuv_weighted[0] );
	float4 f4 = h5.yzwx;

	float4 Ao = float4( 1.0, -1.0, -1.0, 1.0 );
	float4 Bo = float4( 1.0,  1.0, -1.0,-1.0 );
	float4 Co = float4( 1.5,  0.5, -0.5, 0.5 );
	float4 Ax = float4( 1.0, -1.0, -1.0, 1.0 );
	float4 Bx = float4( 0.5,  2.0, -0.5,-2.0 );
	float4 Cx = float4( 1.0,  1.0, -0.5, 0.0 );
	float4 Ay = float4( 1.0, -1.0, -1.0, 1.0 );
	float4 By = float4( 2.0,  0.5, -2.0,-0.5 );
	float4 Cy = float4( 2.0,  0.0, -1.0, 0.5 );
	float4 Ci = float4(0.25, 0.25, 0.25, 0.25);
	
	// These inequations define the line below which interpolation occurs.
	fx      = (Ao*fp.y+Bo*fp.x); 
	fx_left = (Ax*fp.y+Bx*fp.x);
	fx_up   = (Ay*fp.y+By*fp.x);

        interp_restriction_lv1 = interp_restriction_lv0 = ((e!=f) && (e!=h));

#ifdef CORNER_B
	interp_restriction_lv1      = (interp_restriction_lv0  &&  ( !eq(f,b) && !eq(h,d) || eq(e,i) && !eq(f,i4) && !eq(h,i5) || eq(e,g) || eq(e,c) ) );
#endif
#ifdef CORNER_D
	float4 c1 = i4.yzwx;
	float4 g0 = i5.wxyz;
	interp_restriction_lv1      = (interp_restriction_lv0  &&  ( !eq(f,b) && !eq(h,d) || eq(e,i) && !eq(f,i4) && !eq(h,i5) || eq(e,g) || eq(e,c) ) && (f!=f4 && f!=i || h!=h5 && h!=i || h!=g || f!=c || eq(b,c1) && eq(d,g0)));
#endif
#ifdef CORNER_C
	interp_restriction_lv1      = (interp_restriction_lv0  && ( !eq(f,b) && !eq(f,c) || !eq(h,d) && !eq(h,g) || eq(e,i) && (!eq(f,f4) && !eq(f,i4) || !eq(h,h5) && !eq(h,i5)) || eq(e,g) || eq(e,c)) );
#endif

	interp_restriction_lv2_left = ((e!=g) && (d!=g));
	interp_restriction_lv2_up   = ((e!=c) && (b!=c));

	float4 fx45i = saturate((fx      + delta  -Co - Ci)/(2*delta ));
	float4 fx45  = saturate((fx      + delta  -Co     )/(2*delta ));
	float4 fx30  = saturate((fx_left + deltaL -Cx     )/(2*deltaL));
	float4 fx60  = saturate((fx_up   + deltaU -Cy     )/(2*deltaU));

	float4 w1, w2;

    w1 = weighted_distance( e, c,  g, i, h5, f4, h, f);
    w2 = weighted_distance( h, d, i5, f, i4,  b, e, i);

	edri     = (w1 <= w2) && interp_restriction_lv0;
	edr      = (w1 <  w2) && interp_restriction_lv1;
	
	w1.x = dot(abs(F-G),rgbw); w1.y = dot(abs(B-I),rgbw); w1.z = dot(abs(D-C),rgbw); w1.w = dot(abs(H-A),rgbw);
	w2.x = dot(abs(H-C),rgbw); w2.y = dot(abs(F-A),rgbw); w2.z = dot(abs(B-G),rgbw); w2.w = dot(abs(D-I),rgbw);
	
#ifdef CORNER_A
	edr      = edr && (!edri.yzwx || !edri.wxyz);
	edr_left = ((XBR_LV2_COEFFICIENT*w1) <= w2) && interp_restriction_lv2_left && edr && (!edri.yzwx && eq(e,c));
	edr_up   = (w1 >= (XBR_LV2_COEFFICIENT*w2)) && interp_restriction_lv2_up && edr && (!edri.wxyz && eq(e,g));
#endif
#ifndef CORNER_A
	edr_left = ((XBR_LV2_COEFFICIENT*w1) <= w2) && interp_restriction_lv2_left && edr;
	edr_up   = (w1 >= (XBR_LV2_COEFFICIENT*w2)) && interp_restriction_lv2_up && edr;
#endif
 
	fx45  = edr*fx45;
	fx30  = edr_left*fx30;
	fx60  = edr_up*fx60;
	fx45i = edri*fx45i;

	w1.x = dot(abs(E-F),rgbw); w1.y = dot(abs(E-B),rgbw); w1.z = dot(abs(E-D),rgbw); w1.w = dot(abs(E-H),rgbw);
	w2.x = dot(abs(E-H),rgbw); w2.y = dot(abs(E-F),rgbw); w2.z = dot(abs(E-B),rgbw); w2.w = dot(abs(E-D),rgbw);
	
	px = (w1 <= w2);

	float4 maximos = max(max(fx30, fx60), max(fx45, fx45i));

	float3 res1 = E;
	res1 = lerp(res1, lerp(H, F, px.x), maximos.x);
	res1 = lerp(res1, lerp(B, D, px.z), maximos.z);
	
	float3 res2 = E;
	res2 = lerp(res2, lerp(F, B, px.y), maximos.y);
	res2 = lerp(res2, lerp(D, H, px.w), maximos.w);
	
	float3 res = lerp(res1, res2, step(c_df(E, res1), c_df(E, res2)));

	return float4(res, 1.0);
}


//
// Technique
//

technique xBR
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

