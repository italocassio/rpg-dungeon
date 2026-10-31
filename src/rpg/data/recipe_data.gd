class_name RecipeData
extends Resource
## Receita de forja: materiais + cristais de mana => equipamento.

@export var id: StringName
@export var result: ItemData
@export var ingredients: Dictionary[ItemData, int] = {}
@export var mana_crystal_cost: int = 0
@export var tier: int = 1
