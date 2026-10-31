class_name NavFollower
extends RefCounted
## Segue caminhos do NavigationServer, recalculando em intervalos para poupar CPU.

const REPATH_INTERVAL := 0.4
const WAYPOINT_REACHED := 0.7

var body: Node3D
var _path := PackedVector3Array()
var _index: int = 0
var _timer: float = 0.0
var _last_goal := Vector3.INF


func _init(owner_body: Node3D) -> void:
	body = owner_body
	_timer = randf() * REPATH_INTERVAL


## Direção horizontal normalizada para chegar a `goal`.
func direction_to(goal: Vector3, delta: float) -> Vector3:
	_timer -= delta
	if _timer <= 0.0 or _path.is_empty() or goal.distance_squared_to(_last_goal) > 4.0:
		_refresh(goal)
	var position: Vector3 = body.global_position
	while _index < _path.size() - 1 and _flat(position, _path[_index]) < WAYPOINT_REACHED:
		_index += 1
	var waypoint: Vector3 = _path[_index] if _index < _path.size() else goal
	var direction := Vector3(waypoint.x - position.x, 0.0, waypoint.z - position.z)
	return direction.normalized() if direction.length_squared() > 0.0001 else Vector3.ZERO


func _refresh(goal: Vector3) -> void:
	_timer = REPATH_INTERVAL
	_last_goal = goal
	var map: RID = body.get_world_3d().navigation_map
	_path = NavigationServer3D.map_get_path(map, body.global_position, goal, true)
	_index = 1 if _path.size() > 1 else 0


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
