class_name Viewmodel
extends Node3D
## Mãos e arma em primeira pessoa. Animação por deslocamentos sobrepostos à pose de repouso.

const RIGHT_REST := Vector3(0.31, -0.2, -0.6)
const LEFT_REST := Vector3(-0.44, -0.29, -0.66)
const WEAPON_SCALE := 0.82
const SHIELD_SCALE := 0.62
## Luz do tomo com raio de 4,5 cm na tela: o núcleo do modelo tem 6 cm.
const TOME_LIGHT_SCALE := 0.75
const SWAY_LIMIT := 0.05
const WRIST := Vector3(0.018, -0.06, 0.075)
const ELBOW := Vector3(0.3, -0.26, 0.56)
const SKIN := Color("D9A981")
const MAGE_SLEEVE := Color("6E2470")
const MAGE_CUFF := Color("D5D9E4")
const MAGE_RING := Color("4F8DFF")
const PRIEST_BELL := Color("E6DCC0")
const FUR := Color("EEF1F6")
const SHIELD_INSIDE := Color("5A4632")
const SHIELD_STRAP_CENTER := Vector3(0.0, 0.0, 0.045)
const OPEN_HAND_ROTATION := Vector3(-0.95, 0.2, 0.45)
## Modelos em que a mão não fecha em volta de um cabo.
const OPEN_RIGHT_MODELS: Array[StringName] = [&"orb", &"tome"]
const OPEN_LEFT_MODELS: Array[StringName] = [&"staff", &"scepter", &"orb", &"tome"]

var class_id: StringName = &""
var _look: HeroLook
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

var right_position := Vector3.ZERO:
	set(value):
		right_position = value
var right_rotation := Vector3.ZERO
var left_position := Vector3.ZERO
var left_rotation := Vector3.ZERO


## Monta mãos, braços e arma. Retorna cedo se a aparência não mudou: `changed` da ficha dispara a cada XP e ponto.
func setup(class_data: ClassData, look: HeroLook) -> void:
	if look.equals(_look):
		return
	_look = look
	class_id = class_data.id
	_clear()
	_right = Node3D.new()
	_left = Node3D.new()
	add_child(_right)
	add_child(_left)

	var model: StringName = look.weapon_model
	var main_hand: Node3D = WeaponKit.build_main_hand(model, look.weapon_rarity, look.weapon_tier)
	main_hand.name = &"MainHand"
	main_hand.scale = Vector3.ONE * WEAPON_SCALE
	_right.add_child(main_hand)
	var off_hand: Node3D = WeaponKit.build_off_hand(model, look.weapon_rarity, look.weapon_tier)
	var left_grip_rotation := Vector3.ZERO
	match model:
		&"staff":
			main_hand.rotation = Vector3(-0.55, 0.0, 0.12)
			main_hand.position = Vector3(0.0, -0.3, 0.184)
			_right_rest_rotation = Vector3(0.12, 0.0, 0.0)
		&"scepter":
			main_hand.rotation = Vector3(-0.5, 0.0, 0.1)
			main_hand.position = Vector3(0.0, -0.25, 0.137)
			_right_rest_rotation = Vector3(0.12, 0.0, 0.0)
		&"orb":
			main_hand.position = Vector3(0.0, 0.14, -0.04)
			_right_rest_rotation = Vector3(0.12, 0.0, 0.0)
		&"tome":
			main_hand.scale = Vector3.ONE * TOME_LIGHT_SCALE
			main_hand.position = Vector3(0.0, 0.12, -0.04)
			_right_rest_rotation = Vector3(0.12, 0.0, 0.0)
			if off_hand != null:
				off_hand.scale = Vector3.ONE * SHIELD_SCALE
				off_hand.rotation = Vector3(-1.0, 0.0, 0.15)
				off_hand.position = Vector3(0.0, 0.1, -0.06)
		_:
			main_hand.rotation = Vector3(-0.42, 0.0, -0.16)
			main_hand.position = Vector3(0.0, -0.02, 0.0)
			_right_rest_rotation = Vector3(0.35, 0.05, 0.0)
			left_grip_rotation = main_hand.rotation
	if off_hand != null:
		_left.add_child(off_hand)
		if model == &"sword_shield":
			_mount_shield(off_hand)
			left_grip_rotation = off_hand.rotation

	var skin: Material = Look.hero(WeaponKit.STEEL, 0.42, 0.35) if class_data.id == &"warrior" else Look.hero(SKIN, 0.7)
	_build_arm(_right, 1.0, skin)
	# O machado é de uma mão: braço e mão esquerdos ficam ocultos e sem nós.
	var one_handed: bool = model == &"greataxe"
	_left.visible = not one_handed
	if not one_handed:
		_build_arm(_left, -1.0, skin)
	if OPEN_RIGHT_MODELS.has(model):
		_build_open_hand(_right, 1.0, skin)
	else:
		_build_closed_hand(_right, 1.0, skin, main_hand.rotation)
	if one_handed:
		pass
	elif OPEN_LEFT_MODELS.has(model):
		_build_open_hand(_left, -1.0, skin)
	else:
		_build_closed_hand(_left, -1.0, skin, left_grip_rotation)
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


## Interrompe o que ainda aponta para os nós antigos e tira os filhos da árvore na hora, para não contar duas vezes.
func _clear() -> void:
	for tween: Tween in [_action_tween, _glow_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	right_position = Vector3.ZERO
	right_rotation = Vector3.ZERO
	left_position = Vector3.ZERO
	left_rotation = Vector3.ZERO
	for child in get_children():
		remove_child(child)
		child.queue_free()


## Escudo com a face de dentro para o jogador: a abóbada de `WeaponKit._shield` fica para fora.
func _mount_shield(shield: Node3D) -> void:
	shield.scale = Vector3.ONE * SHIELD_SCALE
	shield.rotation = Vector3(-0.15, 0.55, 0.1)
	var inside := _part(shield, MeshKit.cylinder(0.35, 0.35, 0.008, 24), Look.hero(SHIELD_INSIDE, 0.8))
	inside.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	inside.position = Vector3(0.0, 0.0, 0.025)
	# Alça na vertical, no eixo dos dedos: os anéis da mão fechada passam em volta dela.
	var strap := _part(shield, MeshKit.box(Vector3(0.3, 0.05, 0.03)), Look.hero(WeaponKit.LEATHER, 0.8))
	strap.rotation = Vector3(0.0, 0.0, PI * 0.5)
	strap.position = SHIELD_STRAP_CENTER
	# A alça passa pela origem da mão.
	shield.position = -(shield.basis * SHIELD_STRAP_CENTER)


func _part(parent: Node3D, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _build_arm(hand: Node3D, side: float, skin: Material) -> void:
	var wrist := Vector3(side * WRIST.x, WRIST.y, WRIST.z)
	var elbow := Vector3(side * ELBOW.x, ELBOW.y, ELBOW.z)
	var length: float = wrist.distance_to(elbow)
	var along: Vector3 = (elbow - wrist) / length
	var metal: Material = Look.trim(_look.armor_tier)
	match class_id:
		&"warrior":
			_add_segment(hand, wrist, elbow, 0.058, 0.09, skin)
			_add_band(hand, wrist, along, 0.0, 0.05, 0.066, 0.07, metal)
			_add_band(hand, wrist, along, 0.24, 0.27, 0.082, 0.084, metal)
		&"mage":
			_add_segment(hand, wrist, elbow, 0.058, 0.09, Look.hero(MAGE_SLEEVE, 0.8))
			_add_band(hand, wrist, along, 0.0, 0.03, 0.07, 0.07, Look.hero(MAGE_CUFF, 0.45, 0.3))
			_add_band(hand, wrist, along, 0.04, 0.065, 0.066, 0.066, Look.glow(MAGE_RING, 0.9))
		_:
			var bell: Material = Look.hero(PRIEST_BELL, 0.8)
			_add_segment(hand, wrist, elbow, 0.058, 0.09, bell)
			_add_band(hand, wrist, along, -0.015, 0.2, 0.105, 0.085, bell)
			_add_band(hand, wrist, along, -0.02, 0.02, 0.108, 0.108, metal)
	if _look.armor_tier >= 1:
		var fur: Material = Look.hero(FUR, 0.9)
		if class_id == &"warrior" or class_id == &"mage":
			_add_band(hand, wrist, along, 0.0, 0.03, 0.09, 0.09, fur)
		else:
			# O sino do sacerdote chega a .1 no pulso e engoliria o punho: ele fica logo acima do metal.
			_add_band(hand, wrist, along, 0.02, 0.05, 0.115, 0.115, fur)


## Trecho do antebraço entre duas distâncias do pulso, medidas ao longo de `along`. O raio vai do pulso ao cotovelo.
func _add_band(hand: Node3D, wrist: Vector3, along: Vector3, from: float, to: float, radius_from: float, radius_to: float, material: Material) -> void:
	_add_segment(hand, wrist + along * from, wrist + along * to, radius_from, radius_to, material)


## Dedos em anéis de `torus` em volta do cabo, com a mesma rotação da arma.
func _build_closed_hand(hand: Node3D, side: float, skin: Material, grip_rotation: Vector3) -> void:
	var grip := Node3D.new()
	grip.rotation = grip_rotation
	hand.add_child(grip)
	for finger in 4:
		var radius: float = 0.052 if finger == 1 or finger == 2 else 0.05
		var ring := _part(grip, MeshKit.torus(0.02, radius, 10), skin)
		ring.position = Vector3(0.0, (float(finger) - 1.5) * 0.031, 0.0)
		ring.scale = Vector3(1.0, 1.0, 1.1)
	var palm_rings: Array[Vector4] = [Vector4(0.0, -0.06, 0.03, 0.022), Vector4(0.0, 0.0, 0.05, 0.026), Vector4(0.0, 0.06, 0.03, 0.02)]
	_part(grip, MeshKit.loft(palm_rings, 8), skin).position = Vector3(side * 0.012, 0.0, 0.042)
	var thumb := _part(grip, MeshKit.cylinder(0.014, 0.019, 0.085, 8), skin)
	thumb.position = Vector3(side * -0.022, 0.05, -0.03)
	thumb.rotation = Vector3(1.1, 0.0, side * 0.9)


## Palma para cima, para a mão esquerda de mago e sacerdote e para a direita com orbe ou tomo.
func _build_open_hand(hand: Node3D, side: float, skin: Material) -> void:
	var open := Node3D.new()
	# A rotação da ficha é da mão esquerda (lado -1); a direita espelha.
	open.rotation = Vector3(OPEN_HAND_ROTATION.x, -side * OPEN_HAND_ROTATION.y, -side * OPEN_HAND_ROTATION.z)
	hand.add_child(open)
	var palm_rings: Array[Vector4] = [Vector4(0.0, -0.05, 0.032, 0.022), Vector4(0.0, 0.0, 0.052, 0.024), Vector4(0.0, 0.045, 0.046, 0.018)]
	_part(open, MeshKit.loft(palm_rings, 8), skin)
	for finger in 4:
		var x: float = (float(finger) - 1.5) * 0.027
		var digit := _part(open, MeshKit.cylinder(0.0095, 0.012, 0.08, 8), skin)
		digit.position = Vector3(x, 0.08 - absf(float(finger) - 1.3) * 0.008, 0.0)
		digit.rotation = Vector3(0.0, 0.0, -x * 1.2)
	var thumb := _part(open, MeshKit.cylinder(0.011, 0.014, 0.07, 8), skin)
	thumb.position = Vector3(side * 0.06, 0.0, -0.01)
	thumb.rotation = Vector3(0.2, 0.0, -side)


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
	barrier.material_override = Look.barrier(color)
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
