class_name GatePortal
extends Node3D
## Portão dimensional. Na saída, interagir encerra a masmorra.

signal activated

const INTERACT_NAME := "Sair do Portão"

var gate_color := Color("53b6ff")
var is_exit: bool = false


func _ready() -> void:
	var stone: Material = DungeonMaterials.stone_prop(0.35)
	var ring := MeshInstance3D.new()
	ring.mesh = MeshKit.torus(2.75, 3.3, 32)
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3(1.0, 1.0, 1.42)
	ring.position.y = 4.1
	ring.material_override = stone
	add_child(ring)

	var surface := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(5.6, 7.9)
	surface.mesh = quad
	surface.position.y = 4.1
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/portal.gdshader")
	material.set_shader_parameter("gate_color", gate_color)
	material.set_shader_parameter("tex_noise", load("res://assets/textures/noise.png"))
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 4.0, 1.5)
	light.light_color = gate_color.lightened(0.25)
	light.light_energy = 5.0
	light.omni_range = 17.0
	add_child(light)

	var motes := ParticleKit.embers(gate_color.lightened(0.3), 22)
	motes.position = Vector3(0.0, 1.0, 0.6)
	(motes.process_material as ParticleProcessMaterial).emission_sphere_radius = 2.6
	add_child(motes)

	if is_exit:
		add_to_group(&"interactable")


func interact_label() -> String:
	return INTERACT_NAME


func interact(_player: Node) -> void:
	activated.emit()
