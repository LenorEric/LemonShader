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

#define WeatherAngle			//Toggle alternative weather angle

varying vec4 color;

varying vec2 texcoord;
varying float lmcoord;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

void main() {

#ifdef WeatherAngle
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	float worldpos = position.y + cameraPosition.y;
	bool istopv = worldpos > cameraPosition.y+5.0;
	if (!istopv) position.xz += vec2(3.0,1.0);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
#else
	gl_Position = ftransform();
#endif
	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).s;
	color = gl_Color;

}
