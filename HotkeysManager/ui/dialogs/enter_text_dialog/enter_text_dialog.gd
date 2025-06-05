class_name EnterTextDialog extends Window

signal submitted(text: String)
signal canceled

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


func get_label() -> RichTextLabel:
    return $VBoxContainer/VBoxContainer/RichTextLabel


func get_text_field() -> LineEdit:
    return $VBoxContainer/VBoxContainer/LineEdit


func _on_visibility_changed() -> void:
    if visible:
        get_label().text = label_text
        get_text_field().grab_focus()
        get_text_field().caret_column = get_text_field().text.length()


func _on_submit_button_pressed() -> void:
    hide()
    submitted.emit(get_text_field().text)


func _on_cancel_button_pressed() -> void:
    hide()
    canceled.emit()
