class_name UserHotkeyProgramCheckbox extends CheckBox

var program_id: int

var user_hotkey_id: int:
    set(value):
        user_hotkey_id = value
        disabled = user_hotkey_id == 0 # automatically disable checkboxes without a user hotkey


func _init(prog_id: int = 0, uh_id: int = 0) -> void:
    program_id = prog_id
    user_hotkey_id = uh_id

    size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    size_flags_vertical = Control.SIZE_FILL
