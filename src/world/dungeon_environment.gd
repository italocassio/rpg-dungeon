class_name DungeonEnvironment
extends RefCounted
## Ambiente e presets gráficos. Os presets existem para medir o desempenho em GPU integrada.

enum Quality { LOW, MEDIUM, HIGH }

const QUALITY_NAMES: Dictionary = { Quality.LOW: "Baixo", Quality.MEDIUM: "Médio", Quality.HIGH: "Alto" }


static func create(quality: Quality) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("04060c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9b4c9")
	env.ambient_light_energy = 0.26
	# O céu nunca aparece (fundo é cor sólida): serve só de fonte de reflexo para metal e gelo.
	env.sky = _reflection_sky()
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color("3c465e")
	env.fog_light_energy = 0.7
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 0.92
	apply_quality(env, quality)
	return env


static func _reflection_sky() -> Sky:
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = Color("8fa3c4")
	material.sky_horizon_color = Color("55607a")
	material.ground_horizon_color = Color("4a4238")
	material.ground_bottom_color = Color("6a5238")
	material.sun_angle_max = 0.0
	material.sky_energy_multiplier = 0.55
	material.ground_energy_multiplier = 0.55
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	return sky


static func apply_quality(env: Environment, quality: Quality) -> void:
	env.ssao_enabled = quality != Quality.LOW
	env.ssao_radius = 1.6
	env.ssao_intensity = 2.2
	env.ssao_power = 1.5
	env.volumetric_fog_enabled = quality == Quality.HIGH
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color("b8ccee")
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_ambient_inject = 0.25
	env.glow_enabled = quality != Quality.LOW


static func render_scale(quality: Quality) -> float:
	match quality:
		Quality.LOW:
			return 0.67
		Quality.MEDIUM:
			return 0.75
		_:
			return 1.0


static func shadowed_light_count(quality: Quality) -> int:
	match quality:
		Quality.LOW:
			return 0
		Quality.MEDIUM:
			return 2
		_:
			return 4
