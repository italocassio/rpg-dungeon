class_name DungeonWorld
extends Node3D
## Cenário físico da masmorra: visual, colisão, navegação, luzes e ambiente.
## Não conhece regras de jogo; DungeonRun coordena a partida por cima dele.

const LIGHT_UPDATE_INTERVAL := 0.4
const SNOW_EXTENTS := Vector3(13.0, 4.5, 13.0)

var field: DungeonField
var props: DungeonProps
var quality: DungeonEnvironment.Quality = DungeonEnvironment.Quality.MEDIUM
var focus: Node3D

var _environment: Environment
var _snow: GPUParticles3D
var _light_timer: float = 0.0
var _navigation_region: NavigationRegion3D


func build(dungeon: DungeonData, gate_color: Color) -> void:
	field = DungeonField.new(dungeon)
	var mesher := DungeonMesher.new()
	mesher.build(field)
	_add_surface(mesher.floor_mesh, DungeonMaterials.floor_surface())
	_add_surface(mesher.wall_mesh, DungeonMaterials.wall())
	_add_surface(mesher.ceiling_mesh, DungeonMaterials.ceiling())
	_add_collision(mesher.collision_faces)

	props = DungeonProps.new()
	var scenery := Node3D.new()
	scenery.name = "Scenery"
	add_child(scenery)
	props.build(scenery, field)
	_add_pillar_collision()
	_bake_navigation(mesher.navigation_faces)

	var world_environment := WorldEnvironment.new()
	_environment = DungeonEnvironment.create(quality)
	world_environment.environment = _environment
	add_child(world_environment)

	_snow = ParticleKit.snowfall(SNOW_EXTENTS, 150)
	add_child(_snow)

	var entrance: RoomData = dungeon.room_of_kind(RoomData.Kind.ENTRANCE)
	if entrance != null:
		var portal := GatePortal.new()
		portal.gate_color = gate_color
		portal.position = field.ground_position(entrance.center + Vector2(0.0, -entrance.radius + 2.4))
		add_child(portal)
	apply_quality(quality)


func _add_surface(mesh: ArrayMesh, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)


func _add_collision(faces: PackedVector3Array) -> void:
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	# Paredes nunca devem ser atravessadas, mesmo por quem chegar pelo lado de trás.
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var body := StaticBody3D.new()
	body.name = "WorldCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_child(collider)
	add_child(body)


func _add_pillar_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "PillarCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for pillar in props.pillar_obstacles:
		var shape := CylinderShape3D.new()
		shape.radius = pillar.z
		shape.height = 12.0
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position = Vector3(pillar.x, 6.0, pillar.y)
		body.add_child(collider)


func _bake_navigation(faces: PackedVector3Array) -> void:
	var source := NavigationMeshSourceGeometryData3D.new()
	source.add_faces(faces, Transform3D.IDENTITY)
	for pillar in props.pillar_obstacles:
		var outline := PackedVector3Array()
		for i in 8:
			var angle: float = TAU * float(i) / 8.0
			outline.append(Vector3(pillar.x + cos(angle) * pillar.z, 0.0, pillar.y + sin(angle) * pillar.z))
		source.add_projected_obstruction(outline, -1.0, 6.0, true)
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.75
	mesh.agent_max_climb = 0.5
	mesh.agent_max_slope = 50.0
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.region_min_size = 4.0
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	_navigation_region = NavigationRegion3D.new()
	_navigation_region.name = "Navigation"
	_navigation_region.navigation_mesh = mesh
	add_child(_navigation_region)


func navigation_map() -> RID:
	return get_world_3d().navigation_map


func apply_quality(new_quality: DungeonEnvironment.Quality) -> void:
	quality = new_quality
	if _environment != null:
		DungeonEnvironment.apply_quality(_environment, quality)
	var viewport := get_viewport()
	if viewport != null:
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if quality != DungeonEnvironment.Quality.HIGH else Viewport.SCALING_3D_MODE_BILINEAR
		viewport.scaling_3d_scale = DungeonEnvironment.render_scale(quality)
	_update_light_shadows()


func _process(delta: float) -> void:
	if focus == null or not is_instance_valid(focus):
		return
	_snow.global_position = focus.global_position + Vector3(0.0, 2.0, 0.0)
	_light_timer -= delta
	if _light_timer <= 0.0:
		_light_timer = LIGHT_UPDATE_INTERVAL
		_update_light_shadows()


## Sombras só nas luzes mais próximas do jogador: mantém o custo estável com muitas luzes.
func _update_light_shadows() -> void:
	if props == null or focus == null or not is_instance_valid(focus):
		return
	var budget: int = DungeonEnvironment.shadowed_light_count(quality)
	var origin: Vector3 = focus.global_position
	var ordered: Array[OmniLight3D] = props.lights.duplicate()
	ordered.sort_custom(func(a: OmniLight3D, b: OmniLight3D) -> bool:
		return a.position.distance_squared_to(origin) < b.position.distance_squared_to(origin))
	for i in ordered.size():
		ordered[i].shadow_enabled = i < budget
