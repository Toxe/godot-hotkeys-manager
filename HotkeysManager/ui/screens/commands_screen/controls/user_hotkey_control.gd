class_name UserHotkeyControl extends VBoxContainer

var _db: Database
var _programgroup_id: int
var _command_id: int
var _user_hotkey_id: int


func setup(db: Database, programgroup_id: int, command_id: int, user_hotkey_by_commands: Dictionary) -> void:
    _db = db
    _programgroup_id = programgroup_id
    _command_id = command_id

    if command_id in user_hotkey_by_commands:
        var command_user_hotkey_data: Dictionary = user_hotkey_by_commands[command_id]
        var user_hotkey: String = command_user_hotkey_data["user_hotkey"]
        _user_hotkey_id = command_user_hotkey_data["user_hotkey_id"]
        ($UserHotkeyButton as Button).text = user_hotkey
        ($CreateUserHotkeyButton as Button).visible = false
    else:
        ($UserHotkeyButton as Button).visible = false
        ($DeleteUserHotkeyButton as Button).visible = false


func _on_user_hotkey_button_pressed() -> void:
    var dialog: EnterTextDialog = $ChangeUserHotkeyDialog
    dialog.get_text_field().text = ($UserHotkeyButton as Button).text
    dialog.show()


func _on_create_user_hotkey_button_pressed() -> void:
    var dialog: EnterTextDialog = $CreateUserHotkeyDialog
    dialog.show()


func _on_delete_user_hotkey_button_pressed() -> void:
    if _db.delete_rows("user_hotkey", "id=%d" % _user_hotkey_id):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_change_user_hotkey_dialog_submitted(text: String) -> void:
    if _db.update_rows("user_hotkey", "id=%d" % _user_hotkey_id, {"hotkey": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_create_user_hotkey_dialog_submitted(text: String) -> void:
    if _db.insert_row("user_hotkey", {"command_id": _command_id, "hotkey": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
