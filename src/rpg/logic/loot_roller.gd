class_name LootRoller
extends RefCounted
## Sorteia drops de um monstro levando em conta o rank do portão.


class Drop:
	var item: ItemData
	var count: int

	func _init(from_item: ItemData, amount: int) -> void:
		item = from_item
		count = amount


static func roll(monster: MonsterData, rank: GateRankData, rng: RandomNumberGenerator) -> Array[Drop]:
	var result: Array[Drop] = []
	for entry in monster.drops:
		if rank.index < entry.min_rank_index:
			continue
		if rng.randf() <= entry.chance:
			result.append(Drop.new(entry.item, rng.randi_range(entry.min_count, entry.max_count)))
	return result


static func roll_crystals(monster: MonsterData, rank: GateRankData, rng: RandomNumberGenerator) -> int:
	var base: int = rng.randi_range(monster.mana_crystals.x, monster.mana_crystals.y)
	return roundi(base * rank.crystal_multiplier)
