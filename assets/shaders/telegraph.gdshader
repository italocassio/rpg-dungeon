shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, depth_test_disabled;

// Área de perigo no chão. Enche conforme o golpe se aproxima.
uniform vec3 tint : source_color = vec3(1.0, 0.25, 0.2);
uniform int shape = 0; // 0 círculo, 1 cone, 2 retângulo
uniform float half_angle = 0.8;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float mask = 0.0;
	float fill = 0.0;
	float edge = 0.0;
	if (shape == 2) {
		float x = abs(p.x);
		float y = UV.y;
		mask = step(x, 1.0);
		edge = smoothstep(0.9, 1.0, x) + smoothstep(0.03, 0.0, y) + smoothstep(0.97, 1.0, y);
		fill = step(1.0 - y, progress);
	} else {
		float r = length(p);
		mask = step(r, 1.0);
		edge = smoothstep(0.93, 0.985, r);
		fill = step(r, progress);
		if (shape == 1) {
			float a = abs(atan(p.x, -p.y));
			float inside = step(a, half_angle);
			mask *= inside;
			edge = max(edge, smoothstep(half_angle - 0.05, half_angle, a));
		}
	}
	float wave = 0.5 + 0.5 * sin(TIME * 12.0);
	float alpha = mask * (0.07 + fill * 0.16 + edge * (0.5 + wave * 0.3));
	ALBEDO = tint * 1.1;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
