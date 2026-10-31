class_name Hud
extends CanvasLayer
## Interface da masmorra, composta por widgets independentes.

const MENU_ICONS: Array[Array] = [["I", &"menu_inventory", "Inventário", &"armor"], ["C", &"menu_character", "Personagem", &"helm"], ["P", &"menu_forge", "Forja", &"axe"], ["M", &"menu_map", "Mapa", &"cloth"]]

signal menu_pressed(action: StringName)

var feedback: CombatFeedback
var toast: SystemToast

var _run: DungeonRun
var _coords: Label
var _fps: Label
var _quality_name: Callable = Callable()


func bind(run: DungeonRun) -> void:
	_run = run
	layer = 5
	var root := Control.new()
	root.theme = UiKit.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(root)
	add_child(root)

	feedback = CombatFeedback.new()
	root.add_child(feedback)
	feedback.bind(run)

	var player_frame := PlayerFrame.new()
	UiKit.fit_rect(player_frame, 0.0, 0.0, 0.0, 0.0, Rect2(14.0, 12.0, 340.0, 110.0))
	root.add_child(player_frame)
	player_frame.bind(run.player.combatant, run.sheet)

	var party := PartyFrames.new()
	UiKit.fit_rect(party, 0.0, 0.0, 0.0, 0.0, Rect2(14.0, 134.0, 236.0, 340.0))
	root.add_child(party)
	party.bind(run.combat, run.bots)

	var target := TargetFrame.new()
	UiKit.fit_rect(target, 0.5, 0.0, 0.5, 0.0, Rect2(-215.0, 12.0, 215.0, 130.0))
	root.add_child(target)
	target.bind(run.combat)

	var right := UiKit.vbox(4)
	UiKit.fit_rect(right, 1.0, 0.0, 1.0, 0.0, Rect2(-214.0, 10.0, -12.0, 420.0))
	root.add_child(right)
	var zone_line := UiKit.shadowed(UiKit.label("%s · Rank %s" % [run.dungeon.display_name, run.rank.label], 14, UiKit.GOLD_BRIGHT, UiKit.bold_font()), 4)
	zone_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(zone_line)
	var minimap := Minimap.new()
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.add_child(minimap)
	minimap.bind(run)
	_coords = UiKit.shadowed(UiKit.label("", 12, UiKit.MUTED), 3)
	_coords.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_coords)

	var missions := MissionTracker.new()
	var mission_panel := PanelContainer.new()
	mission_panel.add_theme_stylebox_override(&"panel", UiKit.style(Color(0.02, 0.03, 0.05, 0.5), Color.TRANSPARENT, 0, 3))
	UiKit.fit_rect(mission_panel, 1.0, 0.0, 1.0, 0.0, Rect2(-280.0, 256.0, -14.0, 400.0))
	root.add_child(mission_panel)
	mission_panel.add_child(UiKit.margin(missions, 8, 5, 8, 6))
	missions.bind(run)

	var chat := ChatLog.new()
	UiKit.fit_rect(chat, 0.0, 1.0, 0.0, 1.0, Rect2(14.0, -212.0, 394.0, -14.0))
	root.add_child(chat)

	var loot := LootFeed.new()
	UiKit.fit_rect(loot, 1.0, 1.0, 1.0, 1.0, Rect2(-276.0, -258.0, -14.0, -100.0))
	root.add_child(loot)

	var bottom := UiKit.hbox(0)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.fit_rect(bottom, 0.5, 1.0, 0.5, 1.0, Rect2(-290.0, -74.0, 290.0, -12.0))
	root.add_child(bottom)
	var hotbar := Hotbar.new()
	bottom.add_child(hotbar)
	hotbar.bind(run.player, run.combat, run.sheet)

	var menu := UiKit.hbox(4)
	UiKit.fit_rect(menu, 1.0, 1.0, 1.0, 1.0, Rect2(-214.0, -62.0, -14.0, -14.0))
	root.add_child(menu)
	for entry: Array in MENU_ICONS:
		var button := Button.new()
		button.text = entry[0]
		button.tooltip_text = "%s (%s)" % [entry[2], entry[0]]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(44.0, 44.0)
		button.pressed.connect(func() -> void: menu_pressed.emit(entry[1]))
		menu.add_child(button)

	toast = SystemToast.new()
	UiKit.fit_rect(toast, 0.5, 0.31, 0.5, 0.31, Rect2(-230.0, 0.0, 230.0, 100.0))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast)

	_fps = UiKit.shadowed(UiKit.label("", 12, UiKit.MUTED), 3)
	UiKit.fit_rect(_fps, 0.5, 1.0, 0.5, 1.0, Rect2(-200.0, -96.0, 200.0, -78.0))
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fps.visible = false
	root.add_child(_fps)


func set_quality_provider(provider: Callable) -> void:
	_quality_name = provider


func toggle_stats() -> void:
	_fps.visible = not _fps.visible


func _process(_delta: float) -> void:
	if _run == null or not is_instance_valid(_run.player):
		return
	var position_3d: Vector3 = _run.player.global_position
	_coords.text = "%d, %d" % [position_3d.x, position_3d.z]
	if _fps.visible:
		var quality: String = _quality_name.call() if _quality_name.is_valid() else ""
		_fps.text = "%d FPS · gráficos: %s · F10 altera" % [Engine.get_frames_per_second(), quality]
