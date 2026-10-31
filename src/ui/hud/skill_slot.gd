class_name SkillSlot
extends Control
## Espaço da barra de atalhos: ícone, varredura de recarga e tecla.

const SIZE := 58.0

var key_text: String = ""
var tint := Color.WHITE
var icon_texture: Texture2D
var ratio_provider: Callable = Callable()
var seconds_provider: Callable = Callable()
var usable_provider: Callable = Callable()
var count_provider: Callable = Callable()

var _ratio: float = 0.0
var _seconds: float = 0.0
var _usable: bool = true
var _count: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(_delta: float) -> void:
	_ratio = ratio_provider.call() if ratio_provider.is_valid() else 0.0
	_seconds = seconds_provider.call() if seconds_provider.is_valid() else 0.0
	_usable = usable_provider.call() if usable_provider.is_valid() else true
	_count = count_provider.call() if count_provider.is_valid() else -1
	queue_redraw()


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color(tint.r * 0.13, tint.g * 0.13, tint.b * 0.13, 0.92))
	if icon_texture != null:
		var alpha: float = 1.0 if _usable else 0.4
		draw_texture_rect(icon_texture, area.grow(-8.0), false, Color(tint.lightened(0.3), alpha))
	if _ratio > 0.0:
		_draw_sweep(area)
	draw_rect(area, UiKit.BRONZE if _usable else UiKit.BRONZE_DARK, false, 1.5)
	var font: Font = UiKit.bold_font()
	draw_string_outline(font, Vector2(4.0, 15.0), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, 3, Color.BLACK)
	draw_string(font, Vector2(4.0, 15.0), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, UiKit.GOLD_BRIGHT)
	if _seconds > 0.0:
		var text: String = str(ceili(_seconds)) if _seconds >= 1.0 else "%.1f" % _seconds
		var position_center := Vector2(0.0, size.y * 0.5 + 8.0)
		draw_string_outline(font, position_center, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, 4, Color.BLACK)
		draw_string(font, position_center, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color.WHITE)
	if _count >= 0:
		var corner := Vector2(0.0, size.y - 5.0)
		draw_string_outline(font, corner, str(_count), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4.0, 14, 3, Color.BLACK)
		draw_string(font, corner, str(_count), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4.0, 14, Color.WHITE)


func _draw_sweep(area: Rect2) -> void:
	var center: Vector2 = area.get_center()
	var points := PackedVector2Array([center])
	var reach: float = area.size.x
	var steps: int = 28
	for i in steps + 1:
		var angle: float = -PI * 0.5 + TAU * (1.0 - _ratio) + TAU * _ratio * float(i) / float(steps)
		var ray := Vector2(cos(angle), sin(angle)) * reach
		var scale_factor: float = minf(area.size.x * 0.5 / maxf(absf(ray.x), 0.001), area.size.y * 0.5 / maxf(absf(ray.y), 0.001))
		points.append(center + ray * scale_factor)
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.68))
