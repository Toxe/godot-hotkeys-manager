class_name ErrorScreen extends Control

var _error_text := ""
var _error_message := ""


func setup(text: String, message: String) -> void:
    _error_text = text
    _error_message = message


func _ready() -> void:
    ($ErrorView/ErrorText as Label).text = "%s" % _error_text
    ($ErrorView/ErrorMessage as Label).text = _error_message
