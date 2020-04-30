/*
   Hyllian's 5xBR v3.5b Shader
   
   Copyright (C) 2011 Hyllian/Jararaca - sergiogdb@gmail.com

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


const static float4 Ao = float4( 1.0, -1.0, -1.0, 1.0 );
const static float4 Bo = float4( 1.0,  1.0, -1.0,-1.0 );
const static float4 Co = float4( 1.5,  0.5, -0.5, 0.5 );
const static float4 Ax = float4( 1.0, -1.0, -1.0, 1.0 );
const static float4 Bx = float4( 0.5,  2.0, -0.5,-2.0 );
const static float4 Cx = float4( 1.0,  1.0, -0.5, 0.0 );
const static float4 Ay = float4( 1.0, -1.0, -1.0, 1.0 );
const static float4 By = float4( 2.0,  0.5, -2.0,-0.5 );
const static float4 Cy = float4( 2.0,  0.0, -1.0, 0.5 );



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

float3 xBRF (float2 texcoord)
{	
	bool4 edr, edr_left, edr_up, px; // px = pixel, edr = edge detection rule
	bool4 interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
	bool4 nc; // new_color
	bool4 fx, fx_left, fx_up; // inequations of straight lines.
	
	float2 tmp = (ir.x < 1.0) ? float2(1.0,1.0) : ir;
	float2 ps = ps1*tmp;
	
	float2 fp = frac(texcoord/ps);	
    float2 TexCoord_0 = (floor(texcoord/ps) + float2(0.5,0.5))*ps;

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

	// These inequations define the line below which interpolation occurs.
	fx      = (Ao*fp.y+Bo*fp.x > Co); 
	fx_left = (Ax*fp.y+Bx*fp.x > Cx);
	fx_up   = (Ay*fp.y+By*fp.x > Cy);

	interp_restriction_lv1      = ((e!=f) && (e!=h) && ( f!=b && h!=d || e==i && f!=i4 && h!=i5 || e==g || e==c ));
	interp_restriction_lv2_left = ((e!=g) && (d!=g));
	interp_restriction_lv2_up   = ((e!=c) && (b!=c));

	edr      = (weighted_distance( e, c, g, i, h5, f4, h, f) < weighted_distance( h, d, i5, f, i4, b, e, i)) && interp_restriction_lv1;
	edr_left = ((coef*df(f,g)) <= df(h,c)) && interp_restriction_lv2_left;
	edr_up   = (df(f,g) >= (coef*df(h,c))) && interp_restriction_lv2_up;

	nc = ( edr && (fx || edr_left && fx_left || edr_up && fx_up) );

	px = (df(e,f) <= df(e,h));

	float3 res = nc.x ? px.x ? F : H : nc.y ? px.y ? B : F : nc.z ? px.z ? D : B : nc.w ? px.w ? H : D : E;

	return res;
}


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
    float2 TexCoord_0 = VAR.t0;
    float3 E  = xBRF(TexCoord_0      ).xyz;	
	return float4(E, 1.0);
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

