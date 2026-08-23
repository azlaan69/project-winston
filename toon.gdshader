shader_type spatial;
render_mode unshaded;

uniform vec4 color_a : source_color = vec4(0.0, 0.8, 1.0, 1.0); // Cyan
uniform vec4 color_b : source_color = vec4(1.0, 0.0, 0.4, 1.0); // Pink/Crimson
uniform float emission_energy : hint_range(1.0, 20.0) = 5.0;

void fragment() {
    // Splits color 50/50 along the ring's local UV layout
    float split = step(0.5, UV.x); 
    vec3 final_color = mix(color_a.rgb, color_b.rgb, split);
    
    ALBEDO = final_color;
    EMISSION = final_color * emission_energy;
}