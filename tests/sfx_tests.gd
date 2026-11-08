extends Node
## Testes dos sons de habilidade. Executar: godot --headless --path . res://tests/sfx_tests.tscn

const BANK_PATH := "res://data/skill_sounds.tres"
const SFX_DIR := "res://assets/audio/sfx/"
const LOOPING_FILE := "p_circle_loop"
## Cada habilidade, em cada momento, com o arquivo exato: tocar "algum som" não basta.
const SHEET: Dictionary = {
	&"w_slash": {"fire": ["w_slash_1", "w_slash_2", "w_slash_3"]},
	&"w_charge": {"fire": ["w_charge_rush"], "impact": ["w_charge_hit"]},
	&"w_whirl": {"fire": ["w_whirl"]},
	&"w_warcry": {"fire": ["w_warcry"]},
	&"w_seismic": {"fire": ["w_seismic"]},
	&"w_monarch": {"cast": ["w_monarch"], "keeps_cast": true},
	&"guard_warrior": {"fire": ["w_guard"]},
	&"guard_mage": {"fire": ["m_guard"]},
	&"guard_priest": {"fire": ["p_guard"]},
	&"m_bolt": {"fire": ["m_bolt_cast"], "impact": ["m_bolt_hit"]},
	&"m_fireball": {"cast": ["m_fire_charge"], "fire": ["m_fireball_cast"], "impact": ["m_fireball_hit"]},
	&"m_icelance": {"fire": ["m_icelance_cast"], "impact": ["m_icelance_hit"]},
	&"m_meteor": {"cast": ["m_fire_charge"], "fire": ["m_meteor_fall"], "impact": ["m_meteor_hit"]},
	&"m_blink": {"fire": ["m_blink"]},
	&"m_nova": {"cast": ["m_nova"], "keeps_cast": true},
	&"p_smite": {"fire": ["p_smite_cast"], "impact": ["p_smite_hit"]},
	&"p_heal": {"cast": ["p_holy_charge"], "fire": ["p_heal"]},
	&"p_circle": {"cast": ["p_holy_charge"], "fire": ["p_circle_start"], "loop": ["p_circle_loop"]},
	&"p_bless": {"cast": ["p_holy_charge"], "fire": ["p_bless"]},
	&"p_judgement": {"cast": ["p_holy_charge"], "fire": ["p_judgement"]},
	&"p_miracle": {"cast": ["p_holy_charge"], "fire": ["p_miracle"]},
	&"boss_strike": {"fire": ["boss_strike_1", "boss_strike_2"]},
	&"boss_cleave": {"cast": ["boss_cleave_cast"], "fire": ["boss_cleave_fire"]},
	&"boss_slam": {"cast": ["boss_slam_cast"], "impact": ["boss_slam_impact"]},
	&"boss_spikes": {"cast": ["boss_spikes_cast"], "impact": ["boss_spikes_impact"]},
	&"boss_nova": {"cast": ["boss_nova_cast"], "impact": ["boss_nova_impact"]},
}
## Habilidades do Rei Gélido com som, e o dono delas no banco.
const BOSS_ID := &"frost_king"

var _passed: int = 0
var _failed: int = 0
var _current: String = ""


func _ready() -> void:
	for method in get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_"):
			_current = method_name
			await call(method_name)
			for child: Node in get_children():
				child.queue_free()
			await get_tree().process_frame
	print("\nSONS: %d verificações ok, %d falhas" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("  FALHOU [%s]: %s" % [_current, message])


func equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (obtido %s, esperado %s)" % [message, actual, expected])


func _bank() -> SkillSoundBank:
	return load(BANK_PATH) as SkillSoundBank


func _sound(id: StringName) -> SkillSoundData:
	for sound: SkillSoundData in _bank().sounds:
		if sound.id == id:
			return sound
	return null


func _class_skills(class_data: ClassData) -> Array[SkillData]:
	var skills: Array[SkillData] = [class_data.basic_attack, class_data.ultimate]
	skills.append_array(class_data.skills)
	return skills


func _skill(id: StringName) -> SkillData:
	for class_data: ClassData in GameDB.catalog.classes:
		for skill: SkillData in _class_skills(class_data):
			if skill.id == id:
				return skill
	return null


func _file_of(stream: AudioStream) -> String:
	return stream.resource_path.get_file().get_basename()


func _names(clip: SoundClip) -> Array:
	var names: Array = []
	if clip != null:
		for stream: AudioStream in clip.variations:
			names.append(_file_of(stream))
	return names


func _director() -> SfxDirector:
	var director := SfxDirector.new()
	director.bank = _bank()
	add_child(director)
	return director


func _unit(team: Combatant.Team = Combatant.Team.PARTY, position: Vector3 = Vector3.ZERO) -> Combatant:
	var body := Node3D.new()
	add_child(body)
	body.global_position = position
	var unit := Combatant.new()
	body.add_child(unit)
	var stats := StatBlock.new()
	stats.max_hp = 100000.0
	stats.max_mp = 1000.0
	stats.phys_attack = 50.0
	stats.magic_attack = 50.0
	stats.crit_chance = 0.0
	unit.setup("Teste", 1, team, stats, GameDB.balance)
	unit.add_chi(1000.0)
	return unit


func _caster(unit: Combatant) -> SkillCaster:
	var caster := SkillCaster.new()
	caster.combatant = unit
	add_child(caster)
	caster.set_process(false)
	return caster


func _aim() -> SkillAim:
	var aim := SkillAim.new()
	aim.direction = Vector3.FORWARD
	return aim


func _world_root() -> Node3D:
	var root_node := Node3D.new()
	root_node.add_to_group(&"world_root")
	add_child(root_node)
	return root_node


func _playing(director: SfxDirector) -> Array:
	var names: Array = []
	for voice: AudioStreamPlayer3D in director._voices:
		if voice.playing:
			names.append(_file_of(voice.stream))
	names.sort()
	return names


func _voice_of(director: SfxDirector, file: String) -> AudioStreamPlayer3D:
	for voice: AudioStreamPlayer3D in director._voices:
		if voice.playing and _file_of(voice.stream) == file:
			return voice
	return null


func _wait_cut() -> void:
	await get_tree().create_timer(SfxDirector.CUT_SECONDS + 0.1).timeout


func test_bank_matches_the_sheet() -> void:
	var bank: SkillSoundBank = _bank()
	check(bank != null, "banco de sons carrega")
	equal(bank.sounds.size(), SHEET.size(), "uma entrada por linha da planilha")
	for id: StringName in SHEET:
		var sound: SkillSoundData = _sound(id)
		check(sound != null, "%s tem entrada" % id)
		if sound == null:
			continue
		var row: Dictionary = SHEET[id]
		equal(_names(sound.cast), row.get("cast", []), "%s: som de conjuração" % id)
		equal(_names(sound.fire), row.get("fire", []), "%s: som de disparo" % id)
		equal(_names(sound.impact), row.get("impact", []), "%s: som de impacto" % id)
		equal(_names(sound.loop), row.get("loop", []), "%s: som contínuo" % id)
		equal(sound.cut_cast_on_fire, not row.get("keeps_cast", false), "%s: corte ao disparar" % id)


func test_every_class_skill_has_sound() -> void:
	var seen: int = 0
	for class_data: ClassData in GameDB.catalog.classes:
		for skill: SkillData in _class_skills(class_data):
			seen += 1
			check(_sound(skill.id) != null, "%s sem som" % skill.id)
	equal(seen, 18, "três classes com seis habilidades cada")


func test_every_file_is_used_and_only_the_circle_loops() -> void:
	var used: Dictionary[String, AudioStream] = {}
	for sound: SkillSoundData in _bank().sounds:
		for clip: SoundClip in [sound.cast, sound.fire, sound.impact, sound.loop]:
			if clip != null:
				for stream: AudioStream in clip.variations:
					used[_file_of(stream)] = stream
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(SFX_DIR):
		if file.ends_with(".wav"):
			files.append(file.get_basename())
	equal(files.size(), used.size(), "nenhum arquivo sobrando na pasta")
	for file: String in files:
		check(used.has(file), "%s não é usado" % file)
	# Uma voz com loop nunca volta ao grupo de vozes livres.
	for file: String in used:
		var wav: AudioStreamWAV = used[file]
		var expected: AudioStreamWAV.LoopMode = AudioStreamWAV.LOOP_FORWARD if file == LOOPING_FILE else AudioStreamWAV.LOOP_DISABLED
		equal(wav.loop_mode, expected, "%s: modo de repetição" % file)


func test_buses_carry_the_dungeon_effects() -> void:
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	check(sfx >= 0, "bus SFX existe")
	equal(AudioServer.get_bus_send(sfx), &"Master", "SFX vai para o Master")
	check(AudioServer.get_bus_effect(sfx, 0) is AudioEffectReverb, "eco da masmorra no SFX")
	check(AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter, "limitador protege a soma de tudo")


func test_variation_never_repeats_the_previous_one() -> void:
	var clip: SoundClip = _sound(&"w_slash").fire
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen: Dictionary[AudioStream, int] = {}
	var previous: AudioStream = null
	for _i in 300:
		var stream: AudioStream = clip.pick(rng)
		check(stream != previous, "variação repetida")
		previous = stream
		seen[stream] = seen.get(stream, 0) + 1
	equal(seen.size(), 3, "as três variações aparecem")


func test_voice_of_ally_is_placed_in_the_world_and_quieter() -> void:
	var director: SfxDirector = _director()
	var spot := Vector3(4.0, 0.0, -9.0)
	var unit: Combatant = _unit(Combatant.Team.PARTY, spot)
	Events.skill_fired.emit(_skill(&"w_whirl"), unit)
	var voice: AudioStreamPlayer3D = _voice_of(director, "w_whirl")
	check(voice != null, "som do aliado toca")
	var clip: SoundClip = _sound(&"w_whirl").fire
	var volume: float = clip.volume_db + director.bank.ally_volume_db
	equal(voice.volume_db, volume, "aliado abaixo do volume do jogador")
	equal(voice.max_db, volume, "perto do ouvinte não passa do volume da voz")
	equal(voice.global_position, spot, "som sai de onde o aliado está")
	equal(voice.attenuation_model, AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE, "cai com a distância")
	equal(voice.panning_strength, 1.0, "tem direção")
	equal(voice.bus, &"SFX", "bus de efeitos")
	equal(voice.attenuation_filter_db, 0.0, "ganho negativo não abafa o som")
	equal(voice.unit_size, director.bank.unit_size, "alcance do banco")
	equal(voice.max_distance, director.bank.max_distance, "limite do banco")


func test_monster_skills_stay_silent() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit(Combatant.Team.MONSTERS)
	var monster_skill := SkillData.new()
	monster_skill.id = &"mon_smash"
	Events.skill_cast_started.emit(monster_skill, unit)
	Events.skill_fired.emit(monster_skill, unit)
	Events.skill_impacted.emit(monster_skill, unit, Vector3.ZERO)
	equal(_playing(director), [], "monstro sem som mapeado não toca nada")


func _boss_skill(id: StringName) -> SkillData:
	var boss: MonsterData = GameDB.monster(BOSS_ID)
	var skills: Array[SkillData] = boss.skills.duplicate()
	for phase: BossPhaseData in boss.phases:
		skills.append_array(phase.skills)
	for skill: SkillData in skills:
		if skill.id == id:
			return skill
	return null


## O chefe toca os sons dele no lugar onde está, mais baixo que o jogador (como todo som que não é do jogador).
func test_boss_sounds_play_from_the_boss() -> void:
	var spot := Vector3(7.0, 0.0, -3.0)
	for id: StringName in [&"boss_strike", &"boss_cleave", &"boss_slam", &"boss_spikes", &"boss_nova"]:
		var skill: SkillData = _boss_skill(id)
		check(skill != null, "%s existe no chefe" % id)
		if skill == null:
			continue
		var sound: SkillSoundData = _sound(id)
		var director: SfxDirector = _director()
		var boss: Combatant = _unit(Combatant.Team.MONSTERS, spot)
		var cases: Array[Dictionary] = [
			{"slot": "cast", "clip": sound.cast, "emit": func() -> void: Events.skill_cast_started.emit(skill, boss)},
			{"slot": "fire", "clip": sound.fire, "emit": func() -> void: Events.skill_fired.emit(skill, boss)},
			{"slot": "impact", "clip": sound.impact, "emit": func() -> void: Events.skill_impacted.emit(skill, boss, spot)},
		]
		for case in cases:
			var clip: SoundClip = case["clip"]
			for voice: AudioStreamPlayer3D in director._voices:
				voice.stop()
			case["emit"].call()
			if clip == null:
				equal(_playing(director), [], "%s: sem som de %s, nada toca" % [id, case["slot"]])
				continue
			var heard: Array = _playing(director)
			equal(heard.size(), 1, "%s: %s toca uma voz" % [id, case["slot"]])
			if heard.is_empty():
				continue
			check(_names(clip).has(heard[0]), "%s: %s toca um arquivo do próprio slot (%s)" % [id, case["slot"], heard[0]])
			var voice: AudioStreamPlayer3D = _voice_of(director, heard[0])
			equal(voice.global_position, spot, "%s: %s sai de onde o chefe está" % [id, case["slot"]])
			equal(voice.attenuation_model, AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE, "%s: %s tem posição no mundo" % [id, case["slot"]])
			equal(voice.volume_db, clip.volume_db + director.bank.ally_volume_db, "%s: %s não tem o volume do jogador" % [id, case["slot"]])
			await get_tree().process_frame
			await _frames(SfxDirector.MIN_REPEAT_FRAMES)


func test_charge_is_cut_when_the_skill_fires() -> void:
	var director: SfxDirector = _director()
	_world_root()
	var unit: Combatant = _unit()
	var caster: SkillCaster = _caster(unit)
	check(caster.try_cast(_skill(&"m_meteor"), _aim()), "meteoro conjura")
	equal(_playing(director), ["m_fire_charge"], "preparo toca durante o cast")
	caster._process(5.0)
	check(_voice_of(director, "m_meteor_fall") != null, "queda toca no disparo")
	await _wait_cut()
	equal(_playing(director), ["m_meteor_fall"], "preparo some no disparo")
	await get_tree().create_timer(_skill(&"m_meteor").impact_delay + 0.1).timeout
	check(_voice_of(director, "m_meteor_hit") != null, "impacto toca depois do atraso")


func test_cast_that_carries_the_hit_survives_the_fire() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var caster: SkillCaster = _caster(unit)
	check(caster.try_cast(_skill(&"m_nova"), _aim()), "nova conjura")
	equal(_playing(director), ["m_nova"], "explosão começa no cast para cair no fim dele")
	caster._process(5.0)
	await _wait_cut()
	equal(_playing(director), ["m_nova"], "disparo não corta a explosão")
	check(director._casts.is_empty(), "conjuração encerrada não fica registrada")


func test_every_way_of_abandoning_a_cast_cuts_the_sound() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var caster: SkillCaster = _caster(unit)
	var skill: SkillData = _skill(&"m_fireball")
	caster.try_cast(skill, _aim())
	caster.interrupt()
	await _wait_cut()
	equal(_playing(director), [], "interrupção corta")
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	caster.try_cast(skill, _aim())
	caster.reset_all()
	await _wait_cut()
	equal(_playing(director), [], "reaparecer corta")
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	caster.try_cast(skill, _aim())
	equal(_playing(director), ["m_fire_charge"], "preparo tocando antes de faltar mana")
	unit.mp = 0.0
	caster._process(5.0)
	await _wait_cut()
	equal(_playing(director), [], "faltar mana no fim do cast corta e não dispara")
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	unit.restore_full()
	check(caster.try_cast(_skill(&"m_nova"), _aim()), "nova conjura")
	equal(_playing(director), ["m_nova"], "golpe no som de conjuração tocando")
	caster.interrupt()
	await _wait_cut()
	equal(_playing(director), [], "cast interrompido corta até o som que levaria o golpe")


func test_projectile_sounds_its_impact_once() -> void:
	_world_root()
	var unit: Combatant = _unit()
	for id: StringName in [&"m_bolt", &"m_fireball"]:
		var impacts: Array[StringName] = []
		var listener := func(skill: SkillData, _source: Combatant, _point: Vector3) -> void: impacts.append(skill.id)
		Events.skill_impacted.connect(listener)
		var projectile := Projectile.new()
		projectile.skill = _skill(id)
		projectile.caster = unit
		add_child(projectile)
		projectile.set_physics_process(false)
		projectile._impact(Vector3.ZERO, null)
		Events.skill_impacted.disconnect(listener)
		equal(impacts, [id] as Array[StringName], "%s: um impacto por projétil" % id)


func test_impact_uses_the_point_and_the_caster_volume() -> void:
	var director: SfxDirector = _director()
	var spot := Vector3(10.0, 1.0, 3.0)
	Events.skill_impacted.emit(_skill(&"m_bolt"), _unit(), spot)
	var voice: AudioStreamPlayer3D = _voice_of(director, "m_bolt_hit")
	check(voice != null, "impacto toca")
	equal(voice.global_position, spot, "impacto sai do ponto atingido")
	equal(voice.volume_db, _sound(&"m_bolt").impact.volume_db + director.bank.ally_volume_db, "impacto de aliado mais baixo")


func test_charge_impact_needs_a_hit() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var skill: SkillData = _skill(&"w_charge")
	var aim: SkillAim = _aim()
	await SkillExecutor._dash(skill, unit, aim)
	await _frames(2)
	equal(_playing(director), [], "investida no vazio não soa como pancada")
	var hostile: Combatant = _unit(Combatant.Team.MONSTERS, unit.world_position() + Vector3.FORWARD * 4.0)
	aim.target = hostile
	await SkillExecutor._dash(skill, unit, aim)
	await _frames(2)
	equal(_playing(director), ["w_charge_hit"], "investida que acerta soa no impacto")


func test_circle_hum_lives_with_the_zone() -> void:
	var director: SfxDirector = _director()
	var root_node: Node3D = _world_root()
	var unit: Combatant = _unit()
	var spot := Vector3(2.0, 0.0, 5.0)
	HealZone.spawn(_skill(&"p_circle"), unit, spot)
	var voice: AudioStreamPlayer3D = _voice_of(director, LOOPING_FILE)
	check(voice != null, "zona toca o som contínuo")
	equal(voice.global_position, spot, "som fica onde a zona está")
	root_node.get_child(0).queue_free()
	await get_tree().process_frame
	await _wait_cut()
	equal(_playing(director), [], "zona some e o som para")


func test_guard_uses_the_class_sound() -> void:
	var director: SfxDirector = _director()
	Events.guard_raised.emit(&"warrior", _unit())
	equal(_playing(director), ["w_guard"], "guerreiro ergue o escudo")


func test_mage_guard_uses_its_sound() -> void:
	var director: SfxDirector = _director()
	Events.guard_raised.emit(&"mage", _unit())
	equal(_playing(director), ["m_guard"], "mago ergue a barreira")


func test_priest_guard_uses_its_sound() -> void:
	var director: SfxDirector = _director()
	Events.guard_raised.emit(&"priest", _unit())
	equal(_playing(director), ["p_guard"], "sacerdote ergue a égide")


func test_guard_without_file_stays_silent() -> void:
	var director: SfxDirector = _director()
	Events.guard_raised.emit(&"sem_arquivo", _unit())
	equal(_playing(director), [], "classe sem som de defesa não quebra")


func test_same_sound_in_the_same_moment_plays_once() -> void:
	var director: SfxDirector = _director()
	var skill: SkillData = _skill(&"w_seismic")
	Events.skill_fired.emit(skill, _unit())
	Events.skill_fired.emit(skill, _unit())
	equal(_playing(director).size(), 1, "aliados juntos não dobram o volume")
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	Events.skill_fired.emit(skill, _unit())
	equal(_playing(director).size(), 2, "depois do intervalo volta a tocar")


func test_voices_run_out_without_errors() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var clip: SoundClip = _sound(&"m_meteor").impact
	var last: AudioStreamPlayer3D = null
	for _i in SfxDirector.VOICE_COUNT + 6:
		director._last_frame.clear()
		last = director._play(clip, unit, Vector3.ZERO, true)
	check(last == null, "sem voz livre o som é descartado")
	equal(_playing(director).size(), SfxDirector.VOICE_COUNT, "todas as vozes em uso")


func test_cut_fades_instead_of_stopping_the_wave() -> void:
	var director: SfxDirector = _director()
	var clip: SoundClip = _sound(&"m_meteor").impact
	var voice: AudioStreamPlayer3D = director._play(clip, _unit(), Vector3.ZERO, true)
	var volume: float = voice.volume_db
	director._cut(voice)
	await _frames(2)
	check(voice.playing, "corte não para a onda de imediato")
	check(voice.volume_db < volume, "corte abaixa o volume")
	await _wait_cut()
	check(not voice.playing, "corte termina parando a voz")


func test_pitch_varies_only_where_the_clip_asks() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var bolt: SoundClip = _sound(&"m_bolt").fire
	check(bolt.pitch_jitter > 0.0, "seta repete muito e precisa variar")
	var pitches: Dictionary[float, bool] = {}
	for _i in 6:
		director._last_frame.clear()
		var voice: AudioStreamPlayer3D = director._play(bolt, unit, Vector3.ZERO, true)
		check(absf(voice.pitch_scale - 1.0) <= bolt.pitch_jitter, "tom dentro da variação do clipe")
		pitches[voice.pitch_scale] = true
	check(pitches.size() > 1, "tom muda entre disparos")
	# Mudar o tom muda a duração: o golpe sairia do instante do jogo.
	for clip: SoundClip in [_sound(&"m_nova").cast, _sound(&"w_monarch").cast, _sound(&"p_judgement").fire]:
		equal(clip.pitch_jitter, 0.0, "som alinhado ao golpe não varia")
		director._last_frame.clear()
		equal(director._play(clip, unit, Vector3.ZERO, true).pitch_scale, 1.0, "tom exato no som alinhado")


func test_late_cut_does_not_kill_the_new_sound() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var clip: SoundClip = _sound(&"m_meteor").impact
	var voice: AudioStreamPlayer3D = director._play(clip, unit, Vector3.ZERO, true)
	var volume: float = voice.volume_db
	director._cut(voice)
	voice.stop()
	director._last_frame.clear()
	check(director._play(clip, unit, Vector3.ZERO, true) == voice, "voz livre é reaproveitada")
	await _wait_cut()
	check(voice.playing, "corte antigo não para o som novo")
	equal(voice.volume_db, volume, "corte antigo não abaixa o som novo")


func test_reused_voice_leaves_the_old_cast() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	var other: Combatant = _unit()
	var skill: SkillData = _skill(&"m_fireball")
	Events.skill_cast_started.emit(skill, unit)
	var voice: AudioStreamPlayer3D = director._casts[unit.get_instance_id()]
	voice.stop()
	await _frames(SfxDirector.MIN_REPEAT_FRAMES)
	Events.skill_fired.emit(_skill(&"m_blink"), other)
	equal(_playing(director), ["m_blink"], "voz da conjuração encerrada foi reaproveitada")
	Events.skill_cast_stopped.emit(skill, unit)
	await _wait_cut()
	equal(_playing(director), ["m_blink"], "dono antigo não corta o som de outro")


func test_leaving_the_dungeon_silences_everything() -> void:
	var director: SfxDirector = _director()
	var unit: Combatant = _unit()
	Events.skill_cast_started.emit(_skill(&"m_fireball"), unit)
	Events.skill_impacted.emit(_skill(&"m_meteor"), unit, Vector3.ZERO)
	check(not _playing(director).is_empty(), "sons tocando antes de sair")
	Events.dungeon_exited.emit()
	await _wait_cut()
	equal(_playing(director), [], "saída corta tudo")
	check(director._casts.is_empty(), "nenhuma conjuração fica registrada")


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
