class_name DungeonWorld
extends Node3D
## Cenário físico da masmorra: visual, colisão, navegação, luzes e ambiente.
## Não conhece regras de jogo; DungeonRun coordena a partida por cima dele.

const LIGHT_UPDATE_INTERVAL := 0.4
const SNOW_EXTENTS := Vector3(13.0, 4.5, 13.0)
const NAV_AGENT_RADIUS := 0.5
## Folga de um bloco fixo na navmesh: o raio do agente mais a imprecisão do contorno (a malha é
## simplificada em até cerca de 0,35 m), para que nenhum canto de caminho encoste no bloco.
const NAV_BLOCK_MARGIN := 0.9
const SAFE_FIELD_MARGIN := 0.8

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
	for block in props.block_obstacles:
		var box := BoxShape3D.new()
		box.size = block.size
		var box_collider := CollisionShape3D.new()
		box_collider.shape = box
		box_collider.position = block.get_center()
		body.add_child(box_collider)
	for platform in props.platforms:
		var ramp_collider := CollisionShape3D.new()
		ramp_collider.shape = platform.collision_shape()
		ramp_collider.position = Vector3(platform.center.x, 0.0, platform.center.y)
		body.add_child(ramp_collider)


func _bake_navigation(faces: PackedVector3Array) -> void:
	var source := NavigationMeshSourceGeometryData3D.new()
	source.add_faces(_faces_outside_platforms(faces), Transform3D.IDENTITY)
	for platform in props.platforms:
		source.add_faces(platform.navigation_faces(), Transform3D.IDENTITY)
	for pillar in props.pillar_obstacles:
		var outline := PackedVector3Array()
		for i in 8:
			var angle: float = TAU * float(i) / 8.0
			outline.append(Vector3(pillar.x + cos(angle) * pillar.z, 0.0, pillar.y + sin(angle) * pillar.z))
		source.add_projected_obstruction(outline, -1.0, 6.0, true)
	for block in props.block_obstacles:
		# A obstrução não recebe o recuo do agente: sem a folga o caminho raspa na quina do bloco.
		var padded: AABB = block.grow(NAV_BLOCK_MARGIN)
		var corners := PackedVector3Array([
			Vector3(padded.position.x, 0.0, padded.position.z),
			Vector3(padded.end.x, 0.0, padded.position.z),
			Vector3(padded.end.x, 0.0, padded.end.z),
			Vector3(padded.position.x, 0.0, padded.end.z),
		])
		source.add_projected_obstruction(corners, -1.0, 6.0, true)
	var mesh := NavigationMesh.new()
	mesh.agent_radius = NAV_AGENT_RADIUS
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


## Chão em `point`: o maior entre o piso do campo e a superfície de um tablado. O campo não conhece os
## tablados, e a altura de um ponto da navmesh só aproxima a superfície (a malha é discretizada em células).
func ground_at(point: Vector2, lift: float = 0.0) -> Vector3:
	var height: float = maxf(field.floor_at(point), props.platform_height_at(point))
	return Vector3(point.x, height + lift, point.y)


## Ponto de chão onde um corpo pode nascer ou reaparecer: dentro do campo, fora dos blocos fixos
## (trono, colunas, paredes) e em cima da superfície (inclusive do tablado). Usa a navmesh, que já exclui
## tudo isso, só para escolher x e z; a altura vem de `ground_at`. Sem mapa pronto, cai no campo.
func safe_ground(point: Vector3, lift: float = 0.1) -> Vector3:
	var flat := Vector2(point.x, point.z)
	var map: RID = navigation_map()
	if map.is_valid() and NavigationServer3D.map_get_iteration_id(map) > 0 and not NavigationServer3D.map_get_regions(map).is_empty():
		var closest: Vector3 = NavigationServer3D.map_get_closest_point(map, ground_at(flat))
		return ground_at(Vector2(closest.x, closest.z), lift)
	for block in props.block_obstacles:
		flat = _push_out_of_block(flat, block)
	return ground_at(field.push_inside(flat, SAFE_FIELD_MARGIN), lift)


func _push_out_of_block(point: Vector2, block: AABB) -> Vector2:
	var padded: AABB = block.grow(NAV_BLOCK_MARGIN)
	if point.x <= padded.position.x or point.x >= padded.end.x or point.y <= padded.position.z or point.y >= padded.end.z:
		return point
	# Sai pelo lado mais curto, sem passar pela parede de trás.
	var exits: Array[Vector2] = [
		Vector2(padded.position.x, point.y),
		Vector2(padded.end.x, point.y),
		Vector2(point.x, padded.position.z),
	]
	var best: Vector2 = exits[0]
	for candidate in exits:
		if candidate.distance_squared_to(point) < best.distance_squared_to(point):
			best = candidate
	return best


## O piso sob um tablado não pode entrar no bake: ele ficaria como uma segunda camada caminhável
## sob a rampa e a navmesh perderia o topo. Quem anda ali pisa na superfície do tablado.
func _faces_outside_platforms(faces: PackedVector3Array) -> PackedVector3Array:
	if props.platforms.is_empty():
		return faces
	var kept := PackedVector3Array()
	for i in range(0, faces.size(), 3):
		var centroid: Vector3 = (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
		var covered: bool = false
		for platform in props.platforms:
			if Vector2(centroid.x, centroid.z).distance_to(platform.center) < platform.base_radius:
				covered = true
		if not covered:
			kept.append_array(faces.slice(i, i + 3))
	return kept


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
