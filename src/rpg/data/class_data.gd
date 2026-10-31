class_name ClassData
extends Resource
## Classe jogável. Crescimento e atributos definidos por dados.

enum Role { TANK, DAMAGE, HEALER }
enum ArmorType { HEAVY, LIGHT, ARCANE }

const ARMOR_NAMES: Dictionary = {
	ArmorType.HEAVY: "Pesada", ArmorType.LIGHT: "Leve", ArmorType.ARCANE: "Arcana",
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var role: Role = Role.DAMAGE
@export var armor_type: ArmorType = ArmorType.LIGHT
@export var color: Color = Color.WHITE

@export_group("Atributos base")
@export var strength: int = 5
@export var vitality: int = 5
@export var agility: int = 5
@export var intelligence: int = 5
@export var base_hp: float = 200.0
@export var base_mp: float = 100.0
@export var hp_per_level: float = 30.0
@export var mp_per_level: float = 20.0
@export var base_move_speed: float = 6.0

@export_group("Habilidades")
@export var basic_attack: SkillData
@export var skills: Array[SkillData] = []
@export var ultimate: SkillData

@export_group("Postura de defesa (botão direito)")
@export var guard_name: String = "Bloquear"
@export_range(0.0, 1.0) var guard_damage_multiplier: float = 0.5
@export var guard_mp_per_second: float = 0.0

@export_group("Itens iniciais à escolha")
@export var starter_weapons: Array[ItemData] = []
@export var starter_armors: Array[ItemData] = []
