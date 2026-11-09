class_name Hotbar
extends HBoxContainer
## Barra de habilidades: ataque, defesa, quatro habilidades, suprema, esquiva e poções.

const BASIC_KEY := "LMB"
const SKILL_KEYS: Array[String] = ["1", "2", "3", "4", "R"]


func bind(player: PlayerController, combat: PlayerCombat, sheet: CharacterSheet, tooltip: SkillTooltip) -> void:
	var class_data: ClassData = sheet.class_data
	var caster: SkillCaster = player.caster
	var slots: Array[SkillSlot] = build_slots(class_data)
	_wire_skill(slots[0], class_data.basic_attack, caster, player, tooltip)
	slots[1].tooltip_text = class_data.guard_name
	var skills: Array[SkillData] = combat.hotbar()
	for i in skills.size():
		_wire_skill(slots[2 + i], skills[i], caster, player, tooltip)
	var dodge: SkillSlot = slots[2 + skills.size()]
	dodge.tooltip_text = "Esquiva: breve invulnerabilidade"
	dodge.ratio_provider = player.dodge_cooldown_ratio
	var potion_ratio := combat.potion_cooldown_ratio
	var inventory: Inventory = sheet.inventory
	_wire_potion(slots[3 + skills.size()], &"potion_hp", potion_ratio, inventory)
	_wire_potion(slots[4 + skills.size()], &"potion_mp", potion_ratio, inventory)


## Cria os slots, sem provedores, na ordem: botão esquerdo, Guarda, habilidades, suprema, Esquiva, poção Q, poção X.
func build_slots(class_data: ClassData) -> Array[SkillSlot]:
	add_theme_constant_override(&"separation", 4)
	var slots: Array[SkillSlot] = []
	slots.append(SkillSlot.for_skill(class_data.basic_attack, BASIC_KEY))
	slots.append(SkillSlot.for_icon(&"shield", class_data.color, "RMB"))
	var skills: Array[SkillData] = class_data.skills.duplicate()
	skills.append(class_data.ultimate)
	for i in skills.size():
		slots.append(SkillSlot.for_skill(skills[i], SKILL_KEYS[i]))
	slots.append(SkillSlot.for_dodge("Ctrl"))
	slots.append(SkillSlot.for_potion(GameDB.item(&"potion_hp"), &"potion_red", UiKit.HP_COLOR, "Q"))
	slots.append(SkillSlot.for_potion(GameDB.item(&"potion_mp"), &"potion_blue", UiKit.MP_COLOR, "X"))
	var gaps_before: Array[int] = [2, 2 + skills.size()]
	for i in slots.size():
		if i in gaps_before:
			add_child(_gap())
		add_child(slots[i])
	return slots


func _gap() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.x = 10.0
	return gap


func _wire_skill(slot: SkillSlot, skill: SkillData, caster: SkillCaster, player: PlayerController, tooltip: SkillTooltip) -> void:
	tooltip.attach(slot, skill)
	slot.ratio_provider = caster.cooldown_ratio.bind(skill)
	slot.seconds_provider = caster.cooldown_left.bind(skill)
	slot.usable_provider = func() -> bool:
		var unit: Combatant = player.combatant
		return unit.mp >= skill.mp_cost and unit.chi >= skill.chi_cost


func _wire_potion(slot: SkillSlot, item_id: StringName, ratio: Callable, inventory: Inventory) -> void:
	slot.tooltip_text = GameDB.item(item_id).display_name
	slot.ratio_provider = ratio
	slot.count_provider = func() -> int: return inventory.count_of(item_id)
