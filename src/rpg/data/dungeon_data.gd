class_name DungeonData
extends Resource
## Masmorra completa. Toda masmorra precisa de `boss` (validado nos testes).

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rooms: Array[RoomData] = []
@export var corridors: Array[CorridorData] = []
@export var spawn_groups: Array[SpawnGroupData] = []
@export var boss: MonsterData
@export var ranks: Array[GateRankData] = []
## Quantidade de monstros necessária para abrir a porta do chefe.
@export var kills_to_open_gate: int = 12
## Conteúdo dos baús das salas laterais.
@export var chest_drops: Array[DropEntry] = []
## Cor do brilho dos inimigos desta masmorra, passada à arte por CreatureFactory.build.
@export var enemy_glow: Color = Color("7FE0FF")


func room_of_kind(kind: RoomData.Kind) -> RoomData:
	for room in rooms:
		if room.kind == kind:
			return room
	return null
