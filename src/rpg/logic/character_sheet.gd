class_name CharacterSheet
extends RefCounted
## Ficha do personagem: nível, atributos, equipamento e inventário.

signal changed
signal leveled_up(new_level: int)

const ATTRIBUTES: Array[StringName] = [&"strength", &"vitality", &"agility", &"intelligence"]
const ATTRIBUTE_LABELS: Dictionary = {
	&"strength": "Força", &"vitality": "Vitalidade", &"agility": "Agilidade", &"intelligence": "Inteligência",
}

var class_data: ClassData
var balance: BalanceConfig
var level: int = 1
var xp: int = 0
var unspent_points: int = 0
var bonus_attributes: Dictionary[StringName, int] = {}
var equipment: Dictionary[ItemData.Kind, ItemData] = {}
var inventory := Inventory.new()


func _init(from_class: ClassData, config: BalanceConfig) -> void:
	class_data = from_class
	balance = config
	for attribute in ATTRIBUTES:
		bonus_attributes[attribute] = 0


func attribute(name: StringName) -> int:
	return int(class_data.get(name)) + bonus_attributes.get(name, 0)


func xp_to_next_level() -> int:
	return roundi(balance.xp_base * pow(float(level), balance.xp_exponent))


func is_max_level() -> bool:
	return level >= balance.max_level


func xp_ratio() -> float:
	return 1.0 if is_max_level() else float(xp) / float(xp_to_next_level())


func add_xp(amount: int) -> int:
	var gained_levels: int = 0
	if is_max_level():
		return 0
	xp += amount
	while not is_max_level() and xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		unspent_points += balance.attribute_points_per_level
		gained_levels += 1
		leveled_up.emit(level)
	if is_max_level():
		xp = 0
	changed.emit()
	return gained_levels


func spend_point(name: StringName) -> bool:
	if unspent_points <= 0 or name not in ATTRIBUTES:
		return false
	unspent_points -= 1
	bonus_attributes[name] += 1
	changed.emit()
	return true


## Bots distribuem pontos automaticamente conforme o papel da classe.
func auto_spend_points() -> void:
	var primary: StringName = &"strength" if class_data.role == ClassData.Role.TANK else &"intelligence"
	while unspent_points >= 2:
		spend_point(primary)
		spend_point(&"vitality")
	if unspent_points > 0:
		spend_point(primary)


func can_equip(item: ItemData) -> bool:
	return item != null and item.is_equipment() and item.is_usable_by(class_data.id) and level >= item.required_level


## O item vem do inventário; o item substituído volta para ele.
func equip_from_inventory(item: ItemData) -> bool:
	if not can_equip(item) or not inventory.remove(item.id):
		return false
	var previous: ItemData = equipment.get(item.kind)
	equipment[item.kind] = item
	if previous != null:
		inventory.add(previous.id)
	changed.emit()
	return true


func equip_directly(item: ItemData) -> void:
	equipment[item.kind] = item
	changed.emit()


func weapon_model() -> StringName:
	var weapon: ItemData = equipment.get(ItemData.Kind.WEAPON)
	return weapon.weapon_model if weapon != null else &""


func derived_stats() -> StatBlock:
	var stats := StatBlock.new()
	var strength: int = attribute(&"strength")
	var vitality: int = attribute(&"vitality")
	var agility: int = attribute(&"agility")
	var intelligence: int = attribute(&"intelligence")
	var levels: float = float(level - 1)

	stats.max_hp = class_data.base_hp + class_data.hp_per_level * levels + vitality * balance.hp_per_vitality
	stats.max_mp = class_data.base_mp + class_data.mp_per_level * levels + intelligence * balance.mp_per_intelligence
	stats.phys_attack = 4.0 + strength * balance.attack_per_strength
	stats.magic_attack = 4.0 + intelligence * balance.magic_attack_per_intelligence
	stats.phys_defense = 4.0 + vitality * balance.phys_defense_per_vitality
	stats.magic_defense = 4.0 + intelligence * balance.magic_defense_per_intelligence
	stats.crit_chance = balance.base_crit_chance + agility * balance.crit_per_agility
	stats.crit_multiplier = balance.base_crit_multiplier
	stats.dodge_chance = agility * balance.dodge_per_agility
	stats.move_speed = class_data.base_move_speed + agility * balance.move_speed_per_agility

	for kind: ItemData.Kind in equipment:
		stats.add_bonuses(equipment[kind].stat_bonuses)
	return stats


func to_dict() -> Dictionary:
	var gear: Dictionary = {}
	for kind: ItemData.Kind in equipment:
		gear[str(int(kind))] = String(equipment[kind].id)
	var attributes: Dictionary = {}
	for key: StringName in bonus_attributes:
		attributes[String(key)] = bonus_attributes[key]
	return {
		"class_id": String(class_data.id),
		"level": level,
		"xp": xp,
		"unspent_points": unspent_points,
		"attributes": attributes,
		"equipment": gear,
		"inventory": inventory.to_dict(),
	}


func load_dict(data: Dictionary, resolve_item: Callable) -> void:
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	unspent_points = int(data.get("unspent_points", 0))
	var attributes: Dictionary = data.get("attributes", {})
	for key: String in attributes:
		bonus_attributes[StringName(key)] = int(attributes[key])
	equipment.clear()
	var gear: Dictionary = data.get("equipment", {})
	for key: String in gear:
		var item: ItemData = resolve_item.call(StringName(gear[key]))
		if item != null:
			equipment[item.kind] = item
	inventory.load_dict(data.get("inventory", {}))
	_drop_unknown_items(resolve_item)
	changed.emit()


## Saves antigos podem citar itens removidos do jogo: nada disso pode quebrar o carregamento.
func _drop_unknown_items(resolve_item: Callable) -> void:
	for id in inventory.item_ids():
		if resolve_item.call(id) == null:
			inventory.remove(id, inventory.count_of(id))
	if not equipment.has(ItemData.Kind.WEAPON):
		equipment[ItemData.Kind.WEAPON] = class_data.starter_weapons[0]
	if not equipment.has(ItemData.Kind.ARMOR):
		equipment[ItemData.Kind.ARMOR] = class_data.starter_armors[0]
