#version 120
/* DRAWBUFFERS:56 */
//Render hand, entities and particles in here, boost and fix enchanted armor effect in gbuffers_armor_glint
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
#define MobsFlashRed

#define Shadows
#define SHADOW_MAP_BIAS 0.8

varying vec4 color;
varying vec2 texcoord;
varying vec3 normal;
varying vec3 ambientNdotL;
varying vec3 finalSunlight;
varying float skyL;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform sampler2DShadow shadow;

uniform float viewWidth;
uniform float viewHeight;
uniform vec4 entityColor;
uniform float rainStrength;

uniform vec3 shadowLightPosition;
uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;

void main() {

	float diffuse = clamp(dot(normalize(shadowLightPosition),normal),0.0,1.0);
	
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
#ifdef MobsFlashRed
	albedo.rgb = mix(albedo.rgb,entityColor.rgb,entityColor.a);
#endif

#ifdef Shadows
//don't do shading if transparent/translucent (not opaque)
if (diffuse > 0.0 && rainStrength < 0.9 && albedo.a > 0.01){
vec4 fragposition = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0)*2.0-1.0);
	
vec4 worldposition = gbufferModelViewInverse * fragposition;
	 worldposition = shadowModelView * worldposition;
	 worldposition = shadowProjection * worldposition;
	 worldposition /= worldposition.w;
	
	float distortion = ((1.0 - SHADOW_MAP_BIAS) + length(worldposition.xy * 1.165) * SHADOW_MAP_BIAS) * 0.97;
	worldposition.xy /= distortion;
	
	float bias = distortion*distortion*(0.0015*tan(acos(diffuse)));
	worldposition.xyz = worldposition.xyz * vec3(0.5,0.5,0.2) + vec3(0.5,0.5,0.5-bias);

	//Fast and simple shadow drawing for proper rendering of entities etc
	diffuse *= shadow2D(shadow, worldposition.xyz).x;
	diffuse *= (1.0 - rainStrength);
	diffuse *= mix(skyL,1.0,clamp((eyeBrightnessSmooth.y/255.0-2.0/16.)*4.0,0.0,1.0)); //avoid light leaking underground	
}
#endif

	vec3 finalColor = pow(albedo.rgb,vec3(2.2)) * (finalSunlight*diffuse+ambientNdotL.rgb);

	gl_FragData[0] = vec4(finalColor, albedo.a);
	gl_FragData[1] = vec4(normalize(albedo.rgb+0.00001), albedo.a);		
}