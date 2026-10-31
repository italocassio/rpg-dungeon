class_name SkillAim
extends RefCounted
## Para onde uma habilidade foi mirada.

var origin: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.FORWARD
var target: Combatant
var ground_point: Vector3 = Vector3.ZERO


static func toward(caster: Combatant, target_unit: Combatant) -> SkillAim:
	var aim := SkillAim.new()
	aim.origin = caster.center_position()
	aim.target = target_unit
	var destination: Vector3 = target_unit.center_position()
	aim.direction = (destination - aim.origin).normalized()
	aim.ground_point = target_unit.world_position()
	return aim
