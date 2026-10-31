class_name CharacterView
extends HBoxContainer
## Janela de status no estilo do "Sistema": atributos distribuíveis e valores derivados.

const SHOWN_STATS: Array[StringName] = [&"max_hp", &"max_mp", &"phys_attack", &"magic_attack", &"phys_defense", &"magic_defense", &"crit_chance", &"dodge_chance", &"move_speed"]

var _sheet: CharacterSheet
var _header: Label
var _points: Label
var _attributes: VBoxContainer
var _stats: VBoxContainer


func bind(sheet: CharacterSheet) -> void:
	_sheet = sheet
	add_theme_constant_override(&"separation", 24)
	var left := UiKit.vbox(8)
	left.custom_minimum_size.x = 270.0
	add_child(left)
	_header = UiKit.label("", 17, UiKit.SYSTEM_TEXT, UiKit.bold_font())
	left.add_child(_header)
	_points = UiKit.label("", 14, UiKit.GOOD, UiKit.bold_font())
	left.add_child(_points)
	_attributes = UiKit.vbox(6)
	left.add_child(_attributes)
	_stats = UiKit.vbox(3)
	_stats.custom_minimum_size.x = 250.0
	add_child(_stats)
	sheet.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _sheet != null:
		_sheet.changed.disconnect(_refresh)


func _refresh() -> void:
	_header.text = "%s · Nível %d" % [_sheet.class_data.display_name, _sheet.level]
	_points.text = "Pontos disponíveis: %d" % _sheet.unspent_points
	for child in _attributes.get_children():
		child.queue_free()
	for attribute: StringName in CharacterSheet.ATTRIBUTES:
		var row := UiKit.hbox(8)
		var name_label := UiKit.label(CharacterSheet.ATTRIBUTE_LABELS[attribute], 15, UiKit.SYSTEM_TEXT)
		name_label.custom_minimum_size.x = 130.0
		row.add_child(name_label)
		var value := UiKit.label(str(_sheet.attribute(attribute)), 16, UiKit.GOLD_BRIGHT, UiKit.bold_font())
		value.custom_minimum_size.x = 44.0
		row.add_child(value)
		var plus := UiKit.button("+", func() -> void: _sheet.spend_point(attribute))
		plus.disabled = _sheet.unspent_points <= 0
		row.add_child(plus)
		_attributes.add_child(row)
	for child in _stats.get_children():
		child.queue_free()
	var derived: StatBlock = _sheet.derived_stats()
	for stat in SHOWN_STATS:
		var row := UiKit.hbox(8)
		var name_label := UiKit.label(StatBlock.LABELS[stat], 14, UiKit.MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(UiKit.label(StatBlock.format_value(stat, derived.get(stat)), 14, UiKit.PAPER, UiKit.bold_font()))
		_stats.add_child(row)
