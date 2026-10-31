class_name SoundClip
extends Resource
## Um som do jogo: variações sorteadas, ganho de mixagem e variação de tom.

@export var variations: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db: float = 0.0
## Variação do tom para disfarçar a repetição (0.04 = ±4%).
@export_range(0.0, 0.25, 0.01) var pitch_jitter: float = 0.0

var _last_index: int = -1


## Nunca repete a variação anterior: golpes seguidos não podem soar iguais.
func pick(rng: RandomNumberGenerator) -> AudioStream:
	var count: int = variations.size()
	if count == 0:
		return null
	var index: int = rng.randi_range(0, maxi(count - 2, 0))
	if count > 1 and _last_index >= 0 and index >= _last_index:
		index += 1
	_last_index = index
	return variations[index]


func random_pitch(rng: RandomNumberGenerator) -> float:
	return 1.0 + rng.randf_range(-pitch_jitter, pitch_jitter)
