class_name EnemyParts
extends RefCounted
## Corpos e armas que só os inimigos usam (regra S4 do guia de estilo).
## Os corpos antigos de herói em CreatureFactory chamam estas funções até as OS-009 a 011.


static func armored_body(rig: CreatureRig, plate: Material, trim: Material, dark: Material, bulk: float) -> void:
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
		CreatureRig.limb(rig, StringName("shoulder_%s" % side), 0.3, 0.075, 0.06, dark)
		CreatureRig.limb(rig, StringName("elbow_%s" % side), 0.3, 0.075, 0.06, plate)
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.065, 8), plate)
		CreatureRig.limb(rig, StringName("hip_%s" % side), 0.46, 0.1, 0.075, dark)
		CreatureRig.limb(rig, StringName("knee_%s" % side), 0.46, 0.085, 0.07, plate)
		rig.part(rig.get_joint(StringName("knee_%s" % side)), MeshKit.box(Vector3(0.14, 0.09, 0.3)), plate, Vector3(0.0, -0.47, -0.06))


## Sem pernas: a saia cobre as duas em toda a animação (regra J5). Os joints continuam no esqueleto.
static func robed_body(rig: CreatureRig, robe: Material, trim: Material, skin: Material, tint: Color) -> void:
	var chest: Node3D = rig.get_joint(&"chest")
	var torso: Array[Vector4] = [Vector4(0.0, -0.08, 0.19, 0.14), Vector4(0.0, 0.2, 0.2, 0.14), Vector4(0.0, 0.46, 0.25, 0.15), Vector4(0.0, 0.56, 0.11, 0.1)]
	rig.part(chest, MeshKit.loft(torso, 10), robe)
	rig.part(chest, MeshKit.torus(0.07, 0.13, 12), trim, Vector3(0.0, 0.55, 0.0), Vector3.ZERO, Vector3(1.0, 0.7, 1.0))
	var skirt := MeshKit.lathe(PackedVector2Array([Vector2(0.37, -0.93), Vector2(0.33, -0.88), Vector2(0.2, -0.05), Vector2(0.17, 0.08)]), 14)
	rig.part(rig.get_joint(&"pelvis"), skirt, robe, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.lathe(PackedVector2Array([Vector2(0.385, -0.93), Vector2(0.37, -0.83), Vector2(0.34, -0.83)]), 14), trim, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	rig.part(rig.get_joint(&"pelvis"), MeshKit.box(Vector3(0.12, 0.72, 0.02)), Look.matte(tint.lightened(0.28), 0.8), Vector3(0.0, -0.42, -0.214), Vector3(0.125, 0.0, 0.0))
	for side: StringName in [&"r", &"l"]:
		CreatureRig.limb(rig, StringName("shoulder_%s" % side), 0.3, 0.08, 0.09, robe)
		rig.part(rig.get_joint(StringName("elbow_%s" % side)), MeshKit.cylinder(0.14, 0.085, 0.29, 8), robe, Vector3(0.0, -0.15, 0.0))
		rig.part(rig.get_joint(StringName("hand_%s" % side)), MeshKit.sphere(0.05, 8), skin)


static func hood(rig: CreatureRig, cloth: Material, eye: Material, pointed: bool) -> void:
	var head: Node3D = rig.get_joint(&"head")
	var tip: float = 0.46 if pointed else 0.32
	var mesh := MeshKit.lathe(PackedVector2Array([Vector2(0.2, -0.04), Vector2(0.17, 0.12), Vector2(0.13, 0.24), Vector2(0.03, tip)]), 10)
	rig.part(head, mesh, cloth)
	rig.part(head, MeshKit.sphere(0.13, 8), Look.matte(Color("06070b"), 0.9), Vector3(0.0, 0.11, -0.06))
	rig.part(head, MeshKit.sphere(0.025, 6), eye, Vector3(0.055, 0.13, -0.17))
	rig.part(head, MeshKit.sphere(0.025, 6), eye, Vector3(-0.055, 0.13, -0.17))


## Duplica o material antes de desligar o culling: o original pode estar no cache de Look.
static func cape(rig: CreatureRig, material: Material, width: float, length: float) -> void:
	var mesh: ArrayMesh = MeshKit.cloth(width * 0.62, width, length, 0.22)
	var cloth_material: Material = material.duplicate()
	var both := cloth_material as BaseMaterial3D
	if both != null:
		both.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cape_mesh: MeshInstance3D = rig.part(rig.get_joint(&"chest"), mesh, cloth_material, Vector3(0.0, 0.5, 0.17))
	cape_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func sword(root: Node3D) -> void:
	var leather: Material = Look.matte(Color("3a2a22"), 0.85)
	var gold: Material = Look.metal(Color("b98f45"), 0.4)
	_add(root, MeshKit.cylinder(0.022, 0.026, 0.2, 8), leather, Vector3(0.0, 0.0, 0.0))
	_add(root, MeshKit.box(Vector3(0.24, 0.035, 0.05)), gold, Vector3(0.0, 0.11, 0.0))
	_add(root, MeshKit.sphere(0.035, 8), gold, Vector3(0.0, -0.11, 0.0))
	_add(root, MeshKit.blade(0.82, 0.075, 0.024, 0.14), Look.metal(Color("aeb9c8"), 0.3), Vector3(0.0, 0.12, 0.0))


static func shield(root: Node3D) -> void:
	var profile := PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.34, -0.02), Vector2(0.33, 0.0), Vector2(0.18, 0.025), Vector2(0.0, 0.03)])
	_add(root, MeshKit.lathe(profile, 18), Look.metal(Color("6f7a8c"), 0.5), Vector3.ZERO, Vector3(PI * 0.5, 0.0, 0.0))
	_add(root, MeshKit.torus(0.31, 0.35, 24), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 0.0, 0.0), Vector3(PI * 0.5, 0.0, 0.0), Vector3(1.0, 0.6, 1.0))
	_add(root, MeshKit.sphere(0.07, 10), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 0.0, -0.035))


static func staff(root: Node3D, crystal: Color) -> void:
	_add(root, MeshKit.cylinder(0.02, 0.026, 1.4, 8), Look.matte(Color("4a3424"), 0.8), Vector3(0.0, 0.35, 0.0))
	_add(root, MeshKit.torus(0.05, 0.09, 12), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 1.05, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_add(root, MeshKit.shard(0.075, 0.3, rng, 6, 0.0), Look.glow(crystal, 2.4), Vector3(0.0, 1.03, 0.0))


static func _add(root: Node3D, mesh: Mesh, material: Material, offset := Vector3.ZERO, rotation_offset := Vector3.ZERO, scale_factor := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	instance.rotation = rotation_offset
	instance.scale = scale_factor
	root.add_child(instance)
	return instance
