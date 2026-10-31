class_name WeaponKit
extends RefCounted
## Monta armas a partir do id `weapon_model`. Origem = empunhadura; lâmina para +Y.


static func accent_for(rarity: ItemData.Rarity) -> Color:
	match rarity:
		ItemData.Rarity.UNCOMMON:
			return Color("7fd4ff")
		ItemData.Rarity.RARE:
			return Color("ffd76a")
		ItemData.Rarity.EPIC, ItemData.Rarity.LEGENDARY:
			return Color("8ab8ff")
	return Color(0.0, 0.0, 0.0, 0.0)


static func build_main_hand(model: StringName, rarity: ItemData.Rarity = ItemData.Rarity.COMMON) -> Node3D:
	var root := Node3D.new()
	var accent: Color = accent_for(rarity)
	match model:
		&"sword_shield":
			_sword(root, accent)
		&"greataxe":
			_greataxe(root, accent)
		&"staff":
			_staff(root, accent)
		&"orb":
			_orb(root, accent)
		&"scepter":
			_scepter(root, accent)
		&"tome":
			_wand_light(root, accent)
		_:
			_sword(root, accent)
	return root


static func build_off_hand(model: StringName) -> Node3D:
	var root := Node3D.new()
	match model:
		&"sword_shield":
			_shield(root)
		&"tome":
			_tome(root)
		_:
			return null
	return root


static func _add(root: Node3D, mesh: Mesh, material: Material, offset := Vector3.ZERO, rotation_offset := Vector3.ZERO, scale_factor := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	instance.rotation = rotation_offset
	instance.scale = scale_factor
	root.add_child(instance)
	return instance


static func _edge_material(accent: Color) -> Material:
	if accent.a > 0.0:
		return Look.glow(accent, 1.1)
	return Look.matte(Color("c9d2de"), 0.28, 0.95)


static func _sword(root: Node3D, accent: Color) -> void:
	var leather: Material = Look.matte(Color("3a2a22"), 0.85)
	var gold: Material = Look.metal(Color("b98f45"), 0.4)
	_add(root, MeshKit.cylinder(0.022, 0.026, 0.2, 8), leather, Vector3(0.0, 0.0, 0.0))
	_add(root, MeshKit.box(Vector3(0.24, 0.035, 0.05)), gold, Vector3(0.0, 0.11, 0.0))
	_add(root, MeshKit.sphere(0.035, 8), gold, Vector3(0.0, -0.11, 0.0))
	_add(root, MeshKit.blade(0.82, 0.075, 0.024, 0.14), Look.metal(Color("aeb9c8"), 0.3), Vector3(0.0, 0.12, 0.0))
	if accent.a > 0.0:
		_add(root, MeshKit.blade(0.76, 0.02, 0.03, 0.14), _edge_material(accent), Vector3(0.0, 0.13, 0.0))


static func _greataxe(root: Node3D, accent: Color) -> void:
	_add(root, MeshKit.cylinder(0.024, 0.028, 1.15, 8), Look.matte(Color("3a2a22"), 0.85), Vector3(0.0, 0.26, 0.0))
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.76, 0.0)
	root.add_child(head)
	for side: float in [-1.0, 1.0]:
		var path := PackedVector2Array([Vector2(0.03, -0.1), Vector2(0.2, -0.2), Vector2(0.32, -0.26), Vector2(0.37, -0.1), Vector2(0.39, 0.06), Vector2(0.35, 0.22), Vector2(0.2, 0.17), Vector2(0.03, 0.1)])
		var blade: ArrayMesh = _plate(path, 0.03)
		_add(head, blade, Look.metal(Color("9aa5b4"), 0.35), Vector3.ZERO, Vector3(0.0, PI if side < 0.0 else 0.0, 0.0))
	_add(head, MeshKit.cylinder(0.05, 0.05, 0.26, 8), Look.metal(Color("5a616c"), 0.5))
	if accent.a > 0.0:
		_add(head, MeshKit.sphere(0.05, 8), _edge_material(accent))


static func _plate(outline: PackedVector2Array, thickness: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var half: float = thickness * 0.5
	var count: int = outline.size()
	var center := Vector2.ZERO
	for point in outline:
		center += point
	center /= count
	for i in count:
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % count]
		st.add_vertex(Vector3(center.x, center.y, half))
		st.add_vertex(Vector3(b.x, b.y, 0.0))
		st.add_vertex(Vector3(a.x, a.y, 0.0))
		st.add_vertex(Vector3(center.x, center.y, -half))
		st.add_vertex(Vector3(a.x, a.y, 0.0))
		st.add_vertex(Vector3(b.x, b.y, 0.0))
	st.generate_normals()
	return st.commit()


static func _shield(root: Node3D) -> void:
	var profile := PackedVector2Array([Vector2(0.0, 0.03), Vector2(0.18, 0.025), Vector2(0.33, 0.0), Vector2(0.34, -0.02), Vector2(0.0, -0.02)])
	_add(root, MeshKit.lathe(profile, 18), Look.metal(Color("6f7a8c"), 0.5), Vector3.ZERO, Vector3(PI * 0.5, 0.0, 0.0))
	_add(root, MeshKit.torus(0.31, 0.35, 24), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 0.0, 0.0), Vector3(PI * 0.5, 0.0, 0.0), Vector3(1.0, 0.6, 1.0))
	_add(root, MeshKit.sphere(0.07, 10), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 0.0, -0.035))


static func _staff(root: Node3D, accent: Color) -> void:
	var crystal: Color = accent if accent.a > 0.0 else Color("5fb0ff")
	_add(root, MeshKit.cylinder(0.02, 0.026, 1.4, 8), Look.matte(Color("4a3424"), 0.8), Vector3(0.0, 0.35, 0.0))
	_add(root, MeshKit.torus(0.05, 0.09, 12), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 1.05, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_add(root, MeshKit.shard(0.075, 0.3, rng, 6, 0.0), Look.glow(crystal, 2.4), Vector3(0.0, 1.03, 0.0))


static func _orb(root: Node3D, accent: Color) -> void:
	var crystal: Color = accent if accent.a > 0.0 else Color("8a7bff")
	_add(root, MeshKit.sphere(0.1, 16), Look.glow(crystal, 2.0), Vector3(0.0, 0.16, 0.0))
	_add(root, MeshKit.torus(0.13, 0.15, 20), Look.metal(Color("b98f45"), 0.4), Vector3(0.0, 0.16, 0.0), Vector3(0.6, 0.0, 0.4))


static func _scepter(root: Node3D, accent: Color) -> void:
	var gold: Material = Look.metal(Color("c9a24f"), 0.35)
	var crystal: Color = accent if accent.a > 0.0 else Color("ffe9a8")
	_add(root, MeshKit.cylinder(0.018, 0.024, 0.74, 8), gold, Vector3(0.0, 0.1, 0.0))
	for i in 6:
		var angle: float = TAU * i / 6.0
		_add(root, MeshKit.box(Vector3(0.1, 0.17, 0.018)), gold, Vector3(cos(angle) * 0.055, 0.52, sin(angle) * 0.055), Vector3(0.0, -angle, 0.0))
	_add(root, MeshKit.sphere(0.052, 10), Look.glow(crystal, 2.2), Vector3(0.0, 0.53, 0.0))


static func _wand_light(root: Node3D, accent: Color) -> void:
	var color: Color = accent if accent.a > 0.0 else Color("ffe9a8")
	_add(root, MeshKit.sphere(0.075, 12), Look.glow(color, 3.0), Vector3(0.0, 0.12, 0.0))


static func _tome(root: Node3D) -> void:
	var cover: Material = Look.matte(Color("5a2a22"), 0.7)
	var pages: Material = Look.matte(Color("e8dfca"), 0.9)
	for side: float in [-1.0, 1.0]:
		_add(root, MeshKit.box(Vector3(0.21, 0.28, 0.02)), cover, Vector3(side * 0.11, 0.0, 0.0), Vector3(0.0, side * 0.24, 0.0))
		_add(root, MeshKit.box(Vector3(0.19, 0.25, 0.03)), pages, Vector3(side * 0.105, 0.0, -0.022), Vector3(0.0, side * 0.24, 0.0))
