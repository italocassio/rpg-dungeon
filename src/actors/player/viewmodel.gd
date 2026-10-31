class_name Viewmodel
extends Node3D
## Mãos e arma em primeira pessoa. Animação por deslocamentos sobrepostos à pose de repouso.

const RIGHT_REST := Vector3(0.36, -0.31, -0.66)
const LEFT_REST := Vector3(-0.54, -0.45, -0.72)
const WEAPON_SCALE := 0.82
const SHIELD_SCALE := 0.62
const SWAY_LIMIT := 0.05

var class_id: StringName = &""
var _right: Node3D
var _left: Node3D
var _right_offset := Transform3D.IDENTITY
var _left_offset := Transform3D.IDENTITY
var _right_rest_rotation := Vector3.ZERO
var _left_rest_rotation := Vector3.ZERO
var _sway := Vector2.ZERO
var _action_tween: Tween
var _cast_light: OmniLight3D
var _cast_particles: GPUParticles3D
var _guard_shield: MeshInstance3D
var _glow_tween: Tween
var _skin_tint := Color("d9a981")

var right_position := Vector3.ZERO:
	set(value):
		right_position = value
var right_rotation := Vector3.ZERO
var left_position := Vector3.ZERO
var left_rotation := Vector3.ZERO


func setup(class_data: ClassData, weapon: ItemData) -> void:
	class_id = class_data.id
	for child in get_children():
		child.queue_free()
	_right = Node3D.new()
	_left = Node3D.new()
	add_child(_right)
	add_child(_left)

	var sleeve: Material
	var model: StringName = weapon.weapon_model
	match class_data.id:
		&"warrior":
			sleeve = Look.metal(Color("7f8ca0"), 0.45)
		&"mage":
			sleeve = Look.matte(Color("3f5fae"), 0.8)
		_:
			sleeve = Look.matte(Color("e8e2cf"), 0.8)
	_build_arm(_right, sleeve, 1.0)
	_build_arm(_left, sleeve, -1.0)

	var main_hand: Node3D = WeaponKit.build_main_hand(model, weapon.rarity)
	main_hand.scale = Vector3.ONE * WEAPON_SCALE
	_right.add_child(main_hand)
	var off_hand: Node3D = WeaponKit.build_off_hand(model)
	if off_hand != null:
		_left.add_child(off_hand)
		off_hand.scale = Vector3.ONE * SHIELD_SCALE
		off_hand.rotation = Vector3(-0.15, 0.55, 0.1)
		off_hand.position = Vector3(0.0, 0.06, -0.04)
	match model:
		&"staff":
			main_hand.rotation = Vector3(-0.55, 0.0, 0.12)
			main_hand.position = Vector3(0.0, -0.3, 0.1)
			_right_rest_rotation = Vector3(0.12, 0.0, 0.0)
		&"orb":
			main_hand.position = Vector3(0.0, 0.03, -0.05)
		&"tome":
			main_hand.position = Vector3(0.0, 0.03, -0.05)
		_:
			main_hand.rotation = Vector3(-0.42, 0.0, -0.16)
			main_hand.position = Vector3(0.0, -0.02, 0.0)
			_right_rest_rotation = Vector3(0.35, 0.05, 0.0)
	_right.rotation = _right_rest_rotation
	_left.rotation = _left_rest_rotation

	_guard_shield = _build_barrier(class_data.color)
	add_child(_guard_shield)
	_cast_light = OmniLight3D.new()
	_cast_light.position = Vector3(0.0, -0.15, -0.5)
	_cast_light.omni_range = 3.0
	_cast_light.light_energy = 0.0
	add_child(_cast_light)
	_apply_viewmodel_materials(self)


func _build_arm(hand: Node3D, sleeve: Material, side: float) -> void:
	var skin: Material = Look.metal(Color("6a7280"), 0.45) if class_id == &"warrior" else Look.matte(_skin_tint, 0.7)
	var wrist := Vector3(side * 0.03, -0.035, 0.09)
	var elbow := Vector3(side * 0.24, -0.34, 0.68)
	_add_segment(hand, wrist, elbow, 0.05, 0.085, sleeve)
	var palm := MeshInstance3D.new()
	palm.mesh = MeshKit.sphere(0.052, 10)
	palm.material_override = skin
	palm.scale = Vector3(1.05, 0.85, 1.2)
	hand.add_child(palm)
	# Dedos fechados em torno da empunhadura.
	for finger in 4:
		var knuckle := MeshInstance3D.new()
		knuckle.mesh = MeshKit.sphere(0.0185, 6)
		knuckle.material_override = skin
		knuckle.scale = Vector3(1.0, 1.0, 1.5)
		knuckle.position = Vector3((float(finger) - 1.5) * 0.024, 0.02, -0.046)
		hand.add_child(knuckle)
	if class_id == &"warrior":
		_add_segment(hand, wrist * 0.95, wrist + (elbow - wrist).normalized() * 0.1, 0.066, 0.072, Look.metal(Color("b98f45"), 0.4))


## Cilindro entre dois pontos, orientado de `from` para `to`.
func _add_segment(parent: Node3D, from: Vector3, to: Vector3, radius_from: float, radius_to: float, material: Material) -> void:
	var segment := MeshInstance3D.new()
	var length: float = from.distance_to(to)
	segment.mesh = MeshKit.cylinder(radius_to, radius_from, length, 10)
	segment.material_override = material
	var up: Vector3 = (to - from).normalized()
	var side_axis: Vector3 = up.cross(Vector3.FORWARD).normalized()
	segment.basis = Basis(side_axis, up, side_axis.cross(up).normalized())
	segment.position = (from + to) * 0.5
	parent.add_child(segment)


func _build_barrier(color: Color) -> MeshInstance3D:
	var barrier := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 1.2
	mesh.is_hemisphere = false
	barrier.mesh = mesh
	barrier.scale = Vector3(1.0, 1.0, 0.25)
	barrier.position = Vector3(0.0, -0.05, -0.6)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color.r, color.g, color.b, 0.22)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	barrier.material_override = material
	barrier.visible = false
	return barrier


func _apply_viewmodel_materials(node: Node) -> void:
	for child in node.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.material_override = Look.for_viewmodel(mesh.material_override)
		_apply_viewmodel_materials(child)


func notify_look(relative: Vector2) -> void:
	_sway += relative * 0.00035
	_sway = _sway.clamp(Vector2.ONE * -SWAY_LIMIT, Vector2.ONE * SWAY_LIMIT)


func update_motion(delta: float, ground_speed: float, bob_phase: float, on_floor: bool) -> void:
	if _right == null:
		return
	_sway = _sway.lerp(Vector2.ZERO, minf(delta * 9.0, 1.0))
	var strength: float = clampf(ground_speed / 6.0, 0.0, 1.0) * (1.0 if on_floor else 0.3)
	var bob := Vector3(cos(bob_phase * 0.5) * 0.011, sin(bob_phase) * 0.009 * 1.5, 0.0) * strength
	var sway := Vector3(-_sway.x, _sway.y, 0.0)
	_right.position = RIGHT_REST + bob + sway + right_position
	_right.rotation = _right_rest_rotation + right_rotation
	_left.position = LEFT_REST + bob * 0.8 + sway + left_position
	_left.rotation = _left_rest_rotation + left_rotation


func _begin_action() -> Tween:
	if _action_tween != null and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	return _action_tween


func _reset_pose(tween: Tween, seconds: float) -> void:
	tween.tween_property(self, "right_position", Vector3.ZERO, seconds).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "right_rotation", Vector3.ZERO, seconds).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "left_position", Vector3.ZERO, seconds).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "left_rotation", Vector3.ZERO, seconds).set_ease(Tween.EASE_IN_OUT)


func play_swing(index: int) -> void:
	# Direções alternadas: direita-esquerda, esquerda-direita e diagonal.
	var starts: Array[Vector3] = [Vector3(0.9, 0.9, 0.5), Vector3(0.75, -1.0, -0.5), Vector3(1.4, 0.3, 0.2)]
	var ends: Array[Vector3] = [Vector3(-0.95, -1.05, -0.6), Vector3(-0.8, 1.0, 0.7), Vector3(-1.2, -0.3, -0.2)]
	var moves: Array[Vector3] = [Vector3(0.08, 0.14, 0.05), Vector3(-0.2, 0.12, 0.05), Vector3(0.0, 0.2, 0.1)]
	var tween := _begin_action()
	right_rotation = starts[index]
	right_position = moves[index]
	tween.tween_property(self, "right_rotation", ends[index], 0.13).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "right_position", Vector3(-moves[index].x, -0.05, -0.2), 0.13).set_ease(Tween.EASE_OUT)
	_reset_pose(tween, 0.22)


func play_overhead() -> void:
	var tween := _begin_action()
	tween.tween_property(self, "right_rotation", Vector3(1.7, 0.0, 0.0), 0.1).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "right_position", Vector3(-0.08, 0.32, 0.12), 0.1)
	tween.tween_property(self, "right_rotation", Vector3(-1.3, 0.0, 0.0), 0.12).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "right_position", Vector3(-0.12, -0.2, -0.26), 0.12)
	_reset_pose(tween, 0.32)


func play_thrust() -> void:
	var tween := _begin_action()
	tween.tween_property(self, "right_rotation", Vector3(-1.2, 0.0, 0.0), 0.08)
	tween.parallel().tween_property(self, "right_position", Vector3(-0.14, 0.06, -0.34), 0.1).set_ease(Tween.EASE_OUT)
	_reset_pose(tween, 0.3)


func play_spin() -> void:
	var tween := _begin_action()
	tween.tween_property(self, "right_rotation", Vector3(0.8, 2.2, 0.0), 0.08)
	tween.tween_property(self, "right_rotation", Vector3(0.8, -2.2, 0.0), 0.2).set_ease(Tween.EASE_OUT)
	_reset_pose(tween, 0.22)


func play_shout() -> void:
	var tween := _begin_action()
	tween.tween_property(self, "right_position", Vector3(0.1, -0.25, 0.1), 0.12)
	tween.parallel().tween_property(self, "left_position", Vector3(-0.1, -0.25, 0.1), 0.12)
	_reset_pose(tween, 0.34)


func play_dodge() -> void:
	var tween := _begin_action()
	tween.tween_property(self, "right_position", Vector3(0.05, -0.12, 0.08), 0.1)
	tween.parallel().tween_property(self, "left_position", Vector3(-0.05, -0.12, 0.08), 0.1)
	_reset_pose(tween, 0.2)


func start_cast(skill: SkillData, duration: float) -> void:
	var tween := _begin_action()
	tween.tween_property(self, "right_position", Vector3(-0.12, 0.08, -0.08), duration * 0.5)
	tween.parallel().tween_property(self, "left_position", Vector3(0.14, 0.14, -0.1), duration * 0.5)
	tween.parallel().tween_property(self, "right_rotation", Vector3(-0.2, 0.2, 0.0), duration * 0.5)
	_set_cast_glow(skill.color, duration)


func stop_cast() -> void:
	_fade_cast_glow()
	_reset_pose(_begin_action(), 0.2)


func play_release() -> void:
	_fade_cast_glow()
	var tween := _begin_action()
	tween.tween_property(self, "right_position", Vector3(-0.14, 0.1, -0.28), 0.07).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "left_position", Vector3(0.14, 0.1, -0.24), 0.07).set_ease(Tween.EASE_OUT)
	_reset_pose(tween, 0.26)


func play_skill(skill: SkillData, swing_index: int) -> void:
	match skill.animation:
		&"swing":
			play_swing(swing_index)
		&"overhead":
			play_overhead()
		&"thrust":
			play_thrust()
		&"spin":
			play_spin()
		&"shout":
			play_shout()
		_:
			play_release()


func set_guard(active: bool) -> void:
	if _right == null:
		return
	if class_id == &"warrior":
		var tween := _begin_action()
		tween.set_parallel(true)
		tween.tween_property(self, "left_position", Vector3(0.3, 0.2, -0.05) if active else Vector3.ZERO, 0.12)
		tween.tween_property(self, "left_rotation", Vector3(0.1, -0.4, 0.0) if active else Vector3.ZERO, 0.12)
		tween.tween_property(self, "right_position", Vector3(-0.1, 0.04, 0.05) if active else Vector3.ZERO, 0.12)
	else:
		_guard_shield.visible = active


func _set_cast_glow(color: Color, duration: float) -> void:
	_cast_light.light_color = color
	_tween_glow(0.9, duration)


func _fade_cast_glow() -> void:
	_tween_glow(0.0, 0.18)


## Só um tween por vez: senão a subida de um cast interrompido venceria o apagar da luz.
func _tween_glow(energy: float, seconds: float) -> void:
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_property(_cast_light, "light_energy", energy, seconds)
