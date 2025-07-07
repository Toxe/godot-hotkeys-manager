class_name MainScreen extends Control

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var _db: Database = null


func setup(db: Database) -> void:
    _db = db

    var programgroups := query_programgroups()
    var programgroup_programs := query_programgroup_programs()

    for programgroup_id in programgroups:
        var programs: Dictionary = programgroup_programs.get(programgroup_id, {})
        var programgroup: Programgroup = programgroup_scene.instantiate()
        programgroup.setup(_db, programgroup_id, programgroups[programgroup_id], programs)
        programgroup.programgroup_deleted.connect(_on_programgroup_deleted)
        $VBoxContainer/ProgramgroupList.add_child(programgroup)


func query_programgroups() -> Dictionary[int, String]:
    var programgroups: Dictionary[int, String] = {}
    var rows: Variant = _db.select_rows("programgroup", "", ["id", "name"])
    if rows:
        for row: Dictionary in rows:
            var programgroup_id: int = row["id"]
            var programgroup_name: String = row["name"]
            programgroups[programgroup_id] = programgroup_name
    return programgroups


func query_programgroup_programs() -> Dictionary[int, Dictionary]:
    var programgroup_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pp.programgroup_id, pp.program_id, p.name AS program_name
FROM programgroup_program pp
INNER JOIN program p ON pp.program_id = p.id;"

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
    ($NewProgramDialog as EnterTextDialog).show()


func _on_new_program_dialog_submitted(text: String) -> void:
    if _db.insert_row("program", {"name": text}):
        Events.switch_to_main_screen.emit.call_deferred()


func _on_new_group_button_pressed() -> void:
    ($NewGroupDialog as EnterTextDialog).show()


func _on_new_group_dialog_submitted(text: String) -> void:
    if _db.insert_row("programgroup", {"name": text}):
        Events.switch_to_main_screen.emit.call_deferred()


func _on_programgroup_deleted(programgroup_id: int) -> void:
    for programgroup: Programgroup in $VBoxContainer/ProgramgroupList.find_children("*", "Programgroup", true, false):
        if programgroup._programgroup_id == programgroup_id:
            $VBoxContainer/ProgramgroupList.remove_child(programgroup)
            programgroup.free()
            break
