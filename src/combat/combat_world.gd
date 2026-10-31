class_name CombatWorld
extends RefCounted
## Consultas espaciais de combate.

const WORLD_MASK := 1
const MELEE_HEIGHT_TOLERANCE := 5.0


static func root(tree: SceneTree) -> Node3D:
	return tree.get_first_node_in_group(&"world_root") as Node3D


static func all(tree: SceneTree) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for node in tree.get_nodes_in_group(&"combatants"):
		result.append(node as Combatant)
	return result


static func hostiles_of(me: Combatant) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for other in all(me.get_tree()):
		if other.team != me.team and other.is_alive():
			result.append(other)
	return result


static func allies_of(me: Combatant, include_dead: bool = false) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for other in all(me.get_tree()):
		if other.team == me.team and (include_dead or other.is_alive()):
			result.append(other)
	return result


static func hostiles_near(me: Combatant, center: Vector3, radius: float) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for other in hostiles_of(me):
		if _flat_distance(other.world_position(), center) - other.body_radius <= radius:
			result.append(other)
	return result


static func allies_near(me: Combatant, center: Vector3, radius: float) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for other in allies_of(me):
		if _flat_distance(other.world_position(), center) <= radius:
			result.append(other)
	return result


static func nearest_hostile(me: Combatant, radius: float) -> Combatant:
	var best: Combatant = null
	var best_distance: float = radius
	for other in hostiles_of(me):
		var distance: float = _flat_distance(other.world_position(), me.world_position())
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


static func most_hurt_ally(me: Combatant, radius: float) -> Combatant:
	var best: Combatant = null
	var lowest: float = 2.0
	for other in allies_of(me):
		if _flat_distance(other.world_position(), me.world_position()) > radius:
			continue
		if other.hp_ratio() < lowest:
			lowest = other.hp_ratio()
			best = other
	return best


static func in_cone(origin: Vector3, forward: Vector3, target: Combatant, reach: float, degrees: float) -> bool:
	var offset: Vector3 = target.world_position() - origin
	if absf(offset.y) > MELEE_HEIGHT_TOLERANCE:
		return false
	offset.y = 0.0
	var distance: float = offset.length()
	if distance - target.body_radius > reach:
		return false
	if distance <= target.body_radius + 0.5:
		return true
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	var half: float = deg_to_rad(degrees * 0.5)
	# Alvos largos ocupam um ângulo maior.
	half += asin(clampf(target.body_radius / distance, 0.0, 1.0))
	return flat_forward.angle_to(offset / distance) <= half


static func in_line(origin: Vector3, forward: Vector3, target: Combatant, reach: float, width: float) -> bool:
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	var offset: Vector3 = target.world_position() - origin
	offset.y = 0.0
	var along: float = offset.dot(flat_forward)
	if along < -target.body_radius or along > reach + target.body_radius:
		return false
	return (offset - flat_forward * along).length() <= width * 0.5 + target.body_radius


static func has_line_of_sight(actor: Node3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK)
	return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Último ponto livre no caminho de `from` até `to`, respeitando paredes.
static func clear_destination(actor: Node3D, from: Vector3, to: Vector3, margin: float = 0.8) -> Vector3:
	var lifted_from: Vector3 = from + Vector3.UP * 0.9
	var lifted_to: Vector3 = to + Vector3.UP * 0.9
	var query := PhysicsRayQueryParameters3D.create(lifted_from, lifted_to, WORLD_MASK)
	var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	var free_distance: float = maxf(from.distance_to(hit.position) - margin, 0.0)
	return from + (to - from).normalized() * free_distance


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
