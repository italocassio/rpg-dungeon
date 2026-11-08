class_name MeshKit
extends RefCounted
## Gerador de malhas procedurais usado por cenário, armas e criaturas.


## Revolve um perfil (raio, altura) em torno de Y.
static func lathe(profile: PackedVector2Array, sides: int = 12, smooth: bool = true, close_ends: bool = true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0 if smooth else -1)
	var ring := func(index: int, side: int) -> Vector3:
		var angle: float = TAU * float(side) / float(sides)
		return Vector3(cos(angle) * profile[index].x, profile[index].y, sin(angle) * profile[index].x)
	for i in profile.size() - 1:
		for side in sides:
			var a: Vector3 = ring.call(i, side)
			var b: Vector3 = ring.call(i, side + 1)
			var c: Vector3 = ring.call(i + 1, side + 1)
			var d: Vector3 = ring.call(i + 1, side)
			_quad(st, a, b, c, d)
	if close_ends:
		var bottom := Vector3(0.0, profile[0].y, 0.0)
		var top := Vector3(0.0, profile[profile.size() - 1].y, 0.0)
		for side in sides:
			_triangle(st, bottom, ring.call(0, side + 1), ring.call(0, side))
			_triangle(st, top, ring.call(profile.size() - 1, side), ring.call(profile.size() - 1, side + 1))
	st.generate_normals()
	return st.commit()


## Loft entre anéis elípticos: cada anel = Vector4(centro_x, altura, raio_x, raio_z).
static func loft(rings: Array[Vector4], sides: int = 10, smooth: bool = true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0 if smooth else -1)
	var at := func(index: int, side: int) -> Vector3:
		var angle: float = TAU * float(side) / float(sides)
		var ring: Vector4 = rings[index]
		return Vector3(ring.x + cos(angle) * ring.z, ring.y, sin(angle) * ring.w)
	for i in rings.size() - 1:
		for side in sides:
			_quad(st, at.call(i, side), at.call(i, side + 1), at.call(i + 1, side + 1), at.call(i + 1, side))
	var bottom := Vector3(rings[0].x, rings[0].y, 0.0)
	var last: Vector4 = rings[rings.size() - 1]
	var top := Vector3(last.x, last.y, 0.0)
	for side in sides:
		_triangle(st, bottom, at.call(0, side + 1), at.call(0, side))
		_triangle(st, top, at.call(rings.size() - 1, side), at.call(rings.size() - 1, side + 1))
	st.generate_normals()
	return st.commit()


## Cristal facetado com a ponta para cima (base em y = 0).
static func shard(radius: float, height: float, rng: RandomNumberGenerator, sides: int = 6, lean: float = 0.12) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var tip := Vector3(rng.randf_range(-lean, lean) * height, height, rng.randf_range(-lean, lean) * height)
	var shoulder_height: float = height * rng.randf_range(0.62, 0.78)
	var base_ring: Array[Vector3] = []
	var shoulder_ring: Array[Vector3] = []
	for side in sides:
		var angle: float = TAU * float(side) / float(sides) + rng.randf_range(-0.18, 0.18)
		var r: float = radius * rng.randf_range(0.8, 1.1)
		base_ring.append(Vector3(cos(angle) * r, 0.0, sin(angle) * r))
		shoulder_ring.append(Vector3(cos(angle) * r * 0.72 + tip.x * 0.5, shoulder_height, sin(angle) * r * 0.72 + tip.z * 0.5))
	for side in sides:
		var next: int = (side + 1) % sides
		_quad(st, base_ring[side], base_ring[next], shoulder_ring[next], shoulder_ring[side])
		_triangle(st, shoulder_ring[side], shoulder_ring[next], tip)
	st.generate_normals()
	return st.commit()


## Pedra irregular: icosfera grosseira deslocada, com faces planas.
static func rock(radius: float, rng: RandomNumberGenerator, squash: float = 0.7, jitter: float = 0.28) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 5
	sphere.radius = radius
	sphere.height = radius * 2.0
	var source: Array = sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = source[Mesh.ARRAY_INDEX]
	var displaced: Dictionary[Vector3i, Vector3] = {}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for index in indices:
		var vertex: Vector3 = vertices[index]
		var key := Vector3i((vertex * 100.0).round())
		if not displaced.has(key):
			var scale: float = 1.0 + rng.randf_range(-jitter, jitter)
			displaced[key] = Vector3(vertex.x * scale, vertex.y * scale * squash, vertex.z * scale)
		st.add_vertex(displaced[key])
	st.generate_normals()
	return st.commit()


## Lâmina em seção losango; base em y = 0, ponta em y = length.
static func blade(length: float, width: float, thickness: float, tip_ratio: float = 0.2, curve: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var levels: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0 - tip_ratio]
	var section := func(t: float) -> Array[Vector3]:
		var bend: float = curve * t * t * length
		var w: float = width * lerpf(1.0, 0.82, t)
		return [Vector3(-w * 0.5 + bend, t * length, 0.0), Vector3(bend, t * length, thickness * 0.5),
			Vector3(w * 0.5 + bend, t * length, 0.0), Vector3(bend, t * length, -thickness * 0.5)]
	for i in levels.size() - 1:
		var low: Array[Vector3] = section.call(levels[i])
		var high: Array[Vector3] = section.call(levels[i + 1])
		for side in 4:
			_quad(st, low[side], high[side], high[(side + 1) % 4], low[(side + 1) % 4])
	var neck: Array[Vector3] = section.call(1.0 - tip_ratio)
	var tip := Vector3(curve * length, length, 0.0)
	for side in 4:
		_triangle(st, neck[side], tip, neck[(side + 1) % 4])
	var base: Array[Vector3] = section.call(0.0)
	_quad(st, base[0], base[3], base[2], base[1])
	st.generate_normals()
	return st.commit()


## Faixa extrudada ao longo de um caminho 2D (x, y) no plano XY; seção thickness x depth.
static func extrude_path(path: PackedVector2Array, thickness: float, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var half: float = depth * 0.5
	var normal_at := func(i: int) -> Vector2:
		var previous: Vector2 = path[maxi(i - 1, 0)]
		var following: Vector2 = path[mini(i + 1, path.size() - 1)]
		var direction: Vector2 = (following - previous).normalized()
		return Vector2(-direction.y, direction.x)
	for i in path.size() - 1:
		var p0: Vector2 = path[i]
		var p1: Vector2 = path[i + 1]
		var n0: Vector2 = normal_at.call(i)
		var n1: Vector2 = normal_at.call(i + 1)
		var a0: Vector3 = _v(p0, -half)
		var a1: Vector3 = _v(p1, -half)
		var b0: Vector3 = _v(p0, half)
		var b1: Vector3 = _v(p1, half)
		var c0: Vector3 = _v(p0 + n0 * thickness, -half)
		var c1: Vector3 = _v(p1 + n1 * thickness, -half)
		var d0: Vector3 = _v(p0 + n0 * thickness, half)
		var d1: Vector3 = _v(p1 + n1 * thickness, half)
		_quad(st, c0, c1, d1, d0)
		_quad(st, a0, a1, c1, c0)
		_quad(st, b0, d0, d1, b1)
		_quad(st, a0, b0, b1, a1)
	st.generate_normals()
	return st.commit()


static func _v(point: Vector2, z: float) -> Vector3:
	return Vector3(point.x, point.y, z)


## Pano suspenso pela borda superior (capas), com ondulação e barra irregular.
static func cloth(top_width: float, bottom_width: float, length: float, flare: float, columns: int = 6, rows: int = 7) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var hem := PackedFloat32Array()
	for column in columns + 1:
		hem.append(rng.randf_range(-0.05, 0.05) * length)
	var at := func(column: int, row: int) -> Vector3:
		var u: float = float(column) / float(columns)
		var v: float = float(row) / float(rows)
		var width: float = lerpf(top_width, bottom_width, v)
		var fold: float = sin(u * TAU * 1.5) * 0.045 * v
		var y: float = -v * length + (hem[column] * v * v * v)
		return Vector3((u - 0.5) * width, y, flare * v * v + fold)
	for row in rows:
		for column in columns:
			_quad(st, at.call(column, row), at.call(column + 1, row), at.call(column + 1, row + 1), at.call(column, row + 1))
	st.generate_normals()
	return st.commit()


## Chapa fina a partir de um contorno 2D no plano XY, com espessura em Z. Facetada, em leque a partir do centro.
static func plate(outline: PackedVector2Array, thickness: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var half: float = thickness * 0.5
	var count: int = outline.size()
	var center := Vector2.ZERO
	for point in outline:
		center += point
	center /= count
	for i in count:
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % count]
		st.add_vertex(Vector3(center.x, center.y, half))
		st.add_vertex(Vector3(b.x, b.y, 0.0))
		st.add_vertex(Vector3(a.x, a.y, 0.0))
		st.add_vertex(Vector3(center.x, center.y, -half))
		st.add_vertex(Vector3(a.x, a.y, 0.0))
		st.add_vertex(Vector3(b.x, b.y, 0.0))
	st.generate_normals()
	return st.commit()


## Arco de pedra para corredores: sobe pelas paredes e fecha em elipse.
static func arch_path(half_width: float, wall_height: float, rise: float, segments: int = 12) -> PackedVector2Array:
	var path := PackedVector2Array([Vector2(half_width, -0.6), Vector2(half_width, wall_height)])
	for i in range(1, segments):
		var angle: float = PI * float(i) / float(segments)
		path.append(Vector2(cos(angle) * half_width, wall_height + sin(angle) * rise))
	path.append(Vector2(-half_width, wall_height))
	path.append(Vector2(-half_width, -0.6))
	return path


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func cylinder(radius_top: float, radius_bottom: float, height: float, sides: int = 10) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return mesh


static func sphere(radius: float, segments: int = 12) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(segments / 2, 4)
	return mesh


static func torus(inner: float, outer: float, sides: int = 16) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = sides
	mesh.ring_segments = 8
	return mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(st, a, b, c)
	_triangle(st, a, c, d)


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
