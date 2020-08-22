#version 120
/* DRAWBUFFERS:7 */
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
#define Bloom
/*--------------------------------*/
varying vec2 texcoord;

uniform sampler2D composite;

uniform float viewWidth;
uniform float viewHeight;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
/*--------------------------------*/

const bool compositeMipmapEnabled = true;

void main() {

#ifdef Bloom
	const int nSteps = 25;
	const int center = 12;		//=nSteps-1 / 2

	vec3 blur = vec3(0.0);
	float tw = 0.0;
	for (int i = 0; i < nSteps; i++) {
		float dist = abs(i-float(center))/center;
		float weight = (exp(-(dist*dist)/ 0.28));

		vec3 bsample = texture2D(composite,(texcoord.xy*4.0 + 2.0*vec2(pw,ph)*vec2(i-center,0.0))).rgb;

		blur += bsample*weight;
		tw += weight;
	}
	blur /= tw;
	blur = clamp(blur,0.0,1.0); //fix flashing black square
	gl_FragData[0] = vec4(blur, 1.0); 
#else
	gl_FragData[0] = vec4(0.0);
#endif

}

