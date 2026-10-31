extends Node
## Fluxo do jogo: saguão -> masmorra -> saguão.

var _stage: LobbyStage
var _lobby_layer: CanvasLayer
var _screen: Node


func _ready() -> void:
	Session.load_game()
	show_lobby()


## Fechar a janela no meio da partida não pode perder o que já foi coletado.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and Session.active_sheet != null:
		Session.save_game()


func _clear() -> void:
	for node: Node in [_stage, _lobby_layer, _screen]:
		if node != null:
			node.queue_free()
	_stage = null
	_lobby_layer = null
	_screen = null


func show_lobby() -> void:
	_clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var dungeon: DungeonData = GameDB.catalog.dungeons[0]
	_stage = LobbyStage.new()
	add_child(_stage)
	_stage.build(dungeon.ranks[0].color)
	_lobby_layer = CanvasLayer.new()
	add_child(_lobby_layer)
	var lobby := Lobby.new()
	lobby.stage = _stage
	lobby.gate_entered.connect(_on_gate_entered)
	_lobby_layer.add_child(lobby)


func _on_gate_entered() -> void:
	_clear()
	await _show_loading()
	var screen := DungeonScreen.new()
	screen.returned_to_lobby.connect(show_lobby)
	_screen = screen
	add_child(screen)


## Dá tempo de a tela de carregamento aparecer antes da geração da masmorra.
func _show_loading() -> void:
	var layer := CanvasLayer.new()
	var backdrop := ColorRect.new()
	backdrop.color = Color("04060c")
	UiKit.full_rect(backdrop)
	layer.add_child(backdrop)
	var text := UiKit.label("Abrindo o Portão...", 34, UiKit.SYSTEM_LINE, UiKit.title_font())
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.full_rect(text)
	layer.add_child(text)
	add_child(layer)
	await get_tree().process_frame
	await get_tree().process_frame
	layer.queue_free()
