shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 5.0) = 0.8; // Controlled by your GDScript speed

void fragment() {
    // Calculate distance from the center of the screen to create a vignette effect
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = SCREEN_UV;
    vec2 dist = uv - center;
    
    // Offset the color channels based on distance from center and speed amount
    vec4 color = vec4(0.0);
    color.r = texture(SCREEN_TEXTURE, uv - dist * amount * 0.02).r;
    color.g = texture(SCREEN_TEXTURE, uv).g;
    color.b = texture(SCREEN_TEXTURE, uv + dist * amount * 0.02).b;
    color.a = 1.0;
    
    COLOR = color;
}
