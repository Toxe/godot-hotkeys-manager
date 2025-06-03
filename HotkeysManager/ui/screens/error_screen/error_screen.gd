class_name ErrorScreen extends Control

@export var error_text := ""
@export var error_message := ""


func _ready() -> void:
    printerr(error_text)
    printerr(error_message)
    ($ErrorView/ErrorText as Label).text = "Error: %s" % error_text
    ($ErrorView/ErrorMessage as Label).text = error_message
