class_name EnemyStates
extends RefCounted
## Estados da IA de monstros.

const SCAN_INTERVAL := 0.3
const RECOVERY_SECONDS := 0.45


class Base:
	extends ActorState
	var enemy: Enemy

	func _init(owner_enemy: Enemy) -> void:
		enemy = owner_enemy


class Idle:
	extends Base
	var _scan: float = 0.0
	var _wander_goal := Vector3.INF
	var _wander_wait: float = 2.0

	func enter() -> void:
		enemy.halt()
		_wander_goal = Vector3.INF
		_wander_wait = randf_range(1.0, 4.0)

	func physics_update(delta: float) -> void:
		_scan -= delta
		if _scan <= 0.0:
			_scan = SCAN_INTERVAL
			var target: Combatant = _find_target()
			if target != null:
				enemy.engage(target)
				return
		_wander(delta)

	func _find_target() -> Combatant:
		var center: Vector3 = enemy.global_position + Vector3.UP * 1.2
		for hostile in CombatWorld.hostiles_of(enemy.combatant):
			var distance: float = hostile.world_position().distance_to(enemy.global_position)
			if distance <= enemy.data.aggro_radius \
					and CombatWorld.has_line_of_sight(enemy, center, hostile.center_position()):
				return hostile
		return null

	func _wander(delta: float) -> void:
		if _wander_goal == Vector3.INF:
			enemy.halt()
			_wander_wait -= delta
			if _wander_wait <= 0.0 and enemy.data.tier == MonsterData.Tier.NORMAL:
				var angle: float = randf() * TAU
				_wander_goal = enemy.home + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.0, 3.5)
			return
		if Vector2(enemy.global_position.x - _wander_goal.x, enemy.global_position.z - _wander_goal.z).length() < 0.6:
			_wander_goal = Vector3.INF
			_wander_wait = randf_range(2.0, 6.0)
			return
		enemy.move_toward_point(_wander_goal, enemy.data.move_speed * 0.4, delta)


class Chase:
	extends Base

	func physics_update(delta: float) -> void:
		var unit: Combatant = enemy.combatant
		if unit.is_stunned() or unit.is_forced_moving():
			enemy.halt()
			return
		var target: Combatant = enemy.threat.top_target(unit)
		if target == null or enemy.global_position.distance_to(enemy.home) > enemy.data.leash_radius:
			machine.transition(&"return")
			return
		var offset: Vector3 = target.world_position() - enemy.global_position
		var distance: float = Vector2(offset.x, offset.z).length()
		var skill: SkillData = enemy.pick_skill(target)
		if skill != null:
			var attack: Attack = machine._states[&"attack"]
			attack.prepare(skill, target)
			machine.transition(&"attack")
			return
		var stop_distance: float = enemy.data.preferred_range + target.body_radius
		if distance > stop_distance:
			enemy.move_toward_point(target.world_position(), unit.stats.move_speed * enemy.speed_multiplier, delta)
		else:
			enemy.halt()
			enemy.face_point(target.world_position(), delta)


class Attack:
	extends Base
	var _skill: SkillData
	var _target: Combatant
	var _recovery: float = 0.0
	var _started: bool = false

	func prepare(skill: SkillData, target: Combatant) -> void:
		_skill = skill
		_target = target

	func enter() -> void:
		enemy.halt()
		_recovery = RECOVERY_SECONDS
		enemy.snap_facing(_target.world_position())
		var aim := SkillAim.toward(enemy.combatant, _target)
		_started = enemy.caster.try_cast(_skill, aim)

	func physics_update(delta: float) -> void:
		enemy.halt()
		if enemy.caster.is_casting():
			return
		_recovery -= delta
		if _recovery <= 0.0 or not _started:
			machine.transition(&"chase")


class Return:
	extends Base

	func enter() -> void:
		enemy.threat.clear()
		enemy.caster.interrupt()

	func physics_update(delta: float) -> void:
		if enemy.global_position.distance_to(enemy.home) < 1.6:
			enemy.combatant.restore_full()
			machine.transition(&"idle")
			return
		enemy.move_toward_point(enemy.home, enemy.data.move_speed * 1.5, delta)


class Dead:
	extends Base

	func enter() -> void:
		enemy.halt()
		enemy.begin_corpse()
