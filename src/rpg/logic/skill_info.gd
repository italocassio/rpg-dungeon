class_name SkillInfo
extends RefCounted
## Explicação de uma habilidade para um bloco de atributos. Regra pura, sem UI: tooltip, árvore e
## saguão mostram o mesmo resultado, e todo número sai das fórmulas usadas pelo combate.


class Row:
	var label: String
	var value: String
	## &"damage", &"heal", &"area", &"effect", &"cost" ou &"time". A cor fica a cargo da UI.
	var kind: StringName

	func _init(row_label: String, row_value: String, row_kind: StringName) -> void:
		label = row_label
		value = row_value
		kind = row_kind


var skill: SkillData
var subtitle: String = ""
var rows: Array[Row] = []
var footer: String = ""

# Números crus: testes e outras regras leem daqui, nunca do texto.
var damage: float = 0.0
var damage_min: float = 0.0
var damage_max: float = 0.0
var heal: float = 0.0
var heal_min: float = 0.0
var heal_max: float = 0.0
var heal_ticks: int = 0
var periodic: float = 0.0
var periodic_ticks: int = 0
var shield: float = 0.0
var cast_time: float = 0.0
var cooldown: float = 0.0

var _has_periodic_damage: bool = false


## `damage_scale` é o multiplicador externo do conjurador (Combatant.damage_multiplier).
static func describe(from_skill: SkillData, stats: StatBlock, balance: BalanceConfig, damage_scale: float = 1.0) -> SkillInfo:
	var info := SkillInfo.new()
	info.skill = from_skill
	info.subtitle = _subtitle_of(from_skill)
	info._add_damage(stats, balance, damage_scale)
	info._add_heal(stats, balance)
	info._add_area()
	info._add_effects(stats, damage_scale)
	info._add_threat()
	info._add_costs(balance)
	info._add_times(stats)
	info._write_footer(stats, balance)
	return info


## Mesmo conteúdo do card, em uma linha por dado.
func plain_text() -> String:
	var lines: Array[String] = [skill.display_name, subtitle, skill.description]
	for row in rows:
		lines.append("%s: %s" % [row.label, row.value])
	if not footer.is_empty():
		lines.append(footer)
	return "\n".join(lines)


## Único ponto que formata decimais: vírgula e sem zeros à direita ("1,27", "0,6", "4").
static func decimal(value: float) -> String:
	var text: String = "%.2f" % value
	text = text.rstrip("0").trim_suffix(".")
	return text.replace(".", ",")


static func _subtitle_of(from_skill: SkillData) -> String:
	var kind_name: String = SkillData.DAMAGE_KIND_NAMES[from_skill.damage_kind]
	var has_element: bool = from_skill.element != SkillData.Element.NONE
	var deals_damage: bool = from_skill.damage_kind in [SkillData.DamageKind.PHYSICAL, SkillData.DamageKind.MAGICAL]
	return "%s · %s" % [kind_name, SkillData.ELEMENT_NAMES[from_skill.element]] if has_element and deals_damage else kind_name


func _add_damage(stats: StatBlock, balance: BalanceConfig, damage_scale: float) -> void:
	if skill.damage_kind not in [SkillData.DamageKind.PHYSICAL, SkillData.DamageKind.MAGICAL] or skill.power <= 0.0:
		return
	damage = DamageCalculator.nominal_damage(stats, skill.damage_kind, skill.power * damage_scale)
	damage_min = damage * (1.0 - balance.damage_variance)
	damage_max = damage * (1.0 + balance.damage_variance)
	rows.append(Row.new("Dano", _with_range(damage, damage_min, damage_max), &"damage"))


func _add_heal(stats: StatBlock, balance: BalanceConfig) -> void:
	if skill.damage_kind == SkillData.DamageKind.HEAL and skill.power > 0.0:
		heal = DamageCalculator.nominal_heal(stats, skill.power)
		heal_min = heal * (1.0 - balance.damage_variance)
		heal_max = heal * (1.0 + balance.damage_variance)
		if skill.delivery == SkillData.Delivery.HEAL_ZONE:
			heal_ticks = skill.zone_tick_count()
			var total: float = heal * heal_ticks
			rows.append(Row.new("Cura", "%s por pulso (%s a %s) · %d pulsos · %d no total" % [
				_whole(heal), _whole(heal_min), _whole(heal_max), heal_ticks, roundi(total)], &"heal"))
		else:
			heal_ticks = 1
			rows.append(Row.new("Cura", _with_range(heal, heal_min, heal_max), &"heal"))
	if skill.revives_allies:
		rows.append(Row.new("Reviver", "Caídos voltam com %s da vida" % _percent(skill.revive_hp_ratio), &"heal"))


func _add_area() -> void:
	rows.append(Row.new("Área", _area_text(), &"area"))


func _area_text() -> String:
	match skill.delivery:
		SkillData.Delivery.MELEE_CONE:
			return "Cone de %s° · alcance de %s m" % [decimal(skill.cone_degrees), decimal(skill.skill_range)]
		SkillData.Delivery.LINE:
			return "Linha de %s × %s m" % [decimal(skill.skill_range), decimal(skill.line_width)]
		SkillData.Delivery.PROJECTILE:
			var impact: String = "explosão de raio %s m" % decimal(skill.radius) if skill.radius > 0.0 else "atinge o primeiro alvo"
			return "Projétil até %s m · %s" % [decimal(skill.skill_range), impact]
		SkillData.Delivery.GROUND_AOE:
			var parts: Array[String] = ["Ponto da mira até %s m" % decimal(skill.skill_range), "raio de %s m" % decimal(skill.radius)]
			if skill.impact_delay > 0.0:
				parts.append("impacto após %s s" % decimal(skill.impact_delay))
			return " · ".join(parts)
		SkillData.Delivery.SELF_AOE:
			return "Raio de %s m ao seu redor" % decimal(skill.radius)
		SkillData.Delivery.TARGET_ALLY:
			# Com alvo escolhido não há checagem de distância; o limite vale só para a busca automática.
			return "Um aliado · busca automática até %s m" % decimal(skill.skill_range)
		SkillData.Delivery.PARTY:
			return "Todo o grupo, em qualquer distância"
		SkillData.Delivery.DASH:
			return "Avanço até %s m · impacto de raio %s m na chegada" % [decimal(skill.skill_range), decimal(skill.radius)]
		SkillData.Delivery.BLINK:
			return "Teleporte até %s m" % decimal(skill.skill_range)
		SkillData.Delivery.HEAL_ZONE:
			return "Zona de raio %s m a até %s m · dura %s s" % [decimal(skill.radius), decimal(skill.skill_range), decimal(skill.zone_duration)]
	return "Você"


func _add_effects(stats: StatBlock, damage_scale: float) -> void:
	var target_label: String = "Efeito no grupo" if skill.delivery == SkillData.Delivery.PARTY else "Efeito no alvo"
	if skill.target_effect != null:
		_add_effect(target_label, skill.target_effect, stats, damage_scale)
	if skill.self_effect != null:
		_add_effect("Efeito em você", skill.self_effect, stats, damage_scale)


func _add_effect(label: String, effect: EffectData, stats: StatBlock, damage_scale: float) -> void:
	var parts: Array[String] = []
	for stat: StringName in effect.stat_multipliers:
		parts.append("%s %s" % [_signed_percent(effect.stat_multipliers[stat] - 1.0), StatBlock.LABELS[stat]])
	if effect.damage_taken_multiplier != 1.0:
		parts.append("%s de dano recebido" % _signed_percent(effect.damage_taken_multiplier - 1.0))
	if effect.tick_power > 0.0:
		parts.append(_tick_text(effect, stats, damage_scale))
	if effect.shield_power > 0.0:
		var amount: float = DamageCalculator.shield_amount(stats, effect.shield_power)
		shield = maxf(shield, amount)
		parts.append("escudo de %s" % _whole(amount))
	if effect.taunts:
		parts.append("inimigos atacam você")
	if effect.stuns:
		parts.append("não age (chefes são imunes)")
	var heading: String = "%s por %s s" % [effect.display_name, decimal(effect.duration)]
	rows.append(Row.new(label, "%s: %s" % [heading, ", ".join(parts)] if not parts.is_empty() else heading, &"effect"))


func _tick_text(effect: EffectData, stats: StatBlock, damage_scale: float) -> String:
	var amount: float = DamageCalculator.periodic_amount(stats, effect.tick_power)
	if not effect.tick_is_heal:
		amount *= damage_scale
		_has_periodic_damage = true
	if periodic_ticks == 0:
		periodic = amount
		periodic_ticks = effect.tick_count()
	var ticks: int = effect.tick_count()
	return "%s de %s a cada %s s, %s no total" % [
		_whole(amount), "cura" if effect.tick_is_heal else "dano", decimal(effect.tick_interval), _whole(amount * ticks)]


## Sem número: `threat_multiplier` multiplica o dano em golpes, mas é um valor fixo em habilidades sem dano.
func _add_threat() -> void:
	if skill.threat_multiplier > 1.0:
		rows.append(Row.new("Ameaça", "Elevada", &"effect"))


func _add_costs(balance: BalanceConfig) -> void:
	var costs: Array[String] = []
	if skill.mp_cost > 0.0:
		costs.append("%s de Mana" % _whole(skill.mp_cost))
	if skill.chi_cost > 0.0:
		var sparks: float = skill.chi_cost / balance.chi_per_spark
		costs.append("%s de Chi (%s %s)" % [_whole(skill.chi_cost), decimal(sparks), "Faísca" if sparks <= 1.0 else "Faíscas"])
	rows.append(Row.new("Custo", " · ".join(costs) if not costs.is_empty() else "Nenhum", &"cost"))
	if skill.chi_gain > 0.0:
		var condition: String = "com cura efetiva" if skill.delivery == SkillData.Delivery.TARGET_ALLY else "ao acertar"
		rows.append(Row.new("Chi", "+%s %s" % [_whole(skill.chi_gain), condition], &"cost"))


func _add_times(stats: StatBlock) -> void:
	cast_time = skill.cast_duration(stats)
	cooldown = skill.recovery_time(stats)
	rows.append(Row.new("Conjuração", "%s s" % decimal(cast_time) if cast_time > 0.0 else "Instantânea", &"time"))
	rows.append(Row.new("Recarga", "%s s" % decimal(cooldown), &"time"))


func _write_footer(stats: StatBlock, balance: BalanceConfig) -> void:
	var variance: String = "Variação de ±%s" % _percent(balance.damage_variance)
	var notes: Array[String] = []
	if damage > 0.0:
		notes.append("Dano direto antes da defesa e do elemento do alvo. %s; crítico multiplica por %s." % [variance, decimal(stats.crit_multiplier)])
	elif heal > 0.0:
		notes.append("%s; cura não tem crítico." % variance)
	if _has_periodic_damage:
		notes.append("Dano periódico antes da defesa, sem elemento, variação nem crítico.")
	footer = " ".join(notes)


static func _with_range(amount: float, low: float, high: float) -> String:
	return "%s (%s a %s)" % [_whole(amount), _whole(low), _whole(high)]


static func _whole(value: float) -> String:
	return str(roundi(value))


static func _percent(ratio: float) -> String:
	return "%s%%" % decimal(ratio * 100.0)


static func _signed_percent(ratio: float) -> String:
	return "%s%s" % ["+" if ratio >= 0.0 else "-", _percent(absf(ratio))]
