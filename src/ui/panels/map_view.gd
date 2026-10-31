class_name MapView
extends Control
## Mapa em pergaminho, com salas nomeadas e posição do grupo.

var _run: DungeonRun
var _texture: ImageTexture


func bind(run: DungeonRun) -> void:
	_run = run
	_texture = DungeonMapImage.parchment(run.world.field)
	custom_minimum_size = Vector2(_texture.get_size()) * 1.25


func _map_point(point: Vector2) -> Vector2:
	var field: DungeonField = _run.world.field
	return (point - field.origin) * DungeonMapImage.SCALE * size.x / float(_texture.get_width())


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
	var font: Font = UiKit.title_font()
	draw_string(font, Vector2(24.0, 42.0), _run.dungeon.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color("3a2410"))
	for room in _run.dungeon.rooms:
		var point: Vector2 = _map_point(room.center)
		var color := Color("7a1f1a") if room.kind == RoomData.Kind.BOSS else Color("4a3218")
		draw_circle(point, 5.0, color)
		var label_x: float = clampf(point.x - 80.0, 6.0, size.x - 166.0)
		draw_string(UiKit.bold_font(), Vector2(label_x, point.y + 22.0), room.display_name, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 13, Color("3a2410"))
	var player_position: Vector3 = _run.player.global_position
	var marker: Vector2 = _map_point(Vector2(player_position.x, player_position.z))
	draw_circle(marker, 8.0, Color("c8302a"))
	draw_arc(marker, 12.0, 0.0, TAU, 24, Color("3a2410"), 2.0)
