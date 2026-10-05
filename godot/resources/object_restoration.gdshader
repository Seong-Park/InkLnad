shader_type canvas_item;
uniform float restored : hint_range(0.0,1.0) = 0.0;
uniform bool purple_flowers = false;
uniform vec4 source_region = vec4(0.0,0.0,1.0,1.0);
void fragment() {
	vec4 art = texture(TEXTURE, UV);
	float gray = dot(art.rgb, vec3(0.299,0.587,0.114));
	vec3 faded = mix(vec3(0.91,0.88,0.79),vec3(gray),0.55);
	vec2 local_uv = (UV-source_region.xy)/source_region.zw;
	float grain = sin(local_uv.x*113.0)*sin(local_uv.y*97.0)*0.025;
	float wash = smoothstep(local_uv.y-0.15+grain,local_uv.y+0.15+grain,restored*1.3);
	if (restored <= 0.0) { wash = 0.0; }
	vec3 colored = art.rgb;
	if (purple_flowers) {
		float petals = smoothstep(0.04,0.12,art.r-art.g)*(1.0-smoothstep(0.52,0.65,local_uv.y))*smoothstep(0.20,0.42,gray);
		colored = mix(colored,vec3(0.57,0.34,0.76)*(0.65+gray*0.65),petals);
	}
	COLOR = vec4(mix(faded,colored,wash),art.a);
}
