class_name Enemy
extends CharacterBody3D
## Monstro: integra Combatant, SkillCaster, modelo e máquina de estados.

signal defeated(enemy: Enemy)

const SLEEP_DISTANCE := 70.0
const CORPSE_SECONDS := 2.6
const SEPARATION_RADIUS := 1.3
const SEPARATION_FORCE := 2.4
const TURN_SPEED := 9.0
const GRAVITY := 18.0

var data: MonsterData
var rank: GateRankData
var home := Vector3.ZERO
var active_skills: Array[SkillData] = []
var threat := ThreatTable.new()
var nav: NavFollower
var machine := StateMachine.new()
var rig: CreatureRig
var speed_multiplier: float = 1.0
var is_summon: bool = false

@onready var combatant: Combatant = $Combatant
@onready var caster: SkillCaster = $SkillCaster
@onready var collider: CollisionShape3D = $CollisionShape3D

var _focus: Node3D


func setup(monster: MonsterData, gate_rank: GateRankData, spawn_position: Vector3, focus_node: Node3D) -> void:
	data = monster
	rank = gate_rank
	home = spawn_position
	_focus = focus_node
	active_skills = monster.skills.duplicate()


func _ready() -> void:
	add_to_group(&"enemies")
	var stats := StatBlock.new()
	stats.max_hp = data.max_hp * rank.hp_multiplier
	stats.phys_attack = data.phys_attack
	stats.magic_attack = data.magic_attack
	stats.phys_defense = data.phys_defense + rank.monster_level_bonus * 4.0
	stats.magic_defense = data.magic_defense + rank.monster_level_bonus * 4.0
	stats.move_speed = data.move_speed
	stats.crit_chance = 0.05
	stats.weak_element = data.weak_element
	stats.strong_element = data.strong_element
	combatant.setup(data.display_name, data.level + rank.monster_level_bonus, Combatant.Team.MONSTERS, stats, GameDB.balance)
	combatant.damage_multiplier = rank.damage_multiplier
	combatant.body_radius = data.body_radius
	combatant.body_height = data.body_height
	combatant.stun_immune = data.tier == MonsterData.Tier.BOSS
	caster.combatant = combatant

	var capsule := collider.shape.duplicate() as CapsuleShape3D
	capsule.radius = data.body_radius
	capsule.height = maxf(data.body_height, data.body_radius * 2.0)
	collider.shape = capsule
	collider.position.y = capsule.height * 0.5

	rig = CreatureFactory.build(data.visual)
	rig.scale = Vector3.ONE * data.scale
	add_child(rig)

	var tier_color: Color = Color("ffd76a") if data.tier != MonsterData.Tier.NORMAL else Color("ff7a6a")
	var plate := Nameplate.new()
	add_child(plate)
	plate.setup(combatant, "Nv %d  %s" % [combatant.level, data.display_name], tier_color, data.body_height + 0.5,
		1.6 if data.tier != MonsterData.Tier.NORMAL else 1.0)

	nav = NavFollower.new(self)
	machine.add(&"idle", EnemyStates.Idle.new(self))
	machine.add(&"chase", EnemyStates.Chase.new(self))
	machine.add(&"attack", EnemyStates.Attack.new(self))
	machine.add(&"return", EnemyStates.Return.new(self))
	machine.add(&"dead", EnemyStates.Dead.new(self))
	machine.start(&"idle")

	combatant.damaged.connect(_on_damaged)
	combatant.died.connect(_on_died)
	caster.cast_started.connect(func(skill: SkillData, duration: float) -> void: rig.wind_up(skill.animation, duration))
	caster.skill_fired.connect(func(skill: SkillData, _aim: SkillAim) -> void: rig.strike(skill.animation))
	caster.cast_interrupted.connect(func(_skill: SkillData) -> void: rig.cancel_action())


func _physics_process(delta: float) -> void:
	if _is_asleep():
		return
	machine.physics_update(delta)
	if combatant.is_forced_moving():
		velocity = Vector3.ZERO
	else:
		velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
		move_and_slide()
	rig.animate(delta, Vector2(velocity.x, velocity.z).length())


func _is_asleep() -> bool:
	if not is_instance_valid(_focus) or machine.current_name != &"idle":
		return false
	return global_position.distance_to(_focus.global_position) > SLEEP_DISTANCE


func move_toward_point(goal: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = nav.direction_to(goal, delta) + _separation()
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() > 1.0:
		flat = flat.normalized()
	velocity.x = flat.x * speed
	velocity.z = flat.z * speed
	if flat.length_squared() > 0.01:
		face_direction(flat, delta)


func halt() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func face_direction(direction: Vector3, delta: float) -> void:
	var yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, yaw, minf(TURN_SPEED * delta, 1.0))


func snap_facing(point: Vector3) -> void:
	var offset: Vector3 = point - global_position
	if Vector2(offset.x, offset.z).length_squared() > 0.0001:
		rotation.y = atan2(-offset.x, -offset.z)


func face_point(point: Vector3, delta: float) -> void:
	face_direction(point - global_position, delta)


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var other := node as Enemy
		if other == self or not other.combatant.is_alive():
			continue
		var offset: Vector3 = global_position - other.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		var minimum: float = SEPARATION_RADIUS + data.body_radius * 0.5 + other.data.body_radius * 0.5
		if distance > 0.01 and distance < minimum:
			push += offset / distance * (1.0 - distance / minimum)
	return push * SEPARATION_FORCE


## Alcance útil para a IA decidir se pode usar a habilidade.
func skill_reach(skill: SkillData) -> float:
	match skill.delivery:
		SkillData.Delivery.SELF_AOE:
			return skill.radius * 0.75
		_:
			return skill.skill_range * 0.92


func is_skill_in_range(skill: SkillData, target: Combatant) -> bool:
	var distance: float = Vector2(target.world_position().x - global_position.x, target.world_position().z - global_position.z).length() - target.body_radius
	if skill.delivery == SkillData.Delivery.DASH and distance < 3.5:
		return false
	return distance <= skill_reach(skill)


## Habilidades com maior recarga têm prioridade (são as mais perigosas).
func pick_skill(target: Combatant) -> SkillData:
	var best: SkillData = null
	for skill in active_skills:
		if caster.refusal(skill) != SkillCaster.Refusal.NONE or not is_skill_in_range(skill, target):
			continue
		if best == null or skill.cooldown > best.cooldown:
			best = skill
	return best


func engage(target: Combatant, alert_neighbors: bool = true) -> void:
	if not combatant.is_alive():
		return
	threat.add(target, 1.0)
	if machine.current_name == &"idle" or machine.current_name == &"return":
		machine.transition(&"chase")
	if alert_neighbors:
		for node in get_tree().get_nodes_in_group(&"enemies"):
			var other := node as Enemy
			if other != self and other.combatant.is_alive() and other.machine.current_name == &"idle" \
					and other.global_position.distance_to(global_position) < 10.0:
				other.engage(target, false)


func _on_damaged(amount: float, source: Combatant, _is_crit: bool, threat_multiplier: float) -> void:
	if amount > 0.0:
		rig.flash_hit()
	if source == null or not is_instance_valid(source):
		return
	threat.add(source, maxf(amount, 1.0) * threat_multiplier)
	engage(source)


func _on_died(_killer: Combatant) -> void:
	caster.interrupt()
	machine.transition(&"dead")
	defeated.emit(self)


func begin_corpse() -> void:
	collider.set_deferred("disabled", true)
	collision_layer = 0
	rig.die()
	get_tree().create_timer(CORPSE_SECONDS, false).timeout.connect(queue_free)
