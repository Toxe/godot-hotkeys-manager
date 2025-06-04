class_name MainScreen extends Control

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var _db: Database = null


func _ready() -> void:
    assert(_db.is_open())

    var res := _db.query("SELECT id, name FROM programgroup ORDER BY name")
    if res.ok:
        for row: Dictionary in res.rows:
            add_programgroup(row)


func setup(db: Database) -> void:
    _db = db


func add_programgroup(row: Dictionary) -> void:
    var id: int = row.id
    var programgroup_name: String = row.name
    var programgroup := programgroup_scene.instantiate() as Programgroup
    programgroup.setup(_db, id, programgroup_name)
    $VBoxContainer/ProgramgroupList.add_child(programgroup)
