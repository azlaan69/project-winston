shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_always;

uniform vec4 enemy_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	ALBEDO = enemy_color.rgb;
	NORMAL = vec3(0.0, 0.0, 1.0); 
	ROUGHNESS = 0.0;
}
