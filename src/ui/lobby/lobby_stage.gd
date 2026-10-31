class_name LobbyStage
extends Node3D
## Palco 3D do saguão: reutiliza o gerador de masmorra numa sala só, com o Portão ao fundo.

const CAMERA_POSITION := Vector3(0.9, 1.45, 3.4)
const CAMERA_TARGET := Vector3(2.2, 1.35, -4.0)
const HERO_POSITION := Vector3(-0.5, 0.0, -0.6)

var _hero: CreatureRig
var _turntable: Node3D


func build(gate_color: Color) -> void:
	add_to_group(&"world_root")
	var hall := DungeonData.new()
	var room := RoomData.new()
	room.kind = RoomData.Kind.ENTRANCE
	room.display_name = "Salão dos Caçadores"
	room.center = Vector2.ZERO
	room.radius = 14.0
	room.wall_height = 8.0
	room.dome_height = 5.0
	var rooms: Array[RoomData] = [room]
	hall.rooms = rooms
	var world := DungeonWorld.new()
	add_child(world)
	world.build(hall, gate_color)
	var camera := Camera3D.new()
	camera.fov = 52.0
	add_child(camera)
	camera.look_at_from_position(CAMERA_POSITION, CAMERA_TARGET)
	camera.make_current()
	world.focus = camera
	_turntable = Node3D.new()
	_turntable.position = HERO_POSITION
	_turntable.rotation.y = PI + 0.35
	add_child(_turntable)
	var key := OmniLight3D.new()
	key.position = Vector3(1.2, 2.6, 1.6)
	key.light_color = Color("ffe2c0")
	key.light_energy = 2.6
	key.omni_range = 7.0
	add_child(key)


func show_hero(class_id: StringName, armor: ItemData, weapon: ItemData) -> void:
	if _hero != null:
		_hero.queue_free()
	_hero = CreatureFactory.build_hero(class_id, armor.armor_tint, weapon.weapon_model, weapon.rarity)
	_turntable.add_child(_hero)


func _process(delta: float) -> void:
	if _hero != null:
		_hero.animate(delta, 0.0)
		_turntable.rotation.y += delta * 0.12
