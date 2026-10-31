class_name Minimap
extends Control
## Minimapa com bússola N/L/S/O, grupo, monstros e chefe.

const VIEW_METERS := 62.0
const PIXEL_SIZE := 190.0

var _run: DungeonRun
var _texture: ImageTexture
var _scale_pixels: float = 1.0


func bind(run: DungeonRun) -> void:
	_run = run
	_texture = DungeonMapImage.dark(run.world.field)
	custom_minimum_size = Vector2.ONE * PIXEL_SIZE
	clip_contents = true
	_scale_pixels = PIXEL_SIZE / VIEW_METERS


func _process(_delta: float) -> void:
	queue_redraw()


func _map_point(world_position: Vector3, center: Vector2) -> Vector2:
	var offset := Vector2(world_position.x, world_position.z) - center
	return offset * _scale_pixels + size * 0.5


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color(0.02, 0.03, 0.05, 0.9))
	if _run == null or not is_instance_valid(_run.player):
		return
	var position_3d: Vector3 = _run.player.global_position
	var center := Vector2(position_3d.x, position_3d.z)
	var field: DungeonField = _run.world.field
	var source := Rect2((center - field.origin - Vector2.ONE * VIEW_METERS * 0.5) * DungeonMapImage.SCALE,
		Vector2.ONE * VIEW_METERS * DungeonMapImage.SCALE)
	draw_texture_rect_region(_texture, area, source)
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.combatant.is_alive():
			var boss: bool = enemy.data.tier == MonsterData.Tier.BOSS
			draw_circle(_map_point(enemy.global_position, center), 5.5 if boss else 2.8, Color("ff4a3a") if boss else Color("ff7a6a"))
	for bot in _run.bots:
		if bot.combatant.is_alive():
			draw_circle(_map_point(bot.global_position, center), 3.0, UiKit.GOOD)
	var forward: Vector3 = -_run.player.global_basis.z
	var heading := Vector2(forward.x, forward.z).normalized()
	var side := Vector2(-heading.y, heading.x)
	var middle: Vector2 = size * 0.5
	draw_colored_polygon(PackedVector2Array([middle + heading * 9.0, middle - heading * 5.0 + side * 5.0, middle - heading * 2.5, middle - heading * 5.0 - side * 5.0]), UiKit.GOLD_BRIGHT)
	var font: Font = UiKit.bold_font()
	for letter: Array in [["N", Vector2(size.x * 0.5 - 5.0, 16.0)], ["S", Vector2(size.x * 0.5 - 5.0, size.y - 6.0)], ["O", Vector2(6.0, size.y * 0.5 + 5.0)], ["L", Vector2(size.x - 15.0, size.y * 0.5 + 5.0)]]:
		draw_string_outline(font, letter[1], letter[0], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, 3, Color.BLACK)
		draw_string(font, letter[1], letter[0], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, UiKit.GOLD_BRIGHT)
	draw_rect(area, UiKit.BRONZE, false, 2.0)
