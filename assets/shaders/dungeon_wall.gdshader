shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Pedra com geada: a neve assenta nas bordas superiores dos blocos e sobe a partir do chão.
uniform sampler2D tex_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_orm : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 snow_color : source_color = vec3(0.80, 0.87, 1.0);
uniform float frost_amount : hint_range(0.0, 1.5) = 1.0;
uniform float ground_frost_height = 1.5;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 albedo = texture(tex_albedo, UV).rgb;
	vec3 normal_sample = texture(tex_normal, UV).rgb;
	vec3 orm = texture(tex_orm, UV).rgb;
	vec3 noise = texture(tex_noise, vec2(UV.x * 0.37, UV.y * 0.37)).rgb;
	vec3 fine = texture(tex_noise, UV * 1.7).rgb;

	// Neve pousa nas bordas superiores dos blocos; a altura decide o quanto ela sobe na parede.
	float ledge = smoothstep(0.56, 0.68, normal_sample.g) * smoothstep(0.34, 0.6, noise.g + 0.12);
	float climb = world_position.y + (noise.r - 0.5) * 2.6 + (fine.g - 0.5) * 0.9 - (orm.b - 0.5) * 0.9;
	float ground = smoothstep(ground_frost_height, ground_frost_height - 1.1, climb);
	float hoar = smoothstep(0.6, 0.85, noise.b) * smoothstep(0.35, 0.7, fine.r) * 0.32;
	float rime = smoothstep(ground_frost_height + 1.8, ground_frost_height - 0.4, world_position.y) * 0.3;
	float frost = clamp(max(ledge, ground) + hoar + rime, 0.0, 1.0) * frost_amount;

	ALBEDO = mix(albedo, snow_color * (0.86 + 0.14 * orm.b), frost);
	ROUGHNESS = mix(orm.g, 0.5, frost);
	SPECULAR = 0.4;
	NORMAL_MAP = mix(normal_sample, vec3(0.5, 0.5, 1.0), frost * 0.65);
	NORMAL_MAP_DEPTH = 1.25;
	AO = orm.r;
	AO_LIGHT_AFFECT = 0.35;
}
