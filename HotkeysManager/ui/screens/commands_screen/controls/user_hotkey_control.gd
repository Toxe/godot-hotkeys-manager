class_name UserHotkeyControl extends PanelContainer

var _db: Database
var _programgroup_id: int
var _command_id: int
var _user_hotkey_id: int


func setup(db: Database, programgroup_id: int, command_id: int, user_hotkeys: Dictionary[int, Dictionary]) -> void:
    assert(db != null)
    assert(db.is_open())
    assert(programgroup_id > 0)
    assert(command_id > 0)

    _db = db
    _programgroup_id = programgroup_id
    _command_id = command_id

    if _command_id in user_hotkeys:
        var user_hotkey_data: Dictionary = user_hotkeys[_command_id]
        var user_hotkey: String = user_hotkey_data["user_hotkey"]
        _user_hotkey_id = user_hotkey_data["user_hotkey_id"]
        ($VBoxContainer/UserHotkeyButton as Button).text = user_hotkey
        ($VBoxContainer/CreateUserHotkeyButton as Button).visible = false
    else:
        ($VBoxContainer/UserHotkeyButton as Button).visible = false
        ($VBoxContainer/DeleteUserHotkeyButton as Button).visible = false


func _on_user_hotkey_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "Change Hotkey", "Enter the new Hotkey.", _on_change_user_hotkey_dialog_submitted, ($VBoxContainer/UserHotkeyButton as Button).text)


func _on_create_user_hotkey_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "Create Hotkey", "Enter the new Hotkey.", _on_create_user_hotkey_dialog_submitted)


func _on_delete_user_hotkey_button_pressed() -> void:
    if _db.delete_rows("user_hotkey", "user_hotkey_id=%d" % _user_hotkey_id):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_change_user_hotkey_dialog_submitted(_dialog: EnterTextDialog, text: String) -> void:
    if _db.update_rows("user_hotkey", "user_hotkey_id=%d" % _user_hotkey_id, {"hotkey": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_create_user_hotkey_dialog_submitted(_dialog: EnterTextDialog, text: String) -> void:
    if _db.insert_row("user_hotkey", {"command_id": _command_id, "hotkey": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
