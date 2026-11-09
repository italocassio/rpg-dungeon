class_name SkillTreeView
extends HBoxContainer
## Árvore de habilidades somente leitura: níveis à esquerda e a explicação fixa à direita.
## Passar o mouse troca a explicação, que permanece na última habilidade.

const WINDOW_SIZE := Vector2(800.0, 520.0)
const TREE_WIDTH := 262.0

var _sheet: CharacterSheet
var _describe: Callable = Callable()
var _card: SkillCard
var _slots: Dictionary[SkillData, SkillSlot] = {}
var _selected: SkillData


## `describe` recebe a SkillData e devolve o SkillInfo: a janela nunca toca em atributos.
func bind(sheet: CharacterSheet, describe: Callable) -> void:
	_sheet = sheet
	_describe = describe
	add_theme_constant_override(&"separation", 20)
	var class_data: ClassData = sheet.class_data
	var tree := UiKit.vbox(14)
	tree.custom_minimum_size.x = TREE_WIDTH
	add_child(tree)
	_add_tier(tree, "Ataque básico", [Hotbar.BASIC_KEY], [class_data.basic_attack])
	_add_tier(tree, "Habilidades", Hotbar.SKILL_KEYS, class_data.skills)
	_add_tier(tree, "Suprema", Hotbar.SKILL_KEYS.slice(class_data.skills.size()), [class_data.ultimate])
	var hint := UiKit.label("Passe o mouse sobre uma habilidade para ler a explicação.", 12, UiKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tree.add_child(hint)
	_card = SkillCard.new()
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_card)
	sheet.changed.connect(_refresh)
	select(class_data.basic_attack)


func _exit_tree() -> void:
	if _sheet != null and _sheet.changed.is_connected(_refresh):
		_sheet.changed.disconnect(_refresh)


func select(skill: SkillData) -> void:
	_selected = skill
	for candidate: SkillData in _slots:
		_slots[candidate].selected = candidate == skill
	_refresh()


func _add_tier(tree: VBoxContainer, heading: String, keys: Array[String], skills: Array[SkillData]) -> void:
	tree.add_child(UiKit.label(heading, 15, UiKit.SYSTEM_LINE, UiKit.title_font()))
	var row := UiKit.hbox(6)
	tree.add_child(row)
	for i in skills.size():
		var skill: SkillData = skills[i]
		var slot: SkillSlot = SkillSlot.for_skill(skill, keys[i])
		slot.mouse_entered.connect(select.bind(skill))
		row.add_child(slot)
		_slots[skill] = slot


func _refresh() -> void:
	_card.show_info(_describe.call(_selected))
