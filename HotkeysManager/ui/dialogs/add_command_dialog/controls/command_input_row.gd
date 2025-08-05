class_name CommandInputRow extends Control

signal command_input_changed

var _program_id: int


func setup(program_id: int, program_name: String) -> void:
    assert(program_id >= 0)

    _program_id = program_id
    ($ProgramNameLabel as Label).text = program_name


func get_program_id() -> int:
    return _program_id


func get_command_title() -> String:
    return ($CommandTitleLineEdit as LineEdit).text


func get_hotkey() -> String:
    return ($CommandHotkeyLineEdit as LineEdit).text


func has_complete_input() -> bool:
    var command_title := get_command_title()
    var command_hotkey := get_hotkey()
    return !command_title.is_empty() && !command_hotkey.is_empty()


func _on_text_changed(_new_text: String) -> void:
    command_input_changed.emit()
