class_name PartyMember
extends RefCounted
## Companheiro encontrado na busca de grupo (simulada no MVP).

var display_name: String
var class_data: ClassData
var level: int


func _init(member_name: String, member_class: ClassData, member_level: int) -> void:
	display_name = member_name
	class_data = member_class
	level = member_level
