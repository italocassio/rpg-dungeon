class_name LootFeed
extends VBoxContainer
## Lista curta de itens recebidos, na cor da raridade.


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	custom_minimum_size = Vector2(260.0, 150.0)
	Events.loot_collected.connect(func(item: ItemData, count: int) -> void:
		_add("+%d %s" % [count, item.display_name], UiKit.rarity_color(item.rarity), item.rarity >= ItemData.Rarity.RARE))
	Events.crystals_collected.connect(func(amount: int) -> void:
		if amount > 0:
			_add("+%d Cristais de Mana" % amount, Color("7fd4ff"), false))


func _add(text: String, color: Color, big: bool) -> void:
	var line := UiKit.shadowed(UiKit.label(text, 19 if big else 14, color, UiKit.bold_font()), 4)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(line)
	if get_child_count() > 7:
		get_child(0).queue_free()
	var tween := line.create_tween()
	tween.tween_interval(4.5 if big else 2.5)
	tween.tween_property(line, "modulate:a", 0.0, 0.6)
	tween.tween_callback(line.queue_free)
