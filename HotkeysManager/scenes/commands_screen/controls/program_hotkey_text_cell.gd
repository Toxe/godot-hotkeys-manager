class_name ProgramHotkeyTextCell extends TextCell

var command_id: int
var program_id: int
var program_command_id: int


func _init(cmd_id: int = 0, prog_id: int = 0, prog_cmd_id: int = 0) -> void:
    command_id = cmd_id
    program_id = prog_id
    program_command_id = prog_cmd_id
