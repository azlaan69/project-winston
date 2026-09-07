shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform sampler2D normal_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform float line_thickness : hint_range(0.5, 5.0) = 2.0;
uniform float normal_threshold : hint_range(0.01, 2.0) = 0.35;
uniform float depth_threshold : hint_range(0.0001, 0.05) = 0.002;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	vec3 n_c = texture(normal_texture, uv).rgb;

	vec2 ts = (1.0 / VIEWPORT_SIZE) * line_thickness;

	// --- 1. NORMAL EDGE DETECTION ---
	vec3 n_l = texture(normal_texture, uv + vec2(-ts.x, 0.0)).rgb;
	vec3 n_r = texture(normal_texture, uv + vec2( ts.x, 0.0)).rgb;
	vec3 n_u = texture(normal_texture, uv + vec2(0.0, -ts.y)).rgb;
	vec3 n_d = texture(normal_texture, uv + vec2(0.0,  ts.y)).rgb;

	float n_diff = distance(n_c, n_l) + distance(n_c, n_r) + distance(n_c, n_u) + distance(n_c, n_d);

	// --- 2. DEPTH EDGE DETECTION ---
	float d_c = texture(depth_texture, uv).r;

	// Skybox discard
	if (d_c >= 0.999) {
		discard;
	}

	float d_l = texture(depth_texture, uv + vec2(-ts.x, 0.0)).r;
	float d_r = texture(depth_texture, uv + vec2( ts.x, 0.0)).r;
	float d_u = texture(depth_texture, uv + vec2(0.0, -ts.y)).r;
	float d_d = texture(depth_texture, uv + vec2(0.0,  ts.y)).r;

	float d_diff = abs(d_c - d_l) + abs(d_c - d_r) + abs(d_c - d_u) + abs(d_c - d_d);
	float dynamic_depth_thresh = depth_threshold * (1.0 - d_c);

	float is_normal_edge = step(normal_threshold, n_diff);
	float is_depth_edge = step(dynamic_depth_thresh, d_diff);

	if (max(is_normal_edge, is_depth_edge) > 0.5) {
		ALBEDO = line_color.rgb;
		ALPHA = line_color.a;
	} else {
		discard;
	}
}