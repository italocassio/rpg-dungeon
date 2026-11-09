extends Node
## Telas que usam a arte de itens e de habilidades, nos tamanhos reais da UI (OS-023).
## godot --display-driver x11 --disable-vsync --resolution 1600x900 --path . res://tests/visual/icon_review.tscn -- --out=DIR
## Cada captura grava `<nome>.png` (recorte 1:1) e `<nome>_x3.png` (o mesmo recorte ampliado 3 vezes, sem suavizar).

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")
const BACKGROUND := Color("1E1C24")
const CLASS_IDS: Array[StringName] = [&"warrior", &"mage", &"priest"]
const SHOT_MARGIN := 8

var _out := "user://icon_review"
var _root: Control


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	Session.save_path = "user://icon_review_save.json"
	Session.reset_all()
	await _hotbars()
	await _inventory_grid()
	await _equipment()
	await _forge()
	await _skill_trees()
	await _lobby_shots()
	DirAccess.remove_absolute(Session.save_path)
	get_tree().quit()


func _new_stage() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.theme = UiKit.theme()
	UiKit.full_rect(_root)
	var background := ColorRect.new()
	background.color = BACKGROUND
	UiKit.full_rect(background)
	_root.add_child(background)
	add_child(_root)


func _sheet(class_id: StringName) -> CharacterSheet:
	return CharacterSheet.new(GameDB.class_by_id(class_id), GameDB.balance)


func _constant(value: Variant) -> Callable:
	return func() -> Variant: return value


func _hotbars() -> void:
	_new_stage()
	var stack := UiKit.vbox(14)
	stack.position = Vector2(20.0, 20.0)
	_root.add_child(stack)
	for class_id in CLASS_IDS:
		var bar := Hotbar.new()
		stack.add_child(bar)
		var slots: Array[SkillSlot] = bar.build_slots(GameDB.class_by_id(class_id))
		_park(slots)
	await _shot("01_hotbars", stack)


## Estados parados: recarga em andamento, sem mana, suprema sem Chi e contagens das poções.
func _park(slots: Array[SkillSlot]) -> void:
	slots[3].ratio_provider = _constant(0.6)
	slots[3].seconds_provider = _constant(5.4)
	slots[5].usable_provider = _constant(false)
	slots[6].ratio_provider = _constant(0.25)
	slots[6].seconds_provider = _constant(4.0)
	slots[6].usable_provider = _constant(false)
	slots[8].count_provider = _constant(3)
	slots[9].count_provider = _constant(12)


func _inventory_grid() -> void:
	_new_stage()
	var sheet: CharacterSheet = _sheet(&"warrior")
	for file_name in DirAccess.get_files_at("res://data/items"):
		if file_name.ends_with(".tres"):
			sheet.inventory.add(StringName(file_name.get_basename()))
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(900.0, 640.0)
	frame.position = Vector2(20.0, 20.0)
	_root.add_child(frame)
	var view := InventoryView.new()
	view.bind(sheet)
	frame.add_child(view)
	await _shot("02_inventory_grid", frame)


func _equipment() -> void:
	_new_stage()
	var row := UiKit.hbox(20)
	row.position = Vector2(20.0, 20.0)
	_root.add_child(row)
	var loadouts: Array[Array] = [
		[&"warrior", [&"warrior_t3_weapon", &"warrior_t1_helm", &"warrior_t3_armor", &"warrior_t1_boots"]],
		[&"mage", []],
		[&"priest", [&"priest_t2_weapon", &"priest_t2_armor"]],
	]
	for loadout in loadouts:
		var sheet: CharacterSheet = _sheet(loadout[0])
		for item_id: StringName in loadout[1]:
			sheet.equip_directly(GameDB.item(item_id))
		# Só a coluna esquerda interessa: o resto da vista fica cortado.
		var clip := Control.new()
		clip.clip_contents = true
		clip.custom_minimum_size = Vector2(260.0, 290.0)
		row.add_child(clip)
		var view := InventoryView.new()
		view.custom_minimum_size = Vector2(900.0, 290.0)
		clip.add_child(view)
		view.bind(sheet)
	await _shot("03_equipment", row)


func _forge() -> void:
	_new_stage()
	var row := UiKit.hbox(20)
	row.position = Vector2(20.0, 20.0)
	_root.add_child(row)
	var picks: Array[Array] = [[&"mage", &"forge_mage_t3_armor"], [&"warrior", &"forge_warrior_t2_weapon"]]
	for pick in picks:
		var sheet: CharacterSheet = _sheet(pick[0])
		var recipe: RecipeData = load("res://data/recipes/%s.tres" % pick[1])
		var index: int = 0
		for ingredient: ItemData in recipe.ingredients:
			var need: int = recipe.ingredients[ingredient]
			sheet.inventory.add(ingredient.id, need if index % 2 == 0 else maxi(need - 1, 0))
			index += 1
		sheet.inventory.add_crystals(recipe.mana_crystal_cost)
		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(760.0, 440.0)
		row.add_child(frame)
		var view := ForgeView.new()
		view.bind(sheet)
		frame.add_child(view)
		view.select(recipe)
	await _shot("04_forge_header", row)


func _skill_trees() -> void:
	for class_id in CLASS_IDS:
		_new_stage()
		var sheet: CharacterSheet = _sheet(class_id)
		sheet.equip_directly(sheet.class_data.starter_weapons[0])
		sheet.equip_directly(sheet.class_data.starter_armors[0])
		var frame := PanelContainer.new()
		frame.custom_minimum_size = SkillTreeView.WINDOW_SIZE
		frame.position = Vector2(20.0, 20.0)
		_root.add_child(frame)
		var view := SkillTreeView.new()
		frame.add_child(view)
		var describe := func(skill: SkillData) -> SkillInfo: return SkillInfo.describe(skill, sheet.derived_stats(), sheet.balance)
		view.bind(sheet, describe)
		await _shot("07_skill_tree_%s" % class_id, frame)


func _lobby_shots() -> void:
	if _root != null:
		_root.queue_free()
		_root = null
	Session.reset_all()
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await _wait(40)
	var lobby: Lobby = main.find_children("*", "Lobby", true, false)[0]
	for class_id in CLASS_IDS:
		lobby._on_class_chosen(GameDB.class_by_id(class_id))
		await _wait(6)
		var first: Control = lobby._page.find_child("Skill_%s" % lobby.selected_class.basic_attack.id, true, false)
		await _shot("05_lobby_skills_%s" % class_id, first.get_parent())
	lobby._on_class_chosen(GameDB.class_by_id(&"warrior"))
	lobby.open_tab(&"gear")
	await _wait(6)
	await _shot("06_lobby_item_choice", lobby._page)


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _shot(shot_name: String, control: Control) -> void:
	await _wait(4)
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var area := Rect2i(control.get_global_rect().grow(SHOT_MARGIN))
	area = area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var crop: Image = image.get_region(area)
	crop.save_png("%s/%s.png" % [_out, shot_name])
	crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	crop.save_png("%s/%s_x3.png" % [_out, shot_name])
