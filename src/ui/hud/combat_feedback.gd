class_name CombatFeedback
extends Control
## Mira, barra de conjuração, avisos centrais, números de dano e respostas visuais de impacto.

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.7, 0.05, 0.03, 1.0);
uniform float strength = 0.0;
void fragment() {
	float d = distance(UV, vec2(0.5));
	float edge = smoothstep(0.32, 0.72, d);
	COLOR = vec4(tint.rgb, edge * strength);
}
"""

var _run: DungeonRun
var _player: PlayerController
var _combat: PlayerCombat
var _cross_color := Color.WHITE
var _hit_marker: float = 0.0
var _cast_panel: PanelContainer
var _cast_bar: ProgressBar
var _cast_name: Label
var _prompt: Label
var _notice: Label
var _zone: Label
var _respawn: Label
var _vignette: ColorRect
var _vignette_material: ShaderMaterial
var _vignette_strength: float = 0.0
var _notice_tween: Tween
var _zone_tween: Tween


func bind(run: DungeonRun) -> void:
	_run = run
	_player = run.player
	_combat = run.combat
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(self)
	_build()
	_player.combatant.damaged.connect(_on_player_damaged)
	_player.combatant.healed.connect(_on_player_healed)
	_player.combatant.attack_avoided.connect(func(_s: Combatant) -> void: Vfx.floating_text(get_tree(), _player.camera.global_position + _player.aim_direction() * 2.0, "Esquiva", UiKit.SYSTEM_TEXT, 30))
	_player.caster.cast_started.connect(_on_cast_started)
	_player.caster.skill_fired.connect(func(_skill: SkillData, _aim: SkillAim) -> void: _cast_panel.visible = false)
	_player.caster.cast_interrupted.connect(func(_skill: SkillData) -> void: _cast_panel.visible = false)
	_combat.hovered_changed.connect(_on_hovered)
	_combat.interact_prompt_changed.connect(func(text: String) -> void: _prompt.text = "[E]  %s" % text if text != "" else "")
	_combat.skill_refused.connect(show_notice)
	run.enemy_spawned.connect(_watch_enemy)
	run.player_respawning.connect(_on_respawning)
	for node in get_tree().get_nodes_in_group(&"enemies"):
		_watch_enemy(node)
	for bot in run.bots:
		bot.combatant.healed.connect(_on_ally_healed.bind(bot.combatant))
	Events.zone_entered.connect(_on_zone_entered)


func _build() -> void:
	_vignette = ColorRect.new()
	UiKit.full_rect(_vignette)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	_vignette_material = ShaderMaterial.new()
	_vignette_material.shader = shader
	_vignette.material = _vignette_material
	add_child(_vignette)

	_zone = UiKit.shadowed(UiKit.label("", 40, UiKit.GOLD_BRIGHT, UiKit.title_font()), 8)
	_center_label(_zone, 0.19)
	_notice = UiKit.shadowed(UiKit.label("", 18, UiKit.BAD, UiKit.bold_font()))
	_center_label(_notice, 0.66)
	_prompt = UiKit.shadowed(UiKit.label("", 19, UiKit.GOLD_BRIGHT, UiKit.bold_font()))
	_center_label(_prompt, 0.58)
	_respawn = UiKit.shadowed(UiKit.label("", 30, UiKit.BAD, UiKit.title_font()), 7)
	_center_label(_respawn, 0.4)

	_cast_panel = PanelContainer.new()
	_cast_panel.add_theme_stylebox_override(&"panel", UiKit.panel_style(5))
	UiKit.fit_rect(_cast_panel, 0.5, 0.72, 0.5, 0.72, Rect2(-150.0, 0.0, 150.0, 44.0))
	_cast_panel.visible = false
	add_child(_cast_panel)
	var column := UiKit.vbox(2)
	_cast_panel.add_child(column)
	_cast_name = UiKit.label("", 13, UiKit.GOLD_BRIGHT, UiKit.bold_font())
	_cast_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_cast_name)
	_cast_bar = UiKit.bar(Color("e8b44a"), 10.0)
	column.add_child(_cast_bar)


func _center_label(label: Label, height_ratio: float) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.fit_rect(label, 0.0, height_ratio, 1.0, height_ratio, Rect2(0.0, 0.0, 0.0, 44.0))
	add_child(label)


func _watch_enemy(enemy: Enemy) -> void:
	enemy.combatant.damaged.connect(_on_enemy_damaged.bind(enemy.combatant))
	enemy.combatant.attack_avoided.connect(func(source: Combatant) -> void:
		if source == _player.combatant:
			Vfx.floating_text(get_tree(), enemy.combatant.center_position(), "Errou", UiKit.MUTED, 30))


func _on_enemy_damaged(amount: float, source: Combatant, is_crit: bool, _threat: float, unit: Combatant) -> void:
	if source != _player.combatant or amount <= 0.0:
		return
	var point: Vector3 = unit.center_position() + Vector3.UP * 0.4
	if is_crit:
		Vfx.floating_text(get_tree(), point, "%d!" % amount, Color("ffd24a"), 58)
		_player.add_trauma(0.22)
	else:
		Vfx.floating_text(get_tree(), point, str(int(amount)), Color("fff2d8"), 40)
	_hit_marker = 0.14


func _on_player_damaged(amount: float, _source: Combatant, _is_crit: bool, _threat: float) -> void:
	if amount <= 0.0:
		return
	var share: float = amount / maxf(_player.combatant.stats.max_hp, 1.0)
	_player.add_trauma(clampf(share * 2.2, 0.1, 0.6))
	_vignette_strength = minf(_vignette_strength + 0.35 + share * 1.5, 0.9)
	Vfx.floating_text(get_tree(), _player.camera.global_position + _player.aim_direction() * 1.6 + Vector3.DOWN * 0.3, "-%d" % amount, Color("ff6a5a"), 34)


func _on_player_healed(amount: float, _source: Combatant) -> void:
	if amount >= 1.0:
		Vfx.floating_text(get_tree(), _player.camera.global_position + _player.aim_direction() * 1.6, "+%d" % amount, UiKit.GOOD, 34)


func _on_ally_healed(amount: float, source: Combatant, unit: Combatant) -> void:
	if amount >= 1.0 and source == _player.combatant:
		Vfx.floating_text(get_tree(), unit.center_position() + Vector3.UP, "+%d" % amount, UiKit.GOOD, 36)


func _on_cast_started(skill: SkillData, duration: float) -> void:
	_cast_name.text = skill.display_name
	_cast_panel.visible = duration > 0.15


func _on_hovered(unit: Combatant) -> void:
	if unit == null:
		_cross_color = Color.WHITE
	elif unit.team == _player.combatant.team:
		_cross_color = UiKit.GOOD
	else:
		_cross_color = Color("ff5a4a")
	queue_redraw()


func _on_zone_entered(zone_name: String) -> void:
	_zone.text = zone_name
	if _zone_tween != null and _zone_tween.is_valid():
		_zone_tween.kill()
	_zone.modulate.a = 0.0
	_zone_tween = create_tween()
	_zone_tween.tween_property(_zone, "modulate:a", 1.0, 0.5)
	_zone_tween.tween_interval(1.8)
	_zone_tween.tween_property(_zone, "modulate:a", 0.0, 0.9)


func show_notice(text: String) -> void:
	_notice.text = text
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_interval(0.9)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.4)


func _on_respawning(seconds: float) -> void:
	_respawn.visible = seconds > 0.0


func _process(delta: float) -> void:
	if _run == null:
		return
	_hit_marker = maxf(_hit_marker - delta, 0.0)
	_vignette_strength = maxf(_vignette_strength - delta * 1.3, 0.0)
	var low_health: float = 0.3 * clampf(1.0 - _player.combatant.hp_ratio() / 0.3, 0.0, 1.0)
	_vignette_material.set_shader_parameter("strength", maxf(_vignette_strength, low_health))
	if _player.caster.is_casting():
		_cast_bar.value = _player.caster.cast_progress()
	if _run.respawn_left > 0.0:
		_respawn.text = "Você caiu. Retornando em %d..." % ceili(_run.respawn_left)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var color: Color = _cross_color
	draw_circle(center, 2.0, Color(0.0, 0.0, 0.0, 0.7))
	draw_circle(center, 1.3, color)
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(center + direction * 7.0, center + direction * 13.0, Color(0.0, 0.0, 0.0, 0.6), 3.0)
		draw_line(center + direction * 7.0, center + direction * 13.0, color, 1.3)
	if _hit_marker > 0.0:
		var alpha: float = _hit_marker / 0.14
		for corner: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(center + corner * 9.0, center + corner * 17.0, Color(1.0, 1.0, 1.0, alpha), 2.0)
