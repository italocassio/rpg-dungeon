class_name RoomData
extends Resource
## Sala circular do mapa (coordenadas em metros, XZ).

enum Kind { ENTRANCE, NORMAL, SIDE, ANTECHAMBER, BOSS }

@export var id: StringName
@export var display_name: String
@export var kind: Kind = Kind.NORMAL
@export var center: Vector2 = Vector2.ZERO
@export var radius: float = 12.0
@export var wall_height: float = 7.0
@export var dome_height: float = 4.0
@export var has_chest: bool = false
