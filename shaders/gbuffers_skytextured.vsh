#version 120
/*
Sildur's vibrant shaders v1.17, before editing, remember the agreement you've accepted by downloading this shaderpack:
http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/1291396-1-6-4-1-12-1-sildurs-shaders-pc-mac-intel

You are allowed to:
- Modify it for your own personal use only, so don't share it online.

You are not allowed to:
- Rename and/or modify this shaderpack and upload it with your own name on it.
- Provide mirrors by reuploading my shaderpack, if you want to link it, use the link to my thread found above.
- Copy and paste code or even whole files into your "own" shaderpack.
*/

varying vec4 color;
varying vec2 texcoord;

void main() {

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;
	
	gl_Position = ftransform();
}

