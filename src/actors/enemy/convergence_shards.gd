class_name ConvergenceShards
extends Node3D
## Convergência do preparo da nova (OS-022, Revisão 2): lascas de gelo deitadas que descem da borda da zona até o
## chefe, uma fileira por raio. 7 raios (número ímpar, fase fixa: nenhum par a 90 ou 180 graus, regra O2).
## A contagem vem da cadência, não de um número fixo: cada raio solta uma lasca a cada `INTERVAL` entre 25% e 100%
## do preparo, com `RAY_OFFSET` de atraso entre um raio e o próximo. Tudo some no `skill_fired`.
## O cálculo é puro e testável sem janela; os nós (um conjunto reaproveitado) só existem com janela.

const RAYS := 7
const RAY_PHASE := 0.29
## Lascas por raio no máximo: define o tamanho do conjunto de nós.
const MAX_PER_RAY := 4
const START_RADIUS := 15.5
const LIFE := 1.9
const INTERVAL := 0.475
const WINDOW_START := 0.25
const RAY_OFFSET := 0.07
const HEIGHT := 0.30
## Quanto a ponta sobe do piso, em radianos. A ordem pedia 0 (deitada), mas de longe ela lia como pedrinha; a direção de arte aprovou 0,45 no fechamento da Revisão 2.
const TILT := 0.45
const GROW_TIME := 0.15
const SHRINK_TIME := 0.25
const SHARD_RADIUS := 0.07
const SHARD_LENGTH := 1.1
const CRYSTAL_GLOW := 3.0
const MESH_VARIATIONS := 3

static var _meshes: Array[ArrayMesh] = []

var _slot_ray := PackedInt32Array()
var _slot_time := PackedFloat32Array()
var _nodes: Array[MeshInstance3D] = []
var _alive: int = 0


# --- Cálculo puro ---

## Direção, no chão, do raio `index`.
static func ray_direction(index: int) -> Vector3:
	var angle: float = TAU * float(index) / float(RAYS) + RAY_PHASE
	return Vector3(cos(angle), 0.0, sin(angle))


## Distância ao chefe depois de `age` segundos de vida: `15,5 - (4,0·t + 0,5·3,0·t²)`.
static func radius_at(age: float) -> float:
	return START_RADIUS - (AttackFx.CONVERGENCE_SPEED * age + 0.5 * AttackFx.CONVERGENCE_PULL * age * age)


## Escala da lasca: de 0 a 1 nos primeiros 0,15 s e de 1 a 0 nos últimos 0,25 s da vida.
static func scale_at(age: float) -> float:
	if age < 0.0 or age >= LIFE:
		return 0.0
	return minf(minf(age / GROW_TIME, (LIFE - age) / SHRINK_TIME), 1.0)


## Instantes de nascimento, por raio, para um preparo de `cast_duration` segundos. Só nasce lasca até o disparo.
static func spawn_times(cast_duration: float) -> Array[PackedFloat32Array]:
	var rays: Array[PackedFloat32Array] = []
	for ray in RAYS:
		var times := PackedFloat32Array()
		for k in MAX_PER_RAY:
			var born: float = cast_duration * WINDOW_START + float(k) * INTERVAL + float(ray) * RAY_OFFSET
			if born <= cast_duration:
				times.append(born)
		rays.append(times)
	return rays


## Total de lascas de um preparo: o pico vivo, já que a vida (1,9 s) cobre o resto do preparo.
static func total(cast_duration: float) -> int:
	var count: int = 0
	for times in spawn_times(cast_duration):
		count += times.size()
	return count


static func crystal_colors(glow: Color) -> Array[Color]:
	return [glow.darkened(0.45), glow.lightened(0.35)]


## Orientação deitada: a base da malha (y local) aponta para o chefe, a lasca fica rente ao piso.
static func lying_basis(ray: int, scale_factor: float) -> Basis:
	var inward: Vector3 = -ray_direction(ray)
	var side: Vector3 = Vector3.UP.cross(inward).normalized()
	var tip: Vector3 = (inward * cos(TILT) + Vector3.UP * sin(TILT)).normalized()
	var down: Vector3 = side.cross(tip)
	return Basis(side, tip, down).scaled(Vector3.ONE * scale_factor)


static func _mesh(variation: int) -> ArrayMesh:
	if _meshes.is_empty():
		for i in MESH_VARIATIONS:
			var rng := RandomNumberGenerator.new()
			rng.seed = 31 + i
			_meshes.append(MeshKit.shard(SHARD_RADIUS, SHARD_LENGTH, rng, 4, 0.0))
	return _meshes[variation % MESH_VARIATIONS]


# --- Nós ---

## Cria de antemão o conjunto de nós e o material, para o preparo não pagar por eles. Sem janela, não cria nada.
func prepare(glow: Color) -> void:
	if not Vfx.enabled() or not _nodes.is_empty():
		return
	var colors: Array[Color] = crystal_colors(glow)
	var material: Material = DungeonMaterials.crystal(colors[0], colors[1], CRYSTAL_GLOW)
	Vfx.warm_material(material)
	for i in RAYS * MAX_PER_RAY:
		var shard := MeshInstance3D.new()
		shard.mesh = _mesh(i)
		shard.material_override = material
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.top_level = true
		shard.visible = false
		add_child(shard)
		_nodes.append(shard)


## Começa o preparo: marca os instantes de nascimento.
func begin(cast_duration: float) -> void:
	clear()
	var rays: Array[PackedFloat32Array] = spawn_times(cast_duration)
	for ray in rays.size():
		for born in rays[ray]:
			_slot_ray.append(ray)
			_slot_time.append(born)


## Atualiza as lascas vivas: `origin` é o chefe e `elapsed` os segundos desde o começo do preparo.
func update(origin: Vector3, elapsed: float) -> void:
	_alive = 0
	for i in _slot_ray.size():
		var age: float = elapsed - _slot_time[i]
		var alive: bool = age >= 0.0 and age < LIFE
		if alive:
			_alive += 1
		if i >= _nodes.size():
			continue
		var shard: MeshInstance3D = _nodes[i]
		shard.visible = alive
		if alive:
			var ray: int = _slot_ray[i]
			shard.global_transform = Transform3D(lying_basis(ray, scale_at(age)), origin + ray_direction(ray) * radius_at(age) + Vector3.UP * HEIGHT)


## Lascas vivas agora.
func alive_count() -> int:
	return _alive


## Tudo some: no `skill_fired` e no fim do preparo.
func clear() -> void:
	_slot_ray.clear()
	_slot_time.clear()
	_alive = 0
	for shard in _nodes:
		shard.visible = false
