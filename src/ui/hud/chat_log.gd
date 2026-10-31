class_name ChatLog
extends PanelContainer
## Registro de chat e combate. As mensagens globais simulam a vida de um servidor MMO.

const MAX_LINES := 60
const CHANNELS: Dictionary = { "GLOBAL": "e8c98a", "GRUPO": "8dffb0", "SISTEMA": "4fc3ff", "COMBATE": "c8c0b0" }
const WORLD_CHATTER: Array[Array] = [
	["Torvald", "Clã Aurora recruta caçador rank D, ajudamos no portão!"],
	["Marcelo", "COMPRO Núcleo do Rei Gélido, pago em cristais"],
	["Lucas", "vagas pra portão rank E, falta sacerdote"],
	["Sávio", "vendo Ferro Negro, chama PM"],
	["Renan", "alguém já forjou o conjunto Real?"],
	["Rafa", "dica: chefe é fraco contra Fogo"],
	["Nico", "o Inverno Absoluto do Rei me pegou de novo kkk"],
	["Kenji", "abriu portão vermelho em Recife de novo?"],
]

var _text: RichTextLabel
var _timer: float = 8.0
var _next_line: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(380.0, 196.0)
	add_theme_stylebox_override(&"panel", UiKit.style(Color(0.02, 0.03, 0.05, 0.55), Color(UiKit.BRONZE, 0.5), 1, 3))
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.fit_content = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override(&"normal_font_size", 13)
	_text.add_theme_font_override(&"normal_font", UiKit.body_font())
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UiKit.margin(_text, 8, 6, 8, 6))
	_text.get_v_scroll_bar().scale = Vector2.ZERO
	Events.chat_message.connect(add_message)
	Events.combat_log.connect(func(text: String, color: Color) -> void: _append("[color=#%s]%s[/color]" % [color.to_html(false), text]))
	Events.system_message.connect(func(text: String, _kind: String) -> void: add_message("SISTEMA", "", text))
	Events.loot_collected.connect(func(item: ItemData, count: int) -> void:
		var color: Color = UiKit.rarity_color(item.rarity)
		_append("[color=#%s]Você obteve: %s x%d[/color]" % [color.to_html(false), item.display_name, count]))


func add_message(channel: String, author: String, text: String) -> void:
	var color: String = CHANNELS.get(channel, "e6dcc6")
	var prefix: String = "[%s] " % channel
	var who: String = "%s: " % author if author != "" else ""
	_append("[color=#%s]%s%s[/color]%s" % [color, prefix.replace("[", "[lb]"), who, text])


func _append(line: String) -> void:
	_text.append_text(line + "\n")
	while _text.get_paragraph_count() > MAX_LINES:
		_text.remove_paragraph(0)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(9.0, 20.0)
	var line: Array = WORLD_CHATTER[_next_line % WORLD_CHATTER.size()]
	_next_line += 1
	add_message("GLOBAL", line[0], line[1])
