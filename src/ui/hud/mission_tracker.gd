class_name MissionTracker
extends VBoxContainer
## Objetivos da masmorra e registro de itens coletados.

const DONE := Color("6fe08a")
const OPEN := Color("ffe6ad")

var _run: DungeonRun
var _lines: Array[Label] = []


func bind(run: DungeonRun) -> void:
	_run = run
	custom_minimum_size.x = 250.0
	add_child(UiKit.shadowed(UiKit.label("Missões", 16, UiKit.GOLD, UiKit.title_font())))
	for i in 3:
		var line := UiKit.shadowed(UiKit.label("", 14), 3)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(line)
		_lines.append(line)
	run.objectives_changed.connect(_refresh)
	_refresh()


func _set_line(index: int, text: String, done: bool) -> void:
	_lines[index].text = ("✓ " if done else "• ") + text
	_lines[index].add_theme_color_override(&"font_color", DONE if done else OPEN)


func _refresh() -> void:
	var required: int = _run.kills_required()
	var kills: int = _run.kills
	if kills < required:
		_set_line(0, "Elimine monstros: %d/%d" % [kills, required], false)
	elif not _run.door_opened:
		_set_line(0, "Abra a Grande Porta", false)
	else:
		_set_line(0, "A Grande Porta está aberta", true)
	_set_line(1, "Derrote %s" % _run.dungeon.boss.display_name, _run.boss_defeated_flag)
	_set_line(2, "Baús encontrados: %d/%d" % [_run.chests_opened, _run.total_chests()], _run.chests_opened >= _run.total_chests())
