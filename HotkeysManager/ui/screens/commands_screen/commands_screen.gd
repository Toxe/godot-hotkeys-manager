class_name CommandsScreen extends Control

func _on_button_pressed() -> void:
    Events.switch_to_hotkeys_screen.emit()
    pass


func _on_button_2_pressed() -> void:
    Events.switch_to_main_screen.emit()
    pass
