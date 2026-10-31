class_name MusicConfig
extends Resource
## Faixas e mixagem da música (editáveis no Inspector).

@export_group("Faixas")
@export var dungeon_track: AudioStream
@export var boss_track: AudioStream

@export_group("Mixagem")
@export_range(-40.0, 0.0, 0.5, "suffix:dB") var dungeon_volume_db: float = -8.0
@export_range(-40.0, 0.0, 0.5, "suffix:dB") var boss_volume_db: float = -6.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var crossfade_seconds: float = 1.5
@export_range(0.0, 10.0, 0.1, "suffix:s") var fade_out_seconds: float = 1.0
