shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Cristal de gelo com brilho interno: forte nas bordas e nas pontas.
uniform vec3 core_color : source_color = vec3(0.16, 0.42, 0.72);
uniform vec3 rim_color : source_color = vec3(0.6, 0.88, 1.0);
uniform float glow = 1.6;
uniform float pulse_speed = 0.8;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float height = clamp(local_position.y * 0.7, 0.0, 1.0);
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed + NODE_POSITION_WORLD.x * 0.7);
	ALBEDO = mix(core_color * 0.7, rim_color * 0.8, fresnel * 0.55);
	METALLIC = 0.35;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = (core_color * height * 0.5 + rim_color * fresnel) * glow * pulse;
}
