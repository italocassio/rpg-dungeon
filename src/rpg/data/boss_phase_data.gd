class_name BossPhaseData
extends Resource
## Fase de chefe, ativada ao cair abaixo de hp_ratio.

@export_range(0.0, 1.0) var hp_ratio: float = 0.6
@export var announcement: String
@export var skills: Array[SkillData] = []
@export var speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var summon_id: StringName
@export var summon_count: int = 0
