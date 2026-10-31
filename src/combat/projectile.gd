class_name Projectile
extends Node3D
## Projétil mágico. Colide com paredes e com o primeiro inimigo no caminho.

const HIT_PADDING := 0.3

var skill: SkillData
var caster: Combatant
var velocity := Vector3.ZERO
var _travelled: float = 0.0


static func launch(from_skill: SkillData, from_caster: Combatant, aim: SkillAim) -> void:
	var root_node: Node3D = CombatWorld.root(from_caster.get_tree())
	if root_node == null:
		return
	var projectile := Projectile.new()
	projectile.skill = from_skill
	projectile.caster = from_caster
	projectile.velocity = aim.direction.normalized() * from_skill.projectile_speed
	root_node.add_child(projectile)
	projectile.global_position = aim.origin
	Vfx.attach_projectile_visual(projectile, from_skill)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster):
		queue_free()
		return
	var from: Vector3 = global_position
	var step: Vector3 = velocity * delta
	var to: Vector3 = from + step
	var space := get_world_3d().direct_space_state
	var wall_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, CombatWorld.WORLD_MASK))
	var limit: float = step.length()
	if not wall_hit.is_empty():
		limit = from.distance_to(wall_hit.position)

	var target: Combatant = _first_target(from, step.normalized(), limit)
	if target != null:
		_impact(target.center_position(), target)
		return
	if not wall_hit.is_empty():
		_impact(wall_hit.position, null)
		return

	global_position = to
	_travelled += step.length()
	if _travelled > skill.skill_range:
		_impact(global_position, null)


func _first_target(from: Vector3, direction: Vector3, limit: float) -> Combatant:
	var best: Combatant = null
	var best_along: float = limit + 0.001
	for hostile in CombatWorld.hostiles_of(caster):
		var center: Vector3 = hostile.world_position()
		var half_height: float = hostile.body_height * 0.5
		var along: float = (Vector3(center.x, from.y, center.z) - from).dot(direction)
		if along < -hostile.body_radius or along > best_along:
			continue
		var closest: Vector3 = from + direction * clampf(along, 0.0, limit)
		var flat := Vector2(closest.x - center.x, closest.z - center.z)
		if flat.length() > hostile.body_radius + HIT_PADDING:
			continue
		if absf(closest.y - (center.y + half_height)) > half_height + HIT_PADDING:
			continue
		best_along = along
		best = hostile
	return best


func _impact(point: Vector3, target: Combatant) -> void:
	if skill.radius > 0.0:
		SkillExecutor.area_impact(skill, caster, point)
	else:
		Events.skill_impacted.emit(skill, caster, point)
		if target != null and SkillExecutor.strike(skill, caster, target):
			caster.add_chi(skill.chi_gain)
	Vfx.hit_burst(get_tree(), point, skill.color)
	queue_free()
