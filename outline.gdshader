shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec2 size = SCREEN_PIXEL_SIZE * width;
	vec4 col = texture(TEXTURE, UV);
	
	// Sample surrounding alpha values
	float a_up    = texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	float a_down  = texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	float a_left  = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	float a_right = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	
	float max_neighbor_alpha = max(max(a_up, a_down), max(a_left, a_right));
	
	// Smooth transition for anti-aliased edges
	if (col.a < 0.9 && max_neighbor_alpha > 0.05) {
		COLOR = vec4(outline_color.rgb, max_neighbor_alpha);
	} else {
		COLOR = col;
	}
}