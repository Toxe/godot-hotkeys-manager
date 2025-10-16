class_name ProgramHotkeyTextCell extends TextCell

var command_id: int
var program_id: int
var hotkey: Variant

func _init(cmd_id: int = 0, prog_id: int = 0, prog_cmd_hotkey: Variant = null) -> void:
    command_id = cmd_id
    program_id = prog_id
    hotkey = prog_cmd_hotkey
