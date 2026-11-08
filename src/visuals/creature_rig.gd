class_name CreatureRig
extends Node3D
## Modelo articulado procedural. A animação é calculada por código (locomoção + ação),
## pois não há esqueletos importados neste MVP.

enum Gait { BIPED, QUADRUPED, HOVER }
enum ActionPhase { NONE, WINDUP, STRIKE, RECOVER }

const FLASH_INTERVAL := 0.3
const KNEE_LEAD := 0.4
const KNEE_BASE := 0.15

## Duração do golpe e da volta, por criatura. O chefe muda os dois para ganhar peso.
var strike_time: float = 0.16
var recover_time: float = 0.32
var gait: Gait = Gait.BIPED
var stride: float = 0.75
var step_rate: float = 2.3
var knee_bend: float = 0.85
var arm_swing_r: float = 0.7
var arm_swing_l: float = 0.7

var _joints: Dictionary[StringName, Node3D] = {}
var _rest: Dictionary[StringName, Vector3] = {}
var _strike_wrist: Vector3 = Vector3.ZERO
var _strike_clears_rest: bool = false
var _meshes: Array[MeshInstance3D] = []
var _phase: float = 0.0
var _blend: float = 0.0
var _action: StringName = &""
var _action_phase: ActionPhase = ActionPhase.NONE
var _action_time: float = 0.0
var _windup_time: float = 0.3
var _breath: float = 0.0
var _flash_time: float = 0.0
var _flash_cooldown: float = 0.0
var _dead: bool = false
var _overlay: StandardMaterial3D
var _death_tween: Tween
var _rest_height: float = 0.0
var _floaters: Array[Dictionary] = []
var _float_time: float = 0.0


func joint(joint_name: StringName, parent: Node3D, position_offset: Vector3, rest_rotation := Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = String(joint_name)
	node.position = position_offset
	node.rotation = rest_rotation
	(parent if parent != null else self).add_child(node)
	_joints[joint_name] = node
	_rest[joint_name] = rest_rotation
	return node


func part(parent: Node3D, mesh: Mesh, material: Material, offset := Vector3.ZERO, rotation_offset := Vector3.ZERO, scale_factor := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	instance.rotation = rotation_offset
	instance.scale = scale_factor
	parent.add_child(instance)
	_meshes.append(instance)
	return instance


## Oscilação em y de um nó em torno da posição que ele tem agora. O tempo só avança em `animate`.
func add_float(node: Node3D, amplitude: float, frequency: float, phase: float) -> void:
	_floaters.append({"node": node, "base_y": node.position.y, "amplitude": amplitude, "frequency": frequency, "phase": phase})
	_apply_floats()


func _apply_floats() -> void:
	for floater in _floaters:
		var node: Node3D = floater["node"]
		if not is_instance_valid(node):
			continue
		node.position.y = floater["base_y"] + floater["amplitude"] * sin(TAU * floater["frequency"] * _float_time + floater["phase"])


func adopt_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
		adopt_meshes(child)


func has_joint(joint_name: StringName) -> bool:
	return _joints.has(joint_name)


func get_joint(joint_name: StringName) -> Node3D:
	return _joints.get(joint_name)


## Pose de repouso por classe: soma com as poses (regra J6).
func set_rest(joint_name: StringName, rest_rotation: Vector3) -> void:
	_rest[joint_name] = rest_rotation


## Só herói chama. Inimigo continua somando o repouso (J10).
func set_strike_grip(wrist: Vector3) -> void:
	_strike_clears_rest = true
	_strike_wrist = wrist


## Esqueleto bípede padrão com 1.8 m * height. Utilitário sem aparência, vale para herói e monstro (regra S4).
static func biped_skeleton(rig: CreatureRig, height: float, arm_scale: float, width: float) -> void:
	var s: float = height
	rig.set_pelvis_height(0.95 * s)
	var pelvis: Node3D = rig.joint(&"pelvis", null, Vector3(0.0, 0.95 * s, 0.0))
	var chest: Node3D = rig.joint(&"chest", pelvis, Vector3(0.0, 0.12 * s, 0.0))
	rig.joint(&"head", chest, Vector3(0.0, 0.58 * s, 0.0))
	var shoulder_r: Node3D = rig.joint(&"shoulder_r", chest, Vector3(0.26 * s * width, 0.46 * s, 0.0))
	var shoulder_l: Node3D = rig.joint(&"shoulder_l", chest, Vector3(-0.26 * s * width, 0.46 * s, 0.0))
	var elbow_r: Node3D = rig.joint(&"elbow_r", shoulder_r, Vector3(0.0, -0.32 * s * arm_scale, 0.0))
	var elbow_l: Node3D = rig.joint(&"elbow_l", shoulder_l, Vector3(0.0, -0.32 * s * arm_scale, 0.0))
	rig.joint(&"hand_r", elbow_r, Vector3(0.0, -0.3 * s * arm_scale, 0.0))
	rig.joint(&"hand_l", elbow_l, Vector3(0.0, -0.3 * s * arm_scale, 0.0))
	var hip_r: Node3D = rig.joint(&"hip_r", pelvis, Vector3(0.11 * s, -0.02 * s, 0.0))
	var hip_l: Node3D = rig.joint(&"hip_l", pelvis, Vector3(-0.11 * s, -0.02 * s, 0.0))
	rig.joint(&"knee_r", hip_r, Vector3(0.0, -0.46 * s, 0.0))
	rig.joint(&"knee_l", hip_l, Vector3(0.0, -0.46 * s, 0.0))


## Cilindro pendurado abaixo do joint `parent`.
static func limb(rig: CreatureRig, parent: StringName, length: float, top: float, bottom: float, material: Material) -> void:
	rig.part(rig.get_joint(parent), MeshKit.cylinder(top, bottom, length, 8), material, Vector3(0.0, -length * 0.5, 0.0))


func wind_up(action: StringName, duration: float) -> void:
	_action = action
	_windup_time = maxf(duration, 0.05)
	_action_time = 0.0
	_action_phase = ActionPhase.WINDUP


func strike(action: StringName = &"") -> void:
	if action != &"" and _action_phase == ActionPhase.NONE:
		_action = action
	_action_time = 0.0
	_action_phase = ActionPhase.STRIKE


func cancel_action() -> void:
	_action_phase = ActionPhase.NONE


## Clarão curto e com intervalo mínimo: sob vários atacantes o modelo continua visível.
func flash_hit() -> void:
	if _flash_cooldown > 0.0:
		return
	_flash_cooldown = FLASH_INTERVAL
	_flash_time = 0.09
	if _overlay == null:
		_overlay = StandardMaterial3D.new()
		_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_overlay.albedo_color = Color(1.0, 0.9, 0.85, 0.22)
	for mesh in _meshes:
		mesh.material_overlay = _overlay


func die() -> void:
	_dead = true
	cancel_action()
	_rest_height = position.y
	_death_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var side: float = 1.0 if randf() > 0.5 else -1.0
	_death_tween.tween_property(self, "rotation:x", side * PI * 0.48, 0.55)
	_death_tween.tween_property(self, "position:y", _rest_height + 0.2, 0.55)


func revive() -> void:
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_dead = false
	rotation = Vector3.ZERO
	position.y = _rest_height


func animate(delta: float, ground_speed: float) -> void:
	_tick_flash(delta)
	if _dead:
		return
	_blend = lerpf(_blend, clampf(ground_speed / 3.5, 0.0, 1.0), minf(delta * 8.0, 1.0))
	_phase += delta * step_rate * maxf(ground_speed, 1.5) * (1.0 if ground_speed > 0.2 else 0.0)
	_breath += delta * 1.8
	_float_time += delta
	_apply_floats()
	_tick_action(delta)
	match gait:
		Gait.BIPED:
			_pose_biped()
		Gait.QUADRUPED:
			_pose_quadruped()
		Gait.HOVER:
			_pose_hover()


func _tick_flash(delta: float) -> void:
	_flash_cooldown = maxf(_flash_cooldown - delta, 0.0)
	if _flash_time <= 0.0:
		return
	_flash_time -= delta
	if _flash_time <= 0.0:
		for mesh in _meshes:
			if is_instance_valid(mesh):
				mesh.material_overlay = null


func _tick_action(delta: float) -> void:
	if _action_phase == ActionPhase.NONE:
		return
	_action_time += delta
	match _action_phase:
		ActionPhase.WINDUP:
			if _action_time >= _windup_time:
				_action_time = _windup_time
		ActionPhase.STRIKE:
			if _action_time >= strike_time:
				_action_time = 0.0
				_action_phase = ActionPhase.RECOVER
		ActionPhase.RECOVER:
			if _action_time >= recover_time:
				_action_phase = ActionPhase.NONE


## -1 = totalmente armado, +1 = golpe no fim, 0 = repouso.
func _action_value() -> float:
	match _action_phase:
		ActionPhase.WINDUP:
			var t: float = clampf(_action_time / _windup_time, 0.0, 1.0)
			return -sqrt(t)
		ActionPhase.STRIKE:
			return lerpf(-1.0, 1.0, clampf(_action_time / strike_time, 0.0, 1.0))
		ActionPhase.RECOVER:
			return lerpf(1.0, 0.0, clampf(_action_time / recover_time, 0.0, 1.0))
	return 0.0


func _set_joint(joint_name: StringName, rotation_offset: Vector3) -> void:
	var node: Node3D = _joints.get(joint_name)
	if node != null:
		node.rotation = _rest[joint_name] + rotation_offset


## leg_phase = _phase na perna direita. A flexão chega antes da coxa passar pelo quadril.
func _knee_flex(leg_phase: float) -> float:
	return (KNEE_BASE + maxf(cos(leg_phase + KNEE_LEAD), 0.0) * knee_bend) * _blend


## A frente é -Z e os cálculos de ação assumem +Z: o sinal de X inverte ao aplicar (regra J6).
func _pose_biped() -> void:
	var swing: float = sin(_phase) * stride * _blend
	var lift: float = absf(cos(_phase)) * 0.05 * _blend
	var breath: float = sin(_breath) * 0.018
	_set_joint(&"hip_l", Vector3(-swing, 0.0, 0.0))
	_set_joint(&"hip_r", Vector3(swing, 0.0, 0.0))
	_set_joint(&"knee_l", Vector3(-_knee_flex(_phase + PI), 0.0, 0.0))
	_set_joint(&"knee_r", Vector3(-_knee_flex(_phase), 0.0, 0.0))
	# pano atrás: abre com a velocidade, as pernas nunca o atravessam
	_set_joint(&"cloth_back", Vector3(-(_blend * 0.55 + sin(_phase * 2.0) * 0.05 * _blend + sin(_breath) * 0.012), 0.0, 0.0))
	if has_joint(&"pelvis"):
		_joints[&"pelvis"].position.y = _pelvis_height + lift

	var value: float = _action_value()
	var arm_r := Vector3(swing * arm_swing_r + breath, 0.0, 0.0)
	var arm_l := Vector3(-swing * arm_swing_l - breath, 0.0, 0.0)
	var elbow_r := Vector3(-0.25, 0.0, 0.0)
	var elbow_l := Vector3(-0.25, 0.0, 0.0)
	var chest := Vector3(breath, sin(_phase) * 0.08 * _blend, 0.0)
	var neck := Vector3.ZERO
	match _action:
		&"swing":
			var armed: bool = value < 0.0
			var amount: float = absf(value)
			var weight: float = 1.0 if _action_phase == ActionPhase.STRIKE else amount
			var target := Vector3(-lerpf(0.75, 1.9 if armed else 0.5, amount), 0.0, lerpf(0.0, 0.55 if armed else -0.35, amount))
			arm_r = arm_r.lerp(target, weight)
			elbow_r = elbow_r.lerp(Vector3(-lerpf(0.15, 0.2, amount) if armed else -0.15, 0.0, 0.0), weight)
			chest.y += value * 0.55
		&"overhead":
			arm_r = arm_r.lerp(Vector3(-2.7 - value * 2.0 if value < 0.0 else -0.4 - value * 0.2, 0.0, 0.0), absf(value))
			arm_l = arm_l.lerp(Vector3(-2.6 if value < 0.0 else -0.5, 0.0, 0.0), absf(value))
			chest.x += value * 0.42
		&"thrust":
			arm_r = arm_r.lerp(Vector3(-1.4 - minf(value, 0.0) * 0.5, 0.0, 0.0), absf(value))
			chest.y += value * 0.3
		&"cast", &"cast_quick":
			arm_r = arm_r.lerp(Vector3(-1.5, 0.0, 0.25), absf(value))
			arm_l = arm_l.lerp(Vector3(-1.5, 0.0, -0.25), absf(value))
			chest.x += minf(value, 0.0) * -0.12
		&"shout":
			arm_r = arm_r.lerp(Vector3(-0.5, 0.0, 1.0), absf(value))
			arm_l = arm_l.lerp(Vector3(-0.5, 0.0, -1.0), absf(value))
			chest.x -= absf(value) * 0.3
			neck.x -= absf(value) * 0.3
		&"spin":
			chest.y += (value + 1.0) * PI
	if _action_phase == ActionPhase.NONE:
		_action = &""
	var strike_weight: float = 0.0
	if _action in [&"swing", &"overhead", &"thrust"]:
		strike_weight = 1.0 if _action_phase == ActionPhase.STRIKE else absf(value)
	var shoulder_offset := Vector3(-arm_r.x, arm_r.y, arm_r.z)
	var elbow_offset := Vector3(-elbow_r.x, elbow_r.y, elbow_r.z)
	if _strike_clears_rest:
		shoulder_offset.x -= _rest[&"shoulder_r"].x * strike_weight
		elbow_offset.x -= _rest[&"elbow_r"].x * strike_weight
		_set_joint(&"hand_r", _strike_wrist * strike_weight)
	_set_joint(&"shoulder_r", shoulder_offset)
	_set_joint(&"shoulder_l", Vector3(-arm_l.x, arm_l.y, arm_l.z))
	_set_joint(&"elbow_r", elbow_offset)
	_set_joint(&"elbow_l", Vector3(-elbow_l.x, elbow_l.y, elbow_l.z))
	_set_joint(&"chest", Vector3(-chest.x, chest.y, chest.z))
	_set_joint(&"head", Vector3(-neck.x, neck.y, neck.z))


var _pelvis_height: float = 1.0


func set_pelvis_height(height: float) -> void:
	_pelvis_height = height


func _pose_quadruped() -> void:
	var swing: float = sin(_phase) * stride * _blend
	var counter: float = sin(_phase + PI) * stride * _blend
	_set_joint(&"leg_fl", Vector3(swing, 0.0, 0.0))
	_set_joint(&"leg_br", Vector3(swing, 0.0, 0.0))
	_set_joint(&"leg_fr", Vector3(counter, 0.0, 0.0))
	_set_joint(&"leg_bl", Vector3(counter, 0.0, 0.0))
	var value: float = _action_value()
	var head_pitch: float = sin(_breath) * 0.04
	if _action == &"bite":
		head_pitch += value * 0.55
	if _action_phase == ActionPhase.NONE:
		_action = &""
	_set_joint(&"neck", Vector3(head_pitch, 0.0, 0.0))
	_set_joint(&"jaw", Vector3(maxf(-value, 0.0) * 0.7, 0.0, 0.0))
	_set_joint(&"tail", Vector3(sin(_breath * 1.4) * 0.2, sin(_phase) * 0.3 * _blend, 0.0))
	if has_joint(&"body"):
		_joints[&"body"].position.y = _pelvis_height + absf(cos(_phase)) * 0.06 * _blend + minf(value, 0.0) * 0.1


func _pose_hover() -> void:
	if has_joint(&"pelvis"):
		_joints[&"pelvis"].position.y = _pelvis_height + sin(_breath) * 0.08
	var value: float = _action_value()
	var arm := Vector3(-absf(value) * 1.3 + sin(_breath) * 0.05, 0.0, 0.0)
	if _action_phase == ActionPhase.NONE:
		_action = &""
	_set_joint(&"shoulder_r", arm)
	_set_joint(&"shoulder_l", arm)
