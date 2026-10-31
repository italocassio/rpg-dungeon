class_name Telegraph
extends Node3D
## Aviso visual de ataque + consulta usada pelos bots para sair da área de perigo.

enum Shape { CIRCLE, CONE, RECTANGLE }

const FLOOR_LIFT := 0.14

var shape: Shape = Shape.CIRCLE
var radius: float = 3.0
var half_angle: float = 0.8
var length: float = 10.0
var width: float = 3.0
var flat_forward := Vector3.FORWARD

var _material: ShaderMaterial
var _elapsed: float = 0.0
var _duration: float = 1.0


static func spawn(caster: Combatant, skill: SkillData, aim: SkillAim, duration: float) -> Telegraph:
	var telegraph := Telegraph.new()
	telegraph.flat_forward = Vector3(aim.direction.x, 0.0, aim.direction.z).normalized()
	var origin: Vector3 = caster.world_position()
	match skill.delivery:
		SkillData.Delivery.MELEE_CONE:
			telegraph.shape = Shape.CONE
			telegraph.radius = skill.skill_range
			telegraph.half_angle = deg_to_rad(skill.cone_degrees * 0.5)
		SkillData.Delivery.LINE:
			telegraph.shape = Shape.RECTANGLE
			telegraph.length = skill.skill_range
			telegraph.width = skill.line_width
		SkillData.Delivery.GROUND_AOE:
			telegraph.radius = skill.radius
			origin = aim.ground_point
		_:
			telegraph.radius = skill.radius
	telegraph._begin(caster.get_tree(), origin, duration, skill.color)
	return telegraph


static func spawn_area(tree: SceneTree, point: Vector3, area_radius: float, duration: float, color: Color) -> Telegraph:
	var telegraph := Telegraph.new()
	telegraph.radius = area_radius
	telegraph._begin(tree, point, duration, color)
	telegraph.remove_from_group(&"danger_zones")
	return telegraph


static func danger_zones(tree: SceneTree) -> Array[Telegraph]:
	var result: Array[Telegraph] = []
	for node in tree.get_nodes_in_group(&"danger_zones"):
		result.append(node as Telegraph)
	return result


func _begin(tree: SceneTree, origin: Vector3, duration: float, color: Color) -> void:
	_duration = maxf(duration, 0.05)
	add_to_group(&"danger_zones")
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		queue_free()
		return
	root_node.add_child(self)
	global_position = origin + Vector3.UP * FLOOR_LIFT
	if not Vfx.enabled():
		return
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = load("res://assets/shaders/telegraph.gdshader")
	_material.set_shader_parameter("tint", color)
	_material.set_shader_parameter("half_angle", half_angle)
	mesh.material_override = _material
	if flat_forward.length_squared() > 0.01:
		rotation.y = atan2(-flat_forward.x, -flat_forward.z)
	match shape:
		Shape.CIRCLE:
			quad.size = Vector2.ONE * radius * 2.0
			_material.set_shader_parameter("shape", 0)
		Shape.CONE:
			quad.size = Vector2.ONE * radius * 2.0
			_material.set_shader_parameter("shape", 1)
		Shape.RECTANGLE:
			quad.size = Vector2(width, length)
			mesh.position.z = -length * 0.5
			_material.set_shader_parameter("shape", 2)
	add_child(mesh)


func contains(point: Vector3, margin: float = 0.0) -> bool:
	var offset: Vector3 = point - global_position
	offset.y = 0.0
	match shape:
		Shape.CIRCLE:
			return offset.length() <= radius + margin
		Shape.CONE:
			if offset.length() > radius + margin:
				return false
			return offset.length() < 0.5 or flat_forward.angle_to(offset.normalized()) <= half_angle
		_:
			var along: float = offset.dot(flat_forward)
			return along >= -margin and along <= length + margin \
				and (offset - flat_forward * along).length() <= width * 0.5 + margin


func _process(delta: float) -> void:
	_elapsed += delta
	if _material != null:
		_material.set_shader_parameter("progress", clampf(_elapsed / _duration, 0.0, 1.0))
	if _elapsed >= _duration + 0.15:
		queue_free()
