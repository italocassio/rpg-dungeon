class_name StateMachine
extends RefCounted
## Máquina de estados finita usada por monstros e companheiros.

signal state_changed(previous: StringName, next: StringName)

var current_name: StringName = &""

var _states: Dictionary[StringName, ActorState] = {}
var _current: ActorState


func add(state_name: StringName, state: ActorState) -> void:
	state.machine = self
	_states[state_name] = state


func start(state_name: StringName) -> void:
	transition(state_name)


func transition(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_error("Estado inexistente: %s" % state_name)
		return
	if state_name == current_name:
		return
	var previous: StringName = current_name
	if _current != null:
		_current.exit()
	current_name = state_name
	_current = _states[state_name]
	_current.enter()
	state_changed.emit(previous, state_name)


func physics_update(delta: float) -> void:
	if _current != null:
		_current.physics_update(delta)
