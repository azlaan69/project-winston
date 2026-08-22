shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Raise this slightly (e.g. 0.15 - 0.3) to ignore soft SSAO gradients!
uniform float edge_threshold : hint_range(0.01, 1.0) = 0.2;

// Anti-aliasing smoothness
uniform float line_smoothness : hint_range(0.01, 0.2) = 0.08;

// Width of the ink stroke
uniform float line_thickness : hint_range(0.5, 3.0) = 1.5;

uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 ts = SCREEN_PIXEL_SIZE * line_thickness;

	// 3x3 Neighborhood
	vec3 c00 = texture(screen_texture, uv + vec2(-ts.x, -ts.y)).rgb;
	vec3 c10 = texture(screen_texture, uv + vec2( 0.0,  -ts.y)).rgb;
	vec3 c20 = texture(screen_texture, uv + vec2( ts.x, -ts.y)).rgb;
	vec3 c01 = texture(screen_texture, uv + vec2(-ts.x,   0.0)).rgb;
	vec3 c21 = texture(screen_texture, uv + vec2( ts.x,   0.0)).rgb;
	vec3 c02 = texture(screen_texture, uv + vec2(-ts.x,  ts.y)).rgb;
	vec3 c12 = texture(screen_texture, uv + vec2( 0.0,   ts.y)).rgb;
	vec3 c22 = texture(screen_texture, uv + vec2( ts.x,  ts.y)).rgb;

	// Convert to luminance
	float l00 = dot(c00, vec3(0.299, 0.587, 0.114));
	float l10 = dot(c10, vec3(0.299, 0.587, 0.114));
	float l20 = dot(c20, vec3(0.299, 0.587, 0.114));
	float l01 = dot(c01, vec3(0.299, 0.587, 0.114));
	float l21 = dot(c21, vec3(0.299, 0.587, 0.114));
	float l02 = dot(c02, vec3(0.299, 0.587, 0.114));
	float l12 = dot(c12, vec3(0.299, 0.587, 0.114));
	float l22 = dot(c22, vec3(0.299, 0.587, 0.114));

	// Sobel Filter
	float gx = -l00 - 2.0 * l01 - l02 + l20 + 2.0 * l21 + l22;
	float gy = -l00 - 2.0 * l10 - l20 + l02 + 2.0 * l12 + l22;

	float edge = sqrt(gx * gx + gy * gy);

	// Suppress soft gradients (SSAO/lighting) before running edge detection
	edge = max(0.0, edge - (edge_threshold * 0.5));

	// Anti-aliased edge blending
	float is_edge = smoothstep(edge_threshold, edge_threshold + line_smoothness, edge);

	vec4 scene_color = texture(screen_texture, uv);
	COLOR = mix(scene_color, line_color, is_edge);
}