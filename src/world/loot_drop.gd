class_name LootDrop
extends Node3D
## Item no chão. É atraído pelo jogador e entregue ao inventário ao tocá-lo.

signal collected(drop: LootDrop)

const RARITY_COLORS: Dictionary = {
	ItemData.Rarity.COMMON: Color("c8d0dc"),
	ItemData.Rarity.UNCOMMON: Color("6fe08a"),
	ItemData.Rarity.RARE: Color("5aa8ff"),
	ItemData.Rarity.EPIC: Color("c07aff"),
	ItemData.Rarity.LEGENDARY: Color("ffb13c"),
}
const MAGNET_SPEED := 13.0
const COLLECT_DISTANCE := 0.9

var item: ItemData
var count: int = 1
var collector: Node3D
var pickup_radius: float = 3.2

var _time: float = 0.0
var _visual: Node3D
var _claimed: bool = false


func _ready() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	if not Vfx.enabled():
		return
	var color: Color = RARITY_COLORS[item.rarity]
	var rng := RandomNumberGenerator.new()
	rng.seed = item.id.hash()
	var shard := MeshInstance3D.new()
	shard.mesh = MeshKit.shard(0.16, 0.5, rng, 5, 0.05)
	shard.material_override = Look.glow(color, 2.4)
	shard.position.y = 0.2
	_visual.add_child(shard)
	var beam_height: float = 1.6 + float(item.rarity) * 1.0
	var beam := MeshInstance3D.new()
	beam.mesh = MeshKit.cylinder(0.02, 0.15, beam_height, 8)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color, 0.35)
	beam.material_override = material
	beam.position.y = beam_height * 0.5
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	if item.rarity >= ItemData.Rarity.RARE:
		var light := OmniLight3D.new()
		light.position.y = 1.0
		light.light_color = color
		light.light_energy = 1.6
		light.omni_range = 5.0
		add_child(light)


## Cada drop só pode ser entregue uma vez, venha a coleta do toque ou da saída do portão.
func claim() -> bool:
	if _claimed:
		return false
	_claimed = true
	return true


func _process(delta: float) -> void:
	if _claimed:
		return
	_time += delta
	_visual.rotation.y = _time * 1.8
	_visual.position.y = 0.2 + sin(_time * 2.6) * 0.09
	if not is_instance_valid(collector):
		return
	var offset: Vector3 = collector.global_position - global_position
	var distance: float = offset.length()
	if distance < pickup_radius and _time > 0.25:
		global_position += offset.normalized() * MAGNET_SPEED * delta
		if distance < COLLECT_DISTANCE and claim():
			collected.emit(self)
			queue_free()
