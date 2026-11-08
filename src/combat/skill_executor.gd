class_name SkillExecutor
extends RefCounted
## Aplica o efeito de uma habilidade no mundo, conforme seu tipo de entrega.

const DASH_SPEED := 26.0


## `Events.skill_impacted` sai uma vez por conjuração em toda entrega de área, acerte ou não, e em projétil.
## Só a investida emite apenas quando acerta alguém. O ponto de impacto de cada entrega:
## cone e linha: no eixo da mira, a metade do alcance (centro da área varrida);
## área no chão: o ponto mirado; área no conjurador: a posição dele; projétil: onde acertou.
static func execute(skill: SkillData, caster: Combatant, aim: SkillAim) -> void:
	if skill.self_effect != null:
		caster.apply_effect(skill.self_effect, caster)
	match skill.delivery:
		SkillData.Delivery.MELEE_CONE:
			_melee_cone(skill, caster, aim)
		SkillData.Delivery.LINE:
			_line(skill, caster, aim)
		SkillData.Delivery.PROJECTILE:
			Projectile.launch(skill, caster, aim)
		SkillData.Delivery.GROUND_AOE:
			_ground_area(skill, caster, aim)
		SkillData.Delivery.SELF_AOE:
			_self_area(skill, caster)
		SkillData.Delivery.TARGET_ALLY:
			_heal_ally(skill, caster, aim.target)
		SkillData.Delivery.PARTY:
			_party(skill, caster)
		SkillData.Delivery.SELF_BUFF:
			pass
		SkillData.Delivery.DASH:
			_dash(skill, caster, aim)
		SkillData.Delivery.BLINK:
			_blink(skill, caster, aim)
		SkillData.Delivery.HEAL_ZONE:
			HealZone.spawn(skill, caster, aim.ground_point)


## Golpe em um alvo: dano, efeito e ganho de Chi. Usado por todos os tipos de entrega.
static func strike(skill: SkillData, caster: Combatant, target: Combatant) -> bool:
	if not is_instance_valid(target) or not target.is_alive():
		return false
	var hit: bool = true
	if skill.damage_kind != SkillData.DamageKind.NONE and skill.power > 0.0:
		hit = target.receive_hit(caster, skill)
	elif skill.threat_multiplier > 0.0:
		target.damaged.emit(0.0, caster, false, skill.threat_multiplier * 40.0)
	if hit and skill.target_effect != null:
		target.apply_effect(skill.target_effect, caster)
	return hit


static func _strike_all(skill: SkillData, caster: Combatant, targets: Array[Combatant]) -> bool:
	var landed: bool = false
	for target in targets:
		if strike(skill, caster, target):
			landed = true
			Vfx.hit_burst(caster.get_tree(), target.center_position(), skill.color)
	if landed:
		caster.add_chi(skill.chi_gain)
	return landed


static func _melee_cone(skill: SkillData, caster: Combatant, aim: SkillAim) -> void:
	var targets: Array[Combatant] = []
	var origin: Vector3 = caster.world_position()
	for hostile in CombatWorld.hostiles_of(caster):
		if CombatWorld.in_cone(origin, aim.direction, hostile, skill.skill_range, skill.cone_degrees):
			targets.append(hostile)
	_strike_all(skill, caster, targets)
	Events.skill_impacted.emit(skill, caster, _sweep_center(skill, origin, aim))


static func _line(skill: SkillData, caster: Combatant, aim: SkillAim) -> void:
	var targets: Array[Combatant] = []
	var origin: Vector3 = caster.world_position()
	for hostile in CombatWorld.hostiles_of(caster):
		if CombatWorld.in_line(origin, aim.direction, hostile, skill.skill_range, skill.line_width):
			targets.append(hostile)
	_strike_all(skill, caster, targets)
	Events.skill_impacted.emit(skill, caster, _sweep_center(skill, origin, aim))
	if not has_custom_impact(skill):
		Vfx.line_wave(caster.get_tree(), origin, aim.direction, skill.skill_range, skill.line_width, skill.color)


static func _self_area(skill: SkillData, caster: Combatant) -> void:
	var center: Vector3 = caster.world_position()
	_strike_all(skill, caster, CombatWorld.hostiles_near(caster, center, skill.radius))
	Events.skill_impacted.emit(skill, caster, center)
	if not has_custom_impact(skill):
		Vfx.shockwave(caster.get_tree(), center, skill.radius, skill.color)


## O efeito de área genérico (onda, linha de explosões) dá lugar ao do `AttackFx` quando a habilidade traz `fx`
## com forma de impacto. O `hit_burst` em quem foi atingido e o `skill_impacted` continuam.
static func has_custom_impact(skill: SkillData) -> bool:
	return skill.fx != null and skill.fx.impact_style != SkillFxData.ImpactStyle.NONE


## Meio do alcance, no chão, sobre o eixo da mira.
static func _sweep_center(skill: SkillData, origin: Vector3, aim: SkillAim) -> Vector3:
	var flat := Vector3(aim.direction.x, 0.0, aim.direction.z).normalized()
	return origin + flat * skill.skill_range * 0.5


static func _ground_area(skill: SkillData, caster: Combatant, aim: SkillAim) -> void:
	var point: Vector3 = aim.ground_point
	var tree: SceneTree = caster.get_tree()
	if skill.impact_delay <= 0.0:
		area_impact(skill, caster, point)
		return
	Vfx.falling_star(tree, point, skill.impact_delay, skill.color)
	Telegraph.spawn_area(tree, point, skill.radius, skill.impact_delay, skill.color, Telegraph.hostile_caster(caster))
	await tree.create_timer(skill.impact_delay, false).timeout
	if is_instance_valid(caster):
		area_impact(skill, caster, point)


static func area_impact(skill: SkillData, caster: Combatant, point: Vector3) -> void:
	_strike_all(skill, caster, CombatWorld.hostiles_near(caster, point, skill.radius))
	if not has_custom_impact(skill):
		Vfx.shockwave(caster.get_tree(), point, skill.radius, skill.color)
	Events.skill_impacted.emit(skill, caster, point)


static func _heal_ally(skill: SkillData, caster: Combatant, target: Combatant) -> void:
	if target == null or not is_instance_valid(target):
		target = caster
	var amount: float = DamageCalculator.heal_amount(caster.stats, skill.power, caster.balance, caster.rng)
	var before: float = target.hp
	target.receive_heal(amount, caster)
	# Chi só com cura efetiva; curar quem está cheio ou morto não pode virar fonte de suprema.
	if target.hp > before:
		caster.add_chi(skill.chi_gain)
	Vfx.heal_glow(caster.get_tree(), target.world_position(), skill.color)


static func _party(skill: SkillData, caster: Combatant) -> void:
	var allies: Array[Combatant] = CombatWorld.allies_of(caster, true)
	# O conjurador por último: o buff que ele recebe não pode inflar o que os aliados recebem.
	allies.erase(caster)
	allies.append(caster)
	for ally in allies:
		if not ally.is_alive():
			if skill.revives_allies:
				ally.revive(skill.revive_hp_ratio)
				Vfx.heal_glow(caster.get_tree(), ally.world_position(), skill.color)
			continue
		if skill.damage_kind == SkillData.DamageKind.HEAL:
			ally.receive_heal(DamageCalculator.heal_amount(caster.stats, skill.power, caster.balance, caster.rng), caster)
		if skill.target_effect != null:
			ally.apply_effect(skill.target_effect, caster)
		Vfx.heal_glow(caster.get_tree(), ally.world_position(), skill.color)


static func _dash(skill: SkillData, caster: Combatant, aim: SkillAim) -> void:
	var actor: Node3D = caster.actor()
	var start: Vector3 = actor.global_position
	var flat := Vector3(aim.direction.x, 0.0, aim.direction.z).normalized()
	var reach: float = skill.skill_range
	if aim.target != null and is_instance_valid(aim.target):
		var offset: Vector3 = aim.target.world_position() - start
		offset.y = 0.0
		flat = offset.normalized()
		reach = minf(reach, maxf(offset.length() - aim.target.body_radius - 0.8, 0.5))
	var destination: Vector3 = CombatWorld.clear_destination(actor, start, start + flat * reach)
	var duration: float = maxf(start.distance_to(destination) / DASH_SPEED, 0.05)
	caster.begin_forced_move(duration)
	var tween := actor.create_tween()
	tween.tween_property(actor, "global_position", destination, duration)
	await tween.finished
	if is_instance_valid(caster) and caster.is_alive():
		if _strike_all(skill, caster, CombatWorld.hostiles_near(caster, actor.global_position, skill.radius)):
			Events.skill_impacted.emit(skill, caster, actor.global_position)
		Vfx.shockwave(caster.get_tree(), actor.global_position, skill.radius, skill.color)


static func _blink(skill: SkillData, caster: Combatant, aim: SkillAim) -> void:
	var actor: Node3D = caster.actor()
	var start: Vector3 = actor.global_position
	var flat := Vector3(aim.direction.x, 0.0, aim.direction.z).normalized()
	var destination: Vector3 = CombatWorld.clear_destination(actor, start, start + flat * skill.skill_range)
	Vfx.heal_glow(caster.get_tree(), start, skill.color)
	actor.global_position = destination
	Vfx.heal_glow(caster.get_tree(), destination, skill.color)
