extends Node
## Percorre o fluxo real pela interface: saguão, partida, janelas, forja, vitória e retorno.
## godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")

var _main: Node
var _passed: int = 0
var _failed: int = 0


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


func _ready() -> void:
	Session.save_path = "user://test_flow_save.json"
	if FileAccess.file_exists(Session.save_path):
		DirAccess.remove_absolute(Session.save_path)
	Session.reset_all()
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await _frames(6)
	await _test_new_character()
	await _test_windows()
	await _test_pause()
	await _test_forge_station_and_equip()
	await _test_graphics_presets()
	await _test_containment()
	await _test_guard_breaks_without_mana()
	await _test_summons_belong_to_the_encounter()
	await _test_victory_and_return()
	await _test_results_cannot_trap_the_player()
	await _test_rank_lock_and_tabs()
	await _test_second_run_keeps_progress()
	await _test_abandon()
	print("\nFLUXO: %d verificações ok, %d falhas" % [_passed, _failed])
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


func _test_new_character() -> void:
	var lobby: Lobby = _lobby()
	check(lobby != null, "saguão abre")
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


func _test_windows() -> void:
	var screen: DungeonScreen = _screen()
	for action: StringName in [&"menu_inventory", &"menu_character", &"menu_forge", &"menu_map"]:
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
	await _press_key(&"menu_pause")
	check(not get_tree().paused, "Esc despausa")
	check(screen.run.player.input_enabled, "controle volta após pausa")
	screen.toggle_window(&"menu_map")
	await _frames(1)
	await _press_key(&"menu_pause")
	check(screen._window == null and not get_tree().paused, "Esc fecha janela antes de pausar")


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
	boss.machine.transition(&"idle")
	await _frames(3)
	check(_living_enemies() == living_before, "reiniciar o chefe remove os invocados")
	check(director.current_phase == 0, "fases reiniciadas")
	boss.combatant.restore_full()


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
	_kill(boss.combatant)
	await _frames(3)
	check(run.boss_defeated_flag, "vitória registrada")
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
	var results: ResultsView = screen._window.find_children("*", "ResultsView", true, false)[0]
	results.return_requested.emit()
	await _frames(4)
	check(_lobby() != null, "volta ao saguão")
	check(_screen() == null, "masmorra descarregada")
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
	await _finish_run_with_victory()
	var screen: DungeonScreen = _screen()
	check(screen.run.is_finished and screen._window != null, "resultados na tela")
	check(screen.run.process_mode == Node.PROCESS_MODE_DISABLED, "mundo parado nos resultados")
	screen.hud.menu_pressed.emit(&"menu_inventory")
	await _frames(2)
	check(screen._window != null and screen._window_action == &"", "HUD não substitui os resultados")
	await _press_key(&"menu_character")
	check(screen._window_action == &"", "tecla de menu não substitui os resultados")
	await _press_key(&"menu_pause")
	await _frames(3)
	check(_lobby() != null and _screen() == null, "Esc nos resultados volta ao saguão")
	# Saída pelo X da janela
	await _enter_gate_through_ui(_lobby())
	await _finish_run_with_victory()
	screen = _screen()
	screen._window.closed.emit()
	await _frames(3)
	check(_lobby() != null and _screen() == null, "fechar os resultados volta ao saguão")


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
	await _enter_gate_through_ui(_lobby())
	check(_screen().run.sheet == sheet, "segunda partida usa a mesma ficha")
	check(_screen().run.player.combatant.level == sheet.level, "nível aplicado ao combate")


func _test_abandon() -> void:
	var screen: DungeonScreen = _screen()
	screen._open_pause()
	await _frames(1)
	screen._abandon()
	await _frames(4)
	check(_lobby() != null, "abandonar volta ao saguão")
	check(not get_tree().paused, "abandonar não deixa o jogo pausado")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "cursor visível no saguão")
