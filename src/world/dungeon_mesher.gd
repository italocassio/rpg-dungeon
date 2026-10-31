class_name DungeonMesher
extends RefCounted
## Converte o DungeonField em malhas de piso, paredes e teto, além das faces de colisão.

const FLOOR_TILE := 4.0
const WALL_TILE := 4.0
const CEILING_TILE := 5.0
const WALL_RELIEF := 0.24
const WALL_LEVELS := 9
const WALL_BOTTOM := -1.0
## Frações do alcance em que a parede se curva para dentro formando o arranque da abóbada.
const VAULT_STEPS: Array[float] = [0.05, 0.13, 0.25, 0.4, 0.58, 0.78, 1.0]
const VAULT_MIN_REACH := 1.2
const VAULT_MAX_REACH := 3.2
const SURFACE_MARGIN := 1.6
## Teto em grade fica levemente acima do arranque para que este o sobreponha sem z-fighting.
const CEILING_OVERLAP_LIFT := 0.1

var floor_mesh: ArrayMesh
var wall_mesh: ArrayMesh
var ceiling_mesh: ArrayMesh
var collision_faces := PackedVector3Array()
var navigation_faces := PackedVector3Array()

var _field: DungeonField
var _relief := FastNoiseLite.new()


func build(field: DungeonField) -> void:
	_field = field
	_relief.seed = 91
	_relief.frequency = 0.17
	_relief.fractal_octaves = 3
	_build_horizontal_surfaces()
	_build_walls()


func _build_horizontal_surfaces() -> void:
	var columns: int = _field.columns
	var rows: int = _field.rows
	var vertex_index := PackedInt32Array()
	vertex_index.resize(columns * rows)
	vertex_index.fill(-1)

	var floor_positions := PackedVector3Array()
	var floor_normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var ceiling_positions := PackedVector3Array()
	var ceiling_normals := PackedVector3Array()
	var ceiling_uvs := PackedVector2Array()

	for row in rows:
		for column in columns:
			if _field.grid_sdf(column, row) > SURFACE_MARGIN + 1.0:
				continue
			vertex_index[column + row * columns] = floor_positions.size()
			var point: Vector2 = _field.grid_point(column, row)
			floor_positions.append(Vector3(point.x, _field.floor_at(point), point.y))
			floor_normals.append(_floor_normal(point))
			uvs.append(point / FLOOR_TILE)
			colors.append(Color(_field.drift_at(point), 0.0, 0.0))
			ceiling_positions.append(Vector3(point.x, _field.grid_ceiling(column, row) + CEILING_OVERLAP_LIFT, point.y))
			ceiling_normals.append(_ceiling_normal(point))
			ceiling_uvs.append(point / CEILING_TILE)

	var floor_indices := PackedInt32Array()
	var ceiling_indices := PackedInt32Array()
	for row in rows - 1:
		for column in columns - 1:
			var a: int = vertex_index[column + row * columns]
			var b: int = vertex_index[column + 1 + row * columns]
			var c: int = vertex_index[column + 1 + (row + 1) * columns]
			var d: int = vertex_index[column + (row + 1) * columns]
			if a < 0 or b < 0 or c < 0 or d < 0:
				continue
			var lowest: float = minf(minf(_field.grid_sdf(column, row), _field.grid_sdf(column + 1, row)),
				minf(_field.grid_sdf(column, row + 1), _field.grid_sdf(column + 1, row + 1)))
			if lowest > SURFACE_MARGIN:
				continue
			floor_indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
			var highest: float = maxf(maxf(_field.grid_sdf(column, row), _field.grid_sdf(column + 1, row)),
				maxf(_field.grid_sdf(column, row + 1), _field.grid_sdf(column + 1, row + 1)))
			if highest < -0.6:
				ceiling_indices.append_array(PackedInt32Array([a, c, b, a, d, c]))
			for vertex in [a, b, c, a, c, d]:
				collision_faces.append(floor_positions[vertex])
			if lowest < -0.2:
				for vertex in [a, b, c, a, c, d]:
					navigation_faces.append(floor_positions[vertex])

	floor_mesh = _array_mesh(floor_positions, floor_normals, uvs, floor_indices, Plane(1, 0, 0, 1), colors)
	ceiling_mesh = _array_mesh(ceiling_positions, ceiling_normals, ceiling_uvs, ceiling_indices, Plane(1, 0, 0, -1))


func _floor_normal(point: Vector2) -> Vector3:
	var dx: float = _field.floor_at(point + Vector2.RIGHT) - _field.floor_at(point + Vector2.LEFT)
	var dz: float = _field.floor_at(point + Vector2.DOWN) - _field.floor_at(point + Vector2.UP)
	return Vector3(-dx * 0.5, 1.0, -dz * 0.5).normalized()


func _ceiling_normal(point: Vector2) -> Vector3:
	var dx: float = _field.ceiling_at(point + Vector2.RIGHT) - _field.ceiling_at(point + Vector2.LEFT)
	var dz: float = _field.ceiling_at(point + Vector2.DOWN) - _field.ceiling_at(point + Vector2.UP)
	return Vector3(dx * 0.5, -1.0, dz * 0.5).normalized()


static func _array_mesh(positions: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array,
		indices: PackedInt32Array, tangent: Plane, colors := PackedColorArray()) -> ArrayMesh:
	var tangents := PackedFloat32Array()
	tangents.resize(positions.size() * 4)
	for i in positions.size():
		tangents[i * 4] = tangent.x
		tangents[i * 4 + 1] = tangent.y
		tangents[i * 4 + 2] = tangent.z
		tangents[i * 4 + 3] = tangent.d
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	if not colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_walls() -> void:
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for loop in _contour_loops():
		_extrude_loop(loop, positions, normals, tangents, uvs, indices)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	wall_mesh = ArrayMesh.new()
	wall_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _extrude_loop(loop: PackedVector2Array, positions: PackedVector3Array, normals: PackedVector3Array,
		tangents: PackedFloat32Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> void:
	var count: int = loop.size()
	if count < 4:
		return
	var length: float = 0.0
	for i in count:
		length += loop[i].distance_to(loop[(i + 1) % count])
	# Ajusta o tile para fechar o laço sem costura visível.
	var repeats: float = maxf(round(length / WALL_TILE), 1.0)
	var u_scale: float = repeats / length

	var base: int = positions.size()
	var level_count: int = WALL_LEVELS + VAULT_STEPS.size()
	var travelled: float = 0.0
	for i in count + 1:
		var point: Vector2 = loop[i % count]
		var previous: Vector2 = loop[(i - 1 + count) % count]
		var following: Vector2 = loop[(i + 1) % count]
		var along: Vector2 = (following - previous).normalized()
		var inward: Vector2 = _inward_normal(point)
		var top: float = _field.ceiling_exact(point + inward * 0.02)
		var tangent := Vector3(along.x, 0.0, along.y)
		var normal := Vector3(inward.x, 0.0, inward.y)
		var w: float = signf(normal.cross(tangent).y)
		for level in WALL_LEVELS:
			var height: float = lerpf(WALL_BOTTOM, top, float(level) / float(WALL_LEVELS - 1))
			var fade: float = smoothstep(top, top - 1.5, height)
			var relief: float = _relief.get_noise_2d(travelled, height * 1.6) * WALL_RELIEF * fade
			var shifted: Vector2 = point + inward * relief
			positions.append(Vector3(shifted.x, height, shifted.y))
			normals.append(normal)
			tangents.append_array(PackedFloat32Array([tangent.x, tangent.y, tangent.z, w]))
			uvs.append(Vector2(travelled * u_scale, -height / WALL_TILE))
		# Arranque da abóbada: segue a curva real do teto, continuando as fiadas da parede.
		var reach: float = clampf(_local_span(point, inward) * 0.72, VAULT_MIN_REACH, VAULT_MAX_REACH)
		var last := Vector3(point.x, top, point.y)
		var arc: float = top
		for step in VAULT_STEPS:
			var ring_point: Vector2 = point + inward * reach * step
			var vertex := Vector3(ring_point.x, _field.ceiling_exact(ring_point), ring_point.y)
			arc += vertex.distance_to(last)
			last = vertex
			positions.append(vertex)
			normals.append(Vector3.DOWN)
			tangents.append_array(PackedFloat32Array([tangent.x, tangent.y, tangent.z, w]))
			uvs.append(Vector2(travelled * u_scale, -arc / WALL_TILE))
		if i < count:
			travelled += point.distance_to(following)

	_smooth_vault_normals(positions, normals, base, count, level_count)

	# Orientação: frente voltada para a área jogável (sentido horário no Godot).
	var sample_along: Vector2 = loop[1] - loop[0]
	var sample_inward: Vector2 = _inward_normal(loop[0])
	var right_handed: bool = sample_along.x * sample_inward.y - sample_along.y * sample_inward.x > 0.0
	for i in count:
		for level in level_count - 1:
			var a: int = base + i * level_count + level
			var b: int = base + (i + 1) * level_count + level
			var c: int = a + 1
			var d: int = b + 1
			if right_handed:
				indices.append_array(PackedInt32Array([a, c, d, a, d, b]))
			else:
				indices.append_array(PackedInt32Array([a, d, c, a, b, d]))
		var p0: Vector2 = loop[i]
		var p1: Vector2 = loop[(i + 1) % count]
		var low0 := Vector3(p0.x, -1.0, p0.y)
		var low1 := Vector3(p1.x, -1.0, p1.y)
		var high0 := Vector3(p0.x, 13.0, p0.y)
		var high1 := Vector3(p1.x, 13.0, p1.y)
		if right_handed:
			collision_faces.append_array(PackedVector3Array([low0, high0, high1, low0, high1, low1]))
		else:
			collision_faces.append_array(PackedVector3Array([low0, high1, high0, low0, low1, high1]))


func _smooth_vault_normals(positions: PackedVector3Array, normals: PackedVector3Array, base: int, count: int, level_count: int) -> void:
	for i in count + 1:
		var left: int = maxi(i - 1, 0)
		var right: int = mini(i + 1, count)
		for level in range(WALL_LEVELS - 1, level_count):
			var below: int = maxi(level - 1, 0)
			var above: int = mini(level + 1, level_count - 1)
			var along: Vector3 = positions[base + right * level_count + level] - positions[base + left * level_count + level]
			var up: Vector3 = positions[base + i * level_count + above] - positions[base + i * level_count + below]
			var normal: Vector3 = along.cross(up).normalized()
			var reference: Vector3 = normals[base + i * level_count]
			if normal.dot(reference + Vector3.DOWN) < 0.0:
				normal = -normal
			normals[base + i * level_count + level] = normal


## Distância até o eixo medial do espaço (onde o SDF para de ficar mais negativo).
func _local_span(point: Vector2, inward: Vector2) -> float:
	var lowest: float = _field.distance_at(point)
	var span: float = 0.0
	for step in range(1, 12):
		var distance: float = _field.distance_at(point + inward * step * 0.5)
		if distance > lowest:
			break
		lowest = distance
		span = step * 0.5
	return span


func _inward_normal(point: Vector2) -> Vector2:
	var gradient := Vector2(
		_field.distance_at(point + Vector2.RIGHT * 0.7) - _field.distance_at(point + Vector2.LEFT * 0.7),
		_field.distance_at(point + Vector2.DOWN * 0.7) - _field.distance_at(point + Vector2.UP * 0.7))
	return -gradient.normalized() if gradient.length_squared() > 0.00001 else Vector2.UP


## Marching squares: encadeia os cruzamentos da isolinha SDF = 0 em laços fechados.
func _contour_loops() -> Array[PackedVector2Array]:
	var points: Dictionary[int, Vector2] = {}
	var links: Dictionary[int, PackedInt32Array] = {}
	for row in _field.rows - 1:
		for column in _field.columns - 1:
			_march_cell(column, row, points, links)

	var loops: Array[PackedVector2Array] = []
	var visited: Dictionary[int, bool] = {}
	for start: int in links:
		if visited.has(start):
			continue
		var loop := PackedVector2Array()
		var current: int = start
		var previous: int = -1
		while not visited.has(current):
			visited[current] = true
			loop.append(points[current])
			var neighbors: PackedInt32Array = links[current]
			var next: int = neighbors[0] if neighbors[0] != previous else neighbors[1]
			if neighbors.size() < 2:
				break
			previous = current
			current = next
		loops.append(loop)
	return loops


func _edge_key(column: int, row: int, vertical: bool) -> int:
	return (column + row * _field.columns) * 2 + (1 if vertical else 0)


func _march_cell(column: int, row: int, points: Dictionary, links: Dictionary) -> void:
	var a: float = _field.grid_sdf(column, row)
	var b: float = _field.grid_sdf(column + 1, row)
	var c: float = _field.grid_sdf(column + 1, row + 1)
	var d: float = _field.grid_sdf(column, row + 1)
	var crossings: Array[int] = []
	if (a < 0.0) != (b < 0.0):
		crossings.append(_crossing(_edge_key(column, row, false), _field.grid_point(column, row), _field.grid_point(column + 1, row), a, b, points))
	if (b < 0.0) != (c < 0.0):
		crossings.append(_crossing(_edge_key(column + 1, row, true), _field.grid_point(column + 1, row), _field.grid_point(column + 1, row + 1), b, c, points))
	if (c < 0.0) != (d < 0.0):
		crossings.append(_crossing(_edge_key(column, row + 1, false), _field.grid_point(column, row + 1), _field.grid_point(column + 1, row + 1), d, c, points))
	if (d < 0.0) != (a < 0.0):
		crossings.append(_crossing(_edge_key(column, row, true), _field.grid_point(column, row), _field.grid_point(column, row + 1), a, d, points))
	if crossings.size() == 2:
		_link(crossings[0], crossings[1], links)
	elif crossings.size() == 4:
		# Célula ambígua: decide pela média dos cantos.
		if (a + b + c + d) * 0.25 < 0.0:
			_link(crossings[0], crossings[1], links)
			_link(crossings[2], crossings[3], links)
		else:
			_link(crossings[0], crossings[3], links)
			_link(crossings[1], crossings[2], links)


func _crossing(key: int, p0: Vector2, p1: Vector2, v0: float, v1: float, points: Dictionary) -> int:
	if not points.has(key):
		points[key] = p0.lerp(p1, v0 / (v0 - v1))
	return key


func _link(a: int, b: int, links: Dictionary) -> void:
	if not links.has(a):
		links[a] = PackedInt32Array()
	if not links.has(b):
		links[b] = PackedInt32Array()
	links[a].append(b)
	links[b].append(a)
