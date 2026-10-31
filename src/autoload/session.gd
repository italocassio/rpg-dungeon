extends Node
## Sessão do jogador: fichas salvas por classe, personagem ativo e dados da partida atual.

const SAVE_PATH := "user://hunter_save.json"
const SAVE_VERSION := 1

var player_name: String = "Caçador"
var sheets: Dictionary[StringName, CharacterSheet] = {}
var active_sheet: CharacterSheet
var party: Array[PartyMember] = []
var active_dungeon: DungeonData
var active_rank: GateRankData
## Caminho alternativo de save (usado pelos testes para não tocar no save real).
var save_path: String = SAVE_PATH


func has_sheet(class_id: StringName) -> bool:
	return sheets.has(class_id)


## Seleciona a classe. Na primeira vez cria a ficha com os itens iniciais escolhidos.
func select_class(class_data: ClassData, weapon: ItemData = null, armor: ItemData = null) -> CharacterSheet:
	if not sheets.has(class_data.id):
		var sheet := CharacterSheet.new(class_data, GameDB.balance)
		sheet.equip_directly(weapon if weapon != null else class_data.starter_weapons[0])
		sheet.equip_directly(armor if armor != null else class_data.starter_armors[0])
		sheet.inventory.add(&"potion_hp", 5)
		sheet.inventory.add(&"potion_mp", 5)
		sheets[class_data.id] = sheet
	active_sheet = sheets[class_data.id]
	return active_sheet


func begin_run(dungeon: DungeonData, rank: GateRankData, members: Array[PartyMember]) -> void:
	active_dungeon = dungeon
	active_rank = rank
	party = members


func save_game() -> bool:
	var characters: Dictionary = {}
	for key: StringName in sheets:
		characters[String(key)] = sheets[key].to_dict()
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"active_class": String(active_sheet.class_data.id) if active_sheet != null else "",
		"characters": characters,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Não foi possível salvar em %s" % save_path)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK or not json.data is Dictionary:
		push_warning("Save corrompido ignorado.")
		return false
	var parsed: Dictionary = json.data
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		push_warning("Save de versão incompatível ignorado.")
		return false
	sheets.clear()
	active_sheet = null
	player_name = parsed.get("player_name", player_name)
	var characters: Dictionary = parsed.get("characters", {})
	for key: String in characters:
		var class_data: ClassData = GameDB.class_by_id(StringName(key))
		if class_data == null:
			continue
		var sheet := CharacterSheet.new(class_data, GameDB.balance)
		sheet.load_dict(characters[key], GameDB.item)
		sheets[class_data.id] = sheet
	var active_id := StringName(parsed.get("active_class", ""))
	active_sheet = sheets.get(active_id)
	return true


func reset_all() -> void:
	sheets.clear()
	active_sheet = null
