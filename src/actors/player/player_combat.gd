class_name PlayerCombat
extends Node
## Traduz entrada em ações de combate: ataque, habilidades, poções, alvo e interação.

signal target_changed(target: Combatant)
signal hovered_changed(target: Combatant)
signal interact_prompt_changed(text: String)
signal skill_refused(reason: String)
signal potion_used(item: ItemData, cooldown: float)
signal menu_requested(action: StringName)

const AIM_MASK := 8 | 4
const AIM_DISTANCE := 44.0
const ASSIST_DEGREES := 12.0
const TARGET_RANGE := 40.0
const INTERACT_SCAN_INTERVAL := 0.12
const INTERACT_DEFAULT_RADIUS := 4.0
const REFUSAL_NAMES: Dictionary = {
	SkillCaster.Refusal.NO_MANA: "Mana insuficiente",
	SkillCaster.Refusal.NO_CHI: "Chi insuficiente",
	SkillCaster.Refusal.COOLDOWN: "Habilidade em recarga",
}

var sheet: CharacterSheet
var target: Combatant
var hovered: Combatant
var interactable: Node
var party: Array[Combatant] = []

@onready var player: PlayerController = get_parent()

var _guarding: bool = false
var _guard_exhausted: bool = false
var _swing_index: int = 0
var _potion_cooldown: float = 0.0
var _potion_total: float = 15.0
var _interact_scan: float = 0.0


func setup(character: CharacterSheet) -> void:
	sheet = character
	_potion_total = character.balance.potion_cooldown
	player.caster.aim_provider = build_aim
	player.caster.cast_started.connect(_on_cast_started)
	player.caster.skill_fired.connect(_on_skill_fired)
	player.caster.cast_interrupted.connect(func(_skill: SkillData) -> void: player.viewmodel.stop_cast())


func hotbar() -> Array[SkillData]:
	var result: Array[SkillData] = sheet.class_data.skills.duplicate()
	result.append(sheet.class_data.ultimate)
	return result


func potion_cooldown_ratio() -> float:
	return _potion_cooldown / maxf(_potion_total, 0.01)


func _process(delta: float) -> void:
	if sheet == null:
		return
	_potion_cooldown = maxf(_potion_cooldown - delta, 0.0)
	_update_hover()
	_update_interaction(delta)
	if target != null and (not is_instance_valid(target) or not target.is_alive()):
		target = null
		target_changed.emit(null)
	if not player.can_act():
		_set_guard(false)
		return
	_set_guard(Input.is_action_pressed(&"guard"))
	if Input.is_action_pressed(&"attack"):
		use_skill(sheet.class_data.basic_attack, true)
	var hotkeys: Array[StringName] = [&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_ult"]
	var skills: Array[SkillData] = hotbar()
	for i in hotkeys.size():
		if Input.is_action_just_pressed(hotkeys[i]):
			use_skill(skills[i])
	if Input.is_action_just_pressed(&"potion_hp"):
		use_potion(&"potion_hp")
	if Input.is_action_just_pressed(&"potion_mp"):
		use_potion(&"potion_mp")
	if Input.is_action_just_pressed(&"interact"):
		_interact()
	if Input.is_action_just_pressed(&"target_next"):
		cycle_target()
	if Input.is_action_just_pressed(&"target_clear"):
		set_target(null)
	for i in 4:
		if Input.is_action_just_pressed(StringName("party_%d" % (i + 1))) and i < party.size():
			set_target(party[i])


func use_skill(skill: SkillData, silent: bool = false) -> bool:
	if _guarding:
		return false
	var refusal: SkillCaster.Refusal = player.caster.refusal(skill)
	if refusal != SkillCaster.Refusal.NONE:
		if not silent and REFUSAL_NAMES.has(refusal):
			skill_refused.emit(REFUSAL_NAMES[refusal])
		return false
	return player.caster.try_cast(skill, build_aim(skill))


## Mira da câmera, com assistência suave para o alvo selecionado (herança do tab-target do PW).
func build_aim(skill: SkillData) -> SkillAim:
	var aim := SkillAim.new()
	var camera: Camera3D = player.camera
	var forward: Vector3 = player.aim_direction()
	aim.origin = camera.global_position + forward * 0.7 + camera.global_basis.y * -0.15
	aim.direction = forward
	var hostile: Combatant = _assisted_target(forward)
	aim.target = hostile
	if hostile != null and skill.delivery == SkillData.Delivery.PROJECTILE:
		aim.direction = (hostile.center_position() - aim.origin).normalized()
	aim.ground_point = _ground_point(forward, skill.skill_range)
	if skill.delivery == SkillData.Delivery.TARGET_ALLY:
		aim.target = _ally_target(skill)
	return aim


func _assisted_target(forward: Vector3) -> Combatant:
	var candidate: Combatant = null
	if is_instance_valid(target) and target.team != player.combatant.team and target.is_alive():
		candidate = target
	elif is_instance_valid(hovered) and hovered.team != player.combatant.team:
		candidate = hovered
	if candidate == null:
		return null
	var offset: Vector3 = candidate.center_position() - player.camera.global_position
	if offset.length() > TARGET_RANGE or forward.angle_to(offset.normalized()) > deg_to_rad(ASSIST_DEGREES * 2.0):
		return null
	return candidate


func _ally_target(skill: SkillData) -> Combatant:
	if is_instance_valid(target) and target.team == player.combatant.team and target.is_alive():
		return target
	if is_instance_valid(hovered) and hovered.team == player.combatant.team:
		return hovered
	return CombatWorld.most_hurt_ally(player.combatant, skill.skill_range)


func _ground_point(forward: Vector3, reach: float) -> Vector3:
	var from: Vector3 = player.camera.global_position
	var to: Vector3 = from + forward * maxf(reach, 1.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, CombatWorld.WORLD_MASK)
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		var down := PhysicsRayQueryParameters3D.create(to, to + Vector3.DOWN * 30.0, CombatWorld.WORLD_MASK)
		var floor_hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(down)
		return floor_hit.position if not floor_hit.is_empty() else to
	var point: Vector3 = hit.position
	if hit.normal.y < 0.5:
		point -= forward * 0.6
	return point


func _update_hover() -> void:
	var from: Vector3 = player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + player.aim_direction() * AIM_DISTANCE, AIM_MASK | CombatWorld.WORLD_MASK)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	var found: Combatant = null
	if not hit.is_empty():
		var unit: Variant = hit.collider.get("combatant")
		if unit is Combatant and unit.is_alive():
			found = unit
	if found != hovered:
		hovered = found
		hovered_changed.emit(hovered)


func set_target(unit: Combatant) -> void:
	if unit == target:
		return
	target = unit
	target_changed.emit(target)


## Tab: próximo inimigo mais à frente da mira.
func cycle_target() -> void:
	var candidates: Array[Combatant] = []
	var origin: Vector3 = player.global_position
	var forward: Vector3 = player.aim_direction()
	for hostile in CombatWorld.hostiles_of(player.combatant):
		var offset: Vector3 = hostile.world_position() - origin
		if offset.length() <= TARGET_RANGE and forward.dot(offset.normalized()) > 0.1:
			candidates.append(hostile)
	if candidates.is_empty():
		set_target(null)
		return
	candidates.sort_custom(func(a: Combatant, b: Combatant) -> bool:
		var angle_a: float = forward.angle_to((a.world_position() - origin).normalized())
		var angle_b: float = forward.angle_to((b.world_position() - origin).normalized())
		return angle_a < angle_b)
	var index: int = candidates.find(target)
	set_target(candidates[(index + 1) % candidates.size()])


func use_potion(item_id: StringName) -> bool:
	if _potion_cooldown > 0.0 or not sheet.inventory.remove(item_id):
		return false
	var item: ItemData = GameDB.item(item_id)
	var unit: Combatant = player.combatant
	unit.receive_heal(unit.stats.max_hp * item.restores_hp_ratio, unit)
	unit.restore_mana(unit.stats.max_mp * item.restores_mp_ratio)
	_potion_cooldown = _potion_total
	potion_used.emit(item, _potion_total)
	return true


func _set_guard(active: bool) -> void:
	var class_data: ClassData = sheet.class_data
	var unit: Combatant = player.combatant
	var drain: float = class_data.guard_mp_per_second * get_process_delta_time()
	# A regeneração nunca deixa a mana em zero exato: compara com o custo do quadro.
	# Exausta, a defesa só volta depois de soltar o botão, para não piscar.
	if not active:
		_guard_exhausted = false
	elif drain > 0.0 and (_guard_exhausted or unit.mp < drain):
		_guard_exhausted = true
		active = false
	if active and drain > 0.0:
		unit.spend_mana(drain)
	if active == _guarding:
		return
	_guarding = active
	unit.guard_multiplier = class_data.guard_damage_multiplier if active else 1.0
	player.set_guarding(active)
	player.viewmodel.set_guard(active)
	if active:
		player.caster.interrupt()


func is_guarding() -> bool:
	return _guarding


func _update_interaction(delta: float) -> void:
	_interact_scan -= delta
	if _interact_scan > 0.0:
		return
	_interact_scan = INTERACT_SCAN_INTERVAL
	var best: Node = null
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var spot := node as Node3D
		var radius: float = spot.get("interact_radius") if spot.get("interact_radius") != null else INTERACT_DEFAULT_RADIUS
		var distance: float = spot.global_position.distance_to(player.global_position)
		if distance <= radius and distance < best_distance:
			best = spot
			best_distance = distance
	if best != interactable:
		interactable = best
		interact_prompt_changed.emit(interactable.interact_label() if interactable != null else "")


func _interact() -> void:
	if is_instance_valid(interactable):
		interactable.interact(player)


func _on_cast_started(skill: SkillData, duration: float) -> void:
	player.viewmodel.start_cast(skill, duration)


func _on_skill_fired(skill: SkillData, aim: SkillAim) -> void:
	_swing_index = (_swing_index + 1) % 3
	player.viewmodel.play_skill(skill, _swing_index)
	if skill.delivery == SkillData.Delivery.MELEE_CONE:
		Vfx.melee_arc(get_tree(), player, aim.direction, minf(skill.skill_range * 0.72, 3.6), skill.color, _swing_index % 2 == 0)
