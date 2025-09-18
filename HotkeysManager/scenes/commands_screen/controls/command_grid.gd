class_name CommandGrid extends GridContainer

const program_hotkeys_control_scene: PackedScene = preload("uid://dq4m5hd12nvxh")
const user_hotkey_control_scene: PackedScene = preload("uid://brad514ehxj7r")

var _db: Database = null
var _programgroup_id: int = -1


func setup(db: Database, programgroup_id: int, programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String], commands: Dictionary[int, String], program_commands: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    assert(db != null)
    assert(db.is_open())
    assert(programgroup_id > 0)

    _db = db
    _programgroup_id = programgroup_id
    columns = 1 + programs.size() + 1 + programs.size()

    add_header_row(programs, program_abbreviations)

    for command_id in commands:
        add_command_row(command_id, programs, commands, program_commands, program_command_hotkeys, user_hotkeys, user_hotkey_programs)


func add_header_row(programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String]) -> void:
    add_header_command_label("Commands")

    for program_id: int in programs:
        add_header_program_label(programs[program_id])

    add_header_user_hotkey_label("User Hotkey")

    for program_id: int in programs:
        add_header_program_abbreviation(programs[program_id], program_abbreviations[program_id])


func add_command_row(command_id: int, programs: Dictionary[int, String], commands: Dictionary[int, String], program_commands: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    add_command_button(command_id, commands[command_id])

    for program_id: int in programs:
        add_program_hotkeys_control(command_id, program_id, program_commands, program_command_hotkeys)

    add_user_hotkey_control(command_id, user_hotkeys)
    add_user_hotkey_program_controls(command_id, programs, user_hotkeys, user_hotkey_programs)


func add_label(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.size_flags_vertical = Control.SIZE_FILL
    add_child(label)
    return label


func add_header_command_label(text: String) -> Label:
    var label := add_label(text)
    label.theme_type_variation = "HeaderCommandLabel"
    return label


func add_header_user_hotkey_label(text: String) -> Label:
    var label := add_label(text)
    label.theme_type_variation = "HeaderUserHotkeyLabel"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label


func add_header_program_label(text: String) -> Label:
    var label := add_label(text)
    label.theme_type_variation = "HeaderProgramLabel"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label


func add_header_program_abbreviation(program_name: String, program_abbr: String) -> Label:
    var label := add_label(program_abbr)
    label.theme_type_variation = "HeaderProgramAbbreviation"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.tooltip_text = program_name
    label.mouse_filter = MOUSE_FILTER_PASS
    return label


func add_command_button(command_id: int, command_name: String) -> Button:
    var button := Button.new()
    button.text = command_name
    button.theme_type_variation = "CommandButton"
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    button.pressed.connect(_on_rename_command_button_pressed.bind(command_name, command_id))
    add_child(button)
    return button


func add_program_hotkeys_control(command_id: int, program_id: int, program_commands: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary]) -> ProgramHotkeysControl:
    var control: ProgramHotkeysControl = program_hotkeys_control_scene.instantiate()
    control.setup(_db, _programgroup_id, command_id, program_id, program_commands, program_command_hotkeys)
    add_child(control)
    return control


func add_user_hotkey_control(command_id: int, user_hotkeys: Dictionary[int, Dictionary]) -> UserHotkeyControl:
    var control: UserHotkeyControl = user_hotkey_control_scene.instantiate()
    control.setup(_db, _programgroup_id, command_id, user_hotkeys)
    add_child(control)
    return control


func add_user_hotkey_program_controls(command_id: int, programs: Dictionary[int, String], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    if command_id in user_hotkeys:
        var user_hotkey_id: int = user_hotkeys[command_id]["user_hotkey_id"]
        var hotkeys: Array = user_hotkey_programs[command_id].get("hotkeys") if command_id in user_hotkey_programs else []

        for program_id in programs:
            var s := "✔️" if program_id in hotkeys else "❌"
            var label := add_label(s)
            label.mouse_filter = Control.MOUSE_FILTER_PASS
            label.gui_input.connect(_on_user_hotkey_program_checkbox_gui_input.bind(user_hotkey_id, program_id, label))
    else:
        for program_id in programs:
            add_label("–")


func _on_rename_command_button_pressed(command_name: String, command_id: int) -> void:
    var rename_command_dialog := EnterTextDialog.open_dialog(self, "Rename Command", "Enter the new Command name.", {"name": "Name"}, _on_rename_command_dialog_submitted, {"name": command_name})
    rename_command_dialog.set_meta("command_id", command_id)


func _on_rename_command_dialog_submitted(rename_command_dialog: EnterTextDialog, values: Dictionary[String, String]) -> void:
    var command_id: int = rename_command_dialog.get_meta("command_id")
    if _db.update_rows("command", "command_id=%d" % command_id, {"name": values["name"]}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_user_hotkey_program_checkbox_gui_input(event: InputEvent, user_hotkey_id: int, program_id: int, label: Label) -> void:
    if event is InputEventMouseButton:
        var mouse_button_event: InputEventMouseButton = event
        if mouse_button_event.pressed && mouse_button_event.button_index == 1:
            if label.text == "✔️":
                _db.delete_rows("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, program_id])
            elif label.text == "❌":
                _db.insert_row("user_hotkey_program", {"user_hotkey_id": user_hotkey_id, "program_id": program_id})
            Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
