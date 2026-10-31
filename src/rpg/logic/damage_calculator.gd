class_name DamageCalculator
extends RefCounted
## Fórmulas de dano puras (sem cena), para poderem ser testadas e, no futuro, rodar no servidor.


class Outcome:
	var amount: float = 0.0
	var is_crit: bool = false
	var is_dodged: bool = false
	var element_bonus: float = 1.0


## Mitigação estilo Perfect World: retorno decrescente sobre a defesa.
static func mitigation(defense: float, balance: BalanceConfig) -> float:
	return balance.defense_constant / (balance.defense_constant + maxf(defense, 0.0))


static func element_multiplier(element: SkillData.Element, target: StatBlock, balance: BalanceConfig) -> float:
	if element == SkillData.Element.NONE:
		return 1.0
	if element == target.weak_element:
		return balance.element_weakness_multiplier
	if element == target.strong_element:
		return balance.element_resist_multiplier
	return 1.0


static func compute(
		attacker: StatBlock,
		defender: StatBlock,
		kind: SkillData.DamageKind,
		element: SkillData.Element,
		power: float,
		balance: BalanceConfig,
		rng: RandomNumberGenerator) -> Outcome:
	var outcome := Outcome.new()
	if rng.randf() < defender.dodge_chance:
		outcome.is_dodged = true
		return outcome

	var is_physical: bool = kind == SkillData.DamageKind.PHYSICAL
	var attack: float = attacker.phys_attack if is_physical else attacker.magic_attack
	var defense: float = defender.phys_defense if is_physical else defender.magic_defense
	outcome.element_bonus = element_multiplier(element, defender, balance)

	var variance: float = 1.0 + rng.randf_range(-balance.damage_variance, balance.damage_variance)
	var amount: float = attack * power * mitigation(defense, balance) * outcome.element_bonus * variance
	if rng.randf() < attacker.crit_chance:
		outcome.is_crit = true
		amount *= attacker.crit_multiplier
	outcome.amount = maxf(amount, 1.0)
	return outcome


static func heal_amount(healer: StatBlock, power: float, balance: BalanceConfig, rng: RandomNumberGenerator) -> float:
	var variance: float = 1.0 + rng.randf_range(-balance.damage_variance, balance.damage_variance)
	return healer.magic_attack * power * healer.heal_power * variance
