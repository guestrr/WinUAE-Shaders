# WinUAE-Shaders

These shaders can utilize the SmartRes functionality with WinUAE versions 4.2.0 or above. Otherwise they work with Lores and single-line mode.
Hires shaders can operate with hires resolutions and don't skip horizontal hires pixels. Interlace shaders are intended for interrlaced gfx. and situations, lines aren't discarded.

This repository comes with a couple of ReShade shaders. One is for colorspace tweaks and profiles, other is for glow, bloom and mask effects.

If you use ReShade for example for 64 bit version of WinUAE then it's not triggered by a 32 bit version. 

WinUAE shaders are to be copied into the \plugins\filtershaders\direct3d folder.
ReShade shaders persumably into the \reshade-shaders\Shaders folder.
