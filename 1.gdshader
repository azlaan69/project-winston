shader_type spatial;
render_mode depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 16.0) = 0.0;

// Pulls the weapon toward the camera (0.2 - 0.5 works best)
uniform float view_model_fov : hint_range(0.1, 1.0) = 0.3;

void vertex() {
	// Scale projection matrix Z coordinates directly
	// Moves the weapon closer to camera without breaking vertex depth sorting
	PROJECTION_MATRIX[2][2] *= view_model_fov;
}

void fragment() {
	vec4 tex_color = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * tex_color.rgb;
	EMISSION = emission_color.rgb * emission_energy;
}