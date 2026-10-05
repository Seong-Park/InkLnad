shader_type canvas_item;
uniform sampler2D cliff_atlas : source_color, filter_linear, repeat_disable;
void fragment() {
	vec2 uv = vec2((1.0+fract(UV.x))/3.0,0.78+UV.y*0.16);
	vec4 pigment = texture(cliff_atlas,uv);
	float alpha = smoothstep(0.0,0.09,UV.y)*(1.0-smoothstep(0.89,1.0,UV.y));
	COLOR = vec4(pigment.rgb,pigment.a*alpha);
}
