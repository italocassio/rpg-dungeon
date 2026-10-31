extends Node
## Testes de regras. Executar: godot --headless --path . res://tests/unit_tests.tscn

var _passed: int = 0
var _failed: int = 0
var _current: String = ""


func _ready() -> void:
	Session.save_path = "user://test_unit_save.json"
	for method in get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_"):
			_current = method_name
			await call(method_name)
	print("\nRESULTADO: %d verificações ok, %d falhas" % [_passed, _failed])
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
