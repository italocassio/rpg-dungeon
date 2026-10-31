class_name UiKit
extends RefCounted
## Identidade visual: moldura bronze de Perfect World + janelas azuis do "Sistema" de Solo Leveling.

const GOLD := Color("e8c98a")
const GOLD_BRIGHT := Color("ffe6ad")
const BRONZE := Color("8a6a35")
const BRONZE_DARK := Color("4a3a20")
const INK := Color(0.06, 0.05, 0.04, 0.86)
const PAPER := Color("e6dcc6")
const MUTED := Color("a79c88")
const HP_COLOR := Color("c8302a")
const MP_COLOR := Color("2f6fd8")
const XP_COLOR := Color("5ac85a")
const SYSTEM_BG := Color(0.02, 0.07, 0.15, 0.93)
const SYSTEM_LINE := Color("4fc3ff")
const SYSTEM_TEXT := Color("d6f2ff")
const GOOD := Color("8dffb0")
const BAD := Color("ff7a6a")

static var _title_font: Font
static var _bold_font: Font
static var _body_font: Font
static var _theme: Theme
static var _icons: Dictionary[StringName, Texture2D] = {}


static func title_font() -> Font:
	if _title_font == null:
		_title_font = _weighted("res://assets/fonts/Cinzel.ttf", 700)
	return _title_font


static func bold_font() -> Font:
	if _bold_font == null:
		_bold_font = _weighted("res://assets/fonts/Exo2.ttf", 700)
	return _bold_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = _weighted("res://assets/fonts/Exo2.ttf", 500)
	return _body_font


static func _weighted(path: String, weight: int) -> Font:
	var variation := FontVariation.new()
	variation.base_font = load(path)
	var tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	variation.variation_opentype = {tag: weight}
	return variation


static func icon(id: StringName) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	var path: String = "res://assets/icons/%s.svg" % id
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icons[id] = texture
	return texture


static func style(background: Color, border: Color, width: int = 2, radius: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


static func panel_style(padding: int = 10) -> StyleBoxFlat:
	var box: StyleBoxFlat = style(INK, BRONZE, 2, 4)
	box.set_content_margin_all(padding)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	box.shadow_size = 6
	return box


static func system_style(padding: int = 16) -> StyleBoxFlat:
	var box: StyleBoxFlat = style(SYSTEM_BG, SYSTEM_LINE, 1, 2)
	box.set_content_margin_all(padding)
	box.shadow_color = Color(SYSTEM_LINE, 0.35)
	box.shadow_size = 12
	return box


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 15
	t.set_color(&"font_color", &"Label", PAPER)
	t.set_stylebox(&"panel", &"PanelContainer", panel_style())
	t.set_stylebox(&"panel", &"Panel", panel_style(0))
	t.set_stylebox(&"normal", &"Button", _button_box(Color("2a2115"), BRONZE))
	t.set_stylebox(&"hover", &"Button", _button_box(Color("44361f"), GOLD))
	t.set_stylebox(&"pressed", &"Button", _button_box(Color("1c160d"), GOLD))
	t.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	t.set_stylebox(&"disabled", &"Button", _button_box(Color("1a1712"), BRONZE_DARK))
	t.set_color(&"font_color", &"Button", GOLD)
	t.set_color(&"font_hover_color", &"Button", GOLD_BRIGHT)
	t.set_color(&"font_pressed_color", &"Button", GOLD_BRIGHT)
	t.set_color(&"font_disabled_color", &"Button", Color("6a6050"))
	t.set_font(&"font", &"Button", bold_font())
	t.set_stylebox(&"panel", &"TooltipPanel", panel_style(8))
	t.set_color(&"font_color", &"TooltipLabel", PAPER)
	t.set_font(&"font", &"TooltipLabel", body_font())
	t.set_font_size(&"font_size", &"TooltipLabel", 14)
	t.set_stylebox(&"scroll", &"VScrollBar", style(Color(0.0, 0.0, 0.0, 0.3), Color.TRANSPARENT, 0, 2))
	t.set_stylebox(&"grabber", &"VScrollBar", style(BRONZE, Color.TRANSPARENT, 0, 2))
	t.set_stylebox(&"grabber_highlight", &"VScrollBar", style(GOLD, Color.TRANSPARENT, 0, 2))
	t.set_stylebox(&"grabber_pressed", &"VScrollBar", style(GOLD, Color.TRANSPARENT, 0, 2))
	_theme = t
	return t


static func _button_box(background: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = style(background, border, 1, 3)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	return box


static func label(text: String, size: int = 15, color: Color = PAPER, font: Font = null) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override(&"font_size", size)
	node.add_theme_color_override(&"font_color", color)
	if font != null:
		node.add_theme_font_override(&"font", font)
	return node


static func shadowed(node: Label, outline: int = 5) -> Label:
	node.add_theme_constant_override(&"outline_size", outline)
	node.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	return node


static func button(text: String, action: Callable, size: int = 15) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_size_override(&"font_size", size)
	node.pressed.connect(action)
	node.focus_mode = Control.FOCUS_NONE
	return node


static func bar(color: Color, height: float) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size.y = height
	node.max_value = 1.0
	node.step = 0.001
	node.add_theme_stylebox_override(&"background", style(Color(0.02, 0.02, 0.03, 0.9), BRONZE_DARK, 1, 2))
	node.add_theme_stylebox_override(&"fill", style(color, Color.TRANSPARENT, 0, 2))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func vbox(separation: int = 6) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override(&"separation", separation)
	return node


static func hbox(separation: int = 6) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override(&"separation", separation)
	return node


static func margin(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var node := MarginContainer.new()
	node.add_theme_constant_override(&"margin_left", left)
	node.add_theme_constant_override(&"margin_top", top)
	node.add_theme_constant_override(&"margin_right", right)
	node.add_theme_constant_override(&"margin_bottom", bottom)
	node.add_child(child)
	return node


static func rarity_color(rarity: ItemData.Rarity) -> Color:
	return LootDrop.RARITY_COLORS[rarity]


## Ícone sobre fundo escuro com borda colorida (raridade ou classe).
static func icon_tile(icon_id: StringName, tint: Color, size: float) -> PanelContainer:
	var tile := PanelContainer.new()
	var box: StyleBoxFlat = style(Color(tint.r * 0.16, tint.g * 0.16, tint.b * 0.16, 0.95), tint, 1, 3)
	box.set_content_margin_all(size * 0.14)
	tile.add_theme_stylebox_override(&"panel", box)
	tile.custom_minimum_size = Vector2.ONE * size
	var picture := TextureRect.new()
	picture.texture = icon(icon_id)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.modulate = tint.lightened(0.25)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(picture)
	return tile


static func item_tooltip(item: ItemData) -> String:
	var lines: Array[String] = [item.display_name, "%s %s" % [ItemData.RARITY_NAMES[item.rarity], ItemData.KIND_NAMES[item.kind]]]
	if item.is_equipment():
		lines.append("Nível necessário: %d" % item.required_level)
		for stat: StringName in item.stat_bonuses:
			lines.append("%+.0f %s" % [item.stat_bonuses[stat], StatBlock.LABELS.get(stat, stat)] if absf(item.stat_bonuses[stat]) >= 1.0
				else "%+.0f%% %s" % [item.stat_bonuses[stat] * 100.0, StatBlock.LABELS.get(stat, stat)])
	lines.append(item.description)
	return "\n".join(lines)


static func skill_tooltip(skill: SkillData) -> String:
	var lines: Array[String] = [skill.display_name, skill.description]
	var facts: Array[String] = []
	if skill.mp_cost > 0.0:
		facts.append("Mana %d" % skill.mp_cost)
	if skill.chi_cost > 0.0:
		facts.append("Chi %d" % skill.chi_cost)
	if skill.cast_time > 0.0:
		facts.append("Conjuração %.1fs" % skill.cast_time)
	if skill.cooldown > 1.0:
		facts.append("Recarga %.0fs" % skill.cooldown)
	if not facts.is_empty():
		lines.append(" · ".join(facts))
	return "\n".join(lines)


static func fit_rect(control: Control, anchor_left: float, anchor_top: float, anchor_right: float, anchor_bottom: float, offset := Rect2()) -> void:
	control.anchor_left = anchor_left
	control.anchor_top = anchor_top
	control.anchor_right = anchor_right
	control.anchor_bottom = anchor_bottom
	control.offset_left = offset.position.x
	control.offset_top = offset.position.y
	control.offset_right = offset.size.x
	control.offset_bottom = offset.size.y


static func full_rect(control: Control) -> void:
	fit_rect(control, 0.0, 0.0, 1.0, 1.0)
