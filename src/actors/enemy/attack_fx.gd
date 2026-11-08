class_name AttackFx
extends Node3D
## Efeitos de ataque de um inimigo com `SkillData.fx` (OS-022): sinal do preparo, impacto e tremor.
## Nasce como filho do `Enemy` só quando alguma habilidade dele tem `fx`. Liga nos sinais locais do `SkillCaster`.
## O cálculo (curvas, atrasos, contagens) são funções estáticas puras; o desenho passa por `Vfx` e `BossImpact`,
## que não fazem nada sem janela. Nunca conhece o jogador: o tremor sai por `Events.camera_shake_requested`.

enum State { IDLE, PREP, FADE }

const FADE_FIRED := 0.4
const FADE_INTERRUPTED := 0.2
const EMITTER_FADE := 0.15
const SHAKE_INTERVAL := 0.5

## Brilho do repouso dos cristais do chefe, lido do material quando existe (regra N3 do guia).
const DEFAULT_BASE_GLOW: Dictionary[StringName, float] = {&"blade_material": 1.5, &"core_material": 2.4, &"crown_material": 2.0}
const CORE_BLADE_PEAK := 4.0
const WINTER_CROWN_PEAK := 5.0
const WINTER_BLADE_PEAK := 4.0

const GLINT_SIZE := 0.45
const GLINT_SCALE_FROM := 0.6
const GLINT_SCALE_TO := 1.4
const SHARD_LENGTHS: Array[float] = [0.5, 0.4, 0.35]
const SHARD_RADIUS := 0.07
const SHARD_ORBIT_RADIUS := 0.35
const SHARD_ORBIT_SPEED := 2.0
const SHARD_GROW_FROM := 0.2
const SHARD_GROW_TO := 0.9
const FOG_RING_RADIUS := 2.4
const WINTER_RING_RADIUS := 16.0
## Convergência da nova (Revisão 2): velocidade inicial e aceleração para o centro das lascas (m/s e m/s²).
const CONVERGENCE_SPEED := 4.0
const CONVERGENCE_PULL := 3.0
const CORE_LIGHT: Array[float] = [1.2, 9.0]
const WINTER_LIGHT: Array[float] = [2.5, 18.0]

var _enemy: Enemy
var _caster: SkillCaster
var _fx: SkillFxData
var _state: State = State.IDLE
var _progress: float = 0.0
var _fade_left: float = 0.0
var _fade_total: float = 1.0
var _fade_from: float = 0.0
var _shake_clock: float = 0.0
var _bases: Dictionary[StringName, float] = {}
var _glint: MeshInstance3D
var _shards: Array[MeshInstance3D] = []
var _motes: GPUParticles3D
var _motes_anchored: bool = false
var _convergence: ConvergenceShards
var _cast_duration: float = 1.0
var _light: OmniLight3D
var _orbit: float = 0.0


## Habilidades do inimigo, incluindo as das fases do chefe.
static func collect_skills(monster: MonsterData) -> Array[SkillData]:
	var result: Array[SkillData] = monster.skills.duplicate()
	for phase in monster.phases:
		for skill in phase.skills:
			if not result.has(skill):
				result.append(skill)
	return result


static func wants_fx(skills: Array[SkillData]) -> bool:
	for skill in skills:
		if skill.fx != null:
			return true
	return false


## Cria o `AttackFx` no inimigo se alguma habilidade dele tem `fx`. O critério é o dado, não o tier.
static func attach(enemy: Enemy) -> AttackFx:
	if not wants_fx(collect_skills(enemy.data)):
		return null
	var attack_fx := AttackFx.new()
	attack_fx.name = "AttackFx"
	enemy.add_child(attack_fx)
	attack_fx.setup(enemy)
	return attack_fx


# --- Cálculo puro ---

## Brilho do cristal em `progress` (0 a 1): `base + (peak - base) * p^2`.
static func glow_at(base: float, peak: float, progress: float) -> float:
	var p: float = clampf(progress, 0.0, 1.0)
	return base + (peak - base) * p * p


## Pico de brilho por meta do rig para o estilo de preparo (seção 4).
static func glow_peaks(fx: SkillFxData) -> Dictionary[StringName, float]:
	var peaks: Dictionary[StringName, float] = {}
	match fx.prep_style:
		SkillFxData.PrepStyle.BLADE, SkillFxData.PrepStyle.TIP_CRYSTALS:
			peaks[&"blade_material"] = fx.prep_peak
		SkillFxData.PrepStyle.CORE:
			peaks[&"core_material"] = fx.prep_peak
			peaks[&"blade_material"] = CORE_BLADE_PEAK
		SkillFxData.PrepStyle.WINTER:
			peaks[&"core_material"] = fx.prep_peak
			peaks[&"crown_material"] = WINTER_CROWN_PEAK
			peaks[&"blade_material"] = WINTER_BLADE_PEAK
	return peaks


## Brilho de uma meta em `progress`, com o repouso `base`.
static func glow_for(fx: SkillFxData, meta: StringName, base: float, progress: float) -> float:
	var peaks: Dictionary[StringName, float] = glow_peaks(fx)
	return glow_at(base, peaks[meta], progress) if peaks.has(meta) else base


static func glint_scale(progress: float) -> float:
	return lerpf(GLINT_SCALE_FROM, GLINT_SCALE_TO, clampf(progress, 0.0, 1.0))


## Escala das lascas que orbitam a ponta: 0 até `p` 0,2 e 1 a partir de 0,9.
static func shard_scale(progress: float) -> float:
	return clampf((progress - SHARD_GROW_FROM) / (SHARD_GROW_TO - SHARD_GROW_FROM), 0.0, 1.0)


## Luz de preparo: [energia máxima, alcance] por estilo; vazio quando o estilo não tem luz.
static func prep_light(fx: SkillFxData) -> Array[float]:
	match fx.prep_style:
		SkillFxData.PrepStyle.CORE:
			return CORE_LIGHT
		SkillFxData.PrepStyle.WINTER:
			return WINTER_LIGHT
	var none: Array[float] = []
	return none


static func prep_light_energy(fx: SkillFxData, progress: float) -> float:
	var light: Array[float] = prep_light(fx)
	return light[0] * clampf(progress, 0.0, 1.0) if not light.is_empty() else 0.0


## Contagens de um ataque para o orçamento da seção 6.
static func budget(fx: SkillFxData) -> Dictionary:
	var plan: ImpactPlan = ImpactPlan.build(fx, Vector3.ZERO, Vector3.FORWARD) if fx.impact_style != SkillFxData.ImpactStyle.NONE else ImpactPlan.new()
	var prep_meshes: int = 0
	match fx.prep_style:
		SkillFxData.PrepStyle.BLADE:
			prep_meshes = 1
		SkillFxData.PrepStyle.TIP_CRYSTALS:
			prep_meshes = SHARD_LENGTHS.size()
		SkillFxData.PrepStyle.WINTER:
			prep_meshes = fx.prep_motes
	return {
		"prep_particles": 0 if fx.prep_style == SkillFxData.PrepStyle.WINTER else fx.prep_motes,
		"impact_particles": plan.particle_count(),
		"impact_meshes": plan.mesh_count(),
		"prep_meshes": prep_meshes,
		"lights": plan.light_count() + (0 if prep_light(fx).is_empty() else 1),
	}


# --- Ligação ---

func setup(enemy: Enemy) -> void:
	_enemy = enemy
	_caster = enemy.caster
	_caster.cast_started.connect(_on_cast_started)
	_caster.cast_interrupted.connect(_on_cast_interrupted)
	_caster.skill_fired.connect(_on_skill_fired)
	_make_convergence()
	_warm_up()


## A convergência da nova só existe em quem tem preparo `WINTER`. O conjunto de nós nasce junto (com janela).
func _make_convergence() -> void:
	for skill in collect_skills(_enemy.data):
		if skill.fx != null and skill.fx.prep_style == SkillFxData.PrepStyle.WINTER:
			_convergence = ConvergenceShards.new()
			add_child(_convergence)
			_convergence.prepare(_effect_color(skill.fx))
			return


## Cria de antemão as malhas e os materiais que os impactos reaproveitam: o quadro do golpe não paga por eles.
func _warm_up() -> void:
	if not Vfx.enabled():
		return
	for skill in collect_skills(_enemy.data):
		if skill.fx != null and skill.fx.impact_style != SkillFxData.ImpactStyle.NONE:
			var plan: ImpactPlan = ImpactPlan.build(skill.fx, Vector3.ZERO, Vector3.FORWARD)
			BossImpact.prepare(plan, _effect_color(skill.fx))


func _on_cast_started(skill: SkillData, duration: float) -> void:
	if skill.fx == null or skill.fx.prep_style == SkillFxData.PrepStyle.NONE:
		return
	if _state != State.IDLE:
		_finish()
	_fx = skill.fx
	_cast_duration = duration
	_state = State.PREP
	_progress = 0.0
	_shake_clock = 0.0
	_bases.clear()
	for meta: StringName in glow_peaks(_fx):
		_bases[meta] = _material_glow(meta)
	_build_prep_nodes()
	if _convergence != null and _fx.prep_style == SkillFxData.PrepStyle.WINTER:
		_convergence.begin(duration)


func _on_cast_interrupted(_skill: SkillData) -> void:
	_begin_fade(FADE_INTERRUPTED)


func _on_skill_fired(skill: SkillData, aim: SkillAim) -> void:
	if _state == State.PREP and skill.fx == _fx:
		_begin_fade(FADE_FIRED)
	if skill.fx == null or skill.fx.impact_style == SkillFxData.ImpactStyle.NONE:
		return
	var origin: Vector3 = _enemy.global_position
	var direction: Vector3 = aim.direction
	if skill.fx.impact_delay > 0.0:
		await get_tree().create_timer(skill.fx.impact_delay, false).timeout
	if not is_inside_tree():
		return
	_impact(skill.fx, origin, direction)


func _impact(fx: SkillFxData, origin: Vector3, direction: Vector3) -> void:
	var plan: ImpactPlan = ImpactPlan.build(fx, origin, direction)
	BossImpact.draw(get_tree(), plan, _effect_color(fx))
	if fx.shake_strength > 0.0:
		Events.camera_shake_requested.emit(origin, fx.shake_strength, fx.shake_radius)


## Cor dos efeitos: `impact_color` com alfa, ou o `enemy_glow` do tema.
static func effect_color(fx: SkillFxData, theme_glow: Color) -> Color:
	return fx.impact_color if fx.impact_color.a > 0.0 else theme_glow


func _effect_color(fx: SkillFxData) -> Color:
	return effect_color(fx, _enemy.glow)


func _begin_fade(seconds: float) -> void:
	if _state != State.PREP:
		return
	_state = State.FADE
	if _convergence != null:
		_convergence.clear()
	_fade_from = _progress
	_fade_total = seconds
	_fade_left = seconds


# --- Preparo ---

func _material_glow(meta: StringName) -> float:
	var material := _enemy.rig.get_meta(meta, null) as ShaderMaterial
	if material != null:
		var value: Variant = material.get_shader_parameter("glow")
		if value is float:
			return value
	return DEFAULT_BASE_GLOW.get(meta, 1.0)


func _set_material_glow(meta: StringName, value: float) -> void:
	var material := _enemy.rig.get_meta(meta, null) as ShaderMaterial
	if material != null:
		material.set_shader_parameter("glow", value)


func _apply_prep_glow(progress: float) -> void:
	for meta: StringName in _bases:
		_set_material_glow(meta, glow_for(_fx, meta, _bases[meta], progress))


func _anchor() -> Node3D:
	if _enemy.rig.has_joint(_fx.prep_anchor):
		return _enemy.rig.get_joint(_fx.prep_anchor)
	return _enemy


func _glow_color() -> Color:
	return _effect_color(_fx)


func _build_prep_nodes() -> void:
	if not Vfx.enabled():
		return
	var glow: Color = _glow_color()
	match _fx.prep_style:
		SkillFxData.PrepStyle.BLADE:
			_glint = Vfx.glint(self, glow.lightened(0.4), GLINT_SIZE)
			_motes = _build_motes(glow, true)
		SkillFxData.PrepStyle.TIP_CRYSTALS:
			_build_shards(glow)
			_motes = _build_motes(glow, true)
		SkillFxData.PrepStyle.CORE:
			_motes = _build_fog()
			_light = _build_light(glow)
		SkillFxData.PrepStyle.WINTER:
			_light = _build_light(glow)


## Emissores do preparo. Funções puras, na cor do tema.
static func motes_spec(fx: SkillFxData, glow: Color) -> EmitterSpec:
	var spec := EmitterSpec.new()
	spec.amount = fx.prep_motes
	spec.lifetime = 0.7
	spec.size = 0.16
	spec.color = glow.lightened(0.4)
	spec.shape_radius = 0.25
	spec.speed_min = 0.6
	spec.speed_max = 1.4
	return spec


static func fog_spec(fx: SkillFxData) -> EmitterSpec:
	var spec := EmitterSpec.new()
	spec.amount = fx.prep_motes
	spec.lifetime = 1.2
	spec.sprite = ParticleKit.SMOKE
	spec.additive = false
	spec.size = BossImpact.SMOKE_SIZE
	spec.scale_start = BossImpact.SMOKE_SCALE_START
	spec.scale_end = BossImpact.SMOKE_SCALE_END
	spec.color = BossImpact.SMOKE_COLOR
	spec.shape = EmitterSpec.Shape.RING
	spec.shape_radius = FOG_RING_RADIUS
	spec.direction = Vector3.UP
	spec.spread = 10.0
	spec.speed_min = 0.5
	spec.speed_max = 0.5
	return spec


func _build_motes(glow: Color, at_anchor: bool) -> GPUParticles3D:
	if _fx.prep_motes <= 0:
		return null
	_motes_anchored = at_anchor
	return Vfx.emitter(self, motes_spec(_fx, glow))


func _build_fog() -> GPUParticles3D:
	_motes_anchored = false
	return Vfx.emitter(self, fog_spec(_fx))


func _build_light(glow: Color) -> OmniLight3D:
	var settings: Array[float] = prep_light(_fx)
	var light := OmniLight3D.new()
	light.light_color = glow.lightened(0.35)
	light.light_energy = 0.0
	light.omni_range = settings[1]
	light.shadow_enabled = false
	add_child(light)
	return light


func _build_shards(glow: Color) -> void:
	var material: Material = DungeonMaterials.crystal(glow.darkened(0.45), glow.lightened(0.35), 2.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for length in SHARD_LENGTHS:
		var shard := MeshInstance3D.new()
		shard.mesh = MeshKit.shard(SHARD_RADIUS, length, rng, 4, 0.0)
		shard.material_override = material
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.scale = Vector3.ONE * 0.001
		add_child(shard)
		_shards.append(shard)


func _process(delta: float) -> void:
	if _state == State.IDLE or _fx == null:
		return
	var emitter_ratio: float = 1.0
	if _state == State.PREP and not _caster.is_casting():
		# O conjurador foi reiniciado (`reset_all`) sem emitir `cast_interrupted`: o preparo acabou.
		_begin_fade(FADE_INTERRUPTED)
	if _state == State.PREP:
		_progress = _caster.cast_progress()
		_shake_clock += delta
		if _fx.prep_shake > 0.0 and _shake_clock >= SHAKE_INTERVAL:
			_shake_clock -= SHAKE_INTERVAL
			Events.camera_shake_requested.emit(_enemy.global_position, _fx.prep_shake, _fx.shake_radius)
	else:
		_fade_left -= delta
		if _fade_left <= 0.0:
			_finish()
			return
		_progress = _fade_from * _fade_left / _fade_total
		emitter_ratio = clampf(_fade_left / minf(EMITTER_FADE, _fade_total), 0.0, 1.0) * _fade_from
	_apply_prep_glow(_progress)
	_orbit += delta * SHARD_ORBIT_SPEED
	if _convergence != null and _state == State.PREP:
		_convergence.update(_enemy.global_position, _progress * _cast_duration)
	_update_prep_nodes(emitter_ratio if _state == State.FADE else _progress)


func _update_prep_nodes(ratio: float) -> void:
	if not Vfx.enabled():
		return
	var anchor_position: Vector3 = _anchor().global_position
	if _glint != null:
		_glint.global_position = anchor_position
		_glint.scale = Vector3.ONE * glint_scale(_progress)
	for i in _shards.size():
		var angle: float = _orbit + TAU * float(i) / float(_shards.size())
		_shards[i].global_position = anchor_position + Vector3(cos(angle), 0.0, sin(angle)) * SHARD_ORBIT_RADIUS
		_shards[i].scale = Vector3.ONE * maxf(shard_scale(_progress), 0.001)
	if _motes != null:
		_motes.global_position = anchor_position if _motes_anchored else _enemy.global_position
		_motes.amount_ratio = clampf(ratio, 0.01, 1.0)
	if _light != null:
		_light.global_position = anchor_position
		_light.light_energy = prep_light_energy(_fx, _progress)


func _finish() -> void:
	for meta: StringName in _bases:
		_set_material_glow(meta, _bases[meta])
	_end_prep_nodes()
	_state = State.IDLE


func _end_prep_nodes() -> void:
	for node: Node in [_glint, _motes, _light]:
		if is_instance_valid(node):
			node.queue_free()
	for shard in _shards:
		if is_instance_valid(shard):
			shard.queue_free()
	if _convergence != null:
		_convergence.clear()
	_shards.clear()
	_glint = null
	_motes = null
	_light = null
