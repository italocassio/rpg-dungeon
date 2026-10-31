class_name DropEntry
extends Resource
## Linha de uma tabela de drop.

@export var item: ItemData
@export_range(0.0, 1.0) var chance: float = 0.5
@export var min_count: int = 1
@export var max_count: int = 1
## Rank mínimo do portão para este item poder cair (0 = E).
@export var min_rank_index: int = 0
