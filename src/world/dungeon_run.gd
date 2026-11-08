class_name DungeonRun
extends Node3D
## Regras da partida: spawns, progresso, drops, porta do chefe, morte e vitória.

signal objectives_changed
signal run_finished(victory: bool)
signal player_respawning(seconds: float)
signal enemy_spawned(enemy: Enemy)

const PLAYER_SCENE: PackedScene = preload("res://src/actors/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://src/actors/enemy/enemy.tscn")
const BOT_SCENE: PackedScene = preload("res://src/actors/ally/party_bot.tscn")
const FORMATION: Array[Vector3] = [Vector3(-2.4, 0.0, 2.6), Vector3(2.4, 0.0, 2.6), Vector3(0.0, 0.0, 4.2), Vector3(-3.8, 0.0, 4.4)]
const ZONE_CHECK_INTERVAL := 0.3
## Paredes são malhas finas: espremido contra uma coluna, um corpo pode ser empurrado através delas.
## O campo da masmorra é a fronteira real; quem sai dele volta para dentro.
const CONTAINMENT_INTERVAL := 0.25
const OUTSIDE_TOLERANCE := -0.05
const CONTAINMENT_MARGIN := 0.8

var dungeon: DungeonData
var rank: GateRankData
var sheet: CharacterSheet
var world: DungeonWorld
var player: PlayerController
var combat: PlayerCombat
var bots: Array[PartyBot] = []
var boss: Enemy
var kills: int = 0
var chests_opened: int = 0
var loot_log: Dictionary[StringName, int] = {}
var crystals_gained: int = 0
var xp_gained: int = 0
var is_finished: bool = false
var boss_defeated_flag: bool = false
var door_opened: bool = false
var respawn_left: float = -1.0
var containment_rescues: int = 0

var _rng := RandomNumberGenerator.new()
var _zone_timer: float = 0.0
var _containment_timer: float = 0.0
var _current_room: RoomData
var _level_up_connected: Callable
var _summons: Array[Enemy] = []


func start(from_dungeon: DungeonData, gate_rank: GateRankData, character: CharacterSheet, party: Array[PartyMember]) -> void:
	dungeon = from_dungeon
	rank = gate_rank
	sheet = character
	_rng.randomize()
	add_to_group(&"world_root")
	world = DungeonWorld.new()
	world.name = "World"
	add_child(world)
	world.build(dungeon, rank.color)
	_wire_world()
	_spawn_player()
	_spawn_party(party)
	_spawn_monsters()
	_level_up_connected = _on_level_up
	sheet.leveled_up.connect(_level_up_connected)


func _exit_tree() -> void:
	if sheet != null and _level_up_connected.is_valid() and sheet.leveled_up.is_connected(_level_up_connected):
		sheet.leveled_up.disconnect(_level_up_connected)


func kills_required() -> int:
	return dungeon.kills_to_open_gate


func total_chests() -> int:
	return world.props.chests.size()


func _wire_world() -> void:
	var props: DungeonProps = world.props
	if props.door != null:
		props.door.unlock_check = _can_open_door
		props.door.opened.connect(_on_door_opened)
	for chest in props.chests:
		chest.looted.connect(_on_chest_looted)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	var entrance: RoomData = dungeon.room_of_kind(RoomData.Kind.ENTRANCE)
	player.global_position = world.field.ground_position(entrance.center + Vector2(0.0, -3.0), 0.2)
	player.setup_character(sheet, Session.player_name)
	player.look_at_point(world.field.ground_position(entrance.center + Vector2(0.0, entrance.radius), 1.6))
	combat = player.get_node("PlayerCombat")
	combat.setup(sheet)
	combat.party.append(player.combatant)
	world.focus = player.camera
	player.combatant.died.connect(_on_player_died)
	player.combatant.revived.connect(_on_player_revived)
	for station in world.props.forge_stations:
		station.requested.connect(func() -> void: combat.menu_requested.emit(&"forge"))


func _spawn_party(members: Array[PartyMember]) -> void:
	var index: int = 0
	for member: PartyMember in members:
		var bot: PartyBot = BOT_SCENE.instantiate()
		var bot_sheet: CharacterSheet = _build_bot_sheet(member)
		bot.setup(bot_sheet, member.display_name, player, FORMATION[index % FORMATION.size()])
		add_child(bot)
		bot.global_position = player.global_position + FORMATION[index % FORMATION.size()]
		bots.append(bot)
		combat.party.append(bot.combatant)
		index += 1


func _build_bot_sheet(member: PartyMember) -> CharacterSheet:
	var bot_sheet := CharacterSheet.new(member.class_data, GameDB.balance)
	bot_sheet.level = member.level
	bot_sheet.unspent_points = (member.level - 1) * GameDB.balance.attribute_points_per_level
	bot_sheet.auto_spend_points()
	var class_id: StringName = member.class_data.id
	bot_sheet.equip_directly(member.class_data.starter_weapons[0])
	bot_sheet.equip_directly(member.class_data.starter_armors[0])
	# Companheiros acompanham o rank do portão usando equipamento compatível com o nível.
	if member.level >= 3:
		for piece: String in ["weapon", "helm", "armor", "boots"]:
			var item: ItemData = GameDB.item(StringName("%s_t1_%s" % [class_id, piece]))
			if item != null:
				bot_sheet.equip_directly(item)
	if member.level >= 5:
		for piece: String in ["weapon", "armor"]:
			var item: ItemData = GameDB.item(StringName("%s_t2_%s" % [class_id, piece]))
			if item != null:
				bot_sheet.equip_directly(item)
	return bot_sheet


func _spawn_monsters() -> void:
	for group in dungeon.spawn_groups:
		for i in group.count:
			var angle: float = TAU * float(i) / float(maxi(group.count, 1)) + _rng.randf()
			var offset := Vector2(cos(angle), sin(angle)) * _rng.randf_range(group.spread * 0.4, group.spread)
			var point: Vector2 = world.field.push_inside(group.position + offset, 1.4)
			spawn_monster(group.monster, world.field.ground_position(point, 0.1))
	var throne: RoomData = dungeon.room_of_kind(RoomData.Kind.BOSS)
	if throne != null and dungeon.boss != null:
		var boss_point: Vector2 = throne.center + Vector2(0.0, 3.0)
		boss = spawn_monster(dungeon.boss, world.field.ground_position(boss_point, 0.1))
		var director := BossDirector.new()
		director.name = "BossDirector"
		boss.add_child(director)
		director.setup(boss)
		director.summon_requested.connect(_on_boss_summon)
		director.encounter_reset.connect(_clear_summons)


func spawn_monster(monster: MonsterData, point: Vector3) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(monster, rank, point, player, dungeon.enemy_glow)
	add_child(enemy)
	enemy.global_position = point
	enemy.defeated.connect(_on_enemy_defeated)
	enemy_spawned.emit(enemy)
	return enemy


func _on_boss_summon(monster: MonsterData, count: int, center: Vector3) -> void:
	for i in count:
		var angle: float = TAU * float(i) / float(count)
		var point: Vector2 = Vector2(center.x, center.z) + Vector2(cos(angle), sin(angle)) * 6.0
		var enemy: Enemy = spawn_monster(monster, world.field.ground_position(world.field.push_inside(point, 2.0), 0.1))
		enemy.is_summon = true
		_summons.append(enemy)
		enemy.engage(player.combatant)
		Vfx.shockwave(get_tree(), enemy.global_position, 2.0, Color("7fd4ff"))


## Invocados pertencem ao encontro: somem quando ele reinicia ou termina.
func _clear_summons() -> void:
	for enemy in _summons:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_summons.clear()


func _on_enemy_defeated(enemy: Enemy) -> void:
	if is_finished:
		return
	# Invocados não dão recompensa: senão reiniciar o chefe viraria uma fonte infinita de drops.
	if enemy.is_summon:
		_summons.erase(enemy)
		return
	var monster: MonsterData = enemy.data
	if monster.tier != MonsterData.Tier.BOSS:
		kills += 1
	var xp: int = roundi(monster.xp_reward * rank.xp_multiplier)
	var crystals: int = LootRoller.roll_crystals(monster, rank, _rng)
	if not sheet.is_max_level():
		xp_gained += xp
	crystals_gained += crystals
	sheet.inventory.add_crystals(crystals)
	sheet.add_xp(xp)
	Events.crystals_collected.emit(crystals)
	_scatter_loot(LootRoller.roll(monster, rank, _rng), enemy.global_position)
	objectives_changed.emit()
	if kills == kills_required():
		Events.system_message.emit("A Grande Porta pode ser aberta.", "quest")
	if enemy == boss:
		_on_boss_defeated()


func _scatter_loot(drops: Array[LootRoller.Drop], point: Vector3) -> void:
	for drop in drops:
		var loot := LootDrop.new()
		loot.item = drop.item
		loot.count = drop.count
		loot.collector = player
		loot.pickup_radius = GameDB.balance.loot_pickup_radius
		add_child(loot)
		var offset := Vector3(_rng.randf_range(-1.5, 1.5), 0.0, _rng.randf_range(-1.5, 1.5))
		var ground: Vector3 = world.field.ground_position(world.field.push_inside(Vector2(point.x + offset.x, point.z + offset.z), 0.8), 0.1)
		loot.global_position = ground
		loot.collected.connect(_on_loot_collected)


func _on_loot_collected(drop: LootDrop) -> void:
	sheet.inventory.add(drop.item.id, drop.count)
	loot_log[drop.item.id] = loot_log.get(drop.item.id, 0) + drop.count
	Events.loot_collected.emit(drop.item, drop.count)


func _on_chest_looted(chest: TreasureChest) -> void:
	chests_opened += 1
	var drops: Array[LootRoller.Drop] = []
	for entry in dungeon.chest_drops:
		if _rng.randf() <= entry.chance:
			drops.append(LootRoller.Drop.new(entry.item, _rng.randi_range(entry.min_count, entry.max_count)))
	_scatter_loot(drops, chest.global_position + chest.global_basis.z * 1.8)
	objectives_changed.emit()


func _can_open_door() -> bool:
	if kills >= kills_required():
		return true
	Events.system_message.emit("Selo ativo: derrote %d monstros (%d/%d)." % [kills_required(), kills, kills_required()], "warning")
	return false


func _on_door_opened() -> void:
	door_opened = true
	Events.system_message.emit("A Grande Porta se abriu. Algo desperta no trono...", "warning")
	objectives_changed.emit()


func _on_boss_defeated() -> void:
	boss_defeated_flag = true
	_clear_summons()
	Events.boss_defeated.emit(boss.combatant)
	Events.system_message.emit("Portão concluído! O núcleo da masmorra foi destruído.", "reward")
	var throne: RoomData = dungeon.room_of_kind(RoomData.Kind.BOSS)
	var portal := GatePortal.new()
	portal.is_exit = true
	portal.gate_color = Color("8dffb0")
	portal.activated.connect(finish.bind(true))
	world.add_child(portal)
	portal.global_position = world.field.ground_position(throne.center + Vector2(0.0, -6.0))
	objectives_changed.emit()


func finish(victory: bool) -> void:
	if is_finished:
		return
	is_finished = true
	if victory:
		_collect_remaining_loot()
	Session.save_game()
	run_finished.emit(victory)
	# Com os resultados na tela, ninguém mais pode atacar um jogador sem controle.
	process_mode = Node.PROCESS_MODE_DISABLED


## Item raro nunca se perde por sair com pressa: o que ficou no chão vai para o inventário.
func _collect_remaining_loot() -> void:
	for child in get_children():
		var drop := child as LootDrop
		if drop != null and drop.claim():
			_on_loot_collected(drop)
			drop.queue_free()


func _on_player_died(_killer: Combatant) -> void:
	respawn_left = GameDB.balance.respawn_seconds
	player_respawning.emit(respawn_left)
	Events.system_message.emit("Você caiu em combate.", "warning")


func _on_player_revived() -> void:
	respawn_left = -1.0
	player_respawning.emit(-1.0)


func _on_level_up(new_level: int) -> void:
	player.combatant.level = new_level
	player.combatant.base_stats = sheet.derived_stats()
	player.combatant.refresh_stats()
	player.combatant.restore_full()
	Events.system_message.emit("Nível aumentado! Você agora é nível %d. +%d pontos de atributo." % [new_level, GameDB.balance.attribute_points_per_level], "reward")
	Vfx.heal_glow(get_tree(), player.global_position, Color("7fd4ff"))


## Sempre o bloco de atributos do golpe real, com buffs ativos; Combatant.stats é recriado a cada recálculo.
func skill_info(skill: SkillData) -> SkillInfo:
	var unit: Combatant = player.combatant
	return SkillInfo.describe(skill, unit.stats, unit.balance, unit.damage_multiplier)


## Aplica mudanças feitas no painel (atributos ou equipamento) durante a partida.
func refresh_player_stats() -> void:
	player.combatant.base_stats = sheet.derived_stats()
	player.combatant.refresh_stats()
	player.viewmodel.setup(sheet.class_data, HeroLook.from_sheet(sheet))


func _physics_process(delta: float) -> void:
	if world == null or is_finished:
		return
	_contain(player)
	_containment_timer -= delta
	if _containment_timer > 0.0:
		return
	_containment_timer = CONTAINMENT_INTERVAL
	for bot in bots:
		_contain(bot)
	for node in get_tree().get_nodes_in_group(&"enemies"):
		_contain(node as Enemy)


func _contain(body: CharacterBody3D) -> void:
	var point := Vector2(body.global_position.x, body.global_position.z)
	if world.field.distance_at(point) <= OUTSIDE_TOLERANCE:
		return
	body.global_position = world.field.ground_position(world.field.push_inside(point, CONTAINMENT_MARGIN), 0.1)
	body.velocity = Vector3.ZERO
	containment_rescues += 1


func _process(delta: float) -> void:
	if world == null or is_finished:
		return
	_zone_timer -= delta
	if _zone_timer <= 0.0:
		_zone_timer = ZONE_CHECK_INTERVAL
		_check_zone()
	if respawn_left > 0.0:
		respawn_left -= delta
		if respawn_left <= 0.0:
			_respawn_party()


func _check_zone() -> void:
	var room: RoomData = world.field.room_at(Vector2(player.global_position.x, player.global_position.z))
	if room != null and room != _current_room:
		_current_room = room
		Events.zone_entered.emit(room.display_name)


## O jogador volta à entrada. Se todos caíram, os monstros perdem o alvo e voltam ao lugar.
func _respawn_party() -> void:
	respawn_left = -1.0
	var entrance: RoomData = dungeon.room_of_kind(RoomData.Kind.ENTRANCE)
	var spot: Vector3 = world.field.ground_position(entrance.center, 0.2)
	player.teleport_to(spot)
	player.combatant.revive(1.0)
	player.combatant.restore_full()
	player.caster.reset_all()
	for bot in bots:
		if not bot.combatant.is_alive():
			bot.global_position = spot + bot.slot_offset
			bot.combatant.revive(1.0)
			bot.combatant.restore_full()
