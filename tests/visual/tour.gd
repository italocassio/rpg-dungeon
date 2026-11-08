extends Node
## Percorre o jogo real capturando telas e mede FPS.
## godot --path . --disable-vsync --fixed-fps 30 res://tests/visual/tour.tscn -- --out=DIR --class=warrior [--short]
## `--boss_fx`: em vez do autopiloto, grava os efeitos de ataque do chefe (OS-022) em DIR/boss_fx/:
## `meteor_mark` (a marca de aliado) e, por habilidade, `<id>_pre`, `_prep` (85% do cast), `_hit` (0,12 s) e `_after` (0,7 s).

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")

var _out := "user://tour"
var _class_id: StringName = &"warrior"
var _short: bool = false
var _bench_quality: int = -1
var _boss_fx: bool = false
var _boss_fight: bool = false
var _measuring: bool = false
var _main: Node
var _lobby: Lobby
var _screen: DungeonScreen
var _pilot: Autopilot
var _taken: Dictionary[String, bool] = {}
var _frame_ms: Array[float] = []
## Só os quadros com o chefe em combate: é onde a OS-022 gasta, e o tour inteiro diluiria o número.
var _boss_frame_ms: Array[float] = []
## Custo por fase da sequência `--boss_fx` (fora dos quadros logo após uma captura, que travam o salvamento do PNG).
var _boss_gpu_ms: Array[float] = []
var _boss_process_ms: Array[float] = []
var _boss_physics_ms: Array[float] = []
var _boss_cpu_ms: Array[float] = []
var _since_impact: float = 99.0
var _impact_ms: Dictionary[String, Array] = {}
var _phase: String = ""
var _phase_ms: Dictionary[String, Array] = {}
var _skip_frames: int = 0
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
		elif arg == "--boss_fx":
			_boss_fx = true
		elif arg == "--boss_fight":
			_boss_fight = true
		elif arg.begins_with("--bench="):
			_bench_quality = int(arg.trim_prefix("--bench="))
	DirAccess.make_dir_recursive_absolute(_out)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
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
	if _boss_fight:
		await _boss_fight_run()
		_report()
		get_tree().quit()
		return
	if _boss_fx:
		await _boss_fx_sequence()
		_report()
		get_tree().quit()
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
	_print_stats("quadros", _frame_ms)
	_print_stats("quadros com o chefe em combate", _boss_frame_ms)
	_print_stats("  tempo de GPU com o chefe em combate", _boss_gpu_ms)
	_print_stats("  tempo de render na CPU com o chefe em combate", _boss_cpu_ms)
	_print_stats("  tempo de _process com o chefe em combate", _boss_process_ms)
	_print_stats("  tempo de _physics_process com o chefe em combate", _boss_physics_ms)
	for label: String in _impact_ms:
		var frames: Array[float] = []
		frames.assign(_impact_ms[label])
		_print_stats("  chefe, %s" % label, frames)
	for label: String in _phase_ms:
		var frames: Array[float] = []
		frames.assign(_phase_ms[label])
		_print_stats("  fase %s" % label, frames)


func _print_stats(label: String, frames: Array[float]) -> void:
	if frames.is_empty():
		return
	var sorted: Array[float] = frames.duplicate()
	sorted.sort()
	var count: int = sorted.size()
	var total: float = 0.0
	for ms in sorted:
		total += ms
	print("%s=%d média=%.1f ms (%.0f FPS) p95=%.1f ms p99=%.1f ms" % [label, count, total / count, 1000.0 * count / total, sorted[int(count * 0.95)], sorted[int(count * 0.99)]])


func _boss_in_combat() -> bool:
	if _screen == null or _screen.run == null or not is_instance_valid(_screen.run.boss):
		return false
	var state: StringName = _screen.run.boss.machine.current_name
	return state == &"chase" or state == &"attack"


func _request(shot_name: String) -> void:
	if _taken.has(shot_name) or _busy:
		return
	_taken[shot_name] = true
	_shot(shot_name)


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if _last_tick != 0 and (_pilot != null or _measuring):
		var frame: float = (now - _last_tick) / 1000.0
		_frame_ms.append(frame)
		if _boss_in_combat():
			_boss_frame_ms.append(frame)
			var viewport_rid: RID = get_viewport().get_viewport_rid()
			_boss_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid))
			_boss_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid))
			_boss_process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			_boss_physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		if _boss_fight and _boss_in_combat():
			var label: String = "sem impacto nos últimos 3 s"
			if _since_impact < 0.15:
				label = "0 a 0,15 s depois do impacto"
			elif _since_impact < 0.6:
				label = "0,15 a 0,6 s"
			elif _since_impact < 1.5:
				label = "0,6 a 1,5 s"
			elif _since_impact < 3.0:
				label = "1,5 a 3 s"
			var group: Array = _impact_ms.get(label, [])
			group.append(frame)
			_impact_ms[label] = group
		_since_impact += frame / 1000.0
		if _phase != "":
			if _skip_frames > 0:
				_skip_frames -= 1
			else:
				var bucket: Array = _phase_ms.get(_phase, [])
				bucket.append(frame)
				_phase_ms[_phase] = bucket
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
	for entry: Array in [[&"menu_inventory", "21_inventory"], [&"menu_character", "22_character"], [&"menu_forge", "23_forge"], [&"menu_map", "24_map"], [&"menu_skills", "25_skills"]]:
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
	await _capture_to(_out, shot_name)


func _capture_to(directory: String, shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [directory, shot_name])
	_skip_frames = 4


const BOSS_FIGHT_SECONDS := 90.0


## Luta contra o chefe com o autopiloto, sem o resto da masmorra: mede o custo da luta em poucos minutos.
func _boss_fight_run() -> void:
	var run: DungeonRun = _screen.run
	var antechamber: Vector2 = Vector2.ZERO
	for room in run.dungeon.rooms:
		if room.id == &"antechamber":
			antechamber = room.center
	_measuring = true
	Events.skill_impacted.connect(func(_skill: SkillData, caster: Combatant, _point: Vector3) -> void:
		if caster == run.boss.combatant:
			_since_impact = 0.0)
	_pilot = Autopilot.new()
	add_child(_pilot)
	_pilot.begin(run)
	_pilot.route = [antechamber, Vector2(134, 50)]
	_pilot.route_index = 0
	run.player.global_position = run.boss.global_position + Vector3(0.0, 0.5, 14.0)
	run.boss.engage(run.player.combatant)
	await get_tree().create_timer(BOSS_FIGHT_SECONDS, false).timeout
	_measuring = false


const BOSS_FX_SKILLS: Array[StringName] = [&"strike", &"cleave", &"slam", &"spikes", &"nova"]
const BOSS_FX_DISTANCE := 7.0
## Segunda vista, do lado de dentro da sala (-Z do chefe), para ver o impacto inteiro: a 7 m, as estacas
## do cleave e a borda da nova ficam atrás da câmera. Distância por habilidade, em metros.
const BOSS_FX_WIDE_DISTANCE: Dictionary = {&"strike": 14.0, &"cleave": 14.0, &"slam": 14.0, &"spikes": 14.0, &"nova": 22.0}
const BOSS_FX_LOOK_HEIGHT := 3.0
const BOSS_FX_MID_SECONDS := 0.35
const BOSS_FX_PREP_SHOT := 0.85
const BOSS_FX_HIT_SECONDS := 0.12
const BOSS_FX_AFTER_SECONDS := 0.7
const BOSS_FX_SETTLE_SECONDS := 3.0


## O chefe fica parado e sem IA de ataque; o jogador, invulnerável, a 7 m e mirando nele; cada habilidade sai por `try_cast`.
func _boss_fx_sequence() -> void:
	var run: DungeonRun = _screen.run
	var boss: Enemy = run.boss
	var player: PlayerController = run.player
	var directory: String = "%s/boss_fx" % _out
	DirAccess.make_dir_recursive_absolute(directory)
	for bot in run.bots:
		bot.process_mode = Node.PROCESS_MODE_DISABLED
		bot.visible = false
	boss.active_skills.clear()
	boss.speed_multiplier = 0.0
	player.combatant.grant_invulnerability(100000.0)
	_measuring = true
	await _capture_meteor_mark(run, directory)
	var skills: Array[SkillData] = boss.data.skills.duplicate()
	for phase in boss.data.phases:
		skills.append_array(phase.skills)
	for id in BOSS_FX_SKILLS:
		var skill: SkillData = _skill_by_id(skills, StringName("boss_%s" % id))
		if skill == null:
			push_warning("tour: habilidade boss_%s não encontrada" % id)
			continue
		await _boss_fx_cast(run, skill, String(id), directory, BOSS_FX_DISTANCE)
		if BOSS_FX_WIDE_DISTANCE.has(id):
			await _boss_fx_cast(run, skill, "%s_wide" % id, directory, -float(BOSS_FX_WIDE_DISTANCE[id]))
	_measuring = false


func _skill_by_id(skills: Array[SkillData], id: StringName) -> SkillData:
	for skill in skills:
		if skill.id == id:
			return skill
	return null


func _place_player(run: DungeonRun, point: Vector3, look_at: Vector3) -> void:
	run.player.global_position = point
	run.player.velocity = Vector3.ZERO
	run.player.look_at_point(look_at)


## Marca de aliado: o meteoro do jogador a 14 m do chefe, no meio do tempo de queda.
func _capture_meteor_mark(run: DungeonRun, directory: String) -> void:
	var boss: Enemy = run.boss
	var player: PlayerController = run.player
	var spot: Vector3 = boss.global_position + Vector3(0.0, 0.2, 22.0)
	_place_player(run, spot, spot + Vector3(0.0, 1.5, -14.0))
	await _wait(20)
	var meteor: SkillData = load("res://data/skills/m_meteor.tres") as SkillData
	var aim := SkillAim.new()
	aim.origin = player.combatant.center_position()
	aim.direction = Vector3(0.0, 0.0, -1.0)
	aim.ground_point = spot + Vector3(0.0, -0.2, -9.0)
	SkillExecutor.execute(meteor, player.combatant, aim)
	await get_tree().create_timer(meteor.impact_delay * 0.5, false).timeout
	await _capture_to(directory, "meteor_mark")
	await get_tree().create_timer(meteor.impact_delay + 1.5, false).timeout


func _boss_fx_cast(run: DungeonRun, skill: SkillData, id: String, directory: String, distance: float) -> void:
	var boss: Enemy = run.boss
	var player: PlayerController = run.player
	var spot: Vector3 = boss.global_position + Vector3(0.0, 0.2, distance)
	var gaze: Vector3 = boss.global_position + Vector3.UP * BOSS_FX_LOOK_HEIGHT
	_phase = "%s repouso" % id
	_place_player(run, spot, gaze)
	boss.caster.reset_all()
	boss.engage(player.combatant)
	boss.snap_facing(player.global_position)
	await _wait(24)
	_place_player(run, spot, gaze)
	await _capture_to(directory, "%s_pre" % id)
	var fired: Array[bool] = [false]
	var on_fired := func(_s: SkillData, _a: SkillAim) -> void: fired[0] = true
	boss.caster.skill_fired.connect(on_fired)
	boss.snap_facing(player.global_position)
	if not boss.caster.try_cast(skill, SkillAim.toward(boss.combatant, player.combatant)):
		push_warning("tour: o chefe recusou boss_%s" % id)
	var prep_taken: bool = false
	_phase = "%s preparo" % id
	while not fired[0]:
		await get_tree().process_frame
		if not prep_taken and boss.caster.cast_progress() >= BOSS_FX_PREP_SHOT:
			prep_taken = true
			_print_shard_visibility(boss, player.camera, id)
			await _capture_to(directory, "%s_prep" % id)
	boss.caster.skill_fired.disconnect(on_fired)
	_phase = "%s impacto" % id
	await get_tree().create_timer(BOSS_FX_HIT_SECONDS, false).timeout
	await _capture_to(directory, "%s_hit" % id)
	await get_tree().create_timer(BOSS_FX_MID_SECONDS - BOSS_FX_HIT_SECONDS, false).timeout
	await _capture_to(directory, "%s_mid" % id)
	await get_tree().create_timer(BOSS_FX_AFTER_SECONDS - BOSS_FX_MID_SECONDS, false).timeout
	await _capture_to(directory, "%s_after" % id)
	_phase = ""
	await get_tree().create_timer(BOSS_FX_SETTLE_SECONDS, false).timeout


## Conta as lascas de convergência da nova que o quadro mostra: projeta base e ponta de cada uma na câmera.
## "inteira" é a que tem a base e a ponta dentro do quadro; "legível" tem pelo menos 8 px de comprimento na tela.
func _print_shard_visibility(boss: Enemy, camera: Camera3D, id: String) -> void:
	var attack_fx: Node = boss.get_node_or_null("AttackFx")
	if attack_fx == null or attack_fx.get("_convergence") == null:
		return
	var shards: ConvergenceShards = attack_fx.get("_convergence")
	var view: Rect2 = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var alive: int = 0
	var whole: int = 0
	var readable: int = 0
	for node in shards.get_children():
		var shard := node as MeshInstance3D
		if shard == null or not shard.visible:
			continue
		alive += 1
		var base: Vector3 = shard.global_position
		var tip: Vector3 = base + shard.global_basis.y * ConvergenceShards.SHARD_LENGTH
		if camera.is_position_behind(base) or camera.is_position_behind(tip):
			continue
		var base_px: Vector2 = camera.unproject_position(base)
		var tip_px: Vector2 = camera.unproject_position(tip)
		if view.has_point(base_px) and view.has_point(tip_px):
			whole += 1
			if base_px.distance_to(tip_px) >= 8.0:
				readable += 1
	print("LASCAS %s: vivas=%d inteiras no quadro=%d legíveis (>=8 px)=%d" % [id, alive, whole, readable])
