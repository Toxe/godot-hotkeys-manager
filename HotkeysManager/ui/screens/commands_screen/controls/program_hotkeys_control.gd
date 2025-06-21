class_name ProgramHotkeysControl extends VBoxContainer

var _db: Database
var _programgroup_id: int
var _program_id: int
var _command_id: int
var _program_command_id: int


func setup(db: Database, programgroup_id: int, program_id: int, command_id: int, command_data_program_commands: Dictionary) -> void:
    _db = db
    _programgroup_id = programgroup_id
    _program_id = program_id
    _command_id = command_id

    if program_id in command_data_program_commands:
        var command_data_program_commands_data: Dictionary = command_data_program_commands[program_id]
        var command_data_program_commands_hotkeys: Dictionary = command_data_program_commands_data["hotkeys"]

        _program_command_id = command_data_program_commands_data["program_command_id"]

        ($ProgramCommandNameButton as Button).text = command_data_program_commands_data["name"]
        ($CreateProgramCommandButton as Button).visible = false

        if !command_data_program_commands_hotkeys.is_empty():
            ($DeleteProgramCommandButton as Button).visible = false

            for program_hotkey_id: int in command_data_program_commands_hotkeys:
                var program_hotkey: String = command_data_program_commands_hotkeys[program_hotkey_id]

                var hotkey_button := Button.new()
                hotkey_button.text = program_hotkey
                hotkey_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
                hotkey_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                hotkey_button.pressed.connect(_on_change_program_command_hotkey_button_pressed.bind(program_hotkey_id, program_hotkey))

                var delete_button := Button.new()
                delete_button.text = "❌"
                delete_button.pressed.connect(_on_delete_program_command_hotkey_button_pressed.bind(program_hotkey_id))

                var hbox := HBoxContainer.new()
                hbox.add_child(hotkey_button)
                hbox.add_child(delete_button)

                $Hotkeys.add_child(hbox)
    else:
        ($ProgramCommandNameButton as Button).visible = false
        ($AddProgramCommandHotkeyButton as Button).visible = false
        ($DeleteProgramCommandButton as Button).visible = false


func _on_program_command_name_button_pressed() -> void:
    var dialog: EnterTextDialog = $ChangeProgramCommandNameDialog
    dialog.get_text_field().text = ($ProgramCommandNameButton as Button).text
    dialog.show()


func _on_change_program_command_name_dialog_submitted(text: String) -> void:
    if _db.update_rows("program_command", "id=%d" % _program_command_id, {"name": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_change_program_command_hotkey_button_pressed(program_hotkey_id: int, program_hotkey: String) -> void:
    var dialog: EnterTextDialog = $ChangeProgramCommandHotkeyDialog
    dialog.get_text_field().text = program_hotkey
    dialog.set_meta("program_hotkey_id", program_hotkey_id)
    dialog.show()


func _on_change_program_command_hotkey_dialog_submitted(text: String) -> void:
    var dialog: EnterTextDialog = $ChangeProgramCommandHotkeyDialog
    var program_hotkey_id: int = dialog.get_meta("program_hotkey_id")
    if _db.update_rows("program_command_hotkey", "id=%d" % program_hotkey_id, {"hotkey": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_add_program_command_hotkey_button_pressed() -> void:
    var dialog: EnterTextDialog = $AddProgramCommandHotkeyDialog
    dialog.show()


func _on_add_program_command_hotkey_dialog_submitted(text: String) -> void:
    if _db.insert_row("program_command_hotkey", {"program_command_id": _program_command_id, "hotkey": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_create_program_command_button_pressed() -> void:
    var dialog: EnterTextDialog = $CreateProgramCommandDialog
    dialog.show()


func _on_create_program_command_dialog_submitted(text: String) -> void:
    if _db.insert_row("program_command", {"program_id": _program_id, "command_id": _command_id, "name": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_delete_program_command_hotkey_button_pressed(program_hotkey_id: int) -> void:
    if _db.delete_rows("program_command_hotkey", "id=%d" % program_hotkey_id):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_delete_program_command_button_pressed() -> void:
    if _db.delete_rows("program_command", "program_id=%d AND command_id=%d" % [_program_id, _command_id]):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
