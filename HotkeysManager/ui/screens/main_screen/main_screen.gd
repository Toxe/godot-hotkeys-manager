class_name MainScreen extends Control

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var _db: Database = null


func setup(db: Database) -> void:
    _db = db

    var programgroups := query_programgroups()
    var programgroup_programs := query_programgroup_programs()

    for programgroup_id in programgroups:
        var programgroup_name: String = programgroups[programgroup_id]
        var programs: Dictionary = programgroup_programs.get(programgroup_id, {})
        add_programgroup(programgroup_id, programgroup_name, programs)


func add_programgroup(programgroup_id: int, programgroup_name: String, programs: Dictionary) -> void:
        var programgroup: Programgroup = programgroup_scene.instantiate()
        programgroup.setup(_db, programgroup_id, programgroup_name, programs)
        programgroup.programgroup_deleted.connect(_on_programgroup_deleted)
        $VBoxContainer/ScrollContainer/ProgramgroupList.add_child(programgroup)


func query_programgroups() -> Dictionary[int, String]:
    var programgroups: Dictionary[int, String] = {}
    var rows: Variant = _db.select_rows("programgroup", "", ["programgroup_id", "name"])
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
INNER JOIN program p ON pp.program_id = p.program_id;"

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


func _on_new_program_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "New Program", "Please enter the name of the new Program.", _on_new_program_dialog_submitted)


func _on_new_group_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "New Program Group", "Please enter the name of the new Program Group.", _on_new_group_dialog_submitted)


func _on_new_program_dialog_submitted(_dialog: EnterTextDialog, text: String) -> void:
    _db.insert_row("program", {"name": text})


func _on_new_group_dialog_submitted(_dialog: EnterTextDialog, programgroup_name: String) -> void:
    if _db.insert_row("programgroup", {"name": programgroup_name}):
        var programgroup_id := _db.last_insert_rowid()
        var programs := {} # new group is empty
        add_programgroup(programgroup_id, programgroup_name, programs)


func _on_programgroup_deleted(programgroup_id: int) -> void:
    for programgroup: Programgroup in $VBoxContainer/ScrollContainer/ProgramgroupList.find_children("*", "Programgroup", true, false):
        if programgroup._programgroup_id == programgroup_id:
            $VBoxContainer/ScrollContainer/ProgramgroupList.remove_child(programgroup)
            programgroup.queue_free()
            break
