class_name Programgroup extends Control

var _db: Database = null
var _programgroup_id: int = -1

@onready var program_list: ItemList = $HBoxContainer/ProgramList


func setup(db: Database, id: int) -> void:
    _db = db
    _programgroup_id = id


func _ready() -> void:
    var programgroup_name: Variant = _db.select_value("programgroup", "id=%d" % _programgroup_id, "name")
    if programgroup_name != null:
        ($TitleLabel as Label).text = programgroup_name

    var sql := "SELECT pp.programgroup_id, pp.program_id, p.name
FROM programgroup_program pp
INNER JOIN program p ON pp.program_id = p.id
WHERE pp.programgroup_id = ?
ORDER BY p.name;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            add_program(row)


func add_program(row: Dictionary) -> void:
    var program_name: String = row.name
    var program_id: int = row.program_id
    var index := program_list.add_item(program_name)
    program_list.set_item_metadata(index, program_id)


func _on_program_list_item_selected(_index: int) -> void:
    ($HBoxContainer/VBoxContainer/RemoveProgramButton as Button).disabled = !program_list.is_anything_selected()


func _on_add_program_button_pressed() -> void:
    var add_program_dialog: SelectionDialog = $AddProgramDialog
    var list: ItemList = add_program_dialog.get_list()
    list.clear()

    var sql := "SELECT p.id, p.name
FROM program p
LEFT JOIN programgroup_program pp ON p.id = pp.program_id AND pp.programgroup_id = ?
WHERE pp.program_id IS NULL
ORDER BY p.name;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_name: String = row.name
            var program_id: int = row.id
            var index := list.add_item(program_name)
            list.set_item_metadata(index, program_id)
        add_program_dialog.show()


func _on_add_program_dialog_submitted(selection: Array) -> void:
    for id: Variant in selection:
        if !_db.insert_row("programgroup_program", {"programgroup_id": _programgroup_id, "program_id": id}):
            return
    Events.switch_to_main_screen.emit.call_deferred()


func _on_remove_program_button_pressed() -> void:
    assert(program_list.get_selected_items().size() == 1)
    var index := program_list.get_selected_items().get(0)
    var program_id: int = program_list.get_item_metadata(index)
    if _db.delete_rows("programgroup_program", "programgroup_id=%d AND program_id=%d" % [_programgroup_id, program_id]):
        Events.switch_to_main_screen.emit.call_deferred()


func _on_rename_group_button_pressed() -> void:
    var rename_group_dialog: EnterTextDialog = $RenameGroupDialog
    rename_group_dialog.get_text_field().text = ($TitleLabel as Label).text
    rename_group_dialog.show()


func _on_rename_group_dialog_submitted(text: String) -> void:
    if _db.update_rows("programgroup", "id=%d" % _programgroup_id, {"name": text}):
        ($TitleLabel as Label).text = text


func _on_delete_group_button_pressed() -> void:
    ($DeleteGroupDialog as VerificationDialog).show()


func _on_delete_group_dialog_confirmed() -> void:
    if _db.delete_rows("programgroup", "id=%d" % _programgroup_id):
        Events.switch_to_main_screen.emit.call_deferred()
