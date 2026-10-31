class_name BotStates
extends RefCounted
## Estados dos companheiros.


class Base:
	extends ActorState
	var bot: PartyBot

	func _init(owner_bot: PartyBot) -> void:
		bot = owner_bot


class Follow:
	extends Base

	func physics_update(delta: float) -> void:
		var unit: Combatant = bot.combatant
		if bot.brain.find_enemy() != null:
			machine.transition(&"fight")
			return
		bot.brain.support_out_of_combat()
		var goal: Vector3 = bot.formation_point()
		var distance: float = bot.global_position.distance_to(goal)
		if distance > PartyBot.CATCH_UP_DISTANCE:
			bot.global_position = bot.leader.global_position + bot.leader.global_basis * bot.slot_offset.normalized()
			return
		if distance > PartyBot.FOLLOW_DISTANCE * 0.5:
			bot.move_to(goal, unit.stats.move_speed * (1.35 if distance > 10.0 else 1.0), delta)
		else:
			bot.halt()


class Fight:
	extends Base

	func physics_update(delta: float) -> void:
		if bot.combatant.is_stunned():
			bot.halt()
			return
		if not bot.brain.fight(delta):
			machine.transition(&"follow")


class Dead:
	extends Base
	var _wait: float = 0.0

	func enter() -> void:
		bot.halt()
		bot.rig.die()
		_wait = PartyBot.REVIVE_SECONDS

	## Fora de combate o companheiro levanta sozinho, para o grupo não ficar desfalcado.
	func physics_update(delta: float) -> void:
		var leader_unit: Combatant = bot.leader.get("combatant")
		if leader_unit == null or leader_unit.in_combat() or not leader_unit.is_alive():
			return
		_wait -= delta
		if _wait <= 0.0:
			bot.global_position = bot.formation_point()
			bot.combatant.revive(0.6)
