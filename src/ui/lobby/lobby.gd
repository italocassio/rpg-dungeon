class_name Lobby
extends Control
## Saguão: classe, itens conforme a classe, forja e busca de grupo.

signal gate_entered

const TABS: Array[Array] = [[&"class", "1 · Classe"], [&"gear", "2 · Itens"], [&"forge", "Forja"], [&"party", "3 · Grupo"]]
const SEARCH_STEP_SECONDS := 0.9

var stage: LobbyStage
var selected_class: ClassData
var pending_weapon: ItemData
var pending_armor: ItemData
var selected_rank: GateRankData
var found_members: Array[PartyMember] = []

var _tab_buttons: Dictionary[StringName, Button] = {}
var _page: Control
var _content: PanelContainer
var _status: Label
var _rng := RandomNumberGenerator.new()
var _search_serial: int = 0
var _watched_sheet: CharacterSheet


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.full_rect(self)
	_rng.randomize()
	var dungeon: DungeonData = GameDB.catalog.dungeons[0]
	selected_rank = dungeon.ranks[0]
	selected_class = Session.active_sheet.class_data if Session.active_sheet != null else GameDB.catalog.classes[0]
	_pick_defaults()
	_build_frame()
	_refresh_hero()
	open_tab(&"forge" if Session.active_sheet != null and Session.active_sheet.xp + Session.active_sheet.level > 1 else &"class")


func _build_frame() -> void:
	var title := UiKit.shadowed(UiKit.label("Caçadores de Portais", 44, UiKit.GOLD_BRIGHT, UiKit.title_font()), 8)
	UiKit.fit_rect(title, 0.0, 0.0, 0.0, 0.0, Rect2(44.0, 30.0, 720.0, 90.0))
	add_child(title)
	var subtitle := UiKit.shadowed(UiKit.label("Abra o Portão. Derrote o chefe. Forje sua lenda.", 17, UiKit.SYSTEM_TEXT, UiKit.bold_font()), 4)
	UiKit.fit_rect(subtitle, 0.0, 0.0, 0.0, 0.0, Rect2(46.0, 86.0, 720.0, 112.0))
	add_child(subtitle)
	_status = UiKit.shadowed(UiKit.label("", 15, Color("7fd4ff"), UiKit.bold_font()), 4)
	UiKit.fit_rect(_status, 0.0, 1.0, 0.0, 1.0, Rect2(46.0, -48.0, 760.0, -20.0))
	add_child(_status)

	var side := UiKit.vbox(8)
	UiKit.fit_rect(side, 1.0, 0.0, 1.0, 1.0, Rect2(-800.0, 26.0, -26.0, -26.0))
	add_child(side)
	var tabs := UiKit.hbox(6)
	side.add_child(tabs)
	for entry: Array in TABS:
		var button := UiKit.button(entry[1], open_tab.bind(entry[0]), 16)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		_tab_buttons[entry[0]] = button
	_content = PanelContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_stylebox_override(&"panel", UiKit.panel_style(16))
	side.add_child(_content)


func open_tab(tab: StringName) -> void:
	_search_serial += 1
	found_members.clear()
	if _page != null:
		_page.queue_free()
		_page = null
	for key: StringName in _tab_buttons:
		_tab_buttons[key].add_theme_color_override(&"font_color", UiKit.GOLD_BRIGHT if key == tab else UiKit.MUTED)
	match tab:
		&"class":
			_page = _build_class_page()
		&"gear":
			_page = _build_gear_page()
		&"forge":
			_page = _build_forge_page()
		_:
			_page = _build_party_page()
	_content.add_child(_page)
	_update_status()


func _update_status() -> void:
	var sheet: CharacterSheet = Session.sheets.get(selected_class.id)
	if sheet != null:
		_status.text = "%s · Nível %d · %d Cristais de Mana" % [selected_class.display_name, sheet.level, sheet.inventory.mana_crystals]
	else:
		_status.text = "Novo caçador: %s" % selected_class.display_name


func _pick_defaults() -> void:
	pending_weapon = selected_class.starter_weapons[0]
	pending_armor = selected_class.starter_armors[0]


func _refresh_hero() -> void:
	if stage == null:
		return
	var sheet: CharacterSheet = Session.sheets.get(selected_class.id)
	var armor: ItemData = pending_armor
	var weapon: ItemData = pending_weapon
	if sheet != null:
		armor = sheet.equipment.get(ItemData.Kind.ARMOR, armor)
		weapon = sheet.equipment.get(ItemData.Kind.WEAPON, weapon)
	stage.show_hero(selected_class.id, armor, weapon)


# ---------- Classe ----------

func _build_class_page() -> Control:
	var page := UiKit.vbox(10)
	page.add_child(UiKit.label("Raça: Humano", 14, UiKit.MUTED))
	var cards := UiKit.hbox(8)
	page.add_child(cards)
	for class_data in GameDB.catalog.classes:
		cards.add_child(_class_card(class_data))
	page.add_child(_class_detail())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	page.add_child(UiKit.button("Escolher itens  ›", open_tab.bind(&"gear"), 18))
	return page


func _class_card(class_data: ClassData) -> Control:
	var selected: bool = class_data == selected_class
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 120.0
	var tint: Color = class_data.color
	button.add_theme_stylebox_override(&"normal", UiKit.style(Color(tint.r * 0.2, tint.g * 0.2, tint.b * 0.2, 0.9), tint if selected else UiKit.BRONZE_DARK, 2, 4))
	button.add_theme_stylebox_override(&"hover", UiKit.style(Color(tint.r * 0.32, tint.g * 0.32, tint.b * 0.32, 0.9), tint, 2, 4))
	button.pressed.connect(_on_class_chosen.bind(class_data))
	var column := UiKit.vbox(2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(column)
	button.add_child(column)
	var picture := TextureRect.new()
	picture.texture = UiKit.icon(class_data.id)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0.0, 46.0)
	picture.modulate = tint.lightened(0.3)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	var name_label := UiKit.label(class_data.display_name, 18, UiKit.GOLD_BRIGHT if selected else UiKit.PAPER, UiKit.title_font())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var note: String = "Nv %d" % Session.sheets[class_data.id].level if Session.has_sheet(class_data.id) else ClassData.ARMOR_NAMES[class_data.armor_type]
	var note_label := UiKit.label(note, 12, UiKit.MUTED)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note_label)
	return button


func _on_class_chosen(class_data: ClassData) -> void:
	selected_class = class_data
	_pick_defaults()
	_ensure_allowed_rank()
	_refresh_hero()
	open_tab(&"class")


func _rank_allowed(rank: GateRankData) -> bool:
	return _player_level() >= rank.recommended_level - 1


## O rank escolhido pertence à classe anterior: cada classe respeita a própria trava.
func _ensure_allowed_rank() -> void:
	if not _rank_allowed(selected_rank):
		selected_rank = GameDB.catalog.dungeons[0].ranks[0]


func _class_detail() -> Control:
	var column := UiKit.vbox(6)
	var description := UiKit.label(selected_class.description, 15, UiKit.PAPER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	var attributes := UiKit.hbox(18)
	column.add_child(attributes)
	for attribute: StringName in CharacterSheet.ATTRIBUTES:
		attributes.add_child(UiKit.label("%s %d" % [CharacterSheet.ATTRIBUTE_LABELS[attribute], selected_class.get(attribute)], 13, UiKit.SYSTEM_TEXT, UiKit.bold_font()))
	column.add_child(UiKit.label("Habilidades", 15, UiKit.GOLD, UiKit.title_font()))
	var skills: Array[SkillData] = [selected_class.basic_attack]
	skills.append_array(selected_class.skills)
	skills.append(selected_class.ultimate)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 6)
	column.add_child(grid)
	for skill in skills:
		var row := UiKit.hbox(8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(UiKit.icon_tile(skill.icon, skill.color, 38.0))
		var text := UiKit.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		text.add_child(UiKit.label(skill.display_name, 14, UiKit.GOLD_BRIGHT, UiKit.bold_font()))
		var details := UiKit.label(skill.description, 12, UiKit.MUTED)
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.custom_minimum_size.x = 300.0
		text.add_child(details)
		grid.add_child(row)
	return column


# ---------- Itens ----------

func _build_gear_page() -> Control:
	var sheet: CharacterSheet = Session.sheets.get(selected_class.id)
	if sheet != null:
		var view := InventoryView.new()
		view.bind(sheet)
		_watch_sheet(sheet)
		return view
	var page := UiKit.vbox(10)
	page.add_child(UiKit.label("Itens iniciais de %s" % selected_class.display_name, 18, UiKit.GOLD, UiKit.title_font()))
	page.add_child(UiKit.label("Arma", 15, UiKit.MUTED))
	page.add_child(_choice_row(selected_class.starter_weapons, pending_weapon, _on_weapon_chosen))
	page.add_child(UiKit.label("Armadura", 15, UiKit.MUTED))
	page.add_child(_choice_row(selected_class.starter_armors, pending_armor, _on_armor_chosen))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	page.add_child(UiKit.label("Inclui 5 Poções de Vida e 5 Poções de Mana.", 13, UiKit.MUTED))
	page.add_child(UiKit.button("Procurar grupo  ›", open_tab.bind(&"party"), 18))
	return page


## Uma única conexão por ficha, independente de quantas vezes a aba é recriada.
func _watch_sheet(sheet: CharacterSheet) -> void:
	if _watched_sheet == sheet:
		return
	_unwatch_sheet()
	_watched_sheet = sheet
	sheet.changed.connect(_refresh_hero)


func _unwatch_sheet() -> void:
	if _watched_sheet != null and _watched_sheet.changed.is_connected(_refresh_hero):
		_watched_sheet.changed.disconnect(_refresh_hero)
	_watched_sheet = null


func _exit_tree() -> void:
	_unwatch_sheet()


func _choice_row(items: Array[ItemData], selected: ItemData, action: Callable) -> Control:
	var row := UiKit.hbox(8)
	for item in items:
		row.add_child(_item_card(item, item == selected, action))
	return row


func _item_card(item: ItemData, selected: bool, action: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 128.0
	var border: Color = selected_class.color if selected else UiKit.BRONZE_DARK
	button.add_theme_stylebox_override(&"normal", UiKit.style(Color(0.1, 0.08, 0.06, 0.9), border, 2, 4))
	button.add_theme_stylebox_override(&"hover", UiKit.style(Color(0.18, 0.14, 0.09, 0.9), selected_class.color, 2, 4))
	button.pressed.connect(action.bind(item))
	var row := UiKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.fit_rect(row, 0.0, 0.0, 1.0, 1.0, Rect2(10.0, 8.0, -10.0, -8.0))
	button.add_child(row)
	row.add_child(UiKit.icon_tile(item.icon, UiKit.rarity_color(item.rarity), 54.0))
	var column := UiKit.vbox(2)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var name_label := UiKit.label(item.display_name, 15, UiKit.GOLD_BRIGHT if selected else UiKit.PAPER, UiKit.bold_font())
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	var description := UiKit.label(item.description, 12, UiKit.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	var bonuses: Array[String] = []
	for stat: StringName in item.stat_bonuses:
		var value: float = item.stat_bonuses[stat]
		bonuses.append("%+.0f %s" % [value, StatBlock.LABELS.get(stat, stat)] if absf(value) >= 1.0 else "%+.0f%% %s" % [value * 100.0, StatBlock.LABELS.get(stat, stat)])
	var stats := UiKit.label(" · ".join(bonuses), 12, UiKit.GOOD)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	return button


func _on_weapon_chosen(item: ItemData) -> void:
	pending_weapon = item
	_refresh_hero()
	open_tab(&"gear")


func _on_armor_chosen(item: ItemData) -> void:
	pending_armor = item
	_refresh_hero()
	open_tab(&"gear")


# ---------- Forja ----------

func _build_forge_page() -> Control:
	var sheet: CharacterSheet = Session.sheets.get(selected_class.id)
	if sheet == null:
		var empty := UiKit.vbox(10)
		var text := UiKit.label("Entre em um Portão primeiro. Monstros derrubam materiais de forja, e o chefe guarda os itens raros.", 16, UiKit.PAPER)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_child(text)
		return empty
	var view := ForgeView.new()
	view.bind(sheet)
	view.forged.connect(func(_item: ItemData) -> void:
		_update_status()
		_status.text += "  ·  Forja concluída! Equipe a peça na aba Itens.")
	return view


# ---------- Grupo ----------

func _build_party_page() -> Control:
	var page := UiKit.vbox(10)
	var dungeon: DungeonData = GameDB.catalog.dungeons[0]
	page.add_child(UiKit.label(dungeon.display_name, 22, UiKit.GOLD, UiKit.title_font()))
	var description := UiKit.label(dungeon.description, 14, UiKit.PAPER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(description)
	var ranks := UiKit.hbox(8)
	page.add_child(ranks)
	var level: int = _player_level()
	_ensure_allowed_rank()
	for rank in dungeon.ranks:
		var locked: bool = not _rank_allowed(rank)
		var button := UiKit.button("Portão Rank %s  (nível %d+)" % [rank.label, rank.recommended_level], _on_rank_chosen.bind(rank), 15)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = locked
		var border: Color = rank.color if rank == selected_rank else UiKit.BRONZE_DARK
		button.add_theme_stylebox_override(&"normal", UiKit.style(Color(rank.color.r * 0.16, rank.color.g * 0.16, rank.color.b * 0.16, 0.92), border, 2, 3))
		ranks.add_child(button)

	var list := UiKit.vbox(5)
	list.name = "Members"
	page.add_child(list)
	list.add_child(_member_row(_player_name_line(), selected_class, level, true))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	var search := UiKit.button("Procurar Grupo", _begin_search.bind(list), 18)
	search.name = "Search"
	page.add_child(search)
	var enter := UiKit.button("Entrar no Portão", _enter_gate, 20)
	enter.name = "Enter"
	enter.visible = false
	page.add_child(enter)
	return page


func _player_level() -> int:
	return Session.sheets[selected_class.id].level if Session.has_sheet(selected_class.id) else 1


func _player_name_line() -> String:
	return "%s (você)" % Session.player_name


func _on_rank_chosen(rank: GateRankData) -> void:
	selected_rank = rank
	open_tab(&"party")


func _member_row(member_name: String, class_data: ClassData, level: int, is_player: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiKit.style(Color(0.1, 0.08, 0.06, 0.85), UiKit.GOLD if is_player else UiKit.BRONZE_DARK, 1, 3))
	var row := UiKit.hbox(10)
	panel.add_child(UiKit.margin(row, 8, 6, 8, 6))
	row.add_child(UiKit.icon_tile(class_data.id, class_data.color, 38.0))
	var name_label := UiKit.label(member_name, 16, UiKit.GOLD_BRIGHT if is_player else UiKit.PAPER, UiKit.bold_font())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(UiKit.label("%s · Nv %d" % [class_data.display_name, level], 14, UiKit.MUTED))
	return panel


func _begin_search(list: VBoxContainer) -> void:
	var serial: int = _search_serial
	var search_button: Button = _page.find_child("Search", true, false)
	search_button.disabled = true
	search_button.text = "Procurando caçadores..."
	var members: Array[PartyMember] = PartyFinder.assemble(selected_class, _player_level(), GameDB.catalog, GameDB.balance.party_size, _rng)
	for member in members:
		await get_tree().create_timer(SEARCH_STEP_SECONDS).timeout
		if serial != _search_serial:
			return
		list.add_child(_member_row(member.display_name, member.class_data, member.level, false))
		found_members.append(member)
	search_button.visible = false
	(_page.find_child("Enter", true, false) as Button).visible = true


func _enter_gate() -> void:
	Session.select_class(selected_class, pending_weapon, pending_armor)
	Session.begin_run(GameDB.catalog.dungeons[0], selected_rank, found_members.duplicate())
	Session.save_game()
	gate_entered.emit()
