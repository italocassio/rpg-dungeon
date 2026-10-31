class_name ParticleKit
extends RefCounted
## Construtores de partículas e materiais de efeitos.

const SOFT := "res://assets/textures/fx_soft.png"
const SPARK := "res://assets/textures/fx_spark.png"
const FLAKE := "res://assets/textures/fx_flake.png"
const SMOKE := "res://assets/textures/fx_smoke.png"

static var _sprite_cache: Dictionary[String, StandardMaterial3D] = {}


## Material de sprite billboard; cor vem da partícula.
static func sprite_material(texture_path: String, additive: bool = true) -> StandardMaterial3D:
	var key: String = "%s_%s" % [texture_path, additive]
	if _sprite_cache.has(key):
		return _sprite_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture_path)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.disable_receive_shadows = true
	_sprite_cache[key] = material
	return material


static func quad(size: float, material: Material) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * size
	mesh.material = material
	return mesh


static func gradient(colors: Array[Color], offsets: Array[float]) -> GradientTexture1D:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array(offsets)
	ramp.colors = PackedColorArray(colors)
	var texture := GradientTexture1D.new()
	texture.gradient = ramp
	return texture


static func fade_scale(start: float = 1.0, finish: float = 0.0) -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, start))
	curve.add_point(Vector2(1.0, finish))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## Chama contínua de braseiro/tocha.
static func flame(color_hot: Color, color_cool: Color, size: float = 0.42, amount: int = 26) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = size * 0.45
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = 0.7
	process.initial_velocity_max = 1.5
	process.gravity = Vector3(0.0, 0.8, 0.0)
	process.damping_min = 0.3
	process.damping_max = 0.6
	process.scale_min = 0.7
	process.scale_max = 1.2
	process.scale_curve = fade_scale(1.0, 0.1)
	process.color_ramp = gradient(
		[color_hot.lightened(0.5), color_hot, color_cool, Color(color_cool, 0.0)],
		[0.0, 0.25, 0.65, 1.0])
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.amount = amount
	particles.lifetime = 0.8
	particles.draw_pass_1 = quad(size * 1.8, sprite_material(SOFT))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	return particles


## Cinzas/fagulhas que sobem devagar.
static func embers(color: Color, amount: int = 10) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.3
	process.direction = Vector3.UP
	process.spread = 25.0
	process.initial_velocity_min = 0.8
	process.initial_velocity_max = 2.0
	process.gravity = Vector3(0.0, 0.15, 0.0)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.8
	process.scale_min = 0.5
	process.scale_max = 1.0
	process.color_ramp = gradient([color, Color(color, 0.0)], [0.4, 1.0])
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.amount = amount
	particles.lifetime = 2.2
	particles.draw_pass_1 = quad(0.07, sprite_material(SPARK))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
	return particles


## Pó de neve que acompanha a câmera: dá profundidade ao ar.
static func snowfall(extents: Vector3, amount: int) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3.DOWN
	process.spread = 25.0
	process.initial_velocity_min = 0.3
	process.initial_velocity_max = 0.9
	process.gravity = Vector3(0.0, -0.12, 0.0)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.5
	process.turbulence_noise_scale = 2.4
	process.scale_min = 0.5
	process.scale_max = 1.2
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.color_ramp = gradient(
		[Color(0.85, 0.92, 1.0, 0.0), Color(0.85, 0.92, 1.0, 0.75), Color(0.85, 0.92, 1.0, 0.75), Color(0.85, 0.92, 1.0, 0.0)],
		[0.0, 0.15, 0.8, 1.0])
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.amount = amount
	particles.lifetime = 8.0
	particles.preprocess = 4.0
	particles.draw_pass_1 = quad(0.075, sprite_material(FLAKE))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.local_coords = false
	particles.visibility_aabb = AABB(-extents * 2.0, extents * 4.0)
	return particles
