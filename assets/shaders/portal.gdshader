shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

// Superfície do Portão: vórtice animado, cor vinda do rank.
uniform vec3 gate_color : source_color = vec3(0.2, 0.6, 1.0);
uniform sampler2D tex_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float intensity = 0.8;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float radius = length(uv);
	float angle = atan(uv.y, uv.x);
	vec2 spiral = vec2(angle / TAU + radius * 0.35 - TIME * 0.05, radius * 0.6 - TIME * 0.2);
	float swirl = texture(tex_noise, spiral).r * 0.65 + texture(tex_noise, spiral * 2.3 + TIME * 0.03).g * 0.5;
	float edge = smoothstep(1.0, 0.9, radius);
	float rim = smoothstep(0.62, 0.98, radius) * edge;
	float core = smoothstep(0.75, 0.0, radius);
	float energy = (swirl * 1.2 + rim * 1.6 + core * core * 0.9) * edge;
	ALBEDO = mix(gate_color, vec3(0.85, 0.95, 1.0), clamp(core * core * 0.35 + rim * swirl * 0.4, 0.0, 1.0)) * energy * intensity;
	ALPHA = edge;
}
