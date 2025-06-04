class_name HotkeysScreen extends Control

var _db: Database = null


func _ready() -> void:
    assert(_db.is_open())


func setup(db: Database) -> void:
    _db = db


func _on_button_pressed() -> void:
    Events.switch_to_commands_screen.emit()
