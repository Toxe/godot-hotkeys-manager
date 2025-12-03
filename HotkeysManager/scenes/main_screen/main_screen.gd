class_name MainScreen extends Control

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var _db: Database = null


func setup(db: Database) -> void:
    assert(db != null)
    assert(db.is_open())

    _db = db

    ($VBoxContainer/ScrollContainer/HBoxContainer/ProgramList as ProgramList).setup(_db)
    rebuild_programgroups()


func rebuild_programgroups() -> void:
    var programgroup_list := $VBoxContainer/ScrollContainer/HBoxContainer/ProgramgroupList
    for programgroup: Programgroup in programgroup_list.find_children("*", "Programgroup", true, false):
        programgroup_list.remove_child(programgroup)
        programgroup.queue_free()

    var programgroups := query_programgroups()
    var programgroup_programs := query_programgroup_programs()
    for programgroup_id in programgroups:
        var programgroup_name: String = programgroups[programgroup_id]
        var programs: Dictionary = programgroup_programs.get(programgroup_id, {})
        add_programgroup(programgroup_list, programgroup_id, programgroup_name, programs)


func add_programgroup(programgroup_list: Node, programgroup_id: int, programgroup_name: String, programs: Dictionary) -> void:
        var programgroup: Programgroup = programgroup_scene.instantiate()
        programgroup.setup(_db, programgroup_id, programgroup_name, programs)
        programgroup.programgroup_deleted.connect(_on_programgroup_deleted)
        programgroup_list.add_child(programgroup)


func query_programs() -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var rows: Variant = _db.select_rows("program", ["program_id", "name"])
    if rows:
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["name"]
            programs[program_id] = program_name
    return programs


func query_programgroups() -> Dictionary[int, String]:
    var programgroups: Dictionary[int, String] = {}
    var rows: Variant = _db.select_rows("programgroup", ["programgroup_id", "name"])
    if rows:
        for row: Dictionary in rows:
            var programgroup_id: int = row["programgroup_id"]
            var programgroup_name: String = row["name"]
            programgroups[programgroup_id] = programgroup_name
    return programgroups


func query_programgroup_programs() -> Dictionary[int, Dictionary]:
    var programgroup_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pp.programgroup_id, pp.program_id, p.name AS program_name
FROM programgroup_program pp
INNER JOIN program p USING (program_id);"

    if _db.select(sql):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var programgroup_id: int = row["programgroup_id"]
            var program_id: int = row["program_id"]
            var program_name: String = row["program_name"]

            var programgroup_data: Dictionary = programgroup_programs.get_or_add(programgroup_id, {})
            programgroup_data[program_id] = program_name
    return programgroup_programs


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_new_group_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "New Program Group", "Please enter the name of the new Program Group.", {"programgroup_name": "Program Group Name"}, _on_new_group_dialog_submitted)


func _on_new_group_dialog_submitted(_dialog: EnterTextDialog, values: Dictionary[String, String]) -> void:
    if _db.insert_row("programgroup", {"name": values["programgroup_name"]}):
        var programgroup_id := _db.last_insert_rowid()
        var programs := {} # new group is empty
        add_programgroup($VBoxContainer/ScrollContainer/HBoxContainer/ProgramgroupList, programgroup_id, values["programgroup_name"], programs)


func _on_programgroup_deleted(programgroup_id: int) -> void:
    for programgroup: Programgroup in $VBoxContainer/ScrollContainer/HBoxContainer/ProgramgroupList.find_children("*", "Programgroup", true, false):
        if programgroup._programgroup_id == programgroup_id:
            $VBoxContainer/ScrollContainer/HBoxContainer/ProgramgroupList.remove_child(programgroup)
            programgroup.queue_free()
            break


func _on_program_list_program_edited(_program_id: int) -> void:
    rebuild_programgroups()


func _on_program_list_program_deleted(_program_id: int) -> void:
    rebuild_programgroups()
