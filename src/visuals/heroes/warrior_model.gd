class_name WarriorModel
extends RefCounted
## Guerreiro T0 (ficha `documents/art/classes/warrior.md`). Montado sobre a base comum do caçador.
## Não depende de peças de inimigo (S4) nem da cor legada da armadura. A arma entra por `HeroBase.wield`.

const STEEL := Color("B0AEA8")
const STEEL_MAIL := Color("8F8D88")
const STEEL_DARK := Color("6F6D69")
const DARK := Color("23262E")
const TABARD := Color("C23A22")
const CAPE := Color("B3301F")
const LEATHER := Color("3A2A22")
const SKIN := Color("D9A981")
const SEAL_COLOR := Color("E0603A")
## Variante 0 (Cota de Malha): `armor_variant` do `HeroLook`.
const MAIL_VARIANT := 0

const CUIRASS: Array[Vector4] = [
	Vector4(0.0, -0.1, 0.19, 0.135), Vector4(0.0, 0.1, 0.2, 0.145), Vector4(0.0, 0.3, 0.3, 0.19),
	Vector4(0.0, 0.46, 0.31, 0.18), Vector4(0.0, 0.55, 0.13, 0.11),
]
const GORGET := [Vector2(0.14, 0.5), Vector2(0.122, 0.55), Vector2(0.1, 0.58), Vector2(0.06, 0.585)]
const FAULDS := [
	Vector2(0.28, -0.3), Vector2(0.27, -0.22), Vector2(0.25, -0.22), Vector2(0.25, -0.13),
	Vector2(0.23, -0.13), Vector2(0.22, -0.04), Vector2(0.2, -0.04), Vector2(0.21, 0.05),
]
const BELT := [Vector2(0.215, 0.0), Vector2(0.225, 0.07), Vector2(0.21, 0.1)]
const HELM := [Vector2(0.12, 0.172), Vector2(0.128, 0.205), Vector2(0.105, 0.26), Vector2(0.06, 0.295), Vector2(0.0, 0.305)]
const NAPE: Array[Vector4] = [Vector4(0.0, -0.02, 0.11, 0.075), Vector4(0.0, 0.18, 0.125, 0.08)]
const CREST := [
	Vector2(-0.15, 0.17), Vector2(-0.13, 0.27), Vector2(-0.06, 0.36), Vector2(0.05, 0.4),
	Vector2(0.17, 0.37), Vector2(0.25, 0.28), Vector2(0.27, 0.15), Vector2(0.1, 0.2),
]
## Variante 0: telhas alta e baixa da ficha (linha T0 da tabela de tiers), sem a média.
const MAIL_TOP: Array[Vector4] = [
	Vector4(0.0855, -0.13, 0.1662, 0.2), Vector4(0.0475, -0.05, 0.1568, 0.195),
	Vector4(0.0095, 0.05, 0.1235, 0.17), Vector4(-0.019, 0.115, 0.0712, 0.11),
]
const MAIL_LOW: Array[Vector4] = [
	Vector4(0.1496, -0.22, 0.1012, 0.16), Vector4(0.132, -0.15, 0.1188, 0.175), Vector4(0.0968, -0.09, 0.0968, 0.145),
]
const LOW_TILE: Array[Vector4] = [Vector4(0.17, -0.33, 0.115, 0.16), Vector4(0.15, -0.24, 0.135, 0.175), Vector4(0.11, -0.17, 0.11, 0.145)]
const MID_TILE: Array[Vector4] = [Vector4(0.14, -0.24, 0.145, 0.185), Vector4(0.11, -0.14, 0.16, 0.195), Vector4(0.07, -0.07, 0.13, 0.165)]
const TOP_TILE: Array[Vector4] = [
	Vector4(0.09, -0.13, 0.175, 0.2), Vector4(0.05, -0.05, 0.165, 0.195),
	Vector4(0.01, 0.05, 0.13, 0.17), Vector4(-0.02, 0.115, 0.075, 0.11),
]
const PAULDRON_ORIGIN_X := 0.21
const PAULDRON_ORIGIN_Y := 0.5
const SEAL_FRONT := Vector3(0.0, 0.38, -0.205)
const SEAL_BACK := Vector3(0.0, 0.54, 0.2)
const CAPE_ORIGIN := Vector3(0.0, 0.52, 0.17)

## Tiers (OS-013). Peças cumulativas. `armor_tier` manda no corpo, `head_tier` na crista e na máscara. A canela fica escura nos 4 tiers (P2, V1).
const FUR := Color("EEF1F6")
const COLLAR_TIER := 1
const COLLAR := [Vector2(0.3, 0.5), Vector2(0.29, 0.53), Vector2(0.23, 0.57), Vector2(0.17, 0.585)]
const COLLAR_SIDES := 14
const COLLAR_SCALE := Vector3(1.0, 1.0, 0.62)
const GROWN_TIER := 2
const PAULDRON_GROWTH := 1.1
const CREST_TALL_SCALE := Vector3(1.0, 1.5, 1.0)
const MASK_TIER := 3
const MASK: Array[Vector4] = [Vector4(0.0, 0.02, 0.06, 0.08), Vector4(0.0, 0.1, 0.098, 0.112), Vector4(0.0, 0.19, 0.103, 0.116)]
const MASK_SIDES := 10
const MASK_OFFSET := Vector3(0.0, 0.0, -0.006)
const VISOR_COLOR := Color("0C0E14")
const VISOR_SIZE := Vector3(0.11, 0.012, 0.02)
const VISOR_POSITION := Vector3(0.0, 0.135, -0.116)
const BLADE_TIER := 3
const BLADE_PROFILE := [Vector2(0.0, 0.0), Vector2(0.11, 0.0), Vector2(0.09, 0.2), Vector2(0.03, 0.32)]
const BLADE_THICKNESS := 0.04
const BLADE_ORIGIN := Vector3(0.33, 0.6, 0.0)
const BLADE_TILT := -0.3
const CAPE_LENGTH := 1.2
const CAPE_LONG_LENGTH := 1.42


## Esqueleto, passada, corpo, cabeça e Selo. A pose de repouso dos braços vem de `HeroBase.wield`.
static func assemble(rig: CreatureRig, look: HeroLook) -> void:
	CreatureRig.biped_skeleton(rig, 1.0, 1.0, 1.15)
	rig.arm_swing_r = 0.45
	rig.arm_swing_l = 0.15
	rig.stride = 0.75
	rig.knee_bend = 0.85
	var mail: bool = look.armor_tier == 0 and look.armor_variant == MAIL_VARIANT
	var steel: Material = Look.hero(STEEL, 0.42, 0.35)
	var torso_steel: Material = Look.hero(STEEL_MAIL, 0.42, 0.35) if mail else steel
	var dark: Material = Look.hero(DARK, 0.75)
	var trim: Material = Look.trim(look.armor_tier)
	_torso(rig, look, torso_steel, trim, mail)
	_cloth(rig, look)
	_seals(rig, trim)
	_collar(rig, look)
	_blades(rig, look)
	_limbs(rig, steel, dark)
	HeroBase.boots(rig, steel)
	_head(rig, look, steel)


static func _torso(rig: CreatureRig, look: HeroLook, steel: Material, trim: Material, mail: bool) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	var plate: Material = Look.hero(STEEL, 0.42, 0.35)
	rig.part(chest, MeshKit.loft(CUIRASS, 8, false), steel)
	rig.part(chest, MeshKit.lathe(PackedVector2Array(GORGET), 10, false), Look.hero(STEEL_DARK, 0.42, 0.35), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.85))
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(FAULDS), 10, false), plate, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.78))
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(BELT), 12, false), trim, Vector3(0.0, 0.02, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.78))
	for side: float in [1.0, -1.0]:
		_pauldron(rig, chest, side, steel, trim, mail, look.armor_tier >= GROWN_TIER)


## Nome único no rig e marca de tier: o `report.json` lista só o nome da peça.
static func _tier_piece(instance: MeshInstance3D, piece_name: String, tier: int) -> MeshInstance3D:
	instance.name = piece_name
	instance.set_meta(&"tier", tier)
	return instance


## Ombreira em telhas, no `chest` (J3). Cada telha tem o centro deslocado em x e leva `measure` para o relatório.
## Com `grown` (T2 em diante) a origem, o centro_x e o raio_x ficam 10% maiores e as 6 telhas entram como peças do tier 2.
static func _pauldron(rig: CreatureRig, chest: Node3D, side: float, steel: Material, trim: Material, mail: bool, grown: bool) -> void:
	var growth: float = PAULDRON_GROWTH if grown else 1.0
	var origin := Vector3(side * PAULDRON_ORIGIN_X * growth, PAULDRON_ORIGIN_Y, 0.0)
	var low: Array[Vector4] = _mirror(MAIL_LOW if mail else LOW_TILE, side, growth)
	var mid: Array[Vector4] = _mirror(MID_TILE, side, growth)
	var top: Array[Vector4] = _mirror(MAIL_TOP if mail else TOP_TILE, side, growth)
	var tiles: Dictionary = {
		&"baixa": rig.part(chest, MeshKit.loft(low, 8, false), trim, origin),
		&"alta": rig.part(chest, MeshKit.loft(top, 8, false), steel, origin),
	}
	if not mail:
		tiles[&"media"] = rig.part(chest, MeshKit.loft(mid, 8, false), steel, origin)
	for tile_name: StringName in tiles:
		var tile: MeshInstance3D = tiles[tile_name]
		tile.set_meta(&"measure", true)
		if grown:
			_tier_piece(tile, "t2_telha_%s_%s" % ["r" if side > 0.0 else "l", tile_name], GROWN_TIER)


## Anéis da ficha com o centro_x espelhado para o lado `side` e `centro_x` e `raio_x` multiplicados por `growth`.
static func _mirror(rings: Array[Vector4], side: float, growth: float = 1.0) -> Array[Vector4]:
	var result: Array[Vector4] = []
	for ring: Vector4 in rings:
		result.append(Vector4(ring.x * side * growth, ring.y, ring.z * growth, ring.w))
	return result


## Tabardo preso à pélvis e capa fendida no joint `cloth_back` (J4).
static func _cloth(rig: CreatureRig, look: HeroLook) -> void:
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	var chest: Node3D = rig.get_joint(&"chest")
	rig.part(pelvis, MeshKit.cloth(0.26, 0.32, 0.78, 0.05, 4, 5), Look.two_sided(TABARD, 0.85), Vector3(0.0, 0.0, -0.245), Vector3(0.0, PI, 0.0))
	var cape_joint: Node3D = rig.joint(&"cloth_back", chest, CAPE_ORIGIN)
	var cape: Material = Look.two_sided(CAPE, 0.85)
	var length: float = CAPE_LONG_LENGTH if look.armor_tier >= BLADE_TIER else CAPE_LENGTH
	for side: float in [1.0, -1.0]:
		rig.part(cape_joint, MeshKit.cloth(0.25, 0.38, length, 0.26, 6, 7), cape, Vector3(side * 0.125, 0.0, 0.0), Vector3(0.0, side * 0.07, 0.0))


static func _seals(rig: CreatureRig, trim: Material) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	HeroBase.seal(rig, chest, SEAL_FRONT, SEAL_COLOR, trim, 1.0)
	HeroBase.seal(rig, chest, SEAL_BACK, SEAL_COLOR, trim, 1.0)


## Gola de pele no `chest`, parada sob o queixo (J3). Entra no T1.
static func _collar(rig: CreatureRig, look: HeroLook) -> void:
	if look.armor_tier < COLLAR_TIER:
		return
	var collar: MeshInstance3D = rig.part(rig.get_joint(&"chest"), MeshKit.lathe(PackedVector2Array(COLLAR), COLLAR_SIDES, false), Look.hero(FUR, 0.9), Vector3.ZERO, Vector3.ZERO, COLLAR_SCALE)
	_tier_piece(collar, "t1_gola", COLLAR_TIER)


## Lâminas nas ombreiras, no `chest` (J3). A esquerda é o perfil espelhado em x e na ordem inversa (G1), com a rotação em z de sinal oposto.
static func _blades(rig: CreatureRig, look: HeroLook) -> void:
	if look.armor_tier < BLADE_TIER:
		return
	var chest: Node3D = rig.get_joint(&"chest")
	var trim: Material = Look.trim(BLADE_TIER)
	var right := PackedVector2Array(BLADE_PROFILE)
	var left := PackedVector2Array()
	for index in range(BLADE_PROFILE.size() - 1, -1, -1):
		var point: Vector2 = BLADE_PROFILE[index]
		left.append(Vector2(-point.x, point.y))
	var right_blade: MeshInstance3D = rig.part(chest, MeshKit.plate(right, BLADE_THICKNESS), trim, BLADE_ORIGIN, Vector3(0.0, 0.0, BLADE_TILT))
	_tier_piece(right_blade, "t3_lamina_r", BLADE_TIER)
	var left_blade: MeshInstance3D = rig.part(chest, MeshKit.plate(left, BLADE_THICKNESS), trim, Vector3(-BLADE_ORIGIN.x, BLADE_ORIGIN.y, BLADE_ORIGIN.z), Vector3(0.0, 0.0, -BLADE_TILT))
	_tier_piece(left_blade, "t3_lamina_l", BLADE_TIER)


static func _limbs(rig: CreatureRig, steel: Material, dark: Material) -> void:
	for side: StringName in [&"r", &"l"]:
		var shoulder := StringName("shoulder_%s" % side)
		var elbow := StringName("elbow_%s" % side)
		var hip := StringName("hip_%s" % side)
		var knee := StringName("knee_%s" % side)
		CreatureRig.limb(rig, shoulder, 0.3, 0.08, 0.065, dark)
		rig.part(rig.get_joint(elbow), MeshKit.sphere(0.078, 8), steel)
		CreatureRig.limb(rig, elbow, 0.3, 0.08, 0.062, steel)
		HeroBase.hand(rig, StringName("hand_%s" % side), steel)
		CreatureRig.limb(rig, hip, 0.46, 0.105, 0.08, dark)
		rig.part(rig.get_joint(knee), MeshKit.sphere(0.098, 8), steel, Vector3(0.0, 0.0, -0.012))
		CreatureRig.limb(rig, knee, 0.46, 0.09, 0.07, dark)


## Rosto à mostra (R2): elmo aberto com nasal, jugulares, proteção da nuca e crista de placa.
## Com `head_tier` 3 a máscara fechada cobre o rosto e o nasal não existe: sua barra vertical cruzaria o visor (O2).
static func _head(rig: CreatureRig, look: HeroLook, steel: Material) -> void:
	var head: Node3D = HeroBase.head(rig, Look.hero(SKIN, 0.7))
	var masked: bool = look.head_tier >= MASK_TIER
	rig.part(head, MeshKit.lathe(PackedVector2Array(HELM), 8, false), steel)
	if not masked:
		rig.part(head, MeshKit.box(Vector3(0.024, 0.11, 0.02)), Look.trim(look.head_tier), Vector3(0.0, 0.165, -0.128))
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.box(Vector3(0.03, 0.185, 0.16)), steel, Vector3(side * 0.115, 0.0875, 0.0))
	rig.part(head, MeshKit.loft(NAPE, 8, false), steel, Vector3(0.0, 0.0, 0.075))
	var crest_scale: Vector3 = CREST_TALL_SCALE if look.head_tier >= GROWN_TIER else Vector3.ONE
	var crest: MeshInstance3D = rig.part(head, MeshKit.plate(PackedVector2Array(CREST), 0.05), Look.hero(TABARD, 0.5), Vector3.ZERO, Vector3(0.0, -PI * 0.5, 0.0), crest_scale)
	crest.name = "crista"
	if masked:
		var mask: MeshInstance3D = rig.part(head, MeshKit.loft(MASK, MASK_SIDES, false), Look.trim(MASK_TIER), MASK_OFFSET)
		var visor: MeshInstance3D = rig.part(head, MeshKit.box(VISOR_SIZE), Look.matte(VISOR_COLOR), VISOR_POSITION)
		for cover: MeshInstance3D in [mask, visor]:
			cover.set_meta(&"face_cover", true)
		_tier_piece(mask, "t3_mascara", MASK_TIER)
		_tier_piece(visor, "t3_visor", MASK_TIER)
