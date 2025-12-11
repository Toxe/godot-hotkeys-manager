class_name UserHotkeyProgramCheckboxCell extends CheckBox

signal add_row(cell: TextCell, add_above: bool)

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


func _gui_input(event: InputEvent) -> void:
    if event.is_pressed() && !event.is_echo():
        var add_row_above := false
        var add_row_below := false

        if event.is_action_pressed("add_row_above", false, true):
            add_row_above = true
        if event.is_action_pressed("add_row_below", false, true):
            add_row_below = true

        assert((add_row_above && add_row_below) == false)

        if add_row_above:
            accept_event()
            add_row.emit(self, true)

        if add_row_below:
            accept_event()
            add_row.emit(self, false)
