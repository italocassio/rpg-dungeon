class_name MusicDirector
extends Node
## Escolhe a faixa ouvindo Events. Nenhum sistema de jogo conhece este nó.

enum Track { NONE, DUNGEON, BOSS, LOBBY }

const CONFIG_PATH := "res://data/music.tres"
const BUS := &"Music"

var config: MusicConfig
var current: Track = Track.NONE

var _dungeon_player: AudioStreamPlayer
var _boss_player: AudioStreamPlayer
var _lobby_player: AudioStreamPlayer
var _players: Array[AudioStreamPlayer] = []
var _fade: Tween


func _ready() -> void:
	# A música e seus fades continuam com a árvore pausada.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if config == null and ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH) as MusicConfig
	if config == null:
		push_warning("Música desativada: %s ausente." % CONFIG_PATH)
		return
	_dungeon_player = _add_player(config.dungeon_track)
	_boss_player = _add_player(config.boss_track)
	_lobby_player = _add_player(config.lobby_track)
	_players = [_dungeon_player, _boss_player, _lobby_player]
	Events.lobby_entered.connect(_on_lobby_entered)
	Events.dungeon_entered.connect(_on_dungeon_entered)
	Events.dungeon_exited.connect(_on_dungeon_exited)
	Events.boss_engaged.connect(_on_boss_engaged)
	Events.boss_disengaged.connect(_on_boss_finished)
	Events.boss_defeated.connect(_on_boss_finished)


func _add_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS
	add_child(player)
	return player


func _on_lobby_entered() -> void:
	_switch_to(Track.LOBBY)


func _on_dungeon_entered() -> void:
	_switch_to(Track.DUNGEON)


## A tela da masmorra emite isto ao sair da árvore, depois de o saguão já ter avisado `lobby_entered`.
## Só a música da masmorra e a do chefe caem aqui; o saguão não pode ser silenciado por esse aviso tardio.
func _on_dungeon_exited() -> void:
	if current == Track.DUNGEON or current == Track.BOSS:
		_switch_to(Track.NONE)


func _on_boss_engaged(_boss: Node) -> void:
	_switch_to(Track.BOSS)


## Só volta se a luta estava tocando: aviso tardio não religa música fora da masmorra.
func _on_boss_finished(_boss: Node) -> void:
	if current == Track.BOSS:
		_switch_to(Track.DUNGEON)


func _player_of(track: Track) -> AudioStreamPlayer:
	match track:
		Track.DUNGEON:
			return _dungeon_player
		Track.BOSS:
			return _boss_player
		Track.LOBBY:
			return _lobby_player
	return null


func _volume_of(track: Track) -> float:
	match track:
		Track.BOSS:
			return db_to_linear(config.boss_volume_db)
		Track.LOBBY:
			return db_to_linear(config.lobby_volume_db)
	return db_to_linear(config.dungeon_volume_db)


func _switch_to(track: Track) -> void:
	if track == current:
		return
	current = track
	if not is_inside_tree():
		return
	if _fade != null:
		_fade.kill()
	var seconds: float = config.fade_out_seconds if track == Track.NONE else config.crossfade_seconds
	var incoming: AudioStreamPlayer = _player_of(track)
	_fade = create_tween().set_parallel()
	for player: AudioStreamPlayer in _players:
		if player == incoming:
			# Faixa ainda não configurada (ex.: saguão sem arquivo): nada audível, sem erro.
			if player.stream == null:
				continue
			if not player.playing:
				player.volume_linear = 0.0
				player.play()
			_fade.tween_property(player, "volume_linear", _volume_of(track), seconds)
		elif player.playing:
			_fade.tween_property(player, "volume_linear", 0.0, seconds)
	_fade.chain().tween_callback(_stop_silent)


func _stop_silent() -> void:
	var active: AudioStreamPlayer = _player_of(current)
	for player: AudioStreamPlayer in _players:
		if player != active:
			player.stop()
