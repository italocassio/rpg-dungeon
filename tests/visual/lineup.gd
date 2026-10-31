extends Node3D
## Foto de elenco com todos os modelos: godot --path . res://tests/visual/lineup.tscn -- --out=DIR

var _out := "user://lineup"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	add_to_group(&"world_root")
	var hall := DungeonData.new()
	var room := RoomData.new()
	room.kind = RoomData.Kind.ANTECHAMBER
	room.radius = 22.0
	room.wall_height = 10.0
	room.dome_height = 6.0
	var rooms: Array[RoomData] = [room]
	hall.rooms = rooms
	var world := DungeonWorld.new()
	add_child(world)
	world.build(hall, Color("53b6ff"))
	var camera := Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	world.focus = camera

	var cast: Array[Array] = [
		[CreatureFactory.build_hero(&"warrior", Color("8f9fb4"), &"sword_shield", ItemData.Rarity.COMMON), 1.0],
		[CreatureFactory.build_hero(&"mage", Color("3f5fae"), &"staff", ItemData.Rarity.UNCOMMON), 1.0],
		[CreatureFactory.build_hero(&"priest", Color("e8e2cf"), &"scepter", ItemData.Rarity.COMMON), 1.0],
		[CreatureFactory.build(&"goblin"), 0.82],
		[CreatureFactory.build(&"skeleton"), 1.05],
		[CreatureFactory.build(&"shaman"), 1.0],
		[CreatureFactory.build(&"wolf"), 1.0],
		[CreatureFactory.build(&"golem"), 1.5],
		[CreatureFactory.build(&"frost_king"), 2.5],
	]
	var x: float = -9.5
	for entry in cast:
		var rig: CreatureRig = entry[0]
		rig.scale = Vector3.ONE * entry[1]
		rig.position = Vector3(x, 0.0, 0.0)
		rig.rotation.y = PI + 0.25
		add_child(rig)
		x += 1.6 + entry[1] * 0.75
	for light_position: Vector3 in [Vector3(-6.0, 4.0, 6.0), Vector3(2.0, 4.5, 7.0), Vector3(9.0, 6.0, 7.0)]:
		var light := OmniLight3D.new()
		light.position = light_position
		light.light_energy = 3.0
		light.omni_range = 20.0
		light.light_color = Color("fff0dc")
		add_child(light)
	var time: float = 0.0
	camera.look_at_from_position(Vector3(1.5, 3.0, 15.5), Vector3(1.5, 2.0, 0.0))
	while time < 0.8:
		await get_tree().process_frame
		time += get_process_delta_time()
		for entry in cast:
			(entry[0] as CreatureRig).animate(get_process_delta_time(), 0.0)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out + "/lineup.png")
	camera.look_at_from_position(Vector3(-3.5, 1.7, 5.2), Vector3(-5.0, 1.0, 0.0))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out + "/lineup_close.png")
	get_tree().quit()
