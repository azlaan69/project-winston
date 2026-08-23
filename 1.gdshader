shader_type canvas_item;

uniform float line_count : hint_range(1.0, 8.0) = 3.0; // Minimal lines
uniform float line_thickness : hint_range(0.001, 0.02) = 0.003; // Razor thin
uniform float mask_radius : hint_range(0.2, 0.8) = 0.5; // Pushed far into corners
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.4); // Transparent white
uniform float flicker_speed : hint_range(1.0, 60.0) = 2.0; // Calm flicker

float hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p.x + p.y) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV - vec2(0.5);
    uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x; // Keep 1:1 scale
    
    float dist = length(uv);
    vec2 dir = normalize(uv);
    
    // Stationary radial slotting (NO rotation math)
    float angle = atan(dir.y, dir.x);
    float slot = floor((angle + 3.14159) / (2.0 * 3.14159) * line_count);
    
    float ray_angle = (slot + 0.5) / line_count * 2.0 * 3.14159 - 3.14159;
    vec2 ray_dir = vec2(cos(ray_angle), sin(ray_angle));
    
    // Perpendicular distance to ray line
    float dist_to_ray = abs(dot(uv, vec2(-ray_dir.y, ray_dir.x)));
    
    // Taper toward pin-points near center
    float current_thickness = mix(0.0, line_thickness, smoothstep(mask_radius, 0.65, dist));
    float line_mask = step(dist_to_ray, current_thickness);
    
    // Strobe on/off at fixed angles
    float time_step = floor(TIME * flicker_speed);
    float rand = hash(vec2(slot, time_step));
    float active_ray = step(0.65, rand); // Only show occasional lines
    
    float center_mask = step(mask_radius, dist);
    
    float alpha = line_mask * active_ray * center_mask * line_color.a;
    COLOR = vec4(line_color.rgb, alpha);
}