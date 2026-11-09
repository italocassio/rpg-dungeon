class_name InventoryView
extends HBoxContainer
## Equipamento vestido e itens da mochila. Clicar em equipamento veste a peça.

const SLOTS: Array[ItemData.Kind] = [ItemData.Kind.WEAPON, ItemData.Kind.HELM, ItemData.Kind.ARMOR, ItemData.Kind.BOOTS]
const TILE := 58.0

var _sheet: CharacterSheet
var _slots: VBoxContainer
var _grid: GridContainer
var _crystals: Label
var _message: Label


func bind(sheet: CharacterSheet) -> void:
	_sheet = sheet
	add_theme_constant_override(&"separation", 18)
	var left := UiKit.vbox(6)
	left.custom_minimum_size.x = 250.0
	add_child(left)
	left.add_child(UiKit.label("Equipado", 16, UiKit.GOLD, UiKit.title_font()))
	_slots = UiKit.vbox(6)
	left.add_child(_slots)
	_crystals = UiKit.label("", 15, Color("7fd4ff"), UiKit.bold_font())
	left.add_child(_crystals)
	_message = UiKit.label("", 13, UiKit.BAD)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_message)

	var right := UiKit.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(right)
	right.add_child(UiKit.label("Mochila", 16, UiKit.GOLD, UiKit.title_font()))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override(&"h_separation", 6)
	_grid.add_theme_constant_override(&"v_separation", 6)
	scroll.add_child(_grid)
	sheet.changed.connect(_refresh)
	sheet.inventory.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _sheet != null:
		_sheet.changed.disconnect(_refresh)
		_sheet.inventory.changed.disconnect(_refresh)


func _refresh() -> void:
	_crystals.text = "Cristais de Mana: %d" % _sheet.inventory.mana_crystals
	for child in _slots.get_children():
		child.queue_free()
	for kind in SLOTS:
		_slots.add_child(_slot_row(kind))
	for child in _grid.get_children():
		child.queue_free()
	var ids: Array[StringName] = _sheet.inventory.item_ids()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var item_a: ItemData = GameDB.item(a)
		var item_b: ItemData = GameDB.item(b)
		return item_a.rarity > item_b.rarity if item_a.rarity != item_b.rarity else item_a.display_name < item_b.display_name)
	for id in ids:
		var item: ItemData = GameDB.item(id)
		if item != null:
			_grid.add_child(_item_tile(item, _sheet.inventory.count_of(id)))


func _slot_row(kind: ItemData.Kind) -> Control:
	var row := UiKit.hbox(8)
	var item: ItemData = _sheet.equipment.get(kind)
	var tint: Color = UiKit.rarity_color(item.rarity) if item != null else UiKit.BRONZE_DARK
	var tile: PanelContainer
	if item != null:
		tile = UiKit.item_tile(item, 46.0)
		tile.tooltip_text = UiKit.item_tooltip(item)
	else:
		tile = UiKit.empty_slot_tile(_empty_slot_icon(kind), 46.0)
	row.add_child(tile)
	var column := UiKit.vbox(0)
	row.add_child(column)
	column.add_child(UiKit.label(ItemData.KIND_NAMES[kind], 12, UiKit.MUTED))
	column.add_child(UiKit.label(item.display_name if item != null else "Vazio", 14, tint if item != null else UiKit.MUTED, UiKit.bold_font()))
	return row


## Silhueta do tipo de peça; arma e armadura dependem da classe.
func _empty_slot_icon(kind: ItemData.Kind) -> StringName:
	var class_data: ClassData = _sheet.class_data
	match kind:
		ItemData.Kind.WEAPON:
			return class_data.starter_weapons[0].icon
		ItemData.Kind.ARMOR:
			return class_data.starter_armors[0].icon
		ItemData.Kind.HELM:
			return &"helm"
	return &"boots"


func _item_tile(item: ItemData, count: int) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2.ONE * TILE
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = UiKit.item_tooltip(item)
	var tint: Color = UiKit.rarity_color(item.rarity)
	button.add_theme_stylebox_override(&"normal", UiKit.style(Color(tint.r * 0.14, tint.g * 0.14, tint.b * 0.14, 0.95), tint, 1, 3))
	button.add_theme_stylebox_override(&"hover", UiKit.style(Color(tint.r * 0.28, tint.g * 0.28, tint.b * 0.28, 0.95), tint.lightened(0.3), 1, 3))
	button.expand_icon = true
	UiKit.set_button_icon(button, item, tint.lightened(0.3), 46, 40)
	var amount := UiKit.shadowed(UiKit.label("x%d" % count, 12, Color.WHITE, UiKit.bold_font()), 3)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.fit_rect(amount, 0.0, 0.0, 1.0, 1.0, Rect2(0.0, 0.0, -4.0, -2.0))
	button.add_child(amount)
	button.pressed.connect(_on_item_pressed.bind(item))
	return button


func _on_item_pressed(item: ItemData) -> void:
	_message.text = ""
	if not item.is_equipment():
		return
	if not item.is_usable_by(_sheet.class_data.id):
		_message.text = "Esta peça é de outra classe."
	elif _sheet.level < item.required_level:
		_message.text = "Requer nível %d." % item.required_level
	else:
		_sheet.equip_from_inventory(item)
