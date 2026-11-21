shader_type canvas_item;
// Whole background in ONE full-screen pass: warm paper, slowly drifting and
// breathing pastel glows (top haze + bottom glow), minor + major graph-paper
// grid, and a subtle animated paper grain.
// Colours are pushed in from ThemePalette by Paper.gd.

uniform vec2 origin = vec2(0.0);          // world position of the rect's top-left
uniform vec2 rect_size = vec2(1080.0, 2400.0);

uniform vec4 paper : source_color;
uniform vec4 minor_color : source_color;  // alpha = line strength
uniform vec4 major_color : source_color;
uniform float minor_step = 60.0;
uniform float major_step = 240.0;

// Glows: rgb + alpha strength, geo = x, y, radius (world px)
uniform vec4 blob_a : source_color;
uniform vec3 blob_a_geo = vec3(200.0, 100.0, 760.0);
uniform vec4 blob_b : source_color;
uniform vec3 blob_b_geo = vec3(900.0, 40.0, 700.0);
uniform vec4 blob_c : source_color;
uniform vec3 blob_c_geo = vec3(980.0, 1500.0, 650.0);
uniform vec4 blob_d : source_color;       // bottom glow left
uniform vec3 blob_d_geo = vec3(160.0, 2300.0, 820.0);
uniform vec4 blob_e : source_color;       // bottom glow right
uniform vec3 blob_e_geo = vec3(900.0, 2400.0, 780.0);

uniform float drift = 120.0;              // how far glows wander (px)
uniform float drift_speed = 0.1;
uniform float bottom_drift = 1.8;         // bottom glows move further

uniform float grain = 0.035;
uniform float grain_fps = 8.0;

float grid_line(vec2 p, float step_px, float width_px) {
	vec2 g = abs(fract(p / step_px - 0.5) - 0.5) * step_px;  // px to nearest line
	float d = min(g.x, g.y);
	return 1.0 - smoothstep(width_px * 0.5, width_px * 0.5 + 1.0, d);
}

vec2 wander(float seed, float amount) {
	float t = TIME * drift_speed;
	return vec2(sin(t * 1.3 + seed * 2.1) + 0.5 * sin(t * 2.7 + seed),
				cos(t * 0.9 + seed * 3.7)) * drift * amount;
}

float glow(vec2 p, vec3 geo, float seed, float amount) {
	vec2 c = geo.xy + wander(seed, amount);
	float t = 1.0 - clamp(distance(p, c) / geo.z, 0.0, 1.0);
	float breathe = 0.8 + 0.2 * sin(TIME * 0.35 + seed * 5.0);
	return t * t * (3.0 - 2.0 * t) * breathe;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 p = origin + UV * rect_size;
	vec3 col = paper.rgb;

	col = mix(col, blob_a.rgb, blob_a.a * glow(p, blob_a_geo, 1.0, 1.0));
	col = mix(col, blob_b.rgb, blob_b.a * glow(p, blob_b_geo, 2.0, 1.0));
	col = mix(col, blob_c.rgb, blob_c.a * glow(p, blob_c_geo, 3.0, 1.0));
	col = mix(col, blob_d.rgb, blob_d.a * glow(p, blob_d_geo, 4.0, bottom_drift));
	col = mix(col, blob_e.rgb, blob_e.a * glow(p, blob_e_geo, 5.0, bottom_drift));

	col = mix(col, minor_color.rgb, minor_color.a * grid_line(p, minor_step, 1.5));
	col = mix(col, major_color.rgb, major_color.a * grid_line(p, major_step, 2.5));

	float frame = floor(TIME * grain_fps);
	col += (hash(floor(p) + frame * 17.0) - 0.5) * grain;

	COLOR = vec4(col, 1.0);
}
