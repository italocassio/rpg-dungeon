class_name TreasureChest
extends Node3D
## Baú das salas laterais. Ao abrir, entrega o conteúdo de DungeonData.chest_drops.

signal looted(chest: TreasureChest)

var is_open: bool = false
var _lid: Node3D


func _ready() -> void:
	add_to_group(&"interactable")
	var wood: Material = DungeonMaterials.wood()
	var iron: Material = DungeonMaterials.iron()
	var body := MeshInstance3D.new()
	body.mesh = MeshKit.box(Vector3(1.5, 0.75, 0.95))
	body.position.y = 0.38
	body.material_override = wood
	add_child(body)

	_lid = Node3D.new()
	_lid.position = Vector3(0.0, 0.75, -0.47)
	add_child(_lid)
	var lid_mesh := MeshInstance3D.new()
	lid_mesh.mesh = MeshKit.box(Vector3(1.56, 0.34, 1.0))
	lid_mesh.position = Vector3(0.0, 0.17, 0.47)
	lid_mesh.material_override = wood
	_lid.add_child(lid_mesh)

	for x: float in [-0.56, 0.0, 0.56]:
		var strap := MeshInstance3D.new()
		strap.mesh = MeshKit.box(Vector3(0.12, 0.8, 1.0))
		strap.position = Vector3(x, 0.38, 0.0)
		strap.material_override = iron
		add_child(strap)

	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.1, 0.3)
	glow.light_color = Color("ffd76a")
	glow.light_energy = 1.4
	glow.omni_range = 5.0
	add_child(glow)


func interact_label() -> String:
	return "Abrir Baú"


func interact(_player: Node) -> void:
	if is_open:
		return
	is_open = true
	remove_from_group(&"interactable")
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_lid, "rotation:x", -1.9, 0.6)
	looted.emit(self)
