class_name FrostKingModel
extends RefCounted
## Modelo do Rei Gélido (OS-021). Unidades em metros do rig, antes da escala do MonsterData.
## Frente em -Z, mão direita em +X, espada na mão direita. Acabamento limpo: `Look.matte` sem textura.
## Os nomes dos nós e as âncoras (`weapon_tip`, `core`, `crown`, `cloth_back`) são contrato com os testes e com a OS-022.

const PLATE_LIGHT := Color("B4C3D6")
const PLATE_DARK := Color("2B3548")
const GOLD := Color("D8B464")
const BONE := Color("D9E6F2")
const CAPE := Color("4468A8")
const VISOR := Color("06070B")
const ICE_CORE := Color(0.14, 0.42, 0.72)
const ICE_RIM := Color(0.65, 0.92, 1.0)

const HEIGHT := 1.0
const ARM_SCALE := 1.1
const WIDTH := 1.1
const STRIDE := 0.5
const STEP_RATE := 1.5
const ARM_SWING_R := 0.2
const ARM_SWING_L := 0.5
## Golpe curto e volta lenta dão peso; o golpe começa depois do dano, então não pode passar de 0,18 s.
const STRIKE_TIME := 0.18
const RECOVER_TIME := 0.5
const EYE_ENERGY := 7.0
const SEED := 31

const CUIRASS: Array[Vector4] = [
	Vector4(0.0, -0.12, 0.20, 0.15), Vector4(0.0, 0.08, 0.22, 0.17), Vector4(0.0, 0.30, 0.29, 0.20),
	Vector4(0.0, 0.46, 0.31, 0.19), Vector4(0.0, 0.56, 0.15, 0.12),
]
const GORGET: Array[Vector2] = [Vector2(0.17, 0.50), Vector2(0.19, 0.55), Vector2(0.16, 0.62), Vector2(0.15, 0.66)]
const FAULDS: Array[Vector2] = [Vector2(0.30, -0.26), Vector2(0.27, -0.14), Vector2(0.23, 0.0), Vector2(0.21, 0.06)]
const BELT: Array[Vector2] = [Vector2(0.225, -0.01), Vector2(0.235, 0.05), Vector2(0.22, 0.09)]
const CORE: Array[Vector2] = [Vector2(0.0, -0.16), Vector2(0.08, -0.02), Vector2(0.0, 0.17)]
const HELM: Array[Vector4] = [
	Vector4(0.0, -0.02, 0.15, 0.17), Vector4(0.0, 0.07, 0.19, 0.21), Vector4(0.0, 0.17, 0.20, 0.22),
	Vector4(0.0, 0.25, 0.15, 0.17), Vector4(0.0, 0.30, 0.06, 0.07),
]
const CROWN_BAND: Array[Vector4] = [
	Vector4(0.0, 0.18, 0.215, 0.235), Vector4(0.0, 0.20, 0.205, 0.225), Vector4(0.0, 0.26, 0.17, 0.19), Vector4(0.0, 0.285, 0.16, 0.18),
]
const CROWN_HEIGHTS: Array[float] = [0.34, 0.27, 0.20, 0.20, 0.27]
const PAULDRON: Array[Vector2] = [Vector2(0.0, -0.06), Vector2(0.23, -0.05), Vector2(0.27, 0.03), Vector2(0.19, 0.12), Vector2(0.09, 0.19), Vector2(0.0, 0.21)]
const PAULDRON_LOW: Array[Vector2] = [Vector2(0.0, -0.2), Vector2(0.21, -0.19), Vector2(0.26, -0.11), Vector2(0.24, -0.05)]
const PAULDRON_RIM: Array[Vector2] = [Vector2(0.25, -0.2), Vector2(0.27, -0.16), Vector2(0.26, -0.12)]
const CUISSE: Array[Vector4] = [Vector4(0.0, -0.50, 0.10, 0.11), Vector4(0.0, -0.25, 0.115, 0.13), Vector4(0.0, 0.0, 0.125, 0.15)]
const GREAVE: Array[Vector4] = [Vector4(0.0, -0.44, 0.075, 0.10), Vector4(0.0, -0.30, 0.095, 0.12), Vector4(0.0, -0.10, 0.105, 0.125), Vector4(0.0, 0.02, 0.10, 0.12)]
const SABATON: Array[Vector2] = [Vector2(-0.14, -0.47), Vector2(0.10, -0.47), Vector2(0.34, -0.395), Vector2(0.26, -0.355), Vector2(0.08, -0.34), Vector2(-0.12, -0.34), Vector2(-0.16, -0.41)]
const GUARD: Array[Vector2] = [Vector2(-0.36, 0.17), Vector2(-0.30, 0.255), Vector2(-0.08, 0.285), Vector2(0.08, 0.285), Vector2(0.30, 0.255), Vector2(0.36, 0.17), Vector2(0.12, 0.225), Vector2(-0.12, 0.225)]
const BLADE_LENGTH := 1.26
const BLADE_BASE := 0.27
## Abaixa a ponta em repouso: -19° em vez dos +15° do modelo antigo.
const SWORD_PITCH := 0.6


static func assemble(rig: CreatureRig, glow: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	CreatureRig.biped_skeleton(rig, HEIGHT, ARM_SCALE, WIDTH)
	rig.stride = STRIDE
	rig.step_rate = STEP_RATE
	rig.arm_swing_r = ARM_SWING_R
	rig.arm_swing_l = ARM_SWING_L
	rig.strike_time = STRIKE_TIME
	rig.recover_time = RECOVER_TIME
	var light: Material = Look.matte(PLATE_LIGHT, 0.42, 0.35)
	var dark: Material = Look.matte(PLATE_DARK, 0.5, 0.3)
	var gold: Material = Look.matte(GOLD, 0.4, 0.45)
	var bone: Material = Look.matte(BONE, 0.6, 0.0)
	var ice: Material = DungeonMaterials.crystal(ICE_CORE, ICE_RIM, 2.0)
	_torso(rig, light, dark, gold, ice, rng)
	_head(rig, light, gold, bone, glow, rng)
	_arms(rig, light, dark, ice, rng)
	_legs(rig, light, dark, rng)
	_cape(rig)
	_sword(rig, dark, gold)


## Peça nomeada: o nome é o que os testes e a revisão procuram.
static func _named(rig: CreatureRig, part_name: String, parent: Node3D, mesh: Mesh, material: Material, offset := Vector3.ZERO, rotation_offset := Vector3.ZERO, scale_factor := Vector3.ONE) -> MeshInstance3D:
	var instance: MeshInstance3D = rig.part(parent, mesh, material, offset, rotation_offset, scale_factor)
	instance.name = part_name
	return instance


static func _profile(points: Array[Vector2]) -> PackedVector2Array:
	return PackedVector2Array(points)


static func _torso(rig: CreatureRig, light: Material, dark: Material, gold: Material, ice: Material, rng: RandomNumberGenerator) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var pelvis: Node3D = rig.get_joint(&"pelvis")
	_named(rig, "couraca", chest, MeshKit.loft(CUIRASS, 10, false), light)
	_named(rig, "gorjal", chest, MeshKit.lathe(_profile(GORGET), 10, false, false), gold, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.9))
	_named(rig, "saia", pelvis, MeshKit.lathe(_profile(FAULDS), 10, false, false), dark, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.78))
	_named(rig, "cinto", pelvis, MeshKit.lathe(_profile(BELT), 12, false), gold, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.78))
	rig.part(pelvis, MeshKit.shard(0.05, 0.16, rng, 4, 0.0), gold, Vector3(0.0, 0.0, -0.19), Vector3(PI, 0.0, 0.0))
	var core_material: Material = DungeonMaterials.crystal(Color(0.2, 0.55, 0.9), Color(0.7, 0.95, 1.0), 2.4).duplicate()
	_named(rig, "nucleo", chest, MeshKit.lathe(_profile(CORE), 6, false), core_material, Vector3(0.0, 0.28, -0.205), Vector3.ZERO, Vector3(1.0, 1.0, 0.7))
	rig.set_meta(&"core_material", core_material)
	rig.joint(&"core", chest, Vector3(0.0, 0.28, -0.23))
	for side: float in [-1.0, 1.0]:
		var tag: String = "r" if side > 0.0 else "l"
		var origin := Vector3(side * 0.30, 0.46, 0.0)
		var stretch := Vector3(1.0, 1.0, 1.1)
		_named(rig, "ombreira_alta_%s" % tag, chest, MeshKit.lathe(_profile(PAULDRON), 6, false), light, origin, Vector3.ZERO, stretch)
		_named(rig, "ombreira_baixa_%s" % tag, chest, MeshKit.lathe(_profile(PAULDRON_LOW), 6, false), dark, origin, Vector3.ZERO, stretch)
		_named(rig, "ombreira_borda_%s" % tag, chest, MeshKit.lathe(_profile(PAULDRON_RIM), 6, false, false), gold, origin, Vector3.ZERO, stretch)
		rig.part(chest, MeshKit.shard(0.065, 0.40, rng, 5, 0.0), ice, origin + Vector3(side * 0.03, 0.17, 0.0), Vector3(0.0, 0.0, side * -0.35))
		rig.part(chest, MeshKit.shard(0.05, 0.28, rng, 5, 0.0), ice, origin + Vector3(side * 0.11, 0.12, 0.0), Vector3(0.0, 0.0, side * -0.5))
	for i in 3:
		var x: float = (i - 1) * 0.12
		rig.part(chest, MeshKit.shard(0.055, 0.40 - absf(x), rng, 4, 0.0), ice, Vector3(x, 0.40, 0.2), Vector3(0.18, 0.0, -x * 1.2))


static func _head(rig: CreatureRig, light: Material, gold: Material, bone: Material, glow: Color, rng: RandomNumberGenerator) -> void:
	var head: Node3D = rig.get_joint(&"head")
	_named(rig, "elmo", head, MeshKit.loft(HELM, 10, false), light)
	_named(rig, "coroa_aro", head, MeshKit.loft(CROWN_BAND, 10, false), gold)
	_named(rig, "visor", head, MeshKit.box(Vector3(0.30, 0.03, 0.05)), Look.matte(VISOR, 0.4), Vector3(0.0, 0.13, -0.205))
	# O plano fino e pontudo lê como fenda fria: a ponta de dentro é a mais baixa.
	var eye_material: Material = Look.glow(glow, EYE_ENERGY)
	for side: float in [-1.0, 1.0]:
		var eye_outline := PackedVector2Array([Vector2(-0.065 * side, -0.012), Vector2(0.0, 0.012), Vector2(0.07 * side, 0.02), Vector2(0.0, -0.004)])
		if side < 0.0:
			eye_outline.reverse()
		_named(rig, "olho_%s" % ("r" if side > 0.0 else "l"), head, MeshKit.plate(eye_outline, 0.012), eye_material, Vector3(side * 0.085, 0.13, -0.236))
	var crown_material: Material = DungeonMaterials.crystal(ICE_CORE, ICE_RIM, 2.0).duplicate()
	rig.set_meta(&"crown_material", crown_material)
	rig.joint(&"crown", head, Vector3(0.0, 0.30, 0.0))
	for i in CROWN_HEIGHTS.size():
		var angle: float = TAU * float(i) / float(CROWN_HEIGHTS.size())
		var outward := Vector2(sin(angle), -cos(angle))
		rig.part(head, MeshKit.shard(0.05, CROWN_HEIGHTS[i], rng, 5, 0.0), crown_material, Vector3(outward.x * 0.14, 0.275, outward.y * 0.14), Vector3(outward.y * 0.1, 0.0, -outward.x * 0.1))
	for side: float in [-1.0, 1.0]:
		var tag: String = "r" if side > 0.0 else "l"
		_named(rig, "chifre_%s" % tag, head, MeshKit.shard(0.06, 0.2, rng, 5, 0.0), bone, Vector3(side * 0.17, 0.15, 0.0), Vector3(0.0, 0.0, side * -1.0))
		_named(rig, "chifre_ponta_%s" % tag, head, MeshKit.shard(0.045, 0.27, rng, 5, 0.0), bone, Vector3(side * 0.31, 0.24, 0.0), Vector3(0.0, 0.0, side * -0.3))


static func _arms(rig: CreatureRig, light: Material, dark: Material, ice: Material, rng: RandomNumberGenerator) -> void:
	for side: StringName in [&"r", &"l"]:
		var shoulder: Node3D = rig.get_joint(StringName("shoulder_%s" % side))
		var elbow: Node3D = rig.get_joint(StringName("elbow_%s" % side))
		var hand: Node3D = rig.get_joint(StringName("hand_%s" % side))
		_named(rig, "junta_ombro", shoulder, MeshKit.sphere(0.12, 8), dark)
		CreatureRig.limb(rig, StringName("shoulder_%s" % side), 0.39, 0.095, 0.085, dark)
		_named(rig, "junta_cotovelo", elbow, MeshKit.sphere(0.105, 8), dark)
		rig.part(elbow, MeshKit.shard(0.05, 0.12, rng, 4, 0.0), light, Vector3(0.0, 0.0, 0.07), Vector3(PI * 0.5, 0.0, 0.0))
		CreatureRig.limb(rig, StringName("elbow_%s" % side), 0.37, 0.09, 0.075, light)
		rig.part(hand, MeshKit.sphere(0.095, 8), dark)
		if side == &"l":
			for i in 3:
				rig.part(hand, MeshKit.shard(0.03, 0.2, rng, 4, 0.0), ice, Vector3((i - 1) * 0.06, -0.07, -0.08), Vector3(-1.9, 0.0, (i - 1) * 0.25))


static func _legs(rig: CreatureRig, light: Material, dark: Material, rng: RandomNumberGenerator) -> void:
	for side: StringName in [&"r", &"l"]:
		var hip: Node3D = rig.get_joint(StringName("hip_%s" % side))
		var knee: Node3D = rig.get_joint(StringName("knee_%s" % side))
		rig.part(hip, MeshKit.loft(CUISSE, 8, false), dark)
		_named(rig, "junta_joelho", knee, MeshKit.sphere(0.115, 8), dark)
		rig.part(knee, MeshKit.shard(0.06, 0.2, rng, 4, 0.0), light, Vector3(0.0, -0.03, -0.08), Vector3(-PI * 0.5 + 0.2, 0.0, 0.0))
		rig.part(knee, MeshKit.loft(GREAVE, 8, false), dark)
		# Rotação em +Y: a ponta do pé vai para -Z.
		rig.part(knee, MeshKit.plate(_profile(SABATON), 0.17), dark, Vector3.ZERO, Vector3(0.0, PI * 0.5, 0.0))


## A capa pende de `cloth_back`, que o `CreatureRig` abre com a velocidade: a perna nunca a atravessa.
static func _cape(rig: CreatureRig) -> void:
	var anchor: Node3D = rig.joint(&"cloth_back", rig.get_joint(&"chest"), Vector3(0.0, 0.54, 0.2))
	var material: StandardMaterial3D = Look.matte(CAPE, 0.9).duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cape: MeshInstance3D = _named(rig, "capa", anchor, MeshKit.cloth(0.6, 0.98, 1.38, 0.24), material)
	cape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _sword(rig: CreatureRig, dark: Material, gold: Material) -> void:
	var root := Node3D.new()
	root.name = "Sword"
	rig.get_joint(&"hand_r").add_child(root)
	root.rotation.x = -PI * 0.5 - SWORD_PITCH
	rig.part(root, MeshKit.cylinder(0.03, 0.034, 0.42, 8), dark, Vector3(0.0, 0.01, 0.0))
	rig.part(root, MeshKit.sphere(0.065, 6), gold, Vector3(0.0, -0.21, 0.0))
	_named(rig, "guarda", root, MeshKit.plate(_profile(GUARD), 0.09), gold)
	var blade_material: Material = DungeonMaterials.crystal(Color(0.18, 0.46, 0.76), Color(0.72, 0.94, 1.0), 1.5).duplicate()
	_named(rig, "lamina", root, MeshKit.blade(BLADE_LENGTH, 0.26, 0.07, 0.16), blade_material, Vector3(0.0, BLADE_BASE, 0.0))
	rig.set_meta(&"blade_material", blade_material)
	rig.joint(&"weapon_tip", root, Vector3(0.0, BLADE_BASE + BLADE_LENGTH, 0.0))
