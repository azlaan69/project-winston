shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float line_thickness : hint_range(0.5, 5.0) = 1.5;
uniform float color_threshold : hint_range(0.01, 1.0) = 0.08;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 ts = (1.0 / VIEWPORT_SIZE) * line_thickness;

	vec3 c = texture(screen_texture, uv).rgb;
	vec3 l = texture(screen_texture, uv + vec2(-ts.x, 0.0)).rgb;
	vec3 r = texture(screen_texture, uv + vec2( ts.x, 0.0)).rgb;
	vec3 u = texture(screen_texture, uv + vec2(0.0, -ts.y)).rgb;
	vec3 d = texture(screen_texture, uv + vec2(0.0,  ts.y)).rgb;

	// Calculate Euclidean distance in RGB color space across neighboring pixels
	float diff = distance(c, l) + distance(c, r) + distance(c, u) + distance(c, d);

	float is_edge = step(color_threshold, diff);

	vec4 scene = texture(screen_texture, uv);
	ALBEDO = mix(scene.rgb, line_color.rgb, is_edge);
	ALPHA = 1.0;
}