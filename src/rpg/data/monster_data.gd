class_name MonsterData
extends Resource
## Monstro comum, de elite ou chefe.

enum Tier { NORMAL, ELITE, BOSS }

@export var id: StringName
@export var display_name: String
@export var tier: Tier = Tier.NORMAL
@export var level: int = 1
## Identificador usado por CreatureFactory para montar o modelo.
@export var visual: StringName
@export var scale: float = 1.0
@export var body_radius: float = 0.45
@export var body_height: float = 1.6

@export_group("Atributos")
@export var max_hp: float = 100.0
@export var phys_attack: float = 15.0
@export var magic_attack: float = 15.0
@export var phys_defense: float = 15.0
@export var magic_defense: float = 15.0
@export var move_speed: float = 4.0
@export var attack_element: SkillData.Element = SkillData.Element.NONE
@export var weak_element: SkillData.Element = SkillData.Element.NONE
@export var strong_element: SkillData.Element = SkillData.Element.NONE

@export_group("IA")
@export var aggro_radius: float = 13.0
@export var leash_radius: float = 42.0
@export var preferred_range: float = 1.8
@export var skills: Array[SkillData] = []
@export var phases: Array[BossPhaseData] = []

@export_group("Recompensas")
@export var xp_reward: int = 20
@export var mana_crystals: Vector2i = Vector2i(1, 3)
@export var drops: Array[DropEntry] = []
