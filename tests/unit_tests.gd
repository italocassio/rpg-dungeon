extends Node
## Testes de regras. Executar: godot --headless --path . res://tests/unit_tests.tscn

const MUSIC_TEST_FADE := 0.05

var _passed: int = 0
var _failed: int = 0
var _current: String = ""
var _errors := ScriptErrorCounter.new()


func _ready() -> void:
	OS.add_logger(_errors)
	Session.save_path = "user://test_unit_save.json"
	for method in get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_"):
			_current = method_name
			await call(method_name)
	_failed += _errors.count
	print("\nRESULTADO: %d verificações ok, %d falhas (%d erros de script)" % [_passed, _failed, _errors.count])
	OS.remove_logger(_errors)
	DirAccess.remove_absolute(Session.save_path)
	get_tree().quit(1 if _failed > 0 else 0)


func check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("  FALHOU [%s]: %s" % [_current, message])


func equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (obtido %s, esperado %s)" % [message, actual, expected])


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _combatant(team: Combatant.Team, hp: float = 1000.0) -> Combatant:
	var unit := Combatant.new()
	var body := Node3D.new()
	add_child(body)
	body.add_child(unit)
	var stats := StatBlock.new()
	stats.max_hp = hp
	stats.max_mp = 200.0
	stats.phys_attack = 50.0
	stats.magic_attack = 50.0
	stats.crit_chance = 0.0
	unit.setup("Teste", 1, team, stats, GameDB.balance)
	return unit


func _sheet(class_id: StringName = &"warrior") -> CharacterSheet:
	var class_data: ClassData = GameDB.class_by_id(class_id)
	var sheet := CharacterSheet.new(class_data, GameDB.balance)
	sheet.equip_directly(class_data.starter_weapons[0])
	sheet.equip_directly(class_data.starter_armors[0])
	return sheet


func test_catalog_classes_are_complete() -> void:
	equal(GameDB.catalog.classes.size(), 3, "três classes humanas")
	for class_data in GameDB.catalog.classes:
		check(class_data.basic_attack != null, "%s tem ataque básico" % class_data.id)
		equal(class_data.skills.size(), 4, "%s tem 4 habilidades" % class_data.id)
		check(class_data.ultimate != null and class_data.ultimate.chi_cost > 0.0, "%s tem suprema com Chi" % class_data.id)
		check(class_data.starter_weapons.size() >= 2, "%s oferece escolha de arma" % class_data.id)
		check(class_data.starter_armors.size() >= 2, "%s oferece escolha de armadura" % class_data.id)
		for item in class_data.starter_weapons + class_data.starter_armors:
			equal(item.class_id, class_data.id, "item inicial %s é da classe" % item.id)


func test_every_dungeon_has_boss_with_rare_drops() -> void:
	check(GameDB.catalog.dungeons.size() >= 1, "há ao menos uma masmorra")
	for dungeon in GameDB.catalog.dungeons:
		check(dungeon.boss != null, "%s tem chefe" % dungeon.id)
		check(dungeon.boss.tier == MonsterData.Tier.BOSS, "chefe marcado como BOSS")
		check(dungeon.room_of_kind(RoomData.Kind.BOSS) != null, "tem sala do chefe")
		check(dungeon.room_of_kind(RoomData.Kind.ENTRANCE) != null, "tem entrada")
		var rare: int = 0
		for entry in dungeon.boss.drops:
			if entry.item.rarity >= ItemData.Rarity.RARE and entry.item.kind == ItemData.Kind.MATERIAL:
				rare += 1
		check(rare >= 2, "chefe dropa itens raros de forja")


func test_all_recipe_materials_are_obtainable() -> void:
	var obtainable: Dictionary = {}
	for monster in GameDB.catalog.monsters:
		for entry in monster.drops:
			obtainable[entry.item.id] = true
	for recipe in GameDB.catalog.recipes:
		for ingredient: ItemData in recipe.ingredients:
			check(obtainable.has(ingredient.id), "%s é obtido de monstros" % ingredient.id)


func test_armor_tiers_above_one_need_boss_items() -> void:
	var boss_items: Array[StringName] = []
	for entry in GameDB.dungeon(&"frost_gate").boss.drops:
		if entry.item.rarity >= ItemData.Rarity.RARE:
			boss_items.append(entry.item.id)
	for recipe in GameDB.catalog.recipes:
		if recipe.tier < 2:
			continue
		var uses_boss_item: bool = false
		for ingredient: ItemData in recipe.ingredients:
			uses_boss_item = uses_boss_item or ingredient.id in boss_items
		check(uses_boss_item, "%s exige item de chefe" % recipe.id)


func test_mitigation_has_diminishing_returns() -> void:
	var balance: BalanceConfig = GameDB.balance
	check(DamageCalculator.mitigation(0.0, balance) == 1.0, "defesa zero não reduz")
	var low: float = 1.0 - DamageCalculator.mitigation(50.0, balance)
	var high: float = 1.0 - DamageCalculator.mitigation(100.0, balance)
	check(high > low and high < low * 2.0, "dobrar defesa reduz menos que o dobro")


func test_element_weakness_and_resistance() -> void:
	var balance: BalanceConfig = GameDB.balance
	var target := StatBlock.new()
	target.weak_element = SkillData.Element.FIRE
	target.strong_element = SkillData.Element.WATER
	check(DamageCalculator.element_multiplier(SkillData.Element.FIRE, target, balance) > 1.0, "fraqueza aumenta dano")
	check(DamageCalculator.element_multiplier(SkillData.Element.WATER, target, balance) < 1.0, "resistência reduz dano")
	equal(DamageCalculator.element_multiplier(SkillData.Element.NONE, target, balance), 1.0, "neutro não muda")


func test_crit_and_dodge_rates() -> void:
	var balance: BalanceConfig = GameDB.balance
	var attacker := StatBlock.new()
	attacker.crit_chance = 0.5
	var defender := StatBlock.new()
	defender.dodge_chance = 0.25
	var rng := _rng()
	var crits: int = 0
	var dodges: int = 0
	var runs: int = 20000
	for _i in runs:
		var outcome := DamageCalculator.compute(attacker, defender, SkillData.DamageKind.PHYSICAL, SkillData.Element.NONE, 1.0, balance, rng)
		dodges += 1 if outcome.is_dodged else 0
		crits += 1 if outcome.is_crit else 0
	check(absf(dodges / float(runs) - 0.25) < 0.02, "esquiva perto de 25%%: %f" % (dodges / float(runs)))
	check(absf(crits / float(runs - dodges) - 0.5) < 0.02, "crítico perto de 50%%")


func test_level_up_grants_points_and_respects_cap() -> void:
	var sheet := _sheet()
	var levels: Array[int] = [0]
	sheet.leveled_up.connect(func(_l: int) -> void: levels[0] += 1)
	sheet.add_xp(sheet.xp_to_next_level())
	equal(sheet.level, 2, "sobe de nível")
	equal(sheet.unspent_points, GameDB.balance.attribute_points_per_level, "ganha pontos")
	equal(levels[0], 1, "emite sinal")
	var before: float = sheet.derived_stats().phys_attack
	check(sheet.spend_point(&"strength"), "gasta ponto")
	check(sheet.derived_stats().phys_attack > before, "força aumenta ataque")
	sheet.add_xp(100000000)
	equal(sheet.level, GameDB.balance.max_level, "limite de nível")
	equal(sheet.add_xp(1000), 0, "sem xp no limite")


func test_equipment_changes_stats_and_swaps_back_to_inventory() -> void:
	var sheet := _sheet()
	var base: float = sheet.derived_stats().phys_attack
	var forged: ItemData = GameDB.item(&"warrior_t1_weapon")
	sheet.level = forged.required_level
	sheet.inventory.add(forged.id)
	var old: ItemData = sheet.equipment[ItemData.Kind.WEAPON]
	check(sheet.equip_from_inventory(forged), "equipa")
	check(sheet.derived_stats().phys_attack > base, "ataque subiu")
	equal(sheet.inventory.count_of(old.id), 1, "antigo voltou ao inventário")
	equal(sheet.inventory.count_of(forged.id), 0, "novo saiu do inventário")


func test_equipment_restrictions() -> void:
	var sheet := _sheet(&"warrior")
	var staff: ItemData = GameDB.item(&"mage_t1_weapon")
	sheet.inventory.add(staff.id)
	check(not sheet.equip_from_inventory(staff), "guerreiro não usa cajado")
	var locked: ItemData = GameDB.item(&"warrior_t3_weapon")
	sheet.inventory.add(locked.id)
	check(not sheet.equip_from_inventory(locked), "nível baixo não equipa")
	equal(sheet.inventory.count_of(staff.id), 1, "recusa não consome")


func test_forge_consumes_materials_only_on_success() -> void:
	var sheet := _sheet()
	var recipe: RecipeData = null
	for candidate in GameDB.catalog.recipes:
		if candidate.result.id == &"warrior_t1_helm":
			recipe = candidate
	check(recipe != null, "receita existe")
	equal(Forge.check(recipe, sheet), Forge.Failure.MISSING_CRYSTALS, "sem cristais")
	sheet.inventory.add_crystals(recipe.mana_crystal_cost)
	equal(Forge.check(recipe, sheet), Forge.Failure.MISSING_MATERIALS, "sem materiais")
	check(not Forge.craft(recipe, sheet), "falha não forja")
	equal(sheet.inventory.mana_crystals, recipe.mana_crystal_cost, "falha não gasta cristais")
	for ingredient: ItemData in recipe.ingredients:
		sheet.inventory.add(ingredient.id, recipe.ingredients[ingredient])
	check(Forge.craft(recipe, sheet), "forja com tudo")
	equal(sheet.inventory.count_of(recipe.result.id), 1, "recebe item")
	equal(sheet.inventory.mana_crystals, 0, "gasta cristais")
	for ingredient: ItemData in recipe.ingredients:
		equal(sheet.inventory.count_of(ingredient.id), 0, "gasta %s" % ingredient.id)


func test_forge_rejects_other_class_recipe() -> void:
	var sheet := _sheet(&"priest")
	for recipe in GameDB.catalog.recipes:
		if recipe.result.class_id == &"mage":
			equal(Forge.check(recipe, sheet), Forge.Failure.WRONG_CLASS, "classe errada")
			return


func test_loot_rates_and_rank_gating() -> void:
	var dungeon: DungeonData = GameDB.dungeon(&"frost_gate")
	var boss: MonsterData = dungeon.boss
	var rng := _rng(7)
	var crown_e: int = 0
	var crown_d: int = 0
	var core: int = 0
	var runs: int = 4000
	for _i in runs:
		for drop in LootRoller.roll(boss, dungeon.ranks[0], rng):
			crown_e += 1 if drop.item.id == &"boss_crown" else 0
			core += 1 if drop.item.id == &"boss_core" else 0
		for drop in LootRoller.roll(boss, dungeon.ranks[1], rng):
			crown_d += 1 if drop.item.id == &"boss_crown" else 0
	equal(crown_e, 0, "coroa não cai no rank E")
	equal(core, runs, "núcleo é garantido")
	check(absf(crown_d / float(runs) - 0.4) < 0.03, "coroa perto de 40%% no rank D")


func test_save_and_load_roundtrip() -> void:
	Session.reset_all()
	var class_data: ClassData = GameDB.class_by_id(&"mage")
	var sheet: CharacterSheet = Session.select_class(class_data, class_data.starter_weapons[1], class_data.starter_armors[1])
	sheet.add_xp(sheet.xp_to_next_level())
	sheet.spend_point(&"intelligence")
	sheet.inventory.add(&"boss_core", 2)
	sheet.inventory.add_crystals(77)
	check(Session.save_game(), "salva")
	Session.reset_all()
	check(Session.load_game(), "carrega")
	var loaded: CharacterSheet = Session.active_sheet
	check(loaded != null, "ficha ativa restaurada")
	equal(loaded.class_data.id, &"mage", "classe")
	equal(loaded.level, 2, "nível")
	equal(loaded.bonus_attributes[&"intelligence"], 1, "atributos")
	equal(loaded.inventory.count_of(&"boss_core"), 2, "itens")
	equal(loaded.inventory.mana_crystals, 77, "cristais")
	equal(loaded.equipment[ItemData.Kind.WEAPON].id, class_data.starter_weapons[1].id, "arma escolhida")
	equal(loaded.equipment[ItemData.Kind.ARMOR].id, class_data.starter_armors[1].id, "armadura escolhida")
	Session.reset_all()


func test_load_rejects_corrupt_save() -> void:
	var file := FileAccess.open(Session.save_path, FileAccess.WRITE)
	file.store_string("{ isso nao e json")
	file = null
	check(not Session.load_game(), "save corrompido é ignorado")
	Session.reset_all()


func test_party_finder_covers_roles() -> void:
	var catalog: GameCatalog = GameDB.catalog
	for class_data in catalog.classes:
		var members: Array[PartyMember] = PartyFinder.assemble(class_data, 3, catalog, 4, _rng())
		equal(members.size(), 3, "três companheiros")
		var roles: Array = [class_data.role]
		var names: Dictionary = {}
		for member in members:
			roles.append(member.class_data.role)
			names[member.display_name] = true
		check(ClassData.Role.TANK in roles, "tem tanque com %s" % class_data.id)
		check(ClassData.Role.HEALER in roles, "tem cura com %s" % class_data.id)
		equal(names.size(), 3, "nomes únicos")


func test_combatant_damage_shield_death_revive() -> void:
	var attacker := _combatant(Combatant.Team.PARTY)
	var target := _combatant(Combatant.Team.MONSTERS, 100.0)
	var skill := SkillData.new()
	skill.power = 1.0
	var deaths: Array[int] = [0]
	target.died.connect(func(_k: Combatant) -> void: deaths[0] += 1)
	target.shield = 10000.0
	check(target.receive_hit(attacker, skill), "acerta")
	equal(target.hp, 100.0, "escudo absorve")
	target.shield = 0.0
	skill.power = 100.0
	target.receive_hit(attacker, skill)
	check(not target.is_alive(), "morre")
	equal(deaths[0], 1, "sinal de morte")
	check(not target.receive_hit(attacker, skill), "morto não recebe dano")
	equal(deaths[0], 1, "não morre duas vezes")
	target.revive(0.5)
	check(target.is_alive(), "revive")
	equal(target.hp, 50.0, "revive com metade")


func test_invulnerability_and_guard() -> void:
	var attacker := _combatant(Combatant.Team.MONSTERS)
	var target := _combatant(Combatant.Team.PARTY)
	var skill := SkillData.new()
	target.grant_invulnerability(1.0)
	check(not target.receive_hit(attacker, skill), "esquiva invulnerável")
	target._process(1.1)
	check(not target.is_invulnerable(), "invulnerabilidade acaba")
	var rng_hits: Array[float] = []
	target.damaged.connect(func(amount: float, _s: Combatant, _c: bool, _t: float) -> void: rng_hits.append(amount))
	target.guard_multiplier = 1.0
	target.receive_hit(attacker, skill)
	target.guard_multiplier = 0.4
	target.receive_hit(attacker, skill)
	equal(rng_hits.size(), 2, "dois golpes")
	check(rng_hits[1] < rng_hits[0] * 0.6, "postura reduz dano")


func test_effects_modify_stats_tick_and_expire() -> void:
	var source := _combatant(Combatant.Team.PARTY)
	var target := _combatant(Combatant.Team.MONSTERS)
	var chill: EffectData = load("res://data/effects/chill.tres")
	var base: float = target.stats.move_speed
	target.apply_effect(chill, source)
	check(target.stats.move_speed < base, "lentidão reduz velocidade")
	target._process(chill.duration + 0.1)
	equal(target.stats.move_speed, base, "velocidade volta")
	var burn: EffectData = load("res://data/effects/burn.tres")
	var before: float = target.hp
	target.apply_effect(burn, source)
	for _i in 6:
		target._process(1.0)
	check(target.hp < before, "queimadura causa dano")
	equal(target.effects.size(), 0, "efeito termina")


func test_stun_detected_and_blocks_caster() -> void:
	var unit := _combatant(Combatant.Team.PARTY)
	var caster := SkillCaster.new()
	unit.add_child(caster)
	caster.combatant = unit
	unit.apply_effect(load("res://data/effects/stun.tres"), unit)
	var skill := SkillData.new()
	skill.delivery = SkillData.Delivery.SELF_BUFF
	equal(caster.refusal(skill), SkillCaster.Refusal.STUNNED, "atordoado não conjura")


func test_skill_caster_costs_cooldown_and_interrupt() -> void:
	var unit := _combatant(Combatant.Team.PARTY)
	var caster := SkillCaster.new()
	unit.add_child(caster)
	caster.combatant = unit
	var skill := SkillData.new()
	skill.id = &"t_cast"
	skill.delivery = SkillData.Delivery.SELF_BUFF
	skill.cast_time = 1.0
	skill.cooldown = 3.0
	skill.mp_cost = 50.0
	check(caster.try_cast(skill, SkillAim.new()), "inicia cast")
	check(caster.is_casting(), "conjurando")
	equal(unit.mp, 200.0, "custo só ao concluir")
	check(not caster.try_cast(skill, SkillAim.new()), "não sobrepõe cast")
	caster._process(1.05)
	check(not caster.is_casting(), "concluiu")
	equal(unit.mp, 150.0, "pagou mana")
	equal(caster.refusal(skill), SkillCaster.Refusal.COOLDOWN, "em recarga")
	caster._process(3.1)
	equal(caster.refusal(skill), SkillCaster.Refusal.NONE, "recarga acabou")
	caster.try_cast(skill, SkillAim.new())
	caster.interrupt()
	check(not caster.is_casting(), "interrompido")
	equal(unit.mp, 150.0, "interrupção não cobra")
	unit.mp = 10.0
	equal(caster.refusal(skill), SkillCaster.Refusal.NO_MANA, "sem mana")
	var ultimate := SkillData.new()
	ultimate.id = &"t_ult"
	ultimate.chi_cost = 100.0
	equal(caster.refusal(ultimate), SkillCaster.Refusal.NO_CHI, "sem chi")


func test_cast_aim_is_built_for_the_skill_being_cast() -> void:
	var unit := _combatant(Combatant.Team.PARTY)
	var caster := SkillCaster.new()
	unit.add_child(caster)
	caster.combatant = unit
	var asked: Array[SkillData] = []
	caster.aim_provider = func(skill: SkillData) -> SkillAim:
		asked.append(skill)
		return SkillAim.new()
	var skill := SkillData.new()
	skill.id = &"t_aim"
	skill.delivery = SkillData.Delivery.SELF_BUFF
	skill.cast_time = 0.5
	caster.try_cast(skill, SkillAim.new())
	caster._process(0.6)
	equal(asked.size(), 1, "mira pedida ao fim do cast")
	equal(asked[0], skill, "mira pedida para a habilidade conjurada")


func test_heal_gives_chi_only_when_it_heals() -> void:
	var priest := _combatant(Combatant.Team.PARTY)
	var ally := _combatant(Combatant.Team.PARTY)
	var skill := SkillData.new()
	skill.delivery = SkillData.Delivery.TARGET_ALLY
	skill.power = 1.0
	skill.chi_gain = 10.0
	var aim := SkillAim.new()
	aim.target = ally
	SkillExecutor.execute(skill, priest, aim)
	equal(priest.chi, 0.0, "curar quem está cheio não dá Chi")
	ally.hp = 100.0
	SkillExecutor.execute(skill, priest, aim)
	equal(priest.chi, 10.0, "cura efetiva dá Chi")
	var hit := SkillData.new()
	hit.power = 100.0
	ally.receive_hit(_combatant(Combatant.Team.MONSTERS), hit)
	check(not ally.is_alive(), "aliado morreu")
	SkillExecutor.execute(skill, priest, aim)
	equal(priest.chi, 10.0, "curar morto não dá Chi")


func test_boss_cannot_be_stunned() -> void:
	var boss := _combatant(Combatant.Team.MONSTERS)
	boss.stun_immune = true
	boss.apply_effect(load("res://data/effects/stun.tres"), boss)
	check(not boss.is_stunned(), "chefe imune")
	boss.apply_effect(load("res://data/effects/chill.tres"), boss)
	equal(boss.effects.size(), 1, "outros efeitos continuam valendo")


func test_restore_full_does_not_heal_the_dead() -> void:
	var unit := _combatant(Combatant.Team.PARTY, 100.0)
	var hit := SkillData.new()
	hit.power = 100.0
	unit.receive_hit(_combatant(Combatant.Team.MONSTERS), hit)
	unit.restore_full()
	equal(unit.hp, 0.0, "morto continua sem vida")
	check(not unit.is_alive(), "morto continua morto")


func test_load_tolerates_items_removed_from_the_game() -> void:
	var class_data: ClassData = GameDB.class_by_id(&"mage")
	var sheet := CharacterSheet.new(class_data, GameDB.balance)
	sheet.load_dict({
		"equipment": {str(int(ItemData.Kind.WEAPON)): "arma_que_nao_existe_mais"},
		"inventory": {"mana_crystals": 5, "stacks": {"item_fantasma": 3, "mat_fang": 2}},
	}, GameDB.item)
	equal(sheet.equipment[ItemData.Kind.WEAPON], class_data.starter_weapons[0], "arma ausente vira a inicial")
	equal(sheet.equipment[ItemData.Kind.ARMOR], class_data.starter_armors[0], "armadura ausente vira a inicial")
	equal(sheet.inventory.count_of(&"item_fantasma"), 0, "item fantasma removido")
	equal(sheet.inventory.count_of(&"mat_fang"), 2, "item válido preservado")


func test_rig_revive_restores_pose() -> void:
	var rig := CreatureRig.new()
	add_child(rig)
	for _i in 3:
		rig.die()
		await get_tree().create_timer(0.1).timeout
		rig.revive()
		equal(rig.rotation, Vector3.ZERO, "volta em pé")
		equal(rig.position.y, 0.0, "altura não acumula")
	await get_tree().create_timer(0.6).timeout
	equal(rig.rotation, Vector3.ZERO, "tween de morte não continua depois de reviver")


func test_loot_can_only_be_claimed_once() -> void:
	var loot := LootDrop.new()
	loot.item = GameDB.item(&"mat_fang")
	add_child(loot)
	check(loot.claim(), "primeira entrega")
	check(not loot.claim(), "segunda entrega recusada")


func test_chi_sparks_and_cap() -> void:
	var unit := _combatant(Combatant.Team.PARTY)
	unit.add_chi(250.0)
	equal(unit.sparks(), 2, "duas faíscas")
	unit.add_chi(500.0)
	equal(unit.chi, GameDB.balance.max_chi, "limite de chi")


func test_threat_and_taunt() -> void:
	var enemy := _combatant(Combatant.Team.MONSTERS)
	var dps := _combatant(Combatant.Team.PARTY)
	var tank := _combatant(Combatant.Team.PARTY)
	var table := ThreatTable.new()
	table.add(dps, 100.0)
	table.add(tank, 40.0)
	equal(table.top_target(enemy), dps, "maior ameaça")
	enemy.apply_effect(load("res://data/effects/taunt.tres"), tank)
	equal(table.top_target(enemy), tank, "provocação domina")
	enemy._process(10.0)
	equal(table.top_target(enemy), dps, "provocação expira")
	dps.hp = 1.0
	var skill := SkillData.new()
	skill.power = 100.0
	dps.receive_hit(enemy, skill)
	equal(table.top_target(enemy), tank, "ignora morto")


func test_state_machine_transitions() -> void:
	var machine := StateMachine.new()
	machine.add(&"a", ActorState.new())
	machine.add(&"b", ActorState.new())
	var log: Array[StringName] = []
	machine.state_changed.connect(func(_p: StringName, n: StringName) -> void: log.append(n))
	machine.start(&"a")
	machine.transition(&"b")
	machine.transition(&"b")
	equal(log.size(), 2, "ignora transição redundante")
	equal(machine.current_name, &"b", "estado atual")


func test_dungeon_is_fully_connected() -> void:
	var dungeon: DungeonData = GameDB.dungeon(&"frost_gate")
	var field := DungeonField.new(dungeon)
	var visited: Dictionary = {}
	var entrance: RoomData = dungeon.room_of_kind(RoomData.Kind.ENTRANCE)
	var start: Vector2i = Vector2i(((entrance.center - field.origin) / DungeonField.CELL).round())
	var frontier: Array[Vector2i] = [start]
	visited[start] = true
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if next.x < 0 or next.y < 0 or next.x >= field.columns or next.y >= field.rows or visited.has(next):
				continue
			if field.grid_sdf(next.x, next.y) < -0.8:
				visited[next] = true
				frontier.append(next)
	var reach := func(point: Vector2) -> bool:
		return visited.has(Vector2i(((point - field.origin) / DungeonField.CELL).round()))
	for room in dungeon.rooms:
		check(reach.call(room.center), "sala %s alcançável" % room.id)
	for group in dungeon.spawn_groups:
		check(reach.call(field.push_inside(group.position, 1.4)), "spawn em %s alcançável" % group.position)


func test_walkability_helpers() -> void:
	var dungeon: DungeonData = GameDB.dungeon(&"frost_gate")
	var field := DungeonField.new(dungeon)
	var entrance: RoomData = dungeon.room_of_kind(RoomData.Kind.ENTRANCE)
	check(field.is_walkable(entrance.center), "centro é caminhável")
	check(not field.is_walkable(entrance.center + Vector2(entrance.radius + 6.0, 0.0)), "fora da sala não")
	var pushed: Vector2 = field.push_inside(entrance.center + Vector2(entrance.radius + 1.0, 0.0), 1.0)
	check(field.is_walkable(pushed, 0.5), "push_inside devolve ponto válido")
	check(field.floor_at(entrance.center) < 0.1, "centro plano para telegrafias")


# ---------- Explicação das habilidades ----------

func _player_skills() -> Array[SkillData]:
	var skills: Array[SkillData] = []
	for class_data in GameDB.catalog.classes:
		skills.append(class_data.basic_attack)
		skills.append_array(class_data.skills)
		skills.append(class_data.ultimate)
	return skills


func _skill_named(id: StringName) -> SkillData:
	for skill in _player_skills():
		if skill.id == id:
			return skill
	check(false, "habilidade %s existe" % id)
	return null


func _exact_balance() -> BalanceConfig:
	var balance: BalanceConfig = GameDB.balance.duplicate()
	balance.damage_variance = 0.0
	return balance


## Atacante e curador sem crítico nem variação; físico e mágico diferem para flagrar o atributo errado.
func _exact_caster(team: Combatant.Team = Combatant.Team.PARTY) -> Combatant:
	var unit := _combatant(team)
	unit.balance = _exact_balance()
	unit.base_stats.phys_attack = 70.0
	unit.base_stats.magic_attack = 90.0
	unit.base_stats.heal_power = 1.2
	unit.refresh_stats()
	return unit


## `receive_hit` usa o balance do alvo; a cura usa o do conjurador.
func _exact_target(team: Combatant.Team = Combatant.Team.MONSTERS) -> Combatant:
	var unit := _combatant(team, 100000000.0)
	unit.balance = _exact_balance()
	unit.base_stats.phys_defense = 0.0
	unit.base_stats.magic_defense = 0.0
	unit.base_stats.dodge_chance = 0.0
	unit.refresh_stats()
	return unit


func _info_for(skill: SkillData, unit: Combatant) -> SkillInfo:
	return SkillInfo.describe(skill, unit.stats, unit.balance, unit.damage_multiplier)


func _near(actual: float, expected: float, message: String, tolerance: float = 0.01) -> void:
	check(absf(actual - expected) < tolerance, "%s (obtido %f, esperado %f)" % [message, actual, expected])


func _check_damage_parity(caster: Combatant, label: String) -> void:
	for skill in _player_skills():
		var info: SkillInfo = _info_for(skill, caster)
		if info.damage <= 0.0:
			continue
		var target: Combatant = _exact_target()
		var before: float = target.hp
		SkillExecutor.strike(skill, caster, target)
		_near(before - target.hp, info.damage, "%s: dano de %s" % [label, skill.id])


func test_skill_catalog_is_described() -> void:
	var digit: RegEx = RegEx.create_from_string("\\d")
	var stats: StatBlock = _sheet().derived_stats()
	var skills: Array[SkillData] = _player_skills()
	equal(skills.size(), 18, "seis habilidades por classe")
	for skill in skills:
		check(not skill.display_name.is_empty(), "%s tem nome" % skill.id)
		check(not skill.description.is_empty(), "%s tem descrição" % skill.id)
		check(digit.search(skill.description) == null, "descrição de %s não tem número: %s" % [skill.id, skill.description])
		var info: SkillInfo = SkillInfo.describe(skill, stats, GameDB.balance)
		check(not info.rows.is_empty(), "%s gera linhas" % skill.id)
		check(not info.subtitle.is_empty(), "%s tem subtítulo" % skill.id)
		check(info.plain_text().contains(skill.display_name), "%s aparece no texto" % skill.id)


func test_skill_info_damage_matches_combat() -> void:
	_check_damage_parity(_exact_caster(), "base")
	var weakened: Combatant = _exact_caster()
	weakened.damage_multiplier = 0.6
	_check_damage_parity(weakened, "multiplicador 0,6")
	var blessed: Combatant = _exact_caster()
	blessed.apply_effect(load("res://data/effects/blessing.tres"), blessed)
	check(blessed.stats.phys_attack > blessed.base_stats.phys_attack, "bênção aumenta o ataque")
	_check_damage_parity(blessed, "com bênção")


func test_skill_info_damage_stays_inside_the_printed_range() -> void:
	var caster: Combatant = _exact_caster()
	caster.balance = GameDB.balance
	for skill in _player_skills():
		var info: SkillInfo = _info_for(skill, caster)
		if info.damage <= 0.0:
			continue
		var target: Combatant = _exact_target()
		target.balance = GameDB.balance
		var lowest: float = INF
		var highest: float = -INF
		for _i in 500:
			var before: float = target.hp
			target.receive_hit(caster, skill)
			lowest = minf(lowest, before - target.hp)
			highest = maxf(highest, before - target.hp)
		check(lowest >= info.damage_min - 0.001, "%s respeita o mínimo impresso" % skill.id)
		check(highest <= info.damage_max + 0.001, "%s respeita o máximo impresso" % skill.id)
		check(highest > lowest, "%s varia de fato" % skill.id)


func test_skill_info_heal_matches_combat() -> void:
	var priest: Combatant = _exact_caster()
	var heal: SkillData = _skill_named(&"p_heal")
	var ally: Combatant = _exact_target(Combatant.Team.PARTY)
	ally.hp = 1000.0
	var aim := SkillAim.new()
	aim.target = ally
	SkillExecutor.execute(heal, priest, aim)
	_near(ally.hp - 1000.0, _info_for(heal, priest).heal, "cura direta com heal_power")
	var miracle: SkillData = _skill_named(&"p_miracle")
	var hurt: Combatant = _exact_target(Combatant.Team.PARTY)
	hurt.hp = 1000.0
	var fallen: Combatant = _exact_target(Combatant.Team.PARTY)
	var fatal := SkillData.new()
	fatal.power = 100000000.0
	fallen.receive_hit(_exact_caster(Combatant.Team.MONSTERS), fatal)
	check(not fallen.is_alive(), "aliado caiu")
	SkillExecutor.execute(miracle, priest, SkillAim.new())
	_near(hurt.hp - 1000.0, _info_for(miracle, priest).heal, "cura em grupo com heal_power")
	_near(fallen.hp_ratio(), miracle.revive_hp_ratio, "reviver usa o campo da habilidade")
	check(_info_for(miracle, priest).plain_text().contains("%d%%" % roundi(miracle.revive_hp_ratio * 100.0)), "texto mostra a vida ao reviver")


## Além de conter os golpes, a faixa impressa não pode ser folgada: 500 curas chegam perto das duas pontas.
func test_skill_info_heal_stays_inside_the_printed_range() -> void:
	var priest: Combatant = _exact_caster()
	priest.balance = GameDB.balance
	var ally: Combatant = _exact_target(Combatant.Team.PARTY)
	var aim := SkillAim.new()
	aim.target = ally
	for id: StringName in [&"p_heal", &"p_miracle"]:
		var skill: SkillData = _skill_named(id)
		var info: SkillInfo = _info_for(skill, priest)
		var margin: float = (info.heal_max - info.heal_min) * 0.05
		var lowest: float = INF
		var highest: float = -INF
		for _i in 500:
			ally.hp = 1000.0
			SkillExecutor.execute(skill, priest, aim)
			lowest = minf(lowest, ally.hp - 1000.0)
			highest = maxf(highest, ally.hp - 1000.0)
		check(lowest >= info.heal_min - 0.001 and lowest <= info.heal_min + margin, "%s chega ao mínimo impresso (%f, %f)" % [id, lowest, info.heal_min])
		check(highest <= info.heal_max + 0.001 and highest >= info.heal_max - margin, "%s chega ao máximo impresso (%f, %f)" % [id, highest, info.heal_max])


func test_skill_info_zone_ticks_match_combat() -> void:
	var priest: Combatant = _exact_caster()
	var circle: SkillData = _skill_named(&"p_circle")
	var info: SkillInfo = _info_for(circle, priest)
	equal(info.heal_ticks, 7, "Círculo Sagrado promete 7 pulsos")
	var ally: Combatant = _exact_target(Combatant.Team.PARTY)
	ally.hp = 1000.0
	var heals: Array[float] = []
	ally.healed.connect(func(amount: float, _source: Combatant) -> void: heals.append(amount))
	var zone := HealZone.new()
	zone.skill = circle
	zone.caster = priest
	add_child(zone)
	zone.set_process(false)
	zone.global_position = ally.world_position()
	for _i in roundi(circle.zone_duration * 60.0) + 120:
		if zone.is_queued_for_deletion():
			break
		zone._process(1.0 / 60.0)
	check(zone.is_queued_for_deletion(), "zona termina")
	equal(heals.size(), info.heal_ticks, "pulsos reais iguais aos impressos")
	_near(ally.hp - 1000.0, info.heal * info.heal_ticks, "total real igual ao impresso")


func test_zone_tick_count_matches_combat_with_fractional_interval() -> void:
	var slow: SkillData = _skill_named(&"p_circle").duplicate()
	slow.zone_tick_interval = 1.5
	equal(slow.zone_tick_count(), 5, "intervalo fracionário arredonda para cima")
	var ally: Combatant = _exact_target(Combatant.Team.PARTY)
	var heals: Array[float] = []
	ally.healed.connect(func(amount: float, _source: Combatant) -> void: heals.append(amount))
	var zone := HealZone.new()
	zone.skill = slow
	zone.caster = _exact_caster()
	add_child(zone)
	zone.set_process(false)
	zone.global_position = ally.world_position()
	for _i in roundi(slow.zone_duration * 60.0) + 120:
		if zone.is_queued_for_deletion():
			break
		zone._process(1.0 / 60.0)
	equal(heals.size(), slow.zone_tick_count(), "pulsos reais iguais à contagem")


## Crítico certo, alvo fraco ao elemento e balance real: o rodapé promete que nada disso afeta o pulso.
func test_skill_info_periodic_matches_combat() -> void:
	var mage: Combatant = _exact_caster()
	mage.damage_multiplier = 0.6
	mage.base_stats.crit_chance = 1.0
	mage.refresh_stats()
	var fireball: SkillData = _skill_named(&"m_fireball")
	var info: SkillInfo = _info_for(fireball, mage)
	equal(info.periodic_ticks, 4, "queimadura promete 4 pulsos")
	var target: Combatant = _exact_target()
	target.balance = GameDB.balance
	target.base_stats.weak_element = fireball.element
	target.refresh_stats()
	var ticks: Array[float] = []
	target.damaged.connect(func(amount: float, _source: Combatant, _crit: bool, _threat: float) -> void: ticks.append(amount))
	target.apply_effect(fireball.target_effect, mage)
	var before: float = target.hp
	for _i in 6:
		target._process(1.0)
	equal(ticks.size(), info.periodic_ticks, "pulsos reais iguais aos impressos")
	for tick in ticks:
		_near(tick, info.periodic, "pulso sem elemento, variação nem crítico")
	_near(before - target.hp, info.periodic * info.periodic_ticks, "total real igual ao impresso")


## O grupo é percorrido na ordem de entrada, então o conjurador passa por todas as posições.
func test_skill_info_shield_matches_combat() -> void:
	var bless: SkillData = _skill_named(&"p_bless")
	for position in 4:
		var group: Array[Combatant] = []
		for i in 4:
			group.append(_exact_caster() if i == position else _exact_target(Combatant.Team.PARTY))
		var priest: Combatant = group[position]
		var info: SkillInfo = _info_for(bless, priest)
		check(info.shield > 0.0, "Bênção promete escudo")
		SkillExecutor.execute(bless, priest, SkillAim.new())
		for i in 4:
			_near(group[i].shield, info.shield, "conjurador na posição %d: escudo real do membro %d" % [position, i])
		var recast: SkillInfo = _info_for(bless, priest)
		check(recast.shield > info.shield, "buff ativo aumenta o escudo impresso")
		SkillExecutor.execute(bless, priest, SkillAim.new())
		for i in 4:
			_near(group[i].shield, recast.shield, "relançar na posição %d: escudo real do membro %d" % [position, i])


func test_skill_info_times_match_caster() -> void:
	var unit: Combatant = _exact_caster()
	unit.base_stats.cast_speed = 1.1
	unit.base_stats.attack_speed = 1.25
	unit.refresh_stats()
	var caster := SkillCaster.new()
	unit.add_child(caster)
	caster.combatant = unit
	for skill in _player_skills():
		var info: SkillInfo = _info_for(skill, unit)
		# Só os tempos importam aqui: sem entrega, efeitos ou custos não há dependência de mundo.
		var probe: SkillData = skill.duplicate()
		probe.delivery = SkillData.Delivery.SELF_BUFF
		probe.damage_kind = SkillData.DamageKind.NONE
		probe.target_effect = null
		probe.self_effect = null
		probe.mp_cost = 0.0
		probe.chi_cost = 0.0
		caster.reset_all()
		check(caster.try_cast(probe, SkillAim.new()), "%s conjura" % skill.id)
		if skill.cast_time > 0.0:
			_near(info.cast_time, caster._cast_total, "conjuração de %s" % skill.id, 0.00001)
			caster._process(info.cast_time + 0.01)
		else:
			equal(info.cast_time, 0.0, "%s é instantânea" % skill.id)
		_near(info.cooldown, caster._cooldown_totals[skill.id], "recarga de %s" % skill.id, 0.00001)


## Lê a linha, não o texto todo: a descrição e o nome da habilidade repetem palavras das linhas.
func _row_value(info: SkillInfo, label: String) -> String:
	for row in info.rows:
		if row.label == label:
			return row.value
	return ""


func test_skill_info_text_is_truthful() -> void:
	var stats: StatBlock = _sheet(&"priest").derived_stats()
	var dotted_decimal: RegEx = RegEx.create_from_string("\\d\\.\\d")
	var without_chi: Array[SkillData.Delivery] = [SkillData.Delivery.HEAL_ZONE, SkillData.Delivery.PARTY, SkillData.Delivery.BLINK, SkillData.Delivery.SELF_BUFF]
	for skill in _player_skills():
		var info: SkillInfo = SkillInfo.describe(skill, stats, GameDB.balance)
		check(dotted_decimal.search(info.plain_text()) == null, "%s usa vírgula decimal" % skill.id)
		var in_party: bool = skill.delivery == SkillData.Delivery.PARTY
		if in_party:
			equal(_row_value(info, "Área"), "Todo o grupo, em qualquer distância", "%s não promete alcance" % skill.id)
		if skill.chi_gain > 0.0:
			check(skill.delivery not in without_chi, "%s não paga Chi por essa entrega" % skill.id)
			check(_row_value(info, "Chi").begins_with("+%d " % roundi(skill.chi_gain)), "%s mostra o ganho de Chi" % skill.id)
		else:
			equal(_row_value(info, "Chi"), "", "%s não promete Chi" % skill.id)
		var effects: Dictionary = {"Efeito no grupo" if in_party else "Efeito no alvo": skill.target_effect, "Efeito em você": skill.self_effect}
		for label: String in effects:
			var effect: EffectData = effects[label]
			var line: String = _row_value(info, label)
			if effect == null:
				equal(line, "", "%s não tem %s" % [skill.id, label])
				continue
			check(line.begins_with("%s por %s s" % [effect.display_name, SkillInfo.decimal(effect.duration)]), "%s explica %s" % [skill.id, effect.id])
			for stat: StringName in effect.stat_multipliers:
				check(StatBlock.LABELS.has(stat), "%s tem rótulo" % stat)
				check(line.contains(str(StatBlock.LABELS.get(stat, "?"))), "%s mostra %s" % [skill.id, stat])
			if effect.stuns:
				check(line.contains("chefes são imunes"), "%s avisa sobre chefes" % skill.id)
	check(SkillInfo.describe(_skill_named(&"w_warcry"), stats, GameDB.balance).plain_text().contains("Ameaça: Elevada"), "ameaça sem número")
	check(SkillInfo.describe(_skill_named(&"p_miracle"), stats, GameDB.balance).plain_text().contains("1 Faísca"), "custo em Faísca vem dos dados")


## Card e combate usam as mesmas fórmulas, então a paridade não vê mudança nelas: só valores absolutos
## veem. Atributos fixos, sem ficha, nível ou equipamento. Mudança proposital nos dados muda este
## arquivo junto, conferindo cada linha: regenerar a partir da saída, sem conferir, não prova nada.
func test_skill_cards_match_the_golden_file() -> void:
	var stats := StatBlock.new()
	stats.phys_attack = 100.0
	stats.magic_attack = 200.0
	stats.cast_speed = 1.25
	stats.attack_speed = 1.6
	stats.heal_power = 1.5
	stats.crit_multiplier = 2.0
	var skills: Array[SkillData] = _player_skills()
	var cards: PackedStringArray = FileAccess.get_file_as_string("res://tests/skill_cards.golden.txt").strip_edges().split("\n\n")
	equal(cards.size(), skills.size(), "golden tem um card por habilidade")
	for i in mini(cards.size(), skills.size()):
		equal(SkillInfo.describe(skills[i], stats, GameDB.balance, 0.5).plain_text(), cards[i], "card de %s" % skills[i].id)


func test_skill_info_decimal_format() -> void:
	equal(SkillInfo.decimal(1.27), "1,27", "duas casas")
	equal(SkillInfo.decimal(0.6), "0,6", "sem zero à direita")
	equal(SkillInfo.decimal(7.0), "7", "inteiro sem vírgula")
	equal(SkillInfo.decimal(10.0), "10", "zero à esquerda da vírgula é preservado")
	equal(SkillInfo.decimal(0.0), "0", "zero")


func test_skill_text_only_uses_glyphs_the_fonts_have() -> void:
	var font: Font = UiKit.body_font()
	check(not font.has_char(0x4E2D), "a verificação detecta glifo ausente")
	var stats: StatBlock = _sheet().derived_stats()
	for skill in _player_skills():
		var text: String = SkillInfo.describe(skill, stats, GameDB.balance).plain_text().replace("\n", "")
		var missing: String = ""
		for i in text.length():
			if not font.has_char(text.unicode_at(i)):
				missing += text[i]
		equal(missing, "", "%s só usa glifos da fonte" % skill.id)


func test_skill_tooltip_stays_on_screen() -> void:
	var slot := Vector2(58.0, 58.0)
	var card := Vector2(SkillTooltip.WIDTH, 320.0)
	for screen: Vector2 in [Vector2(1600.0, 900.0), Vector2(2133.0, 900.0), Vector2(1600.0, 1200.0), Vector2(3200.0, 900.0)]:
		var bounds: Rect2 = Rect2(Vector2.ZERO, screen).grow(-SkillTooltip.SCREEN_MARGIN)
		var anchors: Array[Rect2] = [
			Rect2(Vector2.ZERO, slot),
			Rect2(Vector2(screen.x - slot.x, 0.0), slot),
			Rect2(Vector2(0.0, screen.y - slot.y), slot),
			Rect2(screen - slot, slot),
			Rect2(Vector2(screen.x * 0.5, screen.y - 74.0), slot),
		]
		for anchor in anchors:
			var spot := Rect2(SkillTooltip.placement(anchor, card, bounds), card)
			check(bounds.encloses(spot), "card em %s dentro de %s" % [anchor, screen])
			check(not spot.intersects(anchor), "card não cobre a âncora %s em %s" % [anchor, screen])
	var hotbar := Rect2(Vector2(800.0, 826.0), slot)
	var bounds: Rect2 = Rect2(0.0, 0.0, 1600.0, 900.0).grow(-SkillTooltip.SCREEN_MARGIN)
	var above: Vector2 = SkillTooltip.placement(hotbar, card, bounds)
	equal(above.y + card.y + SkillTooltip.GAP, hotbar.position.y, "card fica logo acima do slot")
	equal(above.x + card.x * 0.5, hotbar.get_center().x, "card centralizado no slot")


func _music_director() -> MusicDirector:
	var config: MusicConfig = (load(MusicDirector.CONFIG_PATH) as MusicConfig).duplicate()
	config.crossfade_seconds = MUSIC_TEST_FADE
	config.fade_out_seconds = MUSIC_TEST_FADE
	var director := MusicDirector.new()
	director.config = config
	add_child(director)
	return director


func _music_fade_done() -> void:
	await get_tree().create_timer(MUSIC_TEST_FADE * 4.0).timeout


func test_music_config_has_looping_tracks() -> void:
	var config: MusicConfig = load(MusicDirector.CONFIG_PATH) as MusicConfig
	check(config != null, "music.tres carrega como MusicConfig")
	for track: AudioStream in [config.dungeon_track, config.boss_track]:
		var wav := track as AudioStreamWAV
		check(wav != null, "faixa é AudioStreamWAV")
		equal(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "faixa em loop")
		check(wav.loop_end > wav.loop_begin, "trecho de loop válido")


func test_music_buses_exist() -> void:
	check(AudioServer.get_bus_index(&"Music") >= 0, "bus Music existe")
	check(AudioServer.get_bus_index(&"SFX") >= 0, "bus SFX existe")


func test_music_starts_on_dungeon_entered() -> void:
	var director := _music_director()
	equal(director.current, MusicDirector.Track.NONE, "começa em silêncio")
	Events.dungeon_entered.emit()
	equal(director.current, MusicDirector.Track.DUNGEON, "entrar toca a masmorra")
	check(director._dungeon_player.playing, "faixa da masmorra tocando")
	equal(director._dungeon_player.bus, &"Music", "faixa da masmorra no bus Music")
	equal(director._boss_player.bus, &"Music", "faixa do chefe no bus Music")
	await _music_fade_done()
	var target: float = db_to_linear(director.config.dungeon_volume_db)
	check(absf(director._dungeon_player.volume_linear - target) < 0.001, "fade chega ao volume da mixagem")
	director.free()


func test_music_ignores_repeated_events() -> void:
	var director := _music_director()
	Events.dungeon_entered.emit()
	var fade: Tween = director._fade
	Events.dungeon_entered.emit()
	check(director._fade == fade, "repetir a entrada não recria o fade")
	Events.boss_engaged.emit(self)
	check(director._fade != fade, "aggro cria um fade novo")
	fade = director._fade
	Events.boss_engaged.emit(self)
	check(director._fade == fade, "repetir o aggro não recria o fade")
	director.free()


func test_music_crossfades_to_boss_and_stops_dungeon() -> void:
	var director := _music_director()
	Events.dungeon_entered.emit()
	Events.boss_engaged.emit(self)
	equal(director.current, MusicDirector.Track.BOSS, "aggro toca a batalha")
	check(director._boss_player.playing, "faixa do chefe tocando")
	await _music_fade_done()
	check(not director._dungeon_player.playing, "masmorra para depois do fade")
	check(director._boss_player.playing, "faixa do chefe continua")
	director.free()


func test_music_boss_defeated_returns_to_dungeon() -> void:
	var director := _music_director()
	Events.dungeon_entered.emit()
	Events.boss_engaged.emit(self)
	await _music_fade_done()
	Events.boss_defeated.emit(self)
	equal(director.current, MusicDirector.Track.DUNGEON, "chefe morto volta à masmorra")
	check(director._dungeon_player.playing, "faixa da masmorra volta a tocar")
	await _music_fade_done()
	check(not director._boss_player.playing, "faixa do chefe para depois do fade")
	director.free()


func test_music_reversal_mid_fade_keeps_track_playing() -> void:
	var director := _music_director()
	Events.dungeon_entered.emit()
	await _music_fade_done()
	Events.boss_engaged.emit(self)
	Events.boss_disengaged.emit(self)
	equal(director.current, MusicDirector.Track.DUNGEON, "reversão volta à masmorra")
	check(director._dungeon_player.playing, "faixa da masmorra não foi cortada")
	await _music_fade_done()
	check(director._dungeon_player.playing, "faixa da masmorra segue depois do fade")
	check(not director._boss_player.playing, "faixa do chefe para depois da reversão")
	var target: float = db_to_linear(director.config.dungeon_volume_db)
	check(absf(director._dungeon_player.volume_linear - target) < 0.001, "volume volta à mixagem")
	director.free()


func test_music_late_boss_signals_stay_silent() -> void:
	var director := _music_director()
	Events.boss_defeated.emit(self)
	Events.boss_disengaged.emit(self)
	equal(director.current, MusicDirector.Track.NONE, "aviso tardio não liga a música")
	check(not director._dungeon_player.playing, "faixa da masmorra segue parada")
	check(not director._boss_player.playing, "faixa do chefe segue parada")
	director.free()


func test_music_dungeon_exited_fades_everything_out() -> void:
	var director := _music_director()
	Events.dungeon_entered.emit()
	Events.boss_engaged.emit(self)
	Events.dungeon_exited.emit()
	equal(director.current, MusicDirector.Track.NONE, "sair silencia")
	await _music_fade_done()
	check(not director._dungeon_player.playing, "faixa da masmorra parou")
	check(not director._boss_player.playing, "faixa do chefe parou")
	director.free()
