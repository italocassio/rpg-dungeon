class_name ActorState
extends RefCounted
## Estado de IA. Subclasses recebem o dono por construtor.

var machine: StateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
