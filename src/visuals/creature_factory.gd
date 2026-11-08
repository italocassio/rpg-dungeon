class_name CreatureFactory
extends RefCounted
## Monta o modelo de cada monstro/herói a partir de partes procedurais.


## `glow` é o brilho de olho da masmorra (`DungeonData.enemy_glow`), obrigatório.
static func build(visual: StringName, glow: Color) -> CreatureRig:
	match visual:
		&"goblin":
			return _goblin(glow)
		&"wolf":
			return _wolf(glow)
		&"skeleton":
			return _skeleton(glow)
		&"shaman":
			return _shaman(glow)
		&"golem":
			return _golem(glow)
		&"frost_king":
			return _frost_king(glow)
	push_warning("Visual desconhecido: %s" % visual)
	return _goblin(glow)


## Herói do grupo. Cada classe vem do seu modelo em `heroes/`: `WarriorModel`, `MageModel` e `PriestModel`.
static func build_hero(look: HeroLook) -> CreatureRig:
	var rig := CreatureRig.new()
	match look.class_id:
		&"warrior":
			WarriorModel.assemble(rig, look)
		&"mage":
			MageModel.assemble(rig, look)
		&"priest":
			PriestModel.assemble(rig, look)
		_:
			push_warning("Classe de herói desconhecida: %s" % look.class_id)
			CreatureRig.biped_skeleton(rig, 1.0, 1.0, 1.0)
			return rig
	HeroBase.wield(rig, look)
	return rig


static func _grip(rig: CreatureRig, weapon: Node3D, hand: StringName) -> void:
	var joint: Node3D = rig.get_joint(hand)
	joint.add_child(weapon)
	weapon.rotation.x = -PI * 0.5
	rig.adopt_meshes(weapon)


static func _goblin(glow: Color) -> CreatureRig:
	var rig := CreatureRig.new()
	var skin: Material = Look.matte(Color("4f6f73"), 0.68)
	var dark: Material = Look.matte(Color("2b3a40"), 0.7)
	var cloth: Material = Look.matte(Color("5a4232"), 0.9)
	var eye: Material = Look.glow(glow, 4.0)
	CreatureRig.biped_skeleton(rig, 0.8, 1.3, 1.05)
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
		CreatureRig.limb(rig, StringName("shoulder_%s" % side), 0.31, 0.06, 0.048, skin)
		CreatureRig.limb(rig, StringName("elbow_%s" % side), 0.31, 0.05, 0.04, skin)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.07, 6), dark)
		CreatureRig.limb(rig, StringName("hip_%s" % side), 0.37, 0.07, 0.05, skin)
		CreatureRig.limb(rig, StringName("knee_%s" % side), 0.37, 0.055, 0.045, skin)
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.box(Vector3(0.12, 0.06, 0.24)), dark, Vector3(0.0, -0.37, -0.05))
	var club := Node3D.new()
	var wood: Material = Look.matte(Color("4a3424"), 0.9)
	rig.part(club, MeshKit.cylinder(0.05, 0.028, 0.6, 7), wood, Vector3(0.0, 0.26, 0.0))
	rig.part(club, MeshKit.rock(0.11, rng, 0.9), Look.matte(Color("5e6a78"), 0.8), Vector3(0.0, 0.58, 0.0))
	rig.get_joint(&"hand_r").add_child(club)
	club.rotation.x = -PI * 0.5
	rig.set_rest(&"shoulder_r", Vector3(0.0, 0.0, 0.12))
	rig.knee_bend = 0.65
	return rig


static func _wolf(glow: Color) -> CreatureRig:
	var rig := CreatureRig.new()
	rig.gait = CreatureRig.Gait.QUADRUPED
	rig.stride = 0.8
	rig.step_rate = 2.4
	var fur: Material = Look.matte(Color("8ea3b8"), 0.82)
	var pale: Material = Look.matte(Color("c8d6e4"), 0.85)
	var dark: Material = Look.matte(Color("2a3442"), 0.7)
	var eye: Material = Look.glow(glow, 4.0)
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


static func _skeleton(glow: Color) -> CreatureRig:
	var rig := CreatureRig.new()
	var bone: Material = Look.matte(Color("c9c3ae"), 0.65)
	var rust: Material = Look.metal(Color("7a5a44"), 0.75)
	var eye: Material = Look.glow(glow, 4.0)
	CreatureRig.biped_skeleton(rig, 1.0, 1.0, 0.9)
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
		CreatureRig.limb(rig, StringName("shoulder_%s" % side), 0.3, 0.03, 0.025, bone)
		CreatureRig.limb(rig, StringName("elbow_%s" % side), 0.28, 0.026, 0.022, bone)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.04, 6), bone)
		CreatureRig.limb(rig, StringName("hip_%s" % side), 0.46, 0.035, 0.03, bone)
		CreatureRig.limb(rig, StringName("knee_%s" % side), 0.45, 0.03, 0.026, bone)
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.box(Vector3(0.09, 0.04, 0.2)), bone, Vector3(0.0, -0.46, -0.05))
	var sword := Node3D.new()
	EnemyParts.sword(sword)
	_grip(rig, sword, &"hand_r")
	var shield := Node3D.new()
	EnemyParts.shield(shield)
	_grip(rig, shield, &"hand_l")
	shield.rotation = Vector3(0.0, PI * 0.5, 0.0)
	return rig


static func _shaman(glow: Color) -> CreatureRig:
	var rig := CreatureRig.new()
	var robe: Material = Look.matte(Color("2c3e5e"), 0.85)
	var trim: Material = Look.matte(Color("7fa8c8"), 0.6)
	var skin: Material = Look.matte(Color("6f8a96"), 0.7)
	CreatureRig.biped_skeleton(rig, 1.02, 0.95, 0.9)
	EnemyParts.robed_body(rig, robe, trim, skin, Color("2c3e5e"))
	EnemyParts.hood(rig, robe, Look.glow(glow, 4.0), false)
	var staff := Node3D.new()
	EnemyParts.staff(staff, Color("7fd4ff"))
	_grip(rig, staff, &"hand_r")
	staff.rotation.x = 0.0
	return rig


static func _golem(glow: Color) -> CreatureRig:
	var rig := CreatureRig.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var stone: Material = DungeonMaterials.stone_prop(0.6)
	var core: Material = DungeonMaterials.crystal(Color(0.15, 0.45, 0.8), Color(0.6, 0.92, 1.0), 2.2)
	CreatureRig.biped_skeleton(rig, 1.1, 1.15, 1.45)
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
		rig.part(head, MeshKit.sphere(0.03, 6), Look.glow(glow, 4.0), Vector3(side * 0.08, 0.03, -0.27))
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


## O modelo mora em `enemies/frost_king_model.gd`.
static func _frost_king(glow: Color) -> CreatureRig:
	var rig := CreatureRig.new()
	FrostKingModel.assemble(rig, glow)
	return rig
