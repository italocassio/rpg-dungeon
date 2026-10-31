class_name BotBrain
extends RefCounted
## Decisões de combate dos companheiros, por papel da classe.

const MELEE_REACH := 2.8
const CASTER_DISTANCE := 13.0
const HEAL_THRESHOLD := 0.72
const EMERGENCY_THRESHOLD := 0.4

var bot: PartyBot
var _focus: Combatant
var _retarget: float = 0.0


func _init(owner_bot: PartyBot) -> void:
	bot = owner_bot


func _class() -> ClassData:
	return bot.sheet.class_data


func find_enemy() -> Combatant:
	var unit: Combatant = bot.combatant
	var leader_combatant: Combatant = bot.leader.get("combatant")
	var nearest: Combatant = CombatWorld.nearest_hostile(unit, PartyBot.ENGAGE_RADIUS)
	if nearest != null and not CombatWorld.has_line_of_sight(bot, unit.center_position(), nearest.center_position()):
		nearest = null
	if nearest == null and leader_combatant != null and leader_combatant.in_combat():
		nearest = CombatWorld.nearest_hostile(leader_combatant, PartyBot.ENGAGE_RADIUS)
	return nearest


func support_out_of_combat() -> void:
	if _class().role != ClassData.Role.HEALER:
		return
	_try_heal(HEAL_THRESHOLD)


## Retorna false quando não há mais inimigos para enfrentar.
func fight(delta: float) -> bool:
	var escape: Vector3 = bot.danger_escape_point()
	_retarget -= delta
	if _retarget <= 0.0 or _focus == null or not is_instance_valid(_focus) or not _focus.is_alive():
		_retarget = 1.0
		_focus = find_enemy()
	if _focus == null:
		return false
	if escape != Vector3.INF:
		bot.caster.interrupt()
		bot.move_to(escape, bot.combatant.stats.move_speed * 1.2, delta)
		return true
	match _class().role:
		ClassData.Role.TANK:
			_fight_tank(delta)
		ClassData.Role.HEALER:
			_fight_healer(delta)
		_:
			_fight_mage(delta)
	return true


func _distance_to(unit: Combatant) -> float:
	var a: Vector3 = bot.global_position
	var b: Vector3 = unit.world_position()
	return Vector2(a.x - b.x, a.z - b.z).length()


func _cast(skill: SkillData, target: Combatant) -> bool:
	if bot.caster.refusal(skill) != SkillCaster.Refusal.NONE:
		return false
	return bot.caster.try_cast(skill, SkillAim.toward(bot.combatant, target))


func _fight_tank(delta: float) -> void:
	var skills: Array[SkillData] = _class().skills
	var distance: float = _distance_to(_focus) - _focus.body_radius
	bot.face_unit(_focus, delta)
	var nearby: int = CombatWorld.hostiles_near(bot.combatant, bot.global_position, 6.0).size()
	if _class().ultimate != null and bot.combatant.sparks() >= 1 and distance < 5.0 and _cast(_class().ultimate, _focus):
		return
	if distance > 5.5 and distance < 12.0 and _cast(skills[0], _focus):
		return
	if nearby >= 2 and _cast(skills[2], _focus):
		return
	if nearby >= 2 and _cast(skills[1], _focus):
		return
	if distance < 7.0 and _cast(skills[3], _focus):
		return
	if distance <= MELEE_REACH:
		bot.halt()
		_cast(_class().basic_attack, _focus)
	else:
		bot.move_to(_focus.world_position(), bot.combatant.stats.move_speed, delta)


func _keep_distance(delta: float) -> void:
	var distance: float = _distance_to(_focus)
	var can_see: bool = CombatWorld.has_line_of_sight(bot, bot.combatant.center_position(), _focus.center_position())
	if distance > CASTER_DISTANCE + 4.0 or not can_see:
		bot.move_to(_focus.world_position(), bot.combatant.stats.move_speed, delta)
	elif distance < CASTER_DISTANCE * 0.5:
		var away: Vector3 = bot.global_position - _focus.world_position()
		away.y = 0.0
		bot.move_to(bot.global_position + away.normalized() * 6.0, bot.combatant.stats.move_speed, delta)
	else:
		bot.halt()
	bot.face_unit(_focus, delta)


func _fight_mage(delta: float) -> void:
	_keep_distance(delta)
	if bot.caster.is_casting():
		return
	var skills: Array[SkillData] = _class().skills
	var around: int = CombatWorld.hostiles_near(_focus, _focus.world_position(), 6.0).size()
	if _class().ultimate != null and bot.combatant.sparks() >= 1 and _distance_to(_focus) < 9.0 and _cast(_class().ultimate, _focus):
		return
	if around >= 2 and _cast(skills[2], _focus):
		return
	if _cast(skills[0], _focus):
		return
	if _cast(skills[1], _focus):
		return
	_cast(_class().basic_attack, _focus)


func _try_heal(threshold: float) -> bool:
	var hurt: Combatant = CombatWorld.most_hurt_ally(bot.combatant, 34.0)
	if hurt == null or hurt.hp_ratio() > threshold:
		return false
	return _cast(_class().skills[0], hurt)


func _fight_healer(delta: float) -> void:
	_keep_distance(delta)
	if bot.caster.is_casting():
		return
	var skills: Array[SkillData] = _class().skills
	var fallen: bool = false
	var critical: int = 0
	var hurt: int = 0
	for ally in CombatWorld.allies_of(bot.combatant, true):
		if not ally.is_alive():
			fallen = true
		elif ally.hp_ratio() < EMERGENCY_THRESHOLD:
			critical += 1
		if ally.is_alive() and ally.hp_ratio() < HEAL_THRESHOLD:
			hurt += 1
	if _class().ultimate != null and bot.combatant.sparks() >= 1 and (fallen or critical >= 2) and _cast(_class().ultimate, bot.combatant):
		return
	if _try_heal(HEAL_THRESHOLD):
		return
	if hurt >= 2 and _cast(skills[1], bot.combatant):
		return
	if _cast(skills[2], bot.combatant):
		return
	if _cast(skills[3], _focus):
		return
	_cast(_class().basic_attack, _focus)
