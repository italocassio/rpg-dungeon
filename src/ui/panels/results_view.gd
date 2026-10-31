class_name ResultsView
extends VBoxContainer
## Relatório do Sistema ao concluir o Portão.

signal return_requested


func bind(run: DungeonRun, seconds: float) -> void:
	add_theme_constant_override(&"separation", 8)
	_line("Rank do Portão", run.rank.label)
	_line("Tempo", "%d min %02d s" % [int(seconds) / 60, int(seconds) % 60])
	_line("Monstros eliminados", str(run.kills))
	_line("Experiência", "+%d" % run.xp_gained)
	_line("Cristais de Mana", "+%d" % run.crystals_gained)
	add_child(UiKit.label("Itens obtidos", 15, UiKit.SYSTEM_LINE, UiKit.bold_font()))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 22)
	scroll.add_child(grid)
	var ids: Array[StringName] = run.loot_log.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return GameDB.item(a).rarity > GameDB.item(b).rarity)
	for id in ids:
		var item: ItemData = GameDB.item(id)
		grid.add_child(UiKit.label("%s  x%d" % [item.display_name, run.loot_log[id]], 14, UiKit.rarity_color(item.rarity), UiKit.bold_font()))
	add_child(UiKit.button("Voltar ao Salão dos Caçadores", func() -> void: return_requested.emit(), 17))


func _line(caption: String, value: String) -> void:
	var row := UiKit.hbox(8)
	var left := UiKit.label(caption, 15, UiKit.SYSTEM_TEXT)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(UiKit.label(value, 15, UiKit.GOLD_BRIGHT, UiKit.bold_font()))
	add_child(row)
