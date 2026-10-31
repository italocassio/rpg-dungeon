class_name PartyFrames
extends VBoxContainer
## Painel "Grupo": vida e mana dos companheiros, com atalho F2–F4.


class Row:
	extends PanelContainer
	var unit: Combatant
	var hp: ProgressBar
	var mp: ProgressBar
	var box_normal: StyleBoxFlat
	var box_selected: StyleBoxFlat

	func build(member: Combatant, class_data: ClassData, key: int) -> void:
		unit = member
		box_normal = UiKit.style(Color(0.05, 0.04, 0.03, 0.7), Color.TRANSPARENT, 1, 3)
		box_normal.set_content_margin_all(3)
		box_selected = UiKit.style(Color(0.2, 0.15, 0.06, 0.8), UiKit.GOLD, 1, 3)
		box_selected.set_content_margin_all(3)
		add_theme_stylebox_override(&"panel", box_normal)
		var row := UiKit.hbox(6)
		add_child(row)
		row.add_child(UiKit.icon_tile(class_data.id, class_data.color, 34.0))
		var column := UiKit.vbox(1)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var header := UiKit.hbox(4)
		column.add_child(header)
		header.add_child(UiKit.shadowed(UiKit.label("%s" % member.display_name, 13, UiKit.PAPER), 3))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(spacer)
		header.add_child(UiKit.shadowed(UiKit.label("F%d" % key, 11, UiKit.MUTED), 3))
		hp = UiKit.bar(UiKit.HP_COLOR, 7.0)
		mp = UiKit.bar(UiKit.MP_COLOR, 5.0)
		column.add_child(hp)
		column.add_child(mp)
		member.health_changed.connect(_refresh)
		member.mana_changed.connect(_refresh)
		member.died.connect(func(_k: Combatant) -> void: modulate = Color(0.6, 0.45, 0.45))
		member.revived.connect(func() -> void: modulate = Color.WHITE)
		_refresh(0.0, 0.0)

	func _refresh(_a: float, _b: float) -> void:
		hp.value = unit.hp_ratio()
		mp.value = unit.mp_ratio()

	func set_selected(selected: bool) -> void:
		add_theme_stylebox_override(&"panel", box_selected if selected else box_normal)


var _rows: Array[Row] = []


func bind(combat: PlayerCombat, bots: Array[PartyBot]) -> void:
	custom_minimum_size.x = 210.0
	add_theme_constant_override(&"separation", 3)
	add_child(UiKit.shadowed(UiKit.label("Grupo", 16, UiKit.GOLD, UiKit.title_font())))
	var key: int = 2
	for bot in bots:
		var row := Row.new()
		add_child(row)
		row.build(bot.combatant, bot.sheet.class_data, key)
		_rows.append(row)
		key += 1
	combat.target_changed.connect(_on_target)


func _on_target(target: Combatant) -> void:
	for row in _rows:
		row.set_selected(row.unit == target)
