class_name BossImpact
extends RefCounted
## Desenha o `ImpactPlan` de um ataque do chefe (OS-022, seção 5). Sem janela, não cria nada.
## Tudo vive sob um nó único, liberado ao fim da vida da peça mais longa: nada se acumula.

const CRACK_DARK := Color("0A1626")
const CRACK_DARK_ALPHA := 0.85
const CRACK_GROW := 0.18
const CRACK_THREAD_LIFE := 0.4
const CRACK_FADE := 0.5
## Fio aceso: a ordem pede 0,06 m; 0,10 m e energia 1,6 para ler a 14 m (ver ImpactPlan.CRACK_WIDTH_START).
const CRACK_THREAD_WIDTH := 0.10
const CRACK_THREAD_ENERGY := 1.6
const RING_START_RADIUS := 0.5
const RING_ALPHA := 0.45
const GROUND_LIFT := 0.06
## Poeira: véu baixo, não bola. Sprite de 0,9 m com escala de 0,8 a 1,4 (0,72 a 1,26 m), alfa de pico 0,30 (OS-022, Revisão 1).
const SMOKE_COLOR := Color(0.91, 0.957, 1.0, 0.30)
const SMOKE_SIZE := 0.9
const SMOKE_SCALE_START := 0.8
const SMOKE_SCALE_END := 1.4


## Cria de antemão o que o impacto reaproveita (malhas, materiais de partículas, cristal), para o quadro do golpe
## não pagar por isso. Chamado quando o inimigo nasce. Sem janela, não faz nada.
static func prepare(plan: ImpactPlan, glow: Color) -> void:
	if not Vfx.enabled():
		return
	var colors: Array[Color] = crystal_colors(glow)
	DungeonMaterials.crystal(colors[0], colors[1], 2.0)
	for slot in [["crack_dark", false], ["crack_thread", true], ["ring", true], ["crescent_add", true], ["crescent_mix", false]]:
		Vfx.warm_material(Vfx.slot_material(slot[0], Color.WHITE, slot[1]))
	Vfx.warm_material(Vfx.glint_material(Color.WHITE))
	Vfx.stake_mesh()
	for crack in plan.cracks:
		Vfx.crack_mesh(crack.points, crack.width_start, crack.width_end, CRACK_THREAD_WIDTH)
	for ring in plan.rings:
		Vfx.jagged_ring_mesh(ring.teeth, ring.thickness / ring.max_radius, ring.zigzag / ring.max_radius)
	for crescent in plan.crescents:
		Vfx.crescent_mesh(crescent.half_angle, crescent.width / crescent.radius_to)
	for burst in plan.bursts:
		var spec: EmitterSpec = burst_spec(burst, glow)
		Vfx.emitter_material(spec)
		Vfx.emitter_quad(spec)


static func draw(tree: SceneTree, plan: ImpactPlan, glow: Color) -> void:
	if not Vfx.enabled():
		return
	var root_node: Node3D = CombatWorld.root(tree)
	if root_node == null:
		return
	var holder := Node3D.new()
	holder.name = "BossImpact"
	root_node.add_child(holder)
	holder.global_position = plan.origin
	var colors: Array[Color] = crystal_colors(glow)
	var crystal: Material = DungeonMaterials.crystal(colors[0], colors[1], 2.0)
	for stake in plan.stakes:
		Vfx.stake(holder, stake.position, stake.height, stake.base_radius, stake.lean_direction, stake.lean, crystal, stake.delay, stake.rise, stake.hold, stake.sink)
	_draw_cracks(holder, plan, glow)
	for ring in plan.rings:
		_draw_ring(holder, plan, ring, glow)
	for crescent in plan.crescents:
		_draw_crescent(holder, plan, crescent, glow)
	for burst in plan.bursts:
		_draw_burst(tree, holder, burst, glow)
	Vfx.flash_light(tree, plan.flash_position, glow.lightened(0.35), plan.flash_energy, plan.flash_reach, plan.flash_life)
	tree.create_timer(plan.longest_life() + 0.4, false).timeout.connect(func() -> void:
		if is_instance_valid(holder):
			holder.queue_free())


static func _draw_cracks(holder: Node3D, plan: ImpactPlan, glow: Color) -> void:
	if plan.cracks.is_empty():
		return
	var dark: StandardMaterial3D = Vfx.slot_material("crack_dark", Color(CRACK_DARK, CRACK_DARK_ALPHA), false)
	var thread: StandardMaterial3D = Vfx.slot_material("crack_thread", Color(glow.r * CRACK_THREAD_ENERGY, glow.g * CRACK_THREAD_ENERGY, glow.b * CRACK_THREAD_ENERGY, 1.0), true)
	var group := Node3D.new()
	holder.add_child(group)
	group.global_position = plan.origin + Vector3.UP * GROUND_LIFT
	group.scale = Vector3(0.02, 1.0, 0.02)
	for crack in plan.cracks:
		Vfx.crack(group, group.global_position, crack.points, crack.width_start, crack.width_end, CRACK_THREAD_WIDTH, dark, thread)
	group.create_tween().tween_property(group, "scale", Vector3.ONE, CRACK_GROW).set_ease(Tween.EASE_OUT)
	Vfx.fade_slot("crack_thread", group, 0.1, CRACK_THREAD_LIFE)
	Vfx.fade_slot("crack_dark", group, CRACK_FADE, maxf(plan.duration - CRACK_FADE, CRACK_GROW))


static func _draw_ring(holder: Node3D, plan: ImpactPlan, ring: ImpactPlan.Ring, glow: Color) -> void:
	var material: StandardMaterial3D = Vfx.slot_material("ring", Color(glow.lightened(0.2), RING_ALPHA), true)
	var instance := MeshInstance3D.new()
	instance.mesh = Vfx.jagged_ring_mesh(ring.teeth, ring.thickness / ring.max_radius, ring.zigzag / ring.max_radius)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(instance)
	instance.global_position = plan.origin + Vector3.UP * (GROUND_LIFT + 0.04)
	instance.scale = Vector3(RING_START_RADIUS, 1.0, RING_START_RADIUS)
	instance.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(instance, "scale", Vector3(ring.max_radius, 1.0, ring.max_radius), ring.grow_time)
	Vfx.fade_slot("ring", instance, ring.grow_time + 0.04)


static func _draw_crescent(holder: Node3D, plan: ImpactPlan, crescent: ImpactPlan.Crescent, glow: Color) -> void:
	var color: Color = crescent.color_override if crescent.color_override.a > 0.0 else glow.lightened(0.15)
	if crescent.additive and crescent.color_override.a <= 0.0:
		color = Color(glow.r * 1.6, glow.g * 1.6, glow.b * 1.6)
	var slot: String = "crescent_add" if crescent.additive else "crescent_mix"
	var material: StandardMaterial3D = Vfx.slot_material(slot, Color(color, crescent.alpha), crescent.additive)
	var instance := MeshInstance3D.new()
	instance.mesh = Vfx.crescent_mesh(crescent.half_angle, crescent.width / crescent.radius_to)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(instance)
	instance.global_position = plan.origin + Vector3.UP * crescent.height
	instance.rotation.y = atan2(-plan.forward.x, -plan.forward.z)
	instance.scale = Vector3(crescent.radius_from, 1.0, crescent.radius_from)
	instance.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(instance, "scale", Vector3(crescent.radius_to, 1.0, crescent.radius_to), maxf(crescent.grow_time, 0.01))
	Vfx.fade_slot(slot, instance, crescent.fade_time, crescent.fade_start)


## Emissor de uma explosão do impacto, na cor do tema. Função pura, para os testes.
static func burst_spec(burst: ImpactPlan.Burst, glow: Color) -> EmitterSpec:
	var spec := EmitterSpec.new()
	spec.amount = burst.amount
	spec.one_shot = true
	spec.explosiveness = 0.95
	spec.shape_radius = burst.radius
	match burst.kind:
		ImpactPlan.Kind.FLAKE:
			spec.sprite = ParticleKit.FLAKE
			spec.size = 0.12
			spec.color = glow.lightened(0.3)
			spec.lifetime = 0.6
			spec.speed_min = burst.speed * 0.4
			spec.speed_max = burst.speed
			spec.gravity = Vector3(0.0, -6.0, 0.0)
			spec.damping = 2.0
		ImpactPlan.Kind.SPARK:
			spec.sprite = ParticleKit.SPARK
			spec.size = 0.18
			spec.color = glow.lightened(0.45)
			spec.lifetime = 0.7
			spec.speed_min = burst.speed * 0.4
			spec.speed_max = burst.speed
			spec.gravity = Vector3(0.0, -3.0, 0.0)
			spec.damping = 2.0
		ImpactPlan.Kind.SMOKE:
			spec.sprite = ParticleKit.SMOKE
			spec.additive = false
			spec.explosiveness = 0.5
			spec.size = SMOKE_SIZE
			spec.scale_start = SMOKE_SCALE_START
			spec.scale_end = SMOKE_SCALE_END
			spec.color = SMOKE_COLOR
			spec.lifetime = 1.2
			spec.direction = Vector3.UP
			spec.spread = 35.0
			spec.speed_min = burst.speed * 0.6
			spec.speed_max = burst.speed
			spec.damping = 0.5
	return spec


## Cores do cristal das estacas: (miolo, borda), derivadas do brilho do tema.
static func crystal_colors(glow: Color) -> Array[Color]:
	return [glow.darkened(0.45), glow.lightened(0.35)]


static func _draw_burst(tree: SceneTree, holder: Node3D, burst: ImpactPlan.Burst, glow: Color) -> void:
	var spec: EmitterSpec = burst_spec(burst, glow)
	var spawn := func() -> void:
		if not is_instance_valid(holder):
			return
		var particles: GPUParticles3D = Vfx.emitter(holder, spec)
		if particles != null:
			particles.global_position = burst.position
	if burst.delay <= 0.0:
		spawn.call()
	else:
		tree.create_timer(burst.delay, false).timeout.connect(spawn)
