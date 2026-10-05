shader_type canvas_item;

// Local follow-through: the torso and foot anchor remain stationary.
uniform vec4 frame_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float gait_phase = 0.0;
uniform float motion_weight = 0.0;
uniform float cloth_tail_weight = 1.0;
uniform float idle_breath = 0.0;
uniform vec2 tail_center = vec2(0.22, 0.65);
uniform vec2 hair_center = vec2(0.48, 0.24);
uniform vec2 skirt_center = vec2(0.54, 0.71);
uniform vec2 head_proportion = vec2(1.0);
uniform vec2 head_pivot = vec2(0.5, 0.33);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

float region(vec2 p, vec2 center, vec2 radius) {
	vec2 q = (p - center) / radius;
	return exp(-dot(q, q) * 2.0);
}

void fragment() {
	vec2 p = (UV - frame_rect.xy) / frame_rect.zw;
	vec2 source = p;
	// Match authored idle head dimensions to locomotion without resizing the body.
	float head_mask = 1.0 - smoothstep(head_pivot.y - 0.035, head_pivot.y + 0.04, p.y);
	source = mix(source, head_pivot + (p-head_pivot)/head_proportion, head_mask);
	float tail = region(p, tail_center, vec2(0.24, 0.24));
	float hair = region(p, hair_center, vec2(0.27, 0.13));
	float ears = region(p, vec2(hair_center.x, 0.075), vec2(0.23, 0.09));
	float hem = region(p, skirt_center, vec2(0.24, 0.13));
	float cloak = region(p, vec2(hair_center.x, 0.43), vec2(0.27, 0.10));
	// Each flexible part trails the step by a different amount.
	source.x -= motion_weight * (cloth_tail_weight * 0.035 * sin(gait_phase - 1.2) * tail
		+ 0.018 * sin(gait_phase - 0.65) * hair
		+ 0.025 * sin(gait_phase * 2.0 - 0.25) * ears
		+ cloth_tail_weight * 0.023 * sin(gait_phase - 0.8) * hem
		+ cloth_tail_weight * 0.014 * sin(gait_phase - 0.9) * cloak);
	source.y -= cloth_tail_weight * motion_weight * 0.018 * cos(gait_phase - 1.2) * tail;
	// Small chest breathing, without scaling the character or moving its feet.
	source.y -= idle_breath * motion_weight * 0.012 * sin(gait_phase) * region(p, vec2(hair_center.x, 0.47), vec2(0.28, 0.20));
	source = mix(source, p, smoothstep(0.83, 0.95, p.y));
	vec2 sample_uv = frame_rect.xy + source * frame_rect.zw;
	vec2 edge = TEXTURE_PIXEL_SIZE * 0.5;
	sample_uv = clamp(sample_uv, frame_rect.xy + edge, frame_rect.xy + frame_rect.zw - edge);
	vec4 paint = texture(TEXTURE, sample_uv);
	COLOR = vertex_tint * paint;
}
