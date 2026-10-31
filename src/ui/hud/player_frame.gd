class_name PlayerFrame
extends HBoxContainer
## Canto superior esquerdo: retrato, vida, mana, experiência e faíscas de Chi.

var _combatant: Combatant
var _sheet: CharacterSheet
var _hp: ProgressBar
var _mp: ProgressBar
var _xp: ProgressBar
var _hp_text: Label
var _mp_text: Label
var _xp_text: Label
var _level: Label
var _sparks: Array[Panel] = []
var _effects: HBoxContainer


func bind(unit: Combatant, sheet: CharacterSheet) -> void:
	_combatant = unit
	_sheet = sheet
	add_theme_constant_override(&"separation", 8)
	var class_data: ClassData = sheet.class_data
	var portrait := UiKit.icon_tile(class_data.id, class_data.color, 76.0)
	add_child(portrait)
	_level = UiKit.shadowed(UiKit.label("", 15, UiKit.GOLD_BRIGHT, UiKit.bold_font()))
	_level.size_flags_vertical = Control.SIZE_SHRINK_END
	portrait.add_child(_level)

	var column := UiKit.vbox(2)
	column.custom_minimum_size.x = 230.0
	add_child(column)
	var header := UiKit.hbox(8)
	column.add_child(header)
	header.add_child(UiKit.shadowed(UiKit.label(unit.display_name, 15, UiKit.GOLD_BRIGHT, UiKit.bold_font())))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	for i in 3:
		var spark := Panel.new()
		spark.custom_minimum_size = Vector2(13.0, 13.0)
		header.add_child(spark)
		_sparks.append(spark)

	_hp = UiKit.bar(UiKit.HP_COLOR, 16.0)
	_hp_text = _bar_text(_hp)
	column.add_child(_hp)
	_mp = UiKit.bar(UiKit.MP_COLOR, 13.0)
	_mp_text = _bar_text(_mp)
	column.add_child(_mp)
	_xp = UiKit.bar(UiKit.XP_COLOR, 9.0)
	_xp_text = _bar_text(_xp)
	_xp_text.add_theme_font_size_override(&"font_size", 10)
	column.add_child(_xp)
	_effects = UiKit.hbox(3)
	column.add_child(_effects)

	unit.health_changed.connect(_on_health)
	unit.mana_changed.connect(_on_mana)
	unit.chi_changed.connect(_on_chi)
	unit.effects_changed.connect(_on_effects)
	sheet.changed.connect(_on_sheet)
	_on_health(unit.hp, unit.stats.max_hp)
	_on_mana(unit.mp, unit.stats.max_mp)
	_on_chi(unit.chi)
	_on_sheet()


func _bar_text(bar: ProgressBar) -> Label:
	var text := UiKit.shadowed(UiKit.label("", 12, Color.WHITE, UiKit.bold_font()), 3)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.full_rect(text)
	bar.add_child(text)
	return text


func _on_health(current: float, maximum: float) -> void:
	_hp.value = current / maxf(maximum, 1.0)
	_hp_text.text = "%d / %d" % [ceili(current), maximum]


func _on_mana(current: float, maximum: float) -> void:
	_mp.value = current / maxf(maximum, 1.0)
	_mp_text.text = "%d / %d" % [floori(current), maximum]


func _on_chi(current: float) -> void:
	var lit: int = int(current / _combatant.balance.chi_per_spark)
	var partial: float = fmod(current, _combatant.balance.chi_per_spark) / _combatant.balance.chi_per_spark
	for i in _sparks.size():
		var color: Color = Color("ff4a2e") if i < lit else Color(0.28 + partial * 0.3 * float(i == lit), 0.1, 0.08)
		var box: StyleBoxFlat = UiKit.style(color, UiKit.BRONZE, 1, 7)
		_sparks[i].add_theme_stylebox_override(&"panel", box)


func _on_sheet() -> void:
	_level.text = str(_sheet.level)
	_xp.value = _sheet.xp_ratio()
	_xp_text.text = "%.1f%%" % (_sheet.xp_ratio() * 100.0)


func _on_effects() -> void:
	for child in _effects.get_children():
		child.queue_free()
	for effect in _combatant.effects:
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(18.0, 18.0)
		chip.add_theme_stylebox_override(&"panel", UiKit.style(effect.data.color.darkened(0.45), effect.data.color, 1, 2))
		chip.tooltip_text = effect.data.display_name
		_effects.add_child(chip)
