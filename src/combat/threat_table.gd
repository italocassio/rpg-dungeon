class_name ThreatTable
extends RefCounted
## Agressividade de um monstro: escolhe o alvo atual; provocação tem prioridade.

var _threat: Dictionary[Combatant, float] = {}


func add(source: Combatant, amount: float) -> void:
	if source == null:
		return
	_threat[source] = _threat.get(source, 0.0) + amount


func is_empty() -> bool:
	return _threat.is_empty()


func clear() -> void:
	_threat.clear()


func top_target(owner_unit: Combatant) -> Combatant:
	if is_instance_valid(owner_unit.taunted_by) and owner_unit.taunted_by.is_alive():
		return owner_unit.taunted_by
	var best: Combatant = null
	var best_value: float = -1.0
	# Sem tipo no laço: a chave pode ser um objeto já liberado.
	for unit: Variant in _threat.keys():
		if not is_instance_valid(unit) or not (unit as Combatant).is_alive():
			_threat.erase(unit)
			continue
		if _threat[unit] > best_value:
			best_value = _threat[unit]
			best = unit
	return best
