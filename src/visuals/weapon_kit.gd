class_name WeaponKit
extends RefCounted
## Monta armas de herói a partir do id `weapon_model`, com os números das fichas de classe.
## Origem = empunhadura; lâmina para +Y. A pose na mão fica em `HeroBase.GRIPS`.
##
## Tier muda o metal e a forma; raridade muda a luz dos encaixes (seção 9 do guia).
## Raridade nunca cria luz real (C3): a única `OmniLight3D` é a da lanterna do `scepter`.

const STEEL := Color("B0AEA8")
const LEATHER := Color("3A2A22")
const SHIELD_LACQUER := Color("9A2A1F")
const STAFF_SHAFT := Color("2A2038")
const SCEPTER_SHAFT := Color("2B211B")
const TOME_COVER := Color("5A2A22")
const TOME_PAGES := Color("E8DFCA")
const FOCUS_CORE := Color("8A7BFF")
const LANTERN_CORE := Color("FFD76A")

const GLOW_ENERGY := 0.9
## Tier do aro interno do cajado (OS-014).
const STAFF_INNER_RING_TIER := 3
const STAFF_INNER_RING_INNER := 0.103
## Escala y do núcleo do cajado; no T3 o aro interno fecha o vão e o núcleo encolhe (OS-014, R1).
const STAFF_CORE_STRETCH := 1.45
const STAFF_CORE_STRETCH_T3 := 1.15
const LEGENDARY_ENERGY := 1.0
const LANTERN_LIGHT_ENERGY := 0.55
const LANTERN_LIGHT_RANGE := 3.0
const LANTERN_CENTER_Y := 0.96
## Tier da lanterna do cetro em que ela cresce, e quanto (OS-015).
const LANTERN_GROWTH_TIER := 3
const LANTERN_GROWTH := 1.18

## Modelos com peça na mão esquerda. Os outros devolvem `null` antes de criar qualquer nó.
const OFF_HAND_MODELS: Array[StringName] = [&"sword_shield", &"tome"]
## Encaixes acesos por raridade: 0 = nenhum, 1 = fio, 2 = fio e gema, 3 = os três.
const LIT_SLOTS: Dictionary = {
	ItemData.Rarity.COMMON: 0,
	ItemData.Rarity.UNCOMMON: 1,
	ItemData.Rarity.RARE: 2,
	ItemData.Rarity.EPIC: 3,
	ItemData.Rarity.LEGENDARY: 3,
}
const AXE_BLADE_PATH: Array[Vector2] = [Vector2(0.03, -0.1), Vector2(0.2, -0.2), Vector2(0.32, -0.26), Vector2(0.37, -0.1), Vector2(0.39, 0.06), Vector2(0.35, 0.22), Vector2(0.2, 0.17), Vector2(0.03, 0.1)]
const AXE_EDGE_PATH: Array[Vector2] = [Vector2(0.32, -0.26), Vector2(0.37, -0.1), Vector2(0.39, 0.06), Vector2(0.35, 0.22)]
const ORB_RING_ROTATION := Vector3(0.6, 0.0, 0.4)
const TOME_COVER_TILT := 0.24


static func accent_for(rarity: ItemData.Rarity) -> Color:
	return LootDrop.RARITY_COLORS[rarity]


static func build_main_hand(model: StringName, rarity: ItemData.Rarity = ItemData.Rarity.COMMON, tier: int = 0) -> Node3D:
	var root := Node3D.new()
	var slots: int = LIT_SLOTS[rarity]
	var glow: Material = _rarity_glow(rarity)
	var trim: Material = Look.trim(tier)
	match model:
		&"sword_shield":
			_sword(root, slots, glow, trim, tier)
		&"greataxe":
			_greataxe(root, slots, glow, trim)
		&"staff":
			_staff(root, slots, glow, trim, tier)
		&"orb":
			_orb(root, slots, glow, trim)
		&"scepter":
			_scepter(root, slots, glow, trim, tier)
		&"tome":
			_tome_light(root)
		_:
			_sword(root, slots, glow, trim, tier)
	return root


static func build_off_hand(model: StringName, rarity: ItemData.Rarity = ItemData.Rarity.COMMON, tier: int = 0) -> Node3D:
	if not OFF_HAND_MODELS.has(model):
		return null
	var root := Node3D.new()
	var slots: int = LIT_SLOTS[rarity]
	var glow: Material = _rarity_glow(rarity)
	match model:
		&"sword_shield":
			_shield(root, slots, glow, Look.trim(tier))
		&"tome":
			_tome(root, slots, glow)
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


## Material dos encaixes acesos: cor da raridade, energia do guia (seção 9). Comum não tem.
static func _rarity_glow(rarity: ItemData.Rarity) -> Material:
	if LIT_SLOTS[rarity] == 0:
		return null
	var energy: float = LEGENDARY_ENERGY if rarity == ItemData.Rarity.LEGENDARY else GLOW_ENERGY
	return Look.glow(accent_for(rarity), energy)


static func _steel() -> Material:
	return Look.hero(STEEL, 0.42, 0.35)


static func _leather() -> Material:
	return Look.hero(LEATHER, 0.8)


static func _lacquer(color: Color, roughness: float = 0.5) -> Material:
	return Look.hero(color, roughness)


static func _sword(root: Node3D, slots: int, glow: Material, trim: Material, tier: int) -> void:
	var long_blade: bool = tier >= 2
	var blade_length: float = 1.06 if long_blade else 0.98
	_add(root, MeshKit.cylinder(0.022, 0.026, 0.2, 8), _leather())
	_add(root, MeshKit.sphere(0.04, 8), trim, Vector3(0.0, -0.13, 0.0))
	_add(root, MeshKit.box(Vector3(0.28, 0.04, 0.06)), trim, Vector3(0.0, 0.11, 0.0))
	_add(root, MeshKit.blade(blade_length, 0.095, 0.026, 0.14), _steel(), Vector3(0.0, 0.12, 0.0))
	if slots >= 1:
		var shoulder_y: float = 1.04 if long_blade else 0.96
		var tip_y: float = 1.18 if long_blade else 1.1
		for side: float in [-1.0, 1.0]:
			var edge := PackedVector2Array([Vector2(side * 0.0475, 0.13), Vector2(side * 0.04, shoulder_y), Vector2(0.0, tip_y)])
			_add(root, MeshKit.extrude_path(edge, 0.012, 0.032), glow)
	if slots >= 2:
		_add(root, MeshKit.sphere(0.046, 8), glow, Vector3(0.0, -0.13, 0.0))
	if slots >= 3:
		for y: float in [0.098, 0.122]:
			_add(root, MeshKit.box(Vector3(0.2, 0.01, 0.066)), glow, Vector3(0.0, y, 0.0))


static func _greataxe(root: Node3D, slots: int, glow: Material, trim: Material) -> void:
	_add(root, MeshKit.cylinder(0.024, 0.028, 1.15, 8), _leather(), Vector3(0.0, 0.26, 0.0))
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.76, 0.0)
	root.add_child(head)
	var outline := PackedVector2Array(AXE_BLADE_PATH)
	var edge := PackedVector2Array(AXE_EDGE_PATH)
	var blade: ArrayMesh = MeshKit.plate(outline, 0.03)
	var edge_strip: ArrayMesh = MeshKit.extrude_path(edge, 0.012, 0.032) if slots >= 1 else null
	for side: float in [-1.0, 1.0]:
		var yaw := Vector3(0.0, PI if side < 0.0 else 0.0, 0.0)
		_add(head, blade, _steel(), Vector3.ZERO, yaw)
		if edge_strip != null:
			_add(head, edge_strip, glow, Vector3.ZERO, yaw)
	_add(head, MeshKit.cylinder(0.05, 0.05, 0.26, 8), trim)
	if slots >= 2:
		_add(head, MeshKit.sphere(0.05, 8), glow)
	if slots >= 3:
		_add(root, MeshKit.torus(0.035, 0.05, 12), glow, Vector3(0.0, 0.5, 0.0))


static func _shield(root: Node3D, slots: int, glow: Material, trim: Material) -> void:
	var face_up := Vector3(PI * 0.5, 0.0, 0.0)
	var profile := PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.38, -0.02), Vector2(0.37, 0.0), Vector2(0.2, 0.025), Vector2(0.0, 0.03)])
	_add(root, MeshKit.lathe(profile, 16, false), _lacquer(SHIELD_LACQUER), Vector3.ZERO, Vector3(-PI * 0.5, 0.0, 0.0))
	_add(root, MeshKit.torus(0.35, 0.4, 24), trim, Vector3.ZERO, face_up, Vector3(1.0, 0.6, 1.0))
	_add(root, MeshKit.sphere(0.08, 10), trim, Vector3(0.0, 0.0, -0.03))
	if slots >= 1:
		_add(root, MeshKit.torus(0.3, 0.325, 24), glow, Vector3(0.0, 0.0, -0.012), face_up)
	if slots >= 2:
		_add(root, MeshKit.sphere(0.04, 8), glow, Vector3(0.0, 0.0, -0.1))
	if slots >= 3:
		_add(root, MeshKit.torus(0.115, 0.14, 20), glow, Vector3(0.0, 0.0, -0.03), face_up)


static func _staff(root: Node3D, slots: int, glow: Material, trim: Material, tier: int = 0) -> void:
	var face_front := Vector3(PI * 0.5, 0.0, 0.0)
	var focus := Vector3(0.0, 1.11, 0.0)
	_add(root, MeshKit.cylinder(0.022, 0.03, 2.1, 8), _lacquer(STAFF_SHAFT), Vector3(0.0, -0.03, 0.0))
	_add(root, MeshKit.torus(0.135, 0.185, 20), trim, focus, face_front)
	if tier >= STAFF_INNER_RING_TIER:
		var inner_ring: MeshInstance3D = _add(root, MeshKit.torus(STAFF_INNER_RING_INNER, 0.125, 20), trim, focus, face_front)
		inner_ring.name = "t3_aro_interno"
		inner_ring.set_meta(&"tier", STAFF_INNER_RING_TIER)
	var core_stretch: float = STAFF_CORE_STRETCH_T3 if tier >= STAFF_INNER_RING_TIER else STAFF_CORE_STRETCH
	_add(root, MeshKit.sphere(0.085, 12), Look.glow(FOCUS_CORE, GLOW_ENERGY), focus, Vector3.ZERO, Vector3(1.0, core_stretch, 1.0))
	if slots >= 1:
		_add(root, MeshKit.torus(0.125, 0.135, 20), glow, focus, face_front)
	if slots >= 2:
		_add(root, MeshKit.sphere(0.03, 8), glow, Vector3(0.0, 0.88, 0.0))
	if slots >= 3:
		_add(root, MeshKit.torus(0.19, 0.2, 20), glow, focus, face_front)


static func _orb(root: Node3D, slots: int, glow: Material, trim: Material) -> void:
	_add(root, MeshKit.sphere(0.1, 16), Look.glow(FOCUS_CORE, GLOW_ENERGY))
	_add(root, MeshKit.torus(0.13, 0.155, 24), trim, Vector3.ZERO, ORB_RING_ROTATION)
	if slots >= 1:
		_add(root, MeshKit.torus(0.16, 0.17, 20), glow, Vector3.ZERO, ORB_RING_ROTATION)
	if slots >= 2:
		# Ponto do aro voltado para a frente e para cima.
		var on_ring: Vector3 = Basis.from_euler(ORB_RING_ROTATION) * Vector3(0.0, 0.0, -0.1425)
		_add(root, MeshKit.sphere(0.03, 8), glow, on_ring)
	if slots >= 3:
		_add(root, MeshKit.torus(0.16, 0.17, 20), glow, Vector3.ZERO, Vector3(-0.6, 0.0, 0.4))


## A única `OmniLight3D` do kit: a lanterna, igual em todas as raridades e tiers. Segue a arma.
## No tier 3 a lanterna cresce 18% em volta do próprio centro; a luz acompanha o núcleo.
static func _scepter(root: Node3D, slots: int, glow: Material, trim: Material, tier: int = 0) -> void:
	var grow: float = LANTERN_GROWTH if tier >= LANTERN_GROWTH_TIER else 1.0
	var grown := Vector3.ONE * grow
	var lantern := Vector3(0.0, 0.98, 0.0)
	_add(root, MeshKit.cylinder(0.02, 0.026, 1.5, 8), _lacquer(SCEPTER_SHAFT, 0.55), Vector3(0.0, 0.2, 0.0))
	var roof := PackedVector2Array([Vector2(0.09, 0.08), Vector2(0.125, 0.08), Vector2(0.115, 0.1), Vector2(0.03, 0.14)])
	_add(root, MeshKit.lathe(roof, 6, false), trim, lantern, Vector3.ZERO, grown)
	var base := PackedVector2Array([Vector2(0.08, -0.16), Vector2(0.115, -0.11), Vector2(0.11, -0.13)])
	_add(root, MeshKit.lathe(base, 6), trim, lantern, Vector3.ZERO, grown)
	var bar: BoxMesh = MeshKit.box(Vector3(0.012, 0.2, 0.012))
	for i in 6:
		var angle: float = TAU * i / 6.0
		var lit: bool = slots >= 1 and i % 3 == 0
		_add(root, bar, glow if lit else trim, lantern + Vector3(cos(angle) * 0.105, 0.0, sin(angle) * 0.105) * grow, Vector3(0.0, -angle, 0.0), grown)
	var core: Vector3 = lantern + (Vector3(0.0, LANTERN_CENTER_Y, 0.0) - lantern) * grow
	_add(root, MeshKit.sphere(0.075, 10), Look.glow(LANTERN_CORE, GLOW_ENERGY), core, Vector3.ZERO, Vector3(1.0, 1.3, 1.0) * grow)
	if slots >= 2:
		_add(root, MeshKit.sphere(0.03, 8), glow, Vector3(0.0, 0.72, 0.0))
	if slots >= 3:
		_add(root, MeshKit.torus(0.1, 0.11, 12), glow, Vector3(0.0, 0.82, 0.0))
	var light := OmniLight3D.new()
	light.light_color = LANTERN_CORE
	light.light_energy = LANTERN_LIGHT_ENERGY
	light.omni_range = LANTERN_LIGHT_RANGE
	light.shadow_enabled = false
	light.position = core
	root.add_child(light)


## Tomo na mão direita: só o núcleo emissivo, sem luz real.
static func _tome_light(root: Node3D) -> void:
	_add(root, MeshKit.sphere(0.06, 12), Look.glow(LANTERN_CORE, GLOW_ENERGY))


## Livro aberto com as páginas em +Z, voltadas para quem segura.
static func _tome(root: Node3D, slots: int, glow: Material) -> void:
	var cover: Material = Look.hero(TOME_COVER, 0.7)
	var pages: Material = Look.hero(TOME_PAGES, 0.9)
	for side: float in [-1.0, 1.0]:
		var yaw := Vector3(0.0, -side * TOME_COVER_TILT, 0.0)
		_add(root, MeshKit.box(Vector3(0.21, 0.28, 0.02)), cover, Vector3(side * 0.11, 0.0, 0.0), yaw)
		_add(root, MeshKit.box(Vector3(0.19, 0.25, 0.03)), pages, Vector3(side * 0.105, 0.0, 0.022), yaw)
	var bounds: AABB = _bounds_of(root)
	if slots >= 1:
		_add(root, MeshKit.box(Vector3(0.02, 0.28, 0.03)), glow)
	if slots >= 2:
		_add(root, MeshKit.sphere(0.036, 8), glow, Vector3(0.0, 0.15, 0.0))
	if slots >= 3:
		var half_width: float = bounds.size.x * 0.5
		var half_height: float = bounds.size.y * 0.5
		var depth: float = bounds.size.z + 0.012
		for x: float in [-1.0, 1.0]:
			for y: float in [-1.0, 1.0]:
				_add(root, MeshKit.box(Vector3(0.07, 0.02, depth)), glow, Vector3(x * (half_width - 0.032), y * (half_height - 0.007), 0.0))
				_add(root, MeshKit.box(Vector3(0.02, 0.07, depth)), glow, Vector3(x * (half_width - 0.007), y * (half_height - 0.032), 0.0))


static func _bounds_of(root: Node3D) -> AABB:
	var bounds := AABB()
	var first: bool = true
	for child in root.get_children():
		var piece := child as MeshInstance3D
		if piece == null:
			continue
		var box: AABB = piece.transform * piece.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds
