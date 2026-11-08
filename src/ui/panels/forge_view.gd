class_name ForgeView
extends HBoxContainer
## Forja: lista receitas por nível, mostra custo e consome os materiais.

const TIER_NAMES: Dictionary = { 1: "Conjunto Gélido", 2: "Conjunto Real  (itens do chefe)", 3: "Conjunto do Rei Gélido  (Rank D)" }
const FAILURE_TEXT: Dictionary = {
	Forge.Failure.MISSING_MATERIALS: "Materiais insuficientes",
	Forge.Failure.MISSING_CRYSTALS: "Cristais de Mana insuficientes",
	Forge.Failure.WRONG_CLASS: "Receita de outra classe",
}

signal forged(item: ItemData)

var _sheet: CharacterSheet
var _list: VBoxContainer
var _detail: VBoxContainer
var _selected: RecipeData


func bind(sheet: CharacterSheet) -> void:
	_sheet = sheet
	add_theme_constant_override(&"separation", 16)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 340.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = UiKit.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_detail = UiKit.vbox(6)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_detail)
	var recipes: Array[RecipeData] = GameDB.recipes_for(sheet.class_data.id)
	_selected = recipes[0] if not recipes.is_empty() else null
	sheet.inventory.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _sheet != null:
		_sheet.inventory.changed.disconnect(_refresh)


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var current_tier: int = 0
	for recipe in GameDB.recipes_for(_sheet.class_data.id):
		if recipe.tier != current_tier:
			current_tier = recipe.tier
			_list.add_child(UiKit.label(TIER_NAMES.get(current_tier, "Nível %d" % current_tier), 14, UiKit.GOLD, UiKit.title_font()))
		_list.add_child(_recipe_row(recipe))
	_show_detail()


func _recipe_row(recipe: RecipeData) -> Button:
	var item: ItemData = recipe.result
	var button := Button.new()
	var ready_to_forge: bool = Forge.check(recipe, _sheet) == Forge.Failure.NONE
	button.text = ("● " if ready_to_forge else "") + item.display_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.icon = UiKit.icon(item.icon)
	button.expand_icon = false
	button.add_theme_constant_override(&"icon_max_width", 24)
	var tint: Color = UiKit.rarity_color(item.rarity)
	button.add_theme_color_override(&"font_color", tint if recipe != _selected else UiKit.GOLD_BRIGHT)
	button.add_theme_color_override(&"icon_normal_color", tint)
	button.pressed.connect(func() -> void:
		_selected = recipe
		_refresh())
	return button


func _show_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()
	if _selected == null:
		return
	var item: ItemData = _selected.result
	var head := UiKit.hbox(10)
	_detail.add_child(head)
	head.add_child(UiKit.icon_tile(item.icon, UiKit.rarity_color(item.rarity), 64.0))
	var column := UiKit.vbox(2)
	head.add_child(column)
	column.add_child(UiKit.label(item.display_name, 19, UiKit.rarity_color(item.rarity), UiKit.title_font()))
	column.add_child(UiKit.label("%s · %s · nível %d" % [ItemData.RARITY_NAMES[item.rarity], ItemData.KIND_NAMES[item.kind], item.required_level], 13, UiKit.MUTED))
	for stat: StringName in item.stat_bonuses:
		var value: float = item.stat_bonuses[stat]
		if value == 0.0:
			continue
		var text: String = "%+.0f %s" % [value, StatBlock.LABELS.get(stat, stat)] if absf(value) >= 1.0 else "%+.0f%% %s" % [value * 100.0, StatBlock.LABELS.get(stat, stat)]
		_detail.add_child(UiKit.label(text, 14, UiKit.GOOD))
	_detail.add_child(UiKit.label("Materiais", 14, UiKit.GOLD, UiKit.title_font()))
	for ingredient: ItemData in _selected.ingredients:
		var need: int = _selected.ingredients[ingredient]
		var have: int = _sheet.inventory.count_of(ingredient.id)
		var row := UiKit.hbox(8)
		row.add_child(UiKit.icon_tile(ingredient.icon, UiKit.rarity_color(ingredient.rarity), 28.0))
		var name_label := UiKit.label(ingredient.display_name, 14, UiKit.rarity_color(ingredient.rarity))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(UiKit.label("%d / %d" % [have, need], 14, UiKit.GOOD if have >= need else UiKit.BAD, UiKit.bold_font()))
		row.get_child(0).tooltip_text = ingredient.description
		_detail.add_child(row)
	var crystals: int = _sheet.inventory.mana_crystals
	var cost_row := UiKit.hbox(8)
	var cost_label := UiKit.label("Cristais de Mana", 14, Color("7fd4ff"))
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_row.add_child(cost_label)
	cost_row.add_child(UiKit.label("%d / %d" % [crystals, _selected.mana_crystal_cost], 14, UiKit.GOOD if crystals >= _selected.mana_crystal_cost else UiKit.BAD, UiKit.bold_font()))
	_detail.add_child(cost_row)
	var failure: Forge.Failure = Forge.check(_selected, _sheet)
	var forge_button := UiKit.button("Forjar", _on_forge, 18)
	forge_button.disabled = failure != Forge.Failure.NONE
	_detail.add_child(forge_button)
	if failure != Forge.Failure.NONE:
		_detail.add_child(UiKit.label(FAILURE_TEXT[failure], 13, UiKit.BAD))


func _on_forge() -> void:
	var recipe: RecipeData = _selected
	if Forge.craft(recipe, _sheet):
		Events.system_message.emit("Forja concluída: %s" % recipe.result.display_name, "reward")
		forged.emit(recipe.result)
		Session.save_game()
