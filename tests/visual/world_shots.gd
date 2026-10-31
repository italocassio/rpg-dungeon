extends Node3D
## Captura vistas do cenário: godot --path . res://tests/visual/world_shots.tscn -- --out=DIR

var _out := "user://shots"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	var started := Time.get_ticks_msec()
	var world := DungeonWorld.new()
	add_child(world)
	world.build(GameDB.dungeon(&"frost_gate"), Color("53b6ff"))
	print("mundo construído em ", Time.get_ticks_msec() - started, " ms; luzes: ", world.props.lights.size())
	var cam := Camera3D.new()
	cam.fov = 75.0
	add_child(cam)
	var views: Array = [
		[Vector3(0, 1.7, 30), Vector3(0, 2.0, 60)],
		[Vector3(-7, 1.7, -2), Vector3(12, 2.0, 2)],
		[Vector3(-4, 1.7, 56), Vector3(11, 2.5, 66)],
		[Vector3(124, 1.7, 84), Vector3(124, 6.0, 120)],
		[Vector3(133, 1.7, 56), Vector3(131.0, 3.5, 72)],
	]
	var index := 0
	for view: Array in views:
		cam.look_at_from_position(view[0], view[1])
		world.focus = cam
		for _i in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/view_%d.png" % [_out, index])
		index += 1
	get_tree().quit()
