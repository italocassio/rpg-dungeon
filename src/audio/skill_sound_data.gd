class_name SkillSoundData
extends Resource
## Sons de uma habilidade, um por momento em que o jogo a dispara.

## Id da habilidade, ou guard_<classe> para a defesa.
@export var id: StringName
## Toca desde o início da conjuração e é cortado se ela for interrompida.
@export var cast: SoundClip
## Desligado quando o som de conjuração já traz o golpe no instante do disparo.
@export var cut_cast_on_fire: bool = true
@export var fire: SoundClip
@export var impact: SoundClip
## Repete enquanto a zona da habilidade existir.
@export var loop: SoundClip
