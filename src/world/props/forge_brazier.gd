class_name ForgeBrazier
extends Node3D
## Braseiro da Forja do Gelo (ver referência): ponto de interação para forjar.

signal requested

var flame_hot := Color("ff9a3c")
var flame_cool := Color("c8341a")
var interactive: bool = true


func _ready() -> void:
	var iron: Material = DungeonMaterials.iron()
	var stand := MeshInstance3D.new()
	stand.mesh = MeshKit.lathe(PackedVector2Array([
		Vector2(0.55, 0.0), Vector2(0.5, 0.1), Vector2(0.2, 0.2), Vector2(0.13, 0.5),
		Vector2(0.2, 0.75), Vector2(0.13, 0.95), Vector2(0.28, 1.05), Vector2(0.62, 1.2),
		Vector2(0.72, 1.45), Vector2(0.6, 1.45), Vector2(0.5, 1.28),
	]), 14)
	stand.material_override = iron
	add_child(stand)

	var coals := MeshInstance3D.new()
	coals.mesh = MeshKit.cylinder(0.55, 0.45, 0.14, 12)
	coals.position.y = 1.38
	var hot := StandardMaterial3D.new()
	hot.albedo_color = Color(0.08, 0.03, 0.02)
	hot.emission_enabled = true
	hot.emission = flame_hot
	hot.emission_energy_multiplier = 2.2
	coals.material_override = hot
	add_child(coals)

	var fire := ParticleKit.flame(flame_hot, flame_cool, 0.5, 30)
	fire.position.y = 1.45
	add_child(fire)
	var sparks := ParticleKit.embers(flame_hot, 8)
	sparks.position.y = 1.6
	add_child(sparks)

	if interactive:
		add_to_group(&"interactable")


func interact_label() -> String:
	return "Usar a Forja do Gelo"


func interact(_player: Node) -> void:
	requested.emit()
