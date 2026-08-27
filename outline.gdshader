shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width : hint_range(0.0, 20.0) = 12.0;
uniform int pattern_quality : hint_range(4, 16) = 16;

void fragment() {
	vec2 size = SCREEN_PIXEL_SIZE * width;
	vec4 col = texture(TEXTURE, UV);
	
	if (col.a > 0.95) {
		COLOR = col;
	} else {
		float max_alpha = 0.0;
		
		for (int i = 0; i < pattern_quality; i++) {
			float angle = float(i) * (6.28318530718 / float(pattern_quality));
			vec2 offset = vec2(cos(angle), sin(angle)) * size;
			float sampled_alpha = texture(TEXTURE, UV + offset).a;
			max_alpha = max(max_alpha, sampled_alpha);
		}
		
		if (max_alpha > 0.05) {
			COLOR = vec4(outline_color.rgb, max_alpha * outline_color.a);
		} else {
			COLOR = col;
		}
	}
}