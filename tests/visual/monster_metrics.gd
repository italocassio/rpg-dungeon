extends RefCounted
## Medidas de um monstro montado para a revisão de arte (`hero_review --monster=<id>`). Só lê o modelo.
## Tudo no espaço do rig (sem a escala do MonsterData); só os campos `world_*` e a caixa do corpo usam a escala.

## Regra J2 do guia de estilo: uma peça entra pelo menos 3 cm na peça vizinha.
const J2_MIN_OVERLAP := 0.03
const SIDES: Array[StringName] = [&"r", &"l"]
const HAND_JOINTS: Array[StringName] = [&"hand_r", &"hand_l"]
const PRECISION := 0.0001
const WEAPON_ACTIONS: Array[StringName] = [&"swing", &"overhead", &"thrust"]
const WINDUP_SECONDS := 1.0
const WINDUP_SETTLE := 2.0
## Passo depois do disparo: passa de `strike_time` (0,18 s no chefe), então é o fim do golpe.
const STRIKE_SETTLE := 0.18


## Vão axial entre peças vizinhas de cada articulação, medido nos vértices das malhas presas direto a cada joint.
## `gap_m` > 0 é vão, < 0 é sobreposição. O eixo é o Y local do joint de cima, sem depender da pose:
## vão = base mais baixa da peça de cima menos o topo da peça de baixo, que fica na posição do joint filho.
## No joelho, o pé é a peça de menor topo e o membro é o resto das peças do joelho.
static func joint_gaps(rig: CreatureRig, world_scale: float) -> Dictionary:
	var result: Dictionary = {}
	for pair: Array in [["shoulder_elbow", &"shoulder", &"elbow"], ["elbow_hand", &"elbow", &"hand"], ["hip_knee", &"hip", &"knee"], ["knee_foot", &"knee", &""]]:
		var sides: Dictionary = {}
		for side in SIDES:
			var upper: Node3D = rig.get_joint(StringName("%s_%s" % [pair[1], side]))
			var gap: float = NAN
			if upper != null:
				if pair[2] == &"":
					gap = _knee_foot_gap(upper)
				else:
					var lower: Node3D = rig.get_joint(StringName("%s_%s" % [pair[2], side]))
					if lower != null:
						gap = _limb_gap(upper, lower)
			sides[String(side)] = _gap_entry(gap, world_scale)
		result[pair[0]] = sides
	return result


static func _gap_entry(gap: float, world_scale: float) -> Variant:
	if is_nan(gap):
		return null
	return {
		"gap_m": snappedf(gap, PRECISION),
		"world_gap_m": snappedf(gap * world_scale, PRECISION),
		"j2_ok": -gap >= J2_MIN_OVERLAP,
	}


static func _limb_gap(upper: Node3D, lower: Node3D) -> float:
	var upper_range: Vector2 = _y_range(_direct_meshes(upper))
	var lower_range: Vector2 = _y_range(_direct_meshes(lower))
	if upper_range.x > upper_range.y or lower_range.x > lower_range.y:
		return NAN
	return upper_range.x - (lower.position.y + lower_range.y)


static func _knee_foot_gap(knee: Node3D) -> float:
	var meshes: Array[MeshInstance3D] = _direct_meshes(knee)
	if meshes.size() < 2:
		return NAN
	var foot: MeshInstance3D = meshes[0]
	for mesh in meshes:
		if _y_range([mesh]).y < _y_range([foot]).y:
			foot = mesh
	var limb: Array[MeshInstance3D] = meshes.duplicate()
	limb.erase(foot)
	return _y_range(limb).x - _y_range([foot]).y


static func _direct_meshes(joint: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in joint.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
			meshes.append(child)
	return meshes


## x = menor Y, y = maior Y dos vértices no frame do joint. (INF, -INF) sem malhas.
static func _y_range(meshes: Array) -> Vector2:
	var range_y := Vector2(INF, -INF)
	for mesh: MeshInstance3D in meshes:
		for point in mesh.transform * mesh.mesh.get_faces():
			range_y.x = minf(range_y.x, point.y)
			range_y.y = maxf(range_y.y, point.y)
	return range_y


## Corpo sem arma (o que não é malha presa à mão) e sem capa (a única peça sem sombra), no espaço do rig.
static func body_points(rig: CreatureRig) -> PackedVector3Array:
	var excluded: Dictionary = {}
	for hand in HAND_JOINTS:
		var joint: Node3D = rig.get_joint(hand)
		if joint == null:
			continue
		for child in joint.get_children():
			if not child is MeshInstance3D:
				for weapon_mesh in child.find_children("*", "MeshInstance3D", true, false):
					excluded[weapon_mesh] = true
	var to_rig: Transform3D = rig.global_transform.affine_inverse()
	var points := PackedVector3Array()
	for instance: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		if instance.mesh == null or not instance.is_visible_in_tree() or excluded.has(instance):
			continue
		if instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		points.append_array((to_rig * instance.global_transform) * instance.mesh.get_faces())
	return points


## A cápsula do inimigo tem a base no chão (o piso corta a semiesfera de baixo) e a de cima arredondada.
## `overflow_m` é o quanto o vértice mais distante passa do raio; <= 0 cabe.
static func body_vs_capsule(rig: CreatureRig, world_scale: float, radius: float, height: float) -> Dictionary:
	var capsule_height: float = maxf(height, radius * 2.0)
	var box := AABB()
	var radial: float = 0.0
	var overflow: float = -INF
	var outside: int = 0
	var points: PackedVector3Array = body_points(rig)
	for index in points.size():
		var point: Vector3 = points[index] * world_scale
		box = AABB(point, Vector3.ZERO) if index == 0 else box.expand(point)
		radial = maxf(radial, Vector2(point.x, point.z).length())
		var axis_y: float = minf(point.y, capsule_height - radius)
		var excess: float = Vector3(point.x, point.y - axis_y, point.z).length() - radius
		overflow = maxf(overflow, excess)
		if excess > 0.0:
			outside += 1
	if points.is_empty():
		return {}
	var fits_height: bool = box.end.y <= capsule_height
	var fits_radius: bool = radial <= radius
	return {
		"box_size_m": _rounded(box.size),
		"box_min_m": _rounded(box.position),
		"box_max_m": _rounded(box.end),
		"radial_max_m": snappedf(radial, 0.001),
		"capsule_radius_m": radius,
		"capsule_height_m": capsule_height,
		"height_ratio": snappedf(box.size.y / capsule_height, 0.001),
		"radius_ratio": snappedf(radial / radius, 0.001),
		"overflow_m": snappedf(overflow, 0.001),
		"vertices_outside": outside,
		"fits_height": fits_height,
		"fits_radius": fits_radius,
		"fits": overflow <= 0.0 and fits_height,
	}


static func _rounded(vector: Vector3) -> Array[float]:
	return [snappedf(vector.x, 0.001), snappedf(vector.y, 0.001), snappedf(vector.z, 0.001)]


## Mão e ponta da espada em repouso e, para cada golpe, no preparo (pose segurada) e no fim do golpe.
## Mexe na pose do rig: use um rig descartável. Coordenadas no espaço do rig vezes `world_scale`,
## com a origem do rig, `front_m` positivo à frente (-Z) e `x_m` positivo à direita do monstro (+X).
## `weapon_tip` e `pitch_deg` saem nulos sem o joint `weapon_tip`; `pitch_deg` é o ângulo da lâmina da mão à ponta.
static func weapon_poses(rig: CreatureRig, world_scale: float) -> Dictionary:
	rig.animate(0.0, 0.0)
	var result: Dictionary = {"rest": _weapon_pose(rig, world_scale)}
	for action in WEAPON_ACTIONS:
		rig.wind_up(action, WINDUP_SECONDS)
		rig.animate(WINDUP_SETTLE, 0.0)
		var windup: Dictionary = _weapon_pose(rig, world_scale)
		rig.strike(action)
		rig.animate(STRIKE_SETTLE, 0.0)
		result[String(action)] = {"windup": windup, "strike": _weapon_pose(rig, world_scale)}
		rig.cancel_action()
		rig.animate(0.0, 0.0)
	return result


static func _weapon_pose(rig: CreatureRig, world_scale: float) -> Dictionary:
	var hand: Vector3 = _local_point(rig, rig.get_joint(&"hand_r"), world_scale)
	var offhand: Vector3 = _local_point(rig, rig.get_joint(&"hand_l"), world_scale)
	var tip_joint: Node3D = rig.get_joint(&"weapon_tip")
	var pose: Dictionary = {"hand_r": _point_entry(hand), "hand_l": _point_entry(offhand), "weapon_tip": null, "pitch_deg": null}
	if tip_joint != null:
		var tip: Vector3 = _local_point(rig, tip_joint, world_scale)
		pose["weapon_tip"] = _point_entry(tip)
		pose["pitch_deg"] = snappedf(rad_to_deg(asin((tip - hand).normalized().y)), 0.1)
	return pose


static func _local_point(rig: CreatureRig, joint: Node3D, world_scale: float) -> Vector3:
	return rig.to_local(joint.global_position) * world_scale


static func _point_entry(point: Vector3) -> Dictionary:
	return {"x_m": snappedf(point.x, 0.001), "y_m": snappedf(point.y, 0.001), "front_m": snappedf(-point.z, 0.001)}
