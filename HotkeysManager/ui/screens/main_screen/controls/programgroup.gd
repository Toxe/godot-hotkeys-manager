class_name Programgroup extends Control

signal programgroup_deleted(programgroup_id: int)

var _db: Database = null
var _programgroup_id: int = -1

var programgroup_name: String:
    get:
        return ($VBoxContainer/TitleLabel as Label).text
    set(value):
        ($VBoxContainer/TitleLabel as Label).text = value


func setup(db: Database, programgroup_id: int, group_name: String, programs: Dictionary) -> void:
    _db = db
    _programgroup_id = programgroup_id
    programgroup_name = group_name
    update_program_list(programs)


func get_program_list() -> ItemList:
    return $VBoxContainer/HBoxContainer/ProgramList


func get_selected_program_list_item() -> int:
    var items := get_program_list().get_selected_items()
    return items[0] if items.size() == 1 else -1


func select_program_list_item(index: int) -> void:
    get_program_list().select(index)
    update_button_states()


func update_button_states() -> void:
    var list := get_program_list()
    ($VBoxContainer/HBoxContainer/VBoxContainer/RemoveProgramButton as Button).disabled = !list.is_anything_selected()
    ($VBoxContainer/HBoxContainer2/CommandsButton as Button).disabled = list.item_count == 0


func update_program_list(programs: Dictionary) -> void:
    var list := get_program_list()
    list.clear()

    for program_id: int in programs:
        var program_name: String = programs[program_id]
        var index := list.add_item(program_name)
        list.set_item_metadata(index, program_id)

    update_button_states()


func query_programs() -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var sql := "SELECT p.id AS program_id, p.name AS program_name
FROM program p
INNER JOIN programgroup_program pp ON p.id = pp.program_id AND pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["program_name"]
            programs[program_id] = program_name
    return programs


func query_available_programs() -> Dictionary[int, String]:
    var available_programs: Dictionary[int, String] = {}
    var sql := "SELECT p.id AS program_id, p.name AS program_name
FROM program p
LEFT JOIN programgroup_program pp ON p.id = pp.program_id AND pp.programgroup_id = ?
WHERE pp.program_id IS NULL;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["program_name"]
            available_programs[program_id] = program_name
    return available_programs


func _on_program_list_item_selected(index: int) -> void:
    assert(index >= 0 && index < get_program_list().item_count)
    select_program_list_item(index)


func _on_add_program_button_pressed() -> void:
    var available_programs := query_available_programs()
    var add_program_dialog: SelectionDialog = $AddProgramDialog
    var list := add_program_dialog.get_list()
    list.clear()

    for program_id: int in available_programs:
        var program_name: String = available_programs[program_id]
        var index := list.add_item(program_name)
        list.set_item_metadata(index, program_id)
    add_program_dialog.show()


func _on_add_program_dialog_submitted(selection: Array) -> void:
    for id: Variant in selection:
        if !_db.insert_row("programgroup_program", {"programgroup_id": _programgroup_id, "program_id": id}):
            return
    update_program_list(query_programs())


func _on_remove_program_button_pressed() -> void:
    var index := get_selected_program_list_item()
    assert(index >= 0 && index < get_program_list().item_count)
    var program_id: int = get_program_list().get_item_metadata(index)
    if _db.delete_rows("programgroup_program", "programgroup_id=%d AND program_id=%d" % [_programgroup_id, program_id]):
        update_program_list(query_programs())
        select_program_list_item(mini(index, get_program_list().item_count - 1))


func _on_rename_group_button_pressed() -> void:
    var rename_group_dialog: EnterTextDialog = $RenameGroupDialog
    rename_group_dialog.get_text_field().text = programgroup_name
    rename_group_dialog.show()


func _on_rename_group_dialog_submitted(new_name: String) -> void:
    if _db.update_rows("programgroup", "id=%d" % _programgroup_id, {"name": new_name}):
        programgroup_name = new_name


func _on_delete_group_button_pressed() -> void:
    ($DeleteGroupDialog as VerificationDialog).show()


func _on_delete_group_dialog_confirmed() -> void:
    if _db.delete_rows("programgroup", "id=%d" % _programgroup_id):
        programgroup_deleted.emit(_programgroup_id)


func _on_commands_button_pressed() -> void:
    Events.switch_to_commands_screen.emit(_programgroup_id)
