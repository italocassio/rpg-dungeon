class_name PartyBot
extends CharacterBody3D
## Companheiro controlado por IA (grupo simulado do MVP).

const GRAVITY := 18.0
const TURN_SPEED := 10.0
const ENGAGE_RADIUS := 17.0
const FOLLOW_DISTANCE := 4.2
const CATCH_UP_DISTANCE := 34.0
const REVIVE_SECONDS := 8.0

var sheet: CharacterSheet
var leader: Node3D
var slot_offset := Vector3.ZERO
## Ajusta um ponto de nascimento para chão seguro (fora de blocos fixos); a masmorra injeta.
var ground_resolver := Callable()
var nav: NavFollower
var machine := StateMachine.new()
var rig: CreatureRig
var brain: BotBrain

@onready var combatant: Combatant = $Combatant
@onready var caster: SkillCaster = $SkillCaster


func setup(member_sheet: CharacterSheet, display_name: String, leader_node: Node3D, offset: Vector3) -> void:
	sheet = member_sheet
	leader = leader_node
	slot_offset = offset
	name = display_name.validate_node_name()
	set_meta(&"display_name", display_name)


func _ready() -> void:
	var display_name: String = get_meta(&"display_name")
	combatant.setup(display_name, sheet.level, Combatant.Team.PARTY, sheet.derived_stats(), GameDB.balance)
	combatant.body_radius = 0.42
	combatant.body_height = 1.8
	combatant.damage_multiplier = GameDB.balance.bot_damage_multiplier
	caster.combatant = combatant
	rig = CreatureFactory.build_hero(HeroLook.from_sheet(sheet))
	add_child(rig)
	var plate := Nameplate.new()
	add_child(plate)
	plate.setup(combatant, display_name, Color("8dffb0"), 2.25, 0.9)
	nav = NavFollower.new(self)
	brain = BotBrain.new(self)
	machine.add(&"follow", BotStates.Follow.new(self))
	machine.add(&"fight", BotStates.Fight.new(self))
	machine.add(&"dead", BotStates.Dead.new(self))
	machine.start(&"follow")
	combatant.damaged.connect(func(amount: float, _s: Combatant, _c: bool, _t: float) -> void:
		if amount > 0.0:
			rig.flash_hit())
	combatant.died.connect(func(_killer: Combatant) -> void:
		caster.interrupt()
		machine.transition(&"dead"))
	combatant.revived.connect(func() -> void:
		rig.revive()
		machine.transition(&"follow"))
	caster.cast_started.connect(func(skill: SkillData, duration: float) -> void: rig.wind_up(skill.animation, duration))
	caster.skill_fired.connect(func(skill: SkillData, _aim: SkillAim) -> void: rig.strike(skill.animation))
	caster.cast_interrupted.connect(func(_skill: SkillData) -> void: rig.cancel_action())


func _physics_process(delta: float) -> void:
	machine.physics_update(delta)
	if combatant.is_forced_moving():
		velocity = Vector3.ZERO
	else:
		velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
		move_and_slide()
	rig.animate(delta, Vector2(velocity.x, velocity.z).length())


func move_to(goal: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = nav.direction_to(goal, delta)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length_squared() > 0.01:
		face(direction, delta)


func halt() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func face(direction: Vector3, delta: float) -> void:
	var yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, yaw, minf(TURN_SPEED * delta, 1.0))


func face_unit(unit: Combatant, delta: float) -> void:
	face(unit.world_position() - global_position, delta)


func formation_point() -> Vector3:
	return leader.global_position + (leader.global_basis * slot_offset)


## Ponto de formação onde o aliado pode reaparecer sem ficar dentro do trono, de colunas ou de paredes.
func respawn_point() -> Vector3:
	return safe_point(formation_point())


func safe_point(point: Vector3) -> Vector3:
	return ground_resolver.call(point) if ground_resolver.is_valid() else point


## Telegrafias de chefe: sai da área antes do impacto.
func danger_escape_point() -> Vector3:
	for zone in Telegraph.danger_zones(get_tree()):
		if zone.contains(global_position, 0.6):
			var away: Vector3 = global_position - zone.global_position
			away.y = 0.0
			if zone.shape == Telegraph.Shape.CIRCLE:
				return zone.global_position + away.normalized() * (zone.radius + 2.5)
			var side: Vector3 = zone.flat_forward.cross(Vector3.UP).normalized()
			if side.dot(away) < 0.0:
				side = -side
			return global_position + side * 7.0
	return Vector3.INF
