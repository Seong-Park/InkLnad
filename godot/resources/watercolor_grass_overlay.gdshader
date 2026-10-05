shader_type canvas_item;

// The grass sheet's cream underpainting yields to the shared sand beneath it.
// Keep the original bitmap intact and retain dark grass contour strokes.
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float grass = (1.0-smoothstep(0.025,0.075,ink.r-ink.g))
		*(1.0-smoothstep(0.78,0.94,ink.r));
	COLOR = vec4(ink.rgb,ink.a*grass);
}
