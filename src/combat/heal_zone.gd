class_name HealZone
extends Node3D
## Área que cura aliados periodicamente (Círculo Sagrado).

const TICK_INTERVAL := 1.0

var skill: SkillData
var caster: Combatant
var _life: float = 0.0
var _tick: float = 0.0


static func spawn(from_skill: SkillData, from_caster: Combatant, point: Vector3) -> void:
	var root_node: Node3D = CombatWorld.root(from_caster.get_tree())
	if root_node == null:
		return
	var zone := HealZone.new()
	zone.skill = from_skill
	zone.caster = from_caster
	root_node.add_child(zone)
	zone.global_position = point
	Vfx.attach_zone_visual(zone, from_skill)


func _process(delta: float) -> void:
	_life += delta
	if _life >= skill.zone_duration or not is_instance_valid(caster):
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK_INTERVAL
	for ally in CombatWorld.allies_near(caster, global_position, skill.radius):
		ally.receive_heal(DamageCalculator.heal_amount(caster.stats, skill.power, caster.balance, caster.rng), caster)
