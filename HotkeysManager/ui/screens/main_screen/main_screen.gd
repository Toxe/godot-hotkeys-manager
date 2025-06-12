class_name MainScreen extends Control

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var _db: Database = null


func setup(db: Database) -> void:
    _db = db


func _ready() -> void:
    assert(_db.is_open())

    var rows: Variant = _db.select_rows("programgroup", "", ["id", "name"])
    if rows:
        for row: Dictionary in rows:
            add_programgroup(row)


func add_programgroup(row: Dictionary) -> void:
    var id: int = row.id
    var programgroup := programgroup_scene.instantiate() as Programgroup
    programgroup.setup(_db, id)
    $VBoxContainer/ProgramgroupList.add_child(programgroup)


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
