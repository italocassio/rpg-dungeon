class_name Look
extends RefCounted
## Materiais de personagens e armas.

## Luz de personagem (M4): emissão igual ao albedo, só para heróis.
const CHARACTER_LIGHT := 0.2
## Metal de acabamento por tier, de T0 a T3 (seção 9 do guia de estilo).
const TRIM_COLORS: Array[Color] = [Color("C8963F"), Color("C4D2E0"), Color("D8B464"), Color("E6ECF5")]

## Brilho máximo no viewmodel (B4): o lendário chega a 1,0 no modelo, mas na primeira pessoa a mesma energia lava a cor.
const VIEWMODEL_MAX_ENERGY := 0.9

static var _cache: Dictionary[String, StandardMaterial3D] = {}
## Uma duplicata por material de origem, compartilhada por todas as peças e todos os `setup` do viewmodel.
static var _viewmodel_cache: Dictionary[Material, Material] = {}


static func matte(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "m_%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if _cache.has(key):
		return _cache[key]
	var material := _surface(color, roughness, metallic)
	_cache[key] = material
	return material


## Material de herói: `matte` com a luz de personagem. Cache própria, nunca altera `matte`.
static func hero(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "h_%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if _cache.has(key):
		return _cache[key]
	var material := _surface(color, roughness, metallic)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = CHARACTER_LIGHT
	_cache[key] = material
	return material


## Pano com as duas faces (M1): cópia de `hero` com o culling desligado, em cache própria.
static func two_sided(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var key := "t_%s_%.2f" % [color.to_html(), roughness]
	if _cache.has(key):
		return _cache[key]
	var material: StandardMaterial3D = hero(color, roughness).duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[key] = material
	return material


## Metal de acabamento do tier (0 a 3).
static func trim(tier: int) -> StandardMaterial3D:
	return hero(TRIM_COLORS[clampi(tier, 0, TRIM_COLORS.size() - 1)], 0.40, 0.45)


static func _surface(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.rim_enabled = true
	material.rim = 0.35
	material.rim_tint = 0.5
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


## Barreira de guarda do viewmodel: aditiva, sem sombreamento, uma por cor.
static func barrier(color: Color) -> StandardMaterial3D:
	var key := "b_%s" % color.to_html()
	if _cache.has(key):
		return _cache[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color.r, color.g, color.b, 0.22)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[key] = material
	return material


## Versão de um material para a arma em primeira pessoa: desenhada sobre o cenário.
## A duplicata é compartilhada (cache por origem): depois daqui, nada altera o material.
static func for_viewmodel(source: Material) -> Material:
	var standard := source as BaseMaterial3D
	if standard == null:
		return source
	if _viewmodel_cache.has(source):
		return _viewmodel_cache[source]
	var material: BaseMaterial3D = standard.duplicate()
	material.use_z_clip_scale = true
	material.z_clip_scale = 0.08
	material.use_fov_override = true
	material.fov_override = 74.0
	if material.emission_enabled:
		material.emission_energy_multiplier = minf(material.emission_energy_multiplier, VIEWMODEL_MAX_ENERGY)
	_viewmodel_cache[source] = material
	return material
