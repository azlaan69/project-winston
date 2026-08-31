shader_type canvas_item;

uniform vec2 rect_size = vec2(300.0, 30.0);
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float border_thickness_px : hint_range(0.0, 20.0) = 2.0;

void fragment() {
	vec2 uv = UV;
	
	// Convert exact pixel thickness using the real node dimensions
	vec2 b = border_thickness_px / rect_size;

	// Equalized edge check on all 4 sides
	bool is_border = uv.x < b.x || uv.x > (1.0 - b.x) ||
	                 uv.y < b.y || uv.y > (1.0 - b.y);

	if (is_border) {
		COLOR = border_color;
	} else {
		COLOR = vec4(0.0);
	}
}