extends Node3D
## Renders e métricas fixos para a revisão de arte (OS-001). Só lê o jogo.
## godot --display-driver x11 --disable-vsync --resolution 1920x1080 --path . res://tests/visual/hero_review.tscn \
##   -- --out=DIR [--class=warrior] [--tier=0..3] [--variant=0, só com tier 0] [--weapon=sword_shield] [--rarity=0]

## Fixo em SubViewport: a janela real perde a altura da barra de título e varia com o gerenciador de janelas.
const RESOLUTION := Vector2i(1920, 1080)
const SETTLE_FRAMES := 3
const ROOM_WARMUP_FRAMES := 10
const CAMERA_NEAR := 0.06
const CAMERA_FAR := 160.0

const AVAILABLE_TIERS: Array[int] = [0, 1, 2, 3]

const DUNGEON_ID := &"frost_gate"
const EYE := Vector3(-7.0, 1.7, -2.0)
const EYE_TARGET := Vector3(12.0, 1.7, 2.0)

const TURN_FOV := 24.0
const TURN_DISTANCE := 7.0
const TURN_EYE_OFFSET := Vector3(0.0, -0.5, 0.0)
const TURN_AIM_HEIGHT := 1.08
const VIEW_COUNT := 8
const VIEW_STEP_DEGREES := 45.0
const BACK_VIEW := 4
const SHEET_COLUMNS := 4
const SHEET_CELL_WIDTH := 760

const NEUTRAL_BACKGROUND := Color("6a7486")
const NEUTRAL_AMBIENT_ENERGY := 0.9
const NEUTRAL_LIGHT_ROTATION := Vector3(-0.8, 0.6, 0.0)
const NEUTRAL_FOV := 26.0
const NEUTRAL_EYE := Vector3(0.0, 1.2, 7.0)
const NEUTRAL_TARGET := Vector3(0.0, 1.08, 0.0)

const LINE_SPACING := 1.8
const SIDE_YAW := 90.0
const BACK_YAW := 180.0

const WALK_FRAMES := 45
const WALK_DELTA := 0.016
const WALK_SPEED := 6.0

const POSE_FOV := 40.0
const POSE_EYE := Vector3(5.0, 1.1, 0.0)
const POSE_TARGET := Vector3(0.0, 1.1, 0.0)
const POSE_DELTA := 0.016
const POSE_WINDUP_TIME := 0.1
const POSE_WINDUP_FRAMES := 12
const POSE_STRIKE_FRAMES := 8
const SWING_IMPACT_FRAMES := 5
const SWING_FINISH_FRAMES := 4

const MANNEQUIN_SKIN := Color("D9A981")
const MANNEQUIN_STEEL := Color("B0AEA8")
const MANNEQUIN_SEAL_COLOR := Color("E0603A")
## Posições do Selo do guerreiro no `chest` (ficha do guerreiro): frente e costas.
const MANNEQUIN_SEALS: Array[Vector3] = [Vector3(0.0, 0.38, -0.205), Vector3(0.0, 0.54, 0.2)]

const RARITY_SPACING := 1.0
const RARITY_HEIGHT := 0.4

const ROOM_FOV := 78.0
## x = distância, y = espaço entre as classes, z = desvio à direita, para fugir dos braseiros.
const ROOM_SHOTS: Array[Vector3] = [Vector3(5.0, 1.5, 0.0), Vector3(10.0, 1.6, 3.2)]
## Os 20 m não cabem no eixo de EYE: este passa pelo centro da sala e aponta para longe do fogo.
const FAR_EYE := Vector3(3.8, 1.7, 8.1)
const FAR_TARGET := Vector3(-4.7, 1.7, -10.0)
const FAR_DISTANCE := 20
const FAR_SPACING := 1.5

const SILHOUETTE_EYE := Vector3(0.0, 1.7, 20.0)
const SILHOUETTE_CENTER := Vector3(0.0, 1.1, 0.0)
const SILHOUETTE_SPACING := 2.4
const SILHOUETTE_CROP := Vector2i(270, 100)
const SILHOUETTE_ZOOM := 4
const SILHOUETTE_YAWS: Array[float] = [0.0, SIDE_YAW, BACK_YAW]

const MASK_THRESHOLD := 36
const SCAN_WIDTH := 760
const SCAN_STEP := 2

const V1_HIGH_ABOVE := 1.25
const V1_LOW_RANGE := Vector2(0.05, 0.9)
const V1_HIGH_MIN := 45.0
const V1_LOW_MAX := 20.0

const V4_MASSES: Dictionary = {
	&"warrior": {"views": ["back"], "height": Vector2(0.75, 1.3), "half_width": 0.14, "hue": 0.0},
	&"mage": {"views": ["back"], "height": Vector2(0.3, 0.85), "half_width": 0.2, "hue": 280.0},
	&"priest": {"views": ["front", "back"], "height": Vector2(0.12, 0.5), "half_width": 0.2, "hue": 165.0},
}
const V4_MAX_HUE_ERROR := 15.0
const V4_MIN_VALUE := 0.15

## Seção 11 do guia de estilo, indexado pelo tier. Medido com `--rarity=4`.
const HERO_BUDGETS: Array[Dictionary] = [
	{"parts": 66, "tris": 5000, "materials": 18},
	{"parts": 67, "tris": 5200, "materials": 18},
	{"parts": 68, "tris": 5600, "materials": 18},
	{"parts": 70, "tris": 6000, "materials": 18},
]
const VIEWMODEL_BUDGET: Dictionary = {"parts": 38, "tris": 4000, "materials": 10}

## Recorte do `tiers_<classe>_room10.png`: sem reescalar, centrado na altura do meio do herói.
const TIER_ROOM_SHOT := 1
const TIER_ROOM_CROP := Vector2i(220, 280)
const TIER_ROOM_CENTER_HEIGHT := 0.9

## Regras P1, P7, P8 e P9 (guia de estilo, seção 9).
const P1_MIN_SIZE := 0.09
const P7_MIN_RATIO := 0.7
const P8_HEAD_X := 0.1
const P8_HEAD_Y := Vector2(0.02, 0.2)
const P8_HEAD_Z := -0.05
const P9_MIN_AREA := 0.01
const P9_MIN_LSTAR := 46.0
const P9_GLOW_MIN_ENERGY := 0.5
const SEAL_RADIUS := 0.055
const SEAL_COLOR_TOLERANCE := 0.12

var _out := "user://hero_review"
var _class_filter := &""
var _tier: int = 0
var _variant: int = 0
var _weapon_filter := &""
var _rarity: int = ItemData.Rarity.COMMON

var _classes: Array[StringName] = []
var _models: Dictionary = {}
var _files: int = 0
var _save_errors: int = 0
var _mannequin: Dictionary = {}
var _stage: SubViewport
var _camera: Camera3D
var _srgb_to_linear := PackedFloat32Array()


func _ready() -> void:
	var started: int = Time.get_ticks_msec()
	var problem: String = _read_arguments()
	if problem.is_empty():
		problem = _check_arguments()
	if not problem.is_empty():
		printerr("hero_review: ", problem)
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	for value in 256:
		_srgb_to_linear.append(Color(value / 255.0, 0.0, 0.0).srgb_to_linear().r)
	_stage = _make_stage()
	add_child(_stage)
	_camera = Camera3D.new()
	_camera.near = CAMERA_NEAR
	_camera.far = CAMERA_FAR
	_stage.add_child(_camera)
	_camera.make_current()

	await _review_neutral_stage()
	await _review_silhouettes()
	await _review_room()
	await _review_lobby()

	var elapsed: float = (Time.get_ticks_msec() - started) / 1000.0
	_write_report(elapsed)
	print("hero_review: %d arquivos em %.1f s, em %s" % [_files, elapsed, _out])
	get_tree().quit(1 if _save_errors > 0 else 0)


func _read_arguments() -> String:
	for argument in OS.get_cmdline_user_args():
		var pair: PackedStringArray = argument.trim_prefix("--").split("=", true, 1)
		if pair.size() != 2:
			return "argumento inválido: %s" % argument
		match pair[0]:
			"out":
				_out = pair[1]
			"class":
				_class_filter = StringName(pair[1])
			"tier":
				_tier = pair[1].to_int()
			"variant":
				_variant = pair[1].to_int()
			"weapon":
				_weapon_filter = StringName(pair[1])
			"rarity":
				_rarity = pair[1].to_int()
			_:
				return "argumento desconhecido: %s" % argument
	return ""


func _check_arguments() -> String:
	if not AVAILABLE_TIERS.has(_tier):
		return "tier %d não existe" % _tier
	if _tier != 0 and _variant != 0:
		return "variante só existe em T0"
	if not ItemData.Rarity.values().has(_rarity):
		return "raridade %d não existe" % _rarity
	var weapon_models: Array[StringName] = []
	for class_data in GameDB.catalog.classes:
		if _class_filter == &"" or _class_filter == class_data.id:
			_classes.append(class_data.id)
			_models[class_data.id] = {}
			if _variant < 0 or _variant >= class_data.starter_armors.size():
				return "variante %d não existe em %s" % [_variant, class_data.id]
		for weapon in class_data.starter_weapons:
			weapon_models.append(weapon.weapon_model)
	if _classes.is_empty():
		return "classe desconhecida: %s" % _class_filter
	if _weapon_filter != &"" and not weapon_models.has(_weapon_filter):
		return "arma desconhecida: %s" % _weapon_filter
	return ""


## Copia da viewport raiz o que o projeto configura, para o render ser igual ao do jogo.
func _make_stage() -> SubViewport:
	var root: Viewport = get_viewport()
	var stage := SubViewport.new()
	stage.size = RESOLUTION
	stage.own_world_3d = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.screen_space_aa = root.screen_space_aa
	stage.anisotropic_filtering_level = root.anisotropic_filtering_level
	stage.positional_shadow_atlas_size = root.positional_shadow_atlas_size
	for quadrant in 4:
		stage.set_positional_shadow_atlas_quadrant_subdiv(quadrant, root.get_positional_shadow_atlas_quadrant_subdiv(quadrant))
	return stage


## Único ponto que monta o herói.
func _make_hero(class_id: StringName, hero_tier: int = 0, weapon_index: int = 0) -> CreatureRig:
	var rig: CreatureRig = CreatureFactory.build_hero(_look_of(class_id, weapon_index, hero_tier))
	# Delta zero: pose parada, sem depender de quantos quadros passaram.
	rig.animate(0.0, 0.0)
	return rig


func _look_of(class_id: StringName, weapon_index: int = 0, tier: int = 0) -> HeroLook:
	var look: HeroLook = HeroLook.from_items(class_id, _armor_of(class_id), _weapon_of(class_id, weapon_index))
	look.armor_tier = tier
	look.head_tier = tier
	look.boots_tier = tier
	look.weapon_tier = tier
	if tier != 0:
		look.armor_variant = 0
	return look


func _armor_of(class_id: StringName) -> ItemData:
	return GameDB.class_by_id(class_id).starter_armors[_variant]


func _weapon_of(class_id: StringName, weapon_index: int = 0) -> ItemData:
	var weapon: ItemData = GameDB.class_by_id(class_id).starter_weapons[weapon_index].duplicate()
	if _weapon_filter != &"":
		weapon.weapon_model = _weapon_filter
	weapon.rarity = _rarity as ItemData.Rarity
	return weapon


func _spawn_hero(class_id: StringName, hero_tier: int = 0, weapon_index: int = 0) -> CreatureRig:
	var rig: CreatureRig = _make_hero(class_id, hero_tier, weapon_index)
	_stage.add_child(rig)
	return rig


func _spawn_line(direction: Vector3, spacing: float, weapon_index: int = 0) -> Array[CreatureRig]:
	var rigs: Array[CreatureRig] = []
	var middle: float = (_classes.size() - 1) * 0.5
	for index in _classes.size():
		var rig: CreatureRig = _spawn_hero(_classes[index], _tier, weapon_index)
		rig.position = direction * (float(index) - middle) * spacing
		rigs.append(rig)
	return rigs


func _despawn(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()


func _despawn_line(rigs: Array[CreatureRig]) -> void:
	for rig in rigs:
		_despawn(rig)


## O modelo olha para -Z: look_at() sem use_model_front aponta a frente dele para a câmera.
func _face_camera(rig: CreatureRig, yaw_degrees: float) -> void:
	var target: Vector3 = _camera.global_position
	target.y = rig.global_position.y
	rig.look_at(target, Vector3.UP)
	rig.rotate_y(deg_to_rad(yaw_degrees))


## Para fileiras: todos com o mesmo ângulo, sem convergir para a câmera.
func _set_line_yaw(rigs: Array[CreatureRig], yaw_degrees: float) -> void:
	for rig in rigs:
		rig.rotation = Vector3(0.0, PI + deg_to_rad(yaw_degrees), 0.0)


func _aim(fov: float, from: Vector3, target: Vector3) -> void:
	_camera.fov = fov
	_camera.look_at_from_position(from, target)


func _shoot() -> Image:
	for _frame in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = _stage.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	return image


func _save(image: Image, file_name: String) -> void:
	var error: Error = image.save_png(_out.path_join(file_name))
	if error != OK:
		printerr("hero_review: falha ao gravar %s: %s" % [file_name, error_string(error)])
		_save_errors += 1
		return
	_files += 1


func _turnaround(rig: CreatureRig) -> Array[Image]:
	var views: Array[Image] = []
	for view in VIEW_COUNT:
		_face_camera(rig, float(view) * VIEW_STEP_DEGREES)
		views.append(await _shoot())
	return views


func _center_cell(image: Image) -> Image:
	var left: int = floori((image.get_width() - SHEET_CELL_WIDTH) * 0.5)
	return image.get_region(Rect2i(left, 0, SHEET_CELL_WIDTH, image.get_height()))


func _sheet(images: Array[Image], columns: int) -> Image:
	var cell: Vector2i = images[0].get_size()
	var rows: int = ceili(float(images.size()) / float(columns))
	var sheet: Image = Image.create_empty(cell.x * columns, cell.y * rows, false, images[0].get_format())
	for index in images.size():
		var slot := Vector2i(index % columns, floori(float(index) / float(columns)))
		sheet.blit_rect(images[index], Rect2i(Vector2i.ZERO, cell), slot * cell)
	return sheet


func _turn_sheet(views: Array[Image]) -> Image:
	var cells: Array[Image] = []
	for view in views:
		cells.append(_center_cell(view))
	return _sheet(cells, SHEET_COLUMNS)


func _flat_environment(background: Color) -> Environment:
	var flat := Environment.new()
	flat.background_mode = Environment.BG_COLOR
	flat.background_color = background
	flat.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	flat.ambient_light_color = Color.WHITE
	flat.ambient_light_energy = NEUTRAL_AMBIENT_ENERGY
	return flat


func _review_neutral_stage() -> void:
	_camera.environment = _flat_environment(NEUTRAL_BACKGROUND)
	var sun := DirectionalLight3D.new()
	sun.rotation = NEUTRAL_LIGHT_ROTATION
	_stage.add_child(sun)
	_aim(NEUTRAL_FOV, NEUTRAL_EYE, NEUTRAL_TARGET)
	for class_id in _classes:
		var rig: CreatureRig = _spawn_hero(class_id, _tier)
		var views: Array[Image] = await _turnaround(rig)
		_save(_turn_sheet(views), "neutral_%s.png" % class_id)
		_despawn(rig)
		await _review_tiers(class_id)
		await _review_rarities(class_id)
	await _review_walk()
	await _review_poses()
	_despawn(sun)


## Sempre os 4 tiers, qualquer que seja `--tier`: uma coluna por tier, frente na linha de cima e costas na de baixo.
func _review_tiers(class_id: StringName) -> void:
	var fronts: Array[Image] = []
	var backs: Array[Image] = []
	for hero_tier in AVAILABLE_TIERS:
		var rig: CreatureRig = _spawn_hero(class_id, hero_tier)
		_face_camera(rig, 0.0)
		fronts.append(_center_cell(await _shoot()))
		_face_camera(rig, BACK_YAW)
		backs.append(_center_cell(await _shoot()))
		_despawn(rig)
	_save(_sheet(fronts + backs, AVAILABLE_TIERS.size()), "tiers_%s.png" % class_id)


## Uma prateleira de 5 raridades por arma inicial; a peça da mão esquerda vai em outro arquivo (`_off`).
func _review_rarities(class_id: StringName) -> void:
	var weapons: Array = GameDB.class_by_id(class_id).starter_weapons
	for weapon_index in weapons.size():
		if _weapon_filter != &"" and weapon_index > 0:
			break
		var model: StringName = _weapon_of(class_id, weapon_index).weapon_model
		var suffix: String = "" if weapon_index == 0 else "_%s" % model
		await _shoot_rarity_shelf(model, false, "rarity_%s%s.png" % [class_id, suffix])
		if WeaponKit.OFF_HAND_MODELS.has(model):
			await _shoot_rarity_shelf(model, true, "rarity_%s%s_off.png" % [class_id, suffix])


func _shoot_rarity_shelf(model: StringName, off_hand: bool, file_name: String) -> void:
	var shelf := Node3D.new()
	_stage.add_child(shelf)
	var rarities: Array = ItemData.Rarity.values()
	var middle: float = (rarities.size() - 1) * 0.5
	for rarity: int in rarities:
		var piece: Node3D
		if off_hand:
			piece = WeaponKit.build_off_hand(model, rarity as ItemData.Rarity, _tier)
			# Escudo: a face externa fica em -Z, e a câmera olha de +Z.
			if model == &"sword_shield":
				piece.rotation.y = PI
		else:
			piece = WeaponKit.build_main_hand(model, rarity as ItemData.Rarity, _tier)
		piece.position = Vector3((float(rarity) - middle) * RARITY_SPACING, RARITY_HEIGHT, 0.0)
		shelf.add_child(piece)
	_save(await _shoot(), file_name)
	_despawn(shelf)


func _review_walk() -> void:
	var rigs: Array[CreatureRig] = _spawn_line(Vector3.RIGHT, LINE_SPACING)
	for rig in rigs:
		for _frame in WALK_FRAMES:
			rig.animate(WALK_DELTA, WALK_SPEED)
		rig._phase = PI * 0.5
		rig.animate(0.0, WALK_SPEED)
	_set_line_yaw(rigs, SIDE_YAW)
	_save(await _shoot(), "walk_side.png")
	_set_line_yaw(rigs, BACK_YAW)
	_save(await _shoot(), "walk_back.png")
	_despawn_line(rigs)


func _review_poses() -> void:
	_aim(POSE_FOV, POSE_EYE, POSE_TARGET)
	var rigs: Array[CreatureRig] = _spawn_line(Vector3.FORWARD, LINE_SPACING)
	for rig in rigs:
		rig.wind_up(&"cast", POSE_WINDUP_TIME)
		for _frame in POSE_WINDUP_FRAMES:
			rig.animate(POSE_DELTA, 0.0)
	_save(await _shoot(), "pose_cast.png")
	_despawn_line(rigs)
	await _review_strike()
	await _review_swing()


## `overhead` nas 6 armas iniciais: uma coluna por arma (a primeira de cada classe, depois a segunda).
func _review_strike() -> void:
	var cells: Array[Image] = []
	var columns: int = 0
	for weapon_index in 2:
		if _weapon_filter != &"" and weapon_index > 0:
			break
		var rigs: Array[CreatureRig] = _spawn_line(Vector3.FORWARD, LINE_SPACING, weapon_index)
		for rig in rigs:
			rig.strike(&"overhead")
			for _frame in POSE_STRIKE_FRAMES:
				rig.animate(POSE_DELTA, 0.0)
		cells.append(await _shoot())
		columns += 1
		_despawn_line(rigs)
	_save(_sheet(cells, columns), "pose_strike.png")


## Armado, impacto e fim do golpe mais usado, nos mesmos rigs. Uma coluna por arma inicial
## (a primeira de cada classe, depois a segunda); com `--weapon`, só a arma filtrada.
func _review_swing() -> void:
	var columns: Array[Array] = []
	for weapon_index in 2:
		if _weapon_filter != &"" and weapon_index > 0:
			break
		var rigs: Array[CreatureRig] = _spawn_line(Vector3.FORWARD, LINE_SPACING, weapon_index)
		columns.append(await _swing_bands(rigs))
		_despawn_line(rigs)
	var bands: Array[Image] = []
	for phase in columns[0].size():
		for column in columns:
			bands.append(column[phase])
	_save(_sheet(bands, columns.size()), "pose_swing.png")


func _swing_bands(rigs: Array[CreatureRig]) -> Array[Image]:
	var bands: Array[Image] = []
	for rig in rigs:
		rig.wind_up(&"swing", POSE_WINDUP_TIME)
	_animate_line(rigs, POSE_WINDUP_FRAMES)
	bands.append(await _shoot())
	for rig in rigs:
		rig.strike(&"swing")
	_animate_line(rigs, SWING_IMPACT_FRAMES)
	bands.append(await _shoot())
	_animate_line(rigs, SWING_FINISH_FRAMES)
	bands.append(await _shoot())
	return bands


func _animate_line(rigs: Array[CreatureRig], frames: int) -> void:
	for rig in rigs:
		for _frame in frames:
			rig.animate(POSE_DELTA, 0.0)


func _review_silhouettes() -> void:
	_camera.environment = _flat_environment(Color.WHITE)
	_aim(ROOM_FOV, SILHOUETTE_EYE, Vector3(0.0, SILHOUETTE_EYE.y, 0.0))
	# Sem FXAA: a borda continua preta ou branca depois da ampliação.
	var previous_aa: Viewport.ScreenSpaceAA = _stage.screen_space_aa
	_stage.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	await _silhouette_sheet(black, false, "silhouettes.png")
	await _silhouette_sheet(black, true, "silhouettes_noweapon.png")
	_stage.screen_space_aa = previous_aa


func _silhouette_sheet(black: Material, hide_weapons: bool, file_name: String) -> void:
	var rigs: Array[CreatureRig] = _spawn_line(Vector3.RIGHT, SILHOUETTE_SPACING)
	for rig in rigs:
		for mesh: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = black
		if hide_weapons:
			_hide_weapons(rig)
	var center: Vector2i = Vector2i(_camera.unproject_position(SILHOUETTE_CENTER))
	var region := Rect2i(center - SILHOUETTE_CROP / 2, SILHOUETTE_CROP)
	var bands: Array[Image] = []
	for yaw in SILHOUETTE_YAWS:
		_set_line_yaw(rigs, yaw)
		var band: Image = (await _shoot()).get_region(region)
		band.resize(region.size.x * SILHOUETTE_ZOOM, region.size.y * SILHOUETTE_ZOOM, Image.INTERPOLATE_NEAREST)
		bands.append(band)
	_save(_sheet(bands, 1), file_name)
	_despawn_line(rigs)


## A arma é um Node3D preso à mão. As peças da própria mão são MeshInstance3D.
func _hide_weapons(rig: CreatureRig) -> void:
	for hand: StringName in [&"hand_r", &"hand_l"]:
		for child in rig.get_joint(hand).get_children():
			if not child is MeshInstance3D:
				(child as Node3D).visible = false


func _review_room() -> void:
	var dungeon: DungeonData = GameDB.dungeon(DUNGEON_ID)
	var world := DungeonWorld.new()
	world.quality = DungeonEnvironment.Quality.MEDIUM
	_camera.environment = null
	_stage.add_child(world)
	world.build(dungeon, dungeon.ranks[0].color)
	var direction: Vector3 = (EYE_TARGET - EYE).normalized()
	# As luzes com sombra são escolhidas pela posição do foco: a câmera já precisa estar na sala.
	_aim(ROOM_FOV, EYE, EYE + direction)
	world.focus = _camera
	for _frame in ROOM_WARMUP_FRAMES:
		await get_tree().process_frame
	await _review_turns(world, direction)
	await _review_line_in_room(world, direction)
	await _review_tiers_in_room(world, direction)
	await _review_viewmodels(world, direction)
	_despawn(world)


## Partículas nascem ao acaso e mudam a cada quadro. Escondidas, a máscara só pega o herói.
func _show_particles(world: DungeonWorld, shown: bool) -> void:
	for particles: GPUParticles3D in world.find_children("*", "GPUParticles3D", true, false):
		particles.visible = shown


func _ground(world: DungeonWorld, point: Vector3) -> Vector3:
	return world.field.ground_position(Vector2(point.x, point.z))


func _review_turns(world: DungeonWorld, direction: Vector3) -> void:
	var spot: Vector3 = _ground(world, EYE + direction * TURN_DISTANCE)
	_aim(TURN_FOV, EYE + TURN_EYE_OFFSET, spot + Vector3.UP * TURN_AIM_HEIGHT)
	_show_particles(world, false)
	for class_id in _classes:
		var plate: Image = await _shoot()
		# O T0 é renderizado primeiro: é a referência do Selo (P7) para os outros tiers.
		var reference: Dictionary = {}
		if _tier != 0:
			var base: CreatureRig = _spawn_hero(class_id, 0)
			base.position = spot
			_face_camera(base, 0.0)
			var base_front: Image = await _shoot()
			_face_camera(base, BACK_YAW)
			reference = _seal_reference(base, base_front, await _shoot())
			_despawn(base)
		var rig: CreatureRig = _spawn_hero(class_id, _tier)
		rig.position = spot
		var views: Array[Image] = await _turnaround(rig)
		if _tier == 0:
			reference = _seal_reference(rig, views[0], views[BACK_VIEW])
		_models[class_id].merge(_mesh_stats(rig, HERO_BUDGETS[_tier]))
		_models[class_id].merge(_measure(class_id, plate, views[0], views[BACK_VIEW]))
		_models[class_id].merge(_tier_report(rig, views[0], views[BACK_VIEW], reference))
		_save(_turn_sheet(views), "turn_%s.png" % class_id)
		_despawn(rig)
	_show_particles(world, true)


func _review_line_in_room(world: DungeonWorld, direction: Vector3) -> void:
	var right: Vector3 = direction.cross(Vector3.UP)
	_aim(ROOM_FOV, EYE, EYE + direction)
	var rigs: Array[CreatureRig] = _spawn_line(Vector3.ZERO, 0.0)
	for shot in ROOM_SHOTS:
		_place_line(world, rigs, EYE + direction * shot.x + right * shot.z, right, shot.y)
		await _shoot_line(rigs, int(shot.x))
	await _move_room_camera(world, FAR_EYE, FAR_TARGET)
	var far_right: Vector3 = (FAR_TARGET - FAR_EYE).normalized().cross(Vector3.UP)
	_place_line(world, rigs, FAR_TARGET, far_right, FAR_SPACING)
	await _shoot_line(rigs, FAR_DISTANCE)
	_despawn_line(rigs)


## A grade de `tiers_<classe>.png` no enquadramento de `room_10`: um herói por quadro, no centro da fileira.
## Partículas escondidas, para os recortes só diferirem pelo herói.
func _review_tiers_in_room(world: DungeonWorld, direction: Vector3) -> void:
	await _move_room_camera(world, EYE, EYE + direction)
	_show_particles(world, false)
	var shot: Vector3 = ROOM_SHOTS[TIER_ROOM_SHOT]
	var spot: Vector3 = _ground(world, EYE + direction * shot.x + direction.cross(Vector3.UP) * shot.z)
	for class_id in _classes:
		var fronts: Array[Image] = []
		var backs: Array[Image] = []
		for hero_tier in AVAILABLE_TIERS:
			var rig: CreatureRig = _spawn_hero(class_id, hero_tier)
			rig.position = spot
			_face_camera(rig, 0.0)
			fronts.append(await _shoot_crop(spot))
			_face_camera(rig, BACK_YAW)
			backs.append(await _shoot_crop(spot))
			_despawn(rig)
		_save(_sheet(fronts + backs, AVAILABLE_TIERS.size()), "tiers_%s_room10.png" % class_id)
	_show_particles(world, true)


func _shoot_crop(spot: Vector3) -> Image:
	var center: Vector2i = Vector2i(_camera.unproject_position(spot + Vector3.UP * TIER_ROOM_CENTER_HEIGHT))
	var image: Image = await _shoot()
	return image.get_region(Rect2i(center - TIER_ROOM_CROP / 2, TIER_ROOM_CROP))


## O temporizador da sala só troca as luzes com sombra a cada 0,4 s: sem forçar a troca,
## a sombra mudaria conforme o quadro em que ele dispara.
func _move_room_camera(world: DungeonWorld, from: Vector3, target: Vector3) -> void:
	_aim(ROOM_FOV, from, target)
	world._update_light_shadows()
	for _frame in ROOM_WARMUP_FRAMES:
		await get_tree().process_frame


func _place_line(world: DungeonWorld, rigs: Array[CreatureRig], center: Vector3, across: Vector3, spacing: float) -> void:
	var middle: float = (rigs.size() - 1) * 0.5
	for index in rigs.size():
		rigs[index].position = _ground(world, center + across * (float(index) - middle) * spacing)


func _shoot_line(rigs: Array[CreatureRig], distance: int) -> void:
	for side: Array in [["front", 0.0], ["back", BACK_YAW]]:
		for rig in rigs:
			_face_camera(rig, side[1])
		_save(await _shoot(), "room_%02d_%s.png" % [distance, side[0]])


func _review_viewmodels(world: DungeonWorld, direction: Vector3) -> void:
	await _move_room_camera(world, EYE, EYE + direction)
	for class_id in _classes:
		var look: HeroLook = _look_of(class_id, 0, _tier)
		var viewmodel := Viewmodel.new()
		_camera.add_child(viewmodel)
		viewmodel.setup(GameDB.class_by_id(class_id), look)
		viewmodel.update_motion(0.0, 0.0, 0.0, true)
		_models[class_id]["viewmodel"] = _mesh_stats(viewmodel, VIEWMODEL_BUDGET)
		_save(await _shoot(), "vm_%s_%s.png" % [class_id, look.weapon_model])
		# Prova da troca de armadura na mesma cena: o antebraço muda o metal do tier.
		var armored: HeroLook = _look_of(class_id, 0, _tier)
		armored.armor_tier = 2
		viewmodel.setup(GameDB.class_by_id(class_id), armored)
		viewmodel.update_motion(0.0, 0.0, 0.0, true)
		_models[class_id]["viewmodel_t2"] = _mesh_stats(viewmodel, VIEWMODEL_BUDGET)
		_save(await _shoot(), "vm_%s_%s_t2.png" % [class_id, look.weapon_model])
		_despawn(viewmodel)


func _review_lobby() -> void:
	# Duas WorldEnvironment na mesma cena não convivem: a sala saiu e o saguão entra sozinho.
	await get_tree().process_frame
	var lobby := LobbyStage.new()
	_stage.add_child(lobby)
	lobby.build(GameDB.dungeon(DUNGEON_ID).ranks[0].color)
	for _frame in ROOM_WARMUP_FRAMES:
		await get_tree().process_frame
	await _review_mannequin(lobby)
	for class_id in _classes:
		lobby.show_hero(_look_of(class_id, 0, _tier))
		_save(await _shoot(), "lobby_%s.png" % class_id)


## Esqueleto do guerreiro só com a base comum (OS-007), no palco real do saguão e antes de qualquer herói.
func _review_mannequin(lobby: LobbyStage) -> void:
	var skin: Material = Look.hero(MANNEQUIN_SKIN, 0.7)
	var rig := CreatureRig.new()
	CreatureRig.biped_skeleton(rig, 1.0, 1.0, 1.0)
	var head: Node3D = HeroBase.head(rig, skin)
	for hand: StringName in [&"hand_r", &"hand_l"]:
		HeroBase.hand(rig, hand, skin)
	HeroBase.boots(rig, Look.hero(MANNEQUIN_STEEL, 0.42, 0.35))
	var chest: Node3D = rig.get_joint(&"chest")
	for seal_position: Vector3 in MANNEQUIN_SEALS:
		HeroBase.seal(rig, chest, seal_position, MANNEQUIN_SEAL_COLOR, Look.trim(0))
	lobby.add_child(rig)
	rig.position = LobbyStage.HERO_POSITION
	rig.rotation.y = LobbyStage.TURNTABLE_START_YAW
	rig.animate(0.0, 0.0)
	var camera: Camera3D = _stage.get_camera_3d()
	var crown: Vector2 = camera.unproject_position(head.global_transform * Vector3(0.0, 0.02 + HeroBase.HEAD_RINGS[-1].y, 0.0))
	var chin: Vector2 = camera.unproject_position(head.global_transform * Vector3(0.0, 0.02, 0.0))
	_mannequin = {"head_px": snappedf(chin.y - crown.y, 0.1), "crown_px": crown, "chin_px": chin}
	_save(await _shoot(), "mannequin.png")
	_despawn(rig)


## Partes, triângulos e medidas no espaço do próprio modelo, na pose atual.
func _mesh_stats(root: Node3D, budget: Dictionary) -> Dictionary:
	var to_root: Transform3D = root.global_transform.affine_inverse()
	var parts: int = 0
	var tris: int = 0
	var materials: Dictionary = {}
	var all_points := PackedVector3Array()
	var key_points := PackedVector3Array()
	for instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if instance.mesh == null or not instance.is_visible_in_tree():
			continue
		var points: PackedVector3Array = (to_root * instance.global_transform) * instance.mesh.get_faces()
		parts += 1
		tris += floori(points.size() / 3.0)
		all_points.append_array(points)
		if instance.get_meta(&"measure", false):
			key_points.append_array(points)
		if instance.material_override != null:
			materials[instance.material_override] = true
	return {
		"parts": parts,
		"tris": tris,
		"materials": materials.size(),
		"height_m": snappedf(_bounds(all_points).size.y, 0.001),
		"key_width_m": snappedf(_bounds(key_points).size.x, 0.001),
		"limit_ok": parts <= budget["parts"] and tris <= budget["tris"] and materials.size() <= budget["materials"],
	}


## Peças marcadas com `set_meta(&"tier", N)`: medidas no espaço do modelo, na pose atual.
func _tier_pieces(root: Node3D) -> Array[Dictionary]:
	var to_root: Transform3D = root.global_transform.affine_inverse()
	var pieces: Array[Dictionary] = []
	for instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if instance.mesh == null or not instance.has_meta(&"tier") or not instance.is_visible_in_tree():
			continue
		var box: AABB = _bounds((to_root * instance.global_transform) * instance.mesh.get_faces())
		pieces.append({
			"name": String(instance.name),
			"tier": int(instance.get_meta(&"tier")),
			"size_m": _rounded(box.size),
			"center_m": _rounded(box.get_center()),
			"lstar": snappedf(_albedo_lstar(instance), 0.1),
			"back_area_m2": snappedf(box.size.x * box.size.y, 0.0001),
		})
	return pieces


func _rounded(vector: Vector3) -> Array[float]:
	return [snappedf(vector.x, 0.001), snappedf(vector.y, 0.001), snappedf(vector.z, 0.001)]


## L* do `albedo_color` do material da peça. Com emissão de energia 0,5 ou mais (`Look.glow` escurece o albedo
## em 40%), vale o maior entre o L* do albedo e o da cor de emissão. -1 quando a peça não tem material com albedo.
func _albedo_lstar(instance: MeshInstance3D) -> float:
	var material := instance.material_override as BaseMaterial3D
	if material == null:
		material = instance.mesh.surface_get_material(0) as BaseMaterial3D
	if material == null:
		return -1.0
	var lstar: float = _lightness(material.albedo_color.srgb_to_linear())
	if material.emission_enabled and material.emission_energy_multiplier >= P9_GLOW_MIN_ENERGY:
		lstar = maxf(lstar, _lightness(material.emission.srgb_to_linear()))
	return lstar


## P1, P8 e P9 de um herói montado. P7 precisa de render e fica em `_tier_report`.
## `pieces` é o resultado de `_tier_pieces(rig)`; em T0 a lista é vazia e tudo vale `true`.
func _tier_checks(rig: CreatureRig, pieces: Array[Dictionary], tier: int) -> Dictionary:
	if tier == 0:
		return {"p1_ok": true, "p8_ok": true, "p9_ok": true}
	var p1_ok: bool = false
	var p9_ok: bool = true
	for piece in pieces:
		var size: Array = piece["size_m"]
		if piece["tier"] == tier and maxf(size[0], maxf(size[1], size[2])) >= P1_MIN_SIZE:
			p1_ok = true
		if piece["back_area_m2"] >= P9_MIN_AREA and piece["lstar"] < P9_MIN_LSTAR:
			p9_ok = false
	return {"p1_ok": p1_ok, "p8_ok": _outside_face(rig), "p9_ok": p9_ok}


## P8: nenhum vértice de peça de tier no volume do rosto, no frame do joint `head`.
func _outside_face(rig: CreatureRig) -> bool:
	var to_head: Transform3D = rig.get_joint(&"head").global_transform.affine_inverse()
	for instance: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		if instance.mesh == null or not instance.has_meta(&"tier") or instance.get_meta(&"face_cover", false):
			continue
		for point in (to_head * instance.global_transform) * instance.mesh.get_faces():
			if absf(point.x) <= P8_HEAD_X and point.y >= P8_HEAD_Y.x and point.y <= P8_HEAD_Y.y and point.z <= P8_HEAD_Z:
				return false
	return true


func _tier_report(rig: CreatureRig, front: Image, back: Image, reference: Dictionary) -> Dictionary:
	var pieces: Array[Dictionary] = []
	if _tier != 0:
		pieces = _tier_pieces(rig)
	var result: Dictionary = _tier_checks(rig, pieces, _tier)
	var front_ratio: float = _seal_ratio(rig, front, &"front", reference)
	var back_ratio: float = _seal_ratio(rig, back, &"back", reference)
	result["seal_front_ratio"] = snappedf(front_ratio, 0.001)
	result["seal_back_ratio"] = snappedf(back_ratio, 0.001)
	result["p7_ok"] = _tier == 0 or (front_ratio >= P7_MIN_RATIO and back_ratio >= P7_MIN_RATIO)
	result["tier_pieces"] = pieces
	return result


## Disco de luz do Selo (`set_meta(&"seal", &"front" ou &"back")`) projetado na câmera, com a frente ou as costas viradas para ela.
func _seal_probe(rig: CreatureRig, side: StringName) -> Dictionary:
	_face_camera(rig, 0.0 if side == &"front" else BACK_YAW)
	for instance: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		if instance.get_meta(&"seal", &"") == side:
			var center: Vector3 = instance.global_position
			var edge: Vector3 = center + _camera.global_transform.basis.x * SEAL_RADIUS
			var middle: Vector2 = _camera.unproject_position(center)
			return {"center": middle, "radius": middle.distance_to(_camera.unproject_position(edge))}
	return {}


## Cor lida no centro do Selo e pixels do círculo projetado a menos de SEAL_COLOR_TOLERANCE dela.
func _seal_reference(rig: CreatureRig, front: Image, back: Image) -> Dictionary:
	var reference: Dictionary = {}
	for side: StringName in [&"front", &"back"]:
		var image: Image = front if side == &"front" else back
		var probe: Dictionary = _seal_probe(rig, side)
		if probe.is_empty():
			reference[side] = {"count": 0}
			continue
		var color: Color = image.get_pixelv(Vector2i(probe["center"]))
		reference[side] = {"color": color, "count": _seal_pixels(image, probe, color)}
	return reference


func _seal_ratio(rig: CreatureRig, image: Image, side: StringName, reference: Dictionary) -> float:
	var base: Dictionary = reference[side]
	if base["count"] == 0:
		return 0.0
	var probe: Dictionary = _seal_probe(rig, side)
	if probe.is_empty():
		return 0.0
	return float(_seal_pixels(image, probe, base["color"])) / float(base["count"])


func _seal_pixels(image: Image, probe: Dictionary, color: Color) -> int:
	var center: Vector2 = probe["center"]
	var radius: float = probe["radius"]
	var count: int = 0
	for y in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			if Vector2(x, y).distance_to(center) > radius:
				continue
			var pixel: Color = image.get_pixel(x, y)
			if Vector3(pixel.r - color.r, pixel.g - color.g, pixel.b - color.b).length() < SEAL_COLOR_TOLERANCE:
				count += 1
	return count


func _bounds(points: PackedVector3Array) -> AABB:
	if points.is_empty():
		return AABB()
	var box := AABB(points[0], Vector3.ZERO)
	for point in points:
		box = box.expand(point)
	return box


func _measure(class_id: StringName, plate: Image, front: Image, back: Image) -> Dictionary:
	var pixels: Dictionary = {"front": _hero_pixels(plate, front), "back": _hero_pixels(plate, back)}
	var high: Dictionary = {}
	var low: Dictionary = {}
	var v1_ok: bool = true
	for view: String in pixels:
		var zones: Vector2 = _rule_v1(pixels[view])
		high[view] = snappedf(zones.x, 0.1)
		low[view] = snappedf(zones.y, 0.1)
		v1_ok = v1_ok and zones.x >= V1_HIGH_MIN and zones.y >= 0.0 and zones.y <= V1_LOW_MAX
	var result: Dictionary = {"high_p90": high, "low_p10": low, "v1_ok": v1_ok}
	result.merge(_rule_v4(class_id, pixels))
	return result


## Pixels do herói nos SCAN_WIDTH px centrais, com altura e desvio do centro em metros.
func _hero_pixels(plate: Image, shot: Image) -> Dictionary:
	var width: int = shot.get_width()
	var height: int = shot.get_height()
	var pixels_per_meter: float = height / (2.0 * TURN_DISTANCE * tan(deg_to_rad(TURN_FOV * 0.5)))
	var empty_bytes: PackedByteArray = plate.get_data()
	var hero_bytes: PackedByteArray = shot.get_data()
	var left: int = floori((width - SCAN_WIDTH) * 0.5)
	var heights := PackedFloat32Array()
	var offsets := PackedFloat32Array()
	var lightness := PackedFloat32Array()
	var linear := PackedColorArray()
	for y in height:
		var height_m: float = TURN_AIM_HEIGHT + (height * 0.5 - y) / pixels_per_meter
		for x in range(left, left + SCAN_WIDTH, SCAN_STEP):
			var index: int = (y * width + x) * 3
			var red: int = hero_bytes[index]
			var green: int = hero_bytes[index + 1]
			var blue: int = hero_bytes[index + 2]
			var difference: int = absi(red - empty_bytes[index]) + absi(green - empty_bytes[index + 1]) + absi(blue - empty_bytes[index + 2])
			if difference <= MASK_THRESHOLD:
				continue
			var color := Color(_srgb_to_linear[red], _srgb_to_linear[green], _srgb_to_linear[blue])
			heights.append(height_m)
			offsets.append((x - width * 0.5) / pixels_per_meter)
			lightness.append(_lightness(color))
			linear.append(color)
	return {"heights": heights, "offsets": offsets, "lightness": lightness, "linear": linear}


## CIE L* a partir de RGB linear, com luminância D65.
func _lightness(color: Color) -> float:
	var luminance: float = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	return 116.0 * pow(luminance, 1.0 / 3.0) - 16.0 if luminance > 0.008856 else 903.3 * luminance


## x = p90 da zona alta, y = p10 da zona baixa. -1 quando a zona não tem pixels.
func _rule_v1(pixels: Dictionary) -> Vector2:
	var heights: PackedFloat32Array = pixels["heights"]
	var lightness: PackedFloat32Array = pixels["lightness"]
	var high := PackedFloat32Array()
	var low := PackedFloat32Array()
	for index in heights.size():
		if heights[index] > V1_HIGH_ABOVE:
			high.append(lightness[index])
		elif heights[index] > V1_LOW_RANGE.x and heights[index] < V1_LOW_RANGE.y:
			low.append(lightness[index])
	return Vector2(_percentile(high, 0.9), _percentile(low, 0.1))


func _percentile(values: PackedFloat32Array, fraction: float) -> float:
	if values.is_empty():
		return -1.0
	values.sort()
	return values[int(values.size() * fraction)]


func _rule_v4(class_id: StringName, pixels: Dictionary) -> Dictionary:
	var mass: Dictionary = V4_MASSES[class_id]
	var range_m: Vector2 = mass["height"]
	var half_width: float = mass["half_width"]
	var total := Vector3.ZERO
	var count: int = 0
	for view: String in mass["views"]:
		var view_pixels: Dictionary = pixels[view]
		var heights: PackedFloat32Array = view_pixels["heights"]
		var offsets: PackedFloat32Array = view_pixels["offsets"]
		var linear: PackedColorArray = view_pixels["linear"]
		for index in heights.size():
			if heights[index] >= range_m.x and heights[index] <= range_m.y and absf(offsets[index]) <= half_width:
				total += Vector3(linear[index].r, linear[index].g, linear[index].b)
				count += 1
	if count == 0:
		return {"mass_hue": -1.0, "mass_value": 0.0, "v4_ok": false}
	var mean: Vector3 = total / float(count)
	var srgb: Color = Color(mean.x, mean.y, mean.z).linear_to_srgb()
	var hue: float = srgb.h * 360.0
	var hue_error: float = absf(fposmod(hue - float(mass["hue"]) + 180.0, 360.0) - 180.0)
	return {
		"mass_hue": snappedf(hue, 0.1),
		"mass_value": snappedf(srgb.v, 0.001),
		"v4_ok": hue_error <= V4_MAX_HUE_ERROR and srgb.v >= V4_MIN_VALUE,
	}


func _write_report(elapsed: float) -> void:
	var models: Dictionary = {}
	for class_id in _classes:
		models[String(class_id)] = _models[class_id]
	var report: Dictionary = {
		"settings": {
			"dungeon": String(DUNGEON_ID),
			"quality": "medium",
			"resolution": [RESOLUTION.x, RESOLUTION.y],
			"tier": _tier,
			"variant": _variant,
			"weapon": String(_weapon_filter),
			"rarity": _rarity,
		},
		"elapsed_s": snappedf(elapsed, 0.1),
		"models": models,
		"mannequin": {"head_px": _mannequin.get("head_px", -1.0)},
	}
	var file: FileAccess = FileAccess.open(_out.path_join("report.json"), FileAccess.WRITE)
	if file == null:
		printerr("hero_review: falha ao gravar report.json: %s" % error_string(FileAccess.get_open_error()))
		_save_errors += 1
		return
	file.store_string(JSON.stringify(report, "\t"))
	_files += 1
