class_name DungeonScreen
extends Node
## Tela da masmorra: une partida, HUD, janelas e controle do cursor.

signal returned_to_lobby

var run: DungeonRun
var hud: Hud

var _window_layer: CanvasLayer
var _window: WindowFrame
var _window_action: StringName = &""
var _elapsed: float = 0.0
var _quality: DungeonEnvironment.Quality = DungeonEnvironment.Quality.MEDIUM
var _cursor_free: bool = false
var _pause_view: Control
var _left: bool = false


func _ready() -> void:
	# A tela precisa receber Esc mesmo pausada; a partida e o HUD continuam pausáveis.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var party: Array[PartyMember] = Session.party
	run = DungeonRun.new()
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(run)
	run.start(Session.active_dungeon, Session.active_rank, Session.active_sheet, party)
	hud = Hud.new()
	hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hud)
	hud.bind(run)
	hud.menu_pressed.connect(toggle_window)
	hud.set_quality_provider(func() -> String: return DungeonEnvironment.QUALITY_NAMES[_quality])
	_window_layer = CanvasLayer.new()
	_window_layer.layer = 10
	_window_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_window_layer)
	run.combat.menu_requested.connect(func(action: StringName) -> void:
		if action == &"forge":
			toggle_window(&"menu_forge"))
	run.run_finished.connect(_on_run_finished)
	run.sheet.changed.connect(run.refresh_player_stats)
	_update_cursor()
	Events.system_message.emit("Você entrou no %s de Rank %s." % [run.dungeon.display_name, run.rank.label], "info")
	var greetings: Array[String] = ["bora, tanque na frente", "boa sorte pessoal", "cuidado com as áreas no chão"]
	for i in run.bots.size():
		Events.chat_message.emit("GRUPO", run.bots[i].combatant.display_name, greetings[i % greetings.size()])


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if run != null and run.sheet != null and run.sheet.changed.is_connected(run.refresh_player_stats):
		run.sheet.changed.disconnect(run.refresh_player_stats)


func _process(delta: float) -> void:
	if not get_tree().paused:
		_elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if run.is_finished:
		# Nos resultados não há jogo a retomar: Esc equivale a voltar ao saguão.
		if event.is_action_pressed(&"menu_pause"):
			_leave()
		return
	if event.is_action_pressed(&"menu_pause"):
		if get_tree().paused:
			_resume()
		elif _window != null:
			close_window()
		else:
			_open_pause()
		return
	if get_tree().paused:
		return
	for action: StringName in [&"menu_inventory", &"menu_character", &"menu_forge", &"menu_map"]:
		if event.is_action_pressed(action):
			toggle_window(action)
			return
	if event.is_action_pressed(&"graphics_cycle"):
		_quality = ((int(_quality) + 1) % 3) as DungeonEnvironment.Quality
		run.world.apply_quality(_quality)
		Events.system_message.emit("Gráficos: %s" % DungeonEnvironment.QUALITY_NAMES[_quality], "info")
	elif event.is_action_pressed(&"stats_toggle"):
		hud.toggle_stats()
	elif event.is_action(&"cursor_toggle"):
		_update_cursor()


func _update_cursor() -> void:
	# Lê o estado real: Alt pode ter sido solto durante a pausa, quando não recebemos o evento.
	_cursor_free = Input.is_action_pressed(&"cursor_toggle")
	var free: bool = _cursor_free or _window != null or get_tree().paused or run.is_finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if free else Input.MOUSE_MODE_CAPTURED
	run.player.input_enabled = _window == null and not get_tree().paused and not run.is_finished


func toggle_window(action: StringName) -> void:
	if run.is_finished:
		return
	if _window_action == action:
		close_window()
		return
	close_window()
	var content: Control
	var title: String
	var window_size: Vector2
	var system_look: bool = false
	match action:
		&"menu_inventory":
			var view := InventoryView.new()
			view.bind(run.sheet)
			content = view
			title = "Inventário"
			window_size = Vector2(760.0, 520.0)
		&"menu_character":
			var view := CharacterView.new()
			view.bind(run.sheet)
			content = view
			title = "Status do Caçador"
			window_size = Vector2(620.0, 380.0)
			system_look = true
		&"menu_forge":
			var view := ForgeView.new()
			view.bind(run.sheet)
			content = view
			title = "Forja do Gelo"
			window_size = Vector2(860.0, 560.0)
		&"menu_map":
			var view := MapView.new()
			view.bind(run)
			content = view
			title = "Mapa"
			window_size = content.custom_minimum_size + Vector2(30.0, 80.0)
		_:
			return
	_window = _frame(title, content, window_size, system_look)
	_window.closed.connect(close_window)
	_window_action = action
	_update_cursor()


func _frame(title: String, content: Control, window_size: Vector2, system_look: bool) -> WindowFrame:
	var window: WindowFrame = WindowFrame.wrap(title, content, window_size, system_look)
	window.theme = UiKit.theme()
	_window_layer.add_child(window)
	return window


func close_window() -> void:
	if _window != null:
		_window.queue_free()
	_window = null
	_window_action = &""
	_update_cursor()


func _open_pause() -> void:
	var column := UiKit.vbox(10)
	column.add_child(UiKit.button("Continuar", _resume, 17))
	column.add_child(UiKit.button("Abandonar o Portão", _abandon, 17))
	column.add_child(UiKit.button("Sair do Jogo", func() -> void:
		Session.save_game()
		get_tree().quit(), 17))
	column.add_child(UiKit.label("WASD mover · Mouse mirar · LMB atacar · RMB defender\n1-4 habilidades · R suprema · Ctrl esquiva · Shift correr\nTab alvo · F2-F4 aliados · Q/X poções · E interagir\nI inventário · C status · P forja · M mapa · Alt cursor\nF9 FPS · F10 gráficos", 13, UiKit.MUTED))
	_pause_view = WindowFrame.wrap("Pausa", column, Vector2(460.0, 400.0))
	(_pause_view as WindowFrame).closed.connect(_resume)
	_pause_view.theme = UiKit.theme()
	_window_layer.add_child(_pause_view)
	get_tree().paused = true
	_update_cursor()


func _resume() -> void:
	get_tree().paused = false
	if _pause_view != null:
		_pause_view.queue_free()
		_pause_view = null
	_update_cursor()


func _abandon() -> void:
	_resume()
	run.finish(false)


func _on_run_finished(victory: bool) -> void:
	close_window()
	_update_cursor()
	if not victory:
		_leave()
		return
	var results := ResultsView.new()
	results.bind(run, _elapsed)
	results.return_requested.connect(_leave)
	_window = _frame("Portão Concluído", results, Vector2(560.0, 560.0), true)
	_window.closed.connect(_leave)


func _leave() -> void:
	if _left:
		return
	_left = true
	returned_to_lobby.emit()
