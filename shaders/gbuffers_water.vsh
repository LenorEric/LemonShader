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
#define Shadows
#define SHADOW_MAP_BIAS 0.80
varying vec4 color;
varying vec4 ambientNdotL;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 getSunlight;

varying vec3 viewVector;
varying vec3 worldpos;
varying vec3 getShadowPos;
varying float diffuse;
varying mat3 tbnMatrix;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;                      //xyz = tangent vector, w = handedness, added in 1.7.10

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float rainStrength;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform vec3 shadowLightPosition;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.16,0.005),
								vec3(0.58597,0.31,0.05),
								vec3(0.58597,0.45,0.16),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));

float SunIntensity(float zenithAngleCos, float sunIntensity, float cutoffAngle, float steepness){
	return sunIntensity * max(0.0, 1.0 - exp(-((cutoffAngle - acos(zenithAngleCos))/steepness)));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

void main() {

	//pos
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal).xyz;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	worldpos = position.xyz + cameraPosition;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	color = gl_Color;
	
	texcoord = (gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

#ifdef Shadows
	vec4 shadowpos = position;
		 shadowpos = shadowModelView * shadowpos;
		 shadowpos = shadowProjection * shadowpos;
	
	float distortion = ((1.0 - SHADOW_MAP_BIAS) + length(shadowpos.xy * 1.165) * SHADOW_MAP_BIAS) * 0.97;
	shadowpos.xy /= distortion;
	
	diffuse = clamp(dot(normal, normalize(shadowLightPosition)),0.0,1.0);	
	float bias = distortion*distortion*(0.0015*tan(acos(diffuse)));
	shadowpos.xyz = shadowpos.xyz * vec3(0.5,0.5,0.2) + vec3(0.5,0.5,0.5-bias);

	getShadowPos = shadowpos.xyz;
#endif
	
	//Transparency stuff
	ambientNdotL.a = 0.0;
	float iswater = 1.0; //disable lightmap on water, make light go through instead
	if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
		ambientNdotL.a = 1.0;
		iswater = 0.0;
	}
	if(mc_Entity.x == 79.0) ambientNdotL.a = 0.5;
	//---
	
	//ToD
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 sunlight = mix(ToD[int(cmpH)], ToD[int(cmpH1)], fract(hour));
	//---

	//lightmap
	float torch_lightmap = 16.0-min(15.0,(lmcoord.s-0.5/16.0)*16.0*16.0/15.0);
	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	torch_lightmap *= iswater;
	//---

	//light bounce
	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);

	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));
	
	float cutoffAngle = 1.608;
	float steepness = 1.5;
	float cosSunUpAngle = dot(sunVec, upVec) * 0.95 + 0.05; //Has a lower offset making it scatter when sun is below the horizon.
	float sunE = SunIntensity(cosSunUpAngle, 1000.0, cutoffAngle, steepness);  // Get sun intensity based on how high in the sky it is

	float NdotL = dot(normal,sunVec);
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	visibility = pow(clamp(visibility+0.15,0.0,0.3)/0.3,vec2(4.4));
	sunlight = sunlight/luma(sunlight)*sunE*0.0075*0.075*3.*visibility.x;
	
	float skyL = max(lmcoord.t-2./16.0,0.0)*1.14285714286;	
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);

	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.14*skyL*skyL,0.33,0.7,0.1) + vec4(0.6,0.66,0.7,0.25);
		 bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);
	
	vec3 ambientC = mix(vec3(0.3, 0.5, 1.1),vec3(0.08,0.1,0.1),rainStrength)*length(sunlight)*bounced.w;
		 ambientC += 0.25*sunlight*(bounced.x + bounced.z)*(0.03+tr*0.17)/0.4*(1.0-rainStrength*0.98)  + length(sunlight)*0.2*(1.0-rainStrength*0.9);
		 ambientC += sunlight*(NdotL*0.5+0.45)*visibility.x*(1.0-tr)*(1.0-tr)*4.*(1.0-rainStrength*0.98);

	//lighting during night time
	const vec3 moonlight = vec3(0.0024, 0.00432, 0.0078);	
	vec3 moon_ambient = (moonlight*2.0 + moonlight*bounced.y)*(4.0-rainStrength*0.95)*0.2;
	vec3 moonC = (moon_ambient*visibility.y)*SkyL2*(0.03*0.65+tr*0.17*0.65);

	ambientNdotL.rgb = ambientC*SkyL2*0.3 + moonC + vec3(1.1,0.42,0.045)*torch_lightmap*0.2 + 0.00008;
		
	sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y)*tr;

	getSunlight = sunlight;
	//---


	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
					 tangent.y, binormal.y, normal.y,
					 tangent.z, binormal.z, normal.z);

	float dist = length(gl_ModelViewMatrix * gl_Vertex);
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector.xy = viewVector.xy / dist * 8.25;
}