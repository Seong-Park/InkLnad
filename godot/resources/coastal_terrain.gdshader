shader_type canvas_item;
render_mode world_vertex_coords;
uniform sampler2D terrain_weights : filter_linear, repeat_disable;
uniform sampler2D sand_art : source_color, filter_linear, repeat_enable;
uniform sampler2D grass_art : source_color, filter_linear, repeat_enable;
uniform sampler2D water_art : source_color, filter_linear, repeat_enable;
uniform sampler2D dirt_art : source_color, filter_linear, repeat_enable;
uniform sampler2D paving_art : source_color, filter_linear, repeat_enable;
uniform vec2 world_size;
uniform float world_scale = 1.0;
uniform vec4 environment_tint : source_color = vec4(1.0);
uniform vec2 terrain_origin;
uniform vec2 plaza_center;
varying vec2 world_point;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
vec2 mirrored(vec2 p) { return 1.0-abs(mod(p,2.0)-1.0); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() { world_point=VERTEX.xy-terrain_origin; }
void fragment() {
	vec3 weights=texture(terrain_weights,world_point/world_size).rgb;
	float broad=noise(world_point/113.0), fine=noise(world_point/27.0);
	vec2 grain_uv=world_point/512.0;
	vec3 sand=mix(vec3(0.947,0.917,0.806),texture(sand_art,mirrored(grain_uv)).rgb,0.18);
	vec3 dry_earth=mix(vec3(0.99,0.948,0.834),texture(dirt_art,mirrored(world_point/450.0)).rgb,0.12);
	float grass_weight=smoothstep(0.35,0.65,weights.r+(broad-0.5)*0.18+(fine-0.5)*0.06);
	vec3 sparse_grass=mix(vec3(0.773,0.803,0.619),texture(grass_art,mirrored(grain_uv)).rgb,0.40);
	vec3 meadow=mix(vec3(0.625,0.701,0.475),texture(grass_art,mirrored(grain_uv)).rgb,0.40);
	vec3 grass=mix(sparse_grass,meadow,smoothstep(0.50,0.95,weights.r))*mix(0.97,1.03,broad);
	float road=weights.b*(0.7+fine*0.3);
	vec3 ground=mix(sand,dry_earth,road*0.75);
	ground=mix(ground,grass,grass_weight*(1.0-road*0.85));
	if (plaza_center.x>0.0) {
		float paving=1.0-smoothstep(0.62,1.07,length((world_point-plaza_center)/(vec2(285.0,185.0)*world_scale))+(broad-0.5)*0.18);
		vec3 stone=mix(vec3(0.902,0.884,0.789),texture(paving_art,mirrored(world_point/400.0)).rgb,0.55);
		ground=mix(ground,stone,paving*0.85);
	}
	float wet=smoothstep(0.19,0.49,weights.g);
	ground=mix(ground,mix(vec3(0.76,0.773,0.616),sand,0.4),wet*0.65);
	float deep=smoothstep(0.51,0.95,weights.g);
	vec3 sea=mix(vec3(0.586,0.765,0.703),vec3(0.359,0.648,0.648),deep);
	sea=mix(sea,texture(water_art,mirrored(world_point/640.0+vec2(TIME*0.0008,0.0))).rgb,0.24);
	float ripple=sin(world_point.x*0.025+sin(world_point.y*0.03)+TIME*0.5)*sin(world_point.y*0.017-TIME*0.3);
	sea+=vec3(ripple*0.007);
	float water=smoothstep(0.46,0.54,weights.g);
	COLOR=vec4(mix(ground,sea,water)*environment_tint.rgb,1.0);
}
