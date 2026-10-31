class_name PartyFinder
extends RefCounted
## Busca de grupo simulada: completa os papéis que faltam (tanque, cura, dano).
## É o ponto de troca natural por um serviço de matchmaking real no futuro.

const NAMES: Array[String] = [
	"Kael", "Lyra", "Thorn", "Mira", "Dante", "Selene", "Ragnar", "Yuna",
	"Orin", "Freya", "Tavin", "Hana", "Iago", "Astra", "Vex", "Nyx",
]


static func members_needed(player_class: ClassData, catalog: GameCatalog, party_size: int) -> Array[ClassData]:
	var needed: Array[ClassData] = []
	var roles: Array[ClassData.Role] = [ClassData.Role.TANK, ClassData.Role.HEALER]
	for role in roles:
		if player_class.role != role:
			needed.append(_class_with_role(catalog, role))
	while needed.size() < party_size - 1:
		needed.append(_class_with_role(catalog, ClassData.Role.DAMAGE))
	return needed


static func assemble(player_class: ClassData, level: int, catalog: GameCatalog, party_size: int, rng: RandomNumberGenerator) -> Array[PartyMember]:
	var names: Array[String] = NAMES.duplicate()
	var members: Array[PartyMember] = []
	for class_data in members_needed(player_class, catalog, party_size):
		var picked: String = names.pop_at(rng.randi_range(0, names.size() - 1))
		members.append(PartyMember.new(picked, class_data, maxi(level + rng.randi_range(-1, 1), 1)))
	return members


static func _class_with_role(catalog: GameCatalog, role: ClassData.Role) -> ClassData:
	for class_data in catalog.classes:
		if class_data.role == role:
			return class_data
	return catalog.classes[0]
