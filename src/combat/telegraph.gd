class_name Telegraph
extends Node3D
## Aviso visual de ataque + consulta usada pelos bots para sair da área de perigo.

enum Shape { CIRCLE, CONE, RECTANGLE }

const FLOOR_LIFT := 0.14
## Zona hostil: o desenho cobre a área lógica mais o raio do alvo (OS-022, seção 3).
const HOSTILE_MARGIN := 0.4
const HOSTILE_FILL := Color("A01030")
const HOSTILE_BAND := Color("220410")
const HOSTILE_EDGE := Color("FF6A4D")
const HOSTILE_WARNING := Color("FF9A7A")
const SHADER_PATH := "res://assets/shaders/telegraph.gdshader"
## Serrilha por estilo: [dentes na volta (círculo) ou no arco (cone) ou na ponta (linha), comprimento em metros].
const TEETH: Dictionary[int, Array] = {
	SkillFxData.TelegraphStyle.CONE_TEETH: [18, 0.35],
	SkillFxData.TelegraphStyle.CRACKS: [28, 0.35],
	SkillFxData.TelegraphStyle.CHEVRONS: [3, 0.6],
	SkillFxData.TelegraphStyle.CROWN: [48, 0.6],
}
## Rachaduras desenhadas por estilo, com a fase fixa (números ímpares: nenhum par a 90 ou 180 graus).
const CRACKS: Dictionary[int, Array] = {
	SkillFxData.TelegraphStyle.CRACKS: [7, 0.31],
	SkillFxData.TelegraphStyle.CROWN: [11, 0.17],
}

var shape: Shape = Shape.CIRCLE
var radius: float = 3.0
var half_angle: float = 0.8
var length: float = 10.0
var width: float = 3.0
var flat_forward := Vector3.FORWARD

## Conjurador hostil ao jogador (Team.MONSTERS): zona vermelha de perigo. Falso é a marca de aliado de sempre.
var hostile: bool = false
var style: SkillFxData.TelegraphStyle = SkillFxData.TelegraphStyle.PLAIN

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
	telegraph.hostile = hostile_caster(caster)
	if skill.fx != null:
		telegraph.style = skill.fx.telegraph_style
	telegraph._begin(caster.get_tree(), origin, duration, skill.color)
	return telegraph


## `hostile` falso é a marca de aliado (m_meteor, p_judgement), que continua como antes da OS-022.
static func spawn_area(tree: SceneTree, point: Vector3, area_radius: float, duration: float, color: Color, hostile: bool = false) -> Telegraph:
	var telegraph := Telegraph.new()
	telegraph.radius = area_radius
	telegraph.hostile = hostile
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
	if not Vfx.enabled() or (hostile and style == SkillFxData.TelegraphStyle.NONE):
		return
	var layout: Dictionary = Telegraph.layout(shape, radius, length, width, style, hostile)
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	quad.size = layout.size
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position.z = layout.center_z
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	var parameters: Dictionary = shader_parameters(color, hostile, shape, half_angle, radius, length, width, style)
	for key: String in parameters:
		_material.set_shader_parameter(key, parameters[key])
	mesh.material_override = _material
	if flat_forward.length_squared() > 0.01:
		rotation.y = atan2(-flat_forward.x, -flat_forward.z)
	add_child(mesh)


## Só o conjurador hostil ao jogador (Team.MONSTERS) desenha zona de perigo; o grupo mantém a marca de aliado.
static func hostile_caster(caster: Combatant) -> bool:
	return caster.team == Combatant.Team.MONSTERS


## Uniforms do shader para uma marca. Função pura, para os testes.
## `hostile` falso entrega só `tint`, `shape`, `half_angle` e `hostile`: a marca de aliado de sempre.
static func shader_parameters(color: Color, is_hostile: bool, shape_kind: Shape, half_angle_value: float, area_radius: float, line_length: float, line_width: float, telegraph_style: SkillFxData.TelegraphStyle) -> Dictionary:
	var parameters: Dictionary = {
		"tint": color,
		"half_angle": half_angle_value,
		"shape": int(shape_kind),
		"hostile": is_hostile,
	}
	if not is_hostile:
		return parameters
	var layout: Dictionary = Telegraph.layout(shape_kind, area_radius, line_length, line_width, telegraph_style, true)
	var crack_row: Array = CRACKS.get(telegraph_style, [0, 0.0])
	parameters.merge({
		"fill_color": HOSTILE_FILL,
		"band_color": HOSTILE_BAND,
		"edge_color": HOSTILE_EDGE,
		"warn_color": HOSTILE_WARNING,
		"crack_color": HOSTILE_BAND,
		"quad_size": layout.size,
		"draw_radius": layout.draw_radius,
		"tooth_length": layout.tooth_length,
		"tooth_count": float(layout.tooth_count),
		"logic_length": line_length,
		"draw_half_width": layout.draw_half_width,
		"back_margin": HOSTILE_MARGIN,
		"cracks": crack_row[0],
		"crack_phase": crack_row[1],
		"rings": telegraph_style == SkillFxData.TelegraphStyle.CROWN,
		"chevrons": telegraph_style == SkillFxData.TelegraphStyle.CHEVRONS,
	})
	return parameters


## Tamanho e posição do quadro do desenho, em metros. Função pura, para os testes.
## Marca de aliado: o tamanho lógico, sem margem. Zona hostil: mais 0,4 m em todas as bordas e a serrilha por fora.
## `size`: lado do QuadMesh; `center_z`: deslocamento do quadro ao longo da mira (negativo é a frente);
## `draw_radius` e `draw_half_width`: o limite do desenho, antes da serrilha.
static func layout(shape_kind: Shape, area_radius: float, line_length: float, line_width: float, telegraph_style: SkillFxData.TelegraphStyle, is_hostile: bool) -> Dictionary:
	var tooth_row: Array = TEETH.get(telegraph_style, [0, 0.0]) if is_hostile else [0, 0.0]
	var tooth_length: float = tooth_row[1]
	var margin: float = HOSTILE_MARGIN if is_hostile else 0.0
	var result: Dictionary = {
		"tooth_count": tooth_row[0],
		"tooth_length": tooth_length,
		"draw_radius": area_radius + margin,
		"draw_half_width": line_width * 0.5 + margin,
	}
	if shape_kind == Shape.RECTANGLE:
		result.size = Vector2(line_width + margin * 2.0, line_length + margin * 2.0 + tooth_length)
		result.center_z = -(line_length + tooth_length) * 0.5 if is_hostile else -line_length * 0.5
	else:
		result.size = Vector2.ONE * (area_radius + margin + tooth_length) * 2.0
		result.center_z = 0.0
	return result


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
