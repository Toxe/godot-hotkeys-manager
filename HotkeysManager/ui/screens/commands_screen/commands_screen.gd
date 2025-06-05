class_name CommandsScreen extends Control

var _db: Database = null


func setup(db: Database) -> void:
    _db = db


func _ready() -> void:
    assert(_db.is_open())


func _on_button_pressed() -> void:
    Events.switch_to_hotkeys_screen.emit()


func _on_button_2_pressed() -> void:
    Events.switch_to_main_screen.emit()
