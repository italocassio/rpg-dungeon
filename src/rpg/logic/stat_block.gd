class_name StatBlock
extends RefCounted
## Atributos derivados usados em combate. Compartilhado por jogadores, bots e monstros.

const FIELDS: Array[StringName] = [
	&"max_hp", &"max_mp", &"phys_attack", &"magic_attack", &"phys_defense",
	&"magic_defense", &"crit_chance", &"crit_multiplier", &"dodge_chance",
	&"move_speed", &"attack_speed", &"cast_speed", &"heal_power",
]
const LABELS: Dictionary = {
	&"max_hp": "Vida", &"max_mp": "Mana", &"phys_attack": "Ataque Físico",
	&"magic_attack": "Ataque Mágico", &"phys_defense": "Defesa Física",
	&"magic_defense": "Defesa Mágica", &"crit_chance": "Crítico",
	&"crit_multiplier": "Dano Crítico", &"dodge_chance": "Esquiva",
	&"move_speed": "Velocidade", &"attack_speed": "Vel. de Ataque",
	&"cast_speed": "Vel. de Conjuração", &"heal_power": "Poder de Cura",
}
const PERCENT_STATS: Array[StringName] = [&"crit_chance", &"dodge_chance"]

var max_hp: float = 100.0
var max_mp: float = 0.0
var phys_attack: float = 10.0
var magic_attack: float = 10.0
var phys_defense: float = 10.0
var magic_defense: float = 10.0
var crit_chance: float = 0.05
var crit_multiplier: float = 1.75
var dodge_chance: float = 0.0
var move_speed: float = 6.0
var attack_speed: float = 1.0
var cast_speed: float = 1.0
var heal_power: float = 1.0
var weak_element: SkillData.Element = SkillData.Element.NONE
var strong_element: SkillData.Element = SkillData.Element.NONE


func duplicate_block() -> StatBlock:
	var copy := StatBlock.new()
	for field in FIELDS:
		copy.set(field, get(field))
	copy.weak_element = weak_element
	copy.strong_element = strong_element
	return copy


func add_bonuses(bonuses: Dictionary) -> void:
	for key: StringName in bonuses:
		if key in FIELDS:
			set(key, float(get(key)) + float(bonuses[key]))


static func format_value(stat: StringName, value: float) -> String:
	if stat in PERCENT_STATS:
		return "%.1f%%" % (value * 100.0)
	return str(roundi(value)) if absf(value) >= 10.0 else "%.2f" % value
