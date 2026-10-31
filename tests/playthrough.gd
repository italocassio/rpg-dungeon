extends Node
## Partida completa automatizada, sem janela:
## godot --headless --fixed-fps 60 --path . res://tests/playthrough.tscn -- --class=warrior --rank=0 --level=1

const DUNGEON := &"frost_gate"

var _class_id: StringName = &"warrior"
var _rank_index: int = 0
var _level: int = 1
var _forged: bool = false
var _trace: bool = false
var _no_dodge: bool = false
var _limit: float = 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--class="):
			_class_id = StringName(arg.trim_prefix("--class="))
		elif arg.begins_with("--rank="):
			_rank_index = int(arg.trim_prefix("--rank="))
		elif arg.begins_with("--level="):
			_level = int(arg.trim_prefix("--level="))
		elif arg == "--forged":
			_forged = true
		elif arg == "--trace":
			_trace = true
		elif arg == "--no-dodge":
			_no_dodge = true
		elif arg.begins_with("--limit="):
			_limit = float(arg.trim_prefix("--limit="))
	Session.save_path = "user://test_playthrough_%s.json" % _class_id
	Session.reset_all()
	var class_data: ClassData = GameDB.class_by_id(_class_id)
	var sheet: CharacterSheet = Session.select_class(class_data)
	sheet.level = _level
	sheet.unspent_points = (_level - 1) * GameDB.balance.attribute_points_per_level
	sheet.auto_spend_points()
	if _forged:
		for piece: String in ["t1_helm", "t1_boots", "t2_weapon", "t2_armor"]:
			sheet.equip_directly(GameDB.item(StringName("%s_%s" % [_class_id, piece])))
	var dungeon: DungeonData = GameDB.dungeon(DUNGEON)
	var rank: GateRankData = dungeon.ranks[_rank_index]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var party: Array[PartyMember] = PartyFinder.assemble(class_data, sheet.level, GameDB.catalog, GameDB.balance.party_size, rng)
	Session.begin_run(dungeon, rank, party)

	var run := DungeonRun.new()
	add_child(run)
	run.start(dungeon, rank, sheet, party)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var pilot := Autopilot.new()
	add_child(pilot)
	pilot.begin(run)
	pilot.trace_enabled = _trace
	pilot.avoid_mechanics = not _no_dodge
	if _limit > 0.0:
		pilot.time_limit = _limit
	pilot.finished.connect(_on_finished)


func _on_finished(report: Dictionary) -> void:
	var sheet: CharacterSheet = Session.active_sheet
	print("=== PARTIDA %s rank %s nv inicial %d ===" % [_class_id, Session.active_rank.label, _level])
	print("vitória=%s motivo=%s tempo=%.0fs mortes=%d abates=%d baús=%d" % [report.victory, report.reason, report.seconds, report.deaths, report.kills, report.chests])
	print("chefe: %.0fs fase_final=%s hp_restante=%.2f | dano recebido=%.0f" % [report.boss_seconds, report.phase, report.boss_hp, report.damage_taken])
	print("nível final=%d cristais=%d itens=%s" % [report.level, report.crystals, report.loot])
	print("resgates de contenção: %d" % report.rescues)
	var forgeable: Array[String] = []
	for recipe in GameDB.recipes_for(_class_id):
		if Forge.check(recipe, sheet) == Forge.Failure.NONE:
			forgeable.append(recipe.result.display_name)
	print("forjável após a partida: %s" % [forgeable])
	if report.victory:
		var core_ok: bool = sheet.inventory.count_of(&"boss_core") >= 1
		print("drop de chefe coletado: %s" % core_ok)
		get_tree().quit(0 if core_ok else 2)
	else:
		get_tree().quit(3)
