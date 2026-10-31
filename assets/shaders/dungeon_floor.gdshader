shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Piso de lajes parcialmente coberto de neve, com placas de gelo polido.
uniform sampler2D stone_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_orm : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D snow_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D snow_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ice_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ice_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_noise : hint_default_white, filter_linear_mipmap, repeat_enable;

varying vec3 world_position;
varying float drift;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	drift = COLOR.r;
}

void fragment() {
	vec2 p = world_position.xz;
	vec3 stone = texture(stone_albedo, p / 4.0).rgb;
	vec3 stone_n = texture(stone_normal, p / 4.0).rgb;
	vec3 orm = texture(stone_orm, p / 4.0).rgb;
	vec3 snow = texture(snow_albedo, p / 3.0).rgb;
	vec3 snow_n = texture(snow_normal, p / 3.0).rgb;
	vec3 ice = texture(ice_albedo, p / 6.0).rgb;
	vec3 ice_n = texture(ice_normal, p / 6.0).rgb;

	float n1 = texture(tex_noise, p * 0.019).r;
	float n2 = texture(tex_noise, p * 0.067).g;
	float n3 = texture(tex_noise, p * 0.23).b;
	float cover = n1 * 0.55 + n2 * 0.33 + n3 * 0.12 + drift * 0.55;

	float snow_mask = smoothstep(0.455, 0.60, cover + (orm.b - 0.5) * 0.16);
	float ice_mask = smoothstep(0.47, 0.40, n1 * 0.7 + n2 * 0.3) * (1.0 - snow_mask);

	vec3 color = mix(stone * 1.25, ice * vec3(0.36, 0.38, 0.42), ice_mask * 0.85);
	color = mix(color, snow, snow_mask);

	ALBEDO = color;
	ROUGHNESS = mix(mix(orm.g, 0.14, ice_mask), 0.6, snow_mask);
	SPECULAR = mix(0.45, 0.6, ice_mask);
	NORMAL_MAP = mix(mix(stone_n, ice_n, ice_mask), snow_n, snow_mask);
	NORMAL_MAP_DEPTH = 1.0;
	AO = mix(orm.r, 1.0, snow_mask);
	AO_LIGHT_AFFECT = 0.3;
}
