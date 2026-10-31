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
