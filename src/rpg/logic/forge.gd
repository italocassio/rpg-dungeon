class_name Forge
extends RefCounted
## Regras de forja: verifica custos, consome materiais e entrega o equipamento.

enum Failure { NONE, MISSING_MATERIALS, MISSING_CRYSTALS, WRONG_CLASS }


static func check(recipe: RecipeData, sheet: CharacterSheet) -> Failure:
	if not recipe.result.is_usable_by(sheet.class_data.id):
		return Failure.WRONG_CLASS
	if sheet.inventory.mana_crystals < recipe.mana_crystal_cost:
		return Failure.MISSING_CRYSTALS
	for ingredient: ItemData in recipe.ingredients:
		if sheet.inventory.count_of(ingredient.id) < recipe.ingredients[ingredient]:
			return Failure.MISSING_MATERIALS
	return Failure.NONE


## Atômica: nada é consumido se a receita não puder ser concluída.
static func craft(recipe: RecipeData, sheet: CharacterSheet) -> bool:
	if check(recipe, sheet) != Failure.NONE:
		return false
	for ingredient: ItemData in recipe.ingredients:
		sheet.inventory.remove(ingredient.id, recipe.ingredients[ingredient])
	sheet.inventory.add_crystals(-recipe.mana_crystal_cost)
	sheet.inventory.add(recipe.result.id)
	return true
