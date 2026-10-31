extends Node
## Percorre o jogo real capturando telas e mede FPS.
## godot --path . --disable-vsync --fixed-fps 30 res://tests/visual/tour.tscn -- --out=DIR --class=warrior [--short]

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")

var _out := "user://tour"
var _class_id: StringName = &"warrior"
var _short: bool = false
var _bench_quality: int = -1
var _main: Node
var _lobby: Lobby
var _screen: DungeonScreen
var _pilot: Autopilot
var _taken: Dictionary[String, bool] = {}
var _frame_ms: Array[float] = []
var _last_tick: int = 0
var _busy: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--class="):
			_class_id = StringName(arg.trim_prefix("--class="))
		elif arg == "--short":
			_short = true
		elif arg.begins_with("--bench="):
			_bench_quality = int(arg.trim_prefix("--bench="))
	DirAccess.make_dir_recursive_absolute(_out)
	Session.save_path = "user://tour_save_%s.json" % _class_id
	if FileAccess.file_exists(Session.save_path):
		DirAccess.remove_absolute(Session.save_path)
	Session.reset_all()
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await _wait(40)
	_lobby = _main.find_children("*", "Lobby", true, false)[0]
	if not _short:
		await _shot("01_lobby_warrior")
		_lobby._on_class_chosen(GameDB.class_by_id(&"mage"))
		await _wait(6)
		await _shot("02_lobby_mage")
		_lobby._on_class_chosen(GameDB.class_by_id(&"priest"))
		await _wait(6)
		await _shot("03_lobby_priest")
	_lobby._on_class_chosen(GameDB.class_by_id(_class_id))
	_lobby.open_tab(&"gear")
	await _wait(6)
	if not _short:
		await _shot("04_gear")
	_lobby.open_tab(&"party")
	await _wait(4)
	var search: Button = _lobby._page.find_child("Search", true, false)
	search.pressed.emit()
	await get_tree().create_timer(Lobby.SEARCH_STEP_SECONDS * 3.5).timeout
	if not _short:
		await _shot("05_party")
	var enter: Button = _lobby._page.find_child("Enter", true, false)
	enter.pressed.emit()
	while _main.get("_screen") == null:
		await get_tree().process_frame
	_screen = _main.get("_screen")
	await _wait(50)
	if _bench_quality >= 0:
		await _bench()
		return
	await _shot("10_start_%s" % _class_id)
	if _short:
		_report()
		get_tree().quit()
		return
	_pilot = Autopilot.new()
	add_child(_pilot)
	_pilot.begin(_screen.run)
	_pilot.finished.connect(func(report: Dictionary) -> void:
		print("fim: ", report.victory, " ", report.reason, " tempo=", report.seconds))
	Events.boss_engaged.connect(func(_b: Node) -> void: _request("31_boss_engaged"))
	_screen.run.run_finished.connect(_on_finished)


## Mede o custo real de cada preset durante combate automatizado.
func _bench() -> void:
	_screen.run.world.apply_quality(_bench_quality as DungeonEnvironment.Quality)
	_pilot = Autopilot.new()
	add_child(_pilot)
	_pilot.begin(_screen.run)
	_taken["21_panels"] = true
	_busy = true
	await get_tree().create_timer(70.0).timeout
	print("preset ", DungeonEnvironment.QUALITY_NAMES[_bench_quality], " abates=", _screen.run.kills)
	_report()
	get_tree().quit()


func _on_finished(_victory: bool) -> void:
	await _wait(20)
	await _shot("40_results")
	_report()
	get_tree().quit()


func _report() -> void:
	_frame_ms.sort()
	if _frame_ms.is_empty():
		return
	var count: int = _frame_ms.size()
	var total: float = 0.0
	for ms in _frame_ms:
		total += ms
	print("quadros=%d média=%.1f ms (%.0f FPS) p95=%.1f ms p99=%.1f ms" % [count, total / count, 1000.0 * count / total, _frame_ms[int(count * 0.95)], _frame_ms[int(count * 0.99)]])


func _request(shot_name: String) -> void:
	if _taken.has(shot_name) or _busy:
		return
	_taken[shot_name] = true
	_shot(shot_name)


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if _last_tick != 0 and _pilot != null:
		_frame_ms.append((now - _last_tick) / 1000.0)
	_last_tick = now
	if _pilot == null or _busy:
		return
	var run: DungeonRun = _screen.run
	if run.is_finished:
		return
	var player: PlayerController = run.player
	var nearby: Combatant = CombatWorld.nearest_hostile(player.combatant, 7.0)
	if nearby != null and player.combatant.in_combat():
		_request("11_combat_%s" % nearby.actor().data.id)
	if run.kills >= 1:
		_request_panel("20_loot", &"")
	if run.door_opened:
		_request("30_door_open")
	if is_instance_valid(run.boss):
		var phase: BossDirector = run.boss.get_node_or_null("BossDirector")
		if phase != null and phase.current_phase >= 1:
			_request("33_boss_phase2")
		if phase != null and phase.current_phase >= 2:
			_request("34_boss_phase3")
		if not Telegraph.danger_zones(get_tree()).is_empty() and player.global_position.distance_to(run.boss.global_position) < 20.0:
			_request("32_boss_telegraph")
	if run.boss_defeated_flag:
		_request("35_boss_defeated")
	if run.kills >= 12 and not _taken.has("21_panels"):
		_taken["21_panels"] = true
		_capture_panels()


func _request_panel(shot_name: String, _action: StringName) -> void:
	_request(shot_name)


func _capture_panels() -> void:
	_busy = true
	for entry: Array in [[&"menu_inventory", "21_inventory"], [&"menu_character", "22_character"], [&"menu_forge", "23_forge"], [&"menu_map", "24_map"]]:
		_screen.toggle_window(entry[0])
		await _wait(4)
		await _capture(entry[1])
		_screen.close_window()
	_busy = false


func _wait(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	_taken[shot_name] = true
	await _capture(shot_name)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
