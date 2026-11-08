class_name RampPlatform
extends RefCounted
## Tablado em tronco de cone: rampa suave até um topo plano. Uma única descrição serve ao visual
## (perfil do torno), à colisão (casco convexo), à navmesh e à altura do chão, para nunca divergirem.

const SIDES := 24
## Parte enterrada da colisão: evita frestas onde o piso do campo fica abaixo de y = 0.
const SKIRT_DEPTH := 0.5

var center: Vector2
var base_radius: float
var top_radius: float
var height: float


func _init(at: Vector2, base: float, top: float, rise: float) -> void:
	center = at
	base_radius = base
	top_radius = top
	height = rise


## Perfil (raio, altura) para MeshKit.lathe com SIDES lados.
func profile() -> PackedVector2Array:
	return PackedVector2Array([Vector2(base_radius, 0.0), Vector2(top_radius, height), Vector2(0.0, height)])


## Altura da superfície visual acima de y = 0 (0 fora do tablado). Segue o polígono de SIDES lados
## da malha, não o círculo ideal, para coincidir com o visual e com a colisão.
func surface_height_at(point: Vector2) -> float:
	var offset: Vector2 = point - center
	var scale: float = _polygon_scale(offset.angle())
	var base: float = base_radius * scale
	var distance: float = offset.length()
	if distance >= base:
		return 0.0
	var top: float = top_radius * scale
	if distance <= top:
		return height
	return height * (base - distance) / (base - top)


func collision_shape() -> ConvexPolygonShape3D:
	var points := PackedVector3Array()
	for side in SIDES:
		var angle: float = TAU * float(side) / float(SIDES)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		points.append(direction * base_radius + Vector3.DOWN * SKIRT_DEPTH)
		points.append(direction * base_radius)
		points.append(direction * top_radius + Vector3.UP * height)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape


## Triângulos da rampa e do topo no espaço do mundo, com a frente para cima (como o piso do mesher), para a navmesh.
func navigation_faces() -> PackedVector3Array:
	var faces := PackedVector3Array()
	var origin := Vector3(center.x, 0.0, center.y)
	var apex: Vector3 = origin + Vector3.UP * height
	for side in SIDES:
		var angle_a: float = TAU * float(side) / float(SIDES)
		var angle_b: float = TAU * float(side + 1) / float(SIDES)
		var low_a: Vector3 = origin + Vector3(cos(angle_a), 0.0, sin(angle_a)) * base_radius
		var low_b: Vector3 = origin + Vector3(cos(angle_b), 0.0, sin(angle_b)) * base_radius
		var high_a: Vector3 = origin + Vector3(cos(angle_a) * top_radius, height, sin(angle_a) * top_radius)
		var high_b: Vector3 = origin + Vector3(cos(angle_b) * top_radius, height, sin(angle_b) * top_radius)
		_append_up(faces, low_a, low_b, high_b)
		_append_up(faces, low_a, high_b, high_a)
		_append_up(faces, apex, high_a, high_b)
	return faces


static func _polygon_scale(angle: float) -> float:
	var step: float = TAU / float(SIDES)
	var local: float = fposmod(angle, step) - step * 0.5
	return cos(step * 0.5) / cos(local)


## Godot trata o sentido horário como face da frente: de cima, o produto vetorial aponta para baixo.
static func _append_up(faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a)
	faces.append(a)
	if normal.y <= 0.0:
		faces.append(b)
		faces.append(c)
	else:
		faces.append(c)
		faces.append(b)
