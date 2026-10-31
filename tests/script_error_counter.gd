class_name ScriptErrorCounter
extends Logger
## Conta erros de script: sem isto, um erro aborta a função de teste em silêncio e o runner aprova.

var count: int = 0


func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
	if error_type == Logger.ERROR_TYPE_SCRIPT:
		count += 1
