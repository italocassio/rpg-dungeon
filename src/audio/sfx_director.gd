class_name SfxDirector
extends Node
## Toca os sons de habilidade ouvindo Events. Nenhum sistema de jogo conhece este nó.

const BANK_PATH := "res://data/skill_sounds.tres"
const BUS := &"SFX"
const VOICE_COUNT := 24
const CUT_SECONDS := 0.07
const CUT_DB := -60.0
## Faixa aceita por AudioStreamPlayer3D.max_db.
const MIN_PEAK_DB := -24.0
const MAX_PEAK_DB := 6.0
## O mesmo som em quadros seguidos (aliados batendo juntos) só soma volume.
const MIN_REPEAT_FRAMES := 3

var bank: SkillSoundBank

var _sounds: Dictionary[StringName, SkillSoundData] = {}
var _voices: Array[AudioStreamPlayer3D] = []
## Voz da conjuração em curso, pelo instance_id do conjurador.
var _casts: Dictionary[int, AudioStreamPlayer3D] = {}
var _cuts: Dictionary[AudioStreamPlayer3D, Tween] = {}
var _last_frame: Dictionary[SoundClip, int] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if bank == null and ResourceLoader.exists(BANK_PATH):
		bank = load(BANK_PATH) as SkillSoundBank
	if bank == null:
		push_warning("Sons de habilidade desativados: %s ausente." % BANK_PATH)
		return
	_rng.randomize()
	for sound: SkillSoundData in bank.sounds:
		_sounds[sound.id] = sound
	for _i in VOICE_COUNT:
		_voices.append(_add_voice())
	Events.skill_cast_started.connect(_on_skill_cast_started)
	Events.skill_cast_stopped.connect(_on_skill_cast_stopped)
	Events.skill_fired.connect(_on_skill_fired)
	Events.skill_impacted.connect(_on_skill_impacted)
	Events.heal_zone_opened.connect(_on_heal_zone_opened)
	Events.guard_raised.connect(_on_guard_raised)
	Events.dungeon_exited.connect(_on_dungeon_exited)


func _add_voice() -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.bus = BUS
	voice.unit_size = bank.unit_size
	voice.max_distance = bank.max_distance
	# O filtro de distância conta o volume da voz: abafaria todo som com ganho negativo.
	voice.attenuation_filter_db = 0.0
	add_child(voice)
	return voice


func _on_skill_cast_started(skill: SkillData, caster: Combatant) -> void:
	var sound: SkillSoundData = _sounds.get(skill.id)
	if sound == null:
		return
	var voice: AudioStreamPlayer3D = _play_from_caster(sound.cast, caster)
	if voice != null:
		_casts[caster.get_instance_id()] = voice


func _on_skill_cast_stopped(_skill: SkillData, caster: Combatant) -> void:
	_cut_cast(caster)


func _on_skill_fired(skill: SkillData, caster: Combatant) -> void:
	var sound: SkillSoundData = _sounds.get(skill.id)
	if sound == null:
		return
	if sound.cut_cast_on_fire:
		_cut_cast(caster)
	else:
		_casts.erase(caster.get_instance_id())
	_play_from_caster(sound.fire, caster)


func _on_skill_impacted(skill: SkillData, caster: Combatant, point: Vector3) -> void:
	var sound: SkillSoundData = _sounds.get(skill.id)
	if sound != null:
		_play(sound.impact, caster, point, true)


func _on_heal_zone_opened(zone: HealZone) -> void:
	var sound: SkillSoundData = _sounds.get(zone.skill.id)
	if sound == null:
		return
	var voice: AudioStreamPlayer3D = _play(sound.loop, zone.caster, zone.global_position, true)
	if voice != null:
		zone.tree_exiting.connect(_cut.bind(voice), CONNECT_ONE_SHOT)


func _on_guard_raised(class_id: StringName, unit: Combatant) -> void:
	var sound: SkillSoundData = _sounds.get(StringName("guard_%s" % class_id))
	if sound != null:
		_play_from_caster(sound.fire, unit)


func _on_dungeon_exited() -> void:
	_casts.clear()
	for voice: AudioStreamPlayer3D in _voices:
		_cut(voice)


func _is_player(unit: Combatant) -> bool:
	return unit.actor() is PlayerController


## Em primeira pessoa, posicionar o próprio som só o faria dançar entre os ouvidos.
func _play_from_caster(clip: SoundClip, caster: Combatant) -> AudioStreamPlayer3D:
	return _play(clip, caster, caster.world_position(), not _is_player(caster))


func _play(clip: SoundClip, source: Combatant, point: Vector3, positional: bool) -> AudioStreamPlayer3D:
	if clip == null or clip.variations.is_empty():
		return null
	var is_own: bool = _is_player(source)
	var frame: int = Engine.get_process_frames()
	if not is_own and frame - _last_frame.get(clip, -MIN_REPEAT_FRAMES) < MIN_REPEAT_FRAMES:
		return null
	var voice: AudioStreamPlayer3D = _free_voice()
	if voice == null:
		return null
	_last_frame[clip] = frame
	_cancel_cut(voice)
	# A voz de uma conjuração que acabou sozinha não pode ser cortada pelo dono antigo.
	var previous_owner: Variant = _casts.find_key(voice)
	if previous_owner != null:
		_casts.erase(previous_owner)
	var volume: float = clip.volume_db + (0.0 if is_own else bank.ally_volume_db)
	voice.stream = clip.pick(_rng)
	voice.volume_db = volume
	# O padrão de max_db passaria por cima do volume quando a fonte está perto do ouvinte.
	voice.max_db = clampf(volume, MIN_PEAK_DB, MAX_PEAK_DB)
	voice.pitch_scale = clip.random_pitch(_rng)
	voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE if positional else AudioStreamPlayer3D.ATTENUATION_DISABLED
	voice.panning_strength = 1.0 if positional else 0.0
	voice.global_position = point
	voice.play()
	return voice


func _free_voice() -> AudioStreamPlayer3D:
	for voice: AudioStreamPlayer3D in _voices:
		if not voice.playing:
			return voice
	return null


func _cut_cast(caster: Combatant) -> void:
	var id: int = caster.get_instance_id()
	if _casts.has(id):
		_cut(_casts[id])
		_casts.erase(id)


## Fade curto: parar a onda no meio estala.
func _cut(voice: AudioStreamPlayer3D) -> void:
	if not is_inside_tree() or not voice.playing:
		return
	_cancel_cut(voice)
	var tween: Tween = create_tween()
	tween.tween_property(voice, "volume_db", CUT_DB, CUT_SECONDS)
	tween.tween_callback(voice.stop)
	_cuts[voice] = tween


## Um corte atrasado não pode derrubar o som novo que reaproveitou a voz.
func _cancel_cut(voice: AudioStreamPlayer3D) -> void:
	if _cuts.has(voice):
		_cuts[voice].kill()
		_cuts.erase(voice)
