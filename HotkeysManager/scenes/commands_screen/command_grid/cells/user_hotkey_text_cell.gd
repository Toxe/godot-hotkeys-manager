class_name UserHotkeyTextCell extends TextCell

var command_id: int
var user_hotkey_id: int


func _init(cmd_id: int = 0, uh_id: int = 0) -> void:
    command_id = cmd_id
    user_hotkey_id = uh_id
