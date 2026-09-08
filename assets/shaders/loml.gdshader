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
	vec2 ts = (1.0 / VIEWPORT_SIZE) * line_thickness;

	// --- 1. BASE GEOMETRY VALUES & SKYBOX CHECK ---
	float d_c = texture(depth_texture, uv).r;
	if (d_c >= 0.999) {
		discard;
	}

	vec4 n_raw_c = texture(normal_texture, uv);
	vec3 n_c = n_raw_c.rgb;
	float r_c = n_raw_c.a;

	// --- 2. CENTER PIXEL ENEMY DISCARD ---
	// In Godot 4 view-space packing, our enemy normal vec3(0.0,0.0,1.0) and roughness 0.0 
	// reads roughly as rgb=(0.5, 0.5, 1.0) and alpha=0.0. 
	// If the center pixel is an enemy, bail out instantly to prevent inner lines.
	if (distance(n_c, vec3(0.5, 0.5, 1.0)) < 0.05 && r_c < 0.05) {
		discard;
	}

	// --- 3. NEIGHBOR SAMPLES ---
	vec4 n_raw_l = texture(normal_texture, uv + vec2(-ts.x, 0.0));
	vec4 n_raw_r = texture(normal_texture, uv + vec2( ts.x, 0.0));
	vec4 n_raw_u = texture(normal_texture, uv + vec2(0.0, -ts.y));
	vec4 n_raw_d = texture(normal_texture, uv + vec2(0.0,  ts.y));

	float d_l = texture(depth_texture, uv + vec2(-ts.x, 0.0)).r;
	float d_r = texture(depth_texture, uv + vec2( ts.x, 0.0)).r;
	float d_u = texture(depth_texture, uv + vec2(0.0, -ts.y)).r;
	float d_d = texture(depth_texture, uv + vec2(0.0,  ts.y)).r;

	// --- 4. NEIGHBOR SUBSTITUTION FILTERING ---
	// If a neighbor is detected as an enemy, overwrite its values with the center pixel's values.
	// This makes the delta 0.0, hiding the enemy from the map's edge calculations.
	if (distance(n_raw_l.rgb, vec3(0.5, 0.5, 1.0)) < 0.05 && n_raw_l.a < 0.05) { n_raw_l.rgb = n_c; d_l = d_c; }
	if (distance(n_raw_r.rgb, vec3(0.5, 0.5, 1.0)) < 0.05 && n_raw_r.a < 0.05) { n_raw_r.rgb = n_c; d_r = d_c; }
	if (distance(n_raw_u.rgb, vec3(0.5, 0.5, 1.0)) < 0.05 && n_raw_u.a < 0.05) { n_raw_u.rgb = n_c; d_u = d_c; }
	if (distance(n_raw_d.rgb, vec3(0.5, 0.5, 1.0)) < 0.05 && n_raw_d.a < 0.05) { n_raw_d.rgb = n_c; d_d = d_c; }

	// --- 5. EDGE CALCULATIONS (CLEAN ENVIRONMENT ONLY) ---
	float n_diff = distance(n_c, n_raw_l.rgb) + distance(n_c, n_raw_r.rgb) + 
	               distance(n_c, n_raw_u.rgb) + distance(n_c, n_raw_d.rgb);

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
