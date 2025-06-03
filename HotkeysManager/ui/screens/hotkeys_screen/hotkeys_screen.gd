class_name HotkeysScreen extends Control

func _on_button_pressed() -> void:
    Events.switch_to_commands_screen.emit()
    pass
