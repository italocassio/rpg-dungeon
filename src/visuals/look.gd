class_name Look
extends RefCounted
## Materiais de personagens e armas.

static var _cache: Dictionary[String, StandardMaterial3D] = {}


static func matte(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "m_%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if _cache.has(key):
		return _cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.rim_enabled = true
	material.rim = 0.35
	material.rim_tint = 0.5
	_cache[key] = material
	return material


## Metal com textura martelada; dá detalhe às armaduras sem precisar de UV.
static func metal(color: Color, roughness_scale: float = 0.8) -> StandardMaterial3D:
	var key := "x_%s_%.2f" % [color.to_html(), roughness_scale]
	if _cache.has(key):
		return _cache[key]
	var material: StandardMaterial3D = DungeonMaterials.iron().duplicate()
	material.albedo_color = color.lightened(0.32)
	# Metal parcial: sem cena para refletir, metálico puro fica preto em ambientes escuros.
	material.metallic = 0.35
	material.roughness = roughness_scale
	material.uv1_world_triplanar = false
	material.uv1_scale = Vector3.ONE * 1.6
	material.rim_enabled = true
	material.rim = 0.3
	_cache[key] = material
	return material


static func glow(color: Color, energy: float = 2.5) -> StandardMaterial3D:
	var key := "g_%s_%.2f" % [color.to_html(), energy]
	if _cache.has(key):
		return _cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.4)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_cache[key] = material
	return material


## Versão de um material para a arma em primeira pessoa: desenhada sobre o cenário.
static func for_viewmodel(source: Material) -> Material:
	var standard := source as BaseMaterial3D
	if standard == null:
		return source
	var material: BaseMaterial3D = standard.duplicate()
	material.use_z_clip_scale = true
	material.z_clip_scale = 0.08
	material.use_fov_override = true
	material.fov_override = 74.0
	return material
