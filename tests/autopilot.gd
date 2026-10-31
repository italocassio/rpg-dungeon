class_name Autopilot
extends Node
## Joga uma partida completa usando as mesmas ações de entrada do jogador humano.

signal finished(report: Dictionary)

const ENGAGE_DISTANCE := 17.0
const FIND_LOOT_RADIUS := 13.0
const WAYPOINT_RADIUS := 4.0
const STUCK_SECONDS := 6.0
const STALL_SECONDS := 30.0

var run: DungeonRun
var player: PlayerController
var combat: PlayerCombat
var nav: NavFollower
var route: Array[Vector2] = []
var route_index: int = 0
var elapsed: float = 0.0
var deaths: int = 0
var boss_fight_start: float = -1.0
var boss_fight_seconds: float = 0.0
var player_damage_taken: float = 0.0
var max_kills_seen: int = 0
var time_limit: float = 1500.0
var phases_seen: int = 0
var trace_enabled: bool = false
## Falso simula um jogador que ignora as áreas de perigo do chefe.
var avoid_mechanics: bool = true
var _trace_timer: float = 0.0

var _held: Dictionary[StringName, bool] = {}
var _done: bool = false
var _pending_skill: StringName = &""
var _pending_interact: bool = false
var _pending_dodge: bool = false
var _pending_potion: StringName = &""
var _stuck_timer: float = 0.0
var _last_position := Vector3.ZERO
var _sidestep: float = 1.0
var _sidestep_timer: float = 0.0
var _stall_position := Vector3.ZERO
var _stall_timer: float = 0.0


func begin(from_run: DungeonRun) -> void:
	run = from_run
	player = run.player
	combat = run.combat
	nav = NavFollower.new(player)
	process_priority = -100
	process_physics_priority = -100
	var dungeon: DungeonData = run.dungeon
	var by_id: Dictionary = {}
	for room in dungeon.rooms:
		by_id[room.id] = room.center
	# Inclui os ramos laterais para exercitar baús e elites.
	route = [by_id[&"frost_hall"], Vector2(28, 62), by_id[&"wolf_den"], Vector2(44, 2), by_id[&"crossroads"],
		Vector2(98, -30), by_id[&"ossuary"], Vector2(98, -30), by_id[&"crossroads"],
		Vector2(78, 56), by_id[&"crystal_cave"], Vector2(78, 56), by_id[&"crossroads"],
		Vector2(118, 8), by_id[&"antechamber"], Vector2(134, 50)]
	player.combatant.died.connect(func(_killer: Combatant) -> void: deaths += 1)
	player.combatant.damaged.connect(func(amount: float, _s: Combatant, _c: bool, _t: float) -> void: player_damage_taken += amount)
	run.run_finished.connect(_on_run_finished)
	Events.boss_engaged.connect(func(_b: Node) -> void:
		if boss_fight_start < 0.0:
			boss_fight_start = elapsed)
	Events.boss_defeated.connect(func(_b: Node) -> void:
		boss_fight_seconds = elapsed - boss_fight_start)
	_last_position = player.global_position


## Sem sair do lugar nem progredir por muito tempo, a partida é dada como travada.
func _check_stall(delta: float) -> bool:
	var fighting: bool = player.combatant.in_combat()
	if fighting or player.global_position.distance_to(_stall_position) > 1.5:
		_stall_position = player.global_position
		_stall_timer = 0.0
		return false
	_stall_timer += delta
	if _stall_timer < STALL_SECONDS:
		return false
	_print_stall()
	_finish(false, "travado em %s (rota %d, abates %d)" % [player.global_position.round(), route_index, run.kills])
	return true


func _print_stall() -> void:
	var map: RID = player.get_world_3d().navigation_map
	var position_3d: Vector3 = player.global_position
	var center: Vector3 = run.world.field.ground_position(run.dungeon.room_of_kind(RoomData.Kind.ENTRANCE).center)
	var nearest_pillar: float = INF
	for pillar in run.world.props.pillar_obstacles:
		nearest_pillar = minf(nearest_pillar, Vector2(position_3d.x - pillar.x, position_3d.z - pillar.y).length() - pillar.z)
	print("[TRAVOU] pos=%s y=%.2f sdf=%.2f vel=%s piso=%s parede=%s n=%s coluna=%.2f resgates=%d" % [position_3d.round(), position_3d.y, run.world.field.distance_at(Vector2(position_3d.x, position_3d.z)), player.velocity.round(), player.is_on_floor(), player.is_on_wall(), player.get_wall_normal().round(), nearest_pillar, run.containment_rescues])
	print("[TRAVOU] held=%s rota=%d enemigos_vivos=%d" % [_held, route_index, CombatWorld.hostiles_of(player.combatant).size()])
	print("[TRAVOU] nav: ativo=%s iteração=%d regiões=%d caminho_interno=%d índice=%d caminho_até_entrada=%d mais_perto=%s" % [NavigationServer3D.map_is_active(map), NavigationServer3D.map_get_iteration_id(map), NavigationServer3D.map_get_regions(map).size(), nav._path.size(), nav._index, NavigationServer3D.map_get_path(map, position_3d, center, true).size(), NavigationServer3D.map_get_closest_point(map, position_3d).round()])
	var loot_lines: Array[String] = []
	for child in run.get_children():
		if child is LootDrop:
			loot_lines.append("%s %.1fm sdf=%.2f" % [child.global_position.round(), child.global_position.distance_to(position_3d), run.world.field.distance_at(Vector2(child.global_position.x, child.global_position.z))])
	print("[TRAVOU] drops: ", loot_lines)


func _trace() -> void:
	var enemy: Combatant = _nearest_enemy()
	var loot: int = 0
	for child in run.get_children():
		loot += 1 if child is LootDrop else 0
	var states: Array[String] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var unit := node as Enemy
		if unit.global_position.distance_to(player.global_position) < 25.0:
			states.append("%s:%s:%.0f%%:%.0fm" % [unit.data.id, unit.machine.current_name, unit.combatant.hp_ratio() * 100.0, unit.global_position.distance_to(player.global_position)])
	var nearest_loot := "-"
	for child in run.get_children():
		if child is LootDrop:
			nearest_loot = "%s %.1fm mágica=%.1f" % [child.global_position.round(), child.global_position.distance_to(player.global_position), child.pickup_radius]
			break
	print("   vel=%s piso=%s parede=%s n=%s yaw=%.2f held=%s sdf=%.2f loot1=%s" % [player.velocity.round(), player.is_on_floor(), player.is_on_wall(), player.get_wall_normal().round(), player.rotation.y, _held, run.world.field.distance_at(Vector2(player.global_position.x, player.global_position.z)), nearest_loot])
	print("[%.0fs] pos=%s rota=%d abates=%d hp=%.0f%% mp=%.0f%% loot=%d alvo=%s perto=%s" % [elapsed, player.global_position.round(), route_index, run.kills, player.combatant.hp_ratio() * 100.0, player.combatant.mp_ratio() * 100.0, loot, enemy.display_name if enemy != null else "-", states])


func _on_run_finished(victory: bool) -> void:
	_finish(victory, "concluída")


func _finish(victory: bool, reason: String) -> void:
	if _done:
		return
	_done = true
	_release_all()
	finished.emit({
		"victory": victory, "reason": reason, "seconds": elapsed, "deaths": deaths,
		"kills": run.kills, "boss_seconds": boss_fight_seconds, "level": run.sheet.level,
		"crystals": run.crystals_gained, "chests": run.chests_opened, "loot": run.loot_log.duplicate(),
		"damage_taken": player_damage_taken, "phase": _boss_phase(), "rescues": run.containment_rescues,
		"boss_hp": run.boss.combatant.hp_ratio() if is_instance_valid(run.boss) else 0.0,
	})


func _boss_phase() -> int:
	if not is_instance_valid(run.boss):
		return -1
	var director: BossDirector = run.boss.get_node_or_null("BossDirector")
	return director.current_phase if director != null else -1


func _hold(action: StringName, active: bool) -> void:
	var held: bool = _held.get(action, false)
	if active and not held:
		Input.action_press(action)
	elif not active and held:
		Input.action_release(action)
	_held[action] = active


func _release_all() -> void:
	for action: StringName in _held:
		if _held[action]:
			Input.action_release(action)
	_held.clear()


func _tap(action: StringName) -> void:
	Input.action_press(action)
	Input.action_release.call_deferred(action)


## Ações lidas em _process (habilidades, interação, poções).
func _process(_delta: float) -> void:
	if _done:
		return
	if _pending_skill != &"":
		_tap(_pending_skill)
		_pending_skill = &""
	if _pending_interact:
		_tap(&"interact")
		_pending_interact = false
	if _pending_potion != &"":
		_tap(_pending_potion)
		_pending_potion = &""


func _physics_process(delta: float) -> void:
	if _done:
		return
	elapsed += delta
	_trace_timer -= delta
	if trace_enabled and _trace_timer <= 0.0:
		_trace_timer = 10.0
		_trace()
	if elapsed > time_limit:
		_finish(false, "tempo esgotado na sala/rota %d (abates %d)" % [route_index, run.kills])
		return
	if not player.combatant.is_alive():
		_stop_moving()
		_hold(&"attack", false)
		return
	if _check_stall(delta):
		return
	if _pending_dodge:
		_tap(&"dodge")
		_pending_dodge = false
	_use_potions()
	_handle_stuck(delta)

	var zone: Vector3 = _escape_direction() if avoid_mechanics else Vector3.ZERO
	var enemy: Combatant = _nearest_enemy()
	if zone != Vector3.ZERO:
		_hold(&"attack", false)
		player.look_at_point(player.camera.global_position + zone)
		_hold(&"move_forward", true)
		if player.dodge_cooldown_ratio() <= 0.0:
			_pending_dodge = true
		return
	if enemy != null:
		_fight(enemy, delta)
		return
	_hold(&"attack", false)
	if _collect_loot(delta) or _handle_objectives(delta):
		return
	_follow_route(delta)


func _use_potions() -> void:
	var unit: Combatant = player.combatant
	if unit.hp_ratio() < 0.4 and combat.potion_cooldown_ratio() <= 0.0 and run.sheet.inventory.count_of(&"potion_hp") > 0:
		_pending_potion = &"potion_hp"
	elif unit.mp_ratio() < 0.2 and combat.potion_cooldown_ratio() <= 0.0 and run.sheet.inventory.count_of(&"potion_mp") > 0:
		_pending_potion = &"potion_mp"


func _handle_stuck(delta: float) -> void:
	if player.global_position.distance_to(_last_position) > 1.0:
		_last_position = player.global_position
		_stuck_timer = 0.0
		return
	if _held.get(&"move_forward", false):
		_stuck_timer += delta
		if _stuck_timer > STUCK_SECONDS:
			_stuck_timer = 0.0
			_tap(&"jump")


func _escape_direction() -> Vector3:
	for zone in Telegraph.danger_zones(get_tree()):
		if zone.contains(player.global_position, 0.8):
			var away: Vector3 = player.global_position - zone.global_position
			away.y = 0.0
			if zone.shape == Telegraph.Shape.CIRCLE:
				return away.normalized() if away.length() > 0.2 else player.global_basis.x
			var side: Vector3 = zone.flat_forward.cross(Vector3.UP).normalized()
			return side if side.dot(away) >= 0.0 else -side
	return Vector3.ZERO


func _nearest_enemy() -> Combatant:
	var best: Combatant = null
	var best_distance: float = ENGAGE_DISTANCE
	for hostile in CombatWorld.hostiles_of(player.combatant):
		var distance: float = hostile.world_position().distance_to(player.global_position) - hostile.body_radius
		if distance < best_distance and CombatWorld.has_line_of_sight(player, player.camera.global_position, hostile.center_position()):
			best_distance = distance
			best = hostile
	return best


func _stop_moving() -> void:
	_hold(&"move_forward", false)
	_hold(&"move_left", false)
	_hold(&"move_right", false)


func _fight(enemy: Combatant, delta: float) -> void:
	player.look_at_point(enemy.center_position())
	combat.set_target(enemy)
	var distance: float = enemy.world_position().distance_to(player.global_position) - enemy.body_radius
	match run.sheet.class_data.id:
		&"warrior":
			_fight_warrior(enemy, distance, delta)
		&"mage":
			_fight_mage(enemy, distance, delta)
		_:
			_fight_priest(enemy, distance, delta)


func _skill_ready(skill: SkillData) -> bool:
	return player.caster.refusal(skill) == SkillCaster.Refusal.NONE


func _fight_warrior(enemy: Combatant, distance: float, delta: float) -> void:
	var data: ClassData = run.sheet.class_data
	var close: bool = distance < 2.6
	_hold(&"move_forward", not close)
	_hold(&"attack", close)
	if close:
		_strafe(delta)
	var nearby: int = CombatWorld.hostiles_near(player.combatant, player.global_position, 6.0).size()
	if _skill_ready(data.ultimate) and distance < 5.0:
		_pending_skill = &"skill_ult"
	elif distance > 5.0 and distance < 12.0 and _skill_ready(data.skills[0]):
		_pending_skill = &"skill_1"
	elif nearby >= 2 and _skill_ready(data.skills[1]):
		_pending_skill = &"skill_2"
	elif nearby >= 2 and _skill_ready(data.skills[2]):
		_pending_skill = &"skill_3"
	elif distance < 7.0 and _skill_ready(data.skills[3]):
		_pending_skill = &"skill_4"


func _fight_mage(enemy: Combatant, distance: float, delta: float) -> void:
	var data: ClassData = run.sheet.class_data
	_keep_range(distance, delta)
	_hold(&"attack", true)
	if player.caster.is_casting():
		return
	if _skill_ready(data.ultimate) and distance < 8.0:
		_pending_skill = &"skill_ult"
	elif _skill_ready(data.skills[2]):
		_pending_skill = &"skill_3"
	elif _skill_ready(data.skills[0]):
		_pending_skill = &"skill_1"
	elif _skill_ready(data.skills[1]):
		_pending_skill = &"skill_2"


func _fight_priest(enemy: Combatant, distance: float, delta: float) -> void:
	var data: ClassData = run.sheet.class_data
	_keep_range(distance, delta)
	_hold(&"attack", true)
	if player.caster.is_casting():
		return
	var hurt: Combatant = CombatWorld.most_hurt_ally(player.combatant, 34.0)
	var fallen: bool = false
	for ally in CombatWorld.allies_of(player.combatant, true):
		fallen = fallen or not ally.is_alive()
	if fallen and _skill_ready(data.ultimate):
		_pending_skill = &"skill_ult"
	elif hurt != null and hurt.hp_ratio() < 0.7 and _skill_ready(data.skills[0]):
		combat.set_target(hurt)
		_pending_skill = &"skill_1"
	elif _skill_ready(data.skills[2]):
		_pending_skill = &"skill_3"
	elif distance < 20.0 and _skill_ready(data.skills[3]):
		_pending_skill = &"skill_4"


func _keep_range(distance: float, delta: float) -> void:
	_hold(&"move_forward", distance > 15.0)
	_hold(&"move_back", distance < 7.0)
	if distance >= 7.0:
		_strafe(delta)


func _strafe(delta: float) -> void:
	_sidestep_timer -= delta
	if _sidestep_timer <= 0.0:
		_sidestep_timer = 1.6
		_sidestep = -_sidestep
	_hold(&"move_left", _sidestep < 0.0)
	_hold(&"move_right", _sidestep > 0.0)


func _walk_to(goal: Vector3, delta: float) -> void:
	_hold(&"move_back", false)
	_hold(&"move_left", false)
	_hold(&"move_right", false)
	var direction: Vector3 = nav.direction_to(goal, delta)
	if direction != Vector3.ZERO:
		player.look_at_point(player.camera.global_position + direction)
	_hold(&"move_forward", true)
	_hold(&"sprint", true)


func _collect_loot(delta: float) -> bool:
	var best: LootDrop = null
	var best_distance: float = FIND_LOOT_RADIUS
	for child in run.get_children():
		var loot := child as LootDrop
		if loot != null:
			var distance: float = loot.global_position.distance_to(player.global_position)
			if distance < best_distance:
				best_distance = distance
				best = loot
	if best == null:
		return false
	_walk_to(best.global_position, delta)
	return true


func _handle_objectives(delta: float) -> bool:
	for chest in run.world.props.chests:
		if not chest.is_open and chest.global_position.distance_to(player.global_position) < 12.0:
			_approach_and_interact(chest, delta)
			return true
	var props: DungeonProps = run.world.props
	if route_index >= route.size():
		if props.door != null and not props.door.is_open:
			_approach_and_interact(props.door, delta)
			return true
		if not run.boss_defeated_flag:
			if is_instance_valid(run.boss):
				_walk_to(run.boss.global_position, delta)
			return true
		for node in get_tree().get_nodes_in_group(&"interactable"):
			if node is GatePortal:
				_approach_and_interact(node, delta)
				return true
	return false


func _approach_and_interact(node: Node3D, delta: float) -> void:
	if combat.interactable == node:
		_stop_moving()
		_pending_interact = true
		return
	_walk_to(node.global_position, delta)


func _follow_route(delta: float) -> void:
	if route_index >= route.size():
		return
	var point: Vector2 = route[route_index]
	if Vector2(player.global_position.x, player.global_position.z).distance_to(point) < WAYPOINT_RADIUS:
		route_index += 1
		return
	_walk_to(run.world.field.ground_position(point), delta)
