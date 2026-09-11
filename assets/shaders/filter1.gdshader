shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

uniform float threshold : hint_range(0.0, 1.0) = 0.5;

uniform float effect_strength : hint_range(0.0, 1.0) = 1.0; 

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    float normalized_length = length(screen_color.rgb) / 1.73205;
    
    vec3 bw_color;
    if (normalized_length > threshold) {
        bw_color = vec3(1.0);
    } else {
        bw_color = vec3(0.0);
    }
    
    COLOR.rgb = mix(screen_color.rgb, bw_color, effect_strength);
    COLOR.a = 1.0;
}
