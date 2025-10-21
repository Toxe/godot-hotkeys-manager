class_name UserHotkeyProgramCheckbox extends CheckBox

var program_id: int
var user_hotkey_id: int


func _init(prog_id: int = 0, uh_id: int = 0) -> void:
    program_id = prog_id
    user_hotkey_id = uh_id

    size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    size_flags_vertical = Control.SIZE_FILL
