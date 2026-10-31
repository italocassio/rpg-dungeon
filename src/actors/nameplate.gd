class_name Nameplate
extends Node3D
## Nome e barra de vida flutuantes sobre monstros e aliados.

const BAR_WIDTH := 1.1
const VISIBLE_DISTANCE := 26.0
const DISTANCE_SCALE := 0.075
const MIN_SCALE := 0.32
const MAX_SCALE := 1.5

var combatant: Combatant
var _label: Label3D
var _fill: MeshInstance3D
var _base_scale: float = 1.0


func setup(unit: Combatant, text: String, color: Color, height: float, width_scale: float = 1.0) -> void:
	combatant = unit
	position.y = height
	_label = Label3D.new()
	_label.text = text
	_label.font_size = 30
	_label.outline_size = 8
	_label.modulate = color
	_label.pixel_size = 0.0065
	_label.position.y = 0.14
	_label.no_depth_test = true
	_label.render_priority = 5
	_label.outline_render_priority = 4
	add_child(_label)
	var back := MeshInstance3D.new()
	back.mesh = _bar_mesh(Color(0.03, 0.03, 0.05, 0.85))
	add_child(back)
	_fill = MeshInstance3D.new()
	_fill.mesh = _bar_mesh(color.darkened(0.1))
	_fill.position.z = 0.002
	add_child(_fill)
	for bar: MeshInstance3D in [back, _fill]:
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_base_scale = width_scale
	unit.health_changed.connect(_on_health_changed)


func _bar_mesh(color: Color) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(BAR_WIDTH, 0.075)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = 3
	mesh.material = material
	return mesh


func _on_health_changed(current: float, maximum: float) -> void:
	var ratio: float = clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	_fill.scale.x = maxf(ratio, 0.001)
	_fill.position.x = -BAR_WIDTH * 0.5 * (1.0 - ratio)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var distance: float = global_position.distance_to(camera.global_position)
	visible = distance < VISIBLE_DISTANCE and combatant != null and combatant.is_alive()
	if visible:
		# Só gira em Y e compensa a distância: mantém o tamanho legível de perto e de longe.
		var offset: Vector3 = camera.global_position - global_position
		global_rotation = Vector3(0.0, atan2(offset.x, offset.z), 0.0)
		scale = Vector3.ONE * clampf(distance * DISTANCE_SCALE, MIN_SCALE, MAX_SCALE) * _base_scale
