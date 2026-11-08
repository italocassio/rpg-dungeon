extends Node
## Percorre o fluxo real pela interface: saguão, partida, janelas, forja, vitória e retorno.
## godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")

var _main: Node
var _passed: int = 0
var _failed: int = 0
var _errors := ScriptErrorCounter.new()
var _project_aspect: Window.ContentScaleAspect


func check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("  FALHOU: ", message)


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _lobby() -> Lobby:
	var found: Array[Node] = _main.find_children("*", "Lobby", true, false)
	return found[0] as Lobby if not found.is_empty() else null


func _screen() -> DungeonScreen:
	return _main.get("_screen") as DungeonScreen


func _music() -> MusicDirector:
	return _main.get_node("MusicDirector") as MusicDirector


func _sfx() -> SfxDirector:
	return _main.get_node("SfxDirector") as SfxDirector


func _sfx_voice(file: String, positional: bool) -> AudioStreamPlayer3D:
	var model: AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE if positional else AudioStreamPlayer3D.ATTENUATION_DISABLED
	for voice: AudioStreamPlayer3D in _sfx()._voices:
		if voice.playing and voice.attenuation_model == model and voice.stream.resource_path.get_file() == file + ".wav":
			return voice
	return null


func _ready() -> void:
	OS.add_logger(_errors)
	_project_aspect = get_window().content_scale_aspect
	Session.save_path = "user://test_flow_save.json"
	if FileAccess.file_exists(Session.save_path):
		DirAccess.remove_absolute(Session.save_path)
	Session.reset_all()
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await _frames(6)
	await _test_lobby_skill_tooltip()
	await _test_new_character()
	await _test_windows()
	await _test_pause()
	await _test_hotbar_tooltip()
	await _test_skill_tree()
	await _test_skill_tree_fits_every_class()
	_test_skill_info_reads_live_stats()
	await _test_forge_station_and_equip()
	await _test_graphics_presets()
	await _test_containment()
	await _test_throne_is_solid()
	await _test_boss_blocks_bodies()
	await _test_gap_closers_stop_at_boss()
	await _test_fallen_body_is_rescued()
	await _test_summons_avoid_throne_block()
	_test_ally_respawn_avoids_throne_block()
	await _test_throne_platform_is_a_ramp()
	await _test_guard_breaks_without_mana()
	await _test_skill_sounds()
	await _test_summons_belong_to_the_encounter()
	await _test_music_survives_boss_leash()
	await _test_victory_and_return()
	await _test_results_cannot_trap_the_player()
	await _test_rank_lock_and_tabs()
	await _test_second_run_keeps_progress()
	await _test_abandon()
	await _test_viewmodel_swap_in_run()
	_failed += _errors.count
	print("\nFLUXO: %d verificações ok, %d falhas (%d erros de script)" % [_passed, _failed, _errors.count])
	OS.remove_logger(_errors)
	DirAccess.remove_absolute(Session.save_path)
	get_tree().quit(1 if _failed > 0 else 0)


func _enter_gate_through_ui(lobby: Lobby) -> void:
	lobby.open_tab(&"party")
	await _frames(2)
	var search: Button = lobby._page.find_child("Search", true, false)
	check(search != null and not search.disabled, "botão Procurar Grupo disponível")
	search.pressed.emit()
	check(search.disabled, "botão trava durante a busca")
	var enter: Button = lobby._page.find_child("Enter", true, false)
	var waited: float = 0.0
	while not enter.visible and waited < 8.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	check(enter.visible, "grupo encontrado libera a entrada")
	check(lobby.found_members.size() == GameDB.balance.party_size - 1, "grupo completo")
	enter.pressed.emit()
	while _screen() == null:
		await get_tree().process_frame
	await _frames(4)


## Roda antes de criar qualquer ficha: o saguão tem de explicar a classe só com os itens escolhidos.
func _test_lobby_skill_tooltip() -> void:
	await _use_real_screen(true)
	var lobby: Lobby = _lobby()
	var tooltip: SkillTooltip = lobby._skill_tooltip
	var priest: ClassData = GameDB.class_by_id(&"priest")
	var skill: SkillData = priest.ultimate
	var delay_frames: int = ceili(SkillTooltip.SHOW_DELAY * 60.0) + 3
	check(not Session.has_sheet(priest.id), "classe começa sem ficha")
	lobby._on_class_chosen(priest)
	await _frames(2)
	var fresh := CharacterSheet.new(priest, GameDB.balance)
	fresh.equip_directly(lobby.pending_weapon)
	fresh.equip_directly(lobby.pending_armor)
	check(lobby._preview_info(skill).plain_text() == SkillInfo.describe(skill, fresh.derived_stats(), GameDB.balance).plain_text(), "sem ficha usa nível 1 e itens escolhidos")
	lobby._on_weapon_chosen(priest.starter_weapons[1])
	fresh.equip_directly(lobby.pending_weapon)
	check(lobby._preview_info(skill).plain_text() == SkillInfo.describe(skill, fresh.derived_stats(), GameDB.balance).plain_text(), "trocar a arma muda a prévia")
	lobby._on_weapon_chosen(priest.starter_weapons[0])
	lobby.open_tab(&"class")
	await _frames(2)
	var away := Vector2(4.0, 4.0)
	var row: Control = lobby._page.find_child("Skill_%s" % skill.id, true, false)
	check(row != null, "linha da habilidade no saguão")
	await _move_mouse(away)
	await _move_mouse(row.get_global_rect().get_center())
	await _frames(delay_frames)
	check(tooltip.is_open(), "hover real na linha abre o card")
	check(tooltip.shown_text() == lobby._preview_info(skill).plain_text(), "saguão mostra o texto de SkillInfo")
	check(tooltip._panel.get_viewport_rect().encloses(tooltip._panel.get_global_rect()), "card do saguão dentro da tela")
	await _move_mouse(row.get_global_rect().position + Vector2(8.0, 8.0))
	await _frames(2)
	check(tooltip.is_open(), "ícone da linha não tira o hover")
	lobby.open_tab(&"gear")
	await _frames(3)
	check(not tooltip.is_open(), "trocar de aba durante o hover fecha o card")
	lobby.open_tab(&"class")
	await _frames(2)
	await _move_mouse(away)
	check(not tooltip.is_open(), "cursor fora mantém o card fechado")
	await _use_real_screen(false)


func _test_new_character() -> void:
	var lobby: Lobby = _lobby()
	check(lobby != null, "saguão abre")
	check(_music().current == MusicDirector.Track.LOBBY, "saguão começa com a música do saguão")
	for class_data in GameDB.catalog.classes:
		lobby._on_class_chosen(class_data)
		await _frames(2)
		check(lobby.selected_class == class_data, "seleciona %s" % class_data.id)
	var mage: ClassData = GameDB.class_by_id(&"mage")
	lobby._on_class_chosen(mage)
	lobby.open_tab(&"gear")
	await _frames(2)
	lobby._on_weapon_chosen(mage.starter_weapons[1])
	await _frames(2)
	lobby._on_armor_chosen(mage.starter_armors[1])
	await _frames(2)
	lobby.open_tab(&"forge")
	await _frames(2)
	await _enter_gate_through_ui(lobby)
	var sheet: CharacterSheet = Session.active_sheet
	check(sheet != null and sheet.class_data == mage, "ficha do mago criada")
	check(sheet.equipment[ItemData.Kind.WEAPON] == mage.starter_weapons[1], "arma escolhida aplicada")
	check(sheet.equipment[ItemData.Kind.ARMOR] == mage.starter_armors[1], "armadura escolhida aplicada")
	check(_screen().run.bots.size() == 3, "três companheiros na masmorra")
	check(is_instance_valid(_screen().run.boss), "chefe criado")
	check(_music().current == MusicDirector.Track.DUNGEON, "entrar na masmorra toca a música dela")
	check(_music()._dungeon_player.playing, "faixa da masmorra tocando")


func _test_windows() -> void:
	var screen: DungeonScreen = _screen()
	for action: StringName in [&"menu_inventory", &"menu_character", &"menu_skills", &"menu_forge", &"menu_map"]:
		screen.toggle_window(action)
		await _frames(2)
		check(screen._window != null, "janela %s abre" % action)
		check(not screen.run.player.input_enabled, "janela bloqueia controle do jogador")
		screen.toggle_window(action)
		await _frames(1)
		check(screen._window == null, "janela %s fecha" % action)
		check(screen.run.player.input_enabled, "controle volta ao fechar")


func _press_key(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(2)


func _test_pause() -> void:
	var screen: DungeonScreen = _screen()
	await _press_key(&"menu_pause")
	check(get_tree().paused, "Esc pausa")
	check(not screen.run.player.input_enabled, "pausa bloqueia controle")
	await _check_music_while_paused()
	await _press_key(&"menu_pause")
	check(not get_tree().paused, "Esc despausa")
	check(screen.run.player.input_enabled, "controle volta após pausa")
	screen.toggle_window(&"menu_map")
	await _frames(1)
	await _press_key(&"menu_pause")
	check(screen._window == null and not get_tree().paused, "Esc fecha janela antes de pausar")


## Roda logo após a entrada: o fade de 1,5 s ainda está em curso e não pode congelar.
func _check_music_while_paused() -> void:
	var music: MusicDirector = _music()
	var player: AudioStreamPlayer = music._dungeon_player
	var volume_before: float = player.volume_linear
	await _frames(3)
	check(music.current == MusicDirector.Track.DUNGEON, "pausa não troca a faixa")
	check(player.playing and not player.stream_paused, "música segue tocando na pausa")
	check(player.volume_linear > volume_before, "fade segue com a árvore pausada")


## Passa pelo pipeline real da GUI: hit-test, ordem das camadas e mouse_filter.
func _move_mouse(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	get_viewport().push_input(motion, true)
	await _frames(1)


## Pelo Input, ao contrário de `_move_mouse`: a posição fica registrada como a do cursor do sistema.
func _park_mouse(control: Control) -> void:
	var motion := InputEventMouseMotion.new()
	# Input.parse_input_event recebe coordenadas físicas da janela, não as lógicas do canvas.
	motion.position = control.get_global_rect().get_center() * Vector2(get_window().size) / get_viewport().get_visible_rect().size
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await _frames(2)


## A janela headless é 64x64: com o `aspect=expand` do projeto o canvas teria 1600x1600, mais alto que
## a tela real, e checar "dentro da tela" ali não prova nada.
func _use_real_screen(enabled: bool) -> void:
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE if enabled else _project_aspect
	await _frames(2)
	if enabled:
		check(get_viewport().get_visible_rect().size == Vector2(1600.0, 900.0), "checagens de tela rodam em 1600x900")


## Slots de habilidade da hotbar, cada um com a SkillData que sua tecla aciona.
func _hotbar_skills(screen: DungeonScreen) -> Dictionary:
	var class_data: ClassData = screen.run.sheet.class_data
	var by_key: Dictionary = {"LMB": class_data.basic_attack, "R": class_data.ultimate}
	for i in class_data.skills.size():
		by_key[str(i + 1)] = class_data.skills[i]
	var slots: Dictionary = {}
	for node in screen.hud.find_children("*", "SkillSlot", true, false):
		var slot := node as SkillSlot
		if by_key.has(slot.key_text):
			slots[slot] = by_key[slot.key_text]
	return slots


func _test_hotbar_tooltip() -> void:
	await _use_real_screen(true)
	var screen: DungeonScreen = _screen()
	var hud: Hud = screen.hud
	var tooltip: SkillTooltip = hud.skill_tooltip
	var slots: Dictionary = _hotbar_skills(screen)
	check(slots.size() == 6, "seis slots de habilidade na hotbar")
	var delay_frames: int = ceili(SkillTooltip.SHOW_DELAY * 60.0) + 3
	hud.set_cursor_free(true)
	for slot: SkillSlot in slots:
		var skill: SkillData = slots[slot]
		check(slot.tooltip_text.is_empty(), "%s sem tooltip nativo" % skill.id)
		slot.mouse_entered.emit()
		await _frames(2)
		check(not tooltip.is_open(), "%s respeita o atraso" % skill.id)
		await _frames(delay_frames)
		check(tooltip.is_open(), "%s abre o card" % skill.id)
		check(tooltip.shown_text() == screen.run.skill_info(skill).plain_text(), "%s mostra o texto de SkillInfo" % skill.id)
		check(tooltip._panel.get_viewport_rect().encloses(tooltip._panel.get_global_rect()), "card de %s dentro da tela" % skill.id)
		slot.mouse_exited.emit()
		check(not tooltip.is_open(), "%s fecha ao sair" % skill.id)
	var slot_a: SkillSlot = slots.keys()[0]
	var slot_b: SkillSlot = slots.keys()[1]
	var panel: PanelContainer = tooltip._panel
	slot_a.mouse_entered.emit()
	await _frames(delay_frames)
	check(panel.theme != null, "card flutuante tem tema")
	check(panel.modulate.a == 1.0, "card fica visível depois do primeiro ajuste")
	check(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "painel não rouba o hover")
	for node in panel.find_children("*", "Control", true, false):
		check((node as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s não rouba o hover" % node.name)
	check(panel.get_viewport_rect().encloses(panel.get_global_rect()), "card dentro da tela")
	check(not panel.get_global_rect().intersects(slot_a.get_global_rect()), "card não cobre o slot")
	var settled: Rect2 = panel.get_global_rect()
	await _frames(3)
	check(panel.get_global_rect() == settled, "card não salta depois de abrir")
	hud.set_cursor_free(false)
	check(not tooltip.is_open(), "soltar Alt oculta o card")
	slot_a.mouse_exited.emit()
	slot_a.mouse_entered.emit()
	await _frames(delay_frames)
	check(not tooltip.is_open(), "sem cursor livre o hover não reabre")
	slot_a.mouse_exited.emit()

	# Hover de verdade, sem emitir o sinal à mão.
	var away := Vector2(800.0, 450.0)
	hud.set_cursor_free(true)
	await _move_mouse(away)
	await _move_mouse(slot_a.get_global_rect().get_center())
	check(get_viewport().gui_get_hovered_control() == slot_a, "cursor sobre o slot chega ao slot")
	await _frames(delay_frames)
	check(tooltip.is_open(), "hover real abre o card")
	await _move_mouse(slot_a.get_global_rect().get_center() + Vector2(2.0, 0.0))
	check(get_viewport().gui_get_hovered_control() == slot_a, "card aberto não rouba o hover")
	await _move_mouse(slot_b.get_global_rect().get_center())
	await _frames(delay_frames)
	check(tooltip.is_open() and tooltip.shown_text() == screen.run.skill_info(slots[slot_b]).plain_text(), "trocar de slot troca o card")
	await _move_mouse(away)
	check(not tooltip.is_open(), "hover real fecha o card")

	# Alt pode voltar com o cursor parado sobre o slot: aí não chega um novo mouse_entered.
	hud.set_cursor_free(false)
	await _park_mouse(slot_a)
	await _frames(delay_frames)
	check(get_viewport().gui_get_hovered_control() == slot_a, "cursor chega ao slot")
	check(not tooltip.is_open(), "cursor preso não abre o card")
	hud.set_cursor_free(true)
	await _frames(delay_frames)
	check(tooltip.is_open(), "voltar o Alt sobre o slot reabre o card")
	await _move_mouse(away)
	check(not tooltip.is_open(), "sair do slot fecha o card reaberto")

	screen._open_pause()
	await _frames(1)
	check(tooltip._cursor_free, "pausa libera o card")
	await _move_mouse(slot_a.get_global_rect().get_center())
	await _frames(delay_frames)
	check(get_tree().paused and tooltip.is_open(), "card abre com o jogo pausado")
	await _move_mouse(away)
	check(not tooltip.is_open(), "card fecha com o jogo pausado")
	screen._resume()
	await _frames(1)
	check(not tooltip._cursor_free, "combate volta a travar o card")

	# O card fica acima das janelas: abrir uma o fecha, mas a barra segue legível com ela aberta.
	Input.action_press(&"cursor_toggle")
	screen._update_cursor()
	check(tooltip._cursor_free, "Alt libera o card")
	await _park_mouse(slot_a)
	await _frames(delay_frames)
	check(tooltip.is_open(), "Alt com hover abre o card")
	await _press_key(&"menu_skills")
	await _frames(delay_frames)
	check(screen._window_action == &"menu_skills" and not tooltip.is_open(), "abrir uma janela fecha o card")
	slot_a.mouse_exited.emit()
	slot_a.mouse_entered.emit()
	await _frames(delay_frames)
	check(tooltip.is_open(), "com janela aberta um novo hover abre o card")
	await _press_key(&"menu_inventory")
	await _frames(delay_frames)
	check(screen._window_action == &"menu_inventory" and not tooltip.is_open(), "trocar de janela fecha o card")
	await _press_key(&"menu_inventory")
	await _frames(delay_frames)
	check(screen._window == null and not tooltip.is_open(), "fechar a janela não reabre o card sozinho")
	slot_a.mouse_exited.emit()
	slot_a.mouse_entered.emit()
	await _frames(delay_frames)
	check(tooltip.is_open(), "sem janela, novo hover com Alt abre o card")
	Input.action_release(&"cursor_toggle")
	screen._update_cursor()
	check(not tooltip.is_open(), "soltar Alt fecha o card")
	await _press_key(&"menu_skills")
	slot_a.mouse_exited.emit()
	slot_a.mouse_entered.emit()
	await _frames(delay_frames)
	check(tooltip.is_open(), "janela aberta libera o hover mesmo sem Alt")
	await _press_key(&"menu_skills")
	check(screen._window == null and not tooltip.is_open(), "fechar a janela sem Alt fecha o card")
	await _move_mouse(away)
	await _use_real_screen(false)


func _test_skill_tree() -> void:
	await _use_real_screen(true)
	var screen: DungeonScreen = _screen()
	var run: DungeonRun = screen.run
	var sheet: CharacterSheet = run.sheet
	var basic: SkillData = sheet.class_data.basic_attack
	var listeners: int = sheet.changed.get_connections().size()
	await _press_key(&"menu_skills")
	check(screen._window_action == &"menu_skills", "tecla K abre a árvore")
	var views: Array[Node] = screen._window.find_children("*", "SkillTreeView", true, false)
	check(views.size() == 1, "árvore está na janela")
	var view: SkillTreeView = views[0]
	check(view._slots.size() == 6, "árvore tem seis nós")
	check(view._card.shown_text() == run.skill_info(basic).plain_text(), "ao abrir já explica o ataque básico")
	check(view._slots[basic].selected, "ataque básico marcado ao abrir")
	for skill: SkillData in view._slots:
		var node: SkillSlot = view._slots[skill]
		node.mouse_entered.emit()
		check(view._card.shown_text() == run.skill_info(skill).plain_text(), "hover em %s troca o card" % skill.id)
		check(node.selected, "%s fica marcado" % skill.id)
		node.mouse_exited.emit()
		check(view._card.shown_text() == run.skill_info(skill).plain_text(), "card permanece em %s" % skill.id)
	await _move_mouse(view._slots[basic].get_global_rect().get_center())
	check(view._card.shown_text() == run.skill_info(basic).plain_text(), "hover real na janela troca o card")
	await _move_mouse(Vector2(1.0, 1.0))
	var before: String = view._card.shown_text()
	sheet.unspent_points += 1
	sheet.spend_point(&"intelligence")
	await _frames(1)
	check(view._card.shown_text() != before and view._card.shown_text() == run.skill_info(basic).plain_text(), "novo atributo atualiza o card")
	await _press_key(&"menu_skills")
	check(screen._window == null, "tecla K fecha a árvore")
	await _frames(1)
	# Sem liberar o objeto: ao ser liberado, o motor removeria a conexão mesmo sem `_exit_tree`.
	var detached := SkillTreeView.new()
	detached.bind(sheet, run.skill_info)
	add_child(detached)
	check(sheet.changed.get_connections().size() == listeners + 1, "árvore aberta escuta a ficha")
	remove_child(detached)
	check(sheet.changed.get_connections().size() == listeners, "sair da cena solta a ficha")
	detached.free()
	var menu: Dictionary = {}
	for node in screen.hud.find_children("*", "Button", true, false):
		menu[(node as Button).text] = node
	check(menu.size() == Hud.MENU_ICONS.size(), "botões do menu presentes")
	for entry: Array in Hud.MENU_ICONS:
		var button: Button = menu.get(entry[0])
		check(button != null and button.get_viewport_rect().encloses(button.get_global_rect()), "botão %s dentro da tela" % entry[0])
	(menu["K"] as Button).pressed.emit()
	await _frames(1)
	check(screen._window_action == &"menu_skills", "botão do HUD abre a árvore")
	screen.close_window()
	await _use_real_screen(false)


## A ponte entre combate e card: tem de ler os atributos com buff e o multiplicador do jogador,
## nos dois tipos de ataque. Os esperados são calculados aqui, sem passar pelas fórmulas do jogo.
func _test_skill_info_reads_live_stats() -> void:
	var run: DungeonRun = _screen().run
	var unit: Combatant = run.player.combatant
	var physical: SkillData = GameDB.class_by_id(&"warrior").basic_attack
	var magical: SkillData = GameDB.class_by_id(&"mage").basic_attack
	unit.apply_effect(load("res://data/effects/blessing.tres"), unit)
	unit.damage_multiplier = 0.75
	check(unit.stats.phys_attack > unit.base_stats.phys_attack, "bênção aumenta o ataque físico")
	check(unit.stats.magic_attack > unit.base_stats.magic_attack, "bênção aumenta o ataque mágico")
	var expected_physical: float = unit.stats.phys_attack * physical.power * unit.damage_multiplier
	var expected_magical: float = unit.stats.magic_attack * magical.power * unit.damage_multiplier
	check(absf(run.skill_info(physical).damage - expected_physical) < 0.001, "skill_info lê o ataque físico vivo")
	check(absf(run.skill_info(magical).damage - expected_magical) < 0.001, "skill_info lê o ataque mágico vivo")
	unit.damage_multiplier = 1.0
	unit._clear_effects()
	unit.shield = 0.0


## A janela não pode crescer além do tamanho previsto em nenhuma classe nem habilidade.
func _test_skill_tree_fits_every_class() -> void:
	var layer: CanvasLayer = _screen()._window_layer
	for class_data in GameDB.catalog.classes:
		var sheet := CharacterSheet.new(class_data, GameDB.balance)
		sheet.equip_directly(class_data.starter_weapons[0])
		sheet.equip_directly(class_data.starter_armors[0])
		var view := SkillTreeView.new()
		view.bind(sheet, func(skill: SkillData) -> SkillInfo: return SkillInfo.describe(skill, sheet.derived_stats(), GameDB.balance))
		var window: WindowFrame = WindowFrame.wrap("Árvore de Habilidades", view, SkillTreeView.WINDOW_SIZE, true)
		window.theme = UiKit.theme()
		layer.add_child(window)
		for skill: SkillData in view._slots:
			view.select(skill)
			await _frames(2)
			check(window.get_combined_minimum_size().y <= SkillTreeView.WINDOW_SIZE.y, "janela comporta %s (%.0f)" % [skill.id, window.get_combined_minimum_size().y])
		window.queue_free()
		await _frames(1)


func _test_forge_station_and_equip() -> void:
	var screen: DungeonScreen = _screen()
	var run: DungeonRun = screen.run
	var sheet: CharacterSheet = run.sheet
	var station: ForgeBrazier = run.world.props.forge_stations[1]
	run.player.teleport_to(station.global_position + Vector3(-2.0, 0.2, 0.0))
	await _frames(12)
	check(run.combat.interactable == station, "braseiro da forja detectado")
	run.combat._interact()
	await _frames(2)
	check(screen._window_action == &"menu_forge", "braseiro abre a forja")

	var recipe: RecipeData = null
	for candidate in GameDB.recipes_for(&"mage"):
		if candidate.result.id == &"mage_t1_boots":
			recipe = candidate
	for ingredient: ItemData in recipe.ingredients:
		sheet.inventory.add(ingredient.id, recipe.ingredients[ingredient])
	sheet.inventory.add_crystals(recipe.mana_crystal_cost)
	sheet.level = maxi(sheet.level, recipe.result.required_level)
	var view: ForgeView = screen._window.find_children("*", "ForgeView", true, false)[0]
	view._selected = recipe
	view._refresh()
	await _frames(1)
	view._on_forge()
	await _frames(1)
	check(sheet.inventory.count_of(recipe.result.id) == 1, "forja pela interface entrega o item")
	check(FileAccess.file_exists(Session.save_path), "forjar salva o jogo")
	screen.close_window()
	await _frames(1)

	var speed_before: float = run.player.combatant.stats.move_speed
	screen.toggle_window(&"menu_inventory")
	await _frames(2)
	var inventory: InventoryView = screen._window.find_children("*", "InventoryView", true, false)[0]
	inventory._on_item_pressed(recipe.result)
	await _frames(2)
	check(sheet.equipment.get(ItemData.Kind.BOOTS) == recipe.result, "equipa pela interface")
	check(run.player.combatant.stats.move_speed > speed_before, "equipar muda atributos durante a partida")
	screen.close_window()
	await _frames(1)
	sheet.unspent_points = 2
	var attack_before: float = run.player.combatant.base_stats.magic_attack
	sheet.spend_point(&"intelligence")
	await _frames(1)
	check(run.player.combatant.base_stats.magic_attack > attack_before, "ponto de atributo vale na hora")


func _test_graphics_presets() -> void:
	var world: DungeonWorld = _screen().run.world
	for quality: DungeonEnvironment.Quality in [DungeonEnvironment.Quality.LOW, DungeonEnvironment.Quality.HIGH, DungeonEnvironment.Quality.MEDIUM]:
		world.apply_quality(quality)
		await _frames(2)
		check(world.quality == quality, "preset %s aplicado" % quality)


func _test_containment() -> void:
	var run: DungeonRun = _screen().run
	var field: DungeonField = run.world.field
	var entrance: RoomData = run.dungeon.room_of_kind(RoomData.Kind.ENTRANCE)
	var outside: Vector2 = entrance.center + Vector2(entrance.radius + 1.0, 0.0)
	check(not field.is_walkable(outside, 0.0), "ponto de teste está fora da área jogável")
	run.player.teleport_to(field.ground_position(outside, 0.1))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var position_3d: Vector3 = run.player.global_position
	check(field.is_walkable(Vector2(position_3d.x, position_3d.z), 0.3), "jogador fora do mapa volta para dentro")
	check(run.containment_rescues == 1, "resgate registrado uma vez")


## O trono é sólido para física e navegação: a câmera não entra nele nem no nicho atrás do encosto.
func _test_throne_is_solid() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var field: DungeonField = run.world.field
	var blocks: Array[AABB] = run.world.props.block_obstacles
	check(blocks.size() == 1, "trono registra um bloco sólido")
	if blocks.is_empty():
		return
	var block: AABB = blocks[0]
	var rescues_before: int = run.containment_rescues
	# Inimigos e aliados ficam parados para não interferir na caminhada.
	var frozen: Dictionary[Node, Node.ProcessMode] = {}
	for node in get_tree().get_nodes_in_group(&"enemies"):
		frozen[node] = node.process_mode
	for bot in run.bots:
		frozen[bot] = bot.process_mode
	for node in frozen:
		node.process_mode = Node.PROCESS_MODE_DISABLED

	var camera_zone: AABB = block.grow(0.3)
	var middle: Vector3 = block.get_center()
	var lane_z: float = block.end.z - 4.0
	var runs: Array[Dictionary] = [
		{"name": "de frente", "start": Vector2(middle.x, block.position.z - 4.0), "target": Vector2(middle.x, middle.z)},
		{"name": "pela lateral oeste", "start": Vector2(block.position.x - 3.5, lane_z), "target": Vector2(middle.x, lane_z)},
		{"name": "pela lateral leste", "start": Vector2(block.end.x + 3.5, lane_z), "target": Vector2(middle.x, lane_z)},
	]
	for entry in runs:
		var start: Vector2 = entry["start"]
		var target: Vector2 = entry["target"]
		check(field.is_walkable(start, 0.3), "trono (%s): ponto de partida é caminhável" % entry["name"])
		player.teleport_to(run.world.ground_at(start, 0.1))
		player.look_at_point(Vector3(target.x, player.camera.global_position.y, target.y))
		await get_tree().physics_frame
		Input.action_press(&"move_forward")
		var camera_inside: bool = false
		var closest: float = INF
		for _i in 120:
			await get_tree().physics_frame
			var eye: Vector3 = player.camera.global_position
			if camera_zone.has_point(eye):
				camera_inside = true
			closest = minf(closest, _distance_to_block_footprint(eye, block))
		Input.action_release(&"move_forward")
		check(not camera_inside, "trono (%s): câmera fica fora da caixa ampliada em 0,3 m (mais perto: %.2f m)" % [entry["name"], closest])
		var reached := Vector2(player.global_position.x, player.global_position.z)
		check(reached.distance_to(start) > 1.0, "trono (%s): jogador chegou a andar" % entry["name"])
		await _frames(3)

	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var rays: Array[Dictionary] = [
		{"name": "frente do assento", "from": Vector3(middle.x, 1.6, block.position.z - 3.0), "to": Vector3(middle.x, 1.6, block.position.z + 1.0)},
		{"name": "nicho vindo do oeste", "from": Vector3(block.position.x - 3.0, 1.6, lane_z), "to": Vector3(middle.x, 1.6, lane_z)},
		{"name": "nicho vindo do leste", "from": Vector3(block.end.x + 3.0, 1.6, lane_z), "to": Vector3(middle.x, 1.6, lane_z)},
	]
	for entry in rays:
		var query := PhysicsRayQueryParameters3D.create(entry["from"], entry["to"], 1)
		var hit: Dictionary = space.intersect_ray(query)
		check(not hit.is_empty(), "raio horizontal a 1,6 m (%s) acerta a camada 1" % entry["name"])

	var map: RID = run.world.navigation_map()
	var from_point: Vector3 = run.world.ground_at(Vector2(block.position.x - 3.5, lane_z))
	var to_point: Vector3 = run.world.ground_at(Vector2(block.end.x + 3.5, lane_z))
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, from_point, to_point, true)
	check(path.size() >= 3, "navmesh acha caminho de um lado ao outro do trono (%d pontos)" % path.size())
	var length: float = 0.0
	var cuts_block: bool = false
	var footprint := Rect2(Vector2(block.position.x, block.position.z), Vector2(block.size.x, block.size.z)).grow(0.4)  # raio do corpo do jogador
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
		var segment_start := Vector2(path[i - 1].x, path[i - 1].z)
		var segment_end := Vector2(path[i].x, path[i].z)
		for step in 41:
			if footprint.has_point(segment_start.lerp(segment_end, float(step) / 40.0)):
				cuts_block = true
	check(not cuts_block, "caminho da navmesh contorna o bloco do trono com folga para o corpo")
	check(length > from_point.distance_to(to_point) + 2.0, "caminho é mais longo que a reta (%.1f m contra %.1f m)" % [length, from_point.distance_to(to_point)])

	for node in frozen:
		if is_instance_valid(node):
			node.process_mode = frozen[node]
	player.teleport_to(field.ground_position(Vector2(middle.x, block.position.z - 10.0), 0.1))
	player.combatant.restore_full()
	await _frames(3)
	check(run.containment_rescues == rescues_before, "andar contra o trono não aciona resgate de contenção")


## Distância horizontal de um ponto à pegada do bloco (0 quando está dentro).
func _distance_to_block_footprint(point: Vector3, block: AABB) -> float:
	var dx: float = maxf(maxf(block.position.x - point.x, point.x - block.end.x), 0.0)
	var dz: float = maxf(maxf(block.position.z - point.z, point.z - block.end.z), 0.0)
	return Vector2(dx, dz).length()


## Anda contra `target` por `seconds` a partir de `start`. Devolve a posição final e a menor distância horizontal da câmera a `axis`.
func _walk_toward(player: PlayerController, start: Vector3, target: Vector3, seconds: float, axis: Vector3) -> Dictionary:
	player.teleport_to(start)
	player.look_at_point(Vector3(target.x, player.camera.global_position.y, target.z))
	await get_tree().physics_frame
	Input.action_press(&"move_forward")
	var closest_eye: float = INF
	for _i in roundi(seconds * 60.0):
		await get_tree().physics_frame
		var eye: Vector3 = player.camera.global_position
		closest_eye = minf(closest_eye, Vector2(eye.x - axis.x, eye.z - axis.z).length())
	Input.action_release(&"move_forward")
	await _frames(3)
	return {"end": player.global_position, "closest_eye": closest_eye}


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _set_actors_active(actors: Array[Node], active: bool) -> void:
	for actor in actors:
		if is_instance_valid(actor):
			actor.set_process(active)
			actor.set_physics_process(active)


## O chefe ocupa espaço para o jogador (a câmera não entra sob a armadura); monstros comuns continuam atravessáveis.
func _test_boss_blocks_bodies() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var field: DungeonField = run.world.field
	var boss: Enemy = run.boss
	check(boss.data.blocks_bodies, "chefe declara que bloqueia corpos")
	check(boss.collision_layer & CombatWorld.SOLID_BODY_LAYER != 0, "chefe vivo está na camada de corpo sólido")
	check(player.collision_mask & CombatWorld.SOLID_BODY_LAYER != 0, "máscara do jogador enxerga corpos sólidos")
	check(run.bots[0].collision_mask & CombatWorld.SOLID_BODY_LAYER != 0, "máscara dos aliados enxerga corpos sólidos")
	check(boss.collision_mask & CombatWorld.SOLID_BODY_LAYER == 0, "chefe não enxerga corpos sólidos (ele empurra)")
	var rescues_before: int = run.containment_rescues
	# Parados sem sair do espaço físico: PROCESS_MODE_DISABLED removeria os corpos da simulação.
	var frozen: Array[Node] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		frozen.append(node)
	for bot in run.bots:
		frozen.append(bot)
	_set_actors_active(frozen, false)

	var axis: Vector3 = boss.global_position
	var start: Vector3 = field.ground_position(Vector2(axis.x, axis.z - 5.0), 0.1)
	var reach: float = boss.data.body_radius + player.get_node("CollisionShape3D").shape.radius
	var result: Dictionary = await _walk_toward(player, start, axis, 1.5, axis)
	var end: Vector3 = result["end"]
	var stopped_at: float = axis.z - end.z  # positivo = ainda do lado de cá do eixo
	check(stopped_at >= 1.85, "jogador parado pelo chefe a %.2f m do eixo (mínimo 1,85 m)" % stopped_at)
	var live_ray := PhysicsRayQueryParameters3D.create(Vector3(axis.x, 1.6, axis.z - 6.0), Vector3(axis.x, 1.6, axis.z), CombatWorld.SOLID_BODY_LAYER)
	check(not player.get_world_3d().direct_space_state.intersect_ray(live_ray).is_empty(), "raio horizontal a 1,6 m acerta o chefe vivo na camada sólida")
	check(_flat_distance(end, start) > 1.0, "jogador chegou a andar até o chefe")
	check(float(result["closest_eye"]) >= boss.data.body_radius, "câmera não entra na cápsula do chefe (%.2f m do eixo)" % float(result["closest_eye"]))
	check(reach >= 1.85, "teste usa um limite coerente com a soma dos raios (%.2f m)" % reach)

	var goblin: Enemy = run.spawn_monster(load("res://data/monsters/goblin.tres"), field.ground_position(Vector2(axis.x - 14.0, axis.z - 6.0), 0.1))
	goblin.is_summon = true
	_set_actors_active([goblin], false)
	check(goblin.collision_layer & CombatWorld.SOLID_BODY_LAYER == 0, "monstro comum fica fora da camada de corpo sólido")
	await get_tree().physics_frame
	var goblin_axis: Vector3 = goblin.global_position
	var goblin_start: Vector3 = field.ground_position(Vector2(goblin_axis.x, goblin_axis.z - 3.0), 0.1)
	var through: Dictionary = await _walk_toward(player, goblin_start, goblin_axis, 1.5, goblin_axis)
	var goblin_end: Vector3 = through["end"]
	check(goblin_end.z > goblin_axis.z + 1.0, "monstro comum continua atravessável (parou a %.2f m além do eixo)" % (goblin_end.z - goblin_axis.z))
	goblin.free()

	_set_actors_active(frozen, true)
	player.teleport_to(field.ground_position(Vector2(axis.x, axis.z - 12.0), 0.1))
	player.combatant.restore_full()
	await _frames(3)
	check(run.containment_rescues == rescues_before, "andar contra o chefe não aciona resgate de contenção")


## Cadáver do chefe sai da camada sólida: nem corpo sólido nem raio de mira o encontram.
func _check_boss_corpse_is_not_solid(boss: Enemy) -> void:
	var player: PlayerController = _screen().run.player
	check(boss.collision_layer == 0, "cadáver do chefe sai de todas as camadas")
	var axis: Vector3 = boss.global_position
	var query := PhysicsRayQueryParameters3D.create(Vector3(axis.x, 1.6, axis.z - 6.0), Vector3(axis.x, 1.6, axis.z), CombatWorld.SOLID_BODY_LAYER | 8)
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.is_empty(), "raio contra o cadáver do chefe não acerta nada")


func _actors_to_freeze(run: DungeonRun) -> Array[Node]:
	var actors: Array[Node] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		actors.append(node)
	for bot in run.bots:
		actors.append(bot)
	return actors


## Lampejo e investida sem alvo, de frente para o chefe, param antes do corpo dele e não derrubam o jogador.
func _test_gap_closers_stop_at_boss() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var field: DungeonField = run.world.field
	var axis: Vector3 = run.boss.global_position
	var frozen: Array[Node] = _actors_to_freeze(run)
	_set_actors_active(frozen, false)
	var rescues_before: int = run.containment_rescues
	var cases: Array[Dictionary] = [
		{"skill": load("res://data/skills/m_blink.tres"), "distance": 10.0},
		{"skill": load("res://data/skills/w_charge.tres"), "distance": 13.0},
	]
	for entry in cases:
		var skill: SkillData = entry["skill"]
		var distance: float = entry["distance"]
		var start: Vector3 = field.ground_position(Vector2(axis.x, axis.z - distance), 0.1)
		player.teleport_to(start)
		player.look_at_point(Vector3(axis.x, player.camera.global_position.y, axis.z))
		await _frames(20)
		var aim := SkillAim.new()
		aim.origin = player.combatant.center_position()
		aim.direction = Vector3(0.0, 0.0, 1.0)
		SkillExecutor.execute(skill, player.combatant, aim)
		await _frames(60)
		var label: String = String(skill.id)
		var stopped_at: float = axis.z - player.global_position.z
		var floor_y: float = field.floor_at(Vector2(player.global_position.x, player.global_position.z))
		check(stopped_at >= 1.85, "%s: para a %.2f m do eixo do chefe (mínimo 1,85 m)" % [label, stopped_at])
		check(absf(player.global_position.y - floor_y) <= 0.2, "%s: termina no chão (y %.2f, piso %.2f)" % [label, player.global_position.y, floor_y])
		await _frames(120)
		floor_y = field.floor_at(Vector2(player.global_position.x, player.global_position.z))
		check(absf(player.global_position.y - floor_y) <= 0.2, "%s: continua no chão 2 s depois (y %.2f)" % [label, player.global_position.y])
	check(run.containment_rescues == rescues_before, "habilidades de avanço não dependem de resgate")
	_set_actors_active(frozen, true)
	player.teleport_to(field.ground_position(Vector2(axis.x, axis.z - 12.0), 0.1))
	await _frames(3)


## Quem acaba dentro do eixo do chefe (teleporte, empurrão) volta ao chão fora da cápsula.
func _test_fallen_body_is_rescued() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var field: DungeonField = run.world.field
	var boss: Enemy = run.boss
	var axis: Vector3 = boss.global_position
	var frozen: Array[Node] = _actors_to_freeze(run)
	_set_actors_active(frozen, false)
	var rescues_before: int = run.containment_rescues
	# A queda depende da penetração exata no Jolt: tenta algumas posições a até 0,1 m do eixo.
	var center := Vector2(axis.x, axis.z)
	for offset: Vector2 in [Vector2(0.05, 0.0), Vector2(0.1, 0.0), Vector2(0.0, -0.1)]:
		player.teleport_to(field.ground_position(center + offset))
		await _frames(120)
		var here := Vector2(player.global_position.x, player.global_position.z)
		var floor_y: float = field.floor_at(here)
		check(absf(player.global_position.y - floor_y) <= 0.2, "jogador a %.2f m do eixo do chefe está no chão em 2 s (y %.2f, piso %.2f)" % [offset.length(), player.global_position.y, floor_y])
		check(here.distance_to(center) >= boss.data.body_radius + 0.4, "e fora da cápsula do chefe (%.2f m do eixo)" % here.distance_to(center))
	check(run.containment_rescues > rescues_before, "ao menos uma das quedas contou como resgate de contenção")
	_set_actors_active(frozen, true)
	player.teleport_to(field.ground_position(Vector2(axis.x, axis.z - 12.0), 0.1))
	await _frames(3)


## Invocações do chefe perto do trono nascem em chão seguro, fora do bloco, e ficam nele.
func _test_summons_avoid_throne_block() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var field: DungeonField = run.world.field
	var block: AABB = run.world.props.block_obstacles[0]
	var skeleton: MonsterData = load("res://data/monsters/skeleton.tres")
	var boss_spot := Vector2(127.0, 124.0)
	# Longe do raio de agressão do chefe (20 m) e com ele parado, para não despertá-lo.
	var frozen: Array[Node] = _actors_to_freeze(run)
	_set_actors_active(frozen, false)
	player.teleport_to(field.ground_position(Vector2(124.0, 83.0), 0.1))
	run._on_boss_summon(skeleton, 8, field.ground_position(boss_spot))
	var summons: Array[Enemy] = run._summons.duplicate()
	check(summons.size() == 8, "oito invocações nascem")
	var zone := Rect2(Vector2(block.position.x, block.position.z), Vector2(block.size.x, block.size.z)).grow(skeleton.body_radius)
	for enemy in summons:
		var here := Vector2(enemy.global_position.x, enemy.global_position.z)
		check(not zone.has_point(here), "invocação nasce fora do bloco do trono (%s)" % here.snapped(Vector2(0.01, 0.01)))
	await _frames(120)
	for enemy in summons:
		if not is_instance_valid(enemy):
			continue
		var floor_y: float = run.world.ground_at(Vector2(enemy.global_position.x, enemy.global_position.z)).y
		check(absf(enemy.global_position.y - floor_y) <= 0.5, "invocação segue no chão 2 s depois (y %.2f, piso %.2f)" % [enemy.global_position.y, floor_y])
	run._clear_summons()
	# Corpo que acaba fundo no bloco (aqui, preso de propósito) sai pela lateral: o fundo do bloco não oferece saída para baixo.
	var trapped: Enemy = run.spawn_monster(skeleton, run.world.ground_at(Vector2(block.get_center().x, block.position.z + 2.45), 0.1))
	trapped.is_summon = true
	var lowest: float = INF
	for _i in 90:
		await get_tree().physics_frame
		lowest = minf(lowest, trapped.global_position.y)
	check(lowest > -0.5, "corpo no meio do bloco não afunda no piso (menor y %.2f)" % lowest)
	trapped.free()
	_set_actors_active(frozen, true)
	await _frames(3)


## De costas para o trono, o ponto de formação cai dentro do bloco; o renascimento do aliado não.
func _test_ally_respawn_avoids_throne_block() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var field: DungeonField = run.world.field
	var block: AABB = run.world.props.block_obstacles[0]
	var zone := Rect2(Vector2(block.position.x, block.position.z), Vector2(block.size.x, block.size.z))
	player.teleport_to(run.world.ground_at(Vector2(block.get_center().x, block.position.z - 1.0), 0.1))
	player.look_at_point(Vector3(block.get_center().x, player.camera.global_position.y, block.position.z - 10.0))
	var inside_raw: int = 0
	for bot in run.bots:
		if zone.has_point(Vector2(bot.formation_point().x, bot.formation_point().z)):
			inside_raw += 1
		var spot: Vector3 = bot.respawn_point()
		check(not zone.grow(0.4).has_point(Vector2(spot.x, spot.z)), "renascimento de %s fica fora do bloco do trono" % bot.name)
	check(inside_raw > 0, "cenário válido: ao menos um ponto de formação cai dentro do bloco")
	player.teleport_to(field.ground_position(Vector2(block.get_center().x, block.position.z - 12.0), 0.1))
	await _frames(3)


## O tablado do trono é uma rampa: sobe-se andando, os pés seguem a superfície visual, a navmesh cobre
## o topo e o que cai em cima fica na superfície.
func _test_throne_platform_is_a_ramp() -> void:
	var run: DungeonRun = _screen().run
	var world: DungeonWorld = run.world
	var player: PlayerController = run.player
	var platform: RampPlatform = world.props.platforms[0]
	var center: Vector2 = platform.center
	var block: AABB = world.props.block_obstacles[0]
	var block_zone := Rect2(Vector2(block.position.x, block.position.z), Vector2(block.size.x, block.size.z)).grow(0.3)
	var frozen: Array[Node] = _actors_to_freeze(run)
	_set_actors_active(frozen, false)
	var rescues_before: int = run.containment_rescues

	# a. Anda da borda até o topo, de frente para o trono e pela lateral.
	var approaches: Array[Dictionary] = [
		{"name": "pelo sul", "direction": Vector2(0.0, -1.0)},
		{"name": "pelo oeste", "direction": Vector2(-1.0, 0.0)},
	]
	for entry in approaches:
		var direction: Vector2 = entry["direction"]
		var start_flat: Vector2 = center + direction * (platform.base_radius + 1.0)
		var start: Vector3 = world.ground_at(start_flat, 0.1)
		var result: Dictionary = await _walk_toward(player, start, Vector3(center.x, 0.0, center.y), 3.0, Vector3(center.x, 0.0, center.y))
		var end: Vector3 = result["end"]
		var radius: float = Vector2(end.x - center.x, end.z - center.y).length()
		check(radius <= platform.top_radius, "tablado (%s): chegou ao topo, a %.2f m do centro" % [entry["name"], radius])
		check(absf(end.y - platform.height) <= 0.1, "tablado (%s): pé a %.2f m (esperado %.2f)" % [entry["name"], end.y, platform.height])
	# Descer também gruda no chão, sem voar pela rampa.
	var down: Dictionary = await _walk_toward(player, world.ground_at(center + Vector2(0.0, -2.0), 0.1), world.ground_at(center + Vector2(0.0, -20.0)), 2.0, Vector3.ZERO)
	var landed: Vector3 = down["end"]
	check(absf(landed.y - _platform_surface(world, platform, Vector2(landed.x, landed.z))) <= 0.1 and player.is_on_floor(), "tablado: descida termina no chão (y %.2f)" % landed.y)

	# b. Em toda a rampa a colisão coincide com a superfície visual.
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var tested: int = 0
	var worst: float = 0.0
	for radius: float in [5.1, 5.6, 6.25, 6.9, 7.4]:
		for step in 16:
			var angle: float = TAU * (float(step) + 0.37) / 16.0
			var spot: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
			var near_pillar: bool = false
			for pillar in world.props.pillar_obstacles:
				if spot.distance_to(Vector2(pillar.x, pillar.y)) < pillar.z + 0.1:
					near_pillar = true
			if block_zone.has_point(spot) or near_pillar or not world.field.is_walkable(spot, 0.0):
				continue
			var query := PhysicsRayQueryParameters3D.create(Vector3(spot.x, 3.0, spot.y), Vector3(spot.x, -1.0, spot.y), 1)
			var hit: Dictionary = space.intersect_ray(query)
			if hit.is_empty():
				check(false, "tablado: raio em r=%.2f ângulo %.2f não acerta o chão" % [radius, angle])
				continue
			tested += 1
			worst = maxf(worst, absf(hit.position.y - _platform_surface(world, platform, spot)))
	check(tested >= 40, "rampa amostrada em %d pontos" % tested)
	check(worst <= 0.1, "colisão da rampa a até %.3f m da superfície visual" % worst)
	for spot_info: Array in [[Vector2(0.0, -1.0), 5.6], [Vector2(0.0, -1.0), 6.9], [Vector2(-1.0, 0.0), 6.25]]:
		var ramp_spot: Vector2 = center + (spot_info[0] as Vector2) * float(spot_info[1])
		player.teleport_to(world.ground_at(ramp_spot, 0.6))
		await _frames(40)
		var expected: float = _platform_surface(world, platform, Vector2(player.global_position.x, player.global_position.z))
		check(absf(player.global_position.y - expected) <= 0.1 and player.is_on_floor(), "pé na rampa (r=%.2f): y %.2f, superfície %.2f" % [float(spot_info[1]), player.global_position.y, expected])

	# c. A navmesh sobe pela rampa até o topo.
	var map: RID = world.navigation_map()
	var from_point: Vector3 = world.ground_at(center + Vector2(0.0, -platform.base_radius - 1.5))
	var to_point: Vector3 = world.ground_at(center + Vector2(0.0, -3.0))
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, from_point, to_point, true)
	check(path.size() >= 2, "navmesh acha caminho do chão ao topo (%d pontos)" % path.size())
	if path.size() >= 2:
		# A altura da navmesh é deslocada pelo raio do agente, então compara-se a subida, não o valor absoluto.
		var rise: float = path[path.size() - 1].y - path[0].y
		check(rise >= platform.height - 0.15, "caminho sobe %.2f m do chão ao topo (tablado: %.2f m)" % [rise, platform.height])
		check(Vector2(path[path.size() - 1].x - to_point.x, path[path.size() - 1].z - to_point.z).length() < 1.0, "caminho chega perto do destino no topo")

	# d. O que cai em cima do tablado fica na superfície, não dentro dela.
	player.teleport_to(world.ground_at(Vector2(center.x, 90.0), 0.1))
	await _frames(3)
	var existing: Array[Node] = []
	for child in run.get_children():
		if child is LootDrop:
			existing.append(child)
	var drops: Array[LootRoller.Drop] = []
	for _i in 6:
		drops.append(LootRoller.Drop.new(GameDB.item(&"potion_hp"), 1))
	run._scatter_loot(drops, world.ground_at(center + Vector2(0.0, -3.0)))
	var landed_loot: int = 0
	for child in run.get_children():
		if child is LootDrop and not existing.has(child):
			landed_loot += 1
			var loot_flat := Vector2(child.global_position.x, child.global_position.z)
			var surface: float = _platform_surface(world, platform, loot_flat)
			check(absf(child.global_position.y - surface) <= 0.15, "loot sobre o tablado a %.2f m, superfície %.2f" % [child.global_position.y, surface])
			child.free()
	check(landed_loot == 6, "seis itens de loot criados")

	check(run.containment_rescues == rescues_before, "o tablado não aciona resgate de contenção")
	_set_actors_active(frozen, true)
	player.teleport_to(world.ground_at(Vector2(center.x, 100.0), 0.1))
	await _frames(3)



## Superfície esperada, calculada sem `DungeonWorld.ground_at`: o maior entre o piso do campo e o tablado.
func _platform_surface(world: DungeonWorld, platform: RampPlatform, point: Vector2) -> float:
	return maxf(world.field.floor_at(point), platform.surface_height_at(point))

func _test_guard_breaks_without_mana() -> void:
	var run: DungeonRun = _screen().run
	var unit: Combatant = run.player.combatant
	unit.mp = 1.0
	Input.action_press(&"guard")
	for _i in 30:
		unit.mark_in_combat()
		await get_tree().process_frame
	check(not run.combat.is_guarding(), "defesa cai sem mana mesmo com regeneração")
	check(unit.guard_multiplier == 1.0, "dano volta ao normal")
	for _i in 30:
		unit.mark_in_combat()
		await get_tree().process_frame
	check(not run.combat.is_guarding(), "defesa não pisca enquanto o botão segue pressionado")
	Input.action_release(&"guard")
	await _frames(3)
	unit.restore_full()
	Input.action_press(&"guard")
	await _frames(3)
	check(run.combat.is_guarding(), "defesa volta ao soltar e apertar de novo")
	Input.action_release(&"guard")
	await _frames(3)


func _living_enemies() -> int:
	var count: int = 0
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if not node.is_queued_for_deletion() and (node as Enemy).combatant.is_alive():
			count += 1
	return count


## Personagens reais: distingue o jogador dos aliados e passa pela entrada de defesa.
func _test_skill_sounds() -> void:
	var run: DungeonRun = _screen().run
	var player: PlayerController = run.player
	var mage: ClassData = Session.active_sheet.class_data
	var sfx: SfxDirector = _sfx()
	var bolt: SkillData = mage.basic_attack
	var ally: Combatant = run.bots[0].combatant
	player.combatant.restore_full()
	player.caster.reset_all()
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	# Um aliado no mesmo quadro não pode calar o som do próprio jogador.
	Events.skill_fired.emit(bolt, ally)
	check(player.caster.try_cast(bolt, run.combat.build_aim(bolt)), "jogador dispara a seta")
	var own: AudioStreamPlayer3D = _sfx_voice("m_bolt_cast", false)
	check(own != null, "som do jogador toca junto com o do aliado")
	if own != null:
		var clip: SoundClip = sfx.bank.sounds[sfx.bank.sounds.find(sfx._sounds[bolt.id])].fire
		check(own.volume_db == clip.volume_db, "jogador sem redução de aliado")
		check(own.panning_strength == 0.0, "som do jogador não dança entre os ouvidos")
	check(_sfx_voice("m_bolt_cast", true) != null, "som do aliado fica no mundo")
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	var raised: Array[StringName] = []
	var on_raised := func(class_id: StringName, _unit: Combatant) -> void: raised.append(class_id)
	Events.guard_raised.connect(on_raised)
	var fireball: SkillData = GameDB.catalog.classes[GameDB.catalog.classes.find(mage)].skills[0]
	player.caster.reset_all()
	check(fireball.cast_time > 0.0 and player.caster.try_cast(fireball, run.combat.build_aim(fireball)), "jogador conjura")
	check(_sfx_voice("m_fire_charge", false) != null, "preparo do jogador toca")
	Input.action_press(&"guard")
	await _frames(10)
	check(_sfx_voice("m_fire_charge", false) == null, "defender interrompe e corta o preparo")
	Input.action_release(&"guard")
	await _frames(3)
	Input.action_press(&"guard")
	await _frames(3)
	Input.action_release(&"guard")
	await _frames(3)
	Events.guard_raised.disconnect(on_raised)
	check(raised == ([mage.id, mage.id] as Array[StringName]), "defesa avisa uma vez a cada vez que sobe")


func _test_summons_belong_to_the_encounter() -> void:
	var run: DungeonRun = _screen().run
	var boss: Enemy = run.boss
	var director: BossDirector = boss.get_node("BossDirector")
	var skill := SkillData.new()
	skill.damage_kind = SkillData.DamageKind.NONE
	var crystals_before: int = run.crystals_gained
	var kills_before: int = run.kills
	var living_before: int = _living_enemies()
	boss.combatant.hp = boss.combatant.stats.max_hp * 0.5
	boss.combatant.health_changed.emit(boss.combatant.hp, boss.combatant.stats.max_hp)
	await _frames(2)
	check(_living_enemies() == living_before + 3, "fase 2 invoca 3 monstros")
	check(boss.combatant.stun_immune, "chefe é imune a atordoamento")
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	var summon: Enemy = enemies[enemies.size() - 1]
	check(summon.is_summon, "invocado marcado")
	_kill(summon.combatant)
	await _frames(2)
	check(run.crystals_gained == crystals_before, "invocado não dá recompensa")
	check(run.kills == kills_before, "invocado não conta como abate")
	boss.machine.transition(&"chase")
	check(_music().current == MusicDirector.Track.BOSS, "aggro do chefe toca a música de batalha")
	boss.machine.transition(&"idle")
	check(_music().current == MusicDirector.Track.DUNGEON, "chefe reiniciado devolve a música da masmorra")
	await _frames(3)
	check(_living_enemies() == living_before, "reiniciar o chefe remove os invocados")
	check(director.current_phase == 0, "fases reiniciadas")
	boss.combatant.restore_full()


## Em "return" o chefe pode voltar a "chase" sem novo boss_engaged: só "idle" encerra a luta.
func _test_music_survives_boss_leash() -> void:
	var boss: Enemy = _screen().run.boss
	boss.machine.transition(&"chase")
	boss.machine.transition(&"return")
	check(_music().current == MusicDirector.Track.BOSS, "chefe voltando para casa mantém a batalha")
	boss.machine.transition(&"chase")
	check(_music().current == MusicDirector.Track.BOSS, "retomar a perseguição mantém a batalha")
	boss.machine.transition(&"return")
	await _frames(3)
	check(boss.machine.current_name == &"idle", "chefe chegou em casa")
	check(_music().current == MusicDirector.Track.DUNGEON, "chefe em casa devolve a música da masmorra")


func _kill(unit: Combatant) -> void:
	var skill := SkillData.new()
	skill.power = 100000.0
	var run: DungeonRun = _screen().run
	while unit.is_alive():
		unit.receive_hit(run.player.combatant, skill)


func _test_victory_and_return() -> void:
	var screen: DungeonScreen = _screen()
	var run: DungeonRun = screen.run
	var sheet: CharacterSheet = run.sheet
	var door: GateDoor = run.world.props.door
	door.interact(run.player)
	check(not door.is_open, "porta selada sem abates suficientes")
	run.kills = run.kills_required()
	door.interact(run.player)
	check(door.is_open, "porta abre após os abates")
	var boss: Enemy = run.boss
	boss.machine.transition(&"chase")
	check(_music().current == MusicDirector.Track.BOSS, "luta final toca a música de batalha")
	_kill(boss.combatant)
	await _frames(3)
	check(run.boss_defeated_flag, "vitória registrada")
	await _check_boss_corpse_is_not_solid(boss)
	check(_music().current == MusicDirector.Track.DUNGEON, "chefe morto devolve a música da masmorra")
	check(sheet.inventory.count_of(&"boss_core") == 0, "núcleo ainda no chão, não entregue automaticamente")
	var portal: GatePortal = null
	for node in get_tree().get_nodes_in_group(&"interactable"):
		if node is GatePortal:
			portal = node
	check(portal != null, "portal de saída surge")
	portal.interact(run.player)
	await _frames(3)
	check(sheet.inventory.count_of(&"boss_core") >= 1, "item raro recolhido ao sair sem pegar")
	check(screen._window != null, "relatório aparece")
	check(_music().current == MusicDirector.Track.DUNGEON, "resultados seguem com a música da masmorra")
	var results: ResultsView = screen._window.find_children("*", "ResultsView", true, false)[0]
	results.return_requested.emit()
	await _frames(4)
	check(_lobby() != null, "volta ao saguão")
	check(_screen() == null, "masmorra descarregada")
	check(_music().current == MusicDirector.Track.LOBBY, "voltar ao saguão toca a música do saguão")
	check(_main.get_node_or_null("MusicDirector") != null, "diretor de música sobrevive à troca de tela")
	await _frames(2)
	check(_music().current == MusicDirector.Track.LOBBY, "saída da masmorra não silencia o saguão")
	await _frames(4)
	for voice: AudioStreamPlayer3D in _sfx()._voices:
		check(not voice.playing, "efeitos não vazam para o saguão")
	check(get_tree().get_nodes_in_group(&"enemies").is_empty(), "sem monstros órfãos")
	check(get_tree().get_nodes_in_group(&"combatants").is_empty(), "sem combatentes órfãos")


func _finish_run_with_victory() -> void:
	var screen: DungeonScreen = _screen()
	var run: DungeonRun = screen.run
	_kill(run.boss.combatant)
	await _frames(2)
	for node in get_tree().get_nodes_in_group(&"interactable"):
		if node is GatePortal:
			node.interact(run.player)
	await _frames(2)


func _test_results_cannot_trap_the_player() -> void:
	# Saída por Esc
	await _enter_gate_through_ui(_lobby())
	check(_music().current == MusicDirector.Track.DUNGEON, "reentrada volta à música da masmorra")
	await _finish_run_with_victory()
	var screen: DungeonScreen = _screen()
	check(screen.run.is_finished and screen._window != null, "resultados na tela")
	check(screen.run.process_mode == Node.PROCESS_MODE_DISABLED, "mundo parado nos resultados")
	check(not screen.hud.skill_tooltip._cursor_free, "card não cobre os resultados")
	screen.hud.menu_pressed.emit(&"menu_inventory")
	await _frames(2)
	check(screen._window != null and screen._window_action == &"", "HUD não substitui os resultados")
	await _press_key(&"menu_character")
	check(screen._window_action == &"", "tecla de menu não substitui os resultados")
	await _press_key(&"menu_skills")
	check(screen._window_action == &"", "tecla K não substitui os resultados")
	await _press_key(&"menu_pause")
	await _frames(3)
	check(_lobby() != null and _screen() == null, "Esc nos resultados volta ao saguão")
	check(_music().current == MusicDirector.Track.LOBBY, "Esc nos resultados volta à música do saguão")
	# Saída pelo X da janela
	await _enter_gate_through_ui(_lobby())
	check(_music().current == MusicDirector.Track.DUNGEON, "segunda reentrada volta à música da masmorra")
	await _finish_run_with_victory()
	screen = _screen()
	screen._window.closed.emit()
	await _frames(3)
	check(_lobby() != null and _screen() == null, "fechar os resultados volta ao saguão")
	check(_music().current == MusicDirector.Track.LOBBY, "fechar os resultados volta à música do saguão")


func _test_rank_lock_and_tabs() -> void:
	var lobby: Lobby = _lobby()
	var sheet: CharacterSheet = Session.active_sheet
	var dungeon: DungeonData = GameDB.catalog.dungeons[0]
	var saved_level: int = sheet.level
	sheet.level = 9
	lobby.open_tab(&"party")
	await _frames(1)
	lobby._on_rank_chosen(dungeon.ranks[1])
	await _frames(1)
	check(lobby.selected_rank == dungeon.ranks[1], "nível alto escolhe Rank D")
	lobby._on_class_chosen(GameDB.class_by_id(&"priest"))
	await _frames(1)
	check(lobby.selected_rank == dungeon.ranks[0], "trocar para classe nível 1 volta ao Rank E")
	lobby._on_class_chosen(sheet.class_data)
	await _frames(1)
	sheet.level = saved_level
	lobby.open_tab(&"gear")
	await _frames(1)
	lobby.open_tab(&"gear")
	await _frames(2)
	check(sheet.changed.is_connected(lobby._refresh_hero), "reabrir a aba Itens mantém o herói atualizado")


func _test_second_run_keeps_progress() -> void:
	var lobby: Lobby = _lobby()
	var sheet: CharacterSheet = Session.active_sheet
	var core_count: int = sheet.inventory.count_of(&"boss_core")
	var boots: ItemData = sheet.equipment.get(ItemData.Kind.BOOTS)
	check(lobby.selected_class == sheet.class_data, "saguão lembra a classe")
	Session.reset_all()
	check(Session.load_game(), "save da partida existe")
	sheet = Session.active_sheet
	check(sheet.inventory.count_of(&"boss_core") == core_count, "item do chefe persiste no save")
	check(sheet.equipment.get(ItemData.Kind.BOOTS) == boots, "peça forjada persiste no save")
	var fresh: Node = _main
	fresh.call("show_lobby")
	await _frames(3)
	check(_main.get_node_or_null("MusicDirector") != null, "diretor de música sobrevive a show_lobby")
	await _enter_gate_through_ui(_lobby())
	check(_screen().run.sheet == sheet, "segunda partida usa a mesma ficha")
	check(_screen().run.player.combatant.level == sheet.level, "nível aplicado ao combate")


func _test_abandon() -> void:
	var screen: DungeonScreen = _screen()
	screen.run.boss.machine.transition(&"chase")
	check(_music().current == MusicDirector.Track.BOSS, "aggro do chefe antes de abandonar")
	screen._open_pause()
	await _frames(1)
	screen._abandon()
	await _frames(4)
	check(_lobby() != null, "abandonar volta ao saguão")
	check(not get_tree().paused, "abandonar não deixa o jogo pausado")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "cursor visível no saguão")
	var music: MusicDirector = _music()
	check(music.current == MusicDirector.Track.LOBBY, "abandonar a luta volta à música do saguão")
	await _frames(roundi(music.config.crossfade_seconds * 60.0) + 5)
	check(not music._dungeon_player.playing and not music._boss_player.playing, "faixas da masmorra e do chefe não tocam no saguão")
	# O AudioServer libera a faixa parada na thread de mixagem, no relógio real. Com --fixed-fps
	# o teste sairia antes disso e o stream apareceria como vazamento, ao sabor da corrida.
	OS.delay_msec(200)


## Troca de equipamento com a partida rodando, pelo caminho real: inventário, ficha, `changed`, `refresh_player_stats`.
## O inventário não pausa, então a troca pode cair no meio de um golpe.
func _test_viewmodel_swap_in_run() -> void:
	var lobby: Lobby = _lobby()
	var priest: ClassData = GameDB.class_by_id(&"priest")
	lobby._on_class_chosen(priest)
	await _frames(2)
	for weapon in priest.starter_weapons:
		if weapon.weapon_model == &"scepter":
			lobby._on_weapon_chosen(weapon)
	await _frames(2)
	await _enter_gate_through_ui(lobby)
	var screen: DungeonScreen = _screen()
	var sheet: CharacterSheet = screen.run.sheet
	var viewmodel: Viewmodel = screen.run.player.viewmodel
	check(sheet.class_data == priest and sheet.weapon_model() == &"scepter", "partida do sacerdote com scepter")
	sheet.level = 5
	var armor_t1: ItemData = GameDB.item(&"priest_t1_armor")
	var armor_t2: ItemData = GameDB.item(&"priest_t2_armor")
	sheet.inventory.add(armor_t1.id)
	sheet.inventory.add(armor_t2.id)

	# 1. Armadura T2 com a partida rodando: look novo e mãos novas.
	var old_right: Node3D = viewmodel._right
	var old_left: Node3D = viewmodel._left
	check(viewmodel._look.armor_tier == 0, "viewmodel começa em T0")
	await _equip_through_inventory(screen, armor_t2)
	check(sheet.equipment.get(ItemData.Kind.ARMOR) == armor_t2, "armadura T2 equipada pelo inventário")
	check(viewmodel._look.armor_tier == 2, "viewmodel guarda look com armor_tier 2")
	check(viewmodel._right != old_right and viewmodel._left != old_left, "mãos novas")
	check(viewmodel._right.get_parent() == viewmodel and not is_instance_valid(old_right), "mãos antigas saem da árvore")

	# 2. XP e ponto: `changed` dispara e o `setup` retorna cedo, com os mesmos nós.
	var kept: Array[Node] = [viewmodel._right, viewmodel._left, viewmodel._cast_light]
	var changes: Array[int] = [0]
	sheet.changed.connect(func() -> void: changes[0] += 1)
	sheet.add_xp(1)
	sheet.unspent_points = maxi(sheet.unspent_points, 1)
	sheet.spend_point(&"intelligence")
	await _frames(2)
	check(changes[0] >= 2, "XP e ponto disparam changed (%d)" % changes[0])
	check(viewmodel._right == kept[0] and viewmodel._left == kept[1] and viewmodel._cast_light == kept[2], "mãos e luz de cast são os mesmos nós")

	# 3. Armadura no meio de um golpe e de um cast: sem erro, sem nó liberado, mão no repouso.
	var errors_before: int = _errors.count
	viewmodel.play_swing(1)
	await _frames(2)
	check(viewmodel.right_rotation != Vector3.ZERO, "golpe em andamento antes da troca")
	await _equip_through_inventory(screen, armor_t1, 0)
	check(viewmodel._look.armor_tier == 1, "troca durante o golpe aplicada")
	check(viewmodel.right_position == Vector3.ZERO and viewmodel.right_rotation == Vector3.ZERO, "mão volta ao repouso")
	viewmodel.start_cast(priest.basic_attack, 1.0)
	await _frames(3)
	check(viewmodel._cast_light.light_energy > 0.0, "luz de cast acesa antes da troca")
	await _equip_through_inventory(screen, armor_t2, 0)
	await _frames(20)
	check(viewmodel._cast_light.light_energy == 0.0, "luz de cast nova nasce apagada")
	check(viewmodel.right_position == Vector3.ZERO and viewmodel._right.position.distance_to(Viewmodel.RIGHT_REST) < 0.02, "mão no repouso depois do cast")
	check(_errors.count == errors_before, "troca em golpe e cast sem erro no console")

	# 4. Três trocas seguidas: uma só lanterna (C3), fora a luz de cast.
	for armor: ItemData in [armor_t1, armor_t2, armor_t1]:
		await _equip_through_inventory(screen, armor)
		var lanterns: int = 0
		for light: Node in viewmodel.find_children("*", "OmniLight3D", true, false):
			if light != viewmodel._cast_light:
				lanterns += 1
		check(lanterns == 1, "uma só OmniLight3D da lanterna depois da troca (%d)" % lanterns)

	# 5. Alternar entre as mesmas duas armaduras: o cache de materiais para de crescer.
	var sizes: Array[int] = []
	for _lap in 3:
		await _equip_through_inventory(screen, armor_t2)
		await _equip_through_inventory(screen, armor_t1)
		sizes.append(Look._viewmodel_cache.size())
	check(sizes[1] == sizes[0] and sizes[2] == sizes[0], "cache de materiais do viewmodel não cresce: %s" % [sizes])

	screen._open_pause()
	await _frames(1)
	screen._abandon()
	await _frames(4)
	check(_lobby() != null, "teste de troca volta ao saguão")


func _equip_through_inventory(screen: DungeonScreen, item: ItemData, settle_frames: int = 2) -> void:
	screen.toggle_window(&"menu_inventory")
	await _frames(2)
	var inventory: InventoryView = screen._window.find_children("*", "InventoryView", true, false)[0]
	inventory._on_item_pressed(item)
	await _frames(settle_frames)
	screen.close_window()
	await _frames(1)
