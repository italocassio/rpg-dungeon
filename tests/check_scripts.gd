extends Node
## Compila todos os scripts e carrega todas as cenas/recursos do projeto.
## godot --headless --path . res://tests/check_scripts.tscn

var _errors: int = 0
var _scripts: int = 0
var _resources: int = 0


func _ready() -> void:
	for root: String in ["res://src", "res://tests", "res://data", "res://assets/shaders"]:
		_walk(root)
	print("scripts=%d recursos=%d erros=%d" % [_scripts, _resources, _errors])
	get_tree().quit(1 if _errors > 0 else 0)


func _walk(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub in directory.get_directories():
		_walk(path.path_join(sub))
	for file in directory.get_files():
		var full: String = path.path_join(file)
		if file.ends_with(".gd"):
			_scripts += 1
			var script: GDScript = load(full)
			if script == null or not script.can_instantiate():
				_errors += 1
				print("ERRO ao compilar: ", full)
		elif file.ends_with(".tscn") or file.ends_with(".tres") or file.ends_with(".gdshader"):
			_resources += 1
			if load(full) == null:
				_errors += 1
				print("ERRO ao carregar: ", full)
