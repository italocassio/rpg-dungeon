class_name ImpactPlan
extends RefCounted
## Plano do impacto de um ataque do chefe (OS-022, seção 5): onde ficam estacas, rachaduras, anéis, meias-luas
## e explosões de partículas. Função pura, sem árvore e sem janela: o que o teste conta é o que `BossImpact` desenha.

enum Kind { FLAKE, SMOKE, SPARK }

const FLASH_REACH: Dictionary[int, float] = {
	SkillFxData.ImpactStyle.ARC: 8.0,
	SkillFxData.ImpactStyle.SCYTHE: 10.0,
	SkillFxData.ImpactStyle.FRACTURE: 12.0,
	SkillFxData.ImpactStyle.STAKES: 18.0,
	SkillFxData.ImpactStyle.CROWN: 28.0,
}
const FLASH_LIFE_DEFAULT := 0.3
const FLASH_LIFE_ARC := 0.1
const FLASH_LIFE_CROWN := 0.45
const FLASH_HEIGHT := 1.0

const SLAM_CRACKS := 7
const SLAM_CRACK_PHASE := 0.31
const SLAM_REACH := 8.4
const SLAM_STAKES := 14
const CROWN_CRACKS := 11
const CROWN_CRACK_PHASE := 0.17
const CROWN_REACH := 16.4
const CROWN_INNER_STAKES := 20
const CROWN_STAKES := 24
const CROWN_RADIUS := 15.0
const STAKE_ROWS := 11
const SEED := 20221108
## Largura das rachaduras. A ordem pede 0,22 m afinando para 0,05; no render a 7 e 14 m isso some no piso de
## gelo rachado da sala, então ficam 0,34 m e 0,10 m (ver o relatório da OS-022).
const CRACK_WIDTH_START := 0.34
const CRACK_WIDTH_END := 0.10


class Stake:
	extends RefCounted
	var position := Vector3.ZERO
	var height: float = 1.0
	var base_radius: float = 0.3
	var lean_direction := Vector3.FORWARD
	var lean: float = 0.0
	var delay: float = 0.0
	var rise: float = 0.1
	var hold: float = 0.5
	var sink: float = 0.2

	func lifetime() -> float:
		return delay + rise + hold + sink


class Crack:
	extends RefCounted
	## Pontos (x, z) relativos à origem.
	var points := PackedVector2Array()
	var width_start: float = CRACK_WIDTH_START
	var width_end: float = CRACK_WIDTH_END


class Ring:
	extends RefCounted
	var max_radius: float = 8.4
	var grow_time: float = 0.38
	var thickness: float = 0.5
	var zigzag: float = 0.5
	var teeth: int = 28


class Crescent:
	extends RefCounted
	var half_angle: float = 0.9
	var radius_from: float = 5.5
	var radius_to: float = 5.5
	var grow_time: float = 0.25
	var width: float = 0.45
	var height: float = 0.2
	var additive: bool = true
	var color_override := Color(0.0, 0.0, 0.0, 0.0)
	var alpha: float = 0.55
	var fade_time: float = 0.25
	## Segundos até começar a sumir.
	var fade_start: float = 0.3


class Burst:
	extends RefCounted
	var kind: Kind = Kind.FLAKE
	var position := Vector3.ZERO
	var amount: int = 8
	var delay: float = 0.0
	var speed: float = 5.0
	var radius: float = 0.2


var style: SkillFxData.ImpactStyle = SkillFxData.ImpactStyle.NONE
var origin := Vector3.ZERO
var forward := Vector3.FORWARD
var duration: float = 0.5
var stakes: Array[Stake] = []
var cracks: Array[Crack] = []
var rings: Array[Ring] = []
var crescents: Array[Crescent] = []
var bursts: Array[Burst] = []
var flash_position := Vector3.ZERO
var flash_energy: float = 0.0
var flash_reach: float = 0.0
var flash_life: float = FLASH_LIFE_DEFAULT


func particle_count() -> int:
	var total: int = 0
	for burst in bursts:
		total += burst.amount
	return total


func mesh_count() -> int:
	return stakes.size() + cracks.size() + rings.size() + crescents.size()


func light_count() -> int:
	return 1 if flash_energy > 0.0 else 0


## Maior tempo de vida entre as peças, para liberar os nós.
func longest_life() -> float:
	var longest: float = duration
	for stake in stakes:
		longest = maxf(longest, stake.lifetime())
	for burst in bursts:
		longest = maxf(longest, burst.delay + 2.0)
	return longest


static func build(fx: SkillFxData, origin_point: Vector3, aim_direction: Vector3, scale_override: float = -1.0) -> ImpactPlan:
	var plan := ImpactPlan.new()
	plan.style = fx.impact_style
	plan.origin = origin_point
	plan.forward = Vector3(aim_direction.x, 0.0, aim_direction.z).normalized() if Vector2(aim_direction.x, aim_direction.z).length_squared() > 0.0001 else Vector3.FORWARD
	plan.duration = fx.impact_duration
	var impact_scale: float = fx.impact_scale if scale_override < 0.0 else scale_override
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + int(fx.impact_style)
	match fx.impact_style:
		SkillFxData.ImpactStyle.ARC:
			plan._build_arc()
		SkillFxData.ImpactStyle.SCYTHE:
			plan._build_scythe(impact_scale)
		SkillFxData.ImpactStyle.FRACTURE:
			plan._build_fracture(rng, impact_scale)
		SkillFxData.ImpactStyle.STAKES:
			plan._build_stakes(impact_scale)
		SkillFxData.ImpactStyle.CROWN:
			plan._build_crown(rng, impact_scale)
	plan.flash_energy = fx.flash_energy
	plan.flash_reach = FLASH_REACH.get(fx.impact_style, 10.0)
	plan.flash_life = FLASH_LIFE_ARC if fx.impact_style == SkillFxData.ImpactStyle.ARC else (FLASH_LIFE_CROWN if fx.impact_style == SkillFxData.ImpactStyle.CROWN else FLASH_LIFE_DEFAULT)
	var around_boss: bool = fx.impact_style in [SkillFxData.ImpactStyle.FRACTURE, SkillFxData.ImpactStyle.CROWN]
	var sweep: float = plan._sweep_reach()
	plan.flash_position = origin_point + (Vector3.ZERO if around_boss else plan.forward * sweep * 0.5) + Vector3.UP * FLASH_HEIGHT
	return plan


## Alcance do cone ou da linha, para centrar o clarão: o do cone e o da linha vêm das próprias peças.
func _sweep_reach() -> float:
	match style:
		SkillFxData.ImpactStyle.ARC:
			return 5.5
		SkillFxData.ImpactStyle.SCYTHE:
			return 9.0
		SkillFxData.ImpactStyle.STAKES:
			return 22.0
	return 0.0


func _ground(distance: float, angle_from_forward: float = 0.0) -> Vector3:
	var direction: Vector3 = forward.rotated(Vector3.UP, -angle_from_forward)
	return origin + direction * distance


func _stake(position: Vector3, height: float, base_radius: float, outward: Vector3, lean: float, delay: float, rise: float, hold: float, sink: float) -> void:
	var stake := Stake.new()
	stake.position = position
	stake.height = height
	stake.base_radius = base_radius
	stake.lean_direction = outward
	stake.lean = lean
	stake.delay = delay
	stake.rise = rise
	stake.hold = hold
	stake.sink = sink
	stakes.append(stake)


func _burst(kind: Kind, position: Vector3, amount: int, speed: float, radius: float = 0.2, delay: float = 0.0) -> void:
	var burst := Burst.new()
	burst.kind = kind
	burst.position = position
	burst.amount = amount
	burst.speed = speed
	burst.radius = radius
	burst.delay = delay
	bursts.append(burst)


func _build_arc() -> void:
	var arc := Crescent.new()
	arc.half_angle = deg_to_rad(50.0)
	arc.radius_from = 5.5 * 0.7
	arc.radius_to = 5.5
	arc.grow_time = 0.1
	arc.width = 0.45
	arc.height = 2.0
	arc.alpha = 0.55
	arc.fade_time = duration
	arc.fade_start = 0.0
	crescents.append(arc)
	_burst(Kind.FLAKE, origin + forward * 3.5 + Vector3.UP * 2.0, 8, 5.0, 0.6)


func _build_scythe(impact_scale: float) -> void:
	var core := Crescent.new()
	core.half_angle = deg_to_rad(60.0)
	core.radius_from = 1.5
	core.radius_to = 9.0
	core.grow_time = 0.30
	core.width = 1.2
	core.height = 0.2
	core.fade_time = 0.25
	core.fade_start = 0.30
	core.color_override = Color("BFF4FF")
	core.alpha = 0.8
	crescents.append(core)
	var under := Crescent.new()
	under.half_angle = core.half_angle
	under.radius_from = core.radius_from
	under.radius_to = core.radius_to
	under.grow_time = core.grow_time
	under.width = 1.6
	under.height = 0.17
	under.additive = false
	under.color_override = Color("1E4F86")
	under.alpha = 0.45
	under.fade_time = core.fade_time
	under.fade_start = core.fade_start
	crescents.append(under)
	var heights: Array[float] = [1.4, 1.7, 2.0, 1.7, 1.4]
	var flakes: Array[int] = [5, 5, 4, 5, 5]
	for i in 5:
		var angle: float = deg_to_rad((i - 2) * 24.0)
		var foot: Vector3 = _ground(8.6, angle)
		_stake(foot, heights[i] * impact_scale, 0.3, (foot - origin).normalized(), 0.25, 0.0, 0.10, 0.30, 0.15)
		_burst(Kind.FLAKE, foot + Vector3.UP * 0.4, flakes[i], 4.0, 0.3)
	for i in 3:
		_burst(Kind.SMOKE, _ground(6.0, deg_to_rad((i - 1) * 24.0)) + Vector3.UP * 0.2, 4, 1.2, 0.5)


## Rachaduras, anel serrilhado, estacas e poeira. Serve ao slam e, em escala de sala, à nova.
func _fracture_layer(rng: RandomNumberGenerator, crack_count: int, phase: float, reach: float, ring_time: float, ring_thickness: float, ring_zigzag: float, ring_teeth: int) -> void:
	for i in crack_count:
		var angle: float = float(i) * TAU / float(crack_count) + phase
		var direction := Vector2(cos(angle), sin(angle))
		var side := Vector2(-direction.y, direction.x)
		var crack := Crack.new()
		crack.points.append(Vector2.ZERO)
		for step in range(1, 7):
			var along: float = reach * float(step) / 6.0
			var deviation: float = 0.0 if step == 6 else rng.randf_range(-0.35, 0.35)
			crack.points.append(direction * along + side * deviation)
		cracks.append(crack)
	var ring := Ring.new()
	ring.max_radius = reach
	ring.grow_time = ring_time
	ring.thickness = ring_thickness
	ring.zigzag = ring_zigzag
	ring.teeth = ring_teeth
	rings.append(ring)


func _scatter_stakes(rng: RandomNumberGenerator, count: int, inner: float, outer: float, low: float, high: float, impact_scale: float) -> void:
	for i in count:
		var angle: float = float(i) * 2.39996 + rng.randf_range(-0.2, 0.2)
		var distance: float = inner + (outer - inner) * sqrt((float(i) + 0.5) / float(count))
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var height: float = rng.randf_range(low, high) * impact_scale
		_stake(origin + direction * distance, height, 0.32, direction, rng.randf_range(0.0, 0.3), distance / outer * 0.15, 0.10, 0.55, 0.30)


func _ring_dust(smoke: int, sparks: int, radius: float, smoke_groups: int, spark_groups: int, smoke_rise: float) -> void:
	for i in smoke_groups:
		var angle: float = TAU * float(i) / float(smoke_groups)
		_burst(Kind.SMOKE, origin + Vector3(cos(angle), 0.2, sin(angle)) * radius, smoke / smoke_groups, smoke_rise, 1.0, float(i) * 0.02)
	for i in spark_groups:
		var angle: float = TAU * (float(i) + 0.5) / float(spark_groups)
		_burst(Kind.SPARK, origin + Vector3(cos(angle), 0.4, sin(angle)) * radius * 0.7, sparks / spark_groups, 4.0, 0.4)


func _build_fracture(rng: RandomNumberGenerator, impact_scale: float) -> void:
	_fracture_layer(rng, SLAM_CRACKS, SLAM_CRACK_PHASE, SLAM_REACH, 0.38, 0.5, 0.5, 28)
	_scatter_stakes(rng, SLAM_STAKES, 2.0, 7.4, 0.9, 2.2, impact_scale)
	_ring_dust(36, 20, 5.0, 12, 4, 0.5)


func _build_stakes(impact_scale: float) -> void:
	for row in 2:
		var side: float = -0.9 if row == 0 else 0.9
		var shift: float = 0.0 if row == 0 else 0.95
		for i in STAKE_ROWS:
			var distance: float = 1.5 + float(i) * 1.9 + shift
			var height: float = lerpf(2.0, 3.6, float(i) / float(STAKE_ROWS - 1)) * impact_scale
			var lateral: Vector3 = forward.cross(Vector3.UP) * side
			var foot: Vector3 = origin + forward * distance + lateral
			_stake(foot, height, 0.28, lateral.normalized(), 0.12, float(i) * 0.04 + (0.02 if row == 1 else 0.0), 0.08, 0.5, 0.22)
			if row == 0 and i % 2 == 0:
				_burst(Kind.FLAKE, foot + Vector3.UP * 0.4, 8, 4.0, 0.4, float(i) * 0.04)


func _build_crown(rng: RandomNumberGenerator, impact_scale: float) -> void:
	_fracture_layer(rng, CROWN_CRACKS, CROWN_CRACK_PHASE, CROWN_REACH, 0.55, 0.8, 0.8, 48)
	_scatter_stakes(rng, CROWN_INNER_STAKES, 2.0, 14.0, 1.2, 2.8, 1.0)
	for i in CROWN_STAKES:
		var angle: float = TAU * float(i) / float(CROWN_STAKES)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var height: float = (3.0 if i % 2 == 0 else 4.6) * impact_scale
		_stake(origin + direction * CROWN_RADIUS, height, 0.45, direction, 0.22, float(i) * 0.02, 0.14, 0.8, 0.5)
	_ring_dust(60, 40, 8.0, 20, 8, 0.5)
