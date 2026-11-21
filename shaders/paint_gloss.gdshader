shader_type canvas_item;
render_mode blend_premul_alpha;
// Turns the flat paint canvas into raised, glossy "puffy paint".
// Paint alpha is treated as a height map: its slope gives a surface normal,
// which is lit from the top-left -> bevelled rims, a wet specular highlight
// on the lit edge, and a soft cast shadow onto the paper below-right.
// The canvas texture is premultiplied, so all maths stays premultiplied.

uniform float bevel_px = 5.0;          // how wide the rounded edge is
uniform vec2 light_dir = vec2(-0.55, -0.85);
uniform float shade_strength = 0.45;
uniform float spec_strength = 0.6;
uniform float spec_power = 18.0;
uniform vec2 shadow_offset_px = vec2(4.0, 7.0);
uniform float shadow_strength = 0.16;
uniform vec4 shadow_color : source_color = vec4(0.07, 0.06, 0.05, 1.0);
uniform float opacity = 0.96;
uniform float canvas_height = 2400.0;
uniform float wipe_y = -100000.0;       // squeegee: erase everything above this

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, UV);     // premultiplied paint

	// Height slope from neighbouring alpha (two radii for a smoother bevel)
	// v14: one radius (4 samples) instead of two (8); the canvas is smoothed anyway
	vec2 b1 = px * bevel_px;
	float gx = texture(TEXTURE, UV + vec2(b1.x, 0.0)).a - texture(TEXTURE, UV - vec2(b1.x, 0.0)).a;
	float gy = texture(TEXTURE, UV + vec2(0.0, b1.y)).a - texture(TEXTURE, UV - vec2(0.0, b1.y)).a;
	vec2 grad = vec2(gx, gy);

	vec3 n = normalize(vec3(-grad, 0.55));
	vec3 L = normalize(vec3(light_dir, 0.9));
	float shade = (dot(n, L) - L.z) * shade_strength;        // 0 on flat tops
	vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
	float spec = pow(max(dot(n, H), 0.0), spec_power) * spec_strength * clamp(length(grad), 0.0, 1.0);

	vec3 lit = c.rgb * (1.0 + shade) + vec3(spec) * c.a;

	// Soft cast shadow onto the paper where there is no paint
	float sh = texture(TEXTURE, UV - px * shadow_offset_px * 1.4).a;
	sh *= shadow_strength * (1.0 - c.a);

	vec3 rgb = lit + shadow_color.rgb * sh;
	float a = c.a + sh;
	COLOR = vec4(rgb, a) * opacity;
	if (UV.y * canvas_height < wipe_y) {
		COLOR = vec4(0.0);
	}
}
