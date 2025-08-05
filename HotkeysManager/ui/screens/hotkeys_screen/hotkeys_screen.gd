class_name HotkeysScreen extends Control

var _db: Database = null


func setup(db: Database) -> void:
    assert(db != null)
    assert(db.is_open())

    _db = db


func _on_button_pressed() -> void:
    Events.switch_to_commands_screen.emit()
