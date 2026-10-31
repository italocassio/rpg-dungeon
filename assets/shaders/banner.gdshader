shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// Estandarte de tecido balançando com a corrente de ar.
uniform vec3 cloth_color : source_color = vec3(0.5, 0.05, 0.06);
uniform vec3 trim_color : source_color = vec3(0.8, 0.62, 0.25);
uniform sampler2D tex_noise : hint_default_white, filter_linear_mipmap, repeat_enable;

void vertex() {
	float sway = (1.0 - UV.y * 0.0) * UV.y;
	VERTEX.z += sin(TIME * 1.3 + UV.y * 4.0 + NODE_POSITION_WORLD.x) * 0.11 * sway;
	VERTEX.x += sin(TIME * 0.9 + UV.y * 3.0) * 0.04 * sway;
}

void fragment() {
	vec2 centered = abs(UV - vec2(0.5, 0.0));
	float trim = smoothstep(0.42, 0.45, centered.x) + smoothstep(0.93, 0.95, UV.y - centered.x * 0.0);
	float tear = texture(tex_noise, UV * vec2(1.4, 0.9)).r;
	if (UV.y > 0.86 + tear * 0.14 - centered.x * 0.15) {
		discard;
	}
	float weave = 0.75 + texture(tex_noise, UV * 9.0).g * 0.5;
	ALBEDO = mix(cloth_color * weave, trim_color, clamp(trim, 0.0, 1.0));
	ROUGHNESS = 0.85;
}
