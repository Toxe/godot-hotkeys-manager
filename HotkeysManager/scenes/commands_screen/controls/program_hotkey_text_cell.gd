class_name ProgramHotkeyTextCell extends TextCell

var command_id: int
var program_id: int
var is_bound: bool

func _init(cmd_id: int = 0, prog_id: int = 0, cell_is_bound: bool = false) -> void:
    command_id = cmd_id
    program_id = prog_id
    is_bound = cell_is_bound
