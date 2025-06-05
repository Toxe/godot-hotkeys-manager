class_name Programgroup extends Control

var _db: Database = null
var _programgroup_id: int = -1

@onready var item_list: ItemList = $HBoxContainer/ItemList


func setup(db: Database, id: int) -> void:
    _db = db
    _programgroup_id = id


func _ready() -> void:
    var programgroup_name: Variant = _db.query_single_value("SELECT name FROM programgroup WHERE id=?", [_programgroup_id])

    if programgroup_name != null:
        ($TitleLabel as Label).text = programgroup_name

    var sql := "SELECT pp.programgroup_id, pp.program_id, p.name
FROM programgroup_program pp
INNER JOIN program p ON pp.program_id = p.id
WHERE pp.programgroup_id = ?
ORDER BY p.name"

    var res := _db.query(sql, [_programgroup_id])
    if res.ok:
        for row: Dictionary in res.rows:
            add_program(row)


func add_program(row: Dictionary) -> void:
    var program_name: String = row.name
    var program_id: int = row.program_id
    var index := item_list.add_item(program_name)
    item_list.set_item_metadata(index, program_id)


func _on_item_list_item_selected(index: int) -> void:
    var program_id: int = item_list.get_item_metadata(index)
    prints(index, program_id)
