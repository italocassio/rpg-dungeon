class_name CreatureFactory
extends RefCounted
## Monta o modelo de cada monstro/herói a partir de partes procedurais.


static func build(visual: StringName) -> CreatureRig:
	match visual:
		&"goblin":
			return _goblin()
		&"wolf":
			return _wolf()
		&"skeleton":
			return _skeleton()
		&"shaman":
			return _shaman()
		&"golem":
			return _golem()
		&"frost_king":
			return _frost_king()
	push_warning("Visual desconhecido: %s" % visual)
	return _goblin()


## Herói do grupo; cor da armadura e arma vêm da ficha.
static func build_hero(class_id: StringName, armor_tint: Color, weapon_model: StringName, weapon_rarity: ItemData.Rarity) -> CreatureRig:
	var rig := CreatureRig.new()
	var skin: Material = Look.matte(Color("d9a981"), 0.7)
	match class_id:
		&"warrior":
			var plate: Material = Look.metal(armor_tint, 0.42)
			var trim: Material = Look.metal(Color("b98f45"), 0.4)
			var dark: Material = Look.matte(Color("2a2d34"), 0.7)
			_biped_skeleton(rig, 1.0, 1.0, 1.0)
			_armored_body(rig, plate, trim, dark, 1.08)
			_knight_helm(rig, plate, trim, Color("e0603a"))
			_cape(rig, Look.matte(Color("7a1f1a"), 0.85), 0.62, 1.05)
		&"mage":
			var robe: Material = Look.matte(armor_tint, 0.8)
			var trim: Material = Look.metal(Color("b98f45"), 0.4)
			_biped_skeleton(rig, 0.98, 0.9, 0.95)
			_robed_body(rig, robe, trim, skin, armor_tint)
			_hood(rig, Look.matte(armor_tint.darkened(0.15), 0.8), Look.glow(Color("6cc2ff"), 1.8), true)
		_:
			var robe: Material = Look.matte(armor_tint, 0.8)
			var trim: Material = Look.metal(Color("c9a24f"), 0.35)
			_biped_skeleton(rig, 1.0, 0.92, 0.95)
			_robed_body(rig, robe, trim, skin, armor_tint)
			_mitre(rig, robe, trim, skin)
	_grip(rig, WeaponKit.build_main_hand(weapon_model, weapon_rarity), &"hand_r")
	var off_hand: Node3D = WeaponKit.build_off_hand(weapon_model)
	if off_hand != null:
		_grip(rig, off_hand, &"hand_l")
		off_hand.rotation = Vector3(0.0, PI * 0.5, 0.0)
	return rig


static func _grip(rig: CreatureRig, weapon: Node3D, hand: StringName) -> void:
	var joint: Node3D = rig.get_joint(hand)
	joint.add_child(weapon)
	weapon.rotation.x = -PI * 0.5
	rig.adopt_meshes(weapon)


## Esqueleto bípede padrão com 1.8 m * scale.
static func _biped_skeleton(rig: CreatureRig, height: float, arm_scale: float, width: float) -> void:
	var s: float = height
	rig.set_pelvis_height(0.95 * s)
	var pelvis: Node3D = rig.joint(&"pelvis", null, Vector3(0.0, 0.95 * s, 0.0))
	var chest: Node3D = rig.joint(&"chest", pelvis, Vector3(0.0, 0.12 * s, 0.0))
	rig.joint(&"head", chest, Vector3(0.0, 0.58 * s, 0.0))
	var shoulder_r: Node3D = rig.joint(&"shoulder_r", chest, Vector3(0.26 * s * width, 0.46 * s, 0.0))
	var shoulder_l: Node3D = rig.joint(&"shoulder_l", chest, Vector3(-0.26 * s * width, 0.46 * s, 0.0))
	var elbow_r: Node3D = rig.joint(&"elbow_r", shoulder_r, Vector3(0.0, -0.32 * s * arm_scale, 0.0))
	var elbow_l: Node3D = rig.joint(&"elbow_l", shoulder_l, Vector3(0.0, -0.32 * s * arm_scale, 0.0))
	rig.joint(&"hand_r", elbow_r, Vector3(0.0, -0.3 * s * arm_scale, 0.0))
	rig.joint(&"hand_l", elbow_l, Vector3(0.0, -0.3 * s * arm_scale, 0.0))
	var hip_r: Node3D = rig.joint(&"hip_r", pelvis, Vector3(0.11 * s, -0.02 * s, 0.0))
	var hip_l: Node3D = rig.joint(&"hip_l", pelvis, Vector3(-0.11 * s, -0.02 * s, 0.0))
	rig.joint(&"knee_r", hip_r, Vector3(0.0, -0.46 * s, 0.0))
	rig.joint(&"knee_l", hip_l, Vector3(0.0, -0.46 * s, 0.0))


static func _limb(rig: CreatureRig, parent: StringName, length: float, top: float, bottom: float, material: Material) -> void:
	rig.part(rig.get_joint(parent), MeshKit.cylinder(top, bottom, length, 8), material, Vector3(0.0, -length * 0.5, 0.0))


static func _armored_body(rig: CreatureRig, plate: Material, trim: Material, dark: Material, bulk: float) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var torso: Array[Vector4] = [
		Vector4(0.0, -0.1, 0.2 * bulk, 0.14 * bulk), Vector4(0.0, 0.1, 0.2 * bulk, 0.15 * bulk),
		Vector4(0.0, 0.32, 0.29 * bulk, 0.19 * bulk), Vector4(0.0, 0.5, 0.31 * bulk, 0.18 * bulk), Vector4(0.0, 0.57, 0.14, 0.11),
	]
	rig.part(chest, MeshKit.loft(torso, 10, false), plate)
	rig.part(chest, MeshKit.box(Vector3(0.1, 0.48, 0.05)), trim, Vector3(0.0, 0.24, -0.18 * bulk))
	var belt := MeshKit.lathe(PackedVector2Array([Vector2(0.21, 0.0), Vector2(0.22, 0.07), Vector2(0.21, 0.09)]), 12)
	rig.part(rig.get_joint(&"pelvis"), belt, trim, Vector3(0.0, 0.02, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.75))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.lathe(PackedVector2Array([Vector2(0.31, -0.28), Vector2(0.22, 0.04)]), 10, false), dark, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.75))
	for side: StringName in [&"r", &"l"]:
		var sign_x: float = 1.0 if side == &"r" else -1.0
		rig.part(rig.get_joint(StringName("shoulder_%s" % side)), MeshKit.sphere(0.16, 10), plate, Vector3(sign_x * 0.03, 0.02, 0.0), Vector3.ZERO, Vector3(1.15, 0.85, 1.05))
		_limb(rig, StringName("shoulder_%s" % side), 0.3, 0.075, 0.06, dark)
		_limb(rig, StringName("elbow_%s" % side), 0.3, 0.075, 0.06, plate)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.065, 8), plate)
		_limb(rig, StringName("hip_%s" % side), 0.46, 0.1, 0.075, dark)
		_limb(rig, StringName("knee_%s" % side), 0.46, 0.085, 0.07, plate)
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.box(Vector3(0.14, 0.09, 0.3)), plate, Vector3(0.0, -0.47, -0.06))


static func _knight_helm(rig: CreatureRig, plate: Material, trim: Material, plume: Color) -> void:
	var head: Node3D = rig.get_joint(&"head")
	var helm := MeshKit.lathe(PackedVector2Array([Vector2(0.15, 0.0), Vector2(0.16, 0.1), Vector2(0.15, 0.2), Vector2(0.09, 0.28), Vector2(0.0, 0.3)]), 10, false)
	rig.part(head, helm, plate)
	rig.part(head, MeshKit.box(Vector3(0.24, 0.03, 0.04)), Look.matte(Color("08090c"), 0.4), Vector3(0.0, 0.14, -0.15))
	rig.part(head, MeshKit.box(Vector3(0.025, 0.2, 0.05)), trim, Vector3(0.0, 0.1, -0.16))
	rig.part(head, MeshKit.loft([Vector4(0.0, 0.0, 0.012, 0.13), Vector4(0.0, 0.1, 0.02, 0.17), Vector4(0.0, 0.17, 0.005, 0.11)], 6), Look.matte(plume, 0.8), Vector3(0.0, 0.27, 0.06))


static func _cape(rig: CreatureRig, material: Material, width: float, length: float) -> void:
	var mesh: ArrayMesh = MeshKit.cloth(width * 0.62, width, length, 0.22)
	var cape: MeshInstance3D = rig.part(rig.get_joint(&"chest"), mesh, material, Vector3(0.0, 0.5, 0.17))
	var both := material as BaseMaterial3D
	if both != null:
		both.cull_mode = BaseMaterial3D.CULL_DISABLED
	cape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _robed_body(rig: CreatureRig, robe: Material, trim: Material, skin: Material, tint: Color) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var torso: Array[Vector4] = [Vector4(0.0, -0.08, 0.19, 0.14), Vector4(0.0, 0.2, 0.2, 0.14), Vector4(0.0, 0.46, 0.25, 0.15), Vector4(0.0, 0.56, 0.11, 0.1)]
	rig.part(chest, MeshKit.loft(torso, 10), robe)
	rig.part(chest, MeshKit.torus(0.07, 0.13, 12), trim, Vector3(0.0, 0.55, 0.0), Vector3.ZERO, Vector3(1.0, 0.7, 1.0))
	var skirt := MeshKit.lathe(PackedVector2Array([Vector2(0.37, -0.93), Vector2(0.33, -0.88), Vector2(0.2, -0.05), Vector2(0.17, 0.08)]), 14)
	rig.part(rig.get_joint(&"pelvis"), skirt, robe, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.lathe(PackedVector2Array([Vector2(0.385, -0.93), Vector2(0.37, -0.83), Vector2(0.34, -0.83)]), 14), trim, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.box(Vector3(0.12, 0.72, 0.02)), Look.matte(tint.lightened(0.28), 0.8), Vector3(0.0, -0.42, -0.25), Vector3(0.2, 0.0, 0.0))
	for side: StringName in [&"r", &"l"]:
		_limb(rig, StringName("shoulder_%s" % side), 0.3, 0.08, 0.09, robe)
		rig.part(rig.get_joint(StringName("elbow_%s" % side)), MeshKit.cylinder(0.14, 0.085, 0.29, 8), robe, Vector3(0.0, -0.15, 0.0))
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.05, 8), skin)
		_limb(rig, StringName("hip_%s" % side), 0.46, 0.05, 0.04, robe)
		_limb(rig, StringName("knee_%s" % side), 0.46, 0.04, 0.035, robe)


static func _hood(rig: CreatureRig, cloth: Material, eye: Material, pointed: bool) -> void:
	var head: Node3D = rig.get_joint(&"head")
	var tip: float = 0.46 if pointed else 0.32
	var mesh := MeshKit.lathe(PackedVector2Array([Vector2(0.2, -0.04), Vector2(0.17, 0.12), Vector2(0.13, 0.24), Vector2(0.03, tip)]), 10)
	rig.part(head, mesh, cloth)
	rig.part(head, MeshKit.sphere(0.13, 8), Look.matte(Color("06070b"), 0.9), Vector3(0.0, 0.11, -0.06))
	rig.part(head, MeshKit.sphere(0.025, 6), eye, Vector3(0.055, 0.13, -0.17))
	rig.part(head, MeshKit.sphere(0.025, 6), eye, Vector3(-0.055, 0.13, -0.17))


static func _mitre(rig: CreatureRig, robe: Material, trim: Material, skin: Material) -> void:
	var head: Node3D = rig.get_joint(&"head")
	rig.part(head, MeshKit.sphere(0.135, 10), skin, Vector3(0.0, 0.12, 0.0))
	rig.part(head, MeshKit.lathe(PackedVector2Array([Vector2(0.14, 0.18), Vector2(0.15, 0.28), Vector2(0.09, 0.44), Vector2(0.0, 0.52)]), 10, false), robe, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.7))
	rig.part(head, MeshKit.torus(0.13, 0.155, 12), trim, Vector3(0.0, 0.2, 0.0))
	rig.part(head, MeshKit.box(Vector3(0.03, 0.2, 0.01)), trim, Vector3(0.0, 0.34, -0.095))


static func _goblin() -> CreatureRig:
	var rig := CreatureRig.new()
	var skin: Material = Look.matte(Color("4f6f73"), 0.68)
	var dark: Material = Look.matte(Color("2b3a40"), 0.7)
	var cloth: Material = Look.matte(Color("5a4232"), 0.9)
	var eye: Material = Look.glow(Color("ffd24a"), 3.5)
	_biped_skeleton(rig, 0.8, 1.3, 1.05)
	rig.stride = 0.95
	rig.step_rate = 2.9
	rig.get_joint(&"chest").rotation.x = 0.0
	var hunch: Node3D = rig.get_joint(&"chest")
	var torso: Array[Vector4] = [Vector4(0.0, -0.08, 0.14, 0.12), Vector4(0.0, 0.14, 0.2, 0.17), Vector4(0.0, 0.34, 0.22, 0.17), Vector4(0.0, 0.46, 0.1, 0.1)]
	rig.part(hunch, MeshKit.loft(torso, 8), skin)
	rig.part(rig.get_joint(&"pelvis"), MeshKit.lathe(PackedVector2Array([Vector2(0.24, -0.2), Vector2(0.15, 0.06)]), 8, false), cloth)
	var head: Node3D = rig.get_joint(&"head")
	rig.part(head, MeshKit.sphere(0.2, 8), skin, Vector3(0.0, 0.08, -0.04), Vector3.ZERO, Vector3(1.1, 0.9, 1.15))
	rig.part(head, MeshKit.box(Vector3(0.2, 0.08, 0.12)), dark, Vector3(0.0, -0.02, -0.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.shard(0.07, 0.34, rng, 4, 0.0), skin, Vector3(side * 0.18, 0.12, 0.0), Vector3(0.1, 0.0, side * -1.25))
		rig.part(head, MeshKit.sphere(0.03, 6), eye, Vector3(side * 0.08, 0.12, -0.2))
		rig.part(head, MeshKit.shard(0.016, 0.07, rng, 4, 0.0), Look.matte(Color("dcd4bc"), 0.5), Vector3(side * 0.06, 0.0, -0.26), Vector3(0.0, 0.0, 0.0))
	for side: StringName in [&"r", &"l"]:
		_limb(rig, StringName("shoulder_%s" % side), 0.31, 0.06, 0.048, skin)
		_limb(rig, StringName("elbow_%s" % side), 0.31, 0.05, 0.04, skin)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.07, 6), dark)
		_limb(rig, StringName("hip_%s" % side), 0.37, 0.07, 0.05, skin)
		_limb(rig, StringName("knee_%s" % side), 0.37, 0.055, 0.045, skin)
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.box(Vector3(0.12, 0.06, 0.24)), dark, Vector3(0.0, -0.37, -0.05))
	var club := Node3D.new()
	var wood: Material = Look.matte(Color("4a3424"), 0.9)
	rig.part(club, MeshKit.cylinder(0.05, 0.028, 0.6, 7), wood, Vector3(0.0, 0.26, 0.0))
	rig.part(club, MeshKit.rock(0.11, rng, 0.9), Look.matte(Color("5e6a78"), 0.8), Vector3(0.0, 0.58, 0.0))
	rig.get_joint(&"hand_r").add_child(club)
	club.rotation.x = -PI * 0.5
	return rig


static func _wolf() -> CreatureRig:
	var rig := CreatureRig.new()
	rig.gait = CreatureRig.Gait.QUADRUPED
	rig.stride = 0.8
	rig.step_rate = 2.4
	var fur: Material = Look.matte(Color("8ea3b8"), 0.82)
	var pale: Material = Look.matte(Color("c8d6e4"), 0.85)
	var dark: Material = Look.matte(Color("2a3442"), 0.7)
	var eye: Material = Look.glow(Color("6fe0ff"), 4.0)
	var ice: Material = DungeonMaterials.crystal(Color(0.12, 0.3, 0.52), Color(0.6, 0.86, 1.0), 1.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	rig.set_pelvis_height(0.86)
	var body: Node3D = rig.joint(&"body", null, Vector3(0.0, 0.86, 0.0))
	var rings: Array[Vector4] = [Vector4(0.0, -0.62, 0.16, 0.18), Vector4(0.0, -0.3, 0.25, 0.3), Vector4(0.0, 0.14, 0.26, 0.33), Vector4(0.0, 0.5, 0.28, 0.38), Vector4(0.0, 0.72, 0.17, 0.25)]
	rig.part(body, MeshKit.loft(rings, 8, false), fur, Vector3.ZERO, Vector3(-PI * 0.5, 0.0, 0.0))
	for i in 5:
		rig.part(body, MeshKit.shard(0.08, 0.36 + rng.randf() * 0.2, rng, 4, 0.1), ice, Vector3(rng.randf_range(-0.05, 0.05), 0.22, -0.5 + i * 0.28), Vector3(rng.randf_range(0.1, 0.35), 0.0, rng.randf_range(-0.15, 0.15)))
	var neck: Node3D = rig.joint(&"neck", body, Vector3(0.0, 0.1, -0.62), Vector3(-0.2, 0.0, 0.0))
	rig.part(neck, MeshKit.cylinder(0.2, 0.25, 0.42, 8), pale, Vector3(0.0, 0.06, -0.18), Vector3(PI * 0.5 - 0.2, 0.0, 0.0))
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.1, -0.44)
	neck.add_child(head)
	rig.part(head, MeshKit.box(Vector3(0.3, 0.26, 0.32)), fur, Vector3.ZERO)
	rig.part(head, MeshKit.box(Vector3(0.17, 0.11, 0.36)), pale, Vector3(0.0, -0.03, -0.3))
	rig.part(head, MeshKit.box(Vector3(0.08, 0.06, 0.05)), dark, Vector3(0.0, 0.01, -0.49))
	var jaw: Node3D = rig.joint(&"jaw", head, Vector3(0.0, -0.1, -0.12))
	rig.part(jaw, MeshKit.box(Vector3(0.14, 0.05, 0.32)), pale, Vector3(0.0, -0.01, -0.17))
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.shard(0.075, 0.24, rng, 4, 0.0), fur, Vector3(side * 0.1, 0.11, 0.08))
		rig.part(head, MeshKit.sphere(0.03, 6), eye, Vector3(side * 0.1, 0.05, -0.17))
		rig.part(head, MeshKit.shard(0.015, 0.09, rng, 4, 0.0), Look.matte(Color("e8e4d4"), 0.4), Vector3(side * 0.06, -0.08, -0.42), Vector3(PI, 0.0, 0.0))
	var legs: Dictionary = { &"leg_fl": Vector3(-0.2, -0.12, -0.42), &"leg_fr": Vector3(0.2, -0.12, -0.42), &"leg_bl": Vector3(-0.2, -0.1, 0.42), &"leg_br": Vector3(0.2, -0.1, 0.42) }
	for leg: StringName in legs:
		var joint: Node3D = rig.joint(leg, body, legs[leg])
		rig.part(joint, MeshKit.cylinder(0.1, 0.06, 0.42, 7), fur, Vector3(0.0, -0.2, 0.0))
		rig.part(joint, MeshKit.cylinder(0.055, 0.045, 0.34, 6), pale, Vector3(0.0, -0.5, -0.02))
		rig.part(joint, MeshKit.box(Vector3(0.1, 0.05, 0.16)), dark, Vector3(0.0, -0.67, -0.05))
	var tail: Node3D = rig.joint(&"tail", body, Vector3(0.0, 0.1, 0.68), Vector3(0.7, 0.0, 0.0))
	rig.part(tail, MeshKit.cylinder(0.03, 0.11, 0.62, 6), pale, Vector3(0.0, 0.0, 0.28), Vector3(PI * 0.5, 0.0, 0.0))
	return rig


static func _skeleton() -> CreatureRig:
	var rig := CreatureRig.new()
	var bone: Material = Look.matte(Color("c9c3ae"), 0.65)
	var rust: Material = Look.metal(Color("7a5a44"), 0.75)
	var eye: Material = Look.glow(Color("6cc2ff"), 4.0)
	_biped_skeleton(rig, 1.0, 1.0, 0.9)
	var chest: Node3D = rig.get_joint(&"chest")
	rig.part(chest, MeshKit.cylinder(0.03, 0.035, 0.6, 6), bone, Vector3(0.0, 0.2, 0.05))
	for i in 5:
		var w: float = 0.21 - absf(i - 2) * 0.018
		rig.part(chest, MeshKit.torus(w - 0.018, w, 14), bone, Vector3(0.0, 0.12 + i * 0.09, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 0.72))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.torus(0.09, 0.17, 10), bone, Vector3(0.0, 0.02, 0.0), Vector3(0.4, 0.0, 0.0))
	var head: Node3D = rig.get_joint(&"head")
	rig.part(head, MeshKit.sphere(0.13, 9), bone, Vector3(0.0, 0.14, 0.0), Vector3.ZERO, Vector3(0.95, 1.05, 1.1))
	rig.part(head, MeshKit.box(Vector3(0.14, 0.06, 0.13)), bone, Vector3(0.0, 0.015, -0.08))
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.sphere(0.04, 6), Look.matte(Color("08090c"), 0.9), Vector3(side * 0.055, 0.15, -0.115))
		rig.part(head, MeshKit.sphere(0.018, 6), eye, Vector3(side * 0.055, 0.15, -0.142))
	rig.part(head, MeshKit.lathe(PackedVector2Array([Vector2(0.155, 0.17), Vector2(0.15, 0.25), Vector2(0.09, 0.31), Vector2(0.0, 0.33)]), 8, false), rust)
	rig.part(rig.get_joint(&"shoulder_r"), MeshKit.sphere(0.13, 8), rust, Vector3(0.02, 0.02, 0.0), Vector3.ZERO, Vector3(1.1, 0.75, 1.0))
	for side: StringName in [&"r", &"l"]:
		_limb(rig, StringName("shoulder_%s" % side), 0.3, 0.03, 0.025, bone)
		_limb(rig, StringName("elbow_%s" % side), 0.28, 0.026, 0.022, bone)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.04, 6), bone)
		_limb(rig, StringName("hip_%s" % side), 0.46, 0.035, 0.03, bone)
		_limb(rig, StringName("knee_%s" % side), 0.45, 0.03, 0.026, bone)
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.box(Vector3(0.09, 0.04, 0.2)), bone, Vector3(0.0, -0.46, -0.05))
	_grip(rig, WeaponKit.build_main_hand(&"sword_shield"), &"hand_r")
	var shield: Node3D = WeaponKit.build_off_hand(&"sword_shield")
	_grip(rig, shield, &"hand_l")
	shield.rotation = Vector3(0.0, PI * 0.5, 0.0)
	return rig


static func _shaman() -> CreatureRig:
	var rig := CreatureRig.new()
	var robe: Material = Look.matte(Color("2c3e5e"), 0.85)
	var trim: Material = Look.matte(Color("7fa8c8"), 0.6)
	var skin: Material = Look.matte(Color("6f8a96"), 0.7)
	_biped_skeleton(rig, 1.02, 0.95, 0.9)
	_robed_body(rig, robe, trim, skin, Color("2c3e5e"))
	_hood(rig, robe, Look.glow(Color("7fe0ff"), 4.0), false)
	var staff := WeaponKit.build_main_hand(&"staff", ItemData.Rarity.UNCOMMON)
	_grip(rig, staff, &"hand_r")
	staff.rotation.x = 0.0
	return rig


static func _golem() -> CreatureRig:
	var rig := CreatureRig.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var stone: Material = DungeonMaterials.stone_prop(0.6)
	var core: Material = DungeonMaterials.crystal(Color(0.15, 0.45, 0.8), Color(0.6, 0.92, 1.0), 2.2)
	_biped_skeleton(rig, 1.1, 1.15, 1.45)
	rig.stride = 0.5
	rig.step_rate = 1.5
	var chest: Node3D = rig.get_joint(&"chest")
	rig.part(chest, MeshKit.rock(0.5, rng, 0.95, 0.2), stone, Vector3(0.0, 0.34, 0.0), Vector3.ZERO, Vector3(1.15, 1.0, 0.9))
	rig.part(chest, MeshKit.shard(0.13, 0.5, rng, 5, 0.05), core, Vector3(0.0, 0.1, -0.44), Vector3(0.3, 0.0, 0.0))
	for i in 5:
		var angle: float = rng.randf_range(-1.2, 1.2)
		rig.part(chest, MeshKit.shard(0.13, rng.randf_range(0.4, 0.8), rng, 5, 0.1), core, Vector3(sin(angle) * 0.42, 0.62, cos(angle) * 0.3), Vector3(rng.randf_range(-0.2, 0.3), 0.0, angle * -0.5))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.rock(0.34, rng, 0.75), stone)
	var head: Node3D = rig.get_joint(&"head")
	rig.part(head, MeshKit.rock(0.2, rng, 0.85), stone, Vector3(0.0, 0.0, -0.1))
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.sphere(0.03, 6), Look.glow(Color("7fe0ff"), 5.0), Vector3(side * 0.08, 0.03, -0.27))
	for side: StringName in [&"r", &"l"]:
		var shoulder: Node3D = rig.get_joint(StringName("shoulder_%s" % side))
		rig.part(shoulder, MeshKit.rock(0.3, rng, 0.9), stone)
		rig.part(shoulder, MeshKit.rock(0.2, rng, 1.1), stone, Vector3(0.0, -0.26, 0.0))
		var elbow: Node3D = rig.get_joint(StringName("elbow_%s" % side))
		rig.part(elbow, MeshKit.rock(0.21, rng, 1.2), stone, Vector3(0.0, -0.1, 0.0))
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.rock(0.28, rng, 0.9), stone)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.shard(0.07, 0.34, rng, 5, 0.1), core, Vector3(0.0, -0.12, 0.0), Vector3(PI, 0.0, 0.0))
		rig.part(rig.get_joint(StringName("hip_%s" % side)), MeshKit.rock(0.22, rng, 1.2), stone, Vector3(0.0, -0.2, 0.0))
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.rock(0.2, rng, 1.2), stone, Vector3(0.0, -0.22, 0.0))
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.rock(0.22, rng, 0.6), stone, Vector3(0.0, -0.42, -0.04))
	return rig


static func _frost_king() -> CreatureRig:
	var rig := CreatureRig.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var plate: Material = Look.metal(Color("3f4d62"), 0.42)
	var dark: Material = Look.metal(Color("1a2029"), 0.55)
	var gold: Material = Look.metal(Color("9fb8d0"), 0.3)
	var ice: Material = DungeonMaterials.crystal(Color(0.14, 0.42, 0.72), Color(0.65, 0.92, 1.0), 2.0)
	var eye: Material = Look.glow(Color("7fe0ff"), 7.0)
	_biped_skeleton(rig, 1.0, 1.08, 1.2)
	rig.stride = 0.55
	rig.step_rate = 1.5
	_armored_body(rig, plate, gold, dark, 1.3)
	var chest: Node3D = rig.get_joint(&"chest")
	rig.part(chest, MeshKit.shard(0.1, 0.42, rng, 6, 0.0), ice, Vector3(0.0, 0.1, -0.25), Vector3(0.0, 0.0, 0.0))
	var head: Node3D = rig.get_joint(&"head")
	var helm := MeshKit.lathe(PackedVector2Array([Vector2(0.18, -0.04), Vector2(0.19, 0.1), Vector2(0.17, 0.22), Vector2(0.1, 0.31), Vector2(0.0, 0.34)]), 10, false)
	rig.part(head, helm, plate)
	rig.part(head, MeshKit.box(Vector3(0.28, 0.035, 0.05)), Look.matte(Color("06070b"), 0.4), Vector3(0.0, 0.14, -0.17))
	for side: float in [-1.0, 1.0]:
		rig.part(head, MeshKit.sphere(0.024, 6), eye, Vector3(side * 0.07, 0.145, -0.2))
		rig.part(head, MeshKit.shard(0.05, 0.42, rng, 5, 0.1), gold, Vector3(side * 0.16, 0.16, 0.0), Vector3(0.0, 0.0, side * -1.0))
	for i in 7:
		var angle: float = TAU * float(i) / 7.0
		rig.part(head, MeshKit.shard(0.04, 0.2 + (0.14 if i % 2 == 0 else 0.0), rng, 4, 0.03), ice, Vector3(cos(angle) * 0.15, 0.27, sin(angle) * 0.15), Vector3(sin(angle) * 0.25, 0.0, -cos(angle) * 0.25))
	for side: StringName in [&"r", &"l"]:
		var sign_x: float = 1.0 if side == &"r" else -1.0
		var shoulder: Node3D = rig.get_joint(StringName("shoulder_%s" % side))
		rig.part(shoulder, MeshKit.sphere(0.23, 10), plate, Vector3(sign_x * 0.04, 0.03, 0.0), Vector3.ZERO, Vector3(1.2, 0.8, 1.1))
		for i in 3:
			rig.part(shoulder, MeshKit.shard(0.055, 0.32 + i * 0.08, rng, 4, 0.05), ice, Vector3(sign_x * (0.06 + i * 0.07), 0.15, -0.08 + i * 0.08), Vector3(0.0, 0.0, sign_x * -0.4))
	var cape_material: StandardMaterial3D = Look.matte(Color("223a5c"), 0.9).duplicate()
	_cape(rig, cape_material, 0.92, 1.45)
	var sword := Node3D.new()
	var blade_material: Material = DungeonMaterials.crystal(Color(0.18, 0.46, 0.76), Color(0.72, 0.94, 1.0), 1.5)
	rig.part(sword, MeshKit.cylinder(0.03, 0.035, 0.34, 8), Look.matte(Color("20262e"), 0.8))
	rig.part(sword, MeshKit.box(Vector3(0.54, 0.06, 0.09)), gold, Vector3(0.0, 0.18, 0.0))
	rig.part(sword, MeshKit.blade(1.85, 0.2, 0.06, 0.16), blade_material, Vector3(0.0, 0.2, 0.0))
	rig.get_joint(&"hand_r").add_child(sword)
	sword.rotation.x = -PI * 0.5
	return rig
