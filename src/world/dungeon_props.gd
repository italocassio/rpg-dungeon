class_name DungeonProps
extends RefCounted
## Monta a arquitetura e o cenário sobre a geometria gerada (arcos, colunas, cristais, luzes).

const ARCH_SPACING := 10.0
## Colunas ficam embutidas na parede: uma fresta estreita encrava quem anda encostado nela.
const PILLAR_INSET := 0.9
## Distância mínima entre uma coluna e a abertura de um corredor.
const OPENING_CLEARANCE := 3.4
const WARM := Color("ffb46a")
const WARM_DEEP := Color("ff8a3c")
const COLD := Color("bcd6ff")

var pillar_obstacles: Array[Vector3] = []  # (x, z, raio)
var lights: Array[OmniLight3D] = []
var forge_stations: Array[ForgeBrazier] = []
var chests: Array[TreasureChest] = []
var door: GateDoor
var door_position := Vector3.ZERO

var _root: Node3D
var _field: DungeonField
var _rng := RandomNumberGenerator.new()
var _stone: Material
var _stone_transforms: Dictionary[Mesh, Array] = {}


func build(root: Node3D, field: DungeonField) -> void:
	_root = root
	_field = field
	_rng.seed = 20261030
	_stone = DungeonMaterials.stone_prop(0.32)
	for corridor in field.dungeon.corridors:
		_decorate_corridor(corridor)
	for room in field.dungeon.rooms:
		_decorate_room(room)
	_scatter_ice_and_rubble()
	_flush_stone_instances()


func _add_stone(mesh: Mesh, transform: Transform3D) -> void:
	if not _stone_transforms.has(mesh):
		_stone_transforms[mesh] = []
	_stone_transforms[mesh].append(transform)


## Peças repetidas viram MultiMesh para reduzir draw calls em GPU integrada.
func _flush_stone_instances() -> void:
	for mesh: Mesh in _stone_transforms:
		_multimesh(mesh, _stone_transforms[mesh], _stone)
	_stone_transforms.clear()


func _multimesh(mesh: Mesh, transforms: Array, material: Material, shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = shadow
	_root.add_child(instance)
	return instance


func _add_light(position: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.15
	light.light_size = 0.15
	light.distance_fade_enabled = true
	light.distance_fade_begin = 44.0
	light.distance_fade_length = 14.0
	light.distance_fade_shadow = 26.0
	light.shadow_bias = 0.06
	_root.add_child(light)
	lights.append(light)
	return light


func _decorate_corridor(corridor: CorridorData) -> void:
	var half: float = corridor.width * 0.5
	var arch_mesh: ArrayMesh = MeshKit.extrude_path(
		MeshKit.arch_path(half + 0.2, corridor.wall_height, corridor.vault_height + 0.1), 0.55, 1.0)
	var torch_side: float = 1.0
	for i in corridor.points.size() - 1:
		var a: Vector2 = corridor.points[i]
		var b: Vector2 = corridor.points[i + 1]
		var length: float = a.distance_to(b)
		var direction: Vector2 = (b - a) / length
		var side := Vector2(-direction.y, direction.x)
		var basis := Basis.looking_at(Vector3(direction.x, 0.0, direction.y), Vector3.UP)
		var steps: int = maxi(int(length / ARCH_SPACING), 2)
		for step in range(1, steps):
			var point: Vector2 = a.lerp(b, float(step) / float(steps))
			if _field.room_at(point) != null:
				continue
			_add_stone(arch_mesh, Transform3D(basis, Vector3(point.x, 0.0, point.y)))
			_add_wall_torch(point + side * torch_side * (half - 0.55), side * -torch_side, corridor.wall_height)
			torch_side = -torch_side
		if corridor.has_gate_door and i == 0:
			_place_gate_door(a.lerp(b, 0.7), direction, corridor)


func _place_gate_door(point: Vector2, direction: Vector2, corridor: CorridorData) -> void:
	door = GateDoor.new()
	door.width = corridor.width + 0.4
	door.height = corridor.wall_height + 1.6
	door.position = Vector3(point.x, 0.0, point.y)
	door.rotation.y = atan2(direction.x, direction.y)
	door_position = door.position
	_root.add_child(door)
	_add_light(door.position + Vector3(0.0, 4.0, 0.0) - Vector3(direction.x, 0.0, direction.y) * 3.5, WARM, 2.4, 12.0)


func _add_wall_torch(point: Vector2, facing: Vector2, wall_height: float) -> void:
	var height: float = minf(wall_height * 0.62, 3.3)
	var base := Vector3(point.x, height, point.y)
	var sconce := MeshInstance3D.new()
	sconce.mesh = MeshKit.lathe(PackedVector2Array([Vector2(0.04, -0.5), Vector2(0.06, 0.0), Vector2(0.2, 0.18), Vector2(0.17, 0.22), Vector2(0.03, 0.1)]), 8)
	sconce.position = base
	sconce.material_override = DungeonMaterials.iron()
	_root.add_child(sconce)
	var fire := ParticleKit.flame(WARM, WARM_DEEP, 0.26, 14)
	fire.position = base + Vector3(0.0, 0.22, 0.0)
	_root.add_child(fire)
	_add_light(base + Vector3(facing.x, 0.15, facing.y) * 0.5, WARM, 2.4, 16.0)


func _decorate_room(room: RoomData) -> void:
	var count: int = _pillar_count(room)
	var pillar: ArrayMesh = _pillar_mesh(room.wall_height + 0.4)
	var rib: ArrayMesh = _dome_rib(room)
	for i in count:
		var angle: float = TAU * float(i) / float(count) + 0.2
		var direction := Vector2(cos(angle), sin(angle))
		if _near_opening(room, direction):
			continue
		var position: Vector2 = room.center + direction * (room.radius - PILLAR_INSET)
		var base: float = _field.floor_at(position) - 0.25
		_add_stone(pillar, Transform3D(Basis.IDENTITY, Vector3(position.x, base, position.y)))
		_add_stone(rib, Transform3D(Basis(Vector3.UP, -angle), Vector3(room.center.x, 0.0, room.center.y)))
		pillar_obstacles.append(Vector3(position.x, position.y, 0.95))

	match room.kind:
		RoomData.Kind.ENTRANCE:
			_build_forge_hall(room)
		RoomData.Kind.BOSS:
			_build_throne(room)
		RoomData.Kind.ANTECHAMBER:
			_add_light(_room_point(room, 4.6), COLD, 3.4, room.radius * 1.5)
			_add_banners(room, 4, 3.2)
		_:
			_add_light(_room_point(room, 4.8), COLD, 3.2, room.radius * 1.5)
			_add_centerpiece(room)
	if room.has_chest:
		var chest := TreasureChest.new()
		var spot: Vector2 = room.center + Vector2(room.radius * 0.45, -room.radius * 0.35)
		chest.position = _field.ground_position(spot)
		chest.rotation.y = -0.6
		_root.add_child(chest)
		chests.append(chest)
	# Luzes quentes de contraste em pontos opostos da sala.
	if room.kind != RoomData.Kind.BOSS:
		for sign_x: float in [-1.0, 1.0]:
			var edge: Vector2 = room.center + Vector2(sign_x * room.radius * 0.72, room.radius * 0.4)
			if _field.is_walkable(edge, 1.0):
				_add_floor_fire(edge, 0.85)


func _pillar_count(room: RoomData) -> int:
	return maxi(int(TAU * room.radius / 8.5), 6)


func _near_opening(room: RoomData, direction: Vector2) -> bool:
	var spread: float = OPENING_CLEARANCE / room.radius
	for offset: float in [-spread, 0.0, spread]:
		if _field.is_walkable(room.center + direction.rotated(offset) * (room.radius + 1.6), 0.0):
			return true
	return false


func _room_point(room: RoomData, height: float) -> Vector3:
	return Vector3(room.center.x, height, room.center.y)


func _pillar_mesh(height: float) -> ArrayMesh:
	var key: StringName = StringName("pillar_%.1f" % height)
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var r: float = 0.62
	var mesh: ArrayMesh = MeshKit.lathe(PackedVector2Array([
		Vector2(1.05, 0.0), Vector2(1.05, 0.4), Vector2(0.9, 0.5), Vector2(0.8, 0.85), Vector2(r, 1.05),
		Vector2(r * 0.94, height * 0.5), Vector2(r, height - 1.35), Vector2(0.8, height - 1.15),
		Vector2(0.86, height - 1.05), Vector2(1.1, height - 0.55), Vector2(1.3, height - 0.45), Vector2(1.3, height),
	]), 12, false)
	_mesh_cache[key] = mesh
	return mesh


var _mesh_cache: Dictionary[StringName, ArrayMesh] = {}


## Nervura da abóbada: da coluna até o fecho da sala, no plano radial.
func _dome_rib(room: RoomData) -> ArrayMesh:
	var key: StringName = StringName("rib_%s" % room.id)
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var path := PackedVector2Array()
	for i in 13:
		var t: float = float(i) / 12.0
		var depth: float = lerpf(1.3, room.radius, t)
		var ratio: float = clampf(depth / room.radius, 0.0, 1.0)
		var height: float = room.wall_height + room.dome_height * sqrt(1.0 - (1.0 - ratio) * (1.0 - ratio))
		path.append(Vector2(room.radius - depth, height))
	var mesh: ArrayMesh = MeshKit.extrude_path(path, 0.42, 0.8)
	_mesh_cache[key] = mesh
	return mesh


func _add_floor_fire(point: Vector2, scale: float) -> void:
	var brazier := ForgeBrazier.new()
	brazier.interactive = false
	brazier.position = _field.ground_position(point)
	brazier.scale = Vector3.ONE * scale
	_root.add_child(brazier)
	_add_light(brazier.position + Vector3(0.0, 2.2, 0.0), WARM, 1.9, 13.0)
	pillar_obstacles.append(Vector3(point.x, point.y, 0.8))


func _add_centerpiece(room: RoomData) -> void:
	var cluster := Node3D.new()
	cluster.position = _field.ground_position(room.center + Vector2(room.radius * -0.15, room.radius * 0.1))
	_root.add_child(cluster)
	var material: Material = DungeonMaterials.crystal(Color(0.1, 0.24, 0.42), Color(0.55, 0.8, 1.0), 1.0)
	for i in 5:
		var shard := MeshInstance3D.new()
		shard.mesh = MeshKit.shard(_rng.randf_range(0.3, 0.55), _rng.randf_range(1.4, 3.2), _rng, 6, 0.08)
		shard.material_override = material
		shard.position = Vector3(_rng.randf_range(-0.8, 0.8), -0.15, _rng.randf_range(-0.8, 0.8))
		shard.rotation = Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf() * TAU, _rng.randf_range(-0.3, 0.3))
		cluster.add_child(shard)
	var glow := _add_light(cluster.position + Vector3(0.0, 1.6, 0.0), Color("6cc2ff"), 2.2, 11.0)
	glow.shadow_enabled = false
	pillar_obstacles.append(Vector3(cluster.position.x, cluster.position.z, 1.5))


func _build_forge_hall(room: RoomData) -> void:
	# Quatro braseiros alinhados, como na Forja do Gelo da referência.
	for i in 4:
		var brazier := ForgeBrazier.new()
		var offset := Vector2(room.radius * 0.72, -6.0 + i * 4.0)
		brazier.position = _field.ground_position(room.center + offset)
		_root.add_child(brazier)
		forge_stations.append(brazier)
		pillar_obstacles.append(Vector3(brazier.position.x, brazier.position.z, 0.8))
		_add_light(brazier.position + Vector3(-0.8, 2.4, 0.0), WARM, 2.3, 12.0)
	_add_light(_room_point(room, 5.0), COLD, 2.0, room.radius * 1.6)
	_add_rune_floor(room, room.radius * 0.5, Color("53b6ff"))


func _build_throne(room: RoomData) -> void:
	var center: Vector2 = room.center
	var back: Vector2 = center + Vector2(0.0, room.radius - 6.0)
	# Degraus
	var steps := MeshInstance3D.new()
	steps.mesh = MeshKit.lathe(PackedVector2Array([Vector2(7.5, 0.0), Vector2(7.5, 0.25), Vector2(6.2, 0.25), Vector2(6.2, 0.5), Vector2(5.0, 0.5), Vector2(5.0, 0.75), Vector2(0.0, 0.75)]), 24, false, false)
	steps.position = Vector3(back.x, 0.0, back.y)
	steps.material_override = _stone
	_root.add_child(steps)
	# Trono
	var throne := Node3D.new()
	throne.position = Vector3(back.x, 0.75, back.y + 1.0)
	_root.add_child(throne)
	for part: Array in [
		[Vector3(4.0, 1.2, 3.0), Vector3(0.0, 0.6, 0.0)],
		[Vector3(4.2, 6.6, 0.9), Vector3(0.0, 3.3, 1.4)],
		[Vector3(0.7, 2.2, 3.0), Vector3(-2.1, 1.3, 0.0)],
		[Vector3(0.7, 2.2, 3.0), Vector3(2.1, 1.3, 0.0)],
	]:
		var block := MeshInstance3D.new()
		block.mesh = MeshKit.box(part[0])
		block.position = part[1]
		block.material_override = _stone
		throne.add_child(block)
	var crown_material: Material = DungeonMaterials.crystal(Color(0.2, 0.5, 0.85), Color(0.7, 0.93, 1.0), 2.2)
	for i in 7:
		var spike := MeshInstance3D.new()
		var height: float = 3.2 - absf(i - 3) * 0.7
		spike.mesh = MeshKit.shard(0.34, height, _rng, 5, 0.03)
		spike.position = Vector3((i - 3) * 0.62, 6.4, 1.4)
		spike.material_override = crown_material
		throne.add_child(spike)
	# Espadas colossais ladeando o trono
	for side: float in [-1.0, 1.0]:
		var sword := Node3D.new()
		sword.position = Vector3(back.x + side * 10.0, 0.0, back.y + 2.0)
		sword.rotation.z = side * 0.06
		_root.add_child(sword)
		var blade := MeshInstance3D.new()
		blade.mesh = MeshKit.blade(11.0, 1.5, 0.34, 0.14)
		blade.position.y = -0.4
		blade.material_override = DungeonMaterials.iron()
		sword.add_child(blade)
		var guard := MeshInstance3D.new()
		guard.mesh = MeshKit.box(Vector3(4.4, 0.55, 0.7))
		guard.position.y = 10.8
		guard.material_override = DungeonMaterials.iron()
		sword.add_child(guard)
		pillar_obstacles.append(Vector3(sword.position.x, sword.position.z, 1.1))
		_add_floor_fire(Vector2(back.x + side * 15.0, back.y - 6.0), 1.25)
	# Luz principal fria descendo do alto + contraluz atrás do trono
	_add_light(_room_point(room, 12.0), COLD, 9.0, room.radius * 2.0)
	_add_light(Vector3(back.x, 6.0, back.y - 1.0), Color("6cc2ff"), 4.0, 18.0)
	for side: float in [-1.0, 1.0]:
		_add_floor_fire(center + Vector2(side * 17.0, -10.0), 1.25)
	_add_banners(room, 8, 5.2)
	_add_rune_floor(room, room.radius * 0.62, Color("9fe3ff"))


func _add_rune_floor(room: RoomData, radius: float, color: Color) -> void:
	var rings: Array[float] = [radius, radius * 0.97, radius * 0.62]
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color.darkened(0.7)
	glow.emission_enabled = true
	glow.emission = color.darkened(0.2)
	glow.emission_energy_multiplier = 0.55
	for ring_radius in rings:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = ring_radius - 0.035
		mesh.outer_radius = ring_radius + 0.035
		mesh.rings = 48
		mesh.ring_segments = 4
		ring.mesh = mesh
		ring.position = Vector3(room.center.x, 0.0, room.center.y)
		ring.scale.y = 0.3
		ring.material_override = glow
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_root.add_child(ring)


func _add_banners(room: RoomData, count: int, height: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/banner.gdshader")
	material.set_shader_parameter("tex_noise", load("res://assets/textures/noise.png"))
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.8, height)
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.subdivide_depth = 10
	mesh.subdivide_width = 2
	var pillar_count: int = _pillar_count(room)
	var step: float = TAU / float(pillar_count)
	for i in count:
		var gap: float = floorf(TAU * (float(i) + 0.5) / float(count) / step)
		var angle: float = 0.2 + (gap + 0.5) * step
		var direction := Vector2(cos(angle), sin(angle))
		if _field.is_walkable(room.center + direction * (room.radius + 1.0), 0.0):
			continue
		var point: Vector2 = room.center + direction * (room.radius - 0.35)
		var banner := MeshInstance3D.new()
		banner.mesh = mesh
		banner.material_override = material
		banner.position = Vector3(point.x, room.wall_height - height * 0.5 - 0.2, point.y)
		banner.rotation.y = atan2(-direction.x, -direction.y)
		_root.add_child(banner)


func _scatter_ice_and_rubble() -> void:
	var variants: Array[ArrayMesh] = []
	for i in 4:
		variants.append(MeshKit.shard(_rng.randf_range(0.18, 0.34), _rng.randf_range(0.9, 2.1), _rng, 5, 0.1))
	var crystal_sets: Array[Array] = [[], [], [], []]
	var icicle_sets: Array[Array] = [[], [], [], []]
	var rocks: Array[ArrayMesh] = [MeshKit.rock(0.5, _rng), MeshKit.rock(0.35, _rng), MeshKit.rock(0.7, _rng, 0.55)]
	var rock_sets: Array[Array] = [[], [], []]

	for row in range(0, _field.rows, 2):
		for column in range(0, _field.columns, 2):
			var point: Vector2 = _field.grid_point(column, row) + Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9))
			var distance: float = _field.distance_at(point)
			if distance > -0.2:
				continue
			# Estalactites por todo o teto
			if _rng.randf() < 0.11:
				var length: float = _rng.randf_range(0.45, 1.0)
				var flip := Basis(Vector3.RIGHT, PI).scaled(Vector3(1.0, length, 1.0)).rotated(Vector3.UP, _rng.randf() * TAU)
				icicle_sets[_rng.randi() % 4].append(Transform3D(flip, Vector3(point.x, _field.ceiling_at(point) + 0.15, point.y)))
			if distance > -2.4:
				var roll: float = _rng.randf()
				if roll < 0.075:
					var cluster_center := _field.ground_position(point, -0.12)
					for _shard in _rng.randi_range(2, 4):
						var tilt := Basis.from_euler(Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf() * TAU, _rng.randf_range(-0.4, 0.4)))
						var offset := Vector3(_rng.randf_range(-0.5, 0.5), 0.0, _rng.randf_range(-0.5, 0.5))
						crystal_sets[_rng.randi() % 4].append(Transform3D(tilt.scaled(Vector3.ONE * _rng.randf_range(0.7, 1.3)), cluster_center + offset))
				elif roll < 0.2:
					var basis := Basis.from_euler(Vector3(_rng.randf() * TAU, _rng.randf() * TAU, 0.0)).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.2))
					rock_sets[_rng.randi() % 3].append(Transform3D(basis, _field.ground_position(point, 0.05)))

	var crystal: Material = DungeonMaterials.crystal(Color(0.09, 0.2, 0.36), Color(0.5, 0.74, 0.95), 0.8)
	var icicle: Material = DungeonMaterials.crystal(Color(0.2, 0.32, 0.48), Color(0.6, 0.78, 0.95), 0.25)
	for i in 4:
		if not crystal_sets[i].is_empty():
			_multimesh(variants[i], crystal_sets[i], crystal, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		if not icicle_sets[i].is_empty():
			_multimesh(variants[i], icicle_sets[i], icicle, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var rock_material: Material = DungeonMaterials.stone_prop(0.8)
	for i in 3:
		if not rock_sets[i].is_empty():
			_multimesh(rocks[i], rock_sets[i], rock_material)
