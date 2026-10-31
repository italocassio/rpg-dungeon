class_name DungeonMaterials
extends RefCounted
## Materiais compartilhados do cenário.

const TEX := "res://assets/textures/"

static var _cache: Dictionary[StringName, Material] = {}


static func wall() -> ShaderMaterial:
	return _shader_material(&"wall", "res://assets/shaders/dungeon_wall.gdshader", {
		"tex_albedo": "stone_wall_albedo", "tex_normal": "stone_wall_normal",
		"tex_orm": "stone_wall_orm", "tex_noise": "noise",
	})


static func ceiling() -> ShaderMaterial:
	if _cache.has(&"ceiling"):
		return _cache[&"ceiling"]
	var material: ShaderMaterial = wall().duplicate()
	material.set_shader_parameter("frost_amount", 0.35)
	material.set_shader_parameter("ground_frost_height", -5.0)
	_cache[&"ceiling"] = material
	return material


static func floor_surface() -> ShaderMaterial:
	return _shader_material(&"floor", "res://assets/shaders/dungeon_floor.gdshader", {
		"stone_albedo": "stone_floor_albedo", "stone_normal": "stone_floor_normal", "stone_orm": "stone_floor_orm",
		"snow_albedo": "snow_albedo", "snow_normal": "snow_normal",
		"ice_albedo": "ice_albedo", "ice_normal": "ice_normal", "tex_noise": "noise",
	})


static func stone_prop(tile: float = 0.3) -> StandardMaterial3D:
	return _triplanar(StringName("stone_%.2f" % tile), "stone_wall", tile)


static func wood() -> StandardMaterial3D:
	return _textured(&"wood_mat", "wood")


static func iron() -> StandardMaterial3D:
	var material: StandardMaterial3D = _triplanar(&"iron_mat", "metal", 0.8)
	material.metallic = 0.5
	material.albedo_color = Color(0.5, 0.52, 0.58)
	return material


static func crystal(core := Color(0.16, 0.42, 0.72), rim := Color(0.6, 0.88, 1.0), glow: float = 1.0) -> ShaderMaterial:
	var key := StringName("crystal_%s_%s_%.1f" % [core.to_html(), rim.to_html(), glow])
	if _cache.has(key):
		return _cache[key]
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/ice_crystal.gdshader")
	material.set_shader_parameter("core_color", core)
	material.set_shader_parameter("rim_color", rim)
	material.set_shader_parameter("glow", glow)
	_cache[key] = material
	return material


static func _shader_material(key: StringName, path: String, textures: Dictionary) -> ShaderMaterial:
	if _cache.has(key):
		return _cache[key]
	var material := ShaderMaterial.new()
	material.shader = load(path)
	for parameter: String in textures:
		material.set_shader_parameter(parameter, load(TEX + textures[parameter] + ".png"))
	_cache[key] = material
	return material


static func _triplanar(key: StringName, base: String, tile: float) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var material: StandardMaterial3D = _pbr(base)
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * tile
	_cache[key] = material
	return material


static func _textured(key: StringName, base: String) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var material: StandardMaterial3D = _pbr(base)
	_cache[key] = material
	return material


static func _pbr(base: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(TEX + base + "_albedo.png")
	material.normal_enabled = true
	material.normal_texture = load(TEX + base + "_normal.png")
	var orm: Texture2D = load(TEX + base + "_orm.png")
	material.roughness_texture = orm
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.ao_enabled = true
	material.ao_texture = orm
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material
