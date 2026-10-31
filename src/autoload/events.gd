extends Node
## Barramento global apenas para avisos entre sistemas independentes (combate -> UI e áudio).

## kind: "info", "reward", "warning", "quest"
signal system_message(text: String, kind: String)
signal chat_message(channel: String, author: String, text: String)
signal combat_log(text: String, color: Color)
signal zone_entered(zone_name: String)
signal loot_collected(item: ItemData, count: int)
signal crystals_collected(amount: int)
signal dungeon_entered
signal dungeon_exited
signal boss_engaged(boss: Node)
signal boss_disengaged(boss: Node)
signal boss_defeated(boss: Node)
signal skill_cast_started(skill: SkillData, caster: Combatant)
signal skill_cast_stopped(skill: SkillData, caster: Combatant)
signal skill_fired(skill: SkillData, caster: Combatant)
signal skill_impacted(skill: SkillData, caster: Combatant, point: Vector3)
signal heal_zone_opened(zone: HealZone)
signal guard_raised(class_id: StringName, unit: Combatant)
