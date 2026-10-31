class_name EffectData
extends Resource
## Buff, debuff ou efeito periódico aplicado a um Combatant.

@export var id: StringName
@export var display_name: String
@export var duration: float = 5.0
@export var is_debuff: bool = false
@export var color: Color = Color.WHITE
@export var stat_multipliers: Dictionary[StringName, float] = {}
@export var damage_taken_multiplier: float = 1.0
@export var stuns: bool = false
@export var taunts: bool = false
@export_group("Periódico")
@export var tick_interval: float = 1.0
## Fração do ataque de quem aplicou; dano ou cura conforme tick_is_heal.
@export var tick_power: float = 0.0
@export var tick_is_heal: bool = false
@export_group("Escudo")
## Escudo absorve dano; valor = ataque mágico da fonte * shield_power.
@export var shield_power: float = 0.0
