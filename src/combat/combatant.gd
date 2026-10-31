class_name Combatant
extends Node
## Vida, mana, Chi e efeitos de qualquer participante do combate.
## Componente único para jogador, bots e monstros (composição em vez de herança).

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal chi_changed(current: float)
signal damaged(amount: float, source: Combatant, is_crit: bool, threat: float)
signal attack_avoided(source: Combatant)
signal healed(amount: float, source: Combatant)
signal died(killer: Combatant)
signal revived
signal effects_changed

enum Team { PARTY, MONSTERS }

const OUT_OF_COMBAT_DELAY := 6.0
const OUT_OF_COMBAT_REGEN := 5.0

## Efeito em andamento; `source` pode deixar de existir antes do fim.
class ActiveEffect:
	var data: EffectData
	var remaining: float
	var next_tick: float
	var source: Combatant


var display_name: String = ""
var level: int = 1
var team: Team = Team.MONSTERS
var body_radius: float = 0.45
var body_height: float = 1.75
var balance: BalanceConfig
var base_stats: StatBlock = StatBlock.new()
var stats: StatBlock = StatBlock.new()
var hp: float = 1.0
var mp: float = 0.0
var chi: float = 0.0
var shield: float = 0.0
## Multiplicador externo de dano causado (rank do portão, fase do chefe).
var damage_multiplier: float = 1.0
## Dano recebido enquanto a postura de defesa estiver ativa.
var guard_multiplier: float = 1.0
var effects: Array[ActiveEffect] = []
var taunted_by: Combatant
## Chefes não podem ser atordoados: o stun cancelaria seus golpes sem custo.
var stun_immune: bool = false
var rng := RandomNumberGenerator.new()

var _invulnerable_time: float = 0.0
var _forced_move_time: float = 0.0
var _time_since_combat: float = 999.0
var _is_dead: bool = false


func setup(unit_name: String, unit_level: int, unit_team: Team, unit_stats: StatBlock, config: BalanceConfig) -> void:
	display_name = unit_name
	level = unit_level
	team = unit_team
	base_stats = unit_stats
	balance = config
	rng.randomize()
	add_to_group(&"combatants")
	_recalculate_stats()
	hp = stats.max_hp
	mp = stats.max_mp
	_is_dead = false


func actor() -> Node3D:
	return get_parent() as Node3D


func world_position() -> Vector3:
	return actor().global_position


func center_position() -> Vector3:
	return actor().global_position + Vector3.UP * body_height * 0.55


func is_alive() -> bool:
	return not _is_dead


func hp_ratio() -> float:
	return clampf(hp / maxf(stats.max_hp, 1.0), 0.0, 1.0)


func mp_ratio() -> float:
	return clampf(mp / maxf(stats.max_mp, 1.0), 0.0, 1.0)


func sparks() -> int:
	return int(chi / balance.chi_per_spark)


func is_stunned() -> bool:
	for effect in effects:
		if effect.data.stuns:
			return true
	return false


func is_invulnerable() -> bool:
	return _invulnerable_time > 0.0


func grant_invulnerability(seconds: float) -> void:
	_invulnerable_time = maxf(_invulnerable_time, seconds)


func is_forced_moving() -> bool:
	return _forced_move_time > 0.0


func begin_forced_move(seconds: float) -> void:
	_forced_move_time = seconds


func in_combat() -> bool:
	return _time_since_combat < OUT_OF_COMBAT_DELAY


func mark_in_combat() -> void:
	_time_since_combat = 0.0


func spend_mana(amount: float) -> void:
	if amount <= 0.0:
		return
	mp = maxf(mp - amount, 0.0)
	mana_changed.emit(mp, stats.max_mp)


func restore_mana(amount: float) -> void:
	mp = minf(mp + amount, stats.max_mp)
	mana_changed.emit(mp, stats.max_mp)


func add_chi(amount: float) -> void:
	if amount == 0.0:
		return
	chi = clampf(chi + amount, 0.0, balance.max_chi)
	chi_changed.emit(chi)


## Aplica o golpe de `skill`. Retorna true se acertou.
func receive_hit(source: Combatant, skill: SkillData, power_scale: float = 1.0) -> bool:
	if _is_dead or is_invulnerable():
		return false
	mark_in_combat()
	source.mark_in_combat()
	var outcome := DamageCalculator.compute(
		source.stats, stats, skill.damage_kind, skill.element,
		skill.power * power_scale * source.damage_multiplier, balance, rng)
	if outcome.is_dodged:
		attack_avoided.emit(source)
		return false
	_take_damage(outcome.amount * guard_multiplier * _incoming_multiplier(), source, outcome.is_crit, skill.threat_multiplier)
	return true


func receive_periodic_damage(amount: float, source: Combatant) -> void:
	if _is_dead:
		return
	mark_in_combat()
	_take_damage(amount * _incoming_multiplier(), source, false, 1.0)


func _incoming_multiplier() -> float:
	var multiplier: float = 1.0
	for effect in effects:
		multiplier *= effect.data.damage_taken_multiplier
	return multiplier


func _take_damage(amount: float, source: Combatant, is_crit: bool, threat: float) -> void:
	var remaining: float = amount
	if shield > 0.0:
		var absorbed: float = minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	hp = maxf(hp - remaining, 0.0)
	if team == Team.PARTY and remaining > 0.0:
		add_chi(balance.chi_on_hit_taken)
	damaged.emit(amount, source, is_crit, threat)
	health_changed.emit(hp, stats.max_hp)
	if hp <= 0.0:
		_die(source)


func _die(killer: Combatant) -> void:
	_is_dead = true
	shield = 0.0
	guard_multiplier = 1.0
	_clear_effects()
	died.emit(killer)


func receive_heal(amount: float, source: Combatant) -> void:
	if _is_dead or amount <= 0.0:
		return
	var applied: float = minf(amount, stats.max_hp - hp)
	hp += applied
	healed.emit(applied, source)
	health_changed.emit(hp, stats.max_hp)


func revive(hp_ratio_on_revive: float = 0.5) -> void:
	if not _is_dead:
		return
	_is_dead = false
	hp = stats.max_hp * hp_ratio_on_revive
	mp = maxf(mp, stats.max_mp * 0.3)
	revived.emit()
	health_changed.emit(hp, stats.max_hp)
	mana_changed.emit(mp, stats.max_mp)


func restore_full() -> void:
	if _is_dead:
		return
	hp = stats.max_hp
	mp = stats.max_mp
	shield = 0.0
	health_changed.emit(hp, stats.max_hp)
	mana_changed.emit(mp, stats.max_mp)


## Reaplica equipamento/atributos alterados em base_stats mantendo os efeitos ativos.
func refresh_stats() -> void:
	_recalculate_stats()
	hp = minf(hp, stats.max_hp)
	mp = minf(mp, stats.max_mp)
	health_changed.emit(hp, stats.max_hp)
	mana_changed.emit(mp, stats.max_mp)
	effects_changed.emit()


func apply_effect(data: EffectData, source: Combatant) -> void:
	if _is_dead or data == null or (data.stuns and stun_immune):
		return
	if data.is_debuff:
		mark_in_combat()
	for effect in effects:
		if effect.data == data:
			effect.remaining = data.duration
			effect.source = source
			if data.taunts:
				taunted_by = source
			_apply_shield(data, source)
			effects_changed.emit()
			return
	var effect := ActiveEffect.new()
	effect.data = data
	effect.remaining = data.duration
	effect.next_tick = data.tick_interval
	effect.source = source
	effects.append(effect)
	if data.taunts:
		taunted_by = source
	_apply_shield(data, source)
	_recalculate_stats()
	effects_changed.emit()


func _apply_shield(data: EffectData, source: Combatant) -> void:
	if data.shield_power > 0.0 and source != null:
		shield = maxf(shield, DamageCalculator.shield_amount(source.stats, data.shield_power))


func _clear_effects() -> void:
	effects.clear()
	taunted_by = null
	_recalculate_stats()
	effects_changed.emit()


func _recalculate_stats() -> void:
	stats = base_stats.duplicate_block()
	for effect in effects:
		for key: StringName in effect.data.stat_multipliers:
			stats.set(key, float(stats.get(key)) * effect.data.stat_multipliers[key])


func _process(delta: float) -> void:
	_invulnerable_time = maxf(_invulnerable_time - delta, 0.0)
	_forced_move_time = maxf(_forced_move_time - delta, 0.0)
	_time_since_combat += delta
	if _is_dead:
		return
	_tick_effects(delta)
	_regenerate(delta)


func _regenerate(delta: float) -> void:
	if team != Team.PARTY:
		return
	var multiplier: float = OUT_OF_COMBAT_REGEN if not in_combat() else 1.0
	if hp < stats.max_hp:
		hp = minf(hp + stats.max_hp * balance.hp_regen_ratio * multiplier * delta, stats.max_hp)
		health_changed.emit(hp, stats.max_hp)
	if mp < stats.max_mp:
		mp = minf(mp + stats.max_mp * balance.mp_regen_ratio * multiplier * delta, stats.max_mp)
		mana_changed.emit(mp, stats.max_mp)


func _tick_effects(delta: float) -> void:
	var expired: bool = false
	for effect in effects:
		effect.remaining -= delta
		if effect.data.tick_power > 0.0:
			effect.next_tick -= delta
			if effect.next_tick <= 0.0:
				effect.next_tick += effect.data.tick_interval
				_apply_tick(effect)
				if _is_dead:
					return
		if effect.remaining <= 0.0:
			expired = true
	if not expired:
		return
	var had_shield_effect: bool = false
	for i in range(effects.size() - 1, -1, -1):
		if effects[i].remaining <= 0.0:
			var data: EffectData = effects[i].data
			if data.taunts:
				taunted_by = null
			if data.shield_power > 0.0:
				had_shield_effect = true
			effects.remove_at(i)
	if had_shield_effect:
		shield = 0.0
	_recalculate_stats()
	effects_changed.emit()


func _apply_tick(effect: ActiveEffect) -> void:
	var source: Combatant = effect.source if is_instance_valid(effect.source) else null
	if source == null:
		return
	var amount: float = DamageCalculator.periodic_amount(source.stats, effect.data.tick_power)
	if effect.data.tick_is_heal:
		receive_heal(amount, source)
	else:
		var mitigation: float = DamageCalculator.mitigation(stats.magic_defense, balance)
		receive_periodic_damage(amount * mitigation * source.damage_multiplier, source)
