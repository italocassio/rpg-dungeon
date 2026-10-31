class_name BalanceConfig
extends Resource
## Valores globais de balanceamento (editáveis no Inspector).

@export_group("Progressão")
@export var max_level: int = 10
@export var attribute_points_per_level: int = 3
@export var xp_base: float = 120.0
@export var xp_exponent: float = 1.55

@export_group("Atributos")
@export var attack_per_strength: float = 2.2
@export var hp_per_vitality: float = 14.0
@export var phys_defense_per_vitality: float = 1.2
@export var crit_per_agility: float = 0.004
@export var dodge_per_agility: float = 0.0025
@export var move_speed_per_agility: float = 0.03
@export var magic_attack_per_intelligence: float = 2.4
@export var mp_per_intelligence: float = 12.0
@export var magic_defense_per_intelligence: float = 1.2

@export_group("Dano")
@export var defense_constant: float = 110.0
@export var damage_variance: float = 0.1
@export var base_crit_chance: float = 0.05
@export var base_crit_multiplier: float = 1.75
@export var element_weakness_multiplier: float = 1.35
@export var element_resist_multiplier: float = 0.7

@export_group("Recursos")
@export var hp_regen_ratio: float = 0.006
@export var mp_regen_ratio: float = 0.02
@export var chi_per_spark: float = 100.0
@export var max_chi: float = 300.0
@export var chi_on_hit_taken: float = 4.0

@export_group("Movimento do jogador")
@export var sprint_multiplier: float = 1.45
@export var dodge_distance: float = 6.0
@export var dodge_duration: float = 0.28
@export var dodge_cooldown: float = 3.0
@export var jump_velocity: float = 5.6
@export var gravity: float = 16.0

@export_group("Masmorra")
@export var respawn_seconds: float = 8.0
@export var potion_cooldown: float = 15.0
@export var loot_pickup_radius: float = 3.2
@export var party_size: int = 4
## Fração do dano normal causado por companheiros: mantém o jogador como protagonista.
@export var bot_damage_multiplier: float = 0.6
