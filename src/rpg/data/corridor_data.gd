class_name CorridorData
extends Resource
## Corredor poligonal ligando salas.

@export var points: PackedVector2Array = PackedVector2Array()
@export var width: float = 7.0
@export var wall_height: float = 5.5
@export var vault_height: float = 2.2
## Coloca a grande porta de madeira neste corredor (ponto médio do 1º trecho).
@export var has_gate_door: bool = false
