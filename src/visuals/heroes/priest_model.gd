class_name PriestModel
extends RefCounted
## Sacerdote T0 (ficha `documents/art/classes/priest.md`). Montado sobre a base comum do caçador.
## Sem pernas (J5): os joints continuam. Não depende de peças de inimigo (S4) nem da cor legada da armadura.
## A arma entra por `HeroBase.wield`; a luz real da lanterna do bastão nasce em `WeaponKit._scepter`.

const JADE := Color("247050")
const CREAM := Color("E6DCC0")
const HAT := Color("E2D6B6")
const UNDER_BRIM := Color("3A2E25")
const SLEEVE_LINING := Color("14231F")
const SATCHEL := Color("3A2A22")
const SKIN := Color("D9A981")
const CLASS_GOLD := Color("FFD76A")
const TOME_WEAPON := &"tome"
## Variante 1 (Vestes do Peregrino): `armor_variant` do `HeroLook`.
const PILGRIM_VARIANT := 1

const TORSO: Array[Vector4] = [
	Vector4(0.0, -0.08, 0.17, 0.125), Vector4(0.0, 0.16, 0.17, 0.125), Vector4(0.0, 0.34, 0.215, 0.135),
	Vector4(0.0, 0.47, 0.22, 0.13), Vector4(0.0, 0.54, 0.1, 0.09),
]
const COLLAR := [Vector2(0.17, 0.44), Vector2(0.13, 0.52), Vector2(0.08, 0.56)]
const SKIRT := [Vector2(0.41, -0.885), Vector2(0.405, -0.85), Vector2(0.325, -0.5), Vector2(0.235, -0.18), Vector2(0.195, 0.06)]
const HEM := [Vector2(0.42, -0.89), Vector2(0.413, -0.82), Vector2(0.39, -0.82)]
const OVERROBE := [Vector2(0.305, -0.3), Vector2(0.3, -0.27), Vector2(0.245, -0.1), Vector2(0.21, 0.06)]
const SASH := [Vector2(0.2, -0.03), Vector2(0.205, 0.1), Vector2(0.19, 0.13)]
const SKIRT_SCALE_Z := 0.86
const SASH_SCALE_Z := 0.72
const COLLAR_SCALE_Z := 0.75
const STOLA_ORIGIN := Vector3(0.0, 0.0, -0.22)
const SEAL_FRONT := Vector3(0.0, 0.33, -0.14)
const SEAL_BACK := Vector3(0.0, 0.42, 0.14)
const SLEEVE: Array[Vector4] = [Vector4(0.0, -0.32, 0.115, 0.12), Vector4(0.0, -0.2, 0.105, 0.11), Vector4(0.0, 0.02, 0.08, 0.085)]
const CUFF := [Vector2(0.12, -0.325), Vector2(0.122, -0.29)]
const CUFF_LINING: Array[Vector4] = [Vector4(0.0, -0.322, 0.108, 0.112), Vector4(0.0, -0.316, 0.108, 0.112)]
const TURBAN: Array[Vector4] = [Vector4(0.0, 0.185, 0.106, 0.122), Vector4(0.0, 0.215, 0.1, 0.116), Vector4(0.0, 0.25, 0.08, 0.09)]
const NAPE: Array[Vector4] = [Vector4(0.0, 0.03, 0.075, 0.07), Vector4(0.0, 0.12, 0.105, 0.09), Vector4(0.0, 0.2, 0.1, 0.09)]
const HAT_PROFILE := [Vector2(0.45, 0.0), Vector2(0.44, 0.02), Vector2(0.2, 0.125), Vector2(0.05, 0.195), Vector2(0.0, 0.2)]
const HAT_LINING := [Vector2(0.44, 0.0), Vector2(0.0, 0.05)]
const HAT_ORIGIN := Vector3(0.0, 0.215, 0.0)
const HAT_BAND_ORIGIN := Vector3(0.0, 0.27, 0.0)
const HAT_BAND_SCALE := Vector3(1.0, 0.45, 1.0)
const VEIL_ORIGIN := Vector3(0.0, 0.22, 0.125)
const SATCHEL_POS := Vector3(-0.26, -0.1, 0.0)
const BELT_LANTERN_POS := Vector3(0.31, -0.2, -0.06)
const BELT_LANTERN_ROOF := [Vector2(0.08, 0.06), Vector2(0.07, 0.07), Vector2(0.02, 0.1)]

## Tiers (OS-015). Peças cumulativas: `armor_tier` manda no manto, nos Selos e na lanterna de cinto; `head_tier`, na cabeça.
const MANTLE_COLOR := Color("D5D9E4")
const MANTLE_TIER := 1
const MANTLE: Array[Vector4] = [
	Vector4(0.0, 0.3, 0.27, 0.17), Vector4(0.0, 0.38, 0.26, 0.165), Vector4(0.0, 0.5, 0.2, 0.135), Vector4(0.0, 0.56, 0.1, 0.09),
]
## Os Selos saem para fora do manto: o traseiro de T0 ficaria 1,5 cm por dentro dele.
const SEAL_FRONT_MANTLE := Vector3(0.0, 0.4, -0.18)
const SEAL_BACK_MANTLE := Vector3(0.0, 0.42, 0.18)
const PENDANT_TIER := 2
const PENDANT_X := 0.4
const PENDANT_WIRE_Y := 0.13
const PENDANT_BEAD_Y := 0.02
const PENDANT_Z := 0.05
const PENDANT_BEAD_SCALE := Vector3(1.0, 1.25, 1.0)
const CROWN_TIER := 3
const SECOND_BRIM := [Vector2(0.22, 0.0), Vector2(0.21, 0.015), Vector2(0.09, 0.095), Vector2(0.0, 0.13)]
const SECOND_BRIM_ORIGIN := Vector3(0.0, 0.335, 0.0)
const RIBBON_X := 0.15
const RIBBON_Y := 0.22
const RIBBON_Z := 0.125
const SECOND_BELT_LANTERN_POS := Vector3(-0.31, -0.2, -0.06)


## Esqueleto, passada, corpo, cabeça e Selo. A pose de repouso dos braços vem de `HeroBase.wield`.
static func assemble(rig: CreatureRig, look: HeroLook) -> void:
	CreatureRig.biped_skeleton(rig, 0.95, 0.95, 1.0)
	rig.arm_swing_r = 0.2
	rig.arm_swing_l = 0.4
	rig.stride = 0.4
	var jade: Material = Look.hero(JADE, 0.8)
	var cream: Material = Look.hero(CREAM, 0.75)
	var trim: Material = Look.trim(look.armor_tier)
	_torso(rig, look, jade, cream, trim)
	_stola(rig, look)
	_seals(rig, look, trim)
	_limbs(rig, jade, cream, trim)
	_head(rig, look, cream, trim)
	_accessories(rig, look, trim)


static func _torso(rig: CreatureRig, look: HeroLook, jade: Material, cream: Material, trim: Material) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	rig.part(chest, MeshKit.loft(TORSO, 12), jade)
	rig.part(chest, MeshKit.lathe(PackedVector2Array(COLLAR), 12), cream, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, COLLAR_SCALE_Z))
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(SKIRT), 20), jade, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, SKIRT_SCALE_Z))
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(HEM), 20), trim, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, SKIRT_SCALE_Z))
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(OVERROBE), 20), cream, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, SKIRT_SCALE_Z))
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(SASH), 14), trim, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, SASH_SCALE_Z))
	if look.armor_tier >= MANTLE_TIER:
		_tier_piece(rig.part(chest, MeshKit.loft(MANTLE, 12), Look.hero(MANTLE_COLOR, 0.75)), "t1_manto", MANTLE_TIER)


## Nome único no rig e marca de tier: o `report.json` lista só o nome da peça.
static func _tier_piece(instance: MeshInstance3D, piece_name: String, tier: int) -> MeshInstance3D:
	instance.name = piece_name
	instance.set_meta(&"tier", tier)
	return instance


## Estola de metal por fora da sobreveste, com as duas faces (M1).
static func _stola(rig: CreatureRig, look: HeroLook) -> void:
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	var metal: Material = Look.two_sided(Look.TRIM_COLORS[clampi(look.armor_tier, 0, Look.TRIM_COLORS.size() - 1)], 0.5)
	rig.part(pelvis, MeshKit.cloth(0.11, 0.13, 0.36, 0.1, 1, 4), metal, STOLA_ORIGIN, Vector3(0.0, PI, 0.0))


## Com o manto (T1 em diante) os Selos saem para fora dele. `HeroBase.seal` não devolve o disco: ele é
## achado pela meta `seal` e marcado com o tier. O aro não se marca.
static func _seals(rig: CreatureRig, look: HeroLook, trim: Material) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var mantle: bool = look.armor_tier >= MANTLE_TIER
	HeroBase.seal(rig, chest, SEAL_FRONT_MANTLE if mantle else SEAL_FRONT, CLASS_GOLD, trim, 0.9)
	HeroBase.seal(rig, chest, SEAL_BACK_MANTLE if mantle else SEAL_BACK, CLASS_GOLD, trim, 0.9)
	if not mantle:
		return
	for child in chest.get_children():
		var side: StringName = child.get_meta(&"seal", &"")
		if side == &"front" or side == &"back":
			_tier_piece(child as MeshInstance3D, "t1_selo_frente" if side == &"front" else "t1_selo_costas", MANTLE_TIER)


## Braço de jade e manga de sino creme. O punho é aberto (`close_ends = false`) e o fundo escuro fecha a boca.
static func _limbs(rig: CreatureRig, jade: Material, cream: Material, trim: Material) -> void:
	var skin: Material = Look.hero(SKIN, 0.7)
	var lining: Material = Look.matte(SLEEVE_LINING, 0.9)
	for side: StringName in [&"r", &"l"]:
		var elbow: Node3D = rig.get_joint(StringName("elbow_%s" % side))
		CreatureRig.limb(rig, StringName("shoulder_%s" % side), 0.3, 0.07, 0.075, jade)
		rig.part(elbow, MeshKit.sphere(0.075, 8), jade)
		rig.part(elbow, MeshKit.loft(SLEEVE, 12), cream)
		rig.part(elbow, MeshKit.lathe(PackedVector2Array(CUFF), 12, true, false), trim)
		rig.part(elbow, MeshKit.loft(CUFF_LINING, 12), lining)
		HeroBase.hand(rig, StringName("hand_%s" % side), skin)


## Rosto à mostra (R2): turbante e nuca em duas peças, chapéu largo em duas peças e véu atrás.
static func _head(rig: CreatureRig, look: HeroLook, cream: Material, trim: Material) -> void:
	var head: Node3D = HeroBase.head(rig, Look.hero(SKIN, 0.7))
	rig.part(head, MeshKit.loft(TURBAN, 10), cream, Vector3(0.0, 0.0, 0.008))
	rig.part(head, MeshKit.loft(NAPE, 10), cream, Vector3(0.0, 0.0, 0.04))
	# Sem tampa embaixo: ela ficaria no mesmo plano do forro e brigaria com ele (z-fighting) visto de baixo.
	var hat_material: Material = Look.hero(HAT, 0.45)
	var hat: MeshInstance3D = rig.part(head, MeshKit.lathe(PackedVector2Array(HAT_PROFILE), 16, false, false), hat_material, HAT_ORIGIN)
	hat.set_meta(&"measure", true)
	rig.part(head, MeshKit.lathe(PackedVector2Array(HAT_LINING), 16, false), Look.matte(UNDER_BRIM, 0.7), HAT_ORIGIN)
	rig.part(head, MeshKit.torus(0.12, 0.145, 16), trim, HAT_BAND_ORIGIN, Vector3.ZERO, HAT_BAND_SCALE)
	var veil: Material = Look.two_sided(CREAM, 0.75)
	rig.part(head, MeshKit.cloth(0.24, 0.3, 0.26, 0.06, 4, 3), veil, VEIL_ORIGIN)
	var head_trim: Material = Look.trim(look.head_tier)
	if look.head_tier >= PENDANT_TIER:
		_pendants(rig, head, head_trim)
	if look.head_tier >= CROWN_TIER:
		_second_brim_and_ribbons(rig, head, hat_material, veil)


## Dois pingentes largos na aba, um de cada lado (E1). Direito em +x, como os joints `*_r`.
static func _pendants(rig: CreatureRig, head: Node3D, metal: Material) -> void:
	for side: StringName in [&"r", &"l"]:
		var mirror: float = 1.0 if side == &"r" else -1.0
		var wire: MeshInstance3D = rig.part(head, MeshKit.cylinder(0.005, 0.005, 0.2, 6), metal, Vector3(mirror * PENDANT_X, PENDANT_WIRE_Y, PENDANT_Z))
		_tier_piece(wire, "t2_pingente_%s_fio" % side, PENDANT_TIER)
		var bead: MeshInstance3D = rig.part(head, MeshKit.sphere(0.06, 10), metal, Vector3(mirror * PENDANT_X, PENDANT_BEAD_Y, PENDANT_Z), Vector3.ZERO, PENDANT_BEAD_SCALE)
		_tier_piece(bead, "t2_pingente_%s_esfera" % side, PENDANT_TIER)


## Segunda aba, menor, sobre a copa, e as duas fitas atrás: o véu de T0 fica e as fitas saem do mesmo pano.
static func _second_brim_and_ribbons(rig: CreatureRig, head: Node3D, hat_material: Material, veil: Material) -> void:
	var brim: MeshInstance3D = rig.part(head, MeshKit.lathe(PackedVector2Array(SECOND_BRIM), 16, false, false), hat_material, SECOND_BRIM_ORIGIN)
	_tier_piece(brim, "t3_aba_2", CROWN_TIER)
	for side: StringName in [&"r", &"l"]:
		var mirror: float = 1.0 if side == &"r" else -1.0
		var ribbon: MeshInstance3D = rig.part(head, MeshKit.cloth(0.07, 0.08, 0.5, 0.04, 1, 4), veil, Vector3(mirror * RIBBON_X, RIBBON_Y, RIBBON_Z))
		_tier_piece(ribbon, "t3_fita_%s" % side, CROWN_TIER)


## Alforje da variante do Peregrino, lanterna de cinto do tomo (só o núcleo emissivo: a luz real é do bastão)
## e, em T3, a segunda lanterna de cinto do outro lado, com qualquer arma.
static func _accessories(rig: CreatureRig, look: HeroLook, trim: Material) -> void:
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	if look.armor_tier == 0 and look.armor_variant == PILGRIM_VARIANT:
		rig.part(pelvis, MeshKit.box(Vector3(0.16, 0.12, 0.06)), Look.hero(SATCHEL, 0.8), SATCHEL_POS)
	if look.weapon_model == TOME_WEAPON:
		rig.part(pelvis, MeshKit.lathe(PackedVector2Array(BELT_LANTERN_ROOF), 6, false), trim, BELT_LANTERN_POS)
		rig.part(pelvis, MeshKit.sphere(0.05, 10), Look.glow(CLASS_GOLD, 0.9), BELT_LANTERN_POS)
	if look.armor_tier >= CROWN_TIER:
		var roof: MeshInstance3D = rig.part(pelvis, MeshKit.lathe(PackedVector2Array(BELT_LANTERN_ROOF), 6, false), trim, SECOND_BELT_LANTERN_POS)
		_tier_piece(roof, "t3_lanterna_cinto_teto", CROWN_TIER)
		var core: MeshInstance3D = rig.part(pelvis, MeshKit.sphere(0.05, 10), Look.glow(CLASS_GOLD, 0.9), SECOND_BELT_LANTERN_POS)
		_tier_piece(core, "t3_lanterna_cinto_nucleo", CROWN_TIER)
