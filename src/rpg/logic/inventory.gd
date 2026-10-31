class_name Inventory
extends RefCounted
## Inventário com pilhas por id de item e carteira de Cristais de Mana.

signal changed

var mana_crystals: int = 0
var _stacks: Dictionary[StringName, int] = {}


func add(item_id: StringName, count: int = 1) -> void:
	if count <= 0:
		return
	_stacks[item_id] = _stacks.get(item_id, 0) + count
	changed.emit()


func remove(item_id: StringName, count: int = 1) -> bool:
	if count_of(item_id) < count:
		return false
	var remaining: int = _stacks[item_id] - count
	if remaining <= 0:
		_stacks.erase(item_id)
	else:
		_stacks[item_id] = remaining
	changed.emit()
	return true


func count_of(item_id: StringName) -> int:
	return _stacks.get(item_id, 0)


func add_crystals(amount: int) -> void:
	mana_crystals += amount
	changed.emit()


func item_ids() -> Array[StringName]:
	return _stacks.keys()


func to_dict() -> Dictionary:
	var stacks: Dictionary = {}
	for key: StringName in _stacks:
		stacks[String(key)] = _stacks[key]
	return {"mana_crystals": mana_crystals, "stacks": stacks}


func load_dict(data: Dictionary) -> void:
	_stacks.clear()
	mana_crystals = int(data.get("mana_crystals", 0))
	var stacks: Dictionary = data.get("stacks", {})
	for key: String in stacks:
		_stacks[StringName(key)] = int(stacks[key])
	changed.emit()
