extends Node
## Acesso por id ao conteúdo de res://data/catalog.tres.

const CATALOG_PATH := "res://data/catalog.tres"

var catalog: GameCatalog
var balance: BalanceConfig

var _items: Dictionary[StringName, ItemData] = {}
var _classes: Dictionary[StringName, ClassData] = {}
var _monsters: Dictionary[StringName, MonsterData] = {}
var _dungeons: Dictionary[StringName, DungeonData] = {}


func _ready() -> void:
	reload()


func reload() -> void:
	catalog = load(CATALOG_PATH) as GameCatalog
	if catalog == null:
		push_error("Catálogo ausente: %s" % CATALOG_PATH)
		return
	balance = catalog.balance
	_items.clear()
	_classes.clear()
	_monsters.clear()
	_dungeons.clear()
	for item in catalog.items:
		_items[item.id] = item
	for class_data in catalog.classes:
		_classes[class_data.id] = class_data
	for monster in catalog.monsters:
		_monsters[monster.id] = monster
	for dungeon in catalog.dungeons:
		_dungeons[dungeon.id] = dungeon


func item(id: StringName) -> ItemData:
	return _items.get(id)


func class_by_id(id: StringName) -> ClassData:
	return _classes.get(id)


func monster(id: StringName) -> MonsterData:
	return _monsters.get(id)


func dungeon(id: StringName) -> DungeonData:
	return _dungeons.get(id)


func recipes_for(class_id: StringName) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in catalog.recipes:
		if recipe.result.is_usable_by(class_id):
			result.append(recipe)
	return result
