class_name HeroBase
extends RefCounted
## Base comum do caçador (seção 10 do guia de estilo): cabeça, mão, bota e Selo.
## O esqueleto vem de `CreatureRig.biped_skeleton`, para que monstro nenhum dependa de herói (S4).

const EYE_COLOR := Color("1A1410")
const BROW_COLOR := Color("2A1E18")
const MOUTH_COLOR := Color("7A4E3A")
const HEAD_RINGS: Array[Vector4] = [
	Vector4(0.0, 0.0, 0.04, 0.05), Vector4(0.0, 0.05, 0.075, 0.088), Vector4(0.0, 0.12, 0.095, 0.106),
	Vector4(0.0, 0.175, 0.098, 0.11), Vector4(0.0, 0.225, 0.072, 0.085), Vector4(0.0, 0.25, 0.02, 0.03),
]
const NOSE_RINGS: Array[Vector4] = [Vector4(0.0, 0.0, 0.018, 0.02), Vector4(0.0, 0.05, 0.008, 0.008)]
const HAND_RINGS: Array[Vector4] = [
	Vector4(0.0, -0.095, 0.03, 0.035), Vector4(0.0, -0.05, 0.045, 0.052),
	Vector4(0.0, -0.005, 0.042, 0.048), Vector4(0.0, 0.02, 0.032, 0.038),
]
const SEAL_RING_ROTATION := Vector3(PI * 0.5, 0.0, 0.0)
## Empunhadura por modelo de arma (fichas de classe, "Armas e empunhadura"). `rest` é a pose de repouso
## dos braços com essa arma e soma com o `_pose_biped`. `xyz` troca a ordem de Euler (J7).
const GRIPS: Dictionary = {
	&"sword_shield": {
		&"hand_r": {"position": Vector3(0.0, -0.06, -0.02), "rotation": Vector3(-2.45, 0.0, 0.0)},
		&"hand_l": {"position": Vector3(-0.104, -0.007, -0.003), "rotation": Vector3(-1.5, 0.75, 0.0), "xyz": true},
		&"strike_wrist": Vector3.ZERO,
		&"rest": {&"shoulder_r": Vector3(0.0, 0.0, 0.14), &"shoulder_l": Vector3(0.25, 0.0, -0.18), &"elbow_l": Vector3(1.0, 0.25, 0.0)},
	},
	&"greataxe": {
		&"hand_r": {"position": Vector3(0.0, -0.03, 0.0), "rotation": Vector3(-1.215, 0.0, 0.0)},
		&"strike_wrist": Vector3(-1.235, 0.0, 0.0),
		&"rest": {&"shoulder_r": Vector3(0.6, 0.0, 0.2), &"elbow_r": Vector3(1.35, 0.0, 0.0), &"shoulder_l": Vector3(0.05, 0.0, -0.12), &"elbow_l": Vector3.ZERO},
	},
	&"staff": {
		&"hand_r": {"position": Vector3(0.0, -0.02, 0.0), "rotation": Vector3(-0.97, 0.0, -0.47)},
		&"strike_wrist": Vector3(-0.8, 0.0, 0.5),
		&"rest": {&"shoulder_r": Vector3(0.32, 0.0, 0.4), &"elbow_r": Vector3(0.4, 0.0, 0.0)},
	},
	&"orb": {
		&"hand_r": {"position": Vector3(0.0, -0.2, -0.02), "rotation": Vector3.ZERO},
		&"strike_wrist": Vector3.ZERO,
		&"rest": {&"shoulder_r": Vector3(0.35, 0.0, 0.1), &"elbow_r": Vector3(1.2, 0.0, 0.0)},
	},
	&"scepter": {
		&"hand_r": {"position": Vector3(0.0, 0.06, 0.0), "rotation": Vector3(-0.95, 0.0, -0.42)},
		&"strike_wrist": Vector3(-0.8, 0.0, 0.5),
		&"rest": {&"shoulder_r": Vector3(0.2, 0.0, 0.32), &"elbow_r": Vector3(0.5, 0.0, 0.0), &"shoulder_l": Vector3(0.1, 0.0, -0.08), &"elbow_l": Vector3(0.2, 0.0, 0.0)},
	},
	&"tome": {
		&"hand_r": {"position": Vector3(0.0, -0.2, -0.02), "rotation": Vector3.ZERO},
		&"hand_l": {"position": Vector3(0.02, -0.12, -0.03), "rotation": Vector3(-1.55, 0.0, 0.0), "xyz": true},
		&"strike_wrist": Vector3.ZERO,
		&"rest": {&"shoulder_l": Vector3(0.45, 0.0, -0.1), &"elbow_l": Vector3(1.35, 0.0, 0.0), &"shoulder_r": Vector3(0.3, 0.0, 0.14), &"elbow_r": Vector3(1.0, 0.0, 0.0)},
	},
}
## Modelo que `WeaponKit` monta quando o id não existe.
const FALLBACK_MODEL := &"sword_shield"


## Pescoço, cabeça e rosto no joint `head`. Olho e sobrancelha são peças de sombra: `Look.matte`, sem luz de personagem (B1, M4).
static func head(rig: CreatureRig, skin: Material) -> Node3D:
	var joint: Node3D = rig.get_joint(&"head")
	rig.part(joint, MeshKit.cylinder(0.055, 0.065, 0.1, 8), skin, Vector3(0.0, -0.02, 0.0))
	rig.part(joint, MeshKit.loft(HEAD_RINGS, 10), skin, Vector3(0.0, 0.02, 0.0))
	rig.part(joint, MeshKit.loft(NOSE_RINGS, 4, false), skin, Vector3(0.0, 0.085, -0.108))
	rig.part(joint, MeshKit.box(Vector3(0.04, 0.008, 0.008)), Look.hero(MOUTH_COLOR, 0.7), Vector3(0.0, 0.055, -0.092))
	var eye: Material = Look.matte(EYE_COLOR, 0.9)
	var brow: Material = Look.matte(BROW_COLOR, 0.8)
	for side: float in [-1.0, 1.0]:
		rig.part(joint, MeshKit.box(Vector3(0.036, 0.018, 0.012)), eye, Vector3(side * 0.044, 0.132, -0.1))
		rig.part(joint, MeshKit.box(Vector3(0.05, 0.008, 0.02)), brow, Vector3(side * 0.045, 0.158, -0.098), Vector3(0.0, 0.0, -side * 0.06))
	return joint


## Mão arredondada no joint `hand_r` ou `hand_l`.
static func hand(rig: CreatureRig, joint_name: StringName, material: Material) -> void:
	rig.part(rig.get_joint(joint_name), MeshKit.loft(HAND_RINGS, 10), material)


## Bota nos dois joints `knee_*`: pé e cano.
static func boots(rig: CreatureRig, material: Material) -> void:
	for side: StringName in [&"r", &"l"]:
		var knee: Node3D = rig.get_joint(StringName("knee_%s" % side))
		rig.part(knee, MeshKit.box(Vector3(0.11, 0.07, 0.25)), material, Vector3(0.0, -0.46, -0.05))
		rig.part(knee, MeshKit.cylinder(0.078, 0.062, 0.16, 8), material, Vector3(0.0, -0.36, 0.0))


## Selo: aro de metal do tier e disco de luz na cor da classe (B3, B4). `position` é local a `parent`.
static func seal(rig: CreatureRig, parent: Node3D, position: Vector3, color: Color, trim: Material, energy: float = 1.0) -> void:
	rig.part(parent, MeshKit.torus(0.055, 0.08, 16), trim, position, SEAL_RING_ROTATION, Vector3(1.0, 0.6, 1.0))
	var disc: MeshInstance3D = rig.part(parent, MeshKit.sphere(0.055, 10), Look.glow(color, energy), position, Vector3.ZERO, Vector3(1.0, 1.0, 0.35))
	disc.set_meta(&"seal", &"front" if position.z < 0.0 else &"back")


## Arma nas mãos e pose de repouso dos braços para o modelo de `look`.
static func wield(rig: CreatureRig, look: HeroLook) -> void:
	var model: StringName = look.weapon_model if GRIPS.has(look.weapon_model) else FALLBACK_MODEL
	var grips: Dictionary = GRIPS[model]
	var rest: Dictionary = grips[&"rest"]
	for joint_name: StringName in rest:
		var joint: Node3D = rig.get_joint(joint_name)
		if joint == null:
			push_warning("Joint %s ausente: pose de repouso ignorada" % joint_name)
			continue
		rig.set_rest(joint_name, rest[joint_name])
		joint.rotation = rest[joint_name]
	rig.set_strike_grip(grips[&"strike_wrist"])
	_hold(rig, WeaponKit.build_main_hand(look.weapon_model, look.weapon_rarity, look.weapon_tier), &"hand_r", grips)
	_hold(rig, WeaponKit.build_off_hand(look.weapon_model, look.weapon_rarity, look.weapon_tier), &"hand_l", grips)


static func _hold(rig: CreatureRig, weapon: Node3D, hand: StringName, grips: Dictionary) -> void:
	if weapon == null:
		return
	var joint: Node3D = rig.get_joint(hand)
	if joint == null or not grips.has(hand):
		push_warning("Sem empunhadura para %s" % hand)
		weapon.free()
		return
	var grip: Dictionary = grips[hand]
	joint.add_child(weapon)
	if grip.get("xyz", false):
		weapon.rotation_order = EULER_ORDER_XYZ
	weapon.position = grip["position"]
	weapon.rotation = grip["rotation"]
	rig.adopt_meshes(weapon)
