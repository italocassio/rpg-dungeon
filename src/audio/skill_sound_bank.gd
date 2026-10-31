class_name SkillSoundBank
extends Resource
## Sons de habilidade e a mixagem das vozes no mundo (editáveis no Inspector).

@export var sounds: Array[SkillSoundData] = []

@export_group("Mixagem")
## Aliados ficam abaixo do jogador para os sons dele não se perderem na luta.
@export_range(-24.0, 0.0, 0.5, "suffix:dB") var ally_volume_db: float = -8.0
## Distância que mantém o volume cheio; a partir dela o som cai pela metade a cada dobro.
@export_range(1.0, 30.0, 0.5, "suffix:m") var unit_size: float = 6.0
@export_range(10.0, 120.0, 1.0, "suffix:m") var max_distance: float = 55.0
