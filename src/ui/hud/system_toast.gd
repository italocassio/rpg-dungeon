class_name SystemToast
extends VBoxContainer
## Janelas azuis do "Sistema": avisos importantes em fila, uma por vez.

const HOLD_SECONDS := 3.4
const KIND_COLORS: Dictionary = { "info": Color("d6f2ff"), "reward": Color("ffe6ad"), "warning": Color("ff9a8a"), "quest": Color("8dffb0") }

var _queue: Array[Array] = []
var _panel: PanelContainer
var _title: Label
var _body: Label
var _showing: bool = false


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(&"panel", UiKit.system_style(14))
	_panel.custom_minimum_size.x = 460.0
	_panel.modulate.a = 0.0
	add_child(_panel)
	var column := UiKit.vbox(4)
	_panel.add_child(column)
	_title = UiKit.label("[ SISTEMA ]", 13, UiKit.SYSTEM_LINE, UiKit.bold_font())
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_body = UiKit.label("", 17, UiKit.SYSTEM_TEXT, UiKit.bold_font())
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_body)
	Events.system_message.connect(show_message)


func show_message(text: String, kind: String = "info") -> void:
	_queue.append([text, kind])
	if not _showing:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var entry: Array = _queue.pop_front()
	_body.text = entry[0]
	_body.add_theme_color_override(&"font_color", KIND_COLORS.get(entry[1], UiKit.SYSTEM_TEXT))
	_panel.scale = Vector2(1.0, 0.8)
	_panel.pivot_offset = _panel.size * 0.5
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.14)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_SECONDS if _queue.is_empty() else HOLD_SECONDS * 0.6)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_next)
