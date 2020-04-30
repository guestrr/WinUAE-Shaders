//
// PUBLIC DOMAIN CRT STYLED SCAN-LINE SHADER
//
//   by Timothy Lottes
//
// This is more along the style of a really good CGA arcade monitor.
// With RGB inputs instead of NTSC.
// The shadow mask example has the mask rotated 90 degrees for less chromatic aberration.
//
// Left it unoptimized to show the theory behind the algorithm.
//
// It is an example what I personally would want as a display option for pixel art games.
// Please take and use, change, or whatever.
//


#define hardScan -8.0
#define hardPix -3.0
#define warpX 0.031
#define warpY 0.041
#define maskDark 0.5
#define maskLight 1.5
#define scaleInLinearGamma 1
#define brightboost 1.4
#define hardBloomScan -2.0
#define hardBloomPix -1.5
#define bloomAmount 1.0/16.0
#define shape 2.0 
 
#define warp float2(warpX,warpY)
 
// The name of this effect
string name : NAME = "CrtLottes";

float2 ps1                      : TEXELSIZE;
float2 ir                       : sourcescale;

static float2 ps = ps1*ir;

float4x4 World                  : WORLD;
float4x4 View                   : VIEW;
float4x4 Projection             : PROJECTION;
float4x4 Worldview              : WORLDVIEW;               // world * view
float4x4 ViewProjection         : VIEWPROJECTION;          // view * projection
float4x4 WorldViewProjection    : WORLDVIEWPROJECTION;     // world * view * projection

string combineTechique          : COMBINETECHNIQUE = "CrtLottes";

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
	float2 t1       : TEXCOORD1;
}; 
 

out_vertex  VS_VERTEX(float3 position : POSITION, float2 texCoord : TEXCOORD0 )
{ 
	out_vertex OUT = (out_vertex)0;

	OUT.position = mul(float4(position,1.0),WorldViewProjection);
	OUT.t0 = texCoord;
	OUT.t1 = float2((position.x + 0.5) * World._11, (position.y - 0.5) * (-World._22));

	return OUT;  
}




float ToLinear1(float c)
{
   if (scaleInLinearGamma==0) return c;
   return(c<=0.04045)?c/12.92:pow((c+0.055)/1.055,2.4);
}
float3 ToLinear(float3 c)
{
   if (scaleInLinearGamma==0) return c;
   return float3(ToLinear1(c.r),ToLinear1(c.g),ToLinear1(c.b));
}

// Linear to sRGB.
// Assuming using sRGB typed textures this should not be needed.
float ToSrgb1(float c)
{
   if (scaleInLinearGamma==0) return c;
   return(c<0.0031308?c*12.92:1.055*pow(c,0.41666)-0.055);
}

float3 ToSrgb(float3 c)
{
   if (scaleInLinearGamma==0) return c;
   return float3(ToSrgb1(c.r),ToSrgb1(c.g),ToSrgb1(c.b));
} 


// Nearest emulated sample given floating point position and texel offset.
// Also zero's off screen.
float3 Fetch(float2 pos,float2 off){
  float2 texsize = 1.0/ps;	
  pos=(floor(pos*texsize+off)+float2(0.5,0.5))/texsize;
  return (brightboost * ToLinear(tex2D(decal, pos).rgb));
}

// Distance in emulated pixels to nearest texel.
float2 Dist(float2 pos){pos=pos/ps;return -((pos-floor(pos))-float2(0.5,0.5));}
    
// 1D Gaussian.
float Gaus(float pos,float scale){return exp2(scale*pow(abs(pos),shape));}

// 3-tap Gaussian filter along horz line.
float3 Horz3(float2 pos,float off){
  float3 b=Fetch(pos,float2(-1.0,off));
  float3 c=Fetch(pos,float2( 0.0,off));
  float3 d=Fetch(pos,float2( 1.0,off));
  float dst=Dist(pos).x;
  // Convert distance to weight.
  float scale=hardPix;
  float wb=Gaus(dst-1.0,scale);
  float wc=Gaus(dst+0.0,scale);
  float wd=Gaus(dst+1.0,scale);
  // Return filtered sample.
  return (b*wb+c*wc+d*wd)/(wb+wc+wd);}
  
// 5-tap Gaussian filter along horz line.
float3 Horz5(float2 pos,float off){
  float3 a=Fetch(pos,float2(-2.0,off));
  float3 b=Fetch(pos,float2(-1.0,off));
  float3 c=Fetch(pos,float2( 0.0,off));
  float3 d=Fetch(pos,float2( 1.0,off));
  float3 e=Fetch(pos,float2( 2.0,off));
  float dst=Dist(pos).x;
  // Convert distance to weight.
  float scale=hardPix;
  float wa=Gaus(dst-2.0,scale);
  float wb=Gaus(dst-1.0,scale);
  float wc=Gaus(dst+0.0,scale);
  float wd=Gaus(dst+1.0,scale);
  float we=Gaus(dst+2.0,scale);
  // Return filtered sample.
  return (a*wa+b*wb+c*wc+d*wd+e*we)/(wa+wb+wc+wd+we);}

// 7-tap Gaussian filter along horz line.
float3 Horz7(float2 pos,float off){
  float3 a=Fetch(pos,float2(-3.0,off));
  float3 b=Fetch(pos,float2(-2.0,off));
  float3 c=Fetch(pos,float2(-1.0,off));
  float3 d=Fetch(pos,float2( 0.0,off));
  float3 e=Fetch(pos,float2( 1.0,off));
  float3 f=Fetch(pos,float2( 2.0,off));
  float3 g=Fetch(pos,float2( 3.0,off));
  float dst=Dist(pos).x;
  // Convert distance to weight.
  float scale=hardBloomPix;
  float wa=Gaus(dst-3.0,scale);
  float wb=Gaus(dst-2.0,scale);
  float wc=Gaus(dst-1.0,scale);
  float wd=Gaus(dst+0.0,scale);
  float we=Gaus(dst+1.0,scale);
  float wf=Gaus(dst+2.0,scale);
  float wg=Gaus(dst+3.0,scale);
  // Return filtered sample.
  return (a*wa+b*wb+c*wc+d*wd+e*we+f*wf+g*wg)/(wa+wb+wc+wd+we+wf+wg);}

// Return scanline weight.
float Scan(float2 pos,float off){
  float dst=Dist(pos).y;
  return Gaus(dst+off,hardScan);}
  
  // Return scanline weight for bloom.
float BloomScan(float2 pos,float off){
  float dst=Dist(pos).y;
  return Gaus(dst+off,hardBloomScan);}

// Allow nearest three lines to effect pixel.
float3 Tri(float2 pos){
  float3 a=Horz3(pos,-1.0);
  float3 b=Horz5(pos, 0.0);
  float3 c=Horz3(pos, 1.0);
  float wa=Scan(pos,-1.0);
  float wb=Scan(pos, 0.0);
  float wc=Scan(pos, 1.0);
  return a*wa+b*wb+c*wc;}
  
// Small bloom.
float3 Bloom(float2 pos){
  float3 a=Horz5(pos,-2.0);
  float3 b=Horz7(pos,-1.0);
  float3 c=Horz7(pos, 0.0);
  float3 d=Horz7(pos, 1.0);
  float3 e=Horz5(pos, 2.0);
  float wa=BloomScan(pos,-2.0);
  float wb=BloomScan(pos,-1.0);
  float wc=BloomScan(pos, 0.0);
  float wd=BloomScan(pos, 1.0);
  float we=BloomScan(pos, 2.0);
  return a*wa+b*wb+c*wc+d*wd+e*we;}

// Distortion of scanlines, and end of screen alpha. (CRT-Lottes curvature)
float2 Warp(float2 pos)
{
   pos=pos*2.0-1.0;    
   pos*=float2(1.0+(pos.y*pos.y)*warpX,1.0+(pos.x*pos.x)*warpY);
   return pos*0.5+0.5;
}


float4 PS_FRAGMENT (in out_vertex VAR) : COLOR
{	
	//float2 pos = Warp(VAR.t0);
	float2 pos = VAR.t0;
	float3 outColor = Tri(pos);
	return float4(ToSrgb(outColor), 1.0);
}


//
// Technique
//

technique CrtLottes
{
    pass P0
    {
        // shaders		
        VertexShader = compile vs_3_0 VS_VERTEX();
        PixelShader  = compile ps_3_0 PS_FRAGMENT(); 
    }  
}

