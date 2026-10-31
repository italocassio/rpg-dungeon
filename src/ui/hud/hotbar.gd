class_name Hotbar
extends HBoxContainer
## Barra de habilidades: ataque, defesa, quatro habilidades, suprema, esquiva e poções.


func bind(player: PlayerController, combat: PlayerCombat, sheet: CharacterSheet) -> void:
	add_theme_constant_override(&"separation", 4)
	var class_data: ClassData = sheet.class_data
	var caster: SkillCaster = player.caster
	_skill_slot("LMB", class_data.basic_attack, caster, player)
	_custom_slot("RMB", &"shield", class_data.color, class_data.guard_name, Callable(), Callable())
	add_child(_gap())
	var keys: Array[String] = ["1", "2", "3", "4", "R"]
	var skills: Array[SkillData] = combat.hotbar()
	for i in skills.size():
		_skill_slot(keys[i], skills[i], caster, player)
	add_child(_gap())
	_custom_slot("Ctrl", &"dodge", Color("9fe3ff"), "Esquiva: breve invulnerabilidade", player.dodge_cooldown_ratio, Callable())
	var potion_ratio := combat.potion_cooldown_ratio
	var inventory: Inventory = sheet.inventory
	_potion_slot("Q", &"potion_red", UiKit.HP_COLOR, &"potion_hp", potion_ratio, inventory)
	_potion_slot("X", &"potion_blue", UiKit.MP_COLOR, &"potion_mp", potion_ratio, inventory)


func _gap() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.x = 10.0
	return gap


func _skill_slot(key: String, skill: SkillData, caster: SkillCaster, player: PlayerController) -> void:
	var slot := SkillSlot.new()
	slot.key_text = key
	slot.tint = skill.color
	slot.icon_texture = UiKit.icon(skill.icon)
	slot.tooltip_text = UiKit.skill_tooltip(skill)
	slot.ratio_provider = caster.cooldown_ratio.bind(skill)
	slot.seconds_provider = caster.cooldown_left.bind(skill)
	slot.usable_provider = func() -> bool:
		var unit: Combatant = player.combatant
		return unit.mp >= skill.mp_cost and unit.chi >= skill.chi_cost
	add_child(slot)


func _custom_slot(key: String, icon_id: StringName, tint: Color, tooltip: String, ratio: Callable, count: Callable) -> void:
	var slot := SkillSlot.new()
	slot.key_text = key
	slot.tint = tint
	slot.icon_texture = UiKit.icon(icon_id)
	slot.tooltip_text = tooltip
	slot.ratio_provider = ratio
	slot.count_provider = count
	add_child(slot)


func _potion_slot(key: String, icon_id: StringName, tint: Color, item_id: StringName, ratio: Callable, inventory: Inventory) -> void:
	_custom_slot(key, icon_id, tint, GameDB.item(item_id).display_name, ratio, func() -> int: return inventory.count_of(item_id))
