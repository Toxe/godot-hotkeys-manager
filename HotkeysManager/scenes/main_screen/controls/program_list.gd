class_name ProgramList extends VBoxContainer

signal program_edited(program_id: int)
signal program_deleted(program_id: int)

var _db: Database = null


func setup(db: Database) -> void:
    assert(db != null)
    assert(db.is_open())

    _db = db

    update_list()


func get_list() -> ItemList:
    return $ItemList


func update_list() -> void:
    var programs := query_programs()
    var list := get_list()
    list.clear()

    for program_id in programs:
        var program_data: Dictionary = programs[program_id]
        var program_name: String = program_data["name"]
        var program_abbreviation: String = program_data["abbreviation"]
        var item_text := "%s (%s)" % [program_name, program_abbreviation]
        var index := list.add_item(item_text)
        list.set_item_metadata(index, program_data)

    update_button_states()


func update_button_states() -> void:
    var list := get_list()
    ($HBoxContainer/EditButton as Button).disabled = !list.is_anything_selected()
    ($HBoxContainer/DeleteButton as Button).disabled = !list.is_anything_selected()


func get_selected_program_list_item() -> int:
    var items := get_list().get_selected_items()
    return items[0] if items.size() == 1 else -1


func select_program_list_item(index: int) -> void:
    assert(index >= 0 && index < get_list().item_count)
    get_list().select(index)
    update_button_states()


func query_programs() -> Dictionary[int, Dictionary]:
    var programs: Dictionary[int, Dictionary] = {}
    var rows: Variant = _db.select_rows("program", ["program_id", "name", "abbreviation"])
    if rows:
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            programs[program_id] = row
    return programs


func _on_item_list_item_selected(index: int) -> void:
    select_program_list_item(index)


func _on_add_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "Add Program", "Please enter the name and abbreviation of the new Program.", {"name": "Name", "abbreviation": "Abbreviation"}, _on_add_program_dialog_submitted)


func _on_edit_button_pressed() -> void:
    var index := get_selected_program_list_item()
    assert(index >= 0 && index < get_list().item_count)
    var program_data: Dictionary = get_list().get_item_metadata(index)
    var program_id: int = program_data["program_id"]
    var program_name: String = program_data["name"]
    var program_abbreviation: String = program_data["abbreviation"]
    var values: Dictionary[String, String] = {"name": program_name, "abbreviation": program_abbreviation}
    EnterTextDialog.open_dialog(self, "Edit Program", "Please enter the new name and abbreviation of the Program.", {"name": "Name", "abbreviation": "Abbreviation"}, _on_edit_program_dialog_submitted.bind(index, program_id), values)


func _on_delete_button_pressed() -> void:
    var index := get_selected_program_list_item()
    assert(index >= 0 && index < get_list().item_count)
    var program_data: Dictionary = get_list().get_item_metadata(index)
    var program_id: int = program_data["program_id"]
    VerificationDialog.open_dialog(self, "Delete Program", "Are you sure you want to delete this Program?", _on_delete_program_dialog_confirmed.bind(index, program_id))


func _on_add_program_dialog_submitted(_dialog: EnterTextDialog, values: Dictionary[String, Variant]) -> void:
    if _db.insert_row("program", values):
        var program_id := _db.last_insert_rowid()
        var program_name: String = values["name"]
        var program_abbreviation: String = values["abbreviation"]
        var program_data: Dictionary = {"program_id": program_id, "name": program_name, "abbreviation": program_abbreviation}
        var item_text := "%s (%s)" % [program_name, program_abbreviation]
        var index := get_list().add_item(item_text)
        get_list().set_item_metadata(index, program_data)
        select_program_list_item(index)


func _on_edit_program_dialog_submitted(_dialog: EnterTextDialog, values: Dictionary[String, Variant], index: int, program_id: int) -> void:
    if _db.update_rows("program", "program_id=?", [program_id], values):
        var program_name: String = values["name"]
        var program_abbreviation: String = values["abbreviation"]
        var program_data: Dictionary = {"program_id": program_id, "name": program_name, "abbreviation": program_abbreviation}
        var item_text := "%s (%s)" % [program_name, program_abbreviation]
        get_list().set_item_text(index, item_text)
        get_list().set_item_metadata(index, program_data)
        update_button_states()
        program_edited.emit(program_id)


func _on_delete_program_dialog_confirmed(_dialog: VerificationDialog, index: int, program_id: int) -> void:
    if _db.delete_rows("program", "program_id=?", [program_id]):
        get_list().remove_item(index)
        update_button_states()
        program_deleted.emit(program_id)
