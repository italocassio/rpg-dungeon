class_name GateDoor
extends Node3D
## Grande porta dupla de madeira e ferro que guarda a sala do chefe.

signal opened

const OPEN_ANGLE := 1.75

var interact_radius: float = 7.5
var width: float = 8.0
var height: float = 8.5
var is_open: bool = false
var unlock_check: Callable = Callable()

var _left: Node3D
var _right: Node3D
var _blocker: CollisionShape3D


func _ready() -> void:
	add_to_group(&"interactable")
	_left = _build_leaf(-1.0)
	_right = _build_leaf(1.0)
	var lintel := MeshInstance3D.new()
	lintel.mesh = MeshKit.box(Vector3(width + 1.6, 1.0, 1.1))
	lintel.position = Vector3(0.0, height + 0.4, 0.0)
	lintel.material_override = DungeonMaterials.stone_prop(0.4)
	add_child(lintel)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	_blocker = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width + 2.0, height + 2.0, 0.8)
	_blocker.shape = shape
	_blocker.position.y = height * 0.5
	body.add_child(_blocker)
	add_child(body)


func _build_leaf(side: float) -> Node3D:
	var hinge := Node3D.new()
	hinge.position = Vector3(side * width * 0.5, 0.0, 0.0)
	add_child(hinge)
	var leaf_width: float = width * 0.5
	var iron: Material = DungeonMaterials.iron()

	var planks := MeshInstance3D.new()
	planks.mesh = MeshKit.box(Vector3(leaf_width, height, 0.42))
	planks.position = Vector3(-side * leaf_width * 0.5, height * 0.5, 0.0)
	planks.material_override = DungeonMaterials.wood()
	hinge.add_child(planks)

	for band in 4:
		var strap := MeshInstance3D.new()
		strap.mesh = MeshKit.box(Vector3(leaf_width * 0.98, 0.34, 0.54))
		strap.position = Vector3(-side * leaf_width * 0.5, height * (0.14 + band * 0.24), 0.0)
		strap.material_override = iron
		hinge.add_child(strap)
		for stud in 5:
			var rivet := MeshInstance3D.new()
			rivet.mesh = MeshKit.sphere(0.075, 6)
			rivet.position = strap.position + Vector3((stud - 2) * leaf_width * 0.2, 0.0, 0.3)
			rivet.material_override = iron
			hinge.add_child(rivet)

	var knocker := MeshInstance3D.new()
	knocker.mesh = MeshKit.torus(0.18, 0.29, 14)
	knocker.rotation.x = PI * 0.5
	knocker.position = Vector3(-side * (leaf_width - 0.65), height * 0.45, 0.3)
	knocker.material_override = iron
	hinge.add_child(knocker)
	return hinge


func interact_label() -> String:
	return "Abrir a Grande Porta"


func interact(_player: Node) -> void:
	if is_open:
		return
	if unlock_check.is_valid() and not bool(unlock_check.call()):
		return
	open()


func open() -> void:
	if is_open:
		return
	is_open = true
	remove_from_group(&"interactable")
	_blocker.set_deferred("disabled", true)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_left, "rotation:y", OPEN_ANGLE, 2.2)
	tween.tween_property(_right, "rotation:y", -OPEN_ANGLE, 2.2)
	opened.emit()
