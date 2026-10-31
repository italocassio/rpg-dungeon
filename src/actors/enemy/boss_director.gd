class_name BossDirector
extends Node
## Controla as fases do chefe. Anexado ao Enemy apenas em chefes.

signal summon_requested(monster: MonsterData, count: int, center: Vector3)
signal encounter_reset

var enemy: Enemy
var current_phase: int = 0
var _pending: Array[BossPhaseData] = []
var _engaged: bool = false


func setup(boss: Enemy) -> void:
	enemy = boss
	_pending = boss.data.phases.duplicate()
	_pending.sort_custom(func(a: BossPhaseData, b: BossPhaseData) -> bool: return a.hp_ratio > b.hp_ratio)
	boss.combatant.health_changed.connect(_on_health_changed)
	boss.machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_previous: StringName, next: StringName) -> void:
	if next == &"chase" and not _engaged:
		_engaged = true
		Events.boss_engaged.emit(enemy.combatant)
	elif next == &"idle":
		_engaged = false
		_reset_phases()
		encounter_reset.emit()


func _reset_phases() -> void:
	current_phase = 0
	_pending = enemy.data.phases.duplicate()
	_pending.sort_custom(func(a: BossPhaseData, b: BossPhaseData) -> bool: return a.hp_ratio > b.hp_ratio)
	enemy.active_skills = enemy.data.skills.duplicate()
	enemy.speed_multiplier = 1.0
	enemy.combatant.damage_multiplier = enemy.rank.damage_multiplier


func _on_health_changed(current: float, maximum: float) -> void:
	if _pending.is_empty() or current <= 0.0:
		return
	if current / maximum > _pending[0].hp_ratio:
		return
	_enter_phase(_pending.pop_front())


func _enter_phase(phase: BossPhaseData) -> void:
	current_phase += 1
	enemy.active_skills = phase.skills.duplicate()
	enemy.speed_multiplier = phase.speed_multiplier
	enemy.combatant.damage_multiplier = enemy.rank.damage_multiplier * phase.damage_multiplier
	Events.system_message.emit(phase.announcement, "warning")
	if phase.summon_count > 0:
		var monster: MonsterData = GameDB.monster(phase.summon_id)
		if monster != null:
			summon_requested.emit(monster, phase.summon_count, enemy.global_position)
