shader_type spatial;
render_mode depth_draw_always, cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.5, 10.0) = 2.0; // Screen-space pixel thickness

void vertex() {

	vec4 clip_position = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 clip_normal = mat3(PROJECTION_MATRIX * MODELVIEW_MATRIX) * NORMAL;

	vec2 offset = normalize(clip_normal.xy) * outline_thickness * 0.002 * clip_position.w;
	
	clip_position.xy += offset;
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
	//DEPTH = 0.9999;
}