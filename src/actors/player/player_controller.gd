class_name PlayerController
extends CharacterBody3D
## Movimento e câmera em primeira pessoa. Combate fica em PlayerCombat.

signal dodged

const ACCELERATION := 60.0
const AIR_ACCELERATION := 14.0
const PITCH_LIMIT := 1.45
const BASE_FOV := 78.0
const SPRINT_FOV := 86.0
const BOB_FREQUENCY := 2.1
const BOB_AMPLITUDE := 0.045
const MOVE_PENALTY_WHILE_ACTING := 0.55

var mouse_sensitivity: float = 0.0024
var input_enabled: bool = true
var combatant_ready: bool = false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var combatant: Combatant = $Combatant
@onready var caster: SkillCaster = $SkillCaster
@onready var viewmodel: Viewmodel = $Head/Camera3D/Viewmodel

var _balance: BalanceConfig
var _pitch: float = 0.0
var _dodge_left: float = 0.0
var _dodge_cooldown: float = 0.0
var _dodge_direction := Vector3.ZERO
var _bob_phase: float = 0.0
var _trauma: float = 0.0
var _noise := FastNoiseLite.new()
var _time: float = 0.0
var _is_guarding: bool = false
var _head_base_height: float = 1.62


func setup_character(sheet: CharacterSheet, display_name: String) -> void:
	_balance = sheet.balance
	combatant.setup(display_name, sheet.level, Combatant.Team.PARTY, sheet.derived_stats(), sheet.balance)
	combatant.body_radius = 0.4
	combatant.body_height = 1.8
	caster.combatant = combatant
	combatant_ready = true
	var weapon: ItemData = sheet.equipment.get(ItemData.Kind.WEAPON)
	viewmodel.setup(sheet.class_data, weapon)


func _ready() -> void:
	_noise.frequency = 1.6
	camera.fov = BASE_FOV
	camera.near = 0.06
	camera.far = 160.0


## Usa _input: com o cursor capturado, nenhum painel do HUD pode consumir o movimento do mouse.
func _input(event: InputEvent) -> void:
	if not input_enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		look_by(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)
		viewmodel.notify_look(motion.relative)


func look_by(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	_pitch = clampf(_pitch + pitch, -PITCH_LIMIT, PITCH_LIMIT)
	head.rotation.x = _pitch


## Aponta a câmera para um ponto (usado por respawn e pelos testes automatizados).
func look_at_point(point: Vector3) -> void:
	var offset: Vector3 = point - camera.global_position
	rotation.y = atan2(-offset.x, -offset.z)
	_pitch = clampf(atan2(offset.y, Vector2(offset.x, offset.z).length()), -PITCH_LIMIT, PITCH_LIMIT)
	head.rotation.x = _pitch


func aim_direction() -> Vector3:
	return -camera.global_basis.z


func set_guarding(active: bool) -> void:
	_is_guarding = active


func can_act() -> bool:
	return input_enabled and combatant.is_alive() and not combatant.is_stunned()


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if not combatant_ready:
		return
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	var on_floor: bool = is_on_floor()
	if not on_floor:
		velocity.y -= _balance.gravity * delta

	if combatant.is_forced_moving():
		velocity = Vector3.ZERO
		return

	var wish := Vector3.ZERO
	if can_act():
		var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		wish = global_basis * Vector3(input.x, 0.0, input.y)
		if Input.is_action_just_pressed(&"dodge"):
			_try_dodge(wish)
		if Input.is_action_just_pressed(&"jump") and on_floor:
			velocity.y = _balance.jump_velocity

	if _dodge_left > 0.0:
		_dodge_left -= delta
		var speed: float = _balance.dodge_distance / _balance.dodge_duration
		velocity.x = _dodge_direction.x * speed
		velocity.z = _dodge_direction.z * speed
	else:
		var target: Vector3 = wish * _current_speed()
		var rate: float = ACCELERATION if on_floor else AIR_ACCELERATION
		var flat := Vector2(velocity.x, velocity.z).move_toward(Vector2(target.x, target.z), rate * delta)
		velocity.x = flat.x
		velocity.z = flat.y
	move_and_slide()


func _current_speed() -> float:
	var speed: float = combatant.stats.move_speed
	if _is_guarding or caster.is_casting():
		return speed * MOVE_PENALTY_WHILE_ACTING
	if Input.is_action_pressed(&"sprint"):
		return speed * _balance.sprint_multiplier
	return speed


func _try_dodge(wish: Vector3) -> void:
	if _dodge_cooldown > 0.0:
		return
	_dodge_direction = wish.normalized() if wish.length_squared() > 0.01 else -global_basis.z
	_dodge_left = _balance.dodge_duration
	_dodge_cooldown = _balance.dodge_cooldown
	combatant.grant_invulnerability(_balance.dodge_duration + 0.08)
	viewmodel.play_dodge()
	dodged.emit()


func dodge_cooldown_ratio() -> float:
	return _dodge_cooldown / maxf(_balance.dodge_cooldown, 0.01) if _balance != null else 0.0


func _process(delta: float) -> void:
	_time += delta
	var ground_speed: float = Vector2(velocity.x, velocity.z).length()
	var moving: bool = ground_speed > 0.5 and is_on_floor()
	if moving:
		_bob_phase += delta * ground_speed * BOB_FREQUENCY
	var bob: float = sin(_bob_phase) * BOB_AMPLITUDE * (1.0 if moving else 0.0)
	var height: float = _head_base_height if combatant.is_alive() else 0.35
	head.position.y = lerpf(head.position.y, height + bob, minf(delta * 12.0, 1.0))
	head.position.x = lerpf(head.position.x, cos(_bob_phase * 0.5) * BOB_AMPLITUDE * 0.6 * (1.0 if moving else 0.0), minf(delta * 12.0, 1.0))

	var sprinting: bool = ground_speed > combatant.stats.move_speed * 1.1 if combatant_ready else false
	camera.fov = lerpf(camera.fov, SPRINT_FOV if sprinting else BASE_FOV, minf(delta * 7.0, 1.0))

	_trauma = maxf(_trauma - delta * 1.9, 0.0)
	var shake: float = _trauma * _trauma
	camera.rotation = Vector3(
		_noise.get_noise_2d(_time * 18.0, 0.0) * 0.05 * shake,
		_noise.get_noise_2d(_time * 18.0, 40.0) * 0.05 * shake,
		_noise.get_noise_2d(_time * 18.0, 80.0) * 0.08 * shake)
	viewmodel.update_motion(delta, ground_speed, _bob_phase, is_on_floor())


func teleport_to(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO
