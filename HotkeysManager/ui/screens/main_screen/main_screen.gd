class_name MainScreen extends Control

func _on_button_pressed() -> void:
    Events.switch_to_commands_screen.emit()
