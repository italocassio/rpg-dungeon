extends Node
## Barramento global apenas para avisos entre sistemas independentes (combate -> UI).

## kind: "info", "reward", "warning", "quest"
signal system_message(text: String, kind: String)
signal chat_message(channel: String, author: String, text: String)
signal combat_log(text: String, color: Color)
signal zone_entered(zone_name: String)
signal loot_collected(item: ItemData, count: int)
signal crystals_collected(amount: int)
signal boss_engaged(boss: Node)
signal boss_defeated(boss: Node)
