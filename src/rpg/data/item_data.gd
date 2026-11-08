class_name ItemData
extends Resource
## Definição estática de um item (material, consumível ou equipamento).

enum Kind { MATERIAL, CONSUMABLE, WEAPON, HELM, ARMOR, BOOTS }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const EQUIPMENT_KINDS: Array[Kind] = [Kind.WEAPON, Kind.HELM, Kind.ARMOR, Kind.BOOTS]
const KIND_NAMES: Dictionary = {
	Kind.MATERIAL: "Material", Kind.CONSUMABLE: "Consumível", Kind.WEAPON: "Arma",
	Kind.HELM: "Elmo", Kind.ARMOR: "Armadura", Kind.BOOTS: "Botas",
}
const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Comum", Rarity.UNCOMMON: "Incomum", Rarity.RARE: "Raro",
	Rarity.EPIC: "Épico", Rarity.LEGENDARY: "Lendário",
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: Kind = Kind.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export var icon: StringName = &"crystal"

@export_group("Equipamento")
@export var class_id: StringName
@export var required_level: int = 1
@export var stat_bonuses: Dictionary[StringName, float] = {}
@export var weapon_model: StringName
## Forma do modelo (HeroLook): 0 a 3, igual ao tier da receita. T0 são os itens iniciais.
@export_range(0, 3) var look_tier: int = 0
## Segundo desenho do mesmo tier. Só os itens iniciais usam 1.
@export_range(0, 1) var look_variant: int = 0

@export_group("Consumível")
@export_range(0.0, 1.0) var restores_hp_ratio: float = 0.0
@export_range(0.0, 1.0) var restores_mp_ratio: float = 0.0


func is_equipment() -> bool:
	return kind in EQUIPMENT_KINDS


func is_usable_by(class_identifier: StringName) -> bool:
	return class_id == &"" or class_id == class_identifier
