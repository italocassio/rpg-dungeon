class_name MageModel
extends RefCounted
## Mago T0 (ficha `documents/art/classes/mage.md`). Montado sobre a base comum do caçador.
## Não depende de peças de inimigo (S4) nem da cor legada da armadura. A arma entra por `HeroBase.wield`.

const COAT := Color("6E2470")
const PALE := Color("D5D9E4")
const HAIR := Color("CBD2E2")
const LEGS := Color("1B1830")
const BOOTS := Color("2A2038")
const SKIN := Color("D9A981")
const CLASS_BLUE := Color("4F8DFF")
## Variante 1 (Manto do Novato): `armor_variant` do `HeroLook`.
const CLOAK_VARIANT := 1
const CLOAK_LOW_Y := 0.16

const TORSO: Array[Vector4] = [
	Vector4(0.0, -0.08, 0.16, 0.115), Vector4(0.0, 0.14, 0.145, 0.105), Vector4(0.0, 0.34, 0.195, 0.12),
	Vector4(0.0, 0.5, 0.205, 0.115), Vector4(0.0, 0.56, 0.09, 0.08),
]
const CAPE: Array[Vector4] = [
	Vector4(0.0, 0.28, 0.255, 0.165), Vector4(0.0, 0.36, 0.25, 0.16),
	Vector4(0.0, 0.5, 0.2, 0.135), Vector4(0.0, 0.585, 0.085, 0.08),
]
const BELT := [Vector2(0.165, 0.0), Vector2(0.175, 0.08), Vector2(0.165, 0.1)]
const WING_OUTER := [Vector2(0.03, 0.0), Vector2(0.19, 0.0), Vector2(0.27, 0.2), Vector2(0.3, 0.44), Vector2(0.12, 0.3), Vector2(0.03, 0.12)]
const WING_INNER := [Vector2(0.05, 0.03), Vector2(0.17, 0.03), Vector2(0.245, 0.2), Vector2(0.27, 0.37), Vector2(0.125, 0.26), Vector2(0.05, 0.13)]
const COLLAR_ORIGIN := Vector3(0.0, 0.55, 0.1)
const COLLAR_INNER_ORIGIN := Vector3(0.0, 0.55, 0.09)
const COLLAR_TILT := Vector3(0.28, 0.0, 0.0)
const SEAL_FRONT := Vector3(0.0, 0.41, -0.165)
const SEAL_BACK := Vector3(0.0, 0.43, 0.16)
const SKIRT_ORIGIN := Vector3(0.0, 0.04, 0.12)
const CAP: Array[Vector4] = [Vector4(0.0, 0.185, 0.106, 0.122), Vector4(0.0, 0.235, 0.09, 0.106), Vector4(0.0, 0.28, 0.03, 0.04)]
const NAPE: Array[Vector4] = [Vector4(0.0, 0.03, 0.075, 0.07), Vector4(0.0, 0.12, 0.105, 0.09), Vector4(0.0, 0.2, 0.1, 0.09)]
const BUN_POS := Vector3(0.0, 0.3, 0.05)

## Tiers (OS-014). Peças cumulativas: `armor_tier` manda no corpo e nos focos, `head_tier` na gola.
const FUR := Color("EEF1F6")
const FUR_HEM: Array[Vector4] = [Vector4(0.0, 0.255, 0.285, 0.19), Vector4(0.0, 0.325, 0.268, 0.178)]
const COLLAR_TALL_TIER := 2
const COLLAR_TALL_SCALE := 1.22
const COLLAR_PLATE_COUNT := 4
const FRONT_PANEL_LENGTH := 0.86
const LONG_COAT_TIER := 3
const LONG_PANEL_LENGTH := 0.94
const FOCUS_RING_INNER := 0.06
const FOCUS_RING_OUTER := 0.09
const FOCUS_RING_SCALE := Vector3(1.0, 0.6, 1.0)
const FOCUS_CORE_RADIUS := 0.05
const FOCUS_CORE_SCALE := Vector3(1.0, 1.0, 0.45)
const FOCUS_FLOAT_AMPLITUDE := 0.03
const FOCUS_FLOAT_FREQUENCY := 0.5
## Posição no `chest`, o tier em que entra e a fase da oscilação do lado direito; o esquerdo espelha x e soma PI.
const FOCI: Array[Dictionary] = [
	{"tier": 2, "position": Vector3(0.66, 0.42, 0.1), "phase": 0.0},
	{"tier": 3, "position": Vector3(0.66, 0.74, 0.14), "phase": PI * 0.5},
]


## Esqueleto, passada, corpo, cabeça e Selo. A pose de repouso dos braços vem de `HeroBase.wield`.
static func assemble(rig: CreatureRig, look: HeroLook) -> void:
	CreatureRig.biped_skeleton(rig, 1.02, 0.98, 0.86)
	rig.arm_swing_r = 0.2
	rig.arm_swing_l = 0.6
	rig.stride = 0.55
	rig.knee_bend = 0.6
	var coat: Material = Look.hero(COAT, 0.8)
	var pale: Material = Look.hero(PALE, 0.75)
	var trim: Material = Look.trim(look.armor_tier)
	_torso(rig, look, coat, pale, trim)
	_skirt(rig, look)
	_seals(rig, trim)
	_collar(rig, look)
	_foci(rig, look, trim)
	_limbs(rig, coat, pale, Look.hero(LEGS, 0.8))
	HeroBase.boots(rig, Look.hero(BOOTS, 0.6))
	_head(rig, trim)


static func _torso(rig: CreatureRig, look: HeroLook, coat: Material, pale: Material, trim: Material) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	var cape: Array[Vector4] = CAPE.duplicate()
	if look.armor_tier == 0 and look.armor_variant == CLOAK_VARIANT:
		cape[0] = Vector4(cape[0].x, CLOAK_LOW_Y, cape[0].z, cape[0].w)
	rig.part(chest, MeshKit.loft(TORSO, 12), coat)
	rig.part(chest, MeshKit.loft(cape, 12), pale)
	rig.part(pelvis, MeshKit.lathe(PackedVector2Array(BELT), 12, false), trim, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.72))
	if look.armor_tier >= 1:
		_tier_piece(rig.part(chest, MeshKit.loft(FUR_HEM, 12), Look.hero(FUR, 0.9)), "t1_barra", 1)


## Nome único no rig e marca de tier: o `report.json` lista só o nome da peça.
static func _tier_piece(instance: MeshInstance3D, piece_name: String, tier: int) -> MeshInstance3D:
	instance.name = piece_name
	instance.set_meta(&"tier", tier)
	return instance


## Casaco aberto: aba no joint `cloth_back` (J4), dois painéis à frente e o forro azul na abertura.
static func _skirt(rig: CreatureRig, look: HeroLook) -> void:
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	var cloth_back: Node3D = rig.joint(&"cloth_back", pelvis, SKIRT_ORIGIN)
	var coat_cloth: Material = Look.two_sided(COAT, 0.8)
	var lining: Material = Look.two_sided(CLASS_BLUE, 0.5)
	var panel_length: float = LONG_PANEL_LENGTH if look.armor_tier >= LONG_COAT_TIER else FRONT_PANEL_LENGTH
	rig.part(cloth_back, MeshKit.cloth(0.34, 0.66, 1.0, 0.2, 6, 7), coat_cloth)
	for side: float in [-1.0, 1.0]:
		rig.part(pelvis, MeshKit.cloth(0.15, 0.2, panel_length, 0.04, 3, 5), coat_cloth, Vector3(side * 0.14, 0.04, -0.11), Vector3(0.0, PI + side * 0.28, 0.0))
		rig.part(pelvis, MeshKit.cloth(0.02, 0.022, 0.84, 0.04, 1, 5), lining, Vector3(side * 0.05, 0.04, -0.125), Vector3(0.0, PI, 0.0))


static func _seals(rig: CreatureRig, trim: Material) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	HeroBase.seal(rig, chest, SEAL_FRONT, CLASS_BLUE, trim, 1.0)
	HeroBase.seal(rig, chest, SEAL_BACK, CLASS_BLUE, trim, 1.0)


## Gola em duas asas no `chest` (J3). Prata por fora (z .1) e azul por dentro (z .09): a azul fica à frente.
## Com `head_tier` 2 ou mais a gola cresce em y e as 4 placas entram em P8 e P9 como peças do tier 2.
static func _collar(rig: CreatureRig, look: HeroLook) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var outer: Material = Look.hero(PALE, 0.5)
	var inner: Material = Look.two_sided(CLASS_BLUE, 0.5)
	var tall: bool = look.head_tier >= COLLAR_TALL_TIER
	var stretch := Vector3(1.0, COLLAR_TALL_SCALE if tall else 1.0, 1.0)
	var plates: Array[MeshInstance3D] = []
	for wing: PackedVector2Array in [PackedVector2Array(WING_OUTER), _mirror(WING_OUTER)]:
		var plate: MeshInstance3D = rig.part(chest, MeshKit.plate(wing, 0.03), outer, COLLAR_ORIGIN, COLLAR_TILT, stretch)
		plate.set_meta(&"measure", true)
		plates.append(plate)
	for wing: PackedVector2Array in [PackedVector2Array(WING_INNER), _mirror(WING_INNER)]:
		plates.append(rig.part(chest, MeshKit.plate(wing, 0.04), inner, COLLAR_INNER_ORIGIN, COLLAR_TILT, stretch))
	if tall:
		for index in COLLAR_PLATE_COUNT:
			_tier_piece(plates[index], "t2_gola_placa_%d" % index, COLLAR_TALL_TIER)


## Focos flutuantes no `chest`: anel de metal do tier e núcleo no material do núcleo do cajado (cache de `Look.glow`).
## Cada foco oscila em y por `CreatureRig.add_float`, sem `_process` próprio.
static func _foci(rig: CreatureRig, look: HeroLook, trim: Material) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var core: Material = Look.glow(WeaponKit.FOCUS_CORE, WeaponKit.GLOW_ENERGY)
	for spec in FOCI:
		var tier: int = spec["tier"]
		if look.armor_tier < tier:
			continue
		for side: StringName in [&"r", &"l"]:
			var mirror: float = 1.0 if side == &"r" else -1.0
			var origin: Vector3 = spec["position"]
			var focus := Node3D.new()
			focus.name = "t%d_foco_%s" % [tier, side]
			focus.position = Vector3(origin.x * mirror, origin.y, origin.z)
			chest.add_child(focus)
			var ring: MeshInstance3D = rig.part(focus, MeshKit.torus(FOCUS_RING_INNER, FOCUS_RING_OUTER, 12), trim, Vector3.ZERO, Vector3(PI * 0.5, 0.0, 0.0), FOCUS_RING_SCALE)
			_tier_piece(ring, "t%d_foco_%s_anel" % [tier, side], tier)
			var nucleus: MeshInstance3D = rig.part(focus, MeshKit.sphere(FOCUS_CORE_RADIUS, 10), core, Vector3.ZERO, Vector3.ZERO, FOCUS_CORE_SCALE)
			_tier_piece(nucleus, "t%d_foco_%s_nucleo" % [tier, side], tier)
			var phase: float = spec["phase"] + (0.0 if side == &"r" else PI)
			rig.add_float(focus, FOCUS_FLOAT_AMPLITUDE, FOCUS_FLOAT_FREQUENCY, phase)


## Espelho em x com a ordem dos pontos invertida, para manter o sentido do contorno.
static func _mirror(outline: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(outline.size() - 1, -1, -1):
		var point: Vector2 = outline[index]
		result.append(Vector2(-point.x, point.y))
	return result


static func _limbs(rig: CreatureRig, coat: Material, pale: Material, legs: Material) -> void:
	var skin: Material = Look.hero(SKIN, 0.7)
	for side: StringName in [&"r", &"l"]:
		var shoulder := StringName("shoulder_%s" % side)
		var elbow_name := StringName("elbow_%s" % side)
		var elbow: Node3D = rig.get_joint(elbow_name)
		var knee := StringName("knee_%s" % side)
		CreatureRig.limb(rig, shoulder, 0.3, 0.065, 0.058, coat)
		rig.part(elbow, MeshKit.sphere(0.06, 8), coat)
		rig.part(elbow, MeshKit.cylinder(0.095, 0.06, 0.28, 10), coat, Vector3(0.0, -0.15, 0.0))
		rig.part(elbow, MeshKit.cylinder(0.1, 0.098, 0.03, 10), pale, Vector3(0.0, -0.285, 0.0))
		HeroBase.hand(rig, StringName("hand_%s" % side), skin)
		CreatureRig.limb(rig, StringName("hip_%s" % side), 0.46, 0.085, 0.062, legs)
		rig.part(rig.get_joint(knee), MeshKit.sphere(0.065, 8), legs)
		CreatureRig.limb(rig, knee, 0.46, 0.066, 0.052, legs)


## Rosto à mostra (R2): cabelo em duas peças, casquete acima da sobrancelha e nuca deslocada para trás.
static func _head(rig: CreatureRig, trim: Material) -> void:
	var head: Node3D = HeroBase.head(rig, Look.hero(SKIN, 0.7))
	var hair: Material = Look.two_sided(HAIR, 0.55)
	rig.part(head, MeshKit.loft(CAP, 10), hair, Vector3(0.0, 0.0, 0.008))
	rig.part(head, MeshKit.loft(NAPE, 10), hair, Vector3(0.0, 0.0, 0.045))
	rig.part(head, MeshKit.sphere(0.058, 8), hair, BUN_POS)
	rig.part(head, MeshKit.cylinder(0.008, 0.008, 0.2, 6), trim, BUN_POS, Vector3(0.0, 0.0, PI / 2.3))
	rig.part(head, MeshKit.cloth(0.1, 0.04, 0.62, 0.03, 2, 4), hair, Vector3(0.0, 0.22, 0.125))
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.cloth(0.05, 0.02, 0.22, 0.0, 1, 3), hair, Vector3(side * 0.108, 0.2, -0.03), Vector3(0.0, PI * 0.5, 0.0))
