class_name TargetFrame
extends VBoxContainer
## Alvo atual ou sob a mira; chefes ficam fixos com barra maior e nome do golpe em preparo.

var _combat: PlayerCombat
var _unit: Combatant
var _boss: Combatant
var _boss_caster: SkillCaster
var _panel: PanelContainer
var _name: Label
var _bar: ProgressBar
var _value: Label
var _detail: Label
var _cast: Label


func bind(combat: PlayerCombat) -> void:
	_combat = combat
	custom_minimum_size.x = 430.0
	alignment = BoxContainer.ALIGNMENT_BEGIN
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(&"panel", UiKit.panel_style(8))
	add_child(_panel)
	var column := UiKit.vbox(3)
	_panel.add_child(column)
	_name = UiKit.shadowed(UiKit.label("", 17, UiKit.GOLD_BRIGHT, UiKit.title_font()))
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_name)
	_bar = UiKit.bar(UiKit.HP_COLOR, 18.0)
	column.add_child(_bar)
	_value = UiKit.shadowed(UiKit.label("", 12, Color.WHITE, UiKit.bold_font()), 3)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.full_rect(_value)
	_bar.add_child(_value)
	_detail = UiKit.shadowed(UiKit.label("", 12, UiKit.MUTED), 3)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_detail)
	_cast = UiKit.shadowed(UiKit.label("", 16, UiKit.BAD, UiKit.bold_font()))
	_cast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_cast)
	_panel.visible = false
	Events.boss_engaged.connect(_on_boss_engaged)
	Events.boss_defeated.connect(func(_b: Node) -> void:
		_boss = null
		_boss_caster = null)


func _on_boss_engaged(boss: Node) -> void:
	_boss = boss as Combatant
	_boss_caster = _boss.get_parent().get_node_or_null("SkillCaster")


func _shown_unit() -> Combatant:
	if is_instance_valid(_boss) and _boss.is_alive() and _boss.in_combat():
		return _boss
	if is_instance_valid(_combat.target):
		return _combat.target
	if is_instance_valid(_combat.hovered):
		return _combat.hovered
	return null


func _process(_delta: float) -> void:
	var unit: Combatant = _shown_unit()
	_panel.visible = unit != null
	var casting: SkillData = null
	if is_instance_valid(_boss_caster):
		casting = _boss_caster.casting_skill()
	_cast.text = "» %s «" % casting.display_name if casting != null and is_instance_valid(_boss) else ""
	if unit == null:
		return
	if unit != _unit:
		_unit = unit
		var stats: StatBlock = unit.stats
		var friendly: bool = unit.team == Combatant.Team.PARTY
		_name.text = "[%d] %s" % [unit.level, unit.display_name]
		_name.add_theme_color_override(&"font_color", UiKit.GOOD if friendly else UiKit.GOLD_BRIGHT)
		var notes: Array[String] = []
		if stats.weak_element != SkillData.Element.NONE:
			notes.append("Fraqueza: %s" % SkillData.ELEMENT_NAMES[stats.weak_element])
		if stats.strong_element != SkillData.Element.NONE:
			notes.append("Resiste: %s" % SkillData.ELEMENT_NAMES[stats.strong_element])
		_detail.text = "   ".join(notes)
		_detail.visible = not notes.is_empty()
	_bar.value = unit.hp_ratio()
	_value.text = "%d / %d" % [ceili(unit.hp), unit.stats.max_hp]
