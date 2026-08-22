shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D normal_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform float line_thickness : hint_range(0.5, 3.0) = 1.5;
uniform float normal_threshold : hint_range(0.01, 2.0) = 0.4;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 ts = (1.0 / VIEWPORT_SIZE) * line_thickness;

	vec3 n_c = texture(normal_texture, uv).rgb;
	vec3 n_l = texture(normal_texture, uv + vec2(-ts.x, 0.0)).rgb;
	vec3 n_r = texture(normal_texture, uv + vec2( ts.x, 0.0)).rgb;
	vec3 n_u = texture(normal_texture, uv + vec2(0.0, -ts.y)).rgb;
	vec3 n_d = texture(normal_texture, uv + vec2(0.0,  ts.y)).rgb;

	float diff = distance(n_c, n_l) + distance(n_c, n_r) + distance(n_c, n_u) + distance(n_c, n_d);

	float is_edge = step(normal_threshold, diff);

	vec4 scene = texture(screen_texture, uv);
	ALBEDO = mix(scene.rgb, line_color.rgb, is_edge);
	ALPHA = 1.0;
}