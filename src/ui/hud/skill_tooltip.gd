class_name SkillTooltip
extends CanvasLayer
## Card flutuante de habilidade. Fica acima das janelas e funciona na pausa, ao contrário do HUD.
## Usa um painel próprio porque o tooltip nativo não ancora no slot nem some ao soltar o cursor.

const SHOW_DELAY := 0.15
const GAP := 8.0
const WIDTH := 360.0
const SCREEN_MARGIN := 10.0

var _describe: Callable = Callable()
var _panel: PanelContainer
var _card: SkillCard
var _anchor: Control
var _skill: SkillData
var _delay_left: float = 0.0
var _cursor_free: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	# CanvasLayer corta a herança de tema.
	_panel.theme = UiKit.theme()
	var box: StyleBoxFlat = UiKit.panel_style(12)
	# O card flutua sobre texto: com a transparência padrão, as linhas de trás vazam para a leitura.
	box.bg_color.a = 0.97
	_panel.add_theme_stylebox_override(&"panel", box)
	_panel.custom_minimum_size.x = WIDTH
	_panel.visible = false
	add_child(_panel)
	_card = SkillCard.new()
	_panel.add_child(_card)
	_ignore_mouse(_panel)
	set_process(false)


## `describe` recebe a SkillData e devolve o SkillInfo: a UI nunca toca em atributos ou balanceamento.
func setup(describe: Callable, cursor_free: bool = false) -> void:
	_describe = describe
	_cursor_free = cursor_free


func attach(anchor: Control, skill: SkillData) -> void:
	anchor.mouse_entered.connect(_on_anchor_entered.bind(anchor, skill))
	anchor.mouse_exited.connect(_on_anchor_exited.bind(anchor))


func set_cursor_free(free: bool) -> void:
	if free == _cursor_free:
		return
	_cursor_free = free
	if free and _anchor_is_under_mouse():
		_arm()
	else:
		_close()


## Fecha o card sem travar o cursor: um novo hover volta a abri-lo.
func dismiss() -> void:
	_close()


func is_open() -> bool:
	return _panel.visible


func shown_text() -> String:
	return _card.shown_text()


## Acima da âncora; embaixo se não couber. `bounds` é a área útil da tela.
static func placement(anchor: Rect2, card_size: Vector2, bounds: Rect2) -> Vector2:
	var y: float = anchor.position.y - card_size.y - GAP
	if y < bounds.position.y:
		y = anchor.end.y + GAP
	var x: float = anchor.get_center().x - card_size.x * 0.5
	var limit: Vector2 = bounds.end - card_size
	return Vector2(maxf(minf(x, limit.x), bounds.position.x), maxf(minf(y, limit.y), bounds.position.y))


func _on_anchor_entered(anchor: Control, skill: SkillData) -> void:
	_anchor = anchor
	_skill = skill
	_arm()


func _on_anchor_exited(anchor: Control) -> void:
	if anchor != _anchor:
		return
	_anchor = null
	_skill = null
	_close()


func _anchor_is_under_mouse() -> bool:
	return is_instance_valid(_anchor) and _anchor.get_global_rect().has_point(_anchor.get_global_mouse_position())


func _arm() -> void:
	_panel.visible = false
	if not _cursor_free:
		set_process(false)
		return
	_delay_left = SHOW_DELAY
	set_process(true)


func _close() -> void:
	_panel.visible = false
	set_process(false)


func _process(delta: float) -> void:
	# A âncora pode ser liberada sem aviso: abas do saguão são recriadas com queue_free.
	if not is_instance_valid(_anchor) or _anchor.is_queued_for_deletion() or not _anchor.is_visible_in_tree():
		_anchor = null
		_close()
		return
	if _panel.visible:
		_fit()
		return
	_delay_left -= delta
	if _delay_left <= 0.0:
		_open()


func _open() -> void:
	if not _describe.is_valid():
		return
	_card.show_info(_describe.call(_skill))
	_ignore_mouse(_card)
	# A altura só é conhecida depois que o texto quebra: invisível até o primeiro ajuste, para não saltar.
	_panel.modulate.a = 0.0
	_panel.visible = true


func _fit() -> void:
	_panel.reset_size()
	_panel.position = placement(_anchor.get_global_rect(), _panel.size, _panel.get_viewport_rect().grow(-SCREEN_MARGIN))
	_panel.modulate.a = 1.0


## Um Control sob o cursor numa camada superior roubaria o hover do slot, e o card ficaria piscando.
func _ignore_mouse(node: Node) -> void:
	var control := node as Control
	if control != null:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
