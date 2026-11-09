class_name SkillCard
extends VBoxContainer
## Mostra um SkillInfo. Sem fundo próprio: serve no painel bronze e na janela azul do Sistema.

const ICON_SIZE := 46.0
const ROW_COLORS: Dictionary[StringName, Color] = {
	&"damage": UiKit.BAD, &"heal": UiKit.GOOD, &"area": UiKit.SYSTEM_TEXT,
	&"effect": UiKit.GOLD_BRIGHT, &"cost": Color("7fd4ff"), &"time": UiKit.PAPER,
}

var _name: Label
var _subtitle: Label
var _description: Label
var _rows: GridContainer
var _footer: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 8)


func show_info(info: SkillInfo) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var skill: SkillData = info.skill
	var header := UiKit.hbox(10)
	add_child(header)
	header.add_child(UiKit.skill_tile(skill, ICON_SIZE))
	var titles := UiKit.vbox(0)
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_name = UiKit.label(skill.display_name, 18, UiKit.GOLD_BRIGHT, UiKit.bold_font())
	titles.add_child(_name)
	_subtitle = UiKit.label(info.subtitle, 12, UiKit.MUTED)
	titles.add_child(_subtitle)
	_description = _wrapped(skill.description, 14, UiKit.PAPER)
	add_child(_description)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override(&"h_separation", 12)
	_rows.add_theme_constant_override(&"v_separation", 4)
	add_child(_rows)
	for row in info.rows:
		_rows.add_child(UiKit.label(row.label, 13, UiKit.MUTED))
		var value := _wrapped(row.value, 13, ROW_COLORS[row.kind])
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rows.add_child(value)
	_footer = _wrapped(info.footer, 12, UiKit.MUTED)
	_footer.visible = not info.footer.is_empty()
	add_child(_footer)


## O que está de fato nos rótulos, no mesmo formato de SkillInfo.plain_text().
func shown_text() -> String:
	var lines: Array[String] = [_name.text, _subtitle.text, _description.text]
	var cells: Array[Node] = _rows.get_children()
	for i in range(0, cells.size(), 2):
		lines.append("%s: %s" % [(cells[i] as Label).text, (cells[i + 1] as Label).text])
	if _footer.visible:
		lines.append(_footer.text)
	return "\n".join(lines)


func _wrapped(text: String, size: int, color: Color) -> Label:
	var node := UiKit.label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node
