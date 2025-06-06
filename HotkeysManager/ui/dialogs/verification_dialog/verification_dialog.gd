class_name VerificationDialog extends Window

signal confirmed
signal canceled

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


func get_label() -> RichTextLabel:
    return $VBoxContainer/RichTextLabel


func _on_visibility_changed() -> void:
    if visible:
        get_label().text = label_text


func _on_confirmation_button_pressed() -> void:
    hide()
    confirmed.emit()


func _on_cancel_button_pressed() -> void:
    hide()
    canceled.emit()
