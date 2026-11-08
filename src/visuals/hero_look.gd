class_name HeroLook
extends RefCounted
## Tudo que a arte precisa saber para montar um herói. Não conhece cena nem regra de jogo.

var class_id: StringName
var armor_tier: int = 0      # 0 a 3
var armor_variant: int = 0   # 0 ou 1, só em T0
var head_tier: int = 0       # max(tier da armadura, tier do elmo)
var boots_tier: int = 0      # max(tier da armadura, tier das botas)
var weapon_model: StringName
var weapon_tier: int = 0
var weapon_rarity: ItemData.Rarity = ItemData.Rarity.COMMON


static func from_sheet(sheet: CharacterSheet) -> HeroLook:
	var armor: ItemData = sheet.equipment.get(ItemData.Kind.ARMOR)
	var weapon: ItemData = sheet.equipment.get(ItemData.Kind.WEAPON)
	var helm: ItemData = sheet.equipment.get(ItemData.Kind.HELM)
	var boots: ItemData = sheet.equipment.get(ItemData.Kind.BOOTS)
	return from_items(sheet.class_data.id, armor, weapon, helm, boots)


## Único lugar com a regra P3: o corpo segue a armadura; cabeça e botas seguem o maior tier entre a armadura e a peça.
static func from_items(hero_class: StringName, armor: ItemData, weapon: ItemData, helm: ItemData = null, boots: ItemData = null) -> HeroLook:
	var look := HeroLook.new()
	look.class_id = hero_class
	if armor != null:
		look.armor_tier = armor.look_tier
		look.armor_variant = armor.look_variant
	look.head_tier = maxi(look.armor_tier, helm.look_tier if helm != null else 0)
	look.boots_tier = maxi(look.armor_tier, boots.look_tier if boots != null else 0)
	if weapon != null:
		look.weapon_model = weapon.weapon_model
		look.weapon_tier = weapon.look_tier
		look.weapon_rarity = weapon.rarity
	return look


## Compara a aparência: todos os campos.
func equals(other: HeroLook) -> bool:
	if other == null:
		return false
	return class_id == other.class_id \
		and armor_tier == other.armor_tier \
		and armor_variant == other.armor_variant \
		and head_tier == other.head_tier \
		and boots_tier == other.boots_tier \
		and weapon_model == other.weapon_model \
		and weapon_tier == other.weapon_tier \
		and weapon_rarity == other.weapon_rarity
