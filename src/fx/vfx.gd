class_name Vfx
extends RefCounted
## Efeitos visuais descartáveis. Sem renderização (headless) viram no-ops,
## o que mantém os testes de jogabilidade independentes da parte gráfica.


static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"


static func _burst(tree: SceneTree, position: Vector3, color: Color, amount: int, speed: float, size: float, life: float, gravity: float = -6.0, sprite: String = ParticleKit.SPARK) -> void:
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		return
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.18
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = speed * 0.4
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, gravity, 0.0)
	process.damping_min = 2.0
	process.damping_max = 5.0
	process.scale_curve = ParticleKit.fade_scale(1.0, 0.0)
	process.color_ramp = ParticleKit.gradient([color.lightened(0.5), color, Color(color, 0.0)], [0.0, 0.4, 1.0])
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.amount = amount
	particles.lifetime = life
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.draw_pass_1 = ParticleKit.quad(size, ParticleKit.sprite_material(sprite))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3.ONE * -8.0, Vector3.ONE * 16.0)
	root_node.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	_free_later(tree, particles, life + 0.3)


static func _free_later(tree: SceneTree, node: Node, seconds: float) -> void:
	tree.create_timer(seconds).timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free())


static func _flash(tree: SceneTree, position: Vector3, color: Color, energy: float, reach: float, life: float) -> void:
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	root_node.add_child(light)
	light.global_position = position
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, life)
	tween.tween_callback(light.queue_free)


static func hit_burst(tree: SceneTree, position: Vector3, color: Color) -> void:
	if not enabled():
		return
	_burst(tree, position, color, 12, 6.0, 0.14, 0.36)
	_flash(tree, position, color, 0.7, 4.0, 0.12)


static func shockwave(tree: SceneTree, position: Vector3, radius: float, color: Color) -> void:
	if not enabled():
		return
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		return
	var ring := MeshInstance3D.new()
	ring.mesh = MeshKit.torus(0.86, 1.0, 40)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color.r, color.g, color.b, 0.28)
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root_node.add_child(ring)
	ring.global_position = position + Vector3.UP * 0.2
	ring.scale = Vector3(0.2, 0.3, 0.2)
	var tween := ring.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(ring, "scale", Vector3(radius, 0.5, radius), 0.38)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.42)
	tween.chain().tween_callback(ring.queue_free)
	_burst(tree, position + Vector3.UP * 0.5, color, 20, radius * 1.8, 0.18, 0.5, -3.0)
	_flash(tree, position + Vector3.UP, color, 1.3, radius * 1.8, 0.28)


static func line_wave(tree: SceneTree, origin: Vector3, direction: Vector3, reach: float, width: float, color: Color) -> void:
	if not enabled():
		return
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	var steps: int = int(reach / 2.0)
	for i in steps:
		var point: Vector3 = origin + flat * (float(i) + 0.5) * 2.0
		_burst(tree, point + Vector3.UP * 0.3, color, 8, 4.0, 0.34, 0.4, 2.0)
	_flash(tree, origin + flat * reach * 0.5, color, 1.2, reach, 0.25)
	if width > 8.0:
		push_warning("Linha muito larga para o efeito: %s" % width)


static func falling_star(tree: SceneTree, point: Vector3, delay: float, color: Color) -> void:
	if not enabled():
		return
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		return
	var star := MeshInstance3D.new()
	star.mesh = MeshKit.sphere(0.9, 10)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5)
	star.material_override = material
	root_node.add_child(star)
	star.global_position = point + Vector3(4.0, 11.0, -3.0)
	var trail := ParticleKit.flame(color, color.darkened(0.3), 0.6, 14)
	star.add_child(trail)
	var tween := star.create_tween().set_ease(Tween.EASE_IN)
	tween.tween_property(star, "global_position", point + Vector3.UP * 0.4, delay)
	tween.tween_callback(star.queue_free)


static func heal_glow(tree: SceneTree, position: Vector3, color: Color) -> void:
	if not enabled():
		return
	_burst(tree, position + Vector3.UP * 0.6, Color(color, 0.5), 14, 2.2, 0.16, 0.8, 3.0, ParticleKit.SPARK)
	_flash(tree, position + Vector3.UP, color, 0.6, 4.5, 0.35)


static func melee_arc(tree: SceneTree, actor: Node3D, forward: Vector3, reach: float, color: Color, flip: bool) -> void:
	if not enabled():
		return
	var root_node: Node3D = CombatWorld.root(tree)
	var flat := Vector3(forward.x, 0.0, forward.z)
	if root_node == null or flat.length_squared() < 0.01:
		return
	var arc := MeshInstance3D.new()
	var path := PackedVector2Array()
	for i in 15:
		var angle: float = lerpf(-1.1, 1.1, float(i) / 14.0)
		path.append(Vector2(sin(angle), cos(angle)) * reach)
	arc.mesh = MeshKit.extrude_path(path, 0.2, 0.02)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color.r, color.g, color.b, 0.16)
	arc.material_override = material
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root_node.add_child(arc)
	arc.global_position = actor.global_position + Vector3.UP * 1.15
	arc.look_at(arc.global_position + flat, Vector3.UP)
	arc.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
	arc.rotate_object_local(Vector3.FORWARD, 0.5 if flip else -0.5)
	var tween := arc.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(arc.queue_free)


static func attach_projectile_visual(projectile: Projectile, skill: SkillData) -> void:
	if not enabled():
		return
	var big: bool = skill.radius > 0.0
	var size: float = 0.4 if big else 0.2
	var orb := MeshInstance3D.new()
	orb.mesh = MeshKit.sphere(size, 10)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(skill.color.r * 2.6, skill.color.g * 2.6, skill.color.b * 2.6)
	orb.material_override = material
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	projectile.add_child(orb)
	var trail := ParticleKit.flame(skill.color.lightened(0.3), skill.color, size * 1.6, 18 if big else 10)
	(trail.process_material as ParticleProcessMaterial).initial_velocity_max = 0.5
	trail.lifetime = 0.45
	trail.local_coords = false
	projectile.add_child(trail)
	var light := OmniLight3D.new()
	light.light_color = skill.color
	light.light_energy = 2.0
	light.omni_range = 6.0
	projectile.add_child(light)


static func attach_zone_visual(zone: HealZone, skill: SkillData) -> void:
	if not enabled():
		return
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = skill.radius
	mesh.bottom_radius = skill.radius
	mesh.height = 0.04
	mesh.radial_segments = 40
	disc.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(skill.color, 0.18)
	disc.material_override = material
	disc.position.y = 0.16
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	zone.add_child(disc)
	var motes := ParticleKit.embers(skill.color, 30)
	(motes.process_material as ParticleProcessMaterial).emission_sphere_radius = skill.radius * 0.9
	zone.add_child(motes)
	var light := OmniLight3D.new()
	light.position.y = 1.5
	light.light_color = skill.color
	light.light_energy = 1.8
	light.omni_range = skill.radius * 1.8
	zone.add_child(light)


static func floating_text(tree: SceneTree, position: Vector3, text: String, color: Color, size: int = 40) -> void:
	if not enabled():
		return
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		return
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.outline_size = 10
	label.modulate = color
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0009
	label.render_priority = 20
	label.outline_render_priority = 19
	root_node.add_child(label)
	label.global_position = position + Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.3, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.45)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.5).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)


# --- Efeitos de ataque do chefe (OS-022). Primitivas; as composições ficam em BossImpact e AttackFx. ---

const _STAKE_SEED := 7

static var _stake_mesh: ArrayMesh
static var _emitter_cache: Dictionary[String, ParticleProcessMaterial] = {}
static var _quad_cache: Dictionary[String, QuadMesh] = {}
static var _crack_cache: Dictionary[String, ArrayMesh] = {}
## Materiais planos reaproveitados por "vaga": criar um material novo e atribuí-lo a uma malha custa uns 5 ms
## no quadro do golpe, e reaproveitar a instância custa menos de 0,1 ms.
static var _slot_materials: Dictionary[String, StandardMaterial3D] = {}
static var _slot_fades: Dictionary[String, Tween] = {}
static var _glint_material: StandardMaterial3D
static var _shape_cache: Dictionary[String, ArrayMesh] = {}


## Luz de clarão sem sombra que apaga em `life` segundos.
static func flash_light(tree: SceneTree, position: Vector3, color: Color, energy: float, reach: float, life: float) -> void:
	if enabled() and energy > 0.0:
		_flash(tree, position, color, energy, reach, life)


## Monta um emissor a partir de `EmitterSpec` sob `parent`. Devolve null sem janela.
## O material de processo e o quadro de cada configuração ficam em cache: criar texturas e materiais a cada
## impacto custava mais de 10 ms no quadro do golpe.
static func emitter(parent: Node, spec: EmitterSpec) -> GPUParticles3D:
	if not enabled() or parent == null:
		return null
	var particles := GPUParticles3D.new()
	particles.process_material = emitter_material(spec)
	particles.amount = spec.amount
	particles.lifetime = spec.lifetime
	particles.one_shot = spec.one_shot
	particles.explosiveness = spec.explosiveness
	particles.local_coords = not spec.world_space
	particles.draw_pass_1 = emitter_quad(spec)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-40.0, -4.0, -40.0), Vector3(80.0, 24.0, 80.0))
	parent.add_child(particles)
	particles.emitting = true
	return particles


static func emitter_material(spec: EmitterSpec) -> ParticleProcessMaterial:
	var key: String = "pm_%d_%.3f_%s_%.1f_%.3f_%.3f_%s_%.3f_%.3f_%.3f_%s_%.2f_%.2f_%.2f" % [spec.shape, spec.shape_radius, spec.direction, spec.spread, spec.speed_min, spec.speed_max, spec.gravity, spec.radial_accel_min, spec.radial_accel_max, spec.damping, spec.color.to_html(), spec.scale_start, spec.scale_end, spec.fade_start]
	if _emitter_cache.has(key):
		return _emitter_cache[key]
	var process := ParticleProcessMaterial.new()
	if spec.shape == EmitterSpec.Shape.RING:
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		process.emission_ring_axis = Vector3.UP
		process.emission_ring_radius = spec.shape_radius
		process.emission_ring_inner_radius = spec.shape_radius * 0.92
		process.emission_ring_height = 0.2
	else:
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		process.emission_sphere_radius = maxf(spec.shape_radius, 0.01)
	process.direction = spec.direction
	process.spread = spec.spread
	process.initial_velocity_min = spec.speed_min
	process.initial_velocity_max = spec.speed_max
	process.gravity = spec.gravity
	process.radial_accel_min = spec.radial_accel_min
	process.radial_accel_max = spec.radial_accel_max
	process.damping_min = spec.damping
	process.damping_max = spec.damping
	process.scale_curve = ParticleKit.fade_scale(spec.scale_start, spec.scale_end)
	process.color_ramp = ParticleKit.gradient([spec.color, spec.color, Color(spec.color, 0.0)], [0.0, spec.fade_start, 1.0])
	_emitter_cache[key] = process
	return process


static func emitter_quad(spec: EmitterSpec) -> QuadMesh:
	var key: String = "quad_%s_%s_%.3f" % [spec.sprite, spec.additive, spec.size]
	if _quad_cache.has(key):
		return _quad_cache[key]
	var quad: QuadMesh = ParticleKit.quad(spec.size, ParticleKit.sprite_material(spec.sprite, spec.additive))
	_quad_cache[key] = quad
	return quad


## Brilho billboard aditivo (a ponta da lâmina no preparo). O material é um só, reaproveitado.
static func glint(parent: Node, color: Color, size: float) -> MeshInstance3D:
	if not enabled() or parent == null:
		return null
	var instance := MeshInstance3D.new()
	instance.mesh = ParticleKit.quad(size, glint_material(color))
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


static func glint_material(color: Color) -> StandardMaterial3D:
	if _glint_material == null:
		_glint_material = StandardMaterial3D.new()
		_glint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glint_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_glint_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_glint_material.albedo_texture = load(ParticleKit.SPARK)
		_glint_material.disable_receive_shadows = true
	_glint_material.albedo_color = color
	return _glint_material


static func stake_mesh() -> ArrayMesh:
	if _stake_mesh == null:
		var rng := RandomNumberGenerator.new()
		rng.seed = _STAKE_SEED
		_stake_mesh = MeshKit.shard(1.0, 1.0, rng, 5, 0.0)
	return _stake_mesh


## Estaca de cristal: sobe, segura e afunda. `height` e `base_radius` em metros; inclinada `lean` rad para `lean_direction`.
static func stake(parent: Node3D, position: Vector3, height: float, base_radius: float, lean_direction: Vector3, lean: float, material: Material, delay: float, rise: float, hold: float, sink: float) -> MeshInstance3D:
	if not enabled() or parent == null:
		return null
	var instance := MeshInstance3D.new()
	instance.mesh = stake_mesh()
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	instance.global_position = position
	var tilt_axis: Vector3 = Vector3.UP.cross(lean_direction)
	if tilt_axis.length_squared() > 0.0001 and lean != 0.0:
		instance.global_basis = Basis(tilt_axis.normalized(), lean)
	instance.scale = Vector3(base_radius, 0.001, base_radius)
	var tween := instance.create_tween()
	tween.tween_interval(maxf(delay, 0.0))
	tween.tween_property(instance, "scale:y", height, rise).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(hold)
	tween.tween_property(instance, "scale:y", 0.001, sink).set_ease(Tween.EASE_IN)
	tween.tween_callback(instance.queue_free)
	return instance


## Malha da rachadura: duas superfícies (a escura e o fio aceso por cima). Em cache por forma.
static func crack_mesh(points: PackedVector2Array, width_start: float, width_end: float, thread_width: float) -> ArrayMesh:
	var key: String = "crack_%d_%.3f_%.3f_%.3f" % [hash(points), width_start, width_end, thread_width]
	if _crack_cache.has(key):
		return _crack_cache[key]
	var mesh := ArrayMesh.new()
	_add_ribbon(mesh, points, width_start, width_end, 0.0)
	_add_ribbon(mesh, points, thread_width, thread_width, 0.012)
	_crack_cache[key] = mesh
	return mesh


## Faixa plana no chão ao longo de `points` (x, z), com a largura afinando de `width_start` a `width_end`.
## `dark_material` na superfície escura e `thread_material` no fio aceso, por instância (a malha é compartilhada).
static func crack(parent: Node3D, position: Vector3, points: PackedVector2Array, width_start: float, width_end: float, thread_width: float, dark_material: Material, thread_material: Material) -> MeshInstance3D:
	if not enabled() or parent == null or points.size() < 2:
		return null
	var instance := MeshInstance3D.new()
	instance.mesh = crack_mesh(points, width_start, width_end, thread_width)
	instance.set_surface_override_material(0, dark_material)
	instance.set_surface_override_material(1, thread_material)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	instance.global_position = position
	return instance


static func _add_ribbon(mesh: ArrayMesh, points: PackedVector2Array, width_start: float, width_end: float, lift: float) -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var normals := PackedVector3Array()
	var last: int = points.size() - 1
	for i in points.size():
		var previous: Vector2 = points[maxi(i - 1, 0)]
		var following: Vector2 = points[mini(i + 1, last)]
		var direction: Vector2 = (following - previous).normalized()
		var side := Vector2(-direction.y, direction.x)
		var half: float = lerpf(width_start, width_end, float(i) / float(last)) * 0.5
		var left: Vector2 = points[i] + side * half
		var right: Vector2 = points[i] - side * half
		vertices.append(Vector3(left.x, lift, left.y))
		vertices.append(Vector3(right.x, lift, right.y))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	for i in last:
		var base: int = i * 2
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


## Anel em zigue-zague no chão (raio 1 na malha; a escala dá o raio). `thickness` e `zigzag` já relativos ao raio final.
static func jagged_ring_mesh(teeth: int, thickness: float, zigzag: float) -> ArrayMesh:
	var key: String = "ring_%d_%.4f_%.4f" % [teeth, thickness, zigzag]
	if _shape_cache.has(key):
		return _shape_cache[key]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var count: int = teeth * 2
	for i in count + 1:
		var angle: float = TAU * float(i % count) / float(count)
		var base: float = 1.0 + (zigzag if i % 2 == 0 else -zigzag) * 0.5
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		vertices.append(direction * (base + thickness * 0.5))
		vertices.append(direction * (base - thickness * 0.5))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	for i in count:
		var first: int = i * 2
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first + 1, first + 3, first + 2]))
	var mesh := _mesh_from(vertices, normals, indices)
	_shape_cache[key] = mesh
	return mesh


## Meia-lua plana no chão, de raio externo 1, centrada na frente (-Z). Largura `width` (relativa ao raio) no meio e zero nas pontas.
static func crescent_mesh(half_angle: float, width: float) -> ArrayMesh:
	var key: String = "crescent_%.3f_%.4f" % [half_angle, width]
	if _shape_cache.has(key):
		return _shape_cache[key]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var steps: int = 24
	for i in steps + 1:
		var t: float = float(i) / float(steps)
		var angle: float = lerpf(-half_angle, half_angle, t)
		var taper: float = pow(maxf(1.0 - pow(absf(t * 2.0 - 1.0), 2.0), 0.0), 0.7)
		var direction := Vector3(sin(angle), 0.0, -cos(angle))
		vertices.append(direction)
		vertices.append(direction * (1.0 - width * taper))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	for i in steps:
		var first: int = i * 2
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first + 1, first + 3, first + 2]))
	var mesh := _mesh_from(vertices, normals, indices)
	_shape_cache[key] = mesh
	return mesh


static func _mesh_from(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Material plano sem luz para as camadas do chão e do ar: aditivo ou por mistura.
static func flat_material(color: Color, additive: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	material.disable_receive_shadows = true
	return material


## Material plano persistente da vaga `slot`, na cor pedida. Uma vaga só serve a um efeito por vez: o desvanecer
## anterior (`fade_slot`) é cancelado quando a vaga volta a ser pedida.
static func slot_material(slot: String, color: Color, additive: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = _slot_materials.get(slot)
	if material == null:
		material = flat_material(color, additive)
		_slot_materials[slot] = material
	if _slot_fades.has(slot) and is_instance_valid(_slot_fades[slot]):
		_slot_fades[slot].kill()
	_slot_fades.erase(slot)
	material.albedo_color = color
	return material


## Faz o alfa da vaga ir a zero em `seconds` depois de `delay`.
static func fade_slot(slot: String, owner_node: Node, seconds: float, delay: float = 0.0) -> void:
	var material: StandardMaterial3D = _slot_materials.get(slot)
	if material == null or not is_instance_valid(owner_node):
		return
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, seconds).set_delay(delay)
	_slot_fades[slot] = tween


## Atribui o material a uma malha solta, só para o Godot montar o shader agora e não no quadro do golpe.
static func warm_material(material: Material) -> void:
	var probe := MeshInstance3D.new()
	probe.material_override = material
	probe.free()
