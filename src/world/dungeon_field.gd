class_name DungeonField
extends RefCounted
## Campo de distância assinado (SDF) da masmorra, amostrado em grade.
## Negativo = área jogável. Fonte única para paredes, piso, teto, mapas e spawn.

const CELL := 1.0
const MARGIN := 7.0
const UNION_SMOOTHING := 3.0
const WALL_WOBBLE := 0.45
const DRIFT_WIDTH := 3.0
const DRIFT_HEIGHT := 0.55

var dungeon: DungeonData
var origin: Vector2
var columns: int
var rows: int

var _sdf := PackedFloat32Array()
var _ceiling := PackedFloat32Array()
var _noise := FastNoiseLite.new()


func _init(data: DungeonData) -> void:
	dungeon = data
	_noise.seed = 1337
	_noise.frequency = 0.09
	_noise.fractal_octaves = 2
	_compute_bounds()
	_rasterize()


func _compute_bounds() -> void:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for room in dungeon.rooms:
		low = low.min(room.center - Vector2.ONE * room.radius)
		high = high.max(room.center + Vector2.ONE * room.radius)
	for corridor in dungeon.corridors:
		var half: float = corridor.width * 0.5
		for point in corridor.points:
			low = low.min(point - Vector2.ONE * half)
			high = high.max(point + Vector2.ONE * half)
	origin = low - Vector2.ONE * MARGIN
	columns = int(ceil((high.x - low.x + MARGIN * 2.0) / CELL)) + 1
	rows = int(ceil((high.y - low.y + MARGIN * 2.0) / CELL)) + 1


func _rasterize() -> void:
	_sdf.resize(columns * rows)
	_ceiling.resize(columns * rows)
	for row in rows:
		for column in columns:
			var point: Vector2 = grid_point(column, row)
			var distance: float = _raw_distance(point) + _noise.get_noise_2dv(point) * WALL_WOBBLE
			var index: int = column + row * columns
			_sdf[index] = distance
			_ceiling[index] = _ceiling_height(point) if distance < 3.0 else 6.0


func _raw_distance(point: Vector2) -> float:
	var distance: float = INF
	for room in dungeon.rooms:
		distance = _smooth_min(distance, point.distance_to(room.center) - room.radius)
	for corridor in dungeon.corridors:
		var half: float = corridor.width * 0.5
		for i in corridor.points.size() - 1:
			var segment: float = _segment_distance(point, corridor.points[i], corridor.points[i + 1])
			distance = _smooth_min(distance, segment - half)
	return distance


## A abóbada de cada sala/corredor é uma elipse; `max` cria arestas de encontro entre vãos.
func ceiling_exact(point: Vector2) -> float:
	return _ceiling_height(point)


func _ceiling_height(point: Vector2) -> float:
	var best: float = 0.0
	for room in dungeon.rooms:
		var depth: float = room.radius - point.distance_to(room.center)
		best = maxf(best, _vault(depth, room.radius, room.wall_height, room.dome_height))
	for corridor in dungeon.corridors:
		var half: float = corridor.width * 0.5
		for i in corridor.points.size() - 1:
			var depth: float = half - _segment_distance(point, corridor.points[i], corridor.points[i + 1])
			best = maxf(best, _vault(depth, half, corridor.wall_height, corridor.vault_height))
	return best if best > 0.0 else 6.0


static func _vault(depth: float, span: float, wall: float, rise: float) -> float:
	if depth < 0.0:
		return wall + depth * 4.0
	var t: float = clampf(depth / span, 0.0, 1.0)
	return wall + rise * sqrt(1.0 - (1.0 - t) * (1.0 - t))


static func _smooth_min(a: float, b: float) -> float:
	if a == INF:
		return b
	var h: float = clampf(0.5 + 0.5 * (b - a) / UNION_SMOOTHING, 0.0, 1.0)
	return lerpf(b, a, h) - UNION_SMOOTHING * h * (1.0 - h)


static func _segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)


func grid_point(column: int, row: int) -> Vector2:
	return origin + Vector2(column, row) * CELL


func grid_sdf(column: int, row: int) -> float:
	return _sdf[column + row * columns]


func grid_ceiling(column: int, row: int) -> float:
	return _ceiling[column + row * columns]


func distance_at(point: Vector2) -> float:
	return _bilinear(_sdf, point)


func ceiling_at(point: Vector2) -> float:
	return _bilinear(_ceiling, point)


func _bilinear(grid: PackedFloat32Array, point: Vector2) -> float:
	var local: Vector2 = (point - origin) / CELL
	var column: int = clampi(int(floor(local.x)), 0, columns - 2)
	var row: int = clampi(int(floor(local.y)), 0, rows - 2)
	var fx: float = clampf(local.x - column, 0.0, 1.0)
	var fy: float = clampf(local.y - row, 0.0, 1.0)
	var top: float = lerpf(grid[column + row * columns], grid[column + 1 + row * columns], fx)
	var bottom: float = lerpf(grid[column + (row + 1) * columns], grid[column + 1 + (row + 1) * columns], fx)
	return lerpf(top, bottom, fy)


## Neve acumulada junto às paredes (0..1).
func drift_at(point: Vector2) -> float:
	var depth: float = -distance_at(point)
	return smoothstep(DRIFT_WIDTH, 0.0, depth)


func floor_at(point: Vector2) -> float:
	return drift_at(point) * DRIFT_HEIGHT * (0.7 + _noise.get_noise_2dv(point * 2.0) * 0.6)


func ground_position(point: Vector2, lift: float = 0.0) -> Vector3:
	return Vector3(point.x, floor_at(point) + lift, point.y)


func is_walkable(point: Vector2, margin: float = 0.6) -> bool:
	return distance_at(point) < -margin


func room_at(point: Vector2) -> RoomData:
	for room in dungeon.rooms:
		if point.distance_to(room.center) < room.radius:
			return room
	return null


## Aproxima um ponto para dentro da área jogável seguindo o gradiente do campo.
func push_inside(point: Vector2, margin: float = 1.0) -> Vector2:
	var result: Vector2 = point
	for _i in 12:
		var distance: float = distance_at(result) + margin
		if distance <= 0.0:
			break
		var gradient := Vector2(
			distance_at(result + Vector2.RIGHT) - distance_at(result + Vector2.LEFT),
			distance_at(result + Vector2.DOWN) - distance_at(result + Vector2.UP))
		if gradient.length_squared() < 0.0001:
			break
		result -= gradient.normalized() * maxf(distance, 0.25)
	return result
