class_name SkillCaster
extends Node
## Controla conjuração, recarga e custos de habilidades.

signal cast_started(skill: SkillData, duration: float)
signal cast_interrupted(skill: SkillData)
signal skill_fired(skill: SkillData, aim: SkillAim)

enum Refusal { NONE, DEAD, STUNNED, BUSY, COOLDOWN, NO_MANA, NO_CHI }

const GLOBAL_COOLDOWN := 0.45

var combatant: Combatant
## Recebe a habilidade e devolve a mira no fim do cast (o jogador pode ajustar durante a conjuração).
var aim_provider: Callable = Callable()

var _cooldowns: Dictionary[StringName, float] = {}
var _cooldown_totals: Dictionary[StringName, float] = {}
var _global_cooldown: float = 0.0
var _casting: SkillData
var _cast_left: float = 0.0
var _cast_total: float = 0.0
var _aim: SkillAim
var _telegraph: Telegraph


func is_casting() -> bool:
	return _casting != null


func casting_skill() -> SkillData:
	return _casting


func cast_progress() -> float:
	return 1.0 - _cast_left / maxf(_cast_total, 0.001) if _casting != null else 0.0


func cooldown_left(skill: SkillData) -> float:
	return _cooldowns.get(skill.id, 0.0)


func cooldown_ratio(skill: SkillData) -> float:
	return cooldown_left(skill) / maxf(_cooldown_totals.get(skill.id, 1.0), 0.001)


func refusal(skill: SkillData) -> Refusal:
	if combatant == null or not combatant.is_alive():
		return Refusal.DEAD
	if combatant.is_stunned():
		return Refusal.STUNNED
	if _casting != null:
		return Refusal.BUSY
	if cooldown_left(skill) > 0.0:
		return Refusal.COOLDOWN
	if skill.triggers_global_cooldown and _global_cooldown > 0.0:
		return Refusal.BUSY
	if combatant.mp < skill.mp_cost:
		return Refusal.NO_MANA
	if combatant.chi < skill.chi_cost:
		return Refusal.NO_CHI
	return Refusal.NONE


func try_cast(skill: SkillData, aim: SkillAim) -> bool:
	if refusal(skill) != Refusal.NONE:
		return false
	_aim = aim
	var duration: float = skill.cast_time / maxf(combatant.stats.cast_speed, 0.1)
	if duration <= 0.0:
		_fire(skill)
		return true
	_casting = skill
	_cast_left = duration
	_cast_total = duration
	if skill.telegraph:
		_telegraph = Telegraph.spawn(combatant, skill, aim, duration)
	cast_started.emit(skill, duration)
	return true


func interrupt() -> void:
	if _casting == null:
		return
	var skill: SkillData = _casting
	_casting = null
	_clear_telegraph()
	cast_interrupted.emit(skill)


func reset_all() -> void:
	_casting = null
	_clear_telegraph()
	_cooldowns.clear()
	_global_cooldown = 0.0


func _clear_telegraph() -> void:
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


func _process(delta: float) -> void:
	_global_cooldown = maxf(_global_cooldown - delta, 0.0)
	for id: StringName in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	if _casting == null:
		return
	if combatant == null or not combatant.is_alive() or combatant.is_stunned():
		interrupt()
		return
	_cast_left -= delta
	if _cast_left <= 0.0:
		var skill: SkillData = _casting
		_casting = null
		_clear_telegraph()
		# Recursos podem ter acabado durante o cast.
		if combatant.mp < skill.mp_cost or combatant.chi < skill.chi_cost:
			cast_interrupted.emit(skill)
			return
		if aim_provider.is_valid():
			_aim = aim_provider.call(skill)
		_fire(skill)


func _fire(skill: SkillData) -> void:
	combatant.spend_mana(skill.mp_cost)
	combatant.add_chi(-skill.chi_cost)
	var attack_speed: float = combatant.stats.attack_speed if skill.cast_time <= 0.0 else 1.0
	var cooldown: float = skill.cooldown / maxf(attack_speed, 0.1)
	if cooldown > 0.0:
		_cooldowns[skill.id] = cooldown
		_cooldown_totals[skill.id] = cooldown
	if skill.triggers_global_cooldown:
		_global_cooldown = minf(GLOBAL_COOLDOWN, cooldown)
	SkillExecutor.execute(skill, combatant, _aim)
	skill_fired.emit(skill, _aim)
