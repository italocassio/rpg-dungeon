class_name SpawnGroupData
extends Resource
## Grupo de monstros em torno de um ponto do mapa.

@export var monster: MonsterData
@export var count: int = 1
@export var position: Vector2 = Vector2.ZERO
@export var spread: float = 4.0
